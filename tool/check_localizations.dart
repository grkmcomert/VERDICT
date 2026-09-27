import 'dart:convert';
import 'dart:io';

class _QuotedSegment {
  const _QuotedSegment(this.raw, this.endIndex);

  final String raw;
  final int endIndex;
}

class _CheckResult {
  const _CheckResult({
    required this.locale,
    required this.entryCount,
    required this.missingCount,
    required this.mojibakeCount,
    required this.untranslatedCount,
    required this.untranslatedSamples,
  });

  final String locale;
  final int entryCount;
  final int missingCount;
  final int mojibakeCount;
  final int untranslatedCount;
  final List<String> untranslatedSamples;
}

final RegExp _mojibakeC1Pattern = RegExp(r'[\u0080-\u009F]');
final RegExp _mojibakeMarkerPattern = RegExp(
  '[\u00C2\u00C3\u00C4\u00C5\u00D0\u00D1]'
  '(?:'
  '[\u0080-\u00BF]'
  '|'
  '[\u0152\u0153\u0160\u0161\u017D\u017E\u0178\u0192\u02C6\u02DC'
  '\u2013\u2014\u2018\u2019\u201A\u201C\u201D\u201E\u2020\u2021\u2022\u2026'
  '\u2030\u2039\u203A\u20AC\u2122]'
  ')',
);

bool _looksLikeMojibake(String value) {
  if (value.isEmpty) return false;
  if (value.contains('\uFFFD')) return true;
  if (_mojibakeC1Pattern.hasMatch(value)) return true;
  if (value.contains('\u00E2\u20AC')) return true;
  if (_mojibakeMarkerPattern.hasMatch(value)) return true;
  if (value.contains('\u00EF\u00BB\u00BF')) return true;
  return false;
}

String _normalizeSpace(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

String _unescapeDartLiteralBody(String value) {
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < value.length; i++) {
    final String ch = value[i];
    if (ch != '\\') {
      out.write(ch);
      continue;
    }
    if (i + 1 >= value.length) {
      out.write('\\');
      break;
    }

    final String next = value[++i];
    switch (next) {
      case 'n':
        out.write('\n');
        break;
      case 'r':
        out.write('\r');
        break;
      case 't':
        out.write('\t');
        break;
      case r'$':
        out.write(r'$');
        break;
      case "'":
        out.write("'");
        break;
      case '"':
        out.write('"');
        break;
      case '\\':
        out.write('\\');
        break;
      case 'u':
        if (i + 4 < value.length) {
          final String hex = value.substring(i + 1, i + 5);
          final int? code = int.tryParse(hex, radix: 16);
          if (code != null) {
            out.writeCharCode(code);
            i += 4;
            break;
          }
        }
        out.write(r'\u');
        break;
      default:
        out.write('\\');
        out.write(next);
    }
  }
  return out.toString();
}

_QuotedSegment? _readQuotedSegment(String line, int startQuoteIndex) {
  if (startQuoteIndex < 0 ||
      startQuoteIndex >= line.length ||
      line[startQuoteIndex] != '"') {
    return null;
  }
  bool escaped = false;
  for (int i = startQuoteIndex + 1; i < line.length; i++) {
    final String ch = line[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch == '\\') {
      escaped = true;
      continue;
    }
    if (ch == '"') {
      return _QuotedSegment(line.substring(startQuoteIndex + 1, i), i);
    }
  }
  return null;
}

Map<String, Map<String, String>> _parseMapBuckets(
    String fileContent, String mapDeclMarker) {
  final List<String> lines = const LineSplitter().convert(fileContent);
  final Map<String, Map<String, String>> out = <String, Map<String, String>>{};
  bool inMap = false;
  String? currentLocale;

  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];
    if (!inMap) {
      if (line.contains(mapDeclMarker)) inMap = true;
      continue;
    }

    if (currentLocale == null) {
      if (line.trim() == '};') break;
      final RegExpMatch? localeMatch =
          RegExp(r"^  '([^']+)': \{$").firstMatch(line);
      if (localeMatch != null) {
        currentLocale = localeMatch.group(1)!;
        out[currentLocale] = <String, String>{};
      }
      continue;
    }

    if (line.trim() == '},') {
      currentLocale = null;
      continue;
    }

    if (!line.startsWith('    "')) continue;
    final int keyStart = line.indexOf('"');
    final _QuotedSegment? keySeg = _readQuotedSegment(line, keyStart);
    if (keySeg == null) continue;

    String rest = line.substring(keySeg.endIndex + 1).trimLeft();
    if (rest.startsWith(':')) {
      rest = rest.substring(1).trimLeft();
    } else {
      continue;
    }

    int consumedLine = i;
    String valueLine = rest;
    while (!valueLine.contains('"')) {
      consumedLine++;
      if (consumedLine >= lines.length) break;
      valueLine = lines[consumedLine].trimLeft();
    }
    if (consumedLine >= lines.length) break;

    final int valueStart = valueLine.indexOf('"');
    if (valueStart < 0) continue;
    final _QuotedSegment? valueSeg = _readQuotedSegment(valueLine, valueStart);
    if (valueSeg == null) continue;

    final String key = _unescapeDartLiteralBody(keySeg.raw);
    final String value = _unescapeDartLiteralBody(valueSeg.raw);
    out[currentLocale]![key] = value;
    i = consumedLine;
  }
  return out;
}

