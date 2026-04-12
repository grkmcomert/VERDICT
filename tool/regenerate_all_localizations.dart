import 'dart:collection';
import 'dart:convert';
import 'dart:io';

class LangSpec {
  const LangSpec({required this.code, required this.apiCode});

  final String code;
  final String apiCode;
}

const List<LangSpec> kTargetLangs = <LangSpec>[
  LangSpec(code: 'de', apiCode: 'de'),
  LangSpec(code: 'ko', apiCode: 'ko'),
  LangSpec(code: 'ja', apiCode: 'ja'),
  LangSpec(code: 'ru', apiCode: 'ru'),
  LangSpec(code: 'pt', apiCode: 'pt'),
  LangSpec(code: 'ar', apiCode: 'ar'),
  LangSpec(code: 'es', apiCode: 'es'),
  LangSpec(code: 'es-mx', apiCode: 'es'),
  LangSpec(code: 'hi', apiCode: 'hi'),
  LangSpec(code: 'hu', apiCode: 'hu'),
  LangSpec(code: 'zh-hans', apiCode: 'zh-CN'),
  LangSpec(code: 'id', apiCode: 'id'),
  LangSpec(code: 'nl', apiCode: 'nl'),
  LangSpec(code: 'fr', apiCode: 'fr'),
  LangSpec(code: 'it', apiCode: 'it'),
  LangSpec(code: 'vi', apiCode: 'vi'),
  LangSpec(code: 'th', apiCode: 'th'),
  LangSpec(code: 'pl', apiCode: 'pl'),
  LangSpec(code: 'ca', apiCode: 'ca'),
  LangSpec(code: 'zh-hant', apiCode: 'zh-TW'),
  LangSpec(code: 'hr', apiCode: 'hr'),
  LangSpec(code: 'cs', apiCode: 'cs'),
  LangSpec(code: 'da', apiCode: 'da'),
  LangSpec(code: 'fi', apiCode: 'fi'),
  LangSpec(code: 'fr-ca', apiCode: 'fr'),
  LangSpec(code: 'el', apiCode: 'el'),
  LangSpec(code: 'he', apiCode: 'he'),
  LangSpec(code: 'ms', apiCode: 'ms'),
  LangSpec(code: 'no', apiCode: 'no'),
  LangSpec(code: 'pt-pt', apiCode: 'pt'),
  LangSpec(code: 'ro', apiCode: 'ro'),
  LangSpec(code: 'sk', apiCode: 'sk'),
  LangSpec(code: 'sv', apiCode: 'sv'),
  LangSpec(code: 'uk', apiCode: 'uk'),
];

const String kSplitToken = '___XQZP_SPLIT_9F3B___';
const List<String> kProtectedStaticTokens = <String>[
  'Professional Social Media Solutions',
];
const Map<String, String> kTranslationSourceOverrides = <String, String>{
  'The lighter was invented before the match—sometimes “old” tech is older than we think.':
      'The lighter was invented before the matchstick—sometimes “old” tech is older than we think.',
  'GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.':
      'GPS is free to use worldwide, but the U.S. government reportedly spends around 2 million U.S. dollars a day to keep it running.',
};

const Map<int, int> _windows125xExtendedByteMap = <int, int>{
  0x20AC: 0x80,
  0x201A: 0x82,
  0x0192: 0x83,
  0x201E: 0x84,
  0x2026: 0x85,
  0x2020: 0x86,
  0x2021: 0x87,
  0x02C6: 0x88,
  0x2030: 0x89,
  0x0160: 0x8A,
  0x2039: 0x8B,
  0x0152: 0x8C,
  0x017D: 0x8E,
  0x2018: 0x91,
  0x2019: 0x92,
  0x201C: 0x93,
  0x201D: 0x94,
  0x2022: 0x95,
  0x2013: 0x96,
  0x2014: 0x97,
  0x02DC: 0x98,
  0x2122: 0x99,
  0x0161: 0x9A,
  0x203A: 0x9B,
  0x0153: 0x9C,
  0x017E: 0x9E,
  0x0178: 0x9F,
  0x011E: 0xD0,
  0x0130: 0xDD,
  0x015E: 0xDE,
  0x011F: 0xF0,
  0x0131: 0xFD,
  0x015F: 0xFE,
};

