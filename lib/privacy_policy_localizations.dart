// Generated privacy policy localizations.
// Source language: English

import 'dart:convert';

bool _looksLikeMojibake(String value) {
  if (value.isEmpty) return false;
  if (value.contains('\uFFFD')) return true;
  if (_mojibakeC1Pattern.hasMatch(value)) return true;
  if (value.contains('\u00E2\u20AC')) return true; // "â€…"
  if (_mojibakeMarkerPattern.hasMatch(value)) return true;
  if (value.contains('\u00EF\u00BB\u00BF')) return true; // "ï»¿"
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

String _normalizePolicyLang(String lang) {
  final String code = lang.trim().toLowerCase();
  if (code == 'in') return 'id';
  if (code.startsWith('es')) return code == 'es-mx' ? 'es-mx' : 'es';
  return _privacyPolicyBodies.containsKey(code) ? code : 'en';
}

String localizedPrivacyPolicyBody(String lang) {
  final String code = _normalizePolicyLang(lang);
  return _repairMojibakeText(
      _privacyPolicyBodies[code] ?? _privacyPolicyBodies['en']!);
}

String localizedPrivacyPolicyLabel(String lang) {
  final String code = _normalizePolicyLang(lang);
  return _repairMojibakeText(
      _privacyPolicyLabels[code] ?? _privacyPolicyLabels['en']!);
}

String localizedPrivacyPolicyCloseLabel(String lang) {
  final String code = _normalizePolicyLang(lang);
  return _repairMojibakeText(
      _privacyPolicyCloseLabels[code] ?? _privacyPolicyCloseLabels['en']!);
}

String localizedPrivacyPolicyOpenSourceLabel(String lang) {
  final String code = _normalizePolicyLang(lang);
  return _repairMojibakeText(
      _privacyPolicyOpenSourceLabels[code] ??
          _privacyPolicyOpenSourceLabels['en']!);
}

String localizedWithdrawConsentLabel(String lang) {
  final String code = _normalizePolicyLang(lang);
  return _repairMojibakeText(
      _withdrawConsentLabels[code] ?? _withdrawConsentLabels['en']!);
}

const Map<String, String> _privacyPolicyLabels = {
  'tr': 'Gizlilik Politikası',
  'en': 'Privacy Policy',
  'de': 'Datenschutzerklärung',
  'ko': '개인 정보 보호 정책',
  'ja': 'プライバシーポリシー',
  'ru': 'Политика конфиденциальности',
  'pt': 'Política de Privacidade',
  'ar': 'سياسة الخصوصية',
  'es': 'Política de privacidad',
  'es-mx': 'Política de privacidad',
  'hi': 'गोपनीयता नीति',
  'hu': 'Adatvédelmi tájékoztató',
  'zh-hans': '隐私政策',
  'id': 'Kebijakan Privasi',
  'nl': 'Privacybeleid',
  'fr': 'Politique de confidentialité',
  'it': 'Informativa sulla privacy',
  'vi': 'Chính sách bảo mật',
  'th': 'นโยบายความเป็นส่วนตัว',
  'pl': 'Polityka prywatności',
};

const Map<String, String> _privacyPolicyCloseLabels = {
  'tr': 'Kapat',
  'en': 'Close',
  'de': 'Schließen',
  'ko': '닫기',
  'ja': '閉じる',
  'ru': 'Закрыть',
  'pt': 'Fechar',
  'ar': 'إغلاق',
  'es': 'Cerrar',
  'es-mx': 'Cerrar',
  'hi': 'बंद करें',
  'hu': 'Bezárás',
  'zh-hans': '关闭',
  'id': 'Tutup',
  'nl': 'Sluiten',
  'fr': 'Fermer',
  'it': 'Chiudi',
  'vi': 'Đóng',
  'th': 'ปิด',
  'pl': 'Zamknij',
};

const Map<String, String> _privacyPolicyOpenSourceLabels = {
  'tr': 'Kaynak bağlantısını aç',
  'en': 'Open source link',
  'de': 'Quell-Link öffnen',
  'ko': '소스 링크 열기',
  'ja': 'ソースリンクを開く',
  'ru': 'Открыть ссылку на источник',
  'pt': 'Abrir link de origem',
  'ar': 'فتح رابط المصدر',
  'es': 'Abrir enlace de origen',
  'es-mx': 'Abrir enlace de origen',
  'hi': 'स्रोत लिंक खोलें',
  'hu': 'Forráslink megnyitása',
  'zh-hans': '打开来源链接',
  'id': 'Buka tautan sumber',
  'nl': 'Bronlink openen',
  'fr': 'Ouvrir le lien source',
  'it': 'Apri il link sorgente',
  'vi': 'Mở liên kết nguồn',
  'th': 'เปิดลิงก์ต้นทาง',
  'pl': 'Otwórz link źródłowy',
};

const Map<String, String> _withdrawConsentLabels = {
  'tr': 'Rızayı Geri Al',
  'en': 'Withdraw Consent',
  'de': 'Einwilligung widerrufen',
  'ko': '동의 철회',
  'ja': '同意を撤回',
  'ru': 'Отозвать согласие',
  'pt': 'Retirar consentimento',
  'ar': 'سحب الموافقة',
  'es': 'Retirar el consentimiento',
  'es-mx': 'Retirar el consentimiento',
  'hi': 'सहमति वापस लें',
  'hu': 'Hozzájárulás visszavonása',
  'zh-hans': '撤回同意',
  'id': 'Cabut Persetujuan',
  'nl': 'Toestemming intrekken',
  'fr': 'Retirer le consentement',
  'it': 'Revocare il consenso',
  'vi': 'Rút lại sự đồng ý',
  'th': 'ถอนความยินยอม',
  'pl': 'Wycofaj zgodę',
};

const Map<String, String> _privacyPolicyBodies = {
  'tr': '''VERDICT İÇİN GİZLİLİK POLİTİKASI

Bu Gizlilik Politikası, Görkem Ali Cömert tarafından geliştirilen VERDICT'in ("biz", "bize" veya "bizim") mobil uygulamamızı ("Uygulama") kullandığınızda hakkınızdaki bilgileri nasıl topladığını, kullandığını ve ifşa ettiğini açıklamaktadır. Uygulamaya erişerek veya Uygulamayı kullanarak bu Gizlilik Politikasını kabul etmiş olursunuz. Politikalarımızı ve uygulamalarımızı kabul etmiyorsanız Uygulamamızı kullanmamayı tercih edebilirsiniz.

1. Üyeliğe İlişkin Sorumluluk Reddi
VERDICT bağımsız bir üçüncü taraf uygulamasıdır ve Instagram, Facebook veya Meta Platforms, Inc.'e bağlı değildir, bunlar tarafından desteklenmez, desteklenmez veya yönetilmez. "Instagram", Meta Platforms, Inc.'ün ticari markasıdır. Instagram platformunu kesinlikle kullanıcı olarak size sunulan verilere dayalı analiz hizmetleri sağlamak için kullanıyoruz.

2. Topladığımız Bilgiler
Katı bir "Cihaz İçi İşleme" prensibiyle çalışıyoruz. Bu, Uygulamanın temel işlevlerinin cihazınızda yerel olarak depolanan verilere dayandığı anlamına gelir. Kişisel sosyal medya kimlik bilgilerinizi toplamak veya saklamak için bir arka uç sunucusu işletmiyoruz.
A. Kişisel Veriler (Kimlik Doğrulama): Takipçi analizi yapabilmek için Instagram hesabınıza giriş yapmalısınız.
Nasıl çalışır: Uygulama, sizi Instagram'nin resmi giriş sayfasına yönlendirmek için güvenli bir WebView (uygulama içindeki bir tarayıcı bileşeni) kullanır.
Erişimimiz: Şifrenizi görmüyoruz, saklamıyoruz veya aktarmıyoruz. Oturum çerezleriniz ve kimlik doğrulama belirteçleriniz, oturumunuzu sürdürmek için kesinlikle cihazınızın yerel güvenli deposunda (örn. Android SharedPreferences, iOS Keychain) saklanır.
Sunucu Depolama Alanı: Giriş bilgilerinizi veya takipçi listelerinizi bize ait herhangi bir harici sunucuya YÜKLEMİYORUZ.
B. Kullanım ve Cihaz Bilgileri: Biz ve üçüncü taraf hizmet sağlayıcılarımız (Google AdMob, Firebase), uygulama performansını iyileştirmek ve reklam sunmak için cihazınızla ilgili belirli bilgileri otomatik olarak toplayabiliriz. Bu şunları içerebilir:
Cihaz modeli ve üreticisi
İşletim sistemi sürümü
Ağ türü (WiFi/Hücresel)
Reklam Kimliği (Android için AAID / iOS için IDFA)
Kilitlenme günlükleri ve performans verileri

3. Bilgilerinizi Nasıl Kullanıyoruz
Toplanan bilgileri aşağıdaki amaçlarla kullanırız:
Hizmetleri Sağlamak İçin: Takip etmeyenleri, yeni takipçileri ve hayranları belirlemek için cihazınızdaki "Takipçiler" ve "Takip Edilenler" listelerinizi yerel olarak karşılaştırmak.
Uygulamanın Bakımını Yapmak İçin: Uygulama güncellemelerini, bakım modlarını ve özellik geçişlerini yönetmek üzere Firebase Remote Config'yi kullanmak için.
Reklam Sunmak İçin: Bu Uygulamanın ücretsiz olarak kullanılmasına yardımcı olan Google AdMob aracılığıyla ilgili reklamları görüntülemek için.

4. Üçüncü Taraf Hizmetleri ve Veri Paylaşımı
Kişisel verilerinizi satmıyoruz. Ancak reklam ve analiz amacıyla cihazınızı tanımlamak için kullanılan bilgileri toplayabilen güvenilir üçüncü taraf hizmetleri kullanırız. Bu üçüncü taraf hizmet sağlayıcıların gizlilik politikalarını incelemenizi tavsiye ederiz:
Google AdMob: Gizlilik Politikası
Google Firebase: Gizlilik Politikası

5. Veri Saklama ve Silme
Yerel Veriler: Takipçi verileriniz ve oturum çerezleriniz cihazınızda yerel olarak saklandığından kontrol tamamen sizdedir.
Silme: Uygulama tarafından saklanan tüm verileri istediğiniz zaman aşağıdakileri yaparak silebilirsiniz:
Uygulama ayarlarından çıkış yapın.
Telefon ayarlarınızda Uygulamanın "Depolama/Önbellek" kısmını temizleme.
Uygulamanın Kaldırılması. Kaldırıldıktan sonra verilerinize dair hiçbir iz bizde kalmaz.

6. Güvenlik
Kişisel Bilgilerinizi korumak için ticari olarak kabul edilebilir araçları kullanmaya çalışıyoruz. Verileri yerel olarak işleyerek ve yerel depolama için standart şifrelemeyi kullanarak veri ihlali riskini en aza indiriyoruz. Ancak internet üzerinden hiçbir aktarım yöntemi %100 güvenli değildir.

7. Çocukların Gizliliği
Hizmetlerimiz 13 yaşın altındaki kişilere yönelik değildir. 13 yaşın altındaki çocuklardan bilerek kişisel olarak tanımlanabilir bilgiler toplamıyoruz.

8. Bu Gizlilik Politikasındaki Değişiklikler
Gizlilik Politikamızı zaman zaman güncelleyebiliriz. Yeni Gizlilik Politikasını bu sayfada yayınlayarak sizi herhangi bir değişiklik konusunda bilgilendireceğiz. Bu değişiklikler yayınlandıktan hemen sonra yürürlüğe girer.

9. Bize Ulaşın
Herhangi bir sorunuz veya öneriniz varsa bizimle iletişime geçmekten çekinmeyin.''',
  'en': '''PRIVACY POLICY FOR VERDICT

This Privacy Policy explains how VERDICT ("we," "us," or "our"), developed by Görkem Ali Cömert, collects, uses, and discloses information about you when you use our mobile application (the "App"). By accessing or using the App, you agree to this Privacy Policy. If you do not agree with our policies and practices, your choice is not to use our App.

1. Disclaimer regarding Affiliation
VERDICT is an independent third-party application and is not affiliated with, endorsed, sponsored, or administered by, Instagram, Facebook, or Meta Platforms, Inc. "Instagram" is a trademark of Meta Platforms, Inc. We utilize the Instagram platform strictly to provide analysis services based on the data available to you as a user.

2. The Information We Collect
We operate on a strict "On-Device Processing" principle. This means the core functionality of the App relies on data stored locally on your device. We do not operate a backend server to harvest or store your personal social media credentials.
A. Personal Data (Authentication): To perform follower analysis, you must log in to your Instagram account.
How it works: The App uses a secure WebView (a browser component within the app) to direct you to Instagram’s official login page.
Our Access: We DO NOT see, store, or transmit your password. Your session cookies and authentication tokens are stored strictly within the local secure storage of your device (e.g., Android SharedPreferences, iOS Keychain) to maintain your session.
Server Storage: We DO NOT upload your login credentials or your follower lists to any external server owned by us.
B. Usage and Device Information: We, and our third-party service providers (Google AdMob, Firebase), may automatically collect certain information about your device to improve app performance and serve advertisements. This may include:
Device model and manufacturer
Operating system version
Network type (WiFi/Cellular)
Advertising ID (AAID for Android / IDFA for iOS)
Crash logs and performance data

3. How We Use Your Information
We use the information collected for the following purposes:
To Provide Services: To compare your "Followers" and "Following" lists locally on your device to identify unfollowers, new followers, and fans.
To Maintain the App: To use Firebase Remote Config to manage app updates, maintenance modes, and feature toggles.
To Serve Ads: To display relevant advertisements via Google AdMob, which helps keep this App free to use.

4. Third-Party Services and Data Sharing
We do not sell your personal data. However, we use trusted third-party services that may collect information used to identify your device for advertising and analytics purposes. We advise you to review the privacy policies of these third-party service providers:
Google AdMob: Privacy Policy
Google Firebase: Privacy Policy

5. Data Retention and Deletion
Local Data: Since your follower data and session cookies are stored locally on your device, you have full control.
Deletion: You can delete all data stored by the App at any time by:
Logging out via the App settings.
Clearing the App's "Storage/Cache" in your phone settings.
Uninstalling the App. Once uninstalled, no trace of your data remains with us.

6. Security
We strive to use commercially acceptable means to protect your Personal Information. By processing data locally and using standard encryption for local storage, we minimize the risk of data breaches. However, no method of transmission over the internet is 100% secure.

7. Children’s Privacy
Our Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.

8. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted.

9. Contact Us
If you have any questions or suggestions, do not hesitate to contact us.''',
  'de': '''DATENSCHUTZRICHTLINIE FÜR VERDICT

In dieser Datenschutzrichtlinie wird erläutert, wie VERDICT („wir“, „uns“ oder „unser“), entwickelt von Görkem Ali Cömert, Informationen über Sie sammelt, verwendet und offenlegt, wenn Sie unsere mobile Anwendung (die „App“) nutzen. Durch den Zugriff auf oder die Nutzung der App stimmen Sie dieser Datenschutzrichtlinie zu. Wenn Sie mit unseren Richtlinien und Praktiken nicht einverstanden sind, haben Sie die Wahl, unsere App nicht zu nutzen.

1. Haftungsausschluss bezüglich der Zugehörigkeit
VERDICT ist eine unabhängige Drittanbieteranwendung und steht in keiner Verbindung zu Instagram, Facebook oder Meta Platforms, Inc. und wird von diesen nicht unterstützt, gesponsert oder verwaltet.

2. Die von uns erfassten Informationen
Wir arbeiten nach dem strikten „On-Device Processing“-Prinzip. Das bedeutet, dass die Kernfunktionalität der App auf lokal auf Ihrem Gerät gespeicherten Daten basiert. Wir betreiben keinen Backend-Server, um Ihre persönlichen Social-Media-Anmeldeinformationen zu sammeln oder zu speichern.
A. Persönliche Daten (Authentifizierung): Um eine Follower-Analyse durchzuführen, müssen Sie sich bei Ihrem Instagram-Konto anmelden.
So funktioniert es: Die App verwendet ein sicheres WebView (eine Browserkomponente innerhalb der App), um Sie zur offiziellen Anmeldeseite von Instagram weiterzuleiten.
Unser Zugang: Wir sehen, speichern oder übermitteln Ihr Passwort NICHT. Ihre Sitzungscookies und Authentifizierungstoken werden ausschließlich im lokalen sicheren Speicher Ihres Geräts (z. B. Android SharedPreferences, iOS Keychain) gespeichert, um Ihre Sitzung aufrechtzuerhalten.
Serverspeicherung: Wir laden Ihre Anmeldedaten oder Ihre Follower-Listen NICHT auf einen externen Server hoch, der uns gehört.
B. Nutzungs- und Geräteinformationen: Wir und unsere Drittanbieter (Google AdMob, Firebase) erfassen möglicherweise automatisch bestimmte Informationen über Ihr Gerät, um die App-Leistung zu verbessern und Werbung zu schalten. Dies kann Folgendes umfassen:
Gerätemodell und Hersteller
Betriebssystemversion
Netzwerktyp (WLAN/Mobilfunk)
Werbe-ID (AAID für Android / IDFA für iOS)
Absturzprotokolle und Leistungsdaten

3. Wie wir Ihre Daten verwenden
Wir verwenden die gesammelten Informationen für folgende Zwecke:
Zur Bereitstellung von Diensten: Zum Vergleichen Ihrer „Follower“- und „Follower“-Listen lokal auf Ihrem Gerät, um Nicht-Follower, neue Follower und Fans zu identifizieren.
So warten Sie die App: Verwenden Sie Firebase Remote Config, um App-Updates, Wartungsmodi und Funktionsumschaltungen zu verwalten.
Um Anzeigen bereitzustellen: Um relevante Anzeigen über Google AdMob anzuzeigen, was dazu beiträgt, dass die Nutzung dieser App kostenlos bleibt.

4. Dienste Dritter und Datenaustausch
Wir verkaufen Ihre personenbezogenen Daten nicht. Wir nutzen jedoch vertrauenswürdige Drittanbieterdienste, die möglicherweise Informationen zur Identifizierung Ihres Geräts für Werbe- und Analysezwecke sammeln. Wir empfehlen Ihnen, die Datenschutzrichtlinien dieser Drittanbieter zu lesen:
Google AdMob: Datenschutzrichtlinie
Google Firebase: Datenschutzrichtlinie

5. Datenaufbewahrung und -löschung
Lokale Daten: Da Ihre Follower-Daten und Sitzungscookies lokal auf Ihrem Gerät gespeichert werden, haben Sie die volle Kontrolle.
Löschung: Sie können alle von der App gespeicherten Daten jederzeit löschen, indem Sie:
Abmelden über die App-Einstellungen.
Löschen Sie den „Speicher/Cache“ der App in Ihren Telefoneinstellungen.
Deinstallation der App. Nach der Deinstallation verbleiben keine Spuren Ihrer Daten bei uns.

6. Sicherheit
Wir sind bestrebt, kommerziell akzeptable Mittel einzusetzen, um Ihre personenbezogenen Daten zu schützen. Indem wir Daten lokal verarbeiten und Standardverschlüsselung für die lokale Speicherung verwenden, minimieren wir das Risiko von Datenschutzverletzungen. Allerdings ist keine Übertragungsmethode im Internet zu 100 % sicher.

7. Privatsphäre von Kindern
Unsere Dienste richten sich nicht an Personen unter 13 Jahren. Wir erfassen wissentlich keine personenbezogenen Daten von Kindern unter 13 Jahren.

8. Änderungen dieser Datenschutzrichtlinie
Wir können unsere Datenschutzrichtlinie von Zeit zu Zeit aktualisieren. Wir werden Sie über alle Änderungen informieren, indem wir die neue Datenschutzrichtlinie auf dieser Seite veröffentlichen. Diese Änderungen treten sofort nach ihrer Veröffentlichung in Kraft.

9. Kontaktieren Sie uns
Wenn Sie Fragen oder Anregungen haben, zögern Sie nicht, uns zu kontaktieren.''',
  'ko': '''VERDICT에 대한 개인정보 보호정책

본 개인정보 보호정책은 귀하가 당사 모바일 애플리케이션(이하 "앱")을 사용할 때 Görkem Ali Cömert가 개발한 VERDICT("당사", "당사" 또는 "당사의")이 귀하에 대한 정보를 수집, 사용 및 공개하는 방법을 설명합니다. 앱에 액세스하거나 앱을 사용함으로써 귀하는 본 개인정보 보호정책에 동의하게 됩니다. 귀하가 당사의 정책 및 관행에 동의하지 않는 경우 당사 앱을 사용하지 않는 것이 좋습니다.

1. 제휴에 관한 면책조항
VERDICT은 독립적인 제3자 애플리케이션이며 Instagram, Facebook 또는 Meta Platforms, Inc.와 제휴, 승인, 후원 또는 관리되지 않습니다. "Instagram"는 Meta Platforms, Inc.의 상표입니다. 우리는 사용자로서 귀하에게 제공되는 데이터를 기반으로 분석 서비스를 제공하기 위해 Instagram 플랫폼을 엄격하게 활용합니다.

2. 당사가 수집하는 정보
우리는 엄격한 "기기 내 처리" 원칙에 따라 운영됩니다. 이는 앱의 핵심 기능이 귀하의 장치에 로컬로 저장된 데이터에 의존한다는 것을 의미합니다. 당사는 귀하의 개인 소셜 미디어 자격 증명을 수집하거나 저장하기 위해 백엔드 서버를 운영하지 않습니다.
A. 개인 데이터(인증): 팔로어 분석을 수행하려면 Instagram 계정에 로그인해야 합니다.
작동 방식: 앱은 보안 WebView(앱 내의 브라우저 구성 요소)을 사용하여 Instagram의 공식 로그인 페이지로 연결됩니다.
당사의 액세스: 당사는 귀하의 비밀번호를 보거나 저장하거나 전송하지 않습니다. 세션 쿠키와 인증 토큰은 세션을 유지하기 위해 장치의 로컬 보안 저장소(예: Android SharedPreferences, iOS Keychain) 내에 엄격하게 저장됩니다.
서버 저장소: 당사는 귀하의 로그인 자격 증명이나 팔로어 목록을 당사가 소유한 외부 서버에 업로드하지 않습니다.
B. 사용 및 장치 정보: 당사와 당사의 제3자 서비스 제공업체(Google AdMob, Firebase)는 앱 성능을 개선하고 광고를 제공하기 위해 귀하의 장치에 대한 특정 정보를 자동으로 수집할 수 있습니다. 여기에는 다음이 포함될 수 있습니다.
장치 모델 및 제조업체
운영 체제 버전
네트워크 유형(WiFi/셀룰러)
광고 ID(Android용 AAID / iOS용 IDFA)
충돌 로그 및 성능 데이터

3. 당사가 귀하의 정보를 사용하는 방법
당사는 수집된 정보를 다음 목적으로 사용합니다.
서비스 제공: 귀하의 장치에서 로컬로 "팔로워" 및 "팔로잉" 목록을 비교하여 언팔로워, 새로운 팔로어 및 팬을 식별합니다.
앱 유지 관리: Firebase Remote Config을 사용하여 앱 업데이트, 유지 관리 모드 및 기능 전환을 관리합니다.
광고 제공: Google AdMob를 통해 관련 광고를 표시하여 이 앱을 무료로 사용할 수 있도록 도와줍니다.

4. 제3자 서비스 및 데이터 공유
우리는 귀하의 개인 데이터를 판매하지 않습니다. 그러나 당사는 광고 및 분석 목적으로 귀하의 장치를 식별하는 데 사용되는 정보를 수집할 수 있는 신뢰할 수 있는 제3자 서비스를 사용합니다. 당사는 귀하가 다음 제3자 서비스 제공업체의 개인정보 보호정책을 검토할 것을 권장합니다.
Google AdMob: 개인정보 보호정책
Google Firebase: 개인정보 보호정책

5. 데이터 보유 및 삭제
로컬 데이터: 귀하의 팔로어 데이터와 세션 쿠키는 귀하의 장치에 로컬로 저장되므로 귀하는 모든 권한을 갖습니다.
삭제: 귀하는 언제든지 다음 방법으로 앱에 저장된 모든 데이터를 삭제할 수 있습니다.
앱 설정을 통해 로그아웃합니다.
휴대폰 설정에서 앱의 "저장소/캐시"를 지웁니다.
앱 제거. 제거한 후에는 귀하의 데이터에 대한 흔적이 남지 않습니다.

6. 보안
당사는 귀하의 개인정보를 보호하기 위해 상업적으로 허용되는 수단을 사용하려고 노력합니다. 데이터를 로컬에서 처리하고 로컬 저장소에 표준 암호화를 사용하여 데이터 침해 위험을 최소화합니다. 그러나 인터넷을 통한 전송 방법은 100% 안전하지 않습니다.

7. 아동의 개인정보 보호
당사 서비스는 13세 미만의 사용자에게 적용되지 않습니다. 당사는 13세 미만의 어린이로부터 고의로 개인 식별 정보를 수집하지 않습니다.

8. 본 개인정보 보호정책의 변경
당사는 수시로 개인정보 보호정책을 업데이트할 수 있습니다. 당사는 이 페이지에 새로운 개인정보 보호정책을 게시하여 변경 사항을 알려드리겠습니다. 이러한 변경 사항은 게시된 후 즉시 적용됩니다.

9. 문의하기
질문이나 제안 사항이 있으면 주저하지 말고 저희에게 연락해 주세요.''',
  'ja': '''VERDICT のプライバシー ポリシー

このプライバシー ポリシーは、Görkem Ali Cömert によって開発された VERDICT (「当社」、「当社」、または「当社の」) が、お客様が当社のモバイル アプリケーション (「アプリ」) を使用する際にお客様に関する情報をどのように収集、使用、および開示するかを説明します。アプリにアクセスまたは使用すると、このプライバシー ポリシーに同意したことになります。当社のポリシーと慣行に同意できない場合は、当社のアプリを使用しないことを選択してください。

1. 所属に関する免責事項
VERDICT は独立したサードパーティ アプリケーションであり、Instagram、Facebook、または Meta Platforms, Inc. と提携、承認、スポンサー、または管理されていません。 「Instagram」は Meta Platforms, Inc. の商標です。当社は、ユーザーとして利用できるデータに基づいて分析サービスを提供するために Instagram プラットフォームを厳密に利用します。

2. 当社が収集する情報
当社は厳格な「オンデバイス処理」原則に基づいて運営しています。これは、アプリのコア機能がデバイス上にローカルに保存されたデータに依存していることを意味します。当社は、個人のソーシャル メディア認証情報を収集または保存するバックエンド サーバーを運用しません。
A. 個人データ (認証): フォロワー分析を実行するには、Instagram アカウントにログインする必要があります。
仕組み: アプリは安全な WebView (アプリ内のブラウザ コンポーネント) を使用して、Instagram の公式ログイン ページに誘導します。
当社のアクセス: 当社はあなたのパスワードを閲覧、保存、送信することはありません。セッション Cookie と認証トークンは、セッションを維持するために、デバイスのローカルの安全なストレージ (Android SharedPreferences, iOS Keychain など) 内に厳密に保存されます。
サーバーストレージ: 当社が所有する外部サーバーにログイン認証情報やフォロワーリストをアップロードすることはありません。
B. 使用状況およびデバイス情報: 当社および当社のサードパーティ サービス プロバイダー (Google AdMob、Firebase) は、アプリのパフォーマンスを向上させ、広告を配信するために、お客様のデバイスに関する特定の情報を自動的に収集する場合があります。これには以下が含まれる場合があります。
デバイスのモデルとメーカー
オペレーティング システムのバージョン
ネットワークの種類 (WiFi/セルラー)
広告ID (Androidの場合はAAID / iOSの場合はIDFA)
クラッシュログとパフォーマンスデータ

3. お客様の情報の使用方法
当社は収集した情報を次の目的で使用します。
サービスを提供するため: 「フォロワー」リストと「フォロー中」リストをデバイス上でローカルに比較して、フォロー解除者、新規フォロワー、ファンを特定するため。
アプリを保守するには: Firebase Remote Config を使用して、アプリの更新、メンテナンス モード、機能の切り替えを管理します。
広告を配信するには: Google AdMob 経由で関連する広告を表示します。これにより、このアプリを無料で使用できるようになります。

4. サードパーティのサービスとデータ共有
当社はあなたの個人データを販売しません。ただし、当社は、広告や分析の目的でお客様のデバイスを識別するために使用される情報を収集する可能性がある、信頼できるサードパーティのサービスを使用します。以下のサードパーティ サービス プロバイダーのプライバシー ポリシーを確認することをお勧めします。
Google AdMob: プライバシー ポリシー
Google Firebase: プライバシー ポリシー

5. データの保持と削除
ローカル データ: フォロワー データとセッション Cookie はデバイス上にローカルに保存されるため、完全に制御できます。
削除: アプリに保存されているすべてのデータは、次の方法でいつでも削除できます。
アプリの設定からログアウトします。
携帯電話の設定でアプリの「ストレージ/キャッシュ」をクリアします。
アプリのアンインストール。アンインストールすると、データの痕跡は当社に残りません。

6. セキュリティ
当社は、お客様の個人情報を保護するために商業的に許容される手段を使用するよう努めます。データをローカルで処理し、ローカル ストレージに標準の暗号化を使用することで、データ侵害のリスクを最小限に抑えます。ただし、インターネット上で 100% 安全な送信方法はありません。

7. 子供のプライバシー
当社のサービスは 13 歳未満には対応しません。当社は、13 歳未満の子供から故意に個人を特定できる情報を収集しません。

8. 本プライバシーポリシーの変更
当社はプライバシーポリシーを随時更新することがあります。変更があった場合は、このページに新しいプライバシー ポリシーを掲載してお知らせします。これらの変更は、投稿後すぐに有効になります。

9. お問い合わせ
ご質問やご提案がございましたら、お気軽にお問い合わせください。''',
  'ru': '''ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ ДЛЯ VERDICT

В настоящей Политике конфиденциальности объясняется, как VERDICT («мы», «нас» или «наш»), разработанный Görkem Ali Cömert, собирает, использует и раскрывает информацию о вас, когда вы используете наше мобильное приложение («Приложение»). Получая доступ к Приложению или используя его, вы соглашаетесь с настоящей Политикой конфиденциальности. Если вы не согласны с нашей политикой и практикой, вы можете не использовать наше Приложение.

1. Отказ от ответственности в отношении принадлежности
VERDICT является независимым сторонним приложением и не связан, не одобрен, не спонсируется и не администрируется Instagram, Facebook или Meta Platforms, Inc.. «Instagram» является товарным знаком Meta Platforms, Inc.. Мы используем платформу Instagram исключительно для предоставления услуг анализа на основе данных, доступных вам как пользователю.

2. Информация, которую мы собираем
Мы работаем по строгому принципу «Обработка на устройстве». Это означает, что основные функции приложения основаны на данных, хранящихся локально на вашем устройстве. Мы не используем внутренний сервер для сбора или хранения ваших личных учетных данных в социальных сетях.
A. Персональные данные (аутентификация). Чтобы выполнить анализ подписчиков, вам необходимо войти в свою учетную запись Instagram.
Как это работает: приложение использует безопасный WebView (компонент браузера в приложении), чтобы направить вас на официальную страницу входа Instagram.
Наш доступ: Мы НЕ видим, не храним и не передаем ваш пароль. Файлы cookie сеанса и токены аутентификации хранятся строго в локальном безопасном хранилище вашего устройства (например, Android SharedPreferences, iOS Keychain) для поддержания вашего сеанса.
Серверное хранилище: Мы НЕ загружаем ваши учетные данные для входа или списки ваших подписчиков на какой-либо внешний сервер, принадлежащий нам.
Б. Информация об использовании и устройстве. Мы и наши сторонние поставщики услуг (Google AdMob, Firebase) можем автоматически собирать определенную информацию о вашем устройстве для повышения производительности приложения и показа рекламы. Это может включать в себя:
Модель устройства и производитель
Версия операционной системы
Тип сети (Wi-Fi/сотовая связь)
Рекламный идентификатор (AAID для Android/IDFA для iOS)
Журналы сбоев и данные о производительности

3. Как мы используем вашу информацию
Мы используем собранную информацию для следующих целей:
Для предоставления услуг: для сравнения списков «Подписчики» и «Подписчики» локально на вашем устройстве, чтобы идентифицировать отписавшихся, новых подписчиков и поклонников.
Для обслуживания приложения: использовать Firebase Remote Config для управления обновлениями приложения, режимами обслуживания и переключением функций.
Для показа рекламы: для отображения соответствующей рекламы через Google AdMob, что помогает сделать это приложение бесплатным для использования.

4. Сторонние сервисы и обмен данными
Мы не продаем ваши персональные данные. Однако мы используем доверенные сторонние службы, которые могут собирать информацию, используемую для идентификации вашего устройства, в рекламных и аналитических целях. Мы советуем вам ознакомиться с политикой конфиденциальности следующих сторонних поставщиков услуг:
Google AdMob: Политика конфиденциальности
Google Firebase: Политика конфиденциальности

5. Хранение и удаление данных
Локальные данные: поскольку данные ваших подписчиков и файлы cookie сеанса хранятся локально на вашем устройстве, вы имеете полный контроль.
Удаление: Вы можете удалить все данные, хранящиеся в Приложении, в любое время:
Выход из системы через настройки приложения.
Очистите «Хранилище/Кэш» приложения в настройках телефона.
Удаление приложения. После удаления у нас не останется никаких следов ваших данных.

6. Безопасность
Мы стремимся использовать коммерчески приемлемые средства для защиты вашей Личной информации. Обрабатывая данные локально и используя стандартное шифрование для локального хранилища, мы минимизируем риск утечки данных. Однако ни один метод передачи данных через Интернет не является на 100% безопасным.

7. Конфиденциальность детей
Наши Услуги не предназначены для лиц младше 13 лет. Мы сознательно не собираем личную информацию от детей младше 13 лет.

8. Изменения в настоящей Политике конфиденциальности
Мы можем время от времени обновлять нашу Политику конфиденциальности. Мы сообщим вам о любых изменениях, разместив новую Политику конфиденциальности на этой странице. Эти изменения вступают в силу сразу после их публикации.

9. Свяжитесь с нами
Если у вас есть какие-либо вопросы или предложения, не стесняйтесь обращаться к нам.''',
  'pt': '''POLÍTICA DE PRIVACIDADE PARA VERDICT

Esta Política de Privacidade explica como o VERDICT ("nós", "nos" ou "nosso"), desenvolvido por Görkem Ali Cömert, coleta, usa e divulga informações sobre você quando você usa nosso aplicativo móvel (o "Aplicativo"). Ao acessar ou utilizar o App, você concorda com esta Política de Privacidade. Se você não concorda com nossas políticas e práticas, sua opção é não usar nosso Aplicativo.

1. Isenção de responsabilidade quanto à afiliação
VERDICT é um aplicativo de terceiros independente e não é afiliado, endossado, patrocinado ou administrado por Instagram, Facebook ou Meta Platforms, Inc. "Instagram" é uma marca registrada de Meta Platforms, Inc. Utilizamos a plataforma Instagram estritamente para fornecer serviços de análise com base nos dados disponíveis para você como usuário.

2. As informações que coletamos
Operamos com base em um princípio estrito de "processamento no dispositivo". Isso significa que a funcionalidade principal do Aplicativo depende de dados armazenados localmente no seu dispositivo. Não operamos um servidor back-end para coletar ou armazenar suas credenciais pessoais de mídia social.
A. Dados Pessoais (Autenticação): Para realizar a análise do seguidor, você deve fazer login na sua conta Instagram.
Como funciona: O aplicativo usa um WebView seguro (um componente do navegador dentro do aplicativo) para direcioná-lo para a página de login oficial do Instagram.
Nosso acesso: NÃO vemos, armazenamos ou transmitimos sua senha. Seus cookies de sessão e tokens de autenticação são armazenados estritamente no armazenamento local seguro do seu dispositivo (por exemplo, Android SharedPreferences, iOS Keychain) para manter sua sessão.
Armazenamento do servidor: NÃO carregamos suas credenciais de login ou listas de seguidores para nenhum servidor externo de nossa propriedade.
B. Informações de uso e do dispositivo: nós e nossos provedores de serviços terceirizados (Google AdMob, Firebase) podemos coletar automaticamente certas informações sobre o seu dispositivo para melhorar o desempenho do aplicativo e veicular anúncios. Isso pode incluir:
Modelo e fabricante do dispositivo
Versão do sistema operacional
Tipo de rede (WiFi/Celular)
ID de publicidade (AAID para Android / IDFA para iOS)
Logs de falhas e dados de desempenho

3. Como usamos suas informações
Utilizamos as informações coletadas para os seguintes fins:
Para fornecer serviços: para comparar suas listas de "Seguidores" e "Seguidores" localmente em seu dispositivo para identificar não seguidores, novos seguidores e fãs.
Para manter o aplicativo: Para usar Firebase Remote Config para gerenciar atualizações de aplicativos, modos de manutenção e alternância de recursos.
Para veicular anúncios: para exibir anúncios relevantes por meio de Google AdMob, o que ajuda a manter o uso deste aplicativo gratuito.

4. Serviços de terceiros e compartilhamento de dados
Não vendemos os seus dados pessoais. No entanto, utilizamos serviços de terceiros confiáveis ​​que podem coletar informações usadas para identificar o seu dispositivo para fins de publicidade e análise. Aconselhamos você a revisar as políticas de privacidade destes provedores de serviços terceirizados:
Google AdMob: Política de Privacidade
Google Firebase: Política de Privacidade

5. Retenção e exclusão de dados
Dados locais: como os dados dos seus seguidores e os cookies da sessão são armazenados localmente no seu dispositivo, você tem controle total.
Exclusão: Você pode excluir todos os dados armazenados pelo Aplicativo a qualquer momento:
Efetuando logout através das configurações do aplicativo.
Limpando o "Armazenamento/Cache" do aplicativo nas configurações do telefone.
Desinstalando o aplicativo. Uma vez desinstalado, nenhum vestígio dos seus dados permanece conosco.

6. Segurança
Nós nos esforçamos para usar meios comercialmente aceitáveis para proteger suas informações pessoais. Ao processar dados localmente e usar criptografia padrão para armazenamento local, minimizamos o risco de violações de dados. No entanto, nenhum método de transmissão pela Internet é 100% seguro.

7. Privacidade das Crianças
Nossos serviços não se destinam a menores de 13 anos. Não coletamos intencionalmente informações de identificação pessoal de crianças menores de 13 anos.

8. Alterações nesta Política de Privacidade
Poderemos atualizar nossa Política de Privacidade de tempos em tempos. Iremos notificá-lo sobre quaisquer alterações publicando a nova Política de Privacidade nesta página. Essas alterações entram em vigor imediatamente após serem publicadas.

9. Contate-nos
Se você tiver alguma dúvida ou sugestão, não hesite em nos contatar.''',
  'ar': '''سياسة الخصوصية لـ VERDICT

تشرح سياسة الخصوصية هذه كيف يقوم VERDICT ("نحن" أو "لنا" أو "خاصتنا")، الذي طوره Görkem Ali Cömert، بجمع المعلومات الخاصة بك واستخدامها والكشف عنها عند استخدام تطبيق الهاتف المحمول الخاص بنا ("التطبيق"). من خلال الوصول إلى التطبيق أو استخدامه، فإنك توافق على سياسة الخصوصية هذه. إذا كنت لا توافق على سياساتنا وممارساتنا، فلديك خيار عدم استخدام تطبيقنا.

1. إخلاء المسؤولية فيما يتعلق بالانتساب
VERDICT هو تطبيق مستقل تابع لجهة خارجية ولا ينتمي إلى Instagram أو Facebook أو Meta Platforms, Inc.، أو Instagram، أو يدعمه أو يرعاه أو يديره.

2. المعلومات التي نجمعها
نحن نعمل وفقًا لمبدأ "المعالجة على الجهاز" الصارم. وهذا يعني أن الوظيفة الأساسية للتطبيق تعتمد على البيانات المخزنة محليًا على جهازك. نحن لا نقوم بتشغيل خادم خلفي لجمع أو تخزين بيانات اعتماد الوسائط الاجتماعية الشخصية الخاصة بك.
أ. البيانات الشخصية (المصادقة): لإجراء تحليل المتابعين، يجب عليك تسجيل الدخول إلى حساب Instagram الخاص بك.
كيف يعمل: يستخدم التطبيق WebView الآمن (أحد مكونات المتصفح داخل التطبيق) لتوجيهك إلى صفحة تسجيل الدخول الرسمية لـ Instagram.
وصولنا: نحن لا نرى كلمة المرور الخاصة بك أو نخزنها أو نرسلها. يتم تخزين ملفات تعريف الارتباط الخاصة بجلستك ورموز المصادقة بشكل صارم داخل وحدة التخزين المحلية الآمنة لجهازك (على سبيل المثال، Android SharedPreferences, iOS Keychain) للحفاظ على جلستك.
تخزين الخادم: لا نقوم بتحميل بيانات اعتماد تسجيل الدخول الخاصة بك أو قوائم المتابعين لديك إلى أي خادم خارجي مملوك لنا.
ب. معلومات الاستخدام والجهاز: قد نقوم نحن ومقدمو خدمات الطرف الثالث (Google AdMob، Firebase) بجمع معلومات معينة حول جهازك تلقائيًا لتحسين أداء التطبيق وعرض الإعلانات. قد يشمل ذلك:
طراز الجهاز والشركة المصنعة
إصدار نظام التشغيل
نوع الشبكة (واي فاي/خلوي)
معرف الإعلان (AAID لنظام Android / IDFA لنظام التشغيل iOS)
سجلات الأعطال وبيانات الأداء

3. كيف نستخدم معلوماتك
نحن نستخدم المعلومات التي تم جمعها للأغراض التالية:
لتقديم الخدمات: لمقارنة قوائم "المتابعين" و"المتابعين" محليًا على جهازك لتحديد المتابعين والمتابعين الجدد والمعجبين.
لصيانة التطبيق: لاستخدام Firebase Remote Config لإدارة تحديثات التطبيق وأوضاع الصيانة وتبديل الميزات.
لعرض الإعلانات: لعرض الإعلانات ذات الصلة عبر Google AdMob، مما يساعد على إبقاء هذا التطبيق مجانيًا للاستخدام.

4. خدمات الطرف الثالث ومشاركة البيانات
نحن لا نبيع بياناتك الشخصية. ومع ذلك، فإننا نستخدم خدمات موثوقة تابعة لجهات خارجية والتي قد تجمع المعلومات المستخدمة لتحديد جهازك لأغراض الإعلان والتحليلات. ننصحك بمراجعة سياسات الخصوصية لمقدمي خدمات الطرف الثالث هؤلاء:
Google AdMob: سياسة الخصوصية
Google Firebase: سياسة الخصوصية

5. الاحتفاظ بالبيانات وحذفها
البيانات المحلية: بما أن بيانات متابعيك وملفات تعريف الارتباط الخاصة بالجلسة يتم تخزينها محليًا على جهازك، فلديك السيطرة الكاملة.
الحذف: يمكنك حذف جميع البيانات المخزنة بواسطة التطبيق في أي وقت عن طريق:
تسجيل الخروج عبر إعدادات التطبيق.
مسح "التخزين/ذاكرة التخزين المؤقت" للتطبيق في إعدادات هاتفك.
إلغاء تثبيت التطبيق. بمجرد إلغاء التثبيت، لن يبقى أي أثر لبياناتك معنا.

6. الأمن
نحن نسعى جاهدين لاستخدام وسائل مقبولة تجاريًا لحماية معلوماتك الشخصية. ومن خلال معالجة البيانات محليًا واستخدام التشفير القياسي للتخزين المحلي، فإننا نقلل من مخاطر اختراق البيانات. ومع ذلك، لا توجد وسيلة نقل عبر الإنترنت آمنة بنسبة 100%.

7. خصوصية الأطفال
خدماتنا لا تستهدف أي شخص يقل عمره عن 13 عامًا. ونحن لا نجمع معلومات التعريف الشخصية عن عمد من الأطفال الذين تقل أعمارهم عن 13 عامًا.

8. التغييرات في سياسة الخصوصية هذه
قد نقوم بتحديث سياسة الخصوصية الخاصة بنا من وقت لآخر. وسوف نقوم بإعلامك بأي تغييرات عن طريق نشر سياسة الخصوصية الجديدة على هذه الصفحة. تسري هذه التغييرات فورًا بعد نشرها.

9. اتصل بنا
إذا كان لديك أي أسئلة أو اقتراحات، فلا تتردد في الاتصال بنا.''',
  'es': '''POLÍTICA DE PRIVACIDAD PARA VERDICT

Esta Política de Privacidad explica cómo VERDICT ("nosotros", "nos" o "nuestro"), desarrollado por Görkem Ali Cömert, recopila, utiliza y divulga información sobre usted cuando utiliza nuestra aplicación móvil (la "Aplicación"). Al acceder o utilizar la aplicación, acepta esta Política de privacidad. Si no está de acuerdo con nuestras políticas y prácticas, su opción es no utilizar nuestra aplicación.

1. Descargo de responsabilidad sobre la afiliación
VERDICT es una aplicación de terceros independiente y no está afiliada, respaldada, patrocinada ni administrada por Instagram, Facebook o Meta Platforms, Inc.. "Instagram" es una marca comercial de Meta Platforms, Inc. Utilizamos la plataforma Instagram estrictamente para proporcionar servicios de análisis basados en los datos disponibles para usted como usuario.

2. La información que recopilamos
Operamos según un estricto principio de "procesamiento en el dispositivo". Esto significa que la funcionalidad principal de la aplicación se basa en datos almacenados localmente en su dispositivo. No operamos un servidor backend para recopilar o almacenar sus credenciales personales de redes sociales.
A. Datos personales (Autenticación): Para realizar un análisis de seguidores, debe iniciar sesión en su cuenta Instagram.
Cómo funciona: la aplicación utiliza un WebView seguro (un componente del navegador dentro de la aplicación) para dirigirlo a la página de inicio de sesión oficial de Instagram.
Nuestro acceso: NO vemos, almacenamos ni transmitimos su contraseña. Las cookies de sesión y los tokens de autenticación se almacenan estrictamente dentro del almacenamiento seguro local de su dispositivo (por ejemplo, Android SharedPreferences, iOS Keychain) para mantener su sesión.
Almacenamiento en el servidor: NO subimos sus credenciales de inicio de sesión ni sus listas de seguidores a ningún servidor externo de nuestra propiedad.
B. Información de uso y del dispositivo: Nosotros y nuestros proveedores de servicios externos (Google AdMob, Firebase) podemos recopilar automáticamente cierta información sobre su dispositivo para mejorar el rendimiento de la aplicación y publicar anuncios. Esto puede incluir:
Modelo y fabricante del dispositivo.
Versión del sistema operativo
Tipo de red (WiFi/Celular)
ID de publicidad (AAID para Android / IDFA para iOS)
Registros de fallos y datos de rendimiento

3. Cómo utilizamos su información
Utilizamos la información recopilada para los siguientes fines:
Para proporcionar servicios: para comparar sus listas de "Seguidores" y "Seguidores" localmente en su dispositivo para identificar a los que no siguen, a los nuevos seguidores y a los fans.
Para mantener la aplicación: Para usar Firebase Remote Config para administrar actualizaciones de aplicaciones, modos de mantenimiento y alternancia de funciones.
Para publicar anuncios: para mostrar anuncios relevantes a través de Google AdMob, lo que ayuda a que esta aplicación sea de uso gratuito.

4. Servicios de terceros e intercambio de datos
No vendemos sus datos personales. Sin embargo, utilizamos servicios de terceros confiables que pueden recopilar información utilizada para identificar su dispositivo con fines publicitarios y analíticos. Le recomendamos revisar las políticas de privacidad de estos proveedores de servicios externos:
Google AdMob: Política de privacidad
Google Firebase: Política de privacidad

5. Retención y eliminación de datos
Datos locales: dado que los datos de sus seguidores y las cookies de sesión se almacenan localmente en su dispositivo, usted tiene control total.
Eliminación: Puede eliminar todos los datos almacenados por la Aplicación en cualquier momento mediante:
Cerrar sesión a través de la configuración de la aplicación.
Borrar el "Almacenamiento/Caché" de la aplicación en la configuración de su teléfono.
Desinstalar la aplicación. Una vez desinstalado, no queda ningún rastro de sus datos con nosotros.

6. Seguridad
Nos esforzamos por utilizar medios comercialmente aceptables para proteger su información personal. Al procesar datos localmente y utilizar cifrado estándar para el almacenamiento local, minimizamos el riesgo de violaciones de datos. Sin embargo, ningún método de transmisión por Internet es 100% seguro.

7. Privacidad de los niños
Nuestros Servicios no se dirigen a ninguna persona menor de 13 años. No recopilamos intencionadamente información de identificación personal de niños menores de 13 años.

8. Cambios a esta Política de Privacidad
Podemos actualizar nuestra Política de Privacidad de vez en cuando. Le notificaremos cualquier cambio publicando la nueva Política de Privacidad en esta página. Estos cambios entran en vigor inmediatamente después de su publicación.

9. Contáctenos
Si tienes alguna duda o sugerencia, no dudes en contactar con nosotros.''',
  'es-mx': '''POLÍTICA DE PRIVACIDAD PARA VERDICT

Esta Política de Privacidad explica cómo VERDICT ("nosotros", "nos" o "nuestro"), desarrollado por Görkem Ali Cömert, recopila, utiliza y divulga información sobre usted cuando utiliza nuestra aplicación móvil (la "Aplicación"). Al acceder o utilizar la aplicación, acepta esta Política de privacidad. Si no está de acuerdo con nuestras políticas y prácticas, su opción es no utilizar nuestra aplicación.

1. Descargo de responsabilidad sobre la afiliación
VERDICT es una aplicación de terceros independiente y no está afiliada, respaldada, patrocinada ni administrada por Instagram, Facebook o Meta Platforms, Inc.. "Instagram" es una marca comercial de Meta Platforms, Inc. Utilizamos la plataforma Instagram estrictamente para proporcionar servicios de análisis basados en los datos disponibles para usted como usuario.

2. La información que recopilamos
Operamos según un estricto principio de "procesamiento en el dispositivo". Esto significa que la funcionalidad principal de la aplicación se basa en datos almacenados localmente en su dispositivo. No operamos un servidor backend para recopilar o almacenar sus credenciales personales de redes sociales.
A. Datos personales (Autenticación): Para realizar un análisis de seguidores, debe iniciar sesión en su cuenta Instagram.
Cómo funciona: la aplicación utiliza un WebView seguro (un componente del navegador dentro de la aplicación) para dirigirlo a la página de inicio de sesión oficial de Instagram.
Nuestro acceso: NO vemos, almacenamos ni transmitimos su contraseña. Las cookies de sesión y los tokens de autenticación se almacenan estrictamente dentro del almacenamiento seguro local de su dispositivo (por ejemplo, Android SharedPreferences, iOS Keychain) para mantener su sesión.
Almacenamiento en el servidor: NO subimos sus credenciales de inicio de sesión ni sus listas de seguidores a ningún servidor externo de nuestra propiedad.
B. Información de uso y del dispositivo: Nosotros y nuestros proveedores de servicios externos (Google AdMob, Firebase) podemos recopilar automáticamente cierta información sobre su dispositivo para mejorar el rendimiento de la aplicación y publicar anuncios. Esto puede incluir:
Modelo y fabricante del dispositivo.
Versión del sistema operativo
Tipo de red (WiFi/Celular)
ID de publicidad (AAID para Android / IDFA para iOS)
Registros de fallos y datos de rendimiento

3. Cómo utilizamos su información
Utilizamos la información recopilada para los siguientes fines:
Para proporcionar servicios: para comparar sus listas de "Seguidores" y "Seguidores" localmente en su dispositivo para identificar a los que no siguen, a los nuevos seguidores y a los fans.
Para mantener la aplicación: Para usar Firebase Remote Config para administrar actualizaciones de aplicaciones, modos de mantenimiento y alternancia de funciones.
Para publicar anuncios: para mostrar anuncios relevantes a través de Google AdMob, lo que ayuda a que esta aplicación sea de uso gratuito.

4. Servicios de terceros e intercambio de datos
No vendemos sus datos personales. Sin embargo, utilizamos servicios de terceros confiables que pueden recopilar información utilizada para identificar su dispositivo con fines publicitarios y analíticos. Le recomendamos revisar las políticas de privacidad de estos proveedores de servicios externos:
Google AdMob: Política de privacidad
Google Firebase: Política de privacidad

5. Retención y eliminación de datos
Datos locales: dado que los datos de sus seguidores y las cookies de sesión se almacenan localmente en su dispositivo, usted tiene control total.
Eliminación: Puede eliminar todos los datos almacenados por la Aplicación en cualquier momento mediante:
Cerrar sesión a través de la configuración de la aplicación.
Borrar el "Almacenamiento/Caché" de la aplicación en la configuración de su teléfono.
Desinstalar la aplicación. Una vez desinstalado, no queda ningún rastro de sus datos con nosotros.

6. Seguridad
Nos esforzamos por utilizar medios comercialmente aceptables para proteger su información personal. Al procesar datos localmente y utilizar cifrado estándar para el almacenamiento local, minimizamos el riesgo de violaciones de datos. Sin embargo, ningún método de transmisión por Internet es 100% seguro.

7. Privacidad de los niños
Nuestros Servicios no se dirigen a ninguna persona menor de 13 años. No recopilamos intencionadamente información de identificación personal de niños menores de 13 años.

8. Cambios a esta Política de Privacidad
Podemos actualizar nuestra Política de Privacidad de vez en cuando. Le notificaremos cualquier cambio publicando la nueva Política de Privacidad en esta página. Estos cambios entran en vigor inmediatamente después de su publicación.

9. Contáctenos
Si tienes alguna duda o sugerencia, no dudes en contactar con nosotros.''',
  'hi': '''VERDICT के लिए गोपनीयता नीति

यह गोपनीयता नीति बताती है कि गोरकेम अली कोमर्ट द्वारा विकसित VERDICT ("हम," "हमें," या "हमारा"), जब आप हमारे मोबाइल एप्लिकेशन ("ऐप") का उपयोग करते हैं तो आपके बारे में जानकारी कैसे एकत्र, उपयोग और खुलासा करता है। ऐप तक पहुंच या उपयोग करके, आप इस गोपनीयता नीति से सहमत हैं। यदि आप हमारी नीतियों और प्रथाओं से सहमत नहीं हैं, तो आपकी पसंद हमारे ऐप का उपयोग नहीं करना है।

1. संबद्धता के संबंध में अस्वीकरण
VERDICT एक स्वतंत्र तृतीय-पक्ष एप्लिकेशन है और यह Instagram, Facebook, या Meta Platforms, Inc. से संबद्ध, समर्थित, प्रायोजित या प्रशासित नहीं है।

2. जो जानकारी हम एकत्र करते हैं
हम सख्त "ऑन-डिवाइस प्रोसेसिंग" सिद्धांत पर काम करते हैं। इसका मतलब है कि ऐप की मुख्य कार्यक्षमता आपके डिवाइस पर स्थानीय रूप से संग्रहीत डेटा पर निर्भर करती है। हम आपके व्यक्तिगत सोशल मीडिया क्रेडेंशियल्स को इकट्ठा करने या संग्रहीत करने के लिए बैकएंड सर्वर संचालित नहीं करते हैं।
ए. व्यक्तिगत डेटा (प्रमाणीकरण): अनुयायी विश्लेषण करने के लिए, आपको अपने Instagram खाते में लॉग इन करना होगा।
यह कैसे काम करता है: ऐप आपको Instagram के आधिकारिक लॉगिन पेज पर निर्देशित करने के लिए एक सुरक्षित WebView (ऐप के भीतर एक ब्राउज़र घटक) का उपयोग करता है।
हमारी पहुंच: हम आपका पासवर्ड नहीं देखते, संग्रहीत या संचारित नहीं करते। आपके सत्र को बनाए रखने के लिए आपके सत्र कुकीज़ और प्रमाणीकरण टोकन आपके डिवाइस के स्थानीय सुरक्षित भंडारण (उदाहरण के लिए, Android SharedPreferences, iOS Keychain) के भीतर सख्ती से संग्रहीत किए जाते हैं।
सर्वर संग्रहण: हम आपके लॉगिन क्रेडेंशियल या आपके अनुयायी सूचियों को हमारे स्वामित्व वाले किसी भी बाहरी सर्वर पर अपलोड नहीं करते हैं।
बी. उपयोग और डिवाइस जानकारी: हम और हमारे तृतीय-पक्ष सेवा प्रदाता (Google AdMob, फायरबेस), ऐप के प्रदर्शन को बेहतर बनाने और विज्ञापन पेश करने के लिए स्वचालित रूप से आपके डिवाइस के बारे में कुछ जानकारी एकत्र कर सकते हैं। इसमें शामिल हो सकते हैं:
डिवाइस मॉडल और निर्माता
ऑपरेटिंग सिस्टम संस्करण
नेटवर्क प्रकार (वाईफ़ाई/सेलुलर)
विज्ञापन आईडी (एंड्रॉइड के लिए एएआईडी/आईओएस के लिए आईडीएफए)
क्रैश लॉग और प्रदर्शन डेटा

3. हम आपकी जानकारी का उपयोग कैसे करते हैं
हम एकत्रित जानकारी का उपयोग निम्नलिखित उद्देश्यों के लिए करते हैं:
सेवाएं प्रदान करने के लिए: अनफॉलोर्स, नए फॉलोअर्स और प्रशंसकों की पहचान करने के लिए अपने डिवाइस पर स्थानीय रूप से अपने "फॉलोअर्स" और "फॉलोइंग" सूचियों की तुलना करना।
ऐप को बनाए रखने के लिए: ऐप अपडेट, रखरखाव मोड और फीचर टॉगल को प्रबंधित करने के लिए Firebase Remote Config का उपयोग करें।
विज्ञापन परोसने के लिए: Google AdMob के माध्यम से प्रासंगिक विज्ञापन प्रदर्शित करने के लिए, जो इस ऐप को उपयोग के लिए निःशुल्क रखने में मदद करता है।

4. तृतीय-पक्ष सेवाएँ और डेटा साझाकरण
हम आपका व्यक्तिगत डेटा नहीं बेचते हैं. हालाँकि, हम विश्वसनीय तृतीय-पक्ष सेवाओं का उपयोग करते हैं जो विज्ञापन और विश्लेषण उद्देश्यों के लिए आपके डिवाइस की पहचान करने के लिए उपयोग की जाने वाली जानकारी एकत्र कर सकती हैं। हम आपको इन तृतीय-पक्ष सेवा प्रदाताओं की गोपनीयता नीतियों की समीक्षा करने की सलाह देते हैं:
Google AdMob: गोपनीयता नीति
Google Firebase: गोपनीयता नीति

5. डेटा प्रतिधारण और विलोपन
स्थानीय डेटा: चूंकि आपका अनुयायी डेटा और सत्र कुकीज़ आपके डिवाइस पर स्थानीय रूप से संग्रहीत हैं, इसलिए आपका पूर्ण नियंत्रण है।
हटाना: आप ऐप द्वारा संग्रहीत सभी डेटा को किसी भी समय हटा सकते हैं:
ऐप सेटिंग्स के माध्यम से लॉग आउट करना।
अपने फ़ोन की सेटिंग में ऐप का "स्टोरेज/कैश" साफ़ करना।
ऐप को अनइंस्टॉल कर रहा हूं. एक बार अनइंस्टॉल करने के बाद, आपके डेटा का कोई भी निशान हमारे पास नहीं रहता है।

6. सुरक्षा
हम आपकी व्यक्तिगत जानकारी की सुरक्षा के लिए व्यावसायिक रूप से स्वीकार्य साधनों का उपयोग करने का प्रयास करते हैं। डेटा को स्थानीय रूप से संसाधित करके और स्थानीय भंडारण के लिए मानक एन्क्रिप्शन का उपयोग करके, हम डेटा उल्लंघनों के जोखिम को कम करते हैं। हालाँकि, इंटरनेट पर प्रसारण का कोई भी तरीका 100% सुरक्षित नहीं है।

7. बच्चों की गोपनीयता
हमारी सेवाएँ 13 वर्ष से कम उम्र के किसी भी व्यक्ति को संबोधित नहीं करती हैं। हम जानबूझकर 13 वर्ष से कम उम्र के बच्चों से व्यक्तिगत रूप से पहचान योग्य जानकारी एकत्र नहीं करते हैं।

8. इस गोपनीयता नीति में परिवर्तन
हम समय-समय पर अपनी गोपनीयता नीति को अपडेट कर सकते हैं। हम इस पृष्ठ पर नई गोपनीयता नीति पोस्ट करके आपको किसी भी बदलाव के बारे में सूचित करेंगे। ये परिवर्तन पोस्ट किए जाने के तुरंत बाद प्रभावी होते हैं।

9. हमसे संपर्क करें
यदि आपके कोई प्रश्न या सुझाव हैं, तो हमसे संपर्क करने में संकोच न करें।''',
  'hu': '''AZ VERDICT ADATVÉDELMI IRÁNYELVE

Ez az adatvédelmi szabályzat elmagyarázza, hogy a Görkem Ali Cömert által kifejlesztett VERDICT ("mi", "minket" vagy "miénk") hogyan gyűjti, használja fel és hozza nyilvánosságra Önre vonatkozó információkat, amikor Ön mobilalkalmazásunkat (a továbbiakban: "Alkalmazás") használja. Az Alkalmazás elérésével vagy használatával Ön elfogadja a jelen Adatvédelmi szabályzatot. Ha nem ért egyet irányelveinkkel és gyakorlatainkkal, úgy dönt, hogy nem használja az alkalmazásunkat.

1. A társulással kapcsolatos felelősség kizárása
Az VERDICT egy független, harmadik féltől származó alkalmazás, amely nem áll kapcsolatban, nem támogatja, nem szponzorálja vagy nem adminisztrálja az Instagram, Facebook vagy Meta Platforms, Inc.. Az Instagram az Meta Platforms, Inc. védjegye. felhasználó.

2. Az általunk gyűjtött információk
Szigorú „eszközön történő feldolgozás” elve alapján működünk. Ez azt jelenti, hogy az alkalmazás alapvető funkciói az eszközön helyileg tárolt adatokon alapulnak. Nem üzemeltetünk háttérkiszolgálót az Ön személyes közösségi média hitelesítő adatainak begyűjtésére vagy tárolására.
A. Személyes adatok (hitelesítés): A követőelemzés elvégzéséhez be kell jelentkeznie Instagram fiókjába.
Hogyan működik: Az alkalmazás egy biztonságos WebView (az alkalmazáson belüli böngészőkomponens) segítségével irányítja Önt az Instagram hivatalos bejelentkezési oldalára.
Hozzáférésünk: NEM látjuk, nem tároljuk vagy továbbítjuk jelszavát. A munkamenet cookie-jait és hitelesítési tokenjeit szigorúan az eszköz helyi biztonságos tárhelyén (pl. Android SharedPreferences, iOS Keychain) tároljuk a munkamenet fenntartása érdekében.
Szerver tárolása: NEM töltjük fel bejelentkezési adatait vagy követői listáját semmilyen, a tulajdonunkban lévő külső szerverre.
B. Használati és eszközinformációk: Mi és külső szolgáltatóink (Google AdMob, Firebase) automatikusan gyűjthetünk bizonyos információkat az eszközről az alkalmazások teljesítményének javítása és a hirdetések megjelenítése érdekében. Ez a következőket foglalhatja magában:
A készülék típusa és gyártója
Operációs rendszer verziója
Hálózat típusa (WiFi/mobil)
Hirdetésazonosító (AAID Androidhoz / IDFA iOS-hez)
Összeomlási naplók és teljesítményadatok

3. Hogyan használjuk fel az Ön adatait
Az összegyűjtött információkat a következő célokra használjuk fel:
Szolgáltatások nyújtása: A „Követők” és a „Követés” listák helyi összehasonlítása az eszközön, hogy azonosítsa a nem követőket, az új követőket és a rajongókat.
Az alkalmazás karbantartása: Az Firebase Remote Config használata az alkalmazásfrissítések, a karbantartási módok és a funkcióváltások kezelésére.
Hirdetések megjelenítése: Releváns hirdetések megjelenítése az Google AdMob segítségével, ami segít az alkalmazás ingyenes használatában.

4. Harmadik féltől származó szolgáltatások és adatmegosztás
Személyes adatait nem adjuk el. Mindazonáltal megbízható, harmadik féltől származó szolgáltatásokat használunk, amelyek hirdetési és elemzési célból információkat gyűjthetnek az eszköz azonosítására. Javasoljuk, hogy tekintse át az alábbi harmadik fél szolgáltatók adatvédelmi szabályzatát:
Google AdMob: Adatvédelmi szabályzat
Google Firebase: Adatvédelmi szabályzat

5. Adatmegőrzés és -törlés
Helyi adatok: Mivel a követői adatait és a munkamenet-cookie-kat helyileg tárolják az eszközén, teljes mértékben Ön rendelkezik a szabályozással.
Törlés: Az Alkalmazás által tárolt összes adatot bármikor törölheti:
Kijelentkezés az alkalmazás beállításain keresztül.
Törölje az alkalmazás „Tárhely/Gyorsítótár” elemét a telefon beállításaiban.
Az alkalmazás eltávolítása. Az eltávolítás után adatainak nyoma sem marad nálunk.

6. Biztonság
Arra törekszünk, hogy kereskedelmileg elfogadható eszközöket alkalmazzunk személyes adatainak védelme érdekében. Az adatok helyi feldolgozásával és szabványos titkosítással a helyi tároláshoz minimálisra csökkentjük az adatszivárgás kockázatát. Azonban az interneten keresztüli átvitel egyik módja sem 100%-ban biztonságos.

7. Gyermekek adatainak védelme
Szolgáltatásaink nem szólnak 13 év alatti személyeknek. Tudatosan nem gyűjtünk személyazonosításra alkalmas adatokat 13 éven aluli gyermekektől.

8. Jelen adatvédelmi szabályzat változásai
Időről időre frissíthetjük Adatvédelmi szabályzatunkat. Minden változásról az új adatvédelmi szabályzat közzétételével értesítjük ezen az oldalon. Ezek a változtatások a közzétételük után azonnal hatályba lépnek.

9. Vegye fel velünk a kapcsolatot
Ha bármilyen kérdése vagy javaslata van, ne habozzon kapcsolatba lépni velünk.''',
  'zh-hans': '''VERDICT 隐私政策

本隐私政策解释了由 Görkem Ali Cömert 开发的 VERDICT（“我们”或“我们的”）如何在您使用我们的移动应用程序（“应用程序”）时收集、使用和披露有关您的信息。通过访问或使用该应用程序，您同意本隐私政策。如果您不同意我们的政策和做法，您的选择是不使用我们的应用程序。

1. 隶属关系免责声明
VERDICT 是一个独立的第三方应用程序，不隶属于 Instagram、Facebook 或 Meta Platforms, Inc.，也不受其认可、赞助或管理。“Instagram”是 Meta Platforms, Inc. 的商标。我们严格使用 Instagram 平台，根据您作为用户可用的数据提供分析服务。

2. 我们收集的信息
我们遵循严格的“设备上处理”原则。这意味着该应用程序的核心功能依赖于您设备上本地存储的数据。我们不会运营后端服务器来收集或存储您的个人社交媒体凭据。
A. 个人数据（身份验证）：要进行关注者分析，您必须登录您的 Instagram 帐户。
工作原理：该应用程序使用安全的 WebView（应用程序内的浏览器组件）将您引导至 Instagram 的官方登录页面。
我们的访问：我们不会查看、存储或传输您的密码。您的会话 cookie 和身份验证令牌严格存储在设备的本地安全存储中（例如 Android SharedPreferences, iOS Keychain），以维护您的会话。
服务器存储：我们不会将您的登录凭据或关注者列表上传到我们拥有的任何外部服务器。
B. 使用情况和设备信息：我们和我们的第三方服务提供商（Google AdMob、Firebase）可能会自动收集有关您设备的某些信息，以提高应用性能并投放广告。这可能包括：
设备型号和制造商
操作系统版本
网络类型（WiFi/蜂窝）
广告 ID（Android 为 AAID / iOS 为 IDFA）
崩溃日志和性能数据

3.我们如何使用您的信息
我们将收集的信息用于以下目的：
提供服务：比较您设备上本地的“关注者”和“关注者”列表，以识别取消关注者、新关注者和粉丝。
维护应用程序：使用 Firebase Remote Config 管理应用程序更新、维护模式和功能切换。
投放广告：通过 Google AdMob 显示相关广告，这有助于保持此应用程序免费使用。

4. 第三方服务和数据共享
我们不会出售您的个人数据。但是，我们使用受信任的第三方服务，这些服务可能会收集用于识别您的设备的信息，以用于广告和分析目的。我们建议您查看这些第三方服务提供商的隐私政策：
Google AdMob：隐私政策
Google Firebase：隐私政策

5. 数据保留和删除
本地数据：由于您的关注者数据和会话 cookie 存储在您的设备本地，因此您拥有完全的控制权。
删除：您可以随时通过以下方式删除应用程序存储的所有数据：
通过应用程序设置注销。
在手机设置中清除应用程序的“存储/缓存”。
卸载应用程序。卸载后，我们将不会留下任何数据痕迹。

6. 安全
我们努力使用商业上可接受的方式来保护您的个人信息。通过在本地处理数据并使用标准加密进行本地存储，我们可以最大限度地降低数据泄露的风险。然而，没有一种互联网传输方法是 100% 安全的。

7. 儿童隐私
我们的服务不针对 13 岁以下的任何人。我们不会故意收集 13 岁以下儿童的个人身份信息。

8. 本隐私政策的变更
我们可能会不时更新我们的隐私政策。我们将通过在此页面上发布新的隐私政策来通知您任何更改。这些更改在发布后立即生效。

9. 联系我们
如果您有任何疑问或建议，请随时与我们联系。''',
  'id': '''KEBIJAKAN PRIVASI UNTUK VERDICT

Kebijakan Privasi ini menjelaskan bagaimana VERDICT ("kami", "kita", atau "milik kami"), yang dikembangkan oleh Görkem Ali Cömert, mengumpulkan, menggunakan, dan mengungkapkan informasi tentang Anda saat Anda menggunakan aplikasi seluler kami ("Aplikasi"). Dengan mengakses atau menggunakan Aplikasi, Anda menyetujui Kebijakan Privasi ini. Jika Anda tidak setuju dengan kebijakan dan praktik kami, pilihan Anda adalah tidak menggunakan Aplikasi kami.

1. Penafian mengenai Afiliasi
VERDICT adalah aplikasi pihak ketiga yang independen dan tidak berafiliasi dengan, didukung, disponsori, atau dikelola oleh, Instagram, Facebook, atau Meta Platforms, Inc. "Instagram" adalah merek dagang dari Meta Platforms, Inc. Kami menggunakan platform Instagram secara ketat untuk menyediakan layanan analisis berdasarkan data yang tersedia bagi Anda sebagai pengguna.

2. Informasi yang Kami Kumpulkan
Kami beroperasi dengan prinsip "Pemrosesan Pada Perangkat" yang ketat. Ini berarti fungsi inti Aplikasi bergantung pada data yang disimpan secara lokal di perangkat Anda. Kami tidak mengoperasikan server backend untuk mengambil atau menyimpan kredensial media sosial pribadi Anda.
A. Data Pribadi (Otentikasi): Untuk melakukan analisis pengikut, Anda harus login ke akun Instagram Anda.
Cara kerjanya: Aplikasi ini menggunakan WebView yang aman (komponen browser dalam aplikasi) untuk mengarahkan Anda ke halaman login resmi Instagram.
Akses Kami: Kami TIDAK melihat, menyimpan, atau mengirimkan kata sandi Anda. Cookie sesi dan token autentikasi Anda disimpan secara ketat di dalam penyimpanan aman lokal perangkat Anda (misalnya, Android SharedPreferences, iOS Keychain) untuk mempertahankan sesi Anda.
Penyimpanan Server: Kami TIDAK mengunggah kredensial login Anda atau daftar pengikut Anda ke server eksternal mana pun milik kami.
B. Informasi Penggunaan dan Perangkat: Kami, dan penyedia layanan pihak ketiga kami (Google AdMob, Firebase), dapat secara otomatis mengumpulkan informasi tertentu tentang perangkat Anda untuk meningkatkan kinerja aplikasi dan menayangkan iklan. Ini mungkin termasuk:
Model dan pabrikan perangkat
Versi sistem operasi
Jenis jaringan (WiFi/Seluler)
ID Iklan (AAID untuk Android / IDFA untuk iOS)
Log kerusakan dan data kinerja

3. Bagaimana Kami Menggunakan Informasi Anda
Kami menggunakan informasi yang dikumpulkan untuk tujuan berikut:
Untuk Memberikan Layanan: Untuk membandingkan daftar "Pengikut" dan "Mengikuti" secara lokal di perangkat Anda untuk mengidentifikasi orang yang berhenti mengikuti, pengikut baru, dan penggemar.
Untuk Memelihara Aplikasi: Untuk menggunakan Firebase Remote Config untuk mengelola pembaruan aplikasi, mode pemeliharaan, dan peralihan fitur.
Untuk Menayangkan Iklan: Untuk menampilkan iklan yang relevan melalui Google AdMob, yang membantu menjaga Aplikasi ini tetap gratis untuk digunakan.

4. Layanan Pihak Ketiga dan Berbagi Data
Kami tidak menjual data pribadi Anda. Namun, kami menggunakan layanan pihak ketiga tepercaya yang mungkin mengumpulkan informasi yang digunakan untuk mengidentifikasi perangkat Anda untuk tujuan periklanan dan analisis. Kami menyarankan Anda untuk meninjau kebijakan privasi penyedia layanan pihak ketiga berikut:
Google AdMob: Kebijakan Privasi
Google Firebase: Kebijakan Privasi

5. Penyimpanan dan Penghapusan Data
Data Lokal: Karena data pengikut dan cookie sesi Anda disimpan secara lokal di perangkat Anda, Anda memiliki kendali penuh.
Penghapusan: Anda dapat menghapus semua data yang disimpan oleh Aplikasi kapan saja dengan:
Keluar melalui pengaturan Aplikasi.
Menghapus "Penyimpanan/Cache" Aplikasi di pengaturan ponsel Anda.
Menghapus Instalasi Aplikasi. Setelah dihapus instalasinya, tidak ada jejak data Anda yang tersisa bersama kami.

6. Keamanan
Kami berusaha untuk menggunakan cara yang dapat diterima secara komersial untuk melindungi Informasi Pribadi Anda. Dengan memproses data secara lokal dan menggunakan enkripsi standar untuk penyimpanan lokal, kami meminimalkan risiko pelanggaran data. Namun, tidak ada metode penularan melalui internet yang 100% aman.

7. Privasi Anak
Layanan kami tidak ditujukan kepada siapa pun yang berusia di bawah 13 tahun. Kami tidak dengan sengaja mengumpulkan informasi identitas pribadi dari anak-anak di bawah 13 tahun.

8. Perubahan Kebijakan Privasi Ini
Kami dapat memperbarui Kebijakan Privasi kami dari waktu ke waktu. Kami akan memberi tahu Anda tentang perubahan apa pun dengan memposting Kebijakan Privasi baru di halaman ini. Perubahan ini berlaku segera setelah diumumkan.

9. Hubungi Kami
Jika Anda memiliki pertanyaan atau saran, jangan ragu untuk menghubungi kami.''',
  'nl': '''PRIVACYBELEID VOOR VERDICT

In dit privacybeleid wordt uitgelegd hoe VERDICT ("wij", "ons" of "onze"), ontwikkeld door Görkem Ali Cömert, informatie over u verzamelt, gebruikt en openbaar maakt wanneer u onze mobiele applicatie (de "App") gebruikt. Door de App te openen of te gebruiken, gaat u akkoord met dit Privacybeleid. Als u het niet eens bent met ons beleid en onze praktijken, is het uw keuze om onze app niet te gebruiken.

1. Disclaimer met betrekking tot aansluiting
VERDICT is een onafhankelijke applicatie van derden en is niet aangesloten bij, onderschreven, gesponsord of beheerd door Instagram, Facebook of Meta Platforms, Inc.. "Instagram" is een handelsmerk van Meta Platforms, Inc.. We gebruiken het Instagram-platform uitsluitend om analysediensten te leveren op basis van de gegevens die voor u als gebruiker beschikbaar zijn.

2. De informatie die we verzamelen
Wij werken volgens een strikt principe van ‘On-Device Processing’. Dit betekent dat de kernfunctionaliteit van de app afhankelijk is van gegevens die lokaal op uw apparaat zijn opgeslagen. We gebruiken geen backend-server om uw persoonlijke inloggegevens voor sociale media te verzamelen of op te slaan.
A. Persoonlijke gegevens (authenticatie): Om volgersanalyse uit te voeren, moet u inloggen op uw Instagram-account.
Hoe het werkt: De app gebruikt een beveiligde WebView (een browsercomponent binnen de app) om u naar de officiële inlogpagina van Instagram te leiden.
Onze toegang: Wij zien, bewaren of verzenden uw wachtwoord NIET. Uw sessiecookies en authenticatietokens worden strikt opgeslagen in de lokale beveiligde opslag van uw apparaat (bijvoorbeeld Android SharedPreferences, iOS Keychain) om uw sessie te behouden.
Serveropslag: We uploaden uw inloggegevens of uw volgerslijsten NIET naar een externe server die eigendom is van ons.
B. Gebruiks- en apparaatinformatie: Wij en onze externe serviceproviders (Google AdMob, Firebase) kunnen automatisch bepaalde informatie over uw apparaat verzamelen om de app-prestaties te verbeteren en advertenties weer te geven. Dit kan het volgende omvatten:
Apparaatmodel en fabrikant
Versie van het besturingssysteem
Netwerktype (WiFi/mobiel)
Advertentie-ID (AAID voor Android / IDFA voor iOS)
Crashlogboeken en prestatiegegevens

3. Hoe wij uw gegevens gebruiken
Wij gebruiken de verzamelde informatie voor de volgende doeleinden:
Om diensten te verlenen: Om uw lijsten "Volgers" en "Volgers" lokaal op uw apparaat te vergelijken om ontvolgers, nieuwe volgers en fans te identificeren.
De app onderhouden: Firebase Remote Config gebruiken om app-updates, onderhoudsmodi en functieschakelaars te beheren.
Advertenties weergeven: Om relevante advertenties weer te geven via Google AdMob, waardoor deze app gratis te gebruiken blijft.

4. Diensten van derden en delen van gegevens
Wij verkopen uw persoonlijke gegevens niet. We maken echter gebruik van vertrouwde diensten van derden die mogelijk informatie verzamelen die wordt gebruikt om uw apparaat te identificeren voor reclame- en analysedoeleinden. Wij raden u aan het privacybeleid van deze externe dienstverleners te raadplegen:
Google AdMob: Privacybeleid
Google Firebase: Privacybeleid

5. Bewaren en verwijderen van gegevens
Lokale gegevens: Omdat uw volgergegevens en sessiecookies lokaal op uw apparaat worden opgeslagen, heeft u volledige controle.
Verwijdering: U kunt op elk moment alle gegevens die in de App zijn opgeslagen verwijderen door:
Uitloggen via de App-instellingen.
Het wissen van de "Opslag/Cache" van de app in uw telefooninstellingen.
De app verwijderen. Eenmaal verwijderd, blijft er geen spoor van uw gegevens bij ons achter.

6. Beveiliging
Wij streven ernaar commercieel aanvaardbare middelen te gebruiken om uw persoonlijke gegevens te beschermen. Door gegevens lokaal te verwerken en standaard encryptie te gebruiken voor lokale opslag minimaliseren we het risico op datalekken. Geen enkele transmissiemethode via internet is echter 100% veilig.

7. Privacy van kinderen
Onze Services richten zich niet tot personen jonger dan 13 jaar. We verzamelen niet bewust persoonlijk identificeerbare informatie van kinderen jonger dan 13 jaar.

8. Wijzigingen in dit privacybeleid
We kunnen ons privacybeleid van tijd tot tijd bijwerken. Wij zullen u op de hoogte stellen van eventuele wijzigingen door het nieuwe privacybeleid op deze pagina te plaatsen. Deze wijzigingen zijn onmiddellijk van kracht nadat ze zijn gepubliceerd.

9. Neem contact met ons op
Als u vragen of suggesties heeft, aarzel dan niet om contact met ons op te nemen.''',
  'fr': '''POLITIQUE DE CONFIDENTIALITÉ POUR VERDICT

Cette politique de confidentialité explique comment VERDICT (« nous », « notre » ou « notre »), développé par Görkem Ali Cörmert, collecte, utilise et divulgue des informations vous concernant lorsque vous utilisez notre application mobile (l'« Application »). En accédant ou en utilisant l'application, vous acceptez cette politique de confidentialité. Si vous n'êtes pas d'accord avec nos politiques et pratiques, votre choix est de ne pas utiliser notre application.

1. Avis de non-responsabilité concernant l'affiliation
VERDICT est une application tierce indépendante et n'est pas affiliée, approuvée, sponsorisée ou administrée par Instagram, Facebook ou Meta Platforms, Inc. "Instagram" est une marque commerciale de Meta Platforms, Inc.. Nous utilisons la plateforme Instagram uniquement pour fournir des services d'analyse basés sur les données dont vous disposez en tant qu'utilisateur.

2. Les informations que nous collectons
Nous fonctionnons selon le principe strict du « traitement sur appareil ». Cela signifie que la fonctionnalité principale de l'application repose sur les données stockées localement sur votre appareil. Nous n'exploitons pas de serveur principal pour récolter ou stocker vos informations d'identification personnelles sur les réseaux sociaux.
A. Données personnelles (authentification) : Pour effectuer une analyse des abonnés, vous devez vous connecter à votre compte Instagram.
Comment ça marche : L'application utilise un WebView sécurisé (un composant de navigateur au sein de l'application) pour vous diriger vers la page de connexion officielle de Instagram.
Notre accès : Nous ne voyons, ne stockons ni ne transmettons votre mot de passe. Vos cookies de session et jetons d'authentification sont stockés strictement dans le stockage local sécurisé de votre appareil (par exemple, Android SharedPreferences, iOS Keychain) pour maintenir votre session.
Stockage sur serveur : nous ne téléchargeons PAS vos informations de connexion ou vos listes de abonnés sur un serveur externe nous appartenant.
B. Informations sur l'utilisation et l'appareil : nous et nos fournisseurs de services tiers (Google AdMob, Firebase) pouvons collecter automatiquement certaines informations sur votre appareil pour améliorer les performances de l'application et diffuser des publicités. Cela peut inclure :
Modèle et fabricant de l'appareil
Version du système d'exploitation
Type de réseau (WiFi/cellulaire)
Identifiant publicitaire (AAID pour Android / IDFA pour iOS)
Journaux de crash et données de performances

3. Comment nous utilisons vos informations
Nous utilisons les informations collectées aux fins suivantes :
Pour fournir des services : pour comparer vos listes "Abonnés" et "Abonnés" localement sur votre appareil afin d'identifier les non-abonnés, les nouveaux abonnés et les fans.
Pour maintenir l'application : pour utiliser Firebase Remote Config pour gérer les mises à jour de l'application, les modes de maintenance et les bascules de fonctionnalités.
Pour diffuser des publicités : pour afficher des publicités pertinentes via Google AdMob, ce qui permet de garder cette application gratuite.

4. Services tiers et partage de données
Nous ne vendons pas vos données personnelles. Cependant, nous utilisons des services tiers de confiance qui peuvent collecter des informations utilisées pour identifier votre appareil à des fins publicitaires et analytiques. Nous vous conseillons de consulter les politiques de confidentialité de ces prestataires de services tiers :
Google AdMob : Politique de confidentialité
Google Firebase : Politique de confidentialité

5. Conservation et suppression des données
Données locales : étant donné que les données de vos abonnés et les cookies de session sont stockés localement sur votre appareil, vous avez le contrôle total.
Suppression : Vous pouvez supprimer toutes les données stockées par l'Application à tout moment en :
Déconnexion via les paramètres de l'application.
Effacement du « Stockage/Cache » de l'application dans les paramètres de votre téléphone.
Désinstallation de l'application. Une fois désinstallé, aucune trace de vos données ne reste chez nous.

6. Sécurité
Nous nous efforçons d'utiliser des moyens commercialement acceptables pour protéger vos informations personnelles. En traitant les données localement et en utilisant un cryptage standard pour le stockage local, nous minimisons le risque de violation de données. Cependant, aucune méthode de transmission sur Internet n’est sécurisée à 100 %.

7. Confidentialité des enfants
Nos services ne s'adressent pas aux personnes de moins de 13 ans. Nous ne collectons pas sciemment d'informations personnellement identifiables auprès d'enfants de moins de 13 ans.

8. Modifications de cette politique de confidentialité
Nous pouvons mettre à jour notre politique de confidentialité de temps à autre. Nous vous informerons de tout changement en publiant la nouvelle politique de confidentialité sur cette page. Ces modifications entrent en vigueur immédiatement après leur publication.

9. Contactez-nous
Si vous avez des questions ou des suggestions, n'hésitez pas à nous contacter.''',
  'it': '''INFORMATIVA SULLA PRIVACY PER VERDICT

La presente Informativa sulla privacy spiega come VERDICT ("noi", "ci" o "nostro"), sviluppato da Görkem Ali Cömert, raccoglie, utilizza e divulga informazioni su di te quando utilizzi la nostra applicazione mobile (l'"App"). Accedendo o utilizzando l'App, accetti la presente Informativa sulla privacy. Se non sei d'accordo con le nostre politiche e pratiche, la tua scelta è di non utilizzare la nostra App.

1. Dichiarazione di non responsabilità relativa all'affiliazione
VERDICT è un'applicazione di terze parti indipendente e non è affiliata, approvata, sponsorizzata o amministrata da Instagram, Facebook o Meta Platforms, Inc. "Instagram" è un marchio di Meta Platforms, Inc. Utilizziamo la piattaforma Instagram esclusivamente per fornire servizi di analisi basati sui dati a tua disposizione come utente.

2. Le informazioni che raccogliamo
Operiamo secondo un rigoroso principio di "elaborazione sul dispositivo". Ciò significa che la funzionalità principale dell'app si basa sui dati archiviati localmente sul tuo dispositivo. Non gestiamo un server backend per raccogliere o archiviare le tue credenziali personali sui social media.
A. Dati personali (autenticazione): per eseguire l'analisi dei follower, è necessario accedere al proprio account Instagram.
Come funziona: l'app utilizza un WebView sicuro (un componente browser all'interno dell'app) per indirizzarti alla pagina di accesso ufficiale di Instagram.
Il nostro accesso: NON vediamo, memorizziamo o trasmettiamo la tua password. I cookie di sessione e i token di autenticazione vengono archiviati rigorosamente all'interno dell'archivio locale sicuro del tuo dispositivo (ad esempio, Android SharedPreferences, iOS Keychain) per mantenere la tua sessione.
Archiviazione del server: NON carichiamo le tue credenziali di accesso o i tuoi elenchi di follower su nessun server esterno di nostra proprietà.
B. Informazioni sull'utilizzo e sul dispositivo: noi e i nostri fornitori di servizi di terze parti (Google AdMob, Firebase) potremmo raccogliere automaticamente determinate informazioni sul tuo dispositivo per migliorare le prestazioni dell'app e pubblicare annunci pubblicitari. Ciò può includere:
Modello e produttore del dispositivo
Versione del sistema operativo
Tipo di rete (WiFi/cellulare)
ID pubblicitario (AAID per Android/IDFA per iOS)
Registri degli arresti anomali e dati sulle prestazioni

3. Come utilizziamo le tue informazioni
Utilizziamo le informazioni raccolte per i seguenti scopi:
Per fornire servizi: per confrontare i tuoi elenchi "Follower" e "Following" localmente sul tuo dispositivo per identificare chi non segue, nuovi follower e fan.
Per mantenere l'app: utilizzare Firebase Remote Config per gestire gli aggiornamenti dell'app, le modalità di manutenzione e l'attivazione/disattivazione delle funzionalità.
Per pubblicare annunci: per visualizzare annunci pubblicitari pertinenti tramite Google AdMob, che aiuta a mantenere questa app gratuita.

4. Servizi di terze parti e condivisione dei dati
Non vendiamo i tuoi dati personali. Tuttavia, utilizziamo servizi di terze parti affidabili che potrebbero raccogliere informazioni utilizzate per identificare il tuo dispositivo per scopi pubblicitari e di analisi. Ti consigliamo di rivedere le politiche sulla privacy di questi fornitori di servizi di terze parti:
Google AdMob: Informativa sulla privacy
Google Firebase: Informativa sulla privacy

5. Conservazione e cancellazione dei dati
Dati locali: poiché i dati dei tuoi follower e i cookie di sessione sono archiviati localmente sul tuo dispositivo, hai il pieno controllo.
Cancellazione: Puoi cancellare tutti i dati memorizzati dall'App in qualsiasi momento:
Disconnettersi tramite le impostazioni dell'app.
Cancellare la "Memoria/Cache" dell'app nelle impostazioni del telefono.
Disinstallazione dell'app. Una volta disinstallato, nessuna traccia dei tuoi dati rimane con noi.

6. Sicurezza
Ci impegniamo a utilizzare mezzi commercialmente accettabili per proteggere le tue informazioni personali. Elaborando i dati localmente e utilizzando la crittografia standard per l'archiviazione locale, riduciamo al minimo il rischio di violazione dei dati. Tuttavia, nessun metodo di trasmissione su Internet è sicuro al 100%.

7. Privacy dei bambini
I nostri Servizi non si rivolgono a minori di 13 anni. Non raccogliamo consapevolmente informazioni di identificazione personale da bambini di età inferiore a 13 anni.

8. Modifiche alla presente Informativa sulla privacy
Potremmo aggiornare la nostra Informativa sulla privacy di tanto in tanto. Ti informeremo di eventuali modifiche pubblicando la nuova Informativa sulla privacy in questa pagina. Queste modifiche diventano effettive immediatamente dopo la loro pubblicazione.

9. Contattaci
Se avete domande o suggerimenti, non esitate a contattarci.''',
  'vi': '''CHÍNH SÁCH RIÊNG TƯ DÀNH CHO VERDICT

Chính sách quyền riêng tư này giải thích cách VERDICT ("chúng tôi" hoặc "của chúng tôi") do Görkem Ali Cömert phát triển, thu thập, sử dụng và tiết lộ thông tin về bạn khi bạn sử dụng ứng dụng di động của chúng tôi ("Ứng dụng"). Bằng cách truy cập hoặc sử dụng Ứng dụng, bạn đồng ý với Chính sách quyền riêng tư này. Nếu bạn không đồng ý với các chính sách và thông lệ của chúng tôi, lựa chọn của bạn là không sử dụng Ứng dụng của chúng tôi.

1. Tuyên bố miễn trừ trách nhiệm liên quan đến việc liên kết
VERDICT là ứng dụng độc lập của bên thứ ba và không được liên kết, xác nhận, tài trợ hoặc quản lý bởi Instagram, Facebook hoặc Meta Platforms, Inc. "Instagram" là nhãn hiệu của Meta Platforms, Inc.. Chúng tôi sử dụng nghiêm ngặt nền tảng Instagram để cung cấp các dịch vụ phân tích dựa trên dữ liệu có sẵn cho bạn với tư cách là người dùng.

2. Thông tin chúng tôi thu thập
Chúng tôi hoạt động theo nguyên tắc "Xử lý trên thiết bị" nghiêm ngặt. Điều này có nghĩa là chức năng cốt lõi của Ứng dụng dựa vào dữ liệu được lưu trữ cục bộ trên thiết bị của bạn. Chúng tôi không vận hành máy chủ phụ trợ để thu thập hoặc lưu trữ thông tin đăng nhập mạng xã hội cá nhân của bạn.
A. Dữ liệu cá nhân (Xác thực): Để thực hiện phân tích người theo dõi, bạn phải đăng nhập vào tài khoản Instagram của mình.
Cách hoạt động: Ứng dụng sử dụng WebView an toàn (một thành phần trình duyệt trong ứng dụng) để hướng bạn đến trang đăng nhập chính thức của Instagram.
Quyền truy cập của chúng tôi: Chúng tôi KHÔNG xem, lưu trữ hoặc truyền mật khẩu của bạn. Cookie phiên và mã thông báo xác thực của bạn được lưu trữ nghiêm ngặt trong bộ lưu trữ an toàn cục bộ trên thiết bị của bạn (ví dụ: Android SharedPreferences, iOS Keychain) để duy trì phiên của bạn.
Lưu trữ máy chủ: Chúng tôi KHÔNG tải thông tin đăng nhập hoặc danh sách người theo dõi của bạn lên bất kỳ máy chủ bên ngoài nào do chúng tôi sở hữu.
B. Thông tin về cách sử dụng và thiết bị: Chúng tôi và các nhà cung cấp dịch vụ bên thứ ba của chúng tôi (Google AdMob, Firebase), có thể tự động thu thập một số thông tin nhất định về thiết bị của bạn để cải thiện hiệu suất ứng dụng và phân phát quảng cáo. Điều này có thể bao gồm:
Model thiết bị và nhà sản xuất
Phiên bản hệ điều hành
Loại mạng (WiFi/Di động)
ID quảng cáo (AAID cho Android / IDFA cho iOS)
Nhật ký sự cố và dữ liệu hiệu suất

3. Cách chúng tôi sử dụng thông tin của bạn
Chúng tôi sử dụng thông tin được thu thập cho các mục đích sau:
Để cung cấp dịch vụ: Để so sánh danh sách "Người theo dõi" và "Đang theo dõi" cục bộ trên thiết bị của bạn để xác định người hủy theo dõi, người theo dõi mới và người hâm mộ.
Để duy trì ứng dụng: Sử dụng Firebase Remote Config để quản lý các bản cập nhật ứng dụng, chế độ bảo trì và chuyển đổi tính năng.
Để phân phát quảng cáo: Để hiển thị các quảng cáo có liên quan thông qua Google AdMob, giúp sử dụng Ứng dụng này miễn phí.

4. Dịch vụ của bên thứ ba và chia sẻ dữ liệu
Chúng tôi không bán dữ liệu cá nhân của bạn. Tuy nhiên, chúng tôi sử dụng các dịch vụ đáng tin cậy của bên thứ ba có thể thu thập thông tin dùng để nhận dạng thiết bị của bạn cho mục đích quảng cáo và phân tích. Chúng tôi khuyên bạn nên xem lại chính sách quyền riêng tư của các nhà cung cấp dịch vụ bên thứ ba này:
Google AdMob: Chính sách quyền riêng tư
Google Firebase: Chính sách quyền riêng tư

5. Lưu giữ và xóa dữ liệu
Dữ liệu cục bộ: Vì dữ liệu người theo dõi và cookie phiên được lưu trữ cục bộ trên thiết bị của bạn nên bạn có toàn quyền kiểm soát.
Xóa: Bạn có thể xóa tất cả dữ liệu được Ứng dụng lưu trữ bất kỳ lúc nào bằng cách:
Đăng xuất thông qua cài đặt Ứng dụng.
Xóa "Bộ nhớ/bộ nhớ đệm" của ứng dụng trong cài đặt điện thoại của bạn.
Gỡ cài đặt ứng dụng. Sau khi gỡ cài đặt, chúng tôi sẽ không còn dấu vết nào về dữ liệu của bạn.

6. Bảo mật
Chúng tôi cố gắng sử dụng các phương tiện được chấp nhận về mặt thương mại để bảo vệ Thông tin cá nhân của bạn. Bằng cách xử lý dữ liệu cục bộ và sử dụng mã hóa tiêu chuẩn để lưu trữ cục bộ, chúng tôi giảm thiểu nguy cơ vi phạm dữ liệu. Tuy nhiên, không có phương thức truyền qua internet nào an toàn 100%.

7. Quyền riêng tư của trẻ em
Dịch vụ của chúng tôi không đề cập đến bất kỳ ai dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin nhận dạng cá nhân từ trẻ em dưới 13 tuổi.

8. Những thay đổi đối với Chính sách quyền riêng tư này
Thỉnh thoảng chúng tôi có thể cập nhật Chính sách quyền riêng tư của mình. Chúng tôi sẽ thông báo cho bạn về bất kỳ thay đổi nào bằng cách đăng Chính sách quyền riêng tư mới trên trang này. Những thay đổi này có hiệu lực ngay sau khi chúng được đăng.

9. Liên hệ với chúng tôi
Nếu bạn có bất kỳ câu hỏi hoặc gợi ý nào, đừng ngần ngại liên hệ với chúng tôi.''',
  'th': '''นโยบายความเป็นส่วนตัวสำหรับ VERDICT

????????????????????????????????? VERDICT ("???" "??????" ???? "??????") ???????? Görkem Ali Cömert ?????? ??? ???????????????????????????????????????????????????????????????? ("???") ??????? ??????????????????????????????????????????????????????????????? ????????????????????????????????????????????? ????????????????????????????

1. ข้อจำกัดความรับผิดชอบเกี่ยวกับการเป็นพันธมิตร
VERDICT เป็นแอปพลิเคชันบุคคลที่สามที่เป็นอิสระ และไม่มีส่วนเกี่ยวข้องกับ รับรอง สนับสนุน หรือบริหารจัดการโดย Instagram, Facebook หรือ Meta Platforms, Inc. "Instagram" เป็นเครื่องหมายการค้าของ Meta Platforms, Inc. เราใช้แพลตฟอร์ม Instagram อย่างเคร่งครัดเพื่อให้บริการการวิเคราะห์ตามข้อมูลที่คุณสามารถใช้ได้ในฐานะผู้ใช้

2. ข้อมูลที่เรารวบรวม
เราดำเนินการตามหลักการ "การประมวลผลบนอุปกรณ์" ที่เข้มงวด ซึ่งหมายความว่าฟังก์ชันการทำงานหลักของแอปจะขึ้นอยู่กับข้อมูลที่จัดเก็บไว้ในอุปกรณ์ของคุณ เราไม่ได้ดำเนินการเซิร์ฟเวอร์แบ็กเอนด์เพื่อเก็บเกี่ยวหรือจัดเก็บข้อมูลรับรองโซเชียลมีเดียส่วนตัวของคุณ
A. ข้อมูลส่วนบุคคล (การรับรองความถูกต้อง): เพื่อทำการวิเคราะห์ผู้ติดตาม คุณต้องเข้าสู่ระบบบัญชี Instagram ของคุณ
วิธีการทำงาน: แอปใช้ WebView ที่ปลอดภัย (ส่วนประกอบของเบราว์เซอร์ภายในแอป) เพื่อนำคุณไปยังหน้าเข้าสู่ระบบอย่างเป็นทางการของ Instagram
การเข้าถึงของเรา: เราไม่เห็น จัดเก็บ หรือส่งรหัสผ่านของคุณ คุกกี้เซสชันและโทเค็นการรับรองความถูกต้องของคุณจะถูกเก็บไว้อย่างเคร่งครัดภายในที่จัดเก็บข้อมูลที่ปลอดภัยในอุปกรณ์ของคุณ (เช่น Android SharedPreferences, iOS Keychain) เพื่อรักษาเซสชันของคุณ
พื้นที่เก็บข้อมูลเซิร์ฟเวอร์: เราไม่อัปโหลดข้อมูลรับรองการเข้าสู่ระบบหรือรายชื่อผู้ติดตามของคุณไปยังเซิร์ฟเวอร์ภายนอกที่เราเป็นเจ้าของ
B. ข้อมูลการใช้งานและอุปกรณ์: เราและผู้ให้บริการบุคคลที่สามของเรา (Google AdMob, Firebase) อาจรวบรวมข้อมูลบางอย่างเกี่ยวกับอุปกรณ์ของคุณโดยอัตโนมัติเพื่อปรับปรุงประสิทธิภาพของแอปและให้บริการโฆษณา ซึ่งอาจรวมถึง:
รุ่นอุปกรณ์และผู้ผลิต
เวอร์ชันของระบบปฏิบัติการ
ประเภทเครือข่าย (WiFi/เซลลูลาร์)
รหัสโฆษณา (AAID สำหรับ Android / IDFA สำหรับ iOS)
บันทึกข้อขัดข้องและข้อมูลประสิทธิภาพ

3. เราใช้ข้อมูลของคุณอย่างไร
เราใช้ข้อมูลที่รวบรวมเพื่อวัตถุประสงค์ดังต่อไปนี้:
เพื่อให้บริการ: เพื่อเปรียบเทียบรายการ "ผู้ติดตาม" และ "กำลังติดตาม" ของคุณภายในอุปกรณ์ของคุณเพื่อระบุผู้เลิกติดตาม ผู้ติดตามใหม่ และแฟนๆ
วิธีดูแลรักษาแอป: ใช้ Firebase Remote Config เพื่อจัดการการอัปเดตแอป โหมดการบำรุงรักษา และการสลับคุณสมบัติ
เพื่อแสดงโฆษณา: เพื่อแสดงโฆษณาที่เกี่ยวข้องผ่าน Google AdMob ซึ่งช่วยให้แอปนี้ใช้งานได้ฟรี

4. บริการของบุคคลที่สามและการแบ่งปันข้อมูล
เราไม่ขายข้อมูลส่วนบุคคลของคุณ อย่างไรก็ตาม เราใช้บริการจากบุคคลที่สามที่เชื่อถือได้ซึ่งอาจรวบรวมข้อมูลที่ใช้ในการระบุอุปกรณ์ของคุณเพื่อวัตถุประสงค์ในการโฆษณาและการวิเคราะห์ เราขอแนะนำให้คุณตรวจสอบนโยบายความเป็นส่วนตัวของผู้ให้บริการบุคคลที่สามเหล่านี้:
Google AdMob: นโยบายความเป็นส่วนตัว
Google Firebase: นโยบายความเป็นส่วนตัว

5. การเก็บรักษาและการลบข้อมูล
ข้อมูลท้องถิ่น: เนื่องจากข้อมูลผู้ติดตามและคุกกี้เซสชันของคุณถูกจัดเก็บไว้ในอุปกรณ์ของคุณ คุณจึงสามารถควบคุมได้อย่างเต็มที่
การลบ: คุณสามารถลบข้อมูลทั้งหมดที่แอปเก็บไว้ได้ตลอดเวลาโดย:
ออกจากระบบผ่านการตั้งค่าแอพ
การล้าง "ที่เก็บข้อมูล/แคช" ของแอปในการตั้งค่าโทรศัพท์ของคุณ
การถอนการติดตั้งแอพ เมื่อถอนการติดตั้งแล้ว จะไม่เหลือร่องรอยข้อมูลของคุณอยู่กับเรา

6. ความปลอดภัย
เรามุ่งมั่นที่จะใช้วิธีการที่เป็นที่ยอมรับในเชิงพาณิชย์เพื่อปกป้องข้อมูลส่วนบุคคลของคุณ ด้วยการประมวลผลข้อมูลภายในเครื่องและใช้การเข้ารหัสมาตรฐานสำหรับการจัดเก็บในตัวเครื่อง เราจะลดความเสี่ยงของการละเมิดข้อมูลให้เหลือน้อยที่สุด อย่างไรก็ตาม ไม่มีวิธีการส่งข้อมูลทางอินเทอร์เน็ตใดที่ปลอดภัย 100%

7. ความเป็นส่วนตัวของเด็ก
บริการของเราไม่ได้กล่าวถึงผู้ที่มีอายุต่ำกว่า 13 ปี เราไม่รวบรวมข้อมูลที่สามารถระบุตัวบุคคลได้จากเด็กอายุต่ำกว่า 13 ปีโดยเจตนา

8. การเปลี่ยนแปลงนโยบายความเป็นส่วนตัวนี้
เราอาจปรับปรุงนโยบายความเป็นส่วนตัวของเราเป็นครั้งคราว เราจะแจ้งให้คุณทราบถึงการเปลี่ยนแปลงใด ๆ โดยการโพสต์นโยบายความเป็นส่วนตัวใหม่ในหน้านี้ การเปลี่ยนแปลงเหล่านี้จะมีผลทันทีหลังจากโพสต์แล้ว

9. ติดต่อเรา
หากคุณมีคำถามหรือข้อเสนอแนะ อย่าลังเลที่จะติดต่อเรา''',
  'pl': '''POLITYKA PRYWATNOŚCI DLA VERDICT

Niniejsza Polityka prywatności wyjaśnia, w jaki sposób VERDICT („my”, „nas” lub „nasz”), opracowana przez Görkem Ali Cömert, zbiera, wykorzystuje i ujawnia informacje o Tobie, gdy korzystasz z naszej aplikacji mobilnej („Aplikacja”). Uzyskując dostęp do aplikacji lub korzystając z niej, wyrażasz zgodę na niniejszą Politykę prywatności. Jeśli nie zgadzasz się z naszymi zasadami i praktykami, możesz nie korzystać z naszej Aplikacji.

1. Zastrzeżenie dotyczące przynależności
VERDICT to niezależna aplikacja strony trzeciej i nie jest powiązana, wspierana, sponsorowana ani administrowana przez Instagram, Facebook ani Meta Platforms, Inc.. „Instagram” jest znakiem towarowym Meta Platforms, Inc.. Wykorzystujemy platformę Instagram wyłącznie w celu świadczenia usług analitycznych w oparciu o dane dostępne dla Ciebie jako użytkownika.

2. Informacje, które zbieramy
Działamy według ścisłej zasady „przetwarzania na urządzeniu”. Oznacza to, że podstawowa funkcjonalność aplikacji opiera się na danych przechowywanych lokalnie na Twoim urządzeniu. Nie obsługujemy serwera zaplecza służącego do gromadzenia lub przechowywania Twoich osobistych danych uwierzytelniających w mediach społecznościowych.
A. Dane osobowe (uwierzytelnienie): Aby przeprowadzić analizę obserwujących, musisz zalogować się na swoje konto Instagram.
Jak to działa: Aplikacja korzysta z bezpiecznego WebView (komponent przeglądarki w aplikacji), aby przekierować Cię na oficjalną stronę logowania Instagram.
Nasz dostęp: NIE widzimy, nie przechowujemy ani nie przekazujemy Twojego hasła. Twoje sesyjne pliki cookie i tokeny uwierzytelniające są przechowywane wyłącznie w lokalnym bezpiecznym magazynie Twojego urządzenia (np. Android SharedPreferences, iOS Keychain) w celu utrzymania sesji.
Przechowywanie serwera: NIE przesyłamy Twoich danych logowania ani list obserwujących na żaden zewnętrzny serwer będący naszą własnością.
B. Informacje o użytkowaniu i urządzeniu: Zarówno my, jak i nasi zewnętrzni dostawcy usług (Google AdMob, Firebase) możemy automatycznie zbierać pewne informacje o Twoim urządzeniu w celu poprawy wydajności aplikacji i wyświetlania reklam. Może to obejmować:
Model i producent urządzenia
Wersja systemu operacyjnego
Typ sieci (WiFi/komórkowa)
Identyfikator reklamowy (AAID dla Androida / IDFA dla iOS)
Dzienniki awarii i dane dotyczące wydajności

3. Jak wykorzystujemy Twoje dane
Zebrane informacje wykorzystujemy w następujących celach:
Aby świadczyć usługi: Aby porównać listy „Obserwujący” i „Obserwowani” lokalnie na Twoim urządzeniu w celu zidentyfikowania osób, które przestały Cię obserwować, nowych obserwujących i fanów.
Aby zarządzać aplikacją: Aby użyć Firebase Remote Config do zarządzania aktualizacjami aplikacji, trybami konserwacji i przełączaniem funkcji.
Wyświetlanie reklam: Aby wyświetlać odpowiednie reklamy za pośrednictwem Google AdMob, dzięki czemu korzystanie z tej aplikacji jest bezpłatne.

4. Usługi stron trzecich i udostępnianie danych
Nie sprzedajemy Twoich danych osobowych. Korzystamy jednak z zaufanych usług stron trzecich, które mogą zbierać informacje wykorzystywane do identyfikacji Twojego urządzenia w celach reklamowych i analitycznych. Radzimy zapoznać się z polityką prywatności tych zewnętrznych dostawców usług:
Google AdMob: Polityka prywatności
Google Firebase: Polityka prywatności

5. Przechowywanie i usuwanie danych
Dane lokalne: Ponieważ dane obserwujących i pliki cookie sesji są przechowywane lokalnie na Twoim urządzeniu, masz pełną kontrolę.
Usunięcie: W każdej chwili możesz usunąć wszystkie dane zapisane w Aplikacji poprzez:
Wylogowanie poprzez ustawienia aplikacji.
Czyszczenie „Pamięć/pamięć podręczna” aplikacji w ustawieniach telefonu.
Odinstalowanie aplikacji. Po odinstalowaniu nie pozostanie u nas żaden ślad po Twoich danych.

6. Bezpieczeństwo
Staramy się stosować komercyjnie akceptowalne środki w celu ochrony Twoich danych osobowych. Przetwarzając dane lokalnie i stosując standardowe szyfrowanie do lokalnego przechowywania, minimalizujemy ryzyko naruszenia bezpieczeństwa danych. Żadna metoda transmisji przez Internet nie jest jednak w 100% bezpieczna.

7. Prywatność dzieci
Nasze Usługi nie są skierowane do osób poniżej 13 roku życia. Nie zbieramy świadomie danych osobowych od dzieci poniżej 13 roku życia.

8. Zmiany w niniejszej Polityce Prywatności
Od czasu do czasu możemy aktualizować naszą Politykę prywatności. O wszelkich zmianach poinformujemy Cię, publikując nową Politykę prywatności na tej stronie. Zmiany te obowiązują natychmiast po ich opublikowaniu.

9. Skontaktuj się z nami
Jeśli masz jakieś pytania lub sugestie, nie wahaj się z nami skontaktować.''',
};