List<_CheckResult> _checkBuckets(Map<String, Map<String, String>> buckets) {
  if (buckets.isEmpty) return const <_CheckResult>[];
  final List<String> locales = buckets.keys.toList()..sort();
  final String baselineLocale = locales.first;
  final Set<String> baselineKeys = buckets[baselineLocale]!.keys.toSet();

  final List<_CheckResult> results = <_CheckResult>[];
  for (final String locale in locales) {
    final Map<String, String> map = buckets[locale]!;
    final Set<String> keys = map.keys.toSet();
    final int missingCount = baselineKeys.difference(keys).length;
    int mojibakeCount = 0;
    int untranslatedCount = 0;
    final List<String> untranslatedSamples = <String>[];
    for (final MapEntry<String, String> entry in map.entries) {
      if (_looksLikeMojibake(entry.key) || _looksLikeMojibake(entry.value)) {
        mojibakeCount++;
      }
      if (_normalizeSpace(entry.key) == _normalizeSpace(entry.value)) {
        untranslatedCount++;
        if (untranslatedSamples.length < 3) {
          untranslatedSamples.add(entry.key);
        }
      }
    }
    results.add(
      _CheckResult(
        locale: locale,
        entryCount: map.length,
        missingCount: missingCount,
        mojibakeCount: mojibakeCount,
        untranslatedCount: untranslatedCount,
        untranslatedSamples: untranslatedSamples,
      ),
    );
  }
  return results;
}

void _printReport(String title, List<_CheckResult> results) {
  stdout.writeln('[$title]');
  if (results.isEmpty) {
    stdout.writeln('  no data');
    return;
  }
  final int expectedEntries = results.first.entryCount;
  stdout.writeln(
      '  locales: ${results.length}, expected entries per locale: $expectedEntries');
  for (final _CheckResult r in results) {
    stdout.writeln(
      '  ${r.locale}: entries=${r.entryCount}, missing=${r.missingCount}, mojibake=${r.mojibakeCount}, untranslated=${r.untranslatedCount}',
    );
    if (r.untranslatedSamples.isNotEmpty) {
      stdout.writeln('    samples: ${r.untranslatedSamples.join(' | ')}');
    }
  }
}

void _printKeyDump(
    String title, Map<String, Map<String, String>> buckets, String key) {
  stdout.writeln('[$title key dump]');
  stdout.writeln('  key: $key');
  final List<String> locales = buckets.keys.toList()..sort();
  for (final String locale in locales) {
    final String? value = buckets[locale]?[key];
    if (value == null) {
      stdout.writeln('  $locale: <missing>');
      continue;
    }
    stdout.writeln('  $locale: $value');
  }
}

void _printMatchingKeys(
    String title, Map<String, Map<String, String>> buckets, String query) {
  stdout.writeln('[$title key search]');
  stdout.writeln('  query: $query');
  if (buckets.isEmpty) {
    stdout.writeln('  no data');
    return;
  }
  final Set<String> keys = buckets.values.first.keys.toSet();
  final List<String> matches = keys
      .where((String k) => k.toLowerCase().contains(query.toLowerCase().trim()))
      .toList()
    ..sort();
  if (matches.isEmpty) {
    stdout.writeln('  no match');
    return;
  }
  for (final String key in matches) {
    stdout.writeln('  $key');
  }
}

Future<void> main(List<String> args) async {
  final String trEnContent =
      await File('lib/tr_en_phrase_localizations.dart').readAsString();
  final String didContent =
      await File('lib/did_you_know_phrase_localizations.dart').readAsString();

  final Map<String, Map<String, String>> trEn = _parseMapBuckets(
    trEnContent,
    'const Map<String, Map<String, String>> _trEnPhraseLocalizations = {',
  );
  final Map<String, Map<String, String>> did = _parseMapBuckets(
    didContent,
    'const Map<String, Map<String, String>> _didYouKnowPhraseLocalizations = {',
  );

  final List<_CheckResult> trEnResults = _checkBuckets(trEn);
  final List<_CheckResult> didResults = _checkBuckets(did);

  if (args.isNotEmpty) {
    if (args.first == '--dump-tr-en-key' && args.length >= 2) {
      _printKeyDump('tr_en', trEn, args.sublist(1).join(' '));
      return;
    }
    if (args.first == '--dump-did-key' && args.length >= 2) {
      _printKeyDump('did_you_know', did, args.sublist(1).join(' '));
      return;
    }
    if (args.first == '--find-tr-en-key' && args.length >= 2) {
      _printMatchingKeys('tr_en', trEn, args.sublist(1).join(' '));
      return;
    }
    if (args.first == '--find-did-key' && args.length >= 2) {
      _printMatchingKeys('did_you_know', did, args.sublist(1).join(' '));
      return;
    }
  }

  _printReport('tr_en', trEnResults);
  _printReport('did_you_know', didResults);
}