bool _looksLikeMojibake(String value) {
  if (value.isEmpty) return false;
  if (value.contains('\uFFFD')) return true;
  if (RegExp(r'[\u0080-\u009F]').hasMatch(value)) return true;
  if (value.contains('\u00E2\u20AC')) return true;
  if (RegExp(
    '[\u00C2\u00C3\u00C4\u00C5\u00D0\u00D1]'
    '(?:'
    '[\u0080-\u00BF]'
    '|'
    '[\u0152\u0153\u0160\u0161\u017D\u017E\u0178\u0192\u02C6\u02DC'
    '\u2013\u2014\u2018\u2019\u201A\u201C\u201D\u201E\u2020\u2021\u2022\u2026'
    '\u2030\u2039\u203A\u20AC\u2122]'
    ')',
  ).hasMatch(value)) {
    return true;
  }
  if (value.contains('\u00EF\u00BB\u00BF')) return true;
  return false;
}

int? _byteForMojibakeCodeUnit(int unit) {
  if (unit <= 0x00FF) return unit;
  return _windows125xExtendedByteMap[unit];
}

List<int>? _encodeWindows1252Bytes(String value) {
  final List<int> bytes = <int>[];
  for (final int unit in value.codeUnits) {
    final int? mapped = _byteForMojibakeCodeUnit(unit);
    if (mapped == null) return null;
    bytes.add(mapped);
  }
  return bytes;
}

int _utf8SequenceLength(int? firstByte) {
  if (firstByte == null) return 0;
  if (firstByte >= 0xC2 && firstByte <= 0xDF) return 2;
  if (firstByte >= 0xE0 && firstByte <= 0xEF) return 3;
  if (firstByte >= 0xF0 && firstByte <= 0xF4) return 4;
  return 0;
}

bool _isValidUtf8Sequence(List<int> bytes) {
  if (bytes.length == 3) {
    if ((bytes[0] == 0xE0 && bytes[1] < 0xA0) ||
        (bytes[0] == 0xED && bytes[1] > 0x9F)) {
      return false;
    }
  }
  if (bytes.length == 4) {
    if ((bytes[0] == 0xF0 && bytes[1] < 0x90) ||
        (bytes[0] == 0xF4 && bytes[1] > 0x8F)) {
      return false;
    }
  }
  return true;
}

String _decodeUtf8Fragments(String value) {
  final List<int> units = value.codeUnits;
  final StringBuffer out = StringBuffer();
  int i = 0;
  while (i < units.length) {
    final int? firstByte = _byteForMojibakeCodeUnit(units[i]);
    final int length = _utf8SequenceLength(firstByte);
    if (firstByte == null || length == 0 || i + length > units.length) {
      out.writeCharCode(units[i]);
      i++;
      continue;
    }
    final List<int> bytes = <int>[firstByte];
    bool valid = true;
    for (int j = 1; j < length; j++) {
      final int? nextByte = _byteForMojibakeCodeUnit(units[i + j]);
      if (nextByte == null || nextByte < 0x80 || nextByte > 0xBF) {
        valid = false;
        break;
      }
      bytes.add(nextByte);
    }
    if (!valid || !_isValidUtf8Sequence(bytes)) {
      out.writeCharCode(units[i]);
      i++;
      continue;
    }
    try {
      out.write(utf8.decode(bytes, allowMalformed: false));
      i += length;
    } catch (_) {
      out.writeCharCode(units[i]);
      i++;
    }
  }
  return out.toString();
}

