import 'dart:convert';

// Auto-generated did-you-know phrase localizations.
// Source language key is the English phrase used in _analysisDidYouKnowFacts.

bool _looksLikeMojibake(String value) {
  if (value.isEmpty) return false;
  if (value.contains('\uFFFD')) return true;
  if (_mojibakeC1Pattern.hasMatch(value)) return true;
  if (value.contains('\u00E2\u20AC')) return true; // " "
  if (_mojibakeMarkerPattern.hasMatch(value)) return true;
  if (value.contains('\u00EF\u00BB\u00BF')) return true; // ""
  return false;
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

String _cleanDidYouKnowText(String value) {
  return _repairMojibakeText(value).trim();
}

String _normalizeDidYouKnowLookupKey(String value) {
  final String repaired = _repairMojibakeText(value);
  return repaired.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _looksLowQualityDidYouKnowText(String localized, String sourceEn) {
  final String loc = localized.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (loc.isEmpty) return true;
  return false;
}

String? _findLocalizedPhrase(
    Map<String, String>? localizedMap, String enPhrase) {
  if (localizedMap == null) return null;

  final String? direct = localizedMap[enPhrase];
  if (direct != null) return direct;

  final String lookupKey = _normalizeDidYouKnowLookupKey(enPhrase);
  for (final MapEntry<String, String> entry in localizedMap.entries) {
    if (_normalizeDidYouKnowLookupKey(entry.key) == lookupKey) {
      return entry.value;
    }
  }
  return null;
}

String _normalizeDidYouKnowLang(String lang) {
  final String code = lang.trim().toLowerCase().replaceAll('_', '-');
  if (code.isEmpty) return 'en';
  if (code == 'in') return 'id'; // Indonesian alias fix
  if (code.startsWith('es-')) {
    if (code == 'es-mx' || code == 'es-419') return 'es-mx';
    return 'es';
  }
  if (code.startsWith('zh')) {
    if (code.contains('hant') ||
        code.endsWith('-tw') ||
        code.endsWith('-hk') ||
        code.endsWith('-mo')) {
      return 'zh-hant';
    }
    return 'zh-hans';
  }
  return code;
}

String? localizeDidYouKnowPhrase(String lang, String enPhrase) {
  final String normalized = _normalizeDidYouKnowLang(lang);
  String? translated = _findLocalizedPhrase(
      _didYouKnowPhraseLocalizations[normalized], enPhrase);

  // If es-mx misses a phrase, fall back to es.
  if (translated == null && normalized == 'es-mx') {
    translated =
        _findLocalizedPhrase(_didYouKnowPhraseLocalizations['es'], enPhrase);
  }

  if (translated == null) return null;
  final String clean = _cleanDidYouKnowText(translated);
  if (clean.isEmpty ||
      _looksLowQualityDidYouKnowText(clean, enPhrase) ||
      _looksLikeMojibake(clean)) {
    return null;
  }
  return clean;
}

const Map<String, Map<String, String>> _didYouKnowPhraseLocalizations = {
  'de': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Krähen erkennen nicht nur menschliche Gesichter; Sie können sich an Menschen erinnern, die sie jahrelang schlecht behandelt haben – und sogar andere Krähen warnen.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Katzen verbringen etwa 70 % ihres Lebens schlafend – eine 10-jährige Katze ist also erst seit etwa 3 Jahren wach.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Honig verdirbt nie; Archäologen haben in ägyptischen Pyramiden 3.000 Jahre alte Honiggläser gefunden, die noch essbar waren.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Seeotter halten sich im Schlaf an den Händen, damit sie in der Strömung nicht auseinanderdriften.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Auf der Venus ist ein Tag länger als ein Jahr – sie dreht sich langsamer um ihre Achse, als sie die Sonne umkreist.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Das Feuerzeug wurde vor dem Streichholz erfunden – manchmal ist „alte“ Technik älter als wir denken.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Kraken haben drei Herzen und neun Gehirne – Dinge zu vergessen ist eigentlich keine Option.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Kühe haben „beste Freunde“ und sie können ernsthaft gestresst sein – und sogar weinen –, wenn sie getrennt werden.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Der erste Computervirus der Welt hieß „Creeper“ und zeigte: „Ich bin der Creeper, fang mich, wenn du kannst!“",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Eine durchschnittliche Wolke kann etwa 500.000 kg wiegen – wie eine riesige Elefantenherde, die über ihnen schwebt.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Die menschliche DNA ist der Bananen-DNA zu etwa 50 % ähnlich – daher ist es nicht völlig unfair, morgen früh eine Banane „mein Geschwister“ zu nennen.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Eisbären haben tatsächlich schwarze Haut und ihr Fell ist durchsichtig; Sie sehen aufgrund der Lichtstreuung weiß aus.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Im Weltraum kann man nicht wirklich weinen: Ohne die Schwerkraft laufen einem die Tränen nicht übers Gesicht, sondern bilden einen Klumpen im Auge.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Der Mount Everest wächst jedes Jahr um etwa 4 Millimeter – die Erde verändert sich immer noch.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "„Pfeifende“ Mäuse singen im Wesentlichen miteinander, allerdings mit einer Frequenz, die zu hoch ist, als dass Menschen sie hören könnten.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Haie sind älter als Bäume – Haie gibt es seit etwa 400 Millionen Jahren, Bäume seit etwa 350 Millionen Jahren.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Bananen sind botanisch gesehen Beeren, Erdbeeren jedoch nicht – die Botanik kann seltsam sein.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Eine Ameise kann bis zum 50-fachen ihres eigenen Gewichts heben – wenn Sie eine Ameise wären, könnten Sie selbst ein Auto heben.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Durch die Wärmeausdehnung kann der Eiffelturm im Sommer um etwa 15 Zentimeter wachsen.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Das Gesamtgewicht aller Menschen auf der Erde ist in etwa vergleichbar mit dem Gesamtgewicht aller Ameisen.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Faultiere können unter Wasser ihren Atem länger anhalten als Delfine – bis zu etwa 40 Minuten.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Tauben können den Unterschied zwischen Gemälden von Picasso und Monet erkennen – es stellt sich heraus, dass sie kunstbewusster sind, als wir denken.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Die Nutzung von GPS ist weltweit kostenlos, aber die US-Regierung gibt Berichten zufolge täglich rund 2 Millionen US-Dollar aus, um es am Laufen zu halten.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Schnabeltiere haben keinen Magen – die Nahrung gelangt von der Speiseröhre direkt in den Darm.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare wird die erste dokumentierte Verwendung des Wortes „Swagger“ zugeschrieben – er hatte schon im 16. Jahrhundert Stil.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Das Herz eines Blauwals ist so groß, dass ein Mensch durch seine Hauptarterien schwimmen könnte.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Ameisen haben keine Lungen – und sie „schlafen“ nie wirklich; Sie arbeiten ununterbrochen wie kleine Workaholics.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Auf Saturn und Jupiter kann es buchstäblich Diamanten regnen – offenbar leben wir auf dem falschen Planeten.",
    "Honeybees can recognize human faces and remember them individually.":
        "Honigbienen können menschliche Gesichter erkennen und sich individuell an sie erinnern.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Hippo-„Schweiß“ kann rosa aussehen und wirkt sowohl als Sonnenschutz als auch als antibakterieller Schutzschild.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Wombat-Kot ist würfelförmig, sodass er nicht wegrollt und das Revier effektiver markieren kann.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Cashewnüsse wachsen außerhalb des Cashewapfels und hängen ganz am Ende – ein seltsam überraschendes Design.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Haie sind älter als die Saturnringe – sie existierten etwa Millionen Jahre, bevor Saturn seinen berühmten Schmuck bekam.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Schmetterlinge schmecken mit ihren Füßen – wenn sie auf einem Blatt landen, probieren sie im Grunde ein Abendessen.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Eine Schnecke kann bis zu drei Jahre lang schlafen, ohne aufzuwachen – ehrlich gesagt, nachvollziehbar.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Die Augen eines Straußes sind größer als sein Gehirn – sie bewegen sich auf dem schmalen Grat zwischen Sehen und Denken.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingos werden grau geboren; Ihr berühmtes Rosa kommt von Pigmenten in Garnelen und Algen, die sie fressen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Eichhörnchen helfen jedes Jahr dabei, Tausende neuer Bäume wachsen zu lassen, weil sie vergessen, wo sie Nüsse vergraben haben.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Das erste Videospiel, das im Weltraum gespielt wurde, war Tetris – 1993 von einem Kosmonauten auf einem Game Boy gespielt.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Spechte wickeln ihre Zunge um ihr Gehirn, um Gehirnerschütterungen zu vermeiden – die Zunge als Helm zu verwenden, ist eine wilde Lösung.",
  },
  'ko': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "까마귀는 사람의 얼굴만 인식하는 것이 아닙니다. 그들은 수년 동안 자신을 나쁘게 대했던 사람들을 기억할 수 있고 심지어 다른 까마귀들에게 경고할 수도 있습니다.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "고양이는 인생의 약 70%를 잠으로 보냅니다. 따라서 10살 된 고양이는 깨어 있는 기간이 약 3년에 불과합니다.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "꿀은 결코 상하지 않습니다. 고고학자들은 이집트 피라미드에서 여전히 먹을 수 있는 3,000년 된 꿀병을 발견했습니다.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "해달은 잠을 잘 때 손을 잡고 물살에 흩어지지 않도록 합니다.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "금성에서는 하루가 1년보다 길기 때문에 태양을 공전하는 것보다 축을 중심으로 더 천천히 회전합니다.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "라이터는 성냥개비보다 먼저 발명되었습니다. 때로는 \"오래된\" 기술이 우리가 생각하는 것보다 오래되었습니다.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "문어는 3개의 심장과 9개의 뇌를 가지고 있습니다. 잊어버리는 것은 실제로 선택 사항이 아닙니다.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "소에게는 “가장 친한 친구”가 있으며, 떨어져 있을 때 심각한 스트레스를 받을 수 있으며 심지어 울 수도 있습니다.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "세계 최초의 컴퓨터 바이러스는 \"크리퍼(Creeper)\"라고 불리며 \"내가 크리퍼입니다. 잡을 수 있으면 잡아주세요!\"라는 문구가 표시되었습니다.",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "평균 구름의 무게는 약 500,000kg에 달합니다. 마치 머리 위로 떠다니는 거대한 코끼리 떼와 같습니다.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "인간 DNA는 바나나 DNA와 약 50% 유사합니다. 따라서 내일 아침 바나나를 \"내 형제\"라고 부르는 것은 완전히 불공평한 것은 아닙니다.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "북극곰은 실제로 검은 피부를 가지고 있고 털은 투명합니다. 빛이 산란되는 방식 때문에 흰색으로 보입니다.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "우주에서는 실제로 울 수 없습니다. 중력이 없으면 눈물이 얼굴로 흘러내리지 않고 눈에 방울을 형성합니다.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "에베레스트 산은 매년 약 4mm씩 계속해서 성장하고 있습니다. 지구는 여전히 변화하고 있습니다.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "\"휘파람을 부는\" 쥐는 본질적으로 서로에게 노래를 부르지만, 그 주파수는 인간이 들을 수 없을 정도로 너무 높습니다.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "상어는 나무보다 나이가 많습니다. 상어는 약 4억 년, 나무는 약 3억 5천만 년 동안 존재했습니다.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "바나나는 식물학적으로 열매이지만 딸기는 그렇지 않습니다. 식물학은 이상할 수 있습니다.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "개미는 자신의 몸무게의 50배까지 들어 올릴 수 있습니다. 개미라면 혼자서 차도 들어 올릴 수 있습니다.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "에펠탑은 여름에 열팽창으로 인해 약 15cm 정도 자랄 수 있습니다.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "지구상의 모든 인간의 총 무게는 모든 개미의 총 무게와 대략 비슷합니다.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "나무늘보는 물속에서 돌고래보다 더 오랫동안(최대 약 40분) 숨을 참을 수 있습니다.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "비둘기는 피카소와 모네의 그림을 구별할 수 있습니다. 알고 보니 그 그림은 우리가 생각하는 것보다 예술에 더 정통한 것으로 나타났습니다.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS는 전 세계적으로 무료로 사용할 수 있지만 미국 정부는 이를 유지하기 위해 하루 약 200만 달러를 지출하는 것으로 알려졌다.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "오리너구리에는 위가 없습니다. 음식은 식도에서 곧바로 장으로 이동합니다.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "윌리엄 셰익스피어는 \"swagger\"라는 단어를 처음으로 사용한 것으로 기록되어 있습니다. 16세기에도 그에게는 스타일이 있었습니다.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "대왕고래의 심장은 인간이 주요 동맥을 헤엄쳐 지나갈 수 있을 만큼 크다.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "개미는 폐가 없으며 결코 진정으로 \"잠\"을 자지 않습니다. 그들은 작은 일벌레처럼 쉬지 않고 일합니다.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "토성과 목성에서는 문자 그대로 다이아몬드 비가 내릴 수 있습니다. 분명히 우리는 잘못된 행성에 살고 있습니다.",
    "Honeybees can recognize human faces and remember them individually.":
        "꿀벌은 사람의 얼굴을 인식하고 개별적으로 기억할 수 있습니다.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "하마의 “땀”은 분홍색으로 보일 수 있으며 자외선 차단제와 항균막 역할을 합니다.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "웜뱃의 똥은 큐브 형태이기 때문에 굴러가지 않고 더욱 효과적으로 영역을 표시할 수 있습니다.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "캐슈넛은 캐슈사과 외부에서 자라서 맨 끝에 매달려 있습니다. 이상하게도 놀라운 디자인입니다.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "상어는 토성의 고리보다 나이가 많습니다. 토성이 그 유명한 블링블링을 갖기 약 수백만 년 전입니다.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "나비는 발로 맛을 봅니다. 나뭇잎에 앉으면 기본적으로 저녁 식사를 맛보게 됩니다.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "달팽이는 깨어나지 않고 최대 3년 동안 잠을 잘 수 있습니다. 솔직히 말해서 공감할 수 있는 일입니다.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "타조의 눈은 뇌보다 큽니다. 보는 것과 생각하는 것 사이의 미세한 경계에 살고 있습니다.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "플라밍고는 회색으로 태어났습니다. 그들의 유명한 분홍색은 그들이 먹는 새우와 해조류의 색소에서 나옵니다.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "다람쥐는 견과류를 어디에 묻었는지 잊어버리기 때문에 매년 수천 그루의 새로운 나무가 자라는 데 도움을 줍니다.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "우주에서 플레이된 최초의 비디오 게임은 1993년 우주비행사가 게임보이로 플레이한 테트리스였습니다.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "딱따구리는 뇌진탕을 피하기 위해 혀로 뇌를 감쌉니다. 혀를 헬멧으로 사용하는 것은 획기적인 해결책입니다.",
  },
  'ja': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "カラスは人間の顔を認識するだけではありません。彼らは何年にもわたって自分たちにひどい仕打ちをした人々のことを覚えていて、他のカラスに警告することさえできます。",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "猫は一生の約 70% を眠って過ごします。つまり、10 歳の猫が起きているのはわずか 3 年ほどです。",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "蜂蜜は腐ることはありません。考古学者らは、エジプトのピラミッドでまだ食べられる3,000年前の蜂蜜の瓶を発見した。",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "ラッコは流れの中で離れ離れにならないように手をつないで寝ます。",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "金星の 1 日は 1 年よりも長く、金星は太陽の周りを回るよりもゆっくりと自転します。",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "ライターはマッチ棒よりも前に発明されました。「古い」技術は私たちが思っているよりも古い場合があります。",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "タコには 3 つの心臓と 9 つの脳があり、物を忘れることは実際にはありません。",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "牛には「親友」がおり、離れると深刻なストレスを感じ、泣くこともあります。",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "世界初のコンピューター ウイルスは「クリーパー」と呼ばれ、「私はクリーパーです、できれば捕まえてください!」と表示されました。",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "平均的な雲の重さは約 500,000 kg あり、頭上に浮かぶ巨大な象の群れに似ています。",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "人間の DNA はバナナの DNA と約 50% 似ているため、明日の朝バナナを「私の兄弟」と呼ぶのは完全に不公平というわけではありません。",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "ホッキョクグマの肌は実際には黒く、毛皮は透明です。光が散乱するため白く見えます。",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "宇宙では本当に泣くことはできません。重力がなければ、涙は顔に流れ落ちず、目に塊ができます。",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "エベレストは毎年約 4 ミリメートルずつ成長し続けており、地球は依然として変化しています。",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "「口笛を吹く」ネズミは基本的に互いに歌を歌っていますが、その周波数は人間には聞き取れないほど高すぎます。",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "サメは木よりも古く、サメは約 4 億年前から存在し、木は約 3 億 5,000 万年前から存在しています。",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "バナナは植物学的には果実ですが、イチゴはそうではありません。植物学は奇妙な場合があります。",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "アリは自分の体重の 50 倍もの重量を持ち上げることができます。あなたがアリだったら、一人で車を持ち上げることができるでしょう。",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "エッフェル塔は夏には熱膨張により約15センチ伸びることがあります。",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "地球上の全人類の総重量は、すべてのアリの総重量にほぼ匹敵します。",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "ナマケモノはイルカよりも長く水中で息を止めることができます（最長約 40 分）。",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "ハトはピカソとモネの絵の違いを見分けることができ、ハトは私たちが思っているよりも芸術に精通していることが判明しました。",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS は世界中で無料で使用できますが、米国政府はそれを維持するために 1 日あたり約 200 万ドルを費やしていると伝えられています。",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "カモノハシには胃がありません。食べ物は食道から直接腸に送られます。",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "ウィリアム・シェイクスピアは、「闊歩する」という言葉を初めて記録に基づいて使用したとされており、16 世紀であっても、彼にはスタイルがありました。",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "シロナガスクジラの心臓は、人間がその大動脈を泳いで通れるほど大きい。",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "アリには肺がありません。そして、アリは本当に「眠る」ことはありません。彼らは小さな仕事中毒者のようにノンストップで活動します。",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "土星と木星では、文字通りダイヤモンドの雨が降ることがあります。どうやら、私たちは間違った惑星に住んでいるように見えます。",
    "Honeybees can recognize human faces and remember them individually.":
        "ミツバチは人間の顔を認識し、個別に記憶することができます。",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "カバの「汗」はピンク色に見え、日焼け止めと抗菌シールドの両方の役割を果たします。",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "ウォンバットの糞は立方体の形をしているため、転がることがなく、より効果的に縄張りをマークすることができます。",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "カシューナッツはカシューアップルの外側に生え、最後にぶら下がっています。奇妙に驚くべきデザインです。",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "サメは土星の輪よりも古く、土星が有名な輝きを持つようになる数百万年前に存在しました。",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "蝶は足で味を感じます。葉に止まるとき、彼らは基本的に夕食を試食しているのです。",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "カタツムリは最長 3 年間目覚めずに眠ることができます。正直言って、とても共感できます。",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "ダチョウの目は脳よりも大きく、見ることと考えることの紙一重で生きています。",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "フラミンゴは生まれつき灰色です。彼らの有名なピンク色は、彼らが食べるエビや藻類の色素に由来しています。",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "リスは木の実を埋めた場所を忘れてしまうため、毎年何千本もの新しい木を育てるのに役立っています。",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "宇宙でプレイされた最初のビデオ ゲームはテトリスで、1993 年に宇宙飛行士がゲームボーイでプレイしました。",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "キツツキは脳震盪を避けるために舌を脳に巻き付けます。舌をヘルメットとして使うのは、思いがけない解決策です。",
  },
  'ru': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Вороны не просто распознают человеческие лица; они могут годами помнить людей, которые плохо с ними обращались, и даже предупреждать других ворон.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Кошки проводят во сне около 70% своей жизни, то есть 10-летний кот бодрствует всего около 3 лет.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Мед никогда не портится; археологи нашли в египетских пирамидах 3000-летние банки с медом, которые до сих пор были съедобны.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Морские выдры держатся за руки во время сна, чтобы их не разнесло течением.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "На Венере день длиннее года — она вращается вокруг своей оси медленнее, чем вращается вокруг Солнца.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Зажигалка была изобретена до появления спичек — иногда «старые» технологии старше, чем мы думаем.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "У осьминогов три сердца и девять мозгов, поэтому забывать что-то — не вариант.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "У коров есть «лучшие друзья», и они могут испытывать серьезный стресс и даже плакать, когда их разлучают.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Первый в мире компьютерный вирус назывался «Крипер», и на нем было написано: «Я крипер, поймай меня, если сможешь!»",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Среднее облако может весить около 500 000 кг — как огромное стадо слонов, плывущее над головой.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "ДНК человека примерно на 50% похожа на ДНК банана, поэтому завтра утром называть банан «моим братом или сестрой» не совсем несправедливо.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "У белых медведей на самом деле кожа черная, а мех прозрачный; они выглядят белыми из-за рассеивания света.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "В космосе плакать по-настоящему нельзя: без гравитации слезы не текут по лицу — они образуют комок в глазу.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Гора Эверест продолжает расти примерно на 4 миллиметра каждый год — Земля все еще меняется.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "«Свистящие» мыши по сути поют друг другу, но на частотах, слишком высоких, чтобы люди могли их услышать.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Акулы старше деревьев: акулы существуют около 400 миллионов лет, деревья — около 350 миллионов.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Бананы с ботанической точки зрения являются ягодами, а клубника — нет. Ботаника может быть странной.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Муравей может поднять вес, в 50 раз превышающий его собственный. Если бы вы были муравьем, вы могли бы поднять машину самостоятельно.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Эйфелева башня летом может вырасти примерно на 15 сантиметров из-за теплового расширения.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Общий вес всех людей на Земле примерно сопоставим с общим весом всех муравьев.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Ленивцы могут задерживать дыхание под водой дольше, чем дельфины — примерно до 40 минут.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Голуби могут отличить картины Пикассо от Моне — оказывается, они более подкованы в искусстве, чем мы думаем.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS можно использовать бесплатно во всем мире, но, как сообщается, правительство США тратит около 2 миллионов долларов США в день на его поддержание.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Желудков у утконосов нет — пища попадает из пищевода прямо в кишечник.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Уильяму Шекспиру приписывают первое зарегистрированное использование слова «чванство» — даже в 16 веке у него был стиль.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Сердце синего кита настолько велико, что человек может проплыть по его основным артериям.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "У муравьев нет легких, и они никогда по-настоящему не «спят»; они работают без перерыва, как крошечные трудоголики.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "На Сатурне и Юпитере может идти буквально алмазный дождь — видимо, мы живем не на той планете.",
    "Honeybees can recognize human faces and remember them individually.":
        "Медоносные пчелы могут распознавать человеческие лица и запоминать их по отдельности.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "«Пот» бегемота может выглядеть розовым и действует как солнцезащитный крем, так и как антибактериальный щит.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Какашки вомбата имеют форму куба, поэтому они не укатываются и позволяют более эффективно метить территорию.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Кешью растут снаружи яблока кешью, свисая на самом конце — удивительно удивительный дизайн.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Акулы старше колец Сатурна — они существовали примерно за миллионы лет до того, как Сатурн приобрел свой знаменитый блеск.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Бабочки пробуют вкус ногами: когда они приземляются на лист, они, по сути, пробуют ужин.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Улитка может спать до трех лет, не просыпаясь — честно говоря, это интересно.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Глаза страуса больше, чем его мозг, и он живет на тонкой грани между взглядом и мышлением.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Фламинго рождаются серыми; их знаменитый розовый цвет обусловлен пигментами креветок и водорослей, которые они едят.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Белки помогают вырастить тысячи новых деревьев каждый год, потому что они забывают, где закопали орехи.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Первой видеоигрой, в которую играли в космосе, был тетрис, в который космонавт сыграл на Game Boy в 1993 году.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Дятлы обхватывают мозг языком, чтобы избежать сотрясения мозга. Использование языка в качестве шлема — дикое решение.",
  },
  'pt': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Os corvos não reconhecem apenas rostos humanos; eles podem se lembrar de pessoas que os trataram mal durante anos – e até mesmo alertar outros corvos.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Os gatos passam cerca de 70% de suas vidas dormindo – então um gato de 10 anos fica acordado há apenas cerca de 3 anos.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "O mel nunca estraga; arqueólogos encontraram potes de mel de 3.000 anos em pirâmides egípcias que ainda eram comestíveis.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "As lontras marinhas dão as mãos enquanto dormem para não se separarem na correnteza.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Em Vênus, um dia é mais longo que um ano – ele gira em torno de seu eixo mais lentamente do que orbita o Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "O isqueiro foi inventado antes do palito de fósforo – às vezes a tecnologia “antiga” é mais antiga do que pensamos.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Os polvos têm três corações e nove cérebros – esquecer as coisas não é realmente uma opção.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "As vacas têm “melhores amigas” e podem ficar seriamente estressadas – e até chorar – quando separadas.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "O primeiro vírus de computador do mundo chamava-se “Creeper” e exibia: “Eu sou o rastejador, pegue-me se puder!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Uma nuvem média pode pesar cerca de 500.000 kg – como uma enorme manada de elefantes flutuando no alto.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "O DNA humano é cerca de 50% semelhante ao DNA da banana – portanto, chamar uma banana de “meu irmão” amanhã de manhã não é totalmente injusto.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Na verdade, os ursos polares têm pele preta e seu pelo é transparente; eles parecem brancos por causa da forma como a luz se espalha.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Você realmente não pode chorar no espaço: sem gravidade, as lágrimas não escorrem pelo seu rosto – elas formam uma bolha nos seus olhos.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "O Monte Everest continua a crescer cerca de 4 milímetros por ano – a Terra ainda está mudando.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Os ratos “assobiando” estão essencialmente cantando uns para os outros, mas em frequências muito altas para os humanos ouvirem.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Os tubarões são mais velhos que as árvores – os tubarões existem há cerca de 400 milhões de anos e as árvores há cerca de 350 milhões.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "As bananas são botanicamente bagas, mas os morangos não são – a botânica pode ser estranha.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Uma formiga pode levantar até 50 vezes o seu próprio peso – se você fosse uma formiga, poderia levantar um carro sozinho.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "A Torre Eiffel pode crescer cerca de 15 centímetros no verão devido à expansão térmica.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "O peso total de todos os humanos na Terra é aproximadamente comparável ao peso total de todas as formigas.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "As preguiças conseguem prender a respiração debaixo d'água por mais tempo do que os golfinhos – até cerca de 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Os pombos conseguem perceber a diferença entre as pinturas de Picasso e de Monet – afinal, eles são mais conhecedores de arte do que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "O GPS é gratuito para uso em todo o mundo, mas o governo dos EUA gasta cerca de 2 milhões de dólares por dia para mantê-lo funcionando.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Os ornitorrincos não têm estômago – a comida vai do esôfago direto para o intestino.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare é creditado com o primeiro uso registrado da palavra “arrogância” – mesmo no século 16, ele tinha estilo.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "O coração de uma baleia azul é tão grande que um humano poderia nadar através de suas principais artérias.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "As formigas não têm pulmões – e nunca “dormem” de verdade; eles operam sem parar como pequenos workaholics.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Em Saturno e Júpiter, pode literalmente chover diamantes – aparentemente estamos vivendo no planeta errado.",
    "Honeybees can recognize human faces and remember them individually.":
        "As abelhas podem reconhecer rostos humanos e lembrá-los individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "O “suor” do hipopótamo pode parecer rosa e atua tanto como protetor solar quanto como escudo antibacteriano.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "O cocô do Wombat tem formato de cubo, por isso não rola e pode marcar território com mais eficácia.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Os cajus crescem fora do fruto do caju, pendurados bem na extremidade – um design estranhamente surpreendente.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Os tubarões são mais antigos que os anéis de Saturno – já existiam milhões de anos antes de Saturno receber o seu famoso brilho.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "As borboletas têm gosto com os pés – quando pousam em uma folha, estão basicamente experimentando o jantar.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Um caracol pode dormir por até três anos sem acordar – honestamente, é compreensível.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Os olhos de um avestruz são maiores que o seu cérebro – vivendo na linha tênue entre olhar e pensar.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Os flamingos nascem cinzentos; seu famoso rosa vem dos pigmentos dos camarões e das algas que comem.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Os esquilos ajudam a cultivar milhares de novas árvores todos os anos porque se esquecem de onde enterraram as nozes.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "O primeiro videogame jogado no espaço foi Tetris – jogado em um Game Boy por um cosmonauta em 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Os pica-paus envolvem o cérebro com a língua para ajudar a evitar concussões – usar a língua como capacete é uma solução selvagem.",
  },
  'ar': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "لا تتعرف الغربان على الوجوه البشرية فحسب؛ يمكنهم أن يتذكروا الأشخاص الذين عاملوهم بشكل سيئ لسنوات، بل ويمكنهم أيضًا تحذير الغربان الأخرى.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "تقضي القطط حوالي 70% من حياتها نائمة، أي أن القطة البالغة من العمر 10 سنوات تظل مستيقظة لمدة 3 سنوات فقط.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "العسل لا يفسد أبدًا؛ اكتشف علماء الآثار جرارًا من العسل عمرها 3000 عام في الأهرامات المصرية والتي كانت لا تزال صالحة للأكل.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "ثعالب البحر تمسك أيديها أثناء نومها حتى لا تنجرف بعيدًا في التيار.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "على كوكب الزهرة، يكون اليوم أطول من السنة، فهو يدور حول محوره بشكل أبطأ من دورانه حول الشمس.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "تم اختراع الولاعة قبل عود الثقاب، وفي بعض الأحيان تكون التكنولوجيا \"القديمة\" أقدم مما نعتقد.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "يمتلك الأخطبوط ثلاثة قلوب وتسعة أدمغة، ونسيان الأشياء ليس خيارًا في الحقيقة.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "الأبقار لديها \"أفضل الأصدقاء\"، ويمكن أن تتعرض لضغوط شديدة - وحتى البكاء - عند الانفصال.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "أول فيروس كمبيوتر في العالم كان يسمى \"الزاحف\"، وكان يظهر: \"أنا الزاحف، أمسك بي إذا استطعت!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "يمكن أن تزن السحابة المتوسطة حوالي 500000 كجم، مثل قطيع ضخم من الأفيال التي تطفو فوقها.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "يتشابه الحمض النووي البشري مع الحمض النووي للموز بنسبة 50% تقريبًا، لذا فإن تسمية الموز بـ \"أخي\" صباح الغد ليس ظلمًا تمامًا.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "في الواقع، تتمتع الدببة القطبية بجلد أسود، وفرائها شفاف؛ تبدو بيضاء بسبب كيفية تشتت الضوء.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "لا يمكنك البكاء حقًا في الفضاء: فبدون الجاذبية، لن تسيل الدموع على وجهك، بل ستشكل نقطة في عينك.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "يستمر جبل إيفرست في النمو بنحو 4 ملليمترات كل عام، ولا تزال الأرض تتغير.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "تقوم الفئران \"بالتصفير\" بشكل أساسي بالغناء لبعضها البعض، ولكن بترددات عالية جدًا بحيث لا يستطيع البشر سماعها.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "أسماك القرش أقدم من الأشجار، إذ كانت أسماك القرش موجودة منذ حوالي 400 مليون سنة، والأشجار منذ حوالي 350 مليون سنة.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "الموز عبارة عن توت من الناحية النباتية، لكن الفراولة ليست كذلك، فقد يكون علم النبات غريبًا.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "يمكن للنملة أن ترفع ما يصل إلى 50 ضعف وزنها، وإذا كنت نملة، فيمكنك رفع سيارة بنفسك.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "يمكن أن ينمو برج إيفل بحوالي 15 سم في الصيف بسبب التمدد الحراري.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "الوزن الإجمالي لجميع البشر على الأرض يمكن مقارنته تقريبًا بالوزن الإجمالي لجميع النمل.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "يمكن لحيوانات الكسلان حبس أنفاسها تحت الماء لفترة أطول من الدلافين، تصل إلى حوالي 40 دقيقة.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "يستطيع الحمام التمييز بين لوحات بيكاسو ومونيه، وقد تبين أنهم أكثر ذكاءً في الفن مما نعتقد.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "إن استخدام نظام تحديد المواقع العالمي (GPS) مجاني في جميع أنحاء العالم، ولكن يقال إن الحكومة الأمريكية تنفق حوالي 2 مليون دولار أمريكي يوميًا لاستمرار تشغيله.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "خلد الماء ليس لديه معدة، فالطعام ينتقل من المريء مباشرة إلى الأمعاء.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "يعود الفضل إلى ويليام شكسبير في أول استخدام مسجل لكلمة \"اختيال\" - حتى في القرن السادس عشر، كان لديه أسلوب.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "قلب الحوت الأزرق كبير جدًا لدرجة أن الإنسان يستطيع السباحة عبر شرايينه الرئيسية.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "لا يمتلك النمل رئتين، ولا \"ينام\" أبدًا؛ إنهم يعملون دون توقف مثل مدمنين العمل الصغار.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "في زحل والمشتري، يمكن أن تمطر الماس فعليًا، ويبدو أننا نعيش على الكوكب الخطأ.",
    "Honeybees can recognize human faces and remember them individually.":
        "يمكن لنحل العسل التعرف على الوجوه البشرية وتذكرها بشكل فردي.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "يمكن أن يبدو \"عرق\" فرس النهر ورديًا ويعمل بمثابة واقي من الشمس ودرع مضاد للبكتيريا.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "يكون براز الومبت على شكل مكعب، لذا فهو لا يتدحرج ويمكنه تحديد المنطقة بشكل أكثر فعالية.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "ينمو الكاجو خارج ثمرة الكاجو، ويتدلى في نهايتها، وهو تصميم مثير للدهشة بشكل غريب.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "تعد أسماك القرش أقدم من حلقات زحل، فقد كانت موجودة قبل ملايين السنين من حصول زحل على بريقه الشهير.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "تتذوق الفراشات بأقدامها، فعندما تهبط على ورقة شجر، فإنها في الأساس تتناول العشاء.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "يمكن للحلزون أن ينام لمدة تصل إلى ثلاث سنوات دون أن يستيقظ - بصراحة، يمكن التواصل معه.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "عيون النعامة أكبر من دماغها، وتعيش على الخط الرفيع بين النظر والتفكير.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "تولد طيور النحام باللون الرمادي؛ يأتي لونهم الوردي الشهير من الأصباغ الموجودة في الجمبري والطحالب التي يأكلونها.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "تساعد السناجب في زراعة آلاف الأشجار الجديدة كل عام لأنها تنسى المكان الذي دفنت فيه الجوز.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "أول لعبة فيديو تم لعبها في الفضاء كانت Tetris، والتي لعبها رائد فضاء على جهاز Game Boy في عام 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "يلف نقار الخشب ألسنتهم حول أدمغتهم للمساعدة في تجنب الارتجاجات، ويعتبر استخدام لسانك كخوذة حلاً جذريًا.",
  },
  'es': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Los cuervos no sólo reconocen rostros humanos; pueden recordar a las personas que los trataron mal durante años e incluso advertir a otros cuervos.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Los gatos pasan alrededor del 70% de sus vidas dormidos, por lo que un gato de 10 años ha estado despierto sólo durante unos 3 años.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "La miel nunca se echa a perder; Los arqueólogos han encontrado tarros de miel de 3.000 años de antigüedad en pirámides egipcias que aún eran comestibles.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Las nutrias marinas se toman de la mano mientras duermen para no separarse con la corriente.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "En Venus, un día es más largo que un año: gira sobre su eje más lentamente de lo que orbita alrededor del Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "El encendedor se inventó antes que la cerilla; a veces, la tecnología “antigua” es más antigua de lo que pensamos.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Los pulpos tienen tres corazones y nueve cerebros; olvidar cosas no es realmente una opción.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Las vacas tienen “mejores amigas” y pueden estresarse gravemente (e incluso llorar) cuando se las separa.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "El primer virus informático del mundo se llamó \"Creeper\" y decía: \"¡Soy el creeper, atrápame si puedes!\".",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Una nube promedio puede pesar alrededor de 500.000 kg, como una enorme manada de elefantes flotando sobre nuestras cabezas.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "El ADN humano es aproximadamente un 50% similar al ADN del plátano, por lo que llamar a un plátano \"mi hermano\" mañana por la mañana no es del todo injusto.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Los osos polares en realidad tienen la piel negra y su pelaje es transparente; Se ven blancos debido a cómo se dispersa la luz.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Realmente no se puede llorar en el espacio: sin gravedad, las lágrimas no corren por la cara, sino que forman una masa en el ojo.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "El Monte Everest sigue creciendo unos 4 milímetros cada año; la Tierra sigue cambiando.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Los ratones que \"silban\" esencialmente se cantan entre sí, pero a frecuencias demasiado altas para que los humanos las escuchen.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Los tiburones son más viejos que los árboles: los tiburones existen desde hace unos 400 millones de años, los árboles desde hace unos 350 millones.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Los plátanos son botánicamente bayas, pero las fresas no; la botánica puede ser extraña.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Una hormiga puede levantar hasta 50 veces su propio peso; si fueras una hormiga, podrías levantar un coche tú solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel puede crecer unos 15 centímetros en verano debido a la expansión térmica.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "El peso total de todos los humanos en la Tierra es aproximadamente comparable al peso total de todas las hormigas.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Los perezosos pueden contener la respiración bajo el agua durante más tiempo que los delfines: hasta unos 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Las palomas pueden notar la diferencia entre las pinturas de Picasso y Monet; resulta que son más conocedoras del arte de lo que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "El uso del GPS es gratuito en todo el mundo, pero, según se informa, el gobierno de Estados Unidos gasta alrededor de 2 millones de dólares al día para mantenerlo en funcionamiento.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Los ornitorrincos no tienen estómago: la comida va del esófago directamente a los intestinos.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "A William Shakespeare se le atribuye el primer uso registrado de la palabra \"arrogancia\": incluso en el siglo XVI, tenía estilo.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "El corazón de una ballena azul es tan grande que un humano podría nadar a través de sus arterias principales.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Las hormigas no tienen pulmones y nunca “duermen” realmente; operan sin parar como pequeños adictos al trabajo.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "En Saturno y Júpiter, literalmente puede llover diamantes; aparentemente vivimos en el planeta equivocado.",
    "Honeybees can recognize human faces and remember them individually.":
        "Las abejas pueden reconocer rostros humanos y recordarlos individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "El “sudor” del hipopótamo puede verse rosado y actúa como protector solar y escudo antibacteriano.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "La caca de wombat tiene forma de cubo, por lo que no se desplaza y puede marcar el territorio de forma más eficaz.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Los anacardos crecen fuera de la manzana de anacardo, colgando al final, un diseño extrañamente sorprendente.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Los tiburones son más antiguos que los anillos de Saturno: existieron alrededor de millones de años antes de que Saturno obtuviera su famoso brillo.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Las mariposas prueban con los pies: cuando aterrizan en una hoja, básicamente están probando la cena.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un caracol puede dormir hasta tres años sin despertarse; honestamente, es identificable.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Los ojos de un avestruz son más grandes que su cerebro y viven en la delgada línea entre mirar y pensar.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Los flamencos nacen grises; su famoso rosa proviene de los pigmentos de los camarones y las algas que comen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Las ardillas ayudan a cultivar miles de árboles nuevos cada año porque olvidan dónde enterraron las nueces.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "El primer videojuego jugado en el espacio fue el Tetris, jugado en una Game Boy por un cosmonauta en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Los pájaros carpinteros envuelven sus lenguas alrededor de sus cerebros para ayudar a evitar conmociones cerebrales; usar la lengua como casco es una solución descabellada.",
  },
  'es-mx': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Los cuervos no sólo reconocen rostros humanos; pueden recordar a las personas que los trataron mal durante años e incluso advertir a otros cuervos.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Los gatos pasan alrededor del 70% de sus vidas dormidos, por lo que un gato de 10 años ha estado despierto sólo durante unos 3 años.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "La miel nunca se echa a perder; Los arqueólogos han encontrado tarros de miel de 3.000 años de antigüedad en pirámides egipcias que aún eran comestibles.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Las nutrias marinas se toman de la mano mientras duermen para no separarse con la corriente.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "En Venus, un día es más largo que un año: gira sobre su eje más lentamente de lo que orbita alrededor del Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "El encendedor se inventó antes que la cerilla; a veces, la tecnología “antigua” es más antigua de lo que pensamos.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Los pulpos tienen tres corazones y nueve cerebros; olvidar cosas no es realmente una opción.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Las vacas tienen “mejores amigas” y pueden estresarse gravemente (e incluso llorar) cuando se las separa.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "El primer virus informático del mundo se llamó \"Creeper\" y decía: \"¡Soy el creeper, atrápame si puedes!\".",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Una nube promedio puede pesar alrededor de 500.000 kg, como una enorme manada de elefantes flotando sobre nuestras cabezas.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "El ADN humano es aproximadamente un 50% similar al ADN del plátano, por lo que llamar a un plátano \"mi hermano\" mañana por la mañana no es del todo injusto.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Los osos polares en realidad tienen la piel negra y su pelaje es transparente; Se ven blancos debido a cómo se dispersa la luz.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Realmente no se puede llorar en el espacio: sin gravedad, las lágrimas no corren por la cara, sino que forman una masa en el ojo.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "El Monte Everest sigue creciendo unos 4 milímetros cada año; la Tierra sigue cambiando.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Los ratones que \"silban\" esencialmente se cantan entre sí, pero a frecuencias demasiado altas para que los humanos las escuchen.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Los tiburones son más viejos que los árboles: los tiburones existen desde hace unos 400 millones de años, los árboles desde hace unos 350 millones.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Los plátanos son botánicamente bayas, pero las fresas no; la botánica puede ser extraña.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Una hormiga puede levantar hasta 50 veces su propio peso; si fueras una hormiga, podrías levantar un coche tú solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel puede crecer unos 15 centímetros en verano debido a la expansión térmica.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "El peso total de todos los humanos en la Tierra es aproximadamente comparable al peso total de todas las hormigas.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Los perezosos pueden contener la respiración bajo el agua durante más tiempo que los delfines: hasta unos 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Las palomas pueden notar la diferencia entre las pinturas de Picasso y Monet; resulta que son más conocedoras del arte de lo que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "El uso del GPS es gratuito en todo el mundo, pero, según se informa, el gobierno de Estados Unidos gasta alrededor de 2 millones de dólares al día para mantenerlo en funcionamiento.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Los ornitorrincos no tienen estómago: la comida va del esófago directamente a los intestinos.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "A William Shakespeare se le atribuye el primer uso registrado de la palabra \"arrogancia\": incluso en el siglo XVI, tenía estilo.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "El corazón de una ballena azul es tan grande que un humano podría nadar a través de sus arterias principales.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Las hormigas no tienen pulmones y nunca “duermen” realmente; operan sin parar como pequeños adictos al trabajo.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "En Saturno y Júpiter, literalmente puede llover diamantes; aparentemente vivimos en el planeta equivocado.",
    "Honeybees can recognize human faces and remember them individually.":
        "Las abejas pueden reconocer rostros humanos y recordarlos individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "El “sudor” del hipopótamo puede verse rosado y actúa como protector solar y escudo antibacteriano.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "La caca de wombat tiene forma de cubo, por lo que no se desplaza y puede marcar el territorio de forma más eficaz.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Los anacardos crecen fuera de la manzana de anacardo, colgando al final, un diseño extrañamente sorprendente.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Los tiburones son más antiguos que los anillos de Saturno: existieron alrededor de millones de años antes de que Saturno obtuviera su famoso brillo.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Las mariposas prueban con los pies: cuando aterrizan en una hoja, básicamente están probando la cena.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un caracol puede dormir hasta tres años sin despertarse; honestamente, es identificable.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Los ojos de un avestruz son más grandes que su cerebro y viven en la delgada línea entre mirar y pensar.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Los flamencos nacen grises; su famoso rosa proviene de los pigmentos de los camarones y las algas que comen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Las ardillas ayudan a cultivar miles de árboles nuevos cada año porque olvidan dónde enterraron las nueces.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "El primer videojuego jugado en el espacio fue el Tetris, jugado en una Game Boy por un cosmonauta en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Los pájaros carpinteros envuelven sus lenguas alrededor de sus cerebros para ayudar a evitar conmociones cerebrales; usar la lengua como casco es una solución descabellada.",
  },
  'hi': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "कौवे सिर्फ इंसानों के चेहरे ही नहीं पहचानते; वे उन लोगों को याद कर सकते हैं जिन्होंने वर्षों तक उनके साथ बुरा व्यवहार किया - और यहां तक ​​कि अन्य कौवों को भी चेतावनी दे सकते हैं।",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "बिल्लियाँ अपने जीवन का लगभग 70% हिस्सा सोते हुए बिताती हैं - इसलिए 10 साल की बिल्ली केवल 3 साल तक ही जागती है।",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "शहद कभी ख़राब नहीं होता; पुरातत्वविदों को मिस्र के पिरामिडों में शहद के 3,000 साल पुराने जार मिले हैं जो अभी भी खाने योग्य थे।",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "समुद्री ऊदबिलाव सोते समय हाथ पकड़ते हैं ताकि वे धारा में अलग न हो जाएँ।",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "शुक्र पर, एक दिन एक वर्ष से अधिक लंबा होता है - यह सूर्य की परिक्रमा करने की तुलना में अपनी धुरी पर अधिक धीरे-धीरे घूमता है।",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "लाइटर का आविष्कार माचिस की तीली से पहले हुआ था - कभी-कभी \"पुरानी\" तकनीक हमारी सोच से भी पुरानी होती है।",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "ऑक्टोपस के तीन दिल और नौ दिमाग होते हैं—चीज़ों को भूलना वास्तव में कोई विकल्प नहीं है।",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "गायों के \"सबसे अच्छे दोस्त\" होते हैं, और अलग होने पर वे गंभीर रूप से तनावग्रस्त हो सकती हैं - और रो भी सकती हैं।",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "दुनिया के पहले कंप्यूटर वायरस को \"क्रीपर\" कहा जाता था और इसमें प्रदर्शित होता था: \"मैं क्रीपर हूं, यदि आप पकड़ सकते हैं तो मुझे पकड़ लो!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "एक औसत बादल का वजन लगभग 500,000 किलोग्राम हो सकता है—जैसे हाथियों का एक विशाल झुंड, जो ऊपर तैर रहा हो।",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "मानव डीएनए लगभग 50% केले के डीएनए के समान है—इसलिए कल सुबह केले को \"मेरा भाई-बहन\" कहना पूरी तरह से अनुचित नहीं है।",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "ध्रुवीय भालू की त्वचा वास्तव में काली होती है, और उनका फर पारदर्शी होता है; प्रकाश के प्रकीर्णन के कारण वे सफेद दिखते हैं।",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "आप वास्तव में अंतरिक्ष में नहीं रो सकते: गुरुत्वाकर्षण के बिना, आँसू आपके चेहरे से नहीं बहते - वे आपकी आँख में एक बूँद का रूप ले लेते हैं।",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "माउंट एवरेस्ट हर साल लगभग 4 मिलीमीटर बढ़ता रहता है—पृथ्वी अभी भी बदल रही है।",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "\"सीटी बजाने वाले\" चूहे अनिवार्य रूप से एक-दूसरे के लिए गा रहे हैं, लेकिन मनुष्यों के सुनने के लिए इतनी अधिक आवृत्ति पर।",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "शार्क पेड़ों से भी पुरानी हैं - शार्क लगभग 400 मिलियन वर्षों से हैं, पेड़ लगभग 350 मिलियन वर्षों से हैं।",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "केले वानस्पतिक रूप से जामुन हैं, लेकिन स्ट्रॉबेरी नहीं हैं—वनस्पति विज्ञान अजीब हो सकता है।",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "एक चींटी अपने वज़न से 50 गुना अधिक वज़न उठा सकती है—यदि आप चींटी होते, तो आप अकेले एक कार उठा सकते थे।",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "थर्मल विस्तार के कारण एफिल टॉवर गर्मियों में लगभग 15 सेंटीमीटर तक बढ़ सकता है।",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "पृथ्वी पर सभी मनुष्यों का कुल वजन लगभग सभी चींटियों के कुल वजन के बराबर है।",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "स्लॉथ डॉल्फ़िन की तुलना में पानी के भीतर अपनी सांस अधिक समय तक रोक सकते हैं - लगभग 40 मिनट तक।",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "कबूतर पिकासो और मोनेट की पेंटिंग्स के बीच अंतर बता सकते हैं - पता चलता है कि वे जितना हम सोचते हैं उससे कहीं अधिक कला-प्रेमी हैं।",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "दुनिया भर में जीपीएस का उपयोग मुफ़्त है, लेकिन अमेरिकी सरकार कथित तौर पर इसे चालू रखने के लिए प्रतिदिन लगभग 2 मिलियन अमेरिकी डॉलर खर्च करती है।",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "प्लैटिपस में पेट नहीं होता - भोजन ग्रासनली से सीधे आंतों में जाता है।",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "विलियम शेक्सपियर को \"स्वैगर\" शब्द के पहले रिकॉर्ड किए गए उपयोग का श्रेय दिया जाता है - 16 वीं शताब्दी में भी, उनके पास शैली थी।",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "ब्लू व्हेल का हृदय इतना बड़ा होता है कि मनुष्य उसकी मुख्य धमनियों में तैर सकता है।",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "चींटियों के फेफड़े नहीं होते—और वे कभी सचमुच \"नींद\" नहीं लेतीं; वे छोटे वर्कहोलिक्स की तरह बिना रुके काम करते हैं।",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "शनि और बृहस्पति पर, सचमुच हीरों की बारिश हो सकती है—जाहिर तौर पर हम गलत ग्रह पर रह रहे हैं।",
    "Honeybees can recognize human faces and remember them individually.":
        "मधुमक्खियाँ इंसानों के चेहरों को पहचान सकती हैं और उन्हें व्यक्तिगत रूप से याद रख सकती हैं।",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "हिप्पो का \"पसीना\" गुलाबी दिख सकता है और सनस्क्रीन और जीवाणुरोधी ढाल दोनों की तरह काम करता है।",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "वॉम्बैट मल घन के आकार का होता है, इसलिए यह लुढ़कता नहीं है और क्षेत्र को अधिक प्रभावी ढंग से चिह्नित कर सकता है।",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "काजू सेब के बाहर उगते हैं, बिल्कुल अंत में लटकते हैं - एक अजीब आश्चर्यजनक डिजाइन।",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "शार्क शनि के छल्लों से भी पुरानी हैं - शनि को अपनी प्रसिद्ध चमक मिलने से लगभग लाखों साल पहले उनकी उम्र थी।",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "तितलियाँ अपने पैरों से स्वाद चखती हैं - जब वे एक पत्ते पर उतरती हैं, तो वे मूल रूप से रात के खाने का नमूना ले रही होती हैं।",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "एक घोंघा बिना जागे तीन साल तक सो सकता है—ईमानदारी से कहें तो, भरोसेमंद।",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "शुतुरमुर्ग की आंखें उसके मस्तिष्क से बड़ी होती हैं - देखने और सोचने के बीच की महीन रेखा पर रहती हैं।",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "राजहंस भूरे रंग के पैदा होते हैं; उनका प्रसिद्ध गुलाबी रंग उनके द्वारा खाए जाने वाले झींगा और शैवाल के रंगद्रव्य से आता है।",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "गिलहरियाँ हर साल हजारों नए पेड़ उगाने में मदद करती हैं क्योंकि वे भूल जाती हैं कि उन्होंने मेवे कहाँ गाड़े हैं।",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "अंतरिक्ष में खेला जाने वाला पहला वीडियो गेम टेट्रिस था - जिसे 1993 में एक अंतरिक्ष यात्री द्वारा गेम बॉय पर खेला गया था।",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "कठफोड़वा चोट से बचने के लिए अपनी जीभ को अपने दिमाग के चारों ओर लपेटते हैं - अपनी जीभ को हेलमेट के रूप में उपयोग करना एक जंगली समाधान है।",
  },
  'hu': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "A varjak nemcsak az emberi arcokat ismerik fel; emlékezhetnek azokra az emberekre, akik évekig rosszul bántak velük – és még figyelmeztethetnek is más varjakat.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "A macskák életük 70%-át alvással töltik – tehát egy 10 éves macska csak körülbelül 3 éve van ébren.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "A méz soha nem romlik meg; a régészek 3000 éves mézesedényeket találtak egyiptomi piramisokban, amelyek még ehetőek voltak.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "A tengeri vidrák egymás kezét fogják alvás közben, hogy ne sodródjanak szét az áramlatban.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "A Vénuszon egy nap hosszabb, mint egy év – lassabban forog a tengelye körül, mint a Nap körül.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Az öngyújtót a gyufaszál előtt találták fel – a „régi” technológia néha régebbi, mint gondolnánk.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "A polipoknak három szívük és kilenc agyuk van – a dolgok elfelejtése nem igazán lehetséges.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "A teheneknek vannak „legjobb barátai”, és súlyosan stresszesek lehetnek – sőt sírhatnak is –, ha elszakadnak egymástól.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "A világ első számítógépes vírusát „Creeper”-nek hívták, és ez állt rajta: „Én vagyok a kúszónövény, kapj el, ha tudsz!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Egy átlagos felhő körülbelül 500 000 kg-ot nyomhat – akár egy hatalmas elefántcsorda, amely a fejünk fölött lebeg.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Az emberi DNS körülbelül 50%-ban hasonlít a banán DNS-éhez – tehát nem teljesen igazságtalan egy banánt holnap reggel „testvéremnek” nevezni.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "A jegesmedvéknek valójában fekete bőrük van, bundájuk átlátszó; fehérnek tűnnek a fény szórása miatt.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Nem igazán lehet sírni az űrben: gravitáció nélkül a könnyek nem csorognak le az arcodon – foltot képeznek a szemedben.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "A Mount Everest évente körülbelül 4 millimétert növekszik – a Föld még mindig változik.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "A „fütyülő” egerek lényegében énekelnek egymásnak, de túl magas frekvencián ahhoz, hogy az emberek meghallják.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "A cápák idősebbek a fáknál – a cápák körülbelül 400 millió éve, a fák körülbelül 350 millió éve léteznek.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "A banán botanikailag bogyó, de az eper nem – a botanika furcsa lehet.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Egy hangya saját súlyának 50-szeresét is képes megemelni – ha hangya lennél, egyedül is felemelhetnél egy autót.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Az Eiffel-torony nyáron körülbelül 15 centiméterrel nőhet a hőtágulás miatt.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "A Földön élő összes ember össztömege nagyjából összemérhető az összes hangya össztömegével.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "A lajhárok tovább tudják tartani a lélegzetüket a víz alatt, mint a delfinek – akár 40 percig is.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "A galambok képesek különbséget tenni Picasso és Monet festményei között – kiderül, hogy jobban értik a művészetet, mint gondolnánk.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "A GPS világszerte ingyenesen használható, de az Egyesült Államok kormánya állítólag körülbelül napi 2 millió dollárt költ a működés fenntartására.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "A kacsacsőrűeknek nincs gyomra – a táplálék a nyelőcsőből egyenesen a belekbe kerül.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare nevéhez fűződik a „swagger” szó első feljegyzett használata – még a 16. században is volt stílusa.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "A kék bálna szíve akkora, hogy az ember át tud úszni a fő artériákon.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "A hangyáknak nincs tüdejük – és soha nem „alszanak” igazán; megállás nélkül működnek, mint az apró munkamániások.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "A Szaturnuszon és a Jupiteren szó szerint hullhat a gyémánt – úgy tűnik, rossz bolygón élünk.",
    "Honeybees can recognize human faces and remember them individually.":
        "A méhek felismerik az emberi arcokat, és egyenként emlékeznek rájuk.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "A víziló „izzadtsága” rózsaszínnek tűnhet, és fényvédőként és antibakteriális pajzsként is működik.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "A womba kaki kocka alakú, így nem gurul el, és hatékonyabban jelölheti ki a területet.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "A kesudió a kesudió almán kívül nő, a legvégén lóg – ez egy furcsán meglepő design.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "A cápák idősebbek a Szaturnusz gyűrűjénél – körülbelül több millió évvel azelőtt voltak, hogy a Szaturnusz megkapta híres blingjét.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "A pillangók a lábukkal ízlelnek – amikor egy levélre szállnak, alapvetően vacsorát kóstolnak.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Egy csiga akár három évig is aludhat anélkül, hogy felébredne – őszintén szólva.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "A strucc szeme nagyobb, mint az agya – a látás és a gondolkodás közötti finom határvonalon él.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "A flamingók szürkének születnek; híres rózsaszínük az elfogyasztott garnélák és algák pigmentjeiből származik.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "A mókusok évente több ezer új fát növesztenek, mert elfelejtik, hová temették a diót.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Az első űrben játszott videojáték a Tetris volt, amelyet egy űrhajós Game Boy-on játszott 1993-ban.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "A harkályok az agyuk köré csavarják nyelvüket, hogy elkerüljék az agyrázkódást – a nyelv sisakként való használata vad megoldás.",
  },
  'zh-hans': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "乌鸦不仅能识别人脸，还能识别人脸。它们可以记住多年来虐待它们的人，甚至可以警告其他乌鸦。",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "猫一生中大约 70% 的时间都在睡觉，因此 10 岁的猫只有大约 3 年是清醒的。",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "蜂蜜永不变质；考古学家在埃及金字塔中发现了 3000 年前的蜂蜜罐，这些罐子仍然可以食用。",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "海獭睡觉时会手牵手，这样它们就不会在水流中漂散。",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "在金星上，一天比一年长——它绕其轴旋转的速度比绕太阳旋转的速度慢。",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "打火机是在火柴棍之前发明的——有时“旧”技术比我们想象的更古老。",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "章鱼有三颗心脏和九个大脑——忘记事情并不是一种真正的选择。",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "奶牛有“最好的朋友”，当它们分开时，它们会承受很大的压力，甚至哭泣。",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "世界上第一个计算机病毒被称为“爬行者”，它显示：“我是爬行者，如果你能抓住我！”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "一片云的平均重量约为 500,000 公斤，就像一大群大象漂浮在头顶上。",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "人类 DNA 与香蕉 DNA 相似度约为 50%，因此明天早上称香蕉为“我的兄弟姐妹”并不完全不公平。",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "北极熊的皮肤实际上是黑色的，毛皮是透明的；由于光的散射，它们看起来是白色的。",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "你不可能在太空中真正哭泣：没有重力，眼泪不会从你的脸上流下来——它们会在你的眼睛里形成一个斑点。",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "珠穆朗玛峰每年持续增长约 4 毫米——地球仍在变化。",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "“吹口哨”的老鼠本质上是在互相唱歌，但频率太高，人类听不到。",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "鲨鱼比树木更古老——鲨鱼已经存在了大约 4 亿年，树木也有大约 3.5 亿年。",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "香蕉在植物学上是浆果，但草莓不是——植物学可能很奇怪。",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "一只蚂蚁可以举起自身重量 50 倍的物体——如果你是一只蚂蚁，你可以自己举起一辆车。",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "由于热膨胀，埃菲尔铁塔在夏季可增长约 15 厘米。",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "地球上所有人类的总重量大致相当于所有蚂蚁的总重量。",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "树懒在水下屏住呼吸的时间比海豚长，最长可达 40 分钟左右。",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "鸽子可以区分毕加索和莫奈的画作——事实证明它们比我们想象的更懂艺术。",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS 在全球范围内免费使用，但据报道美国政府每天花费约 200 万美元来维持其运行。",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "鸭嘴兽没有胃，食物从食道直接进入肠道。",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "威廉·莎士比亚被认为是第一个使用“招摇”这个词的人——即使在 16 世纪，他也很有风格。",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "蓝鲸的心脏非常大，人类可以通过它的主要动脉游泳。",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "蚂蚁没有肺，而且它们从不真正“睡觉”；他们像小工作狂一样不停地工作。",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "在土星和木星上，它确实会下钻石雨——显然我们生活在错误的星球上。",
    "Honeybees can recognize human faces and remember them individually.":
        "蜜蜂可以识别人脸并单独记住他们。",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "河马的“汗水”看起来是粉红色的，它的作用既像防晒霜又像抗菌盾。",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "袋熊的粪便是立方体形状的，因此不会滚动，可以更有效地标记领地。",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "腰果长在腰果苹果外面，挂在腰果的末端——这是一个奇怪而令人惊讶的设计。",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "鲨鱼比土星环还要古老——它们在土星获得著名的光彩之前大约有数百万年。",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "蝴蝶用脚来品尝——当它们落在叶子上时，它们基本上是在品尝晚餐。",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "一只蜗牛可以睡长达三年而不醒来——老实说，这是有道理的。",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "鸵鸟的眼睛比大脑大——生活在观察和思考之间。",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "火烈鸟出生时是灰色的；它们著名的粉红色来自它们吃的虾和藻类中的色素。",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "松鼠每年帮助种植数千棵新树，因为它们忘记了将坚果埋在哪里。",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "第一个在太空中玩的视频游戏是俄罗斯方块，由一名宇航员于 1993 年在 Game Boy 上玩。",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "啄木鸟用舌头包裹大脑，以避免脑震荡——用舌头作为头盔是一个疯狂的解决方案。",
  },
  'id': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Gagak tidak hanya mengenali wajah manusia; mereka dapat mengingat orang-orang yang memperlakukan mereka dengan buruk selama bertahun-tahun—dan bahkan memperingatkan burung gagak lainnya.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Kucing menghabiskan sekitar 70% hidupnya untuk tidur—jadi kucing berusia 10 tahun baru terbangun sekitar 3 tahun.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Madu tidak pernah rusak; Para arkeolog telah menemukan toples madu berusia 3.000 tahun di piramida Mesir yang masih dapat dimakan.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Berang-berang laut berpegangan tangan saat tidur agar tidak hanyut terbawa arus.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Di Venus, satu hari lebih panjang dari satu tahun—perputarannya pada porosnya lebih lambat dibandingkan orbitnya terhadap Matahari.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Pemantik api ditemukan sebelum batang korek api—terkadang teknologi “lama” lebih tua dari yang kita kira.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Gurita memiliki tiga hati dan sembilan otak—melupakan sesuatu bukanlah suatu pilihan.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Sapi punya “sahabat”, dan mereka bisa mengalami stres berat—dan bahkan menangis—saat dipisahkan.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Virus komputer pertama di dunia disebut “Creeper,” dan tulisannya berbunyi: “Akulah yang menjalar, tangkap aku jika kamu bisa!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Rata-rata berat awan bisa mencapai 500.000 kg—seperti kawanan gajah dalam jumlah besar yang melayang di atasnya.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "DNA manusia sekitar 50% mirip dengan DNA pisang—jadi menyebut pisang sebagai “saudaraku” besok pagi bukanlah hal yang tidak adil.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Beruang kutub sebenarnya berkulit hitam dan bulunya transparan; mereka tampak putih karena penyebaran cahaya.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Anda tidak bisa benar-benar menangis di luar angkasa: tanpa gravitasi, air mata tidak akan mengalir di wajah Anda—air mata akan membentuk gumpalan di mata Anda.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Gunung Everest terus tumbuh sekitar 4 milimeter setiap tahun—Bumi masih terus berubah.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Tikus yang “bersiul” pada dasarnya bernyanyi satu sama lain, tetapi pada frekuensi yang terlalu tinggi untuk didengar manusia.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Hiu lebih tua dari pohon—hiu telah ada sekitar 400 juta tahun, dan pohon berusia sekitar 350 juta tahun.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Pisang secara botani adalah buah beri, tetapi stroberi tidak—botani bisa jadi aneh.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Seekor semut dapat mengangkat beban hingga 50 kali beratnya sendiri—jika Anda seekor semut, Anda dapat mengangkat sebuah mobil sendirian.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Menara Eiffel bisa tumbuh sekitar 15 sentimeter di musim panas karena ekspansi termal.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Berat total seluruh manusia di Bumi kira-kira sebanding dengan berat total semua semut.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Sloth dapat menahan napas di bawah air lebih lama dibandingkan lumba-lumba—hingga sekitar 40 menit.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Merpati bisa membedakan lukisan karya Picasso dan Monet—ternyata mereka lebih paham seni daripada yang kita kira.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS gratis untuk digunakan di seluruh dunia, namun pemerintah AS dilaporkan menghabiskan sekitar 2 juta dolar AS per hari agar tetap berfungsi.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platipus tidak memiliki perut—makanan mengalir dari kerongkongan langsung ke usus.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare dianggap sebagai orang pertama yang menggunakan kata “kesombongan”—bahkan pada abad ke-16, ia memiliki gaya.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Jantung paus biru sangat besar sehingga manusia bisa berenang melalui arteri utamanya.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Semut tidak memiliki paru-paru—dan mereka tidak pernah benar-benar “tidur”; mereka beroperasi tanpa henti seperti pecandu kerja kecil.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Di Saturnus dan Jupiter, hujan berlian bisa terjadi—tampaknya kita hidup di planet yang salah.",
    "Honeybees can recognize human faces and remember them individually.":
        "Lebah madu dapat mengenali wajah manusia dan mengingatnya satu per satu.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "“Keringat” kuda nil bisa terlihat berwarna merah muda dan berfungsi seperti tabir surya dan pelindung antibakteri.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Kotoran wombat berbentuk kubus sehingga tidak menggelinding dan dapat menandai wilayah dengan lebih efektif.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Kacang mete tumbuh di luar buah jambu mete, menggantung di bagian paling ujung—sebuah desain yang aneh dan mengejutkan.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Hiu lebih tua dari cincin Saturnus—mereka berusia jutaan tahun sebelum Saturnus mendapatkan kilaunya yang terkenal.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Kupu-kupu mengecap dengan kakinya—saat hinggap di atas daun, pada dasarnya mereka sedang mencicipi makan malam.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Seekor siput bisa tidur hingga tiga tahun tanpa terbangun—sejujurnya, itu bisa diterima.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Mata burung unta lebih besar dari otaknya—berada di garis tipis antara melihat dan berpikir.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingo terlahir berwarna abu-abu; warna merah mudanya yang terkenal berasal dari pigmen pada udang dan ganggang yang mereka makan.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Tupai membantu menumbuhkan ribuan pohon baru setiap tahun karena mereka lupa di mana mereka mengubur kacang.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Video game pertama yang dimainkan di luar angkasa adalah Tetris—dimainkan di Game Boy oleh seorang kosmonot pada tahun 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Burung pelatuk membungkus otaknya dengan lidahnya untuk membantu menghindari gegar otak—menggunakan lidah Anda sebagai helm adalah solusi yang tepat.",
  },
  'nl': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Kraaien herkennen niet alleen menselijke gezichten; ze kunnen zich mensen herinneren die hen jarenlang slecht hebben behandeld – en zelfs andere kraaien waarschuwen.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Katten brengen ongeveer 70% van hun leven slapend door, dus een kat van 10 jaar oud is pas ongeveer 3 jaar wakker.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Honing bederft nooit; Archeologen hebben in Egyptische piramides 3000 jaar oude potten met honing gevonden die nog eetbaar waren.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Zeeotters houden elkaars hand vast terwijl ze slapen, zodat ze niet uit elkaar drijven in de stroming.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Op Venus duurt een dag langer dan een jaar: hij draait langzamer om zijn as dan hij om de zon draait.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "De aansteker is uitgevonden vóór het luciferstokje – soms is ‘oude’ technologie ouder dan we denken.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Octopussen hebben drie harten en negen hersenen; dingen vergeten is niet echt een optie.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Koeien hebben ‘beste vrienden’ en kunnen ernstig gestrest raken – en zelfs huilen – als ze gescheiden zijn.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Het eerste computervirus ter wereld heette ‘Creeper’ en er stond op: ‘Ik ben de creeper, vang me als je kunt!’",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Een gemiddelde wolk kan ongeveer 500.000 kg wegen, net als een enorme kudde olifanten die boven de grond zweeft.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Menselijk DNA is voor ongeveer 50% vergelijkbaar met bananen-DNA, dus een banaan morgenochtend ‘mijn broer of zus’ noemen is niet helemaal oneerlijk.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "IJsberen hebben eigenlijk een zwarte huid en hun vacht is transparant; ze zien er wit uit vanwege de manier waarop licht verstrooit.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Je kunt niet echt huilen in de ruimte: zonder zwaartekracht lopen de tranen niet over je gezicht; ze vormen een klodder in je ogen.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "De Mount Everest groeit elk jaar met ongeveer 4 millimeter – de aarde verandert nog steeds.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "‘Fluitende’ muizen zingen in wezen voor elkaar, maar op frequenties die te hoog zijn voor mensen om te horen.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Haaien zijn ouder dan bomen: haaien bestaan ​​al ongeveer 400 miljoen jaar, bomen al ongeveer 350 miljoen jaar.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Bananen zijn botanisch gezien bessen, maar aardbeien zijn dat niet. Plantkunde kan raar zijn.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Een mier kan tot 50 keer zijn eigen gewicht tillen. Als je een mier was, zou je zelf een auto kunnen tillen.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "De Eiffeltoren kan in de zomer zo’n 15 centimeter groeien als gevolg van thermische uitzetting.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Het totale gewicht van alle mensen op aarde is grofweg vergelijkbaar met het totale gewicht van alle mieren.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Luiaards kunnen hun adem onder water langer inhouden dan dolfijnen, tot ongeveer 40 minuten.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Duiven kunnen het verschil zien tussen schilderijen van Picasso en Monet; het blijkt dat ze meer kunstzinnig zijn dan we denken.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS is wereldwijd gratis te gebruiken, maar de Amerikaanse overheid geeft naar verluidt ongeveer 2 miljoen dollar per dag uit om het draaiende te houden.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Vogelbekdieren hebben geen maag; voedsel gaat rechtstreeks van de slokdarm naar de darmen.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare wordt gecrediteerd voor het eerste geregistreerde gebruik van het woord ‘swagger’ – zelfs in de 16e eeuw had hij stijl.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Het hart van een blauwe vinvis is zo groot dat een mens door de hoofdslagaders zou kunnen zwemmen.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Mieren hebben geen longen – en ze ‘slapen’ nooit echt; ze opereren non-stop als kleine workaholics.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Op Saturnus en Jupiter kan het letterlijk diamanten regenen – blijkbaar leven we op de verkeerde planeet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Honingbijen kunnen menselijke gezichten herkennen en deze individueel onthouden.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Het ‘zweet’ van nijlpaarden kan er roze uitzien en werkt zowel als zonnebrandcrème als als antibacterieel schild.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Wombatpoep is kubusvormig, zodat deze niet wegrolt en het territorium effectiever kan markeren.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Cashewnoten groeien buiten de cashewappel en hangen helemaal aan het uiteinde – een vreemd verrassend ontwerp.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Haaien zijn ouder dan de ringen van Saturnus: ze bestonden al miljoenen jaren voordat Saturnus zijn beroemde bling kreeg.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Vlinders proeven met hun voeten: als ze op een blad landen, proeven ze eigenlijk het avondeten.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Een slak kan wel drie jaar slapen zonder wakker te worden – eerlijk gezegd, herkenbaar.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "De ogen van een struisvogel zijn groter dan zijn hersenen en leven op de dunne grens tussen kijken en denken.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingo's worden grijs geboren; hun beroemde roze komt van pigmenten in garnalen en algen die ze eten.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Eekhoorns helpen elk jaar duizenden nieuwe bomen te laten groeien omdat ze vergeten waar ze noten hebben begraven.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "De eerste videogame die in de ruimte werd gespeeld was Tetris, gespeeld op een Game Boy door een kosmonaut in 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Spechten wikkelen hun tong om hun hersenen om hersenschuddingen te voorkomen; je tong als helm gebruiken is een wilde oplossing.",
  },
  'fr': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Les corbeaux ne reconnaissent pas seulement les visages humains ; ils peuvent se souvenir des personnes qui les ont maltraités pendant des années et même avertir les autres corbeaux.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Les chats passent environ 70 % de leur vie à dormir. Ainsi, un chat de 10 ans n'est éveillé que depuis environ 3 ans.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Le miel ne se gâte jamais ; Des archéologues ont découvert dans des pyramides égyptiennes des pots de miel vieux de 3 000 ans et encore comestibles.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Les loutres de mer se tiennent la main pendant leur sommeil pour ne pas se séparer dans le courant.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Sur Vénus, un jour dure plus d’un an : il tourne sur son axe plus lentement qu’il ne tourne autour du Soleil.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Le briquet a été inventé avant l’allumette – parfois la « vieille » technologie est plus ancienne qu’on ne le pense.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Les poulpes ont trois cœurs et neuf cerveaux : oublier des choses n’est pas vraiment une option.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Les vaches ont des « meilleures amies » et elles peuvent être très stressées et même pleurer lorsqu’elles sont séparées.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Le premier virus informatique au monde s’appelait « Creeper » et il affichait : « Je suis le creeper, attrape-moi si tu peux ! »",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Un nuage moyen peut peser environ 500 000 kg, comme un énorme troupeau d’éléphants flottant au-dessus de nous.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "L’ADN humain est similaire à environ 50 % à l’ADN de la banane. Il n’est donc pas totalement injuste d’appeler une banane « mon frère » demain matin.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Les ours polaires ont en fait la peau noire et leur fourrure est transparente ; ils semblent blancs à cause de la façon dont la lumière se disperse.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Vous ne pouvez pas vraiment pleurer dans l’espace : sans gravité, les larmes ne coulent pas sur votre visage : elles forment une goutte dans vos yeux.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Le mont Everest continue de croître d’environ 4 millimètres chaque année : la Terre continue de changer.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Les souris « sifflantes » chantent essentiellement entre elles, mais à des fréquences trop élevées pour que les humains puissent les entendre.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Les requins sont plus vieux que les arbres : les requins existent depuis environ 400 millions d'années, les arbres depuis environ 350 millions d'années.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Les bananes sont des baies botaniques, mais les fraises ne le sont pas : la botanique peut être étrange.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Une fourmi peut soulever jusqu’à 50 fois son propre poids. Si vous étiez une fourmi, vous pourriez soulever une voiture par vous-même.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Tour Eiffel peut s'agrandir d'environ 15 centimètres en été en raison de la dilatation thermique.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Le poids total de tous les humains sur Terre est à peu près comparable au poids total de toutes les fourmis.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Les paresseux peuvent retenir leur souffle sous l’eau plus longtemps que les dauphins, jusqu’à environ 40 minutes.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Les pigeons peuvent faire la différence entre les peintures de Picasso et de Monet – il s’avère qu’ils sont plus doués en art qu’on ne le pense.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "L'utilisation du GPS est gratuite dans le monde entier, mais le gouvernement américain dépenserait environ 2 millions de dollars américains par jour pour le faire fonctionner.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Les ornithorynques n’ont pas d’estomac : la nourriture va de l’œsophage directement aux intestins.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "On attribue à William Shakespeare la première utilisation enregistrée du mot « swagger » : même au XVIe siècle, il avait du style.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Le cœur d’une baleine bleue est si gros qu’un humain pourrait nager dans ses artères principales.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Les fourmis n’ont pas de poumons et ne « dorment » jamais vraiment ; ils opèrent sans arrêt comme de minuscules bourreaux de travail.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Sur Saturne et Jupiter, il peut littéralement pleuvoir des diamants. Apparemment, nous vivons sur la mauvaise planète.",
    "Honeybees can recognize human faces and remember them individually.":
        "Les abeilles peuvent reconnaître les visages humains et s’en souvenir individuellement.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "La « sueur » d’hippopotame peut paraître rose et agit à la fois comme un écran solaire et un bouclier antibactérien.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Les crottes de wombat sont en forme de cube, elles ne roulent donc pas et peuvent marquer le territoire plus efficacement.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Les noix de cajou poussent à l’extérieur de la pomme de cajou, suspendues à l’extrémité – un design étrangement surprenant.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Les requins sont plus vieux que les anneaux de Saturne : ils existaient environ des millions d’années avant que Saturne n’obtienne son fameux bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Les papillons goûtent avec leurs pattes : lorsqu’ils atterrissent sur une feuille, ils goûtent essentiellement à un dîner.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un escargot peut dormir jusqu’à trois ans sans se réveiller – honnêtement, c’est pertinent.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Les yeux d’une autruche sont plus grands que son cerveau et vivent à la frontière ténue entre regarder et penser.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Les flamants naissent gris ; leur célèbre rose provient des pigments des crevettes et des algues qu'ils mangent.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Les écureuils contribuent à faire pousser des milliers de nouveaux arbres chaque année parce qu’ils oublient où ils ont enterré les noix.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Le premier jeu vidéo joué dans l'espace fut Tetris, joué sur une Game Boy par un cosmonaute en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Les pics enroulent leur langue autour de leur cerveau pour éviter les commotions cérébrales. Utiliser votre langue comme casque est une solution folle.",
  },
  'it': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "I corvi non riconoscono solo i volti umani; possono ricordare le persone che li hanno trattati male per anni e persino mettere in guardia gli altri corvi.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "I gatti trascorrono circa il 70% della loro vita dormendo, quindi un gatto di 10 anni è sveglio solo da circa 3 anni.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Il miele non va mai a male; gli archeologi hanno trovato vasetti di miele di 3.000 anni fa nelle piramidi egiziane che erano ancora commestibili.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Le lontre marine si tengono per mano mentre dormono per non allontanarsi dalla corrente.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Su Venere, un giorno è più lungo di un anno: ruota sul proprio asse più lentamente di quanto orbita attorno al Sole.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "L’accendino è stato inventato prima del fiammifero: a volte la “vecchia” tecnologia è più vecchia di quanto pensiamo.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "I polpi hanno tre cuori e nove cervelli: dimenticare le cose non è davvero un’opzione.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Le mucche hanno “migliori amiche” e possono stressarsi seriamente – e persino piangere – quando vengono separate.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Il primo virus informatico al mondo si chiamava “Creeper” e diceva: “Sono il rampicante, prendimi se puoi!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Una nuvola media può pesare circa 500.000 kg, come un enorme branco di elefanti che fluttua sopra di loro.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Il DNA umano è simile per circa il 50% al DNA della banana, quindi chiamare una banana “mia sorella” domani mattina non è del tutto ingiusto.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Gli orsi polari hanno in realtà la pelle nera e la loro pelliccia è trasparente; sembrano bianchi a causa del modo in cui la luce si disperde.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Non puoi davvero piangere nello spazio: senza gravità, le lacrime non scendono sul tuo viso, ma formano una macchia nei tuoi occhi.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Il Monte Everest continua a crescere di circa 4 millimetri ogni anno: la Terra continua a cambiare.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "I topi che “fischiano” essenzialmente cantano tra loro, ma a frequenze troppo alte perché gli esseri umani possano sentirle.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Gli squali sono più vecchi degli alberi: gli squali esistono da circa 400 milioni di anni, gli alberi da circa 350 milioni.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Le banane sono botanicamente bacche, ma le fragole no: la botanica può essere strana.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Una formica può sollevare fino a 50 volte il proprio peso: se tu fossi una formica, potresti sollevare un’auto da solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel può crescere di circa 15 centimetri in estate a causa della dilatazione termica.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Il peso totale di tutti gli esseri umani sulla Terra è grossomodo paragonabile al peso totale di tutte le formiche.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "I bradipi possono trattenere il respiro sott'acqua più a lungo dei delfini, fino a circa 40 minuti.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "I piccioni riescono a distinguere i dipinti di Picasso e Monet: si scopre che sono più esperti d'arte di quanto pensiamo.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Il GPS è gratuito in tutto il mondo, ma secondo quanto riferito il governo degli Stati Uniti spende circa 2 milioni di dollari al giorno per mantenerlo in funzione.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Gli ornitorinchi non hanno stomaco: il cibo va dall'esofago direttamente all'intestino.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "A William Shakespeare viene attribuito il primo uso documentato della parola “spavalderia”: già nel XVI secolo aveva stile.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Il cuore di una balenottera azzurra è così grande che un essere umano potrebbe nuotare attraverso le sue arterie principali.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Le formiche non hanno polmoni e non “dormono” mai veramente; operano senza sosta come piccoli maniaci del lavoro.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Su Saturno e Giove possono letteralmente piovere diamanti: a quanto pare viviamo sul pianeta sbagliato.",
    "Honeybees can recognize human faces and remember them individually.":
        "Le api possono riconoscere i volti umani e ricordarli individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Il “sudore” dell’ippopotamo può sembrare rosa e agisce sia come protezione solare che come scudo antibatterico.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "La cacca del vombato è a forma di cubo, quindi non rotola via e può marcare il territorio in modo più efficace.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Gli anacardi crescono all'esterno dell'anacardio, appesi all'estremità: un disegno stranamente sorprendente.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Gli squali sono più antichi degli anelli di Saturno: erano circa milioni di anni prima che Saturno acquisisse il suo famoso splendore.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Le farfalle assaggiano con i piedi: quando si posano su una foglia, stanno praticamente assaggiando la cena.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Una lumaca può dormire fino a tre anni senza svegliarsi: onestamente, è facilmente riconoscibile.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Gli occhi di uno struzzo sono più grandi del suo cervello e vivono sulla linea sottile tra guardare e pensare.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "I fenicotteri nascono grigi; il loro famoso rosa deriva dai pigmenti presenti nei gamberetti e nelle alghe che mangiano.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Gli scoiattoli aiutano a far crescere migliaia di nuovi alberi ogni anno perché dimenticano dove hanno seppellito le noci.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Il primo videogioco giocato nello spazio è stato Tetris, giocato su un Game Boy da un cosmonauta nel 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "I picchi avvolgono la lingua attorno al cervello per evitare commozioni cerebrali: usare la lingua come un elmo è una soluzione azzardata.",
  },
  'vi': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Quạ không chỉ nhận diện khuôn mặt người; chúng có thể nhớ những người đã đối xử tệ bạc với chúng trong nhiều năm — và thậm chí còn cảnh báo những con quạ khác.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Mèo dành khoảng 70% cuộc đời để ngủ—vì vậy một con mèo 10 tuổi chỉ thức được khoảng 3 năm.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Mật ong không bao giờ hư; Các nhà khảo cổ học đã tìm thấy những lọ mật ong 3.000 năm tuổi trong kim tự tháp Ai Cập vẫn có thể ăn được.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Rái cá biển nắm tay nhau khi ngủ để không bị trôi theo dòng nước.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Trên sao Kim, một ngày dài hơn một năm – nó quay quanh trục chậm hơn so với quay quanh Mặt trời.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Chiếc bật lửa được phát minh trước cả que diêm - đôi khi công nghệ “cũ” còn lâu đời hơn chúng ta nghĩ.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Bạch tuộc có ba trái tim và chín bộ não – quên đi mọi thứ thực sự không phải là một lựa chọn.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Bò có “những người bạn thân nhất” và chúng có thể bị căng thẳng trầm trọng—và thậm chí khóc—khi bị tách ra.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Virus máy tính đầu tiên trên thế giới có tên là “Creeper” và nó hiển thị: “Tôi là cây leo, hãy bắt tôi nếu bạn có thể!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Một đám mây trung bình có thể nặng khoảng 500.000 kg – giống như một đàn voi khổng lồ bay lơ lửng trên đầu.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "DNA của con người giống DNA của chuối khoảng 50% — vì vậy sáng mai gọi một quả chuối là “anh chị em của tôi” không hoàn toàn không công bằng.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Gấu Bắc Cực thực sự có làn da đen và lông của chúng trong suốt; chúng trông có màu trắng vì ánh sáng tán xạ.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Bạn thực sự không thể khóc trong không gian: không có trọng lực, nước mắt không chảy xuống mặt bạn - chúng tạo thành một đốm màu trong mắt bạn.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Đỉnh Everest tiếp tục cao thêm khoảng 4 mm mỗi năm—Trái đất vẫn đang thay đổi.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Những con chuột “huýt sáo” về cơ bản là đang hát với nhau nhưng ở tần số quá cao để con người có thể nghe thấy.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Cá mập già hơn cây cối - cá mập đã tồn tại được khoảng 400 triệu năm, cây cối khoảng 350 triệu năm.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Chuối là loại quả mọng về mặt thực vật học, nhưng dâu tây thì không – thực vật học có thể kỳ lạ.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Một con kiến ​​có thể nâng vật nặng gấp 50 lần trọng lượng của nó – nếu bạn là kiến, bạn có thể tự mình nâng một chiếc ô tô.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Tháp Eiffel có thể cao thêm khoảng 15 cm vào mùa hè do sự giãn nở nhiệt.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Tổng trọng lượng của toàn bộ con người trên Trái đất gần tương đương với tổng trọng lượng của toàn bộ loài kiến.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Con lười có thể nín thở dưới nước lâu hơn cá heo - lên tới khoảng 40 phút.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Chim bồ câu có thể nhận ra sự khác biệt giữa tranh của Picasso và Monet - hóa ra chúng am hiểu nghệ thuật hơn chúng ta nghĩ.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS được sử dụng miễn phí trên toàn thế giới, nhưng chính phủ Hoa Kỳ được cho là phải chi khoảng 2 triệu đô la Mỹ mỗi ngày để duy trì hoạt động của nó.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Thú mỏ vịt không có dạ dày - thức ăn đi thẳng từ thực quản xuống ruột.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare được ghi nhận là người đầu tiên sử dụng từ “vênh vang” - thậm chí vào thế kỷ 16, ông đã có phong cách.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Trái tim của cá voi xanh lớn đến mức con người có thể bơi qua các động mạch chính của nó.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Kiến không có phổi—và chúng không bao giờ thực sự “ngủ”; họ làm việc không ngừng nghỉ như những kẻ nghiện công việc tí hon.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Trên Sao Thổ và Sao Mộc, theo đúng nghĩa đen, nó có thể tạo ra mưa kim cương - rõ ràng là chúng ta đang sống nhầm hành tinh.",
    "Honeybees can recognize human faces and remember them individually.":
        "Ong mật có thể nhận diện khuôn mặt con người và ghi nhớ từng khuôn mặt.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "“Mồ hôi” hà mã có thể trông có màu hồng và có tác dụng vừa là kem chống nắng vừa là tấm chắn kháng khuẩn.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Phân của Wombat có hình khối nên không bị lăn đi và có thể đánh dấu lãnh thổ hiệu quả hơn.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Hạt điều mọc bên ngoài quả điều, treo ở phần cuối—một thiết kế đáng ngạc nhiên kỳ lạ.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Cá mập còn lâu đời hơn các vành đai của Sao Thổ - chúng đã tồn tại khoảng hàng triệu năm trước khi Sao Thổ có được vẻ ngoài lấp lánh nổi tiếng.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Bướm nếm bằng chân - khi đậu trên một chiếc lá, về cơ bản chúng đang nếm thử bữa tối.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Một con ốc sên có thể ngủ tới ba năm mà không thức dậy—thành thật mà nói, cũng dễ hiểu thôi.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Đôi mắt của đà điểu lớn hơn não của nó—sống ở ranh giới mong manh giữa nhìn và suy nghĩ.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Chim hồng hạc sinh ra có màu xám; Màu hồng nổi tiếng của chúng đến từ sắc tố trong tôm và tảo mà chúng ăn.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Sóc giúp trồng hàng nghìn cây mới mỗi năm vì chúng quên mất nơi chôn hạt.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Trò chơi điện tử đầu tiên chơi trong không gian là Tetris—được một phi hành gia chơi trên Game Boy vào năm 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Chim gõ kiến ​​quấn lưỡi quanh não để giúp tránh chấn động — sử dụng lưỡi làm mũ bảo hiểm là một giải pháp hoang dã.",
  },
  'th': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "กาไม่เพียงแค่จดจำใบหน้าของมนุษย์เท่านั้น พวกมันจำคนที่ปฏิบัติต่อพวกมันอย่างเลวร้ายมานานหลายปีได้ และยังเตือนอีกาตัวอื่นด้วย",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "แมวใช้เวลาประมาณ 70% ของชีวิตในการนอนหลับ ดังนั้นแมวอายุ 10 ปีจึงตื่นได้เพียงประมาณ 3 ปีเท่านั้น",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "น้ำผึ้งไม่เคยเน่าเสีย นักโบราณคดีพบขวดน้ำผึ้งอายุ 3,000 ปีในปิรามิดอียิปต์ที่ยังกินได้",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "นากทะเลจับมือกันขณะนอนหลับเพื่อไม่ให้แยกจากกันตามกระแสน้ำ",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "บนดาวศุกร์ หนึ่งวันยาวนานกว่าหนึ่งปี โดยจะหมุนรอบแกนช้ากว่าที่โคจรรอบดวงอาทิตย์",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "ไฟแช็คถูกประดิษฐ์ขึ้นก่อนไม้ขีดไฟ บางครั้งเทคโนโลยี \"เก่า\" ก็เก่ากว่าที่เราคิด",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "ปลาหมึกยักษ์มีหัวใจ 3 ดวงและสมอง 9 สมอง การลืมสิ่งต่างๆ ไม่ใช่ทางเลือกที่ดีนัก",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "วัวมี \"เพื่อนที่ดีที่สุด\" และพวกมันอาจเครียดหนักและอาจร้องไห้ได้เมื่อแยกจากกัน",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "ไวรัสคอมพิวเตอร์ตัวแรกของโลกถูกเรียกว่า \"Creeper\" และมีข้อความว่า \"ฉันคือ Creeper จับฉันให้ได้ถ้าคุณทำได้!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "เมฆโดยเฉลี่ยสามารถมีน้ำหนักประมาณ 500,000 กิโลกรัม เหมือนฝูงช้างขนาดใหญ่ที่ลอยอยู่เหนือศีรษะ",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "DNA ของมนุษย์มีความคล้ายคลึงกับ DNA ของกล้วยประมาณ 50% ดังนั้นการเรียกกล้วยว่า \"พี่น้องของฉัน\" ในเช้าวันพรุ่งนี้จึงไม่ยุติธรรมเลย",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "จริงๆ แล้วหมีขั้วโลกมีผิวสีดำ และขนของพวกมันโปร่งใส พวกมันดูขาวเพราะแสงกระเจิง",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "คุณไม่สามารถร้องไห้ในอวกาศได้จริงๆ หากไม่มีแรงโน้มถ่วง น้ำตาจะไม่ไหลอาบหน้า แต่จะทำให้เกิดหยดในดวงตาของคุณ",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "ยอดเขาเอเวอเรสต์เติบโตขึ้นเรื่อยๆ ประมาณ 4 มิลลิเมตรในแต่ละปี—โลกยังคงเปลี่ยนแปลงอยู่",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "โดยพื้นฐานแล้วหนู “ผิวปาก” มักจะร้องเพลงให้กัน แต่มีความถี่สูงเกินกว่าที่มนุษย์จะได้ยิน",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "ฉลามมีอายุมากกว่าต้นไม้ ฉลามมีอายุประมาณ 400 ล้านปี ต้นไม้มีอายุประมาณ 350 ล้านปี",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "กล้วยเป็นผลเบอร์รี่ทางพฤกษศาสตร์ แต่สตรอเบอร์รี่ไม่ใช่ เพราะพฤกษศาสตร์อาจดูแปลกได้",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "มดสามารถยกของหนักได้ถึง 50 เท่า หากคุณเป็นมด ก็สามารถยกรถได้ด้วยตัวเอง",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "หอไอเฟลสามารถเติบโตได้ประมาณ 15 เซนติเมตรในฤดูร้อนเนื่องจากการขยายตัวทางความร้อน",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "น้ำหนักรวมของมนุษย์ทั้งหมดบนโลกเทียบได้กับน้ำหนักรวมของมดทั้งหมดโดยประมาณ",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "สลอธสามารถกลั้นหายใจใต้น้ำได้นานกว่าโลมา ประมาณ 40 นาที",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "นกพิราบสามารถบอกความแตกต่างระหว่างภาพวาดของปิกัสโซและโมเนต์ได้ ปรากฏว่าพวกเขาเชี่ยวชาญด้านศิลปะมากกว่าที่เราคิด",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS ใช้งานได้ฟรีทั่วโลก แต่มีรายงานว่ารัฐบาลสหรัฐฯ ใช้จ่ายประมาณ 2 ล้านดอลลาร์สหรัฐต่อวันเพื่อให้ GPS ทำงานต่อไป",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "ตุ่นปากเป็ดไม่มีกระเพาะ อาหารเคลื่อนจากหลอดอาหารตรงไปยังลำไส้",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "วิลเลียม เชคสเปียร์ได้รับเครดิตจากการใช้คำว่า \"ผยอง\" ที่บันทึกไว้เป็นครั้งแรก แม้แต่ในศตวรรษที่ 16 เขาก็มีสไตล์",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "หัวใจของวาฬสีน้ำเงินมีขนาดใหญ่มากจนมนุษย์สามารถว่ายผ่านหลอดเลือดแดงหลักได้",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "มดไม่มีปอด และพวกมันไม่เคย \"หลับ\" เลยด้วยซ้ำ พวกเขาทำงานไม่หยุดเหมือนคนบ้างานตัวเล็กๆ",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "บนดาวเสาร์และดาวพฤหัส มันสามารถทำให้เพชรตกลงมาได้ ดูเหมือนว่าเรากำลังอยู่บนดาวเคราะห์ผิดดวง",
    "Honeybees can recognize human faces and remember them individually.":
        "ผึ้งสามารถจดจำใบหน้าของมนุษย์และจดจำใบหน้าเหล่านั้นเป็นรายบุคคลได้",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "“เหงื่อ” ของฮิปโปอาจมีลักษณะเป็นสีชมพูและทำหน้าที่เหมือนเป็นทั้งครีมกันแดดและเกราะป้องกันแบคทีเรีย",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "อุจจาระวอมแบทมีรูปร่างเป็นลูกบาศก์ จึงไม่หลุดออกและสามารถทำเครื่องหมายอาณาเขตได้อย่างมีประสิทธิภาพมากขึ้น",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "เม็ดมะม่วงหิมพานต์เติบโตนอกผลมะม่วงหิมพานต์ โดยห้อยอยู่ที่ปลายสุด ซึ่งเป็นการออกแบบที่น่าแปลกใจอย่างประหลาด",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "ฉลามมีอายุมากกว่าวงแหวนของดาวเสาร์ พวกมันมีอายุประมาณล้านปีก่อนที่ดาวเสาร์จะมีประกายแวววาว",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "ผีเสื้อรับรสด้วยเท้า เมื่อพวกมันเกาะบนใบไม้ พวกมันก็กำลังสุ่มตัวอย่างอาหารเย็น",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "หอยทากสามารถนอนหลับได้นานถึงสามปีโดยไม่ต้องตื่น จริงๆ แล้วมีความสัมพันธ์กัน",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "ดวงตาของนกกระจอกเทศใหญ่กว่าสมอง โดยอยู่บนเส้นแบ่งระหว่างการมองและการคิด",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "นกฟลามิงโกเกิดเป็นสีเทา สีชมพูอันโด่งดังของพวกมันมาจากเม็ดสีในกุ้งและสาหร่ายที่มันกินเข้าไป",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "กระรอกช่วยปลูกต้นไม้ใหม่นับพันต้นในแต่ละปี เพราะพวกเขาลืมว่าฝังถั่วไว้ที่ไหน",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "วิดีโอเกมแรกที่เล่นในอวกาศคือ Tetris ซึ่งเล่นบน Game Boy โดยนักบินอวกาศในปี 1993",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "นกหัวขวานพันลิ้นไว้รอบสมองเพื่อช่วยหลีกเลี่ยงการถูกกระทบกระแทก การใช้ลิ้นเป็นหมวกกันน็อคถือเป็นวิธีแก้ปัญหาที่อันตราย",
  },
  'pl': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Wrony nie tylko rozpoznają ludzkie twarze; potrafią zapamiętać ludzi, którzy źle je traktowali przez lata – a nawet ostrzegają inne wrony.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Koty spędzają około 70% swojego życia we śnie, zatem 10-letni kot nie śpi zaledwie od około 3 lat.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Miód nigdy się nie psuje; archeolodzy odkryli w egipskich piramidach słoje z miodem sprzed 3000 lat, które nadal nadawały się do spożycia.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Wydry morskie podczas snu trzymają się za ręce, aby nie rozpłynąć się pod wpływem prądu.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Na Wenus dzień jest dłuższy niż rok – obraca się wokół własnej osi wolniej niż okrąża Słońce.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Zapalniczka została wynaleziona przed zapałką – czasami „stara” technologia jest starsza, niż nam się wydaje.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Ośmiornice mają trzy serca i dziewięć mózgów – zapominanie nie wchodzi w grę.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Krowy mają „najlepszych przyjaciół” i mogą być poważnie zestresowane, a nawet płakać, gdy zostaną rozdzielone.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Pierwszy na świecie wirus komputerowy nazywał się „Creeper” i wyświetlał komunikat: „Jestem pnączem, złap mnie, jeśli potrafisz!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Przeciętna chmura może ważyć około 500 000 kg – jak ogromne stado słoni unoszące się nad jej głowami.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Ludzkie DNA jest w około 50% podobne do DNA banana, więc nazywanie banana jutro rano „moim rodzeństwem” nie jest całkowicie niesprawiedliwe.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Niedźwiedzie polarne w rzeczywistości mają czarną skórę, a ich futro jest przezroczyste; wyglądają na białe ze względu na sposób rozpraszania światła.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "W kosmosie naprawdę nie można płakać: bez grawitacji łzy nie spływają po twarzy – tworzą kroplę w oku.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest rośnie każdego roku o około 4 milimetry – Ziemia wciąż się zmienia.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "„Gwiżdżące” myszy zasadniczo śpiewają sobie nawzajem, ale na częstotliwościach zbyt wysokich, aby ludzie mogli je usłyszeć.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Rekiny są starsze od drzew – rekiny istnieją od około 400 milionów lat, a drzewa od około 350 milionów.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Banany to jagody z botanicznego punktu widzenia, ale truskawki nie – botanika może być dziwna.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Mrówka może unieść ciężar do 50 razy większy od swojej własnej wagi. Gdybyś był mrówką, mógłbyś sam podnieść samochód.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Wieża Eiffla może urosnąć latem o około 15 centymetrów ze względu na rozszerzalność cieplną.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Całkowita waga wszystkich ludzi na Ziemi jest mniej więcej porównywalna z całkowitą wagą wszystkich mrówek.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Leniwce potrafią wstrzymywać oddech pod wodą dłużej niż delfiny – nawet do około 40 minut.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Gołębie potrafią odróżnić obrazy Picassa i Moneta – okazuje się, że są bardziej obeznane ze sztuką, niż nam się wydaje.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Z GPS można korzystać bezpłatnie na całym świecie, ale według doniesień rząd USA wydaje około 2 milionów dolarów dziennie na jego utrzymanie.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Dziobaki nie mają żołądków – pokarm trafia z przełyku prosto do jelit.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Williamowi Szekspirowi przypisuje się pierwsze odnotowane użycie słowa „swagger” – nawet w XVI wieku miał styl.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Serce płetwal błękitny jest tak duże, że człowiek mógłby przepłynąć przez jego główne tętnice.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Mrówki nie mają płuc i nigdy tak naprawdę nie „śpią”; działają bez przerwy jak mali pracoholicy.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Na Saturnie i Jowiszu może dosłownie padać deszcz diamentów – najwyraźniej żyjemy na niewłaściwej planecie.",
    "Honeybees can recognize human faces and remember them individually.":
        "Pszczoły miodne potrafią rozpoznawać ludzkie twarze i zapamiętywać je indywidualnie.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "„Pot” hipopotama może wyglądać na różowo i działać zarówno jak filtr przeciwsłoneczny, jak i tarcza antybakteryjna.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Odchody wombata mają kształt sześcianu, dzięki czemu nie staczają się i skuteczniej oznaczają terytorium.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Orzechy nerkowca wyrastają poza jabłkiem nerkowca i zwisają na samym końcu – dziwnie zaskakujący projekt.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Rekiny są starsze niż pierścienie Saturna — istniały około milionów lat, zanim Saturn zyskał swój słynny blask.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Motyle smakują stopami – kiedy lądują na liściu, w zasadzie próbują obiadu.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Ślimak może spać nawet przez trzy lata, nie budząc się – szczerze mówiąc, można go porównać.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Oczy strusia są większe niż jego mózg – żyją na cienkiej granicy między patrzeniem a myśleniem.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingi rodzą się szare; ich słynny różowy kolor pochodzi od pigmentów znajdujących się w krewetkach i algach, które jedzą.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Wiewiórki pomagają co roku wyhodować tysiące nowych drzew, ponieważ zapominają, gdzie zakopały orzechy.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Pierwszą grą wideo, w którą grano w kosmosie, był Tetris, w który kosmonauta zagrał na Game Boyu w 1993 roku.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Dzięcioły owijają języki wokół mózgu, aby uniknąć wstrząśnień mózgu – używanie języka jako hełmu jest szalonym rozwiązaniem.",
  },
  'ca': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Els corbs no només reconeixen rostres humans; poden recordar persones que els van tractar malament durant anys, i fins i tot advertir altres corbs.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Els gats passen al voltant del 70% de la seva vida adormits, de manera que un gat de 10 anys només fa uns 3 anys que està despert.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "La mel mai es fa malbé; Els arqueòlegs han trobat pots de mel de 3.000 anys d'antiguitat a les piràmides egípcies que encara eren comestibles.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Les llúdrigues marines s'agafen de la mà mentre dormen per no separar-se en el corrent.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "A Venus, un dia és més llarg que un any: gira sobre el seu eix més lentament que no pas al voltant del Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "L'encenedor es va inventar abans que el lluminós; de vegades, la tecnologia \"vella\" és més antiga del que pensem.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Els pops tenen tres cors i nou cervells; oblidar les coses no és realment una opció.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Les vaques tenen \"millors amics\" i poden estressar-se seriosament, i fins i tot plorar, quan se separen.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "El primer virus informàtic del món es deia \"Creeper\" i mostrava: \"Sóc el creeper, atrapa'm si pots!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Un núvol mitjà pot pesar uns 500.000 kg, com un ramat massiu d'elefants que suren per sobre.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "L'ADN humà és aproximadament un 50% similar a l'ADN del plàtan, així que anomenar un plàtan \"el meu germà\" demà al matí no és totalment injust.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Els óssos polars en realitat tenen la pell negra i el seu pelatge és transparent; semblen blanques per com es dispersa la llum.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Realment no pots plorar a l'espai: sense gravetat, les llàgrimes no et corren per la cara; et formen una taca als ulls.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "L'Everest continua creixent uns 4 mil·límetres cada any; la Terra encara està canviant.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Els ratolins \"xiuladors\" es canten essencialment els uns als altres, però a freqüències massa altes perquè els humans els escoltin.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Els taurons són més vells que els arbres: els taurons fa uns 400 milions d'anys, els arbres uns 350 milions.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Els plàtans són botànicament baies, però les maduixes no; la botànica pot ser estranya.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Una formiga pot aixecar fins a 50 vegades el seu propi pes; si fossis una formiga, podríeu aixecar un cotxe sol.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel pot créixer uns 15 centímetres a l'estiu a causa de l'expansió tèrmica.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "El pes total de tots els humans a la Terra és aproximadament comparable al pes total de totes les formigues.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Els mansos poden aguantar la respiració sota l'aigua més temps que els dofins, fins a uns 40 minuts.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Els coloms poden dir la diferència entre les pintures de Picasso i Monet; resulta que tenen més coneixements artístics del que pensem.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "El GPS és d'ús gratuït a tot el món, però el govern dels Estats Units gasta uns 2 milions de dòlars al dia per mantenir-lo en funcionament.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Els ornitorincs no tenen estómac: el menjar va de l'esòfag directament als intestins.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "A William Shakespeare se li atribueix el primer ús registrat de la paraula \"swagger\"; fins i tot al segle XVI, tenia estil.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "El cor d'una balena blava és tan gran que un humà podria nedar per les seves artèries principals.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Les formigues no tenen pulmons, i mai realment \"dormen\"; operen sense parar com petits addictes al treball.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "A Saturn i Júpiter, literalment pot ploure diamants; pel que sembla, vivim al planeta equivocat.",
    "Honeybees can recognize human faces and remember them individually.":
        "Les abelles poden reconèixer rostres humans i recordar-los individualment.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "La \"suor\" d'hipopòtam pot semblar rosa i actua com a protector solar i com un escut antibacterià.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "La caca de wombat té forma de cub, de manera que no es desplaça i pot marcar el territori de manera més eficaç.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Els anacards creixen fora de la poma de l'anacard, penjant al final, un disseny estranyament sorprenent.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Els taurons són més antics que els anells de Saturn: eren uns milions d'anys abans que Saturn tingués el seu famós bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Les papallones saben amb els peus; quan aterren sobre una fulla, bàsicament estan provant el sopar.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un cargol pot dormir fins a tres anys sense despertar-se, sincerament, relacionable.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Els ulls d'un estruç són més grans que el seu cervell, vivint en la línia fina entre mirar i pensar.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Els flamencs neixen grisos; el seu famós rosa prové dels pigments de les gambes i les algues que mengen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Els esquirols ajuden a fer créixer milers d'arbres nous cada any perquè obliden on van enterrar els fruits secs.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "El primer videojoc que es va jugar a l'espai va ser Tetris, jugat en un Game Boy per un cosmonauta el 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Els picot emboliquen la llengua al voltant del cervell per evitar les commocions cerebrals; utilitzar la llengua com a casc és una solució salvatge.",
  },
  'zh-hant': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "烏鴉不僅能辨識人臉，還能辨識人臉。它們可以記住多年來虐待它們的人，甚至可以警告其他烏鴉。",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "貓一生中大約 70% 的時間都在睡覺，因此 10 歲的貓只有大約 3 年是清醒的。",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "蜂蜜永不變質；考古學家在埃及金字塔中發現了 3000 年前的蜂蜜罐，這些罐子仍然可以食用。",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "海獺睡覺時會手牽手，這樣它們就不會在水流中漂散。",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "在金星上，一天比一年長——它繞其軸旋轉的速度比繞太陽旋轉的速度慢。",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "打火機是在火柴棍之前發明的——有時「舊」技術比我們想像的更古老。",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "章魚有三顆心臟和九個大腦——忘記事情並不是真正的選擇。",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "乳牛有“最好的朋友”，當它們分開時，它們會承受很大的壓力，甚至哭泣。",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "世界上第一個電腦病毒被稱為“爬行者”，它顯示：“我是爬行者，如果你能抓住我！”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "一片雲的平均重量約為 50 萬公斤，就像一大群大象漂浮在頭頂上。",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "人類 DNA 與香蕉 DNA 相似度約為 50%，因此明天早上稱香蕉為「我的兄弟姐妹」並不完全不公平。",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "北極熊的皮膚實際上是黑色的，毛皮是透明的；由於光的散射，它們看起來是白色的。",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "你不可能在太空中真正哭泣：沒有重力，眼淚不會從你的臉上流下來——它們會在你的眼睛裡形成一個斑點。",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "珠穆朗瑪峰每年持續成長約 4 毫米——地球仍在變化。",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "「吹口哨」的老鼠本質上是在互相唱歌，但頻率太高，人類聽不到。",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "鯊魚比樹木更古老——鯊魚已經存在了大約 4 億年，樹木也有大約 3.5 億年。",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "香蕉在植物學上是漿果，但草莓不是——植物學可能很奇怪。",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "一隻螞蟻可以舉起自身重量 50 倍的物體——如果你是一隻螞蟻，你可以自己舉起一輛車。",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "由於熱膨脹，艾菲爾鐵塔在夏季可增長約 15 公分。",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "地球上所有人類的總重量大致相當於所有螞蟻的總重量。",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "樹懶在水下屏住呼吸的時間比海豚長，最長可達 40 分鐘左右。",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "鴿子可以區分畢卡索和莫內的畫作——事實證明它們比我們想像的更懂藝術。",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS 在全球範圍內免費使用，但據報道美國政府每天花費約 200 萬美元來維持其運作。",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "鴨嘴獸沒有胃，食物從食道直接進入腸道。",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "威廉·莎士比亞被認為是第一個使用「招搖」這個詞的人——即使在 16 世紀，他也很有風格。",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "藍鯨的心臟非常大，人類可以透過它的主要動脈游泳。",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "螞蟻沒有肺，而且它們從不真正「睡覺」；他們像小工作狂一樣不停地工作。",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "在土星和木星上，它確實會下鑽石雨——顯然我們生活在錯誤的星球上。",
    "Honeybees can recognize human faces and remember them individually.":
        "蜜蜂可以識別人臉並單獨記住他們。",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "河馬的「汗水」看起來是粉紅色的，它的作用既像防曬乳又像抗菌盾。",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "袋熊的糞便是立方體形狀的，因此不會滾動，可以更有效地標記領地。",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "腰果長在腰果蘋果外面，掛在腰果的末端——這是一個奇怪而令人驚訝的設計。",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "鯊魚比土星環還要古老——它們在土星獲得著名的光彩之前大約有數百萬年。",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "蝴蝶用腳來品嚐——當它們落在葉子上時，它們基本上是在品嚐晚餐。",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "一隻蝸牛可以睡長達三年而不醒來——老實說，這是有道理的。",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "鴕鳥的眼睛比大腦大——生活在觀察和思考之間。",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "火烈鳥出生時是灰色的；它們著名的粉紅色來自它們吃的蝦和藻類中的色素。",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "松鼠每年幫助種植數千棵新樹，因為它們忘記了將堅果埋在哪裡。",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "第一個在太空中玩的電玩遊戲是俄羅斯方塊，由一名太空人於 1993 年在 Game Boy 上玩。",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "啄木鳥用舌頭包裹大腦，以避免腦震盪——用舌頭作為頭盔是一個瘋狂的解決方案。",
  },
  'hr': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Vrane ne prepoznaju samo ljudska lica; mogu se sjetiti ljudi koji su se prema njima godinama loše ponašali — pa čak i upozoriti druge vrane.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Mačke provedu oko 70% svog života u snu—tako da je mačka stara 10 godina budna tek oko 3 godine.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Med se nikad ne kvari; arheolozi su u egipatskim piramidama pronašli 3000 godina stare posude s medom koje su još bile jestive.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Morske vidre drže se za ruke dok spavaju kako se ne bi razdvojile u struji.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Na Veneri je dan duži od godine - sporije se okreće oko svoje osi nego što kruži oko Sunca.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Upaljač je izumljen prije šibica - ponekad je \"stara\" tehnologija starija nego što mislimo.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Hobotnice imaju tri srca i devet mozgova - zaboravljanje stvari zapravo nije opcija.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Krave imaju \"najbolje prijatelje\" i mogu biti ozbiljno pod stresom - pa čak i plakati - kada su razdvojene.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Prvi računalni virus na svijetu zvao se \"Creeper\", a prikazivao je: \"Ja sam puzavac, uhvati me ako možeš!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Prosječan oblak može težiti oko 500 000 kg — poput golemog krda slonova koji lebde iznad nas.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Ljudski DNK je oko 50% sličan DNK banane—tako da nazvati bananu \"mojim bratom\" sutra ujutro nije potpuno nepravedno.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Polarni medvjedi zapravo imaju crnu kožu, a krzno im je prozirno; izgledaju bijele zbog toga kako se svjetlost raspršuje.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Ne možete stvarno plakati u svemiru: bez gravitacije, suze vam ne teku niz lice - one stvaraju mrlju u vašem oku.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest raste za oko 4 milimetra svake godine - Zemlja se i dalje mijenja.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Miševi koji \"zvižde\" u biti pjevaju jedni drugima, ali na frekvencijama previsokim da ih ljudi čuju.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Morski psi su stariji od drveća - morski psi postoje oko 400 milijuna godina, a drveće oko 350 milijuna.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Banane su botanički bobičasto voće, ali jagode nisu - botanika može biti čudna.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Mrav može podići težinu do 50 puta veću od vlastite — da ste mrav, mogli biste sami podići automobil.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Eiffelov toranj može ljeti narasti za oko 15 centimetara zbog toplinskog širenja.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Ukupna težina svih ljudi na Zemlji otprilike je usporediva s ukupnom težinom svih mrava.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Ljenjivci mogu zadržati dah pod vodom dulje od dupina—do otprilike 40 minuta.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Golubovi mogu uočiti razliku između Picassovih i Monetovih slika - pokazalo se da su bolje upućeni u umjetnost nego što mislimo.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS je besplatan za korištenje diljem svijeta, ali američka vlada navodno troši oko 2 milijuna američkih dolara dnevno kako bi ga održao u radu.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platypusi nemaju želudac - hrana ide iz jednjaka ravno u crijeva.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare je zaslužan za prvu zabilježenu upotrebu riječi \"swagger\" - čak je iu 16. stoljeću imao stila.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Srce plavog kita toliko je veliko da bi čovjek mogao plivati ​​kroz njegove glavne arterije.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Mravi nemaju pluća - i nikada ne \"spavaju\"; rade bez prestanka kao mali radoholičari.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Na Saturnu i Jupiteru može doslovno padati kiša dijamanata - očito živimo na pogrešnom planetu.",
    "Honeybees can recognize human faces and remember them individually.":
        "Pčele mogu prepoznati ljudska lica i zapamtiti ih pojedinačno.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "\"Znoj\" nilskog konja može izgledati ružičasto i djeluje kao krema za sunčanje i kao antibakterijski štit.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Kakica wombat je kockastog oblika, pa se ne otkotrlja i može učinkovitije označavati teritorij.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Indijski oraščići rastu izvan indijske jabuke, viseći na samom kraju - neobično iznenađujući dizajn.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Morski psi su stariji od Saturnovih prstenova - postojali su oko milijune godina prije nego što je Saturn dobio svoj poznati sjaj.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Leptiri kušaju svojim nogama - kad slete na list, zapravo kušaju večeru.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Puž može spavati i do tri godine a da se ne probudi - iskreno, relativno.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Oči noja su veće od njegovog mozga - žive na tankoj granici između gledanja i razmišljanja.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingosi se rađaju sivi; njihova poznata ružičasta dolazi od pigmenata u račićima i algama koje jedu.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Vjeverice pomažu u rastu tisuća novih stabala svake godine jer zaborave gdje su zakopale orahe.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Prva video igrica koja se igrala u svemiru bila je Tetris—igrao ju je kozmonaut na Game Boyu 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Djetlići omotavaju jezik oko svog mozga kako bi izbjegli potrese - korištenje jezika kao kacige je divlje rješenje.",
  },
  'cs': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Vrány nejenže rozpoznávají lidské tváře; dokážou si pamatovat lidi, kteří se k nim po léta chovali špatně – a dokonce varovat ostatní vrány.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Kočky tráví asi 70 % svého života spánkem – takže 10letá kočka je vzhůru jen asi 3 roky.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Med se nikdy nezkazí; archeologové našli v egyptských pyramidách 3000 let staré sklenice medu, které byly stále jedlé.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Mořské vydry se během spánku drží za ruce, aby se v proudu nerozpadly.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Na Venuši je den delší než rok – otáčí se kolem své osy pomaleji, než obíhá kolem Slunce.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Zapalovač byl vynalezen dříve než zápalka – někdy je „stará“ technologie starší, než si myslíme.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Chobotnice mají tři srdce a devět mozků – zapomenout na věci není ve skutečnosti možnost.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Krávy mají „nejlepší přátele“ a když jsou odděleny, mohou být vážně vystresované – a dokonce i plakat.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "První počítačový virus na světě se jmenoval „Creeper“ a zobrazoval: „Jsem liána, chyť mě, jestli to dokážeš!“",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Průměrný mrak může vážit kolem 500 000 kg – jako obrovské stádo slonů plující nad hlavou.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Lidská DNA je asi z 50 % podobná banánové DNA – takže říkat zítra ráno banánu „můj sourozenec“ není úplně nespravedlivé.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Lední medvědi mají ve skutečnosti černou kůži a jejich srst je průhledná; vypadají bíle, protože světlo rozptyluje.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Ve vesmíru opravdu nemůžete plakat: bez gravitace vám slzy netečou po tváři – tvoří kapku v oku.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest každým rokem roste asi o 4 milimetry – Země se stále mění.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "„Pískající“ myši si v podstatě zpívají navzájem, ale na frekvencích příliš vysokých na to, aby je lidé slyšeli.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Žraloci jsou starší než stromy – žraloci existují asi 400 milionů let, stromy asi 350 milionů.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Banány jsou botanicky bobule, ale jahody ne – botanika může být divná.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Mravenec dokáže zvednout až 50násobek své vlastní hmotnosti – pokud byste byli mravenci, mohli byste sami zvednout auto.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Eiffelova věž může v létě díky tepelné roztažnosti vyrůst asi o 15 centimetrů.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Celková hmotnost všech lidí na Zemi je zhruba srovnatelná s celkovou hmotností všech mravenců.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Lenoši dokážou zadržet dech pod vodou déle než delfíni – až asi 40 minut.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Holubi dokážou rozeznat rozdíl mezi obrazy Picassa a Moneta – ukázalo se, že jsou umělecky důvtipnější, než si myslíme.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS je zdarma k použití po celém světě, ale americká vláda údajně vynakládá kolem 2 milionů amerických dolarů denně na to, aby fungovala.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platypusové nemají žaludky – potrava jde z jícnu přímo do střev.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare je připisován prvnímu zaznamenanému použití slova „chvástat se“ – dokonce i v 16. století měl styl.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Srdce modré velryby je tak velké, že by člověk mohl proplouvat jejími hlavními tepnami.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Mravenci nemají plíce – a nikdy skutečně „nespí“; fungují nonstop jako malí workoholici.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Na Saturnu a Jupiteru může doslova pršet diamanty – zjevně žijeme na špatné planetě.",
    "Honeybees can recognize human faces and remember them individually.":
        "Včely dokážou rozpoznat lidské tváře a jednotlivě si je zapamatovat.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Hroší „pot“ může vypadat růžově a působí jako opalovací krém i jako antibakteriální štít.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Hovno vombatů má tvar kostky, takže se neodkutálí a může efektivněji označit území.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Kešu oříšky rostou mimo kešu jablko, visí na samém konci – podivně překvapivý design.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Žraloci jsou starší než Saturnovy prstence – byli asi miliony let předtím, než Saturn získal svůj slavný bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Motýli chutnají nohama – když přistanou na listu, v podstatě ochutnávají večeři.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Hlemýžď ​​může spát až tři roky, aniž by se probudil - upřímně řečeno, příbuzný.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Oči pštrosa jsou větší než jeho mozek – žijí na tenké hranici mezi pohledem a myšlením.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Plameňáci se rodí šedí; jejich slavná růžová pochází z pigmentů v krevetách a řasách, které jedí.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Veverky pomáhají každý rok vyrůst tisícům nových stromů, protože zapomínají, kde zakopaly ořechy.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "První videohra hraná ve vesmíru byla Tetris, kterou v roce 1993 hrál kosmonaut na Game Boy.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Datel si jazykem omotává mozek, aby se vyhnul otřesům mozku – používat jazyk jako helmu je divoké řešení.",
  },
  'da': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Krager genkender ikke kun menneskelige ansigter; de kan huske folk, der behandlede dem dårligt i årevis - og endda advare andre krager.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Katte bruger omkring 70 % af deres liv i søvn - så en 10-årig kat har kun været vågen i omkring 3 år.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Honning fordærves aldrig; arkæologer har fundet 3.000 år gamle krukker med honning i egyptiske pyramider, som stadig var spiselige.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Havodderne holder i hånden, mens de sover, så de ikke driver fra hinanden i strømmen.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "På Venus er en dag længere end et år – den roterer langsommere om sin akse, end den kredser om Solen.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Lighteren blev opfundet før tændstikken - nogle gange er \"gammel\" teknologi ældre, end vi tror.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Blæksprutter har tre hjerter og ni hjerner - at glemme ting er egentlig ikke en mulighed.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Køer har \"bedste venner\", og de kan blive alvorligt stressede - og endda græde - når de er adskilt.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Verdens første computervirus blev kaldt \"Creeper\", og den viste: \"Jeg er creeperen, fang mig, hvis du kan!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "En gennemsnitlig sky kan veje omkring 500.000 kg - som en massiv flok elefanter, der flyder over hovedet.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Menneskets DNA ligner cirka 50 % banan-DNA - så at kalde en banan \"min søskende\" i morgen tidlig er ikke helt uretfærdigt.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Isbjørne har faktisk sort hud, og deres pels er gennemsigtig; de ser hvide ud på grund af, hvordan lyset spredes.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Du kan ikke rigtig græde i rummet: uden tyngdekraft løber tårerne ikke ned af dit ansigt - de danner en klat i dit øje.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest bliver ved med at vokse med omkring 4 millimeter hvert år - Jorden er stadig under forandring.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "\"Fløjtende\" mus synger i det væsentlige for hinanden, men ved frekvenser, der er for høje for mennesker at høre.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Hajer er ældre end træer - hajer har eksisteret i omkring 400 millioner år, træer i omkring 350 millioner.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Bananer er botanisk bær, men jordbær er det ikke - botanik kan være underligt.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "En myre kan løfte op til 50 gange sin egen vægt - hvis du var en myre, kunne du løfte en bil alene.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Eiffeltårnet kan vokse med omkring 15 centimeter om sommeren på grund af termisk udvidelse.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Den samlede vægt af alle mennesker på Jorden er nogenlunde sammenlignelig med den samlede vægt af alle myrer.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Dovendyr kan holde vejret under vandet længere end delfiner - op til omkring 40 minutter.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Duer kan kende forskel på malerier af Picasso og Monet - det viser sig, at de er mere kunstkyndige, end vi tror.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS er gratis at bruge på verdensplan, men den amerikanske regering bruger angiveligt omkring 2 millioner amerikanske dollars om dagen for at holde den kørende.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Næbdyr har ikke maver - maden går fra spiserøret direkte til tarmene.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare er krediteret med den første registrerede brug af ordet \"swagger\" - selv i det 16. århundrede havde han stil.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "En blåhvals hjerte er så stort, at et menneske kan svømme gennem dens hovedpulsårer.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Myrer har ikke lunger - og de \"sover\" aldrig rigtigt; de opererer nonstop som små arbejdsnarkomaner.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "På Saturn og Jupiter kan det bogstaveligt talt regne med diamanter - tilsyneladende lever vi på den forkerte planet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Honningbier kan genkende menneskelige ansigter og huske dem individuelt.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Flodhests \"sved\" kan se lyserød ud og fungerer som både solcreme og et antibakterielt skjold.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Wombat afføring er terningformet, så den ruller ikke væk og kan markere territorium mere effektivt.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Cashewnødder vokser uden for cashewæblet og hænger til allersidst - et mærkeligt overraskende design.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Hajer er ældre end Saturns ringe - de var omkring millioner af år, før Saturn fik sin berømte bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Sommerfugle smager med deres fødder - når de lander på et blad, prøver de dybest set aftensmaden.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "En snegl kan sove i op til tre år uden at vågne - helt ærligt, relateret.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "En struds øjne er større end dens hjerne - lever på den fine linje mellem at se og tænke.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingoer er født grå; deres berømte pink kommer fra pigmenter i rejer og alger, de spiser.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Egern hjælper med at dyrke tusindvis af nye træer hvert år, fordi de glemmer, hvor de har begravet nødder.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Det første videospil, der blev spillet i rummet, var Tetris - spillet på en Game Boy af en kosmonaut i 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Spætter vikler deres tunger rundt om deres hjerner for at hjælpe med at undgå hjernerystelse - at bruge din tunge som hjelm er en vild løsning.",
  },
  'fi': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Variset eivät vain tunnista ihmisten kasvoja; he voivat muistaa ihmisiä, jotka ovat kohdelleet heitä huonosti vuosia – ja jopa varoittaa muita varisia.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Kissat viettävät noin 70 % elämästään unissa, joten 10-vuotias kissa on ollut hereillä vain noin 3 vuotta.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Hunaja ei pilaannu koskaan; arkeologit ovat löytäneet egyptiläisistä pyramideista 3000 vuotta vanhoja hunajapurkkeja, jotka olivat vielä syötäviä.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Merisaukot pitelevät kädestä nukkuessaan, jotta ne eivät ajaudu erilleen virrassa.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Venuksella päivä on pidempi kuin vuosi – se pyörii akselinsa ympäri hitaammin kuin aurinkoa.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Sytytin keksittiin ennen tulitikkua – joskus \"vanha\" tekniikka on vanhempi kuin luulemme.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Mustekalalla on kolme sydäntä ja yhdeksän aivoja – asioiden unohtaminen ei ole oikeastaan ​​vaihtoehto.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Lehmillä on \"parhaita ystäviä\", ja ne voivat stressaantua vakavasti – ja jopa itkeä – erottuaan.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Maailman ensimmäinen tietokonevirus oli nimeltään \"Creeper\", ja se näytti: \"Minä olen creeper, ota minut kiinni, jos voit!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Keskimääräinen pilvi voi painaa noin 500 000 kg – kuten pään yläpuolella kelluva massiivinen elefanttilauma.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Ihmisen DNA on noin 50-prosenttisesti samanlainen kuin banaanin DNA, joten banaanin kutsuminen \"sisarukselleni\" huomenna aamulla ei ole täysin epäreilua.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Jääkarhuilla on itse asiassa musta iho ja niiden turkki on läpinäkyvää; ne näyttävät valkoisilta valon hajoamisen vuoksi.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Et voi todella itkeä avaruudessa: ilman painovoimaa kyyneleet eivät valu alas kasvoillesi – ne muodostavat läiskän silmiisi.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest kasvaa jatkuvasti noin 4 millimetriä vuodessa – maapallo muuttuu edelleen.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "\"Vielävät\" hiiret laulavat toisilleen, mutta taajuuksilla, jotka ovat liian korkeita ihmisille.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Hait ovat vanhempia kuin puita – haita on ollut olemassa noin 400 miljoonaa vuotta, puita noin 350 miljoonaa vuotta.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Banaanit ovat kasvitieteellisesti marjoja, mutta mansikat eivät ole – kasvitiede voi olla outoa.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Muurahainen voi nostaa jopa 50 kertaa oman painonsa – jos olisit muurahainen, voisit nostaa auton itse.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Eiffel-torni voi kasvaa kesällä noin 15 senttimetriä lämpölaajenemisen vuoksi.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Kaikkien maan päällä olevien ihmisten kokonaispaino on suunnilleen verrattavissa kaikkien muurahaisten kokonaispainoon.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Laiskiaiset voivat pidätellä hengitystään veden alla pidempään kuin delfiinit – jopa noin 40 minuuttia.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Kyyhkyset pystyvät erottamaan Picasson ja Monetin maalaukset – osoittautuu, että ne ovat taidetaitoisempia kuin uskommekaan.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS:n käyttö on ilmaista maailmanlaajuisesti, mutta Yhdysvaltain hallituksen kerrotaan kuluttavan noin 2 miljoonaa dollaria päivässä sen ylläpitämiseen.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platypuksella ei ole vatsaa – ruoka menee ruokatorvesta suoraan suolistoon.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespearen ansioksi sanotaan sanan \"swagger\" ensimmäinen kirjattu käyttö – jopa 1500-luvulla hänellä oli tyyliä.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Sinivalaan sydän on niin suuri, että ihminen voisi uida sen päävaltimoiden läpi.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Muurahaisilla ei ole keuhkoja – eivätkä ne koskaan todella \"nuku\"; he toimivat taukoamatta kuin pienet työnarkomaanit.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Saturnuksella ja Jupiterilla voi kirjaimellisesti sataa timantteja – ilmeisesti elämme väärällä planeetalla.",
    "Honeybees can recognize human faces and remember them individually.":
        "Mehiläiset voivat tunnistaa ihmisten kasvot ja muistaa ne yksilöllisesti.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Virtahepo \"hiki\" voi näyttää vaaleanpunaiselta ja toimii sekä aurinkosuojana että antibakteerisena suojana.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Wombat-kakka on kuution muotoinen, joten se ei rullaa pois ja voi merkitä alueen tehokkaammin.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Cashewpähkinät kasvavat cashew-omenan ulkopuolella ja roikkuvat aivan lopussa – oudon yllättävä malli.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Hait ovat vanhempia kuin Saturnuksen renkaat – ne olivat noin miljoonia vuosia ennen kuin Saturnus sai kuuluisan blinginsä.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Perhoset maistuvat jaloillaan – kun ne laskeutuvat lehdelle, ne pohjimmiltaan maistelevat illallista.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Etana voi nukkua jopa kolme vuotta heräämättä – rehellisesti sanottuna.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Strutsin silmät ovat suurempia kuin sen aivot – ne elävät katselun ja ajattelun välisellä hienolla rajalla.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingot syntyvät harmaina; niiden kuuluisa vaaleanpunainen tulee heidän syömiensä katkarapujen ja levien pigmenteistä.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Oravat auttavat kasvattamaan tuhansia uusia puita joka vuosi, koska he unohtavat, minne he hautasivat pähkinät.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Ensimmäinen avaruudessa pelattu videopeli oli Tetris – kosmonautti pelasi Game Boylla vuonna 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Tikat kiertävät kielensä aivojensa ympärille välttääkseen aivotärähdyksiä – kielen käyttäminen kypäränä on villi ratkaisu.",
  },
  'fr-ca': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Les corbeaux ne reconnaissent pas seulement les visages humains ; ils peuvent se souvenir des personnes qui les ont maltraités pendant des années et même avertir les autres corbeaux.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Les chats passent environ 70 % de leur vie à dormir. Ainsi, un chat de 10 ans n'est éveillé que depuis environ 3 ans.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Le miel ne se gâte jamais ; Des archéologues ont découvert dans des pyramides égyptiennes des pots de miel vieux de 3 000 ans et encore comestibles.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Les loutres de mer se tiennent la main pendant leur sommeil pour ne pas se séparer dans le courant.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Sur Vénus, un jour dure plus d’un an : il tourne sur son axe plus lentement qu’il ne tourne autour du Soleil.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Le briquet a été inventé avant l’allumette – parfois la « vieille » technologie est plus ancienne qu’on ne le pense.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Les poulpes ont trois cœurs et neuf cerveaux : oublier des choses n’est pas vraiment une option.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Les vaches ont des « meilleures amies » et elles peuvent être très stressées et même pleurer lorsqu’elles sont séparées.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Le premier virus informatique au monde s’appelait « Creeper » et il affichait : « Je suis le creeper, attrape-moi si tu peux ! »",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Un nuage moyen peut peser environ 500 000 kg, comme un énorme troupeau d’éléphants flottant au-dessus de nous.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "L’ADN humain est similaire à environ 50 % à l’ADN de la banane. Il n’est donc pas totalement injuste d’appeler une banane « mon frère » demain matin.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Les ours polaires ont en fait la peau noire et leur fourrure est transparente ; ils semblent blancs à cause de la façon dont la lumière se disperse.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Vous ne pouvez pas vraiment pleurer dans l’espace : sans gravité, les larmes ne coulent pas sur votre visage : elles forment une goutte dans vos yeux.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Le mont Everest continue de croître d’environ 4 millimètres chaque année : la Terre continue de changer.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Les souris « sifflantes » chantent essentiellement entre elles, mais à des fréquences trop élevées pour que les humains puissent les entendre.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Les requins sont plus vieux que les arbres : les requins existent depuis environ 400 millions d'années, les arbres depuis environ 350 millions d'années.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Les bananes sont des baies botaniques, mais les fraises ne le sont pas : la botanique peut être étrange.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Une fourmi peut soulever jusqu’à 50 fois son propre poids. Si vous étiez une fourmi, vous pourriez soulever une voiture par vous-même.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Tour Eiffel peut s'agrandir d'environ 15 centimètres en été en raison de la dilatation thermique.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Le poids total de tous les humains sur Terre est à peu près comparable au poids total de toutes les fourmis.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Les paresseux peuvent retenir leur souffle sous l’eau plus longtemps que les dauphins, jusqu’à environ 40 minutes.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Les pigeons peuvent faire la différence entre les peintures de Picasso et de Monet – il s’avère qu’ils sont plus doués en art qu’on ne le pense.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "L'utilisation du GPS est gratuite dans le monde entier, mais le gouvernement américain dépenserait environ 2 millions de dollars américains par jour pour le faire fonctionner.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Les ornithorynques n’ont pas d’estomac : la nourriture va de l’œsophage directement aux intestins.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "On attribue à William Shakespeare la première utilisation enregistrée du mot « swagger » : même au XVIe siècle, il avait du style.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Le cœur d’une baleine bleue est si gros qu’un humain pourrait nager dans ses artères principales.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Les fourmis n’ont pas de poumons et ne « dorment » jamais vraiment ; ils opèrent sans arrêt comme de minuscules bourreaux de travail.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Sur Saturne et Jupiter, il peut littéralement pleuvoir des diamants. Apparemment, nous vivons sur la mauvaise planète.",
    "Honeybees can recognize human faces and remember them individually.":
        "Les abeilles peuvent reconnaître les visages humains et s’en souvenir individuellement.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "La « sueur » d’hippopotame peut paraître rose et agit à la fois comme un écran solaire et un bouclier antibactérien.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Les crottes de wombat sont en forme de cube, elles ne roulent donc pas et peuvent marquer le territoire plus efficacement.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Les noix de cajou poussent à l’extérieur de la pomme de cajou, suspendues à l’extrémité – un design étrangement surprenant.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Les requins sont plus vieux que les anneaux de Saturne : ils existaient environ des millions d’années avant que Saturne n’obtienne son fameux bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Les papillons goûtent avec leurs pattes : lorsqu’ils atterrissent sur une feuille, ils goûtent essentiellement à un dîner.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un escargot peut dormir jusqu’à trois ans sans se réveiller – honnêtement, c’est pertinent.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Les yeux d’une autruche sont plus grands que son cerveau et vivent à la frontière ténue entre regarder et penser.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Les flamants naissent gris ; leur célèbre rose provient des pigments des crevettes et des algues qu'ils mangent.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Les écureuils contribuent à faire pousser des milliers de nouveaux arbres chaque année parce qu’ils oublient où ils ont enterré les noix.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Le premier jeu vidéo joué dans l'espace fut Tetris, joué sur une Game Boy par un cosmonaute en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Les pics enroulent leur langue autour de leur cerveau pour éviter les commotions cérébrales. Utiliser votre langue comme casque est une solution folle.",
  },
  'el': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Τα κοράκια δεν αναγνωρίζουν μόνο ανθρώπινα πρόσωπα. μπορούν να θυμούνται ανθρώπους που τους φέρθηκαν άσχημα για χρόνια—και ακόμη και να προειδοποιήσουν άλλα κοράκια.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Οι γάτες περνούν περίπου το 70% της ζωής τους στον ύπνο — έτσι μια 10χρονη γάτα είναι ξύπνια μόνο για περίπου 3 χρόνια.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Το μέλι δεν χαλάει ποτέ. Οι αρχαιολόγοι βρήκαν βάζα 3.000 ετών με μέλι σε αιγυπτιακές πυραμίδες που ήταν ακόμα βρώσιμα.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Οι θαλάσσιες ενυδρίδες κρατιούνται από τα χέρια ενώ κοιμούνται για να μην απομακρυνθούν στο ρεύμα.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Στην Αφροδίτη, μια μέρα είναι μεγαλύτερη από ένα χρόνο—περιστρέφεται γύρω από τον άξονά της πιο αργά από ό,τι περιστρέφεται γύρω από τον Ήλιο.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Ο αναπτήρας εφευρέθηκε πριν από το σπιρτόξυλο—μερικές φορές η «παλιά» τεχνολογία είναι παλαιότερη από όσο νομίζουμε.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Τα χταπόδια έχουν τρεις καρδιές και εννέα εγκεφάλους - το να ξεχνάς πράγματα δεν είναι πραγματικά μια επιλογή.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Οι αγελάδες έχουν «τους καλύτερους φίλους» και μπορεί να αγχωθούν σοβαρά - ακόμα και να κλάψουν - όταν χωρίζονται.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Ο πρώτος ιός υπολογιστή στον κόσμο ονομαζόταν \"Creeper\" και έδειχνε: \"Είμαι ο αναρριχητικός ιός, πιάστε με αν μπορείτε!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Ένα μέσο σύννεφο μπορεί να ζυγίζει περίπου 500.000 κιλά—όπως ένα τεράστιο κοπάδι ελεφάντων που επιπλέει από πάνω.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Το ανθρώπινο DNA είναι περίπου 50% παρόμοιο με το DNA της μπανάνας — επομένως το να αποκαλώ μια μπανάνα «αδελφό μου» αύριο το πρωί δεν είναι εντελώς άδικο.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Οι πολικές αρκούδες έχουν στην πραγματικότητα μαύρο δέρμα και η γούνα τους είναι διαφανής. φαίνονται άσπρα λόγω του πώς διαχέεται το φως.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Δεν μπορείτε πραγματικά να κλάψετε στο διάστημα: χωρίς βαρύτητα, τα δάκρυα δεν τρέχουν στο πρόσωπό σας - σχηματίζουν μια σταγόνα στο μάτι σας.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Το Έβερεστ συνεχίζει να αυξάνεται κατά περίπου 4 χιλιοστά κάθε χρόνο—η Γη εξακολουθεί να αλλάζει.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Τα ποντίκια που «σφυρίζουν» ουσιαστικά τραγουδούν μεταξύ τους, αλλά σε πολύ υψηλές συχνότητες για να τις ακούσουν οι άνθρωποι.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Οι καρχαρίες είναι παλαιότεροι από τα δέντρα—οι καρχαρίες υπάρχουν εδώ και περίπου 400 εκατομμύρια χρόνια, τα δέντρα για περίπου 350 εκατομμύρια.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Οι μπανάνες είναι βοτανικά μούρα, αλλά οι φράουλες δεν είναι - η βοτανική μπορεί να είναι περίεργη.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Ένα μυρμήγκι μπορεί να σηκώσει έως και 50 φορές το βάρος του—αν ήσασταν μυρμήγκι, θα μπορούσατε να σηκώσετε ένα αυτοκίνητο μόνος σας.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Ο Πύργος του Άιφελ μπορεί να μεγαλώσει κατά περίπου 15 εκατοστά το καλοκαίρι λόγω της θερμικής διαστολής.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Το συνολικό βάρος όλων των ανθρώπων στη Γη είναι περίπου συγκρίσιμο με το συνολικό βάρος όλων των μυρμηγκιών.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Οι βραδύποδες μπορούν να κρατήσουν την αναπνοή τους κάτω από το νερό περισσότερο από τα δελφίνια—έως περίπου 40 λεπτά.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Τα περιστέρια μπορούν να διακρίνουν τη διαφορά μεταξύ των πινάκων του Πικάσο και του Μονέ - αποδεικνύεται ότι είναι πιο γνώστες της τέχνης από όσο νομίζουμε.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Το GPS είναι δωρεάν για χρήση παγκοσμίως, αλλά η κυβέρνηση των ΗΠΑ φέρεται να ξοδεύει περίπου 2 εκατομμύρια δολάρια την ημέρα για να το διατηρήσει σε λειτουργία.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Οι πλατύπους δεν έχουν στομάχι - η τροφή πηγαίνει από τον οισοφάγο κατευθείαν στα έντερα.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Στον William Shakespeare πιστώνεται η πρώτη καταγεγραμμένη χρήση της λέξης «swagger»—ακόμα και τον 16ο αιώνα, είχε στυλ.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Η καρδιά μιας μπλε φάλαινας είναι τόσο μεγάλη που ένας άνθρωπος μπορεί να κολυμπήσει μέσα από τις κύριες αρτηρίες της.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Τα μυρμήγκια δεν έχουν πνεύμονες—και ποτέ δεν «κοιμούνται» αληθινά. λειτουργούν ασταμάτητα σαν μικροσκοπικοί εργασιομανείς.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Στον Κρόνο και τον Δία, μπορεί κυριολεκτικά να βρέχει διαμάντια - προφανώς ζούμε σε λάθος πλανήτη.",
    "Honeybees can recognize human faces and remember them individually.":
        "Οι μέλισσες μπορούν να αναγνωρίσουν ανθρώπινα πρόσωπα και να τα θυμούνται μεμονωμένα.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Ο «ιδρώτας» του ιπποπόταμου μπορεί να φαίνεται ροζ και λειτουργεί τόσο σαν αντηλιακό όσο και σαν αντιβακτηριδιακή ασπίδα.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Το Wombat Poop έχει σχήμα κύβου, επομένως δεν κυλάει και μπορεί να σημαδέψει την περιοχή πιο αποτελεσματικά.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Τα κάσιους αναπτύσσονται έξω από το μήλο των ανακαρδιοειδών, κρέμονται στο τέλος - ένα παράξενα εκπληκτικό σχέδιο.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Οι καρχαρίες είναι παλαιότεροι από τους δακτυλίους του Κρόνου—ήταν περίπου εκατομμύρια χρόνια πριν ο Κρόνος αποκτήσει το διάσημο bling του.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Οι πεταλούδες γεύονται με τα πόδια τους - όταν προσγειώνονται σε ένα φύλλο, βασικά δοκιμάζουν δείπνο.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Ένα σαλιγκάρι μπορεί να κοιμηθεί για έως και τρία χρόνια χωρίς να ξυπνήσει — ειλικρινά, είναι σχετικό.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Τα μάτια μιας στρουθοκαμήλου είναι μεγαλύτερα από τον εγκέφαλό της - ζουν στη λεπτή γραμμή μεταξύ του βλέμματος και της σκέψης.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Τα φλαμίνγκο γεννιούνται γκρίζα. Το διάσημο ροζ τους προέρχεται από χρωστικές ουσίες σε γαρίδες και φύκια που τρώνε.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Οι σκίουροι βοηθούν στην ανάπτυξη χιλιάδων νέων δέντρων κάθε χρόνο επειδή ξεχνούν πού έθαψαν τους ξηρούς καρπούς.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Το πρώτο βιντεοπαιχνίδι που παίχτηκε στο διάστημα ήταν το Tetris — παίχτηκε σε Game Boy από έναν κοσμοναύτη το 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Οι δρυοκολάπτες τυλίγουν τη γλώσσα τους γύρω από τον εγκέφαλό τους για να αποφύγουν τα εγκεφαλικά επεισόδια - η χρήση της γλώσσας σας ως κράνος είναι μια άγρια ​​λύση.",
  },
  'he': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "עורבים לא רק מזהים פנים אנושיות; הם יכולים לזכור אנשים שהתייחסו אליהם רע במשך שנים - ואפילו להזהיר עורבים אחרים.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "חתולים מבלים כ-70% מחייהם בשינה - כך שחתול בן 10 היה ער רק כ-3 שנים.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "דבש לעולם אינו מתקלקל; ארכיאולוגים מצאו צנצנות דבש בנות 3,000 שנה בפירמידות מצריות שעדיין היו אכילות.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "לוטרות הים מחזיקות ידיים בזמן שהן ישנות כדי שלא יתרחקו בזרם.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "בנוגה, יום ארוך משנה - הוא מסתובב על צירו לאט יותר ממה שהוא מקיף את השמש.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "המצית הומצא לפני הגפרור - לפעמים הטכנולוגיה ה\"ישנה\" ישנה ממה שאנחנו חושבים.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "לתמנונים יש שלושה לבבות ותשעה מוחות - לשכוח דברים זו לא באמת אופציה.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "לפרות יש \"חברים הכי טובים\", והן עלולות להיכנס ללחץ רציני - ואפילו לבכות - כשהן נפרדות.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "וירוס המחשב הראשון בעולם נקרא \"Creeper\", והוא הציג: \"אני ה-creeper, תפוס אותי אם אתה יכול!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "ענן ממוצע יכול לשקול בסביבות 500,000 ק\"ג - כמו עדר עצום של פילים שצף מעליו.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "ה-DNA האנושי דומה בכ-50% ל-DNA של בננה - אז לקרוא לבננה \"אחי\" מחר בבוקר זה לא לגמרי לא הוגן.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "לדובי הקוטב יש למעשה עור שחור, והפרוות שלהם שקופה; הם נראים לבנים בגלל איך האור מתפזר.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "אתה לא באמת יכול לבכות בחלל: ללא כוח הכבידה, הדמעות לא זולגות על פניך - הן יוצרות כתם בעין שלך.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "הר האוורסט ממשיך לגדול בכ-4 מילימטרים בכל שנה - כדור הארץ עדיין משתנה.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "עכברים \"שורקים\" בעצם שרים זה לזה, אבל בתדרים גבוהים מכדי שבני אדם יוכלו לשמוע.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "כרישים מבוגרים יותר מעצים - כרישים קיימים כ-400 מיליון שנה, עצים כ-350 מיליון.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "בננות הן פירות יער מבחינה בוטנית, אבל תותים לא - בוטניקה יכולה להיות מוזרה.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "נמלה יכולה להרים עד פי 50 ממשקלה - אם היית נמלה, יכולת להרים מכונית לבד.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "מגדל אייפל יכול לגדול בכ-15 סנטימטרים בקיץ עקב התפשטות תרמית.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "המשקל הכולל של כל בני האדם על פני כדור הארץ דומה בערך למשקל הכולל של כל הנמלים.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "עצלנים יכולים לעצור את נשימתם מתחת למים יותר מדולפינים - עד כ-40 דקות.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "יונים יכולות להבחין בהבדל בין ציורים של פיקאסו ומונה - מסתבר שהן יותר מבינות אמנות ממה שאנחנו חושבים.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS הוא חופשי לשימוש ברחבי העולם, אך לפי הדיווחים ממשלת ארה\"ב מוציאה כ-2 מיליון דולר ביום כדי להמשיך לפעול.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "לפלטיפוסים אין קיבה - האוכל עובר מהוושט היישר אל המעיים.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "לוויליאם שייקספיר מיוחס השימוש המתועד הראשון במילה \"סוואגר\" - אפילו במאה ה-16, היה לו סטייל.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "הלב של לוויתן כחול כל כך גדול שאדם יכול לשחות דרך העורקים הראשיים שלו.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "לנמלים אין ריאות - והן אף פעם לא באמת \"ישנות\"; הם פועלים ללא הפסקה כמו מכורי עבודה זעירים.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "על שבתאי וצדק, זה יכול ממש להמטיר יהלומים - כנראה שאנחנו חיים על הפלנטה הלא נכונה.",
    "Honeybees can recognize human faces and remember them individually.":
        "דבורי דבש יכולות לזהות פנים אנושיות ולזכור אותן בנפרד.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "\"זיעה\" היפופוטמית יכולה להיראות ורודה ומתנהגת גם כמו קרם הגנה וגם כמגן אנטיבקטריאלי.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "קקי וומבט הוא בצורת קובייה, כך שהוא אינו מתגלגל ויכול לסמן טריטוריה בצורה יעילה יותר.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "אגוזי קשיו גדלים מחוץ לתפוח הקשיו, תלויים ממש בסוף - עיצוב מפתיע באופן מוזר.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "כרישים מבוגרים יותר מהטבעות של שבתאי - הם היו בסביבות מיליוני שנים לפני ששבתאי קיבל את הבלינג המפורסם שלו.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "פרפרים טועמים ברגליהם - כשהם נוחתים על עלה, הם בעצם דוגמים ארוחת ערב.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "חילזון יכול לישון עד שלוש שנים מבלי להתעורר - בכנות, ניתן לקשר.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "עיניו של יען גדולות מהמוח שלו - חיים על הגבול הדק שבין הסתכלות וחשיבה.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "פלמינגו נולדים אפורים; הוורוד המפורסם שלהם מגיע מפיגמנטים בשרימפס ובאצות שהם אוכלים.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "סנאים עוזרים לגדל אלפי עצים חדשים מדי שנה, כי הם שוכחים היכן קברו אגוזים.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "משחק הווידאו הראשון ששיחק בחלל היה טטריס - שיחק ב-Game Boy על ידי קוסמונאוט ב-1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "נקרים עוטפים את לשונם סביב מוחם כדי למנוע זעזוע מוח - השימוש בלשון כקסדה הוא פתרון פרוע.",
  },
  'ms': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Gagak tidak hanya mengenali wajah manusia; mereka boleh mengingati orang yang melayan mereka dengan teruk selama bertahun-tahun—malah memberi amaran kepada burung gagak lain.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Kucing menghabiskan kira-kira 70% daripada kehidupan mereka untuk tidur—jadi kucing berusia 10 tahun telah terjaga selama kira-kira 3 tahun sahaja.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Madu tidak pernah rosak; ahli arkeologi telah menemui balang madu berusia 3,000 tahun di piramid Mesir yang masih boleh dimakan.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Berang-berang laut berpegangan tangan semasa mereka tidur supaya mereka tidak hanyut dalam arus.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Di Zuhrah, satu hari lebih lama daripada setahun—ia berputar pada paksinya lebih perlahan daripada mengelilingi Matahari.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Pemetik api dicipta sebelum batang mancis—kadangkala teknologi \"lama\" lebih tua daripada yang kita sangka.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Sotong mempunyai tiga hati dan sembilan otak—melupakan sesuatu bukanlah satu pilihan.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Lembu mempunyai \"kawan baik\", dan mereka boleh mendapat tekanan yang serius-dan juga menangis-apabila dipisahkan.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Virus komputer pertama di dunia dipanggil \"Creeper,\" dan ia memaparkan: \"Saya yang menjalar, tangkap saya jika anda boleh!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Purata awan boleh mempunyai berat sekitar 500,000 kg—seperti sekumpulan besar gajah yang terapung di atas kepala.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "DNA manusia kira-kira 50% serupa dengan DNA pisang—jadi memanggil pisang sebagai “adik saya” pagi esok bukanlah tidak adil.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Beruang kutub sebenarnya mempunyai kulit hitam, dan bulunya telus; mereka kelihatan putih kerana bagaimana cahaya tersebar.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Anda tidak boleh benar-benar menangis di angkasa: tanpa graviti, air mata tidak mengalir ke muka anda-ia membentuk gumpalan di mata anda.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Gunung Everest terus berkembang kira-kira 4 milimeter setiap tahun—Bumi masih berubah.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Tikus \"bersiul\" pada dasarnya menyanyi antara satu sama lain, tetapi pada frekuensi yang terlalu tinggi untuk didengari manusia.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Jerung lebih tua daripada pokok-jerung telah wujud selama kira-kira 400 juta tahun, pokok selama kira-kira 350 juta.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Pisang adalah buah beri secara botani, tetapi strawberi tidak—botani boleh menjadi pelik.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Seekor semut boleh mengangkat sehingga 50 kali ganda beratnya sendiri—jika anda seorang semut, anda boleh mengangkat kereta sendiri.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Menara Eiffel boleh tumbuh kira-kira 15 sentimeter pada musim panas kerana pengembangan haba.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Jumlah berat semua manusia di Bumi adalah kira-kira setanding dengan jumlah berat semua semut.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Sloth boleh menahan nafas di dalam air lebih lama daripada ikan lumba-lumba—sehingga kira-kira 40 minit.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Merpati boleh membezakan antara lukisan oleh Picasso dan Monet—ternyata mereka lebih celik seni daripada yang kita fikirkan.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS adalah percuma untuk digunakan di seluruh dunia, tetapi kerajaan A.S. dilaporkan membelanjakan sekitar 2 juta dolar A.S. sehari untuk memastikan ia berjalan.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platipus tidak mempunyai perut-makanan pergi dari esofagus terus ke usus.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare dikreditkan dengan penggunaan pertama perkataan \"sombong\" yang direkodkan—walaupun pada abad ke-16, dia mempunyai gaya.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Jantung ikan paus biru sangat besar sehingga manusia boleh berenang melalui arteri utamanya.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Semut tidak mempunyai paru-paru-dan mereka tidak pernah benar-benar \"tidur\"; mereka beroperasi tanpa henti seperti orang gila kerja.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Pada Zuhal dan Musytari, ia benar-benar boleh menghujani berlian-nampaknya kita hidup di planet yang salah.",
    "Honeybees can recognize human faces and remember them individually.":
        "Lebah madu boleh mengenali wajah manusia dan mengingatnya secara individu.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Hippo \"peluh\" boleh kelihatan merah jambu dan bertindak seperti pelindung matahari dan perisai antibakteria.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Najis wombat berbentuk kiub, jadi ia tidak bergolek dan boleh menandakan wilayah dengan lebih berkesan.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Gajus tumbuh di luar epal gajus, tergantung di hujungnya—reka bentuk yang mengejutkan.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Jerung lebih tua daripada cincin Saturnus-ia adalah sekitar berjuta-juta tahun sebelum Zuhal mendapat bling terkenalnya.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Rama-rama merasa dengan kakinya-apabila mereka mendarat di atas daun, mereka pada asasnya mengambil sampel makan malam.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Seekor siput boleh tidur sehingga tiga tahun tanpa bangun—sejujurnya, boleh dikaitkan.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Mata burung unta lebih besar daripada otaknya—hidup dalam garis halus antara melihat dan berfikir.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingo dilahirkan kelabu; merah jambu terkenal mereka berasal dari pigmen dalam udang dan alga yang mereka makan.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Tupai membantu menanam beribu-ribu pokok baru setiap tahun kerana mereka lupa di mana mereka menanam kacang.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Permainan video pertama yang dimainkan di angkasa ialah Tetris—dimainkan pada Game Boy oleh angkasawan pada tahun 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Burung belatuk membungkus lidah mereka di sekeliling otak mereka untuk membantu mengelakkan gegaran—menggunakan lidah anda sebagai topi keledar adalah penyelesaian liar.",
  },
  'no': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Kråker gjenkjenner ikke bare menneskelige ansikter; de kan huske folk som behandlet dem dårlig i årevis – og til og med advare andre kråker.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Katter tilbringer omtrent 70 % av livet i søvn – så en 10 år gammel katt har vært våken i bare omtrent 3 år.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Honning blir aldri ødelagt; arkeologer har funnet 3000 år gamle krukker med honning i egyptiske pyramider som fortsatt var spiselige.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Sjøaure holder hender mens de sover slik at de ikke driver fra hverandre i strømmen.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "På Venus er en dag lengre enn ett år – den roterer om sin akse saktere enn den går i bane rundt solen.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Lighteren ble oppfunnet før fyrstikken - noen ganger er \"gammel\" teknologi eldre enn vi tror.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Blekkspruter har tre hjerter og ni hjerner - å glemme ting er egentlig ikke et alternativ.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Kyr har \"beste venner\", og de kan bli alvorlig stresset – og til og med gråte – når de er separert.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Verdens første datavirus ble kalt \"Creeper\", og det viste: \"I'm the creeper, catch me if you can!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "En gjennomsnittlig sky kan veie rundt 500 000 kg – som en massiv flokk med elefanter som flyter over hodet.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Menneskelig DNA er omtrent 50 % lik banan-DNA - så å kalle en banan \"min søsken\" i morgen tidlig er ikke helt urettferdig.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Isbjørner har faktisk svart hud, og pelsen deres er gjennomsiktig; de ser hvite ut på grunn av hvordan lyset spres.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Du kan egentlig ikke gråte i verdensrommet: uten tyngdekraften renner ikke tårer nedover ansiktet ditt – de danner en klump i øyet ditt.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest fortsetter å vokse med rundt 4 millimeter hvert år—Jorden er fortsatt i endring.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "\"Plystrende\" mus synger i hovedsak til hverandre, men med frekvenser som er for høye for mennesker å høre.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Haier er eldre enn trær - haier har eksistert i omtrent 400 millioner år, trær i omtrent 350 millioner.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Bananer er botanisk bær, men jordbær er det ikke - botanikk kan være rart.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "En maur kan løfte opptil 50 ganger sin egen vekt - hvis du var en maur, kunne du løfte en bil alene.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Eiffeltårnet kan vokse med rundt 15 centimeter om sommeren på grunn av termisk ekspansjon.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Den totale vekten av alle mennesker på jorden er omtrent sammenlignbar med totalvekten til alle maur.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Dovendyr kan holde pusten under vann lenger enn delfiner - opptil 40 minutter.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Duer kan se forskjell på malerier av Picasso og Monet - viser seg at de er mer kunstkyndige enn vi tror.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS er gratis å bruke over hele verden, men den amerikanske regjeringen bruker angivelig rundt 2 millioner amerikanske dollar om dagen for å holde den i gang.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Nebbdyr har ikke mage - maten går fra spiserøret rett til tarmen.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare er kreditert med den første registrerte bruken av ordet \"swagger\" - selv på 1500-tallet hadde han stil.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "En blåhvals hjerte er så stort at et menneske kan svømme gjennom hovedpulsårene.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Maur har ikke lunger - og de \"sover\" aldri virkelig; de opererer nonstop som bittesmå arbeidsnarkomane.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "På Saturn og Jupiter kan det bokstavelig talt regne diamanter - tilsynelatende lever vi på feil planet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Honningbier kan gjenkjenne menneskelige ansikter og huske dem individuelt.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Flodhests \"svette\" kan se rosa ut og fungerer som både solkrem og et antibakterielt skjold.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Wombat-bajs er kubeformet, så den ruller ikke bort og kan markere territorium mer effektivt.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Cashewnøtter vokser utenfor cashew-eplet, og henger helt til slutt – et merkelig overraskende design.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Haier er eldre enn Saturns ringer - de var rundt millioner av år før Saturn fikk sin berømte bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Sommerfugler smaker med føttene - når de lander på et blad, smaker de i utgangspunktet middag.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "En snegl kan sove i opptil tre år uten å våkne – ærlig talt, relaterbar.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "En struts øyne er større enn hjernen – lever på den fine linjen mellom å se og tenke.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingoer er født grå; deres berømte rosa kommer fra pigmenter i reker og alger de spiser.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Ekorn hjelper til med å vokse tusenvis av nye trær hvert år fordi de glemmer hvor de begravde nøtter.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Det første videospillet som ble spilt i verdensrommet var Tetris - spilt på en Game Boy av en kosmonaut i 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Hakkespetter legger tungen rundt hjernen for å unngå hjernerystelse – å bruke tungen som hjelm er en vill løsning.",
  },
  'pt-pt': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Os corvos não reconhecem apenas rostos humanos; eles podem se lembrar de pessoas que os trataram mal durante anos – e até mesmo alertar outros corvos.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Os gatos passam cerca de 70% de suas vidas dormindo – então um gato de 10 anos fica acordado há apenas cerca de 3 anos.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "O mel nunca estraga; arqueólogos encontraram potes de mel de 3.000 anos em pirâmides egípcias que ainda eram comestíveis.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "As lontras marinhas dão as mãos enquanto dormem para não se separarem na correnteza.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Em Vênus, um dia é mais longo que um ano – ele gira em torno de seu eixo mais lentamente do que orbita o Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "O isqueiro foi inventado antes do palito de fósforo – às vezes a tecnologia “antiga” é mais antiga do que pensamos.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Os polvos têm três corações e nove cérebros – esquecer as coisas não é realmente uma opção.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "As vacas têm “melhores amigas” e podem ficar seriamente estressadas – e até chorar – quando separadas.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "O primeiro vírus de computador do mundo chamava-se “Creeper” e exibia: “Eu sou o rastejador, pegue-me se puder!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Uma nuvem média pode pesar cerca de 500.000 kg – como uma enorme manada de elefantes flutuando no alto.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "O DNA humano é cerca de 50% semelhante ao DNA da banana – portanto, chamar uma banana de “meu irmão” amanhã de manhã não é totalmente injusto.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Na verdade, os ursos polares têm pele preta e seu pelo é transparente; eles parecem brancos por causa da forma como a luz se espalha.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Você realmente não pode chorar no espaço: sem gravidade, as lágrimas não escorrem pelo seu rosto – elas formam uma bolha nos seus olhos.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "O Monte Everest continua a crescer cerca de 4 milímetros por ano – a Terra ainda está mudando.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Os ratos “assobiando” estão essencialmente cantando uns para os outros, mas em frequências muito altas para os humanos ouvirem.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Os tubarões são mais velhos que as árvores – os tubarões existem há cerca de 400 milhões de anos e as árvores há cerca de 350 milhões.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "As bananas são botanicamente bagas, mas os morangos não são – a botânica pode ser estranha.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Uma formiga pode levantar até 50 vezes o seu próprio peso – se você fosse uma formiga, poderia levantar um carro sozinho.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "A Torre Eiffel pode crescer cerca de 15 centímetros no verão devido à expansão térmica.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "O peso total de todos os humanos na Terra é aproximadamente comparável ao peso total de todas as formigas.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "As preguiças conseguem prender a respiração debaixo d'água por mais tempo do que os golfinhos – até cerca de 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Os pombos conseguem perceber a diferença entre as pinturas de Picasso e de Monet – afinal, eles são mais conhecedores de arte do que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "O GPS é gratuito para uso em todo o mundo, mas o governo dos EUA gasta cerca de 2 milhões de dólares por dia para mantê-lo funcionando.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Os ornitorrincos não têm estômago – a comida vai do esôfago direto para o intestino.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare é creditado com o primeiro uso registrado da palavra “arrogância” – mesmo no século 16, ele tinha estilo.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "O coração de uma baleia azul é tão grande que um humano poderia nadar através de suas principais artérias.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "As formigas não têm pulmões – e nunca “dormem” de verdade; eles operam sem parar como pequenos workaholics.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Em Saturno e Júpiter, pode literalmente chover diamantes – aparentemente estamos vivendo no planeta errado.",
    "Honeybees can recognize human faces and remember them individually.":
        "As abelhas podem reconhecer rostos humanos e lembrá-los individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "O “suor” do hipopótamo pode parecer rosa e atua tanto como protetor solar quanto como escudo antibacteriano.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "O cocô do Wombat tem formato de cubo, por isso não rola e pode marcar território com mais eficácia.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Os cajus crescem fora do fruto do caju, pendurados bem na extremidade – um design estranhamente surpreendente.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Os tubarões são mais antigos que os anéis de Saturno – já existiam milhões de anos antes de Saturno receber o seu famoso brilho.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "As borboletas têm gosto com os pés – quando pousam em uma folha, estão basicamente experimentando o jantar.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Um caracol pode dormir por até três anos sem acordar – honestamente, é compreensível.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Os olhos de um avestruz são maiores que o seu cérebro – vivendo na linha tênue entre olhar e pensar.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Os flamingos nascem cinzentos; seu famoso rosa vem dos pigmentos dos camarões e das algas que comem.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Os esquilos ajudam a cultivar milhares de novas árvores todos os anos porque se esquecem de onde enterraram as nozes.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "O primeiro videogame jogado no espaço foi Tetris – jogado em um Game Boy por um cosmonauta em 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Os pica-paus envolvem o cérebro com a língua para ajudar a evitar concussões – usar a língua como capacete é uma solução selvagem.",
  },
  'ro': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Ciorii nu recunosc doar fețele umane; își pot aminti de oameni care i-au tratat urât ani de zile — și chiar să avertizeze alți corbi.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Pisicile își petrec aproximativ 70% din viață dormind, așa că o pisică de 10 ani este trează de doar aproximativ 3 ani.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Mierea nu se strică niciodată; arheologii au găsit borcane de miere vechi de 3.000 de ani în piramidele egiptene care erau încă comestibile.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Vidrele de mare se țin de mână în timp ce dorm, astfel încât să nu se despartă în curent.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Pe Venus, o zi este mai lungă decât un an - se rotește pe axa sa mai lent decât orbitează în jurul Soarelui.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Bricheta a fost inventată înainte de chibritul – uneori, tehnologia „veche” este mai veche decât credem.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Caracatițele au trei inimi și nouă creiere – a uita lucrurile nu este cu adevărat o opțiune.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Vacile au „cei mai buni prieteni” și pot fi foarte stresate – și chiar să plângă – atunci când sunt separate.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Primul virus informatic din lume s-a numit „Creeper” și arăta: „Eu sunt creeperul, prinde-mă dacă poți!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Un nor mediu poate cântări în jur de 500.000 kg, ca o turmă masivă de elefanți care plutesc deasupra capului.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "ADN-ul uman este în aproximativ 50% similar cu ADN-ul bananelor, așa că a numi o banană „fratele meu” mâine dimineață nu este total nedrept.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Urșii polari au de fapt pielea neagră, iar blana lor este transparentă; arată albe din cauza modului în care lumina se împrăștie.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Nu poți să plângi cu adevărat în spațiu: fără gravitație, lacrimile nu îți curg pe față – ele formează o pată în ochi.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Muntele Everest continuă să crească cu aproximativ 4 milimetri în fiecare an – Pământul încă se schimbă.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Șoarecii „fluierători” cântă în esență unul altuia, dar la frecvențe prea mari pentru ca oamenii să le audă.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Rechinii sunt mai bătrâni decât copacii – rechinii există de aproximativ 400 de milioane de ani, copacii de aproximativ 350 de milioane.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Bananele sunt din punct de vedere botanic fructe de pădure, dar căpșunile nu - botanica poate fi ciudată.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "O furnică poate ridica de până la 50 de ori propria greutate — dacă ai fi furnică, ai putea ridica singur o mașină.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Turnul Eiffel poate crește cu aproximativ 15 centimetri vara datorită expansiunii termice.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Greutatea totală a tuturor oamenilor de pe Pământ este aproximativ comparabilă cu greutatea totală a tuturor furnicilor.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Leneșii își pot ține respirația sub apă mai mult decât delfinii – până la aproximativ 40 de minute.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Porumbeii pot face diferența dintre picturile lui Picasso și Monet - se dovedește că sunt mai pricepuți în artă decât credem.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS-ul poate fi folosit gratuit în întreaga lume, dar se pare că guvernul SUA cheltuiește aproximativ 2 milioane de dolari SUA pe zi pentru a-l menține în funcțiune.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Ornitorincii nu au stomac - alimentele merg din esofag direct în intestine.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare este creditat cu prima utilizare înregistrată a cuvântului „swagger” – chiar și în secolul al XVI-lea, el avea stil.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Inima unei balene albastre este atât de mare încât un om ar putea înota prin arterele sale principale.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Furnicile nu au plămâni – și nu „dorm” niciodată cu adevărat; aceștia funcționează fără oprire ca niște mici dependenti de muncă.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Pe Saturn și Jupiter, poate ploua literalmente cu diamante - se pare că trăim pe o planetă greșită.",
    "Honeybees can recognize human faces and remember them individually.":
        "Albinele pot recunoaște fețele umane și le pot aminti individual.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "„Transpirația” hipopotamilor poate arăta roz și acționează atât ca protecție solară, cât și ca un scut antibacterian.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Caca de wombat are formă de cub, așa că nu se rostogolește și poate marca teritoriul mai eficient.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Numele de caju cresc în afara mărului de caju, atârnând la capăt – un design ciudat de surprinzător.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Rechinii sunt mai vechi decât inelele lui Saturn - erau cu aproximativ milioane de ani înainte ca Saturn să obțină faimosul său bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Fluturii gustă cu picioarele - când aterizează pe o frunză, practic iau probe de cină.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un melc poate dormi până la trei ani fără să se trezească - sincer, se poate identifica.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Ochii unui struț sunt mai mari decât creierul său - trăind pe linia fină dintre privire și gândire.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingii se nasc gri; faimosul lor roz provine din pigmenții din creveți și algele pe care le mănâncă.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Veverițele ajută la creșterea a mii de copaci noi în fiecare an, deoarece uită unde au îngropat nucile.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Primul joc video jucat în spațiu a fost Tetris – jucat pe un Game Boy de un cosmonaut în 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Ciocănitorii își înfășoară limba în jurul creierului pentru a evita comoțiile cerebrale – folosirea limbii pe post de cască este o soluție sălbatică.",
  },
  'sk': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Vrany nielenže rozpoznávajú ľudské tváre; dokážu si spomenúť na ľudí, ktorí s nimi celé roky zle zaobchádzali – a dokonca varovať ostatné vrany.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Mačky strávia asi 70 % svojho života spánkom – takže 10-ročná mačka je hore len asi 3 roky.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Med sa nikdy nekazí; archeológovia našli v egyptských pyramídach 3000 rokov staré nádoby s medom, ktoré boli stále jedlé.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Morské vydry sa počas spánku držia za ruky, aby sa v prúde nerozdelili.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Na Venuši je deň dlhší ako rok – otáča sa okolo svojej osi pomalšie ako obieha okolo Slnka.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Zapaľovač bol vynájdený pred zápalkou – niekedy je „stará“ technológia staršia, než si myslíme.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Chobotnice majú tri srdcia a deväť mozgov – zabúdanie vecí nie je v skutočnosti možné.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Kravy majú „najlepších priateľov“ a keď sú oddelené, môžu byť vážne vystresované – a dokonca plakať.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Prvý počítačový vírus na svete sa volal „Creeper“ a zobrazoval: „Ja som creeper, chyť ma, ak to dokážeš!“",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Priemerný oblak môže vážiť okolo 500 000 kg – ako obrovské stádo slonov plávajúce nad hlavou.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Ľudská DNA je asi z 50 % podobná banánovej DNA – takže nazvať banán „môj súrodenec“ zajtra ráno nie je úplne nefér.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Ľadové medvede majú v skutočnosti čiernu kožu a ich srsť je priehľadná; vyzerajú biele kvôli rozptylu svetla.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Vo vesmíre naozaj nemôžete plakať: bez gravitácie vám slzy nestiekajú po tvári – tvoria kvapku v oku.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest každý rok rastie asi o 4 milimetre – Zem sa stále mení.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "„Pískajúce“ myši si v podstate navzájom spievajú, ale pri príliš vysokých frekvenciách na to, aby ich ľudia počuli.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Žraloky sú staršie ako stromy – žraloky sú tu asi 400 miliónov rokov, stromy asi 350 miliónov.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Banány sú botanicky bobule, ale jahody nie – botanika môže byť divná.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Mravec dokáže zdvihnúť až 50-násobok svojej vlastnej hmotnosti – ak by ste boli mravcom, dokázali by ste zdvihnúť aj auto.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Eiffelova veža môže v lete v dôsledku tepelnej rozťažnosti narásť asi o 15 centimetrov.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Celková hmotnosť všetkých ľudí na Zemi je zhruba porovnateľná s celkovou hmotnosťou všetkých mravcov.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Leňochy dokážu zadržať dych pod vodou dlhšie ako delfíny – až asi 40 minút.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Holuby dokážu rozpoznať rozdiel medzi obrazmi Picassa a Moneta – ukázalo sa, že sú umelecky zdatnejší, než si myslíme.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS je možné používať na celom svete zadarmo, ale vláda USA údajne vynakladá približne 2 milióny amerických dolárov denne na jeho udržanie v prevádzke.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platypusy nemajú žalúdky – potrava ide z pažeráka priamo do čriev.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare sa pripisuje prvému zaznamenanému použitiu slova „chvaľovať sa“ – dokonca aj v 16. storočí mal štýl.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Srdce modrej veľryby je také veľké, že človek môže preplávať jej hlavnými tepnami.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Mravce nemajú pľúca – a nikdy skutočne „nespia“; fungujú nonstop ako malí workoholici.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Na Saturn a Jupiter môže doslova pršať diamantmi – zrejme žijeme na nesprávnej planéte.",
    "Honeybees can recognize human faces and remember them individually.":
        "Včely dokážu rozpoznať ľudské tváre a zapamätať si ich individuálne.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Hroší „pot“ môže vyzerať ružovo a pôsobí ako opaľovací krém aj ako antibakteriálny štít.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Hovno vombata má tvar kocky, takže sa neodkotúľa a môže efektívnejšie označiť územie.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Kešu oriešky rastú mimo kešu jablka, visia na samom konci – zvláštne prekvapivý dizajn.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Žraloky sú staršie ako Saturnove prstence – boli asi milióny rokov predtým, ako Saturn dostal svoj slávny bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Motýle chutia nohami – keď pristanú na liste, v podstate ochutnávajú večeru.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Slimák môže spať až tri roky bez prebudenia - úprimne, príbuzný.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Oči pštrosa sú väčšie ako jeho mozog – žijú na tenkej hranici medzi pozeraním a myslením.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Plameniaky sa rodia sivé; ich slávna ružová pochádza z pigmentov v krevetách a riasach, ktoré jedia.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Veveričky pomáhajú pestovať tisíce nových stromov každý rok, pretože zabudnú, kde pochovali orechy.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Prvá videohra hraná vo vesmíre bola Tetris, ktorú v roku 1993 hral kozmonaut na Game Boy.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Ďatle si omotajú jazyk okolo mozgu, aby sa vyhli otrasom mozgu – používanie jazyka ako prilby je divoké riešenie.",
  },
  'sv': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Kråkor känner inte bara igen mänskliga ansikten; de kan minnas människor som behandlat dem illa i flera år – och till och med varna andra kråkor.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Katter tillbringar cirka 70 % av sitt liv i sömn, så en 10-årig katt har bara varit vaken i cirka 3 år.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Honung förstör aldrig; arkeologer har hittat 3 000 år gamla burkar med honung i egyptiska pyramider som fortfarande var ätbara.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Havsuttrar håller hand medan de sover så att de inte glider isär i strömmen.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "På Venus är en dag längre än ett år – den roterar på sin axel långsammare än den kretsar runt solen.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Tändaren uppfanns före tändstickan - ibland är \"gammal\" teknik äldre än vi tror.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Bläckfiskar har tre hjärtan och nio hjärnor - att glömma saker är egentligen inte ett alternativ.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Kor har \"bästa vänner\" och de kan bli allvarligt stressade – och till och med gråta – när de separeras.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Världens första datavirus kallades \"Creeper\", och det visade: \"I'm the creeper, catch me if you can!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Ett genomsnittligt moln kan väga runt 500 000 kg – som en massiv flock elefanter som flyter ovanför.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Mänskligt DNA är ungefär 50 % likt banan-DNA - så att kalla en banan \"mitt syskon\" i morgon bitti är inte helt orättvist.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Isbjörnar har faktiskt svart hud, och deras päls är genomskinlig; de ser vita ut på grund av hur ljuset sprids.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Du kan inte riktigt gråta i rymden: utan gravitation rinner inte tårarna ner för ditt ansikte – de bildar en klump i ögat.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest fortsätter att växa med cirka 4 millimeter varje år - jorden förändras fortfarande.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "\"Vislande\" möss sjunger i huvudsak för varandra, men vid frekvenser som är för höga för människor att höra.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Hajar är äldre än träd – hajar har funnits i cirka 400 miljoner år, träd i cirka 350 miljoner.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Bananer är botaniskt bär, men jordgubbar är det inte - botanik kan vara konstigt.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "En myra kan lyfta upp till 50 gånger sin egen vikt – om du var en myra kunde du lyfta en bil själv.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Eiffeltornet kan växa med cirka 15 centimeter på sommaren på grund av termisk expansion.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Den totala vikten av alla människor på jorden är ungefär jämförbar med den totala vikten av alla myror.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Sengångare kan hålla andan under vattnet längre än delfiner - upp till cirka 40 minuter.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Duvor kan se skillnad på målningar av Picasso och Monet – det visar sig att de är mer konstkunniga än vi tror.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS är gratis att använda över hela världen, men den amerikanska regeringen spenderar enligt uppgift cirka 2 miljoner US-dollar om dagen för att hålla den igång.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platypuses har inga magar - maten går från matstrupen direkt till tarmen.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare är krediterad för den första registrerade användningen av ordet \"swagger\" - även på 1500-talet hade han stil.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "En blåvals hjärta är så stort att en människa kan simma genom dess huvudartärer.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Myror har inga lungor - och de \"sover\" aldrig riktigt; de fungerar nonstop som små arbetsnarkomaner.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "På Saturnus och Jupiter kan det bokstavligen regna diamanter - uppenbarligen lever vi på fel planet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Honungsbin kan känna igen mänskliga ansikten och komma ihåg dem individuellt.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Flodhästens \"svett\" kan se rosa ut och fungerar som både solskyddsmedel och en antibakteriell sköld.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Wombatbajs är kubformad, så den rullar inte iväg och kan markera territorium mer effektivt.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Cashewnötter växer utanför cashewäpplet och hänger i slutet - en märkligt överraskande design.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Hajar är äldre än Saturnus ringar - de var runt miljoner år innan Saturnus fick sitt berömda bling.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Fjärilar smakar med fötterna - när de landar på ett löv, provar de i princip middag.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "En snigel kan sova i upp till tre år utan att vakna - ärligt talat, relaterbar.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "En struts ögon är större än dess hjärna – lever på den fina gränsen mellan att titta och tänka.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingos föds grå; deras berömda rosa kommer från pigment i räkor och alger de äter.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Ekorrar hjälper till att odla tusentals nya träd varje år eftersom de glömmer var de grävde ner nötter.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Det första videospelet som spelades i rymden var Tetris – spelat på en Game Boy av en kosmonaut 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Hackspettar lindar sina tungor runt hjärnan för att undvika hjärnskakning - att använda tungan som hjälm är en vild lösning.",
  },
  'uk': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Ворони не тільки розпізнають людські обличчя; вони можуть пам’ятати людей, які роками з ними погано поводилися, і навіть застерігати інших ворон.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Коти проводять уві сні близько 70% свого життя, тому 10-річний кіт не спить лише близько 3 років.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Мед ніколи не псується; археологи знайшли в єгипетських пірамідах 3000-літні глеки з медом, які все ще були їстівними.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Морські видри тримаються за руки під час сну, щоб не розійтися за течією.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "На Венері доба довша за рік — вона обертається навколо своєї осі повільніше, ніж обертається навколо Сонця.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Запальничка була винайдена раніше, ніж сірник — інколи «старі» технології старіші, ніж ми думаємо.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Восьминоги мають три серця і дев’ять мізків, тому забувати про речі не можна.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "У корів є «найкращі друзі», і вони можуть відчувати серйозний стрес — і навіть плакати — коли їх розлучають.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Перший у світі комп’ютерний вірус називався «Creeper», і він показував: «Я — creeper, спіймай мене, якщо зможеш!»",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Середня хмара може важити близько 500 000 кг, як величезне стадо слонів, що ширяє над головою.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "ДНК людини приблизно на 50% схожа на ДНК банана, тому називати банан «моїм братом» завтра вранці не зовсім несправедливо.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Білі ведмеді насправді мають чорну шкіру, а їхнє хутро прозоре; вони виглядають білими через розсіювання світла.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Ви не можете по-справжньому плакати в космосі: без сили тяжіння сльози не течуть по обличчю — вони утворюють краплю в оці.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Гора Еверест продовжує зростати приблизно на 4 міліметри щороку — Земля все ще змінюється.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "«Свистячі» миші, по суті, співають одна одній, але на частотах, які занадто високі, щоб люди могли почути.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Акули старші за дерева — акули існують близько 400 мільйонів років, дерева — приблизно 350 мільйонів.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Банани є ботанічними ягодами, але полуниця ні — ботаніка може бути дивною.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Мураха може підняти вагу, яка в 50 разів перевищує власну вагу — якби ви були мурахою, ви могли б самостійно підняти автомобіль.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Влітку Ейфелева вежа може вирости приблизно на 15 сантиметрів через теплове розширення.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Загальна вага всіх людей на Землі приблизно порівнянна з загальною вагою всіх мурах.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Лінивці можуть затримувати дихання під водою довше, ніж дельфіни, приблизно на 40 хвилин.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Голуби можуть розрізнити картини Пікассо та Моне — виявилося, що вони більш підковані в мистецтві, ніж ми думаємо.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS можна використовувати безкоштовно в усьому світі, але, як повідомляється, уряд США витрачає близько 2 мільйонів доларів США на день, щоб підтримувати його роботу.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "У качкодзьобів немає шлунка — їжа потрапляє зі стравоходу прямо в кишечник.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Вільяму Шекспіру приписують перше зафіксоване використання слова «swagger» — навіть у 16 ​​столітті він мав стиль.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Серце синього кита настільки велике, що людина могла б пропливти його головними артеріями.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Мурахи не мають легенів, і вони ніколи не «сплять»; вони працюють безперервно, як крихітні трудоголіки.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "На Сатурн і Юпітер може буквально посипатися діамантовий дощ — очевидно, ми живемо не на тій планеті.",
    "Honeybees can recognize human faces and remember them individually.":
        "Медоносні бджоли можуть розпізнавати людські обличчя та запам’ятовувати їх окремо.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "«Піт» бегемота може виглядати рожевим і діє як сонцезахисний і антибактеріальний щит.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Кал вомбата має форму куба, тому не скочується і може більш ефективно позначати територію.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Горіхи кешью ростуть за межами яблука кешью, висять на самому кінці — дивовижний дизайн.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Акули старші за кільця Сатурна — вони були приблизно за мільйони років до того, як Сатурн отримав свій знаменитий блиск.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Метелики куштують ногами — коли вони сідають на листок, вони, по суті, пробують обід.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Равлик може спати до трьох років, не прокидаючись — чесно кажучи, це можна сказати.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Очі страуса більші за його мозок, він живе на тонкій межі між поглядом і мисленням.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Фламінго народжуються сірими; їх знаменитий рожевий колір походить від пігментів у креветках і водоростях, які вони їдять.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Білки допомагають вирощувати тисячі нових дерев щороку, тому що вони забувають, де закопали горіхи.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Першою відеогрою, в яку грали в космосі, був тетріс, у який грав на Game Boy космонавт у 1993 році.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Дятли обертають язиком свій мозок, щоб уникнути струсу мозку — використовувати язик як шолом — це дике рішення.",
  },
};
