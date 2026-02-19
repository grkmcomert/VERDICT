import 'dart:convert';

// Auto-generated did-you-know phrase localizations.
// Source language key is the English phrase used in _analysisDidYouKnowFacts.

bool _looksLikeMojibake(String value) {
  if (value.isEmpty) return false;
  if (value.contains('\uFFFD')) return true;
  if (_mojibakeC1Pattern.hasMatch(value)) return true;
  if (value.contains('\u00E2\u20AC')) return true; // "Ã¢â‚¬â€¦"
  if (_mojibakeMarkerPattern.hasMatch(value)) return true;
  if (value.contains('\u00EF\u00BB\u00BF')) return true; // "Ã¯Â»Â¿"
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

String? _findLocalizedPhrase(Map<String, String>? localizedMap, String enPhrase) {
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
  if (code.startsWith('zh')) return 'zh-hans';
  return code;
}

String? localizeDidYouKnowPhrase(String lang, String enPhrase) {
  final String normalized = _normalizeDidYouKnowLang(lang);
  String? translated =
      _findLocalizedPhrase(_didYouKnowPhraseLocalizations[normalized], enPhrase);

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
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.": "Krähen erkennen nicht nur menschliche Gesichter; Sie können sich an Menschen erinnern, die sie jahrelang schlecht behandelt haben – und sogar andere Krähen warnen.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.": "Katzen verbringen etwa 70 % ihres Lebens schlafend – eine 10-jährige Katze ist also erst seit etwa 3 Jahren wach.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.": "Honig verdirbt nie; Archäologen haben in ägyptischen Pyramiden 3.000 Jahre alte Honiggläser gefunden, die noch essbar waren.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.": "Seeotter halten sich im Schlaf an den Händen, damit sie in der Strömung nicht auseinanderdriften.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.": "Auf der Venus ist ein Tag länger als ein Jahr – sie dreht sich langsamer um ihre Achse, als sie die Sonne umkreist.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.": "Das Feuerzeug wurde vor dem Spiel erfunden – manchmal ist „alte“ Technik älter als wir denken.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.": "Kraken haben drei Herzen und neun Gehirne – Dinge zu vergessen ist eigentlich keine Option.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.": "Kühe haben „beste Freunde“ und sie können ernsthaft gestresst sein – und sogar weinen –, wenn sie getrennt werden.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”": "Der erste Computervirus der Welt hieß „Creeper“ und zeigte: „Ich bin der Creeper, fang mich, wenn du kannst!“",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.": "Eine durchschnittliche Wolke kann etwa 500.000 kg wiegen – wie eine riesige Elefantenherde, die über ihnen schwebt.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.": "Die menschliche DNA ist der Bananen-DNA zu etwa 50 % ähnlich – daher ist es nicht völlig unfair, morgen früh eine Banane „mein Geschwister“ zu nennen.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.": "Eisbären haben tatsächlich schwarze Haut und ihr Fell ist durchsichtig; Sie sehen aufgrund der Lichtstreuung weiß aus.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.": "Im Weltraum kann man nicht wirklich weinen: Ohne die Schwerkraft laufen einem die Tränen nicht übers Gesicht, sondern bilden einen Klumpen im Auge.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.": "Der Mount Everest wächst jedes Jahr um etwa 4 Millimeter – die Erde verändert sich immer noch.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.": "„Pfeifende“ Mäuse singen im Wesentlichen miteinander, allerdings mit einer Frequenz, die zu hoch ist, als dass Menschen sie hören könnten.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.": "Haie sind älter als Bäume – Haie gibt es seit etwa 400 Millionen Jahren, Bäume seit etwa 350 Millionen Jahren.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.": "Bananen sind botanisch gesehen Beeren, Erdbeeren jedoch nicht – die Botanik kann seltsam sein.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.": "Eine Ameise kann bis zum 50-fachen ihres eigenen Gewichts heben – wenn Sie eine Ameise wären, könnten Sie selbst ein Auto heben.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.": "Durch die Wärmeausdehnung kann der Eiffelturm im Sommer um etwa 15 Zentimeter wachsen.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.": "Das Gesamtgewicht aller Menschen auf der Erde ist ungefähr vergleichbar mit dem Gesamtgewicht aller Ameisen.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.": "Faultiere können unter Wasser ihren Atem länger anhalten als Delfine – bis zu etwa 40 Minuten.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.": "Tauben können den Unterschied zwischen Gemälden von Picasso und Monet erkennen – es stellt sich heraus, dass sie kunstbewusster sind, als wir denken.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.": "Die Nutzung von GPS ist weltweit kostenlos, aber die US-Regierung gibt Berichten zufolge täglich rund 2 Millionen US-Dollar aus, um es am Laufen zu halten.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.": "Schnabeltiere haben keinen Magen – die Nahrung gelangt von der Speiseröhre direkt in den Darm.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.": "William Shakespeare wird die erste dokumentierte Verwendung des Wortes „Swagger“ zugeschrieben – er hatte schon im 16. Jahrhundert Stil.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.": "Das Herz eines Blauwals ist so groß, dass ein Mensch durch seine Hauptarterien schwimmen könnte.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.": "Ameisen haben keine Lungen – und sie „schlafen“ nie wirklich; Sie arbeiten ununterbrochen wie kleine Workaholics.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.": "Auf Saturn und Jupiter kann es buchstäblich Diamanten regnen – offenbar leben wir auf dem falschen Planeten.",
    "Honeybees can recognize human faces and remember them individually.": "Honigbienen können menschliche Gesichter erkennen und sich individuell an sie erinnern.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.": "Hippo-„Schweiß“ kann rosa aussehen und wirkt sowohl als Sonnenschutz als auch als antibakterieller Schutzschild.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.": "Wombat-Kot ist würfelförmig, sodass er nicht wegrollt und das Revier effektiver markieren kann.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.": "Cashewnüsse wachsen außerhalb des Cashewapfels und hängen ganz am Ende – ein seltsam überraschendes Design.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.": "Haie sind älter als die Saturnringe – sie existierten etwa Millionen Jahre, bevor Saturn seinen berühmten Schmuck bekam.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.": "Schmetterlinge schmecken mit ihren Füßen – wenn sie auf einem Blatt landen, probieren sie im Grunde ein Abendessen.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.": "Eine Schnecke kann bis zu drei Jahre lang schlafen, ohne aufzuwachen – ehrlich gesagt, nachvollziehbar.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.": "Die Augen eines Straußes sind größer als sein Gehirn – sie bewegen sich auf dem schmalen Grat zwischen Sehen und Denken.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.": "Flamingos werden grau geboren; Ihr berühmtes Rosa kommt von Pigmenten in Garnelen und Algen, die sie fressen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.": "Eichhörnchen helfen jedes Jahr dabei, Tausende neuer Bäume wachsen zu lassen, weil sie vergessen, wo sie Nüsse vergraben haben.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.": "Das erste Videospiel, das im Weltraum gespielt wurde, war Tetris – 1993 von einem Kosmonauten auf einem Game Boy gespielt.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.": "Spechte wickeln ihre Zunge um ihr Gehirn, um Gehirnerschütterungen zu vermeiden – die Zunge als Helm zu verwenden, ist eine wilde Lösung.",
  },
  'ko': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.": "까마귀는 사람의 얼굴만 인식하는 것이 아닙니다. 그들은 수년 동안 자신을 나쁘게 대했던 사람들을 기억할 수 있고 심지어 다른 까마귀들에게 경고할 수도 있습니다.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.": "고양이는 일생의 약 70%를 잠으로 보냅니다. 따라서 10살 된 고양이는 깨어 있는 기간이 약 3년에 불과합니다.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.": "꿀은 결코 상하지 않습니다. 고고학자들은 이집트 피라미드에서 여전히 먹을 수 있는 3,000년 된 꿀 항아리를 발견했습니다.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.": "해달은 잠을 잘 때 손을 잡고 물살에 흩어지지 않도록 합니다.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.": "금성에서는 하루가 1년보다 길기 때문에 태양을 공전하는 것보다 축을 중심으로 더 천천히 회전합니다.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.": "라이터는 경기 전에 발명되었습니다. 때로는 \"오래된\" 기술이 우리가 생각하는 것보다 오래되었습니다.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.": "문어는 3개의 심장과 9개의 뇌를 가지고 있습니다. 잊어버리는 것은 실제로 선택 사항이 아닙니다.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.": "소에게는 “가장 친한 친구”가 있으며, 떨어져 있을 때 심각한 스트레스를 받을 수 있으며 심지어 울 수도 있습니다.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”": "세계 최초의 컴퓨터 바이러스는 \"크리퍼(Creeper)\"라고 불리며 \"내가 크리퍼입니다. 잡을 수 있으면 잡아주세요!\"라는 문구가 표시되었습니다.",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.": "평균 구름의 무게는 약 500,000kg에 달합니다. 마치 머리 위로 떠다니는 거대한 코끼리 떼와 같습니다.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.": "인간 DNA는 바나나 DNA와 약 50% 유사합니다. 따라서 내일 아침 바나나를 \"내 형제\"라고 부르는 것은 완전히 불공평한 것은 아닙니다.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.": "북극곰은 실제로 검은 피부를 가지고 있고 털은 투명합니다. 빛이 산란되는 방식 때문에 흰색으로 보입니다.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.": "우주에서는 실제로 울 수 없습니다. 중력이 없으면 눈물이 얼굴로 흘러내리지 않고 눈에 방울을 형성합니다.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.": "에베레스트 산은 매년 약 4mm씩 계속해서 성장하고 있습니다. 지구는 여전히 변화하고 있습니다.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.": "\"휘파람을 부는\" 쥐는 본질적으로 서로에게 노래를 부르지만, 그 주파수는 인간이 들을 수 없을 정도로 너무 높습니다.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.": "상어는 나무보다 나이가 많습니다. 상어는 약 4억 년, 나무는 약 3억 5천만 년 동안 존재했습니다.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.": "바나나는 식물학적으로 열매이지만 딸기는 그렇지 않습니다. 식물학은 이상할 수 있습니다.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.": "개미는 자신의 몸무게의 50배까지 들어 올릴 수 있습니다. 개미라면 혼자서 차도 들어 올릴 수 있습니다.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.": "에펠탑은 여름에 열팽창으로 인해 약 15cm 정도 자랄 수 있습니다.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.": "지구상의 모든 인간의 총 무게는 모든 개미의 총 무게와 대략 비슷합니다.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.": "나무늘보는 물 속에서 돌고래보다 더 오랫동안(최대 약 40분) 숨을 참을 수 있습니다.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.": "비둘기는 피카소와 모네의 그림을 구별할 수 있습니다. 알고 보니 그 그림은 우리가 생각하는 것보다 예술에 더 정통한 것으로 나타났습니다.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.": "GPS는 전 세계적으로 무료로 사용할 수 있지만, 미국 정부는 이를 유지하기 위해 하루 약 200만 달러를 지출하는 것으로 알려졌습니다.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.": "오리너구리에는 위가 없습니다. 음식은 식도에서 곧바로 장으로 이동합니다.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.": "윌리엄 셰익스피어는 \"swagger\"라는 단어를 처음으로 사용한 것으로 기록되어 있습니다. 16세기에도 그에게는 스타일이 있었습니다.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.": "대왕고래의 심장은 인간이 주요 동맥을 헤엄쳐 지나갈 수 있을 만큼 크다.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.": "개미는 폐가 없으며 결코 진정으로 \"잠\"을 자지 않습니다. 그들은 작은 일벌레처럼 쉬지 않고 일합니다.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.": "토성과 목성에서는 문자 그대로 다이아몬드 비가 내릴 수 있습니다. 분명히 우리는 잘못된 행성에 살고 있습니다.",
    "Honeybees can recognize human faces and remember them individually.": "꿀벌은 사람의 얼굴을 인식하고 개별적으로 기억할 수 있습니다.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.": "하마의 “땀”은 분홍색으로 보일 수 있으며 자외선 차단제와 항균막 역할을 합니다.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.": "웜뱃의 똥은 큐브 형태이기 때문에 굴러가지 않고 더욱 효과적으로 영역을 표시할 수 있습니다.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.": "캐슈넛은 캐슈사과 외부에서 자라서 맨 끝에 매달려 있습니다. 이상하게도 놀라운 디자인입니다.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.": "상어는 토성의 고리보다 나이가 많습니다. 토성이 그 유명한 블링블링을 갖기 약 수백만 년 전입니다.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.": "나비는 발로 맛을 봅니다. 나뭇잎에 앉으면 기본적으로 저녁 식사를 맛보게 됩니다.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.": "달팽이는 깨어나지 않고 최대 3년 동안 잠을 잘 수 있습니다. 솔직히 말해서 공감할 수 있는 일입니다.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.": "타조의 눈은 뇌보다 큽니다. 보는 것과 생각하는 것 사이의 미세한 경계에 살고 있습니다.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.": "플라밍고는 회색으로 태어났습니다. 그들의 유명한 분홍색은 그들이 먹는 새우와 해조류의 색소에서 나옵니다.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.": "다람쥐는 견과류를 어디에 묻었는지 잊어버리기 때문에 매년 수천 그루의 새로운 나무가 자라는 데 도움을 줍니다.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.": "우주에서 플레이된 최초의 비디오 게임은 1993년 우주비행사가 게임보이로 플레이한 테트리스였습니다.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.": "딱따구리는 뇌진탕을 피하기 위해 혀로 뇌를 감쌉니다. 혀를 헬멧으로 사용하는 것은 획기적인 해결책입니다.",
  },
  'ja': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.": "カラスは人間の顔を認識するだけではありません。彼らは何年にもわたって自分たちにひどい仕打ちをした人々を覚えていて、他のカラスに警告することさえできます。",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.": "猫は一生の約 70% を眠って過ごします。つまり、10 歳の猫が起きているのはわずか 3 年ほどです。",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.": "蜂蜜は腐ることはありません。考古学者らは、エジプトのピラミッドでまだ食べられる3,000年前の蜂蜜の瓶を発見した。",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.": "ラッコは流れの中で離れ離れにならないように手をつないで寝ます。",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.": "金星の 1 日は 1 年よりも長く、金星は太陽の周りを回るよりもゆっくりと自転します。",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.": "ライターは試合前に発明されました。「古い」技術は私たちが思っているよりも古い場合があります。",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.": "タコには 3 つの心臓と 9 つの脳があり、物を忘れるという選択肢は実際にはありません。",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.": "牛には「親友」がおり、離れると深刻なストレスを感じ、泣くこともあります。",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”": "世界初のコンピューター ウイルスは「クリーパー」と呼ばれ、「私はクリーパーです、できれば捕まえてください!」と表示されました。",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.": "平均的な雲の重さは約 500,000 kg あり、頭上に浮かぶ巨大な象の群れに似ています。",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.": "人間の DNA はバナナの DNA と約 50% 似ているため、明日の朝バナナを「私の兄弟」と呼ぶのは完全に不公平というわけではありません。",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.": "ホッキョクグマの肌は実際には黒く、毛皮は透明です。光が散乱するため白く見えます。",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.": "宇宙では本当に泣くことはできません。重力がなければ、涙は顔に流れ落ちず、目に塊ができます。",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.": "エベレストは毎年約 4 ミリメートルずつ成長し続けており、地球は依然として変化しています。",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.": "「口笛を吹く」ネズミは基本的に互いに歌を歌っていますが、その周波数は人間には聞き取れないほど高すぎます。",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.": "サメは木よりも古く、サメは約 4 億年前から存在し、木は約 3 億 5,000 万年前から存在しています。",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.": "バナナは植物学的には果実ですが、イチゴはそうではありません。植物学は奇妙な場合があります。",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.": "アリは自分の体重の 50 倍もの重量を持ち上げることができます。あなたがアリだったら、一人で車を持ち上げることができるでしょう。",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.": "エッフェル塔は夏には熱膨張により約15センチ伸びることがあります。",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.": "地球上の全人類の総重量は、すべてのアリの総重量にほぼ匹敵します。",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.": "ナマケモノはイルカよりも長く水中で息を止めることができます（最長約 40 分）。",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.": "ハトはピカソとモネの絵の違いを見分けることができ、ハトは私たちが思っているよりも芸術に精通していることが判明しました。",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.": "GPS は世界中で無料で使用できますが、米国政府はそれを維持するために 1 日あたり約 200 万ドルを費やしていると伝えられています。",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.": "カモノハシには胃がありません。食べ物は食道から直接腸に送られます。",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.": "ウィリアム・シェイクスピアは、「闊歩する」という言葉を初めて記録に基づいて使用したとされており、16 世紀であっても、彼にはスタイルがありました。",
    "A blue whale’s heart is so large that a human could swim through its main arteries.": "シロナガスクジラの心臓は、人間がその大動脈を泳いで通れるほど大きい。",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.": "アリには肺がありません。そして、アリは本当に「眠る」ことはありません。彼らは小さなワーカホリックのようにノンストップで活動します。",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.": "土星と木星では、文字通りダイヤモンドの雨が降ることがあります。どうやら、私たちは間違った惑星に住んでいるようです。",
    "Honeybees can recognize human faces and remember them individually.": "ミツバチは人間の顔を認識し、個別に記憶することができます。",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.": "カバの「汗」はピンク色に見え、日焼け止めと抗菌シールドの両方の役割を果たします。",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.": "ウォンバットの糞は立方体の形をしているため、転がることがなく、より効果的に縄張りをマークすることができます。",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.": "カシューナッツはカシューアップルの外側に生え、最後にぶら下がっています。奇妙に驚くべきデザインです。",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.": "サメは土星の輪よりも古く、土星が有名な輝きを持つようになる数百万年前に存在しました。",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.": "蝶は足で味を感じます。葉に止まるとき、彼らは基本的に夕食を試食しているのです。",
    "A snail can sleep for up to three years without waking up—honestly, relatable.": "カタツムリは最長 3 年間目覚めずに眠ることができます。正直言って、とても共感できます。",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.": "ダチョウの目は脳よりも大きく、見ることと考えることの紙一重で生きています。",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.": "フラミンゴは生まれつき灰色です。彼らの有名なピンク色は、彼らが食べるエビや藻類の色素に由来しています。",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.": "リスは木の実を埋めた場所を忘れてしまうため、毎年何千本もの新しい木を育てるのに役立っています。",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.": "宇宙でプレイされた最初のビデオ ゲームはテトリスで、1993 年に宇宙飛行士がゲームボーイでプレイしました。",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.": "キツツキは脳震盪を避けるために舌を脳に巻き付けます。舌をヘルメットとして使うのは、思いがけない解決策です。",
  },
  'ru': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.": "Вороны не просто распознают человеческие лица; они могут годами помнить людей, которые плохо с ними обращались, и даже предупреждать других ворон.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.": "Кошки проводят во сне около 70% своей жизни, то есть 10-летний кот бодрствует всего около 3 лет.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.": "Мед никогда не портится; археологи нашли в египетских пирамидах 3000-летние банки с медом, которые до сих пор были съедобны.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.": "Морские выдры держатся за руки во время сна, чтобы их не разнесло течением.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.": "На Венере день длиннее года — она вращается вокруг своей оси медленнее, чем вращается вокруг Солнца.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.": "Зажигалка была изобретена еще до спички — иногда «старая» технология старше, чем мы думаем.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.": "У осьминогов три сердца и девять мозгов, поэтому забывать что-то — не вариант.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.": "У коров есть «лучшие друзья», и они могут испытывать серьезный стресс и даже плакать, когда их разлучают.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”": "Первый в мире компьютерный вирус назывался «Крипер», и на нем было написано: «Я крипер, поймай меня, если сможешь!»",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.": "Среднее облако может весить около 500 000 кг — как огромное стадо слонов, плывущее над головой.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.": "ДНК человека примерно на 50% похожа на ДНК банана, поэтому завтра утром называть банан «моим братом или сестрой» не совсем несправедливо.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.": "У белых медведей на самом деле кожа черная, а мех прозрачный; они выглядят белыми из-за рассеивания света.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.": "В космосе плакать по-настоящему нельзя: без гравитации слезы не текут по лицу — они образуют комок в глазу.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.": "Гора Эверест продолжает расти примерно на 4 миллиметра каждый год — Земля все еще меняется.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.": "«Свистящие» мыши по сути поют друг другу, но на частотах, слишком высоких, чтобы люди могли их услышать.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.": "Акулы старше деревьев: акулы существуют около 400 миллионов лет, деревья — около 350 миллионов.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.": "Бананы с ботанической точки зрения являются ягодами, а клубника — нет. Ботаника может быть странной.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.": "Муравей может поднять вес, в 50 раз превышающий его собственный. Если бы вы были муравьем, вы могли бы поднять машину самостоятельно.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.": "Эйфелева башня летом может вырасти примерно на 15 сантиметров из-за теплового расширения.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.": "Общий вес всех людей на Земле примерно сопоставим с общим весом всех муравьев.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.": "Ленивцы могут задерживать дыхание под водой дольше, чем дельфины — примерно до 40 минут.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.": "Голуби могут отличить картины Пикассо от Моне — оказывается, они более подкованы в искусстве, чем мы думаем.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.": "GPS можно использовать бесплатно во всем мире, но, как сообщается, правительство США тратит около 2 миллионов долларов в день на его поддержание.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.": "Желудков у утконосов нет — пища попадает из пищевода прямо в кишечник.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.": "Уильяму Шекспиру приписывают первое зарегистрированное использование слова «чванство» — даже в 16 веке у него был стиль.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.": "Сердце синего кита настолько велико, что человек может проплыть по его основным артериям.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.": "У муравьев нет легких, и они никогда по-настоящему не «спят»; они работают без перерыва, как крошечные трудоголики.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.": "На Сатурне и Юпитере может идти буквально алмазный дождь — видимо, мы живем не на той планете.",
    "Honeybees can recognize human faces and remember them individually.": "Медоносные пчелы могут распознавать человеческие лица и запоминать их по отдельности.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.": "«Пот» бегемота может выглядеть розовым и действует как солнцезащитный крем, так и как антибактериальный щит.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.": "Какашки вомбата имеют форму куба, поэтому они не укатываются и позволяют более эффективно метить территорию.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.": "Кешью растут снаружи яблока кешью, свисая на самом конце — удивительно удивительный дизайн.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.": "Акулы старше колец Сатурна — они существовали примерно за миллионы лет до того, как Сатурн приобрел свой знаменитый блеск.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.": "Бабочки пробуют вкус ногами: когда они приземляются на лист, они, по сути, пробуют ужин.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.": "Улитка может спать до трех лет, не просыпаясь — честно говоря, это интересно.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.": "Глаза страуса больше, чем его мозг, и он живет на тонкой грани между взглядом и мышлением.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.": "Фламинго рождаются серыми; их знаменитый розовый цвет обусловлен пигментами креветок и водорослей, которые они едят.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.": "Белки помогают вырастить тысячи новых деревьев каждый год, потому что они забывают, где закопали орехи.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.": "Первой видеоигрой, в которую играли в космосе, был тетрис, в который космонавт сыграл на Game Boy в 1993 году.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.": "Дятлы обхватывают мозг языком, чтобы избежать сотрясения мозга. Использование языка в качестве шлема — дикое решение.",
  },
  'pt': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.": "Os corvos não reconhecem apenas rostos humanos; eles podem se lembrar de pessoas que os trataram mal durante anos – e até mesmo alertar outros corvos.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.": "Os gatos passam cerca de 70% de suas vidas dormindo – então um gato de 10 anos fica acordado há apenas cerca de 3 anos.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.": "O mel nunca estraga; arqueólogos encontraram potes de mel de 3.000 anos em pirâmides egípcias que ainda eram comestíveis.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.": "As lontras marinhas dão as mãos enquanto dormem para não se separarem na correnteza.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.": "Em Vênus, um dia é mais longo que um ano – ele gira em torno de seu eixo mais lentamente do que orbita o Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.": "O isqueiro foi inventado antes do jogo – às vezes a tecnologia “antiga” é mais antiga do que pensamos.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.": "Os polvos têm três corações e nove cérebros – esquecer as coisas não é realmente uma opção.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.": "As vacas têm “melhores amigas” e podem ficar seriamente estressadas – e até chorar – quando separadas.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”": "O primeiro vírus de computador do mundo chamava-se “Creeper” e exibia: “Eu sou o rastejador, pegue-me se puder!”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.": "Uma nuvem média pode pesar cerca de 500.000 kg – como uma enorme manada de elefantes flutuando no alto.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.": "O DNA humano é cerca de 50% semelhante ao DNA da banana – portanto, chamar uma banana de “meu irmão” amanhã de manhã não é totalmente injusto.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.": "Na verdade, os ursos polares têm pele preta e seu pelo é transparente; eles parecem brancos por causa da forma como a luz se espalha.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.": "Você realmente não pode chorar no espaço: sem gravidade, as lágrimas não escorrem pelo seu rosto – elas formam uma bolha nos seus olhos.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.": "O Monte Everest continua a crescer cerca de 4 milímetros por ano – a Terra ainda está mudando.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.": "Os ratos “assobiando” estão essencialmente cantando uns para os outros, mas em frequências muito altas para os humanos ouvirem.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.": "Os tubarões são mais velhos que as árvores – os tubarões existem há cerca de 400 milhões de anos e as árvores há cerca de 350 milhões.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.": "As bananas são botanicamente bagas, mas os morangos não são – a botânica pode ser estranha.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.": "Uma formiga pode levantar até 50 vezes o seu próprio peso – se você fosse uma formiga, poderia levantar um carro sozinho.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.": "A Torre Eiffel pode crescer cerca de 15 centímetros no verão devido à expansão térmica.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.": "O peso total de todos os humanos na Terra é aproximadamente comparável ao peso total de todas as formigas.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.": "As preguiças conseguem prender a respiração debaixo d'água por mais tempo do que os golfinhos – até cerca de 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.": "Os pombos conseguem perceber a diferença entre as pinturas de Picasso e de Monet – afinal, eles são mais conhecedores de arte do que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.": "O GPS é gratuito para uso em todo o mundo, mas o governo dos EUA gasta cerca de US\$ 2 milhões por dia para mantê-lo funcionando.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.": "Os ornitorrincos não têm estômago – a comida vai do esôfago direto para o intestino.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.": "William Shakespeare é creditado com o primeiro uso registrado da palavra “arrogância” – mesmo no século 16, ele tinha estilo.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.": "O coração de uma baleia azul é tão grande que um humano poderia nadar através de suas principais artérias.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.": "As formigas não têm pulmões – e nunca “dormem” de verdade; eles operam sem parar como pequenos workaholics.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.": "Em Saturno e Júpiter, pode literalmente chover diamantes – aparentemente estamos vivendo no planeta errado.",
    "Honeybees can recognize human faces and remember them individually.": "As abelhas podem reconhecer rostos humanos e lembrá-los individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.": "O “suor” do hipopótamo pode parecer rosa e atua tanto como protetor solar quanto como escudo antibacteriano.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.": "O cocô do Wombat tem formato de cubo, por isso não rola e pode marcar território com mais eficácia.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.": "Os cajus crescem fora do fruto do caju, pendurados bem na extremidade – um design estranhamente surpreendente.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.": "Os tubarões são mais antigos que os anéis de Saturno – já existiam milhões de anos antes de Saturno receber o seu famoso brilho.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.": "As borboletas têm gosto com os pés – quando pousam em uma folha, estão basicamente experimentando o jantar.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.": "Um caracol pode dormir por até três anos sem acordar – honestamente, é compreensível.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.": "Os olhos de um avestruz são maiores que o seu cérebro – vivendo na linha tênue entre olhar e pensar.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.": "Os flamingos nascem cinzentos; seu famoso rosa vem dos pigmentos dos camarões e das algas que comem.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.": "Os esquilos ajudam a cultivar milhares de novas árvores todos os anos porque se esquecem de onde enterraram as nozes.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.": "O primeiro videogame jogado no espaço foi Tetris – jogado em um Game Boy por um cosmonauta em 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.": "Os pica-paus envolvem o cérebro com a língua para ajudar a evitar concussões – usar a língua como capacete é uma solução selvagem.",
  },
  'ar': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.": "لا تتعرف الغربان على الوجوه البشرية فحسب؛ يمكنهم أن يتذكروا الأشخاص الذين عاملوهم بشكل سيئ لسنوات، بل ويمكنهم أيضًا تحذير الغربان الأخرى.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.": "تقضي القطط حوالي 70% من حياتها نائمة، أي أن القطة البالغة من العمر 10 سنوات تظل مستيقظة لمدة 3 سنوات فقط.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.": "العسل لا يفسد أبدًا؛ اكتشف علماء الآثار جرارًا من العسل عمرها 3000 عام في الأهرامات المصرية والتي كانت لا تزال صالحة للأكل.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.": "ثعالب البحر تمسك أيديها أثناء نومها حتى لا تنجرف بعيدًا في التيار.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.": "على كوكب الزهرة، يكون اليوم أطول من السنة، فهو يدور حول محوره بشكل أبطأ من دورانه حول الشمس.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.": "تم اختراع الولاعة قبل المباراة، وفي بعض الأحيان تكون التكنولوجيا \"القديمة\" أقدم مما نعتقد.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.": "يمتلك الأخطبوط ثلاثة قلوب وتسعة أدمغة، ونسيان الأشياء ليس خيارًا في الحقيقة.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.": "الأبقار لديها \"أفضل الأصدقاء\"، ويمكن أن تتعرض لضغوط شديدة - وحتى البكاء - عند الانفصال.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”": "أول فيروس كمبيوتر في العالم كان يسمى \"الزاحف\"، وكان يظهر: \"أنا الزاحف، أمسك بي إذا استطعت!\"",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.": "يمكن أن تزن السحابة المتوسطة حوالي 500000 كجم، مثل قطيع ضخم من الأفيال التي تطفو فوقها.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.": "يتشابه الحمض النووي البشري مع الحمض النووي للموز بنسبة 50% تقريبًا، لذا فإن تسمية الموز بـ \"أخي\" صباح الغد ليس ظلمًا تمامًا.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.": "في الواقع، تتمتع الدببة القطبية بجلد أسود، وفرائها شفاف؛ تبدو بيضاء بسبب كيفية تشتت الضوء.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.": "لا يمكنك البكاء حقًا في الفضاء: فبدون الجاذبية، لن تسيل الدموع على وجهك، بل ستشكل نقطة في عينك.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.": "يستمر جبل إيفرست في النمو بنحو 4 ملليمترات كل عام، ولا تزال الأرض تتغير.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.": "تقوم الفئران \"بالتصفير\" بشكل أساسي بالغناء لبعضها البعض، ولكن بترددات عالية جدًا بحيث لا يستطيع البشر سماعها.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.": "أسماك القرش أقدم من الأشجار، إذ كانت أسماك القرش موجودة منذ حوالي 400 مليون سنة، والأشجار منذ حوالي 350 مليون سنة.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.": "الموز عبارة عن توت من الناحية النباتية، لكن الفراولة ليست كذلك، فقد يكون علم النبات غريبًا.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.": "يمكن للنملة أن ترفع ما يصل إلى 50 ضعف وزنها، وإذا كنت نملة، فيمكنك رفع سيارة بنفسك.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.": "يمكن أن ينمو برج إيفل بحوالي 15 سم في الصيف بسبب التمدد الحراري.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.": "الوزن الإجمالي لجميع البشر على الأرض يمكن مقارنته تقريبًا بالوزن الإجمالي لجميع النمل.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.": "يمكن لحيوانات الكسلان حبس أنفاسها تحت الماء لفترة أطول من الدلافين، تصل إلى حوالي 40 دقيقة.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.": "يستطيع الحمام التمييز بين لوحات بيكاسو ومونيه، وقد تبين أنهم أكثر ذكاءً في الفن مما نعتقد.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.": "إن استخدام نظام تحديد المواقع العالمي (GPS) مجاني في جميع أنحاء العالم، لكن يقال إن حكومة الولايات المتحدة تنفق حوالي 2 مليون دولار يوميًا لاستمرار تشغيله.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.": "خلد الماء ليس لديه معدة، فالطعام ينتقل من المريء مباشرة إلى الأمعاء.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.": "يعود الفضل إلى ويليام شكسبير في أول استخدام مسجل لكلمة \"اختيال\" - حتى في القرن السادس عشر، كان لديه أسلوب.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.": "قلب الحوت الأزرق كبير جدًا لدرجة أن الإنسان يستطيع السباحة عبر شرايينه الرئيسية.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.": "لا يمتلك النمل رئتين، ولا \"ينام\" أبدًا؛ إنهم يعملون دون توقف مثل مدمنين العمل الصغار.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.": "في زحل والمشتري، يمكن أن تمطر الماس فعليًا، ويبدو أننا نعيش على الكوكب الخطأ.",
    "Honeybees can recognize human faces and remember them individually.": "يمكن لنحل العسل التعرف على الوجوه البشرية وتذكرها بشكل فردي.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.": "يمكن أن يبدو \"عرق\" فرس النهر ورديًا ويعمل بمثابة واقي من الشمس ودرع مضاد للبكتيريا.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.": "يكون براز الومبت على شكل مكعب، لذا فهو لا يتدحرج ويمكنه تحديد المنطقة بشكل أكثر فعالية.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.": "ينمو الكاجو خارج ثمرة الكاجو، ويتدلى في نهايتها، وهو تصميم مثير للدهشة بشكل غريب.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.": "تعد أسماك القرش أقدم من حلقات زحل، فقد كانت موجودة قبل ملايين السنين من حصول زحل على بريقه الشهير.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.": "تتذوق الفراشات بأقدامها، فعندما تهبط على ورقة شجر، فإنها في الأساس تتناول العشاء.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.": "يمكن للحلزون أن ينام لمدة تصل إلى ثلاث سنوات دون أن يستيقظ - بصراحة، يمكن التواصل معه.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.": "عيون النعامة أكبر من دماغها، وتعيش على الخط الرفيع بين النظر والتفكير.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.": "تولد طيور النحام باللون الرمادي؛ يأتي لونهم الوردي الشهير من الأصباغ الموجودة في الجمبري والطحالب التي يأكلونها.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.": "تساعد السناجب في زراعة آلاف الأشجار الجديدة كل عام لأنها تنسى المكان الذي دفنت فيه الجوز.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.": "أول لعبة فيديو تم لعبها في الفضاء كانت Tetris، والتي لعبها رائد فضاء على جهاز Game Boy في عام 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.": "يلف نقار الخشب ألسنتهم حول أدمغتهم للمساعدة في تجنب الارتجاجات، ويعتبر استخدام لسانك كخوذة حلاً جذريًا.",
  },
  'es': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "Los cuervos no solo reconocen rostros humanos; pueden recordar durante aÃ±os a quienes los trataron mal e incluso advertir a otros cuervos.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "Los gatos pasan cerca del 70% de su vida durmiendo. AsÃ­ que un gato de 10 aÃ±os, en realidad, solo ha estado despierto unos 3 aÃ±os.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "La miel nunca caduca. Los arqueÃ³logos han hallado tarros con 3.000 aÃ±os de antigÃ¼edad en pirÃ¡mides egipcias que aÃºn eran comestibles.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "Las nutrias marinas se toman de la mano al dormir para que la corriente no las separe.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "En Venus, un dÃ­a dura mÃ¡s que un aÃ±o: tarda mÃ¡s en girar sobre su propio eje que en dar la vuelta al Sol.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "El encendedor se inventÃ³ antes que la cerilla. A veces, la tecnologÃ­a 'antigua' es mÃ¡s vieja de lo que creemos.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "Los pulpos tienen tres corazones y nueve cerebros; olvidar cosas no es realmente una opciÃ³n para ellos.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "Las vacas tienen 'mejores amigas' y pueden sufrir mucho estrÃ©s (e incluso llorar) si las separan.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "El primer virus informÃ¡tico se llamÃ³ 'Creeper' y mostraba el mensaje: 'Â¡Soy el Creeper, atrÃ¡pame si puedes!'.",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Una nube promedio puede pesar unos 500.000 kg; imagina una manada gigante de elefantes flotando sobre tu cabeza.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "El ADN humano es un 50% idÃ©ntico al de una banana. AsÃ­ que llamar 'hermano' a un plÃ¡tano no es del todo descabellado.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Los osos polares tienen la piel negra y su pelaje es transparente; se ven blancos por cÃ³mo reflejan la luz.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "No se puede llorar en el espacio: sin gravedad, las lÃ¡grimas no caen, se quedan acumuladas como una burbuja en el ojo.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "El Monte Everest crece unos 4 milÃ­metros al aÃ±o; la Tierra sigue cambiando.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Los ratones que 'silban' en realidad se estÃ¡n cantando, pero a una frecuencia tan alta que los humanos no podemos oÃ­rla.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "Los tiburones son mÃ¡s antiguos que los Ã¡rboles: ellos llevan aquÃ­ 400 millones de aÃ±os, los Ã¡rboles solo 350 millones.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "BotÃ¡nicamente, las bananas son bayas, pero las fresas no. La naturaleza es extraÃ±a.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Una hormiga levanta 50 veces su peso. Si fueras una hormiga, podrÃ­as levantar un coche tÃº solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel puede crecer unos 15 cm en verano debido a la expansiÃ³n tÃ©rmica del metal.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "El peso total de todos los humanos en la Tierra es casi igual al peso total de todas las hormigas del mundo.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "Los perezosos aguantan la respiraciÃ³n bajo el agua mÃ¡s tiempo que los delfines: hasta 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "Las palomas distinguen entre pinturas de Picasso y Monet. Resulta que saben mÃ¡s de arte de lo que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "El GPS es gratis, pero el gobierno de EE. UU. gasta unos 2 millones de dÃ³lares al dÃ­a para mantenerlo funcionando.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "Los ornitorrincos no tienen estÃ³mago; la comida pasa directamente del esÃ³fago a los intestinos.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "A Shakespeare se le atribuye el primer uso de la palabra 'swagger' (estilo/chulerÃ­a). Incluso en el siglo XVI, tenÃ­a clase.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "El corazÃ³n de una ballena azul es tan grande que un humano podrÃ­a nadar por sus arterias principales.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "Las hormigas no tienen pulmones y nunca 'duermen' realmente; trabajan sin parar.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "En Saturno y JÃºpiter llueven diamantes literalmente. Al parecer, vivimos en el planeta equivocado.",
    "Honeybees can recognize human faces and remember them individually.":
        "Las abejas pueden reconocer rostros humanos y recordarlos individualmente.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "El 'sudor' de los hipopÃ³tamos es rosado y funciona como protector solar y antibacteriano.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "La caca del wombat es cÃºbica para que no ruede y marque mejor su territorio.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "El anacardo crece por fuera del fruto, colgando al final. Un diseÃ±o de la naturaleza bastante curioso.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "Los tiburones son mÃ¡s viejos que los anillos de Saturno. Ya estaban aquÃ­ millones de aÃ±os antes de que Saturno tuviera sus anillos.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "Las mariposas saborean con los pies. Cuando se posan en una hoja, estÃ¡n probando la cena.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Un caracol puede dormir tres aÃ±os seguidos. Sinceramente, quÃ© envidia.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "Los ojos del avestruz son mÃ¡s grandes que su cerebro.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Los flamencos nacen grises; su color rosa viene de los pigmentos de las algas y camarones que comen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Las ardillas plantan miles de Ã¡rboles al aÃ±o simplemente porque olvidan dÃ³nde enterraron sus nueces.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "El primer videojuego jugado en el espacio fue Tetris, en una Game Boy, por un cosmonauta en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "Los pÃ¡jaros carpinteros envuelven su lengua alrededor de su cerebro para protegerlo de los golpes. Usar la lengua como casco es una locura.",
  },
  'es-mx': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "Los cuervos no solo reconocen rostros humanos; pueden recordar durante aÃ±os a quienes los trataron mal e incluso advertir a otros cuervos.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "Los gatos pasan cerca del 70% de su vida durmiendo. AsÃ­ que un gato de 10 aÃ±os, en realidad, solo ha estado despierto unos 3 aÃ±os.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "La miel nunca caduca. Los arqueÃ³logos han hallado tarros con 3.000 aÃ±os de antigÃ¼edad en pirÃ¡mides egipcias que aÃºn eran comestibles.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "Las nutrias marinas se toman de la mano al dormir para que la corriente no las separe.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "En Venus, un dÃ­a dura mÃ¡s que un aÃ±o: tarda mÃ¡s en girar sobre su propio eje que en dar la vuelta al Sol.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "El encendedor se inventÃ³ antes que los cerillos. A veces, la tecnologÃ­a 'vieja' es mÃ¡s antigua de lo que pensamos.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "Los pulpos tienen tres corazones y nueve cerebros; olvidar cosas no es realmente una opciÃ³n para ellos.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "Las vacas tienen 'mejores amigas' y pueden sufrir mucho estrÃ©s (e incluso llorar) si las separan.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "El primer virus informÃ¡tico se llamÃ³ 'Creeper' y mostraba el mensaje: 'Â¡Soy el Creeper, atrÃ¡pame si puedes!'.",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Una nube promedio puede pesar unos 500.000 kg; imagina una manada gigante de elefantes flotando sobre tu cabeza.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "El ADN humano es 50% similar al de un plÃ¡tano. AsÃ­ que llamar 'hermano' a un plÃ¡tano no es tan descabellado.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Los osos polares tienen la piel negra y su pelaje es transparente; se ven blancos por cÃ³mo reflejan la luz.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "No se puede llorar en el espacio: sin gravedad, las lÃ¡grimas no caen, se quedan acumuladas como una burbuja en el ojo.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "El Monte Everest crece unos 4 milÃ­metros al aÃ±o; la Tierra sigue cambiando.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Los ratones que 'silban' en realidad se estÃ¡n cantando, pero a una frecuencia tan alta que los humanos no podemos oÃ­rla.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "Los tiburones son mÃ¡s antiguos que los Ã¡rboles: ellos llevan aquÃ­ 400 millones de aÃ±os, los Ã¡rboles solo 350 millones.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "BotÃ¡nicamente, las bananas son bayas, pero las fresas no. La naturaleza es extraÃ±a.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Una hormiga levanta 50 veces su peso. Si fueras una hormiga, podrÃ­as levantar un coche tÃº solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel puede crecer unos 15 cm en verano debido a la expansiÃ³n tÃ©rmica del metal.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "El peso total de todos los humanos en la Tierra es casi igual al peso total de todas las hormigas del mundo.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "Los perezosos aguantan la respiraciÃ³n bajo el agua mÃ¡s tiempo que los delfines: hasta 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "Las palomas distinguen entre pinturas de Picasso y Monet. Resulta que saben mÃ¡s de arte de lo que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "El GPS es gratis, pero el gobierno de EE. UU. gasta unos 2 millones de dÃ³lares al dÃ­a para mantenerlo funcionando.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "Los ornitorrincos no tienen estÃ³mago; la comida pasa directamente del esÃ³fago a los intestinos.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "A Shakespeare se le atribuye el primer uso de la palabra 'swagger' (estilo/chulerÃ­a). Incluso en el siglo XVI, tenÃ­a clase.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "El corazÃ³n de una ballena azul es tan grande que un humano podrÃ­a nadar por sus arterias principales.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "Las hormigas no tienen pulmones y nunca 'duermen' realmente; trabajan sin parar.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "En Saturno y JÃºpiter llueven diamantes literalmente. Al parecer, vivimos en el planeta equivocado.",
    "Honeybees can recognize human faces and remember them individually.":
        "Las abejas pueden reconocer rostros humanos y recordarlos individualmente.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "El 'sudor' de los hipopÃ³tamos es rosado y funciona como protector solar y antibacteriano.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "La caca del wombat es cÃºbica para que no ruede y marque mejor su territorio.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "El anacardo crece por fuera del fruto, colgando al final. Un diseÃ±o de la naturaleza bastante curioso.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "Los tiburones son mÃ¡s viejos que los anillos de Saturno. Ya estaban aquÃ­ millones de aÃ±os antes de que Saturno tuviera sus anillos.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "Las mariposas saborean con los pies. Cuando se posan en una hoja, estÃ¡n probando la cena.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Un caracol puede dormir hasta tres aÃ±os sin despertar. La verdad, me identifico.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "Los ojos del avestruz son mÃ¡s grandes que su cerebro.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Los flamencos nacen grises; su color rosa viene de los pigmentos de las algas y camarones que comen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Las ardillas plantan miles de Ã¡rboles al aÃ±o simplemente porque olvidan dÃ³nde enterraron sus nueces.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "El primer videojuego jugado en el espacio fue Tetris, en una Game Boy, por un cosmonauta en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "Los pÃ¡jaros carpinteros envuelven su lengua alrededor de su cerebro para protegerlo de los golpes. Usar la lengua como casco es una locura.",
  },
  'hi': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "à¤•à¥Œà¤µà¥‡ à¤¨ à¤•à¥‡à¤µà¤² à¤‡à¤‚à¤¸à¤¾à¤¨à¥€ à¤šà¥‡à¤¹à¤°à¥‡ à¤ªà¤¹à¤šà¤¾à¤¨à¤¤à¥‡ à¤¹à¥ˆà¤‚, à¤¬à¤²à¥à¤•à¤¿ à¤‰à¤¨ à¤²à¥‹à¤—à¥‹à¤‚ à¤•à¥‹ à¤­à¥€ à¤¯à¤¾à¤¦ à¤°à¤–à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤œà¤¿à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤‰à¤¨à¤•à¥‡ à¤¸à¤¾à¤¥ à¤¬à¥à¤°à¤¾ à¤¬à¤°à¥à¤¤à¤¾à¤µ à¤•à¤¿à¤¯à¤¾, à¤”à¤° à¤µà¥‡ à¤¬à¤¾à¤•à¥€ à¤•à¥Œà¤µà¥‹à¤‚ à¤•à¥‹ à¤­à¥€ à¤†à¤—à¤¾à¤¹ à¤•à¤° à¤¦à¥‡à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "à¤¬à¤¿à¤²à¥à¤²à¤¿à¤¯à¤¾à¤ à¤…à¤ªà¤¨à¥‡ à¤œà¥€à¤µà¤¨ à¤•à¤¾ 70% à¤¹à¤¿à¤¸à¥à¤¸à¤¾ à¤¸à¥‹à¤¨à¥‡ à¤®à¥‡à¤‚ à¤¬à¤¿à¤¤à¤¾à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤¯à¤¾à¤¨à¥€ à¤à¤• 10 à¤¸à¤¾à¤² à¤•à¥€ à¤¬à¤¿à¤²à¥à¤²à¥€ à¤…à¤¸à¤² à¤®à¥‡à¤‚ à¤¸à¤¿à¤°à¥à¤« 3 à¤¸à¤¾à¤² à¤¹à¥€ à¤œà¤¾à¤—à¥€ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆà¥¤",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "à¤¶à¤¹à¤¦ à¤•à¤­à¥€ à¤–à¤°à¤¾à¤¬ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾à¥¤ à¤ªà¥à¤°à¤¾à¤¤à¤¤à¥à¤µà¤µà¤¿à¤¦à¥‹à¤‚ à¤•à¥‹ à¤®à¤¿à¤¸à¥à¤° à¤•à¥‡ à¤ªà¤¿à¤°à¤¾à¤®à¤¿à¤¡à¥‹à¤‚ à¤®à¥‡à¤‚ 3,000 à¤¸à¤¾à¤² à¤ªà¥à¤°à¤¾à¤¨à¤¾ à¤¶à¤¹à¤¦ à¤®à¤¿à¤²à¤¾ à¤¹à¥ˆ à¤œà¥‹ à¤†à¤œ à¤­à¥€ à¤–à¤¾à¤¨à¥‡ à¤¯à¥‹à¤—à¥à¤¯ à¤¹à¥ˆà¥¤",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "à¤¸à¤®à¥à¤¦à¥à¤°à¥€ à¤Šà¤¦à¤¬à¤¿à¤²à¤¾à¤µ (Sea otters) à¤¸à¥‹à¤¤à¥‡ à¤¸à¤®à¤¯ à¤à¤•-à¤¦à¥‚à¤¸à¤°à¥‡ à¤•à¤¾ à¤¹à¤¾à¤¥ à¤ªà¤•à¤¡à¤¼ à¤•à¤° à¤°à¤–à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤¤à¤¾à¤•à¤¿ à¤µà¥‡ à¤ªà¤¾à¤¨à¥€ à¤•à¥‡ à¤¬à¤¹à¤¾à¤µ à¤®à¥‡à¤‚ à¤¬à¤¿à¤›à¤¡à¤¼ à¤¨ à¤œà¤¾à¤à¤‚à¥¤",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "à¤¶à¥à¤•à¥à¤° à¤—à¥à¤°à¤¹ à¤ªà¤° à¤à¤• à¤¦à¤¿à¤¨, à¤‰à¤¸à¤•à¥‡ à¤à¤• à¤¸à¤¾à¤² à¤¸à¥‡ à¤­à¥€ à¤²à¤‚à¤¬à¤¾ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤¯à¤¹ à¤…à¤ªà¤¨à¥€ à¤§à¥à¤°à¥€ à¤ªà¤° à¤¸à¥‚à¤°à¤œ à¤•à¥€ à¤ªà¤°à¤¿à¤•à¥à¤°à¤®à¤¾ à¤•à¤°à¤¨à¥‡ à¤¸à¥‡ à¤­à¥€ à¤§à¥€à¤®à¥€ à¤—à¤¤à¤¿ à¤¸à¥‡ à¤˜à¥‚à¤®à¤¤à¤¾ à¤¹à¥ˆà¥¤",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "à¤²à¤¾à¤‡à¤Ÿà¤° à¤•à¤¾ à¤†à¤µà¤¿à¤·à¥à¤•à¤¾à¤° à¤®à¤¾à¤šà¤¿à¤¸ à¤¸à¥‡ à¤ªà¤¹à¤²à¥‡ à¤¹à¥à¤† à¤¥à¤¾à¥¤ à¤•à¤­à¥€-à¤•à¤­à¥€ à¤ªà¥à¤°à¤¾à¤¨à¥€ à¤¤à¤•à¤¨à¥€à¤• à¤¹à¤®à¤¾à¤°à¥€ à¤¸à¥‹à¤š à¤¸à¥‡ à¤­à¥€ à¤œà¥à¤¯à¤¾à¤¦à¤¾ à¤ªà¥à¤°à¤¾à¤¨à¥€ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆà¥¤",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "à¤‘à¤•à¥à¤Ÿà¥‹à¤ªà¤¸ à¤•à¥‡ à¤ªà¤¾à¤¸ à¤¤à¥€à¤¨ à¤¦à¤¿à¤² à¤”à¤° à¤¨à¥Œ à¤¦à¤¿à¤®à¤¾à¤— à¤¹à¥‹à¤¤à¥‡ à¤¹à¥ˆà¤‚â€”à¤šà¥€à¤œà¥‹à¤‚ à¤•à¥‹ à¤­à¥‚à¤²à¤¨à¤¾ à¤‰à¤¨à¤•à¥‡ à¤²à¤¿à¤ à¤•à¥‹à¤ˆ à¤µà¤¿à¤•à¤²à¥à¤ª à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¥¤",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "à¤—à¤¾à¤¯à¥‹à¤‚ à¤•à¥‡ à¤­à¥€ 'à¤¬à¥‡à¤¸à¥à¤Ÿ à¤«à¥à¤°à¥‡à¤‚à¤¡à¥à¤¸' à¤¹à¥‹à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤…à¤—à¤° à¤‰à¤¨à¥à¤¹à¥‡à¤‚ à¤…à¤²à¤— à¤•à¤° à¤¦à¤¿à¤¯à¤¾ à¤œà¤¾à¤, à¤¤à¥‹ à¤µà¥‡ à¤¬à¤¹à¥à¤¤ à¤¤à¤¨à¤¾à¤µ à¤®à¥‡à¤‚ à¤† à¤œà¤¾à¤¤à¥€ à¤¹à¥ˆà¤‚ à¤”à¤° à¤°à¥‹à¤¨à¥‡ à¤­à¥€ à¤²à¤—à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "à¤¦à¥à¤¨à¤¿à¤¯à¤¾ à¤•à¥‡ à¤ªà¤¹à¤²à¥‡ à¤•à¤‚à¤ªà¥à¤¯à¥‚à¤Ÿà¤° à¤µà¤¾à¤¯à¤°à¤¸ à¤•à¤¾ à¤¨à¤¾à¤® 'à¤•à¥à¤°à¥€à¤ªà¤°' à¤¥à¤¾, à¤œà¥‹ à¤¸à¥à¤•à¥à¤°à¥€à¤¨ à¤ªà¤° à¤²à¤¿à¤–à¤¤à¤¾ à¤¥à¤¾: 'à¤®à¥ˆà¤‚ à¤•à¥à¤°à¥€à¤ªà¤° à¤¹à¥‚à¤, à¤ªà¤•à¤¡à¤¼ à¤¸à¤•à¥‹ à¤¤à¥‹ à¤ªà¤•à¤¡à¤¼ à¤²à¥‹!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "à¤à¤• à¤”à¤¸à¤¤ à¤¬à¤¾à¤¦à¤² à¤•à¤¾ à¤µà¤œà¤¨ à¤•à¤°à¥€à¤¬ 500,000 à¤•à¤¿à¤²à¥‹ à¤¹à¥‹ à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆâ€”à¤œà¥ˆà¤¸à¥‡ à¤¹à¤¾à¤¥à¤¿à¤¯à¥‹à¤‚ à¤•à¤¾ à¤à¤• à¤µà¤¿à¤¶à¤¾à¤² à¤à¥à¤‚à¤¡ à¤†à¤ªà¤•à¥‡ à¤¸à¤¿à¤° à¤•à¥‡ à¤Šà¤ªà¤° à¤¤à¥ˆà¤° à¤°à¤¹à¤¾ à¤¹à¥‹à¥¤",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "à¤‡à¤‚à¤¸à¤¾à¤¨à¥€ à¤¡à¥€à¤à¤¨à¤ à¤”à¤° à¤•à¥‡à¤²à¥‡ à¤•à¤¾ à¤¡à¥€à¤à¤¨à¤ 50% à¤à¤• à¤œà¥ˆà¤¸à¤¾ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤¤à¥‹ à¤…à¤—à¤° à¤†à¤ª à¤•à¥‡à¤²à¥‡ à¤•à¥‹ à¤…à¤ªà¤¨à¤¾ 'à¤­à¤¾à¤ˆ-à¤¬à¤¹à¤¨' à¤•à¤¹à¥‡à¤‚, à¤¤à¥‹ à¤¯à¤¹ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤—à¤²à¤¤ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤—à¤¾à¥¤",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "à¤§à¥à¤°à¥à¤µà¥€à¤¯ à¤­à¤¾à¤²à¥‚ (Polar Bear) à¤•à¥€ à¤¤à¥à¤µà¤šà¤¾ à¤…à¤¸à¤² à¤®à¥‡à¤‚ à¤•à¤¾à¤²à¥€ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆ à¤”à¤° à¤‰à¤¨à¤•à¥‡ à¤¬à¤¾à¤² à¤ªà¤¾à¤°à¤¦à¤°à¥à¤¶à¥€à¥¤ à¤°à¥‹à¤¶à¤¨à¥€ à¤•à¥‡ à¤¬à¤¿à¤–à¤°à¤¾à¤µ à¤•à¥€ à¤µà¤œà¤¹ à¤¸à¥‡ à¤µà¥‡ à¤¸à¤«à¥‡à¤¦ à¤¦à¤¿à¤–à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "à¤†à¤ª à¤…à¤‚à¤¤à¤°à¤¿à¤•à¥à¤· à¤®à¥‡à¤‚ à¤°à¥‹ à¤¨à¤¹à¥€à¤‚ à¤¸à¤•à¤¤à¥‡à¥¤ à¤—à¥à¤°à¥à¤¤à¥à¤µà¤¾à¤•à¤°à¥à¤·à¤£ à¤•à¥‡ à¤¬à¤¿à¤¨à¤¾ à¤†à¤à¤¸à¥‚ à¤—à¤¾à¤²à¥‹à¤‚ à¤ªà¤° à¤¨à¤¹à¥€à¤‚ à¤—à¤¿à¤°à¤¤à¥‡, à¤¬à¤²à¥à¤•à¤¿ à¤†à¤à¤–à¥‹à¤‚ à¤®à¥‡à¤‚ à¤¹à¥€ à¤à¤• à¤¬à¥à¤²à¤¬à¥à¤²à¥‡ à¤•à¥€ à¤¤à¤°à¤¹ à¤œà¤® à¤œà¤¾à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "à¤®à¤¾à¤‰à¤‚à¤Ÿ à¤à¤µà¤°à¥‡à¤¸à¥à¤Ÿ à¤¹à¤° à¤¸à¤¾à¤² à¤²à¤—à¤­à¤— 4 à¤®à¤¿à¤²à¥€à¤®à¥€à¤Ÿà¤° à¤¬à¤¢à¤¼à¤¤à¤¾ à¤¹à¥ˆâ€”à¤¹à¤®à¤¾à¤°à¥€ à¤§à¤°à¤¤à¥€ à¤…à¤¬ à¤­à¥€ à¤¬à¤¦à¤² à¤°à¤¹à¥€ à¤¹à¥ˆà¥¤",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "à¤¸à¥€à¤Ÿà¥€ à¤¬à¤œà¤¾à¤¨à¥‡ à¤µà¤¾à¤²à¥‡ à¤šà¥‚à¤¹à¥‡ à¤…à¤¸à¤² à¤®à¥‡à¤‚ à¤à¤•-à¤¦à¥‚à¤¸à¤°à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤—à¤¾à¤¨à¤¾ à¤—à¤¾à¤¤à¥‡ à¤¹à¥ˆà¤‚, à¤²à¥‡à¤•à¤¿à¤¨ à¤‰à¤¨à¤•à¥€ à¤†à¤µà¤¾à¤œà¤¼ à¤‡à¤¤à¤¨à¥€ à¤¬à¤¾à¤°à¥€à¤• à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆ à¤•à¤¿ à¤‡à¤‚à¤¸à¤¾à¤¨ à¤¸à¥à¤¨ à¤¨à¤¹à¥€à¤‚ à¤¸à¤•à¤¤à¥‡à¥¤",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "à¤¶à¤¾à¤°à¥à¤• à¤ªà¥‡à¤¡à¤¼à¥‹à¤‚ à¤¸à¥‡ à¤­à¥€ à¤œà¥à¤¯à¤¾à¤¦à¤¾ à¤ªà¥à¤°à¤¾à¤¨à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤¶à¤¾à¤°à¥à¤• 400 à¤®à¤¿à¤²à¤¿à¤¯à¤¨ à¤¸à¤¾à¤²à¥‹à¤‚ à¤¸à¥‡ à¤¹à¥ˆà¤‚, à¤œà¤¬à¤•à¤¿ à¤ªà¥‡à¤¡à¤¼ 350 à¤®à¤¿à¤²à¤¿à¤¯à¤¨ à¤¸à¤¾à¤² à¤ªà¤¹à¤²à¥‡ à¤†à¤à¥¤",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "à¤µà¤¨à¤¸à¥à¤ªà¤¤à¤¿ à¤µà¤¿à¤œà¥à¤à¤¾à¤¨ à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤° à¤•à¥‡à¤²à¤¾ à¤à¤• 'à¤¬à¥‡à¤°à¥€' à¤¹à¥ˆ, à¤²à¥‡à¤•à¤¿à¤¨ à¤¸à¥à¤Ÿà¥à¤°à¥‰à¤¬à¥‡à¤°à¥€ à¤¨à¤¹à¥€à¤‚à¥¤ à¤µà¤¿à¤œà¥à¤à¤¾à¤¨ à¤•à¤­à¥€-à¤•à¤­à¥€ à¤…à¤œà¥€à¤¬ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "à¤šà¥€à¤‚à¤Ÿà¥€ à¤…à¤ªà¤¨à¥‡ à¤µà¤œà¤¨ à¤•à¤¾ 50 à¤—à¥à¤¨à¤¾ à¤‰à¤ à¤¾ à¤¸à¤•à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤…à¤—à¤° à¤†à¤ª à¤šà¥€à¤‚à¤Ÿà¥€ à¤¹à¥‹à¤¤à¥‡, à¤¤à¥‹ à¤à¤• à¤•à¤¾à¤° à¤…à¤•à¥‡à¤²à¥‡ à¤‰à¤ à¤¾ à¤²à¥‡à¤¤à¥‡à¥¤",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "à¤—à¤°à¥à¤®à¥€ à¤•à¥€ à¤µà¤œà¤¹ à¤¸à¥‡ à¤à¤«à¤¿à¤² à¤Ÿà¥‰à¤µà¤° à¤•à¥€ à¤Šà¤‚à¤šà¤¾à¤ˆ 15 à¤¸à¥‡à¤‚à¤Ÿà¥€à¤®à¥€à¤Ÿà¤° à¤¤à¤• à¤¬à¤¢à¤¼ à¤œà¤¾à¤¤à¥€ à¤¹à¥ˆà¥¤",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "à¤§à¤°à¤¤à¥€ à¤ªà¤° à¤®à¥Œà¤œà¥‚à¤¦ à¤¸à¤­à¥€ à¤‡à¤‚à¤¸à¤¾à¤¨à¥‹à¤‚ à¤•à¤¾ à¤•à¥à¤² à¤µà¤œà¤¨, à¤¦à¥à¤¨à¤¿à¤¯à¤¾ à¤•à¥€ à¤¸à¤¾à¤°à¥€ à¤šà¥€à¤‚à¤Ÿà¤¿à¤¯à¥‹à¤‚ à¤•à¥‡ à¤•à¥à¤² à¤µà¤œà¤¨ à¤•à¥‡ à¤²à¤—à¤­à¤— à¤¬à¤°à¤¾à¤¬à¤° à¤¹à¥ˆà¥¤",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "à¤¸à¥à¤²à¥‰à¤¥ (Sloth) à¤ªà¤¾à¤¨à¥€ à¤•à¥‡ à¤…à¤‚à¤¦à¤° à¤¡à¥‰à¤²à¥à¤«à¤¿à¤¨ à¤¸à¥‡ à¤œà¥à¤¯à¤¾à¤¦à¤¾ à¤¦à¥‡à¤° à¤¤à¤• à¤¸à¤¾à¤‚à¤¸ à¤°à¥‹à¤• à¤¸à¤•à¤¤à¥‡ à¤¹à¥ˆà¤‚â€”à¤•à¤°à¥€à¤¬ 40 à¤®à¤¿à¤¨à¤Ÿ à¤¤à¤•à¥¤",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "à¤•à¤¬à¥‚à¤¤à¤° à¤ªà¤¿à¤•à¤¾à¤¸à¥‹ à¤”à¤° à¤®à¥‹à¤¨à¥‡à¤Ÿ à¤•à¥€ à¤ªà¥‡à¤‚à¤Ÿà¤¿à¤‚à¤—à¥à¤¸ à¤®à¥‡à¤‚ à¤«à¤°à¥à¤• à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤µà¥‡ à¤¹à¤®à¤¾à¤°à¥€ à¤¸à¥‹à¤š à¤¸à¥‡ à¤œà¥à¤¯à¤¾à¤¦à¤¾ à¤•à¤²à¤¾-à¤ªà¥à¤°à¥‡à¤®à¥€ à¤¹à¥ˆà¤‚à¥¤",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS à¤‡à¤¸à¥à¤¤à¥‡à¤®à¤¾à¤² à¤•à¤°à¤¨à¤¾ à¤«à¥à¤°à¥€ à¤¹à¥ˆ, à¤²à¥‡à¤•à¤¿à¤¨ à¤‡à¤¸à¥‡ à¤šà¤²à¤¾à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤…à¤®à¥‡à¤°à¤¿à¤•à¥€ à¤¸à¤°à¤•à¤¾à¤° à¤¹à¤° à¤¦à¤¿à¤¨ à¤•à¤°à¥€à¤¬ 2 à¤®à¤¿à¤²à¤¿à¤¯à¤¨ à¤¡à¥‰à¤²à¤° à¤–à¤°à¥à¤š à¤•à¤°à¤¤à¥€ à¤¹à¥ˆà¥¤",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "à¤ªà¥à¤²à¥ˆà¤Ÿà¤¿à¤ªà¤¸ à¤•à¥‡ à¤ªà¤¾à¤¸ à¤ªà¥‡à¤Ÿ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾; à¤–à¤¾à¤¨à¤¾ à¤¸à¥€à¤§à¥‡ à¤‰à¤¨à¤•à¥€ à¤†à¤‚à¤¤à¥‹à¤‚ à¤®à¥‡à¤‚ à¤œà¤¾à¤¤à¤¾ à¤¹à¥ˆà¥¤",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "à¤µà¤¿à¤²à¤¿à¤¯à¤® à¤¶à¥‡à¤•à¥à¤¸à¤ªà¤¿à¤¯à¤° à¤¨à¥‡ à¤¹à¥€ à¤¸à¤¬à¤¸à¥‡ à¤ªà¤¹à¤²à¥‡ 'à¤¸à¥à¤µà¥ˆà¤—à¤°' (Swagger) à¤¶à¤¬à¥à¤¦ à¤•à¤¾ à¤‡à¤¸à¥à¤¤à¥‡à¤®à¤¾à¤² à¤•à¤¿à¤¯à¤¾ à¤¥à¤¾à¥¤ 16à¤µà¥€à¤‚ à¤¸à¤¦à¥€ à¤®à¥‡à¤‚ à¤­à¥€ à¤‰à¤¨à¤•à¤¾ à¤…à¤ªà¤¨à¤¾ à¤Ÿà¤¶à¤¨ à¤¥à¤¾à¥¤",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "à¤¬à¥à¤²à¥‚ à¤µà¥à¤¹à¥‡à¤² à¤•à¤¾ à¤¦à¤¿à¤² à¤‡à¤¤à¤¨à¤¾ à¤¬à¤¡à¤¼à¤¾ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤•à¤¿ à¤à¤• à¤‡à¤‚à¤¸à¤¾à¤¨ à¤‰à¤¸à¤•à¥€ à¤¨à¤¸à¥‹à¤‚ à¤•à¥‡ à¤…à¤‚à¤¦à¤° à¤¤à¥ˆà¤° à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆà¥¤",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "à¤šà¥€à¤‚à¤Ÿà¤¿à¤¯à¥‹à¤‚ à¤•à¥‡ à¤«à¥‡à¤«à¤¡à¤¼à¥‡ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¥‡ à¤”à¤° à¤µà¥‡ à¤•à¤­à¥€ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤¨à¤¹à¥€à¤‚ 'à¤¸à¥‹à¤¤à¥€à¤‚'à¥¤ à¤µà¥‡ à¤›à¥‹à¤Ÿà¥‡ à¤•à¤¾à¤®à¤šà¥‹à¤° à¤¨à¤¹à¥€à¤‚, à¤¬à¤²à¥à¤•à¤¿ à¤•à¤°à¥à¤®à¤  à¤®à¤œà¤¦à¥‚à¤° à¤¹à¥ˆà¤‚à¥¤",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "à¤¶à¤¨à¤¿ à¤”à¤° à¤¬à¥ƒà¤¹à¤¸à¥à¤ªà¤¤à¤¿ à¤—à¥à¤°à¤¹ à¤ªà¤° à¤¹à¥€à¤°à¥‹à¤‚ à¤•à¥€ à¤¬à¤¾à¤°à¤¿à¤¶ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤²à¤—à¤¤à¤¾ à¤¹à¥ˆ à¤¹à¤® à¤—à¤²à¤¤ à¤—à¥à¤°à¤¹ à¤ªà¤° à¤°à¤¹ à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚à¥¤",
    "Honeybees can recognize human faces and remember them individually.":
        "à¤®à¤§à¥à¤®à¤•à¥à¤–à¤¿à¤¯à¤¾à¤‚ à¤‡à¤‚à¤¸à¤¾à¤¨à¥€ à¤šà¥‡à¤¹à¤°à¥‹à¤‚ à¤•à¥‹ à¤ªà¤¹à¤šà¤¾à¤¨ à¤¸à¤•à¤¤à¥€ à¤¹à¥ˆà¤‚ à¤”à¤° à¤‰à¤¨à¥à¤¹à¥‡à¤‚ à¤¯à¤¾à¤¦ à¤­à¥€ à¤°à¤– à¤¸à¤•à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "à¤¦à¤°à¤¿à¤¯à¤¾à¤ˆ à¤˜à¥‹à¤¡à¤¼à¥‡ à¤•à¤¾ à¤ªà¤¸à¥€à¤¨à¤¾ à¤—à¥à¤²à¤¾à¤¬à¥€ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤”à¤° à¤¯à¤¹ à¤¸à¤¨à¤¸à¥à¤•à¥à¤°à¥€à¤¨ à¤”à¤° à¤à¤‚à¤Ÿà¥€à¤¬à¤¾à¤¯à¥‹à¤Ÿà¤¿à¤• à¤•à¥€ à¤¤à¤°à¤¹ à¤•à¤¾à¤® à¤•à¤°à¤¤à¤¾ à¤¹à¥ˆà¥¤",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "à¤µà¥‰à¤®à¥à¤¬à¥ˆà¤Ÿ (Wombat) à¤•à¥€ à¤ªà¥‰à¤Ÿà¥€ à¤šà¥Œà¤•à¥‹à¤° (à¤•à¥à¤¯à¥‚à¤¬) à¤†à¤•à¤¾à¤° à¤•à¥€ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆ, à¤¤à¤¾à¤•à¤¿ à¤µà¤¹ à¤²à¥à¤¢à¤¼à¤• à¤¨ à¤œà¤¾à¤ à¤”à¤° à¤‡à¤²à¤¾à¤•à¤¾ à¤®à¤¾à¤°à¥à¤• à¤•à¤° à¤¸à¤•à¥‡à¥¤",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "à¤•à¤¾à¤œà¥‚, à¤•à¤¾à¤œà¥‚-à¤«à¤² à¤•à¥‡ à¤¬à¤¾à¤¹à¤° à¤‰à¤—à¤¤à¤¾ à¤¹à¥ˆ à¤”à¤° à¤¨à¥€à¤šà¥‡ à¤²à¤Ÿà¤•à¤¾ à¤°à¤¹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤•à¥à¤¦à¤°à¤¤ à¤•à¤¾ à¤à¤• à¤…à¤œà¥€à¤¬ à¤¡à¤¿à¤œà¤¾à¤‡à¤¨à¥¤",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "à¤¶à¤¾à¤°à¥à¤•, à¤¶à¤¨à¤¿ à¤—à¥à¤°à¤¹ à¤•à¥‡ à¤›à¤²à¥à¤²à¥‹à¤‚ à¤¸à¥‡ à¤­à¥€ à¤ªà¥à¤°à¤¾à¤¨à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤œà¤¬ à¤¶à¤¨à¤¿ à¤•à¥‹ à¤‰à¤¸à¤•à¥‡ à¤›à¤²à¥à¤²à¥‡ à¤®à¤¿à¤²à¥‡, à¤‰à¤¸à¤¸à¥‡ à¤•à¤°à¥‹à¤¡à¤¼à¥‹à¤‚ à¤¸à¤¾à¤² à¤ªà¤¹à¤²à¥‡ à¤¶à¤¾à¤°à¥à¤• à¤®à¥Œà¤œà¥‚à¤¦ à¤¥à¥€à¤‚à¥¤",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "à¤¤à¤¿à¤¤à¤²à¤¿à¤¯à¤¾à¤ à¤…à¤ªà¤¨à¥‡ à¤ªà¥ˆà¤°à¥‹à¤‚ à¤¸à¥‡ à¤¸à¥à¤µà¤¾à¤¦ à¤²à¥‡à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤œà¤¬ à¤µà¥‡ à¤•à¤¿à¤¸à¥€ à¤ªà¤¤à¥à¤¤à¥‡ à¤ªà¤° à¤¬à¥ˆà¤ à¤¤à¥€ à¤¹à¥ˆà¤‚, à¤¤à¥‹ à¤¸à¤®à¤à¥‹ à¤µà¥‡ à¤…à¤ªà¤¨à¤¾ à¤–à¤¾à¤¨à¤¾ à¤šà¤– à¤°à¤¹à¥€ à¤¹à¥ˆà¤‚à¥¤",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "à¤˜à¥‹à¤‚à¤˜à¤¾ (Snail) à¤²à¤—à¤¾à¤¤à¤¾à¤° à¤¤à¥€à¤¨ à¤¸à¤¾à¤² à¤¤à¤• à¤¸à¥‹ à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤¸à¤š à¤•à¤¹à¥‡à¤‚ à¤¤à¥‹, à¤•à¤¾à¤¶ à¤¹à¤® à¤­à¥€ à¤à¤¸à¤¾ à¤•à¤° à¤ªà¤¾à¤¤à¥‡à¥¤",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "à¤¶à¥à¤¤à¥à¤°à¤®à¥à¤°à¥à¤— à¤•à¥€ à¤†à¤à¤–à¥‡à¤‚ à¤‰à¤¸à¤•à¥‡ à¤¦à¤¿à¤®à¤¾à¤— à¤¸à¥‡ à¤¬à¤¡à¤¼à¥€ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "à¤«à¥à¤²à¥‡à¤®à¤¿à¤‚à¤—à¥‹ (à¤°à¤¾à¤œà¤¹à¤‚à¤¸) à¤ªà¥ˆà¤¦à¤¾ à¤¹à¥‹à¤¤à¥‡ à¤µà¤•à¥à¤¤ à¤—à¥à¤°à¥‡ à¤°à¤‚à¤— à¤•à¥‡ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤‰à¤¨à¤•à¤¾ à¤—à¥à¤²à¤¾à¤¬à¥€ à¤°à¤‚à¤— à¤‰à¤¨à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤–à¤¾à¤ à¤œà¤¾à¤¨à¥‡ à¤µà¤¾à¤²à¥‡ à¤à¥€à¤‚à¤—à¥‹à¤‚ à¤”à¤° à¤¶à¥ˆà¤µà¤¾à¤² à¤¸à¥‡ à¤†à¤¤à¤¾ à¤¹à¥ˆà¥¤",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "à¤—à¤¿à¤²à¤¹à¤°à¤¿à¤¯à¤¾à¤ à¤¹à¤° à¤¸à¤¾à¤² à¤¹à¤œà¤¾à¤°à¥‹à¤‚ à¤¨à¤ à¤ªà¥‡à¤¡à¤¼ à¤²à¤—à¤¾à¤¤à¥€ à¤¹à¥ˆà¤‚, à¤¸à¤¿à¤°à¥à¤« à¤‡à¤¸à¤²à¤¿à¤ à¤•à¥à¤¯à¥‹à¤‚à¤•à¤¿ à¤µà¥‡ à¤­à¥‚à¤² à¤œà¤¾à¤¤à¥€ à¤¹à¥ˆà¤‚ à¤•à¤¿ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤…à¤–à¤°à¥‹à¤Ÿ à¤•à¤¹à¤¾à¤ à¤›à¤¿à¤ªà¤¾à¤ à¤¥à¥‡à¥¤",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "à¤…à¤‚à¤¤à¤°à¤¿à¤•à¥à¤· à¤®à¥‡à¤‚ à¤–à¥‡à¤²à¤¾ à¤—à¤¯à¤¾ à¤ªà¤¹à¤²à¤¾ à¤µà¥€à¤¡à¤¿à¤¯à¥‹ à¤—à¥‡à¤® à¤Ÿà¥‡à¤Ÿà¥à¤°à¤¿à¤¸ (Tetris) à¤¥à¤¾, à¤œà¤¿à¤¸à¥‡ 1993 à¤®à¥‡à¤‚ à¤à¤• à¤—à¥‡à¤® à¤¬à¥‰à¤¯ à¤ªà¤° à¤–à¥‡à¤²à¤¾ à¤—à¤¯à¤¾ à¤¥à¤¾à¥¤",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "à¤•à¤ à¤«à¥‹à¤¡à¤¼à¤µà¤¾ à¤…à¤ªà¤¨à¥€ à¤œà¥€à¤­ à¤•à¥‹ à¤…à¤ªà¤¨à¥‡ à¤¦à¤¿à¤®à¤¾à¤— à¤•à¥‡ à¤šà¤¾à¤°à¥‹à¤‚ à¤“à¤° à¤²à¤ªà¥‡à¤Ÿ à¤²à¥‡à¤¤à¤¾ à¤¹à¥ˆ à¤¤à¤¾à¤•à¤¿ à¤šà¥‹à¤Ÿ à¤¨ à¤²à¤—à¥‡à¥¤ à¤œà¥€à¤­ à¤•à¥‹ à¤¹à¥‡à¤²à¤®à¥‡à¤Ÿ à¤•à¥€ à¤¤à¤°à¤¹ à¤‡à¤¸à¥à¤¤à¥‡à¤®à¤¾à¤² à¤•à¤°à¤¨à¤¾ à¤—à¤œà¤¬ à¤•à¤¾ à¤¤à¤°à¥€à¤•à¤¾ à¤¹à¥ˆà¥¤",
  },
  'hu': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "A varjak nemcsak felismerik az arcokat, hanem Ã©vekre megjegyzik azokat, akik rosszul bÃ¡ntak velÃ¼k â€“ sÅ‘t, mÃ¡s varjakat is figyelmeztetnek.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "A macskÃ¡k Ã©letÃ¼k 70%-Ã¡t Ã¡talusszÃ¡k. TehÃ¡t egy 10 Ã©ves macska valÃ³jÃ¡ban csak kb. 3 Ã©vet tÃ¶ltÃ¶tt Ã©bren.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "A mÃ©z sosem romlik meg. RÃ©gÃ©szek 3000 Ã©ves, ehetÅ‘ mÃ©zet talÃ¡ltak az egyiptomi piramisokban.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "A tengeri vidrÃ¡k kÃ©zenfogva alszanak, hogy az Ã¡ramlat ne sodorja el Å‘ket egymÃ¡stÃ³l.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "A VÃ©nuszon egy nap hosszabb, mint egy Ã©v â€“ lassabban fordul meg a tengelye kÃ¶rÃ¼l, mint ahogy megkerÃ¼li a Napot.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "Az Ã¶ngyÃºjtÃ³t a gyufa elÅ‘tt talÃ¡ltÃ¡k fel. NÃ©ha a 'rÃ©gi' technolÃ³gia rÃ©gebbi, mint hinnÃ©nk.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "A polipoknak hÃ¡rom szÃ­vÃ¼k Ã©s kilenc agyuk van â€“ a felejtÃ©s nÃ¡luk nem opciÃ³.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "A teheneknek vannak 'legjobb barÃ¡taik', Ã©s sÃºlyosan stresszelnek, sÅ‘t sÃ­rnak is, ha elvÃ¡lasztjÃ¡k Å‘ket.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "A vilÃ¡g elsÅ‘ szÃ¡mÃ­tÃ³gÃ©pes vÃ­rusa a 'Creeper' volt, ami ezt Ã­rta ki: 'Ã‰n vagyok a Creeper, kapj el, ha tudsz!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Egy Ã¡tlagos felhÅ‘ sÃºlya kb. 500 000 kg â€“ mintha egy hatalmas elefÃ¡ntcsorda lebegne a fejÃ¼nk felett.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "Az emberi DNS 50%-ban megegyezik a banÃ¡nÃ©val. SzÃ³val, ha holnap 'tesÃ³nak' hÃ­vsz egy banÃ¡nt, nem tÃ©vedsz nagyot.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "A jegesmedvÃ©k bÅ‘re valÃ³jÃ¡ban fekete, a szÅ‘rÃ¼k pedig Ã¡tlÃ¡tszÃ³. Csak a fÃ©nyvisszaverÅ‘dÃ©s miatt tÅ±nnek fehÃ©rnek.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "Az Å±rben nem tudsz sÃ­rni: gravitÃ¡ciÃ³ hÃ­jÃ¡n a kÃ¶nnyek nem folynak le, hanem egy gombÃ³cban gyÅ±lnek Ã¶ssze a szemedben.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "A Mount Everest Ã©vente kb. 4 millimÃ©tert nÅ‘ â€“ a FÃ¶ldÃ¼nk folyamatosan vÃ¡ltozik.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "A 'fÃ¼tyÃ¼lÅ‘' egerek valÃ³jÃ¡ban Ã©nekelnek egymÃ¡snak, csak olyan magas frekvenciÃ¡n, amit mi nem hallunk.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "A cÃ¡pÃ¡k idÅ‘sebbek, mint a fÃ¡k. A cÃ¡pÃ¡k 400 milliÃ³ Ã©ve vannak itt, a fÃ¡k csak 350 milliÃ³ Ã©ve.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "BiolÃ³giailag a banÃ¡n bogyÃ³s gyÃ¼mÃ¶lcs, de az eper nem az. A botanika nÃ©ha fura.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Egy hangya a sÃºlya 50-szeresÃ©t is elbÃ­rja. Ha hangya lennÃ©l, egyedÃ¼l felemelnÃ©l egy autÃ³t.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "NyÃ¡ron az Eiffel-torony kb. 15 centivel megnÅ‘ a hÅ‘tÃ¡gulÃ¡s miatt.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "A FÃ¶ld Ã¶sszes emberÃ©nek sÃºlya nagyjÃ¡bÃ³l megegyezik a vilÃ¡g Ã¶sszes hangyÃ¡jÃ¡nak sÃºlyÃ¡val.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "A lajhÃ¡rok tovÃ¡bb bÃ­rjÃ¡k vÃ­z alatt levegÅ‘ nÃ©lkÃ¼l, mint a delfinek â€“ akÃ¡r 40 percig is.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "A galambok meg tudjÃ¡k kÃ¼lÃ¶nbÃ¶ztetni Picasso Ã©s Monet festmÃ©nyeit. Ãšgy tÅ±nik, jobban Ã©rtenek a mÅ±vÃ©szethez, mint hittÃ¼k.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "A GPS ingyenes, de az USA kormÃ¡nya Ã¡llÃ­tÃ³lag napi 2 milliÃ³ dollÃ¡rt kÃ¶lt a mÅ±kÃ¶dtetÃ©sÃ©re.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "A kacsacsÅ‘rÅ± emlÅ‘snek nincs gyomra; az Ã©tel a nyelÅ‘csÅ‘bÅ‘l egyenesen a belekbe kerÃ¼l.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "A 'swagger' (vagÃ¡ny stÃ­lus) szÃ³t Shakespeare hasznÃ¡lta elÅ‘szÃ¶r. MÃ¡r a 16. szÃ¡zadban is volt stÃ­lusa.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "A kÃ©k bÃ¡lna szÃ­ve akkora, hogy egy ember simÃ¡n Ã¡tÃºszhatna a fÅ‘ artÃ©riÃ¡in.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "A hangyÃ¡knak nincs tÃ¼dejÃ¼k Ã©s sosem 'alszanak' igazÃ¡n. AprÃ³ munkamÃ¡niÃ¡sok.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "A Szaturnuszon Ã©s a Jupiteren gyÃ©mÃ¡ntesÅ‘ hullik. Ãšgy tÅ±nik, rossz bolygÃ³ra szÃ¼lettÃ¼nk.",
    "Honeybees can recognize human faces and remember them individually.":
        "A mÃ©hek kÃ©pesek felismerni Ã©s megjegyezni az emberi arcokat.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "A vÃ­zilovak izzadsÃ¡ga rÃ³zsaszÃ­n, ami naptejkÃ©nt Ã©s antibakteriÃ¡lis pajzskÃ©nt is szolgÃ¡l.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "A vombat Ã¼rÃ¼lÃ©ke kocka alakÃº, Ã­gy nem gurul el, Ã©s jobban jelzi a terÃ¼letet.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "A kesudiÃ³ a gyÃ¼mÃ¶lcsÃ¶n kÃ­vÃ¼l, annak az aljÃ¡n nÅ‘. ElÃ©g fura dizÃ¡jn.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "A cÃ¡pÃ¡k Ã¶regebbek a Szaturnusz gyÅ±rÅ±inÃ©l. MilliÃ³ Ã©vekkel a gyÅ±rÅ±k elÅ‘tt mÃ¡r itt voltak.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "A pillangÃ³k a lÃ¡bukkal Ã©reznek Ã­zeket. Ha rÃ¡szÃ¡llnak egy levÃ©lre, lÃ©nyegÃ©ben a vacsorÃ¡t kÃ³stoljÃ¡k.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Egy csiga akÃ¡r hÃ¡rom Ã©vig is aludhat egyhuzamban. ÅszintÃ©n szÃ³lva, irigylem.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "A strucc szeme nagyobb, mint az agya.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "A flamingÃ³k szÃ¼rkÃ©nek szÃ¼letnek. A szÃ­nÃ¼ket a rÃ¡kokbÃ³l Ã©s algÃ¡kbÃ³l nyert pigmentek okozzÃ¡k.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "A mÃ³kusok Ã©vente tÃ¶bb ezer fÃ¡t Ã¼ltetnek, pusztÃ¡n azÃ©rt, mert elfelejtik, hovÃ¡ Ã¡stÃ¡k el a mogyorÃ³t.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "Az elsÅ‘ videojÃ¡tÃ©k az Å±rben a Tetris volt, amit egy Å±rhajÃ³s jÃ¡tszott Game Boy-on 1993-ban.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "A harkÃ¡lyok a nyelvÃ¼kkel kÃ¶rbetekerik az agyukat, hogy tompÃ­tsÃ¡k az Ã¼tÃ©st. Nyelv-sisak, elÃ©g vad megoldÃ¡s.",
  },
  'zh-hans': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "ä¹Œé¸¦ä¸ä»…èƒ½è¯†åˆ«äººè„¸ï¼Œè¿˜èƒ½è®°ä½è™å¾…è¿‡å®ƒä»¬çš„äººé•¿è¾¾æ•°å¹´ï¼Œç”šè‡³ä¼šè­¦å‘ŠåŒä¼´ã€‚",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "çŒ«ä¸€ç”Ÿä¸­çº¦70%çš„æ—¶é—´éƒ½åœ¨ç¡è§‰ã€‚æ‰€ä»¥ä¸€åª10å²çš„çŒ«ï¼Œæ¸…é†’çš„æ—¶é—´åªæœ‰3å¹´å·¦å³ã€‚",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "èœ‚èœœæ°¸è¿œä¸ä¼šå˜è´¨ã€‚è€ƒå¤å­¦å®¶åœ¨åŸƒåŠé‡‘å­—å¡”é‡Œå‘ç°äº†3000å¹´å‰çš„èœ‚èœœï¼Œè‡³ä»Šä»å¯é£Ÿç”¨ã€‚",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "æµ·ç­ç¡è§‰æ—¶ä¼šæ‰‹ç‰µæ‰‹ï¼Œä»¥å…è¢«æ°´æµå†²æ•£ã€‚",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "åœ¨é‡‘æ˜Ÿä¸Šï¼Œä¸€å¤©æ¯”ä¸€å¹´è¿˜é•¿ã€‚å®ƒè‡ªè½¬çš„é€Ÿåº¦æ¯”ç»•å¤ªé˜³å…¬è½¬çš„é€Ÿåº¦è¿˜è¦æ…¢ã€‚",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "æ‰“ç«æœºæ¯”ç«æŸ´å‘æ˜å¾—æ›´æ—©ã€‚æœ‰æ—¶å€™ï¼Œâ€œè€â€æŠ€æœ¯æ¯”æˆ‘ä»¬æƒ³è±¡çš„è¿˜è¦å¤è€ã€‚",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "ç« é±¼æœ‰ä¸‰é¢—å¿ƒè„å’Œä¹ä¸ªå¤§è„‘â€”â€”æ‰€ä»¥â€œå¥å¿˜â€å¯¹å®ƒä»¬æ¥è¯´æ˜¯ä¸å­˜åœ¨çš„ã€‚",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "å¥¶ç‰›ä¹Ÿæœ‰â€œå¥½é—ºèœœâ€ã€‚å¦‚æœæŠŠå®ƒä»¬åˆ†å¼€ï¼Œå®ƒä»¬ä¼šæ„Ÿåˆ°ç„¦è™‘ï¼Œç”šè‡³ä¼šæµæ³ªã€‚",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "ä¸–ç•Œä¸Šç¬¬ä¸€ä¸ªè®¡ç®—æœºç—…æ¯’å«â€œCreeperâ€ï¼Œå®ƒçš„å¼¹çª—å†…å®¹æ˜¯ï¼šâ€œæˆ‘æ˜¯Creeperï¼Œæœ‰æœ¬äº‹æ¥æŠ“æˆ‘å‘€ï¼â€",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "ä¸€æœµæ™®é€šçš„äº‘é‡çº¦50ä¸‡å…¬æ–¤â€”â€”å°±åƒä¸€å¤§ç¾¤å¤§è±¡æ‚¬æµ®åœ¨å¤´é¡¶ã€‚",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "äººç±»çš„DNAä¸é¦™è•‰çš„DNAæœ‰50%çš„ç›¸ä¼¼åº¦ã€‚æ‰€ä»¥å«é¦™è•‰ä¸€å£°â€œäº²æˆšâ€ä¹Ÿä¸ç®—è¿‡åˆ†ã€‚",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "åŒ—æç†Šçš„çš®è‚¤å…¶å®æ˜¯é»‘è‰²çš„ï¼Œæ¯›å‘æ˜¯é€æ˜çš„ã€‚çœ‹èµ·æ¥æ˜¯ç™½è‰²æ˜¯å› ä¸ºå…‰çº¿çš„æŠ˜å°„ã€‚",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "åœ¨å¤ªç©ºä¸­æ²¡æ³•æµæ³ªï¼šå› ä¸ºæ²¡æœ‰é‡åŠ›ï¼Œçœ¼æ³ªä¸ä¼šæµä¸‹æ¥ï¼Œåªä¼šèšæˆä¸€å›¢ç§¯åœ¨çœ¼ç›é‡Œã€‚",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "ç ç©†æœ—ç›å³°æ¯å¹´ä»åœ¨é•¿é«˜çº¦4æ¯«ç±³â€”â€”åœ°çƒä¸€ç›´åœ¨å˜åŒ–ã€‚",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "æ‰€è°“â€œå¹å£å“¨â€çš„è€é¼ å…¶å®æ˜¯åœ¨äº’ç›¸å”±æ­Œï¼Œåªæ˜¯é¢‘ç‡å¤ªé«˜ï¼Œäººç±»å¬ä¸è§ã€‚",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "é²¨é±¼æ¯”æ ‘æœ¨æ›´å¤è€ã€‚é²¨é±¼å­˜åœ¨äº†4äº¿å¹´ï¼Œè€Œæ ‘æœ¨åªæœ‰3.5äº¿å¹´ã€‚",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "ä»æ¤ç‰©å­¦è§’åº¦çœ‹ï¼Œé¦™è•‰å±äºæµ†æœï¼Œä½†è‰è“å´ä¸æ˜¯ã€‚æ¤ç‰©å­¦çœŸæ˜¯å¥‡å¦™ã€‚",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "èš‚èšèƒ½ä¸¾èµ·è‡ªèº«ä½“é‡50å€çš„ç‰©ä½“ã€‚å¦‚æœä½ æ˜¯èš‚èšï¼Œä½ å¯ä»¥å¾’æ‰‹ä¸¾èµ·ä¸€è¾†æ±½è½¦ã€‚",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "ç”±äºçƒ­èƒ€å†·ç¼©ï¼ŒåŸƒè²å°”é“å¡”åœ¨å¤å¤©ä¼šé•¿é«˜çº¦15å˜ç±³ã€‚",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "åœ°çƒä¸Šæ‰€æœ‰äººç±»çš„æ€»é‡é‡ï¼Œå¤§çº¦ç­‰äºæ‰€æœ‰èš‚èšçš„æ€»é‡é‡ã€‚",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "æ ‘æ‡’åœ¨æ°´ä¸‹æ†‹æ°”çš„æ—¶é—´æ¯”æµ·è±šè¿˜é•¿â€”â€”å¯è¾¾40åˆ†é’Ÿã€‚",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "é¸½å­èƒ½åˆ†è¾¨å‡ºæ¯•Ã¥Å  ç´¢å’Œè«å¥ˆçš„ç”»ä½œã€‚çœ‹æ¥å®ƒä»¬æ¯”æˆ‘ä»¬æ›´æœ‰è‰ºæœ¯ç»†èƒã€‚",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPSæ˜¯å…è´¹ä½¿ç”¨çš„ï¼Œä½†æ®æŠ¥é“ï¼Œç¾å›½æ”¿åºœæ¯å¤©è¦èŠ±è´¹çº¦200ä¸‡ç¾å…ƒæ¥ç»´æŒå…¶è¿è¡Œã€‚",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "é¸­å˜´å…½æ²¡æœ‰èƒƒï¼Œé£Ÿç‰©ä»é£Ÿé“ç›´æ¥è¿›å…¥è‚ é“ã€‚",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "èå£«æ¯”äºšæ˜¯ç¬¬ä¸€ä¸ªä½¿ç”¨â€œSwaggerâ€ï¼ˆå¤§æ‘‡å¤§æ‘†/èŒƒå„¿ï¼‰è¿™ä¸ªè¯çš„äººã€‚æ—©åœ¨16ä¸–çºªä»–å°±å¾ˆæ½®äº†ã€‚",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "è“é²¸çš„å¿ƒè„å¤§åˆ°äººç±»å¯ä»¥åœ¨å®ƒçš„ä¸»è¦åŠ¨è„‰é‡Œæ¸¸æ³³ã€‚",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "èš‚èšæ²¡æœ‰è‚ºï¼Œä¹Ÿä¸çœŸæ­£â€œç¡è§‰â€ã€‚å®ƒä»¬å°±åƒå°å°çš„å·¥ä½œç‹‚ï¼Œæ°¸ä¸åœæ­‡ã€‚",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "åœ¨åœŸæ˜Ÿå’Œæœ¨æ˜Ÿä¸ŠçœŸçš„ä¼šä¸‹â€œé’»çŸ³é›¨â€ã€‚çœ‹æ¥æˆ‘ä»¬ä½é”™æ˜Ÿçƒäº†ã€‚",
    "Honeybees can recognize human faces and remember them individually.":
        "èœœèœ‚èƒ½è¯†åˆ«äººè„¸ï¼Œå¹¶ä¸”èƒ½å•ç‹¬è®°ä½æ¯ä¸€å¼ è„¸ã€‚",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "æ²³é©¬çš„â€œæ±—æ°´â€æ˜¯ç²‰çº¢è‰²çš„ï¼Œæ—¢èƒ½é˜²æ™’åˆèƒ½æ€èŒã€‚",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "è¢‹ç†Šçš„ä¾¿ä¾¿æ˜¯æ–¹å½¢çš„ï¼Œè¿™æ ·å°±ä¸ä¼šæ»šèµ°ï¼Œèƒ½æ›´å¥½åœ°æ ‡è®°é¢†åœ°ã€‚",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "è…°æœé•¿åœ¨æœå®çš„å¤–é¢ï¼ŒæŒ‚åœ¨æœ€åº•ç«¯ã€‚å¤§è‡ªç„¶çš„è®¾è®¡çœŸå¥‡æ€ªã€‚",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "é²¨é±¼æ¯”åœŸæ˜Ÿç¯è¿˜è¦å¤è€ã€‚åœ¨åœŸæ˜Ÿæˆ´ä¸Šå…‰ç¯ä¹‹å‰ï¼Œé²¨é±¼å·²ç»å­˜åœ¨äº†æ•°ç™¾ä¸‡å¹´ã€‚",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "è´è¶ç”¨è„šå°å‘³é“ã€‚å½“å®ƒä»¬åœåœ¨å¶å­ä¸Šæ—¶ï¼Œå…¶å®æ˜¯åœ¨è¯•åƒæ™šé¤ã€‚",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "èœ—ç‰›å¯ä»¥ä¸€ç¡ä¸‰å¹´ä¸é†’ã€‚è¯´å®è¯ï¼Œè¿™å¤ªè®©äººç¾¡æ…•äº†ã€‚",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "é¸µé¸Ÿçš„çœ¼ç›æ¯”è„‘å­è¿˜å¤§ã€‚",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "ç«çƒˆé¸Ÿå‡ºç”Ÿæ—¶æ˜¯ç°è‰²çš„ã€‚å®ƒä»¬æ ‡å¿—æ€§çš„ç²‰çº¢è‰²æ¥è‡ªé£Ÿç‰©ï¼ˆè™¾å’Œè—»ç±»ï¼‰ä¸­çš„è‰²ç´ ã€‚",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "æ¾é¼ æ¯å¹´ä¼šâ€œè¯¯æ‰“è¯¯æ’â€ç§ä¸‹å‡ åƒæ£µæ ‘ï¼Œå› ä¸ºå®ƒä»¬æ€»å¿˜è®°æŠŠåšæœåŸ‹å“ªå„¿äº†ã€‚",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "å¤ªç©ºä¸­ç©çš„ç¬¬ä¸€æ¬¾ç”µå­æ¸¸æˆæ˜¯ã€Šä¿„ç½—æ–¯æ–¹å—ã€‹ã€‚1993å¹´ï¼Œä¸€ä½å®‡èˆªå‘˜åœ¨Game Boyä¸Šç©çš„ã€‚",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "å•„æœ¨é¸ŸæŠŠèˆŒå¤´ç»•åœ¨è„‘å­ä¸Šä»¥é˜²è„‘éœ‡è¡ã€‚æŠŠèˆŒå¤´å½“å¤´ç›”ç”¨ï¼Œè¿™æ‹›å¤ªç»äº†ã€‚",
  },
  'id': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "Gagak tidak hanya mengenali wajah; mereka mengingat orang yang jahat pada mereka selama bertahun-tahun, bahkan memperingatkan gagak lain.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "Kucing menghabiskan 70% hidupnya untuk tidur. Jadi, kucing umur 10 tahun sebenarnya baru bangun selama 3 tahun.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Madu tidak pernah basi. Arkeolog menemukan madu berusia 3.000 tahun di piramida Mesir yang masih bisa dimakan.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "Berang-berang laut bergandengan tangan saat tidur supaya tidak terpisah oleh arus.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "Di Venus, satu hari lebih lama dari satu tahun. Rotasinya lebih lambat daripada waktu yang dibutuhkan untuk mengelilingi Matahari.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "Korek api gas (lighter) ditemukan sebelum korek api kayu (match). Kadang teknologi 'lama' lebih tua dari dugaan kita.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "Gurita punya tiga jantung dan sembilan otakâ€”jadi lupa ingatan bukan alasan bagi mereka.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "Sapi punya 'sahabat', dan mereka bisa stres beratâ€”bahkan menangisâ€”kalau dipisahkan.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "Virus komputer pertama bernama 'Creeper', yang menampilkan pesan: 'Aku Creeper, tangkap aku kalau bisa!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Awan rata-rata beratnya sekitar 500.000 kgâ€”seperti sekumpulan gajah yang melayang di atas kepala.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "DNA manusia 50% mirip dengan DNA pisang. Jadi menganggap pisang sebagai 'saudara jauh' tidak sepenuhnya salah.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Kulit beruang kutub sebenarnya hitam dan bulunya transparan. Mereka terlihat putih karena pantulan cahaya.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "Kamu tidak bisa menangis di luar angkasa. Tanpa gravitasi, air mata tidak jatuh, tapi menggumpal di mata.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "Gunung Everest tumbuh sekitar 4 milimeter setiap tahunâ€”Bumi masih terus berubah.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Tikus yang 'bersiul' sebenarnya sedang bernyanyi, tapi frekuensinya terlalu tinggi untuk didengar manusia.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "Hiu lebih tua dari pohon. Hiu sudah ada sejak 400 juta tahun lalu, pohon baru 350 juta tahun.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "Secara botani, pisang adalah beri, tapi stroberi bukan. Ilmu botani memang aneh.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Semut bisa mengangkat beban 50 kali berat tubuhnya. Kalau kamu semut, kamu bisa mengangkat mobil sendirian.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Menara Eiffel bisa bertambah tinggi 15 cm di musim panas karena pemuaian panas.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Total berat seluruh manusia di Bumi kira-kira sama dengan total berat seluruh semut.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "Kukang bisa menahan napas di dalam air lebih lama dari lumba-lumbaâ€”sampai 40 menit.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "Burung dara bisa membedakan lukisan Picasso dan Monet. Ternyata mereka punya jiwa seni.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS gratis digunakan, tapi pemerintah AS menghabiskan sekitar \$2 juta per hari untuk mengoperasikannya.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "Platipus tidak punya lambung; makanan langsung turun dari kerongkongan ke usus.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "William Shakespeare adalah orang pertama yang menggunakan kata 'swagger'. Dia sudah keren sejak abad ke-16.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "Jantung paus biru sangat besar sampai-sampai manusia bisa berenang di dalam pembuluh darah arterinya.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "Semut tidak punya paru-paru dan tidak pernah benar-benar 'tidur'. Mereka pekerja keras sejati.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "Di Saturnus dan Jupiter bisa terjadi hujan berlian. Sepertinya kita salah pilih planet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Lebah madu bisa mengenali dan mengingat wajah manusia.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "Keringat kuda nil berwarna merah muda dan berfungsi sebagai tabir surya sekaligus antibakteri.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "Kotoran wombat berbentuk kubus agar tidak menggelinding, sehingga lebih efektif menandai wilayah.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "Kacang mete tumbuh di luar buahnya, menggantung di ujung. Desain alam yang aneh.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "Hiu lebih tua dari cincin Saturnus. Hiu sudah ada jutaan tahun sebelum Saturnus punya cincinnya.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "Kupu-kupu mencicipi rasa dengan kakinya. Saat hinggap di daun, mereka sebenarnya sedang mencicipi makan malam.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Siput bisa tidur selama tiga tahun tanpa bangun. Jujur, aku iri.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "Mata burung unta lebih besar daripada otaknya.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingo lahir berwarna abu-abu. Warna merah mudanya berasal dari udang dan ganggang yang mereka makan.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Tupai menanam ribuan pohon setiap tahun secara tidak sengaja karena lupa di mana mengubur kacangnya.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "Game pertama yang dimainkan di luar angkasa adalah Tetris, dimainkan di Game Boy oleh kosmonot tahun 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "Burung pelatuk melilitkan lidahnya ke sekeliling otak untuk mencegah gegar otak. Lidah sebagai helm, ide gila.",
  },
  'nl': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "Kraaien herkennen niet alleen gezichten, ze onthouden ook jarenlang wie hen slecht behandelde en waarschuwen andere kraaien.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "Katten slapen 70% van hun leven. Een kat van 10 is dus eigenlijk maar 3 jaar wakker geweest.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Honing bederft nooit. Archeologen vonden in piramides 3000 jaar oude honing die nog eetbaar was.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "Zeeotters houden elkaars hand vast tijdens het slapen zodat ze niet uit elkaar drijven.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "Op Venus duurt een dag langer dan een jaar. De planeet draait langzamer om zijn as dan om de zon.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "De aansteker werd uitgevonden vÃ³Ã³r de lucifer. Soms is oude technologie nieuwer dan we denken.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "Octopussen hebben drie harten en negen breinenâ€”vergeten is voor hen geen optie.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "Koeien hebben 'beste vriendinnen' en raken gestrest, of gaan zelfs huilen, als ze gescheiden worden.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "Het eerste computervirus heette 'Creeper' en toonde de tekst: 'Ik ben de Creeper, pak me dan als je kan!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Een gemiddelde wolk weegt zo'n 500.000 kgâ€”alsof er een kudde olifanten boven je hoofd zweeft.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "Menselijk DNA lijkt voor 50% op dat van een banaan. Een banaan je 'broer' noemen is dus niet helemaal onterecht.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "De huid van een ijsbeer is zwart en de vacht transparant. Ze lijken wit door de weerkaatsing van licht.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "Je kunt niet huilen in de ruimte. Zonder zwaartekracht rollen tranen niet naar beneden, maar vormen ze een bolletje in je oog.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "De Mount Everest groeit elk jaar zo'n 4 millimeterâ€”de aarde verandert nog steeds.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Muizen die 'fluiten' zingen eigenlijk naar elkaar, maar op een frequentie die wij niet kunnen horen.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "Haaien zijn ouder dan bomen. Haaien zijn er al 400 miljoen jaar, bomen pas 350 miljoen jaar.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "Botanisch gezien is een banaan een bes, maar een aardbei niet. De natuur is vreemd.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Een mier tilt 50 keer zijn eigen gewicht. Als jij een mier was, kon je in je eentje een auto optillen.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "De Eiffeltoren wordt in de zomer zo'n 15 cm langer door de hitte.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Het totale gewicht van alle mensen op aarde is ongeveer gelijk aan dat van alle mieren.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "Luiaards kunnen langer hun adem inhouden onder water dan dolfijnenâ€”tot wel 40 minuten.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "Duiven zien het verschil tussen Picasso en Monet. Ze hebben meer verstand van kunst dan wij.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS is gratis, maar de Amerikaanse overheid geeft dagelijks zo'n 2 miljoen dollar uit om het draaiende te houden.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "Vogelbekdieren hebben geen maag; voedsel gaat direct van de slokdarm naar de darmen.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "Shakespeare gebruikte als eerste het woord 'swagger'. Hij had al stijl in de 16e eeuw.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "Het hart van een blauwe vinvis is zo groot dat een mens door de slagaderen zou kunnen zwemmen.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "Mieren hebben geen longen en slapen nooit echt. Het zijn kleine workaholics.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "Op Saturnus en Jupiter regent het diamanten. We wonen op de verkeerde planeet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Honingbijen kunnen menselijke gezichten herkennen en onthouden.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "Het zweet van nijlpaarden is roze en werkt als zonnebrandcrÃ¨me en bacteriedoder.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "De poep van een wombat is vierkant (kubus), zodat het niet wegrolt en zijn territorium markeert.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "Cashewnoten groeien aan de buitenkant van de vrucht, helemaal onderaan. Een vreemd ontwerp van de natuur.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "Haaien zijn ouder dan de ringen van Saturnus. Ze waren er al miljoenen jaren eerder.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "Vlinders proeven met hun voeten. Als ze op een blad landen, zijn ze eigenlijk aan het voorproeven.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Een slak kan drie jaar aan Ã©Ã©n stuk slapen. Eerlijk gezegd: jaloers.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "De ogen van een struisvogel zijn groter dan zijn hersenen.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingo's worden grijs geboren. Hun roze kleur komt door de garnalen en algen die ze eten.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Eekhoorns planten per ongeluk duizenden bomen per jaar omdat ze vergeten waar ze hun nootjes hebben begraven.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "De eerste videogame in de ruimte was Tetris, gespeeld op een Game Boy door een kosmonaut in 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "Spechten wikkelen hun tong om hun hersenen als schokdemper. Je tong als helm gebruiken is best wild.",
  },
  'fr': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "Les corbeaux reconnaissent les visages et se souviennent pendant des annÃ©es de ceux qui les ont maltraitÃ©s, prÃ©venant mÃªme les autres.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "Les chats dorment 70% de leur vie. Un chat de 10 ans n'a donc passÃ© que 3 ans Ã©veillÃ©.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Le miel ne se pÃ©rime jamais. Des archÃ©ologues ont trouvÃ© du miel vieux de 3000 ans dans des pyramides, encore comestible.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "Les loutres de mer se tiennent la main en dormant pour ne pas Ãªtre sÃ©parÃ©es par le courant.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "Sur VÃ©nus, un jour dure plus longtemps qu'une annÃ©e. Elle tourne sur elle-mÃªme plus lentement qu'autour du Soleil.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "Le briquet a Ã©tÃ© inventÃ© avant l'allumette. Parfois, la technologie 'moderne' est plus ancienne qu'on ne le croit.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "Les pieuvres ont trois cÅ“urs et neuf cerveaux. L'oubli n'est pas vraiment une option pour elles.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "Les vaches ont des 'meilleures amies' et peuvent stresser, voire pleurer, si on les sÃ©pare.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "Le premier virus informatique s'appelait 'Creeper' et affichait : 'Je suis le Creeper, attrapez-moi si vous pouvez !'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Un nuage moyen pÃ¨se environ 500 000 kg, soit l'Ã©quivalent d'un troupeau d'Ã©lÃ©phants flottant au-dessus de nos tÃªtes.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "L'ADN humain est identique Ã  50% Ã  celui d'une banane. Appeler une banane 'mon frÃ¨re' n'est donc pas si faux.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "La peau des ours polaires est noire et leur fourrure transparente. Ils paraissent blancs grÃ¢ce Ã  la rÃ©fraction de la lumiÃ¨re.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "On ne peut pas pleurer dans l'espace. Sans gravitÃ©, les larmes ne coulent pas, elles forment une bulle dans l'Å“il.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "L'Everest grandit d'environ 4 mm par an. La Terre change en permanence.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Les souris qui 'sifflent' chantent en rÃ©alitÃ©, mais Ã  une frÃ©quence inaudible pour l'homme.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "Les requins sont plus vieux que les arbres. Ils existent depuis 400 millions d'annÃ©es, contre 350 millions pour les arbres.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "Botaniquement, la banane est une baie, mais pas la fraise. La nature est Ã©trange.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Une fourmi peut soulever 50 fois son poids. Si vous Ã©tiez une fourmi, vous pourriez soulever une voiture.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "En Ã©tÃ©, la Tour Eiffel grandit d'environ 15 cm Ã  cause de la dilatation thermique du mÃ©tal.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Le poids total de tous les humains sur Terre Ã©quivaut Ã  peu prÃ¨s au poids total de toutes les fourmis.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "Les paresseux peuvent retenir leur respiration sous l'eau plus longtemps que les dauphins (environ 40 min).",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "Les pigeons distinguent les tableaux de Picasso de ceux de Monet. Ils sont plus artistes qu'on ne le pense.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Le GPS est gratuit, mais il coÃ»te environ 2 millions de dollars par jour au gouvernement amÃ©ricain pour fonctionner.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "L'ornithorynque n'a pas d'estomac ; la nourriture passe directement de l'Å“sophage aux intestins.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "C'est Shakespeare qui a utilisÃ© le mot 'swagger' (avoir du style) en premier. Il avait dÃ©jÃ  la classe au 16Ã¨me siÃ¨cle.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "Le cÅ“ur de la baleine bleue est si grand qu'un humain pourrait nager dans ses artÃ¨res.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "Les fourmis n'ont pas de poumons et ne dorment jamais vraiment. Ce sont de minuscules bourreaux de travail.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "Il pleut des diamants sur Saturne et Jupiter. On dirait qu'on vit sur la mauvaise planÃ¨te.",
    "Honeybees can recognize human faces and remember them individually.":
        "Les abeilles peuvent reconnaÃ®tre les visages humains et s'en souvenir.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "La sueur des hippopotames est rose et sert d'Ã©cran solaire et d'antibactÃ©rien.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "Les crottes du wombat sont cubiques pour ne pas rouler, ce qui aide Ã  marquer son territoire.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "La noix de cajou pousse Ã  l'extÃ©rieur du fruit, suspendue au bout. Un design naturel surprenant.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "Les requins sont plus vieux que les anneaux de Saturne. Ils Ã©taient lÃ  des millions d'annÃ©es avant eux.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "Les papillons goÃ»tent avec leurs pattes. Quand ils se posent sur une feuille, ils testent leur dÃ®ner.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Un escargot peut dormir trois ans sans se rÃ©veiller. Franchement, on dirait moi.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "Les yeux de l'autruche sont plus gros que son cerveau.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Les flamants naissent gris. Leur couleur rose vient des crevettes et des algues qu'ils mangent.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Les Ã©cureuils plantent des milliers d'arbres par an simplement en oubliant oÃ¹ ils ont cachÃ© leurs noisettes.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "Le premier jeu vidÃ©o jouÃ© dans l'espace fut Tetris, sur une Game Boy, par un cosmonaute en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "Le pic-vert enroule sa langue autour de son cerveau pour amortir les chocs. Une langue-casque, c'est fou.",
  },
  'it': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "I corvi non solo riconoscono i volti, ma ricordano chi li ha trattati male per anni e avvertono gli altri corvi.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "I gatti dormono per il 70% della loro vita. Un gatto di 10 anni Ã¨ stato sveglio solo per circa 3 anni.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Il miele non scade mai. Nelle piramidi egizie Ã¨ stato trovato miele di 3.000 anni fa ancora commestibile.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "Le lontre marine si tengono per mano mentre dormono per non essere separate dalla corrente.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "Su Venere un giorno dura piÃ¹ di un anno. Ruota su se stesso piÃ¹ lentamente di quanto giri intorno al Sole.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "L'accendino Ã¨ stato inventato prima del fiammifero. A volte la tecnologia 'vecchia' Ã¨ piÃ¹ antica di quanto pensiamo.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "I polpi hanno tre cuori e nove cervelli. Dimenticare le cose non Ã¨ un'opzione per loro.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "Le mucche hanno 'migliori amiche' e si stressano molto, arrivando a piangere, se vengono separate.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "Il primo virus informatico si chiamava 'Creeper' e mostrava il messaggio: 'Sono il Creeper, prendimi se ci riesci!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Una nuvola media pesa circa 500.000 kg, come un branco di elefanti che fluttua sopra di noi.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "Il DNA umano Ã¨ simile al 50% a quello di una banana. Chiamare una banana 'fratello' non Ã¨ poi cosÃ¬ sbagliato.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "La pelle degli orsi polari Ã¨ nera e il pelo trasparente. Sembrano bianchi per via del riflesso della luce.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "Nello spazio non si puÃ² piangere. Senza gravitÃ , le lacrime non scendono, ma formano una bolla nell'occhio.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "L'Everest cresce di circa 4 millimetri l'anno. La Terra Ã¨ in continuo cambiamento.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "I topi che 'fischiano' in realtÃ  cantano, ma a una frequenza troppo alta per l'orecchio umano.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "Gli squali sono piÃ¹ antichi degli alberi. Esistono da 400 milioni di anni, gli alberi solo da 350 milioni.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "Botanicamente la banana Ã¨ una bacca, ma la fragola no. La natura Ã¨ strana.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Una formica solleva 50 volte il suo peso. Se fossi una formica, potresti sollevare un'auto da solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "In estate la Torre Eiffel si alza di circa 15 cm a causa dell'espansione termica del metallo.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Il peso totale di tutti gli esseri umani sulla Terra Ã¨ quasi uguale a quello di tutte le formiche.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "I bradipi possono trattenere il respiro sott'acqua piÃ¹ a lungo dei delfini, fino a 40 minuti.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "I piccioni distinguono i quadri di Picasso da quelli di Monet. A quanto pare, ne sanno di arte.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Il GPS Ã¨ gratuito, ma il governo USA spende circa 2 milioni di dollari al giorno per mantenerlo attivo.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "L'ornitorinco non ha lo stomaco; il cibo passa direttamente dall'esofago all'intestino.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "Shakespeare fu il primo a usare la parola 'swagger' (spavalderia). Aveva stile giÃ  nel XVI secolo.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "Il cuore della balenottera azzurra Ã¨ cosÃ¬ grande che un uomo potrebbe nuotare nelle sue arterie.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "Le formiche non hanno polmoni e non dormono mai davvero. Sono piccole stacanoviste.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "Su Saturno e Giove piovono letteralmente diamanti. Viviamo sul pianeta sbagliato.",
    "Honeybees can recognize human faces and remember them individually.":
        "Le api possono riconoscere i volti umani e ricordarseli.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "Il sudore dell'ippopotamo Ã¨ rosa e funge da crema solare e antibatterico.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "La cacca del vombato Ã¨ cubica per non rotolare via e marcare meglio il territorio.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "Gli anacardi crescono all'esterno del frutto, appesi all'estremitÃ . Uno strano design della natura.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "Gli squali sono piÃ¹ vecchi degli anelli di Saturno. Esistevano milioni di anni prima degli anelli.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "Le farfalle sentono i sapori con le zampe. Quando si posano su una foglia, stanno assaggiando la cena.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Una lumaca puÃ² dormire per tre anni di fila. Onestamente, la capisco.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "Gli occhi dello struzzo sono piÃ¹ grandi del suo cervello.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "I fenicotteri nascono grigi. Il rosa deriva dai gamberetti e dalle alghe che mangiano.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Gli scoiattoli piantano migliaia di alberi ogni anno semplicemente dimenticando dove hanno nascosto le noci.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "Il primo videogioco nello spazio Ã¨ stato Tetris, giocato su un Game Boy da un cosmonauta nel 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "Il picchio avvolge la lingua attorno al cervello per proteggersi dai colpi. Usare la lingua come casco Ã¨ geniale.",
  },
  'vi': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "Quáº¡ khÃ´ng chá»‰ nhá»› máº·t ngÆ°á»i, mÃ  cÃ²n thÃ¹ dai nhá»¯ng ai Ä‘á»‘i xá»­ tá»‡ vá»›i chÃºng vÃ  cáº£nh bÃ¡o cáº£ Ä‘Ã n quáº¡ khÃ¡c.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "MÃ¨o dÃ nh 70% cuá»™c Ä‘á»i Ä‘á»ƒ ngá»§. Váº­y nÃªn má»™t con mÃ¨o 10 tuá»•i thá»±c ra má»›i thá»©c Ä‘Æ°á»£c cÃ³ 3 nÄƒm.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Máº­t ong khÃ´ng bao giá» há»ng. CÃ¡c nhÃ  kháº£o cá»• tÃ¬m tháº¥y máº­t ong 3.000 nÄƒm tuá»•i trong Kim tá»± thÃ¡p váº«n Äƒn Ä‘Æ°á»£c.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "RÃ¡i cÃ¡ biá»ƒn náº¯m tay nhau khi ngá»§ Ä‘á»ƒ khÃ´ng bá»‹ dÃ²ng nÆ°á»›c cuá»‘n trÃ´i xa nhau.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "TrÃªn sao Kim, má»™t ngÃ y dÃ i hÆ¡n má»™t nÄƒm. NÃ³ tá»± quay quanh trá»¥c cÃ²n cháº­m hÆ¡n quay quanh Máº·t Trá»i.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "Báº­t lá»­a Ä‘Æ°á»£c phÃ¡t minh trÆ°á»›c diÃªm. ÄÃ´i khi cÃ´ng nghá»‡ 'cÅ©' láº¡i má»›i hÆ¡n ta tÆ°á»Ÿng.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "Báº¡ch tuá»™c cÃ³ 3 trÃ¡i tim vÃ  9 bá»™ nÃ£o. Tháº¿ nÃªn 'quÃªn' khÃ´ng pháº£i lÃ  lá»±a chá»n cá»§a chÃºng.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "BÃ² cÅ©ng cÃ³ 'báº¡n thÃ¢n'. ChÃºng sáº½ bá»‹ stress náº·ng, tháº­m chÃ­ khÃ³c náº¿u bá»‹ tÃ¡ch khá»i báº¡n mÃ¬nh.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "Virus mÃ¡y tÃ­nh Ä‘áº§u tiÃªn tÃªn lÃ  'Creeper', vá»›i thÃ´ng Ä‘iá»‡p: 'Ta lÃ  Creeper, báº¯t ta náº¿u cÃ³ thá»ƒ!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "Má»™t Ä‘Ã¡m mÃ¢y trung bÃ¬nh náº·ng khoáº£ng 500.000 kg â€“ tÆ°Æ¡ng Ä‘Æ°Æ¡ng má»™t Ä‘Ã n voi khá»•ng lá»“ bay trÃªn Ä‘áº§u báº¡n.",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "DNA cá»§a ngÆ°á»i giá»‘ng chuá»‘i Ä‘áº¿n 50%. NÃªn gá»i quáº£ chuá»‘i lÃ  'ngÆ°á»i anh em' cÅ©ng khÃ´ng sai láº¯m.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Da gáº¥u Báº¯c Cá»±c thá»±c ra mÃ u Ä‘en, cÃ²n lÃ´ng thÃ¬ trong suá»‘t. ChÃºng trÃ´ng tráº¯ng lÃ  do pháº£n xáº¡ Ã¡nh sÃ¡ng.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "Báº¡n khÃ´ng thá»ƒ khÃ³c trong vÅ© trá»¥. KhÃ´ng cÃ³ trá»ng lá»±c, nÆ°á»›c máº¯t khÃ´ng cháº£y xuá»‘ng mÃ  tá»¥ thÃ nh giá»t ngay trong máº¯t.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "Äá»‰nh Everest cao thÃªm khoáº£ng 4mm má»—i nÄƒm. TrÃ¡i Ä‘áº¥t váº«n Ä‘ang thay Ä‘á»•i.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Chuá»™t 'huÃ½t sÃ¡o' thá»±c ra lÃ  Ä‘ang hÃ¡t cho nhau nghe, nhÆ°ng á»Ÿ táº§n sá»‘ quÃ¡ cao Ä‘á»ƒ ngÆ°á»i nghe tháº¥y.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "CÃ¡ máº­p giÃ  hÆ¡n cáº£ cÃ¢y cá»‘i. CÃ¡ máº­p cÃ³ tá»« 400 triá»‡u nÄƒm trÆ°á»›c, cÃ¢y cá»‘i má»›i 350 triá»‡u nÄƒm.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "Vá» máº·t thá»±c váº­t há»c, chuá»‘i lÃ  quáº£ má»ng, cÃ²n dÃ¢u tÃ¢y thÃ¬ khÃ´ng. Tá»± nhiÃªn tháº­t ká»³ láº¡.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "Kiáº¿n cÃ³ thá»ƒ nÃ¢ng váº­t náº·ng gáº¥p 50 láº§n cÆ¡ thá»ƒ. Náº¿u báº¡n lÃ  kiáº¿n, báº¡n cÃ³ thá»ƒ tá»± nÃ¢ng má»™t chiáº¿c Ã´ tÃ´.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "ThÃ¡p Eiffel cao thÃªm khoáº£ng 15cm vÃ o mÃ¹a hÃ¨ do kim loáº¡i giÃ£n ná»Ÿ vÃ¬ nhiá»‡t.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Tá»•ng trá»ng lÆ°á»£ng cá»§a táº¥t cáº£ con ngÆ°á»i trÃªn TrÃ¡i Ä‘áº¥t xáº¥p xá»‰ tá»•ng trá»ng lÆ°á»£ng cá»§a loÃ i kiáº¿n.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "Con lÆ°á»i cÃ³ thá»ƒ nÃ­n thá»Ÿ dÆ°á»›i nÆ°á»›c lÃ¢u hÆ¡n cÃ¡ heo â€“ lÃªn tá»›i 40 phÃºt.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "Bá»“ cÃ¢u cÃ³ thá»ƒ phÃ¢n biá»‡t tranh cá»§a Picasso vÃ  Monet. HÃ³a ra chÃºng cÃ³ gu nghá»‡ thuáº­t hÆ¡n ta tÆ°á»Ÿng.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "DÃ¹ng GPS thÃ¬ miá»…n phÃ­, nhÆ°ng chÃ­nh phá»§ Má»¹ tá»‘n khoáº£ng 2 triá»‡u Ä‘Ã´ má»—i ngÃ y Ä‘á»ƒ váº­n hÃ nh nÃ³.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "ThÃº má» vá»‹t khÃ´ng cÃ³ dáº¡ dÃ y; thá»©c Äƒn Ä‘i tháº³ng tá»« thá»±c quáº£n xuá»‘ng ruá»™t.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "Shakespeare lÃ  ngÆ°á»i Ä‘áº§u tiÃªn dÃ¹ng tá»« 'swagger' (phong cÃ¡ch/ngáº§u). Ã”ng Ä‘Ã£ ráº¥t cháº¥t tá»« tháº¿ ká»· 16.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "Tim cÃ¡ voi xanh lá»›n Ä‘áº¿n má»©c con ngÆ°á»i cÃ³ thá»ƒ bÆ¡i trong Ä‘á»™ng máº¡ch cá»§a nÃ³.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "Kiáº¿n khÃ´ng cÃ³ phá»•i vÃ  khÃ´ng bao giá» thá»±c sá»± ngá»§. ChÃºng lÃ  nhá»¯ng káº» cuá»“ng cÃ´ng viá»‡c tÃ­ hon.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "TrÃªn sao Thá»• vÃ  sao Má»™c cÃ³ mÆ°a kim cÆ°Æ¡ng. CÃ³ váº» chÃºng ta Ä‘ang sá»‘ng sai hÃ nh tinh rá»“i.",
    "Honeybees can recognize human faces and remember them individually.":
        "Ong máº­t cÃ³ thá»ƒ nháº­n diá»‡n vÃ  ghi nhá»› khuÃ´n máº·t tá»«ng ngÆ°á»i.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "Má»“ hÃ´i hÃ  mÃ£ mÃ u há»“ng, cÃ³ tÃ¡c dá»¥ng nhÆ° kem chá»‘ng náº¯ng vÃ  cháº¥t khÃ¡ng khuáº©n.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "PhÃ¢n cá»§a gáº¥u tÃºi mÅ©i tráº§n (Wombat) hÃ¬nh khá»‘i vuÃ´ng Ä‘á»ƒ khÃ´ng bá»‹ lÄƒn Ä‘i, giÃºp Ä‘Ã¡nh dáº¥u lÃ£nh thá»• tá»‘t hÆ¡n.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "Háº¡t Ä‘iá»u má»c bÃªn ngoÃ i quáº£, treo lá»§ng láº³ng á»Ÿ dÆ°á»›i Ä‘Ã¡y. Má»™t thiáº¿t káº¿ ká»³ láº¡ cá»§a tá»± nhiÃªn.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "CÃ¡ máº­p cÃ²n giÃ  hÆ¡n cáº£ vÃ nh Ä‘ai sao Thá»•. ChÃºng Ä‘Ã£ á»Ÿ Ä‘Ã¢y hÃ ng triá»‡u nÄƒm trÆ°á»›c khi sao Thá»• cÃ³ vÃ²ng Ä‘eo.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "BÆ°á»›m náº¿m mÃ¹i vá»‹ báº±ng chÃ¢n. Khi Ä‘áº­u lÃªn lÃ¡, thá»±c ra chÃºng Ä‘ang náº¿m thá»­ bá»¯a tá»‘i.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "á»c sÃªn cÃ³ thá»ƒ ngá»§ liá»n 3 nÄƒm khÃ´ng dáº­y. Tháº­t sá»± lÃ  Æ°á»›c mÆ¡ cá»§a tÃ´i.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "Máº¯t Ä‘Ã  Ä‘iá»ƒu cÃ²n to hÆ¡n cáº£ nÃ£o cá»§a nÃ³.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Há»“ng háº¡c sinh ra cÃ³ mÃ u xÃ¡m. MÃ u há»“ng lÃ  do tÃ´m vÃ  táº£o chÃºng Äƒn.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "SÃ³c trá»“ng hÃ ng nghÃ¬n cÃ¢y má»—i nÄƒm chá»‰ vÃ¬ chÃºng quÃªn máº¥t chá»— chÃ´n háº¡t dáº».",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "TrÃ² chÆ¡i Ä‘iá»‡n tá»­ Ä‘áº§u tiÃªn trong vÅ© trá»¥ lÃ  Tetris, Ä‘Æ°á»£c má»™t phi hÃ nh gia chÆ¡i trÃªn Game Boy nÄƒm 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "Chim gÃµ kiáº¿n quáº¥n lÆ°á»¡i quanh nÃ£o Ä‘á»ƒ giáº£m cháº¥n Ä‘á»™ng. DÃ¹ng lÆ°á»¡i lÃ m mÅ© báº£o hiá»ƒm, tháº­t Ä‘iÃªn rá»“.",
  },
  'th': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "à¸­à¸µà¸à¸²à¹„à¸¡à¹ˆà¹à¸„à¹ˆà¸ˆà¸³à¸«à¸™à¹‰à¸²à¸„à¸™à¹„à¸”à¹‰ à¹à¸•à¹ˆà¸¢à¸±à¸‡à¸ˆà¸³à¸„à¸™à¸—à¸µà¹ˆà¸—à¸³à¸£à¹‰à¸²à¸¢à¸¡à¸±à¸™à¹„à¸”à¹‰à¹€à¸›à¹‡à¸™à¸›à¸µà¹† à¹à¸–à¸¡à¸¢à¸±à¸‡à¹„à¸›à¹€à¸•à¸·à¸­à¸™à¸­à¸µà¸à¸²à¸•à¸±à¸§à¸­à¸·à¹ˆà¸™à¹„à¸”à¹‰à¸”à¹‰à¸§à¸¢",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "à¹à¸¡à¸§à¹ƒà¸Šà¹‰à¹€à¸§à¸¥à¸² 70% à¸‚à¸­à¸‡à¸Šà¸µà¸§à¸´à¸•à¹„à¸›à¸à¸±à¸šà¸à¸²à¸£à¸™à¸­à¸™ à¸”à¸±à¸‡à¸™à¸±à¹‰à¸™à¹à¸¡à¸§à¸­à¸²à¸¢à¸¸ 10 à¸›à¸µ à¸ˆà¸£à¸´à¸‡à¹† à¹à¸¥à¹‰à¸§à¸•à¸·à¹ˆà¸™à¸¡à¸²à¹à¸„à¹ˆ 3 à¸›à¸µà¹€à¸­à¸‡",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "à¸™à¹‰à¸³à¸œà¸¶à¹‰à¸‡à¹„à¸¡à¹ˆà¸¡à¸µà¸§à¸±à¸™à¹€à¸ªà¸µà¸¢ à¸™à¸±à¸à¹‚à¸šà¸£à¸²à¸“à¸„à¸”à¸µà¹€à¸„à¸¢à¹€à¸ˆà¸­à¸™à¹‰à¸³à¸œà¸¶à¹‰à¸‡à¸­à¸²à¸¢à¸¸ 3,000 à¸›à¸µà¹ƒà¸™à¸à¸µà¸£à¸°à¸¡à¸´à¸”à¸—à¸µà¹ˆà¸¢à¸±à¸‡à¸à¸´à¸™à¹„à¸”à¹‰à¸­à¸¢à¸¹à¹ˆà¹€à¸¥à¸¢",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "à¸™à¸²à¸à¸—à¸°à¹€à¸¥à¸ˆà¸°à¸ˆà¸±à¸šà¸¡à¸·à¸­à¸à¸±à¸™à¸•à¸­à¸™à¸™à¸­à¸™ à¹€à¸à¸·à¹ˆà¸­à¹„à¸¡à¹ˆà¹ƒà¸«à¹‰à¸à¸£à¸°à¹à¸ªà¸™à¹‰à¸³à¸à¸±à¸”à¸à¸§à¸à¸¡à¸±à¸™à¹à¸¢à¸à¸ˆà¸²à¸à¸à¸±à¸™",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "à¸šà¸™à¸”à¸²à¸§à¸¨à¸¸à¸à¸£à¹Œ 1 à¸§à¸±à¸™à¸¢à¸²à¸§à¸™à¸²à¸™à¸à¸§à¹ˆà¸² 1 à¸›à¸µ à¹€à¸à¸£à¸²à¸°à¸¡à¸±à¸™à¸«à¸¡à¸¸à¸™à¸£à¸­à¸šà¸•à¸±à¸§à¹€à¸­à¸‡à¸Šà¹‰à¸²à¸à¸§à¹ˆà¸²à¸«à¸¡à¸¸à¸™à¸£à¸­à¸šà¸”à¸§à¸‡à¸­à¸²à¸—à¸´à¸•à¸¢à¹Œ",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "à¹„à¸Ÿà¹à¸Šà¹‡à¸à¸–à¸¹à¸à¸›à¸£à¸°à¸”à¸´à¸©à¸à¹Œà¸‚à¸¶à¹‰à¸™à¸à¹ˆà¸­à¸™à¹„à¸¡à¹‰à¸‚à¸µà¸”à¹„à¸Ÿ à¸šà¸²à¸‡à¸—à¸µà¹€à¸—à¸„à¹‚à¸™à¹‚à¸¥à¸¢à¸µ 'à¸ªà¸¡à¸±à¸¢à¹ƒà¸«à¸¡à¹ˆ' à¸à¹‡à¹€à¸à¹ˆà¸²à¹à¸à¹ˆà¸à¸§à¹ˆà¸²à¸—à¸µà¹ˆà¹€à¸£à¸²à¸„à¸´à¸”",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "à¸›à¸¥à¸²à¸«à¸¡à¸¶à¸à¸¢à¸±à¸à¸©à¹Œà¸¡à¸µ 3 à¸«à¸±à¸§à¹ƒà¸ˆà¹à¸¥à¸° 9 à¸ªà¸¡à¸­à¸‡ à¹€à¸£à¸·à¹ˆà¸­à¸‡à¸‚à¸µà¹‰à¸¥à¸·à¸¡à¸„à¸‡à¹„à¸¡à¹ˆà¹ƒà¸Šà¹ˆà¸›à¸±à¸à¸«à¸²à¸‚à¸­à¸‡à¸à¸§à¸à¸¡à¸±à¸™",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "à¸§à¸±à¸§à¸à¹‡à¸¡à¸µ 'à¹€à¸à¸·à¹ˆà¸­à¸™à¸ªà¸™à¸´à¸—' à¸™à¸° à¸–à¹‰à¸²à¸–à¸¹à¸à¸ˆà¸±à¸šà¹à¸¢à¸à¸à¸±à¸™à¸à¸§à¸à¸¡à¸±à¸™à¸ˆà¸°à¹€à¸„à¸£à¸µà¸¢à¸”à¸«à¸™à¸±à¸à¸¡à¸²à¸à¸ˆà¸™à¸£à¹‰à¸­à¸‡à¹„à¸«à¹‰à¹„à¸”à¹‰à¹€à¸¥à¸¢",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "à¹„à¸§à¸£à¸±à¸ªà¸„à¸­à¸¡à¸à¸´à¸§à¹€à¸•à¸­à¸£à¹Œà¸•à¸±à¸§à¹à¸£à¸à¸Šà¸·à¹ˆà¸­ 'Creeper' à¸¡à¸±à¸™à¸‚à¸¶à¹‰à¸™à¸‚à¹‰à¸­à¸„à¸§à¸²à¸¡à¸§à¹ˆà¸²: 'à¸‰à¸±à¸™à¸„à¸·à¸­ Creeper à¸ˆà¸±à¸šà¸‰à¸±à¸™à¹ƒà¸«à¹‰à¹„à¸”à¹‰à¸ªà¸´à¸–à¹‰à¸²à¸—à¸³à¹„à¸”à¹‰!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "à¹€à¸¡à¸†à¸à¹‰à¸­à¸™à¸«à¸™à¸¶à¹ˆà¸‡à¸­à¸²à¸ˆà¸«à¸™à¸±à¸à¸–à¸¶à¸‡ 500,000 à¸à¸´à¹‚à¸¥à¸à¸£à¸±à¸¡ à¹€à¸«à¸¡à¸·à¸­à¸™à¸¡à¸µà¸à¸¹à¸‡à¸Šà¹‰à¸²à¸‡à¸¥à¸­à¸¢à¸­à¸¢à¸¹à¹ˆà¸šà¸™à¸«à¸±à¸§à¹€à¸£à¸²",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "DNA à¸„à¸™à¹€à¸£à¸²à¹€à¸«à¸¡à¸·à¸­à¸™à¸à¸¥à¹‰à¸§à¸¢à¸–à¸¶à¸‡ 50% à¸”à¸±à¸‡à¸™à¸±à¹‰à¸™à¸–à¹‰à¸²à¸ˆà¸°à¹€à¸£à¸µà¸¢à¸à¸à¸¥à¹‰à¸§à¸¢à¸§à¹ˆà¸² 'à¸à¸µà¹ˆà¸™à¹‰à¸­à¸‡' à¸à¹‡à¸„à¸‡à¹„à¸¡à¹ˆà¸œà¸´à¸”à¸™à¸±à¸",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "à¸ˆà¸£à¸´à¸‡à¹† à¹à¸¥à¹‰à¸§à¸«à¸¡à¸µà¸‚à¸±à¹‰à¸§à¹‚à¸¥à¸à¸œà¸´à¸§à¸ªà¸µà¸”à¸³ à¸‚à¸™à¹ƒà¸ª à¹à¸•à¹ˆà¸—à¸µà¹ˆà¹€à¸«à¹‡à¸™à¹€à¸›à¹‡à¸™à¸ªà¸µà¸‚à¸²à¸§à¹€à¸à¸£à¸²à¸°à¸à¸²à¸£à¸ªà¸°à¸—à¹‰à¸­à¸™à¹à¸ªà¸‡",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "à¸„à¸¸à¸“à¸£à¹‰à¸­à¸‡à¹„à¸«à¹‰à¹ƒà¸™à¸­à¸§à¸à¸²à¸¨à¹„à¸¡à¹ˆà¹„à¸”à¹‰ à¹€à¸à¸£à¸²à¸°à¹„à¸¡à¹ˆà¸¡à¸µà¹à¸£à¸‡à¹‚à¸™à¹‰à¸¡à¸–à¹ˆà¸§à¸‡ à¸™à¹‰à¸³à¸•à¸²à¸ˆà¸°à¹„à¸¡à¹ˆà¹„à¸«à¸¥à¸¥à¸‡à¸¡à¸²à¹à¸•à¹ˆà¸ˆà¸°à¹€à¸à¸²à¸°à¹€à¸›à¹‡à¸™à¸à¹‰à¸­à¸™à¸—à¸µà¹ˆà¸•à¸²",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "à¸¢à¸­à¸”à¹€à¸‚à¸²à¹€à¸­à¹€à¸§à¸­à¹€à¸£à¸ªà¸•à¹Œà¸ªà¸¹à¸‡à¸‚à¸¶à¹‰à¸™à¸›à¸µà¸¥à¸° 4 à¸¡à¸´à¸¥à¸¥à¸´à¹€à¸¡à¸•à¸£ à¹‚à¸¥à¸à¹€à¸£à¸²à¸¢à¸±à¸‡à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¹à¸›à¸¥à¸‡à¸­à¸¢à¸¹à¹ˆà¸•à¸¥à¸­à¸”",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "à¸«à¸™à¸¹à¸—à¸µà¹ˆ 'à¸œà¸´à¸§à¸›à¸²à¸' à¸ˆà¸£à¸´à¸‡à¹† à¹à¸¥à¹‰à¸§à¸à¸³à¸¥à¸±à¸‡à¸£à¹‰à¸­à¸‡à¹€à¸à¸¥à¸‡à¸ˆà¸µà¸šà¸à¸±à¸™ à¹à¸•à¹ˆà¹€à¸ªà¸µà¸¢à¸‡à¸ªà¸¹à¸‡à¹€à¸à¸´à¸™à¸à¸§à¹ˆà¸²à¸«à¸¹à¸„à¸™à¸ˆà¸°à¹„à¸”à¹‰à¸¢à¸´à¸™",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "à¸‰à¸¥à¸²à¸¡à¹€à¸à¸´à¸”à¸à¹ˆà¸­à¸™à¸•à¹‰à¸™à¹„à¸¡à¹‰à¹€à¸ªà¸µà¸¢à¸­à¸µà¸ à¸‰à¸¥à¸²à¸¡à¸¡à¸µà¸¡à¸² 400 à¸¥à¹‰à¸²à¸™à¸›à¸µ à¸ªà¹ˆà¸§à¸™à¸•à¹‰à¸™à¹„à¸¡à¹‰à¹€à¸à¸´à¹ˆà¸‡à¸¡à¸µà¸¡à¸² 350 à¸¥à¹‰à¸²à¸™à¸›à¸µ",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "à¸•à¸²à¸¡à¸«à¸¥à¸±à¸à¸à¸¤à¸à¸©à¸¨à¸²à¸ªà¸•à¸£à¹Œ à¸à¸¥à¹‰à¸§à¸¢à¸„à¸·à¸­à¹€à¸šà¸­à¸£à¹Œà¸£à¸µà¹ˆ à¹à¸•à¹ˆà¸ªà¸•à¸£à¸­à¸§à¹Œà¹€à¸šà¸­à¸£à¹Œà¸£à¸µà¹ˆà¹„à¸¡à¹ˆà¹ƒà¸Šà¹ˆ à¹‚à¸¥à¸à¸à¸·à¸Šà¸¡à¸±à¸™à¸‹à¸±à¸šà¸‹à¹‰à¸­à¸™à¸™à¸°",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "à¸¡à¸”à¹à¸šà¸à¸‚à¸­à¸‡à¸«à¸™à¸±à¸à¸à¸§à¹ˆà¸²à¸•à¸±à¸§à¸¡à¸±à¸™à¹„à¸”à¹‰ 50 à¹€à¸—à¹ˆà¸² à¸–à¹‰à¸²à¸„à¸¸à¸“à¹€à¸›à¹‡à¸™à¸¡à¸” à¸„à¸¸à¸“à¸„à¸‡à¸¢à¸à¸£à¸–à¸—à¸±à¹‰à¸‡à¸„à¸±à¸™à¹„à¸”à¹‰à¸ªà¸šà¸²à¸¢à¹†",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "à¸«à¸­à¹„à¸­à¹€à¸Ÿà¸¥à¸ˆà¸°à¸ªà¸¹à¸‡à¸‚à¸¶à¹‰à¸™ 15 à¸‹à¸¡. à¹ƒà¸™à¸«à¸™à¹‰à¸²à¸£à¹‰à¸­à¸™ à¹€à¸à¸£à¸²à¸°à¹€à¸«à¸¥à¹‡à¸à¸‚à¸¢à¸²à¸¢à¸•à¸±à¸§à¸ˆà¸²à¸à¸„à¸§à¸²à¸¡à¸£à¹‰à¸­à¸™",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "à¸™à¹‰à¸³à¸«à¸™à¸±à¸à¸£à¸§à¸¡à¸‚à¸­à¸‡à¸„à¸™à¸—à¸±à¹‰à¸‡à¹‚à¸¥à¸ à¸à¸­à¹† à¸à¸±à¸šà¸™à¹‰à¸³à¸«à¸™à¸±à¸à¸£à¸§à¸¡à¸‚à¸­à¸‡à¸¡à¸”à¸—à¸±à¹‰à¸‡à¹‚à¸¥à¸à¹€à¸¥à¸¢à¸—à¸µà¹€à¸”à¸µà¸¢à¸§",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "à¸ªà¸¥à¸­à¸˜à¸à¸¥à¸±à¹‰à¸™à¸«à¸²à¸¢à¹ƒà¸ˆà¹ƒà¸™à¸™à¹‰à¸³à¹„à¸”à¹‰à¸™à¸²à¸™à¸à¸§à¹ˆà¸²à¹‚à¸¥à¸¡à¸²à¸­à¸µà¸ (à¹„à¸”à¹‰à¸–à¸¶à¸‡ 40 à¸™à¸²à¸—à¸µà¹€à¸¥à¸¢à¸™à¸°)",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "à¸™à¸à¸à¸´à¸£à¸²à¸šà¹à¸¢à¸à¸ à¸²à¸à¸§à¸²à¸”à¸‚à¸­à¸‡à¸›à¸´à¸à¸±à¸ªà¹‚à¸‹à¸à¸±à¸šà¹‚à¸¡à¹€à¸™à¸•à¹Œà¹„à¸”à¹‰ à¸à¸§à¸à¸¡à¸±à¸™à¸¡à¸µà¸«à¸±à¸§à¸¨à¸´à¸¥à¸›à¸°à¸à¸§à¹ˆà¸²à¸—à¸µà¹ˆà¹€à¸£à¸²à¸„à¸´à¸”",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS à¹ƒà¸Šà¹‰à¸Ÿà¸£à¸µà¸—à¸±à¹ˆà¸§à¹‚à¸¥à¸ à¹à¸•à¹ˆà¸£à¸±à¸à¸šà¸²à¸¥à¸ªà¸«à¸£à¸±à¸à¸¯ à¸ˆà¹ˆà¸²à¸¢à¸§à¸±à¸™à¸¥à¸° 2 à¸¥à¹‰à¸²à¸™à¸”à¸­à¸¥à¸¥à¸²à¸£à¹Œà¹€à¸à¸·à¹ˆà¸­à¸”à¸¹à¹à¸¥à¸£à¸°à¸šà¸šà¸™à¸µà¹‰",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "à¸•à¸¸à¹ˆà¸™à¸›à¸²à¸à¹€à¸›à¹‡à¸”à¹„à¸¡à¹ˆà¸¡à¸µà¸à¸£à¸°à¹€à¸à¸²à¸° à¸­à¸²à¸«à¸²à¸£à¸ˆà¸°à¹„à¸«à¸¥à¸ˆà¸²à¸à¸«à¸¥à¸­à¸”à¸­à¸²à¸«à¸²à¸£à¸¥à¸‡à¸¥à¸³à¹„à¸ªà¹‰à¹€à¸¥à¸¢",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "à¹€à¸Šà¸à¸ªà¹€à¸›à¸µà¸¢à¸£à¹Œà¹€à¸›à¹‡à¸™à¸„à¸™à¹à¸£à¸à¸—à¸µà¹ˆà¹ƒà¸Šà¹‰à¸„à¸³à¸§à¹ˆà¸² 'swagger' (à¹€à¸—à¹ˆ/à¸à¸£à¹ˆà¸²à¸‡) à¸•à¸±à¹‰à¸‡à¹à¸•à¹ˆà¸¨à¸•à¸§à¸£à¸£à¸©à¸—à¸µà¹ˆ 16 à¸à¸µà¹ˆà¹à¸à¸¡à¸µà¸ªà¹„à¸•à¸¥à¹Œà¸ˆà¸£à¸´à¸‡à¹†",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "à¸«à¸±à¸§à¹ƒà¸ˆà¸§à¸²à¸¬à¸ªà¸µà¸™à¹‰à¸³à¹€à¸‡à¸´à¸™à¹ƒà¸«à¸à¹ˆà¸¡à¸²à¸ à¸ˆà¸™à¸„à¸™à¸ªà¸²à¸¡à¸²à¸£à¸–à¸§à¹ˆà¸²à¸¢à¹€à¸‚à¹‰à¸²à¹„à¸›à¹ƒà¸™à¹€à¸ªà¹‰à¸™à¹€à¸¥à¸·à¸­à¸”à¹à¸”à¸‡à¹ƒà¸«à¸à¹ˆà¹„à¸”à¹‰à¹€à¸¥à¸¢",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "à¸¡à¸”à¹„à¸¡à¹ˆà¸¡à¸µà¸›à¸­à¸”à¹à¸¥à¸°à¹„à¸¡à¹ˆà¹€à¸„à¸¢à¸«à¸¥à¸±à¸šà¸ˆà¸£à¸´à¸‡à¹† à¸à¸§à¸à¸¡à¸±à¸™à¸„à¸·à¸­à¸¢à¸­à¸”à¸¡à¸™à¸¸à¸©à¸¢à¹Œà¸šà¹‰à¸²à¸‡à¸²à¸™",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "à¸šà¸™à¸”à¸²à¸§à¹€à¸ªà¸²à¸£à¹Œà¹à¸¥à¸°à¸à¸¤à¸«à¸±à¸ªà¸šà¸”à¸µà¸¡à¸µà¸à¸™à¸•à¸à¹€à¸›à¹‡à¸™à¹€à¸à¸Šà¸£ à¸ªà¸‡à¸ªà¸±à¸¢à¹€à¸£à¸²à¸ˆà¸°à¸­à¸¢à¸¹à¹ˆà¸œà¸´à¸”à¸”à¸²à¸§à¸à¸±à¸™à¹à¸¥à¹‰à¸§",
    "Honeybees can recognize human faces and remember them individually.":
        "à¸œà¸¶à¹‰à¸‡à¸ªà¸²à¸¡à¸²à¸£à¸–à¸ˆà¸³à¸«à¸™à¹‰à¸²à¸„à¸™à¹à¸¥à¸°à¹à¸¢à¸à¹à¸¢à¸°à¹à¸•à¹ˆà¸¥à¸°à¸„à¸™à¹„à¸”à¹‰",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "à¹€à¸«à¸‡à¸·à¹ˆà¸­à¸®à¸´à¸›à¹‚à¸›à¹€à¸›à¹‡à¸™à¸ªà¸µà¸Šà¸¡à¸à¸¹ à¸Šà¹ˆà¸§à¸¢à¸à¸±à¸™à¹à¸”à¸”à¹à¸¥à¸°à¸†à¹ˆà¸²à¹€à¸Šà¸·à¹‰à¸­à¹‚à¸£à¸„à¹„à¸”à¹‰à¸”à¹‰à¸§à¸¢",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "à¸­à¸¶à¸‚à¸­à¸‡à¸§à¸­à¸¡à¹à¸šà¸•à¹€à¸›à¹‡à¸™à¸—à¸£à¸‡à¸ªà¸µà¹ˆà¹€à¸«à¸¥à¸µà¹ˆà¸¢à¸¡à¸¥à¸¹à¸à¸šà¸²à¸¨à¸à¹Œ à¹€à¸à¸·à¹ˆà¸­à¹„à¸¡à¹ˆà¹ƒà¸«à¹‰à¸à¸¥à¸´à¹‰à¸‡à¸«à¸™à¸µà¹à¸¥à¸°à¹ƒà¸Šà¹‰à¸šà¸­à¸à¸­à¸²à¸“à¸²à¹€à¸‚à¸•à¹„à¸”à¹‰",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "à¹€à¸¡à¹‡à¸”à¸¡à¸°à¸¡à¹ˆà¸§à¸‡à¸«à¸´à¸¡à¸à¸²à¸™à¸•à¹Œà¸‡à¸­à¸à¸­à¸¢à¸¹à¹ˆà¸™à¸­à¸à¸œà¸¥ à¸«à¹‰à¸­à¸¢à¸•à¹ˆà¸­à¸‡à¹à¸•à¹ˆà¸‡à¸­à¸¢à¸¹à¹ˆà¸‚à¹‰à¸²à¸‡à¸¥à¹ˆà¸²à¸‡ à¹€à¸›à¹‡à¸™à¸”à¸µà¹„à¸‹à¸™à¹Œà¸—à¸µà¹ˆà¹à¸›à¸¥à¸à¸”à¸µà¸™à¸°",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "à¸‰à¸¥à¸²à¸¡à¹à¸à¹ˆà¸à¸§à¹ˆà¸²à¸§à¸‡à¹à¸«à¸§à¸™à¸”à¸²à¸§à¹€à¸ªà¸²à¸£à¹Œà¹€à¸ªà¸µà¸¢à¸­à¸µà¸ à¸à¸§à¸à¸¡à¸±à¸™à¸­à¸¢à¸¹à¹ˆà¸¡à¸²à¸à¹ˆà¸­à¸™à¸§à¸‡à¹à¸«à¸§à¸™à¸ˆà¸°à¹€à¸à¸´à¸”à¸«à¸¥à¸²à¸¢à¸¥à¹‰à¸²à¸™à¸›à¸µ",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "à¸œà¸µà¹€à¸ªà¸·à¹‰à¸­à¹ƒà¸Šà¹‰à¸‚à¸²à¸Šà¸´à¸¡à¸£à¸ªà¸Šà¸²à¸•à¸´ à¹€à¸§à¸¥à¸²à¹€à¸à¸²à¸°à¹ƒà¸šà¹„à¸¡à¹‰à¸„à¸·à¸­à¸à¸§à¸à¸¡à¸±à¸™à¸à¸³à¸¥à¸±à¸‡à¸Šà¸´à¸¡à¸­à¸²à¸«à¸²à¸£à¹€à¸¢à¹‡à¸™à¸­à¸¢à¸¹à¹ˆ",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "à¸«à¸­à¸¢à¸—à¸²à¸à¸ªà¸²à¸¡à¸²à¸£à¸–à¸«à¸¥à¸±à¸šà¸¢à¸²à¸§ 3 à¸›à¸µà¹‚à¸”à¸¢à¹„à¸¡à¹ˆà¸•à¸·à¹ˆà¸™à¹€à¸¥à¸¢ à¸­à¸¢à¸²à¸à¸—à¸³à¹„à¸”à¹‰à¸šà¹‰à¸²à¸‡à¸ˆà¸±à¸‡",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "à¸•à¸²à¸‚à¸­à¸‡à¸™à¸à¸à¸£à¸°à¸ˆà¸­à¸à¹€à¸—à¸¨à¹ƒà¸«à¸à¹ˆà¸à¸§à¹ˆà¸²à¸ªà¸¡à¸­à¸‡à¸‚à¸­à¸‡à¸¡à¸±à¸™à¸‹à¸°à¸­à¸µà¸",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "à¸Ÿà¸¥à¸²à¸¡à¸´à¸‡à¹‚à¸à¹‰à¹€à¸à¸´à¸”à¸¡à¸²à¸•à¸±à¸§à¸ªà¸µà¹€à¸—à¸² à¸ªà¸µà¸Šà¸¡à¸à¸¹à¹„à¸”à¹‰à¸¡à¸²à¸ˆà¸²à¸à¸à¸²à¸£à¸à¸´à¸™à¸à¸¸à¹‰à¸‡à¹à¸¥à¸°à¸ªà¸²à¸«à¸£à¹ˆà¸²à¸¢",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "à¸à¸£à¸°à¸£à¸­à¸à¸Šà¹ˆà¸§à¸¢à¸›à¸¥à¸¹à¸à¸•à¹‰à¸™à¹„à¸¡à¹‰à¸›à¸µà¸¥à¸°à¸«à¸¥à¸²à¸¢à¸à¸±à¸™à¸•à¹‰à¸™ à¹€à¸à¸µà¸¢à¸‡à¹€à¸à¸£à¸²à¸°à¸à¸§à¸à¸¡à¸±à¸™à¸¥à¸·à¸¡à¸§à¹ˆà¸²à¹€à¸­à¸²à¸–à¸±à¹ˆà¸§à¹„à¸›à¸à¸±à¸‡à¹„à¸§à¹‰à¹„à¸«à¸™",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "à¹€à¸à¸¡à¹à¸£à¸à¸—à¸µà¹ˆà¹€à¸¥à¹ˆà¸™à¹ƒà¸™à¸­à¸§à¸à¸²à¸¨à¸„à¸·à¸­ Tetris à¸šà¸™à¹€à¸„à¸£à¸·à¹ˆà¸­à¸‡ Game Boy à¹€à¸¡à¸·à¹ˆà¸­à¸›à¸µ 1993",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "à¸™à¸à¸«à¸±à¸§à¸‚à¸§à¸²à¸™à¹€à¸­à¸²à¸¥à¸´à¹‰à¸™à¸à¸±à¸™à¸£à¸­à¸šà¸ªà¸¡à¸­à¸‡à¹€à¸à¸·à¹ˆà¸­à¸à¸±à¸™à¸à¸£à¸°à¹à¸—à¸ à¹ƒà¸Šà¹‰à¸¥à¸´à¹‰à¸™à¹€à¸›à¹‡à¸™à¸«à¸¡à¸§à¸à¸à¸±à¸™à¸™à¹‡à¸­à¸„à¹€à¸™à¸µà¹ˆà¸¢à¸™à¸° à¸ªà¸¸à¸”à¸¢à¸­à¸”à¹„à¸›à¹€à¸¥à¸¢",
  },
  'pl': {

    "Crows donâ€™t just recognize human faces; they can remember people who treated them badly for yearsâ€”and even warn other crows.":
        "Wrony nie tylko rozpoznajÄ… twarze, ale pamiÄ™tajÄ… tych, ktÃ³rzy je skrzywdzili, a nawet ostrzegajÄ… inne wrony.",
    "Cats spend about 70% of their lives asleepâ€”so a 10-year-old cat has been awake for only about 3 years.":
        "Koty przesypiajÄ… 70% Å¼ycia. 10-letni kot byÅ‚ wiÄ™c obudzony tylko przez okoÅ‚o 3 lata.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "MiÃ³d siÄ™ nie psuje. Archeolodzy znaleÅºli w piramidach jadalny miÃ³d sprzed 3000 lat.",
    "Sea otters hold hands while they sleep so they donâ€™t drift apart in the current.":
        "Wydry morskie trzymajÄ… siÄ™ za rÄ™ce podczas snu, Å¼eby prÄ…d ich nie rozdzieliÅ‚.",
    "On Venus, a day is longer than a yearâ€”it rotates on its axis more slowly than it orbits the Sun.":
        "Na Wenus dzieÅ„ trwa dÅ‚uÅ¼ej niÅ¼ rok. Planeta obraca siÄ™ wokÃ³Å‚ wÅ‚asnej osi wolniej niÅ¼ wokÃ³Å‚ SÅ‚oÅ„ca.",
    "The lighter was invented before the matchâ€”sometimes â€œoldâ€ tech is older than we think.":
        "ZapalniczkÄ™ wynaleziono przed zapaÅ‚kami. Czasem 'nowa' technologia jest starsza niÅ¼ myÅ›limy.",
    "Octopuses have three hearts and nine brainsâ€”forgetting things isnâ€™t really an option.":
        "OÅ›miornice majÄ… trzy serca i dziewiÄ™Ä‡ mÃ³zgÃ³w â€“ zapominanie raczej im nie grozi.",
    "Cows have â€œbest friends,â€ and they can get seriously stressedâ€”and even cryâ€”when separated.":
        "Krowy majÄ… 'najlepsze przyjaciÃ³Å‚ki' i bardzo siÄ™ stresujÄ…, a nawet pÅ‚aczÄ…, gdy siÄ™ je rozdzieli.",
    "The worldâ€™s first computer virus was called â€œCreeper,â€ and it displayed: â€œIâ€™m the creeper, catch me if you can!â€":
        "Pierwszy wirus komputerowy nazywaÅ‚ siÄ™ 'Creeper' i wyÅ›wietlaÅ‚ napis: 'Jestem Creeper, zÅ‚ap mnie, jeÅ›li potrafisz!'",
    "An average cloud can weigh around 500,000 kgâ€”like a massive herd of elephants floating overhead.":
        "PrzeciÄ™tna chmura waÅ¼y okoÅ‚o 500 000 kg â€“ to jak stado sÅ‚oni unoszÄ…ce siÄ™ nad gÅ‚owÄ….",
    "Human DNA is about 50% similar to banana DNAâ€”so calling a banana â€œmy siblingâ€ tomorrow morning isnâ€™t totally unfair.":
        "Ludzkie DNA jest w 50% zgodne z DNA banana. WiÄ™c nazwanie banana 'bratem' nie jest tak caÅ‚kiem bez sensu.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "NiedÅºwiedzie polarne majÄ… czarnÄ… skÃ³rÄ™ i przezroczyste futro. WyglÄ…dajÄ… na biaÅ‚e przez odbicie Å›wiatÅ‚a.",
    "You canâ€™t really cry in space: without gravity, tears donâ€™t run down your faceâ€”they form a blob in your eye.":
        "W kosmosie nie da siÄ™ pÅ‚akaÄ‡. Bez grawitacji Å‚zy nie spÅ‚ywajÄ…, tylko tworzÄ… kulÄ™ w oku.",
    "Mount Everest keeps growing by about 4 millimeters each yearâ€”Earth is still changing.":
        "Mount Everest roÅ›nie o ok. 4 mm rocznie. Ziemia wciÄ…Å¼ siÄ™ zmienia.",
    "â€œWhistlingâ€ mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Myszy, ktÃ³re 'gwiÅ¼dÅ¼Ä…', tak naprawdÄ™ Å›piewajÄ… do siebie, ale my tego nie sÅ‚yszymy.",
    "Sharks are older than treesâ€”sharks have been around for about 400 million years, trees for about 350 million.":
        "Rekiny sÄ… starsze niÅ¼ drzewa. Rekiny sÄ… tu od 400 mln lat, drzewa od 350 mln.",
    "Bananas are botanically berries, but strawberries arenâ€™tâ€”botany can be weird.":
        "Botanicznie banan to jagoda, a truskawka nie. Botanika bywa dziwna.",
    "An ant can lift up to 50 times its own weightâ€”if you were an ant, you could lift a car by yourself.":
        "MrÃ³wka podnosi ciÄ™Å¼ar 50 razy wiÄ™kszy od siebie. GdybyÅ› byÅ‚ mrÃ³wkÄ…, podniÃ³sÅ‚byÅ› samochÃ³d.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Latem WieÅ¼a Eiffla roÅ›nie o ok. 15 cm przez rozszerzanie siÄ™ metalu pod wpÅ‚ywem ciepÅ‚a.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "ÅÄ…czna waga wszystkich ludzi na Ziemi jest mniej wiÄ™cej rÃ³wna wadze wszystkich mrÃ³wek.",
    "Sloths can hold their breath underwater longer than dolphinsâ€”up to about 40 minutes.":
        "Leniwce potrafiÄ… wstrzymaÄ‡ oddech pod wodÄ… dÅ‚uÅ¼ej niÅ¼ delfiny â€“ nawet do 40 minut.",
    "Pigeons can tell the difference between paintings by Picasso and Monetâ€”turns out theyâ€™re more art-savvy than we think.":
        "GoÅ‚Ä™bie odrÃ³Å¼niajÄ… obrazy Picassa od Moneta. ZnajÄ… siÄ™ na sztuce lepiej niÅ¼ myÅ›limy.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS jest darmowy, ale rzÄ…d USA wydaje dziennie ok. 2 mln dolarÃ³w na jego utrzymanie.",
    "Platypuses donâ€™t have stomachsâ€”food goes from the esophagus straight to the intestines.":
        "Dziobak nie ma Å¼oÅ‚Ä…dka; jedzenie trafia z przeÅ‚yku prosto do jelit.",
    "William Shakespeare is credited with the first recorded use of the word â€œswaggerâ€â€”even in the 16th century, he had style.":
        "Szekspir jako pierwszy uÅ¼yÅ‚ sÅ‚owa 'swagger' (lans). JuÅ¼ w XVI wieku miaÅ‚ styl.",
    "A blue whaleâ€™s heart is so large that a human could swim through its main arteries.":
        "Serce pÅ‚etwala bÅ‚Ä™kitnego jest tak duÅ¼e, Å¼e czÅ‚owiek mÃ³gÅ‚by pÅ‚ywaÄ‡ w jego tÄ™tnicach.",
    "Ants donâ€™t have lungsâ€”and they never truly â€œsleepâ€; they operate nonstop like tiny workaholics.":
        "MrÃ³wki nie majÄ… pÅ‚uc i nigdy tak naprawdÄ™ nie Å›piÄ…. To maÅ‚e pracoholiki.",
    "On Saturn and Jupiter, it can literally rain diamondsâ€”apparently weâ€™re living on the wrong planet.":
        "Na Saturnie i Jowiszu pada deszcz diamentÃ³w. Chyba Å¼yjemy na zÅ‚ej planecie.",
    "Honeybees can recognize human faces and remember them individually.":
        "PszczoÅ‚y potrafiÄ… rozpoznawaÄ‡ i zapamiÄ™tywaÄ‡ ludzkie twarze.",
    "Hippo â€œsweatâ€ can look pink and acts like both sunscreen and an antibacterial shield.":
        "Pot hipopotama jest rÃ³Å¼owy i dziaÅ‚a jak krem z filtrem oraz antybiotyk.",
    "Wombat poop is cube-shaped, so it doesnâ€™t roll away and can mark territory more effectively.":
        "Kupa wombata jest szeÅ›cienna, Å¼eby siÄ™ nie turlaÅ‚a i lepiej znaczyÅ‚a teren.",
    "Cashews grow outside the cashew apple, hanging at the very endâ€”an oddly surprising design.":
        "Nerkowce rosnÄ… na zewnÄ…trz owocu, zwisajÄ…c na samym dole. Dziwny projekt natury.",
    "Sharks are older than Saturnâ€™s ringsâ€”they were around millions of years before Saturn got its famous bling.":
        "Rekiny sÄ… starsze niÅ¼ pierÅ›cienie Saturna. ByÅ‚y tu miliony lat przed nimi.",
    "Butterflies taste with their feetâ€”when they land on a leaf, theyâ€™re basically sampling dinner.":
        "Motyle czujÄ… smak nogami. LÄ…dujÄ…c na liÅ›ciu, tak naprawdÄ™ prÃ³bujÄ… obiad.",
    "A snail can sleep for up to three years without waking upâ€”honestly, relatable.":
        "Åšlimak moÅ¼e spaÄ‡ 3 lata bez przerwy. Szczerze? ZazdroszczÄ™.",
    "An ostrichâ€™s eyes are bigger than its brainâ€”living on the fine line between looking and thinking.":
        "Oczy strusia sÄ… wiÄ™ksze od jego mÃ³zgu.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingi rodzÄ… siÄ™ szare. RÃ³Å¼owe stajÄ… siÄ™ od jedzenia krewetek i alg.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "WiewiÃ³rki sadzÄ… tysiÄ…ce drzew rocznie, bo zapominajÄ…, gdzie zakopaÅ‚y orzechy.",
    "The first video game played in space was Tetrisâ€”played on a Game Boy by a cosmonaut in 1993.":
        "PierwszÄ… grÄ… w kosmosie byÅ‚ Tetris, zagrany na Game Boyu przez kosmonautÄ™ w 1993 roku.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussionsâ€”using your tongue as a helmet is a wild solution.":
        "DziÄ™cioÅ‚ owija jÄ™zyk wokÃ³Å‚ mÃ³zgu, by chroniÄ‡ go przed wstrzÄ…sami. JÄ™zyk jako kask â€“ szalone.",
  },
};