String _repairMojibakeText(String value) {
  if (value.isEmpty) return value;
  if (!_looksLikeMojibake(value)) return value;

  String fixed = value;
  const Map<String, String> replacements = <String, String>{
    '\u00E2\u20AC\u2122': '\u2019',
    '\u00E2\u20AC\u02DC': '\u2018',
    '\u00E2\u20AC\u0153': '\u201C',
    '\u00E2\u20AC\u009D': '\u201D',
    '\u00E2\u20AC\u201C': '\u2013',
    '\u00E2\u20AC\u201D': '\u2014',
    '\u00E2\u20AC\u00A6': '\u2026',
    '\u00C2\u00A0': ' ',
    '\u00C2': '',
  };

  for (int i = 0; i < 8; i++) {
    if (!_looksLikeMojibake(fixed)) break;
    bool changed = false;

    final String fragmentDecoded = _decodeUtf8Fragments(fixed);
    if (fragmentDecoded != fixed) {
      fixed = fragmentDecoded;
      changed = true;
    }

    for (final MapEntry<String, String> entry in replacements.entries) {
      final String next = fixed.replaceAll(entry.key, entry.value);
      if (next != fixed) changed = true;
      fixed = next;
    }

    final List<int>? bytes = _encodeWindows1252Bytes(fixed);
    if (bytes != null) {
      try {
        final String decoded = utf8.decode(bytes, allowMalformed: false);
        if (decoded != fixed) {
          fixed = decoded;
          changed = true;
        }
      } catch (_) {}
    }

    if (!changed) break;
  }

  for (final MapEntry<String, String> entry in replacements.entries) {
    fixed = fixed.replaceAll(entry.key, entry.value);
  }
  return fixed;
}

String _normalizeSourceText(String value) {
  return _repairMojibakeText(value).trim();
}

String _escapeDartDouble(String value) {
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < value.length; i++) {
    final int unit = value.codeUnitAt(i);
    switch (unit) {
      case 0x5C: // \
        out.write(r'\\');
        break;
      case 0x22: // "
        out.write(r'\"');
        break;
      case 0x24: // $
        out.write(r'\$');
        break;
      case 0x0A: // \n
        out.write(r'\n');
        break;
      case 0x0D: // \r
        out.write(r'\r');
        break;
      case 0x09: // \t
        out.write(r'\t');
        break;
      default:
        out.writeCharCode(unit);
    }
  }
  return out.toString();
}

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

class Translator {
  Translator();

  final HttpClient _http = HttpClient();
  final Map<String, String> _cache = <String, String>{};

  Future<String> translateSingle(String text, String target) async {
    final String source = _normalizeSourceText(text);
    if (source.isEmpty) return source;
    final String cacheKey = '$target::$source';
    final String? cached = _cache[cacheKey];
    if (cached != null) return cached;

    final Map<String, String> tokenMap = <String, String>{};
    final String protected = _protectText(source, tokenMap);
    final String translatedProtected =
        await _translateRaw(protected, target).onError((_, __) => protected);
    final String restored = _restoreText(translatedProtected, tokenMap).trim();
    final String finalText = restored.isEmpty ? source : restored;
    _cache[cacheKey] = finalText;
    return finalText;
  }

  Future<List<String>> translateBatch(List<String> texts, String target) async {
    if (texts.isEmpty) return <String>[];
    if (texts.length == 1) {
      return <String>[await translateSingle(texts.first, target)];
    }

    Future<List<String>> splitAndTranslate(List<String> source) async {
      if (source.isEmpty) return <String>[];
      if (source.length == 1) {
        return <String>[await translateSingle(source.first, target)];
      }
      final int mid = source.length ~/ 2;
      final List<String> left =
          await translateBatch(source.sublist(0, mid), target);
      final List<String> right =
          await translateBatch(source.sublist(mid), target);
      return <String>[...left, ...right];
    }

    final List<String> cleaned = texts
        .map((String t) => _normalizeSourceText(t))
        .toList(growable: false);
    final List<Map<String, String>> tokenMaps = <Map<String, String>>[];
    final List<String> protected = <String>[];
    for (final String text in cleaned) {
      final Map<String, String> tokens = <String, String>{};
      tokenMaps.add(tokens);
      protected.add(_protectText(text, tokens));
    }
    final String payload = protected.join('\n$kSplitToken\n');
    if (payload.length > 3000) {
      return splitAndTranslate(texts);
    }

    final String translatedPayload =
        await _translateRaw(payload, target).onError((_, __) => payload);
    if (translatedPayload == payload) {
      return splitAndTranslate(texts);
    }

    List<String> parts = translatedPayload.split(kSplitToken);
    if (parts.length != texts.length) {
      return splitAndTranslate(texts);
    }
    for (int i = 0; i < parts.length; i++) {
      parts[i] = _restoreText(parts[i], tokenMaps[i]).trim();
      if (parts[i].isEmpty) parts[i] = cleaned[i];
    }
    return parts;
  }

