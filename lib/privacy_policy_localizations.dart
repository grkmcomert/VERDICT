// Generated privacy policy localizations.
// Source language: English

import 'dart:convert';

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

String _normalizePolicyLang(String lang) {
  final String code = lang.trim().toLowerCase().replaceAll('_', '-');
  if (code == 'in') return 'id';
  if (code.startsWith('es')) return code == 'es-mx' ? 'es-mx' : 'es';
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
  return _privacyPolicyBodies.containsKey(code) ? code : 'en';
}

String localizedPrivacyPolicyBody(String lang) {
  final String code = _normalizePolicyLang(lang);
  final String? humanized = _humanizedPrivacyPolicyBodies[code];
  return _repairMojibakeText(
      humanized ?? _privacyPolicyBodies[code] ?? _privacyPolicyBodies['en']!);
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
  return _repairMojibakeText(_privacyPolicyOpenSourceLabels[code] ??
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
  'ca': 'Política de privadesa',
  'zh-hant': '隱私權政策',
  'hr': 'Politika privatnosti',
  'cs': 'Zásady ochrany osobních údajů',
  'da': 'Privatlivspolitik',
  'fi': 'Tietosuojakäytäntö',
  'fr-ca': 'politique de confidentialité',
  'el': 'Πολιτική Απορρήτου',
  'he': 'מדיניות פרטיות',
  'ms': 'Dasar Privasi',
  'no': 'Personvernerklæring',
  'pt-pt': 'política de Privacidade',
  'ro': 'Politica de confidențialitate',
  'sk': 'Zásady ochrany osobných údajov',
  'sv': 'Sekretesspolicy',
  'uk': 'Політика конфіденційності',
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
  'ca': 'Tancar',
  'zh-hant': '關閉',
  'hr': 'Zatvoriti',
  'cs': 'Zavřít',
  'da': 'Luk',
  'fi': 'Sulje',
  'fr-ca': 'Fermer',
  'el': 'Κλείσιμο',
  'he': 'לִסְגוֹר',
  'ms': 'tutup',
  'no': 'Lukke',
  'pt-pt': 'Fechar',
  'ro': 'Închide',
  'sk': 'Zavrieť',
  'sv': 'Stäng',
  'uk': 'Закрити',
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
  'ca': 'Enllaç de codi obert',
  'zh-hant': '開源連結',
  'hr': 'Link otvorenog koda',
  'cs': 'Odkaz na otevřený zdroj',
  'da': 'Åbn kildekodelink',
  'fi': 'Avoimen lähdekoodin linkki',
  'fr-ca': 'Lien open source',
  'el': 'Σύνδεσμος ανοιχτού κώδικα',
  'he': 'קישור קוד פתוח',
  'ms': 'Pautan sumber terbuka',
  'no': 'Åpen kildekode-lenke',
  'pt-pt': 'Link de código aberto',
  'ro': 'Link sursă deschisă',
  'sk': 'Odkaz na otvorený zdroj',
  'sv': 'Länk med öppen källkod',
  'uk': 'Відкритий вихідний код',
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
  'ca': 'Retirar el consentiment',
  'zh-hant': '撤回同意',
  'hr': 'Povući privolu',
  'cs': 'Odvolat souhlas',
  'da': 'Tilbagekald samtykke',
  'fi': 'Peruuta suostumus',
  'fr-ca': 'Retirer le consentement',
  'el': 'Ανάκληση συγκατάθεσης',
  'he': 'בטל את ההסכמה',
  'ms': 'Tarik Keizinan',
  'no': 'Trekk tilbake samtykke',
  'pt-pt': 'Retirar consentimento',
  'ro': 'Retrage consimțământul',
  'sk': 'Odvolať súhlas',
  'sv': 'Återkalla samtycke',
  'uk': 'Відкликати згоду',
};

const Map<String, String> _privacyPolicyBodies = {
  'tr': '''VERDICT İÇİN GİZLİLİK POLİTİKASI

Bu Gizlilik Politikası, Görkem Ali Cömert tarafından geliştirilen VERDICT uygulamasını kullanırken bilgilerinizle ilgili süreçleri nasıl yönettiğimizi açıklar. Uygulamaya erişerek veya Uygulamayı kullanarak bu Gizlilik Politikasını kabul etmiş olursunuz. Politikalarımızı ve uygulamalarımızı kabul etmiyorsanız Uygulamamızı kullanmamayı tercih edebilirsiniz.

1. Platform İlişkisi Hakkında Şeffaflık
VERDICT bağımsız bir üçüncü taraf uygulamasıdır ve Instagram, Facebook veya Meta Platforms, Inc.'e bağlı değildir, bunlar tarafından desteklenmez, desteklenmez veya yönetilmez. "Instagram", Meta Platforms, Inc.'ün ticari markasıdır. Instagram platformunu kesinlikle kullanıcı olarak size sunulan verilere dayalı analiz hizmetleri sağlamak için kullanıyoruz.

2. Topladığımız Bilgiler
Uygulamayı gizlilik odaklı ve cihaz içi işleme önceliğiyle tasarladık. Analiz işlemlerinin büyük bölümü telefonunuzda yerel olarak gerçekleşir. Sosyal medya şifrelerinizi toplamak için bir arka uç sunucusu işletmiyoruz.
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
Güvenliğiniz bizim için önceliklidir. Verilerinizi cihazınızda korumak için standart şifreleme ve güvenli depolama yöntemleri kullanıyor, koruma önlemlerimizi düzenli olarak geliştiriyoruz.

7. Çocukların Gizliliği
Hizmetlerimiz 13 yaşın altındaki kişilere yönelik değildir. 13 yaşın altındaki çocuklardan bilerek kişisel olarak tanımlanabilir bilgiler toplamıyoruz.

8. Bu Gizlilik Politikasındaki Değişiklikler
Gizlilik Politikamızı zaman zaman güncelleyebiliriz. Yeni Gizlilik Politikasını bu sayfada yayınlayarak sizi herhangi bir değişiklik konusunda bilgilendireceğiz. Bu değişiklikler yayınlandıktan hemen sonra yürürlüğe girer.

9. Bize Ulaşın
Herhangi bir sorunuz veya öneriniz varsa bizimle iletişime geçmekten çekinmeyin.''',
  'en': '''PRIVACY POLICY FOR VERDICT

This Privacy Policy explains how VERDICT, developed by Görkem Ali Cömert, handles information related to your use of our mobile application. By accessing or using the App, you agree to this Privacy Policy. If you do not agree with our policies and practices, your choice is not to use our App.

1. Transparency About Platform Relationship
VERDICT is an independent third-party application and is not affiliated with, endorsed, sponsored, or administered by, Instagram, Facebook, or Meta Platforms, Inc. "Instagram" is a trademark of Meta Platforms, Inc. We utilize the Instagram platform strictly to provide analysis services based on the data available to you as a user.

2. The Information We Collect
We designed the App with privacy-first, on-device processing in mind. Most analysis runs locally on your phone. We do not run a backend server to collect your social media passwords.
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
Your security matters to us. We protect data on your device with standard encryption and secure storage practices, and we continuously improve these protections.

7. Children’s Privacy
Our Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.

8. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted.

9. Contact Us
If you have any questions or suggestions, do not hesitate to contact us.''',
  'de': '''DATENSCHUTZRICHTLINIE FÜR VERDICT

In dieser Datenschutzrichtlinie wird erläutert, wie VERDICT, entwickelt von Görkem Ali Cömert, Informationen im Zusammenhang mit Ihrer Nutzung unserer mobilen Anwendung verarbeitet. Durch den Zugriff auf oder die Nutzung der App stimmen Sie dieser Datenschutzrichtlinie zu. Wenn Sie mit unseren Richtlinien und Praktiken nicht einverstanden sind, haben Sie die Wahl, unsere App nicht zu nutzen.

1. Transparenz zur Plattformbeziehung
VERDICT ist eine unabhängige Drittanbieteranwendung und steht in keiner Verbindung zu Instagram, Facebook oder Meta Platforms, Inc. und wird von diesen nicht unterstützt, gesponsert oder verwaltet.

2. Die von uns erfassten Informationen
Wir haben die App mit Fokus auf Privatsphäre und Verarbeitung direkt auf dem Gerät entwickelt. Der Großteil der Analyse läuft lokal auf Ihrem Telefon. Wir betreiben keinen Backend-Server, um Ihre Social-Media-Passwörter zu sammeln.
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
Ihre Sicherheit ist uns wichtig. Wir schützen Daten auf Ihrem Gerät mit standardisierter Verschlüsselung und sicheren Speicherverfahren und verbessern diese Schutzmaßnahmen kontinuierlich.

7. Privatsphäre von Kindern
Unsere Dienste richten sich nicht an Personen unter 13 Jahren. Wir erfassen wissentlich keine personenbezogenen Daten von Kindern unter 13 Jahren.

8. Änderungen dieser Datenschutzrichtlinie
Wir können unsere Datenschutzrichtlinie von Zeit zu Zeit aktualisieren. Wir werden Sie über alle Änderungen informieren, indem wir die neue Datenschutzrichtlinie auf dieser Seite veröffentlichen. Diese Änderungen treten sofort nach ihrer Veröffentlichung in Kraft.

9. Kontaktieren Sie uns
Wenn Sie Fragen oder Anregungen haben, zögern Sie nicht, uns zu kontaktieren.''',
  'ko': '''VERDICT에 대한 개인정보 보호정책

본 개인정보 보호정책은 Görkem Ali Cömert가 개발한 VERDICT가 모바일 애플리케이션 사용과 관련된 정보를 어떻게 관리하는지 설명합니다. 앱에 액세스하거나 앱을 사용함으로써 귀하는 본 개인정보 보호정책에 동의하게 됩니다. 귀하가 당사의 정책 및 관행에 동의하지 않는 경우 당사 앱을 사용하지 않는 것이 좋습니다.

1. 플랫폼 관계 안내
VERDICT은 독립적인 제3자 애플리케이션이며 Instagram, Facebook 또는 Meta Platforms, Inc.와 제휴, 승인, 후원 또는 관리되지 않습니다. "Instagram"는 Meta Platforms, Inc.의 상표입니다. 우리는 사용자로서 귀하에게 제공되는 데이터를 기반으로 분석 서비스를 제공하기 위해 Instagram 플랫폼을 엄격하게 활용합니다.

2. 당사가 수집하는 정보
앱은 개인정보 보호를 우선으로, 기기 내 처리 중심으로 설계되었습니다. 대부분의 분석은 휴대폰에서 로컬로 실행됩니다. 소셜 미디어 비밀번호를 수집하기 위한 백엔드 서버를 운영하지 않습니다.
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
사용자 보안은 저희에게 매우 중요합니다. 기기 내 데이터는 표준 암호화와 안전한 저장 방식으로 보호하며, 보호 수준을 지속적으로 개선하고 있습니다.

7. 아동의 개인정보 보호
당사 서비스는 13세 미만의 사용자에게 적용되지 않습니다. 당사는 13세 미만의 어린이로부터 고의로 개인 식별 정보를 수집하지 않습니다.

8. 본 개인정보 보호정책의 변경
당사는 수시로 개인정보 보호정책을 업데이트할 수 있습니다. 당사는 이 페이지에 새로운 개인정보 보호정책을 게시하여 변경 사항을 알려드리겠습니다. 이러한 변경 사항은 게시된 후 즉시 적용됩니다.

9. 문의하기
질문이나 제안 사항이 있으면 주저하지 말고 저희에게 연락해 주세요.''',
  'ja': '''VERDICT のプライバシー ポリシー

このプライバシー ポリシーは、Görkem Ali Cömert によって開発された VERDICT が、モバイル アプリの利用に関連する情報をどのように取り扱うかを説明します。アプリにアクセスまたは使用すると、このプライバシー ポリシーに同意したことになります。当社のポリシーと慣行に同意できない場合は、当社のアプリを使用しないことを選択してください。

1. プラットフォームとの関係について
VERDICT は独立したサードパーティ アプリケーションであり、Instagram、Facebook、または Meta Platforms, Inc. と提携、承認、スポンサー、または管理されていません。 「Instagram」は Meta Platforms, Inc. の商標です。当社は、ユーザーとして利用できるデータに基づいて分析サービスを提供するために Instagram プラットフォームを厳密に利用します。

2. 当社が収集する情報
本アプリは、プライバシーを最優先にし、端末内処理を中心に設計されています。分析の大部分はお使いのスマートフォン内でローカルに実行されます。SNSのパスワードを収集するためのバックエンド サーバーは運用していません。
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
お客様の安全は私たちにとって重要です。端末内データは標準的な暗号化と安全な保存方法で保護し、保護対策を継続的に改善しています。

7. 子供のプライバシー
当社のサービスは 13 歳未満には対応しません。当社は、13 歳未満の子供から故意に個人を特定できる情報を収集しません。

8. 本プライバシーポリシーの変更
当社はプライバシーポリシーを随時更新することがあります。変更があった場合は、このページに新しいプライバシー ポリシーを掲載してお知らせします。これらの変更は、投稿後すぐに有効になります。

9. お問い合わせ
ご質問やご提案がございましたら、お気軽にお問い合わせください。''',
  'ru': '''ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ ДЛЯ VERDICT

В настоящей Политике конфиденциальности объясняется, как VERDICT, разработанный Görkem Ali Cömert, обрабатывает информацию, связанную с использованием вами нашего мобильного приложения. Получая доступ к Приложению или используя его, вы соглашаетесь с настоящей Политикой конфиденциальности. Если вы не согласны с нашей политикой и практикой, вы можете не использовать наше Приложение.

1. Прозрачность о связи с платформой
VERDICT является независимым сторонним приложением и не связан, не одобрен, не спонсируется и не администрируется Instagram, Facebook или Meta Platforms, Inc.. «Instagram» является товарным знаком Meta Platforms, Inc.. Мы используем платформу Instagram исключительно для предоставления услуг анализа на основе данных, доступных вам как пользователю.

2. Информация, которую мы собираем
Мы разработали приложение с приоритетом конфиденциальности и обработкой данных на устройстве. Большая часть анализа выполняется локально на вашем телефоне. Мы не используем серверную часть для сбора ваших паролей от соцсетей.
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
Ваша безопасность важна для нас. Мы защищаем данные на вашем устройстве с помощью стандартного шифрования и безопасного хранения и постоянно улучшаем эти меры защиты.

7. Конфиденциальность детей
Наши Услуги не предназначены для лиц младше 13 лет. Мы сознательно не собираем личную информацию от детей младше 13 лет.

8. Изменения в настоящей Политике конфиденциальности
Мы можем время от времени обновлять нашу Политику конфиденциальности. Мы сообщим вам о любых изменениях, разместив новую Политику конфиденциальности на этой странице. Эти изменения вступают в силу сразу после их публикации.

9. Свяжитесь с нами
Если у вас есть какие-либо вопросы или предложения, не стесняйтесь обращаться к нам.''',
  'pt': '''POLÍTICA DE PRIVACIDADE PARA VERDICT

Esta Política de Privacidade explica como o VERDICT, desenvolvido por Görkem Ali Cömert, trata informações relacionadas ao uso do nosso aplicativo móvel. Ao acessar ou utilizar o App, você concorda com esta Política de Privacidade. Se você não concorda com nossas políticas e práticas, sua opção é não usar nosso Aplicativo.

1. Transparência sobre vínculo com plataformas
VERDICT é um aplicativo de terceiros independente e não é afiliado, endossado, patrocinado ou administrado por Instagram, Facebook ou Meta Platforms, Inc. "Instagram" é uma marca registrada de Meta Platforms, Inc. Utilizamos a plataforma Instagram estritamente para fornecer serviços de análise com base nos dados disponíveis para você como usuário.

2. As informações que coletamos
Desenvolvemos o App com foco em privacidade e processamento no próprio dispositivo. A maior parte das análises ocorre localmente no seu celular. Não operamos servidor de backend para coletar suas senhas de redes sociais.
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
Sua segurança é importante para nós. Protegemos os dados no seu dispositivo com criptografia padrão e práticas de armazenamento seguro, e melhoramos continuamente essas proteções.

7. Privacidade das Crianças
Nossos serviços não se destinam a menores de 13 anos. Não coletamos intencionalmente informações de identificação pessoal de crianças menores de 13 anos.

8. Alterações nesta Política de Privacidade
Poderemos atualizar nossa Política de Privacidade de tempos em tempos. Iremos notificá-lo sobre quaisquer alterações publicando a nova Política de Privacidade nesta página. Essas alterações entram em vigor imediatamente após serem publicadas.

9. Contate-nos
Se você tiver alguma dúvida ou sugestão, não hesite em nos contatar.''',
  'ar': '''سياسة الخصوصية لـ VERDICT

تشرح سياسة الخصوصية هذه كيف يدير VERDICT الذي طوره Görkem Ali Cömert المعلومات المرتبطة باستخدامك لتطبيق الهاتف المحمول الخاص بنا. من خلال الوصول إلى التطبيق أو استخدامه فإنك توافق على سياسة الخصوصية هذه. إذا كنت لا توافق على سياساتنا وممارساتنا فلديك خيار عدم استخدام تطبيقنا.

1. توضيح علاقتنا بالمنصات
VERDICT هو تطبيق مستقل تابع لجهة خارجية ولا ينتمي إلى Instagram أو Facebook أو Meta Platforms, Inc.، أو Instagram، أو يدعمه أو يرعاه أو يديره.

2. المعلومات التي نجمعها
صممنا التطبيق مع أولوية واضحة للخصوصية والمعالجة على الجهاز. أغلب التحليلات تتم محليًا على هاتفك. لا نشغّل خادمًا خلفيًا لجمع كلمات مرور حساباتك الاجتماعية.
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
أمانك مهم بالنسبة لنا. نحمي البيانات على جهازك باستخدام تشفير قياسي وممارسات تخزين آمنة، ونواصل تحسين وسائل الحماية بشكل مستمر.

7. خصوصية الأطفال
خدماتنا لا تستهدف أي شخص يقل عمره عن 13 عامًا. ونحن لا نجمع معلومات التعريف الشخصية عن عمد من الأطفال الذين تقل أعمارهم عن 13 عامًا.

8. التغييرات في سياسة الخصوصية هذه
قد نقوم بتحديث سياسة الخصوصية الخاصة بنا من وقت لآخر. وسوف نقوم بإعلامك بأي تغييرات عن طريق نشر سياسة الخصوصية الجديدة على هذه الصفحة. تسري هذه التغييرات فورًا بعد نشرها.

9. اتصل بنا
إذا كان لديك أي أسئلة أو اقتراحات، فلا تتردد في الاتصال بنا.''',
  'es': '''POLÍTICA DE PRIVACIDAD PARA VERDICT

Esta Política de Privacidad explica cómo VERDICT, desarrollado por Görkem Ali Cömert, gestiona la información relacionada con su uso de nuestra aplicación móvil. Al acceder o utilizar la aplicación, acepta esta Política de privacidad. Si no está de acuerdo con nuestras políticas y prácticas, su opción es no utilizar nuestra aplicación.

1. Transparencia sobre nuestra relación con la plataforma
VERDICT es una aplicación de terceros independiente y no está afiliada, respaldada, patrocinada ni administrada por Instagram, Facebook o Meta Platforms, Inc.. "Instagram" es una marca comercial de Meta Platforms, Inc. Utilizamos la plataforma Instagram estrictamente para proporcionar servicios de análisis basados en los datos disponibles para usted como usuario.

2. La información que recopilamos
Diseñamos la App con enfoque en privacidad y procesamiento en el propio dispositivo. La mayor parte del análisis se ejecuta localmente en tu teléfono. No operamos un servidor backend para recopilar tus contraseñas de redes sociales.
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
Tu seguridad es importante para nosotros. Protegemos los datos en tu dispositivo con cifrado estándar y prácticas de almacenamiento seguro, y mejoramos estas protecciones de forma continua.

7. Privacidad de los niños
Nuestros Servicios no se dirigen a ninguna persona menor de 13 años. No recopilamos intencionadamente información de identificación personal de niños menores de 13 años.

8. Cambios a esta Política de Privacidad
Podemos actualizar nuestra Política de Privacidad de vez en cuando. Le notificaremos cualquier cambio publicando la nueva Política de Privacidad en esta página. Estos cambios entran en vigor inmediatamente después de su publicación.

9. Contáctenos
Si tienes alguna duda o sugerencia, no dudes en contactar con nosotros.''',
  'es-mx': '''POLÍTICA DE PRIVACIDAD PARA VERDICT

Esta Política de Privacidad explica cómo VERDICT, desarrollado por Görkem Ali Cömert, gestiona la información relacionada con su uso de nuestra aplicación móvil. Al acceder o utilizar la aplicación, acepta esta Política de privacidad. Si no está de acuerdo con nuestras políticas y prácticas, su opción es no utilizar nuestra aplicación.

1. Transparencia sobre nuestra relación con la plataforma
VERDICT es una aplicación de terceros independiente y no está afiliada, respaldada, patrocinada ni administrada por Instagram, Facebook o Meta Platforms, Inc.. "Instagram" es una marca comercial de Meta Platforms, Inc. Utilizamos la plataforma Instagram estrictamente para proporcionar servicios de análisis basados en los datos disponibles para usted como usuario.

2. La información que recopilamos
Diseñamos la App con enfoque en privacidad y procesamiento en el propio dispositivo. La mayor parte del análisis se ejecuta localmente en tu teléfono. No operamos un servidor backend para recopilar tus contraseñas de redes sociales.
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
Tu seguridad es importante para nosotros. Protegemos los datos en tu dispositivo con cifrado estándar y prácticas de almacenamiento seguro, y mejoramos estas protecciones de forma continua.

7. Privacidad de los niños
Nuestros Servicios no se dirigen a ninguna persona menor de 13 años. No recopilamos intencionadamente información de identificación personal de niños menores de 13 años.

8. Cambios a esta Política de Privacidad
Podemos actualizar nuestra Política de Privacidad de vez en cuando. Le notificaremos cualquier cambio publicando la nueva Política de Privacidad en esta página. Estos cambios entran en vigor inmediatamente después de su publicación.

9. Contáctenos
Si tienes alguna duda o sugerencia, no dudes en contactar con nosotros.''',
  'hi': '''VERDICT के लिए गोपनीयता नीति

यह गोपनीयता नीति बताती है कि गोरकेम अली कोमर्ट द्वारा विकसित VERDICT हमारे मोबाइल एप्लिकेशन के आपके उपयोग से संबंधित जानकारी का प्रबंधन कैसे करता है। ऐप तक पहुंच या उपयोग करके, आप इस गोपनीयता नीति से सहमत हैं। यदि आप हमारी नीतियों और प्रथाओं से सहमत नहीं हैं, तो आपकी पसंद हमारे ऐप का उपयोग नहीं करना है।

1. प्लेटफ़ॉर्म संबंध में पारदर्शिता
VERDICT एक स्वतंत्र तृतीय-पक्ष एप्लिकेशन है और यह Instagram, Facebook, या Meta Platforms, Inc. से संबद्ध, समर्थित, प्रायोजित या प्रशासित नहीं है।

2. जो जानकारी हम एकत्र करते हैं
हमने ऐप को प्राइवेसी-फर्स्ट और ऑन-डिवाइस प्रोसेसिंग को प्राथमिकता देकर बनाया है। अधिकतर विश्लेषण आपके फोन पर लोकली चलता है। आपके सोशल मीडिया पासवर्ड इकट्ठा करने के लिए हम कोई बैकएंड सर्वर नहीं चलाते हैं।
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
आपकी सुरक्षा हमारे लिए महत्वपूर्ण है। हम आपके डिवाइस पर डेटा को मानक एन्क्रिप्शन और सुरक्षित स्टोरेज तरीकों से सुरक्षित रखते हैं, और इन सुरक्षा उपायों को लगातार बेहतर बनाते हैं।

7. बच्चों की गोपनीयता
हमारी सेवाएँ 13 वर्ष से कम उम्र के किसी भी व्यक्ति को संबोधित नहीं करती हैं। हम जानबूझकर 13 वर्ष से कम उम्र के बच्चों से व्यक्तिगत रूप से पहचान योग्य जानकारी एकत्र नहीं करते हैं।

8. इस गोपनीयता नीति में परिवर्तन
हम समय-समय पर अपनी गोपनीयता नीति को अपडेट कर सकते हैं। हम इस पृष्ठ पर नई गोपनीयता नीति पोस्ट करके आपको किसी भी बदलाव के बारे में सूचित करेंगे। ये परिवर्तन पोस्ट किए जाने के तुरंत बाद प्रभावी होते हैं।

9. हमसे संपर्क करें
यदि आपके कोई प्रश्न या सुझाव हैं, तो हमसे संपर्क करने में संकोच न करें।''',
  'hu': '''AZ VERDICT ADATVÉDELMI IRÁNYELVE

Ez az adatvédelmi szabályzat elmagyarázza, hogy a Görkem Ali Cömert által kifejlesztett VERDICT hogyan kezeli az Ön mobilalkalmazás-használatához kapcsolódó információkat. Az Alkalmazás elérésével vagy használatával Ön elfogadja a jelen Adatvédelmi szabályzatot. Ha nem ért egyet irányelveinkkel és gyakorlatainkkal, úgy dönt, hogy nem használja az alkalmazásunkat.

1. Átláthatóság a platformkapcsolatról
Az VERDICT egy független, harmadik féltől származó alkalmazás, amely nem áll kapcsolatban, nem támogatja, nem szponzorálja vagy nem adminisztrálja az Instagram, Facebook vagy Meta Platforms, Inc.. Az Instagram az Meta Platforms, Inc. védjegye. felhasználó.

2. Az általunk gyűjtött információk
Az alkalmazást adatvédelmi szemlélettel, eszközön történő feldolgozásra optimalizálva készítettük. Az elemzés nagy része helyben, a telefonján fut. Nem üzemeltetünk háttérszervert a közösségi média jelszavak gyűjtésére.
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
Az Ön biztonsága fontos számunkra. Az eszközén tárolt adatokat szabványos titkosítással és biztonságos tárolási megoldásokkal védjük, és ezeket a védelmeket folyamatosan fejlesztjük.

7. Gyermekek adatainak védelme
Szolgáltatásaink nem szólnak 13 év alatti személyeknek. Tudatosan nem gyűjtünk személyazonosításra alkalmas adatokat 13 éven aluli gyermekektől.

8. Jelen adatvédelmi szabályzat változásai
Időről időre frissíthetjük Adatvédelmi szabályzatunkat. Minden változásról az új adatvédelmi szabályzat közzétételével értesítjük ezen az oldalon. Ezek a változtatások a közzétételük után azonnal hatályba lépnek.

9. Vegye fel velünk a kapcsolatot
Ha bármilyen kérdése vagy javaslata van, ne habozzon kapcsolatba lépni velünk.''',
  'zh-hans': '''VERDICT 隐私政策

本隐私政策解释了由 Görkem Ali Cömert 开发的 VERDICT（“我们”或“我们的”）如何在您使用我们的移动应用程序（“应用程序”）时收集、使用和披露有关您的信息。通过访问或使用该应用程序，您同意本隐私政策。如果您不同意我们的政策和做法，您的选择是不使用我们的应用程序。

1. 关于平台关系的透明说明
VERDICT 是一个独立的第三方应用程序，不隶属于 Instagram、Facebook 或 Meta Platforms, Inc.，也不受其认可、赞助或管理。“Instagram”是 Meta Platforms, Inc. 的商标。我们严格使用 Instagram 平台，根据您作为用户可用的数据提供分析服务。

2. 我们收集的信息
我们以隐私优先和设备本地处理为核心设计了本应用。大部分分析会在您的手机本地完成。我们不会运营后端服务器来收集您的社交媒体密码。
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
您的安全对我们非常重要。我们通过标准加密和安全存储方式保护您设备中的数据，并持续改进这些保护措施。

7. 儿童隐私
我们的服务不针对 13 岁以下的任何人。我们不会故意收集 13 岁以下儿童的个人身份信息。

8. 本隐私政策的变更
我们可能会不时更新我们的隐私政策。我们将通过在此页面上发布新的隐私政策来通知您任何更改。这些更改在发布后立即生效。

9. 联系我们
如果您有任何疑问或建议，请随时与我们联系。''',
  'id': '''KEBIJAKAN PRIVASI UNTUK VERDICT

Kebijakan Privasi ini menjelaskan bagaimana VERDICT yang dikembangkan oleh Görkem Ali Cömert mengelola informasi yang terkait dengan penggunaan aplikasi seluler kami. Dengan mengakses atau menggunakan Aplikasi, Anda menyetujui Kebijakan Privasi ini. Jika Anda tidak setuju dengan kebijakan dan praktik kami, pilihan Anda adalah tidak menggunakan Aplikasi kami.

1. Transparansi tentang hubungan dengan platform
VERDICT adalah aplikasi pihak ketiga yang independen dan tidak berafiliasi dengan, didukung, disponsori, atau dikelola oleh, Instagram, Facebook, atau Meta Platforms, Inc. "Instagram" adalah merek dagang dari Meta Platforms, Inc. Kami menggunakan platform Instagram secara ketat untuk menyediakan layanan analisis berdasarkan data yang tersedia bagi Anda sebagai pengguna.

2. Informasi yang Kami Kumpulkan
Aplikasi dirancang dengan prioritas privasi dan pemrosesan di perangkat. Sebagian besar analisis berjalan secara lokal di ponsel Anda. Kami tidak menjalankan server backend untuk mengumpulkan kata sandi media sosial Anda.
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
Keamanan Anda penting bagi kami. Kami melindungi data di perangkat Anda dengan enkripsi standar dan praktik penyimpanan yang aman, serta terus meningkatkan perlindungan ini.

7. Privasi Anak
Layanan kami tidak ditujukan kepada siapa pun yang berusia di bawah 13 tahun. Kami tidak dengan sengaja mengumpulkan informasi identitas pribadi dari anak-anak di bawah 13 tahun.

8. Perubahan Kebijakan Privasi Ini
Kami dapat memperbarui Kebijakan Privasi kami dari waktu ke waktu. Kami akan memberi tahu Anda tentang perubahan apa pun dengan memposting Kebijakan Privasi baru di halaman ini. Perubahan ini berlaku segera setelah diumumkan.

9. Hubungi Kami
Jika Anda memiliki pertanyaan atau saran, jangan ragu untuk menghubungi kami.''',
  'nl': '''PRIVACYBELEID VOOR VERDICT

In dit privacybeleid wordt uitgelegd hoe VERDICT, ontwikkeld door Görkem Ali Cömert, informatie verwerkt die verband houdt met uw gebruik van onze mobiele applicatie. Door de App te openen of te gebruiken, gaat u akkoord met dit Privacybeleid. Als u het niet eens bent met ons beleid en onze praktijken, is het uw keuze om onze app niet te gebruiken.

1. Transparantie over platformrelatie
VERDICT is een onafhankelijke applicatie van derden en is niet aangesloten bij, onderschreven, gesponsord of beheerd door Instagram, Facebook of Meta Platforms, Inc.. "Instagram" is een handelsmerk van Meta Platforms, Inc.. We gebruiken het Instagram-platform uitsluitend om analysediensten te leveren op basis van de gegevens die voor u als gebruiker beschikbaar zijn.

2. De informatie die we verzamelen
We hebben de app ontworpen met privacy als uitgangspunt en verwerking op het apparaat. Het grootste deel van de analyse draait lokaal op je telefoon. We gebruiken geen backendserver om je socialmediawachtwoorden te verzamelen.
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
Jouw veiligheid is belangrijk voor ons. We beschermen gegevens op je apparaat met standaard encryptie en veilige opslagpraktijken, en verbeteren deze bescherming voortdurend.

7. Privacy van kinderen
Onze Services richten zich niet tot personen jonger dan 13 jaar. We verzamelen niet bewust persoonlijk identificeerbare informatie van kinderen jonger dan 13 jaar.

8. Wijzigingen in dit privacybeleid
We kunnen ons privacybeleid van tijd tot tijd bijwerken. Wij zullen u op de hoogte stellen van eventuele wijzigingen door het nieuwe privacybeleid op deze pagina te plaatsen. Deze wijzigingen zijn onmiddellijk van kracht nadat ze zijn gepubliceerd.

9. Neem contact met ons op
Als u vragen of suggesties heeft, aarzel dan niet om contact met ons op te nemen.''',
  'fr': '''POLITIQUE DE CONFIDENTIALITÉ POUR VERDICT

Cette politique de confidentialité explique comment VERDICT, développé par Görkem Ali Cörmert, traite les informations liées à votre utilisation de notre application mobile. En accédant ou en utilisant l’application, vous acceptez cette politique de confidentialité. Si vous n’êtes pas d’accord avec nos politiques et pratiques, votre choix est de ne pas utiliser notre application.

1. Transparence sur notre relation avec la plateforme
VERDICT est une application tierce indépendante et n'est pas affiliée, approuvée, sponsorisée ou administrée par Instagram, Facebook ou Meta Platforms, Inc. "Instagram" est une marque commerciale de Meta Platforms, Inc.. Nous utilisons la plateforme Instagram uniquement pour fournir des services d'analyse basés sur les données dont vous disposez en tant qu'utilisateur.

2. Les informations que nous collectons
Nous avons conçu l'application avec une approche "privacy first" et un traitement sur l'appareil. La majorité de l'analyse s'exécute localement sur votre téléphone. Nous n'exploitons pas de serveur backend pour collecter vos mots de passe de réseaux sociaux.
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
Votre sécurité compte pour nous. Nous protégeons les données sur votre appareil avec un chiffrement standard et des pratiques de stockage sécurisées, et nous améliorons ces protections en continu.

7. Confidentialité des enfants
Nos services ne s'adressent pas aux personnes de moins de 13 ans. Nous ne collectons pas sciemment d'informations personnellement identifiables auprès d'enfants de moins de 13 ans.

8. Modifications de cette politique de confidentialité
Nous pouvons mettre à jour notre politique de confidentialité de temps à autre. Nous vous informerons de tout changement en publiant la nouvelle politique de confidentialité sur cette page. Ces modifications entrent en vigueur immédiatement après leur publication.

9. Contactez-nous
Si vous avez des questions ou des suggestions, n'hésitez pas à nous contacter.''',
  'it': '''INFORMATIVA SULLA PRIVACY PER VERDICT

La presente Informativa sulla privacy spiega come VERDICT, sviluppato da Görkem Ali Cömert, gestisce le informazioni relative al tuo utilizzo della nostra applicazione mobile. Accedendo o utilizzando l’app, accetti la presente Informativa sulla privacy. Se non sei d’accordo con le nostre politiche e pratiche, la tua scelta è di non utilizzare la nostra App.

1. Trasparenza sul rapporto con la piattaforma
VERDICT è un'applicazione di terze parti indipendente e non è affiliata, approvata, sponsorizzata o amministrata da Instagram, Facebook o Meta Platforms, Inc. "Instagram" è un marchio di Meta Platforms, Inc. Utilizziamo la piattaforma Instagram esclusivamente per fornire servizi di analisi basati sui dati a tua disposizione come utente.

2. Le informazioni che raccogliamo
Abbiamo progettato l'app con un approccio orientato alla privacy e all'elaborazione sul dispositivo. La maggior parte delle analisi viene eseguita localmente sul tuo telefono. Non gestiamo un server backend per raccogliere le password dei tuoi social media.
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
La tua sicurezza è importante per noi. Proteggiamo i dati sul tuo dispositivo con crittografia standard e pratiche di archiviazione sicure, migliorando continuamente queste misure.

7. Privacy dei bambini
I nostri Servizi non si rivolgono a minori di 13 anni. Non raccogliamo consapevolmente informazioni di identificazione personale da bambini di età inferiore a 13 anni.

8. Modifiche alla presente Informativa sulla privacy
Potremmo aggiornare la nostra Informativa sulla privacy di tanto in tanto. Ti informeremo di eventuali modifiche pubblicando la nuova Informativa sulla privacy in questa pagina. Queste modifiche diventano effettive immediatamente dopo la loro pubblicazione.

9. Contattaci
Se avete domande o suggerimenti, non esitate a contattarci.''',
  'vi': '''CHÍNH SÁCH RIÊNG TƯ DÀNH CHO VERDICT

Chính sách quyền riêng tư này giải thích cách VERDICT do Görkem Ali Cömert phát triển quản lý thông tin liên quan đến việc bạn sử dụng ứng dụng di động của chúng tôi. Bằng cách truy cập hoặc sử dụng Ứng dụng, bạn đồng ý với Chính sách quyền riêng tư này. Nếu bạn không đồng ý với các chính sách và thông lệ của chúng tôi, lựa chọn của bạn là không sử dụng Ứng dụng của chúng tôi.

1. Minh bạch về mối quan hệ với nền tảng
VERDICT là ứng dụng độc lập của bên thứ ba và không được liên kết, xác nhận, tài trợ hoặc quản lý bởi Instagram, Facebook hoặc Meta Platforms, Inc. "Instagram" là nhãn hiệu của Meta Platforms, Inc.. Chúng tôi sử dụng nghiêm ngặt nền tảng Instagram để cung cấp các dịch vụ phân tích dựa trên dữ liệu có sẵn cho bạn với tư cách là người dùng.

2. Thông tin chúng tôi thu thập
Chúng tôi thiết kế ứng dụng theo hướng ưu tiên quyền riêng tư và xử lý trên thiết bị. Phần lớn phân tích được chạy cục bộ trên điện thoại của bạn. Chúng tôi không vận hành máy chủ backend để thu thập mật khẩu mạng xã hội của bạn.
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
An toàn của bạn rất quan trọng với chúng tôi. Chúng tôi bảo vệ dữ liệu trên thiết bị của bạn bằng mã hóa tiêu chuẩn và phương thức lưu trữ an toàn, đồng thời liên tục cải thiện các biện pháp này.

7. Quyền riêng tư của trẻ em
Dịch vụ của chúng tôi không đề cập đến bất kỳ ai dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin nhận dạng cá nhân từ trẻ em dưới 13 tuổi.

8. Những thay đổi đối với Chính sách quyền riêng tư này
Thỉnh thoảng chúng tôi có thể cập nhật Chính sách quyền riêng tư của mình. Chúng tôi sẽ thông báo cho bạn về bất kỳ thay đổi nào bằng cách đăng Chính sách quyền riêng tư mới trên trang này. Những thay đổi này có hiệu lực ngay sau khi chúng được đăng.

9. Liên hệ với chúng tôi
Nếu bạn có bất kỳ câu hỏi hoặc gợi ý nào, đừng ngần ngại liên hệ với chúng tôi.''',
  'th': '''นโยบายความเป็นส่วนตัวสำหรับ VERDICT

นโยบายความเป็นส่วนตัวนี้อธิบายว่า VERDICT ที่พัฒนาโดย Görkem Ali Cömert จัดการข้อมูลที่เกี่ยวข้องกับการใช้งานแอปมือถือของคุณอย่างไร การเข้าถึงหรือใช้งานแอปถือว่าคุณยอมรับนโยบายความเป็นส่วนตัวนี้ หากคุณไม่เห็นด้วยกับนโยบายและแนวปฏิบัติของเรา คุณสามารถเลือกไม่ใช้แอปของเราได้

1. ความชัดเจนเรื่องความสัมพันธ์กับแพลตฟอร์ม
VERDICT เป็นแอปพลิเคชันบุคคลที่สามที่เป็นอิสระ และไม่มีส่วนเกี่ยวข้องกับ รับรอง สนับสนุน หรือบริหารจัดการโดย Instagram, Facebook หรือ Meta Platforms, Inc. "Instagram" เป็นเครื่องหมายการค้าของ Meta Platforms, Inc. เราใช้แพลตฟอร์ม Instagram อย่างเคร่งครัดเพื่อให้บริการการวิเคราะห์ตามข้อมูลที่คุณสามารถใช้ได้ในฐานะผู้ใช้

2. ข้อมูลที่เรารวบรวม
เราออกแบบแอปโดยให้ความสำคัญกับความเป็นส่วนตัวและการประมวลผลบนอุปกรณ์เป็นหลัก การวิเคราะห์ส่วนใหญ่ทำงานภายในโทรศัพท์ของคุณแบบภายในเครื่อง เราไม่ใช้เซิร์ฟเวอร์แบ็กเอนด์เพื่อเก็บรหัสผ่านโซเชียลมีเดียของคุณ
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
ความปลอดภัยของคุณสำคัญสำหรับเรา เราปกป้องข้อมูลบนอุปกรณ์ของคุณด้วยการเข้ารหัสมาตรฐานและแนวทางจัดเก็บที่ปลอดภัย พร้อมพัฒนามาตรการป้องกันอย่างต่อเนื่อง

7. ความเป็นส่วนตัวของเด็ก
บริการของเราไม่ได้กล่าวถึงผู้ที่มีอายุต่ำกว่า 13 ปี เราไม่รวบรวมข้อมูลที่สามารถระบุตัวบุคคลได้จากเด็กอายุต่ำกว่า 13 ปีโดยเจตนา

8. การเปลี่ยนแปลงนโยบายความเป็นส่วนตัวนี้
เราอาจปรับปรุงนโยบายความเป็นส่วนตัวของเราเป็นครั้งคราว เราจะแจ้งให้คุณทราบถึงการเปลี่ยนแปลงใด ๆ โดยการโพสต์นโยบายความเป็นส่วนตัวใหม่ในหน้านี้ การเปลี่ยนแปลงเหล่านี้จะมีผลทันทีหลังจากโพสต์แล้ว

9. ติดต่อเรา
หากคุณมีคำถามหรือข้อเสนอแนะ อย่าลังเลที่จะติดต่อเรา''',
  'pl': '''POLITYKA PRYWATNOŚCI DLA VERDICT

Niniejsza Polityka prywatności wyjaśnia, w jaki sposób VERDICT, opracowana przez Görkem Ali Cömert, zarządza informacjami związanymi z korzystaniem z naszej aplikacji mobilnej. Uzyskując dostęp do aplikacji lub korzystając z niej, wyrażasz zgodę na niniejszą Politykę prywatności. Jeśli nie zgadzasz się z naszymi zasadami i praktykami, możesz nie korzystać z naszej Aplikacji.

1. Przejrzystość relacji z platformą
VERDICT to niezależna aplikacja strony trzeciej i nie jest powiązana, wspierana, sponsorowana ani administrowana przez Instagram, Facebook ani Meta Platforms, Inc.. „Instagram” jest znakiem towarowym Meta Platforms, Inc.. Wykorzystujemy platformę Instagram wyłącznie w celu świadczenia usług analitycznych w oparciu o dane dostępne dla Ciebie jako użytkownika.

2. Informacje, które zbieramy
Aplikację zaprojektowaliśmy z podejściem privacy-first i przetwarzaniem na urządzeniu. Większość analiz działa lokalnie na Twoim telefonie. Nie prowadzimy serwera backend do zbierania haseł do Twoich kont społecznościowych.
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
Twoje bezpieczeństwo jest dla nas ważne. Chronimy dane na Twoim urządzeniu przy użyciu standardowego szyfrowania i bezpiecznych praktyk przechowywania oraz stale udoskonalamy te zabezpieczenia.

7. Prywatność dzieci
Nasze Usługi nie są skierowane do osób poniżej 13 roku życia. Nie zbieramy świadomie danych osobowych od dzieci poniżej 13 roku życia.

8. Zmiany w niniejszej Polityce Prywatności
Od czasu do czasu możemy aktualizować naszą Politykę prywatności. O wszelkich zmianach poinformujemy Cię, publikując nową Politykę prywatności na tej stronie. Zmiany te obowiązują natychmiast po ich opublikowaniu.

9. Skontaktuj się z nami
Jeśli masz jakieś pytania lub sugestie, nie wahaj się z nami skontaktować.''',
  'ca': '''POLÍTICA DE PRIVADESA PER A VERDICT

Aquesta Política de privadesa explica com VERDICT, desenvolupat per Görkem Ali Cömert, gestiona la informació relacionada amb el vostre ús de la nostra aplicació mòbil. En accedir o utilitzar l'aplicació, acceptes aquesta Política de privadesa. Si no esteu d'acord amb les nostres polítiques i pràctiques, la vostra opció és no utilitzar la nostra aplicació.

1. Transparència sobre la relació amb la plataforma
VERDICT és una aplicació de tercers independent i no està afiliada, avalada, patrocinada ni administrada per, Instagram, Facebook o Meta Platforms, Inc. "Instagram" és una marca comercial de Meta Platforms, Inc. Utilitzem la plataforma Instagram estrictament per oferir serveis d'anàlisi basats en les dades disponibles com a usuari.

2. La informació que recollim
Hem dissenyat l'aplicació tenint en compte la privadesa primer, el processament al dispositiu. La majoria d'anàlisis s'executen localment al vostre telèfon. No executem cap servidor de fons per recollir les vostres contrasenyes de xarxes socials.
A. Dades personals (autenticació): per realitzar anàlisis de seguidors, heu d'iniciar sessió al vostre compte Instagram.
Com funciona: l'aplicació utilitza un WebView segur (un component del navegador dins de l'aplicació) per dirigir-vos a la pàgina d'inici de sessió oficial de Instagram.
El nostre accés: NO veiem, emmagatzemem ni transmetem la vostra contrasenya. Les galetes de sessió i els testimonis d'autenticació s'emmagatzemen estrictament a l'emmagatzematge local segur del vostre dispositiu (p. ex., Android SharedPreferences, iOS Keychain) per mantenir la vostra sessió.
Emmagatzematge del servidor: NO carreguem les vostres credencials d'inici de sessió ni les vostres llistes de seguidors a cap servidor extern de la nostra propietat.
B. Informació sobre l'ús i el dispositiu: nosaltres i els nostres proveïdors de serveis de tercers (Google AdMob, Firebase), podem recopilar automàticament certa informació sobre el vostre dispositiu per millorar el rendiment de l'aplicació i publicar anuncis. Això pot incloure:
Model i fabricant del dispositiu
Versió del sistema operatiu
Tipus de xarxa (WiFi/cel·lular)
Identificador de publicitat (AAID per a Android/IDFA per a iOS)
Registres d'errors i dades de rendiment

3. Com fem servir la vostra informació
Utilitzem la informació recollida per a les finalitats següents:
Per oferir serveis: per comparar les vostres llistes de "Seguidors" i de "Seguidors" localment al vostre dispositiu per identificar els que no fan els seguidors, els seguidors nous i els seguidors.
Per mantenir l'aplicació: per utilitzar Firebase Remote Config per gestionar les actualitzacions d'aplicacions, els modes de manteniment i els canvis de funcions.
Per publicar anuncis: per mostrar anuncis rellevants mitjançant Google AdMob, cosa que ajuda a mantenir aquesta aplicació gratuïta.

4. Serveis de tercers i intercanvi de dades
No venem les vostres dades personals. Tanmateix, utilitzem serveis de tercers de confiança que poden recopilar informació utilitzada per identificar el vostre dispositiu amb finalitats publicitàries i analítiques. Us recomanem que reviseu les polítiques de privadesa d'aquests proveïdors de serveis de tercers:
Google AdMob: Política de privadesa
Google Firebase: Política de privadesa

5. Conservació i supressió de dades
Dades locals: com que les vostres dades de seguidors i les galetes de sessió s'emmagatzemen localment al vostre dispositiu, teniu el control total.
Supressió: podeu eliminar totes les dades emmagatzemades per l'aplicació en qualsevol moment mitjançant:
Tanqueu la sessió mitjançant la configuració de l'aplicació.
Esborrar l'"Emmagatzematge/Caché" de l'aplicació a la configuració del telèfon.
Desinstal·lant l'aplicació. Un cop desinstal·lat, no ens queda cap rastre de les vostres dades.

6. Seguretat
La teva seguretat ens importa. Protegim les dades del vostre dispositiu amb pràctiques estàndard d'encriptació i emmagatzematge segur, i millorem contínuament aquestes proteccions.

7. Privadesa dels nens
Els nostres Serveis no s'adrecen a ningú menor de 13 anys. No recollim conscientment informació d'identificació personal de menors de 13 anys.

8. Canvis a aquesta Política de privadesa
És possible que actualitzem la nostra Política de privadesa de tant en tant. Us avisarem de qualsevol canvi mitjançant la publicació de la nova Política de privadesa en aquesta pàgina. Aquests canvis són efectius immediatament després de la seva publicació.

9. Contacta amb nosaltres
Si tens qualsevol pregunta o suggeriment, no dubtis a contactar amb nosaltres.''',
  'zh-hant': '''VERDICT 的隱私權政策

本隱私權政策解釋了由 Görkem Ali Cömert 開發的 VERDICT 如何處理與您使用我們的行動應用程式相關的資訊。透過存取或使用該應用程序，您同意本隱私權政策。如果您不同意我們的政策和做法，您的選擇是不使用我們的應用程式。

1. 平台關係的透明度
VERDICT 是獨立的第三方應用程序，不隸屬於 Instagram、Facebook 或 Meta Platforms, Inc.，也不受其認可、贊助或管理。 「Instagram」是 Meta Platforms, Inc. 的商標。 Instagram平台嚴格根據您作為使用者可用的資料提供分析服務。

2. 我們收集的資訊
我們設計該應用程式時考慮到了隱私第一、設備上的處理。大多數分析在您的手機上本地運行。我們不會運行後端伺服器來收集您的社交媒體密碼。
A. 個人資料（驗證）：要執行追蹤者分析，您必須登入您的 Instagram 帳戶。
如何運作：該應用程式使用安全的 WebView（應用程式內的瀏覽器元件）將您引導至 Instagram 的官方登入頁面。
我們的存取：我們不會查看、儲存或傳輸您的密碼。您的會話 cookie 和驗證令牌嚴格儲存在裝置的本機安全儲存中（例如 Android SharedPreferences, iOS Keychain），以維護您的會話。
伺服器儲存：我們不會將您的登入憑證或追蹤者清單上傳到我們擁有的任何外部伺服器。
B. 使用情況和設備資訊：我們和我們的第三方服務提供者（Google AdMob、Firebase）可能會自動收集有關您裝置的某些信息，以提高應用程式效能並投放廣告。這可能包括：
設備型號和製造商
作業系統版本
網路類型（WiFi/蜂窩）
廣告 ID（Android 為 AAID / iOS 為 IDFA）
崩潰日誌和效能數據

3.我們如何使用您的訊息
我們將收集的資訊用於以下目的：
提供服務：比較您裝置上本地的「追蹤者」和「追蹤者」列表，以識別取消追蹤者、新追蹤者和粉絲。
維護應用程式：使用 Firebase Remote Config 管理應用程式更新、維護模式和功能切換。
投放廣告：透過 Google AdMob 顯示相關廣告，這有助於保持此應用程式免費使用。

4. 第三方服務和資料共享
我們不會出售您的個人資料。但是，我們使用受信任的第三方服務，這些服務可能會收集用於識別您的裝置的信息，以用於廣告和分析目的。我們建議您查看這些第三方服務提供者的隱私權政策：
Google AdMob：隱私權政策
Google Firebase：隱私權政策

5. 資料保留和刪除
本機資料：由於您的追蹤者資料和會話 cookie 儲存在您的裝置本機，因此您擁有完全的控制權。
刪除：您可以隨時透過以下方式刪除應用程式儲存的所有資料：
透過應用程式設定註銷。
在手機設定中清除應用程式的「儲存/快取」。
卸載應用程式。卸載後，我們將不會留下任何資料痕跡。

6. 安全
您的安全對我們很重要。我們透過標準加密和安全儲存實踐來保護您裝置上的數據，並不斷改進這些保護。

7. 兒童隱私
我們的服務不針對 13 歲以下的任何人。我們不會故意收集 13 歲以下兒童的個人識別資訊。

8. 本隱私權政策的變更
我們可能會不時更新我們的隱私權政策。我們將透過在此頁面上發布新的隱私權政策來通知您任何變更。這些變更在發布後立即生效。

9. 聯絡我們
如果您有任何疑問或建議，請隨時與我們聯繫。''',
  'hr': '''POLITIKA PRIVATNOSTI ZA VERDICT

Ova Pravila o privatnosti objašnjavaju kako VERDICT, koji je razvio Görkem Ali Cömert, postupa s informacijama koje se odnose na vašu upotrebu naše mobilne aplikacije. Pristupom ili korištenjem aplikacije, slažete se s ovom Politikom privatnosti. Ako se ne slažete s našim pravilima i praksama, vaš je izbor ne koristiti našu aplikaciju.

1. Transparentnost odnosa s platformom
VERDICT je neovisna aplikacija treće strane i nije povezana, podržana, sponzorirana ili njome upravljaju Instagram, Facebook ili Meta Platforms, Inc. "Instagram" je zaštitni znak tvrtke Meta Platforms, Inc. Platformu Instagram koristimo isključivo za pružanje usluga analize na temelju podataka dostupnih vama kao korisniku.

2. Informacije koje prikupljamo
Dizajnirali smo aplikaciju imajući na umu privatnost na prvom mjestu, obradu na uređaju. Većina analiza izvodi se lokalno na vašem telefonu. Ne pokrećemo pozadinski poslužitelj za prikupljanje vaših lozinki za društvene mreže.
A. Osobni podaci (Autentifikacija): Da biste izvršili analizu sljedbenika, morate se prijaviti na svoj Instagram račun.
Kako radi: Aplikacija koristi sigurni WebView (komponentu preglednika unutar aplikacije) da vas usmjeri na službenu stranicu za prijavu Instagram.
Naš pristup: NE vidimo, ne pohranjujemo niti prenosimo vašu lozinku. Vaši sesijski kolačići i tokeni za provjeru autentičnosti pohranjuju se strogo unutar lokalne sigurne pohrane vašeg uređaja (npr. Android SharedPreferences, iOS Keychain) kako bi se održala vaša sesija.
Pohrana poslužitelja: NE učitavamo vaše vjerodajnice za prijavu ili vaše popise sljedbenika na bilo koji vanjski poslužitelj u našem vlasništvu.
B. Informacije o korištenju i uređaju: Mi i naši pružatelji usluga trećih strana (Google AdMob, Firebase) možemo automatski prikupljati određene informacije o vašem uređaju kako bismo poboljšali rad aplikacije i posluživali oglase. To može uključivati:
Model i proizvođač uređaja
Verzija operativnog sustava
Vrsta mreže (WiFi/mobilna)
ID za oglašavanje (AAID za Android / IDFA za iOS)
Dnevnici padova i podaci o izvedbi

3. Kako koristimo vaše podatke
Prikupljene podatke koristimo u sljedeće svrhe:
Za pružanje usluga: za usporedbu vaših popisa "Followers" i "Following" lokalno na vašem uređaju za prepoznavanje onih koji vas ne prate, novih pratitelja i obožavatelja.
Za održavanje aplikacije: Za korištenje Firebase Remote Config za upravljanje ažuriranjem aplikacije, načinima održavanja i uključivanjem značajki.
Za posluživanje oglasa: za prikaz relevantnih oglasa putem Google AdMob, što pomaže da ova aplikacija ostane besplatna za korištenje.

4. Usluge trećih strana i dijeljenje podataka
Ne prodajemo vaše osobne podatke. Međutim, koristimo pouzdane usluge trećih strana koje mogu prikupljati informacije koje se koriste za identifikaciju vašeg uređaja u svrhe oglašavanja i analitike. Savjetujemo vam da pregledate pravila o privatnosti ovih pružatelja usluga trećih strana:
Google AdMob: Pravila privatnosti
Google Firebase: Pravila privatnosti

5. Zadržavanje i brisanje podataka
Lokalni podaci: budući da se podaci o vašim pratiteljima i kolačići sesije pohranjuju lokalno na vašem uređaju, imate potpunu kontrolu.
Brisanje: Sve podatke pohranjene u aplikaciji možete izbrisati u bilo kojem trenutku na sljedeći način:
Odjava putem postavki aplikacije.
Brisanje "Storage/Cache" aplikacije u postavkama telefona.
Deinstaliranje aplikacije. Nakon deinstalacije, nema traga vašim podacima kod nas.

6. Sigurnost
Vaša sigurnost nam je važna. Štitimo podatke na vašem uređaju standardnom enkripcijom i praksama sigurnog pohranjivanja te kontinuirano poboljšavamo tu zaštitu.

7. Privatnost djece
Naše se usluge ne obraćaju nikome mlađem od 13 godina. Ne prikupljamo svjesno osobne podatke od djece mlađe od 13 godina.

8. Promjene ove Politike privatnosti
S vremena na vrijeme možemo ažurirati našu Politiku privatnosti. Obavijestit ćemo vas o svim promjenama objavljivanjem novih Pravila privatnosti na ovoj stranici. Ove promjene stupaju na snagu odmah nakon što su objavljene.

9. Kontaktirajte nas
Ako imate bilo kakvih pitanja ili sugestija, ne ustručavajte se kontaktirati nas.''',
  'cs': '''ZÁSADY OCHRANY OSOBNÍCH ÚDAJŮ PRO VERDICT

Tyto zásady ochrany osobních údajů vysvětlují, jak VERDICT, vyvinutý společností Görkem Ali Cömert, nakládá s informacemi souvisejícími s vaším používáním naší mobilní aplikace. Přístupem k aplikaci nebo jejím používáním souhlasíte s těmito Zásadami ochrany osobních údajů. Pokud nesouhlasíte s našimi zásadami a postupy, vaše volba je nepoužívat naši aplikaci.

1. Transparentnost o vztazích mezi platformami
VERDICT je nezávislá aplikace třetí strany a není přidružena, schválena, sponzorována ani spravována společnostmi Instagram, Facebook nebo Meta Platforms, Inc. „Instagram“ je ochranná známka společnosti Meta Platforms, Inc. Platformu Instagram používáme výhradně k poskytování analytických služeb na základě dat, která máte jako uživatel k dispozici.

2. Informace, které shromažďujeme
Aplikaci jsme navrhli s ohledem na ochranu soukromí a zpracování na zařízení. Většina analýz probíhá lokálně ve vašem telefonu. Neprovozujeme back-end server pro shromažďování vašich hesel pro sociální sítě.
A. Osobní údaje (Autentizace): Chcete-li provést analýzu sledujících, musíte se přihlásit ke svému účtu Instagram.
Jak to funguje: Aplikace používá zabezpečený WebView (součást prohlížeče v rámci aplikace), aby vás přesměrovala na oficiální přihlašovací stránku Instagram.
Náš přístup: Vaše heslo NEVIDÍME, neukládáme ani nepřenášíme. Soubory cookie vaší relace a ověřovací tokeny jsou uloženy přísně v místním zabezpečeném úložišti vašeho zařízení (např. Android SharedPreferences, iOS Keychain), aby byla zachována vaše relace.
Úložiště serveru: Vaše přihlašovací údaje ani seznamy sledujících NENAHRÁVÁME na žádný externí server, který vlastníme.
B. Informace o použití a zařízení: My a naši poskytovatelé služeb třetích stran (Google AdMob, Firebase) můžeme automaticky shromažďovat určité informace o vašem zařízení za účelem zlepšení výkonu aplikace a zobrazování reklam. To může zahrnovat:
Model zařízení a výrobce
Verze operačního systému
Typ sítě (WiFi/Mobilní)
Reklamní ID (AAID pro Android / IDFA pro iOS)
Protokoly o selhání a údaje o výkonu

3. Jak používáme vaše údaje
Shromážděné informace používáme pro následující účely:
Poskytování služeb: Chcete-li porovnat své seznamy „Sledovaní“ a „Sledování“ lokálně na vašem zařízení, abyste identifikovali osoby, které přestaly sledovat, nové sledující a fanoušky.
Údržba aplikace: Chcete-li používat Firebase Remote Config ke správě aktualizací aplikací, režimů údržby a přepínání funkcí.
Chcete-li zobrazovat reklamy: Chcete-li zobrazovat relevantní reklamy prostřednictvím Google AdMob, což pomáhá udržovat tuto aplikaci zdarma k použití.

4. Služby třetích stran a sdílení dat
Vaše osobní údaje neprodáváme. Používáme však důvěryhodné služby třetích stran, které mohou shromažďovat informace používané k identifikaci vašeho zařízení pro reklamní a analytické účely. Doporučujeme vám přečíst si zásady ochrany osobních údajů těchto poskytovatelů služeb třetích stran:
Google AdMob: Zásady ochrany osobních údajů
Google Firebase: Zásady ochrany osobních údajů

5. Uchovávání a mazání dat
Místní data: Vzhledem k tomu, že vaše data sledujících a soubory cookie relace jsou uloženy lokálně ve vašem zařízení, máte plnou kontrolu.
Smazání: Všechna data uložená v aplikaci můžete kdykoli smazat:
Odhlášení přes nastavení aplikace.
Vymazání "Úložiště/Cache" aplikace v nastavení telefonu.
Odinstalování aplikace. Po odinstalaci u nás nezůstane žádná stopa vašich dat.

6. Bezpečnost
Vaše bezpečnost je pro nás důležitá. Data na vašem zařízení chráníme standardními postupy šifrování a bezpečného úložiště a tyto ochrany neustále zlepšujeme.

7. Soukromí dětí
Naše služby neoslovují nikoho mladšího 13 let. Vědomě neshromažďujeme osobní údaje od dětí mladších 13 let.

8. Změny těchto Zásad ochrany osobních údajů
Naše Zásady ochrany osobních údajů můžeme čas od času aktualizovat. O jakýchkoli změnách vás budeme informovat zveřejněním nových Zásad ochrany osobních údajů na této stránce. Tyto změny jsou účinné ihned po jejich zveřejnění.

9. Kontaktujte nás
Máte-li jakékoli dotazy nebo návrhy, neváhejte nás kontaktovat.''',
  'da': '''FORTROLIGHEDSPOLITIK FOR VERDICT

Denne privatlivspolitik forklarer, hvordan VERDICT, udviklet af Görkem Ali Cömert, håndterer information relateret til din brug af vores mobilapplikation. Ved at tilgå eller bruge appen accepterer du denne fortrolighedspolitik. Hvis du ikke er enig i vores politikker og praksis, er dit valg ikke at bruge vores app.

1. Gennemsigtighed om platformsforhold
VERDICT er en uafhængig tredjepartsapplikation og er ikke tilknyttet, godkendt, sponsoreret eller administreret af Instagram, Facebook eller Meta Platforms, Inc. "Instagram" er et varemærke tilhørende Meta Platforms, Inc. Vi bruger Instagram-platformen udelukkende til at levere analysetjenester baseret på de data, der er tilgængelige for dig som bruger.

2. De oplysninger, vi indsamler
Vi har designet appen med privatliv først, behandling på enheden i tankerne. De fleste analyser kører lokalt på din telefon. Vi kører ikke en backend-server til at indsamle dine adgangskoder til sociale medier.
A. Personlige data (godkendelse): For at udføre følgeranalyse skal du logge ind på din Instagram-konto.
Sådan fungerer det: Appen bruger en sikker WebView (en browserkomponent i appen) til at dirigere dig til Instagrams officielle login-side.
Vores adgang: Vi ser, gemmer eller overfører IKKE din adgangskode. Dine sessionscookies og autentificeringstokens opbevares strengt i den lokale sikre lagring på din enhed (f.eks. Android SharedPreferences, iOS Keychain) for at opretholde din session.
Serveropbevaring: Vi uploader IKKE dine loginoplysninger eller dine følgerlister til nogen ekstern server ejet af os.
B. Oplysninger om brug og enhed: Vi og vores tredjepartstjenesteudbydere (Google AdMob, Firebase) kan automatisk indsamle visse oplysninger om din enhed for at forbedre appens ydeevne og vise annoncer. Dette kan omfatte:
Enhedsmodel og producent
Operativsystem version
Netværkstype (WiFi/Mobil)
Annonce-id (AAID til Android / IDFA til iOS)
Crash-logs og ydeevnedata

3. Hvordan vi bruger dine oplysninger
Vi bruger de indsamlede oplysninger til følgende formål:
At levere tjenester: At sammenligne dine "Følgere" og "Følger"-lister lokalt på din enhed for at identificere ikke-følgere, nye følgere og fans.
Sådan vedligeholdes appen: For at bruge Firebase Remote Config til at administrere appopdateringer, vedligeholdelsestilstande og funktionsskift.
At vise annoncer: At vise relevante annoncer via Google AdMob, hvilket hjælper med at holde denne app gratis at bruge.

4. Tredjepartstjenester og datadeling
Vi sælger ikke dine personlige data. Vi bruger dog betroede tredjepartstjenester, der kan indsamle oplysninger, der bruges til at identificere din enhed til reklame- og analyseformål. Vi råder dig til at gennemgå fortrolighedspolitikkerne for disse tredjepartstjenesteudbydere:
Google AdMob: Privatlivspolitik
Google Firebase: Privatlivspolitik

5. Opbevaring og sletning af data
Lokale data: Da dine følgerdata og sessionscookies gemmes lokalt på din enhed, har du fuld kontrol.
Sletning: Du kan til enhver tid slette alle data gemt af appen ved at:
Log ud via appindstillingerne.
Rydning af Appens "Lagring/Cache" i dine telefonindstillinger.
Afinstallerer appen. Når først afinstalleret, er der ingen spor af dine data tilbage hos os.

6. Sikkerhed
Din sikkerhed betyder noget for os. Vi beskytter data på din enhed med standardkryptering og sikker opbevaringspraksis, og vi forbedrer løbende disse beskyttelser.

7. Børns privatliv
Vores tjenester henvender sig ikke til nogen under 13 år. Vi indsamler ikke bevidst personligt identificerbare oplysninger fra børn under 13 år.

8. Ændringer af denne fortrolighedspolitik
Vi kan opdatere vores privatlivspolitik fra tid til anden. Vi vil underrette dig om eventuelle ændringer ved at offentliggøre den nye privatlivspolitik på denne side. Disse ændringer træder i kraft umiddelbart efter, at de er offentliggjort.

9. Kontakt os
Hvis du har spørgsmål eller forslag, så tøv ikke med at kontakte os.''',
  'fi': '''VERDICT-TIETOSUOJAKÄYTTÖ

Tämä tietosuojakäytäntö selittää, kuinka Görkem Ali Cömertin kehittämä VERDICT käsittelee mobiilisovelluksemme käyttöön liittyviä tietoja. Kun käytät sovellusta tai käytät sitä, hyväksyt tämän tietosuojakäytännön. Jos et hyväksy käytäntöjämme ja käytäntöjämme, valintasi on olla käyttämättä sovellustamme.

1. Avoimuus alustasuhteista
VERDICT on riippumaton kolmannen osapuolen sovellus, eikä se ole Instagramin, Facebookin tai Meta Platforms, Inc.:n kanssa sidoksissa, hyväksymä, sponsoroima tai hallinnoima. "Instagram" on Meta Platforms, Inc.:n tavaramerkki. Käytämme Instagram-alustaa ainoastaan tarjotaksemme analytiikkapalveluja käyttäjänä käytettävissä olevien tietojen perusteella.

2. Keräämämme tiedot
Suunnittelimme sovelluksen ajatellen tietosuojaa ennen kaikkea laitteessa tapahtuvaa käsittelyä. Useimmat analyysit suoritetaan paikallisesti puhelimellasi. Emme käytä taustapalvelinta sosiaalisen median salasanojesi keräämiseen.
A. Henkilötiedot (todennus): Jotta voit suorittaa seuraajaanalyysin, sinun on kirjauduttava sisään Instagram-tilillesi.
Kuinka se toimii: Sovellus ohjaa sinut Instagramin viralliselle kirjautumissivulle suojatun WebViewin (sovelluksen selainkomponentin) avulla.
Pääsymme: EMME näe, tallenna tai lähetä salasanaasi. Istuntoevästeet ja todennustunnukset tallennetaan tiukasti laitteesi paikalliseen suojattuun tallennustilaan (esim. Android SharedPreferences, iOS Keychain) istunnon ylläpitämiseksi.
Palvelimen tallennus: emme lataa kirjautumistunnuksiasi tai seuraajaluetteloitasi millekään omistamamme ulkoiselle palvelimelle.
B. Käyttö- ja laitetiedot: Me ja kolmannen osapuolen palveluntarjoajamme (Google AdMob, Firebase) voimme kerätä automaattisesti tiettyjä tietoja laitteestasi parantaaksemme sovellusten suorituskykyä ja näyttääksemme mainoksia. Tämä voi sisältää:
Laitteen malli ja valmistaja
Käyttöjärjestelmän versio
Verkkotyyppi (WiFi/matkapuhelin)
Mainostunnus (AAID Androidille / IDFA iOS:lle)
Kaatumislokit ja suorituskykytiedot

3. Kuinka käytämme tietojasi
Käytämme kerättyjä tietoja seuraaviin tarkoituksiin:
Palvelujen tarjoaminen: Voit verrata "Seuraajat"- ja "Seuraavat"-luetteloita paikallisesti laitteessasi tunnistaaksesi seuraajansa lopettaneet, uudet seuraajat ja fanit.
Sovelluksen ylläpito: Käytä Firebase Remote Config-sovellusta sovelluspäivitysten, ylläpitotilojen ja toimintojen vaihtamiseen.
Mainosten näyttäminen: osuvien mainosten näyttäminen Google AdMob-palvelun kautta, mikä auttaa pitämään tämän sovelluksen vapaana.

4. Kolmannen osapuolen palvelut ja tietojen jakaminen
Emme myy henkilötietojasi. Käytämme kuitenkin luotettavia kolmannen osapuolen palveluita, jotka voivat kerätä tietoja, joita käytetään laitteesi tunnistamiseen mainontaa ja analytiikkaa varten. Suosittelemme tutustumaan näiden kolmannen osapuolen palveluntarjoajien tietosuojakäytäntöihin:
Google AdMob: Tietosuojakäytäntö
Google Firebase: Tietosuojakäytäntö

5. Tietojen säilyttäminen ja poistaminen
Paikalliset tiedot: Koska seuraajatietosi ja istuntoevästeet tallennetaan paikallisesti laitteellesi, sinulla on täysi hallinta.
Poistaminen: Voit poistaa kaikki sovelluksen tallentamat tiedot milloin tahansa seuraavasti:
Kirjaudu ulos sovelluksen asetuksista.
Tyhjennä sovelluksen "Tallennus/välimuisti" puhelimen asetuksista.
Sovelluksen asennuksen poistaminen. Kun asennus on poistettu, tiedoistasi ei jää jälkeäkään.

6. Turvallisuus
Turvallisuutesi on meille tärkeä. Suojaamme laitteesi tiedot vakiosalauksella ja suojatulla tallennuskäytännöllä, ja parannamme näitä suojauksia jatkuvasti.

7. Lasten yksityisyys
Palvelumme eivät koske alle 13-vuotiaita. Emme tietoisesti kerää henkilökohtaisia tunnistetietoja alle 13-vuotiailta lapsilta.

8. Muutokset tähän tietosuojakäytäntöön
Saatamme päivittää tietosuojakäytäntöämme ajoittain. Ilmoitamme sinulle kaikista muutoksista julkaisemalla uuden tietosuojakäytännön tällä sivulla. Nämä muutokset tulevat voimaan heti niiden julkaisemisen jälkeen.

9. Ota yhteyttä
Jos sinulla on kysyttävää tai ehdotuksia, älä epäröi ottaa meihin yhteyttä.''',
  'fr-ca': '''POLITIQUE DE CONFIDENTIALITÉ POUR VERDICT

Cette politique de confidentialité explique comment VERDICT, développé par Görkem Ali Cömert, traite les informations liées à votre utilisation de notre application mobile. En accédant ou en utilisant l'application, vous acceptez cette politique de confidentialité. Si vous n'êtes pas d'accord avec nos politiques et pratiques, votre choix est de ne pas utiliser notre application.

1. Transparence sur la relation avec la plateforme
VERDICT est une application tierce indépendante et n'est pas affiliée, approuvée, sponsorisée ou administrée par Instagram, Facebook ou Meta Platforms, Inc. "Instagram" est une marque commerciale de Meta Platforms, Inc.. Nous utilisons le Plateforme Instagram strictement destinée à fournir des services d'analyse basés sur les données dont vous disposez en tant qu'utilisateur.

2. Les informations que nous collectons
Nous avons conçu l'application en gardant à l'esprit le traitement sur l'appareil axé sur la confidentialité. La plupart des analyses s'exécutent localement sur votre téléphone. Nous n'exécutons pas de serveur backend pour collecter vos mots de passe de réseaux sociaux.
A. Données personnelles (authentification) : Pour effectuer une analyse des abonnés, vous devez vous connecter à votre compte Instagram.
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
Pour diffuser des annonces : pour afficher des publicités pertinentes via Google AdMob, ce qui permet de garder cette application gratuite.

4. Services tiers et partage de données
Nous ne vendons pas vos données personnelles. Cependant, nous utilisons des services tiers de confiance qui peuvent collecter des informations utilisées pour identifier votre appareil à des fins publicitaires et analytiques. Nous vous conseillons de consulter les politiques de confidentialité de ces prestataires de services tiers :
Google AdMob : Politique de confidentialité
Google Firebase : Politique de confidentialité

5. Conservation et suppression des données
Données locales : étant donné que les données de vos abonnés et les cookies de session sont stockés localement sur votre appareil, vous avez le contrôle total.
Suppression : vous pouvez supprimer toutes les données stockées par l'application à tout moment en :
Déconnexion via les paramètres de l'application.
Effacement du « Stockage/Cache » de l'application dans les paramètres de votre téléphone.
Désinstallation de l'application. Une fois désinstallé, aucune trace de vos données ne reste chez nous.

6. Sécurité
Votre sécurité nous tient à cœur. Nous protégeons les données sur votre appareil avec des pratiques de cryptage et de stockage sécurisées standard, et nous améliorons continuellement ces protections.

7. Confidentialité des enfants
Nos services ne s'adressent pas aux personnes de moins de 13 ans. Nous ne collectons pas sciemment d'informations personnellement identifiables auprès d'enfants de moins de 13 ans.

8. Modifications de cette politique de confidentialité
Nous pouvons mettre à jour notre politique de confidentialité de temps à autre. Nous vous informerons de tout changement en publiant la nouvelle politique de confidentialité sur cette page. Ces modifications entrent en vigueur immédiatement après leur publication.

9. Contactez-nous
Si vous avez des questions ou des suggestions, n'hésitez pas à nous contacter.''',
  'el': '''ΠΟΛΙΤΙΚΗ ΑΠΟΡΡΗΤΟΥ ΓΙΑ VERDICT

Αυτή η Πολιτική Απορρήτου εξηγεί πώς το VERDICT, που αναπτύχθηκε από τον Görkem Ali Cömert, χειρίζεται πληροφορίες που σχετίζονται με τη χρήση της εφαρμογής μας για κινητά από εσάς. Με την πρόσβαση ή τη χρήση της Εφαρμογής, συμφωνείτε με αυτήν την Πολιτική Απορρήτου. Εάν δεν συμφωνείτε με τις πολιτικές και τις πρακτικές μας, η επιλογή σας είναι να μην χρησιμοποιήσετε την Εφαρμογή μας.

1. Διαφάνεια σχετικά με τη σχέση πλατφόρμας
Το VERDICT είναι μια ανεξάρτητη εφαρμογή τρίτου μέρους και δεν συνδέεται με, δεν υποστηρίζεται, χορηγείται ή διαχειρίζεται από τα Instagram, Facebook ή Meta Platforms, Inc. "Meta Platforms, Inc." του εμπορικού σήματος "XQZPTOK" Meta Platforms, Inc. Χρησιμοποιούμε την πλατφόρμα Instagram αυστηρά για να παρέχουμε υπηρεσίες ανάλυσης με βάση τα δεδομένα που έχετε στη διάθεσή σας ως χρήστη.

2. Οι πληροφορίες που συλλέγουμε
Σχεδιάσαμε την εφαρμογή έχοντας κατά νου την επεξεργασία απορρήτου πρώτα στη συσκευή. Οι περισσότερες αναλύσεις εκτελούνται τοπικά στο τηλέφωνό σας. Δεν εκτελούμε διακομιστή υποστήριξης για τη συλλογή των κωδικών πρόσβασης των μέσων κοινωνικής δικτύωσης.
Α. Προσωπικά δεδομένα (Έλεγχος ταυτότητας): Για να πραγματοποιήσετε ανάλυση ακολούθων, πρέπει να συνδεθείτε στον λογαριασμό σας Instagram.
Πώς λειτουργεί: Η εφαρμογή χρησιμοποιεί ένα ασφαλές WebView (ένα στοιχείο προγράμματος περιήγησης εντός της εφαρμογής) για να σας κατευθύνει στην επίσημη σελίδα σύνδεσης του Instagram.
Η πρόσβασή μας: ΔΕΝ βλέπουμε, αποθηκεύουμε ή μεταδίδουμε τον κωδικό πρόσβασής σας. Τα cookie περιόδου λειτουργίας και τα διακριτικά ελέγχου ταυτότητας αποθηκεύονται αυστηρά στον τοπικό ασφαλή χώρο αποθήκευσης της συσκευής σας (π.χ. Android SharedPreferences, iOS Keychain) για τη διατήρηση της συνεδρίας σας.
Αποθήκευση διακομιστή: ΔΕΝ ανεβάζουμε τα διαπιστευτήρια σύνδεσής σας ή τις λίστες ακολούθων σας σε οποιονδήποτε εξωτερικό διακομιστή που ανήκει σε εμάς.
Β. Πληροφορίες χρήσης και συσκευής: Εμείς και οι τρίτοι πάροχοι υπηρεσιών μας (Google AdMob, Firebase), ενδέχεται να συλλέξουμε αυτόματα ορισμένες πληροφορίες σχετικά με τη συσκευή σας για τη βελτίωση της απόδοσης της εφαρμογής και την προβολή διαφημίσεων. Αυτό μπορεί να περιλαμβάνει:
Μοντέλο και κατασκευαστής συσκευής
Έκδοση λειτουργικού συστήματος
Τύπος δικτύου (WiFi/Κυψέλη)
Αναγνωριστικό διαφήμισης (AAID για Android / IDFA για iOS)
Αρχεία καταγραφής σφαλμάτων και δεδομένα απόδοσης

3. Πώς χρησιμοποιούμε τις πληροφορίες σας
Χρησιμοποιούμε τις πληροφορίες που συλλέγουμε για τους ακόλουθους σκοπούς:
Παροχή υπηρεσιών: Για να συγκρίνετε τις λίστες "Ακολουθούν" και "Ακολουθούν" τοπικά στη συσκευή σας για να εντοπίσετε άτομα που δεν ακολουθούν, νέους οπαδούς και θαυμαστές.
Για να διατηρήσετε την εφαρμογή: Για να χρησιμοποιήσετε το Firebase Remote Config για να διαχειριστείτε ενημερώσεις εφαρμογών, λειτουργίες συντήρησης και εναλλαγές λειτουργιών.
Προβολή διαφημίσεων: Για εμφάνιση σχετικών διαφημίσεων μέσω Google AdMob, το οποίο βοηθάει να διατηρείται αυτή η εφαρμογή δωρεάν στη χρήση.

4. Υπηρεσίες τρίτων και κοινή χρήση δεδομένων
Δεν πουλάμε τα προσωπικά σας δεδομένα. Ωστόσο, χρησιμοποιούμε αξιόπιστες υπηρεσίες τρίτων που ενδέχεται να συλλέγουν πληροφορίες που χρησιμοποιούνται για την αναγνώριση της συσκευής σας για διαφημιστικούς και αναλυτικούς σκοπούς. Σας συμβουλεύουμε να διαβάσετε τις πολιτικές απορρήτου αυτών των τρίτων παρόχων υπηρεσιών:
Google AdMob: Πολιτική απορρήτου
Google Firebase: Πολιτική απορρήτου

5. Διατήρηση και διαγραφή δεδομένων
Τοπικά δεδομένα: Εφόσον τα δεδομένα των ακολούθων και τα cookie περιόδου λειτουργίας αποθηκεύονται τοπικά στη συσκευή σας, έχετε τον πλήρη έλεγχο.
Διαγραφή: Μπορείτε να διαγράψετε όλα τα δεδομένα που είναι αποθηκευμένα από την εφαρμογή ανά πάσα στιγμή με:
Αποσύνδεση μέσω των ρυθμίσεων εφαρμογής.
Εκκαθάριση του "Storage/Cache" της εφαρμογής στις ρυθμίσεις του τηλεφώνου σας.
Απεγκατάσταση της εφαρμογής. Μετά την απεγκατάσταση, κανένα ίχνος των δεδομένων σας δεν παραμένει μαζί μας.

6. Ασφάλεια
Η ασφάλειά σας έχει σημασία για εμάς. Προστατεύουμε τα δεδομένα στη συσκευή σας με τυπικές πρακτικές κρυπτογράφησης και ασφαλούς αποθήκευσης και βελτιώνουμε συνεχώς αυτές τις προστασίες.

7. Παιδικό απόρρητο
Οι Υπηρεσίες μας δεν απευθύνονται σε κανέναν κάτω των 13 ετών. Δεν συλλέγουμε εν γνώσει μας στοιχεία προσωπικής ταυτοποίησης από παιδιά κάτω των 13 ετών.

8. Αλλαγές σε αυτήν την Πολιτική Απορρήτου
Ενδέχεται να ενημερώνουμε την Πολιτική Απορρήτου μας από καιρό σε καιρό. Θα σας ειδοποιήσουμε για τυχόν αλλαγές δημοσιεύοντας τη νέα Πολιτική Απορρήτου σε αυτή τη σελίδα. Αυτές οι αλλαγές ισχύουν αμέσως μετά τη δημοσίευσή τους.

9. Επικοινωνήστε μαζί μας
Εάν έχετε οποιεσδήποτε ερωτήσεις ή προτάσεις, μη διστάσετε να επικοινωνήσετε μαζί μας.''',
  'he': '''מדיניות פרטיות עבור VERDICT

מדיניות פרטיות זו מסבירה כיצד VERDICT, שפותחה על ידי Görkem Ali Cömert, מטפלת במידע הקשור לשימוש שלך באפליקציה שלנו לנייד. על ידי גישה או שימוש באפליקציה, אתה מסכים למדיניות פרטיות זו. אם אינך מסכים למדיניות ולנהלים שלנו, הבחירה שלך היא לא להשתמש באפליקציה שלנו.

1. שקיפות לגבי יחסי פלטפורמה
VERDICT היא אפליקציית צד שלישי עצמאית ואינה קשורה ל-Instagram, Facebook או Meta Platforms, Inc., ואינה מאושרת, ממומנת או מנוהלת על ידן. "Instagram" הוא סימן מסחרי של Meta Platforms, Inc. אנו משתמשים בפלטפורמת Instagram אך ורק כדי לספק שירותי אנליטיקה המבוססים על הנתונים הזמינים לך כמשתמש.

2. המידע שאנו אוספים
עיצבנו את האפליקציה מתוך מחשבה על עיבוד במכשיר בראש ובראשונה לפרטיות. רוב הניתוחים פועלים באופן מקומי בטלפון שלך. אנחנו לא מפעילים שרת אחורי כדי לאסוף את סיסמאות המדיה החברתית שלך.
א. נתונים אישיים (אימות): כדי לבצע ניתוח עוקבים, עליך להיכנס לחשבון Instagram שלך.
איך זה עובד: האפליקציה משתמשת ב-WebView מאובטח (רכיב דפדפן בתוך האפליקציה) כדי להפנות אותך לדף ההתחברות הרשמי של Instagram.
הגישה שלנו: אנחנו לא רואים, מאחסנים או מעבירים את הסיסמה שלך. קובצי ה-cookie של ההפעלה ואסימוני האימות שלך מאוחסנים אך ורק באחסון המאובטח המקומי של המכשיר שלך (למשל, Android SharedPreferences, iOS Keychain) כדי לשמור על ההפעלה שלך.
אחסון שרת: אנו לא מעלים את אישורי הכניסה שלך או את רשימות העוקבים שלך לשרת חיצוני כלשהו בבעלותנו.
ב. מידע על שימוש ומכשיר: אנו, וספקי השירותים של הצד השלישי שלנו (Google AdMob, Firebase), עשויים לאסוף באופן אוטומטי מידע מסוים על המכשיר שלך כדי לשפר את ביצועי האפליקציה ולהציג פרסומות. זה עשוי לכלול:
דגם ויצרן מכשיר
גרסת מערכת הפעלה
סוג רשת (WiFi/סלולר)
מזהה פרסום (AAID עבור Android / IDFA עבור iOS)
יומני קריסה ונתוני ביצועים

3. כיצד אנו משתמשים במידע שלך
אנו משתמשים במידע שנאסף למטרות הבאות:
כדי לספק שירותים: כדי להשוות את רשימות ה"עוקבים" ו"העוקבים" שלך באופן מקומי במכשיר שלך כדי לזהות עוקבים, עוקבים חדשים ומעריצים.
כדי לתחזק את האפליקציה: כדי להשתמש ב-Firebase Remote Config לניהול עדכוני אפליקציה, מצבי תחזוקה וחילופי תכונות.
כדי להציג מודעות: כדי להציג פרסומות רלוונטיות באמצעות Google AdMob, מה שעוזר לשמור על האפליקציה הזו חופשית לשימוש.

4. שירותי צד שלישי ושיתוף נתונים
אנחנו לא מוכרים את הנתונים האישיים שלך. עם זאת, אנו משתמשים בשירותי צד שלישי מהימנים שעשויים לאסוף מידע המשמש לזיהוי המכשיר שלך למטרות פרסום וניתוח. אנו ממליצים לך לעיין במדיניות הפרטיות של ספקי שירות צד שלישי אלה:
Google AdMob: מדיניות פרטיות
Google Firebase: מדיניות פרטיות

5. שמירה ומחיקה של נתונים
נתונים מקומיים: מאחר שנתוני העוקבים וקובצי ה-cookie של הפגישה מאוחסנים באופן מקומי במכשיר שלך, יש לך שליטה מלאה.
מחיקה: אתה יכול למחוק את כל הנתונים המאוחסנים באפליקציה בכל עת על ידי:
יציאה דרך הגדרות האפליקציה.
ניקוי "אחסון/מטמון" של האפליקציה בהגדרות הטלפון שלך.
הסרת ההתקנה של האפליקציה. לאחר הסרת ההתקנה, לא נשאר איתנו זכר לנתונים שלך.

6. אבטחה
האבטחה שלך חשובה לנו. אנו מגנים על הנתונים במכשיר שלך באמצעות הצפנה סטנדרטית ושיטות אחסון מאובטחות, ואנו משפרים ללא הרף את ההגנות הללו.

7. פרטיות ילדים
השירותים שלנו אינם פונים לאף אחד מתחת לגיל 13. איננו אוספים ביודעין מידע אישי מזהה מילדים מתחת לגיל 13.

8. שינויים במדיניות פרטיות זו
אנו עשויים לעדכן את מדיניות הפרטיות שלנו מעת לעת. אנו נודיע לך על כל שינוי על ידי פרסום מדיניות הפרטיות החדשה בדף זה. שינויים אלה ייכנסו לתוקף מיד לאחר פרסומם.

9. צור קשר
אם יש לך שאלות או הצעות, אל תהסס לפנות אלינו.''',
  'ms': '''DASAR PRIVASI UNTUK VERDICT

Dasar Privasi ini menerangkan cara VERDICT, yang dibangunkan oleh Görkem Ali Cömert, mengendalikan maklumat yang berkaitan dengan penggunaan aplikasi mudah alih kami oleh anda. Dengan mengakses atau menggunakan Apl, anda bersetuju menerima Dasar Privasi ini. Jika anda tidak bersetuju dengan dasar dan amalan kami, pilihan anda adalah untuk tidak menggunakan Apl kami.

1. Ketelusan Mengenai Perhubungan Platform
VERDICT ialah aplikasi pihak ketiga yang bebas dan tidak bergabung, disokong, ditaja atau ditadbir oleh Instagram, Facebook atau Meta Platforms, Inc. "Instagram" ialah tanda dagangan milik Meta Platforms, Inc. Kami menggunakan platform Instagram semata-mata untuk menyediakan perkhidmatan analitik berdasarkan data yang tersedia kepada anda sebagai pengguna.

2. Maklumat yang Kami Kumpul
Kami mereka Apl dengan mengutamakan privasi, pemprosesan pada peranti dalam fikiran. Kebanyakan analisis dijalankan secara setempat pada telefon anda. Kami tidak menjalankan pelayan bahagian belakang untuk mengumpul kata laluan media sosial anda.
A. Data Peribadi (Pengesahan): Untuk melakukan analisis pengikut, anda mesti log masuk ke akaun Instagram anda.
Cara ia berfungsi: Apl menggunakan WebView yang selamat (komponen penyemak imbas dalam apl) untuk mengarahkan anda ke halaman log masuk rasmi Instagram.
Akses Kami: Kami TIDAK melihat, menyimpan atau menghantar kata laluan anda. Kuki sesi dan token pengesahan anda disimpan dengan ketat dalam storan selamat setempat peranti anda (cth., Android SharedPreferences, iOS Keychain) untuk mengekalkan sesi anda.
Storan Pelayan: Kami TIDAK memuat naik kelayakan log masuk anda atau senarai pengikut anda ke mana-mana pelayan luaran yang dimiliki oleh kami.
B. Maklumat Penggunaan dan Peranti: Kami dan pembekal perkhidmatan pihak ketiga kami (Google AdMob, Firebase), boleh mengumpul maklumat tertentu tentang peranti anda secara automatik untuk meningkatkan prestasi apl dan menyiarkan iklan. Ini mungkin termasuk:
Model peranti dan pengilang
Versi sistem pengendalian
Jenis rangkaian (WiFi/Selular)
ID Pengiklanan (AAID untuk Android / IDFA untuk iOS)
Log ranap sistem dan data prestasi

3. Bagaimana Kami Menggunakan Maklumat Anda
Kami menggunakan maklumat yang dikumpul untuk tujuan berikut:
Untuk Menyediakan Perkhidmatan: Untuk membandingkan senarai "Pengikut" dan "Mengikuti" anda secara setempat pada peranti anda untuk mengenal pasti penyahikut, pengikut baharu dan peminat.
Untuk Mengekalkan Apl: Untuk menggunakan Firebase Remote Config untuk mengurus kemas kini apl, mod penyelenggaraan dan togol ciri.
Untuk Menyajikan Iklan: Untuk memaparkan iklan yang berkaitan melalui Google AdMob, yang membantu memastikan Apl ini bebas digunakan.

4. Perkhidmatan Pihak Ketiga dan Perkongsian Data
Kami tidak menjual data peribadi anda. Walau bagaimanapun, kami menggunakan perkhidmatan pihak ketiga yang dipercayai yang mungkin mengumpul maklumat yang digunakan untuk mengenal pasti peranti anda untuk tujuan pengiklanan dan analitis. Kami menasihati anda untuk menyemak dasar privasi penyedia perkhidmatan pihak ketiga ini:
Google AdMob: Dasar Privasi
Google Firebase: Dasar Privasi

5. Pengekalan dan Pemadaman Data
Data Setempat: Memandangkan data pengikut anda dan kuki sesi disimpan secara setempat pada peranti anda, anda mempunyai kawalan penuh.
Pemadaman: Anda boleh memadam semua data yang disimpan oleh Apl pada bila-bila masa dengan:
Log keluar melalui tetapan Apl.
Membersihkan "Storan/Cache" Apl dalam tetapan telefon anda.
Menyahpasang Apl. Setelah dinyahpasang, tiada kesan data anda kekal bersama kami.

6. Keselamatan
Keselamatan anda penting kepada kami. Kami melindungi data pada peranti anda dengan penyulitan standard dan amalan storan selamat, dan kami terus meningkatkan perlindungan ini.

7. Privasi Kanak-kanak
Perkhidmatan kami tidak menangani sesiapa di bawah umur 13 tahun. Kami tidak mengumpul maklumat yang boleh dikenal pasti secara peribadi daripada kanak-kanak di bawah umur 13 tahun dengan sengaja.

8. Perubahan kepada Dasar Privasi Ini
Kami mungkin mengemas kini Dasar Privasi kami dari semasa ke semasa. Kami akan memberitahu anda tentang sebarang perubahan dengan menyiarkan Dasar Privasi baharu pada halaman ini. Perubahan ini berkuat kuasa serta-merta selepas ia disiarkan.

9. Hubungi Kami
Jika anda mempunyai sebarang soalan atau cadangan, jangan teragak-agak untuk menghubungi kami.''',
  'no': '''PERSONVERN FOR VERDICT

Denne personvernerklæringen forklarer hvordan VERDICT, utviklet av Görkem Ali Cömert, håndterer informasjon relatert til din bruk av mobilapplikasjonen vår. Ved å gå inn på eller bruke appen godtar du denne personvernerklæringen. Hvis du ikke er enig i retningslinjene og praksisene våre, er ditt valg å ikke bruke appen vår.

1. Åpenhet om plattformforhold
VERDICT er en uavhengig tredjepartsapplikasjon og er ikke tilknyttet, godkjent, sponset eller administrert av Instagram, Facebook eller Meta Platforms, Inc. "Instagram" er et varemerke som tilhører Meta Platforms, Inc. Vi bruker Instagram-plattformen utelukkende for å tilby analysetjenester basert på dataene som er tilgjengelige for deg som bruker.

2. Informasjonen vi samler inn
Vi designet appen med personvern først, behandling på enheten i tankene. De fleste analyser kjører lokalt på telefonen din. Vi kjører ikke en backend-server for å samle inn passordene dine for sosiale medier.
A. Personlige data (autentisering): For å utføre følgeranalyse må du logge på Instagram-kontoen din.
Slik fungerer det: Appen bruker en sikker WebView (en nettleserkomponent i appen) for å lede deg til Instagrams offisielle påloggingsside.
Vår tilgang: Vi ser, lagrer eller overfører IKKE passordet ditt. Sesjonskapsler og autentiseringstokener lagres strengt innenfor den lokale sikre lagringen på enheten din (f.eks. Android SharedPreferences, iOS Keychain) for å opprettholde økten din.
Serverlagring: Vi laster IKKE opp påloggingsinformasjonen din eller følgerlistene dine til noen ekstern server som eies av oss.
B. Informasjon om bruk og enhet: Vi og våre tredjeparts tjenesteleverandører (Google AdMob, Firebase), kan automatisk samle inn viss informasjon om enheten din for å forbedre appytelsen og vise annonser. Dette kan inkludere:
Enhetsmodell og produsent
Operativsystemversjon
Nettverkstype (WiFi/Mobil)
Annonserings-ID (AAID for Android / IDFA for iOS)
Krasjlogger og ytelsesdata

3. Hvordan vi bruker informasjonen din
Vi bruker informasjonen som samles inn til følgende formål:
For å tilby tjenester: For å sammenligne "Følgere" og "Følger"-listene dine lokalt på enheten din for å identifisere ikke-følgere, nye følgere og fans.
For å vedlikeholde appen: For å bruke Firebase Remote Config til å administrere appoppdateringer, vedlikeholdsmoduser og funksjonsvekslinger.
For å vise annonser: For å vise relevante annonser via Google AdMob, som bidrar til å holde denne appen gratis å bruke.

4. Tredjepartstjenester og datadeling
Vi selger ikke dine personopplysninger. Vi bruker imidlertid pålitelige tredjepartstjenester som kan samle inn informasjon som brukes til å identifisere enheten din for reklame- og analyseformål. Vi anbefaler deg å lese personvernreglene til disse tredjeparts tjenesteleverandørene:
Google AdMob: Retningslinjer for personvern
Google Firebase: Retningslinjer for personvern

5. Oppbevaring og sletting av data
Lokale data: Siden dine følgerdata og øktinformasjonskapsler lagres lokalt på enheten din, har du full kontroll.
Sletting: Du kan slette alle data som er lagret av appen når som helst ved å:
Logger ut via appinnstillingene.
Tømme appens "lagring/buffer" i telefoninnstillingene.
Avinstallerer appen. Når den er avinstallert, er det ingen spor av dataene dine igjen hos oss.

6. Sikkerhet
Din sikkerhet er viktig for oss. Vi beskytter data på enheten din med standard kryptering og sikker lagringspraksis, og vi forbedrer kontinuerlig disse beskyttelsene.

7. Barns personvern
Våre tjenester henvender seg ikke til noen under 13 år. Vi samler ikke bevisst inn personlig identifiserbar informasjon fra barn under 13 år.

8. Endringer i denne personvernerklæringen
Vi kan oppdatere vår personvernerklæring fra tid til annen. Vi vil varsle deg om eventuelle endringer ved å legge ut den nye personvernerklæringen på denne siden. Disse endringene trer i kraft umiddelbart etter at de er lagt ut.

9. Kontakt oss
Hvis du har spørsmål eller forslag, ikke nøl med å kontakte oss.''',
  'pt-pt': '''POLÍTICA DE PRIVACIDADE PARA VERDICT

Esta Política de Privacidade explica como o VERDICT, desenvolvido por Görkem Ali Cömert, trata as informações relacionadas ao uso do nosso aplicativo móvel. Ao acessar ou utilizar o App, você concorda com esta Política de Privacidade. Se você não concorda com nossas políticas e práticas, sua opção é não usar nosso Aplicativo.

1. Transparência sobre o relacionamento da plataforma
VERDICT é um aplicativo independente de terceiros e não é afiliado, endossado, patrocinado ou administrado por Instagram, Facebook ou Meta Platforms, Inc. "Instagram" é uma marca registrada de Meta Platforms, Inc.. Plataforma Instagram estritamente para fornecer serviços de análise com base nos dados disponíveis para você como usuário.

2. As informações que coletamos
Projetamos o aplicativo tendo em mente o processamento no dispositivo que prioriza a privacidade. A maioria das análises é executada localmente no seu telefone. Não administramos um servidor back-end para coletar suas senhas de redes sociais.
A. Dados Pessoais (Autenticação): Para realizar a análise dos seguidores, você deve fazer login na sua conta Instagram.
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
Para manter o aplicativo: para usar Firebase Remote Config para gerenciar atualizações de aplicativos, modos de manutenção e alternância de recursos.
Para veicular anúncios: para exibir anúncios relevantes via Google AdMob, o que ajuda a manter este aplicativo de uso gratuito.

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
Sua segurança é importante para nós. Protegemos os dados no seu dispositivo com criptografia padrão e práticas de armazenamento seguro, e melhoramos continuamente essas proteções.

7. Privacidade das Crianças
Nossos serviços não se destinam a menores de 13 anos. Não coletamos intencionalmente informações de identificação pessoal de crianças menores de 13 anos.

8. Alterações nesta Política de Privacidade
Poderemos atualizar nossa Política de Privacidade de tempos em tempos. Iremos notificá-lo sobre quaisquer alterações publicando a nova Política de Privacidade nesta página. Essas alterações entram em vigor imediatamente após serem publicadas.

9. Contate-nos
Se você tiver alguma dúvida ou sugestão, não hesite em nos contatar.''',
  'ro': '''POLITICA DE CONFIDENTIALITATE PENTRU VERDICT

Această politică de confidențialitate explică modul în care VERDICT, dezvoltat de Görkem Ali Cömert, gestionează informațiile legate de utilizarea de către dvs. a aplicației noastre mobile. Prin accesarea sau utilizarea aplicației, sunteți de acord cu această Politică de confidențialitate. Dacă nu sunteți de acord cu politicile și practicile noastre, alegerea dvs. este să nu utilizați aplicația noastră.

1. Transparență despre relația cu platforma
VERDICT este o aplicație independentă terță parte și nu este afiliată, susținută, sponsorizată sau administrată de, Instagram, Facebook sau Meta Platforms, Inc. „Instagram” este o marcă comercială a lui. Meta Platforms, Inc. Utilizăm platforma Instagram strict pentru a furniza servicii de analiză bazate pe datele disponibile pentru dvs. ca utilizator.

2. Informațiile pe care le colectăm
Am proiectat aplicația ținând cont în primul rând de confidențialitate, procesarea pe dispozitiv. Majoritatea analizelor rulează local pe telefonul dvs. Nu rulăm un server backend pentru a vă colecta parolele pentru rețelele sociale.
A. Date personale (autentificare): Pentru a efectua analiza urmăritorilor, trebuie să vă conectați la contul dvs. Instagram.
Cum funcționează: Aplicația folosește un WebView securizat (o componentă de browser din cadrul aplicației) pentru a vă direcționa către pagina oficială de conectare a Instagram.
Accesul nostru: NU vedem, stocăm sau transmitem parola dvs. Cookie-urile de sesiune și jetoanele de autentificare sunt stocate strict în spațiul de stocare local securizat al dispozitivului dvs. (de exemplu, Android SharedPreferences, iOS Keychain) pentru a vă menține sesiunea.
Stocare pe server: NU încărcăm datele dvs. de conectare sau listele de urmăritori pe niciun server extern deținut de noi.
B. Informații despre utilizare și dispozitiv: noi și furnizorii noștri de servicii terți (Google AdMob, Firebase), putem colecta automat anumite informații despre dispozitivul dvs. pentru a îmbunătăți performanța aplicației și pentru a difuza reclame. Aceasta poate include:
Modelul și producătorul dispozitivului
Versiunea sistemului de operare
Tip de rețea (WiFi/Celular)
ID de publicitate (AAID pentru Android / IDFA pentru iOS)
Jurnalele de blocare și date de performanță

3. Cum folosim informațiile dvs
Folosim informațiile colectate în următoarele scopuri:
Pentru a oferi servicii: pentru a compara listele dvs. „Următori” și „Următori” la nivel local pe dispozitiv pentru a identifica persoanele care nu sunt urmărite, adepții noi și fanii.
Pentru a întreține aplicația: pentru a utiliza Firebase Remote Config pentru a gestiona actualizările aplicației, modurile de întreținere și comutarile de funcții.
Pentru a difuza reclame: pentru a afișa reclame relevante prin Google AdMob, ceea ce ajută la menținerea gratuită a acestei aplicații.

4. Servicii de la terți și partajarea datelor
Nu vindem datele dumneavoastră cu caracter personal. Cu toate acestea, folosim servicii terțe de încredere care pot colecta informații utilizate pentru a identifica dispozitivul dvs. în scopuri publicitare și de analiză. Vă sfătuim să examinați politicile de confidențialitate ale acestor furnizori de servicii terți:
Google AdMob: Politica de confidențialitate
Google Firebase: Politica de confidențialitate

5. Reținerea și ștergerea datelor
Date locale: Deoarece datele dvs. de urmărire și modulele cookie de sesiune sunt stocate local pe dispozitivul dvs., aveți control deplin.
Ștergere: puteți șterge oricând toate datele stocate de aplicație prin:
Deconectare prin setările aplicației.
Ștergerea „Stocare/cache” a aplicației din setările telefonului.
Dezinstalarea aplicației. Odată dezinstalat, nicio urmă a datelor dvs. nu rămâne la noi.

6. Securitate
Securitatea ta contează pentru noi. Protejăm datele de pe dispozitivul dvs. cu practici standard de criptare și stocare sigură și îmbunătățim continuu aceste protecții.

7. Confidențialitatea copiilor
Serviciile noastre nu se adresează nimănui cu vârsta sub 13 ani. Nu colectăm cu bună știință informații de identificare personală de la copii sub 13 ani.

8. Modificări ale acestei politici de confidențialitate
Putem actualiza Politica noastră de confidențialitate din când în când. Vă vom anunța cu privire la orice modificare postând noua Politică de confidențialitate pe această pagină. Aceste modificări sunt efective imediat după ce sunt postate.

9. Contactați-ne
Dacă aveți întrebări sau sugestii, nu ezitați să ne contactați.''',
  'sk': '''ZÁSADY OCHRANY OSOBNÝCH ÚDAJOV PRE VERDICT

Tieto zásady ochrany osobných údajov vysvetľujú, ako VERDICT, vyvinutý spoločnosťou Görkem Ali Cömert, narába s informáciami súvisiacimi s vaším používaním našej mobilnej aplikácie. Vstupom do aplikácie alebo jej používaním súhlasíte s týmito zásadami ochrany osobných údajov. Ak nesúhlasíte s našimi zásadami a postupmi, vašou voľbou je nepoužívať našu aplikáciu.

1. Transparentnosť o vzťahoch medzi platformami
VERDICT je nezávislá aplikácia tretej strany a nie je pridružená, schválená, sponzorovaná ani spravovaná spoločnosťami Instagram, Facebook alebo Meta Platforms, Inc. „Instagram“ je ochranná známka spoločnosti Meta Platforms, Inc. Platformu Instagram používame výhradne na poskytovanie analytických služieb na základe údajov, ktoré máte ako používateľ k dispozícii.

2. Informácie, ktoré zhromažďujeme
Aplikáciu sme navrhli s ohľadom na súkromie a spracovanie na zariadení. Väčšina analýz prebieha lokálne vo vašom telefóne. Neprevádzkujeme backendový server na zhromažďovanie vašich hesiel sociálnych médií.
A. Osobné údaje (Autentifikácia): Ak chcete vykonať analýzu sledovateľov, musíte sa prihlásiť do svojho účtu Instagram.
Ako to funguje: Aplikácia používa zabezpečený WebView (súčasť prehliadača v rámci aplikácie), aby vás nasmerovala na oficiálnu prihlasovaciu stránku Instagram.
Náš prístup: NEvidíme, neukladáme ani neprenášame vaše heslo. Súbory cookie vašej relácie a overovacie tokeny sú uložené striktne v miestnom zabezpečenom úložisku vášho zariadenia (napr. Android SharedPreferences, iOS Keychain), aby sa zachovala vaša relácia.
Ukladací priestor servera: NENAHRÁVAME vaše prihlasovacie údaje ani zoznamy sledovateľov na žiadny externý server, ktorý vlastníme.
B. Informácie o používaní a zariadení: My a naši poskytovatelia služieb tretích strán (Google AdMob, Firebase) môžeme automaticky zhromažďovať určité informácie o vašom zariadení na zlepšenie výkonu aplikácie a zobrazovanie reklám. To môže zahŕňať:
Model a výrobca zariadenia
Verzia operačného systému
Typ siete (WiFi/Celular)
Reklamný identifikátor (AAID pre Android / IDFA pre iOS)
Protokoly o zlyhaní a údaje o výkone

3. Ako používame vaše informácie
Zhromaždené informácie používame na nasledujúce účely:
Poskytovanie služieb: Porovnanie zoznamov „Nasledovatelia“ a „Sledovaní“ lokálne na vašom zariadení s cieľom identifikovať nesledovateľov, nových sledovateľov a fanúšikov.
Údržba aplikácie: Ak chcete použiť Firebase Remote Config na správu aktualizácií aplikácií, režimov údržby a prepínačov funkcií.
Na zobrazovanie reklám: Na zobrazovanie relevantných reklám prostredníctvom Google AdMob, čo pomáha udržiavať túto aplikáciu zadarmo na používanie.

4. Služby tretích strán a zdieľanie údajov
Vaše osobné údaje nepredávame. Používame však dôveryhodné služby tretích strán, ktoré môžu zhromažďovať informácie používané na identifikáciu vášho zariadenia na reklamné a analytické účely. Odporúčame vám, aby ste si prečítali zásady ochrany osobných údajov týchto poskytovateľov služieb tretích strán:
Google AdMob: Zásady ochrany osobných údajov
Google Firebase: Zásady ochrany osobných údajov

5. Uchovávanie a mazanie údajov
Miestne údaje: Keďže údaje vašich sledovateľov a súbory cookie relácie sú uložené lokálne vo vašom zariadení, máte plnú kontrolu.
Odstránenie: Všetky údaje uložené v aplikácii môžete kedykoľvek odstrániť:
Odhlásenie cez nastavenia aplikácie.
Vymazanie "Úložisko/Vyrovnávacia pamäť" aplikácie v nastaveniach telefónu.
Odinštalovanie aplikácie. Po odinštalovaní u nás nezostane žiadna stopa vašich údajov.

6. Bezpečnosť
Vaša bezpečnosť je pre nás dôležitá. Údaje vo vašom zariadení chránime štandardnými postupmi šifrovania a bezpečného ukladania a tieto ochrany neustále zlepšujeme.

7. Súkromie detí
Naše služby neoslovujú nikoho mladšieho ako 13 rokov. Od detí mladších ako 13 rokov vedome nezhromažďujeme osobné údaje.

8. Zmeny týchto zásad ochrany osobných údajov
Naše Zásady ochrany osobných údajov môžeme z času na čas aktualizovať. O akýchkoľvek zmenách vás budeme informovať zverejnením nových Zásad ochrany osobných údajov na tejto stránke. Tieto zmeny sú účinné ihneď po ich zverejnení.

9. Kontaktujte nás
Ak máte akékoľvek otázky alebo návrhy, neváhajte nás kontaktovať.''',
  'sv': '''SEKRETESSPOLICY FÖR VERDICT

Denna integritetspolicy förklarar hur VERDICT, utvecklad av Görkem Ali Cömert, hanterar information relaterad till din användning av vår mobilapplikation. Genom att komma åt eller använda appen godkänner du denna integritetspolicy. Om du inte håller med vår policy och praxis är ditt val att inte använda vår app.

1. Transparens om plattformsrelationer
VERDICT är en oberoende tredjepartsapplikation och är inte ansluten till, godkänd, sponsrad eller administrerad av Instagram, Facebook eller Meta Platforms, Inc. "Instagram" är ett varumärke som tillhör Meta Platforms, Inc. Vi använder Instagram-plattformen enbart för att tillhandahålla analystjänster baserade på den data som är tillgänglig för dig som användare.

2. Informationen vi samlar in
Vi designade appen med sekretess-först, bearbetning på enheten i åtanke. De flesta analyser körs lokalt på din telefon. Vi kör ingen backend-server för att samla in dina lösenord för sociala medier.
A. Personuppgifter (autentisering): För att utföra följaranalys måste du logga in på ditt Instagram-konto.
Hur det fungerar: Appen använder en säker WebView (en webbläsarkomponent i appen) för att dirigera dig till Instagrams officiella inloggningssida.
Vår åtkomst: Vi ser, lagrar eller överför INTE ditt lösenord. Dina sessionscookies och autentiseringstokens lagras strikt inom den lokala säkra lagringen på din enhet (t.ex. Android SharedPreferences, iOS Keychain) för att upprätthålla din session.
Serverlagring: Vi laddar INTE upp dina inloggningsuppgifter eller dina följarlistor till någon extern server som ägs av oss.
B. Användnings- och enhetsinformation: Vi, och våra tredjepartstjänsteleverantörer (Google AdMob, Firebase), kan automatiskt samla in viss information om din enhet för att förbättra appens prestanda och visa annonser. Detta kan inkludera:
Enhetsmodell och tillverkare
Operativsystem version
Nätverkstyp (WiFi/mobil)
Annons-ID (AAID för Android / IDFA för iOS)
Kraschloggar och prestandadata

3. Hur vi använder din information
Vi använder informationen som samlas in för följande ändamål:
Att tillhandahålla tjänster: För att jämföra dina "Följare" och "Följer"-listor lokalt på din enhet för att identifiera avföljare, nya följare och fans.
För att underhålla appen: För att använda Firebase Remote Config för att hantera appuppdateringar, underhållslägen och funktionsväxlar.
Att visa annonser: För att visa relevanta annonser via Google AdMob, vilket hjälper till att hålla den här appen fri att använda.

4. Tredjepartstjänster och datadelning
Vi säljer inte dina personuppgifter. Däremot använder vi betrodda tredjepartstjänster som kan samla in information som används för att identifiera din enhet för reklam- och analysändamål. Vi råder dig att läsa sekretesspolicyn för dessa tredjepartstjänsteleverantörer:
Google AdMob: Sekretesspolicy
Google Firebase: Sekretesspolicy

5. Datalagring och radering
Lokal data: Eftersom din följardata och sessionscookies lagras lokalt på din enhet har du full kontroll.
Radering: Du kan radera all data som lagras av appen när som helst genom att:
Loggar ut via appinställningarna.
Rensa appens "Storage/Cache" i dina telefoninställningar.
Avinstallerar appen. Efter avinstallation finns inga spår av din data kvar hos oss.

6. Säkerhet
Din säkerhet är viktig för oss. Vi skyddar data på din enhet med standardkryptering och säker lagring, och vi förbättrar kontinuerligt dessa skydd.

7. Barns integritet
Våra tjänster vänder sig inte till någon under 13 år. Vi samlar inte medvetet in personligt identifierbar information från barn under 13 år.

8. Ändringar av denna integritetspolicy
Vi kan uppdatera vår integritetspolicy då och då. Vi kommer att meddela dig om eventuella ändringar genom att publicera den nya integritetspolicyn på denna sida. Dessa ändringar träder i kraft omedelbart efter att de har publicerats.

9. Kontakta oss
Om du har några frågor eller förslag, tveka inte att kontakta oss.''',
  'uk': '''ПОЛІТИКА КОНФІДЕНЦІЙНОСТІ ДЛЯ VERDICT

У цій Політиці конфіденційності пояснюється, як VERDICT, розроблений Görkem Ali Cömert, обробляє інформацію, пов’язану з використанням вами нашої мобільної програми. Отримуючи доступ або використовуючи Додаток, ви погоджуєтеся з цією Політикою конфіденційності. Якщо ви не згодні з нашою політикою та практикою, ви вирішуєте не використовувати наш додаток.

1. Прозорість стосунків між платформами
VERDICT є незалежною сторонньою програмою, яка не пов’язана, не схвалена, спонсорована чи адміністрована Instagram, Facebook або Meta Platforms, Inc. «Instagram» є торговою маркою Meta Platforms, Inc. Ми використовуємо платформу Instagram виключно для надання послуг аналізу на основі даних, доступних вам як користувачу.

2. Інформація, яку ми збираємо
Ми розробили програму з урахуванням конфіденційності, обробки на пристрої. Більшість аналізів виконується локально на вашому телефоні. Ми не використовуємо внутрішній сервер для збору ваших паролів у соціальних мережах.
A. Особисті дані (автентифікація): щоб виконати аналіз підписників, ви повинні увійти у свій обліковий запис Instagram.
Як це працює: програма використовує захищений WebView (компонент браузера в програмі), щоб направити вас на офіційну сторінку входу Instagram.
Наш доступ: ми НЕ бачимо, не зберігаємо та не передаємо ваш пароль. Ваші сеансові файли cookie та маркери автентифікації зберігаються виключно в локальному захищеному сховищі вашого пристрою (наприклад, Android SharedPreferences, iOS Keychain), щоб підтримувати ваш сеанс.
Зберігання на сервері: ми НЕ завантажуємо ваші облікові дані для входу або ваші списки підписників на будь-який зовнішній сервер, який належить нам.
Б. Інформація про використання та пристрій. Ми та наші сторонні постачальники послуг (Google AdMob, Firebase) можемо автоматично збирати певну інформацію про ваш пристрій, щоб покращити продуктивність програми та показувати рекламу. Це може включати:
Модель і виробник пристрою
Версія операційної системи
Тип мережі (Wi-Fi/стільниковий)
Рекламний ідентифікатор (AAID для Android / IDFA для iOS)
Журнали збоїв і дані про продуктивність

3. Як ми використовуємо вашу інформацію
Ми використовуємо зібрану інформацію для таких цілей:
Щоб надавати послуги: порівнювати ваші списки «Підписувачі» та «Підписки» локально на вашому пристрої, щоб ідентифікувати тих, хто не підписався, нових підписників і шанувальників.
Щоб підтримувати програму: використовувати Firebase Remote Config для керування оновленнями програми, режимами обслуговування та перемиканням функцій.
Розміщувати рекламу: відображати релевантну рекламу через Google AdMob, що дозволяє використовувати цю програму безкоштовно.

4. Послуги третіх сторін і обмін даними
Ми не продаємо ваші особисті дані. Однак ми використовуємо надійні сторонні служби, які можуть збирати інформацію, яка використовується для ідентифікації вашого пристрою в рекламних і аналітичних цілях. Радимо ознайомитися з політикою конфіденційності цих сторонніх постачальників послуг:
Google AdMob: Політика конфіденційності
Google Firebase: Політика конфіденційності

5. Зберігання та видалення даних
Локальні дані: оскільки дані ваших підписників і файли cookie сеансу зберігаються локально на вашому пристрої, ви маєте повний контроль.
Видалення. Ви можете будь-коли видалити всі дані, які зберігає Додаток, виконавши:
Вихід через налаштування програми.
Очищення «Пам’яті/кешу» програми в налаштуваннях телефону.
Видалення програми. Після видалення у нас не залишиться жодних слідів ваших даних.

6. Безпека
Ваша безпека важлива для нас. Ми захищаємо дані на вашому пристрої стандартним шифруванням і методами безпечного зберігання та постійно вдосконалюємо цей захист.

7. Конфіденційність дітей
Наші Послуги не спрямовані на осіб віком до 13 років. Ми свідомо не збираємо особисту інформацію дітей віком до 13 років.

8. Зміни до цієї Політики конфіденційності
Час від часу ми можемо оновлювати нашу Політику конфіденційності. Ми повідомимо вас про будь-які зміни, опублікувавши нову Політику конфіденційності на цій сторінці. Ці зміни набувають чинності відразу після їх публікації.

9. Зв'яжіться з нами
Якщо у вас є будь-які запитання чи пропозиції, не соромтеся звертатися до нас.''',
};

const Map<String, String> _humanizedPrivacyPolicyBodies = {
  'tr': '''VERDICT İÇİN GİZLİLİK POLİTİKASI

VERDICT'i kullandığınız için teşekkür ederiz. Bu metin, uygulamayı kullanırken bilgilerinizin nasıl işlendiğini sade bir dille açıklar. Aklınıza takılan bir nokta olursa dilediğiniz zaman bize ulaşabilirsiniz.

1. VERDICT ve Instagram ilişkisi
VERDICT bağımsız bir üçüncü taraf uygulamasıdır. Instagram, Facebook veya Meta Platforms, Inc. ile resmi bir ortaklığı yoktur. "Instagram", Meta Platforms, Inc. şirketinin ticari markasıdır.

2. Hizmeti sunmak için işlediğimiz bilgiler
Uygulama, gizlilik önceliğiyle ve cihaz içi çalışma mantığıyla tasarlanmıştır. Analizlerin büyük bölümü telefonunuzda yerel olarak yapılır.
A. Giriş oturumu (kimlik doğrulama): Takipçi analizini çalıştırabilmek için Instagram hesabınıza, Instagram'ın resmi giriş ekranı üzerinden giriş yaparsınız.
Erişimimiz: Şifrenizi görmeyiz ve saklamayız. Oturum çerezleri ve kimlik doğrulama belirteçleri yalnızca cihazınızdaki güvenli yerel alanda tutulur (ör. Android SharedPreferences, iOS Keychain).
Sunucu yaklaşımımız: Şifreniz veya takipçi listeleriniz bize ait harici bir sunucuya yüklenmez.
B. Sınırlı cihaz/kullanım verileri: Google AdMob ve Firebase gibi hizmet ortaklarımız, uygulamanın stabil çalışması ve uygun reklamların gösterilmesi için sınırlı teknik verileri işleyebilir (cihaz modeli, işletim sistemi sürümü, ağ türü, reklam kimliği, çökme/performance kayıtları).

3. Bu bilgileri neden kullanıyoruz
Takipçi analiz özelliklerini sunmak, uygulamayı güncel tutmak (bakım, güncelleme, özellik geçişleri) ve uygulamanın ücretsiz kalabilmesi için reklam gösterebilmek.

4. Üçüncü taraf hizmetleri
Kişisel verilerinizi satmayız. Reklam ve analiz altyapısı için güvenilir üçüncü taraf hizmetleri kullanırız:
Google AdMob: Gizlilik Politikası
Google Firebase: Gizlilik Politikası

5. Kontrol sizde ve silme seçenekleri
Oturum ve analiz verileri cihazınızda tutulduğu için kontrol sizdedir.
İsterseniz istediğiniz an çıkış yaparak, uygulama depolamasını/önbelleğini temizleyerek veya uygulamayı kaldırarak verileri silebilirsiniz.

6. Güvenlik
Cihazınızdaki verileri korumak için standart güvenlik yöntemleri kullanıyor ve korumaları düzenli olarak geliştiriyoruz.

7. Çocukların gizliliği
VERDICT, 13 yaş altı çocuklara yönelik değildir. 13 yaş altındaki çocuklardan bilerek kişisel veri toplamıyoruz.

8. Politika güncellemeleri
Bu politikayı zaman zaman güncelleyebiliriz. Güncel sürümü bu sayfada yayınlarız.

9. İletişim
Sorularınız veya önerileriniz için bizimle iletişime geçebilirsiniz.''',
  'en': '''PRIVACY POLICY FOR VERDICT

Thank you for using VERDICT. This policy explains, in plain language, how data is handled when you use the app. If anything is unclear, you can contact us anytime.

1. VERDICT and Instagram relationship
VERDICT is an independent third-party app. It is not affiliated with, sponsored by, or managed by Instagram, Facebook, or Meta Platforms, Inc. "Instagram" is a trademark of Meta Platforms, Inc.

2. Data we process to provide the service
VERDICT is designed with privacy-first, on-device processing in mind. Most analysis runs locally on your phone.
A. Login session (authentication): To run follower analysis, you log in through Instagram's official login page inside a secure WebView.
Our access: We do not see or store your password. Session cookies and auth tokens stay in secure local storage on your device (e.g., Android SharedPreferences, iOS Keychain).
Server approach: We do not upload your password or follower lists to servers we own.
B. Limited device and usage data: Our service partners (Google AdMob and Firebase) may process limited technical identifiers (device model, OS version, network type, ad ID, crash/performance logs) to keep the app stable and show relevant ads.

3. Why this data is used
To provide follower analysis features, maintain the app (updates, maintenance mode, feature flags), and support free usage through ads.

4. Third-party services
We do not sell personal data. We use trusted third-party services for ads and analytics:
Google AdMob: Privacy Policy
Google Firebase: Privacy Policy

5. Your control and deletion options
Because session and analysis data are stored locally, you remain in control.
You can delete data anytime by logging out, clearing app storage/cache, or uninstalling the app.

6. Security
We apply standard security practices to protect local data on your device and continue improving these safeguards.

7. Children
VERDICT is not intended for children under 13. We do not knowingly collect personal data from children under 13.

8. Policy updates
We may update this policy from time to time. The latest version will be published on this page.

9. Contact
If you have questions or suggestions, please contact us.''',
  'de': '''DATENSCHUTZHINWEIS FUR VERDICT

Danke, dass Sie VERDICT nutzen. Dieser Hinweis erklart in klarer Sprache, wie Daten bei der Nutzung der App verarbeitet werden. Wenn etwas unklar ist, konnen Sie uns jederzeit kontaktieren.

1. Beziehung zwischen VERDICT und Instagram
VERDICT ist eine unabhangige Drittanbieter-App. Es besteht keine offizielle Verbindung, Partnerschaft oder Verwaltung durch Instagram, Facebook oder Meta Platforms, Inc. "Instagram" ist eine Marke von Meta Platforms, Inc.

2. Datenverarbeitung fur den Service
VERDICT ist privacy-first aufgebaut; die meisten Analysen laufen lokal auf Ihrem Gerat.
A. Login-Sitzung (Authentifizierung): Fur die Follower-Analyse melden Sie sich uber die offizielle Instagram-Loginseite in einer sicheren WebView an.
Unser Zugriff: Wir sehen oder speichern Ihr Passwort nicht. Sitzungs-Cookies und Tokens bleiben in der lokalen sicheren Speicherung Ihres Gerats (z. B. Android SharedPreferences, iOS Keychain).
Serveransatz: Passworter und Follower-Listen werden nicht auf eigene externe Server hochgeladen.
B. Begrenzte Gerate- und Nutzungsdaten: Google AdMob und Firebase konnen begrenzte technische Daten verarbeiten (Geratemodell, Betriebssystem, Netzwerktyp, Werbe-ID, Absturz-/Leistungsprotokolle), um Stabilitat und relevante Werbung zu ermoglichen.

3. Zweck der Nutzung
Zur Bereitstellung der Analysefunktionen, zur App-Wartung (Updates, Wartungsmodus, Feature-Schalter) und zur Finanzierung der kostenlosen Nutzung uber Werbung.

4. Drittanbieter-Dienste
Wir verkaufen keine personenbezogenen Daten. Fur Werbung und Analysen nutzen wir vertrauenswurdige Drittanbieter:
Google AdMob: Datenschutzerklarung
Google Firebase: Datenschutzerklarung

5. Ihre Kontrolle und Loschung
Da Sitzungs- und Analysedaten lokal gespeichert werden, behalten Sie die Kontrolle.
Sie konnen Daten jederzeit loschen: abmelden, App-Speicher/Cache leeren oder App deinstallieren.

6. Sicherheit
Wir verwenden etablierte Sicherheitsverfahren zum Schutz lokaler Daten und verbessern diese SchutzmaBnahmen fortlaufend.

7. Kinder
VERDICT richtet sich nicht an Kinder unter 13 Jahren. Wir erfassen wissentlich keine personenbezogenen Daten von Kindern unter 13.

8. Aktualisierungen
Diese Richtlinie kann gelegentlich aktualisiert werden. Die aktuelle Version finden Sie auf dieser Seite.

9. Kontakt
Bei Fragen oder Vorschlagen konnen Sie uns gerne kontaktieren.''',
  'ko': '''VERDICT 개인정보 처리방침

VERDICT를 이용해 주셔서 감사합니다. 이 문서는 앱 이용 중 데이터가 어떻게 처리되는지 이해하기 쉽게 안내합니다. 궁금한 점이 있으면 언제든지 문의해 주세요.

1. VERDICT와 Instagram의 관계
VERDICT는 독립적인 제3자 앱입니다. Instagram, Facebook, Meta Platforms, Inc.와 공식 제휴 또는 운영 관계가 없습니다. "Instagram"은 Meta Platforms, Inc.의 상표입니다.

2. 서비스 제공을 위해 처리되는 정보
VERDICT는 개인정보 보호를 우선으로 하며, 대부분의 분석은 기기 내에서 로컬로 처리됩니다.
A. 로그인 세션(인증): 팔로워 분석을 위해 보안 WebView 내 Instagram 공식 로그인 페이지에서 로그인합니다.
접근 범위: 비밀번호는 확인하거나 저장하지 않습니다. 세션 쿠키와 인증 토큰은 기기의 안전한 로컬 저장소(Android SharedPreferences, iOS Keychain 등)에 보관됩니다.
서버 정책: 비밀번호나 팔로워 목록을 당사 소유 외부 서버로 업로드하지 않습니다.
B. 제한된 기기/사용 정보: Google AdMob, Firebase는 앱 안정화와 관련 광고 제공을 위해 제한된 기술 정보를 처리할 수 있습니다(기기 모델, OS 버전, 네트워크 유형, 광고 ID, 충돌/성능 로그).

3. 정보 사용 목적
팔로워 분석 기능 제공, 앱 유지관리(업데이트/점검/기능 토글), 무료 서비스 유지를 위한 광고 운영.

4. 제3자 서비스
개인정보를 판매하지 않습니다. 광고와 분석을 위해 신뢰할 수 있는 제3자 서비스를 사용합니다.
Google AdMob: 개인정보처리방침
Google Firebase: 개인정보처리방침

5. 사용자 제어 및 삭제
세션/분석 데이터는 로컬에 저장되므로 사용자가 직접 제어할 수 있습니다.
로그아웃, 앱 저장공간/캐시 삭제, 앱 삭제를 통해 언제든 데이터 삭제가 가능합니다.

6. 보안
기기 내 데이터 보호를 위해 표준 보안 방식을 적용하며, 보호 수준을 지속적으로 개선합니다.

7. 아동 개인정보
VERDICT는 만 13세 미만 아동을 대상으로 하지 않으며, 해당 연령 아동의 개인정보를 고의로 수집하지 않습니다.

8. 정책 변경
본 정책은 필요 시 업데이트될 수 있으며, 최신 버전은 이 페이지에 게시됩니다.

9. 문의
질문이나 제안이 있으면 언제든지 연락해 주세요.''',
  'ja': '''VERDICT プライバシーポリシー

VERDICTをご利用いただきありがとうございます。このポリシーは、アプリ利用時のデータの扱いを分かりやすく説明するものです。ご不明点があれば、いつでもお問い合わせください。

1. VERDICTとInstagramの関係
VERDICTは独立した第三者アプリです。Instagram、Facebook、Meta Platforms, Inc.とは公式な提携・後援・運営関係はありません。"Instagram"はMeta Platforms, Inc.の商標です。

2. サービス提供のために扱う情報
VERDICTはプライバシーを重視し、分析の大半は端末内でローカル処理されます。
A. ログインセッション（認証）: フォロワー分析のため、アプリ内の安全なWebViewでInstagram公式ログインページにログインします。
当社のアクセス範囲: パスワードを閲覧・保存しません。セッションクッキーと認証トークンは端末内の安全なローカル保存領域（Android SharedPreferences、iOS Keychainなど）に保存されます。
サーバー方針: パスワードやフォロワー一覧を当社所有の外部サーバーへアップロードしません。
B. 限定的な端末・利用情報: Google AdMobとFirebaseは、安定動作と適切な広告表示のために限定的な技術情報（端末モデル、OSバージョン、ネットワーク種別、広告ID、クラッシュ/性能ログ）を処理する場合があります。

3. 情報の利用目的
フォロワー分析機能の提供、アプリ運用（更新・メンテナンス・機能切替）、無料提供を支える広告表示のために利用します。

4. 外部サービス
個人データを販売することはありません。広告・分析のため信頼できる第三者サービスを利用します。
Google AdMob: プライバシーポリシー
Google Firebase: プライバシーポリシー

5. ユーザーによる管理と削除
セッション・分析データは端末ローカルに保存されるため、管理権限はユーザーにあります。
ログアウト、アプリの保存領域/キャッシュ削除、アンインストールでいつでも削除できます。

6. セキュリティ
端末内データを守るため標準的なセキュリティ対策を実施し、継続的に改善します。

7. 子どものプライバシー
VERDICTは13歳未満を対象としていません。13歳未満の個人データを故意に収集しません。

8. ポリシーの更新
本ポリシーは随時更新される場合があります。最新版はこのページに掲載します。

9. お問い合わせ
ご質問・ご提案があれば、お気軽にご連絡ください。''',
  'ru': '''ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ VERDICT

Спасибо, что используете VERDICT. В этом тексте простым языком объясняется, как обрабатываются данные при работе с приложением. Если что-то непонятно, вы всегда можете связаться с нами.

1. Отношения VERDICT и Instagram
VERDICT - независимое стороннее приложение. Оно не связано официально с Instagram, Facebook или Meta Platforms, Inc. и не управляется ими. "Instagram" является товарным знаком Meta Platforms, Inc.

2. Какие данные обрабатываются для работы сервиса
VERDICT спроектирован с приоритетом приватности: большая часть анализа выполняется локально на вашем устройстве.
A. Сеанс входа (аутентификация): для анализа подписчиков вы входите через официальную страницу входа Instagram во встроенном защищенном WebView.
Наш доступ: мы не видим и не храним ваш пароль. Сессионные cookie и токены сохраняются только в защищенном локальном хранилище устройства (например, Android SharedPreferences, iOS Keychain).
Серверный подход: ваш пароль и списки подписчиков не загружаются на внешние серверы, принадлежащие нам.
B. Ограниченные данные устройства/использования: Google AdMob и Firebase могут обрабатывать ограниченные технические данные (модель устройства, версия ОС, тип сети, рекламный ID, логи сбоев/производительности) для стабильной работы приложения и релевантной рекламы.

3. Для чего используются данные
Для работы функций анализа, поддержки приложения (обновления, режим обслуживания, переключатели функций) и показа рекламы, чтобы приложение оставалось бесплатным.

4. Сторонние сервисы
Мы не продаем персональные данные. Для рекламы и аналитики используем надежные сторонние сервисы:
Google AdMob: Политика конфиденциальности
Google Firebase: Политика конфиденциальности

5. Контроль и удаление
Поскольку данные сеанса и анализа хранятся локально, контроль остается у вас.
Вы можете удалить данные в любой момент: выйти из аккаунта, очистить хранилище/кэш приложения или удалить приложение.

6. Безопасность
Мы применяем стандартные меры безопасности для защиты локальных данных на устройстве и регулярно усиливаем защиту.

7. Дети
VERDICT не предназначен для детей младше 13 лет. Мы не собираем персональные данные детей младше 13 лет намеренно.

8. Обновления политики
Мы можем периодически обновлять политику. Актуальная версия публикуется на этой странице.

9. Контакты
Если у вас есть вопросы или предложения, свяжитесь с нами.''',
  'pt': '''POLITICA DE PRIVACIDADE DO VERDICT

Obrigado por usar o VERDICT. Este texto explica, de forma clara, como os dados sao tratados durante o uso do app. Se algo nao estiver claro, voce pode falar com a gente a qualquer momento.

1. Relacao entre VERDICT e Instagram
O VERDICT e um app independente de terceiro. Nao possui afiliacao oficial, patrocinio ou administracao por Instagram, Facebook ou Meta Platforms, Inc. "Instagram" e marca registrada da Meta Platforms, Inc.

2. Dados tratados para prestar o servico
O VERDICT foi pensado com foco em privacidade e processamento no proprio dispositivo. A maior parte das analises roda localmente no seu telefone.
A. Sessao de login (autenticacao): para executar a analise de seguidores, voce entra pela pagina oficial de login do Instagram em um WebView seguro.
Nosso acesso: nao vemos nem armazenamos sua senha. Cookies de sessao e tokens de autenticacao ficam apenas no armazenamento local seguro do aparelho (ex.: Android SharedPreferences, iOS Keychain).
Abordagem de servidor: sua senha e suas listas de seguidores nao sao enviadas para servidores externos nossos.
B. Dados limitados de dispositivo/uso: Google AdMob e Firebase podem processar dados tecnicos limitados (modelo do aparelho, versao do sistema, tipo de rede, ID de publicidade, logs de falha/desempenho) para manter estabilidade e exibir anuncios relevantes.

3. Por que usamos esses dados
Para oferecer os recursos de analise, manter o app (atualizacoes, manutencao, ativacao de recursos) e sustentar a versao gratuita por meio de anuncios.

4. Servicos de terceiros
Nao vendemos dados pessoais. Utilizamos servicos confiaveis de terceiros para anuncios e analise:
Google AdMob: Politica de Privacidade
Google Firebase: Politica de Privacidade

5. Seu controle e exclusao
Como os dados de sessao e analise ficam no dispositivo, o controle permanece com voce.
Voce pode apagar os dados quando quiser: sair da conta, limpar armazenamento/cache do app ou desinstalar o app.

6. Seguranca
Aplicamos praticas padrao de seguranca para proteger dados locais no dispositivo e melhoramos continuamente essas medidas.

7. Criancas
O VERDICT nao e destinado a menores de 13 anos. Nao coletamos intencionalmente dados pessoais de criancas menores de 13 anos.

8. Atualizacoes desta politica
Podemos atualizar esta politica ocasionalmente. A versao mais recente sera publicada nesta pagina.

9. Contato
Se tiver duvidas ou sugestoes, entre em contato conosco.''',
  'ar': '''سياسة الخصوصية لتطبيق VERDICT

شكرًا لاستخدامك VERDICT. يوضح هذا النص بطريقة بسيطة كيف يتم التعامل مع البيانات عند استخدام التطبيق. إذا كان هناك أي جزء غير واضح، يمكنك التواصل معنا في أي وقت.

1. العلاقة بين VERDICT وInstagram
VERDICT تطبيق مستقل من طرف ثالث. لا توجد شراكة رسمية أو إدارة من Instagram أو Facebook أو Meta Platforms, Inc. علامة "Instagram" هي علامة تجارية لشركة Meta Platforms, Inc.

2. البيانات التي نعالجها لتقديم الخدمة
تم تصميم VERDICT مع أولوية للخصوصية ومعالجة على الجهاز. معظم التحليل يتم محليًا على هاتفك.
A. جلسة تسجيل الدخول (المصادقة): لتشغيل تحليل المتابعين، تقوم بتسجيل الدخول عبر صفحة Instagram الرسمية داخل WebView آمن.
نطاق وصولنا: نحن لا نرى كلمة المرور ولا نخزنها. ملفات تعريف الارتباط الخاصة بالجلسة ورموز المصادقة تبقى في التخزين المحلي الآمن على جهازك (مثل Android SharedPreferences وiOS Keychain).
نهج الخادم: لا يتم رفع كلمة المرور أو قوائم المتابعين إلى خوادم خارجية نملكها.
B. بيانات تقنية محدودة: قد يعالج Google AdMob وFirebase بيانات تقنية محدودة (طراز الجهاز، إصدار النظام، نوع الشبكة، معرف الإعلانات، سجلات الأعطال/الأداء) لتحسين الاستقرار وعرض إعلانات مناسبة.

3. لماذا نستخدم هذه البيانات
لتقديم ميزات التحليل، وصيانة التطبيق (التحديثات، وضع الصيانة، تفعيل الميزات)، ودعم النسخة المجانية عبر الإعلانات.

4. خدمات الطرف الثالث
نحن لا نبيع البيانات الشخصية. نستخدم خدمات موثوقة من طرف ثالث للإعلانات والتحليلات:
Google AdMob: سياسة الخصوصية
Google Firebase: سياسة الخصوصية

5. التحكم والحذف
لأن بيانات الجلسة والتحليل مخزنة محليًا، يبقى التحكم بيدك.
يمكنك حذف البيانات في أي وقت عبر تسجيل الخروج أو مسح تخزين/ذاكرة التخزين المؤقت للتطبيق أو إزالة التطبيق.

6. الأمان
نطبق ممارسات أمان قياسية لحماية البيانات المحلية على جهازك، ونواصل تحسين إجراءات الحماية.

7. خصوصية الأطفال
VERDICT غير مخصص للأطفال دون 13 عامًا. لا نجمع عمدًا بيانات شخصية من الأطفال دون 13 عامًا.

8. تحديثات السياسة
قد نقوم بتحديث هذه السياسة من وقت لآخر، وسيتم نشر النسخة الأحدث على هذه الصفحة.

9. التواصل
إذا كان لديك أي سؤال أو اقتراح، يسعدنا تواصلك معنا.''',
  'es': '''POLITICA DE PRIVACIDAD DE VERDICT

Gracias por usar VERDICT. Este texto explica, de forma clara, como se tratan los datos cuando usas la app. Si algo no queda claro, puedes contactarnos en cualquier momento.

1. Relacion entre VERDICT e Instagram
VERDICT es una app independiente de terceros. No tiene afiliacion oficial, patrocinio ni gestion por parte de Instagram, Facebook o Meta Platforms, Inc. "Instagram" es una marca registrada de Meta Platforms, Inc.

2. Datos que tratamos para prestar el servicio
VERDICT esta disenada con enfoque de privacidad y procesamiento en el dispositivo. La mayor parte del analisis se realiza localmente en tu telefono.
A. Sesion de inicio (autenticacion): para ejecutar el analisis de seguidores, inicias sesion en la pagina oficial de Instagram dentro de un WebView seguro.
Nuestro acceso: no vemos ni almacenamos tu contrasena. Las cookies de sesion y los tokens de autenticacion se guardan solo en el almacenamiento local seguro del dispositivo (p. ej., Android SharedPreferences, iOS Keychain).
Enfoque de servidor: tu contrasena y tus listas de seguidores no se suben a servidores externos de nuestra propiedad.
B. Datos limitados de dispositivo/uso: Google AdMob y Firebase pueden tratar datos tecnicos limitados (modelo del dispositivo, version del sistema, tipo de red, ID de publicidad, registros de fallos/rendimiento) para mantener la app estable y mostrar anuncios relevantes.

3. Para que usamos estos datos
Para ofrecer las funciones de analisis, mantener la app (actualizaciones, modo mantenimiento, activacion de funciones) y sostener el uso gratuito mediante anuncios.

4. Servicios de terceros
No vendemos datos personales. Usamos servicios de terceros confiables para anuncios y analitica:
Google AdMob: Politica de privacidad
Google Firebase: Politica de privacidad

5. Tu control y eliminacion
Como los datos de sesion y analisis se almacenan localmente, el control sigue siendo tuyo.
Puedes eliminar los datos en cualquier momento cerrando sesion, limpiando almacenamiento/cache o desinstalando la app.

6. Seguridad
Aplicamos practicas de seguridad estandar para proteger los datos locales en tu dispositivo y mejoramos estas medidas de forma continua.

7. Menores
VERDICT no esta dirigida a menores de 13 anos. No recopilamos intencionalmente datos personales de menores de 13 anos.

8. Cambios en esta politica
Podemos actualizar esta politica ocasionalmente. La version vigente se publicara en esta pagina.

9. Contacto
Si tienes preguntas o sugerencias, puedes escribirnos.''',
  'es-mx': '''POLITICA DE PRIVACIDAD DE VERDICT

Gracias por usar VERDICT. Este texto explica, de manera clara, como tratamos los datos cuando usas la app. Si algo no queda claro, puedes contactarnos en cualquier momento.

1. Relacion entre VERDICT e Instagram
VERDICT es una app independiente de terceros. No tiene afiliacion oficial, patrocinio ni administracion por parte de Instagram, Facebook o Meta Platforms, Inc. "Instagram" es una marca registrada de Meta Platforms, Inc.

2. Datos que tratamos para brindar el servicio
VERDICT esta disenada con enfoque de privacidad y procesamiento en el dispositivo. La mayor parte del analisis se realiza localmente en tu telefono.
A. Sesion de inicio (autenticacion): para ejecutar el analisis de seguidores, inicias sesion en la pagina oficial de Instagram dentro de un WebView seguro.
Nuestro acceso: no vemos ni almacenamos tu contrasena. Las cookies de sesion y los tokens de autenticacion se guardan solo en el almacenamiento local seguro del dispositivo (por ejemplo, Android SharedPreferences, iOS Keychain).
Enfoque de servidor: tu contrasena y tus listas de seguidores no se suben a servidores externos de nuestra propiedad.
B. Datos limitados de dispositivo/uso: Google AdMob y Firebase pueden tratar datos tecnicos limitados (modelo del dispositivo, version del sistema, tipo de red, ID de publicidad, registros de fallas/rendimiento) para mantener la app estable y mostrar anuncios relevantes.

3. Para que usamos estos datos
Para ofrecer funciones de analisis, mantener la app (actualizaciones, modo mantenimiento, activacion de funciones) y sostener el uso gratuito mediante anuncios.

4. Servicios de terceros
No vendemos datos personales. Usamos servicios confiables de terceros para anuncios y analitica:
Google AdMob: Politica de privacidad
Google Firebase: Politica de privacidad

5. Tu control y eliminacion
Como los datos de sesion y analisis se almacenan localmente, el control sigue siendo tuyo.
Puedes eliminar datos en cualquier momento cerrando sesion, limpiando almacenamiento/cache o desinstalando la app.

6. Seguridad
Aplicamos practicas de seguridad estandar para proteger los datos locales en tu dispositivo y mejoramos estas medidas de forma continua.

7. Menores
VERDICT no esta dirigida a menores de 13 anos. No recopilamos intencionalmente datos personales de menores de 13 anos.

8. Cambios en esta politica
Podemos actualizar esta politica ocasionalmente. La version vigente se publicara en esta pagina.

9. Contacto
Si tienes dudas o sugerencias, puedes escribirnos.''',
  'hi': '''VERDICT की गोपनीयता नीति

VERDICT का उपयोग करने के लिए धन्यवाद। यह नीति सरल भाषा में बताती है कि ऐप इस्तेमाल करते समय जानकारी कैसे संभाली जाती है। अगर कोई बात स्पष्ट न हो, तो आप कभी भी हमसे संपर्क कर सकते हैं।

1. VERDICT और Instagram का संबंध
VERDICT एक स्वतंत्र थर्ड-पार्टी ऐप है। इसका Instagram, Facebook या Meta Platforms, Inc. के साथ कोई आधिकारिक साझेदारी या प्रबंधन संबंध नहीं है। "Instagram" Meta Platforms, Inc. का ट्रेडमार्क है।

2. सेवा देने के लिए हम कौन-सी जानकारी प्रोसेस करते हैं
VERDICT को प्राइवेसी-फर्स्ट और ऑन-डिवाइस प्रोसेसिंग के साथ डिजाइन किया गया है। ज्यादातर विश्लेषण आपके फोन पर लोकली होता है।
A. लॉगिन सेशन (प्रमाणीकरण): फॉलोअर विश्लेषण के लिए आप सुरक्षित WebView में Instagram के आधिकारिक लॉगिन पेज से साइन इन करते हैं।
हमारी पहुंच: हम आपका पासवर्ड न देखते हैं, न स्टोर करते हैं। सेशन कुकी और ऑथ टोकन केवल आपके डिवाइस के सुरक्षित लोकल स्टोरेज (जैसे Android SharedPreferences, iOS Keychain) में रहते हैं।
सर्वर नीति: आपका पासवर्ड या फॉलोअर सूची हमारे किसी बाहरी सर्वर पर अपलोड नहीं की जाती।
B. सीमित डिवाइस/उपयोग डेटा: Google AdMob और Firebase ऐप स्थिर रखने और प्रासंगिक विज्ञापन दिखाने के लिए सीमित तकनीकी डेटा प्रोसेस कर सकते हैं (डिवाइस मॉडल, OS वर्जन, नेटवर्क प्रकार, विज्ञापन ID, क्रैश/परफॉर्मेंस लॉग)।

3. यह डेटा क्यों उपयोग होता है
विश्लेषण सुविधाएं उपलब्ध कराने, ऐप रखरखाव (अपडेट, मेंटेनेंस मोड, फीचर टॉगल) और ऐप को मुफ्त रखने के लिए विज्ञापन दिखाने हेतु।

4. तृतीय-पक्ष सेवाएं
हम व्यक्तिगत डेटा नहीं बेचते। विज्ञापन और एनालिटिक्स के लिए भरोसेमंद तृतीय-पक्ष सेवाओं का उपयोग करते हैं:
Google AdMob: Privacy Policy
Google Firebase: Privacy Policy

5. आपका नियंत्रण और डेटा हटाना
सेशन और विश्लेषण डेटा लोकली स्टोर होने के कारण नियंत्रण आपके पास रहता है।
आप कभी भी लॉगआउट करके, ऐप स्टोरेज/कैश साफ करके या ऐप अनइंस्टॉल करके डेटा हटा सकते हैं।

6. सुरक्षा
हम आपके डिवाइस पर लोकल डेटा की सुरक्षा के लिए मानक सुरक्षा उपाय अपनाते हैं और इन्हें लगातार बेहतर बनाते रहते हैं।

7. बच्चों की गोपनीयता
VERDICT 13 वर्ष से कम आयु के बच्चों के लिए नहीं है। हम 13 वर्ष से कम आयु के बच्चों का व्यक्तिगत डेटा जानबूझकर एकत्र नहीं करते।

8. नीति में बदलाव
हम समय-समय पर इस नीति को अपडेट कर सकते हैं। नवीनतम संस्करण इसी पेज पर प्रकाशित किया जाएगा।

9. संपर्क
यदि आपके पास कोई प्रश्न या सुझाव है, तो कृपया हमसे संपर्क करें।''',
  'hu': '''VERDICT ADATVEDELMI TAJEKOZTATO

Koszonjuk, hogy a VERDICT-et hasznalod. Ez a tajekoztato kozerhetoen leirja, hogyan kezeljuk az adatokat az alkalmazas hasznalata kozben. Ha barmi nem egyertelmu, barmikor kapcsolatba lephetsz velunk.

1. VERDICT es Instagram kapcsolata
A VERDICT egy fuggetlen, harmadik feltol szarmazo alkalmazas. Nem all hivatalos kapcsolatban az Instagrammal, a Facebookkal vagy a Meta Platforms, Inc.-szel, es nem is ezek kezelik. Az "Instagram" a Meta Platforms, Inc. vedjegye.

2. A szolgaltatashoz kezelt adatok
A VERDICT privacy-first szemlelettel keszult, az elemzesek nagy resze helyben, a keszulekeden fut.
A. Bejelentkezesi munkamenet (hitelesites): a kovetoelemzeshez az Instagram hivatalos bejelentkezesi oldalan jelentkezel be egy biztonsagos WebView-n keresztul.
Hozzaferesunk: a jelszavadat nem latjuk es nem taroljuk. A munkamenet-cookie-k es hitelesitesi tokenek kizarolag a keszulek biztonsagos helyi tarhelyen maradnak (pl. Android SharedPreferences, iOS Keychain).
Szerverelv: a jelszo es a kovetolistak nem kerulnek altalunk uzemeltetett kulso szerverre.
B. Korlatozott eszkoz- es hasznalati adatok: a Google AdMob es a Firebase korlatozott technikai adatokat dolgozhat fel (eszkozmodell, operacios rendszer verzio, halozattipus, hirdetesi azonosito, osszeomlasi/teljesitmeny naplok) a stabil mukodes es relevans hirdetesek erdekeben.

3. Miert hasznaljuk ezeket az adatokat
Az elemzesi funkciok biztositasahoz, az alkalmazas fenntartasahoz (frissitesek, karbantartas, funkciokapcsolok), valamint a reklamokkal tamogatott ingyenes hasznalathoz.

4. Harmadik fel szolgaltatasai
Szemelyes adatot nem ertekesitunk. Hirdeteshez es analitikahoz megbizhato harmadik feleket hasznalunk:
Google AdMob: Adatvedelmi tajekoztato
Google Firebase: Adatvedelmi tajekoztato

5. Te iranyitasz, es torolhetsz
Mivel a munkamenet- es elemzesi adatok helyben maradnak, az iranyitas nalad van.
Az adatok barmikor torolhetok kijelentkezessel, az alkalmazas tarhelyenek/gyorsitotaranak torlesevel vagy az app eltavolitasaval.

6. Biztonsag
Szabvanyos biztonsagi gyakorlatokat alkalmazunk a helyi adatok vedelmere, es folyamatosan fejlesztjuk a vedelmet.

7. Gyermekek adatvedelme
A VERDICT nem 13 ev alatti gyermekeknek keszult. 13 ev alattiaktol nem gyujtunk tudatosan szemelyes adatot.

8. Frissitesek
Ezt a tajekoztatot idorol idore frissithetjuk. Az aktualis verzio ezen az oldalon lesz elerheto.

9. Kapcsolat
Kerdes vagy javaslat eseten lepj kapcsolatba velunk.''',
  'zh-hans': '''VERDICT 隐私政策

感谢你使用 VERDICT。本政策会用简明语言说明在使用应用时我们如何处理数据。如有任何不清楚的地方，欢迎随时联系我们。

1. VERDICT 与 Instagram 的关系
VERDICT 是独立的第三方应用，不隶属于、也不由 Instagram、Facebook 或 Meta Platforms, Inc. 赞助或管理。"Instagram" 是 Meta Platforms, Inc. 的商标。

2. 为提供服务而处理的数据
VERDICT 以隐私优先和本地处理为设计原则，大部分分析都在你的设备上完成。
A. 登录会话（认证）：进行粉丝分析时，你会在安全 WebView 中通过 Instagram 官方登录页面登录。
我们的访问范围：我们不会查看或保存你的密码。会话 Cookie 和认证令牌仅保存在你设备的安全本地存储中（例如 Android SharedPreferences、iOS Keychain）。
服务器策略：你的密码和粉丝列表不会上传到我们拥有的外部服务器。
B. 限定的设备/使用数据：Google AdMob 和 Firebase 可能会处理少量技术信息（设备型号、系统版本、网络类型、广告 ID、崩溃/性能日志），用于保持应用稳定并展示更相关的广告。

3. 数据用途
用于提供分析功能、维护应用（更新、维护模式、功能开关），以及通过广告支持应用免费使用。

4. 第三方服务
我们不会出售个人数据。我们会使用可信的第三方服务进行广告和分析：
Google AdMob: 隐私政策
Google Firebase: 隐私政策

5. 你的控制权与删除方式
由于会话和分析数据保存在本地设备上，控制权始终在你手中。
你可以随时通过退出登录、清理应用存储/缓存或卸载应用来删除数据。

6. 安全
我们采用标准安全措施保护你设备上的本地数据，并持续改进这些防护。

7. 儿童隐私
VERDICT 不面向 13 岁以下儿童。我们不会故意收集 13 岁以下儿童的个人数据。

8. 政策更新
我们可能会不定期更新本政策，最新版本会发布在本页面。

9. 联系我们
如果你有任何问题或建议，欢迎联系我们。''',
  'id': '''KEBIJAKAN PRIVASI VERDICT

Terima kasih telah menggunakan VERDICT. Kebijakan ini menjelaskan dengan bahasa sederhana bagaimana data diproses saat kamu menggunakan aplikasi. Jika ada hal yang belum jelas, kamu bisa menghubungi kami kapan saja.

1. Hubungan VERDICT dengan Instagram
VERDICT adalah aplikasi pihak ketiga yang independen. Aplikasi ini tidak berafiliasi resmi, tidak disponsori, dan tidak dikelola oleh Instagram, Facebook, atau Meta Platforms, Inc. "Instagram" adalah merek dagang Meta Platforms, Inc.

2. Data yang diproses untuk menyediakan layanan
VERDICT dirancang dengan prinsip privacy-first dan pemrosesan di perangkat. Sebagian besar analisis berjalan secara lokal di ponselmu.
A. Sesi login (autentikasi): untuk analisis pengikut, kamu login melalui halaman resmi Instagram di dalam WebView yang aman.
Akses kami: kami tidak melihat atau menyimpan kata sandimu. Cookie sesi dan token autentikasi hanya disimpan di penyimpanan lokal aman pada perangkatmu (misalnya Android SharedPreferences, iOS Keychain).
Kebijakan server: kata sandi dan daftar pengikutmu tidak diunggah ke server eksternal milik kami.
B. Data perangkat/penggunaan terbatas: Google AdMob dan Firebase dapat memproses data teknis terbatas (model perangkat, versi OS, jenis jaringan, ID iklan, log crash/kinerja) untuk menjaga stabilitas aplikasi dan menampilkan iklan yang relevan.

3. Tujuan penggunaan data
Untuk menyediakan fitur analisis, memelihara aplikasi (pembaruan, mode pemeliharaan, pengaturan fitur), serta mendukung penggunaan gratis melalui iklan.

4. Layanan pihak ketiga
Kami tidak menjual data pribadi. Kami menggunakan layanan pihak ketiga tepercaya untuk iklan dan analitik:
Google AdMob: Kebijakan Privasi
Google Firebase: Kebijakan Privasi

5. Kendali pengguna dan penghapusan
Karena data sesi dan analisis disimpan lokal, kendali tetap di tangan kamu.
Kamu bisa menghapus data kapan saja dengan logout, membersihkan penyimpanan/cache aplikasi, atau uninstall aplikasi.

6. Keamanan
Kami menerapkan praktik keamanan standar untuk melindungi data lokal di perangkatmu dan terus meningkatkan perlindungan ini.

7. Privasi anak
VERDICT tidak ditujukan untuk anak di bawah 13 tahun. Kami tidak dengan sengaja mengumpulkan data pribadi anak di bawah 13 tahun.

8. Perubahan kebijakan
Kebijakan ini dapat diperbarui sewaktu-waktu. Versi terbaru akan dipublikasikan di halaman ini.

9. Kontak
Jika kamu punya pertanyaan atau saran, silakan hubungi kami.''',
  'nl': '''PRIVACYBELEID VAN VERDICT

Bedankt dat je VERDICT gebruikt. Dit beleid legt in duidelijke taal uit hoe gegevens worden verwerkt tijdens het gebruik van de app. Als iets niet duidelijk is, kun je altijd contact met ons opnemen.

1. Relatie tussen VERDICT en Instagram
VERDICT is een onafhankelijke app van een derde partij. Er is geen officiele samenwerking met Instagram, Facebook of Meta Platforms, Inc. en de app wordt niet door hen beheerd. "Instagram" is een handelsmerk van Meta Platforms, Inc.

2. Gegevens die we verwerken om de dienst te leveren
VERDICT is ontworpen met privacy-first en verwerking op het apparaat. Het grootste deel van de analyse gebeurt lokaal op je telefoon.
A. Login-sessie (authenticatie): voor volgersanalyse log je in via de officiele Instagram-inlogpagina in een beveiligde WebView.
Onze toegang: we zien of bewaren je wachtwoord niet. Sessiecookies en authenticatietokens blijven in de veilige lokale opslag van je apparaat (bijv. Android SharedPreferences, iOS Keychain).
Serverbeleid: je wachtwoord en volgerslijsten worden niet geupload naar externe servers die van ons zijn.
B. Beperkte apparaat-/gebruiksgegevens: Google AdMob en Firebase kunnen beperkte technische gegevens verwerken (apparaatmodel, OS-versie, netwerktype, advertentie-ID, crash-/prestatie-logs) om de app stabiel te houden en relevante advertenties te tonen.

3. Waarom we deze gegevens gebruiken
Om analysefuncties te bieden, de app te onderhouden (updates, onderhoudsmodus, feature toggles) en gratis gebruik mogelijk te houden via advertenties.

4. Diensten van derden
We verkopen geen persoonsgegevens. We gebruiken vertrouwde diensten van derden voor advertenties en analytics:
Google AdMob: Privacybeleid
Google Firebase: Privacybeleid

5. Jouw controle en verwijdering
Omdat sessie- en analysedata lokaal worden opgeslagen, houd jij de controle.
Je kunt data altijd verwijderen door uit te loggen, appopslag/cache te wissen of de app te verwijderen.

6. Beveiliging
We passen standaard beveiligingsmaatregelen toe om lokale data op je apparaat te beschermen en verbeteren deze maatregelen voortdurend.

7. Kinderen
VERDICT is niet bedoeld voor kinderen jonger dan 13 jaar. We verzamelen niet bewust persoonsgegevens van kinderen onder 13.

8. Updates van dit beleid
We kunnen dit beleid af en toe bijwerken. De meest recente versie publiceren we op deze pagina.

9. Contact
Heb je vragen of suggesties, neem dan gerust contact met ons op.''',
  'fr': '''POLITIQUE DE CONFIDENTIALITE VERDICT

Merci d'utiliser VERDICT. Ce document explique simplement comment les donnees sont traitees pendant l'utilisation de l'application. Si un point n'est pas clair, vous pouvez nous contacter a tout moment.

1. Relation entre VERDICT et Instagram
VERDICT est une application tierce independante. Elle n'est ni affiliee, ni sponsorisee, ni geree par Instagram, Facebook ou Meta Platforms, Inc. "Instagram" est une marque de Meta Platforms, Inc.

2. Donnees traitees pour fournir le service
VERDICT est concu avec une approche privacy-first et un traitement sur l'appareil. La majeure partie de l'analyse est effectuee localement sur votre telephone.
A. Session de connexion (authentification): pour l'analyse des abonnes, vous vous connectez via la page officielle de connexion Instagram dans un WebView securise.
Notre acces: nous ne voyons pas et ne stockons pas votre mot de passe. Les cookies de session et jetons d'authentification restent dans le stockage local securise de votre appareil (ex.: Android SharedPreferences, iOS Keychain).
Approche serveur: votre mot de passe et vos listes d'abonnes ne sont pas televerses vers des serveurs externes que nous possedons.
B. Donnees techniques limitees: Google AdMob et Firebase peuvent traiter des donnees techniques limitees (modele d'appareil, version OS, type de reseau, identifiant publicitaire, journaux de crash/performance) pour maintenir la stabilite et afficher des publicites pertinentes.

3. Pourquoi ces donnees sont utilisees
Pour fournir les fonctions d'analyse, maintenir l'application (mises a jour, mode maintenance, activation de fonctionnalites) et financer l'usage gratuit via la publicite.

4. Services tiers
Nous ne vendons pas de donnees personnelles. Nous utilisons des services tiers fiables pour la publicite et l'analyse:
Google AdMob: Politique de confidentialite
Google Firebase: Politique de confidentialite

5. Votre controle et la suppression
Comme les donnees de session et d'analyse sont stockees localement, vous gardez le controle.
Vous pouvez supprimer vos donnees a tout moment en vous deconnectant, en vidant le stockage/cache de l'app ou en desinstallant l'application.

6. Securite
Nous appliquons des pratiques de securite standard pour proteger les donnees locales sur votre appareil et nous ameliorons ces protections en continu.

7. Donnees des enfants
VERDICT n'est pas destine aux enfants de moins de 13 ans. Nous ne collectons pas volontairement de donnees personnelles concernant des enfants de moins de 13 ans.

8. Mise a jour de la politique
Cette politique peut etre mise a jour ponctuellement. La version la plus recente sera publiee sur cette page.

9. Contact
Pour toute question ou suggestion, contactez-nous.''',
  'it': '''INFORMATIVA SULLA PRIVACY DI VERDICT

Grazie per usare VERDICT. Questo testo spiega in modo semplice come vengono trattati i dati durante l'uso dell'app. Se qualcosa non e chiaro, puoi contattarci in qualsiasi momento.

1. Rapporto tra VERDICT e Instagram
VERDICT e un'app indipendente di terze parti. Non e affiliata, sponsorizzata o gestita da Instagram, Facebook o Meta Platforms, Inc. "Instagram" e un marchio di Meta Platforms, Inc.

2. Dati trattati per fornire il servizio
VERDICT e progettata con approccio privacy-first e elaborazione sul dispositivo. La maggior parte delle analisi avviene localmente sul tuo telefono.
A. Sessione di accesso (autenticazione): per l'analisi follower effettui l'accesso tramite la pagina ufficiale di login Instagram in una WebView sicura.
Il nostro accesso: non vediamo e non memorizziamo la tua password. Cookie di sessione e token di autenticazione restano solo nello spazio locale sicuro del dispositivo (es. Android SharedPreferences, iOS Keychain).
Approccio server: la tua password e le liste follower non vengono caricate su server esterni di nostra proprieta.
B. Dati limitati di dispositivo/uso: Google AdMob e Firebase possono trattare dati tecnici limitati (modello dispositivo, versione OS, tipo rete, ID pubblicitario, log crash/prestazioni) per mantenere stabilita e mostrare annunci pertinenti.

3. Perche usiamo questi dati
Per offrire le funzioni di analisi, mantenere l'app (aggiornamenti, modalita manutenzione, attivazione funzioni) e sostenere la versione gratuita tramite annunci.

4. Servizi di terze parti
Non vendiamo dati personali. Usiamo servizi affidabili di terze parti per pubblicita e analisi:
Google AdMob: Informativa sulla privacy
Google Firebase: Informativa sulla privacy

5. Il tuo controllo e cancellazione
Poiche i dati di sessione e analisi sono salvati localmente, il controllo resta a te.
Puoi eliminare i dati in qualsiasi momento effettuando logout, pulendo storage/cache dell'app o disinstallando l'app.

6. Sicurezza
Applichiamo pratiche standard di sicurezza per proteggere i dati locali sul dispositivo e miglioriamo continuamente queste misure.

7. Privacy dei minori
VERDICT non e destinata a minori di 13 anni. Non raccogliamo consapevolmente dati personali di minori di 13 anni.

8. Aggiornamenti della politica
Possiamo aggiornare questa informativa periodicamente. La versione piu recente verra pubblicata in questa pagina.

9. Contatti
Per domande o suggerimenti, contattaci.''',
  'vi': '''CHINH SACH QUYEN RIENG TU CUA VERDICT

Cam on ban da su dung VERDICT. Tai lieu nay giai thich ro rang cach du lieu duoc xu ly khi ban su dung ung dung. Neu co diem nao chua ro, ban co the lien he voi chung toi bat cu luc nao.

1. Moi quan he giua VERDICT va Instagram
VERDICT la ung dung ben thu ba doc lap. Ung dung khong lien ket chinh thuc, khong duoc tai tro va khong duoc van hanh boi Instagram, Facebook hoac Meta Platforms, Inc. "Instagram" la thuong hieu cua Meta Platforms, Inc.

2. Du lieu duoc xu ly de cung cap dich vu
VERDICT duoc thiet ke theo huong privacy-first va xu ly tren thiet bi. Phan lon phan tich duoc thuc hien cuc bo tren dien thoai cua ban.
A. Phien dang nhap (xac thuc): de chay phan tich nguoi theo doi, ban dang nhap qua trang dang nhap chinh thuc cua Instagram trong WebView an toan.
Pham vi truy cap cua chung toi: chung toi khong xem va khong luu mat khau cua ban. Cookie phien va token xac thuc chi duoc luu trong bo nho cuc bo an toan tren thiet bi (vi du Android SharedPreferences, iOS Keychain).
Chinh sach may chu: mat khau va danh sach nguoi theo doi cua ban khong duoc tai len may chu ben ngoai do chung toi so huu.
B. Du lieu thiet bi/su dung gioi han: Google AdMob va Firebase co the xu ly du lieu ky thuat gioi han (mau thiet bi, phien ban he dieu hanh, loai mang, ID quang cao, nhat ky loi/hieu nang) de giu ung dung on dinh va hien thi quang cao phu hop.

3. Muc dich su dung du lieu
De cung cap tinh nang phan tich, duy tri ung dung (cap nhat, che do bao tri, bat/tat tinh nang) va ho tro su dung mien phi thong qua quang cao.

4. Dich vu ben thu ba
Chung toi khong ban du lieu ca nhan. Chung toi su dung cac dich vu ben thu ba dang tin cay cho quang cao va phan tich:
Google AdMob: Chinh sach quyen rieng tu
Google Firebase: Chinh sach quyen rieng tu

5. Quyen kiem soat va xoa du lieu
Vi du lieu phien va phan tich duoc luu cuc bo, ban van la nguoi kiem soat.
Ban co the xoa du lieu bat cu luc nao bang cach dang xuat, xoa bo nho luu tru/cache cua ung dung hoac go cai dat ung dung.

6. Bao mat
Chung toi ap dung cac bien phap bao mat tieu chuan de bao ve du lieu cuc bo tren thiet bi va lien tuc cai tien cac bien phap nay.

7. Tre em
VERDICT khong danh cho tre duoi 13 tuoi. Chung toi khong co y thu thap du lieu ca nhan cua tre duoi 13 tuoi.

8. Cap nhat chinh sach
Chung toi co the cap nhat chinh sach nay theo tung thoi diem. Ban moi nhat se duoc dang tai tren trang nay.

9. Lien he
Neu ban co cau hoi hoac goi y, vui long lien he voi chung toi.''',
  'th': '''นโยบายความเป็นส่วนตัวของ VERDICT

ขอบคุณที่ใช้งาน VERDICT เอกสารนี้อธิบายด้วยภาษาที่เข้าใจง่ายว่าเราดูแลข้อมูลอย่างไรระหว่างการใช้งานแอป หากมีจุดใดที่ไม่ชัดเจน คุณสามารถติดต่อเราได้ทุกเมื่อ

1. ความสัมพันธ์ระหว่าง VERDICT กับ Instagram
VERDICT เป็นแอปของบุคคลที่สามที่พัฒนาอย่างอิสระ ไม่มีความร่วมมืออย่างเป็นทางการ และไม่ได้อยู่ภายใต้การสนับสนุนหรือการบริหารของ Instagram, Facebook หรือ Meta Platforms, Inc. คำว่า "Instagram" เป็นเครื่องหมายการค้าของ Meta Platforms, Inc.

2. ข้อมูลที่เราประมวลผลเพื่อให้บริการ
VERDICT ออกแบบโดยให้ความสำคัญกับความเป็นส่วนตัว และประมวลผลบนอุปกรณ์เป็นหลัก การวิเคราะห์ส่วนใหญ่ทำงานภายในโทรศัพท์ของคุณ
A. เซสชันการเข้าสู่ระบบ (การยืนยันตัวตน): เพื่อใช้งานการวิเคราะห์ผู้ติดตาม คุณจะเข้าสู่ระบบผ่านหน้าเข้าสู่ระบบทางการของ Instagram ภายใน WebView ที่ปลอดภัย
ขอบเขตการเข้าถึงของเรา: เราไม่เห็นและไม่เก็บรหัสผ่านของคุณ คุกกี้เซสชันและโทเคนยืนยันตัวตนจะถูกเก็บไว้เฉพาะในพื้นที่จัดเก็บภายในที่ปลอดภัยของอุปกรณ์ (เช่น Android SharedPreferences, iOS Keychain)
แนวทางด้านเซิร์ฟเวอร์: รหัสผ่านและรายการผู้ติดตามของคุณจะไม่ถูกอัปโหลดไปยังเซิร์ฟเวอร์ภายนอกที่เราเป็นเจ้าของ
B. ข้อมูลอุปกรณ์/การใช้งานแบบจำกัด: Google AdMob และ Firebase อาจประมวลผลข้อมูลทางเทคนิคบางส่วน (รุ่นอุปกรณ์ เวอร์ชันระบบ ประเภทเครือข่าย รหัสโฆษณา บันทึกข้อขัดข้อง/ประสิทธิภาพ) เพื่อให้แอปทำงานเสถียรและแสดงโฆษณาที่เหมาะสม

3. วัตถุประสงค์ในการใช้ข้อมูล
เพื่อให้บริการฟีเจอร์วิเคราะห์ ดูแลระบบแอป (อัปเดต โหมดบำรุงรักษา การสลับฟีเจอร์) และสนับสนุนการใช้งานฟรีผ่านโฆษณา

4. บริการของบุคคลที่สาม
เราไม่ขายข้อมูลส่วนบุคคล เราใช้บริการบุคคลที่สามที่เชื่อถือได้สำหรับโฆษณาและการวิเคราะห์
Google AdMob: นโยบายความเป็นส่วนตัว
Google Firebase: นโยบายความเป็นส่วนตัว

5. การควบคุมและการลบข้อมูล
เนื่องจากข้อมูลเซสชันและข้อมูลวิเคราะห์ถูกเก็บไว้ในอุปกรณ์ของคุณ คุณจึงควบคุมได้ด้วยตนเอง
คุณสามารถลบข้อมูลได้ทุกเมื่อโดยออกจากระบบ ล้างที่เก็บข้อมูล/แคชของแอป หรือถอนการติดตั้งแอป

6. ความปลอดภัย
เราใช้มาตรการความปลอดภัยตามมาตรฐานเพื่อปกป้องข้อมูลในอุปกรณ์ และปรับปรุงมาตรการเหล่านี้อย่างต่อเนื่อง

7. ความเป็นส่วนตัวของเด็ก
VERDICT ไม่ได้ออกแบบมาสำหรับผู้ที่อายุต่ำกว่า 13 ปี และเราไม่ตั้งใจเก็บข้อมูลส่วนบุคคลของเด็กอายุต่ำกว่า 13 ปี

8. การอัปเดตนโยบาย
เราอาจปรับปรุงนโยบายนี้เป็นระยะ โดยจะแสดงฉบับล่าสุดไว้บนหน้านี้

9. ติดต่อเรา
หากคุณมีคำถามหรือข้อเสนอแนะ กรุณาติดต่อเราได้เสมอ''',
  'pl': '''POLITYKA PRYWATNOŚCI VERDICT

Dziękujemy za korzystanie z VERDICT. Ten dokument prostym językiem wyjaśnia, jak przetwarzamy dane podczas korzystania z aplikacji. Jeśli coś jest niejasne, możesz skontaktować się z nami w każdej chwili.

1. Relacja VERDICT z Instagramem
VERDICT to niezależna aplikacja strony trzeciej. Nie jest oficjalnie powiązana z Instagramem, Facebookiem ani Meta Platforms, Inc., ani przez te podmioty zarządzana. "Instagram" jest znakiem towarowym Meta Platforms, Inc.

2. Dane przetwarzane w celu świadczenia usługi
VERDICT została zaprojektowana zgodnie z podejściem privacy-first, a większość analiz odbywa się lokalnie na Twoim urządzeniu.
A. Sesja logowania (uwierzytelnianie): aby uruchomić analizę obserwujących, logujesz się przez oficjalną stronę logowania Instagram w bezpiecznym WebView.
Nasz dostęp: nie widzimy i nie przechowujemy Twojego hasła. Cookies sesyjne i tokeny uwierzytelniające pozostają wyłącznie w bezpiecznym, lokalnym magazynie urządzenia (np. Android SharedPreferences, iOS Keychain).
Podejście serwerowe: hasło i listy obserwujących nie są przesyłane na zewnętrzne serwery będące naszą własnością.
B. Ograniczone dane urządzenia/użycia: Google AdMob i Firebase mogą przetwarzać ograniczone dane techniczne (model urządzenia, wersja systemu, typ sieci, identyfikator reklamowy, logi awarii/wydajności), aby utrzymać stabilność aplikacji i wyświetlać trafniejsze reklamy.

3. Dlaczego używamy tych danych
Aby udostępniać funkcje analizy, utrzymywać aplikację (aktualizacje, tryb konserwacji, przełączniki funkcji) oraz finansować darmowe korzystanie z aplikacji poprzez reklamy.

4. Usługi stron trzecich
Nie sprzedajemy danych osobowych. Korzystamy z zaufanych usług stron trzecich do reklam i analityki:
Google AdMob: Polityka prywatności
Google Firebase: Polityka prywatności

5. Twoja kontrola i usuwanie danych
Ponieważ dane sesji i analizy są przechowywane lokalnie, kontrola pozostaje po Twojej stronie.
Możesz usunąć dane w dowolnym momencie: wylogować się, wyczyścić pamięć/cache aplikacji albo odinstalować aplikację.

6. Bezpieczeństwo
Stosujemy standardowe praktyki bezpieczeństwa do ochrony danych lokalnych i stale udoskonalamy te zabezpieczenia.

7. Prywatność dzieci
VERDICT nie jest przeznaczony dla dzieci poniżej 13 roku życia. Nie zbieramy świadomie danych osobowych dzieci poniżej 13 lat.

8. Aktualizacje polityki
Możemy okresowo aktualizować tę politykę. Najnowsza wersja będzie publikowana na tej stronie.

9. Kontakt
Jeśli masz pytania lub sugestie, skontaktuj się z nami.''',
};