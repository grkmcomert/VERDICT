import 'dart:convert';

// Auto-generated did-you-know phrase localizations.
// Source language key is the English phrase used in _analysisDidYouKnowFacts.

bool _looksLikeMojibake(String value) {
  return value.contains('\uFFFD') ||
      value.contains('\u00C2') ||
      value.contains('\u00C3') ||
      value.contains('\u00C4') ||
      value.contains('\u00C5') ||
      value.contains('\u00D0') ||
      value.contains('\u00D1') ||
      value.contains('\u00E0') ||
      value.contains('\u00E2\u20AC');
}

List<int>? _encodeWindows1252Bytes(String value) {
  const Map<int, int> cp1252Extended = <int, int>{
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
  };

  final List<int> bytes = <int>[];
  for (final int unit in value.codeUnits) {
    if (unit <= 0x00FF) {
      bytes.add(unit);
      continue;
    }
    final int? mapped = cp1252Extended[unit];
    if (mapped == null) return null;
    bytes.add(mapped);
  }
  return bytes;
}

String _repairMojibakeText(String value) {
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

  for (int i = 0; i < 3; i++) {
    if (!_looksLikeMojibake(fixed)) break;
    for (final MapEntry<String, String> entry in replacements.entries) {
      fixed = fixed.replaceAll(entry.key, entry.value);
    }
    final List<int>? bytes = _encodeWindows1252Bytes(fixed);
    if (bytes == null) break;
    try {
      final String decoded = utf8.decode(bytes, allowMalformed: false);
      if (decoded == fixed) break;
      fixed = decoded;
    } catch (_) {
      break;
    }
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
  if (code == 'in') return 'id'; // Endonezce dÃ¼zeltmesi
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

  // EGER es-mx icinde bulunamazsa es dilini fallback olarak dene.
  if (translated == null && normalized == 'es-mx') {
    translated =
        _findLocalizedPhrase(_didYouKnowPhraseLocalizations['es'], enPhrase);
  }

  if (translated == null) return null;
  final String clean = _cleanDidYouKnowText(translated);
  return clean.isEmpty ? null : clean;
}

const Map<String, Map<String, String>> _didYouKnowPhraseLocalizations = {
  'es': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Los cuervos no solo reconocen rostros humanos; pueden recordar durante años a quienes los trataron mal e incluso advertir a otros cuervos.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Los gatos pasan cerca del 70% de su vida durmiendo. Así que un gato de 10 años, en realidad, solo ha estado despierto unos 3 años.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "La miel nunca caduca. Los arqueólogos han hallado tarros con 3.000 años de antigüedad en pirámides egipcias que aún eran comestibles.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Las nutrias marinas se toman de la mano al dormir para que la corriente no las separe.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "En Venus, un día dura más que un año: tarda más en girar sobre su propio eje que en dar la vuelta al Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "El encendedor se inventó antes que la cerilla. A veces, la tecnología 'antigua' es más vieja de lo que creemos.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Los pulpos tienen tres corazones y nueve cerebros; olvidar cosas no es realmente una opción para ellos.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Las vacas tienen 'mejores amigas' y pueden sufrir mucho estrés (e incluso llorar) si las separan.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "El primer virus informático se llamó 'Creeper' y mostraba el mensaje: '¡Soy el Creeper, atrápame si puedes!'.",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Una nube promedio puede pesar unos 500.000 kg; imagina una manada gigante de elefantes flotando sobre tu cabeza.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "El ADN humano es un 50% idéntico al de una banana. Así que llamar 'hermano' a un plátano no es del todo descabellado.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Los osos polares tienen la piel negra y su pelaje es transparente; se ven blancos por cómo reflejan la luz.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "No se puede llorar en el espacio: sin gravedad, las lágrimas no caen, se quedan acumuladas como una burbuja en el ojo.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "El Monte Everest crece unos 4 milímetros al año; la Tierra sigue cambiando.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Los ratones que 'silban' en realidad se están cantando, pero a una frecuencia tan alta que los humanos no podemos oírla.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Los tiburones son más antiguos que los árboles: ellos llevan aquí 400 millones de años, los árboles solo 350 millones.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Botánicamente, las bananas son bayas, pero las fresas no. La naturaleza es extraña.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Una hormiga levanta 50 veces su peso. Si fueras una hormiga, podrías levantar un coche tú solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel puede crecer unos 15 cm en verano debido a la expansión térmica del metal.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "El peso total de todos los humanos en la Tierra es casi igual al peso total de todas las hormigas del mundo.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Los perezosos aguantan la respiración bajo el agua más tiempo que los delfines: hasta 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Las palomas distinguen entre pinturas de Picasso y Monet. Resulta que saben más de arte de lo que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "El GPS es gratis, pero el gobierno de EE. UU. gasta unos 2 millones de dólares al día para mantenerlo funcionando.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Los ornitorrincos no tienen estómago; la comida pasa directamente del esófago a los intestinos.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "A Shakespeare se le atribuye el primer uso de la palabra 'swagger' (estilo/chulería). Incluso en el siglo XVI, tenía clase.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "El corazón de una ballena azul es tan grande que un humano podría nadar por sus arterias principales.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Las hormigas no tienen pulmones y nunca 'duermen' realmente; trabajan sin parar.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "En Saturno y Júpiter llueven diamantes literalmente. Al parecer, vivimos en el planeta equivocado.",
    "Honeybees can recognize human faces and remember them individually.":
        "Las abejas pueden reconocer rostros humanos y recordarlos individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "El 'sudor' de los hipopótamos es rosado y funciona como protector solar y antibacteriano.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "La caca del wombat es cúbica para que no ruede y marque mejor su territorio.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "El anacardo crece por fuera del fruto, colgando al final. Un diseño de la naturaleza bastante curioso.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Los tiburones son más viejos que los anillos de Saturno. Ya estaban aquí millones de años antes de que Saturno tuviera sus anillos.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Las mariposas saborean con los pies. Cuando se posan en una hoja, están probando la cena.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un caracol puede dormir tres años seguidos. Sinceramente, qué envidia.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Los ojos del avestruz son más grandes que su cerebro.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Los flamencos nacen grises; su color rosa viene de los pigmentos de las algas y camarones que comen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Las ardillas plantan miles de árboles al año simplemente porque olvidan dónde enterraron sus nueces.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "El primer videojuego jugado en el espacio fue Tetris, en una Game Boy, por un cosmonauta en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Los pájaros carpinteros envuelven su lengua alrededor de su cerebro para protegerlo de los golpes. Usar la lengua como casco es una locura.",
  },
  'es-mx': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Los cuervos no solo reconocen rostros humanos; pueden recordar durante años a quienes los trataron mal e incluso advertir a otros cuervos.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Los gatos pasan cerca del 70% de su vida durmiendo. Así que un gato de 10 años, en realidad, solo ha estado despierto unos 3 años.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "La miel nunca caduca. Los arqueólogos han hallado tarros con 3.000 años de antigüedad en pirámides egipcias que aún eran comestibles.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Las nutrias marinas se toman de la mano al dormir para que la corriente no las separe.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "En Venus, un día dura más que un año: tarda más en girar sobre su propio eje que en dar la vuelta al Sol.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "El encendedor se inventó antes que los cerillos. A veces, la tecnología 'vieja' es más antigua de lo que pensamos.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Los pulpos tienen tres corazones y nueve cerebros; olvidar cosas no es realmente una opción para ellos.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Las vacas tienen 'mejores amigas' y pueden sufrir mucho estrés (e incluso llorar) si las separan.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "El primer virus informático se llamó 'Creeper' y mostraba el mensaje: '¡Soy el Creeper, atrápame si puedes!'.",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Una nube promedio puede pesar unos 500.000 kg; imagina una manada gigante de elefantes flotando sobre tu cabeza.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "El ADN humano es 50% similar al de un plátano. Así que llamar 'hermano' a un plátano no es tan descabellado.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Los osos polares tienen la piel negra y su pelaje es transparente; se ven blancos por cómo reflejan la luz.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "No se puede llorar en el espacio: sin gravedad, las lágrimas no caen, se quedan acumuladas como una burbuja en el ojo.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "El Monte Everest crece unos 4 milímetros al año; la Tierra sigue cambiando.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Los ratones que 'silban' en realidad se están cantando, pero a una frecuencia tan alta que los humanos no podemos oírla.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Los tiburones son más antiguos que los árboles: ellos llevan aquí 400 millones de años, los árboles solo 350 millones.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Botánicamente, las bananas son bayas, pero las fresas no. La naturaleza es extraña.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Una hormiga levanta 50 veces su peso. Si fueras una hormiga, podrías levantar un coche tú solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "La Torre Eiffel puede crecer unos 15 cm en verano debido a la expansión térmica del metal.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "El peso total de todos los humanos en la Tierra es casi igual al peso total de todas las hormigas del mundo.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Los perezosos aguantan la respiración bajo el agua más tiempo que los delfines: hasta 40 minutos.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Las palomas distinguen entre pinturas de Picasso y Monet. Resulta que saben más de arte de lo que pensamos.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "El GPS es gratis, pero el gobierno de EE. UU. gasta unos 2 millones de dólares al día para mantenerlo funcionando.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Los ornitorrincos no tienen estómago; la comida pasa directamente del esófago a los intestinos.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "A Shakespeare se le atribuye el primer uso de la palabra 'swagger' (estilo/chulería). Incluso en el siglo XVI, tenía clase.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "El corazón de una ballena azul es tan grande que un humano podría nadar por sus arterias principales.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Las hormigas no tienen pulmones y nunca 'duermen' realmente; trabajan sin parar.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "En Saturno y Júpiter llueven diamantes literalmente. Al parecer, vivimos en el planeta equivocado.",
    "Honeybees can recognize human faces and remember them individually.":
        "Las abejas pueden reconocer rostros humanos y recordarlos individualmente.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "El 'sudor' de los hipopótamos es rosado y funciona como protector solar y antibacteriano.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "La caca del wombat es cúbica para que no ruede y marque mejor su territorio.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "El anacardo crece por fuera del fruto, colgando al final. Un diseño de la naturaleza bastante curioso.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Los tiburones son más viejos que los anillos de Saturno. Ya estaban aquí millones de años antes de que Saturno tuviera sus anillos.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Las mariposas saborean con los pies. Cuando se posan en una hoja, están probando la cena.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un caracol puede dormir hasta tres años sin despertar. La verdad, me identifico.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Los ojos del avestruz son más grandes que su cerebro.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Los flamencos nacen grises; su color rosa viene de los pigmentos de las algas y camarones que comen.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Las ardillas plantan miles de árboles al año simplemente porque olvidan dónde enterraron sus nueces.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "El primer videojuego jugado en el espacio fue Tetris, en una Game Boy, por un cosmonauta en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Los pájaros carpinteros envuelven su lengua alrededor de su cerebro para protegerlo de los golpes. Usar la lengua como casco es una locura.",
  },
  'hi': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "कौवे न केवल इंसानी चेहरे पहचानते हैं, बल्कि उन लोगों को भी याद रखते हैं जिन्होंने उनके साथ बुरा बर्ताव किया, और वे बाकी कौवों को भी आगाह कर देते हैं।",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "बिल्लियाँ अपने जीवन का 70% हिस्सा सोने में बिताती हैं। यानी एक 10 साल की बिल्ली असल में सिर्फ 3 साल ही जागी होती है।",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "शहद कभी खराब नहीं होता। पुरातत्वविदों को मिस्र के पिरामिडों में 3,000 साल पुराना शहद मिला है जो आज भी खाने योग्य है।",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "समुद्री ऊदबिलाव (Sea otters) सोते समय एक-दूसरे का हाथ पकड़ कर रखते हैं ताकि वे पानी के बहाव में बिछड़ न जाएं।",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "शुक्र ग्रह पर एक दिन, उसके एक साल से भी लंबा होता है। यह अपनी धुरी पर सूरज की परिक्रमा करने से भी धीमी गति से घूमता है।",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "लाइटर का आविष्कार माचिस से पहले हुआ था। कभी-कभी पुरानी तकनीक हमारी सोच से भी ज्यादा पुरानी होती है।",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "ऑक्टोपस के पास तीन दिल और नौ दिमाग होते हैं—चीजों को भूलना उनके लिए कोई विकल्प नहीं है।",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "गायों के भी 'बेस्ट फ्रेंड्स' होते हैं। अगर उन्हें अलग कर दिया जाए, तो वे बहुत तनाव में आ जाती हैं और रोने भी लगती हैं।",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "दुनिया के पहले कंप्यूटर वायरस का नाम 'क्रीपर' था, जो स्क्रीन पर लिखता था: 'मैं क्रीपर हूँ, पकड़ सको तो पकड़ लो!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "एक औसत बादल का वजन करीब 500,000 किलो हो सकता है—जैसे हाथियों का एक विशाल झुंड आपके सिर के ऊपर तैर रहा हो।",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "इंसानी डीएनए और केले का डीएनए 50% एक जैसा होता है। तो अगर आप केले को अपना 'भाई-बहन' कहें, तो यह पूरी तरह गलत नहीं होगा।",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "ध्रुवीय भालू (Polar Bear) की त्वचा असल में काली होती है और उनके बाल पारदर्शी। रोशनी के बिखराव की वजह से वे सफेद दिखते हैं।",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "आप अंतरिक्ष में रो नहीं सकते। गुरुत्वाकर्षण के बिना आँसू गालों पर नहीं गिरते, बल्कि आँखों में ही एक बुलबुले की तरह जम जाते हैं।",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "माउंट एवरेस्ट हर साल लगभग 4 मिलीमीटर बढ़ता है—हमारी धरती अब भी बदल रही है।",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "सीटी बजाने वाले चूहे असल में एक-दूसरे के लिए गाना गाते हैं, लेकिन उनकी आवाज़ इतनी बारीक होती है कि इंसान सुन नहीं सकते।",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "शार्क पेड़ों से भी ज्यादा पुरानी हैं। शार्क 400 मिलियन सालों से हैं, जबकि पेड़ 350 मिलियन साल पहले आए।",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "वनस्पति विज्ञान के अनुसार केला एक 'बेरी' है, लेकिन स्ट्रॉबेरी नहीं। विज्ञान कभी-कभी अजीब होता है।",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "चींटी अपने वजन का 50 गुना उठा सकती है। अगर आप चींटी होते, तो एक कार अकेले उठा लेते।",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "गर्मी की वजह से एफिल टॉवर की ऊंचाई 15 सेंटीमीटर तक बढ़ जाती है।",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "धरती पर मौजूद सभी इंसानों का कुल वजन, दुनिया की सारी चींटियों के कुल वजन के लगभग बराबर है।",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "स्लॉथ (Sloth) पानी के अंदर डॉल्फिन से ज्यादा देर तक सांस रोक सकते हैं—करीब 40 मिनट तक।",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "कबूतर पिकासो और मोनेट की पेंटिंग्स में फर्क कर सकते हैं। वे हमारी सोच से ज्यादा कला-प्रेमी हैं।",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS इस्तेमाल करना फ्री है, लेकिन इसे चलाने के लिए अमेरिकी सरकार हर दिन करीब 2 मिलियन डॉलर खर्च करती है।",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "प्लैटिपस के पास पेट नहीं होता; खाना सीधे उनकी आंतों में जाता है।",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "विलियम शेक्सपियर ने ही सबसे पहले 'स्वैगर' (Swagger) शब्द का इस्तेमाल किया था। 16वीं सदी में भी उनका अपना टशन था।",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "ब्लू व्हेल का दिल इतना बड़ा होता है कि एक इंसान उसकी नसों के अंदर तैर सकता है।",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "चींटियों के फेफड़े नहीं होते और वे कभी पूरी तरह नहीं 'सोतीं'। वे छोटे कामचोर नहीं, बल्कि कर्मठ मजदूर हैं।",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "शनि और बृहस्पति ग्रह पर हीरों की बारिश होती है। लगता है हम गलत ग्रह पर रह रहे हैं।",
    "Honeybees can recognize human faces and remember them individually.":
        "मधुमक्खियां इंसानी चेहरों को पहचान सकती हैं और उन्हें याद भी रख सकती हैं।",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "दरियाई घोड़े का पसीना गुलाबी होता है और यह सनस्क्रीन और एंटीबायोटिक की तरह काम करता है।",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "वॉम्बैट (Wombat) की पॉटी चौकोर (क्यूब) आकार की होती है, ताकि वह लुढ़क न जाए और इलाका मार्क कर सके।",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "काजू, काजू-फल के बाहर उगता है और नीचे लटका रहता है। कुदरत का एक अजीब डिजाइन।",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "शार्क, शनि ग्रह के छल्लों से भी पुरानी हैं। जब शनि को उसके छल्ले मिले, उससे करोड़ों साल पहले शार्क मौजूद थीं।",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "तितलियाँ अपने पैरों से स्वाद लेती हैं। जब वे किसी पत्ते पर बैठती हैं, तो समझो वे अपना खाना चख रही हैं।",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "घोंघा (Snail) लगातार तीन साल तक सो सकता है। सच कहें तो, काश हम भी ऐसा कर पाते।",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "शुतुरमुर्ग की आँखें उसके दिमाग से बड़ी होती हैं।",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "फ्लेमिंगो (राजहंस) पैदा होते वक्त ग्रे रंग के होते हैं। उनका गुलाबी रंग उनके द्वारा खाए जाने वाले झींगों और शैवाल से आता है।",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "गिलहरियाँ हर साल हजारों नए पेड़ लगाती हैं, सिर्फ इसलिए क्योंकि वे भूल जाती हैं कि उन्होंने अपने अखरोट कहाँ छिपाए थे।",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "अंतरिक्ष में खेला गया पहला वीडियो गेम टेट्रिस (Tetris) था, जिसे 1993 में एक गेम बॉय पर खेला गया था।",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "कठफोड़वा अपनी जीभ को अपने दिमाग के चारों ओर लपेट लेता है ताकि चोट न लगे। जीभ को हेलमेट की तरह इस्तेमाल करना गजब का तरीका है।",
  },
  'hu': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "A varjak nemcsak felismerik az arcokat, hanem évekre megjegyzik azokat, akik rosszul bántak velük – sőt, más varjakat is figyelmeztetnek.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "A macskák életük 70%-át átalusszák. Tehát egy 10 éves macska valójában csak kb. 3 évet töltött ébren.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "A méz sosem romlik meg. Régészek 3000 éves, ehető mézet találtak az egyiptomi piramisokban.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "A tengeri vidrák kézenfogva alszanak, hogy az áramlat ne sodorja el őket egymástól.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "A Vénuszon egy nap hosszabb, mint egy év – lassabban fordul meg a tengelye körül, mint ahogy megkerüli a Napot.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Az öngyújtót a gyufa előtt találták fel. Néha a 'régi' technológia régebbi, mint hinnénk.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "A polipoknak három szívük és kilenc agyuk van – a felejtés náluk nem opció.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "A teheneknek vannak 'legjobb barátaik', és súlyosan stresszelnek, sőt sírnak is, ha elválasztják őket.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "A világ első számítógépes vírusa a 'Creeper' volt, ami ezt írta ki: 'Én vagyok a Creeper, kapj el, ha tudsz!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Egy átlagos felhő súlya kb. 500 000 kg – mintha egy hatalmas elefántcsorda lebegne a fejünk felett.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Az emberi DNS 50%-ban megegyezik a banánéval. Szóval, ha holnap 'tesónak' hívsz egy banánt, nem tévedsz nagyot.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "A jegesmedvék bőre valójában fekete, a szőrük pedig átlátszó. Csak a fényvisszaverődés miatt tűnnek fehérnek.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Az űrben nem tudsz sírni: gravitáció híján a könnyek nem folynak le, hanem egy gombócban gyűlnek össze a szemedben.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "A Mount Everest évente kb. 4 millimétert nő – a Földünk folyamatosan változik.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "A 'fütyülő' egerek valójában énekelnek egymásnak, csak olyan magas frekvencián, amit mi nem hallunk.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "A cápák idősebbek, mint a fák. A cápák 400 millió éve vannak itt, a fák csak 350 millió éve.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Biológiailag a banán bogyós gyümölcs, de az eper nem az. A botanika néha fura.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Egy hangya a súlya 50-szeresét is elbírja. Ha hangya lennél, egyedül felemelnél egy autót.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Nyáron az Eiffel-torony kb. 15 centivel megnő a hőtágulás miatt.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "A Föld összes emberének súlya nagyjából megegyezik a világ összes hangyájának súlyával.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "A lajhárok tovább bírják víz alatt levegő nélkül, mint a delfinek – akár 40 percig is.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "A galambok meg tudják különböztetni Picasso és Monet festményeit. Úgy tűnik, jobban értenek a művészethez, mint hittük.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "A GPS ingyenes, de az USA kormánya állítólag napi 2 millió dollárt költ a működtetésére.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "A kacsacsőrű emlősnek nincs gyomra; az étel a nyelőcsőből egyenesen a belekbe kerül.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "A 'swagger' (vagány stílus) szót Shakespeare használta először. Már a 16. században is volt stílusa.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "A kék bálna szíve akkora, hogy egy ember simán átúszhatna a fő artériáin.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "A hangyáknak nincs tüdejük és sosem 'alszanak' igazán. Apró munkamániások.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "A Szaturnuszon és a Jupiteren gyémánteső hullik. Úgy tűnik, rossz bolygóra születtünk.",
    "Honeybees can recognize human faces and remember them individually.":
        "A méhek képesek felismerni és megjegyezni az emberi arcokat.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "A vízilovak izzadsága rózsaszín, ami naptejként és antibakteriális pajzsként is szolgál.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "A vombat ürüléke kocka alakú, így nem gurul el, és jobban jelzi a területet.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "A kesudió a gyümölcsön kívül, annak az alján nő. Elég fura dizájn.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "A cápák öregebbek a Szaturnusz gyűrűinél. Millió évekkel a gyűrűk előtt már itt voltak.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "A pillangók a lábukkal éreznek ízeket. Ha rászállnak egy levélre, lényegében a vacsorát kóstolják.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Egy csiga akár három évig is aludhat egyhuzamban. Őszintén szólva, irigylem.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "A strucc szeme nagyobb, mint az agya.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "A flamingók szürkének születnek. A színüket a rákokból és algákból nyert pigmentek okozzák.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "A mókusok évente több ezer fát ültetnek, pusztán azért, mert elfelejtik, hová ásták el a mogyorót.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Az első videojáték az űrben a Tetris volt, amit egy űrhajós játszott Game Boy-on 1993-ban.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "A harkályok a nyelvükkel körbetekerik az agyukat, hogy tompítsák az ütést. Nyelv-sisak, elég vad megoldás.",
  },
  'zh-hans': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "ä¹Œé¸¦ä¸ä»…èƒ½è¯†åˆ«äººè„¸ï¼Œè¿˜èƒ½è®°ä½è™å¾…è¿‡å®ƒä»¬çš„äººé•¿è¾¾æ•°å¹´ï¼Œç”šè‡³ä¼šè­¦å‘ŠåŒä¼´ã€‚",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "çŒ«ä¸€ç”Ÿä¸­çº¦70%çš„æ—¶é—´éƒ½åœ¨ç¡è§‰ã€‚æ‰€ä»¥ä¸€åª10å²çš„çŒ«ï¼Œæ¸…é†’çš„æ—¶é—´åªæœ‰3å¹´å·¦å³ã€‚",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "èœ‚èœœæ°¸è¿œä¸ä¼šå˜è´¨ã€‚è€ƒå¤å­¦å®¶åœ¨åŸƒåŠé‡‘å­—å¡”é‡Œå‘ç°äº†3000å¹´å‰çš„èœ‚èœœï¼Œè‡³ä»Šä»å¯é£Ÿç”¨ã€‚",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "æµ·ç­ç¡è§‰æ—¶ä¼šæ‰‹ç‰µæ‰‹ï¼Œä»¥å…è¢«æ°´æµå†²æ•£ã€‚",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "åœ¨é‡‘æ˜Ÿä¸Šï¼Œä¸€å¤©æ¯”ä¸€å¹´è¿˜é•¿ã€‚å®ƒè‡ªè½¬çš„é€Ÿåº¦æ¯”ç»•å¤ªé˜³å…¬è½¬çš„é€Ÿåº¦è¿˜è¦æ…¢ã€‚",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "打火机比火柴发明得更早。有时候，“老”技术比我们想象的还要古老。",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "章鱼有三颗心脏和九个大脑——所以“健忘”对它们来说是不存在的。",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "奶牛也有“好闺蜜”。如果把它们分开，它们会感到焦虑，甚至会流泪。",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "世界上第一个计算机病毒叫“Creeper”，它的弹窗内容是：“我是Creeper，有本事来抓我呀！”",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "一朵普通的云重约50万公斤——就像一大群大象悬浮在头顶。",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "人类的DNA与香蕉的DNA有50%的相似度。所以叫香蕉一声“亲戚”也不算过分。",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "åŒ—æç†Šçš„çš®è‚¤å…¶å®æ˜¯é»‘è‰²çš„ï¼Œæ¯›å‘æ˜¯é€æ˜çš„ã€‚çœ‹èµ·æ¥æ˜¯ç™½è‰²æ˜¯å› ä¸ºå…‰çº¿çš„æŠ˜å°„ã€‚",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "åœ¨å¤ªç©ºä¸­æ²¡æ³•æµæ³ªï¼šå› ä¸ºæ²¡æœ‰é‡åŠ›ï¼Œçœ¼æ³ªä¸ä¼šæµä¸‹æ¥ï¼Œåªä¼šèšæˆä¸€å›¢ç§¯åœ¨çœ¼ç›é‡Œã€‚",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "珠穆朗玛峰每年仍在长高约4毫米——地球一直在变化。",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "所谓“吹口哨”的老鼠其实是在互相唱歌，只是频率太高，人类听不见。",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "é²¨é±¼æ¯”æ ‘æœ¨æ›´å¤è€ã€‚é²¨é±¼å­˜åœ¨äº†4äº¿å¹´ï¼Œè€Œæ ‘æœ¨åªæœ‰3.5äº¿å¹´ã€‚",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "ä»æ¤ç‰©å­¦è§’åº¦çœ‹ï¼Œé¦™è•‰å±äºæµ†æœï¼Œä½†è‰è“å´ä¸æ˜¯ã€‚æ¤ç‰©å­¦çœŸæ˜¯å¥‡å¦™ã€‚",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "èš‚èšèƒ½ä¸¾èµ·è‡ªèº«ä½“é‡50å€çš„ç‰©ä½“ã€‚å¦‚æœä½ æ˜¯èš‚èšï¼Œä½ å¯ä»¥å¾’æ‰‹ä¸¾èµ·ä¸€è¾†æ±½è½¦ã€‚",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "ç”±äºçƒ­èƒ€å†·ç¼©ï¼ŒåŸƒè²å°”é“å¡”åœ¨å¤å¤©ä¼šé•¿é«˜çº¦15å˜ç±³ã€‚",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "åœ°çƒä¸Šæ‰€æœ‰äººç±»çš„æ€»é‡é‡ï¼Œå¤§çº¦ç­‰äºæ‰€æœ‰èš‚èšçš„æ€»é‡é‡ã€‚",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "树懒在水下憋气的时间比海豚还长——可达40分钟。",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "é¸½å­èƒ½åˆ†è¾¨å‡ºæ¯•åŠ ç´¢å’Œè«å¥ˆçš„ç”»ä½œã€‚çœ‹æ¥å®ƒä»¬æ¯”æˆ‘ä»¬æ›´æœ‰è‰ºæœ¯ç»†èƒã€‚",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPSæ˜¯å…è´¹ä½¿ç”¨çš„ï¼Œä½†æ®æŠ¥é“ï¼Œç¾å›½æ”¿åºœæ¯å¤©è¦èŠ±è´¹çº¦200ä¸‡ç¾å…ƒæ¥ç»´æŒå…¶è¿è¡Œã€‚",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "é¸­å˜´å…½æ²¡æœ‰èƒƒï¼Œé£Ÿç‰©ä»é£Ÿé“ç›´æ¥è¿›å…¥è‚ é“ã€‚",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "莎士比亚是第一个使用“Swagger”（大摇大摆/范儿）这个词的人。早在16世纪他就很潮了。",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "è“é²¸çš„å¿ƒè„å¤§åˆ°äººç±»å¯ä»¥åœ¨å®ƒçš„ä¸»è¦åŠ¨è„‰é‡Œæ¸¸æ³³ã€‚",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "蚂蚁没有肺，也不真正“睡觉”。它们就像小小的工作狂，永不停歇。",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "在土星和木星上真的会下“钻石雨”。看来我们住错星球了。",
    "Honeybees can recognize human faces and remember them individually.":
        "èœœèœ‚èƒ½è¯†åˆ«äººè„¸ï¼Œå¹¶ä¸”èƒ½å•ç‹¬è®°ä½æ¯ä¸€å¼ è„¸ã€‚",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "河马的“汗水”是粉红色的，既能防晒又能杀菌。",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "è¢‹ç†Šçš„ä¾¿ä¾¿æ˜¯æ–¹å½¢çš„ï¼Œè¿™æ ·å°±ä¸ä¼šæ»šèµ°ï¼Œèƒ½æ›´å¥½åœ°æ ‡è®°é¢†åœ°ã€‚",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "è…°æœé•¿åœ¨æœå®çš„å¤–é¢ï¼ŒæŒ‚åœ¨æœ€åº•ç«¯ã€‚å¤§è‡ªç„¶çš„è®¾è®¡çœŸå¥‡æ€ªã€‚",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "é²¨é±¼æ¯”åœŸæ˜Ÿç¯è¿˜è¦å¤è€ã€‚åœ¨åœŸæ˜Ÿæˆ´ä¸Šå…‰ç¯ä¹‹å‰ï¼Œé²¨é±¼å·²ç»å­˜åœ¨äº†æ•°ç™¾ä¸‡å¹´ã€‚",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "è´è¶ç”¨è„šå°å‘³é“ã€‚å½“å®ƒä»¬åœåœ¨å¶å­ä¸Šæ—¶ï¼Œå…¶å®æ˜¯åœ¨è¯•åƒæ™šé¤ã€‚",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "èœ—ç‰›å¯ä»¥ä¸€ç¡ä¸‰å¹´ä¸é†’ã€‚è¯´å®è¯ï¼Œè¿™å¤ªè®©äººç¾¡æ…•äº†ã€‚",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "é¸µé¸Ÿçš„çœ¼ç›æ¯”è„‘å­è¿˜å¤§ã€‚",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "ç«çƒˆé¸Ÿå‡ºç”Ÿæ—¶æ˜¯ç°è‰²çš„ã€‚å®ƒä»¬æ ‡å¿—æ€§çš„ç²‰çº¢è‰²æ¥è‡ªé£Ÿç‰©ï¼ˆè™¾å’Œè—»ç±»ï¼‰ä¸­çš„è‰²ç´ ã€‚",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "松鼠每年会“误打误撞”种下几千棵树，因为它们总忘记把坚果埋哪儿了。",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "å¤ªç©ºä¸­ç©çš„ç¬¬ä¸€æ¬¾ç”µå­æ¸¸æˆæ˜¯ã€Šä¿„ç½—æ–¯æ–¹å—ã€‹ã€‚1993å¹´ï¼Œä¸€ä½å®‡èˆªå‘˜åœ¨Game Boyä¸Šç©çš„ã€‚",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "å•„æœ¨é¸ŸæŠŠèˆŒå¤´ç»•åœ¨è„‘å­ä¸Šä»¥é˜²è„‘éœ‡è¡ã€‚æŠŠèˆŒå¤´å½“å¤´ç›”ç”¨ï¼Œè¿™æ‹›å¤ªç»äº†ã€‚",
  },
  'id': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Gagak tidak hanya mengenali wajah; mereka mengingat orang yang jahat pada mereka selama bertahun-tahun, bahkan memperingatkan gagak lain.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Kucing menghabiskan 70% hidupnya untuk tidur. Jadi, kucing umur 10 tahun sebenarnya baru bangun selama 3 tahun.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Madu tidak pernah basi. Arkeolog menemukan madu berusia 3.000 tahun di piramida Mesir yang masih bisa dimakan.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Berang-berang laut bergandengan tangan saat tidur supaya tidak terpisah oleh arus.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Di Venus, satu hari lebih lama dari satu tahun. Rotasinya lebih lambat daripada waktu yang dibutuhkan untuk mengelilingi Matahari.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Korek api gas (lighter) ditemukan sebelum korek api kayu (match). Kadang teknologi 'lama' lebih tua dari dugaan kita.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Gurita punya tiga jantung dan sembilan otak—jadi lupa ingatan bukan alasan bagi mereka.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Sapi punya 'sahabat', dan mereka bisa stres berat—bahkan menangis—kalau dipisahkan.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Virus komputer pertama bernama 'Creeper', yang menampilkan pesan: 'Aku Creeper, tangkap aku kalau bisa!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Awan rata-rata beratnya sekitar 500.000 kg—seperti sekumpulan gajah yang melayang di atas kepala.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "DNA manusia 50% mirip dengan DNA pisang. Jadi menganggap pisang sebagai 'saudara jauh' tidak sepenuhnya salah.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Kulit beruang kutub sebenarnya hitam dan bulunya transparan. Mereka terlihat putih karena pantulan cahaya.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Kamu tidak bisa menangis di luar angkasa. Tanpa gravitasi, air mata tidak jatuh, tapi menggumpal di mata.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Gunung Everest tumbuh sekitar 4 milimeter setiap tahun—Bumi masih terus berubah.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Tikus yang 'bersiul' sebenarnya sedang bernyanyi, tapi frekuensinya terlalu tinggi untuk didengar manusia.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Hiu lebih tua dari pohon. Hiu sudah ada sejak 400 juta tahun lalu, pohon baru 350 juta tahun.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Secara botani, pisang adalah beri, tapi stroberi bukan. Ilmu botani memang aneh.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Semut bisa mengangkat beban 50 kali berat tubuhnya. Kalau kamu semut, kamu bisa mengangkat mobil sendirian.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Menara Eiffel bisa bertambah tinggi 15 cm di musim panas karena pemuaian panas.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Total berat seluruh manusia di Bumi kira-kira sama dengan total berat seluruh semut.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Kukang bisa menahan napas di dalam air lebih lama dari lumba-lumba—sampai 40 menit.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Burung dara bisa membedakan lukisan Picasso dan Monet. Ternyata mereka punya jiwa seni.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS gratis digunakan, tapi pemerintah AS menghabiskan sekitar \$2 juta per hari untuk mengoperasikannya.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Platipus tidak punya lambung; makanan langsung turun dari kerongkongan ke usus.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "William Shakespeare adalah orang pertama yang menggunakan kata 'swagger'. Dia sudah keren sejak abad ke-16.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Jantung paus biru sangat besar sampai-sampai manusia bisa berenang di dalam pembuluh darah arterinya.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Semut tidak punya paru-paru dan tidak pernah benar-benar 'tidur'. Mereka pekerja keras sejati.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Di Saturnus dan Jupiter bisa terjadi hujan berlian. Sepertinya kita salah pilih planet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Lebah madu bisa mengenali dan mengingat wajah manusia.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Keringat kuda nil berwarna merah muda dan berfungsi sebagai tabir surya sekaligus antibakteri.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Kotoran wombat berbentuk kubus agar tidak menggelinding, sehingga lebih efektif menandai wilayah.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Kacang mete tumbuh di luar buahnya, menggantung di ujung. Desain alam yang aneh.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Hiu lebih tua dari cincin Saturnus. Hiu sudah ada jutaan tahun sebelum Saturnus punya cincinnya.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Kupu-kupu mencicipi rasa dengan kakinya. Saat hinggap di daun, mereka sebenarnya sedang mencicipi makan malam.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Siput bisa tidur selama tiga tahun tanpa bangun. Jujur, aku iri.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Mata burung unta lebih besar daripada otaknya.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingo lahir berwarna abu-abu. Warna merah mudanya berasal dari udang dan ganggang yang mereka makan.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Tupai menanam ribuan pohon setiap tahun secara tidak sengaja karena lupa di mana mengubur kacangnya.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Game pertama yang dimainkan di luar angkasa adalah Tetris, dimainkan di Game Boy oleh kosmonot tahun 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Burung pelatuk melilitkan lidahnya ke sekeliling otak untuk mencegah gegar otak. Lidah sebagai helm, ide gila.",
  },
  'nl': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Kraaien herkennen niet alleen gezichten, ze onthouden ook jarenlang wie hen slecht behandelde en waarschuwen andere kraaien.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Katten slapen 70% van hun leven. Een kat van 10 is dus eigenlijk maar 3 jaar wakker geweest.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Honing bederft nooit. Archeologen vonden in piramides 3000 jaar oude honing die nog eetbaar was.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Zeeotters houden elkaars hand vast tijdens het slapen zodat ze niet uit elkaar drijven.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Op Venus duurt een dag langer dan een jaar. De planeet draait langzamer om zijn as dan om de zon.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "De aansteker werd uitgevonden vóór de lucifer. Soms is oude technologie nieuwer dan we denken.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Octopussen hebben drie harten en negen breinen—vergeten is voor hen geen optie.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Koeien hebben 'beste vriendinnen' en raken gestrest, of gaan zelfs huilen, als ze gescheiden worden.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Het eerste computervirus heette 'Creeper' en toonde de tekst: 'Ik ben de Creeper, pak me dan als je kan!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Een gemiddelde wolk weegt zo'n 500.000 kg—alsof er een kudde olifanten boven je hoofd zweeft.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Menselijk DNA lijkt voor 50% op dat van een banaan. Een banaan je 'broer' noemen is dus niet helemaal onterecht.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "De huid van een ijsbeer is zwart en de vacht transparant. Ze lijken wit door de weerkaatsing van licht.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Je kunt niet huilen in de ruimte. Zonder zwaartekracht rollen tranen niet naar beneden, maar vormen ze een bolletje in je oog.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "De Mount Everest groeit elk jaar zo'n 4 millimeter—de aarde verandert nog steeds.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Muizen die 'fluiten' zingen eigenlijk naar elkaar, maar op een frequentie die wij niet kunnen horen.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Haaien zijn ouder dan bomen. Haaien zijn er al 400 miljoen jaar, bomen pas 350 miljoen jaar.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Botanisch gezien is een banaan een bes, maar een aardbei niet. De natuur is vreemd.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Een mier tilt 50 keer zijn eigen gewicht. Als jij een mier was, kon je in je eentje een auto optillen.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "De Eiffeltoren wordt in de zomer zo'n 15 cm langer door de hitte.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Het totale gewicht van alle mensen op aarde is ongeveer gelijk aan dat van alle mieren.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Luiaards kunnen langer hun adem inhouden onder water dan dolfijnen—tot wel 40 minuten.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Duiven zien het verschil tussen Picasso en Monet. Ze hebben meer verstand van kunst dan wij.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS is gratis, maar de Amerikaanse overheid geeft dagelijks zo'n 2 miljoen dollar uit om het draaiende te houden.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Vogelbekdieren hebben geen maag; voedsel gaat direct van de slokdarm naar de darmen.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Shakespeare gebruikte als eerste het woord 'swagger'. Hij had al stijl in de 16e eeuw.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Het hart van een blauwe vinvis is zo groot dat een mens door de slagaderen zou kunnen zwemmen.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Mieren hebben geen longen en slapen nooit echt. Het zijn kleine workaholics.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Op Saturnus en Jupiter regent het diamanten. We wonen op de verkeerde planeet.",
    "Honeybees can recognize human faces and remember them individually.":
        "Honingbijen kunnen menselijke gezichten herkennen en onthouden.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Het zweet van nijlpaarden is roze en werkt als zonnebrandcrème en bacteriedoder.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "De poep van een wombat is vierkant (kubus), zodat het niet wegrolt en zijn territorium markeert.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Cashewnoten groeien aan de buitenkant van de vrucht, helemaal onderaan. Een vreemd ontwerp van de natuur.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Haaien zijn ouder dan de ringen van Saturnus. Ze waren er al miljoenen jaren eerder.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Vlinders proeven met hun voeten. Als ze op een blad landen, zijn ze eigenlijk aan het voorproeven.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Een slak kan drie jaar aan één stuk slapen. Eerlijk gezegd: jaloers.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "De ogen van een struisvogel zijn groter dan zijn hersenen.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingo's worden grijs geboren. Hun roze kleur komt door de garnalen en algen die ze eten.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Eekhoorns planten per ongeluk duizenden bomen per jaar omdat ze vergeten waar ze hun nootjes hebben begraven.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "De eerste videogame in de ruimte was Tetris, gespeeld op een Game Boy door een kosmonaut in 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Spechten wikkelen hun tong om hun hersenen als schokdemper. Je tong als helm gebruiken is best wild.",
  },
  'fr': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Les corbeaux reconnaissent les visages et se souviennent pendant des années de ceux qui les ont maltraités, prévenant même les autres.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Les chats dorment 70% de leur vie. Un chat de 10 ans n'a donc passé que 3 ans éveillé.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Le miel ne se périme jamais. Des archéologues ont trouvé du miel vieux de 3000 ans dans des pyramides, encore comestible.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Les loutres de mer se tiennent la main en dormant pour ne pas être séparées par le courant.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Sur Vénus, un jour dure plus longtemps qu'une année. Elle tourne sur elle-même plus lentement qu'autour du Soleil.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Le briquet a été inventé avant l'allumette. Parfois, la technologie 'moderne' est plus ancienne qu'on ne le croit.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Les pieuvres ont trois cœurs et neuf cerveaux. L'oubli n'est pas vraiment une option pour elles.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Les vaches ont des 'meilleures amies' et peuvent stresser, voire pleurer, si on les sépare.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Le premier virus informatique s'appelait 'Creeper' et affichait : 'Je suis le Creeper, attrapez-moi si vous pouvez !'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Un nuage moyen pèse environ 500 000 kg, soit l'équivalent d'un troupeau d'éléphants flottant au-dessus de nos têtes.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "L'ADN humain est identique à 50% à celui d'une banane. Appeler une banane 'mon frère' n'est donc pas si faux.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "La peau des ours polaires est noire et leur fourrure transparente. Ils paraissent blancs grâce à la réfraction de la lumière.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "On ne peut pas pleurer dans l'espace. Sans gravité, les larmes ne coulent pas, elles forment une bulle dans l'œil.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "L'Everest grandit d'environ 4 mm par an. La Terre change en permanence.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Les souris qui 'sifflent' chantent en réalité, mais à une fréquence inaudible pour l'homme.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Les requins sont plus vieux que les arbres. Ils existent depuis 400 millions d'années, contre 350 millions pour les arbres.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Botaniquement, la banane est une baie, mais pas la fraise. La nature est étrange.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Une fourmi peut soulever 50 fois son poids. Si vous étiez une fourmi, vous pourriez soulever une voiture.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "En été, la Tour Eiffel grandit d'environ 15 cm à cause de la dilatation thermique du métal.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Le poids total de tous les humains sur Terre équivaut à peu près au poids total de toutes les fourmis.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Les paresseux peuvent retenir leur respiration sous l'eau plus longtemps que les dauphins (environ 40 min).",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Les pigeons distinguent les tableaux de Picasso de ceux de Monet. Ils sont plus artistes qu'on ne le pense.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Le GPS est gratuit, mais il coûte environ 2 millions de dollars par jour au gouvernement américain pour fonctionner.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "L'ornithorynque n'a pas d'estomac ; la nourriture passe directement de l'œsophage aux intestins.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "C'est Shakespeare qui a utilisé le mot 'swagger' (avoir du style) en premier. Il avait déjà la classe au 16ème siècle.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Le cœur de la baleine bleue est si grand qu'un humain pourrait nager dans ses artères.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Les fourmis n'ont pas de poumons et ne dorment jamais vraiment. Ce sont de minuscules bourreaux de travail.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Il pleut des diamants sur Saturne et Jupiter. On dirait qu'on vit sur la mauvaise planète.",
    "Honeybees can recognize human faces and remember them individually.":
        "Les abeilles peuvent reconnaître les visages humains et s'en souvenir.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "La sueur des hippopotames est rose et sert d'écran solaire et d'antibactérien.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Les crottes du wombat sont cubiques pour ne pas rouler, ce qui aide à marquer son territoire.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "La noix de cajou pousse à l'extérieur du fruit, suspendue au bout. Un design naturel surprenant.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Les requins sont plus vieux que les anneaux de Saturne. Ils étaient là des millions d'années avant eux.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Les papillons goûtent avec leurs pattes. Quand ils se posent sur une feuille, ils testent leur dîner.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Un escargot peut dormir trois ans sans se réveiller. Franchement, on dirait moi.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Les yeux de l'autruche sont plus gros que son cerveau.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Les flamants naissent gris. Leur couleur rose vient des crevettes et des algues qu'ils mangent.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Les écureuils plantent des milliers d'arbres par an simplement en oubliant où ils ont caché leurs noisettes.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Le premier jeu vidéo joué dans l'espace fut Tetris, sur une Game Boy, par un cosmonaute en 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Le pic-vert enroule sa langue autour de son cerveau pour amortir les chocs. Une langue-casque, c'est fou.",
  },
  'it': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "I corvi non solo riconoscono i volti, ma ricordano chi li ha trattati male per anni e avvertono gli altri corvi.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "I gatti dormono per il 70% della loro vita. Un gatto di 10 anni è stato sveglio solo per circa 3 anni.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Il miele non scade mai. Nelle piramidi egizie è stato trovato miele di 3.000 anni fa ancora commestibile.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Le lontre marine si tengono per mano mentre dormono per non essere separate dalla corrente.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Su Venere un giorno dura più di un anno. Ruota su se stesso più lentamente di quanto giri intorno al Sole.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "L'accendino è stato inventato prima del fiammifero. A volte la tecnologia 'vecchia' è più antica di quanto pensiamo.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "I polpi hanno tre cuori e nove cervelli. Dimenticare le cose non è un'opzione per loro.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Le mucche hanno 'migliori amiche' e si stressano molto, arrivando a piangere, se vengono separate.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Il primo virus informatico si chiamava 'Creeper' e mostrava il messaggio: 'Sono il Creeper, prendimi se ci riesci!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Una nuvola media pesa circa 500.000 kg, come un branco di elefanti che fluttua sopra di noi.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Il DNA umano è simile al 50% a quello di una banana. Chiamare una banana 'fratello' non è poi così sbagliato.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "La pelle degli orsi polari è nera e il pelo trasparente. Sembrano bianchi per via del riflesso della luce.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Nello spazio non si può piangere. Senza gravità, le lacrime non scendono, ma formano una bolla nell'occhio.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "L'Everest cresce di circa 4 millimetri l'anno. La Terra è in continuo cambiamento.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "I topi che 'fischiano' in realtà cantano, ma a una frequenza troppo alta per l'orecchio umano.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Gli squali sono più antichi degli alberi. Esistono da 400 milioni di anni, gli alberi solo da 350 milioni.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Botanicamente la banana è una bacca, ma la fragola no. La natura è strana.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Una formica solleva 50 volte il suo peso. Se fossi una formica, potresti sollevare un'auto da solo.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "In estate la Torre Eiffel si alza di circa 15 cm a causa dell'espansione termica del metallo.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Il peso totale di tutti gli esseri umani sulla Terra è quasi uguale a quello di tutte le formiche.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "I bradipi possono trattenere il respiro sott'acqua più a lungo dei delfini, fino a 40 minuti.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "I piccioni distinguono i quadri di Picasso da quelli di Monet. A quanto pare, ne sanno di arte.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Il GPS è gratuito, ma il governo USA spende circa 2 milioni di dollari al giorno per mantenerlo attivo.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "L'ornitorinco non ha lo stomaco; il cibo passa direttamente dall'esofago all'intestino.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Shakespeare fu il primo a usare la parola 'swagger' (spavalderia). Aveva stile già nel XVI secolo.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Il cuore della balenottera azzurra è così grande che un uomo potrebbe nuotare nelle sue arterie.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Le formiche non hanno polmoni e non dormono mai davvero. Sono piccole stacanoviste.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Su Saturno e Giove piovono letteralmente diamanti. Viviamo sul pianeta sbagliato.",
    "Honeybees can recognize human faces and remember them individually.":
        "Le api possono riconoscere i volti umani e ricordarseli.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Il sudore dell'ippopotamo è rosa e funge da crema solare e antibatterico.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "La cacca del vombato è cubica per non rotolare via e marcare meglio il territorio.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Gli anacardi crescono all'esterno del frutto, appesi all'estremità. Uno strano design della natura.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Gli squali sono più vecchi degli anelli di Saturno. Esistevano milioni di anni prima degli anelli.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Le farfalle sentono i sapori con le zampe. Quando si posano su una foglia, stanno assaggiando la cena.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Una lumaca può dormire per tre anni di fila. Onestamente, la capisco.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Gli occhi dello struzzo sono più grandi del suo cervello.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "I fenicotteri nascono grigi. Il rosa deriva dai gamberetti e dalle alghe che mangiano.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Gli scoiattoli piantano migliaia di alberi ogni anno semplicemente dimenticando dove hanno nascosto le noci.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Il primo videogioco nello spazio è stato Tetris, giocato su un Game Boy da un cosmonauta nel 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Il picchio avvolge la lingua attorno al cervello per proteggersi dai colpi. Usare la lingua come casco è geniale.",
  },
  'vi': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Quạ không chỉ nhớ mặt người, mà còn thù dai những ai đối xử tệ với chúng và cảnh báo cả đàn quạ khác.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Mèo dành 70% cuộc đời để ngủ. Vậy nên một con mèo 10 tuổi thực ra mới thức được có 3 năm.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Mật ong không bao giờ hỏng. Các nhà khảo cổ tìm thấy mật ong 3.000 năm tuổi trong Kim tự tháp vẫn ăn được.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Rái cá biển nắm tay nhau khi ngủ để không bị dòng nước cuốn trôi xa nhau.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Trên sao Kim, một ngày dài hơn một năm. Nó tự quay quanh trục còn chậm hơn quay quanh Mặt Trời.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Bật lửa được phát minh trước diêm. Đôi khi công nghệ 'cũ' lại mới hơn ta tưởng.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Bạch tuộc có 3 trái tim và 9 bộ não. Thế nên 'quên' không phải là lựa chọn của chúng.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Bò cũng có 'bạn thân'. Chúng sẽ bị stress nặng, thậm chí khóc nếu bị tách khỏi bạn mình.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Virus máy tính đầu tiên tên là 'Creeper', với thông điệp: 'Ta là Creeper, bắt ta nếu có thể!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Một đám mây trung bình nặng khoảng 500.000 kg – tương đương một đàn voi khổng lồ bay trên đầu bạn.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "DNA của người giống chuối đến 50%. Nên gọi quả chuối là 'người anh em' cũng không sai lắm.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Da gấu Bắc Cực thực ra màu đen, còn lông thì trong suốt. Chúng trông trắng là do phản xạ ánh sáng.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "Bạn không thể khóc trong vũ trụ. Không có trọng lực, nước mắt không chảy xuống mà tụ thành giọt ngay trong mắt.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Đỉnh Everest cao thêm khoảng 4mm mỗi năm. Trái đất vẫn đang thay đổi.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Chuột 'huýt sáo' thực ra là đang hát cho nhau nghe, nhưng ở tần số quá cao để người nghe thấy.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Cá mập già hơn cả cây cối. Cá mập có từ 400 triệu năm trước, cây cối mới 350 triệu năm.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Về mặt thực vật học, chuối là quả mọng, còn dâu tây thì không. Tự nhiên thật kỳ lạ.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Kiến có thể nâng vật nặng gấp 50 lần cơ thể. Nếu bạn là kiến, bạn có thể tự nâng một chiếc ô tô.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Tháp Eiffel cao thêm khoảng 15cm vào mùa hè do kim loại giãn nở vì nhiệt.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Tổng trọng lượng của tất cả con người trên Trái đất xấp xỉ tổng trọng lượng của loài kiến.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Con lười có thể nín thở dưới nước lâu hơn cá heo – lên tới 40 phút.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Bồ câu có thể phân biệt tranh của Picasso và Monet. Hóa ra chúng có gu nghệ thuật hơn ta tưởng.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "Dùng GPS thì miễn phí, nhưng chính phủ Mỹ tốn khoảng 2 triệu đô mỗi ngày để vận hành nó.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Thú mỏ vịt không có dạ dày; thức ăn đi thẳng từ thực quản xuống ruột.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Shakespeare là người đầu tiên dùng từ 'swagger' (phong cách/ngầu). Ông đã rất chất từ thế kỷ 16.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Tim cá voi xanh lớn đến mức con người có thể bơi trong động mạch của nó.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Kiến không có phổi và không bao giờ thực sự ngủ. Chúng là những kẻ cuồng công việc tí hon.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Trên sao Thổ và sao Mộc có mưa kim cương. Có vẻ chúng ta đang sống sai hành tinh rồi.",
    "Honeybees can recognize human faces and remember them individually.":
        "Ong mật có thể nhận diện và ghi nhớ khuôn mặt từng người.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Mồ hôi hà mã màu hồng, có tác dụng như kem chống nắng và chất kháng khuẩn.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Phân của gấu túi mũi trần (Wombat) hình khối vuông để không bị lăn đi, giúp đánh dấu lãnh thổ tốt hơn.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Hạt điều mọc bên ngoài quả, treo lủng lẳng ở dưới đáy. Một thiết kế kỳ lạ của tự nhiên.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Cá mập còn già hơn cả vành đai sao Thổ. Chúng đã ở đây hàng triệu năm trước khi sao Thổ có vòng đeo.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Bướm nếm mùi vị bằng chân. Khi đậu lên lá, thực ra chúng đang nếm thử bữa tối.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Ốc sên có thể ngủ liền 3 năm không dậy. Thật sự là ước mơ của tôi.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Mắt đà điểu còn to hơn cả não của nó.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Hồng hạc sinh ra có màu xám. Màu hồng là do tôm và tảo chúng ăn.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Sóc trồng hàng nghìn cây mỗi năm chỉ vì chúng quên mất chỗ chôn hạt dẻ.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Trò chơi điện tử đầu tiên trong vũ trụ là Tetris, được một phi hành gia chơi trên Game Boy năm 1993.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Chim gõ kiến quấn lưỡi quanh não để giảm chấn động. Dùng lưỡi làm mũ bảo hiểm, thật điên rồ.",
  },
  'th': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "อีกาไม่แค่จำหน้าคนได้ แต่ยังจำคนที่ทำร้ายมันได้เป็นปีๆ แถมยังไปเตือนอีกาตัวอื่นได้ด้วย",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "แมวใช้เวลา 70% ของชีวิตไปกับการนอน ดังนั้นแมวอายุ 10 ปี จริงๆ แล้วตื่นมาแค่ 3 ปีเอง",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "น้ำผึ้งไม่มีวันเสีย นักโบราณคดีเคยเจอน้ำผึ้งอายุ 3,000 ปีในพีระมิดที่ยังกินได้อยู่เลย",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "นากทะเลจะจับมือกันตอนนอน เพื่อไม่ให้กระแสน้ำพัดพวกมันแยกจากกัน",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "บนดาวศุกร์ 1 วันยาวนานกว่า 1 ปี เพราะมันหมุนรอบตัวเองช้ากว่าหมุนรอบดวงอาทิตย์",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "ไฟแช็กถูกประดิษฐ์ขึ้นก่อนไม้ขีดไฟ บางทีเทคโนโลยี 'สมัยใหม่' ก็เก่าแก่กว่าที่เราคิด",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "ปลาหมึกยักษ์มี 3 หัวใจและ 9 สมอง เรื่องขี้ลืมคงไม่ใช่ปัญหาของพวกมัน",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "วัวก็มี 'เพื่อนสนิท' นะ ถ้าถูกจับแยกกันพวกมันจะเครียดหนักมากจนร้องไห้ได้เลย",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "ไวรัสคอมพิวเตอร์ตัวแรกชื่อ 'Creeper' มันขึ้นข้อความว่า: 'ฉันคือ Creeper จับฉันให้ได้สิถ้าทำได้!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "เมฆก้อนหนึ่งอาจหนักถึง 500,000 กิโลกรัม เหมือนมีฝูงช้างลอยอยู่บนหัวเรา",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "DNA คนเราเหมือนกล้วยถึง 50% ดังนั้นถ้าจะเรียกกล้วยว่า 'พี่น้อง' ก็คงไม่ผิดนัก",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "จริงๆ แล้วหมีขั้วโลกผิวสีดำ ขนใส แต่ที่เห็นเป็นสีขาวเพราะการสะท้อนแสง",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "คุณร้องไห้ในอวกาศไม่ได้ เพราะไม่มีแรงโน้มถ่วง น้ำตาจะไม่ไหลลงมาแต่จะเกาะเป็นก้อนที่ตา",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "ยอดเขาเอเวอเรสต์สูงขึ้นปีละ 4 มิลลิเมตร โลกเรายังเปลี่ยนแปลงอยู่ตลอด",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "หนูที่ 'ผิวปาก' จริงๆ แล้วกำลังร้องเพลงจีบกัน แต่เสียงสูงเกินกว่าหูคนจะได้ยิน",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "ฉลามเกิดก่อนต้นไม้เสียอีก ฉลามมีมา 400 ล้านปี ส่วนต้นไม้เพิ่งมีมา 350 ล้านปี",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "ตามหลักพฤกษศาสตร์ กล้วยคือเบอร์รี่ แต่สตรอว์เบอร์รี่ไม่ใช่ โลกพืชมันซับซ้อนนะ",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "มดแบกของหนักกว่าตัวมันได้ 50 เท่า ถ้าคุณเป็นมด คุณคงยกรถทั้งคันได้สบายๆ",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "หอไอเฟลจะสูงขึ้น 15 ซม. ในหน้าร้อน เพราะเหล็กขยายตัวจากความร้อน",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "น้ำหนักรวมของคนทั้งโลก พอๆ กับน้ำหนักรวมของมดทั้งโลกเลยทีเดียว",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "สลอธกลั้นหายใจในน้ำได้นานกว่าโลมาอีก (ได้ถึง 40 นาทีเลยนะ)",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "นกพิราบแยกภาพวาดของปิกัสโซกับโมเนต์ได้ พวกมันมีหัวศิลปะกว่าที่เราคิด",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS ใช้ฟรีทั่วโลก แต่รัฐบาลสหรัฐฯ จ่ายวันละ 2 ล้านดอลลาร์เพื่อดูแลระบบนี้",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "ตุ่นปากเป็ดไม่มีกระเพาะ อาหารจะไหลจากหลอดอาหารลงลำไส้เลย",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "เชกสเปียร์เป็นคนแรกที่ใช้คำว่า 'swagger' (เท่/กร่าง) ตั้งแต่ศตวรรษที่ 16 พี่แกมีสไตล์จริงๆ",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "หัวใจวาฬสีน้ำเงินใหญ่มาก จนคนสามารถว่ายเข้าไปในเส้นเลือดแดงใหญ่ได้เลย",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "มดไม่มีปอดและไม่เคยหลับจริงๆ พวกมันคือยอดมนุษย์บ้างาน",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "บนดาวเสาร์และพฤหัสบดีมีฝนตกเป็นเพชร สงสัยเราจะอยู่ผิดดาวกันแล้ว",
    "Honeybees can recognize human faces and remember them individually.":
        "ผึ้งสามารถจำหน้าคนและแยกแยะแต่ละคนได้",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "เหงื่อฮิปโปเป็นสีชมพู ช่วยกันแดดและฆ่าเชื้อโรคได้ด้วย",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "อึของวอมแบตเป็นทรงสี่เหลี่ยมลูกบาศก์ เพื่อไม่ให้กลิ้งหนีและใช้บอกอาณาเขตได้",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "เม็ดมะม่วงหิมพานต์งอกอยู่นอกผล ห้อยต่องแต่งอยู่ข้างล่าง เป็นดีไซน์ที่แปลกดีนะ",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "ฉลามแก่กว่าวงแหวนดาวเสาร์เสียอีก พวกมันอยู่มาก่อนวงแหวนจะเกิดหลายล้านปี",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "ผีเสื้อใช้ขาชิมรสชาติ เวลาเกาะใบไม้คือพวกมันกำลังชิมอาหารเย็นอยู่",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "หอยทากสามารถหลับยาว 3 ปีโดยไม่ตื่นเลย อยากทำได้บ้างจัง",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "ตาของนกกระจอกเทศใหญ่กว่าสมองของมันซะอีก",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "ฟลามิงโก้เกิดมาตัวสีเทา สีชมพูได้มาจากการกินกุ้งและสาหร่าย",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "กระรอกช่วยปลูกต้นไม้ปีละหลายพันต้น เพียงเพราะพวกมันลืมว่าเอาถั่วไปฝังไว้ไหน",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "เกมแรกที่เล่นในอวกาศคือ Tetris บนเครื่อง Game Boy เมื่อปี 1993",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "นกหัวขวานเอาลิ้นพันรอบสมองเพื่อกันกระแทก ใช้ลิ้นเป็นหมวกกันน็อคเนี่ยนะ สุดยอดไปเลย",
  },
  'pl': {
    "Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.":
        "Wrony nie tylko rozpoznają twarze, ale pamiętają tych, którzy je skrzywdzili, a nawet ostrzegają inne wrony.",
    "Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.":
        "Koty przesypiają 70% życia. 10-letni kot był więc obudzony tylko przez około 3 lata.",
    "Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.":
        "Miód się nie psuje. Archeolodzy znaleźli w piramidach jadalny miód sprzed 3000 lat.",
    "Sea otters hold hands while they sleep so they don’t drift apart in the current.":
        "Wydry morskie trzymają się za ręce podczas snu, żeby prąd ich nie rozdzielił.",
    "On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.":
        "Na Wenus dzień trwa dłużej niż rok. Planeta obraca się wokół własnej osi wolniej niż wokół Słońca.",
    "The lighter was invented before the match—sometimes “old” tech is older than we think.":
        "Zapalniczkę wynaleziono przed zapałkami. Czasem 'nowa' technologia jest starsza niż myślimy.",
    "Octopuses have three hearts and nine brains—forgetting things isn’t really an option.":
        "Ośmiornice mają trzy serca i dziewięć mózgów – zapominanie raczej im nie grozi.",
    "Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.":
        "Krowy mają 'najlepsze przyjaciółki' i bardzo się stresują, a nawet płaczą, gdy się je rozdzieli.",
    "The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”":
        "Pierwszy wirus komputerowy nazywał się 'Creeper' i wyświetlał napis: 'Jestem Creeper, złap mnie, jeśli potrafisz!'",
    "An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.":
        "Przeciętna chmura waży około 500 000 kg – to jak stado słoni unoszące się nad głową.",
    "Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.":
        "Ludzkie DNA jest w 50% zgodne z DNA banana. Więc nazwanie banana 'bratem' nie jest tak całkiem bez sensu.",
    "Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.":
        "Niedźwiedzie polarne mają czarną skórę i przezroczyste futro. Wyglądają na białe przez odbicie światła.",
    "You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.":
        "W kosmosie nie da się płakać. Bez grawitacji łzy nie spływają, tylko tworzą kulę w oku.",
    "Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.":
        "Mount Everest rośnie o ok. 4 mm rocznie. Ziemia wciąż się zmienia.",
    "“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.":
        "Myszy, które 'gwiżdżą', tak naprawdę śpiewają do siebie, ale my tego nie słyszymy.",
    "Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.":
        "Rekiny są starsze niż drzewa. Rekiny są tu od 400 mln lat, drzewa od 350 mln.",
    "Bananas are botanically berries, but strawberries aren’t—botany can be weird.":
        "Botanicznie banan to jagoda, a truskawka nie. Botanika bywa dziwna.",
    "An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.":
        "Mrówka podnosi ciężar 50 razy większy od siebie. Gdybyś był mrówką, podniósłbyś samochód.",
    "The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.":
        "Latem Wieża Eiffla rośnie o ok. 15 cm przez rozszerzanie się metalu pod wpływem ciepła.",
    "The total weight of all humans on Earth is roughly comparable to the total weight of all ants.":
        "Łączna waga wszystkich ludzi na Ziemi jest mniej więcej równa wadze wszystkich mrówek.",
    "Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.":
        "Leniwce potrafią wstrzymać oddech pod wodą dłużej niż delfiny – nawet do 40 minut.",
    "Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.":
        "Gołębie odróżniają obrazy Picassa od Moneta. Znają się na sztuce lepiej niż myślimy.",
    "GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.":
        "GPS jest darmowy, ale rząd USA wydaje dziennie ok. 2 mln dolarów na jego utrzymanie.",
    "Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.":
        "Dziobak nie ma żołądka; jedzenie trafia z przełyku prosto do jelit.",
    "William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.":
        "Szekspir jako pierwszy użył słowa 'swagger' (lans). Już w XVI wieku miał styl.",
    "A blue whale’s heart is so large that a human could swim through its main arteries.":
        "Serce płetwala błękitnego jest tak duże, że człowiek mógłby pływać w jego tętnicach.",
    "Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.":
        "Mrówki nie mają płuc i nigdy tak naprawdę nie śpią. To małe pracoholiki.",
    "On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.":
        "Na Saturnie i Jowiszu pada deszcz diamentów. Chyba żyjemy na złej planecie.",
    "Honeybees can recognize human faces and remember them individually.":
        "Pszczoły potrafią rozpoznawać i zapamiętywać ludzkie twarze.",
    "Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.":
        "Pot hipopotama jest różowy i działa jak krem z filtrem oraz antybiotyk.",
    "Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.":
        "Kupa wombata jest sześcienna, żeby się nie turlała i lepiej znaczyła teren.",
    "Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.":
        "Nerkowce rosną na zewnątrz owocu, zwisając na samym dole. Dziwny projekt natury.",
    "Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.":
        "Rekiny są starsze niż pierścienie Saturna. Były tu miliony lat przed nimi.",
    "Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.":
        "Motyle czują smak nogami. Lądując na liściu, tak naprawdę próbują obiad.",
    "A snail can sleep for up to three years without waking up—honestly, relatable.":
        "Ślimak może spać 3 lata bez przerwy. Szczerze? Zazdroszczę.",
    "An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.":
        "Oczy strusia są większe od jego mózgu.",
    "Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.":
        "Flamingi rodzą się szare. Różowe stają się od jedzenia krewetek i alg.",
    "Squirrels help grow thousands of new trees each year because they forget where they buried nuts.":
        "Wiewiórki sadzą tysiące drzew rocznie, bo zapominają, gdzie zakopały orzechy.",
    "The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.":
        "Pierwszą grą w kosmosie był Tetris, zagrany na Game Boyu przez kosmonautę w 1993 roku.",
    "Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.":
        "Dzięcioł owija język wokół mózgu, by chronić go przed wstrząsami. Język jako kask – szalone.",
  },
};