  Future<void> close() async {
    _http.close(force: true);
  }

  String _protectText(String input, Map<String, String> tokenMap) {
    String out = input;
    int counter = 0;

    String putToken(String value, {String prefix = 'XQZP'}) {
      final String token = '${prefix}_${counter++}_TOKEN';
      tokenMap[token] = value;
      return token;
    }

    for (final String staticToken in kProtectedStaticTokens) {
      out = out.replaceAllMapped(
        RegExp(RegExp.escape(staticToken)),
        (Match m) => putToken(m.group(0)!, prefix: 'XQZP_STATIC'),
      );
    }

    out = out.replaceAllMapped(
      RegExp(
        r'\$[0-9]+(?:[.,][0-9]+)?(?:\s?(?:million|billion|trillion))?',
        caseSensitive: false,
      ),
      (Match m) => putToken(m.group(0)!, prefix: 'XQZP_MONEY'),
    );

    out = out.replaceAllMapped(RegExp(r'\{[a-zA-Z0-9_]+\}'), (Match m) {
      return putToken(m.group(0)!, prefix: 'XQZP_VAR');
    });

    out = out.replaceAllMapped(RegExp(r'\$[a-zA-Z_][a-zA-Z0-9_]*'), (Match m) {
      return putToken(m.group(0)!, prefix: 'XQZP_DOLLAR');
    });

    return out;
  }

  String _restoreText(String input, Map<String, String> tokenMap) {
    String out = input;
    final List<String> keys = tokenMap.keys.toList()
      ..sort((String a, String b) => b.length.compareTo(a.length));
    for (final String key in keys) {
      out = out.replaceAll(key, tokenMap[key]!);
    }
    return out;
  }

  Future<String> _translateRaw(String text, String target) async {
    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final Uri uri = Uri.parse(
          'https://translate.googleapis.com/translate_a/single'
          '?client=gtx&sl=en&tl=${Uri.encodeQueryComponent(target)}&dt=t'
          '&q=${Uri.encodeQueryComponent(text)}',
        );
        final HttpClientRequest request = await _http.getUrl(uri);
        final HttpClientResponse response = await request.close();
        if (response.statusCode != 200) {
          throw HttpException('Translate HTTP ${response.statusCode}');
        }
        final String raw = await response.transform(utf8.decoder).join();
        final dynamic decoded = jsonDecode(raw);
        if (decoded is! List || decoded.isEmpty || decoded.first is! List) {
          throw const FormatException('Unexpected translation response shape');
        }
        final List<dynamic> segments = decoded.first as List<dynamic>;
        final StringBuffer out = StringBuffer();
        for (final dynamic item in segments) {
          if (item is List && item.isNotEmpty && item.first is String) {
            out.write(item.first as String);
          }
        }
        return out.toString();
      } catch (e) {
        lastError = e;
        await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    throw StateError('Translation failed: $lastError');
  }
}

String _replaceConstMapBody(
    String content, String mapDeclMarker, String newBodyWithLeadingNewline) {
  final int start = content.indexOf(mapDeclMarker);
  if (start < 0) {
    throw StateError('Map marker not found: $mapDeclMarker');
  }
  final int open = content.indexOf('{', start);
  final int close = content.indexOf('\n};', open);
  if (open < 0 || close < 0) {
    throw StateError('Could not locate map boundaries: $mapDeclMarker');
  }
  return content.replaceRange(open + 1, close, newBodyWithLeadingNewline);
}

String _buildLanguageBucket(String code, List<String> orderedKeys,
    Map<String, String> translatedByKey) {
  final StringBuffer out = StringBuffer();
  out.writeln("  '$code': {");
  for (final String key in orderedKeys) {
    final String translated = translatedByKey[key] ?? key;
    out.writeln(
      '    "${_escapeDartDouble(key)}": "${_escapeDartDouble(translated)}",',
    );
  }
  out.writeln('  },');
  return out.toString();
}

