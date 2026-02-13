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
import 'purchases_service.dart';
import 'telemetry_service.dart';

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
const MethodChannel _cookieChannel =
    MethodChannel('com.grkmcomert.unfollowerscurrent/cookie');
const MethodChannel _reviewChannel =
    MethodChannel('com.grkmcomert.unfollowerscurrent/review');

Future<void> _waitForUmpConsentFlow() async {
  if (_umpConsentFlowCompleter.isCompleted) return;
  try {
    await _umpConsentFlowCompleter.future
        .timeout(const Duration(seconds: 12));
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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
    await Firebase.initializeApp();
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
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);
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
      debugPrint("Timezone hatası: $e");
    }

    try {
      await _initNotifications();
    } catch (e) {
      debugPrint("Bildirim başlatma hatası: $e");
    }

    try {
      await _fetchConfig();
    } catch (e) {
      debugPrint("Config Hatası: $e");
      _debugError = "Bağlantı Hatası: $e";
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

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
      }

      messaging.onTokenRefresh.listen((t) {
        debugPrint("FCM Token Refresh: $t");
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        if (notification == null) return;

        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_default_channel',
              'FCM Notifications',
              channelDescription: 'Foreground FCM notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      });
    } catch (e) {
      debugPrint("FCM init error: $e");
    }
  }

  Future<void> _scheduleDailyNotification() async {
    try {
      final String locale = Platform.localeName;
      final bool isTr = locale.toLowerCase().startsWith('tr');
      final String title = isTr ? 'Analiz Vakti!' : 'Analysis Time!';
      final String body = isTr
          ? 'Verileri güncelleme zamanı! Takipçi listendeki değişiklikleri görmek için şimdi analiz et.'
          : 'Time to update data! Analyze now to see changes in your follower list.';
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      for (int i = 0; i < _dailyReminderDaysToSchedule; i++) {
        await flutterLocalNotificationsPlugin.cancel(_dailyReminderBaseId + i);
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
            _dailyReminderBaseId + i,
            title,
            body,
            scheduleAt,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_analysis_channel',
                'Daily Analysis',
                channelDescription: 'Daily reminder to check followers',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
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
      await remoteConfig.setDefaults({
        "show_real_app": false,
        "app_enabled": true
      });
      await remoteConfig.fetchAndActivate();
      _showRealApp = remoteConfig.getBool('show_real_app');
      _isAppEnabled = remoteConfig.getBool('app_enabled');
      await _checkForcedUpdate(remoteConfig);
    } catch (e) {
      _showRealApp = false;
      _isAppEnabled = true;
      _debugError = "Config Error: $e";
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
        final String locale = Platform.localeName;
        final bool isTr = locale.toLowerCase().startsWith('tr');
        _updateMessage = isTr
            ? 'Yeni güncelleme mevcut! Lütfen mağazayı kontrol edin.'
            : 'A new update is available. Please check the store.';
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
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: ModernLoader(text: "VERDICT Başlatılıyor...")),
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
    final String bodyText = message.isNotEmpty
        ? message
        : "İyi haber! Güncelleme mevcut. Mağazamızı kontrol edip yeni sürümü indir!";
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
                        "İyi haber! Güncelleme mevcut",
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
                          child: const Text("KAPAT",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12)),
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
              Text("SİSTEM BAKIMDA",
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
    'tr': "Eyfel Kulesi yaz aylarında genleşme nedeniyle yaklaşık 15 santimetre kadar uzayabilir.",
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
    'en':
        'Honeybees can recognize human faces and remember them individually.',
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

class _ModernLoaderState extends State<ModernLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _factRand = Random();
  Timer? _factTimer;
  int _factIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 550), vsync: this)
          ..repeat();
    _startFactRotationIfNeeded();
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    _controller.dispose();
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

    final bool isTr = widget.lang.toLowerCase() == 'tr';
    final String label = isTr ? 'BUNU BİLİYOR MUYDUNUZ?' : 'DID YOU KNOW?';
    final Map<String, String> fact =
        _analysisDidYouKnowFacts[_factIndex % _analysisDidYouKnowFacts.length];
    final String body =
        (fact[isTr ? 'tr' : 'en'] ?? fact['en'] ?? '').trim();
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
    const double barHeight = 6;
    const double catWidth = 46;
    const double catHeight = 28;
    const double totalHeight = 44;
    const double barTop = 32;
    final Color catBase =
        widget.isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(builder: (context, constraints) {
        final double maxX = max(0.0, constraints.maxWidth - catWidth);
        final double x = (maxX * clamped).clamp(0.0, maxX);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: barTop,
              child: LinearProgressIndicator(
                value: clamped,
                backgroundColor: accent.withOpacity(0.18),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: barHeight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Positioned(
              left: x,
              top: barTop - catHeight + 2,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final double t = _controller.value;
                  final double bob = -1.2 * sin(t * 2 * pi);
                  final double tilt = 0.03 * sin(t * 2 * pi);
                  return Transform.translate(
                    offset: Offset(0, bob),
                    child: Transform.rotate(
                      angle: tilt,
                      child: CustomPaint(
                        size: const Size(catWidth, catHeight),
                        painter: _CatWalkerPainter(
                          phase: t,
                          baseColor: catBase,
                          accentColor: accent,
                          isDark: widget.isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isDark ? Colors.white : Colors.blueGrey;
    final Color textColor =
        widget.isDark ? Colors.white : Colors.blueGrey.shade800;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
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
                final Color accent = widget.isDark ? Colors.blueAccent : Colors.blue;
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

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.35 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final Rect shadowRect =
        Rect.fromCenter(center: Offset(w * 0.50, groundY + 1), width: w * 0.55, height: 6);
    canvas.drawOval(shadowRect, shadowPaint);

    final Rect bodyBounds = Rect.fromLTWH(10, 11, w - 22, 11);
    final RRect body = RRect.fromRectAndRadius(bodyBounds, const Radius.circular(7));

    final Color dark = _mix(baseColor, Colors.black, isDark ? 0.05 : 0.18);
    final Color light = _mix(baseColor, Colors.white, isDark ? 0.14 : 0.08);
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [light, dark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRRect(body, bodyPaint);

    final Paint outline = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.35 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(body, outline);

    final Offset headCenter = Offset(w - 12.2, 13.2);
    const double headR = 6.7;
    final Rect headRect =
        Rect.fromCircle(center: headCenter, radius: headR);
    final Paint headPaint = Paint()
      ..shader = LinearGradient(
        colors: [_mix(light, Colors.white, 0.10), _mix(dark, Colors.black, 0.06)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(headRect);
    canvas.drawCircle(headCenter, headR, headPaint);
    canvas.drawCircle(headCenter, headR, outline);

    final Path ear1 = Path()
      ..moveTo(headCenter.dx - 3.8, headCenter.dy - 5.8)
      ..lineTo(headCenter.dx - 1.2, headCenter.dy - 9.2)
      ..lineTo(headCenter.dx + 0.6, headCenter.dy - 5.4)
      ..close();
    final Path ear2 = Path()
      ..moveTo(headCenter.dx + 0.4, headCenter.dy - 5.4)
      ..lineTo(headCenter.dx + 2.4, headCenter.dy - 9.0)
      ..lineTo(headCenter.dx + 4.7, headCenter.dy - 5.4)
      ..close();
    canvas.drawPath(ear1, headPaint);
    canvas.drawPath(ear2, headPaint);
    canvas.drawPath(ear1, outline);
    canvas.drawPath(ear2, outline);

    final Paint eye = Paint()..color = _mix(baseColor, Colors.white, isDark ? 0.10 : 0.04);
    canvas.drawCircle(Offset(headCenter.dx + 2.3, headCenter.dy - 0.6), 0.8, eye);

    final double tailWiggle = 1.6 * sin(t * 2 * pi + pi / 3);
    final Path tail = Path()
      ..moveTo(bodyBounds.left + 1.4, bodyBounds.top + 6.5)
      ..quadraticBezierTo(
        bodyBounds.left - 7.5,
        bodyBounds.top + 2.0 + tailWiggle,
        bodyBounds.left - 4.0,
        bodyBounds.top - 3.2 + tailWiggle,
      )
      ..quadraticBezierTo(
        bodyBounds.left - 2.5,
        bodyBounds.top - 6.2 + tailWiggle,
        bodyBounds.left + 1.6,
        bodyBounds.top - 4.6 + tailWiggle,
      );
    final Paint tailPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tail, tailPaint);
    canvas.drawPath(
      tail,
      outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    final double legMaxH = 8.0;
    final double legMinH = 4.6;
    final double baseline = groundY;

    double legLift(double phaseOffset) {
      final double s = sin(t * 2 * pi + phaseOffset);
      return (s + 1.0) / 2.0;
    }

    final double liftA = legLift(0);
    final double liftB = legLift(pi);

    final List<double> legXs = [
      bodyBounds.left + 4.5,
      bodyBounds.left + 10.0,
      bodyBounds.left + 15.5,
      bodyBounds.left + 21.0,
    ];
    final List<double> lifts = [liftA, liftB, liftB, liftA];
    final Paint legPaint = Paint()..color = baseColor;

    for (int i = 0; i < legXs.length; i++) {
      final double lift = lifts[i];
      final double legH = legMaxH - ((legMaxH - legMinH) * lift);
      final Rect r = Rect.fromLTWH(legXs[i], baseline - legH, 3.0, legH);
      final RRect rr = RRect.fromRectAndRadius(r, const Radius.circular(1.2));
      canvas.drawRRect(rr, legPaint);
    }

    final double collarPulse = 0.30 + (0.12 * (0.5 + 0.5 * walk));
    final Paint collar = Paint()..color = accentColor.withOpacity(collarPulse);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(headCenter.dx - 6.2, headCenter.dy + 3.9, 10.0, 2.2),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bio Planner"),
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

class UnfollowersApp extends StatelessWidget {
  const UnfollowersApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
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

  String _lang = 'tr';

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _bannerAdError;
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

  static const bool _forceTestAds = false;
  static const Duration _igRequestTimeout = Duration(seconds: 12);
  static const Duration _igRetryBaseDelay = Duration(milliseconds: 700);
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
  bool _watchStoriesEnabled = false;
  bool _isPremium = false;

  bool get _adsDisabled => _adsHidden || _removeAllAds || _isPremium;

  Future<void> _loadStoryTray() async {
    if (!isLoggedIn || savedCookie == null || _isStoryTrayLoading) return;
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

      Future<http.Response> fetchWeb() => _igGet(
            Uri.parse("https://www.instagram.com/api/v1/feed/reels_tray/"),
            headers: _buildWebHeaders(savedCookie!, ua, dsUserId: savedUserId),
            minGap: const Duration(milliseconds: 240),
            jitterMaxMs: 220,
          );
      Future<http.Response> fetchApp() => _igGet(
            Uri.parse("https://i.instagram.com/api/v1/feed/reels_tray/"),
            headers: _buildAppHeaders(savedCookie!, appUa, dsUserId: savedUserId),
            minGap: const Duration(milliseconds: 240),
            jitterMaxMs: 220,
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

          final String pic = user['profile_pic_url']?.toString().trim() ?? '';
          if (pic.isNotEmpty) pics[uname] = _normalizeProfileImageUrl(pic);
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
      'tagline': 'Professional Social Media Solutions',
      'adsense_banner': 'REKLAM ALANI',
      'admin_active_note': 'Adminlik aktif',
      'free_app_note':
          'Size daha iyi bir deneyim sunmak için her gün gelişiyoruz. Görüşleriniz bizim için değerli, geri bildirimlerinizi bekliyoruz!',
      'login_prompt': 'Analizi başlatmak için lütfen giriş yapınız.',
      'welcome': 'Hoş geldiniz, {username}',
      'refresh_data': 'VERİLERİ GÜNCELLE',
      'login_with_instagram': 'INSTAGRAM İLE GİRİŞ YAP',
      'fetching_data': 'Veriler analiz ediliyor...\nBu işlem biraz sürebilir.',
      'processing_data': 'Veriler işleniyor...\nNeredeyse bitti.',
      'loading_ad': 'Reklam yükleniyor...\nLütfen bekleyin.',
      'analysis_secure':
          'Analiz işlemleri güvenli bir şekilde cihazınızda gerçekleştirilmektedir.',
      'purchases_not_configured':
          'Satın alma sistemi hazır değil. Lütfen daha sonra tekrar deneyin.',
      'premium_not_active':
          'Satın alma tamamlandı ancak Premium aktif görünmüyor. Lütfen tekrar deneyin.',
      'restore_purchases': 'Satın Alımları Geri Yükle',
      'restore_purchases_short': 'GERİ YÜKLE',
      'restoring_purchases': 'Satın alımlar geri yükleniyor...',
      'restore_purchases_success': 'Satın alımlar geri yüklendi ✅',
      'restore_purchases_none': 'Geri yüklenecek satın alım bulunamadı.',
      'restore_purchases_failed': 'Geri yükleme başarısız: {err}',
      'next_analysis': 'Sonraki analiz',
      'next_analysis_ready': 'Analiz şu anda yapılabilir.',
      'analysis_available_now': 'Şu an analiz yapılabilir',
      'analysis_ready_risk':
          'Şu an analiz yapılabilir fakat art arda analiz yapmak hesabınızı riske atabilir.',
      'please_wait': 'Lütfen bekleyiniz',
      'warning': 'Uyarı',
      'remaining_time': 'Kalan süre: {time}',
      'watch_ad': 'REKLAM İZLE VE ANALİZİ BAŞLAT',
      'start_analysis': 'ANALİZİ BAŞLAT',
      'start_analysis_question': 'Analizi başlat?',
      'clear_data_title': 'Veri Sıfırlama',
      'clear_data_content':
          'Tüm yerel veriler ve oturum bilgileri silinecektir. Emin misiniz?',
      'cancel': 'İPTAL',
      'delete': 'SİL',
      'error_title': 'HATA',
      'data_fetch_error': 'Veri çekilemedi: {err}\n\nÇözüm: Çıkış yapıp tekrar giriş deneyin.',
      'followers': 'Takipçiler',
      'following': 'Takip Ettiklerin',
      'new_followers': 'Yeni Takipçiler',
      'non_followers': 'Geri Takip Etmeyenler',
      'left_followers': 'Takibi Bırakanlar',
      'left_following': 'Takipten Çıkardıklarım',
      'legal_warning': 'Yasal Uyarı',
      'rate_us': 'Bizi Puanla',
      'rate_test_message': 'Bu kutucuk şu anda test aşamasındadır.',
      'story_section_title': 'Hikayeleri Gizlice İzle veya Profil Fotoğraflarını Büyüt',
      'story_login_required':
          'Hikayeleri gizli bir şekilde izlemek için lütfen giriş yapınız.',
      'story_ad_wait': 'Reklamdan sonra gösterilecektir, lütfen bekleyiniz.',
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
          "VERDICT, 'istemci taraflı' (client-side) çalışan bir yazılımdır. Kullanıcının giriş bilgileri (kullanıcı adı, şifre, session cookies) hiçbir surette harici bir sunucuya iletilmez veya depolanmaz. Tüm veri işleme faaliyetleri, münhasıran kullanıcının cihazının geçici belleğinde (RAM) ve yerel depolama alanında gerçekleşir. Uygulama, Instagram arayüzü üzerinde çalışan bir 'tarayıcı katmanı' (browser-wrapper) olarak işlev görür.",
      'article2_title': 'Madde 2: Üçüncü Taraf Platform Riskleri',
      'article2_text':
          "Instagram (Meta Platforms, Inc.), platform politikaları gereği üçüncü taraf yazılımların kullanımını kısıtlama hakkını saklı tutar. Uygulamanın kullanımına bağlı olarak gelişebilecek 'işlem engeli' (action block), 'hesap kısıtlaması', 'gölge yasaklama' (shadowban) veya 'hesap kapatılması' dahil ancak bunlarla sınırlı olmamak üzere tüm riskler münhasıran Kullanıcı'ya aittir. VERDICT geliştiricisi, bu tür idari yaptırımlardan dolayı doğabilecek doğrudan veya dolaylı zararlardan sorumlu tutulamaz.",
      'article3_title': 'Madde 3: Garanti Feragatnamesi ve Sorumluluk Reddi',
      'article3_text':
          "İşbu yazılım, 'OLDUĞU GİBİ' (AS-IS) ve 'MEVCUT HALİYLE' sunulmaktadır. Yazılımın sağladığı analiz sonuçlarının %100 kesinliği, sürekliliği veya ticari elverişliliği garanti edilmez. Kullanıcı, uygulama verilerine dayanarak gerçekleştireceği hukuki veya ticari işlemlerden doğabilecek sonuçların kendi sorumluluğunda olduğunu; geliştiriciyi her türlü talep, dava ve şikayetten ari tutacağını beyan ve taahhüt eder.",
      'article4_title': 'Madde 4: Fikri Mülkiyet ve Bağımsızlık Bildirimi',
      'article4_text':
          "VERDICT, bağımsız bir geliştirici projesidir. 'Instagram', 'Facebook' ve 'Meta' markaları Meta Platforms, Inc.'in tescilli ticari markalarıdır. Bu uygulamanın söz konusu şirketlerle herhangi bir ticari ortaklığı, sponsorluk anlaşması veya resmi bağlantısı bulunmamaktadır.",
      'article5_title': 'Madde 5: Hizmet Sürekliliği ve Platform Değişiklikleri',
      'article5_text':
          "Instagram API’sinde veya web altyapısında meydana gelebilecek köklü değişiklikler, uygulamanın işlevselliğini kısmen veya tamamen yitirmesine neden olabilir. Geliştirici, 'mücbir sebep' (force majeure) olarak kabul edilen bu tür altyapısal değişikliklere bağlı olarak uygulamayı güncelleme veya hizmeti sürdürme konusunda herhangi bir taahhütte bulunmamaktadır.",
      'ad_wait_message':
          'Analiz tamamlandı, sonuçlar reklamdan sonra gösterilecek.',
      'rate_title': 'Memnun Kaldın mı?',
      'rate_content': 'Uygulamanın gelişmesi ve sürdürülebilirliği için bize mağazadan puan verebilir misin?',
      'rate_button': 'MAĞAZAYA GİT',
      'later': 'SONRA',
      'analysis_failed_title': 'Analiz yapılamadı',
      'analysis_failed_reason': 'Neden: {reason}',
      'analysis_failed_hint':
          'Tavsiye: Çıkış yapıp tekrar giriş yapmanız fayda sağlayabilir.',
      'analysis_fast_no_change':
          'Hızlı kontrol: Herhangi bir değişiklik tespit edilmedi.',
      'usage_metrics_title': 'Günlük Veriler',
      'usage_metrics_active': 'Aktif kullanıcı',
      'usage_metrics_queries': 'Günlük sorgu',
      'usage_metrics_na': '--',
      'usage_metrics_live': 'canlı panel'
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
      'analysis_secure':
          'All analysis is securely processed locally on your device.',
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
      'non_followers': 'Don\'t Follow Back',
      'left_followers': 'Unfollowers',
      'legal_warning': 'Legal Disclaimer',
      'left_following': 'Unfollowed Users',
      'rate_us': 'Rate Us',
      'Bize Ulaşın': 'Contact Us',
      'Tüm Reklam Birimlerini ve Bekleme Sürelerini Kaldır':
          'Remove Ads & Wait Times',
      'rate_test_message': 'This box is currently under test.',
      'story_section_title': 'Watch Stories Secretly or Zoom Profile Photos',
      'story_login_required':
          'Please log in to watch stories secretly.',
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
      'redirecting': 'Session verified, redirecting securely...',
      'data_updated': 'Analysis complete ✅',
      'purchases_not_configured':
          'Purchases are not available right now. Please try again later.',
      'premium_not_active':
          'Purchase completed, but Premium is not active yet. Please try again.',
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
      'article1_title': 'Article 1: Data Privacy and Local Processing Architecture',
      'article1_text':
          "VERDICT is 'client-side' software. The User's login credentials (username, password, session cookies) are under no circumstances transmitted to or stored on an external server. All data processing activities occur exclusively within the temporary memory (RAM) and local storage of the User's device. The application functions as a 'browser-wrapper' operating over the Instagram interface.",
      'article2_title': 'Article 2: Third-Party Platform Risks',
      'article2_text':
          "Instagram (Meta Platforms, Inc.) reserves the right to restrict the use of third-party software per its platform policies. All risks, including but not limited to 'action blocks', 'account restrictions', 'shadowbans', or 'account closures' that may arise from the use of the application, belong exclusively to the User. The VERDICT developer cannot be held liable for any direct or indirect damages resulting from such administrative sanctions.",
      'article3_title': 'Article 3: Warranty Disclaimer and Limitation of Liability',
      'article3_text':
          "This software is provided 'AS-IS' and 'AS AVAILABLE'. The 100% accuracy, continuity, or merchantability of the analysis results provided by the software is not guaranteed. The User acknowledges that any results arising from legal or commercial transactions based on application data are their own responsibility; and declares and undertakes to hold the developer harmless from all claims, lawsuits, and complaints.",
      'article4_title': 'Article 4: Intellectual Property and Independence Notice',
      'article4_text':
          "VERDICT is an independent developer project. The 'Instagram', 'Facebook', and 'Meta' brands are registered trademarks of Meta Platforms, Inc. This application has no commercial partnership, sponsorship agreement, or official affiliation with the aforementioned companies.",
      'article5_title': 'Article 5: Service Continuity and Platform Changes',
      'article5_text':
          'Fundamental changes to the Instagram API or web infrastructure may cause the application to lose its functionality partially or completely. The developer makes no commitment to update the application or maintain the service in response to such infrastructural changes, which are considered "force majeure".',
      'ad_wait_message':
          'Analysis complete, results will be shown after the ad.',
      'rate_title': 'Did you enjoy it?',
      'rate_content':
          'Would you mind rating us on the store to support the app?',
      'rate_button': 'GO TO STORE',
      'later': 'LATER',
      'analysis_failed_title': 'Analysis failed',
      'analysis_failed_reason': 'Reason: {reason}',
      'analysis_failed_hint':
          'Tip: Logging out and logging back in may help.',
      'analysis_fast_no_change':
          'Quick check: Counts are the same. No changes detected.',
      'usage_metrics_title': 'Daily Metrics',
      'usage_metrics_active': 'Active users',
      'usage_metrics_queries': 'Daily queries',
      'usage_metrics_na': '--',
      'usage_metrics_live': 'live panel'
    }
  };

  String _t(String key, [Map<String, String>? args]) {
    String res = _localized[_lang]?[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        res = res.replaceAll('{$k}', v);
      });
    }
    return res;
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pref = prefs.getString('language_code');
    if (pref != null) {
      if (mounted) setState(() => _lang = pref);
      return;
    }
    try {
      final String locale = Platform.localeName;
      if (locale.toLowerCase().startsWith('tr')) {
        if (mounted) setState(() => _lang = 'tr');
      } else {
        if (mounted) setState(() => _lang = 'en');
      }
    } catch (_) {
      if (mounted) setState(() => _lang = 'en');
    }
  }

  Future<void> _setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    if (mounted) setState(() => _lang = code);
  }

  void _toggleLanguage() {
    _setLanguage(_lang == 'tr' ? 'en' : 'tr');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PurchasesService.instance.isPremium.addListener(_onPremiumChanged);
    _isPremium = PurchasesService.instance.isPremium.value;
    _storyScrollController = ScrollController();
    _loadStoredData();
    _loadLanguagePreference();
    _tryAutoLogin();
    _loadRemoteUserFlags();
    _updatePrivacyOptionsRequirement();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkUserAgreement();
      _checkRatingDialog();
      _maybeLoadBannerAfterConsent();
      _maybeRequestATT();
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
      });
    } else {
      _isAdLoaded = false;
      _bannerAdError = null;
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
      final String bannedRaw =
          remoteConfig.getString('bannedusers').trim();
      final String removeAdsRaw =
          remoteConfig.getString('removeadsfor').trim();
      final bool removeAllAds = remoteConfig.getBool('removeallads');
      final bool watchStories =
          remoteConfig.getBool('watchstoriessecretly');
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
    } catch (_) {} finally {
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
     final prefs = await SharedPreferences.getInstance();
     int count = prefs.getInt('app_launch_count') ?? 0;
     bool hasRated = prefs.getBool('has_rated_app') ?? false;

     if (count == 2 && !hasRated) {
        _showRateDialog();
     }
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(_t('rate_title'), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
          ],
        ),
        content: Text(_t('rate_content'), style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text(_t('later'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.blueAccent,
               foregroundColor: Colors.white,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
             ),
             onPressed: () async {
               final prefs = await SharedPreferences.getInstance();
               await prefs.setBool('has_rated_app', true);
               Navigator.pop(ctx);
               await _launchRateUrl();
             },
             child: Text(_t('rate_button')),
          )
        ],
      )
    );
  }

  Future<void> _launchRateUrl() async {
    if (Platform.isIOS) {
      try {
        await _reviewChannel.invokeMethod('requestReview');
      } catch (_) {}
      return;
    }

    final String rawUrl = Platform.isIOS ? _rateUrlIos : _rateUrlAndroid;
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _lang == 'tr' ? 'Mağaza linki bulunamadı.' : 'Store link not set.'),
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
          content: Text(
              _lang == 'tr' ? 'Geçersiz mağaza linki.' : 'Invalid store link.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_lang == 'tr'
              ? 'Link açılamadı.'
              : 'Could not open the link.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _restorePurchasesPressed() async {
    if (isProcessing) return;

    await PurchasesService.instance.configure(
      androidApiKey: _revenueCatAndroidApiKey,
      iosApiKey: _revenueCatIosApiKey,
    );

    if (!PurchasesService.instance.isConfigured) {
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
      final String err = _lang == 'tr'
          ? 'Lütfen tekrar deneyin.'
          : 'Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('restore_purchases_failed', {'err': err})),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('restore_purchases_success')),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green.shade700,
      ));
      return;
    }

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
            });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint("Banner Ad Failed: $err");
          ad.dispose();
          if (mounted)
            setState(() {
              _isAdLoaded = false;
              _bannerAdError = err.message;
            });
        },
      ),
    );

    try {
      await _bannerAd!.load();
    } catch (e) {
      if (kDebugMode) print('Ad load error: $e');
    }
  }

  Future<Map<String, dynamic>> _showRewardedAdWithResult(
      {String? adUnitOverride}) async {
    if (_adsDisabled) return {"status": true, "skipped": true};
    if (_isRewardedLoading) {
      return {
        "status": false,
        "error": _lang == 'tr' ? 'Yükleniyor...' : 'Loading...',
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
              if (!c.isCompleted) {
                c.complete({
                  "status": false,
                  "error": _lang == 'tr'
                      ? "Gösterim hatası: ${err.message}"
                      : "Show error: ${err.message}",
                });
              }
            },
          );
          try {
            ad.show();
          } catch (e) {
            if (!c.isCompleted) {
              c.complete({
                "status": false,
                "error": _lang == 'tr' ? "Hata: $e" : "Exception: $e",
              });
            }
          }
        },
        onAdFailedToLoad: (LoadAdError err) {
          debugPrint("Ad failed to load: $err");
          if (!c.isCompleted) {
            c.complete({
              "status": false,
              "error": _lang == 'tr'
                  ? "Yükleme hatası: ${err.message} (Kod: ${err.code})"
                  : "Load error: ${err.message} (Code: ${err.code})",
            });
          }
        },
      ),
    );

    Map<String, dynamic> result = {
      "status": false,
      "error": _lang == 'tr' ? "Zaman aşımı" : "Timeout",
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
      try {
        if (mounted) {
          setState(() {
            _justWatchedReward = true;
          });
        }
      } catch (_) {}
      unawaited(TelemetryService.instance.recordRewardedAdWatched());
    }
    return result;
  }

  Future<DateTime> _getEstimatedNetworkTime() async {
    if (_networkTimeOffsetMs != null) {
      return DateTime.now()
          .add(Duration(milliseconds: _networkTimeOffsetMs!));
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
          .head(Uri.parse('https://raw.githubusercontent.com/grkmcomert/verdict-web/refs/heads/main/privacy-policy.txt'))
          .timeout(const Duration(seconds: 2));
      final String? dateHeader = response.headers['date'];
      if (dateHeader != null) {
        final DateTime networkTime = HttpDate.parse(dateHeader).toLocal();
        final DateTime localNow = DateTime.now();
        final int offsetMs =
            networkTime.difference(localNow).inMilliseconds;
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

  Future<void> _incrementFirestoreCounter(String counterName) async {
    try {
      final String today = DateTime.now().toString().substring(0, 10);
      await FirebaseFirestore.instance
          .collection('daily_stats')
          .doc(today)
          .set({
            counterName: FieldValue.increment(1),
            'last_updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      debugPrint('[Firestore] $counterName incremented');
    } catch (e, st) {
      debugPrint('[Firestore] $counterName increment failed: $e');
      debugPrint('$st');
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

  Future<void> _forceWriteIgUserDoc({
    required String userId,
    required String username,
  }) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty || cleanUserId == 'null') return;

    String version = '7.0.1';
    try {
      final info = await PackageInfo.fromPlatform();
      final String v = info.version.trim();
      if (v.isNotEmpty) version = v;
    } catch (_) {}

    try {
      final docRef =
          FirebaseFirestore.instance.collection('ig_users').doc(cleanUserId);
      await docRef.set({
            'username': username,
            'userId': cleanUserId,
            'platform': Platform.isAndroid ? 'android' : 'ios',
            'is_premium': PurchasesService.instance.isPremium.value,
            'last_seen': FieldValue.serverTimestamp(),
            'version': version,
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      try {
        await docRef
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
      debugPrint('[ForceWrite] ig_users/$cleanUserId written');
      try {
        FirebaseCrashlytics.instance.log('ForceWrite ig_users/$cleanUserId ok');
      } catch (_) {}
    } catch (e, st) {
      debugPrint('[ForceWrite] ig_users/$cleanUserId write failed: $e');
      debugPrint('$st');
      try {
        unawaited(FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'forceWriteIgUserDoc:$cleanUserId',
          fatal: false,
        ));
      } catch (_) {}
    }
  }

  Future<void> _forceWriteTestLog(String event) async {
    try {
      final docRef =
          await FirebaseFirestore.instance.collection('test_logs').add({
        'event': event,
        'at': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'userId': (savedUserId ?? '').trim(),
        'username': currentUsername,
      }).timeout(const Duration(seconds: 10));
      try {
        await docRef
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
      debugPrint('[ForceWrite] test_logs written ($event)');
      try {
        FirebaseCrashlytics.instance.log('ForceWrite test_logs ok ($event)');
      } catch (_) {}
    } catch (e, st) {
      debugPrint('[ForceWrite] test_logs write failed: $e');
      debugPrint('$st');
      try {
        unawaited(FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'forceWriteTestLog:$event',
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
              content: Text(
                  _t('remaining_time', {'time': _formatDuration(remaining)})),
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
        title: Text(_t('clear_data_title'), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: Text(_t('clear_data_content'), style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('delete'), style: const TextStyle(color: Colors.red))),
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
      final String? cookieString = await _cookieChannel
          .invokeMethod<String>('getCookies', {'url': 'https://www.instagram.com/'});
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
      final String fromCookie = _extractCookieValue(cookie, 'ds_user_id').trim();
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
        isDarkMode =
            hasPref ? (prefs.getBool('is_dark_mode') ?? systemDark) : systemDark;
      });
    }
    if (cookie != null && userId != null) {
      final String fallback = _lang == 'tr' ? 'Kullanıcı' : 'User';
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
      unawaited(TelemetryService.instance.recordLogin(
        userId: userId,
        username: currentUsername,
        isPremium: PurchasesService.instance.isPremium.value,
      ));
      unawaited(_incrementFirestoreCounter('login_count'));
      unawaited(_forceWriteIgUserDoc(userId: userId, username: currentUsername));
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

  Future<void> _launchPrivacyPolicyURL() async {
    final Uri url = Uri.parse('https://raw.githubusercontent.com/grkmcomert/verdict-web/refs/heads/main/privacy-policy.txt');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       debugPrint("Link açılamadı");
    }
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
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
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
                        color:
                            isDarkMode ? Colors.white : Colors.black87)),
                content: Text(_t('withdraw_consent_confirm_body'),
                    style: TextStyle(
                        color:
                            isDarkMode ? Colors.white70 : Colors.black87)),
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
        content: Text(_lang == 'tr'
            ? 'Rıza formu açılıyor...'
            : 'Opening consent form...'),
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
      ok = status == ConsentStatus.obtained || status == ConsentStatus.notRequired;
    } catch (_) {
      ok = false;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (_lang == 'tr'
              ? 'Rıza tercihiniz güncellendi.'
              : 'Your consent preference was updated.')
          : (_lang == 'tr'
              ? 'Rıza güncellenemedi. Lütfen tekrar deneyin.'
              : 'Consent update failed. Please try again.')),
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
                  _lang == 'tr'
                      ? 'Hesabınız engellendi'
                      : 'Your account is blocked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  _lang == 'tr'
                      ? 'Bu hesap için erişim kısıtlandı.'
                      : 'Access is restricted for this account.',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_lang == 'tr' ? 'KAPAT' : 'CLOSE'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  icon: Icon(
                                      isDarkMode
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                      color: headerColor),
                                  onPressed: _toggleDarkMode),
                              IconButton(
                                icon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.language, color: headerColor),
                                      const SizedBox(width: 6),
                                      Text(_lang.toUpperCase(),
                                          style: TextStyle(
                                              color: headerColor,
                                              fontWeight: FontWeight.bold))
                                    ]),
                                onPressed: _toggleLanguage,
                              ),
                              if (_privacyOptionsRequired)
                                IconButton(
                                  icon: Icon(Icons.privacy_tip_outlined,
                                      color: headerColor),
                                  onPressed: _showPrivacyOptionsForm,
                                ),
                            ])),
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
                        Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined,
                                    color: Colors.redAccent),
                                onPressed: (isProcessing || _isClearingData)
                                    ? null
                                    : _clearCache)),
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
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          if (_isAdLoaded && _bannerAd != null)
                            SizedBox(
                              width: _bannerAd!.size.width.toDouble(),
                              height: _bannerAd!.size.height.toDouble(),
                              child: AdWidget(ad: _bannerAd!),
                            )
                          else if (_bannerAdError != null)
                            const SizedBox(height: 50)
                          else
                            const SizedBox(
                                height: 50,
                                child: Center(
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))))
                        ]),
                      ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      if (isLoggedIn && _isAdminUser) ...[
                        _buildInfoBox(Icons.admin_panel_settings,
                            _t('admin_active_note'), primaryColor),
                        const SizedBox(height: 10),
                      ],
                      if (_announcementText.trim().isNotEmpty) ...[
                        _buildInfoBox(
                            Icons.info_outline, _announcementText, primaryColor),
                        const SizedBox(height: 10),
                      ],
                      _buildInfoBox(
                          Icons.info_outline, _t('free_app_note'), primaryColor),
                      const SizedBox(height: 10),
                      if (!isLoggedIn)
                        _buildInfoBox(Icons.lock_outline, _t('login_prompt'),
                            Colors.redAccent)
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
                          height: 330,
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
                        _buildGrid(cardColor, textColor),
                      SizedBox(height: isProcessing ? 10 : 18),
                      if (isProcessing) ...[
                        Text(_t('analysis_secure'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    isDarkMode ? Colors.grey : Colors.blueGrey,
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
              child: _buildBigCard('Bize Ulaşın', "", const Color(0xFFC13584),
                  Icons.chat_bubble_rounded, cardColor, textColor,
                  showCount: false)),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard(
                  'Tüm Reklam Birimlerini ve Bekleme Sürelerini Kaldır',
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
                    height:
                        max(0.0, cardHeight - (miniButtonHeight + miniGap)),
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
          showDialog(
              context: context,
              builder: (ctx) =>
                  _buildDetailedLegalDialog(ctx, isInitial: false));
        } else if (titleKey == 'rate_us') {
          await _launchRateUrl();
        } else if (titleKey == 'Bize Ulaşın') {
          try {
            final Uri url = Uri.parse('https://instagram.com/grkmcomert');
            final bool ok = await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Link açılamadı.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ));
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Link açılamadı.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ));
            }
          }
        } else if (titleKey ==
            'Tüm Reklam Birimlerini ve Bekleme Sürelerini Kaldır') {
          if (PurchasesService.instance.isPremium.value) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_lang == 'tr'
                    ? 'Premium zaten aktif ✅'
                    : 'Premium is already active ✅'),
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
                            _lang == 'tr'
                                ? 'Satın alma başlatılıyor...'
                                : 'Starting purchase...',
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_lang == 'tr'
                  ? 'Satın alma iptal edildi.'
                  : 'Purchase cancelled.'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blueGrey.shade900,
            ));
            return;
          }

          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_lang == 'tr'
                  ? 'Premium aktif ✅ Reklamlar ve bekleme süreleri kapatıldı.'
                  : 'Premium active ✅ Ads and wait times are disabled.'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green.shade700,
            ));
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_lang == 'tr'
                ? 'Satın alma başarısız. Lütfen tekrar deneyin.'
                : 'Purchase failed. Please try again.'),
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
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
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
                        builder: (context) =>
                            InstagramApiPage(isDark: isDarkMode, lang: _lang)));
                if (result is! Map) return;
                final Map<String, dynamic> payload =
                    result.map((k, v) => MapEntry(k.toString(), v));
                final String status =
                    (payload['status'] ?? '').toString().trim().toLowerCase();
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
                : (isLoggedIn ? _t('refresh_data') : _t('login_with_instagram')),
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

      final double cap = (_analysisProgressCap <= 0.0 ? 0.92 : _analysisProgressCap)
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
        final int timeLeftMs = finishEndAt.difference(DateTime.now()).inMilliseconds;
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

    final DateTime deadline = DateTime.now()
        .add(duration + const Duration(milliseconds: 250));
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
    unawaited(_forceWriteTestLog('refresh_data'));
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

    if (startProcessingImmediately && mounted) startProcessingUi();

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
          content: Text(_lang == 'tr'
              ? 'Oturum geçersiz. Lütfen tekrar giriş yapın.'
              : 'Session is invalid. Please log in again.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    final String uaToUse = _resolveUserAgent();

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
                    if (mounted) {
                      final String msg = _lang == 'tr'
                          ? 'Reklam açılamadı. Lütfen tekrar deneyin.'
                          : 'Ad could not be shown. Please try again.';
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
        maxAttempts: 3,
      );

      _setAnalysisProgressCap(0.55);

      // Kullanıcı adını güncelle
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
        _showAnalysisWarning(_lang == 'tr'
            ? 'Instagram veri döndürmedi.'
            : 'Instagram returned no data.');
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
        _showAnalysisWarning(_lang == 'tr'
            ? 'Takipçi verileri eksik geldi.'
            : 'Follower data was incomplete.');
        return;
      }
      if (tFollowing > 0 && fetchedFollowing < (tFollowing * 0.85)) {
        _showAnalysisWarning(_lang == 'tr'
            ? 'Takip edilen verileri eksik geldi.'
            : 'Following data was incomplete.');
        return;
      }

      if (nFollowers.isNotEmpty || nFollowing.isNotEmpty) {
        final bool mustWatchAdToShowResults = !_adsDisabled && !_justWatchedReward;
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
            _showAnalysisWarning(_lang == 'tr'
                ? "Reklam açılamadı. Sonuçlar gösterilemedi."
                : "Ad could not be shown. Results cannot be displayed.");
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
      }
    } catch (e) {
      String reason = _lang == 'tr'
          ? 'Beklenmeyen bir hata oluştu.'
          : 'An unexpected error occurred.';
      final String raw = e.toString();
      if (raw.toLowerCase().contains('ig_warning')) {
        final String igMsg = _extractIgWarningTextFromError(e);
        reason = _lang == 'tr'
            ? 'Instagram bu işlemi geçici olarak kısıtladı. Biraz bekleyip tekrar deneyin.'
            : 'Instagram temporarily restricted this action. Please wait a bit and try again.';
        unawaited(_showIgWarningGuide(igMsg));
      } else
      if (raw.contains('http_401') || raw.contains('http_403')) {
        reason = _lang == 'tr'
            ? 'Oturum süresi doldu veya doğrulama gerekli.'
            : 'Session expired or verification required.';
      } else if (raw.contains('http_429')) {
        reason = _lang == 'tr'
            ? 'Çok hızlı istek gönderildi.'
            : 'Too many requests were sent.';
      } else if (raw.contains('checkpoint_required') ||
          raw.contains('challenge_required')) {
        final String code =
            raw.contains('checkpoint_required') ? 'checkpoint_required' : 'challenge_required';
        reason = _lang == 'tr'
            ? 'Instagram güvenlik doğrulaması istedi (şüpheli giriş / hesap kilidi). Instagram uygulamasından doğrulayın ve tekrar deneyin.'
            : 'Instagram requires a security verification (suspicious login / account lock). Verify in the Instagram app and try again.';
        unawaited(_showIgSecurityVerificationGuide(code));
      } else if (raw.contains('session_invalid')) {
        reason = _lang == 'tr'
            ? 'Instagram oturumu geçersiz veya doğrulama bekliyor.'
            : 'Instagram session is invalid or pending verification.';
      } else if (raw.contains('invalid_json') || raw.contains('invalid_payload')) {
        reason = _lang == 'tr'
            ? 'Instagram beklenmeyen bir yanıt döndürdü.'
            : 'Instagram returned an unexpected response.';
      } else if (raw.contains('http_')) {
        reason = _lang == 'tr'
            ? 'Instagram sunucusu hata döndürdü.'
            : 'Instagram returned an error.';
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
      msg = msg.isEmpty ? cleanFeedbackMessage : '$msg — $cleanFeedbackMessage';
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
    if (allowBreather) {
      _igPageRequestCounter++;
      if (_igPageRequestCounter % 12 == 0) {
        breatherMs = 280 + _storyRand.nextInt(520);
      }
    }

    final int desiredGapMs = minGap.inMilliseconds + jitterMs + breatherMs;
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
    Duration minGap = const Duration(milliseconds: 220),
    int jitterMaxMs = 200,
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
    Duration minGap = const Duration(milliseconds: 410),
    int jitterMaxMs = 280,
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
          final String message = body['message']?.toString().toLowerCase() ?? '';
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
        minGap: const Duration(milliseconds: 410),
        jitterMaxMs: 280,
      );
      final parsed = parseUser(webResp);
      if (parsed != null) return parsed;
    }

    final appResp = await _igGet(
      Uri.parse("https://i.instagram.com/api/v1/users/$userId/info/"),
      headers: _buildAppHeaders(cookie, appUa, dsUserId: userId),
      minGap: const Duration(milliseconds: 410),
      jitterMaxMs: 280,
    );
    final appParsed = parseUser(appResp);
    if (appParsed != null) return appParsed;

    if (!preferWeb) {
      final webResp = await _igGet(
        Uri.parse("https://www.instagram.com/api/v1/users/$userId/info/"),
        headers: _buildWebHeaders(cookie, ua, dsUserId: userId),
        minGap: const Duration(milliseconds: 410),
        jitterMaxMs: 280,
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
    int currentCount = 0;
    String? terminalError;

    void switchEndpointAndReset() {
      triedAlternate = true;
      useWebApi = !useWebApi;
      nextMaxId = null;
      hasNext = true;
      currentCount = 0;
      targetMap.clear();
    }

    while (hasNext) {
      String base = useWebApi
          ? "https://www.instagram.com/api/v1/"
          : "https://i.instagram.com/api/v1/";
      String url = "$base$endpoint";
      if (nextMaxId != null) url += "?max_id=$nextMaxId";

      final response = await _igGet(
        Uri.parse(url),
        headers: useWebApi
            ? _buildWebHeaders(cookie, ua, dsUserId: userId)
            : _buildAppHeaders(cookie, appUa, dsUserId: userId),
        minGap: const Duration(milliseconds: 410),
        jitterMaxMs: 280,
        allowBreather: true,
      );

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
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
          if (!triedAlternate) {
            switchEndpointAndReset();
            continue;
          }
          throw Exception('invalid_json');
        }
        if (decoded is! Map) {
          if (!triedAlternate) {
            switchEndpointAndReset();
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
          if (!triedAlternate) {
            switchEndpointAndReset();
            continue;
          }
          throw Exception(terminalError);
        }

        final String? warning = _detectIgWarningFromMap(data);
        if (warning != null) {
          terminalError = 'ig_warning:$warning';
          throw Exception(terminalError);
        }

        if (status == 'fail') {
          final String rawMsg = data['message']?.toString().trim() ?? '';
          terminalError = rawMsg.isNotEmpty ? 'ig_warning:$rawMsg' : 'ig_warning';
          throw Exception(terminalError);
        }

        final List users = data['users'] is List ? data['users'] : const [];
        for (var u in users) {
          String picUrl = u['profile_pic_url'].toString();
          picUrl = _normalizeProfileImageUrl(picUrl);

          targetMap[u['username'].toString()] = picUrl;
          currentCount++;
        }

        if (onProgress != null) onProgress(currentCount);

        final String? nextCursor = data['next_max_id']?.toString();
        nextMaxId = (nextCursor != null && nextCursor.isNotEmpty)
            ? nextCursor
            : null;
        hasNext = nextMaxId != null;
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
        if (response.statusCode == 401 || response.statusCode == 403) {
          terminalError = 'session_invalid';
        } else if (response.statusCode == 429) {
          terminalError = 'http_429';
        } else {
          terminalError ??= 'http_${response.statusCode}';
        }
        if (!triedAlternate) {
          switchEndpointAndReset();
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
    final String userAgentRaw =
        (payload['user_agent'] ?? '').toString().trim();
    final String userAgent =
        userAgentRaw.isNotEmpty ? userAgentRaw : _defaultIgUserAgent;
    if (cookie.isEmpty || userId.isEmpty || userId == 'null') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_lang == 'tr'
              ? 'Oturum doğrulaması tamamlanamadı. Lütfen tekrar giriş yapın.'
              : 'Session verification failed. Please log in again.'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ));
      }
      return;
    }
    final String username =
        usernameRaw.isNotEmpty ? usernameRaw : (_lang == 'tr' ? 'Kullanıcı' : 'User');

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
    unawaited(_forceWriteIgUserDoc(userId: userId, username: username));
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
    unawaited(_refreshData(startProcessingImmediately: true));
    unawaited(_loadStoryTray());
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
      final double fraction =
          total <= 0 ? 1.0 : (done / total).clamp(0.0, 1.0);
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
    final Map<String, String> storedLeftFollowing = _safeMapCast(
        jsonDecode(prefs.getString('left_following_map') ?? '{}'));
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
        output[key] = _normalizeProfileImageUrl(raw);
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
            child: Text(text,
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
    final bool isTr = _lang == 'tr';
    final bool isCheckpoint = code.toLowerCase().contains('checkpoint');
    final String title = isTr
        ? 'Instagram Doğrulaması Gerekli'
        : 'Instagram Verification Required';
    final String description = isTr
        ? 'Instagram hesabınız için güvenlik doğrulaması gerekiyor (şüpheli giriş bildirimi / geçici kilit). Bu yüzden verileri çekemiyoruz.'
        : 'Instagram requires a security verification for your account (suspicious login / temporary lock). We can’t fetch data until it’s verified.';
    final String typeHint = isTr
        ? (isCheckpoint
            ? 'Bu genelde “hesap kilidi / checkpoint” durumudur.'
            : 'Bu genelde “şüpheli giriş” doğrulamasıdır.')
        : (isCheckpoint
            ? 'This is usually an “account lock / checkpoint”.'
            : 'This is usually a “suspicious login” verification.');
    final String steps = isTr
        ? 'Ne yapmalıyım?\n'
            '1) Instagram uygulamasını açın.\n'
            '2) “Şüpheli giriş” uyarısı varsa “Bu bendim” diyerek doğrulayın.\n'
            '3) Gerekirse şifrenizi değiştirip tekrar giriş yapın.\n'
            '4) Bu uygulamaya dönüp “VERİLERİ GÜNCELLE”ye basın.'
        : 'What to do:\n'
            '1) Open the Instagram app.\n'
            '2) If you see a “Suspicious login” alert, confirm it’s you.\n'
            '3) If needed, change your password and log in again.\n'
            '4) Come back here and tap “REFRESH DATA”.';
    final String hint = isTr
        ? 'Not: Doğrulama sonrası bazen 1–2 dakika beklemek gerekebilir.'
        : 'Note: After verification, you may need to wait 1–2 minutes.';

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
                child: Text(isTr ? 'Kapat' : 'Close')),
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
              child: Text(isTr ? "Instagram'ı Aç" : 'Open Instagram'),
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
    final bool isTr = _lang == 'tr';

    final String title =
        isTr ? 'Instagram Geçici Kısıtlama' : 'Instagram Temporary Restriction';
    final String description = isTr
        ? 'Instagram bu işlemi geçici olarak kısıtladı. Bu genelde çok sık istek / otomatik aktivite algılandığında olur. Veri çekme durduruldu.'
        : 'Instagram temporarily restricted this action. This can happen when requests are too frequent or activity looks automated. We stopped fetching data.';

    final String cleanIg = (() {
      final String v = igMessage.trim();
      final String lower = v.toLowerCase();
      if (lower == 'try_again_later' || lower == 'feedback_required') return '';
      return v;
    })();

    final String igBlock = cleanIg.isEmpty
        ? ''
        : (isTr ? 'Instagram mesajı:\n$cleanIg' : 'Instagram message:\n$cleanIg');

    final String steps = isTr
        ? 'Ne yapabilirsin?\n'
            '1) Instagram uygulamasını aç.\n'
            '2) Bir uyarı/ek doğrulama varsa tamamla.\n'
            '3) 10–30 dakika bekle.\n'
            '4) Bu uygulamaya dönüp tekrar “VERİLERİ GÜNCELLE”ye bas.'
        : 'What you can do:\n'
            '1) Open the Instagram app.\n'
            '2) Complete any alert or verification if shown.\n'
            '3) Wait 10–30 minutes.\n'
            '4) Come back here and tap “REFRESH DATA” again.';

    final String hint = isTr
        ? 'Not: Arka arkaya çok sık analiz yapmak bu uyarıyı tetikleyebilir.'
        : 'Note: Running analyses back-to-back can trigger this.';

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
                child: Text(isTr ? 'Kapat' : 'Close')),
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
              child: Text(isTr ? "Instagram'ı Aç" : 'Open Instagram'),
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
        "${_t('analysis_failed_title')}\n${_t('analysis_failed_reason', {'reason': reason})}\n${_t('analysis_failed_hint')}";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.redAccent,
    ));
  }

  void _ensureStoryAutoScroll() {
    if (!_watchStoriesEnabled) return;
    if (_storyAutoTimer != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || isLoggedIn) return;
      if (!_storyScrollController.hasClients) return;
      _storyAutoTimer = Timer.periodic(const Duration(milliseconds: 1800),
          (timer) {
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
      backgroundColor: Colors.blueGrey.shade900,
    ));
    await Future.delayed(const Duration(seconds: 1));
    final adResult = await _showRewardedAdWithResult(
      adUnitOverride: 'ca-app-pub-7480771330660307/4726353967',
    );
    if (adResult["status"] == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_lang == 'tr'
              ? 'Reklam açılamadı. Lütfen tekrar deneyin.'
              : 'Ad could not be shown. Please try again.'),
          backgroundColor: Colors.red,
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
      final List<_StoryProfile> list = source.entries
          .map((e) {
            final String unameLower = e.key.toLowerCase();
            return _StoryProfile(
                username: e.key,
                imageUrl: e.value,
                hasStory: _storyUsersWithActive.contains(unameLower),
                pk: _storyUserPks[unameLower]);
          })
          .toList();

      final Set<String> seen = source.keys.map((e) => e.toLowerCase()).toSet();
      int added = 0;
      for (final unameLower in _storyUsersWithActive) {
        if (seen.contains(unameLower)) continue;
        if (added >= 25) break;
        final String pic = (_storyUserPics[unameLower] ?? '').trim();
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
    final String fakePrefix = _lang == 'tr' ? 'kullanıcı' : 'user';
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
                _lang == 'tr'
                    ? 'Hikayeler yükleniyor...'
                    : 'Loading stories...',
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
                              color:
                                  isDarkMode ? Colors.white54 : Colors.black54))))
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
                          fontWeight: FontWeight.bold,
                          color: sheetTextColor)),
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
            backgroundColor: Colors.redAccent,
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
            backgroundColor: Colors.redAccent,
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
    try {
      return url.replaceAll(RegExp(r'\/[sp]\d+x\d+\/'), '/');
    } catch (_) {
      return url;
    }
  }

  Future<String?> _fetchHdProfilePhotoUrl(_StoryProfile profile) async {
    if (savedCookie == null) return null;
    final String ua = _resolveUserAgent();
    final String appUa =
        ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;

    Future<String?> fromAppUserId(String userId) async {
      try {
        final response = await http.get(
          Uri.parse("https://i.instagram.com/api/v1/users/$userId/info/"),
          headers: _buildAppHeaders(savedCookie!, appUa, dsUserId: savedUserId),
        );
        if (response.statusCode != 200) return null;
        final data = jsonDecode(response.body);
        if (data is! Map || data['user'] is! Map) return null;
        final user = data['user'] as Map;
        final versions = user['hd_profile_pic_versions'];
        if (versions is List && versions.isNotEmpty) {
          String? bestUrl;
          int bestPixels = -1;
          for (final v in versions) {
            if (v is Map) {
              final String url = v['url']?.toString() ?? '';
              if (url.isEmpty) continue;
              final int w = _toIntOrNull(v['width']) ?? 0;
              final int h = _toIntOrNull(v['height']) ?? 0;
              final int pixels = w * h;
              if (pixels > bestPixels) {
                bestPixels = pixels;
                bestUrl = url;
              }
            }
          }
          if (bestUrl != null && bestUrl.trim().isNotEmpty) {
            return bestUrl.trim();
          }
        }
        final hdInfo = user['hd_profile_pic_url_info'];
        final hdUrl = hdInfo is Map ? hdInfo['url'] : null;
        if (hdUrl != null && hdUrl.toString().isNotEmpty) {
          return hdUrl.toString();
        }
        final url = user['profile_pic_url_hd'];
        if (url != null && url.toString().isNotEmpty) {
          return url.toString();
        }
      } catch (_) {}
      return null;
    }

    if (profile.pk != null && profile.pk!.isNotEmpty) {
      final url = await fromAppUserId(profile.pk!);
      if (url != null) return url;
    }

    final String? userId = await _getUserId(profile.username);
    if (userId != null && userId.isNotEmpty) {
      final url = await fromAppUserId(userId);
      if (url != null) return url;
    }

    try {
      final String safe = Uri.encodeComponent(profile.username);
      final response = await http.get(
        Uri.parse(
            "https://www.instagram.com/api/v1/users/web_profile_info/?username=$safe"),
        headers: _buildWebHeaders(savedCookie!, ua, dsUserId: savedUserId),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataNode = data is Map ? data['data'] : null;
        final user = dataNode is Map ? dataNode['user'] : null;
        if (user is Map) {
          final hdUrl = user['profile_pic_url_hd'];
          if (hdUrl != null && hdUrl.toString().isNotEmpty) {
            return hdUrl.toString();
          }
          final url = user['profile_pic_url'];
          if (url != null && url.toString().isNotEmpty) {
            return url.toString();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _showProfilePhoto(_StoryProfile profile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    String url = profile.imageUrl;
    final String? hdUrl = await _fetchHdProfilePhotoUrl(profile);
    if (hdUrl != null && hdUrl.isNotEmpty) {
      url = hdUrl;
    }
    url = _normalizeProfileImageUrl(url);

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
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ));
  }

  Future<String?> _getUserId(String username) async {
    if (_storyUserPks.containsKey(username.toLowerCase())) {
      return _storyUserPks[username.toLowerCase()];
    }

    if (savedCookie == null) return null;
    try {
      final String safe = Uri.encodeComponent(username);

      final response = await http.get(
        Uri.parse(
            "https://www.instagram.com/api/v1/users/web_profile_info/?username=$safe"),
        headers: _buildWebHeaders(savedCookie!, _resolveUserAgent(),
            dsUserId: savedUserId),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['data']['user'];
        if (user != null) {
           return user['id'].toString();
        }
      }

      final response2 = await http.get(
        Uri.parse(
            "https://www.instagram.com/api/v1/users/web_profile_info/?username=$safe"),
        headers: _buildWebHeaders(savedCookie!, _resolveUserAgent(),
            dsUserId: savedUserId),
      );
      if (response2.statusCode == 200) {
        final data = jsonDecode(response2.body);
        return data['user']['pk'].toString();
      } else {
         _lastIgWarning = _extractIgWarning(response2.body);
      }

    } catch (_) {}
    return null;
  }

  String? _extractIgWarning(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        final String? msg =
            data['message']?.toString() ??
            data['error_title']?.toString() ??
            data['detail']?.toString();
        if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      }
    } catch (_) {}
    return null;
  }

  Future<List<StoryItem>> _fetchStoryItems(String targetUserId) async {
    List<StoryItem> items = [];
    if (savedCookie == null || savedUserId == null) return items;

    final String ua = _resolveUserAgent();
    final String appUa =
        ua.toLowerCase().contains('instagram') ? ua : _defaultIgUserAgent;
    final Map<String, String> headers =
        _buildAppHeaders(savedCookie!, appUa, dsUserId: savedUserId);

    try {
      var response = await http.get(
        Uri.parse("https://i.instagram.com/api/v1/feed/reels_media/?reel_ids=$targetUserId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reels = data['reels'] ?? data['reels_media'];

        if (reels != null) {
          var userReel = reels[targetUserId];
          if (userReel == null && reels is Map && reels.isNotEmpty) {
            userReel = reels.values.first;
          }

          if (userReel != null && userReel['items'] != null) {
            items = _parseStoryItems(userReel['items']);
          }
        }
      }

      if (items.isEmpty) {
        response = await http.get(
          Uri.parse("https://i.instagram.com/api/v1/feed/user/$targetUserId/reel_media/"),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final reel = data['reel'];
          if (reel != null && reel['items'] != null) {
            items = _parseStoryItems(reel['items']);
          }
        }
      }
    } catch (e) {
      debugPrint("Hikaye çekme hatası: $e");
    }
    return items;
  }

  List<StoryItem> _parseStoryItems(List<dynamic> dynamicItems) {
    List<StoryItem> result = [];
    for (var item in dynamicItems) {
      try {
        int mType = item['media_type'] ?? 1;
        String url = "";
        bool isVid = mType == 2;

        if (isVid) {
          if (item['video_versions'] != null) {
            var vids = item['video_versions'] as List;
            if (vids.isNotEmpty) {
              url = vids[0]['url'];
            }
          }
        } else {
          if (item['image_versions2'] != null &&
              item['image_versions2']['candidates'] != null) {
            var candidates = item['image_versions2']['candidates'] as List;
            if (candidates.isNotEmpty) {
              url = candidates[0]['url'];
            }
          }
        }

        if (url.isNotEmpty) {
          result.add(StoryItem(url: url, isVideo: isVid));
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> _openSecretStoryViewer(_StoryProfile profile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.white))
    );

    try {
      String? targetId = profile.pk ?? await _getUserId(profile.username);

      if (targetId == null) {
         if (mounted) Navigator.pop(context);
         final String msg = _lastIgWarning?.trim().isNotEmpty == true
             ? _lastIgWarning!
             : "Kullanıcı verisi alınamadı (Gizli profil veya API hatası)";
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
         return;
      }

      List<StoryItem> stories = await _fetchStoryItems(targetId);

      if (mounted) Navigator.pop(context);

      if (stories.isEmpty) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('story_no_data')), backgroundColor: Colors.orange));
         return;
      }

      if (mounted) {
        final String modeLabel = _lang == 'tr' ? "GİZLİ MOD" : "Secret Mode";

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
    final String label = '${_t('next_analysis')}: ${_formatDuration(remaining)}';
    return GestureDetector(
        onTap: _showRemainingDialog,
        child: Text(
            label,
            style: style));
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
    WidgetsBinding.instance.removeObserver(this);
    _cancelCountdown();
    _cancelLegalHoldTimer();
    _consentWatchTimer?.cancel();
    _storyAutoTimer?.cancel();
    _stopProgressPump();
    _stopAnalysisProgressTimeline();
    _storyScrollController.dispose();
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

  Widget _buildDetailedLegalDialog(BuildContext context,
      {required bool isInitial, SharedPreferences? prefs}) {
    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.info_outline, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Text(_t('legal_warning'),
            style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87))
      ]),
      content: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t('legal_intro'),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 15),
        _legalSection('article1_title', 'article1_text'),
        _legalSection('article2_title', 'article2_text'),
        _legalSection('article3_title', 'article3_text'),
        _legalSection('article4_title', 'article4_text'),
        _legalSection('article5_title', 'article5_text'),
        const Divider(height: 30),
      ])),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: _launchPrivacyPolicyURL,
                  child: Text(
                    _lang == 'tr' ? "Gizlilik Politikası" : "Privacy Policy",
                    style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isInitial)
                  TextButton(
                    onPressed: _revokeConsentAndShowForm,
                    child: Text(
                      _t('withdraw_consent'),
                      style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.blueGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
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
                    child: Text(_lang == 'tr' ? "KAPAT" : "CLOSE")),
          ],
        )
      ],
    );
  }

  Widget _legalSection(String titleKey, String contentKey) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(titleKey),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.blueAccent,
                  fontSize: 13)),
          const SizedBox(height: 4),
          Text(_t(contentKey),
              style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: isDarkMode ? Colors.white70 : Colors.black87))
        ]));
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
                          shape: BoxShape.circle,
                          color: Colors.white24
                        ),
                        child: const Icon(Icons.visibility_off, color: Colors.white, size: 16),
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
                  side: const BorderSide(color: Colors.white30)
                ),
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
          IgnorePointer(
            ignoring: true,
            child: WebViewWidget(controller: _videoController),
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
              return const Center(child: CircularProgressIndicator(color: Colors.white));
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
                child: Text(lang == 'tr' ? 'Veri yok' : 'No data',
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
                            child: Text(lang == 'tr' ? 'YENİ' : 'NEW',
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
  const InstagramApiPage(
      {super.key, required this.isDark, required this.lang});
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
      content: Text(widget.lang == 'tr' ? trText : enText),
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
            Uri.parse("https://i.instagram.com/api/v1/users/$targetUserId/info/"),
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
          "username": username ?? (widget.lang == 'tr' ? "Kullanıcı" : "User"),
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
            title: Text(widget.lang == 'tr' ? 'Giriş Yap' : 'Login'),
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
                    Text(widget.lang == 'tr'
                        ? 'Oturum doğrulandı, yönlendiriliyorsunuz...'
                        : 'Session verified, redirecting...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              widget.isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ))
                  ]))
            : WebViewWidget(controller: _controller));
  }
}
