import 'dart:convert';

// Auto-generated tr/en phrase localizations for additional languages.
// Source language key is English phrase.

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

String _cleanLocalizedText(String value) {
  return _repairMojibakeText(value).trim();
}

String _normalizeLocalizationLookupKey(String value) {
  final String repaired = _repairMojibakeText(value);
  return repaired.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _looksLowQualityLocalizedText(String localized, String sourceEn) {
  final String loc = localized.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (loc.isEmpty) return true;
  return false;
}

String _normalizeTrEnLanguageCode(String lang) {
  final String code = lang.trim().toLowerCase().replaceAll('_', '-');
  if (code.isEmpty) return 'en';
  if (code == 'in') return 'id';
  if (code.startsWith('es')) {
    if (code == 'es-mx' || code == 'es-419') return 'es-mx';
    return 'es';
  }
  if (code.startsWith('fr-')) return code == 'fr-ca' ? 'fr-ca' : 'fr';
  if (code.startsWith('pt-')) return code == 'pt-pt' ? 'pt-pt' : 'pt';
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

String localizeTrEn(String lang, String tr, String en) {
  final String code = _normalizeTrEnLanguageCode(lang);
  if (code == 'tr') return _cleanLocalizedText(tr);
  if (code == 'en') return _cleanLocalizedText(en);

  final Map<String, String>? bucket = _trEnPhraseLocalizations[code];
  String? translated = bucket?[en];

  if (translated == null && bucket != null) {
    final String lookupKey = _normalizeLocalizationLookupKey(en);
    for (final MapEntry<String, String> entry in bucket.entries) {
      if (_normalizeLocalizationLookupKey(entry.key) == lookupKey) {
        translated = entry.value;
        break;
      }
    }
  }

  final String cleanEn = _cleanLocalizedText(en);
  if (translated == null) return cleanEn;
  final String clean = _cleanLocalizedText(translated);
  if (clean.isEmpty ||
      _looksLowQualityLocalizedText(clean, cleanEn) ||
      _looksLikeMojibake(clean)) {
    return cleanEn;
  }
  return clean;
}

const Map<String, Map<String, String>> _trEnPhraseLocalizations = {
  'de': {
    "Analysis Time!": "Analysezeit!",
    "CLOSE": "SCHLIESSEN",
    "SYSTEM UNDER MAINTENANCE": "SYSTEM IN WARTUNG",
    "Bio Planner": "Bio-Planer",
    "Store link not set.": "Store-Link nicht festgelegt.",
    "Invalid store link.": "Ungültiger Store-Link.",
    "Could not open the link.": "Der Link konnte nicht geöffnet werden.",
    "Please try again.": "Bitte versuchen Sie es erneut.",
    "Show error": "Fehler anzeigen",
    "Exception": "Ausnahme",
    "Load error": "Ladefehler",
    "Code": "Code",
    "Timeout": "Time-out",
    "REST probe failed: missing auth.":
        "REST-Prüfung fehlgeschlagen: Authentifizierung fehlt.",
    "REST probe success (Firestore endpoint reachable).":
        "REST-Prüfung erfolgreich (Firestore-Endpunkt erreichbar).",
    "REST probe failed (check logs).":
        "REST-Prüfung fehlgeschlagen (Protokolle prüfen).",
    "Firebase Auth probe failed.":
        "Die Firebase-Auth-Prüfung ist fehlgeschlagen.",
    "Firebase Auth probe success.": "Erfolgreicher Firebase-Auth-Test.",
    "Firebase token probe failed.":
        "Die Firebase-Token-Prüfung ist fehlgeschlagen.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITISCHER DIAGNOSEFEHLER",
    "COPY": "KOPIE",
    "OPEN LOGS": "OFFENE PROTOKOLLE",
    "Firebase": "Feuerbasis",
    "Store": "Speichern",
    "Copy all": "Alles kopieren",
    "Close": "Schließen",
    "Auth Probe": "Authentifizierungsprobe",
    "Write Test": "Test schreiben",
    "REST Probe": "REST-Probe",
    "Restore Test": "Test wiederherstellen",
    "Firebase auth error: user verification failed.":
        "Firebase-Authentifizierungsfehler: Benutzerüberprüfung fehlgeschlagen.",
    "Firestore test write successful.":
        "Firestore-Testschreibvorgang erfolgreich.",
    "Firestore test failed.": "Der Firestore-Test ist fehlgeschlagen.",
    "Firestore auth error: user verification failed.":
        "Firestore-Authentifizierungsfehler: Benutzerüberprüfung fehlgeschlagen.",
    "Firestore counter write failed.":
        "Das Schreiben des Firestore-Zählers ist fehlgeschlagen.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore-Authentifizierung fehlt: ig_users-Schreiben blockiert.",
    "Firestore ig_users write failed.":
        "Das Schreiben von Firestore ig_users ist fehlgeschlagen.",
    "User": "Benutzer",
    "Opening consent form...": "Einverständniserklärung wird geöffnet...",
    "Your consent preference was updated.":
        "Ihre Einwilligungspräferenz wurde aktualisiert.",
    "Consent update failed. Please try again.":
        "Die Aktualisierung der Einwilligung ist fehlgeschlagen. Bitte versuchen Sie es erneut.",
    "Your account is blocked": "Ihr Konto ist gesperrt",
    "Access is restricted for this account.":
        "Der Zugriff für dieses Konto ist eingeschränkt.",
    "Starting purchase...": "Kaufbeginn...",
    "Purchase cancelled.": "Kauf storniert.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktiv ✅ Werbung und Wartezeiten sind deaktiviert.",
    "Purchase failed. Please try again.":
        "Der Kauf ist fehlgeschlagen. Bitte versuchen Sie es erneut.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Eine Sitzungsüberprüfung ist erforderlich. Bitte verifizieren Sie Ihr Konto in der Instagram-App und versuchen Sie es erneut.",
    "Instagram returned no data.": "Instagram hat keine Daten zurückgegeben.",
    "Session verification failed. Please log in again.":
        "Die Sitzungsüberprüfung ist fehlgeschlagen. Bitte melden Sie sich erneut an.",
    "Open Instagram": "Öffne Instagram",
    "Instagram message": "Instagram-Nachricht",
    "Loading stories...": "Geschichten werden geladen...",
    "No data": "Keine Daten",
    "NEW": "NEU",
    "Login": "Login",
    "Session verified, redirecting...": "Sitzung bestätigt, Weiterleitung...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "WERBEFLÄCHE",
    "Admin mode active": "Admin-Modus aktiv",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Wir entwickeln uns jeden Tag weiter, um Ihnen ein besseres Erlebnis zu bieten. Ihr Feedback ist für uns wertvoll – wir würden uns freuen, von Ihnen zu hören!",
    "Please log in to start the analysis.":
        "Bitte melden Sie sich an, um die Analyse zu starten.",
    "Welcome, {username}": "Willkommen, {username}",
    "REFRESH DATA": "DATEN AKTUALISIEREN",
    "LOG IN WITH INSTAGRAM": "Mit Instagram anmelden",
    "Analyzing data...\nThis might take a moment.":
        "Analyzing data...\nDies kann einen Moment dauern.",
    "Processing data...\nAlmost done.":
        "Daten werden verarbeitet...\nFast fertig.",
    "Loading ad...\nPlease wait.": "Anzeige wird geladen...\nBitte warten.",
    "Google ad warning: {reason}": "Google-Anzeigenwarnung: {reason}",
    "All analysis is securely processed locally on your device.":
        "Alle Analysen werden sicher lokal auf Ihrem Gerät verarbeitet.",
    "Total analyses today: {count}": "Gesamtanalysen heute: {count}",
    "Next analysis": "Nächste Analyse",
    "Ready to scan.": "Bereit zum Scannen.",
    "Analysis available now": "Analyse jetzt verfügbar",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Die Analyse ist jetzt verfügbar, aber die gleichzeitige Ausführung von Analysen kann Ihr Konto gefährden.",
    "Please wait": "Bitte warten",
    "Warning": "Warnung",
    "Next analysis: {time}": "Nächste Analyse: {time}",
    "WATCH AD AND START ANALYSIS": "ANZEIGE ANSEHEN UND ANALYSE STARTEN",
    "START ANALYSIS": "ANALYSE STARTEN",
    "Start analysis?": "Analyse starten?",
    "Reset App Data": "App-Daten zurücksetzen",
    "This will wipe all local data and session cookies. Are you sure?":
        "Dadurch werden alle lokalen Daten und Sitzungscookies gelöscht. Bist du sicher?",
    "CANCEL": "STORNIEREN",
    "DELETE": "LÖSCHEN",
    "Error": "Fehler",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Datenabruf fehlgeschlagen: {err}\n\nFehlerbehebung: Versuchen Sie, sich abzumelden und erneut anzumelden.",
    "Followers": "Anhänger",
    "Following": "Nachfolgend",
    "New Followers": "Neue Follower",
    "Not Following Back": "Nicht folgen",
    "Lost Followers": "Verlorene Follower",
    "Legal Disclaimer": "Haftungsausschluss",
    "Unfollowed Users": "Nicht verfolgte Benutzer",
    "Rate Us": "Bewerten Sie uns",
    "Contact Us": "Kontaktieren Sie uns",
    "Remove Ads & Wait Times": "Entfernen Sie Werbung und Wartezeiten",
    "This box is currently under test.": "Diese Box wird derzeit getestet.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Sehen Sie sich Geschichten heimlich an oder zoomen Sie Profilfotos",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Bitte melden Sie sich an, um Geschichten heimlich anzusehen und Profilfotos zu vergrößern.",
    "Will be shown after the ad, please wait.":
        "Wird nach der Anzeige angezeigt, bitte warten.",
    "What would you like to do?": "Was möchten Sie tun?",
    "Enlarge profile photo": "Profilfoto vergrößern",
    "Watch story secretly": "Schau dir die Geschichte heimlich an",
    "No story data available.": "Keine Story-Daten verfügbar.",
    "I HAVE READ AND AGREE": "ICH HABE GELESEN UND STIMME ZU",
    "Withdraw Consent": "Einwilligung widerrufen",
    "Confirm": "Bestätigen",
    "Your consent settings will be reset. Are you sure?":
        "Ihre Einwilligungseinstellungen werden zurückgesetzt. Bist du sicher?",
    "Yes": "Ja",
    "Cancel": "Stornieren",
    "Session verified, redirecting securely...":
        "Sitzung überprüft, sichere Weiterleitung...",
    "Analysis complete ✅": "Analyse abgeschlossen ✅",
    "Purchases are not available right now. Please try again later.":
        "Käufe sind derzeit nicht möglich. Bitte versuchen Sie es später noch einmal.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Der Kauf wurde abgeschlossen, aber Premium ist noch nicht aktiv. Bitte versuchen Sie es erneut.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Willkommen bei Premium! Werbung und Wartezeiten werden entfernt.",
    "Your Premium membership is active.":
        "Ihre Premium-Mitgliedschaft ist aktiv.",
    "Restore Purchases": "Einkäufe wiederherstellen",
    "RESTORE": "WIEDERHERSTELLEN",
    "Restoring purchases...": "Einkäufe werden wiederhergestellt...",
    "Purchases restored ✅": "Einkäufe wiederhergestellt ✅",
    "No purchases to restore.": "Keine Käufe zum Wiederherstellen.",
    "Restore failed: {err}": "Wiederherstellung fehlgeschlagen: {err}",
    "Enter PIN": "PIN eingeben",
    "PIN accepted, timer reset ✅": "PIN akzeptiert, Timer zurückgesetzt ✅",
    "Invalid PIN": "Ungültige PIN",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Durch das Herunterladen und Verwenden dieser Anwendung wird davon ausgegangen, dass jeder Benutzer den folgenden Text „Nutzungsbedingungen und Haftungsausschluss“ im Voraus gelesen, verstanden und unwiderruflich akzeptiert hat:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artikel 1: Datenschutz und lokale Verarbeitungsarchitektur",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT ist eine „clientseitige“ Software. Die Anmeldedaten des Nutzers (Benutzername, Passwort, Sitzungscookies) werden unter keinen Umständen an einen externen Server übermittelt oder dort gespeichert. Sämtliche Datenverarbeitungsaktivitäten erfolgen ausschließlich im temporären Speicher (RAM) und im lokalen Speicher des Geräts des Nutzers. Die Anwendung fungiert als „Browser-Wrapper“, der über die Instagram-Oberfläche läuft.",
    "Article 2: Third-Party Platform Risks":
        "Artikel 2: Risiken der Plattform Dritter",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) behält sich das Recht vor, die Nutzung von Software Dritter gemäß seinen Plattformrichtlinien einzuschränken. Alle Risiken, einschließlich, aber nicht beschränkt auf „Aktionssperren“, „Kontobeschränkungen“, „Shadowbans“ oder „Kontoschließungen“, die sich aus der Nutzung der Anwendung ergeben können, liegen ausschließlich beim Benutzer. Der VERDICT-Entwickler kann nicht für direkte oder indirekte Schäden haftbar gemacht werden, die sich aus solchen Verwaltungssanktionen ergeben.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artikel 3: Gewährleistungsausschluss und Haftungsbeschränkung",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Diese Software wird „WIE BESEHEN“ und „WIE VERFÜGBAR“ bereitgestellt. Die 100-prozentige Genauigkeit, Kontinuität oder Marktgängigkeit der von der Software bereitgestellten Analyseergebnisse wird nicht garantiert. Der Nutzer erkennt an, dass sämtliche Ergebnisse, die sich aus rechtlichen oder kommerziellen Transaktionen auf der Grundlage von Anwendungsdaten ergeben, in seiner eigenen Verantwortung liegen; und erklärt und verpflichtet sich, den Entwickler von allen Ansprüchen, Klagen und Beschwerden schadlos zu halten.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artikel 4: Mitteilung über geistiges Eigentum und Unabhängigkeit",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT ist ein unabhängiges Entwicklerprojekt. Die Marken „Instagram“, „Facebook“ und „Meta“ sind eingetragene Marken von Meta Platforms, Inc. Diese Anwendung hat keine kommerzielle Partnerschaft, Sponsoringvereinbarung oder offizielle Zugehörigkeit mit den oben genannten Unternehmen.",
    "Article 5: Service Continuity and Platform Changes":
        "Artikel 5: Servicekontinuität und Plattformänderungen",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Grundlegende Änderungen an der Instagram-API oder der Web-Infrastruktur können dazu führen, dass die Anwendung ihre Funktionalität teilweise oder vollständig verliert. Der Entwickler übernimmt keine Verpflichtung, die Anwendung zu aktualisieren oder den Dienst als Reaktion auf solche infrastrukturellen Änderungen, die als „höhere Gewalt“ gelten, aufrechtzuerhalten.",
    "Analysis complete, results will be shown after the ad.":
        "Analyse abgeschlossen, Ergebnisse werden nach der Anzeige angezeigt.",
    "Analysis failed": "Die Analyse ist fehlgeschlagen",
    "Reason: {reason}": "Grund: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tipp: Abmelden und erneutes Anmelden kann hilfreich sein.",
    "Quick check: Counts are the same. No changes detected.":
        "Kurzer Check: Die Zählungen sind gleich. Keine Änderungen festgestellt.",
    "Daily Metrics": "Tägliche Kennzahlen",
    "Active users": "Aktive Benutzer",
    "Daily queries": "Tägliche Anfragen",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Das Laden der Daten wurde unterbrochen: Follower-Daten unvollständig ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Das Laden der Daten wurde unterbrochen: Folgende Daten unvollständig ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Das Laden der Daten wurde unterbrochen: Instagram hat leere Daten zurückgegeben.",
    "Data loading stopped due to an unexpected error.":
        "Das Laden der Daten wurde aufgrund eines unerwarteten Fehlers gestoppt.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram hat eine Warnung vor automatisiertem Verhalten zurückgegeben. Aus Sicherheitsgründen haben wir den Datenabruf eingestellt.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram hat eine Sicherheitsüberprüfung angefordert. Überprüfen Sie dies in der Instagram-App und versuchen Sie es erneut.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Die Sitzung ist ungültig oder wartet auf Bestätigung. Bitte melden Sie sich erneut an.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Es wurden zu viele Anfragen gesendet. Das Laden der Daten wurde aus Sicherheitsgründen unterbrochen.",
    "Data loading could not complete due to a connection issue.":
        "Das Laden der Daten konnte aufgrund eines Verbindungsproblems nicht abgeschlossen werden.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram hat einen Fehler zurückgegeben (HTTP {code}). Das Laden der Daten wurde unterbrochen.",
    "Instagram security verification is required (story data could not be fetched).":
        "Es ist eine Instagram-Sicherheitsüberprüfung erforderlich (Story-Daten konnten nicht abgerufen werden).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Story-Daten konnten nicht abgerufen werden. Normalerweise wird dies durch eine Instagram-Verifizierung, vorübergehende API-Einschränkungen oder eine Verbindungsunterbrechung verursacht. Bitte versuchen Sie es in 2-3 Minuten erneut.",
    "Could not fetch story data. Please try again shortly.":
        "Story-Daten konnten nicht abgerufen werden. Bitte versuchen Sie es in Kürze noch einmal.",
    "Secret Mode": "Geheimmodus",
    "Starting VERDICT...": "VERDICT wird gestartet...",
    "DID YOU KNOW?": "WUSSTEN SIE?",
    "Estimated time left: {time}": "Geschätzte verbleibende Zeit: {time}",
    "Estimating remaining time...": "Die verbleibende Zeit wird geschätzt...",
    "LOG OUT": "Abmelden",
    "Open Profile": "Profil öffnen",
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
    "Analysis Time!": "분석 시간!",
    "CLOSE": "닫다",
    "SYSTEM UNDER MAINTENANCE": "유지보수 중인 시스템",
    "Bio Planner": "바이오 플래너",
    "Store link not set.": "스토어 링크가 설정되지 않았습니다.",
    "Invalid store link.": "잘못된 매장 링크입니다.",
    "Could not open the link.": "링크를 열 수 없습니다.",
    "Please try again.": "다시 시도해 주세요.",
    "Show error": "오류 표시",
    "Exception": "예외",
    "Load error": "로드 오류",
    "Code": "암호",
    "Timeout": "시간 초과",
    "REST probe failed: missing auth.": "REST 프로브 실패: 인증이 누락되었습니다.",
    "REST probe success (Firestore endpoint reachable).":
        "REST 프로브 성공(Firestore 엔드포인트에 도달 가능)",
    "REST probe failed (check logs).": "REST 프로브가 실패했습니다(로그 확인).",
    "Firebase Auth probe failed.": "Firebase 인증 프로브에 실패했습니다.",
    "Firebase Auth probe success.": "Firebase 인증 프로브가 성공했습니다.",
    "Firebase token probe failed.": "Firebase 토큰 조사에 실패했습니다.",
    "CRITICAL DIAGNOSTIC ERROR": "심각한 진단 오류",
    "COPY": "복사",
    "OPEN LOGS": "오픈 로그",
    "Firebase": "중포 기지",
    "Store": "가게",
    "Copy all": "모두 복사",
    "Close": "닫다",
    "Auth Probe": "인증 프로브",
    "Write Test": "테스트 작성",
    "REST Probe": "REST 프로브",
    "Restore Test": "복원 테스트",
    "Firebase auth error: user verification failed.":
        "Firebase 인증 오류: 사용자 확인에 실패했습니다.",
    "Firestore test write successful.": "Firestore 테스트 쓰기에 성공했습니다.",
    "Firestore test failed.": "Firestore 테스트에 실패했습니다.",
    "Firestore auth error: user verification failed.":
        "Firestore 인증 오류: 사용자 확인에 실패했습니다.",
    "Firestore counter write failed.": "Firestore 카운터 쓰기에 실패했습니다.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore 인증 누락: ig_users 쓰기가 차단되었습니다.",
    "Firestore ig_users write failed.": "Firestore ig_users 쓰기에 실패했습니다.",
    "User": "사용자",
    "Opening consent form...": "동의서를 여는 중...",
    "Your consent preference was updated.": "동의 기본 설정이 업데이트되었습니다.",
    "Consent update failed. Please try again.": "동의 업데이트에 실패했습니다. 다시 시도해 주세요.",
    "Your account is blocked": "귀하의 계정이 차단되었습니다",
    "Access is restricted for this account.": "이 계정에 대한 액세스가 제한되어 있습니다.",
    "Starting purchase...": "구매 시작 중...",
    "Purchase cancelled.": "구매가 취소되었습니다.",
    "Premium active ✅ Ads and wait times are disabled.":
        "프리미엄 활성 ✅ 광고 및 대기 시간이 비활성화됩니다.",
    "Purchase failed. Please try again.": "구매에 실패했습니다. 다시 시도해 주세요.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "세션 확인이 필요합니다. Instagram 앱에서 계정을 확인한 후 다시 시도해 주세요.",
    "Instagram returned no data.": "Instagram은 데이터를 반환하지 않았습니다.",
    "Session verification failed. Please log in again.":
        "세션 확인에 실패했습니다. 다시 로그인해주세요.",
    "Open Instagram": "인스타그램 열기",
    "Instagram message": "인스타그램 메시지",
    "Loading stories...": "스토리 로드 중...",
    "No data": "데이터 없음",
    "NEW": "새로운",
    "Login": "로그인",
    "Session verified, redirecting...": "세션이 확인되었습니다. 리디렉션 중...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "광고 공간",
    "Admin mode active": "관리자 모드 활성화",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "우리는 더 나은 경험을 제공하기 위해 매일 진화하고 있습니다. 귀하의 피드백은 우리에게 소중합니다. 귀하의 의견을 듣고 싶습니다!",
    "Please log in to start the analysis.": "분석을 시작하려면 로그인하세요.",
    "Welcome, {username}": "환영합니다, {username}",
    "REFRESH DATA": "데이터 새로 고침",
    "LOG IN WITH INSTAGRAM": "인스타그램으로 로그인",
    "Analyzing data...\nThis might take a moment.":
        "데이터 분석 중...\n잠시 시간이 걸릴 수 있습니다.",
    "Processing data...\nAlmost done.": "데이터 처리 중...\n거의 완료되었습니다.",
    "Loading ad...\nPlease wait.": "광고 로드 중...\n기다려 주십시오.",
    "Google ad warning: {reason}": "Google 광고 경고: {reason}",
    "All analysis is securely processed locally on your device.":
        "모든 분석은 귀하의 장치에서 로컬로 안전하게 처리됩니다.",
    "Total analyses today: {count}": "오늘의 총 분석: {count}",
    "Next analysis": "다음 분석",
    "Ready to scan.": "스캔할 준비가 되었습니다.",
    "Analysis available now": "지금 분석 가능",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "현재 분석이 가능하지만 연속적으로 분석을 실행하면 계정이 위험해질 수 있습니다.",
    "Please wait": "기다리세요",
    "Warning": "경고",
    "Next analysis: {time}": "다음 분석: {time}",
    "WATCH AD AND START ANALYSIS": "광고를 시청하고 분석을 시작하세요",
    "START ANALYSIS": "분석 시작",
    "Start analysis?": "분석을 시작하시겠습니까?",
    "Reset App Data": "앱 데이터 재설정",
    "This will wipe all local data and session cookies. Are you sure?":
        "이렇게 하면 모든 로컬 데이터와 세션 쿠키가 지워집니다. 확실합니까?",
    "CANCEL": "취소",
    "DELETE": "삭제",
    "Error": "오류",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "데이터 검색 실패: {err}\n\n문제 해결: 로그아웃했다가 다시 로그인해 보세요.",
    "Followers": "추종자",
    "Following": "수행원",
    "New Followers": "새로운 추종자",
    "Not Following Back": "뒤를 따르지 않음",
    "Lost Followers": "잃어버린 추종자",
    "Legal Disclaimer": "법적 고지 사항",
    "Unfollowed Users": "팔로우되지 않은 사용자",
    "Rate Us": "우리를 평가해 주세요",
    "Contact Us": "문의하기",
    "Remove Ads & Wait Times": "광고 및 대기 시간 제거",
    "This box is currently under test.": "이 상자는 현재 테스트 중입니다.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "비밀리에 스토리를 시청하거나 프로필 사진을 확대/축소하세요",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "스토리를 비밀리에 시청하고 프로필 사진을 확대하려면 로그인하세요.",
    "Will be shown after the ad, please wait.": "광고 후 표시됩니다. 잠시만 기다려주세요.",
    "What would you like to do?": "무엇을 하고 싶나요?",
    "Enlarge profile photo": "프로필 사진 확대",
    "Watch story secretly": "몰래 스토리 보기",
    "No story data available.": "스토리 데이터가 없습니다.",
    "I HAVE READ AND AGREE": "나는 읽었으며 이에 동의합니다.",
    "Withdraw Consent": "동의 철회",
    "Confirm": "확인하다",
    "Your consent settings will be reset. Are you sure?":
        "동의 설정이 재설정됩니다. 확실합니까?",
    "Yes": "예",
    "Cancel": "취소",
    "Session verified, redirecting securely...":
        "세션이 확인되었습니다. 안전하게 리디렉션 중입니다...",
    "Analysis complete ✅": "분석 완료 ✅",
    "Purchases are not available right now. Please try again later.":
        "지금은 구매할 수 없습니다. 나중에 다시 시도해 주세요.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "구매가 완료되었지만 프리미엄이 아직 활성화되지 않았습니다. 다시 시도해 주세요.",
    "Welcome to Premium! Ads and wait times are removed.":
        "프리미엄에 오신 것을 환영합니다! 광고 및 대기 시간이 제거됩니다.",
    "Your Premium membership is active.": "귀하의 프리미엄 멤버십이 활성화되었습니다.",
    "Restore Purchases": "구매 복원",
    "RESTORE": "복원하다",
    "Restoring purchases...": "구매 복원 중...",
    "Purchases restored ✅": "구매 내역이 복원되었습니다 ✅",
    "No purchases to restore.": "복원할 구매가 없습니다.",
    "Restore failed: {err}": "복원 실패: {err}",
    "Enter PIN": "PIN 입력",
    "PIN accepted, timer reset ✅": "PIN 승인, 타이머 재설정 ✅",
    "Invalid PIN": "잘못된 PIN",
    "OK": "좋아요",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "이 애플리케이션을 다운로드하고 사용함으로써 모든 사용자는 아래의 \"이용 약관 및 면책 조항\" 텍스트를 사전에 읽고, 이해하고, 최종적으로 동의한 것으로 간주됩니다.",
    "Article 1: Data Privacy and Local Processing Architecture":
        "기사 1: 데이터 개인정보 보호 및 로컬 처리 아키텍처",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT는 '클라이언트 측' 소프트웨어입니다. 사용자의 로그인 자격 증명(사용자 이름, 비밀번호, 세션 쿠키)은 어떠한 경우에도 외부 서버로 전송되거나 외부 서버에 저장되지 않습니다. 모든 데이터 처리 활동은 사용자 장치의 임시 메모리(RAM)와 로컬 저장소 내에서만 발생합니다. 이 애플리케이션은 Instagram 인터페이스를 통해 작동하는 '브라우저 래퍼' 역할을 합니다.",
    "Article 2: Third-Party Platform Risks": "조항 2: 제3자 플랫폼 위험",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram(Meta Platforms, Inc.)은 플랫폼 정책에 따라 타사 소프트웨어의 사용을 제한할 권리를 보유합니다. 애플리케이션 사용으로 인해 발생할 수 있는 '작업 차단', '계정 제한', '섀도우 금지' 또는 '계정 폐쇄'를 포함하되 이에 국한되지 않는 모든 위험은 전적으로 사용자에게 속합니다. VERDICT 개발자는 이러한 행정적 제재로 인해 발생한 직간접적 손해에 대해 책임을 지지 않습니다.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "제3조: 보증 부인 및 책임 제한",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "이 소프트웨어는 '있는 그대로' 및 '사용 가능한 대로' 제공됩니다. 소프트웨어에서 제공하는 분석 결과의 100% 정확성, 연속성 또는 상품성은 보장되지 않습니다. 사용자는 애플리케이션 데이터를 기반으로 한 법적 또는 상업적 거래로 인해 발생하는 모든 결과가 자신의 책임임을 인정합니다. 모든 청구, 소송 및 불만 사항으로부터 개발자를 보호할 것을 선언하고 약속합니다.",
    "Article 4: Intellectual Property and Independence Notice":
        "제4조: 지적재산권 및 독립성 고지",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT는 독립 개발자 프로젝트입니다. 'Instagram', 'Facebook' 및 'Meta' 브랜드는 Meta Platforms, Inc.의 등록 상표입니다. 이 애플리케이션은 앞서 언급한 회사와 상업적 파트너십, 후원 계약 또는 공식 제휴 관계가 없습니다.",
    "Article 5: Service Continuity and Platform Changes":
        "제5조: 서비스 연속성 및 플랫폼 변경",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Instagram API 또는 웹 인프라의 근본적인 변경으로 인해 애플리케이션의 기능이 부분적으로 또는 완전히 손실될 수 있습니다. 개발자는 \"불가항력\"으로 간주되는 이러한 인프라 변경에 대응하여 애플리케이션을 업데이트하거나 서비스를 유지하겠다는 약속을 하지 않습니다.",
    "Analysis complete, results will be shown after the ad.":
        "분석이 완료되었습니다. 결과는 광고 후에 표시됩니다.",
    "Analysis failed": "분석 실패",
    "Reason: {reason}": "이유: {reason}",
    "Tip: Logging out and logging back in may help.":
        "팁: 로그아웃했다가 다시 로그인하면 도움이 될 수 있습니다.",
    "Quick check: Counts are the same. No changes detected.":
        "빠른 확인: 개수가 동일합니다. 변경사항이 감지되지 않았습니다.",
    "Daily Metrics": "일일 지표",
    "Active users": "활성 사용자",
    "Daily queries": "일일 쿼리",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "데이터 로드가 중단되었습니다. 팔로어 데이터가 불완전합니다({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "데이터 로드가 중단되었습니다. 다음 데이터가 불완전합니다({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "데이터 로드가 중단되었습니다. Instagram이 빈 데이터를 반환했습니다.",
    "Data loading stopped due to an unexpected error.":
        "예상치 못한 오류로 인해 데이터 로딩이 중단되었습니다.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram이 자동 행동 경고를 반환했습니다. 안전을 위해 데이터 가져오기를 중단했습니다.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "인스타그램에서 보안 확인을 요청했습니다. Instagram 앱에서 인증하고 다시 시도하세요.",
    "Session is invalid or waiting for verification. Please log in again.":
        "세션이 잘못되었거나 확인을 기다리고 있습니다. 다시 로그인해주세요.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "요청이 너무 많이 전송되었습니다. 안전을 위해 데이터 로딩이 중단되었습니다.",
    "Data loading could not complete due to a connection issue.":
        "연결 문제로 인해 데이터 로드를 완료할 수 없습니다.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram에서 오류(HTTP {code})를 반환했습니다. 데이터 로딩이 중단되었습니다.",
    "Instagram security verification is required (story data could not be fetched).":
        "인스타그램 보안 확인이 필요합니다(스토리 데이터를 가져올 수 없습니다).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "스토리 데이터를 가져올 수 없습니다. 일반적으로 이는 Instagram 인증, 임시 API 제한 또는 연결 중단으로 인해 발생합니다. 2~3분 후에 다시 시도해 주세요.",
    "Could not fetch story data. Please try again shortly.":
        "스토리 데이터를 가져올 수 없습니다. 잠시 후 다시 시도해 주세요.",
    "Secret Mode": "비밀 모드",
    "Starting VERDICT...": "판정 시작 중...",
    "DID YOU KNOW?": "알고 계셨나요?",
    "Estimated time left: {time}": "남은 예상 시간: {time}",
    "Estimating remaining time...": "남은 시간 추정 중...",
    "LOG OUT": "로그아웃",
    "Open Profile": "프로필 열기",
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
    "Analysis Time!": "分析タイム！",
    "CLOSE": "近い",
    "SYSTEM UNDER MAINTENANCE": "システムメンテナンス中",
    "Bio Planner": "バイオプランナー",
    "Store link not set.": "ストアリンクが設定されていません。",
    "Invalid store link.": "ストアリンクが無効です。",
    "Could not open the link.": "リンクを開けませんでした。",
    "Please try again.": "もう一度試してください。",
    "Show error": "エラーを表示",
    "Exception": "例外",
    "Load error": "ロードエラー",
    "Code": "コード",
    "Timeout": "タイムアウト",
    "REST probe failed: missing auth.": "REST プローブが失敗しました: 認証がありません。",
    "REST probe success (Firestore endpoint reachable).":
        "REST プローブが成功しました (Firestore エンドポイントに到達可能)。",
    "REST probe failed (check logs).": "REST プローブが失敗しました (ログを確認してください)。",
    "Firebase Auth probe failed.": "Firebase 認証プローブが失敗しました。",
    "Firebase Auth probe success.": "Firebase Auth プローブが成功しました。",
    "Firebase token probe failed.": "Firebase トークン プローブが失敗しました。",
    "CRITICAL DIAGNOSTIC ERROR": "重大な診断エラー",
    "COPY": "コピー",
    "OPEN LOGS": "ログを開く",
    "Firebase": "ファイアベース",
    "Store": "店",
    "Copy all": "すべてコピー",
    "Close": "近い",
    "Auth Probe": "認証プローブ",
    "Write Test": "書き込みテスト",
    "REST Probe": "RESTプローブ",
    "Restore Test": "復元テスト",
    "Firebase auth error: user verification failed.":
        "Firebase 認証エラー: ユーザー認証に失敗しました。",
    "Firestore test write successful.": "Firestore テスト書き込みが成功しました。",
    "Firestore test failed.": "Firestore テストが失敗しました。",
    "Firestore auth error: user verification failed.":
        "Firestore 認証エラー: ユーザー認証に失敗しました。",
    "Firestore counter write failed.": "Firestore カウンターの書き込みに失敗しました。",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore 認証がありません: ig_users の書き込みがブロックされました。",
    "Firestore ig_users write failed.": "Firestore ig_users の書き込みに失敗しました。",
    "User": "ユーザー",
    "Opening consent form...": "同意フォームを開く...",
    "Your consent preference was updated.": "同意設定が更新されました。",
    "Consent update failed. Please try again.": "同意の更新に失敗しました。もう一度試してください。",
    "Your account is blocked": "あなたのアカウントはブロックされています",
    "Access is restricted for this account.": "このアカウントへのアクセスは制限されています。",
    "Starting purchase...": "購入を開始しています...",
    "Purchase cancelled.": "購入はキャンセルされました。",
    "Premium active ✅ Ads and wait times are disabled.":
        "プレミアムが有効です ✅ 広告と待ち時間は無効になっています。",
    "Purchase failed. Please try again.": "購入に失敗しました。もう一度試してください。",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "セッションの検証が必要です。 Instagram アプリでアカウントを確認して、もう一度お試しください。",
    "Instagram returned no data.": "Instagram はデータを返しませんでした。",
    "Session verification failed. Please log in again.":
        "セッションの検証に失敗しました。再度ログインしてください。",
    "Open Instagram": "インスタグラムを開く",
    "Instagram message": "インスタグラムのメッセージ",
    "Loading stories...": "ストーリーを読み込んでいます...",
    "No data": "データなし",
    "NEW": "新しい",
    "Login": "ログイン",
    "Session verified, redirecting...": "セッションが確認されました、リダイレクト中...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "広告スペース",
    "Admin mode active": "管理者モードがアクティブです",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "より良い体験を提供できるよう、私たちは日々進化しています。皆様からのフィードバックは私たちにとって貴重なものです。ぜひお聞かせください。",
    "Please log in to start the analysis.": "分析を開始するにはログインしてください。",
    "Welcome, {username}": "ようこそ、{username}",
    "REFRESH DATA": "データを更新",
    "LOG IN WITH INSTAGRAM": "インスタグラムでログイン",
    "Analyzing data...\nThis might take a moment.":
        "データを分析中...\nこれには少し時間がかかる場合があります。",
    "Processing data...\nAlmost done.": "データを処理中...\nほぼ完了しました。",
    "Loading ad...\nPlease wait.": "広告を読み込んでいます...\nお待ちください。",
    "Google ad warning: {reason}": "Google 広告の警告: {reason}",
    "All analysis is securely processed locally on your device.":
        "すべての分析はデバイス上でローカルに安全に処理されます。",
    "Total analyses today: {count}": "今日の分析合計: {count}",
    "Next analysis": "次の分析",
    "Ready to scan.": "スキャンの準備ができました。",
    "Analysis available now": "分析が可能になりました",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "分析は現在利用可能ですが、分析を連続して実行するとアカウントが危険にさらされる可能性があります。",
    "Please wait": "お待ちください",
    "Warning": "警告",
    "Next analysis: {time}": "次の分析: {time}",
    "WATCH AD AND START ANALYSIS": "広告を見て分析を開始",
    "START ANALYSIS": "分析を開始する",
    "Start analysis?": "分析を開始しますか?",
    "Reset App Data": "アプリデータをリセット",
    "This will wipe all local data and session cookies. Are you sure?":
        "これにより、すべてのローカル データとセッション Cookie が消去されます。本気ですか？",
    "CANCEL": "キャンセル",
    "DELETE": "消去",
    "Error": "エラー",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "データの取得に失敗しました: {err}\n\nトラブルシューティング: ログアウトしてから再度ログインしてみてください。",
    "Followers": "フォロワー",
    "Following": "続く",
    "New Followers": "新しいフォロワー",
    "Not Following Back": "フォローバックしていない",
    "Lost Followers": "失われたフォロワー",
    "Legal Disclaimer": "法的免責事項",
    "Unfollowed Users": "フォローを解除されたユーザー",
    "Rate Us": "評価してください",
    "Contact Us": "お問い合わせ",
    "Remove Ads & Wait Times": "広告と待ち時間を削除",
    "This box is currently under test.": "このボックスは現在テスト中です。",
    "Watch Stories Secretly or Zoom Profile Photos":
        "ストーリーをこっそり見るか、プロフィール写真をズームする",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "ストーリーをこっそり見たり、プロフィール写真を拡大するにはログインしてください。",
    "Will be shown after the ad, please wait.": "広告の後に表示されますのでお待ちください。",
    "What would you like to do?": "何をしたいですか?",
    "Enlarge profile photo": "プロフィール写真を拡大する",
    "Watch story secretly": "ストーリーをこっそり見る",
    "No story data available.": "ストーリーデータはありません。",
    "I HAVE READ AND AGREE": "読んで同意します",
    "Withdraw Consent": "同意の撤回",
    "Confirm": "確認する",
    "Your consent settings will be reset. Are you sure?":
        "同意設定がリセットされます。本気ですか？",
    "Yes": "はい",
    "Cancel": "キャンセル",
    "Session verified, redirecting securely...":
        "セッションが検証され、安全にリダイレクトされています...",
    "Analysis complete ✅": "分析完了 ✅",
    "Purchases are not available right now. Please try again later.":
        "現在購入はできません。後でもう一度試してください。",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "購入は完了しましたが、プレミアムはまだ有効になっていません。もう一度試してください。",
    "Welcome to Premium! Ads and wait times are removed.":
        "プレミアムへようこそ!広告と待ち時間が削除されます。",
    "Your Premium membership is active.": "プレミアム メンバーシップは有効です。",
    "Restore Purchases": "購入を復元する",
    "RESTORE": "復元する",
    "Restoring purchases...": "購入を復元しています...",
    "Purchases restored ✅": "購入が復元されました ✅",
    "No purchases to restore.": "復元する購入はありません。",
    "Restore failed: {err}": "復元に失敗しました: {err}",
    "Enter PIN": "PINを入力してください",
    "PIN accepted, timer reset ✅": "PIN が受け入れられ、タイマーがリセットされました ✅",
    "Invalid PIN": "無効なPIN",
    "OK": "わかりました",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "このアプリケーションをダウンロードして使用することにより、すべてのユーザーは、以下の「利用規約および免責事項」のテキストを事前に読み、理解し、取り消し不能の形で同意したものとみなされます。",
    "Article 1: Data Privacy and Local Processing Architecture":
        "第 1 条: データプライバシーとローカル処理アーキテクチャ",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT は「クライアント側」ソフトウェアです。ユーザーのログイン資格情報 (ユーザー名、パスワード、セッション Cookie) は、いかなる状況でも外部サーバーに送信されたり、外部サーバーに保存されたりすることはありません。すべてのデータ処理アクティビティは、ユーザーのデバイスの一時メモリ (RAM) およびローカル ストレージ内でのみ発生します。このアプリケーションは、Instagram インターフェイス上で動作する「ブラウザ ラッパー」として機能します。",
    "Article 2: Third-Party Platform Risks": "第 2 条: サードパーティ プラットフォームのリスク",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) は、プラットフォーム ポリシーに従ってサードパーティ ソフトウェアの使用を制限する権利を留保します。アプリケーションの使用から生じる可能性のある「アクションブロック」、「アカウント制限」、「シャドウバン」、または「アカウント閉鎖」を含むがこれらに限定されないすべてのリスクは、ユーザーにのみ帰属します。 VERDICT 開発者は、そのような行政制裁に起因する直接的または間接的な損害に対して責任を負うことはできません。",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "第 3 条: 保証の免責および責任の制限",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "このソフトウェアは「現状のまま」および「利用可能な状態」で提供されます。ソフトウェアによって提供される分析結果の 100% の精度、継続性、または商品性は保証されません。ユーザーは、アプリケーションデータに基づく法的取引または商業取引から生じるいかなる結果も自己責任であることを承認します。そして、開発者をあらゆる請求、訴訟、苦情から免責することを宣言し、約束します。",
    "Article 4: Intellectual Property and Independence Notice":
        "第 4 条: 知的財産および独立性に関する通知",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT は独立した開発者プロジェクトです。 「Instagram」、「Facebook」、および「Meta」ブランドは、Meta Platforms, Inc. の登録商標です。このアプリケーションには、前述の企業との商業提携、スポンサー契約、または正式な提携はありません。",
    "Article 5: Service Continuity and Platform Changes":
        "第 5 条: サービスの継続性とプラットフォームの変更",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Instagram API または Web インフラストラクチャに対する根本的な変更により、アプリケーションの機能が部分的または完全に失われる可能性があります。開発者は、「不可抗力」とみなされ、そのようなインフラストラクチャの変更に応じてアプリケーションを更新したり、サービスを維持したりすることを約束しません。",
    "Analysis complete, results will be shown after the ad.":
        "分析が完了しました。結果は広告の後に表示されます。",
    "Analysis failed": "分析に失敗しました",
    "Reason: {reason}": "理由: {reason}",
    "Tip: Logging out and logging back in may help.":
        "ヒント: ログアウトして再度ログインすると解決する場合があります。",
    "Quick check: Counts are the same. No changes detected.":
        "簡単なチェック: カウントは同じです。変化は検出されませんでした。",
    "Daily Metrics": "毎日のメトリクス",
    "Active users": "アクティブユーザー",
    "Daily queries": "毎日のクエリ",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "データのロードが中断されました: フォロワー データが不完全です ({fetched}/{total})。",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "データのロードが中断されました: 次のデータは不完全です ({fetched}/{total})。",
    "Data loading was interrupted: Instagram returned empty data.":
        "データの読み込みが中断されました: Instagram は空のデータを返しました。",
    "Data loading stopped due to an unexpected error.":
        "予期しないエラーによりデータの読み込みが停止しました。",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram は自動化された動作に関する警告を返しました。安全のためデータの取得を停止しました。",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "インスタグラムはセキュリティ検証を要求した。 Instagram アプリで確認して、もう一度お試しください。",
    "Session is invalid or waiting for verification. Please log in again.":
        "セッションが無効であるか、検証を待機しています。再度ログインしてください。",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "送信されたリクエストが多すぎます。安全のためデータの読み込みが中断されました。",
    "Data loading could not complete due to a connection issue.":
        "接続の問題により、データの読み込みを完了できませんでした。",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram がエラーを返しました (HTTP {code})。データのロードが中断されました。",
    "Instagram security verification is required (story data could not be fetched).":
        "Instagramのセキュリティ検証が必要です（ストーリーデータを取得できませんでした）。",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "ストーリーデータを取得できませんでした。通常、これは Instagram の検証、一時的な API 制限、または接続の中断によって発生します。 2 ～ 3 分後にもう一度お試しください。",
    "Could not fetch story data. Please try again shortly.":
        "ストーリーデータを取得できませんでした。しばらくしてからもう一度お試しください。",
    "Secret Mode": "シークレットモード",
    "Starting VERDICT...": "評決を開始しています...",
    "DID YOU KNOW?": "知っていましたか？",
    "Estimated time left: {time}": "推定残り時間: {time}",
    "Estimating remaining time...": "残り時間を見積もっています...",
    "LOG OUT": "ログアウト",
    "Open Profile": "プロフィールを開く",
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
    "Analysis Time!": "Время анализа!",
    "CLOSE": "ЗАКРЫВАТЬ",
    "SYSTEM UNDER MAINTENANCE": "СИСТЕМА НА ОБСЛУЖИВАНИИ",
    "Bio Planner": "Био Планировщик",
    "Store link not set.": "Ссылка на магазин не установлена.",
    "Invalid store link.": "Неверная ссылка на магазин.",
    "Could not open the link.": "Не удалось открыть ссылку.",
    "Please try again.": "Пожалуйста, попробуйте еще раз.",
    "Show error": "Показать ошибку",
    "Exception": "Исключение",
    "Load error": "Ошибка загрузки",
    "Code": "Код",
    "Timeout": "Тайм-аут",
    "REST probe failed: missing auth.":
        "Проверка REST не удалась: отсутствует аутентификация.",
    "REST probe success (Firestore endpoint reachable).":
        "Проверка REST прошла успешно (конечная точка Firestore достижима).",
    "REST probe failed (check logs).":
        "Проверка REST не удалась (проверьте журналы).",
    "Firebase Auth probe failed.": "Проверка подлинности Firebase не удалась.",
    "Firebase Auth probe success.":
        "Проверка аутентификации Firebase прошла успешно.",
    "Firebase token probe failed.": "Проверка токена Firebase не удалась.",
    "CRITICAL DIAGNOSTIC ERROR": "КРИТИЧЕСКАЯ ДИАГНОСТИЧЕСКАЯ ОШИБКА",
    "COPY": "КОПИРОВАТЬ",
    "OPEN LOGS": "ОТКРЫТЬ ЖУРНАЛЫ",
    "Firebase": "Огневая база",
    "Store": "Магазин",
    "Copy all": "Скопировать все",
    "Close": "Закрывать",
    "Auth Probe": "Проверка подлинности",
    "Write Test": "Написать тест",
    "REST Probe": "REST-зонд",
    "Restore Test": "Восстановить тест",
    "Firebase auth error: user verification failed.":
        "Ошибка аутентификации Firebase: проверка пользователя не удалась.",
    "Firestore test write successful.":
        "Тестовая запись Firestore прошла успешно.",
    "Firestore test failed.": "Тест Firestore не пройден.",
    "Firestore auth error: user verification failed.":
        "Ошибка аутентификации Firestore: проверка пользователя не удалась.",
    "Firestore counter write failed.": "Ошибка записи счетчика Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Отсутствует аутентификация Firestore: запись ig_users заблокирована.",
    "Firestore ig_users write failed.": "Ошибка записи ig_users в Firestore.",
    "User": "Пользователь",
    "Opening consent form...": "Открытие формы согласия...",
    "Your consent preference was updated.":
        "Ваши настройки согласия были обновлены.",
    "Consent update failed. Please try again.":
        "Не удалось обновить согласие. Пожалуйста, попробуйте еще раз.",
    "Your account is blocked": "Ваш аккаунт заблокирован",
    "Access is restricted for this account.":
        "Доступ для этой учетной записи ограничен.",
    "Starting purchase...": "Начинаю покупку...",
    "Purchase cancelled.": "Покупка отменена.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Премиум активен ✅ Реклама и время ожидания отключены.",
    "Purchase failed. Please try again.":
        "Покупка не удалась. Пожалуйста, попробуйте еще раз.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Требуется проверка сеанса. Пожалуйста, подтвердите свою учетную запись в приложении Instagram и повторите попытку.",
    "Instagram returned no data.": "Instagram не вернул данных.",
    "Session verification failed. Please log in again.":
        "Проверка сеанса не удалась. Пожалуйста, войдите снова.",
    "Open Instagram": "Открыть Инстаграм",
    "Instagram message": "сообщение в инстаграме",
    "Loading stories...": "Загрузка историй...",
    "No data": "Нет данных",
    "NEW": "НОВЫЙ",
    "Login": "Авторизоваться",
    "Session verified, redirecting...": "Сеанс подтвержден, перенаправление...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "РЕКЛАМНОЕ ПРОСТРАНСТВО",
    "Admin mode active": "Режим администратора активен",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Мы развиваемся каждый день, чтобы предоставить вам лучший опыт. Ваше мнение очень ценно для нас — мы будем рады услышать ваше мнение!",
    "Please log in to start the analysis.":
        "Пожалуйста, войдите, чтобы начать анализ.",
    "Welcome, {username}": "Добро пожаловать, {username}",
    "REFRESH DATA": "ОБНОВИТЬ ДАННЫЕ",
    "LOG IN WITH INSTAGRAM": "ВОЙТИ ЧЕРЕЗ ИНСТАГРАМ",
    "Analyzing data...\nThis might take a moment.":
        "Анализ данных...\nЭто может занять некоторое время.",
    "Processing data...\nAlmost done.": "Обработка данных...\nПочти готово.",
    "Loading ad...\nPlease wait.":
        "Загрузка объявления...\nПожалуйста, подождите.",
    "Google ad warning: {reason}": "Предупреждение Google о рекламе: {reason}",
    "All analysis is securely processed locally on your device.":
        "Весь анализ безопасно обрабатывается локально на вашем устройстве.",
    "Total analyses today: {count}": "Всего анализов за сегодня: {count}",
    "Next analysis": "Следующий анализ",
    "Ready to scan.": "Готов к сканированию.",
    "Analysis available now": "Анализ доступен уже сейчас",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Анализ доступен уже сейчас, но выполнение анализа подряд может подвергнуть риску вашу учетную запись.",
    "Please wait": "пожалуйста, подождите",
    "Warning": "Предупреждение",
    "Next analysis: {time}": "Следующий анализ: {time}",
    "WATCH AD AND START ANALYSIS": "ПОСМОТРЕТЬ ОБЪЯВЛЕНИЕ И НАЧАТЬ АНАЛИЗ",
    "START ANALYSIS": "НАЧАТЬ АНАЛИЗ",
    "Start analysis?": "Начать анализ?",
    "Reset App Data": "Сбросить данные приложения",
    "This will wipe all local data and session cookies. Are you sure?":
        "Это приведет к удалению всех локальных данных и файлов cookie сеанса. Вы уверены?",
    "CANCEL": "ОТМЕНА",
    "DELETE": "УДАЛИТЬ",
    "Error": "Ошибка",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Не удалось получить данные: {err}.\n\nУстранение неполадок: попробуйте выйти из системы и снова войти в систему.",
    "Followers": "Последователи",
    "Following": "Следующий",
    "New Followers": "Новые подписчики",
    "Not Following Back": "Не следовать назад",
    "Lost Followers": "Потерянные подписчики",
    "Legal Disclaimer": "Юридическая оговорка",
    "Unfollowed Users": "Неподписанные пользователи",
    "Rate Us": "Оцените нас",
    "Contact Us": "Связаться с нами",
    "Remove Ads & Wait Times": "Удалить рекламу и время ожидания",
    "This box is currently under test.":
        "Эта коробка в настоящее время находится на стадии тестирования.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Смотрите истории тайно или увеличивайте фотографии профиля",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Пожалуйста, войдите в систему, чтобы тайно смотреть истории и увеличивать фотографии профиля.",
    "Will be shown after the ad, please wait.":
        "Будет показано после объявления, пожалуйста, подождите.",
    "What would you like to do?": "Что бы вы хотели сделать?",
    "Enlarge profile photo": "Увеличить фото профиля",
    "Watch story secretly": "Смотрите историю тайно",
    "No story data available.": "Данных по истории нет.",
    "I HAVE READ AND AGREE": "Я ПРОЧИТАЛ И СОГЛАСЕН",
    "Withdraw Consent": "Отозвать согласие",
    "Confirm": "Подтверждать",
    "Your consent settings will be reset. Are you sure?":
        "Настройки вашего согласия будут сброшены. Вы уверены?",
    "Yes": "Да",
    "Cancel": "Отмена",
    "Session verified, redirecting securely...":
        "Сеанс проверен, перенаправление безопасно...",
    "Analysis complete ✅": "Анализ завершен ✅",
    "Purchases are not available right now. Please try again later.":
        "Покупки сейчас недоступны. Пожалуйста, повторите попытку позже.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Покупка завершена, но Премиум еще не активен. Пожалуйста, попробуйте еще раз.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Добро пожаловать в Премиум! Реклама и время ожидания удалены.",
    "Your Premium membership is active.": "Ваше Премиум-членство активно.",
    "Restore Purchases": "Восстановить покупки",
    "RESTORE": "ВОССТАНОВИТЬ",
    "Restoring purchases...": "Восстановление покупок...",
    "Purchases restored ✅": "Покупки восстановлены ✅",
    "No purchases to restore.": "Нет покупок для восстановления.",
    "Restore failed: {err}": "Не удалось восстановить: {err}.",
    "Enter PIN": "Введите PIN-код",
    "PIN accepted, timer reset ✅": "PIN-код принят, таймер сброшен ✅",
    "Invalid PIN": "Неверный PIN-код",
    "OK": "ХОРОШО",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Загружая и используя это приложение, считается, что каждый Пользователь заранее прочитал, понял и безоговорочно принял приведенный ниже текст «Условий использования и отказа от ответственности»:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Статья 1. Конфиденциальность данных и архитектура локальной обработки",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "ВЕРДИКТ — это клиентское программное обеспечение. Учетные данные Пользователя (имя пользователя, пароль, файлы cookie сеанса) ни при каких обстоятельствах не передаются и не сохраняются на внешнем сервере. Все действия по обработке данных происходят исключительно во временной памяти (ОЗУ) и локальном хранилище устройства Пользователя. Приложение функционирует как «браузер-обертка», работающая через интерфейс Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Статья 2. Риски сторонних платформ",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) оставляет за собой право ограничивать использование стороннего программного обеспечения в соответствии с политикой своей платформы. Все риски, включая, помимо прочего, «блокировку действий», «ограничения учетной записи», «теневые баны» или «закрытие учетной записи», которые могут возникнуть в результате использования приложения, принадлежат исключительно Пользователю. Разработчик ВЕРДИКТ не может быть привлечен к ответственности за какой-либо прямой или косвенный ущерб, возникший в результате таких административных санкций.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Статья 3: Отказ от гарантийных обязательств и ограничение ответственности",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Это программное обеспечение предоставляется «КАК ЕСТЬ» и «КАК ДОСТУПНО». 100% точность, непрерывность или коммерческая ценность результатов анализа, предоставляемых программным обеспечением, не гарантируется. Пользователь признает, что любые результаты, возникающие в результате юридических или коммерческих операций на основе данных приложения, являются его собственной ответственностью; а также заявляет и обязуется оградить разработчика от всех претензий, исков и жалоб.",
    "Article 4: Intellectual Property and Independence Notice":
        "Статья 4: Интеллектуальная собственность и уведомление о независимости",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "ВЕРДИКТ — независимый девелоперский проект. Бренды «Instagram», «Facebook» и «Meta» являются зарегистрированными торговыми марками Meta Platforms, Inc. Это приложение не имеет коммерческого партнерства, спонсорского соглашения или официальной связи с вышеупомянутыми компаниями.",
    "Article 5: Service Continuity and Platform Changes":
        "Статья 5. Непрерывность обслуживания и изменения платформы",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Фундаментальные изменения в API Instagram или веб-инфраструктуре могут привести к частичной или полной потере функциональности приложения. Разработчик не берет на себя обязательств по обновлению приложения или поддержке сервиса в ответ на такие инфраструктурные изменения, которые считаются «форс-мажорными обстоятельствами».",
    "Analysis complete, results will be shown after the ad.":
        "Анализ завершен, результаты будут показаны после объявления.",
    "Analysis failed": "Анализ не удался",
    "Reason: {reason}": "Причина: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Совет: может помочь выход из системы и повторный вход.",
    "Quick check: Counts are the same. No changes detected.":
        "Быстрая проверка: количество одинаковое. Никаких изменений не обнаружено.",
    "Daily Metrics": "Ежедневные показатели",
    "Active users": "Активные пользователи",
    "Daily queries": "Ежедневные запросы",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Загрузка данных прервана: данные подчиненного устройства неполные ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Загрузка данных прервана: следующие данные неполные ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Загрузка данных была прервана: Instagram вернул пустые данные.",
    "Data loading stopped due to an unexpected error.":
        "Загрузка данных остановлена ​​из-за непредвиденной ошибки.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram вернул предупреждение об автоматическом поведении. Мы прекратили получение данных в целях безопасности.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram запросил проверку безопасности. Подтвердите данные в приложении Instagram и повторите попытку.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Сеанс недействителен или ожидает проверки. Пожалуйста, войдите снова.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Было отправлено слишком много запросов. Загрузка данных была прервана в целях безопасности.",
    "Data loading could not complete due to a connection issue.":
        "Загрузка данных не может быть завершена из-за проблем с подключением.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram вернул ошибку (HTTP {code}). Загрузка данных прервана.",
    "Instagram security verification is required (story data could not be fetched).":
        "Требуется проверка безопасности Instagram (не удалось получить данные истории).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Не удалось получить данные истории. Обычно это вызвано проверкой Instagram, временными ограничениями API или прерыванием соединения. Пожалуйста, повторите попытку через 2–3 минуты.",
    "Could not fetch story data. Please try again shortly.":
        "Не удалось получить данные истории. Пожалуйста, повторите попытку в ближайшее время.",
    "Secret Mode": "Секретный режим",
    "Starting VERDICT...": "Начинаем ВЕРДИКТ...",
    "DID YOU KNOW?": "ВЫ ЗНАЛИ?",
    "Estimated time left: {time}": "Примерное время осталось: {time}",
    "Estimating remaining time...": "Оценка оставшегося времени...",
    "LOG OUT": "ВЫХОД",
    "Open Profile": "Открыть профиль",
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
    "Analysis Time!": "Hora de análise!",
    "CLOSE": "FECHAR",
    "SYSTEM UNDER MAINTENANCE": "SISTEMA EM MANUTENÇÃO",
    "Bio Planner": "Planejador biológico",
    "Store link not set.": "Link da loja não definido.",
    "Invalid store link.": "Link de loja inválido.",
    "Could not open the link.": "Não foi possível abrir o link.",
    "Please try again.": "Por favor, tente novamente.",
    "Show error": "Mostrar erro",
    "Exception": "Exceção",
    "Load error": "Erro de carregamento",
    "Code": "Código",
    "Timeout": "Tempo esgotado",
    "REST probe failed: missing auth.":
        "Falha na sonda REST: autenticação ausente.",
    "REST probe success (Firestore endpoint reachable).":
        "Êxito na sondagem REST (endpoint do Firestore acessível).",
    "REST probe failed (check logs).":
        "Falha na sonda REST (verifique os logs).",
    "Firebase Auth probe failed.": "Falha na sondagem do Firebase Auth.",
    "Firebase Auth probe success.": "Sucesso na investigação do Firebase Auth.",
    "Firebase token probe failed.": "Falha na análise do token do Firebase.",
    "CRITICAL DIAGNOSTIC ERROR": "ERRO DE DIAGNÓSTICO CRÍTICO",
    "COPY": "CÓPIA",
    "OPEN LOGS": "ABRIR REGISTROS",
    "Firebase": "Base de fogo",
    "Store": "Loja",
    "Copy all": "Copiar tudo",
    "Close": "Fechar",
    "Auth Probe": "Sonda de autenticação",
    "Write Test": "Teste de gravação",
    "REST Probe": "Sonda REST",
    "Restore Test": "Teste de restauração",
    "Firebase auth error: user verification failed.":
        "Erro de autenticação do Firebase: falha na verificação do usuário.",
    "Firestore test write successful.":
        "Gravação de teste do Firestore bem-sucedida.",
    "Firestore test failed.": "O teste do Firestore falhou.",
    "Firestore auth error: user verification failed.":
        "Erro de autenticação do Firestore: falha na verificação do usuário.",
    "Firestore counter write failed.":
        "Falha na gravação do contador do Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Autenticação do Firestore ausente: gravação de ig_users bloqueada.",
    "Firestore ig_users write failed.":
        "Falha na gravação do Firestore ig_users.",
    "User": "Usuário",
    "Opening consent form...": "Abrindo formulário de consentimento...",
    "Your consent preference was updated.":
        "Sua preferência de consentimento foi atualizada.",
    "Consent update failed. Please try again.":
        "Falha na atualização do consentimento. Por favor, tente novamente.",
    "Your account is blocked": "Sua conta está bloqueada",
    "Access is restricted for this account.":
        "O acesso é restrito para esta conta.",
    "Starting purchase...": "Iniciando compra...",
    "Purchase cancelled.": "Compra cancelada.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium ativo ✅ Anúncios e tempos de espera estão desativados.",
    "Purchase failed. Please try again.":
        "A compra falhou. Por favor, tente novamente.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "A verificação da sessão é necessária. Verifique sua conta no aplicativo Instagram e tente novamente.",
    "Instagram returned no data.": "O Instagram não retornou dados.",
    "Session verification failed. Please log in again.":
        "Falha na verificação da sessão. Faça login novamente.",
    "Open Instagram": "Abra o Instagram",
    "Instagram message": "Mensagem do Instagram",
    "Loading stories...": "Carregando histórias...",
    "No data": "Sem dados",
    "NEW": "NOVO",
    "Login": "Conecte-se",
    "Session verified, redirecting...": "Sessão verificada, redirecionando...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ESPAÇO DE ANÚNCIO",
    "Admin mode active": "Modo administrador ativo",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Estamos evoluindo a cada dia para lhe proporcionar uma melhor experiência. Seu feedback é valioso para nós – adoraríamos ouvir sua opinião!",
    "Please log in to start the analysis.":
        "Faça login para iniciar a análise.",
    "Welcome, {username}": "Bem-vindo, {username}",
    "REFRESH DATA": "ATUALIZAR DADOS",
    "LOG IN WITH INSTAGRAM": "ENTRAR COM INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analisando dados...\nIsso pode demorar um pouco.",
    "Processing data...\nAlmost done.": "Processando dados...\nQuase pronto.",
    "Loading ad...\nPlease wait.": "Carregando anúncio...\nPor favor, espere.",
    "Google ad warning: {reason}": "Aviso de anúncio do Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Todas as análises são processadas localmente com segurança no seu dispositivo.",
    "Total analyses today: {count}": "Total de análises hoje: {count}",
    "Next analysis": "Próxima análise",
    "Ready to scan.": "Pronto para digitalizar.",
    "Analysis available now": "Análise disponível agora",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "A análise já está disponível, mas executá-las consecutivamente pode colocar sua conta em risco.",
    "Please wait": "Por favor, aguarde",
    "Warning": "Aviso",
    "Next analysis: {time}": "Próxima análise: {time}",
    "WATCH AD AND START ANALYSIS": "ASSISTA AO ANÚNCIO E INICIE A ANÁLISE",
    "START ANALYSIS": "INICIAR ANÁLISE",
    "Start analysis?": "Iniciar análise?",
    "Reset App Data": "Redefinir dados do aplicativo",
    "This will wipe all local data and session cookies. Are you sure?":
        "Isso apagará todos os dados locais e cookies de sessão. Tem certeza?",
    "CANCEL": "CANCELAR",
    "DELETE": "EXCLUIR",
    "Error": "Erro",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Falha na recuperação de dados: {err}\n\nSolução de problemas: tente sair e fazer login novamente.",
    "Followers": "Seguidores",
    "Following": "Seguindo",
    "New Followers": "Novos seguidores",
    "Not Following Back": "Não seguindo de volta",
    "Lost Followers": "Seguidores perdidos",
    "Legal Disclaimer": "Isenção de responsabilidade legal",
    "Unfollowed Users": "Usuários não seguidos",
    "Rate Us": "Avalie-nos",
    "Contact Us": "Contate-nos",
    "Remove Ads & Wait Times": "Remover anúncios e tempos de espera",
    "This box is currently under test.": "Esta caixa está atualmente em teste.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Assista histórias secretamente ou amplie fotos de perfil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Faça login para assistir histórias secretamente e ampliar as fotos do perfil.",
    "Will be shown after the ad, please wait.":
        "Será exibido após o anúncio, aguarde.",
    "What would you like to do?": "O que você gostaria de fazer?",
    "Enlarge profile photo": "Ampliar foto do perfil",
    "Watch story secretly": "Assista a história secretamente",
    "No story data available.": "Nenhum dado da história disponível.",
    "I HAVE READ AND AGREE": "EU LI E CONCORDO",
    "Withdraw Consent": "Retirar consentimento",
    "Confirm": "Confirmar",
    "Your consent settings will be reset. Are you sure?":
        "Suas configurações de consentimento serão redefinidas. Tem certeza?",
    "Yes": "Sim",
    "Cancel": "Cancelar",
    "Session verified, redirecting securely...":
        "Sessão verificada, redirecionando com segurança...",
    "Analysis complete ✅": "Análise concluída ✅",
    "Purchases are not available right now. Please try again later.":
        "As compras não estão disponíveis no momento. Por favor, tente novamente mais tarde.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Compra concluída, mas o Premium ainda não está ativo. Por favor, tente novamente.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Bem-vindo ao Premium! Anúncios e tempos de espera são removidos.",
    "Your Premium membership is active.": "Sua assinatura Premium está ativa.",
    "Restore Purchases": "Restaurar compras",
    "RESTORE": "RESTAURAR",
    "Restoring purchases...": "Restaurando compras...",
    "Purchases restored ✅": "Compras restauradas ✅",
    "No purchases to restore.": "Nenhuma compra para restaurar.",
    "Restore failed: {err}": "Falha na restauração: {err}",
    "Enter PIN": "Insira o PIN",
    "PIN accepted, timer reset ✅": "PIN aceito, cronômetro redefinido ✅",
    "Invalid PIN": "PIN inválido",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Ao baixar e usar este aplicativo, considera-se que todo Usuário leu, compreendeu e aceitou irrevogavelmente o texto dos \"Termos de Uso e Isenção de Responsabilidade\" abaixo, com antecedência:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artigo 1: Privacidade de dados e arquitetura de processamento local",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT é um software do 'lado do cliente'. As credenciais de login do Utilizador (nome de utilizador, palavra-passe, cookies de sessão) não são em caso algum transmitidas ou armazenadas num servidor externo. Todas as atividades de processamento de dados ocorrem exclusivamente na memória temporária (RAM) e no armazenamento local do dispositivo do Usuário. O aplicativo funciona como um 'invólucro de navegador' operando na interface do Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Artigo 2: Riscos de plataformas de terceiros",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "O Instagram (Meta Platforms, Inc.) reserva-se o direito de restringir o uso de software de terceiros de acordo com as políticas da plataforma. Todos os riscos, incluindo, entre outros, 'bloqueios de ação', 'restrições de conta', 'shadowbans' ou 'encerramentos de conta' que possam surgir do uso do aplicativo, pertencem exclusivamente ao Usuário. O desenvolvedor VERDICT não pode ser responsabilizado por quaisquer danos diretos ou indiretos resultantes de tais sanções administrativas.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artigo 3: Isenção de responsabilidade de garantia e limitação de responsabilidade",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Este software é fornecido 'NO ESTADO EM QUE SE ENCONTRA' e 'CONFORME DISPONÍVEL'. A precisão, continuidade ou comercialização de 100% dos resultados da análise fornecidos pelo software não são garantidas. O Usuário reconhece que quaisquer resultados decorrentes de transações legais ou comerciais baseadas em dados do aplicativo são de sua própria responsabilidade; e declara e compromete-se a isentar o desenvolvedor de todas as reclamações, ações judiciais e reclamações.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artigo 4: Aviso de Propriedade Intelectual e Independência",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT é um projeto de desenvolvedor independente. As marcas 'Instagram', 'Facebook' e 'Meta' são marcas registradas da Meta Platforms, Inc. Este aplicativo não possui parceria comercial, acordo de patrocínio ou afiliação oficial com as empresas mencionadas.",
    "Article 5: Service Continuity and Platform Changes":
        "Artigo 5: Continuidade do Serviço e Mudanças na Plataforma",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Mudanças fundamentais na API do Instagram ou na infraestrutura da web podem fazer com que o aplicativo perca sua funcionalidade parcial ou totalmente. O desenvolvedor não se compromete a atualizar o aplicativo ou manter o serviço em resposta a tais alterações infraestruturais, que são consideradas “força maior”.",
    "Analysis complete, results will be shown after the ad.":
        "Análise concluída, os resultados serão mostrados após o anúncio.",
    "Analysis failed": "Falha na análise",
    "Reason: {reason}": "Motivo: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Dica: Sair e fazer login novamente pode ajudar.",
    "Quick check: Counts are the same. No changes detected.":
        "Verificação rápida: as contagens são as mesmas. Nenhuma alteração detectada.",
    "Daily Metrics": "Métricas Diárias",
    "Active users": "Usuários ativos",
    "Daily queries": "Consultas diárias",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "O carregamento de dados foi interrompido: dados do seguidor incompletos ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "O carregamento de dados foi interrompido: seguintes dados incompletos ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "O carregamento de dados foi interrompido: o Instagram retornou dados vazios.",
    "Data loading stopped due to an unexpected error.":
        "O carregamento de dados foi interrompido devido a um erro inesperado.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "O Instagram retornou um aviso de comportamento automatizado. Paramos de buscar dados por segurança.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "O Instagram solicitou verificação de segurança. Verifique no aplicativo Instagram e tente novamente.",
    "Session is invalid or waiting for verification. Please log in again.":
        "A sessão é inválida ou aguarda verificação. Faça login novamente.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Muitas solicitações foram enviadas. O carregamento de dados foi interrompido por segurança.",
    "Data loading could not complete due to a connection issue.":
        "O carregamento de dados não pôde ser concluído devido a um problema de conexão.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "O Instagram retornou um erro (HTTP {code}). O carregamento de dados foi interrompido.",
    "Instagram security verification is required (story data could not be fetched).":
        "A verificação de segurança do Instagram é necessária (não foi possível obter os dados da história).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Não foi possível buscar os dados da história. Geralmente isso é causado pela verificação do Instagram, restrições temporárias da API ou interrupção da conexão. Tente novamente em 2 a 3 minutos.",
    "Could not fetch story data. Please try again shortly.":
        "Não foi possível buscar os dados da história. Por favor, tente novamente em breve.",
    "Secret Mode": "Modo secreto",
    "Starting VERDICT...": "Iniciando o VEREDICTO...",
    "DID YOU KNOW?": "VOCÊ SABIA?",
    "Estimated time left: {time}": "Tempo restante estimado: {time}",
    "Estimating remaining time...": "Estimando o tempo restante...",
    "LOG OUT": "SAIR",
    "Open Profile": "Abrir perfil",
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
    "Analysis Time!": "وقت التحليل!",
    "CLOSE": "يغلق",
    "SYSTEM UNDER MAINTENANCE": "النظام تحت الصيانة",
    "Bio Planner": "المخطط الحيوي",
    "Store link not set.": "لم يتم ضبط رابط المتجر.",
    "Invalid store link.": "رابط المتجر غير صالح.",
    "Could not open the link.": "لا يمكن فتح الرابط.",
    "Please try again.": "يرجى المحاولة مرة أخرى.",
    "Show error": "إظهار الخطأ",
    "Exception": "استثناء",
    "Load error": "خطأ في التحميل",
    "Code": "شفرة",
    "Timeout": "نفذ الوقت",
    "REST probe failed: missing auth.": "فشل مسبار REST: المصادقة مفقودة.",
    "REST probe success (Firestore endpoint reachable).":
        "نجاح مسبار REST (يمكن الوصول إلى نقطة نهاية Firestore).",
    "REST probe failed (check logs).": "فشل مسبار REST (تحقق من السجلات).",
    "Firebase Auth probe failed.": "فشل التحقيق في مصادقة Firebase.",
    "Firebase Auth probe success.": "نجاح التحقيق في مصادقة Firebase.",
    "Firebase token probe failed.": "فشل التحقيق في رمز Firebase.",
    "CRITICAL DIAGNOSTIC ERROR": "خطأ تشخيصي فادح",
    "COPY": "ينسخ",
    "OPEN LOGS": "السجلات المفتوحة",
    "Firebase": "Firebase",
    "Store": "محل",
    "Copy all": "انسخ الكل",
    "Close": "يغلق",
    "Auth Probe": "مسبار المصادقة",
    "Write Test": "اختبار الكتابة",
    "REST Probe": "مسبار الراحة",
    "Restore Test": "استعادة الاختبار",
    "Firebase auth error: user verification failed.":
        "خطأ في مصادقة Firebase: فشل التحقق من المستخدم.",
    "Firestore test write successful.": "نجح اختبار Firestore في الكتابة.",
    "Firestore test failed.": "فشل اختبار Firestore.",
    "Firestore auth error: user verification failed.":
        "خطأ في مصادقة Firestore: فشل التحقق من المستخدم.",
    "Firestore counter write failed.": "فشلت كتابة عداد Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "مصادقة Firestore مفقودة: تم حظر كتابة ig_users.",
    "Firestore ig_users write failed.":
        "فشلت عملية الكتابة في Firestore ig_users.",
    "User": "مستخدم",
    "Opening consent form...": "جارٍ فتح نموذج الموافقة...",
    "Your consent preference was updated.": "تم تحديث تفضيل موافقتك.",
    "Consent update failed. Please try again.":
        "فشل تحديث الموافقة. يرجى المحاولة مرة أخرى.",
    "Your account is blocked": "تم حظر حسابك",
    "Access is restricted for this account.": "الوصول مقيد لهذا الحساب.",
    "Starting purchase...": "بدء الشراء...",
    "Purchase cancelled.": "تم إلغاء الشراء.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium نشط ✅ تم تعطيل الإعلانات وأوقات الانتظار.",
    "Purchase failed. Please try again.": "فشل الشراء. يرجى المحاولة مرة أخرى.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "مطلوب التحقق من الجلسة. يرجى التحقق من حسابك في تطبيق Instagram والمحاولة مرة أخرى.",
    "Instagram returned no data.": "لم يُرجع Instagram أي بيانات.",
    "Session verification failed. Please log in again.":
        "فشل التحقق من الجلسة. الرجاء تسجيل الدخول مرة أخرى.",
    "Open Instagram": "افتح انستقرام",
    "Instagram message": "رسالة انستغرام",
    "Loading stories...": "جارٍ تحميل القصص...",
    "No data": "لا توجد بيانات",
    "NEW": "جديد",
    "Login": "تسجيل الدخول",
    "Session verified, redirecting...":
        "تم التحقق من الجلسة، جارٍ إعادة التوجيه...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "مساحة إعلانية",
    "Admin mode active": "وضع المسؤول نشط",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "نحن نتطور كل يوم لنقدم لك تجربة أفضل. ملاحظاتك ذات قيمة بالنسبة لنا، ونحن نحب أن نسمع منك!",
    "Please log in to start the analysis.": "الرجاء تسجيل الدخول لبدء التحليل.",
    "Welcome, {username}": "مرحبًا، {username}",
    "REFRESH DATA": "تحديث البيانات",
    "LOG IN WITH INSTAGRAM": "قم بتسجيل الدخول باستخدام الانستقرام",
    "Analyzing data...\nThis might take a moment.":
        "جارٍ تحليل البيانات...\nقد يستغرق هذا لحظة.",
    "Processing data...\nAlmost done.": "معالجة البيانات...\nانتهى تقريبا.",
    "Loading ad...\nPlease wait.": "جارٍ تحميل الإعلان...\nمن فضلك انتظر.",
    "Google ad warning: {reason}": "تحذير إعلان Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "تتم معالجة جميع التحليلات بشكل آمن محليًا على جهازك.",
    "Total analyses today: {count}": "إجمالي التحليلات اليوم: {count}",
    "Next analysis": "التحليل التالي",
    "Ready to scan.": "جاهز للمسح.",
    "Analysis available now": "التحليل متاح الآن",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "التحليل متاح الآن، ولكن تشغيل التحليلات بشكل متتالي قد يعرض حسابك للخطر.",
    "Please wait": "انتظر من فضلك",
    "Warning": "تحذير",
    "Next analysis: {time}": "التحليل التالي: {time}",
    "WATCH AD AND START ANALYSIS": "شاهد الإعلان وابدأ التحليل",
    "START ANALYSIS": "ابدأ التحليل",
    "Start analysis?": "بدء التحليل؟",
    "Reset App Data": "إعادة ضبط بيانات التطبيق",
    "This will wipe all local data and session cookies. Are you sure?":
        "سيؤدي هذا إلى مسح كافة البيانات المحلية وملفات تعريف الارتباط للجلسة. هل أنت متأكد؟",
    "CANCEL": "يلغي",
    "DELETE": "يمسح",
    "Error": "خطأ",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "فشل استرداد البيانات: {err}\n\nاستكشاف الأخطاء وإصلاحها: حاول تسجيل الخروج ثم تسجيل الدخول مرة أخرى.",
    "Followers": "المتابعون",
    "Following": "التالي",
    "New Followers": "متابعين جدد",
    "Not Following Back": "عدم متابعة العودة",
    "Lost Followers": "متابعين مفقودين",
    "Legal Disclaimer": "إخلاء المسؤولية القانونية",
    "Unfollowed Users": "المستخدمون غير المتابعين",
    "Rate Us": "قيمنا",
    "Contact Us": "اتصل بنا",
    "Remove Ads & Wait Times": "إزالة الإعلانات وأوقات الانتظار",
    "This box is currently under test.": "هذا المربع قيد الاختبار حاليًا.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "شاهد القصص سرًا أو قم بتكبير صور الملف الشخصي",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "الرجاء تسجيل الدخول لمشاهدة القصص سرا وتكبير الصور الشخصية.",
    "Will be shown after the ad, please wait.":
        "سيتم عرضه بعد الإعلان، برجاء الانتظار.",
    "What would you like to do?": "ماذا تريد أن تفعل؟",
    "Enlarge profile photo": "تكبير الصورة الشخصية",
    "Watch story secretly": "شاهد القصة سرا",
    "No story data available.": "لا توجد بيانات القصة المتاحة.",
    "I HAVE READ AND AGREE": "لقد قرأت ووافقت",
    "Withdraw Consent": "سحب الموافقة",
    "Confirm": "يتأكد",
    "Your consent settings will be reset. Are you sure?":
        "سيتم إعادة ضبط إعدادات موافقتك. هل أنت متأكد؟",
    "Yes": "نعم",
    "Cancel": "يلغي",
    "Session verified, redirecting securely...":
        "تم التحقق من الجلسة، وإعادة التوجيه بشكل آمن...",
    "Analysis complete ✅": "انتهى التحليل ✅",
    "Purchases are not available right now. Please try again later.":
        "المشتريات غير متوفرة في الوقت الحالي. يرجى المحاولة مرة أخرى لاحقا.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "اكتملت عملية الشراء، لكن Premium لم يتم تفعيله بعد. يرجى المحاولة مرة أخرى.",
    "Welcome to Premium! Ads and wait times are removed.":
        "مرحبًا بك في Premium! تتم إزالة الإعلانات وأوقات الانتظار.",
    "Your Premium membership is active.": "عضويتك المميزة نشطة.",
    "Restore Purchases": "استعادة المشتريات",
    "RESTORE": "يعيد",
    "Restoring purchases...": "جارٍ استعادة عمليات الشراء...",
    "Purchases restored ✅": "تمت استعادة المشتريات ✅",
    "No purchases to restore.": "لا توجد مشتريات لاستعادة.",
    "Restore failed: {err}": "فشلت الاستعادة: {err}",
    "Enter PIN": "أدخل رقم التعريف الشخصي",
    "PIN accepted, timer reset ✅":
        "تم قبول رقم التعريف الشخصي، وإعادة ضبط المؤقت ✅",
    "Invalid PIN": "رقم التعريف الشخصي غير صالح",
    "OK": "نعم",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "من خلال تنزيل هذا التطبيق واستخدامه، يُعتبر كل مستخدم قد قرأ نص \"شروط الاستخدام وإخلاء المسؤولية\" أدناه مسبقًا وفهمه وقبله بشكل لا رجعة فيه:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "المادة 1: خصوصية البيانات وبنية المعالجة المحلية",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT هو برنامج \"من جانب العميل\". لا يتم تحت أي ظرف من الظروف نقل بيانات اعتماد تسجيل الدخول الخاصة بالمستخدم (اسم المستخدم وكلمة المرور وملفات تعريف الارتباط للجلسة) إلى خادم خارجي أو تخزينها عليه. تتم جميع أنشطة معالجة البيانات حصريًا داخل الذاكرة المؤقتة (RAM) والتخزين المحلي لجهاز المستخدم. يعمل التطبيق بمثابة \"غلاف متصفح\" يعمل عبر واجهة Instagram.",
    "Article 2: Third-Party Platform Risks":
        "المادة 2: مخاطر منصة الطرف الثالث",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "تحتفظ Instagram (Meta Platforms, Inc.) بالحق في تقييد استخدام برامج الجهات الخارجية وفقًا لسياسات النظام الأساسي الخاصة بها. جميع المخاطر، بما في ذلك على سبيل المثال لا الحصر، \"حظر الإجراءات\"، أو \"قيود الحساب\"، أو \"حظر الظل\"، أو \"إغلاق الحساب\" التي قد تنشأ عن استخدام التطبيق، مملوكة حصريًا للمستخدم. لا يمكن أن يتحمل مطور VERDICT المسؤولية عن أي أضرار مباشرة أو غير مباشرة ناتجة عن هذه العقوبات الإدارية.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "المادة 3: إخلاء المسؤولية عن الضمان وحدود المسؤولية",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "يتم توفير هذا البرنامج \"كما هو\" و\"كما هو متاح\". لا يتم ضمان دقة نتائج التحليل التي يقدمها البرنامج أو استمراريتها أو قابليتها للتسويق بنسبة 100%. يقر المستخدم بأن أي نتائج تنشأ عن المعاملات القانونية أو التجارية بناءً على بيانات التطبيق هي مسؤوليته الخاصة؛ ويعلن ويتعهد بحماية المطور من كافة المطالبات والدعاوى القضائية والشكاوى.",
    "Article 4: Intellectual Property and Independence Notice":
        "المادة 4: إشعار الملكية الفكرية والاستقلال",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT هو مشروع مطور مستقل. العلامات التجارية \"Instagram\" و\"Facebook\" و\"Meta\" هي علامات تجارية مسجلة لشركة Meta Platforms, Inc. وليس لهذا التطبيق أي شراكة تجارية أو اتفاقية رعاية أو انتماء رسمي مع الشركات المذكورة أعلاه.",
    "Article 5: Service Continuity and Platform Changes":
        "المادة الخامسة: استمرارية الخدمة وتغييرات النظام الأساسي",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "قد تؤدي التغييرات الأساسية في واجهة برمجة تطبيقات Instagram أو البنية التحتية للويب إلى فقدان التطبيق لوظائفه جزئيًا أو كليًا. لا يقدم المطور أي التزام بتحديث التطبيق أو الحفاظ على الخدمة استجابة لهذه التغييرات في البنية التحتية، والتي تعتبر \"قوة قاهرة\".",
    "Analysis complete, results will be shown after the ad.":
        "اكتمل التحليل، وستظهر النتائج بعد الإعلان.",
    "Analysis failed": "فشل التحليل",
    "Reason: {reason}": "السبب: {reason}",
    "Tip: Logging out and logging back in may help.":
        "نصيحة: قد يساعد تسجيل الخروج وتسجيل الدخول مرة أخرى.",
    "Quick check: Counts are the same. No changes detected.":
        "فحص سريع: الأعداد هي نفسها. لم يتم اكتشاف أي تغييرات.",
    "Daily Metrics": "المقاييس اليومية",
    "Active users": "المستخدمين النشطين",
    "Daily queries": "الاستفسارات اليومية",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "تمت مقاطعة تحميل البيانات: بيانات المتابعين غير مكتملة ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "تمت مقاطعة تحميل البيانات: البيانات التالية غير مكتملة ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "تمت مقاطعة تحميل البيانات: أعاد Instagram بيانات فارغة.",
    "Data loading stopped due to an unexpected error.":
        "توقف تحميل البيانات بسبب خطأ غير متوقع.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "أعاد Instagram تحذيرًا بشأن السلوك الآلي. لقد توقفنا عن جلب البيانات من أجل السلامة.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "طلب Instagram التحقق الأمني. قم بالتحقق في تطبيق Instagram وحاول مرة أخرى.",
    "Session is invalid or waiting for verification. Please log in again.":
        "الجلسة غير صالحة أو في انتظار التحقق. الرجاء تسجيل الدخول مرة أخرى.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "تم إرسال عدد كبير جدًا من الطلبات. تمت مقاطعة تحميل البيانات من أجل السلامة.",
    "Data loading could not complete due to a connection issue.":
        "تعذر إكمال تحميل البيانات بسبب مشكلة في الاتصال.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "أعاد Instagram خطأ (HTTP {code}). تمت مقاطعة تحميل البيانات.",
    "Instagram security verification is required (story data could not be fetched).":
        "مطلوب التحقق من أمان Instagram (تعذر جلب بيانات القصة).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "لا يمكن جلب بيانات القصة. عادةً ما يحدث هذا بسبب التحقق من Instagram أو قيود واجهة برمجة التطبيقات المؤقتة أو انقطاع الاتصال. يرجى المحاولة مرة أخرى خلال 2-3 دقائق.",
    "Could not fetch story data. Please try again shortly.":
        "تعذر جلب بيانات القصة. يرجى المحاولة مرة أخرى قريبا.",
    "Secret Mode": "الوضع السري",
    "Starting VERDICT...": "بدء الحكم...",
    "DID YOU KNOW?": "هل تعلم؟",
    "Estimated time left: {time}": "الوقت المتبقي المقدر: {time}",
    "Estimating remaining time...": "تقدير الوقت المتبقي...",
    "LOG OUT": "تسجيل الخروج",
    "Open Profile": "افتح الملف الشخصي",
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
    "Analysis Time!": "¡Tiempo de análisis!",
    "CLOSE": "CERCA",
    "SYSTEM UNDER MAINTENANCE": "SISTEMA EN MANTENIMIENTO",
    "Bio Planner": "Planificador biológico",
    "Store link not set.": "Enlace de la tienda no establecido.",
    "Invalid store link.": "Enlace de tienda no válido.",
    "Could not open the link.": "No se pudo abrir el enlace.",
    "Please try again.": "Por favor inténtalo de nuevo.",
    "Show error": "Mostrar error",
    "Exception": "Excepción",
    "Load error": "error de carga",
    "Code": "Código",
    "Timeout": "Se acabó el tiempo",
    "REST probe failed: missing auth.":
        "Falló la sonda REST: falta autenticación.",
    "REST probe success (Firestore endpoint reachable).":
        "Éxito de la sonda REST (se puede acceder al punto final de Firestore).",
    "REST probe failed (check logs).":
        "La sonda REST falló (verifique los registros).",
    "Firebase Auth probe failed.":
        "Error en la prueba de autenticación de Firebase.",
    "Firebase Auth probe success.":
        "La investigación de Firebase Auth fue exitosa.",
    "Firebase token probe failed.": "Error en la sonda del token de Firebase.",
    "CRITICAL DIAGNOSTIC ERROR": "ERROR DE DIAGNÓSTICO CRÍTICO",
    "COPY": "COPIAR",
    "OPEN LOGS": "ABRIR REGISTROS",
    "Firebase": "base de fuego",
    "Store": "Almacenar",
    "Copy all": "Copiar todo",
    "Close": "Cerca",
    "Auth Probe": "Sonda de autenticación",
    "Write Test": "Escribir prueba",
    "REST Probe": "Sonda de descanso",
    "Restore Test": "Restaurar prueba",
    "Firebase auth error: user verification failed.":
        "Error de autenticación de Firebase: falló la verificación del usuario.",
    "Firestore test write successful.":
        "Escritura de prueba de Firestore exitosa.",
    "Firestore test failed.": "La prueba de Firestore falló.",
    "Firestore auth error: user verification failed.":
        "Error de autenticación de Firestore: falló la verificación del usuario.",
    "Firestore counter write failed.":
        "Error al escribir el contador de Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Falta autenticación de Firestore: escritura de ig_users bloqueada.",
    "Firestore ig_users write failed.":
        "Error al escribir en Firestore ig_users.",
    "User": "Usuario",
    "Opening consent form...": "Abriendo formulario de consentimiento...",
    "Your consent preference was updated.":
        "Su preferencia de consentimiento fue actualizada.",
    "Consent update failed. Please try again.":
        "Error en la actualización del consentimiento. Por favor inténtalo de nuevo.",
    "Your account is blocked": "Tu cuenta está bloqueada",
    "Access is restricted for this account.":
        "El acceso está restringido para esta cuenta.",
    "Starting purchase...": "Iniciando compra...",
    "Purchase cancelled.": "Compra cancelada.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium activo ✅ Los anuncios y los tiempos de espera están deshabilitados.",
    "Purchase failed. Please try again.":
        "Compra fallida. Por favor inténtalo de nuevo.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Se requiere verificación de sesión. Verifique su cuenta en la aplicación de Instagram e inténtelo nuevamente.",
    "Instagram returned no data.": "Instagram no arrojó datos.",
    "Session verification failed. Please log in again.":
        "La verificación de la sesión falló. Por favor inicia sesión nuevamente.",
    "Open Instagram": "Abrir Instagram",
    "Instagram message": "mensaje de instagram",
    "Loading stories...": "Cargando historias...",
    "No data": "Sin datos",
    "NEW": "NUEVO",
    "Login": "Acceso",
    "Session verified, redirecting...": "Sesión verificada, redireccionando...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ESPACIO PUBLICITARIO",
    "Admin mode active": "Modo administrador activo",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Estamos evolucionando cada día para brindarte una mejor experiencia. Sus comentarios son valiosos para nosotros: ¡nos encantaría saber de usted!",
    "Please log in to start the analysis.":
        "Por favor inicie sesión para iniciar el análisis.",
    "Welcome, {username}": "Bienvenido, {username}",
    "REFRESH DATA": "ACTUALIZAR DATOS",
    "LOG IN WITH INSTAGRAM": "INICIAR SESIÓN CON INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analizando datos...\nEsto podría tardar un momento.",
    "Processing data...\nAlmost done.": "Procesando datos...\nCasi terminado.",
    "Loading ad...\nPlease wait.": "Cargando anuncio...\nPor favor espera.",
    "Google ad warning: {reason}": "Advertencia de anuncio de Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Todos los análisis se procesan de forma segura localmente en su dispositivo.",
    "Total analyses today: {count}": "Análisis totales hoy: {count}",
    "Next analysis": "Próximo análisis",
    "Ready to scan.": "Listo para escanear.",
    "Analysis available now": "Análisis disponible ahora",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "El análisis ya está disponible, pero ejecutar análisis seguidos puede poner su cuenta en riesgo.",
    "Please wait": "Espere por favor",
    "Warning": "Advertencia",
    "Next analysis: {time}": "Próximo análisis: {time}",
    "WATCH AD AND START ANALYSIS": "VER EL ANUNCIO Y COMENZAR EL ANÁLISIS",
    "START ANALYSIS": "INICIAR ANÁLISIS",
    "Start analysis?": "¿Iniciar análisis?",
    "Reset App Data": "Restablecer datos de la aplicación",
    "This will wipe all local data and session cookies. Are you sure?":
        "Esto borrará todos los datos locales y las cookies de sesión. ¿Está seguro?",
    "CANCEL": "CANCELAR",
    "DELETE": "BORRAR",
    "Error": "Error",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Error al recuperar datos: {err}\n\nSolución de problemas: intente cerrar sesión y volver a iniciarla.",
    "Followers": "Seguidores",
    "Following": "Siguiente",
    "New Followers": "Nuevos seguidores",
    "Not Following Back": "No seguir atrás",
    "Lost Followers": "Seguidores perdidos",
    "Legal Disclaimer": "Aviso Legal",
    "Unfollowed Users": "Usuarios no seguidos",
    "Rate Us": "Califícanos",
    "Contact Us": "Contáctenos",
    "Remove Ads & Wait Times": "Eliminar anuncios y tiempos de espera",
    "This box is currently under test.":
        "Esta caja está actualmente bajo prueba.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Mira historias en secreto o haz zoom en las fotos de perfil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Inicie sesión para ver historias en secreto y ampliar las fotos del perfil.",
    "Will be shown after the ad, please wait.":
        "Se mostrará después del anuncio, espere.",
    "What would you like to do?": "¿Qué te gustaría hacer?",
    "Enlarge profile photo": "Ampliar foto de perfil",
    "Watch story secretly": "Ver historia en secreto",
    "No story data available.": "No hay datos de la historia disponibles.",
    "I HAVE READ AND AGREE": "HE LEÍDO Y ACEPTO",
    "Withdraw Consent": "Retirar el consentimiento",
    "Confirm": "Confirmar",
    "Your consent settings will be reset. Are you sure?":
        "Se restablecerá su configuración de consentimiento. ¿Está seguro?",
    "Yes": "Sí",
    "Cancel": "Cancelar",
    "Session verified, redirecting securely...":
        "Sesión verificada, redireccionando de forma segura...",
    "Analysis complete ✅": "Análisis completo ✅",
    "Purchases are not available right now. Please try again later.":
        "Las compras no están disponibles en este momento. Inténtelo de nuevo más tarde.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Compra completada, pero Premium aún no está activo. Por favor inténtalo de nuevo.",
    "Welcome to Premium! Ads and wait times are removed.":
        "¡Bienvenido a Premium! Se eliminan los anuncios y los tiempos de espera.",
    "Your Premium membership is active.": "Tu membresía Premium está activa.",
    "Restore Purchases": "Restaurar compras",
    "RESTORE": "RESTAURAR",
    "Restoring purchases...": "Restaurando compras...",
    "Purchases restored ✅": "Compras restauradas ✅",
    "No purchases to restore.": "No hay compras para restaurar.",
    "Restore failed: {err}": "Error de restauración: {err}",
    "Enter PIN": "Introducir PIN",
    "PIN accepted, timer reset ✅": "PIN aceptado, reinicio del temporizador ✅",
    "Invalid PIN": "PIN no válido",
    "OK": "DE ACUERDO",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Al descargar y utilizar esta aplicación, se considera que cada Usuario ha leído, comprendido y aceptado irrevocablemente de antemano el texto de \"Términos de uso y descargo de responsabilidad\" que aparece a continuación:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artículo 1: Privacidad de datos y arquitectura de procesamiento local",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT es un software del \"lado del cliente\". Las credenciales de inicio de sesión del Usuario (nombre de usuario, contraseña, cookies de sesión) en ningún caso se transmiten ni se almacenan en un servidor externo. Todas las actividades de procesamiento de datos ocurren exclusivamente dentro de la memoria temporal (RAM) y el almacenamiento local del dispositivo del Usuario. La aplicación funciona como un 'envoltorio de navegador' que opera a través de la interfaz de Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Artículo 2: Riesgos de plataformas de terceros",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) se reserva el derecho de restringir el uso de software de terceros según las políticas de su plataforma. Todos los riesgos, incluidos, entre otros, 'bloqueos de acciones', 'restricciones de cuenta', 'shadowbans' o 'cierres de cuenta' que puedan surgir del uso de la aplicación, pertenecen exclusivamente al Usuario. El desarrollador de VERDICT no se hace responsable de ningún daño directo o indirecto resultante de dichas sanciones administrativas.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artículo 3: Descargo de responsabilidad de garantía y limitación de responsabilidad",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Este software se proporciona \"TAL CUAL\" y \"SEGÚN DISPONIBILIDAD\". No se garantiza el 100% de precisión, continuidad o comerciabilidad de los resultados del análisis proporcionados por el software. El Usuario reconoce que cualquier resultado que surja de transacciones legales o comerciales basadas en los datos de la aplicación es de su propia responsabilidad; y declara y se compromete a mantener indemne al desarrollador frente a todos los reclamos, juicios y quejas.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artículo 4: Aviso de Propiedad Intelectual e Independencia",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT es un proyecto de desarrollador independiente. Las marcas 'Instagram', 'Facebook' y 'Meta' son marcas registradas de Meta Platforms, Inc. Esta aplicación no tiene ninguna asociación comercial, acuerdo de patrocinio ni afiliación oficial con las empresas antes mencionadas.",
    "Article 5: Service Continuity and Platform Changes":
        "Artículo 5: Continuidad del Servicio y Cambios de Plataforma",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Los cambios fundamentales en la API de Instagram o la infraestructura web pueden hacer que la aplicación pierda su funcionalidad parcial o completamente. El desarrollador no se compromete a actualizar la aplicación ni a mantener el servicio en respuesta a dichos cambios de infraestructura, que se consideran \"fuerza mayor\".",
    "Analysis complete, results will be shown after the ad.":
        "Análisis completo, los resultados se mostrarán después del anuncio.",
    "Analysis failed": "El análisis falló",
    "Reason: {reason}": "Motivo: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Consejo: Cerrar sesión y volver a iniciarla puede resultar útil.",
    "Quick check: Counts are the same. No changes detected.":
        "Comprobación rápida: los recuentos son los mismos. No se detectaron cambios.",
    "Daily Metrics": "Métricas diarias",
    "Active users": "Usuarios activos",
    "Daily queries": "Consultas diarias",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Se interrumpió la carga de datos: datos del seguidor incompletos ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Se interrumpió la carga de datos: los siguientes datos están incompletos ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Se interrumpió la carga de datos: Instagram devolvió datos vacíos.",
    "Data loading stopped due to an unexpected error.":
        "La carga de datos se detuvo debido a un error inesperado.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram devolvió una advertencia de comportamiento automatizado. Dejamos de obtener datos por seguridad.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram solicitó verificación de seguridad. Verifica en la aplicación de Instagram y vuelve a intentarlo.",
    "Session is invalid or waiting for verification. Please log in again.":
        "La sesión no es válida o está esperando verificación. Por favor inicia sesión nuevamente.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Se enviaron demasiadas solicitudes. La carga de datos se interrumpió por seguridad.",
    "Data loading could not complete due to a connection issue.":
        "La carga de datos no pudo completarse debido a un problema de conexión.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram devolvió un error (HTTP {code}). La carga de datos fue interrumpida.",
    "Instagram security verification is required (story data could not be fetched).":
        "Se requiere verificación de seguridad de Instagram (no se pudieron recuperar los datos de la historia).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "No se pudieron recuperar los datos de la historia. Por lo general, esto se debe a la verificación de Instagram, restricciones temporales de API o una interrupción de la conexión. Inténtelo de nuevo en 2 o 3 minutos.",
    "Could not fetch story data. Please try again shortly.":
        "No se pudieron recuperar los datos de la historia. Inténtelo de nuevo en breve.",
    "Secret Mode": "Modo secreto",
    "Starting VERDICT...": "Iniciando VEREDICTO...",
    "DID YOU KNOW?": "¿SABÍAS?",
    "Estimated time left: {time}": "Tiempo restante estimado: {time}",
    "Estimating remaining time...": "Estimando el tiempo restante...",
    "LOG OUT": "FINALIZAR LA SESIÓN",
    "Open Profile": "Abrir perfil",
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
    "Analysis Time!": "¡Tiempo de análisis!",
    "CLOSE": "CERCA",
    "SYSTEM UNDER MAINTENANCE": "SISTEMA EN MANTENIMIENTO",
    "Bio Planner": "Planificador biológico",
    "Store link not set.": "Enlace de la tienda no establecido.",
    "Invalid store link.": "Enlace de tienda no válido.",
    "Could not open the link.": "No se pudo abrir el enlace.",
    "Please try again.": "Por favor inténtalo de nuevo.",
    "Show error": "Mostrar error",
    "Exception": "Excepción",
    "Load error": "error de carga",
    "Code": "Código",
    "Timeout": "Se acabó el tiempo",
    "REST probe failed: missing auth.":
        "Falló la sonda REST: falta autenticación.",
    "REST probe success (Firestore endpoint reachable).":
        "Éxito de la sonda REST (se puede acceder al punto final de Firestore).",
    "REST probe failed (check logs).":
        "La sonda REST falló (verifique los registros).",
    "Firebase Auth probe failed.":
        "Error en la prueba de autenticación de Firebase.",
    "Firebase Auth probe success.":
        "La investigación de Firebase Auth fue exitosa.",
    "Firebase token probe failed.": "Error en la sonda del token de Firebase.",
    "CRITICAL DIAGNOSTIC ERROR": "ERROR DE DIAGNÓSTICO CRÍTICO",
    "COPY": "COPIAR",
    "OPEN LOGS": "ABRIR REGISTROS",
    "Firebase": "base de fuego",
    "Store": "Almacenar",
    "Copy all": "Copiar todo",
    "Close": "Cerca",
    "Auth Probe": "Sonda de autenticación",
    "Write Test": "Escribir prueba",
    "REST Probe": "Sonda de descanso",
    "Restore Test": "Restaurar prueba",
    "Firebase auth error: user verification failed.":
        "Error de autenticación de Firebase: falló la verificación del usuario.",
    "Firestore test write successful.":
        "Escritura de prueba de Firestore exitosa.",
    "Firestore test failed.": "La prueba de Firestore falló.",
    "Firestore auth error: user verification failed.":
        "Error de autenticación de Firestore: falló la verificación del usuario.",
    "Firestore counter write failed.":
        "Error al escribir el contador de Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Falta autenticación de Firestore: escritura de ig_users bloqueada.",
    "Firestore ig_users write failed.":
        "Error al escribir en Firestore ig_users.",
    "User": "Usuario",
    "Opening consent form...": "Abriendo formulario de consentimiento...",
    "Your consent preference was updated.":
        "Su preferencia de consentimiento fue actualizada.",
    "Consent update failed. Please try again.":
        "Error en la actualización del consentimiento. Por favor inténtalo de nuevo.",
    "Your account is blocked": "Tu cuenta está bloqueada",
    "Access is restricted for this account.":
        "El acceso está restringido para esta cuenta.",
    "Starting purchase...": "Iniciando compra...",
    "Purchase cancelled.": "Compra cancelada.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium activo ✅ Los anuncios y los tiempos de espera están deshabilitados.",
    "Purchase failed. Please try again.":
        "Compra fallida. Por favor inténtalo de nuevo.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Se requiere verificación de sesión. Verifique su cuenta en la aplicación de Instagram e inténtelo nuevamente.",
    "Instagram returned no data.": "Instagram no arrojó datos.",
    "Session verification failed. Please log in again.":
        "La verificación de la sesión falló. Por favor inicia sesión nuevamente.",
    "Open Instagram": "Abrir Instagram",
    "Instagram message": "mensaje de instagram",
    "Loading stories...": "Cargando historias...",
    "No data": "Sin datos",
    "NEW": "NUEVO",
    "Login": "Acceso",
    "Session verified, redirecting...": "Sesión verificada, redireccionando...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ESPACIO PUBLICITARIO",
    "Admin mode active": "Modo administrador activo",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Estamos evolucionando cada día para brindarte una mejor experiencia. Sus comentarios son valiosos para nosotros: ¡nos encantaría saber de usted!",
    "Please log in to start the analysis.":
        "Por favor inicie sesión para iniciar el análisis.",
    "Welcome, {username}": "Bienvenido, {username}",
    "REFRESH DATA": "ACTUALIZAR DATOS",
    "LOG IN WITH INSTAGRAM": "INICIAR SESIÓN CON INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analizando datos...\nEsto podría tardar un momento.",
    "Processing data...\nAlmost done.": "Procesando datos...\nCasi terminado.",
    "Loading ad...\nPlease wait.": "Cargando anuncio...\nPor favor espera.",
    "Google ad warning: {reason}": "Advertencia de anuncio de Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Todos los análisis se procesan de forma segura localmente en su dispositivo.",
    "Total analyses today: {count}": "Análisis totales hoy: {count}",
    "Next analysis": "Próximo análisis",
    "Ready to scan.": "Listo para escanear.",
    "Analysis available now": "Análisis disponible ahora",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "El análisis ya está disponible, pero ejecutar análisis seguidos puede poner su cuenta en riesgo.",
    "Please wait": "Espere por favor",
    "Warning": "Advertencia",
    "Next analysis: {time}": "Próximo análisis: {time}",
    "WATCH AD AND START ANALYSIS": "VER EL ANUNCIO Y COMENZAR EL ANÁLISIS",
    "START ANALYSIS": "INICIAR ANÁLISIS",
    "Start analysis?": "¿Iniciar análisis?",
    "Reset App Data": "Restablecer datos de la aplicación",
    "This will wipe all local data and session cookies. Are you sure?":
        "Esto borrará todos los datos locales y las cookies de sesión. ¿Está seguro?",
    "CANCEL": "CANCELAR",
    "DELETE": "BORRAR",
    "Error": "Error",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Error al recuperar datos: {err}\n\nSolución de problemas: intente cerrar sesión y volver a iniciarla.",
    "Followers": "Seguidores",
    "Following": "Siguiente",
    "New Followers": "Nuevos seguidores",
    "Not Following Back": "No seguir atrás",
    "Lost Followers": "Seguidores perdidos",
    "Legal Disclaimer": "Aviso Legal",
    "Unfollowed Users": "Usuarios no seguidos",
    "Rate Us": "Califícanos",
    "Contact Us": "Contáctenos",
    "Remove Ads & Wait Times": "Eliminar anuncios y tiempos de espera",
    "This box is currently under test.":
        "Esta caja está actualmente bajo prueba.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Mira historias en secreto o haz zoom en las fotos de perfil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Inicie sesión para ver historias en secreto y ampliar las fotos del perfil.",
    "Will be shown after the ad, please wait.":
        "Se mostrará después del anuncio, espere.",
    "What would you like to do?": "¿Qué te gustaría hacer?",
    "Enlarge profile photo": "Ampliar foto de perfil",
    "Watch story secretly": "Ver historia en secreto",
    "No story data available.": "No hay datos de la historia disponibles.",
    "I HAVE READ AND AGREE": "HE LEÍDO Y ACEPTO",
    "Withdraw Consent": "Retirar el consentimiento",
    "Confirm": "Confirmar",
    "Your consent settings will be reset. Are you sure?":
        "Se restablecerá su configuración de consentimiento. ¿Está seguro?",
    "Yes": "Sí",
    "Cancel": "Cancelar",
    "Session verified, redirecting securely...":
        "Sesión verificada, redireccionando de forma segura...",
    "Analysis complete ✅": "Análisis completo ✅",
    "Purchases are not available right now. Please try again later.":
        "Las compras no están disponibles en este momento. Inténtelo de nuevo más tarde.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Compra completada, pero Premium aún no está activo. Por favor inténtalo de nuevo.",
    "Welcome to Premium! Ads and wait times are removed.":
        "¡Bienvenido a Premium! Se eliminan los anuncios y los tiempos de espera.",
    "Your Premium membership is active.": "Tu membresía Premium está activa.",
    "Restore Purchases": "Restaurar compras",
    "RESTORE": "RESTAURAR",
    "Restoring purchases...": "Restaurando compras...",
    "Purchases restored ✅": "Compras restauradas ✅",
    "No purchases to restore.": "No hay compras para restaurar.",
    "Restore failed: {err}": "Error de restauración: {err}",
    "Enter PIN": "Introducir PIN",
    "PIN accepted, timer reset ✅": "PIN aceptado, reinicio del temporizador ✅",
    "Invalid PIN": "PIN no válido",
    "OK": "DE ACUERDO",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Al descargar y utilizar esta aplicación, se considera que cada Usuario ha leído, comprendido y aceptado irrevocablemente de antemano el texto de \"Términos de uso y descargo de responsabilidad\" que aparece a continuación:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artículo 1: Privacidad de datos y arquitectura de procesamiento local",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT es un software del \"lado del cliente\". Las credenciales de inicio de sesión del Usuario (nombre de usuario, contraseña, cookies de sesión) en ningún caso se transmiten ni se almacenan en un servidor externo. Todas las actividades de procesamiento de datos ocurren exclusivamente dentro de la memoria temporal (RAM) y el almacenamiento local del dispositivo del Usuario. La aplicación funciona como un 'envoltorio de navegador' que opera a través de la interfaz de Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Artículo 2: Riesgos de plataformas de terceros",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) se reserva el derecho de restringir el uso de software de terceros según las políticas de su plataforma. Todos los riesgos, incluidos, entre otros, 'bloqueos de acciones', 'restricciones de cuenta', 'shadowbans' o 'cierres de cuenta' que puedan surgir del uso de la aplicación, pertenecen exclusivamente al Usuario. El desarrollador de VERDICT no se hace responsable de ningún daño directo o indirecto resultante de dichas sanciones administrativas.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artículo 3: Descargo de responsabilidad de garantía y limitación de responsabilidad",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Este software se proporciona \"TAL CUAL\" y \"SEGÚN DISPONIBILIDAD\". No se garantiza el 100% de precisión, continuidad o comerciabilidad de los resultados del análisis proporcionados por el software. El Usuario reconoce que cualquier resultado que surja de transacciones legales o comerciales basadas en los datos de la aplicación es de su propia responsabilidad; y declara y se compromete a mantener indemne al desarrollador frente a todos los reclamos, juicios y quejas.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artículo 4: Aviso de Propiedad Intelectual e Independencia",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT es un proyecto de desarrollador independiente. Las marcas 'Instagram', 'Facebook' y 'Meta' son marcas registradas de Meta Platforms, Inc. Esta aplicación no tiene ninguna asociación comercial, acuerdo de patrocinio ni afiliación oficial con las empresas antes mencionadas.",
    "Article 5: Service Continuity and Platform Changes":
        "Artículo 5: Continuidad del Servicio y Cambios de Plataforma",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Los cambios fundamentales en la API de Instagram o la infraestructura web pueden hacer que la aplicación pierda su funcionalidad parcial o completamente. El desarrollador no se compromete a actualizar la aplicación ni a mantener el servicio en respuesta a dichos cambios de infraestructura, que se consideran \"fuerza mayor\".",
    "Analysis complete, results will be shown after the ad.":
        "Análisis completo, los resultados se mostrarán después del anuncio.",
    "Analysis failed": "El análisis falló",
    "Reason: {reason}": "Motivo: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Consejo: Cerrar sesión y volver a iniciarla puede resultar útil.",
    "Quick check: Counts are the same. No changes detected.":
        "Comprobación rápida: los recuentos son los mismos. No se detectaron cambios.",
    "Daily Metrics": "Métricas diarias",
    "Active users": "Usuarios activos",
    "Daily queries": "Consultas diarias",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Se interrumpió la carga de datos: datos del seguidor incompletos ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Se interrumpió la carga de datos: los siguientes datos están incompletos ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Se interrumpió la carga de datos: Instagram devolvió datos vacíos.",
    "Data loading stopped due to an unexpected error.":
        "La carga de datos se detuvo debido a un error inesperado.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram devolvió una advertencia de comportamiento automatizado. Dejamos de obtener datos por seguridad.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram solicitó verificación de seguridad. Verifica en la aplicación de Instagram y vuelve a intentarlo.",
    "Session is invalid or waiting for verification. Please log in again.":
        "La sesión no es válida o está esperando verificación. Por favor inicia sesión nuevamente.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Se enviaron demasiadas solicitudes. La carga de datos se interrumpió por seguridad.",
    "Data loading could not complete due to a connection issue.":
        "La carga de datos no pudo completarse debido a un problema de conexión.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram devolvió un error (HTTP {code}). La carga de datos fue interrumpida.",
    "Instagram security verification is required (story data could not be fetched).":
        "Se requiere verificación de seguridad de Instagram (no se pudieron recuperar los datos de la historia).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "No se pudieron recuperar los datos de la historia. Por lo general, esto se debe a la verificación de Instagram, restricciones temporales de API o una interrupción de la conexión. Inténtelo de nuevo en 2 o 3 minutos.",
    "Could not fetch story data. Please try again shortly.":
        "No se pudieron recuperar los datos de la historia. Inténtelo de nuevo en breve.",
    "Secret Mode": "Modo secreto",
    "Starting VERDICT...": "Iniciando VEREDICTO...",
    "DID YOU KNOW?": "¿SABÍAS?",
    "Estimated time left: {time}": "Tiempo restante estimado: {time}",
    "Estimating remaining time...": "Estimando el tiempo restante...",
    "LOG OUT": "FINALIZAR LA SESIÓN",
    "Open Profile": "Abrir perfil",
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
    "Analysis Time!": "विश्लेषण का समय!",
    "CLOSE": "बंद करना",
    "SYSTEM UNDER MAINTENANCE": "रखरखाव के तहत प्रणाली",
    "Bio Planner": "बायो प्लानर",
    "Store link not set.": "स्टोर लिंक सेट नहीं है.",
    "Invalid store link.": "अमान्य स्टोर लिंक.",
    "Could not open the link.": "लिंक नहीं खुल सका.",
    "Please try again.": "कृपया पुन: प्रयास करें।",
    "Show error": "त्रुटि दिखाएँ",
    "Exception": "अपवाद",
    "Load error": "लोड त्रुटि",
    "Code": "कोड",
    "Timeout": "समयबाह्य",
    "REST probe failed: missing auth.": "REST जांच विफल: प्रमाणीकरण गुम है।",
    "REST probe success (Firestore endpoint reachable).":
        "REST जांच सफल (फ़ायरस्टोर एंडपॉइंट पहुंच योग्य)।",
    "REST probe failed (check logs).": "REST जांच विफल रही (लॉग जांचें)।",
    "Firebase Auth probe failed.": "फायरबेस प्रामाणिक जांच विफल रही।",
    "Firebase Auth probe success.": "फायरबेस प्रामाणिक जांच सफल रही।",
    "Firebase token probe failed.": "फायरबेस टोकन जांच विफल रही।",
    "CRITICAL DIAGNOSTIC ERROR": "गंभीर निदान संबंधी त्रुटि",
    "COPY": "कॉपी",
    "OPEN LOGS": "लॉग खोलें",
    "Firebase": "फायरबेस",
    "Store": "इकट्ठा करना",
    "Copy all": "सभी को कॉपी करें",
    "Close": "बंद करना",
    "Auth Probe": "प्रामाणिक जांच",
    "Write Test": "परीक्षण लिखें",
    "REST Probe": "बाकी जांच",
    "Restore Test": "परीक्षण पुनर्स्थापित करें",
    "Firebase auth error: user verification failed.":
        "फायरबेस प्रमाणीकरण त्रुटि: उपयोगकर्ता सत्यापन विफल रहा।",
    "Firestore test write successful.": "फ़ायरस्टोर परीक्षण लेखन सफल.",
    "Firestore test failed.": "फायरस्टोर परीक्षण विफल रहा.",
    "Firestore auth error: user verification failed.":
        "फायरस्टोर प्रमाणीकरण त्रुटि: उपयोगकर्ता सत्यापन विफल रहा।",
    "Firestore counter write failed.": "फायरस्टोर काउंटर लिखना विफल रहा।",
    "Firestore auth missing: ig_users write blocked.":
        "फायरस्टोर का प्रमाणीकरण अनुपलब्ध है: ig_users का लेखन अवरुद्ध है।",
    "Firestore ig_users write failed.": "फायरस्टोर ig_users लिखना विफल रहा।",
    "User": "उपयोगकर्ता",
    "Opening consent form...": "सहमति प्रपत्र खुल रहा है...",
    "Your consent preference was updated.":
        "आपकी सहमति प्राथमिकता अपडेट कर दी गई है.",
    "Consent update failed. Please try again.":
        "सहमति अद्यतन विफल रहा. कृपया पुन: प्रयास करें।",
    "Your account is blocked": "आपका खाता ब्लॉक कर दिया गया है",
    "Access is restricted for this account.":
        "इस खाते के लिए पहुंच प्रतिबंधित है.",
    "Starting purchase...": "खरीदारी शुरू हो रही है...",
    "Purchase cancelled.": "खरीदारी रद्द कर दी गई.",
    "Premium active ✅ Ads and wait times are disabled.":
        "प्रीमियम सक्रिय ✅ विज्ञापन और प्रतीक्षा समय अक्षम हैं।",
    "Purchase failed. Please try again.":
        "खरीदारी विफल. कृपया पुन: प्रयास करें।",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "सत्र सत्यापन आवश्यक है. कृपया इंस्टाग्राम ऐप में अपना अकाउंट सत्यापित करें और पुनः प्रयास करें।",
    "Instagram returned no data.": "इंस्टाग्राम ने कोई डेटा नहीं लौटाया.",
    "Session verification failed. Please log in again.":
        "सत्र सत्यापन विफल रहा. कृपया फिर भाग लें।",
    "Open Instagram": "इंस्टाग्राम खोलें",
    "Instagram message": "इंस्टाग्राम संदेश",
    "Loading stories...": "कहानियाँ लोड हो रही हैं...",
    "No data": "कोई डेटा नहीं",
    "NEW": "नया",
    "Login": "लॉग इन करें",
    "Session verified, redirecting...": "सत्र सत्यापित, पुनर्निर्देशन...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "विज्ञापन स्थान",
    "Admin mode active": "एडमिन मोड सक्रिय",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "हम आपको बेहतर अनुभव प्रदान करने के लिए हर दिन विकसित हो रहे हैं। आपकी प्रतिक्रिया हमारे लिए मूल्यवान है—हमें आपसे सुनना अच्छा लगेगा!",
    "Please log in to start the analysis.":
        "विश्लेषण शुरू करने के लिए कृपया लॉग इन करें।",
    "Welcome, {username}": "स्वागत है, {username}",
    "REFRESH DATA": "डेटा ताज़ा करें",
    "LOG IN WITH INSTAGRAM": "इंस्टाग्राम से लॉग इन करें",
    "Analyzing data...\nThis might take a moment.":
        "डेटा का विश्लेषण किया जा रहा है...\nइसमें एक क्षण लग सकता है.",
    "Processing data...\nAlmost done.":
        "डेटा संसाधित किया जा रहा है...\nलगभग पूरा हो गया.",
    "Loading ad...\nPlease wait.":
        "विज्ञापन लोड हो रहा है...\nकृपया प्रतीक्षा करें.",
    "Google ad warning: {reason}": "Google विज्ञापन चेतावनी: {reason}",
    "All analysis is securely processed locally on your device.":
        "सभी विश्लेषण आपके डिवाइस पर स्थानीय रूप से सुरक्षित रूप से संसाधित किए जाते हैं।",
    "Total analyses today: {count}": "आज का कुल विश्लेषण: {count}",
    "Next analysis": "अगला विश्लेषण",
    "Ready to scan.": "स्कैन करने के लिए तैयार.",
    "Analysis available now": "विश्लेषण अब उपलब्ध है",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "विश्लेषण अब उपलब्ध है, लेकिन लगातार विश्लेषण चलाने से आपका खाता जोखिम में पड़ सकता है।",
    "Please wait": "कृपया प्रतीक्षा करें",
    "Warning": "चेतावनी",
    "Next analysis: {time}": "अगला विश्लेषण: {time}",
    "WATCH AD AND START ANALYSIS": "विज्ञापन देखें और विश्लेषण शुरू करें",
    "START ANALYSIS": "विश्लेषण प्रारंभ करें",
    "Start analysis?": "विश्लेषण प्रारंभ करें?",
    "Reset App Data": "ऐप डेटा रीसेट करें",
    "This will wipe all local data and session cookies. Are you sure?":
        "यह सभी स्थानीय डेटा और सत्र कुकीज़ मिटा देगा। क्या आपको यकीन है?",
    "CANCEL": "रद्द करना",
    "DELETE": "मिटाना",
    "Error": "गलती",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "डेटा पुनर्प्राप्ति विफल: {err}\n\nसमस्या निवारण: लॉग आउट करने और वापस लॉग इन करने का प्रयास करें।",
    "Followers": "समर्थक",
    "Following": "अगले",
    "New Followers": "नए अनुयायी",
    "Not Following Back": "फॉलो बैक नहीं",
    "Lost Followers": "खोए हुए अनुयायी",
    "Legal Disclaimer": "कानूनी अस्वीकरण",
    "Unfollowed Users": "अनफॉलो किए गए उपयोगकर्ता",
    "Rate Us": "हमें रेटिंग दें",
    "Contact Us": "हमसे संपर्क करें",
    "Remove Ads & Wait Times": "विज्ञापन हटाएँ और प्रतीक्षा समय",
    "This box is currently under test.": "इस बॉक्स का अभी परीक्षण चल रहा है.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "गुप्त रूप से कहानियाँ देखें या प्रोफ़ाइल फ़ोटो ज़ूम करें",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "कृपया कहानियों को गुप्त रूप से देखने और प्रोफ़ाइल फ़ोटो को बड़ा करने के लिए लॉग इन करें।",
    "Will be shown after the ad, please wait.":
        "विज्ञापन बाद में दिखाया जाएगा, कृपया प्रतीक्षा करें।",
    "What would you like to do?": "आप क्या करना चाहेंगे?",
    "Enlarge profile photo": "प्रोफ़ाइल फ़ोटो बड़ा करें",
    "Watch story secretly": "छिपकर देखो कहानी",
    "No story data available.": "कोई कहानी डेटा उपलब्ध नहीं है.",
    "I HAVE READ AND AGREE": "मैंने पढ़ा है और इस बात से सहमत है",
    "Withdraw Consent": "सहमति वापस लें",
    "Confirm": "पुष्टि करना",
    "Your consent settings will be reset. Are you sure?":
        "आपकी सहमति सेटिंग रीसेट कर दी जाएंगी. क्या आपको यकीन है?",
    "Yes": "हाँ",
    "Cancel": "रद्द करना",
    "Session verified, redirecting securely...":
        "सत्र सत्यापित, सुरक्षित रूप से पुनर्निर्देशन...",
    "Analysis complete ✅": "विश्लेषण पूरा ✅",
    "Purchases are not available right now. Please try again later.":
        "अभी खरीदारी उपलब्ध नहीं है. कृपया बाद में पुन: प्रयास करें।",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "खरीदारी पूरी हो गई, लेकिन प्रीमियम अभी तक सक्रिय नहीं है। कृपया पुन: प्रयास करें।",
    "Welcome to Premium! Ads and wait times are removed.":
        "प्रीमियम में आपका स्वागत है! विज्ञापन और प्रतीक्षा समय हटा दिए जाते हैं.",
    "Your Premium membership is active.": "आपकी प्रीमियम सदस्यता सक्रिय है.",
    "Restore Purchases": "खरीदारी वापस लौटाएं",
    "RESTORE": "पुनर्स्थापित करना",
    "Restoring purchases...": "खरीदारी बहाल की जा रही है...",
    "Purchases restored ✅": "खरीदारी बहाल ✅",
    "No purchases to restore.": "पुनर्स्थापित करने के लिए कोई खरीदारी नहीं.",
    "Restore failed: {err}": "पुनर्स्थापना विफल: {err}",
    "Enter PIN": "पिन दर्ज करें",
    "PIN accepted, timer reset ✅": "पिन स्वीकृत, टाइमर रीसेट ✅",
    "Invalid PIN": "अमान्य पिन",
    "OK": "ठीक है",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "इस एप्लिकेशन को डाउनलोड करने और उपयोग करने से, यह माना जाएगा कि प्रत्येक उपयोगकर्ता ने नीचे दिए गए \"उपयोग की शर्तें और अस्वीकरण\" पाठ को पहले ही पढ़, समझ लिया है और अपरिवर्तनीय रूप से स्वीकार कर लिया है:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "अनुच्छेद 1: डेटा गोपनीयता और स्थानीय प्रसंस्करण वास्तुकला",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT 'क्लाइंट-साइड' सॉफ़्टवेयर है। उपयोगकर्ता के लॉगिन क्रेडेंशियल (उपयोगकर्ता नाम, पासवर्ड, सत्र कुकीज़) किसी भी परिस्थिति में बाहरी सर्वर पर प्रेषित या संग्रहीत नहीं होते हैं। सभी डेटा प्रोसेसिंग गतिविधियाँ विशेष रूप से उपयोगकर्ता के डिवाइस की अस्थायी मेमोरी (RAM) और स्थानीय स्टोरेज के भीतर होती हैं। एप्लिकेशन इंस्टाग्राम इंटरफ़ेस पर संचालित होने वाले 'ब्राउज़र-रैपर' के रूप में कार्य करता है।",
    "Article 2: Third-Party Platform Risks":
        "अनुच्छेद 2: तृतीय-पक्ष प्लेटफ़ॉर्म जोखिम",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "इंस्टाग्राम (मेटा प्लेटफ़ॉर्म, इंक.) अपनी प्लेटफ़ॉर्म नीतियों के अनुसार तीसरे पक्ष के सॉफ़्टवेयर के उपयोग को प्रतिबंधित करने का अधिकार सुरक्षित रखता है। एप्लिकेशन के उपयोग से उत्पन्न होने वाले सभी जोखिम, जिनमें 'एक्शन ब्लॉक', 'खाता प्रतिबंध', 'शैडोबैन', या 'खाता बंद करना' शामिल हैं, लेकिन इन्हीं तक सीमित नहीं हैं, विशेष रूप से उपयोगकर्ता से संबंधित हैं। ऐसे प्रशासनिक प्रतिबंधों के परिणामस्वरूप होने वाले किसी भी प्रत्यक्ष या अप्रत्यक्ष नुकसान के लिए VERDICT डेवलपर को उत्तरदायी नहीं ठहराया जा सकता है।",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "अनुच्छेद 3: वारंटी अस्वीकरण और दायित्व की सीमा",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "यह सॉफ़्टवेयर 'जैसा है' और 'जैसा उपलब्ध है' प्रदान किया गया है। सॉफ़्टवेयर द्वारा प्रदान किए गए विश्लेषण परिणामों की 100% सटीकता, निरंतरता या व्यापारिकता की गारंटी नहीं है। उपयोगकर्ता स्वीकार करता है कि एप्लिकेशन डेटा के आधार पर कानूनी या वाणिज्यिक लेनदेन से उत्पन्न कोई भी परिणाम उनकी स्वयं की जिम्मेदारी है; और डेवलपर को सभी दावों, मुकदमों और शिकायतों से हानिरहित रखने की घोषणा करता है और वचन देता है।",
    "Article 4: Intellectual Property and Independence Notice":
        "अनुच्छेद 4: बौद्धिक संपदा और स्वतंत्रता सूचना",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT एक स्वतंत्र डेवलपर परियोजना है। 'इंस्टाग्राम', 'फेसबुक' और 'मेटा' ब्रांड मेटा प्लेटफॉर्म्स, इंक. के पंजीकृत ट्रेडमार्क हैं। इस एप्लिकेशन की उपरोक्त कंपनियों के साथ कोई व्यावसायिक साझेदारी, प्रायोजन समझौता या आधिकारिक संबद्धता नहीं है।",
    "Article 5: Service Continuity and Platform Changes":
        "अनुच्छेद 5: सेवा निरंतरता और प्लेटफ़ॉर्म परिवर्तन",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "इंस्टाग्राम एपीआई या वेब इन्फ्रास्ट्रक्चर में मूलभूत बदलावों के कारण एप्लिकेशन आंशिक या पूरी तरह से अपनी कार्यक्षमता खो सकता है। डेवलपर ऐसे बुनियादी परिवर्तनों के जवाब में एप्लिकेशन को अपडेट करने या सेवा को बनाए रखने के लिए कोई प्रतिबद्धता नहीं रखता है, जिन्हें \"अप्रत्याशित घटना\" माना जाता है।",
    "Analysis complete, results will be shown after the ad.":
        "विश्लेषण पूरा हो गया, परिणाम विज्ञापन के बाद दिखाए जाएंगे।",
    "Analysis failed": "विश्लेषण विफल रहा",
    "Reason: {reason}": "कारण: {reason}",
    "Tip: Logging out and logging back in may help.":
        "युक्ति: लॉग आउट करने और वापस लॉग इन करने से मदद मिल सकती है।",
    "Quick check: Counts are the same. No changes detected.":
        "त्वरित जाँच: गणनाएँ समान हैं। कोई परिवर्तन नहीं पाया गया.",
    "Daily Metrics": "दैनिक मेट्रिक्स",
    "Active users": "सक्रिय उपयोगकर्ता",
    "Daily queries": "दैनिक प्रश्न",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "डेटा लोडिंग बाधित हुई: अनुयायी डेटा अधूरा ({fetched}/{total})।",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "डेटा लोडिंग बाधित हुई: निम्नलिखित डेटा अधूरा ({fetched}/{total})।",
    "Data loading was interrupted: Instagram returned empty data.":
        "डेटा लोडिंग बाधित हुई: इंस्टाग्राम ने खाली डेटा लौटाया।",
    "Data loading stopped due to an unexpected error.":
        "किसी अप्रत्याशित त्रुटि के कारण डेटा लोड होना रुक गया।",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "इंस्टाग्राम ने एक स्वचालित-व्यवहार चेतावनी लौटा दी। हमने सुरक्षा के लिए डेटा लाना बंद कर दिया।",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "इंस्टाग्राम ने सुरक्षा सत्यापन का अनुरोध किया। इंस्टाग्राम ऐप में सत्यापित करें और पुनः प्रयास करें।",
    "Session is invalid or waiting for verification. Please log in again.":
        "सत्र अमान्य है या सत्यापन की प्रतीक्षा कर रहा है. कृपया फिर भाग लें।",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "बहुत सारे अनुरोध भेजे गए थे. सुरक्षा के लिए डेटा लोडिंग बाधित कर दी गई थी।",
    "Data loading could not complete due to a connection issue.":
        "कनेक्शन समस्या के कारण डेटा लोडिंग पूरी नहीं हो सकी.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "इंस्टाग्राम ने एक त्रुटि लौटाई (HTTP {code})। डेटा लोडिंग बाधित हो गई थी.",
    "Instagram security verification is required (story data could not be fetched).":
        "इंस्टाग्राम सुरक्षा सत्यापन आवश्यक है (स्टोरी डेटा प्राप्त नहीं किया जा सका)।",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "कहानी का डेटा प्राप्त नहीं किया जा सका. आमतौर पर यह इंस्टाग्राम सत्यापन, अस्थायी एपीआई प्रतिबंध या कनेक्शन रुकावट के कारण होता है। कृपया 2-3 मिनट में पुनः प्रयास करें।",
    "Could not fetch story data. Please try again shortly.":
        "कहानी डेटा नहीं लाया जा सका. कृपया शीघ्र ही पुनः प्रयास करें.",
    "Secret Mode": "गुप्त मोड",
    "Starting VERDICT...": "फैसला शुरू हो रहा है...",
    "DID YOU KNOW?": "क्या आप जानते हैं?",
    "Estimated time left: {time}": "अनुमानित समय शेष: {time}",
    "Estimating remaining time...": "शेष समय का अनुमान लगाया जा रहा है...",
    "LOG OUT": "लॉग आउट",
    "Open Profile": "प्रोफ़ाइल खोलें",
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
    "Analysis Time!": "Elemzés ideje!",
    "CLOSE": "KÖZELI",
    "SYSTEM UNDER MAINTENANCE": "RENDSZER KARBANTARTÁS ALATT",
    "Bio Planner": "Biotervező",
    "Store link not set.": "Az áruház linkje nincs beállítva.",
    "Invalid store link.": "Érvénytelen bolti link.",
    "Could not open the link.": "Nem sikerült megnyitni a linket.",
    "Please try again.": "Kérjük, próbálja újra.",
    "Show error": "Hiba megjelenítése",
    "Exception": "Kivétel",
    "Load error": "Betöltési hiba",
    "Code": "Kód",
    "Timeout": "Időtúllépés",
    "REST probe failed: missing auth.":
        "A REST vizsgálat sikertelen: hiányzik a hitelesítés.",
    "REST probe success (Firestore endpoint reachable).":
        "A REST vizsgálat sikeres (a Firestore végpontja elérhető).",
    "REST probe failed (check logs).":
        "A REST vizsgálat sikertelen (ellenőrizze a naplókat).",
    "Firebase Auth probe failed.": "Firebase Auth vizsgálat sikertelen.",
    "Firebase Auth probe success.": "Sikeres Firebase Auth vizsgálat.",
    "Firebase token probe failed.": "A Firebase token vizsgálata meghiúsult.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITIKUS DIAGNOSZTIKAI HIBA",
    "COPY": "MÁSOLAT",
    "OPEN LOGS": "NAPLÓK NYITÁSA",
    "Firebase": "Firebase",
    "Store": "Bolt",
    "Copy all": "Az összes másolása",
    "Close": "Közeli",
    "Auth Probe": "Auth Probe",
    "Write Test": "Írj tesztet",
    "REST Probe": "REST szonda",
    "Restore Test": "Teszt visszaállítása",
    "Firebase auth error: user verification failed.":
        "Firebase hitelesítési hiba: a felhasználó ellenőrzése nem sikerült.",
    "Firestore test write successful.": "A Firestore tesztírás sikeres volt.",
    "Firestore test failed.": "A Firestore teszt sikertelen volt.",
    "Firestore auth error: user verification failed.":
        "Firestore hitelesítési hiba: a felhasználó ellenőrzése nem sikerült.",
    "Firestore counter write failed.":
        "A Firestore számláló írása nem sikerült.",
    "Firestore auth missing: ig_users write blocked.":
        "Hiányzik a Firestore hitelesítés: az ig_users írása blokkolva.",
    "Firestore ig_users write failed.":
        "A Firestore ig_users írása nem sikerült.",
    "User": "Felhasználó",
    "Opening consent form...": "Hozzájárulási űrlap megnyitása...",
    "Your consent preference was updated.":
        "A hozzájárulási preferenciája frissítve lett.",
    "Consent update failed. Please try again.":
        "A hozzájárulás frissítése nem sikerült. Kérjük, próbálja újra.",
    "Your account is blocked": "Fiókja blokkolva van",
    "Access is restricted for this account.":
        "A hozzáférés korlátozott ehhez a fiókhoz.",
    "Starting purchase...": "Vásárlás megkezdése...",
    "Purchase cancelled.": "Vásárlás törölve.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Prémium aktív ✅ A hirdetések és a várakozási idők le vannak tiltva.",
    "Purchase failed. Please try again.":
        "A vásárlás sikertelen. Kérjük, próbálja újra.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Munkamenet-ellenőrzés szükséges. Kérjük, igazolja fiókját az Instagram alkalmazásban, és próbálja újra.",
    "Instagram returned no data.": "Az Instagram nem adott vissza adatokat.",
    "Session verification failed. Please log in again.":
        "A munkamenet ellenőrzése nem sikerült. Kérjük, jelentkezzen be újra.",
    "Open Instagram": "Nyissa meg az Instagramot",
    "Instagram message": "Instagram üzenet",
    "Loading stories...": "Történetek betöltése...",
    "No data": "Nincs adat",
    "NEW": "ÚJ",
    "Login": "Bejelentkezés",
    "Session verified, redirecting...":
        "Munkamenet ellenőrizve, átirányítás...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "HIRDETÉSI HELY",
    "Admin mode active": "Adminisztrációs mód aktív",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Napról napra fejlődünk, hogy jobb élményben legyen részed. Visszajelzése értékes számunkra – szívesen hallanánk!",
    "Please log in to start the analysis.":
        "Kérjük, jelentkezzen be az elemzés elindításához.",
    "Welcome, {username}": "Üdvözöljük, {username}",
    "REFRESH DATA": "AZ ADATOK FRISSÍTÉSE",
    "LOG IN WITH INSTAGRAM": "BEJELENTKEZÉS INSTAGRAMAL",
    "Analyzing data...\nThis might take a moment.":
        "Adatok elemzése...\nEz eltarthat egy pillanatig.",
    "Processing data...\nAlmost done.": "Adatok feldolgozása...\nMajdnem kész.",
    "Loading ad...\nPlease wait.": "Hirdetés betöltése...\nKérjük, várjon.",
    "Google ad warning: {reason}": "Google hirdetési figyelmeztetés: {reason}",
    "All analysis is securely processed locally on your device.":
        "Minden elemzés biztonságosan, helyben kerül feldolgozásra az eszközön.",
    "Total analyses today: {count}": "Összes elemzés ma: {count}",
    "Next analysis": "Következő elemzés",
    "Ready to scan.": "Készen áll a beolvasásra.",
    "Analysis available now": "Az elemzés már elérhető",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Az elemzés már elérhető, de az elemzések egymás utáni futtatása veszélybe sodorhatja fiókját.",
    "Please wait": "Kérjük, várjon",
    "Warning": "Figyelmeztetés",
    "Next analysis: {time}": "Következő elemzés: {time}",
    "WATCH AD AND START ANALYSIS":
        "NÉZD MEG A HIRDETÉST ÉS KEZDJEN EL AZ ELEMZÉST",
    "START ANALYSIS": "AZ ELEMZÉS INDÍTÁSA",
    "Start analysis?": "Elkezdi az elemzést?",
    "Reset App Data": "Alkalmazásadatok visszaállítása",
    "This will wipe all local data and session cookies. Are you sure?":
        "Ezzel törli az összes helyi adatot és munkamenet-cookie-t. Biztos vagy benne?",
    "CANCEL": "MÉGSEM",
    "DELETE": "TÖRÖL",
    "Error": "Hiba",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Az adatok visszakeresése sikertelen: {err}\n\nHibaelhárítás: Próbáljon meg kijelentkezni, majd újra bejelentkezni.",
    "Followers": "Követői",
    "Following": "Következő",
    "New Followers": "Új követők",
    "Not Following Back": "Nem Követ vissza",
    "Lost Followers": "Elveszett követők",
    "Legal Disclaimer": "Jogi nyilatkozat",
    "Unfollowed Users": "Nem követett felhasználók",
    "Rate Us": "Értékeljen minket",
    "Contact Us": "Lépjen kapcsolatba velünk",
    "Remove Ads & Wait Times":
        "Távolítsa el a hirdetéseket és a várakozási időket",
    "This box is currently under test.":
        "Ez a doboz jelenleg tesztelés alatt áll.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Nézze meg a Stories Secretly (Titokban) vagy a Profilfotók nagyítását",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Kérjük, jelentkezzen be, hogy titokban nézzen történeteket és nagyítsa ki a profilképeket.",
    "Will be shown after the ad, please wait.":
        "A hirdetés után megjelenik, várjon.",
    "What would you like to do?": "mit szeretnél csinálni?",
    "Enlarge profile photo": "Profilfotó nagyítása",
    "Watch story secretly": "Nézze meg a történetet titokban",
    "No story data available.": "Nem állnak rendelkezésre történetadatok.",
    "I HAVE READ AND AGREE": "OLVASSAM ÉS EGYETÉRTEM",
    "Withdraw Consent": "Hozzájárulás visszavonása",
    "Confirm": "Erősítse meg",
    "Your consent settings will be reset. Are you sure?":
        "A hozzájárulási beállítások visszaállnak. Biztos vagy benne?",
    "Yes": "Igen",
    "Cancel": "Mégse",
    "Session verified, redirecting securely...":
        "Munkamenet ellenőrizve, biztonságos átirányítás...",
    "Analysis complete ✅": "Elemzés kész ✅",
    "Purchases are not available right now. Please try again later.":
        "A vásárlások jelenleg nem elérhetők. Kérjük, próbálja újra később.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "A vásárlás befejeződött, de a Premium még nem aktív. Kérjük, próbálja újra.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Üdvözöljük a Premiumban! A hirdetések és a várakozási idő eltávolítva.",
    "Your Premium membership is active.": "Prémium tagságod aktív.",
    "Restore Purchases": "Vásárlások visszaállítása",
    "RESTORE": "VISSZAÁLLÍTÁS",
    "Restoring purchases...": "Vásárlások visszaállítása...",
    "Purchases restored ✅": "A vásárlások visszaállítva ✅",
    "No purchases to restore.": "Nincs visszaállítandó vásárlás.",
    "Restore failed: {err}": "A visszaállítás sikertelen: {err}",
    "Enter PIN": "Írja be a PIN-kódot",
    "PIN accepted, timer reset ✅": "PIN elfogadva, időzítő visszaállítása ✅",
    "Invalid PIN": "Érvénytelen PIN kód",
    "OK": "RENDBEN",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Az alkalmazás letöltésével és használatával úgy kell tekinteni, hogy minden Felhasználó előzetesen elolvasta, megértette és visszavonhatatlanul elfogadta az alábbi „Használati feltételek és felelősség kizárása” szöveget:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "1. cikk: Adatvédelem és helyi feldolgozási architektúra",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "A VERDICT egy „kliensoldali” szoftver. A Felhasználó bejelentkezési adatai (felhasználónév, jelszó, munkamenet-sütik) semmilyen körülmények között nem kerülnek továbbításra vagy tárolásra külső szerverre. Minden adatfeldolgozási tevékenység kizárólag a Felhasználó eszközének ideiglenes memóriájában (RAM) és helyi tárolójában történik. Az alkalmazás az Instagram felületen keresztül működő „böngésző-csomagolóként” működik.",
    "Article 2: Third-Party Platform Risks":
        "2. cikk: Harmadik felek platformkockázatai",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Az Instagram (Meta Platforms, Inc.) fenntartja a jogot arra, hogy platformszabályzata szerint korlátozza a harmadik féltől származó szoftverek használatát. Az alkalmazás használatából eredő minden kockázat, beleértve, de nem kizárólagosan a „műveletblokkokat”, „számlakorlátozásokat”, „árnyékos tilalmakat” vagy „számlalezárásokat”, kizárólag a Felhasználót terheli. A VERDICT fejlesztője nem vonható felelősségre az ilyen közigazgatási szankciókból eredő közvetlen vagy közvetett károkért.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "3. cikk: A jótállás kizárása és a felelősség korlátozása",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Ezt a szoftvert „AHOGY VAN” és „AHOGY ELÉRHETŐ” állapotban szállítjuk. A szoftver által biztosított elemzési eredmények 100%-os pontossága, folytonossága vagy eladhatósága nem garantált. A Felhasználó tudomásul veszi, hogy a pályázati adatokon alapuló jogi vagy kereskedelmi ügyletekből eredő bármely eredmény a saját felelőssége; valamint kijelenti és vállalja, hogy a fejlesztőt minden követeléstől, pertől és panasztól mentesíti.",
    "Article 4: Intellectual Property and Independence Notice":
        "4. cikk: Szellemi tulajdonra és függetlenségre vonatkozó közlemény",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "A VERDICT egy független fejlesztői projekt. Az „Instagram”, „Facebook” és „Meta” márkák a Meta Platforms, Inc. bejegyzett védjegyei. Ennek az alkalmazásnak nincs kereskedelmi partnersége, szponzori szerződése vagy hivatalos kapcsolata a fent említett cégekkel.",
    "Article 5: Service Continuity and Platform Changes":
        "5. cikk: A szolgáltatás folytonossága és a platform változásai",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Az Instagram API-n vagy a webes infrastruktúrán végrehajtott alapvető változtatások miatt az alkalmazás részben vagy teljesen elveszítheti a funkcionalitását. A fejlesztő nem vállal kötelezettséget az alkalmazás frissítésére vagy a szolgáltatás karbantartására válaszul az infrastrukturális változásokra, amelyek vis maiornak minősülnek.",
    "Analysis complete, results will be shown after the ad.":
        "Az elemzés kész, az eredmények a hirdetés után jelennek meg.",
    "Analysis failed": "Az elemzés sikertelen",
    "Reason: {reason}": "Ok: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tipp: A ki- és visszajelentkezés segíthet.",
    "Quick check: Counts are the same. No changes detected.":
        "Gyors ellenőrzés: A számok megegyeznek. Nem észleltünk változást.",
    "Daily Metrics": "Napi mutatók",
    "Active users": "Aktív felhasználók",
    "Daily queries": "Napi lekérdezések",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Az adatbetöltés megszakadt: a követő adatok hiányosak ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Az adatbetöltés megszakadt: a következő adatok hiányosak ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Az adatbetöltés megszakadt: az Instagram üres adatokat adott vissza.",
    "Data loading stopped due to an unexpected error.":
        "Az adatok betöltése váratlan hiba miatt leállt.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Az Instagram automatikus viselkedési figyelmeztetést adott vissza. A biztonság kedvéért leállítottuk az adatok lekérését.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Az Instagram biztonsági ellenőrzést kért. Ellenőrizze az Instagram alkalmazásban, és próbálja újra.",
    "Session is invalid or waiting for verification. Please log in again.":
        "A munkamenet érvénytelen, vagy ellenőrzésre vár. Kérjük, jelentkezzen be újra.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Túl sok kérést küldtek el. Az adatbetöltés a biztonság kedvéért megszakadt.",
    "Data loading could not complete due to a connection issue.":
        "Az adatok betöltése kapcsolati probléma miatt nem fejeződött be.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Az Instagram hibát adott vissza (HTTP {code}). Az adatbetöltés megszakadt.",
    "Instagram security verification is required (story data could not be fetched).":
        "Instagram biztonsági ellenőrzés szükséges (a történetadatokat nem sikerült lekérni).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "A történetadatokat nem sikerült lekérni. Ezt általában az Instagram-ellenőrzés, az ideiglenes API-korlátozások vagy a kapcsolat megszakadása okozza. Kérjük, próbálja újra 2-3 perc múlva.",
    "Could not fetch story data. Please try again shortly.":
        "Nem sikerült lekérni a történet adatait. Kérjük, próbálja újra rövidesen.",
    "Secret Mode": "Titkos mód",
    "Starting VERDICT...": "A VERDICT indítása...",
    "DID YOU KNOW?": "TUDTA?",
    "Estimated time left: {time}": "Becsült hátralévő idő: {time}",
    "Estimating remaining time...": "A hátralévő idő becslése...",
    "LOG OUT": "KIJELENTKEZÉS",
    "Open Profile": "Nyissa meg a Profilt",
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
    "Analysis Time!": "分析时间！",
    "CLOSE": "关闭",
    "SYSTEM UNDER MAINTENANCE": "系统维护中",
    "Bio Planner": "生物规划师",
    "Store link not set.": "未设置商店链接。",
    "Invalid store link.": "商店链接无效。",
    "Could not open the link.": "无法打开链接。",
    "Please try again.": "请再试一次。",
    "Show error": "显示错误",
    "Exception": "例外",
    "Load error": "负载错误",
    "Code": "代码",
    "Timeout": "暂停",
    "REST probe failed: missing auth.": "REST 探测失败：缺少身份验证。",
    "REST probe success (Firestore endpoint reachable).":
        "REST 探测成功（Firestore 端点可访问）。",
    "REST probe failed (check logs).": "REST 探测失败（检查日志）。",
    "Firebase Auth probe failed.": "Firebase 身份验证探测失败。",
    "Firebase Auth probe success.": "Firebase 身份验证探测成功。",
    "Firebase token probe failed.": "Firebase 令牌探测失败。",
    "CRITICAL DIAGNOSTIC ERROR": "严重诊断错误",
    "COPY": "复制",
    "OPEN LOGS": "打开日志",
    "Firebase": "火力基地",
    "Store": "店铺",
    "Copy all": "全部复制",
    "Close": "关闭",
    "Auth Probe": "验证探针",
    "Write Test": "编写测试",
    "REST Probe": "休息探针",
    "Restore Test": "恢复测试",
    "Firebase auth error: user verification failed.": "Firebase 身份验证错误：用户验证失败。",
    "Firestore test write successful.": "Firestore 测试写入成功。",
    "Firestore test failed.": "Firestore 测试失败。",
    "Firestore auth error: user verification failed.":
        "Firestore 身份验证错误：用户验证失败。",
    "Firestore counter write failed.": "Firestore 计数器写入失败。",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore 身份验证丢失：ig_users 写入被阻止。",
    "Firestore ig_users write failed.": "Firestore ig_users 写入失败。",
    "User": "用户",
    "Opening consent form...": "打开同意书...",
    "Your consent preference was updated.": "您的同意偏好已更新。",
    "Consent update failed. Please try again.": "同意更新失败。请再试一次。",
    "Your account is blocked": "您的帐户已被封锁",
    "Access is restricted for this account.": "此帐户的访问受到限制。",
    "Starting purchase...": "开始购买...",
    "Purchase cancelled.": "购买已取消。",
    "Premium active ✅ Ads and wait times are disabled.": "高级活动 ✅ 广告和等待时间被禁用。",
    "Purchase failed. Please try again.": "购买失败。请再试一次。",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "需要会话验证。请在 Instagram 应用中验证您的帐户，然后重试。",
    "Instagram returned no data.": "Instagram 没有返回任何数据。",
    "Session verification failed. Please log in again.": "会话验证失败。请重新登录。",
    "Open Instagram": "打开 Instagram",
    "Instagram message": "Instagram 消息",
    "Loading stories...": "正在加载故事...",
    "No data": "无数据",
    "NEW": "新的",
    "Login": "登录",
    "Session verified, redirecting...": "会话已验证，正在重定向...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "广告空间",
    "Admin mode active": "管理模式已激活",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "我们每天都在不断发展，为您提供更好的体验。您的反馈对我们很有价值——我们很乐意听取您的意见！",
    "Please log in to start the analysis.": "请登录以开始分析。",
    "Welcome, {username}": "欢迎，{username}",
    "REFRESH DATA": "刷新数据",
    "LOG IN WITH INSTAGRAM": "使用 Instagram 登录",
    "Analyzing data...\nThis might take a moment.": "正在分析数据...\n这可能需要一些时间。",
    "Processing data...\nAlmost done.": "处理数据...\n快完成了。",
    "Loading ad...\nPlease wait.": "正在加载广告...\n请稍候。",
    "Google ad warning: {reason}": "Google 广告警告：{reason}",
    "All analysis is securely processed locally on your device.":
        "所有分析均在您的设备上进行本地安全处理。",
    "Total analyses today: {count}": "今日总分析：{count}",
    "Next analysis": "接下来分析",
    "Ready to scan.": "准备扫描。",
    "Analysis available now": "现已提供分析",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "分析现已可用，但连续运行分析可能会使您的帐户面临风险。",
    "Please wait": "请稍等",
    "Warning": "警告",
    "Next analysis: {time}": "接下来分析：{time}",
    "WATCH AD AND START ANALYSIS": "观看广告并开始分析",
    "START ANALYSIS": "开始分析",
    "Start analysis?": "开始分析？",
    "Reset App Data": "重置应用程序数据",
    "This will wipe all local data and session cookies. Are you sure?":
        "这将擦除所有本地数据和会话 cookie。你确定吗？",
    "CANCEL": "取消",
    "DELETE": "删除",
    "Error": "错误",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "数据检索失败：{err}\n\n故障排除：尝试注销并重新登录。",
    "Followers": "追随者",
    "Following": "下列的",
    "New Followers": "新关注者",
    "Not Following Back": "不跟进",
    "Lost Followers": "失去的追随者",
    "Legal Disclaimer": "法律免责声明",
    "Unfollowed Users": "取消关注的用户",
    "Rate Us": "评价我们",
    "Contact Us": "联系我们",
    "Remove Ads & Wait Times": "删除广告和等待时间",
    "This box is currently under test.": "该盒子目前正在测试中。",
    "Watch Stories Secretly or Zoom Profile Photos": "秘密观看故事或缩放个人资料照片",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "请登录后偷偷观看故事并放大头像。",
    "Will be shown after the ad, please wait.": "将会在广告后显示，请稍候。",
    "What would you like to do?": "你想做什么？",
    "Enlarge profile photo": "放大个人资料照片",
    "Watch story secretly": "偷偷看故事",
    "No story data available.": "没有可用的故事数据。",
    "I HAVE READ AND AGREE": "我已阅读并同意",
    "Withdraw Consent": "撤回同意",
    "Confirm": "确认",
    "Your consent settings will be reset. Are you sure?": "您的同意设置将被重置。你确定吗？",
    "Yes": "是的",
    "Cancel": "取消",
    "Session verified, redirecting securely...": "会话已验证，安全重定向...",
    "Analysis complete ✅": "分析完成✅",
    "Purchases are not available right now. Please try again later.":
        "目前无法购买。请稍后重试。",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "购买已完成，但高级版尚未激活。请再试一次。",
    "Welcome to Premium! Ads and wait times are removed.":
        "欢迎来到高级版！广告和等待时间被删除。",
    "Your Premium membership is active.": "您的高级会员资格已激活。",
    "Restore Purchases": "恢复购买",
    "RESTORE": "恢复",
    "Restoring purchases...": "正在恢复购买...",
    "Purchases restored ✅": "已恢复购买 ✅",
    "No purchases to restore.": "没有要恢复的购买。",
    "Restore failed: {err}": "恢复失败：{err}",
    "Enter PIN": "输入密码",
    "PIN accepted, timer reset ✅": "PIN 码已接受，计时器重置 ✅",
    "Invalid PIN": "PIN 码无效",
    "OK": "好的",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "通过下载和使用本应用程序，每个用户均被视为已提前阅读、理解并不可撤销地接受以下“使用条款和免责声明”文本：",
    "Article 1: Data Privacy and Local Processing Architecture":
        "第 1 条：数据隐私和本地处理架构",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT 是“客户端”软件。用户的登录凭据（用户名、密码、会话 cookie）在任何情况下都不会传输到或存储在外部服务器上。所有数据处理活动仅发生在用户设备的临时内存 (RAM) 和本地存储中。该应用程序充当通过 Instagram 界面运行的“浏览器包装器”。",
    "Article 2: Third-Party Platform Risks": "第二条：第三方平台风险",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) 保留根据其平台政策限制使用第三方软件的权利。所有风险，包括但不限于因使用该应用程序而可能产生的“行动阻止”、“帐户限制”、“影子禁令”或“帐户关闭”，均完全由用户承担。 VERDICT 开发商不对此类行政制裁造成的任何直接或间接损害承担责任。",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "第三条：免责声明和责任限制",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "该软件按“原样”和“可用”形式提供。不保证软件提供的分析结果的 100% 准确性、连续性或适销性。用户承认基于应用数据进行的法律或商业交易所产生的任何结果均由其自行承担；并声明并承诺使开发商免受所有索赔、诉讼和投诉的损害。",
    "Article 4: Intellectual Property and Independence Notice":
        "第四条：知识产权和独立性声明",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT 是一个独立开发者项目。 “Instagram”、“Facebook”和“Meta”品牌是 Meta Platforms, Inc. 的注册商标。此应用程序与上述公司没有商业合作伙伴关系、赞助协议或官方从属关系。",
    "Article 5: Service Continuity and Platform Changes": "第五条：服务连续性和平台变更",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Instagram API 或 Web 基础设施的根本性更改可能会导致应用程序部分或完全失去其功能。开发人员不承诺更新应用程序或维护服务以应对此类基础设施变更，这被视为“不可抗力”。",
    "Analysis complete, results will be shown after the ad.": "分析完成，结果将在广告后显示。",
    "Analysis failed": "分析失败",
    "Reason: {reason}": "原因：{reason}",
    "Tip: Logging out and logging back in may help.": "提示：注销并重新登录可能会有所帮助。",
    "Quick check: Counts are the same. No changes detected.":
        "快速检查：计数是相同的。未检测到任何变化。",
    "Daily Metrics": "每日指标",
    "Active users": "活跃用户",
    "Daily queries": "每日查询",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "数据加载被中断：跟随者数据不完整（{fetched}/{total}）。",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "数据加载被中断：以下数据不完整（{fetched}/{total}）。",
    "Data loading was interrupted: Instagram returned empty data.":
        "数据加载中断：Instagram 返回空数据。",
    "Data loading stopped due to an unexpected error.": "由于意外错误，数据加载停止。",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram 返回了自动行为警告。为了安全起见，我们停止获取数据。",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram 请求安全验证。在 Instagram 应用程序中验证并重试。",
    "Session is invalid or waiting for verification. Please log in again.":
        "会话无效或正在等待验证。请重新登录。",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "发送的请求过多。为了安全起见，数据加载被中断。",
    "Data loading could not complete due to a connection issue.":
        "由于连接问题，数据加载无法完成。",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram 返回错误 (HTTP {code})。数据加载被中断。",
    "Instagram security verification is required (story data could not be fetched).":
        "需要Instagram安全验证（无法获取故事数据）。",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "无法获取故事数据。通常这是由 Instagram 验证、临时 API 限制或连接中断引起的。请在 2-3 分钟后重试。",
    "Could not fetch story data. Please try again shortly.": "无法获取故事数据。请稍后重试。",
    "Secret Mode": "秘密模式",
    "Starting VERDICT...": "开始判决...",
    "DID YOU KNOW?": "你可知道？",
    "Estimated time left: {time}": "预计剩余时间：{time}",
    "Estimating remaining time...": "估计剩余时间...",
    "LOG OUT": "退出",
    "Open Profile": "公开资料",
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
    "Analysis Time!": "Waktu Analisis!",
    "CLOSE": "MENUTUP",
    "SYSTEM UNDER MAINTENANCE": "SISTEM DALAM PEMELIHARAAN",
    "Bio Planner": "Perencana Bio",
    "Store link not set.": "Tautan toko tidak disetel.",
    "Invalid store link.": "Tautan toko tidak valid.",
    "Could not open the link.": "Tidak dapat membuka tautan.",
    "Please try again.": "Silakan coba lagi.",
    "Show error": "Tampilkan kesalahan",
    "Exception": "Pengecualian",
    "Load error": "Kesalahan pemuatan",
    "Code": "Kode",
    "Timeout": "Batas waktu",
    "REST probe failed: missing auth.":
        "Pemeriksaan REST gagal: autentikasi tidak ada.",
    "REST probe success (Firestore endpoint reachable).":
        "Pemeriksaan REST berhasil (titik akhir Firestore dapat dijangkau).",
    "REST probe failed (check logs).": "Pemeriksaan REST gagal (periksa log).",
    "Firebase Auth probe failed.": "Pemeriksaan Firebase Auth gagal.",
    "Firebase Auth probe success.": "Pemeriksaan Firebase Auth berhasil.",
    "Firebase token probe failed.": "Pemeriksaan token Firebase gagal.",
    "CRITICAL DIAGNOSTIC ERROR": "KESALAHAN DIAGNOSTIK KRITIS",
    "COPY": "MENYALIN",
    "OPEN LOGS": "BUKA LOG",
    "Firebase": "basis api",
    "Store": "Toko",
    "Copy all": "Salin semua",
    "Close": "Menutup",
    "Auth Probe": "Penyelidikan Otentikasi",
    "Write Test": "Tes Tulis",
    "REST Probe": "Pemeriksaan SISA",
    "Restore Test": "Tes Pemulihan",
    "Firebase auth error: user verification failed.":
        "Kesalahan autentikasi Firebase: verifikasi pengguna gagal.",
    "Firestore test write successful.": "Tes penulisan Firestore berhasil.",
    "Firestore test failed.": "Tes Firestore gagal.",
    "Firestore auth error: user verification failed.":
        "Kesalahan autentikasi Firestore: verifikasi pengguna gagal.",
    "Firestore counter write failed.": "Penulisan penghitung Firestore gagal.",
    "Firestore auth missing: ig_users write blocked.":
        "Otentikasi Firestore hilang: penulisan ig_users diblokir.",
    "Firestore ig_users write failed.": "Penulisan ig_users Firestore gagal.",
    "User": "Pengguna",
    "Opening consent form...": "Formulir persetujuan pembukaan...",
    "Your consent preference was updated.":
        "Preferensi persetujuan Anda telah diperbarui.",
    "Consent update failed. Please try again.":
        "Pembaruan izin gagal. Silakan coba lagi.",
    "Your account is blocked": "Akun Anda diblokir",
    "Access is restricted for this account.": "Akses dibatasi untuk akun ini.",
    "Starting purchase...": "Memulai pembelian...",
    "Purchase cancelled.": "Pembelian dibatalkan.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktif ✅ Iklan dan waktu tunggu dinonaktifkan.",
    "Purchase failed. Please try again.": "Pembelian gagal. Silakan coba lagi.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Verifikasi sesi diperlukan. Harap verifikasi akun Anda di aplikasi Instagram dan coba lagi.",
    "Instagram returned no data.": "Instagram tidak mengembalikan data.",
    "Session verification failed. Please log in again.":
        "Verifikasi sesi gagal. Silakan masuk lagi.",
    "Open Instagram": "Buka Instagram",
    "Instagram message": "pesan Instagram",
    "Loading stories...": "Memuat cerita...",
    "No data": "Tidak ada data",
    "NEW": "BARU",
    "Login": "Login",
    "Session verified, redirecting...": "Sesi diverifikasi, mengalihkan...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "RUANG IKLAN",
    "Admin mode active": "Mode admin aktif",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Kami berkembang setiap hari untuk memberi Anda pengalaman yang lebih baik. Masukan Anda sangat berharga bagi kami—kami ingin mendengar pendapat Anda!",
    "Please log in to start the analysis.":
        "Silakan masuk untuk memulai analisis.",
    "Welcome, {username}": "Selamat datang, {username}",
    "REFRESH DATA": "SEGARKAN DATA",
    "LOG IN WITH INSTAGRAM": "MASUK DENGAN INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Menganalisis data...\nIni mungkin memerlukan waktu beberapa saat.",
    "Processing data...\nAlmost done.": "Memproses data...\nHampir selesai.",
    "Loading ad...\nPlease wait.": "Memuat iklan...\nHarap tunggu.",
    "Google ad warning: {reason}": "Peringatan iklan Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Semua analisis diproses dengan aman secara lokal di perangkat Anda.",
    "Total analyses today: {count}": "Total analisis hari ini: {count}",
    "Next analysis": "Analisis selanjutnya",
    "Ready to scan.": "Siap untuk memindai.",
    "Analysis available now": "Analisis tersedia sekarang",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analisis sudah tersedia sekarang, namun menjalankan analisis secara berulang-ulang dapat membahayakan akun Anda.",
    "Please wait": "Harap tunggu",
    "Warning": "Peringatan",
    "Next analysis: {time}": "Analisis selanjutnya: {time}",
    "WATCH AD AND START ANALYSIS": "PERHATIKAN IKLAN DAN MULAI ANALISIS",
    "START ANALYSIS": "MULAI ANALISIS",
    "Start analysis?": "Mulai analisis?",
    "Reset App Data": "Setel Ulang Data Aplikasi",
    "This will wipe all local data and session cookies. Are you sure?":
        "Ini akan menghapus semua data lokal dan cookie sesi. Apa kamu yakin?",
    "CANCEL": "MEMBATALKAN",
    "DELETE": "MENGHAPUS",
    "Error": "Kesalahan",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Pengambilan data gagal: {err}\n\nPemecahan Masalah: Coba keluar dan masuk kembali.",
    "Followers": "Pengikut",
    "Following": "Mengikuti",
    "New Followers": "Pengikut Baru",
    "Not Following Back": "Tidak Mengikuti Kembali",
    "Lost Followers": "Pengikut yang Hilang",
    "Legal Disclaimer": "Penafian Hukum",
    "Unfollowed Users": "Pengguna yang Berhenti Mengikuti",
    "Rate Us": "Nilai Kami",
    "Contact Us": "Hubungi kami",
    "Remove Ads & Wait Times": "Hapus Iklan & Waktu Tunggu",
    "This box is currently under test.": "Kotak ini sedang diuji.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Tonton Cerita Secara Diam-diam atau Zoom Foto Profil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Silakan masuk untuk menonton cerita secara diam-diam dan memperbesar foto profil.",
    "Will be shown after the ad, please wait.":
        "Akan ditampilkan setelah iklan, harap tunggu.",
    "What would you like to do?": "Apa yang ingin kamu lakukan?",
    "Enlarge profile photo": "Perbesar foto profil",
    "Watch story secretly": "Tonton cerita secara diam-diam",
    "No story data available.": "Tidak ada data cerita yang tersedia.",
    "I HAVE READ AND AGREE": "SAYA TELAH BACA DAN SETUJU",
    "Withdraw Consent": "Tarik Persetujuan",
    "Confirm": "Mengonfirmasi",
    "Your consent settings will be reset. Are you sure?":
        "Pengaturan persetujuan Anda akan diatur ulang. Apa kamu yakin?",
    "Yes": "Ya",
    "Cancel": "Membatalkan",
    "Session verified, redirecting securely...":
        "Sesi diverifikasi, dialihkan dengan aman...",
    "Analysis complete ✅": "Analisis selesai ✅",
    "Purchases are not available right now. Please try again later.":
        "Pembelian tidak tersedia saat ini. Silakan coba lagi nanti.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Pembelian selesai, namun Premium belum aktif. Silakan coba lagi.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Selamat datang di Premium! Iklan dan waktu tunggu dihapus.",
    "Your Premium membership is active.": "Keanggotaan Premium Anda aktif.",
    "Restore Purchases": "Pulihkan Pembelian",
    "RESTORE": "MEMULIHKAN",
    "Restoring purchases...": "Memulihkan pembelian...",
    "Purchases restored ✅": "Pembelian dipulihkan ✅",
    "No purchases to restore.": "Tidak ada pembelian yang perlu dipulihkan.",
    "Restore failed: {err}": "Pemulihan gagal: {err}",
    "Enter PIN": "Masukkan PIN",
    "PIN accepted, timer reset ✅":
        "PIN diterima, pengatur waktu disetel ulang ✅",
    "Invalid PIN": "PIN tidak valid",
    "OK": "OKE",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Dengan mengunduh dan menggunakan aplikasi ini, setiap Pengguna dianggap telah membaca, memahami, dan menerima secara tidak dapat ditarik kembali teks \"Ketentuan Penggunaan dan Penafian\" di bawah ini terlebih dahulu:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Pasal 1: Privasi Data dan Arsitektur Pemrosesan Lokal",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT adalah perangkat lunak 'sisi klien'. Kredensial login Pengguna (nama pengguna, kata sandi, cookie sesi) dalam keadaan apa pun tidak dikirimkan ke atau disimpan di server eksternal. Semua aktivitas pemrosesan data terjadi secara eksklusif dalam memori sementara (RAM) dan penyimpanan lokal perangkat Pengguna. Aplikasi ini berfungsi sebagai 'browser-wrapper' yang beroperasi melalui antarmuka Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Pasal 2: Risiko Platform Pihak Ketiga",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) berhak membatasi penggunaan perangkat lunak pihak ketiga sesuai kebijakan platformnya. Segala risiko, termasuk namun tidak terbatas pada 'pemblokiran tindakan', 'pembatasan akun', 'shadowbans', atau 'penutupan akun' yang mungkin timbul akibat penggunaan aplikasi, sepenuhnya menjadi milik Pengguna. Pengembang VERDICT tidak bertanggung jawab atas segala kerugian langsung atau tidak langsung yang diakibatkan oleh sanksi administratif tersebut.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Pasal 3: Penafian Garansi dan Batasan Tanggung Jawab",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Perangkat lunak ini disediakan 'APA ADANYA' dan 'SEBAGAIMANA TERSEDIA'. Akurasi 100%, kontinuitas, atau kelayakan hasil analisis yang disediakan oleh perangkat lunak tidak dijamin. Pengguna mengakui bahwa segala akibat yang timbul dari transaksi legal atau komersial berdasarkan data aplikasi adalah tanggung jawabnya sendiri; dan menyatakan serta berjanji untuk membebaskan pengembang dari segala klaim, tuntutan hukum, dan keluhan.",
    "Article 4: Intellectual Property and Independence Notice":
        "Pasal 4: Pemberitahuan Kekayaan Intelektual dan Kemerdekaan",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT adalah proyek pengembang independen. Merek 'Instagram', 'Facebook', dan 'Meta' adalah merek dagang terdaftar dari Meta Platforms, Inc. Aplikasi ini tidak memiliki kemitraan komersial, perjanjian sponsorship, atau afiliasi resmi dengan perusahaan-perusahaan tersebut di atas.",
    "Article 5: Service Continuity and Platform Changes":
        "Pasal 5: Keberlangsungan Layanan dan Perubahan Platform",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Perubahan mendasar pada API Instagram atau infrastruktur web dapat menyebabkan aplikasi kehilangan fungsinya sebagian atau seluruhnya. Pengembang tidak berkomitmen untuk memperbarui aplikasi atau memelihara layanan sebagai respons terhadap perubahan infrastruktur tersebut, yang dianggap sebagai \"keadaan kahar\".",
    "Analysis complete, results will be shown after the ad.":
        "Analisis selesai, hasilnya akan ditampilkan setelah iklan.",
    "Analysis failed": "Analisis gagal",
    "Reason: {reason}": "Alasan: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tip: Keluar dan masuk kembali mungkin membantu.",
    "Quick check: Counts are the same. No changes detected.":
        "Pemeriksaan cepat: Jumlahnya sama. Tidak ada perubahan yang terdeteksi.",
    "Daily Metrics": "Metrik Harian",
    "Active users": "Pengguna aktif",
    "Daily queries": "Pertanyaan harian",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Pemuatan data terhenti: data pengikut tidak lengkap ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Pemuatan data terhenti: data berikut tidak lengkap ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Pemuatan data terhenti: Instagram mengembalikan data kosong.",
    "Data loading stopped due to an unexpected error.":
        "Pemuatan data terhenti karena kesalahan yang tidak terduga.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram mengembalikan peringatan perilaku otomatis. Kami berhenti mengambil data demi keamanan.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram meminta verifikasi keamanan. Verifikasi di aplikasi Instagram dan coba lagi.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sesi tidak valid atau menunggu verifikasi. Silakan masuk lagi.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Terlalu banyak permintaan yang dikirim. Pemuatan data dihentikan demi keamanan.",
    "Data loading could not complete due to a connection issue.":
        "Pemuatan data tidak dapat diselesaikan karena masalah koneksi.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram mengembalikan kesalahan (HTTP {code}). Pemuatan data terhenti.",
    "Instagram security verification is required (story data could not be fetched).":
        "Verifikasi keamanan Instagram diperlukan (data cerita tidak dapat diambil).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Data cerita tidak dapat diambil. Biasanya hal ini disebabkan oleh verifikasi Instagram, pembatasan API sementara, atau gangguan koneksi. Silakan coba lagi dalam 2-3 menit.",
    "Could not fetch story data. Please try again shortly.":
        "Tidak dapat mengambil data cerita. Silakan coba lagi sebentar lagi.",
    "Secret Mode": "Modus Rahasia",
    "Starting VERDICT...": "Memulai PUTUSAN...",
    "DID YOU KNOW?": "TAHUKAH ANDA?",
    "Estimated time left: {time}": "Perkiraan waktu tersisa: {time}",
    "Estimating remaining time...": "Memperkirakan sisa waktu...",
    "LOG OUT": "KELUAR",
    "Open Profile": "Buka Profil",
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
    "Analysis Time!": "Analyse tijd!",
    "CLOSE": "DICHTBIJ",
    "SYSTEM UNDER MAINTENANCE": "SYSTEEM ONDER ONDERHOUD",
    "Bio Planner": "Bioplanner",
    "Store link not set.": "Winkellink niet ingesteld.",
    "Invalid store link.": "Ongeldige winkellink.",
    "Could not open the link.": "Kon de link niet openen.",
    "Please try again.": "Probeer het opnieuw.",
    "Show error": "Toon fout",
    "Exception": "Uitzondering",
    "Load error": "Fout bij laden",
    "Code": "Code",
    "Timeout": "Time-out",
    "REST probe failed: missing auth.":
        "REST-test mislukt: verificatie ontbreekt.",
    "REST probe success (Firestore endpoint reachable).":
        "REST-test geslaagd (Firestore-eindpunt bereikbaar).",
    "REST probe failed (check logs).":
        "REST-test mislukt (controleer logboeken).",
    "Firebase Auth probe failed.": "Firebase-verificatietest mislukt.",
    "Firebase Auth probe success.": "Firebase-authenticatie geslaagd.",
    "Firebase token probe failed.": "Firebase-tokenonderzoek mislukt.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITIEKE DIAGNOSTISCHE FOUT",
    "COPY": "KOPIËREN",
    "OPEN LOGS": "OPEN LOGBOEKJES",
    "Firebase": "Vuurbasis",
    "Store": "Winkel",
    "Copy all": "Kopieer alles",
    "Close": "Dichtbij",
    "Auth Probe": "Verificatietest",
    "Write Test": "Schrijf proef",
    "REST Probe": "REST-sonde",
    "Restore Test": "Test herstellen",
    "Firebase auth error: user verification failed.":
        "Firebase-authenticatiefout: gebruikersverificatie mislukt.",
    "Firestore test write successful.": "Firestore-test schrijven succesvol.",
    "Firestore test failed.": "Firestore-test mislukt.",
    "Firestore auth error: user verification failed.":
        "Firestore-authenticatiefout: gebruikersverificatie mislukt.",
    "Firestore counter write failed.": "Firestore-teller schrijven mislukt.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore-authenticatie ontbreekt: ig_users schrijven geblokkeerd.",
    "Firestore ig_users write failed.": "Firestore ig_users schrijven mislukt.",
    "User": "Gebruiker",
    "Opening consent form...": "Toestemmingsformulier openen...",
    "Your consent preference was updated.":
        "Uw toestemmingsvoorkeur is bijgewerkt.",
    "Consent update failed. Please try again.":
        "Updaten van toestemming is mislukt. Probeer het opnieuw.",
    "Your account is blocked": "Uw account is geblokkeerd",
    "Access is restricted for this account.":
        "De toegang is beperkt voor dit account.",
    "Starting purchase...": "Aankoop starten...",
    "Purchase cancelled.": "Aankoop geannuleerd.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium actief ✅ Advertenties en wachttijden zijn uitgeschakeld.",
    "Purchase failed. Please try again.":
        "Aankoop mislukt. Probeer het opnieuw.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Sessieverificatie is vereist. Verifieer je account in de Instagram-app en probeer het opnieuw.",
    "Instagram returned no data.":
        "Instagram heeft geen gegevens geretourneerd.",
    "Session verification failed. Please log in again.":
        "Sessieverificatie mislukt. Log opnieuw in.",
    "Open Instagram": "Instagram openen",
    "Instagram message": "Instagram-bericht",
    "Loading stories...": "Verhalen laden...",
    "No data": "Geen gegevens",
    "NEW": "NIEUW",
    "Login": "Login",
    "Session verified, redirecting...": "Sessie geverifieerd, omleiding...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ADVERTENTIERUIMTE",
    "Admin mode active": "Beheermodus actief",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "We evolueren elke dag om u een betere ervaring te bieden. Uw feedback is waardevol voor ons; we horen graag van u!",
    "Please log in to start the analysis.": "Log in om de analyse te starten.",
    "Welcome, {username}": "Welkom, {username}",
    "REFRESH DATA": "VERNIEUW GEGEVENS",
    "LOG IN WITH INSTAGRAM": "INLOGGEN MET INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Gegevens analyseren...\nDit kan even duren.",
    "Processing data...\nAlmost done.": "Gegevens verwerken...\nBijna klaar.",
    "Loading ad...\nPlease wait.": "Advertentie laden...\nWacht alstublieft.",
    "Google ad warning: {reason}": "Google-advertentiewaarschuwing: {reason}",
    "All analysis is securely processed locally on your device.":
        "Alle analyses worden veilig lokaal op uw apparaat verwerkt.",
    "Total analyses today: {count}": "Totaal aantal analyses vandaag: {count}",
    "Next analysis": "Volgende analyse",
    "Ready to scan.": "Klaar om te scannen.",
    "Analysis available now": "Analyse nu beschikbaar",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analyses zijn nu beschikbaar, maar het achter elkaar uitvoeren van analyses kan uw account in gevaar brengen.",
    "Please wait": "Wacht alstublieft",
    "Warning": "Waarschuwing",
    "Next analysis: {time}": "Volgende analyse: {time}",
    "WATCH AD AND START ANALYSIS": "BEKIJK DE ADVERTENTIE EN START DE ANALYSE",
    "START ANALYSIS": "BEGIN ANALYSE",
    "Start analysis?": "Analyse starten?",
    "Reset App Data": "App-gegevens opnieuw instellen",
    "This will wipe all local data and session cookies. Are you sure?":
        "Hiermee worden alle lokale gegevens en sessiecookies gewist. Weet je het zeker?",
    "CANCEL": "ANNULEREN",
    "DELETE": "VERWIJDEREN",
    "Error": "Fout",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Ophalen van gegevens mislukt: {err}\n\nProblemen oplossen: Probeer uit te loggen en weer in te loggen.",
    "Followers": "Volgers",
    "Following": "Volgende",
    "New Followers": "Nieuwe volgers",
    "Not Following Back": "Volgt niet terug",
    "Lost Followers": "Verloren volgers",
    "Legal Disclaimer": "Juridische disclaimer",
    "Unfollowed Users": "Niet-gevolgde gebruikers",
    "Rate Us": "Beoordeel ons",
    "Contact Us": "Neem contact met ons op",
    "Remove Ads & Wait Times": "Verwijder advertenties en wachttijden",
    "This box is currently under test.": "Deze box wordt momenteel getest.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Bekijk verhalen in het geheim of zoom in op profielfoto's",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Log in om verhalen in het geheim te bekijken en profielfoto's te vergroten.",
    "Will be shown after the ad, please wait.":
        "Wordt na de advertentie getoond, even geduld a.u.b.",
    "What would you like to do?": "Wat zou je graag willen doen?",
    "Enlarge profile photo": "Vergroot profielfoto",
    "Watch story secretly": "Bekijk het verhaal in het geheim",
    "No story data available.": "Er zijn geen verhaalgegevens beschikbaar.",
    "I HAVE READ AND AGREE": "IK HEB GELEZEN EN GA AKKOORD",
    "Withdraw Consent": "Toestemming intrekken",
    "Confirm": "Bevestigen",
    "Your consent settings will be reset. Are you sure?":
        "Uw toestemmingsinstellingen worden opnieuw ingesteld. Weet je het zeker?",
    "Yes": "Ja",
    "Cancel": "Annuleren",
    "Session verified, redirecting securely...":
        "Sessie geverifieerd, veilig omleiden...",
    "Analysis complete ✅": "Analyse voltooid ✅",
    "Purchases are not available right now. Please try again later.":
        "Aankopen zijn momenteel niet beschikbaar. Probeer het later opnieuw.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Aankoop voltooid, maar Premium is nog niet actief. Probeer het opnieuw.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Welkom bij Premium! Advertenties en wachttijden zijn verwijderd.",
    "Your Premium membership is active.": "Je Premium-lidmaatschap is actief.",
    "Restore Purchases": "Aankopen herstellen",
    "RESTORE": "HERSTELLEN",
    "Restoring purchases...": "Aankopen herstellen...",
    "Purchases restored ✅": "Aankopen hersteld ✅",
    "No purchases to restore.": "Geen aankopen om te herstellen.",
    "Restore failed: {err}": "Herstellen mislukt: {err}",
    "Enter PIN": "Voer pincode in",
    "PIN accepted, timer reset ✅": "PIN geaccepteerd, timer gereset ✅",
    "Invalid PIN": "Ongeldige pincode",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Door deze applicatie te downloaden en te gebruiken, wordt elke Gebruiker geacht de onderstaande tekst \"Gebruiksvoorwaarden en Disclaimer\" vooraf te hebben gelezen, begrepen en onherroepelijk aanvaard:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artikel 1: Gegevensprivacy en lokale verwerkingsarchitectuur",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT is 'client-side'-software. De inloggegevens van de Gebruiker (gebruikersnaam, wachtwoord, sessiecookies) worden in geen geval verzonden naar of opgeslagen op een externe server. Alle gegevensverwerkingsactiviteiten vinden uitsluitend plaats binnen het tijdelijke geheugen (RAM) en de lokale opslag van het apparaat van de gebruiker. De applicatie functioneert als een 'browser-wrapper' die via de Instagram-interface werkt.",
    "Article 2: Third-Party Platform Risks":
        "Artikel 2: Risico's van platforms van derden",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) behoudt zich het recht voor om het gebruik van software van derden te beperken volgens haar platformbeleid. Alle risico's, inclusief maar niet beperkt tot 'actieblokkeringen', 'accountbeperkingen', 'shadowbans' of 'accountsluitingen' die kunnen voortvloeien uit het gebruik van de applicatie, behoren uitsluitend toe aan de Gebruiker. De VERDICT-ontwikkelaar kan niet aansprakelijk worden gesteld voor enige directe of indirecte schade die voortvloeit uit dergelijke administratieve sancties.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artikel 3: Garantiedisclaimer en beperking van aansprakelijkheid",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Deze software wordt 'AS-IS' en 'ZOALS BESCHIKBAAR' geleverd. De 100% nauwkeurigheid, continuïteit of verkoopbaarheid van de analyseresultaten die door de software worden geleverd, wordt niet gegarandeerd. De Gebruiker erkent dat eventuele resultaten voortvloeiend uit juridische of commerciële transacties op basis van sollicitatiegegevens zijn eigen verantwoordelijkheid zijn; en verklaart en verbindt zich ertoe de ontwikkelaar te vrijwaren van alle claims, rechtszaken en klachten.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artikel 4: Intellectuele eigendom en onafhankelijkheidsverklaring",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT is een onafhankelijk ontwikkelaarsproject. De merken 'Instagram', 'Facebook' en 'Meta' zijn geregistreerde handelsmerken van Meta Platforms, Inc. Deze applicatie heeft geen commercieel partnerschap, sponsorovereenkomst of officiële band met de bovengenoemde bedrijven.",
    "Article 5: Service Continuity and Platform Changes":
        "Artikel 5: Continuïteit van de dienstverlening en platformwijzigingen",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Fundamentele wijzigingen aan de Instagram API of webinfrastructuur kunnen ervoor zorgen dat de applicatie zijn functionaliteit geheel of gedeeltelijk verliest. De ontwikkelaar doet geen enkele toezegging om de applicatie bij te werken of de service te onderhouden als reactie op dergelijke infrastructurele veranderingen, die als \"overmacht\" worden beschouwd.",
    "Analysis complete, results will be shown after the ad.":
        "Analyse voltooid, resultaten worden na de advertentie weergegeven.",
    "Analysis failed": "Analyse mislukt",
    "Reason: {reason}": "Reden: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tip: Uitloggen en opnieuw inloggen kan helpen.",
    "Quick check: Counts are the same. No changes detected.":
        "Snelle controle: tellingen zijn hetzelfde. Geen wijzigingen gedetecteerd.",
    "Daily Metrics": "Dagelijkse statistieken",
    "Active users": "Actieve gebruikers",
    "Daily queries": "Dagelijkse vragen",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Het laden van gegevens is onderbroken: gegevens van volgers zijn onvolledig ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Het laden van gegevens is onderbroken: de volgende gegevens zijn onvolledig ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Het laden van gegevens werd onderbroken: Instagram retourneerde lege gegevens.",
    "Data loading stopped due to an unexpected error.":
        "Het laden van gegevens is gestopt vanwege een onverwachte fout.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram heeft een automatische gedragswaarschuwing geretourneerd. Uit veiligheidsoverwegingen zijn we gestopt met het ophalen van gegevens.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram heeft om beveiligingsverificatie gevraagd. Verifieer in de Instagram-app en probeer het opnieuw.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sessie is ongeldig of wacht op verificatie. Log opnieuw in.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Er zijn te veel verzoeken verzonden. Het laden van gegevens is om veiligheidsredenen onderbroken.",
    "Data loading could not complete due to a connection issue.":
        "Het laden van gegevens kon niet worden voltooid vanwege een verbindingsprobleem.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram heeft een fout geretourneerd (HTTP {code}). Het laden van gegevens is onderbroken.",
    "Instagram security verification is required (story data could not be fetched).":
        "Instagram-beveiligingsverificatie is vereist (verhaalgegevens kunnen niet worden opgehaald).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Verhaalgegevens kunnen niet worden opgehaald. Meestal wordt dit veroorzaakt door Instagram-verificatie, tijdelijke API-beperkingen of een verbindingsonderbreking. Probeer het over 2-3 minuten opnieuw.",
    "Could not fetch story data. Please try again shortly.":
        "Kan verhaalgegevens niet ophalen. Probeer het binnenkort opnieuw.",
    "Secret Mode": "Geheime modus",
    "Starting VERDICT...": "Beginnen met VERDICT...",
    "DID YOU KNOW?": "WIST JE DAT?",
    "Estimated time left: {time}": "Geschatte resterende tijd: {time}",
    "Estimating remaining time...": "Resterende tijd schatten...",
    "LOG OUT": "UITLOGGEN",
    "Open Profile": "Profiel openen",
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
    "Analysis Time!": "C'est l'heure de l'analyse !",
    "CLOSE": "FERMER",
    "SYSTEM UNDER MAINTENANCE": "SYSTÈME EN MAINTENANCE",
    "Bio Planner": "Planificateur biologique",
    "Store link not set.": "Lien de magasin non défini.",
    "Invalid store link.": "Lien de magasin invalide.",
    "Could not open the link.": "Impossible d'ouvrir le lien.",
    "Please try again.": "Veuillez réessayer.",
    "Show error": "Afficher l'erreur",
    "Exception": "Exception",
    "Load error": "Erreur de chargement",
    "Code": "Code",
    "Timeout": "Temps mort",
    "REST probe failed: missing auth.":
        "Échec de la sonde REST : authentification manquante.",
    "REST probe success (Firestore endpoint reachable).":
        "Réussite de la sonde REST (point de terminaison Firestore accessible).",
    "REST probe failed (check logs).":
        "La sonde REST a échoué (vérifier les journaux).",
    "Firebase Auth probe failed.": "La sonde Firebase Auth a échoué.",
    "Firebase Auth probe success.": "Réussite de la sonde Firebase Auth.",
    "Firebase token probe failed.":
        "La vérification du jeton Firebase a échoué.",
    "CRITICAL DIAGNOSTIC ERROR": "ERREUR DE DIAGNOSTIC CRITIQUE",
    "COPY": "COPIE",
    "OPEN LOGS": "JOURNAUX OUVERTS",
    "Firebase": "Base de feu",
    "Store": "Magasin",
    "Copy all": "Copier tout",
    "Close": "Fermer",
    "Auth Probe": "Sonde d'authentification",
    "Write Test": "Test d'écriture",
    "REST Probe": "Sonde REST",
    "Restore Test": "Test de restauration",
    "Firebase auth error: user verification failed.":
        "Erreur d'authentification Firebase : la vérification de l'utilisateur a échoué.",
    "Firestore test write successful.": "Test d'écriture Firestore réussi.",
    "Firestore test failed.": "Le test Firestore a échoué.",
    "Firestore auth error: user verification failed.":
        "Erreur d'authentification Firestore : la vérification de l'utilisateur a échoué.",
    "Firestore counter write failed.":
        "Échec de l'écriture du compteur Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Authentification Firestore manquante : ig_users bloque l'écriture.",
    "Firestore ig_users write failed.":
        "Échec de l'écriture de Firestore ig_users.",
    "User": "Utilisateur",
    "Opening consent form...": "Formulaire de consentement d'ouverture...",
    "Your consent preference was updated.":
        "Votre préférence de consentement a été mise à jour.",
    "Consent update failed. Please try again.":
        "La mise à jour du consentement a échoué. Veuillez réessayer.",
    "Your account is blocked": "Votre compte est bloqué",
    "Access is restricted for this account.":
        "L'accès est restreint pour ce compte.",
    "Starting purchase...": "Début de l'achat...",
    "Purchase cancelled.": "Achat annulé.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium actif ✅ Les publicités et les temps d'attente sont désactivés.",
    "Purchase failed. Please try again.":
        "L'achat a échoué. Veuillez réessayer.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "La vérification de la session est requise. Veuillez vérifier votre compte dans l'application Instagram et réessayer.",
    "Instagram returned no data.": "Instagram n'a renvoyé aucune donnée.",
    "Session verification failed. Please log in again.":
        "La vérification de la session a échoué. Veuillez vous reconnecter.",
    "Open Instagram": "Ouvrez Instagram",
    "Instagram message": "Message Instagram",
    "Loading stories...": "Chargement des histoires...",
    "No data": "Aucune donnée",
    "NEW": "NOUVEAU",
    "Login": "Se connecter",
    "Session verified, redirecting...": "Session vérifiée, redirection...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ESPACE PUBLICITAIRE",
    "Admin mode active": "Mode administrateur actif",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Nous évoluons chaque jour pour vous offrir une meilleure expérience. Vos commentaires sont précieux pour nous ; nous serions ravis de vous entendre !",
    "Please log in to start the analysis.":
        "Veuillez vous connecter pour démarrer l'analyse.",
    "Welcome, {username}": "Bienvenue, {username}",
    "REFRESH DATA": "RAFRAÎCHIR LES DONNÉES",
    "LOG IN WITH INSTAGRAM": "CONNEXION AVEC INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analyse des données...\nCela peut prendre un moment.",
    "Processing data...\nAlmost done.":
        "Traitement des données...\nPresque terminé.",
    "Loading ad...\nPlease wait.":
        "Chargement de l'annonce...\nVeuillez patienter.",
    "Google ad warning: {reason}":
        "Avertissement publicitaire Google : {reason}",
    "All analysis is securely processed locally on your device.":
        "Toutes les analyses sont traitées en toute sécurité localement sur votre appareil.",
    "Total analyses today: {count}": "Analyses totales aujourd'hui : {count}",
    "Next analysis": "Analyse suivante",
    "Ready to scan.": "Prêt à numériser.",
    "Analysis available now": "Analyse disponible maintenant",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "L'analyse est disponible dès maintenant, mais l'exécution d'analyses consécutives peut mettre votre compte en danger.",
    "Please wait": "S'il vous plaît, attendez",
    "Warning": "Avertissement",
    "Next analysis: {time}": "Analyse suivante : {time}",
    "WATCH AD AND START ANALYSIS": "REGARDER L'ANNONCE ET COMMENCER L'ANALYSE",
    "START ANALYSIS": "COMMENCER L'ANALYSE",
    "Start analysis?": "Démarrer l'analyse ?",
    "Reset App Data": "Réinitialiser les données de l'application",
    "This will wipe all local data and session cookies. Are you sure?":
        "Cela effacera toutes les données locales et les cookies de session. Es-tu sûr?",
    "CANCEL": "ANNULER",
    "DELETE": "SUPPRIMER",
    "Error": "Erreur",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Échec de la récupération des données : {err}\n\nDépannage : essayez de vous déconnecter et de vous reconnecter.",
    "Followers": "Abonnés",
    "Following": "Suivant",
    "New Followers": "Nouveaux abonnés",
    "Not Following Back": "Ne pas suivre",
    "Lost Followers": "Abonnés perdus",
    "Legal Disclaimer": "Mentions légales",
    "Unfollowed Users": "Utilisateurs non suivis",
    "Rate Us": "Évaluez-nous",
    "Contact Us": "Contactez-nous",
    "Remove Ads & Wait Times":
        "Supprimer les publicités et les temps d'attente",
    "This box is currently under test.": "Cette box est actuellement en test.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Regardez des histoires en secret ou zoomez sur les photos de profil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Veuillez vous connecter pour regarder des histoires en secret et agrandir les photos de profil.",
    "Will be shown after the ad, please wait.":
        "Sera diffusé après l'annonce, veuillez patienter.",
    "What would you like to do?": "Qu'aimeriez-vous faire ?",
    "Enlarge profile photo": "Agrandir la photo de profil",
    "Watch story secretly": "Regarder l'histoire en secret",
    "No story data available.": "Aucune donnée d'histoire disponible.",
    "I HAVE READ AND AGREE": "J'AI LU ET D'ACCORD",
    "Withdraw Consent": "Retirer le consentement",
    "Confirm": "Confirmer",
    "Your consent settings will be reset. Are you sure?":
        "Vos paramètres de consentement seront réinitialisés. Es-tu sûr?",
    "Yes": "Oui",
    "Cancel": "Annuler",
    "Session verified, redirecting securely...":
        "Session vérifiée, redirection sécurisée...",
    "Analysis complete ✅": "Analyse terminée ✅",
    "Purchases are not available right now. Please try again later.":
        "Les achats ne sont pas disponibles pour le moment. Veuillez réessayer plus tard.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Achat terminé, mais Premium n'est pas encore actif. Veuillez réessayer.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Bienvenue sur Premium ! Les publicités et les temps d'attente sont supprimés.",
    "Your Premium membership is active.": "Votre abonnement Premium est actif.",
    "Restore Purchases": "Restaurer les achats",
    "RESTORE": "RESTAURER",
    "Restoring purchases...": "Restauration des achats...",
    "Purchases restored ✅": "Achats restaurés ✅",
    "No purchases to restore.": "Aucun achat à restaurer.",
    "Restore failed: {err}": "Échec de la restauration : {err}",
    "Enter PIN": "Entrez le code PIN",
    "PIN accepted, timer reset ✅":
        "Code PIN accepté, minuterie réinitialisée ✅",
    "Invalid PIN": "Code PIN invalide",
    "OK": "D'ACCORD",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "En téléchargeant et en utilisant cette application, chaque Utilisateur est réputé avoir lu, compris et accepté irrévocablement au préalable le texte des « Conditions d'utilisation et clause de non-responsabilité » ci-dessous :",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Article 1 : Confidentialité des données et architecture de traitement local",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT est un logiciel « côté client ». Les identifiants de connexion de l'Utilisateur (identifiant, mot de passe, cookies de session) ne sont en aucun cas transmis ou stockés sur un serveur externe. Toutes les activités de traitement des données se déroulent exclusivement dans la mémoire temporaire (RAM) et le stockage local de l'appareil de l'utilisateur. L'application fonctionne comme un « navigateur-wrapper » fonctionnant sur l'interface Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Article 2 : Risques liés aux plateformes tierces",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) se réserve le droit de restreindre l'utilisation de logiciels tiers conformément aux politiques de sa plateforme. Tous les risques, y compris, mais sans s'y limiter, les « blocages d'actions », les « restrictions de compte », les « shadowbans » ou les « fermetures de compte » pouvant découler de l'utilisation de l'application, appartiennent exclusivement à l'Utilisateur. Le développeur VERDICT ne peut être tenu responsable de tout dommage direct ou indirect résultant de telles sanctions administratives.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Article 3 : Exclusion de garantie et limitation de responsabilité",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Ce logiciel est fourni « EN L'ÉTAT » et « TEL QUE DISPONIBLE ». L'exactitude, la continuité ou la qualité marchande à 100 % des résultats d'analyse fournis par le logiciel ne sont pas garanties. L'Utilisateur reconnaît que tous les résultats découlant de transactions juridiques ou commerciales basées sur les données de l'application relèvent de sa propre responsabilité ; et déclare et s'engage à dégager le développeur de toute responsabilité contre toutes réclamations, poursuites et plaintes.",
    "Article 4: Intellectual Property and Independence Notice":
        "Article 4 : Propriété Intellectuelle et Avis d'Indépendance",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT est un projet de développeur indépendant. Les marques « Instagram », « Facebook » et « Meta » sont des marques déposées de Meta Platforms, Inc. Cette application n'a aucun partenariat commercial, accord de parrainage ou affiliation officielle avec les sociétés susmentionnées.",
    "Article 5: Service Continuity and Platform Changes":
        "Article 5 : Continuité du Service et Modifications de la Plateforme",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Des modifications fondamentales apportées à l'API Instagram ou à l'infrastructure Web peuvent entraîner la perte partielle ou totale de la fonctionnalité de l'application. Le développeur ne s'engage pas à mettre à jour l'application ou à maintenir le service en réponse à de tels changements d'infrastructure, qui sont considérés comme « force majeure ».",
    "Analysis complete, results will be shown after the ad.":
        "Analyse terminée, les résultats seront affichés après la publicité.",
    "Analysis failed": "L'analyse a échoué",
    "Reason: {reason}": "Raison : {reason}",
    "Tip: Logging out and logging back in may help.":
        "Astuce : Se déconnecter et se reconnecter peut s'avérer utile.",
    "Quick check: Counts are the same. No changes detected.":
        "Vérification rapide : les comptes sont les mêmes. Aucun changement détecté.",
    "Daily Metrics": "Mesures quotidiennes",
    "Active users": "Utilisateurs actifs",
    "Daily queries": "Requêtes quotidiennes",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Le chargement des données a été interrompu : données suiveuses incomplètes ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Le chargement des données a été interrompu : données suivantes incomplètes ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Le chargement des données a été interrompu : Instagram a renvoyé des données vides.",
    "Data loading stopped due to an unexpected error.":
        "Le chargement des données s'est arrêté en raison d'une erreur inattendue.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram a renvoyé un avertissement de comportement automatisé. Nous avons arrêté de récupérer des données pour des raisons de sécurité.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram a demandé une vérification de sécurité. Vérifiez dans l'application Instagram et réessayez.",
    "Session is invalid or waiting for verification. Please log in again.":
        "La session n'est pas valide ou est en attente de vérification. Veuillez vous reconnecter.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Trop de demandes ont été envoyées. Le chargement des données a été interrompu pour des raisons de sécurité.",
    "Data loading could not complete due to a connection issue.":
        "Le chargement des données n'a pas pu se terminer en raison d'un problème de connexion.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram a renvoyé une erreur (HTTP {code}). Le chargement des données a été interrompu.",
    "Instagram security verification is required (story data could not be fetched).":
        "Une vérification de sécurité Instagram est requise (les données de l'histoire n'ont pas pu être récupérées).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Les données de l'histoire n'ont pas pu être récupérées. Cela est généralement dû à une vérification Instagram, à des restrictions temporaires de l'API ou à une interruption de connexion. Veuillez réessayer dans 2-3 minutes.",
    "Could not fetch story data. Please try again shortly.":
        "Impossible de récupérer les données de l'histoire. Veuillez réessayer sous peu.",
    "Secret Mode": "Mode secret",
    "Starting VERDICT...": "Démarrage du VERDICT...",
    "DID YOU KNOW?": "SAVIEZ-VOUS?",
    "Estimated time left: {time}": "Temps restant estimé : {time}",
    "Estimating remaining time...": "Estimation du temps restant...",
    "LOG OUT": "DÉCONNEXION",
    "Open Profile": "Ouvrir le profil",
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
    "Analysis Time!": "È tempo di analisi!",
    "CLOSE": "VICINO",
    "SYSTEM UNDER MAINTENANCE": "SISTEMA IN MANUTENZIONE",
    "Bio Planner": "Pianificatore biologico",
    "Store link not set.": "Collegamento al negozio non impostato.",
    "Invalid store link.": "Collegamento al negozio non valido.",
    "Could not open the link.": "Impossibile aprire il collegamento.",
    "Please try again.": "Per favore riprova.",
    "Show error": "Mostra errore",
    "Exception": "Eccezione",
    "Load error": "Errore di caricamento",
    "Code": "Codice",
    "Timeout": "Tempo scaduto",
    "REST probe failed: missing auth.":
        "Sondaggio REST fallito: autenticazione mancante.",
    "REST probe success (Firestore endpoint reachable).":
        "Probe REST riuscita (endpoint Firestore raggiungibile).",
    "REST probe failed (check logs).":
        "La sonda REST non è riuscita (controlla i log).",
    "Firebase Auth probe failed.":
        "La sonda di autenticazione Firebase non è riuscita.",
    "Firebase Auth probe success.":
        "Probe di autenticazione Firebase riuscita.",
    "Firebase token probe failed.":
        "Il test del token Firebase non è riuscito.",
    "CRITICAL DIAGNOSTIC ERROR": "ERRORE DIAGNOSTICO CRITICO",
    "COPY": "COPIA",
    "OPEN LOGS": "REGISTRI APERTI",
    "Firebase": "Base di fuoco",
    "Store": "Negozio",
    "Copy all": "Copia tutto",
    "Close": "Vicino",
    "Auth Probe": "Sonda di autenticazione",
    "Write Test": "Scrivi prova",
    "REST Probe": "Sonda RESTO",
    "Restore Test": "Ripristina prova",
    "Firebase auth error: user verification failed.":
        "Errore di autenticazione Firebase: verifica dell'utente non riuscita.",
    "Firestore test write successful.":
        "Scrittura del test Firestore riuscita.",
    "Firestore test failed.": "Il test Firestore non è riuscito.",
    "Firestore auth error: user verification failed.":
        "Errore di autenticazione Firestore: verifica dell'utente non riuscita.",
    "Firestore counter write failed.":
        "Scrittura del contatore Firestore non riuscita.",
    "Firestore auth missing: ig_users write blocked.":
        "Autenticazione Firestore mancante: scrittura ig_users bloccata.",
    "Firestore ig_users write failed.":
        "Scrittura ig_users su Firestore non riuscita.",
    "User": "Utente",
    "Opening consent form...": "Apertura modulo di consenso...",
    "Your consent preference was updated.":
        "La tua preferenza per il consenso è stata aggiornata.",
    "Consent update failed. Please try again.":
        "Aggiornamento del consenso non riuscito. Per favore riprova.",
    "Your account is blocked": "Il tuo account è bloccato",
    "Access is restricted for this account.":
        "L'accesso è limitato per questo account.",
    "Starting purchase...": "Avvio acquisto...",
    "Purchase cancelled.": "Acquisto annullato.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium attivo ✅ Annunci e tempi di attesa disabilitati.",
    "Purchase failed. Please try again.":
        "Acquisto fallito. Per favore riprova.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "È richiesta la verifica della sessione. Verifica il tuo account nell'app Instagram e riprova.",
    "Instagram returned no data.": "Instagram non ha restituito dati.",
    "Session verification failed. Please log in again.":
        "La verifica della sessione non è riuscita. Effettua nuovamente l'accesso.",
    "Open Instagram": "Apri Instagram",
    "Instagram message": "Messaggio di Instagram",
    "Loading stories...": "Caricamento storie...",
    "No data": "Nessun dato",
    "NEW": "NUOVO",
    "Login": "Login",
    "Session verified, redirecting...":
        "Sessione verificata, reindirizzamento...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "SPAZIO ANNUNCI",
    "Admin mode active": "Modalità amministratore attiva",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Ci evolviamo ogni giorno per offrirti un'esperienza migliore. Il tuo feedback è prezioso per noi: ci piacerebbe sentire la tua opinione!",
    "Please log in to start the analysis.":
        "Effettua il login per avviare l'analisi.",
    "Welcome, {username}": "Benvenuto, {username}",
    "REFRESH DATA": "AGGIORNA DATI",
    "LOG IN WITH INSTAGRAM": "ACCEDI CON INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analisi dei dati...\nL'operazione potrebbe richiedere un momento.",
    "Processing data...\nAlmost done.": "Elaborazione dati...\nQuasi finito.",
    "Loading ad...\nPlease wait.":
        "Caricamento annuncio...\nPer favore aspetta.",
    "Google ad warning: {reason}": "Avviso annuncio Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Tutte le analisi vengono elaborate in modo sicuro localmente sul tuo dispositivo.",
    "Total analyses today: {count}": "Analisi totali oggi: {count}",
    "Next analysis": "Prossima analisi",
    "Ready to scan.": "Pronto per la scansione.",
    "Analysis available now": "Analisi disponibile ora",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "L'analisi è ora disponibile, ma l'esecuzione di analisi consecutive potrebbe mettere a rischio il tuo account.",
    "Please wait": "attendere prego",
    "Warning": "Avvertimento",
    "Next analysis: {time}": "Prossima analisi: {time}",
    "WATCH AD AND START ANALYSIS": "GUARDA L'ANNUNCIO E INIZIA L'ANALISI",
    "START ANALYSIS": "INIZIA L'ANALISI",
    "Start analysis?": "Iniziare l'analisi?",
    "Reset App Data": "Reimposta i dati dell'app",
    "This will wipe all local data and session cookies. Are you sure?":
        "Ciò cancellerà tutti i dati locali e i cookie di sessione. Sei sicuro?",
    "CANCEL": "CANCELLARE",
    "DELETE": "ELIMINARE",
    "Error": "Errore",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Recupero dati non riuscito: {err}\n\nRisoluzione del problema: prova a disconnetterti e ad accedere nuovamente.",
    "Followers": "Seguaci",
    "Following": "Seguente",
    "New Followers": "Nuovi follower",
    "Not Following Back": "Non seguire indietro",
    "Lost Followers": "Seguaci perduti",
    "Legal Disclaimer": "Dichiarazione di non responsabilità legale",
    "Unfollowed Users": "Utenti non seguiti",
    "Rate Us": "Valutaci",
    "Contact Us": "Contattaci",
    "Remove Ads & Wait Times": "Rimuovi pubblicità e tempi di attesa",
    "This box is currently under test.":
        "Questa scatola è attualmente in fase di test.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Guarda le storie in segreto o ingrandisci le foto del profilo",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Accedi per guardare le storie in segreto e ingrandire le foto del profilo.",
    "Will be shown after the ad, please wait.":
        "Verrà mostrato dopo l'annuncio, attendere.",
    "What would you like to do?": "Cosa ti piacerebbe fare?",
    "Enlarge profile photo": "Ingrandisci la foto del profilo",
    "Watch story secretly": "Guarda la storia di nascosto",
    "No story data available.": "Nessun dato sulla storia disponibile.",
    "I HAVE READ AND AGREE": "HO LETTO E ACCETTO",
    "Withdraw Consent": "Revoca del consenso",
    "Confirm": "Confermare",
    "Your consent settings will be reset. Are you sure?":
        "Le impostazioni del tuo consenso verranno ripristinate. Sei sicuro?",
    "Yes": "SÌ",
    "Cancel": "Cancellare",
    "Session verified, redirecting securely...":
        "Sessione verificata, reindirizzamento sicuro...",
    "Analysis complete ✅": "Analisi completata✅",
    "Purchases are not available right now. Please try again later.":
        "Gli acquisti non sono disponibili al momento. Per favore riprova più tardi.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Acquisto completato, ma Premium non è ancora attivo. Per favore riprova.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Benvenuto in Premium! Gli annunci e i tempi di attesa vengono rimossi.",
    "Your Premium membership is active.":
        "Il tuo abbonamento Premium è attivo.",
    "Restore Purchases": "Ripristina gli acquisti",
    "RESTORE": "RIPRISTINARE",
    "Restoring purchases...": "Ripristino degli acquisti...",
    "Purchases restored ✅": "Acquisti ripristinati ✅",
    "No purchases to restore.": "Nessun acquisto da ripristinare.",
    "Restore failed: {err}": "Ripristino non riuscito: {err}",
    "Enter PIN": "Inserisci il PIN",
    "PIN accepted, timer reset ✅": "PIN accettato, reset timer ✅",
    "Invalid PIN": "PIN non valido",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Scaricando e utilizzando questa applicazione, si ritiene che ogni Utente abbia letto, compreso e accettato irrevocabilmente in anticipo il testo \"Termini di utilizzo e Dichiarazione di non responsabilità\" di seguito:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Articolo 1: Privacy dei dati e architettura locale del trattamento",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT è un software \"lato client\". Le credenziali di accesso dell'Utente (username, password, cookie di sessione) non vengono in nessun caso trasmesse o memorizzate su un server esterno. Tutte le attività di trattamento dei dati avvengono esclusivamente all'interno della memoria temporanea (RAM) e di archiviazione locale del dispositivo dell'Utente. L'applicazione funziona come un \"wrapper del browser\" che opera sull'interfaccia di Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Articolo 2: Rischi della Piattaforma di Terzi",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) si riserva il diritto di limitare l'uso di software di terze parti in base alle politiche della piattaforma. Tutti i rischi, inclusi ma non limitati a \"blocchi di azioni\", \"restrizioni dell'account\", \"shadowban\" o \"chiusure di account\" che potrebbero derivare dall'uso dell'applicazione, appartengono esclusivamente all'Utente. Lo sviluppatore VERDICT non può essere ritenuto responsabile per eventuali danni diretti o indiretti derivanti da tali sanzioni amministrative.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Articolo 3: Esclusione di garanzia e limitazione di responsabilità",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Questo software viene fornito \"COSÌ COM'È\" e \"COME DISPONIBILE\". L'accuratezza, la continuità o la commerciabilità al 100% dei risultati dell'analisi forniti dal software non sono garantite. L'Utente riconosce che eventuali risultati derivanti da transazioni legali o commerciali basate sui dati dell'applicazione sono di propria responsabilità; e dichiara e si impegna a tenere indenne lo sviluppatore da tutte le pretese, azioni legali e reclami.",
    "Article 4: Intellectual Property and Independence Notice":
        "Articolo 4: Avviso sulla proprietà intellettuale e sull'indipendenza",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT è un progetto di sviluppo indipendente. I marchi \"Instagram\", \"Facebook\" e \"Meta\" sono marchi registrati di Meta Platforms, Inc. Questa applicazione non ha alcuna partnership commerciale, accordo di sponsorizzazione o affiliazione ufficiale con le società sopra menzionate.",
    "Article 5: Service Continuity and Platform Changes":
        "Articolo 5: Continuità del Servizio e Modifiche della Piattaforma",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Modifiche fondamentali all'API di Instagram o all'infrastruttura web possono causare la perdita parziale o totale delle funzionalità dell'applicazione. Lo sviluppatore non si impegna ad aggiornare l'applicazione o a mantenere il servizio in risposta a tali cambiamenti infrastrutturali, che sono considerati \"forza maggiore\".",
    "Analysis complete, results will be shown after the ad.":
        "Analisi completata, i risultati verranno visualizzati dopo l'annuncio.",
    "Analysis failed": "Analisi fallita",
    "Reason: {reason}": "Motivo: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Suggerimento: disconnettersi e accedere nuovamente può essere utile.",
    "Quick check: Counts are the same. No changes detected.":
        "Controllo rapido: i conteggi sono gli stessi. Nessuna modifica rilevata.",
    "Daily Metrics": "Metriche giornaliere",
    "Active users": "Utenti attivi",
    "Daily queries": "Domande quotidiane",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Il caricamento dei dati è stato interrotto: dati del follower incompleti ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Il caricamento dei dati è stato interrotto: dati successivi incompleti ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Il caricamento dei dati è stato interrotto: Instagram ha restituito dati vuoti.",
    "Data loading stopped due to an unexpected error.":
        "Il caricamento dei dati si è interrotto a causa di un errore imprevisto.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram ha restituito un avviso di comportamento automatico. Abbiamo interrotto il recupero dei dati per motivi di sicurezza.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram ha richiesto la verifica di sicurezza. Verifica nell'app Instagram e riprova.",
    "Session is invalid or waiting for verification. Please log in again.":
        "La sessione non è valida o è in attesa di verifica. Effettua nuovamente l'accesso.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Sono state inviate troppe richieste. Il caricamento dei dati è stato interrotto per sicurezza.",
    "Data loading could not complete due to a connection issue.":
        "Impossibile completare il caricamento dei dati a causa di un problema di connessione.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram ha restituito un errore (HTTP {code}). Il caricamento dei dati è stato interrotto.",
    "Instagram security verification is required (story data could not be fetched).":
        "È richiesta la verifica della sicurezza di Instagram (non è stato possibile recuperare i dati della storia).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Impossibile recuperare i dati della storia. Di solito ciò è causato dalla verifica di Instagram, da restrizioni API temporanee o da un'interruzione della connessione. Riprova tra 2-3 minuti.",
    "Could not fetch story data. Please try again shortly.":
        "Impossibile recuperare i dati della storia. Per favore riprova a breve.",
    "Secret Mode": "Modalità segreta",
    "Starting VERDICT...": "Inizio VERDETTO...",
    "DID YOU KNOW?": "LO SAPEVATE?",
    "Estimated time left: {time}": "Tempo stimato rimanente: {time}",
    "Estimating remaining time...": "Stima del tempo rimanente...",
    "LOG OUT": "DISCONNETTERSI",
    "Open Profile": "Apri profilo",
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
    "Analysis Time!": "Thời gian phân tích!",
    "CLOSE": "ĐÓNG",
    "SYSTEM UNDER MAINTENANCE": "HỆ THỐNG ĐANG BẢO TRÌ",
    "Bio Planner": "Công cụ lập kế hoạch sinh học",
    "Store link not set.": "Liên kết cửa hàng chưa được đặt.",
    "Invalid store link.": "Liên kết cửa hàng không hợp lệ.",
    "Could not open the link.": "Không thể mở liên kết.",
    "Please try again.": "Vui lòng thử lại.",
    "Show error": "Hiển thị lỗi",
    "Exception": "Ngoại lệ",
    "Load error": "Lỗi tải",
    "Code": "Mã số",
    "Timeout": "Hết giờ",
    "REST probe failed: missing auth.":
        "Thăm dò REST không thành công: thiếu auth.",
    "REST probe success (Firestore endpoint reachable).":
        "Thành công thăm dò REST (Có thể truy cập điểm cuối Firestore).",
    "REST probe failed (check logs).":
        "Thăm dò REST không thành công (kiểm tra nhật ký).",
    "Firebase Auth probe failed.":
        "Thăm dò xác thực Firebase không thành công.",
    "Firebase Auth probe success.": "Thành công thăm dò xác thực Firebase.",
    "Firebase token probe failed.":
        "Thăm dò mã thông báo Firebase không thành công.",
    "CRITICAL DIAGNOSTIC ERROR": "LỖI CHẨN ĐOÁN NGHIÊM TRỌNG",
    "COPY": "SAO CHÉP",
    "OPEN LOGS": "MỞ NHẬT KÝ",
    "Firebase": "căn cứ hỏa lực",
    "Store": "Cửa hàng",
    "Copy all": "Sao chép tất cả",
    "Close": "Đóng",
    "Auth Probe": "Thăm dò xác thực",
    "Write Test": "Viết bài kiểm tra",
    "REST Probe": "thăm dò REST",
    "Restore Test": "Khôi phục bài kiểm tra",
    "Firebase auth error: user verification failed.":
        "Lỗi xác thực Firebase: xác minh người dùng không thành công.",
    "Firestore test write successful.": "Viết thử nghiệm Firestore thành công.",
    "Firestore test failed.": "Thử nghiệm Firestore không thành công.",
    "Firestore auth error: user verification failed.":
        "Lỗi xác thực Firestore: xác minh người dùng không thành công.",
    "Firestore counter write failed.": "Ghi bộ đếm Firestore không thành công.",
    "Firestore auth missing: ig_users write blocked.":
        "Thiếu xác thực Firestore: ig_users viết bị chặn.",
    "Firestore ig_users write failed.":
        "Firestore ig_users ghi không thành công.",
    "User": "người dùng",
    "Opening consent form...": "Đang mở biểu mẫu đồng ý...",
    "Your consent preference was updated.":
        "Tùy chọn đồng ý của bạn đã được cập nhật.",
    "Consent update failed. Please try again.":
        "Cập nhật sự đồng ý không thành công. Vui lòng thử lại.",
    "Your account is blocked": "Tài khoản của bạn bị chặn",
    "Access is restricted for this account.":
        "Quyền truy cập bị hạn chế đối với tài khoản này.",
    "Starting purchase...": "Bắt đầu mua hàng...",
    "Purchase cancelled.": "Đã hủy mua hàng.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium kích hoạt ✅ Quảng cáo và thời gian chờ bị tắt.",
    "Purchase failed. Please try again.":
        "Mua hàng không thành công. Vui lòng thử lại.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Cần phải xác minh phiên. Vui lòng xác minh tài khoản của bạn trong ứng dụng Instagram và thử lại.",
    "Instagram returned no data.": "Instagram không trả lại dữ liệu.",
    "Session verification failed. Please log in again.":
        "Xác minh phiên không thành công. Vui lòng đăng nhập lại.",
    "Open Instagram": "Mở Instagram",
    "Instagram message": "tin nhắn trên Instagram",
    "Loading stories...": "Đang tải câu chuyện...",
    "No data": "Không có dữ liệu",
    "NEW": "MỚI",
    "Login": "Đăng nhập",
    "Session verified, redirecting...":
        "Đã xác minh phiên, đang chuyển hướng...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "KHÔNG GIAN QUẢNG CÁO",
    "Admin mode active": "Chế độ quản trị đang hoạt động",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Chúng tôi đang phát triển mỗi ngày để cung cấp cho bạn trải nghiệm tốt hơn. Phản hồi của bạn rất có giá trị đối với chúng tôi—chúng tôi rất mong nhận được phản hồi từ bạn!",
    "Please log in to start the analysis.":
        "Vui lòng đăng nhập để bắt đầu phân tích.",
    "Welcome, {username}": "Chào mừng, {username}",
    "REFRESH DATA": "LÀM MỚI DỮ LIỆU",
    "LOG IN WITH INSTAGRAM": "ĐĂNG NHẬP BẰNG INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Phân tích dữ liệu...\nViệc này có thể mất một chút thời gian.",
    "Processing data...\nAlmost done.": "Đang xử lý dữ liệu...\nGần xong rồi.",
    "Loading ad...\nPlease wait.":
        "Đang tải quảng cáo...\nXin vui lòng chờ đợi.",
    "Google ad warning: {reason}": "Cảnh báo quảng cáo của Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Tất cả các phân tích được xử lý an toàn cục bộ trên thiết bị của bạn.",
    "Total analyses today: {count}": "Tổng số phân tích hôm nay: {count}",
    "Next analysis": "Phân tích tiếp theo",
    "Ready to scan.": "Sẵn sàng để quét.",
    "Analysis available now": "Phân tích hiện có sẵn",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Phân tích hiện có sẵn nhưng việc chạy phân tích liên tục có thể khiến tài khoản của bạn gặp rủi ro.",
    "Please wait": "Vui lòng chờ",
    "Warning": "Cảnh báo",
    "Next analysis: {time}": "Phân tích tiếp theo: {time}",
    "WATCH AD AND START ANALYSIS": "XEM QUẢNG CÁO VÀ BẮT ĐẦU PHÂN TÍCH",
    "START ANALYSIS": "BẮT ĐẦU PHÂN TÍCH",
    "Start analysis?": "Bắt đầu phân tích?",
    "Reset App Data": "Đặt lại dữ liệu ứng dụng",
    "This will wipe all local data and session cookies. Are you sure?":
        "Thao tác này sẽ xóa tất cả dữ liệu cục bộ và cookie phiên. Bạn có chắc không?",
    "CANCEL": "HỦY BỎ",
    "DELETE": "XÓA BỎ",
    "Error": "Lỗi",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Truy xuất dữ liệu không thành công: {err}\n\nKhắc phục sự cố: Hãy thử đăng xuất và đăng nhập lại.",
    "Followers": "Người theo dõi",
    "Following": "Tiếp theo",
    "New Followers": "Người theo dõi mới",
    "Not Following Back": "Không theo dõi lại",
    "Lost Followers": "Người theo dõi bị mất",
    "Legal Disclaimer": "Tuyên bố từ chối trách nhiệm pháp lý",
    "Unfollowed Users": "Người dùng đã hủy theo dõi",
    "Rate Us": "Đánh giá chúng tôi",
    "Contact Us": "Liên hệ với chúng tôi",
    "Remove Ads & Wait Times": "Xóa quảng cáo và thời gian chờ",
    "This box is currently under test.": "Hộp này hiện đang được thử nghiệm.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Xem câu chuyện một cách bí mật hoặc thu phóng ảnh hồ sơ",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Vui lòng đăng nhập để xem truyện bí mật và phóng to ảnh hồ sơ.",
    "Will be shown after the ad, please wait.":
        "Sẽ được hiển thị sau quảng cáo, vui lòng chờ.",
    "What would you like to do?": "Bạn muốn làm gì?",
    "Enlarge profile photo": "Phóng to ảnh hồ sơ",
    "Watch story secretly": "Xem câu chuyện bí mật",
    "No story data available.": "Không có dữ liệu câu chuyện có sẵn.",
    "I HAVE READ AND AGREE": "TÔI ĐÃ ĐỌC VÀ ĐỒNG Ý",
    "Withdraw Consent": "Rút lại sự đồng ý",
    "Confirm": "Xác nhận",
    "Your consent settings will be reset. Are you sure?":
        "Cài đặt đồng ý của bạn sẽ được đặt lại. Bạn có chắc không?",
    "Yes": "Đúng",
    "Cancel": "Hủy bỏ",
    "Session verified, redirecting securely...":
        "Phiên đã được xác minh, đang chuyển hướng an toàn...",
    "Analysis complete ✅": "Phân tích hoàn tất ✅",
    "Purchases are not available right now. Please try again later.":
        "Việc mua hàng hiện không có sẵn. Vui lòng thử lại sau.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Giao dịch mua đã hoàn tất nhưng Premium vẫn chưa hoạt động. Vui lòng thử lại.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Chào mừng đến với Premium! Quảng cáo và thời gian chờ đợi được loại bỏ.",
    "Your Premium membership is active.":
        "Tư cách thành viên Premium của bạn đang hoạt động.",
    "Restore Purchases": "Khôi phục mua hàng",
    "RESTORE": "KHÔI PHỤC",
    "Restoring purchases...": "Đang khôi phục giao dịch mua...",
    "Purchases restored ✅": "Đã khôi phục giao dịch mua hàng ✅",
    "No purchases to restore.": "Không có mua hàng để khôi phục.",
    "Restore failed: {err}": "Khôi phục không thành công: {err}",
    "Enter PIN": "Nhập mã PIN",
    "PIN accepted, timer reset ✅": "Chấp nhận mã PIN, đặt lại hẹn giờ ✅",
    "Invalid PIN": "Mã PIN không hợp lệ",
    "OK": "ĐƯỢC RỒI",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Bằng cách tải xuống và sử dụng ứng dụng này, mọi Người dùng được coi là đã đọc, hiểu và chấp nhận trước văn bản \"Điều khoản sử dụng và Tuyên bố từ chối trách nhiệm\" bên dưới:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Điều 1: Quyền riêng tư dữ liệu và kiến ​​trúc xử lý cục bộ",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT là phần mềm 'phía máy khách'. Thông tin đăng nhập của Người dùng (tên người dùng, mật khẩu, cookie phiên) trong mọi trường hợp không được truyền đến hoặc lưu trữ trên máy chủ bên ngoài. Tất cả các hoạt động xử lý dữ liệu chỉ diễn ra trong bộ nhớ tạm thời (RAM) và bộ nhớ cục bộ trên thiết bị của Người dùng. Ứng dụng này hoạt động như một 'trình bao bọc trình duyệt' hoạt động trên giao diện Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Điều 2: Rủi ro nền tảng của bên thứ ba",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) có quyền hạn chế việc sử dụng phần mềm của bên thứ ba theo chính sách nền tảng của mình. Tất cả rủi ro, bao gồm nhưng không giới hạn ở 'các khối hành động', 'hạn chế tài khoản', 'cấm chặn' hoặc 'đóng tài khoản' có thể phát sinh từ việc sử dụng ứng dụng, chỉ thuộc về Người dùng. Nhà phát triển VERDICT không thể chịu trách nhiệm pháp lý về bất kỳ thiệt hại trực tiếp hoặc gián tiếp nào phát sinh từ các biện pháp xử phạt hành chính đó.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Điều 3: Tuyên bố miễn trừ trách nhiệm bảo hành và giới hạn trách nhiệm pháp lý",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Phần mềm này được cung cấp 'AS-IS' và 'AS AVAILABLE'. Độ chính xác, tính liên tục hoặc khả năng bán được 100% của kết quả phân tích do phần mềm cung cấp không được đảm bảo. Người dùng thừa nhận rằng mọi kết quả phát sinh từ các giao dịch thương mại hoặc pháp lý dựa trên dữ liệu ứng dụng đều là trách nhiệm của chính họ; đồng thời tuyên bố và cam kết giữ cho nhà phát triển không bị tổn hại trước mọi khiếu nại, vụ kiện và khiếu nại.",
    "Article 4: Intellectual Property and Independence Notice":
        "Điều 4: Sở hữu trí tuệ và thông báo độc lập",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT là một dự án phát triển độc lập. Các nhãn hiệu 'Instagram', 'Facebook' và 'Meta' là các nhãn hiệu đã đăng ký của Meta Platforms, Inc. Ứng dụng này không có quan hệ đối tác thương mại, thỏa thuận tài trợ hoặc liên kết chính thức với các công ty nói trên.",
    "Article 5: Service Continuity and Platform Changes":
        "Điều 5: Tính liên tục của dịch vụ và thay đổi nền tảng",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Những thay đổi cơ bản đối với API Instagram hoặc cơ sở hạ tầng web có thể khiến ứng dụng mất một phần hoặc toàn bộ chức năng. Nhà phát triển không cam kết cập nhật ứng dụng hoặc duy trì dịch vụ để đáp ứng những thay đổi về cơ sở hạ tầng được coi là \"bất khả kháng\".",
    "Analysis complete, results will be shown after the ad.":
        "Phân tích hoàn tất, kết quả sẽ được hiển thị sau quảng cáo.",
    "Analysis failed": "Phân tích không thành công",
    "Reason: {reason}": "Lý do: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Mẹo: Đăng xuất và đăng nhập lại có thể hữu ích.",
    "Quick check: Counts are the same. No changes detected.":
        "Kiểm tra nhanh: Số lượng giống nhau. Không có thay đổi nào được phát hiện.",
    "Daily Metrics": "Số liệu hàng ngày",
    "Active users": "Người dùng đang hoạt động",
    "Daily queries": "Truy vấn hàng ngày",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Quá trình tải dữ liệu bị gián đoạn: dữ liệu người theo dõi không đầy đủ ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Quá trình tải dữ liệu bị gián đoạn: dữ liệu sau không đầy đủ ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Quá trình tải dữ liệu bị gián đoạn: Instagram trả về dữ liệu trống.",
    "Data loading stopped due to an unexpected error.":
        "Quá trình tải dữ liệu đã dừng do lỗi không mong muốn.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram trả lại cảnh báo hành vi tự động. Chúng tôi đã ngừng tìm nạp dữ liệu để đảm bảo an toàn.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram đã yêu cầu xác minh bảo mật. Hãy xác minh trong ứng dụng Instagram và thử lại.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Phiên không hợp lệ hoặc đang chờ xác minh. Vui lòng đăng nhập lại.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Quá nhiều yêu cầu đã được gửi đi. Quá trình tải dữ liệu bị gián đoạn vì lý do an toàn.",
    "Data loading could not complete due to a connection issue.":
        "Không thể tải dữ liệu hoàn tất do sự cố kết nối.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram trả về lỗi (HTTP {code}). Quá trình tải dữ liệu bị gián đoạn.",
    "Instagram security verification is required (story data could not be fetched).":
        "Cần phải xác minh bảo mật Instagram (không thể tìm nạp dữ liệu câu chuyện).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Không thể tìm nạp dữ liệu câu chuyện. Thông thường, điều này là do xác minh Instagram, hạn chế API tạm thời hoặc gián đoạn kết nối. Vui lòng thử lại sau 2-3 phút.",
    "Could not fetch story data. Please try again shortly.":
        "Không thể tìm nạp dữ liệu câu chuyện. Vui lòng thử lại trong thời gian ngắn.",
    "Secret Mode": "Chế độ bí mật",
    "Starting VERDICT...": "Đang bắt đầu XÁC MINH...",
    "DID YOU KNOW?": "BẠN CÓ BIẾT KHÔNG?",
    "Estimated time left: {time}": "Thời gian dự kiến ​​còn lại: {time}",
    "Estimating remaining time...": "Đang ước tính thời gian còn lại...",
    "LOG OUT": "ĐĂNG NHẬP",
    "Open Profile": "Mở hồ sơ",
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
    "Analysis Time!": "ถึงเวลาวิเคราะห์!",
    "CLOSE": "ปิด",
    "SYSTEM UNDER MAINTENANCE": "ระบบอยู่ระหว่างการบำรุงรักษา",
    "Bio Planner": "ไบโอแพลนเนอร์",
    "Store link not set.": "ไม่ได้ตั้งค่าลิงก์ร้านค้า",
    "Invalid store link.": "ลิงก์ร้านค้าไม่ถูกต้อง",
    "Could not open the link.": "ไม่สามารถเปิดลิงก์ได้",
    "Please try again.": "โปรดลองอีกครั้ง",
    "Show error": "แสดงข้อผิดพลาด",
    "Exception": "ข้อยกเว้น",
    "Load error": "โหลดผิดพลาด",
    "Code": "รหัส",
    "Timeout": "หมดเวลา",
    "REST probe failed: missing auth.":
        "การสอบสวน REST ล้มเหลว: ไม่มีการตรวจสอบสิทธิ์",
    "REST probe success (Firestore endpoint reachable).":
        "โพรบ REST สำเร็จ (เข้าถึงจุดสิ้นสุด Firestore ได้)",
    "REST probe failed (check logs).": "การสอบสวน REST ล้มเหลว (ตรวจสอบบันทึก)",
    "Firebase Auth probe failed.": "การสอบสวน Firebase Auth ล้มเหลว",
    "Firebase Auth probe success.": "การสอบสวน Firebase Auth สำเร็จ",
    "Firebase token probe failed.": "การสอบสวนโทเค็น Firebase ล้มเหลว",
    "CRITICAL DIAGNOSTIC ERROR": "ข้อผิดพลาดในการวินิจฉัยที่สำคัญ",
    "COPY": "สำเนา",
    "OPEN LOGS": "เปิดบันทึก",
    "Firebase": "ฐานไฟ",
    "Store": "เก็บ",
    "Copy all": "คัดลอกทั้งหมด",
    "Close": "ปิด",
    "Auth Probe": "การสอบสวนการตรวจสอบสิทธิ์",
    "Write Test": "เขียนแบบทดสอบ",
    "REST Probe": "โพรบส่วนที่เหลือ",
    "Restore Test": "คืนค่าการทดสอบ",
    "Firebase auth error: user verification failed.":
        "ข้อผิดพลาดการตรวจสอบสิทธิ์ Firebase: การตรวจสอบผู้ใช้ล้มเหลว",
    "Firestore test write successful.": "การเขียนการทดสอบ Firestore สำเร็จ",
    "Firestore test failed.": "การทดสอบ Firestore ล้มเหลว",
    "Firestore auth error: user verification failed.":
        "ข้อผิดพลาดการรับรองความถูกต้องของ Firestore: การตรวจสอบผู้ใช้ล้มเหลว",
    "Firestore counter write failed.": "การเขียนตัวนับ Firestore ล้มเหลว",
    "Firestore auth missing: ig_users write blocked.":
        "ขาดการรับรองความถูกต้องของ Firestore: การเขียน ig_users ถูกบล็อก",
    "Firestore ig_users write failed.": "การเขียน Firestore ig_users ล้มเหลว",
    "User": "ผู้ใช้",
    "Opening consent form...": "กำลังเปิดแบบฟอร์มยินยอม...",
    "Your consent preference was updated.":
        "ค่ากำหนดความยินยอมของคุณได้รับการอัปเดตแล้ว",
    "Consent update failed. Please try again.":
        "การอัปเดตความยินยอมล้มเหลว โปรดลองอีกครั้ง",
    "Your account is blocked": "บัญชีของคุณถูกบล็อก",
    "Access is restricted for this account.":
        "การเข้าถึงถูกจำกัดสำหรับบัญชีนี้",
    "Starting purchase...": "กำลังเริ่มซื้อ...",
    "Purchase cancelled.": "ยกเลิกการซื้อแล้ว",
    "Premium active ✅ Ads and wait times are disabled.":
        "ใช้งานระดับพรีเมียม ✅ โฆษณาและเวลารอถูกปิดใช้งาน",
    "Purchase failed. Please try again.": "การซื้อล้มเหลว โปรดลองอีกครั้ง",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "จำเป็นต้องมีการตรวจสอบเซสชัน โปรดยืนยันบัญชีของคุณในแอป Instagram แล้วลองอีกครั้ง",
    "Instagram returned no data.": "Instagram ไม่ได้ส่งคืนข้อมูล",
    "Session verification failed. Please log in again.":
        "การยืนยันเซสชันล้มเหลว กรุณาเข้าสู่ระบบอีกครั้ง",
    "Open Instagram": "เปิดอินสตาแกรม",
    "Instagram message": "ข้อความอินสตาแกรม",
    "Loading stories...": "กำลังโหลดเรื่องราว...",
    "No data": "ไม่มีข้อมูล",
    "NEW": "ใหม่",
    "Login": "เข้าสู่ระบบ",
    "Session verified, redirecting...":
        "ยืนยันเซสชันแล้ว กำลังเปลี่ยนเส้นทาง...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "พื้นที่โฆษณา",
    "Admin mode active": "โหมดผู้ดูแลระบบใช้งานอยู่",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "เรากำลังพัฒนาทุกวันเพื่อมอบประสบการณ์ที่ดีกว่าให้กับคุณ ความคิดเห็นของคุณมีค่าสำหรับเรา เรายินดีรับฟังจากคุณ!",
    "Please log in to start the analysis.":
        "กรุณาเข้าสู่ระบบเพื่อเริ่มการวิเคราะห์",
    "Welcome, {username}": "ยินดีต้อนรับ {username}",
    "REFRESH DATA": "รีเฟรชข้อมูล",
    "LOG IN WITH INSTAGRAM": "เข้าสู่ระบบด้วยอินสตาแกรม",
    "Analyzing data...\nThis might take a moment.":
        "กำลังวิเคราะห์ข้อมูล...\nการดำเนินการนี้อาจใช้เวลาสักครู่",
    "Processing data...\nAlmost done.":
        "กำลังประมวลผลข้อมูล...\nเกือบเสร็จแล้ว",
    "Loading ad...\nPlease wait.": "กำลังโหลดโฆษณา...\nกรุณารอสักครู่.",
    "Google ad warning: {reason}": "คำเตือนโฆษณา Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "การวิเคราะห์ทั้งหมดได้รับการประมวลผลอย่างปลอดภัยบนอุปกรณ์ของคุณ",
    "Total analyses today: {count}": "การวิเคราะห์ทั้งหมดวันนี้: {count}",
    "Next analysis": "การวิเคราะห์ครั้งต่อไป",
    "Ready to scan.": "พร้อมสแกน.",
    "Analysis available now": "การวิเคราะห์ที่มีอยู่ในขณะนี้",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "การวิเคราะห์พร้อมใช้งานแล้ว แต่การดำเนินการวิเคราะห์ต่อเนื่องกันอาจทำให้บัญชีของคุณตกอยู่ในความเสี่ยง",
    "Please wait": "โปรดรอ",
    "Warning": "คำเตือน",
    "Next analysis: {time}": "การวิเคราะห์ถัดไป: {time}",
    "WATCH AD AND START ANALYSIS": "ดูโฆษณาและเริ่มการวิเคราะห์",
    "START ANALYSIS": "เริ่มการวิเคราะห์",
    "Start analysis?": "เริ่มการวิเคราะห์?",
    "Reset App Data": "รีเซ็ตข้อมูลแอพ",
    "This will wipe all local data and session cookies. Are you sure?":
        "การดำเนินการนี้จะล้างข้อมูลในเครื่องและคุกกี้เซสชันทั้งหมด คุณแน่ใจเหรอ?",
    "CANCEL": "ยกเลิก",
    "DELETE": "ลบ",
    "Error": "ข้อผิดพลาด",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "การเรียกข้อมูลล้มเหลว: {err}\n\nการแก้ไขปัญหา: ลองออกจากระบบแล้วเข้าสู่ระบบอีกครั้ง",
    "Followers": "ผู้ติดตาม",
    "Following": "กำลังติดตาม",
    "New Followers": "ผู้ติดตามใหม่",
    "Not Following Back": "ไม่ติดตามกลับ.",
    "Lost Followers": "ผู้ติดตามที่หายไป",
    "Legal Disclaimer": "ข้อสงวนสิทธิ์ทางกฎหมาย",
    "Unfollowed Users": "ผู้ใช้ที่เลิกติดตาม",
    "Rate Us": "ให้คะแนนเรา",
    "Contact Us": "ติดต่อเรา",
    "Remove Ads & Wait Times": "ลบโฆษณาและเวลารอ",
    "This box is currently under test.": "กล่องนี้อยู่ระหว่างการทดสอบ",
    "Watch Stories Secretly or Zoom Profile Photos":
        "ดูเรื่องราวอย่างลับๆ หรือ ซูมรูปโปรไฟล์",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "กรุณาเข้าสู่ระบบเพื่อดูเรื่องราวอย่างลับๆ และขยายรูปโปรไฟล์",
    "Will be shown after the ad, please wait.":
        "จะแสดงหลังโฆษณา กรุณารอสักครู่",
    "What would you like to do?": "คุณอยากจะทำอะไร?",
    "Enlarge profile photo": "ขยายรูปโปรไฟล์",
    "Watch story secretly": "ดูเรื่องราวอย่างลับๆ",
    "No story data available.": "ไม่มีข้อมูลเรื่องราว",
    "I HAVE READ AND AGREE": "ฉันได้อ่านและยอมรับแล้ว",
    "Withdraw Consent": "ถอนความยินยอม",
    "Confirm": "ยืนยัน",
    "Your consent settings will be reset. Are you sure?":
        "การตั้งค่าความยินยอมของคุณจะถูกรีเซ็ต คุณแน่ใจเหรอ?",
    "Yes": "ใช่",
    "Cancel": "ยกเลิก",
    "Session verified, redirecting securely...":
        "ยืนยันเซสชันแล้ว เปลี่ยนเส้นทางอย่างปลอดภัย...",
    "Analysis complete ✅": "วิเคราะห์เสร็จแล้ว ✅",
    "Purchases are not available right now. Please try again later.":
        "ไม่สามารถซื้อได้ในขณะนี้ โปรดลองอีกครั้งในภายหลัง",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "การซื้อเสร็จสมบูรณ์ แต่ Premium ยังไม่สามารถใช้งานได้ โปรดลองอีกครั้ง",
    "Welcome to Premium! Ads and wait times are removed.":
        "ยินดีต้อนรับสู่พรีเมี่ยม! โฆษณาและเวลารอจะถูกลบออก",
    "Your Premium membership is active.": "สมาชิกพรีเมี่ยมของคุณเปิดใช้งานอยู่",
    "Restore Purchases": "คืนค่าการซื้อ",
    "RESTORE": "คืนค่า",
    "Restoring purchases...": "กำลังคืนค่าการซื้อ...",
    "Purchases restored ✅": "การซื้อคืนแล้ว ✅",
    "No purchases to restore.": "ไม่มีการซื้อที่จะกู้คืน",
    "Restore failed: {err}": "การคืนค่าล้มเหลว: {err}",
    "Enter PIN": "ป้อนรหัส PIN",
    "PIN accepted, timer reset ✅": "ยอมรับ PIN แล้ว รีเซ็ตตัวจับเวลา ✅",
    "Invalid PIN": "PIN ไม่ถูกต้อง",
    "OK": "ตกลง",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "โดยการดาวน์โหลดและใช้งานแอปพลิเคชันนี้ จะถือว่าผู้ใช้ทุกคนได้อ่าน เข้าใจ และยอมรับข้อความ \"ข้อกำหนดการใช้งานและข้อจำกัดความรับผิดชอบ\" ด้านล่างนี้ล่วงหน้าอย่างไม่อาจเพิกถอนได้:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "บทความที่ 1: ความเป็นส่วนตัวของข้อมูลและสถาปัตยกรรมการประมวลผลในท้องถิ่น",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "คำตัดสินคือซอฟต์แวร์ 'ฝั่งไคลเอ็นต์' ข้อมูลรับรองการเข้าสู่ระบบของผู้ใช้ (ชื่อผู้ใช้ รหัสผ่าน คุกกี้เซสชัน) จะไม่ถูกส่งไปยังหรือเก็บไว้ในเซิร์ฟเวอร์ภายนอก กิจกรรมการประมวลผลข้อมูลทั้งหมดเกิดขึ้นเฉพาะภายในหน่วยความจำชั่วคราว (RAM) และที่เก็บข้อมูลในเครื่องของอุปกรณ์ของผู้ใช้ แอปพลิเคชั่นนี้ทำหน้าที่เป็น 'เครื่องห่อเบราว์เซอร์' ที่ทำงานผ่านอินเทอร์เฟซ Instagram",
    "Article 2: Third-Party Platform Risks":
        "บทความที่ 2: ความเสี่ยงของแพลตฟอร์มบุคคลที่สาม",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) ขอสงวนสิทธิ์ในการจำกัดการใช้ซอฟต์แวร์บุคคลที่สามตามนโยบายแพลตฟอร์ม ความเสี่ยงทั้งหมด รวมถึงแต่ไม่จำกัดเพียง 'บล็อกการดำเนินการ', 'ข้อจำกัดบัญชี', 'แบนเงา' หรือ 'การปิดบัญชี' ที่อาจเกิดขึ้นจากการใช้แอปพลิเคชัน เป็นของผู้ใช้แต่เพียงผู้เดียว ผู้พัฒนาคำตัดสินไม่สามารถรับผิดชอบต่อความเสียหายโดยตรงหรือโดยอ้อมอันเป็นผลมาจากการลงโทษทางปกครองดังกล่าว",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "บทความที่ 3: การปฏิเสธการรับประกันและข้อจำกัดความรับผิด",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "ซอฟต์แวร์นี้มีให้ 'ตามที่เป็น' และ 'ตามที่มีอยู่' ไม่รับประกันความถูกต้อง ความต่อเนื่อง หรือความสามารถเชิงพาณิชย์ 100% ของผลการวิเคราะห์ที่ได้รับจากซอฟต์แวร์ ผู้ใช้รับทราบว่าผลลัพธ์ใดๆ ที่เกิดขึ้นจากธุรกรรมทางกฎหมายหรือเชิงพาณิชย์ตามข้อมูลแอปพลิเคชันถือเป็นความรับผิดชอบของตนเอง และประกาศและรับรองว่าผู้พัฒนาจะไม่ได้รับอันตรายจากการเรียกร้อง การฟ้องร้อง และการร้องเรียนทั้งหมด",
    "Article 4: Intellectual Property and Independence Notice":
        "บทความ 4: ประกาศเกี่ยวกับทรัพย์สินทางปัญญาและความเป็นอิสระ",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "คำตัดสินเป็นโครงการนักพัฒนาอิสระ แบรนด์ 'Instagram', 'Facebook' และ 'Meta' เป็นเครื่องหมายการค้าจดทะเบียนของ Meta Platforms, Inc. แอปพลิเคชันนี้ไม่มีความร่วมมือทางการค้า ข้อตกลงการสนับสนุน หรือความร่วมมืออย่างเป็นทางการกับบริษัทดังกล่าว",
    "Article 5: Service Continuity and Platform Changes":
        "บทความที่ 5: ความต่อเนื่องของบริการและการเปลี่ยนแปลงแพลตฟอร์ม",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "การเปลี่ยนแปลงพื้นฐานของ Instagram API หรือโครงสร้างพื้นฐานของเว็บอาจทำให้แอปพลิเคชันสูญเสียฟังก์ชันการทำงานบางส่วนหรือทั้งหมด นักพัฒนาไม่มีข้อผูกมัดที่จะอัปเดตแอปพลิเคชันหรือบำรุงรักษาบริการเพื่อตอบสนองต่อการเปลี่ยนแปลงโครงสร้างพื้นฐานดังกล่าว ซึ่งถือเป็น \"เหตุสุดวิสัย\"",
    "Analysis complete, results will be shown after the ad.":
        "การวิเคราะห์เสร็จสมบูรณ์ ผลลัพธ์จะแสดงหลังโฆษณา",
    "Analysis failed": "การวิเคราะห์ล้มเหลว",
    "Reason: {reason}": "เหตุผล: {reason}",
    "Tip: Logging out and logging back in may help.":
        "เคล็ดลับ: การออกจากระบบและกลับเข้าสู่ระบบใหม่อาจช่วยได้",
    "Quick check: Counts are the same. No changes detected.":
        "ตรวจสอบด่วน: จำนวนเท่ากัน ไม่พบการเปลี่ยนแปลง",
    "Daily Metrics": "ตัวชี้วัดรายวัน",
    "Active users": "ผู้ใช้ที่ใช้งานอยู่",
    "Daily queries": "แบบสอบถามรายวัน",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "การโหลดข้อมูลถูกขัดจังหวะ: ข้อมูลผู้ติดตามไม่สมบูรณ์ ({fetched}/{total})",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "การโหลดข้อมูลถูกขัดจังหวะ: ข้อมูลต่อไปนี้ไม่สมบูรณ์ ({fetched}/{total})",
    "Data loading was interrupted: Instagram returned empty data.":
        "การโหลดข้อมูลถูกขัดจังหวะ: Instagram ส่งคืนข้อมูลเปล่า",
    "Data loading stopped due to an unexpected error.":
        "การโหลดข้อมูลหยุดลงเนื่องจากข้อผิดพลาดที่ไม่คาดคิด",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram ส่งคืนคำเตือนพฤติกรรมอัตโนมัติ เราหยุดดึงข้อมูลเพื่อความปลอดภัย",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram ขอการตรวจสอบความปลอดภัย ยืนยันในแอป Instagram แล้วลองอีกครั้ง",
    "Session is invalid or waiting for verification. Please log in again.":
        "เซสชันไม่ถูกต้องหรือกำลังรอการยืนยัน กรุณาเข้าสู่ระบบอีกครั้ง",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "มีการส่งคำขอมากเกินไป การโหลดข้อมูลถูกขัดจังหวะเพื่อความปลอดภัย",
    "Data loading could not complete due to a connection issue.":
        "ไม่สามารถโหลดข้อมูลได้สำเร็จเนื่องจากปัญหาการเชื่อมต่อ",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram ส่งคืนข้อผิดพลาด (HTTP {code}) การโหลดข้อมูลถูกขัดจังหวะ",
    "Instagram security verification is required (story data could not be fetched).":
        "จำเป็นต้องมีการตรวจสอบความปลอดภัยของ Instagram (ไม่สามารถดึงข้อมูลเรื่องราวได้)",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "ไม่สามารถดึงข้อมูลเรื่องราวได้ โดยปกติจะเกิดจากการยืนยัน Instagram, ข้อจำกัด API ชั่วคราว หรือการหยุดชะงักของการเชื่อมต่อ โปรดลองอีกครั้งในอีก 2-3 นาที",
    "Could not fetch story data. Please try again shortly.":
        "ไม่สามารถดึงข้อมูลเรื่องราวได้ โปรดลองอีกครั้งในอีกสักครู่",
    "Secret Mode": "โหมดลับ",
    "Starting VERDICT...": "กำลังเริ่มคำตัดสิน...",
    "DID YOU KNOW?": "คุณรู้หรือไม่?",
    "Estimated time left: {time}": "เวลาที่เหลือโดยประมาณ: {time}",
    "Estimating remaining time...": "กำลังประมาณเวลาที่เหลืออยู่...",
    "LOG OUT": "ออกจากระบบ",
    "Open Profile": "เปิดโปรไฟล์",
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
    "Analysis Time!": "Czas analizy!",
    "CLOSE": "ZAMKNĄĆ",
    "SYSTEM UNDER MAINTENANCE": "SYSTEM W KONSERWACJI",
    "Bio Planner": "Bioplanista",
    "Store link not set.": "Link do sklepu nie został ustawiony.",
    "Invalid store link.": "Nieprawidłowy link do sklepu.",
    "Could not open the link.": "Nie można otworzyć linku.",
    "Please try again.": "Spróbuj ponownie.",
    "Show error": "Pokaż błąd",
    "Exception": "Wyjątek",
    "Load error": "Błąd ładowania",
    "Code": "Kod",
    "Timeout": "Limit czasu",
    "REST probe failed: missing auth.":
        "Sonda REST nie powiodła się: brak autoryzacji.",
    "REST probe success (Firestore endpoint reachable).":
        "Próba REST powiodła się (osiągalny punkt końcowy Firestore).",
    "REST probe failed (check logs).":
        "Sonda REST nie powiodła się (sprawdź dzienniki).",
    "Firebase Auth probe failed.":
        "Próba uwierzytelnienia Firebase nie powiodła się.",
    "Firebase Auth probe success.":
        "Próba uwierzytelnienia Firebase zakończyła się sukcesem.",
    "Firebase token probe failed.": "Sonda tokena Firebase nie powiodła się.",
    "CRITICAL DIAGNOSTIC ERROR": "KRYTYCZNY BŁĄD DIAGNOSTYCZNY",
    "COPY": "KOPIA",
    "OPEN LOGS": "OTWÓRZ DZIENNIKI",
    "Firebase": "Baza ogniowa",
    "Store": "Sklep",
    "Copy all": "Skopiuj wszystko",
    "Close": "Zamknąć",
    "Auth Probe": "Sonda uwierzytelniająca",
    "Write Test": "Napisz test",
    "REST Probe": "Sonda REST",
    "Restore Test": "Test przywracania",
    "Firebase auth error: user verification failed.":
        "Błąd autoryzacji Firebase: weryfikacja użytkownika nie powiodła się.",
    "Firestore test write successful.": "Zapis testowy Firestore powiódł się.",
    "Firestore test failed.": "Test Firestore nie powiódł się.",
    "Firestore auth error: user verification failed.":
        "Błąd autoryzacji Firestore: weryfikacja użytkownika nie powiodła się.",
    "Firestore counter write failed.":
        "Zapisanie licznika Firestore nie powiodło się.",
    "Firestore auth missing: ig_users write blocked.":
        "Brak autoryzacji Firestore: zapis ig_users zablokowany.",
    "Firestore ig_users write failed.":
        "Zapis ig_users Firestore nie powiódł się.",
    "User": "Użytkownik",
    "Opening consent form...": "Otwieram formularz zgody...",
    "Your consent preference was updated.":
        "Twoje preferencje dotyczące zgody zostały zaktualizowane.",
    "Consent update failed. Please try again.":
        "Aktualizacja zgody nie powiodła się. Spróbuj ponownie.",
    "Your account is blocked": "Twoje konto jest zablokowane",
    "Access is restricted for this account.":
        "Dostęp do tego konta jest ograniczony.",
    "Starting purchase...": "Rozpoczęcie zakupu...",
    "Purchase cancelled.": "Zakup anulowany.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktywny ✅ Reklamy i czasy oczekiwania są wyłączone.",
    "Purchase failed. Please try again.":
        "Zakup nie powiódł się. Spróbuj ponownie.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Wymagana jest weryfikacja sesji. Zweryfikuj swoje konto w aplikacji Instagram i spróbuj ponownie.",
    "Instagram returned no data.": "Instagram nie zwrócił żadnych danych.",
    "Session verification failed. Please log in again.":
        "Weryfikacja sesji nie powiodła się. Proszę zalogować się ponownie.",
    "Open Instagram": "Otwórz Instagrama",
    "Instagram message": "Wiadomość na Instagramie",
    "Loading stories...": "Ładowanie historii...",
    "No data": "Brak danych",
    "NEW": "NOWY",
    "Login": "Login",
    "Session verified, redirecting...":
        "Sesja zweryfikowana, przekierowanie...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "PRZESTRZEŃ REKLAMOWA",
    "Admin mode active": "Tryb administratora aktywny",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Każdego dnia rozwijamy się, aby zapewnić Ci lepsze doświadczenia. Twoja opinia jest dla nas cenna — chętnie ją poznamy!",
    "Please log in to start the analysis.":
        "Aby rozpocząć analizę, zaloguj się.",
    "Welcome, {username}": "Witamy, {username}",
    "REFRESH DATA": "ODŚWIEŻ DANE",
    "LOG IN WITH INSTAGRAM": "ZALOGUJ SIĘ NA INSTAGRAMIE",
    "Analyzing data...\nThis might take a moment.":
        "Analizowanie danych...\nTo może chwilę potrwać.",
    "Processing data...\nAlmost done.":
        "Przetwarzanie danych...\nPrawie gotowe.",
    "Loading ad...\nPlease wait.": "Ładowanie reklamy...\nProszę czekać.",
    "Google ad warning: {reason}":
        "Ostrzeżenie dotyczące reklamy Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Wszystkie analizy są bezpiecznie przetwarzane lokalnie na Twoim urządzeniu.",
    "Total analyses today: {count}": "Wszystkie dzisiejsze analizy: {count}",
    "Next analysis": "Następna analiza",
    "Ready to scan.": "Gotowy do skanowania.",
    "Analysis available now": "Analiza dostępna już teraz",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analiza jest już dostępna, ale powtarzanie analiz może narazić Twoje konto na ryzyko.",
    "Please wait": "Proszę czekać",
    "Warning": "Ostrzeżenie",
    "Next analysis: {time}": "Następna analiza: {time}",
    "WATCH AD AND START ANALYSIS": "OBEJRZYJ REKLAMĘ I ROZPOCZNIJ ANALIZĘ",
    "START ANALYSIS": "ROZPOCZNIJ ANALIZĘ",
    "Start analysis?": "Rozpocząć analizę?",
    "Reset App Data": "Zresetuj dane aplikacji",
    "This will wipe all local data and session cookies. Are you sure?":
        "Spowoduje to wyczyszczenie wszystkich danych lokalnych i plików cookie sesji. Czy jesteś pewien?",
    "CANCEL": "ANULOWAĆ",
    "DELETE": "USUWAĆ",
    "Error": "Błąd",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Pobieranie danych nie powiodło się: {err}\n\nRozwiązywanie problemów: spróbuj się wylogować i zalogować ponownie.",
    "Followers": "Świta",
    "Following": "Następny",
    "New Followers": "Nowi obserwujący",
    "Not Following Back": "Nie podążanie wstecz",
    "Lost Followers": "Utraceni obserwujący",
    "Legal Disclaimer": "Zastrzeżenie prawne",
    "Unfollowed Users": "Nieobserwowani użytkownicy",
    "Rate Us": "Oceń nas",
    "Contact Us": "Skontaktuj się z nami",
    "Remove Ads & Wait Times": "Usuń reklamy i czas oczekiwania",
    "This box is currently under test.":
        "To pudełko jest obecnie w fazie testów.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Oglądaj historie w tajemnicy lub powiększaj zdjęcia profilowe",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Zaloguj się, aby oglądać historie w tajemnicy i powiększać zdjęcia profilowe.",
    "Will be shown after the ad, please wait.":
        "Wyświetli się po reklamie, proszę czekać.",
    "What would you like to do?": "Co chciałbyś zrobić?",
    "Enlarge profile photo": "Powiększ zdjęcie profilowe",
    "Watch story secretly": "Oglądaj historię w tajemnicy",
    "No story data available.": "Brak dostępnych danych historii.",
    "I HAVE READ AND AGREE": "PRZECZYTAŁEM I ZGADZAM SIĘ",
    "Withdraw Consent": "Wycofaj zgodę",
    "Confirm": "Potwierdzać",
    "Your consent settings will be reset. Are you sure?":
        "Ustawienia Twojej zgody zostaną zresetowane. Czy jesteś pewien?",
    "Yes": "Tak",
    "Cancel": "Anulować",
    "Session verified, redirecting securely...":
        "Sesja zweryfikowana, przekierowanie bezpieczne...",
    "Analysis complete ✅": "Analiza zakończona ✅",
    "Purchases are not available right now. Please try again later.":
        "Zakupy nie są obecnie dostępne. Spróbuj ponownie później.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Zakup został sfinalizowany, ale Premium nie jest jeszcze aktywny. Spróbuj ponownie.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Witamy w Premium! Reklamy i czasy oczekiwania zostały usunięte.",
    "Your Premium membership is active.":
        "Twoje członkostwo Premium jest aktywne.",
    "Restore Purchases": "Przywróć zakupy",
    "RESTORE": "PRZYWRÓCIĆ",
    "Restoring purchases...": "Przywracam zakupy...",
    "Purchases restored ✅": "Zakupy przywrócone ✅",
    "No purchases to restore.": "Brak zakupów do przywrócenia.",
    "Restore failed: {err}": "Przywracanie nie powiodło się: {err}",
    "Enter PIN": "Wprowadź PIN",
    "PIN accepted, timer reset ✅": "PIN zaakceptowany, reset timera ✅",
    "Invalid PIN": "Nieprawidłowy kod PIN",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Uznaje się, że pobierając i korzystając z tej aplikacji, każdy Użytkownik z wyprzedzeniem przeczytał, zrozumiał i nieodwołalnie zaakceptował poniższy tekst „Warunków użytkowania i zastrzeżenia”:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artykuł 1: Prywatność danych i architektura lokalnego przetwarzania",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT to oprogramowanie działające po stronie klienta. Dane logowania Użytkownika (nazwa użytkownika, hasło, pliki cookie sesji) w żadnym wypadku nie są przesyłane ani przechowywane na serwerze zewnętrznym. Wszelkie czynności związane z przetwarzaniem danych odbywają się wyłącznie w obrębie pamięci tymczasowej (RAM) i pamięci lokalnej urządzenia Użytkownika. Aplikacja pełni funkcję „opakowania przeglądarki” działającego poprzez interfejs Instagrama.",
    "Article 2: Third-Party Platform Risks":
        "Artykuł 2: Ryzyko związane z platformami stron trzecich",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) zastrzega sobie prawo do ograniczenia korzystania z oprogramowania stron trzecich zgodnie z zasadami swojej platformy. Wszelkie ryzyko, w tym między innymi „blokady działań”, „ograniczenia konta”, „blokady cieni” lub „zamknięcie kont”, które mogą wyniknąć w wyniku korzystania z aplikacji, należą wyłącznie do Użytkownika. Deweloper VERDICT nie ponosi odpowiedzialności za jakiekolwiek bezpośrednie lub pośrednie szkody wynikające z takich sankcji administracyjnych.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artykuł 3: Wyłączenie gwarancji i ograniczenie odpowiedzialności",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "To oprogramowanie jest dostarczane w stanie „takim, w jakim jest” i „w miarę dostępności”. Nie gwarantuje się 100% dokładności, ciągłości ani przydatności handlowej wyników analiz dostarczonych przez oprogramowanie. Użytkownik przyjmuje do wiadomości, że za wszelkie skutki wynikające z transakcji prawnych lub handlowych opartych na danych aplikacji odpowiada na własną odpowiedzialność; oraz oświadcza i zobowiązuje się chronić dewelopera przed wszelkimi roszczeniami, procesami sądowymi i reklamacjami.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artykuł 4: Informacja o własności intelektualnej i niezależności",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT jest niezależnym projektem deweloperskim. Marki „Instagram”, „Facebook” i „Meta” są zastrzeżonymi znakami towarowymi firmy Meta Platforms, Inc. Ta aplikacja nie ma partnerstwa handlowego, umowy sponsorskiej ani oficjalnego powiązania z wyżej wymienionymi firmami.",
    "Article 5: Service Continuity and Platform Changes":
        "Artykuł 5: Ciągłość świadczenia usług i zmiany platformy",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Zasadnicze zmiany w API Instagrama lub infrastrukturze sieciowej mogą spowodować, że aplikacja częściowo lub całkowicie utraci swoją funkcjonalność. Deweloper nie zobowiązuje się do aktualizacji aplikacji lub utrzymywania usługi w odpowiedzi na takie zmiany infrastrukturalne, które są uznawane za „siłę wyższą”.",
    "Analysis complete, results will be shown after the ad.":
        "Analiza zakończona, wyniki zostaną wyświetlone po ogłoszeniu.",
    "Analysis failed": "Analiza nie powiodła się",
    "Reason: {reason}": "Powód: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Wskazówka: pomocne może być wylogowanie się i ponowne zalogowanie.",
    "Quick check: Counts are the same. No changes detected.":
        "Szybkie sprawdzenie: liczby są takie same. Nie wykryto żadnych zmian.",
    "Daily Metrics": "Dane dzienne",
    "Active users": "Aktywni użytkownicy",
    "Daily queries": "Codzienne zapytania",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Ładowanie danych zostało przerwane: dane obserwującego są niekompletne ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Ładowanie danych zostało przerwane: następujące dane są niekompletne ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Ładowanie danych zostało przerwane: Instagram zwrócił puste dane.",
    "Data loading stopped due to an unexpected error.":
        "Ładowanie danych zostało zatrzymane z powodu nieoczekiwanego błędu.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram zwrócił ostrzeżenie o automatycznym zachowaniu. Ze względów bezpieczeństwa przestaliśmy pobierać dane.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram zażądał weryfikacji bezpieczeństwa. Sprawdź w aplikacji Instagram i spróbuj ponownie.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sesja jest nieprawidłowa lub oczekuje na weryfikację. Proszę zalogować się ponownie.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Wysłano zbyt wiele żądań. Ładowanie danych zostało przerwane ze względów bezpieczeństwa.",
    "Data loading could not complete due to a connection issue.":
        "Ładowanie danych nie mogło zostać ukończone z powodu problemu z połączeniem.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram zwrócił błąd (HTTP {code}). Ładowanie danych zostało przerwane.",
    "Instagram security verification is required (story data could not be fetched).":
        "Wymagana jest weryfikacja bezpieczeństwa na Instagramie (nie udało się pobrać danych historii).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Nie udało się pobrać danych historii. Zwykle jest to spowodowane weryfikacją na Instagramie, tymczasowymi ograniczeniami API lub przerwą w połączeniu. Spróbuj ponownie za 2–3 minuty.",
    "Could not fetch story data. Please try again shortly.":
        "Nie udało się pobrać danych historii. Spróbuj ponownie wkrótce.",
    "Secret Mode": "Tryb tajny",
    "Starting VERDICT...": "Rozpoczęcie WERDYKTU...",
    "DID YOU KNOW?": "CZY WIESZ?",
    "Estimated time left: {time}": "Szacowany pozostały czas: {time}",
    "Estimating remaining time...": "Szacowanie pozostałego czasu...",
    "LOG OUT": "WYLOGUJ SIĘ",
    "Open Profile": "Otwórz profil",
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
    "Analysis Time!": "Temps d'anàlisi!",
    "CLOSE": "TANCAR",
    "SYSTEM UNDER MAINTENANCE": "SISTEMA EN MANTENIMENT",
    "Bio Planner": "Bio Planificador",
    "Store link not set.": "No s'ha definit l'enllaç de la botiga.",
    "Invalid store link.": "Enllaç a la botiga no vàlid.",
    "Could not open the link.": "No s'ha pogut obrir l'enllaç.",
    "Please try again.": "Si us plau, torna-ho a provar.",
    "Show error": "Mostra l'error",
    "Exception": "Excepció",
    "Load error": "Error de càrrega",
    "Code": "Codi",
    "Timeout": "Temps mort",
    "REST probe failed: missing auth.":
        "La sonda REST ha fallat: falta l'autenticació.",
    "REST probe success (Firestore endpoint reachable).":
        "Sonda REST correcta (punt final de Firestore accessible).",
    "REST probe failed (check logs).":
        "La sonda REST ha fallat (comproveu els registres).",
    "Firebase Auth probe failed.":
        "La sonda d'autenticació de Firebase ha fallat.",
    "Firebase Auth probe success.":
        "La sonda d'autenticació de Firebase ha estat correcta.",
    "Firebase token probe failed.":
        "La sonda de testimoni de Firebase ha fallat.",
    "CRITICAL DIAGNOSTIC ERROR": "ERROR CRÍTIC DE DIAGNÒSTIC",
    "COPY": "CÒPIA",
    "OPEN LOGS": "REGISTRES OBERTS",
    "Firebase": "Firebase",
    "Store": "Botiga",
    "Copy all": "Copia-ho tot",
    "Close": "Tancar",
    "Auth Probe": "Sonda d'autenticació",
    "Write Test": "Test d'escriptura",
    "REST Probe": "Sonda REST",
    "Restore Test": "Prova de restauració",
    "Firebase auth error: user verification failed.":
        "Error d'autenticació de Firebase: la verificació de l'usuari ha fallat.",
    "Firestore test write successful.":
        "Escriptura de la prova de Firestore correcta.",
    "Firestore test failed.": "La prova de Firestore ha fallat.",
    "Firestore auth error: user verification failed.":
        "Error d'autenticació de Firestore: la verificació de l'usuari ha fallat.",
    "Firestore counter write failed.":
        "Ha fallat l'escriptura del comptador de Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Falta l'autenticació de Firestore: ig_users escriptura bloquejada.",
    "Firestore ig_users write failed.":
        "Error d'escriptura de Firestore ig_users.",
    "User": "Usuari",
    "Opening consent form...": "Obertura del formulari de consentiment...",
    "Your consent preference was updated.":
        "La teva preferència de consentiment s'ha actualitzat.",
    "Consent update failed. Please try again.":
        "No s'ha pogut actualitzar el consentiment. Si us plau, torna-ho a provar.",
    "Your account is blocked": "El teu compte està bloquejat",
    "Access is restricted for this account.":
        "L'accés està restringit per a aquest compte.",
    "Starting purchase...": "S'està començant a comprar...",
    "Purchase cancelled.": "Compra cancel·lada.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium activa ✅ Els anuncis i els temps d'espera estan desactivats.",
    "Purchase failed. Please try again.":
        "La compra ha fallat. Si us plau, torna-ho a provar.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "La verificació de la sessió és necessària. Verifiqueu el vostre compte a l'aplicació d'Instagram i torneu-ho a provar.",
    "Instagram returned no data.": "Instagram no ha retornat cap dada.",
    "Session verification failed. Please log in again.":
        "La verificació de la sessió ha fallat. Si us plau, torneu a iniciar sessió.",
    "Open Instagram": "Obre Instagram",
    "Instagram message": "Missatge d'Instagram",
    "Loading stories...": "S'estan carregant històries...",
    "No data": "Sense dades",
    "NEW": "NOU",
    "Login": "Inicieu sessió",
    "Session verified, redirecting...": "Sessió verificada, redirecció...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ESPAI ANUNCI",
    "Admin mode active": "Mode administrador actiu",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Estem evolucionant cada dia per oferir-te una millor experiència. Els vostres comentaris són valuosos per a nosaltres; ens agradaria molt saber de vosaltres!",
    "Please log in to start the analysis.":
        "Inicieu sessió per iniciar l'anàlisi.",
    "Welcome, {username}": "Benvingut, {username}",
    "REFRESH DATA": "ACTUALITZAR DADES",
    "LOG IN WITH INSTAGRAM": "INICIA SESIÓ AMB INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "S'estan analitzant dades...\nAixò pot trigar un moment.",
    "Processing data...\nAlmost done.":
        "Processament de dades...\nGairebé fet.",
    "Loading ad...\nPlease wait.":
        "S'està carregant l'anunci...\nSi us plau, espereu.",
    "Google ad warning: {reason}": "Advertiment d'anunci de Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Totes les anàlisis es processen de manera segura localment al vostre dispositiu.",
    "Total analyses today: {count}": "Total d'anàlisis avui: {count}",
    "Next analysis": "Següent anàlisi",
    "Ready to scan.": "A punt per escanejar.",
    "Analysis available now": "Anàlisi disponible ara",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "L'anàlisi està disponible ara, però l'execució d'anàlisis adossades pot posar en perill el vostre compte.",
    "Please wait": "Si us plau, espereu",
    "Warning": "Avís",
    "Next analysis: {time}": "Següent anàlisi: {time}",
    "WATCH AD AND START ANALYSIS": "MIREU L'ANUNCI I COMENÇA L'ANÀLISI",
    "START ANALYSIS": "INICI ANÀLISI",
    "Start analysis?": "Començar l'anàlisi?",
    "Reset App Data": "Restableix les dades de l'aplicació",
    "This will wipe all local data and session cookies. Are you sure?":
        "Això esborrarà totes les dades locals i les galetes de sessió. N'estàs segur?",
    "CANCEL": "CANCEL·LA",
    "DELETE": "ELIMINAR",
    "Error": "Error",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "La recuperació de dades ha fallat: {err}\n\nSolució de problemes: proveu de tancar la sessió i tornar-la a iniciar.",
    "Followers": "Seguidors",
    "Following": "Seguint",
    "New Followers": "Nous Seguidors",
    "Not Following Back": "No seguir enrere",
    "Lost Followers": "Seguidors perduts",
    "Legal Disclaimer": "Avís legal",
    "Unfollowed Users": "Usuaris no seguits",
    "Rate Us": "Valora'ns",
    "Contact Us": "Contacta amb nosaltres",
    "Remove Ads & Wait Times": "Elimina anuncis i temps d'espera",
    "This box is currently under test.":
        "Aquesta caixa està actualment en prova.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Mira les històries en secret o amplia les fotos de perfil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Si us plau, inicieu sessió per veure històries en secret i ampliar les fotos de perfil.",
    "Will be shown after the ad, please wait.":
        "Es mostrarà després de l'anunci, espereu.",
    "What would you like to do?": "Què t'agradaria fer?",
    "Enlarge profile photo": "Amplia la foto de perfil",
    "Watch story secretly": "Mira la història en secret",
    "No story data available.": "No hi ha dades de la història disponibles.",
    "I HAVE READ AND AGREE": "HO HE LLEGIT I ESTIC D'ACORD",
    "Withdraw Consent": "Retirar el consentiment",
    "Confirm": "Confirmeu",
    "Your consent settings will be reset. Are you sure?":
        "La configuració del teu consentiment es restablirà. N'estàs segur?",
    "Yes": "Sí",
    "Cancel": "Cancel·la",
    "Session verified, redirecting securely...":
        "Sessió verificada, redirigint de manera segura...",
    "Analysis complete ✅": "Anàlisi completa ✅",
    "Purchases are not available right now. Please try again later.":
        "Les compres no estan disponibles ara mateix. Si us plau, torna-ho a provar més tard.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "La compra s'ha completat, però Premium encara no està activa. Si us plau, torna-ho a provar.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Benvingut a Premium! S'eliminen els anuncis i els temps d'espera.",
    "Your Premium membership is active.":
        "La teva subscripció Premium està activa.",
    "Restore Purchases": "Restaurar les compres",
    "RESTORE": "RESTAURAR",
    "Restoring purchases...": "S'estan restaurant les compres...",
    "Purchases restored ✅": "Compres restaurades ✅",
    "No purchases to restore.": "No hi ha compres per restaurar.",
    "Restore failed: {err}": "La restauració ha fallat: {err}",
    "Enter PIN": "Introduïu el PIN",
    "PIN accepted, timer reset ✅":
        "PIN acceptat, restabliment del temporitzador ✅",
    "Invalid PIN": "PIN no vàlid",
    "OK": "D'acord",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "En baixar i utilitzar aquesta aplicació, es considera que cada Usuari ha llegit, entès i acceptat de manera irrevocable el text \"Condicions d'ús i exempció de responsabilitat\" a continuació per endavant:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Article 1: Privadesa de dades i Arquitectura Local de Tractament",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT és un programari \"del costat del client\". Les credencials d'inici de sessió de l'Usuari (nom d'usuari, contrasenya, galetes de sessió) no es transmeten ni s'emmagatzemen en cap cas a un servidor extern. Totes les activitats de tractament de dades tenen lloc exclusivament dins de la memòria temporal (RAM) i l'emmagatzematge local del dispositiu de l'Usuari. L'aplicació funciona com un \"embolcall de navegador\" que opera a través de la interfície d'Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Article 2: Riscos de la plataforma de tercers",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) es reserva el dret de restringir l'ús de programari de tercers segons les seves polítiques de plataforma. Tots els riscos, inclosos, entre d'altres, els \"bloqueigs d'acció\", les \"restriccions de comptes\", els \"bancaments d'ombra\" o els \"tancaments de comptes\" que es puguin derivar de l'ús de l'aplicació, pertanyen exclusivament a l'usuari. El desenvolupador VERDICT no es fa responsable dels danys directes o indirectes derivats d'aquestes sancions administratives.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Article 3: Exempció de garantia i limitació de responsabilitat",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Aquest programari es proporciona \"COM ESTÀ\" i \"COM DISPONIBLE\". No es garanteix el 100% de precisió, continuïtat o comercialització dels resultats de l'anàlisi proporcionats pel programari. L'Usuari reconeix que qualsevol resultat derivat de transaccions legals o comercials basades en dades de l'aplicació és de la seva pròpia responsabilitat; i declara i es compromet a mantenir indemne el desenvolupador de totes les reclamacions, demandes i queixes.",
    "Article 4: Intellectual Property and Independence Notice":
        "Article 4: Avís de propietat intel·lectual i independència",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT és un projecte de desenvolupament independent. Les marques \"Instagram\", \"Facebook\" i \"Meta\" són marques registrades de Meta Platforms, Inc. Aquesta aplicació no té cap associació comercial, acord de patrocini o afiliació oficial amb les empreses esmentades anteriorment.",
    "Article 5: Service Continuity and Platform Changes":
        "Article 5: Continuïtat del servei i canvis de plataforma",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Els canvis fonamentals a l'API d'Instagram o a la infraestructura web poden fer que l'aplicació perdi la seva funcionalitat parcial o completament. El desenvolupador no es compromet a actualitzar l'aplicació o mantenir el servei en resposta a aquests canvis d'infraestructura, que es consideren \"força major\".",
    "Analysis complete, results will be shown after the ad.":
        "Anàlisi completa, els resultats es mostraran després de l'anunci.",
    "Analysis failed": "L'anàlisi ha fallat",
    "Reason: {reason}": "Motiu: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Consell: tancar la sessió i tornar a iniciar sessió pot ajudar.",
    "Quick check: Counts are the same. No changes detected.":
        "Comprovació ràpida: els recomptes són els mateixos. No s'han detectat canvis.",
    "Daily Metrics": "Mètriques diàries",
    "Active users": "Usuaris actius",
    "Daily queries": "Consultes diàries",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "La càrrega de dades s'ha interromput: dades de seguidors incompletes ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "La càrrega de dades s'ha interromput: dades següents incompletes ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "La càrrega de dades s'ha interromput: Instagram ha retornat dades buides.",
    "Data loading stopped due to an unexpected error.":
        "La càrrega de dades s'ha aturat a causa d'un error inesperat.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram va tornar un avís de comportament automatitzat. Hem deixat d'obtenir dades per seguretat.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram ha sol·licitat una verificació de seguretat. Verifiqueu-ho a l'aplicació d'Instagram i torneu-ho a provar.",
    "Session is invalid or waiting for verification. Please log in again.":
        "La sessió no és vàlida o està pendent de verificació. Si us plau, torneu a iniciar sessió.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "S'han enviat massa peticions. La càrrega de dades s'ha interromput per seguretat.",
    "Data loading could not complete due to a connection issue.":
        "La càrrega de dades no s'ha pogut completar a causa d'un problema de connexió.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram ha retornat un error (HTTP {code}). La càrrega de dades s'ha interromput.",
    "Instagram security verification is required (story data could not be fetched).":
        "La verificació de seguretat d'Instagram és necessària (no s'han pogut obtenir les dades de la història).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "No s'han pogut obtenir les dades de la història. Normalment això és causat per la verificació d'Instagram, restriccions temporals de l'API o una interrupció de la connexió. Si us plau, torna-ho a provar d'aquí a 2 o 3 minuts.",
    "Could not fetch story data. Please try again shortly.":
        "No s'han pogut obtenir les dades de la història. Si us plau, torna-ho a provar en breu.",
    "Secret Mode": "Mode secret",
    "Starting VERDICT...": "Comença el VEREDICTE...",
    "DID YOU KNOW?": "HO SABIES?",
    "Estimated time left: {time}": "Temps estimat restant: {time}",
    "Estimating remaining time...": "S'està estimant el temps restant...",
    "LOG OUT": "Tanca la sessió",
    "Open Profile": "Obre el perfil",
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
    "Analysis Time!": "分析時間！",
    "CLOSE": "關閉",
    "SYSTEM UNDER MAINTENANCE": "系統維​​護中",
    "Bio Planner": "生物規劃師",
    "Store link not set.": "未設定商店連結。",
    "Invalid store link.": "商店連結無效。",
    "Could not open the link.": "無法開啟連結。",
    "Please try again.": "請再試一次。",
    "Show error": "顯示錯誤",
    "Exception": "例外",
    "Load error": "負載錯誤",
    "Code": "程式碼",
    "Timeout": "暫停",
    "REST probe failed: missing auth.": "REST 探測失敗：缺少身份驗證。",
    "REST probe success (Firestore endpoint reachable).":
        "REST 探測成功（Firestore 端點可存取）。",
    "REST probe failed (check logs).": "REST 探測失敗（檢查日誌）。",
    "Firebase Auth probe failed.": "Firebase 身份驗證探測失敗。",
    "Firebase Auth probe success.": "Firebase 身份驗證探測成功。",
    "Firebase token probe failed.": "Firebase 令牌探測失敗。",
    "CRITICAL DIAGNOSTIC ERROR": "嚴重診斷錯誤",
    "COPY": "複製",
    "OPEN LOGS": "打開日誌",
    "Firebase": "火力基地",
    "Store": "店鋪",
    "Copy all": "全部複製",
    "Close": "關閉",
    "Auth Probe": "驗證探針",
    "Write Test": "編寫測試",
    "REST Probe": "休息探針",
    "Restore Test": "恢復測試",
    "Firebase auth error: user verification failed.":
        "Firebase 身份驗證錯誤：使用者驗證失敗。",
    "Firestore test write successful.": "Firestore 測試寫入成功。",
    "Firestore test failed.": "Firestore 測試失敗。",
    "Firestore auth error: user verification failed.":
        "Firestore 驗證錯誤：使用者驗證失敗。",
    "Firestore counter write failed.": "Firestore 計數器寫入失敗。",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore 驗證遺失：ig_users 寫入被封鎖。",
    "Firestore ig_users write failed.": "Firestore ig_users 寫入失敗。",
    "User": "使用者",
    "Opening consent form...": "打開同意書...",
    "Your consent preference was updated.": "您的同意偏好已更新。",
    "Consent update failed. Please try again.": "同意更新失敗。請再試一次。",
    "Your account is blocked": "您的帳戶已被封鎖",
    "Access is restricted for this account.": "此帳戶的存取受到限制。",
    "Starting purchase...": "開始購買...",
    "Purchase cancelled.": "購買已取消。",
    "Premium active ✅ Ads and wait times are disabled.": "高級活動 ✅ 廣告和等待時間被禁用。",
    "Purchase failed. Please try again.": "購買失敗。請再試一次。",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "需要會話驗證。請在 Instagram 應用程式中驗證您的帳戶，然後重試。",
    "Instagram returned no data.": "Instagram 沒有回任何數據。",
    "Session verification failed. Please log in again.": "會話驗證失敗。請重新登入。",
    "Open Instagram": "開啟 Instagram",
    "Instagram message": "Instagram 訊息",
    "Loading stories...": "正在加載故事...",
    "No data": "無數據",
    "NEW": "新的",
    "Login": "登入",
    "Session verified, redirecting...": "會話已驗證，正在重定向...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "廣告空間",
    "Admin mode active": "管理模式已激活",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "我們每天都在不斷發展，為您提供更好的體驗。您的回饋對我們很有價值—我們很樂意聽取您的意見！",
    "Please log in to start the analysis.": "請登入以開始分析。",
    "Welcome, {username}": "歡迎，{username}",
    "REFRESH DATA": "重新整理數據",
    "LOG IN WITH INSTAGRAM": "使用 Instagram 登入",
    "Analyzing data...\nThis might take a moment.": "正在分析數據...\n這可能需要一些時間。",
    "Processing data...\nAlmost done.": "處理數據...\n快完成了。",
    "Loading ad...\nPlease wait.": "正在加載廣告...\n請稍候。",
    "Google ad warning: {reason}": "Google 廣告警告：{reason}",
    "All analysis is securely processed locally on your device.":
        "所有分析均在您的裝置上進行本機安全處理。",
    "Total analyses today: {count}": "今日總分析：{count}",
    "Next analysis": "接下來分析",
    "Ready to scan.": "準備掃描。",
    "Analysis available now": "現已提供分析",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "分析現已可用，但連續運行分析可能會使您的帳戶面臨風險。",
    "Please wait": "請稍等",
    "Warning": "警告",
    "Next analysis: {time}": "接下來分析：{time}",
    "WATCH AD AND START ANALYSIS": "觀看廣告並開始分析",
    "START ANALYSIS": "開始分析",
    "Start analysis?": "開始分析？",
    "Reset App Data": "重置應用程式數據",
    "This will wipe all local data and session cookies. Are you sure?":
        "這將擦除所有本機資料和會話 cookie。你確定嗎？",
    "CANCEL": "取消",
    "DELETE": "刪除",
    "Error": "錯誤",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "資料檢索失敗：{err}\n\n故障排除：嘗試登出並重新登入。",
    "Followers": "追隨者",
    "Following": "下列的",
    "New Followers": "新追蹤者",
    "Not Following Back": "不跟進",
    "Lost Followers": "失去的追隨者",
    "Legal Disclaimer": "法律免責聲明",
    "Unfollowed Users": "取消追蹤的用戶",
    "Rate Us": "評價我們",
    "Contact Us": "聯絡我們",
    "Remove Ads & Wait Times": "刪除廣告和等待時間",
    "This box is currently under test.": "該盒子目前正在測試中。",
    "Watch Stories Secretly or Zoom Profile Photos": "秘密觀看故事或縮放個人資料照片",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "請登入後偷偷觀看故事並放大頭像。",
    "Will be shown after the ad, please wait.": "會在廣告後顯示，請稍候。",
    "What would you like to do?": "你想做什麼？",
    "Enlarge profile photo": "放大個人資料照片",
    "Watch story secretly": "偷偷看故事",
    "No story data available.": "沒有可用的故事數據。",
    "I HAVE READ AND AGREE": "我已閱讀並同意",
    "Withdraw Consent": "撤回同意",
    "Confirm": "確認",
    "Your consent settings will be reset. Are you sure?": "您的同意設定將會重設。你確定嗎？",
    "Yes": "是的",
    "Cancel": "取消",
    "Session verified, redirecting securely...": "會話已驗證，安全重定向...",
    "Analysis complete ✅": "分析完成✅",
    "Purchases are not available right now. Please try again later.":
        "目前無法購買。請稍後重試。",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "購買已完成，但高級版尚未啟動。請再試一次。",
    "Welcome to Premium! Ads and wait times are removed.":
        "歡迎來到高級版！廣告和等待時間被刪除。",
    "Your Premium membership is active.": "您的高級會員資格已啟用。",
    "Restore Purchases": "恢復購買",
    "RESTORE": "恢復",
    "Restoring purchases...": "正在恢復購買...",
    "Purchases restored ✅": "已恢復購買 ✅",
    "No purchases to restore.": "沒有要恢復的購買。",
    "Restore failed: {err}": "恢復失敗：{err}",
    "Enter PIN": "輸入密碼",
    "PIN accepted, timer reset ✅": "PIN 碼已接受，計時器重設 ✅",
    "Invalid PIN": "PIN 碼無效",
    "OK": "好的",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "透過下載和使用本應用程序，每個使用者被視為已事先閱讀、理解並不可撤銷地接受以下「使用條款和免責聲明」文字：",
    "Article 1: Data Privacy and Local Processing Architecture":
        "第 1 條：資料隱私與本地處理架構",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT 是「客戶端」軟體。使用者的登入憑證（使用者名稱、密碼、會話 cookie）在任何情況下都不會傳輸到或儲存在外部伺服器上。所有資料處理活動僅發生在使用者裝置的臨時記憶體 (RAM) 和本機儲存中。該應用程式充當透過 Instagram 介面運行的「瀏覽器包裝器」。",
    "Article 2: Third-Party Platform Risks": "第二條：第三方平台風險",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) 保留根據其平台政策限制使用第三方軟體的權利。所有風險，包括但不限於因使用該應用程式而可能產生的“行動阻止”、“帳戶限制”、“影子禁令”或“帳戶關閉”，均完全由用戶承擔。 VERDICT 開發商不對此類行政制裁造成的任何直接或間接損害承擔責任。",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "第三條：免責聲明與責任限制",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "該軟體以“原樣”和“可用”形式提供。不保證軟體提供的分析結果的 100% 準確性、連續性或適銷性。使用者承認基於應用資料進行的法律或商業交易所產生的任何結果均由其自行承擔；並聲明並承諾使開發商免受所有索賠、訴訟和投訴的損害。",
    "Article 4: Intellectual Property and Independence Notice":
        "第四條：智慧財產權和獨立性聲明",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT 是一個獨立開發者專案。 「Instagram」、「Facebook」和「Meta」品牌是 Meta Platforms, Inc. 的註冊商標。此應用程式與上述公司沒有商業合作夥伴關係、贊助協議或官方從屬關係。",
    "Article 5: Service Continuity and Platform Changes": "第五條：服務連續性與平台變更",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Instagram API 或 Web 基礎架構的根本性變更可能會導致應用程式部分或完全失去其功能。開發人員不承諾更新應用程式或維護服務以應對此類基礎設施變更，這被視為「不可抗力」。",
    "Analysis complete, results will be shown after the ad.": "分析完成，結果將在廣告後顯示。",
    "Analysis failed": "分析失敗",
    "Reason: {reason}": "原因：{reason}",
    "Tip: Logging out and logging back in may help.": "提示：登出並重新登入可能會有所幫助。",
    "Quick check: Counts are the same. No changes detected.":
        "快速檢查：計數是相同的。未偵測到任何變化。",
    "Daily Metrics": "每日指標",
    "Active users": "活躍用戶",
    "Daily queries": "每日查詢",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "資料載入中斷：跟隨者資料不完整（{fetched}/{total}）。",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "資料載入中斷：以下資料不完整（{fetched}/{total}）。",
    "Data loading was interrupted: Instagram returned empty data.":
        "資料載入中斷：Instagram 返回空數據。",
    "Data loading stopped due to an unexpected error.": "由於意外錯誤，資料載入停止。",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram 回傳了自動行為警告。為了安全起見，我們停止取得資料。",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram 請求安全驗證。在 Instagram 應用程式中驗證並重試。",
    "Session is invalid or waiting for verification. Please log in again.":
        "會話無效或正在等待驗證。請重新登入。",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "發送的請求過多。為了安全起見，資料載入被中斷。",
    "Data loading could not complete due to a connection issue.":
        "由於連線問題，資料載入無法完成。",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram 回傳錯誤 (HTTP {code})。資料載入被中斷。",
    "Instagram security verification is required (story data could not be fetched).":
        "需要Instagram安全驗證（無法取得故事數據）。",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "無法取得故事數據。通常這是由 Instagram 驗證、臨時 API 限製或連接中斷引起的。請在 2-3 分鐘後重試。",
    "Could not fetch story data. Please try again shortly.": "無法取得故事數據。請稍後重試。",
    "Secret Mode": "秘密模式",
    "Starting VERDICT...": "開始判決...",
    "DID YOU KNOW?": "你可知道？",
    "Estimated time left: {time}": "預計剩餘時間：{time}",
    "Estimating remaining time...": "估計剩餘時間...",
    "LOG OUT": "退出",
    "Open Profile": "公開資料",
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
    "Analysis Time!": "Vrijeme je za analizu!",
    "CLOSE": "ZATVORITI",
    "SYSTEM UNDER MAINTENANCE": "SUSTAV U ODRŽAVANJU",
    "Bio Planner": "Bio planer",
    "Store link not set.": "Veza trgovine nije postavljena.",
    "Invalid store link.": "Nevažeća veza trgovine.",
    "Could not open the link.": "Nije moguće otvoriti vezu.",
    "Please try again.": "Molimo pokušajte ponovo.",
    "Show error": "Prikaži pogrešku",
    "Exception": "Iznimka",
    "Load error": "Greška pri učitavanju",
    "Code": "Kodirati",
    "Timeout": "Istek vremena",
    "REST probe failed: missing auth.":
        "REST sonda nije uspjela: nedostaje autorizacija.",
    "REST probe success (Firestore endpoint reachable).":
        "REST sonda uspješna (krajnja točka Firestore dostupna).",
    "REST probe failed (check logs).":
        "REST sonda nije uspjela (provjerite zapise).",
    "Firebase Auth probe failed.":
        "Proba Firebase autentifikacije nije uspjela.",
    "Firebase Auth probe success.": "Firebase Auth probe uspjela.",
    "Firebase token probe failed.": "Proba Firebase tokena nije uspjela.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITIČNA DIJAGNOSTIČKA POGREŠKA",
    "COPY": "KOPIRATI",
    "OPEN LOGS": "OTVORENI DNEVNICI",
    "Firebase": "Firebase",
    "Store": "Store",
    "Copy all": "Kopiraj sve",
    "Close": "Zatvoriti",
    "Auth Probe": "Auth Probe",
    "Write Test": "Napiši test",
    "REST Probe": "REST sonda",
    "Restore Test": "Test vraćanja",
    "Firebase auth error: user verification failed.":
        "Pogreška Firebase autentifikacije: provjera korisnika nije uspjela.",
    "Firestore test write successful.": "Pisanje Firestore testa uspješno.",
    "Firestore test failed.": "Firestore test nije uspio.",
    "Firestore auth error: user verification failed.":
        "Firestore pogreška autentifikacije: provjera korisnika nije uspjela.",
    "Firestore counter write failed.":
        "Pisanje Firestore brojača nije uspjelo.",
    "Firestore auth missing: ig_users write blocked.":
        "Nedostaje Firestore autentifikacija: ig_users pisanje blokirano.",
    "Firestore ig_users write failed.":
        "Firestore ig_users pisanje nije uspjelo.",
    "User": "Korisnik",
    "Opening consent form...": "Otvaranje obrasca za pristanak...",
    "Your consent preference was updated.":
        "Vaše postavke pristanka su ažurirane.",
    "Consent update failed. Please try again.":
        "Ažuriranje pristanka nije uspjelo. Molimo pokušajte ponovo.",
    "Your account is blocked": "Vaš račun je blokiran",
    "Access is restricted for this account.":
        "Pristup je ograničen za ovaj račun.",
    "Starting purchase...": "Početak kupnje...",
    "Purchase cancelled.": "Kupnja otkazana.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktivan ✅ Oglasi i vrijeme čekanja su onemogućeni.",
    "Purchase failed. Please try again.":
        "Kupnja nije uspjela. Molimo pokušajte ponovo.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Potrebna je verifikacija sesije. Potvrdite svoj račun u aplikaciji Instagram i pokušajte ponovno.",
    "Instagram returned no data.": "Instagram nije vratio podatke.",
    "Session verification failed. Please log in again.":
        "Provjera sesije nije uspjela. Molimo prijavite se ponovo.",
    "Open Instagram": "Otvorite Instagram",
    "Instagram message": "Instagram poruka",
    "Loading stories...": "Učitavanje priča...",
    "No data": "Nema podataka",
    "NEW": "NOVI",
    "Login": "Prijava",
    "Session verified, redirecting...": "Sesija potvrđena, preusmjeravanje...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "OGLASNI PROSTOR",
    "Admin mode active": "Administratorski način rada aktivan",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Svaki dan se razvijamo kako bismo vam pružili bolje iskustvo. Vaše povratne informacije su nam vrijedne - voljeli bismo čuti vaše mišljenje!",
    "Please log in to start the analysis.": "Prijavite se za početak analize.",
    "Welcome, {username}": "Dobro došli, {username}",
    "REFRESH DATA": "OSVJEŽI PODATKE",
    "LOG IN WITH INSTAGRAM": "PRIJAVITE SE PREKO INSTAGRAMA",
    "Analyzing data...\nThis might take a moment.":
        "Analiza podataka...\nOvo bi moglo potrajati.",
    "Processing data...\nAlmost done.": "Obrada podataka...\nSkoro gotovo.",
    "Loading ad...\nPlease wait.": "Učitavanje oglasa...\nMolimo pričekajte.",
    "Google ad warning: {reason}": "Upozorenje Google oglasa: {reason}",
    "All analysis is securely processed locally on your device.":
        "Sve analize sigurno se obrađuju lokalno na vašem uređaju.",
    "Total analyses today: {count}": "Ukupno analiza danas: {count}",
    "Next analysis": "Sljedeća analiza",
    "Ready to scan.": "Spremno za skeniranje.",
    "Analysis available now": "Analiza je sada dostupna",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analiza je sada dostupna, ali uzastopno izvođenje analiza može dovesti vaš račun u opasnost.",
    "Please wait": "Molimo pričekajte",
    "Warning": "Upozorenje",
    "Next analysis: {time}": "Sljedeća analiza: {time}",
    "WATCH AD AND START ANALYSIS": "POGLEDAJTE OGLAS I KRENITE U ANALIZU",
    "START ANALYSIS": "POKRENI ANALIZU",
    "Start analysis?": "Pokrenuti analizu?",
    "Reset App Data": "Poništi podatke aplikacije",
    "This will wipe all local data and session cookies. Are you sure?":
        "Ovo će izbrisati sve lokalne podatke i kolačiće sesije. Jeste li sigurni?",
    "CANCEL": "OTKAZATI",
    "DELETE": "IZBRISATI",
    "Error": "Greška",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Dohvaćanje podataka nije uspjelo: {err}\n\nRješavanje problema: Pokušajte se odjaviti i ponovno prijaviti.",
    "Followers": "Sljedbenici",
    "Following": "Praćenje",
    "New Followers": "Novi sljedbenici",
    "Not Following Back": "Ne pratim natrag",
    "Lost Followers": "Izgubljeni sljedbenici",
    "Legal Disclaimer": "Pravno odricanje od odgovornosti",
    "Unfollowed Users": "Nepraćeni korisnici",
    "Rate Us": "Ocijenite nas",
    "Contact Us": "Kontaktirajte nas",
    "Remove Ads & Wait Times": "Uklonite oglase i vremena čekanja",
    "This box is currently under test.":
        "Ova kutija je trenutno u fazi testiranja.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Gledajte priče potajno ili zumirajte fotografije profila",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Prijavite se kako biste tajno gledali priče i povećali fotografije profila.",
    "Will be shown after the ad, please wait.":
        "Prikazat će se nakon oglasa, pričekajte.",
    "What would you like to do?": "Što biste željeli raditi?",
    "Enlarge profile photo": "Povećaj profilnu sliku",
    "Watch story secretly": "Gledajte priču tajno",
    "No story data available.": "Nema dostupnih podataka o priči.",
    "I HAVE READ AND AGREE": "PROČITAO SAM I SLAŽEM SE",
    "Withdraw Consent": "Povući privolu",
    "Confirm": "Potvrdi",
    "Your consent settings will be reset. Are you sure?":
        "Vaše postavke pristanka bit će poništene. Jeste li sigurni?",
    "Yes": "Da",
    "Cancel": "Otkazati",
    "Session verified, redirecting securely...":
        "Sesija potvrđena, sigurno preusmjeravanje...",
    "Analysis complete ✅": "Analiza završena ✅",
    "Purchases are not available right now. Please try again later.":
        "Kupnje trenutno nisu dostupne. Pokušajte ponovno kasnije.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Kupnja je dovršena, ali Premium još nije aktivan. Molimo pokušajte ponovo.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Dobro došli u Premium! Oglasi i vrijeme čekanja su uklonjeni.",
    "Your Premium membership is active.": "Vaše Premium članstvo je aktivno.",
    "Restore Purchases": "Obnovi kupnje",
    "RESTORE": "VRATITI",
    "Restoring purchases...": "Vraćanje kupnji...",
    "Purchases restored ✅": "Kupnje obnovljene ✅",
    "No purchases to restore.": "Nema kupnji za vraćanje.",
    "Restore failed: {err}": "Vraćanje nije uspjelo: {err}",
    "Enter PIN": "Unesite PIN",
    "PIN accepted, timer reset ✅": "PIN prihvaćen, mjerač vremena poništen ✅",
    "Invalid PIN": "Nevažeći PIN",
    "OK": "U REDU",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Preuzimanjem i korištenjem ove aplikacije, smatra se da je svaki korisnik unaprijed pročitao, razumio i neopozivo prihvatio tekst \"Uvjeti korištenja i odricanje od odgovornosti\" u nastavku:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Članak 1: Privatnost podataka i arhitektura lokalne obrade",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT je softver na strani klijenta. Korisničke vjerodajnice za prijavu (korisničko ime, lozinka, kolačići sesije) ni pod kojim okolnostima se ne prenose niti pohranjuju na vanjski poslužitelj. Sve aktivnosti obrade podataka odvijaju se isključivo unutar privremene memorije (RAM) i lokalne pohrane uređaja Korisnika. Aplikacija funkcionira kao \"omotač preglednika\" koji radi preko Instagram sučelja.",
    "Article 2: Third-Party Platform Risks":
        "Članak 2: Rizici platforme treće strane",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) pridržava pravo ograničiti korištenje softvera trećih strana prema svojim pravilima platforme. Svi rizici, uključujući ali ne ograničavajući se na 'blokade radnji', 'ograničenja računa', 'zabrane u sjeni' ili 'zatvaranja računa' koji mogu proizaći iz korištenja aplikacije, pripadaju isključivo Korisniku. Programer VERDICT ne može se smatrati odgovornim za bilo kakvu izravnu ili neizravnu štetu koja proizlazi iz takvih administrativnih sankcija.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Članak 3: Odricanje od jamstva i ograničenje odgovornosti",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Ovaj softver se isporučuje 'KAKAV JE' i 'KAKO JE DOSTUPAN'. Ne jamči se 100%-tna točnost, kontinuitet ili mogućnost prodaje rezultata analize koje nudi softver. Korisnik potvrđuje da su svi rezultati proizašli iz pravnih ili komercijalnih transakcija temeljenih na podacima aplikacije njegova vlastita odgovornost; te izjavljuje i obvezuje se da će programera zaštititi od svih zahtjeva, tužbi i pritužbi.",
    "Article 4: Intellectual Property and Independence Notice":
        "Članak 4: Obavijest o intelektualnom vlasništvu i neovisnosti",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT je neovisni razvojni projekt. Brendovi 'Instagram', 'Facebook' i 'Meta' registrirani su zaštitni znakovi tvrtke Meta Platforms, Inc. Ova aplikacija nema komercijalno partnerstvo, ugovor o sponzorstvu ili službenu povezanost s gore navedenim tvrtkama.",
    "Article 5: Service Continuity and Platform Changes":
        "Članak 5: Kontinuitet usluge i promjene platforme",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Temeljite promjene Instagram API-ja ili web infrastrukture mogu uzrokovati djelomični ili potpuni gubitak funkcionalnosti aplikacije. Programer se ne obvezuje ažurirati aplikaciju ili održavati uslugu kao odgovor na takve infrastrukturne promjene, koje se smatraju \"višom silom\".",
    "Analysis complete, results will be shown after the ad.":
        "Analiza dovršena, rezultati će biti prikazani nakon oglasa.",
    "Analysis failed": "Analiza nije uspjela",
    "Reason: {reason}": "Razlog: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Savjet: odjava i ponovna prijava može pomoći.",
    "Quick check: Counts are the same. No changes detected.":
        "Brza provjera: Brojevi su isti. Nisu otkrivene promjene.",
    "Daily Metrics": "Dnevna metrika",
    "Active users": "Aktivni korisnici",
    "Daily queries": "Dnevni upiti",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Učitavanje podataka je prekinuto: podaci o pratitelju nisu potpuni ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Učitavanje podataka je prekinuto: sljedeći podaci nisu potpuni ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Učitavanje podataka je prekinuto: Instagram je vratio prazne podatke.",
    "Data loading stopped due to an unexpected error.":
        "Učitavanje podataka zaustavljeno je zbog neočekivane pogreške.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram je vratio upozorenje o automatskom ponašanju. Prestali smo dohvaćati podatke radi sigurnosti.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram je zatražio sigurnosnu provjeru. Potvrdite u aplikaciji Instagram i pokušajte ponovno.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sesija je nevažeća ili čeka potvrdu. Molimo prijavite se ponovo.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Poslano je previše zahtjeva. Učitavanje podataka je prekinuto radi sigurnosti.",
    "Data loading could not complete due to a connection issue.":
        "Učitavanje podataka nije dovršeno zbog problema s vezom.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram je vratio pogrešku (HTTP {code}). Učitavanje podataka je prekinuto.",
    "Instagram security verification is required (story data could not be fetched).":
        "Potrebna je sigurnosna potvrda Instagrama (podaci o priči nisu se mogli dohvatiti).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Nije moguće dohvatiti podatke priče. Obično je to uzrokovano provjerom Instagrama, privremenim ograničenjima API-ja ili prekidom veze. Pokušajte ponovno za 2-3 minute.",
    "Could not fetch story data. Please try again shortly.":
        "Nije moguće dohvatiti podatke priče. Pokušajte ponovno uskoro.",
    "Secret Mode": "Tajni način rada",
    "Starting VERDICT...": "Počinje VERDICT...",
    "DID YOU KNOW?": "JESTE LI ZNALI?",
    "Estimated time left: {time}": "Procijenjeno preostalo vrijeme: {time}",
    "Estimating remaining time...": "Procjena preostalog vremena...",
    "LOG OUT": "ODJAVA",
    "Open Profile": "Otvorite profil",
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
    "Analysis Time!": "Čas analýzy!",
    "CLOSE": "BLÍZKO",
    "SYSTEM UNDER MAINTENANCE": "SYSTÉM POD ÚDRŽBOU",
    "Bio Planner": "Bio plánovač",
    "Store link not set.": "Odkaz na obchod není nastaven.",
    "Invalid store link.": "Neplatný odkaz na obchod.",
    "Could not open the link.": "Odkaz nelze otevřít.",
    "Please try again.": "Zkuste to prosím znovu.",
    "Show error": "Zobrazit chybu",
    "Exception": "Výjimka",
    "Load error": "Chyba načítání",
    "Code": "Kód",
    "Timeout": "Časový limit",
    "REST probe failed: missing auth.": "Sonda REST selhala: chybí ověření.",
    "REST probe success (Firestore endpoint reachable).":
        "Úspěch sondy REST (koncový bod Firestore dosažitelný).",
    "REST probe failed (check logs).":
        "Sonda REST selhala (zkontrolujte protokoly).",
    "Firebase Auth probe failed.": "Test Firebase Auth selhal.",
    "Firebase Auth probe success.": "Testování Firebase Auth bylo úspěšné.",
    "Firebase token probe failed.": "Snímání tokenu Firebase se nezdařilo.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITICKÁ DIAGNOSTICKÁ CHYBA",
    "COPY": "KOPIE",
    "OPEN LOGS": "OTEVŘENÉ DENÍKY",
    "Firebase": "Firebase",
    "Store": "Obchod",
    "Copy all": "Zkopírujte vše",
    "Close": "Blízko",
    "Auth Probe": "Auth Probe",
    "Write Test": "Napište test",
    "REST Probe": "REST Sonda",
    "Restore Test": "Obnovit test",
    "Firebase auth error: user verification failed.":
        "Chyba ověření Firebase: ověření uživatele se nezdařilo.",
    "Firestore test write successful.": "Zápis testu Firestore byl úspěšný.",
    "Firestore test failed.": "Test Firestore se nezdařil.",
    "Firestore auth error: user verification failed.":
        "Chyba ověření Firestore: ověření uživatele se nezdařilo.",
    "Firestore counter write failed.": "Zápis počítadla Firestore se nezdařil.",
    "Firestore auth missing: ig_users write blocked.":
        "Chybí ověření Firestore: ig_users zápis blokován.",
    "Firestore ig_users write failed.": "Zápis ig_users Firestore se nezdařil.",
    "User": "Uživatel",
    "Opening consent form...": "Otevírání formuláře souhlasu...",
    "Your consent preference was updated.":
        "Vaše předvolba souhlasu byla aktualizována.",
    "Consent update failed. Please try again.":
        "Aktualizace souhlasu se nezdařila. Zkuste to prosím znovu.",
    "Your account is blocked": "Váš účet je zablokován",
    "Access is restricted for this account.":
        "Přístup je pro tento účet omezen.",
    "Starting purchase...": "Spouštění nákupu...",
    "Purchase cancelled.": "Nákup zrušen.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktivní ✅ Reklamy a čekací doby jsou deaktivovány.",
    "Purchase failed. Please try again.":
        "Nákup se nezdařil. Zkuste to prosím znovu.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Je vyžadováno ověření relace. Ověřte svůj účet v aplikaci Instagram a zkuste to znovu.",
    "Instagram returned no data.": "Instagram nevrátil žádná data.",
    "Session verification failed. Please log in again.":
        "Ověření relace se nezdařilo. Přihlaste se prosím znovu.",
    "Open Instagram": "Otevřete Instagram",
    "Instagram message": "Zpráva na Instagramu",
    "Loading stories...": "Načítání příběhů...",
    "No data": "Žádná data",
    "NEW": "NOVÝ",
    "Login": "Přihlášení",
    "Session verified, redirecting...": "Relace ověřena, přesměrování...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "REKLAMNÍ PROSTOR",
    "Admin mode active": "Režim správce je aktivní",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Každým dnem se vyvíjíme, abychom vám poskytli lepší zážitek. Vaše zpětná vazba je pro nás cenná – rádi bychom ji slyšeli!",
    "Please log in to start the analysis.":
        "Pro zahájení analýzy se prosím přihlaste.",
    "Welcome, {username}": "Vítejte, {username}",
    "REFRESH DATA": "OBNOVIT DATA",
    "LOG IN WITH INSTAGRAM": "PŘIHLÁSIT SE NA INSTAGRAMU",
    "Analyzing data...\nThis might take a moment.":
        "Analýza dat...\nMůže to chvíli trvat.",
    "Processing data...\nAlmost done.": "Zpracování dat...\nTéměř hotovo.",
    "Loading ad...\nPlease wait.": "Načítání reklamy...\nČekejte prosím.",
    "Google ad warning: {reason}": "Upozornění na reklamu Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Všechny analýzy jsou bezpečně zpracovávány lokálně na vašem zařízení.",
    "Total analyses today: {count}": "Celkový počet dnešních analýz: {count}",
    "Next analysis": "Další analýza",
    "Ready to scan.": "Připraveno ke skenování.",
    "Analysis available now": "Analýza je nyní k dispozici",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analýza je nyní k dispozici, ale souběžné provádění analýz může ohrozit váš účet.",
    "Please wait": "Čekejte prosím",
    "Warning": "Varování",
    "Next analysis: {time}": "Další analýza: {time}",
    "WATCH AD AND START ANALYSIS": "PODÍVEJTE SE NA REKLAMU A ZAČNĚTE ANALÝZU",
    "START ANALYSIS": "ZAČNĚTE ANALÝZU",
    "Start analysis?": "Spustit analýzu?",
    "Reset App Data": "Resetujte data aplikace",
    "This will wipe all local data and session cookies. Are you sure?":
        "Tím se vymažou všechna místní data a soubory cookie relace. jsi si jistý?",
    "CANCEL": "ZRUŠIT",
    "DELETE": "VYMAZAT",
    "Error": "Chyba",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Načítání dat se nezdařilo: {err}\n\nOdstraňování problémů: Zkuste se odhlásit a znovu přihlásit.",
    "Followers": "Následovníci",
    "Following": "Následující",
    "New Followers": "Noví sledující",
    "Not Following Back": "Nesledování Zpět",
    "Lost Followers": "Ztracení následovníci",
    "Legal Disclaimer": "Právní vyloučení odpovědnosti",
    "Unfollowed Users": "Nesledovaní uživatelé",
    "Rate Us": "Ohodnoťte nás",
    "Contact Us": "Kontaktujte nás",
    "Remove Ads & Wait Times": "Odstraňte reklamy a čekací doby",
    "This box is currently under test.":
        "Tento box je v současné době ve fázi testování.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Sledujte příběhy tajně nebo přibližujte profilové fotografie",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Přihlaste se, abyste mohli tajně sledovat příběhy a zvětšovat profilové fotografie.",
    "Will be shown after the ad, please wait.":
        "Zobrazí se po reklamě, čekejte prosím.",
    "What would you like to do?": "co bys chtěl dělat?",
    "Enlarge profile photo": "Zvětšit profilovou fotku",
    "Watch story secretly": "Sledujte příběh tajně",
    "No story data available.": "Nejsou k dispozici žádná data příběhu.",
    "I HAVE READ AND AGREE": "PŘEČETLA JSEM A SOUHLASÍM",
    "Withdraw Consent": "Odvolat souhlas",
    "Confirm": "Potvrdit",
    "Your consent settings will be reset. Are you sure?":
        "Vaše nastavení souhlasu bude resetováno. jsi si jistý?",
    "Yes": "Ano",
    "Cancel": "Zrušit",
    "Session verified, redirecting securely...":
        "Relace ověřena, přesměrování zabezpečené...",
    "Analysis complete ✅": "Analýza hotová ✅",
    "Purchases are not available right now. Please try again later.":
        "Nákupy nejsou momentálně dostupné. Zkuste to znovu později.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Nákup dokončen, ale Premium ještě není aktivní. Zkuste to prosím znovu.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Vítejte ve službě Premium! Reklamy a čekací doby jsou odstraněny.",
    "Your Premium membership is active.": "Vaše prémiové členství je aktivní.",
    "Restore Purchases": "Obnovit nákupy",
    "RESTORE": "OBNOVIT",
    "Restoring purchases...": "Obnovování nákupů...",
    "Purchases restored ✅": "Nákupy obnoveny ✅",
    "No purchases to restore.": "Žádné nákupy k obnovení.",
    "Restore failed: {err}": "Obnovení se nezdařilo: {err}",
    "Enter PIN": "Zadejte PIN",
    "PIN accepted, timer reset ✅": "PIN přijat, časovač resetován ✅",
    "Invalid PIN": "Neplatný PIN",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Stažením a používáním této aplikace se má za to, že každý uživatel si předem přečetl, porozuměl a neodvolatelně přijal níže uvedený text „Podmínky použití a vyloučení odpovědnosti:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Článek 1: Ochrana osobních údajů a místní architektura zpracování",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT je software na straně klienta. Přihlašovací údaje uživatele (uživatelské jméno, heslo, soubory cookie relace) se za žádných okolností nepřenášejí na externí server ani se na něm neukládají. Veškeré činnosti zpracování dat probíhají výhradně v rámci dočasné paměti (RAM) a místního úložiště zařízení Uživatele. Aplikace funguje jako „obálka prohlížeče“ fungující přes rozhraní Instagramu.",
    "Article 2: Third-Party Platform Risks":
        "Článek 2: Rizika platformy třetích stran",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) si vyhrazuje právo omezit používání softwaru třetích stran podle zásad své platformy. Veškerá rizika, včetně, ale bez omezení, „blokování akcí“, „omezení účtu“, „stínových zákazů“ nebo „uzavření účtu“, která mohou vyplynout z používání aplikace, náleží výhradně Uživateli. Vývojář VERDICT nemůže nést odpovědnost za žádné přímé nebo nepřímé škody vyplývající z takových správních sankcí.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Článek 3: Zřeknutí se záruky a omezení odpovědnosti",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Tento software je poskytován „TAK, JAK JE“ a „JAK JE DOSTUPNÝ“. 100% přesnost, kontinuita nebo prodejnost výsledků analýzy poskytovaných softwarem není zaručena. Uživatel bere na vědomí, že jakékoli výsledky vyplývající z právních nebo obchodních transakcí založených na datech aplikace jsou jeho vlastní odpovědností; a prohlašuje a zavazuje se chránit vývojáře před všemi nároky, soudními spory a stížnostmi.",
    "Article 4: Intellectual Property and Independence Notice":
        "Článek 4: Oznámení o duševním vlastnictví a nezávislosti",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT je nezávislý developerský projekt. Značky 'Instagram', 'Facebook' a 'Meta' jsou registrované ochranné známky společnosti Meta Platforms, Inc. Tato aplikace nemá žádné obchodní partnerství, sponzorskou smlouvu ani oficiální přidružení k výše uvedeným společnostem.",
    "Article 5: Service Continuity and Platform Changes":
        "Článek 5: Kontinuita služby a změny platformy",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Zásadní změny v Instagram API nebo webové infrastruktuře mohou způsobit, že aplikace částečně nebo úplně ztratí svou funkčnost. Vývojář se nezavazuje aktualizovat aplikaci nebo udržovat službu v reakci na takové změny infrastruktury, které jsou považovány za „vyšší moc“.",
    "Analysis complete, results will be shown after the ad.":
        "Analýza dokončena, výsledky se zobrazí po reklamě.",
    "Analysis failed": "Analýza se nezdařila",
    "Reason: {reason}": "Důvod: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tip: Může vám pomoci odhlášení a opětovné přihlášení.",
    "Quick check: Counts are the same. No changes detected.":
        "Rychlá kontrola: Počty jsou stejné. Nebyly zjištěny žádné změny.",
    "Daily Metrics": "Denní metriky",
    "Active users": "Aktivní uživatelé",
    "Daily queries": "Denní dotazy",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Načítání dat bylo přerušeno: data sledujícího nejsou kompletní ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Načítání dat bylo přerušeno: následující data nejsou kompletní ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Načítání dat bylo přerušeno: Instagram vrátil prázdná data.",
    "Data loading stopped due to an unexpected error.":
        "Načítání dat se zastavilo kvůli neočekávané chybě.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram vrátil varování o automatickém chování. Kvůli bezpečnosti jsme přestali načítat data.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram požádal o bezpečnostní ověření. Ověřte v aplikaci Instagram a zkuste to znovu.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Relace je neplatná nebo čeká na ověření. Přihlaste se prosím znovu.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Bylo odesláno příliš mnoho žádostí. Načítání dat bylo kvůli bezpečnosti přerušeno.",
    "Data loading could not complete due to a connection issue.":
        "Načítání dat nebylo možné dokončit kvůli problému s připojením.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram vrátil chybu (HTTP {code}). Načítání dat bylo přerušeno.",
    "Instagram security verification is required (story data could not be fetched).":
        "Je vyžadováno ověření zabezpečení Instagramu (data příběhu nelze načíst).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Data příběhu se nepodařilo načíst. Obvykle je to způsobeno ověřením Instagramu, dočasnými omezeními API nebo přerušením připojení. Zkuste to znovu za 2–3 minuty.",
    "Could not fetch story data. Please try again shortly.":
        "Nepodařilo se načíst data příběhu. Zkuste to za chvíli znovu.",
    "Secret Mode": "Tajný režim",
    "Starting VERDICT...": "Začíná VERDICT...",
    "DID YOU KNOW?": "VĚDĚLI JSTE?",
    "Estimated time left: {time}": "Odhadovaný zbývající čas: {time}",
    "Estimating remaining time...": "Odhad zbývajícího času...",
    "LOG OUT": "ODHLÁSIT SE",
    "Open Profile": "Otevřete Profil",
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
    "Analysis Time!": "Analyse tid!",
    "CLOSE": "TÆT",
    "SYSTEM UNDER MAINTENANCE": "SYSTEM UNDER VEDLIGEHOLDELSE",
    "Bio Planner": "Bioplanlægger",
    "Store link not set.": "Butikslink ikke angivet.",
    "Invalid store link.": "Ugyldigt butikslink.",
    "Could not open the link.": "Kunne ikke åbne linket.",
    "Please try again.": "Prøv venligst igen.",
    "Show error": "Vis fejl",
    "Exception": "Undtagelse",
    "Load error": "Fejl ved indlæsning",
    "Code": "Kode",
    "Timeout": "Timeout",
    "REST probe failed: missing auth.":
        "REST-sonde mislykkedes: manglende godkendelse.",
    "REST probe success (Firestore endpoint reachable).":
        "REST sonde succes (Firestore-endepunkt kan nås).",
    "REST probe failed (check logs).":
        "REST-sonden mislykkedes (tjek logfiler).",
    "Firebase Auth probe failed.": "Firebase Auth-probe mislykkedes.",
    "Firebase Auth probe success.": "Firebase Auth-probe lykkedes.",
    "Firebase token probe failed.": "Firebase-tokensonde mislykkedes.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITISK DIAGNOSTISK FEJL",
    "COPY": "KOPI",
    "OPEN LOGS": "ÅBN LOGS",
    "Firebase": "Firebase",
    "Store": "Butik",
    "Copy all": "Kopier alle",
    "Close": "Tæt",
    "Auth Probe": "Auth Probe",
    "Write Test": "Skriv test",
    "REST Probe": "HVILE sonde",
    "Restore Test": "Gendan test",
    "Firebase auth error: user verification failed.":
        "Firebase-godkendelsesfejl: Brugerbekræftelse mislykkedes.",
    "Firestore test write successful.": "Firestore testskrivning lykkedes.",
    "Firestore test failed.": "Firestore-testen mislykkedes.",
    "Firestore auth error: user verification failed.":
        "Firestore-godkendelsesfejl: Brugerbekræftelse mislykkedes.",
    "Firestore counter write failed.": "Firestore-tællerskrivning mislykkedes.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore-godkendelse mangler: ig_users skrive blokeret.",
    "Firestore ig_users write failed.":
        "Firestore ig_users skrivning mislykkedes.",
    "User": "Bruger",
    "Opening consent form...": "Åbner samtykkeformular...",
    "Your consent preference was updated.":
        "Din samtykkepræference blev opdateret.",
    "Consent update failed. Please try again.":
        "Samtykkeopdatering mislykkedes. Prøv venligst igen.",
    "Your account is blocked": "Din konto er blokeret",
    "Access is restricted for this account.":
        "Adgangen er begrænset for denne konto.",
    "Starting purchase...": "Starter køb...",
    "Purchase cancelled.": "Køb annulleret.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktiv ✅ Annoncer og ventetider er deaktiveret.",
    "Purchase failed. Please try again.":
        "Køb mislykkedes. Prøv venligst igen.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Sessionsbekræftelse er påkrævet. Bekræft venligst din konto i Instagram-appen, og prøv igen.",
    "Instagram returned no data.": "Instagram returnerede ingen data.",
    "Session verification failed. Please log in again.":
        "Sessionsbekræftelse mislykkedes. Log venligst ind igen.",
    "Open Instagram": "Åbn Instagram",
    "Instagram message": "Instagram besked",
    "Loading stories...": "Indlæser historier...",
    "No data": "Ingen data",
    "NEW": "NY",
    "Login": "Log ind",
    "Session verified, redirecting...": "Session bekræftet, omdirigerer...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ANNONCERUM",
    "Admin mode active": "Admin-tilstand aktiv",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Vi udvikler os hver dag for at give dig en bedre oplevelse. Din feedback er værdifuld for os - vi vil meget gerne høre fra dig!",
    "Please log in to start the analysis.":
        "Log venligst ind for at starte analysen.",
    "Welcome, {username}": "Velkommen, {username}",
    "REFRESH DATA": "OPDATERE DATA",
    "LOG IN WITH INSTAGRAM": "LOG IND MED INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analyserer data...\nDette kan tage et øjeblik.",
    "Processing data...\nAlmost done.": "Behandler data...\nNæsten færdig.",
    "Loading ad...\nPlease wait.": "Indlæser annonce...\nVent venligst.",
    "Google ad warning: {reason}": "Google-annonceadvarsel: {reason}",
    "All analysis is securely processed locally on your device.":
        "Al analyse behandles sikkert lokalt på din enhed.",
    "Total analyses today: {count}": "Samlede analyser i dag: {count}",
    "Next analysis": "Næste analyse",
    "Ready to scan.": "Klar til at scanne.",
    "Analysis available now": "Analyse tilgængelig nu",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analyse er tilgængelig nu, men at køre analyser back-to-back kan bringe din konto i fare.",
    "Please wait": "Vent venligst",
    "Warning": "Advarsel",
    "Next analysis: {time}": "Næste analyse: {time}",
    "WATCH AD AND START ANALYSIS": "SE ANNONCE OG START ANALYSE",
    "START ANALYSIS": "START ANALYSE",
    "Start analysis?": "Start analyse?",
    "Reset App Data": "Nulstil appdata",
    "This will wipe all local data and session cookies. Are you sure?":
        "Dette vil slette alle lokale data og sessionscookies. Er du sikker?",
    "CANCEL": "OPHÆVE",
    "DELETE": "SLET",
    "Error": "Fejl",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Datahentning mislykkedes: {err}\n\nFejlfinding: Prøv at logge ud og logge ind igen.",
    "Followers": "Tilhængere",
    "Following": "Følge",
    "New Followers": "Nye følgere",
    "Not Following Back": "Følger ikke tilbage",
    "Lost Followers": "Mistede følgere",
    "Legal Disclaimer": "Juridisk ansvarsfraskrivelse",
    "Unfollowed Users": "Ikke fulgte brugere",
    "Rate Us": "Bedøm os",
    "Contact Us": "Kontakt os",
    "Remove Ads & Wait Times": "Fjern annoncer og ventetider",
    "This box is currently under test.":
        "Denne boks er i øjeblikket under test.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Se historier i hemmelighed eller zoom profilbilleder",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Log venligst ind for at se historier hemmeligt og forstørre profilbilleder.",
    "Will be shown after the ad, please wait.":
        "Vil blive vist efter annoncen, vent venligst.",
    "What would you like to do?": "Hvad vil du gerne lave?",
    "Enlarge profile photo": "Forstør profilbillede",
    "Watch story secretly": "Se historien i hemmelighed",
    "No story data available.": "Ingen historiedata tilgængelige.",
    "I HAVE READ AND AGREE": "JEG HAR LÆST OG ENIG",
    "Withdraw Consent": "Tilbagekald samtykke",
    "Confirm": "Bekræfte",
    "Your consent settings will be reset. Are you sure?":
        "Dine samtykkeindstillinger nulstilles. Er du sikker?",
    "Yes": "Ja",
    "Cancel": "Ophæve",
    "Session verified, redirecting securely...":
        "Session bekræftet, omdirigerer sikkert...",
    "Analysis complete ✅": "Analyse færdig ✅",
    "Purchases are not available right now. Please try again later.":
        "Køb er ikke tilgængelige lige nu. Prøv venligst igen senere.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Købet er gennemført, men Premium er ikke aktivt endnu. Prøv venligst igen.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Velkommen til Premium! Annoncer og ventetider fjernes.",
    "Your Premium membership is active.": "Dit Premium-medlemskab er aktivt.",
    "Restore Purchases": "Gendan køb",
    "RESTORE": "GENDAN",
    "Restoring purchases...": "Gendanner køb...",
    "Purchases restored ✅": "Køb genoprettet ✅",
    "No purchases to restore.": "Ingen køb at gendanne.",
    "Restore failed: {err}": "Gendannelse mislykkedes: {err}",
    "Enter PIN": "Indtast PIN-kode",
    "PIN accepted, timer reset ✅": "PIN accepteret, timer nulstilling ✅",
    "Invalid PIN": "Ugyldig pinkode",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Ved at downloade og bruge denne applikation anses enhver bruger for at have læst, forstået og uigenkaldeligt accepteret teksten \"Betingelser for brug og ansvarsfraskrivelse\" nedenfor på forhånd:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artikel 1: Databeskyttelse og lokal behandlingsarkitektur",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT er 'client-side' software. Brugerens loginoplysninger (brugernavn, adgangskode, sessionscookies) overføres under ingen omstændigheder til eller gemmes på en ekstern server. Alle databehandlingsaktiviteter foregår udelukkende i den midlertidige hukommelse (RAM) og lokale lager på brugerens enhed. Applikationen fungerer som en 'browser-indpakning', der fungerer over Instagram-grænsefladen.",
    "Article 2: Third-Party Platform Risks":
        "Artikel 2: Tredjepartsplatformsrisici",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) forbeholder sig retten til at begrænse brugen af ​​tredjepartssoftware i henhold til deres platformspolitikker. Alle risici, herunder men ikke begrænset til \"handlingsblokeringer\", \"kontobegrænsninger\", \"shadowbans\" eller \"kontolukninger\", der kan opstå ved brugen af ​​applikationen, tilhører udelukkende Brugeren. VERDICT-udvikleren kan ikke holdes ansvarlig for nogen direkte eller indirekte skader som følge af sådanne administrative sanktioner.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artikel 3: Ansvarsfraskrivelse og begrænsning af ansvar",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Denne software leveres 'SOM DEN ER' og 'SOM TILGÆNGELIG'. 100 % nøjagtighed, kontinuitet eller salgbarhed af analyseresultaterne leveret af softwaren er ikke garanteret. Brugeren anerkender, at ethvert resultat, der opstår fra juridiske eller kommercielle transaktioner baseret på applikationsdata, er deres eget ansvar; og erklærer og forpligter sig til at holde udvikleren skadesløs fra alle krav, retssager og klager.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artikel 4: Meddelelse om intellektuel ejendomsret og uafhængighed",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT er et uafhængigt udviklerprojekt. Mærkerne 'Instagram', 'Facebook' og 'Meta' er registrerede varemærker tilhørende Meta Platforms, Inc. Denne applikation har intet kommercielt partnerskab, sponsoraftale eller officiel tilknytning til de førnævnte virksomheder.",
    "Article 5: Service Continuity and Platform Changes":
        "Artikel 5: Tjenestekontinuitet og platformsændringer",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Grundlæggende ændringer af Instagram API eller webinfrastruktur kan få applikationen til at miste sin funktionalitet helt eller delvist. Udvikleren forpligter sig ikke til at opdatere applikationen eller vedligeholde tjenesten som svar på sådanne infrastrukturelle ændringer, som betragtes som \"force majeure\".",
    "Analysis complete, results will be shown after the ad.":
        "Analysen er fuldført, resultaterne vil blive vist efter annoncen.",
    "Analysis failed": "Analyse mislykkedes",
    "Reason: {reason}": "Årsag: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tip: Det kan hjælpe at logge ud og logge ind igen.",
    "Quick check: Counts are the same. No changes detected.":
        "Hurtigt tjek: Antallet er det samme. Ingen ændringer registreret.",
    "Daily Metrics": "Daglige målinger",
    "Active users": "Aktive brugere",
    "Daily queries": "Daglige forespørgsler",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Dataindlæsningen blev afbrudt: følgerdata er ufuldstændige ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Dataindlæsningen blev afbrudt: følgende data er ufuldstændige ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Dataindlæsningen blev afbrudt: Instagram returnerede tomme data.",
    "Data loading stopped due to an unexpected error.":
        "Dataindlæsning stoppede på grund af en uventet fejl.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram returnerede en advarsel om automatisk adfærd. Vi holdt op med at hente data for en sikkerheds skyld.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram anmodede om sikkerhedsbekræftelse. Bekræft i Instagram-appen, og prøv igen.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sessionen er ugyldig eller venter på bekræftelse. Log venligst ind igen.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Der blev sendt for mange anmodninger. Dataindlæsningen blev afbrudt af sikkerhedsmæssige årsager.",
    "Data loading could not complete due to a connection issue.":
        "Dataindlæsningen kunne ikke fuldføres på grund af et forbindelsesproblem.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram returnerede en fejl (HTTP {code}). Dataindlæsningen blev afbrudt.",
    "Instagram security verification is required (story data could not be fetched).":
        "Instagram-sikkerhedsbekræftelse er påkrævet (historiedata kunne ikke hentes).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Historiedata kunne ikke hentes. Normalt er dette forårsaget af Instagram-bekræftelse, midlertidige API-begrænsninger eller en forbindelsesafbrydelse. Prøv venligst igen om 2-3 minutter.",
    "Could not fetch story data. Please try again shortly.":
        "Kunne ikke hente historiedata. Prøv igen snart.",
    "Secret Mode": "Hemmelig tilstand",
    "Starting VERDICT...": "Starter VERDICT...",
    "DID YOU KNOW?": "VIDSTE DU?",
    "Estimated time left: {time}": "Estimeret tid tilbage: {time}",
    "Estimating remaining time...": "Estimerer resterende tid...",
    "LOG OUT": "LOG UD",
    "Open Profile": "Åbn profil",
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
    "Analysis Time!": "Analyysin aika!",
    "CLOSE": "LÄHELLÄ",
    "SYSTEM UNDER MAINTENANCE": "JÄRJESTELMÄ HUOLTOALLA",
    "Bio Planner": "Bio suunnittelija",
    "Store link not set.": "Kaupan linkkiä ei ole asetettu.",
    "Invalid store link.": "Virheellinen kauppalinkki.",
    "Could not open the link.": "Linkkiä ei voitu avata.",
    "Please try again.": "Yritä uudelleen.",
    "Show error": "Näytä virhe",
    "Exception": "Poikkeus",
    "Load error": "Latausvirhe",
    "Code": "Koodi",
    "Timeout": "Aikakatkaisu",
    "REST probe failed: missing auth.":
        "REST-anturi epäonnistui: todennus puuttuu.",
    "REST probe success (Firestore endpoint reachable).":
        "REST-anturi onnistui (Firestore-päätepiste tavoitettavissa).",
    "REST probe failed (check logs).":
        "REST-anturi epäonnistui (tarkista lokit).",
    "Firebase Auth probe failed.": "Firebase Auth -tarkistus epäonnistui.",
    "Firebase Auth probe success.": "Firebase Auth -tutkinta onnistui.",
    "Firebase token probe failed.": "Firebase-tunnuksen tutkinta epäonnistui.",
    "CRITICAL DIAGNOSTIC ERROR": "KRIITTINEN DIAGNOSTINEN VIRHE",
    "COPY": "KOPIOIDA",
    "OPEN LOGS": "AVAA LOKIT",
    "Firebase": "Firebase",
    "Store": "Store",
    "Copy all": "Kopioi kaikki",
    "Close": "Lähellä",
    "Auth Probe": "Auth Probe",
    "Write Test": "Kirjoita testi",
    "REST Probe": "REST Anturi",
    "Restore Test": "Palauta testi",
    "Firebase auth error: user verification failed.":
        "Firebase-todennusvirhe: käyttäjän vahvistus epäonnistui.",
    "Firestore test write successful.": "Firestore-testikirjoitus onnistui.",
    "Firestore test failed.": "Firestore-testi epäonnistui.",
    "Firestore auth error: user verification failed.":
        "Firestore-todennusvirhe: käyttäjän vahvistus epäonnistui.",
    "Firestore counter write failed.":
        "Firestore-laskurin kirjoitus epäonnistui.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore-todennus puuttuu: ig_users kirjoitus estetty.",
    "Firestore ig_users write failed.":
        "Firestore ig_users -kirjoitus epäonnistui.",
    "User": "Käyttäjä",
    "Opening consent form...": "Avataan suostumuslomake...",
    "Your consent preference was updated.": "Suostumusasetuksesi päivitettiin.",
    "Consent update failed. Please try again.":
        "Suostumuspäivitys epäonnistui. Yritä uudelleen.",
    "Your account is blocked": "Tilisi on estetty",
    "Access is restricted for this account.":
        "Pääsyä on rajoitettu tälle tilille.",
    "Starting purchase...": "Aloittaa osto...",
    "Purchase cancelled.": "Ostos peruutettu.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktiivinen ✅ Mainokset ja odotusajat ovat poissa käytöstä.",
    "Purchase failed. Please try again.": "Osto epäonnistui. Yritä uudelleen.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Istunnon vahvistus vaaditaan. Vahvista tilisi Instagram-sovelluksessa ja yritä uudelleen.",
    "Instagram returned no data.": "Instagram ei palauttanut tietoja.",
    "Session verification failed. Please log in again.":
        "Istunnon vahvistus epäonnistui. Kirjaudu uudelleen sisään.",
    "Open Instagram": "Avaa Instagram",
    "Instagram message": "Instagram viesti",
    "Loading stories...": "Ladataan tarinoita...",
    "No data": "Ei dataa",
    "NEW": "UUSI",
    "Login": "Kirjaudu sisään",
    "Session verified, redirecting...":
        "Istunto vahvistettu, uudelleenohjaus...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "MAINOSTILA",
    "Admin mode active": "Järjestelmänvalvojatila aktiivinen",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Kehitämme joka päivä tarjotaksemme sinulle paremman kokemuksen. Palautteesi on meille arvokasta – haluaisimme kuulla sinusta!",
    "Please log in to start the analysis.":
        "Ole hyvä ja kirjaudu sisään aloittaaksesi analyysin.",
    "Welcome, {username}": "Tervetuloa, {username}",
    "REFRESH DATA": "PÄIVITYS TIEDOT",
    "LOG IN WITH INSTAGRAM": "KIRJAUDU INSTAGRAMIN KANSSA",
    "Analyzing data...\nThis might take a moment.":
        "Analysoidaan tietoja...\nTämä voi kestää hetken.",
    "Processing data...\nAlmost done.":
        "Käsitellään tietoja...\nMelkein valmis.",
    "Loading ad...\nPlease wait.": "Ladataan mainosta...\nOdota.",
    "Google ad warning: {reason}": "Google-mainoksen varoitus: {reason}",
    "All analysis is securely processed locally on your device.":
        "Kaikki analyysit käsitellään turvallisesti paikallisesti laitteellasi.",
    "Total analyses today: {count}": "Tämän päivän analyysit yhteensä: {count}",
    "Next analysis": "Seuraava analyysi",
    "Ready to scan.": "Valmiina skannaamaan.",
    "Analysis available now": "Analyysi nyt saatavilla",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analyysi on nyt saatavilla, mutta analyysien suorittaminen peräkkäin voi vaarantaa tilisi.",
    "Please wait": "Odota",
    "Warning": "Varoitus",
    "Next analysis: {time}": "Seuraava analyysi: {time}",
    "WATCH AD AND START ANALYSIS": "KATSO MAINOS JA ALOITA ANALYYSI",
    "START ANALYSIS": "ALOITA ANALYYSI",
    "Start analysis?": "Aloitetaanko analyysi?",
    "Reset App Data": "Nollaa sovellustiedot",
    "This will wipe all local data and session cookies. Are you sure?":
        "Tämä poistaa kaikki paikalliset tiedot ja istunnon evästeet. Oletko varma?",
    "CANCEL": "PERUUTTAA",
    "DELETE": "POISTAA",
    "Error": "Virhe",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Tietojen haku epäonnistui: {err}\n\nVianetsintä: Yritä kirjautua ulos ja kirjautua takaisin sisään.",
    "Followers": "Seuraajat",
    "Following": "Jälkeen",
    "New Followers": "Uusia seuraajia",
    "Not Following Back": "Ei seuraa takaisin",
    "Lost Followers": "Kadonneet seuraajat",
    "Legal Disclaimer": "Oikeudellinen vastuuvapauslauseke",
    "Unfollowed Users": "Seuraamattomat käyttäjät",
    "Rate Us": "Arvioi meidät",
    "Contact Us": "Ota yhteyttä",
    "Remove Ads & Wait Times": "Poista mainokset ja odotusajat",
    "This box is currently under test.":
        "Tätä laatikkoa testataan parhaillaan.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Katso Stories Secretly tai Zoomaa profiilikuvia",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Kirjaudu sisään nähdäksesi tarinoita salaa ja suurentaaksesi profiilikuvia.",
    "Will be shown after the ad, please wait.":
        "Näytetään mainoksen jälkeen, odota.",
    "What would you like to do?": "Mitä haluaisit tehdä?",
    "Enlarge profile photo": "Suurenna profiilikuva",
    "Watch story secretly": "Katso tarina salaa",
    "No story data available.": "Tarinadataa ei ole saatavilla.",
    "I HAVE READ AND AGREE": "OLEN LUKINUT JA YHTÄVÄT",
    "Withdraw Consent": "Peruuta suostumus",
    "Confirm": "Vahvistaa",
    "Your consent settings will be reset. Are you sure?":
        "Suostumusasetuksesi nollataan. Oletko varma?",
    "Yes": "Kyllä",
    "Cancel": "Peruuttaa",
    "Session verified, redirecting securely...":
        "Istunto vahvistettu, ohjataan turvallisesti...",
    "Analysis complete ✅": "Analyysi valmis ✅",
    "Purchases are not available right now. Please try again later.":
        "Ostoksia ei ole tällä hetkellä saatavilla. Yritä myöhemmin uudelleen.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Ostos tehty, mutta Premium ei ole vielä aktiivinen. Yritä uudelleen.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Tervetuloa Premiumiin! Mainokset ja odotusajat poistetaan.",
    "Your Premium membership is active.": "Premium-jäsenyytesi on aktiivinen.",
    "Restore Purchases": "Palauta ostokset",
    "RESTORE": "PALAUTTAA",
    "Restoring purchases...": "Palautetaan ostoksia...",
    "Purchases restored ✅": "Ostokset palautettu ✅",
    "No purchases to restore.": "Ei palautettavia ostoksia.",
    "Restore failed: {err}": "Palautus epäonnistui: {err}",
    "Enter PIN": "Anna PIN-koodi",
    "PIN accepted, timer reset ✅": "PIN hyväksytty, ajastin nollattu ✅",
    "Invalid PIN": "Virheellinen PIN-koodi",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Lataamalla ja käyttämällä tätä sovellusta jokaisen käyttäjän katsotaan lukeneen, ymmärtäneen ja peruuttamattomasti hyväksyneen alla olevat \"Käyttöehdot ja vastuuvapauslauseke\" -teksti etukäteen:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artikkeli 1: Tietosuoja ja paikallinen käsittelyarkkitehtuuri",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT on \"asiakaspuolen\" ohjelmisto. Käyttäjän kirjautumistunnuksia (käyttäjätunnus, salasana, istuntoevästeet) ei missään olosuhteissa välitetä tai tallenneta ulkoiselle palvelimelle. Kaikki tietojenkäsittelytoiminnot tapahtuvat yksinomaan käyttäjän laitteen väliaikaisessa muistissa (RAM) ja paikallisessa tallennustilassa. Sovellus toimii \"selainkääreenä\", joka toimii Instagram-käyttöliittymän yli.",
    "Article 2: Third-Party Platform Risks":
        "Artikla 2: Kolmannen osapuolen alustan riskit",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) pidättää oikeuden rajoittaa kolmannen osapuolen ohjelmistojen käyttöä alustakäytäntöjensä mukaisesti. Kaikki sovelluksen käytöstä mahdollisesti aiheutuvat riskit, mukaan lukien \"toimintalohkot\", \"tilirajoitukset\", \"shadowbans\" tai \"tilin sulkemiset\", mukaan lukien, mutta ei niihin rajoittuen, kuuluvat yksinomaan Käyttäjälle. VERDICT-kehittäjä ei ole vastuussa mistään suorista tai välillisistä vahingoista, jotka johtuvat tällaisista hallinnollisista seuraamuksista.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artikla 3: Takuun vastuuvapauslauseke ja vastuunrajoitus",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Tämä ohjelmisto toimitetaan \"SELLAISENAAN\" ja \"SAATAVILLA\". Ohjelmiston toimittamien analyysitulosten 100 %:n tarkkuutta, jatkuvuutta tai myyntikelpoisuutta ei taata. Käyttäjä hyväksyy, että sovellustietoihin perustuvista juridisista tai kaupallisista liiketoimista aiheutuvat tulokset ovat hänen omalla vastuullaan; ja ilmoittaa ja sitoutuu pitämään kehittäjän vaarattomana kaikista vaatimuksista, oikeudenkäynneistä ja valituksista.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artikla 4: Teollis- ja tekijänoikeuksia ja riippumattomuutta koskeva tiedonanto",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT on itsenäinen kehittäjäprojekti. Brändit \"Instagram\", \"Facebook\" ja \"Meta\" ovat Meta Platforms, Inc:n rekisteröityjä tavaramerkkejä. Tällä sovelluksella ei ole kaupallista kumppanuutta, sponsorointisopimusta tai virallista yhteyttä edellä mainittuihin yrityksiin.",
    "Article 5: Service Continuity and Platform Changes":
        "Artikla 5: Palvelun jatkuvuus ja alustan muutokset",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Perusteelliset muutokset Instagram-sovellusliittymään tai verkkoinfrastruktuuriin voivat aiheuttaa sen, että sovellus menettää toiminnallisuutensa osittain tai kokonaan. Kehittäjä ei sitoudu päivittämään sovellusta tai ylläpitämään palvelua tällaisten infrastruktuurimuutosten vuoksi, joita pidetään ylivoimaisena esteenä.",
    "Analysis complete, results will be shown after the ad.":
        "Analyysi valmis, tulokset näytetään mainoksen jälkeen.",
    "Analysis failed": "Analyysi epäonnistui",
    "Reason: {reason}": "Syy: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Vinkki: Ulos- ja takaisin sisäänkirjautuminen voi auttaa.",
    "Quick check: Counts are the same. No changes detected.":
        "Pikatarkistus: Luvut ovat samat. Muutoksia ei havaittu.",
    "Daily Metrics": "Päivittäiset tiedot",
    "Active users": "Aktiiviset käyttäjät",
    "Daily queries": "Päivittäiset kyselyt",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Tietojen lataus keskeytettiin: seuraajan tiedot puutteellisia ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Tietojen lataus keskeytettiin: seuraavat tiedot ovat epätäydellisiä ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Tietojen lataus keskeytettiin: Instagram palautti tyhjiä tietoja.",
    "Data loading stopped due to an unexpected error.":
        "Tietojen lataus pysähtyi odottamattoman virheen vuoksi.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram palautti automaattisen käyttäytymisvaroituksen. Lopetimme tietojen hakemisen turvallisuuden vuoksi.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram pyysi turvatarkastusta. Vahvista Instagram-sovelluksessa ja yritä uudelleen.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Istunto on virheellinen tai se odottaa vahvistusta. Kirjaudu uudelleen sisään.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Liian monta pyyntöä lähetettiin. Tietojen lataus keskeytettiin turvallisuussyistä.",
    "Data loading could not complete due to a connection issue.":
        "Tietojen lataus epäonnistui yhteysongelman vuoksi.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram palautti virheen (HTTP {code}). Tietojen lataus keskeytettiin.",
    "Instagram security verification is required (story data could not be fetched).":
        "Instagram-suojausvahvistus vaaditaan (tarinatietoja ei voitu hakea).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Tarinatietoja ei voitu noutaa. Yleensä tämä johtuu Instagram-vahvistuksesta, väliaikaisista API-rajoituksista tai yhteyden katkeamisesta. Yritä uudelleen 2–3 minuutin kuluttua.",
    "Could not fetch story data. Please try again shortly.":
        "Tarinatietoja ei voitu noutaa. Yritä hetken kuluttua uudelleen.",
    "Secret Mode": "Salainen tila",
    "Starting VERDICT...": "Aloitetaan VERDICT...",
    "DID YOU KNOW?": "TIESITKÖ?",
    "Estimated time left: {time}": "Arvioitu aika jäljellä: {time}",
    "Estimating remaining time...": "Arvioitu jäljellä oleva aika...",
    "LOG OUT": "KIRJAUDU ULOS",
    "Open Profile": "Avaa Profiili",
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
    "Analysis Time!": "C'est l'heure de l'analyse !",
    "CLOSE": "FERMER",
    "SYSTEM UNDER MAINTENANCE": "SYSTÈME EN MAINTENANCE",
    "Bio Planner": "Planificateur biologique",
    "Store link not set.": "Lien de magasin non défini.",
    "Invalid store link.": "Lien de magasin invalide.",
    "Could not open the link.": "Impossible d'ouvrir le lien.",
    "Please try again.": "Veuillez réessayer.",
    "Show error": "Afficher l'erreur",
    "Exception": "Exception",
    "Load error": "Erreur de chargement",
    "Code": "Code",
    "Timeout": "Temps mort",
    "REST probe failed: missing auth.":
        "Échec de la sonde REST : authentification manquante.",
    "REST probe success (Firestore endpoint reachable).":
        "Réussite de la sonde REST (point de terminaison Firestore accessible).",
    "REST probe failed (check logs).":
        "La sonde REST a échoué (vérifier les journaux).",
    "Firebase Auth probe failed.": "La sonde Firebase Auth a échoué.",
    "Firebase Auth probe success.": "Réussite de la sonde Firebase Auth.",
    "Firebase token probe failed.":
        "La vérification du jeton Firebase a échoué.",
    "CRITICAL DIAGNOSTIC ERROR": "ERREUR DE DIAGNOSTIC CRITIQUE",
    "COPY": "COPIE",
    "OPEN LOGS": "JOURNAUX OUVERTS",
    "Firebase": "Base de feu",
    "Store": "Magasin",
    "Copy all": "Copier tout",
    "Close": "Fermer",
    "Auth Probe": "Sonde d'authentification",
    "Write Test": "Test d'écriture",
    "REST Probe": "Sonde REST",
    "Restore Test": "Test de restauration",
    "Firebase auth error: user verification failed.":
        "Erreur d'authentification Firebase : la vérification de l'utilisateur a échoué.",
    "Firestore test write successful.": "Test d'écriture Firestore réussi.",
    "Firestore test failed.": "Le test Firestore a échoué.",
    "Firestore auth error: user verification failed.":
        "Erreur d'authentification Firestore : la vérification de l'utilisateur a échoué.",
    "Firestore counter write failed.":
        "Échec de l'écriture du compteur Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Authentification Firestore manquante : ig_users bloque l'écriture.",
    "Firestore ig_users write failed.":
        "Échec de l'écriture de Firestore ig_users.",
    "User": "Utilisateur",
    "Opening consent form...": "Formulaire de consentement d'ouverture...",
    "Your consent preference was updated.":
        "Votre préférence de consentement a été mise à jour.",
    "Consent update failed. Please try again.":
        "La mise à jour du consentement a échoué. Veuillez réessayer.",
    "Your account is blocked": "Votre compte est bloqué",
    "Access is restricted for this account.":
        "L'accès est restreint pour ce compte.",
    "Starting purchase...": "Début de l'achat...",
    "Purchase cancelled.": "Achat annulé.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium actif ✅ Les publicités et les temps d'attente sont désactivés.",
    "Purchase failed. Please try again.":
        "L'achat a échoué. Veuillez réessayer.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "La vérification de la session est requise. Veuillez vérifier votre compte dans l'application Instagram et réessayer.",
    "Instagram returned no data.": "Instagram n'a renvoyé aucune donnée.",
    "Session verification failed. Please log in again.":
        "La vérification de la session a échoué. Veuillez vous reconnecter.",
    "Open Instagram": "Ouvrez Instagram",
    "Instagram message": "Message Instagram",
    "Loading stories...": "Chargement des histoires...",
    "No data": "Aucune donnée",
    "NEW": "NOUVEAU",
    "Login": "Se connecter",
    "Session verified, redirecting...": "Session vérifiée, redirection...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ESPACE PUBLICITAIRE",
    "Admin mode active": "Mode administrateur actif",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Nous évoluons chaque jour pour vous offrir une meilleure expérience. Vos commentaires sont précieux pour nous ; nous serions ravis de vous entendre !",
    "Please log in to start the analysis.":
        "Veuillez vous connecter pour démarrer l'analyse.",
    "Welcome, {username}": "Bienvenue, {username}",
    "REFRESH DATA": "RAFRAÎCHIR LES DONNÉES",
    "LOG IN WITH INSTAGRAM": "CONNEXION AVEC INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analyse des données...\nCela peut prendre un moment.",
    "Processing data...\nAlmost done.":
        "Traitement des données...\nPresque terminé.",
    "Loading ad...\nPlease wait.":
        "Chargement de l'annonce...\nVeuillez patienter.",
    "Google ad warning: {reason}":
        "Avertissement publicitaire Google : {reason}",
    "All analysis is securely processed locally on your device.":
        "Toutes les analyses sont traitées en toute sécurité localement sur votre appareil.",
    "Total analyses today: {count}": "Analyses totales aujourd'hui : {count}",
    "Next analysis": "Analyse suivante",
    "Ready to scan.": "Prêt à numériser.",
    "Analysis available now": "Analyse disponible maintenant",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "L'analyse est disponible dès maintenant, mais l'exécution d'analyses consécutives peut mettre votre compte en danger.",
    "Please wait": "S'il vous plaît, attendez",
    "Warning": "Avertissement",
    "Next analysis: {time}": "Analyse suivante : {time}",
    "WATCH AD AND START ANALYSIS": "REGARDER L'ANNONCE ET COMMENCER L'ANALYSE",
    "START ANALYSIS": "COMMENCER L'ANALYSE",
    "Start analysis?": "Démarrer l'analyse ?",
    "Reset App Data": "Réinitialiser les données de l'application",
    "This will wipe all local data and session cookies. Are you sure?":
        "Cela effacera toutes les données locales et les cookies de session. Es-tu sûr?",
    "CANCEL": "ANNULER",
    "DELETE": "SUPPRIMER",
    "Error": "Erreur",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Échec de la récupération des données : {err}\n\nDépannage : essayez de vous déconnecter et de vous reconnecter.",
    "Followers": "Abonnés",
    "Following": "Suivant",
    "New Followers": "Nouveaux abonnés",
    "Not Following Back": "Ne pas suivre",
    "Lost Followers": "Abonnés perdus",
    "Legal Disclaimer": "Mentions légales",
    "Unfollowed Users": "Utilisateurs non suivis",
    "Rate Us": "Évaluez-nous",
    "Contact Us": "Contactez-nous",
    "Remove Ads & Wait Times":
        "Supprimer les publicités et les temps d'attente",
    "This box is currently under test.": "Cette box est actuellement en test.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Regardez des histoires en secret ou zoomez sur les photos de profil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Veuillez vous connecter pour regarder des histoires en secret et agrandir les photos de profil.",
    "Will be shown after the ad, please wait.":
        "Sera diffusé après l'annonce, veuillez patienter.",
    "What would you like to do?": "Qu'aimeriez-vous faire ?",
    "Enlarge profile photo": "Agrandir la photo de profil",
    "Watch story secretly": "Regarder l'histoire en secret",
    "No story data available.": "Aucune donnée d'histoire disponible.",
    "I HAVE READ AND AGREE": "J'AI LU ET D'ACCORD",
    "Withdraw Consent": "Retirer le consentement",
    "Confirm": "Confirmer",
    "Your consent settings will be reset. Are you sure?":
        "Vos paramètres de consentement seront réinitialisés. Es-tu sûr?",
    "Yes": "Oui",
    "Cancel": "Annuler",
    "Session verified, redirecting securely...":
        "Session vérifiée, redirection sécurisée...",
    "Analysis complete ✅": "Analyse terminée ✅",
    "Purchases are not available right now. Please try again later.":
        "Les achats ne sont pas disponibles pour le moment. Veuillez réessayer plus tard.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Achat terminé, mais Premium n'est pas encore actif. Veuillez réessayer.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Bienvenue sur Premium ! Les publicités et les temps d'attente sont supprimés.",
    "Your Premium membership is active.": "Votre abonnement Premium est actif.",
    "Restore Purchases": "Restaurer les achats",
    "RESTORE": "RESTAURER",
    "Restoring purchases...": "Restauration des achats...",
    "Purchases restored ✅": "Achats restaurés ✅",
    "No purchases to restore.": "Aucun achat à restaurer.",
    "Restore failed: {err}": "Échec de la restauration : {err}",
    "Enter PIN": "Entrez le code PIN",
    "PIN accepted, timer reset ✅":
        "Code PIN accepté, minuterie réinitialisée ✅",
    "Invalid PIN": "Code PIN invalide",
    "OK": "D'ACCORD",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "En téléchargeant et en utilisant cette application, chaque Utilisateur est réputé avoir lu, compris et accepté irrévocablement au préalable le texte des « Conditions d'utilisation et clause de non-responsabilité » ci-dessous :",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Article 1 : Confidentialité des données et architecture de traitement local",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT est un logiciel « côté client ». Les identifiants de connexion de l'Utilisateur (identifiant, mot de passe, cookies de session) ne sont en aucun cas transmis ou stockés sur un serveur externe. Toutes les activités de traitement des données se déroulent exclusivement dans la mémoire temporaire (RAM) et le stockage local de l'appareil de l'utilisateur. L'application fonctionne comme un « navigateur-wrapper » fonctionnant sur l'interface Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Article 2 : Risques liés aux plateformes tierces",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) se réserve le droit de restreindre l'utilisation de logiciels tiers conformément aux politiques de sa plateforme. Tous les risques, y compris, mais sans s'y limiter, les « blocages d'actions », les « restrictions de compte », les « shadowbans » ou les « fermetures de compte » pouvant découler de l'utilisation de l'application, appartiennent exclusivement à l'Utilisateur. Le développeur VERDICT ne peut être tenu responsable de tout dommage direct ou indirect résultant de telles sanctions administratives.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Article 3 : Exclusion de garantie et limitation de responsabilité",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Ce logiciel est fourni « EN L'ÉTAT » et « TEL QUE DISPONIBLE ». L'exactitude, la continuité ou la qualité marchande à 100 % des résultats d'analyse fournis par le logiciel ne sont pas garanties. L'Utilisateur reconnaît que tous les résultats découlant de transactions juridiques ou commerciales basées sur les données de l'application relèvent de sa propre responsabilité ; et déclare et s'engage à dégager le développeur de toute responsabilité contre toutes réclamations, poursuites et plaintes.",
    "Article 4: Intellectual Property and Independence Notice":
        "Article 4 : Propriété Intellectuelle et Avis d'Indépendance",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT est un projet de développeur indépendant. Les marques « Instagram », « Facebook » et « Meta » sont des marques déposées de Meta Platforms, Inc. Cette application n'a aucun partenariat commercial, accord de parrainage ou affiliation officielle avec les sociétés susmentionnées.",
    "Article 5: Service Continuity and Platform Changes":
        "Article 5 : Continuité du Service et Modifications de la Plateforme",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Des modifications fondamentales apportées à l'API Instagram ou à l'infrastructure Web peuvent entraîner la perte partielle ou totale de la fonctionnalité de l'application. Le développeur ne s'engage pas à mettre à jour l'application ou à maintenir le service en réponse à de tels changements d'infrastructure, qui sont considérés comme « force majeure ».",
    "Analysis complete, results will be shown after the ad.":
        "Analyse terminée, les résultats seront affichés après la publicité.",
    "Analysis failed": "L'analyse a échoué",
    "Reason: {reason}": "Raison : {reason}",
    "Tip: Logging out and logging back in may help.":
        "Astuce : Se déconnecter et se reconnecter peut s'avérer utile.",
    "Quick check: Counts are the same. No changes detected.":
        "Vérification rapide : les comptes sont les mêmes. Aucun changement détecté.",
    "Daily Metrics": "Mesures quotidiennes",
    "Active users": "Utilisateurs actifs",
    "Daily queries": "Requêtes quotidiennes",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Le chargement des données a été interrompu : données suiveuses incomplètes ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Le chargement des données a été interrompu : données suivantes incomplètes ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Le chargement des données a été interrompu : Instagram a renvoyé des données vides.",
    "Data loading stopped due to an unexpected error.":
        "Le chargement des données s'est arrêté en raison d'une erreur inattendue.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram a renvoyé un avertissement de comportement automatisé. Nous avons arrêté de récupérer des données pour des raisons de sécurité.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram a demandé une vérification de sécurité. Vérifiez dans l'application Instagram et réessayez.",
    "Session is invalid or waiting for verification. Please log in again.":
        "La session n'est pas valide ou est en attente de vérification. Veuillez vous reconnecter.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Trop de demandes ont été envoyées. Le chargement des données a été interrompu pour des raisons de sécurité.",
    "Data loading could not complete due to a connection issue.":
        "Le chargement des données n'a pas pu se terminer en raison d'un problème de connexion.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram a renvoyé une erreur (HTTP {code}). Le chargement des données a été interrompu.",
    "Instagram security verification is required (story data could not be fetched).":
        "Une vérification de sécurité Instagram est requise (les données de l'histoire n'ont pas pu être récupérées).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Les données de l'histoire n'ont pas pu être récupérées. Cela est généralement dû à une vérification Instagram, à des restrictions temporaires de l'API ou à une interruption de connexion. Veuillez réessayer dans 2-3 minutes.",
    "Could not fetch story data. Please try again shortly.":
        "Impossible de récupérer les données de l'histoire. Veuillez réessayer sous peu.",
    "Secret Mode": "Mode secret",
    "Starting VERDICT...": "Démarrage du VERDICT...",
    "DID YOU KNOW?": "SAVIEZ-VOUS?",
    "Estimated time left: {time}": "Temps restant estimé : {time}",
    "Estimating remaining time...": "Estimation du temps restant...",
    "LOG OUT": "DÉCONNEXION",
    "Open Profile": "Ouvrir le profil",
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
    "Analysis Time!": "Ώρα ανάλυσης!",
    "CLOSE": "ΚΟΝΤΑ",
    "SYSTEM UNDER MAINTENANCE": "ΣΥΣΤΗΜΑ ΥΠΟ ΣΥΝΤΗΡΗΣΗ",
    "Bio Planner": "Bio Planner",
    "Store link not set.": "Ο σύνδεσμος καταστήματος δεν έχει οριστεί.",
    "Invalid store link.": "Μη έγκυρος σύνδεσμος καταστήματος.",
    "Could not open the link.": "Δεν ήταν δυνατό το άνοιγμα του συνδέσμου.",
    "Please try again.": "Δοκιμάστε ξανά.",
    "Show error": "Εμφάνιση σφάλματος",
    "Exception": "Εξαίρεση",
    "Load error": "Σφάλμα φόρτωσης",
    "Code": "Κώδικας",
    "Timeout": "Timeout",
    "REST probe failed: missing auth.":
        "Η ανίχνευση REST απέτυχε: λείπει η ταυτότητα.",
    "REST probe success (Firestore endpoint reachable).":
        "Επιτυχία ανίχνευσης REST (προσβάσιμο τελικό σημείο του Firestore).",
    "REST probe failed (check logs).":
        "Ο ανιχνευτής REST απέτυχε (έλεγχος αρχείων καταγραφής).",
    "Firebase Auth probe failed.": "Η έρευνα Firebase Auth απέτυχε.",
    "Firebase Auth probe success.": "Επιτυχία διερεύνησης Firebase Auth.",
    "Firebase token probe failed.":
        "Ο ανιχνευτής διακριτικού Firebase απέτυχε.",
    "CRITICAL DIAGNOSTIC ERROR": "ΚΡΙΣΙΜΟ ΔΙΑΓΝΩΣΤΙΚΟ ΣΦΑΛΜΑ",
    "COPY": "ΑΝΤΙΓΡΑΦΟ",
    "OPEN LOGS": "ΑΝΟΙΧΤΑ ΚΑΤΑΣΚΕΥΕΣ",
    "Firebase": "Firebase",
    "Store": "Κατάστημα",
    "Copy all": "Αντιγράψτε όλα",
    "Close": "Κοντά",
    "Auth Probe": "Auth Probe",
    "Write Test": "Γράψτε τεστ",
    "REST Probe": "REST Probe",
    "Restore Test": "Επαναφορά δοκιμής",
    "Firebase auth error: user verification failed.":
        "Σφάλμα ελέγχου ταυτότητας Firebase: η επαλήθευση χρήστη απέτυχε.",
    "Firestore test write successful.": "Επιτυχής εγγραφή δοκιμής Firestore.",
    "Firestore test failed.": "Η δοκιμή Firestore απέτυχε.",
    "Firestore auth error: user verification failed.":
        "Σφάλμα ελέγχου ταυτότητας Firestore: η επαλήθευση χρήστη απέτυχε.",
    "Firestore counter write failed.":
        "Η εγγραφή του μετρητή Firestore απέτυχε.",
    "Firestore auth missing: ig_users write blocked.":
        "Λείπει η ταυτότητα του Firestore: η εγγραφή ig_users έχει αποκλειστεί.",
    "Firestore ig_users write failed.":
        "Η εγγραφή του Firestore ig_users απέτυχε.",
    "User": "Μεταχειριζόμενος",
    "Opening consent form...": "Έναρξη φόρμας συναίνεσης...",
    "Your consent preference was updated.":
        "Η προτίμηση συναίνεσής σας ενημερώθηκε.",
    "Consent update failed. Please try again.":
        "Η ενημέρωση συναίνεσης απέτυχε. Δοκιμάστε ξανά.",
    "Your account is blocked": "Ο λογαριασμός σας έχει αποκλειστεί",
    "Access is restricted for this account.":
        "Η πρόσβαση είναι περιορισμένη για αυτόν τον λογαριασμό.",
    "Starting purchase...": "Έναρξη αγοράς...",
    "Purchase cancelled.": "Η αγορά ακυρώθηκε.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium ενεργό ✅ Οι διαφημίσεις και οι χρόνοι αναμονής είναι απενεργοποιημένοι.",
    "Purchase failed. Please try again.": "Η αγορά απέτυχε. Δοκιμάστε ξανά.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Απαιτείται επαλήθευση συνεδρίας. Επαληθεύστε τον λογαριασμό σας στην εφαρμογή Instagram και δοκιμάστε ξανά.",
    "Instagram returned no data.": "Το Instagram δεν επέστρεψε δεδομένα.",
    "Session verification failed. Please log in again.":
        "Η επαλήθευση της περιόδου σύνδεσης απέτυχε. Παρακαλούμε συνδεθείτε ξανά.",
    "Open Instagram": "Ανοίξτε το Instagram",
    "Instagram message": "Μήνυμα στο Instagram",
    "Loading stories...": "Φόρτωση ιστοριών...",
    "No data": "Δεν υπάρχουν δεδομένα",
    "NEW": "ΝΕΟΣ",
    "Login": "Σύνδεση",
    "Session verified, redirecting...":
        "Η συνεδρία επαληθεύτηκε, ανακατεύθυνση...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ΔΙΑΦΗΜΙΣΤΙΚΟΣ ΧΩΡΟΣ",
    "Admin mode active": "Ενεργή λειτουργία διαχειριστή",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Εξελισσόμαστε καθημερινά για να σας προσφέρουμε μια καλύτερη εμπειρία. Τα σχόλιά σας είναι πολύτιμα για εμάς—θα θέλαμε να ακούσουμε από εσάς!",
    "Please log in to start the analysis.":
        "Παρακαλούμε συνδεθείτε για να ξεκινήσετε την ανάλυση.",
    "Welcome, {username}": "Καλώς ορίσατε, {username}",
    "REFRESH DATA": "ΑΝΑΝΕΩΣΗ ΔΕΔΟΜΕΝΩΝ",
    "LOG IN WITH INSTAGRAM": "ΣΥΝΔΕΣΗ ΜΕ INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Ανάλυση δεδομένων...\nΑυτό μπορεί να διαρκέσει λίγο.",
    "Processing data...\nAlmost done.":
        "Επεξεργασία δεδομένων...\nΣχεδόν τελειωμένο.",
    "Loading ad...\nPlease wait.":
        "Φόρτωση διαφήμισης...\nΠαρακαλώ περιμένετε.",
    "Google ad warning: {reason}": "Προειδοποίηση διαφημίσεων Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Όλες οι αναλύσεις επεξεργάζονται με ασφάλεια τοπικά στη συσκευή σας.",
    "Total analyses today: {count}": "Συνολικές αναλύσεις σήμερα: {count}",
    "Next analysis": "Επόμενη ανάλυση",
    "Ready to scan.": "Έτοιμο για σάρωση.",
    "Analysis available now": "Η ανάλυση είναι διαθέσιμη τώρα",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Η ανάλυση είναι διαθέσιμη τώρα, αλλά η συνεχής εκτέλεση αναλύσεων μπορεί να θέσει τον λογαριασμό σας σε κίνδυνο.",
    "Please wait": "Παρακαλώ περιμένετε",
    "Warning": "Προειδοποίηση",
    "Next analysis: {time}": "Επόμενη ανάλυση: {time}",
    "WATCH AD AND START ANALYSIS": "ΔΕΙΤΕ ΔΙΑΦΗΜΙΣΗ ΚΑΙ ΞΕΚΙΝΗΣΤΕ ΤΗΝ ΑΝΑΛΥΣΗ",
    "START ANALYSIS": "ΕΝΑΡΞΗ ΑΝΑΛΥΣΗΣ",
    "Start analysis?": "Έναρξη ανάλυσης;",
    "Reset App Data": "Επαναφορά δεδομένων εφαρμογής",
    "This will wipe all local data and session cookies. Are you sure?":
        "Αυτό θα διαγράψει όλα τα τοπικά δεδομένα και τα cookie περιόδου λειτουργίας. Είσαι σίγουρος;",
    "CANCEL": "ΜΑΤΑΙΩΣΗ",
    "DELETE": "ΔΙΑΓΡΑΦΩ",
    "Error": "Σφάλμα",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Η ανάκτηση δεδομένων απέτυχε: {err}\n\nΑντιμετώπιση προβλημάτων: Δοκιμάστε να αποσυνδεθείτε και να συνδεθείτε ξανά.",
    "Followers": "Οπαδοί",
    "Following": "Εξής",
    "New Followers": "Νέοι ακόλουθοι",
    "Not Following Back": "Δεν ακολουθεί",
    "Lost Followers": "Χαμένοι ακόλουθοι",
    "Legal Disclaimer": "Νομική Αποποίηση Ευθύνης",
    "Unfollowed Users": "Χρήστες που δεν ακολουθούν",
    "Rate Us": "Αξιολογήστε μας",
    "Contact Us": "Επικοινωνήστε μαζί μας",
    "Remove Ads & Wait Times": "Κατάργηση διαφημίσεων και χρόνους αναμονής",
    "This box is currently under test.":
        "Αυτό το πλαίσιο είναι επί του παρόντος υπό δοκιμή.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Παρακολουθήστε τις ιστορίες μυστικά ή ζουμ φωτογραφίες προφίλ",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Παρακαλούμε συνδεθείτε για να παρακολουθήσετε κρυφά ιστορίες και να μεγεθύνετε τις φωτογραφίες προφίλ.",
    "Will be shown after the ad, please wait.":
        "Θα εμφανιστεί μετά τη διαφήμιση, περιμένετε.",
    "What would you like to do?": "Τι θα ήθελες να κάνεις;",
    "Enlarge profile photo": "Μεγέθυνση φωτογραφίας προφίλ",
    "Watch story secretly": "Παρακολουθήστε την ιστορία κρυφά",
    "No story data available.": "Δεν υπάρχουν διαθέσιμα δεδομένα ιστορίας.",
    "I HAVE READ AND AGREE": "ΕΧΩ ΔΙΑΒΑΣΕΙ ΚΑΙ ΣΥΜΦΩΝΩ",
    "Withdraw Consent": "Ανάκληση συγκατάθεσης",
    "Confirm": "Επιβεβαιώνω",
    "Your consent settings will be reset. Are you sure?":
        "Οι ρυθμίσεις συναίνεσής σας θα επαναφερθούν. Είσαι σίγουρος;",
    "Yes": "Ναί",
    "Cancel": "Ματαίωση",
    "Session verified, redirecting securely...":
        "Η συνεδρία επαληθεύτηκε, ανακατεύθυνση με ασφάλεια...",
    "Analysis complete ✅": "Η ανάλυση ολοκληρώθηκε ✅",
    "Purchases are not available right now. Please try again later.":
        "Οι αγορές δεν είναι διαθέσιμες αυτήν τη στιγμή. Δοκιμάστε ξανά αργότερα.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Η αγορά ολοκληρώθηκε, αλλά το Premium δεν είναι ακόμα ενεργό. Δοκιμάστε ξανά.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Καλώς ήρθατε στο Premium! Οι διαφημίσεις και οι χρόνοι αναμονής καταργούνται.",
    "Your Premium membership is active.":
        "Η συνδρομή σας Premium είναι ενεργή.",
    "Restore Purchases": "Επαναφορά αγορών",
    "RESTORE": "ΕΠΑΝΑΦΕΡΩ",
    "Restoring purchases...": "Επαναφορά αγορών...",
    "Purchases restored ✅": "Οι αγορές αποκαταστάθηκαν ✅",
    "No purchases to restore.": "Δεν υπάρχουν αγορές για επαναφορά.",
    "Restore failed: {err}": "Η επαναφορά απέτυχε: {err}",
    "Enter PIN": "Εισαγάγετε το PIN",
    "PIN accepted, timer reset ✅": "Αποδεκτό PIN, επαναφορά χρονοδιακόπτη ✅",
    "Invalid PIN": "Μη έγκυρο PIN",
    "OK": "ΕΝΤΑΞΕΙ",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Με τη λήψη και τη χρήση αυτής της εφαρμογής, κάθε Χρήστης θεωρείται ότι έχει διαβάσει, κατανοήσει και αποδεχθεί αμετάκλητα το παρακάτω κείμενο \"Όροι Χρήσης και Αποποίηση ευθυνών\" εκ των προτέρων:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Άρθρο 1: Απόρρητο δεδομένων και Αρχιτεκτονική τοπικής επεξεργασίας",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "Το VERDICT είναι λογισμικό από την πλευρά του πελάτη. Τα διαπιστευτήρια σύνδεσης του Χρήστη (όνομα χρήστη, κωδικός πρόσβασης, cookies περιόδου λειτουργίας) σε καμία περίπτωση δεν μεταδίδονται ή αποθηκεύονται σε εξωτερικό διακομιστή. Όλες οι δραστηριότητες επεξεργασίας δεδομένων πραγματοποιούνται αποκλειστικά εντός της προσωρινής μνήμης (RAM) και της τοπικής αποθήκευσης της συσκευής του Χρήστη. Η εφαρμογή λειτουργεί ως «περιτύλιγμα προγράμματος περιήγησης» που λειτουργεί μέσω της διεπαφής του Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Άρθρο 2: Κίνδυνοι πλατφόρμας τρίτων",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Το Instagram (Meta Platforms, Inc.) διατηρεί το δικαίωμα να περιορίσει τη χρήση λογισμικού τρίτων σύμφωνα με τις πολιτικές πλατφόρμας του. Όλοι οι κίνδυνοι, συμπεριλαμβανομένων, ενδεικτικά, των «μπλοκ ενεργειών», «περιορισμοί λογαριασμού», «σκιώδεις περιοχές» ή «κλείσιμο λογαριασμού» που ενδέχεται να προκύψουν από τη χρήση της εφαρμογής, ανήκουν αποκλειστικά στον Χρήστη. Ο προγραμματιστής VERDICT δεν μπορεί να θεωρηθεί υπεύθυνος για άμεσες ή έμμεσες ζημίες που προκύπτουν από τέτοιες διοικητικές κυρώσεις.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Άρθρο 3: Αποποίηση Εγγύησης και Περιορισμός Ευθύνης",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Αυτό το λογισμικό παρέχεται «ΩΣ ΕΧΕΙ» και «ΩΣ ΔΙΑΘΕΣΙΜΟ». Η 100% ακρίβεια, η συνέχεια ή η εμπορευσιμότητα των αποτελεσμάτων ανάλυσης που παρέχονται από το λογισμικό δεν είναι εγγυημένη. Ο Χρήστης αναγνωρίζει ότι τυχόν αποτελέσματα που προκύπτουν από νομικές ή εμπορικές συναλλαγές που βασίζονται σε δεδομένα εφαρμογής είναι δική του ευθύνη. και δηλώνει και αναλαμβάνει να κρατήσει τον προγραμματιστή αβλαβή από όλες τις αξιώσεις, αγωγές και παράπονα.",
    "Article 4: Intellectual Property and Independence Notice":
        "Άρθρο 4: Ανακοίνωση Πνευματικής Ιδιοκτησίας και Ανεξαρτησίας",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "Το VERDICT είναι ένα ανεξάρτητο έργο προγραμματιστή. Οι επωνυμίες «Instagram», «Facebook» και «Meta» είναι σήματα κατατεθέντα της Meta Platforms, Inc. Αυτή η εφαρμογή δεν έχει εμπορική συνεργασία, συμφωνία χορηγίας ή επίσημη σχέση με τις προαναφερθείσες εταιρείες.",
    "Article 5: Service Continuity and Platform Changes":
        "Άρθρο 5: Συνέχεια υπηρεσίας και αλλαγές πλατφόρμας",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Θεμελιώδεις αλλαγές στο API του Instagram ή στην υποδομή ιστού ενδέχεται να προκαλέσουν την απώλεια της λειτουργικότητάς της εν μέρει ή πλήρως. Ο προγραμματιστής δεν δεσμεύεται να ενημερώσει την εφαρμογή ή να διατηρήσει την υπηρεσία ως απάντηση σε τέτοιες αλλαγές υποδομής, οι οποίες θεωρούνται \"ανωτέρα βία\".",
    "Analysis complete, results will be shown after the ad.":
        "Η ανάλυση ολοκληρώθηκε, τα αποτελέσματα θα εμφανιστούν μετά τη διαφήμιση.",
    "Analysis failed": "Η ανάλυση απέτυχε",
    "Reason: {reason}": "Αιτία: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Συμβουλή: Η αποσύνδεση και η επανασύνδεση μπορεί να βοηθήσει.",
    "Quick check: Counts are the same. No changes detected.":
        "Γρήγορος έλεγχος: Οι μετρήσεις είναι οι ίδιες. Δεν εντοπίστηκαν αλλαγές.",
    "Daily Metrics": "Ημερήσιες μετρήσεις",
    "Active users": "Ενεργοί χρήστες",
    "Daily queries": "Καθημερινές ερωτήσεις",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Η φόρτωση δεδομένων διακόπηκε: τα δεδομένα ακολούθων δεν είναι πλήρη ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Η φόρτωση δεδομένων διακόπηκε: τα ακόλουθα δεδομένα ήταν ελλιπή ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Η φόρτωση δεδομένων διακόπηκε: Το Instagram επέστρεψε άδεια δεδομένα.",
    "Data loading stopped due to an unexpected error.":
        "Η φόρτωση δεδομένων σταμάτησε λόγω απροσδόκητου σφάλματος.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Το Instagram επέστρεψε μια προειδοποίηση αυτοματοποιημένης συμπεριφοράς. Σταματήσαμε τη λήψη δεδομένων για ασφάλεια.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Το Instagram ζήτησε επαλήθευση ασφαλείας. Επαληθεύστε στην εφαρμογή Instagram και δοκιμάστε ξανά.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Η συνεδρία δεν είναι έγκυρη ή περιμένει επαλήθευση. Παρακαλούμε συνδεθείτε ξανά.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Εστάλησαν πάρα πολλά αιτήματα. Η φόρτωση δεδομένων διακόπηκε για ασφάλεια.",
    "Data loading could not complete due to a connection issue.":
        "Η φόρτωση δεδομένων δεν ήταν δυνατή λόγω προβλήματος σύνδεσης.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Το Instagram επέστρεψε ένα σφάλμα (HTTP {code}). Η φόρτωση δεδομένων διακόπηκε.",
    "Instagram security verification is required (story data could not be fetched).":
        "Απαιτείται επαλήθευση ασφαλείας του Instagram (δεν ήταν δυνατή η ανάκτηση δεδομένων ιστορίας).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Δεν ήταν δυνατή η ανάκτηση δεδομένων ιστορίας. Συνήθως αυτό προκαλείται από επαλήθευση Instagram, προσωρινούς περιορισμούς API ή διακοπή σύνδεσης. Δοκιμάστε ξανά σε 2-3 λεπτά.",
    "Could not fetch story data. Please try again shortly.":
        "Δεν ήταν δυνατή η ανάκτηση δεδομένων ιστορίας. Δοκιμάστε ξανά σύντομα.",
    "Secret Mode": "Μυστική λειτουργία",
    "Starting VERDICT...": "Έναρξη ετυμηγορίας...",
    "DID YOU KNOW?": "ΓΝΩΡΙΖΑΤΕ;",
    "Estimated time left: {time}": "Εκτιμώμενος χρόνος που απομένει: {time}",
    "Estimating remaining time...": "Εκτίμηση του υπολειπόμενου χρόνου...",
    "LOG OUT": "LOG OUT",
    "Open Profile": "Ανοίξτε το προφίλ",
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
    "Analysis Time!": "זמן ניתוח!",
    "CLOSE": "לִסְגוֹר",
    "SYSTEM UNDER MAINTENANCE": "מערכת תחת תחזוקה",
    "Bio Planner": "ביו מתכנן",
    "Store link not set.": "קישור לחנות לא הוגדר.",
    "Invalid store link.": "קישור לא חוקי לחנות.",
    "Could not open the link.": "לא ניתן היה לפתוח את הקישור.",
    "Please try again.": "אנא נסה שוב.",
    "Show error": "הצג שגיאה",
    "Exception": "חֲרִיגָה",
    "Load error": "שגיאת טעינה",
    "Code": "קוד",
    "Timeout": "פסק זמן",
    "REST probe failed: missing auth.": "בדיקת REST נכשלה: אישור חסר.",
    "REST probe success (Firestore endpoint reachable).":
        "הצלחת בדיקה REST (ניתן להגיע לנקודת הקצה של Firestore).",
    "REST probe failed (check logs).": "בדיקת REST נכשלה (בדוק יומנים).",
    "Firebase Auth probe failed.": "בדיקת Firebase Auth נכשלה.",
    "Firebase Auth probe success.": "בדיקת Firebase Auth הצליחה.",
    "Firebase token probe failed.": "בדיקת אסימון Firebase נכשלה.",
    "CRITICAL DIAGNOSTIC ERROR": "שגיאת אבחון קריטית",
    "COPY": "לְהַעְתִיק",
    "OPEN LOGS": "פתח יומנים",
    "Firebase": "Firebase",
    "Store": "חנות",
    "Copy all": "תעתיק הכל",
    "Close": "לִסְגוֹר",
    "Auth Probe": "Auth Probe",
    "Write Test": "כתוב מבחן",
    "REST Probe": "בדיקת מנוחה",
    "Restore Test": "שחזור בדיקה",
    "Firebase auth error: user verification failed.":
        "שגיאת אימות Firebase: אימות המשתמש נכשל.",
    "Firestore test write successful.": "מבחן Firestore כתיבה מוצלחת.",
    "Firestore test failed.": "בדיקת Firestore נכשלה.",
    "Firestore auth error: user verification failed.":
        "שגיאת אישור Firestore: אימות המשתמש נכשל.",
    "Firestore counter write failed.": "כתיבה נגדית של Firestore נכשלה.",
    "Firestore auth missing: ig_users write blocked.":
        "אישור Firestore חסר: ig_users כתיבה חסומה.",
    "Firestore ig_users write failed.": "כתיבה של Firestore ig_users נכשלה.",
    "User": "מִשׁתַמֵשׁ",
    "Opening consent form...": "פותח טופס הסכמה...",
    "Your consent preference was updated.": "העדפת ההסכמה שלך עודכנה.",
    "Consent update failed. Please try again.":
        "עדכון ההסכמה נכשל. אנא נסה שוב.",
    "Your account is blocked": "החשבון שלך חסום",
    "Access is restricted for this account.": "הגישה מוגבלת לחשבון זה.",
    "Starting purchase...": "מתחיל ברכישה...",
    "Purchase cancelled.": "הרכישה בוטלה.",
    "Premium active ✅ Ads and wait times are disabled.":
        "פרימיום פעיל ✅ מודעות וזמני המתנה מושבתים.",
    "Purchase failed. Please try again.": "הרכישה נכשלה. אנא נסה שוב.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "נדרש אימות הפעלה. אנא אמת את חשבונך באפליקציית אינסטגרם ונסה שוב.",
    "Instagram returned no data.": "אינסטגרם לא החזירה נתונים.",
    "Session verification failed. Please log in again.":
        "אימות הפגישה נכשל. נא להיכנס שוב.",
    "Open Instagram": "פתח את אינסטגרם",
    "Instagram message": "הודעת אינסטגרם",
    "Loading stories...": "טוען סיפורים...",
    "No data": "אין נתונים",
    "NEW": "חָדָשׁ",
    "Login": "כְּנִיסָה לַמַעֲרֶכֶת",
    "Session verified, redirecting...": "הפעלה מאומתת, מפנה מחדש...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "חלל מודעה",
    "Admin mode active": "מצב ניהול פעיל",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "אנו מתפתחים מדי יום כדי לספק לך חוויה טובה יותר. המשוב שלך חשוב לנו - נשמח לשמוע ממך!",
    "Please log in to start the analysis.": "אנא היכנס כדי להתחיל בניתוח.",
    "Welcome, {username}": "ברוך הבא, {username}",
    "REFRESH DATA": "רענון נתונים",
    "LOG IN WITH INSTAGRAM": "התחבר עם אינסטגרם",
    "Analyzing data...\nThis might take a moment.":
        "מנתח נתונים...\nזה עלול לקחת רגע.",
    "Processing data...\nAlmost done.": "מעבד נתונים...\nכמעט גמור.",
    "Loading ad...\nPlease wait.": "טוען מודעה...\nאנא המתן.",
    "Google ad warning: {reason}": "אזהרת מודעות Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "כל הניתוח מעובד באופן מאובטח באופן מקומי במכשיר שלך.",
    "Total analyses today: {count}": "סך הניתוחים היום: {count}",
    "Next analysis": "הניתוח הבא",
    "Ready to scan.": "מוכן לסריקה.",
    "Analysis available now": "ניתוח זמין כעת",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "ניתוח זמין כעת, אך הפעלת ניתוחים גב אל גב עלולה לסכן את חשבונך.",
    "Please wait": "אנא המתן",
    "Warning": "אַזהָרָה",
    "Next analysis: {time}": "הניתוח הבא: {time}",
    "WATCH AD AND START ANALYSIS": "צפה במודעה והתחל בניתוח",
    "START ANALYSIS": "התחל ניתוח",
    "Start analysis?": "להתחיל ניתוח?",
    "Reset App Data": "אפס את נתוני האפליקציה",
    "This will wipe all local data and session cookies. Are you sure?":
        "פעולה זו תמחק את כל הנתונים המקומיים וקובצי ה-cookie של הפעלה. אתה בטוח?",
    "CANCEL": "לְבַטֵל",
    "DELETE": "לִמְחוֹק",
    "Error": "שְׁגִיאָה",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "אחזור הנתונים נכשל: {err}\n\nפתרון בעיות: נסה להתנתק ולהיכנס שוב.",
    "Followers": "עוקבים",
    "Following": "הַבָּא",
    "New Followers": "עוקבים חדשים",
    "Not Following Back": "לא עוקב בחזרה",
    "Lost Followers": "עוקבים אבודים",
    "Legal Disclaimer": "כתב ויתור משפטי",
    "Unfollowed Users": "משתמשים שלא עוקבים אחריהם",
    "Rate Us": "דרג אותנו",
    "Contact Us": "צור קשר",
    "Remove Ads & Wait Times": "הסר מודעות וזמני המתנה",
    "This box is currently under test.": "תיבה זו נמצאת כעת בבדיקה.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "צפה בסיפורים בסתר או הגדל תמונות פרופיל",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "אנא היכנס כדי לצפות בסיפורים בסתר ולהגדיל תמונות פרופיל.",
    "Will be shown after the ad, please wait.": "יוצג לאחר המודעה, אנא המתן.",
    "What would you like to do?": "מה היית רוצה לעשות?",
    "Enlarge profile photo": "הגדל את תמונת הפרופיל",
    "Watch story secretly": "צפו בסיפור בסתר",
    "No story data available.": "אין נתוני סיפור זמינים.",
    "I HAVE READ AND AGREE": "קראתי והסכמתי",
    "Withdraw Consent": "בטל את ההסכמה",
    "Confirm": "לְאַשֵׁר",
    "Your consent settings will be reset. Are you sure?":
        "הגדרות ההסכמה שלך יאופסו. אתה בטוח?",
    "Yes": "כֵּן",
    "Cancel": "לְבַטֵל",
    "Session verified, redirecting securely...":
        "הפעלה מאומתת, מפנה מחדש בצורה מאובטחת...",
    "Analysis complete ✅": "הניתוח הושלם ✅",
    "Purchases are not available right now. Please try again later.":
        "רכישות אינן זמינות כעת. אנא נסה שוב מאוחר יותר.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "הרכישה הושלמה, אך ה-Premium עדיין לא פעילה. אנא נסה שוב.",
    "Welcome to Premium! Ads and wait times are removed.":
        "ברוכים הבאים ל-Premium! מודעות וזמני המתנה מוסרים.",
    "Your Premium membership is active.": "מנוי הפרימיום שלך פעיל.",
    "Restore Purchases": "שחזור רכישות",
    "RESTORE": "לְשַׁחְזֵר",
    "Restoring purchases...": "משחזר רכישות...",
    "Purchases restored ✅": "רכישות שוחזרו ✅",
    "No purchases to restore.": "אין רכישות לשחזור.",
    "Restore failed: {err}": "השחזור נכשל: {err}",
    "Enter PIN": "הזן PIN",
    "PIN accepted, timer reset ✅": "PIN מקובל, איפוס טיימר ✅",
    "Invalid PIN": "PIN לא חוקי",
    "OK": "בְּסֵדֶר",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "על ידי הורדה ושימוש באפליקציה זו, כל משתמש נחשב כמי שקרא, הבין וקיבל באופן בלתי חוזר את הטקסט של \"תנאי השימוש וכתב ויתור\" להלן מראש:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "מאמר 1: פרטיות נתונים וארכיטקטורת עיבוד מקומי",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT היא תוכנה 'צד לקוח'. אישורי הכניסה של המשתמש (שם משתמש, סיסמה, קובצי Cookie) בשום פנים ואופן לא מועברים או מאוחסנים בשרת חיצוני. כל פעילויות עיבוד הנתונים מתרחשות אך ורק בתוך הזיכרון הזמני (RAM) והאחסון המקומי של המכשיר של המשתמש. האפליקציה מתפקדת כ'מעטפת דפדפן' הפועלת על פני ממשק אינסטגרם.",
    "Article 2: Third-Party Platform Risks":
        "סעיף 2: סיכוני פלטפורמה של צד שלישי",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "אינסטגרם (Meta Platforms, Inc.) שומרת לעצמה את הזכות להגביל את השימוש בתוכנת צד שלישי בהתאם למדיניות הפלטפורמה שלה. כל הסיכונים, לרבות אך לא רק 'חסימות פעולה', 'הגבלות חשבון', 'shadowbans' או 'סגירת חשבונות' שעלולים לנבוע מהשימוש באפליקציה, שייכים בלעדית למשתמש. מפתח VERDICT אינו יכול לשאת באחריות לכל נזק ישיר או עקיף הנובע מסנקציות מנהליות מסוג זה.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "סעיף 3: כתב ויתור אחריות והגבלת אחריות",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "תוכנה זו מסופקת 'כפי שהיא' ו'כפי שהיא זמינה'. הדיוק, ההמשכיות או הסחירות של 100% של תוצאות הניתוח המסופקות על ידי התוכנה אינם מובטחים. המשתמש מאשר שכל תוצאות הנובעות מעסקאות משפטיות או מסחריות המבוססות על נתוני אפליקציה הן באחריותו בלבד; ומצהירה ומתחייבת לשמור על היזם מכל תביעות, תביעות ותלונות.",
    "Article 4: Intellectual Property and Independence Notice":
        "סעיף 4: הודעת קניין רוחני ועצמאות",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT הוא פרויקט מפתח עצמאי. המותגים 'Instagram', 'Facebook' ו-'Meta' הם סימנים מסחריים רשומים של Meta Platforms, Inc. לאפליקציה זו אין שותפות מסחרית, הסכם חסות או זיקה רשמית עם החברות הנזכרות לעיל.",
    "Article 5: Service Continuity and Platform Changes":
        "סעיף 5: המשכיות שירות ושינויים בפלטפורמה",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "שינויים מהותיים ב-Instagram API או בתשתית האינטרנט עלולים לגרום לאפליקציה לאבד את הפונקציונליות שלה באופן חלקי או מלא. היזם אינו מתחייב לעדכן את האפליקציה או לתחזק את השירות בתגובה לשינויים תשתיתיים כאמור, הנחשבים ל\"כוח עליון\".",
    "Analysis complete, results will be shown after the ad.":
        "הניתוח הושלם, התוצאות יוצגו לאחר המודעה.",
    "Analysis failed": "הניתוח נכשל",
    "Reason: {reason}": "סיבה: {reason}",
    "Tip: Logging out and logging back in may help.":
        "טיפ: יציאה והתחברות חוזרת עשויות לעזור.",
    "Quick check: Counts are the same. No changes detected.":
        "בדיקה מהירה: הספירות זהות. לא זוהו שינויים.",
    "Daily Metrics": "מדדים יומיים",
    "Active users": "משתמשים פעילים",
    "Daily queries": "שאילתות יומיות",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "טעינת הנתונים נקטעה: נתוני העוקבים אינם שלמים ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "טעינת הנתונים נקטעה: הנתונים הבאים לא שלמים ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "טעינת הנתונים נקטעה: אינסטגרם החזירה נתונים ריקים.",
    "Data loading stopped due to an unexpected error.":
        "טעינת הנתונים הופסקה עקב שגיאה בלתי צפויה.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "אינסטגרם החזירה אזהרת התנהגות אוטומטית. הפסקנו להביא נתונים ליתר ביטחון.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "אינסטגרם ביקשה אימות אבטחה. אמת באפליקציית אינסטגרם ונסה שוב.",
    "Session is invalid or waiting for verification. Please log in again.":
        "ההפעלה לא חוקית או ממתינה לאימות. נא להיכנס שוב.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "נשלחו יותר מדי בקשות. טעינת הנתונים נקטעה ליתר ביטחון.",
    "Data loading could not complete due to a connection issue.":
        "לא ניתן היה להשלים את טעינת הנתונים עקב בעיית חיבור.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "אינסטגרם החזירה שגיאה (HTTP {code}). טעינת הנתונים נקטעה.",
    "Instagram security verification is required (story data could not be fetched).":
        "נדרש אימות אבטחה של אינסטגרם (לא ניתן היה לשלוף נתוני סיפור).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "לא ניתן היה לאחזר נתוני סיפור. בדרך כלל זה נגרם על ידי אימות אינסטגרם, הגבלות API זמניות או הפרעה בחיבור. אנא נסה שוב בעוד 2-3 דקות.",
    "Could not fetch story data. Please try again shortly.":
        "לא ניתן היה להביא נתוני סיפור. אנא נסה שוב בקרוב.",
    "Secret Mode": "מצב סודי",
    "Starting VERDICT...": "מתחיל את פסק הדין...",
    "DID YOU KNOW?": "האם ידעת?",
    "Estimated time left: {time}": "זמן משוער שנותר: {time}",
    "Estimating remaining time...": "אומדן הזמן שנותר...",
    "LOG OUT": "צא",
    "Open Profile": "פתח את הפרופיל",
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
    "Analysis Time!": "Masa Analisis!",
    "CLOSE": "TUTUP",
    "SYSTEM UNDER MAINTENANCE": "SISTEM DALAM PENYELENGGARAAN",
    "Bio Planner": "Perancang Bio",
    "Store link not set.": "Pautan kedai tidak ditetapkan.",
    "Invalid store link.": "Pautan kedai tidak sah.",
    "Could not open the link.": "Tidak dapat membuka pautan.",
    "Please try again.": "Sila cuba lagi.",
    "Show error": "Tunjukkan ralat",
    "Exception": "Pengecualian",
    "Load error": "Ralat memuatkan",
    "Code": "Kod",
    "Timeout": "tamat masa",
    "REST probe failed: missing auth.":
        "Siasatan REST gagal: tiada pengesahan.",
    "REST probe success (Firestore endpoint reachable).":
        "Kejayaan siasatan REST (titik akhir Firestore boleh dicapai).",
    "REST probe failed (check logs).": "Siasatan REST gagal (semak log).",
    "Firebase Auth probe failed.": "Siasatan Firebase Auth gagal.",
    "Firebase Auth probe success.": "Kejayaan siasatan Firebase Auth.",
    "Firebase token probe failed.": "Siasatan token Firebase gagal.",
    "CRITICAL DIAGNOSTIC ERROR": "RALAT DIAGNOSTIK KRITIKAL",
    "COPY": "SALINAN",
    "OPEN LOGS": "BUKA LOG",
    "Firebase": "Firebase",
    "Store": "Kedai",
    "Copy all": "Salin semua",
    "Close": "tutup",
    "Auth Probe": "Siasatan Kebenaran",
    "Write Test": "Ujian Tulis",
    "REST Probe": "Siasatan REHAT",
    "Restore Test": "Pulihkan Ujian",
    "Firebase auth error: user verification failed.":
        "Ralat auth Firebase: pengesahan pengguna gagal.",
    "Firestore test write successful.": "Ujian tulis Firestore berjaya.",
    "Firestore test failed.": "Ujian Firestore gagal.",
    "Firestore auth error: user verification failed.":
        "Ralat auth Firestore: pengesahan pengguna gagal.",
    "Firestore counter write failed.": "Tulisan kaunter Firestore gagal.",
    "Firestore auth missing: ig_users write blocked.":
        "Pengesahan Firestore tiada: tulis ig_users disekat.",
    "Firestore ig_users write failed.": "Penulisan ig_users Firestore gagal.",
    "User": "pengguna",
    "Opening consent form...": "Membuka borang kebenaran...",
    "Your consent preference was updated.":
        "Pilihan persetujuan anda telah dikemas kini.",
    "Consent update failed. Please try again.":
        "Kemas kini persetujuan gagal. Sila cuba lagi.",
    "Your account is blocked": "Akaun anda disekat",
    "Access is restricted for this account.":
        "Akses adalah terhad untuk akaun ini.",
    "Starting purchase...": "Memulakan pembelian...",
    "Purchase cancelled.": "Pembelian dibatalkan.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktif ✅ Iklan dan masa menunggu dilumpuhkan.",
    "Purchase failed. Please try again.": "Pembelian gagal. Sila cuba lagi.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Pengesahan sesi diperlukan. Sila sahkan akaun anda dalam apl Instagram dan cuba lagi.",
    "Instagram returned no data.": "Instagram tidak mengembalikan data.",
    "Session verification failed. Please log in again.":
        "Pengesahan sesi gagal. Sila log masuk semula.",
    "Open Instagram": "Buka Instagram",
    "Instagram message": "Mesej Instagram",
    "Loading stories...": "Memuatkan cerita...",
    "No data": "Tiada data",
    "NEW": "BARU",
    "Login": "Log masuk",
    "Session verified, redirecting...": "Sesi disahkan, mengubah hala...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "RUANG IKLAN",
    "Admin mode active": "Mod pentadbir aktif",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Kami berkembang setiap hari untuk memberikan anda pengalaman yang lebih baik. Maklum balas anda sangat berharga bagi kami—kami ingin mendengar daripada anda!",
    "Please log in to start the analysis.":
        "Sila log masuk untuk memulakan analisis.",
    "Welcome, {username}": "Selamat datang, {username}",
    "REFRESH DATA": "SEMAKAN DATA",
    "LOG IN WITH INSTAGRAM": "LOG MASUK DENGAN INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Menganalisis data...\nIni mungkin mengambil sedikit masa.",
    "Processing data...\nAlmost done.": "Memproses data...\nhampir selesai.",
    "Loading ad...\nPlease wait.": "Memuatkan iklan...\nSila tunggu.",
    "Google ad warning: {reason}": "Amaran iklan Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Semua analisis diproses dengan selamat secara setempat pada peranti anda.",
    "Total analyses today: {count}": "Jumlah analisis hari ini: {count}",
    "Next analysis": "Analisis seterusnya",
    "Ready to scan.": "Bersedia untuk mengimbas.",
    "Analysis available now": "Analisis tersedia sekarang",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analisis tersedia sekarang, tetapi menjalankan analisis secara berturut-turut boleh menyebabkan akaun anda berisiko.",
    "Please wait": "Sila tunggu",
    "Warning": "Amaran",
    "Next analysis: {time}": "Analisis seterusnya: {time}",
    "WATCH AD AND START ANALYSIS": "LIHAT IKLAN DAN MULAKAN ANALISIS",
    "START ANALYSIS": "MULAKAN ANALISIS",
    "Start analysis?": "Mulakan analisis?",
    "Reset App Data": "Tetapkan Semula Data Apl",
    "This will wipe all local data and session cookies. Are you sure?":
        "Ini akan memadamkan semua data tempatan dan kuki sesi. Adakah anda pasti?",
    "CANCEL": "BATALKAN",
    "DELETE": "PADAM",
    "Error": "ralat",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Pendapatan data gagal: {err}\n\nSelesaikan masalah: Cuba log keluar dan log masuk semula.",
    "Followers": "Pengikut",
    "Following": "Mengikuti",
    "New Followers": "Pengikut Baru",
    "Not Following Back": "Tidak Mengikut Belakang",
    "Lost Followers": "Pengikut Hilang",
    "Legal Disclaimer": "Penafian Undang-undang",
    "Unfollowed Users": "Pengguna yang tidak mengikut jejak",
    "Rate Us": "Nilaikan Kami",
    "Contact Us": "Hubungi Kami",
    "Remove Ads & Wait Times": "Alih Keluar Iklan & Masa Tunggu",
    "This box is currently under test.": "Kotak ini sedang diuji.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Tonton Cerita Secara Rahsia atau Zum Foto Profil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Sila log masuk untuk menonton cerita secara rahsia dan besarkan foto profil.",
    "Will be shown after the ad, please wait.":
        "Akan dipaparkan selepas iklan, sila tunggu.",
    "What would you like to do?": "Apa yang anda ingin lakukan?",
    "Enlarge profile photo": "Besarkan foto profil",
    "Watch story secretly": "Tonton cerita secara rahsia",
    "No story data available.": "Tiada data cerita tersedia.",
    "I HAVE READ AND AGREE": "SAYA TELAH BACA DAN SETUJU",
    "Withdraw Consent": "Tarik Keizinan",
    "Confirm": "sahkan",
    "Your consent settings will be reset. Are you sure?":
        "Tetapan persetujuan anda akan ditetapkan semula. Adakah anda pasti?",
    "Yes": "ya",
    "Cancel": "Batal",
    "Session verified, redirecting securely...":
        "Sesi disahkan, mengubah hala dengan selamat...",
    "Analysis complete ✅": "Analisis lengkap ✅",
    "Purchases are not available right now. Please try again later.":
        "Pembelian tidak tersedia sekarang. Sila cuba lagi kemudian.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Pembelian selesai, tetapi Premium belum aktif lagi. Sila cuba lagi.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Selamat datang ke Premium! Iklan dan masa menunggu dialih keluar.",
    "Your Premium membership is active.": "Keahlian Premium anda aktif.",
    "Restore Purchases": "Pulihkan Pembelian",
    "RESTORE": "MEMULIHKAN",
    "Restoring purchases...": "Memulihkan pembelian...",
    "Purchases restored ✅": "Pembelian dipulihkan ✅",
    "No purchases to restore.": "Tiada pembelian untuk dipulihkan.",
    "Restore failed: {err}": "Pemulihan gagal: {err}",
    "Enter PIN": "Masukkan PIN",
    "PIN accepted, timer reset ✅": "PIN diterima, tetapan semula pemasa ✅",
    "Invalid PIN": "PIN tidak sah",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Dengan memuat turun dan menggunakan aplikasi ini, setiap Pengguna dianggap telah membaca, memahami dan menerima teks \"Syarat Penggunaan dan Penafian\" di bawah terlebih dahulu:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artikel 1: Privasi Data dan Seni Bina Pemprosesan Setempat",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT ialah perisian 'pihak pelanggan'. Bukti kelayakan log masuk Pengguna (nama pengguna, kata laluan, kuki sesi) tidak dihantar ke atau disimpan pada pelayan luaran dalam apa jua keadaan. Semua aktiviti pemprosesan data berlaku secara eksklusif dalam memori sementara (RAM) dan storan tempatan peranti Pengguna. Aplikasi ini berfungsi sebagai 'pembungkus pelayar' yang beroperasi melalui antara muka Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Artikel 2: Risiko Platform Pihak Ketiga",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) berhak untuk menyekat penggunaan perisian pihak ketiga mengikut dasar platformnya. Semua risiko, termasuk tetapi tidak terhad kepada 'blok tindakan', 'sekatan akaun', 'shadowbans' atau 'penutupan akaun' yang mungkin timbul daripada penggunaan aplikasi, adalah milik Pengguna secara eksklusif. Pemaju VERDICT tidak boleh dipertanggungjawabkan untuk sebarang kerosakan langsung atau tidak langsung akibat daripada sekatan pentadbiran tersebut.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artikel 3: Penafian Waranti dan Had Liabiliti",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Perisian ini disediakan 'SEBAGAIMANA ADANYA' dan 'SEBAGAIMANA TERSEDIA'. Ketepatan 100%, kesinambungan atau kebolehdagangan keputusan analisis yang disediakan oleh perisian tidak dijamin. Pengguna mengakui bahawa sebarang keputusan yang timbul daripada transaksi undang-undang atau komersial berdasarkan data aplikasi adalah tanggungjawab mereka sendiri; dan mengisytiharkan dan berjanji untuk memastikan pemaju tidak berbahaya daripada semua tuntutan, tuntutan mahkamah dan aduan.",
    "Article 4: Intellectual Property and Independence Notice":
        "Perkara 4: Harta Intelek dan Notis Kemerdekaan",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT ialah projek pembangun bebas. Jenama 'Instagram', 'Facebook' dan 'Meta' ialah tanda dagangan berdaftar Meta Platforms, Inc. Aplikasi ini tidak mempunyai perkongsian komersial, perjanjian penajaan atau gabungan rasmi dengan syarikat yang disebutkan di atas.",
    "Article 5: Service Continuity and Platform Changes":
        "Artikel 5: Kesinambungan Perkhidmatan dan Perubahan Platform",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Perubahan asas kepada API Instagram atau infrastruktur web boleh menyebabkan aplikasi kehilangan fungsinya sebahagian atau sepenuhnya. Pembangun tidak membuat komitmen untuk mengemas kini aplikasi atau mengekalkan perkhidmatan sebagai tindak balas kepada perubahan infrastruktur sedemikian, yang dianggap \"force majeure\".",
    "Analysis complete, results will be shown after the ad.":
        "Analisis selesai, keputusan akan ditunjukkan selepas iklan.",
    "Analysis failed": "Analisis gagal",
    "Reason: {reason}": "Sebab: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Petua: Log keluar dan log masuk semula boleh membantu.",
    "Quick check: Counts are the same. No changes detected.":
        "Semakan pantas: Kiraan adalah sama. Tiada perubahan dikesan.",
    "Daily Metrics": "Metrik Harian",
    "Active users": "Pengguna aktif",
    "Daily queries": "Pertanyaan harian",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Pemuatan data telah terganggu: data pengikut tidak lengkap ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Pemuatan data telah terganggu: data berikut tidak lengkap ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Pemuatan data terganggu: Instagram mengembalikan data kosong.",
    "Data loading stopped due to an unexpected error.":
        "Pemuatan data dihentikan kerana ralat yang tidak dijangka.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram mengembalikan amaran tingkah laku automatik. Kami berhenti mengambil data untuk keselamatan.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram meminta pengesahan keselamatan. Sahkan dalam apl Instagram dan cuba lagi.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sesi tidak sah atau menunggu pengesahan. Sila log masuk semula.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Terlalu banyak permintaan telah dihantar. Pemuatan data telah terganggu untuk keselamatan.",
    "Data loading could not complete due to a connection issue.":
        "Pemuatan data tidak dapat diselesaikan kerana masalah sambungan.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram mengembalikan ralat (HTTP {code}). Pemuatan data telah terganggu.",
    "Instagram security verification is required (story data could not be fetched).":
        "Pengesahan keselamatan Instagram diperlukan (data cerita tidak dapat diambil).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Data cerita tidak dapat diambil. Biasanya ini disebabkan oleh pengesahan Instagram, sekatan API sementara atau gangguan sambungan. Sila cuba lagi dalam 2-3 minit.",
    "Could not fetch story data. Please try again shortly.":
        "Tidak dapat mengambil data cerita. Sila cuba sebentar lagi.",
    "Secret Mode": "Mod Rahsia",
    "Starting VERDICT...": "Memulakan VERDICT...",
    "DID YOU KNOW?": "TAHUKAH ANDA?",
    "Estimated time left: {time}": "Anggaran masa yang tinggal: {time}",
    "Estimating remaining time...": "Anggarkan baki masa...",
    "LOG OUT": "LOG KELUAR",
    "Open Profile": "Buka Profil",
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
    "Analysis Time!": "Analyse tid!",
    "CLOSE": "LUKKE",
    "SYSTEM UNDER MAINTENANCE": "SYSTEM UNDER VEDLIKEHOLD",
    "Bio Planner": "Bioplanlegger",
    "Store link not set.": "Butikklink ikke angitt.",
    "Invalid store link.": "Ugyldig butikklink.",
    "Could not open the link.": "Kunne ikke åpne linken.",
    "Please try again.": "Vennligst prøv igjen.",
    "Show error": "Vis feil",
    "Exception": "Unntak",
    "Load error": "Last feil",
    "Code": "Kode",
    "Timeout": "Tidsavbrudd",
    "REST probe failed: missing auth.": "REST-sonde mislyktes: mangler auth.",
    "REST probe success (Firestore endpoint reachable).":
        "REST-probe suksess (Firestore-endepunkt kan nås).",
    "REST probe failed (check logs).": "REST-sonde mislyktes (sjekk logger).",
    "Firebase Auth probe failed.": "Firebase Auth-sonde mislyktes.",
    "Firebase Auth probe success.": "Firebase Auth-sonde er vellykket.",
    "Firebase token probe failed.": "Firebase-tokensonde mislyktes.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITISK DIAGNOSTISK FEIL",
    "COPY": "KOPIERE",
    "OPEN LOGS": "ÅPNE LOGGER",
    "Firebase": "Firebase",
    "Store": "Lager",
    "Copy all": "Kopier alle",
    "Close": "Lukke",
    "Auth Probe": "Auth Probe",
    "Write Test": "Skriv test",
    "REST Probe": "HVILE sonde",
    "Restore Test": "Gjenopprett test",
    "Firebase auth error: user verification failed.":
        "Firebase-autentiseringsfeil: brukerbekreftelse mislyktes.",
    "Firestore test write successful.": "Firestore testskriving vellykket.",
    "Firestore test failed.": "Firestore-testen mislyktes.",
    "Firestore auth error: user verification failed.":
        "Firestore-autentiseringsfeil: brukerbekreftelse mislyktes.",
    "Firestore counter write failed.": "Firestore-tellerskriving mislyktes.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore-autentisering mangler: ig_users skrive blokkert.",
    "Firestore ig_users write failed.":
        "Firestore ig_users-skriving mislyktes.",
    "User": "Bruker",
    "Opening consent form...": "Åpner samtykkeskjema...",
    "Your consent preference was updated.":
        "Samtykkespreferansen din ble oppdatert.",
    "Consent update failed. Please try again.":
        "Samtykkeoppdatering mislyktes. Vennligst prøv igjen.",
    "Your account is blocked": "Kontoen din er blokkert",
    "Access is restricted for this account.":
        "Tilgangen er begrenset for denne kontoen.",
    "Starting purchase...": "Begynner kjøpet...",
    "Purchase cancelled.": "Kjøp kansellert.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktiv ✅ Annonser og ventetider er deaktivert.",
    "Purchase failed. Please try again.":
        "Kjøpet mislyktes. Vennligst prøv igjen.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Sesjonsbekreftelse er nødvendig. Bekreft kontoen din i Instagram-appen og prøv igjen.",
    "Instagram returned no data.": "Instagram returnerte ingen data.",
    "Session verification failed. Please log in again.":
        "Øktbekreftelse mislyktes. Logg på igjen.",
    "Open Instagram": "Åpne Instagram",
    "Instagram message": "Instagram-melding",
    "Loading stories...": "Laster inn historier...",
    "No data": "Ingen data",
    "NEW": "NY",
    "Login": "Logg inn",
    "Session verified, redirecting...": "Økt bekreftet, omdirigerer...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ANNONSEPLASS",
    "Admin mode active": "Admin-modus aktiv",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Vi utvikler oss hver dag for å gi deg en bedre opplevelse. Tilbakemeldingen din er verdifull for oss – vi vil gjerne høre fra deg!",
    "Please log in to start the analysis.": "Logg inn for å starte analysen.",
    "Welcome, {username}": "Velkommen, {username}",
    "REFRESH DATA": "OPPDATERT DATA",
    "LOG IN WITH INSTAGRAM": "LOGG INN MED INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analyserer data ...\nDette kan ta et øyeblikk.",
    "Processing data...\nAlmost done.": "Behandler data...\nNesten ferdig.",
    "Loading ad...\nPlease wait.": "Laster inn annonse ...\nVennligst vent.",
    "Google ad warning: {reason}": "Google-annonseadvarsel: {reason}",
    "All analysis is securely processed locally on your device.":
        "All analyse behandles sikkert lokalt på enheten din.",
    "Total analyses today: {count}": "Totale analyser i dag: {count}",
    "Next analysis": "Neste analyse",
    "Ready to scan.": "Klar til å skanne.",
    "Analysis available now": "Analyse tilgjengelig nå",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analyse er tilgjengelig nå, men å kjøre analyser rygg-til-rygg kan sette kontoen din i fare.",
    "Please wait": "Vennligst vent",
    "Warning": "Advarsel",
    "Next analysis: {time}": "Neste analyse: {time}",
    "WATCH AD AND START ANALYSIS": "SE ANNONSEN OG START ANALYSE",
    "START ANALYSIS": "START ANALYSE",
    "Start analysis?": "Start analyse?",
    "Reset App Data": "Tilbakestill appdata",
    "This will wipe all local data and session cookies. Are you sure?":
        "Dette vil slette alle lokale data og øktinformasjonskapsler. Er du sikker?",
    "CANCEL": "KANSELLERE",
    "DELETE": "SLETT",
    "Error": "Feil",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Datahenting mislyktes: {err}\n\nFeilsøking: Prøv å logge av og på igjen.",
    "Followers": "Følgere",
    "Following": "Følgende",
    "New Followers": "Nye følgere",
    "Not Following Back": "Følger ikke tilbake",
    "Lost Followers": "Tapte følgere",
    "Legal Disclaimer": "Juridisk ansvarsfraskrivelse",
    "Unfollowed Users": "Brukere som ikke følges",
    "Rate Us": "Vurder oss",
    "Contact Us": "Kontakt oss",
    "Remove Ads & Wait Times": "Fjern annonser og ventetider",
    "This box is currently under test.":
        "Denne boksen er for øyeblikket under testing.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Se historier i hemmelighet eller zoom profilbilder",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Logg inn for å se historier i hemmelighet og forstørre profilbilder.",
    "Will be shown after the ad, please wait.":
        "Vil bli vist etter annonsen, vennligst vent.",
    "What would you like to do?": "Hva vil du gjøre?",
    "Enlarge profile photo": "Forstørre profilbildet",
    "Watch story secretly": "Se historien i hemmelighet",
    "No story data available.": "Ingen historiedata tilgjengelig.",
    "I HAVE READ AND AGREE": "JEG HAR LEST OG ENIG",
    "Withdraw Consent": "Trekk tilbake samtykke",
    "Confirm": "Bekrefte",
    "Your consent settings will be reset. Are you sure?":
        "Samtykkeinnstillingene dine tilbakestilles. Er du sikker?",
    "Yes": "Ja",
    "Cancel": "Kansellere",
    "Session verified, redirecting securely...":
        "Økt bekreftet, omdirigerer sikkert...",
    "Analysis complete ✅": "Analyse fullført ✅",
    "Purchases are not available right now. Please try again later.":
        "Kjøp er ikke tilgjengelig akkurat nå. Vennligst prøv igjen senere.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Kjøp fullført, men Premium er ikke aktiv ennå. Vennligst prøv igjen.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Velkommen til Premium! Annonser og ventetider fjernes.",
    "Your Premium membership is active.":
        "Premium-medlemskapet ditt er aktivt.",
    "Restore Purchases": "Gjenopprett kjøp",
    "RESTORE": "RESTAURERE",
    "Restoring purchases...": "Gjenoppretter kjøp ...",
    "Purchases restored ✅": "Kjøp gjenopprettet ✅",
    "No purchases to restore.": "Ingen kjøp å gjenopprette.",
    "Restore failed: {err}": "Gjenoppretting mislyktes: {err}",
    "Enter PIN": "Skriv inn PIN",
    "PIN accepted, timer reset ✅": "PIN akseptert, tilbakestilling av timer ✅",
    "Invalid PIN": "Ugyldig PIN-kode",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Ved å laste ned og bruke denne applikasjonen, anses hver bruker for å ha lest, forstått og ugjenkallelig akseptert teksten \"Vilkår for bruk og ansvarsfraskrivelse\" nedenfor på forhånd:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artikkel 1: Datavern og lokal behandlingsarkitektur",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT er programvare på klientsiden. Brukerens påloggingsinformasjon (brukernavn, passord, øktinformasjonskapsler) blir under ingen omstendigheter overført til eller lagret på en ekstern server. Alle databehandlingsaktiviteter skjer utelukkende innenfor det midlertidige minnet (RAM) og lokal lagring på brukerens enhet. Applikasjonen fungerer som en \"nettleser-innpakning\" som opererer over Instagram-grensesnittet.",
    "Article 2: Third-Party Platform Risks":
        "Artikkel 2: Tredjepartsplattformrisiko",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) forbeholder seg retten til å begrense bruken av tredjepartsprogramvare i henhold til plattformens retningslinjer. Alle risikoer, inkludert men ikke begrenset til \"handlingsblokker\", \"kontobegrensninger\", \"shadowbans\" eller \"kontostenginger\" som kan oppstå ved bruk av applikasjonen, tilhører utelukkende brukeren. VERDICT-utvikleren kan ikke holdes ansvarlig for noen direkte eller indirekte skader som følge av slike administrative sanksjoner.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artikkel 3: Ansvarsfraskrivelse og ansvarsbegrensning",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Denne programvaren leveres 'AS-IS' og 'AS AVAILABLE'. 100 % nøyaktighet, kontinuitet eller salgbarhet av analyseresultatene levert av programvaren er ikke garantert. Brukeren erkjenner at eventuelle resultater som oppstår fra juridiske eller kommersielle transaksjoner basert på applikasjonsdata er deres eget ansvar; og erklærer og forplikter seg til å holde utvikleren skadesløs fra alle krav, søksmål og klager.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artikkel 4: Merknad om intellektuell eiendom og uavhengighet",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT er et uavhengig utviklerprosjekt. Merkene 'Instagram', 'Facebook' og 'Meta' er registrerte varemerker for Meta Platforms, Inc. Denne applikasjonen har ingen kommersielt partnerskap, sponsoravtale eller offisiell tilknytning til de nevnte selskapene.",
    "Article 5: Service Continuity and Platform Changes":
        "Artikkel 5: Tjenestekontinuitet og plattformendringer",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Grunnleggende endringer i Instagram API eller nettinfrastruktur kan føre til at applikasjonen mister funksjonaliteten helt eller delvis. Utvikleren forplikter seg ikke til å oppdatere applikasjonen eller vedlikeholde tjenesten som svar på slike infrastrukturelle endringer, som anses som \"force majeure\".",
    "Analysis complete, results will be shown after the ad.":
        "Analysen er fullført, resultatene vises etter annonsen.",
    "Analysis failed": "Analyse mislyktes",
    "Reason: {reason}": "Årsak: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tips: Det kan hjelpe å logge av og på igjen.",
    "Quick check: Counts are the same. No changes detected.":
        "Rask sjekk: Antallet er det samme. Ingen endringer oppdaget.",
    "Daily Metrics": "Daglige beregninger",
    "Active users": "Aktive brukere",
    "Daily queries": "Daglige spørsmål",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Datainnlasting ble avbrutt: følgerdata er ufullstendige ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Datainnlasting ble avbrutt: følgende data er ufullstendige ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Datainnlasting ble avbrutt: Instagram returnerte tomme data.",
    "Data loading stopped due to an unexpected error.":
        "Datainnlasting stoppet på grunn av en uventet feil.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram returnerte en advarsel om automatisk atferd. Vi sluttet å hente data for sikkerhets skyld.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram ba om sikkerhetsverifisering. Bekreft i Instagram-appen og prøv igjen.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Økten er ugyldig eller venter på bekreftelse. Logg på igjen.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Det ble sendt for mange forespørsler. Datainnlastingen ble avbrutt for sikkerhets skyld.",
    "Data loading could not complete due to a connection issue.":
        "Datainnlasting kunne ikke fullføres på grunn av et tilkoblingsproblem.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram returnerte en feil (HTTP {code}). Datainnlastingen ble avbrutt.",
    "Instagram security verification is required (story data could not be fetched).":
        "Instagram-sikkerhetsverifisering er nødvendig (historiedata kunne ikke hentes).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Historiedata kunne ikke hentes. Vanligvis er dette forårsaket av Instagram-verifisering, midlertidige API-begrensninger eller et tilkoblingsavbrudd. Prøv igjen om 2-3 minutter.",
    "Could not fetch story data. Please try again shortly.":
        "Kunne ikke hente historiedata. Prøv igjen snart.",
    "Secret Mode": "Hemmelig modus",
    "Starting VERDICT...": "Starter VERDICT...",
    "DID YOU KNOW?": "VISSTE DU?",
    "Estimated time left: {time}": "Beregnet tid igjen: {time}",
    "Estimating remaining time...": "Anslår gjenværende tid ...",
    "LOG OUT": "LOGG UT",
    "Open Profile": "Åpne profil",
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
    "Analysis Time!": "Hora de análise!",
    "CLOSE": "FECHAR",
    "SYSTEM UNDER MAINTENANCE": "SISTEMA EM MANUTENÇÃO",
    "Bio Planner": "Planejador biológico",
    "Store link not set.": "Link da loja não definido.",
    "Invalid store link.": "Link de loja inválido.",
    "Could not open the link.": "Não foi possível abrir o link.",
    "Please try again.": "Por favor, tente novamente.",
    "Show error": "Mostrar erro",
    "Exception": "Exceção",
    "Load error": "Erro de carregamento",
    "Code": "Código",
    "Timeout": "Tempo esgotado",
    "REST probe failed: missing auth.":
        "Falha na sonda REST: autenticação ausente.",
    "REST probe success (Firestore endpoint reachable).":
        "Êxito na sondagem REST (endpoint do Firestore acessível).",
    "REST probe failed (check logs).":
        "Falha na sonda REST (verifique os logs).",
    "Firebase Auth probe failed.": "Falha na sondagem do Firebase Auth.",
    "Firebase Auth probe success.": "Sucesso na investigação do Firebase Auth.",
    "Firebase token probe failed.": "Falha na análise do token do Firebase.",
    "CRITICAL DIAGNOSTIC ERROR": "ERRO DE DIAGNÓSTICO CRÍTICO",
    "COPY": "CÓPIA",
    "OPEN LOGS": "ABRIR REGISTROS",
    "Firebase": "Base de fogo",
    "Store": "Loja",
    "Copy all": "Copiar tudo",
    "Close": "Fechar",
    "Auth Probe": "Sonda de autenticação",
    "Write Test": "Teste de gravação",
    "REST Probe": "Sonda REST",
    "Restore Test": "Teste de restauração",
    "Firebase auth error: user verification failed.":
        "Erro de autenticação do Firebase: falha na verificação do usuário.",
    "Firestore test write successful.":
        "Gravação de teste do Firestore bem-sucedida.",
    "Firestore test failed.": "O teste do Firestore falhou.",
    "Firestore auth error: user verification failed.":
        "Erro de autenticação do Firestore: falha na verificação do usuário.",
    "Firestore counter write failed.":
        "Falha na gravação do contador do Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Autenticação do Firestore ausente: gravação de ig_users bloqueada.",
    "Firestore ig_users write failed.":
        "Falha na gravação do Firestore ig_users.",
    "User": "Usuário",
    "Opening consent form...": "Abrindo formulário de consentimento...",
    "Your consent preference was updated.":
        "Sua preferência de consentimento foi atualizada.",
    "Consent update failed. Please try again.":
        "Falha na atualização do consentimento. Por favor, tente novamente.",
    "Your account is blocked": "Sua conta está bloqueada",
    "Access is restricted for this account.":
        "O acesso é restrito para esta conta.",
    "Starting purchase...": "Iniciando compra...",
    "Purchase cancelled.": "Compra cancelada.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium ativo ✅ Anúncios e tempos de espera estão desativados.",
    "Purchase failed. Please try again.":
        "A compra falhou. Por favor, tente novamente.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "A verificação da sessão é necessária. Verifique sua conta no aplicativo Instagram e tente novamente.",
    "Instagram returned no data.": "O Instagram não retornou dados.",
    "Session verification failed. Please log in again.":
        "Falha na verificação da sessão. Faça login novamente.",
    "Open Instagram": "Abra o Instagram",
    "Instagram message": "Mensagem do Instagram",
    "Loading stories...": "Carregando histórias...",
    "No data": "Sem dados",
    "NEW": "NOVO",
    "Login": "Conecte-se",
    "Session verified, redirecting...": "Sessão verificada, redirecionando...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ESPAÇO DE ANÚNCIO",
    "Admin mode active": "Modo administrador ativo",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Estamos evoluindo a cada dia para lhe proporcionar uma melhor experiência. Seu feedback é valioso para nós – adoraríamos ouvir sua opinião!",
    "Please log in to start the analysis.":
        "Faça login para iniciar a análise.",
    "Welcome, {username}": "Bem-vindo, {username}",
    "REFRESH DATA": "ATUALIZAR DADOS",
    "LOG IN WITH INSTAGRAM": "ENTRAR COM INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analisando dados...\nIsso pode demorar um pouco.",
    "Processing data...\nAlmost done.": "Processando dados...\nQuase pronto.",
    "Loading ad...\nPlease wait.": "Carregando anúncio...\nPor favor, espere.",
    "Google ad warning: {reason}": "Aviso de anúncio do Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Todas as análises são processadas localmente com segurança no seu dispositivo.",
    "Total analyses today: {count}": "Total de análises hoje: {count}",
    "Next analysis": "Próxima análise",
    "Ready to scan.": "Pronto para digitalizar.",
    "Analysis available now": "Análise disponível agora",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "A análise já está disponível, mas executá-las consecutivamente pode colocar sua conta em risco.",
    "Please wait": "Por favor, aguarde",
    "Warning": "Aviso",
    "Next analysis: {time}": "Próxima análise: {time}",
    "WATCH AD AND START ANALYSIS": "ASSISTA AO ANÚNCIO E INICIE A ANÁLISE",
    "START ANALYSIS": "INICIAR ANÁLISE",
    "Start analysis?": "Iniciar análise?",
    "Reset App Data": "Redefinir dados do aplicativo",
    "This will wipe all local data and session cookies. Are you sure?":
        "Isso apagará todos os dados locais e cookies de sessão. Tem certeza?",
    "CANCEL": "CANCELAR",
    "DELETE": "EXCLUIR",
    "Error": "Erro",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Falha na recuperação de dados: {err}\n\nSolução de problemas: tente sair e fazer login novamente.",
    "Followers": "Seguidores",
    "Following": "Seguindo",
    "New Followers": "Novos seguidores",
    "Not Following Back": "Não seguindo de volta",
    "Lost Followers": "Seguidores perdidos",
    "Legal Disclaimer": "Isenção de responsabilidade legal",
    "Unfollowed Users": "Usuários não seguidos",
    "Rate Us": "Avalie-nos",
    "Contact Us": "Contate-nos",
    "Remove Ads & Wait Times": "Remover anúncios e tempos de espera",
    "This box is currently under test.": "Esta caixa está atualmente em teste.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Assista histórias secretamente ou amplie fotos de perfil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Faça login para assistir histórias secretamente e ampliar as fotos do perfil.",
    "Will be shown after the ad, please wait.":
        "Será exibido após o anúncio, aguarde.",
    "What would you like to do?": "O que você gostaria de fazer?",
    "Enlarge profile photo": "Ampliar foto do perfil",
    "Watch story secretly": "Assista a história secretamente",
    "No story data available.": "Nenhum dado da história disponível.",
    "I HAVE READ AND AGREE": "EU LI E CONCORDO",
    "Withdraw Consent": "Retirar consentimento",
    "Confirm": "Confirmar",
    "Your consent settings will be reset. Are you sure?":
        "Suas configurações de consentimento serão redefinidas. Tem certeza?",
    "Yes": "Sim",
    "Cancel": "Cancelar",
    "Session verified, redirecting securely...":
        "Sessão verificada, redirecionando com segurança...",
    "Analysis complete ✅": "Análise concluída ✅",
    "Purchases are not available right now. Please try again later.":
        "As compras não estão disponíveis no momento. Por favor, tente novamente mais tarde.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Compra concluída, mas o Premium ainda não está ativo. Por favor, tente novamente.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Bem-vindo ao Premium! Anúncios e tempos de espera são removidos.",
    "Your Premium membership is active.": "Sua assinatura Premium está ativa.",
    "Restore Purchases": "Restaurar compras",
    "RESTORE": "RESTAURAR",
    "Restoring purchases...": "Restaurando compras...",
    "Purchases restored ✅": "Compras restauradas ✅",
    "No purchases to restore.": "Nenhuma compra para restaurar.",
    "Restore failed: {err}": "Falha na restauração: {err}",
    "Enter PIN": "Insira o PIN",
    "PIN accepted, timer reset ✅": "PIN aceito, cronômetro redefinido ✅",
    "Invalid PIN": "PIN inválido",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Ao baixar e usar este aplicativo, considera-se que todo Usuário leu, compreendeu e aceitou irrevogavelmente o texto dos \"Termos de Uso e Isenção de Responsabilidade\" abaixo, com antecedência:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artigo 1: Privacidade de dados e arquitetura de processamento local",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT é um software do 'lado do cliente'. As credenciais de login do Utilizador (nome de utilizador, palavra-passe, cookies de sessão) não são em caso algum transmitidas ou armazenadas num servidor externo. Todas as atividades de processamento de dados ocorrem exclusivamente na memória temporária (RAM) e no armazenamento local do dispositivo do Usuário. O aplicativo funciona como um 'invólucro de navegador' operando na interface do Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Artigo 2: Riscos de plataformas de terceiros",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "O Instagram (Meta Platforms, Inc.) reserva-se o direito de restringir o uso de software de terceiros de acordo com as políticas da plataforma. Todos os riscos, incluindo, entre outros, 'bloqueios de ação', 'restrições de conta', 'shadowbans' ou 'encerramentos de conta' que possam surgir do uso do aplicativo, pertencem exclusivamente ao Usuário. O desenvolvedor VERDICT não pode ser responsabilizado por quaisquer danos diretos ou indiretos resultantes de tais sanções administrativas.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artigo 3: Isenção de responsabilidade de garantia e limitação de responsabilidade",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Este software é fornecido 'NO ESTADO EM QUE SE ENCONTRA' e 'CONFORME DISPONÍVEL'. A precisão, continuidade ou comercialização de 100% dos resultados da análise fornecidos pelo software não são garantidas. O Usuário reconhece que quaisquer resultados decorrentes de transações legais ou comerciais baseadas em dados do aplicativo são de sua própria responsabilidade; e declara e compromete-se a isentar o desenvolvedor de todas as reclamações, ações judiciais e reclamações.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artigo 4: Aviso de Propriedade Intelectual e Independência",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT é um projeto de desenvolvedor independente. As marcas 'Instagram', 'Facebook' e 'Meta' são marcas registradas da Meta Platforms, Inc. Este aplicativo não possui parceria comercial, acordo de patrocínio ou afiliação oficial com as empresas mencionadas.",
    "Article 5: Service Continuity and Platform Changes":
        "Artigo 5: Continuidade do Serviço e Mudanças na Plataforma",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Mudanças fundamentais na API do Instagram ou na infraestrutura da web podem fazer com que o aplicativo perca sua funcionalidade parcial ou totalmente. O desenvolvedor não se compromete a atualizar o aplicativo ou manter o serviço em resposta a tais alterações infraestruturais, que são consideradas “força maior”.",
    "Analysis complete, results will be shown after the ad.":
        "Análise concluída, os resultados serão mostrados após o anúncio.",
    "Analysis failed": "Falha na análise",
    "Reason: {reason}": "Motivo: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Dica: Sair e fazer login novamente pode ajudar.",
    "Quick check: Counts are the same. No changes detected.":
        "Verificação rápida: as contagens são as mesmas. Nenhuma alteração detectada.",
    "Daily Metrics": "Métricas Diárias",
    "Active users": "Usuários ativos",
    "Daily queries": "Consultas diárias",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "O carregamento de dados foi interrompido: dados do seguidor incompletos ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "O carregamento de dados foi interrompido: seguintes dados incompletos ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "O carregamento de dados foi interrompido: o Instagram retornou dados vazios.",
    "Data loading stopped due to an unexpected error.":
        "O carregamento de dados foi interrompido devido a um erro inesperado.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "O Instagram retornou um aviso de comportamento automatizado. Paramos de buscar dados por segurança.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "O Instagram solicitou verificação de segurança. Verifique no aplicativo Instagram e tente novamente.",
    "Session is invalid or waiting for verification. Please log in again.":
        "A sessão é inválida ou aguarda verificação. Faça login novamente.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Muitas solicitações foram enviadas. O carregamento de dados foi interrompido por segurança.",
    "Data loading could not complete due to a connection issue.":
        "O carregamento de dados não pôde ser concluído devido a um problema de conexão.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "O Instagram retornou um erro (HTTP {code}). O carregamento de dados foi interrompido.",
    "Instagram security verification is required (story data could not be fetched).":
        "A verificação de segurança do Instagram é necessária (não foi possível obter os dados da história).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Não foi possível buscar os dados da história. Geralmente isso é causado pela verificação do Instagram, restrições temporárias da API ou interrupção da conexão. Tente novamente em 2 a 3 minutos.",
    "Could not fetch story data. Please try again shortly.":
        "Não foi possível buscar os dados da história. Por favor, tente novamente em breve.",
    "Secret Mode": "Modo secreto",
    "Starting VERDICT...": "Iniciando o VEREDICTO...",
    "DID YOU KNOW?": "VOCÊ SABIA?",
    "Estimated time left: {time}": "Tempo restante estimado: {time}",
    "Estimating remaining time...": "Estimando o tempo restante...",
    "LOG OUT": "SAIR",
    "Open Profile": "Abrir perfil",
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
    "Analysis Time!": "Timp de analiză!",
    "CLOSE": "APROAPE",
    "SYSTEM UNDER MAINTENANCE": "SISTEM ÎN ÎNTREȚINERE",
    "Bio Planner": "Bio Planner",
    "Store link not set.": "Linkul magazinului nu este setat.",
    "Invalid store link.": "Link de magazin nevalid.",
    "Could not open the link.": "Nu s-a putut deschide linkul.",
    "Please try again.": "Vă rugăm să încercați din nou.",
    "Show error": "Afișează eroarea",
    "Exception": "Excepţie",
    "Load error": "Eroare de încărcare",
    "Code": "Cod",
    "Timeout": "Pauză",
    "REST probe failed: missing auth.":
        "Sonda REST a eșuat: autentificare lipsă.",
    "REST probe success (Firestore endpoint reachable).":
        "Sonda REST reușită (punctul final Firestore accesibil).",
    "REST probe failed (check logs).":
        "Sonda REST a eșuat (verificați jurnalele).",
    "Firebase Auth probe failed.": "Sonda Firebase Auth a eșuat.",
    "Firebase Auth probe success.": "Sonda Firebase Auth a reușit.",
    "Firebase token probe failed.": "Sonda de token Firebase a eșuat.",
    "CRITICAL DIAGNOSTIC ERROR": "EROARE CRITICA DE DIAGNOSTIC",
    "COPY": "COPIE",
    "OPEN LOGS": "JURURI DESCHISE",
    "Firebase": "Firebase",
    "Store": "Magazin",
    "Copy all": "Copiați tot",
    "Close": "Aproape",
    "Auth Probe": "Sonda de autentificare",
    "Write Test": "Test de scriere",
    "REST Probe": "Sondă REST",
    "Restore Test": "Test de restaurare",
    "Firebase auth error: user verification failed.":
        "Eroare de autentificare Firebase: verificarea utilizatorului a eșuat.",
    "Firestore test write successful.": "Scrierea testului Firestore a reușit.",
    "Firestore test failed.": "Testul Firestore a eșuat.",
    "Firestore auth error: user verification failed.":
        "Eroare de autentificare Firestore: verificarea utilizatorului a eșuat.",
    "Firestore counter write failed.": "Scrierea contorului Firestore a eșuat.",
    "Firestore auth missing: ig_users write blocked.":
        "Lipsește autorizarea Firestore: scrierea ig_users este blocată.",
    "Firestore ig_users write failed.": "Scrierea Firestore ig_users a eșuat.",
    "User": "Utilizator",
    "Opening consent form...": "Se deschide formularul de consimțământ...",
    "Your consent preference was updated.":
        "Preferința dvs. de consimțământ a fost actualizată.",
    "Consent update failed. Please try again.":
        "Actualizarea consimțământului a eșuat. Vă rugăm să încercați din nou.",
    "Your account is blocked": "Contul dvs. este blocat",
    "Access is restricted for this account.":
        "Accesul este restricționat pentru acest cont.",
    "Starting purchase...": "Începe achiziția...",
    "Purchase cancelled.": "Achiziție anulată.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium activ ✅ Reclamele și timpii de așteptare sunt dezactivate.",
    "Purchase failed. Please try again.":
        "Achiziția nu a reușit. Vă rugăm să încercați din nou.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Este necesară verificarea sesiunii. Vă rugăm să vă verificați contul în aplicația Instagram și să încercați din nou.",
    "Instagram returned no data.": "Instagram nu a returnat date.",
    "Session verification failed. Please log in again.":
        "Verificarea sesiunii a eșuat. Vă rugăm să vă conectați din nou.",
    "Open Instagram": "Deschide Instagram",
    "Instagram message": "mesaj Instagram",
    "Loading stories...": "Se încarcă poveștile...",
    "No data": "Fără date",
    "NEW": "NOU",
    "Login": "Log in",
    "Session verified, redirecting...": "Sesiune verificată, redirecționare...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "SPAȚIU ANUNȚ",
    "Admin mode active": "Modul de administrare activ",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Evoluăm în fiecare zi pentru a vă oferi o experiență mai bună. Feedbackul dvs. este valoros pentru noi - ne-ar plăcea să auzim de la dvs.!",
    "Please log in to start the analysis.":
        "Vă rugăm să vă conectați pentru a începe analiza.",
    "Welcome, {username}": "Bun venit, {username}",
    "REFRESH DATA": "ACTUALIZARE DATE",
    "LOG IN WITH INSTAGRAM": "LOGIN CU INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Se analizează datele...\nAcest lucru ar putea dura un moment.",
    "Processing data...\nAlmost done.": "Prelucrarea datelor...\nAproape gata.",
    "Loading ad...\nPlease wait.":
        "Se încarcă anunțul...\nVă rugăm să așteptați.",
    "Google ad warning: {reason}":
        "Avertisment pentru anunțuri Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Toate analizele sunt procesate local în siguranță pe dispozitivul dvs.",
    "Total analyses today: {count}": "Total analize astăzi: {count}",
    "Next analysis": "Următoarea analiză",
    "Ready to scan.": "Gata de scanare.",
    "Analysis available now": "Analiza disponibilă acum",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analiza este disponibilă acum, dar efectuarea analizelor consecutive vă poate pune contul în pericol.",
    "Please wait": "Va rugam asteptati",
    "Warning": "Avertizare",
    "Next analysis: {time}": "Următoarea analiză: {time}",
    "WATCH AD AND START ANALYSIS": "VIZIȚI ANUNȚUL ȘI ÎNCEPEȚI ANALIZA",
    "START ANALYSIS": "ÎNCEPE ANALIZA",
    "Start analysis?": "Începeți analiza?",
    "Reset App Data": "Resetați datele aplicației",
    "This will wipe all local data and session cookies. Are you sure?":
        "Aceasta va șterge toate datele locale și modulele cookie de sesiune. esti sigur?",
    "CANCEL": "ANULA",
    "DELETE": "ŞTERGE",
    "Error": "Eroare",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Preluarea datelor a eșuat: {err}\n\nDepanare: Încercați să vă deconectați și să vă conectați din nou.",
    "Followers": "Urmaritori",
    "Following": "Urmând",
    "New Followers": "Noi urmăritori",
    "Not Following Back": "Nu Urmează Înapoi",
    "Lost Followers": "Abonați pierduti",
    "Legal Disclaimer": "Declinarea răspunderii legale",
    "Unfollowed Users": "Utilizatori neurmăriti",
    "Rate Us": "Evaluează-ne",
    "Contact Us": "Contactaţi-ne",
    "Remove Ads & Wait Times": "Eliminați anunțurile și timpii de așteptare",
    "This box is currently under test.":
        "Această casetă este în prezent în curs de testare.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Vizionați poveștile în secret sau măriți fotografiile de profil",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Vă rugăm să vă conectați pentru a viziona poveștile în secret și pentru a mări fotografiile de profil.",
    "Will be shown after the ad, please wait.":
        "Va fi afișat după anunț, vă rugăm să așteptați.",
    "What would you like to do?": "Ce ai vrea sa faci?",
    "Enlarge profile photo": "Măriți fotografia de profil",
    "Watch story secretly": "Urmărește povestea în secret",
    "No story data available.": "Nu sunt disponibile date despre poveste.",
    "I HAVE READ AND AGREE": "AM CITIT SI SUNT DE ACORD",
    "Withdraw Consent": "Retragerea consimțământului",
    "Confirm": "Confirma",
    "Your consent settings will be reset. Are you sure?":
        "Setările dvs. de consimțământ vor fi resetate. esti sigur?",
    "Yes": "Da",
    "Cancel": "Anula",
    "Session verified, redirecting securely...":
        "Sesiune verificată, redirecționare în siguranță...",
    "Analysis complete ✅": "Analiza finalizată ✅",
    "Purchases are not available right now. Please try again later.":
        "Achizițiile nu sunt disponibile momentan. Vă rugăm să încercați din nou mai târziu.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Achiziție finalizată, dar Premium nu este încă activ. Vă rugăm să încercați din nou.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Bun venit la Premium! Reclamele și timpii de așteptare sunt eliminate.",
    "Your Premium membership is active.":
        "Abonamentul dvs. Premium este activ.",
    "Restore Purchases": "Restabiliți achizițiile",
    "RESTORE": "RESTABILI",
    "Restoring purchases...": "Se restabilește achizițiile...",
    "Purchases restored ✅": "Achiziții restaurate ✅",
    "No purchases to restore.": "Nu există achiziții de restaurat.",
    "Restore failed: {err}": "Restaurarea eșuată: {err}",
    "Enter PIN": "Introduceți codul PIN",
    "PIN accepted, timer reset ✅": "PIN acceptat, resetarea temporizatorului ✅",
    "Invalid PIN": "PIN nevalid",
    "OK": "Bine",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Prin descărcarea și utilizarea acestei aplicații, se consideră că fiecare Utilizator a citit, a înțeles și a acceptat irevocabil textul „Termeni de utilizare și declinare a răspunderii” de mai jos în avans:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Articolul 1: Confidențialitatea datelor și arhitectura locală de procesare",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT este un software „partea client”. Acreditările de conectare ale Utilizatorului (nume de utilizator, parolă, cookie-uri de sesiune) nu sunt în niciun caz transmise sau stocate pe un server extern. Toate activitățile de prelucrare a datelor au loc exclusiv în memoria temporară (RAM) și stocarea locală a dispozitivului Utilizatorului. Aplicația funcționează ca un „browser-wrapper” care operează prin interfața Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Articolul 2: Riscurile platformei terțelor părți",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) își rezervă dreptul de a restricționa utilizarea software-ului terță parte conform politicilor platformei sale. Toate riscurile, inclusiv, dar fără a se limita la, „blocuri de acțiuni”, „restricții de cont”, „interzice în umbră” sau „închidere de cont” care pot apărea din utilizarea aplicației, aparțin exclusiv Utilizatorului. Dezvoltatorul VERDICT nu poate fi tras la răspundere pentru orice daune directe sau indirecte rezultate din astfel de sancțiuni administrative.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Articolul 3: Declinarea garanției și limitarea răspunderii",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Acest software este furnizat „AS-AS-IS” și „AS-AVAILABLE”. Nu este garantată acuratețea, continuitatea sau caracterul comercial de 100% a rezultatelor analizei furnizate de software. Utilizatorul recunoaște că orice rezultat care decurge din tranzacții juridice sau comerciale bazate pe datele aplicației este propria sa responsabilitate; și declară și se angajează să țină dezvoltatorul inofensiv de toate pretențiile, procesele și plângerile.",
    "Article 4: Intellectual Property and Independence Notice":
        "Articolul 4: Notificarea privind proprietatea intelectuală și independența",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT este un proiect de dezvoltator independent. Mărcile „Instagram”, „Facebook” și „Meta” sunt mărci comerciale înregistrate ale Meta Platforms, Inc. Această aplicație nu are parteneriate comerciale, acord de sponsorizare sau afiliere oficială cu companiile menționate mai sus.",
    "Article 5: Service Continuity and Platform Changes":
        "Articolul 5: Continuitatea serviciului și modificările platformei",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Modificările fundamentale ale API-ului Instagram sau ale infrastructurii web pot face ca aplicația să își piardă parțial sau complet funcționalitatea. Dezvoltatorul nu se angajează să actualizeze aplicația sau să mențină serviciul ca răspuns la astfel de modificări de infrastructură, care sunt considerate „forță majoră”.",
    "Analysis complete, results will be shown after the ad.":
        "Analiza finalizată, rezultatele vor fi afișate după anunț.",
    "Analysis failed": "Analiza a eșuat",
    "Reason: {reason}": "Motiv: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Sfat: deconectarea și reconectarea pot ajuta.",
    "Quick check: Counts are the same. No changes detected.":
        "Verificare rapidă: Numărările sunt aceleași. Nu au fost detectate modificări.",
    "Daily Metrics": "Valori zilnice",
    "Active users": "Utilizatori activi",
    "Daily queries": "Interogări zilnice",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Încărcarea datelor a fost întreruptă: datele adepților incomplete ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Încărcarea datelor a fost întreruptă: următoarele date sunt incomplete ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Încărcarea datelor a fost întreruptă: Instagram a returnat date goale.",
    "Data loading stopped due to an unexpected error.":
        "Încărcarea datelor a fost oprită din cauza unei erori neașteptate.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram a returnat un avertisment de comportament automatizat. Am încetat să preluăm date pentru siguranță.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram a solicitat verificarea de securitate. Verificați în aplicația Instagram și încercați din nou.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sesiunea este nevalidă sau așteaptă verificarea. Vă rugăm să vă conectați din nou.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Au fost trimise prea multe cereri. Încărcarea datelor a fost întreruptă pentru siguranță.",
    "Data loading could not complete due to a connection issue.":
        "Încărcarea datelor nu s-a putut finaliza din cauza unei probleme de conexiune.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram a returnat o eroare (HTTP {code}). Încărcarea datelor a fost întreruptă.",
    "Instagram security verification is required (story data could not be fetched).":
        "Este necesară verificarea securității Instagram (datele despre poveste nu au putut fi preluate).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Datele poveștii nu au putut fi preluate. De obicei, acest lucru este cauzat de verificarea Instagram, restricții temporare API sau o întrerupere a conexiunii. Vă rugăm să încercați din nou în 2-3 minute.",
    "Could not fetch story data. Please try again shortly.":
        "Nu s-au putut prelua datele despre poveste. Vă rugăm să încercați din nou în scurt timp.",
    "Secret Mode": "Modul secret",
    "Starting VERDICT...": "Se începe VERDICT...",
    "DID YOU KNOW?": "ȘTIAȚI?",
    "Estimated time left: {time}": "Timp rămas estimat: {time}",
    "Estimating remaining time...": "Se estimează timpul rămas...",
    "LOG OUT": "LOG OUT",
    "Open Profile": "Deschide Profil",
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
    "Analysis Time!": "Čas analýzy!",
    "CLOSE": "ZATVORTE",
    "SYSTEM UNDER MAINTENANCE": "SYSTÉM POD ÚDRŽBOU",
    "Bio Planner": "Bio plánovač",
    "Store link not set.": "Odkaz obchodu nie je nastavený.",
    "Invalid store link.": "Neplatný odkaz na obchod.",
    "Could not open the link.": "Odkaz sa nepodarilo otvoriť.",
    "Please try again.": "Skúste to znova.",
    "Show error": "Zobraziť chybu",
    "Exception": "Výnimka",
    "Load error": "Chyba načítania",
    "Code": "kód",
    "Timeout": "Časový limit",
    "REST probe failed: missing auth.":
        "Sonda REST zlyhala: chýba autorizácia.",
    "REST probe success (Firestore endpoint reachable).":
        "Úspešnosť sondy REST (dosiahnuteľný koncový bod Firestore).",
    "REST probe failed (check logs).":
        "Sonda REST zlyhala (skontrolujte denníky).",
    "Firebase Auth probe failed.": "Test Firebase Auth zlyhal.",
    "Firebase Auth probe success.": "Testovanie Firebase Auth bolo úspešné.",
    "Firebase token probe failed.": "Testovanie tokenu Firebase zlyhalo.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITICKÁ DIAGNOSTICKÁ CHYBA",
    "COPY": "KOPÍROVAŤ",
    "OPEN LOGS": "OTVORTE DENNÍKY",
    "Firebase": "Firebase",
    "Store": "Obchod",
    "Copy all": "Skopírujte všetko",
    "Close": "Zavrieť",
    "Auth Probe": "Auth Probe",
    "Write Test": "Napíšte test",
    "REST Probe": "REST Sonda",
    "Restore Test": "Obnoviť test",
    "Firebase auth error: user verification failed.":
        "Chyba overenia Firebase: overenie používateľa zlyhalo.",
    "Firestore test write successful.": "Zápis testu Firestore bol úspešný.",
    "Firestore test failed.": "Test Firestore zlyhal.",
    "Firestore auth error: user verification failed.":
        "Chyba overenia Firestore: overenie používateľa zlyhalo.",
    "Firestore counter write failed.": "Zápis počítadla Firestore zlyhal.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore auth chýba: ig_users zápis blokovaný.",
    "Firestore ig_users write failed.": "Zápis ig_users do Firestore zlyhal.",
    "User": "Používateľ",
    "Opening consent form...": "Otvára sa formulár súhlasu...",
    "Your consent preference was updated.":
        "Vaša predvoľba súhlasu bola aktualizovaná.",
    "Consent update failed. Please try again.":
        "Aktualizácia súhlasu zlyhala. Skúste to znova.",
    "Your account is blocked": "Váš účet je zablokovaný",
    "Access is restricted for this account.":
        "Prístup je pre tento účet obmedzený.",
    "Starting purchase...": "Spúšťa sa nákup...",
    "Purchase cancelled.": "Nákup bol zrušený.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Prémiové aktívne ✅ Reklamy a čakacie doby sú vypnuté.",
    "Purchase failed. Please try again.": "Nákup zlyhal. Skúste to znova.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Vyžaduje sa overenie relácie. Overte svoj účet v aplikácii Instagram a skúste to znova.",
    "Instagram returned no data.": "Instagram nevrátil žiadne údaje.",
    "Session verification failed. Please log in again.":
        "Overenie relácie zlyhalo. Prihláste sa znova.",
    "Open Instagram": "Otvorte Instagram",
    "Instagram message": "Správa na Instagrame",
    "Loading stories...": "Načítavajú sa príbehy...",
    "No data": "Žiadne údaje",
    "NEW": "NOVINKA",
    "Login": "Prihláste sa",
    "Session verified, redirecting...":
        "Relácia overená, prebieha presmerovanie...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "REKLAMNÝ PRIESTOR",
    "Admin mode active": "Režim správcu je aktívny",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Každým dňom sa vyvíjame, aby sme vám poskytli lepší zážitok. Vaša spätná väzba je pre nás cenná – radi by sme sa o vás dozvedeli!",
    "Please log in to start the analysis.":
        "Ak chcete spustiť analýzu, prihláste sa.",
    "Welcome, {username}": "Vitajte, {username}",
    "REFRESH DATA": "OBNOVIŤ ÚDAJE",
    "LOG IN WITH INSTAGRAM": "PRIHLÁSIŤ SA NA INSTAGRAME",
    "Analyzing data...\nThis might take a moment.":
        "Prebieha analýza údajov...\nMôže to chvíľu trvať.",
    "Processing data...\nAlmost done.":
        "Spracúvajú sa údaje...\nTakmer hotovo.",
    "Loading ad...\nPlease wait.": "Načítava sa reklama...\nČakajte prosím.",
    "Google ad warning: {reason}": "Upozornenie na reklamu Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Všetky analýzy sú bezpečne spracované lokálne na vašom zariadení.",
    "Total analyses today: {count}": "Celkové dnešné analýzy: {count}",
    "Next analysis": "Ďalšia analýza",
    "Ready to scan.": "Pripravené na skenovanie.",
    "Analysis available now": "Analýza je teraz k dispozícii",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analýza je teraz k dispozícii, ale súbežné vykonávanie analýz môže ohroziť váš účet.",
    "Please wait": "Čakajte prosím",
    "Warning": "POZOR",
    "Next analysis: {time}": "Ďalšia analýza: {time}",
    "WATCH AD AND START ANALYSIS": "POZRITE SI REKLAMU A ZAČNITE S ANALÝZOU",
    "START ANALYSIS": "ZAČAŤ ANALÝZU",
    "Start analysis?": "Spustiť analýzu?",
    "Reset App Data": "Obnoviť údaje aplikácie",
    "This will wipe all local data and session cookies. Are you sure?":
        "Týmto sa vymažú všetky miestne údaje a súbory cookie relácie. si si istý?",
    "CANCEL": "ZRUŠIŤ",
    "DELETE": "VYMAZAŤ",
    "Error": "Chyba",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Načítanie údajov zlyhalo: {err}\n\nRiešenie problémov: Skúste sa odhlásiť a znova prihlásiť.",
    "Followers": "Nasledovníci",
    "Following": "Sledovanie",
    "New Followers": "Noví sledovatelia",
    "Not Following Back": "Nesledovanie späť",
    "Lost Followers": "Stratení nasledovníci",
    "Legal Disclaimer": "Právne odmietnutie zodpovednosti",
    "Unfollowed Users": "Nesledovaní používatelia",
    "Rate Us": "Ohodnoťte nás",
    "Contact Us": "Kontaktujte nás",
    "Remove Ads & Wait Times": "Odstráňte reklamy a čakacie doby",
    "This box is currently under test.": "Tento box je momentálne v teste.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Sledujte príbehy tajne alebo približujte profilové fotografie",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Ak chcete tajne sledovať príbehy a zväčšiť profilové fotografie, prihláste sa.",
    "Will be shown after the ad, please wait.":
        "Zobrazí sa po reklame, čakajte prosím.",
    "What would you like to do?": "čo by ste chceli robiť?",
    "Enlarge profile photo": "Zväčšiť profilovú fotku",
    "Watch story secretly": "Sledujte príbeh tajne",
    "No story data available.": "Nie sú k dispozícii žiadne údaje príbehu.",
    "I HAVE READ AND AGREE": "PREČÍTAL SOM A SÚHLASÍM",
    "Withdraw Consent": "Odvolať súhlas",
    "Confirm": "Potvrďte",
    "Your consent settings will be reset. Are you sure?":
        "Vaše nastavenia súhlasu budú obnovené. si si istý?",
    "Yes": "áno",
    "Cancel": "Zrušiť",
    "Session verified, redirecting securely...":
        "Relácia overená, presmerovanie zabezpečené...",
    "Analysis complete ✅": "Analýza hotová ✅",
    "Purchases are not available right now. Please try again later.":
        "Nákupy nie sú momentálne dostupné. Skúste to znova neskôr.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Nákup dokončený, ale Premium ešte nie je aktívne. Skúste to znova.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Vitajte v službe Premium! Reklamy a čakacie doby sú odstránené.",
    "Your Premium membership is active.": "Vaše prémiové členstvo je aktívne.",
    "Restore Purchases": "Obnoviť nákupy",
    "RESTORE": "OBNOVIŤ",
    "Restoring purchases...": "Obnovujú sa nákupy...",
    "Purchases restored ✅": "Nákupy obnovené ✅",
    "No purchases to restore.": "Žiadne nákupy na obnovenie.",
    "Restore failed: {err}": "Obnovenie zlyhalo: {err}",
    "Enter PIN": "Zadajte PIN",
    "PIN accepted, timer reset ✅": "PIN akceptovaný, časovač resetovaný ✅",
    "Invalid PIN": "Neplatný kód PIN",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Stiahnutím a používaním tejto aplikácie sa má za to, že každý používateľ si vopred prečítal, porozumel a neodvolateľne prijal text „Podmienky používania a vylúčenie zodpovednosti“:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Článok 1: Ochrana údajov a lokálna architektúra spracovania",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT je softvér na strane klienta. Prihlasovacie údaje používateľa (používateľské meno, heslo, súbory cookie relácie) sa za žiadnych okolností neprenášajú na externý server ani sa na ňom neukladajú. Všetky činnosti spracovania údajov prebiehajú výlučne v rámci dočasnej pamäte (RAM) a lokálneho úložiska zariadenia Používateľa. Aplikácia funguje ako „obálka prehliadača“ fungujúca cez rozhranie Instagramu.",
    "Article 2: Third-Party Platform Risks":
        "Článok 2: Riziká platformy tretích strán",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Spoločnosť Instagram (Meta Platforms, Inc.) si vyhradzuje právo obmedziť používanie softvéru tretích strán podľa svojich pravidiel platformy. Všetky riziká, vrátane, ale nie výlučne, „blokovania akcií“, „obmedzení účtu“, „tieňových zákazov“ alebo „zatvorení účtu“, ktoré môžu vyplynúť z používania aplikácie, patria výlučne Používateľovi. Developer VERDICT nemôže niesť zodpovednosť za žiadne priame alebo nepriame škody vyplývajúce z takýchto administratívnych sankcií.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Článok 3: Vylúčenie záruky a obmedzenie zodpovednosti",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Tento softvér sa poskytuje „AKO JE“ a „AKO JE DOSTUPNÉ“. Nie je zaručená 100% presnosť, kontinuita alebo predajnosť výsledkov analýzy poskytovaných softvérom. Používateľ berie na vedomie, že akékoľvek výsledky vyplývajúce z právnych alebo obchodných transakcií na základe údajov aplikácie sú jeho vlastnou zodpovednosťou; a vyhlasuje a zaväzuje sa chrániť vývojára pred všetkými nárokmi, súdnymi spormi a sťažnosťami.",
    "Article 4: Intellectual Property and Independence Notice":
        "Článok 4: Oznámenie o duševnom vlastníctve a nezávislosti",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT je nezávislý developerský projekt. Značky 'Instagram', 'Facebook' a 'Meta' sú registrované ochranné známky spoločnosti Meta Platforms, Inc. Táto aplikácia nemá žiadne komerčné partnerstvo, sponzorskú zmluvu ani oficiálnu príslušnosť k vyššie uvedeným spoločnostiam.",
    "Article 5: Service Continuity and Platform Changes":
        "Článok 5: Kontinuita služby a zmeny platformy",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Zásadné zmeny v Instagram API alebo webovej infraštruktúre môžu spôsobiť, že aplikácia čiastočne alebo úplne stratí svoju funkčnosť. Vývojár sa nezaväzuje aktualizovať aplikáciu alebo udržiavať službu v reakcii na takéto zmeny infraštruktúry, ktoré sa považujú za „vyššiu moc“.",
    "Analysis complete, results will be shown after the ad.":
        "Analýza je dokončená, výsledky sa zobrazia po reklame.",
    "Analysis failed": "Analýza zlyhala",
    "Reason: {reason}": "Dôvod: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tip: Odhlásenie a opätovné prihlásenie môže pomôcť.",
    "Quick check: Counts are the same. No changes detected.":
        "Rýchla kontrola: Počty sú rovnaké. Nezistili sa žiadne zmeny.",
    "Daily Metrics": "Denné metriky",
    "Active users": "Aktívni používatelia",
    "Daily queries": "Denné otázky",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Načítanie údajov bolo prerušené: údaje o sledovateľoch nie sú úplné ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Načítanie údajov bolo prerušené: nasledujúce údaje sú neúplné ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Načítanie údajov bolo prerušené: Instagram vrátil prázdne údaje.",
    "Data loading stopped due to an unexpected error.":
        "Načítavanie údajov sa zastavilo z dôvodu neočakávanej chyby.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram vrátil automatické varovanie o správaní. Pre istotu sme zastavili načítavanie údajov.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram požiadal o overenie zabezpečenia. Overte v aplikácii Instagram a skúste to znova.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Relácia je neplatná alebo čaká na overenie. Prihláste sa znova.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Bolo odoslaných príliš veľa žiadostí. Načítanie údajov bolo pre bezpečnosť prerušené.",
    "Data loading could not complete due to a connection issue.":
        "Načítanie údajov sa nepodarilo dokončiť pre problém s pripojením.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram vrátil chybu (HTTP {code}). Načítanie údajov bolo prerušené.",
    "Instagram security verification is required (story data could not be fetched).":
        "Vyžaduje sa overenie zabezpečenia Instagramu (dáta príbehu sa nepodarilo načítať).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Údaje príbehu sa nepodarilo načítať. Zvyčajne je to spôsobené overením Instagramu, dočasnými obmedzeniami rozhrania API alebo prerušením pripojenia. Skúste to znova o 2 až 3 minúty.",
    "Could not fetch story data. Please try again shortly.":
        "Nepodarilo sa načítať údaje príbehu. Skúste to znova o chvíľu.",
    "Secret Mode": "Tajný režim",
    "Starting VERDICT...": "Začína sa VERDICT...",
    "DID YOU KNOW?": "VEDELI STE?",
    "Estimated time left: {time}": "Odhadovaný zostávajúci čas: {time}",
    "Estimating remaining time...": "Odhaduje sa zostávajúci čas...",
    "LOG OUT": "ODHLÁSIŤ SA",
    "Open Profile": "Otvorte profil",
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
    "Analysis Time!": "Analystid!",
    "CLOSE": "NÄRA",
    "SYSTEM UNDER MAINTENANCE": "SYSTEM UNDER UNDERHÅLL",
    "Bio Planner": "Bioplanerare",
    "Store link not set.": "Butikslänk inte inställd.",
    "Invalid store link.": "Ogiltig butikslänk.",
    "Could not open the link.": "Det gick inte att öppna länken.",
    "Please try again.": "Försök igen.",
    "Show error": "Visa fel",
    "Exception": "Undantag",
    "Load error": "Ladda fel",
    "Code": "Koda",
    "Timeout": "Timeout",
    "REST probe failed: missing auth.": "REST-sond misslyckades: auth. saknas.",
    "REST probe success (Firestore endpoint reachable).":
        "REST-proben lyckades (Firestore-ändpunkten kan nås).",
    "REST probe failed (check logs).":
        "REST-sonden misslyckades (kontrollera loggar).",
    "Firebase Auth probe failed.": "Firebase Auth-prob misslyckades.",
    "Firebase Auth probe success.": "Firebase Auth-sond lyckades.",
    "Firebase token probe failed.": "Firebase-tokensond misslyckades.",
    "CRITICAL DIAGNOSTIC ERROR": "KRITISKT DIAGNOSTISKT FEL",
    "COPY": "KOPIERA",
    "OPEN LOGS": "ÖPPNA LOGGAR",
    "Firebase": "Firebase",
    "Store": "Lagra",
    "Copy all": "Kopiera alla",
    "Close": "Nära",
    "Auth Probe": "Auth Probe",
    "Write Test": "Skriv test",
    "REST Probe": "REST-sond",
    "Restore Test": "Återställ test",
    "Firebase auth error: user verification failed.":
        "Firebase autentiseringsfel: användarverifiering misslyckades.",
    "Firestore test write successful.": "Firestore testskrivning lyckades.",
    "Firestore test failed.": "Firestore-testet misslyckades.",
    "Firestore auth error: user verification failed.":
        "Firestore autentiseringsfel: användarverifiering misslyckades.",
    "Firestore counter write failed.":
        "Firestore-räknarskrivning misslyckades.",
    "Firestore auth missing: ig_users write blocked.":
        "Firestore-autentisering saknas: ig_users skrivblockering.",
    "Firestore ig_users write failed.":
        "Firestore ig_users skrivning misslyckades.",
    "User": "Användare",
    "Opening consent form...": "Öppnar samtyckesformulär...",
    "Your consent preference was updated.":
        "Ditt samtyckesinställning har uppdaterats.",
    "Consent update failed. Please try again.":
        "Samtyckesuppdatering misslyckades. Försök igen.",
    "Your account is blocked": "Ditt konto är blockerat",
    "Access is restricted for this account.":
        "Åtkomsten är begränsad för det här kontot.",
    "Starting purchase...": "Börjar köpa...",
    "Purchase cancelled.": "Köpet annullerats.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Premium aktiv ✅ Annonser och väntetider är inaktiverade.",
    "Purchase failed. Please try again.": "Köpet misslyckades. Försök igen.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Sessionsverifiering krävs. Verifiera ditt konto i Instagram-appen och försök igen.",
    "Instagram returned no data.": "Instagram returnerade ingen data.",
    "Session verification failed. Please log in again.":
        "Sessionsverifiering misslyckades. Logga in igen.",
    "Open Instagram": "Öppna Instagram",
    "Instagram message": "Instagram meddelande",
    "Loading stories...": "Laddar berättelser...",
    "No data": "Inga data",
    "NEW": "NY",
    "Login": "Inloggning",
    "Session verified, redirecting...": "Session verifierad, omdirigerar...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "ANNONSUTRYMME",
    "Admin mode active": "Adminläge aktivt",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Vi utvecklas varje dag för att ge dig en bättre upplevelse. Din feedback är värdefull för oss – vi vill gärna höra från dig!",
    "Please log in to start the analysis.": "Logga in för att starta analysen.",
    "Welcome, {username}": "Välkommen, {username}",
    "REFRESH DATA": "UPPDATERA DATA",
    "LOG IN WITH INSTAGRAM": "LOGGA IN MED INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Analyserar data...\nDet här kan ta en stund.",
    "Processing data...\nAlmost done.": "Bearbetar data...\nNästan klar.",
    "Loading ad...\nPlease wait.": "Laddar annons...\nVänta.",
    "Google ad warning: {reason}": "Google-annonsvarning: {reason}",
    "All analysis is securely processed locally on your device.":
        "All analys bearbetas säkert lokalt på din enhet.",
    "Total analyses today: {count}": "Totala analyser idag: {count}",
    "Next analysis": "Nästa analys",
    "Ready to scan.": "Klar att skanna.",
    "Analysis available now": "Analys tillgänglig nu",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Analyser är tillgängliga nu, men att köra analyser back-to-back kan utsätta ditt konto för risk.",
    "Please wait": "Vänta",
    "Warning": "Varning",
    "Next analysis: {time}": "Nästa analys: {time}",
    "WATCH AD AND START ANALYSIS": "SE ANNONSEN OCH BÖRJA ANALYS",
    "START ANALYSIS": "BÖRJA ANALYS",
    "Start analysis?": "Börja analysera?",
    "Reset App Data": "Återställ appdata",
    "This will wipe all local data and session cookies. Are you sure?":
        "Detta kommer att radera alla lokala data och sessionscookies. Är du säker?",
    "CANCEL": "AVBOKA",
    "DELETE": "RADERA",
    "Error": "Fel",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Datahämtning misslyckades: {err}\n\nFelsökning: Testa att logga ut och logga in igen.",
    "Followers": "Följare",
    "Following": "Följande",
    "New Followers": "Nya följare",
    "Not Following Back": "Följer inte tillbaka",
    "Lost Followers": "Förlorade följare",
    "Legal Disclaimer": "Juridisk ansvarsfriskrivning",
    "Unfollowed Users": "Användare som inte följs",
    "Rate Us": "Betygsätt oss",
    "Contact Us": "Kontakta oss",
    "Remove Ads & Wait Times": "Ta bort annonser och väntetider",
    "This box is currently under test.": "Denna låda testas för närvarande.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Titta på berättelser i hemlighet eller zooma in profilfoton",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Logga in för att se historier i hemlighet och förstora profilbilder.",
    "Will be shown after the ad, please wait.":
        "Kommer att visas efter annonsen, vänta.",
    "What would you like to do?": "Vad skulle du vilja göra?",
    "Enlarge profile photo": "Förstora profilfoto",
    "Watch story secretly": "Titta på historien i hemlighet",
    "No story data available.": "Inga berättelsedata tillgängliga.",
    "I HAVE READ AND AGREE": "JAG HAR LÄST OCH HÅLLER MED",
    "Withdraw Consent": "Återkalla samtycke",
    "Confirm": "Bekräfta",
    "Your consent settings will be reset. Are you sure?":
        "Dina samtyckesinställningar kommer att återställas. Är du säker?",
    "Yes": "Ja",
    "Cancel": "Avboka",
    "Session verified, redirecting securely...":
        "Session verifierad, omdirigerar säkert...",
    "Analysis complete ✅": "Analysen klar ✅",
    "Purchases are not available right now. Please try again later.":
        "Köp är inte tillgängliga just nu. Försök igen senare.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Köpet genomfört, men Premium är inte aktivt än. Försök igen.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Välkommen till Premium! Annonser och väntetider tas bort.",
    "Your Premium membership is active.": "Ditt Premium-medlemskap är aktivt.",
    "Restore Purchases": "Återställ inköp",
    "RESTORE": "ÅTERSTÄLLA",
    "Restoring purchases...": "Återställer köp...",
    "Purchases restored ✅": "Inköp återställda ✅",
    "No purchases to restore.": "Inga köp att återställa.",
    "Restore failed: {err}": "Återställning misslyckades: {err}",
    "Enter PIN": "Ange PIN-kod",
    "PIN accepted, timer reset ✅": "PIN accepteras, timeråterställning ✅",
    "Invalid PIN": "Ogiltig PIN-kod",
    "OK": "OK",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Genom att ladda ner och använda denna applikation anses varje användare ha läst, förstått och oåterkalleligt accepterat texten \"Användarvillkor och ansvarsfriskrivning\" nedan i förväg:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Artikel 1: Datasekretess och lokal bearbetningsarkitektur",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT är mjukvara på klientsidan. Användarens inloggningsuppgifter (användarnamn, lösenord, sessionscookies) överförs under inga omständigheter till eller lagras på en extern server. Alla databehandlingsaktiviteter sker uteslutande inom det temporära minnet (RAM) och lokal lagring av användarens enhet. Applikationen fungerar som en \"webbläsaromslag\" som fungerar över Instagram-gränssnittet.",
    "Article 2: Third-Party Platform Risks":
        "Artikel 2: Tredjepartsplattformsrisker",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) förbehåller sig rätten att begränsa användningen av programvara från tredje part enligt dess plattformspolicy. Alla risker, inklusive men inte begränsat till \"åtgärdsblockeringar\", \"kontobegränsningar\", \"shadowbans\" eller \"kontostängningar\" som kan uppstå från användningen av applikationen, tillhör endast Användaren. VERDICT-utvecklaren kan inte hållas ansvarig för några direkta eller indirekta skador till följd av sådana administrativa sanktioner.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Artikel 3: Garantifriskrivning och ansvarsbegränsning",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Denna programvara tillhandahålls \"I BEFINTLIGT SKICK\" och \"SOM TILLGÄNGLIG\". 100 % noggrannhet, kontinuitet eller säljbarhet för analysresultaten som tillhandahålls av programvaran garanteras inte. Användaren bekräftar att alla resultat som härrör från juridiska eller kommersiella transaktioner baserade på applikationsdata är deras eget ansvar; och förklarar och åtar sig att hålla utvecklaren oskadlig från alla anspråk, stämningar och klagomål.",
    "Article 4: Intellectual Property and Independence Notice":
        "Artikel 4: Meddelande om immateriella rättigheter och oberoende",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT är ett oberoende utvecklarprojekt. Varumärkena 'Instagram', 'Facebook' och 'Meta' är registrerade varumärken som tillhör Meta Platforms, Inc. Denna applikation har inget kommersiellt partnerskap, sponsringsavtal eller officiell anknytning till de ovan nämnda företagen.",
    "Article 5: Service Continuity and Platform Changes":
        "Artikel 5: Servicekontinuitet och plattformsändringar",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Grundläggande ändringar av Instagram API eller webbinfrastruktur kan göra att applikationen helt eller delvis förlorar sin funktionalitet. Utvecklaren gör inget åtagande att uppdatera applikationen eller underhålla tjänsten som svar på sådana infrastrukturella förändringar, som anses vara \"force majeure\".",
    "Analysis complete, results will be shown after the ad.":
        "Analysen är klar, resultat kommer att visas efter annonsen.",
    "Analysis failed": "Analysen misslyckades",
    "Reason: {reason}": "Orsak: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Tips: Att logga ut och logga in igen kan hjälpa.",
    "Quick check: Counts are the same. No changes detected.":
        "Snabbkontroll: Antalet är detsamma. Inga ändringar upptäcktes.",
    "Daily Metrics": "Dagliga mätvärden",
    "Active users": "Aktiva användare",
    "Daily queries": "Dagliga frågor",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Dataladdningen avbröts: följardata är ofullständig ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Dataladdningen avbröts: följande data är ofullständig ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Dataladdningen avbröts: Instagram returnerade tom data.",
    "Data loading stopped due to an unexpected error.":
        "Dataladdningen stoppades på grund av ett oväntat fel.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram returnerade en varning för automatiskt beteende. Vi slutade hämta data för säkerhets skull.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram begärde säkerhetsverifiering. Verifiera i Instagram-appen och försök igen.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Sessionen är ogiltig eller väntar på verifiering. Logga in igen.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "För många förfrågningar skickades. Dataladdningen avbröts för säkerhets skull.",
    "Data loading could not complete due to a connection issue.":
        "Dataladdningen kunde inte slutföras på grund av ett anslutningsproblem.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram returnerade ett fel (HTTP {code}). Dataladdningen avbröts.",
    "Instagram security verification is required (story data could not be fetched).":
        "Instagram-säkerhetsverifiering krävs (berättelsedata kunde inte hämtas).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Det gick inte att hämta berättelsedata. Vanligtvis orsakas detta av Instagram-verifiering, tillfälliga API-begränsningar eller ett anslutningsavbrott. Försök igen om 2-3 minuter.",
    "Could not fetch story data. Please try again shortly.":
        "Det gick inte att hämta berättelsedata. Försök snart igen.",
    "Secret Mode": "Hemligt läge",
    "Starting VERDICT...": "Startar VERDICT...",
    "DID YOU KNOW?": "VISSTE DU?",
    "Estimated time left: {time}": "Beräknad tid kvar: {time}",
    "Estimating remaining time...": "Beräknar återstående tid...",
    "LOG OUT": "LOGGA UT",
    "Open Profile": "Öppna profil",
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
    "Analysis Time!": "Час аналізу!",
    "CLOSE": "ЗАКРИТИ",
    "SYSTEM UNDER MAINTENANCE": "СИСТЕМА НА ОБСЛУГОВУВАННІ",
    "Bio Planner": "Біопланувальник",
    "Store link not set.": "Посилання на магазин не встановлено.",
    "Invalid store link.": "Недійсне посилання на магазин.",
    "Could not open the link.": "Не вдалося відкрити посилання.",
    "Please try again.": "Спробуйте ще раз.",
    "Show error": "Показати помилку",
    "Exception": "Виняток",
    "Load error": "Помилка завантаження",
    "Code": "Код",
    "Timeout": "Час очікування",
    "REST probe failed: missing auth.":
        "Не вдалося перевірити REST: відсутні авторизації.",
    "REST probe success (Firestore endpoint reachable).":
        "Успішний тест REST (кінцева точка Firestore доступна).",
    "REST probe failed (check logs).":
        "Помилка зонду REST (перевірте журнали).",
    "Firebase Auth probe failed.": "Помилка перевірки автентифікації Firebase.",
    "Firebase Auth probe success.": "Успішне тестування Firebase Auth.",
    "Firebase token probe failed.": "Не вдалося перевірити маркер Firebase.",
    "CRITICAL DIAGNOSTIC ERROR": "КРИТИЧНА ДІАГНОСТИЧНА ПОМИЛКА",
    "COPY": "КОПІЮВАТИ",
    "OPEN LOGS": "ВІДКРИТІ ЖУРНАЛИ",
    "Firebase": "Firebase",
    "Store": "Магазин",
    "Copy all": "Копіювати все",
    "Close": "Закрити",
    "Auth Probe": "Зонд авторизації",
    "Write Test": "Написати тест",
    "REST Probe": "Зонд REST",
    "Restore Test": "Тест відновлення",
    "Firebase auth error: user verification failed.":
        "Помилка автентифікації Firebase: помилка перевірки користувача.",
    "Firestore test write successful.": "Тестовий запис Firestore успішний.",
    "Firestore test failed.": "Тест Firestore не вдався.",
    "Firestore auth error: user verification failed.":
        "Помилка авторизації Firestore: помилка перевірки користувача.",
    "Firestore counter write failed.": "Помилка запису лічильника Firestore.",
    "Firestore auth missing: ig_users write blocked.":
        "Відсутня автентифікація Firestore: запис ig_users заблоковано.",
    "Firestore ig_users write failed.": "Помилка запису Firestore ig_users.",
    "User": "Користувач",
    "Opening consent form...": "Відкриття форми згоди...",
    "Your consent preference was updated.": "Ваші налаштування згоди оновлено.",
    "Consent update failed. Please try again.":
        "Не вдалося оновити згоду. Спробуйте ще раз.",
    "Your account is blocked": "Ваш обліковий запис заблоковано",
    "Access is restricted for this account.":
        "Для цього облікового запису доступ обмежено.",
    "Starting purchase...": "Початок покупки...",
    "Purchase cancelled.": "Покупку скасовано.",
    "Premium active ✅ Ads and wait times are disabled.":
        "Преміум активний ✅ Реклама та час очікування вимкнено.",
    "Purchase failed. Please try again.":
        "Покупка не здійснена. Спробуйте ще раз.",
    "Session verification is required. Please verify your account in the Instagram app and try again.":
        "Потрібна перевірка сесії. Підтвердьте свій обліковий запис у додатку Instagram і повторіть спробу.",
    "Instagram returned no data.": "Instagram не повернув жодних даних.",
    "Session verification failed. Please log in again.":
        "Не вдалося перевірити сеанс. Будь ласка, увійдіть знову.",
    "Open Instagram": "Відкрийте Instagram",
    "Instagram message": "Повідомлення в Instagram",
    "Loading stories...": "Завантаження історій...",
    "No data": "Немає даних",
    "NEW": "НОВИЙ",
    "Login": "Логін",
    "Session verified, redirecting...": "Сеанс перевірено, перенаправлення...",
    "Professional Social Media Solutions":
        "Professional Social Media Solutions",
    "AD SPACE": "РЕКЛАМНЕ МІСЦЕ",
    "Admin mode active": "Активний режим адміністратора",
    "We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!":
        "Ми вдосконалюємося щодня, щоб надати вам кращий досвід. Ваш відгук важливий для нас — ми будемо раді почути від вас!",
    "Please log in to start the analysis.": "Увійдіть, щоб почати аналіз.",
    "Welcome, {username}": "Ласкаво просимо, {username}",
    "REFRESH DATA": "ОНОВИТИ ДАНІ",
    "LOG IN WITH INSTAGRAM": "УВІЙТИ ЗА ДОПОМОГОЮ INSTAGRAM",
    "Analyzing data...\nThis might take a moment.":
        "Аналіз даних...\nЦе може зайняти деякий час.",
    "Processing data...\nAlmost done.": "Обробка даних...\nМайже готово.",
    "Loading ad...\nPlease wait.":
        "Завантаження оголошення...\nБудь ласка, зачекайте.",
    "Google ad warning: {reason}":
        "Попередження про оголошення Google: {reason}",
    "All analysis is securely processed locally on your device.":
        "Весь аналіз безпечно обробляється локально на вашому пристрої.",
    "Total analyses today: {count}": "Усього аналізів за сьогодні: {count}",
    "Next analysis": "Наступний аналіз",
    "Ready to scan.": "Готовий до сканування.",
    "Analysis available now": "Аналіз доступний зараз",
    "Analysis is available now, but running analyses back-to-back may put your account at risk.":
        "Аналіз доступний зараз, але послідовне виконання аналізів може поставити під загрозу ваш обліковий запис.",
    "Please wait": "Будь ласка, зачекайте",
    "Warning": "УВАГА",
    "Next analysis: {time}": "Наступний аналіз: {time}",
    "WATCH AD AND START ANALYSIS": "ДИВІТЬСЯ РЕКЛАМУ ТА ПОЧИНАЙТЕ АНАЛІЗ",
    "START ANALYSIS": "ПОЧАТИ АНАЛІЗ",
    "Start analysis?": "Почати аналіз?",
    "Reset App Data": "Скинути дані програми",
    "This will wipe all local data and session cookies. Are you sure?":
        "Це призведе до видалення всіх локальних даних і файлів cookie сеансу. Ви впевнені?",
    "CANCEL": "СКАСУВАТИ",
    "DELETE": "ВИДАЛИТИ",
    "Error": "Помилка",
    "Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.":
        "Помилка отримання даних: {err}\n\nУсунення несправностей: спробуйте вийти з системи та знову ввійти.",
    "Followers": "Послідовники",
    "Following": "Слідую",
    "New Followers": "Нові підписники",
    "Not Following Back": "Не слідкуйте назад",
    "Lost Followers": "Втрачені послідовники",
    "Legal Disclaimer": "Юридична відмова від відповідальності",
    "Unfollowed Users": "Користувачі, на які скасовано підписку",
    "Rate Us": "Оцініть нас",
    "Contact Us": "Зв'яжіться з нами",
    "Remove Ads & Wait Times": "Видаліть рекламу та час очікування",
    "This box is currently under test.": "Ця коробка зараз тестується.",
    "Watch Stories Secretly or Zoom Profile Photos":
        "Дивіться Stories Secretly або масштабуйте фотографії профілю",
    "Please log in to watch stories secretly and enlarge profile photos.":
        "Увійдіть, щоб таємно переглядати історії та збільшувати фотографії профілю.",
    "Will be shown after the ad, please wait.":
        "Буде показано після оголошення, зачекайте.",
    "What would you like to do?": "Що б ти хотіла зробити?",
    "Enlarge profile photo": "Збільшити фото профілю",
    "Watch story secretly": "Дивіться історію таємно",
    "No story data available.": "Дані історії відсутні.",
    "I HAVE READ AND AGREE": "Я ПРОЧИТАВ І ПОГОДЖУЮСЯ",
    "Withdraw Consent": "Відкликати згоду",
    "Confirm": "Підтвердити",
    "Your consent settings will be reset. Are you sure?":
        "Ваші налаштування згоди буде скинуто. Ви впевнені?",
    "Yes": "так",
    "Cancel": "Скасувати",
    "Session verified, redirecting securely...":
        "Сеанс перевірено, безпечне перенаправлення...",
    "Analysis complete ✅": "Аналіз завершено ✅",
    "Purchases are not available right now. Please try again later.":
        "Покупки зараз недоступні. Спробуйте пізніше.",
    "Purchase completed, but Premium is not active yet. Please try again.":
        "Покупку завершено, але Premium ще не активний. Спробуйте ще раз.",
    "Welcome to Premium! Ads and wait times are removed.":
        "Ласкаво просимо до Premium! Оголошення та час очікування видалено.",
    "Your Premium membership is active.": "Ваше членство Premium активне.",
    "Restore Purchases": "Відновити покупки",
    "RESTORE": "ВІДНОВИТИ",
    "Restoring purchases...": "Відновлення покупок...",
    "Purchases restored ✅": "Покупки відновлено ✅",
    "No purchases to restore.": "Немає покупок для відновлення.",
    "Restore failed: {err}": "Не вдалося відновити: {err}",
    "Enter PIN": "Введіть PIN-код",
    "PIN accepted, timer reset ✅": "PIN прийнято, таймер скинуто ✅",
    "Invalid PIN": "Недійсний PIN-код",
    "OK": "добре",
    "By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the \"Terms of Use and Disclaimer\" text below in advance:":
        "Завантажуючи та використовуючи цю програму, кожен Користувач вважається таким, що заздалегідь прочитав, зрозумів і безповоротно прийняв текст «Умов використання та Відмова від відповідальності» нижче:",
    "Article 1: Data Privacy and Local Processing Architecture":
        "Стаття 1: Конфіденційність даних і архітектура локальної обробки",
    "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.":
        "VERDICT — це «клієнтське» програмне забезпечення. Облікові дані Користувача для входу (ім’я користувача, пароль, сеансові файли cookie) ні в якому разі не передаються на зовнішній сервер і не зберігаються на ньому. Усі дії з обробки даних відбуваються виключно в тимчасовій пам’яті (RAM) і локальному сховищі пристрою Користувача. Програма функціонує як «обгортка браузера», що працює через інтерфейс Instagram.",
    "Article 2: Third-Party Platform Risks":
        "Стаття 2: Ризики платформи третіх сторін",
    "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.":
        "Instagram (Meta Platforms, Inc.) залишає за собою право обмежувати використання стороннього програмного забезпечення відповідно до своєї політики платформи. Усі ризики, включаючи, але не обмежуючись, «блокування дій», «обмеження облікових записів», «тіні» або «закриття облікових записів», які можуть виникнути в результаті використання програми, належать виключно Користувачеві. Розробник VERDICT не несе відповідальності за прямі чи непрямі збитки, спричинені такими адміністративними санкціями.",
    "Article 3: Warranty Disclaimer and Limitation of Liability":
        "Стаття 3: Відмова від гарантії та обмеження відповідальності",
    "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.":
        "Це програмне забезпечення надається «ЯК Є» та «ЯК ДОСТУПНО». 100% точність, безперервність або комерційна придатність результатів аналізу, які надає програмне забезпечення, не гарантуються. Користувач визнає, що будь-які результати, пов’язані з юридичними чи комерційними операціями на основі даних програми, є його власною відповідальністю; і заявляє та зобов'язується захистити розробника від будь-яких претензій, позовів і скарг.",
    "Article 4: Intellectual Property and Independence Notice":
        "Стаття 4: Повідомлення про інтелектуальну власність і незалежність",
    "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.":
        "VERDICT — проект незалежного розробника. Бренди «Instagram», «Facebook» і «Meta» є зареєстрованими торговельними марками Meta Platforms, Inc. Ця програма не має комерційного партнерства, спонсорської угоди чи офіційного зв’язку з вищезазначеними компаніями.",
    "Article 5: Service Continuity and Platform Changes":
        "Стаття 5: безперервність обслуговування та зміни платформи",
    "Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered \"force majeure\".":
        "Фундаментальні зміни в API або веб-інфраструктурі Instagram можуть призвести до часткової або повної втрати функціональності програми. Розробник не зобов’язується оновлювати програму чи підтримувати службу у відповідь на такі інфраструктурні зміни, які вважаються «форс-мажорними обставинами».",
    "Analysis complete, results will be shown after the ad.":
        "Аналіз завершено, результати будуть показані після оголошення.",
    "Analysis failed": "Аналіз не вдалося",
    "Reason: {reason}": "Причина: {reason}",
    "Tip: Logging out and logging back in may help.":
        "Порада. Може допомогти вихід із системи та повторний вхід.",
    "Quick check: Counts are the same. No changes detected.":
        "Швидка перевірка: показники однакові. Змін не виявлено.",
    "Daily Metrics": "Щоденні показники",
    "Active users": "Активні користувачі",
    "Daily queries": "Щоденні запити",
    "--": "--",
    "Data loading was interrupted: follower data incomplete ({fetched}/{total}).":
        "Завантаження даних було перервано: дані підписника неповні ({fetched}/{total}).",
    "Data loading was interrupted: following data incomplete ({fetched}/{total}).":
        "Завантаження даних було перервано: такі дані неповні ({fetched}/{total}).",
    "Data loading was interrupted: Instagram returned empty data.":
        "Завантаження даних було перервано: Instagram повернув порожні дані.",
    "Data loading stopped due to an unexpected error.":
        "Завантаження даних зупинено через неочікувану помилку.",
    "Instagram returned an automated-behavior warning. We stopped fetching data for safety.":
        "Instagram повернув автоматичне попередження про поведінку. З міркувань безпеки ми припинили отримання даних.",
    "Instagram requested security verification. Verify in Instagram app and try again.":
        "Instagram запитав перевірку безпеки. Підтвердьте в додатку Instagram і повторіть спробу.",
    "Session is invalid or waiting for verification. Please log in again.":
        "Сеанс недійсний або очікує перевірки. Будь ласка, увійдіть знову.",
    "Too many requests were sent. Data loading was interrupted for safety.":
        "Надіслано забагато запитів. Завантаження даних було перервано з міркувань безпеки.",
    "Data loading could not complete due to a connection issue.":
        "Не вдалося завантажити дані через проблему з’єднання.",
    "Instagram returned an error (HTTP {code}). Data loading was interrupted.":
        "Instagram повернув помилку (HTTP {code}). Завантаження даних було перервано.",
    "Instagram security verification is required (story data could not be fetched).":
        "Потрібна перевірка безпеки Instagram (не вдалося отримати дані історії).",
    "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.":
        "Не вдалося отримати дані історії. Зазвичай причиною цього є перевірка Instagram, тимчасові обмеження API або переривання з’єднання. Повторіть спробу через 2-3 хвилини.",
    "Could not fetch story data. Please try again shortly.":
        "Не вдалося отримати дані історії. Спробуйте ще раз незабаром.",
    "Secret Mode": "Секретний режим",
    "Starting VERDICT...": "Початок VERDICT...",
    "DID YOU KNOW?": "ЧИ ЗНАЄТЕ ВИ?",
    "Estimated time left: {time}": "Приблизний час, що залишився: {time}",
    "Estimating remaining time...": "Оцінка часу, що залишився...",
    "LOG OUT": "ВИЙТИ",
    "Open Profile": "Відкрийте профіль",
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