List<String> _collectNeededPhrases(String mainContent) {
  final LinkedHashSet<String> out = LinkedHashSet<String>();

  void addPhrase(String raw) {
    final String clean = _normalizeSourceText(raw);
    if (clean.isNotEmpty) out.add(clean);
  }

  final RegExp localizeCallRe = RegExp(
    r'''localizeTrEn\([^,]+,\s*(?:'((?:\\.|[^'])*)'|"((?:\\.|[^"])*)")\s*,\s*(?:'((?:\\.|[^'])*)'|"((?:\\.|[^"])*)")\s*\)''',
    dotAll: true,
  );
  for (final RegExpMatch m in localizeCallRe.allMatches(mainContent)) {
    final String? enRaw = m.group(3) ?? m.group(4);
    if (enRaw != null) addPhrase(_unescapeDartLiteralBody(enRaw));
  }

  String sliceBetween(String anchorStart, String anchorEnd, {int from = 0}) {
    final int s = mainContent.indexOf(anchorStart, from);
    if (s < 0) return '';
    final int e = mainContent.indexOf(anchorEnd, s + anchorStart.length);
    if (e < 0) return '';
    return mainContent.substring(s, e);
  }

  final int localizedIdx = mainContent
      .indexOf('final Map<String, Map<String, String>> _localized = {');
  final String localizedEnBlock = sliceBetween(
    "'en': {",
    "\n    'de': {",
    from: localizedIdx,
  );
  final RegExp mapValueRe = RegExp(
    r'''^\s{6}(?:'(?:\\.|[^'])*'|"(?:\\.|[^"])*")\s*:\s*(?:'((?:\\.|[^'])*)'|"((?:\\.|[^"])*)")\s*,''',
    multiLine: true,
    dotAll: true,
  );
  for (final RegExpMatch m in mapValueRe.allMatches(localizedEnBlock)) {
    final String? raw = m.group(1) ?? m.group(2);
    if (raw != null) addPhrase(_unescapeDartLiteralBody(raw));
  }

  final int flowIdx = mainContent
      .indexOf('final Map<String, Map<String, String>> _flowLocalized = {');
  final String flowEnBlock = sliceBetween(
    '"en": {',
    '\n    "de": {',
    from: flowIdx,
  );
  final RegExp flowValueRe = RegExp(
    r'''^\s{6}(?:"(?:\\.|[^"])*"|'(?:\\.|[^'])*')\s*:\s*(?:"((?:\\.|[^"])*)"|'((?:\\.|[^'])*)')\s*,''',
    multiLine: true,
    dotAll: true,
  );
  for (final RegExpMatch m in flowValueRe.allMatches(flowEnBlock)) {
    final String? raw = m.group(1) ?? m.group(2);
    if (raw != null) addPhrase(_unescapeDartLiteralBody(raw));
  }

  const List<String> mapNames = <String>[
    '_startupLoadingLabels',
    '_didYouKnowLabels',
    '_analysisRemainingTimeLabels',
    '_analysisRemainingPreparingLabels',
    '_logoutButtonLabels',
    '_detailOpenProfileLabels',
  ];
  for (final String name in mapNames) {
    final int idx = mainContent.indexOf('const Map<String, String> $name');
    if (idx < 0) continue;
    final int open = mainContent.indexOf('{', idx);
    final int close = mainContent.indexOf('\n};', open);
    if (open < 0 || close < 0) continue;
    final String block = mainContent.substring(open + 1, close);
    final RegExp enEntryRe = RegExp(
      r'''^\s*'en'\s*:\s*(?:'((?:\\.|[^'])*)'|"((?:\\.|[^"])*)")\s*,''',
      multiLine: true,
      dotAll: true,
    );
    final RegExpMatch? m = enEntryRe.firstMatch(block);
    if (m != null) {
      final String? raw = m.group(1) ?? m.group(2);
      if (raw != null) addPhrase(_unescapeDartLiteralBody(raw));
    }
  }

  final int factsStart = mainContent
      .indexOf('const List<Map<String, String>> _analysisDidYouKnowFacts = [');
  if (factsStart >= 0) {
    final int factsEnd = mainContent.indexOf('\n];', factsStart);
    if (factsEnd > factsStart) {
      final String facts = mainContent.substring(factsStart, factsEnd);
      final RegExp factEnRe = RegExp(
        r'''^\s*'en'\s*:\s*(?:'((?:\\.|[^'])*)'|"((?:\\.|[^"])*)")\s*,''',
        multiLine: true,
        dotAll: true,
      );
      for (final RegExpMatch m in factEnRe.allMatches(facts)) {
        final String? raw = m.group(1) ?? m.group(2);
        if (raw != null) addPhrase(_unescapeDartLiteralBody(raw));
      }
    }
  }

  return out.toList(growable: false);
}

