import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'firebase_options.dart';
import 'purchases_service.dart';
import 'telemetry_service.dart';
import 'tr_en_phrase_localizations.dart';
import 'did_you_know_phrase_localizations.dart';
import 'privacy_policy_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final Completer<void> _umpConsentFlowCompleter = Completer<void>();

const String _igAppId = '936619743392459';
const String _defaultIgUserAgent =
    'Instagram 315.0.0.32.109 Android (33/13; 420dpi; 1080x2400; samsung; SM-G991B; o1s; exynos2100; tr_TR; 563533633)';
const String _revenueCatAndroidApiKey = String.fromEnvironment(
  'REVENUECAT_ANDROID_API_KEY',
  defaultValue: '',
);
const String _revenueCatIosApiKey = String.fromEnvironment(
  'REVENUECAT_IOS_API_KEY',
  defaultValue: 'appl_JaWUAzYMRRqsEAkwdcRvjJxRWnv',
);
const bool _forceFirestoreTest = false;
const bool _userFacingFirebaseDiagnosticsEnabled = false;
const int _firestoreTimeoutSeconds =
    int.fromEnvironment('FIRESTORE_TIMEOUT_SECONDS', defaultValue: 20);
const Duration _firestoreTimeout = Duration(seconds: _firestoreTimeoutSeconds);
const String _firestoreSetupBaseUrl =
    'https://console.cloud.google.com/datastore/setup?project=';
const String _privacyPolicySourceUrl =
    'https://raw.githubusercontent.com/grkmcomert/verdict-web/refs/heads/main/privacy-policy.txt';
const MethodChannel _cookieChannel =
    MethodChannel('com.grkmcomert.unfollowerscurrent/cookie');
const MethodChannel _reviewChannel =
    MethodChannel('com.grkmcomert.unfollowerscurrent/review');

const Map<String, String> _startupLoadingLabels = <String, String>{
  'tr': 'VERDICT başlatılıyor...',
  'en': 'Starting VERDICT...',
  'de': 'VERDICT wird gestartet...',
  'ko': 'VERDICT를 시작하는 중...',
  'ja': 'VERDICTを起動しています...',
  'ru': 'Запуск VERDICT...',
  'pt': 'Iniciando VERDICT...',
  'ar': 'جاري تشغيل VERDICT...',
  'es': 'Iniciando VERDICT...',
  'es-mx': 'Iniciando VERDICT...',
  'hi': 'VERDICT शुरू हो रहा है...',
  'hu': 'VERDICT indul...',
  'zh-hans': '正在启动 VERDICT...',
  'id': 'Memulai VERDICT...',
  'nl': 'VERDICT wordt gestart...',
  'fr': 'Démarrage de VERDICT...',
  'it': 'Avvio di VERDICT...',
  'vi': 'Đang khởi động VERDICT...',
  'th': 'กำลังเริ่ม VERDICT...',
  'pl': 'Uruchamianie VERDICT...',
};

const Map<String, String> _legalWarningSummaryLabels = <String, String>{
  'tr':
      'Yasal bilgilendirme: Bu bölüm kısa bir özet gösterir. Gizlilik Politikası düğmesine dokunarak tam metni dilinizde görüntüleyebilirsiniz.',
  'en':
      'Legal notice: This section shows a short summary. Tap Privacy Policy to view the full text in your language.',
  'de':
      'Rechtlicher Hinweis: Dieser Abschnitt zeigt eine kurze Zusammenfassung. Tippen Sie auf Datenschutzrichtlinie, um den vollständigen Text in Ihrer Sprache zu lesen.',
  'ko':
      '법적 고지: 이 섹션은 요약만 표시합니다. 개인정보 처리방침 버튼을 눌러 전체 내용을 사용자 언어로 확인하세요.',
  'ja':
      '法的通知: このセクションには要約のみ表示されます。プライバシーポリシーをタップすると、全文をお使いの言語で確認できます。',
  'ru':
      'Юридическое уведомление: В этом разделе показывается краткое содержание. Нажмите «Политика конфиденциальности», чтобы открыть полный текст на вашем языке.',
  'pt':
      'Aviso legal: esta seção mostra apenas um resumo. Toque em Política de Privacidade para ver o texto completo no seu idioma.',
  'ar':
      'إشعار قانوني: يعرض هذا القسم ملخصًا قصيرًا فقط. اضغط على سياسة الخصوصية لعرض النص الكامل بلغتك.',
  'es':
      'Aviso legal: esta sección muestra un resumen breve. Toca Política de privacidad para ver el texto completo en tu idioma.',
  'es-mx':
      'Aviso legal: esta sección muestra un resumen breve. Toca Política de privacidad para ver el texto completo en tu idioma.',
  'hi':
      'कानूनी सूचना: इस भाग में केवल संक्षिप्त सार दिखाया जाता है। अपनी भाषा में पूरा पाठ देखने के लिए गोपनीयता नीति पर टैप करें।',
  'hu':
      'Jogi tájékoztató: Ez a szakasz csak rövid összefoglalót mutat. A teljes szöveg nyelveden a „Adatvédelmi tájékoztató” gombbal érhető el.',
  'zh-hans': '法律提示：此处仅显示简要说明。点击“隐私政策”可查看你所用语言的完整内容。',
  'id':
      'Pemberitahuan hukum: Bagian ini hanya menampilkan ringkasan singkat. Ketuk Kebijakan Privasi untuk melihat teks lengkap dalam bahasa Anda.',
  'nl':
      'Juridische melding: Dit onderdeel toont alleen een korte samenvatting. Tik op Privacybeleid om de volledige tekst in jouw taal te bekijken.',
  'fr':
      'Mentions légales : cette section affiche un court résumé. Appuyez sur Politique de confidentialité pour voir le texte complet dans votre langue.',
  'it':
      'Avviso legale: questa sezione mostra un breve riepilogo. Tocca Informativa sulla privacy per vedere il testo completo nella tua lingua.',
  'vi':
      'Thông báo pháp lý: Mục này chỉ hiển thị phần tóm tắt ngắn. Nhấn Chính sách bảo mật để xem toàn văn bằng ngôn ngữ của bạn.',
  'th':
      'ประกาศทางกฎหมาย: ส่วนนี้จะแสดงเพียงสรุปสั้นๆ เท่านั้น แตะนโยบายความเป็นส่วนตัวเพื่อดูข้อความเต็มตามภาษาของคุณ',
  'pl':
      'Informacja prawna: Ta sekcja pokazuje krótkie podsumowanie. Dotknij „Polityka prywatności”, aby wyświetlić pełny tekst w swoim języku.',
};

String _normalizeSupportedLangCodeFromLocale(String localeRaw) {
  final String locale = localeRaw.trim().toLowerCase().replaceAll('-', '_');
  if (locale.isEmpty) return 'en';
  final String base = locale.split('_').first.trim();

  if (base == 'es') {
    if (locale.startsWith('es_mx') || locale.startsWith('es_419')) {
      return 'es-mx';
    }
    return 'es';
  }
  if (base == 'zh') return 'zh-hans';
  if (base == 'in') return 'id';

  return _startupLoadingLabels.containsKey(base) ? base : 'en';
}

String _startupLoadingTextForLocale(String localeRaw) {
  final String code = _normalizeSupportedLangCodeFromLocale(localeRaw);
  return _startupLoadingLabels[code] ?? _startupLoadingLabels['en']!;
}

Future<void> _waitForUmpConsentFlow() async {
  if (_umpConsentFlowCompleter.isCompleted) return;
  try {
    await _umpConsentFlowCompleter.future.timeout(const Duration(seconds: 12));
  } catch (_) {}
}

String _extractCookieValue(String cookieHeader, String name) {
  String value = '';
  for (final part in cookieHeader.split(';')) {
    final String trimmed = part.trim();
    if (trimmed.startsWith('$name=')) {
      value = trimmed.substring(name.length + 1);
    }
  }
  return value;
}

String? _resolveSessionDsUserId(String? savedUserId, String? savedCookie) {
  final String direct = (savedUserId ?? '').trim();
  if (direct.isNotEmpty && direct != 'null') return direct;
  final String cookie = (savedCookie ?? '').trim();
  if (cookie.isEmpty) return null;
  final String fromCookie = _extractCookieValue(cookie, 'ds_user_id').trim();
  if (fromCookie.isEmpty || fromCookie == 'null') return null;
  return fromCookie;
}

bool _preferWebApi(String userAgent) {
  return !userAgent.toLowerCase().contains('instagram');
}

Map<String, String> _buildWebHeaders(String cookie, String userAgent,
    {String? dsUserId}) {
  final String csrf = _extractCookieValue(cookie, 'csrftoken');
  return {
    'Cookie': cookie,
    'User-Agent': userAgent,
    'X-IG-App-ID': _igAppId,
    'X-Requested-With': 'XMLHttpRequest',
    'X-IG-WWW-Claim': '0',
    if (csrf.isNotEmpty) 'X-CSRFToken': csrf,
    if (dsUserId != null && dsUserId.isNotEmpty) 'IG-U-DS-User-ID': dsUserId,
    'Accept': '*/*',
    'Referer': 'https://www.instagram.com/',
  };
}

Map<String, String> _buildAppHeaders(String cookie, String userAgent,
    {String? dsUserId}) {
  final String csrf = _extractCookieValue(cookie, 'csrftoken');
  return {
    'Cookie': cookie,
    'User-Agent': userAgent,
    'X-IG-App-ID': _igAppId,
    'X-IG-WWW-Claim': '0',
    if (csrf.isNotEmpty) 'X-CSRFToken': csrf,
    if (dsUserId != null && dsUserId.isNotEmpty) 'IG-U-DS-User-ID': dsUserId,
    'Accept': '*/*',
  };
}

bool _looksLikeMojibakeText(String value) {
  if (value.isEmpty) return false;

  // Replacement char is a strong indicator of a decoding problem.
  if (value.contains('\uFFFD')) return true;

  // C1 control characters often appear when bytes were mis-decoded as Latin-1.
  if (_mojibakeC1Pattern.hasMatch(value)) return true;

  // Common CP1252-decoded UTF-8 artifact prefix: "â€…"
  if (value.contains('\u00E2\u20AC')) return true;

  // Marker bytes (Â/Ã/Ä/Å/Ð/Ñ) followed by likely UTF-8 continuation bytes or
  // CP1252 "extended" punctuation.
  if (_mojibakeMarkerPattern.hasMatch(value)) return true;

  // UTF-8 BOM decoded as Latin-1: ï»¿
  if (value.contains('\u00EF\u00BB\u00BF')) return true;

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
  // cp1254 characters that frequently appear in mixed mojibake text.
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

String _repairDisplayText(String value) {
  if (value.isEmpty) return value;
  if (!_looksLikeMojibakeText(value)) return value;

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
    if (!_looksLikeMojibakeText(fixed)) break;
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _initializeFirebaseApp();
}

Future<void> _initializeFirebaseApp() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await PurchasesService.instance.loadCachedPremiumStatus();
    unawaited(() async {
      await PurchasesService.instance.configure(
        androidApiKey: _revenueCatAndroidApiKey,
        iosApiKey: _revenueCatIosApiKey,
      );
      await PurchasesService.instance.checkPurchaseStatus();
    }());
    await _initializeFirebaseApp();
    try {
      final FirebaseApp app = Firebase.app();
      debugPrint('[Firebase] Initialized projectId=${app.options.projectId}');
    } catch (_) {}
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        final UserCredential cred =
            await FirebaseAuth.instance.signInAnonymously();
        debugPrint('[FirebaseAuth] anonymous uid=${cred.user?.uid}');
      } else {
        debugPrint(
            '[FirebaseAuth] already signed in uid=${FirebaseAuth.instance.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('[FirebaseAuth] anonymous sign-in failed: $e');
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    runApp(const RootApp());
  }, (error, stack) {
    debugPrint("Global Hata Yakalandı: $error");
  });
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  static const int _dailyReminderBaseId = 11000;
  static const int _dailyReminderDaysToSchedule = 30;

  bool _isLoading = true;
  bool _showRealApp = false;
  bool _isAppEnabled = true;
  bool _isUpdateRequired = false;
  String _updateMessage = "";
  String _debugError = "";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone hatası: $e');
    }

    try {
      await _initNotifications();
    } catch (e) {
      debugPrint('Bildirim başlatma hatası: $e');
    }

    try {
      await _fetchConfig();
    } catch (e) {
      debugPrint('Config hatası: $e');
      final String langCode =
          Platform.localeName.toLowerCase().split(RegExp(r'[_-]')).first.trim();
      _debugError = localizeTrEn(
        langCode,
        'Bağlantı hatası. Lütfen tekrar deneyin.',
        'Connection error. Please try again.',
      );
    }

    try {
      _initGoogleMobileAds();
      _initFirebaseMessaging();
      _checkAppLaunchForRating();
      _scheduleDailyNotification();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_default_channel',
      'FCM Notifications',
      description: 'Foreground FCM notifications',
      importance: Importance.high,
    );
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'daily_analysis_channel',
      'Daily Analysis',
      description: 'Daily reminder to check followers',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(dailyChannel);
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(false);
      await messaging.deleteToken();
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (e) {
      debugPrint("FCM init error: $e");
    }
  }

  Future<void> _scheduleDailyNotification() async {
    try {
      final String locale = Platform.localeName;
      final String langCode =
          locale.toLowerCase().split(RegExp(r'[_-]')).first.trim();
      final String title =
          localizeTrEn(langCode, 'Analiz Vakti!', 'Analysis Time!');
      final String body = localizeTrEn(
        langCode,
        'Verileri güncelleme zamanı! Takipçi listendeki değişiklikleri görmek için şimdi analiz et.',
        'Time to update data! Analyze now to see changes in your follower list.',
      );
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      for (int i = 0; i < _dailyReminderDaysToSchedule; i++) {
        await flutterLocalNotificationsPlugin.cancel(
          id: _dailyReminderBaseId + i,
        );
      }
      try {
        for (int i = 0; i < _dailyReminderDaysToSchedule; i++) {
          final tz.TZDateTime day = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
          ).add(Duration(days: i));
          final tz.TZDateTime scheduleAt = _randomReminderTimeForDay(day);
          if (!scheduleAt.isAfter(now)) continue;
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: _dailyReminderBaseId + i,
            title: title,
            body: body,
            scheduledDate: scheduleAt,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_analysis_channel',
                'Daily Analysis',
                channelDescription: 'Daily reminder to check followers',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      } catch (e) {
        debugPrint('ZonedSchedule hatası: $e');
      }
    } catch (e) {
      debugPrint('Bildirim genel hata: $e');
    }
  }

  tz.TZDateTime _randomReminderTimeForDay(tz.TZDateTime day) {
    const int startMinute = 11 * 60;
    const int endMinute = 21 * 60 + 30;
    final int seed = day.year * 10000 + day.month * 100 + day.day;
    final Random random = Random(seed);
    final int minuteOfDay =
        startMinute + random.nextInt(endMinute - startMinute + 1);
    final int hour = minuteOfDay ~/ 60;
    final int minute = minuteOfDay % 60;
    return tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
  }

  Future<void> _checkAppLaunchForRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int launchCount = prefs.getInt('app_launch_count') ?? 0;
      launchCount++;
      await prefs.setInt('app_launch_count', launchCount);
    } catch (_) {}
  }

  void _initGoogleMobileAds() {
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          await _loadAndShowConsentForm();
        }
        _initializeMobileAds();
        if (!_umpConsentFlowCompleter.isCompleted) {
          _umpConsentFlowCompleter.complete();
        }
      },
      (FormError error) async {
        _initializeMobileAds();
        if (!_umpConsentFlowCompleter.isCompleted) {
          _umpConsentFlowCompleter.complete();
        }
      },
    );
  }

  Future<void> _loadAndShowConsentForm() async {
    final Completer<void> c = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) {
      if (!c.isCompleted) c.complete();
    });
    try {
      await c.future;
    } catch (_) {}
  }

  Future<void> _initializeMobileAds() async {
    if (await ConsentInformation.instance.canRequestAds()) {
      await MobileAds.instance.initialize();
    }
  }

  Future<void> _fetchConfig() async {
    _showRealApp = false;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig
          .setDefaults({"show_real_app": false, "app_enabled": true});
      await remoteConfig.fetchAndActivate();
      _showRealApp = remoteConfig.getBool('show_real_app');
      _isAppEnabled = remoteConfig.getBool('app_enabled');
      await _checkForcedUpdate(remoteConfig);
    } catch (e) {
      _showRealApp = false;
      _isAppEnabled = true;
      final String langCode =
          Platform.localeName.toLowerCase().split(RegExp(r'[_-]')).first.trim();
      _debugError = localizeTrEn(
        langCode,
        'Bağlantı hatası. Lütfen tekrar deneyin.',
        'Connection error. Please try again.',
      );
    }
  }

  Future<void> _checkForcedUpdate(FirebaseRemoteConfig remoteConfig) async {
    try {
      final String rawAllowed = remoteConfig.getString('currentappversion');
      final Set<String> allowedVersions = rawAllowed
          .split(RegExp(r'[,\n;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) =>
              (e.startsWith('v') || e.startsWith('V')) ? e.substring(1) : e)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      if (allowedVersions.isEmpty) {
        _isUpdateRequired = false;
        if (mounted) setState(() {});
        return;
      }
      final info = await PackageInfo.fromPlatform();
      final String currentVersion = info.version.trim();
      final String currentFull =
          '${info.version.trim()}+${info.buildNumber.trim()}';
      final bool matches = allowedVersions.contains(currentVersion) ||
          allowedVersions.contains(currentFull);
      _isUpdateRequired = !matches;
      if (_isUpdateRequired) {
        final String langCode = Platform.localeName
            .toLowerCase()
            .split(RegExp(r'[_-]'))
            .first
            .trim();
        _updateMessage = localizeTrEn(
          langCode,
          'Yeni güncelleme mevcut! Lütfen mağazayı kontrol edin.',
          'A new update is available. Please check the store.',
        );
      }
      if (mounted) setState(() {});
    } catch (_) {
      _isUpdateRequired = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final String startupText =
          _startupLoadingTextForLocale(Platform.localeName);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: ModernLoader(text: startupText)),
      );
    }
    if (_isUpdateRequired) {
      return UpdateRequiredApp(message: _updateMessage);
    }
    if (!_isAppEnabled) return const MaintenanceApp();
    if (_showRealApp) {
      return const UnfollowersApp();
    } else {
      return SafeModeApp(debugError: _debugError);
    }
  }
}

class UpdateRequiredApp extends StatelessWidget {
  final String message;
  const UpdateRequiredApp({super.key, required this.message});

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
      return;
    }
    if (Platform.isIOS) {
      exit(0);
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final String langCode =
        Platform.localeName.toLowerCase().split(RegExp(r'[_-]')).first.trim();
    final String bodyText = message.isNotEmpty
        ? message
        : localizeTrEn(
            langCode,
            'İyi haber! Güncelleme mevcut. Mağazamızı kontrol edip yeni sürümü indir!',
            'Good news! An update is available. Check our store and download the latest version!',
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F7F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF3F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.system_update_alt,
                            size: 42, color: Colors.blueGrey.shade700),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizeTrEn(
                          langCode,
                          'İyi haber! Güncelleme mevcut',
                          'Good news! Update available',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey.shade900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        bodyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.blueGrey.shade600),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _closeApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            localizeTrEn(langCode, 'KAPAT', 'CLOSE'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MaintenanceApp extends StatelessWidget {
  const MaintenanceApp({super.key});
  @override
  Widget build(BuildContext context) {
    final String langCode =
        Platform.localeName.toLowerCase().split(RegExp(r'[_-]')).first.trim();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F7F9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle_outlined,
                  size: 80, color: Colors.blueGrey.shade700),
              const SizedBox(height: 20),
              Text(
                  localizeTrEn(
                      langCode, 'SİSTEM BAKIMDA', 'SYSTEM UNDER MAINTENANCE'),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey.shade800)),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernLoader extends StatefulWidget {
  final String? text;
  final bool isDark;
  final double? progress;

  final String lang;

  const ModernLoader(
      {super.key,
      this.text,
      this.isDark = false,
      this.progress,
      this.lang = 'tr'});

  @override
  State<ModernLoader> createState() => _ModernLoaderState();
}

const Map<String, String> _didYouKnowLabels = <String, String>{
  'tr': 'BUNLARI BİLİYOR MUYDUNUZ?',
  'en': 'DID YOU KNOW?',
  'de': 'WUSSTEN SIE?',
  'ko': '알고 계셨나요?',
  'ja': '知っていましたか？',
  'ru': 'ЗНАЛИ ЛИ ВЫ?',
  'pt': 'VOCÊ SABIA?',
  'ar': 'هل تعلم؟',
  'es': '¿SABÍAS QUE?',
  'es-mx': '¿SABÍAS QUE?',
  'hi': 'क्या आप जानते हैं?',
  'hu': 'TUDTAD?',
  'zh-hans': '你知道吗？',
  'id': 'TAHUKAH ANDA?',
  'nl': 'WIST JE DIT?',
  'fr': 'LE SAVIEZ-VOUS ?',
  'it': 'LO SAPEVI?',
  'vi': 'BẠN CÓ BIẾT KHÔNG?',
  'th': 'คุณรู้หรือไม่?',
  'pl': 'CZY WIESZ?',
};

String _didYouKnowLabelForLang(String lang) {
  final String normalized = lang.trim().toLowerCase().replaceAll('_', '-');
  String label;
  if (normalized.startsWith('es')) {
    label = _didYouKnowLabels[normalized == 'es-mx' ? 'es-mx' : 'es']!;
  } else if (normalized.startsWith('zh')) {
    label = _didYouKnowLabels['zh-hans']!;
  } else if (normalized == 'in') {
    label = _didYouKnowLabels['id']!;
  } else {
    label = _didYouKnowLabels[normalized] ?? _didYouKnowLabels['en']!;
  }
  final String repaired = _repairDisplayText(label).trim();
  if (_looksLikeMojibakeText(repaired)) return _didYouKnowLabels['en']!;
  return repaired;
}

const List<Map<String, String>> _analysisDidYouKnowFacts = [
  {
    'tr':
        'Kargalar sadece insan yüzlerini tanımakla kalmaz, kendilerine kötü davrananları yıllarca unutmaz ve diğer kargalara da bunu haber verirler.',
    'en':
        'Crows don’t just recognize human faces; they can remember people who treated them badly for years—and even warn other crows.',
  },
  {
    'tr':
        "Kediler hayatlarının yaklaşık %70'ini uyuyarak geçirirler; yani 10 yaşındaki bir kedi aslında sadece 3 yıl uyanık kalmıştır.",
    'en':
        'Cats spend about 70% of their lives asleep—so a 10-year-old cat has been awake for only about 3 years.',
  },
  {
    'tr':
        'Bal asla bozulmaz; arkeologlar Mısır piramitlerinde 3000 yıllık bozulmamış ve hala yenilebilir durumda olan bal kavanozları bulmuşlardır.',
    'en':
        'Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.',
  },
  {
    'tr':
        'Su samurları, uyurken akıntıya kapılıp birbirlerinden ayrılmamak için el ele tutuşurlar.',
    'en':
        'Sea otters hold hands while they sleep so they don’t drift apart in the current.',
  },
  {
    'tr':
        "Venüs'te bir gün, bir yıldan daha uzun sürer; yani kendi etrafında dönmesi, Güneş etrafında dönmesinden daha yavaştır.",
    'en':
        'On Venus, a day is longer than a year—it rotates on its axis more slowly than it orbits the Sun.',
  },
  {
    'tr':
        'Çakmak, kibritten önce icat edilmiştir; bazen teknoloji sandığımızdan daha eski kafalı olabiliyor.',
    'en':
        'The lighter was invented before the match—sometimes “old” tech is older than we think.',
  },
  {
    'tr':
        'Ahtapotların üç tane kalbi ve tam dokuz tane beyni vardır; bir şeyi unutma lüksleri pek yok gibi.',
    'en':
        'Octopuses have three hearts and nine brains—forgetting things isn’t really an option.',
  },
  {
    'tr':
        'İneklerin "en yakın arkadaşları" vardır ve onlardan ayrıldıklarında ciddi şekilde strese girip ağlayabilirler.',
    'en':
        'Cows have “best friends,” and they can get seriously stressed—and even cry—when separated.',
  },
  {
    'tr':
        'Dünyadaki ilk bilgisayar virüsü "Creeper" adındaydı ve ekranda sadece "Ben bir sarmaşığım, yakalayabiliyorsan yakala!" yazıyordu.',
    'en':
        'The world’s first computer virus was called “Creeper,” and it displayed: “I’m the creeper, catch me if you can!”',
  },
  {
    'tr':
        'Bir bulutun ağırlığı ortalama 500 bin kilogramdır; yani tepemizde yüzen devasa bir fil sürüsü gibi düşünebilirsin.',
    'en':
        'An average cloud can weigh around 500,000 kg—like a massive herd of elephants floating overhead.',
  },
  {
    'tr':
        'İnsan DNA\'sı ile bir muzun DNA\'sı %50 oranında benzerdir; yani yarın sabah bir muza "kardeşim" dersen pek de haksız sayılmazsın.',
    'en':
        'Human DNA is about 50% similar to banana DNA—so calling a banana “my sibling” tomorrow morning isn’t totally unfair.',
  },
  {
    'tr':
        'Kutup ayılarının derisi aslında siyahtır, tüyleri ise şeffaftır; beyaz görünmesi sadece bir ışık yansıması hilesidir.',
    'en':
        'Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.',
  },
  {
    'tr':
        'Uzayda ağlayamazsınız çünkü yerçekimi olmadığı için gözyaşlarınız yüzünüzden aşağı süzülmez, gözünüzde bir top gibi birikir.',
    'en':
        'You can’t really cry in space: without gravity, tears don’t run down your face—they form a blob in your eye.',
  },
  {
    'tr':
        'Everest Dağı her yıl yaklaşık 4 milimetre kadar uzamaya devam ediyor; yani dünya hala büyüyor.',
    'en':
        'Mount Everest keeps growing by about 4 millimeters each year—Earth is still changing.',
  },
  {
    'tr':
        'Islık çalan fareler aslında birbirlerine şarkı söylerler ama bu sesler insan kulağının duyamayacağı kadar yüksek frekanstadır.',
    'en':
        '“Whistling” mice are essentially singing to each other, but at frequencies too high for humans to hear.',
  },
  {
    'tr':
        'Köpekbalıkları ağaçlardan daha eskidir; dünyada yaklaşık 400 milyon yıldır varlar, ağaçlar ise sadece 350 milyon yıldır.',
    'en':
        'Sharks are older than trees—sharks have been around for about 400 million years, trees for about 350 million.',
  },
  {
    'tr':
        'Muzlar aslında botanik olarak meyve (berry) sayılırken, çilekler bu gruba girmez; botanik dünyası biraz karışık.',
    'en':
        'Bananas are botanically berries, but strawberries aren’t—botany can be weird.',
  },
  {
    'tr':
        'Bir karınca kendi ağırlığının 50 katını kaldırabilir; eğer sen bir karınca olsaydın, bir otomobili tek başına kaldırabilirdin.',
    'en':
        'An ant can lift up to 50 times its own weight—if you were an ant, you could lift a car by yourself.',
  },
  {
    'tr':
        "Eyfel Kulesi yaz aylarında genleşme nedeniyle yaklaşık 15 santimetre kadar uzayabilir.",
    'en':
        'The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.',
  },
  {
    'tr':
        'Dünyadaki tüm insanların toplam ağırlığı, dünyadaki tüm karıncaların toplam ağırlığına neredeyse eşittir.',
    'en':
        'The total weight of all humans on Earth is roughly comparable to the total weight of all ants.',
  },
  {
    'tr':
        'Tembel hayvanlar nefeslerini su altında yunuslardan daha uzun süre tutabilirler; tam 40 dakika boyunca suyun altında kalabilirler.',
    'en':
        'Sloths can hold their breath underwater longer than dolphins—up to about 40 minutes.',
  },
  {
    'tr':
        "Güvercinler, Picasso ve Monet'nin tabloları arasındaki farkı ayırt edebilirler; yani sandığından çok daha sanatsal bir vizyona sahipler.",
    'en':
        'Pigeons can tell the difference between paintings by Picasso and Monet—turns out they’re more art-savvy than we think.',
  },
  {
    'tr':
        'GPS sistemi aslında dünya çapında ücretsizdir ancak ABD hükümeti bu sistemi çalışır halde tutmak için günde yaklaşık 2 milyon dolar harcar.',
    'en':
        'GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.',
  },
  {
    'tr':
        'Platipusların (orkinitorenk) mideleri yoktur; yedikleri besinler yemek borusundan doğrudan bağırsaklarına geçer.',
    'en':
        'Platypuses don’t have stomachs—food goes from the esophagus straight to the intestines.',
  },
  {
    'tr':
        '"Swagger" (havalı yürüyüş/tavır) kelimesini ilk kez William Shakespeare kullanmıştır; adam 16. yüzyılda bile ortama şeklini koymuş.',
    'en':
        'William Shakespeare is credited with the first recorded use of the word “swagger”—even in the 16th century, he had style.',
  },
  {
    'tr':
        'Mavi balinaların kalbi o kadar büyüktür ki, bir insan ana atardamarlarının içinde rahatça yüzebilir.',
    'en':
        'A blue whale’s heart is so large that a human could swim through its main arteries.',
  },
  {
    'tr':
        'Karıncaların akciğerleri yoktur ve asla uyumazlar; tam bir işkolik gibi 7/24 çalışırlar.',
    'en':
        'Ants don’t have lungs—and they never truly “sleep”; they operate nonstop like tiny workaholics.',
  },
  {
    'tr':
        "Satürn ve Jüpiter'de kelimenin tam anlamıyla elmas yağmuru yağar; zengin olmak için yanlış gezegende yaşıyoruz.",
    'en':
        'On Saturn and Jupiter, it can literally rain diamonds—apparently we’re living on the wrong planet.',
  },
  {
    'tr':
        'Bal arıları insan yüzlerini tanıyabilir ve onları tek tek hafızalarına kaydedebilirler.',
    'en': 'Honeybees can recognize human faces and remember them individually.',
  },
  {
    'tr':
        'Su aygırlarının teri aslında pembe renklidir ve bu ter hem güneş kremi hem de mikrop öldürücü yerine geçer.',
    'en':
        'Hippo “sweat” can look pink and acts like both sunscreen and an antibacterial shield.',
  },
  {
    'tr':
        'Vombatların dışkıları küp şeklindedir; bu sayede dışkıları yokuş aşağı yuvarlanmaz ve bölgelerini işaretlemek için sabit durur.',
    'en':
        'Wombat poop is cube-shaped, so it doesn’t roll away and can mark territory more effectively.',
  },
  {
    'tr':
        'Kaju fıstığı aslında bir meyvenin (kaju elması) en ucunda, meyvenin dışında yetişir; oldukça tuhaf bir görüntüsü vardır.',
    'en':
        'Cashews grow outside the cashew apple, hanging at the very end—an oddly surprising design.',
  },
  {
    'tr':
        "Köpekbalıkları, Satürn'ün halkalarından daha eskidir; Satürn o gösterişli halkalarını takınmadan milyonlarca yıl önce köpekbalıkları dünyadaydı.",
    'en':
        'Sharks are older than Saturn’s rings—they were around millions of years before Saturn got its famous bling.',
  },
  {
    'tr':
        'Kelebekler ayaklarıyla tat alırlar; bir yaprağın üzerine konduklarında aslında akşam yemeğinin tadına bakıyorlar.',
    'en':
        'Butterflies taste with their feet—when they land on a leaf, they’re basically sampling dinner.',
  },
  {
    'tr':
        'Bir salyangoz tam 3 yıl boyunca hiç uyanmadan uyuyabilir; bazen hepimizin buna ihtiyacı var.',
    'en':
        'A snail can sleep for up to three years without waking up—honestly, relatable.',
  },
  {
    'tr':
        'Deve kuşlarının gözleri beyinlerinden daha büyüktür; bakmakla görmek arasındaki o ince çizgide yaşıyorlar.',
    'en':
        'An ostrich’s eyes are bigger than its brain—living on the fine line between looking and thinking.',
  },
  {
    'tr':
        'Flamingolar aslında gri doğarlar; o meşhur pembe renklerini yedikleri karides ve alglerdeki pigmentlerden alırlar.',
    'en':
        'Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.',
  },
  {
    'tr':
        'Sincaplar her yıl binlerce yeni ağacın yetişmesine neden olur çünkü sakladıkları fındık ve cevizlerin yerini unuturlar.',
    'en':
        'Squirrels help grow thousands of new trees each year because they forget where they buried nuts.',
  },
  {
    'tr':
        "Uzayda oynanan ilk video oyunu Tetris'tir; 1993 yılında bir kozmonot tarafından Game Boy ile oynanmıştır.",
    'en':
        'The first video game played in space was Tetris—played on a Game Boy by a cosmonaut in 1993.',
  },
  {
    'tr':
        'Ağaçkakanlar beyin sarsıntısı geçirmemek için dillerini beyinlerinin etrafına sararlar; kask niyetine dil kullanmak oldukça yaratıcı bir çözüm.',
    'en':
        'Woodpeckers wrap their tongues around their brains to help avoid concussions—using your tongue as a helmet is a wild solution.',
  },
];

String _localizeDidYouKnowFact(String lang, Map<String, String> fact) {
  final String code = lang.trim().toLowerCase();
  final String tr = _repairDisplayText((fact['tr'] ?? '').trim());
  final String en = _repairDisplayText((fact['en'] ?? '').trim());
  if (tr.isEmpty && en.isEmpty) return '';
  if (code == 'tr') return tr.isNotEmpty ? tr : en;
  if (code == 'en') return en.isNotEmpty ? en : tr;

  final String? supplemental = localizeDidYouKnowPhrase(code, en);
  if (supplemental != null && supplemental.isNotEmpty) {
    final String repaired = _repairDisplayText(supplemental).trim();
    if (repaired.isNotEmpty && !_looksLikeMojibakeText(repaired)) {
      return repaired;
    }
  }

  final String repairedFallback = _repairDisplayText(localizeTrEn(code, tr, en)).trim();
  if (repairedFallback.isNotEmpty && !_looksLikeMojibakeText(repairedFallback)) {
    return repairedFallback;
  }
  return en;
}

class _ModernLoaderState extends State<ModernLoader> {
  final Random _factRand = Random();
  Timer? _factTimer;
  int _factIndex = 0;

  @override
  void initState() {
    super.initState();
    _startFactRotationIfNeeded();
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ModernLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress == null && widget.progress != null) {
      _startFactRotationIfNeeded();
    } else if (oldWidget.progress != null && widget.progress == null) {
      _factTimer?.cancel();
      _factTimer = null;
    }
  }

  void _startFactRotationIfNeeded() {
    if (widget.progress == null) return;
    if (_analysisDidYouKnowFacts.isEmpty) return;
    if (_factTimer != null) return;
    _factIndex = _factRand.nextInt(_analysisDidYouKnowFacts.length);
    _factTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      setState(() {
        _factIndex = (_factIndex + 1) % _analysisDidYouKnowFacts.length;
      });
    });
  }

  Widget _buildDidYouKnow(Color textColor) {
    if (widget.progress == null) return const SizedBox.shrink();
    if (_analysisDidYouKnowFacts.isEmpty) return const SizedBox.shrink();

    final String label = _didYouKnowLabelForLang(widget.lang);
    final Map<String, String> fact =
        _analysisDidYouKnowFacts[_factIndex % _analysisDidYouKnowFacts.length];
    final String body = _localizeDidYouKnowFact(widget.lang, fact);
    if (body.isEmpty) return const SizedBox.shrink();

    final Color panelBg = widget.isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.95);
    final Color panelBorder = widget.isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.blueGrey.withOpacity(0.14);
    final List<BoxShadow> panelShadow = widget.isDark
        ? const []
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ];

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: panelBorder, width: 1),
          boxShadow: panelShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFC13584)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.black.withOpacity(widget.isDark ? 0.35 : 0.12),
                  width: 0.8,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.05,
                  fontSize: 9,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: Text(
                body,
                key: ValueKey('${widget.lang}_$_factIndex'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningMascot({
    required double progress,
    required Color accent,
  }) {
    final double clamped = progress.clamp(0.0, 1.0);
    const double barHeight = 8;
    const double catWidth = 40;
    const double catHeight = 42;
    const double totalHeight = 62;
    const double barTop = 48;
    final Color catBase =
        widget.isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);

    return SizedBox(
      height: totalHeight,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: clamped),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, _) {
          final double p = animatedProgress.clamp(0.0, 1.0);
          return LayoutBuilder(builder: (context, constraints) {
            final double maxX = max(0.0, constraints.maxWidth - catWidth);
            final double x = (maxX * p).clamp(0.0, maxX);
            final double phase = (p * 16.0) % 1.0;
            final double bob = -1.1 * sin(phase * 2 * pi);
            final double tilt = 0.028 * sin(phase * 2 * pi);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: barTop,
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(widget.isDark ? 0.16 : 0.12),
                          accent.withOpacity(widget.isDark ? 0.06 : 0.03),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accent.withOpacity(widget.isDark ? 0.25 : 0.14),
                        width: 0.7,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: p,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.lerp(accent, Colors.white, 0.18) ??
                                    accent,
                                accent,
                                Color.lerp(accent, Colors.black, 0.12) ??
                                    accent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: accent
                                    .withOpacity(widget.isDark ? 0.45 : 0.30),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ProgressTrailParticlesPainter(
                        progress: p,
                        phase: phase,
                        catCenterX: x + (catWidth * 0.5),
                        barTop: barTop,
                        barHeight: barHeight,
                        accentColor: accent,
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: x,
                  top: barTop - catHeight + 1,
                  child: Transform.translate(
                    offset: Offset(0, bob),
                    child: Transform.rotate(
                      angle: tilt,
                      child: CustomPaint(
                        size: const Size(catWidth, catHeight),
                        painter: _CatWalkerPainter(
                          phase: phase,
                          baseColor: catBase,
                          accentColor: accent,
                          isDark: widget.isDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isDark ? Colors.white : Colors.blueGrey;
    final Color textColor =
        widget.isDark ? Colors.white : Colors.blueGrey.shade800;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.progress != null ? 24 : 34,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(color))),
            const SizedBox(height: 20),
            if (widget.text != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.blueGrey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(widget.text!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.35,
                      fontSize: 13,
                      shadows: widget.isDark
                          ? const [
                              Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 1))
                            ]
                          : null,
                    )),
              ),
            if (widget.progress != null) ...[
              const SizedBox(height: 15),
              Builder(builder: (context) {
                final double value = (widget.progress ?? 0.0).clamp(0.0, 1.0);
                final int percent =
                    value >= 1.0 ? 100 : min(99, (value * 100).round());
                final Color accent =
                    widget.isDark ? Colors.blueAccent : Colors.blue;
                return Column(
                  children: [
                    _buildRunningMascot(progress: value, accent: accent),
                    const SizedBox(height: 8),
                    Text(
                      "%$percent",
                      style: TextStyle(
                        color: (widget.isDark ? Colors.white : color)
                            .withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                );
              }),
              _buildDidYouKnow(textColor),
            ]
          ],
        ),
      ),
    );
  }
}

class _ProgressTrailParticlesPainter extends CustomPainter {
  final double progress;
  final double phase;
  final double catCenterX;
  final double barTop;
  final double barHeight;
  final Color accentColor;
  final bool isDark;

  const _ProgressTrailParticlesPainter({
    required this.progress,
    required this.phase,
    required this.catCenterX,
    required this.barTop,
    required this.barHeight,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    // Keep particles tighter and above the bar center so they stay distinct
    // from the percentage label while remaining clearly visible.
    final double centerY = barTop + (barHeight * 0.5) - 6.0;
    final double trailLength = min(catCenterX, 150.0);
    if (trailLength < 3) return;

    final double startX = max(0.0, catCenterX - trailLength);
    final Rect streakRect =
        Rect.fromLTWH(startX, centerY - 2.8, trailLength, 5.6);
    final Paint streak = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withOpacity(0.0),
          accentColor.withOpacity(isDark ? 0.40 : 0.30),
          accentColor.withOpacity(isDark ? 0.75 : 0.58),
        ],
        stops: const [0.0, 0.58, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(streakRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(streakRect, const Radius.circular(999)),
      streak,
    );

    final Rect glowRect =
        Rect.fromLTWH(startX, centerY - 8.5, trailLength, 17.0);
    final Paint glow = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withOpacity(0.0),
          accentColor.withOpacity(isDark ? 0.24 : 0.16),
          accentColor.withOpacity(isDark ? 0.46 : 0.34),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(glowRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, const Radius.circular(999)),
      glow,
    );

    for (int i = 0; i < 32; i++) {
      final double life = ((phase * 2.0) + (i * 0.097)) % 1.0;
      final double x = catCenterX - 8 - (life * trailLength) - ((i % 4) * 2.0);
      if (x < 0 || x > size.width) continue;

      final double y = centerY -
          2.8 +
          sin((phase * 2 * pi) + (i * 0.82)) * 2.9 +
          ((i % 5) - 2) * 0.78;
      final double radius = (1.0 - life) * (i.isEven ? 3.4 : 2.5);
      if (radius <= 0.12) continue;

      final double opacity =
          (1.0 - life) * (1.0 - life) * (isDark ? 0.95 : 0.80);
      final Color particleColor = Color.lerp(
        accentColor,
        Colors.white,
        0.38 + (0.12 * sin((i + 1) * 0.67).abs()),
      )!
          .withOpacity(opacity);

      final Paint particle = Paint()
        ..color = particleColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i.isEven ? 2.9 : 2.2);
      canvas.drawCircle(Offset(x, y), radius, particle);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressTrailParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.catCenterX != catCenterX ||
        oldDelegate.barTop != barTop ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}

class _CatWalkerPainter extends CustomPainter {
  final double phase;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;

  const _CatWalkerPainter({
    required this.phase,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
  });

  Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double t = phase % 1.0;
    final double walk = sin(t * 2 * pi);
    final double groundY = h - 4.0;

    final Color dark = _mix(baseColor, Colors.black, isDark ? 0.06 : 0.18);
    final Color light = _mix(baseColor, Colors.white, isDark ? 0.18 : 0.12);

    final Paint outline = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.40 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.30 : 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, groundY + 0.6),
        width: 16.0 + (2.0 * walk.abs()),
        height: 5.5,
      ),
      shadowPaint,
    );

    final Rect torsoRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.60),
      width: 12.2,
      height: 15.2,
    );
    final RRect torso =
        RRect.fromRectAndRadius(torsoRect, const Radius.circular(6.8));
    final Paint torsoPaint = Paint()
      ..shader = LinearGradient(
        colors: [light, dark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(torsoRect);
    canvas.drawRRect(torso, torsoPaint);
    canvas.drawRRect(torso, outline);

    final Offset headCenter = Offset(w * 0.53, 10.2);
    const double headRadius = 7.2;
    final Rect headRect =
        Rect.fromCircle(center: headCenter, radius: headRadius);
    final Paint headPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _mix(light, Colors.white, 0.10),
          _mix(dark, Colors.black, 0.06),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(headRect);
    canvas.drawCircle(headCenter, headRadius, headPaint);
    canvas.drawCircle(headCenter, headRadius, outline);

    final Path leftEar = Path()
      ..moveTo(headCenter.dx - 5.1, headCenter.dy - 4.2)
      ..lineTo(headCenter.dx - 2.8, headCenter.dy - 9.8)
      ..lineTo(headCenter.dx - 0.9, headCenter.dy - 4.2)
      ..close();
    final Path rightEar = Path()
      ..moveTo(headCenter.dx + 0.9, headCenter.dy - 4.2)
      ..lineTo(headCenter.dx + 2.8, headCenter.dy - 9.8)
      ..lineTo(headCenter.dx + 5.1, headCenter.dy - 4.2)
      ..close();
    canvas.drawPath(leftEar, headPaint);
    canvas.drawPath(rightEar, headPaint);
    canvas.drawPath(leftEar, outline);
    canvas.drawPath(rightEar, outline);

    final Paint nearEye = Paint()
      ..color = _mix(baseColor, Colors.white, isDark ? 0.14 : 0.07);
    final Paint farEye = Paint()
      ..color = _mix(baseColor, Colors.white, isDark ? 0.09 : 0.04);
    canvas.drawCircle(
        Offset(headCenter.dx + 2.0, headCenter.dy - 0.4), 1.0, nearEye);
    canvas.drawCircle(
        Offset(headCenter.dx + 0.2, headCenter.dy - 0.6), 0.56, farEye);

    final Rect snoutRect = Rect.fromCenter(
      center: Offset(headCenter.dx + 4.6, headCenter.dy + 1.2),
      width: 4.9,
      height: 4.2,
    );
    final Paint snoutPaint = Paint()..color = _mix(light, Colors.white, 0.15);
    canvas.drawOval(snoutRect, snoutPaint);
    canvas.drawOval(snoutRect, outline);

    final Paint nose = Paint()
      ..color = _mix(accentColor, Colors.white, 0.22).withOpacity(0.85);
    final Path nosePath = Path()
      ..moveTo(headCenter.dx + 5.2, headCenter.dy + 1.3)
      ..lineTo(headCenter.dx + 4.2, headCenter.dy + 2.2)
      ..lineTo(headCenter.dx + 5.8, headCenter.dy + 2.2)
      ..close();
    canvas.drawPath(nosePath, nose);

    final Paint whiskerPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.30 : 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(headCenter.dx + 5.8, headCenter.dy + 1.6),
      Offset(headCenter.dx + 8.2, headCenter.dy + 0.8),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(headCenter.dx + 5.7, headCenter.dy + 2.2),
      Offset(headCenter.dx + 8.4, headCenter.dy + 2.2),
      whiskerPaint,
    );

    final double armSwing = 1.9 * sin(t * 2 * pi);
    final Paint limbPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round;
    final Paint limbOutline = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.34 : 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final Offset shoulderLeft =
        Offset(torsoRect.left + 0.7, torsoRect.top + 3.8);
    final Offset shoulderRight =
        Offset(torsoRect.right - 0.7, torsoRect.top + 3.8);
    final Offset handLeft =
        Offset(shoulderLeft.dx - 1.4, torsoRect.center.dy + 2.0 + armSwing);
    final Offset handRight =
        Offset(shoulderRight.dx + 1.4, torsoRect.center.dy + 2.0 - armSwing);
    canvas.drawLine(shoulderLeft, handLeft, limbPaint);
    canvas.drawLine(shoulderRight, handRight, limbPaint);
    canvas.drawLine(shoulderLeft, handLeft, limbOutline);
    canvas.drawLine(shoulderRight, handRight, limbOutline);

    final double leftLift = max(0.0, walk);
    final double rightLift = max(0.0, -walk);
    final double hipY = torsoRect.bottom - 0.8;
    final Offset hipLeft = Offset(w * 0.50 - 3.4, hipY);
    final Offset hipRight = Offset(w * 0.50 + 3.4, hipY);
    final Offset footLeft = Offset(w * 0.50 - 3.9, groundY - (leftLift * 3.2));
    final Offset footRight =
        Offset(w * 0.50 + 3.9, groundY - (rightLift * 3.2));
    canvas.drawLine(hipLeft, footLeft, limbPaint);
    canvas.drawLine(hipRight, footRight, limbPaint);
    canvas.drawLine(hipLeft, footLeft, limbOutline);
    canvas.drawLine(hipRight, footRight, limbOutline);

    final Paint shoePaint = Paint()
      ..color = _mix(baseColor, Colors.black, isDark ? 0.16 : 0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: footLeft, width: 5.3, height: 2.0),
        const Radius.circular(999),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: footRight, width: 5.3, height: 2.0),
        const Radius.circular(999),
      ),
      shoePaint,
    );

    final double tailSwing = 2.1 * sin((t * 2 * pi) + (pi / 2));
    final Offset tailBase =
        Offset(torsoRect.left + 0.4, torsoRect.center.dy + 1.2);
    final Path tail = Path()
      ..moveTo(tailBase.dx, tailBase.dy)
      ..quadraticBezierTo(
        tailBase.dx - 7.5,
        tailBase.dy - 4.2 + tailSwing,
        tailBase.dx - 5.4,
        tailBase.dy - 8.2 + tailSwing,
      );
    final Paint tailPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tail, tailPaint);
    canvas.drawPath(tail, limbOutline);

    final double collarPulse = 0.34 + (0.14 * (0.5 + 0.5 * walk));
    final Paint collar = Paint()..color = accentColor.withOpacity(collarPulse);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, torsoRect.top + 1.7),
          width: 8.7,
          height: 2.0,
        ),
        const Radius.circular(999),
      ),
      collar,
    );
  }

  @override
  bool shouldRepaint(covariant _CatWalkerPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}

class SafeModeApp extends StatelessWidget {
  final String debugError;
  const SafeModeApp({super.key, this.debugError = ""});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFC13584),
          scaffoldBackgroundColor: const Color(0xFFFAFAFA)),
      home: BioPlannerScreen(debugError: debugError),
    );
  }
}

class BioPlannerScreen extends StatefulWidget {
  final String debugError;
  const BioPlannerScreen({super.key, required this.debugError});
  @override
  State<BioPlannerScreen> createState() => _BioPlannerScreenState();
}

class _BioPlannerScreenState extends State<BioPlannerScreen> {
  final TextEditingController _bioCtrl = TextEditingController();
  final Random _rand = Random();
  final List<String> _aiTemplates = [
    "Collecting moments, not things.",
    "Proof that small steps still move you forward.",
    "Soft light, loud dreams.",
    "Catching the in‑between.",
    "If you need me, I’m out chasing sunsets.",
    "Less perfection, more authenticity.",
    "Built on late nights and big ideas.",
    "My favorite color is the feeling of calm.",
    "Here for the journey, not the highlight reel.",
    "Choose progress over pressure.",
    "A little chaos, a lot of heart.",
    "Quiet confidence looks good on me.",
    "Making ordinary days feel cinematic.",
    "This is your sign to start.",
    "Woke up grateful, stayed focused.",
    "Dreams don’t work unless we do.",
    "Staying soft in a loud world.",
    "Find your pace, then enjoy it.",
    "Messy hair, clear goals.",
    "Small wins add up."
  ];

  final List<String> _popularHashtags = [
    "#photooftheday",
    "#instagood",
    "#aesthetic",
    "#vibes",
    "#explorepage",
    "#dailyinspo",
    "#mindset",
    "#selfgrowth",
    "#creative",
    "#lifestyle",
    "#minimalism",
    "#goodenergy"
  ];

  void _generateAiCaption() {
    _bioCtrl.text = _aiTemplates[_rand.nextInt(_aiTemplates.length)];
  }

  @override
  Widget build(BuildContext context) {
    final String langCode =
        Platform.localeName.toLowerCase().split(RegExp(r'[_-]')).first.trim();
    return Scaffold(
      appBar: AppBar(
        title:
            Text(localizeTrEn(langCode, 'Biyografi Planlayıcı', 'Bio Planner')),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F7FB), Color(0xFFEFEFF7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Caption Generator",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Tap generate for a fresh caption in seconds.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _bioCtrl,
                      maxLength: 150,
                      decoration: InputDecoration(
                        hintText: "Your caption will appear here...",
                        counterText: "",
                        filled: true,
                        fillColor: const Color(0xFFF7F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _generateAiCaption,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Generate",
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Popular Hashtags",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Updated every 24 hours",
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularHashtags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F3F7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final GlobalKey<ScaffoldMessengerState> _diagScaffoldKey =
    GlobalKey<ScaffoldMessengerState>();

Color _appSnackColorForTone({
  required bool isDark,
  String tone = 'info',
}) {
  switch (tone) {
    case 'error':
      return isDark ? const Color(0xFF7C2D3C) : const Color(0xFFB34A61);
    case 'success':
      return isDark ? const Color(0xFF1F6A49) : const Color(0xFF2E7D32);
    case 'warn':
      return isDark ? const Color(0xFF7A5B24) : const Color(0xFFAF8235);
    default:
      return isDark ? const Color(0xFF2C4B63) : const Color(0xFF3F5F7A);
  }
}

SnackBarThemeData _appSnackBarTheme({required bool isDark}) {
  return SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: _appSnackColorForTone(isDark: isDark),
    elevation: isDark ? 10 : 7,
    insetPadding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: isDark
            ? Colors.white.withOpacity(0.14)
            : Colors.white.withOpacity(0.22),
        width: 1,
      ),
    ),
    contentTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      height: 1.28,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(isDark ? 0.58 : 0.40),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    actionTextColor: isDark ? const Color(0xFFB7D9FF) : const Color(0xFFD6E8FF),
  );
}

class UnfollowersApp extends StatelessWidget {
  const UnfollowersApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _diagScaffoldKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        snackBarTheme: _appSnackBarTheme(isDark: false),
      ),
      home: const DashboardScreen(),
    );
  }
}

class _StoryProfile {
  final String username;
  final String imageUrl;
  final bool isBlurred;
  final bool hasStory;
  final String? pk;
  const _StoryProfile(
      {required this.username,
      required this.imageUrl,
      this.isBlurred = false,
      this.hasStory = false,
      this.pk});
}

class StoryItem {
  final String url;
  final bool isVideo;
  StoryItem({required this.url, required this.isVideo});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Map<String, String> followersMap = {},
      followingMap = {},
      nonFollowersMap = {},
      unfollowersMap = {},
      newFollowersMap = {},
      leftFollowingMap = {};

  Map<String, int> badges = {
    'followers': 0,
    'following': 0,
    'new_followers': 0,
    'non_followers': 0,
    'left_followers': 0,
    'left_following': 0,
  };

  Map<String, Set<String>> newItemsMap = {
    'followers': {},
    'following': {},
    'new_followers': {},
    'non_followers': {},
    'left_followers': {},
    'left_following': {},
  };

  bool _hasAnalyzed = false;

  String followersCount = '?',
      followingCount = '?',
      nonFollowersCount = '?',
      leftCount = '?',
      newCount = '?',
      leftFollowingCount = '?';
  bool isLoggedIn = false, isProcessing = false, isDarkMode = false;
  bool _isClearingData = false;
  double _progressValue = 0.0;
  double _progressTarget = 0.0;
  DateTime? _progressFinishEndAt;
  DateTime? _analysisStartedAt;
  Timer? _analysisProgressTimelineTimer;
  DateTime? _analysisProgressTimelineStartAt;
  double _analysisProgressCap = 0.0;

  String currentUsername = "";
  String? savedCookie, savedUserId, savedUserAgent;

  Duration? _remainingToNextAnalysis;
  Timer? _countdownTimer;
  Timer? _legalHoldTimer;
  Timer? _consentWatchTimer;
  Timer? _storyAutoTimer;
  Timer? _progressPumpTimer;
  int _consentWatchTries = 0;

  static const List<String> _supportedLanguageCodes = <String>[
    'tr',
    'en',
    'de',
    'ko',
    'ja',
    'ru',
    'pt',
    'ar',
    'es',
    'es-mx',
    'hi',
    'hu',
    'zh-hans',
    'id',
    'nl',
    'fr',
    'it',
    'vi',
    'th',
    'pl',
  ];

  static const Map<String, String> _languageNativeNames = <String, String>{
    'tr': 'T\u00fcrk\u00e7e',
    'en': 'English',
    'de': 'Deutsch',
    'ko': '\ud55c\uad6d\uc5b4',
    'ja': '\u65e5\u672c\u8a9e',
    'ru': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
    'pt': 'Portugu\u00eas',
    'ar': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
    'es': 'Espa\u00f1ol (Espa\u00f1a)',
    'es-mx': 'Espa\u00f1ol (M\u00e9xico)',
    'hi': '\u0939\u093f\u0928\u094d\u0926\u0940',
    'hu': 'Magyar',
    'zh-hans': '\u7b80\u4f53\u4e2d\u6587',
    'id': 'Bahasa Indonesia',
    'nl': 'Nederlands',
    'fr': 'Fran\u00e7ais',
    'it': 'Italiano',
    'vi': 'Ti\u1ebfng Vi\u1ec7t',
    'th': '\u0e44\u0e17\u0e22',
    'pl': 'Polski',
  };
  static const Map<String, String> _languageFlags = <String, String>{
    'tr': '\u{1F1F9}\u{1F1F7}',
    'en': '\u{1F1FA}\u{1F1F8}',
    'de': '\u{1F1E9}\u{1F1EA}',
    'ko': '\u{1F1F0}\u{1F1F7}',
    'ja': '\u{1F1EF}\u{1F1F5}',
    'ru': '\u{1F1F7}\u{1F1FA}',
    'pt': '\u{1F1F5}\u{1F1F9}',
    'ar': '\u{1F1F8}\u{1F1E6}',
    'es': '\u{1F1EA}\u{1F1F8}',
    'es-mx': '\u{1F1F2}\u{1F1FD}',
    'hi': '\u{1F1EE}\u{1F1F3}',
    'hu': '\u{1F1ED}\u{1F1FA}',
    'zh-hans': '\u{1F1E8}\u{1F1F3}',
    'id': '\u{1F1EE}\u{1F1E9}',
    'nl': '\u{1F1F3}\u{1F1F1}',
    'fr': '\u{1F1EB}\u{1F1F7}',
    'it': '\u{1F1EE}\u{1F1F9}',
    'vi': '\u{1F1FB}\u{1F1F3}',
    'th': '\u{1F1F9}\u{1F1ED}',
    'pl': '\u{1F1F5}\u{1F1F1}',
  };

  String _lang = 'tr';

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _bannerAdError;
  String? _googleAdWarning;
  bool _adsHidden = false;
  bool _removeAllAds = false;
  bool _remoteFlagsLoaded = false;
  bool _privacyOptionsRequired = false;
  String _announcementText = "";

  bool _justWatchedReward = false;
  bool _isRewardedLoading = false;
  bool _isBanned = false;
  bool _isAdminUser = false;
  String? _lastIgWarning;
  bool _securityGuideVisible = false;
  bool _igWarningVisible = false;
  final ValueNotifier<List<String>> _firebaseDiagnosticEvents =
      ValueNotifier<List<String>>(<String>[]);
  static const int _maxFirebaseDiagnosticEvents = 280;
  bool _criticalDiagnosticVisible = false;
  String? _lastCriticalDiagnosticFingerprint;
  DateTime? _lastCriticalDiagnosticAt;
  String _lastObservedPurchaseError = '';

  static const bool _forceTestAds = false;
  static const Duration _igRequestTimeout = Duration(seconds: 12);
  static const Duration _igRetryBaseDelay = Duration(milliseconds: 900);
  static const Duration _firestoreAuthTimeout = Duration(seconds: 12);
  static const Duration _firestoreRestTimeout = Duration(seconds: 12);
  static const String _networkTimeOffsetKey = 'network_time_offset_ms';
  int? _networkTimeOffsetMs;

  Future<void> _igRequestChain = Future.value();
  DateTime? _igLastIgRequestAt;
  int _igPageRequestCounter = 0;

  final Random _storyRand = Random();
  String _rateUrlAndroid = "";
  String _rateUrlIos = "";
  late final ScrollController _storyScrollController;
  Set<String> _storyUsersWithActive = {};
  Map<String, String> _storyUserPks = {};
  Map<String, String> _storyUserPics = {};
  Map<String, int> _storyActiveOrderIndex = {};
  bool _isStoryTrayLoading = false;
  bool _storyTrayRefreshQueued = false;
  bool _watchStoriesEnabled = false;
  bool _isPremium = false;

  bool get _adsDisabled => _adsHidden || _removeAllAds || _isPremium;

  Future<void> _loadStoryTray() async {
    if (isProcessing) {
      _storyTrayRefreshQueued = true;
      return;
    }
    if (!isLoggedIn || savedCookie == null || _isStoryTrayLoading) return;
    _storyTrayRefreshQueued = false;
    if (mounted) {
      setState(() => _isStoryTrayLoading = true);
    } else {
      _isStoryTrayLoading = true;
    }
    try {
      await _refreshSessionCookieFromWebViewStore(updateUserId: false);
      final String ua = _resolveUserAgent();
      final bool preferWeb = _preferWebApi(ua);
      final String appUa =
          ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;
      final String? dsUserIdHeader =
          _resolveSessionDsUserId(savedUserId, savedCookie);

      Future<http.Response> fetchWeb() => _igGet(
            Uri.parse("https://www.instagram.com/api/v1/feed/reels_tray/"),
            headers: _buildWebHeaders(savedCookie!, ua,
                dsUserId: dsUserIdHeader),
            minGap: const Duration(milliseconds: 420),
            jitterMaxMs: 360,
          );
      Future<http.Response> fetchApp() => _igGet(
            Uri.parse("https://i.instagram.com/api/v1/feed/reels_tray/"),
            headers: _buildAppHeaders(savedCookie!, appUa,
                dsUserId: dsUserIdHeader),
            minGap: const Duration(milliseconds: 420),
            jitterMaxMs: 360,
          );

      http.Response response;
      if (preferWeb) {
        response = await fetchWeb();
        if (response.statusCode != 200) response = await fetchApp();
      } else {
        response = await fetchApp();
        if (response.statusCode != 200) response = await fetchWeb();
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          return;
        }
        if (decoded is! Map) return;
        final Map data = decoded;
        final String? security = _detectIgSecurityBlockFromMap(data);
        if (security != null) return;

        final List tray =
            data['tray'] is List ? (data['tray'] as List) : const [];
        final Set<String> active = {};
        final Map<String, String> pks = {};
        final Map<String, String> pics = {};
        final Map<String, int> orderIndex = {};
        int order = 0;

        for (var t in tray) {
          if (t is! Map) continue;
          final user = t['user'];
          if (user is! Map) continue;
          final String unameRaw = user['username']?.toString().trim() ?? '';
          if (unameRaw.isEmpty) continue;
          final String uname = unameRaw.toLowerCase();

          active.add(uname);
          orderIndex.putIfAbsent(uname, () => order++);
          final String pk = user['pk']?.toString().trim() ?? '';
          if (pk.isNotEmpty) pks[uname] = pk;

          final String pic = _extractBestProfilePhotoUrlFromUser(user) ?? '';
          if (pic.isNotEmpty) pics[uname] = pic;
        }
        if (mounted) {
          setState(() {
            _storyUsersWithActive = active;
            _storyUserPks = pks;
            _storyUserPics = pics;
            _storyActiveOrderIndex = orderIndex;
          });
        } else {
          _storyUsersWithActive = active;
          _storyUserPks = pks;
          _storyUserPics = pics;
          _storyActiveOrderIndex = orderIndex;
        }
      }
    } catch (e) {
      debugPrint("Story tray load error: $e");
    } finally {
      if (mounted) {
        setState(() => _isStoryTrayLoading = false);
      } else {
        _isStoryTrayLoading = false;
      }
    }
  }

  Set<String> _bannedUsers = {};
  Set<String> _removeAdsUsers = {};

  final Map<String, Map<String, String>> _localized = {
    'tr': {
      'tagline': 'Sosyal medya için profesyonel çözümler',
      'adsense_banner': 'REKLAM ALANI',
      'admin_active_note': 'Y\u00F6netici Modu Aktif',
      'free_app_note':
          'Size daha iyi bir deneyim sunmak için her gün gelişiyoruz. Görüşleriniz bizim için değerli, geri bildirimlerinizi bekliyoruz!',
      'login_prompt': 'Analizi başlatmak için lütfen giriş yapın.',
      'welcome': 'Hoş geldiniz, {username}',
      'refresh_data': 'VERİLERİ GÜNCELLE',
      'login_with_instagram': 'INSTAGRAM İLE GİRİŞ YAP',
      'fetching_data':
          'Veriler analiz ediliyor...\nBu işlem biraz sürebilir.',
      'processing_data': 'Veriler işleniyor...\nNeredeyse bitti.',
      'loading_ad': 'Reklam yükleniyor...\nLütfen bekleyin.',
      'google_ad_warning': 'Google reklam uyarısı: {reason}',
      'analysis_secure':
          'Tüm analizler güvenli şekilde yalnızca cihazınızda işlenir.',
      'today_total_analysis': 'Bugün yapılan toplam analiz: {count}',
      'purchases_not_configured':
          'Satın alma sistemi hazır değil. Lütfen daha sonra tekrar deneyin.',
      'premium_not_active':
          'Satın alma tamamlandı ancak Premium aktif görünmüyor. Lütfen tekrar deneyin.',
      'premium_welcome_box':
          'Premium\'a hoş geldiniz! Reklamlar ve bekleme süreleri kaldırıldı.',
      'premium_already_active': 'Premium üyeliğiniz aktif.',
      'restore_purchases': 'Satın Alımları Geri Yükle',
      'restore_purchases_short': 'GERİ YÜKLE',
      'restoring_purchases': 'Satın alımlar geri yükleniyor...',
      'restore_purchases_success': 'Satın alımlar geri yüklendi ✅',
      'restore_purchases_none': 'Geri yüklenecek satın alım bulunamadı.',
      'restore_purchases_failed': 'Geri yükleme başarısız: {err}',
      'next_analysis': 'Sonraki analiz',
      'next_analysis_ready': 'Analiz şimdi hazır.',
      'analysis_available_now': 'Analiz şu anda kullanılabilir.',
      'analysis_ready_risk':
          'Analiz şimdi hazır; ancak art arda analiz yapmak hesabınızı riske atabilir.',
      'please_wait': 'Lütfen bekleyin',
      'warning': 'Uyarı',
      'remaining_time': 'Kalan süre: {time}',
      'watch_ad': 'REKLAM İZLE VE ANALİZİ BAŞLAT',
      'start_analysis': 'ANALİZİ BAŞLAT',
      'start_analysis_question': 'Analiz başlatılsın mı?',
      'clear_data_title': 'Veri Sıfırlama',
      'clear_data_content':
          'Tüm yerel veriler ve oturum bilgileri silinecektir. Emin misiniz?',
      'cancel': 'İPTAL',
      'delete': 'SİL',
      'error_title': 'HATA',
      'data_fetch_error':
          'Veri alınamadı: {err}\n\nÖneri: Çıkış yapıp tekrar giriş yapmayı deneyin.',
      'followers': 'Takipçiler',
      'following': 'Takip Ettiklerin',
      'new_followers': 'Yeni Takipçiler',
      'non_followers': 'Geri Takip Etmeyenler',
      'left_followers': 'Takibi Bırakanlar',
      'left_following': 'Takibi B\u0131rakt\u0131klar\u0131m',
      'legal_warning': 'Yasal Uyarı',
      'rate_us': 'Bizi Puanla',
      'contact_us': 'Bize Ula\u015f\u0131n',
      'remove_ads_and_limits': 'Reklamları ve bekleme sürelerini kaldır',
      'rate_test_message': 'Bu kutucuk şu anda test aşamasındadır.',
      'story_section_title':
          'Hikayeleri gizlice izle veya profil fotoğraflarını büyüt',
      'story_login_required':
          'Hikayeleri gizlice izleyebilmemiz için geçerli bir Instagram oturumu gerekiyor. Giriş yaptıktan sonra da bu uyarıyı görüyorsanız Instagram hesabınızdan çıkış yapıp tekrar giriş yapın.',
      'story_ad_wait': 'Reklamdan sonra gösterilecek. Lütfen bekleyin.',
      'story_action_title': 'Ne yapmak istersiniz?',
      'story_view_photo': 'Profil fotoğrafını büyüt',
      'story_watch_secret': 'Gizlice hikayeyi izle',
      'story_no_data': 'Hikaye verisi bulunamadı.',
      'story_close': 'KAPAT',
      'read_and_agree': 'OKUDUM VE KABUL EDİYORUM',
      'withdraw_consent': 'Rızayı Geri Al',
      'withdraw_consent_confirm_title': 'Onay',
      'withdraw_consent_confirm_body':
          'Rıza ayarları sıfırlanacak. Emin misiniz?',
      'withdraw_consent_confirm_yes': 'Evet',
      'withdraw_consent_confirm_no': 'Vazgeç',
      'no_data': 'Veri yok',
      'new_badge': 'YENİ',
      'login_title': 'Giriş Yap',
      'user_label': 'Kullan\u0131c\u0131',
      'redirecting': 'Oturum doğrulandı, yönlendiriliyorsunuz...',
      'data_updated': 'Analiz tamamlandı ✅',
      'enter_pin': 'PIN giriniz',
      'pin_accepted': 'PIN kabul edildi, süre sıfırlandı ✅',
      'pin_incorrect': 'Yanlış PIN',
      'ok': 'TAMAM',
      'legal_intro':
          'Bu uygulamayı indiren ve kullanan her Kullanıcı, aşağıdaki "Kullanım Koşulları ve Feragatname" metnini okumuş, anlamış ve hükümlerini kabul etmiş sayılır:',
      'article1_title': 'Madde 1: Veri Gizliliği ve Yerel İşleme Mimarisi',
      'article1_text':
          "VERDICT, istemci tarafında çalışan bir yazılımdır. Kullanıcının giriş bilgileri (kullanıcı adı, şifre, oturum çerezleri) hiçbir surette harici bir sunucuya iletilmez veya depolanmaz. Tüm veri işleme faaliyetleri yalnızca kullanıcının cihazının geçici belleğinde ve yerel depolama alanında gerçekleşir. Uygulama, Instagram arayüzü üzerinde çalışan bir tarayıcı katmanı olarak işlev görür.",
      'article2_title': 'Madde 2: Üçüncü Taraf Platform Riskleri',
      'article2_text':
          "Instagram (Meta Platforms, Inc.), platform politikaları gereği üçüncü taraf yazılımların kullanımını kısıtlama hakkını saklı tutar. Uygulamanın kullanımına bağlı olarak gelişebilecek işlem engeli, hesap kısıtlaması, gölge yasaklama veya hesap kapatılması dahil ancak bunlarla sınırlı olmamak üzere tüm riskler münhasıran Kullanıcıya aittir. VERDICT geliştiricisi, bu tür idari yaptırımlardan dolayı doğabilecek doğrudan veya dolaylı zararlardan sorumlu tutulamaz.",
      'article3_title': 'Madde 3: Garanti Feragatnamesi ve Sorumluluk Reddi',
      'article3_text':
          "İşbu yazılım, olduğu gibi ve mevcut haliyle sunulmaktadır. Yazılımın sağladığı analiz sonuçlarının %100 kesinliği, sürekliliği veya ticari elverişliliği garanti edilmez. Kullanıcı, uygulama verilerine dayanarak gerçekleştireceği hukuki veya ticari işlemlerden doğabilecek sonuçların kendi sorumluluğunda olduğunu; geliştiriciyi her türlü talep, dava ve şikayetten ari tutacağını beyan ve taahhüt eder.",
      'article4_title': 'Madde 4: Fikri Mülkiyet ve Bağımsızlık Bildirimi',
      'article4_text':
          "VERDICT, bağımsız bir geliştirici projesidir. 'Instagram', 'Facebook' ve 'Meta' markaları Meta Platforms, Inc.'in tescilli ticari markalarıdır. Bu uygulamanın söz konusu şirketlerle herhangi bir ticari ortaklığı, sponsorluk anlaşması veya resmi bağlantısı bulunmamaktadır.",
      'article5_title':
          'Madde 5: Hizmet Sürekliliği ve Platform Değişiklikleri',
      'article5_text':
          "Instagram API’sinde veya web altyapısında meydana gelebilecek köklü değişiklikler, uygulamanın işlevselliğini kısmen veya tamamen yitirmesine neden olabilir. Geliştirici, mücbir sebep kapsamında değerlendirilen bu tür altyapısal değişikliklere bağlı olarak uygulamayı güncelleme veya hizmeti sürdürme konusunda herhangi bir taahhütte bulunmamaktadır.",
      'ad_wait_message':
          'Analiz tamamlandı, sonuçlar reklamdan sonra gösterilecek.',
      'analysis_failed_title': 'Analiz yapılamadı',
      'analysis_failed_reason': 'Neden: {reason}',
      'analysis_failed_hint':
          'İpucu: Çıkış yapıp yeniden giriş yapmak işe yarayabilir.',
      'analysis_fast_no_change': 'Hızlı kontrol: Değişiklik bulunamadı.',
      'usage_metrics_title': 'Günlük Veriler',
      'usage_metrics_active': 'Aktif kullanıcı',
      'usage_metrics_queries': 'Günlük sorgu sayısı',
      'usage_metrics_na': '--',
      'usage_metrics_live': 'canlı'
    },
    'en': {
      'tagline': 'Professional Social Media Solutions',
      'adsense_banner': 'AD SPACE',
      'admin_active_note': 'Admin mode active',
      'free_app_note':
          'We are evolving every day to provide you with a better experience. Your feedback is valuable to us—we’d love to hear from you!',
      'login_prompt': 'Please log in to start the analysis.',
      'welcome': 'Welcome, {username}',
      'refresh_data': 'REFRESH DATA',
      'login_with_instagram': 'LOG IN WITH INSTAGRAM',
      'fetching_data': 'Analyzing data...\nThis might take a moment.',
      'processing_data': 'Processing data...\nAlmost done.',
      'loading_ad': 'Loading ad...\nPlease wait.',
      'google_ad_warning': 'Google ad warning: {reason}',
      'analysis_secure':
          'All analysis is securely processed locally on your device.',
      'today_total_analysis': 'Total analyses today: {count}',
      'next_analysis': 'Next analysis',
      'next_analysis_ready': 'Ready to scan.',
      'analysis_available_now': 'Analysis available now',
      'analysis_ready_risk':
          'Analysis is available now, but running analyses back-to-back may put your account at risk.',
      'please_wait': 'Please wait',
      'warning': 'Warning',
      'remaining_time': 'Next analysis: {time}',
      'watch_ad': 'WATCH AD AND START ANALYSIS',
      'start_analysis': 'START ANALYSIS',
      'start_analysis_question': 'Start analysis?',
      'clear_data_title': 'Reset App Data',
      'clear_data_content':
          'This will wipe all local data and session cookies. Are you sure?',
      'cancel': 'CANCEL',
      'delete': 'DELETE',
      'error_title': 'Error',
      'data_fetch_error':
          'Data retrieval failed: {err}\n\nTroubleshoot: Try logging out and logging back in.',
      'followers': 'Followers',
      'following': 'Following',
      'new_followers': 'New Followers',
      'non_followers': 'Not Following Back',
      'left_followers': 'Lost Followers',
      'legal_warning': 'Legal Disclaimer',
      'left_following': 'Unfollowed Users',
      'rate_us': 'Rate Us',
      'contact_us': 'Contact Us',
      'remove_ads_and_limits':
          'Remove Ads & Wait Times',
      'rate_test_message': 'This box is currently under test.',
      'story_section_title': 'Watch Stories Secretly or Zoom Profile Photos',
      'story_login_required': 'A valid Instagram login is required to view stories privately. If you are already logged in and still see this warning, log out of Instagram and log in again.',
      'story_ad_wait': 'Will be shown after the ad, please wait.',
      'story_action_title': 'What would you like to do?',
      'story_view_photo': 'Enlarge profile photo',
      'story_watch_secret': 'Watch story secretly',
      'story_no_data': 'No story data available.',
      'story_close': 'CLOSE',
      'read_and_agree': 'I HAVE READ AND AGREE',
      'withdraw_consent': 'Withdraw Consent',
      'withdraw_consent_confirm_title': 'Confirm',
      'withdraw_consent_confirm_body':
          'Your consent settings will be reset. Are you sure?',
      'withdraw_consent_confirm_yes': 'Yes',
      'withdraw_consent_confirm_no': 'Cancel',
      'no_data': 'No data',
      'new_badge': 'NEW',
      'login_title': 'Login',
      'user_label': 'User',
      'redirecting': 'Session verified, redirecting securely...',
      'data_updated': 'Analysis complete ✅',
      'purchases_not_configured':
          'Purchases are not available right now. Please try again later.',
      'premium_not_active':
          'Purchase completed, but Premium is not active yet. Please try again.',
      'premium_welcome_box':
          'Welcome to Premium! Ads and wait times are removed.',
      'premium_already_active': 'Your Premium membership is active.',
      'restore_purchases': 'Restore Purchases',
      'restore_purchases_short': 'RESTORE',
      'restoring_purchases': 'Restoring purchases...',
      'restore_purchases_success': 'Purchases restored ✅',
      'restore_purchases_none': 'No purchases to restore.',
      'restore_purchases_failed': 'Restore failed: {err}',
      'enter_pin': 'Enter PIN',
      'pin_accepted': 'PIN accepted, timer reset ✅',
      'pin_incorrect': 'Invalid PIN',
      'ok': 'OK',
      'legal_intro':
          'By downloading and using this application, every User is deemed to have read, understood, and irrevocably accepted the "Terms of Use and Disclaimer" text below in advance:',
      'article1_title':
          'Article 1: Data Privacy and Local Processing Architecture',
      'article1_text':
          "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.",
      'article2_title': 'Article 2: Third-Party Platform Risks',
      'article2_text':
          "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.",
      'article3_title':
          'Article 3: Warranty Disclaimer and Limitation of Liability',
      'article3_text':
          "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.",
      'article4_title':
          'Article 4: Intellectual Property and Independence Notice',
      'article4_text':
          "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.",
      'article5_title': 'Article 5: Service Continuity and Platform Changes',
      'article5_text':
          'Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered "force majeure".',
      'ad_wait_message':
          'Analysis complete, results will be shown after the ad.',
      'analysis_failed_title': 'Analysis failed',
      'analysis_failed_reason': 'Reason: {reason}',
      'analysis_failed_hint': 'Tip: Logging out and logging back in may help.',
      'analysis_fast_no_change':
          'Quick check: Counts are the same. No changes detected.',
      'usage_metrics_title': 'Daily Metrics',
      'usage_metrics_active': 'Active users',
      'usage_metrics_queries': 'Daily queries',
      'usage_metrics_na': '--',
      'usage_metrics_live': 'live panel'
    },
    'de': {
      'tagline': 'Professionelle Social-Media-Lösungen',
      'admin_active_note': 'Admin-Modus aktiv',
      'free_app_note':
          'Wir entwickeln uns täglich weiter, um dir ein besseres Erlebnis zu bieten. Dein Feedback ist uns wichtig.',
      'login_prompt': 'Bitte melde dich an, um die Analyse zu starten.',
      'welcome': 'Willkommen, {username}',
      'refresh_data': 'DATEN AKTUALISIEREN',
      'login_with_instagram': 'MIT INSTAGRAM ANMELDEN',
      'fetching_data': 'Daten werden analysiert...\nDas kann kurz dauern.',
      'processing_data': 'Daten werden verarbeitet...\nFast fertig.',
      'loading_ad': 'Anzeige wird geladen...\nBitte warten.',
      'google_ad_warning': 'Google-Warnung zur Werbung: {reason}',
      'analysis_secure':
          'Alle Analysen werden sicher lokal auf deinem Gerät verarbeitet.',
      'today_total_analysis': 'Analysen heute insgesamt: {count}',
      'purchases_not_configured':
          'Käufe sind derzeit nicht verfügbar. Bitte später erneut versuchen.',
      'premium_already_active': 'Deine Premium-Mitgliedschaft ist aktiv.',
      'premium_welcome_box':
          'Willkommen bei Premium! Werbung und Wartezeiten wurden entfernt.',
      'restore_purchases': 'Käufe wiederherstellen',
      'restore_purchases_short': 'WIEDERHERSTELLEN',
      'restoring_purchases': 'Käufe werden wiederhergestellt...',
      'restore_purchases_success': 'Käufe wiederhergestellt ✅',
      'restore_purchases_none': 'Keine Käufe zum Wiederherstellen gefunden.',
      'restore_purchases_failed': 'Wiederherstellung fehlgeschlagen: {err}',
      'next_analysis': 'Nächste Analyse',
      'next_analysis_ready': 'Analyse ist jetzt verfügbar.',
      'analysis_ready_risk':
          'Eine Analyse ist jetzt möglich, aber Analysen direkt hintereinander können dein Konto gefährden.',
      'please_wait': 'Bitte warten',
      'remaining_time': 'Verbleibende Zeit: {time}',
      'watch_ad': 'WERBUNG ANSEHEN UND ANALYSE STARTEN',
      'start_analysis': 'ANALYSE STARTEN',
      'start_analysis_question': 'Analyse starten?',
      'clear_data_title': 'App-Daten zurücksetzen',
      'clear_data_content':
          'Alle lokalen Daten und Sitzungsinformationen werden gelöscht. Bist du sicher?',
      'cancel': 'ABBRECHEN',
      'delete': 'LÖSCHEN',
      'ad_wait_message':
          'Analyse abgeschlossen, Ergebnisse werden nach der Werbung angezeigt.',
      'analysis_failed_title': 'Analyse fehlgeschlagen',
      'analysis_failed_reason': 'Grund: {reason}',
      'analysis_failed_hint': 'Tipp: Abmelden und erneut anmelden kann helfen.',
      'story_section_title':
          'Stories heimlich ansehen oder Profilfotos vergrößern',
      'story_login_required':
          'Zum anonymen Ansehen von Stories ist eine gültige Instagram-Anmeldung erforderlich. Wenn du bereits eingeloggt bist und diese Warnung weiter siehst, melde dich bei Instagram ab und wieder an.',
      'story_ad_wait': 'Wird nach der Werbung angezeigt, bitte warten.',
      'story_action_title': 'Was möchtest du tun?',
      'story_view_photo': 'Profilfoto vergrößern',
      'story_watch_secret': 'Story heimlich ansehen',
      'story_no_data': 'Keine Story-Daten gefunden.',
      'story_close': 'SCHLIESSEN',
      'no_data': 'Keine Daten',
      'new_badge': 'NEU',
      'login_title': 'Anmelden',
      'read_and_agree': 'ICH HABE GELESEN UND STIMME ZU',
      'withdraw_consent': 'Einwilligung zurückziehen',
      'withdraw_consent_confirm_title': 'Bestätigen',
      'withdraw_consent_confirm_body':
          'Deine Einwilligungseinstellungen werden zurückgesetzt. Bist du sicher?',
      'withdraw_consent_confirm_yes': 'Ja',
      'withdraw_consent_confirm_no': 'Abbrechen',
      'data_updated': 'Analyse abgeschlossen ✅',
      'enter_pin': 'PIN eingeben',
      'pin_accepted': 'PIN akzeptiert, Zeit zurückgesetzt ✅',
      'pin_incorrect': 'Falsche PIN',
      'ok': 'OK',
      'legal_warning': 'Rechtlicher Hinweis',
      'rate_us': 'Bewerte uns',
      'contact_us': 'Kontakt',
      'remove_ads_and_limits': 'Werbung und Wartezeiten entfernen',
      'left_followers': 'Entfolger',
      'legal_intro':
          'Durch das Herunterladen und die Nutzung dieser App gilt der Nutzer als informiert und einverstanden.',
      'user_label': 'Nutzer',
    },
    'ko': {
      'tagline': '전문 소셜 미디어 솔루션',
      'admin_active_note': '관리자 모드 활성화',
      'free_app_note':
          '더 나은 경험을 위해 매일 개선하고 있습니다. 여러분의 피드백은 매우 소중합니다.',
      'login_prompt': '분석을 시작하려면 로그인해 주세요.',
      'welcome': '환영합니다, {username}',
      'refresh_data': '데이터 새로고침',
      'login_with_instagram': '인스타그램으로 로그인',
      'fetching_data':
          '데이터를 분석하는 중...\n잠시만 기다려 주세요.',
      'processing_data':
          '데이터 처리 중...\n거의 완료되었습니다.',
      'loading_ad': '광고 로딩 중...\n잠시만 기다려 주세요.',
      'google_ad_warning': 'Google 광고 경고: {reason}',
      'analysis_secure':
          '모든 분석은 기기에서 안전하게 로컬 처리됩니다.',
      'today_total_analysis': '오늘 총 분석 수: {count}',
      'purchases_not_configured':
          '현재 구매 기능을 사용할 수 없습니다. 나중에 다시 시도해 주세요.',
      'premium_already_active':
          '프리미엄 멤버십이 활성화되어 있습니다.',
      'premium_welcome_box':
          '프리미엄에 오신 것을 환영합니다! 광고와 대기 시간이 제거되었습니다.',
      'restore_purchases': '구매 복원',
      'restore_purchases_short': '\uBCF5\uC6D0',
      'restoring_purchases': '구매 복원 중...',
      'restore_purchases_success': '구매가 복원되었습니다 ✅',
      'restore_purchases_none': '복원할 구매 내역이 없습니다.',
      'restore_purchases_failed': '복원 실패: {err}',
      'next_analysis': '다음 분석',
      'next_analysis_ready': '지금 분석할 수 있습니다.',
      'analysis_ready_risk':
          '지금 분석이 가능하지만, 연속 분석은 계정에 위험할 수 있습니다.',
      'please_wait': '잠시만 기다려 주세요',
      'remaining_time': '남은 시간: {time}',
      'watch_ad': '광고 시청 후 분석 시작',
      'start_analysis': '분석 시작',
      'start_analysis_question': '분석을 시작할까요?',
      'clear_data_title': '앱 데이터 초기화',
      'clear_data_content':
          '모든 로컬 데이터와 세션 정보가 삭제됩니다. 계속할까요?',
      'cancel': '취소',
      'delete': '삭제',
      'ad_wait_message':
          '분석이 완료되었습니다. 광고 후 결과가 표시됩니다.',
      'analysis_failed_title': '분석 실패',
      'analysis_failed_reason': '원인: {reason}',
      'analysis_failed_hint':
          '도움말: 로그아웃 후 다시 로그인해 보세요.',
      'story_section_title':
          '스토리를 몰래 보거나 프로필 사진 확대하기',
      'story_login_required':
          '스토리를 익명으로 보려면 유효한 Instagram 로그인 세션이 필요합니다. 이미 로그인했는데도 이 안내가 계속 보이면 Instagram에서 로그아웃한 뒤 다시 로그인해 주세요.',
      'story_ad_wait':
          '광고 후 표시됩니다. 잠시만 기다려 주세요.',
      'story_action_title': '무엇을 하시겠어요?',
      'story_view_photo': '프로필 사진 확대',
      'story_watch_secret': '스토리 몰래 보기',
      'story_no_data': '스토리 데이터가 없습니다.',
      'story_close': '닫기',
      'no_data': '\uB370\uC774\uD130 \uC5C6\uC74C',
      'new_badge': '\uC2E0\uADDC',
      'login_title': '\uB85C\uADF8\uC778',
      'read_and_agree': '읽었으며 동의합니다',
      'withdraw_consent': '동의 철회',
      'withdraw_consent_confirm_title': '확인',
      'withdraw_consent_confirm_body':
          '동의 설정이 초기화됩니다. 계속하시겠습니까?',
      'withdraw_consent_confirm_yes': '예',
      'withdraw_consent_confirm_no': '취소',
      'data_updated': '분석 완료 ✅',
      'enter_pin': 'PIN 입력',
      'pin_accepted':
          'PIN이 승인되어 시간이 초기화되었습니다 ✅',
      'pin_incorrect': 'PIN이 올바르지 않습니다',
      'ok': '확인',
      'legal_warning': '법적 고지',
      'rate_us': '\uBCC4\uC810 \uC8FC\uAE30',
      'contact_us': '\uBB38\uC758\uD558\uAE30',
      'remove_ads_and_limits': '\uAD11\uACE0 \uBC0F \uB300\uAE30 \uC2DC\uAC04 \uC81C\uAC70',
      'legal_intro':
          '이 앱을 다운로드하고 사용하는 모든 사용자는 아래 고지 내용을 읽고 동의한 것으로 간주됩니다.',
      'user_label': '\uC0AC\uC6A9\uC790',
    },
    'ja': {
      'tagline': 'プロフェッショナルSNSソリューション',
      'admin_active_note': '管理者モード有効',
      'free_app_note':
          'より良い体験のため、毎日改善を続けています。ご意見をお待ちしています。',
      'login_prompt':
          '分析を開始するにはログインしてください。',
      'welcome': 'ようこそ、{username}',
      'refresh_data': 'データを更新',
      'login_with_instagram': 'Instagramでログイン',
      'fetching_data':
          'データを分析中...\nしばらくお待ちください。',
      'processing_data':
          'データを処理中...\nまもなく完了します。',
      'loading_ad':
          '広告を読み込み中...\nしばらくお待ちください。',
      'google_ad_warning': 'Google広告の警告: {reason}',
      'analysis_secure':
          'すべての分析は端末内で安全にローカル処理されます。',
      'today_total_analysis': '本日の分析総数: {count}',
      'purchases_not_configured':
          '現在、購入機能は利用できません。後でもう一度お試しください。',
      'premium_already_active':
          'Premiumメンバーシップは有効です。',
      'premium_welcome_box':
          'Premiumへようこそ！広告と待機時間が解除されました。',
      'restore_purchases': '購入を復元',
      'restore_purchases_short': '\u5FA9\u5143',
      'restoring_purchases': '購入を復元中...',
      'restore_purchases_success': '購入を復元しました ✅',
      'restore_purchases_none': '復元できる購入がありません。',
      'restore_purchases_failed': '復元に失敗しました: {err}',
      'next_analysis': '次の分析',
      'next_analysis_ready': '今すぐ分析できます。',
      'analysis_ready_risk':
          '今すぐ分析できますが、連続実行はアカウントのリスクになる可能性があります。',
      'please_wait': 'お待ちください',
      'remaining_time': '残り時間: {time}',
      'watch_ad': '広告を見て分析を開始',
      'start_analysis': '分析を開始',
      'start_analysis_question': '分析を開始しますか？',
      'clear_data_title': 'アプリデータをリセット',
      'clear_data_content':
          'ローカルデータとセッション情報がすべて削除されます。よろしいですか？',
      'cancel': 'キャンセル',
      'delete': '削除',
      'ad_wait_message':
          '分析が完了しました。広告の後に結果を表示します。',
      'analysis_failed_title': '分析に失敗しました',
      'analysis_failed_reason': '理由: {reason}',
      'analysis_failed_hint':
          'ヒント: ログアウトして再ログインすると改善する場合があります。',
      'story_section_title':
          'ストーリーをこっそり見る / プロフィール写真を拡大',
      'story_login_required':
          'ストーリーを匿名で表示するには、有効なInstagramログインセッションが必要です。すでにログイン済みでもこの案内が出る場合は、Instagramで一度ログアウトしてから再ログインしてください。',
      'story_ad_wait':
          '広告の後に表示されます。しばらくお待ちください。',
      'story_action_title': '何をしますか？',
      'story_view_photo': 'プロフィール写真を拡大',
      'story_watch_secret': '\u8db3\u8de1\u306a\u3057\u3067\u95b2\u89a7',
      'story_no_data': 'ストーリーデータが見つかりません。',
      'story_close': '閉じる',
      'no_data': '\u30C7\u30FC\u30BF\u306A\u3057',
      'new_badge': '\u65B0\u7740',
      'login_title': '\u30ED\u30B0\u30A4\u30F3',
      'read_and_agree': '内容を読み、同意します',
      'withdraw_consent': '同意を取り消す',
      'withdraw_consent_confirm_title': '確認',
      'withdraw_consent_confirm_body':
          '同意設定がリセットされます。よろしいですか？',
      'withdraw_consent_confirm_yes': 'はい',
      'withdraw_consent_confirm_no': '戻る',
      'data_updated': '分析完了 ✅',
      'enter_pin': 'PINを入力',
      'pin_accepted':
          'PINを確認しました。タイマーをリセットしました ✅',
      'pin_incorrect': 'PINが正しくありません',
      'ok': 'OK',
      'legal_warning': '法的注意事項',
      'rate_us': '\u8A55\u4FA1\u3059\u308B',
      'contact_us': '\u304A\u554F\u3044\u5408\u308F\u305B',
      'remove_ads_and_limits': '\u5E83\u544A\u3068\u5F85\u6A5F\u6642\u9593\u3092\u524A\u9664',
      'legal_intro':
          '本アプリをダウンロードして利用した時点で、以下の規約に同意したものとみなされます。',
      'user_label': '\u30E6\u30FC\u30B6\u30FC',
    },
    'ru': {
      'tagline':
          'Профессиональные решения для соцсетей',
      'admin_active_note':
          'Режим администратора активен',
      'free_app_note':
          'Мы ежедневно улучшаем приложение, чтобы сделать ваш опыт лучше. Ваш отзыв важен для нас.',
      'login_prompt':
          'Пожалуйста, войдите, чтобы начать анализ.',
      'welcome': 'Добро пожаловать, {username}',
      'refresh_data': 'ОБНОВИТЬ ДАННЫЕ',
      'login_with_instagram': 'ВОЙТИ ЧЕРЕЗ INSTAGRAM',
      'fetching_data':
          'Анализируем данные...\nЭто может занять немного времени.',
      'processing_data':
          'Обрабатываем данные...\nПочти готово.',
      'loading_ad':
          'Загрузка рекламы...\nПожалуйста, подождите.',
      'google_ad_warning':
          'Предупреждение рекламы Google: {reason}',
      'analysis_secure':
          'Весь анализ безопасно выполняется локально на вашем устройстве.',
      'today_total_analysis':
          'Всего анализов сегодня: {count}',
      'purchases_not_configured':
          'Покупки сейчас недоступны. Пожалуйста, попробуйте позже.',
      'premium_already_active':
          'Ваша подписка Premium активна.',
      'premium_welcome_box':
          'Добро пожаловать в Premium! Реклама и ожидание отключены.',
      'restore_purchases': 'Восстановить покупки',
      'restore_purchases_short': '\u0412\u041E\u0421\u0421\u0422\u0410\u041D\u041E\u0412\u0418\u0422\u042C',
      'restoring_purchases': 'Восстанавливаем покупки...',
      'restore_purchases_success':
          'Покупки восстановлены ✅',
      'restore_purchases_none':
          'Нет покупок для восстановления.',
      'restore_purchases_failed':
          'Ошибка восстановления: {err}',
      'next_analysis': 'Следующий анализ',
      'next_analysis_ready': 'Анализ уже доступен.',
      'analysis_ready_risk':
          'Анализ доступен сейчас, но частые подряд анализы могут повысить риск для аккаунта.',
      'please_wait': 'Пожалуйста, подождите',
      'remaining_time': 'Осталось времени: {time}',
      'watch_ad':
          'ПОСМОТРЕТЬ РЕКЛАМУ И НАЧАТЬ АНАЛИЗ',
      'start_analysis': 'НАЧАТЬ АНАЛИЗ',
      'start_analysis_question': 'Начать анализ?',
      'clear_data_title': 'Сброс данных приложения',
      'clear_data_content':
          'Все локальные данные и данные сессии будут удалены. Продолжить?',
      'cancel': 'ОТМЕНА',
      'delete': 'УДАЛИТЬ',
      'ad_wait_message':
          'Анализ завершен, результаты будут показаны после рекламы.',
      'analysis_failed_title':
          'Не удалось выполнить анализ',
      'analysis_failed_reason': 'Причина: {reason}',
      'analysis_failed_hint':
          'Совет: попробуйте выйти и войти снова.',
      'story_section_title':
          'Смотреть сторис анонимно или увеличивать фото профиля',
      'story_login_required':
          'Чтобы смотреть сторис анонимно, нужен действующий вход в Instagram. Если вы уже вошли, но это сообщение не исчезает, выйдите из Instagram и войдите снова.',
      'story_ad_wait':
          'Появится после рекламы, пожалуйста, подождите.',
      'story_action_title': 'Что вы хотите сделать?',
      'story_view_photo': 'Увеличить фото профиля',
      'story_watch_secret': 'Смотреть сторис анонимно',
      'story_no_data': 'Данные сторис не найдены.',
      'story_close': 'ЗАКРЫТЬ',
      'no_data': '\u041D\u0435\u0442 \u0434\u0430\u043D\u043D\u044B\u0445',
      'new_badge': '\u041D\u041E\u0412\u041E\u0415',
      'login_title': '\u0412\u0445\u043E\u0434',
      'read_and_agree': 'Я ПРОЧИТАЛ И СОГЛАСЕН',
      'withdraw_consent': 'Отозвать согласие',
      'withdraw_consent_confirm_title': 'Подтверждение',
      'withdraw_consent_confirm_body':
          'Настройки согласия будут сброшены. Вы уверены?',
      'withdraw_consent_confirm_yes': 'Да',
      'withdraw_consent_confirm_no': 'Отмена',
      'data_updated': 'Анализ завершен ✅',
      'enter_pin': 'Введите PIN',
      'pin_accepted': 'PIN принят, таймер сброшен ✅',
      'pin_incorrect': 'Неверный PIN',
      'ok': 'OK',
      'legal_warning': 'Юридическое предупреждение',
      'rate_us': '\u041E\u0446\u0435\u043D\u0438\u0442\u0435 \u043D\u0430\u0441',
      'contact_us': '\u0421\u0432\u044F\u0437\u0430\u0442\u044C\u0441\u044F \u0441 \u043D\u0430\u043C\u0438',
      'remove_ads_and_limits': '\u0423\u0431\u0440\u0430\u0442\u044C \u0440\u0435\u043A\u043B\u0430\u043C\u0443 \u0438 \u043E\u0436\u0438\u0434\u0430\u043D\u0438\u0435',
      'legal_intro':
          'Скачивая и используя это приложение, пользователь считается ознакомившимся и согласившимся с условиями ниже.',
      'user_label': '\u041F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u0435\u043B\u044C',
    },
    'pt': {
      'tagline': 'Soluções profissionais para redes sociais',
      'admin_active_note': 'Modo administrador ativo',
      'free_app_note':
          'Estamos evoluindo todos os dias para oferecer uma experiência melhor. Seu feedback é muito importante para nós.',
      'login_prompt': 'Faça login para iniciar a análise.',
      'welcome': 'Bem-vindo, {username}',
      'refresh_data': 'ATUALIZAR DADOS',
      'login_with_instagram': 'ENTRAR COM INSTAGRAM',
      'fetching_data': 'Analisando dados...\nIsso pode levar um momento.',
      'processing_data': 'Processando dados...\nQuase pronto.',
      'loading_ad': 'Carregando anúncio...\nAguarde.',
      'google_ad_warning': 'Aviso de anúncio do Google: {reason}',
      'analysis_secure':
          'Toda a análise é processada com segurança localmente no seu dispositivo.',
      'today_total_analysis': 'Total de análises hoje: {count}',
      'purchases_not_configured':
          'Compras indisponíveis no momento. Tente novamente mais tarde.',
      'premium_already_active': 'Sua assinatura Premium está ativa.',
      'premium_welcome_box':
          'Bem-vindo ao Premium! Anúncios e tempos de espera foram removidos.',
      'restore_purchases': 'Restaurar compras',
      'restore_purchases_short': 'RESTAURAR',
      'restoring_purchases': 'Restaurando compras...',
      'restore_purchases_success': 'Compras restauradas ✅',
      'restore_purchases_none': 'Nenhuma compra para restaurar.',
      'restore_purchases_failed': 'Falha na restauração: {err}',
      'next_analysis': 'Próxima análise',
      'next_analysis_ready': 'Análise disponível agora.',
      'analysis_ready_risk':
          'A análise está disponível, mas fazer análises em sequência pode aumentar o risco da conta.',
      'please_wait': 'Aguarde',
      'remaining_time': 'Tempo restante: {time}',
      'watch_ad': 'ASSISTIR AO ANÚNCIO E INICIAR ANÁLISE',
      'start_analysis': 'INICIAR ANÁLISE',
      'start_analysis_question': 'Iniciar análise?',
      'clear_data_title': 'Redefinir dados do app',
      'clear_data_content':
          'Todos os dados locais e sessões serão apagados. Tem certeza?',
      'cancel': 'CANCELAR',
      'delete': 'EXCLUIR',
      'ad_wait_message':
          'Análise concluída, os resultados serão mostrados após o anúncio.',
      'analysis_failed_title': 'Falha na análise',
      'analysis_failed_reason': 'Motivo: {reason}',
      'analysis_failed_hint': 'Dica: sair e entrar novamente pode ajudar.',
      'story_section_title':
          'Veja stories em segredo ou amplie fotos de perfil',
      'story_login_required': 'Para ver stories de forma anônima, é necessário um login válido no Instagram. Se você já entrou e este aviso continua, saia do Instagram e entre novamente.',
      'story_ad_wait': 'Será exibido após o anúncio. Aguarde.',
      'story_action_title': 'O que você deseja fazer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver story em segredo',
      'story_no_data': 'Nenhum dado de story encontrado.',
      'story_close': 'FECHAR',
      'no_data': 'Sem dados',
      'new_badge': 'NOVO',
      'login_title': 'Entrar',
      'read_and_agree': 'LI E CONCORDO',
      'withdraw_consent': 'Retirar consentimento',
      'withdraw_consent_confirm_title': 'Confirmação',
      'withdraw_consent_confirm_body':
          'As configurações de consentimento serão redefinidas. Continuar?',
      'withdraw_consent_confirm_yes': 'Sim',
      'withdraw_consent_confirm_no': 'Cancelar',
      'data_updated': 'Análise concluída ✅',
      'enter_pin': 'Digite o PIN',
      'pin_accepted': 'PIN aceito, tempo reiniciado ✅',
      'pin_incorrect': 'PIN inválido',
      'ok': 'OK',
      'legal_warning': 'Aviso legal',
      'rate_us': 'Avalie-nos',
      'contact_us': 'Fale conosco',
      'remove_ads_and_limits': 'Remover an\u00FAncios e espera',
      'legal_intro':
          'Ao baixar e usar este aplicativo, o usuário declara que leu e aceitou os termos abaixo.',
      'user_label': 'Usu\u00E1rio',
    },
    'ar': {
      'tagline':
          'حلول احترافية لوسائل التواصل الاجتماعي',
      'admin_active_note': 'وضع المشرف مفعّل',
      'free_app_note':
          'نحن نطوّر التطبيق يومياً لتقديم تجربة أفضل. ملاحظاتك مهمة جداً لنا.',
      'login_prompt':
          'يرجى تسجيل الدخول لبدء التحليل.',
      'welcome': 'مرحباً، {username}',
      'refresh_data': 'تحديث البيانات',
      'login_with_instagram': 'تسجيل الدخول عبر انستغرام',
      'fetching_data':
          'جارٍ تحليل البيانات...\nقد يستغرق ذلك بعض الوقت.',
      'processing_data':
          'جارٍ معالجة البيانات...\nعلى وشك الانتهاء.',
      'loading_ad':
          'جارٍ تحميل الإعلان...\nيرجى الانتظار.',
      'google_ad_warning': 'تحذير إعلان Google: {reason}',
      'analysis_secure':
          'يتم تنفيذ جميع التحليلات بشكل آمن محلياً على جهازك.',
      'today_total_analysis':
          'إجمالي التحليلات اليوم: {count}',
      'purchases_not_configured':
          'الشراء غير متاح حالياً. يرجى المحاولة لاحقاً.',
      'premium_already_active': 'عضوية Premium مفعلة لديك.',
      'premium_welcome_box':
          'مرحباً بك في Premium! تمت إزالة الإعلانات وفترات الانتظار.',
      'restore_purchases': 'استعادة المشتريات',
      'restore_purchases_short': '\u0627\u0633\u062A\u0639\u0627\u062F\u0629',
      'restoring_purchases': 'جارٍ استعادة المشتريات...',
      'restore_purchases_success':
          'تمت استعادة المشتريات ✅',
      'restore_purchases_none':
          'لا توجد مشتريات للاستعادة.',
      'restore_purchases_failed': 'فشلت الاستعادة: {err}',
      'next_analysis': 'التحليل التالي',
      'next_analysis_ready': 'يمكنك إجراء التحليل الآن.',
      'analysis_ready_risk':
          'التحليل متاح الآن، لكن التحليل المتكرر قد يعرّض حسابك للخطر.',
      'please_wait': 'يرجى الانتظار',
      'remaining_time': 'الوقت المتبقي: {time}',
      'watch_ad': 'شاهد الإعلان وابدأ التحليل',
      'start_analysis': 'ابدأ التحليل',
      'start_analysis_question': 'هل تريد بدء التحليل؟',
      'clear_data_title': 'إعادة تعيين بيانات التطبيق',
      'clear_data_content':
          'سيتم حذف جميع البيانات المحلية ومعلومات الجلسة. هل أنت متأكد؟',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'ad_wait_message':
          'اكتمل التحليل، وسيتم عرض النتائج بعد الإعلان.',
      'analysis_failed_title': 'فشل التحليل',
      'analysis_failed_reason': 'السبب: {reason}',
      'analysis_failed_hint':
          'نصيحة: قد يفيد تسجيل الخروج ثم تسجيل الدخول مرة أخرى.',
      'story_section_title':
          'شاهد القصص بشكل مخفي أو كبّر صور الملف الشخصي',
      'story_login_required':
          'لمشاهدة القصص بشكل سري، يلزم تسجيل دخول صالح في Instagram. إذا كنت مسجلا بالفعل وما زال هذا التنبيه يظهر، سجل الخروج من Instagram ثم سجل الدخول مرة أخرى.',
      'story_ad_wait':
          'سيتم العرض بعد الإعلان، يرجى الانتظار.',
      'story_action_title': 'ماذا تريد أن تفعل؟',
      'story_view_photo': 'تكبير صورة الملف الشخصي',
      'story_watch_secret': 'مشاهدة القصة بشكل مخفي',
      'story_no_data': 'لا توجد بيانات للقصص.',
      'story_close': 'إغلاق',
      'no_data': '\u0644\u0627 \u062A\u0648\u062C\u062F \u0628\u064A\u0627\u0646\u0627\u062A',
      'new_badge': '\u062C\u062F\u064A\u062F',
      'login_title': '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644',
      'read_and_agree': 'لقد قرأت وأوافق',
      'withdraw_consent': 'سحب الموافقة',
      'withdraw_consent_confirm_title': 'تأكيد',
      'withdraw_consent_confirm_body':
          'سيتم إعادة تعيين إعدادات الموافقة. هل أنت متأكد؟',
      'withdraw_consent_confirm_yes': 'نعم',
      'withdraw_consent_confirm_no': 'إلغاء',
      'data_updated': 'اكتمل التحليل ✅',
      'enter_pin': 'أدخل PIN',
      'pin_accepted':
          'تم قبول PIN وإعادة تعيين الوقت ✅',
      'pin_incorrect': 'PIN غير صحيح',
      'ok': 'موافق',
      'legal_warning': 'تنبيه قانوني',
      'rate_us': '\u0642\u064A\u0645\u0646\u0627',
      'contact_us': '\u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u0646\u0627',
      'remove_ads_and_limits': '\u0625\u0632\u0627\u0644\u0629 \u0627\u0644\u0625\u0639\u0644\u0627\u0646\u0627\u062A \u0648\u0641\u062A\u0631\u0627\u062A \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631',
      'legal_intro':
          'بتنزيل هذا التطبيق واستخدامه، يُعتبر المستخدم قد قرأ ووافق على الشروط التالية.',
      'user_label': '\u0645\u0633\u062A\u062E\u062F\u0645',
    },
    'es': {
      "tagline": "Soluciones profesionales de redes sociales",
      "adsense_banner": "PUBLICIDAD",
      "admin_active_note": "Modo administrador activo",
      "free_app_note":
          "Mejoramos cada d\u00eda para darte una mejor experiencia. Tu opini\u00f3n nos ayuda much\u00edsimo.",
      "login_prompt": "Inicia sesi\u00f3n para comenzar el an\u00e1lisis.",
      "welcome": "Bienvenido, {username}",
      "refresh_data": "ACTUALIZAR DATOS",
      "login_with_instagram": "INICIA SESI\u00d3N CON INSTAGRAM",
      "fetching_data":
          "Analizando datos...\nEsto podr\u00eda tardar un momento.",
      "processing_data": "Procesando datos...\nCasi terminado.",
      "loading_ad": "Cargando anuncio...\nPor favor espera.",
      "google_ad_warning": "Advertencia de anuncio de Google: {reason}",
      "analysis_secure":
          "Todos los an\u00e1lisis se procesan de forma segura localmente en su dispositivo.",
      "today_total_analysis": "An\u00e1lisis totales hoy: {count}",
      "next_analysis": "Pr\u00f3ximo an\u00e1lisis",
      "next_analysis_ready": "Listo para escanear.",
      "analysis_available_now": "An\u00e1lisis disponible ahora",
      "analysis_ready_risk":
          "El an\u00e1lisis ya est\u00e1 disponible, pero ejecutar an\u00e1lisis seguidos puede poner tu cuenta en riesgo.",
      "please_wait": "Por favor espera",
      "warning": "Advertencia",
      "remaining_time": "Pr\u00f3ximo an\u00e1lisis: {time}",
      "watch_ad": "VER EL ANUNCIO E INICIAR EL AN\u00c1LISIS",
      "start_analysis": "INICIAR AN\u00c1LISIS",
      "start_analysis_question": "\u00bfIniciar an\u00e1lisis?",
      "clear_data_title": "Restablecer datos de la aplicaci\u00f3n",
      "clear_data_content":
          "Esto borrar\u00e1 todos los datos locales y las cookies de sesi\u00f3n. \u00bfEst\u00e1 seguro?",
      "cancel": "CANCELAR",
      "delete": "BORRAR",
      "error_title": "Error",
      "data_fetch_error":
          "Error en la recuperaci\u00f3n de datos: {err}\n\nSoluci\u00f3n de problemas: intente cerrar sesi\u00f3n y volver a iniciarla.",
      "followers": "Seguidores",
      "following": "Siguiendo",
      "new_followers": "Nuevos seguidores",
      "non_followers": "No me siguen",
      "left_followers": "Dejaron de seguirte",
      "legal_warning": "Aviso legal",
      'left_following': 'Dejados de seguir',
      "rate_us": "Calif\u00edcanos",
      "contact_us": "Cont\u00e1ctenos",
      "remove_ads_and_limits":
          "Eliminar anuncios y tiempos de espera",
      "rate_test_message": "Este cuadro est\u00e1 actualmente bajo prueba.",
      "story_section_title":
          "Ver historias en secreto o hacer zoom en las fotos del perfil",
      "story_login_required":
          "Para ver historias en modo anónimo necesitas una sesión válida de Instagram. Si ya iniciaste sesión y este aviso sigue apareciendo, cierra sesión en Instagram y vuelve a iniciar sesión.",
      "story_ad_wait": "Se mostrar\u00e1 despu\u00e9s del anuncio, espere.",
      "story_action_title": "\u00bfQu\u00e9 te gustar\u00eda hacer?",
      "story_view_photo": "Ampliar foto de perfil",
      "story_watch_secret": "Ver historia sin dejar rastro",
      "story_no_data": "No hay datos de la historia disponibles.",
      "story_close": "CERRAR",
      "read_and_agree": "HE LE\u00cdDO Y ACEPTO",
      "withdraw_consent": "Retirar el consentimiento",
      "withdraw_consent_confirm_title": "Confirmar",
      "withdraw_consent_confirm_body":
          "Se restablecer\u00e1 su configuraci\u00f3n de consentimiento. \u00bfEst\u00e1 seguro?",
      "withdraw_consent_confirm_yes": "S\u00ed",
      "withdraw_consent_confirm_no": "Cancelar",
      "no_data": "Sin datos",
      "new_badge": "NUEVO",
      "login_title": "Iniciar sesi\u00f3n",
      'user_label': 'Usuario',
      "redirecting":
          "Sesi\u00f3n verificada, redireccionando de forma segura...",
      "data_updated": "An\u00e1lisis completo \u2705",
      "purchases_not_configured":
          "Las compras no est\u00e1n disponibles en este momento. Int\u00e9ntelo de nuevo m\u00e1s tarde.",
      "premium_not_active":
          "Compra completada, pero Premium a\u00fan no est\u00e1 activo. Por favor int\u00e9ntalo de nuevo.",
      "premium_welcome_box":
          "\u00a1Bienvenido a Premium! Se eliminan los anuncios y los tiempos de espera.",
      "premium_already_active": "Su membres\u00eda Premium est\u00e1 activa.",
      "restore_purchases": "Restaurar compras",
      "restore_purchases_short": "RESTAURAR",
      "restoring_purchases": "Restaurando compras...",
      "restore_purchases_success": "Compras restauradas \u2705",
      "restore_purchases_none": "No hay compras para restaurar.",
      "restore_purchases_failed": "Error de restauraci\u00f3n: {err}",
      "enter_pin": "Ingrese el PIN",
      "pin_accepted": "PIN aceptado, reinicio del temporizador \u2705",
      "pin_incorrect": "PIN no v\u00e1lido",
      "ok": "OK",
      "legal_intro":
          "Al descargar y utilizar esta aplicaci\u00f3n, se considera que cada Usuario ha le\u00eddo, comprendido y aceptado irrevocablemente el texto de \"T\u00e9rminos de uso y exenci\u00f3n de responsabilidad\" a continuaci\u00f3n por adelantado:",
      "article1_title":
          "Art\u00edculo 1: Privacidad de datos y arquitectura de procesamiento local",
      "article2_title": "Art\u00edculo 2: Riesgos de plataformas de terceros",
      "article3_title":
          "Art\u00edculo 3: Descargo de responsabilidad de garant\u00eda y limitaci\u00f3n de responsabilidad",
      "article4_title":
          "Art\u00edculo 4: Aviso de Propiedad Intelectual e Independencia",
      "article5_title":
          "Art\u00edculo 5: Continuidad del servicio y cambios de plataforma",
      "article5_text":
          "Los cambios fundamentales en la API de Instagram o la infraestructura web pueden hacer que la aplicaci\u00f3n pierda su funcionalidad parcial o completamente. El desarrollador no se compromete a actualizar la aplicaci\u00f3n ni a mantener el servicio en respuesta a dichos cambios de infraestructura, que se consideran \"fuerza mayor\".",
      "ad_wait_message":
          "An\u00e1lisis completo, los resultados se mostrar\u00e1n despu\u00e9s del anuncio.",
      "analysis_failed_title": "El an\u00e1lisis fall\u00f3",
      "analysis_failed_reason": "Raz\u00f3n: {reason}",
      "analysis_failed_hint":
          "Consejo: Cerrar sesi\u00f3n y volver a iniciarla puede resultar \u00fatil.",
      "analysis_fast_no_change":
          "Comprobaci\u00f3n r\u00e1pida: los recuentos son los mismos. No se detectaron cambios.",
      "usage_metrics_title": "M\u00e9tricas diarias",
      "usage_metrics_active": "Usuarios activos",
      "usage_metrics_queries": "Consultas diarias",
      "usage_metrics_na": "--",
      "usage_metrics_live": "panel en vivo",
    },
    'es-mx': {
      "tagline": "Soluciones profesionales de redes sociales",
      "adsense_banner": "PUBLICIDAD",
      "admin_active_note": "Modo administrador activo",
      "free_app_note":
          "Mejoramos cada d\u00eda para darte una mejor experiencia. Tu opini\u00f3n nos ayuda much\u00edsimo.",
      "login_prompt": "Inicia sesi\u00f3n para comenzar el an\u00e1lisis.",
      "welcome": "Bienvenido, {username}",
      "refresh_data": "ACTUALIZAR DATOS",
      "login_with_instagram": "INICIA SESI\u00d3N CON INSTAGRAM",
      "fetching_data":
          "Analizando datos...\nEsto podr\u00eda tardar un momento.",
      "processing_data": "Procesando datos...\nCasi terminado.",
      "loading_ad": "Cargando anuncio...\nPor favor espera.",
      "google_ad_warning": "Advertencia de anuncio de Google: {reason}",
      "analysis_secure":
          "Todos los an\u00e1lisis se procesan de forma segura localmente en su dispositivo.",
      "today_total_analysis": "An\u00e1lisis totales hoy: {count}",
      "next_analysis": "Pr\u00f3ximo an\u00e1lisis",
      "next_analysis_ready": "Listo para escanear.",
      "analysis_available_now": "An\u00e1lisis disponible ahora",
      "analysis_ready_risk":
          "El an\u00e1lisis ya est\u00e1 disponible, pero ejecutar an\u00e1lisis seguidos puede poner tu cuenta en riesgo.",
      "please_wait": "Por favor espera",
      "warning": "Advertencia",
      "remaining_time": "Pr\u00f3ximo an\u00e1lisis: {time}",
      "watch_ad": "VER EL ANUNCIO E INICIAR EL AN\u00c1LISIS",
      "start_analysis": "INICIAR AN\u00c1LISIS",
      "start_analysis_question": "\u00bfIniciar an\u00e1lisis?",
      "clear_data_title": "Restablecer datos de la aplicaci\u00f3n",
      "clear_data_content":
          "Esto borrar\u00e1 todos los datos locales y las cookies de sesi\u00f3n. \u00bfEst\u00e1 seguro?",
      "cancel": "CANCELAR",
      "delete": "BORRAR",
      "error_title": "Error",
      "data_fetch_error":
          "Error en la recuperaci\u00f3n de datos: {err}\n\nSoluci\u00f3n de problemas: intente cerrar sesi\u00f3n y volver a iniciarla.",
      "followers": "Seguidores",
      "following": "Siguiendo",
      "new_followers": "Nuevos seguidores",
      "non_followers": "No me siguen",
      "left_followers": "Dejaron de seguirte",
      "legal_warning": "Aviso legal",
      'left_following': 'Dejados de seguir',
      "rate_us": "Calif\u00edcanos",
      "contact_us": "Cont\u00e1ctenos",
      "remove_ads_and_limits":
          "Eliminar anuncios y tiempos de espera",
      "rate_test_message": "Este cuadro est\u00e1 actualmente bajo prueba.",
      "story_section_title":
          "Ver historias en secreto o hacer zoom en las fotos del perfil",
      "story_login_required":
          "Para ver historias en modo anónimo necesitas una sesión válida de Instagram. Si ya iniciaste sesión y este aviso sigue apareciendo, cierra sesión en Instagram y vuelve a iniciar sesión.",
      "story_ad_wait": "Se mostrar\u00e1 despu\u00e9s del anuncio, espere.",
      "story_action_title": "\u00bfQu\u00e9 te gustar\u00eda hacer?",
      "story_view_photo": "Ampliar foto de perfil",
      "story_watch_secret": "Ver historia sin dejar rastro",
      "story_no_data": "No hay datos de la historia disponibles.",
      "story_close": "CERRAR",
      "read_and_agree": "HE LE\u00cdDO Y ACEPTO",
      "withdraw_consent": "Retirar el consentimiento",
      "withdraw_consent_confirm_title": "Confirmar",
      "withdraw_consent_confirm_body":
          "Se restablecer\u00e1 su configuraci\u00f3n de consentimiento. \u00bfEst\u00e1 seguro?",
      "withdraw_consent_confirm_yes": "S\u00ed",
      "withdraw_consent_confirm_no": "Cancelar",
      "no_data": "Sin datos",
      "new_badge": "NUEVO",
      "login_title": "Iniciar sesi\u00f3n",
      'user_label': 'Usuario',
      "redirecting":
          "Sesi\u00f3n verificada, redireccionando de forma segura...",
      "data_updated": "An\u00e1lisis completo \u2705",
      "purchases_not_configured":
          "Las compras no est\u00e1n disponibles en este momento. Int\u00e9ntelo de nuevo m\u00e1s tarde.",
      "premium_not_active":
          "Compra completada, pero Premium a\u00fan no est\u00e1 activo. Por favor int\u00e9ntalo de nuevo.",
      "premium_welcome_box":
          "\u00a1Bienvenido a Premium! Se eliminan los anuncios y los tiempos de espera.",
      "premium_already_active": "Su membres\u00eda Premium est\u00e1 activa.",
      "restore_purchases": "Restaurar compras",
      "restore_purchases_short": "RESTAURAR",
      "restoring_purchases": "Restaurando compras...",
      "restore_purchases_success": "Compras restauradas \u2705",
      "restore_purchases_none": "No hay compras para restaurar.",
      "restore_purchases_failed": "Error de restauraci\u00f3n: {err}",
      "enter_pin": "Ingrese el PIN",
      "pin_accepted": "PIN aceptado, reinicio del temporizador \u2705",
      "pin_incorrect": "PIN no v\u00e1lido",
      "ok": "OK",
      "legal_intro":
          "Al descargar y utilizar esta aplicaci\u00f3n, se considera que cada Usuario ha le\u00eddo, comprendido y aceptado irrevocablemente el texto de \"T\u00e9rminos de uso y exenci\u00f3n de responsabilidad\" a continuaci\u00f3n por adelantado:",
      "article1_title":
          "Art\u00edculo 1: Privacidad de datos y arquitectura de procesamiento local",
      "article2_title": "Art\u00edculo 2: Riesgos de plataformas de terceros",
      "article3_title":
          "Art\u00edculo 3: Descargo de responsabilidad de garant\u00eda y limitaci\u00f3n de responsabilidad",
      "article4_title":
          "Art\u00edculo 4: Aviso de Propiedad Intelectual e Independencia",
      "article5_title":
          "Art\u00edculo 5: Continuidad del servicio y cambios de plataforma",
      "article5_text":
          "Los cambios fundamentales en la API de Instagram o la infraestructura web pueden hacer que la aplicaci\u00f3n pierda su funcionalidad parcial o completamente. El desarrollador no se compromete a actualizar la aplicaci\u00f3n ni a mantener el servicio en respuesta a dichos cambios de infraestructura, que se consideran \"fuerza mayor\".",
      "ad_wait_message":
          "An\u00e1lisis completo, los resultados se mostrar\u00e1n despu\u00e9s del anuncio.",
      "analysis_failed_title": "El an\u00e1lisis fall\u00f3",
      "analysis_failed_reason": "Raz\u00f3n: {reason}",
      "analysis_failed_hint":
          "Consejo: Cerrar sesi\u00f3n y volver a iniciarla puede resultar \u00fatil.",
      "analysis_fast_no_change":
          "Comprobaci\u00f3n r\u00e1pida: los recuentos son los mismos. No se detectaron cambios.",
      "usage_metrics_title": "M\u00e9tricas diarias",
      "usage_metrics_active": "Usuarios activos",
      "usage_metrics_queries": "Consultas diarias",
      "usage_metrics_na": "--",
      "usage_metrics_live": "panel en vivo",
    },
    'hi': {
      "tagline":
          "\u092a\u094d\u0930\u094b\u092b\u0947\u0936\u0928\u0932 \u0938\u094b\u0936\u0932 \u092e\u0940\u0921\u093f\u092f\u093e \u0938\u0949\u0932\u094d\u092f\u0942\u0936\u0902\u0938",
      "adsense_banner": "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0938\u094d\u0925\u093e\u0928",
      "admin_active_note":
          "\u090f\u0921\u092e\u093f\u0928 \u092e\u094b\u0921 \u0938\u0915\u094d\u0930\u093f\u092f",
      "free_app_note":
          "\u0939\u092e \u0906\u092a\u0915\u094b \u092c\u0947\u0939\u0924\u0930 \u0905\u0928\u0941\u092d\u0935 \u092a\u094d\u0930\u0926\u093e\u0928 \u0915\u0930\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f \u0939\u0930 \u0926\u093f\u0928 \u0935\u093f\u0915\u0938\u093f\u0924 \u0939\u094b \u0930\u0939\u0947 \u0939\u0948\u0902\u0964 \u0906\u092a\u0915\u0940 \u092a\u094d\u0930\u0924\u093f\u0915\u094d\u0930\u093f\u092f\u093e \u0939\u092e\u093e\u0930\u0947 \u0932\u093f\u090f \u092e\u0942\u0932\u094d\u092f\u0935\u093e\u0928 \u0939\u0948\u2014\u0939\u092e\u0947\u0902 \u0906\u092a\u0938\u0947 \u0938\u0941\u0928\u0928\u093e \u0905\u091a\u094d\u091b\u093e \u0932\u0917\u0947\u0917\u093e!",
      "login_prompt":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u0936\u0941\u0930\u0942 \u0915\u0930\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f \u0915\u0943\u092a\u092f\u093e \u0932\u0949\u0917 \u0907\u0928 \u0915\u0930\u0947\u0902\u0964",
      "welcome":
          "\u0938\u094d\u0935\u093e\u0917\u0924 \u0939\u0948, {username}",
      "refresh_data":
          "\u0921\u0947\u091f\u093e \u0924\u093e\u091c\u093c\u093e \u0915\u0930\u0947\u0902",
      "login_with_instagram":
          "\u0907\u0902\u0938\u094d\u091f\u093e\u0917\u094d\u0930\u093e\u092e \u0938\u0947 \u0932\u0949\u0917 \u0907\u0928 \u0915\u0930\u0947\u0902",
      "fetching_data":
          "\u0921\u0947\u091f\u093e \u0915\u093e \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u0915\u093f\u092f\u093e \u091c\u093e \u0930\u0939\u093e \u0939\u0948...\n\u0907\u0938\u092e\u0947\u0902 \u090f\u0915 \u0915\u094d\u0937\u0923 \u0932\u0917 \u0938\u0915\u0924\u093e \u0939\u0948.",
      "processing_data":
          "\u0921\u0947\u091f\u093e \u0938\u0902\u0938\u093e\u0927\u093f\u0924 \u0939\u094b \u0930\u0939\u093e \u0939\u0948...\n\u0932\u0917\u092d\u0917 \u092a\u0942\u0930\u093e \u0939\u094b \u0917\u092f\u093e.",
      "loading_ad":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0932\u094b\u0921 \u0939\u094b \u0930\u0939\u093e \u0939\u0948...\n\u0915\u0943\u092a\u092f\u093e \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0915\u0930\u0947\u0902.",
      "google_ad_warning":
          "Google \u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u091a\u0947\u0924\u093e\u0935\u0928\u0940: {reason}",
      "analysis_secure":
          "\u0938\u092d\u0940 \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u0906\u092a\u0915\u0947 \u0921\u093f\u0935\u093e\u0907\u0938 \u092a\u0930 \u0938\u094d\u0925\u093e\u0928\u0940\u092f \u0930\u0942\u092a \u0938\u0947 \u0938\u0941\u0930\u0915\u094d\u0937\u093f\u0924 \u0930\u0942\u092a \u0938\u0947 \u0938\u0902\u0938\u093e\u0927\u093f\u0924 \u0915\u093f\u090f \u091c\u093e\u0924\u0947 \u0939\u0948\u0902\u0964",
      "today_total_analysis":
          "\u0906\u091c \u0915\u093e \u0915\u0941\u0932 \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923: {count}",
      "next_analysis":
          "\u0905\u0917\u0932\u093e \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923",
      "next_analysis_ready":
          "\u0938\u094d\u0915\u0948\u0928 \u0915\u0930\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f \u0924\u0948\u092f\u093e\u0930\u0964",
      "analysis_available_now":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u0905\u092c \u0909\u092a\u0932\u092c\u094d\u0927 \u0939\u0948",
      "analysis_ready_risk":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u0905\u092c \u0909\u092a\u0932\u092c\u094d\u0927 \u0939\u0948, \u0932\u0947\u0915\u093f\u0928 \u0932\u0917\u093e\u0924\u093e\u0930 \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u091a\u0932\u093e\u0928\u0947 \u0938\u0947 \u0906\u092a\u0915\u093e \u0916\u093e\u0924\u093e \u0916\u0924\u0930\u0947 \u092e\u0947\u0902 \u092a\u0921\u093c \u0938\u0915\u0924\u093e \u0939\u0948\u0964",
      "please_wait":
          "\u0915\u0943\u092a\u092f\u093e \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0915\u0930\u0947\u0902",
      "warning": "\u091a\u0947\u0924\u093e\u0935\u0928\u0940",
      "remaining_time":
          "\u0905\u0917\u0932\u093e \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923: {time}",
      "watch_ad":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0926\u0947\u0916\u0947\u0902 \u0914\u0930 \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u092a\u094d\u0930\u093e\u0930\u0902\u092d \u0915\u0930\u0947\u0902",
      "start_analysis":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u092a\u094d\u0930\u093e\u0930\u0902\u092d \u0915\u0930\u0947\u0902",
      "start_analysis_question":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u092a\u094d\u0930\u093e\u0930\u0902\u092d \u0915\u0930\u0947\u0902?",
      "clear_data_title":
          "\u0910\u092a \u0921\u0947\u091f\u093e \u0930\u0940\u0938\u0947\u091f \u0915\u0930\u0947\u0902",
      "clear_data_content":
          "\u092f\u0939 \u0938\u092d\u0940 \u0938\u094d\u0925\u093e\u0928\u0940\u092f \u0921\u0947\u091f\u093e \u0914\u0930 \u0938\u0924\u094d\u0930 \u0915\u0941\u0915\u0940\u091c\u093c \u092e\u093f\u091f\u093e \u0926\u0947\u0917\u093e\u0964 \u0915\u094d\u092f\u093e \u0906\u092a\u0915\u094b \u092f\u0915\u0940\u0928 \u0939\u0948?",
      "cancel": "\u0930\u0926\u094d\u0926 \u0915\u0930\u0947\u0902",
      "delete": "\u0939\u091f\u093e\u090f\u0902",
      "error_title": "\u0924\u094d\u0930\u0941\u091f\u093f",
      "data_fetch_error":
          "\u0921\u0947\u091f\u093e \u092a\u0941\u0928\u0930\u094d\u092a\u094d\u0930\u093e\u092a\u094d\u0924\u093f \u0935\u093f\u092b\u0932: {err}\n\n\u0938\u092e\u0938\u094d\u092f\u093e \u0928\u093f\u0935\u093e\u0930\u0923: \u0932\u0949\u0917 \u0906\u0909\u091f \u0915\u0930\u0928\u0947 \u0914\u0930 \u0935\u093e\u092a\u0938 \u0932\u0949\u0917 \u0907\u0928 \u0915\u0930\u0928\u0947 \u0915\u093e \u092a\u094d\u0930\u092f\u093e\u0938 \u0915\u0930\u0947\u0902\u0964",
      "followers": "\u0905\u0928\u0941\u092f\u093e\u092f\u0940",
      "following": "\u095e\u093c\u0949\u0932\u094b \u0915\u093f\u090f \u0917\u090f",
      "new_followers":
          "\u0928\u092f\u0947 \u0905\u0928\u0941\u092f\u093e\u092f\u0940",
      "non_followers":
          "\u091c\u094b \u092b\u0949\u0932\u094b \u092c\u0948\u0915 \u0928\u0939\u0940\u0902 \u0915\u0930\u0924\u0947",
      "left_followers":
          "\u0905\u0928\u092b\u093c\u0949\u0932\u094b\u0905\u0930\u094d\u0938",
      "legal_warning":
          "\u0915\u093e\u0928\u0942\u0928\u0940 \u0905\u0938\u094d\u0935\u0940\u0915\u0930\u0923",
      "left_following":
          "\u091c\u093f\u0928\u094d\u0939\u0947\u0902 \u0906\u092a\u0928\u0947 \u0905\u0928\u092b\u0949\u0932\u094b \u0915\u093f\u092f\u093e",
      "rate_us":
          "\u0939\u092e\u0947\u0902 \u0930\u0947\u091f \u0915\u0930\u0947\u0902",
      "contact_us":
          "\u0939\u092e\u0938\u0947 \u0938\u0902\u092a\u0930\u094d\u0915 \u0915\u0930\u0947\u0902",
      "remove_ads_and_limits":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0939\u091f\u093e\u090f\u0902 \u0914\u0930 \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f",
      "rate_test_message":
          "\u092f\u0939 \u092c\u0949\u0915\u094d\u0938 \u0905\u092d\u0940 \u092a\u0930\u0940\u0915\u094d\u0937\u0923\u093e\u0927\u0940\u0928 \u0939\u0948\u0964",
      "story_section_title":
          "\u0917\u0941\u092a\u094d\u0924 \u0930\u0942\u092a \u0938\u0947 \u0915\u0939\u093e\u0928\u093f\u092f\u093e\u0902 \u0926\u0947\u0916\u0947\u0902 \u092f\u093e \u092a\u094d\u0930\u094b\u092b\u093c\u093e\u0907\u0932 \u092b\u093c\u094b\u091f\u094b \u091c\u093c\u0942\u092e \u0915\u0930\u0947\u0902",
      "story_login_required":
          "स्टोरी को गुप्त रूप से देखने के लिए Instagram में मान्य लॉगिन सत्र जरूरी है। यदि आपने पहले से लॉगिन किया है और यह संदेश फिर भी दिख रहा है, तो Instagram से लॉगआउट करके दोबारा लॉगिन करें।",
      "story_ad_wait":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0915\u0947 \u092c\u093e\u0926 \u0926\u093f\u0916\u093e\u092f\u093e \u091c\u093e\u090f\u0917\u093e, \u0915\u0943\u092a\u092f\u093e \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0915\u0930\u0947\u0902\u0964",
      "story_action_title":
          "\u0906\u092a \u0915\u094d\u092f\u093e \u0915\u0930\u0928\u093e \u091a\u093e\u0939\u0947\u0902\u0917\u0947?",
      "story_view_photo":
          "\u092a\u094d\u0930\u094b\u092b\u093c\u093e\u0907\u0932 \u092b\u093c\u094b\u091f\u094b \u092c\u0921\u093c\u093e \u0915\u0930\u0947\u0902",
      "story_watch_secret":
          "\u092c\u093f\u0928\u093e \u092a\u0924\u093e \u091a\u0932\u0947 \u0938\u094d\u091f\u094b\u0930\u0940 \u0926\u0947\u0916\u0947\u0902",
      "story_no_data":
          "\u0915\u094b\u0908 \u0915\u0939\u093e\u0928\u0940 \u0921\u0947\u091f\u093e \u0909\u092a\u0932\u092c\u094d\u0927 \u0928\u0939\u0940\u0902 \u0939\u0948\u0964",
      "story_close": "\u092c\u0902\u0926 \u0915\u0930\u0947\u0902",
      "read_and_agree":
          "\u092e\u0948\u0902\u0928\u0947 \u092a\u0922\u093c\u093e \u0939\u0948 \u0914\u0930 \u0938\u0939\u092e\u0924 \u0939\u0942\u0902",
      "withdraw_consent":
          "\u0938\u0939\u092e\u0924\u093f \u0935\u093e\u092a\u0938 \u0932\u0947\u0902",
      "withdraw_consent_confirm_title":
          "\u092a\u0941\u0937\u094d\u091f\u093f \u0915\u0930\u0947\u0902",
      "withdraw_consent_confirm_body":
          "\u0906\u092a\u0915\u0940 \u0938\u0939\u092e\u0924\u093f \u0938\u0947\u091f\u093f\u0902\u0917\u094d\u0938 \u0930\u0940\u0938\u0947\u091f \u0915\u0930 \u0926\u0940 \u091c\u093e\u090f\u0902\u0917\u0940\u0964 \u0915\u094d\u092f\u093e \u0906\u092a\u0915\u094b \u092f\u0915\u0940\u0928 \u0939\u0948?",
      "withdraw_consent_confirm_yes": "\u0939\u093e\u0902",
      "withdraw_consent_confirm_no":
          "\u0930\u0926\u094d\u0926 \u0915\u0930\u0947\u0902",
      "no_data":
          "\u0915\u094b\u0908 \u0921\u0947\u091f\u093e \u0928\u0939\u0940\u0902",
      "new_badge": "\u0928\u092f\u093e",
      "login_title": "\u0932\u0949\u0917\u093f\u0928",
      'user_label': '\u0909\u092A\u092F\u094B\u0917\u0915\u0930\u094D\u0924\u093E',
      "redirecting":
          "\u0938\u0924\u094d\u0930 \u0938\u0924\u094d\u092f\u093e\u092a\u093f\u0924, \u0938\u0941\u0930\u0915\u094d\u0937\u093f\u0924 \u0930\u0942\u092a \u0938\u0947 \u092a\u0941\u0928\u0930\u094d\u0928\u093f\u0930\u094d\u0926\u0947\u0936\u093f\u0924...",
      "data_updated":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u092a\u0942\u0930\u093e \u2705",
      "purchases_not_configured":
          "\u0916\u0930\u0940\u0926\u093e\u0930\u0940 \u0905\u092d\u0940 \u0909\u092a\u0932\u092c\u094d\u0927 \u0928\u0939\u0940\u0902 \u0939\u0948\u0964 \u0915\u0943\u092a\u092f\u093e \u092c\u093e\u0926 \u092e\u0947\u0902 \u092a\u0941\u0928: \u092a\u094d\u0930\u092f\u093e\u0938 \u0915\u0930\u0947\u0902\u0964",
      "premium_not_active":
          "\u0916\u0930\u0940\u0926\u093e\u0930\u0940 \u092a\u0942\u0930\u0940 \u0939\u094b \u0917\u0908, \u0932\u0947\u0915\u093f\u0928 \u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u0905\u092d\u0940 \u0938\u0915\u094d\u0930\u093f\u092f \u0928\u0939\u0940\u0902 \u0939\u0948\u0964 \u0915\u0943\u092a\u092f\u093e \u092a\u0941\u0928: \u092a\u094d\u0930\u092f\u093e\u0938 \u0915\u0930\u0947\u0902\u0964",
      "premium_welcome_box":
          "\u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u092e\u0947\u0902 \u0906\u092a\u0915\u093e \u0938\u094d\u0935\u093e\u0917\u0924 \u0939\u0948! \u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0914\u0930 \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f \u0939\u091f\u093e \u0926\u093f\u090f \u091c\u093e\u0924\u0947 \u0939\u0948\u0902.",
      "premium_already_active":
          "\u0906\u092a\u0915\u0940 \u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u0938\u0926\u0938\u094d\u092f\u0924\u093e \u0938\u0915\u094d\u0930\u093f\u092f \u0939\u0948\u0964",
      "restore_purchases":
          "\u0916\u0930\u0940\u0926\u093e\u0930\u0940 \u092a\u0941\u0928\u0930\u094d\u0938\u094d\u0925\u093e\u092a\u093f\u0924 \u0915\u0930\u0947\u0902",
      "restore_purchases_short":
          "\u092a\u0941\u0928\u0930\u094d\u0938\u094d\u0925\u093e\u092a\u093f\u0924 \u0915\u0930\u0947\u0902",
      "restoring_purchases":
          "\u0916\u0930\u0940\u0926\u093e\u0930\u0940 \u092c\u0939\u093e\u0932 \u0915\u0940 \u091c\u093e \u0930\u0939\u0940 \u0939\u0948...",
      "restore_purchases_success":
          "\u0916\u0930\u0940\u0926\u093e\u0930\u0940 \u092c\u0939\u093e\u0932 \u2705",
      "restore_purchases_none":
          "\u092a\u0941\u0928\u0930\u094d\u0938\u094d\u0925\u093e\u092a\u093f\u0924 \u0915\u0930\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f \u0915\u094b\u0908 \u0916\u0930\u0940\u0926\u093e\u0930\u0940 \u0928\u0939\u0940\u0902\u0964",
      "restore_purchases_failed":
          "\u092a\u0941\u0928\u0930\u094d\u0938\u094d\u0925\u093e\u092a\u0928\u093e \u0935\u093f\u092b\u0932: {err}",
      "enter_pin":
          "\u092a\u093f\u0928 \u0926\u0930\u094d\u091c \u0915\u0930\u0947\u0902",
      "pin_accepted":
          "\u092a\u093f\u0928 \u0938\u094d\u0935\u0940\u0915\u0943\u0924, \u091f\u093e\u0907\u092e\u0930 \u0930\u0940\u0938\u0947\u091f \u2705",
      "pin_incorrect":
          "\u0905\u092e\u093e\u0928\u094d\u092f \u092a\u093f\u0928",
      "ok": "\u0920\u0940\u0915 \u0939\u0948",
      "legal_intro":
          "\u0907\u0938 \u090f\u092a\u094d\u0932\u093f\u0915\u0947\u0936\u0928 \u0915\u094b \u0921\u093e\u0909\u0928\u0932\u094b\u0921 \u0915\u0930\u0928\u0947 \u0914\u0930 \u0909\u092a\u092f\u094b\u0917 \u0915\u0930\u0928\u0947 \u0938\u0947, \u092f\u0939 \u092e\u093e\u0928\u093e \u091c\u093e\u090f\u0917\u093e \u0915\u093f \u092a\u094d\u0930\u0924\u094d\u092f\u0947\u0915 \u0909\u092a\u092f\u094b\u0917\u0915\u0930\u094d\u0924\u093e \u0928\u0947 \u0928\u0940\u091a\u0947 \u0926\u093f\u090f \u0917\u090f \"\u0909\u092a\u092f\u094b\u0917 \u0915\u0940 \u0936\u0930\u094d\u0924\u0947\u0902 \u0914\u0930 \u0905\u0938\u094d\u0935\u0940\u0915\u0930\u0923\" \u092a\u093e\u0920 \u0915\u094b \u092a\u0939\u0932\u0947 \u0939\u0940 \u092a\u0922\u093c, \u0938\u092e\u091d \u0932\u093f\u092f\u093e \u0939\u0948 \u0914\u0930 \u0905\u092a\u0930\u093f\u0935\u0930\u094d\u0924\u0928\u0940\u092f \u0930\u0942\u092a \u0938\u0947 \u0938\u094d\u0935\u0940\u0915\u093e\u0930 \u0915\u0930 \u0932\u093f\u092f\u093e \u0939\u0948:",
      "article1_title":
          "\u0905\u0928\u0941\u091a\u094d\u091b\u0947\u0926 1: \u0921\u0947\u091f\u093e \u0917\u094b\u092a\u0928\u0940\u092f\u0924\u093e \u0914\u0930 \u0938\u094d\u0925\u093e\u0928\u0940\u092f \u092a\u094d\u0930\u0938\u0902\u0938\u094d\u0915\u0930\u0923 \u0935\u093e\u0938\u094d\u0924\u0941\u0915\u0932\u093e",
      "article2_title":
          "\u0905\u0928\u0941\u091a\u094d\u091b\u0947\u0926 2: \u0924\u0943\u0924\u0940\u092f-\u092a\u0915\u094d\u0937 \u092a\u094d\u0932\u0947\u091f\u092b\u093c\u0949\u0930\u094d\u092e \u091c\u094b\u0916\u093f\u092e",
      "article3_title":
          "\u0905\u0928\u0941\u091a\u094d\u091b\u0947\u0926 3: \u0935\u093e\u0930\u0902\u091f\u0940 \u0905\u0938\u094d\u0935\u0940\u0915\u0930\u0923 \u0914\u0930 \u0926\u093e\u092f\u093f\u0924\u094d\u0935 \u0915\u0940 \u0938\u0940\u092e\u093e",
      "article4_title":
          "\u0905\u0928\u0941\u091a\u094d\u091b\u0947\u0926 4: \u092c\u094c\u0926\u094d\u0927\u093f\u0915 \u0938\u0902\u092a\u0926\u093e \u0914\u0930 \u0938\u094d\u0935\u0924\u0902\u0924\u094d\u0930\u0924\u093e \u0938\u0942\u091a\u0928\u093e",
      "article5_title":
          "\u0905\u0928\u0941\u091a\u094d\u091b\u0947\u0926 5: \u0938\u0947\u0935\u093e \u0928\u093f\u0930\u0902\u0924\u0930\u0924\u093e \u0914\u0930 \u092a\u094d\u0932\u0947\u091f\u092b\u093c\u0949\u0930\u094d\u092e \u092a\u0930\u093f\u0935\u0930\u094d\u0924\u0928",
      "article5_text":
          "\u0907\u0902\u0938\u094d\u091f\u093e\u0917\u094d\u0930\u093e\u092e \u090f\u092a\u0940\u0906\u0908 \u092f\u093e \u0935\u0947\u092c \u0907\u0902\u092b\u094d\u0930\u093e\u0938\u094d\u091f\u094d\u0930\u0915\u094d\u091a\u0930 \u092e\u0947\u0902 \u092c\u0941\u0928\u093f\u092f\u093e\u0926\u0940 \u092c\u0926\u0932\u093e\u0935\u094b\u0902 \u0915\u0947 \u0915\u093e\u0930\u0923 \u090f\u092a\u094d\u0932\u093f\u0915\u0947\u0936\u0928 \u0906\u0902\u0936\u093f\u0915 \u092f\u093e \u092a\u0942\u0930\u0940 \u0924\u0930\u0939 \u0938\u0947 \u0905\u092a\u0928\u0940 \u0915\u093e\u0930\u094d\u092f\u0915\u094d\u0937\u092e\u0924\u093e \u0916\u094b \u0938\u0915\u0924\u093e \u0939\u0948\u0964 \u0921\u0947\u0935\u0932\u092a\u0930 \u0910\u0938\u0947 \u092c\u0941\u0928\u093f\u092f\u093e\u0926\u0940 \u092a\u0930\u093f\u0935\u0930\u094d\u0924\u0928\u094b\u0902 \u0915\u0947 \u091c\u0935\u093e\u092c \u092e\u0947\u0902 \u090f\u092a\u094d\u0932\u093f\u0915\u0947\u0936\u0928 \u0915\u094b \u0905\u092a\u0921\u0947\u091f \u0915\u0930\u0928\u0947 \u092f\u093e \u0938\u0947\u0935\u093e \u0915\u094b \u092c\u0928\u093e\u090f \u0930\u0916\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f \u0915\u094b\u0908 \u092a\u094d\u0930\u0924\u093f\u092c\u0926\u094d\u0927\u0924\u093e \u0928\u0939\u0940\u0902 \u0930\u0916\u0924\u093e \u0939\u0948, \u091c\u093f\u0928\u094d\u0939\u0947\u0902 \"\u0905\u092a\u094d\u0930\u0924\u094d\u092f\u093e\u0936\u093f\u0924 \u0918\u091f\u0928\u093e\" \u092e\u093e\u0928\u093e \u091c\u093e\u0924\u093e \u0939\u0948\u0964",
      "ad_wait_message":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u092a\u0942\u0930\u093e \u0939\u094b \u0917\u092f\u093e, \u092a\u0930\u093f\u0923\u093e\u092e \u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0915\u0947 \u092c\u093e\u0926 \u0926\u093f\u0916\u093e\u090f \u091c\u093e\u090f\u0902\u0917\u0947\u0964",
      "analysis_failed_title":
          "\u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u0935\u093f\u092b\u0932 \u0930\u0939\u093e",
      "analysis_failed_reason": "\u0915\u093e\u0930\u0923: {reason}",
      "analysis_failed_hint":
          "\u091f\u093f\u092a: \u0932\u0949\u0917 \u0906\u0909\u091f \u0915\u0930\u0928\u0947 \u0914\u0930 \u0935\u093e\u092a\u0938 \u0932\u0949\u0917 \u0907\u0928 \u0915\u0930\u0928\u0947 \u0938\u0947 \u092e\u0926\u0926 \u092e\u093f\u0932 \u0938\u0915\u0924\u0940 \u0939\u0948\u0964",
      "analysis_fast_no_change":
          "\u0924\u094d\u0935\u0930\u093f\u0924 \u091c\u093e\u0902\u091a: \u0917\u093f\u0928\u0924\u0940 \u0938\u092e\u093e\u0928 \u0939\u0948\u0964 \u0915\u094b\u0908 \u092a\u0930\u093f\u0935\u0930\u094d\u0924\u0928 \u0928\u0939\u0940\u0902 \u092a\u093e\u092f\u093e \u0917\u092f\u093e.",
      "usage_metrics_title":
          "\u0926\u0948\u0928\u093f\u0915 \u092e\u0947\u091f\u094d\u0930\u093f\u0915\u094d\u0938",
      "usage_metrics_active":
          "\u0938\u0915\u094d\u0930\u093f\u092f \u0909\u092a\u092f\u094b\u0917\u0915\u0930\u094d\u0924\u093e",
      "usage_metrics_queries":
          "\u0926\u0948\u0928\u093f\u0915 \u092a\u094d\u0930\u0936\u094d\u0928",
      "usage_metrics_na": "--",
      "usage_metrics_live": "\u0932\u093e\u0907\u0935 \u092a\u0948\u0928\u0932",
    },
    'hu': {
      "tagline":
          "Professzion\u00e1lis k\u00f6z\u00f6ss\u00e9gi m\u00e9dia megold\u00e1sok",
      "adsense_banner": "HIRDET\u00c9SI HELY",
      "admin_active_note": "Admin m\u00f3d akt\u00edv",
      "free_app_note":
          "Minden nap fejl\u0151d\u00fcnk, hogy jobb \u00e9lm\u00e9nyben legyen r\u00e9szed. Visszajelz\u00e9se \u00e9rt\u00e9kes sz\u00e1munkra \u2013 sz\u00edvesen hallan\u00e1nk!",
      "login_prompt":
          "K\u00e9rj\u00fck, jelentkezzen be az elemz\u00e9s elind\u00edt\u00e1s\u00e1hoz.",
      "welcome": "\u00dcdv\u00f6z\u00f6lj\u00fck, {username}",
      "refresh_data": "ADATOK FRISS\u00cdT\u00c9SE",
      "login_with_instagram": "BEJELENTKEZ\u00c9S AZ INSTAGRAM-AL",
      "fetching_data": "Adatok elemz\u00e9se...\nEz eltarthat egy pillanatig.",
      "processing_data": "Adatok feldolgoz\u00e1sa...\nMajdnem k\u00e9sz.",
      "loading_ad":
          "Hirdet\u00e9s bet\u00f6lt\u00e9se...\nK\u00e9rj\u00fck, v\u00e1rjon.",
      "google_ad_warning":
          "Google hirdet\u00e9si figyelmeztet\u00e9s: {reason}",
      "analysis_secure":
          "Minden elemz\u00e9s biztons\u00e1gosan, helyben ker\u00fcl feldolgoz\u00e1sra az eszk\u00f6z\u00f6n.",
      "today_total_analysis": "A mai nap \u00f6sszes elemz\u00e9se: {count}",
      "next_analysis": "K\u00f6vetkez\u0151 elemz\u00e9s",
      "next_analysis_ready": "Szkennel\u00e9sre k\u00e9sz.",
      "analysis_available_now": "Az elemz\u00e9s m\u00e1r el\u00e9rhet\u0151",
      "analysis_ready_risk":
          "Az elemz\u00e9s m\u00e1r el\u00e9rhet\u0151, de az elemz\u00e9sek egym\u00e1s ut\u00e1ni futtat\u00e1sa vesz\u00e9lybe sodorhatja fi\u00f3kj\u00e1t.",
      "please_wait": "K\u00e9rj\u00fck, v\u00e1rjon",
      "warning": "Figyelem",
      "remaining_time": "K\u00f6vetkez\u0151 elemz\u00e9s: {time}",
      "watch_ad":
          "N\u00c9ZZE MEG A HIRDET\u00c9ST \u00c9S KEZDJEN EL AZ ELEMZ\u00c9ST",
      "start_analysis": "IND\u00cdTSA EL AZ ELEMZ\u00c9ST",
      "start_analysis_question": "Elkezdi az elemz\u00e9st?",
      "clear_data_title": "Alkalmaz\u00e1sadatok vissza\u00e1ll\u00edt\u00e1sa",
      "clear_data_content":
          "Ez t\u00f6rli az \u00f6sszes helyi adatot \u00e9s munkamenet-cookie-t. Biztos vagy benne?",
      "cancel": "M\u00c9GSEM",
      "delete": "DELETE",
      "error_title": "Hiba",
      "data_fetch_error":
          "Az adatlek\u00e9r\u00e9s sikertelen: {err}\n\nHibaelh\u00e1r\u00edt\u00e1s: Pr\u00f3b\u00e1ljon meg kijelentkezni, majd \u00fajra bejelentkezni.",
      "followers": "K\u00f6vet\u0151k",
      "following": "K\u00f6vetve",
      "new_followers": "\u00daj k\u00f6vet\u0151k",
      "non_followers": "Ne k\u00f6vess vissza",
      "left_followers": "K\u00f6vet\u00e9s megsz\u00fcntet\u00e9se",
      "legal_warning": "Jogi felel\u0151ss\u00e9g kiz\u00e1r\u00e1sa",
      "left_following": "Nem k\u00f6vetett felhaszn\u00e1l\u00f3k",
      "rate_us": "\u00c9rt\u00e9keljen minket",
      "contact_us": "Vegye fel vel\u00fcnk a kapcsolatot",
      "remove_ads_and_limits":
          "Hirdet\u00e9sek elt\u00e1vol\u00edt\u00e1sa \u00e9s v\u00e1rakoz\u00e1si id\u0151k",
      "rate_test_message": "Ez a doboz jelenleg tesztel\u00e9s alatt \u00e1ll.",
      "story_section_title":
          "N\u00e9zze meg a t\u00f6rt\u00e9neteket titokban vagy nagy\u00edtsa ki a profilfot\u00f3kat",
      "story_login_required":
          "A történetek névtelen megtekintéséhez érvényes Instagram-bejelentkezés szükséges. Ha már be vagy jelentkezve, de ez az üzenet továbbra is megjelenik, jelentkezz ki az Instagramból, majd jelentkezz be újra.",
      "story_ad_wait":
          "A hirdet\u00e9s ut\u00e1n jelenik meg, k\u00e9rj\u00fck, v\u00e1rjon.",
      "story_action_title": "Mit szeretn\u00e9l csin\u00e1lni?",
      "story_view_photo": "Profilfot\u00f3 nagy\u00edt\u00e1sa",
      "story_watch_secret": "N\u00e9zze meg a t\u00f6rt\u00e9netet titokban",
      "story_no_data":
          "Nem \u00e1llnak rendelkez\u00e9sre t\u00f6rt\u00e9netadatok.",
      "story_close": "BEz\u00e1r",
      "read_and_agree": "ELOLVASTAM \u00c9S EGYET\u00c9RTEM",
      "withdraw_consent": "A hozz\u00e1j\u00e1rul\u00e1s visszavon\u00e1sa",
      "withdraw_consent_confirm_title": "Er\u0151s\u00edtse meg",
      "withdraw_consent_confirm_body":
          "A hozz\u00e1j\u00e1rul\u00e1si be\u00e1ll\u00edt\u00e1sai vissza\u00e1llnak. Biztos vagy benne?",
      "withdraw_consent_confirm_yes": "Igen",
      "withdraw_consent_confirm_no": "M\u00e9gse",
      "no_data": "Nincs adat",
      "new_badge": "\u00daJ",
      "login_title": "Bejelentkez\u00e9s",
      'user_label': 'Felhaszn\u00E1l\u00F3',
      "redirecting":
          "Munkamenet igazolva, biztons\u00e1gos \u00e1tir\u00e1ny\u00edt\u00e1s...",
      "data_updated": "Az elemz\u00e9s k\u00e9sz \u2705",
      "purchases_not_configured":
          "A v\u00e1s\u00e1rl\u00e1sok jelenleg nem \u00e9rhet\u0151k el. K\u00e9rj\u00fck, pr\u00f3b\u00e1lja \u00fajra k\u00e9s\u0151bb.",
      "premium_not_active":
          "A v\u00e1s\u00e1rl\u00e1s befejez\u0151d\u00f6tt, de a Premium m\u00e9g nem akt\u00edv. K\u00e9rj\u00fck, pr\u00f3b\u00e1lja \u00fajra.",
      "premium_welcome_box":
          "\u00dcdv\u00f6z\u00f6lj\u00fck a Premiumban! A hirdet\u00e9sek \u00e9s a v\u00e1rakoz\u00e1si id\u0151 elt\u00e1vol\u00edtva.",
      "premium_already_active": "Pr\u00e9mium tags\u00e1god akt\u00edv.",
      "restore_purchases":
          "A v\u00e1s\u00e1rl\u00e1sok vissza\u00e1ll\u00edt\u00e1sa",
      "restore_purchases_short": "RESTORE",
      "restoring_purchases":
          "V\u00e1s\u00e1rl\u00e1sok vissza\u00e1ll\u00edt\u00e1sa...",
      "restore_purchases_success":
          "A v\u00e1s\u00e1rl\u00e1sok vissza\u00e1ll\u00edtva \u2705",
      "restore_purchases_none":
          "Nincs vissza\u00e1ll\u00edtand\u00f3 v\u00e1s\u00e1rl\u00e1s.",
      "restore_purchases_failed":
          "A vissza\u00e1ll\u00edt\u00e1s sikertelen: {err}",
      "enter_pin": "Adja meg a PIN-k\u00f3dot",
      "pin_accepted":
          "PIN elfogadva, id\u0151z\u00edt\u0151 vissza\u00e1ll\u00edt\u00e1sa \u2705",
      "pin_incorrect": "\u00c9rv\u00e9nytelen PIN-k\u00f3d",
      "ok": "OK",
      "legal_intro":
          "Az alkalmaz\u00e1s let\u00f6lt\u00e9s\u00e9vel \u00e9s haszn\u00e1lat\u00e1val \u00fagy kell tekinteni, hogy minden Felhaszn\u00e1l\u00f3 el\u0151zetesen elolvasta, meg\u00e9rtette \u00e9s visszavonhatatlanul elfogadta az al\u00e1bbi \u201eHaszn\u00e1lati felt\u00e9telek \u00e9s felel\u0151ss\u00e9g kiz\u00e1r\u00e1sa\u201d sz\u00f6veget:",
      "article1_title":
          "1. cikk: Adatv\u00e9delem \u00e9s helyi feldolgoz\u00e1si architekt\u00fara",
      "article2_title": "2. cikk: Harmadik felek platformkock\u00e1zatai",
      "article3_title":
          "3. cikk: A j\u00f3t\u00e1ll\u00e1si nyilatkozat \u00e9s a felel\u0151ss\u00e9g korl\u00e1toz\u00e1sa",
      "article4_title":
          "4. cikk: Szellemi tulajdonra \u00e9s f\u00fcggetlens\u00e9gre vonatkoz\u00f3 k\u00f6zlem\u00e9ny",
      "article5_title":
          "5. cikk: A szolg\u00e1ltat\u00e1s folytonoss\u00e1ga \u00e9s a platform v\u00e1ltoz\u00e1sai",
      "article5_text":
          "Az Instagram API-ban vagy a webes infrastrukt\u00far\u00e1ban bek\u00f6vetkezett alapvet\u0151 v\u00e1ltoztat\u00e1sok miatt az alkalmaz\u00e1s r\u00e9szben vagy teljesen elvesz\u00edtheti funkcionalit\u00e1s\u00e1t. A fejleszt\u0151 nem v\u00e1llal k\u00f6telezetts\u00e9get az alkalmaz\u00e1s friss\u00edt\u00e9s\u00e9re vagy a szolg\u00e1ltat\u00e1s karbantart\u00e1s\u00e1ra v\u00e1laszul az infrastruktur\u00e1lis v\u00e1ltoz\u00e1sokra, amelyek vis maiornak min\u0151s\u00fclnek.",
      "ad_wait_message":
          "Elemz\u00e9s k\u00e9sz, az eredm\u00e9nyek a hirdet\u00e9s ut\u00e1n jelennek meg.",
      "analysis_failed_title": "Az elemz\u00e9s sikertelen",
      "analysis_failed_reason": "Ok: {reason}",
      "analysis_failed_hint":
          "Tipp: A ki- \u00e9s visszajelentkez\u00e9s seg\u00edthet.",
      "analysis_fast_no_change":
          "Gyors ellen\u0151rz\u00e9s: A sz\u00e1mok megegyeznek. Nem \u00e9szlelt\u00fcnk v\u00e1ltoz\u00e1st.",
      "usage_metrics_title": "Napi mutat\u00f3k",
      "usage_metrics_active": "Akt\u00edv felhaszn\u00e1l\u00f3k",
      "usage_metrics_queries": "Napi lek\u00e9rdez\u00e9sek",
      "usage_metrics_na": "--",
      "usage_metrics_live": "\u00e9l\u0151 panel",
    },
    'zh-hans': {
      "tagline": "\u4e13\u4e1a\u793e\u4ea4\u5a92\u4f53\u89e3\u51b3\u65b9\u6848",
      "adsense_banner": "\u5e7f\u544a\u7a7a\u95f4",
      "admin_active_note": "\u7ba1\u7406\u5458\u6a21\u5f0f\u5df2\u6fc0\u6d3b",
      "free_app_note":
          "\u6211\u4eec\u6bcf\u5929\u90fd\u5728\u8fdb\u6b65\uff0c\u4e3a\u60a8\u63d0\u4f9b\u66f4\u597d\u7684\u4f53\u9a8c\u3002\u60a8\u7684\u53cd\u9988\u5bf9\u6211\u4eec\u5f88\u6709\u4ef7\u503c\u2014\u2014\u6211\u4eec\u5f88\u4e50\u610f\u542c\u53d6\u60a8\u7684\u610f\u89c1\uff01",
      "login_prompt": "\u8bf7\u767b\u5f55\u5f00\u59cb\u5206\u6790\u3002",
      "welcome": "\u6b22\u8fce\uff0c{username}",
      "refresh_data": "\u5237\u65b0\u6570\u636e",
      "login_with_instagram": "\u7528 INSTAGRAM \u767b\u5f55",
      "fetching_data":
          "\u6b63\u5728\u5206\u6790\u6570\u636e...\n\u8fd9\u53ef\u80fd\u9700\u8981\u4e00\u4e9b\u65f6\u95f4\u3002",
      "processing_data":
          "\u6b63\u5728\u5904\u7406\u6570\u636e...\n\u5feb\u5b8c\u6210\u4e86\u3002",
      "loading_ad": "\u52a0\u8f7d\u5e7f\u544a...\n\u8bf7\u7a0d\u5019\u3002",
      "google_ad_warning": "Google \u5e7f\u544a\u8b66\u544a\uff1a{reason}",
      "analysis_secure":
          "\u6240\u6709\u5206\u6790\u5747\u5728\u60a8\u7684\u8bbe\u5907\u4e0a\u672c\u5730\u5b89\u5168\u5904\u7406\u3002",
      "today_total_analysis":
          "\u4eca\u5929\u7684\u603b\u5206\u6790\uff1a{count}",
      "next_analysis": "\u63a5\u4e0b\u6765\u5206\u6790",
      "next_analysis_ready": "\u51c6\u5907\u626b\u63cf\u3002",
      "analysis_available_now": "\u5206\u6790\u73b0\u5df2\u53ef\u7528",
      "analysis_ready_risk":
          "\u5206\u6790\u73b0\u5df2\u53ef\u7528\uff0c\u4f46\u8fde\u7eed\u8fd0\u884c\u5206\u6790\u53ef\u80fd\u4f1a\u4f7f\u60a8\u7684\u5e10\u6237\u9762\u4e34\u98ce\u9669\u3002",
      "please_wait": "\u8bf7\u7a0d\u5019",
      "warning": "\u8b66\u544a",
      "remaining_time": "\u4e0b\u4e00\u6b65\u5206\u6790\uff1a{time}",
      "watch_ad": "\u89c2\u770b\u5e7f\u544a\u5e76\u5f00\u59cb\u5206\u6790",
      "start_analysis": "\u5f00\u59cb\u5206\u6790",
      "start_analysis_question": "\u5f00\u59cb\u5206\u6790\uff1f",
      "clear_data_title": "\u91cd\u7f6e\u5e94\u7528\u7a0b\u5e8f\u6570\u636e",
      "clear_data_content":
          "\u8fd9\u5c06\u64e6\u9664\u6240\u6709\u672c\u5730\u6570\u636e\u548c\u4f1a\u8bddcookie\u3002\u4f60\u786e\u5b9a\u5417\uff1f",
      "cancel": "\u53d6\u6d88",
      "delete": "\u5220\u9664",
      "error_title": "\u9519\u8bef",
      "data_fetch_error":
          "\u6570\u636e\u68c0\u7d22\u5931\u8d25\uff1a{err}\n\n\u6545\u969c\u6392\u9664\uff1a\u5c1d\u8bd5\u6ce8\u9500\u5e76\u91cd\u65b0\u767b\u5f55\u3002",
      "followers": "\u5173\u6ce8\u8005",
      "following": "\u6b63\u5728\u5173\u6ce8",
      "new_followers": "\u65b0\u5173\u6ce8\u8005",
      "non_followers": "\u672a\u56de\u5173",
      "left_followers": "\u53d6\u6d88\u5173\u6ce8\u8005",
      "legal_warning": "\u6cd5\u5f8b\u514d\u8d23\u58f0\u660e",
      "left_following": "\u53d6\u6d88\u5173\u6ce8\u7684\u7528\u6237",
      "rate_us": "\u7ed9\u6211\u4eec\u8bc4\u5206",
      "contact_us": "\u8054\u7cfb\u6211\u4eec",
      "remove_ads_and_limits":
          "\u5220\u9664\u5e7f\u544a\u548c\u7b49\u5f85\u65f6\u95f4",
      "rate_test_message":
          "\u8fd9\u4e2a\u76d2\u5b50\u76ee\u524d\u6b63\u5728\u6d4b\u8bd5\u4e2d\u3002",
      "story_section_title":
          "\u79d8\u5bc6\u89c2\u770b\u6545\u4e8b\u6216\u7f29\u653e\u4e2a\u4eba\u8d44\u6599\u7167\u7247",
      "story_login_required":
          "要匿名查看动态，需要有效的 Instagram 登录会话。如果你已经登录但仍看到此提示，请先退出 Instagram，再重新登录。",
      "story_ad_wait":
          "\u5c06\u5728\u5e7f\u544a\u540e\u663e\u793a\uff0c\u8bf7\u7a0d\u5019\u3002",
      "story_action_title": "\u4f60\u60f3\u505a\u4ec0\u4e48\uff1f",
      "story_view_photo": "\u653e\u5927\u4e2a\u4eba\u8d44\u6599\u7167\u7247",
      "story_watch_secret": "\u5077\u5077\u770b\u6545\u4e8b",
      "story_no_data":
          "\u6ca1\u6709\u53ef\u7528\u7684\u6545\u4e8b\u6570\u636e\u3002",
      "story_close": "\u5173\u95ed",
      "read_and_agree": "\u6211\u5df2\u9605\u8bfb\u5e76\u540c\u610f",
      "withdraw_consent": "\u64a4\u56de\u540c\u610f",
      "withdraw_consent_confirm_title": "\u786e\u8ba4",
      "withdraw_consent_confirm_body":
          "\u60a8\u7684\u540c\u610f\u8bbe\u7f6e\u5c06\u88ab\u91cd\u7f6e\u3002\u4f60\u786e\u5b9a\u5417\uff1f",
      "withdraw_consent_confirm_yes": "\u662f\u7684",
      "withdraw_consent_confirm_no": "\u53d6\u6d88",
      "no_data": "\u65e0\u6570\u636e",
      "new_badge": "\u65b0",
      "login_title": "\u767b\u5f55",
      'user_label': '\u7528\u6237',
      "redirecting":
          "\u4f1a\u8bdd\u5df2\u9a8c\u8bc1\uff0c\u5b89\u5168\u91cd\u5b9a\u5411...",
      "data_updated": "\u5206\u6790\u5b8c\u6210\u2705",
      "purchases_not_configured":
          "\u76ee\u524d\u65e0\u6cd5\u8d2d\u4e70\u3002\u8bf7\u7a0d\u540e\u91cd\u8bd5\u3002",
      "premium_not_active":
          "\u8d2d\u4e70\u5df2\u5b8c\u6210\uff0c\u4f46\u9ad8\u7ea7\u7248\u5c1a\u672a\u6fc0\u6d3b\u3002\u8bf7\u518d\u8bd5\u4e00\u6b21\u3002",
      "premium_welcome_box":
          "\u6b22\u8fce\u4f7f\u7528\u9ad8\u7ea7\u7248\uff01\u5e7f\u544a\u548c\u7b49\u5f85\u65f6\u95f4\u88ab\u5220\u9664\u3002",
      "premium_already_active":
          "\u60a8\u7684\u9ad8\u7ea7\u4f1a\u5458\u8d44\u683c\u5df2\u6fc0\u6d3b\u3002",
      "restore_purchases": "\u6062\u590d\u8d2d\u4e70",
      "restore_purchases_short": "\u6062\u590d",
      "restoring_purchases": "\u6b63\u5728\u6062\u590d\u8d2d\u4e70...",
      "restore_purchases_success": "\u8d2d\u4e70\u5df2\u6062\u590d \u2705",
      "restore_purchases_none":
          "\u6ca1\u6709\u8981\u6062\u590d\u7684\u8d2d\u4e70\u3002",
      "restore_purchases_failed": "\u6062\u590d\u5931\u8d25\uff1a{err}",
      "enter_pin": "\u8f93\u5165 PIN \u7801",
      "pin_accepted":
          "PIN \u5df2\u63a5\u53d7\uff0c\u8ba1\u65f6\u5668\u91cd\u7f6e \u2705",
      "pin_incorrect": "PIN \u7801\u65e0\u6548",
      "ok": "\u597d\u7684",
      "legal_intro":
          "\u4e0b\u8f7d\u5e76\u4f7f\u7528\u672c\u5e94\u7528\u7a0b\u5e8f\uff0c\u5373\u8868\u793a\u6bcf\u4f4d\u7528\u6237\u5df2\u63d0\u524d\u9605\u8bfb\u3001\u7406\u89e3\u5e76\u4e0d\u53ef\u64a4\u9500\u5730\u63a5\u53d7\u4ee5\u4e0b\u201c\u4f7f\u7528\u6761\u6b3e\u548c\u514d\u8d23\u58f0\u660e\u201d\u6587\u672c\uff1a",
      "article1_title":
          "\u7b2c 1 \u6761\uff1a\u6570\u636e\u9690\u79c1\u548c\u672c\u5730\u5904\u7406\u67b6\u6784",
      "article2_title":
          "\u7b2c\u4e8c\u6761\uff1a\u7b2c\u4e09\u65b9\u5e73\u53f0\u98ce\u9669",
      "article3_title":
          "\u7b2c 3 \u6761\uff1a\u514d\u8d23\u58f0\u660e\u548c\u8d23\u4efb\u9650\u5236",
      "article4_title":
          "\u7b2c4\u6761\uff1a\u77e5\u8bc6\u4ea7\u6743\u548c\u72ec\u7acb\u6027\u58f0\u660e",
      "article5_title":
          "\u7b2c5\u6761\uff1a\u670d\u52a1\u8fde\u7eed\u6027\u548c\u5e73\u53f0\u53d8\u66f4",
      "article5_text":
          "Instagram API \u6216 Web \u57fa\u7840\u8bbe\u65bd\u7684\u6839\u672c\u6027\u66f4\u6539\u53ef\u80fd\u4f1a\u5bfc\u81f4\u5e94\u7528\u7a0b\u5e8f\u90e8\u5206\u6216\u5b8c\u5168\u5931\u53bb\u5176\u529f\u80fd\u3002\u5f00\u53d1\u4eba\u5458\u4e0d\u627f\u8bfa\u66f4\u65b0\u5e94\u7528\u7a0b\u5e8f\u6216\u7ef4\u62a4\u670d\u52a1\u4ee5\u5e94\u5bf9\u6b64\u7c7b\u57fa\u7840\u8bbe\u65bd\u53d8\u66f4\uff0c\u8fd9\u88ab\u89c6\u4e3a\u201c\u4e0d\u53ef\u6297\u529b\u201d\u3002",
      "ad_wait_message":
          "\u5206\u6790\u5b8c\u6210\uff0c\u7ed3\u679c\u5c06\u5728\u5e7f\u544a\u540e\u663e\u793a\u3002",
      "analysis_failed_title": "\u5206\u6790\u5931\u8d25",
      "analysis_failed_reason": "\u539f\u56e0\uff1a{reason}",
      "analysis_failed_hint":
          "\u63d0\u793a\uff1a\u6ce8\u9500\u5e76\u91cd\u65b0\u767b\u5f55\u53ef\u80fd\u4f1a\u6709\u6240\u5e2e\u52a9\u3002",
      "analysis_fast_no_change":
          "\u5feb\u901f\u68c0\u67e5\uff1a\u8ba1\u6570\u76f8\u540c\u3002\u672a\u68c0\u6d4b\u5230\u4efb\u4f55\u53d8\u5316\u3002",
      "usage_metrics_title": "\u6bcf\u65e5\u6307\u6807",
      "usage_metrics_active": "\u6d3b\u8dc3\u7528\u6237",
      "usage_metrics_queries": "\u6bcf\u65e5\u67e5\u8be2",
      "usage_metrics_na": "--",
      "usage_metrics_live": "\u73b0\u573a\u9762\u677f",
    },
    'id': {
      "tagline": "Solusi Media Sosial Profesional",
      "adsense_banner": "RUANG IKLAN",
      "admin_active_note": "Mode Admin aktif",
      "free_app_note":
          "Kami berkembang setiap hari untuk memberikan Anda pengalaman yang lebih baik. Masukan Anda sangat berharga bagi kami\u2014kami ingin mendengar pendapat Anda!",
      "login_prompt": "Silakan masuk untuk memulai analisis.",
      "welcome": "Selamat datang, {username}",
      "refresh_data": "SEGARKAN DATA",
      "login_with_instagram": "MASUK DENGAN INSTAGRAM",
      "fetching_data":
          "Menganalisis data...\nIni mungkin memerlukan waktu beberapa saat.",
      "processing_data": "Memproses data...\nHampir selesai.",
      "loading_ad": "Memuat iklan...\nHarap tunggu.",
      "google_ad_warning": "Peringatan iklan Google: {reason}",
      "analysis_secure":
          "Semua analisis diproses dengan aman secara lokal di perangkat Anda.",
      "today_total_analysis": "Total analisis hari ini: {count}",
      "next_analysis": "Analisis selanjutnya",
      "next_analysis_ready": "Siap memindai.",
      "analysis_available_now": "Analisis tersedia sekarang",
      "analysis_ready_risk":
          "Analisis kini tersedia, namun menjalankan analisis secara berulang-ulang dapat membahayakan akun Anda.",
      "please_wait": "Harap tunggu",
      "warning": "Peringatan",
      "remaining_time": "Analisis selanjutnya: {time}",
      "watch_ad": "TONTON IKLAN DAN MULAI ANALISIS",
      "start_analysis": "MULAI ANALISIS",
      "start_analysis_question": "Mulai analisis?",
      "clear_data_title": "Setel Ulang Data Aplikasi",
      "clear_data_content":
          "Ini akan menghapus semua data lokal dan cookie sesi. Apa kamu yakin?",
      "cancel": "BATAL",
      "delete": "HAPUS",
      "error_title": "Kesalahan",
      "data_fetch_error":
          "Pengambilan data gagal: {err}\n\nPemecahan Masalah: Coba keluar dan masuk kembali.",
      "followers": "Pengikut",
      "following": "Mengikuti",
      "new_followers": "Pengikut Baru",
      "non_followers": "Tidak Mengikuti Balik",
      "left_followers": "Berhenti mengikuti",
      "legal_warning": "Penafian Hukum",
      "left_following": "Akun yang Anda berhenti ikuti",
      "rate_us": "Nilai Kami",
      "contact_us": "Hubungi Kami",
      "remove_ads_and_limits":
          "Hapus Iklan & Waktu Tunggu",
      "rate_test_message": "Kotak ini sedang diuji.",
      "story_section_title":
          "Tonton Cerita Secara Diam-diam atau Zoom Foto Profil",
      "story_login_required":
          "Untuk melihat story secara anonim, diperlukan sesi login Instagram yang valid. Jika Anda sudah login tetapi peringatan ini masih muncul, keluar dari Instagram lalu masuk kembali.",
      "story_ad_wait": "Akan ditampilkan setelah iklan, harap tunggu.",
      "story_action_title": "Apa yang ingin Anda lakukan?",
      "story_view_photo": "Perbesar foto profil",
      "story_watch_secret": "Lihat story tanpa jejak",
      "story_no_data": "Tidak ada data cerita yang tersedia.",
      "story_close": "TUTUP",
      "read_and_agree": "SAYA TELAH MEMBACA DAN SETUJU",
      "withdraw_consent": "Menarik Persetujuan",
      "withdraw_consent_confirm_title": "Konfirmasi",
      "withdraw_consent_confirm_body":
          "Setelan izin Anda akan disetel ulang. Apa kamu yakin?",
      "withdraw_consent_confirm_yes": "Ya",
      "withdraw_consent_confirm_no": "Batal",
      "no_data": "Tidak ada data",
      "new_badge": "BARU",
      "login_title": "Masuk",
      'user_label': 'Pengguna',
      "redirecting": "Sesi terverifikasi, mengalihkan dengan aman...",
      "data_updated": "Analisis selesai \u2705",
      "purchases_not_configured":
          "Pembelian tidak tersedia saat ini. Silakan coba lagi nanti.",
      "premium_not_active":
          "Pembelian selesai, namun Premium belum aktif. Silakan coba lagi.",
      "premium_welcome_box":
          "Selamat datang di Premium! Iklan dan waktu tunggu dihapus.",
      "premium_already_active": "Keanggotaan Premium Anda aktif.",
      "restore_purchases": "Kembalikan Pembelian",
      "restore_purchases_short": "PEMBALIKAN",
      "restoring_purchases": "Memulihkan pembelian...",
      "restore_purchases_success": "Pembelian dipulihkan \u2705",
      "restore_purchases_none": "Tidak ada pembelian yang perlu dipulihkan.",
      "restore_purchases_failed": "Pemulihan gagal: {err}",
      "enter_pin": "Masukkan PIN",
      "pin_accepted": "PIN diterima, pengatur waktu disetel ulang \u2705",
      "pin_incorrect": "PIN tidak valid",
      "ok": "OK",
      "legal_intro":
          "Dengan mengunduh dan menggunakan aplikasi ini, setiap Pengguna dianggap telah membaca, memahami, dan menerima secara tidak dapat ditarik kembali teks \"Ketentuan Penggunaan dan Penafian\" di bawah ini terlebih dahulu:",
      "article1_title":
          "Artikel 1: Privasi Data dan Arsitektur Pemrosesan Lokal",
      "article2_title": "Artikel 2: Risiko Platform Pihak Ketiga",
      "article3_title":
          "Artikel 3: Penafian Garansi dan Batasan Tanggung Jawab",
      "article4_title":
          "Pasal 4: Pemberitahuan Kekayaan Intelektual dan Kemerdekaan",
      "article5_title": "Pasal 5: Kontinuitas Layanan dan Perubahan Platform",
      "article5_text":
          "Perubahan mendasar pada API Instagram atau infrastruktur web dapat menyebabkan aplikasi kehilangan fungsinya sebagian atau seluruhnya. Pengembang tidak berkomitmen untuk memperbarui aplikasi atau memelihara layanan sebagai respons terhadap perubahan infrastruktur tersebut, yang dianggap sebagai \"keadaan kahar\".",
      "ad_wait_message":
          "Analisis selesai, hasilnya akan ditampilkan setelah iklan.",
      "analysis_failed_title": "Analisis gagal",
      "analysis_failed_reason": "Alasan: {reason}",
      "analysis_failed_hint":
          "Tip: Keluar dan masuk kembali mungkin bisa membantu.",
      "analysis_fast_no_change":
          "Pemeriksaan cepat: Jumlahnya sama. Tidak ada perubahan yang terdeteksi.",
      "usage_metrics_title": "Metrik Harian",
      "usage_metrics_active": "Pengguna aktif",
      "usage_metrics_queries": "Pertanyaan harian",
      "usage_metrics_na": "--",
      "usage_metrics_live": "panel langsung",
    },
    'nl': {
      "tagline": "Professionele sociale media-oplossingen",
      "adsense_banner": "ADVERTENTIERUIMTE",
      "admin_active_note": "Beheermodus actief",
      "free_app_note":
          "We ontwikkelen ons elke dag om u een betere ervaring te bieden. Uw feedback is waardevol voor ons; we horen graag van u!",
      "login_prompt": "Log in om de analyse te starten.",
      "welcome": "Welkom, {username}",
      'refresh_data': 'GEGEVENS VERNIEUWEN',
      "login_with_instagram": "LOG IN MET INSTAGRAM",
      "fetching_data": "Gegevens analyseren...\nDit kan even duren.",
      "processing_data": "Gegevens verwerken...\nBijna klaar.",
      "loading_ad": "Advertentie laden...\nWacht alstublieft.",
      "google_ad_warning": "Google-advertentiewaarschuwing: {reason}",
      "analysis_secure":
          "Alle analyses worden veilig lokaal op uw apparaat verwerkt.",
      "today_total_analysis": "Totaalanalyses vandaag: {count}",
      "next_analysis": "Volgende analyse",
      "next_analysis_ready": "Klaar om te scannen.",
      "analysis_available_now": "Analyse nu beschikbaar",
      "analysis_ready_risk":
          "De analyse is nu beschikbaar, maar het achter elkaar uitvoeren van analyses kan uw account in gevaar brengen.",
      "please_wait": "Een ogenblik geduld",
      "warning": "Waarschuwing",
      "remaining_time": "Volgende analyse: {time}",
      "watch_ad": "KIJK ADVERTENTIE EN START DE ANALYSE",
      "start_analysis": "ANALYSE STARTEN",
      "start_analysis_question": "Analyse starten?",
      "clear_data_title": "App-gegevens opnieuw instellen",
      "clear_data_content":
          "Hiermee worden alle lokale gegevens en sessiecookies gewist. Weet je het zeker?",
      "cancel": "ANNULEREN",
      "delete": "VERWIJDEREN",
      "error_title": "Fout",
      "data_fetch_error":
          "Gegevens ophalen mislukt: {err}\n\nProblemen oplossen: Probeer uit te loggen en weer in te loggen.",
      "followers": "Volgers",
      'following': 'Volgend',
      "new_followers": "Nieuwe volgers",
      "non_followers": "Volg niet terug",
      "left_followers": "Ontvolgers",
      "legal_warning": "Juridische disclaimer",
      "left_following": "Niet-gevolgde gebruikers",
      "rate_us": "Beoordeel ons",
      "contact_us": "Neem contact met ons op",
      "remove_ads_and_limits":
          "Verwijder advertenties en wachttijden",
      "rate_test_message": "Deze box wordt momenteel getest.",
      "story_section_title":
          "Bekijk verhalen in het geheim of zoom in op profielfoto's",
      "story_login_required": "Voor het anoniem bekijken van stories is een geldige Instagram-login nodig. Ben je al ingelogd maar zie je deze melding nog steeds, log dan uit bij Instagram en log opnieuw in.",
      "story_ad_wait":
          "Wordt weergegeven na de advertentie, even geduld a.u.b.",
      "story_action_title": "Wat zou je graag willen doen?",
      "story_view_photo": "Profielfoto vergroten",
      "story_watch_secret": "Bekijk het verhaal in het geheim",
      "story_no_data": "Geen verhaalgegevens beschikbaar.",
      "story_close": "SLUITEN",
      "read_and_agree": "IK HEB HET GELEZEN EN GA AKKOORD",
      "withdraw_consent": "Toestemming intrekken",
      "withdraw_consent_confirm_title": "Bevestigen",
      "withdraw_consent_confirm_body":
          "Uw toestemmingsinstellingen worden gereset. Weet je het zeker?",
      "withdraw_consent_confirm_yes": "Ja",
      "withdraw_consent_confirm_no": "Annuleren",
      "no_data": "Geen gegevens",
      "new_badge": "NIEUW",
      "login_title": "Inloggen",
      'user_label': 'Gebruiker',
      "redirecting": "Sessie geverifieerd, veilig doorverwezen...",
      "data_updated": "Analyse voltooid \u2705",
      "purchases_not_configured":
          "Aankopen zijn momenteel niet beschikbaar. Probeer het later opnieuw.",
      "premium_not_active":
          "Aankoop voltooid, maar Premium is nog niet actief. Probeer het opnieuw.",
      "premium_welcome_box":
          "Welkom bij Premium! Advertenties en wachttijden zijn verwijderd.",
      "premium_already_active": "Uw Premium-lidmaatschap is actief.",
      "restore_purchases": "Aankopen herstellen",
      "restore_purchases_short": "HERSTELLEN",
      "restoring_purchases": "Aankopen herstellen...",
      "restore_purchases_success": "Aankopen hersteld \u2705",
      "restore_purchases_none": "Geen aankopen om te herstellen.",
      "restore_purchases_failed": "Herstellen mislukt: {err}",
      "enter_pin": "Voer pincode in",
      "pin_accepted": "PIN geaccepteerd, timer gereset \u2705",
      "pin_incorrect": "Ongeldige pincode",
      "ok": "OK",
      "legal_intro":
          "Door deze applicatie te downloaden en te gebruiken, wordt elke Gebruiker geacht de onderstaande tekst \"Gebruiksvoorwaarden en Disclaimer\" vooraf te hebben gelezen, begrepen en onherroepelijk aanvaard:",
      "article1_title":
          "Artikel 1: Gegevensprivacy en lokale verwerkingsarchitectuur",
      "article2_title": "Artikel 2: Risico's van platforms van derden",
      "article3_title":
          "Artikel 3: Garantiedisclaimer en beperking van aansprakelijkheid",
      "article4_title":
          "Artikel 4: Intellectuele eigendom en onafhankelijkheidsverklaring",
      "article5_title":
          "Artikel 5: Servicecontinu\u00efteit en platformwijzigingen",
      "article5_text":
          "Fundamentele wijzigingen aan de Instagram API of webinfrastructuur kunnen ervoor zorgen dat de applicatie zijn functionaliteit geheel of gedeeltelijk verliest. De ontwikkelaar doet geen enkele toezegging om de applicatie bij te werken of de service te onderhouden als reactie op dergelijke infrastructurele veranderingen, die als \"overmacht\" worden beschouwd.",
      "ad_wait_message":
          "Analyse voltooid, resultaten worden na de advertentie weergegeven.",
      "analysis_failed_title": "Analyse mislukt",
      "analysis_failed_reason": "Reden: {reason}",
      "analysis_failed_hint": "Tip: Uitloggen en opnieuw inloggen kan helpen.",
      "analysis_fast_no_change":
          "Snelle controle: Tellingen zijn hetzelfde. Geen wijzigingen gedetecteerd.",
      "usage_metrics_title": "Dagelijkse statistieken",
      "usage_metrics_active": "Actieve gebruikers",
      "usage_metrics_queries": "Dagelijkse vragen",
      "usage_metrics_na": "--",
      "usage_metrics_live": "live-paneel",
    },
    'fr': {
      "tagline": "Solutions professionnelles de m\u00e9dias sociaux",
      "adsense_banner": "ESPACE PUB",
      "admin_active_note": "Mode administrateur actif",
      "free_app_note":
          "Nous \u00e9voluons chaque jour pour vous offrir une meilleure exp\u00e9rience. Vos commentaires sont pr\u00e9cieux pour nous\u00a0; nous serions ravis de vous entendre\u00a0!",
      "login_prompt": "Veuillez vous connecter pour d\u00e9marrer l'analyse.",
      "welcome": "Bienvenue, {username}",
      "refresh_data": "ACTUALISER LES DONN\u00c9ES",
      "login_with_instagram": "CONNEXION AVEC INSTAGRAM",
      "fetching_data":
          "Analyse des donn\u00e9es...\nCela peut prendre un moment.",
      "processing_data":
          "Traitement des donn\u00e9es...\nPresque termin\u00e9.",
      "loading_ad": "Chargement de l'annonce...\nVeuillez patienter.",
      "google_ad_warning": "Avertissement publicitaire Google\u00a0: {reason}",
      "analysis_secure":
          "Toutes les analyses sont trait\u00e9es en toute s\u00e9curit\u00e9 localement sur votre appareil.",
      "today_total_analysis": "Analyses totales aujourd'hui\u00a0: {count}",
      "next_analysis": "Analyse suivante",
      "next_analysis_ready": "Pr\u00eat \u00e0 num\u00e9riser.",
      "analysis_available_now": "Analyse disponible maintenant",
      "analysis_ready_risk":
          "L'analyse est d\u00e9j\u00e0 disponible, mais encha\u00eener les analyses peut mettre votre compte en danger.",
      "please_wait": "Veuillez patienter",
      "warning": "Avertissement",
      "remaining_time": "Analyse suivante\u00a0: {time}",
      "watch_ad": "REGARDER L'ANNONCE ET COMMENCER L'ANALYSE",
      "start_analysis": "D\u00c9MARRER L'ANALYSE",
      "start_analysis_question": "D\u00e9marrer l'analyse\u00a0?",
      "clear_data_title":
          "R\u00e9initialiser les donn\u00e9es de l'application",
      "clear_data_content":
          "Cela effacera toutes les donn\u00e9es locales et les cookies de session. Es-tu s\u00fbr?",
      "cancel": "ANNULER",
      "delete": "SUPPRIMER",
      "error_title": "Erreur",
      "data_fetch_error":
          "\u00c9chec de la r\u00e9cup\u00e9ration des donn\u00e9es\u00a0: {err}\n\nD\u00e9pannage\u00a0: essayez de vous d\u00e9connecter et de vous reconnecter.",
      "followers": "Abonn\u00e9s",
      'following': 'Abonnements',
      "new_followers": "Nouveaux abonn\u00e9s",
      "non_followers": "Ne vous suivent pas",
      'left_followers': 'D\u00E9sabonnements',
      "legal_warning": "Mentions l\u00e9gales",
      "left_following": "Comptes que vous ne suivez plus",
      "rate_us": "\u00c9valuez-nous",
      "contact_us": "Contactez-nous",
      "remove_ads_and_limits":
          "Supprimer les publicit\u00e9s et les temps d'attente",
      "rate_test_message": "Cette box est actuellement en test.",
      "story_section_title":
          "Regardez des histoires en secret ou zoomez sur les photos de profil",
      "story_login_required":
          "Pour voir les stories en mode anonyme, une session Instagram valide est nécessaire. Si vous êtes déjà connecté mais que ce message persiste, déconnectez-vous de Instagram puis reconnectez-vous.",
      "story_ad_wait":
          "Sera affich\u00e9 apr\u00e8s la publicit\u00e9, veuillez patienter.",
      "story_action_title": "Que souhaiteriez-vous faire\u00a0?",
      "story_view_photo": "Agrandir la photo de profil",
      "story_watch_secret": "Voir la story sans laisser de trace",
      "story_no_data": "Aucune donn\u00e9e d'histoire disponible.",
      "story_close": "FERMER",
      "read_and_agree": "J'AI LU ET J'ACCEPTE",
      "withdraw_consent": "Retirer le consentement",
      "withdraw_consent_confirm_title": "Confirmer",
      "withdraw_consent_confirm_body":
          "Vos param\u00e8tres de consentement seront r\u00e9initialis\u00e9s. Es-tu s\u00fbr?",
      "withdraw_consent_confirm_yes": "Oui",
      "withdraw_consent_confirm_no": "Annuler",
      "no_data": "Aucune donn\u00e9e",
      "new_badge": "NOUVEAU",
      "login_title": "Connexion",
      'user_label': 'Utilisateur',
      "redirecting":
          "Session v\u00e9rifi\u00e9e, redirection s\u00e9curis\u00e9e...",
      "data_updated": "Analyse termin\u00e9e \u2705",
      "purchases_not_configured":
          "Les achats ne sont pas disponibles pour le moment. Veuillez r\u00e9essayer plus tard.",
      "premium_not_active":
          "Achat termin\u00e9, mais Premium n'est pas encore actif. Veuillez r\u00e9essayer.",
      "premium_welcome_box":
          "Bienvenue sur Premium\u00a0! Les publicit\u00e9s et les temps d'attente sont supprim\u00e9s.",
      "premium_already_active": "Votre abonnement Premium est actif.",
      "restore_purchases": "Restaurer les achats",
      "restore_purchases_short": "RESTAURER",
      "restoring_purchases": "Restaurer les achats...",
      "restore_purchases_success": "Achats restaur\u00e9s \u2705",
      "restore_purchases_none": "Aucun achat \u00e0 restaurer.",
      "restore_purchases_failed": "\u00c9chec de la restauration\u00a0: {err}",
      "enter_pin": "Entrez le code PIN",
      "pin_accepted":
          "PIN accept\u00e9, r\u00e9initialisation du minuteur \u2705",
      "pin_incorrect": "PIN invalide",
      "ok": "OK",
      "legal_intro":
          "En t\u00e9l\u00e9chargeant et en utilisant cette application, chaque utilisateur est r\u00e9put\u00e9 avoir lu, compris et accept\u00e9 irr\u00e9vocablement le texte des \u00ab\u00a0Conditions d'utilisation et clause de non-responsabilit\u00e9\u00a0\u00bb ci-dessous\u00a0:",
      "article1_title":
          "Article 1\u00a0:\u00a0Confidentialit\u00e9 des donn\u00e9es et architecture de traitement local",
      "article2_title":
          "Article 2\u00a0:\u00a0Risques li\u00e9s aux plateformes tierces",
      "article3_title":
          "Article 3\u00a0:\u00a0Exclusion de garantie et limitation de responsabilit\u00e9",
      "article4_title":
          "Article 4 : Propri\u00e9t\u00e9 Intellectuelle et Avis d'Ind\u00e9pendance",
      "article5_title":
          "Article 5\u00a0:\u00a0Continuit\u00e9 du service et modifications de la plateforme",
      "article5_text":
          "Des modifications fondamentales apport\u00e9es \u00e0 l'API Instagram ou \u00e0 l'infrastructure Web peuvent entra\u00eener la perte partielle ou totale de l'application de ses fonctionnalit\u00e9s. Le d\u00e9veloppeur ne s'engage pas \u00e0 mettre \u00e0 jour l'application ou \u00e0 maintenir le service en r\u00e9ponse \u00e0 de tels changements d'infrastructure, qui sont consid\u00e9r\u00e9s comme \u00ab force majeure \u00bb.",
      "ad_wait_message":
          "Analyse termin\u00e9e, les r\u00e9sultats seront affich\u00e9s apr\u00e8s la publicit\u00e9.",
      "analysis_failed_title": "\u00c9chec de l'analyse",
      "analysis_failed_reason": "Raison\u00a0: {reason}",
      "analysis_failed_hint":
          "Astuce\u00a0:\u00a0Se d\u00e9connecter et se reconnecter peut s'av\u00e9rer utile.",
      "analysis_fast_no_change":
          "V\u00e9rification rapide\u00a0: les comptes sont les m\u00eames. Aucun changement d\u00e9tect\u00e9.",
      "usage_metrics_title": "Mesures quotidiennes",
      "usage_metrics_active": "Utilisateurs actifs",
      "usage_metrics_queries": "Requ\u00eates quotidiennes",
      "usage_metrics_na": "--",
      "usage_metrics_live": "panneau en direct",
    },
    'it': {
      "tagline": "Soluzioni professionali per social media",
      "adsense_banner": "SPAZIO ANNUNCIO",
      "admin_active_note": "Modalit\u00e0 amministratore attiva",
      "free_app_note":
          "Ci evolviamo ogni giorno per offrirti un'esperienza migliore. Il tuo feedback \u00e8 prezioso per noi: ci piacerebbe sentire la tua opinione!",
      "login_prompt": "Accedi per avviare l'analisi.",
      "welcome": "Benvenuto, {username}",
      "refresh_data": "AGGIORNA DATI",
      "login_with_instagram": "ACCEDI CON INSTAGRAM",
      "fetching_data":
          "Analisi dei dati in corso...\nL'operazione potrebbe richiedere un momento.",
      "processing_data": "Elaborazione dati...\nQuasi finito.",
      "loading_ad": "Caricamento annuncio...\nPer favore aspetta.",
      "google_ad_warning": "Avviso annuncio Google: {reason}",
      "analysis_secure":
          "Tutte le analisi vengono elaborate in modo sicuro localmente sul tuo dispositivo.",
      "today_total_analysis": "Totale analisi oggi: {count}",
      "next_analysis": "Prossima analisi",
      "next_analysis_ready": "Pronto per la scansione.",
      "analysis_available_now": "Analisi ora disponibile",
      "analysis_ready_risk":
          "L'analisi \u00e8 ora disponibile, ma l'esecuzione di analisi consecutive potrebbe mettere a rischio il tuo account.",
      "please_wait": "Attendere",
      "warning": "Attenzione",
      "remaining_time": "Prossima analisi: {time}",
      "watch_ad": "GUARDA L'ANNUNCIO E INIZIA L'ANALISI",
      "start_analysis": "INIZIA ANALISI",
      "start_analysis_question": "Avviare l'analisi?",
      "clear_data_title": "Reimposta i dati dell'app",
      "clear_data_content":
          "Questa operazione canceller\u00e0 tutti i dati locali e i cookie di sessione. Sei sicuro?",
      "cancel": "ANNULLA",
      "delete": "CANCELLA",
      "error_title": "Errore",
      "data_fetch_error":
          "Recupero dati non riuscito: {err}\n\nRisoluzione del problema: prova a disconnetterti e ad accedere nuovamente.",
      "followers": "Follower",
      'following': 'Seguiti',
      "new_followers": "Nuovi follower",
      'non_followers': 'Utenti che non ricambiano',
      "left_followers": "Unfollowers",
      "legal_warning": "Disclaimer legale",
      "left_following": "Utenti non seguiti",
      "rate_us": "Valutaci",
      "contact_us": "Contattaci",
      "remove_ads_and_limits":
          "Rimuovi pubblicit\u00e0 e tempi di attesa",
      "rate_test_message": "Questa scatola \u00e8 attualmente in fase di test.",
      "story_section_title":
          "Guarda le storie di nascosto o ingrandisci le foto del profilo",
      "story_login_required": "Per vedere le storie in modo anonimo serve una sessione Instagram valida. Se hai già fatto login ma questo avviso continua a comparire, esci da Instagram e accedi di nuovo.",
      "story_ad_wait": "Verr\u00e0 mostrato dopo l'annuncio, attendere.",
      "story_action_title": "Cosa ti piacerebbe fare?",
      "story_view_photo": "Ingrandisci la foto del profilo",
      "story_watch_secret": "Guarda la storia in segreto",
      "story_no_data": "Nessun dato sulla storia disponibile.",
      "story_close": "CHIUDI",
      "read_and_agree": "HO LETTO E ACCETTO",
      "withdraw_consent": "Revocare il consenso",
      "withdraw_consent_confirm_title": "Conferma",
      "withdraw_consent_confirm_body":
          "Le impostazioni del consenso verranno ripristinate. Sei sicuro?",
      "withdraw_consent_confirm_yes": "S\u00ec",
      "withdraw_consent_confirm_no": "Annulla",
      "no_data": "Nessun dato",
      "new_badge": "NUOVO",
      "login_title": "Accedi",
      'user_label': 'Utente',
      "redirecting": "Sessione verificata, reindirizzamento sicuro...",
      "data_updated": "Analisi completata \u2705",
      "purchases_not_configured":
          "Gli acquisti non sono disponibili al momento. Per favore riprova pi\u00f9 tardi.",
      "premium_not_active":
          "Acquisto completato, ma Premium non \u00e8 ancora attivo. Per favore riprova.",
      "premium_welcome_box":
          "Benvenuto in Premium! Gli annunci e i tempi di attesa vengono rimossi.",
      "premium_already_active": "Il tuo abbonamento Premium \u00e8 attivo.",
      "restore_purchases": "Ripristina acquisti",
      "restore_purchases_short": "RIPRISTINA",
      "restoring_purchases": "Ripristino degli acquisti in corso...",
      "restore_purchases_success": "Acquisti ripristinati \u2705",
      "restore_purchases_none": "Nessun acquisto da ripristinare.",
      "restore_purchases_failed": "Ripristino non riuscito: {err}",
      "enter_pin": "Inserisci il PIN",
      "pin_accepted": "PIN accettato, reset timer \u2705",
      "pin_incorrect": "PIN non valido",
      "ok": "OK",
      "legal_intro":
          "Scaricando e utilizzando questa applicazione, si ritiene che ogni Utente abbia letto, compreso e accettato irrevocabilmente in anticipo il testo \"Termini di utilizzo e Dichiarazione di non responsabilit\u00e0\" di seguito riportato:",
      "article1_title":
          "Articolo 1: Privacy dei dati e architettura di trattamento locale",
      "article2_title": "Articolo 2: Rischi della piattaforma di terze parti",
      "article3_title":
          "Articolo 3: Esclusione di garanzia e limitazione di responsabilit\u00e0",
      "article4_title":
          "Articolo 4: Avviso sulla propriet\u00e0 intellettuale e sull'indipendenza",
      "article5_title":
          "Articolo 5: Continuit\u00e0 del servizio e modifiche alla piattaforma",
      "article5_text":
          "Modifiche fondamentali all'API di Instagram o all'infrastruttura web possono causare la perdita parziale o totale delle funzionalit\u00e0 dell'applicazione. Lo sviluppatore non si impegna ad aggiornare l'applicazione o a mantenere il servizio in risposta a tali cambiamenti infrastrutturali, che sono considerati \"forza maggiore\".",
      "ad_wait_message":
          "Analisi completata, i risultati verranno visualizzati dopo l'annuncio.",
      "analysis_failed_title": "Analisi non riuscita",
      "analysis_failed_reason": "Motivo: {reason}",
      "analysis_failed_hint":
          "Suggerimento: disconnettersi e accedere nuovamente pu\u00f2 essere utile.",
      "analysis_fast_no_change":
          "Controllo rapido: i conteggi sono gli stessi. Nessuna modifica rilevata.",
      "usage_metrics_title": "Metriche giornaliere",
      "usage_metrics_active": "Utenti attivi",
      "usage_metrics_queries": "Query quotidiane",
      "usage_metrics_na": "--",
      "usage_metrics_live": "pannello live",
    },
    'vi': {
      "tagline":
          "Gi\u1ea3i ph\u00e1p truy\u1ec1n th\u00f4ng x\u00e3 h\u1ed9i chuy\u00ean nghi\u1ec7p",
      "adsense_banner": "V\u1eca TR\u00cd QU\u1ea2NG C\u00c1O",
      "admin_active_note":
          "Ch\u1ebf \u0111\u1ed9 qu\u1ea3n tr\u1ecb \u0111ang ho\u1ea1t \u0111\u1ed9ng",
      "free_app_note":
          "Ch\u00fang t\u00f4i \u0111ang ph\u00e1t tri\u1ec3n m\u1ed7i ng\u00e0y \u0111\u1ec3 mang \u0111\u1ebfn cho b\u1ea1n tr\u1ea3i nghi\u1ec7m t\u1ed1t h\u01a1n. Ph\u1ea3n h\u1ed3i c\u1ee7a b\u1ea1n r\u1ea5t c\u00f3 gi\u00e1 tr\u1ecb \u0111\u1ed1i v\u1edbi ch\u00fang t\u00f4i\u2014ch\u00fang t\u00f4i r\u1ea5t mong nh\u1eadn \u0111\u01b0\u1ee3c ph\u1ea3n h\u1ed3i t\u1eeb b\u1ea1n!",
      "login_prompt":
          "Vui l\u00f2ng \u0111\u0103ng nh\u1eadp \u0111\u1ec3 b\u1eaft \u0111\u1ea7u ph\u00e2n t\u00edch.",
      "welcome": "Ch\u00e0o m\u1eebng, {username}",
      "refresh_data": "L\u00c0M M\u1edaI D\u1eee LI\u1ec6U",
      "login_with_instagram": "\u0110\u0102NG NH\u1eacP B\u1eb0NG INSTAGRAM",
      "fetching_data":
          "\u0110ang ph\u00e2n t\u00edch d\u1eef li\u1ec7u...\nVi\u1ec7c n\u00e0y c\u00f3 th\u1ec3 m\u1ea5t m\u1ed9t ch\u00fat th\u1eddi gian.",
      "processing_data":
          "\u0110ang x\u1eed l\u00fd d\u1eef li\u1ec7u...\nG\u1ea7n xong r\u1ed3i.",
      "loading_ad":
          "\u0110ang t\u1ea3i qu\u1ea3ng c\u00e1o...\nXin vui l\u00f2ng ch\u1edd \u0111\u1ee3i.",
      "google_ad_warning":
          "C\u1ea3nh b\u00e1o qu\u1ea3ng c\u00e1o c\u1ee7a Google: {reason}",
      "analysis_secure":
          "T\u1ea5t c\u1ea3 ph\u00e2n t\u00edch \u0111\u1ec1u \u0111\u01b0\u1ee3c x\u1eed l\u00fd an to\u00e0n c\u1ee5c b\u1ed9 tr\u00ean thi\u1ebft b\u1ecb c\u1ee7a b\u1ea1n.",
      "today_total_analysis":
          "T\u1ed5ng s\u1ed1 ph\u00e2n t\u00edch ng\u00e0y h\u00f4m nay: {count}",
      "next_analysis": "Ph\u00e2n t\u00edch ti\u1ebfp theo",
      "next_analysis_ready": "S\u1eb5n s\u00e0ng qu\u00e9t.",
      "analysis_available_now": "Ph\u00e2n t\u00edch hi\u1ec7n c\u00f3 s\u1eb5n",
      "analysis_ready_risk":
          "Ph\u00e2n t\u00edch hi\u1ec7n \u0111\u00e3 s\u1eb5n s\u00e0ng, nh\u01b0ng ch\u1ea1y ph\u00e2n t\u00edch li\u00ean t\u1ee5c c\u00f3 th\u1ec3 khi\u1ebfn t\u00e0i kho\u1ea3n c\u1ee7a b\u1ea1n g\u1eb7p r\u1ee7i ro.",
      "please_wait": "Xin vui l\u00f2ng \u0111\u1ee3i",
      "warning": "C\u1ea3nh b\u00e1o",
      "remaining_time": "Ph\u00e2n t\u00edch ti\u1ebfp theo: {time}",
      "watch_ad":
          "XEM QU\u1ea2NG C\u00c1O V\u00c0 B\u1eaeT \u0110\u1ea6U PH\u00c2N T\u00cdCH",
      "start_analysis": "B\u1eaeT \u0110\u1ea6U PH\u00c2N T\u00cdCH",
      "start_analysis_question": "B\u1eaft \u0111\u1ea7u ph\u00e2n t\u00edch?",
      "clear_data_title":
          "\u0110\u1eb7t l\u1ea1i d\u1eef li\u1ec7u \u1ee9ng d\u1ee5ng",
      "clear_data_content":
          "Vi\u1ec7c n\u00e0y s\u1ebd x\u00f3a t\u1ea5t c\u1ea3 d\u1eef li\u1ec7u c\u1ee5c b\u1ed9 v\u00e0 cookie phi\u00ean. B\u1ea1n c\u00f3 ch\u1eafc kh\u00f4ng?",
      "cancel": "H\u1ee6Y",
      "delete": "DELETE",
      "error_title": "L\u1ed7i",
      "data_fetch_error":
          "Truy xu\u1ea5t d\u1eef li\u1ec7u kh\u00f4ng th\u00e0nh c\u00f4ng: {err}\n\nKh\u1eafc ph\u1ee5c s\u1ef1 c\u1ed1: H\u00e3y th\u1eed \u0111\u0103ng xu\u1ea5t v\u00e0 \u0111\u0103ng nh\u1eadp l\u1ea1i.",
      "followers": "Ng\u01b0\u1eddi theo d\u00f5i",
      "following": "\u0110ang theo d\u00f5i",
      "new_followers": "Ng\u01b0\u1eddi theo d\u00f5i m\u1edbi",
      "non_followers": "\u0110\u1eebng theo d\u00f5i l\u1ea1i",
      "left_followers": "Ng\u01b0\u1eddi h\u1ee7y theo d\u00f5i",
      "legal_warning":
          "Tuy\u00ean b\u1ed1 mi\u1ec5n tr\u1eeb tr\u00e1ch nhi\u1ec7m ph\u00e1p l\u00fd",
      "left_following":
          "Ng\u01b0\u1eddi d\u00f9ng ch\u01b0a \u0111\u01b0\u1ee3c theo d\u00f5i",
      "rate_us": "\u0110\u00e1nh gi\u00e1 ch\u00fang t\u00f4i",
      "contact_us": "Li\u00ean h\u1ec7 v\u1edbi ch\u00fang t\u00f4i",
      "remove_ads_and_limits":
          "X\u00f3a qu\u1ea3ng c\u00e1o v\u00e0 th\u1eddi gian ch\u1edd",
      "rate_test_message":
          "H\u1ed9p n\u00e0y hi\u1ec7n \u0111ang \u0111\u01b0\u1ee3c th\u1eed nghi\u1ec7m.",
      "story_section_title":
          "Xem c\u00e2u chuy\u1ec7n m\u1ed9t c\u00e1ch b\u00ed m\u1eadt ho\u1eb7c thu ph\u00f3ng \u1ea3nh h\u1ed3 s\u01a1",
      "story_login_required":
          "Để xem story ẩn danh, bạn cần phiên đăng nhập Instagram hợp lệ. Nếu bạn đã đăng nhập mà vẫn thấy thông báo này, hãy đăng xuất khỏi Instagram rồi đăng nhập lại.",
      "story_ad_wait":
          "S\u1ebd hi\u1ec3n th\u1ecb sau qu\u1ea3ng c\u00e1o, vui l\u00f2ng \u0111\u1ee3i.",
      "story_action_title": "B\u1ea1n mu\u1ed1n l\u00e0m g\u00ec?",
      "story_view_photo": "Ph\u00f3ng to \u1ea3nh h\u1ed3 s\u01a1",
      "story_watch_secret": "Xem truy\u1ec7n b\u00ed m\u1eadt",
      "story_no_data":
          "Kh\u00f4ng c\u00f3 d\u1eef li\u1ec7u c\u00e2u chuy\u1ec7n.",
      "story_close": "\u0110\u00d3NG",
      "read_and_agree":
          "T\u00d4I \u0110\u00c3 \u0110\u1eccC V\u00c0 \u0110\u1ed2NG \u00dd",
      "withdraw_consent": "R\u00fat l\u1ea1i s\u1ef1 \u0111\u1ed3ng \u00fd",
      "withdraw_consent_confirm_title": "X\u00e1c nh\u1eadn",
      "withdraw_consent_confirm_body":
          "C\u00e0i \u0111\u1eb7t \u0111\u1ed3ng \u00fd c\u1ee7a b\u1ea1n s\u1ebd \u0111\u01b0\u1ee3c \u0111\u1eb7t l\u1ea1i. B\u1ea1n c\u00f3 ch\u1eafc kh\u00f4ng?",
      "withdraw_consent_confirm_yes": "C\u00f3",
      "withdraw_consent_confirm_no": "H\u1ee7y",
      "no_data": "Kh\u00f4ng c\u00f3 d\u1eef li\u1ec7u",
      "new_badge": "M\u1edaI",
      "login_title": "\u0110\u0103ng nh\u1eadp",
      'user_label': 'Ng\u01B0\u1EDDi d\u00F9ng',
      "redirecting":
          "Phi\u00ean \u0111\u00e3 \u0111\u01b0\u1ee3c x\u00e1c minh, chuy\u1ec3n h\u01b0\u1edbng an to\u00e0n...",
      "data_updated": "Ph\u00e2n t\u00edch ho\u00e0n t\u1ea5t \u2705",
      "purchases_not_configured":
          "Vi\u1ec7c mua h\u00e0ng hi\u1ec7n kh\u00f4ng kh\u1ea3 d\u1ee5ng. Vui l\u00f2ng th\u1eed l\u1ea1i sau.",
      "premium_not_active":
          "Vi\u1ec7c mua h\u00e0ng \u0111\u00e3 ho\u00e0n t\u1ea5t nh\u01b0ng Premium v\u1eabn ch\u01b0a ho\u1ea1t \u0111\u1ed9ng. Vui l\u00f2ng th\u1eed l\u1ea1i.",
      "premium_welcome_box":
          "Ch\u00e0o m\u1eebng b\u1ea1n \u0111\u1ebfn v\u1edbi Premium! Qu\u1ea3ng c\u00e1o v\u00e0 th\u1eddi gian ch\u1edd \u0111\u1ee3i \u0111\u01b0\u1ee3c lo\u1ea1i b\u1ecf.",
      "premium_already_active":
          "T\u01b0 c\u00e1ch th\u00e0nh vi\u00ean Premium c\u1ee7a b\u1ea1n \u0111ang ho\u1ea1t \u0111\u1ed9ng.",
      "restore_purchases": "Kh\u00f4i ph\u1ee5c mua h\u00e0ng",
      "restore_purchases_short": "PH\u1ee4C H\u1ed2I",
      "restoring_purchases":
          "\u0110ang kh\u00f4i ph\u1ee5c giao d\u1ecbch mua...",
      "restore_purchases_success":
          "\u0110\u00e3 kh\u00f4i ph\u1ee5c giao d\u1ecbch mua \u2705",
      "restore_purchases_none":
          "Kh\u00f4ng c\u00f3 giao d\u1ecbch mua n\u00e0o \u0111\u1ec3 kh\u00f4i ph\u1ee5c.",
      "restore_purchases_failed":
          "Kh\u00f4i ph\u1ee5c kh\u00f4ng th\u00e0nh c\u00f4ng: {err}",
      "enter_pin": "Nh\u1eadp m\u00e3 PIN",
      "pin_accepted":
          "PIN \u0111\u01b0\u1ee3c ch\u1ea5p nh\u1eadn, \u0111\u1eb7t l\u1ea1i h\u1eb9n gi\u1edd \u2705",
      "pin_incorrect": "M\u00e3 PIN kh\u00f4ng h\u1ee3p l\u1ec7",
      "ok": "OK",
      "legal_intro":
          "B\u1eb1ng c\u00e1ch t\u1ea3i xu\u1ed1ng v\u00e0 s\u1eed d\u1ee5ng \u1ee9ng d\u1ee5ng n\u00e0y, m\u1ecdi Ng\u01b0\u1eddi d\u00f9ng \u0111\u01b0\u1ee3c coi l\u00e0 \u0111\u00e3 \u0111\u1ecdc, hi\u1ec3u v\u00e0 ch\u1ea5p nh\u1eadn tr\u01b0\u1edbc v\u0103n b\u1ea3n \"\u0110i\u1ec1u kho\u1ea3n s\u1eed d\u1ee5ng v\u00e0 Tuy\u00ean b\u1ed1 t\u1eeb ch\u1ed1i tr\u00e1ch nhi\u1ec7m\" b\u00ean d\u01b0\u1edbi:",
      "article1_title":
          "\u0110i\u1ec1u 1: B\u1ea3o m\u1eadt d\u1eef li\u1ec7u v\u00e0 Ki\u1ebfn tr\u00fac x\u1eed l\u00fd c\u1ee5c b\u1ed9",
      "article2_title":
          "\u0110i\u1ec1u 2: R\u1ee7i ro n\u1ec1n t\u1ea3ng c\u1ee7a b\u00ean th\u1ee9 ba",
      "article3_title":
          "\u0110i\u1ec1u 3: Tuy\u00ean b\u1ed1 mi\u1ec5n tr\u1eeb tr\u00e1ch nhi\u1ec7m b\u1ea3o h\u00e0nh v\u00e0 gi\u1edbi h\u1ea1n tr\u00e1ch nhi\u1ec7m ph\u00e1p l\u00fd",
      "article4_title":
          "\u0110i\u1ec1u 4: Th\u00f4ng b\u00e1o v\u1ec1 s\u1edf h\u1eefu tr\u00ed tu\u1ec7 v\u00e0 \u0111\u1ed9c l\u1eadp",
      "article5_title":
          "\u0110i\u1ec1u 5: T\u00ednh li\u00ean t\u1ee5c c\u1ee7a d\u1ecbch v\u1ee5 v\u00e0 nh\u1eefng thay \u0111\u1ed5i v\u1ec1 n\u1ec1n t\u1ea3ng",
      "article5_text":
          "Nh\u1eefng thay \u0111\u1ed5i c\u01a1 b\u1ea3n \u0111\u1ed1i v\u1edbi API Instagram ho\u1eb7c c\u01a1 s\u1edf h\u1ea1 t\u1ea7ng web c\u00f3 th\u1ec3 khi\u1ebfn \u1ee9ng d\u1ee5ng m\u1ea5t m\u1ed9t ph\u1ea7n ho\u1eb7c to\u00e0n b\u1ed9 ch\u1ee9c n\u0103ng. Nh\u00e0 ph\u00e1t tri\u1ec3n kh\u00f4ng cam k\u1ebft c\u1eadp nh\u1eadt \u1ee9ng d\u1ee5ng ho\u1eb7c duy tr\u00ec d\u1ecbch v\u1ee5 \u0111\u1ec3 \u0111\u00e1p \u1ee9ng nh\u1eefng thay \u0111\u1ed5i v\u1ec1 c\u01a1 s\u1edf h\u1ea1 t\u1ea7ng \u0111\u01b0\u1ee3c coi l\u00e0 \"b\u1ea5t kh\u1ea3 kh\u00e1ng\".",
      "ad_wait_message":
          "Ph\u00e2n t\u00edch ho\u00e0n t\u1ea5t, k\u1ebft qu\u1ea3 s\u1ebd hi\u1ec3n th\u1ecb sau qu\u1ea3ng c\u00e1o.",
      "analysis_failed_title":
          "Ph\u00e2n t\u00edch kh\u00f4ng th\u00e0nh c\u00f4ng",
      "analysis_failed_reason": "L\u00fd do: {reason}",
      "analysis_failed_hint":
          "M\u1eb9o: \u0110\u0103ng xu\u1ea5t v\u00e0 \u0111\u0103ng nh\u1eadp l\u1ea1i c\u00f3 th\u1ec3 h\u1eefu \u00edch.",
      "analysis_fast_no_change":
          "Ki\u1ec3m tra nhanh: S\u1ed1 l\u01b0\u1ee3ng gi\u1ed1ng nhau. Kh\u00f4ng c\u00f3 thay \u0111\u1ed5i n\u00e0o \u0111\u01b0\u1ee3c ph\u00e1t hi\u1ec7n.",
      "usage_metrics_title": "S\u1ed1 li\u1ec7u h\u00e0ng ng\u00e0y",
      "usage_metrics_active":
          "Ng\u01b0\u1eddi d\u00f9ng \u0111ang ho\u1ea1t \u0111\u1ed9ng",
      "usage_metrics_queries": "Truy v\u1ea5n h\u00e0ng ng\u00e0y",
      "usage_metrics_na": "--",
      "usage_metrics_live":
          "b\u1ea3ng \u0111i\u1ec1u khi\u1ec3n tr\u1ef1c ti\u1ebfp",
    },
    'th': {
      "tagline":
          "\u0e42\u0e0b\u0e25\u0e39\u0e0a\u0e31\u0e48\u0e19\u0e42\u0e0b\u0e40\u0e0a\u0e35\u0e22\u0e25\u0e21\u0e35\u0e40\u0e14\u0e35\u0e22\u0e23\u0e30\u0e14\u0e31\u0e1a\u0e21\u0e37\u0e2d\u0e2d\u0e32\u0e0a\u0e35\u0e1e",
      "adsense_banner":
          "\u0e1e\u0e37\u0e49\u0e19\u0e17\u0e35\u0e48\u0e42\u0e06\u0e29\u0e13\u0e32",
      "admin_active_note":
          "\u0e42\u0e2b\u0e21\u0e14\u0e1c\u0e39\u0e49\u0e14\u0e39\u0e41\u0e25\u0e23\u0e30\u0e1a\u0e1a\u0e40\u0e1b\u0e34\u0e14\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e2d\u0e22\u0e39\u0e48",
      "free_app_note":
          "\u0e40\u0e23\u0e32\u0e01\u0e33\u0e25\u0e31\u0e07\u0e1e\u0e31\u0e12\u0e19\u0e32\u0e17\u0e38\u0e01\u0e27\u0e31\u0e19\u0e40\u0e1e\u0e37\u0e48\u0e2d\u0e43\u0e2b\u0e49\u0e04\u0e38\u0e13\u0e44\u0e14\u0e49\u0e23\u0e31\u0e1a\u0e1b\u0e23\u0e30\u0e2a\u0e1a\u0e01\u0e32\u0e23\u0e13\u0e4c\u0e17\u0e35\u0e48\u0e14\u0e35\u0e22\u0e34\u0e48\u0e07\u0e02\u0e36\u0e49\u0e19 \u0e04\u0e27\u0e32\u0e21\u0e04\u0e34\u0e14\u0e40\u0e2b\u0e47\u0e19\u0e02\u0e2d\u0e07\u0e04\u0e38\u0e13\u0e21\u0e35\u0e04\u0e48\u0e32\u0e2a\u0e33\u0e2b\u0e23\u0e31\u0e1a\u0e40\u0e23\u0e32 \u0e40\u0e23\u0e32\u0e22\u0e34\u0e19\u0e14\u0e35\u0e23\u0e31\u0e1a\u0e1f\u0e31\u0e07\u0e08\u0e32\u0e01\u0e04\u0e38\u0e13!",
      "login_prompt":
          "\u0e01\u0e23\u0e38\u0e13\u0e32\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a\u0e40\u0e1e\u0e37\u0e48\u0e2d\u0e40\u0e23\u0e34\u0e48\u0e21\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c",
      "welcome":
          "\u0e22\u0e34\u0e19\u0e14\u0e35\u0e15\u0e49\u0e2d\u0e19\u0e23\u0e31\u0e1a {username}",
      "refresh_data":
          "\u0e23\u0e35\u0e40\u0e1f\u0e23\u0e0a\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25",
      "login_with_instagram":
          "\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a\u0e14\u0e49\u0e27\u0e22\u0e2d\u0e34\u0e19\u0e2a\u0e15\u0e32\u0e41\u0e01\u0e23\u0e21",
      "fetching_data":
          "\u0e01\u0e33\u0e25\u0e31\u0e07\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25...\n\u0e01\u0e32\u0e23\u0e14\u0e33\u0e40\u0e19\u0e34\u0e19\u0e01\u0e32\u0e23\u0e19\u0e35\u0e49\u0e2d\u0e32\u0e08\u0e43\u0e0a\u0e49\u0e40\u0e27\u0e25\u0e32\u0e2a\u0e31\u0e01\u0e04\u0e23\u0e39\u0e48",
      "processing_data":
          "\u0e01\u0e33\u0e25\u0e31\u0e07\u0e1b\u0e23\u0e30\u0e21\u0e27\u0e25\u0e1c\u0e25\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25...\n\u0e40\u0e01\u0e37\u0e2d\u0e1a\u0e40\u0e2a\u0e23\u0e47\u0e08\u0e41\u0e25\u0e49\u0e27",
      "loading_ad":
          "\u0e01\u0e33\u0e25\u0e31\u0e07\u0e42\u0e2b\u0e25\u0e14\u0e42\u0e06\u0e29\u0e13\u0e32...\n\u0e01\u0e23\u0e38\u0e13\u0e32\u0e23\u0e2d\u0e2a\u0e31\u0e01\u0e04\u0e23\u0e39\u0e48.",
      "google_ad_warning":
          "\u0e04\u0e33\u0e40\u0e15\u0e37\u0e2d\u0e19\u0e42\u0e06\u0e29\u0e13\u0e32 Google: {reason}",
      "analysis_secure":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14\u0e44\u0e14\u0e49\u0e23\u0e31\u0e1a\u0e01\u0e32\u0e23\u0e1b\u0e23\u0e30\u0e21\u0e27\u0e25\u0e1c\u0e25\u0e2d\u0e22\u0e48\u0e32\u0e07\u0e1b\u0e25\u0e2d\u0e14\u0e20\u0e31\u0e22\u0e43\u0e19\u0e2d\u0e38\u0e1b\u0e01\u0e23\u0e13\u0e4c\u0e02\u0e2d\u0e07\u0e04\u0e38\u0e13",
      "today_total_analysis":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14\u0e27\u0e31\u0e19\u0e19\u0e35\u0e49: {count}",
      "next_analysis":
          "\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e15\u0e48\u0e2d\u0e44\u0e1b",
      "next_analysis_ready":
          "\u0e1e\u0e23\u0e49\u0e2d\u0e21\u0e2a\u0e41\u0e01\u0e19",
      "analysis_available_now":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e1e\u0e23\u0e49\u0e2d\u0e21\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e41\u0e25\u0e49\u0e27",
      "analysis_ready_risk": "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e1e\u0e23\u0e49\u0e2d\u0e21\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e41\u0e25\u0e49\u0e27 \u0e41\u0e15\u0e48\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e15\u0e34\u0e14\u0e15\u0e48\u0e2d\u0e01\u0e31\u0e19\u0e2d\u0e32\u0e08\u0e40\u0e1e\u0e34\u0e48\u0e21\u0e04\u0e27\u0e32\u0e21\u0e40\u0e2a\u0e35\u0e48\u0e22\u0e07\u0e43\u0e2b\u0e49\u0e1a\u0e31\u0e0d\u0e0a\u0e35\u0e02\u0e2d\u0e07\u0e04\u0e38\u0e13",
      "please_wait":
          "\u0e01\u0e23\u0e38\u0e13\u0e32\u0e23\u0e2d\u0e2a\u0e31\u0e01\u0e04\u0e23\u0e39\u0e48",
      "warning": "\u0e04\u0e33\u0e40\u0e15\u0e37\u0e2d\u0e19",
      "remaining_time":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e16\u0e31\u0e14\u0e44\u0e1b: {time}",
      "watch_ad":
          "\u0e14\u0e39\u0e42\u0e06\u0e29\u0e13\u0e32\u0e41\u0e25\u0e30\u0e40\u0e23\u0e34\u0e48\u0e21\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c",
      "start_analysis":
          "\u0e40\u0e23\u0e34\u0e48\u0e21\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c",
      "start_analysis_question":
          "\u0e40\u0e23\u0e34\u0e48\u0e21\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c?",
      "clear_data_title":
          "\u0e23\u0e35\u0e40\u0e0b\u0e47\u0e15\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e41\u0e2d\u0e1b",
      "clear_data_content":
          "\u0e01\u0e32\u0e23\u0e14\u0e33\u0e40\u0e19\u0e34\u0e19\u0e01\u0e32\u0e23\u0e19\u0e35\u0e49\u0e08\u0e30\u0e25\u0e49\u0e32\u0e07\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e43\u0e19\u0e40\u0e04\u0e23\u0e37\u0e48\u0e2d\u0e07\u0e41\u0e25\u0e30\u0e04\u0e38\u0e01\u0e01\u0e35\u0e49\u0e40\u0e0b\u0e2a\u0e0a\u0e31\u0e19\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14 \u0e04\u0e38\u0e13\u0e41\u0e19\u0e48\u0e43\u0e08\u0e40\u0e2b\u0e23\u0e2d?",
      "cancel": "\u0e22\u0e01\u0e40\u0e25\u0e34\u0e01",
      "delete": "\u0e25\u0e1a",
      "error_title":
          "\u0e40\u0e01\u0e34\u0e14\u0e02\u0e49\u0e2d\u0e1c\u0e34\u0e14\u0e1e\u0e25\u0e32\u0e14",
      "data_fetch_error":
          "\u0e01\u0e32\u0e23\u0e14\u0e36\u0e07\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e25\u0e49\u0e21\u0e40\u0e2b\u0e25\u0e27: {err}\n\n\u0e01\u0e32\u0e23\u0e41\u0e01\u0e49\u0e44\u0e02\u0e1b\u0e31\u0e0d\u0e2b\u0e32: \u0e25\u0e2d\u0e07\u0e2d\u0e2d\u0e01\u0e08\u0e32\u0e01\u0e23\u0e30\u0e1a\u0e1a\u0e41\u0e25\u0e49\u0e27\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a\u0e2d\u0e35\u0e01\u0e04\u0e23\u0e31\u0e49\u0e07",
      "followers": "\u0e1c\u0e39\u0e49\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21",
      "following":
          "\u0e01\u0e33\u0e25\u0e31\u0e07\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21",
      "new_followers":
          "\u0e1c\u0e39\u0e49\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21\u0e43\u0e2b\u0e21\u0e48",
      "non_followers":
          "\u0e44\u0e21\u0e48\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21\u0e01\u0e25\u0e31\u0e1a",
      "left_followers":
          "\u0e40\u0e25\u0e34\u0e01\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21",
      "legal_warning":
          "\u0e02\u0e49\u0e2d\u0e08\u0e33\u0e01\u0e31\u0e14\u0e04\u0e27\u0e32\u0e21\u0e23\u0e31\u0e1a\u0e1c\u0e34\u0e14\u0e0a\u0e2d\u0e1a\u0e17\u0e32\u0e07\u0e01\u0e0e\u0e2b\u0e21\u0e32\u0e22",
      "left_following":
          "\u0e1c\u0e39\u0e49\u0e43\u0e0a\u0e49\u0e17\u0e35\u0e48\u0e40\u0e25\u0e34\u0e01\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21",
      "rate_us":
          "\u0e43\u0e2b\u0e49\u0e04\u0e30\u0e41\u0e19\u0e19\u0e40\u0e23\u0e32",
      "contact_us":
          "\u0e15\u0e34\u0e14\u0e15\u0e48\u0e2d\u0e40\u0e23\u0e32",
      "remove_ads_and_limits":
          "\u0e25\u0e1a\u0e42\u0e06\u0e29\u0e13\u0e32\u0e41\u0e25\u0e30\u0e40\u0e27\u0e25\u0e32\u0e23\u0e2d",
      "rate_test_message":
          "\u0e01\u0e25\u0e48\u0e2d\u0e07\u0e19\u0e35\u0e49\u0e2d\u0e22\u0e39\u0e48\u0e23\u0e30\u0e2b\u0e27\u0e48\u0e32\u0e07\u0e01\u0e32\u0e23\u0e17\u0e14\u0e2a\u0e2d\u0e1a",
      "story_section_title":
          "\u0e14\u0e39\u0e40\u0e23\u0e37\u0e48\u0e2d\u0e07\u0e25\u0e31\u0e1a\u0e2b\u0e23\u0e37\u0e2d\u0e0b\u0e39\u0e21\u0e23\u0e39\u0e1b\u0e42\u0e1b\u0e23\u0e44\u0e1f\u0e25\u0e4c",
      "story_login_required":
          "การดูสตอรีแบบไม่ระบุตัวตนต้องใช้เซสชันเข้าสู่ระบบ Instagram ที่ถูกต้อง หากคุณเข้าสู่ระบบแล้วแต่ยังเห็นข้อความนี้ ให้ลงชื่อออกจาก Instagram แล้วเข้าสู่ระบบอีกครั้ง",
      "story_ad_wait":
          "\u0e08\u0e30\u0e41\u0e2a\u0e14\u0e07\u0e2b\u0e25\u0e31\u0e07\u0e42\u0e06\u0e29\u0e13\u0e32 \u0e01\u0e23\u0e38\u0e13\u0e32\u0e23\u0e2d\u0e2a\u0e31\u0e01\u0e04\u0e23\u0e39\u0e48",
      "story_action_title":
          "\u0e04\u0e38\u0e13\u0e2d\u0e22\u0e32\u0e01\u0e08\u0e30\u0e17\u0e33\u0e2d\u0e30\u0e44\u0e23?",
      "story_view_photo":
          "\u0e02\u0e22\u0e32\u0e22\u0e23\u0e39\u0e1b\u0e42\u0e1b\u0e23\u0e44\u0e1f\u0e25\u0e4c",
      "story_watch_secret":
          "\u0e14\u0e39\u0e40\u0e23\u0e37\u0e48\u0e2d\u0e07\u0e25\u0e31\u0e1a\u0e46",
      "story_no_data":
          "\u0e44\u0e21\u0e48\u0e21\u0e35\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e40\u0e23\u0e37\u0e48\u0e2d\u0e07\u0e23\u0e32\u0e27",
      "story_close": "\u0e1b\u0e34\u0e14",
      "read_and_agree":
          "\u0e09\u0e31\u0e19\u0e44\u0e14\u0e49\u0e2d\u0e48\u0e32\u0e19\u0e41\u0e25\u0e30\u0e40\u0e2b\u0e47\u0e19\u0e14\u0e49\u0e27\u0e22",
      "withdraw_consent":
          "\u0e16\u0e2d\u0e19\u0e04\u0e27\u0e32\u0e21\u0e22\u0e34\u0e19\u0e22\u0e2d\u0e21",
      "withdraw_consent_confirm_title": "\u0e22\u0e37\u0e19\u0e22\u0e31\u0e19",
      "withdraw_consent_confirm_body":
          "\u0e01\u0e32\u0e23\u0e15\u0e31\u0e49\u0e07\u0e04\u0e48\u0e32\u0e04\u0e27\u0e32\u0e21\u0e22\u0e34\u0e19\u0e22\u0e2d\u0e21\u0e02\u0e2d\u0e07\u0e04\u0e38\u0e13\u0e08\u0e30\u0e16\u0e39\u0e01\u0e23\u0e35\u0e40\u0e0b\u0e47\u0e15 \u0e04\u0e38\u0e13\u0e41\u0e19\u0e48\u0e43\u0e08\u0e40\u0e2b\u0e23\u0e2d?",
      "withdraw_consent_confirm_yes": "\u0e43\u0e0a\u0e48",
      "withdraw_consent_confirm_no": "\u0e22\u0e01\u0e40\u0e25\u0e34\u0e01",
      "no_data":
          "\u0e44\u0e21\u0e48\u0e21\u0e35\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25",
      "new_badge": "\u0e43\u0e2b\u0e21\u0e48",
      "login_title":
          "\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a",
      'user_label': '\u0E1C\u0E39\u0E49\u0E43\u0E0A\u0E49',
      "redirecting":
          "\u0e40\u0e0b\u0e2a\u0e0a\u0e31\u0e48\u0e19\u0e44\u0e14\u0e49\u0e23\u0e31\u0e1a\u0e01\u0e32\u0e23\u0e22\u0e37\u0e19\u0e22\u0e31\u0e19 \u0e01\u0e33\u0e25\u0e31\u0e07\u0e40\u0e1b\u0e25\u0e35\u0e48\u0e22\u0e19\u0e40\u0e2a\u0e49\u0e19\u0e17\u0e32\u0e07\u0e2d\u0e22\u0e48\u0e32\u0e07\u0e1b\u0e25\u0e2d\u0e14\u0e20\u0e31\u0e22...",
      "data_updated":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e40\u0e2a\u0e23\u0e47\u0e08\u0e2a\u0e21\u0e1a\u0e39\u0e23\u0e13\u0e4c \u2705",
      "purchases_not_configured":
          "\u0e01\u0e32\u0e23\u0e0b\u0e37\u0e49\u0e2d\u0e44\u0e21\u0e48\u0e2a\u0e32\u0e21\u0e32\u0e23\u0e16\u0e17\u0e33\u0e44\u0e14\u0e49\u0e43\u0e19\u0e02\u0e13\u0e30\u0e19\u0e35\u0e49 \u0e42\u0e1b\u0e23\u0e14\u0e25\u0e2d\u0e07\u0e2d\u0e35\u0e01\u0e04\u0e23\u0e31\u0e49\u0e07\u0e43\u0e19\u0e20\u0e32\u0e22\u0e2b\u0e25\u0e31\u0e07",
      "premium_not_active":
          "\u0e01\u0e32\u0e23\u0e0b\u0e37\u0e49\u0e2d\u0e40\u0e2a\u0e23\u0e47\u0e08\u0e2a\u0e21\u0e1a\u0e39\u0e23\u0e13\u0e4c \u0e41\u0e15\u0e48 Premium \u0e22\u0e31\u0e07\u0e44\u0e21\u0e48\u0e2a\u0e32\u0e21\u0e32\u0e23\u0e16\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e44\u0e14\u0e49 \u0e42\u0e1b\u0e23\u0e14\u0e25\u0e2d\u0e07\u0e2d\u0e35\u0e01\u0e04\u0e23\u0e31\u0e49\u0e07",
      "premium_welcome_box":
          "\u0e22\u0e34\u0e19\u0e14\u0e35\u0e15\u0e49\u0e2d\u0e19\u0e23\u0e31\u0e1a\u0e2a\u0e39\u0e48\u0e1e\u0e23\u0e35\u0e40\u0e21\u0e35\u0e48\u0e22\u0e21! \u0e42\u0e06\u0e29\u0e13\u0e32\u0e41\u0e25\u0e30\u0e40\u0e27\u0e25\u0e32\u0e23\u0e2d\u0e08\u0e30\u0e16\u0e39\u0e01\u0e25\u0e1a\u0e2d\u0e2d\u0e01",
      "premium_already_active":
          "\u0e2a\u0e21\u0e32\u0e0a\u0e34\u0e01\u0e23\u0e30\u0e14\u0e31\u0e1a\u0e1e\u0e23\u0e35\u0e40\u0e21\u0e35\u0e22\u0e21\u0e02\u0e2d\u0e07\u0e04\u0e38\u0e13\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e44\u0e14\u0e49",
      "restore_purchases":
          "\u0e04\u0e37\u0e19\u0e04\u0e48\u0e32\u0e01\u0e32\u0e23\u0e0b\u0e37\u0e49\u0e2d",
      "restore_purchases_short": "\u0e04\u0e37\u0e19\u0e04\u0e48\u0e32",
      "restoring_purchases":
          "\u0e01\u0e33\u0e25\u0e31\u0e07\u0e01\u0e39\u0e49\u0e04\u0e37\u0e19\u0e01\u0e32\u0e23\u0e0b\u0e37\u0e49\u0e2d...",
      "restore_purchases_success":
          "\u0e04\u0e37\u0e19\u0e04\u0e48\u0e32\u0e01\u0e32\u0e23\u0e0b\u0e37\u0e49\u0e2d\u0e41\u0e25\u0e49\u0e27 \u2705",
      "restore_purchases_none":
          "\u0e44\u0e21\u0e48\u0e21\u0e35\u0e01\u0e32\u0e23\u0e0b\u0e37\u0e49\u0e2d\u0e17\u0e35\u0e48\u0e08\u0e30\u0e01\u0e39\u0e49\u0e04\u0e37\u0e19",
      "restore_purchases_failed":
          "\u0e01\u0e32\u0e23\u0e04\u0e37\u0e19\u0e04\u0e48\u0e32\u0e25\u0e49\u0e21\u0e40\u0e2b\u0e25\u0e27: {err}",
      "enter_pin": "\u0e43\u0e2a\u0e48 PIN",
      "pin_accepted":
          "PIN \u0e22\u0e2d\u0e21\u0e23\u0e31\u0e1a\u0e41\u0e25\u0e49\u0e27 \u0e23\u0e35\u0e40\u0e0b\u0e47\u0e15\u0e15\u0e31\u0e27\u0e08\u0e31\u0e1a\u0e40\u0e27\u0e25\u0e32 \u2705",
      "pin_incorrect":
          "PIN \u0e44\u0e21\u0e48\u0e16\u0e39\u0e01\u0e15\u0e49\u0e2d\u0e07",
      "ok": "\u0e15\u0e01\u0e25\u0e07",
      "legal_intro":
          "\u0e42\u0e14\u0e22\u0e01\u0e32\u0e23\u0e14\u0e32\u0e27\u0e19\u0e4c\u0e42\u0e2b\u0e25\u0e14\u0e41\u0e25\u0e30\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e41\u0e2d\u0e1b\u0e1e\u0e25\u0e34\u0e40\u0e04\u0e0a\u0e31\u0e19\u0e19\u0e35\u0e49 \u0e1c\u0e39\u0e49\u0e43\u0e0a\u0e49\u0e17\u0e38\u0e01\u0e04\u0e19\u0e08\u0e30\u0e16\u0e37\u0e2d\u0e27\u0e48\u0e32\u0e44\u0e14\u0e49\u0e2d\u0e48\u0e32\u0e19 \u0e17\u0e33\u0e04\u0e27\u0e32\u0e21\u0e40\u0e02\u0e49\u0e32\u0e43\u0e08 \u0e41\u0e25\u0e30\u0e22\u0e2d\u0e21\u0e23\u0e31\u0e1a\u0e02\u0e49\u0e2d\u0e04\u0e27\u0e32\u0e21 \"\u0e02\u0e49\u0e2d\u0e01\u0e33\u0e2b\u0e19\u0e14\u0e01\u0e32\u0e23\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e41\u0e25\u0e30\u0e02\u0e49\u0e2d\u0e08\u0e33\u0e01\u0e31\u0e14\u0e04\u0e27\u0e32\u0e21\u0e23\u0e31\u0e1a\u0e1c\u0e34\u0e14\u0e0a\u0e2d\u0e1a\" \u0e14\u0e49\u0e32\u0e19\u0e25\u0e48\u0e32\u0e07\u0e19\u0e35\u0e49\u0e25\u0e48\u0e27\u0e07\u0e2b\u0e19\u0e49\u0e32\u0e42\u0e14\u0e22\u0e44\u0e21\u0e48\u0e2a\u0e32\u0e21\u0e32\u0e23\u0e16\u0e40\u0e1e\u0e34\u0e01\u0e16\u0e2d\u0e19\u0e44\u0e14\u0e49:",
      "article1_title":
          "\u0e1a\u0e17\u0e04\u0e27\u0e32\u0e21\u0e17\u0e35\u0e48 1: \u0e04\u0e27\u0e32\u0e21\u0e40\u0e1b\u0e47\u0e19\u0e2a\u0e48\u0e27\u0e19\u0e15\u0e31\u0e27\u0e02\u0e2d\u0e07\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e41\u0e25\u0e30\u0e2a\u0e16\u0e32\u0e1b\u0e31\u0e15\u0e22\u0e01\u0e23\u0e23\u0e21\u0e01\u0e32\u0e23\u0e1b\u0e23\u0e30\u0e21\u0e27\u0e25\u0e1c\u0e25\u0e43\u0e19\u0e17\u0e49\u0e2d\u0e07\u0e16\u0e34\u0e48\u0e19",
      "article2_title":
          "\u0e1a\u0e17\u0e04\u0e27\u0e32\u0e21 2: \u0e04\u0e27\u0e32\u0e21\u0e40\u0e2a\u0e35\u0e48\u0e22\u0e07\u0e02\u0e2d\u0e07\u0e41\u0e1e\u0e25\u0e15\u0e1f\u0e2d\u0e23\u0e4c\u0e21\u0e1a\u0e38\u0e04\u0e04\u0e25\u0e17\u0e35\u0e48\u0e2a\u0e32\u0e21",
      "article3_title":
          "\u0e02\u0e49\u0e2d 3: \u0e01\u0e32\u0e23\u0e1b\u0e0f\u0e34\u0e40\u0e2a\u0e18\u0e01\u0e32\u0e23\u0e23\u0e31\u0e1a\u0e1b\u0e23\u0e30\u0e01\u0e31\u0e19\u0e41\u0e25\u0e30\u0e02\u0e49\u0e2d\u0e08\u0e33\u0e01\u0e31\u0e14\u0e04\u0e27\u0e32\u0e21\u0e23\u0e31\u0e1a\u0e1c\u0e34\u0e14",
      "article4_title":
          "\u0e21\u0e32\u0e15\u0e23\u0e32 4: \u0e1b\u0e23\u0e30\u0e01\u0e32\u0e28\u0e40\u0e01\u0e35\u0e48\u0e22\u0e27\u0e01\u0e31\u0e1a\u0e17\u0e23\u0e31\u0e1e\u0e22\u0e4c\u0e2a\u0e34\u0e19\u0e17\u0e32\u0e07\u0e1b\u0e31\u0e0d\u0e0d\u0e32\u0e41\u0e25\u0e30\u0e04\u0e27\u0e32\u0e21\u0e40\u0e1b\u0e47\u0e19\u0e2d\u0e34\u0e2a\u0e23\u0e30",
      "article5_title":
          "\u0e1a\u0e17\u0e04\u0e27\u0e32\u0e21 5: \u0e04\u0e27\u0e32\u0e21\u0e15\u0e48\u0e2d\u0e40\u0e19\u0e37\u0e48\u0e2d\u0e07\u0e02\u0e2d\u0e07\u0e1a\u0e23\u0e34\u0e01\u0e32\u0e23\u0e41\u0e25\u0e30\u0e01\u0e32\u0e23\u0e40\u0e1b\u0e25\u0e35\u0e48\u0e22\u0e19\u0e41\u0e1b\u0e25\u0e07\u0e41\u0e1e\u0e25\u0e15\u0e1f\u0e2d\u0e23\u0e4c\u0e21",
      "article5_text":
          "\u0e01\u0e32\u0e23\u0e40\u0e1b\u0e25\u0e35\u0e48\u0e22\u0e19\u0e41\u0e1b\u0e25\u0e07\u0e02\u0e31\u0e49\u0e19\u0e1e\u0e37\u0e49\u0e19\u0e10\u0e32\u0e19\u0e43\u0e19 Instagram API \u0e2b\u0e23\u0e37\u0e2d\u0e42\u0e04\u0e23\u0e07\u0e2a\u0e23\u0e49\u0e32\u0e07\u0e1e\u0e37\u0e49\u0e19\u0e10\u0e32\u0e19\u0e02\u0e2d\u0e07\u0e40\u0e27\u0e47\u0e1a\u0e2d\u0e32\u0e08\u0e17\u0e33\u0e43\u0e2b\u0e49\u0e41\u0e2d\u0e1b\u0e1e\u0e25\u0e34\u0e40\u0e04\u0e0a\u0e31\u0e19\u0e2a\u0e39\u0e0d\u0e40\u0e2a\u0e35\u0e22\u0e1f\u0e31\u0e07\u0e01\u0e4c\u0e0a\u0e31\u0e19\u0e01\u0e32\u0e23\u0e17\u0e33\u0e07\u0e32\u0e19\u0e1a\u0e32\u0e07\u0e2a\u0e48\u0e27\u0e19\u0e2b\u0e23\u0e37\u0e2d\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14 \u0e19\u0e31\u0e01\u0e1e\u0e31\u0e12\u0e19\u0e32\u0e44\u0e21\u0e48\u0e21\u0e35\u0e02\u0e49\u0e2d\u0e1c\u0e39\u0e01\u0e21\u0e31\u0e14\u0e17\u0e35\u0e48\u0e08\u0e30\u0e2d\u0e31\u0e1b\u0e40\u0e14\u0e15\u0e41\u0e2d\u0e1b\u0e1e\u0e25\u0e34\u0e40\u0e04\u0e0a\u0e31\u0e19\u0e2b\u0e23\u0e37\u0e2d\u0e1a\u0e33\u0e23\u0e38\u0e07\u0e23\u0e31\u0e01\u0e29\u0e32\u0e1a\u0e23\u0e34\u0e01\u0e32\u0e23\u0e40\u0e1e\u0e37\u0e48\u0e2d\u0e15\u0e2d\u0e1a\u0e2a\u0e19\u0e2d\u0e07\u0e15\u0e48\u0e2d\u0e01\u0e32\u0e23\u0e40\u0e1b\u0e25\u0e35\u0e48\u0e22\u0e19\u0e41\u0e1b\u0e25\u0e07\u0e42\u0e04\u0e23\u0e07\u0e2a\u0e23\u0e49\u0e32\u0e07\u0e1e\u0e37\u0e49\u0e19\u0e10\u0e32\u0e19\u0e14\u0e31\u0e07\u0e01\u0e25\u0e48\u0e32\u0e27 \u0e0b\u0e36\u0e48\u0e07\u0e16\u0e37\u0e2d\u0e40\u0e1b\u0e47\u0e19 \"\u0e40\u0e2b\u0e15\u0e38\u0e2a\u0e38\u0e14\u0e27\u0e34\u0e2a\u0e31\u0e22\"",
      "ad_wait_message":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e40\u0e2a\u0e23\u0e47\u0e08\u0e2a\u0e21\u0e1a\u0e39\u0e23\u0e13\u0e4c \u0e1c\u0e25\u0e25\u0e31\u0e1e\u0e18\u0e4c\u0e08\u0e30\u0e41\u0e2a\u0e14\u0e07\u0e2b\u0e25\u0e31\u0e07\u0e42\u0e06\u0e29\u0e13\u0e32",
      "analysis_failed_title":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e25\u0e49\u0e21\u0e40\u0e2b\u0e25\u0e27",
      "analysis_failed_reason":
          "\u0e40\u0e2b\u0e15\u0e38\u0e1c\u0e25: {reason}",
      "analysis_failed_hint":
          "\u0e40\u0e04\u0e25\u0e47\u0e14\u0e25\u0e31\u0e1a: \u0e01\u0e32\u0e23\u0e2d\u0e2d\u0e01\u0e08\u0e32\u0e01\u0e23\u0e30\u0e1a\u0e1a\u0e41\u0e25\u0e30\u0e01\u0e25\u0e31\u0e1a\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a\u0e43\u0e2b\u0e21\u0e48\u0e2d\u0e32\u0e08\u0e0a\u0e48\u0e27\u0e22\u0e44\u0e14\u0e49",
      "analysis_fast_no_change":
          "\u0e15\u0e23\u0e27\u0e08\u0e2a\u0e2d\u0e1a\u0e14\u0e48\u0e27\u0e19: \u0e08\u0e33\u0e19\u0e27\u0e19\u0e40\u0e17\u0e48\u0e32\u0e01\u0e31\u0e19 \u0e44\u0e21\u0e48\u0e1e\u0e1a\u0e01\u0e32\u0e23\u0e40\u0e1b\u0e25\u0e35\u0e48\u0e22\u0e19\u0e41\u0e1b\u0e25\u0e07",
      "usage_metrics_title":
          "\u0e15\u0e31\u0e27\u0e0a\u0e35\u0e49\u0e27\u0e31\u0e14\u0e23\u0e32\u0e22\u0e27\u0e31\u0e19",
      "usage_metrics_active":
          "\u0e1c\u0e39\u0e49\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e17\u0e35\u0e48\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e2d\u0e22\u0e39\u0e48",
      "usage_metrics_queries":
          "\u0e2a\u0e2d\u0e1a\u0e16\u0e32\u0e21\u0e17\u0e38\u0e01\u0e27\u0e31\u0e19",
      "usage_metrics_na": "--",
      "usage_metrics_live":
          "\u0e41\u0e1c\u0e07\u0e16\u0e48\u0e32\u0e22\u0e17\u0e2d\u0e14\u0e2a\u0e14",
    },
    'pl': {
      "tagline":
          "Profesjonalne rozwi\u0105zania w zakresie medi\u00f3w spo\u0142eczno\u015bciowych",
      "adsense_banner": "PRZESTRZE\u0143 NA REKLAM\u0118",
      "admin_active_note": "Tryb administratora aktywny",
      "free_app_note":
          "Ewoluujemy ka\u017cdego dnia, aby zapewni\u0107 Ci lepsze do\u015bwiadczenia. Twoja opinia jest dla nas cenna \u2014 ch\u0119tnie j\u0105 poznamy!",
      "login_prompt": "Zaloguj si\u0119, aby rozpocz\u0105\u0107 analiz\u0119.",
      "welcome": "Witamy, {username}",
      "refresh_data": "OD\u015aWIE\u017b DANE",
      "login_with_instagram": "ZALOGUJ SI\u0118 NA INSTAGRAMIE",
      "fetching_data":
          "Analiza danych...\nTo mo\u017ce chwil\u0119 potrwa\u0107.",
      "processing_data": "Przetwarzanie danych...\nPrawie gotowe.",
      "loading_ad": "\u0141adowanie reklamy...\nProsz\u0119 czeka\u0107.",
      "google_ad_warning":
          "Ostrze\u017cenie dotycz\u0105ce reklamy Google: {reason}",
      "analysis_secure":
          "Wszystkie analizy s\u0105 bezpiecznie przetwarzane lokalnie na Twoim urz\u0105dzeniu.",
      "today_total_analysis": "\u0141\u0105czne dzisiejsze analizy: {count}",
      "next_analysis": "Nast\u0119pna analiza",
      "next_analysis_ready": "Gotowy do skanowania.",
      "analysis_available_now": "Analiza jest ju\u017c dost\u0119pna",
      "analysis_ready_risk":
          "Analiza jest ju\u017c dost\u0119pna, ale powtarzanie analiz mo\u017ce narazi\u0107 Twoje konto na ryzyko.",
      "please_wait": "Prosz\u0119 czeka\u0107",
      "warning": "Ostrze\u017cenie",
      "remaining_time": "Nast\u0119pna analiza: {time}",
      "watch_ad": "OBEJRZYJ REKLAM\u0118 I ROZPOCZNIJ ANALIZ\u0118",
      "start_analysis": "ROZPOCZNIJ ANALIZ\u0118",
      "start_analysis_question": "Rozpocz\u0105\u0107 analiz\u0119?",
      "clear_data_title": "Zresetuj dane aplikacji",
      "clear_data_content":
          "Spowoduje to usuni\u0119cie wszystkich danych lokalnych i plik\u00f3w cookie sesji. Czy jeste\u015b pewien?",
      "cancel": "ANULUJ",
      "delete": "USU\u0143",
      "error_title": "B\u0142\u0105d",
      "data_fetch_error":
          "Pobieranie danych nie powiod\u0142o si\u0119: {err}\n\nRozwi\u0105zywanie problem\u00f3w: spr\u00f3buj si\u0119 wylogowa\u0107 i zalogowa\u0107 ponownie.",
      "followers": "Obserwatorzy",
      "following": "Obserwuj\u0119",
      "new_followers": "Nowi obserwuj\u0105cy",
      "non_followers": "Nie obserwuj\u0105 Ci\u0119",
      "left_followers": "Przesta\u0144 obserwowa\u0107",
      "legal_warning": "Zastrze\u017cenie prawne",
      "left_following": "Nieobserwowani u\u017cytkownicy",
      "rate_us": "Oce\u0144 nas",
      "contact_us": "Skontaktuj si\u0119 z nami",
      "remove_ads_and_limits":
          "Usu\u0144 reklamy i czasy oczekiwania",
      "rate_test_message":
          "To urz\u0105dzenie jest obecnie w fazie test\u00f3w.",
      "story_section_title":
          "Ogl\u0105daj historie w tajemnicy lub powi\u0119kszaj zdj\u0119cia profilowe",
      "story_login_required":
          "Aby oglądać relacje anonimowo, wymagane jest poprawne logowanie do Instagrama. Jeśli jesteś już zalogowany, a komunikat nadal się pojawia, wyloguj się z Instagrama i zaloguj ponownie.",
      "story_ad_wait":
          "Zostanie wy\u015bwietlone po reklamie, prosz\u0119 czeka\u0107.",
      "story_action_title": "Co chcia\u0142by\u015b robi\u0107?",
      "story_view_photo": "Powi\u0119ksz zdj\u0119cie profilowe",
      "story_watch_secret": "Obejrzyj histori\u0119 w tajemnicy",
      "story_no_data": "Brak dost\u0119pnych danych historii.",
      "story_close": "ZAMKNIJ",
      "read_and_agree": "Przeczyta\u0142em i zgadzam si\u0119",
      "withdraw_consent": "Wycofaj zgod\u0119",
      "withdraw_consent_confirm_title": "Potwierd\u017a",
      "withdraw_consent_confirm_body":
          "Twoje ustawienia zgody zostan\u0105 zresetowane. Czy jeste\u015b pewien?",
      "withdraw_consent_confirm_yes": "Tak",
      "withdraw_consent_confirm_no": "Anuluj",
      "no_data": "Brak danych",
      "new_badge": "NOWO\u015a\u0106",
      "login_title": "Zaloguj si\u0119",
      'user_label': 'U\u017Cytkownik',
      "redirecting": "Sesja zweryfikowana, przekierowanie bezpieczne...",
      "data_updated": "Analiza zako\u0144czona \u2705",
      "purchases_not_configured":
          "Zakupy nie s\u0105 obecnie dost\u0119pne. Spr\u00f3buj ponownie p\u00f3\u017aniej.",
      "premium_not_active":
          "Zakup zako\u0144czony, ale Premium nie jest jeszcze aktywny. Spr\u00f3buj ponownie.",
      "premium_welcome_box":
          "Witamy w Premium! Reklamy i czasy oczekiwania zosta\u0142y usuni\u0119te.",
      "premium_already_active": "Twoje cz\u0142onkostwo Premium jest aktywne.",
      "restore_purchases": "Przywr\u00f3\u0107 zakupy",
      "restore_purchases_short": "PRZYWR\u00d3\u0106",
      "restoring_purchases": "Przywracanie zakup\u00f3w...",
      "restore_purchases_success": "Zakupy przywr\u00f3cone \u2705",
      "restore_purchases_none": "Brak zakup\u00f3w do przywr\u00f3cenia.",
      "restore_purchases_failed":
          "Przywracanie nie powiod\u0142o si\u0119: {err}",
      "enter_pin": "Wprowad\u017a PIN",
      "pin_accepted": "PIN zaakceptowany, reset timera \u2705",
      "pin_incorrect": "Nieprawid\u0142owy PIN",
      "ok": "OK",
      "legal_intro":
          "Pobieraj\u0105c i korzystaj\u0105c z tej aplikacji, uznaje si\u0119, \u017ce ka\u017cdy U\u017cytkownik z wyprzedzeniem przeczyta\u0142, zrozumia\u0142 i nieodwo\u0142alnie zaakceptowa\u0142 poni\u017cszy tekst \u201eWarunk\u00f3w u\u017cytkowania i zastrze\u017cenia\u201d:",
      "article1_title":
          "Artyku\u0142 1: Prywatno\u015b\u0107 danych i architektura lokalnego przetwarzania",
      "article2_title":
          "Artyku\u0142 2: Ryzyko zwi\u0105zane z platformami stron trzecich",
      "article3_title":
          "Artyku\u0142 3: Wy\u0142\u0105czenie gwarancji i ograniczenie odpowiedzialno\u015bci",
      "article4_title":
          "Artyku\u0142 4: Informacja o w\u0142asno\u015bci intelektualnej i niezale\u017cno\u015bci",
      "article5_title":
          "Artyku\u0142 5: Ci\u0105g\u0142o\u015b\u0107 us\u0142ug i zmiany na platformie",
      "article5_text":
          "Zasadnicze zmiany w API Instagrama lub infrastrukturze sieciowej mog\u0105 spowodowa\u0107, \u017ce aplikacja utraci cz\u0119\u015bciowo lub ca\u0142kowicie swoj\u0105 funkcjonalno\u015b\u0107. Deweloper nie zobowi\u0105zuje si\u0119 do aktualizacji aplikacji lub utrzymywania us\u0142ugi w odpowiedzi na takie zmiany infrastrukturalne, kt\u00f3re s\u0105 uznawane za \u201esi\u0142\u0119 wy\u017csz\u0105\u201d.",
      "ad_wait_message":
          "Analiza zako\u0144czona, wyniki zostan\u0105 pokazane po og\u0142oszeniu.",
      "analysis_failed_title": "Analiza nie powiod\u0142a si\u0119",
      "analysis_failed_reason": "Pow\u00f3d: {reason}",
      "analysis_failed_hint":
          "Wskaz\u00f3wka: wylogowanie i ponowne zalogowanie mo\u017ce pom\u00f3c.",
      "analysis_fast_no_change":
          "Szybkie sprawdzenie: Liczby s\u0105 takie same. Nie wykryto \u017cadnych zmian.",
      "usage_metrics_title": "Dzienne wska\u017aniki",
      "usage_metrics_active": "Aktywni u\u017cytkownicy",
      "usage_metrics_queries": "Codzienne zapytania",
      "usage_metrics_na": "--",
      "usage_metrics_live": "panel na \u017cywo",
    },
  };

  final Map<String, Map<String, String>> _flowLocalized = {
    "tr": {
      "followers_incomplete":
          "Veri yükleme kesildi: takipçi verisi eksik ({fetched}/{total}).",
      "following_incomplete":
          "Veri yükleme kesildi: takip edilen verisi eksik ({fetched}/{total}).",
      "empty_data": "Veri yükleme kesildi: Instagram boş veri döndürdü.",
      "unexpected_error": "Veri yükleme kesildi: beklenmeyen bir hata oluştu.",
      "automation_warning":
          "Instagram otomatik davranış uyarısı verdi. Güvenlik için veri çekme durduruldu.",
      "security_required":
          "Instagram güvenlik doğrulaması istedi. Instagram uygulamasından doğrulayıp tekrar deneyin.",
      "session_invalid":
          "Oturum geçersiz veya doğrulama bekliyor. Lütfen tekrar giriş yapın.",
      "rate_limited":
          "Çok hızlı istek gönderildi. Veri yükleme güvenlik nedeniyle kesildi.",
      "connection_error":
          "Bağlantı sorunu nedeniyle veri yükleme tamamlanamadı.",
      "server_error":
          "Instagram sunucusu hata döndürdü (HTTP {code}). Veri yükleme kesildi.",
      "story_security_required":
          "Instagram güvenlik doğrulaması gerekiyor (hikaye verisi alınamadı).",
      "story_detail":
          "Hikaye verisi alınamadı. Genelde Instagram doğrulaması, geçici API kısıtı veya bağlantı kesintisinden kaynaklanır. 2-3 dakika sonra tekrar deneyin.",
      "story_generic":
          "Hikaye verisi alınamadı. Lütfen biraz sonra tekrar deneyin.",
      "secret_mode_label": "GİZLİ MOD",
    },
    "en": {
      "followers_incomplete":
          "Data loading was interrupted: follower data incomplete ({fetched}/{total}).",
      "following_incomplete":
          "Data loading was interrupted: following data incomplete ({fetched}/{total}).",
      "empty_data":
          "Data loading was interrupted: Instagram returned empty data.",
      "unexpected_error":
          "Data loading stopped due to an unexpected error.",
      "automation_warning":
          "Instagram returned an automated-behavior warning. We stopped fetching data for safety.",
      "security_required":
          "Instagram requested security verification. Verify in Instagram app and try again.",
      "session_invalid":
          "Session is invalid or waiting for verification. Please log in again.",
      "rate_limited":
          "Too many requests were sent. Data loading was interrupted for safety.",
      "connection_error":
          "Data loading could not complete due to a connection issue.",
      "server_error":
          "Instagram returned an error (HTTP {code}). Data loading was interrupted.",
      "story_security_required":
          "Instagram security verification is required (story data could not be fetched).",
      "story_detail":
          "Story data could not be fetched. Usually this is caused by Instagram verification, temporary API restrictions, or a connection interruption. Please try again in 2-3 minutes.",
      "story_generic":
          "Could not fetch story data. Please try again shortly.",
      "secret_mode_label": "Secret Mode",
    },
    "de": {
      "followers_incomplete":
          "Datenabruf unterbrochen: Follower-Daten unvollstandig ({fetched}/{total}).",
      "following_incomplete":
          "Datenabruf unterbrochen: Following-Daten unvollstandig ({fetched}/{total}).",
      "empty_data":
          "Datenabruf unterbrochen: Instagram lieferte leere Daten.",
      "unexpected_error": "Datenabruf unterbrochen: Unerwarteter Fehler.",
      "automation_warning":
          "Instagram erkannte automatisches Verhalten. Abruf wurde zum Schutz gestoppt.",
      "security_required":
          "Instagram verlangt Sicherheitsprufung. Bitte im Instagram-App bestatigen und erneut versuchen.",
      "session_invalid":
          "Sitzung ungultig oder wartet auf Verifizierung. Bitte erneut anmelden.",
      "rate_limited":
          "Zu viele Anfragen. Abruf wurde aus Sicherheitsgrunden unterbrochen.",
      "connection_error":
          "Daten konnten wegen eines Verbindungsproblems nicht geladen werden.",
      "server_error":
          "Instagram-Serverfehler (HTTP {code}). Abruf unterbrochen.",
      "story_security_required":
          "Instagram-Sicherheitsprufung erforderlich (Story-Daten konnten nicht geladen werden).",
      "story_detail":
          "Story-Daten konnten nicht geladen werden. Ursache ist oft Verifizierung, temporare API-Limits oder Verbindungsausfall. Bitte in 2-3 Minuten erneut versuchen.",
      "story_generic":
          "Story-Daten konnten nicht geladen werden. Bitte kurz erneut versuchen.",
      "secret_mode_label": "GEHEIMMODUS",
    },
    "ko": {
      "followers_incomplete":
          "Data rodeu jungdan: follower deiteoga bujokham ({fetched}/{total}).",
      "following_incomplete":
          "Data rodeu jungdan: following deiteoga bujokham ({fetched}/{total}).",
      "empty_data": "Data rodeu jungdan: Instagram-i bin deiteoreul banhwam.",
      "unexpected_error": "Data rodeu jungdan: yegisang mothan oryu.",
      "automation_warning":
          "Instagram-i jadong haengdong gyeonggoreul boim. anjeon sang rodeu jungji.",
      "security_required":
          "Instagram boan hwagin pilyo. app-eseo hwagin hu dasi si-do.",
      "session_invalid":
          "Sesyeon mueffyo ttoneun geomjeung daegi jung. dasi login haejuseyo.",
      "rate_limited": "Yocheongi neomu manhaseo anjeon sang jungji.",
      "connection_error": "Yeongyeol munjero data rodeu wanryo bulga.",
      "server_error": "Instagram oryu (HTTP {code}). data rodeu jungdan.",
      "story_security_required":
          "Instagram boan hwagin pilyo (story data rodu bulga).",
      "story_detail":
          "Story data rodu bulga. boan hwagin, ilsi API jehan ttoneun network munje il su isseum. 2-3bun hu dasi si-do.",
      "story_generic": "Story data rodu bulga. jamshi hu dasi si-do.",
      "secret_mode_label": "BIMIL MODE",
    },
    "ja": {
      "followers_incomplete":
          "Data yomi-komi chudan: follower data fukanzen ({fetched}/{total}).",
      "following_incomplete":
          "Data yomi-komi chudan: following data fukanzen ({fetched}/{total}).",
      "empty_data":
          "Data yomi-komi chudan: Instagram ga ku no data o henkan.",
      "unexpected_error": "Data yomi-komi chudan: yosoki shinai eraa.",
      "automation_warning":
          "Instagram ga jidoka koudo o kentchi. anzen no tame shutoku teishi.",
      "security_required":
          "Instagram no anzen kakunin ga hitsuyou. app de kakunin shite saishikou.",
      "session_invalid":
          "Session ga mukou ka kakunin machi. mou ichido login shite kudasai.",
      "rate_limited":
          "Request ga oosugimasu. anzen no tame yomi-komi o chudan shimashita.",
      "connection_error": "Setsuzoku mondai de data yomi-komi ga kanryou dekinai.",
      "server_error":
          "Instagram eraa (HTTP {code}). data yomi-komi chudan.",
      "story_security_required":
          "Instagram anzen kakunin hitsuyou (story data shutoku dekinai).",
      "story_detail":
          "Story data o shutoku dekinai. verification, ichiji API seigen, setsuzoku mondai no kanousei. 2-3 fun ato ni saishikou.",
      "story_generic": "Story data o shutoku dekinai. sukkoshi ato de saishikou.",
      "secret_mode_label": "SECRET MODE",
    },
    "ru": {
      "followers_incomplete":
          "Zagruzka prervana: dannye podpischikov nepolnye ({fetched}/{total}).",
      "following_incomplete":
          "Zagruzka prervana: dannye podpisok nepolnye ({fetched}/{total}).",
      "empty_data": "Zagruzka prervana: Instagram vernul pustye dannye.",
      "unexpected_error": "Zagruzka prervana: neozhidannaya oshibka.",
      "automation_warning":
          "Instagram obnaruzhil avtomaticheskoe povedenie. Zagruzka ostanovlena radi bezopasnosti.",
      "security_required":
          "Instagram trebuet proverku bezopasnosti. Proydite proverku v prilozhenii i povtorite.",
      "session_invalid":
          "Sessiya nevalidna ili ozhidaet proverki. Voydite snova.",
      "rate_limited":
          "Slishkom mnogo zaprosov. Zagruzka ostanovlena radi bezopasnosti.",
      "connection_error": "Ne udalos zavershit zagruzku iz-za problemi seti.",
      "server_error": "Oshibka Instagram (HTTP {code}). Zagruzka prervana.",
      "story_security_required":
          "Trebuetsya proverka Instagram (dannye story nedostupny).",
      "story_detail":
          "Ne udalos poluchit story. Chasto iz-za proverki Instagram, vremennogo limita API ili setevoy oshibki. Povtorite cherez 2-3 minuty.",
      "story_generic":
          "Ne udalos poluchit dannye story. Poprobuite eshche raz pozhe.",
      "secret_mode_label": "SECRET MODE",
    },
    "ar": {
      "followers_incomplete":
          "Tahmil mutawaqqif: bayanat almutabiin ghayr maktamilah ({fetched}/{total}).",
      "following_incomplete":
          "Tahmil mutawaqqif: bayanat almutabaein ghayr maktamilah ({fetched}/{total}).",
      "empty_data": "Tahmil mutawaqqif: Instagram arja data farigha.",
      "unexpected_error": "Tahmil mutawaqqif: khata ghayr mutawaqqa.",
      "automation_warning":
          "Instagram iktashafa suluk otomatiqi. tm iiqaf aljلب lil-aman.",
      "security_required":
          "Instagram yutalib bitahqiq amni. akmil altahqiq fi altaṭbiq wa hawil marra ukhra.",
      "session_invalid":
          "Aljalsa ghayr saliha aw tantazir tahqiq. urjuw tasjil aldukhul marra ukhra.",
      "rate_limited":
          "Tamm irsal talabāt kathira jiddan. tm iiqaf altahmil lil-aman.",
      "connection_error": "Lam yaktamil altahmil bisabab mushkilat ittisal.",
      "server_error": "Khata Instagram (HTTP {code}). altahmil mutawaqqif.",
      "story_security_required":
          "Yujad tahqiq amni matlub min Instagram (data story ghayr mutaha).",
      "story_detail":
          "Lam yumkin jلب story. ghaliban bisabab tahqiq Instagram aw hadd API mu'aqqat aw mushkila shabaka. hawil baed 2-3 daqayeq.",
      "story_generic":
          "Lam yumkin jلب data story. hawil marra ukhra baed qalil.",
      "secret_mode_label": "SECRET MODE",
    },
    "hi": {
      "followers_incomplete":
          "Data load ruk gaya: follower data adhura ({fetched}/{total}).",
      "following_incomplete":
          "Data load ruk gaya: following data adhura ({fetched}/{total}).",
      "empty_data": "Data load ruk gaya: Instagram ne khali data diya.",
      "unexpected_error": "Data load ruk gaya: anapekshit truti.",
      "automation_warning":
          "Instagram ne automatic vyavahar pakda. suraksha ke liye load rok diya gaya.",
      "security_required":
          "Instagram security verification mang raha hai. app me verify karke phir koshish karein.",
      "session_invalid":
          "Session invalid hai ya verification ka intezar hai. dubara login karein.",
      "rate_limited":
          "Bahut zyada requests bheji gayi. suraksha ke liye load rok diya gaya.",
      "connection_error": "Connection problem ki wajah se data load pura nahi hua.",
      "server_error": "Instagram error (HTTP {code}). data load ruk gaya.",
      "story_security_required":
          "Instagram security verification zaruri hai (story data nahi mil saka).",
      "story_detail":
          "Story data nahi mila. aksar verification, temporary API limit ya network issue ki wajah se hota hai. 2-3 minute baad fir koshish karein.",
      "story_generic":
          "Story data nahi mila. thodi der baad phir koshish karein.",
      "secret_mode_label": "SECRET MODE",
    },
    "es": {
      "followers_incomplete":
          "Carga interrumpida: datos de seguidores incompletos ({fetched}/{total}).",
      "following_incomplete":
          "Carga interrumpida: datos de seguidos incompletos ({fetched}/{total}).",
      "empty_data":
          "Carga interrumpida: Instagram devolvio datos vacios.",
      "unexpected_error": "Carga interrumpida: error inesperado.",
      "automation_warning":
          "Instagram detecto comportamiento automatizado. Se detuvo la carga por seguridad.",
      "security_required":
          "Instagram solicita verificacion de seguridad. Verifica en la app y vuelve a intentar.",
      "session_invalid":
          "La sesion es invalida o espera verificacion. Inicia sesion nuevamente.",
      "rate_limited":
          "Demasiadas solicitudes. La carga se detuvo por seguridad.",
      "connection_error":
          "No se pudo completar la carga por un problema de conexion.",
      "server_error":
          "Error de Instagram (HTTP {code}). Carga interrumpida.",
      "story_security_required":
          "Se requiere verificacion de seguridad de Instagram (no se pudieron obtener historias).",
      "story_detail":
          "No se pudieron obtener datos de historias. Suele deberse a verificacion de Instagram, limite temporal de API o problema de conexion. Intenta de nuevo en 2-3 minutos.",
      "story_generic":
          "No se pudieron obtener datos de historias. Intenta de nuevo en breve.",
      "secret_mode_label": "MODO SECRETO",
    },
    "es-mx": {
      "followers_incomplete":
          "Carga interrumpida: datos de seguidores incompletos ({fetched}/{total}).",
      "following_incomplete":
          "Carga interrumpida: datos de seguidos incompletos ({fetched}/{total}).",
      "empty_data":
          "Carga interrumpida: Instagram devolvio datos vacios.",
      "unexpected_error": "Carga interrumpida: error inesperado.",
      "automation_warning":
          "Instagram detecto comportamiento automatizado. Se detuvo la carga por seguridad.",
      "security_required":
          "Instagram solicita verificacion de seguridad. Verifica en la app y vuelve a intentar.",
      "session_invalid":
          "La sesion es invalida o espera verificacion. Inicia sesion otra vez.",
      "rate_limited":
          "Demasiadas solicitudes. La carga se detuvo por seguridad.",
      "connection_error":
          "No se pudo completar la carga por un problema de conexion.",
      "server_error":
          "Error de Instagram (HTTP {code}). Carga interrumpida.",
      "story_security_required":
          "Se requiere verificacion de seguridad de Instagram (no se pudieron obtener historias).",
      "story_detail":
          "No se pudieron obtener datos de historias. Suele deberse a verificacion de Instagram, limite temporal de API o problema de conexion. Intenta de nuevo en 2-3 minutos.",
      "story_generic":
          "No se pudieron obtener datos de historias. Intenta de nuevo en breve.",
      "secret_mode_label": "MODO SECRETO",
    },
    "fr": {
      "followers_incomplete":
          "Chargement interrompu : donnees abonnes incompletes ({fetched}/{total}).",
      "following_incomplete":
          "Chargement interrompu : donnees abonnements incompletes ({fetched}/{total}).",
      "empty_data":
          "Chargement interrompu : Instagram a renvoye des donnees vides.",
      "unexpected_error": "Chargement interrompu : erreur inattendue.",
      "automation_warning":
          "Instagram a detecte un comportement automatise. Chargement arrete pour la securite.",
      "security_required":
          "Instagram demande une verification de securite. Verifiez dans l'application puis reessayez.",
      "session_invalid":
          "Session invalide ou en attente de verification. Reconnectez-vous.",
      "rate_limited":
          "Trop de requetes. Chargement interrompu pour la securite.",
      "connection_error":
          "Impossible de terminer le chargement a cause d'un probleme reseau.",
      "server_error":
          "Erreur Instagram (HTTP {code}). Chargement interrompu.",
      "story_security_required":
          "Verification de securite Instagram requise (impossible de recuperer les stories).",
      "story_detail":
          "Impossible de recuperer les donnees story. Souvent a cause d'une verification Instagram, d'une limite API temporaire ou d'un probleme reseau. Reessayez dans 2-3 minutes.",
      "story_generic":
          "Impossible de recuperer les donnees story. Reessayez bientot.",
      "secret_mode_label": "MODE SECRET",
    },
    "it": {
      "followers_incomplete":
          "Caricamento interrotto: dati follower incompleti ({fetched}/{total}).",
      "following_incomplete":
          "Caricamento interrotto: dati following incompleti ({fetched}/{total}).",
      "empty_data":
          "Caricamento interrotto: Instagram ha restituito dati vuoti.",
      "unexpected_error": "Caricamento interrotto: errore imprevisto.",
      "automation_warning":
          "Instagram ha rilevato comportamento automatico. Caricamento fermato per sicurezza.",
      "security_required":
          "Instagram richiede verifica di sicurezza. Verifica nell'app e riprova.",
      "session_invalid":
          "Sessione non valida o in attesa di verifica. Accedi di nuovo.",
      "rate_limited":
          "Troppe richieste inviate. Caricamento interrotto per sicurezza.",
      "connection_error":
          "Impossibile completare il caricamento per un problema di connessione.",
      "server_error":
          "Errore Instagram (HTTP {code}). Caricamento interrotto.",
      "story_security_required":
          "Verifica di sicurezza Instagram necessaria (impossibile ottenere i dati story).",
      "story_detail":
          "Impossibile ottenere i dati story. Di solito per verifica Instagram, limite API temporaneo o problema di rete. Riprova tra 2-3 minuti.",
      "story_generic":
          "Impossibile ottenere i dati story. Riprova tra poco.",
      "secret_mode_label": "MODALITA SEGRETA",
    },
    "pt": {
      "followers_incomplete":
          "Carregamento interrompido: dados de seguidores incompletos ({fetched}/{total}).",
      "following_incomplete":
          "Carregamento interrompido: dados de seguindo incompletos ({fetched}/{total}).",
      "empty_data":
          "Carregamento interrompido: o Instagram retornou dados vazios.",
      "unexpected_error": "Carregamento interrompido: erro inesperado.",
      "automation_warning":
          "O Instagram detectou comportamento automatizado. Interrompemos a coleta por seguranca.",
      "security_required":
          "O Instagram solicitou verificacao de seguranca. Verifique no app e tente novamente.",
      "session_invalid":
          "Sessao invalida ou aguardando verificacao. Faca login novamente.",
      "rate_limited":
          "Muitas solicitacoes. O carregamento foi interrompido por seguranca.",
      "connection_error":
          "Nao foi possivel concluir o carregamento por problema de conexao.",
      "server_error":
          "Erro do Instagram (HTTP {code}). Carregamento interrompido.",
      "story_security_required":
          "Verificacao de seguranca do Instagram necessaria (nao foi possivel obter stories).",
      "story_detail":
          "Nao foi possivel carregar stories. Geralmente por verificacao do Instagram, limite temporario de API ou problema de conexao. Tente novamente em 2-3 minutos.",
      "story_generic":
          "Nao foi possivel obter os dados de stories. Tente novamente em instantes.",
      "secret_mode_label": "MODO SECRETO",
    },
    "nl": {
      "followers_incomplete":
          "Laden onderbroken: volgersgegevens onvolledig ({fetched}/{total}).",
      "following_incomplete":
          "Laden onderbroken: volgend-gegevens onvolledig ({fetched}/{total}).",
      "empty_data":
          "Laden onderbroken: Instagram gaf lege gegevens terug.",
      "unexpected_error": "Laden onderbroken: onverwachte fout.",
      "automation_warning":
          "Instagram detecteerde geautomatiseerd gedrag. Laden is om veiligheidsredenen gestopt.",
      "security_required":
          "Instagram vereist beveiligingscontrole. Verifieer in de app en probeer opnieuw.",
      "session_invalid":
          "Sessie ongeldig of wacht op verificatie. Log opnieuw in.",
      "rate_limited":
          "Te veel verzoeken. Laden is uit veiligheid onderbroken.",
      "connection_error":
          "Laden kon niet worden voltooid door een verbindingsprobleem.",
      "server_error":
          "Instagram-fout (HTTP {code}). Laden onderbroken.",
      "story_security_required":
          "Instagram-beveiligingsverificatie vereist (storygegevens konden niet worden opgehaald).",
      "story_detail":
          "Storygegevens konden niet worden opgehaald. Meestal door Instagram-verificatie, tijdelijke API-limiet of netwerkprobleem. Probeer opnieuw over 2-3 minuten.",
      "story_generic":
          "Storygegevens konden niet worden opgehaald. Probeer zo opnieuw.",
      "secret_mode_label": "GEHEIME MODUS",
    },
    "pl": {
      "followers_incomplete":
          "Ladowanie przerwane: dane obserwujacych sa niepelne ({fetched}/{total}).",
      "following_incomplete":
          "Ladowanie przerwane: dane obserwowanych sa niepelne ({fetched}/{total}).",
      "empty_data":
          "Ladowanie przerwane: Instagram zwrocil puste dane.",
      "unexpected_error": "Ladowanie przerwane: nieoczekiwany blad.",
      "automation_warning":
          "Instagram wykryl automatyczne zachowanie. Dla bezpieczenstwa zatrzymano pobieranie.",
      "security_required":
          "Instagram wymaga weryfikacji bezpieczenstwa. Zweryfikuj w aplikacji i sprobuj ponownie.",
      "session_invalid":
          "Sesja jest niewazna lub oczekuje weryfikacji. Zaloguj sie ponownie.",
      "rate_limited":
          "Wyslano zbyt wiele zadan. Ladowanie zostalo przerwane dla bezpieczenstwa.",
      "connection_error":
          "Nie mozna zakonczyc ladowania z powodu problemu z polaczeniem.",
      "server_error":
          "Blad Instagram (HTTP {code}). Ladowanie przerwane.",
      "story_security_required":
          "Wymagana weryfikacja bezpieczenstwa Instagram (nie mozna pobrac danych story).",
      "story_detail":
          "Nie mozna pobrac danych story. Zwykle z powodu weryfikacji Instagram, tymczasowego limitu API lub problemu z siecia. Sprobuj ponownie za 2-3 minuty.",
      "story_generic":
          "Nie mozna pobrac danych story. Sprobuj ponownie za chwile.",
      "secret_mode_label": "TRYB TAJNY",
    },
  };

  static const Map<String, Map<String, String>> _humanizedUiOverrides = {
    'tr': {
      'story_section_title':
          'Hikayeleri gizlice izle veya profil fotoğrafını büyüt',
      'story_login_required':
          'Hikayeleri gizlice izleyebilmemiz için geçerli bir Instagram oturumu gerekiyor. Giriş yaptıktan sonra da bu uyarıyı görüyorsanız Instagram hesabınızdan çıkış yapıp tekrar giriş yapın.',
      'story_ad_wait': 'Reklamdan sonra gösterilecek. Lütfen bekleyin.',
      'story_action_title': 'Ne yapmak istersiniz?',
      'story_view_photo': 'Profil fotoğrafını büyüt',
      'story_watch_secret': 'Hikayeyi gizlice izle',
      'story_no_data': 'Hikaye verisi yok.',
      'story_close': 'KAPAT',
    },
    'en': {
      'story_section_title':
          'Watch stories secretly or zoom profile photos',
      'story_login_required':
          'A valid Instagram login is required to view stories privately. If you are already logged in and still see this warning, log out of Instagram and log in again.',
      'story_ad_wait': 'Will be shown after the ad. Please wait.',
      'story_action_title': 'What would you like to do?',
      'story_view_photo': 'Enlarge profile photo',
      'story_watch_secret': 'Watch story secretly',
      'story_no_data': 'No story data available.',
      'story_close': 'CLOSE',
    },
    'de': {
      'story_section_title':
          'Stories heimlich ansehen oder Profilfotos vergrößern',
      'story_login_required':
          'Zum anonymen Ansehen von Stories ist eine gültige Instagram-Anmeldung erforderlich. Wenn du bereits eingeloggt bist und diese Warnung weiter siehst, melde dich bei Instagram ab und wieder an.',
      'story_ad_wait': 'Wird nach der Werbung angezeigt. Bitte warten.',
      'story_action_title': 'Was möchtest du tun?',
      'story_view_photo': 'Profilfoto vergrößern',
      'story_watch_secret': 'Story heimlich ansehen',
      'story_no_data': 'Keine Story-Daten verfügbar.',
      'story_close': 'SCHLIESSEN',
      'adsense_banner': 'WERBEFLÄCHE',
      'analysis_available_now': 'Analyse ist jetzt verfügbar.',
      'analysis_fast_no_change': 'Schnellprüfung: Keine Änderung gefunden.',
      'data_fetch_error':
          'Daten konnten nicht geladen werden: {err}\n\nTipp: Abmelden und erneut anmelden kann helfen.',
      'error_title': 'FEHLER',
      'followers': 'Follower',
      'following': 'Gefolgt',
      'left_followers': 'Verlorene Follower',
      'left_following': 'Entfolgte Konten',
      'new_followers': 'Neue Follower',
      'non_followers': 'Folgen nicht zurück',
      'premium_not_active':
          'Kauf abgeschlossen, aber Premium ist nicht aktiv. Bitte versuche es erneut.',
      'rate_test_message':
          'Gefällt dir die App? Deine Bewertung hilft uns sehr.',
      'redirecting': 'Sitzung bestätigt, du wirst weitergeleitet...',
      'usage_metrics_active': 'Aktive Nutzer',
      'usage_metrics_live': 'live',
      'usage_metrics_na': '--',
      'usage_metrics_queries': 'Tägliche Abfragen',
      'usage_metrics_title': 'Tagesmetriken',
      'warning': 'Warnung',
    },
    'ko': {
      'story_section_title': '스토리를 몰래 보거나 프로필 사진을 확대하세요',
      'story_login_required': '스토리를 익명으로 보려면 유효한 Instagram 로그인 세션이 필요합니다. 이미 로그인했는데도 이 안내가 계속 보이면 Instagram에서 로그아웃한 뒤 다시 로그인해 주세요.',
      'story_ad_wait': '광고 후 표시됩니다. 잠시만 기다려 주세요.',
      'story_action_title': '무엇을 하시겠어요?',
      'story_view_photo': '프로필 사진 확대',
      'story_watch_secret': '스토리 몰래 보기',
      'story_no_data': '스토리 데이터가 없습니다.',
      'story_close': '닫기',
      'adsense_banner': '광고 영역',
      'analysis_available_now': '지금 분석할 수 있어요.',
      'analysis_fast_no_change': '빠른 확인: 변경 사항이 없습니다.',
      'data_fetch_error':
          '데이터를 가져오지 못했습니다: {err}\\n\\n팁: 로그아웃 후 다시 로그인해 보세요.',
      'error_title': '오류',
      'followers': '팔로워',
      'following': '팔로잉',
      'left_followers': '떠난 팔로워',
      'left_following': '언팔로우한 계정',
      'new_followers': '새 팔로워',
      'non_followers': '맞팔하지 않는 계정',
      'premium_not_active':
          '구매는 완료되었지만 프리미엄이 활성화되지 않았습니다. 다시 시도해 주세요.',
      'rate_test_message': '앱이 마음에 드시나요? 평점이 큰 도움이 됩니다.',
      'redirecting': '세션이 확인되어 이동 중입니다...',
      'usage_metrics_active': '활성 사용자',
      'usage_metrics_live': '실시간',
      'usage_metrics_na': '--',
      'usage_metrics_queries': '일일 조회 수',
      'usage_metrics_title': '일일 지표',
      'warning': '경고',
    },
    'ja': {
      'story_section_title': 'ストーリーをこっそり見る / プロフィール写真を拡大',
      'story_login_required': 'ストーリーを匿名で表示するには、有効なInstagramログインセッションが必要です。すでにログイン済みでもこの案内が出る場合は、Instagramで一度ログアウトしてから再ログインしてください。',
      'story_ad_wait': '広告の後に表示されます。しばらくお待ちください。',
      'story_action_title': 'どうしますか？',
      'story_view_photo': 'プロフィール写真を拡大',
      'story_watch_secret': '足跡を残さず見る',
      'story_no_data': 'ストーリーデータがありません。',
      'story_close': '閉じる',
      'adsense_banner': '広告枠',
      'analysis_available_now': '今すぐ分析できます。',
      'analysis_fast_no_change': 'クイック確認: 変更は見つかりませんでした。',
      'data_fetch_error':
          'データを取得できませんでした: {err}\\n\\nヒント: いったんログアウトして再ログインすると改善する場合があります。',
      'error_title': 'エラー',
      'followers': 'フォロワー',
      'following': 'フォロー中',
      'left_followers': '離れたフォロワー',
      'left_following': 'フォロー解除したアカウント',
      'new_followers': '新しいフォロワー',
      'non_followers': 'フォローバックしていないユーザー',
      'premium_not_active': '購入は完了しましたが、プレミアムが有効になっていません。もう一度お試しください。',
      'rate_test_message': 'このアプリは役に立ちましたか？評価で応援してください。',
      'redirecting': 'セッションを確認しました。リダイレクトしています...',
      'usage_metrics_active': 'アクティブユーザー',
      'usage_metrics_live': 'ライブ',
      'usage_metrics_na': '--',
      'usage_metrics_queries': '1日のクエリ数',
      'usage_metrics_title': '日次メトリクス',
      'warning': '警告',
    },
    'ru': {
      'story_section_title':
          'Смотреть сторис анонимно или увеличить фото профиля',
      'story_login_required':
          'Чтобы смотреть сторис анонимно, нужен действующий вход в Instagram. Если вы уже вошли, но это сообщение не исчезает, выйдите из Instagram и войдите снова.',
      'story_ad_wait': 'Появится после рекламы. Пожалуйста, подождите.',
      'story_action_title': 'Что хотите сделать?',
      'story_view_photo': 'Увеличить фото профиля',
      'story_watch_secret': 'Смотреть сторис анонимно',
      'story_no_data': 'Данные сторис недоступны.',
      'story_close': 'ЗАКРЫТЬ',
      'adsense_banner': 'РЕКЛАМНОЕ МЕСТО',
      'analysis_available_now': 'Анализ доступен сейчас.',
      'analysis_fast_no_change': 'Быстрая проверка: изменений не найдено.',
      'data_fetch_error':
          'Не удалось получить данные: {err}\\n\\nСовет: выйдите и войдите снова.',
      'error_title': 'ОШИБКА',
      'followers': 'Подписчики',
      'following': 'Подписки',
      'left_followers': 'Отписавшиеся',
      'left_following': 'Вы перестали читать',
      'new_followers': 'Новые подписчики',
      'non_followers': 'Не подписаны в ответ',
      'premium_not_active':
          'Покупка завершена, но Premium не активен. Попробуйте снова.',
      'rate_test_message': 'Нравится приложение? Ваша оценка очень помогает.',
      'redirecting': 'Сессия подтверждена, выполняется переход...',
      'usage_metrics_active': 'Активные пользователи',
      'usage_metrics_live': 'в реальном времени',
      'usage_metrics_na': '--',
      'usage_metrics_queries': 'Запросов за день',
      'usage_metrics_title': 'Дневные метрики',
      'warning': 'Предупреждение',
    },
    'pt': {
      'story_section_title':
          'Ver stories em segredo ou ampliar foto de perfil',
      'story_login_required':
          'Para ver stories de forma anônima, é necessário um login válido no Instagram. Se você já entrou e este aviso continua, saia do Instagram e entre novamente.',
      'story_ad_wait': 'Será exibido após o anúncio. Aguarde.',
      'story_action_title': 'O que você quer fazer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver story em segredo',
      'story_no_data': 'Não há dados de story disponíveis.',
      'story_close': 'FECHAR',
      'adsense_banner': 'ESPAÇO DE ANÚNCIO',
      'analysis_available_now': 'Análise disponível agora.',
      'analysis_fast_no_change': 'Verificação rápida: nenhuma alteração encontrada.',
      'data_fetch_error':
          'Não foi possível obter os dados: {err}\\n\\nDica: sair e entrar novamente pode ajudar.',
      'error_title': 'ERRO',
      'followers': 'Seguidores',
      'following': 'Seguindo',
      'left_followers': 'Perdeu seguidores',
      'left_following': 'Deixou de seguir',
      'new_followers': 'Novos seguidores',
      'non_followers': 'Não seguem de volta',
      'premium_not_active':
          'Compra concluída, mas o Premium não foi ativado. Tente novamente.',
      'rate_test_message': 'Está gostando do app? Sua avaliação ajuda muito.',
      'redirecting': 'Sessão verificada, redirecionando...',
      'usage_metrics_active': 'Usuários ativos',
      'usage_metrics_live': 'ao vivo',
      'usage_metrics_na': '--',
      'usage_metrics_queries': 'Consultas diárias',
      'usage_metrics_title': 'Métricas diárias',
      'warning': 'Aviso',
    },
    'ar': {
      'story_section_title':
          'شاهد القصص بسرية أو كبّر صورة الملف الشخصي',
      'story_login_required':
          'لمشاهدة القصص بشكل سري، يلزم تسجيل دخول صالح في Instagram. إذا كنت مسجلا بالفعل وما زال هذا التنبيه يظهر، سجل الخروج من Instagram ثم سجل الدخول مرة أخرى.',
      'story_ad_wait': 'سيظهر بعد الإعلان. يرجى الانتظار.',
      'story_action_title': 'ماذا تريد أن تفعل؟',
      'story_view_photo': 'تكبير صورة الملف الشخصي',
      'story_watch_secret': 'مشاهدة القصة بسرية',
      'story_no_data': 'لا تتوفر بيانات القصة.',
      'story_close': 'إغلاق',
      'adsense_banner': 'مساحة إعلانية',
      'analysis_available_now': 'التحليل متاح الآن.',
      'analysis_fast_no_change': 'فحص سريع: لا توجد تغييرات.',
      'data_fetch_error':
          'تعذّر جلب البيانات: {err}\\n\\nنصيحة: سجّل الخروج ثم سجّل الدخول مرة أخرى.',
      'error_title': 'خطأ',
      'followers': 'المتابعون',
      'following': 'تتابع',
      'left_followers': 'من ألغى متابعتك',
      'left_following': 'ألغيت متابعتهم',
      'new_followers': 'متابعون جدد',
      'non_followers': 'لا يتابعونك بالمقابل',
      'premium_not_active':
          'اكتملت عملية الشراء لكن لم يتم تفعيل Premium. حاول مرة أخرى.',
      'rate_test_message': 'هل أعجبك التطبيق؟ تقييمك يساعدنا كثيرًا.',
      'redirecting': 'تم التحقق من الجلسة، جارٍ التحويل...',
      'usage_metrics_active': 'المستخدمون النشطون',
      'usage_metrics_live': 'مباشر',
      'usage_metrics_na': '--',
      'usage_metrics_queries': 'عدد التحليلات اليومية',
      'usage_metrics_title': 'إحصاءات اليوم',
      'warning': 'تحذير',
    },
    'es': {
      'story_section_title':
          'Ver historias en secreto o ampliar foto de perfil',
      'story_login_required':
          'Para ver historias en modo anónimo necesitas una sesión válida de Instagram. Si ya iniciaste sesión y este aviso sigue apareciendo, cierra sesión en Instagram y vuelve a iniciar sesión.',
      'story_ad_wait':
          'Se mostrará después del anuncio. Espera un momento.',
      'story_action_title': '¿Qué te gustaría hacer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver historia en secreto',
      'story_no_data': 'No hay datos de historias disponibles.',
      'story_close': 'CERRAR',
    },
    'es-mx': {
      'story_section_title':
          'Ver historias en secreto o ampliar foto de perfil',
      'story_login_required':
          'Para ver historias en modo anónimo necesitas una sesión válida de Instagram. Si ya iniciaste sesión y este aviso sigue apareciendo, cierra sesión en Instagram y vuelve a iniciar sesión.',
      'story_ad_wait':
          'Se mostrará después del anuncio. Espera un momento.',
      'story_action_title': '¿Qué te gustaría hacer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver historia en secreto',
      'story_no_data': 'No hay datos de historias disponibles.',
      'story_close': 'CERRAR',
    },
    'hi': {
      'story_section_title':
          'स्टोरी चुपचाप देखें या प्रोफाइल फोटो बड़ा करें',
      'story_login_required':
          'स्टोरी को गुप्त रूप से देखने के लिए Instagram में मान्य लॉगिन सत्र जरूरी है। यदि आपने पहले से लॉगिन किया है और यह संदेश फिर भी दिख रहा है, तो Instagram से लॉगआउट करके दोबारा लॉगिन करें।',
      'story_ad_wait':
          'विज्ञापन के बाद दिखाया जाएगा। कृपया इंतज़ार करें।',
      'story_action_title': 'आप क्या करना चाहेंगे?',
      'story_view_photo': 'प्रोफाइल फोटो बड़ा करें',
      'story_watch_secret': 'स्टोरी चुपचाप देखें',
      'story_no_data': 'स्टोरी डेटा उपलब्ध नहीं है।',
      'story_close': 'बंद करें',
    },
    'hu': {
      'story_section_title':
          'Sztorik megtekintése titokban vagy profilkép nagyítása',
      'story_login_required':
          'A történetek névtelen megtekintéséhez érvényes Instagram-bejelentkezés szükséges. Ha már be vagy jelentkezve, de ez az üzenet továbbra is megjelenik, jelentkezz ki az Instagramból, majd jelentkezz be újra.',
      'story_ad_wait':
          'A hirdetés után jelenik meg. Kérjük, várj.',
      'story_action_title': 'Mit szeretnél csinálni?',
      'story_view_photo': 'Profilkép nagyítása',
      'story_watch_secret': 'Sztori megtekintése titokban',
      'story_no_data': 'Nem érhető el sztoriadat.',
      'story_close': 'BEZÁR',
    },
    'zh-hans': {
      'story_section_title': '匿名查看动态或放大头像',
      'story_login_required': '要匿名查看动态，需要有效的 Instagram 登录会话。如果你已经登录但仍看到此提示，请先退出 Instagram，再重新登录。',
      'story_ad_wait': '广告后显示，请稍候。',
      'story_action_title': '你想做什么？',
      'story_view_photo': '放大头像',
      'story_watch_secret': '匿名查看动态',
      'story_no_data': '暂无动态数据。',
      'story_close': '关闭',
    },
    'id': {
      'story_section_title':
          'Lihat story diam-diam atau perbesar foto profil',
      'story_login_required':
          'Untuk melihat story secara anonim, diperlukan sesi login Instagram yang valid. Jika Anda sudah login tetapi peringatan ini masih muncul, keluar dari Instagram lalu masuk kembali.',
      'story_ad_wait': 'Akan ditampilkan setelah iklan. Harap tunggu.',
      'story_action_title': 'Apa yang ingin Anda lakukan?',
      'story_view_photo': 'Perbesar foto profil',
      'story_watch_secret': 'Lihat story diam-diam',
      'story_no_data': 'Data story tidak tersedia.',
      'story_close': 'TUTUP',
    },
    'nl': {
      'story_section_title':
          'Bekijk stories stiekem of vergroot de profielfoto',
      'story_login_required':
          'Voor het anoniem bekijken van stories is een geldige Instagram-login nodig. Ben je al ingelogd maar zie je deze melding nog steeds, log dan uit bij Instagram en log opnieuw in.',
      'story_ad_wait': 'Wordt na de advertentie getoond. Even geduld.',
      'story_action_title': 'Wat wil je doen?',
      'story_view_photo': 'Profielfoto vergroten',
      'story_watch_secret': 'Story stiekem bekijken',
      'story_no_data': 'Geen storygegevens beschikbaar.',
      'story_close': 'SLUITEN',
    },
    'fr': {
      'story_section_title':
          'Voir les stories discrètement ou agrandir la photo de profil',
      'story_login_required':
          'Pour voir les stories en mode anonyme, une session Instagram valide est nécessaire. Si vous êtes déjà connecté mais que ce message persiste, déconnectez-vous de Instagram puis reconnectez-vous.',
      'story_ad_wait': 'S’affichera après la publicité. Veuillez patienter.',
      'story_action_title': 'Que souhaitez-vous faire ?',
      'story_view_photo': 'Agrandir la photo de profil',
      'story_watch_secret': 'Voir la story discrètement',
      'story_no_data': 'Aucune donnée de story disponible.',
      'story_close': 'FERMER',
    },
    'it': {
      'story_section_title':
          'Guarda le storie in segreto o ingrandisci la foto profilo',
      'story_login_required':
          'Per vedere le storie in modo anonimo serve una sessione Instagram valida. Se hai già fatto login ma questo avviso continua a comparire, esci da Instagram e accedi di nuovo.',
      'story_ad_wait': 'Verrà mostrato dopo l’annuncio. Attendi.',
      'story_action_title': 'Cosa vuoi fare?',
      'story_view_photo': 'Ingrandisci la foto profilo',
      'story_watch_secret': 'Guarda la storia in segreto',
      'story_no_data': 'Nessun dato story disponibile.',
      'story_close': 'CHIUDI',
    },
    'vi': {
      'story_section_title':
          'Xem story bí mật hoặc phóng to ảnh hồ sơ',
      'story_login_required':
          'Để xem story ẩn danh, bạn cần phiên đăng nhập Instagram hợp lệ. Nếu bạn đã đăng nhập mà vẫn thấy thông báo này, hãy đăng xuất khỏi Instagram rồi đăng nhập lại.',
      'story_ad_wait': 'Sẽ hiển thị sau quảng cáo. Vui lòng chờ.',
      'story_action_title': 'Bạn muốn làm gì?',
      'story_view_photo': 'Phóng to ảnh hồ sơ',
      'story_watch_secret': 'Xem story bí mật',
      'story_no_data': 'Không có dữ liệu story.',
      'story_close': 'ĐÓNG',
    },
    'th': {
      'story_section_title':
          'ดูสตอรีแบบลับ ๆ หรือขยายรูปโปรไฟล์',
      'story_login_required':
          'การดูสตอรีแบบไม่ระบุตัวตนต้องใช้เซสชันเข้าสู่ระบบ Instagram ที่ถูกต้อง หากคุณเข้าสู่ระบบแล้วแต่ยังเห็นข้อความนี้ ให้ลงชื่อออกจาก Instagram แล้วเข้าสู่ระบบอีกครั้ง',
      'story_ad_wait': 'จะแสดงหลังโฆษณา กรุณารอสักครู่',
      'story_action_title': 'คุณต้องการทำอะไร?',
      'story_view_photo': 'ขยายรูปโปรไฟล์',
      'story_watch_secret': 'ดูสตอรีแบบลับ ๆ',
      'story_no_data': 'ไม่มีข้อมูลสตอรี',
      'story_close': 'ปิด',
    },
    'pl': {
      'story_section_title':
          'Oglądaj relacje anonimowo lub powiększ zdjęcie profilowe',
      'story_login_required':
          'Aby oglądać relacje anonimowo, wymagane jest poprawne logowanie do Instagrama. Jeśli jesteś już zalogowany, a komunikat nadal się pojawia, wyloguj się z Instagrama i zaloguj ponownie.',
      'story_ad_wait':
          'Zostanie pokazane po reklamie. Prosimy czekać.',
      'story_action_title': 'Co chcesz zrobić?',
      'story_view_photo': 'Powiększ zdjęcie profilowe',
      'story_watch_secret': 'Oglądaj relację anonimowo',
      'story_no_data': 'Brak danych relacji.',
      'story_close': 'ZAMKNIJ',
    },
  };

  String _t(String key, [Map<String, String>? args]) {
    if (key == 'tagline') return 'Professional Social Media Solutions';

    final String lang = _lang.trim().toLowerCase();
    final String? direct = _humanizedUiOverrides[lang]?[key] ??
        _localized[lang]?[key] ??
        _flowLocalized[lang]?[key];
    final String? enText =
        _localized['en']?[key] ?? _flowLocalized['en']?[key];
    final String? trText =
        _localized['tr']?[key] ?? _flowLocalized['tr']?[key];

    bool looksUntranslated(String? value, String? en) {
      if (lang == 'en') return false;
      final String v = (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      final String e = (en ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (v.isEmpty || e.isEmpty) return false;
      return v.toLowerCase() == e.toLowerCase();
    }

    String res;
    if (direct == null || direct.trim().isEmpty || looksUntranslated(direct, enText)) {
      final String trBase = (trText ?? enText ?? key).trim();
      final String enBase = (enText ?? trText ?? key).trim();
      res = localizeTrEn(lang, trBase, enBase);
    } else {
      res = direct;
    }

    if (args != null) {
      args.forEach((k, v) {
        res = res.replaceAll('{$k}', v);
      });
    }
    final String repaired = _repairDisplayText(res).trim();
    if (!_looksLikeMojibakeText(repaired)) return repaired;

    String fallback = _repairDisplayText((enText ?? trText ?? key).trim());
    if (args != null) {
      args.forEach((k, v) {
        fallback = fallback.replaceAll('{$k}', v);
      });
    }
    return fallback.trim();
  }

  bool _isSupportedLanguageCode(String code) {
    return _supportedLanguageCodes.contains(code.trim().toLowerCase());
  }

  String _languageFlagFor(String code) {
    return _languageFlags[code.trim().toLowerCase()] ?? '\u{1F310}';
  }

  String _compactLanguageName(String code) {
    final String normalized = code.trim().toLowerCase();
    final String nativeName =
        _languageNativeNames[normalized] ?? normalized.toUpperCase();
    const int maxLength = 12;
    if (nativeName.length <= maxLength) return nativeName;
    return '${nativeName.substring(0, maxLength - 1)}\u2026';
  }

  String _resolveLanguageFromLocale(String localeRaw) {
    final String locale = localeRaw.trim().toLowerCase().replaceAll('-', '_');
    if (locale.isEmpty) return 'en';

    final String languageCode = locale.split('_').first.trim();

    if (languageCode == 'es') {
      if (locale.startsWith('es_mx') || locale.startsWith('es_419'))
        return 'es-mx';
      return 'es';
    }

    if (languageCode == 'zh') {
      if (locale.contains('_hant') ||
          locale.endsWith('_tw') ||
          locale.endsWith('_hk') ||
          locale.endsWith('_mo')) {
        return 'en';
      }
      return 'zh-hans';
    }

    if (languageCode == 'in') return 'id';

    switch (languageCode) {
      case 'tr':
      case 'en':
      case 'de':
      case 'ko':
      case 'ja':
      case 'ru':
      case 'pt':
      case 'ar':
      case 'hi':
      case 'hu':
      case 'id':
      case 'nl':
      case 'fr':
      case 'it':
      case 'vi':
      case 'th':
      case 'pl':
        return languageCode;
      default:
        return 'en';
    }
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final String pref =
        (prefs.getString('language_code') ?? '').trim().toLowerCase();
    if (_isSupportedLanguageCode(pref)) {
      if (mounted) setState(() => _lang = pref);
      return;
    }

    try {
      final String resolved = _resolveLanguageFromLocale(Platform.localeName);
      if (mounted) setState(() => _lang = resolved);
    } catch (_) {
      if (mounted) setState(() => _lang = 'en');
    }
  }

  Future<void> _setLanguage(String code) async {
    final String normalized = code.trim().toLowerCase();
    if (!_isSupportedLanguageCode(normalized)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', normalized);
    if (mounted) setState(() => _lang = normalized);
  }

  @override
  void initState() {
    super.initState();
    try {
      _lang = _resolveLanguageFromLocale(Platform.localeName);
    } catch (_) {
      _lang = 'en';
    }
    WidgetsBinding.instance.addObserver(this);
    PurchasesService.instance.isPremium.addListener(_onPremiumChanged);
    PurchasesService.instance.lastPurchaseError
        .addListener(_onPurchaseErrorChanged);
    _isPremium = PurchasesService.instance.isPremium.value;
    _lastObservedPurchaseError =
        PurchasesService.instance.lastPurchaseError.value.trim();
    _storyScrollController = ScrollController();
    _logFirebaseDiagnostic('app', 'dashboard init state created');
    _loadStoredData();
    _loadLanguagePreference();
    _tryAutoLogin();
    _loadRemoteUserFlags();
    _updatePrivacyOptionsRequirement();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkRatingDialog();
      _maybeLoadBannerAfterConsent();
      _maybeRequestATT();

      if (_forceFirestoreTest) {
        Future.delayed(const Duration(seconds: 5), () {
          if (!mounted) return;
          unawaited(_testFirestoreWrite());
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSessionCookieFromWebViewStore());
      if (isLoggedIn) {
        unawaited(TelemetryService.instance.recordSeen());
      }
    }
  }

  void _onPremiumChanged() {
    final bool premium = PurchasesService.instance.isPremium.value;
    if (_isPremium == premium) return;
    if (mounted) {
      setState(() => _isPremium = premium);
    } else {
      _isPremium = premium;
    }

    if (premium) {
      _disposeBannerAd();
    } else {
      unawaited(_maybeLoadBannerAfterConsent());
    }
  }

  void _disposeBannerAd() {
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    if (mounted) {
      setState(() {
        _isAdLoaded = false;
        _bannerAdError = null;
        _googleAdWarning = null;
      });
    } else {
      _isAdLoaded = false;
      _bannerAdError = null;
      _googleAdWarning = null;
    }
  }

  String _normalizeUserKey(String raw) {
    String value = raw.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'^https?://(www\.)?instagram\.com/'), '');
    if (value.startsWith('@')) value = value.substring(1);
    final int q = value.indexOf('?');
    if (q >= 0) value = value.substring(0, q);
    final int h = value.indexOf('#');
    if (h >= 0) value = value.substring(0, h);
    value = value.replaceAll('/', '').replaceAll(' ', '');
    value = value
        .replaceAll('\u0131', 'i')
        .replaceAll('\u015f', 's')
        .replaceAll('\u011f', 'g')
        .replaceAll('\u00fc', 'u')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u00e7', 'c');
    return value;
  }

  bool _isPlaceholderUsername(String username) {
    final String u = _normalizeUserKey(username);
    return u.isEmpty || u == 'kullanici' || u == 'user';
  }

  Set<String> _parseUserList(String raw) {
    return raw
        .split(RegExp(r'[,\n;]'))
        .map(_normalizeUserKey)
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  Future<void> _refreshUsernameForBanCheckIfNeeded({bool force = false}) async {
    if (!isLoggedIn || savedUserId == null || savedCookie == null) return;
    if (!force && !_isPlaceholderUsername(currentUsername)) return;

    try {
      final info = await _fetchUserInfoRaw(
          savedUserId!, savedCookie!, _resolveUserAgent());
      final String? fetched = info?['username']?.toString().trim();
      if (fetched == null || fetched.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => currentUsername = fetched);
      } else {
        currentUsername = fetched;
      }
      await prefs.setString('session_username', fetched);
    } catch (_) {}
  }

  Future<void> _loadRemoteUserFlags() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.setDefaults({
        'bannedusers': '',
        'removeadsfor': '',
        'removeallads': false,
        'announcement_text': '',
        'bizipuanlaandroid': '',
        'bizipuanlaios': '',
        'watchstoriessecretly': true,
      });
      await remoteConfig.fetchAndActivate();
      final String bannedRaw = remoteConfig.getString('bannedusers').trim();
      final String removeAdsRaw = remoteConfig.getString('removeadsfor').trim();
      final bool removeAllAds = remoteConfig.getBool('removeallads');
      final bool watchStories = remoteConfig.getBool('watchstoriessecretly');
      final String announcementText =
          remoteConfig.getString('announcement_text').trim();
      _rateUrlAndroid = remoteConfig.getString('bizipuanlaandroid').trim();
      _rateUrlIos = remoteConfig.getString('bizipuanlaios').trim();
      _bannedUsers = _parseUserList(bannedRaw);
      _removeAdsUsers = _parseUserList(removeAdsRaw);
      _removeAllAds = removeAllAds;
      _watchStoriesEnabled = watchStories;
      _announcementText = announcementText;
      if (_removeAllAds) {
        _disableAdsForUser();
      }
      await _refreshUsernameForBanCheckIfNeeded();
      _applyUserFlags();
      if (mounted) setState(() {});
    } catch (_) {
    } finally {
      _remoteFlagsLoaded = true;
    }
  }

  void _applyUserFlags() {
    if (!isLoggedIn) {
      bool changed = false;
      if (_isBanned) {
        _isBanned = false;
        changed = true;
      }
      if (_isAdminUser) {
        _isAdminUser = false;
        changed = true;
      }
      if (changed && mounted) setState(() {});
      return;
    }
    final String username = _normalizeUserKey(currentUsername);
    final bool banned = _bannedUsers.contains(username);
    final bool admin = _removeAdsUsers.contains(username);
    _isBanned = banned;
    _isAdminUser = admin;
    if (_removeAllAds || banned || admin) {
      _disableAdsForUser();
    }
    if (mounted) setState(() {});
  }

  void _disableAdsForUser() {
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    _isAdLoaded = false;
    _bannerAdError = null;
    _googleAdWarning = null;
    _adsHidden = true;
  }

  Future<void> _maybeLoadBannerAfterConsent() async {
    if (!_remoteFlagsLoaded) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _maybeLoadBannerAfterConsent();
      });
      return;
    }
    if (_adsDisabled) return;
    _consentWatchTimer?.cancel();
    _consentWatchTries = 0;
    _consentWatchTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      _consentWatchTries++;
      if (_consentWatchTries > 60) {
        t.cancel();
        return;
      }
      try {
        if (await ConsentInformation.instance.canRequestAds()) {
          _loadBannerAd();
          t.cancel();
        }
      } catch (_) {}
    });
  }

  Future<bool> _shouldUseNonPersonalizedAds() async {
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      return status != ConsentStatus.obtained &&
          status != ConsentStatus.notRequired;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkRatingDialog() async {
    if (!Platform.isIOS) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final int count = prefs.getInt('app_launch_count') ?? 0;
      final bool hasRequested = prefs.getBool('has_rated_app') ?? false;

      if (count == 2 && !hasRequested) {
        await prefs.setBool('has_rated_app', true);
        unawaited(_launchRateUrl(userInitiated: false));
      }
    } catch (_) {}
  }

  Future<void> _launchRateUrl({bool userInitiated = true}) async {
    // On iOS, `SKStoreReviewController.requestReview` is rate-limited by Apple
    // and may show nothing even when it succeeds. For user-initiated taps,
    // prefer opening the App Store review page so the action always "responds".
    if (Platform.isIOS && !userInitiated) {
      try {
        await _reviewChannel.invokeMethod('requestReview');
      } catch (_) {}
      return;
    }

    final String rawUrl = Platform.isIOS ? _rateUrlIos : _rateUrlAndroid;
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      if (Platform.isIOS && userInitiated) {
        try {
          await _reviewChannel.invokeMethod('requestReview');
          return;
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizeTrEn(
              _lang, 'Magaza linki bulunamadi.', 'Store link not set.')),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    final String url = _normalizeStoreUrl(trimmed);
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizeTrEn(
              _lang, 'Geçersiz mağaza linki.', 'Invalid store link.')),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizeTrEn(
              _lang, 'Link açılamadı.', 'Could not open the link.')),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _openPrivacyPolicySource() async {
    final Uri uri = Uri.parse(_privacyPolicySourceUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizeTrEn(
            _lang, 'Link açılamadı.', 'Could not open the link.')),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _restorePurchasesPressed() async {
    if (isProcessing) return;
    _logFirebaseDiagnostic('purchase_restore', 'restore flow started');

    await PurchasesService.instance.configure(
      androidApiKey: _revenueCatAndroidApiKey,
      iosApiKey: _revenueCatIosApiKey,
    );

    if (!PurchasesService.instance.isConfigured) {
      _logFirebaseDiagnostic(
        'purchase_restore',
        'restore blocked: purchases not configured',
        isError: true,
        popCritical: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('purchases_not_configured')),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }

    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              backgroundColor:
                  isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              content: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('restoring_purchases'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ));

    final PurchaseAttemptResult result =
        await PurchasesService.instance.restorePurchases();

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    if (!mounted) return;

    if (result.errorMessage != null) {
      _logFirebaseDiagnostic(
        'purchase_restore',
        'restore failed: ${result.errorMessage}',
        isError: true,
        popCritical: true,
      );
      final String err =
          localizeTrEn(_lang, 'Lütfen tekrar deneyin.', 'Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('restore_purchases_failed', {'err': err})),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    if (result.success) {
      _logFirebaseDiagnostic('purchase_restore', 'restore success');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('restore_purchases_success')),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green.shade700,
      ));
      return;
    }

    _logFirebaseDiagnostic(
      'purchase_restore',
      'restore completed without entitlement',
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_t('restore_purchases_none')),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.blueGrey.shade900,
    ));
  }

  String _normalizeStoreUrl(String input) {
    final String lower = input.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('market://') ||
        lower.startsWith('itms-apps://')) {
      return input;
    }
    return 'https://$input';
  }

  Future<void> _loadBannerAd() async {
    final bool useTestAds = _forceTestAds;
    if (_adsDisabled) {
      try {
        _bannerAd?.dispose();
      } catch (_) {}
      _bannerAd = null;
      if (mounted)
        setState(() {
          _isAdLoaded = false;
          _bannerAdError = null;
        });
      return;
    }

    final String adUnit = useTestAds
        ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716')
        : (Platform.isAndroid
            ? 'ca-app-pub-7480771330660307/9017777173'
            : 'ca-app-pub-7480771330660307/9017777173');

    if (_bannerAd != null) {
      try {
        _bannerAd!.dispose();
      } catch (_) {}
      _bannerAd = null;
      _isAdLoaded = false;
      _bannerAdError = null;
    }

    AdSize adSize = AdSize.banner;
    try {
      final int adWidth = MediaQuery.of(context).size.width.truncate();
      final AdSize? adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              adWidth);
      if (adaptive != null) adSize = adaptive;
    } catch (e) {
      if (kDebugMode) print('Adaptive size error: $e');
    }

    final bool useNpa = await _shouldUseNonPersonalizedAds();
    _bannerAd = BannerAd(
      adUnitId: adUnit,
      request: AdRequest(nonPersonalizedAds: useNpa),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Banner Ad Loaded! Size: ${ad.responseInfo}");
          if (mounted)
            setState(() {
              _isAdLoaded = true;
              _bannerAdError = null;
              _googleAdWarning = null;
            });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint("Banner Ad Failed: $err");
          ad.dispose();
          if (mounted)
            setState(() {
              _isAdLoaded = false;
              _bannerAdError = err.message;
              _googleAdWarning = err.message;
            });
        },
      ),
    );

    try {
      await _bannerAd!.load();
    } catch (e) {
      if (kDebugMode) print('Ad load error: $e');
      _setGoogleAdWarning(e.toString());
    }
  }

  Future<Map<String, dynamic>> _showRewardedAdWithResult(
      {String? adUnitOverride}) async {
    if (_adsDisabled) return {"status": true, "skipped": true};
    if (_isRewardedLoading) {
      return {
        "status": false,
        "error": localizeTrEn(_lang, 'Yükleniyor...', 'Loading...'),
      };
    }
    setState(() {
      _isRewardedLoading = true;
    });

    final bool useTestAds = _forceTestAds;

    final String adUnit = useTestAds
        ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910')
        : (adUnitOverride ??
            (Platform.isAndroid
                ? 'ca-app-pub-7480771330660307/1330858844'
                : 'ca-app-pub-7480771330660307/1330858844'));

    final Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();

    InterstitialAd? tempAd;

    final bool useNpa = await _shouldUseNonPersonalizedAds();
    InterstitialAd.load(
      adUnitId: adUnit,
      request: AdRequest(nonPersonalizedAds: useNpa),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          tempAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              try {
                ad.dispose();
              } catch (_) {}
              if (!c.isCompleted) c.complete({"status": true});
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              try {
                ad.dispose();
              } catch (_) {}
              final String errMsg =
                  '${localizeTrEn(_lang, 'Gösterim hatası', 'Show error')}: ${err.message}';
              _setGoogleAdWarning(errMsg);
              if (!c.isCompleted) {
                c.complete({
                  "status": false,
                  "error": errMsg,
                });
              }
            },
          );
          try {
            ad.show();
          } catch (e) {
            final String errMsg =
                '${localizeTrEn(_lang, 'Hata', 'Exception')}: $e';
            _setGoogleAdWarning(errMsg);
            if (!c.isCompleted) {
              c.complete({
                "status": false,
                "error": errMsg,
              });
            }
          }
        },
        onAdFailedToLoad: (LoadAdError err) {
          debugPrint("Ad failed to load: $err");
          final String errMsg =
              '${localizeTrEn(_lang, 'Yükleme hatası', 'Load error')}: ${err.message} '
              '(${localizeTrEn(_lang, 'Kod', 'Code')}: ${err.code})';
          _setGoogleAdWarning(errMsg);
          if (!c.isCompleted) {
            c.complete({
              "status": false,
              "error": errMsg,
            });
          }
        },
      ),
    );

    Map<String, dynamic> result = {
      "status": false,
      "error": localizeTrEn(_lang, "Zaman aşımı", "Timeout"),
    };
    try {
      result = await c.future.timeout(const Duration(seconds: 45));
    } catch (_) {}

    try {
      tempAd?.dispose();
    } catch (_) {}
    setState(() {
      _isRewardedLoading = false;
    });
    if (result["status"] == true) {
      _clearGoogleAdWarning();
      try {
        if (mounted) {
          setState(() {
            _justWatchedReward = true;
          });
        }
      } catch (_) {}
      unawaited(TelemetryService.instance.recordRewardedAdWatched());
    } else {
      final String err = (result["error"] ?? '').toString().trim();
      if (err.isNotEmpty) _setGoogleAdWarning(err);
    }
    return result;
  }

  Future<DateTime> _getEstimatedNetworkTime() async {
    if (_networkTimeOffsetMs != null) {
      return DateTime.now().add(Duration(milliseconds: _networkTimeOffsetMs!));
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? offsetMs = prefs.getInt(_networkTimeOffsetKey);
      if (offsetMs != null) {
        _networkTimeOffsetMs = offsetMs;
        return DateTime.now().add(Duration(milliseconds: offsetMs));
      }
    } catch (_) {}
    return DateTime.now();
  }

  Future<DateTime> _getNetworkTime() async {
    try {
      final response = await http
          .head(Uri.parse(_privacyPolicySourceUrl))
          .timeout(const Duration(seconds: 2));
      final String? dateHeader = response.headers['date'];
      if (dateHeader != null) {
        final DateTime networkTime = HttpDate.parse(dateHeader).toLocal();
        final DateTime localNow = DateTime.now();
        final int offsetMs = networkTime.difference(localNow).inMilliseconds;
        _networkTimeOffsetMs = offsetMs;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_networkTimeOffsetKey, offsetMs);
        } catch (_) {}
        return networkTime;
      }
    } catch (_) {}
    return DateTime.now();
  }

  void _refreshNetworkTimeOffset() {
    _getNetworkTime();
  }

  Future<void> _startCountdownFromStoredTime() async {
    _cancelCountdown();
    final prefs = await SharedPreferences.getInstance();
    final int? lastMs = prefs.getInt('last_update_time');
    if (lastMs == null) {
      if (mounted)
        setState(() {
          _remainingToNextAnalysis = null;
        });
      return;
    }

    final DateTime last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    try {
      final DateTime now = await _getEstimatedNetworkTime();
      _refreshNetworkTimeOffset();
      Duration remaining = const Duration(hours: 6) - now.difference(last);
      if (remaining <= Duration.zero) {
        if (mounted)
          setState(() {
            _remainingToNextAnalysis = null;
          });
        return;
      }

      if (mounted)
        setState(() {
          _remainingToNextAnalysis = remaining;
        });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _remainingToNextAnalysis =
              (_remainingToNextAnalysis ?? Duration.zero) -
                  const Duration(seconds: 1);
          if ((_remainingToNextAnalysis ?? Duration.zero) <= Duration.zero) {
            _remainingToNextAnalysis = null;
            _cancelCountdown();
          }
        });
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _remainingToNextAnalysis = null;
        });
    }
  }

  void _cancelCountdown() {
    try {
      _countdownTimer?.cancel();
    } catch (_) {}
    _countdownTimer = null;
  }

  String _formatDuration(Duration d) {
    final hrs = d.inHours.remainder(100).toString().padLeft(2, '0');
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hrs:$mins:$secs';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
  String _threeDigits(int value) => value.toString().padLeft(3, '0');

  String _nowTurkeyIso8601() {
    final DateTime trNow = DateTime.now().toUtc().add(const Duration(hours: 3));
    return '${trNow.year.toString().padLeft(4, '0')}-'
        '${_twoDigits(trNow.month)}-'
        '${_twoDigits(trNow.day)}T'
        '${_twoDigits(trNow.hour)}:'
        '${_twoDigits(trNow.minute)}:'
        '${_twoDigits(trNow.second)}.'
        '${_threeDigits(trNow.millisecond)}+03:00';
  }

  String _currentGoogleAdWarningText() {
    final String warning = (_googleAdWarning ?? '').trim();
    if (warning.isNotEmpty) return warning;
    return (_bannerAdError ?? '').trim();
  }

  void _setGoogleAdWarning(String warning) {
    final String clean = warning.trim();
    if (clean.isEmpty) return;
    if (mounted) {
      setState(() {
        _googleAdWarning = clean;
      });
    } else {
      _googleAdWarning = clean;
    }
  }

  void _clearGoogleAdWarning() {
    if (mounted) {
      setState(() {
        _googleAdWarning = null;
      });
    } else {
      _googleAdWarning = null;
    }
  }

  void _showDiagSnackBar(
    String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!_userFacingFirebaseDiagnosticsEnabled) return;
    final SnackBar sb = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: backgroundColor,
      duration: duration,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(sb);
      return;
    }
    _diagScaffoldKey.currentState?.showSnackBar(sb);
  }

  String _firebaseProjectId() {
    try {
      final String projectId = Firebase.app().options.projectId.trim();
      if (projectId.isNotEmpty) return projectId;
    } catch (_) {}
    return '';
  }

  String _trimForDiagLog(String input, {int maxLength = 320}) {
    final String value = input.trim();
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  bool _isFirestoreDatabaseMissingBody(String rawBody) {
    final String body = rawBody.toLowerCase();
    return body.contains('database (default) does not exist');
  }

  String _firestoreSetupUrlForProject(String projectId) {
    final String clean = projectId.trim();
    if (clean.isEmpty) return _firestoreSetupBaseUrl;
    return '$_firestoreSetupBaseUrl$clean';
  }

  String _encodeFirestoreRestPath(String documentPath) {
    return documentPath
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
  }

  Map<String, dynamic> _toFirestoreRestValue(dynamic value) {
    if (value == null) return <String, dynamic>{'nullValue': null};
    if (value is bool) return <String, dynamic>{'booleanValue': value};
    if (value is int) {
      return <String, dynamic>{'integerValue': value.toString()};
    }
    if (value is double) return <String, dynamic>{'doubleValue': value};
    if (value is String) return <String, dynamic>{'stringValue': value};
    if (value is Timestamp) {
      return <String, dynamic>{
        'timestampValue': value.toDate().toUtc().toIso8601String(),
      };
    }
    if (value is DateTime) {
      return <String, dynamic>{
        'timestampValue': value.toUtc().toIso8601String(),
      };
    }
    if (value is List) {
      return <String, dynamic>{
        'arrayValue': <String, dynamic>{
          'values': value.map(_toFirestoreRestValue).toList(),
        },
      };
    }
    if (value is Map) {
      final Map<String, dynamic> fields = <String, dynamic>{};
      value.forEach((key, nestedValue) {
        final String nestedKey = key.toString().trim();
        if (nestedKey.isEmpty) return;
        fields[nestedKey] = _toFirestoreRestValue(nestedValue);
      });
      return <String, dynamic>{
        'mapValue': <String, dynamic>{'fields': fields},
      };
    }
    return <String, dynamic>{'stringValue': value.toString()};
  }

  Map<String, dynamic> _toFirestoreRestFields(Map<String, dynamic> data) {
    final Map<String, dynamic> fields = <String, dynamic>{};
    data.forEach((key, value) {
      final String cleanKey = key.trim();
      if (cleanKey.isEmpty) return;
      fields[cleanKey] = _toFirestoreRestValue(value);
    });
    return fields;
  }

  String _buildFirebaseStatusSummary() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = currentUser?.uid ?? '(none)';
    final bool isAnon = currentUser?.isAnonymous ?? false;
    final bool hasCookie = (savedCookie ?? '').trim().isNotEmpty;
    final bool hasUserId = (savedUserId ?? '').trim().isNotEmpty;
    final String projectId = _firebaseProjectId();
    return 'time=${DateTime.now().toIso8601String()}\n'
        'firebase_project_id=${projectId.isEmpty ? '(missing)' : projectId}\n'
        'firebase_auth_uid=$uid\n'
        'firebase_auth_is_anonymous=$isAnon\n'
        'app_is_logged_in=$isLoggedIn\n'
        'session_cookie_present=$hasCookie\n'
        'session_user_id_present=$hasUserId\n'
        'current_username=${currentUsername.trim().isEmpty ? '(empty)' : currentUsername.trim()}\n'
        'is_premium=$_isPremium\n'
        'purchases_configured=${PurchasesService.instance.isConfigured}\n'
        'last_purchase_error_empty=${PurchasesService.instance.lastPurchaseError.value.trim().isEmpty}\n'
        'network_offset_ms=${_networkTimeOffsetMs ?? '(null)'}';
  }

  void _appendFirebaseDiagnosticEvent(String line) {
    final List<String> next =
        List<String>.from(_firebaseDiagnosticEvents.value);
    next.insert(0, line);
    if (next.length > _maxFirebaseDiagnosticEvents) {
      next.removeRange(_maxFirebaseDiagnosticEvents, next.length);
    }
    _firebaseDiagnosticEvents.value = next;
  }

  void _logFirebaseDiagnostic(
    String area,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    bool isError = false,
    bool popCritical = false,
  }) {
    final String cleanArea = area.trim().isEmpty ? 'general' : area.trim();
    String cleanMessage = message.replaceAll('\r\n', '\n').trim();
    if (cleanMessage.isEmpty) cleanMessage = '(empty message)';
    if (cleanMessage.length > 2600) {
      cleanMessage = '${cleanMessage.substring(0, 2600)}...';
    }

    final String level = isError ? 'ERROR' : 'INFO';
    final StringBuffer buffer = StringBuffer()
      ..writeln(
          '[${DateTime.now().toIso8601String()}][$level][$cleanArea] $cleanMessage');
    if (error != null) {
      buffer.writeln('error=$error');
    }
    if (stackTrace != null) {
      final List<String> stackLines = stackTrace.toString().split('\n');
      final String compactStack = stackLines.take(8).join('\n').trim();
      if (compactStack.isNotEmpty) {
        buffer.writeln('stack=$compactStack');
      }
    }

    final String entry = buffer.toString().trimRight();
    debugPrint('[Diag][$cleanArea][$level] $cleanMessage');
    _appendFirebaseDiagnosticEvent(entry);

    if (popCritical && isError) {
      _showCriticalDiagnosticOverlay(
        title: cleanArea.toUpperCase(),
        details: entry,
      );
    }
  }

  String _buildCombinedDiagnosticDump() {
    final List<String> firebaseEvents = _firebaseDiagnosticEvents.value;
    final List<String> purchaseEvents =
        PurchasesService.instance.diagnosticEvents.value;
    final StringBuffer buffer = StringBuffer()
      ..writeln('==== STATUS ====')
      ..writeln(_buildFirebaseStatusSummary())
      ..writeln('')
      ..writeln('==== FIREBASE EVENTS (${firebaseEvents.length}) ====');
    for (final String line in firebaseEvents) {
      buffer.writeln(line);
      buffer.writeln('---');
    }
    buffer.writeln('');
    buffer.writeln('==== PURCHASE EVENTS (${purchaseEvents.length}) ====');
    for (final String line in purchaseEvents) {
      buffer.writeln(line);
      buffer.writeln('---');
    }
    return buffer.toString().trimRight();
  }

  Future<bool> _probeFirestoreViaRest({
    required User user,
    required String documentPath,
  }) async {
    final String projectId = _firebaseProjectId();
    if (projectId.isEmpty) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'probe blocked: projectId is empty',
        isError: true,
      );
      return false;
    }

    final String encodedPath = _encodeFirestoreRestPath(documentPath);
    final Uri uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$encodedPath',
    );

    String token;
    try {
      final String? rawToken =
          await user.getIdToken(true).timeout(_firestoreAuthTimeout);
      token = rawToken?.trim() ?? '';
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'probe token fetch failed',
        error: e,
        stackTrace: st,
        isError: true,
      );
      return false;
    }
    if (token.isEmpty) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'probe token fetch returned empty token',
        isError: true,
      );
      return false;
    }

    try {
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_firestoreRestTimeout);
      final String rawBody = response.body;
      final String body = _trimForDiagLog(rawBody);
      if (response.statusCode == 200) {
        _logFirebaseDiagnostic(
          'firestore_rest',
          'probe success status=${response.statusCode} path=$documentPath',
        );
        return true;
      }
      if (response.statusCode == 404) {
        if (_isFirestoreDatabaseMissingBody(rawBody)) {
          _logFirebaseDiagnostic(
            'firestore_rest',
            'probe failed: Firestore (default) database missing for project=$projectId setup=${_firestoreSetupUrlForProject(projectId)}',
            isError: true,
            popCritical: true,
          );
          return false;
        }
        _logFirebaseDiagnostic(
          'firestore_rest',
          'probe doc-not-found status=404 path=$documentPath (expected before first write)',
        );
        return true;
      }

      _logFirebaseDiagnostic(
        'firestore_rest',
        'probe failed status=${response.statusCode} path=$documentPath body=$body',
        isError: true,
      );
      return false;
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'probe request exception path=$documentPath',
        error: e,
        stackTrace: st,
        isError: true,
      );
      return false;
    }
  }

  Future<bool> _writeFirestoreViaRest({
    required User user,
    required String documentPath,
    required Map<String, dynamic> data,
    bool merge = true,
    required String reason,
  }) async {
    final String projectId = _firebaseProjectId();
    if (projectId.isEmpty) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'write blocked: projectId is empty reason=$reason',
        isError: true,
      );
      return false;
    }
    if (data.isEmpty) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'write blocked: empty payload reason=$reason path=$documentPath',
        isError: true,
      );
      return false;
    }

    String token;
    try {
      final String? rawToken =
          await user.getIdToken(true).timeout(_firestoreAuthTimeout);
      token = rawToken?.trim() ?? '';
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'write token fetch failed reason=$reason',
        error: e,
        stackTrace: st,
        isError: true,
      );
      return false;
    }
    if (token.isEmpty) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'write token fetch returned empty token reason=$reason',
        isError: true,
      );
      return false;
    }

    final String encodedPath = _encodeFirestoreRestPath(documentPath);
    final String baseUrl =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$encodedPath';

    final List<String> queryParts = <String>[];
    if (merge) {
      for (final String key in data.keys) {
        queryParts.add(
          'updateMask.fieldPaths=${Uri.encodeQueryComponent(key)}',
        );
      }
    }
    final Uri uri = Uri.parse(
      queryParts.isEmpty ? baseUrl : '$baseUrl?${queryParts.join('&')}',
    );

    final Map<String, dynamic> body = <String, dynamic>{
      'fields': _toFirestoreRestFields(data),
    };

    try {
      final http.Response response = await http
          .patch(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_firestoreRestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logFirebaseDiagnostic(
          'firestore_rest',
          'write success status=${response.statusCode} path=$documentPath reason=$reason merge=$merge',
        );
        return true;
      }

      if (response.statusCode == 404 &&
          _isFirestoreDatabaseMissingBody(response.body)) {
        _logFirebaseDiagnostic(
          'firestore_rest',
          'write failed: Firestore (default) database missing for project=$projectId setup=${_firestoreSetupUrlForProject(projectId)}',
          isError: true,
          popCritical: true,
        );
        return false;
      }

      _logFirebaseDiagnostic(
        'firestore_rest',
        'write failed status=${response.statusCode} path=$documentPath reason=$reason merge=$merge body=${_trimForDiagLog(response.body)}',
        isError: true,
      );
      return false;
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_rest',
        'write request exception path=$documentPath reason=$reason',
        error: e,
        stackTrace: st,
        isError: true,
      );
      return false;
    }
  }

  Future<void> _runFirestoreRestDiagnosticProbe() async {
    _logFirebaseDiagnostic('firestore_rest', 'manual rest probe started');
    final User? user = await _ensureFirestoreAuthUser();
    if (user == null) {
      _showDiagSnackBar(
        localizeTrEn(_lang, 'REST probe başarısız: kimlik doğrulama yok.',
            'REST probe failed: missing auth.'),
        backgroundColor: Colors.red,
      );
      return;
    }

    final bool ok = await _probeFirestoreViaRest(
      user: user,
      documentPath: 'test_collection/test_doc',
    );

    _showDiagSnackBar(
      ok
          ? (localizeTrEn(
              _lang,
              'REST probe başarılı (Firestore uç noktasına erişilebiliyor).',
              'REST probe success (Firestore endpoint reachable).'))
          : (localizeTrEn(_lang, 'REST probe başarısız (loglara bakın).',
              'REST probe failed (check logs).')),
      backgroundColor: ok ? Colors.green : Colors.red,
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> _runFirestoreWriteWithRestFallback({
    required String label,
    required Future<void> Function() sdkWrite,
    required String documentPath,
    required Map<String, dynamic> restData,
    bool merge = true,
  }) async {
    try {
      await _runFirestoreWriteWithRetry(
        sdkWrite,
        label: label,
        popCriticalOnFinalFailure: false,
      );
      return;
    } catch (e, st) {
      final bool retryable = _isRetryableFirestoreError(e);
      if (!retryable) {
        _logFirebaseDiagnostic(
          'firestore_write',
          '$label failed with non-retryable error; REST fallback skipped',
          error: e,
          stackTrace: st,
          isError: true,
          popCritical: true,
        );
        Error.throwWithStackTrace(e, st);
      }

      _logFirebaseDiagnostic(
        'firestore_write',
        '$label sdk path exhausted; trying REST fallback path=$documentPath',
        error: e,
        stackTrace: st,
        isError: true,
      );

      final User? user =
          FirebaseAuth.instance.currentUser ?? await _ensureFirestoreAuthUser();
      if (user == null) {
        _logFirebaseDiagnostic(
          'firestore_write',
          '$label REST fallback blocked: auth unavailable',
          isError: true,
          popCritical: true,
        );
        Error.throwWithStackTrace(e, st);
      }

      final bool restOk = await _writeFirestoreViaRest(
        user: user,
        documentPath: documentPath,
        data: restData,
        merge: merge,
        reason: label,
      );
      if (restOk) {
        _logFirebaseDiagnostic(
          'firestore_write',
          '$label recovered via REST fallback path=$documentPath',
        );
        return;
      }

      _logFirebaseDiagnostic(
        'firestore_write',
        '$label REST fallback failed after sdk timeout',
        isError: true,
        popCritical: true,
      );
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> _runFirebaseAuthDiagnosticProbe() async {
    _logFirebaseDiagnostic('auth_probe', 'manual probe started');
    final User? user = await _ensureFirestoreAuthUser();
    if (user == null) {
      _logFirebaseDiagnostic(
        'auth_probe',
        'probe failed: ensureFirestoreAuthUser returned null',
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firebase Auth probe başarısız.',
            'Firebase Auth probe failed.'),
        backgroundColor: Colors.red,
      );
      return;
    }
    try {
      final IdTokenResult tokenResult =
          await user.getIdTokenResult(true).timeout(_firestoreAuthTimeout);
      _logFirebaseDiagnostic(
        'auth_probe',
        'probe success uid=${user.uid} anon=${user.isAnonymous} tokenExp=${tokenResult.expirationTime?.toIso8601String() ?? '(null)'}',
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firebase Auth probe başarılı.',
            'Firebase Auth probe success.'),
        backgroundColor: Colors.green,
      );
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'auth_probe',
        'token fetch failed',
        error: e,
        stackTrace: st,
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firebase token probe başarısız.',
            'Firebase token probe failed.'),
        backgroundColor: Colors.red,
      );
    }
  }

  void _showCriticalDiagnosticOverlay({
    required String title,
    required String details,
  }) {
    if (!_userFacingFirebaseDiagnosticsEnabled) return;
    if (!mounted) return;
    final String cleanTitle = title.trim().isEmpty ? 'ERROR' : title.trim();
    final String cleanDetails =
        details.trim().isEmpty ? '(empty)' : details.trim();
    final String fingerprint = '$cleanTitle|$cleanDetails';
    final DateTime now = DateTime.now();

    if (_criticalDiagnosticVisible) return;
    if (_lastCriticalDiagnosticFingerprint == fingerprint &&
        _lastCriticalDiagnosticAt != null &&
        now.difference(_lastCriticalDiagnosticAt!) <
            const Duration(seconds: 7)) {
      return;
    }

    _lastCriticalDiagnosticFingerprint = fingerprint;
    _lastCriticalDiagnosticAt = now;
    _criticalDiagnosticVisible = true;

    unawaited(showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'critical_diagnostic',
      barrierColor: Colors.black.withOpacity(0.75),
      pageBuilder: (ctx, _, __) {
        return SafeArea(
          child: Material(
            color: Colors.red.shade900.withOpacity(0.95),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    localizeTrEn(_lang, 'KRİTİK TEŞHİS HATASI',
                        'CRITICAL DIAGNOSTIC ERROR'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cleanTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          cleanDetails,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 15,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: cleanDetails),
                          ),
                          child: Text(localizeTrEn(_lang, 'KOPYALA', 'COPY')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Future.delayed(const Duration(milliseconds: 120),
                                () {
                              if (!mounted) return;
                              unawaited(
                                  _openDiagnosticsConsole(initialTabIndex: 0));
                            });
                          },
                          child: Text(
                              localizeTrEn(_lang, 'LOG EKRANI', 'OPEN LOGS')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        localizeTrEn(_lang, 'KAPAT', 'CLOSE'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _criticalDiagnosticVisible = false;
    }));
  }

  Future<void> _openDiagnosticsConsole({int initialTabIndex = 0}) async {
    if (!mounted) return;
    final String langCode = _lang;
    final bool canRunWriteTest =
        kDebugMode || _isAdminUser || _forceFirestoreTest;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog.fullscreen(
        child: DefaultTabController(
          length: 2,
          initialIndex: initialTabIndex.clamp(0, 1),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                localizeTrEn(
                  langCode,
                  'Firebase + Satın Alma Logları',
                  'Firebase + Purchase Logs',
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              bottom: TabBar(
                tabs: [
                  Tab(text: localizeTrEn(langCode, 'Firebase', 'Firebase')),
                  Tab(text: localizeTrEn(langCode, 'Store', 'Store')),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: localizeTrEn(langCode, 'Tümünü kopyala', 'Copy all'),
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: _buildCombinedDiagnosticDump()),
                  ),
                  icon: const Icon(Icons.copy_all_rounded),
                ),
                IconButton(
                  tooltip: localizeTrEn(langCode, 'Kapat', 'Close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white10
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    _buildFirebaseStatusSummary(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _runFirebaseAuthDiagnosticProbe,
                                    icon: const Icon(
                                        Icons.verified_user_outlined),
                                    label: Text(
                                      localizeTrEn(
                                          langCode, 'Auth Probe', 'Auth Probe'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: canRunWriteTest
                                        ? _testFirestoreWrite
                                        : null,
                                    icon:
                                        const Icon(Icons.cloud_upload_outlined),
                                    label: Text(
                                      localizeTrEn(
                                          langCode, 'Write Test', 'Write Test'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: localizeTrEn(
                                    langCode,
                                    'Firebase loglarini temizle',
                                    'Clear Firebase logs',
                                  ),
                                  onPressed: () {
                                    _firebaseDiagnosticEvents.value =
                                        <String>[];
                                  },
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _runFirestoreRestDiagnosticProbe,
                                icon: const Icon(Icons.http_rounded),
                                label: Text(
                                  localizeTrEn(
                                      langCode, 'REST Probe', 'REST Probe'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ValueListenableBuilder<List<String>>(
                              valueListenable: _firebaseDiagnosticEvents,
                              builder: (_, logs, __) {
                                if (logs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      localizeTrEn(
                                        langCode,
                                        'Firebase logu henuz yok.',
                                        'No Firebase logs yet.',
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: logs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, index) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.white10
                                            : Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: SelectableText(
                                        logs[index],
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _restorePurchasesPressed,
                                    icon: const Icon(Icons.restore_rounded),
                                    label: Text(
                                      localizeTrEn(langCode, 'Restore Test',
                                          'Restore Test'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (PurchasesService
                                          .instance.isPremium.value) {
                                        _showDiagSnackBar(
                                          _t('premium_already_active'),
                                          backgroundColor:
                                              Colors.blueGrey.shade900,
                                        );
                                        return;
                                      }
                                      await PurchasesService.instance.configure(
                                        androidApiKey: _revenueCatAndroidApiKey,
                                        iosApiKey: _revenueCatIosApiKey,
                                      );
                                      if (!mounted) return;
                                      final PurchaseAttemptResult result =
                                          await PurchasesService.instance
                                              .makePurchase();
                                      if (!mounted) return;
                                      if (result.cancelled) {
                                        _showDiagSnackBar(
                                          localizeTrEn(
                                            langCode,
                                            'Satın alım iptal edildi.',
                                            'Purchase cancelled.',
                                          ),
                                          backgroundColor:
                                              Colors.blueGrey.shade900,
                                        );
                                      } else if (result.success) {
                                        _showDiagSnackBar(
                                          localizeTrEn(
                                            langCode,
                                            'Satın alım başarılı.',
                                            'Purchase successful.',
                                          ),
                                          backgroundColor: Colors.green,
                                        );
                                      } else {
                                        _showDiagSnackBar(
                                          localizeTrEn(
                                            langCode,
                                            'Satın alım başarısız.',
                                            'Purchase failed.',
                                          ),
                                          backgroundColor: Colors.red,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.payment_rounded),
                                    label: Text(
                                      localizeTrEn(
                                        langCode,
                                        'Purchase Test',
                                        'Purchase Test',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: localizeTrEn(
                                    langCode,
                                    'Store loglarini temizle',
                                    'Clear store logs',
                                  ),
                                  onPressed: () {
                                    PurchasesService.instance
                                        .clearLastPurchaseError();
                                    PurchasesService.instance
                                        .clearDiagnosticEvents();
                                  },
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ValueListenableBuilder<List<String>>(
                              valueListenable:
                                  PurchasesService.instance.diagnosticEvents,
                              builder: (_, logs, __) {
                                if (logs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      localizeTrEn(
                                        langCode,
                                        'Store logu henuz yok.',
                                        'No store logs yet.',
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: logs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, index) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.white10
                                            : Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: SelectableText(
                                        logs[index],
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPurchaseErrorChanged() {
    final String value =
        PurchasesService.instance.lastPurchaseError.value.trim();
    if (value == _lastObservedPurchaseError) return;
    _lastObservedPurchaseError = value;
    if (value.isEmpty) return;

    _logFirebaseDiagnostic(
      'purchase_error',
      value,
      isError: true,
      popCritical: true,
    );
  }

  bool _isRetryableFirestoreError(Object error) {
    if (error is TimeoutException) return true;

    if (error is FirebaseException) {
      final String code = error.code.toLowerCase().trim();
      if (code == 'permission-denied' || code == 'unauthenticated') {
        return false;
      }
      return code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'aborted' ||
          code == 'internal' ||
          code == 'resource-exhausted';
    }

    final String raw = error.toString().toLowerCase();
    if (raw.contains('permission_denied') ||
        raw.contains('permission-denied') ||
        raw.contains('unauthenticated')) {
      return false;
    }
    return raw.contains('timeout') ||
        raw.contains('future not completed') ||
        raw.contains('deadline_exceeded') ||
        raw.contains('deadline-exceeded') ||
        raw.contains('unavailable') ||
        raw.contains('socketexception') ||
        raw.contains('connection');
  }

  Future<void> _safeResetFirestoreNetwork(String reason) async {
    _logFirebaseDiagnostic('firestore_network', 'reset start: $reason');
    try {
      await FirebaseFirestore.instance
          .disableNetwork()
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      _logFirebaseDiagnostic(
        'firestore_network',
        'disableNetwork failed',
        error: e,
        isError: true,
      );
    }
    await Future.delayed(const Duration(milliseconds: 280));
    try {
      await FirebaseFirestore.instance
          .enableNetwork()
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      _logFirebaseDiagnostic(
        'firestore_network',
        'enableNetwork failed',
        error: e,
        isError: true,
      );
    }
    _logFirebaseDiagnostic('firestore_network', 'reset complete: $reason');
  }

  Future<User?> _ensureFirestoreAuthUser() async {
    _logFirebaseDiagnostic('firestore_auth', 'ensure auth user start');
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      try {
        final UserCredential cred = await FirebaseAuth.instance
            .signInAnonymously()
            .timeout(_firestoreAuthTimeout);
        currentUser = cred.user;
        _logFirebaseDiagnostic(
          'firestore_auth',
          'anonymous sign-in success uid=${currentUser?.uid ?? '(null)'}',
        );
      } catch (e, st) {
        _logFirebaseDiagnostic(
          'firestore_auth',
          'anonymous sign-in failed',
          error: e,
          stackTrace: st,
          isError: true,
          popCritical: true,
        );
        return null;
      }
    } else {
      _logFirebaseDiagnostic(
        'firestore_auth',
        'existing auth user uid=${currentUser.uid}',
      );
    }

    if (currentUser == null) {
      _logFirebaseDiagnostic(
        'firestore_auth',
        'auth user is null after sign-in',
        isError: true,
        popCritical: true,
      );
      return null;
    }

    try {
      await currentUser.getIdToken(true).timeout(_firestoreAuthTimeout);
      _logFirebaseDiagnostic(
        'firestore_auth',
        'token refresh success uid=${currentUser.uid}',
      );
      return currentUser;
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_auth',
        'token refresh failed; attempting re-auth',
        error: e,
        stackTrace: st,
        isError: true,
      );
      try {
        final UserCredential cred = await FirebaseAuth.instance
            .signInAnonymously()
            .timeout(_firestoreAuthTimeout);
        currentUser = cred.user;
      } catch (authErr, authStack) {
        _logFirebaseDiagnostic(
          'firestore_auth',
          're-auth failed',
          error: authErr,
          stackTrace: authStack,
          isError: true,
          popCritical: true,
        );
        return null;
      }
      if (currentUser == null) {
        _logFirebaseDiagnostic(
          'firestore_auth',
          're-auth returned null user',
          isError: true,
          popCritical: true,
        );
        return null;
      }
      try {
        await currentUser.getIdToken(true).timeout(_firestoreAuthTimeout);
      } catch (_) {}
      _logFirebaseDiagnostic(
        'firestore_auth',
        're-auth success uid=${currentUser.uid}',
      );
      return currentUser;
    }
  }

  Future<void> _runFirestoreWriteWithRetry(
    Future<void> Function() op, {
    required String label,
    int maxAttempts = 3,
    bool popCriticalOnFinalFailure = true,
  }) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await op().timeout(_firestoreTimeout);
        _logFirebaseDiagnostic(
          'firestore_write',
          '$label success attempt=$attempt',
        );
        return;
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        final bool retryable = _isRetryableFirestoreError(e);
        _logFirebaseDiagnostic(
          'firestore_write',
          '$label failed attempt=$attempt/$maxAttempts retryable=$retryable',
          error: e,
          stackTrace: st,
          isError: true,
          popCritical: (!retryable || attempt >= maxAttempts) &&
              popCriticalOnFinalFailure,
        );
        if (!retryable || attempt >= maxAttempts) break;
        await _safeResetFirestoreNetwork('$label attempt $attempt');
        await Future.delayed(Duration(milliseconds: 240 * attempt));
      }
    }

    if (lastError != null && lastStackTrace != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace);
    }
    throw Exception('firestore_write_failed:$label');
  }

  Future<void> _testFirestoreWrite() async {
    _logFirebaseDiagnostic('firestore_test', 'manual write test started');

    final User? currentUser = await _ensureFirestoreAuthUser();
    if (currentUser == null) {
      _logFirebaseDiagnostic(
        'firestore_test',
        'aborted: no auth user',
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firebase Auth hatası: kullanıcı doğrulanamadı.',
            'Firebase auth error: user verification failed.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('test_collection')
          .doc('test_doc');
      final DateTime nowUtc = DateTime.now().toUtc();
      final String nowTr = _nowTurkeyIso8601();
      final Map<String, dynamic> sdkPayload = <String, dynamic>{
        'test_field': 'Hello Firestore!',
        'timestamp': nowTr,
        'random': nowUtc.millisecondsSinceEpoch,
        'user_uid': currentUser.uid,
      };
      final Map<String, dynamic> restPayload = <String, dynamic>{
        'test_field': 'Hello Firestore!',
        'timestamp': nowTr,
        'random': nowUtc.millisecondsSinceEpoch,
        'user_uid': currentUser.uid,
      };

      await _runFirestoreWriteWithRestFallback(
        label: 'test_collection/test_doc set',
        sdkWrite: () => docRef.set(sdkPayload),
        documentPath: 'test_collection/test_doc',
        restData: restPayload,
        merge: false,
      );

      try {
        final snapshot = await docRef
            .get(const GetOptions(source: Source.server))
            .timeout(_firestoreTimeout);
        _logFirebaseDiagnostic(
          'firestore_test',
          'server read success data=${snapshot.data()}',
        );
      } catch (readError, readStackTrace) {
        _logFirebaseDiagnostic(
          'firestore_test',
          'write succeeded but server read check failed (often rule-related)',
          error: readError,
          stackTrace: readStackTrace,
          isError: true,
        );
      }

      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firestore test yazma başarılı.',
            'Firestore test write successful.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_test',
        'write test failed',
        error: e,
        stackTrace: st,
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(
            _lang, 'Firestore test hatası oluştu.', 'Firestore test failed.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      try {
        unawaited(FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'testFirestoreWrite',
          fatal: false,
        ));
      } catch (_) {}
    }
  }

  Future<void> _incrementFirestoreCounter(String counterName) async {
    _logFirebaseDiagnostic(
      'firestore_counter',
      'counter write start name=$counterName',
    );
    final User? currentUser = await _ensureFirestoreAuthUser();
    if (currentUser == null) {
      _logFirebaseDiagnostic(
        'firestore_counter',
        'counter write blocked: no auth user',
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firestore auth hatası: kullanıcı doğrulanamadı.',
            'Firestore auth error: user verification failed.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    try {
      final String today = DateTime.now().toString().substring(0, 10);
      final String nowTr = _nowTurkeyIso8601();
      await _runFirestoreWriteWithRetry(
        () => FirebaseFirestore.instance
            .collection('daily_stats')
            .doc(today)
            .set({
          counterName: FieldValue.increment(1),
          'last_updated_at': nowTr,
        }, SetOptions(merge: true)),
        label: 'daily_stats/$today set($counterName)',
      );
      _logFirebaseDiagnostic(
        'firestore_counter',
        'counter write success name=$counterName uid=${currentUser.uid}',
      );
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_counter',
        'counter write failed name=$counterName',
        error: e,
        stackTrace: st,
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firestore sayaç yazma hatası.',
            'Firestore counter write failed.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      try {
        unawaited(FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'incrementFirestoreCounter:$counterName',
          fatal: false,
        ));
      } catch (_) {}
    }
  }

  String _igUserDocIdFromUsername(String username) {
    final String normalized = _normalizeUserKey(username);
    if (normalized == '.' || normalized == '..') return '';
    return normalized;
  }

  Future<void> _forceWriteIgUserDoc({
    required String username,
  }) async {
    final String cleanUsername = username.trim();
    final String userDocId = _igUserDocIdFromUsername(cleanUsername);
    if (userDocId.isEmpty || userDocId == 'null') {
      _logFirebaseDiagnostic(
        'ig_users_write',
        'skipped: invalid username',
        isError: true,
      );
      return;
    }

    final User? currentUser = await _ensureFirestoreAuthUser();
    if (currentUser == null) {
      _logFirebaseDiagnostic(
        'ig_users_write',
        'blocked: no auth user for ig_users/$userDocId',
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firestore auth yok: ig_users yazılamadı.',
            'Firestore auth missing: ig_users write blocked.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    String version = '15.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      final String v = info.version.trim();
      if (v.isNotEmpty) version = v;
    } catch (_) {}

    try {
      final String nowTr = _nowTurkeyIso8601();
      _logFirebaseDiagnostic(
        'ig_users_write',
        'write start doc=ig_users/$userDocId authUid=${currentUser.uid} username=$cleanUsername',
      );
      final docRef =
          FirebaseFirestore.instance.collection('ig_users').doc(userDocId);
      final Map<String, dynamic> sdkPayload = <String, dynamic>{
        'username': cleanUsername,
        'is_premium': PurchasesService.instance.isPremium.value,
        'version': version,
        'last_seen': nowTr,
        'userId': FieldValue.delete(),
        'platform': FieldValue.delete(),
        'os_version': FieldValue.delete(),
        'app_build': FieldValue.delete(),
        'app_package': FieldValue.delete(),
        'country_source': FieldValue.delete(),
        'updated_at': FieldValue.delete(),
        'last_session_id': FieldValue.delete(),
        'user_id': FieldValue.delete(),
        'last_seen_at': FieldValue.delete(),
        'device_manufacturer': FieldValue.delete(),
        'last_analysis_duration_ms': FieldValue.delete(),
        'last_analysis_followers_count': FieldValue.delete(),
        'last_analysis_following_count': FieldValue.delete(),
      };
      final Map<String, dynamic> restPayload = <String, dynamic>{
        'username': cleanUsername,
        'is_premium': PurchasesService.instance.isPremium.value,
        'version': version,
        'last_seen': nowTr,
      };
      await _runFirestoreWriteWithRestFallback(
        label: 'ig_users/$userDocId set',
        sdkWrite: () => docRef.set(sdkPayload, SetOptions(merge: true)),
        documentPath: 'ig_users/$userDocId',
        restData: restPayload,
        merge: true,
      );
      try {
        await docRef
            .get(const GetOptions(source: Source.server))
            .timeout(_firestoreTimeout);
      } catch (_) {}
      _logFirebaseDiagnostic(
        'ig_users_write',
        'write success doc=ig_users/$userDocId',
      );
      try {
        FirebaseCrashlytics.instance.log('ForceWrite ig_users/$userDocId ok');
      } catch (_) {}
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'ig_users_write',
        'write failed doc=ig_users/$userDocId',
        error: e,
        stackTrace: st,
        isError: true,
        popCritical: true,
      );
      _showDiagSnackBar(
        localizeTrEn(_lang, 'Firestore ig_users yazma hatası.',
            'Firestore ig_users write failed.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      try {
        unawaited(FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'forceWriteIgUserDoc:$userDocId',
          fatal: false,
        ));
      } catch (_) {}
    }
  }

  Future<void> _showRemainingDialog() async {
    if (_adsDisabled) return;
    if (!mounted) return;
    final remaining = _remainingToNextAnalysis;
    if (remaining == null) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(_t('next_analysis')),
                  content: Text(_t('next_analysis_ready')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_t('cancel')))
                  ]));
    } else {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(_t('please_wait')),
                  content: Text(_t(
                      'remaining_time', {'time': _formatDuration(remaining)})),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_t('cancel')))
                  ]));
    }
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('is_dark_mode', isDarkMode);
    });
  }

  Future<void> _clearCache() async {
    if (_isClearingData) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(_t('clear_data_title'),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: Text(_t('clear_data_content'),
            style:
                TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('delete'),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isClearingData = true);
    try {
      await _logout();
    } finally {
      if (mounted) setState(() => _isClearingData = false);
    }
  }

  Future<String?> _readCookieFromWebViewStore() async {
    try {
      final String? cookieString = await _cookieChannel.invokeMethod<String>(
          'getCookies', {'url': 'https://www.instagram.com/'});
      final String cookie = (cookieString ?? '').trim();
      if (cookie.isEmpty) return null;
      final String sessionId = _extractCookieValue(cookie, 'sessionid').trim();
      if (sessionId.isEmpty) return null;
      return cookie;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _refreshSessionCookieFromWebViewStore(
      {bool updateUserId = true}) async {
    if (!isLoggedIn) return false;

    final String? cookie = await _readCookieFromWebViewStore();
    if (cookie == null) return false;

    final String previous = (savedCookie ?? '').trim();
    if (previous.isNotEmpty && previous == cookie) return false;

    String? updatedUserId = savedUserId;
    if (updateUserId) {
      final String fromCookie =
          _extractCookieValue(cookie, 'ds_user_id').trim();
      if (fromCookie.isNotEmpty) {
        updatedUserId = fromCookie;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_cookie', cookie);
    if (updateUserId && (updatedUserId ?? '').trim().isNotEmpty) {
      await prefs.setString('session_user_id', updatedUserId!.trim());
    }

    if (mounted) {
      setState(() {
        savedCookie = cookie;
        if (updateUserId) savedUserId = updatedUserId;
      });
    } else {
      savedCookie = cookie;
      if (updateUserId) savedUserId = updatedUserId;
    }
    return true;
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? cookie = prefs.getString('session_cookie');
    String? userId = prefs.getString('session_user_id');
    String? username = prefs.getString('session_username');
    String? ua = prefs.getString('session_user_agent');
    if (mounted) {
      final bool hasPref = prefs.containsKey('is_dark_mode');
      final bool systemDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      setState(() {
        isDarkMode = hasPref
            ? (prefs.getBool('is_dark_mode') ?? systemDark)
            : systemDark;
      });
    }
    if (cookie != null && userId != null) {
      final String fallback = localizeTrEn(_lang, 'Kullanıcı', 'User');
      if (mounted) {
        setState(() {
          isLoggedIn = true;
          _hasAnalyzed = false;
          savedCookie = cookie;
          savedUserId = userId;
          currentUsername = username ?? fallback;
          savedUserAgent = ua;
          _syncCountsForUi();
        });
      } else {
        isLoggedIn = true;
        _hasAnalyzed = false;
        savedCookie = cookie;
        savedUserId = userId;
        currentUsername = username ?? fallback;
        savedUserAgent = ua;
      }
      _logFirebaseDiagnostic(
        'session',
        'auto-login restored userId=$userId username=$currentUsername',
      );
      unawaited(TelemetryService.instance.recordLogin(
        userId: userId,
        username: currentUsername,
        isPremium: PurchasesService.instance.isPremium.value,
      ));
      unawaited(_incrementFirestoreCounter('login_count'));
      unawaited(_forceWriteIgUserDoc(username: currentUsername));
      await _refreshSessionCookieFromWebViewStore();
      await _refreshUsernameForBanCheckIfNeeded();
      _applyUserFlags();
      if (_isBanned) return;
      _loadStoredData();
      _loadStoryTray();
    }
  }

  Future<void> _logout() async {
    final bool currentDark = isDarkMode;

    _cancelCountdown();
    _stopStoryAutoScroll();

    if (mounted) {
      setState(() {
        isLoggedIn = false;
        _isBanned = false;
        _hasAnalyzed = false;
        currentUsername = "";
        savedCookie = null;
        savedUserId = null;
        savedUserAgent = null;
        followersMap = {};
        followingMap = {};
        nonFollowersMap = {};
        unfollowersMap = {};
        leftFollowingMap = {};
        newFollowersMap = {};
        _syncCountsForUi();
      });
    } else {
      isLoggedIn = false;
      _isBanned = false;
      _hasAnalyzed = false;
      currentUsername = "";
      savedCookie = null;
      savedUserId = null;
      savedUserAgent = null;
      followersMap = {};
      followingMap = {};
      nonFollowersMap = {};
      unfollowersMap = {};
      leftFollowingMap = {};
      newFollowersMap = {};
    }

    try {
      await TelemetryService.instance
          .recordLogout()
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('is_dark_mode', currentDark);
      await prefs.setBool('is_terms_accepted', true);
    } catch (_) {}

    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {}
  }

  Future<void> _updatePrivacyOptionsRequirement() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      final required = status == PrivacyOptionsRequirementStatus.required;
      if (mounted) {
        setState(() {
          _privacyOptionsRequired = required;
        });
      } else {
        _privacyOptionsRequired = required;
      }
    } catch (_) {}
  }

  Future<void> _showPrivacyOptionsForm() async {
    ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint("${formError.errorCode}: ${formError.message}");
      }
    });
  }

  Future<void> _maybeRequestATT() async {
    if (!Platform.isIOS) return;
    await _waitForUmpConsentFlow();
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {}
  }

  Future<void> _revokeConsentAndShowForm() async {
    if (mounted) {
      final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor:
                    isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                title: Text(_t('withdraw_consent_confirm_title'),
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87)),
                content: Text(_t('withdraw_consent_confirm_body'),
                    style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(_t('withdraw_consent_confirm_no'))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(_t('withdraw_consent_confirm_yes'),
                          style: const TextStyle(color: Colors.red)))
                ],
              ));
      if (confirmed != true) return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizeTrEn(
            _lang, 'Rıza formu açılıyor...', 'Opening consent form...')),
        duration: const Duration(seconds: 2),
      ));
    }
    try {
      await ConsentInformation.instance.reset();
    } catch (_) {}
    final params = ConsentRequestParameters();
    final Completer<void> c = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? _) {
            if (!c.isCompleted) c.complete();
          });
        } else {
          if (!c.isCompleted) c.complete();
        }
      },
      (FormError _) {
        if (!c.isCompleted) c.complete();
      },
    );
    try {
      await c.future;
    } catch (_) {}
    _reloadBannerForConsentChange();
    await _updatePrivacyOptionsRequirement();
    if (!mounted) return;
    bool ok = false;
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      ok = status == ConsentStatus.obtained ||
          status == ConsentStatus.notRequired;
    } catch (_) {
      ok = false;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (localizeTrEn(_lang, 'Rıza tercihiniz güncellendi.',
              'Your consent preference was updated.'))
          : (localizeTrEn(
              _lang,
              'Rıza güncellenemedi. Lütfen tekrar deneyin.',
              'Consent update failed. Please try again.'))),
      backgroundColor: ok ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _reloadBannerForConsentChange() async {
    try {
      if (_bannerAd != null) {
        _bannerAd!.dispose();
      }
    } catch (_) {}
    _bannerAd = null;
    _isAdLoaded = false;
    _bannerAdError = null;
    _googleAdWarning = null;
    if (mounted) {
      setState(() {});
    }
    _maybeLoadBannerAfterConsent();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBanned) {
      return Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF000000) : const Color(0xFFF4F7F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 72, color: Colors.redAccent.shade200),
                const SizedBox(height: 16),
                Text(
                  localizeTrEn(_lang, 'Hesabınız engellendi',
                      'Your account is blocked'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  localizeTrEn(_lang, 'Bu hesap için erişim kısıtlandı.',
                      'Access is restricted for this account.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.blueGrey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(localizeTrEn(_lang, 'KAPAT', 'CLOSE')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    Color bgColor =
        isDarkMode ? const Color(0xFF000000) : const Color(0xFFF4F7F9);
    Color cardColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color primaryColor = isDarkMode ? Colors.blueAccent : Colors.blueGrey;
    Color headerColor = isDarkMode ? Colors.white : primaryColor;

    final ThemeData themed = ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueGrey,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      snackBarTheme: _appSnackBarTheme(isDark: isDarkMode),
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: isDarkMode ? Colors.white : Colors.black87,
            displayColor: isDarkMode ? Colors.white : Colors.black87,
          ),
    );

    return Theme(
        data: themed,
        child: Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                PopupMenuButton<String>(
                                  tooltip: 'Language',
                                  onSelected: (String code) {
                                    unawaited(_setLanguage(code));
                                  },
                                  itemBuilder: (context) {
                                    return _supportedLanguageCodes
                                        .map((String code) {
                                      final bool selected = code == _lang;
                                      final String nativeName =
                                          _languageNativeNames[code] ??
                                              code.toUpperCase();
                                      final String flag = _languageFlagFor(code);
                                      return PopupMenuItem<String>(
                                        value: code,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 28,
                                              child: Text(
                                                flag,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                nativeName,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: selected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            if (selected) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.check, size: 16),
                                            ],
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                  child: Tooltip(
                                    message:
                                        '${_languageFlagFor(_lang)} ${_languageNativeNames[_lang] ?? _lang.toUpperCase()}',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _languageFlagFor(_lang),
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _compactLanguageName(_lang),
                                            style: TextStyle(
                                              color: headerColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (_privacyOptionsRequired)
                                  IconButton(
                                    icon: Icon(Icons.privacy_tip_outlined,
                                        color: headerColor),
                                    onPressed: _showPrivacyOptionsForm,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    isDarkMode
                                        ? Icons.light_mode
                                        : Icons.dark_mode,
                                    color: headerColor,
                                  ),
                                  onPressed: _toggleDarkMode,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: (isProcessing || _isClearingData)
                                      ? null
                                      : _clearCache,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('VERDICT',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 26,
                                        color: headerColor,
                                        letterSpacing: 3.0)),
                                Text(_t('tagline'),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 8,
                                        color: headerColor.withOpacity(0.6))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!_adsDisabled)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.1))),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isAdLoaded && _bannerAd != null)
                                    SizedBox(
                                      width: _bannerAd!.size.width.toDouble(),
                                      height: _bannerAd!.size.height.toDouble(),
                                      child: AdWidget(ad: _bannerAd!),
                                    )
                                  else if (_currentGoogleAdWarningText()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 18,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _t('google_ad_warning', {
                                                'reason':
                                                    _currentGoogleAdWarningText()
                                              }),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? Colors.orange.shade200
                                                    : Colors.orange.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    const SizedBox(
                                        height: 50,
                                        child: Center(
                                            child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))))
                                ]),
                          ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 560),
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: Column(
                        children: [
                          if (isLoggedIn && _isAdminUser) ...[
                            _buildInfoBox(Icons.admin_panel_settings,
                                _t('admin_active_note'), primaryColor),
                            const SizedBox(height: 10),
                          ],
                          if (_announcementText.trim().isNotEmpty) ...[
                            _buildInfoBox(Icons.info_outline, _announcementText,
                                primaryColor),
                            const SizedBox(height: 10),
                          ],
                          if (_isPremium) ...[
                            _buildInfoBox(
                                Icons.workspace_premium_rounded,
                                _t('premium_welcome_box'),
                                Colors.amber.shade700),
                            const SizedBox(height: 10),
                          ],
                          _buildInfoBox(Icons.info_outline, _t('free_app_note'),
                              primaryColor),
                          const SizedBox(height: 10),
                          if (!isLoggedIn)
                            _buildInfoBox(Icons.lock_outline,
                                _t('login_prompt'), Colors.redAccent)
                          else
                            _buildInfoBox(
                                Icons.verified_user,
                                _t('welcome', {'username': currentUsername}),
                                Colors.green),
                          if (_remoteFlagsLoaded && _watchStoriesEnabled) ...[
                            const SizedBox(height: 12),
                            _buildStorySection(),
                            const SizedBox(height: 18),
                          ],
                          if (isProcessing)
                            Container(
                              height: 368,
                              alignment: Alignment.center,
                              child: ModernLoader(
                                text: _isRewardedLoading
                                    ? _t('loading_ad')
                                    : (_progressValue >= 0.97
                                        ? _t('processing_data')
                                        : _t('fetching_data')),
                                isDark: isDarkMode,
                                progress: _progressValue,
                                lang: _lang,
                              ),
                            )
                          else
                            Column(
                              children: [
                                _buildGrid(cardColor, textColor),
                              ],
                            ),
                          SizedBox(height: isProcessing ? 10 : 18),
                          if (isProcessing) ...[
                            Text(_t('analysis_secure'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isDarkMode
                                        ? Colors.grey
                                        : Colors.blueGrey,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 30),
                          ] else ...[
                            Column(children: [
                              _buildAnalysisReadyNowAboveButton(),
                              _buildNextAnalysisInfo(),
                              const SizedBox(height: 10),
                              _buildMainButton(isDarkMode),
                              const SizedBox(height: 8),
                              Text(_t('analysis_secure'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isDarkMode
                                          ? Colors.grey
                                          : Colors.blueGrey,
                                      fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(height: 30),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildRestorePurchasesMiniButton({
    required Color cardBg,
    required Color txtColor,
  }) {
    final bool disabled = isProcessing;
    final Color accent = Colors.blueGrey;

    return AbsorbPointer(
      absorbing: disabled,
      child: Opacity(
        opacity: disabled ? 0.55 : 1.0,
        child: GestureDetector(
          onTap: _restorePurchasesPressed,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withOpacity(isDarkMode ? 0.20 : 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: LayoutBuilder(builder: (context, constraints) {
              const double iconSize = 16;
              const double gap = 6;
              final double textWidth =
                  max(0.0, constraints.maxWidth - (iconSize + gap));

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restore_rounded, size: iconSize, color: accent),
                  const SizedBox(width: gap),
                  SizedBox(
                    width: textWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        _t('restore_purchases'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: txtColor.withOpacity(0.72),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(Color cardColor, Color textColor) {
    return LayoutBuilder(builder: (context, constraints) {
      double cardWidth = (constraints.maxWidth - 16) / 2;
      cardWidth = cardWidth * 0.90;
      double cardHeight = cardWidth * 0.92;
      const double miniButtonHeight = 34;
      const double miniGap = 8;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard('followers', followersCount,
                  Colors.blueAccent, Icons.groups_3, cardColor, textColor)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard('following', followingCount, Colors.teal,
                  Icons.person_add_alt_1, cardColor, textColor)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard('new_followers', newCount, Colors.green,
                  Icons.person_add_rounded, cardColor, textColor)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard(
                  'non_followers',
                  nonFollowersCount,
                  Colors.orange.shade800,
                  Icons.person_search,
                  cardColor,
                  textColor)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard(
                  'left_followers',
                  leftCount,
                  Colors.deepOrangeAccent,
                  Icons.trending_down,
                  cardColor,
                  textColor)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard(
                  'left_following',
                  leftFollowingCount,
                  Colors.deepOrangeAccent,
                  Icons.person_off,
                  cardColor,
                  textColor)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard('rate_us', "", Colors.amber,
                  Icons.star_rounded, cardColor, textColor,
                  showCount: false)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard('contact_us', "", const Color(0xFFC13584),
                  Icons.chat_bubble_rounded, cardColor, textColor,
                  showCount: false)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard(
                  'remove_ads_and_limits',
                  "",
                  const Color(0xFF833AB4),
                  Icons.ad_units_rounded,
                  cardColor,
                  textColor,
                  showCount: false,
                  iconWidget: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.ad_units_rounded,
                            color: Color(0xFF833AB4),
                            size: 35,
                          ),
                        ),
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: max(0.0, cardHeight - (miniButtonHeight + miniGap)),
                    child: _buildBigCard('legal_warning', "", Colors.blueGrey,
                        Icons.info_outline, cardColor, textColor,
                        showCount: false),
                  ),
                  SizedBox(height: miniGap),
                  SizedBox(
                    height: miniButtonHeight,
                    child: _buildRestorePurchasesMiniButton(
                      cardBg: cardColor,
                      txtColor: textColor,
                    ),
                  ),
                ],
              )),
        ],
      );
    });
  }

  Widget _buildBigCard(String titleKey, String count, Color color,
      IconData icon, Color cardBg, Color txtColor,
      {bool showCount = true, IconData? footerIcon, Widget? iconWidget}) {
    final String title = _t(titleKey, {'username': currentUsername});
    int badgeCount = badges[titleKey] ?? 0;
    final Widget iconNode = iconWidget ?? Icon(icon, color: color, size: 35);

    return GestureDetector(
      onTapDown: (details) {
        if (titleKey == 'legal_warning') _startLegalHoldTimer();
      },
      onTapUp: (_) {
        if (titleKey == 'legal_warning') _cancelLegalHoldTimer();
      },
      onTapCancel: () {
        if (titleKey == 'legal_warning') _cancelLegalHoldTimer();
      },
      onTap: () async {
        if (titleKey == 'legal_warning') {
          await _showPrivacyPolicyDialog();
        } else if (titleKey == 'rate_us') {
          await _launchRateUrl();
        } else if (titleKey == 'contact_us') {
          try {
            final Uri url = Uri.parse('https://instagram.com/grkmcomert');
            final bool ok = await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(localizeTrEn(
                    _lang, 'Link açılamadı.', 'Could not open the link.')),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ));
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(localizeTrEn(
                    _lang, 'Link açılamadı.', 'Could not open the link.')),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ));
            }
          }
        } else if (titleKey ==
            'remove_ads_and_limits') {
          _logFirebaseDiagnostic(
              'purchase', 'purchase flow started from card tap');
          if (PurchasesService.instance.isPremium.value) {
            _logFirebaseDiagnostic(
                'purchase', 'purchase skipped: premium already active');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_t('premium_already_active')),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.blueGrey.shade900,
              ));
            }
            return;
          }

          await PurchasesService.instance.configure(
            androidApiKey: _revenueCatAndroidApiKey,
            iosApiKey: _revenueCatIosApiKey,
          );
          if (!PurchasesService.instance.isConfigured) {
            _logFirebaseDiagnostic(
              'purchase',
              'purchase blocked: service not configured',
              isError: true,
              popCritical: true,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_t('purchases_not_configured')),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.redAccent,
              ));
            }
            return;
          }

          if (!mounted) return;
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                    backgroundColor:
                        isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localizeTrEn(
                                _lang,
                                'Satın alma başlatılıyor...',
                                'Starting purchase...'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ));

          final PurchaseAttemptResult result =
              await PurchasesService.instance.makePurchase();

          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (!mounted) return;

          if (result.cancelled) {
            _logFirebaseDiagnostic('purchase', 'purchase cancelled by user');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(localizeTrEn(
                  _lang, 'Satın alma iptal edildi.', 'Purchase cancelled.')),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blueGrey.shade900,
            ));
            return;
          }

          if (result.success) {
            _logFirebaseDiagnostic(
                'purchase', 'purchase success: premium active');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(localizeTrEn(
                  _lang,
                  'Premium aktif ✅ Reklamlar ve bekleme süreleri kapatıldı.',
                  'Premium active ✅ Ads and wait times are disabled.')),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green.shade700,
            ));
            return;
          }

          _logFirebaseDiagnostic(
            'purchase',
            'purchase failed resultError=${result.errorMessage ?? '(null)'}',
            isError: true,
            popCritical: true,
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(localizeTrEn(
                _lang,
                'Satın alma başarısız. Lütfen tekrar deneyin.',
                'Purchase failed. Please try again.')),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.redAccent,
          ));
        } else {
          Map<String, String> targetMap = followersMap;
          if (titleKey == 'following') targetMap = followingMap;
          if (titleKey == 'non_followers') targetMap = nonFollowersMap;
          if (titleKey == 'left_followers') targetMap = unfollowersMap;
          if (titleKey == 'left_following') targetMap = leftFollowingMap;
          if (titleKey == 'new_followers') targetMap = newFollowersMap;

          await Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => DetailListPage(
                        title: title,
                        items: targetMap,
                        color: color,
                        isDark: isDarkMode,
                        newItems: newItemsMap[titleKey] ?? {},
                        lang: _lang,
                      )));

          setState(() {
            badges[titleKey] = 0;
            newItemsMap[titleKey]?.clear();
          });
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              iconNode,
              const SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: txtColor.withOpacity(0.6)),
                  textAlign: TextAlign.center),
              if (showCount)
                Text(count,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color)),
              if (!showCount && footerIcon != null)
                Icon(footerIcon, color: Colors.blueGrey, size: 20)
            ]),
          ),
          if (badgeCount != 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: Text(
                  badgeCount > 0 ? "+$badgeCount" : "$badgeCount",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainButton(bool isDark) {
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(
            color: Colors.blueGrey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8))
      ]),
      child: ElevatedButton.icon(
        onPressed: _isClearingData
            ? null
            : (isLoggedIn
                ? () =>
                    unawaited(_refreshData(startProcessingImmediately: true))
                : () async {
                    final dynamic result = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => InstagramApiPage(
                                isDark: isDarkMode, lang: _lang)));
                    if (result is! Map) return;
                    final Map<String, dynamic> payload =
                        result.map((k, v) => MapEntry(k.toString(), v));
                    final String status = (payload['status'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase();
                    final String cookie =
                        (payload['cookie'] ?? '').toString().trim();
                    final String userId =
                        (payload['user_id'] ?? '').toString().trim();
                    final bool hasSessionPayload = cookie.isNotEmpty &&
                        (userId.isNotEmpty ||
                            _extractCookieValue(cookie, 'ds_user_id')
                                .trim()
                                .isNotEmpty);
                    if (status == 'success' || hasSessionPayload) {
                      await _handleLoginSuccess(payload);
                    }
                  }),
        icon: Icon(
            _isClearingData
                ? Icons.hourglass_top_rounded
                : (isLoggedIn ? Icons.refresh : Icons.fingerprint),
            size: 28),
        label: Text(
            _isClearingData
                ? _t('please_wait')
                : (isLoggedIn
                    ? _t('refresh_data')
                    : _t('login_with_instagram')),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 70),
            backgroundColor: isDark ? Colors.white : Colors.blueGrey.shade900,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  void _setProgressValue(double value) {
    if (!mounted) return;
    final double clamped = value.clamp(0.0, 1.0);
    if (clamped <= _progressTarget) return;
    if ((clamped - _progressTarget).abs() < 0.0009) return;

    _progressTarget = clamped;

    if (!isProcessing) {
      _stopProgressPump();
      if (clamped <= _progressValue) return;
      setState(() => _progressValue = clamped);
      return;
    }

    _ensureProgressPump();
  }

  void _stopProgressPump() {
    _progressPumpTimer?.cancel();
    _progressPumpTimer = null;
    _progressFinishEndAt = null;
  }

  void _setAnalysisProgressCap(double cap) {
    _analysisProgressCap = max(_analysisProgressCap, cap);
  }

  void _startAnalysisProgressTimeline() {
    _analysisProgressTimelineStartAt = DateTime.now();
    _analysisProgressTimelineTimer?.cancel();
    _analysisProgressTimelineTimer =
        Timer.periodic(const Duration(milliseconds: 160), (_) {
      if (!mounted || !isProcessing) return;
      final DateTime? start = _analysisProgressTimelineStartAt;
      if (start == null) return;

      final int elapsedMs = DateTime.now().difference(start).inMilliseconds;

      final double cap =
          (_analysisProgressCap <= 0.0 ? 0.92 : _analysisProgressCap)
              .clamp(0.0, 0.985);
      final double ceiling = (cap - 0.010).clamp(0.0, 0.985);
      if (ceiling <= 0) return;

      const double base = 0.08;
      final double k = ceiling < 0.70 ? 1250 : 1700;
      final double t = 1.0 - exp(-elapsedMs / k);
      final double desired = (base + (ceiling - base) * t).clamp(0.0, ceiling);
      _setProgressValue(desired);
    });
  }

  void _stopAnalysisProgressTimeline() {
    _analysisProgressTimelineTimer?.cancel();
    _analysisProgressTimelineTimer = null;
    _analysisProgressTimelineStartAt = null;
    _analysisProgressCap = 0.0;
  }

  void _ensureProgressPump() {
    if (_progressPumpTimer != null) return;
    const int intervalMs = 50;
    _progressPumpTimer =
        Timer.periodic(const Duration(milliseconds: intervalMs), (_) {
      if (!mounted) {
        _stopProgressPump();
        return;
      }
      if (!isProcessing) {
        _stopProgressPump();
        return;
      }

      final double target = _progressTarget.clamp(0.0, 1.0);
      final double current = _progressValue;
      final double remaining = target - current;

      if (remaining <= 0.0009) {
        if ((target - current).abs() > 0.0001) {
          setState(() => _progressValue = target);
        }
        if (target >= 0.999) _progressFinishEndAt = null;
        _stopProgressPump();
        return;
      }

      final DateTime? finishEndAt = _progressFinishEndAt;
      if (finishEndAt != null) {
        final int timeLeftMs =
            finishEndAt.difference(DateTime.now()).inMilliseconds;
        if (timeLeftMs <= 0) {
          setState(() => _progressValue = target);
          _stopProgressPump();
          return;
        }
        final int ticksLeft = max(1, (timeLeftMs / intervalMs).ceil());
        final double step = max(0.0022, remaining / ticksLeft);
        setState(() => _progressValue = (current + step).clamp(0.0, 1.0));
        return;
      }

      final double maxStep = current < 0.60
          ? 0.012
          : (current < 0.85 ? 0.010 : (current < 0.95 ? 0.008 : 0.006));
      const double minStep = 0.0014;
      final double proportional = remaining * 0.16;
      final double step =
          min(remaining, min(maxStep, max(minStep, proportional)));

      setState(() => _progressValue = (current + step).clamp(0.0, 1.0));
    });
  }

  Future<void> _finishProgressUi({
    Duration duration = const Duration(milliseconds: 1100),
    Duration hold = const Duration(milliseconds: 140),
  }) async {
    if (!mounted || !isProcessing) return;

    _progressFinishEndAt = DateTime.now().add(duration);
    _setProgressValue(1.0);

    final DateTime deadline =
        DateTime.now().add(duration + const Duration(milliseconds: 250));
    while (mounted &&
        isProcessing &&
        _progressValue < 0.999 &&
        DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 40));
    }

    if (!mounted || !isProcessing) return;
    if (hold > Duration.zero) await Future.delayed(hold);
  }

  Future<void> _refreshData({bool startProcessingImmediately = false}) async {
    if (_isBanned) return;
    bool processingStarted = false;
    void startProcessingUi() {
      if (processingStarted) return;
      processingStarted = true;
      _stopProgressPump();
      _stopAnalysisProgressTimeline();
      setState(() {
        isProcessing = true;
        _analysisStartedAt = DateTime.now();
        _progressValue = 0.05;
        _progressTarget = 0.05;
      });
      _setAnalysisProgressCap(0.18);
      _startAnalysisProgressTimeline();
    }

    void stopProcessingUi() {
      if (!processingStarted) return;
      _stopProgressPump();
      _stopAnalysisProgressTimeline();
      if (mounted) {
        setState(() {
          isProcessing = false;
          _analysisStartedAt = null;
        });
      } else {
        isProcessing = false;
        _analysisStartedAt = null;
      }
      processingStarted = false;
    }

    final prefs = await SharedPreferences.getInstance();
    await _refreshSessionCookieFromWebViewStore();
    String cookie = (savedCookie ?? '').trim();
    String userId = (savedUserId ?? '').trim();
    _justWatchedReward = false;
    if (userId.isEmpty && cookie.isNotEmpty) {
      userId = _extractCookieValue(cookie, 'ds_user_id').trim();
      if (userId.isNotEmpty) {
        savedUserId = userId;
        await prefs.setString('session_user_id', userId);
      }
    }
    if (cookie.isEmpty || userId.isEmpty || userId == 'null') {
      stopProcessingUi();
      if (mounted) {
        setState(() {
          isLoggedIn = false;
          _hasAnalyzed = false;
          savedCookie = null;
          savedUserId = null;
          savedUserAgent = null;
          _syncCountsForUi();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizeTrEn(
              _lang,
              'Oturum geçersiz. Lütfen tekrar giriş yapın.',
              'Session is invalid. Please log in again.')),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    final String uaToUse = _resolveUserAgent();
    _storyTrayRefreshQueued = true;

    try {
      final DateTime now = await _getEstimatedNetworkTime();
      _refreshNetworkTimeOffset();
      final int? lastMs = prefs.getInt('last_update_time');
      if (lastMs != null) {
        final DateTime last = DateTime.fromMillisecondsSinceEpoch(lastMs);
        final Duration wait = const Duration(hours: 6) - now.difference(last);
        if (wait > Duration.zero) {
          final bool adsDisabled = _adsDisabled;
          if (mounted) {
            final bool? wantWatch = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                      title: Text(_t('start_analysis_question')),
                      content: Text(adsDisabled
                          ? _t('analysis_ready_risk')
                          : _t('remaining_time',
                              {'time': _formatDuration(wait)})),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(_t('cancel'))),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(adsDisabled
                                ? _t('start_analysis')
                                : _t('watch_ad'))),
                      ],
                    ));

            if (wantWatch == true) {
              final adResult = await _showRewardedAdWithResult();
              if (adResult["status"] == false) {
                final String adError =
                    (adResult["error"] ?? '').toString().trim();
                if (adError.isNotEmpty) _setGoogleAdWarning(adError);
                if (mounted) {
                  final String msg = adError.isNotEmpty
                      ? _t('google_ad_warning', {'reason': adError})
                      : (localizeTrEn(
                          _lang,
                          'Reklam açılamadı. Lütfen tekrar deneyin.',
                          'Ad could not be shown. Please try again.'));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(msg),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ));
                }
                return;
              }
            } else {
              stopProcessingUi();
              return;
            }
          } else {
            stopProcessingUi();
            return;
          }
        }
      }
    } catch (_) {}

    if (!processingStarted && mounted) {
      startProcessingUi();
    }

    try {
      final Map<String, dynamic> info = await _retryIg<Map<String, dynamic>>(
        () async {
          final Map<String, dynamic>? fetched =
              await _fetchUserInfoRaw(userId, cookie, uaToUse);
          if (fetched == null) throw Exception('invalid_payload');
          return fetched;
        },
        maxAttempts: 2,
      );

      _setAnalysisProgressCap(0.55);

      // Kullanıcı adı güncelle
      if (info['username'] != null) {
        String freshUser = info['username'].toString();
        if (currentUsername != freshUser) {
          setState(() => currentUsername = freshUser);
          prefs.setString('session_username', freshUser);
        }
      }
      _applyUserFlags();
      if (_isBanned) return;

      int tFollowers = _toIntOrNull(info['follower_count']) ?? 0;
      int tFollowing = _toIntOrNull(info['following_count']) ?? 0;
      const double baseProgress = 0.10;
      const double followersSpan = 0.40;
      const double followingSpan = 0.45;
      const double followingStart = baseProgress + followersSpan;
      final int followersExpected = max(1, tFollowers);
      final int followingExpected = max(1, tFollowing);

      final bool hasStoredData =
          followersMap.isNotEmpty || followingMap.isNotEmpty;
      if (hasStoredData && tFollowers == 0 && tFollowing == 0) {
        _showAnalysisWarning(localizeTrEn(_lang, 'Instagram veri döndürmedi.',
            'Instagram returned no data.'));
        return;
      }

      // HIZLI KONTROL KALDIRILDI - Her seferinde veri çekecek.

      Map<String, String> nFollowers = {};

      final int fetchedFollowers = await _retryIg<int>(() async {
        nFollowers.clear();
        return await _fetchPagedData(
            userId: userId,
            cookie: cookie,
            ua: uaToUse,
            type: 'followers',
            totalExpected: tFollowers,
            targetMap: nFollowers,
            onProgress: (fetched) {
              final double fraction =
                  (fetched / followersExpected).clamp(0.0, 1.0);
              _setAnalysisProgressCap(
                  baseProgress + (fraction * followersSpan));
            });
      }, maxAttempts: 2);
      _setAnalysisProgressCap(0.80);

      Map<String, String> nFollowing = {};

      final int fetchedFollowing = await _retryIg<int>(() async {
        nFollowing.clear();
        return await _fetchPagedData(
            userId: userId,
            cookie: cookie,
            ua: uaToUse,
            type: 'following',
            totalExpected: tFollowing,
            targetMap: nFollowing,
            onProgress: (fetched) {
              final double fraction =
                  (fetched / followingExpected).clamp(0.0, 1.0);
              _setAnalysisProgressCap(
                  followingStart + (fraction * followingSpan));
            });
      }, maxAttempts: 2);
      _setAnalysisProgressCap(0.92);
      _setAnalysisProgressCap(0.96);

      if (tFollowers > 0 && fetchedFollowers < (tFollowers * 0.85)) {
        _showAnalysisWarning(localizeTrEn(
          _lang,
          'Veri yükleme kesildi: takipçi verisi eksik ($fetchedFollowers/$tFollowers). Biraz bekleyip tekrar deneyin.',
          'Data loading was interrupted: follower data incomplete ($fetchedFollowers/$tFollowers). Please wait a bit and try again.',
        ));
        return;
      }
      if (tFollowing > 0 && fetchedFollowing < (tFollowing * 0.85)) {
        _showAnalysisWarning(localizeTrEn(
          _lang,
          'Veri yükleme kesildi: takip edilen verisi eksik ($fetchedFollowing/$tFollowing). Biraz bekleyip tekrar deneyin.',
          'Data loading was interrupted: following data incomplete ($fetchedFollowing/$tFollowing). Please wait a bit and try again.',
        ));
        return;
      }


      if (nFollowers.isNotEmpty || nFollowing.isNotEmpty) {
        final bool mustWatchAdToShowResults =
            !_adsDisabled && !_justWatchedReward;
        if (mustWatchAdToShowResults) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_t('ad_wait_message')),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.blueGrey.shade900,
            ));
          }

          await Future.delayed(const Duration(seconds: 2));

          final adResult = await _showRewardedAdWithResult();
          if (adResult["status"] != true) {
            final String adError = (adResult["error"] ?? '').toString().trim();
            if (adError.isNotEmpty) _setGoogleAdWarning(adError);
            final String reason = adError.isNotEmpty
                ? _t('google_ad_warning', {'reason': adError})
                : (localizeTrEn(
                    _lang,
                    "Reklam açılamadı. Sonuçlar gösterilemedi.",
                    "Ad could not be shown. Results cannot be displayed."));
            _showAnalysisWarning(reason);
            return;
          }
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }

        _setAnalysisProgressCap(0.985);
        await Future.delayed(const Duration(milliseconds: 16));
        await _processData(nFollowers, nFollowing);
        unawaited(TelemetryService.instance.recordAnalysisCompleted(
          followersCount: fetchedFollowers,
          followingCount: fetchedFollowing,
          duration: _analysisStartedAt == null
              ? null
              : DateTime.now().difference(_analysisStartedAt!),
        ));
        await _finishProgressUi();

        if (_justWatchedReward) setState(() => _justWatchedReward = false);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_t('data_updated')),
              backgroundColor: Colors.green));
      } else {
        if (tFollowers == 0 && tFollowing == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_t('data_updated')),
                backgroundColor: Colors.green));
          }
        } else {
          _showAnalysisWarning(localizeTrEn(
            _lang,
            'Veri yükleme kesildi: Instagram boş veri döndürdü. Lütfen tekrar deneyin.',
            'Data loading was interrupted: Instagram returned empty data. Please try again.',
          ));
        }
      }
    } catch (e) {
      String reason = localizeTrEn(
        _lang,
        'Veri yükleme kesildi: beklenmeyen bir hata oluştu.',
        'Data loading stopped due to an unexpected error.',
      );
      final String raw = e.toString();
      final String rawLower = raw.toLowerCase();

      if (rawLower.contains('ig_warning')) {
        final String igMsg = _extractIgWarningTextFromError(e).trim();
        reason = localizeTrEn(
          _lang,
          'Instagram otomatik davranış uyarısı verdi. Güvenlik için veri çekme durduruldu. Biraz bekleyip tekrar deneyin.',
          'Instagram returned an automated-behavior warning. We stopped fetching data for safety. Please wait and try again.',
        );
        unawaited(_showIgWarningGuide(igMsg));
      } else if (rawLower.contains('checkpoint_required') ||
          rawLower.contains('challenge_required')) {
        final String code = rawLower.contains('checkpoint_required')
            ? 'checkpoint_required'
            : 'challenge_required';
        reason = localizeTrEn(
          _lang,
          'Instagram güvenlik doğrulaması istedi (şüpheli giriş / hesap kilidi). Instagram uygulamasından doğrulayıp tekrar deneyin.',
          'Instagram requested security verification (suspicious login / account lock). Verify in Instagram app and try again.',
        );
        unawaited(_showIgSecurityVerificationGuide(code));
      } else if (rawLower.contains('session_invalid') ||
          rawLower.contains('http_401') ||
          rawLower.contains('http_403')) {
        reason = localizeTrEn(
          _lang,
          'Oturum geçersiz veya doğrulama bekliyor. Lütfen tekrar giriş yapın.',
          'Session is invalid or waiting for verification. Please log in again.',
        );
      } else if (rawLower.contains('http_429')) {
        reason = localizeTrEn(
          _lang,
          'Çok hızlı istek gönderildi. Veri yükleme güvenlik nedeniyle kesildi.',
          'Too many requests were sent. Data loading was interrupted for safety.',
        );
      } else if (rawLower.contains('timeoutexception') ||
          rawLower.contains('timeout')) {
        reason = localizeTrEn(
          _lang,
          'Bağlantı zaman aşımına uğradı. Veri yükleme yarıda kesildi.',
          'Connection timed out. Data loading was interrupted.',
        );
      } else if (rawLower.contains('socketexception') ||
          rawLower.contains('failed host lookup') ||
          rawLower.contains('network is unreachable') ||
          rawLower.contains('connection reset') ||
          rawLower.contains('clientexception')) {
        reason = localizeTrEn(
          _lang,
          'İnternet bağlantısı kesildi veya zayıf. Veri yükleme tamamlanamadı.',
          'Network connection dropped or is unstable. Data loading could not complete.',
        );
      } else if (rawLower.contains('handshakeexception') ||
          rawLower.contains('certificate')) {
        reason = localizeTrEn(
          _lang,
          'Güvenli bağlantı kurulamadığı için veri yükleme durdu.',
          'Secure connection could not be established, so loading stopped.',
        );
      } else if (rawLower.contains('invalid_json') ||
          rawLower.contains('invalid_payload')) {
        reason = localizeTrEn(
          _lang,
          'Instagram beklenmeyen bir yanıt döndürdü. Veri yükleme kesildi.',
          'Instagram returned an unexpected response. Data loading was interrupted.',
        );
      } else if (rawLower.contains('http_')) {
        final int? code = _parseHttpErrorCode(rawLower);
        if (code != null) {
          reason = localizeTrEn(
            _lang,
            'Instagram sunucusu hata döndürdü (HTTP $code). Veri yükleme kesildi.',
            'Instagram returned an error (HTTP $code). Data loading was interrupted.',
          );
        } else {
          reason = localizeTrEn(
            _lang,
            'Instagram sunucusu hata döndürdü. Veri yükleme kesildi.',
            'Instagram returned an error. Data loading was interrupted.',
          );
        }
      }
      _showAnalysisWarning(reason);
    } finally {
      _stopProgressPump();
      _stopAnalysisProgressTimeline();
      if (mounted) {
        setState(() {
          isProcessing = false;
          _analysisStartedAt = null;
          _progressValue = _progressTarget.clamp(0.0, 1.0);
        });
      }
      if (isLoggedIn && !_isBanned && _storyTrayRefreshQueued) {
        unawaited(_loadStoryTray());
      }
    }
  }

  int? _parseHttpErrorCode(String raw) {
    final RegExpMatch? match =
        RegExp(r'http_(\d{3})').firstMatch(raw.toLowerCase());
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  String? _detectIgSecurityBlockFromText(String rawBody) {
    final String body = rawBody.toLowerCase();
    if (body.contains('checkpoint_required') ||
        body.contains('checkpoint_url') ||
        body.contains('/checkpoint/')) {
      return 'checkpoint_required';
    }
    if (body.contains('challenge_required') || body.contains('/challenge/')) {
      return 'challenge_required';
    }
    return null;
  }

  String? _detectIgSecurityBlockFromMap(Map body) {
    final String message = body['message']?.toString().toLowerCase() ?? '';
    final String errorType = body['error_type']?.toString().toLowerCase() ?? '';
    final String errorTitle =
        body['error_title']?.toString().toLowerCase() ?? '';
    final String detail = body['detail']?.toString().toLowerCase() ?? '';
    final String combined = '$message $errorType $errorTitle $detail';
    if (combined.contains('checkpoint') || body.containsKey('checkpoint_url')) {
      return 'checkpoint_required';
    }
    if (combined.contains('challenge') || body.containsKey('challenge')) {
      return 'challenge_required';
    }
    return null;
  }

  String? _detectIgWarningFromMap(Map body) {
    final String message = body['message']?.toString() ?? '';
    final String status = body['status']?.toString() ?? '';
    final String errorType = body['error_type']?.toString() ?? '';
    final String errorTitle = body['error_title']?.toString() ?? '';
    final String detail = body['detail']?.toString() ?? '';
    final String feedbackTitle = body['feedback_title']?.toString() ?? '';
    final String feedbackMessage = body['feedback_message']?.toString() ?? '';
    final bool spam = body['spam'] == true;

    final String combinedLower =
        '$message $status $errorType $errorTitle $detail $feedbackTitle $feedbackMessage'
            .toLowerCase();

    final String statusLower = status.toLowerCase().trim();
    final bool looksLikeWarning = statusLower == 'fail' ||
        spam ||
        feedbackTitle.trim().isNotEmpty ||
        feedbackMessage.trim().isNotEmpty ||
        combinedLower.contains('feedback_required') ||
        combinedLower.contains('try again later') ||
        combinedLower.contains('please wait') ||
        combinedLower.contains('we restrict') ||
        combinedLower.contains('action blocked') ||
        combinedLower.contains('temporarily') ||
        combinedLower.contains('sentry_block') ||
        combinedLower.contains('rate limit') ||
        combinedLower.contains('too many requests');

    if (!looksLikeWarning) return null;

    String msg = '';
    final String cleanFeedbackTitle = feedbackTitle.trim();
    final String cleanFeedbackMessage = feedbackMessage.trim();
    if (cleanFeedbackTitle.isNotEmpty) msg = cleanFeedbackTitle;
    if (cleanFeedbackMessage.isNotEmpty) {
      msg =
          msg.isEmpty ? cleanFeedbackMessage : '$msg — $cleanFeedbackMessage';
    }

    final String cleanMessage = message.trim();
    final String cleanErrorTitle = errorTitle.trim();
    final String cleanDetail = detail.trim();

    if (msg.isEmpty) {
      if (cleanMessage.isNotEmpty &&
          cleanMessage.toLowerCase() != 'feedback_required') {
        msg = cleanMessage;
      } else if (cleanErrorTitle.isNotEmpty) {
        msg = cleanErrorTitle;
      } else if (cleanDetail.isNotEmpty) {
        msg = cleanDetail;
      }
    }

    msg = msg.trim();
    if (msg.isEmpty) return 'try_again_later';
    return msg;
  }

  String? _detectIgWarningFromText(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map) {
        return _detectIgWarningFromMap(decoded);
      }
    } catch (_) {}

    final String body = rawBody.toLowerCase();
    final bool looksLikeWarning = body.contains('feedback_required') ||
        body.contains('try again later') ||
        body.contains('please wait') ||
        body.contains('we restrict') ||
        body.contains('action blocked') ||
        body.contains('temporarily') ||
        body.contains('sentry_block') ||
        body.contains('rate limit') ||
        body.contains('too many requests');
    if (!looksLikeWarning) return null;
    return _extractIgWarning(rawBody) ?? 'try_again_later';
  }

  String _extractIgWarningTextFromError(Object error) {
    final String raw = error.toString();
    final int idx = raw.toLowerCase().indexOf('ig_warning');
    if (idx < 0) return '';
    String tail = raw.substring(idx);
    tail = tail.replaceFirst(
      RegExp(r'ig_warning\s*:?\s*', caseSensitive: false),
      '',
    );
    return tail.trim();
  }

  bool _isRetryableIgException(Object error) {
    final String raw = error.toString().toLowerCase();
    if (raw.contains('session_invalid') ||
        raw.contains('ig_warning') ||
        raw.contains('challenge_required') ||
        raw.contains('checkpoint_required')) {
      return false;
    }
    final int? code = _parseHttpErrorCode(raw);
    if (code != null) {
      if (code == 429) return false;
      if (code == 401 || code == 403) return false;
      if (code == 408) return true;
      if (code == 301 || code == 302) return true;
      if (code >= 500 && code <= 599) return true;
      return false;
    }
    return raw.contains('timeoutexception') ||
        raw.contains('timeout') ||
        raw.contains('socketexception') ||
        raw.contains('handshakeexception') ||
        raw.contains('clientexception') ||
        raw.contains('invalid_json') ||
        raw.contains('invalid_payload');
  }

  Future<T> _retryIg<T>(Future<T> Function() action,
      {int maxAttempts = 3}) async {
    Object? lastError;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        if (attempt >= maxAttempts || !_isRetryableIgException(e)) rethrow;
        final int backoffMs =
            _igRetryBaseDelay.inMilliseconds * (1 << (attempt - 1));
        final int jitterMs = _storyRand.nextInt(250);
        await Future.delayed(Duration(milliseconds: backoffMs + jitterMs));
      }
    }
    throw lastError ?? Exception('unknown_error');
  }

  Future<void> _applyIgRequestPacing({
    required Duration minGap,
    required int jitterMaxMs,
    required bool allowBreather,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? last = _igLastIgRequestAt;

    final int jitterMs = jitterMaxMs <= 0 ? 0 : _storyRand.nextInt(jitterMaxMs);
    int breatherMs = 0;
    int humanPauseMs = 0;
    if (allowBreather) {
      _igPageRequestCounter++;
      if (_igPageRequestCounter % 8 == 0) {
        breatherMs = 700 + _storyRand.nextInt(1100);
      } else if (_storyRand.nextInt(100) < 20) {
        humanPauseMs = 140 + _storyRand.nextInt(260);
      }
    }

    final int desiredGapMs =
        minGap.inMilliseconds + jitterMs + humanPauseMs + breatherMs;
    if (last != null) {
      final int elapsedMs = now.difference(last).inMilliseconds;
      final int waitMs = desiredGapMs - elapsedMs;
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
  }

  Future<T> _withIgRequestPacing<T>(
    Future<T> Function() action, {
    Duration minGap = const Duration(milliseconds: 360),
    int jitterMaxMs = 260,
    bool allowBreather = false,
  }) async {
    final Completer<T> completer = Completer<T>();
    final Future<void> previous = _igRequestChain.catchError((_) {});
    _igRequestChain = previous.then((_) async {
      try {
        await _applyIgRequestPacing(
          minGap: minGap,
          jitterMaxMs: jitterMaxMs,
          allowBreather: allowBreather,
        );
        final T result = await action();
        _igLastIgRequestAt = DateTime.now();
        completer.complete(result);
      } catch (e, st) {
        _igLastIgRequestAt = DateTime.now();
        completer.completeError(e, st);
      }
    }).catchError((_) {});
    return completer.future;
  }

  Future<http.Response> _igGet(
    Uri uri, {
    required Map<String, String> headers,
    Duration minGap = const Duration(milliseconds: 560),
    int jitterMaxMs = 420,
    bool allowBreather = false,
  }) {
    return _withIgRequestPacing(
      () => http.get(uri, headers: headers).timeout(_igRequestTimeout),
      minGap: minGap,
      jitterMaxMs: jitterMaxMs,
      allowBreather: allowBreather,
    );
  }

  Future<Map<String, dynamic>?> _fetchUserInfoRaw(
      String userId, String cookie, String ua) async {
    String? terminalError;

    Map<String, dynamic>? parseUser(http.Response response) {
      if (response.statusCode != 200) {
        final String? security = _detectIgSecurityBlockFromText(response.body);
        if (security != null) {
          terminalError = security;
          return null;
        }
        final String? warning = _detectIgWarningFromText(response.body);
        if (warning != null) {
          terminalError = 'ig_warning:$warning';
          throw Exception(terminalError);
        }
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        terminalError = 'session_invalid';
        return null;
      }
      if (response.statusCode == 429) {
        terminalError = 'http_429';
        return null;
      }
      if (response.statusCode != 200) {
        terminalError ??= 'http_${response.statusCode}';
        return null;
      }
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['user'] is Map) {
          return body['user'] as Map<String, dynamic>;
        }
        if (body is Map) {
          final String? security = _detectIgSecurityBlockFromMap(body);
          if (security != null) {
            terminalError = security;
            return null;
          }
          final String message =
              body['message']?.toString().toLowerCase() ?? '';
          if (message.contains('login')) {
            terminalError = 'session_invalid';
            return null;
          }
          final String? warning = _detectIgWarningFromMap(body);
          if (warning != null) {
            terminalError = 'ig_warning:$warning';
            throw Exception(terminalError);
          }
          return body.cast<String, dynamic>();
        }
      } catch (_) {
        final String? security = _detectIgSecurityBlockFromText(response.body);
        if (security != null) {
          terminalError ??= security;
        } else {
          final String? warning = _detectIgWarningFromText(response.body);
          if (warning != null) {
            terminalError = 'ig_warning:$warning';
            throw Exception(terminalError);
          }
          terminalError ??= 'invalid_json';
        }
      }
      terminalError ??= 'invalid_payload';
      return null;
    }

    final bool preferWeb = _preferWebApi(ua);
    final String appUa =
        ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;

    if (preferWeb) {
      final webResp = await _igGet(
        Uri.parse("https://www.instagram.com/api/v1/users/$userId/info/"),
        headers: _buildWebHeaders(cookie, ua, dsUserId: userId),
        minGap: const Duration(milliseconds: 460),
        jitterMaxMs: 320,
      );
      final parsed = parseUser(webResp);
      if (parsed != null) return parsed;
    }

    final appResp = await _igGet(
      Uri.parse("https://i.instagram.com/api/v1/users/$userId/info/"),
      headers: _buildAppHeaders(cookie, appUa, dsUserId: userId),
      minGap: const Duration(milliseconds: 460),
      jitterMaxMs: 320,
    );
    final appParsed = parseUser(appResp);
    if (appParsed != null) return appParsed;

    if (!preferWeb) {
      final webResp = await _igGet(
        Uri.parse("https://www.instagram.com/api/v1/users/$userId/info/"),
        headers: _buildWebHeaders(cookie, ua, dsUserId: userId),
        minGap: const Duration(milliseconds: 460),
        jitterMaxMs: 320,
      );
      final parsed = parseUser(webResp);
      if (parsed != null) return parsed;
    }

    if (terminalError != null) {
      throw Exception(terminalError);
    }
    return null;
  }

  Future<int> _fetchPagedData(
      {required String userId,
      required String cookie,
      required String ua,
      required String type,
      required int totalExpected,
      required Map<String, String> targetMap,
      Function(int count)? onProgress}) async {
    final String endpoint = type == 'followers'
        ? 'friendships/$userId/followers'
        : 'friendships/$userId/following';
    final bool preferWeb = _preferWebApi(ua);
    final String appUa =
        ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;

    bool useWebApi = preferWeb;
    bool triedAlternate = false;
    String? nextMaxId;
    bool hasNext = true;
    int currentCount = targetMap.length;
    String? terminalError;
    final int expected = max(1, totalExpected);
    const int pageCount = 200;
    int adaptiveMinGapMs = expected <= 350
        ? 340
        : (expected <= 1200 ? 430 : 520);
    int adaptiveJitterMaxMs = expected <= 350
        ? 140
        : (expected <= 1200 ? 200 : 260);
    final int adaptiveMinGapFloorMs = expected <= 350 ? 300 : 390;
    final int adaptiveJitterFloorMs = expected <= 350 ? 110 : 160;
    final int adaptiveMinGapMaxMs = expected <= 350 ? 980 : 1280;
    int repeatedCursorCount = 0;

    bool canSwitchEndpoint() {
      return !triedAlternate;
    }

    void slowDownAdaptivePacing() {
      adaptiveMinGapMs = min(
        adaptiveMinGapMaxMs,
        adaptiveMinGapMs + (expected <= 350 ? 90 : 130),
      );
      adaptiveJitterMaxMs = min(
        520,
        adaptiveJitterMaxMs + (expected <= 350 ? 50 : 90),
      );
    }

    void switchEndpointPreservingProgress() {
      triedAlternate = true;
      useWebApi = !useWebApi;
      repeatedCursorCount = 0;
    }

    while (hasNext) {
      String base = useWebApi
          ? "https://www.instagram.com/api/v1/"
          : "https://i.instagram.com/api/v1/";
      final String? requestCursor = nextMaxId;
      final Uri baseUri = Uri.parse("$base$endpoint");
      final Map<String, String> query = <String, String>{
        'count': pageCount.toString(),
      };
      if (requestCursor != null && requestCursor.isNotEmpty) {
        query['max_id'] = requestCursor;
      }
      final Uri requestUri = baseUri.replace(queryParameters: query);

      final response = await _igGet(
        requestUri,
        headers: useWebApi
            ? _buildWebHeaders(cookie, ua, dsUserId: userId)
            : _buildAppHeaders(cookie, appUa, dsUserId: userId),
        minGap: Duration(milliseconds: adaptiveMinGapMs),
        jitterMaxMs: adaptiveJitterMaxMs,
        allowBreather: true,
      );

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          final String? security =
              _detectIgSecurityBlockFromText(response.body);
          if (security != null) {
            terminalError = security;
            throw Exception(terminalError);
          }
          final String? warning = _detectIgWarningFromText(response.body);
          if (warning != null) {
            terminalError = 'ig_warning:$warning';
            throw Exception(terminalError);
          }
          slowDownAdaptivePacing();
          if (canSwitchEndpoint()) {
            switchEndpointPreservingProgress();
            continue;
          }
          throw Exception('invalid_json');
        }
        if (decoded is! Map) {
          slowDownAdaptivePacing();
          if (canSwitchEndpoint()) {
            switchEndpointPreservingProgress();
            continue;
          }
          throw Exception('invalid_payload');
        }
        final Map data = decoded;
        final String? security = _detectIgSecurityBlockFromMap(data);
        if (security != null) {
          terminalError = security;
          throw Exception(terminalError);
        }
        final String status = data['status']?.toString().toLowerCase() ?? '';
        final String message = data['message']?.toString().toLowerCase() ?? '';
        if (message.contains('login') ||
            message.contains('challenge') ||
            message.contains('checkpoint')) {
          terminalError = 'session_invalid';
          if (canSwitchEndpoint()) {
            switchEndpointPreservingProgress();
            continue;
          }
          throw Exception(terminalError);
        }

        final String? warning = _detectIgWarningFromMap(data);
        if (warning != null) {
          slowDownAdaptivePacing();
          terminalError = 'ig_warning:$warning';
          throw Exception(terminalError);
        }

        if (status == 'fail') {
          slowDownAdaptivePacing();
          final String rawMsg = data['message']?.toString().trim() ?? '';
          terminalError =
              rawMsg.isNotEmpty ? 'ig_warning:$rawMsg' : 'ig_warning';
          if (canSwitchEndpoint()) {
            switchEndpointPreservingProgress();
            continue;
          }
          throw Exception(terminalError);
        }

        final List users = data['users'] is List ? data['users'] : const [];
        if (users.isNotEmpty) {
          adaptiveMinGapMs = max(adaptiveMinGapFloorMs, adaptiveMinGapMs - 6);
          adaptiveJitterMaxMs =
              max(adaptiveJitterFloorMs, adaptiveJitterMaxMs - 4);
        }
        for (final dynamic u in users) {
          if (u is! Map) continue;
          final String username = (u['username'] ?? '').toString().trim();
          if (username.isEmpty) continue;
          String picUrl = _extractBestProfilePhotoUrlFromUser(u) ?? '';
          if (picUrl.isEmpty) {
            picUrl =
                _normalizeHdProfileImageUrl((u['profile_pic_url'] ?? '').toString());
          }
          final bool isNew = !targetMap.containsKey(username);
          final String existingPic = (targetMap[username] ?? '').trim();
          if (picUrl.isNotEmpty || existingPic.isEmpty) {
            targetMap[username] = picUrl;
          }
          if (isNew) currentCount++;
        }

        if (onProgress != null) onProgress(currentCount);

        final String? nextCursor = data['next_max_id']?.toString();
        if (nextCursor != null &&
            nextCursor.isNotEmpty &&
            requestCursor != null &&
            nextCursor == requestCursor) {
          repeatedCursorCount++;
        } else {
          repeatedCursorCount = 0;
        }
        nextMaxId = (nextCursor != null && nextCursor.isNotEmpty)
            ? nextCursor
            : null;
        hasNext = nextMaxId != null;
        if (repeatedCursorCount >= 2) {
          hasNext = false;
        }
        if (totalExpected > 0 && currentCount >= totalExpected) {
          hasNext = false;
        }
      } else {
        final String? security = _detectIgSecurityBlockFromText(response.body);
        if (security != null) {
          terminalError = security;
          throw Exception(terminalError);
        }
        final String? warning = _detectIgWarningFromText(response.body);
        if (warning != null) {
          terminalError = 'ig_warning:$warning';
          throw Exception(terminalError);
        }
        slowDownAdaptivePacing();
        if (response.statusCode == 401 || response.statusCode == 403) {
          terminalError = 'session_invalid';
        } else if (response.statusCode == 429) {
          terminalError = 'http_429';
        } else {
          terminalError ??= 'http_${response.statusCode}';
        }
        if (canSwitchEndpoint()) {
          switchEndpointPreservingProgress();
          continue;
        }
        throw Exception(terminalError);
      }
    }
    return currentCount;
  }

  Future<void> _handleLoginSuccess(dynamic result) async {
    if (result is! Map) return;
    final Map<String, dynamic> payload =
        result.map((k, v) => MapEntry(k.toString(), v));
    final String cookie = (payload['cookie'] ?? '').toString().trim();
    String userId = (payload['user_id'] ?? '').toString().trim();
    if (userId.isEmpty || userId == 'null') {
      userId = _extractCookieValue(cookie, 'ds_user_id').trim();
    }
    final String usernameRaw = (payload['username'] ?? '').toString().trim();
    final String userAgentRaw = (payload['user_agent'] ?? '').toString().trim();
    final String userAgent =
        userAgentRaw.isNotEmpty ? userAgentRaw : _defaultIgUserAgent;
    if (cookie.isEmpty || userId.isEmpty || userId == 'null') {
      _logFirebaseDiagnostic(
        'session',
        'login payload invalid: cookie/userId missing',
        isError: true,
        popCritical: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizeTrEn(
              _lang,
              'Oturum doğrulaması tamamlanamadı. Lütfen tekrar giriş yapın.',
              'Session verification failed. Please log in again.')),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ));
      }
      return;
    }
    final String username = usernameRaw.isNotEmpty
        ? usernameRaw
        : (localizeTrEn(_lang, 'Kullanıcı', 'User'));

    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_cookie', cookie);
        await prefs.setString('session_user_id', userId);
        await prefs.setString('session_username', username);
        await prefs.setString('session_user_agent', userAgent);
      } catch (_) {}
    }());

    unawaited(TelemetryService.instance.recordLogin(
      userId: userId,
      username: username,
      isPremium: PurchasesService.instance.isPremium.value,
    ));
    unawaited(_incrementFirestoreCounter('login_count'));
    unawaited(_forceWriteIgUserDoc(username: username));
    if (mounted) {
      setState(() {
        isLoggedIn = true;
        _hasAnalyzed = false;
        savedCookie = cookie;
        savedUserId = userId;
        currentUsername = username;
        savedUserAgent = userAgent;
        _syncCountsForUi();
      });
    } else {
      isLoggedIn = true;
      _hasAnalyzed = false;
      savedCookie = cookie;
      savedUserId = userId;
      currentUsername = username;
      savedUserAgent = userAgent;
    }

    _applyUserFlags();
    if (_isBanned) return;
    _storyTrayRefreshQueued = true;
    unawaited(_refreshData(startProcessingImmediately: true));
  }

  Future<void> _processData(
      Map<String, String> nFollowers, Map<String, String> nFollowing) async {
    _setProgressValue(0.975);
    await Future.delayed(const Duration(milliseconds: 16));

    final prefs = await SharedPreferences.getInstance();
    Map<String, String> oldFollowers =
        _safeMapCast(jsonDecode(prefs.getString('followers_map') ?? '{}'));
    Map<String, String> oldFollowing =
        _safeMapCast(jsonDecode(prefs.getString('following_map') ?? '{}'));
    Map<String, String> storedUnfollowers =
        _safeMapCast(jsonDecode(prefs.getString('unfollowers_map') ?? '{}'));
    Map<String, String> storedLeftFollowing =
        _safeMapCast(jsonDecode(prefs.getString('left_following_map') ?? '{}'));

    final bool allowLeftFollowing = nFollowing.length < oldFollowing.length;
    Map<String, String> newFollowers = {};
    bool isFirstRun = oldFollowers.isEmpty;

    const int yieldEvery = 750;
    Future<void> maybeYield(
        int done, int total, double start, double end) async {
      if (done <= 0 || done % yieldEvery != 0) return;
      final double fraction = total <= 0 ? 1.0 : (done / total).clamp(0.0, 1.0);
      _setProgressValue(start + ((end - start) * fraction));
      await Future.delayed(const Duration(milliseconds: 1));
    }

    badges = {
      'followers': 0,
      'following': 0,
      'new_followers': 0,
      'non_followers': 0,
      'left_followers': 0,
      'left_following': 0
    };
    newItemsMap = {
      'followers': {},
      'following': {},
      'new_followers': {},
      'non_followers': {},
      'left_followers': {},
      'left_following': {}
    };

    final int oldFollowersTotal = oldFollowers.length;
    int oldFollowersDone = 0;
    for (final entry in oldFollowers.entries) {
      final String user = entry.key;
      final String img = entry.value;
      if (!nFollowers.containsKey(user)) {
        if (!storedUnfollowers.containsKey(user)) {
          badges['left_followers'] = (badges['left_followers'] ?? 0) + 1;
          newItemsMap['left_followers']!.add(user);
        }
        storedUnfollowers[user] = img;
      }
      oldFollowersDone++;
      await maybeYield(oldFollowersDone, oldFollowersTotal, 0.975, 0.980);
    }
    _setProgressValue(0.980);
    await Future.delayed(const Duration(milliseconds: 1));

    final int oldFollowingTotal = oldFollowing.length;
    int oldFollowingDone = 0;
    for (final entry in oldFollowing.entries) {
      final String user = entry.key;
      final String img = entry.value;
      if (!nFollowing.containsKey(user) && allowLeftFollowing) {
        if (!storedLeftFollowing.containsKey(user)) {
          badges['left_following'] = (badges['left_following'] ?? 0) + 1;
          newItemsMap['left_following']!.add(user);
        }
        storedLeftFollowing[user] = img;
      }
      oldFollowingDone++;
      await maybeYield(oldFollowingDone, oldFollowingTotal, 0.980, 0.985);
    }
    _setProgressValue(0.985);
    await Future.delayed(const Duration(milliseconds: 1));

    final int nFollowersTotal = nFollowers.length;
    int nFollowersDone = 0;
    for (final entry in nFollowers.entries) {
      final String user = entry.key;
      final String img = entry.value;
      if (!oldFollowers.containsKey(user)) {
        newItemsMap['followers']!.add(user);

        if (!isFirstRun) {
          newFollowers[user] = img;
          badges['new_followers'] = (badges['new_followers'] ?? 0) + 1;
          newItemsMap['new_followers']!.add(user);
        }
      }
      nFollowersDone++;
      await maybeYield(nFollowersDone, nFollowersTotal, 0.985, 0.990);
    }
    badges['followers'] = newItemsMap['followers']!.length;

    final int nFollowingTotal = nFollowing.length;
    int nFollowingDone = 0;
    for (final entry in nFollowing.entries) {
      final String user = entry.key;
      if (!oldFollowing.containsKey(user)) {
        badges['following'] = (badges['following'] ?? 0) + 1;
        newItemsMap['following']!.add(user);
      }
      nFollowingDone++;
      await maybeYield(nFollowingDone, nFollowingTotal, 0.990, 0.992);
    }
    _setProgressValue(0.992);
    await Future.delayed(const Duration(milliseconds: 1));

    final int followerDelta = nFollowers.length - oldFollowers.length;
    if (followerDelta < 0) badges['followers'] = followerDelta;
    final int followingDelta = nFollowing.length - oldFollowing.length;
    if (followingDelta < 0) badges['following'] = followingDelta;

    Map<String, String> curNon = {};
    int curNonBuildDone = 0;
    for (final entry in nFollowing.entries) {
      final String u = entry.key;
      final String img = entry.value;
      if (!nFollowers.containsKey(u)) curNon[u] = img;
      curNonBuildDone++;
      await maybeYield(curNonBuildDone, nFollowingTotal, 0.992, 0.993);
    }
    Map<String, String> oldNon = {};
    int oldNonBuildDone = 0;
    for (final entry in oldFollowing.entries) {
      final String u = entry.key;
      final String img = entry.value;
      if (!oldFollowers.containsKey(u)) oldNon[u] = img;
      oldNonBuildDone++;
      await maybeYield(oldNonBuildDone, oldFollowingTotal, 0.993, 0.994);
    }

    final int curNonTotal = curNon.length;
    int curNonDone = 0;
    for (final entry in curNon.entries) {
      final String user = entry.key;
      if (!oldNon.containsKey(user)) {
        badges['non_followers'] = (badges['non_followers'] ?? 0) + 1;
        newItemsMap['non_followers']!.add(user);
      }
      curNonDone++;
      await maybeYield(curNonDone, curNonTotal, 0.994, 0.996);
    }

    _setProgressValue(0.996);
    await Future.delayed(const Duration(milliseconds: 1));

    await prefs.setString('followers_map', jsonEncode(nFollowers));
    _setProgressValue(0.9965);
    await Future.delayed(const Duration(milliseconds: 1));
    await prefs.setString('following_map', jsonEncode(nFollowing));
    _setProgressValue(0.9970);
    await Future.delayed(const Duration(milliseconds: 1));
    await prefs.setString('unfollowers_map', jsonEncode(storedUnfollowers));
    _setProgressValue(0.9975);
    await Future.delayed(const Duration(milliseconds: 1));
    await prefs.setString(
        'left_following_map', jsonEncode(storedLeftFollowing));
    _setProgressValue(0.9980);
    await Future.delayed(const Duration(milliseconds: 1));
    await prefs.setString('new_followers_map', jsonEncode(newFollowers));
    _setProgressValue(0.9986);
    await Future.delayed(const Duration(milliseconds: 1));

    final realNow = await _getNetworkTime();
    await prefs.setInt('last_update_time', realNow.millisecondsSinceEpoch);
    _setProgressValue(0.999);
    unawaited(_incrementFirestoreCounter('query_count'));
    _hasAnalyzed = true;
    _loadStoredData();
  }

  String _resolveUserAgent() {
    final String? ua = savedUserAgent;
    if (ua != null && ua.trim().isNotEmpty) return ua;
    return _defaultIgUserAgent;
  }

  void _resetBadgesAndNewItems() {
    badges = {
      'followers': 0,
      'following': 0,
      'new_followers': 0,
      'non_followers': 0,
      'left_followers': 0,
      'left_following': 0,
    };
    newItemsMap = {
      'followers': {},
      'following': {},
      'new_followers': {},
      'non_followers': {},
      'left_followers': {},
      'left_following': {},
    };
  }

  void _syncCountsForUi() {
    if (!isLoggedIn) {
      followersCount = '?';
      followingCount = '?';
      nonFollowersCount = '?';
      leftCount = '?';
      leftFollowingCount = '?';
      newCount = '?';
      _resetBadgesAndNewItems();
      return;
    }

    if (!_hasAnalyzed) {
      followersCount = '0';
      followingCount = '0';
      nonFollowersCount = '0';
      leftCount = '0';
      leftFollowingCount = '0';
      newCount = '0';
      _resetBadgesAndNewItems();
      return;
    }

    followersCount = followersMap.length.toString();
    followingCount = followingMap.length.toString();
    nonFollowersCount = nonFollowersMap.length.toString();
    leftCount = unfollowersMap.length.toString();
    leftFollowingCount = leftFollowingMap.length.toString();
    newCount = newFollowersMap.length.toString();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _networkTimeOffsetMs = prefs.getInt(_networkTimeOffsetKey);
    } catch (_) {}
    final int? lastUpdateMs = prefs.getInt('last_update_time');
    final Map<String, String> storedFollowers =
        _safeMapCast(jsonDecode(prefs.getString('followers_map') ?? '{}'));
    final Map<String, String> storedFollowing =
        _safeMapCast(jsonDecode(prefs.getString('following_map') ?? '{}'));
    final Map<String, String> storedUnfollowers =
        _safeMapCast(jsonDecode(prefs.getString('unfollowers_map') ?? '{}'));
    final Map<String, String> storedLeftFollowing =
        _safeMapCast(jsonDecode(prefs.getString('left_following_map') ?? '{}'));
    final Map<String, String> storedNewFollowers =
        _safeMapCast(jsonDecode(prefs.getString('new_followers_map') ?? '{}'));
    final bool hasStoredAnalysis = lastUpdateMs != null ||
        storedFollowers.isNotEmpty ||
        storedFollowing.isNotEmpty ||
        storedUnfollowers.isNotEmpty ||
        storedLeftFollowing.isNotEmpty ||
        storedNewFollowers.isNotEmpty;
    if (mounted) {
      setState(() {
        followersMap = storedFollowers;
        followingMap = storedFollowing;
        unfollowersMap = storedUnfollowers;
        leftFollowingMap = storedLeftFollowing;
        newFollowersMap = storedNewFollowers;
        _hasAnalyzed = hasStoredAnalysis;
        nonFollowersMap = {};
        followingMap.forEach((u, img) {
          if (!followersMap.containsKey(u)) nonFollowersMap[u] = img;
        });
        _syncCountsForUi();
      });
    }
    await _startCountdownFromStoredTime();
  }

  Map<String, String> _safeMapCast(dynamic input) {
    Map<String, String> output = {};
    if (input is Map) {
      input.forEach((k, v) {
        final String key = k.toString();
        final String raw = v.toString();
        output[key] = _normalizeHdProfileImageUrl(raw);
      });
    }
    return output;
  }

  int? _toIntOrNull(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Widget _buildInfoBox(IconData icon, String text, Color color) {
    final String cleanText = text.trim();
    if (cleanText.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1))),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(cleanText,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : color)))
      ]),
    );
  }

  Future<void> _showIgSecurityVerificationGuide(String code) async {
    if (!mounted || _securityGuideVisible) return;
    _securityGuideVisible = true;
    final String langCode = _lang;
    final bool isCheckpoint = code.toLowerCase().contains('checkpoint');
    final String title = localizeTrEn(
      langCode,
      'Instagram Doğrulaması Gerekli',
      'Instagram Verification Required',
    );
    final String description = localizeTrEn(
      langCode,
      'Instagram hesabınız için güvenlik doğrulaması gerekiyor (şüpheli giriş bildirimi / geçici kilit). Bu yüzden verileri çekemiyoruz.',
      'Instagram requires a security verification for your account (suspicious login / temporary lock). We can’t fetch data until it’s verified.',
    );
    final String typeHint = isCheckpoint
        ? localizeTrEn(
            langCode,
            'Bu genelde “hesap kilidi / checkpoint” durumudur.',
            'This is usually an “account lock / checkpoint”.',
          )
        : localizeTrEn(
            langCode,
            'Bu genelde “şüpheli giriş” doğrulamasıdır.',
            'This is usually a “suspicious login” verification.',
          );
    final String steps = localizeTrEn(
      langCode,
      'Ne yapmalıyım?\n'
          '1) Instagram uygulamasını açın.\n'
          '2) “Şüpheli giriş” uyarısı varsa “Bu bendim” diyerek doğrulayın.\n'
          '3) Gerekirse şifrenizi değiştirip tekrar giriş yapın.\n'
          '4) Bu uygulamaya dönüp “VERİLERİ GÜNCELLE”ye basın.',
      'What to do:\n'
          '1) Open the Instagram app.\n'
          '2) If you see a “Suspicious login” alert, confirm it’s you.\n'
          '3) If needed, change your password and log in again.\n'
          '4) Come back here and tap “REFRESH DATA”.',
    );
    final String hint = localizeTrEn(
      langCode,
      'Not: Doğrulama sonrası bazen 1–2 dakika beklemek gerekebilir.',
      'Note: After verification, you may need to wait 1–2 minutes.',
    );

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              '$description\n$typeHint\n\n$steps\n\n$hint',
              style: const TextStyle(height: 1.35),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(localizeTrEn(langCode, 'Kapat', 'Close'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 120));
                try {
                  await launchUrl(
                    Uri.parse('https://www.instagram.com/'),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {}
              },
              child: Text(
                  localizeTrEn(langCode, "Instagram'ı Aç", 'Open Instagram')),
            ),
          ],
        ),
      );
    } finally {
      _securityGuideVisible = false;
    }
  }

  Future<void> _showIgWarningGuide(String igMessage) async {
    if (!mounted || _igWarningVisible) return;
    _igWarningVisible = true;
    final String langCode = _lang;

    final String title = localizeTrEn(
      langCode,
      'Instagram Geçici Kısıtlama',
      'Instagram Temporary Restriction',
    );
    final String description = localizeTrEn(
      langCode,
      'Instagram bu işlemi geçici olarak kısıtladı. Bu genelde çok sık istek / otomatik aktivite algılandığında olur. Veri çekme durduruldu.',
      'Instagram temporarily restricted this action. This can happen when requests are too frequent or activity looks automated. We stopped fetching data.',
    );

    final String cleanIg = (() {
      final String v = igMessage.trim();
      final String lower = v.toLowerCase();
      if (lower == 'try_again_later' || lower == 'feedback_required') return '';
      return v;
    })();

    final String igBlock = cleanIg.isEmpty
        ? ''
        : '${localizeTrEn(langCode, 'Instagram mesajı', 'Instagram message')}:\n$cleanIg';

    final String steps = localizeTrEn(
      langCode,
      'Ne yapabilirsin?\n'
          '1) Instagram uygulamasını aç.\n'
          '2) Bir uyarı/ek doğrulama varsa tamamla.\n'
          '3) 10–30 dakika bekle.\n'
          '4) Bu uygulamaya dönüp tekrar “VERİLERİ GÜNCELLE”ye bas.',
      'What you can do:\n'
          '1) Open the Instagram app.\n'
          '2) Complete any alert or verification if shown.\n'
          '3) Wait 10–30 minutes.\n'
          '4) Come back here and tap “REFRESH DATA” again.',
    );

    final String hint = localizeTrEn(
      langCode,
      'Not: Arka arkaya çok sık analiz yapmak bu uyarıyı tetikleyebilir.',
      'Note: Running analyses back-to-back can trigger this.',
    );

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              igBlock.isEmpty
                  ? '$description\n\n$steps\n\n$hint'
                  : '$description\n\n$igBlock\n\n$steps\n\n$hint',
              style: const TextStyle(height: 1.35),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(localizeTrEn(langCode, 'Kapat', 'Close'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 120));
                try {
                  await launchUrl(
                    Uri.parse('https://www.instagram.com/'),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {}
              },
              child: Text(
                  localizeTrEn(langCode, "Instagram'ı Aç", 'Open Instagram')),
            ),
          ],
        ),
      );
    } finally {
      _igWarningVisible = false;
    }
  }

  void _showAnalysisWarning(String reason) {
    if (!mounted) return;
    final String message =
        "${_t('analysis_failed_title')}\n${_t('analysis_failed_reason', {
          'reason': reason
        })}\n${_t('analysis_failed_hint')}";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      backgroundColor: _storySnackColor(tone: 'error'),
    ));
  }

  Color _storySnackColor({String tone = 'info'}) {
    return _appSnackColorForTone(isDark: isDarkMode, tone: tone);
  }

  void _ensureStoryAutoScroll() {
    if (!_watchStoriesEnabled) return;
    if (_storyAutoTimer != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || isLoggedIn) return;
      if (!_storyScrollController.hasClients) return;
      _storyAutoTimer =
          Timer.periodic(const Duration(milliseconds: 1800), (timer) {
        if (!mounted || isLoggedIn) {
          _stopStoryAutoScroll();
          return;
        }
        if (!_storyScrollController.hasClients) return;
        final max = _storyScrollController.position.maxScrollExtent;
        final current = _storyScrollController.offset;
        final next = current + 80.0;
        final target = next >= max ? 0.0 : next;
        _storyScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  void _stopStoryAutoScroll() {
    _storyAutoTimer?.cancel();
    _storyAutoTimer = null;
  }

  Future<bool> _showAdGate() async {
    if (_adsDisabled) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_t('story_ad_wait')),
      duration: const Duration(seconds: 1),
      backgroundColor: _storySnackColor(),
    ));
    await Future.delayed(const Duration(seconds: 1));
    final adResult = await _showRewardedAdWithResult(
      adUnitOverride: 'ca-app-pub-7480771330660307/4726353967',
    );
    if (adResult["status"] == false) {
      final String adError = (adResult["error"] ?? '').toString().trim();
      if (adError.isNotEmpty) _setGoogleAdWarning(adError);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(adError.isNotEmpty
              ? _t('google_ad_warning', {'reason': adError})
              : (localizeTrEn(
                  _lang,
                  'Reklam açılamadı. Lütfen tekrar deneyin.',
                  'Ad could not be shown. Please try again.'))),
          backgroundColor: _storySnackColor(tone: 'error'),
          duration: const Duration(seconds: 4),
        ));
      }
      return false;
    }
    return true;
  }

  List<_StoryProfile> _getStoryProfiles() {
    if (isLoggedIn) {
      final source = followingMap.isNotEmpty ? followingMap : followersMap;
      final List<_StoryProfile> list = source.entries.map((e) {
        final String unameLower = e.key.toLowerCase();
        final String normalizedPic = _normalizeHdProfileImageUrl(e.value);
        final String trayPic =
            _normalizeHdProfileImageUrl((_storyUserPics[unameLower] ?? '').trim());
        final String resolvedPic =
            normalizedPic.isNotEmpty ? normalizedPic : trayPic;
        return _StoryProfile(
            username: e.key,
            imageUrl: resolvedPic.isNotEmpty
                ? resolvedPic
                : "https://via.placeholder.com/150",
            isBlurred: resolvedPic.isEmpty,
            hasStory: _storyUsersWithActive.contains(unameLower),
            pk: _storyUserPks[unameLower]);
      }).toList();

      final Set<String> seen = source.keys.map((e) => e.toLowerCase()).toSet();
      int added = 0;
      for (final unameLower in _storyUsersWithActive) {
        if (seen.contains(unameLower)) continue;
        if (added >= 25) break;
        final String pic =
            _normalizeHdProfileImageUrl((_storyUserPics[unameLower] ?? '').trim());
        final bool hasPic = pic.isNotEmpty;
        list.add(_StoryProfile(
            username: unameLower,
            imageUrl: hasPic ? pic : "https://via.placeholder.com/150",
            isBlurred: !hasPic,
            hasStory: true,
            pk: _storyUserPks[unameLower]));
        added++;
      }

      list.sort((a, b) {
        if (a.hasStory && !b.hasStory) return -1;
        if (!a.hasStory && b.hasStory) return 1;
        if (a.hasStory && b.hasStory) {
          final int ai =
              _storyActiveOrderIndex[a.username.toLowerCase()] ?? (1 << 30);
          final int bi =
              _storyActiveOrderIndex[b.username.toLowerCase()] ?? (1 << 30);
          if (ai != bi) return ai.compareTo(bi);
        }
        return a.username.compareTo(b.username);
      });
      return list;
    }

    final List<int> ids = List<int>.generate(20, (i) => i + 1);
    ids.shuffle(_storyRand);
    final String fakePrefix = _t('user_label');
    return ids.take(12).map((i) {
      return _StoryProfile(
          username: "${fakePrefix}_$i",
          imageUrl: "https://via.placeholder.com/150",
          isBlurred: true,
          hasStory: false);
    }).toList();
  }

  Widget _buildStoryImage(_StoryProfile profile, double size) {
    Color colorFromKey(String key) {
      final int h = key.codeUnits.fold(0, (p, c) => p + c);
      const List<Color> palette = [
        Color(0xFFE57373),
        Color(0xFF64B5F6),
        Color(0xFF81C784),
        Color(0xFFFFB74D),
        Color(0xFFBA68C8),
        Color(0xFF4DB6AC),
      ];
      return palette[h % palette.length];
    }

    final img = Image.network(profile.imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stack) => Container(
              width: size,
              height: size,
              color: Colors.grey.shade300,
              child: Icon(Icons.person, color: Colors.grey.shade600),
            ));
    if (!profile.isBlurred) return img;
    final Color c = colorFromKey(profile.username);
    final placeholder = Container(
      width: size,
      height: size,
      color: c.withOpacity(0.9),
      alignment: Alignment.center,
      child: Text(
        '?',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.95),
        ),
      ),
    );
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: placeholder,
    );
  }

  Widget _buildStoryAvatar(_StoryProfile profile) {
    const double size = 56;
    final bool showRing = isLoggedIn && profile.hasStory;
    final bool showWhiteRing = isLoggedIn && !profile.hasStory;
    final bool showMutedRing = !isLoggedIn;
    final BoxDecoration? ringDecoration = showRing
        ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFFFBAA47),
                Color(0xFFD91A46),
                Color(0xFFA60F93),
                Color(0xFFFBAA47),
              ],
              transform: GradientRotation(-pi / 2),
            ),
          )
        : (showWhiteRing
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Colors.white70 : Colors.white,
                  width: 2,
                ),
              )
            : (showMutedRing
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white24
                          : Colors.blueGrey.withOpacity(0.35),
                      width: 2,
                    ),
                  )
                : null));

    final double outerPadding =
        showRing ? 3.0 : (showWhiteRing ? 2.2 : (showMutedRing ? 2.0 : 0.0));
    final double innerPadding = showRing ? 1.6 : 0.0;

    final Widget avatar = ClipOval(child: _buildStoryImage(profile, size));
    final Widget inner = innerPadding <= 0
        ? avatar
        : Container(
            padding: EdgeInsets.all(innerPadding),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            child: avatar,
          );

    final Widget avatarWithRing = ringDecoration == null
        ? inner
        : Container(
            padding: EdgeInsets.all(outerPadding),
            decoration: ringDecoration,
            child: inner,
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoggedIn ? () => _handleStoryTap(profile) : null,
      child: Column(
        children: [
          avatarWithRing,
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              profile.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStorySection() {
    if (!_watchStoriesEnabled) return const SizedBox.shrink();
    final profiles = _getStoryProfiles();
    if (isLoggedIn) {
      _stopStoryAutoScroll();
    } else {
      _ensureStoryAutoScroll();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('story_section_title'),
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDarkMode ? Colors.white : Colors.black87)),
        if (isLoggedIn && _isStoryTrayLoading) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.white70 : Colors.black54))),
              const SizedBox(width: 8),
              Text(
                localizeTrEn(
                    _lang, 'Hikayeler yükleniyor...', 'Loading stories...'),
                style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white60 : Colors.black54),
              ),
            ],
          ),
        ],
        if (!isLoggedIn) ...[
          const SizedBox(height: 4),
          Text(_t('story_login_required'),
              style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white60 : Colors.black54)),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: profiles.isEmpty
              ? (isLoggedIn && _isStoryTrayLoading
                  ? const SizedBox.shrink()
                  : Center(
                      child: Text(_t('story_no_data'),
                          style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.black54))))
              : ListView.separated(
                  controller: _storyScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) => _buildStoryAvatar(profiles[i]),
                ),
        ),
      ],
    );
  }

  Future<void> _handleStoryTap(_StoryProfile profile) async {
    if (!_watchStoriesEnabled) return;
    final String? action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (ctx) {
          final Color sheetTextColor =
              isDarkMode ? Colors.white : Colors.black87;
          final Color sheetIconColor =
              isDarkMode ? Colors.white70 : Colors.black54;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_t('story_action_title'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: sheetTextColor)),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.photo, color: sheetIconColor),
                    title: Text(_t('story_view_photo'),
                        style: TextStyle(color: sheetTextColor)),
                    onTap: () => Navigator.pop(ctx, 'photo'),
                  ),
                  ListTile(
                    leading: Icon(Icons.visibility_off, color: sheetIconColor),
                    title: Text(_t('story_watch_secret'),
                        style: TextStyle(color: sheetTextColor)),
                    onTap: () => Navigator.pop(ctx, 'story'),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        });

    if (action == 'photo') {
      if (!isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_t('story_login_required')),
            backgroundColor: _storySnackColor(tone: 'error'),
            duration: const Duration(seconds: 4),
          ));
        }
        return;
      }
      final bool ok = await _showAdGate();
      if (!ok) return;
      _showProfilePhoto(profile);
    } else if (action == 'story') {
      if (!isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_t('story_login_required')),
            backgroundColor: _storySnackColor(tone: 'error'),
            duration: const Duration(seconds: 4),
          ));
        }
        return;
      }
      final bool ok = await _showAdGate();
      if (!ok) return;
      _openSecretStoryViewer(profile);
    }
  }

  String _normalizeProfileImageUrl(String url) {
    final String normalized = url.trim();
    if (normalized.isEmpty) return normalized;
    try {
      final Uri? parsed = Uri.tryParse(normalized);
      if (parsed == null) return normalized;
      if (parsed.scheme.isEmpty || parsed.host.isEmpty) return normalized;
      return parsed.toString();
    } catch (_) {
      return normalized;
    }
  }

  String _normalizeHdProfileImageUrl(String url) {
    String normalized = _normalizeProfileImageUrl(url).trim();
    if (normalized.isEmpty) return normalized;
    try {
      final Uri? parsed = Uri.tryParse(normalized);
      if (parsed != null && parsed.hasQuery) {
        final Map<String, String> query =
            Map<String, String>.from(parsed.queryParameters);
        query.removeWhere((key, value) => value.trim().isEmpty);
        normalized = parsed
            .replace(queryParameters: query.isEmpty ? null : query)
            .toString();
      }
    } catch (_) {}
    return normalized;
  }

  String? _pickLargestUrlFromVersionList(dynamic versions) {
    if (versions is! List) return null;
    String? bestUrl;
    int bestScore = -1;
    for (final dynamic version in versions) {
      if (version is! Map) continue;
      final String url = (version['url'] ?? '').toString().trim();
      if (url.isEmpty) continue;
      final int width = _toIntOrNull(version['width']) ?? 0;
      final int height = _toIntOrNull(version['height']) ?? 0;
      final int pixels = width * height;
      final int bitRate = _toIntOrNull(version['bit_rate']) ??
          _toIntOrNull(version['bandwidth']) ??
          0;
      final int score = pixels > 0 ? pixels : bitRate;
      if (score > bestScore) {
        bestScore = score;
        bestUrl = url;
      }
    }
    if (bestUrl != null && bestUrl.trim().isNotEmpty) {
      return bestUrl.trim();
    }
    for (final dynamic version in versions) {
      if (version is! Map) continue;
      final String url = (version['url'] ?? '').toString().trim();
      if (url.isNotEmpty) return url;
    }
    return null;
  }

  String? _extractBestProfilePhotoUrlFromUser(dynamic userNode) {
    if (userNode is! Map) return null;
    final List<String> candidates = [];

    final String? hdFromVersions =
        _pickLargestUrlFromVersionList(userNode['hd_profile_pic_versions']);
    if (hdFromVersions != null && hdFromVersions.isNotEmpty) {
      candidates.add(hdFromVersions);
    }

    final dynamic hdInfo = userNode['hd_profile_pic_url_info'];
    if (hdInfo is Map) {
      final String hdInfoUrl = (hdInfo['url'] ?? '').toString().trim();
      if (hdInfoUrl.isNotEmpty) candidates.add(hdInfoUrl);
    }

    final String profilePicHd =
        (userNode['profile_pic_url_hd'] ?? '').toString().trim();
    if (profilePicHd.isNotEmpty) candidates.add(profilePicHd);

    final dynamic imageVersions2 = userNode['image_versions2'];
    if (imageVersions2 is Map) {
      final String? fromCandidates =
          _pickLargestUrlFromVersionList(imageVersions2['candidates']);
      if (fromCandidates != null && fromCandidates.isNotEmpty) {
        candidates.add(fromCandidates);
      }
    }

    final String profilePic = (userNode['profile_pic_url'] ?? '').toString().trim();
    if (profilePic.isNotEmpty) candidates.add(profilePic);

    for (final String raw in candidates) {
      final String normalized = _normalizeHdProfileImageUrl(raw);
      if (normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  String? _extractUserIdFromWebProfilePayload(dynamic payload) {
    if (payload is! Map) return null;

    final dynamic userNode =
        payload['user'] ?? (payload['data'] is Map ? payload['data']['user'] : null);

    final List<dynamic> idCandidates = [
      payload['id'],
      payload['pk'],
      userNode is Map ? userNode['id'] : null,
      userNode is Map ? userNode['pk'] : null,
    ];
    for (final dynamic candidate in idCandidates) {
      final String value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  bool _looksLikeDirectStoryMediaNode(dynamic node) {
    if (node is! Map) return false;
    return node.containsKey('media_type') ||
        node.containsKey('image_versions2') ||
        node.containsKey('image_candidates2') ||
        node.containsKey('video_versions') ||
        node.containsKey('video_resources') ||
        node.containsKey('carousel_media') ||
        node.containsKey('display_url') ||
        node.containsKey('thumbnail_url');
  }

  Map<dynamic, dynamic>? _resolveStoryMediaNode(dynamic node,
      {int depth = 0}) {
    if (depth > 6) return null;

    if (node is Map) {
      if (_looksLikeDirectStoryMediaNode(node)) return node;

      const List<String> priorityKeys = <String>[
        'story_feed_media',
        'story_media',
        'story_reel_media',
        'story_share',
        'story_app_attribution',
        'reel_share',
        'media_share',
        'media_container',
        'media',
        'clip',
        'clips',
        'xma_story',
        'reshared_story_media',
        'reshared_media',
        'reposted_media',
        'repost',
        'original_media',
        'parent_media',
      ];

      for (final String key in priorityKeys) {
        final Map<dynamic, dynamic>? resolved =
            _resolveStoryMediaNode(node[key], depth: depth + 1);
        if (resolved != null) return resolved;
      }

      for (final MapEntry<dynamic, dynamic> entry in node.entries) {
        final String key = entry.key.toString();
        if (key == 'user' || key == 'owner') continue;
        final Map<dynamic, dynamic>? resolved =
            _resolveStoryMediaNode(entry.value, depth: depth + 1);
        if (resolved != null) return resolved;
      }
      return null;
    }

    if (node is List) {
      for (final dynamic child in node) {
        final Map<dynamic, dynamic>? resolved =
            _resolveStoryMediaNode(child, depth: depth + 1);
        if (resolved != null) return resolved;
      }
    }
    return null;
  }

  List<StoryItem> _extractStoryItemsFromPayload(
      String responseBody, String targetUserId) {
    try {
      final dynamic decoded = jsonDecode(responseBody);
      return _extractStoryItemsFromDecodedPayload(decoded, targetUserId);
    } catch (_) {}
    return const [];
  }

  List<StoryItem> _extractStoryItemsFromDecodedPayload(
      dynamic decoded, String targetUserId) {
    if (decoded is! Map && decoded is! List) return const [];
    final String target = targetUserId.trim();
    if (target.isEmpty) return const [];

    bool matchesTarget(dynamic node) {
      if (node is! Map) return false;
      final dynamic user = node['user'];
      final dynamic owner = node['owner'];
      final List<dynamic> ids = [
        node['id'],
        node['user_id'],
        node['pk'],
        node['owner_id'],
        node['reel_owner_id'],
        node['target_user_id'],
        node['author_id'],
        user is Map ? user['pk'] : null,
        user is Map ? user['id'] : null,
        owner is Map ? owner['pk'] : null,
        owner is Map ? owner['id'] : null,
      ];
      for (final dynamic id in ids) {
        if ((id ?? '').toString().trim() == target) return true;
      }
      return false;
    }

    bool looksLikeStoryItem(dynamic node) {
      return _resolveStoryMediaNode(node) != null;
    }

    final List<List<dynamic>> matchedItemLists = <List<dynamic>>[];
    final List<List<dynamic>> fallbackItemLists = <List<dynamic>>[];

    void collect(dynamic node, {bool forceMatch = false}) {
      if (node is Map) {
        final bool currentMatch = forceMatch || matchesTarget(node);
        final dynamic directItems = node['items'];
        if (directItems is List && directItems.isNotEmpty) {
          final bool validItems = directItems.any(looksLikeStoryItem);
          if (validItems) {
            if (currentMatch) {
              matchedItemLists.add(directItems);
            } else {
              fallbackItemLists.add(directItems);
            }
          }
        }
        for (final MapEntry<dynamic, dynamic> entry in node.entries) {
          if (entry.key.toString() == 'items') continue;
          final String entryKey = entry.key.toString().trim();
          collect(
            entry.value,
            forceMatch: currentMatch || entryKey == target,
          );
        }
        return;
      }
      if (node is List) {
        for (final dynamic child in node) {
          collect(child, forceMatch: forceMatch);
        }
      }
    }

    collect(decoded);

    final List<List<dynamic>> orderedItemLists;
    if (matchedItemLists.isNotEmpty) {
      orderedItemLists = <List<dynamic>>[
        ...matchedItemLists,
        ...fallbackItemLists,
      ];
    } else if (fallbackItemLists.length == 1) {
      // If target IDs are missing in payload, only trust a single-candidate set.
      orderedItemLists = <List<dynamic>>[fallbackItemLists.first];
    } else {
      return const [];
    }
    for (final List<dynamic> items in orderedItemLists) {
      final List<StoryItem> parsed = _parseStoryItems(items);
      if (parsed.isNotEmpty) return parsed;
    }
    return const [];
  }

  Future<String?> _fetchHdProfilePhotoUrl(_StoryProfile profile) async {
    final String cookie = (savedCookie ?? '').trim();
    if (cookie.isEmpty) return null;
    final String ua = _resolveUserAgent();
    final String appUa =
        ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;
    final bool preferWeb = _preferWebApi(ua);
    final String? sessionDsUserId =
        _resolveSessionDsUserId(savedUserId, savedCookie);

    Future<String?> fromUserId(String userId) async {
      final String cleanUserId = userId.trim();
      if (cleanUserId.isEmpty) return null;

      try {
        final Map<String, dynamic>? user =
            await _fetchUserInfoRaw(cleanUserId, cookie, ua);
        final String? best = _extractBestProfilePhotoUrlFromUser(user);
        if (best != null && best.isNotEmpty) return best;
      } catch (_) {}

      Future<String?> fetchInfo({
        required Uri uri,
        required Map<String, String> headers,
      }) async {
        try {
          final response = await _igGet(
            uri,
            headers: headers,
            minGap: const Duration(milliseconds: 420),
            jitterMaxMs: 320,
          );
          if (response.statusCode != 200) return null;
          final dynamic parsed = jsonDecode(response.body);
          if (parsed is! Map) return null;
          final dynamic userNode = parsed['user'] ??
              (parsed['data'] is Map ? parsed['data']['user'] : null);
          return _extractBestProfilePhotoUrlFromUser(userNode);
        } catch (_) {
          return null;
        }
      }

      final Uri appUri =
          Uri.parse("https://i.instagram.com/api/v1/users/$cleanUserId/info/");
      final Uri webUri = Uri.parse(
          "https://www.instagram.com/api/v1/users/$cleanUserId/info/");

      final List<Future<String?> Function()> attempts = preferWeb
          ? [
              () => fetchInfo(
                    uri: webUri,
                    headers:
                        _buildWebHeaders(cookie, ua, dsUserId: sessionDsUserId),
                  ),
              () => fetchInfo(
                    uri: appUri,
                    headers:
                        _buildAppHeaders(cookie, appUa, dsUserId: sessionDsUserId),
                  ),
            ]
          : [
              () => fetchInfo(
                    uri: appUri,
                    headers:
                        _buildAppHeaders(cookie, appUa, dsUserId: sessionDsUserId),
                  ),
              () => fetchInfo(
                    uri: webUri,
                    headers:
                        _buildWebHeaders(cookie, ua, dsUserId: sessionDsUserId),
                  ),
            ];
      for (final attempt in attempts) {
        final String? found = await attempt();
        if (found != null && found.isNotEmpty) return found;
      }
      return null;
    }

    final String cachedPk = (profile.pk ?? '').trim();
    if (cachedPk.isNotEmpty) {
      final String? fromPk = await fromUserId(cachedPk);
      if (fromPk != null && fromPk.isNotEmpty) return fromPk;
    }

    final String? resolvedUserId = await _getUserId(profile.username);
    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      final String? fromResolved = await fromUserId(resolvedUserId);
      if (fromResolved != null && fromResolved.isNotEmpty) {
        return fromResolved;
      }
    }

    final String safe = Uri.encodeComponent(profile.username);
    final Uri webProfileUri = Uri.parse(
        "https://www.instagram.com/api/v1/users/web_profile_info/?username=$safe");
    final Uri appProfileUri = Uri.parse(
        "https://i.instagram.com/api/v1/users/web_profile_info/?username=$safe");

    Future<String?> fetchByUsername({
      required Uri uri,
      required Map<String, String> headers,
    }) async {
      try {
        final response = await _igGet(
          uri,
          headers: headers,
          minGap: const Duration(milliseconds: 420),
          jitterMaxMs: 320,
        );
        if (response.statusCode != 200) return null;
        final dynamic parsed = jsonDecode(response.body);
        if (parsed is! Map) return null;
        final dynamic userNode = parsed['user'] ??
            (parsed['data'] is Map ? parsed['data']['user'] : null);
        return _extractBestProfilePhotoUrlFromUser(userNode);
      } catch (_) {
        return null;
      }
    }

    final List<Future<String?> Function()> usernameAttempts = preferWeb
        ? [
            () => fetchByUsername(
                  uri: webProfileUri,
                  headers:
                      _buildWebHeaders(cookie, ua, dsUserId: sessionDsUserId),
                ),
            () => fetchByUsername(
                  uri: appProfileUri,
                  headers:
                      _buildAppHeaders(cookie, appUa, dsUserId: sessionDsUserId),
                ),
          ]
        : [
            () => fetchByUsername(
                  uri: appProfileUri,
                  headers:
                      _buildAppHeaders(cookie, appUa, dsUserId: sessionDsUserId),
                ),
            () => fetchByUsername(
                  uri: webProfileUri,
                  headers:
                      _buildWebHeaders(cookie, ua, dsUserId: sessionDsUserId),
                ),
          ];
    for (final attempt in usernameAttempts) {
      final String? found = await attempt();
      if (found != null && found.isNotEmpty) return found;
    }
    return null;
  }

  Future<void> _showProfilePhoto(_StoryProfile profile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    await _refreshSessionCookieFromWebViewStore(updateUserId: false);

    String url = profile.imageUrl;
    final String? hdUrl = await _fetchHdProfilePhotoUrl(profile);
    if (hdUrl != null && hdUrl.isNotEmpty) {
      url = hdUrl;
    }
    url = _normalizeHdProfileImageUrl(url);
    final String fallbackUrl = _normalizeProfileImageUrl(profile.imageUrl);

    if (mounted) Navigator.pop(context);

    if (!mounted) return;

    await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.black,
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double minH = constraints.maxHeight * 0.6;
                            final double minW = constraints.maxWidth * 0.9;
                            return SizedBox(
                              height: minH,
                              width: minW,
                              child: InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  headers: savedCookie != null
                                      ? {
                                          'Cookie': savedCookie!,
                                          'User-Agent': _resolveUserAgent(),
                                          'Accept': '*/*',
                                        }
                                      : null,
                                  errorBuilder: (context, error, stack) {
                                    if (fallbackUrl.isNotEmpty &&
                                        fallbackUrl != url) {
                                      return Image.network(
                                        fallbackUrl,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                        headers: savedCookie != null
                                            ? {
                                                'Cookie': savedCookie!,
                                                'User-Agent': _resolveUserAgent(),
                                                'Accept': '*/*',
                                              }
                                            : null,
                                        errorBuilder: (context, _, __) =>
                                            const Icon(
                                          Icons.broken_image,
                                          color: Colors.white70,
                                          size: 42,
                                        ),
                                      );
                                    }
                                    return const Icon(
                                      Icons.broken_image,
                                      color: Colors.white70,
                                      size: 42,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_t('story_close'),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  Future<String?> _getUserId(String username) async {
    final String key = username.toLowerCase();
    final String cached = (_storyUserPks[key] ?? '').trim();
    if (cached.isNotEmpty) return cached;

    final String cookie = (savedCookie ?? '').trim();
    if (cookie.isEmpty) return null;

    final String ua = _resolveUserAgent();
    final String appUa =
        ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;
    final bool preferWeb = _preferWebApi(ua);
    final String? sessionDsUserId =
        _resolveSessionDsUserId(savedUserId, savedCookie);
    final String safe = Uri.encodeComponent(username);

    Future<String?> fetchId({
      required Uri uri,
      required Map<String, String> headers,
    }) async {
      try {
        final response = await _igGet(
          uri,
          headers: headers,
          minGap: const Duration(milliseconds: 420),
          jitterMaxMs: 320,
        );
        if (response.statusCode != 200) {
          _lastIgWarning = _extractIgWarning(response.body);
          return null;
        }
        final dynamic data = jsonDecode(response.body);
        return _extractUserIdFromWebProfilePayload(data);
      } catch (_) {
        return null;
      }
    }

    final Uri webUri = Uri.parse(
        "https://www.instagram.com/api/v1/users/web_profile_info/?username=$safe");
    final Uri appUri = Uri.parse(
        "https://i.instagram.com/api/v1/users/web_profile_info/?username=$safe");

    final List<Future<String?> Function()> attempts = preferWeb
        ? [
            () => fetchId(
                  uri: webUri,
                  headers:
                      _buildWebHeaders(cookie, ua, dsUserId: sessionDsUserId),
                ),
            () => fetchId(
                  uri: appUri,
                  headers:
                      _buildAppHeaders(cookie, appUa, dsUserId: sessionDsUserId),
                ),
          ]
        : [
            () => fetchId(
                  uri: appUri,
                  headers:
                      _buildAppHeaders(cookie, appUa, dsUserId: sessionDsUserId),
                ),
            () => fetchId(
                  uri: webUri,
                  headers:
                      _buildWebHeaders(cookie, ua, dsUserId: sessionDsUserId),
                ),
          ];
    for (final attempt in attempts) {
      final String? id = await attempt();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  String? _extractIgWarning(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        final String? msg = data['message']?.toString() ??
            data['error_title']?.toString() ??
            data['detail']?.toString();
        if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      }
    } catch (_) {}
    return null;
  }

  Future<List<StoryItem>> _fetchStoryItems(String targetUserId) async {
    final String cookie = (savedCookie ?? '').trim();
    if (cookie.isEmpty) return const [];
    final String ua = _resolveUserAgent();
    final bool preferWeb = _preferWebApi(ua);
    final String appUa =
        ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;
    final String? dsUserHeader =
        _resolveSessionDsUserId(savedUserId, savedCookie);

    final Map<String, String> webHeaders =
        _buildWebHeaders(cookie, ua, dsUserId: dsUserHeader);
    final Map<String, String> appHeaders =
        _buildAppHeaders(cookie, appUa, dsUserId: dsUserHeader);

    final Uri reelsMediaWeb = Uri.parse(
        "https://www.instagram.com/api/v1/feed/reels_media/?reel_ids=$targetUserId");
    final Uri reelsMediaApp = Uri.parse(
        "https://i.instagram.com/api/v1/feed/reels_media/?reel_ids=$targetUserId");
    final Uri reelMediaWeb = Uri.parse(
        "https://www.instagram.com/api/v1/feed/user/$targetUserId/reel_media/");
    final Uri reelMediaApp = Uri.parse(
        "https://i.instagram.com/api/v1/feed/user/$targetUserId/reel_media/");
    final Uri reelsTrayWeb =
        Uri.parse("https://www.instagram.com/api/v1/feed/reels_tray/");
    final Uri reelsTrayApp =
        Uri.parse("https://i.instagram.com/api/v1/feed/reels_tray/");

    final List<Map<String, dynamic>> attempts = preferWeb
        ? [
            {'uri': reelsMediaWeb, 'headers': webHeaders},
            {'uri': reelsMediaApp, 'headers': appHeaders},
            {'uri': reelMediaWeb, 'headers': webHeaders},
            {'uri': reelMediaApp, 'headers': appHeaders},
            {'uri': reelsTrayWeb, 'headers': webHeaders},
            {'uri': reelsTrayApp, 'headers': appHeaders},
          ]
        : [
            {'uri': reelsMediaApp, 'headers': appHeaders},
            {'uri': reelsMediaWeb, 'headers': webHeaders},
            {'uri': reelMediaApp, 'headers': appHeaders},
            {'uri': reelMediaWeb, 'headers': webHeaders},
            {'uri': reelsTrayApp, 'headers': appHeaders},
            {'uri': reelsTrayWeb, 'headers': webHeaders},
          ];

    for (final Map<String, dynamic> attempt in attempts) {
      try {
        final http.Response response = await _igGet(
          attempt['uri'] as Uri,
          headers: attempt['headers'] as Map<String, String>,
          minGap: const Duration(milliseconds: 460),
          jitterMaxMs: 360,
        );
        if (response.statusCode != 200) {
          final String? security = _detectIgSecurityBlockFromText(response.body);
          if (security != null) {
            _lastIgWarning = localizeTrEn(
              _lang,
              'Instagram güvenlik doğrulaması gerekiyor (hikaye verisi alınamadı).',
              'Instagram security verification is required (story data could not be fetched).',
            );
          }
          final String? warning = _detectIgWarningFromText(response.body);
          if (warning != null && warning.trim().isNotEmpty) {
            _lastIgWarning = warning.trim();
          }
          continue;
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = null;
        }

        if (decoded is Map) {
          final String? security = _detectIgSecurityBlockFromMap(decoded);
          if (security != null) {
            _lastIgWarning = localizeTrEn(
              _lang,
              'Instagram güvenlik doğrulaması gerekiyor (hikaye verisi alınamadı).',
              'Instagram security verification is required (story data could not be fetched).',
            );
            continue;
          }
          final String? warning = _detectIgWarningFromMap(decoded);
          if (warning != null && warning.trim().isNotEmpty) {
            _lastIgWarning = warning.trim();
          }
        }

        final List<StoryItem> parsed = decoded == null
            ? _extractStoryItemsFromPayload(response.body, targetUserId)
            : _extractStoryItemsFromDecodedPayload(decoded, targetUserId);
        if (parsed.isNotEmpty) return parsed;
      } catch (e) {
        debugPrint("Story request error: $e");
      }
    }
    return const [];
  }

  List<StoryItem> _parseStoryItems(List<dynamic> dynamicItems) {
    final List<StoryItem> result = [];
    for (final dynamic item in dynamicItems) {
      if (item is! Map) continue;
      try {
        final Map<dynamic, dynamic> rawItem = item;
        final Map<dynamic, dynamic>? mediaNode = _resolveStoryMediaNode(rawItem);
        if (mediaNode == null) continue;

        String pickVideoUrl(Map<dynamic, dynamic> node) {
          String candidate =
              _pickLargestUrlFromVersionList(node['video_versions']) ?? '';
          if (candidate.isEmpty) {
            candidate =
                _pickLargestUrlFromVersionList(node['video_resources']) ?? '';
          }
          if (candidate.isEmpty) {
            final String clipVideo =
                (node['video_url'] ?? '').toString().trim();
            if (clipVideo.isNotEmpty) candidate = clipVideo;
          }
          return candidate;
        }

        String pickImageUrl(Map<dynamic, dynamic> node) {
          final dynamic imageVersions = node['image_versions2'];
          final dynamic candidates =
              imageVersions is Map ? imageVersions['candidates'] : null;
          String candidate = _pickLargestUrlFromVersionList(candidates) ?? '';
          if (candidate.isEmpty) {
            final dynamic imageCandidates2 = node['image_candidates2'];
            final dynamic c2 = imageCandidates2 is Map
                ? imageCandidates2['candidates']
                : imageCandidates2;
            candidate = _pickLargestUrlFromVersionList(c2) ?? '';
          }
          if (candidate.isEmpty) {
            final String displayUrl = (node['display_url'] ?? '').toString().trim();
            if (displayUrl.isNotEmpty) candidate = displayUrl;
          }
          if (candidate.isEmpty) {
            final String thumbnailUrl =
                (node['thumbnail_url'] ?? '').toString().trim();
            if (thumbnailUrl.isNotEmpty) candidate = thumbnailUrl;
          }
          return candidate;
        }

        final int mType = _toIntOrNull(mediaNode['media_type']) ??
            _toIntOrNull(rawItem['media_type']) ??
            1;
        String url = '';
        bool isVid = mType == 2 ||
            mediaNode.containsKey('video_versions') ||
            mediaNode.containsKey('video_resources');

        if (isVid) {
          url = pickVideoUrl(mediaNode);
          if (url.isEmpty && !identical(mediaNode, rawItem)) {
            url = pickVideoUrl(rawItem);
          }
        }

        if (url.isEmpty) {
          url = pickImageUrl(mediaNode);
          if (url.isEmpty && !identical(mediaNode, rawItem)) {
            url = pickImageUrl(rawItem);
          }
          if (url.isNotEmpty) isVid = false;
        }

        if (url.isEmpty) {
          dynamic carousel = mediaNode['carousel_media'];
          if ((carousel is! List || carousel.isEmpty) &&
              !identical(mediaNode, rawItem)) {
            carousel = rawItem['carousel_media'];
          }
          if (carousel is List && carousel.isNotEmpty) {
            final List<StoryItem> nested = _parseStoryItems(carousel);
            if (nested.isNotEmpty) {
              result.add(nested.first);
              continue;
            }
          }
        }

        if (url.isNotEmpty) {
          final String normalized =
              isVid ? url.trim() : _normalizeHdProfileImageUrl(url);
          if (normalized.isNotEmpty) {
            result.add(StoryItem(url: normalized, isVideo: isVid));
          }
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> _openSecretStoryViewer(_StoryProfile profile) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: Colors.white)));

    try {
      _lastIgWarning = null;
      await _refreshSessionCookieFromWebViewStore(updateUserId: false);
      String? targetId = (profile.pk ?? '').trim();
      if (targetId.isEmpty) {
        targetId = await _getUserId(profile.username);
      }

      if (targetId == null || targetId.trim().isEmpty) {
        if (mounted) Navigator.pop(context);
        final String msg = _lastIgWarning?.trim().isNotEmpty == true
            ? _lastIgWarning!
            : localizeTrEn(
                _lang,
                'Kullan\u0131c\u0131 verisi al\u0131namad\u0131 (Gizli profil veya API hatas\u0131)',
                'Could not fetch user data (Private profile or API error).',
              );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(msg),
                  backgroundColor: _storySnackColor(tone: 'error')));
        }
        return;
      }

      final List<StoryItem> stories = await _fetchStoryItems(targetId);

      if (mounted) Navigator.pop(context);

      if (stories.isEmpty) {
        final String warning = (_lastIgWarning ?? '').trim();
        final String message = warning.isNotEmpty
            ? warning
            : (profile.hasStory
                ? localizeTrEn(
                    _lang,
                    'Hikaye verisi alınamadı. Bu durum genelde Instagram doğrulaması, geçici API kısıtı veya bağlantı kesintisinden kaynaklanır. 2-3 dakika sonra tekrar deneyin.',
                    'Story data could not be fetched. This is usually caused by Instagram verification, temporary API restrictions, or connection interruption. Please try again in 2-3 minutes.',
                  )
                : _t('story_no_data'));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(message),
              backgroundColor: _storySnackColor(tone: 'warn')));
        }
        return;
      }

      if (mounted) {
        final String modeLabel =
            localizeTrEn(_lang, 'G\u0130ZL\u0130 MOD', 'Secret Mode');

        await Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => SecretStoryViewerPage(
                      username: profile.username,
                      stories: stories,
                      closeLabel: _t('story_close'),
                      modeLabel: modeLabel,
                    )));
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (!mounted) return;
      final String raw = e.toString().toLowerCase();
      final String message = (raw.contains('timeout') ||
              raw.contains('socketexception') ||
              raw.contains('failed host lookup'))
          ? localizeTrEn(
              _lang,
              'Hikaye yükleme bağlantı kesintisi nedeniyle durdu. Lütfen tekrar deneyin.',
              'Story loading stopped due to a network interruption. Please try again.',
            )
          : localizeTrEn(
              _lang,
              'Hikaye verisi alınamadı. Lütfen biraz sonra tekrar deneyin.',
              'Could not fetch story data. Please try again shortly.',
            );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: _storySnackColor(tone: 'warn'),
      ));
    }
  }

  Widget _buildNextAnalysisInfo() {
    if (!isLoggedIn) {
      return const SizedBox.shrink();
    }
    final TextStyle style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: isDarkMode ? Colors.white : Colors.black87,
    );
    final bool adsDisabled = _adsDisabled;
    if (adsDisabled) {
      return Text(_t('analysis_ready_risk'), style: style);
    }
    final remaining = _remainingToNextAnalysis;
    if (remaining == null) return const SizedBox.shrink();
    final String label =
        '${_t('next_analysis')}: ${_formatDuration(remaining)}';
    return GestureDetector(
        onTap: _showRemainingDialog, child: Text(label, style: style));
  }

  Widget _buildAnalysisReadyNowAboveButton() {
    if (!isLoggedIn) return const SizedBox.shrink();
    if (_adsDisabled) return const SizedBox.shrink();
    if (_remainingToNextAnalysis != null) return const SizedBox.shrink();

    final Color readyColor = isDarkMode ? Colors.greenAccent : Colors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        _t('next_analysis_ready'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: readyColor.withOpacity(0.92),
        ),
      ),
    );
  }

  Future<void> _checkUserAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('is_terms_accepted') ?? false)) {
      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) =>
                _buildDetailedLegalDialog(ctx, isInitial: true, prefs: prefs));
      }
    }
  }

  @override
  void dispose() {
    PurchasesService.instance.isPremium.removeListener(_onPremiumChanged);
    PurchasesService.instance.lastPurchaseError
        .removeListener(_onPurchaseErrorChanged);
    WidgetsBinding.instance.removeObserver(this);
    _cancelCountdown();
    _cancelLegalHoldTimer();
    _consentWatchTimer?.cancel();
    _storyAutoTimer?.cancel();
    _stopProgressPump();
    _stopAnalysisProgressTimeline();
    _storyScrollController.dispose();
    _firebaseDiagnosticEvents.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _startLegalHoldTimer() {
    _cancelLegalHoldTimer();
    _legalHoldTimer =
        Timer(const Duration(seconds: 5), () => _promptSecretPin());
  }

  void _cancelLegalHoldTimer() {
    _legalHoldTimer?.cancel();
    _legalHoldTimer = null;
  }

  Future<void> _promptSecretPin() async {
    final TextEditingController pCtrl = TextEditingController();
    final entered = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(_t('legal_warning')),
                content: TextField(
                    controller: pCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: _t('enter_pin'))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(_t('cancel'))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, pCtrl.text),
                      child: Text(_t('ok')))
                ]));
    if (entered != null) _handlePinEntry(entered.trim());
  }

  Future<void> _handlePinEntry(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    if (pin == '3333') {
      await prefs.remove('last_update_time');
      _startCountdownFromStoredTime();
      _bannerAd?.dispose();
      if (mounted)
        setState(() {
          _adsHidden = true;
          _bannerAd = null;
          _isAdLoaded = false;
        });
    }
  }

  String _legalSummaryForLang(String raw) {
    final String lang = raw.trim().toLowerCase().replaceAll('_', '-');
    String code = lang;
    if (lang.startsWith('es')) {
      code = lang == 'es-mx' ? 'es-mx' : 'es';
    } else if (lang.startsWith('zh')) {
      code = 'zh-hans';
    } else if (lang == 'in') {
      code = 'id';
    }
    final String resolvedCode =
        _legalWarningSummaryLabels.containsKey(code) ? code : 'en';
    return localizedPrivacyPolicyBody(resolvedCode);
  }

  String _buildLegalBodyText() {
    return _legalSummaryForLang(_lang);
  }

  Future<void> _showPrivacyPolicyDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_outlined, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                localizedPrivacyPolicyLabel(_lang),
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            localizedPrivacyPolicyBody(_lang),
            style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _openPrivacyPolicySource,
            child: Text(
              localizedPrivacyPolicyOpenSourceLabel(_lang),
              style: const TextStyle(fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              localizedPrivacyPolicyCloseLabel(_lang),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedLegalDialog(BuildContext context,
      {required bool isInitial, SharedPreferences? prefs}) {
    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.info_outline, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Text(localizedPrivacyPolicyLabel(_lang),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87))
      ]),
      content: SingleChildScrollView(
        child: Text(_buildLegalBodyText(),
            style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: isDarkMode ? Colors.white70 : Colors.black87)),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isInitial)
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _revokeConsentAndShowForm,
                        child: Text(
                          localizedWithdrawConsentLabel(_lang),
                          style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.blueGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (!isInitial) const SizedBox(height: 4),
            isInitial
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      prefs?.setBool('is_terms_accepted', true);
                      Navigator.pop(context);
                    },
                    child: Text(
                      _t('read_and_agree'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ))
                : TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(localizedPrivacyPolicyCloseLabel(_lang))),
          ],
        )
      ],
    );
  }
}

class SecretStoryViewerPage extends StatefulWidget {
  final String username;
  final List<StoryItem> stories;
  final String closeLabel;
  final String modeLabel;

  const SecretStoryViewerPage(
      {super.key,
      required this.username,
      required this.stories,
      required this.closeLabel,
      required this.modeLabel});

  @override
  State<SecretStoryViewerPage> createState() => _SecretStoryViewerPageState();
}

class _SecretStoryViewerPageState extends State<SecretStoryViewerPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTapUp: (details) {
                final double screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx > screenWidth / 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.stories.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentIndex = idx;
                  });
                },
                itemBuilder: (ctx, index) {
                  final story = widget.stories[index];
                  return _StoryItemView(story: story);
                },
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(widget.stories.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: index < _currentIndex
                                  ? Colors.white
                                  : (index == _currentIndex
                                      ? Colors.white
                                      : Colors.white24),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white24),
                        child: const Icon(Icons.visibility_off,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(widget.username,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(widget.modeLabel,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 25,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.transparent,
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    side: const BorderSide(color: Colors.white30)),
                onPressed: () => Navigator.pop(context),
                child: Text(widget.closeLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StoryItemView extends StatefulWidget {
  final StoryItem story;
  const _StoryItemView({required this.story});

  @override
  State<_StoryItemView> createState() => _StoryItemViewState();
}

class _StoryItemViewState extends State<_StoryItemView> {
  late final WebViewController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.story.isVideo) {
      final PlatformWebViewControllerCreationParams params;
      if (Platform.isIOS || Platform.isMacOS) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final WebViewController controller =
          WebViewController.fromPlatformCreationParams(params);

      if (controller.platform is AndroidWebViewController) {
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              unawaited(controller.runJavaScript('''
                (function() {
                  var v = document.querySelector('video');
                  if (v) { try { v.play(); } catch (e) {} }
                })();
              '''));
              if (mounted) {
                setState(() {
                  _isVideoInitialized = true;
                });
              }
            },
          ),
        )
        ..loadHtmlString('''
          <!DOCTYPE html>
          <html>
          <body style="margin:0;padding:0;background-color:black;display:flex;align-items:center;justify-content:center;height:100vh;">
            <video width="100%" height="100%" autoplay playsinline webkit-playsinline name="media">
              <source src="${widget.story.url}" type="video/mp4">
            </video>
          </body>
          </html>
        ''');

      _videoController = controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.isVideo) {
      return Stack(
        children: [
          if (!_isVideoInitialized)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          Offstage(
            offstage: !_isVideoInitialized,
            child: IgnorePointer(
              ignoring: true,
              child: WebViewWidget(controller: _videoController),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.story.url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                const Icon(Icons.broken_image, color: Colors.white70),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            },
          ),
        ],
      );
    }
  }
}

class DetailListPage extends StatelessWidget {
  final String title;
  final Map<String, String> items;
  final Color color;
  final bool isDark;
  final Set<String> newItems;
  final String lang;
  const DetailListPage(
      {super.key,
      required this.title,
      required this.items,
      required this.color,
      required this.isDark,
      required this.newItems,
      required this.lang});
  @override
  Widget build(BuildContext context) {
    List<String> names = items.keys.toList();
    final Color itemTextColor = isDark ? Colors.white : Colors.black87;
    final Color bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black),
        body: items.isEmpty
            ? Center(
                child: Text(localizeTrEn(lang, 'Veri yok', 'No data'),
                    style: TextStyle(color: itemTextColor)))
            : ListView.builder(
                itemCount: names.length,
                itemBuilder: (ctx, i) {
                  bool isNew = newItems.contains(names[i]);
                  final String imageUrl = (items[names[i]] ?? '').trim();
                  final Widget avatar = imageUrl.isEmpty
                      ? Container(
                          width: 40,
                          height: 40,
                          color: isDark ? Colors.white12 : Colors.black12,
                          child: Icon(
                            Icons.person,
                            color: isDark ? Colors.white70 : Colors.black45,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stack) => Container(
                            width: 40,
                            height: 40,
                            color: isDark ? Colors.white12 : Colors.black12,
                            child: Icon(
                              Icons.person,
                              color: isDark ? Colors.white70 : Colors.black45,
                            ),
                          ),
                        );
                  return ListTile(
                    onTap: () async {
                      final Uri url =
                          Uri.parse('https://instagram.com/${names[i]}');
                      if (!await launchUrl(url,
                          mode: LaunchMode.externalApplication)) {
                        Clipboard.setData(ClipboardData(text: names[i]));
                      }
                    },
                    leading: ClipOval(child: avatar),
                    title: Row(children: [
                      Text(names[i],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: itemTextColor)),
                      if (isNew) ...[
                        const SizedBox(width: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(localizeTrEn(lang, 'YENİ', 'NEW'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)))
                      ]
                    ]),
                    trailing: Icon(Icons.open_in_new,
                        size: 18, color: itemTextColor.withOpacity(0.5)),
                  );
                }));
  }
}

class InstagramApiPage extends StatefulWidget {
  final bool isDark;
  final String lang;
  const InstagramApiPage({super.key, required this.isDark, required this.lang});
  @override
  State<InstagramApiPage> createState() => _InstagramApiPageState();
}

class _InstagramApiPageState extends State<InstagramApiPage> {
  late final WebViewController _controller;
  static const platform =
      MethodChannel('com.grkmcomert.unfollowerscurrent/cookie');
  bool isScanning = false;

  void _showLoginError(String trText, String enText) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(localizeTrEn(widget.lang, trText, enText)),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onUrlChange: (change) {
        final url = change.url ?? "";
        if (url.contains("instagram.com/") &&
            !url.contains("login") &&
            !url.contains("accounts/")) {
          if (!isScanning) _startSafeApiProcess();
        }
      }))
      ..loadRequest(Uri.parse('https://www.instagram.com/accounts/login/'));
  }

  Future<void> _startSafeApiProcess() async {
    if (!mounted) return;
    setState(() => isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    try {
      final String? cookieString = await platform
          .invokeMethod('getCookies', {'url': "https://www.instagram.com/"});
      if (cookieString == null || cookieString.trim().isEmpty) {
        if (mounted) setState(() => isScanning = false);
        _showLoginError(
          'Çerez alınamadı. Lütfen tekrar giriş yapın.',
          'Could not read cookies. Please log in again.',
        );
        return;
      }
      final String dsUserId =
          _extractCookieValue(cookieString, 'ds_user_id').trim();
      String? resolvedUserId = dsUserId.isNotEmpty ? dsUserId : null;
      final String sessionId =
          _extractCookieValue(cookieString, 'sessionid').trim();
      if (sessionId.isEmpty) {
        if (mounted) setState(() => isScanning = false);
        _showLoginError(
          'Oturum çerezi eksik. Lütfen Instagram girişini tekrar yapın.',
          'Session cookie is missing. Please log in to Instagram again.',
        );
        return;
      }
      String? username;
      bool sessionValidated = false;
      final dynamic userAgentResult =
          await _controller.runJavaScriptReturningResult('navigator.userAgent');
      String userAgent = userAgentResult is String
          ? userAgentResult
          : userAgentResult.toString();
      userAgent = userAgent.replaceAll('"', '').trim();
      if (userAgent.isEmpty || userAgent.toLowerCase() == 'null') {
        userAgent = _defaultIgUserAgent;
      }
      try {
        final infoResponse = await http.get(
            Uri.parse(
                "https://www.instagram.com/api/v1/accounts/current_user/?edit=true"),
            headers: _buildWebHeaders(cookieString, userAgent));
        if (infoResponse.statusCode == 200) {
          final dynamic parsed = jsonDecode(infoResponse.body);
          if (parsed is Map && parsed['user'] is Map) {
            final Map userData = parsed['user'] as Map;
            sessionValidated = true;
            username = userData['username']?.toString().trim();
            final String pk = userData['pk']?.toString().trim() ?? '';
            if (pk.isNotEmpty) {
              resolvedUserId = pk;
            }
          }
        }
      } catch (_) {}
      if (username == null || username.isEmpty || resolvedUserId == null) {
        final String targetUserId = (resolvedUserId ?? dsUserId).trim();
        if (targetUserId.isEmpty) {
          if (mounted) setState(() => isScanning = false);
          _showLoginError(
            'Oturum bilgisi alınamadı. Lütfen Instagram girişini tekrar yapın.',
            'Session data is missing. Please log in to Instagram again.',
          );
          return;
        }
        try {
          final appInfoResponse = await http.get(
            Uri.parse(
                "https://i.instagram.com/api/v1/users/$targetUserId/info/"),
            headers: _buildAppHeaders(cookieString, userAgent,
                dsUserId: targetUserId),
          );
          if (appInfoResponse.statusCode == 200) {
            final dynamic parsed = jsonDecode(appInfoResponse.body);
            if (parsed is Map && parsed['user'] is Map) {
              final Map userData = parsed['user'] as Map;
              sessionValidated = true;
              username = userData['username']?.toString().trim();
              final String pk = userData['pk']?.toString().trim() ?? '';
              if (pk.isNotEmpty) {
                resolvedUserId = pk;
              } else if (resolvedUserId == null || resolvedUserId.isEmpty) {
                resolvedUserId = targetUserId;
              }
            }
          }
        } catch (_) {}
      }
      if (!sessionValidated ||
          resolvedUserId == null ||
          resolvedUserId.trim().isEmpty) {
        if (mounted) setState(() => isScanning = false);
        _showLoginError(
          'Oturum doğrulanamadı. Lütfen tekrar giriş yapın.',
          'Session verification failed. Please log in again.',
        );
        return;
      }
      if (mounted)
        Navigator.pop(context, {
          "status": "success",
          "cookie": cookieString,
          "user_id": resolvedUserId.trim(),
          "username":
              username ?? (localizeTrEn(widget.lang, "Kullanıcı", "User")),
          "user_agent": userAgent
        });
    } catch (e) {
      if (mounted) setState(() => isScanning = false);
      _showLoginError(
        'Oturum doğrulaması sırasında bir hata oluştu.',
        'An error occurred while verifying the session.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: widget.isDark ? Colors.black : Colors.white,
        appBar: AppBar(
            title: Text(localizeTrEn(widget.lang, 'Giriş Yap', 'Login')),
            backgroundColor:
                widget.isDark ? const Color(0xFF121212) : Colors.white,
            foregroundColor: widget.isDark ? Colors.white : Colors.black),
        body: isScanning
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isDark ? Colors.white : Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                        localizeTrEn(
                            widget.lang,
                            'Oturum doğrulandı, yönlendiriliyorsunuz...',
                            'Session verified, redirecting...'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ))
                  ]))
            : WebViewWidget(controller: _controller));
  }
}