List<String> _collectDidYouKnowFacts(String mainContent) {
  final LinkedHashSet<String> out = LinkedHashSet<String>();
  final int factsStart = mainContent
      .indexOf('const List<Map<String, String>> _analysisDidYouKnowFacts = [');
  if (factsStart < 0) return <String>[];

  final int factsEnd = mainContent.indexOf('\n];', factsStart);
  if (factsEnd <= factsStart) return <String>[];

  final String facts = mainContent.substring(factsStart, factsEnd);
  final RegExp factEnRe = RegExp(
    r'''^\s*'en'\s*:\s*(?:'((?:\\.|[^'])*)'|"((?:\\.|[^"])*)")\s*,''',
    multiLine: true,
    dotAll: true,
  );
  for (final RegExpMatch m in factEnRe.allMatches(facts)) {
    final String? raw = m.group(1) ?? m.group(2);
    if (raw == null) continue;
    final String clean = _normalizeSourceText(_unescapeDartLiteralBody(raw));
    if (clean.isNotEmpty) out.add(clean);
  }
  return out.toList(growable: false);
}

Future<void> main() async {
  final File mainFile = File('lib/main.dart');
  final File phraseFile = File('lib/tr_en_phrase_localizations.dart');
  final File didFile = File('lib/did_you_know_phrase_localizations.dart');

  final String mainContent = await mainFile.readAsString();
  final List<String> phraseKeys = _collectNeededPhrases(mainContent);
  final List<String> didFacts = _collectDidYouKnowFacts(mainContent);
  if (phraseKeys.isEmpty) {
    throw StateError('No phrase keys collected from main.dart');
  }
  if (didFacts.isEmpty) {
    throw StateError('No did-you-know fact keys collected from main.dart');
  }

  stdout.writeln('[collect] phrase keys: ${phraseKeys.length}');
  stdout.writeln('[collect] did-you-know facts: ${didFacts.length}');

  final Translator translator = Translator();
  try {
    final String phraseContent = await phraseFile.readAsString();
    final StringBuffer phraseBuckets = StringBuffer();

    for (final LangSpec lang in kTargetLangs) {
      final Map<String, String> byKey = <String, String>{};
      for (final String key in phraseKeys) {
        final String source = kTranslationSourceOverrides[key] ?? key;
        final String translated =
            await translator.translateSingle(source, lang.apiCode);
        byKey[key] = _normalizeSourceText(translated);
      }
      phraseBuckets.writeln(_buildLanguageBucket(lang.code, phraseKeys, byKey));
      stdout.writeln('[tr_en] generated ${lang.code} (${phraseKeys.length})');
    }

    final String updatedPhraseContent = _replaceConstMapBody(
      phraseContent,
      'const Map<String, Map<String, String>> _trEnPhraseLocalizations = {',
      '\n${phraseBuckets.toString().trimRight()}\n',
    );
    await phraseFile.writeAsString(updatedPhraseContent);

    final String didContent = await didFile.readAsString();
    final StringBuffer didBuckets = StringBuffer();
    for (final LangSpec lang in kTargetLangs) {
      final Map<String, String> byKey = <String, String>{};
      for (final String key in didFacts) {
        final String source = kTranslationSourceOverrides[key] ?? key;
        final String translated =
            await translator.translateSingle(source, lang.apiCode);
        byKey[key] = _normalizeSourceText(translated);
      }
      didBuckets.writeln(_buildLanguageBucket(lang.code, didFacts, byKey));
      stdout.writeln('[did] generated ${lang.code} (${didFacts.length})');
    }

    final String updatedDidContent = _replaceConstMapBody(
      didContent,
      'const Map<String, Map<String, String>> _didYouKnowPhraseLocalizations = {',
      '\n${didBuckets.toString().trimRight()}\n',
    );
    await didFile.writeAsString(updatedDidContent);

    stdout.writeln('Localization regeneration complete.');
  } finally {
    await translator.close();
  }
}
