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
import 'dart:collection';
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
import 'ad_consent_flow.dart';
import 'purchases_service.dart';
import 'telemetry_service.dart';
import 'tr_en_phrase_localizations.dart';
import 'did_you_know_phrase_localizations.dart';
import 'privacy_policy_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final AdConsentFlow _adConsentFlow = AdConsentFlow(
  canRequestAds: () => ConsentInformation.instance.canRequestAds(),
);

const String _igAppId = '936619743392459';
const String _iosPlatformUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Mobile/15E148 Safari/604.1';
const String _androidPlatformUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8 Build/UD1A.231105.004) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6778.135 Mobile Safari/537.36';
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
    int.fromEnvironment('FIRESTORE_TIMEOUT_SECONDS', defaultValue: 10);
const Duration _firestoreTimeout = Duration(seconds: _firestoreTimeoutSeconds);
const String _firestoreSetupBaseUrl =
    'https://console.cloud.google.com/datastore/setup?project=';
const String _privacyPolicySourceUrl =
    'https://raw.githubusercontent.com/grkmcomert/verdict-web/refs/heads/main/privacy-policy.txt';
const String _appleEulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const MethodChannel _cookieChannel =
    MethodChannel('com.grkmcomert.unfollowerscurrent/cookie');
const MethodChannel _reviewChannel =
    MethodChannel('com.grkmcomert.unfollowerscurrent/review');

Future<void> _clearInstagramWebSessionStorage() async {
  try {
    await WebViewCookieManager()
        .clearCookies()
        .timeout(const Duration(seconds: 4));
  } catch (_) {}

  try {
    await _cookieChannel
        .invokeMethod<bool>('clearCookies')
        .timeout(const Duration(seconds: 4));
  } catch (_) {}
}

// Keep X-IG-Set-WWW-Claim token global so it can be used by multiple
// components without relying on a specific widget state instance.
String? _igWwwClaimToken;

final ValueNotifier<List<String>> _igDiagnosticEvents =
    ValueNotifier<List<String>>(<String>[]);
const int _maxIgDiagnosticEvents = 320;

void _appendIgDiagnosticEvent(String line) {
  final List<String> next = List<String>.from(_igDiagnosticEvents.value);
  next.insert(0, line);
  if (next.length > _maxIgDiagnosticEvents) {
    next.removeRange(_maxIgDiagnosticEvents, next.length);
  }
  _igDiagnosticEvents.value = next;
}

void _logIgDiagnosticEntry(
  String phase,
  String message, {
  String? label,
  Uri? uri,
  Map<String, String>? headers,
  Object? error,
  StackTrace? stackTrace,
  int? statusCode,
  Duration? elapsed,
  String? responseBody,
  Map<String, String>? responseHeaders,
  bool isError = false,
}) {
  final String cleanPhase =
      phase.trim().isEmpty ? 'general' : phase.trim().toUpperCase();
  final String cleanLabel = (label ?? '').trim();
  String cleanMessage = message.replaceAll('\r\n', '\n').trim();
  if (cleanMessage.isEmpty) cleanMessage = '(empty message)';
  if (cleanMessage.length > 2200) {
    cleanMessage = '${cleanMessage.substring(0, 2200)}...';
  }

  final String level = isError ? 'ERROR' : 'INFO';
  final StringBuffer buffer = StringBuffer()
    ..writeln(
      '[${DateTime.now().toIso8601String()}][$level][IG][$cleanPhase] '
      '${cleanLabel.isEmpty ? '' : '[$cleanLabel] '}$cleanMessage',
    );
  if (uri != null) buffer.writeln('uri=$uri');
  if (statusCode != null) buffer.writeln('statusCode=$statusCode');
  if (elapsed != null) buffer.writeln('elapsedMs=${elapsed.inMilliseconds}');
  if (headers != null && headers.isNotEmpty) {
    buffer.writeln('requestHeaders:');
    final List<String> requestKeys = headers.keys.toList()..sort();
    for (final String key in requestKeys) {
      buffer.writeln(
          '$key: ${_redactIgHeaderValueForLog(key, headers[key] ?? '')}');
    }
  }
  if (responseHeaders != null && responseHeaders.isNotEmpty) {
    buffer.writeln('responseHeaders:');
    final List<String> responseKeys = responseHeaders.keys.toList()..sort();
    for (final String key in responseKeys) {
      buffer.writeln(
          '$key: ${_redactIgHeaderValueForLog(key, responseHeaders[key] ?? '')}');
    }
  }
  if (responseBody != null && responseBody.isNotEmpty) {
    final String cleanBody = responseBody.replaceAll('\r\n', '\n').trim();
    final String preview = cleanBody.length <= 2200
        ? cleanBody
        : '${cleanBody.substring(0, 2200)}...';
    buffer.writeln('responseBodyPreview=$preview');
  }
  if (error != null) buffer.writeln('error=$error');
  if (stackTrace != null) {
    final List<String> stackLines = stackTrace.toString().split('\n');
    final String compactStack = stackLines.take(10).join('\n').trim();
    if (compactStack.isNotEmpty) buffer.writeln('stack=$compactStack');
  }

  final String entry = buffer.toString().trimRight();
  debugPrint('[IG][$cleanPhase][$level] $cleanMessage');
  _appendIgDiagnosticEvent(entry);
}

const Map<String, String> _startupLoadingLabels = <String, String>{
  'tr': 'VERDICT baÃ…Å¸latÃ„Â±lÃ„Â±yor...',
  'en': 'Starting VERDICT...',
  'de': 'VERDICT wird gestartet...',
  'ko': 'VERDICTÃ«Â¥Â¼ Ã¬â€¹Å“Ã¬Ââ€˜Ã­â€¢ËœÃ«Å â€ Ã¬Â¤â€˜...',
  'ja': 'VERDICTÃ£â€šâ€™Ã¨ÂµÂ·Ã¥â€¹â€¢Ã£Ââ€”Ã£ÂÂ¦Ã£Ââ€Ã£ÂÂ¾Ã£Ââ„¢...',
  'ru': 'Äâ€”ÄÂ°ÄÂ¿Ã‘Æ’Ã‘ÂÄÂº VERDICT...',
  'pt': 'Iniciando VERDICT...',
  'ar': 'Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Å  Ã˜ÂªÃ˜Â´Ã˜ÂºÃ™Å Ã™â€ VERDICT...',
  'es': 'Iniciando VERDICT...',
  'es-mx': 'Iniciando VERDICT...',
  'hi':
      'VERDICT Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â°Ã Â¥â€š Ã Â¤Â¹Ã Â¥â€¹ Ã Â¤Â°Ã Â¤Â¹Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†...',
  'hu': 'VERDICT indul...',
  'zh-hans': 'Ã¦Â­Â£Ã¥Å“Â¨Ã¥ÂÂ¯Ã¥Å Â¨ VERDICT...',
  'id': 'Memulai VERDICT...',
  'nl': 'VERDICT wordt gestart...',
  'fr': 'DÃƒÂ©marrage de VERDICT...',
  'it': 'Avvio di VERDICT...',
  'vi': 'Ã„Âang khÃ¡Â»Å¸i Ã„â€˜Ã¡Â»â„¢ng VERDICT...',
  'th':
      'Ã Â¸ÂÃ Â¸Â³Ã Â¸Â¥Ã Â¸Â±Ã Â¸â€¡Ã Â¹â‚¬Ã Â¸Â£Ã Â¸Â´Ã Â¹Ë†Ã Â¸Â¡ VERDICT...',
  'pl': 'Uruchamianie VERDICT...',
};

const Map<String, String> _legalWarningSummaryLabels = <String, String>{
  'tr':
      'Yasal bilgilendirme: Bu bÃƒÂ¶lÃƒÂ¼m kÃ„Â±sa bir ÃƒÂ¶zet gÃƒÂ¶sterir. Gizlilik PolitikasÃ„Â± dÃƒÂ¼Ã„Å¸mesine dokunarak tam metni dilinizde gÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼leyebilirsiniz.',
  'en':
      'Legal notice: This section shows a short summary. Tap Privacy Policy to view the full text in your language.',
  'de':
      'Rechtlicher Hinweis: Dieser Abschnitt zeigt eine kurze Zusammenfassung. Tippen Sie auf Datenschutzrichtlinie, um den vollstÃƒÂ¤ndigen Text in Ihrer Sprache zu lesen.',
  'ko':
      'Ã«Â²â€¢Ã¬Â Â ÃªÂ³Â Ã¬Â§â‚¬: Ã¬ÂÂ´ Ã¬â€Â¹Ã¬â€¦ËœÃ¬Ââ‚¬ Ã¬Å¡â€Ã¬â€¢Â½Ã«Â§Å’ Ã­â€˜Å“Ã¬â€¹Å“Ã­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤. ÃªÂ°Å“Ã¬ÂÂ¸Ã¬Â â€¢Ã«Â³Â´ Ã¬Â²ËœÃ«Â¦Â¬Ã«Â°Â©Ã¬Â¹Â¨ Ã«Â²â€Ã­Å Â¼Ã¬Ââ€ Ã«Ë†Å’Ã«Å¸Â¬ Ã¬Â â€Ã¬Â²Â´ Ã«â€šÂ´Ã¬Å¡Â©Ã¬Ââ€ Ã¬â€šÂ¬Ã¬Å¡Â©Ã¬ÂÂ Ã¬â€“Â¸Ã¬â€“Â´Ã«Â¡Å“ Ã­â„¢â€¢Ã¬ÂÂ¸Ã­â€¢ËœÃ¬â€Â¸Ã¬Å¡â€.',
  'ja':
      'Ã¦Â³â€¢Ã§Å¡â€Ã©â‚¬Å¡Ã§Å¸Â¥: Ã£Ââ€œÃ£ÂÂ®Ã£â€šÂ»Ã£â€šÂ¯Ã£â€šÂ·Ã£Æ’Â§Ã£Æ’Â³Ã£ÂÂ«Ã£ÂÂ¯Ã¨Â¦ÂÃ§Â´â€Ã£ÂÂ®Ã£ÂÂ¿Ã¨Â¡Â¨Ã§Â¤ÂºÃ£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€šÃ£Æ’â€”Ã£Æ’Â©Ã£â€šÂ¤Ã£Æ’ÂÃ£â€šÂ·Ã£Æ’Â¼Ã£Æ’ÂÃ£Æ’ÂªÃ£â€šÂ·Ã£Æ’Â¼Ã£â€šâ€™Ã£â€šÂ¿Ã£Æ’Æ’Ã£Æ’â€”Ã£Ââ„¢Ã£â€šâ€¹Ã£ÂÂ¨Ã£â‚¬ÂÃ¥â€¦Â¨Ã¦â€“â€¡Ã£â€šâ€™Ã£ÂÅ Ã¤Â½Â¿Ã£Ââ€Ã£ÂÂ®Ã¨Â¨â‚¬Ã¨ÂªÂÃ£ÂÂ§Ã§Â¢ÂºÃ¨ÂªÂÃ£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
  'ru':
      'ÄÂ®Ã‘â‚¬ÄÂ¸ÄÂ´ÄÂ¸Ã‘â€¡ÄÂµÃ‘ÂÄÂºÄÂ¾ÄÂµ Ã‘Æ’ÄÂ²ÄÂµÄÂ´ÄÂ¾ÄÂ¼ÄÂ»ÄÂµÄÂ½ÄÂ¸ÄÂµ: Äâ€™ Ã‘ÂÃ‘â€šÄÂ¾ÄÂ¼ Ã‘â‚¬ÄÂ°ÄÂ·ÄÂ´ÄÂµÄÂ»ÄÂµ ÄÂ¿ÄÂ¾ÄÂºÄÂ°ÄÂ·Ã‘â€¹ÄÂ²ÄÂ°ÄÂµÃ‘â€šÃ‘ÂÃ‘Â ÄÂºÃ‘â‚¬ÄÂ°Ã‘â€šÄÂºÄÂ¾ÄÂµ Ã‘ÂÄÂ¾ÄÂ´ÄÂµÃ‘â‚¬ÄÂ¶ÄÂ°ÄÂ½ÄÂ¸ÄÂµ. ÄÂÄÂ°ÄÂ¶ÄÂ¼ÄÂ¸Ã‘â€šÄÂµ Ã‚Â«ÄÅ¸ÄÂ¾ÄÂ»ÄÂ¸Ã‘â€šÄÂ¸ÄÂºÄÂ° ÄÂºÄÂ¾ÄÂ½Ã‘â€ÄÂ¸ÄÂ´ÄÂµÄÂ½Ã‘â€ ÄÂ¸ÄÂ°ÄÂ»Ã‘Å’ÄÂ½ÄÂ¾Ã‘ÂÃ‘â€šÄÂ¸Ã‚Â», Ã‘â€¡Ã‘â€šÄÂ¾ÄÂ±Ã‘â€¹ ÄÂ¾Ã‘â€šÄÂºÃ‘â‚¬Ã‘â€¹Ã‘â€šÃ‘Å’ ÄÂ¿ÄÂ¾ÄÂ»ÄÂ½Ã‘â€¹ÄÂ¹ Ã‘â€šÄÂµÄÂºÃ‘ÂÃ‘â€š ÄÂ½ÄÂ° ÄÂ²ÄÂ°Ã‘Ë†ÄÂµÄÂ¼ Ã‘ÂÄÂ·Ã‘â€¹ÄÂºÄÂµ.',
  'pt':
      'Aviso legal: esta seÃƒÂ§ÃƒÂ£o mostra apenas um resumo. Toque em PolÃƒÂ­tica de Privacidade para ver o texto completo no seu idioma.',
  'ar':
      'Ã˜Â¥Ã˜Â´Ã˜Â¹Ã˜Â§Ã˜Â± Ã™â€šÃ˜Â§Ã™â€ Ã™Ë†Ã™â€ Ã™Å : Ã™Å Ã˜Â¹Ã˜Â±Ã˜Â¶ Ã™â€¡Ã˜Â°Ã˜Â§ Ã˜Â§Ã™â€Ã™â€šÃ˜Â³Ã™â€¦ Ã™â€¦Ã™â€Ã˜Â®Ã˜ÂµÃ™â€¹Ã˜Â§ Ã™â€šÃ˜ÂµÃ™Å Ã˜Â±Ã™â€¹Ã˜Â§ Ã™ÂÃ™â€šÃ˜Â·. Ã˜Â§Ã˜Â¶Ã˜ÂºÃ˜Â· Ã˜Â¹Ã™â€Ã™â€° Ã˜Â³Ã™Å Ã˜Â§Ã˜Â³Ã˜Â© Ã˜Â§Ã™â€Ã˜Â®Ã˜ÂµÃ™Ë†Ã˜ÂµÃ™Å Ã˜Â© Ã™â€Ã˜Â¹Ã˜Â±Ã˜Â¶ Ã˜Â§Ã™â€Ã™â€ Ã˜Âµ Ã˜Â§Ã™â€Ã™Æ’Ã˜Â§Ã™â€¦Ã™â€ Ã˜Â¨Ã™â€Ã˜ÂºÃ˜ÂªÃ™Æ’.',
  'es':
      'Aviso legal: esta secciÃƒÂ³n muestra un resumen breve. Toca PolÃƒÂ­tica de privacidad para ver el texto completo en tu idioma.',
  'es-mx':
      'Aviso legal: esta secciÃƒÂ³n muestra un resumen breve. Toca PolÃƒÂ­tica de privacidad para ver el texto completo en tu idioma.',
  'hi':
      'Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â¨Ã Â¥â€šÃ Â¤Â¨Ã Â¥â‚¬ Ã Â¤Â¸Ã Â¥â€šÃ Â¤Å¡Ã Â¤Â¨Ã Â¤Â¾: Ã Â¤â€¡Ã Â¤Â¸ Ã Â¤Â­Ã Â¤Â¾Ã Â¤â€” Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤â€¢Ã Â¥â€¡Ã Â¤ÂµÃ Â¤Â² Ã Â¤Â¸Ã Â¤â€šÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¿Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¤ Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â° Ã Â¤Â¦Ã Â¤Â¿Ã Â¤â€“Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤ Ã Â¤â€¦Ã Â¤ÂªÃ Â¤Â¨Ã Â¥â‚¬ Ã Â¤Â­Ã Â¤Â¾Ã Â¤Â·Ã Â¤Â¾ Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤ÂªÃ Â¥â€šÃ Â¤Â°Ã Â¤Â¾ Ã Â¤ÂªÃ Â¤Â¾Ã Â¤Â  Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤â€”Ã Â¥â€¹Ã Â¤ÂªÃ Â¤Â¨Ã Â¥â‚¬Ã Â¤Â¯Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¨Ã Â¥â‚¬Ã Â¤Â¤Ã Â¤Â¿ Ã Â¤ÂªÃ Â¤Â° Ã Â¤Å¸Ã Â¥Ë†Ã Â¤Âª Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤',
  'hu':
      'Jogi tÃƒÂ¡jÃƒÂ©koztatÃƒÂ³: Ez a szakasz csak rÃƒÂ¶vid ÃƒÂ¶sszefoglalÃƒÂ³t mutat. A teljes szÃƒÂ¶veg nyelveden a Ã¢â‚¬ÂAdatvÃƒÂ©delmi tÃƒÂ¡jÃƒÂ©koztatÃƒÂ³Ã¢â‚¬Â gombbal ÃƒÂ©rhetÃ…â€˜ el.',
  'zh-hans':
      'Ã¦Â³â€¢Ã¥Â¾â€¹Ã¦ÂÂÃ§Â¤ÂºÃ¯Â¼Å¡Ã¦Â­Â¤Ã¥Â¤â€Ã¤Â»â€¦Ã¦ËœÂ¾Ã§Â¤ÂºÃ§Â®â‚¬Ã¨Â¦ÂÃ¨Â¯Â´Ã¦ËœÂÃ£â‚¬â€šÃ§â€šÂ¹Ã¥â€¡Â»Ã¢â‚¬Å“Ã©Å¡ÂÃ§Â§ÂÃ¦â€Â¿Ã§Â­â€“Ã¢â‚¬ÂÃ¥ÂÂ¯Ã¦Å¸Â¥Ã§Å“â€¹Ã¤Â½Â Ã¦â€°â‚¬Ã§â€Â¨Ã¨Â¯Â­Ã¨Â¨â‚¬Ã§Å¡â€Ã¥Â®Å’Ã¦â€¢Â´Ã¥â€ â€¦Ã¥Â®Â¹Ã£â‚¬â€š',
  'id':
      'Pemberitahuan hukum: Bagian ini hanya menampilkan ringkasan singkat. Ketuk Kebijakan Privasi untuk melihat teks lengkap dalam bahasa Anda.',
  'nl':
      'Juridische melding: Dit onderdeel toont alleen een korte samenvatting. Tik op Privacybeleid om de volledige tekst in jouw taal te bekijken.',
  'fr':
      'Mentions lÃƒÂ©gales : cette section affiche un court rÃƒÂ©sumÃƒÂ©. Appuyez sur Politique de confidentialitÃƒÂ© pour voir le texte complet dans votre langue.',
  'it':
      'Avviso legale: questa sezione mostra un breve riepilogo. Tocca Informativa sulla privacy per vedere il testo completo nella tua lingua.',
  'vi':
      'ThÃƒÂ´ng bÃƒÂ¡o phÃƒÂ¡p lÃƒÂ½: MÃ¡Â»Â¥c nÃƒÂ y chÃ¡Â»â€° hiÃ¡Â»Æ’n thÃ¡Â»â€¹ phÃ¡ÂºÂ§n tÃƒÂ³m tÃ¡ÂºÂ¯t ngÃ¡ÂºÂ¯n. NhÃ¡ÂºÂ¥n ChÃƒÂ­nh sÃƒÂ¡ch bÃ¡ÂºÂ£o mÃ¡ÂºÂ­t Ã„â€˜Ã¡Â»Æ’ xem toÃƒÂ n vÃ„Æ’n bÃ¡ÂºÂ±ng ngÃƒÂ´n ngÃ¡Â»Â¯ cÃ¡Â»Â§a bÃ¡ÂºÂ¡n.',
  'th':
      'Ã Â¸â€ºÃ Â¸Â£Ã Â¸Â°Ã Â¸ÂÃ Â¸Â²Ã Â¸Â¨Ã Â¸â€”Ã Â¸Â²Ã Â¸â€¡Ã Â¸ÂÃ Â¸ÂÃ Â¸Â«Ã Â¸Â¡Ã Â¸Â²Ã Â¸Â¢: Ã Â¸ÂªÃ Â¹Ë†Ã Â¸Â§Ã Â¸â„¢Ã Â¸â„¢Ã Â¸ÂµÃ Â¹â€°Ã Â¸Ë†Ã Â¸Â°Ã Â¹ÂÃ Â¸ÂªÃ Â¸â€Ã Â¸â€¡Ã Â¹â‚¬Ã Â¸ÂÃ Â¸ÂµÃ Â¸Â¢Ã Â¸â€¡Ã Â¸ÂªÃ Â¸Â£Ã Â¸Â¸Ã Â¸â€ºÃ Â¸ÂªÃ Â¸Â±Ã Â¹â€°Ã Â¸â„¢Ã Â¹â€  Ã Â¹â‚¬Ã Â¸â€”Ã Â¹Ë†Ã Â¸Â²Ã Â¸â„¢Ã Â¸Â±Ã Â¹â€°Ã Â¸â„¢ Ã Â¹ÂÃ Â¸â€¢Ã Â¸Â°Ã Â¸â„¢Ã Â¹â€šÃ Â¸Â¢Ã Â¸Å¡Ã Â¸Â²Ã Â¸Â¢Ã Â¸â€Ã Â¸Â§Ã Â¸Â²Ã Â¸Â¡Ã Â¹â‚¬Ã Â¸â€ºÃ Â¹â€¡Ã Â¸â„¢Ã Â¸ÂªÃ Â¹Ë†Ã Â¸Â§Ã Â¸â„¢Ã Â¸â€¢Ã Â¸Â±Ã Â¸Â§Ã Â¹â‚¬Ã Â¸ÂÃ Â¸Â·Ã Â¹Ë†Ã Â¸Â­Ã Â¸â€Ã Â¸Â¹Ã Â¸â€šÃ Â¹â€°Ã Â¸Â­Ã Â¸â€Ã Â¸Â§Ã Â¸Â²Ã Â¸Â¡Ã Â¹â‚¬Ã Â¸â€¢Ã Â¹â€¡Ã Â¸Â¡Ã Â¸â€¢Ã Â¸Â²Ã Â¸Â¡Ã Â¸Â Ã Â¸Â²Ã Â¸Â©Ã Â¸Â²Ã Â¸â€šÃ Â¸Â­Ã Â¸â€¡Ã Â¸â€Ã Â¸Â¸Ã Â¸â€œ',
  'pl':
      'Informacja prawna: Ta sekcja pokazuje krÃƒÂ³tkie podsumowanie. Dotknij Ã¢â‚¬ÂPolityka prywatnoÃ…â€ºciÃ¢â‚¬Â, aby wyÃ…â€ºwietliÃ„â€¡ peÃ…â€šny tekst w swoim jÃ„â„¢zyku.',
};

const Set<String> _supportedLanguageCodesGlobal = <String>{
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
  'ca',
  'zh-hant',
  'hr',
  'cs',
  'da',
  'fi',
  'fr-ca',
  'el',
  'he',
  'ms',
  'no',
  'pt-pt',
  'ro',
  'sk',
  'sv',
  'uk',
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

  if (base == 'fr') {
    if (locale.startsWith('fr_ca')) return 'fr-ca';
    return 'fr';
  }
  if (base == 'pt') {
    if (locale.startsWith('pt_pt')) return 'pt-pt';
    return 'pt';
  }
  if (base == 'zh') {
    if (locale.contains('_hant') ||
        locale.endsWith('_tw') ||
        locale.endsWith('_hk') ||
        locale.endsWith('_mo')) {
      return 'zh-hant';
    }
    return 'zh-hans';
  }
  if (base == 'in') return 'id';

  return _supportedLanguageCodesGlobal.contains(base) ? base : 'en';
}

String _normalizeSupportedLangCodeFromAppSetting(String raw) {
  final String code = raw.trim().toLowerCase().replaceAll('_', '-');
  if (code.isEmpty) return 'en';
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
  if (code == 'in') return 'id';
  return _supportedLanguageCodesGlobal.contains(code) ? code : 'en';
}

String _startupLoadingTextForLocale(String localeRaw) {
  final String code = _normalizeSupportedLangCodeFromLocale(localeRaw);
  return localizeTrEn(
    code,
    _startupLoadingLabels['tr'] ?? 'Starting VERDICT...',
    _startupLoadingLabels['en'] ?? 'Starting VERDICT...',
  );
}

String _startupLoadingTextForAppSetting(String languageCodeRaw) {
  final String code =
      _normalizeSupportedLangCodeFromAppSetting(languageCodeRaw);
  return localizeTrEn(
    code,
    _startupLoadingLabels['tr'] ?? 'Starting VERDICT...',
    _startupLoadingLabels['en'] ?? 'Starting VERDICT...',
  );
}

Future<bool> shouldUseNonPersonalizedAdsGlobal() async {
  try {
    final status = await ConsentInformation.instance.getConsentStatus();

    final bool consentAllowsAds =
        await ConsentInformation.instance.canRequestAds();

    if (!consentAllowsAds) return true;

    if (status != ConsentStatus.obtained &&
        status != ConsentStatus.notRequired) {
      return true;
    }

    if (!Platform.isIOS) return false;

    try {
      final TrackingStatus trackingStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      return trackingStatus != TrackingStatus.authorized;
    } catch (_) {
      return true;
    }
  } catch (_) {
    return true;
  }
}

Future<void> _waitForAdConsentFlow() => _adConsentFlow.completed;

Future<void> _requestTrackingAuthorizationIfNeeded() async {
  if (!Platform.isIOS) return;
  try {
    // UMP dismissal can coincide with the app becoming active again.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      final resumed = Completer<void>();
      final listener = AppLifecycleListener(onResume: () {
        if (!resumed.isCompleted) resumed.complete();
      });
      try {
        await resumed.future;
      } finally {
        listener.dispose();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
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

String _extractIgUserIdFromSessionId(String sessionId) {
  final String raw = sessionId.trim();
  if (raw.isEmpty) return '';
  final String decoded = Uri.decodeComponent(raw);
  final RegExp decodedPattern = RegExp(r'^(\d+):');
  final Match? decodedMatch = decodedPattern.firstMatch(decoded);
  if (decodedMatch != null) return decodedMatch.group(1) ?? '';
  final Match? rawMatch =
      RegExp(r'^(\d+)%3A', caseSensitive: false).firstMatch(raw);
  if (rawMatch != null) return rawMatch.group(1) ?? '';
  return '';
}

String _redactIgCookieHeaderForLog(String value) {
  String redacted = value;
  const List<String> cookieNames = <String>[
    'sessionid',
    'csrftoken',
    'ds_user_id',
    'rur',
    'mid',
    'ig_did',
    'datr',
    'shbid',
    'shbts',
  ];
  for (final String name in cookieNames) {
    redacted = redacted.replaceAllMapped(
      RegExp(
        '(${RegExp.escape(name)}=)("[^"\\r\\n]*"|[^;,\\r\\n]*)',
        caseSensitive: false,
      ),
      (Match match) => '${match.group(1)}<redacted>',
    );
  }
  return redacted;
}

String _redactIgHeaderValueForLog(String key, String value) {
  final String lowerKey = key.toLowerCase().trim();
  if (lowerKey == 'cookie' || lowerKey == 'set-cookie') {
    return _redactIgCookieHeaderForLog(value);
  }
  const Set<String> sensitiveHeaders = <String>{
    'x-csrftoken',
    'ig-u-ds-user-id',
    'x-ig-device-id',
    'x-ig-www-claim',
    'x-ig-set-www-claim',
    'x-mid',
  };
  if (sensitiveHeaders.contains(lowerKey) && value.trim().isNotEmpty) {
    return '<redacted>';
  }
  return value;
}

String? _resolveSessionDsUserId(String? savedUserId, String? savedCookie) {
  final String direct = (savedUserId ?? '').trim();
  if (direct.isNotEmpty && direct != 'null') return direct;
  final String cookie = (savedCookie ?? '').trim();
  if (cookie.isEmpty) return null;
  final String fromCookie = _extractCookieValue(cookie, 'ds_user_id').trim();
  if (fromCookie.isNotEmpty && fromCookie != 'null') return fromCookie;
  final String fromSession = _extractIgUserIdFromSessionId(
    _extractCookieValue(cookie, 'sessionid'),
  ).trim();
  if (fromSession.isNotEmpty) return fromSession;
  return null;
}

bool _preferWebApi(String userAgent) {
  return !userAgent.toLowerCase().contains('instagram');
}

String _normalizeAcceptLanguage(String localeName) {
  final String cleaned = localeName.trim();
  if (cleaned.isEmpty) return 'en-US,en;q=0.9';

  final List<String> parts = cleaned.split(RegExp(r'[_-]'));
  final String language =
      parts.isNotEmpty ? parts.first.trim().toLowerCase() : 'en';
  final String region = parts.length >= 2 ? parts[1].trim().toUpperCase() : '';
  if (language.isEmpty) return 'en-US,en;q=0.9';
  final String primary = region.isEmpty ? language : '$language-$region';
  return '$primary,$language;q=0.9';
}

String _canonicalPlatformUserAgent({String? fallback}) {
  final String candidate = (fallback ?? '').trim();
  if (candidate.isNotEmpty) {
    return candidate;
  }
  return Platform.isIOS ? _iosPlatformUserAgent : _androidPlatformUserAgent;
}

LinkedHashMap<String, String> _orderedInstagramHeaders({
  required String host,
  required String userAgent,
  required String cookie,
  required String acceptLanguage,
  required String csrfToken,
  required String referer,
  required String origin,
  String? dsUserId,
  String? mid,
  String? igDid,
  String? secFetchSite,
  String? secFetchMode,
  String? secFetchDest,
  String? connectionType,
}) {
  final LinkedHashMap<String, String> headers = LinkedHashMap<String, String>();
  headers['Host'] = host;
  headers['User-Agent'] = userAgent;
  headers['Accept'] = '*/*';
  headers['Accept-Language'] = acceptLanguage;
  // IMPORTANT: Do NOT advertise Brotli here. The Flutter `http` client used by
  // VERDICT does not reliably decode Instagram's `Content-Encoding: br` payloads
  // on all Android builds. When Instagram responds with Brotli bytes,
  // `response.body` can throw `FormatException: Unexpected extension byte`.
  // Request an uncompressed payload so JSON is decoded deterministically.
  headers['Accept-Encoding'] = 'identity';
  if (secFetchSite != null && secFetchSite.isNotEmpty) {
    headers['Sec-Fetch-Site'] = secFetchSite;
  }
  if (secFetchMode != null && secFetchMode.isNotEmpty) {
    headers['Sec-Fetch-Mode'] = secFetchMode;
  }
  if (secFetchDest != null && secFetchDest.isNotEmpty) {
    headers['Sec-Fetch-Dest'] = secFetchDest;
  }
  headers['Referer'] = referer;
  headers['Origin'] = origin;
  if (csrfToken.isNotEmpty) headers['X-CSRFToken'] = csrfToken;
  headers['Cookie'] = cookie;
  headers['Connection'] = 'keep-alive';

  if (dsUserId != null && dsUserId.isNotEmpty) {
    headers['IG-U-DS-User-ID'] = dsUserId;
  }
  if (mid != null && mid.isNotEmpty) headers['X-MID'] = mid;
  if (igDid != null && igDid.isNotEmpty) headers['X-IG-Device-ID'] = igDid;
  if (connectionType != null && connectionType.isNotEmpty) {
    headers['X-IG-Connection-Type'] = connectionType;
  }

  return headers;
}

String _instagramProfileReferer(String username, {String? section}) {
  final String cleanUsername = username.trim();
  String normalized = cleanUsername.toLowerCase();
  normalized =
      normalized.replaceAll(RegExp(r'^https?://(www\.)?instagram\.com/'), '');
  if (normalized.startsWith('@')) normalized = normalized.substring(1);
  final int queryIndex = normalized.indexOf('?');
  if (queryIndex >= 0) normalized = normalized.substring(0, queryIndex);
  final int hashIndex = normalized.indexOf('#');
  if (hashIndex >= 0) normalized = normalized.substring(0, hashIndex);
  normalized = normalized.replaceAll('/', '').replaceAll(' ', '');
  if (normalized.isEmpty || normalized == 'kullanici' || normalized == 'user') {
    return 'https://www.instagram.com/';
  }
  final String encodedUsername = Uri.encodeComponent(cleanUsername);
  if (section == null || section.trim().isEmpty) {
    return 'https://www.instagram.com/$encodedUsername/';
  }
  return 'https://www.instagram.com/$encodedUsername/${section.trim()}/';
}

Map<String, String> _buildWebHeaders(String cookie, String userAgent,
    {String? dsUserId, String? referer, String? igWwwClaim}) {
  final String csrf = _extractCookieValue(cookie, 'csrftoken');
  final String mid = _extractCookieValue(cookie, 'mid').trim();
  final String igDid = _extractCookieValue(cookie, 'ig_did').trim();
  final String acceptLanguage = _normalizeAcceptLanguage(Platform.localeName);
  final LinkedHashMap<String, String> headers = _orderedInstagramHeaders(
    host: 'www.instagram.com',
    userAgent: userAgent,
    cookie: cookie,
    acceptLanguage: acceptLanguage,
    csrfToken: csrf,
    referer: referer ?? 'https://www.instagram.com/',
    origin: 'https://www.instagram.com',
    dsUserId: dsUserId,
    mid: mid,
    igDid: igDid,
    secFetchSite: 'same-origin',
    secFetchMode: 'cors',
    secFetchDest: 'empty',
  );
  headers['X-IG-App-ID'] = _igAppId;
  headers['X-IG-WWW-Claim'] = (() {
    final String fromState = (igWwwClaim ?? '').trim();
    if (fromState.isNotEmpty) return fromState;
    final String v = _extractCookieValue(cookie, 'www-claim').trim();
    return v.isNotEmpty ? v : '0';
  })();
  return headers;
}

Map<String, String> _buildAppHeaders(String cookie, String userAgent,
    {String? dsUserId, String? igWwwClaim}) {
  final String csrf = _extractCookieValue(cookie, 'csrftoken');
  final String mid = _extractCookieValue(cookie, 'mid').trim();
  final String igDid = _extractCookieValue(cookie, 'ig_did').trim();
  final String acceptLanguage = _normalizeAcceptLanguage(Platform.localeName);
  // Use web host for app headers too to unify identity.
  final LinkedHashMap<String, String> headers = _orderedInstagramHeaders(
    host: 'www.instagram.com',
    userAgent: userAgent,
    cookie: cookie,
    acceptLanguage: acceptLanguage,
    csrfToken: csrf,
    referer: 'https://www.instagram.com/',
    origin: 'https://www.instagram.com',
    dsUserId: dsUserId,
    mid: mid,
    igDid: igDid,
    secFetchSite: 'same-origin',
    secFetchMode: 'cors',
    secFetchDest: 'empty',
    connectionType: 'WIFI',
  );
  headers['X-IG-App-ID'] = _igAppId;
  headers['X-IG-WWW-Claim'] = (() {
    final String fromState = (igWwwClaim ?? '').trim();
    if (fromState.isNotEmpty) return fromState;
    final String v = _extractCookieValue(cookie, 'www-claim').trim();
    return v.isNotEmpty ? v : '0';
  })();
  return headers;
}

bool _looksLikeMojibakeText(String value) {
  if (value.isEmpty) return false;

  // Replacement char is a strong indicator of a decoding problem.
  if (value.contains('\uFFFD')) return true;

  // C1 control characters often appear when bytes were mis-decoded as Latin-1.
  if (_mojibakeC1Pattern.hasMatch(value)) return true;

  // Common CP1252-decoded UTF-8 artifact prefix: "Ã¢â‚¬â€¦"
  if (value.contains('\u00E2\u20AC')) return true;

  // Marker bytes (0xC2/0xC3/0xC4/0xC5/0xD0/0xD1) followed by likely UTF-8 continuation bytes or
  // CP1252 "extended" punctuation.
  if (_mojibakeMarkerPattern.hasMatch(value)) return true;

  // UTF-8 BOM decoded as Latin-1:
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
    debugPrint("Global Hata YakalandÃ„Â±: $error");
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
  static const int _premiumActivatedNotificationId = 12100;

  bool _isLoading = true;
  late String _startupLoadingText;
  bool _showRealApp = false;
  bool _isAppEnabled = true;
  bool _isUpdateRequired = false;
  String _updateMessage = "";
  String _debugError = "";

  @override
  void initState() {
    super.initState();
    _startupLoadingText = _startupLoadingTextForLocale(Platform.localeName);
    _initializeApp();
  }

  Future<void> _loadStartupLoadingLanguagePreference() async {
    String resolved = _startupLoadingTextForLocale(Platform.localeName);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String pref =
          (prefs.getString('language_code') ?? '').trim().toLowerCase();
      if (pref.isNotEmpty) {
        resolved = _startupLoadingTextForAppSetting(pref);
      }
    } catch (_) {}

    _startupLoadingText = resolved;
    if (mounted && _isLoading) {
      setState(() {});
    }
  }

  Future<void> _initializeApp() async {
    await _loadStartupLoadingLanguagePreference();
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone hatasÃ„Â±: $e');
    }

    try {
      await _initNotifications();
    } catch (e) {
      debugPrint('Bildirim baÃ…Å¸latma hatasÃ„Â±: $e');
    }

    try {
      await _fetchConfig();
    } catch (e) {
      debugPrint('Config hatasÃ„Â±: $e');
      final String langCode =
          Platform.localeName.toLowerCase().split(RegExp(r'[_-]')).first.trim();
      _debugError = localizeTrEn(
        langCode,
        'BaÃ„Å¸lantÃ„Â± hatasÃ„Â±. LÃƒÂ¼tfen tekrar deneyin.',
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
    const AndroidNotificationChannel purchaseChannel =
        AndroidNotificationChannel(
      'purchase_status_channel',
      'Purchase Status',
      description: 'Purchase and subscription confirmations',
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
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(purchaseChannel);
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
      final String title = localizeTrEn(
          langCode, 'Takipten Çıkanlar Olabilir!', 'You May Have Unfollowers!');
      final String body = localizeTrEn(
        langCode,
        'Hesabını kontrol et!',
        'Check your account!',
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
        debugPrint('ZonedSchedule hatasÃ„Â±: $e');
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
    unawaited(_adConsentFlow.start(
      gatherConsent: _gatherAdConsent,
      requestTracking: _requestTrackingAuthorizationIfNeeded,
      initializeAds: _initializeMobileAds,
      onError: (error) => debugPrint('Ad consent flow failed: $error'),
    ));
  }

  Future<void> _gatherAdConsent() async {
    final update = Completer<FormError?>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => update.complete(null),
      (error) => update.complete(error),
    );
    final updateError = await update.future;
    if (updateError != null) throw updateError;

    // The Future completes only when UMP has dismissed all required forms.
    FormError? formError;
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      formError = error;
    });
    if (formError != null) throw formError!;
  }

  Future<void> _initializeMobileAds() async {
    if (await ConsentInformation.instance.canRequestAds()) {
      final InitializationStatus initStatus =
          await MobileAds.instance.initialize();
      if (kDebugMode) {
        AdapterStatus? unityStatus;
        String unityAdapterName = '';
        for (final entry in initStatus.adapterStatuses.entries) {
          if (entry.key.toLowerCase().contains('unity')) {
            unityAdapterName = entry.key;
            unityStatus = entry.value;
            break;
          }
        }
        if (unityStatus == null) {
          debugPrint('Unity mediation adapter was not found at init.');
        } else {
          debugPrint(
            'Unity mediation adapter: $unityAdapterName, state=${unityStatus.state}, latencyMs=${unityStatus.latency}, desc=${unityStatus.description}',
          );
        }
      }
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
        'BaÃ„Å¸lantÃ„Â± hatasÃ„Â±. LÃƒÂ¼tfen tekrar deneyin.',
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
          'Yeni gÃƒÂ¼ncelleme mevcut! LÃƒÂ¼tfen maÃ„Å¸azayÃ„Â± kontrol edin.',
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
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: ModernLoader(text: _startupLoadingText)),
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
            'Ã„Â°yi haber! GÃƒÂ¼ncelleme mevcut. MaÃ„Å¸azamÃ„Â±zÃ„Â± kontrol edip yeni sÃƒÂ¼rÃƒÂ¼mÃƒÂ¼ indir!',
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
                          'Ã„Â°yi haber! GÃƒÂ¼ncelleme mevcut',
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
                  localizeTrEn(langCode, 'SÃ„Â°STEM BAKIMDA',
                      'SYSTEM UNDER MAINTENANCE'),
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
  'tr': 'BUNLARI BILIYOR MUYDUNUZ?',
  'en': 'DID YOU KNOW?',
  'de': 'WUSSTEN SIE?',
  'ko': 'Ã¬â€¢Å’ÃªÂ³Â  ÃªÂ³â€Ã¬â€¦Â¨Ã«â€šËœÃ¬Å¡â€?',
  'ja': 'Ã§Å¸Â¥Ã£ÂÂ£Ã£ÂÂ¦Ã£Ââ€Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£Ââ€¹Ã¯Â¼Å¸',
  'ru': 'Äâ€”ÄÂÄÂÄâ€ºÄËœ Äâ€ºÄËœ Äâ€™ÄÂ«?',
  'pt': 'VOCÃƒÅ  SABIA?',
  'ar': 'Ã™â€¡Ã™â€ Ã˜ÂªÃ˜Â¹Ã™â€Ã™â€¦Ã˜Å¸',
  'es': 'Ã‚Â¿SABÃƒÂAS QUE?',
  'es-mx': 'Ã‚Â¿SABÃƒÂAS QUE?',
  'hi':
      'Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤â€ Ã Â¤Âª Ã Â¤Å“Ã Â¤Â¾Ã Â¤Â¨Ã Â¤Â¤Ã Â¥â€¡ Ã Â¤Â¹Ã Â¥Ë†Ã Â¤â€š?',
  'hu': 'TUDTAD?',
  'zh-hans': 'Ã¤Â½Â Ã§Å¸Â¥Ã©Ââ€œÃ¥Ââ€”Ã¯Â¼Å¸',
  'id': 'TAHUKAH ANDA?',
  'nl': 'WIST JE DIT?',
  'fr': 'LE SAVIEZ-VOUS ?',
  'it': 'LO SAPEVI?',
  'vi': 'BÃ¡ÂºÂ N CÃƒâ€œ BIÃ¡ÂºÂ¾T KHÃƒâ€NG?',
  'th':
      'Ã Â¸â€Ã Â¸Â¸Ã Â¸â€œÃ Â¸Â£Ã Â¸Â¹Ã Â¹â€°Ã Â¸Â«Ã Â¸Â£Ã Â¸Â·Ã Â¸Â­Ã Â¹â€Ã Â¸Â¡Ã Â¹Ë†?',
  'pl': 'CZY WIESZ?',
};

String _didYouKnowLabelForLang(String lang) {
  final String code = _normalizedUiLanguageCode(lang);
  String label = _didYouKnowLabels[code] ?? '';
  if (label.trim().isEmpty) {
    label = localizeTrEn(
      code,
      _didYouKnowLabels['tr'] ?? 'DID YOU KNOW?',
      _didYouKnowLabels['en'] ?? 'DID YOU KNOW?',
    );
  }
  final String repaired = _repairDisplayText(label).trim();
  if (_looksLikeMojibakeText(repaired)) {
    return _didYouKnowLabels['en'] ?? 'DID YOU KNOW?';
  }
  return repaired;
}

const Map<String, String> _analysisRemainingTimeLabels = <String, String>{
  'tr': 'Tahmini kalan sÃƒÂ¼re: {time}',
  'en': 'Estimated time left: {time}',
  'de': 'Geschatzte verbleibende Zeit: {time}',
  'ko': 'Ã¬ËœË†Ã¬Æ’Â Ã«â€šÂ¨Ã¬Ââ‚¬ Ã¬â€¹Å“ÃªÂ°â€: {time}',
  'ja': 'Ã¦ÂÂ¨Ã¥Â®Å¡Ã¦Â®â€¹Ã£â€šÅ Ã¦â„¢â€šÃ©â€“â€œ: {time}',
  'ru':
      'ÄÅ¸Ã‘â‚¬ÄÂ¸ÄÂ¼ÄÂµÃ‘â‚¬ÄÂ½ÄÂ¾ÄÂµ ÄÂ¾Ã‘ÂÃ‘â€šÄÂ°ÄÂ²Ã‘Ë†ÄÂµÄÂµÃ‘ÂÃ‘Â ÄÂ²Ã‘â‚¬ÄÂµÄÂ¼Ã‘Â: {time}',
  'pt': 'Tempo restante estimado: {time}',
  'ar':
      'Ã˜Â§Ã™â€Ã™Ë†Ã™â€šÃ˜Âª Ã˜Â§Ã™â€Ã™â€¦Ã˜ÂªÃ˜Â¨Ã™â€šÃ™Å  Ã˜Â§Ã™â€Ã˜ÂªÃ™â€šÃ˜Â¯Ã™Å Ã˜Â±Ã™Å : {time}',
  'es': 'Tiempo restante estimado: {time}',
  'es-mx': 'Tiempo restante estimado: {time}',
  'hi':
      'Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â®Ã Â¤Â¾Ã Â¤Â¨Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤Â¶Ã Â¥â€¡Ã Â¤Â· Ã Â¤Â¸Ã Â¤Â®Ã Â¤Â¯: {time}',
  'hu': 'Becsult hatralevo ido: {time}',
  'zh-hans': 'Ã©Â¢â€Ã¨Â®Â¡Ã¥â€°Â©Ã¤Â½â„¢Ã¦â€”Â¶Ã©â€”Â´Ã¯Â¼Å¡{time}',
  'id': 'Perkiraan waktu tersisa: {time}',
  'nl': 'Geschatte resterende tijd: {time}',
  'fr': 'Temps restant estime : {time}',
  'it': 'Tempo rimanente stimato: {time}',
  'vi': 'Thoi gian con lai uoc tinh: {time}',
  'th':
      'Ã Â¹â‚¬Ã Â¸Â§Ã Â¸Â¥Ã Â¸Â²Ã Â¸â€”Ã Â¸ÂµÃ Â¹Ë†Ã Â¹â‚¬Ã Â¸Â«Ã Â¸Â¥Ã Â¸Â·Ã Â¸Â­Ã Â¹â€šÃ Â¸â€Ã Â¸Â¢Ã Â¸â€ºÃ Â¸Â£Ã Â¸Â°Ã Â¸Â¡Ã Â¸Â²Ã Â¸â€œ: {time}',
  'pl': 'Szacowany pozostaly czas: {time}',
};

const Map<String, String> _analysisRemainingPreparingLabels = <String, String>{
  'tr': 'Kalan sÃƒÂ¼re hesaplanÃ„Â±yor...',
  'en': 'Estimating remaining time...',
  'de': 'Verbleibende Zeit wird geschatzt...',
  'ko': 'Ã«â€šÂ¨Ã¬Ââ‚¬ Ã¬â€¹Å“ÃªÂ°â€ ÃªÂ³â€Ã¬â€šÂ° Ã¬Â¤â€˜...',
  'ja': 'Ã¦Â®â€¹Ã£â€šÅ Ã¦â„¢â€šÃ©â€“â€œÃ£â€šâ€™Ã¨Â¨Ë†Ã§Â®â€”Ã¤Â¸Â­...',
  'ru':
      'ÄÂÃ‘â€ ÄÂµÄÂ½ÄÂºÄÂ° ÄÂ¾Ã‘ÂÃ‘â€šÄÂ°ÄÂ²Ã‘Ë†ÄÂµÄÂ³ÄÂ¾Ã‘ÂÃ‘Â ÄÂ²Ã‘â‚¬ÄÂµÄÂ¼ÄÂµÄÂ½ÄÂ¸...',
  'pt': 'Estimando tempo restante...',
  'ar':
      'Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Â Ã˜ÂªÃ™â€šÃ˜Â¯Ã™Å Ã˜Â± Ã˜Â§Ã™â€Ã™Ë†Ã™â€šÃ˜Âª Ã˜Â§Ã™â€Ã™â€¦Ã˜ÂªÃ˜Â¨Ã™â€šÃ™Å ...',
  'es': 'Calculando el tiempo restante...',
  'es-mx': 'Calculando el tiempo restante...',
  'hi':
      'Ã Â¤Â¶Ã Â¥â€¡Ã Â¤Â· Ã Â¤Â¸Ã Â¤Â®Ã Â¤Â¯ Ã Â¤â€¢Ã Â¤Â¾ Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â®Ã Â¤Â¾Ã Â¤Â¨ Ã Â¤Â²Ã Â¤â€”Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾ Ã Â¤Â°Ã Â¤Â¹Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†...',
  'hu': 'Hatralevo ido becslese...',
  'zh-hans': 'Ã¦Â­Â£Ã¥Å“Â¨Ã¤Â¼Â°Ã§Â®â€”Ã¥â€°Â©Ã¤Â½â„¢Ã¦â€”Â¶Ã©â€”Â´...',
  'id': 'Sedang memperkirakan waktu tersisa...',
  'nl': 'Resterende tijd wordt geschat...',
  'fr': 'Estimation du temps restant...',
  'it': 'Stima del tempo rimanente...',
  'vi': 'Dang uoc tinh thoi gian con lai...',
  'th':
      'Ã Â¸ÂÃ Â¸Â³Ã Â¸Â¥Ã Â¸Â±Ã Â¸â€¡Ã Â¸â€Ã Â¸Â³Ã Â¸â„¢Ã Â¸Â§Ã Â¸â€œÃ Â¹â‚¬Ã Â¸Â§Ã Â¸Â¥Ã Â¸Â²Ã Â¸â€”Ã Â¸ÂµÃ Â¹Ë†Ã Â¹â‚¬Ã Â¸Â«Ã Â¸Â¥Ã Â¸Â·Ã Â¸Â­...',
  'pl': 'Trwa szacowanie pozostalego czasu...',
};

const Map<String, String> _logoutButtonLabels = <String, String>{
  'tr': 'Ãƒâ€¡IKIÃ…Â YAP',
  'en': 'LOG OUT',
  'de': 'ABMELDEN',
  'ko': 'Ã«Â¡Å“ÃªÂ·Â¸Ã¬â€¢â€Ã¬â€ºÆ’',
  'ja': 'Ã£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¢Ã£â€šÂ¦Ã£Æ’Ë†',
  'ru': 'Äâ€™ÄÂ«Äâ„¢ÄÂ¢ÄËœ',
  'pt': 'SAIR',
  'ar': 'Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â®Ã˜Â±Ã™Ë†Ã˜Â¬',
  'es': 'CERRAR SESION',
  'es-mx': 'CERRAR SESION',
  'hi': 'Ã Â¤Â²Ã Â¥â€°Ã Â¤â€” Ã Â¤â€ Ã Â¤â€°Ã Â¤Å¸',
  'hu': 'KIJELENTKEZES',
  'zh-hans': 'Ã©â‚¬â‚¬Ã¥â€¡ÂºÃ§â„¢Â»Ã¥Â½â€¢',
  'id': 'KELUAR',
  'nl': 'UITLOGGEN',
  'fr': 'SE DECONNECTER',
  'it': 'DISCONNETTITI',
  'vi': 'DANG XUAT',
  'th': 'Ã Â¸Â­Ã Â¸Â­Ã Â¸ÂÃ Â¸Ë†Ã Â¸Â²Ã Â¸ÂÃ Â¸Â£Ã Â¸Â°Ã Â¸Å¡Ã Â¸Å¡',
  'pl': 'WYLOGUJ',
};

const Map<String, String> _detailOpenProfileLabels = <String, String>{
  'tr': 'Profile Git',
  'en': 'Open Profile',
  'de': 'Profil ÃƒÂ¶ffnen',
  'ko': 'Ã­â€â€Ã«Â¡Å“Ã­â€¢â€ Ã¬â€”Â´ÃªÂ¸Â°',
  'ja': 'Ã£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ£Ã£Æ’Â¼Ã£Æ’Â«Ã£â€šâ€™Ã©â€“â€¹Ã£ÂÂ',
  'ru': 'ÄÂÃ‘â€šÄÂºÃ‘â‚¬Ã‘â€¹Ã‘â€šÃ‘Å’ ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂ¸ÄÂ»Ã‘Å’',
  'pt': 'Abrir perfil',
  'ar': 'Ã™ÂÃ˜ÂªÃ˜Â­ Ã˜Â§Ã™â€Ã™â€¦Ã™â€Ã™Â Ã˜Â§Ã™â€Ã˜Â´Ã˜Â®Ã˜ÂµÃ™Å ',
  'es': 'Abrir perfil',
  'es-mx': 'Abrir perfil',
  'hi':
      'Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤â€“Ã Â¥â€¹Ã Â¤Â²Ã Â¥â€¡Ã Â¤â€š',
  'hu': 'Profil megnyitasa',
  'zh-hans': 'Ã¦â€°â€œÃ¥Â¼â‚¬Ã¤Â¸ÂªÃ¤ÂºÂºÃ¨Âµâ€Ã¦â€“â„¢',
  'id': 'Buka profil',
  'nl': 'Profiel openen',
  'fr': 'Ouvrir le profil',
  'it': 'Apri profilo',
  'vi': 'Mo ho so',
  'th':
      'Ã Â¹â‚¬Ã Â¸â€ºÃ Â¸Â´Ã Â¸â€Ã Â¹â€šÃ Â¸â€ºÃ Â¸Â£Ã Â¹â€Ã Â¸Å¸Ã Â¸Â¥Ã Â¹Å’',
  'pl': 'Otworz profil',
};

String _normalizedUiLanguageCode(String lang) {
  final String normalized = lang.trim().toLowerCase().replaceAll('_', '-');
  if (normalized.startsWith('es'))
    return normalized == 'es-mx' ? 'es-mx' : 'es';
  if (normalized.startsWith('fr-'))
    return normalized == 'fr-ca' ? 'fr-ca' : 'fr';
  if (normalized.startsWith('pt-'))
    return normalized == 'pt-pt' ? 'pt-pt' : 'pt';
  if (normalized.startsWith('zh')) {
    if (normalized.contains('hant') ||
        normalized.endsWith('-tw') ||
        normalized.endsWith('-hk') ||
        normalized.endsWith('-mo')) {
      return 'zh-hant';
    }
    return 'zh-hans';
  }
  if (normalized == 'in') return 'id';
  return normalized;
}

String _lookupUiTextByLang(Map<String, String> labels, String lang) {
  final String code = _normalizedUiLanguageCode(lang);
  final String enBase = labels['en'] ?? '';
  final String trBase = labels['tr'] ?? enBase;
  String raw = labels[code] ?? '';
  if (raw.trim().isEmpty && enBase.isNotEmpty) {
    raw = localizeTrEn(code, trBase, enBase);
  }
  final String repaired = _repairDisplayText(raw).trim();
  if (repaired.isNotEmpty && !_looksLikeMojibakeText(repaired)) {
    return repaired;
  }
  return _repairDisplayText(enBase).trim();
}

String _analysisRemainingTextForLang(String lang, String time) {
  final String template =
      _lookupUiTextByLang(_analysisRemainingTimeLabels, lang);
  return template.replaceAll('{time}', time);
}

String _analysisRemainingPreparingForLang(String lang) {
  return _lookupUiTextByLang(_analysisRemainingPreparingLabels, lang);
}

String _logoutButtonTextForLang(String lang) {
  return _lookupUiTextByLang(_logoutButtonLabels, lang);
}

String _detailOpenProfileTextForLang(String lang) {
  return _lookupUiTextByLang(_detailOpenProfileLabels, lang);
}

const List<Map<String, String>> _analysisDidYouKnowFacts = [
  {
    'tr':
        'Kargalar sadece insan yÃƒÂ¼zlerini tanÃ„Â±makla kalmaz, kendilerine kÃƒÂ¶tÃƒÂ¼ davrananlarÃ„Â± yÃ„Â±llarca unutmaz ve diÃ„Å¸er kargalara da bunu haber verirler.',
    'en':
        'Crows donÃ¢â‚¬â„¢t just recognize human faces; they can remember people who treated them badly for yearsÃ¢â‚¬â€and even warn other crows.',
  },
  {
    'tr':
        "Kediler hayatlarÃ„Â±nÃ„Â±n yaklaÃ…Å¸Ã„Â±k %70'ini uyuyarak geÃƒÂ§irirler; yani 10 yaÃ…Å¸Ã„Â±ndaki bir kedi aslÃ„Â±nda sadece 3 yÃ„Â±l uyanÃ„Â±k kalmÃ„Â±Ã…Å¸tÃ„Â±r.",
    'en':
        'Cats spend about 70% of their lives asleepÃ¢â‚¬â€so a 10-year-old cat has been awake for only about 3 years.',
  },
  {
    'tr':
        'Bal asla bozulmaz; arkeologlar MÃ„Â±sÃ„Â±r piramitlerinde 3000 yÃ„Â±llÃ„Â±k bozulmamÃ„Â±Ã…Å¸ ve hala yenilebilir durumda olan bal kavanozlarÃ„Â± bulmuÃ…Å¸lardÃ„Â±r.',
    'en':
        'Honey never spoils; archaeologists have found 3,000-year-old jars of honey in Egyptian pyramids that were still edible.',
  },
  {
    'tr':
        'Su samurlarÃ„Â±, uyurken akÃ„Â±ntÃ„Â±ya kapÃ„Â±lÃ„Â±p birbirlerinden ayrÃ„Â±lmamak iÃƒÂ§in el ele tutuÃ…Å¸urlar.',
    'en':
        'Sea otters hold hands while they sleep so they donÃ¢â‚¬â„¢t drift apart in the current.',
  },
  {
    'tr':
        "VenÃƒÂ¼s'te bir gÃƒÂ¼n, bir yÃ„Â±ldan daha uzun sÃƒÂ¼rer; yani kendi etrafÃ„Â±nda dÃƒÂ¶nmesi, GÃƒÂ¼neÃ…Å¸ etrafÃ„Â±nda dÃƒÂ¶nmesinden daha yavaÃ…Å¸tÃ„Â±r.",
    'en':
        'On Venus, a day is longer than a yearÃ¢â‚¬â€it rotates on its axis more slowly than it orbits the Sun.',
  },
  {
    'tr':
        'Ãƒâ€¡akmak, kibritten ÃƒÂ¶nce icat edilmiÃ…Å¸tir; bazen teknoloji sandÃ„Â±Ã„Å¸Ã„Â±mÃ„Â±zdan daha eski kafalÃ„Â± olabiliyor.',
    'en':
        'The lighter was invented before the matchÃ¢â‚¬â€sometimes Ã¢â‚¬Å“oldÃ¢â‚¬Â tech is older than we think.',
  },
  {
    'tr':
        'AhtapotlarÃ„Â±n ÃƒÂ¼ÃƒÂ§ tane kalbi ve tam dokuz tane beyni vardÃ„Â±r; bir Ã…Å¸eyi unutma lÃƒÂ¼ksleri pek yok gibi.',
    'en':
        'Octopuses have three hearts and nine brainsÃ¢â‚¬â€forgetting things isnÃ¢â‚¬â„¢t really an option.',
  },
  {
    'tr':
        'Ã„Â°neklerin "en yakÃ„Â±n arkadaÃ…Å¸larÃ„Â±" vardÃ„Â±r ve onlardan ayrÃ„Â±ldÃ„Â±klarÃ„Â±nda ciddi Ã…Å¸ekilde strese girip aÃ„Å¸layabilirler.',
    'en':
        'Cows have Ã¢â‚¬Å“best friends,Ã¢â‚¬Â and they can get seriously stressedÃ¢â‚¬â€and even cryÃ¢â‚¬â€when separated.',
  },
  {
    'tr':
        'DÃƒÂ¼nyadaki ilk bilgisayar virÃƒÂ¼sÃƒÂ¼ "Creeper" adÃ„Â±ndaydÃ„Â± ve ekranda sadece "Ben bir sarmaÃ…Å¸Ã„Â±Ã„Å¸Ã„Â±m, yakalayabiliyorsan yakala!" yazÃ„Â±yordu.',
    'en':
        'The worldÃ¢â‚¬â„¢s first computer virus was called Ã¢â‚¬Å“Creeper,Ã¢â‚¬Â and it displayed: Ã¢â‚¬Å“IÃ¢â‚¬â„¢m the creeper, catch me if you can!Ã¢â‚¬Â',
  },
  {
    'tr':
        'Bir bulutun aÃ„Å¸Ã„Â±rlÃ„Â±Ã„Å¸Ã„Â± ortalama 500 bin kilogramdÃ„Â±r; yani tepemizde yÃƒÂ¼zen devasa bir fil sÃƒÂ¼rÃƒÂ¼sÃƒÂ¼ gibi dÃƒÂ¼Ã…Å¸ÃƒÂ¼nebilirsin.',
    'en':
        'An average cloud can weigh around 500,000 kgÃ¢â‚¬â€like a massive herd of elephants floating overhead.',
  },
  {
    'tr':
        'Ã„Â°nsan DNA\'sÃ„Â± ile bir muzun DNA\'sÃ„Â± %50 oranÃ„Â±nda benzerdir; yani yarÃ„Â±n sabah bir muza "kardeÃ…Å¸im" dersen pek de haksÃ„Â±z sayÃ„Â±lmazsÃ„Â±n.',
    'en':
        'Human DNA is about 50% similar to banana DNAÃ¢â‚¬â€so calling a banana Ã¢â‚¬Å“my siblingÃ¢â‚¬Â tomorrow morning isnÃ¢â‚¬â„¢t totally unfair.',
  },
  {
    'tr':
        'Kutup ayÃ„Â±larÃ„Â±nÃ„Â±n derisi aslÃ„Â±nda siyahtÃ„Â±r, tÃƒÂ¼yleri ise Ã…Å¸effaftÃ„Â±r; beyaz gÃƒÂ¶rÃƒÂ¼nmesi sadece bir Ã„Â±Ã…Å¸Ã„Â±k yansÃ„Â±masÃ„Â± hilesidir.',
    'en':
        'Polar bears actually have black skin, and their fur is transparent; they look white because of how light scatters.',
  },
  {
    'tr':
        'Uzayda aÃ„Å¸layamazsÃ„Â±nÃ„Â±z ÃƒÂ§ÃƒÂ¼nkÃƒÂ¼ yerÃƒÂ§ekimi olmadÃ„Â±Ã„Å¸Ã„Â± iÃƒÂ§in gÃƒÂ¶zyaÃ…Å¸larÃ„Â±nÃ„Â±z yÃƒÂ¼zÃƒÂ¼nÃƒÂ¼zden aÃ…Å¸aÃ„Å¸Ã„Â± sÃƒÂ¼zÃƒÂ¼lmez, gÃƒÂ¶zÃƒÂ¼nÃƒÂ¼zde bir top gibi birikir.',
    'en':
        'You canÃ¢â‚¬â„¢t really cry in space: without gravity, tears donÃ¢â‚¬â„¢t run down your faceÃ¢â‚¬â€they form a blob in your eye.',
  },
  {
    'tr':
        'Everest DaÃ„Å¸Ã„Â± her yÃ„Â±l yaklaÃ…Å¸Ã„Â±k 4 milimetre kadar uzamaya devam ediyor; yani dÃƒÂ¼nya hala bÃƒÂ¼yÃƒÂ¼yor.',
    'en':
        'Mount Everest keeps growing by about 4 millimeters each yearÃ¢â‚¬â€Earth is still changing.',
  },
  {
    'tr':
        'IslÃ„Â±k ÃƒÂ§alan fareler aslÃ„Â±nda birbirlerine Ã…Å¸arkÃ„Â± sÃƒÂ¶ylerler ama bu sesler insan kulaÃ„Å¸Ã„Â±nÃ„Â±n duyamayacaÃ„Å¸Ã„Â± kadar yÃƒÂ¼ksek frekanstadÃ„Â±r.',
    'en':
        'Ã¢â‚¬Å“WhistlingÃ¢â‚¬Â mice are essentially singing to each other, but at frequencies too high for humans to hear.',
  },
  {
    'tr':
        'KÃƒÂ¶pekbalÃ„Â±klarÃ„Â± aÃ„Å¸aÃƒÂ§lardan daha eskidir; dÃƒÂ¼nyada yaklaÃ…Å¸Ã„Â±k 400 milyon yÃ„Â±ldÃ„Â±r varlar, aÃ„Å¸aÃƒÂ§lar ise sadece 350 milyon yÃ„Â±ldÃ„Â±r.',
    'en':
        'Sharks are older than treesÃ¢â‚¬â€sharks have been around for about 400 million years, trees for about 350 million.',
  },
  {
    'tr':
        'Muzlar aslÃ„Â±nda botanik olarak meyve (berry) sayÃ„Â±lÃ„Â±rken, ÃƒÂ§ilekler bu gruba girmez; botanik dÃƒÂ¼nyasÃ„Â± biraz karÃ„Â±Ã…Å¸Ã„Â±k.',
    'en':
        'Bananas are botanically berries, but strawberries arenÃ¢â‚¬â„¢tÃ¢â‚¬â€botany can be weird.',
  },
  {
    'tr':
        'Bir karÃ„Â±nca kendi aÃ„Å¸Ã„Â±rlÃ„Â±Ã„Å¸Ã„Â±nÃ„Â±n 50 katÃ„Â±nÃ„Â± kaldÃ„Â±rabilir; eÃ„Å¸er sen bir karÃ„Â±nca olsaydÃ„Â±n, bir otomobili tek baÃ…Å¸Ã„Â±na kaldÃ„Â±rabilirdin.',
    'en':
        'An ant can lift up to 50 times its own weightÃ¢â‚¬â€if you were an ant, you could lift a car by yourself.',
  },
  {
    'tr':
        "Eyfel Kulesi yaz aylarÃ„Â±nda genleÃ…Å¸me nedeniyle yaklaÃ…Å¸Ã„Â±k 15 santimetre kadar uzayabilir.",
    'en':
        'The Eiffel Tower can grow by about 15 centimeters in summer due to thermal expansion.',
  },
  {
    'tr':
        'DÃƒÂ¼nyadaki tÃƒÂ¼m insanlarÃ„Â±n toplam aÃ„Å¸Ã„Â±rlÃ„Â±Ã„Å¸Ã„Â±, dÃƒÂ¼nyadaki tÃƒÂ¼m karÃ„Â±ncalarÃ„Â±n toplam aÃ„Å¸Ã„Â±rlÃ„Â±Ã„Å¸Ã„Â±na neredeyse eÃ…Å¸ittir.',
    'en':
        'The total weight of all humans on Earth is roughly comparable to the total weight of all ants.',
  },
  {
    'tr':
        'Tembel hayvanlar nefeslerini su altÃ„Â±nda yunuslardan daha uzun sÃƒÂ¼re tutabilirler; tam 40 dakika boyunca suyun altÃ„Â±nda kalabilirler.',
    'en':
        'Sloths can hold their breath underwater longer than dolphinsÃ¢â‚¬â€up to about 40 minutes.',
  },
  {
    'tr':
        "GÃƒÂ¼vercinler, Picasso ve Monet'nin tablolarÃ„Â± arasÃ„Â±ndaki farkÃ„Â± ayÃ„Â±rt edebilirler; yani sandÃ„Â±Ã„Å¸Ã„Â±ndan ÃƒÂ§ok daha sanatsal bir vizyona sahipler.",
    'en':
        'Pigeons can tell the difference between paintings by Picasso and MonetÃ¢â‚¬â€turns out theyÃ¢â‚¬â„¢re more art-savvy than we think.',
  },
  {
    'tr':
        'GPS sistemi aslÃ„Â±nda dÃƒÂ¼nya ÃƒÂ§apÃ„Â±nda ÃƒÂ¼cretsizdir ancak ABD hÃƒÂ¼kÃƒÂ¼meti bu sistemi ÃƒÂ§alÃ„Â±Ã…Å¸Ã„Â±r halde tutmak iÃƒÂ§in gÃƒÂ¼nde yaklaÃ…Å¸Ã„Â±k 2 milyon dolar harcar.',
    'en':
        'GPS is free to use worldwide, but the U.S. government reportedly spends around \$2 million a day to keep it running.',
  },
  {
    'tr':
        'PlatipuslarÃ„Â±n (orkinitorenk) mideleri yoktur; yedikleri besinler yemek borusundan doÃ„Å¸rudan baÃ„Å¸Ã„Â±rsaklarÃ„Â±na geÃƒÂ§er.',
    'en':
        'Platypuses donÃ¢â‚¬â„¢t have stomachsÃ¢â‚¬â€food goes from the esophagus straight to the intestines.',
  },
  {
    'tr':
        '"Swagger" (havalÃ„Â± yÃƒÂ¼rÃƒÂ¼yÃƒÂ¼Ã…Å¸/tavÃ„Â±r) kelimesini ilk kez William Shakespeare kullanmÃ„Â±Ã…Å¸tÃ„Â±r; adam 16. yÃƒÂ¼zyÃ„Â±lda bile ortama Ã…Å¸eklini koymuÃ…Å¸.',
    'en':
        'William Shakespeare is credited with the first recorded use of the word Ã¢â‚¬Å“swaggerÃ¢â‚¬ÂÃ¢â‚¬â€even in the 16th century, he had style.',
  },
  {
    'tr':
        'Mavi balinalarÃ„Â±n kalbi o kadar bÃƒÂ¼yÃƒÂ¼ktÃƒÂ¼r ki, bir insan ana atardamarlarÃ„Â±nÃ„Â±n iÃƒÂ§inde rahatÃƒÂ§a yÃƒÂ¼zebilir.',
    'en':
        'A blue whaleÃ¢â‚¬â„¢s heart is so large that a human could swim through its main arteries.',
  },
  {
    'tr':
        'KarÃ„Â±ncalarÃ„Â±n akciÃ„Å¸erleri yoktur ve asla uyumazlar; tam bir iÃ…Å¸kolik gibi 7/24 ÃƒÂ§alÃ„Â±Ã…Å¸Ã„Â±rlar.',
    'en':
        'Ants donÃ¢â‚¬â„¢t have lungsÃ¢â‚¬â€and they never truly Ã¢â‚¬Å“sleepÃ¢â‚¬Â; they operate nonstop like tiny workaholics.',
  },
  {
    'tr':
        "SatÃƒÂ¼rn ve JÃƒÂ¼piter'de kelimenin tam anlamÃ„Â±yla elmas yaÃ„Å¸muru yaÃ„Å¸ar; zengin olmak iÃƒÂ§in yanlÃ„Â±Ã…Å¸ gezegende yaÃ…Å¸Ã„Â±yoruz.",
    'en':
        'On Saturn and Jupiter, it can literally rain diamondsÃ¢â‚¬â€apparently weÃ¢â‚¬â„¢re living on the wrong planet.',
  },
  {
    'tr':
        'Bal arÃ„Â±larÃ„Â± insan yÃƒÂ¼zlerini tanÃ„Â±yabilir ve onlarÃ„Â± tek tek hafÃ„Â±zalarÃ„Â±na kaydedebilirler.',
    'en': 'Honeybees can recognize human faces and remember them individually.',
  },
  {
    'tr':
        'Su aygÃ„Â±rlarÃ„Â±nÃ„Â±n teri aslÃ„Â±nda pembe renklidir ve bu ter hem gÃƒÂ¼neÃ…Å¸ kremi hem de mikrop ÃƒÂ¶ldÃƒÂ¼rÃƒÂ¼cÃƒÂ¼ yerine geÃƒÂ§er.',
    'en':
        'Hippo Ã¢â‚¬Å“sweatÃ¢â‚¬Â can look pink and acts like both sunscreen and an antibacterial shield.',
  },
  {
    'tr':
        'VombatlarÃ„Â±n dÃ„Â±Ã…Å¸kÃ„Â±larÃ„Â± kÃƒÂ¼p Ã…Å¸eklindedir; bu sayede dÃ„Â±Ã…Å¸kÃ„Â±larÃ„Â± yokuÃ…Å¸ aÃ…Å¸aÃ„Å¸Ã„Â± yuvarlanmaz ve bÃƒÂ¶lgelerini iÃ…Å¸aretlemek iÃƒÂ§in sabit durur.',
    'en':
        'Wombat poop is cube-shaped, so it doesnÃ¢â‚¬â„¢t roll away and can mark territory more effectively.',
  },
  {
    'tr':
        'Kaju fÃ„Â±stÃ„Â±Ã„Å¸Ã„Â± aslÃ„Â±nda bir meyvenin (kaju elmasÃ„Â±) en ucunda, meyvenin dÃ„Â±Ã…Å¸Ã„Â±nda yetiÃ…Å¸ir; oldukÃƒÂ§a tuhaf bir gÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼sÃƒÂ¼ vardÃ„Â±r.',
    'en':
        'Cashews grow outside the cashew apple, hanging at the very endÃ¢â‚¬â€an oddly surprising design.',
  },
  {
    'tr':
        "KÃƒÂ¶pekbalÃ„Â±klarÃ„Â±, SatÃƒÂ¼rn'ÃƒÂ¼n halkalarÃ„Â±ndan daha eskidir; SatÃƒÂ¼rn o gÃƒÂ¶steriÃ…Å¸li halkalarÃ„Â±nÃ„Â± takÃ„Â±nmadan milyonlarca yÃ„Â±l ÃƒÂ¶nce kÃƒÂ¶pekbalÃ„Â±klarÃ„Â± dÃƒÂ¼nyadaydÃ„Â±.",
    'en':
        'Sharks are older than SaturnÃ¢â‚¬â„¢s ringsÃ¢â‚¬â€they were around millions of years before Saturn got its famous bling.',
  },
  {
    'tr':
        'Kelebekler ayaklarÃ„Â±yla tat alÃ„Â±rlar; bir yapraÃ„Å¸Ã„Â±n ÃƒÂ¼zerine konduklarÃ„Â±nda aslÃ„Â±nda akÃ…Å¸am yemeÃ„Å¸inin tadÃ„Â±na bakÃ„Â±yorlar.',
    'en':
        'Butterflies taste with their feetÃ¢â‚¬â€when they land on a leaf, theyÃ¢â‚¬â„¢re basically sampling dinner.',
  },
  {
    'tr':
        'Bir salyangoz tam 3 yÃ„Â±l boyunca hiÃƒÂ§ uyanmadan uyuyabilir; bazen hepimizin buna ihtiyacÃ„Â± var.',
    'en':
        'A snail can sleep for up to three years without waking upÃ¢â‚¬â€honestly, relatable.',
  },
  {
    'tr':
        'Deve kuÃ…Å¸larÃ„Â±nÃ„Â±n gÃƒÂ¶zleri beyinlerinden daha bÃƒÂ¼yÃƒÂ¼ktÃƒÂ¼r; bakmakla gÃƒÂ¶rmek arasÃ„Â±ndaki o ince ÃƒÂ§izgide yaÃ…Å¸Ã„Â±yorlar.',
    'en':
        'An ostrichÃ¢â‚¬â„¢s eyes are bigger than its brainÃ¢â‚¬â€living on the fine line between looking and thinking.',
  },
  {
    'tr':
        'Flamingolar aslÃ„Â±nda gri doÃ„Å¸arlar; o meÃ…Å¸hur pembe renklerini yedikleri karides ve alglerdeki pigmentlerden alÃ„Â±rlar.',
    'en':
        'Flamingos are born gray; their famous pink comes from pigments in shrimp and algae they eat.',
  },
  {
    'tr':
        'Sincaplar her yÃ„Â±l binlerce yeni aÃ„Å¸acÃ„Â±n yetiÃ…Å¸mesine neden olur ÃƒÂ§ÃƒÂ¼nkÃƒÂ¼ sakladÃ„Â±klarÃ„Â± fÃ„Â±ndÃ„Â±k ve cevizlerin yerini unuturlar.',
    'en':
        'Squirrels help grow thousands of new trees each year because they forget where they buried nuts.',
  },
  {
    'tr':
        "Uzayda oynanan ilk video oyunu Tetris'tir; 1993 yÃ„Â±lÃ„Â±nda bir kozmonot tarafÃ„Â±ndan Game Boy ile oynanmÃ„Â±Ã…Å¸tÃ„Â±r.",
    'en':
        'The first video game played in space was TetrisÃ¢â‚¬â€played on a Game Boy by a cosmonaut in 1993.',
  },
  {
    'tr':
        'AÃ„Å¸aÃƒÂ§kakanlar beyin sarsÃ„Â±ntÃ„Â±sÃ„Â± geÃƒÂ§irmemek iÃƒÂ§in dillerini beyinlerinin etrafÃ„Â±na sararlar; kask niyetine dil kullanmak oldukÃƒÂ§a yaratÃ„Â±cÃ„Â± bir ÃƒÂ§ÃƒÂ¶zÃƒÂ¼m.',
    'en':
        'Woodpeckers wrap their tongues around their brains to help avoid concussionsÃ¢â‚¬â€using your tongue as a helmet is a wild solution.',
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
    final bool isUntranslatedFallback = code != 'en' && repaired == en;
    if (repaired.isNotEmpty &&
        !_looksLikeMojibakeText(repaired) &&
        !isUntranslatedFallback) {
      return repaired;
    }
  }

  final String repairedFallback =
      _repairDisplayText(localizeTrEn(code, tr, en)).trim();
  if (repairedFallback.isNotEmpty &&
      !_looksLikeMojibakeText(repairedFallback)) {
    return repairedFallback;
  }
  return en;
}

class _ModernLoaderState extends State<ModernLoader> {
  final Random _factRand = Random();
  Timer? _factTimer;
  int _factIndex = 0;
  DateTime? _progressStartedAt;
  Duration? _lastRemainingEstimate;
  DateTime? _lastRemainingAt;

  @override
  void initState() {
    super.initState();
    _syncProgressTracking(oldProgress: null, newProgress: widget.progress);
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
    _syncProgressTracking(
      oldProgress: oldWidget.progress,
      newProgress: widget.progress,
    );
    if (oldWidget.progress == null && widget.progress != null) {
      _startFactRotationIfNeeded();
    } else if (oldWidget.progress != null && widget.progress == null) {
      _factTimer?.cancel();
      _factTimer = null;
    }
  }

  void _syncProgressTracking({
    required double? oldProgress,
    required double? newProgress,
  }) {
    if (newProgress == null) {
      _progressStartedAt = null;
      _lastRemainingEstimate = null;
      _lastRemainingAt = null;
      return;
    }
    if (_progressStartedAt == null || oldProgress == null) {
      _progressStartedAt = DateTime.now();
      _lastRemainingEstimate = null;
      _lastRemainingAt = null;
      return;
    }
    // Progress can move backward when a brand-new analysis starts.
    if (newProgress + 0.08 < oldProgress) {
      _progressStartedAt = DateTime.now();
      _lastRemainingEstimate = null;
      _lastRemainingAt = null;
    }
  }

  Duration? _estimateRemaining(double progress) {
    final DateTime? startedAt = _progressStartedAt;
    if (startedAt == null) return null;

    final DateTime now = DateTime.now();
    final double p = progress.clamp(0.0, 1.0);
    if (p <= 0.03) {
      _lastRemainingEstimate = null;
      _lastRemainingAt = null;
      return null;
    }
    if (p >= 0.995) {
      _lastRemainingEstimate = Duration.zero;
      _lastRemainingAt = now;
      return Duration.zero;
    }

    final Duration elapsed = now.difference(startedAt);
    if (elapsed.inMilliseconds < 900) return null;

    final int elapsedMs = elapsed.inMilliseconds;
    final double safeProgress = p.clamp(0.035, 0.995);
    final double phaseMultiplier = p < 0.12
        ? 2.4
        : (p < 0.28)
            ? 2.0
            : (p < 0.50)
                ? 1.7
                : (p < 0.72)
                    ? 1.45
                    : (p < 0.88)
                        ? 1.28
                        : 1.12;

    int estimatedTotalMs =
        ((elapsedMs / safeProgress) * phaseMultiplier).round();
    final int dynamicMaxTotalMs = p < 0.20
        ? 540000
        : (p < 0.50)
            ? 360000
            : (p < 0.80)
                ? 220000
                : 120000;
    final int dynamicMinTotalMs = max(2600, elapsedMs + 900);
    estimatedTotalMs =
        estimatedTotalMs.clamp(dynamicMinTotalMs, dynamicMaxTotalMs);
    int remainingMs = max(0, estimatedTotalMs - elapsedMs);

    if (p >= 0.97) {
      remainingMs = min(remainingMs, 2200);
    } else if (p >= 0.90) {
      final int lateBound = max(450, (6500 * (1.0 - p)).round() + 320);
      remainingMs = min(remainingMs, lateBound);
    }

    final Duration? previous = _lastRemainingEstimate;
    final DateTime? previousAt = _lastRemainingAt;
    if (previous != null && previousAt != null) {
      final int previousMs = previous.inMilliseconds;
      final int deltaMs = max(1, now.difference(previousAt).inMilliseconds);

      final double alpha = p < 0.22
          ? 0.16
          : (p < 0.55)
              ? 0.24
              : (p < 0.82)
                  ? 0.34
                  : 0.48;
      int smoothed =
          (previousMs + ((remainingMs - previousMs) * alpha)).round();

      // Never allow ETA to move backward (increase).
      if (smoothed > previousMs) {
        smoothed = previousMs;
      }

      // Enforce gentle countdown so ETA does not appear frozen.
      final int minDecay = max(20, (deltaMs * 0.35).round());
      final int maxAllowed = max(0, previousMs - minDecay);
      if (smoothed > maxAllowed) {
        smoothed = maxAllowed;
      }

      // Avoid unrealistically steep drops that feel jumpy.
      final int maxDecay = (deltaMs * 3) + 2600;
      final int minAllowed = max(0, previousMs - maxDecay);
      if (smoothed < minAllowed) {
        smoothed = minAllowed;
      }
      remainingMs = max(0, smoothed);
    }

    final Duration result = Duration(milliseconds: remainingMs);
    _lastRemainingEstimate = result;
    _lastRemainingAt = now;
    return result;
  }

  String _formatShortDuration(Duration duration) {
    final int totalSeconds = max(0, duration.inSeconds);
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildProgressPanel({
    required double progress,
    required Color accent,
    required Color textColor,
  }) {
    final Color panelBg = widget.isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.blueGrey.withOpacity(0.08);
    final Color panelBorder = widget.isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);
    final int percent =
        progress >= 1.0 ? 100 : min(99, (progress * 100).round());
    final Duration? remainingEstimate = _estimateRemaining(progress);
    final String? remainingText = remainingEstimate == null
        ? (progress > 0.03 && progress < 0.995
            ? _analysisRemainingPreparingForLang(widget.lang)
            : null)
        : _analysisRemainingTextForLang(
            widget.lang,
            _formatShortDuration(remainingEstimate),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: accent.withOpacity(widget.isDark ? 0.16 : 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "%$percent",
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          if (remainingText != null && remainingText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              remainingText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.72),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isDark ? Colors.white : Colors.blueGrey;
    final Color textColor =
        widget.isDark ? Colors.white : Colors.blueGrey.shade800;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.progress != null ? 14 : 26,
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
                final Color accent =
                    widget.isDark ? Colors.blueAccent : Colors.blue;
                return Column(
                  children: [
                    _buildProgressPanel(
                      progress: value,
                      accent: accent,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 10),
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
    "Catching the inÃ¢â‚¬â€˜between.",
    "If you need me, IÃ¢â‚¬â„¢m out chasing sunsets.",
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
    "Dreams donÃ¢â‚¬â„¢t work unless we do.",
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
        title: Text(localizeTrEn(
            langCode, 'Biyografi PlanlayÃ„Â±cÃ„Â±', 'Bio Planner')),
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
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  Completer<void>? _resumeCompleter;

  String currentUsername = "";
  String _ownerUsernameCache = "";
  bool _debugPinUnlocked = false;
  String? savedCookie, savedUserId, savedUserAgent;
  final http.Client _httpClient = http.Client();
  String? _sessionAppUserAgent;

  Duration? _remainingToNextAnalysis;
  Timer? _countdownTimer;
  Timer? _legalHoldTimer;
  Timer? _consentWatchTimer;
  Timer? _bannerRetryTimer;
  Timer? _headerBannerRetryTimer;
  Timer? _storyAutoTimer;

  Future<void> _applyFastSnapshotDiff({
    required SharedPreferences prefs,
    required Map<String, String> nFollowers,
    required Map<String, String> nFollowing,
  }) async {
    final String accountUserId = _currentAccountUserId();

    final Map<String, String> oldFollowers = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'followers_map', userId: accountUserId) ??
            '{}'));
    final Map<String, String> oldFollowing = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'following_map', userId: accountUserId) ??
            '{}'));
    final Map<String, String> storedUnfollowers = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'unfollowers_map', userId: accountUserId) ??
            '{}'));
    final Map<String, String> storedLeftFollowing = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'left_following_map',
                userId: accountUserId) ??
            '{}'));

    final Set<String> oldF = oldFollowers.keys.toSet();
    final Set<String> newF = nFollowers.keys.toSet();
    final Set<String> oldG = oldFollowing.keys.toSet();
    final Set<String> newG = nFollowing.keys.toSet();

    final Set<String> unfollowers = oldF.difference(newF);
    final Set<String> newFollowersSet = newF.difference(oldF);
    final Set<String> leftFollowing = oldG.difference(newG);
    final Set<String> newFollowingSet = newG.difference(oldG);

    Map<String, String> newFollowersMapLocal = {};
    int leftFollowersCount = 0;
    int newFollowersCount = 0;
    int leftFollowingCount = 0;
    int newFollowingCount = 0;

    for (final u in unfollowers) {
      final String img = oldFollowers[u] ?? '';
      if (!storedUnfollowers.containsKey(u)) {
        storedUnfollowers[u] = img;
        leftFollowersCount++;
      }
    }

    for (final u in newFollowersSet) {
      final String img = nFollowers[u] ?? '';
      newFollowersMapLocal[u] = img;
      newFollowersCount++;
    }

    for (final u in leftFollowing) {
      final String img = oldFollowing[u] ?? '';
      if (!storedLeftFollowing.containsKey(u)) {
        storedLeftFollowing[u] = img;
        leftFollowingCount++;
      }
    }

    newFollowingCount = newFollowingSet.length;

    // persist maps
    await _setAccountPrefString(prefs, 'followers_map', jsonEncode(nFollowers),
        userId: accountUserId);
    await _setAccountPrefString(prefs, 'following_map', jsonEncode(nFollowing),
        userId: accountUserId);
    await _setAccountPrefString(
        prefs, 'unfollowers_map', jsonEncode(storedUnfollowers),
        userId: accountUserId);
    await _setAccountPrefString(
        prefs, 'left_following_map', jsonEncode(storedLeftFollowing),
        userId: accountUserId);
    await _setAccountPrefString(
        prefs, 'new_followers_map', jsonEncode(newFollowersMapLocal),
        userId: accountUserId);

    // update in-memory state and badges
    if (mounted) {
      setState(() {
        followersMap = nFollowers;
        followingMap = nFollowing;
        unfollowersMap = storedUnfollowers;
        leftFollowingMap = storedLeftFollowing;
        newFollowersMap = newFollowersMapLocal;
        badges['left_followers'] =
            (badges['left_followers'] ?? 0) + leftFollowersCount;
        badges['new_followers'] =
            (badges['new_followers'] ?? 0) + newFollowersCount;
        badges['left_following'] =
            (badges['left_following'] ?? 0) + leftFollowingCount;
        badges['following'] = (badges['following'] ?? 0) + newFollowingCount;
        _syncCountsForUi();
      });
    } else {
      followersMap = nFollowers;
      followingMap = nFollowing;
      unfollowersMap = storedUnfollowers;
      leftFollowingMap = storedLeftFollowing;
      newFollowersMap = newFollowersMapLocal;
    }

    final realNow = await _getNetworkTime();
    final int currentWindowCount = _analysisWindowCount(prefs, realNow) + 1;
    await _setAccountPrefInt(
      prefs,
      _analysisWindowCountKey,
      currentWindowCount,
      userId: accountUserId,
    );
    await _setAccountPrefInt(
      prefs,
      'last_update_time',
      realNow.millisecondsSinceEpoch,
      userId: accountUserId,
    );

    unawaited(TelemetryService.instance.recordAnalysisCompleted(
      followersCount: nFollowers.length,
      followingCount: nFollowing.length,
      duration: _analysisStartedAt == null
          ? null
          : DateTime.now().difference(_analysisStartedAt!),
    ));
  }

  Timer? _progressPumpTimer;
  bool _isEntryInterstitialInFlight = false;
  bool _isEntryInterstitialPreloadInFlight = false;
  Timer? _entryInterstitialPrefetchRetryTimer;
  Timer? _entryInterstitialPrefetchTimeoutTimer;
  bool _isBannerLoadInFlight = false;
  bool _isHeaderBannerLoadInFlight = false;
  int _bannerLoadAttempt = 0;
  int _bannerConsecutiveFailures = 0;
  int _headerBannerConsecutiveFailures = 0;
  int _entryInterstitialPrefetchFailureCount = 0;
  DateTime? _bannerBackoffUntil;
  bool _isRewardedLoading = false;
  bool _justWatchedReward = false;
  DateTime? _lastEntryInterstitialShown;
  bool _fetchChunkStopRequested = false;

  static const int _entryInterstitialMinIntervalSeconds = 180;
  static const int _entryInterstitialMaxDailyLimit = 3;
  static const int _entryInterstitialFirstEligibleDetailOpen = 4;
  static const int _entryInterstitialDetailOpenInterval = 4;

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
    'ca',
    'zh-hant',
    'hr',
    'cs',
    'da',
    'fi',
    'fr-ca',
    'el',
    'he',
    'ms',
    'no',
    'pt-pt',
    'ro',
    'sk',
    'sv',
    'uk',
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
    'ca': 'Catal\u00e0',
    'zh-hant': '\u7e41\u9ad4\u4e2d\u6587',
    'hr': 'Hrvatski',
    'cs': '\u010ce\u0161tina',
    'da': 'Dansk',
    'fi': 'Suomi',
    'fr-ca': 'Fran\u00e7ais (Canada)',
    'el': '\u0395\u03bb\u03bb\u03b7\u03bd\u03b9\u03ba\u03ac',
    'he': '\u05e2\u05d1\u05e8\u05d9\u05ea',
    'ms': 'Bahasa Melayu',
    'no': 'Norsk',
    'pt-pt': 'Portugu\u00eas (Portugal)',
    'ro': 'Rom\u00e2n\u0103',
    'sk': 'Sloven\u010dina',
    'sv': 'Svenska',
    'uk': '\u0423\u043a\u0440\u0430\u0457\u043d\u0441\u044c\u043a\u0430',
  };
  static const Map<String, String> _languageFlags = <String, String>{
    'tr': '\u{1F1F9}\u{1F1F7}',
    'en': '\u{1F1EC}\u{1F1E7}',
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
    'ca': '\u{1F1EA}\u{1F1F8}',
    'zh-hant': '\u{1F1F9}\u{1F1FC}',
    'hr': '\u{1F1ED}\u{1F1F7}',
    'cs': '\u{1F1E8}\u{1F1FF}',
    'da': '\u{1F1E9}\u{1F1F0}',
    'fi': '\u{1F1EB}\u{1F1EE}',
    'fr-ca': '\u{1F1E8}\u{1F1E6}',
    'el': '\u{1F1EC}\u{1F1F7}',
    'he': '\u{1F1EE}\u{1F1F1}',
    'ms': '\u{1F1F2}\u{1F1FE}',
    'no': '\u{1F1F3}\u{1F1F4}',
    'pt-pt': '\u{1F1F5}\u{1F1F9}',
    'ro': '\u{1F1F7}\u{1F1F4}',
    'sk': '\u{1F1F8}\u{1F1F0}',
    'sv': '\u{1F1F8}\u{1F1EA}',
    'uk': '\u{1F1FA}\u{1F1E6}',
  };

  String _lang = 'tr';

  NativeAd? _bannerAd;
  BannerAd? _headerBannerAd;
  InterstitialAd? _entryInterstitialAd;
  bool _isAdLoaded = false;
  bool _isHeaderBannerLoaded = false;
  bool _adsHidden = false;
  bool _removeAllAds = false;
  bool _remoteFlagsLoaded = false;
  bool _privacyOptionsRequired = false;
  String _announcementText = "";

  bool _isBanned = false;
  bool _isAdminUser = false;
  String? _lastIgWarning;
  bool _storyRequiresSecurityVerification = false;
  bool _securityGuideVisible = false;
  bool _igWarningVisible = false;
  DateTime? _lastIgVerificationPromptAt;
  final ValueNotifier<List<String>> _firebaseDiagnosticEvents =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<List<Map<String, String>>> _recentFirebaseAnalysisRows =
      ValueNotifier<List<Map<String, String>>>(<Map<String, String>>[]);
  static const int _maxFirebaseDiagnosticEvents = 280;
  bool _criticalDiagnosticVisible = false;
  String? _lastCriticalDiagnosticFingerprint;
  DateTime? _lastCriticalDiagnosticAt;
  String _lastObservedPurchaseError = '';
  int _igRequestSequence = 0;

  static const String _bannerAdUnitIdAndroid =
      'ca-app-pub-7480771330660307/7647068689';
  static const String _bannerAdUnitIdIos =
      'ca-app-pub-7480771330660307/7647068689';
  static const String _headerBannerAdUnitIdAndroid =
      'ca-app-pub-7480771330660307/9017777173';
  static const String _headerBannerAdUnitIdIos =
      'ca-app-pub-7480771330660307/9017777173';
  static const String _analysisRewardedAdUnitIdAndroid =
      'ca-app-pub-7480771330660307/1330858844';
  static const String _analysisRewardedAdUnitIdIos =
      'ca-app-pub-7480771330660307/1330858844';
  static const String _storyRewardedAdUnitIdAndroid =
      'ca-app-pub-7480771330660307/2420482147';
  static const String _storyRewardedAdUnitIdIos =
      'ca-app-pub-7480771330660307/2420482147';
  static const String _entryInterstitialAdUnitIdAndroid =
      'ca-app-pub-7480771330660307/2420482147';
  static const String _entryInterstitialAdUnitIdIos =
      'ca-app-pub-7480771330660307/2420482147';
  static const double _nativeAdSlotHeightAndroid = 292;
  static const double _nativeAdSlotHeightIos = 304;
  static const Duration _headerBannerRetryDelay = Duration(seconds: 25);
  static const Duration _bannerAggressiveRetryInterval = Duration(seconds: 25);
  static const Duration _bannerSingleAttemptTimeout = Duration(seconds: 10);
  static const Duration _rewardedSingleAttemptTimeout = Duration(seconds: 15);
  static const Duration _rewardedAggressiveRetryInterval = Duration(seconds: 6);
  static const Duration _rewardedRetryMaxWindow = Duration(seconds: 18);
  static const Duration _rewardedShownSafetyTimeout = Duration(minutes: 2);
  static const Duration _entryInterstitialLoadTimeout = Duration(seconds: 15);
  static const Duration _entryInterstitialPrefetchRetryBase =
      Duration(seconds: 25);
  static const Duration _igRequestTimeout = Duration(seconds: 12);
  static const Duration _igRetryBaseDelay = Duration(milliseconds: 900);
  static const Duration _igSafetyCooldownDefault = Duration(minutes: 35);
  static const Duration _igSafetyCooldownMin = Duration(minutes: 10);
  static const Duration _igSafetyCooldownMax = Duration(hours: 6);
  static const Duration _igSafetyCooldown429Fallback = Duration(minutes: 60);
  static const Duration _igVerificationPromptCooldown = Duration(minutes: 3);
  static const Duration _analysisSafetyMinGap = Duration.zero;
  static const Duration _analysisCooldown = Duration(hours: 30);
  static const Duration _storyGateCooldown = Duration(hours: 24);
  static const Duration _deltaForceFullInterval = Duration(hours: 48);
  static const Duration _firestoreAuthTimeout = Duration(seconds: 12);
  static const Duration _firestoreRestTimeout = Duration(seconds: 12);
  static const int _deltaProbeMaxPages = 1;
  static const int _deltaSignatureSampleSize = 140;
  static const String _networkTimeOffsetKey = 'network_time_offset_ms';
  static const String _analysisSnapshotVersionKey =
      'analysis_snapshot_version_v2';
  static const String _analysisSnapshotVersionValue = 'v2';
  static const String _analysisWindowCountKey = 'analysis_window_count';
  static const String _storyWindowCountKey = 'story_window_count';
  static const String _storyLastViewTimeKey = 'story_last_view_time_ms';
  static const String _photoWindowCountKey = 'photo_window_count';
  static const String _photoLastViewTimeKey = 'photo_last_view_time_ms';
  static const String _analysisBaselineReadyKey = 'analysis_baseline_ready_v2';
  static const String _analysisBaselineFollowersTotalKey =
      'analysis_baseline_followers_total_v2';
  static const String _analysisBaselineFollowingTotalKey =
      'analysis_baseline_following_total_v2';
  static const String _analysisBaselineFollowersSigKey =
      'analysis_baseline_followers_sig_v2';
  static const String _analysisBaselineFollowingSigKey =
      'analysis_baseline_following_sig_v2';
  static const String _analysisLastFullScanMsKey = 'analysis_last_full_scan_ms';
  int? _networkTimeOffsetMs;

  Future<void> _igRequestChain = Future.value();
  DateTime? _igLastIgRequestAt;
  DateTime? _igSafetyCooldownUntil;
  int _igRiskSignalCount = 0;
  DateTime? _igLastRiskSignalAt;
  DateTime? _lastAnalysisRequestAt;

  final Random _storyRand = Random();
  String _rateUrlAndroid = "";
  String _rateUrlIos = "";
  late final ScrollController _storyScrollController;
  Set<String> _storyUsersWithActive = {};
  Map<String, String> _storyUserPks = {};
  Map<String, String> _storyUserPics = {};
  // Session cache for resolved HD profile photo URLs, keyed by pk (or
  // username when pk is unknown). Avoids re-hitting Instagram's
  // heavily bot-monitored lookup endpoints every time the same
  // profile photo is enlarged again.
  final Map<String, String> _hdProfilePhotoCache = {};
  // Cached placeholder profiles for not-logged-in state to avoid
  // regenerating a different list on every rebuild (prevents jumps).
  List<_StoryProfile>? _cachedPlaceholderStories;
  Map<String, int> _storyActiveOrderIndex = {};
  bool _isStoryTrayLoading = false;
  bool _storyTrayRefreshQueued = false;
  DateTime? _lastStoryTrayQuickRefreshAt;
  static const Duration _storyTrayQuickRefreshMinGap = Duration(minutes: 45);
  bool _watchStoriesEnabled = false;
  bool _isPremium = false;
  DateTime? _lastPremiumActivatedNotificationAt;
  StreamSubscription<String>? _ownerFcmTokenRefreshSub;
  bool _ownerPurchaseNotificationTokenSyncing = false;

  bool get _adsDisabled => _adsHidden || _removeAllAds || _isPremium;
  late final double _analysisSpeedMultiplier =
      0.72 + (_storyRand.nextDouble() * 0.08);

  bool _isCurrentSessionUser({
    String username = '',
    String? userId,
  }) {
    final String ownUserId =
        (_resolveSessionDsUserId(savedUserId, savedCookie) ?? '').trim();
    final String candidateUserId = (userId ?? '').trim();
    if (ownUserId.isNotEmpty &&
        candidateUserId.isNotEmpty &&
        ownUserId == candidateUserId) {
      return true;
    }

    if (_isPlaceholderUsername(currentUsername)) return false;
    final String ownUsername = _normalizeUserKey(currentUsername);
    if (ownUsername.isEmpty) return false;
    final String candidateUsername = _normalizeUserKey(username);
    if (candidateUsername.isEmpty) return false;
    return ownUsername == candidateUsername;
  }

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
      final String? dsUserIdHeader =
          _resolveSessionDsUserId(savedUserId, savedCookie);

      // Use web-only reels tray fetch with human pacing
      final http.Response response = await _igGet(
        Uri.parse("https://www.instagram.com/api/v1/feed/reels_tray/"),
        headers: _buildWebHeaders(savedCookie!, ua,
            dsUserId: dsUserIdHeader, igWwwClaim: _igWwwClaimToken),
        minGap: const Duration(milliseconds: 2200),
        jitterMaxMs: 1600,
        debugLabel: 'loadStoryTray.reelsTray',
      );

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(_safeResponseBody(response));
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
          final String pk = user['pk']?.toString().trim() ?? '';
          if (_isCurrentSessionUser(username: unameRaw, userId: pk)) continue;
          final String uname = unameRaw.toLowerCase();

          active.add(uname);
          orderIndex.putIfAbsent(uname, () => order++);
          if (pk.isNotEmpty) pks[uname] = pk;

          final String pic = _extractBestProfilePhotoUrlFromUser(user) ?? '';
          if (pic.isNotEmpty) pics[uname] = pic;
        }
        // IMPORTANT: merge instead of overwrite. `_storyUserPks` is also
        // populated for every followed/follower account during the main
        // analysis pass (used later to fetch each user's real HD profile
        // photo with a single request). The reels tray only ever contains
        // users who currently have an active story, so replacing the whole
        // map here used to wipe out the pk we already knew for everyone
        // else. That forced a much slower/riskier username->id lookup for
        // non-story users whenever their photo was enlarged, and that
        // lookup silently failing left them stuck on the tiny fallback
        // thumbnail. Merging keeps everyone's pk around while still
        // refreshing the ones we just got from the tray.
        final Map<String, String> mergedPks =
            Map<String, String>.from(_storyUserPks)..addAll(pks);
        final Map<String, String> mergedPics =
            Map<String, String>.from(_storyUserPics)..addAll(pics);
        if (mounted) {
          setState(() {
            _storyUsersWithActive = active;
            _storyUserPks = mergedPks;
            _storyUserPics = mergedPics;
            _storyActiveOrderIndex = orderIndex;
          });
        } else {
          _storyUsersWithActive = active;
          _storyUserPks = mergedPks;
          _storyUserPics = mergedPics;
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
      'tagline': 'Sosyal medya iÃƒÂ§in profesyonel ÃƒÂ§ÃƒÂ¶zÃƒÂ¼mler',
      'adsense_banner': 'REKLAM ALANI',
      'admin_active_note': 'Y\u00F6netici Modu Aktif',
      'free_app_note':
          'Size daha iyi bir deneyim sunmak iÃƒÂ§in her gÃƒÂ¼n geliÃ…Å¸iyoruz. GÃƒÂ¶rÃƒÂ¼Ã…Å¸leriniz bizim iÃƒÂ§in deÃ„Å¸erli, geri bildirimlerinizi bekliyoruz!',
      'login_prompt':
          'Analizi baÃ…Å¸latmak iÃƒÂ§in lÃƒÂ¼tfen giriÃ…Å¸ yapÃ„Â±n.',
      'welcome': 'HoÃ…Å¸ geldiniz, {username}',
      'refresh_data': 'VERÃ„Â°LERÃ„Â° GÃƒÅ“NCELLE',
      'login_with_instagram': 'INSTAGRAM Ã„Â°LE GÃ„Â°RÃ„Â°Ã…Â YAP',
      'fetching_data':
          'Veriler analiz ediliyor...\nBu iÃ…Å¸lem biraz sÃƒÂ¼rebilir.',
      'processing_data': 'Veriler iÃ…Å¸leniyor...\nNeredeyse bitti.',
      'loading_ad': 'Reklam yÃƒÂ¼kleniyor...\nLÃƒÂ¼tfen bekleyin.',
      'google_ad_warning': 'Google reklam uyarÃ„Â±sÃ„Â±: {reason}',
      'analysis_secure':
          'TÃƒÂ¼m analizler gÃƒÂ¼venli Ã…Å¸ekilde yalnÃ„Â±zca cihazÃ„Â±nÃ„Â±zda iÃ…Å¸lenir.',
      'today_total_analysis': 'BugÃƒÂ¼n yapÃ„Â±lan toplam analiz: {count}',
      'purchases_not_configured':
          'SatÃ„Â±n alma sistemi hazÃ„Â±r deÃ„Å¸il. LÃƒÂ¼tfen daha sonra tekrar deneyin.',
      'premium_not_active':
          'SatÃ„Â±n alma tamamlandÃ„Â± ancak Premium aktif gÃƒÂ¶rÃƒÂ¼nmÃƒÂ¼yor. LÃƒÂ¼tfen tekrar deneyin.',
      'premium_welcome_box':
          'Premium\'a hoÃ…Å¸ geldiniz! Reklamlar ve bekleme sÃƒÂ¼releri kaldÃ„Â±rÃ„Â±ldÃ„Â±.',
      'premium_already_active': 'Premium ÃƒÂ¼yeliÃ„Å¸iniz aktif.',
      'restore_purchases': 'SatÃ„Â±n AlÃ„Â±mlarÃ„Â± Geri YÃƒÂ¼kle',
      'restore_purchases_short': 'GERÃ„Â° YÃƒÅ“KLE',
      'restoring_purchases': 'SatÃ„Â±n alÃ„Â±mlar geri yÃƒÂ¼kleniyor...',
      'restore_purchases_success':
          'SatÃ„Â±n alÃ„Â±mlar geri yÃƒÂ¼klendi Ã¢Å“â€¦',
      'restore_purchases_none':
          'Geri yÃƒÂ¼klenecek satÃ„Â±n alÃ„Â±m bulunamadÃ„Â±.',
      'restore_purchases_failed': 'Geri yÃƒÂ¼kleme baÃ…Å¸arÃ„Â±sÃ„Â±z: {err}',
      'next_analysis': 'Sonraki analiz',
      'next_analysis_ready': 'Analiz Ã…Å¸imdi hazÃ„Â±r.',
      'analysis_available_now': 'Analiz Ã…Å¸u anda kullanÃ„Â±labilir.',
      'analysis_ready_risk':
          'Analiz Ã…Å¸imdi hazÃ„Â±r; ancak art arda analiz yapmak hesabÃ„Â±nÃ„Â±zÃ„Â± riske atabilir.',
      'please_wait': 'LÃƒÂ¼tfen bekleyin',
      'warning': 'UyarÃ„Â±',
      'remaining_time': 'Kalan sÃƒÂ¼re: {time}',
      'watch_ad': 'REKLAM Ã„Â°ZLE VE ANALÃ„Â°ZÃ„Â° BAÃ…ÂLAT',
      'start_analysis': 'ANALÃ„Â°ZÃ„Â° BAÃ…ÂLAT',
      'start_analysis_question': 'Analiz baÃ…Å¸latÃ„Â±lsÃ„Â±n mÃ„Â±?',
      'premium_required_title': 'Premium gerekli',
      'premium_required_description':
          'Bu analiz için Premium gereklidir. Reklam destek limiti doldu. Lütfen Premium\'a yükseltin.',
      'buy_premium': 'PREMIUM AL',
      'premium_main_description':
          'Tüm reklamları kaldırın, bekleme sürelerini ortadan kaldırın ve sınırsız analiz yapın.',
      'premium_benefits_title': 'Premium avantajları',
      'premium_benefit_no_ads': 'Reklamlar tamamen kaldırılır.',
      'premium_benefit_fast': 'Bekleme süreleri kapanır ve akış hızlanır.',
      'premium_benefit_unlimited':
          'Sınırsız analiz ve tüm özelliklere tam erişim.',
      'remove_ads_and_limits_subtitle':
          'Reklamları ve bekleme sürelerini kaldırın.',
      'subscription_details_title': 'Abonelik Detaylaró',
      'subscription_3day_trial_notice': '3 gün ücretsiz deneme mevcut!',
      'subscription_privacy_policy': 'Gizlilik Politikasó',
      'subscription_terms_of_use': 'Kullaným Koşullaró',
      'subscription_restore_purchases': 'Satın Alımları Geri Yükle',
      'subscription_legal_disclaimer':
          'Abonelik başlatarak, Kullaným Koşullarımızñ ve Gizlilik Politikamñzñ kabul etmiş olursunuz.',
      'subscription_start_trial': 'ÜCRETSİZ DENE',
      'subscription_subscribe': 'ABONE OL',
      'clear_data_title': 'Veri SÃ„Â±fÃ„Â±rlama',
      'clear_data_content':
          'TÃƒÂ¼m yerel veriler ve oturum bilgileri silinecektir. Emin misiniz?',
      'cancel': 'Ã„Â°PTAL',
      'delete': 'SÃ„Â°L',
      'error_title': 'HATA',
      'data_fetch_error':
          'Veri alÃ„Â±namadÃ„Â±: {err}\n\nÃƒâ€“neri: Ãƒâ€¡Ã„Â±kÃ„Â±Ã…Å¸ yapÃ„Â±p tekrar giriÃ…Å¸ yapmayÃ„Â± deneyin.',
      'followers': 'TakipÃƒÂ§iler',
      'following': 'Takip Ettiklerin',
      'new_followers': 'Yeni TakipÃƒÂ§iler',
      'non_followers': 'Geri Takip Etmeyenler',
      'left_followers': 'Takibi BÃ„Â±rakanlar',
      'left_following': 'Takibi B\u0131rakt\u0131klar\u0131m',
      'legal_warning': 'Yasal UyarÃ„Â±',
      'rate_us': 'Bizi Puanla',
      'contact_us': 'Bize Ula\u015f\u0131n',
      'remove_ads_and_limits':
          'ReklamlarÃ„Â± ve bekleme sÃƒÂ¼relerini kaldÃ„Â±r',
      'rate_test_message': 'Bu kutucuk Ã…Å¸u anda test aÃ…Å¸amasÃ„Â±ndadÃ„Â±r.',
      'story_section_title':
          'Hikayeleri gizlice izle veya profil fotoÃ„Å¸raflarÃ„Â±nÃ„Â± bÃƒÂ¼yÃƒÂ¼t',
      'story_login_required':
          'Hikayeleri gizlice izleyebilmek ve profil fotoÃ„Å¸raflarÃ„Â±nÃ„Â± bÃƒÂ¼yÃƒÂ¼tmek iÃƒÂ§in lÃƒÂ¼tfen giriÃ…Å¸ yapÃ„Â±nÃ„Â±z.',
      'story_ad_wait': 'Reklamdan sonra gÃƒÂ¶sterilecek. LÃƒÂ¼tfen bekleyin.',
      'story_action_title': 'Ne yapmak istersiniz?',
      'story_view_photo': 'Profil fotoÃ„Å¸rafÃ„Â±nÃ„Â± bÃƒÂ¼yÃƒÂ¼t',
      'story_watch_secret': 'Gizlice hikayeyi izle',
      'story_no_data': 'Hikaye verisi bulunamadÃ„Â±.',
      'story_close': 'KAPAT',
      'read_and_agree': 'OKUDUM VE KABUL EDÃ„Â°YORUM',
      'withdraw_consent': 'RÃ„Â±zayÃ„Â± Geri Al',
      'withdraw_consent_confirm_title': 'Onay',
      'withdraw_consent_confirm_body':
          'RÃ„Â±za ayarlarÃ„Â± sÃ„Â±fÃ„Â±rlanacak. Emin misiniz?',
      'withdraw_consent_confirm_yes': 'Evet',
      'withdraw_consent_confirm_no': 'VazgeÃƒÂ§',
      'no_data': 'Veri yok',
      'new_badge': 'YENÃ„Â°',
      'login_title': 'GiriÃ…Å¸ Yap',
      'user_label': 'Kullan\u0131c\u0131',
      'redirecting': 'Oturum doÃ„Å¸rulandÃ„Â±, yÃƒÂ¶nlendiriliyorsunuz...',
      'data_updated': 'Analiz tamamlandÃ„Â± Ã¢Å“â€¦',
      'enter_pin': 'PIN giriniz',
      'pin_accepted': 'PIN kabul edildi, sÃƒÂ¼re sÃ„Â±fÃ„Â±rlandÃ„Â± Ã¢Å“â€¦',
      'pin_incorrect': 'YanlÃ„Â±Ã…Å¸ PIN',
      'ok': 'TAMAM',
      'legal_intro':
          'Bu uygulamayÃ„Â± indiren ve kullanan her KullanÃ„Â±cÃ„Â±, aÃ…Å¸aÃ„Å¸Ã„Â±daki "KullanÃ„Â±m KoÃ…Å¸ullarÃ„Â± ve Feragatname" metnini okumuÃ…Å¸, anlamÃ„Â±Ã…Å¸ ve hÃƒÂ¼kÃƒÂ¼mlerini kabul etmiÃ…Å¸ sayÃ„Â±lÃ„Â±r:',
      'article1_title':
          'Madde 1: Veri GizliliÃ„Å¸i ve Yerel Ã„Â°Ã…Å¸leme Mimarisi',
      'article1_text':
          "VERDICT, istemci tarafÃ„Â±nda ÃƒÂ§alÃ„Â±Ã…Å¸an bir yazÃ„Â±lÃ„Â±mdÃ„Â±r. KullanÃ„Â±cÃ„Â±nÃ„Â±n giriÃ…Å¸ bilgileri (kullanÃ„Â±cÃ„Â± adÃ„Â±, Ã…Å¸ifre, oturum ÃƒÂ§erezleri) hiÃƒÂ§bir surette harici bir sunucuya iletilmez veya depolanmaz. TÃƒÂ¼m veri iÃ…Å¸leme faaliyetleri yalnÃ„Â±zca kullanÃ„Â±cÃ„Â±nÃ„Â±n cihazÃ„Â±nÃ„Â±n geÃƒÂ§ici belleÃ„Å¸inde ve yerel depolama alanÃ„Â±nda gerÃƒÂ§ekleÃ…Å¸ir. Uygulama, Instagram arayÃƒÂ¼zÃƒÂ¼ ÃƒÂ¼zerinde ÃƒÂ§alÃ„Â±Ã…Å¸an bir tarayÃ„Â±cÃ„Â± katmanÃ„Â± olarak iÃ…Å¸lev gÃƒÂ¶rÃƒÂ¼r.",
      'article2_title': 'Madde 2: ÃƒÅ“ÃƒÂ§ÃƒÂ¼ncÃƒÂ¼ Taraf Platform Riskleri',
      'article2_text':
          "Instagram (Meta Platforms, Inc.), platform politikalarÃ„Â± gereÃ„Å¸i ÃƒÂ¼ÃƒÂ§ÃƒÂ¼ncÃƒÂ¼ taraf yazÃ„Â±lÃ„Â±mlarÃ„Â±n kullanÃ„Â±mÃ„Â±nÃ„Â± kÃ„Â±sÃ„Â±tlama hakkÃ„Â±nÃ„Â± saklÃ„Â± tutar. UygulamanÃ„Â±n kullanÃ„Â±mÃ„Â±na baÃ„Å¸lÃ„Â± olarak geliÃ…Å¸ebilecek iÃ…Å¸lem engeli, hesap kÃ„Â±sÃ„Â±tlamasÃ„Â±, gÃƒÂ¶lge yasaklama veya hesap kapatÃ„Â±lmasÃ„Â± dahil ancak bunlarla sÃ„Â±nÃ„Â±rlÃ„Â± olmamak ÃƒÂ¼zere tÃƒÂ¼m riskler mÃƒÂ¼nhasÃ„Â±ran KullanÃ„Â±cÃ„Â±ya aittir. VERDICT geliÃ…Å¸tiricisi, bu tÃƒÂ¼r idari yaptÃ„Â±rÃ„Â±mlardan dolayÃ„Â± doÃ„Å¸abilecek doÃ„Å¸rudan veya dolaylÃ„Â± zararlardan sorumlu tutulamaz.",
      'article3_title': 'Madde 3: Garanti Feragatnamesi ve Sorumluluk Reddi',
      'article3_text':
          "Ã„Â°Ã…Å¸bu yazÃ„Â±lÃ„Â±m, olduÃ„Å¸u gibi ve mevcut haliyle sunulmaktadÃ„Â±r. YazÃ„Â±lÃ„Â±mÃ„Â±n saÃ„Å¸ladÃ„Â±Ã„Å¸Ã„Â± analiz sonuÃƒÂ§larÃ„Â±nÃ„Â±n %100 kesinliÃ„Å¸i, sÃƒÂ¼rekliliÃ„Å¸i veya ticari elveriÃ…Å¸liliÃ„Å¸i garanti edilmez. KullanÃ„Â±cÃ„Â±, uygulama verilerine dayanarak gerÃƒÂ§ekleÃ…Å¸tireceÃ„Å¸i hukuki veya ticari iÃ…Å¸lemlerden doÃ„Å¸abilecek sonuÃƒÂ§larÃ„Â±n kendi sorumluluÃ„Å¸unda olduÃ„Å¸unu; geliÃ…Å¸tiriciyi her tÃƒÂ¼rlÃƒÂ¼ talep, dava ve Ã…Å¸ikayetten ari tutacaÃ„Å¸Ã„Â±nÃ„Â± beyan ve taahhÃƒÂ¼t eder.",
      'article4_title':
          'Madde 4: Fikri MÃƒÂ¼lkiyet ve BaÃ„Å¸Ã„Â±msÃ„Â±zlÃ„Â±k Bildirimi',
      'article4_text':
          "VERDICT, baÃ„Å¸Ã„Â±msÃ„Â±z bir geliÃ…Å¸tirici projesidir. 'Instagram', 'Facebook' ve 'Meta' markalarÃ„Â± Meta Platforms, Inc.'in tescilli ticari markalarÃ„Â±dÃ„Â±r. Bu uygulamanÃ„Â±n sÃƒÂ¶z konusu Ã…Å¸irketlerle herhangi bir ticari ortaklÃ„Â±Ã„Å¸Ã„Â±, sponsorluk anlaÃ…Å¸masÃ„Â± veya resmi baÃ„Å¸lantÃ„Â±sÃ„Â± bulunmamaktadÃ„Â±r.",
      'article5_title':
          'Madde 5: Hizmet SÃƒÂ¼rekliliÃ„Å¸i ve Platform DeÃ„Å¸iÃ…Å¸iklikleri',
      'article5_text':
          "Instagram APIÃ¢â‚¬â„¢sinde veya web altyapÃ„Â±sÃ„Â±nda meydana gelebilecek kÃƒÂ¶klÃƒÂ¼ deÃ„Å¸iÃ…Å¸iklikler, uygulamanÃ„Â±n iÃ…Å¸levselliÃ„Å¸ini kÃ„Â±smen veya tamamen yitirmesine neden olabilir. GeliÃ…Å¸tirici, mÃƒÂ¼cbir sebep kapsamÃ„Â±nda deÃ„Å¸erlendirilen bu tÃƒÂ¼r altyapÃ„Â±sal deÃ„Å¸iÃ…Å¸ikliklere baÃ„Å¸lÃ„Â± olarak uygulamayÃ„Â± gÃƒÂ¼ncelleme veya hizmeti sÃƒÂ¼rdÃƒÂ¼rme konusunda herhangi bir taahhÃƒÂ¼tte bulunmamaktadÃ„Â±r.",
      'ad_wait_message':
          'Analiz tamamlandÃ„Â±, sonuÃƒÂ§lar reklamdan sonra gÃƒÂ¶sterilecek.',
      'analysis_failed_title': 'Analiz yapÃ„Â±lamadÃ„Â±',
      'analysis_failed_reason': 'Neden: {reason}',
      'analysis_failed_hint':
          'Ã„Â°pucu: Ãƒâ€¡Ã„Â±kÃ„Â±Ã…Å¸ yapÃ„Â±p yeniden giriÃ…Å¸ yapmak iÃ…Å¸e yarayabilir.',
      'analysis_fast_no_change':
          'HÃ„Â±zlÃ„Â± kontrol: DeÃ„Å¸iÃ…Å¸iklik bulunamadÃ„Â±.',
      'usage_metrics_title': 'GÃƒÂ¼nlÃƒÂ¼k Veriler',
      'usage_metrics_active': 'Aktif kullanÃ„Â±cÃ„Â±',
      'usage_metrics_queries': 'GÃƒÂ¼nlÃƒÂ¼k sorgu sayÃ„Â±sÃ„Â±',
      'usage_metrics_na': '--',
      'usage_metrics_live': 'canlÃ„Â±'
    },
    'en': {
      'tagline': 'Professional Social Media Solutions',
      'adsense_banner': 'AD SPACE',
      'admin_active_note': 'Admin mode active',
      'free_app_note':
          'We are evolving every day to provide you with a better experience. Your feedback is valuable to usÃ¢â‚¬â€weÃ¢â‚¬â„¢d love to hear from you!',
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
      'premium_required_title': 'Premium required',
      'premium_required_description':
          'This analysis requires Premium. The ad support limit has ended. Please upgrade to Premium.',
      'buy_premium': 'BUY PREMIUM',
      'premium_main_description':
          'Remove all ads, eliminate wait times, and perform unlimited analysis.',
      'premium_benefits_title': 'Premium benefits',
      'premium_benefit_no_ads': 'Ads completely removed.',
      'premium_benefit_fast': 'Wait times eliminated and speed increased.',
      'premium_benefit_unlimited':
          'Unlimited analysis with full access to all features.',
      'remove_ads_and_limits_subtitle': 'Remove Ads & Wait Times',
      'subscription_details_title': 'Subscription Details',
      'subscription_3day_trial_notice': '3-day free trial available!',
      'subscription_privacy_policy': 'Privacy Policy',
      'subscription_terms_of_use': 'Terms of Use',
      'subscription_restore_purchases': 'Restore Purchases',
      'subscription_legal_disclaimer':
          'By subscribing, you agree to our Terms of Use and Privacy Policy.',
      'subscription_start_trial': 'START FREE TRIAL',
      'subscription_subscribe': 'SUBSCRIBE',
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
      'remove_ads_and_limits': 'Remove Ads & Wait Times',
      'rate_test_message': 'This box is currently under test.',
      'story_section_title': 'Watch Stories Secretly or Zoom Profile Photos',
      'story_login_required':
          'Please log in to watch stories secretly and enlarge profile photos.',
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
      'data_updated': 'Analysis complete Ã¢Å“â€¦',
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
      'restore_purchases_success': 'Purchases restored Ã¢Å“â€¦',
      'restore_purchases_none': 'No purchases to restore.',
      'restore_purchases_failed': 'Restore failed: {err}',
      'enter_pin': 'Enter PIN',
      'pin_accepted': 'PIN accepted, timer reset Ã¢Å“â€¦',
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
      'tagline': 'Professionelle Social-Media-LÃƒÂ¶sungen',
      'admin_active_note': 'Admin-Modus aktiv',
      'free_app_note':
          'Wir entwickeln uns tÃƒÂ¤glich weiter, um dir ein besseres Erlebnis zu bieten. Dein Feedback ist uns wichtig.',
      'login_prompt': 'Bitte melde dich an, um die Analyse zu starten.',
      'welcome': 'Willkommen, {username}',
      'refresh_data': 'DATEN AKTUALISIEREN',
      'login_with_instagram': 'MIT INSTAGRAM ANMELDEN',
      'fetching_data': 'Daten werden analysiert...\nDas kann kurz dauern.',
      'processing_data': 'Daten werden verarbeitet...\nFast fertig.',
      'loading_ad': 'Anzeige wird geladen...\nBitte warten.',
      'google_ad_warning': 'Google-Warnung zur Werbung: {reason}',
      'analysis_secure':
          'Alle Analysen werden sicher lokal auf deinem GerÃƒÂ¤t verarbeitet.',
      'today_total_analysis': 'Analysen heute insgesamt: {count}',
      'purchases_not_configured':
          'KÃƒÂ¤ufe sind derzeit nicht verfÃƒÂ¼gbar. Bitte spÃƒÂ¤ter erneut versuchen.',
      'premium_already_active': 'Deine Premium-Mitgliedschaft ist aktiv.',
      'premium_welcome_box':
          'Willkommen bei Premium! Werbung und Wartezeiten wurden entfernt.',
      'restore_purchases': 'KÃƒÂ¤ufe wiederherstellen',
      'restore_purchases_short': 'WIEDERHERSTELLEN',
      'restoring_purchases': 'KÃƒÂ¤ufe werden wiederhergestellt...',
      'restore_purchases_success': 'KÃƒÂ¤ufe wiederhergestellt Ã¢Å“â€¦',
      'restore_purchases_none': 'Keine KÃƒÂ¤ufe zum Wiederherstellen gefunden.',
      'restore_purchases_failed': 'Wiederherstellung fehlgeschlagen: {err}',
      'premium_main_description':
          'Entfernen Sie alle Anzeigen, eliminieren Sie Wartezeiten und fÃƒÂ¼hren Sie unbegrenzte Analysen durch.',
      'premium_benefits_title': 'Premium-Vorteile',
      'premium_benefit_no_ads': 'Werbung komplett entfernt.',
      'premium_benefit_fast':
          'Wartezeiten eliminiert und Geschwindigkeit erhÃƒÂ¶ht.',
      'premium_benefit_unlimited':
          'Unbegrenzte Analyse mit vollem Zugriff auf alle Funktionen.',
      'remove_ads_and_limits_subtitle': 'Werbung und Wartezeiten entfernen.',
      'next_analysis': 'NÃƒÂ¤chste Analyse',
      'next_analysis_ready': 'Analyse ist jetzt verfÃƒÂ¼gbar.',
      'analysis_ready_risk':
          'Eine Analyse ist jetzt mÃƒÂ¶glich, aber Analysen direkt hintereinander kÃƒÂ¶nnen dein Konto gefÃƒÂ¤hrden.',
      'please_wait': 'Bitte warten',
      'remaining_time': 'Verbleibende Zeit: {time}',
      'watch_ad': 'WERBUNG ANSEHEN UND ANALYSE STARTEN',
      'start_analysis': 'ANALYSE STARTEN',
      'start_analysis_question': 'Analyse starten?',
      'clear_data_title': 'App-Daten zurÃƒÂ¼cksetzen',
      'clear_data_content':
          'Alle lokalen Daten und Sitzungsinformationen werden gelÃƒÂ¶scht. Bist du sicher?',
      'cancel': 'ABBRECHEN',
      'delete': 'LÃƒâ€“SCHEN',
      'ad_wait_message':
          'Analyse abgeschlossen, Ergebnisse werden nach der Werbung angezeigt.',
      'analysis_failed_title': 'Analyse fehlgeschlagen',
      'analysis_failed_reason': 'Grund: {reason}',
      'analysis_failed_hint': 'Tipp: Abmelden und erneut anmelden kann helfen.',
      'story_section_title':
          'Stories heimlich ansehen oder Profilfotos vergrÃƒÂ¶ÃƒÅ¸ern',
      'story_login_required':
          'Bitte melde dich an, um Stories anonym anzusehen und Profilfotos zu vergrÃƒÂ¶ÃƒÅ¸ern.',
      'story_ad_wait': 'Wird nach der Werbung angezeigt, bitte warten.',
      'story_action_title': 'Was mÃƒÂ¶chtest du tun?',
      'story_view_photo': 'Profilfoto vergrÃƒÂ¶ÃƒÅ¸ern',
      'story_watch_secret': 'Story heimlich ansehen',
      'story_no_data': 'Keine Story-Daten gefunden.',
      'story_close': 'SCHLIESSEN',
      'no_data': 'Keine Daten',
      'new_badge': 'NEU',
      'login_title': 'Anmelden',
      'read_and_agree': 'ICH HABE GELESEN UND STIMME ZU',
      'withdraw_consent': 'Einwilligung zurÃƒÂ¼ckziehen',
      'withdraw_consent_confirm_title': 'BestÃƒÂ¤tigen',
      'withdraw_consent_confirm_body':
          'Deine Einwilligungseinstellungen werden zurÃƒÂ¼ckgesetzt. Bist du sicher?',
      'withdraw_consent_confirm_yes': 'Ja',
      'withdraw_consent_confirm_no': 'Abbrechen',
      'data_updated': 'Analyse abgeschlossen Ã¢Å“â€¦',
      'enter_pin': 'PIN eingeben',
      'pin_accepted': 'PIN akzeptiert, Zeit zurÃƒÂ¼ckgesetzt Ã¢Å“â€¦',
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
      'tagline':
          'Ã¬Â â€Ã«Â¬Â¸ Ã¬â€ Å’Ã¬â€¦Å“ Ã«Â¯Â¸Ã«â€â€Ã¬â€“Â´ Ã¬â€ â€Ã«Â£Â¨Ã¬â€¦Ëœ',
      'admin_active_note':
          'ÃªÂ´â‚¬Ã«Â¦Â¬Ã¬ÂÂ Ã«ÂªÂ¨Ã«â€œÅ“ Ã­â„¢Å“Ã¬â€Â±Ã­â„¢â€',
      'free_app_note':
          'Ã«Ââ€ Ã«â€šËœÃ¬Ââ‚¬ ÃªÂ²Â½Ã­â€”ËœÃ¬Ââ€ Ã¬Å“â€Ã­â€¢Â´ Ã«Â§Â¤Ã¬ÂÂ¼ ÃªÂ°Å“Ã¬â€Â Ã­â€¢ËœÃªÂ³Â  Ã¬ÂË†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤. Ã¬â€”Â¬Ã«Å¸Â¬Ã«Â¶â€Ã¬ÂËœ Ã­â€Â¼Ã«â€œÅ“Ã«Â°Â±Ã¬Ââ‚¬ Ã«Â§Â¤Ã¬Å¡Â° Ã¬â€ Å’Ã¬Â¤â€˜Ã­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤.',
      'login_prompt':
          'Ã«Â¶â€Ã¬â€ÂÃ¬Ââ€ Ã¬â€¹Å“Ã¬Ââ€˜Ã­â€¢ËœÃ«Â Â¤Ã«Â©Â´ Ã«Â¡Å“ÃªÂ·Â¸Ã¬ÂÂ¸Ã­â€¢Â´ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'welcome': 'Ã­â„¢ËœÃ¬ËœÂÃ­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤, {username}',
      'refresh_data': 'Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã¬Æ’Ë†Ã«Â¡Å“ÃªÂ³Â Ã¬Â¹Â¨',
      'login_with_instagram':
          'Ã¬ÂÂ¸Ã¬Å Â¤Ã­Æ’â‚¬ÃªÂ·Â¸Ã«ÂÂ¨Ã¬Å“Â¼Ã«Â¡Å“ Ã«Â¡Å“ÃªÂ·Â¸Ã¬ÂÂ¸',
      'fetching_data':
          'Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°Ã«Â¥Â¼ Ã«Â¶â€Ã¬â€ÂÃ­â€¢ËœÃ«Å â€ Ã¬Â¤â€˜...\nÃ¬ÂÂ Ã¬â€¹Å“Ã«Â§Å’ ÃªÂ¸Â°Ã«â€¹Â¤Ã«Â Â¤ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'processing_data':
          'Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã¬Â²ËœÃ«Â¦Â¬ Ã¬Â¤â€˜...\nÃªÂ±Â°Ã¬ÂËœ Ã¬â„¢â€Ã«Â£Å’Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'loading_ad':
          'ÃªÂ´â€˜ÃªÂ³Â  Ã«Â¡Å“Ã«â€Â© Ã¬Â¤â€˜...\nÃ¬ÂÂ Ã¬â€¹Å“Ã«Â§Å’ ÃªÂ¸Â°Ã«â€¹Â¤Ã«Â Â¤ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'google_ad_warning': 'Google ÃªÂ´â€˜ÃªÂ³Â  ÃªÂ²Â½ÃªÂ³Â : {reason}',
      'analysis_secure':
          'Ã«ÂªÂ¨Ã«â€œÂ  Ã«Â¶â€Ã¬â€ÂÃ¬Ââ‚¬ ÃªÂ¸Â°ÃªÂ¸Â°Ã¬â€”ÂÃ¬â€Å“ Ã¬â€¢Ë†Ã¬Â â€Ã­â€¢ËœÃªÂ²Å’ Ã«Â¡Å“Ã¬Â»Â¬ Ã¬Â²ËœÃ«Â¦Â¬Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤.',
      'today_total_analysis':
          'Ã¬ËœÂ¤Ã«Å Ëœ Ã¬Â´Â Ã«Â¶â€Ã¬â€Â Ã¬Ë†Ëœ: {count}',
      'purchases_not_configured':
          'Ã­Ëœâ€Ã¬ÂÂ¬ ÃªÂµÂ¬Ã«Â§Â¤ ÃªÂ¸Â°Ã«Å Â¥Ã¬Ââ€ Ã¬â€šÂ¬Ã¬Å¡Â©Ã­â€¢Â  Ã¬Ë†Ëœ Ã¬â€”â€ Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤. Ã«â€šËœÃ¬Â¤â€˜Ã¬â€”Â Ã«â€¹Â¤Ã¬â€¹Å“ Ã¬â€¹Å“Ã«Ââ€Ã­â€¢Â´ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'premium_already_active':
          'Ã­â€â€Ã«Â¦Â¬Ã«Â¯Â¸Ã¬â€”â€ Ã«Â©Â¤Ã«Â²â€Ã¬â€¹Â­Ã¬ÂÂ´ Ã­â„¢Å“Ã¬â€Â±Ã­â„¢â€Ã«ÂËœÃ¬â€“Â´ Ã¬ÂË†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'premium_welcome_box':
          'Ã­â€â€Ã«Â¦Â¬Ã«Â¯Â¸Ã¬â€”â€Ã¬â€”Â Ã¬ËœÂ¤Ã¬â€¹Â  ÃªÂ²Æ’Ã¬Ââ€ Ã­â„¢ËœÃ¬ËœÂÃ­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤! ÃªÂ´â€˜ÃªÂ³Â Ã¬â„¢â‚¬ Ã«Å’â‚¬ÃªÂ¸Â° Ã¬â€¹Å“ÃªÂ°â€Ã¬ÂÂ´ Ã¬Â Å“ÃªÂ±Â°Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'premium_main_description': '모든 광고를 제거하고 대기 시간을 없애며 무제한 분석을 수행하세요.',
      'premium_benefits_title': '프리미엄 혜택',
      'premium_benefit_no_ads': '광고가 완전히 제거되었습니다.',
      'premium_benefit_fast': '대기 시간이 제거되고 속도가 향상되었습니다.',
      'premium_benefit_unlimited': '모든 기능에 대한 전체 액세스 권한과 무제한 분석.',
      'remove_ads_and_limits_subtitle': '광고 및 대기 시간 제거.',
      'restore_purchases': 'ÃªÂµÂ¬Ã«Â§Â¤ Ã«Â³ÂµÃ¬â€ºÂ',
      'restore_purchases_short': '\uBCF5\uC6D0',
      'restoring_purchases': 'ÃªÂµÂ¬Ã«Â§Â¤ Ã«Â³ÂµÃ¬â€ºÂ Ã¬Â¤â€˜...',
      'restore_purchases_success':
          'ÃªÂµÂ¬Ã«Â§Â¤ÃªÂ°â‚¬ Ã«Â³ÂµÃ¬â€ºÂÃ«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤ Ã¢Å“â€¦',
      'restore_purchases_none':
          'Ã«Â³ÂµÃ¬â€ºÂÃ­â€¢Â  ÃªÂµÂ¬Ã«Â§Â¤ Ã«â€šÂ´Ã¬â€”Â­Ã¬ÂÂ´ Ã¬â€”â€ Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'restore_purchases_failed': 'Ã«Â³ÂµÃ¬â€ºÂ Ã¬â€¹Â¤Ã­Å’Â¨: {err}',
      'next_analysis': 'Ã«â€¹Â¤Ã¬ÂÅ’ Ã«Â¶â€Ã¬â€Â',
      'next_analysis_ready':
          'Ã¬Â§â‚¬ÃªÂ¸Ë† Ã«Â¶â€Ã¬â€ÂÃ­â€¢Â  Ã¬Ë†Ëœ Ã¬ÂË†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'analysis_ready_risk':
          'Ã¬Â§â‚¬ÃªÂ¸Ë† Ã«Â¶â€Ã¬â€ÂÃ¬ÂÂ´ ÃªÂ°â‚¬Ã«Å Â¥Ã­â€¢ËœÃ¬Â§â‚¬Ã«Â§Å’, Ã¬â€”Â°Ã¬â€ Â Ã«Â¶â€Ã¬â€ÂÃ¬Ââ‚¬ ÃªÂ³â€Ã¬Â â€¢Ã¬â€”Â Ã¬Å“â€Ã­â€”ËœÃ­â€¢Â  Ã¬Ë†Ëœ Ã¬ÂË†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'please_wait':
          'Ã¬ÂÂ Ã¬â€¹Å“Ã«Â§Å’ ÃªÂ¸Â°Ã«â€¹Â¤Ã«Â Â¤ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€',
      'remaining_time': 'Ã«â€šÂ¨Ã¬Ââ‚¬ Ã¬â€¹Å“ÃªÂ°â€: {time}',
      'watch_ad':
          'ÃªÂ´â€˜ÃªÂ³Â  Ã¬â€¹Å“Ã¬Â²Â­ Ã­â€ºâ€ Ã«Â¶â€Ã¬â€Â Ã¬â€¹Å“Ã¬Ââ€˜',
      'start_analysis': 'Ã«Â¶â€Ã¬â€Â Ã¬â€¹Å“Ã¬Ââ€˜',
      'start_analysis_question':
          'Ã«Â¶â€Ã¬â€ÂÃ¬Ââ€ Ã¬â€¹Å“Ã¬Ââ€˜Ã­â€¢Â ÃªÂ¹Å’Ã¬Å¡â€?',
      'clear_data_title': 'Ã¬â€¢Â± Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã¬Â´Ë†ÃªÂ¸Â°Ã­â„¢â€',
      'clear_data_content':
          'Ã«ÂªÂ¨Ã«â€œÂ  Ã«Â¡Å“Ã¬Â»Â¬ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°Ã¬â„¢â‚¬ Ã¬â€Â¸Ã¬â€¦Ëœ Ã¬Â â€¢Ã«Â³Â´ÃªÂ°â‚¬ Ã¬â€šÂ­Ã¬Â Å“Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤. ÃªÂ³â€Ã¬â€ ÂÃ­â€¢Â ÃªÂ¹Å’Ã¬Å¡â€?',
      'cancel': 'Ã¬Â·Â¨Ã¬â€ Å’',
      'delete': 'Ã¬â€šÂ­Ã¬Â Å“',
      'ad_wait_message':
          'Ã«Â¶â€Ã¬â€ÂÃ¬ÂÂ´ Ã¬â„¢â€Ã«Â£Å’Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤. ÃªÂ´â€˜ÃªÂ³Â  Ã­â€ºâ€ ÃªÂ²Â°ÃªÂ³Â¼ÃªÂ°â‚¬ Ã­â€˜Å“Ã¬â€¹Å“Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤.',
      'analysis_failed_title': 'Ã«Â¶â€Ã¬â€Â Ã¬â€¹Â¤Ã­Å’Â¨',
      'analysis_failed_reason': 'Ã¬â€ºÂÃ¬ÂÂ¸: {reason}',
      'analysis_failed_hint':
          'Ã«Ââ€Ã¬â€ºâ‚¬Ã«Â§Â: Ã«Â¡Å“ÃªÂ·Â¸Ã¬â€¢â€Ã¬â€ºÆ’ Ã­â€ºâ€ Ã«â€¹Â¤Ã¬â€¹Å“ Ã«Â¡Å“ÃªÂ·Â¸Ã¬ÂÂ¸Ã­â€¢Â´ Ã«Â³Â´Ã¬â€Â¸Ã¬Å¡â€.',
      'story_section_title':
          'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬Ã«Â¥Â¼ Ã«ÂªÂ°Ã«ÂËœ Ã«Â³Â´ÃªÂ±Â°Ã«â€šËœ Ã­â€â€Ã«Â¡Å“Ã­â€¢â€ Ã¬â€šÂ¬Ã¬Â§â€ Ã­â„¢â€¢Ã«Å’â‚¬Ã­â€¢ËœÃªÂ¸Â°',
      'story_login_required':
          'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬Ã«Â¥Â¼ Ã¬ÂÂµÃ«Âªâ€¦Ã¬Å“Â¼Ã«Â¡Å“ Ã«Â³Â´ÃªÂ³Â  Ã­â€â€Ã«Â¡Å“Ã­â€¢â€ Ã¬â€šÂ¬Ã¬Â§â€Ã¬Ââ€ Ã­â„¢â€¢Ã«Å’â‚¬Ã­â€¢ËœÃ«Â Â¤Ã«Â©Â´ Ã«Â¡Å“ÃªÂ·Â¸Ã¬ÂÂ¸Ã­â€¢Â´ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'story_ad_wait':
          'ÃªÂ´â€˜ÃªÂ³Â  Ã­â€ºâ€ Ã­â€˜Å“Ã¬â€¹Å“Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤. Ã¬ÂÂ Ã¬â€¹Å“Ã«Â§Å’ ÃªÂ¸Â°Ã«â€¹Â¤Ã«Â Â¤ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'story_action_title':
          'Ã«Â¬Â´Ã¬â€”â€¡Ã¬Ââ€ Ã­â€¢ËœÃ¬â€¹Å“ÃªÂ²Â Ã¬â€“Â´Ã¬Å¡â€?',
      'story_view_photo':
          'Ã­â€â€Ã«Â¡Å“Ã­â€¢â€ Ã¬â€šÂ¬Ã¬Â§â€ Ã­â„¢â€¢Ã«Å’â‚¬',
      'story_watch_secret': 'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬ Ã«ÂªÂ°Ã«ÂËœ Ã«Â³Â´ÃªÂ¸Â°',
      'story_no_data':
          'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°ÃªÂ°â‚¬ Ã¬â€”â€ Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'story_close': 'Ã«â€¹Â«ÃªÂ¸Â°',
      'no_data': '\uB370\uC774\uD130 \uC5C6\uC74C',
      'new_badge': '\uC2E0\uADDC',
      'login_title': '\uB85C\uADF8\uC778',
      'read_and_agree':
          'Ã¬ÂÂ½Ã¬â€”Ë†Ã¬Å“Â¼Ã«Â©Â° Ã«Ââ„¢Ã¬ÂËœÃ­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤',
      'withdraw_consent': 'Ã«Ââ„¢Ã¬ÂËœ Ã¬Â²Â Ã­Å¡Å’',
      'withdraw_consent_confirm_title': 'Ã­â„¢â€¢Ã¬ÂÂ¸',
      'withdraw_consent_confirm_body':
          'Ã«Ââ„¢Ã¬ÂËœ Ã¬â€Â¤Ã¬Â â€¢Ã¬ÂÂ´ Ã¬Â´Ë†ÃªÂ¸Â°Ã­â„¢â€Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤. ÃªÂ³â€Ã¬â€ ÂÃ­â€¢ËœÃ¬â€¹Å“ÃªÂ²Â Ã¬Å ÂµÃ«â€¹Ë†ÃªÂ¹Å’?',
      'withdraw_consent_confirm_yes': 'Ã¬ËœË†',
      'withdraw_consent_confirm_no': 'Ã¬Â·Â¨Ã¬â€ Å’',
      'data_updated': 'Ã«Â¶â€Ã¬â€Â Ã¬â„¢â€Ã«Â£Å’ Ã¢Å“â€¦',
      'enter_pin': 'PIN Ã¬Ââ€¦Ã«Â Â¥',
      'pin_accepted':
          'PINÃ¬ÂÂ´ Ã¬Å Â¹Ã¬ÂÂ¸Ã«ÂËœÃ¬â€“Â´ Ã¬â€¹Å“ÃªÂ°â€Ã¬ÂÂ´ Ã¬Â´Ë†ÃªÂ¸Â°Ã­â„¢â€Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤ Ã¢Å“â€¦',
      'pin_incorrect':
          'PINÃ¬ÂÂ´ Ã¬ËœÂ¬Ã«Â°â€Ã«Â¥Â´Ã¬Â§â‚¬ Ã¬â€¢Å Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤',
      'ok': 'Ã­â„¢â€¢Ã¬ÂÂ¸',
      'legal_warning': 'Ã«Â²â€¢Ã¬Â Â ÃªÂ³Â Ã¬Â§â‚¬',
      'rate_us': '\uBCC4\uC810 \uC8FC\uAE30',
      'contact_us': '\uBB38\uC758\uD558\uAE30',
      'remove_ads_and_limits':
          '\uAD11\uACE0 \uBC0F \uB300\uAE30 \uC2DC\uAC04 \uC81C\uAC70',
      'legal_intro':
          'Ã¬ÂÂ´ Ã¬â€¢Â±Ã¬Ââ€ Ã«â€¹Â¤Ã¬Å¡Â´Ã«Â¡Å“Ã«â€œÅ“Ã­â€¢ËœÃªÂ³Â  Ã¬â€šÂ¬Ã¬Å¡Â©Ã­â€¢ËœÃ«Å â€ Ã«ÂªÂ¨Ã«â€œÂ  Ã¬â€šÂ¬Ã¬Å¡Â©Ã¬ÂÂÃ«Å â€ Ã¬â€¢â€Ã«ÂËœ ÃªÂ³Â Ã¬Â§â‚¬ Ã«â€šÂ´Ã¬Å¡Â©Ã¬Ââ€ Ã¬ÂÂ½ÃªÂ³Â  Ã«Ââ„¢Ã¬ÂËœÃ­â€¢Å“ ÃªÂ²Æ’Ã¬Å“Â¼Ã«Â¡Å“ ÃªÂ°â€Ã¬Â£Â¼Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤.',
      'user_label': '\uC0AC\uC6A9\uC790',
    },
    'ja': {
      'tagline':
          'Ã£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ§Ã£Æ’Æ’Ã£â€šÂ·Ã£Æ’Â§Ã£Æ’Å Ã£Æ’Â«SNSÃ£â€šÂ½Ã£Æ’ÂªÃ£Æ’Â¥Ã£Æ’Â¼Ã£â€šÂ·Ã£Æ’Â§Ã£Æ’Â³',
      'admin_active_note':
          'Ã§Â®Â¡Ã§Ââ€ Ã¨â‚¬â€¦Ã£Æ’Â¢Ã£Æ’Â¼Ã£Æ’â€°Ã¦Å“â€°Ã¥Å Â¹',
      'free_app_note':
          'Ã£â€šË†Ã£â€šÅ Ã¨â€°Â¯Ã£Ââ€Ã¤Â½â€œÃ©Â¨â€œÃ£ÂÂ®Ã£ÂÅ¸Ã£â€šÂÃ£â‚¬ÂÃ¦Â¯ÂÃ¦â€”Â¥Ã¦â€Â¹Ã¥â€“â€Ã£â€šâ€™Ã§Â¶Å¡Ã£Ââ€˜Ã£ÂÂ¦Ã£Ââ€Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€šÃ£Ââ€Ã¦â€ÂÃ¨Â¦â€¹Ã£â€šâ€™Ã£ÂÅ Ã¥Â¾â€¦Ã£ÂÂ¡Ã£Ââ€”Ã£ÂÂ¦Ã£Ââ€Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'login_prompt':
          'Ã¥Ë†â€ Ã¦ÂÂÃ£â€šâ€™Ã©â€“â€¹Ã¥Â§â€¹Ã£Ââ„¢Ã£â€šâ€¹Ã£ÂÂ«Ã£ÂÂ¯Ã£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¤Ã£Æ’Â³Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'welcome': 'Ã£â€šË†Ã£Ââ€ Ã£Ââ€œÃ£ÂÂÃ£â‚¬Â{username}',
      'refresh_data': 'Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¦â€ºÂ´Ã¦â€“Â°',
      'login_with_instagram': 'InstagramÃ£ÂÂ§Ã£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¤Ã£Æ’Â³',
      'fetching_data':
          'Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¥Ë†â€ Ã¦ÂÂÃ¤Â¸Â­...\nÃ£Ââ€”Ã£ÂÂ°Ã£â€šâ€°Ã£ÂÂÃ£ÂÅ Ã¥Â¾â€¦Ã£ÂÂ¡Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'processing_data':
          'Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¥â€¡Â¦Ã§Ââ€ Ã¤Â¸Â­...\nÃ£ÂÂ¾Ã£â€šâ€šÃ£ÂÂªÃ£ÂÂÃ¥Â®Å’Ã¤Âºâ€ Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'loading_ad':
          'Ã¥ÂºÆ’Ã¥â€˜Å Ã£â€šâ€™Ã¨ÂªÂ­Ã£ÂÂ¿Ã¨Â¾Â¼Ã£ÂÂ¿Ã¤Â¸Â­...\nÃ£Ââ€”Ã£ÂÂ°Ã£â€šâ€°Ã£ÂÂÃ£ÂÅ Ã¥Â¾â€¦Ã£ÂÂ¡Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'google_ad_warning': 'GoogleÃ¥ÂºÆ’Ã¥â€˜Å Ã£ÂÂ®Ã¨Â­Â¦Ã¥â€˜Å : {reason}',
      'analysis_secure':
          'Ã£Ââ„¢Ã£ÂÂ¹Ã£ÂÂ¦Ã£ÂÂ®Ã¥Ë†â€ Ã¦ÂÂÃ£ÂÂ¯Ã§Â«Â¯Ã¦Å“Â«Ã¥â€ â€¦Ã£ÂÂ§Ã¥Â®â€°Ã¥â€¦Â¨Ã£ÂÂ«Ã£Æ’Â­Ã£Æ’Â¼Ã£â€šÂ«Ã£Æ’Â«Ã¥â€¡Â¦Ã§Ââ€ Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'today_total_analysis':
          'Ã¦Å“Â¬Ã¦â€”Â¥Ã£ÂÂ®Ã¥Ë†â€ Ã¦ÂÂÃ§Â·ÂÃ¦â€¢Â°: {count}',
      'purchases_not_configured':
          'Ã§ÂÂ¾Ã¥Å“Â¨Ã£â‚¬ÂÃ¨Â³Â¼Ã¥â€¦Â¥Ã¦Â©Å¸Ã¨Æ’Â½Ã£ÂÂ¯Ã¥Ë†Â©Ã§â€Â¨Ã£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£â‚¬â€šÃ¥Â¾Å’Ã£ÂÂ§Ã£â€šâ€šÃ£Ââ€ Ã¤Â¸â‚¬Ã¥ÂºÂ¦Ã£ÂÅ Ã¨Â©Â¦Ã£Ââ€”Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'premium_already_active':
          'PremiumÃ£Æ’Â¡Ã£Æ’Â³Ã£Æ’ÂÃ£Æ’Â¼Ã£â€šÂ·Ã£Æ’Æ’Ã£Æ’â€”Ã£ÂÂ¯Ã¦Å“â€°Ã¥Å Â¹Ã£ÂÂ§Ã£Ââ„¢Ã£â‚¬â€š',
      'premium_welcome_box':
          'PremiumÃ£ÂÂ¸Ã£â€šË†Ã£Ââ€ Ã£Ââ€œÃ£ÂÂÃ¯Â¼ÂÃ¥ÂºÆ’Ã¥â€˜Å Ã£ÂÂ¨Ã¥Â¾â€¦Ã¦Â©Å¸Ã¦â„¢â€šÃ©â€“â€œÃ£ÂÅ’Ã¨Â§Â£Ã©â„¢Â¤Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š',
      'premium_main_description': 'すべての広告を削除し、待ち時間をなくし、無制限の分析を実行します。',
      'premium_benefits_title': 'プレミアム特典',
      'premium_benefit_no_ads': '広告は完全に削除されました。',
      'premium_benefit_fast': '待ち時間がなくなり、速度が向上しました。',
      'premium_benefit_unlimited': 'すべての機能へのフルアクセスと無制限の分析。',
      'remove_ads_and_limits_subtitle': '広告と待ち時間の削除。',
      'restore_purchases': 'Ã¨Â³Â¼Ã¥â€¦Â¥Ã£â€šâ€™Ã¥Â¾Â©Ã¥â€¦Æ’',
      'restore_purchases_short': '\u5FA9\u5143',
      'restoring_purchases': 'Ã¨Â³Â¼Ã¥â€¦Â¥Ã£â€šâ€™Ã¥Â¾Â©Ã¥â€¦Æ’Ã¤Â¸Â­...',
      'restore_purchases_success':
          'Ã¨Â³Â¼Ã¥â€¦Â¥Ã£â€šâ€™Ã¥Â¾Â©Ã¥â€¦Æ’Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸ Ã¢Å“â€¦',
      'restore_purchases_none':
          'Ã¥Â¾Â©Ã¥â€¦Æ’Ã£ÂÂ§Ã£ÂÂÃ£â€šâ€¹Ã¨Â³Â¼Ã¥â€¦Â¥Ã£ÂÅ’Ã£Ââ€šÃ£â€šÅ Ã£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£â‚¬â€š',
      'restore_purchases_failed':
          'Ã¥Â¾Â©Ã¥â€¦Æ’Ã£ÂÂ«Ã¥Â¤Â±Ã¦â€¢â€”Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸: {err}',
      'next_analysis': 'Ã¦Â¬Â¡Ã£ÂÂ®Ã¥Ë†â€ Ã¦ÂÂ',
      'next_analysis_ready':
          'Ã¤Â»Å Ã£Ââ„¢Ã£ÂÂÃ¥Ë†â€ Ã¦ÂÂÃ£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'analysis_ready_risk':
          'Ã¤Â»Å Ã£Ââ„¢Ã£ÂÂÃ¥Ë†â€ Ã¦ÂÂÃ£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ„¢Ã£ÂÅ’Ã£â‚¬ÂÃ©â‚¬Â£Ã§Â¶Å¡Ã¥Â®Å¸Ã¨Â¡Å’Ã£ÂÂ¯Ã£â€šÂ¢Ã£â€šÂ«Ã£â€šÂ¦Ã£Æ’Â³Ã£Æ’Ë†Ã£ÂÂ®Ã£Æ’ÂªÃ£â€šÂ¹Ã£â€šÂ¯Ã£ÂÂ«Ã£ÂÂªÃ£â€šâ€¹Ã¥ÂÂ¯Ã¨Æ’Â½Ã¦â‚¬Â§Ã£ÂÅ’Ã£Ââ€šÃ£â€šÅ Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'please_wait': 'Ã£ÂÅ Ã¥Â¾â€¦Ã£ÂÂ¡Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€',
      'remaining_time': 'Ã¦Â®â€¹Ã£â€šÅ Ã¦â„¢â€šÃ©â€“â€œ: {time}',
      'watch_ad':
          'Ã¥ÂºÆ’Ã¥â€˜Å Ã£â€šâ€™Ã¨Â¦â€¹Ã£ÂÂ¦Ã¥Ë†â€ Ã¦ÂÂÃ£â€šâ€™Ã©â€“â€¹Ã¥Â§â€¹',
      'start_analysis': 'Ã¥Ë†â€ Ã¦ÂÂÃ£â€šâ€™Ã©â€“â€¹Ã¥Â§â€¹',
      'start_analysis_question':
          'Ã¥Ë†â€ Ã¦ÂÂÃ£â€šâ€™Ã©â€“â€¹Ã¥Â§â€¹Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ„¢Ã£Ââ€¹Ã¯Â¼Å¸',
      'clear_data_title':
          'Ã£â€šÂ¢Ã£Æ’â€”Ã£Æ’ÂªÃ£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã£Æ’ÂªÃ£â€šÂ»Ã£Æ’Æ’Ã£Æ’Ë†',
      'clear_data_content':
          'Ã£Æ’Â­Ã£Æ’Â¼Ã£â€šÂ«Ã£Æ’Â«Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£ÂÂ¨Ã£â€šÂ»Ã£Æ’Æ’Ã£â€šÂ·Ã£Æ’Â§Ã£Æ’Â³Ã¦Æ’â€¦Ã¥Â Â±Ã£ÂÅ’Ã£Ââ„¢Ã£ÂÂ¹Ã£ÂÂ¦Ã¥â€°Å Ã©â„¢Â¤Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€šÃ£â€šË†Ã£â€šÂÃ£Ââ€”Ã£Ââ€Ã£ÂÂ§Ã£Ââ„¢Ã£Ââ€¹Ã¯Â¼Å¸',
      'cancel': 'Ã£â€šÂ­Ã£Æ’Â£Ã£Æ’Â³Ã£â€šÂ»Ã£Æ’Â«',
      'delete': 'Ã¥â€°Å Ã©â„¢Â¤',
      'ad_wait_message':
          'Ã¥Ë†â€ Ã¦ÂÂÃ£ÂÅ’Ã¥Â®Å’Ã¤Âºâ€ Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€šÃ¥ÂºÆ’Ã¥â€˜Å Ã£ÂÂ®Ã¥Â¾Å’Ã£ÂÂ«Ã§ÂµÂÃ¦ÂÅ“Ã£â€šâ€™Ã¨Â¡Â¨Ã§Â¤ÂºÃ£Ââ€”Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'analysis_failed_title':
          'Ã¥Ë†â€ Ã¦ÂÂÃ£ÂÂ«Ã¥Â¤Â±Ã¦â€¢â€”Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸',
      'analysis_failed_reason': 'Ã§Ââ€ Ã§â€Â±: {reason}',
      'analysis_failed_hint':
          'Ã£Æ’â€™Ã£Æ’Â³Ã£Æ’Ë†: Ã£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¢Ã£â€šÂ¦Ã£Æ’Ë†Ã£Ââ€”Ã£ÂÂ¦Ã¥â€ ÂÃ£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¤Ã£Æ’Â³Ã£Ââ„¢Ã£â€šâ€¹Ã£ÂÂ¨Ã¦â€Â¹Ã¥â€“â€Ã£Ââ„¢Ã£â€šâ€¹Ã¥Â Â´Ã¥ÂË†Ã£ÂÅ’Ã£Ââ€šÃ£â€šÅ Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'story_section_title':
          'Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£â€šâ€™Ã£Ââ€œÃ£ÂÂ£Ã£ÂÂÃ£â€šÅ Ã¨Â¦â€¹Ã£â€šâ€¹ / Ã£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ£Ã£Æ’Â¼Ã£Æ’Â«Ã¥â€ â„¢Ã§Å“Å¸Ã£â€šâ€™Ã¦â€¹Â¡Ã¥Â¤Â§',
      'story_login_required':
          'Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£â€šâ€™Ã¥Å’Â¿Ã¥ÂÂÃ£ÂÂ§Ã¨Â¦â€¹Ã£ÂÅ¸Ã£â€šÅ Ã£â‚¬ÂÃ£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ£Ã£Æ’Â¼Ã£Æ’Â«Ã¥â€ â„¢Ã§Å“Å¸Ã£â€šâ€™Ã¦â€¹Â¡Ã¥Â¤Â§Ã£Ââ€”Ã£ÂÅ¸Ã£â€šÅ Ã£Ââ„¢Ã£â€šâ€¹Ã£ÂÂ«Ã£ÂÂ¯Ã£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¤Ã£Æ’Â³Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'story_ad_wait':
          'Ã¥ÂºÆ’Ã¥â€˜Å Ã£ÂÂ®Ã¥Â¾Å’Ã£ÂÂ«Ã¨Â¡Â¨Ã§Â¤ÂºÃ£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€šÃ£Ââ€”Ã£ÂÂ°Ã£â€šâ€°Ã£ÂÂÃ£ÂÅ Ã¥Â¾â€¦Ã£ÂÂ¡Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'story_action_title': 'Ã¤Â½â€¢Ã£â€šâ€™Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ„¢Ã£Ââ€¹Ã¯Â¼Å¸',
      'story_view_photo':
          'Ã£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ£Ã£Æ’Â¼Ã£Æ’Â«Ã¥â€ â„¢Ã§Å“Å¸Ã£â€šâ€™Ã¦â€¹Â¡Ã¥Â¤Â§',
      'story_watch_secret': '\u8db3\u8de1\u306a\u3057\u3067\u95b2\u89a7',
      'story_no_data':
          'Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£ÂÅ’Ã¨Â¦â€¹Ã£ÂÂ¤Ã£Ââ€¹Ã£â€šÅ Ã£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£â‚¬â€š',
      'story_close': 'Ã©â€“â€°Ã£ÂËœÃ£â€šâ€¹',
      'no_data': '\u30C7\u30FC\u30BF\u306A\u3057',
      'new_badge': '\u65B0\u7740',
      'login_title': '\u30ED\u30B0\u30A4\u30F3',
      'read_and_agree':
          'Ã¥â€ â€¦Ã¥Â®Â¹Ã£â€šâ€™Ã¨ÂªÂ­Ã£ÂÂ¿Ã£â‚¬ÂÃ¥ÂÅ’Ã¦â€ÂÃ£Ââ€”Ã£ÂÂ¾Ã£Ââ„¢',
      'withdraw_consent': 'Ã¥ÂÅ’Ã¦â€ÂÃ£â€šâ€™Ã¥Ââ€“Ã£â€šÅ Ã¦Â¶Ë†Ã£Ââ„¢',
      'withdraw_consent_confirm_title': 'Ã§Â¢ÂºÃ¨ÂªÂ',
      'withdraw_consent_confirm_body':
          'Ã¥ÂÅ’Ã¦â€ÂÃ¨Â¨Â­Ã¥Â®Å¡Ã£ÂÅ’Ã£Æ’ÂªÃ£â€šÂ»Ã£Æ’Æ’Ã£Æ’Ë†Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€šÃ£â€šË†Ã£â€šÂÃ£Ââ€”Ã£Ââ€Ã£ÂÂ§Ã£Ââ„¢Ã£Ââ€¹Ã¯Â¼Å¸',
      'withdraw_consent_confirm_yes': 'Ã£ÂÂ¯Ã£Ââ€',
      'withdraw_consent_confirm_no': 'Ã¦Ë†Â»Ã£â€šâ€¹',
      'data_updated': 'Ã¥Ë†â€ Ã¦ÂÂÃ¥Â®Å’Ã¤Âºâ€  Ã¢Å“â€¦',
      'enter_pin': 'PINÃ£â€šâ€™Ã¥â€¦Â¥Ã¥Å â€º',
      'pin_accepted':
          'PINÃ£â€šâ€™Ã§Â¢ÂºÃ¨ÂªÂÃ£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€šÃ£â€šÂ¿Ã£â€šÂ¤Ã£Æ’ÂÃ£Æ’Â¼Ã£â€šâ€™Ã£Æ’ÂªÃ£â€šÂ»Ã£Æ’Æ’Ã£Æ’Ë†Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸ Ã¢Å“â€¦',
      'pin_incorrect':
          'PINÃ£ÂÅ’Ã¦Â­Â£Ã£Ââ€”Ã£ÂÂÃ£Ââ€šÃ£â€šÅ Ã£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œ',
      'ok': 'OK',
      'legal_warning': 'Ã¦Â³â€¢Ã§Å¡â€Ã¦Â³Â¨Ã¦â€ÂÃ¤Âºâ€¹Ã©Â â€¦',
      'rate_us': '\u8A55\u4FA1\u3059\u308B',
      'contact_us': '\u304A\u554F\u3044\u5408\u308F\u305B',
      'remove_ads_and_limits':
          '\u5E83\u544A\u3068\u5F85\u6A5F\u6642\u9593\u3092\u524A\u9664',
      'legal_intro':
          'Ã¦Å“Â¬Ã£â€šÂ¢Ã£Æ’â€”Ã£Æ’ÂªÃ£â€šâ€™Ã£Æ’â‚¬Ã£â€šÂ¦Ã£Æ’Â³Ã£Æ’Â­Ã£Æ’Â¼Ã£Æ’â€°Ã£Ââ€”Ã£ÂÂ¦Ã¥Ë†Â©Ã§â€Â¨Ã£Ââ€”Ã£ÂÅ¸Ã¦â„¢â€šÃ§â€šÂ¹Ã£ÂÂ§Ã£â‚¬ÂÃ¤Â»Â¥Ã¤Â¸â€¹Ã£ÂÂ®Ã¨Â¦ÂÃ§Â´â€Ã£ÂÂ«Ã¥ÂÅ’Ã¦â€ÂÃ£Ââ€”Ã£ÂÅ¸Ã£â€šâ€šÃ£ÂÂ®Ã£ÂÂ¨Ã£ÂÂ¿Ã£ÂÂªÃ£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'user_label': '\u30E6\u30FC\u30B6\u30FC',
    },
    'ru': {
      'tagline':
          'ÄÅ¸Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂµÃ‘ÂÃ‘ÂÄÂ¸ÄÂ¾ÄÂ½ÄÂ°ÄÂ»Ã‘Å’ÄÂ½Ã‘â€¹ÄÂµ Ã‘â‚¬ÄÂµÃ‘Ë†ÄÂµÄÂ½ÄÂ¸Ã‘Â ÄÂ´ÄÂ»Ã‘Â Ã‘ÂÄÂ¾Ã‘â€ Ã‘ÂÄÂµÃ‘â€šÄÂµÄÂ¹',
      'admin_active_note':
          'ÄÂ ÄÂµÄÂ¶ÄÂ¸ÄÂ¼ ÄÂ°ÄÂ´ÄÂ¼ÄÂ¸ÄÂ½ÄÂ¸Ã‘ÂÃ‘â€šÃ‘â‚¬ÄÂ°Ã‘â€šÄÂ¾Ã‘â‚¬ÄÂ° ÄÂ°ÄÂºÃ‘â€šÄÂ¸ÄÂ²ÄÂµÄÂ½',
      'free_app_note':
          'ÄÅ“Ã‘â€¹ ÄÂµÄÂ¶ÄÂµÄÂ´ÄÂ½ÄÂµÄÂ²ÄÂ½ÄÂ¾ Ã‘Æ’ÄÂ»Ã‘Æ’Ã‘â€¡Ã‘Ë†ÄÂ°ÄÂµÄÂ¼ ÄÂ¿Ã‘â‚¬ÄÂ¸ÄÂ»ÄÂ¾ÄÂ¶ÄÂµÄÂ½ÄÂ¸ÄÂµ, Ã‘â€¡Ã‘â€šÄÂ¾ÄÂ±Ã‘â€¹ Ã‘ÂÄÂ´ÄÂµÄÂ»ÄÂ°Ã‘â€šÃ‘Å’ ÄÂ²ÄÂ°Ã‘Ë† ÄÂ¾ÄÂ¿Ã‘â€¹Ã‘â€š ÄÂ»Ã‘Æ’Ã‘â€¡Ã‘Ë†ÄÂµ. Äâ€™ÄÂ°Ã‘Ë† ÄÂ¾Ã‘â€šÄÂ·Ã‘â€¹ÄÂ² ÄÂ²ÄÂ°ÄÂ¶ÄÂµÄÂ½ ÄÂ´ÄÂ»Ã‘Â ÄÂ½ÄÂ°Ã‘Â.',
      'login_prompt':
          'ÄÅ¸ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ²ÄÂ¾ÄÂ¹ÄÂ´ÄÂ¸Ã‘â€šÄÂµ, Ã‘â€¡Ã‘â€šÄÂ¾ÄÂ±Ã‘â€¹ ÄÂ½ÄÂ°Ã‘â€¡ÄÂ°Ã‘â€šÃ‘Å’ ÄÂ°ÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ·.',
      'welcome':
          'Äâ€ÄÂ¾ÄÂ±Ã‘â‚¬ÄÂ¾ ÄÂ¿ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»ÄÂ¾ÄÂ²ÄÂ°Ã‘â€šÃ‘Å’, {username}',
      'refresh_data':
          'ÄÂÄâ€˜ÄÂÄÂÄâ€™ÄËœÄÂ¢ÄÂ¬ Äâ€ÄÂÄÂÄÂÄÂ«Äâ€¢',
      'login_with_instagram':
          'Äâ€™ÄÂÄâ„¢ÄÂ¢ÄËœ ÄÂ§Äâ€¢ÄÂ Äâ€¢Äâ€” INSTAGRAM',
      'fetching_data':
          'ÄÂÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ·ÄÂ¸Ã‘â‚¬Ã‘Æ’ÄÂµÄÂ¼ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ...\nÄÂ­Ã‘â€šÄÂ¾ ÄÂ¼ÄÂ¾ÄÂ¶ÄÂµÃ‘â€š ÄÂ·ÄÂ°ÄÂ½Ã‘ÂÃ‘â€šÃ‘Å’ ÄÂ½ÄÂµÄÂ¼ÄÂ½ÄÂ¾ÄÂ³ÄÂ¾ ÄÂ²Ã‘â‚¬ÄÂµÄÂ¼ÄÂµÄÂ½ÄÂ¸.',
      'processing_data':
          'ÄÂÄÂ±Ã‘â‚¬ÄÂ°ÄÂ±ÄÂ°Ã‘â€šÃ‘â€¹ÄÂ²ÄÂ°ÄÂµÄÂ¼ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ...\nÄÅ¸ÄÂ¾Ã‘â€¡Ã‘â€šÄÂ¸ ÄÂ³ÄÂ¾Ã‘â€šÄÂ¾ÄÂ²ÄÂ¾.',
      'loading_ad':
          'Äâ€”ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° Ã‘â‚¬ÄÂµÄÂºÄÂ»ÄÂ°ÄÂ¼Ã‘â€¹...\nÄÅ¸ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¾ÄÂ¶ÄÂ´ÄÂ¸Ã‘â€šÄÂµ.',
      'google_ad_warning':
          'ÄÅ¸Ã‘â‚¬ÄÂµÄÂ´Ã‘Æ’ÄÂ¿Ã‘â‚¬ÄÂµÄÂ¶ÄÂ´ÄÂµÄÂ½ÄÂ¸ÄÂµ Ã‘â‚¬ÄÂµÄÂºÄÂ»ÄÂ°ÄÂ¼Ã‘â€¹ Google: {reason}',
      'analysis_secure':
          'Äâ€™ÄÂµÃ‘ÂÃ‘Å’ ÄÂ°ÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ· ÄÂ±ÄÂµÄÂ·ÄÂ¾ÄÂ¿ÄÂ°Ã‘ÂÄÂ½ÄÂ¾ ÄÂ²Ã‘â€¹ÄÂ¿ÄÂ¾ÄÂ»ÄÂ½Ã‘ÂÄÂµÃ‘â€šÃ‘ÂÃ‘Â ÄÂ»ÄÂ¾ÄÂºÄÂ°ÄÂ»Ã‘Å’ÄÂ½ÄÂ¾ ÄÂ½ÄÂ° ÄÂ²ÄÂ°Ã‘Ë†ÄÂµÄÂ¼ Ã‘Æ’Ã‘ÂÃ‘â€šÃ‘â‚¬ÄÂ¾ÄÂ¹Ã‘ÂÃ‘â€šÄÂ²ÄÂµ.',
      'today_total_analysis':
          'Äâ€™Ã‘ÂÄÂµÄÂ³ÄÂ¾ ÄÂ°ÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ·ÄÂ¾ÄÂ² Ã‘ÂÄÂµÄÂ³ÄÂ¾ÄÂ´ÄÂ½Ã‘Â: {count}',
      'purchases_not_configured':
          'ÄÅ¸ÄÂ¾ÄÂºÃ‘Æ’ÄÂ¿ÄÂºÄÂ¸ Ã‘ÂÄÂµÄÂ¹Ã‘â€¡ÄÂ°Ã‘Â ÄÂ½ÄÂµÄÂ´ÄÂ¾Ã‘ÂÃ‘â€šÃ‘Æ’ÄÂ¿ÄÂ½Ã‘â€¹. ÄÅ¸ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ¿ÄÂ¾ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ±Ã‘Æ’ÄÂ¹Ã‘â€šÄÂµ ÄÂ¿ÄÂ¾ÄÂ·ÄÂ¶ÄÂµ.',
      'premium_already_active':
          'Äâ€™ÄÂ°Ã‘Ë†ÄÂ° ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¿ÄÂ¸Ã‘ÂÄÂºÄÂ° Premium ÄÂ°ÄÂºÃ‘â€šÄÂ¸ÄÂ²ÄÂ½ÄÂ°.',
      'premium_welcome_box':
          'Äâ€ÄÂ¾ÄÂ±Ã‘â‚¬ÄÂ¾ ÄÂ¿ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»ÄÂ¾ÄÂ²ÄÂ°Ã‘â€šÃ‘Å’ ÄÂ² Premium! ÄÂ ÄÂµÄÂºÄÂ»ÄÂ°ÄÂ¼ÄÂ° ÄÂ¸ ÄÂ¾ÄÂ¶ÄÂ¸ÄÂ´ÄÂ°ÄÂ½ÄÂ¸ÄÂµ ÄÂ¾Ã‘â€šÄÂºÄÂ»Ã‘ÂÃ‘â€¡ÄÂµÄÂ½Ã‘â€¹.',
      'premium_main_description':
          '\u0423\u0434\u0430\u043B\u0438\u0442\u0435 \u0432\u0441\u044E \u0440\u0435\u043A\u043B\u0430\u043C\u0443, \u0438\u0441\u043A\u043B\u044E\u0447\u0438\u0442\u0435 \u0432\u0440\u0435\u043C\u044F \u043E\u0436\u0438\u0434\u0430\u043D\u0438\u044F \u0438 \u043F\u0440\u043E\u0432\u043E\u0434\u0438\u0442\u0435 \u043D\u0435\u043E\u0433\u0440\u0430\u043D\u0438\u0447\u0435\u043D\u043D\u044B\u0439 \u0430\u043D\u0430\u043B\u0438\u0437.',
      'premium_benefits_title':
          '\u041F\u0440\u0435\u0431\u0430\u0432\u043A\u0438 Premium',
      'premium_benefit_no_ads':
          '\u0420\u0435\u043A\u043B\u0430\u043C\u0430 \u043F\u043E\u043B\u043D\u043E\u0441\u0442\u044C\u044E \u0443\u0434\u0430\u043B\u0435\u043D\u0430.',
      'premium_benefit_fast':
          '\u0412\u0440\u0435\u043C\u044F \u043E\u0436\u0438\u0434\u0430\u043D\u0438\u044F \u0438\u0441\u043A\u043B\u044E\u0447\u0435\u043D\u043E.',
      'premium_benefit_unlimited':
          '\u041D\u0435\u043E\u0433\u0440\u0430\u043D\u0438\u0447\u0435\u043D\u043D\u044B\u0439 \u0430\u043D\u0430\u043B\u0438\u0437 \u0441 \u043F\u043E\u043B\u043D\u044B\u043C \u0434\u043E\u0441\u0442\u0443\u043F\u043E\u043C.',
      'remove_ads_and_limits_subtitle':
          '\u0423\u0431\u0440\u0430\u0442\u044C \u0440\u0435\u043A\u043B\u0430\u043C\u0443 \u0438 \u043E\u0436\u0438\u0434\u0430\u043D\u0438\u0435.',
      'restore_purchases':
          'Äâ€™ÄÂ¾Ã‘ÂÃ‘ÂÃ‘â€šÄÂ°ÄÂ½ÄÂ¾ÄÂ²ÄÂ¸Ã‘â€šÃ‘Å’ ÄÂ¿ÄÂ¾ÄÂºÃ‘Æ’ÄÂ¿ÄÂºÄÂ¸',
      'restore_purchases_short':
          '\u0412\u041E\u0421\u0421\u0422\u0410\u041D\u041E\u0412\u0418\u0422\u042C',
      'restoring_purchases':
          'Äâ€™ÄÂ¾Ã‘ÂÃ‘ÂÃ‘â€šÄÂ°ÄÂ½ÄÂ°ÄÂ²ÄÂ»ÄÂ¸ÄÂ²ÄÂ°ÄÂµÄÂ¼ ÄÂ¿ÄÂ¾ÄÂºÃ‘Æ’ÄÂ¿ÄÂºÄÂ¸...',
      'restore_purchases_success':
          'ÄÅ¸ÄÂ¾ÄÂºÃ‘Æ’ÄÂ¿ÄÂºÄÂ¸ ÄÂ²ÄÂ¾Ã‘ÂÃ‘ÂÃ‘â€šÄÂ°ÄÂ½ÄÂ¾ÄÂ²ÄÂ»ÄÂµÄÂ½Ã‘â€¹ Ã¢Å“â€¦',
      'restore_purchases_none':
          'ÄÂÄÂµÃ‘â€š ÄÂ¿ÄÂ¾ÄÂºÃ‘Æ’ÄÂ¿ÄÂ¾ÄÂº ÄÂ´ÄÂ»Ã‘Â ÄÂ²ÄÂ¾Ã‘ÂÃ‘ÂÃ‘â€šÄÂ°ÄÂ½ÄÂ¾ÄÂ²ÄÂ»ÄÂµÄÂ½ÄÂ¸Ã‘Â.',
      'restore_purchases_failed':
          'ÄÂÃ‘Ë†ÄÂ¸ÄÂ±ÄÂºÄÂ° ÄÂ²ÄÂ¾Ã‘ÂÃ‘ÂÃ‘â€šÄÂ°ÄÂ½ÄÂ¾ÄÂ²ÄÂ»ÄÂµÄÂ½ÄÂ¸Ã‘Â: {err}',
      'next_analysis':
          'ÄÂ¡ÄÂ»ÄÂµÄÂ´Ã‘Æ’Ã‘ÂÃ‘â€°ÄÂ¸ÄÂ¹ ÄÂ°ÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ·',
      'next_analysis_ready':
          'ÄÂÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ· Ã‘Æ’ÄÂ¶ÄÂµ ÄÂ´ÄÂ¾Ã‘ÂÃ‘â€šÃ‘Æ’ÄÂ¿ÄÂµÄÂ½.',
      'analysis_ready_risk':
          'ÄÂÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ· ÄÂ´ÄÂ¾Ã‘ÂÃ‘â€šÃ‘Æ’ÄÂ¿ÄÂµÄÂ½ Ã‘ÂÄÂµÄÂ¹Ã‘â€¡ÄÂ°Ã‘Â, ÄÂ½ÄÂ¾ Ã‘â€¡ÄÂ°Ã‘ÂÃ‘â€šÃ‘â€¹ÄÂµ ÄÂ¿ÄÂ¾ÄÂ´Ã‘â‚¬Ã‘ÂÄÂ´ ÄÂ°ÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ·Ã‘â€¹ ÄÂ¼ÄÂ¾ÄÂ³Ã‘Æ’Ã‘â€š ÄÂ¿ÄÂ¾ÄÂ²Ã‘â€¹Ã‘ÂÄÂ¸Ã‘â€šÃ‘Å’ Ã‘â‚¬ÄÂ¸Ã‘ÂÄÂº ÄÂ´ÄÂ»Ã‘Â ÄÂ°ÄÂºÄÂºÄÂ°Ã‘Æ’ÄÂ½Ã‘â€šÄÂ°.',
      'please_wait':
          'ÄÅ¸ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¾ÄÂ¶ÄÂ´ÄÂ¸Ã‘â€šÄÂµ',
      'remaining_time':
          'ÄÂÃ‘ÂÃ‘â€šÄÂ°ÄÂ»ÄÂ¾Ã‘ÂÃ‘Å’ ÄÂ²Ã‘â‚¬ÄÂµÄÂ¼ÄÂµÄÂ½ÄÂ¸: {time}',
      'watch_ad':
          'ÄÅ¸ÄÂÄÂ¡ÄÅ“ÄÂÄÂ¢ÄÂ Äâ€¢ÄÂ¢ÄÂ¬ ÄÂ Äâ€¢ÄÅ¡Äâ€ºÄÂÄÅ“ÄÂ£ ÄËœ ÄÂÄÂÄÂ§ÄÂÄÂ¢ÄÂ¬ ÄÂÄÂÄÂÄâ€ºÄËœÄâ€”',
      'start_analysis': 'ÄÂÄÂÄÂ§ÄÂÄÂ¢ÄÂ¬ ÄÂÄÂÄÂÄâ€ºÄËœÄâ€”',
      'start_analysis_question':
          'ÄÂÄÂ°Ã‘â€¡ÄÂ°Ã‘â€šÃ‘Å’ ÄÂ°ÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ·?',
      'clear_data_title':
          'ÄÂ¡ÄÂ±Ã‘â‚¬ÄÂ¾Ã‘Â ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹Ã‘â€¦ ÄÂ¿Ã‘â‚¬ÄÂ¸ÄÂ»ÄÂ¾ÄÂ¶ÄÂµÄÂ½ÄÂ¸Ã‘Â',
      'clear_data_content':
          'Äâ€™Ã‘ÂÄÂµ ÄÂ»ÄÂ¾ÄÂºÄÂ°ÄÂ»Ã‘Å’ÄÂ½Ã‘â€¹ÄÂµ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ ÄÂ¸ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ Ã‘ÂÄÂµÃ‘ÂÃ‘ÂÄÂ¸ÄÂ¸ ÄÂ±Ã‘Æ’ÄÂ´Ã‘Æ’Ã‘â€š Ã‘Æ’ÄÂ´ÄÂ°ÄÂ»ÄÂµÄÂ½Ã‘â€¹. ÄÅ¸Ã‘â‚¬ÄÂ¾ÄÂ´ÄÂ¾ÄÂ»ÄÂ¶ÄÂ¸Ã‘â€šÃ‘Å’?',
      'cancel': 'ÄÂÄÂ¢ÄÅ“Äâ€¢ÄÂÄÂ',
      'delete': 'ÄÂ£Äâ€ÄÂÄâ€ºÄËœÄÂ¢ÄÂ¬',
      'ad_wait_message':
          'ÄÂÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ· ÄÂ·ÄÂ°ÄÂ²ÄÂµÃ‘â‚¬Ã‘Ë†ÄÂµÄÂ½, Ã‘â‚¬ÄÂµÄÂ·Ã‘Æ’ÄÂ»Ã‘Å’Ã‘â€šÄÂ°Ã‘â€šÃ‘â€¹ ÄÂ±Ã‘Æ’ÄÂ´Ã‘Æ’Ã‘â€š ÄÂ¿ÄÂ¾ÄÂºÄÂ°ÄÂ·ÄÂ°ÄÂ½Ã‘â€¹ ÄÂ¿ÄÂ¾Ã‘ÂÄÂ»ÄÂµ Ã‘â‚¬ÄÂµÄÂºÄÂ»ÄÂ°ÄÂ¼Ã‘â€¹.',
      'analysis_failed_title':
          'ÄÂÄÂµ Ã‘Æ’ÄÂ´ÄÂ°ÄÂ»ÄÂ¾Ã‘ÂÃ‘Å’ ÄÂ²Ã‘â€¹ÄÂ¿ÄÂ¾ÄÂ»ÄÂ½ÄÂ¸Ã‘â€šÃ‘Å’ ÄÂ°ÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ·',
      'analysis_failed_reason': 'ÄÅ¸Ã‘â‚¬ÄÂ¸Ã‘â€¡ÄÂ¸ÄÂ½ÄÂ°: {reason}',
      'analysis_failed_hint':
          'ÄÂ¡ÄÂ¾ÄÂ²ÄÂµÃ‘â€š: ÄÂ¿ÄÂ¾ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ±Ã‘Æ’ÄÂ¹Ã‘â€šÄÂµ ÄÂ²Ã‘â€¹ÄÂ¹Ã‘â€šÄÂ¸ ÄÂ¸ ÄÂ²ÄÂ¾ÄÂ¹Ã‘â€šÄÂ¸ Ã‘ÂÄÂ½ÄÂ¾ÄÂ²ÄÂ°.',
      'story_section_title':
          'ÄÂ¡ÄÂ¼ÄÂ¾Ã‘â€šÃ‘â‚¬ÄÂµÃ‘â€šÃ‘Å’ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ°ÄÂ½ÄÂ¾ÄÂ½ÄÂ¸ÄÂ¼ÄÂ½ÄÂ¾ ÄÂ¸ÄÂ»ÄÂ¸ Ã‘Æ’ÄÂ²ÄÂµÄÂ»ÄÂ¸Ã‘â€¡ÄÂ¸ÄÂ²ÄÂ°Ã‘â€šÃ‘Å’ Ã‘â€ÄÂ¾Ã‘â€šÄÂ¾ ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂ¸ÄÂ»Ã‘Â',
      'story_login_required':
          'ÄÅ¸ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ²ÄÂ¾ÄÂ¹ÄÂ´ÄÂ¸Ã‘â€šÄÂµ, Ã‘â€¡Ã‘â€šÄÂ¾ÄÂ±Ã‘â€¹ ÄÂ°ÄÂ½ÄÂ¾ÄÂ½ÄÂ¸ÄÂ¼ÄÂ½ÄÂ¾ Ã‘ÂÄÂ¼ÄÂ¾Ã‘â€šÃ‘â‚¬ÄÂµÃ‘â€šÃ‘Å’ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ¸ Ã‘Æ’ÄÂ²ÄÂµÄÂ»ÄÂ¸Ã‘â€¡ÄÂ¸ÄÂ²ÄÂ°Ã‘â€šÃ‘Å’ Ã‘â€ÄÂ¾Ã‘â€šÄÂ¾ ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂ¸ÄÂ»Ã‘Â.',
      'story_ad_wait':
          'ÄÅ¸ÄÂ¾Ã‘ÂÄÂ²ÄÂ¸Ã‘â€šÃ‘ÂÃ‘Â ÄÂ¿ÄÂ¾Ã‘ÂÄÂ»ÄÂµ Ã‘â‚¬ÄÂµÄÂºÄÂ»ÄÂ°ÄÂ¼Ã‘â€¹, ÄÂ¿ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¾ÄÂ¶ÄÂ´ÄÂ¸Ã‘â€šÄÂµ.',
      'story_action_title':
          'ÄÂ§Ã‘â€šÄÂ¾ ÄÂ²Ã‘â€¹ Ã‘â€¦ÄÂ¾Ã‘â€šÄÂ¸Ã‘â€šÄÂµ Ã‘ÂÄÂ´ÄÂµÄÂ»ÄÂ°Ã‘â€šÃ‘Å’?',
      'story_view_photo':
          'ÄÂ£ÄÂ²ÄÂµÄÂ»ÄÂ¸Ã‘â€¡ÄÂ¸Ã‘â€šÃ‘Å’ Ã‘â€ÄÂ¾Ã‘â€šÄÂ¾ ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂ¸ÄÂ»Ã‘Â',
      'story_watch_secret':
          'ÄÂ¡ÄÂ¼ÄÂ¾Ã‘â€šÃ‘â‚¬ÄÂµÃ‘â€šÃ‘Å’ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ°ÄÂ½ÄÂ¾ÄÂ½ÄÂ¸ÄÂ¼ÄÂ½ÄÂ¾',
      'story_no_data':
          'Äâ€ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ½ÄÂµ ÄÂ½ÄÂ°ÄÂ¹ÄÂ´ÄÂµÄÂ½Ã‘â€¹.',
      'story_close': 'Äâ€”ÄÂÄÅ¡ÄÂ ÄÂ«ÄÂ¢ÄÂ¬',
      'no_data': '\u041D\u0435\u0442 \u0434\u0430\u043D\u043D\u044B\u0445',
      'new_badge': '\u041D\u041E\u0412\u041E\u0415',
      'login_title': '\u0412\u0445\u043E\u0434',
      'read_and_agree':
          'ÄÂ¯ ÄÅ¸ÄÂ ÄÂÄÂ§ÄËœÄÂ¢ÄÂÄâ€º ÄËœ ÄÂ¡ÄÂÄâ€œÄâ€ºÄÂÄÂ¡Äâ€¢ÄÂ',
      'withdraw_consent':
          'ÄÂÃ‘â€šÄÂ¾ÄÂ·ÄÂ²ÄÂ°Ã‘â€šÃ‘Å’ Ã‘ÂÄÂ¾ÄÂ³ÄÂ»ÄÂ°Ã‘ÂÄÂ¸ÄÂµ',
      'withdraw_consent_confirm_title':
          'ÄÅ¸ÄÂ¾ÄÂ´Ã‘â€šÄÂ²ÄÂµÃ‘â‚¬ÄÂ¶ÄÂ´ÄÂµÄÂ½ÄÂ¸ÄÂµ',
      'withdraw_consent_confirm_body':
          'ÄÂÄÂ°Ã‘ÂÃ‘â€šÃ‘â‚¬ÄÂ¾ÄÂ¹ÄÂºÄÂ¸ Ã‘ÂÄÂ¾ÄÂ³ÄÂ»ÄÂ°Ã‘ÂÄÂ¸Ã‘Â ÄÂ±Ã‘Æ’ÄÂ´Ã‘Æ’Ã‘â€š Ã‘ÂÄÂ±Ã‘â‚¬ÄÂ¾Ã‘Ë†ÄÂµÄÂ½Ã‘â€¹. Äâ€™Ã‘â€¹ Ã‘Æ’ÄÂ²ÄÂµÃ‘â‚¬ÄÂµÄÂ½Ã‘â€¹?',
      'withdraw_consent_confirm_yes': 'Äâ€ÄÂ°',
      'withdraw_consent_confirm_no': 'ÄÂÃ‘â€šÄÂ¼ÄÂµÄÂ½ÄÂ°',
      'data_updated':
          'ÄÂÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ· ÄÂ·ÄÂ°ÄÂ²ÄÂµÃ‘â‚¬Ã‘Ë†ÄÂµÄÂ½ Ã¢Å“â€¦',
      'enter_pin': 'Äâ€™ÄÂ²ÄÂµÄÂ´ÄÂ¸Ã‘â€šÄÂµ PIN',
      'pin_accepted':
          'PIN ÄÂ¿Ã‘â‚¬ÄÂ¸ÄÂ½Ã‘ÂÃ‘â€š, Ã‘â€šÄÂ°ÄÂ¹ÄÂ¼ÄÂµÃ‘â‚¬ Ã‘ÂÄÂ±Ã‘â‚¬ÄÂ¾Ã‘Ë†ÄÂµÄÂ½ Ã¢Å“â€¦',
      'pin_incorrect': 'ÄÂÄÂµÄÂ²ÄÂµÃ‘â‚¬ÄÂ½Ã‘â€¹ÄÂ¹ PIN',
      'ok': 'OK',
      'legal_warning':
          'ÄÂ®Ã‘â‚¬ÄÂ¸ÄÂ´ÄÂ¸Ã‘â€¡ÄÂµÃ‘ÂÄÂºÄÂ¾ÄÂµ ÄÂ¿Ã‘â‚¬ÄÂµÄÂ´Ã‘Æ’ÄÂ¿Ã‘â‚¬ÄÂµÄÂ¶ÄÂ´ÄÂµÄÂ½ÄÂ¸ÄÂµ',
      'rate_us':
          '\u041E\u0446\u0435\u043D\u0438\u0442\u0435 \u043D\u0430\u0441',
      'contact_us':
          '\u0421\u0432\u044F\u0437\u0430\u0442\u044C\u0441\u044F \u0441 \u043D\u0430\u043C\u0438',
      'remove_ads_and_limits':
          '\u0423\u0431\u0440\u0430\u0442\u044C \u0440\u0435\u043A\u043B\u0430\u043C\u0443 \u0438 \u043E\u0436\u0438\u0434\u0430\u043D\u0438\u0435',
      'legal_intro':
          'ÄÂ¡ÄÂºÄÂ°Ã‘â€¡ÄÂ¸ÄÂ²ÄÂ°Ã‘Â ÄÂ¸ ÄÂ¸Ã‘ÂÄÂ¿ÄÂ¾ÄÂ»Ã‘Å’ÄÂ·Ã‘Æ’Ã‘Â Ã‘ÂÃ‘â€šÄÂ¾ ÄÂ¿Ã‘â‚¬ÄÂ¸ÄÂ»ÄÂ¾ÄÂ¶ÄÂµÄÂ½ÄÂ¸ÄÂµ, ÄÂ¿ÄÂ¾ÄÂ»Ã‘Å’ÄÂ·ÄÂ¾ÄÂ²ÄÂ°Ã‘â€šÄÂµÄÂ»Ã‘Å’ Ã‘ÂÃ‘â€¡ÄÂ¸Ã‘â€šÄÂ°ÄÂµÃ‘â€šÃ‘ÂÃ‘Â ÄÂ¾ÄÂ·ÄÂ½ÄÂ°ÄÂºÄÂ¾ÄÂ¼ÄÂ¸ÄÂ²Ã‘Ë†ÄÂ¸ÄÂ¼Ã‘ÂÃ‘Â ÄÂ¸ Ã‘ÂÄÂ¾ÄÂ³ÄÂ»ÄÂ°Ã‘ÂÄÂ¸ÄÂ²Ã‘Ë†ÄÂ¸ÄÂ¼Ã‘ÂÃ‘Â Ã‘Â Ã‘Æ’Ã‘ÂÄÂ»ÄÂ¾ÄÂ²ÄÂ¸Ã‘ÂÄÂ¼ÄÂ¸ ÄÂ½ÄÂ¸ÄÂ¶ÄÂµ.',
      'user_label':
          '\u041F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u0435\u043B\u044C',
    },
    'pt': {
      'tagline': 'SoluÃƒÂ§ÃƒÂµes profissionais para redes sociais',
      'admin_active_note': 'Modo administrador ativo',
      'free_app_note':
          'Estamos evoluindo todos os dias para oferecer uma experiÃƒÂªncia melhor. Seu feedback ÃƒÂ© muito importante para nÃƒÂ³s.',
      'login_prompt': 'FaÃƒÂ§a login para iniciar a anÃƒÂ¡lise.',
      'welcome': 'Bem-vindo, {username}',
      'refresh_data': 'ATUALIZAR DADOS',
      'login_with_instagram': 'ENTRAR COM INSTAGRAM',
      'fetching_data': 'Analisando dados...\nIsso pode levar um momento.',
      'processing_data': 'Processando dados...\nQuase pronto.',
      'loading_ad': 'Carregando anÃƒÂºncio...\nAguarde.',
      'google_ad_warning': 'Aviso de anÃƒÂºncio do Google: {reason}',
      'analysis_secure':
          'Toda a anÃƒÂ¡lise ÃƒÂ© processada com seguranÃƒÂ§a localmente no seu dispositivo.',
      'today_total_analysis': 'Total de anÃƒÂ¡lises hoje: {count}',
      'purchases_not_configured':
          'Compras indisponÃƒÂ­veis no momento. Tente novamente mais tarde.',
      'premium_already_active': 'Sua assinatura Premium estÃƒÂ¡ ativa.',
      'premium_welcome_box':
          'Bem-vindo ao Premium! AnÃƒÂºncios e tempos de espera foram removidos.',
      'premium_main_description':
          'Remova todos os an\u00FAncios, elimine os tempos de espera e realize an\u00E1lises ilimitadas.',
      'premium_benefits_title': 'Benef\u00EDcios Premium',
      'premium_benefit_no_ads': 'An\u00FAncios completamente removidos.',
      'premium_benefit_fast':
          'Tempos de espera eliminados e velocidade aumentada.',
      'premium_benefit_unlimited':
          'An\u00E1lise ilimitada com acesso total a todos os recursos.',
      'remove_ads_and_limits_subtitle':
          'Remova an\u00FAncios e tempos de espera.',
      'restore_purchases': 'Restaurar compras',
      'restore_purchases_short': 'RESTAURAR',
      'restoring_purchases': 'Restaurando compras...',
      'restore_purchases_success': 'Compras restauradas Ã¢Å“â€¦',
      'restore_purchases_none': 'Nenhuma compra para restaurar.',
      'restore_purchases_failed': 'Falha na restauraÃƒÂ§ÃƒÂ£o: {err}',
      'next_analysis': 'PrÃƒÂ³xima anÃƒÂ¡lise',
      'next_analysis_ready': 'AnÃƒÂ¡lise disponÃƒÂ­vel agora.',
      'analysis_ready_risk':
          'A anÃƒÂ¡lise estÃƒÂ¡ disponÃƒÂ­vel, mas fazer anÃƒÂ¡lises em sequÃƒÂªncia pode aumentar o risco da conta.',
      'please_wait': 'Aguarde',
      'remaining_time': 'Tempo restante: {time}',
      'watch_ad': 'ASSISTIR AO ANÃƒÅ¡NCIO E INICIAR ANÃƒÂLISE',
      'start_analysis': 'INICIAR ANÃƒÂLISE',
      'start_analysis_question': 'Iniciar anÃƒÂ¡lise?',
      'clear_data_title': 'Redefinir dados do app',
      'clear_data_content':
          'Todos os dados locais e sessÃƒÂµes serÃƒÂ£o apagados. Tem certeza?',
      'cancel': 'CANCELAR',
      'delete': 'EXCLUIR',
      'ad_wait_message':
          'AnÃƒÂ¡lise concluÃƒÂ­da, os resultados serÃƒÂ£o mostrados apÃƒÂ³s o anÃƒÂºncio.',
      'analysis_failed_title': 'Falha na anÃƒÂ¡lise',
      'analysis_failed_reason': 'Motivo: {reason}',
      'analysis_failed_hint': 'Dica: sair e entrar novamente pode ajudar.',
      'story_section_title':
          'Veja stories em segredo ou amplie fotos de perfil',
      'story_login_required':
          'FaÃƒÂ§a login para ver stories anonimamente e ampliar fotos de perfil.',
      'story_ad_wait': 'SerÃƒÂ¡ exibido apÃƒÂ³s o anÃƒÂºncio. Aguarde.',
      'story_action_title': 'O que vocÃƒÂª deseja fazer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver story em segredo',
      'story_no_data': 'Nenhum dado de story encontrado.',
      'story_close': 'FECHAR',
      'no_data': 'Sem dados',
      'new_badge': 'NOVO',
      'login_title': 'Entrar',
      'read_and_agree': 'LI E CONCORDO',
      'withdraw_consent': 'Retirar consentimento',
      'withdraw_consent_confirm_title': 'ConfirmaÃƒÂ§ÃƒÂ£o',
      'withdraw_consent_confirm_body':
          'As configuraÃƒÂ§ÃƒÂµes de consentimento serÃƒÂ£o redefinidas. Continuar?',
      'withdraw_consent_confirm_yes': 'Sim',
      'withdraw_consent_confirm_no': 'Cancelar',
      'data_updated': 'AnÃƒÂ¡lise concluÃƒÂ­da Ã¢Å“â€¦',
      'enter_pin': 'Digite o PIN',
      'pin_accepted': 'PIN aceito, tempo reiniciado Ã¢Å“â€¦',
      'pin_incorrect': 'PIN invÃƒÂ¡lido',
      'ok': 'OK',
      'legal_warning': 'Aviso legal',
      'rate_us': 'Avalie-nos',
      'contact_us': 'Fale conosco',
      'remove_ads_and_limits': 'Remover an\u00FAncios e espera',
      'legal_intro':
          'Ao baixar e usar este aplicativo, o usuÃƒÂ¡rio declara que leu e aceitou os termos abaixo.',
      'user_label': 'Usu\u00E1rio',
    },
    'ar': {
      'tagline':
          'Ã˜Â­Ã™â€Ã™Ë†Ã™â€ Ã˜Â§Ã˜Â­Ã˜ÂªÃ˜Â±Ã˜Â§Ã™ÂÃ™Å Ã˜Â© Ã™â€Ã™Ë†Ã˜Â³Ã˜Â§Ã˜Â¦Ã™â€ Ã˜Â§Ã™â€Ã˜ÂªÃ™Ë†Ã˜Â§Ã˜ÂµÃ™â€ Ã˜Â§Ã™â€Ã˜Â§Ã˜Â¬Ã˜ÂªÃ™â€¦Ã˜Â§Ã˜Â¹Ã™Å ',
      'admin_active_note':
          'Ã™Ë†Ã˜Â¶Ã˜Â¹ Ã˜Â§Ã™â€Ã™â€¦Ã˜Â´Ã˜Â±Ã™Â Ã™â€¦Ã™ÂÃ˜Â¹Ã™â€˜Ã™â€',
      'free_app_note':
          'Ã™â€ Ã˜Â­Ã™â€  Ã™â€ Ã˜Â·Ã™Ë†Ã™â€˜Ã˜Â± Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â·Ã˜Â¨Ã™Å Ã™â€š Ã™Å Ã™Ë†Ã™â€¦Ã™Å Ã˜Â§Ã™â€¹ Ã™â€Ã˜ÂªÃ™â€šÃ˜Â¯Ã™Å Ã™â€¦ Ã˜ÂªÃ˜Â¬Ã˜Â±Ã˜Â¨Ã˜Â© Ã˜Â£Ã™ÂÃ˜Â¶Ã™â€. Ã™â€¦Ã™â€Ã˜Â§Ã˜Â­Ã˜Â¸Ã˜Â§Ã˜ÂªÃ™Æ’ Ã™â€¦Ã™â€¡Ã™â€¦Ã˜Â© Ã˜Â¬Ã˜Â¯Ã˜Â§Ã™â€¹ Ã™â€Ã™â€ Ã˜Â§.',
      'login_prompt':
          'Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¯Ã˜Â®Ã™Ë†Ã™â€ Ã™â€Ã˜Â¨Ã˜Â¯Ã˜Â¡ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€.',
      'welcome': 'Ã™â€¦Ã˜Â±Ã˜Â­Ã˜Â¨Ã˜Â§Ã™â€¹Ã˜Å’ {username}',
      'refresh_data': 'Ã˜ÂªÃ˜Â­Ã˜Â¯Ã™Å Ã˜Â« Ã˜Â§Ã™â€Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª',
      'login_with_instagram':
          'Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¯Ã˜Â®Ã™Ë†Ã™â€ Ã˜Â¹Ã˜Â¨Ã˜Â± Ã˜Â§Ã™â€ Ã˜Â³Ã˜ÂªÃ˜ÂºÃ˜Â±Ã˜Â§Ã™â€¦',
      'fetching_data':
          'Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Â Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª...\nÃ™â€šÃ˜Â¯ Ã™Å Ã˜Â³Ã˜ÂªÃ˜ÂºÃ˜Â±Ã™â€š Ã˜Â°Ã™â€Ã™Æ’ Ã˜Â¨Ã˜Â¹Ã˜Â¶ Ã˜Â§Ã™â€Ã™Ë†Ã™â€šÃ˜Âª.',
      'processing_data':
          'Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Â Ã™â€¦Ã˜Â¹Ã˜Â§Ã™â€Ã˜Â¬Ã˜Â© Ã˜Â§Ã™â€Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª...\nÃ˜Â¹Ã™â€Ã™â€° Ã™Ë†Ã˜Â´Ã™Æ’ Ã˜Â§Ã™â€Ã˜Â§Ã™â€ Ã˜ÂªÃ™â€¡Ã˜Â§Ã˜Â¡.',
      'loading_ad':
          'Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Â Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€ ...\nÃ™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â§Ã™â€Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¸Ã˜Â§Ã˜Â±.',
      'google_ad_warning':
          'Ã˜ÂªÃ˜Â­Ã˜Â°Ã™Å Ã˜Â± Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€  Google: {reason}',
      'analysis_secure':
          'Ã™Å Ã˜ÂªÃ™â€¦ Ã˜ÂªÃ™â€ Ã™ÂÃ™Å Ã˜Â° Ã˜Â¬Ã™â€¦Ã™Å Ã˜Â¹ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€Ã˜Â§Ã˜Âª Ã˜Â¨Ã˜Â´Ã™Æ’Ã™â€ Ã˜Â¢Ã™â€¦Ã™â€  Ã™â€¦Ã˜Â­Ã™â€Ã™Å Ã˜Â§Ã™â€¹ Ã˜Â¹Ã™â€Ã™â€° Ã˜Â¬Ã™â€¡Ã˜Â§Ã˜Â²Ã™Æ’.',
      'today_total_analysis':
          'Ã˜Â¥Ã˜Â¬Ã™â€¦Ã˜Â§Ã™â€Ã™Å  Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™Å Ã™Ë†Ã™â€¦: {count}',
      'purchases_not_configured':
          'Ã˜Â§Ã™â€Ã˜Â´Ã˜Â±Ã˜Â§Ã˜Â¡ Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â­ Ã˜Â­Ã˜Â§Ã™â€Ã™Å Ã˜Â§Ã™â€¹. Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â§Ã™â€Ã™â€¦Ã˜Â­Ã˜Â§Ã™Ë†Ã™â€Ã˜Â© Ã™â€Ã˜Â§Ã˜Â­Ã™â€šÃ˜Â§Ã™â€¹.',
      'premium_already_active':
          'Ã˜Â¹Ã˜Â¶Ã™Ë†Ã™Å Ã˜Â© Premium Ã™â€¦Ã™ÂÃ˜Â¹Ã™â€Ã˜Â© Ã™â€Ã˜Â¯Ã™Å Ã™Æ’.',
      'premium_welcome_box':
          'Ã™â€¦Ã˜Â±Ã˜Â­Ã˜Â¨Ã˜Â§Ã™â€¹ Ã˜Â¨Ã™Æ’ Ã™ÂÃ™Å  Premium! Ã˜ÂªÃ™â€¦Ã˜Âª Ã˜Â¥Ã˜Â²Ã˜Â§Ã™â€Ã˜Â© Ã˜Â§Ã™â€Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã™Ë†Ã™ÂÃ˜ÂªÃ˜Â±Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¸Ã˜Â§Ã˜Â±.',
      'premium_benefits_title': 'مزايا بريميوم',
      'remove_ads_and_limits_subtitle': 'إزالة الإعلانات وأوقات الانتظار.',
      'premium_main_description':
          'قم بإزالة جميع الإعلانات، وإلغاء أوقات الانتظار، وإجراء تحليل غير محدود.',
      'premium_benefit_no_ads': 'تمت إزالة الإعلانات بالكامل.',
      'premium_benefit_fast': 'تم إلغاء أوقات الانتظار وزيادة السرعة.',
      'premium_benefit_unlimited':
          'تحليل غير محدود مع وصول كامل لجميع الميزات.',
      'restore_purchases':
          'Ã˜Â§Ã˜Â³Ã˜ÂªÃ˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€Ã™â€¦Ã˜Â´Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â§Ã˜Âª',
      'restore_purchases_short': '\u0627\u0633\u062A\u0639\u0627\u062F\u0629',
      'restoring_purchases':
          'Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Â Ã˜Â§Ã˜Â³Ã˜ÂªÃ˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€Ã™â€¦Ã˜Â´Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â§Ã˜Âª...',
      'restore_purchases_success':
          'Ã˜ÂªÃ™â€¦Ã˜Âª Ã˜Â§Ã˜Â³Ã˜ÂªÃ˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€Ã™â€¦Ã˜Â´Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â§Ã˜Âª Ã¢Å“â€¦',
      'restore_purchases_none':
          'Ã™â€Ã˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã™â€¦Ã˜Â´Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â§Ã˜Âª Ã™â€Ã™â€Ã˜Â§Ã˜Â³Ã˜ÂªÃ˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â©.',
      'restore_purchases_failed':
          'Ã™ÂÃ˜Â´Ã™â€Ã˜Âª Ã˜Â§Ã™â€Ã˜Â§Ã˜Â³Ã˜ÂªÃ˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â©: {err}',
      'next_analysis':
          'Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â§Ã™â€Ã™Å ',
      'next_analysis_ready':
          'Ã™Å Ã™â€¦Ã™Æ’Ã™â€ Ã™Æ’ Ã˜Â¥Ã˜Â¬Ã˜Â±Ã˜Â§Ã˜Â¡ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¢Ã™â€ .',
      'analysis_ready_risk':
          'Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€ Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â­ Ã˜Â§Ã™â€Ã˜Â¢Ã™â€ Ã˜Å’ Ã™â€Ã™Æ’Ã™â€  Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã™â€¦Ã˜ÂªÃ™Æ’Ã˜Â±Ã˜Â± Ã™â€šÃ˜Â¯ Ã™Å Ã˜Â¹Ã˜Â±Ã™â€˜Ã˜Â¶ Ã˜Â­Ã˜Â³Ã˜Â§Ã˜Â¨Ã™Æ’ Ã™â€Ã™â€Ã˜Â®Ã˜Â·Ã˜Â±.',
      'please_wait': 'Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â§Ã™â€Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¸Ã˜Â§Ã˜Â±',
      'remaining_time':
          'Ã˜Â§Ã™â€Ã™Ë†Ã™â€šÃ˜Âª Ã˜Â§Ã™â€Ã™â€¦Ã˜ÂªÃ˜Â¨Ã™â€šÃ™Å : {time}',
      'watch_ad':
          'Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯ Ã˜Â§Ã™â€Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€  Ã™Ë†Ã˜Â§Ã˜Â¨Ã˜Â¯Ã˜Â£ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€',
      'start_analysis': 'Ã˜Â§Ã˜Â¨Ã˜Â¯Ã˜Â£ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€',
      'start_analysis_question':
          'Ã™â€¡Ã™â€ Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â¯ Ã˜Â¨Ã˜Â¯Ã˜Â¡ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€Ã˜Å¸',
      'clear_data_title':
          'Ã˜Â¥Ã˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜ÂªÃ˜Â¹Ã™Å Ã™Å Ã™â€  Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â·Ã˜Â¨Ã™Å Ã™â€š',
      'clear_data_content':
          'Ã˜Â³Ã™Å Ã˜ÂªÃ™â€¦ Ã˜Â­Ã˜Â°Ã™Â Ã˜Â¬Ã™â€¦Ã™Å Ã˜Â¹ Ã˜Â§Ã™â€Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™â€¦Ã˜Â­Ã™â€Ã™Å Ã˜Â© Ã™Ë†Ã™â€¦Ã˜Â¹Ã™â€Ã™Ë†Ã™â€¦Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã˜Â¬Ã™â€Ã˜Â³Ã˜Â©. Ã™â€¡Ã™â€ Ã˜Â£Ã™â€ Ã˜Âª Ã™â€¦Ã˜ÂªÃ˜Â£Ã™Æ’Ã˜Â¯Ã˜Å¸',
      'cancel': 'Ã˜Â¥Ã™â€Ã˜ÂºÃ˜Â§Ã˜Â¡',
      'delete': 'ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â',
      'ad_wait_message':
          'Ã˜Â§Ã™Æ’Ã˜ÂªÃ™â€¦Ã™â€ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€Ã˜Å’ Ã™Ë†Ã˜Â³Ã™Å Ã˜ÂªÃ™â€¦ Ã˜Â¹Ã˜Â±Ã˜Â¶ Ã˜Â§Ã™â€Ã™â€ Ã˜ÂªÃ˜Â§Ã˜Â¦Ã˜Â¬ Ã˜Â¨Ã˜Â¹Ã˜Â¯ Ã˜Â§Ã™â€Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€ .',
      'analysis_failed_title': 'Ã™ÂÃ˜Â´Ã™â€ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€',
      'analysis_failed_reason': 'Ã˜Â§Ã™â€Ã˜Â³Ã˜Â¨Ã˜Â¨: {reason}',
      'analysis_failed_hint':
          'Ã™â€ Ã˜ÂµÃ™Å Ã˜Â­Ã˜Â©: Ã™â€šÃ˜Â¯ Ã™Å Ã™ÂÃ™Å Ã˜Â¯ Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â®Ã˜Â±Ã™Ë†Ã˜Â¬ Ã˜Â«Ã™â€¦ Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¯Ã˜Â®Ã™Ë†Ã™â€ Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°.',
      'story_section_title':
          'Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯ Ã˜Â§Ã™â€Ã™â€šÃ˜ÂµÃ˜Âµ Ã˜Â¨Ã˜Â´Ã™Æ’Ã™â€ Ã™â€¦Ã˜Â®Ã™ÂÃ™Å  Ã˜Â£Ã™Ë† Ã™Æ’Ã˜Â¨Ã™â€˜Ã˜Â± Ã˜ÂµÃ™Ë†Ã˜Â± Ã˜Â§Ã™â€Ã™â€¦Ã™â€Ã™Â Ã˜Â§Ã™â€Ã˜Â´Ã˜Â®Ã˜ÂµÃ™Å ',
      'story_login_required':
          'Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¯Ã˜Â®Ã™Ë†Ã™â€ Ã™â€Ã™â€¦Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€Ã™â€šÃ˜ÂµÃ˜Âµ Ã˜Â¨Ã˜Â´Ã™Æ’Ã™â€ Ã˜Â³Ã˜Â±Ã™Å  Ã™Ë†Ã˜ÂªÃ™Æ’Ã˜Â¨Ã™Å Ã˜Â± Ã˜ÂµÃ™Ë†Ã˜Â± Ã˜Â§Ã™â€Ã™â€¦Ã™â€Ã™Â Ã˜Â§Ã™â€Ã˜Â´Ã˜Â®Ã˜ÂµÃ™Å .',
      'story_ad_wait':
          'Ã˜Â³Ã™Å Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€Ã˜Â¹Ã˜Â±Ã˜Â¶ Ã˜Â¨Ã˜Â¹Ã˜Â¯ Ã˜Â§Ã™â€Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€ Ã˜Å’ Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â§Ã™â€Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¸Ã˜Â§Ã˜Â±.',
      'story_action_title':
          'Ã™â€¦Ã˜Â§Ã˜Â°Ã˜Â§ Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â¯ Ã˜Â£Ã™â€  Ã˜ÂªÃ™ÂÃ˜Â¹Ã™â€Ã˜Å¸',
      'story_view_photo':
          'Ã˜ÂªÃ™Æ’Ã˜Â¨Ã™Å Ã˜Â± Ã˜ÂµÃ™Ë†Ã˜Â±Ã˜Â© Ã˜Â§Ã™â€Ã™â€¦Ã™â€Ã™Â Ã˜Â§Ã™â€Ã˜Â´Ã˜Â®Ã˜ÂµÃ™Å ',
      'story_watch_secret':
          'Ã™â€¦Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€Ã™â€šÃ˜ÂµÃ˜Â© Ã˜Â¨Ã˜Â´Ã™Æ’Ã™â€ Ã™â€¦Ã˜Â®Ã™ÂÃ™Å ',
      'story_no_data':
          'Ã™â€Ã˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã™â€Ã™â€Ã™â€šÃ˜ÂµÃ˜Âµ.',
      'story_close': 'Ã˜Â¥Ã˜ÂºÃ™â€Ã˜Â§Ã™â€š',
      'no_data':
          '\u0644\u0627 \u062A\u0648\u062C\u062F \u0628\u064A\u0627\u0646\u0627\u062A',
      'new_badge': '\u062C\u062F\u064A\u062F',
      'login_title':
          '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644',
      'read_and_agree':
          'Ã™â€Ã™â€šÃ˜Â¯ Ã™â€šÃ˜Â±Ã˜Â£Ã˜Âª Ã™Ë†Ã˜Â£Ã™Ë†Ã˜Â§Ã™ÂÃ™â€š',
      'withdraw_consent': 'Ã˜Â³Ã˜Â­Ã˜Â¨ Ã˜Â§Ã™â€Ã™â€¦Ã™Ë†Ã˜Â§Ã™ÂÃ™â€šÃ˜Â©',
      'withdraw_consent_confirm_title': 'Ã˜ÂªÃ˜Â£Ã™Æ’Ã™Å Ã˜Â¯',
      'withdraw_consent_confirm_body':
          'Ã˜Â³Ã™Å Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜ÂªÃ˜Â¹Ã™Å Ã™Å Ã™â€  Ã˜Â¥Ã˜Â¹Ã˜Â¯Ã˜Â§Ã˜Â¯Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™â€¦Ã™Ë†Ã˜Â§Ã™ÂÃ™â€šÃ˜Â©. Ã™â€¡Ã™â€ Ã˜Â£Ã™â€ Ã˜Âª Ã™â€¦Ã˜ÂªÃ˜Â£Ã™Æ’Ã˜Â¯Ã˜Å¸',
      'withdraw_consent_confirm_yes': 'Ã™â€ Ã˜Â¹Ã™â€¦',
      'withdraw_consent_confirm_no': 'Ã˜Â¥Ã™â€Ã˜ÂºÃ˜Â§Ã˜Â¡',
      'data_updated':
          'Ã˜Â§Ã™Æ’Ã˜ÂªÃ™â€¦Ã™â€ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€ Ã¢Å“â€¦',
      'enter_pin': 'Ã˜Â£Ã˜Â¯Ã˜Â®Ã™â€ PIN',
      'pin_accepted':
          'Ã˜ÂªÃ™â€¦ Ã™â€šÃ˜Â¨Ã™Ë†Ã™â€ PIN Ã™Ë†Ã˜Â¥Ã˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜ÂªÃ˜Â¹Ã™Å Ã™Å Ã™â€  Ã˜Â§Ã™â€Ã™Ë†Ã™â€šÃ˜Âª Ã¢Å“â€¦',
      'pin_incorrect': 'PIN Ã˜ÂºÃ™Å Ã˜Â± Ã˜ÂµÃ˜Â­Ã™Å Ã˜Â­',
      'ok': 'Ã™â€¦Ã™Ë†Ã˜Â§Ã™ÂÃ™â€š',
      'legal_warning': 'Ã˜ÂªÃ™â€ Ã˜Â¨Ã™Å Ã™â€¡ Ã™â€šÃ˜Â§Ã™â€ Ã™Ë†Ã™â€ Ã™Å ',
      'rate_us': '\u0642\u064A\u0645\u0646\u0627',
      'contact_us': '\u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u0646\u0627',
      'remove_ads_and_limits':
          '\u0625\u0632\u0627\u0644\u0629 \u0627\u0644\u0625\u0639\u0644\u0627\u0646\u0627\u062A \u0648\u0641\u062A\u0631\u0627\u062A \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631',
      'legal_intro':
          'Ã˜Â¨Ã˜ÂªÃ™â€ Ã˜Â²Ã™Å Ã™â€ Ã™â€¡Ã˜Â°Ã˜Â§ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â·Ã˜Â¨Ã™Å Ã™â€š Ã™Ë†Ã˜Â§Ã˜Â³Ã˜ÂªÃ˜Â®Ã˜Â¯Ã˜Â§Ã™â€¦Ã™â€¡Ã˜Å’ Ã™Å Ã™ÂÃ˜Â¹Ã˜ÂªÃ˜Â¨Ã˜Â± Ã˜Â§Ã™â€Ã™â€¦Ã˜Â³Ã˜ÂªÃ˜Â®Ã˜Â¯Ã™â€¦ Ã™â€šÃ˜Â¯ Ã™â€šÃ˜Â±Ã˜Â£ Ã™Ë†Ã™Ë†Ã˜Â§Ã™ÂÃ™â€š Ã˜Â¹Ã™â€Ã™â€° Ã˜Â§Ã™â€Ã˜Â´Ã˜Â±Ã™Ë†Ã˜Â· Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â§Ã™â€Ã™Å Ã˜Â©.',
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
      "remove_ads_and_limits": "Eliminar anuncios y tiempos de espera",
      "remove_ads_and_limits_subtitle": "Elimina anuncios y tiempos de espera.",
      "premium_benefits_title": "Beneficios Premium",
      "premium_main_description":
          "Elimine todos los anuncios, elimine los tiempos de espera y realice an\u00E1lisis ilimitados.",
      "premium_benefit_no_ads": "Anuncios completamente eliminados.",
      "premium_benefit_fast":
          "Tiempos de espera eliminados y velocidad aumentada.",
      "premium_benefit_unlimited":
          "An\u00E1lisis ilimitado con acceso total a todas las funciones.",
      "rate_test_message": "Este cuadro est\u00e1 actualmente bajo prueba.",
      "story_section_title":
          "Ver historias en secreto o hacer zoom en las fotos del perfil",
      "story_login_required":
          "Inicia sesiÃƒÂ³n para ver historias en modo anÃƒÂ³nimo y ampliar fotos de perfil.",
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
      'left_following': 'Usuarios que dejaste de seguir',
      "rate_us": "Calif\u00edcanos",
      "contact_us": "Cont\u00e1ctenos",
      "remove_ads_and_limits": "Eliminar anuncios y tiempos de espera",
      "remove_ads_and_limits_subtitle": "Elimina anuncios y tiempos de espera.",
      "premium_benefits_title": "Beneficios Premium",
      "premium_main_description":
          "Elimine todos los anuncios, elimine los tiempos de espera y realice an\u00E1lisis ilimitados.",
      "premium_benefit_no_ads": "Anuncios completamente eliminados.",
      "premium_benefit_fast":
          "Tiempos de espera eliminados y velocidad aumentada.",
      "premium_benefit_unlimited":
          "An\u00E1lisis ilimitado con acceso total a todas las funciones.",
      "rate_test_message": "Este cuadro est\u00e1 actualmente bajo prueba.",
      "story_section_title":
          "Ver historias en secreto o hacer zoom en las fotos del perfil",
      "story_login_required":
          "Inicia sesiÃƒÂ³n para ver historias en modo anÃƒÂ³nimo y ampliar fotos de perfil.",
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
      "adsense_banner":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0938\u094d\u0925\u093e\u0928",
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
      "following":
          "\u095e\u093c\u0949\u0932\u094b \u0915\u093f\u090f \u0917\u090f",
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
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0914\u0930 \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f \u0939\u091f\u093e\u090f\u0901",
      "remove_ads_and_limits_subtitle":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0914\u0930 \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f \u0939\u091f\u093e\u090f\u0901\u0964",
      "premium_benefits_title":
          "\u092a\u094d\u0930\u0940\u092e\u093f\u092f\u092e \u0932\u093e\u092d",
      "premium_main_description":
          "\u0938\u092d\u0940 \u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0939\u091f\u093e\u090f\u0901, \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f \u0938\u092e\u093e\u092a\u094d\u0924 \u0915\u0930\u0947\u0902 \u0914\u0930 \u0905\u0938\u0940\u092e\u093f\u0924 \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923 \u0915\u0930\u0947\u0902\u0964",
      "premium_benefit_no_ads":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u092a\u0942\u0930\u0940 \u0924\u0930\u0939 \u0938\u0947 \u0939\u091f\u093e \u0926\u093f\u090f \u0917\u090f\u0964",
      "premium_benefit_fast":
          "\u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f \u0938\u092e\u093e\u092a\u094d\u0924 \u0914\u0930 \u0917\u0924\u093f \u092c\u0922\u093c \u0917\u0908\u0964",
      "premium_benefit_unlimited":
          "\u0938\u092d\u0940 \u0938\u0941\u0935\u093f\u0927\u093e\u0913\u0902 \u0924\u0915 \u092a\u0942\u0930\u094d\u0923 \u092a\u0939\u0941\u0901\u091a \u0915\u0947 \u0938\u093e\u0925 \u0905\u0938\u0940\u092e\u093f\u0924 \u0935\u093f\u0936\u094d\u0932\u0947\u0937\u0923\u0964",
      "rate_test_message":
          "\u092f\u0939 \u092c\u0949\u0915\u094d\u0938 \u0905\u092d\u0940 \u092a\u0930\u0940\u0915\u094d\u0937\u0923\u093e\u0927\u0940\u0928 \u0939\u0948\u0964",
      "story_section_title":
          "\u0917\u0941\u092a\u094d\u0924 \u0930\u0942\u092a \u0938\u0947 \u0915\u0939\u093e\u0928\u093f\u092f\u093e\u0902 \u0926\u0947\u0916\u0947\u0902 \u092f\u093e \u092a\u094d\u0930\u094b\u092b\u093c\u093e\u0907\u0932 \u092b\u093c\u094b\u091f\u094b \u091c\u093c\u0942\u092e \u0915\u0930\u0947\u0902",
      "story_login_required":
          "Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤â€¢Ã Â¥â€¹ Ã Â¤â€”Ã Â¥ÂÃ Â¤ÂªÃ Â¥ÂÃ Â¤Â¤ Ã Â¤Â°Ã Â¥â€šÃ Â¤Âª Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€Ã Â¤Â° Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹ Ã Â¤Â¬Ã Â¤Â¡Ã Â¤Â¼Ã Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤â€¢Ã Â¥Æ’Ã Â¤ÂªÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€°Ã Â¤â€”Ã Â¤Â¿Ã Â¤Â¨ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤",
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
      'user_label':
          '\u0909\u092A\u092F\u094B\u0917\u0915\u0930\u094D\u0924\u093E',
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
          "Hirdet\u00e9sek \u00e9s v\u00e1rakoz\u00e1si id\u0151k elt\u00e1vol\u00edt\u00e1sa",
      "remove_ads_and_limits_subtitle":
          "Hirdet\u00e9sek \u00e9s v\u00e1rakoz\u00e1si id\u0151k elt\u00e1vol\u00edt\u00e1sa.",
      "premium_benefits_title": "Pr\u00e9mium el\u0151ny\u00f6k",
      "premium_main_description":
          "T\u00e1vol\u00edtsa el az \u00f6sszes hirdet\u00e9st, sz\u00fcntesse meg a v\u00e1rakoz\u00e1si id\u0151ket \u00e9s v\u00e9gezzen korl\u00e1tlan elemz\u00e9st.",
      "premium_benefit_no_ads":
          "Hirdet\u00e9sek teljesen elt\u00e1vol\u00edtva.",
      "premium_benefit_fast":
          "V\u00e1rakoz\u00e1si id\u0151k megsz\u00fcntetve \u00e9s sebess\u00e9g n\u00f6velve.",
      "premium_benefit_unlimited":
          "Korl\u00e1tlan elemz\u00e9s teljes hozz\u00e1f\u00e9r\u00e9ssel minden funkci\u00f3hoz.",
      "rate_test_message": "Ez a doboz jelenleg tesztel\u00e9s alatt \u00e1ll.",
      "story_section_title":
          "N\u00e9zze meg a t\u00f6rt\u00e9neteket titokban vagy nagy\u00edtsa ki a profilfot\u00f3kat",
      "story_login_required":
          "KÃƒÂ©rjÃƒÂ¼k, jelentkezz be a tÃƒÂ¶rtÃƒÂ©netek nÃƒÂ©vtelen megtekintÃƒÂ©sÃƒÂ©hez ÃƒÂ©s a profilkÃƒÂ©pek nagyÃƒÂ­tÃƒÂ¡sÃƒÂ¡hoz.",
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
          "\u79fb\u9664\u5e7f\u544a\u548c\u7b49\u5f85\u65f6\u95f4",
      "remove_ads_and_limits_subtitle":
          "\u79fb\u9664\u5e7f\u544a\u548c\u7b49\u5f85\u65f6\u95f4\u3002",
      "premium_benefits_title": "Premium \u6743\u76ca",
      "premium_main_description":
          "\u79fb\u9664\u6240\u6709\u5e7f\u544a\uff0c\u6d88\u9664\u7b49\u5f85\u65f6\u95f4\uff0c\u5e76\u8fdb\u884c\u65e0\u9650\u6b21\u5206\u6790\u3002",
      "premium_benefit_no_ads":
          "\u5e7f\u544a\u5df2\u5b8c\u5168\u79fb\u9664\u3002",
      "premium_benefit_fast":
          "\u6d88\u9664\u7b49\u5f85\u65f6\u95f4\u5e76\u63d0\u5347\u901f\u5ea6\u3002",
      "premium_benefit_unlimited":
          "\u65e0\u9650\u6b21\u5206\u6790\uff0c\u5b8c\u5168\u8bbf\u95ee\u6240\u6709\u529f\u80fd\u3002",
      "rate_test_message":
          "\u8fd9\u4e2a\u76d2\u5b50\u76ee\u524d\u6b63\u5728\u6d4b\u8bd5\u4e2d\u3002",
      "story_section_title":
          "\u79d8\u5bc6\u89c2\u770b\u6545\u4e8b\u6216\u7f29\u653e\u4e2a\u4eba\u8d44\u6599\u7167\u7247",
      "story_login_required":
          "Ã¨Â¯Â·Ã§â„¢Â»Ã¥Â½â€¢Ã¤Â»Â¥Ã¥Å’Â¿Ã¥ÂÂÃ¦Å¸Â¥Ã§Å“â€¹Ã¥Å Â¨Ã¦â‚¬ÂÃ¥Â¹Â¶Ã¦â€Â¾Ã¥Â¤Â§Ã¥Â¤Â´Ã¥Æ’ÂÃ§â€¦Â§Ã§â€°â€¡Ã£â‚¬â€š",
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
      "remove_ads_and_limits": "Hapus Iklan & Waktu Tunggu",
      "remove_ads_and_limits_subtitle": "Hapus iklan dan waktu tunggu.",
      "premium_benefits_title": "Manfaat Premium",
      "premium_main_description":
          "Hapus semua iklan, hilangkan waktu tunggu, dan lakukan analisis tanpa batas.",
      "premium_benefit_no_ads": "Iklan sepenuhnya dihapus.",
      "premium_benefit_fast":
          "Waktu tunggu dihilangkan dan kecepatan ditingkatkan.",
      "premium_benefit_unlimited":
          "Analisis tanpa batas dengan akses penuh ke semua fitur.",
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
      "rate_test_message": "Kotak ini sedang diuji.",
      "story_section_title":
          "Tonton Cerita Secara Diam-diam atau Zoom Foto Profil",
      "story_login_required":
          "Silakan masuk untuk melihat story secara anonim dan memperbesar foto profil.",
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
      "remove_ads_and_limits": "Verwijder advertenties en wachttijden",
      "remove_ads_and_limits_subtitle":
          "Verwijder advertenties en wachttijden.",
      "premium_benefits_title": "Premium voordelen",
      "premium_main_description":
          "Verwijder alle advertenties, elimineer wachttijden en voer onbeperkte analyses uit.",
      "premium_benefit_no_ads": "Advertenties volledig verwijderd.",
      "premium_benefit_fast":
          "Wachttijden ge\u00eblimineerd en snelheid verhoogd.",
      "premium_benefit_unlimited":
          "Onbeperkte analyse met volledige toegang tot alle functies.",
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
      "rate_test_message": "Deze box wordt momenteel getest.",
      "story_section_title":
          "Bekijk verhalen in het geheim of zoom in op profielfoto's",
      "story_login_required":
          "Log in om stories anoniem te bekijken en profielfoto's te vergroten.",
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
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0914\u0930 \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f \u0939\u091f\u093e\u090f\u0901",
      "remove_ads_and_limits_subtitle":
          "\u0935\u093f\u091c\u094d\u091e\u093e\u092a\u0928 \u0914\u0930 \u092a\u094d\u0930\u0924\u0940\u0915\u094d\u0937\u093e \u0938\u092e\u092f \u0939\u091f\u093e\u090f\u0901\u3002",
      "premium_benefits_title": "Avantages Premium",
      "premium_main_description":
          "Supprimez toutes les publicit\u00e9s, \u00e9liminez les attentes et effectuez des analyses illimit\u00e9es.",
      "premium_benefit_no_ads":
          "Publicit\u00e9s enti\u00e8rement supprim\u00e9es.",
      "premium_benefit_fast":
          "Temps d'attente \u00e9limin\u00e9s et vitesse augment\u00e9e.",
      "premium_benefit_unlimited":
          "Analyse illimit\u00e9e avec acc\u00e8s complet \u00e0 toutes les fonctions.",
      "rate_test_message": "Cette box est actuellement en test.",
      "story_section_title":
          "Regardez des histoires en secret ou zoomez sur les photos de profil",
      "story_login_required":
          "Connectez-vous pour voir les stories en mode anonyme et agrandir les photos de profil.",
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
      "remove_ads_and_limits": "Rimuovi pubblicit\u00e0 e tempi di attesa",
      "remove_ads_and_limits_subtitle":
          "Rimuovi pubblicit\u00e0 e tempi di attesa.",
      "premium_benefits_title": "Vantaggi Premium",
      "premium_main_description":
          "Rimuovi tutti gli annunci, elimina i tempi di attesa ed esegui analisi illimitate.",
      "premium_benefit_no_ads": "Annunci completamente rimossi.",
      "premium_benefit_fast":
          "Tempi di attesa eliminati e velocit\u00e0 aumentata.",
      "premium_benefit_unlimited":
          "Analisi illimitata con accesso completo a tutte le funzioni.",
      "rate_test_message": "Questa scatola \u00e8 attualmente in fase di test.",
      "story_section_title":
          "Guarda le storie di nascosto o ingrandisci le foto del profilo",
      "story_login_required":
          "Accedi per vedere le storie in modo anonimo e ingrandire le foto profilo.",
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
      "analysis_available_now":
          "Ph\u00e2n t\u00edch hi\u1ec7n c\u00f3 s\u1eb5n",
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
          "Lo\u1ea1i b\u1ecf qu\u1ea3ng c\u00e1o v\u00e0 th\u1eddi gian ch\u1edd",
      "remove_ads_and_limits_subtitle":
          "Lo\u1ea1i b\u1ecf qu\u1ea3ng c\u00e1o v\u00e0 th\u1eddi gian ch\u1edd.",
      "premium_benefits_title": "L\u1ee3i \u00edch Premium",
      "premium_main_description":
          "X\u00f3a t\u1ea5t c\u1ea3 qu\u1ea3ng c\u00e1o, lo\u1ea1i b\u1ecf th\u1eddi gian ch\u1edd v\u00e0 th\u1ef1c hi\u1ec7n ph\u00e2n t\u00edch kh\u00f4ng gi\u1edbi h\u1ea1n.",
      "premium_benefit_no_ads":
          "Qu\u1ea3ng c\u00e1o \u0111\u00e3 \u0111\u01b0\u1ee3c g\u1ee1 b\u1ecf ho\u00e0n to\u00e0n.",
      "premium_benefit_fast":
          "Th\u1eddi gian ch\u1edd \u0111\u01b0\u1ee3c lo\u1ea1i b\u1ecf v\u00e0 t\u1ed1c \u0111\u1ed9 t\u0103ng l\u00ean.",
      "premium_benefit_unlimited":
          "Ph\u00e2n t\u00edch kh\u00f4ng gi\u1edbi h\u1ea1n v\u1edbi quy\u1ec1n truy c\u1eadp \u0111\u1ea7y \u0111\u1ee7 v\u00e0o t\u1ea5t c\u1ea3 c\u00e1c t\u00ednh n\u0103ng.",
      "rate_test_message":
          "H\u1ed9p n\u00e0y hi\u1ec7n \u0111ang \u0111\u01b0\u1ee3c th\u1eed nghi\u1ec7m.",
      "story_section_title":
          "Xem c\u00e2u chuy\u1ec7n m\u1ed9t c\u00e1ch b\u00ed m\u1eadt ho\u1eb7c thu ph\u00f3ng \u1ea3nh h\u1ed3 s\u01a1",
      "story_login_required":
          "Vui lÃƒÂ²ng Ã„â€˜Ã„Æ’ng nhÃ¡ÂºÂ­p Ã„â€˜Ã¡Â»Æ’ xem story Ã¡ÂºÂ©n danh vÃƒÂ  phÃƒÂ³ng to Ã¡ÂºÂ£nh hÃ¡Â»â€œ sÃ†Â¡.",
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
      "analysis_ready_risk":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e1e\u0e23\u0e49\u0e2d\u0e21\u0e43\u0e0a\u0e49\u0e07\u0e32\u0e19\u0e41\u0e25\u0e49\u0e27 \u0e41\u0e15\u0e48\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e15\u0e34\u0e14\u0e15\u0e48\u0e2d\u0e01\u0e31\u0e19\u0e2d\u0e32\u0e08\u0e40\u0e1e\u0e34\u0e48\u0e21\u0e04\u0e27\u0e32\u0e21\u0e40\u0e2a\u0e35\u0e48\u0e22\u0e07\u0e43\u0e2b\u0e49\u0e1a\u0e31\u0e0d\u0e0a\u0e35\u0e02\u0e2d\u0e07\u0e04\u0e38\u0e13",
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
      "contact_us": "\u0e15\u0e34\u0e14\u0e15\u0e48\u0e2d\u0e40\u0e23\u0e32",
      "remove_ads_and_limits":
          "\u0e25\u0e1a\u0e42\u0e06\u0e29\u0e13\u0e32\u0e41\u0e25\u0e30\u0e40\u0e27\u0e25\u0e32\u0e23\u0e2d",
      "remove_ads_and_limits_subtitle":
          "\u0e25\u0e1a\u0e42\u0e06\u0e29\u0e13\u0e32\u0e41\u0e25\u0e30\u0e40\u0e27\u0e25\u0e32\u0e23\u0e2d.",
      "premium_benefits_title":
          "\u0e2a\u0e34\u0e17\u0e18\u0e34\u0e1b\u0e23\u0e30\u0e42\u0e22\u0e0a\u0e19\u0e4c\u0e23\u0e30\u0e14\u0e31\u0e1a\u0e1e\u0e23\u0e35\u0e40\u0e21\u0e35\u0e22\u0e21",
      "premium_main_description":
          "\u0e25\u0e1a\u0e42\u0e06\u0e29\u0e13\u0e32\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14 \u0e01\u0e33\u0e08\u0e31\u0e14\u0e40\u0e27\u0e25\u0e32\u0e23\u0e2d \u0e41\u0e25\u0e30\u0e17\u0e33\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e41\u0e1a\u0e1a\u0e44\u0e21\u0e48\u0e08\u0e33\u0e01\u0e31\u0e14",
      "premium_benefit_no_ads":
          "\u0e42\u0e06\u0e29\u0e13\u0e32\u0e16\u0e39\u0e01\u0e25\u0e1a\u0e2d\u0e2d\u0e01\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14.",
      "premium_benefit_fast":
          "\u0e01\u0e33\u0e08\u0e31\u0e14\u0e40\u0e27\u0e25\u0e32\u0e23\u0e2d\u0e41\u0e25\u0e30\u0e40\u0e1e\u0e34\u0e48\u0e21\u0e04\u0e27\u0e32\u0e21\u0e40\u0e23\u0e47\u0e27.",
      "premium_benefit_unlimited":
          "\u0e01\u0e32\u0e23\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e44\u0e21\u0e48\u0e08\u0e33\u0e01\u0e31\u0e14\u0e1e\u0e23\u0e49\u0e2d\u0e21\u0e01\u0e32\u0e23\u0e40\u0e02\u0e49\u0e32\u0e16\u0e36\u0e07\u0e17\u0e38\u0e01\u0e1f\u0e35\u0e40\u0e08\u0e2d\u0e23\u0e4c\u0e2d\u0e22\u0e48\u0e32\u0e07\u0e40\u0e15\u0e47\u0e21\u0e1a\u0e38\u0e1b\u0e41\u0e1a\u0e1a.",
      "rate_test_message":
          "\u0e01\u0e25\u0e48\u0e2d\u0e07\u0e19\u0e35\u0e49\u0e2d\u0e22\u0e39\u0e48\u0e23\u0e30\u0e2b\u0e27\u0e48\u0e32\u0e07\u0e01\u0e32\u0e23\u0e17\u0e14\u0e2a\u0e2d\u0e1a",
      "story_section_title":
          "\u0e14\u0e39\u0e40\u0e23\u0e37\u0e48\u0e2d\u0e07\u0e25\u0e31\u0e1a\u0e2b\u0e23\u0e37\u0e2d\u0e0b\u0e39\u0e21\u0e23\u0e39\u0e1b\u0e42\u0e1b\u0e23\u0e44\u0e1f\u0e25\u0e4c",
      "story_login_required":
          "Ã Â¹â€šÃ Â¸â€ºÃ Â¸Â£Ã Â¸â€Ã Â¹â‚¬Ã Â¸â€šÃ Â¹â€°Ã Â¸Â²Ã Â¸ÂªÃ Â¸Â¹Ã Â¹Ë†Ã Â¸Â£Ã Â¸Â°Ã Â¸Å¡Ã Â¸Å¡Ã Â¹â‚¬Ã Â¸ÂÃ Â¸Â·Ã Â¹Ë†Ã Â¸Â­Ã Â¸â€Ã Â¸Â¹Ã Â¸ÂªÃ Â¸â€¢Ã Â¸Â­Ã Â¸Â£Ã Â¸ÂµÃ Â¹ÂÃ Â¸Å¡Ã Â¸Å¡Ã Â¹â€Ã Â¸Â¡Ã Â¹Ë†Ã Â¸Â£Ã Â¸Â°Ã Â¸Å¡Ã Â¸Â¸Ã Â¸â€¢Ã Â¸Â±Ã Â¸Â§Ã Â¸â€¢Ã Â¸â„¢Ã Â¹ÂÃ Â¸Â¥Ã Â¸Â°Ã Â¸â€šÃ Â¸Â¢Ã Â¸Â²Ã Â¸Â¢Ã Â¸Â£Ã Â¸Â¹Ã Â¸â€ºÃ Â¹â€šÃ Â¸â€ºÃ Â¸Â£Ã Â¹â€Ã Â¸Å¸Ã Â¸Â¥Ã Â¹Å’",
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
      "remove_ads_and_limits": "Usu\u0144 reklamy i czasy oczekiwania",
      "remove_ads_and_limits_subtitle":
          "Usu\u0144 reklamy i czasy oczekiwania.",
      "premium_benefits_title": "Korzy\u015bci Premium",
      "premium_main_description":
          "Usu\u0144 wszystkie reklamy, wyeliminuj czasy oczekiwania i wykonuj nieograniczon\u0105 analiz\u0119.",
      "premium_benefit_no_ads": "Reklamy ca\u0142kowicie usuni\u0119te.",
      "premium_benefit_fast":
          "Czasy oczekiwania wyeliminowane i zwi\u0119kszona pr\u0119dko\u015b\u0107.",
      "premium_benefit_unlimited":
          "Nieograniczona analiza z pe\u0142nym dost\u0119pem do wszystkich funkcji.",
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
      "rate_test_message":
          "To urz\u0105dzenie jest obecnie w fazie test\u00f3w.",
      "story_section_title":
          "Ogl\u0105daj historie w tajemnicy lub powi\u0119kszaj zdj\u0119cia profilowe",
      "story_login_required":
          "Zaloguj siÃ„â„¢, aby oglÃ„â€¦daÃ„â€¡ relacje anonimowo i powiÃ„â„¢kszaÃ„â€¡ zdjÃ„â„¢cia profilowe.",
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
          "Veri yÃƒÂ¼kleme kesildi: takipÃƒÂ§i verisi eksik ({fetched}/{total}).",
      "following_incomplete":
          "Veri yÃƒÂ¼kleme kesildi: takip edilen verisi eksik ({fetched}/{total}).",
      "empty_data":
          "Veri yÃƒÂ¼kleme kesildi: Instagram boÃ…Å¸ veri dÃƒÂ¶ndÃƒÂ¼rdÃƒÂ¼.",
      "unexpected_error":
          "Veri yÃƒÂ¼kleme kesildi: beklenmeyen bir hata oluÃ…Å¸tu.",
      "automation_warning":
          "Instagram otomatik davranÃ„Â±Ã…Å¸ uyarÃ„Â±sÃ„Â± verdi. GÃƒÂ¼venlik iÃƒÂ§in veri ÃƒÂ§ekme durduruldu.",
      "security_required":
          "Instagram gÃƒÂ¼venlik doÃ„Å¸rulamasÃ„Â± istedi. Instagram uygulamasÃ„Â±ndan doÃ„Å¸rulayÃ„Â±p tekrar deneyin.",
      "session_invalid":
          "Oturum geÃƒÂ§ersiz veya doÃ„Å¸rulama bekliyor. LÃƒÂ¼tfen tekrar giriÃ…Å¸ yapÃ„Â±n.",
      "rate_limited":
          "Ãƒâ€¡ok hÃ„Â±zlÃ„Â± istek gÃƒÂ¶nderildi. Veri yÃƒÂ¼kleme gÃƒÂ¼venlik nedeniyle kesildi.",
      "connection_error":
          "BaÃ„Å¸lantÃ„Â± sorunu nedeniyle veri yÃƒÂ¼kleme tamamlanamadÃ„Â±.",
      "server_error":
          "Instagram sunucusu hata dÃƒÂ¶ndÃƒÂ¼rdÃƒÂ¼ (HTTP {code}). Veri yÃƒÂ¼kleme kesildi.",
      "story_security_required":
          "Instagram gÃƒÂ¼venlik doÃ„Å¸rulamasÃ„Â± gerekiyor (hikaye verisi alÃ„Â±namadÃ„Â±).",
      "story_detail":
          "Hikaye verisi alÃ„Â±namadÃ„Â±. Genelde Instagram doÃ„Å¸rulamasÃ„Â±, geÃƒÂ§ici API kÃ„Â±sÃ„Â±tÃ„Â± veya baÃ„Å¸lantÃ„Â± kesintisinden kaynaklanÃ„Â±r. 2-3 dakika sonra tekrar deneyin.",
      "story_generic":
          "Hikaye verisi alÃ„Â±namadÃ„Â±. LÃƒÂ¼tfen biraz sonra tekrar deneyin.",
      "secret_mode_label": "GÃ„Â°ZLÃ„Â° MOD",
    },
    "en": {
      "followers_incomplete":
          "Data loading was interrupted: follower data incomplete ({fetched}/{total}).",
      "following_incomplete":
          "Data loading was interrupted: following data incomplete ({fetched}/{total}).",
      "empty_data":
          "Data loading was interrupted: Instagram returned empty data.",
      "unexpected_error": "Data loading stopped due to an unexpected error.",
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
      "story_generic": "Could not fetch story data. Please try again shortly.",
      "secret_mode_label": "Secret Mode",
    },
    "de": {
      "followers_incomplete":
          "Datenabruf unterbrochen: Follower-Daten unvollstandig ({fetched}/{total}).",
      "following_incomplete":
          "Datenabruf unterbrochen: Following-Daten unvollstandig ({fetched}/{total}).",
      "empty_data": "Datenabruf unterbrochen: Instagram lieferte leere Daten.",
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
          "Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã«Â¡Å“Ã«â€œÅ“ÃªÂ°â‚¬ Ã¬Â¤â€˜Ã«â€¹Â¨Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤: Ã­Å’â€Ã«Â¡Å“Ã¬â€ºÅ’ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°ÃªÂ°â‚¬ Ã«Â¶Ë†Ã¬â„¢â€Ã¬Â â€Ã­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤ ({fetched}/{total}).",
      "following_incomplete":
          "Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã«Â¡Å“Ã«â€œÅ“ÃªÂ°â‚¬ Ã¬Â¤â€˜Ã«â€¹Â¨Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤: Ã­Å’â€Ã«Â¡Å“Ã¬Ââ€° Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°ÃªÂ°â‚¬ Ã«Â¶Ë†Ã¬â„¢â€Ã¬Â â€Ã­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤ ({fetched}/{total}).",
      "empty_data":
          "Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã«Â¡Å“Ã«â€œÅ“ÃªÂ°â‚¬ Ã¬Â¤â€˜Ã«â€¹Â¨Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤: InstagramÃ¬ÂÂ´ Ã«Â¹Ë† Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°Ã«Â¥Â¼ Ã«Â°ËœÃ­â„¢ËœÃ­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.",
      "unexpected_error":
          "Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã«Â¡Å“Ã«â€œÅ“ÃªÂ°â‚¬ Ã¬Â¤â€˜Ã«â€¹Â¨Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤: Ã¬ËœË†ÃªÂ¸Â°Ã¬Â¹Ëœ Ã¬â€¢Å Ã¬Ââ‚¬ Ã¬ËœÂ¤Ã«Â¥ËœÃªÂ°â‚¬ Ã«Â°Å“Ã¬Æ’ÂÃ­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.",
      "automation_warning":
          "InstagramÃ¬â€”ÂÃ¬â€Å“ Ã¬ÂÂÃ«Ââ„¢Ã­â„¢â€ Ã«Ââ„¢Ã¬Ââ€˜ ÃªÂ²Â½ÃªÂ³Â ÃªÂ°â‚¬ ÃªÂ°ÂÃ¬Â§â‚¬Ã«ÂËœÃ¬â€“Â´ Ã¬â€¢Ë†Ã¬Â â€Ã¬Ââ€ Ã¬Å“â€Ã­â€¢Â´ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã¬Ë†ËœÃ¬Â§â€˜Ã¬Ââ€ Ã¬Â¤â€˜Ã«â€¹Â¨Ã­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.",
      "security_required":
          "Instagram Ã«Â³Â´Ã¬â€¢Ë† Ã­â„¢â€¢Ã¬ÂÂ¸Ã¬ÂÂ´ Ã­â€¢â€Ã¬Å¡â€Ã­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤. Instagram Ã¬â€¢Â±Ã¬â€”ÂÃ¬â€Å“ Ã­â„¢â€¢Ã¬ÂÂ¸ Ã­â€ºâ€ Ã«â€¹Â¤Ã¬â€¹Å“ Ã¬â€¹Å“Ã«Ââ€Ã­â€¢ËœÃ¬â€Â¸Ã¬Å¡â€.",
      "session_invalid":
          "Ã¬â€Â¸Ã¬â€¦ËœÃ¬ÂÂ´ Ã¬Å“Â Ã­Å¡Â¨Ã­â€¢ËœÃ¬Â§â‚¬ Ã¬â€¢Å ÃªÂ±Â°Ã«â€šËœ Ã­â„¢â€¢Ã¬ÂÂ¸ Ã«Å’â‚¬ÃªÂ¸Â° Ã¬Â¤â€˜Ã¬Ââ€¦Ã«â€¹Ë†Ã«â€¹Â¤. Ã«â€¹Â¤Ã¬â€¹Å“ Ã«Â¡Å“ÃªÂ·Â¸Ã¬ÂÂ¸Ã­â€¢Â´ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.",
      "rate_limited":
          "Ã¬Å¡â€Ã¬Â²Â­Ã¬ÂÂ´ Ã«â€Ë†Ã«Â¬Â´ Ã«Â§ÂÃ¬â€¢â€ Ã¬â€¢Ë†Ã¬Â â€Ã¬Ââ€ Ã¬Å“â€Ã­â€¢Â´ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã«Â¡Å“Ã«â€œÅ“Ã«Â¥Â¼ Ã¬Â¤â€˜Ã«â€¹Â¨Ã­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.",
      "connection_error":
          "Ã¬â€”Â°ÃªÂ²Â° Ã«Â¬Â¸Ã¬Â Å“Ã«Â¡Å“ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã«Â¡Å“Ã«â€œÅ“Ã«Â¥Â¼ Ã¬â„¢â€Ã«Â£Å’Ã­â€¢ËœÃ¬Â§â‚¬ Ã«ÂªÂ»Ã­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.",
      "server_error":
          "Instagram Ã¬ËœÂ¤Ã«Â¥Ëœ(HTTP {code})Ã«Â¡Å“ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â° Ã«Â¡Å“Ã«â€œÅ“ÃªÂ°â‚¬ Ã¬Â¤â€˜Ã«â€¹Â¨Ã«ÂËœÃ¬â€”Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.",
      "story_security_required":
          "Instagram Ã«Â³Â´Ã¬â€¢Ë† Ã­â„¢â€¢Ã¬ÂÂ¸Ã¬ÂÂ´ Ã­â€¢â€Ã¬Å¡â€Ã­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤ (Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°Ã«Â¥Â¼ Ã«Â¶Ë†Ã«Å¸Â¬Ã¬ËœÂ¬ Ã¬Ë†Ëœ Ã¬â€”â€ Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤).",
      "story_detail":
          "Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°Ã«Â¥Â¼ Ã«Â¶Ë†Ã«Å¸Â¬Ã¬ËœÂ¤Ã¬Â§â‚¬ Ã«ÂªÂ»Ã­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤. Ã¬ÂÂ¼Ã«Â°ËœÃ¬Â ÂÃ¬Å“Â¼Ã«Â¡Å“ Instagram Ã¬ÂÂ¸Ã¬Â¦Â, Ã¬ÂÂ¼Ã¬â€¹Å“Ã¬Â Â API Ã¬Â Å“Ã­â€¢Å“ Ã«ËœÂÃ«Å â€ Ã«â€Â¤Ã­Å Â¸Ã¬â€ºÅ’Ã­ÂÂ¬ Ã«Â¬Â¸Ã¬Â Å“Ã«Â¡Å“ Ã«Â°Å“Ã¬Æ’ÂÃ­â€¢Â©Ã«â€¹Ë†Ã«â€¹Â¤. 2-3Ã«Â¶â€ Ã­â€ºâ€ Ã«â€¹Â¤Ã¬â€¹Å“ Ã¬â€¹Å“Ã«Ââ€Ã­â€¢ËœÃ¬â€Â¸Ã¬Å¡â€.",
      "story_generic":
          "Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°Ã«Â¥Â¼ Ã«Â¶Ë†Ã«Å¸Â¬Ã¬ËœÂ¤Ã¬Â§â‚¬ Ã«ÂªÂ»Ã­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤. Ã¬ÂÂ Ã¬â€¹Å“ Ã­â€ºâ€ Ã«â€¹Â¤Ã¬â€¹Å“ Ã¬â€¹Å“Ã«Ââ€Ã­â€¢ËœÃ¬â€Â¸Ã¬Å¡â€.",
      "secret_mode_label": "Ã«Â¹â€Ã«Â°â‚¬ Ã«ÂªÂ¨Ã«â€œÅ“",
    },
    "ja": {
      "followers_incomplete":
          "Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÅ’Ã¤Â¸Â­Ã¦â€“Â­Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸: Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¯Ã£Æ’Â¼Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£ÂÅ’Ã¤Â¸ÂÃ¥Â®Å’Ã¥â€¦Â¨Ã£ÂÂ§Ã£Ââ„¢ ({fetched}/{total})Ã£â‚¬â€š",
      "following_incomplete":
          "Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÅ’Ã¤Â¸Â­Ã¦â€“Â­Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸: Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¼Ã¤Â¸Â­Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£ÂÅ’Ã¤Â¸ÂÃ¥Â®Å’Ã¥â€¦Â¨Ã£ÂÂ§Ã£Ââ„¢ ({fetched}/{total})Ã£â‚¬â€š",
      "empty_data":
          "Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÅ’Ã¤Â¸Â­Ã¦â€“Â­Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸: Instagram Ã£ÂÅ’Ã§Â©ÂºÃ£ÂÂ®Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¨Â¿â€Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š",
      "unexpected_error":
          "Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÅ’Ã¤Â¸Â­Ã¦â€“Â­Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸: Ã¤ÂºË†Ã¦Å“Å¸Ã£Ââ€”Ã£ÂÂªÃ£Ââ€Ã£â€šÂ¨Ã£Æ’Â©Ã£Æ’Â¼Ã£ÂÅ’Ã§â„¢ÂºÃ§â€Å¸Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š",
      "automation_warning":
          "Instagram Ã£ÂÅ’Ã¨â€¡ÂªÃ¥â€¹â€¢Ã¥Å’â€“Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÅ¸Ã¦Å’â„¢Ã¥â€¹â€¢Ã£â€šâ€™Ã¦Â¤Å“Ã¥â€¡ÂºÃ£Ââ€”Ã£ÂÅ¸Ã£ÂÅ¸Ã£â€šÂÃ£â‚¬ÂÃ¥Â®â€°Ã¥â€¦Â¨Ã£ÂÂ®Ã£ÂÅ¸Ã£â€šÂÃ£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£â€šâ€™Ã¥ÂÅ“Ã¦Â­Â¢Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š",
      "security_required":
          "Instagram Ã£ÂÂ®Ã£â€šÂ»Ã£â€šÂ­Ã£Æ’Â¥Ã£Æ’ÂªÃ£Æ’â€ Ã£â€šÂ£Ã§Â¢ÂºÃ¨ÂªÂÃ£ÂÅ’Ã¥Â¿â€¦Ã¨Â¦ÂÃ£ÂÂ§Ã£Ââ„¢Ã£â‚¬â€šÃ£â€šÂ¢Ã£Æ’â€”Ã£Æ’ÂªÃ£ÂÂ§Ã§Â¢ÂºÃ¨ÂªÂÃ¥Â¾Å’Ã£â‚¬ÂÃ¥â€ ÂÃ¨Â©Â¦Ã¨Â¡Å’Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š",
      "session_invalid":
          "Ã£â€šÂ»Ã£Æ’Æ’Ã£â€šÂ·Ã£Æ’Â§Ã£Æ’Â³Ã£ÂÅ’Ã§â€Â¡Ã¥Å Â¹Ã£Ââ€¹Ã£â‚¬ÂÃ§Â¢ÂºÃ¨ÂªÂÃ¥Â¾â€¦Ã£ÂÂ¡Ã£ÂÂ§Ã£Ââ„¢Ã£â‚¬â€šÃ¥â€ ÂÃ£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¤Ã£Æ’Â³Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š",
      "rate_limited":
          "Ã£Æ’ÂªÃ£â€šÂ¯Ã£â€šÂ¨Ã£â€šÂ¹Ã£Æ’Ë†Ã£ÂÅ’Ã¥Â¤Å¡Ã£Ââ„¢Ã£ÂÂÃ£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€šÃ¥Â®â€°Ã¥â€¦Â¨Ã£ÂÂ®Ã£ÂÅ¸Ã£â€šÂÃ£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£â€šâ€™Ã¤Â¸Â­Ã¦â€“Â­Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š",
      "connection_error":
          "Ã¦ÂÂ¥Ã§Â¶Å¡Ã£ÂÂ®Ã¥â€¢ÂÃ©Â¡Å’Ã£ÂÂ«Ã£â€šË†Ã£â€šÅ Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£â€šâ€™Ã¥Â®Å’Ã¤Âºâ€ Ã£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£ÂÂ§Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š",
      "server_error":
          "Instagram Ã£â€šÂ¨Ã£Æ’Â©Ã£Æ’Â¼ (HTTP {code}) Ã£ÂÂ«Ã£â€šË†Ã£â€šÅ Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÅ’Ã¤Â¸Â­Ã¦â€“Â­Ã£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š",
      "story_security_required":
          "Instagram Ã£ÂÂ®Ã£â€šÂ»Ã£â€šÂ­Ã£Æ’Â¥Ã£Æ’ÂªÃ£Æ’â€ Ã£â€šÂ£Ã§Â¢ÂºÃ¨ÂªÂÃ£ÂÅ’Ã¥Â¿â€¦Ã¨Â¦ÂÃ£ÂÂ§Ã£Ââ„¢ (Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œ)Ã£â‚¬â€š",
      "story_detail":
          "Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£ÂÂ§Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€šÃ©â‚¬Å¡Ã¥Â¸Â¸Ã£ÂÂ¯ Instagram Ã£ÂÂ®Ã¨ÂªÂÃ¨Â¨Â¼Ã£â‚¬ÂAPI Ã£ÂÂ®Ã¤Â¸â‚¬Ã¦â„¢â€šÃ¥Ë†Â¶Ã©â„¢ÂÃ£â‚¬ÂÃ£ÂÂ¾Ã£ÂÅ¸Ã£ÂÂ¯Ã¦ÂÂ¥Ã§Â¶Å¡Ã¥â€¢ÂÃ©Â¡Å’Ã£ÂÅ’Ã¥ÂÅ¸Ã¥â€ºÂ Ã£ÂÂ§Ã£Ââ„¢Ã£â‚¬â€š2Ã£â‚¬Å“3 Ã¥Ë†â€ Ã¥Â¾Å’Ã£ÂÂ«Ã¥â€ ÂÃ¨Â©Â¦Ã¨Â¡Å’Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š",
      "story_generic":
          "Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£ÂÂ§Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€šÃ£Ââ€”Ã£ÂÂ°Ã£â€šâ€°Ã£ÂÂÃ£Ââ€”Ã£ÂÂ¦Ã£Ââ€¹Ã£â€šâ€°Ã¥â€ ÂÃ¨Â©Â¦Ã¨Â¡Å’Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š",
      "secret_mode_label":
          "Ã£â€šÂ·Ã£Æ’Â¼Ã£â€šÂ¯Ã£Æ’Â¬Ã£Æ’Æ’Ã£Æ’Ë†Ã£Æ’Â¢Ã£Æ’Â¼Ã£Æ’â€°",
    },
    "ru": {
      "followers_incomplete":
          "Äâ€”ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° ÄÂ¿Ã‘â‚¬ÄÂµÃ‘â‚¬ÄÂ²ÄÂ°ÄÂ½ÄÂ°: ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¿ÄÂ¸Ã‘ÂÃ‘â€¡ÄÂ¸ÄÂºÄÂ¾ÄÂ² ÄÂ½ÄÂµÄÂ¿ÄÂ¾ÄÂ»ÄÂ½Ã‘â€¹ÄÂµ ({fetched}/{total}).",
      "following_incomplete":
          "Äâ€”ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° ÄÂ¿Ã‘â‚¬ÄÂµÃ‘â‚¬ÄÂ²ÄÂ°ÄÂ½ÄÂ°: ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¿ÄÂ¸Ã‘ÂÄÂ¾ÄÂº ÄÂ½ÄÂµÄÂ¿ÄÂ¾ÄÂ»ÄÂ½Ã‘â€¹ÄÂµ ({fetched}/{total}).",
      "empty_data":
          "Äâ€”ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° ÄÂ¿Ã‘â‚¬ÄÂµÃ‘â‚¬ÄÂ²ÄÂ°ÄÂ½ÄÂ°: Instagram ÄÂ²ÄÂµÃ‘â‚¬ÄÂ½Ã‘Æ’ÄÂ» ÄÂ¿Ã‘Æ’Ã‘ÂÃ‘â€šÃ‘â€¹ÄÂµ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ.",
      "unexpected_error":
          "Äâ€”ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° ÄÂ¿Ã‘â‚¬ÄÂµÃ‘â‚¬ÄÂ²ÄÂ°ÄÂ½ÄÂ°: ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ¸ÄÂ·ÄÂ¾Ã‘Ë†ÄÂ»ÄÂ° ÄÂ½ÄÂµÄÂ¿Ã‘â‚¬ÄÂµÄÂ´ÄÂ²ÄÂ¸ÄÂ´ÄÂµÄÂ½ÄÂ½ÄÂ°Ã‘Â ÄÂ¾Ã‘Ë†ÄÂ¸ÄÂ±ÄÂºÄÂ°.",
      "automation_warning":
          "Instagram ÄÂ¾ÄÂ±ÄÂ½ÄÂ°Ã‘â‚¬Ã‘Æ’ÄÂ¶ÄÂ¸ÄÂ» ÄÂ¿Ã‘â‚¬ÄÂ¸ÄÂ·ÄÂ½ÄÂ°ÄÂºÄÂ¸ ÄÂ°ÄÂ²Ã‘â€šÄÂ¾ÄÂ¼ÄÂ°Ã‘â€šÄÂ¸ÄÂ·ÄÂ°Ã‘â€ ÄÂ¸ÄÂ¸. Äâ€ÄÂ»Ã‘Â ÄÂ±ÄÂµÄÂ·ÄÂ¾ÄÂ¿ÄÂ°Ã‘ÂÄÂ½ÄÂ¾Ã‘ÂÃ‘â€šÄÂ¸ ÄÂ·ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° ÄÂ¾Ã‘ÂÃ‘â€šÄÂ°ÄÂ½ÄÂ¾ÄÂ²ÄÂ»ÄÂµÄÂ½ÄÂ°.",
      "security_required":
          "Instagram Ã‘â€šÃ‘â‚¬ÄÂµÄÂ±Ã‘Æ’ÄÂµÃ‘â€š ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ²ÄÂµÃ‘â‚¬ÄÂºÃ‘Æ’ ÄÂ±ÄÂµÄÂ·ÄÂ¾ÄÂ¿ÄÂ°Ã‘ÂÄÂ½ÄÂ¾Ã‘ÂÃ‘â€šÄÂ¸. ÄÅ¸ÄÂ¾ÄÂ´Ã‘â€šÄÂ²ÄÂµÃ‘â‚¬ÄÂ´ÄÂ¸Ã‘â€šÄÂµ ÄÂ² ÄÂ¿Ã‘â‚¬ÄÂ¸ÄÂ»ÄÂ¾ÄÂ¶ÄÂµÄÂ½ÄÂ¸ÄÂ¸ ÄÂ¸ ÄÂ¿ÄÂ¾ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ±Ã‘Æ’ÄÂ¹Ã‘â€šÄÂµ Ã‘ÂÄÂ½ÄÂ¾ÄÂ²ÄÂ°.",
      "session_invalid":
          "ÄÂ¡ÄÂµÃ‘ÂÃ‘ÂÄÂ¸Ã‘Â ÄÂ½ÄÂµÄÂ´ÄÂµÄÂ¹Ã‘ÂÃ‘â€šÄÂ²ÄÂ¸Ã‘â€šÄÂµÄÂ»Ã‘Å’ÄÂ½ÄÂ° ÄÂ¸ÄÂ»ÄÂ¸ ÄÂ¾ÄÂ¶ÄÂ¸ÄÂ´ÄÂ°ÄÂµÃ‘â€š ÄÂ¿ÄÂ¾ÄÂ´Ã‘â€šÄÂ²ÄÂµÃ‘â‚¬ÄÂ¶ÄÂ´ÄÂµÄÂ½ÄÂ¸Ã‘Â. Äâ€™ÄÂ¾ÄÂ¹ÄÂ´ÄÂ¸Ã‘â€šÄÂµ Ã‘ÂÄÂ½ÄÂ¾ÄÂ²ÄÂ°.",
      "rate_limited":
          "ÄÂÃ‘â€šÄÂ¿Ã‘â‚¬ÄÂ°ÄÂ²ÄÂ»ÄÂµÄÂ½ÄÂ¾ Ã‘ÂÄÂ»ÄÂ¸Ã‘Ë†ÄÂºÄÂ¾ÄÂ¼ ÄÂ¼ÄÂ½ÄÂ¾ÄÂ³ÄÂ¾ ÄÂ·ÄÂ°ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘ÂÄÂ¾ÄÂ². Äâ€ÄÂ»Ã‘Â ÄÂ±ÄÂµÄÂ·ÄÂ¾ÄÂ¿ÄÂ°Ã‘ÂÄÂ½ÄÂ¾Ã‘ÂÃ‘â€šÄÂ¸ ÄÂ·ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° ÄÂ¾Ã‘ÂÃ‘â€šÄÂ°ÄÂ½ÄÂ¾ÄÂ²ÄÂ»ÄÂµÄÂ½ÄÂ°.",
      "connection_error":
          "ÄÂÄÂµ Ã‘Æ’ÄÂ´ÄÂ°ÄÂ»ÄÂ¾Ã‘ÂÃ‘Å’ ÄÂ·ÄÂ°ÄÂ²ÄÂµÃ‘â‚¬Ã‘Ë†ÄÂ¸Ã‘â€šÃ‘Å’ ÄÂ·ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÃ‘Æ’ ÄÂ¸ÄÂ·-ÄÂ·ÄÂ° ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ±ÄÂ»ÄÂµÄÂ¼Ã‘â€¹ Ã‘Â ÄÂ¿ÄÂ¾ÄÂ´ÄÂºÄÂ»Ã‘ÂÃ‘â€¡ÄÂµÄÂ½ÄÂ¸ÄÂµÄÂ¼.",
      "server_error":
          "ÄÂÃ‘Ë†ÄÂ¸ÄÂ±ÄÂºÄÂ° Instagram (HTTP {code}). Äâ€”ÄÂ°ÄÂ³Ã‘â‚¬Ã‘Æ’ÄÂ·ÄÂºÄÂ° ÄÂ¿Ã‘â‚¬ÄÂµÃ‘â‚¬ÄÂ²ÄÂ°ÄÂ½ÄÂ°.",
      "story_security_required":
          "ÄÂ¢Ã‘â‚¬ÄÂµÄÂ±Ã‘Æ’ÄÂµÃ‘â€šÃ‘ÂÃ‘Â ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ²ÄÂµÃ‘â‚¬ÄÂºÄÂ° ÄÂ±ÄÂµÄÂ·ÄÂ¾ÄÂ¿ÄÂ°Ã‘ÂÄÂ½ÄÂ¾Ã‘ÂÃ‘â€šÄÂ¸ Instagram (ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ½ÄÂµÄÂ´ÄÂ¾Ã‘ÂÃ‘â€šÃ‘Æ’ÄÂ¿ÄÂ½Ã‘â€¹).",
      "story_detail":
          "ÄÂÄÂµ Ã‘Æ’ÄÂ´ÄÂ°ÄÂ»ÄÂ¾Ã‘ÂÃ‘Å’ ÄÂ¿ÄÂ¾ÄÂ»Ã‘Æ’Ã‘â€¡ÄÂ¸Ã‘â€šÃ‘Å’ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â. ÄÂÄÂ±Ã‘â€¹Ã‘â€¡ÄÂ½ÄÂ¾ Ã‘ÂÃ‘â€šÄÂ¾ Ã‘ÂÄÂ²Ã‘ÂÄÂ·ÄÂ°ÄÂ½ÄÂ¾ Ã‘Â ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ²ÄÂµÃ‘â‚¬ÄÂºÄÂ¾ÄÂ¹ Instagram, ÄÂ²Ã‘â‚¬ÄÂµÄÂ¼ÄÂµÄÂ½ÄÂ½Ã‘â€¹ÄÂ¼ÄÂ¸ ÄÂ¾ÄÂ³Ã‘â‚¬ÄÂ°ÄÂ½ÄÂ¸Ã‘â€¡ÄÂµÄÂ½ÄÂ¸Ã‘ÂÄÂ¼ÄÂ¸ API ÄÂ¸ÄÂ»ÄÂ¸ Ã‘ÂÄÂ±ÄÂ¾ÄÂµÄÂ¼ Ã‘ÂÄÂµÃ‘â€šÄÂ¸. ÄÅ¸ÄÂ¾ÄÂ²Ã‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘â€šÄÂµ Ã‘â€¡ÄÂµÃ‘â‚¬ÄÂµÄÂ· 2Ã¢â‚¬â€œ3 ÄÂ¼ÄÂ¸ÄÂ½Ã‘Æ’Ã‘â€šÃ‘â€¹.",
      "story_generic":
          "ÄÂÄÂµ Ã‘Æ’ÄÂ´ÄÂ°ÄÂ»ÄÂ¾Ã‘ÂÃ‘Å’ ÄÂ¿ÄÂ¾ÄÂ»Ã‘Æ’Ã‘â€¡ÄÂ¸Ã‘â€šÃ‘Å’ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â. ÄÅ¸ÄÂ¾ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ±Ã‘Æ’ÄÂ¹Ã‘â€šÄÂµ Ã‘ÂÄÂ½ÄÂ¾ÄÂ²ÄÂ° Ã‘â€¡Ã‘Æ’Ã‘â€šÃ‘Å’ ÄÂ¿ÄÂ¾ÄÂ·ÄÂ¶ÄÂµ.",
      "secret_mode_label":
          "ÄÂ¡Äâ€¢ÄÅ¡ÄÂ Äâ€¢ÄÂ¢ÄÂÄÂ«Äâ„¢ ÄÂ Äâ€¢Äâ€“ÄËœÄÅ“",
    },
    "ar": {
      "followers_incomplete":
          "Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€: Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¨Ã˜Â¹Ã™Å Ã™â€  Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã™Æ’Ã˜ÂªÃ™â€¦Ã™â€Ã˜Â© ({fetched}/{total}).",
      "following_incomplete":
          "Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€: Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¨Ã™ÂÃ˜Â¹Ã™Å Ã™â€  Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã™Æ’Ã˜ÂªÃ™â€¦Ã™â€Ã˜Â© ({fetched}/{total}).",
      "empty_data":
          "Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€: Ã˜Â£Ã˜Â¹Ã˜Â§Ã˜Â¯ Instagram Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã™ÂÃ˜Â§Ã˜Â±Ã˜ÂºÃ˜Â©.",
      "unexpected_error":
          "Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€ Ã˜Â¨Ã˜Â³Ã˜Â¨Ã˜Â¨ Ã˜Â®Ã˜Â·Ã˜Â£ Ã˜ÂºÃ™Å Ã˜Â± Ã™â€¦Ã˜ÂªÃ™Ë†Ã™â€šÃ˜Â¹.",
      "automation_warning":
          "Ã˜Â±Ã˜ÂµÃ˜Â¯ Instagram Ã˜Â³Ã™â€Ã™Ë†Ã™Æ’Ã™â€¹Ã˜Â§ Ã˜Â¢Ã™â€Ã™Å Ã™â€¹Ã˜Â§. Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â Ã˜Â¬Ã™â€Ã˜Â¨ Ã˜Â§Ã™â€Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â­Ã™ÂÃ˜Â§Ã˜Â¸Ã™â€¹Ã˜Â§ Ã˜Â¹Ã™â€Ã™â€° Ã˜Â§Ã™â€Ã˜Â£Ã™â€¦Ã˜Â§Ã™â€ .",
      "security_required":
          "Ã™Å Ã˜ÂªÃ˜Â·Ã™â€Ã˜Â¨ Instagram Ã˜ÂªÃ˜Â­Ã™â€šÃ™â€šÃ™â€¹Ã˜Â§ Ã˜Â£Ã™â€¦Ã™â€ Ã™Å Ã™â€¹Ã˜Â§. Ã˜Â£Ã™Æ’Ã™â€¦Ã™â€ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€šÃ™â€š Ã™â€¦Ã™â€  Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â·Ã˜Â¨Ã™Å Ã™â€š Ã˜Â«Ã™â€¦ Ã˜Â­Ã˜Â§Ã™Ë†Ã™â€ Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°.",
      "session_invalid":
          "Ã˜Â§Ã™â€Ã˜Â¬Ã™â€Ã˜Â³Ã˜Â© Ã˜ÂºÃ™Å Ã˜Â± Ã˜ÂµÃ˜Â§Ã™â€Ã˜Â­Ã˜Â© Ã˜Â£Ã™Ë† Ã˜Â¨Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¸Ã˜Â§Ã˜Â± Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€šÃ™â€š. Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¯Ã˜Â®Ã™Ë†Ã™â€ Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°.",
      "rate_limited":
          "Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã˜Â±Ã˜Â³Ã˜Â§Ã™â€ Ã˜Â¹Ã˜Â¯Ã˜Â¯ Ã™Æ’Ã˜Â¨Ã™Å Ã˜Â± Ã˜Â¬Ã˜Â¯Ã™â€¹Ã˜Â§ Ã™â€¦Ã™â€  Ã˜Â§Ã™â€Ã˜Â·Ã™â€Ã˜Â¨Ã˜Â§Ã˜Âª. Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€ Ã˜Â­Ã™ÂÃ˜Â§Ã˜Â¸Ã™â€¹Ã˜Â§ Ã˜Â¹Ã™â€Ã™â€° Ã˜Â§Ã™â€Ã˜Â£Ã™â€¦Ã˜Â§Ã™â€ .",
      "connection_error":
          "Ã˜ÂªÃ˜Â¹Ã˜Â°Ã˜Â± Ã˜Â¥Ã™Æ’Ã™â€¦Ã˜Â§Ã™â€ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€ Ã˜Â¨Ã˜Â³Ã˜Â¨Ã˜Â¨ Ã™â€¦Ã˜Â´Ã™Æ’Ã™â€Ã˜Â© Ã™ÂÃ™Å  Ã˜Â§Ã™â€Ã˜Â§Ã˜ÂªÃ˜ÂµÃ˜Â§Ã™â€.",
      "server_error":
          "Ã˜Â®Ã˜Â·Ã˜Â£ Ã™â€¦Ã™â€  Instagram Ã¢â‚¬Â(HTTP {code}). Ã˜ÂªÃ™â€¦ Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€¦Ã™Å Ã™â€.",
      "story_security_required":
          "Ã™Å Ã™â€Ã˜Â²Ã™â€¦ Ã˜ÂªÃ˜Â­Ã™â€šÃ™â€š Ã˜Â£Ã™â€¦Ã™â€ Ã™Å  Ã™â€¦Ã™â€  Instagram (Ã˜ÂªÃ˜Â¹Ã˜Â°Ã˜Â± Ã˜Â¬Ã™â€Ã˜Â¨ Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã˜Â³Ã˜ÂªÃ™Ë†Ã˜Â±Ã™Å ).",
      "story_detail":
          "Ã˜ÂªÃ˜Â¹Ã˜Â°Ã˜Â± Ã˜Â¬Ã™â€Ã˜Â¨ Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã˜Â³Ã˜ÂªÃ™Ë†Ã˜Â±Ã™Å . Ã™Å Ã˜Â­Ã˜Â¯Ã˜Â« Ã˜Â°Ã™â€Ã™Æ’ Ã˜ÂºÃ˜Â§Ã™â€Ã˜Â¨Ã™â€¹Ã˜Â§ Ã˜Â¨Ã˜Â³Ã˜Â¨Ã˜Â¨ Ã˜ÂªÃ˜Â­Ã™â€šÃ™â€š Instagram Ã˜Â£Ã™Ë† Ã™â€šÃ™Å Ã™Ë†Ã˜Â¯ API Ã™â€¦Ã˜Â¤Ã™â€šÃ˜ÂªÃ˜Â© Ã˜Â£Ã™Ë† Ã™â€¦Ã˜Â´Ã™Æ’Ã™â€Ã˜Â© Ã˜Â´Ã˜Â¨Ã™Æ’Ã˜Â©. Ã˜Â­Ã˜Â§Ã™Ë†Ã™â€ Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€° Ã˜Â¨Ã˜Â¹Ã˜Â¯ 2-3 Ã˜Â¯Ã™â€šÃ˜Â§Ã˜Â¦Ã™â€š.",
      "story_generic":
          "Ã˜ÂªÃ˜Â¹Ã˜Â°Ã˜Â± Ã˜Â¬Ã™â€Ã˜Â¨ Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã˜Â³Ã˜ÂªÃ™Ë†Ã˜Â±Ã™Å . Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â§Ã™â€Ã™â€¦Ã˜Â­Ã˜Â§Ã™Ë†Ã™â€Ã˜Â© Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€° Ã˜Â¨Ã˜Â¹Ã˜Â¯ Ã™â€šÃ™â€Ã™Å Ã™â€.",
      "secret_mode_label": "Ã˜Â§Ã™â€Ã™Ë†Ã˜Â¶Ã˜Â¹ Ã˜Â§Ã™â€Ã˜Â³Ã˜Â±Ã™Å ",
    },
    "hi": {
      "followers_incomplete":
          "Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤Â°Ã Â¥ÂÃ Â¤â€¢ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾: Ã Â¤Â«Ã Â¤Â¼Ã Â¥â€°Ã Â¤Â²Ã Â¥â€¹Ã Â¤â€¦Ã Â¤Â° Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤â€¦Ã Â¤Â§Ã Â¥â€šÃ Â¤Â°Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë† ({fetched}/{total}).",
      "following_incomplete":
          "Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤Â°Ã Â¥ÂÃ Â¤â€¢ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾: Ã Â¤Â«Ã Â¤Â¼Ã Â¥â€°Ã Â¤Â²Ã Â¥â€¹Ã Â¤â€¡Ã Â¤â€šÃ Â¤â€” Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤â€¦Ã Â¤Â§Ã Â¥â€šÃ Â¤Â°Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë† ({fetched}/{total}).",
      "empty_data":
          "Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤Â°Ã Â¥ÂÃ Â¤â€¢ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾: Instagram Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€“Ã Â¤Â¾Ã Â¤Â²Ã Â¥â‚¬ Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥Å’Ã Â¤Å¸Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¾Ã Â¥Â¤",
      "unexpected_error":
          "Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤Â°Ã Â¥ÂÃ Â¤â€¢ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾: Ã Â¤ÂÃ Â¤â€¢ Ã Â¤â€¦Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾Ã Â¤Â¶Ã Â¤Â¿Ã Â¤Â¤ Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â°Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â¿ Ã Â¤Â¹Ã Â¥ÂÃ Â¤Ë†Ã Â¥Â¤",
      "automation_warning":
          "Instagram Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€˜Ã Â¤Å¸Ã Â¥â€¹Ã Â¤Â®Ã Â¥â€¡Ã Â¤Â¶Ã Â¤Â¨ Ã Â¤Å“Ã Â¥Ë†Ã Â¤Â¸Ã Â¥â‚¬ Ã Â¤â€”Ã Â¤Â¤Ã Â¤Â¿Ã Â¤ÂµÃ Â¤Â¿Ã Â¤Â§Ã Â¤Â¿ Ã Â¤ÂªÃ Â¤Â¹Ã Â¤Å¡Ã Â¤Â¾Ã Â¤Â¨Ã Â¥â‚¬Ã Â¥Â¤ Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â°Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¾ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤Â°Ã Â¥â€¹Ã Â¤â€¢ Ã Â¤Â¦Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾Ã Â¥Â¤",
      "security_required":
          "Instagram Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â°Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾Ã Â¤ÂªÃ Â¤Â¨ Ã Â¤Â®Ã Â¤Â¾Ã Â¤â€šÃ Â¤â€” Ã Â¤Â°Ã Â¤Â¹Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤ Ã Â¤ÂÃ Â¤Âª Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¸Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾Ã Â¤ÂªÃ Â¤Â¿Ã Â¤Â¤ Ã Â¤â€¢Ã Â¤Â°Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â«Ã Â¤Â¿Ã Â¤Â° Ã Â¤â€¢Ã Â¥â€¹Ã Â¤Â¶Ã Â¤Â¿Ã Â¤Â¶ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤",
      "session_invalid":
          "Ã Â¤Â¸Ã Â¥â€¡Ã Â¤Â¶Ã Â¤Â¨ Ã Â¤â€¦Ã Â¤Â®Ã Â¤Â¾Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¯ Ã Â¤Â¹Ã Â¥Ë† Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾Ã Â¤ÂªÃ Â¤Â¨ Ã Â¤â€¢Ã Â¥â‚¬ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¤Ã Â¥â‚¬Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¾ Ã Â¤Â®Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤ Ã Â¤â€¢Ã Â¥Æ’Ã Â¤ÂªÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¦Ã Â¥â€¹Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â°Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€°Ã Â¤â€”Ã Â¤Â¿Ã Â¤Â¨ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤",
      "rate_limited":
          "Ã Â¤Â¬Ã Â¤Â¹Ã Â¥ÂÃ Â¤Â¤ Ã Â¤â€¦Ã Â¤Â§Ã Â¤Â¿Ã Â¤â€¢ Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â§ Ã Â¤Â­Ã Â¥â€¡Ã Â¤Å“Ã Â¥â€¡ Ã Â¤â€”Ã Â¤ÂÃ Â¥Â¤ Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â°Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¾ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤Â°Ã Â¥â€¹Ã Â¤â€¢ Ã Â¤Â¦Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾Ã Â¥Â¤",
      "connection_error":
          "Ã Â¤â€¢Ã Â¤Â¨Ã Â¥â€¡Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â¶Ã Â¤Â¨ Ã Â¤Â¸Ã Â¤Â®Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¤Â£ Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤ÂªÃ Â¥â€šÃ Â¤Â°Ã Â¤Â¾ Ã Â¤Â¨Ã Â¤Â¹Ã Â¥â‚¬Ã Â¤â€š Ã Â¤Â¹Ã Â¥â€¹ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¾Ã Â¥Â¤",
      "server_error":
          "Instagram Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â°Ã Â¥ÂÃ Â¤Å¸Ã Â¤Â¿ (HTTP {code}) Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¤Â£ Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€¹Ã Â¤Â¡ Ã Â¤Â°Ã Â¥ÂÃ Â¤â€¢ Ã Â¤â€”Ã Â¤Â¯Ã Â¤Â¾Ã Â¥Â¤",
      "story_security_required":
          "Instagram Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â°Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾Ã Â¤ÂªÃ Â¤Â¨ Ã Â¤â€ Ã Â¤ÂµÃ Â¤Â¶Ã Â¥ÂÃ Â¤Â¯Ã Â¤â€¢ Ã Â¤Â¹Ã Â¥Ë† (Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¤ Ã Â¤Â¨Ã Â¤Â¹Ã Â¥â‚¬Ã Â¤â€š Ã Â¤Â¹Ã Â¥â€¹ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¾)Ã Â¥Â¤",
      "story_detail":
          "Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¤ Ã Â¤Â¨Ã Â¤Â¹Ã Â¥â‚¬Ã Â¤â€š Ã Â¤Â¹Ã Â¥â€¹ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¾Ã Â¥Â¤ Ã Â¤â€ Ã Â¤Â®Ã Â¤Â¤Ã Â¥Å’Ã Â¤Â° Ã Â¤ÂªÃ Â¤Â° Ã Â¤Â¯Ã Â¤Â¹ Instagram Ã Â¤Â¸Ã Â¤Â¤Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾Ã Â¤ÂªÃ Â¤Â¨, Ã Â¤â€¦Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â¥Ã Â¤Â¾Ã Â¤Â¯Ã Â¥â‚¬ API Ã Â¤Â¸Ã Â¥â‚¬Ã Â¤Â®Ã Â¤Â¾ Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¨Ã Â¥â€¡Ã Â¤Å¸Ã Â¤ÂµÃ Â¤Â°Ã Â¥ÂÃ Â¤â€¢ Ã Â¤Â¸Ã Â¤Â®Ã Â¤Â¸Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤â€¢Ã Â¤Â¾Ã Â¤Â°Ã Â¤Â£ Ã Â¤Â¹Ã Â¥â€¹Ã Â¤Â¤Ã Â¤Â¾ Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤ 2-3 Ã Â¤Â®Ã Â¤Â¿Ã Â¤Â¨Ã Â¤Å¸ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ Ã Â¤Â«Ã Â¤Â¿Ã Â¤Â° Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â¸ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤",
      "story_generic":
          "Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¾Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¤ Ã Â¤Â¨Ã Â¤Â¹Ã Â¥â‚¬Ã Â¤â€š Ã Â¤Â¹Ã Â¥â€¹ Ã Â¤Â¸Ã Â¤â€¢Ã Â¤Â¾Ã Â¥Â¤ Ã Â¤â€¢Ã Â¥Æ’Ã Â¤ÂªÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤Â¥Ã Â¥â€¹Ã Â¤Â¡Ã Â¤Â¼Ã Â¥â‚¬ Ã Â¤Â¦Ã Â¥â€¡Ã Â¤Â° Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ Ã Â¤Â«Ã Â¤Â¿Ã Â¤Â° Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¯Ã Â¤Â¾Ã Â¤Â¸ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤",
      "secret_mode_label":
          "Ã Â¤Â¸Ã Â¥â‚¬Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â°Ã Â¥â€¡Ã Â¤Å¸ Ã Â¤Â®Ã Â¥â€¹Ã Â¤Â¡",
    },
    "es": {
      "followers_incomplete":
          "Carga interrumpida: datos de seguidores incompletos ({fetched}/{total}).",
      "following_incomplete":
          "Carga interrumpida: datos de seguidos incompletos ({fetched}/{total}).",
      "empty_data": "Carga interrumpida: Instagram devolvio datos vacios.",
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
      "server_error": "Error de Instagram (HTTP {code}). Carga interrumpida.",
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
      "empty_data": "Carga interrumpida: Instagram devolvio datos vacios.",
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
      "server_error": "Error de Instagram (HTTP {code}). Carga interrumpida.",
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
      "server_error": "Erreur Instagram (HTTP {code}). Chargement interrompu.",
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
      "server_error": "Errore Instagram (HTTP {code}). Caricamento interrotto.",
      "story_security_required":
          "Verifica di sicurezza Instagram necessaria (impossibile ottenere i dati story).",
      "story_detail":
          "Impossibile ottenere i dati story. Di solito per verifica Instagram, limite API temporaneo o problema di rete. Riprova tra 2-3 minuti.",
      "story_generic": "Impossibile ottenere i dati story. Riprova tra poco.",
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
      "empty_data": "Laden onderbroken: Instagram gaf lege gegevens terug.",
      "unexpected_error": "Laden onderbroken: onverwachte fout.",
      "automation_warning":
          "Instagram detecteerde geautomatiseerd gedrag. Laden is om veiligheidsredenen gestopt.",
      "security_required":
          "Instagram vereist beveiligingscontrole. Verifieer in de app en probeer opnieuw.",
      "session_invalid":
          "Sessie ongeldig of wacht op verificatie. Log opnieuw in.",
      "rate_limited": "Te veel verzoeken. Laden is uit veiligheid onderbroken.",
      "connection_error":
          "Laden kon niet worden voltooid door een verbindingsprobleem.",
      "server_error": "Instagram-fout (HTTP {code}). Laden onderbroken.",
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
      "empty_data": "Ladowanie przerwane: Instagram zwrocil puste dane.",
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
      "server_error": "Blad Instagram (HTTP {code}). Ladowanie przerwane.",
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
          'Hikayeleri gizlice izle veya profil fotoÃ„Å¸rafÃ„Â±nÃ„Â± bÃƒÂ¼yÃƒÂ¼t',
      'story_login_required':
          'Hikayeleri gizlice izleyebilmek ve profil fotoÃ„Å¸raflarÃ„Â±nÃ„Â± bÃƒÂ¼yÃƒÂ¼tmek iÃƒÂ§in lÃƒÂ¼tfen giriÃ…Å¸ yapÃ„Â±nÃ„Â±z.',
      'story_ad_wait': 'Reklamdan sonra gÃƒÂ¶sterilecek. LÃƒÂ¼tfen bekleyin.',
      'story_action_title': 'Ne yapmak istersiniz?',
      'story_view_photo': 'Profil fotoÃ„Å¸rafÃ„Â±nÃ„Â± bÃƒÂ¼yÃƒÂ¼t',
      'story_watch_secret': 'Hikayeyi gizlice izle',
      'story_no_data': 'Hikaye verisi yok.',
      'story_close': 'KAPAT',
    },
    'en': {
      'story_section_title': 'Watch stories secretly or zoom profile photos',
      'story_login_required':
          'Please log in to watch stories secretly and enlarge profile photos.',
      'story_ad_wait': 'Will be shown after the ad. Please wait.',
      'story_action_title': 'What would you like to do?',
      'story_view_photo': 'Enlarge profile photo',
      'story_watch_secret': 'Watch story secretly',
      'story_no_data': 'No story data available.',
      'story_close': 'CLOSE',
    },
    'de': {
      'story_section_title':
          'Stories heimlich ansehen oder Profilfotos vergrÃƒÂ¶ÃƒÅ¸ern',
      'story_login_required':
          'Bitte melde dich an, um Stories anonym anzusehen und Profilfotos zu vergrÃƒÂ¶ÃƒÅ¸ern.',
      'story_ad_wait': 'Wird nach der Werbung angezeigt. Bitte warten.',
      'story_action_title': 'Was mÃƒÂ¶chtest du tun?',
      'story_view_photo': 'Profilfoto vergrÃƒÂ¶ÃƒÅ¸ern',
      'story_watch_secret': 'Story heimlich ansehen',
      'story_no_data': 'Keine Story-Daten verfÃƒÂ¼gbar.',
      'story_close': 'SCHLIESSEN',
      'adsense_banner': 'WERBEFLÃƒâ€CHE',
      'analysis_available_now': 'Analyse ist jetzt verfÃƒÂ¼gbar.',
      'analysis_fast_no_change':
          'SchnellprÃƒÂ¼fung: Keine Ãƒâ€nderung gefunden.',
      'data_fetch_error':
          'Daten konnten nicht geladen werden: {err}\n\nTipp: Abmelden und erneut anmelden kann helfen.',
      'error_title': 'FEHLER',
      'followers': 'Follower',
      'following': 'Gefolgt',
      'left_followers': 'Verlorene Follower',
      'left_following': 'Entfolgte Konten',
      'new_followers': 'Neue Follower',
      'non_followers': 'Folgen nicht zurÃƒÂ¼ck',
      'premium_not_active':
          'Kauf abgeschlossen, aber Premium ist nicht aktiv. Bitte versuche es erneut.',
      'rate_test_message':
          'GefÃƒÂ¤llt dir die App? Deine Bewertung hilft uns sehr.',
      'redirecting': 'Sitzung bestÃƒÂ¤tigt, du wirst weitergeleitet...',
      'usage_metrics_active': 'Aktive Nutzer',
      'usage_metrics_live': 'live',
      'usage_metrics_na': '--',
      'usage_metrics_queries': 'TÃƒÂ¤gliche Abfragen',
      'usage_metrics_title': 'Tagesmetriken',
      'warning': 'Warnung',
    },
    'ko': {
      'story_section_title':
          'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬Ã«Â¥Â¼ Ã«ÂªÂ°Ã«ÂËœ Ã«Â³Â´ÃªÂ±Â°Ã«â€šËœ Ã­â€â€Ã«Â¡Å“Ã­â€¢â€ Ã¬â€šÂ¬Ã¬Â§â€Ã¬Ââ€ Ã­â„¢â€¢Ã«Å’â‚¬Ã­â€¢ËœÃ¬â€Â¸Ã¬Å¡â€',
      'story_login_required':
          'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬Ã«Â¥Â¼ Ã¬ÂÂµÃ«Âªâ€¦Ã¬Å“Â¼Ã«Â¡Å“ Ã«Â³Â´ÃªÂ³Â  Ã­â€â€Ã«Â¡Å“Ã­â€¢â€ Ã¬â€šÂ¬Ã¬Â§â€Ã¬Ââ€ Ã­â„¢â€¢Ã«Å’â‚¬Ã­â€¢ËœÃ«Â Â¤Ã«Â©Â´ Ã«Â¡Å“ÃªÂ·Â¸Ã¬ÂÂ¸Ã­â€¢Â´ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'story_ad_wait':
          'ÃªÂ´â€˜ÃªÂ³Â  Ã­â€ºâ€ Ã­â€˜Å“Ã¬â€¹Å“Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤. Ã¬ÂÂ Ã¬â€¹Å“Ã«Â§Å’ ÃªÂ¸Â°Ã«â€¹Â¤Ã«Â Â¤ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'story_action_title':
          'Ã«Â¬Â´Ã¬â€”â€¡Ã¬Ââ€ Ã­â€¢ËœÃ¬â€¹Å“ÃªÂ²Â Ã¬â€“Â´Ã¬Å¡â€?',
      'story_view_photo':
          'Ã­â€â€Ã«Â¡Å“Ã­â€¢â€ Ã¬â€šÂ¬Ã¬Â§â€ Ã­â„¢â€¢Ã«Å’â‚¬',
      'story_watch_secret': 'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬ Ã«ÂªÂ°Ã«ÂËœ Ã«Â³Â´ÃªÂ¸Â°',
      'story_no_data':
          'Ã¬Å Â¤Ã­â€ Â Ã«Â¦Â¬ Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°ÃªÂ°â‚¬ Ã¬â€”â€ Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'story_close': 'Ã«â€¹Â«ÃªÂ¸Â°',
      'adsense_banner': 'ÃªÂ´â€˜ÃªÂ³Â  Ã¬ËœÂÃ¬â€”Â­',
      'analysis_available_now':
          'Ã¬Â§â‚¬ÃªÂ¸Ë† Ã«Â¶â€Ã¬â€ÂÃ­â€¢Â  Ã¬Ë†Ëœ Ã¬ÂË†Ã¬â€“Â´Ã¬Å¡â€.',
      'analysis_fast_no_change':
          'Ã«Â¹Â Ã«Â¥Â¸ Ã­â„¢â€¢Ã¬ÂÂ¸: Ã«Â³â‚¬ÃªÂ²Â½ Ã¬â€šÂ¬Ã­â€¢Â­Ã¬ÂÂ´ Ã¬â€”â€ Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤.',
      'data_fetch_error':
          'Ã«ÂÂ°Ã¬ÂÂ´Ã­â€Â°Ã«Â¥Â¼ ÃªÂ°â‚¬Ã¬Â Â¸Ã¬ËœÂ¤Ã¬Â§â‚¬ Ã«ÂªÂ»Ã­â€“Ë†Ã¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤: {err}\\n\\nÃ­Å’Â: Ã«Â¡Å“ÃªÂ·Â¸Ã¬â€¢â€Ã¬â€ºÆ’ Ã­â€ºâ€ Ã«â€¹Â¤Ã¬â€¹Å“ Ã«Â¡Å“ÃªÂ·Â¸Ã¬ÂÂ¸Ã­â€¢Â´ Ã«Â³Â´Ã¬â€Â¸Ã¬Å¡â€.',
      'error_title': 'Ã¬ËœÂ¤Ã«Â¥Ëœ',
      'followers': 'Ã­Å’â€Ã«Â¡Å“Ã¬â€ºÅ’',
      'following': 'Ã­Å’â€Ã«Â¡Å“Ã¬Ââ€°',
      'left_followers': 'Ã«â€“Â Ã«â€šÅ“ Ã­Å’â€Ã«Â¡Å“Ã¬â€ºÅ’',
      'left_following': 'Ã¬â€“Â¸Ã­Å’â€Ã«Â¡Å“Ã¬Å¡Â°Ã­â€¢Å“ ÃªÂ³â€Ã¬Â â€¢',
      'new_followers': 'Ã¬Æ’Ë† Ã­Å’â€Ã«Â¡Å“Ã¬â€ºÅ’',
      'non_followers':
          'Ã«Â§ÂÃ­Å’â€Ã­â€¢ËœÃ¬Â§â‚¬ Ã¬â€¢Å Ã«Å â€ ÃªÂ³â€Ã¬Â â€¢',
      'premium_not_active':
          'ÃªÂµÂ¬Ã«Â§Â¤Ã«Å â€ Ã¬â„¢â€Ã«Â£Å’Ã«ÂËœÃ¬â€”Ë†Ã¬Â§â‚¬Ã«Â§Å’ Ã­â€â€Ã«Â¦Â¬Ã«Â¯Â¸Ã¬â€”â€Ã¬ÂÂ´ Ã­â„¢Å“Ã¬â€Â±Ã­â„¢â€Ã«ÂËœÃ¬Â§â‚¬ Ã¬â€¢Å Ã¬â€¢ËœÃ¬Å ÂµÃ«â€¹Ë†Ã«â€¹Â¤. Ã«â€¹Â¤Ã¬â€¹Å“ Ã¬â€¹Å“Ã«Ââ€Ã­â€¢Â´ Ã¬Â£Â¼Ã¬â€Â¸Ã¬Å¡â€.',
      'rate_test_message':
          'Ã¬â€¢Â±Ã¬ÂÂ´ Ã«Â§Ë†Ã¬ÂÅ’Ã¬â€”Â Ã«â€œÅ“Ã¬â€¹Å“Ã«â€šËœÃ¬Å¡â€? Ã­Ââ€°Ã¬Â ÂÃ¬ÂÂ´ Ã­ÂÂ° Ã«Ââ€Ã¬â€ºâ‚¬Ã¬ÂÂ´ Ã«ÂÂ©Ã«â€¹Ë†Ã«â€¹Â¤.',
      'redirecting':
          'Ã¬â€Â¸Ã¬â€¦ËœÃ¬ÂÂ´ Ã­â„¢â€¢Ã¬ÂÂ¸Ã«ÂËœÃ¬â€“Â´ Ã¬ÂÂ´Ã«Ââ„¢ Ã¬Â¤â€˜Ã¬Ââ€¦Ã«â€¹Ë†Ã«â€¹Â¤...',
      'usage_metrics_active': 'Ã­â„¢Å“Ã¬â€Â± Ã¬â€šÂ¬Ã¬Å¡Â©Ã¬ÂÂ',
      'usage_metrics_live': 'Ã¬â€¹Â¤Ã¬â€¹Å“ÃªÂ°â€',
      'usage_metrics_na': '--',
      'usage_metrics_queries': 'Ã¬ÂÂ¼Ã¬ÂÂ¼ Ã¬Â¡Â°Ã­Å¡Å’ Ã¬Ë†Ëœ',
      'usage_metrics_title': 'Ã¬ÂÂ¼Ã¬ÂÂ¼ Ã¬Â§â‚¬Ã­â€˜Å“',
      'warning': 'ÃƒÂªÃ‚Â²Ã‚Â½ÃƒÂªÃ‚Â³Ã‚Â ',
    },
    'ja': {
      'story_section_title':
          'Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£â€šâ€™Ã£Ââ€œÃ£ÂÂ£Ã£ÂÂÃ£â€šÅ Ã¨Â¦â€¹Ã£â€šâ€¹ / Ã£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ£Ã£Æ’Â¼Ã£Æ’Â«Ã¥â€ â„¢Ã§Å“Å¸Ã£â€šâ€™Ã¦â€¹Â¡Ã¥Â¤Â§',
      'story_login_required':
          'Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£â€šâ€™Ã¥Å’Â¿Ã¥ÂÂÃ£ÂÂ§Ã¨Â¦â€¹Ã£ÂÅ¸Ã£â€šÅ Ã£â‚¬ÂÃ£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ£Ã£Æ’Â¼Ã£Æ’Â«Ã¥â€ â„¢Ã§Å“Å¸Ã£â€šâ€™Ã¦â€¹Â¡Ã¥Â¤Â§Ã£Ââ€”Ã£ÂÅ¸Ã£â€šÅ Ã£Ââ„¢Ã£â€šâ€¹Ã£ÂÂ«Ã£ÂÂ¯Ã£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¤Ã£Æ’Â³Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'story_ad_wait':
          'Ã¥ÂºÆ’Ã¥â€˜Å Ã£ÂÂ®Ã¥Â¾Å’Ã£ÂÂ«Ã¨Â¡Â¨Ã§Â¤ÂºÃ£Ââ€¢Ã£â€šÅ’Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€šÃ£Ââ€”Ã£ÂÂ°Ã£â€šâ€°Ã£ÂÂÃ£ÂÅ Ã¥Â¾â€¦Ã£ÂÂ¡Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'story_action_title': 'Ã£ÂÂ©Ã£Ââ€ Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ„¢Ã£Ââ€¹Ã¯Â¼Å¸',
      'story_view_photo':
          'Ã£Æ’â€”Ã£Æ’Â­Ã£Æ’â€¢Ã£â€šÂ£Ã£Æ’Â¼Ã£Æ’Â«Ã¥â€ â„¢Ã§Å“Å¸Ã£â€šâ€™Ã¦â€¹Â¡Ã¥Â¤Â§',
      'story_watch_secret':
          'Ã¨Â¶Â³Ã¨Â·Â¡Ã£â€šâ€™Ã¦Â®â€¹Ã£Ââ€¢Ã£ÂÅ¡Ã¨Â¦â€¹Ã£â€šâ€¹',
      'story_no_data':
          'Ã£â€šÂ¹Ã£Æ’Ë†Ã£Æ’Â¼Ã£Æ’ÂªÃ£Æ’Â¼Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£ÂÅ’Ã£Ââ€šÃ£â€šÅ Ã£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£â‚¬â€š',
      'story_close': 'Ã©â€“â€°Ã£ÂËœÃ£â€šâ€¹',
      'adsense_banner': 'Ã¥ÂºÆ’Ã¥â€˜Å Ã¦ÂÂ ',
      'analysis_available_now':
          'Ã¤Â»Å Ã£Ââ„¢Ã£ÂÂÃ¥Ë†â€ Ã¦ÂÂÃ£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'analysis_fast_no_change':
          'Ã£â€šÂ¯Ã£â€šÂ¤Ã£Æ’Æ’Ã£â€šÂ¯Ã§Â¢ÂºÃ¨ÂªÂ: Ã¥Â¤â€°Ã¦â€ºÂ´Ã£ÂÂ¯Ã¨Â¦â€¹Ã£ÂÂ¤Ã£Ââ€¹Ã£â€šÅ Ã£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£ÂÂ§Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€š',
      'data_fetch_error':
          'Ã£Æ’â€¡Ã£Æ’Â¼Ã£â€šÂ¿Ã£â€šâ€™Ã¥Ââ€“Ã¥Â¾â€”Ã£ÂÂ§Ã£ÂÂÃ£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£ÂÂ§Ã£Ââ€”Ã£ÂÅ¸: {err}\\n\\nÃ£Æ’â€™Ã£Æ’Â³Ã£Æ’Ë†: Ã£Ââ€Ã£ÂÂ£Ã£ÂÅ¸Ã£â€šâ€œÃ£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¢Ã£â€šÂ¦Ã£Æ’Ë†Ã£Ââ€”Ã£ÂÂ¦Ã¥â€ ÂÃ£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¤Ã£Æ’Â³Ã£Ââ„¢Ã£â€šâ€¹Ã£ÂÂ¨Ã¦â€Â¹Ã¥â€“â€Ã£Ââ„¢Ã£â€šâ€¹Ã¥Â Â´Ã¥ÂË†Ã£ÂÅ’Ã£Ââ€šÃ£â€šÅ Ã£ÂÂ¾Ã£Ââ„¢Ã£â‚¬â€š',
      'error_title': 'Ã£â€šÂ¨Ã£Æ’Â©Ã£Æ’Â¼',
      'followers': 'Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¯Ã£Æ’Â¼',
      'following': 'Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¼Ã¤Â¸Â­',
      'left_followers': 'Ã©â€ºÂ¢Ã£â€šÅ’Ã£ÂÅ¸Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¯Ã£Æ’Â¼',
      'left_following':
          'Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¼Ã¨Â§Â£Ã©â„¢Â¤Ã£Ââ€”Ã£ÂÅ¸Ã£â€šÂ¢Ã£â€šÂ«Ã£â€šÂ¦Ã£Æ’Â³Ã£Æ’Ë†',
      'new_followers': 'Ã¦â€“Â°Ã£Ââ€”Ã£Ââ€Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¯Ã£Æ’Â¼',
      'non_followers':
          'Ã£Æ’â€¢Ã£â€šÂ©Ã£Æ’Â­Ã£Æ’Â¼Ã£Æ’ÂÃ£Æ’Æ’Ã£â€šÂ¯Ã£Ââ€”Ã£ÂÂ¦Ã£Ââ€Ã£ÂÂªÃ£Ââ€Ã£Æ’Â¦Ã£Æ’Â¼Ã£â€šÂ¶Ã£Æ’Â¼',
      'premium_not_active':
          'Ã¨Â³Â¼Ã¥â€¦Â¥Ã£ÂÂ¯Ã¥Â®Å’Ã¤Âºâ€ Ã£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£ÂÅ’Ã£â‚¬ÂÃ£Æ’â€”Ã£Æ’Â¬Ã£Æ’Å¸Ã£â€šÂ¢Ã£Æ’Â Ã£ÂÅ’Ã¦Å“â€°Ã¥Å Â¹Ã£ÂÂ«Ã£ÂÂªÃ£ÂÂ£Ã£ÂÂ¦Ã£Ââ€Ã£ÂÂ¾Ã£Ââ€ºÃ£â€šâ€œÃ£â‚¬â€šÃ£â€šâ€šÃ£Ââ€ Ã¤Â¸â‚¬Ã¥ÂºÂ¦Ã£ÂÅ Ã¨Â©Â¦Ã£Ââ€”Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'rate_test_message':
          'Ã£Ââ€œÃ£ÂÂ®Ã£â€šÂ¢Ã£Æ’â€”Ã£Æ’ÂªÃ£ÂÂ¯Ã¥Â½Â¹Ã£ÂÂ«Ã§Â«â€¹Ã£ÂÂ¡Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£Ââ€¹Ã¯Â¼Å¸Ã¨Â©â€¢Ã¤Â¾Â¡Ã£ÂÂ§Ã¥Â¿Å“Ã¦ÂÂ´Ã£Ââ€”Ã£ÂÂ¦Ã£ÂÂÃ£ÂÂ Ã£Ââ€¢Ã£Ââ€Ã£â‚¬â€š',
      'redirecting':
          'Ã£â€šÂ»Ã£Æ’Æ’Ã£â€šÂ·Ã£Æ’Â§Ã£Æ’Â³Ã£â€šâ€™Ã§Â¢ÂºÃ¨ÂªÂÃ£Ââ€”Ã£ÂÂ¾Ã£Ââ€”Ã£ÂÅ¸Ã£â‚¬â€šÃ£Æ’ÂªÃ£Æ’â‚¬Ã£â€šÂ¤Ã£Æ’Â¬Ã£â€šÂ¯Ã£Æ’Ë†Ã£Ââ€”Ã£ÂÂ¦Ã£Ââ€Ã£ÂÂ¾Ã£Ââ„¢...',
      'usage_metrics_active':
          'Ã£â€šÂ¢Ã£â€šÂ¯Ã£Æ’â€ Ã£â€šÂ£Ã£Æ’â€“Ã£Æ’Â¦Ã£Æ’Â¼Ã£â€šÂ¶Ã£Æ’Â¼',
      'usage_metrics_live': 'Ã£Æ’Â©Ã£â€šÂ¤Ã£Æ’â€“',
      'usage_metrics_na': '--',
      'usage_metrics_queries': '1Ã¦â€”Â¥Ã£ÂÂ®Ã£â€šÂ¯Ã£â€šÂ¨Ã£Æ’ÂªÃ¦â€¢Â°',
      'usage_metrics_title': 'Ã¦â€”Â¥Ã¦Â¬Â¡Ã£Æ’Â¡Ã£Æ’Ë†Ã£Æ’ÂªÃ£â€šÂ¯Ã£â€šÂ¹',
      'warning': 'Ã¨Â­Â¦Ã¥â€˜Å ',
    },
    'ru': {
      'story_section_title':
          'ÄÂ¡ÄÂ¼ÄÂ¾Ã‘â€šÃ‘â‚¬ÄÂµÃ‘â€šÃ‘Å’ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ°ÄÂ½ÄÂ¾ÄÂ½ÄÂ¸ÄÂ¼ÄÂ½ÄÂ¾ ÄÂ¸ÄÂ»ÄÂ¸ Ã‘Æ’ÄÂ²ÄÂµÄÂ»ÄÂ¸Ã‘â€¡ÄÂ¸Ã‘â€šÃ‘Å’ Ã‘â€ÄÂ¾Ã‘â€šÄÂ¾ ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂ¸ÄÂ»Ã‘Â',
      'story_login_required':
          'ÄÅ¸ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ²ÄÂ¾ÄÂ¹ÄÂ´ÄÂ¸Ã‘â€šÄÂµ, Ã‘â€¡Ã‘â€šÄÂ¾ÄÂ±Ã‘â€¹ ÄÂ°ÄÂ½ÄÂ¾ÄÂ½ÄÂ¸ÄÂ¼ÄÂ½ÄÂ¾ Ã‘ÂÄÂ¼ÄÂ¾Ã‘â€šÃ‘â‚¬ÄÂµÃ‘â€šÃ‘Å’ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ¸ Ã‘Æ’ÄÂ²ÄÂµÄÂ»ÄÂ¸Ã‘â€¡ÄÂ¸ÄÂ²ÄÂ°Ã‘â€šÃ‘Å’ Ã‘â€ÄÂ¾Ã‘â€šÄÂ¾ ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂ¸ÄÂ»Ã‘Â.',
      'story_ad_wait':
          'ÄÅ¸ÄÂ¾Ã‘ÂÄÂ²ÄÂ¸Ã‘â€šÃ‘ÂÃ‘Â ÄÂ¿ÄÂ¾Ã‘ÂÄÂ»ÄÂµ Ã‘â‚¬ÄÂµÄÂºÄÂ»ÄÂ°ÄÂ¼Ã‘â€¹. ÄÅ¸ÄÂ¾ÄÂ¶ÄÂ°ÄÂ»Ã‘Æ’ÄÂ¹Ã‘ÂÃ‘â€šÄÂ°, ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¾ÄÂ¶ÄÂ´ÄÂ¸Ã‘â€šÄÂµ.',
      'story_action_title':
          'ÄÂ§Ã‘â€šÄÂ¾ Ã‘â€¦ÄÂ¾Ã‘â€šÄÂ¸Ã‘â€šÄÂµ Ã‘ÂÄÂ´ÄÂµÄÂ»ÄÂ°Ã‘â€šÃ‘Å’?',
      'story_view_photo':
          'ÄÂ£ÄÂ²ÄÂµÄÂ»ÄÂ¸Ã‘â€¡ÄÂ¸Ã‘â€šÃ‘Å’ Ã‘â€ÄÂ¾Ã‘â€šÄÂ¾ ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘â€ÄÂ¸ÄÂ»Ã‘Â',
      'story_watch_secret':
          'ÄÂ¡ÄÂ¼ÄÂ¾Ã‘â€šÃ‘â‚¬ÄÂµÃ‘â€šÃ‘Å’ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ°ÄÂ½ÄÂ¾ÄÂ½ÄÂ¸ÄÂ¼ÄÂ½ÄÂ¾',
      'story_no_data':
          'Äâ€ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ Ã‘ÂÃ‘â€šÄÂ¾Ã‘â‚¬ÄÂ¸Ã‘Â ÄÂ½ÄÂµÄÂ´ÄÂ¾Ã‘ÂÃ‘â€šÃ‘Æ’ÄÂ¿ÄÂ½Ã‘â€¹.',
      'story_close': 'Äâ€”ÄÂÄÅ¡ÄÂ ÄÂ«ÄÂ¢ÄÂ¬',
      'adsense_banner':
          'ÄÂ Äâ€¢ÄÅ¡Äâ€ºÄÂÄÅ“ÄÂÄÂÄâ€¢ ÄÅ“Äâ€¢ÄÂ¡ÄÂ¢ÄÂ',
      'analysis_available_now':
          'ÄÂÄÂ½ÄÂ°ÄÂ»ÄÂ¸ÄÂ· ÄÂ´ÄÂ¾Ã‘ÂÃ‘â€šÃ‘Æ’ÄÂ¿ÄÂµÄÂ½ Ã‘ÂÄÂµÄÂ¹Ã‘â€¡ÄÂ°Ã‘Â.',
      'analysis_fast_no_change':
          'Äâ€˜Ã‘â€¹Ã‘ÂÃ‘â€šÃ‘â‚¬ÄÂ°Ã‘Â ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ²ÄÂµÃ‘â‚¬ÄÂºÄÂ°: ÄÂ¸ÄÂ·ÄÂ¼ÄÂµÄÂ½ÄÂµÄÂ½ÄÂ¸ÄÂ¹ ÄÂ½ÄÂµ ÄÂ½ÄÂ°ÄÂ¹ÄÂ´ÄÂµÄÂ½ÄÂ¾.',
      'data_fetch_error':
          'ÄÂÄÂµ Ã‘Æ’ÄÂ´ÄÂ°ÄÂ»ÄÂ¾Ã‘ÂÃ‘Å’ ÄÂ¿ÄÂ¾ÄÂ»Ã‘Æ’Ã‘â€¡ÄÂ¸Ã‘â€šÃ‘Å’ ÄÂ´ÄÂ°ÄÂ½ÄÂ½Ã‘â€¹ÄÂµ: {err}\\n\\nÄÂ¡ÄÂ¾ÄÂ²ÄÂµÃ‘â€š: ÄÂ²Ã‘â€¹ÄÂ¹ÄÂ´ÄÂ¸Ã‘â€šÄÂµ ÄÂ¸ ÄÂ²ÄÂ¾ÄÂ¹ÄÂ´ÄÂ¸Ã‘â€šÄÂµ Ã‘ÂÄÂ½ÄÂ¾ÄÂ²ÄÂ°.',
      'error_title': 'ÄÂÄÂ¨ÄËœÄâ€˜ÄÅ¡ÄÂ',
      'followers': 'ÄÅ¸ÄÂ¾ÄÂ´ÄÂ¿ÄÂ¸Ã‘ÂÃ‘â€¡ÄÂ¸ÄÂºÄÂ¸',
      'following': 'ÄÅ¸ÄÂ¾ÄÂ´ÄÂ¿ÄÂ¸Ã‘ÂÄÂºÄÂ¸',
      'left_followers': 'ÄÂÃ‘â€šÄÂ¿ÄÂ¸Ã‘ÂÄÂ°ÄÂ²Ã‘Ë†ÄÂ¸ÄÂµÃ‘ÂÃ‘Â',
      'left_following':
          'Äâ€™Ã‘â€¹ ÄÂ¿ÄÂµÃ‘â‚¬ÄÂµÃ‘ÂÃ‘â€šÄÂ°ÄÂ»ÄÂ¸ Ã‘â€¡ÄÂ¸Ã‘â€šÄÂ°Ã‘â€šÃ‘Å’',
      'new_followers':
          'ÄÂÄÂ¾ÄÂ²Ã‘â€¹ÄÂµ ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¿ÄÂ¸Ã‘ÂÃ‘â€¡ÄÂ¸ÄÂºÄÂ¸',
      'non_followers':
          'ÄÂÄÂµ ÄÂ¿ÄÂ¾ÄÂ´ÄÂ¿ÄÂ¸Ã‘ÂÄÂ°ÄÂ½Ã‘â€¹ ÄÂ² ÄÂ¾Ã‘â€šÄÂ²ÄÂµÃ‘â€š',
      'premium_not_active':
          'ÄÅ¸ÄÂ¾ÄÂºÃ‘Æ’ÄÂ¿ÄÂºÄÂ° ÄÂ·ÄÂ°ÄÂ²ÄÂµÃ‘â‚¬Ã‘Ë†ÄÂµÄÂ½ÄÂ°, ÄÂ½ÄÂ¾ Premium ÄÂ½ÄÂµ ÄÂ°ÄÂºÃ‘â€šÄÂ¸ÄÂ²ÄÂµÄÂ½. ÄÅ¸ÄÂ¾ÄÂ¿Ã‘â‚¬ÄÂ¾ÄÂ±Ã‘Æ’ÄÂ¹Ã‘â€šÄÂµ Ã‘ÂÄÂ½ÄÂ¾ÄÂ²ÄÂ°.',
      'rate_test_message':
          'ÄÂÃ‘â‚¬ÄÂ°ÄÂ²ÄÂ¸Ã‘â€šÃ‘ÂÃ‘Â ÄÂ¿Ã‘â‚¬ÄÂ¸ÄÂ»ÄÂ¾ÄÂ¶ÄÂµÄÂ½ÄÂ¸ÄÂµ? Äâ€™ÄÂ°Ã‘Ë†ÄÂ° ÄÂ¾Ã‘â€ ÄÂµÄÂ½ÄÂºÄÂ° ÄÂ¾Ã‘â€¡ÄÂµÄÂ½Ã‘Å’ ÄÂ¿ÄÂ¾ÄÂ¼ÄÂ¾ÄÂ³ÄÂ°ÄÂµÃ‘â€š.',
      'redirecting':
          'ÄÂ¡ÄÂµÃ‘ÂÃ‘ÂÄÂ¸Ã‘Â ÄÂ¿ÄÂ¾ÄÂ´Ã‘â€šÄÂ²ÄÂµÃ‘â‚¬ÄÂ¶ÄÂ´ÄÂµÄÂ½ÄÂ°, ÄÂ²Ã‘â€¹ÄÂ¿ÄÂ¾ÄÂ»ÄÂ½Ã‘ÂÄÂµÃ‘â€šÃ‘ÂÃ‘Â ÄÂ¿ÄÂµÃ‘â‚¬ÄÂµÃ‘â€¦ÄÂ¾ÄÂ´...',
      'usage_metrics_active':
          'ÄÂÄÂºÃ‘â€šÄÂ¸ÄÂ²ÄÂ½Ã‘â€¹ÄÂµ ÄÂ¿ÄÂ¾ÄÂ»Ã‘Å’ÄÂ·ÄÂ¾ÄÂ²ÄÂ°Ã‘â€šÄÂµÄÂ»ÄÂ¸',
      'usage_metrics_live':
          'ÄÂ² Ã‘â‚¬ÄÂµÄÂ°ÄÂ»Ã‘Å’ÄÂ½ÄÂ¾ÄÂ¼ ÄÂ²Ã‘â‚¬ÄÂµÄÂ¼ÄÂµÄÂ½ÄÂ¸',
      'usage_metrics_na': '--',
      'usage_metrics_queries':
          'Äâ€”ÄÂ°ÄÂ¿Ã‘â‚¬ÄÂ¾Ã‘ÂÄÂ¾ÄÂ² ÄÂ·ÄÂ° ÄÂ´ÄÂµÄÂ½Ã‘Å’',
      'usage_metrics_title':
          'Äâ€ÄÂ½ÄÂµÄÂ²ÄÂ½Ã‘â€¹ÄÂµ ÄÂ¼ÄÂµÃ‘â€šÃ‘â‚¬ÄÂ¸ÄÂºÄÂ¸',
      'warning': 'ÄÅ¸Ã‘â‚¬ÄÂµÄÂ´Ã‘Æ’ÄÂ¿Ã‘â‚¬ÄÂµÄÂ¶ÄÂ´ÄÂµÄÂ½ÄÂ¸ÄÂµ',
    },
    'pt': {
      'story_section_title': 'Ver stories em segredo ou ampliar foto de perfil',
      'story_login_required':
          'FaÃƒÂ§a login para ver stories anonimamente e ampliar fotos de perfil.',
      'story_ad_wait': 'SerÃƒÂ¡ exibido apÃƒÂ³s o anÃƒÂºncio. Aguarde.',
      'story_action_title': 'O que vocÃƒÂª quer fazer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver story em segredo',
      'story_no_data': 'NÃƒÂ£o hÃƒÂ¡ dados de story disponÃƒÂ­veis.',
      'story_close': 'FECHAR',
      'adsense_banner': 'ESPAÃƒâ€¡O DE ANÃƒÅ¡NCIO',
      'analysis_available_now': 'AnÃƒÂ¡lise disponÃƒÂ­vel agora.',
      'analysis_fast_no_change':
          'VerificaÃƒÂ§ÃƒÂ£o rÃƒÂ¡pida: nenhuma alteraÃƒÂ§ÃƒÂ£o encontrada.',
      'data_fetch_error':
          'NÃƒÂ£o foi possÃƒÂ­vel obter os dados: {err}\\n\\nDica: sair e entrar novamente pode ajudar.',
      'error_title': 'ERRO',
      'followers': 'Seguidores',
      'following': 'Seguindo',
      'left_followers': 'Perdeu seguidores',
      'left_following': 'Deixou de seguir',
      'new_followers': 'Novos seguidores',
      'non_followers': 'NÃƒÂ£o seguem de volta',
      'premium_not_active':
          'Compra concluÃƒÂ­da, mas o Premium nÃƒÂ£o foi ativado. Tente novamente.',
      'rate_test_message':
          'EstÃƒÂ¡ gostando do app? Sua avaliaÃƒÂ§ÃƒÂ£o ajuda muito.',
      'redirecting': 'SessÃƒÂ£o verificada, redirecionando...',
      'usage_metrics_active': 'UsuÃƒÂ¡rios ativos',
      'usage_metrics_live': 'ao vivo',
      'usage_metrics_na': '--',
      'usage_metrics_queries': 'Consultas diÃƒÂ¡rias',
      'usage_metrics_title': 'MÃƒÂ©tricas diÃƒÂ¡rias',
      'warning': 'Aviso',
    },
    'ar': {
      'story_section_title':
          'Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯ Ã˜Â§Ã™â€Ã™â€šÃ˜ÂµÃ˜Âµ Ã˜Â¨Ã˜Â³Ã˜Â±Ã™Å Ã˜Â© Ã˜Â£Ã™Ë† Ã™Æ’Ã˜Â¨Ã™â€˜Ã˜Â± Ã˜ÂµÃ™Ë†Ã˜Â±Ã˜Â© Ã˜Â§Ã™â€Ã™â€¦Ã™â€Ã™Â Ã˜Â§Ã™â€Ã˜Â´Ã˜Â®Ã˜ÂµÃ™Å ',
      'story_login_required':
          'Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜ÂªÃ˜Â³Ã˜Â¬Ã™Å Ã™â€ Ã˜Â§Ã™â€Ã˜Â¯Ã˜Â®Ã™Ë†Ã™â€ Ã™â€Ã™â€¦Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€Ã™â€šÃ˜ÂµÃ˜Âµ Ã˜Â¨Ã˜Â´Ã™Æ’Ã™â€ Ã˜Â³Ã˜Â±Ã™Å  Ã™Ë†Ã˜ÂªÃ™Æ’Ã˜Â¨Ã™Å Ã˜Â± Ã˜ÂµÃ™Ë†Ã˜Â± Ã˜Â§Ã™â€Ã™â€¦Ã™â€Ã™Â Ã˜Â§Ã™â€Ã˜Â´Ã˜Â®Ã˜ÂµÃ™Å .',
      'story_ad_wait':
          'Ã˜Â³Ã™Å Ã˜Â¸Ã™â€¡Ã˜Â± Ã˜Â¨Ã˜Â¹Ã˜Â¯ Ã˜Â§Ã™â€Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€ . Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â§Ã™â€Ã˜Â§Ã™â€ Ã˜ÂªÃ˜Â¸Ã˜Â§Ã˜Â±.',
      'story_action_title':
          'Ã™â€¦Ã˜Â§Ã˜Â°Ã˜Â§ Ã˜ÂªÃ˜Â±Ã™Å Ã˜Â¯ Ã˜Â£Ã™â€  Ã˜ÂªÃ™ÂÃ˜Â¹Ã™â€Ã˜Å¸',
      'story_view_photo':
          'Ã˜ÂªÃ™Æ’Ã˜Â¨Ã™Å Ã˜Â± Ã˜ÂµÃ™Ë†Ã˜Â±Ã˜Â© Ã˜Â§Ã™â€Ã™â€¦Ã™â€Ã™Â Ã˜Â§Ã™â€Ã˜Â´Ã˜Â®Ã˜ÂµÃ™Å ',
      'story_watch_secret':
          'Ã™â€¦Ã˜Â´Ã˜Â§Ã™â€¡Ã˜Â¯Ã˜Â© Ã˜Â§Ã™â€Ã™â€šÃ˜ÂµÃ˜Â© Ã˜Â¨Ã˜Â³Ã˜Â±Ã™Å Ã˜Â©',
      'story_no_data':
          'Ã™â€Ã˜Â§ Ã˜ÂªÃ˜ÂªÃ™Ë†Ã™ÂÃ˜Â± Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™â€šÃ˜ÂµÃ˜Â©.',
      'story_close': 'Ã˜Â¥Ã˜ÂºÃ™â€Ã˜Â§Ã™â€š',
      'adsense_banner': 'Ã™â€¦Ã˜Â³Ã˜Â§Ã˜Â­Ã˜Â© Ã˜Â¥Ã˜Â¹Ã™â€Ã˜Â§Ã™â€ Ã™Å Ã˜Â©',
      'analysis_available_now':
          'Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€ Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â­ Ã˜Â§Ã™â€Ã˜Â¢Ã™â€ .',
      'analysis_fast_no_change':
          'Ã™ÂÃ˜Â­Ã˜Âµ Ã˜Â³Ã˜Â±Ã™Å Ã˜Â¹: Ã™â€Ã˜Â§ Ã˜ÂªÃ™Ë†Ã˜Â¬Ã˜Â¯ Ã˜ÂªÃ˜ÂºÃ™Å Ã™Å Ã˜Â±Ã˜Â§Ã˜Âª.',
      'data_fetch_error':
          'Ã˜ÂªÃ˜Â¹Ã˜Â°Ã™â€˜Ã˜Â± Ã˜Â¬Ã™â€Ã˜Â¨ Ã˜Â§Ã™â€Ã˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª: {err}\\n\\nÃ™â€ Ã˜ÂµÃ™Å Ã˜Â­Ã˜Â©: Ã˜Â³Ã˜Â¬Ã™â€˜Ã™â€ Ã˜Â§Ã™â€Ã˜Â®Ã˜Â±Ã™Ë†Ã˜Â¬ Ã˜Â«Ã™â€¦ Ã˜Â³Ã˜Â¬Ã™â€˜Ã™â€ Ã˜Â§Ã™â€Ã˜Â¯Ã˜Â®Ã™Ë†Ã™â€ Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°.',
      'error_title': 'ÃƒËœÃ‚Â®ÃƒËœÃ‚Â·ÃƒËœÃ‚Â£',
      'followers': 'Ã˜Â§Ã™â€Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¨Ã˜Â¹Ã™Ë†Ã™â€ ',
      'following': 'ÃƒËœÃ‚ÂªÃƒËœÃ‚ÂªÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¹',
      'left_followers':
          'Ã™â€¦Ã™â€  Ã˜Â£Ã™â€Ã˜ÂºÃ™â€° Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¨Ã˜Â¹Ã˜ÂªÃ™Æ’',
      'left_following':
          'Ã˜Â£Ã™â€Ã˜ÂºÃ™Å Ã˜Âª Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¨Ã˜Â¹Ã˜ÂªÃ™â€¡Ã™â€¦',
      'new_followers': 'Ã™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¨Ã˜Â¹Ã™Ë†Ã™â€  Ã˜Â¬Ã˜Â¯Ã˜Â¯',
      'non_followers':
          'Ã™â€Ã˜Â§ Ã™Å Ã˜ÂªÃ˜Â§Ã˜Â¨Ã˜Â¹Ã™Ë†Ã™â€ Ã™Æ’ Ã˜Â¨Ã˜Â§Ã™â€Ã™â€¦Ã™â€šÃ˜Â§Ã˜Â¨Ã™â€',
      'premium_not_active':
          'Ã˜Â§Ã™Æ’Ã˜ÂªÃ™â€¦Ã™â€Ã˜Âª Ã˜Â¹Ã™â€¦Ã™â€Ã™Å Ã˜Â© Ã˜Â§Ã™â€Ã˜Â´Ã˜Â±Ã˜Â§Ã˜Â¡ Ã™â€Ã™Æ’Ã™â€  Ã™â€Ã™â€¦ Ã™Å Ã˜ÂªÃ™â€¦ Ã˜ÂªÃ™ÂÃ˜Â¹Ã™Å Ã™â€ Premium. Ã˜Â­Ã˜Â§Ã™Ë†Ã™â€ Ã™â€¦Ã˜Â±Ã˜Â© Ã˜Â£Ã˜Â®Ã˜Â±Ã™â€°.',
      'rate_test_message':
          'Ã™â€¡Ã™â€ Ã˜Â£Ã˜Â¹Ã˜Â¬Ã˜Â¨Ã™Æ’ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â·Ã˜Â¨Ã™Å Ã™â€šÃ˜Å¸ Ã˜ÂªÃ™â€šÃ™Å Ã™Å Ã™â€¦Ã™Æ’ Ã™Å Ã˜Â³Ã˜Â§Ã˜Â¹Ã˜Â¯Ã™â€ Ã˜Â§ Ã™Æ’Ã˜Â«Ã™Å Ã˜Â±Ã™â€¹Ã˜Â§.',
      'redirecting':
          'Ã˜ÂªÃ™â€¦ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€šÃ™â€š Ã™â€¦Ã™â€  Ã˜Â§Ã™â€Ã˜Â¬Ã™â€Ã˜Â³Ã˜Â©Ã˜Å’ Ã˜Â¬Ã˜Â§Ã˜Â±Ã™Â Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™Ë†Ã™Å Ã™â€...',
      'usage_metrics_active':
          'Ã˜Â§Ã™â€Ã™â€¦Ã˜Â³Ã˜ÂªÃ˜Â®Ã˜Â¯Ã™â€¦Ã™Ë†Ã™â€  Ã˜Â§Ã™â€Ã™â€ Ã˜Â´Ã˜Â·Ã™Ë†Ã™â€ ',
      'usage_metrics_live': 'Ã™â€¦Ã˜Â¨Ã˜Â§Ã˜Â´Ã˜Â±',
      'usage_metrics_na': '--',
      'usage_metrics_queries':
          'Ã˜Â¹Ã˜Â¯Ã˜Â¯ Ã˜Â§Ã™â€Ã˜ÂªÃ˜Â­Ã™â€Ã™Å Ã™â€Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™Å Ã™Ë†Ã™â€¦Ã™Å Ã˜Â©',
      'usage_metrics_title':
          'Ã˜Â¥Ã˜Â­Ã˜ÂµÃ˜Â§Ã˜Â¡Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€Ã™Å Ã™Ë†Ã™â€¦',
      'warning': 'Ã˜ÂªÃ˜Â­Ã˜Â°Ã™Å Ã˜Â±',
    },
    'es': {
      'story_section_title':
          'Ver historias en secreto o ampliar foto de perfil',
      'story_login_required':
          'Inicia sesiÃƒÂ³n para ver historias en modo anÃƒÂ³nimo y ampliar fotos de perfil.',
      'story_ad_wait':
          'Se mostrarÃƒÂ¡ despuÃƒÂ©s del anuncio. Espera un momento.',
      'story_action_title': 'Ã‚Â¿QuÃƒÂ© te gustarÃƒÂ­a hacer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver historia en secreto',
      'story_no_data': 'No hay datos de historias disponibles.',
      'story_close': 'CERRAR',
    },
    'es-mx': {
      'story_section_title':
          'Ver historias en secreto o ampliar foto de perfil',
      'story_login_required':
          'Inicia sesiÃƒÂ³n para ver historias en modo anÃƒÂ³nimo y ampliar fotos de perfil.',
      'story_ad_wait':
          'Se mostrarÃƒÂ¡ despuÃƒÂ©s del anuncio. Espera un momento.',
      'story_action_title': 'Ã‚Â¿QuÃƒÂ© te gustarÃƒÂ­a hacer?',
      'story_view_photo': 'Ampliar foto de perfil',
      'story_watch_secret': 'Ver historia en secreto',
      'story_no_data': 'No hay datos de historias disponibles.',
      'story_close': 'CERRAR',
    },
    'hi': {
      'story_section_title':
          'Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Å¡Ã Â¥ÂÃ Â¤ÂªÃ Â¤Å¡Ã Â¤Â¾Ã Â¤Âª Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¥â€¡Ã Â¤â€š Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹ Ã Â¤Â¬Ã Â¤Â¡Ã Â¤Â¼Ã Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€š',
      'story_login_required':
          'Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤â€¢Ã Â¥â€¹ Ã Â¤â€”Ã Â¥ÂÃ Â¤ÂªÃ Â¥ÂÃ Â¤Â¤ Ã Â¤Â°Ã Â¥â€šÃ Â¤Âª Ã Â¤Â¸Ã Â¥â€¡ Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€Ã Â¤Â° Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¼Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹ Ã Â¤Â¬Ã Â¤Â¡Ã Â¤Â¼Ã Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¨Ã Â¥â€¡ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â Ã Â¤â€¢Ã Â¥Æ’Ã Â¤ÂªÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤Â²Ã Â¥â€°Ã Â¤â€”Ã Â¤Â¿Ã Â¤Â¨ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤',
      'story_ad_wait':
          'Ã Â¤ÂµÃ Â¤Â¿Ã Â¤Å“Ã Â¥ÂÃ Â¤ÂÃ Â¤Â¾Ã Â¤ÂªÃ Â¤Â¨ Ã Â¤â€¢Ã Â¥â€¡ Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¦ Ã Â¤Â¦Ã Â¤Â¿Ã Â¤â€“Ã Â¤Â¾Ã Â¤Â¯Ã Â¤Â¾ Ã Â¤Å“Ã Â¤Â¾Ã Â¤ÂÃ Â¤â€”Ã Â¤Â¾Ã Â¥Â¤ Ã Â¤â€¢Ã Â¥Æ’Ã Â¤ÂªÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¡Ã Â¤â€šÃ Â¤Â¤Ã Â¤Å“Ã Â¤Â¼Ã Â¤Â¾Ã Â¤Â° Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€šÃ Â¥Â¤',
      'story_action_title':
          'Ã Â¤â€ Ã Â¤Âª Ã Â¤â€¢Ã Â¥ÂÃ Â¤Â¯Ã Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¤Â¨Ã Â¤Â¾ Ã Â¤Å¡Ã Â¤Â¾Ã Â¤Â¹Ã Â¥â€¡Ã Â¤â€šÃ Â¤â€”Ã Â¥â€¡?',
      'story_view_photo':
          'Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¥â€¹Ã Â¤Â«Ã Â¤Â¾Ã Â¤â€¡Ã Â¤Â² Ã Â¤Â«Ã Â¥â€¹Ã Â¤Å¸Ã Â¥â€¹ Ã Â¤Â¬Ã Â¤Â¡Ã Â¤Â¼Ã Â¤Â¾ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€š',
      'story_watch_secret':
          'Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Å¡Ã Â¥ÂÃ Â¤ÂªÃ Â¤Å¡Ã Â¤Â¾Ã Â¤Âª Ã Â¤Â¦Ã Â¥â€¡Ã Â¤â€“Ã Â¥â€¡Ã Â¤â€š',
      'story_no_data':
          'Ã Â¤Â¸Ã Â¥ÂÃ Â¤Å¸Ã Â¥â€¹Ã Â¤Â°Ã Â¥â‚¬ Ã Â¤Â¡Ã Â¥â€¡Ã Â¤Å¸Ã Â¤Â¾ Ã Â¤â€°Ã Â¤ÂªÃ Â¤Â²Ã Â¤Â¬Ã Â¥ÂÃ Â¤Â§ Ã Â¤Â¨Ã Â¤Â¹Ã Â¥â‚¬Ã Â¤â€š Ã Â¤Â¹Ã Â¥Ë†Ã Â¥Â¤',
      'story_close': 'Ã Â¤Â¬Ã Â¤â€šÃ Â¤Â¦ Ã Â¤â€¢Ã Â¤Â°Ã Â¥â€¡Ã Â¤â€š',
    },
    'hu': {
      'story_section_title':
          'Sztorik megtekintÃƒÂ©se titokban vagy profilkÃƒÂ©p nagyÃƒÂ­tÃƒÂ¡sa',
      'story_login_required':
          'KÃƒÂ©rjÃƒÂ¼k, jelentkezz be a tÃƒÂ¶rtÃƒÂ©netek nÃƒÂ©vtelen megtekintÃƒÂ©sÃƒÂ©hez ÃƒÂ©s a profilkÃƒÂ©pek nagyÃƒÂ­tÃƒÂ¡sÃƒÂ¡hoz.',
      'story_ad_wait':
          'A hirdetÃƒÂ©s utÃƒÂ¡n jelenik meg. KÃƒÂ©rjÃƒÂ¼k, vÃƒÂ¡rj.',
      'story_action_title': 'Mit szeretnÃƒÂ©l csinÃƒÂ¡lni?',
      'story_view_photo': 'ProfilkÃƒÂ©p nagyÃƒÂ­tÃƒÂ¡sa',
      'story_watch_secret': 'Sztori megtekintÃƒÂ©se titokban',
      'story_no_data': 'Nem ÃƒÂ©rhetÃ…â€˜ el sztoriadat.',
      'story_close': 'BEZÃƒÂR',
    },
    'zh-hans': {
      'story_section_title':
          'Ã¥Å’Â¿Ã¥ÂÂÃ¦Å¸Â¥Ã§Å“â€¹Ã¥Å Â¨Ã¦â‚¬ÂÃ¦Ë†â€“Ã¦â€Â¾Ã¥Â¤Â§Ã¥Â¤Â´Ã¥Æ’Â',
      'story_login_required':
          'Ã¨Â¯Â·Ã§â„¢Â»Ã¥Â½â€¢Ã¤Â»Â¥Ã¥Å’Â¿Ã¥ÂÂÃ¦Å¸Â¥Ã§Å“â€¹Ã¥Å Â¨Ã¦â‚¬ÂÃ¥Â¹Â¶Ã¦â€Â¾Ã¥Â¤Â§Ã¥Â¤Â´Ã¥Æ’ÂÃ§â€¦Â§Ã§â€°â€¡Ã£â‚¬â€š',
      'story_ad_wait':
          'Ã¥Â¹Â¿Ã¥â€˜Å Ã¥ÂÂÃ¦ËœÂ¾Ã§Â¤ÂºÃ¯Â¼Å’Ã¨Â¯Â·Ã§Â¨ÂÃ¥â‚¬â„¢Ã£â‚¬â€š',
      'story_action_title': 'Ã¤Â½Â Ã¦Æ’Â³Ã¥ÂÅ¡Ã¤Â»â‚¬Ã¤Â¹Ë†Ã¯Â¼Å¸',
      'story_view_photo': 'Ã¦â€Â¾Ã¥Â¤Â§Ã¥Â¤Â´Ã¥Æ’Â',
      'story_watch_secret': 'Ã¥Å’Â¿Ã¥ÂÂÃ¦Å¸Â¥Ã§Å“â€¹Ã¥Å Â¨Ã¦â‚¬Â',
      'story_no_data': 'Ã¦Å¡â€šÃ¦â€”Â Ã¥Å Â¨Ã¦â‚¬ÂÃ¦â€¢Â°Ã¦ÂÂ®Ã£â‚¬â€š',
      'story_close': 'Ã¥â€¦Â³Ã©â€”Â­',
    },
    'id': {
      'story_section_title': 'Lihat story diam-diam atau perbesar foto profil',
      'story_login_required':
          'Silakan masuk untuk melihat story secara anonim dan memperbesar foto profil.',
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
          'Log in om stories anoniem te bekijken en profielfoto\'s te vergroten.',
      'story_ad_wait': 'Wordt na de advertentie getoond. Even geduld.',
      'story_action_title': 'Wat wil je doen?',
      'story_view_photo': 'Profielfoto vergroten',
      'story_watch_secret': 'Story stiekem bekijken',
      'story_no_data': 'Geen storygegevens beschikbaar.',
      'story_close': 'SLUITEN',
    },
    'fr': {
      'story_section_title':
          'Voir les stories discrÃƒÂ¨tement ou agrandir la photo de profil',
      'story_login_required':
          'Connectez-vous pour voir les stories en mode anonyme et agrandir les photos de profil.',
      'story_ad_wait':
          'SÃ¢â‚¬â„¢affichera aprÃƒÂ¨s la publicitÃƒÂ©. Veuillez patienter.',
      'story_action_title': 'Que souhaitez-vous faire ?',
      'story_view_photo': 'Agrandir la photo de profil',
      'story_watch_secret': 'Voir la story discrÃƒÂ¨tement',
      'story_no_data': 'Aucune donnÃƒÂ©e de story disponible.',
      'story_close': 'FERMER',
    },
    'it': {
      'story_section_title':
          'Guarda le storie in segreto o ingrandisci la foto profilo',
      'story_login_required':
          'Accedi per vedere le storie in modo anonimo e ingrandire le foto profilo.',
      'story_ad_wait': 'VerrÃƒÂ  mostrato dopo lÃ¢â‚¬â„¢annuncio. Attendi.',
      'story_action_title': 'Cosa vuoi fare?',
      'story_view_photo': 'Ingrandisci la foto profilo',
      'story_watch_secret': 'Guarda la storia in segreto',
      'story_no_data': 'Nessun dato story disponibile.',
      'story_close': 'CHIUDI',
    },
    'vi': {
      'story_section_title':
          'Xem story bÃƒÂ­ mÃ¡ÂºÂ­t hoÃ¡ÂºÂ·c phÃƒÂ³ng to Ã¡ÂºÂ£nh hÃ¡Â»â€œ sÃ†Â¡',
      'story_login_required':
          'Vui lÃƒÂ²ng Ã„â€˜Ã„Æ’ng nhÃ¡ÂºÂ­p Ã„â€˜Ã¡Â»Æ’ xem story Ã¡ÂºÂ©n danh vÃƒÂ  phÃƒÂ³ng to Ã¡ÂºÂ£nh hÃ¡Â»â€œ sÃ†Â¡.',
      'story_ad_wait':
          'SÃ¡ÂºÂ½ hiÃ¡Â»Æ’n thÃ¡Â»â€¹ sau quÃ¡ÂºÂ£ng cÃƒÂ¡o. Vui lÃƒÂ²ng chÃ¡Â»Â.',
      'story_action_title': 'BÃ¡ÂºÂ¡n muÃ¡Â»â€˜n lÃƒÂ m gÃƒÂ¬?',
      'story_view_photo': 'PhÃƒÂ³ng to Ã¡ÂºÂ£nh hÃ¡Â»â€œ sÃ†Â¡',
      'story_watch_secret': 'Xem story bÃƒÂ­ mÃ¡ÂºÂ­t',
      'story_no_data': 'KhÃƒÂ´ng cÃƒÂ³ dÃ¡Â»Â¯ liÃ¡Â»â€¡u story.',
      'story_close': 'Ã„ÂÃƒâ€œNG',
    },
    'th': {
      'story_section_title':
          'Ã Â¸â€Ã Â¸Â¹Ã Â¸ÂªÃ Â¸â€¢Ã Â¸Â­Ã Â¸Â£Ã Â¸ÂµÃ Â¹ÂÃ Â¸Å¡Ã Â¸Å¡Ã Â¸Â¥Ã Â¸Â±Ã Â¸Å¡ Ã Â¹â€  Ã Â¸Â«Ã Â¸Â£Ã Â¸Â·Ã Â¸Â­Ã Â¸â€šÃ Â¸Â¢Ã Â¸Â²Ã Â¸Â¢Ã Â¸Â£Ã Â¸Â¹Ã Â¸â€ºÃ Â¹â€šÃ Â¸â€ºÃ Â¸Â£Ã Â¹â€Ã Â¸Å¸Ã Â¸Â¥Ã Â¹Å’',
      'story_login_required':
          'Ã Â¹â€šÃ Â¸â€ºÃ Â¸Â£Ã Â¸â€Ã Â¹â‚¬Ã Â¸â€šÃ Â¹â€°Ã Â¸Â²Ã Â¸ÂªÃ Â¸Â¹Ã Â¹Ë†Ã Â¸Â£Ã Â¸Â°Ã Â¸Å¡Ã Â¸Å¡Ã Â¹â‚¬Ã Â¸ÂÃ Â¸Â·Ã Â¹Ë†Ã Â¸Â­Ã Â¸â€Ã Â¸Â¹Ã Â¸ÂªÃ Â¸â€¢Ã Â¸Â­Ã Â¸Â£Ã Â¸ÂµÃ Â¹ÂÃ Â¸Å¡Ã Â¸Å¡Ã Â¹â€Ã Â¸Â¡Ã Â¹Ë†Ã Â¸Â£Ã Â¸Â°Ã Â¸Å¡Ã Â¸Â¸Ã Â¸â€¢Ã Â¸Â±Ã Â¸Â§Ã Â¸â€¢Ã Â¸â„¢Ã Â¹ÂÃ Â¸Â¥Ã Â¸Â°Ã Â¸â€šÃ Â¸Â¢Ã Â¸Â²Ã Â¸Â¢Ã Â¸Â£Ã Â¸Â¹Ã Â¸â€ºÃ Â¹â€šÃ Â¸â€ºÃ Â¸Â£Ã Â¹â€Ã Â¸Å¸Ã Â¸Â¥Ã Â¹Å’',
      'story_ad_wait':
          'Ã Â¸Ë†Ã Â¸Â°Ã Â¹ÂÃ Â¸ÂªÃ Â¸â€Ã Â¸â€¡Ã Â¸Â«Ã Â¸Â¥Ã Â¸Â±Ã Â¸â€¡Ã Â¹â€šÃ Â¸â€ Ã Â¸Â©Ã Â¸â€œÃ Â¸Â² Ã Â¸ÂÃ Â¸Â£Ã Â¸Â¸Ã Â¸â€œÃ Â¸Â²Ã Â¸Â£Ã Â¸Â­Ã Â¸ÂªÃ Â¸Â±Ã Â¸ÂÃ Â¸â€Ã Â¸Â£Ã Â¸Â¹Ã Â¹Ë†',
      'story_action_title':
          'Ã Â¸â€Ã Â¸Â¸Ã Â¸â€œÃ Â¸â€¢Ã Â¹â€°Ã Â¸Â­Ã Â¸â€¡Ã Â¸ÂÃ Â¸Â²Ã Â¸Â£Ã Â¸â€”Ã Â¸Â³Ã Â¸Â­Ã Â¸Â°Ã Â¹â€Ã Â¸Â£?',
      'story_view_photo':
          'Ã Â¸â€šÃ Â¸Â¢Ã Â¸Â²Ã Â¸Â¢Ã Â¸Â£Ã Â¸Â¹Ã Â¸â€ºÃ Â¹â€šÃ Â¸â€ºÃ Â¸Â£Ã Â¹â€Ã Â¸Å¸Ã Â¸Â¥Ã Â¹Å’',
      'story_watch_secret':
          'Ã Â¸â€Ã Â¸Â¹Ã Â¸ÂªÃ Â¸â€¢Ã Â¸Â­Ã Â¸Â£Ã Â¸ÂµÃ Â¹ÂÃ Â¸Å¡Ã Â¸Å¡Ã Â¸Â¥Ã Â¸Â±Ã Â¸Å¡ Ã Â¹â€ ',
      'story_no_data':
          'Ã Â¹â€Ã Â¸Â¡Ã Â¹Ë†Ã Â¸Â¡Ã Â¸ÂµÃ Â¸â€šÃ Â¹â€°Ã Â¸Â­Ã Â¸Â¡Ã Â¸Â¹Ã Â¸Â¥Ã Â¸ÂªÃ Â¸â€¢Ã Â¸Â­Ã Â¸Â£Ã Â¸Âµ',
      'story_close': 'Ã Â¸â€ºÃ Â¸Â´Ã Â¸â€',
    },
    'pl': {
      'story_section_title':
          'OglÃ„â€¦daj relacje anonimowo lub powiÃ„â„¢ksz zdjÃ„â„¢cie profilowe',
      'story_login_required':
          'Zaloguj siÃ„â„¢, aby oglÃ„â€¦daÃ„â€¡ relacje anonimowo i powiÃ„â„¢kszaÃ„â€¡ zdjÃ„â„¢cia profilowe.',
      'story_ad_wait': 'Zostanie pokazane po reklamie. Prosimy czekaÃ„â€¡.',
      'story_action_title': 'Co chcesz zrobic?',
      'story_view_photo': 'PowiÃ„â„¢ksz zdjÃ„â„¢cie profilowe',
      'story_watch_secret': 'OglÃ„â€¦daj relacjÃ„â„¢ anonimowo',
      'story_no_data': 'Brak danych relacji.',
      'story_close': 'ZAMKNIJ',
    },
  };

  String _t(String key, [Map<String, String>? args]) {
    if (key == 'tagline') {
      return localizeTrEn(_lang, 'Professional Social Media Solutions',
          'Professional Social Media Solutions');
    }

    final String lang = _lang.trim().toLowerCase();
    final String? enText = _localized['en']?[key] ?? _flowLocalized['en']?[key];
    final String? trText = _localized['tr']?[key] ?? _flowLocalized['tr']?[key];
    final String trBase = (trText ?? enText ?? key).trim();
    final String enBase = (enText ?? trText ?? key).trim();

    if (lang != 'tr' && lang != 'en') {
      String mapped = localizeTrEn(lang, trBase, enBase);
      if (args != null) {
        args.forEach((k, v) {
          mapped = mapped.replaceAll('{$k}', v);
        });
      }
      final String mappedClean = _repairDisplayText(mapped).trim();
      if (mappedClean.isNotEmpty && !_looksLikeMojibakeText(mappedClean)) {
        return mappedClean;
      }
    }

    final String? direct = _humanizedUiOverrides[lang]?[key] ??
        _localized[lang]?[key] ??
        _flowLocalized[lang]?[key];

    bool looksUntranslated(String? value, String? en) {
      if (lang == 'en') return false;
      final String v = (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      final String e = (en ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (v.isEmpty || e.isEmpty) return false;
      return v.toLowerCase() == e.toLowerCase();
    }

    String res;
    if (direct == null ||
        direct.trim().isEmpty ||
        looksUntranslated(direct, enText)) {
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
    return _normalizeSupportedLangCodeFromLocale(localeRaw);
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
    final AppLifecycleState? lifecycleState =
        WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null) {
      _appLifecycleState = lifecycleState;
    }
    if (_appLifecycleState != AppLifecycleState.resumed) {
      _resumeCompleter = Completer<void>();
    }
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
    unawaited(_loadOwnerUsernameCache());
    _tryAutoLogin();
    _loadRemoteUserFlags();
    _updatePrivacyOptionsRequirement();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _waitForAdConsentFlow();
      if (!mounted) return;
      _checkRatingDialog();
      await _maybeLoadBannerAfterConsent();
      unawaited(_prefetchEntryInterstitialAd());
      unawaited(() async {
        await _waitForAdConsentFlow();
        if (!mounted) return;
        await _updatePrivacyOptionsRequirement();
      }());

      if (_forceFirestoreTest) {
        Future.delayed(const Duration(seconds: 5), () {
          if (!mounted) return;
          unawaited(_testFirestoreWrite());
        });
      }
    });
  }

  Future<void> _waitUntilAppResumedIfNeeded() async {
    if (!mounted || _appLifecycleState == AppLifecycleState.resumed) return;
    _resumeCompleter ??= Completer<void>();
    await _resumeCompleter!.future;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      final Completer<void>? pendingResume = _resumeCompleter;
      _resumeCompleter = null;
      if (pendingResume != null && !pendingResume.isCompleted) {
        pendingResume.complete();
      }
      unawaited(_refreshSessionCookieFromWebViewStore());
      if (isLoggedIn) {
        unawaited(TelemetryService.instance.recordSeen());
        _queueQuickStoryTrayRefresh();
      }
      if (!_adsDisabled && (!_isAdLoaded || !_isHeaderBannerLoaded)) {
        unawaited(_maybeLoadBannerAfterConsent());
      }
    } else {
      _resumeCompleter ??= Completer<void>();
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
      if (_canViewAdminPanel()) {
        unawaited(_showPremiumActivatedNotification());
      }
    } else {
      unawaited(_maybeLoadBannerAfterConsent());
    }
  }

  Future<void> _showPremiumActivatedNotification() async {
    if (!_canViewAdminPanel()) return;
    final DateTime now = DateTime.now();
    final DateTime? lastShown = _lastPremiumActivatedNotificationAt;
    if (lastShown != null &&
        now.difference(lastShown) < const Duration(seconds: 20)) {
      return;
    }
    _lastPremiumActivatedNotificationAt = now;

    final String title = localizeTrEn(
      _lang,
      'VERDICT Premium aktif',
      'VERDICT Premium is active',
    );
    final String body = localizeTrEn(
      _lang,
      'Satın alımın onaylandı. Reklamlar ve limitler kaldırıldı.',
      'Your purchase was confirmed. Ads and limits are removed.',
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        id: _RootAppState._premiumActivatedNotificationId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'purchase_status_channel',
            'Purchase Status',
            channelDescription: 'Purchase and subscription confirmations',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'purchase_notification',
        'local purchase notification failed',
        error: e,
        stackTrace: st,
        isError: true,
      );
    }
  }

  Future<DocumentReference<Map<String, dynamic>>?> _ownerPurchasePushTokenRef(
      {String? uid}) async {
    final String cleanUid =
        (uid ?? FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    if (cleanUid.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('owner_push_tokens')
        .doc('grkmcomert')
        .collection('devices')
        .doc(cleanUid);
  }

  Future<void> _writeOwnerPurchaseNotificationToken({
    required String uid,
    required String token,
  }) async {
    if (!_canViewAdminPanel()) return;
    final String cleanToken = token.trim();
    if (cleanToken.isEmpty) return;
    final DocumentReference<Map<String, dynamic>>? ref =
        await _ownerPurchasePushTokenRef(uid: uid);
    if (ref == null) return;

    await ref.set({
      'owner': 'grkmcomert',
      'username': currentUsername.trim(),
      'username_key': _normalizeUserKey(currentUsername),
      'auth_uid': uid,
      'fcm_token': cleanToken,
      'platform': Platform.operatingSystem,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(_firestoreTimeout);
  }

  Future<void> _syncOwnerPurchaseNotificationTokenIfAllowed() async {
    if (!_canViewAdminPanel()) return;
    if (_ownerPurchaseNotificationTokenSyncing) return;
    _ownerPurchaseNotificationTokenSyncing = true;

    try {
      final User? user = await _ensureFirestoreAuthUser();
      final String uid = user?.uid.trim() ?? '';
      if (uid.isEmpty) return;

      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _logFirebaseDiagnostic(
          'owner_push',
          'blocked: notification permission denied for grkmcomert',
          isError: true,
        );
        return;
      }

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final String token = (await messaging.getToken())?.trim() ?? '';
      await _writeOwnerPurchaseNotificationToken(uid: uid, token: token);
      _logFirebaseDiagnostic(
        'owner_push',
        'grkmcomert FCM token registered uid=$uid token_length=${token.length}',
      );

      _ownerFcmTokenRefreshSub ??=
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        if (!_canViewAdminPanel()) return;
        unawaited(_writeOwnerPurchaseNotificationToken(
          uid: uid,
          token: newToken,
        ));
      });
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'owner_push',
        'grkmcomert FCM token registration failed',
        error: e,
        stackTrace: st,
        isError: true,
      );
    } finally {
      _ownerPurchaseNotificationTokenSyncing = false;
    }
  }

  Future<void> _unregisterOwnerPurchaseNotificationToken({String? uid}) async {
    await _ownerFcmTokenRefreshSub?.cancel();
    _ownerFcmTokenRefreshSub = null;

    try {
      final DocumentReference<Map<String, dynamic>>? ref =
          await _ownerPurchasePushTokenRef(uid: uid);
      await ref?.delete().timeout(const Duration(seconds: 4));
    } catch (_) {}

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.deleteToken();
      await messaging.setAutoInitEnabled(false);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (_) {}
  }

  void _disposeBannerAd() {
    _bannerRetryTimer?.cancel();
    _bannerRetryTimer = null;
    _headerBannerRetryTimer?.cancel();
    _headerBannerRetryTimer = null;
    _entryInterstitialPrefetchRetryTimer?.cancel();
    _entryInterstitialPrefetchRetryTimer = null;
    _entryInterstitialPrefetchTimeoutTimer?.cancel();
    _entryInterstitialPrefetchTimeoutTimer = null;
    _consentWatchTimer?.cancel();
    _consentWatchTimer = null;
    _isBannerLoadInFlight = false;
    _isHeaderBannerLoadInFlight = false;
    _bannerConsecutiveFailures = 0;
    _headerBannerConsecutiveFailures = 0;
    _entryInterstitialPrefetchFailureCount = 0;
    _bannerBackoffUntil = null;
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    try {
      _headerBannerAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    _headerBannerAd = null;
    if (mounted) {
      setState(() {
        _isAdLoaded = false;
        _isHeaderBannerLoaded = false;
      });
    } else {
      _isAdLoaded = false;
      _isHeaderBannerLoaded = false;
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
      await _setAccountPrefString(
        prefs,
        'session_username',
        fetched,
        userId: savedUserId,
      );
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
    // Owner account: always exempt from bans and the ad/paywall gate,
    // independent of Firebase Remote Config (removeadsfor/bannedusers), so
    // testing this app on the owner's own account is never blocked by the
    // 30-hour analysis cooldown / rewarded-ad / premium-purchase prompts.
    final bool isOwner = username == 'grkmcomert';
    final bool banned = !isOwner && _bannedUsers.contains(username);
    final bool admin = isOwner || _removeAdsUsers.contains(username);
    _isBanned = banned;
    _isAdminUser = admin;
    if (_removeAllAds || banned || admin) {
      _disableAdsForUser();
    }
    if (mounted) setState(() {});
    if (_canViewAdminPanel()) {
      unawaited(_syncOwnerPurchaseNotificationTokenIfAllowed());
    }
  }

  bool _canViewAdminPanel() {
    if (!isLoggedIn) return false;
    return _normalizeUserKey(currentUsername) == 'grkmcomert';
  }

  // Diagnostics are intentionally available without an Instagram login while
  // we are investigating the current production failure. This does NOT grant
  // owner-only Firebase actions; those remain protected by _canViewAdminPanel().
  //
  // NOTE: currentUsername is only populated while a login is active. When the
  // startup session-restore probe reports the session as inactive, the code
  // shows the "please log in again" warning and returns WITHOUT ever setting
  // isLoggedIn/currentUsername, so relying on currentUsername alone locks the
  // owner out of the exact screen meant to diagnose that failure.
  // _ownerUsernameCache is a small persisted fallback (see _loadOwnerUsernameCache /
  // _persistOwnerUsernameIfNeeded) that survives logouts and failed session
  // restores, so this device keeps console access once the owner has logged
  // in on it at least once. _debugPinUnlocked is a second, entirely
  // login-independent fallback, set from the existing secret-PIN entry point
  // (hold the "Yasal Uyarı" card for 5s, enter 3333 — see _handlePinEntry),
  // so the console is reachable even on a device that has never logged in as
  // the owner at all.
  bool _canOpenDiagnosticsConsole() =>
      kDebugMode ||
      _normalizeUserKey(currentUsername) == 'grkmcomert' ||
      _normalizeUserKey(_ownerUsernameCache) == 'grkmcomert' ||
      _debugPinUnlocked;

  static const String _ownerUsernameCachePrefKey = 'owner_username_cache';
  static const String _debugPinUnlockedPrefKey = 'debug_pin_unlocked';

  Future<void> _loadOwnerUsernameCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cached =
          (prefs.getString(_ownerUsernameCachePrefKey) ?? '').trim();
      final bool pinUnlocked =
          prefs.getBool(_debugPinUnlockedPrefKey) ?? false;
      if (cached.isEmpty && !pinUnlocked) return;
      if (mounted) {
        setState(() {
          if (cached.isNotEmpty) _ownerUsernameCache = cached;
          if (pinUnlocked) _debugPinUnlocked = true;
        });
      } else {
        if (cached.isNotEmpty) _ownerUsernameCache = cached;
        if (pinUnlocked) _debugPinUnlocked = true;
      }
    } catch (_) {}
  }

  Future<void> _persistOwnerUsernameIfNeeded(String username) async {
    final String clean = username.trim();
    if (clean.isEmpty) return;
    if (_normalizeUserKey(clean) != 'grkmcomert') return;
    _ownerUsernameCache = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ownerUsernameCachePrefKey, clean);
    } catch (_) {}
  }

  bool _canViewOwnerFirebaseUserList() {
    return _canViewAdminPanel();
  }

  void _disableAdsForUser() {
    _bannerRetryTimer?.cancel();
    _bannerRetryTimer = null;
    _headerBannerRetryTimer?.cancel();
    _headerBannerRetryTimer = null;
    _entryInterstitialPrefetchRetryTimer?.cancel();
    _entryInterstitialPrefetchRetryTimer = null;
    _entryInterstitialPrefetchTimeoutTimer?.cancel();
    _entryInterstitialPrefetchTimeoutTimer = null;
    _consentWatchTimer?.cancel();
    _consentWatchTimer = null;
    _isBannerLoadInFlight = false;
    _isHeaderBannerLoadInFlight = false;
    _isEntryInterstitialPreloadInFlight = false;
    _bannerConsecutiveFailures = 0;
    _headerBannerConsecutiveFailures = 0;
    _entryInterstitialPrefetchFailureCount = 0;
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    try {
      _headerBannerAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    _headerBannerAd = null;
    _isAdLoaded = false;
    _isHeaderBannerLoaded = false;
    _adsHidden = true;
  }

  Future<void> _maybeLoadBannerAfterConsent() async {
    if (!_remoteFlagsLoaded) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _maybeLoadBannerAfterConsent();
      });
      return;
    }
    if (_adsDisabled) {
      _consentWatchTimer?.cancel();
      _consentWatchTimer = null;
      return;
    }
    Future<bool> tryLoadBanner() async {
      final bool nativeBusy = _isAdLoaded || _isBannerLoadInFlight;
      final bool headerBusy =
          _isHeaderBannerLoaded || _isHeaderBannerLoadInFlight;
      if (!mounted || _adsDisabled || (nativeBusy && headerBusy)) {
        return false;
      }
      try {
        if (await _adConsentFlow.canRequestAds()) {
          _consentWatchTimer?.cancel();
          _consentWatchTimer = null;
          bool startedAnyLoad = false;
          if (!_isHeaderBannerLoaded && !_isHeaderBannerLoadInFlight) {
            startedAnyLoad = true;
            await _loadHeaderBannerAd();
          }
          if (!_isAdLoaded && !_isBannerLoadInFlight) {
            startedAnyLoad = true;
            await _loadBannerAd();
          }
          return startedAnyLoad;
        }
      } catch (_) {}
      return false;
    }

    final bool loadTriggered = await tryLoadBanner();
    if (loadTriggered || _isAdLoaded || _adsDisabled || !mounted) return;

    if (_consentWatchTimer != null && _consentWatchTimer!.isActive) return;
    _consentWatchTimer?.cancel();
    _consentWatchTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (!mounted || _adsDisabled || _isAdLoaded) {
        t.cancel();
        if (identical(_consentWatchTimer, t)) _consentWatchTimer = null;
        return;
      }
      final bool triggered = await tryLoadBanner();
      if (triggered && identical(_consentWatchTimer, t)) {
        t.cancel();
        _consentWatchTimer = null;
      }
    });
  }

  Duration _nextBannerRetryDelay({
    int? code,
    String message = '',
  }) {
    _bannerConsecutiveFailures = min(_bannerConsecutiveFailures + 1, 12);
    final String lower = message.toLowerCase();

    if (code == 1 &&
        (lower.contains('too many recently failed requests') ||
            lower.contains('wait a few seconds'))) {
      const Duration penalty = Duration(seconds: 15);
      _bannerBackoffUntil = DateTime.now().add(penalty);
      return penalty;
    }

    if (code == 3 || lower.contains('no fill')) {
      return Duration(seconds: min(75, 25 + _bannerConsecutiveFailures * 8));
    }

    if (code == 2 || lower.contains('network')) {
      return const Duration(seconds: 25);
    }

    return Duration(seconds: min(60, 20 + _bannerConsecutiveFailures * 5));
  }

  void _scheduleBannerRetry({Duration? delay}) {
    if (!mounted || _adsDisabled || _isAdLoaded) return;
    if (_consentWatchTimer != null && _consentWatchTimer!.isActive) return;
    Duration retryDelay = delay ?? _bannerAggressiveRetryInterval;
    final DateTime? backoffUntil = _bannerBackoffUntil;
    if (backoffUntil != null) {
      final Duration left = backoffUntil.difference(DateTime.now());
      if (left <= Duration.zero) {
        _bannerBackoffUntil = null;
      } else if (left > retryDelay) {
        retryDelay = left;
      }
    }
    _bannerRetryTimer?.cancel();
    _bannerRetryTimer = Timer(retryDelay, () {
      _bannerRetryTimer = null;
      if (!mounted || _adsDisabled || _isAdLoaded) return;
      unawaited(_loadBannerAd());
    });
  }

  bool _isAdNoFillError(Object error) {
    final int? code = _tryAdErrorCode(error);
    final String message = _tryAdErrorMessage(error).toLowerCase();
    final String raw = error.toString().toLowerCase();
    return code == 3 || message.contains('no fill') || raw.contains('no fill');
  }

  bool _isRetryableAdLoadError(Object error) {
    final int? code = _tryAdErrorCode(error);
    final String message = _tryAdErrorMessage(error).toLowerCase();
    final String raw = error.toString().toLowerCase();
    if (_isAdNoFillError(error)) return true;
    if (code == 2 ||
        message.contains('network') ||
        raw.contains('network') ||
        raw.contains('timeout')) {
      return true;
    }
    if (code == 1 &&
        (message.contains('too many recently failed requests') ||
            message.contains('wait a few seconds') ||
            raw.contains('too many recently failed requests'))) {
      return true;
    }
    return false;
  }

  Duration _nextHeaderBannerRetryDelay(Object error) {
    _headerBannerConsecutiveFailures =
        min(_headerBannerConsecutiveFailures + 1, 12);
    if (_isAdNoFillError(error)) {
      return Duration(
          seconds: min(75, 25 + _headerBannerConsecutiveFailures * 8));
    }
    if (_isRetryableAdLoadError(error)) {
      return Duration(
          seconds: min(60, 20 + _headerBannerConsecutiveFailures * 5));
    }
    return _headerBannerRetryDelay;
  }

  void _scheduleHeaderBannerRetry({Duration delay = _headerBannerRetryDelay}) {
    if (!mounted || _adsDisabled || _isHeaderBannerLoaded) return;
    _headerBannerRetryTimer?.cancel();
    _headerBannerRetryTimer = Timer(delay, () {
      _headerBannerRetryTimer = null;
      if (!mounted || _adsDisabled || _isHeaderBannerLoaded) return;
      unawaited(_loadHeaderBannerAd());
    });
  }

  Future<void> _loadHeaderBannerAd() async {
    if (!await _adConsentFlow.canRequestAds() || !mounted) return;
    if (_adsDisabled) {
      _headerBannerRetryTimer?.cancel();
      _headerBannerRetryTimer = null;
      _isHeaderBannerLoadInFlight = false;
      try {
        _headerBannerAd?.dispose();
      } catch (_) {}
      _headerBannerAd = null;
      if (mounted) {
        setState(() {
          _isHeaderBannerLoaded = false;
        });
      } else {
        _isHeaderBannerLoaded = false;
      }
      return;
    }

    if (_isHeaderBannerLoaded || _isHeaderBannerLoadInFlight) return;
    _isHeaderBannerLoadInFlight = true;

    try {
      _headerBannerAd?.dispose();
    } catch (_) {}
    _headerBannerAd = null;
    _isHeaderBannerLoaded = false;

    final bool useNpa = await _shouldUseNonPersonalizedAds();
    final BannerAd banner = BannerAd(
      adUnitId: Platform.isAndroid
          ? _headerBannerAdUnitIdAndroid
          : _headerBannerAdUnitIdIos,
      size: AdSize.banner,
      request: AdRequest(nonPersonalizedAds: useNpa),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _isHeaderBannerLoadInFlight = false;
          _headerBannerConsecutiveFailures = 0;
          _headerBannerRetryTimer?.cancel();
          _headerBannerRetryTimer = null;
          if (mounted) {
            setState(() {
              _isHeaderBannerLoaded = true;
            });
          } else {
            _isHeaderBannerLoaded = true;
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _isHeaderBannerLoadInFlight = false;
          try {
            ad.dispose();
          } catch (_) {}
          if (identical(_headerBannerAd, ad)) {
            _headerBannerAd = null;
          }
          if (mounted) {
            setState(() {
              _isHeaderBannerLoaded = false;
            });
          } else {
            _isHeaderBannerLoaded = false;
          }
          _scheduleHeaderBannerRetry(
            delay: _nextHeaderBannerRetryDelay(error),
          );
        },
      ),
    );

    _headerBannerAd = banner;
    try {
      await banner.load().timeout(_headerBannerRetryDelay);
    } catch (e) {
      _isHeaderBannerLoadInFlight = false;
      try {
        banner.dispose();
      } catch (_) {}
      if (identical(_headerBannerAd, banner)) {
        _headerBannerAd = null;
      }
      _scheduleHeaderBannerRetry(delay: _nextHeaderBannerRetryDelay(e));
    }
  }

  Future<bool> _shouldUseNonPersonalizedAds() async {
    return shouldUseNonPersonalizedAdsGlobal();
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

  Future<bool> _requestIosInAppReview() async {
    if (!Platform.isIOS) return false;
    try {
      final dynamic result = await _reviewChannel.invokeMethod('requestReview');
      if (result is bool) return result;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _launchRateUrl({bool userInitiated = true}) async {
    // Apple does not tell us whether the in-app review sheet was actually
    // shown. We can only best-effort trigger it and fall back to the store
    // when the native call itself fails.
    if (Platform.isIOS && !userInitiated) {
      await _requestIosInAppReview();
      return;
    }

    if (Platform.isIOS && userInitiated) {
      final bool reviewRequested = await _requestIosInAppReview();
      if (reviewRequested) return;
    }

    final String rawUrl = Platform.isIOS ? _rateUrlIos : _rateUrlAndroid;
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
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
              _lang, 'GeÃƒÂ§ersiz maÃ„Å¸aza linki.', 'Invalid store link.')),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizeTrEn(
              _lang, 'Link aÃƒÂ§Ã„Â±lamadÃ„Â±.', 'Could not open the link.')),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _openAppleEula() async {
    final Uri uri = Uri.parse(_appleEulaUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizeTrEn(
            _lang, 'Link aÃƒÂ§Ã„Â±lamadÃ„Â±.', 'Could not open the link.')),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  String _purchaseNotConfiguredMessage() {
    final String raw = PurchasesService.instance.lastPurchaseError.value.trim();
    if (raw.isEmpty) return '';

    final String lower = raw.toLowerCase();
    if (lower.contains('purchases not configured')) return '';

    if (lower.contains('revenuecat api key missing') &&
        lower.contains('android')) {
      return localizeTrEn(
        _lang,
        'Android RevenueCat anahtarı eksik. Bu build satın alma anahtarı olmadan oluşturulmuş.',
        'Android RevenueCat key is missing. This build was created without the purchase key.',
      );
    }
    if (lower.contains('revenuecat api key missing') && lower.contains('ios')) {
      return localizeTrEn(
        _lang,
        'iOS RevenueCat anahtarı eksik. Bu build satın alma anahtarı olmadan oluşturulmuş.',
        'iOS RevenueCat key is missing. This build was created without the purchase key.',
      );
    }

    return raw;
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
      final String purchaseMessage = _purchaseNotConfiguredMessage();
      if (mounted && purchaseMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(purchaseMessage),
          duration: const Duration(seconds: 4),
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
          localizeTrEn(_lang, 'LÃƒÂ¼tfen tekrar deneyin.', 'Please try again.');
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
    if (!await _adConsentFlow.canRequestAds() || !mounted) return;
    if (_adsDisabled) {
      _bannerRetryTimer?.cancel();
      _bannerRetryTimer = null;
      _isBannerLoadInFlight = false;
      try {
        _bannerAd?.dispose();
      } catch (_) {}
      _bannerAd = null;
      if (mounted)
        setState(() {
          _isAdLoaded = false;
        });
      return;
    }
    if (_isAdLoaded || _isBannerLoadInFlight) return;
    _isBannerLoadInFlight = true;
    final int attemptId = ++_bannerLoadAttempt;

    final String adUnit =
        Platform.isAndroid ? _bannerAdUnitIdAndroid : _bannerAdUnitIdIos;

    if (_bannerAd != null) {
      try {
        _bannerAd!.dispose();
      } catch (_) {}
      _bannerAd = null;
      _isAdLoaded = false;
    }

    final bool useNpa = await _shouldUseNonPersonalizedAds();
    _logAdDebug(
      'banner',
      'load_start attempt=$attemptId unit=$adUnit npa=$useNpa',
    );
    _bannerAd = NativeAd(
      adUnitId: adUnit,
      request: AdRequest(nonPersonalizedAds: useNpa),
      factoryId: 'adFactoryExample',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isBannerLoadInFlight = false;
          _bannerConsecutiveFailures = 0;
          _bannerBackoffUntil = null;
          _bannerRetryTimer?.cancel();
          _bannerRetryTimer = null;
          _consentWatchTimer?.cancel();
          _consentWatchTimer = null;
          if (mounted)
            setState(() {
              _isAdLoaded = true;
            });
        },
        onAdFailedToLoad: (ad, err) {
          final Duration retryDelay = _nextBannerRetryDelay(
            code: _tryAdErrorCode(err),
            message: _tryAdErrorMessage(err),
          );
          _isBannerLoadInFlight = false;
          ad.dispose();
          if (mounted)
            setState(() {
              _isAdLoaded = false;
            });
          _scheduleBannerRetry(delay: retryDelay);
        },
      ),
    );

    try {
      await _bannerAd!.load().timeout(_bannerSingleAttemptTimeout);
    } catch (e) {
      if (!mounted || _adsDisabled || _isAdLoaded) return;
      if (_isBannerLoadInFlight && attemptId == _bannerLoadAttempt) {
        _isBannerLoadInFlight = false;
        final String errorMsg =
            e is TimeoutException ? 'load_timeout' : e.toString();
        final Duration retryDelay = _nextBannerRetryDelay(message: errorMsg);
        _scheduleBannerRetry(delay: retryDelay);
      }
    }
  }

  Future<Map<String, dynamic>> _runSingleRewardedAdAttempt({
    required String adUnit,
    required bool useNpa,
    required Duration attemptTimeout,
    required int attemptNumber,
  }) async {
    if (!await _adConsentFlow.canRequestAds() || !mounted || _adsDisabled) {
      return {
        'status': false,
        'skipped': true,
        'reason': 'consent_unavailable',
      };
    }
    final bool isInterstitial = adUnit.contains('2420482147');
    if (isInterstitial) {
      return _runSingleLegacyRewardedAdAttempt(
        adUnit: adUnit,
        useNpa: useNpa,
        attemptTimeout: attemptTimeout,
        attemptNumber: attemptNumber,
      );
    }
    return _runSingleNativeRewardedAdAttempt(
      adUnit: adUnit,
      useNpa: useNpa,
      attemptTimeout: attemptTimeout,
      attemptNumber: attemptNumber,
    );
  }

  Future<Map<String, dynamic>> _runSingleNativeRewardedAdAttempt({
    required String adUnit,
    required bool useNpa,
    required Duration attemptTimeout,
    required int attemptNumber,
  }) async {
    final Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    RewardedAd? tempAd;
    bool attemptClosed = false;
    bool adWasShown = false;
    bool rewardEarned = false;
    late final Timer loadTimeoutTimer;
    Timer? shownSafetyTimer;

    _logAdDebug(
      'rewarded',
      'attempt=$attemptNumber load_start unit=$adUnit timeout_ms=${attemptTimeout.inMilliseconds} npa=$useNpa api=rewarded',
    );

    void completeAttempt(Map<String, dynamic> value) {
      if (attemptClosed || c.isCompleted) return;
      c.complete(value);
    }

    loadTimeoutTimer = Timer(attemptTimeout, () {
      if (attemptClosed || c.isCompleted) return;
      if (adWasShown) return;
      _logAdDebug(
        'rewarded',
        'attempt=$attemptNumber load_timeout',
        isError: true,
      );
      completeAttempt({
        "status": false,
        "skipped": true,
        "reason": "load_timeout",
        "error": localizeTrEn(_lang, "Zaman asimi", "Timeout"),
      });
    });

    RewardedAd.load(
      adUnitId: adUnit,
      request: AdRequest(nonPersonalizedAds: useNpa),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _logAdDebug(
            'rewarded',
            'attempt=$attemptNumber ad_loaded',
            responseInfo: ad.responseInfo,
          );
          if (attemptClosed || c.isCompleted) {
            try {
              ad.dispose();
            } catch (_) {}
            return;
          }
          tempAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
            onAdShowedFullScreenContent: (RewardedAd ad) {
              _logAdDebug(
                'rewarded',
                'attempt=$attemptNumber showed',
                responseInfo: ad.responseInfo,
              );
            },
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              _hideAdCloseButton();
              final bool earned = rewardEarned;
              shownSafetyTimer?.cancel();
              try {
                ad.dispose();
              } catch (_) {}
              if (attemptClosed || c.isCompleted) return;
              _logAdDebug(
                'rewarded',
                'attempt=$attemptNumber dismissed reward_earned=$earned',
              );
              if (earned) {
                completeAttempt({
                  "status": true,
                  "shown": true,
                });
                return;
              }
              completeAttempt({
                "status": false,
                "shown": true,
                "reason": "reward_not_earned",
                "error": localizeTrEn(
                  _lang,
                  "Odul kazanilmadan reklam kapatildi.",
                  "Ad closed before reward was earned.",
                ),
              });
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError err) {
              _hideAdCloseButton();
              shownSafetyTimer?.cancel();
              try {
                ad.dispose();
              } catch (_) {}
              if (attemptClosed) return;
              final ResponseInfo? responseInfo =
                  _tryAdResponseInfoFromObject(ad);
              final String detail =
                  _buildAdErrorDetails(err, responseInfo: responseInfo);
              _logAdDebug(
                'rewarded',
                'attempt=$attemptNumber show_failed',
                error: err,
                responseInfo: responseInfo,
                isError: true,
              );
              completeAttempt({
                "status": false,
                "skipped": true,
                "reason": "show_failed",
                "error": detail,
              });
            },
          );
          try {
            if (attemptClosed) return;
            loadTimeoutTimer.cancel();
            adWasShown = true;
            shownSafetyTimer?.cancel();
            shownSafetyTimer = Timer(_rewardedShownSafetyTimeout, () {
              if (attemptClosed || c.isCompleted) return;
              _logAdDebug(
                'rewarded',
                'attempt=$attemptNumber show_timeout',
                isError: true,
              );
              completeAttempt({
                "status": false,
                "skipped": true,
                "reason": "show_timeout",
                "shown": true,
                "error": localizeTrEn(_lang, "Zaman asimi", "Timeout"),
              });
            });
            ad.show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                rewardEarned = true;
                _logAdDebug(
                  'rewarded',
                  'attempt=$attemptNumber reward_earned amount=${reward.amount} type=${_sanitizeAdLogText(reward.type, maxLength: 80)}',
                );
              },
            );
          } catch (e) {
            shownSafetyTimer?.cancel();
            final String errMsg = _buildAdErrorDetails(e);
            _logAdDebug(
              'rewarded',
              'attempt=$attemptNumber show_exception',
              error: e,
              isError: true,
            );
            completeAttempt({
              "status": false,
              "skipped": true,
              "reason": "show_exception",
              "error": errMsg,
            });
          }
        },
        onAdFailedToLoad: (LoadAdError err) {
          final String detail = _buildAdErrorDetails(err);
          _logAdDebug(
            'rewarded',
            'attempt=$attemptNumber load_failed',
            error: err,
            isError: true,
          );
          completeAttempt({
            "status": false,
            "skipped": true,
            "reason": "load_failed",
            "error": detail,
          });
        },
      ),
    );

    final Map<String, dynamic> result = await c.future;
    attemptClosed = true;
    loadTimeoutTimer.cancel();
    shownSafetyTimer?.cancel();

    try {
      tempAd?.dispose();
    } catch (_) {}
    _logAdDebug(
      'rewarded',
      'attempt=$attemptNumber completed status=${result["status"]} shown=${result["shown"]} reason=${result["reason"] ?? "-"} api=rewarded',
    );
    return result;
  }

  Future<Map<String, dynamic>> _runSingleLegacyRewardedAdAttempt({
    required String adUnit,
    required bool useNpa,
    required Duration attemptTimeout,
    required int attemptNumber,
  }) async {
    final Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    InterstitialAd? tempAd;
    bool attemptClosed = false;
    bool adWasShown = false;
    late final Timer loadTimeoutTimer;
    Timer? shownSafetyTimer;

    _logAdDebug(
      'rewarded',
      'attempt=$attemptNumber load_start unit=$adUnit timeout_ms=${attemptTimeout.inMilliseconds} npa=$useNpa api=legacy_interstitial',
    );

    void completeAttempt(Map<String, dynamic> value) {
      if (attemptClosed || c.isCompleted) return;
      c.complete(value);
    }

    loadTimeoutTimer = Timer(attemptTimeout, () {
      if (attemptClosed || c.isCompleted) return;
      if (adWasShown) return;
      _logAdDebug(
        'rewarded',
        'attempt=$attemptNumber load_timeout',
        isError: true,
      );
      completeAttempt({
        "status": false,
        "skipped": true,
        "reason": "load_timeout",
        "error": localizeTrEn(_lang, "Zaman aÃ…Å¸Ã„Â±mÃ„Â±", "Timeout"),
      });
    });

    InterstitialAd.load(
      adUnitId: adUnit,
      request: AdRequest(nonPersonalizedAds: useNpa),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _logAdDebug(
            'rewarded',
            'attempt=$attemptNumber ad_loaded',
            responseInfo: ad.responseInfo,
          );
          if (attemptClosed || c.isCompleted) {
            try {
              ad.dispose();
            } catch (_) {}
            return;
          }
          tempAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _hideAdCloseButton();
              try {
                ad.dispose();
              } catch (_) {}
              if (attemptClosed || c.isCompleted) return;
              _logAdDebug(
                'rewarded',
                'attempt=$attemptNumber dismissed',
              );
              completeAttempt({
                "status": true,
                "shown": true,
              });
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              _hideAdCloseButton();
              try {
                ad.dispose();
              } catch (_) {}
              if (attemptClosed) return;
              final ResponseInfo? responseInfo =
                  _tryAdResponseInfoFromObject(ad);
              final String detail =
                  _buildAdErrorDetails(err, responseInfo: responseInfo);
              final String errMsg = detail;
              _logAdDebug(
                'rewarded',
                'attempt=$attemptNumber show_failed',
                error: err,
                responseInfo: responseInfo,
                isError: true,
              );
              completeAttempt({
                "status": false,
                "skipped": true,
                "reason": "show_failed",
                "error": errMsg,
              });
            },
          );
          try {
            if (attemptClosed) return;
            loadTimeoutTimer.cancel();
            adWasShown = true;
            shownSafetyTimer?.cancel();
            shownSafetyTimer = Timer(_rewardedShownSafetyTimeout, () {
              if (attemptClosed || c.isCompleted) return;
              _logAdDebug(
                'rewarded',
                'attempt=$attemptNumber show_timeout',
                isError: true,
              );
              completeAttempt({
                "status": false,
                "skipped": true,
                "reason": "show_timeout",
                "shown": true,
                "error": localizeTrEn(_lang, "Zaman aÃ…Å¸Ã„Â±mÃ„Â±", "Timeout"),
              });
            });
            ad.show();
          } catch (e) {
            final String errMsg = _buildAdErrorDetails(e);
            _logAdDebug(
              'rewarded',
              'attempt=$attemptNumber show_exception',
              error: e,
              isError: true,
            );
            completeAttempt({
              "status": false,
              "skipped": true,
              "reason": "show_exception",
              "error": errMsg,
            });
          }
        },
        onAdFailedToLoad: (LoadAdError err) {
          debugPrint("Ad failed to load: $err");
          final String detail = _buildAdErrorDetails(err);
          final String errMsg = detail;
          _logAdDebug(
            'rewarded',
            'attempt=$attemptNumber load_failed',
            error: err,
            isError: true,
          );
          completeAttempt({
            "status": false,
            "skipped": true,
            "reason": "load_failed",
            "error": errMsg,
          });
        },
      ),
    );

    final Map<String, dynamic> result = await c.future;
    attemptClosed = true;
    loadTimeoutTimer.cancel();
    shownSafetyTimer?.cancel();

    try {
      tempAd?.dispose();
    } catch (_) {}
    _logAdDebug(
      'rewarded',
      'attempt=$attemptNumber completed status=${result["status"]} shown=${result["shown"]} reason=${result["reason"] ?? "-"} api=legacy_interstitial',
    );
    return result;
  }

  Future<Map<String, dynamic>> _showRewardedAdWithResult(
      {String? adUnitOverride}) async {
    if (_adsDisabled) {
      _logAdDebug('rewarded', 'flow_skipped ads_disabled');
      return {
        "status": true,
        "skipped": true,
        "reason": "ads_disabled",
      };
    }
    if (_isRewardedLoading) {
      _logAdDebug(
        'rewarded',
        'flow_rejected ad_busy (another rewarded flow is active)',
        isError: true,
      );
      return {
        "status": false,
        "skipped": true,
        "reason": "ad_busy",
      };
    }
    if (mounted) {
      setState(() {
        _isRewardedLoading = true;
      });
    } else {
      _isRewardedLoading = true;
    }

    final String adUnit = adUnitOverride ??
        (Platform.isAndroid
            ? _analysisRewardedAdUnitIdAndroid
            : _analysisRewardedAdUnitIdIos);

    final bool useNpa = await _shouldUseNonPersonalizedAds();
    _logAdDebug(
      'rewarded',
      'flow_start unit=$adUnit npa=$useNpa max_window_ms=${_rewardedRetryMaxWindow.inMilliseconds}',
    );
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? loadingSnack;
    if (mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
        final String searchingText =
            _t('loading_ad').replaceAll('\n', ' ').trim();
        loadingSnack = messenger.showSnackBar(SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.1,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(searchingText),
              ),
            ],
          ),
          duration: _rewardedRetryMaxWindow,
          backgroundColor: _storySnackColor(),
        ));
      }
    }

    final DateTime retryDeadline = DateTime.now().add(_rewardedRetryMaxWindow);
    const int hardCap = 2;
    int attempt = 0;
    Map<String, dynamic> result = {
      "status": false,
      "skipped": true,
      "reason": "load_timeout",
      "error": localizeTrEn(_lang, "Zaman a\u015f\u0131m\u0131", "Timeout"),
    };
    while (attempt < hardCap) {
      if (_adsDisabled) {
        result = {
          "status": true,
          "skipped": true,
          "reason": "ads_disabled",
        };
        break;
      }

      final Duration remainingWindow = retryDeadline.difference(DateTime.now());
      if (remainingWindow <= Duration.zero) break;

      attempt++;
      _logAdDebug(
        'rewarded',
        'attempt=$attempt begin remaining_ms=${remainingWindow.inMilliseconds}',
      );
      result = await _runSingleRewardedAdAttempt(
        adUnit: adUnit,
        useNpa: useNpa,
        attemptTimeout: remainingWindow < _rewardedSingleAttemptTimeout
            ? remainingWindow
            : _rewardedSingleAttemptTimeout,
        attemptNumber: attempt,
      );
      result["attempt"] = attempt;
      _logAdDebug(
        'rewarded',
        'attempt=$attempt result status=${result["status"]} shown=${result["shown"]} reason=${result["reason"] ?? "-"}',
      );

      if (result["status"] == true) break;
      if (result["shown"] == true) break;

      final bool userCaused = _isUserCausedAdFailure(result);
      final String reason = (result["reason"] ?? '').toString().toLowerCase();
      if (userCaused || reason == 'reward_not_earned') break;

      final Duration remainingAfterAttempt =
          retryDeadline.difference(DateTime.now());
      if (remainingAfterAttempt <= Duration.zero) break;
      final Duration waitDuration =
          remainingAfterAttempt < _rewardedAggressiveRetryInterval
              ? remainingAfterAttempt
              : _rewardedAggressiveRetryInterval;
      if (waitDuration > Duration.zero) {
        _logAdDebug(
          'rewarded',
          'attempt=$attempt retry_wait_ms=${waitDuration.inMilliseconds}',
        );
        await Future.delayed(waitDuration);
      }
    }
    try {
      loadingSnack?.close();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isRewardedLoading = false;
      });
    } else {
      _isRewardedLoading = false;
    }

    final bool skipped = result["skipped"] == true;
    if (result["status"] == true && !skipped) {
      _logAdDebug(
          'rewarded', 'flow_success attempt=${result["attempt"] ?? "-"}');
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
      _logAdDebug(
        'rewarded',
        'flow_end_no_fill status=${result["status"]} shown=${result["shown"]} reason=${result["reason"] ?? "-"}',
        isError: true,
      );
      if (err.isNotEmpty) {
        _setGoogleAdWarning(err);
      }
    }
    return result;
  }

  void _hideAdCloseButton() {
    // Intentionally empty - placeholder for future native ad close button hiding
  }

  Future<void> _prefetchEntryInterstitialAd() async {
    if (_adsDisabled ||
        _isEntryInterstitialInFlight ||
        _isEntryInterstitialPreloadInFlight) {
      return;
    }
    if (_entryInterstitialAd != null) return;
    if (_entryInterstitialPrefetchRetryTimer != null &&
        _entryInterstitialPrefetchRetryTimer!.isActive) {
      return;
    }

    bool canRequestAds = false;
    try {
      canRequestAds = await _adConsentFlow.canRequestAds();
    } catch (_) {
      canRequestAds = false;
    }
    if (!canRequestAds || _adsDisabled || _isEntryInterstitialInFlight) return;

    _isEntryInterstitialPreloadInFlight = true;
    _entryInterstitialPrefetchRetryTimer?.cancel();
    _entryInterstitialPrefetchRetryTimer = null;
    final String adUnit = Platform.isAndroid
        ? _entryInterstitialAdUnitIdAndroid
        : _entryInterstitialAdUnitIdIos;

    void completePrefetchAttempt({
      Object? retryError,
      bool loaded = false,
    }) {
      _entryInterstitialPrefetchTimeoutTimer?.cancel();
      _entryInterstitialPrefetchTimeoutTimer = null;
      _isEntryInterstitialPreloadInFlight = false;
      if (loaded) {
        _entryInterstitialPrefetchFailureCount = 0;
        _entryInterstitialPrefetchRetryTimer?.cancel();
        _entryInterstitialPrefetchRetryTimer = null;
        return;
      }
      if (retryError != null && _isRetryableAdLoadError(retryError)) {
        _scheduleEntryInterstitialPrefetchRetry(error: retryError);
      }
    }

    try {
      final bool useNpa = await _shouldUseNonPersonalizedAds();
      _logAdDebug(
        'entry_interstitial',
        'prefetch_start unit=$adUnit npa=$useNpa',
      );
      _entryInterstitialPrefetchTimeoutTimer =
          Timer(_entryInterstitialLoadTimeout, () {
        if (!_isEntryInterstitialPreloadInFlight ||
            _entryInterstitialAd != null) return;
        _logAdDebug(
          'entry_interstitial',
          'prefetch_timeout',
          isError: true,
        );
        completePrefetchAttempt(
            retryError: TimeoutException('prefetch_timeout'));
      });
      InterstitialAd.load(
        adUnitId: adUnit,
        request: AdRequest(nonPersonalizedAds: useNpa),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            if (!mounted || _adsDisabled || _isEntryInterstitialInFlight) {
              try {
                ad.dispose();
              } catch (_) {}
              completePrefetchAttempt();
              return;
            }
            _entryInterstitialAd?.dispose();
            _entryInterstitialAd = ad;
            completePrefetchAttempt(loaded: true);
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                _hideAdCloseButton();
                try {
                  ad.dispose();
                } catch (_) {}
                if (identical(_entryInterstitialAd, ad)) {
                  _entryInterstitialAd = null;
                }
                unawaited(_prefetchEntryInterstitialAd());
              },
              onAdFailedToShowFullScreenContent:
                  (InterstitialAd ad, AdError err) {
                _hideAdCloseButton();
                try {
                  ad.dispose();
                } catch (_) {}
                if (identical(_entryInterstitialAd, ad)) {
                  _entryInterstitialAd = null;
                }
                unawaited(_prefetchEntryInterstitialAd());
              },
            );
            _logAdDebug(
              'entry_interstitial',
              'prefetch_loaded',
              responseInfo: ad.responseInfo,
            );
          },
          onAdFailedToLoad: (LoadAdError err) {
            _logAdDebug(
              'entry_interstitial',
              'prefetch_failed',
              error: err,
              isError: true,
            );
            completePrefetchAttempt(retryError: err);
          },
        ),
      );
    } catch (e) {
      _logAdDebug(
        'entry_interstitial',
        'prefetch_exception',
        error: e,
        isError: true,
      );
      completePrefetchAttempt(retryError: e);
    }
  }

  Duration _nextEntryInterstitialPrefetchRetryDelay(Object error) {
    _entryInterstitialPrefetchFailureCount =
        min(_entryInterstitialPrefetchFailureCount + 1, 12);
    if (_isAdNoFillError(error)) {
      return Duration(
        seconds: min(90, 25 + _entryInterstitialPrefetchFailureCount * 10),
      );
    }
    if (_isRetryableAdLoadError(error)) {
      return Duration(
        seconds: min(75, 25 + _entryInterstitialPrefetchFailureCount * 8),
      );
    }
    return _entryInterstitialPrefetchRetryBase;
  }

  void _scheduleEntryInterstitialPrefetchRetry({
    required Object error,
  }) {
    if (!mounted ||
        _adsDisabled ||
        _entryInterstitialAd != null ||
        _isEntryInterstitialInFlight) {
      return;
    }
    final Duration delay = _nextEntryInterstitialPrefetchRetryDelay(error);
    _entryInterstitialPrefetchRetryTimer?.cancel();
    _entryInterstitialPrefetchRetryTimer = Timer(delay, () {
      _entryInterstitialPrefetchRetryTimer = null;
      if (!mounted ||
          _adsDisabled ||
          _entryInterstitialAd != null ||
          _isEntryInterstitialInFlight) {
        return;
      }
      unawaited(_prefetchEntryInterstitialAd());
    });
  }

  Future<void> _showEntryInterstitialIfEligible(String placement) async {
    if (_adsDisabled || _isEntryInterstitialInFlight) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String todayKey =
        'ei_date_${DateTime.now().toIso8601String().substring(0, 10)}';
    final int todayCount = prefs.getInt(todayKey) ?? 0;

    if (todayCount >= _entryInterstitialMaxDailyLimit) {
      _logAdDebug('entry_interstitial', 'skipped daily_limit_reached');
      return;
    }

    if (_lastEntryInterstitialShown != null) {
      final elapsed = DateTime.now().difference(_lastEntryInterstitialShown!);
      if (elapsed.inSeconds < _entryInterstitialMinIntervalSeconds) {
        _logAdDebug('entry_interstitial',
            'skipped too_recent interval=${elapsed.inSeconds}s');
        return;
      }
    }

    const String detailOpenCountKey = 'entry_interstitial_detail_open_count';
    final int detailOpenCount = (prefs.getInt(detailOpenCountKey) ?? 0) + 1;
    await prefs.setInt(detailOpenCountKey, detailOpenCount);
    final bool cadenceEligible = placement == 'analysis_end' ||
        (detailOpenCount >= _entryInterstitialFirstEligibleDetailOpen &&
            (detailOpenCount - _entryInterstitialFirstEligibleDetailOpen) %
                    _entryInterstitialDetailOpenInterval ==
                0);
    if (!cadenceEligible) {
      _logAdDebug(
        'entry_interstitial',
        'skipped cadence detail_open_count=$detailOpenCount',
      );
      return;
    }

    final int totalCount = prefs.getInt('entry_interstitial_total') ?? 0;

    bool canRequestAds = false;
    try {
      canRequestAds = await _adConsentFlow.canRequestAds();
    } catch (_) {
      canRequestAds = false;
    }
    if (!canRequestAds) return;

    _isEntryInterstitialInFlight = true;
    final Completer<void> flowCompleter = Completer<void>();
    Timer? loadTimeoutTimer;
    final String adUnit = Platform.isAndroid
        ? _entryInterstitialAdUnitIdAndroid
        : _entryInterstitialAdUnitIdIos;

    void finishFlow() {
      loadTimeoutTimer?.cancel();
      if (!flowCompleter.isCompleted) {
        flowCompleter.complete();
      }
    }

    void recordShown() {
      _lastEntryInterstitialShown = DateTime.now();
      unawaited(prefs.setInt(todayKey, todayCount + 1));
      unawaited(prefs.setInt('entry_interstitial_total', totalCount + 1));
    }

    try {
      final bool useNpa = await _shouldUseNonPersonalizedAds();
      final InterstitialAd? cachedAd = _entryInterstitialAd;
      if (cachedAd != null) {
        _entryInterstitialAd = null;
        _logAdDebug(
          'entry_interstitial',
          'show_cached placement=$placement unit=$adUnit npa=$useNpa',
          responseInfo: cachedAd.responseInfo,
        );
        cachedAd.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (InterstitialAd ad) {
            recordShown();
            _logAdDebug(
              'entry_interstitial',
              'showed placement=$placement detail_open_count=$detailOpenCount',
              responseInfo: ad.responseInfo,
            );
          },
          onAdDismissedFullScreenContent: (InterstitialAd ad) {
            _hideAdCloseButton();
            _logAdDebug(
              'entry_interstitial',
              'dismissed placement=$placement',
              responseInfo: ad.responseInfo,
            );
            try {
              ad.dispose();
            } catch (_) {}
            if (identical(_entryInterstitialAd, ad)) {
              _entryInterstitialAd = null;
            }
            unawaited(_prefetchEntryInterstitialAd());
            finishFlow();
          },
          onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError err) {
            _hideAdCloseButton();
            _logAdDebug(
              'entry_interstitial',
              'show_failed placement=$placement',
              error: err,
              responseInfo: ad.responseInfo,
              isError: true,
            );
            try {
              ad.dispose();
            } catch (_) {}
            if (identical(_entryInterstitialAd, ad)) {
              _entryInterstitialAd = null;
            }
            unawaited(_prefetchEntryInterstitialAd());
            finishFlow();
          },
        );
        try {
          cachedAd.show();
        } catch (e) {
          _logAdDebug(
            'entry_interstitial',
            'show_exception_cached placement=$placement',
            error: e,
            responseInfo: cachedAd.responseInfo,
            isError: true,
          );
          try {
            cachedAd.dispose();
          } catch (_) {}
          finishFlow();
        }
        await flowCompleter.future;
        return;
      }

      _entryInterstitialAd?.dispose();
    } catch (_) {}
    _entryInterstitialAd = null;

    try {
      final bool useNpa = await _shouldUseNonPersonalizedAds();
      _logAdDebug(
        'entry_interstitial',
        'load_start placement=$placement unit=$adUnit npa=$useNpa',
      );
      loadTimeoutTimer = Timer(_entryInterstitialLoadTimeout, () {
        _logAdDebug(
          'entry_interstitial',
          'load_timeout placement=$placement',
          isError: true,
        );
        finishFlow();
      });
      InterstitialAd.load(
        adUnitId: adUnit,
        request: AdRequest(nonPersonalizedAds: useNpa),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            if (flowCompleter.isCompleted) {
              try {
                ad.dispose();
              } catch (_) {}
              return;
            }
            loadTimeoutTimer?.cancel();
            _entryInterstitialAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) {
                recordShown();
                _logAdDebug(
                  'entry_interstitial',
                  'showed placement=$placement detail_open_count=$detailOpenCount',
                  responseInfo: ad.responseInfo,
                );
              },
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                _hideAdCloseButton();
                _logAdDebug(
                  'entry_interstitial',
                  'dismissed placement=$placement',
                  responseInfo: ad.responseInfo,
                );
                try {
                  ad.dispose();
                } catch (_) {}
                if (identical(_entryInterstitialAd, ad)) {
                  _entryInterstitialAd = null;
                }
                unawaited(_prefetchEntryInterstitialAd());
                finishFlow();
              },
              onAdFailedToShowFullScreenContent:
                  (InterstitialAd ad, AdError err) {
                _hideAdCloseButton();
                _logAdDebug(
                  'entry_interstitial',
                  'show_failed placement=$placement',
                  error: err,
                  responseInfo: ad.responseInfo,
                  isError: true,
                );
                try {
                  ad.dispose();
                } catch (_) {}
                if (identical(_entryInterstitialAd, ad)) {
                  _entryInterstitialAd = null;
                }
                unawaited(_prefetchEntryInterstitialAd());
                finishFlow();
              },
            );
            _logAdDebug(
              'entry_interstitial',
              'loaded placement=$placement',
              responseInfo: ad.responseInfo,
            );
            try {
              ad.show();
            } catch (e) {
              _logAdDebug(
                'entry_interstitial',
                'show_exception placement=$placement',
                error: e,
                responseInfo: ad.responseInfo,
                isError: true,
              );
              try {
                ad.dispose();
              } catch (_) {}
              if (identical(_entryInterstitialAd, ad)) {
                _entryInterstitialAd = null;
              }
              unawaited(_prefetchEntryInterstitialAd());
              finishFlow();
            }
          },
          onAdFailedToLoad: (LoadAdError err) {
            _logAdDebug(
              'entry_interstitial',
              'load_failed placement=$placement',
              error: err,
              isError: true,
            );
            finishFlow();
          },
        ),
      );
      await flowCompleter.future;
    } catch (e) {
      _logAdDebug(
        'entry_interstitial',
        'flow_exception placement=$placement',
        error: e,
        isError: true,
      );
    } finally {
      loadTimeoutTimer?.cancel();
      _isEntryInterstitialInFlight = false;
      try {
        _entryInterstitialAd?.dispose();
      } catch (_) {}
      _entryInterstitialAd = null;
      unawaited(_prefetchEntryInterstitialAd());
    }
  }

  Future<DateTime> _getEstimatedNetworkTime() async {
    if (_networkTimeOffsetMs != null) {
      return DateTime.now().add(Duration(milliseconds: _networkTimeOffsetMs!));
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? offsetMs =
          prefs.getInt(_accountScopedKey(_networkTimeOffsetKey));
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
          await prefs.setInt(
              _accountScopedKey(_networkTimeOffsetKey), offsetMs);
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
    final int? lastMs = prefs.getInt(_accountScopedKey('last_update_time'));
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
      Duration remaining = _analysisCooldown - now.difference(last);
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

  void _activateIgSafetyCooldown(
      [Duration duration = _igSafetyCooldownDefault]) {
    Duration normalized = duration;
    if (normalized < _igSafetyCooldownMin) {
      normalized = _igSafetyCooldownMin;
    } else if (normalized > _igSafetyCooldownMax) {
      normalized = _igSafetyCooldownMax;
    }
    final DateTime now = DateTime.now();
    final DateTime next = now.add(normalized);
    final DateTime? current = _igSafetyCooldownUntil;
    if (current == null || next.isAfter(current)) {
      _igSafetyCooldownUntil = next;
    }
  }

  void _registerIgRiskSignal(
      {Duration minimumCooldown = _igSafetyCooldownDefault}) {
    final DateTime now = DateTime.now();
    final DateTime? last = _igLastRiskSignalAt;
    if (last == null || now.difference(last) > const Duration(hours: 12)) {
      _igRiskSignalCount = 0;
    }
    _igLastRiskSignalAt = now;
    _igRiskSignalCount = min(6, _igRiskSignalCount + 1);

    Duration escalated = minimumCooldown;
    if (_igRiskSignalCount >= 5) {
      escalated = const Duration(hours: 3);
    } else if (_igRiskSignalCount == 4) {
      escalated = const Duration(minutes: 90);
    } else if (_igRiskSignalCount == 3) {
      escalated = const Duration(minutes: 60);
    } else if (_igRiskSignalCount == 2) {
      escalated = const Duration(minutes: 35);
    } else {
      escalated = minimumCooldown >= _igSafetyCooldownDefault
          ? minimumCooldown
          : _igSafetyCooldownDefault;
    }
    _activateIgSafetyCooldown(escalated);
  }

  Duration? _retryAfterDurationFromHeaders(Map<String, String> headers) {
    String? retryAfterRaw;
    for (final MapEntry<String, String> entry in headers.entries) {
      if (entry.key.toLowerCase() == 'retry-after') {
        retryAfterRaw = entry.value.trim();
        break;
      }
    }
    if (retryAfterRaw == null || retryAfterRaw.isEmpty) return null;

    final int? seconds = int.tryParse(retryAfterRaw);
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds);
    }

    try {
      final DateTime retryAt = HttpDate.parse(retryAfterRaw);
      final Duration diff = retryAt.difference(DateTime.now().toUtc());
      if (diff > Duration.zero) return diff;
    } catch (_) {}

    return null;
  }

  void _activateIgSafetyCooldownFromHeaders(
    Map<String, String> headers, {
    Duration fallback = _igSafetyCooldown429Fallback,
  }) {
    final Duration cooldown =
        _retryAfterDurationFromHeaders(headers) ?? fallback;
    _registerIgRiskSignal(minimumCooldown: cooldown);
  }

  Duration? _remainingIgSafetyCooldown() {
    final DateTime? until = _igSafetyCooldownUntil;
    if (until == null) return null;
    final Duration left = until.difference(DateTime.now());
    if (left <= Duration.zero) {
      _igSafetyCooldownUntil = null;
      return null;
    }
    return left;
  }

  Duration? _remainingAnalysisSafetyDelay() {
    if (_analysisSafetyMinGap <= Duration.zero) return null;
    final DateTime? last = _lastAnalysisRequestAt;
    if (last == null) return null;
    final Duration left =
        _analysisSafetyMinGap - DateTime.now().difference(last);
    if (left <= Duration.zero) return null;
    return left;
  }

  int _viewWindowCount(
    SharedPreferences prefs,
    DateTime now, {
    required String countKey,
    required String lastViewKey,
  }) {
    final String accountUserId = _currentAccountUserId();
    final int? lastMs = prefs.getInt(
      _accountScopedKey(lastViewKey, userId: accountUserId),
    );
    if (lastMs == null) return 0;
    final DateTime last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (now.difference(last) >= _storyGateCooldown) return 0;
    return prefs.getInt(_accountScopedKey(countKey, userId: accountUserId)) ??
        1;
  }

  Future<void> _incrementViewWindowCount(
    SharedPreferences prefs,
    DateTime now, {
    required String countKey,
    required String lastViewKey,
  }) async {
    final int current = _viewWindowCount(
      prefs,
      now,
      countKey: countKey,
      lastViewKey: lastViewKey,
    );
    final String accountUserId = _currentAccountUserId();
    await _setAccountPrefInt(prefs, countKey, current + 1,
        userId: accountUserId);
    await _setAccountPrefInt(prefs, lastViewKey, now.millisecondsSinceEpoch,
        userId: accountUserId);
  }

  Future<void> _incrementStoryWindowCount(
      SharedPreferences prefs, DateTime now) async {
    await _incrementViewWindowCount(
      prefs,
      now,
      countKey: _storyWindowCountKey,
      lastViewKey: _storyLastViewTimeKey,
    );
  }

  Future<void> _incrementPhotoWindowCount(
      SharedPreferences prefs, DateTime now) async {
    await _incrementViewWindowCount(
      prefs,
      now,
      countKey: _photoWindowCountKey,
      lastViewKey: _photoLastViewTimeKey,
    );
  }

  int _analysisWindowCount(SharedPreferences prefs, DateTime now) {
    final String accountUserId = _currentAccountUserId();
    final int? lastMs = prefs.getInt(
      _accountScopedKey('last_update_time', userId: accountUserId),
    );
    if (lastMs == null) return 0;
    final DateTime last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (now.difference(last) >= _analysisCooldown) return 0;
    return max(
        1,
        prefs.getInt(_accountScopedKey(_analysisWindowCountKey,
                userId: accountUserId)) ??
            1);
  }

  String _premiumCardTitle() => 'VERDICT PREMIUM';

  String _localizedSubscriptionLength(String rawPeriod) {
    final Match? match = RegExp(
      r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$',
      caseSensitive: false,
    ).firstMatch(rawPeriod.trim());

    if (match == null) {
      return localizeTrEn(_lang, '1 ay', '1 month');
    }

    String formatPart(
        int value, String trUnit, String enSingular, String enPlural) {
      return localizeTrEn(
        _lang,
        '$value $trUnit',
        value == 1 ? '1 $enSingular' : '$value $enPlural',
      );
    }

    final List<String> parts = <String>[];
    final int years = int.tryParse(match.group(1) ?? '') ?? 0;
    final int months = int.tryParse(match.group(2) ?? '') ?? 0;
    final int weeks = int.tryParse(match.group(3) ?? '') ?? 0;
    final int days = int.tryParse(match.group(4) ?? '') ?? 0;

    if (years > 0) parts.add(formatPart(years, 'yıl', 'year', 'years'));
    if (months > 0) parts.add(formatPart(months, 'ay', 'month', 'months'));
    if (weeks > 0) parts.add(formatPart(weeks, 'hafta', 'week', 'weeks'));
    if (days > 0) parts.add(formatPart(days, 'gün', 'day', 'days'));

    return parts.isEmpty
        ? localizeTrEn(_lang, '1 ay', '1 month')
        : parts.join(', ');
  }

  MapEntry<String, String>? _subscriptionUnitPriceDetails(
      SubscriptionDisplayInfo info) {
    final String normalizedPeriod =
        info.subscriptionPeriod.trim().toUpperCase();

    MapEntry<String, String>? entryFor(
      String? value, {
      required String trLabel,
      required String enLabel,
    }) {
      final String clean = value?.trim() ?? '';
      if (clean.isEmpty) return null;
      return MapEntry<String, String>(
        localizeTrEn(_lang, trLabel, enLabel),
        clean,
      );
    }

    if (normalizedPeriod.contains('Y')) {
      return entryFor(
            info.pricePerMonth,
            trLabel: 'Aylık fiyat',
            enLabel: 'Price per month',
          ) ??
          entryFor(
            info.pricePerYear,
            trLabel: 'Yıllık fiyat',
            enLabel: 'Price per year',
          );
    }

    if (normalizedPeriod.contains('M')) {
      return entryFor(
        info.pricePerMonth,
        trLabel: 'Aylık fiyat',
        enLabel: 'Price per month',
      );
    }

    if (normalizedPeriod.contains('W')) {
      return entryFor(
        info.pricePerWeek,
        trLabel: 'Haftalık fiyat',
        enLabel: 'Price per week',
      );
    }

    return null;
  }

  Widget _buildSubscriptionDetailRow({
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefit({
    required IconData icon,
    required String text,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDarkMode ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withOpacity(isDarkMode ? 0.26 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showSubscriptionDetailsDialog() async {
    await PurchasesService.instance.configure(
      androidApiKey: _revenueCatAndroidApiKey,
      iosApiKey: _revenueCatIosApiKey,
    );
    final bool isPurchaseReady = PurchasesService.instance.isConfigured;

    final SubscriptionDisplayInfo? subInfo = isPurchaseReady
        ? await PurchasesService.instance.getMonthlySubscriptionDisplayInfo()
        : null;
    final bool hasTrial = isPurchaseReady
        ? await PurchasesService.instance.hasEligibleThreeDayTrialForMonthly()
        : false;
    final String subscriptionTitle =
        subInfo != null && subInfo.title.trim().isNotEmpty
            ? subInfo.title.trim()
            : _premiumCardTitle();
    final String subscriptionPrice =
        subInfo != null && subInfo.price.trim().isNotEmpty
            ? subInfo.price.trim()
            : localizeTrEn(
                _lang,
                'Fiyat App Store üzerinde gösterilecektir.',
                'The price will be shown in the App Store.',
              );
    final String subscriptionLength = _localizedSubscriptionLength(
      subInfo?.subscriptionPeriod ?? 'P1M',
    );
    final MapEntry<String, String>? unitPriceDetails =
        subInfo == null ? null : _subscriptionUnitPriceDetails(subInfo);
    final String purchaseNote = _purchaseNotConfiguredMessage();

    if (!mounted) return false;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: Colors.amber.shade600, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _premiumCardTitle(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('premium_main_description'),
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _buildSubscriptionDetailRow(
                label: localizeTrEn(
                  _lang,
                  'Otomatik yenilenen abonelik',
                  'Auto-renewing subscription',
                ),
                value: subscriptionTitle,
              ),
              const SizedBox(height: 8),
              _buildSubscriptionDetailRow(
                label: localizeTrEn(
                  _lang,
                  'Abonelik süresi',
                  'Subscription length',
                ),
                value: subscriptionLength,
              ),
              const SizedBox(height: 8),
              _buildSubscriptionDetailRow(
                label: localizeTrEn(
                  _lang,
                  'Abonelik fiyatı',
                  'Subscription price',
                ),
                value: subscriptionPrice,
              ),
              if (unitPriceDetails != null &&
                  unitPriceDetails.value.trim() !=
                      subscriptionPrice.trim()) ...[
                const SizedBox(height: 8),
                _buildSubscriptionDetailRow(
                  label: unitPriceDetails.key,
                  value: unitPriceDetails.value,
                ),
              ],
              if (hasTrial) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.shade700.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.celebration_rounded,
                          color: Colors.green.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _t('subscription_3day_trial_notice'),
                          style: TextStyle(
                            color: Colors.green.shade400,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                _t('premium_benefits_title'),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _buildPremiumBenefit(
                icon: Icons.block_rounded,
                accent: Colors.purple.shade300,
                text: _t('premium_benefit_no_ads'),
              ),
              const SizedBox(height: 8),
              _buildPremiumBenefit(
                icon: Icons.flash_on_rounded,
                accent: Colors.orange.shade300,
                text: _t('premium_benefit_fast'),
              ),
              const SizedBox(height: 8),
              _buildPremiumBenefit(
                icon: Icons.all_inclusive_rounded,
                accent: Colors.lightBlue.shade300,
                text: _t('premium_benefit_unlimited'),
              ),
              if (purchaseNote.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(isDarkMode ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.28),
                    ),
                  ),
                  child: Text(
                    purchaseNote,
                    style: TextStyle(
                      color: isDarkMode ? Colors.orange.shade200 : Colors.brown,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx, null);
                    _restorePurchasesPressed();
                  },
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: Text(
                    _t('subscription_restore_purchases'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white70 : Colors.black54,
                    side: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _showPrivacyPolicyDialog,
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: Text(
                    localizedPrivacyPolicyLabel(_lang),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white70 : Colors.black54,
                    side: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _openAppleEula,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text(
                    'EULA',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white70 : Colors.black54,
                    side: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizeTrEn(
                  _lang,
                  'Aboneliği başlatarak Gizlilik Politikamızı ve Apple Standart EULA sözleşmesini kabul etmiş olursunuz.',
                  'By subscribing, you agree to our Privacy Policy and Apple\'s Standard EULA.',
                ),
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _t('cancel'),
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.black45,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              hasTrial
                  ? _t('subscription_start_trial')
                  : _t('subscription_subscribe'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<bool> _startPremiumPurchaseFlow() async {
    if (PurchasesService.instance.isPremium.value) return true;
    _logFirebaseDiagnostic(
        'purchase', 'purchase flow started from premium gate');

    final bool proceed = await _showSubscriptionDetailsDialog();
    if (!proceed) {
      _logFirebaseDiagnostic(
          'purchase', 'subscription dialog cancelled by user');
      return false;
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
      final String purchaseMessage = _purchaseNotConfiguredMessage();
      if (mounted && purchaseMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(purchaseMessage),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.redAccent,
        ));
      }
      return false;
    }

    if (!mounted) return false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
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
                localizeTrEn(_lang, 'Satın alma başlatılıyor...',
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
      ),
    );

    final PurchaseAttemptResult result =
        await PurchasesService.instance.makePurchase();
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    if (!mounted) return false;

    if (result.cancelled) {
      _logFirebaseDiagnostic('purchase', 'purchase cancelled by user');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizeTrEn(
            _lang, 'Satın alma iptal edildi.', 'Purchase cancelled.')),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blueGrey.shade900,
      ));
      return false;
    }

    if (result.success) {
      _logFirebaseDiagnostic('purchase', 'purchase success: premium active');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizeTrEn(
            _lang,
            'Premium aktif … Reklamlar ve bekleme süreleri kapatıldı.',
            'Premium active … Ads and wait times are disabled.')),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green.shade700,
      ));
      return true;
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
    return false;
  }

  Future<bool> _promptPremiumPurchaseIfNeeded(
      SharedPreferences prefs, DateTime now) async {
    if (_adsDisabled) return true;
    if (_analysisWindowCount(prefs, now) < 2) return true;
    return _startPremiumPurchaseFlow();
  }

  Future<void> _showPremiumCardPurchaseDialog() async {
    if (PurchasesService.instance.isPremium.value) {
      _logFirebaseDiagnostic(
          'purchase', 'card dialog skipped: premium already active');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('premium_already_active')),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blueGrey.shade900,
        ));
      }
      return;
    }

    await _startPremiumPurchaseFlow();
  }

  String _sanitizeAdLogText(String input, {int maxLength = 1500}) {
    final String compact =
        input.replaceAll('\r\n', '\n').replaceAll('\n', ' | ').trim();
    if (compact.length <= maxLength) return compact;
    return '${compact.substring(0, maxLength)}...';
  }

  int? _tryAdErrorCode(Object source) {
    try {
      final dynamic value = (source as dynamic).code;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString().trim());
    } catch (_) {
      return null;
    }
  }

  String _tryAdErrorDomain(Object source) {
    try {
      final dynamic value = (source as dynamic).domain;
      return value?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _tryAdErrorMessage(Object source) {
    try {
      final dynamic value = (source as dynamic).message;
      return value?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  ResponseInfo? _tryAdResponseInfoFromObject(Object source) {
    try {
      final dynamic value = (source as dynamic).responseInfo;
      if (value is ResponseInfo) return value;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _buildAdapterResponseDetails(AdapterResponseInfo info) {
    final List<String> parts = <String>[
      'adapter=${_sanitizeAdLogText(info.adapterClassName, maxLength: 120)}',
      'latency_ms=${info.latencyMillis}',
    ];

    final String sourceName = info.adSourceName.trim();
    if (sourceName.isNotEmpty) {
      parts.add('source=${_sanitizeAdLogText(sourceName, maxLength: 80)}');
    }

    final String instanceName = info.adSourceInstanceName.trim();
    if (instanceName.isNotEmpty) {
      parts.add('instance=${_sanitizeAdLogText(instanceName, maxLength: 80)}');
    }

    final String description =
        _sanitizeAdLogText(info.description, maxLength: 160);
    if (description.isNotEmpty) {
      parts.add('desc=$description');
    }

    final AdError? adError = info.adError;
    if (adError != null) {
      parts.add(
        'adapter_error=${_sanitizeAdLogText(_buildAdErrorDetails(adError), maxLength: 220)}',
      );
    }

    return parts.join(', ');
  }

  String _buildAdErrorDetails(
    Object error, {
    ResponseInfo? responseInfo,
  }) {
    final List<String> parts = <String>[
      'type=${error.runtimeType}',
    ];

    final int? code = _tryAdErrorCode(error);
    if (code != null) parts.add('code=$code');

    final String domain = _tryAdErrorDomain(error);
    if (domain.isNotEmpty) parts.add('domain=$domain');

    final String message = _tryAdErrorMessage(error);
    if (message.isNotEmpty) {
      parts.add('message=${_sanitizeAdLogText(message, maxLength: 400)}');
    }

    final ResponseInfo? info =
        responseInfo ?? _tryAdResponseInfoFromObject(error);
    if (info != null) {
      final String responseId = (info.responseId ?? '').trim();
      if (responseId.isNotEmpty) parts.add('response_id=$responseId');

      final String adapter = (info.mediationAdapterClassName ?? '').trim();
      if (adapter.isNotEmpty) parts.add('adapter=$adapter');

      final AdapterResponseInfo? loadedAdapter = info.loadedAdapterResponseInfo;
      if (loadedAdapter != null) {
        final String loadedAdapterDetails =
            _buildAdapterResponseDetails(loadedAdapter);
        if (loadedAdapterDetails.isNotEmpty) {
          parts.add('loaded_adapter=$loadedAdapterDetails');
        }
      }

      final List<AdapterResponseInfo> adapterResponses =
          info.adapterResponses ?? const <AdapterResponseInfo>[];
      if (adapterResponses.isNotEmpty) {
        final String adapterChain = adapterResponses
            .take(4)
            .map(_buildAdapterResponseDetails)
            .join(' || ');
        if (adapterChain.isNotEmpty) {
          parts.add('adapter_chain=$adapterChain');
        }
      }

      if (info.responseExtras.isNotEmpty) {
        parts.add(
          'response_extras=${_sanitizeAdLogText(info.responseExtras.toString(), maxLength: 220)}',
        );
      }

      final String rawInfo =
          _sanitizeAdLogText(info.toString(), maxLength: 320);
      if (rawInfo.isNotEmpty) parts.add('response_info=$rawInfo');
    }

    if (parts.length == 1) {
      final String raw = _sanitizeAdLogText(error.toString(), maxLength: 900);
      if (raw.isNotEmpty) parts.add('raw=$raw');
    }

    return parts.join(' | ');
  }

  void _logAdDebug(
    String area,
    String message, {
    Object? error,
    ResponseInfo? responseInfo,
    bool isError = false,
  }) {}

  void _setGoogleAdWarning(String warning) {}

  void _clearGoogleAdWarning() {}

  double get _nativeAdSlotHeight =>
      Platform.isIOS ? _nativeAdSlotHeightIos : _nativeAdSlotHeightAndroid;

  bool get _shouldShowHeaderBannerPanel {
    return !_adsDisabled && _isHeaderBannerLoaded && _headerBannerAd != null;
  }

  Widget _buildHeaderBannerPanel(Color accentColor) {
    if (!_isHeaderBannerLoaded || _headerBannerAd == null) {
      return const SizedBox.shrink();
    }

    final Color borderColor = accentColor.withOpacity(isDarkMode ? 0.18 : 0.10);
    final Color surfaceColor = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Center(
        child: SizedBox(
          width: _headerBannerAd!.size.width.toDouble(),
          height: _headerBannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _headerBannerAd!),
        ),
      ),
    );
  }

  bool get _shouldShowNativeAdPanel {
    return !_adsDisabled && _isAdLoaded && _bannerAd != null;
  }

  Widget _buildNativeAdPanel(Color accentColor) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final Color borderColor = accentColor.withOpacity(isDarkMode ? 0.20 : 0.12);
    final Color surfaceColor = isDarkMode
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.04);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: double.infinity,
          height: _nativeAdSlotHeight,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  void _showDiagSnackBar(
    String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!_userFacingFirebaseDiagnosticsEnabled && !_canOpenDiagnosticsConsole()) return;
    final SnackBar sb = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
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

  void _appendIgDiagnosticEvent(String line) {
    final List<String> next = List<String>.from(_igDiagnosticEvents.value);
    next.insert(0, line);
    if (next.length > _maxIgDiagnosticEvents) {
      next.removeRange(_maxIgDiagnosticEvents, next.length);
    }
    _igDiagnosticEvents.value = next;
  }

  String _shortenForIgLog(String input, {int maxLength = 1200}) {
    final String clean = input.replaceAll('\r\n', '\n').trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength)}...';
  }

  String _buildIgHeadersLog(Map<String, String> headers) {
    final List<String> keys = headers.keys.toList()..sort();
    final StringBuffer buffer = StringBuffer();
    for (final String key in keys) {
      final String value = headers[key] ?? '';
      final String redacted = _redactIgHeaderValueForLog(key, value);
      final String displayValue = key.toLowerCase() == 'cookie'
          ? _shortenForIgLog(redacted, maxLength: 1600)
          : _shortenForIgLog(redacted, maxLength: 600);
      buffer.writeln('$key: $displayValue');
    }
    return buffer.toString().trimRight();
  }

  void _logIgDiagnostic(
    String phase,
    String message, {
    String? label,
    Uri? uri,
    Map<String, String>? headers,
    Object? error,
    StackTrace? stackTrace,
    int? statusCode,
    Duration? elapsed,
    String? responseBody,
    Map<String, String>? responseHeaders,
    bool isError = false,
  }) {
    final String cleanPhase =
        phase.trim().isEmpty ? 'general' : phase.trim().toUpperCase();
    final String cleanLabel = (label ?? '').trim();
    String cleanMessage = message.replaceAll('\r\n', '\n').trim();
    if (cleanMessage.isEmpty) cleanMessage = '(empty message)';
    if (cleanMessage.length > 2200) {
      cleanMessage = '${cleanMessage.substring(0, 2200)}...';
    }

    final String level = isError ? 'ERROR' : 'INFO';
    final StringBuffer buffer = StringBuffer()
      ..writeln(
        '[${DateTime.now().toIso8601String()}][$level][IG][$cleanPhase] '
        '${cleanLabel.isEmpty ? '' : '[$cleanLabel] '}$cleanMessage',
      );
    if (uri != null) buffer.writeln('uri=$uri');
    if (statusCode != null) buffer.writeln('statusCode=$statusCode');
    if (elapsed != null) buffer.writeln('elapsedMs=${elapsed.inMilliseconds}');
    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('requestHeaders:');
      buffer.writeln(_buildIgHeadersLog(headers));
    }
    if (responseHeaders != null && responseHeaders.isNotEmpty) {
      buffer.writeln('responseHeaders:');
      buffer.writeln(_buildIgHeadersLog(responseHeaders));
    }
    if (responseBody != null && responseBody.isNotEmpty) {
      buffer.writeln(
        'responseBodyPreview=${_shortenForIgLog(responseBody, maxLength: 2200)}',
      );
    }
    if (error != null) buffer.writeln('error=$error');
    if (stackTrace != null) {
      final List<String> stackLines = stackTrace.toString().split('\n');
      final String compactStack = stackLines.take(10).join('\n').trim();
      if (compactStack.isNotEmpty) buffer.writeln('stack=$compactStack');
    }

    final String entry = buffer.toString().trimRight();
    debugPrint('[IG][$cleanPhase][$level] $cleanMessage');
    _appendIgDiagnosticEvent(entry);
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
    final List<String> igEvents = _igDiagnosticEvents.value;
    final List<String> firebaseEvents = _firebaseDiagnosticEvents.value;
    final List<String> purchaseEvents =
        PurchasesService.instance.diagnosticEvents.value;
    final StringBuffer buffer = StringBuffer()
      ..writeln('==== STATUS ====')
      ..writeln(_buildFirebaseStatusSummary())
      ..writeln('')
      ..writeln('==== IG EVENTS (${igEvents.length}) ====');
    for (final String line in igEvents) {
      buffer.writeln(line);
      buffer.writeln('---');
    }
    buffer.writeln('');
    buffer.writeln('==== FIREBASE EVENTS (${firebaseEvents.length}) ====');
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
      final String rawBody = _safeResponseBody(response);
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
          _isFirestoreDatabaseMissingBody(_safeResponseBody(response))) {
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
        'write failed status=${response.statusCode} path=$documentPath reason=$reason merge=$merge body=${_trimForDiagLog(_safeResponseBody(response))}',
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
        localizeTrEn(
            _lang,
            'REST probe baÃ…Å¸arÃ„Â±sÃ„Â±z: kimlik doÃ„Å¸rulama yok.',
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
              'REST probe baÃ…Å¸arÃ„Â±lÃ„Â± (Firestore uÃƒÂ§ noktasÃ„Â±na eriÃ…Å¸ilebiliyor).',
              'REST probe success (Firestore endpoint reachable).'))
          : (localizeTrEn(
              _lang,
              'REST probe baÃ…Å¸arÃ„Â±sÃ„Â±z (loglara bakÃ„Â±n).',
              'REST probe failed (check logs).')),
      backgroundColor: ok ? Colors.green : Colors.red,
      duration: const Duration(seconds: 5),
    );
  }

  String _formatFirestoreDebugValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return value.toDate().toIso8601String();
    final String raw = value.toString().trim();
    if (raw == 'null') return '';
    return raw;
  }

  DateTime? _parseTurkeyDebugDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().add(const Duration(hours: 3));
    }
    if (value is DateTime) {
      return value.toUtc().add(const Duration(hours: 3));
    }

    final String raw =
        _formatFirestoreDebugValue(value).replaceAll('TRT', '').trim();
    if (raw.isEmpty) return null;

    final Match? legacyMatch = RegExp(
      r'^(\d{2})-(\d{2})-(\d{4})[ T](\d{2})[.:](\d{2})[.:](\d{2})',
    ).firstMatch(raw);
    if (legacyMatch != null) {
      try {
        return DateTime.utc(
          int.parse(legacyMatch.group(3)!),
          int.parse(legacyMatch.group(2)!),
          int.parse(legacyMatch.group(1)!),
          int.parse(legacyMatch.group(4)!),
          int.parse(legacyMatch.group(5)!),
          int.parse(legacyMatch.group(6)!),
        );
      } catch (_) {
        return null;
      }
    }

    try {
      final DateTime parsed = DateTime.parse(raw);
      final bool hasExplicitZone =
          raw.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
      if (hasExplicitZone) {
        return parsed.toUtc().add(const Duration(hours: 3));
      }
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatTurkeyDebugDateTime(dynamic value) {
    final DateTime? parsed = _parseTurkeyDebugDateTime(value);
    if (parsed == null) return _formatFirestoreDebugValue(value);
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${_twoDigits(parsed.month)}-'
        '${_twoDigits(parsed.day)} '
        '${_twoDigits(parsed.hour)}:'
        '${_twoDigits(parsed.minute)}:'
        '${_twoDigits(parsed.second)} TRT';
  }

  Future<void> _loadRecentFirebaseAnalyses() async {
    if (!_canViewOwnerFirebaseUserList()) return;
    _logFirebaseDiagnostic('firestore_read', 'recent analyses read started');
    final User? user = await _ensureFirestoreAuthUser();
    if (user == null) {
      _logFirebaseDiagnostic(
        'firestore_read',
        'recent analyses blocked: no auth user',
        isError: true,
      );
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('ig_users')
              .get(const GetOptions(source: Source.server))
              .timeout(_firestoreTimeout);

      if (snapshot.docs.isEmpty) {
        _recentFirebaseAnalysisRows.value = <Map<String, String>>[];
        _logFirebaseDiagnostic(
          'firestore_read',
          'recent analyses read success: no analyzed ig_users documents',
        );
        _showDiagSnackBar(
          localizeTrEn(_lang, 'Kayit bulunamadi.', 'No records found.'),
          backgroundColor: Colors.blueGrey.shade900,
        );
        return;
      }

      final List<MapEntry<DateTime, Map<String, String>>> rows =
          <MapEntry<DateTime, Map<String, String>>>[];
      int documentsWithoutAnalysisDate = 0;
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final dynamic lastAnalysisRaw = data['last_analysis_at'];
        final DateTime? sortDate = _parseTurkeyDebugDateTime(lastAnalysisRaw);
        if (sortDate == null) {
          documentsWithoutAnalysisDate++;
          continue;
        }

        final String rawUsername = _formatFirestoreDebugValue(data['username']);
        final String username = rawUsername.isNotEmpty ? rawUsername : doc.id;
        final String appVersion = _formatFirestoreDebugValue(
          data['app_version'] ?? data['version'],
        );
        final String device = _formatFirestoreDebugValue(data['device_model']);
        final String country = _formatFirestoreDebugValue(data['country_code']);
        final String premium = _formatFirestoreDebugValue(data['is_premium']);
        final String analysisCount =
            _formatFirestoreDebugValue(data['analysis_count']);
        rows.add(MapEntry<DateTime, Map<String, String>>(
          sortDate,
          <String, String>{
            'username': username,
            'last_analysis_at': _formatTurkeyDebugDateTime(lastAnalysisRaw),
            'premium': premium.isEmpty ? '-' : premium,
            'analysis_count': analysisCount.isEmpty ? '0' : analysisCount,
            'app': appVersion.isEmpty ? '-' : appVersion,
            'device': device.isEmpty ? '-' : device,
            'country': country.isEmpty ? '-' : country,
          },
        ));
      }
      rows.sort((a, b) => b.key.compareTo(a.key));
      final List<Map<String, String>> recentRows =
          rows.take(30).map((entry) => entry.value).toList(growable: false);
      _recentFirebaseAnalysisRows.value = recentRows;

      if (recentRows.isEmpty) {
        _recentFirebaseAnalysisRows.value = <Map<String, String>>[];
        _logFirebaseDiagnostic(
          'firestore_read',
          'recent analyses read success but no document has parseable last_analysis_at. skipped=$documentsWithoutAnalysisDate',
        );
        _showDiagSnackBar(
          localizeTrEn(_lang, 'last_analysis_at bulunamadi.',
              'No last_analysis_at records found.'),
          backgroundColor: Colors.blueGrey.shade900,
        );
        return;
      }

      final StringBuffer buffer = StringBuffer()
        ..writeln('Son analiz yapan Instagram kullanicilari '
            '(${recentRows.length}/${snapshot.docs.length}) key=last_analysis_at');
      int index = 0;
      for (final Map<String, String> row in recentRows) {
        index++;
        buffer.writeln(
          '$index. @${row['username']} '
          'last_analysis_at=${row['last_analysis_at']} '
          'premium=${row['premium']} '
          'analiz_sayisi=${row['analysis_count']} '
          'app=${row['app']} '
          'device=${row['device']} '
          'country=${row['country']}',
        );
      }

      _logFirebaseDiagnostic('firestore_read', buffer.toString());
      _showDiagSnackBar(
        localizeTrEn(
            _lang, 'Son analizler yuklendi.', 'Recent analyses loaded.'),
        backgroundColor: Colors.green,
      );
    } catch (e, st) {
      _logFirebaseDiagnostic(
        'firestore_read',
        'recent analyses read failed. Create debug_admins/${user.uid} in Firestore to allow admin reads.',
        error: e,
        stackTrace: st,
        isError: true,
      );
      _showDiagSnackBar(
        localizeTrEn(
          _lang,
          'Firebase okuma izni yok veya sorgu basarisiz.',
          'Firebase read permission is missing or query failed.',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
    }
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
        localizeTrEn(_lang, 'Firebase Auth probe baÃ…Å¸arÃ„Â±sÃ„Â±z.',
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
        localizeTrEn(_lang, 'Firebase Auth probe baÃ…Å¸arÃ„Â±lÃ„Â±.',
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
        localizeTrEn(_lang, 'Firebase token probe baÃ…Å¸arÃ„Â±sÃ„Â±z.',
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
                    localizeTrEn(_lang, 'KRÃ„Â°TÃ„Â°K TEÃ…ÂHÃ„Â°S HATASI',
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

  Color get _diagnosticBgColor =>
      isDarkMode ? const Color(0xFF0B1020) : const Color(0xFFF4F7FB);

  Color get _diagnosticSurfaceColor =>
      isDarkMode ? const Color(0xFF121A2A) : Colors.white;

  Color get _diagnosticCardColor =>
      isDarkMode ? const Color(0xFF182235) : const Color(0xFFFFFFFF);

  Color get _diagnosticTextColor =>
      isDarkMode ? const Color(0xFFEAF0FF) : const Color(0xFF172033);

  Color get _diagnosticMutedTextColor =>
      isDarkMode ? const Color(0xFFAAB5CC) : const Color(0xFF5C667A);

  Color get _diagnosticBorderColor =>
      isDarkMode ? const Color(0xFF293449) : const Color(0xFFE1E7F0);

  Color get _diagnosticSuccessColor =>
      isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669);

  Color get _diagnosticWarningColor =>
      isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

  Color get _diagnosticErrorColor =>
      isDarkMode ? const Color(0xFFFB7185) : const Color(0xFFE11D48);

  ThemeData _diagnosticTheme() {
    final ThemeData base = Theme.of(context);
    final Color textColor = _diagnosticTextColor;
    final Color cardColor = _diagnosticCardColor;
    return base.copyWith(
      scaffoldBackgroundColor: _diagnosticBgColor,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _diagnosticSurfaceColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textColor,
        unselectedLabelColor: _diagnosticMutedTextColor,
        indicatorColor: Colors.orangeAccent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      iconTheme: IconThemeData(color: textColor),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDarkMode ? const Color(0xFF24324A) : const Color(0xFFEAF0FA),
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _diagnosticBorderColor),
          ),
        ),
      ),
      dividerColor: _diagnosticBorderColor,
    );
  }

  String _diagValue(String? value) {
    final String clean = (value ?? '').trim();
    return clean.isEmpty ? '-' : clean;
  }

  String _diagJoin(Iterable<String> values) {
    final List<String> clean = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return clean.isEmpty ? '-' : clean.join(', ');
  }

  String _formatDiagDateTime(DateTime? value) {
    if (value == null) return '-';
    return value.toLocal().toIso8601String().split('.').first;
  }

  Widget _buildDiagnosticActionGrid(List<Widget> actions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final int columns = constraints.maxWidth >= 760
              ? 4
              : (constraints.maxWidth >= 480 ? 2 : 1);
          final double width =
              (constraints.maxWidth - ((columns - 1) * 8)) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map((action) => SizedBox(width: width, child: action))
                .toList(growable: false),
          );
        },
      ),
    );
  }

  Widget _buildDiagnosticStatGrid(List<Widget> stats) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final int columns = constraints.maxWidth >= 860
            ? 4
            : (constraints.maxWidth >= 560 ? 2 : 1);
        final double width =
            (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats
              .map((stat) => SizedBox(width: width, child: stat))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildDiagnosticStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDarkMode ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(isDarkMode ? 0.34 : 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(isDarkMode ? 0.18 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _diagnosticMutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _diagnosticTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _diagnosticMutedTextColor,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticPill({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticKeyValue(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black12,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _diagnosticBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: TextStyle(
                color: _diagnosticMutedTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              _diagValue(value),
              style: TextStyle(
                color: _diagnosticTextColor,
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticOverview(String langCode) {
    return ValueListenableBuilder<PurchaseDebugSnapshot>(
      valueListenable: PurchasesService.instance.debugSnapshot,
      builder: (_, snapshot, __) {
        final String projectId = _firebaseProjectId();
        final User? currentUser = FirebaseAuth.instance.currentUser;
        final bool revenueCatReady = PurchasesService.instance.isConfigured;
        final bool hasPurchaseError =
            PurchasesService.instance.lastPurchaseError.value.trim().isNotEmpty;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _diagnosticSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _diagnosticBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.orangeAccent.shade200, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizeTrEn(
                            langCode,
                            'grkmcomert Debug Paneli',
                            'grkmcomert Debug Panel',
                          ),
                          style: TextStyle(
                            color: _diagnosticTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localizeTrEn(
                            langCode,
                            'Canli durum, test aksiyonlari ve okunur loglar.',
                            'Live status, test actions, and readable logs.',
                          ),
                          style: TextStyle(
                            color: _diagnosticMutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDiagnosticPill(
                    label: _canViewAdminPanel() ? 'OWNER' : 'LOCAL DEBUG',
                    color: _canViewAdminPanel()
                        ? _diagnosticSuccessColor
                        : _diagnosticWarningColor,
                    icon: _canViewAdminPanel()
                        ? Icons.lock_open_rounded
                        : Icons.bug_report_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDiagnosticStatGrid([
                _buildDiagnosticStatCard(
                  icon: Icons.person_rounded,
                  label: 'Instagram',
                  value: isLoggedIn ? 'Logged in' : 'Guest',
                  subtitle: currentUsername.trim().isEmpty
                      ? '-'
                      : '@${currentUsername.trim()}',
                  accent: isLoggedIn
                      ? _diagnosticSuccessColor
                      : _diagnosticWarningColor,
                ),
                _buildDiagnosticStatCard(
                  icon: Icons.cloud_done_rounded,
                  label: 'Firebase',
                  value: projectId.isEmpty ? 'Missing' : 'Ready',
                  subtitle: currentUser?.uid ?? '-',
                  accent: projectId.isEmpty
                      ? _diagnosticErrorColor
                      : _diagnosticSuccessColor,
                ),
                _buildDiagnosticStatCard(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Premium',
                  value: _isPremium ? 'Active' : 'Inactive',
                  subtitle: 'local=${snapshot.premium}',
                  accent: _isPremium
                      ? _diagnosticSuccessColor
                      : _diagnosticWarningColor,
                ),
                _buildDiagnosticStatCard(
                  icon: Icons.storefront_rounded,
                  label: 'RevenueCat',
                  value: revenueCatReady ? 'Configured' : 'Not ready',
                  subtitle: hasPurchaseError ? 'has error' : snapshot.source,
                  accent: hasPurchaseError
                      ? _diagnosticErrorColor
                      : (revenueCatReady
                          ? _diagnosticSuccessColor
                          : _diagnosticWarningColor),
                ),
              ]),
              const SizedBox(height: 12),
              ValueListenableBuilder<List<String>>(
                valueListenable: _igDiagnosticEvents,
                builder: (_, logs, __) {
                  final String lastFailure = logs.cast<String?>().firstWhere(
                        (line) => line != null &&
                            line.toLowerCase().contains('[error]') &&
                            line.toLowerCase().contains('analysis_failure'),
                        orElse: () => null,
                      ) ?? '';
                  if (lastFailure.trim().isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _diagnosticErrorColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _diagnosticErrorColor.withOpacity(0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: _diagnosticErrorColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'LAST ANALYSIS FAILURE\n$lastFailure',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _diagnosticTextColor,
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy failure',
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: lastFailure),
                          ),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildPurchaseDebugDump(PurchaseDebugSnapshot snapshot) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('source=${snapshot.source}')
      ..writeln('updated_at=${_formatDiagDateTime(snapshot.updatedAt)}')
      ..writeln('configured=${snapshot.configured}')
      ..writeln('premium=${snapshot.premium}')
      ..writeln(
          'original_app_user_id=${_diagValue(snapshot.originalAppUserId)}')
      ..writeln('request_date=${_diagValue(snapshot.requestDate)}')
      ..writeln('first_seen=${_diagValue(snapshot.firstSeen)}')
      ..writeln(
          'active_subscriptions=${_diagJoin(snapshot.activeSubscriptions)}')
      ..writeln(
          'all_products=${_diagJoin(snapshot.allPurchasedProductIdentifiers)}')
      ..writeln(
          'latest_expiration=${_diagValue(snapshot.latestExpirationDate)}')
      ..writeln('management_url=${_diagValue(snapshot.managementURL)}');
    if ((snapshot.lastTransactionIdentifier ?? '').trim().isNotEmpty) {
      buffer
        ..writeln('last_transaction_id=${snapshot.lastTransactionIdentifier}')
        ..writeln(
            'last_transaction_product=${snapshot.lastTransactionProductIdentifier}')
        ..writeln(
            'last_transaction_purchase_date=${snapshot.lastTransactionPurchaseDate}');
    }
    if (snapshot.lastError.trim().isNotEmpty) {
      buffer.writeln('last_error=${snapshot.lastError.trim()}');
    }
    return buffer.toString().trimRight();
  }

  Widget _buildPurchaseEntitlementCard(PurchaseDebugEntitlement item) {
    final Color accent =
        item.isActive ? _diagnosticSuccessColor : _diagnosticWarningColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDarkMode ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.isActive
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 17,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.identifier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _diagnosticTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildDiagnosticPill(
                label: item.isActive ? 'ACTIVE' : 'INACTIVE',
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDiagnosticKeyValue('product', item.productIdentifier),
          const SizedBox(height: 6),
          _buildDiagnosticKeyValue('latest', item.latestPurchaseDate),
          const SizedBox(height: 6),
          _buildDiagnosticKeyValue('expires', item.expirationDate ?? '-'),
          const SizedBox(height: 6),
          _buildDiagnosticKeyValue(
            'flags',
            'renew=${item.willRenew} sandbox=${item.isSandbox} store=${item.store} period=${item.periodType}',
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRevenueCatDebugInfo(String langCode) async {
    await PurchasesService.instance.configure(
      androidApiKey: _revenueCatAndroidApiKey,
      iosApiKey: _revenueCatIosApiKey,
    );
    final PurchaseDebugSnapshot? snapshot =
        await PurchasesService.instance.refreshCustomerInfoForDebug();
    if (!mounted) return;
    _showDiagSnackBar(
      snapshot == null
          ? localizeTrEn(
              langCode,
              'RevenueCat bilgisi alinamadi.',
              'Could not refresh RevenueCat info.',
            )
          : localizeTrEn(
              langCode,
              'RevenueCat bilgisi yenilendi.',
              'RevenueCat info refreshed.',
            ),
      backgroundColor: snapshot == null ? Colors.red : Colors.green,
    );
  }

  Widget _buildStoreDebugPanel(String langCode) {
    return ValueListenableBuilder<PurchaseDebugSnapshot>(
      valueListenable: PurchasesService.instance.debugSnapshot,
      builder: (_, snapshot, __) {
        final bool hasError = snapshot.lastError.trim().isNotEmpty;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _diagnosticSurfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _diagnosticBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 19, color: _diagnosticMutedTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizeTrEn(
                        langCode,
                        'RevenueCat Canli Bilgi',
                        'RevenueCat Live Info',
                      ),
                      style: TextStyle(
                        color: _diagnosticTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _buildDiagnosticPill(
                    label: snapshot.hasCustomerInfo ? 'CUSTOMER' : 'EMPTY',
                    color: snapshot.hasCustomerInfo
                        ? _diagnosticSuccessColor
                        : _diagnosticWarningColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDiagnosticStatGrid([
                _buildDiagnosticStatCard(
                  icon: Icons.sync_rounded,
                  label: 'Snapshot',
                  value: snapshot.source,
                  subtitle: _formatDiagDateTime(snapshot.updatedAt),
                  accent: _diagnosticSuccessColor,
                ),
                _buildDiagnosticStatCard(
                  icon: Icons.subscriptions_rounded,
                  label: 'Active Subs',
                  value: '${snapshot.activeSubscriptions.length}',
                  subtitle: _diagJoin(snapshot.activeSubscriptions),
                  accent: snapshot.activeSubscriptions.isEmpty
                      ? _diagnosticWarningColor
                      : _diagnosticSuccessColor,
                ),
                _buildDiagnosticStatCard(
                  icon: Icons.verified_rounded,
                  label: 'Entitlements',
                  value: '${snapshot.activeEntitlements.length}',
                  subtitle: snapshot.activeEntitlements
                      .map((item) => item.identifier)
                      .join(', '),
                  accent: snapshot.activeEntitlements.isEmpty
                      ? _diagnosticWarningColor
                      : _diagnosticSuccessColor,
                ),
                _buildDiagnosticStatCard(
                  icon: hasError
                      ? Icons.error_outline_rounded
                      : Icons.notifications_active_rounded,
                  label: 'Last Error',
                  value: hasError ? 'Exists' : 'Clean',
                  subtitle: hasError ? snapshot.lastError : 'ready',
                  accent: hasError
                      ? _diagnosticErrorColor
                      : _diagnosticSuccessColor,
                ),
              ]),
              const SizedBox(height: 10),
              if (!snapshot.hasCustomerInfo)
                Text(
                  localizeTrEn(
                    langCode,
                    'Refresh RC veya Purchase/Restore Test ile musteri bilgisi yuklenir.',
                    'Use Refresh RC or Purchase/Restore Test to load customer info.',
                  ),
                  style: TextStyle(
                    color: _diagnosticMutedTextColor,
                    fontSize: 12,
                  ),
                )
              else ...[
                _buildDiagnosticKeyValue(
                  'customer',
                  snapshot.originalAppUserId,
                ),
                const SizedBox(height: 6),
                _buildDiagnosticKeyValue(
                  'products',
                  _diagJoin(snapshot.allPurchasedProductIdentifiers),
                ),
                const SizedBox(height: 6),
                _buildDiagnosticKeyValue(
                  'latest expiration',
                  snapshot.latestExpirationDate ?? '-',
                ),
                const SizedBox(height: 6),
                _buildDiagnosticKeyValue(
                  'management',
                  snapshot.managementURL ?? '-',
                ),
                if ((snapshot.lastTransactionProductIdentifier ?? '')
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildDiagnosticKeyValue(
                    'last transaction',
                    '${snapshot.lastTransactionProductIdentifier} / ${snapshot.lastTransactionIdentifier ?? '-'} / ${snapshot.lastTransactionPurchaseDate ?? '-'}',
                  ),
                ],
                if (snapshot.activeEntitlements.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...snapshot.activeEntitlements.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildPurchaseEntitlementCard(item),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.18)
                      : const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _diagnosticBorderColor),
                ),
                child: SelectableText(
                  _buildPurchaseDebugDump(snapshot),
                  style: TextStyle(
                    color: _diagnosticTextColor,
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticLogList({
    required List<String> logs,
    required String emptyText,
  }) {
    if (logs.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
            color: _diagnosticMutedTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final String log = logs[index];
        final String lower = log.toLowerCase();
        final bool isError = lower.contains('[error]') ||
            lower.contains('failed') ||
            lower.contains('permission-denied');
        final bool isWarn = lower.contains('warning') ||
            lower.contains('blocked') ||
            lower.contains('timeout');
        final Color accent = isError
            ? Colors.redAccent
            : (isWarn ? Colors.amber : Colors.lightBlueAccent);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _diagnosticCardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: accent, width: 3),
              top: BorderSide(color: _diagnosticBorderColor),
              right: BorderSide(color: _diagnosticBorderColor),
              bottom: BorderSide(color: _diagnosticBorderColor),
            ),
          ),
          child: SelectableText(
            log,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.35,
              color: _diagnosticTextColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentFirebaseAnalysisPanel(String langCode) {
    if (!_canViewOwnerFirebaseUserList()) return const SizedBox.shrink();
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: _recentFirebaseAnalysisRows,
      builder: (_, rows, __) {
        final bool hasRows = rows.isNotEmpty;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _diagnosticSurfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _diagnosticBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 18, color: _diagnosticMutedTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizeTrEn(
                          langCode, 'Son Analizler', 'Recent Analyses'),
                      style: TextStyle(
                        color: _diagnosticTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'key: last_analysis_at',
                    style: TextStyle(
                      color: _diagnosticMutedTextColor,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!hasRows)
                Text(
                  localizeTrEn(
                    langCode,
                    'Listeyi yuklemek icin Son Analizler butonuna bas.',
                    'Tap Recent Analyses to load the list.',
                  ),
                  style: TextStyle(
                    color: _diagnosticMutedTextColor,
                    fontSize: 12,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 230),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final Map<String, String> row = rows[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _diagnosticCardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _diagnosticBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: TextStyle(
                                    color: _diagnosticMutedTextColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '@${row['username'] ?? '-'}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _diagnosticTextColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  row['last_analysis_at'] ?? '-',
                                  style: TextStyle(
                                    color: Colors.greenAccent.shade400,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'analiz=${row['analysis_count'] ?? '0'}  premium=${row['premium'] ?? '-'}  app=${row['app'] ?? '-'}  device=${row['device'] ?? '-'}  country=${row['country'] ?? '-'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _diagnosticMutedTextColor,
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDiagnosticsConsole({int initialTabIndex = 0}) async {
    if (!mounted) return;
    if (!_canOpenDiagnosticsConsole()) return;
    final String langCode = _lang;
    final bool canRunWriteTest =
        kDebugMode || _isAdminUser || _forceFirestoreTest;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: _diagnosticBgColor,
        child: Theme(
          data: _diagnosticTheme(),
          child: DefaultTabController(
            length: 3,
            initialIndex: initialTabIndex.clamp(0, 2),
            child: Scaffold(
              backgroundColor: _diagnosticBgColor,
              appBar: AppBar(
                title: Text(
                  localizeTrEn(
                    langCode,
                    'TeÃ…Å¸his LoglarÃ„Â±',
                    'Diagnostic Logs',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                bottom: TabBar(
                  tabs: [
                    Tab(text: localizeTrEn(langCode, 'Instagram', 'Instagram')),
                    Tab(text: localizeTrEn(langCode, 'Firebase', 'Firebase')),
                    Tab(text: localizeTrEn(langCode, 'Store', 'Store')),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: localizeTrEn(
                        langCode, 'TÃƒÂ¼mÃƒÂ¼nÃƒÂ¼ kopyala', 'Copy all'),
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
                  _buildDiagnosticOverview(langCode),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Column(
                          children: [
                            _buildDiagnosticActionGrid([
                              ElevatedButton.icon(
                                onPressed: () {
                                  _igDiagnosticEvents.value = <String>[];
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: Text(
                                  localizeTrEn(
                                    langCode,
                                    'IG loglarini temizle',
                                    'Clear IG logs',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: _buildCombinedDiagnosticDump(),
                                  ));
                                },
                                icon: const Icon(Icons.copy_all_rounded),
                                label: Text(
                                  localizeTrEn(
                                    langCode,
                                    'Tum loglari kopyala',
                                    'Copy all logs',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ValueListenableBuilder<List<String>>(
                                valueListenable: _igDiagnosticEvents,
                                builder: (_, logs, __) {
                                  if (logs.isEmpty) {
                                    return Center(
                                      child: Text(
                                        localizeTrEn(
                                          langCode,
                                          'HenÃƒÂ¼z IG logu yok.',
                                          'No IG logs yet.',
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
                                          color: _diagnosticCardColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: _diagnosticBorderColor),
                                        ),
                                        child: SelectableText(
                                          logs[index],
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: _diagnosticTextColor,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _runFirebaseAuthDiagnosticProbe,
                                      icon: const Icon(
                                          Icons.verified_user_outlined),
                                      label: Text(
                                        localizeTrEn(langCode, 'Auth Probe',
                                            'Auth Probe'),
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
                                      icon: const Icon(
                                          Icons.cloud_upload_outlined),
                                      label: Text(
                                        localizeTrEn(langCode, 'Write Test',
                                            'Write Test'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: localizeTrEn(
                                      langCode,
                                      'Firebase loglarini temizle',
                                      'Clear Firebase logs',
                                    ),
                                    onPressed: () {
                                      _firebaseDiagnosticEvents.value =
                                          <String>[];
                                      _recentFirebaseAnalysisRows.value =
                                          <Map<String, String>>[];
                                    },
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                              child: Row(
                                children: [
                                  if (_canViewOwnerFirebaseUserList()) ...[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _loadRecentFirebaseAnalyses,
                                        icon: const Icon(Icons.history_rounded),
                                        label: Text(
                                          localizeTrEn(
                                              langCode,
                                              'Son Analizler',
                                              'Recent Analyses'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _runFirestoreRestDiagnosticProbe,
                                      icon: const Icon(Icons.http_rounded),
                                      label: Text(
                                        localizeTrEn(langCode, 'REST Probe',
                                            'REST Probe'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildRecentFirebaseAnalysisPanel(langCode),
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
                                          color: _diagnosticCardColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: _diagnosticBorderColor),
                                        ),
                                        child: SelectableText(
                                          logs[index],
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: _diagnosticTextColor,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
                                      onPressed: () => unawaited(
                                        _refreshRevenueCatDebugInfo(langCode),
                                      ),
                                      icon: const Icon(Icons.sync_rounded),
                                      label: const Text(
                                        'Refresh RC',
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
                                        await PurchasesService.instance
                                            .configure(
                                          androidApiKey:
                                              _revenueCatAndroidApiKey,
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
                                              'SatÃ„Â±n alÃ„Â±m iptal edildi.',
                                              'Purchase cancelled.',
                                            ),
                                            backgroundColor:
                                                Colors.blueGrey.shade900,
                                          );
                                        } else if (result.success) {
                                          _showDiagSnackBar(
                                            localizeTrEn(
                                              langCode,
                                              'SatÃ„Â±n alÃ„Â±m baÃ…Å¸arÃ„Â±lÃ„Â±.',
                                              'Purchase successful.',
                                            ),
                                            backgroundColor: Colors.green,
                                          );
                                        } else {
                                          _showDiagSnackBar(
                                            localizeTrEn(
                                              langCode,
                                              'SatÃ„Â±n alÃ„Â±m baÃ…Å¸arÃ„Â±sÃ„Â±z.',
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
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 360),
                              child: SingleChildScrollView(
                                child: _buildStoreDebugPanel(langCode),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ValueListenableBuilder<List<String>>(
                                valueListenable:
                                    PurchasesService.instance.diagnosticEvents,
                                builder: (_, logs, __) =>
                                    _buildDiagnosticLogList(
                                  logs: logs,
                                  emptyText: localizeTrEn(
                                    langCode,
                                    'Store logu henuz yok.',
                                    'No store logs yet.',
                                  ),
                                ),
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
        localizeTrEn(
            _lang,
            'Firebase Auth hatasÃ„Â±: kullanÃ„Â±cÃ„Â± doÃ„Å¸rulanamadÃ„Â±.',
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
        localizeTrEn(_lang, 'Firestore test yazma baÃ…Å¸arÃ„Â±lÃ„Â±.',
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
        localizeTrEn(_lang, 'Firestore test hatasÃ„Â± oluÃ…Å¸tu.',
            'Firestore test failed.'),
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
        localizeTrEn(
            _lang,
            'Firestore auth hatasÃ„Â±: kullanÃ„Â±cÃ„Â± doÃ„Å¸rulanamadÃ„Â±.',
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
        localizeTrEn(_lang, 'Firestore sayaÃƒÂ§ yazma hatasÃ„Â±.',
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
        localizeTrEn(_lang, 'Firestore auth yok: ig_users yazÃ„Â±lamadÃ„Â±.',
            'Firestore auth missing: ig_users write blocked.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    String version = '38.0.0';
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
        localizeTrEn(_lang, 'Firestore ig_users yazma hatasÃ„Â±.',
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
      await _logout(wipeLocalData: true);
    } finally {
      if (mounted) setState(() => _isClearingData = false);
    }
  }

  Future<void> _logoutDirectly() async {
    if (_isClearingData) return;
    if (mounted) setState(() => _isClearingData = true);
    try {
      await _logout(clearSession: true);
    } finally {
      if (mounted) setState(() => _isClearingData = false);
    }
  }

  Future<void> _clearStoredSessionOnly(SharedPreferences prefs) async {
    const List<String> sessionKeys = <String>[
      'session_username',
      'session_user_agent',
      'session_cookie',
      'session_user_id',
      'ig_www_claim',
      'target_user_id',
      'cached_follower_count',
      'cached_following_count',
    ];

    final List<String> keysToRemove = prefs
        .getKeys()
        .where((key) =>
            sessionKeys.contains(key) ||
            sessionKeys.any((base) => key.startsWith('${base}_')))
        .toList(growable: false);

    for (final String key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  String _cleanSessionUserId(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty || clean == 'null') return '';
    return clean;
  }

  String _userIdFromCookie(String? cookie) {
    final String cleanCookie = (cookie ?? '').trim();
    if (cleanCookie.isEmpty) return '';
    final String fromCookie =
        _extractCookieValue(cleanCookie, 'ds_user_id').trim();
    final String cleanFromCookie = _cleanSessionUserId(fromCookie);
    if (cleanFromCookie.isNotEmpty) return cleanFromCookie;

    final String sessionId =
        _extractCookieValue(cleanCookie, 'sessionid').trim();
    return _cleanSessionUserId(_extractIgUserIdFromSessionId(sessionId));
  }

  String _storedSessionUserId(SharedPreferences prefs) {
    final String fromMemory = _cleanSessionUserId(savedUserId);
    if (fromMemory.isNotEmpty) return fromMemory;

    final String fromMemoryCookie = _userIdFromCookie(savedCookie);
    if (fromMemoryCookie.isNotEmpty) return fromMemoryCookie;

    final String fromAlias = _cleanSessionUserId(
      prefs.getString('session_user_id'),
    );
    if (fromAlias.isNotEmpty) return fromAlias;

    final String fromAliasCookie = _userIdFromCookie(
      prefs.getString('session_cookie'),
    );
    if (fromAliasCookie.isNotEmpty) return fromAliasCookie;

    final List<String> userIdKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('session_user_id_'))
        .toList()
      ..sort();
    for (final String key in userIdKeys) {
      final String fromValue = _cleanSessionUserId(prefs.getString(key));
      if (fromValue.isNotEmpty) return fromValue;

      final String suffix =
          _cleanSessionUserId(key.substring('session_user_id_'.length));
      if (suffix.isNotEmpty) return suffix;
    }

    final List<String> cookieKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('session_cookie_'))
        .toList()
      ..sort();
    for (final String key in cookieKeys) {
      final String fromCookie = _userIdFromCookie(prefs.getString(key));
      if (fromCookie.isNotEmpty) return fromCookie;

      final String suffix =
          _cleanSessionUserId(key.substring('session_cookie_'.length));
      if (suffix.isNotEmpty) return suffix;
    }

    return '';
  }

  Future<void> _persistActiveSessionPrefs(
    SharedPreferences prefs, {
    required String cookie,
    required String userId,
    String? username,
    String? userAgent,
  }) async {
    final String cleanUserId = _cleanSessionUserId(userId);
    if (cleanUserId.isEmpty) return;

    final String cleanCookie = cookie.trim();
    if (cleanCookie.isNotEmpty) {
      await prefs.setString('session_cookie', cleanCookie);
      await _setAccountPrefString(
        prefs,
        'session_cookie',
        cleanCookie,
        userId: cleanUserId,
      );
    }

    await prefs.setString('session_user_id', cleanUserId);
    await _setAccountPrefString(
      prefs,
      'session_user_id',
      cleanUserId,
      userId: cleanUserId,
    );

    final String cleanUsername = (username ?? '').trim();
    if (cleanUsername.isNotEmpty) {
      await prefs.setString('session_username', cleanUsername);
      await _setAccountPrefString(
        prefs,
        'session_username',
        cleanUsername,
        userId: cleanUserId,
      );
    }

    final String cleanUserAgent = (userAgent ?? '').trim();
    if (cleanUserAgent.isNotEmpty) {
      await prefs.setString('session_user_agent', cleanUserAgent);
      await _setAccountPrefString(
        prefs,
        'session_user_agent',
        cleanUserAgent,
        userId: cleanUserId,
      );
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
      {bool updateUserId = true, bool allowWhenLoggedOut = false}) async {
    if (!allowWhenLoggedOut && !isLoggedIn) return false;

    final String? cookie = await _readCookieFromWebViewStore();
    if (cookie == null) return false;

    final String previous = (savedCookie ?? '').trim();
    String? updatedUserId = savedUserId;
    if (updateUserId) {
      final String fromCookie =
          _extractCookieValue(cookie, 'ds_user_id').trim();
      if (fromCookie.isNotEmpty) {
        updatedUserId = fromCookie;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (_cleanSessionUserId(updatedUserId).isNotEmpty) {
      await _persistActiveSessionPrefs(
        prefs,
        cookie: cookie,
        userId: updatedUserId!,
        userAgent: savedUserAgent,
      );
    }
    if (previous.isNotEmpty && previous == cookie) return false;

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

  Future<bool> _recoverSessionState(SharedPreferences prefs) async {
    String cookie = (savedCookie ?? '').trim();
    String userId = _cleanSessionUserId(savedUserId);

    if (cookie.isNotEmpty) {
      final String fromCookie =
          _extractCookieValue(cookie, 'ds_user_id').trim();
      if (userId.isEmpty && fromCookie.isNotEmpty) userId = fromCookie;
    }

    final bool validInMemory = cookie.isNotEmpty &&
        _extractCookieValue(cookie, 'sessionid').trim().isNotEmpty &&
        userId.isNotEmpty &&
        userId != 'null';
    if (validInMemory) return true;

    await _refreshSessionCookieFromWebViewStore(
      updateUserId: true,
      allowWhenLoggedOut: true,
    );

    cookie = (savedCookie ?? '').trim();
    userId = _cleanSessionUserId(savedUserId);
    if (cookie.isNotEmpty) {
      final String fromCookie =
          _extractCookieValue(cookie, 'ds_user_id').trim();
      if (userId.isEmpty && fromCookie.isNotEmpty) userId = fromCookie;
    }

    if (userId.isEmpty) {
      userId = _storedSessionUserId(prefs);
    }
    if (cookie.isEmpty && userId.isNotEmpty) {
      cookie = (_accountPrefString(prefs, 'session_cookie', userId: userId) ??
              prefs.getString('session_cookie') ??
              '')
          .trim();
    }

    if (cookie.isEmpty || userId.isEmpty || userId == 'null') {
      final String prefCookie =
          (_accountPrefString(prefs, 'session_cookie', userId: userId) ?? '')
              .trim();
      String prefUserId =
          (_accountPrefString(prefs, 'session_user_id', userId: userId) ?? '')
              .trim();
      if (prefUserId.isEmpty && prefCookie.isNotEmpty) {
        prefUserId = _extractCookieValue(prefCookie, 'ds_user_id').trim();
      }
      final String prefSessionId =
          _extractCookieValue(prefCookie, 'sessionid').trim();
      if (prefCookie.isNotEmpty &&
          prefSessionId.isNotEmpty &&
          prefUserId.isNotEmpty &&
          prefUserId != 'null') {
        cookie = prefCookie;
        userId = prefUserId;
      }
    }

    final bool validRecovered = cookie.isNotEmpty &&
        _extractCookieValue(cookie, 'sessionid').trim().isNotEmpty &&
        userId.isNotEmpty &&
        userId != 'null';
    if (!validRecovered) return false;

    await _persistActiveSessionPrefs(
      prefs,
      cookie: cookie,
      userId: userId,
      userAgent: savedUserAgent,
    );

    if (mounted) {
      setState(() {
        savedCookie = cookie;
        savedUserId = userId;
      });
    } else {
      savedCookie = cookie;
      savedUserId = userId;
    }
    return true;
  }

  String _startupSessionEndedMessage() {
    return localizeTrEn(
      _lang,
      'Oturumunuz sonlandÃ„Â±, lÃƒÂ¼tfen tekrar giriÃ…Å¸ yapÃ„Â±nÃ„Â±z.',
      'Session is invalid. Please log in again.',
    );
  }

  void _showStartupSessionEndedWarning() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_startupSessionEndedMessage()),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ));
    });
  }

  bool _hasUsableStoredCookie(String cookie, String userId) {
    final String sessionId = _extractCookieValue(cookie, 'sessionid').trim();
    final String cleanUserId = _cleanSessionUserId(userId);
    return sessionId.isNotEmpty &&
        cleanUserId.isNotEmpty &&
        cleanUserId != 'null';
  }

  Future<bool?> _probeStartupSessionActive({
    required String cookie,
    required String userId,
    required String userAgent,
  }) async {
    final String sessionId = _extractCookieValue(cookie, 'sessionid').trim();
    if (sessionId.isEmpty) return false;

    String dsUserId = _extractCookieValue(cookie, 'ds_user_id').trim();
    if (dsUserId.isEmpty) dsUserId = userId.trim();
    if (dsUserId.isEmpty || dsUserId == 'null') return false;

    try {
      final response = await http
          .get(
            Uri.parse(
                'https://www.instagram.com/api/v1/accounts/current_user/?edit=true'),
            headers: _buildWebHeaders(cookie, userAgent,
                dsUserId: dsUserId, igWwwClaim: _igWwwClaimToken),
          )
          .timeout(const Duration(seconds: 4));

      final int status = response.statusCode;
      final String body = _safeResponseBody(response).toLowerCase();
      if (status == 200 && body.contains('"status":"ok"')) return true;
      if (status == 401 || status == 403) return false;
      if (body.contains('login_required') ||
          body.contains('session_invalid') ||
          body.contains('checkpoint_required') ||
          body.contains('consent_required')) {
        return false;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final String storedClaim = (prefs.getString('ig_www_claim') ?? '').trim();
    if ((_igWwwClaimToken ?? '').trim().isEmpty && storedClaim.isNotEmpty) {
      _igWwwClaimToken = storedClaim;
    }
    await _refreshSessionCookieFromWebViewStore(
      updateUserId: true,
      allowWhenLoggedOut: true,
    );
    final String currentUserId = _storedSessionUserId(prefs);
    String? cookie = _accountPrefString(
      prefs,
      'session_cookie',
      userId: currentUserId,
    );
    if ((cookie ?? '').trim().isEmpty) {
      cookie = prefs.getString('session_cookie');
    }
    String? userId = _accountPrefString(
      prefs,
      'session_user_id',
      userId: currentUserId,
    );
    if (_cleanSessionUserId(userId).isEmpty) {
      userId = currentUserId.isNotEmpty
          ? currentUserId
          : prefs.getString('session_user_id');
    }
    String? username = _accountPrefString(
      prefs,
      'session_username',
      userId: currentUserId,
    );
    if ((username ?? '').trim().isEmpty) {
      username = prefs.getString('session_username');
    }
    String? ua = _accountPrefString(
      prefs,
      'session_user_agent',
      userId: currentUserId,
    );
    if ((ua ?? '').trim().isEmpty) {
      ua = prefs.getString('session_user_agent');
    }
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
      final String restoredUa =
          (ua ?? '').trim().isNotEmpty ? ua!.trim() : _resolveAppUserAgent('');
      _sessionAppUserAgent =
          restoredUa.toLowerCase().contains('instagram') ? restoredUa : null;
      final String refreshedCookie = (savedCookie ?? '').trim();
      final String refreshedUserId = (savedUserId ?? '').trim();
      if (refreshedCookie.isNotEmpty) cookie = refreshedCookie;
      if (refreshedUserId.isNotEmpty && refreshedUserId != 'null') {
        userId = refreshedUserId;
      }
      final bool? active = await _probeStartupSessionActive(
        cookie: cookie,
        userId: userId,
        userAgent: restoredUa,
      );
      if (active == false) {
        final bool hasUsableCookie = _hasUsableStoredCookie(cookie, userId);
        if (!hasUsableCookie) {
          _logFirebaseDiagnostic(
            'session',
            'startup check indicates session needs verification; keeping stored session',
          );
          _showStartupSessionEndedWarning();
          _scheduleIgVerificationGuide('session_invalid');
          return;
        }
        // The current_user probe was rejected (401/403, or a body
        // matching login/challenge/consent text), but we still hold what
        // looks like a genuinely valid sessionid + user id pair. Under
        // heavy recent request volume Instagram can return a blanket
        // 401/403 across an account for a while even though the
        // underlying session cookie is still valid, so treating this one
        // probe as absolute truth was locking the owner out of a session
        // that actually still worked, with no way to recover short of a
        // fresh login (which hits this exact same endpoint). Proceed
        // optimistically here; a genuinely dead session will still
        // surface its own error on the first real analysis request, same
        // as it always has.
        _logFirebaseDiagnostic(
          'session',
          'startup check rejected the session but a usable cookie/user id pair is stored; proceeding optimistically instead of forcing re-login',
        );
      }

      final String fallback = localizeTrEn(_lang, 'KullanÃ„Â±cÃ„Â±', 'User');
      if (mounted) {
        setState(() {
          isLoggedIn = true;
          _hasAnalyzed = false;
          savedCookie = cookie;
          savedUserId = userId;
          currentUsername = username ?? fallback;
          savedUserAgent = restoredUa;
          _syncCountsForUi();
        });
      } else {
        isLoggedIn = true;
        _hasAnalyzed = false;
        savedCookie = cookie;
        savedUserId = userId;
        currentUsername = username ?? fallback;
        savedUserAgent = restoredUa;
      }
      _logFirebaseDiagnostic(
        'session',
        'auto-login restored userId=$userId username=$currentUsername',
      );
      unawaited(_persistOwnerUsernameIfNeeded(currentUsername));
      await _persistActiveSessionPrefs(
        prefs,
        cookie: cookie,
        userId: userId,
        username: currentUsername,
        userAgent: restoredUa,
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
      _queueQuickStoryTrayRefresh(force: true);
    }
  }

  Future<void> _logout({
    bool wipeLocalData = false,
    bool clearSession = false,
  }) async {
    final bool wasOwnerPushUser = _canViewAdminPanel();
    final String? ownerPushUid = FirebaseAuth.instance.currentUser?.uid;

    _cancelCountdown();
    _stopStoryAutoScroll();
    _analysisProgressTimelineTimer?.cancel();
    _analysisProgressTimelineTimer = null;
    _entryInterstitialPrefetchRetryTimer?.cancel();
    _entryInterstitialPrefetchRetryTimer = null;
    _entryInterstitialPrefetchTimeoutTimer?.cancel();
    _entryInterstitialPrefetchTimeoutTimer = null;
    _isEntryInterstitialPreloadInFlight = false;

    void clearState() {
      isLoggedIn = false;
      _isBanned = false;
      _hasAnalyzed = false;
      currentUsername = "";
      savedCookie = null;
      savedUserId = null;
      savedUserAgent = null;
      _sessionAppUserAgent = null;
      _remainingToNextAnalysis = null;
      _analysisStartedAt = null;
      _progressValue = 0.0;
      _progressTarget = 0.0;
      _progressFinishEndAt = null;
      _lastStoryTrayQuickRefreshAt = null;
      _isStoryTrayLoading = false;
      _storyTrayRefreshQueued = false;
      _storyRequiresSecurityVerification = false;
      followersMap = {};
      followingMap = {};
      nonFollowersMap = {};
      unfollowersMap = {};
      leftFollowingMap = {};
      newFollowersMap = {};
      _storyUsersWithActive = {};
      _storyUserPks = {};
      _storyUserPics = {};
      _storyActiveOrderIndex = {};
      _hdProfilePhotoCache.clear();
      _syncCountsForUi();
    }

    if (mounted) {
      setState(() => clearState());
    } else {
      clearState();
    }

    try {
      await TelemetryService.instance
          .recordLogout()
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    if (clearSession || wipeLocalData) {
      try {
        await _clearInstagramWebSessionStorage();
      } catch (_) {}
    }

    if (wasOwnerPushUser) {
      unawaited(_unregisterOwnerPurchaseNotificationToken(uid: ownerPushUid));
    }

    if (wipeLocalData) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}

      try {
        _igDiagnosticEvents.value = <String>[];
        _firebaseDiagnosticEvents.value = <String>[];
        _recentFirebaseAnalysisRows.value = <Map<String, String>>[];
        PurchasesService.instance.clearLastPurchaseError();
        PurchasesService.instance.clearDiagnosticEvents();
      } catch (_) {}
    } else if (clearSession) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await _clearStoredSessionOnly(prefs);
      } catch (_) {}
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
    await _waitForAdConsentFlow();
    if (!mounted) return;
    await ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint("${formError.errorCode}: ${formError.message}");
      }
    });
    if (!mounted) return;
    _entryInterstitialAd?.dispose();
    _entryInterstitialAd = null;
    await _reloadBannerForConsentChange();
    await _updatePrivacyOptionsRequirement();
  }

  Future<void> _reloadBannerForConsentChange() async {
    _bannerRetryTimer?.cancel();
    _bannerRetryTimer = null;
    _headerBannerRetryTimer?.cancel();
    _headerBannerRetryTimer = null;
    _isBannerLoadInFlight = false;
    _isHeaderBannerLoadInFlight = false;
    try {
      if (_bannerAd != null) {
        _bannerAd!.dispose();
      }
    } catch (_) {}
    try {
      _headerBannerAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    _headerBannerAd = null;
    _isAdLoaded = false;
    _isHeaderBannerLoaded = false;
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
                  localizeTrEn(_lang, 'HesabÃ„Â±nÃ„Â±z engellendi',
                      'Your account is blocked'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  localizeTrEn(
                      _lang,
                      'Bu hesap iÃƒÂ§in eriÃ…Å¸im kÃ„Â±sÃ„Â±tlandÃ„Â±.',
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
                        if (_shouldShowHeaderBannerPanel) ...[
                          _buildHeaderBannerPanel(primaryColor),
                          const SizedBox(height: 16),
                        ],
                        LayoutBuilder(builder: (context, constraints) {
                          final bool compact = constraints.maxWidth < 420;
                          final bool veryCompact = constraints.maxWidth < 360;
                          final BoxConstraints headerButtonConstraints = compact
                              ? const BoxConstraints(
                                  minWidth: 34, minHeight: 34)
                              : const BoxConstraints(
                                  minWidth: 40, minHeight: 40);

                          Widget headerIconButton({
                            required IconData icon,
                            required Color color,
                            required VoidCallback? onPressed,
                          }) {
                            return IconButton(
                              icon: Icon(
                                icon,
                                color: color,
                                size: compact ? 19 : 22,
                              ),
                              onPressed: onPressed,
                              padding: EdgeInsets.zero,
                              constraints: headerButtonConstraints,
                              visualDensity: VisualDensity.compact,
                              splashRadius: compact ? 18 : 20,
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: PopupMenuButton<String>(
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
                                        final String flag =
                                            _languageFlagFor(code);
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: selected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (selected) ...[
                                                const SizedBox(width: 8),
                                                const Icon(Icons.check,
                                                    size: 16),
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
                                        padding: EdgeInsets.symmetric(
                                          horizontal: compact ? 4 : 8,
                                          vertical: compact ? 6 : 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _languageFlagFor(_lang),
                                              style: TextStyle(
                                                  fontSize: compact ? 16 : 18),
                                            ),
                                            if (!veryCompact) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                _compactLanguageName(_lang),
                                                style: TextStyle(
                                                  color: headerColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('VERDICT',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: compact ? 22 : 26,
                                                color: headerColor,
                                                letterSpacing:
                                                    compact ? 2.2 : 3.0)),
                                        Text(_t('tagline'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: compact ? 7 : 8,
                                                color: headerColor
                                                    .withOpacity(0.6))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_privacyOptionsRequired)
                                        headerIconButton(
                                          icon: Icons.privacy_tip_outlined,
                                          color: headerColor,
                                          onPressed: _showPrivacyOptionsForm,
                                        ),
                                      if (_canOpenDiagnosticsConsole())
                                        headerIconButton(
                                          icon: Icons.bug_report_outlined,
                                          color: Colors.orangeAccent,
                                          onPressed: () =>
                                              _openDiagnosticsConsole(
                                            initialTabIndex: 0,
                                          ),
                                        ),
                                      headerIconButton(
                                        icon: isDarkMode
                                            ? Icons.light_mode
                                            : Icons.dark_mode,
                                        color: headerColor,
                                        onPressed: _toggleDarkMode,
                                      ),
                                      headerIconButton(
                                        icon: Icons.delete_sweep_outlined,
                                        color: Colors.redAccent,
                                        onPressed:
                                            (isProcessing || _isClearingData)
                                                ? null
                                                : _clearCache,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 20),
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
                              height: 420,
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
                              if (isLoggedIn) ...[
                                const SizedBox(height: 10),
                                _buildLogoutButton(isDarkMode),
                              ],
                              if (_shouldShowNativeAdPanel) ...[
                                const SizedBox(height: 18),
                                _buildNativeAdPanel(primaryColor),
                              ],
                              const SizedBox(height: 10),
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

  Widget _buildGrid(Color cardColor, Color textColor) {
    return LayoutBuilder(builder: (context, constraints) {
      double cardWidth = (constraints.maxWidth - 16) / 2;
      cardWidth = cardWidth * 0.90;
      double cardHeight = cardWidth * 0.92;
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
                  subtitle: _t('remove_ads_and_limits_subtitle'),
                  iconWidget: SizedBox(
                    width: 40,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF833AB4).withOpacity(0.40),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFF833AB4),
                          size: 22,
                        ),
                      ),
                    ),
                  ))),
          SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _buildBigCard('legal_warning', "", Colors.blueGrey,
                  Icons.info_outline, cardColor, textColor,
                  showCount: false)),
        ],
      );
    });
  }

  Widget _buildBigCard(String titleKey, String count, Color color,
      IconData icon, Color cardBg, Color txtColor,
      {bool showCount = true,
      IconData? footerIcon,
      Widget? iconWidget,
      String? subtitle}) {
    final String title = titleKey == 'remove_ads_and_limits'
        ? _premiumCardTitle()
        : _t(titleKey, {'username': currentUsername});
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
                content: Text(localizeTrEn(_lang, 'Link aÃƒÂ§Ã„Â±lamadÃ„Â±.',
                    'Could not open the link.')),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ));
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(localizeTrEn(_lang, 'Link aÃƒÂ§Ã„Â±lamadÃ„Â±.',
                    'Could not open the link.')),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ));
            }
          }
        } else if (titleKey == 'remove_ads_and_limits') {
          _logFirebaseDiagnostic('purchase', 'premium card tapped');
          await _showPremiumCardPurchaseDialog();
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
                        adsDisabled:
                            _adsDisabled || _removeAllAds || _isAdminUser,
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
                      fontSize: titleKey == 'remove_ads_and_limits' ? 11 : 10,
                      fontWeight: titleKey == 'remove_ads_and_limits'
                          ? FontWeight.w900
                          : FontWeight.bold,
                      letterSpacing:
                          titleKey == 'remove_ads_and_limits' ? 0.2 : 0,
                      color: titleKey == 'remove_ads_and_limits'
                          ? txtColor.withOpacity(0.86)
                          : txtColor.withOpacity(0.6)),
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: txtColor.withOpacity(0.52),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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

  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isClearingData || isProcessing
            ? null
            : () => unawaited(_logoutDirectly()),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          _logoutButtonTextForLang(_lang),
          style:
              const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.4),
          backgroundColor: isDark
              ? Colors.redAccent.withOpacity(0.10)
              : Colors.redAccent.withOpacity(0.06),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
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

  double _requiredCoverageRatio(int expectedTotal) {
    final int total = max(0, expectedTotal);
    if (total >= 8000) return 0.56;
    if (total >= 3500) return 0.60;
    if (total >= 1500) return 0.66;
    return 0.72;
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
      final double k = ceiling < 0.70 ? 2800 : 3500;
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

  Future<void> _refreshData({
    bool startProcessingImmediately = false,
    bool skipStartPrompt = false,
  }) async {
    if (_isBanned) return;
    if (isProcessing) return;
    _logFirebaseDiagnostic(
      'analysis',
      'refreshData start: isLoggedIn=$isLoggedIn '
      'username=${_normalizeUserKey(currentUsername)} '
      'hasCookie=${(savedCookie ?? '').trim().isNotEmpty} '
      'hasUserId=${(savedUserId ?? '').trim().isNotEmpty} '
      'isAdmin=$_isAdminUser adsDisabled=$_adsDisabled '
      'hasAnalyzed=$_hasAnalyzed '
      'startProcessingImmediately=$startProcessingImmediately '
      'skipStartPrompt=$skipStartPrompt',
    );
    bool processingStarted = false;
    void startProcessingUi() {
      if (processingStarted) return;
      processingStarted = true;
      _lastAnalysisRequestAt = DateTime.now();
      _stopProgressPump();
      _stopAnalysisProgressTimeline();
      setState(() {
        isProcessing = true;
        _analysisStartedAt = DateTime.now();
        _progressValue = 0.05;
        _progressTarget = 0.05;
      });
      unawaited(_prefetchEntryInterstitialAd());
      // Keep the first phase conservative so users don't hit ~84% too early.
      _setAnalysisProgressCap(0.28);
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
    _fetchChunkStopRequested = false;
    _justWatchedReward = false;
    if (userId.isEmpty && cookie.isNotEmpty) {
      userId = _extractCookieValue(cookie, 'ds_user_id').trim();
      if (userId.isNotEmpty) {
        savedUserId = userId;
        await _setAccountPrefString(prefs, 'session_user_id', userId,
            userId: userId);
      }
    }
    if (cookie.isEmpty || userId.isEmpty || userId == 'null') {
      final bool recovered = await _recoverSessionState(prefs);
      if (recovered) {
        cookie = (savedCookie ?? '').trim();
        userId = (savedUserId ?? '').trim();
      }
    }
    if (cookie.isEmpty || userId.isEmpty || userId == 'null') {
      stopProcessingUi();
      if (mounted) {
        setState(() {
          _hasAnalyzed = false;
          _syncCountsForUi();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizeTrEn(
              _lang,
              'Oturum geÃƒÂ§ersiz. LÃƒÂ¼tfen tekrar giriÃ…Å¸ yapÃ„Â±n.',
              'Session verification is required. Please verify your account in the Instagram app and try again.')),
          backgroundColor: Colors.orange.shade700,
        ));
      }
      _scheduleIgVerificationGuide('session_invalid');
      return;
    }
    final String uaToUse = _resolveUserAgent();
    _storyTrayRefreshQueued = _watchStoriesEnabled;
    final Duration? analysisSafetyDelay = _remainingAnalysisSafetyDelay();
    if (analysisSafetyDelay != null) {
      stopProcessingUi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('remaining_time', {
            'time': _formatDuration(analysisSafetyDelay),
          })),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 4),
        ));
      }
      return;
    }

    bool initialLoginAdHandled = false;
    if (skipStartPrompt && !_adsDisabled) {
      final int? lastMs = prefs.getInt(
        _accountScopedKey('last_update_time', userId: userId),
      );
      final DateTime now = DateTime.now();
      final int analysisCount = _analysisWindowCount(prefs, now);
      if (lastMs != null && analysisCount >= 2) {
        final bool premiumAccepted =
            await _promptPremiumPurchaseIfNeeded(prefs, now);
        if (!premiumAccepted) return;
      } else {
        final adResult = await _showRewardedAdWithResult();
        if (adResult["status"] == false) {
          final String adError = (adResult["error"] ?? '').toString().trim();
          if (adError.isNotEmpty) _setGoogleAdWarning(adError);
          final bool userCaused = _isUserCausedAdFailure(adResult);
          if (userCaused) return;
        }
      }
      initialLoginAdHandled = true;
    }

    try {
      final DateTime now = await _getEstimatedNetworkTime();
      _refreshNetworkTimeOffset();
      final int? lastMs = prefs.getInt(
        _accountScopedKey('last_update_time', userId: userId),
      );
      if (lastMs != null) {
        final DateTime last = DateTime.fromMillisecondsSinceEpoch(lastMs);
        final Duration wait = _analysisCooldown - now.difference(last);
        _logFirebaseDiagnostic(
          'analysis',
          '30h cooldown check: wait=${wait.inMinutes}m '
          'adsDisabled=$_adsDisabled isAdmin=$_isAdminUser',
        );
        if (wait > Duration.zero) {
          final bool adsDisabled = _adsDisabled;
          final int analysisCount = _analysisWindowCount(prefs, now);
          if (skipStartPrompt) {
            // First-login flow starts directly, but still enforces ad gate when ads are enabled.
            if (!adsDisabled && !initialLoginAdHandled) {
              if (analysisCount >= 2) {
                final bool premiumAccepted =
                    await _promptPremiumPurchaseIfNeeded(prefs, now);
                if (!premiumAccepted) return;
              } else {
                final adResult = await _showRewardedAdWithResult();
                if (adResult["status"] == false) {
                  final String adError =
                      (adResult["error"] ?? '').toString().trim();
                  if (adError.isNotEmpty) _setGoogleAdWarning(adError);
                  final bool userCaused = _isUserCausedAdFailure(adResult);
                  if (userCaused) return;
                }
              }
            }
          } else {
            if (mounted) {
              if (!adsDisabled && analysisCount >= 2) {
                final bool premiumAccepted =
                    await _promptPremiumPurchaseIfNeeded(prefs, now);
                if (!premiumAccepted) {
                  stopProcessingUi();
                  return;
                }
              } else {
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
                  // When ads are disabled (premium / admin), skip the rewarded ad entirely.
                  if (!adsDisabled) {
                    final adResult = await _showRewardedAdWithResult();
                    if (adResult["status"] == false) {
                      final String adError =
                          (adResult["error"] ?? '').toString().trim();
                      if (adError.isNotEmpty) _setGoogleAdWarning(adError);
                      final bool userCaused = _isUserCausedAdFailure(adResult);
                      if (userCaused) return;
                    }
                  }
                } else {
                  stopProcessingUi();
                  return;
                }
              }
            } else {
              stopProcessingUi();
              return;
            }
          }
        }
      }
    } catch (_) {}

    if (!processingStarted && mounted) {
      startProcessingUi();
    }

    String analysisPhase = 'analysis';
    String analysisEndpoint = '';
    try {
     analysisPhase = 'user_info';

// user_info ayrı bir Instagram endpoint'idir. Bu endpoint 429 verdiğinde
// _retryIg() üzerinden tekrar denemek, 429'u global risk cooldown'una
// çevirip bütün analizi "ig_cooldown_active" ile kesebiliyordu.
//
// Bu yüzden user_info yalnızca bir kez deneniyor.
// 429 gelirse pagination'ı doğrudan çalıştırıyoruz.
// Toplamlar bilinmiyorsa 0 bırakmak önemli: mevcut map uzunluğunu
// "gerçek toplam" kabul edersek pagination erken bitebilir.
Map<String, dynamic> info;

try {
  final Map<String, dynamic>? fetched =
      await _fetchUserInfoRaw(userId, cookie, uaToUse);

  if (fetched == null) {
    throw Exception('invalid_payload');
  }

  info = fetched;
} catch (e) {
  final String raw = e.toString().toLowerCase();

  if (!raw.contains('http_429') && !raw.contains('429')) {
    rethrow;
  }

  info = <String, dynamic>{
    'username': currentUsername,
    'follower_count': 0,
    'following_count': 0,
    '_user_info_fallback': '429_pagination',
  };

  _logIgDiagnostic(
    'user_info_fallback',
    'user_info returned HTTP 429; continuing directly with pagination '
        'without using partial cached map sizes as the real totals.',
    label: 'analysis.user_info',
    uri: Uri.parse(
        'https://www.instagram.com/api/v1/users/$userId/info/'),
    statusCode: 429,
    isError: false,
  );
}

      // KullanÃ„Â±cÃ„Â± adÃ„Â± gÃƒÂ¼ncelle
      if (info['username'] != null) {
        String freshUser = info['username'].toString();
        if (currentUsername != freshUser) {
          setState(() => currentUsername = freshUser);
          _setAccountPrefString(prefs, 'session_username', freshUser,
              userId: userId);
        }
      }
      _applyUserFlags();
      if (_isBanned) return;

      int tFollowers = _toIntOrNull(info['follower_count']) ?? 0;
      int tFollowing = _toIntOrNull(info['following_count']) ?? 0;
      final int followersExpected = max(1, tFollowers);
      final int followingExpected = max(1, tFollowing);
      final int totalExpectedForProgress = max(
        1,
        followersExpected + followingExpected,
      );
      const double baseProgress = 0.10;
      const double fetchSpanTotal = 0.86;
      final double followersWeight =
          followersExpected / totalExpectedForProgress;
      final double followersSpan =
          (fetchSpanTotal * followersWeight).clamp(0.34, 0.66).toDouble();
      final double followingSpan = fetchSpanTotal - followersSpan;
      final double followingStart = baseProgress + followersSpan;
      _setAnalysisProgressCap(baseProgress + 0.04);

      final bool hasStoredData =
          followersMap.isNotEmpty || followingMap.isNotEmpty;
      if (hasStoredData && tFollowers == 0 && tFollowing == 0) {
        _showAnalysisWarning(localizeTrEn(_lang,
            'Instagram veri dÃƒÂ¶ndÃƒÂ¼rmedi.', 'Instagram returned no data.'));
        return;
      }

      final bool canRunDelta = _canRunDeltaProbe(
        prefs: prefs,
        followersTotal: tFollowers,
        followingTotal: tFollowing,
      );
      if (canRunDelta) {
        final int baselineFollowersTotal = prefs.getInt(_accountScopedKey(
                _analysisBaselineFollowersTotalKey,
                userId: userId)) ??
            -1;
        final int baselineFollowingTotal = prefs.getInt(_accountScopedKey(
                _analysisBaselineFollowingTotalKey,
                userId: userId)) ??
            -1;
        final String baselineFollowersSig = (prefs.getString(_accountScopedKey(
                    _analysisBaselineFollowersSigKey,
                    userId: userId)) ??
                '')
            .trim();
        final String baselineFollowingSig = (prefs.getString(_accountScopedKey(
                    _analysisBaselineFollowingSigKey,
                    userId: userId)) ??
                '')
            .trim();
        final Map<String, String> probeFollowers = <String, String>{};
        final Map<String, String> probeFollowing = <String, String>{};
        const double probeStart = 0.16;
        const double probeSpan = 0.38;
        const double probeFollowingStart = probeStart + (probeSpan * 0.5);

        try {
          // Sequential fetch for delta probe. Never parallelize traversal on the same session.
          analysisPhase = 'delta_followers';
          analysisEndpoint = 'friendships/$userId/followers';
          await _fetchPagedData(
            userId: userId,
            cookie: cookie,
            ua: uaToUse,
            type: 'followers',
            totalExpected: tFollowers,
            targetMap: probeFollowers,
            maxPages: _deltaProbeMaxPages,
            onProgress: (fetched) {
              final double fraction =
                  (fetched / max(1, _deltaSignatureSampleSize)).clamp(0.0, 1.0);
              _setAnalysisProgressCap(
                  probeStart + (fraction * probeSpan * 0.5));
            },
          );

          if (!mounted || !isProcessing) return;

          analysisPhase = 'delta_following';
          analysisEndpoint = 'friendships/$userId/following';
          await _fetchPagedData(
            userId: userId,
            cookie: cookie,
            ua: uaToUse,
            type: 'following',
            totalExpected: tFollowing,
            targetMap: probeFollowing,
            maxPages: _deltaProbeMaxPages,
            onProgress: (fetched) {
              final double fraction =
                  (fetched / max(1, _deltaSignatureSampleSize)).clamp(0.0, 1.0);
              _setAnalysisProgressCap(
                  probeFollowingStart + (fraction * probeSpan * 0.5));
            },
          );
        } catch (_) {
          probeFollowers.clear();
          probeFollowing.clear();
        }
        _setAnalysisProgressCap(0.60);

        final String probeFollowersSig = _buildHeadSignature(probeFollowers);
        final String probeFollowingSig = _buildHeadSignature(probeFollowing);
        final bool totalsStableForNoChange =
            (baselineFollowersTotal - tFollowers).abs() <=
                    _deltaCountTolerance(baselineFollowersTotal) &&
                (baselineFollowingTotal - tFollowing).abs() <=
                    _deltaCountTolerance(baselineFollowingTotal);
        final bool noChange = totalsStableForNoChange &&
            probeFollowersSig.isNotEmpty &&
            probeFollowingSig.isNotEmpty &&
            baselineFollowersSig == probeFollowersSig &&
            baselineFollowingSig == probeFollowingSig;

        if (noChange) {
          _logFirebaseDiagnostic(
            'analysis',
            'fast probe: no change detected, followers=$tFollowers following=$tFollowing',
          );
          await _setAccountPrefString(
              prefs, 'new_followers_map', jsonEncode(<String, String>{}),
              userId: userId);
          await _persistFastNoChangeSnapshot(
            prefs,
            followersTotal: tFollowers,
            followingTotal: tFollowing,
            probeFollowers: probeFollowers,
            probeFollowing: probeFollowing,
          );
          final DateTime realNow = await _getNetworkTime();
          final int currentWindowCount =
              _analysisWindowCount(prefs, realNow) + 1;
          await _setAccountPrefInt(
              prefs, _analysisWindowCountKey, currentWindowCount,
              userId: userId);
          await _setAccountPrefInt(
              prefs, 'last_update_time', realNow.millisecondsSinceEpoch,
              userId: userId);
          await _loadStoredData();
          if (mounted) {
            setState(() {
              _hasAnalyzed = true;
              _resetBadgesAndNewItems();
              _syncCountsForUi();
            });
          } else {
            _hasAnalyzed = true;
            _resetBadgesAndNewItems();
            _syncCountsForUi();
          }
          unawaited(_incrementFirestoreCounter('query_count'));
          unawaited(TelemetryService.instance.recordAnalysisCompleted(
            followersCount: tFollowers,
            followingCount: tFollowing,
            duration: _analysisStartedAt == null
                ? null
                : DateTime.now().difference(_analysisStartedAt!),
          ));
          _setAnalysisProgressCap(0.985);
          await _finishProgressUi();
          unawaited(_showEntryInterstitialIfEligible('analysis_end'));

          if (_justWatchedReward) {
            if (mounted) {
              setState(() => _justWatchedReward = false);
            } else {
              _justWatchedReward = false;
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_t('analysis_fast_no_change')),
                backgroundColor: Colors.green));
          }
          return;
        } else {
          // Delta probe mismatch: Fallback to full scan.
          // Reset progress logically so it doesn't get stuck at 59% (0.60 cap).
          _setAnalysisProgressCap(baseProgress + 0.04);
        }
      }

      Map<String, String> nFollowers = {};

      _logFirebaseDiagnostic(
        'analysis',
        'starting full pagination scan: expectedFollowers=$tFollowers expectedFollowing=$tFollowing',
      );

      analysisPhase = 'followers';
      analysisEndpoint = 'friendships/$userId/followers';
      final int fetchedFollowers = await _fetchPagedData(
          userId: userId,
          cookie: cookie,
          ua: uaToUse,
          type: 'followers',
          totalExpected: tFollowers,
          targetMap: nFollowers,
          onProgress: (fetched) {
            final double fraction =
                (fetched / followersExpected).clamp(0.0, 1.0);
            _setAnalysisProgressCap(baseProgress + (fraction * followersSpan));
          });
      if (_fetchChunkStopRequested) {
        stopProcessingUi();
        return;
      }
      _setAnalysisProgressCap(
        (followingStart + 0.02).clamp(0.0, 0.92).toDouble(),
      );

      Map<String, String> nFollowing = {};

      analysisPhase = 'following';
      analysisEndpoint = 'friendships/$userId/following';
      final int fetchedFollowing = await _fetchPagedData(
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
      if (_fetchChunkStopRequested) {
        stopProcessingUi();
        return;
      }
      _setAnalysisProgressCap(0.92);
      _setAnalysisProgressCap(0.96);

      final double followersCoverageNeeded = _requiredCoverageRatio(tFollowers);
      final double followingCoverageNeeded = _requiredCoverageRatio(tFollowing);

      if (tFollowers > 0 &&
          fetchedFollowers < (tFollowers * followersCoverageNeeded)) {
        _showAnalysisWarning(localizeTrEn(
          _lang,
          'Veri yÃƒÂ¼kleme kesildi: takipÃƒÂ§i verisi eksik ($fetchedFollowers/$tFollowers). Biraz bekleyip tekrar deneyin.',
          'Data loading was interrupted: follower data incomplete ($fetchedFollowers/$tFollowers). Please wait a bit and try again.',
        ));
        return;
      }
      if (tFollowing > 0 &&
          fetchedFollowing < (tFollowing * followingCoverageNeeded)) {
        _showAnalysisWarning(localizeTrEn(
          _lang,
          'Veri yÃƒÂ¼kleme kesildi: takip edilen verisi eksik ($fetchedFollowing/$tFollowing). Biraz bekleyip tekrar deneyin.',
          'Data loading was interrupted: following data incomplete ($fetchedFollowing/$tFollowing). Please wait a bit and try again.',
        ));
        return;
      }

      if (nFollowers.isNotEmpty || nFollowing.isNotEmpty) {
        _setAnalysisProgressCap(0.985);
        await Future.delayed(const Duration(milliseconds: 16));
        // If allowed, use fast delta snapshot diff to compute results quickly.
        if (_canRunDeltaProbe(
            prefs: prefs,
            followersTotal: tFollowers,
            followingTotal: tFollowing)) {
          await _applyFastSnapshotDiff(
              prefs: prefs, nFollowers: nFollowers, nFollowing: nFollowing);
          await _persistFastNoChangeSnapshot(
            prefs,
            followersTotal: tFollowers,
            followingTotal: tFollowing,
            probeFollowers: nFollowers,
            probeFollowing: nFollowing,
          );
          await _finishProgressUi();
          unawaited(_showEntryInterstitialIfEligible('analysis_end'));
          if (_justWatchedReward) setState(() => _justWatchedReward = false);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_t('data_updated')),
                backgroundColor: Colors.green));
        } else {
          await _processData(nFollowers, nFollowing);
          await _persistFullAnalysisSnapshot(
            prefs,
            followersTotal: tFollowers,
            followingTotal: tFollowing,
            followersData: nFollowers,
            followingData: nFollowing,
          );
          unawaited(TelemetryService.instance.recordAnalysisCompleted(
            followersCount: fetchedFollowers,
            followingCount: fetchedFollowing,
            duration: _analysisStartedAt == null
                ? null
                : DateTime.now().difference(_analysisStartedAt!),
          ));
          await _finishProgressUi();
          unawaited(_showEntryInterstitialIfEligible('analysis_end'));

          if (_justWatchedReward) setState(() => _justWatchedReward = false);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_t('data_updated')),
                backgroundColor: Colors.green));
        }
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
            'Veri yÃƒÂ¼kleme kesildi: Instagram boÃ…Å¸ veri dÃƒÂ¶ndÃƒÂ¼rdÃƒÂ¼. LÃƒÂ¼tfen tekrar deneyin.',
            'Data loading was interrupted: Instagram returned empty data. Please try again.',
          ));
        }
      }
    } catch (e, st) {
      final String failureDetails = _buildAnalysisFailureDetails(
        error: e,
        stackTrace: st,
        phase: analysisPhase,
        endpoint: analysisEndpoint,
      );
      _logIgDiagnostic(
        'analysis_failure',
        'ANALYSIS FAILED phase=$analysisPhase endpoint=${analysisEndpoint.isEmpty ? '(unknown)' : analysisEndpoint}',
        label: 'analysis.failure',
        error: e,
        stackTrace: st,
        isError: true,
      );
      _appendIgDiagnosticEvent(failureDetails);

      String reason = localizeTrEn(
        _lang,
        'Veri yÃƒÂ¼kleme kesildi: beklenmeyen bir hata oluÃ…Å¸tu.',
        'Data loading stopped due to an unexpected error.',
      );
      final String raw = e.toString();
      final String rawLower = raw.toLowerCase();

      if (rawLower.contains('ig_warning')) {
        final String igMsg = _extractIgWarningTextFromError(e).trim();
        reason = localizeTrEn(
          _lang,
          'Instagram otomatik davranÃ„Â±Ã…Å¸ uyarÃ„Â±sÃ„Â± verdi. GÃƒÂ¼venlik iÃƒÂ§in veri ÃƒÂ§ekme durduruldu. Biraz bekleyip tekrar deneyin.',
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
          'Instagram gÃƒÂ¼venlik doÃ„Å¸rulamasÃ„Â± istedi (Ã…Å¸ÃƒÂ¼pheli giriÃ…Å¸ / hesap kilidi). Instagram uygulamasÃ„Â±ndan doÃ„Å¸rulayÃ„Â±p tekrar deneyin.',
          'Instagram requested security verification (suspicious login / account lock). Verify in Instagram app and try again.',
        );
        unawaited(_showIgSecurityVerificationGuide(code));
      } else if (rawLower.contains('session_invalid') ||
          rawLower.contains('http_401') ||
          rawLower.contains('http_403')) {
        final bool recovered = await _recoverSessionState(prefs);
        if (recovered) {
          reason = localizeTrEn(
            _lang,
            'Oturum yenilendi. Lutfen tekrar deneyin.',
            'Session was refreshed. Please try again.',
          );
        } else {
          reason = localizeTrEn(
            _lang,
            'Oturum dogrulama bekliyor. Lutfen Instagram uygulamasindan dogrulayip tekrar deneyin.',
            'Session is invalid or waiting for verification. Verify in Instagram app and try again.',
          );
          _scheduleIgVerificationGuide('session_invalid');
        }
      } else if (rawLower.contains('http_429')) {
        reason = localizeTrEn(
          _lang,
          'Ãƒâ€¡ok hÃ„Â±zlÃ„Â± istek gÃƒÂ¶nderildi. Veri yÃƒÂ¼kleme gÃƒÂ¼venlik nedeniyle kesildi.',
          'Too many requests were sent. Data loading was interrupted for safety.',
        );
      } else if (rawLower.contains('ig_cooldown_active')) {
        final Duration? cooldownLeft = _remainingIgSafetyCooldown();
        reason = cooldownLeft != null
            ? _t('remaining_time', {'time': _formatDuration(cooldownLeft)})
            : _t('rate_limited');
      } else if (rawLower.contains('timeoutexception') ||
          rawLower.contains('timeout')) {
        reason = localizeTrEn(
          _lang,
          'BaÃ„Å¸lantÃ„Â± zaman aÃ…Å¸Ã„Â±mÃ„Â±na uÃ„Å¸radÃ„Â±. Veri yÃƒÂ¼kleme yarÃ„Â±da kesildi.',
          'Connection timed out. Data loading was interrupted.',
        );
      } else if (rawLower.contains('socketexception') ||
          rawLower.contains('failed host lookup') ||
          rawLower.contains('network is unreachable') ||
          rawLower.contains('connection reset') ||
          rawLower.contains('clientexception')) {
        reason = localizeTrEn(
          _lang,
          'Ã„Â°nternet baÃ„Å¸lantÃ„Â±sÃ„Â± kesildi veya zayÃ„Â±f. Veri yÃƒÂ¼kleme tamamlanamadÃ„Â±.',
          'Network connection dropped or is unstable. Data loading could not complete.',
        );
      } else if (rawLower.contains('handshakeexception') ||
          rawLower.contains('certificate')) {
        reason = localizeTrEn(
          _lang,
          'GÃƒÂ¼venli baÃ„Å¸lantÃ„Â± kurulamadÃ„Â±Ã„Å¸Ã„Â± iÃƒÂ§in veri yÃƒÂ¼kleme durdu.',
          'Secure connection could not be established, so loading stopped.',
        );
      } else if (rawLower.contains('invalid_json') ||
          rawLower.contains('invalid_payload')) {
        reason = localizeTrEn(
          _lang,
          'Instagram beklenmeyen bir yanÃ„Â±t dÃƒÂ¶ndÃƒÂ¼rdÃƒÂ¼. Veri yÃƒÂ¼kleme kesildi.',
          'Instagram returned an unexpected response. Data loading was interrupted.',
        );
      } else if (rawLower.contains('http_')) {
        final int? code = _parseHttpErrorCode(rawLower);
        if (code != null) {
          reason = localizeTrEn(
            _lang,
            'Instagram sunucusu hata dÃƒÂ¶ndÃƒÂ¼rdÃƒÂ¼ (HTTP $code). Veri yÃƒÂ¼kleme kesildi.',
            'Instagram returned an error (HTTP $code). Data loading was interrupted.',
          );
        } else {
          reason = localizeTrEn(
            _lang,
            'Instagram sunucusu hata dÃƒÂ¶ndÃƒÂ¼rdÃƒÂ¼. Veri yÃƒÂ¼kleme kesildi.',
            'Instagram returned an error. Data loading was interrupted.',
          );
        }
      }
      _showAnalysisWarning(reason, details: failureDetails);
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
        _queueQuickStoryTrayRefresh(delay: Duration.zero);
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
      msg = msg.isEmpty
          ? cleanFeedbackMessage
          : '$msg Ã¢â‚¬â€ $cleanFeedbackMessage';
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
      _registerIgRiskSignal();
      return false;
    }
    final int? code = _parseHttpErrorCode(raw);
    if (code != null) {
      if (code == 429) {
        _registerIgRiskSignal(minimumCooldown: _igSafetyCooldown429Fallback);
        return false;
      }
      if (code == 401 || code == 403) return false;
      if (code == 408) return true;
      if (code == 301 || code == 302) return false;
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
        final int jitterMs = _storyRand.nextInt(100);
        await Future.delayed(Duration(
            milliseconds:
                (_adsDisabled ? (backoffMs ~/ 2) : backoffMs) + jitterMs));
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

    // Use a stable jitter for consistent network signature
    final int jitterMs =
        jitterMaxMs <= 0 ? 0 : _storyRand.nextInt(jitterMaxMs + 1);

    // Simplifed, deterministic pacing.
    // "Fake humanization" (breathers/pauses) is often a bot signal.
    // Consistent, low-noise client behavior is safer.
    final bool isPremium = _adsDisabled;
    final int baseGapMs = minGap.inMilliseconds;

    final int desiredGapMs = isPremium
        ? baseGapMs + _storyRand.nextInt(100)
        : baseGapMs + jitterMs + (isProcessing ? 150 : 0);

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
    Duration minGap = const Duration(milliseconds: 2200),
    int jitterMaxMs = 1600,
    bool allowBreather = false,
  }) async {
    final Completer<T> completer = Completer<T>();
    final Future<void> previous = _igRequestChain.catchError((_) {});
    _igRequestChain = previous.then((_) async {
      try {
        final Duration? cooldown = _remainingIgSafetyCooldown();
        if (cooldown != null) {
          throw Exception('ig_cooldown_active');
        }
        // Keep analysis fetches running when app is backgrounded.
        final bool requireForeground = !isProcessing;
        if (requireForeground) {
          await _waitUntilAppResumedIfNeeded();
        }
        await _applyIgRequestPacing(
          minGap: minGap,
          jitterMaxMs: jitterMaxMs,
          allowBreather: allowBreather,
        );
        if (requireForeground) {
          await _waitUntilAppResumedIfNeeded();
        }
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

  // IMPORTANT: http.Response.body can throw FormatException when the server
  // advertises a charset/encoding that does not match the actual bytes.
  // Instagram occasionally returns such payloads. Never let diagnostic/logging
  // code crash the entire analysis before we can inspect the real response.
  String _safeResponseBody(http.Response response) {
    try {
      return response.body;
    } catch (e) {
      try {
        final List<int> bytes = response.bodyBytes;
        final String hexPreview = bytes
            .take(32)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(' ');
        final String decoded = utf8.decode(bytes, allowMalformed: true);
        final String encoding =
            response.headers.entries
                .firstWhere(
                  (entry) => entry.key.toLowerCase() == 'content-encoding',
                  orElse: () => const MapEntry<String, String>(
                    'content-encoding',
                    '(none)',
                  ),
                )
                .value;
        final String compressionWarning = encoding.toLowerCase().contains('br')
            ? '[BROTLI_WARNING: Instagram returned Brotli despite Accept-Encoding: identity.\n'
              'The request must be retried with compression disabled before JSON parsing.]\n'
            : '';
        return '[BODY_DECODE_ERROR: ${e.runtimeType}: $e]\n'
            '[CONTENT_ENCODING: $encoding]\n'
            '[RAW_BYTES_LENGTH: ${bytes.length}]\n'
            '[RAW_BYTES_HEX_FIRST_32: $hexPreview]\n'
            '$compressionWarning'
            '$decoded';
      } catch (fallbackError) {
        return '[BODY_DECODE_ERROR: ${e.runtimeType}: $e]\n'
            '[FALLBACK_DECODE_ERROR: $fallbackError]';
      }
    }
  }

  Future<http.Response> _igGet(
    Uri uri, {
    required Map<String, String> headers,
    Duration minGap = const Duration(milliseconds: 2200),
    int jitterMaxMs = 1600,
    bool allowBreather = false,
    String? debugLabel,
  }) {
    final Map<String, String> requestHeaders =
        Map<String, String>.from(headers);
    final String requestCookie =
        (requestHeaders['Cookie'] ?? requestHeaders['cookie'] ?? '').trim();
    final String label = (debugLabel ?? uri.path).trim();
    final int requestId = ++_igRequestSequence;
    final Stopwatch stopwatch = Stopwatch()..start();
    _logIgDiagnostic(
      'request_start',
      'request#$requestId GET started',
      label: label,
      uri: uri,
      headers: requestHeaders,
    );
    return _withIgRequestPacing(
      () async {
        try {
          final http.Response response =
              await _httpClient.get(uri, headers: requestHeaders).timeout(
                    _igRequestTimeout,
                  );
          stopwatch.stop();
          _logIgDiagnostic(
            'response',
            'request#$requestId completed',
            label: label,
            uri: uri,
            statusCode: response.statusCode,
            elapsed: stopwatch.elapsed,
            responseHeaders: response.headers,
            responseBody: _safeResponseBody(response),
          );
          _refreshSessionCookieFromResponseHeaders(
            response.headers,
            requestCookie: requestCookie,
          );
          return response;
        } catch (e, st) {
          stopwatch.stop();
          _logIgDiagnostic(
            'request_error',
            'request#$requestId failed',
            label: label,
            uri: uri,
            elapsed: stopwatch.elapsed,
            error: e,
            stackTrace: st,
            isError: true,
          );
          rethrow;
        }
      },
      minGap: minGap,
      jitterMaxMs: jitterMaxMs,
      allowBreather: allowBreather,
    );
  }

  Future<http.Response> _igGetWithStatusRetry(
    Uri uri, {
    required Map<String, String> headers,
    Duration minGap = const Duration(milliseconds: 2200),
    int jitterMaxMs = 1600,
    bool allowBreather = false,
    String? debugLabel,
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    StackTrace? lastStackTrace;
    final int attempts = max(1, maxAttempts);

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        final String? attemptLabel = debugLabel == null
            ? null
            : (attempt == 1 ? debugLabel : '$debugLabel.retry$attempt');
        final http.Response response = await _igGet(
          uri,
          headers: headers,
          minGap: minGap,
          jitterMaxMs: jitterMaxMs,
          allowBreather: allowBreather,
          debugLabel: attemptLabel,
        );
        final bool retryableStatus = response.statusCode == 408 ||
            (response.statusCode >= 500 && response.statusCode <= 599);
        if (!retryableStatus || attempt >= attempts) {
          return response;
        }

        final int baseDelayMs = response.statusCode >= 500 ? 5000 : 900;
        final int jitterMs =
            _storyRand.nextInt(response.statusCode >= 500 ? 3001 : 251);
        final int delayMs = (_adsDisabled
                ? ((baseDelayMs * attempt) ~/ 2)
                : baseDelayMs * attempt) +
            jitterMs;
        _logIgDiagnostic(
          'retry',
          'HTTP ${response.statusCode}; retrying same request '
              'attempt ${attempt + 1}/$attempts',
          label: debugLabel ?? uri.path,
          uri: uri,
          statusCode: response.statusCode,
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        if (attempt >= attempts || !_isRetryableIgException(e)) {
          rethrow;
        }
        final int backoffMs =
            _igRetryBaseDelay.inMilliseconds * (1 << (attempt - 1));
        final int jitterMs = _storyRand.nextInt(251);
        _logIgDiagnostic(
          'retry',
          'request failed; retrying same request attempt ${attempt + 1}/$attempts',
          label: debugLabel ?? uri.path,
          uri: uri,
          error: e,
        );
        await Future.delayed(Duration(
          milliseconds:
              (_adsDisabled ? (backoffMs ~/ 2) : backoffMs) + jitterMs,
        ));
      }
    }

    if (lastError != null && lastStackTrace != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace);
    }
    throw Exception('unknown_ig_retry_error');
  }

  void _queueQuickStoryTrayRefresh({
    bool force = false,
    Duration delay = const Duration(milliseconds: 450),
  }) {
    if (!isLoggedIn || savedCookie == null) return;
    if (!force) {
      final DateTime? last = _lastStoryTrayQuickRefreshAt;
      if (last != null &&
          DateTime.now().difference(last) < _storyTrayQuickRefreshMinGap) {
        return;
      }
    }
    _lastStoryTrayQuickRefreshAt = DateTime.now();
    unawaited(() async {
      try {
        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }
        if (!mounted || !isLoggedIn) return;
        await _loadStoryTray();
      } catch (_) {}
    }());
  }

  Future<Map<String, dynamic>?> _fetchUserInfoRaw(
      String userId, String cookie, String ua) async {
    String? terminalError;

    Map<String, dynamic>? parseUser(http.Response response) {
      if (response.statusCode != 200) {
        final String? security = _detectIgSecurityBlockFromText(_safeResponseBody(response));
        if (security != null) {
          terminalError = security;
          return null;
        }
        final String? warning = _detectIgWarningFromText(_safeResponseBody(response));
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
  // user_info endpoint'i kendi başına throttle edilebilir.
  // Buradaki 429'u global Instagram güvenlik cooldown'una
  // dönüştürme. Çağıran analiz akışı kontrollü fallback yapacak.
  terminalError = 'http_429';
  return null;
      }
      if (response.statusCode != 200) {
        terminalError ??= 'http_${response.statusCode}';
        return null;
      }
      try {
        final String rawBody = _safeResponseBody(response);
        final String contentEncoding = response.headers.entries
            .firstWhere(
              (entry) => entry.key.toLowerCase() == 'content-encoding',
              orElse: () => const MapEntry<String, String>('content-encoding', ''),
            )
            .value
            .toLowerCase()
            .trim();
        if (contentEncoding.contains('br')) {
          terminalError = 'brotli_response_received';
          _logIgDiagnostic(
            'response_decode_error',
            'Instagram returned Brotli despite identity encoding request; JSON parsing skipped.',
            label: 'fetchUserInfoRaw.web',
            uri: Uri.parse('https://www.instagram.com/api/v1/users/$userId/info/'),
            statusCode: response.statusCode,
            responseHeaders: response.headers,
            responseBody: rawBody,
            isError: true,
          );
          return null;
        }
        final body = jsonDecode(rawBody);
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
        final String? security = _detectIgSecurityBlockFromText(_safeResponseBody(response));
        if (security != null) {
          terminalError ??= security;
        } else {
          final String? warning = _detectIgWarningFromText(_safeResponseBody(response));
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

    final webResp = await _igGet(
      Uri.parse("https://www.instagram.com/api/v1/users/$userId/info/"),
      headers: _buildWebHeaders(
        cookie,
        ua,
        dsUserId: userId,
        referer: _instagramProfileReferer(currentUsername),
        igWwwClaim: _igWwwClaimToken,
      ),
      minGap: const Duration(milliseconds: 460),
      jitterMaxMs: 320,
      debugLabel: 'fetchUserInfoRaw.web',
    );
    final parsed = parseUser(webResp);
    if (parsed != null) return parsed;

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
      Function(int count)? onProgress,
      int? maxPages}) async {
    final String endpoint = type == 'followers'
        ? 'friendships/$userId/followers'
        : 'friendships/$userId/following';
    // Force web-only usage to lock identity to Mobile Web UA
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String accountUserId = _currentAccountUserId();
    final Map<String, dynamic>? savedCursorState =
        _readFetchCursorState(prefs, userId: accountUserId);
    final String? savedCursorType =
        savedCursorState?['type']?.toString().trim();
    final String? savedCursor = savedCursorState?['cursor']?.toString().trim();

    String? nextMaxId =
        savedCursorType == type && savedCursor != null && savedCursor.isNotEmpty
            ? savedCursor
            : null;
    bool hasNext = true;
    int currentCount = targetMap.length;
    String? terminalError;
    final int expected = max(1, totalExpected);
    final double requiredCoverageRatio = _requiredCoverageRatio(expected);
    final int sessionStartCount = currentCount;
    final bool applyChunkLimit = maxPages == null;
    const int sessionChunkLimit = 1000;
    final int longWaitIntervalPages =
        max(2, ((3 + _storyRand.nextInt(2)) * 3) ~/ 4);

    int adaptiveMinGapMs;
    int adaptiveJitterMaxMs;
    final int adaptiveMinGapMaxMs;
    int scaleMs(int value) =>
        max(1, (value * _analysisSpeedMultiplier).round());
    // Keep pacing human-like, but trim waits by 25% to speed up the analysis.
    if (expected <= 350) {
      adaptiveMinGapMs = scaleMs(2000);
      adaptiveJitterMaxMs = scaleMs(1500);
      adaptiveMinGapMaxMs = scaleMs(3000);
    } else if (expected <= 1200) {
      adaptiveMinGapMs = scaleMs(2200);
      adaptiveJitterMaxMs = scaleMs(2000);
      adaptiveMinGapMaxMs = scaleMs(3600);
    } else if (expected <= 8000) {
      adaptiveMinGapMs = scaleMs(2500);
      adaptiveJitterMaxMs = scaleMs(3000);
      adaptiveMinGapMaxMs = scaleMs(5000);
    } else {
      adaptiveMinGapMs = scaleMs(3000);
      adaptiveJitterMaxMs = scaleMs(4000);
      adaptiveMinGapMaxMs = scaleMs(6000);
    }
    int repeatedCursorCount = 0;
    int pageIndex = 0;
    final int? pageLimit = (maxPages != null && maxPages > 0) ? maxPages : null;

    bool hasEnoughCoverageToStopEarly() {
      if (totalExpected <= 0) return false;
      final double coverage = currentCount / expected;
      return coverage >= requiredCoverageRatio;
    }

    bool shouldStopAfterIgWarning() {
      if (expected > 500) {
        _registerIgRiskSignal();
        return true;
      }
      return hasEnoughCoverageToStopEarly();
    }

    void slowDownAdaptivePacing() {
      adaptiveMinGapMs = min(
        adaptiveMinGapMaxMs,
        adaptiveMinGapMs + 100,
      );
      adaptiveJitterMaxMs = min(scaleMs(5000), adaptiveJitterMaxMs + 150);
    }

    while (hasNext) {
      pageIndex++;
      if (pageLimit != null && pageIndex > pageLimit) break;

      // Stable request base
      const String base = "https://www.instagram.com/api/v1/";
      final String? requestCursor = nextMaxId;
      final Uri baseUri = Uri.parse("$base$endpoint");

      // Instagram tarafında daha güvenli ve doğal görünen düşük sayfa boyutu.
      // Keep page size stable across pagination. Changing count while reusing
      // next_max_id can make Instagram return a transient 500/Oops response.
      final int pageCount = type == 'followers' ? 30 : 25;

      final Map<String, String> query = <String, String>{
        'count': pageCount.toString(),
      };
      if (type == 'followers') {
        query['search_surface'] = 'follow_list_page';
      }
      if (requestCursor != null && requestCursor.isNotEmpty) {
        query['max_id'] = requestCursor;
      }
      final Uri requestUri = baseUri.replace(queryParameters: query);
      final String requestCookie = _latestSessionCookie(fallback: cookie);
      final String requestDsUserId =
          (_resolveSessionDsUserId(savedUserId, requestCookie) ?? userId)
              .trim();
      final String requestReferer =
          _instagramProfileReferer(currentUsername, section: type);

      final response = await _igGetWithStatusRetry(
        requestUri,
        headers: _buildWebHeaders(
          requestCookie,
          ua,
          dsUserId: requestDsUserId,
          referer: requestReferer,
          igWwwClaim: _igWwwClaimToken,
        ),
        minGap: Duration(milliseconds: adaptiveMinGapMs),
        jitterMaxMs: adaptiveJitterMaxMs,
        allowBreather: false,
        debugLabel: 'fetchPagedData.$type.page$pageIndex',
        maxAttempts: 3,
      );

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(_safeResponseBody(response));
        } catch (_) {
          final String? security =
              _detectIgSecurityBlockFromText(_safeResponseBody(response));
          if (security != null) {
            terminalError = security;
            throw Exception(terminalError);
          }
          slowDownAdaptivePacing();
          throw Exception('invalid_json');
        }
        if (decoded is! Map) {
          slowDownAdaptivePacing();
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
          throw Exception(terminalError);
        }

        final String? warning = _detectIgWarningFromMap(data);
        if (warning != null) {
          slowDownAdaptivePacing();
          if (shouldStopAfterIgWarning()) {
            hasNext = false;
            break;
          }
          terminalError = 'ig_warning:$warning';
          throw Exception(terminalError);
        }

        if (status == 'fail') {
          slowDownAdaptivePacing();
          final String rawMsg = data['message']?.toString().trim() ?? '';
          if (shouldStopAfterIgWarning()) {
            hasNext = false;
            break;
          }
          terminalError =
              rawMsg.isNotEmpty ? 'ig_warning:$rawMsg' : 'ig_warning';
          throw Exception(terminalError);
        }

        final List users = data['users'] is List ? data['users'] : const [];
        for (final dynamic u in users) {
          if (u is! Map) continue;
          final String username = (u['username'] ?? '').toString().trim();
          if (username.isEmpty) continue;
          final String pk = (u['pk'] ?? u['pk_id'] ?? '').toString().trim();
          if (pk.isNotEmpty) {
            _storyUserPks[username.toLowerCase()] = pk;
          }
          String picUrl = _extractBestProfilePhotoUrlFromUser(u) ?? '';
          if (picUrl.isEmpty) {
            picUrl = _normalizeHdProfileImageUrl(
                (u['profile_pic_url_hd'] ?? u['profile_pic_url'] ?? '')
                    .toString());
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
        nextMaxId =
            (nextCursor != null && nextCursor.isNotEmpty) ? nextCursor : null;
        hasNext = nextMaxId != null;
        if (repeatedCursorCount >= 3) {
          hasNext = false;
        }
        if (pageLimit != null && pageIndex >= pageLimit) {
          hasNext = false;
        }
        if (totalExpected > 0 && currentCount >= totalExpected) {
          hasNext = false;
        }
        if (applyChunkLimit &&
            currentCount - sessionStartCount >= sessionChunkLimit) {
          if (nextMaxId != null && nextMaxId.isNotEmpty) {
            await _storeFetchCursorState(
              prefs,
              userId: accountUserId,
              type: type,
              cursor: nextMaxId,
              fetchedCount: currentCount,
              pageCount: pageIndex,
            );
          }
          _fetchChunkStopRequested = true;
          hasNext = false;
        }
        if (hasNext && pageIndex % longWaitIntervalPages == 0) {
          await Future.delayed(Duration(
            milliseconds: scaleMs(1500) + _storyRand.nextInt(scaleMs(1700)),
          ));
        }
      } else {
        final String? security = _detectIgSecurityBlockFromText(_safeResponseBody(response));
        if (security != null) {
          terminalError = security;
          throw Exception(terminalError);
        }
        slowDownAdaptivePacing();

        if (response.statusCode >= 500) {
          // IMPORTANT: Do NOT reset nextMaxId on 500. Preserve progress.
          await Future.delayed(Duration(
            milliseconds: scaleMs(5000) + _storyRand.nextInt(scaleMs(3001)),
          ));
        }

        if (response.statusCode == 429) {
          _activateIgSafetyCooldownFromHeaders(response.headers);
        }
        if ((response.statusCode == 429 || response.statusCode >= 500) &&
            hasEnoughCoverageToStopEarly()) {
          hasNext = false;
          break;
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          terminalError = 'session_invalid';
        } else if (response.statusCode == 429) {
          terminalError = 'http_429';
        } else {
          terminalError ??= 'http_${response.statusCode}';
        }
        throw Exception(terminalError);
      }
    }

    if (!applyChunkLimit || !hasNext) {
      if (!_fetchChunkStopRequested) {
        await _clearFetchCursorState(prefs, userId: accountUserId);
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
        userAgentRaw.isNotEmpty ? userAgentRaw : _resolveAppUserAgent('');
    _sessionAppUserAgent =
        userAgent.toLowerCase().contains('instagram') ? userAgent : null;
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
              'Oturum doÃ„Å¸rulamasÃ„Â± tamamlanamadÃ„Â±. LÃƒÂ¼tfen tekrar giriÃ…Å¸ yapÃ„Â±n.',
              'Session verification failed. Please log in again.')),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ));
      }
      return;
    }
    final String username = usernameRaw.isNotEmpty
        ? usernameRaw
        : (localizeTrEn(_lang, 'KullanÃ„Â±cÃ„Â±', 'User'));

    try {
      final prefs = await SharedPreferences.getInstance();
      await _persistActiveSessionPrefs(
        prefs,
        cookie: cookie,
        userId: userId,
        username: username,
        userAgent: userAgent,
      );
    } catch (_) {}

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

    unawaited(_persistOwnerUsernameIfNeeded(username));
    _applyUserFlags();
    if (_isBanned) return;
    _storyTrayRefreshQueued = false;
    await _loadStoredData();
    unawaited(_refreshData(
      startProcessingImmediately: true,
      skipStartPrompt: true,
    ));
  }

  Future<void> _processData(
      Map<String, String> nFollowers, Map<String, String> nFollowing) async {
    _setProgressValue(0.975);
    await Future.delayed(const Duration(milliseconds: 16));

    final prefs = await SharedPreferences.getInstance();
    Map<String, String> oldFollowers = _safeMapCast(
        jsonDecode(_accountPrefString(prefs, 'followers_map') ?? '{}'));
    Map<String, String> oldFollowing = _safeMapCast(
        jsonDecode(_accountPrefString(prefs, 'following_map') ?? '{}'));
    Map<String, String> storedUnfollowers = _safeMapCast(
        jsonDecode(_accountPrefString(prefs, 'unfollowers_map') ?? '{}'));
    Map<String, String> storedLeftFollowing = _safeMapCast(
        jsonDecode(_accountPrefString(prefs, 'left_following_map') ?? '{}'));

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

    final String accountUserId = _currentAccountUserId();
    await _setAccountPrefString(prefs, 'followers_map', jsonEncode(nFollowers),
        userId: accountUserId);
    _setProgressValue(0.9965);
    await Future.delayed(const Duration(milliseconds: 1));
    await _setAccountPrefString(prefs, 'following_map', jsonEncode(nFollowing),
        userId: accountUserId);
    _setProgressValue(0.9970);
    await Future.delayed(const Duration(milliseconds: 1));
    await _setAccountPrefString(
        prefs, 'unfollowers_map', jsonEncode(storedUnfollowers),
        userId: accountUserId);
    _setProgressValue(0.9975);
    await Future.delayed(const Duration(milliseconds: 1));
    await _setAccountPrefString(
        prefs, 'left_following_map', jsonEncode(storedLeftFollowing),
        userId: accountUserId);
    _setProgressValue(0.9980);
    await Future.delayed(const Duration(milliseconds: 1));
    await _setAccountPrefString(
        prefs, 'new_followers_map', jsonEncode(newFollowers),
        userId: accountUserId);
    _setProgressValue(0.9986);
    await Future.delayed(const Duration(milliseconds: 1));

    final realNow = await _getNetworkTime();
    final int currentWindowCount = _analysisWindowCount(prefs, realNow) + 1;
    await _setAccountPrefInt(prefs, _analysisWindowCountKey, currentWindowCount,
        userId: accountUserId);
    await _setAccountPrefInt(
        prefs, 'last_update_time', realNow.millisecondsSinceEpoch,
        userId: accountUserId);
    _setProgressValue(0.999);
    unawaited(_incrementFirestoreCounter('query_count'));
    _logFirebaseDiagnostic(
      'analysis',
      'full scan complete: newFollowers=${newFollowers.length} '
      'leftFollowing=${storedLeftFollowing.length}',
    );
    _hasAnalyzed = true;
    _loadStoredData();
  }

  String _resolveAppUserAgent(String candidateUserAgent) {
    final String direct = candidateUserAgent.trim();
    if (direct.isNotEmpty) {
      return _canonicalPlatformUserAgent(fallback: direct);
    }
    final String saved = (savedUserAgent ?? '').trim();
    if (saved.isNotEmpty) {
      return _canonicalPlatformUserAgent(fallback: saved);
    }
    return _sessionAppUserAgent ??= _canonicalPlatformUserAgent();
  }

  String _resolveUserAgent() {
    final String saved = (savedUserAgent ?? '').trim();
    if (saved.isNotEmpty && !saved.toLowerCase().contains('instagram')) {
      return saved;
    }
    return _resolveAppUserAgent('');
  }

  String _latestSessionCookie({required String fallback}) {
    final String latest = (savedCookie ?? '').trim();
    if (latest.isNotEmpty) return latest;
    return fallback.trim();
  }

  String _currentAccountUserId({String? fallbackCookie}) {
    final String direct = (savedUserId ?? '').trim();
    if (direct.isNotEmpty && direct != 'null') return direct;
    final String cookie = (fallbackCookie ?? savedCookie ?? '').trim();
    if (cookie.isNotEmpty) {
      final String fromCookie =
          _extractCookieValue(cookie, 'ds_user_id').trim();
      if (fromCookie.isNotEmpty && fromCookie != 'null') return fromCookie;
    }
    return '';
  }

  String _accountScopedKey(String key, {String? userId}) {
    final String scope = (userId ?? _currentAccountUserId()).trim();
    if (scope.isEmpty) return key;
    return '${key}_$scope';
  }

  String? _accountPrefString(
    SharedPreferences prefs,
    String key, {
    String? userId,
  }) {
    return prefs.getString(_accountScopedKey(key, userId: userId));
  }

  Future<void> _setAccountPrefString(
    SharedPreferences prefs,
    String key,
    String value, {
    String? userId,
  }) async {
    await prefs.setString(_accountScopedKey(key, userId: userId), value);
  }

  Future<void> _setAccountPrefInt(
    SharedPreferences prefs,
    String key,
    int value, {
    String? userId,
  }) async {
    await prefs.setInt(_accountScopedKey(key, userId: userId), value);
  }

  Future<void> _setAccountPrefBool(
    SharedPreferences prefs,
    String key,
    bool value, {
    String? userId,
  }) async {
    await prefs.setBool(_accountScopedKey(key, userId: userId), value);
  }

  Map<String, dynamic>? _readFetchCursorState(
    SharedPreferences prefs, {
    String? userId,
  }) {
    final String raw =
        (prefs.getString(_accountScopedKey('fetch_cursor', userId: userId)) ??
                '')
            .trim();
    if (raw.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return <String, dynamic>{'type': '', 'cursor': raw};
  }

  Future<void> _storeFetchCursorState(
    SharedPreferences prefs, {
    required String userId,
    required String type,
    required String cursor,
    required int fetchedCount,
    required int pageCount,
  }) async {
    if (userId.trim().isEmpty || cursor.trim().isEmpty) return;
    await _setAccountPrefString(
      prefs,
      'fetch_cursor',
      jsonEncode(<String, dynamic>{
        'type': type,
        'cursor': cursor,
        'fetched_count': fetchedCount,
        'page_count': pageCount,
      }),
      userId: userId,
    );
  }

  Future<void> _clearFetchCursorState(
    SharedPreferences prefs, {
    required String userId,
  }) async {
    await prefs.remove(_accountScopedKey('fetch_cursor', userId: userId));
  }

  String? _headerValueIgnoreCase(Map<String, String> headers, String name) {
    for (final MapEntry<String, String> entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  Map<String, String> _parseCookieHeader(String cookieHeader) {
    final Map<String, String> out = <String, String>{};
    for (final String token in cookieHeader.split(';')) {
      final String part = token.trim();
      if (part.isEmpty) continue;
      final int eq = part.indexOf('=');
      if (eq <= 0) continue;
      final String key = part.substring(0, eq).trim();
      final String value = part.substring(eq + 1).trim();
      if (key.isEmpty) continue;
      out[key] = value;
    }
    return out;
  }

  String _cookieMapToHeader(Map<String, String> cookieMap) {
    final List<String> parts = <String>[];
    for (final MapEntry<String, String> entry in cookieMap.entries) {
      final String key = entry.key.trim();
      final String value = entry.value.trim();
      if (key.isEmpty) continue;
      parts.add('$key=$value');
    }
    return parts.join('; ');
  }

  String _extractCookieFromSetCookie(String setCookieHeader, String name) {
    if (setCookieHeader.trim().isEmpty || name.trim().isEmpty) return '';
    final RegExp reg = RegExp(
      '(?:^|,\\s*)${RegExp.escape(name)}=([^;\\r\\n]*)',
      caseSensitive: false,
    );
    final Match? match = reg.firstMatch(setCookieHeader);
    if (match == null) return '';
    return (match.group(1) ?? '').trim();
  }

  void _refreshSessionCookieFromResponseHeaders(
    Map<String, String> responseHeaders, {
    required String requestCookie,
  }) {
    final String setCookie =
        (_headerValueIgnoreCase(responseHeaders, 'set-cookie') ?? '').trim();
    final String setWwwClaim =
        (_headerValueIgnoreCase(responseHeaders, 'x-ig-set-www-claim') ?? '')
            .trim();
    if (setCookie.isEmpty && setWwwClaim.isEmpty) return;

    _logIgDiagnostic(
      'session_refresh',
      'response headers changed session state',
      responseHeaders: responseHeaders,
    );

    const List<String> tracked = <String>[
      'sessionid',
      'ds_user_id',
      'csrftoken',
      'rur',
      'mid',
      'ig_did',
      'shbid',
      'shbts',
      'ig_nrcb',
      'ig_cb',
    ];
    final String baseCookie = _latestSessionCookie(fallback: requestCookie);
    final Map<String, String> cookieMap = _parseCookieHeader(baseCookie);
    if (cookieMap.isEmpty) {
      cookieMap.addAll(_parseCookieHeader(requestCookie));
    }

    // If server only sent an X-IG-Set-WWW-Claim header (no Set-Cookie),
    // store it separately and avoid rebuilding the cookie header which
    // could drop empty-valued cookies.
    if (setWwwClaim.isNotEmpty && setCookie.isEmpty) {
      if (mounted) {
        setState(() => _igWwwClaimToken = setWwwClaim);
      } else {
        _igWwwClaimToken = setWwwClaim;
      }
      unawaited(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ig_www_claim', setWwwClaim);
        } catch (_) {}
      }());
      return;
    }

    bool changed = false;
    // If x-ig-set-www-claim is present alongside Set-Cookie, keep the
    // token in state but do not inject it into the cookie string.
    if (setWwwClaim.isNotEmpty) {
      if (mounted) {
        setState(() => _igWwwClaimToken = setWwwClaim);
      } else {
        _igWwwClaimToken = setWwwClaim;
      }
    }
    for (final String name in tracked) {
      final String nextValue = _extractCookieFromSetCookie(setCookie, name);
      if (nextValue.isEmpty) continue;
      final String previous = (cookieMap[name] ?? '').trim();
      if (previous == nextValue) continue;
      cookieMap[name] = nextValue;
      changed = true;
    }
    if (!changed || cookieMap.isEmpty) return;

    final String mergedCookie = _cookieMapToHeader(cookieMap);
    if (mergedCookie.isEmpty) return;
    savedCookie = mergedCookie;
    final String dsUserId = (cookieMap['ds_user_id'] ?? '').trim();
    if (dsUserId.isNotEmpty && dsUserId != 'null') {
      savedUserId = dsUserId;
    }

    final String persistUserId =
        _cleanSessionUserId(dsUserId).isNotEmpty
            ? dsUserId
            : _userIdFromCookie(mergedCookie);
    if (persistUserId.isNotEmpty) {
      unawaited(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await _persistActiveSessionPrefs(
            prefs,
            cookie: mergedCookie,
            userId: persistUserId,
            username: currentUsername,
            userAgent: savedUserAgent,
          );
          if (setWwwClaim.isNotEmpty) {
            await prefs.setString('ig_www_claim', setWwwClaim);
          }
        } catch (_) {}
      }());
    }
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
    final String accountUserId = _currentAccountUserId();
    try {
      _networkTimeOffsetMs = prefs.getInt(_accountScopedKey(
        _networkTimeOffsetKey,
        userId: accountUserId,
      ));
    } catch (_) {}
    final int? lastUpdateMs = prefs.getInt(
      _accountScopedKey('last_update_time', userId: accountUserId),
    );
    final Map<String, String> storedFollowers = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'followers_map', userId: accountUserId) ??
            '{}'));
    final Map<String, String> storedFollowing = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'following_map', userId: accountUserId) ??
            '{}'));
    final Map<String, String> storedUnfollowers = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'unfollowers_map', userId: accountUserId) ??
            '{}'));
    final Map<String, String> storedLeftFollowing = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'left_following_map',
                userId: accountUserId) ??
            '{}'));
    final Map<String, String> storedNewFollowers = _safeMapCast(jsonDecode(
        _accountPrefString(prefs, 'new_followers_map', userId: accountUserId) ??
            '{}'));
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

  String _stableUserListSignature(Iterable<String> usernames) {
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    const int mask64 = 0xFFFFFFFFFFFFFFFF;
    int hash = fnvOffset;
    int count = 0;
    for (final String raw in usernames) {
      final String value = _normalizeUserKey(raw);
      if (value.isEmpty) continue;
      count++;
      for (final int codeUnit in value.codeUnits) {
        hash = ((hash ^ codeUnit) * fnvPrime) & mask64;
      }
      hash = ((hash ^ 0x1f) * fnvPrime) & mask64;
    }
    if (count == 0) return '';
    return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  String _buildHeadSignature(Map<String, String> users,
      {int sampleSize = _deltaSignatureSampleSize}) {
    if (users.isEmpty || sampleSize <= 0) return '';
    final List<String> sample = <String>[];
    for (final String username in users.keys) {
      final String clean = _normalizeUserKey(username);
      if (clean.isEmpty) continue;
      sample.add(clean);
      if (sample.length >= sampleSize) break;
    }
    sample.sort();
    return _stableUserListSignature(sample);
  }

  int _deltaCountTolerance(int baselineCount) {
    final int total = max(0, baselineCount);
    if (total == 0) return 5;
    return max(20, (total * 0.035).round());
  }

  bool _canRunDeltaProbe({
    required SharedPreferences prefs,
    required int followersTotal,
    required int followingTotal,
  }) {
    final String accountUserId = _currentAccountUserId();
    if ((prefs.getString(_accountScopedKey(_analysisSnapshotVersionKey,
                    userId: accountUserId)) ??
                '')
            .trim() !=
        _analysisSnapshotVersionValue) {
      return false;
    }
    if (prefs.getBool(_accountScopedKey(_analysisBaselineReadyKey,
            userId: accountUserId)) !=
        true) return false;
    final int baselineFollowers = prefs.getInt(_accountScopedKey(
            _analysisBaselineFollowersTotalKey,
            userId: accountUserId)) ??
        -1;
    final int baselineFollowing = prefs.getInt(_accountScopedKey(
            _analysisBaselineFollowingTotalKey,
            userId: accountUserId)) ??
        -1;
    if (baselineFollowers < 0 || baselineFollowing < 0) {
      return false;
    }
    final int followersDiff = (baselineFollowers - followersTotal).abs();
    final int followingDiff = (baselineFollowing - followingTotal).abs();
    if (followersDiff > _deltaCountTolerance(baselineFollowers) ||
        followingDiff > _deltaCountTolerance(baselineFollowing)) {
      return false;
    }
    final String followersSig = (prefs.getString(_accountScopedKey(
                _analysisBaselineFollowersSigKey,
                userId: accountUserId)) ??
            '')
        .trim();
    final String followingSig = (prefs.getString(_accountScopedKey(
                _analysisBaselineFollowingSigKey,
                userId: accountUserId)) ??
            '')
        .trim();
    if (followersSig.isEmpty || followingSig.isEmpty) return false;

    final int? lastFullMs = prefs.getInt(
      _accountScopedKey(_analysisLastFullScanMsKey, userId: accountUserId),
    );
    if (lastFullMs == null) return false;
    final DateTime lastFull = DateTime.fromMillisecondsSinceEpoch(lastFullMs);
    if (DateTime.now().difference(lastFull) >= _deltaForceFullInterval) {
      return false;
    }
    return true;
  }

  Future<void> _persistFullAnalysisSnapshot(
    SharedPreferences prefs, {
    required int followersTotal,
    required int followingTotal,
    required Map<String, String> followersData,
    required Map<String, String> followingData,
  }) async {
    final String accountUserId = _currentAccountUserId();
    await _setAccountPrefString(
        prefs, _analysisSnapshotVersionKey, _analysisSnapshotVersionValue,
        userId: accountUserId);
    await _setAccountPrefInt(
        prefs, _analysisBaselineFollowersTotalKey, followersTotal,
        userId: accountUserId);
    await _setAccountPrefInt(
        prefs, _analysisBaselineFollowingTotalKey, followingTotal,
        userId: accountUserId);
    await _setAccountPrefString(
      prefs,
      _analysisBaselineFollowersSigKey,
      _buildHeadSignature(followersData),
      userId: accountUserId,
    );
    await _setAccountPrefString(
      prefs,
      _analysisBaselineFollowingSigKey,
      _buildHeadSignature(followingData),
      userId: accountUserId,
    );
    await _setAccountPrefInt(prefs, _analysisLastFullScanMsKey,
        DateTime.now().millisecondsSinceEpoch,
        userId: accountUserId);
    // Mark baseline as ready only after all snapshot data was written.
    await _setAccountPrefBool(prefs, _analysisBaselineReadyKey, true,
        userId: accountUserId);
  }

  Future<void> _persistFastNoChangeSnapshot(
    SharedPreferences prefs, {
    required int followersTotal,
    required int followingTotal,
    required Map<String, String> probeFollowers,
    required Map<String, String> probeFollowing,
  }) async {
    final String accountUserId = _currentAccountUserId();
    await _setAccountPrefString(
        prefs, _analysisSnapshotVersionKey, _analysisSnapshotVersionValue,
        userId: accountUserId);
    await _setAccountPrefInt(
        prefs, _analysisBaselineFollowersTotalKey, followersTotal,
        userId: accountUserId);
    await _setAccountPrefInt(
        prefs, _analysisBaselineFollowingTotalKey, followingTotal,
        userId: accountUserId);
    final String followersSig = _buildHeadSignature(probeFollowers);
    if (followersSig.isNotEmpty) {
      await _setAccountPrefString(
          prefs, _analysisBaselineFollowersSigKey, followersSig,
          userId: accountUserId);
    }

    final String followingSig = _buildHeadSignature(probeFollowing);
    if (followingSig.isNotEmpty) {
      await _setAccountPrefString(
          prefs, _analysisBaselineFollowingSigKey, followingSig,
          userId: accountUserId);
    }
    // Mark baseline as ready only after all snapshot data was written.
    await _setAccountPrefBool(prefs, _analysisBaselineReadyKey, true,
        userId: accountUserId);
  }

  void _scheduleIgVerificationGuide([String code = 'session_invalid']) {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastIgVerificationPromptAt;
    if (last != null && now.difference(last) < _igVerificationPromptCooldown) {
      return;
    }
    _lastIgVerificationPromptAt = now;
    unawaited(_showIgSecurityVerificationGuide(code));
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
      'Instagram DoÃ„Å¸rulamasÃ„Â± Gerekli',
      'Instagram Verification Required',
    );
    final String description = localizeTrEn(
      langCode,
      'Instagram hesabÃ„Â±nÃ„Â±z iÃƒÂ§in gÃƒÂ¼venlik doÃ„Å¸rulamasÃ„Â± gerekiyor (Ã…Å¸ÃƒÂ¼pheli giriÃ…Å¸ bildirimi / geÃƒÂ§ici kilit). Bu yÃƒÂ¼zden verileri ÃƒÂ§ekemiyoruz.',
      'Instagram requires a security verification for your account (suspicious login / temporary lock). We canÃ¢â‚¬â„¢t fetch data until itÃ¢â‚¬â„¢s verified.',
    );
    final String typeHint = isCheckpoint
        ? localizeTrEn(
            langCode,
            'Bu genelde Ã¢â‚¬Å“hesap kilidi / checkpointÃ¢â‚¬Â durumudur.',
            'This is usually an Ã¢â‚¬Å“account lock / checkpointÃ¢â‚¬Â.',
          )
        : localizeTrEn(
            langCode,
            'Bu genelde Ã¢â‚¬Å“Ã…Å¸ÃƒÂ¼pheli giriÃ…Å¸Ã¢â‚¬Â doÃ„Å¸rulamasÃ„Â±dÃ„Â±r.',
            'This is usually a Ã¢â‚¬Å“suspicious loginÃ¢â‚¬Â verification.',
          );
    final String steps = localizeTrEn(
      langCode,
      'Ne yapmaliyim?\n'
          '1) Instagram uygulamasÃ„Â±nÃ„Â± aÃƒÂ§Ã„Â±n.\n'
          '2) Ã¢â‚¬Å“Ã…ÂÃƒÂ¼pheli giriÃ…Å¸Ã¢â‚¬Â uyarÃ„Â±sÃ„Â± varsa Ã¢â‚¬Å“Bu bendimÃ¢â‚¬Â diyerek doÃ„Å¸rulayÃ„Â±n.\n'
          '3) Gerekirse Ã…Å¸ifrenizi deÃ„Å¸iÃ…Å¸tirip tekrar giriÃ…Å¸ yapÃ„Â±n.\n'
          '4) Bu uygulamaya dÃƒÂ¶nÃƒÂ¼p Ã¢â‚¬Å“VERÃ„Â°LERÃ„Â° GÃƒÅ“NCELLEÃ¢â‚¬Âye basÃ„Â±n.',
      'What to do:\n'
          '1) Open the Instagram app.\n'
          '2) If you see a Ã¢â‚¬Å“Suspicious loginÃ¢â‚¬Â alert, confirm itÃ¢â‚¬â„¢s you.\n'
          '3) If needed, change your password and log in again.\n'
          '4) Come back here and tap Ã¢â‚¬Å“REFRESH DATAÃ¢â‚¬Â.',
    );
    final String hint = localizeTrEn(
      langCode,
      'Not: DoÃ„Å¸rulama sonrasÃ„Â± bazen 1Ã¢â‚¬â€œ2 dakika beklemek gerekebilir.',
      'Note: After verification, you may need to wait 1Ã¢â‚¬â€œ2 minutes.',
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
              child: Text(localizeTrEn(
                  langCode, "Instagram'Ã„Â± AÃƒÂ§", 'Open Instagram')),
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
      'Instagram GeÃƒÂ§ici KÃ„Â±sÃ„Â±tlama',
      'Instagram Temporary Restriction',
    );
    final String description = localizeTrEn(
      langCode,
      'Instagram bu iÃ…Å¸lemi geÃƒÂ§ici olarak kÃ„Â±sÃ„Â±tladÃ„Â±. Bu genelde ÃƒÂ§ok sÃ„Â±k istek / otomatik aktivite algÃ„Â±landÃ„Â±Ã„Å¸Ã„Â±nda olur. Veri ÃƒÂ§ekme durduruldu.',
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
        : '${localizeTrEn(langCode, 'Instagram mesajÃ„Â±', 'Instagram message')}:\n$cleanIg';

    final String steps = localizeTrEn(
      langCode,
      'Ne yapabilirsin?\n'
          '1) Instagram uygulamasÃ„Â±nÃ„Â± aÃƒÂ§.\n'
          '2) Bir uyarÃ„Â±/ek doÃ„Å¸rulama varsa tamamla.\n'
          '3) 10Ã¢â‚¬â€œ30 dakika bekle.\n'
          '4) Bu uygulamaya dÃƒÂ¶nÃƒÂ¼p tekrar Ã¢â‚¬Å“VERÃ„Â°LERÃ„Â° GÃƒÅ“NCELLEÃ¢â‚¬Âye bas.',
      'What you can do:\n'
          '1) Open the Instagram app.\n'
          '2) Complete any alert or verification if shown.\n'
          '3) Wait 10Ã¢â‚¬â€œ30 minutes.\n'
          '4) Come back here and tap Ã¢â‚¬Å“REFRESH DATAÃ¢â‚¬Â again.',
    );

    final String hint = localizeTrEn(
      langCode,
      'Not: Arka arkaya ÃƒÂ§ok sÃ„Â±k analiz yapmak bu uyarÃ„Â±yÃ„Â± tetikleyebilir.',
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
              child: Text(localizeTrEn(
                  langCode, "Instagram'Ã„Â± AÃƒÂ§", 'Open Instagram')),
            ),
          ],
        ),
      );
    } finally {
      _igWarningVisible = false;
    }
  }

  String _buildAnalysisFailureDetails({
    required Object error,
    required StackTrace stackTrace,
    required String phase,
    required String endpoint,
  }) {
    final StringBuffer b = StringBuffer()
      ..writeln('VERDICT ANALYSIS FAILURE')
      ..writeln('time=${DateTime.now().toIso8601String()}')
      ..writeln('phase=${phase.isEmpty ? '(unknown)' : phase}')
      ..writeln('endpoint=${endpoint.isEmpty ? '(unknown)' : endpoint}')
      ..writeln('exception=${error.runtimeType}: $error')
      ..writeln('stackTrace:')
      ..writeln(stackTrace.toString());

    final List<String> recent = _igDiagnosticEvents.value.take(12).toList();
    if (recent.isNotEmpty) {
      b.writeln('recentIgEvents:');
      for (final String event in recent) {
        b.writeln('---');
        b.writeln(event);
      }
    }
    return b.toString().trim();
  }

  void _showAnalysisWarning(String reason, {String? details}) {
    if (!mounted) return;
    final String message =
        "${_t('analysis_failed_title')}\n${_t('analysis_failed_reason', {
          'reason': reason
        })}\n${_t('analysis_failed_hint')}";
    final String cleanDetails = (details ?? '').trim();
    final bool canSeeDiagnostics = _canOpenDiagnosticsConsole();

    if (!canSeeDiagnostics && cleanDetails.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('analysis_failed_reason', {
          'reason': _t('analysis_failed_hint'),
        })),
        duration: const Duration(seconds: 5),
        backgroundColor: _storySnackColor(tone: 'error'),
      ));
      return;
    }

    if (cleanDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: _storySnackColor(tone: 'error'),
      ));
      return;
    }

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'VERDICT ANALYSIS FAILURE',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(ctx).size.height * 0.58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      cleanDetails,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(
              ClipboardData(text: cleanDetails),
            ),
            child: const Text('KOPYALA'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Future.delayed(const Duration(milliseconds: 120), () {
                if (!mounted) return;
                unawaited(_openDiagnosticsConsole(initialTabIndex: 0));
              });
            },
            child: const Text('DEBUG LOG'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('KAPAT'),
          ),
        ],
      ),
    ));
  }

  Color _storySnackColor({String tone = 'info'}) {
    return _appSnackColorForTone(isDark: isDarkMode, tone: tone);
  }

  bool _isUserCausedAdFailure(Map<String, dynamic> adResult) {
    final String reason = (adResult['reason'] ?? '').toString().toLowerCase();
    final String error = (adResult['error'] ?? '').toString().toLowerCase();
    return reason.contains('user_cancel') ||
        reason.contains('cancelled_by_user') ||
        reason.contains('reward_not_earned') ||
        reason.contains('consent_denied') ||
        error.contains('user cancel') ||
        error.contains('cancelled by user');
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

  void _showStoryAdPendingSnackBar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text(_t('story_ad_wait')),
      duration: const Duration(seconds: 1),
      backgroundColor: _storySnackColor(),
    ));
  }

  Future<bool> _showStoryAdGate() async {
    return _showViewAdGate(
      incrementer: _incrementStoryWindowCount,
    );
  }

  Future<bool> _showPhotoAdGate() async {
    return _showViewAdGate(
      incrementer: _incrementPhotoWindowCount,
    );
  }

  Future<bool> _showViewAdGate({
    required Future<void> Function(SharedPreferences prefs, DateTime now)
        incrementer,
  }) async {
    if (_adsDisabled) return true;
    if (!mounted) return false;
    if (_isRewardedLoading) {
      _showStoryAdPendingSnackBar();
      return false;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();
    _showStoryAdPendingSnackBar();
    await Future.delayed(const Duration(milliseconds: 800));
    final adResult = await _showRewardedAdWithResult(
      adUnitOverride: Platform.isAndroid
          ? _storyRewardedAdUnitIdAndroid
          : _storyRewardedAdUnitIdIos,
    );
    if (adResult["status"] == false) {
      final String reason = (adResult["reason"] ?? '').toString().toLowerCase();
      if (reason == 'ad_busy') {
        _showStoryAdPendingSnackBar();
        return false;
      }
      final String adError = (adResult["error"] ?? '').toString().trim();
      if (adError.isNotEmpty) _setGoogleAdWarning(adError);
      final bool userCaused = _isUserCausedAdFailure(adResult);
      if (!userCaused) {
        _showStoryAdPendingSnackBar();
        await Future.delayed(const Duration(milliseconds: 1500));
        return true;
      }
      return false;
    }
    await incrementer(prefs, now);
    return true;
  }

  List<_StoryProfile> _getStoryProfiles() {
    if (isLoggedIn) {
      // Clear any cached placeholders when logged in.
      _cachedPlaceholderStories = null;
      final source = followingMap.isNotEmpty ? followingMap : followersMap;
      final List<MapEntry<String, String>> filteredSourceEntries =
          source.entries.where((e) {
        final String uname = e.key.trim();
        final String unameLower = uname.toLowerCase();
        final String? pk = _storyUserPks[unameLower];
        return !_isCurrentSessionUser(username: uname, userId: pk);
      }).toList(growable: false);

      final List<_StoryProfile> list = filteredSourceEntries.map((e) {
        final String unameLower = e.key.toLowerCase();
        final String normalizedPic = _normalizeHdProfileImageUrl(e.value);
        final String trayPic = _normalizeHdProfileImageUrl(
            (_storyUserPics[unameLower] ?? '').trim());
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

      final Set<String> seen =
          filteredSourceEntries.map((e) => e.key.toLowerCase()).toSet();
      int added = 0;
      for (final unameLower in _storyUsersWithActive) {
        if (seen.contains(unameLower)) continue;
        final String? pk = _storyUserPks[unameLower];
        if (_isCurrentSessionUser(username: unameLower, userId: pk)) continue;
        if (added >= 25) break;
        final String pic = _normalizeHdProfileImageUrl(
            (_storyUserPics[unameLower] ?? '').trim());
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

    // Not logged in: return a cached placeholder list so the UI doesn't
    // change length or order on every rebuild (prevents sudden jumps).
    if (_cachedPlaceholderStories != null) return _cachedPlaceholderStories!;
    final List<int> ids = List<int>.generate(20, (i) => i + 1);
    ids.shuffle(_storyRand);
    final String fakePrefix = _t('user_label');
    _cachedPlaceholderStories = ids.take(12).map((i) {
      return _StoryProfile(
          username: "${fakePrefix}_$i",
          imageUrl: "https://via.placeholder.com/150",
          isBlurred: true,
          hasStory: false);
    }).toList(growable: false);
    return _cachedPlaceholderStories!;
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
        headers: _profileImageRequestHeaders(profile.imageUrl),
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
      onTap: (isLoggedIn && !_isRewardedLoading)
          ? () => _handleStoryTap(profile)
          : null,
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
                    _lang, 'Hikayeler yÃƒÂ¼kleniyor...', 'Loading stories...'),
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
    if (_isRewardedLoading) {
      _showStoryAdPendingSnackBar();
      return;
    }
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
      final bool ok = await _showPhotoAdGate();
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
      final bool ok = await _showStoryAdGate();
      if (!ok) return;
      _openSecretStoryViewer(profile);
    }
  }

  String _normalizeProfileImageUrl(String url) {
    String normalized =
        url.trim().replaceAll(r'\u0026', '&').replaceAll('&amp;', '&');
    if (normalized.isEmpty) return normalized;
    try {
      final Uri? parsed = Uri.tryParse(normalized);
      if (parsed == null) return normalized;
      if (parsed.scheme.isEmpty || parsed.host.isEmpty) return normalized;
      String path = parsed.path;
      final String host = parsed.host.toLowerCase();
      if (host.contains('cdninstagram.com') ||
          host.contains('fbcdn.net') ||
          host.contains('instagram.com')) {
        // Older app versions injected "s2048x2048" before the extension.
        // Instagram CDN URLs are signed; changing the path makes them 404.
        path = path.replaceFirst(
          RegExp(r's\d{2,4}x\d{2,4}(?=\.(?:jpg|jpeg|png|webp)(?:$|[?#]))',
              caseSensitive: false),
          '',
        );
      }
      return parsed.replace(path: path).toString();
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

  List<String> _buildUltraProfileImageCandidates(String rawUrl) {
    final Set<String> results = <String>{};

    void addCandidate(String candidate) {
      final String normalized = _normalizeProfileImageUrl(candidate);
      if (normalized.isNotEmpty) results.add(normalized);
    }

    addCandidate(rawUrl);
    final String normalized = _normalizeProfileImageUrl(rawUrl);
    if (normalized.isEmpty) return results.toList(growable: false);

    try {
      final Uri? parsed = Uri.tryParse(normalized);
      if (parsed == null || parsed.host.isEmpty) {
        return results.toList(growable: false);
      }

      final Map<String, String> query =
          Map<String, String>.from(parsed.queryParameters);

      if (query.containsKey('stp')) {
        final Map<String, String> withoutStp = Map<String, String>.from(query);
        withoutStp.remove('stp');
        final Map<String, String>? cleaned =
            withoutStp.isEmpty ? null : withoutStp;
        addCandidate(parsed.replace(queryParameters: cleaned).toString());
      }
    } catch (_) {}

    return results.toList(growable: false);
  }

  Map<String, String>? _profileImageRequestHeaders(String rawUrl) {
    final String cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) return null;
    final Map<String, String> headers = <String, String>{
      'User-Agent': _resolveUserAgent(),
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'Referer': 'https://www.instagram.com/',
    };
    try {
      final Uri? uri = Uri.tryParse(cleanUrl);
      final String host = uri?.host.toLowerCase() ?? '';
      final bool firstPartyHost =
          host == 'instagram.com' || host.endsWith('.instagram.com');
      final String cookie = (savedCookie ?? '').trim();
      if (firstPartyHost && cookie.isNotEmpty) {
        headers['Cookie'] = cookie;
      }
    } catch (_) {}
    return headers;
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

    final String profilePic =
        (userNode['profile_pic_url'] ?? '').toString().trim();
    if (profilePic.isNotEmpty) candidates.add(profilePic);

    for (final String raw in candidates) {
      final String normalized = _normalizeHdProfileImageUrl(raw);
      if (normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  String? _extractUserIdFromWebProfilePayload(dynamic payload) {
    if (payload is! Map) return null;

    final dynamic userNode = payload['user'] ??
        (payload['data'] is Map ? payload['data']['user'] : null);

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

  Map<dynamic, dynamic>? _resolveStoryMediaNode(dynamic node, {int depth = 0}) {
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
    final String cacheKey = ((profile.pk ?? '').trim().isNotEmpty)
        ? 'pk:${profile.pk!.trim()}'
        : 'un:${profile.username.trim().toLowerCase()}';
    final String cachedUrl = (_hdProfilePhotoCache[cacheKey] ?? '').trim();
    if (cachedUrl.isNotEmpty) return cachedUrl;

    final String? resolved = await _fetchHdProfilePhotoUrlNetwork(profile);
    if (resolved != null && resolved.isNotEmpty) {
      _hdProfilePhotoCache[cacheKey] = resolved;
    }
    return resolved;
  }

  Future<String?> _fetchHdProfilePhotoUrlNetwork(
      _StoryProfile profile) async {
    final String cookie = (savedCookie ?? '').trim();
    if (cookie.isEmpty) return null;
    final String ua = _resolveUserAgent();
    final String appUa = _resolveAppUserAgent(ua);
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
            minGap: const Duration(seconds: 2),
            jitterMaxMs: 1500,
          );
          if (response.statusCode != 200) return null;
          final dynamic parsed = jsonDecode(_safeResponseBody(response));
          if (parsed is! Map) return null;
          final dynamic userNode = parsed['user'] ??
              (parsed['data'] is Map ? parsed['data']['user'] : null);
          return _extractBestProfilePhotoUrlFromUser(userNode);
        } catch (_) {
          return null;
        }
      }

      final Uri webUri = Uri.parse(
          "https://www.instagram.com/api/v1/users/$cleanUserId/info/");

      // Force web-only attempts
      final List<Future<String?> Function()> attempts = [
        () => fetchInfo(
              uri: webUri,
              headers: _buildWebHeaders(cookie, ua,
                  dsUserId: sessionDsUserId, igWwwClaim: _igWwwClaimToken),
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
        "https://www.instagram.com/api/v1/users/$safe/username_info/");

    Future<String?> fetchByUsername({
      required Uri uri,
      required Map<String, String> headers,
    }) async {
      try {
        final response = await _igGet(
          uri,
          headers: headers,
          minGap: const Duration(seconds: 2),
          jitterMaxMs: 1500,
          debugLabel: 'fetchHdProfilePhotoUrl.byUsername',
        );
        if (response.statusCode != 200) return null;
        final dynamic parsed = jsonDecode(_safeResponseBody(response));
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
                  headers: _buildWebHeaders(cookie, ua,
                      dsUserId: sessionDsUserId, igWwwClaim: _igWwwClaimToken),
                ),
            () => fetchByUsername(
                  uri: Uri.parse(
                      "https://www.instagram.com/api/v1/users/$safe/username_info/"),
                  headers: _buildWebHeaders(cookie, ua,
                      dsUserId: sessionDsUserId, igWwwClaim: _igWwwClaimToken),
                ),
          ]
        : [
            () => fetchByUsername(
                  uri: appProfileUri,
                  headers: _buildAppHeaders(cookie, appUa,
                      dsUserId: sessionDsUserId, igWwwClaim: _igWwwClaimToken),
                ),
            () => fetchByUsername(
                  uri: webProfileUri,
                  headers: _buildWebHeaders(cookie, ua,
                      dsUserId: sessionDsUserId, igWwwClaim: _igWwwClaimToken),
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
    final String fallbackUrl = _normalizeHdProfileImageUrl(profile.imageUrl);
    final Set<String> candidateSet = <String>{};

    for (final String candidate in _buildUltraProfileImageCandidates(url)) {
      candidateSet.add(candidate);
    }
    for (final String candidate
        in _buildUltraProfileImageCandidates(fallbackUrl)) {
      candidateSet.add(candidate);
    }

    if (mounted) Navigator.pop(context);

    if (!mounted) return;

    final List<String> candidates = candidateSet
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (candidates.isEmpty) return;

    final Map<String, String>? requestHeaders =
        _profileImageRequestHeaders(candidates.first);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ProfilePhotoFullscreenViewer(
        imageCandidates: candidates,
        closeLabel: _t('story_close'),
        headers: requestHeaders,
      ),
    );
  }

  Future<String?> _getUserId(String username) async {
    final String key = username.toLowerCase();
    final String cached = (_storyUserPks[key] ?? '').trim();
    if (cached.isNotEmpty) return cached;

    final String cookie = (savedCookie ?? '').trim();
    if (cookie.isEmpty) return null;

    final String ua = _resolveUserAgent();
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
          minGap: const Duration(milliseconds: 280),
          jitterMaxMs: 210,
          debugLabel: 'getUserId.webProfileInfo',
        );
        if (response.statusCode != 200) {
          _lastIgWarning = _extractIgWarning(_safeResponseBody(response));
          return null;
        }
        final dynamic data = jsonDecode(_safeResponseBody(response));
        return _extractUserIdFromWebProfilePayload(data);
      } catch (_) {
        return null;
      }
    }

    final Uri webUri = Uri.parse(
        "https://www.instagram.com/api/v1/users/web_profile_info/?username=$safe");
    // appUri removed; web-only approach enforced

    // Force web-only attempts for user id resolution
    final List<Future<String?> Function()> attempts = [
      () => fetchId(
            uri: webUri,
            headers: _buildWebHeaders(cookie, ua,
                dsUserId: sessionDsUserId, igWwwClaim: _igWwwClaimToken),
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
    _storyRequiresSecurityVerification = false;
    final String cookie = (savedCookie ?? '').trim();
    if (cookie.isEmpty) return const [];
    final String ua = _resolveUserAgent();
    final String? dsUserHeader =
        _resolveSessionDsUserId(savedUserId, savedCookie);

    final Map<String, String> webHeaders = _buildWebHeaders(cookie, ua,
        dsUserId: dsUserHeader, igWwwClaim: _igWwwClaimToken);

    final Uri reelsMediaWeb = Uri.parse(
        "https://www.instagram.com/api/v1/feed/reels_media/?reel_ids=$targetUserId");
    final Uri reelMediaWeb = Uri.parse(
        "https://www.instagram.com/api/v1/feed/user/$targetUserId/reel_media/");
    final Uri reelsTrayWeb =
        Uri.parse("https://www.instagram.com/api/v1/feed/reels_tray/");

    // Force web-only attempts to keep a single consistent identity
    final List<Map<String, dynamic>> attempts = [
      {'uri': reelsMediaWeb, 'headers': webHeaders},
      {'uri': reelMediaWeb, 'headers': webHeaders},
      {'uri': reelsTrayWeb, 'headers': webHeaders},
    ];

    for (final Map<String, dynamic> attempt in attempts) {
      try {
        final http.Response response = await _igGet(
          attempt['uri'] as Uri,
          headers: attempt['headers'] as Map<String, String>,
          minGap: const Duration(seconds: 2),
          jitterMaxMs: 1500,
          debugLabel: 'fetchStoryItems.$targetUserId',
        );
        if (response.statusCode != 200) {
          final String? security =
              _detectIgSecurityBlockFromText(_safeResponseBody(response));
          if (security != null) {
            _storyRequiresSecurityVerification = true;
            _lastIgWarning = localizeTrEn(
              _lang,
              'Instagram gÃƒÂ¼venlik doÃ„Å¸rulamasÃ„Â± gerekiyor (hikaye verisi alÃ„Â±namadÃ„Â±).',
              'Instagram security verification is required (story data could not be fetched).',
            );
          }
          final String? warning = _detectIgWarningFromText(_safeResponseBody(response));
          if (warning != null && warning.trim().isNotEmpty) {
            _lastIgWarning = warning.trim();
          }
          continue;
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(_safeResponseBody(response));
        } catch (_) {
          decoded = null;
        }

        if (decoded is Map) {
          final String? security = _detectIgSecurityBlockFromMap(decoded);
          if (security != null) {
            _storyRequiresSecurityVerification = true;
            _lastIgWarning = localizeTrEn(
              _lang,
              'Instagram gÃƒÂ¼venlik doÃ„Å¸rulamasÃ„Â± gerekiyor (hikaye verisi alÃ„Â±namadÃ„Â±).',
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
            ? _extractStoryItemsFromPayload(_safeResponseBody(response), targetUserId)
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
        final Map<dynamic, dynamic>? mediaNode =
            _resolveStoryMediaNode(rawItem);
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
            final String displayUrl =
                (node['display_url'] ?? '').toString().trim();
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: _storySnackColor(tone: 'error')));
        }
        return;
      }

      final List<StoryItem> stories = await _fetchStoryItems(targetId);

      if (mounted) Navigator.pop(context);

      if (stories.isEmpty) {
        if (_storyRequiresSecurityVerification) {
          _scheduleIgVerificationGuide('session_invalid');
        }
        final String warning = (_lastIgWarning ?? '').trim();
        final String message = warning.isNotEmpty
            ? warning
            : (profile.hasStory
                ? localizeTrEn(
                    _lang,
                    'Hikaye verisi alÃ„Â±namadÃ„Â±. Bu durum genelde Instagram doÃ„Å¸rulamasÃ„Â±, geÃƒÂ§ici API kÃ„Â±sÃ„Â±tÃ„Â± veya baÃ„Å¸lantÃ„Â± kesintisinden kaynaklanÃ„Â±r. 2-3 dakika sonra tekrar deneyin.',
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
        final String modeLabel = _t('secret_mode_label');

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
              'Hikaye yÃƒÂ¼kleme baÃ„Å¸lantÃ„Â± kesintisi nedeniyle durdu. LÃƒÂ¼tfen tekrar deneyin.',
              'Story loading stopped due to a network interruption. Please try again.',
            )
          : localizeTrEn(
              _lang,
              'Hikaye verisi alÃ„Â±namadÃ„Â±. LÃƒÂ¼tfen biraz sonra tekrar deneyin.',
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

  @override
  void dispose() {
    final Completer<void>? pendingResume = _resumeCompleter;
    _resumeCompleter = null;
    if (pendingResume != null && !pendingResume.isCompleted) {
      pendingResume.complete();
    }
    PurchasesService.instance.isPremium.removeListener(_onPremiumChanged);
    PurchasesService.instance.lastPurchaseError
        .removeListener(_onPurchaseErrorChanged);
    WidgetsBinding.instance.removeObserver(this);
    _cancelCountdown();
    _cancelLegalHoldTimer();
    _consentWatchTimer?.cancel();
    _bannerRetryTimer?.cancel();
    _headerBannerRetryTimer?.cancel();
    _entryInterstitialPrefetchRetryTimer?.cancel();
    _entryInterstitialPrefetchTimeoutTimer?.cancel();
    _ownerFcmTokenRefreshSub?.cancel();
    _isBannerLoadInFlight = false;
    _isHeaderBannerLoadInFlight = false;
    _isEntryInterstitialPreloadInFlight = false;
    _storyAutoTimer?.cancel();
    _stopProgressPump();
    _stopAnalysisProgressTimeline();
    _storyScrollController.dispose();
    _firebaseDiagnosticEvents.dispose();
    _recentFirebaseAnalysisRows.dispose();
    _entryInterstitialAd?.dispose();
    _bannerAd?.dispose();
    _headerBannerAd?.dispose();
    _httpClient.close();
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
      await prefs.remove(_accountScopedKey('last_update_time'));
      _startCountdownFromStoredTime();
      _bannerRetryTimer?.cancel();
      _bannerRetryTimer = null;
      _consentWatchTimer?.cancel();
      _consentWatchTimer = null;
      _isBannerLoadInFlight = false;
      _bannerAd?.dispose();
      if (!_debugPinUnlocked) {
        _debugPinUnlocked = true;
        try {
          await prefs.setBool(_debugPinUnlockedPrefKey, true);
        } catch (_) {}
      }
      if (mounted)
        setState(() {
          _adsHidden = true;
          _bannerAd = null;
          _isAdLoaded = false;
        });
      unawaited(_openDiagnosticsConsole(initialTabIndex: 0));
    }
  }

  String _legalSummaryForLang(String raw) {
    final String code = _normalizedUiLanguageCode(raw);
    final String resolvedCode = (_supportedLanguageCodesGlobal.contains(code) ||
            _legalWarningSummaryLabels.containsKey(code))
        ? code
        : 'en';
    return localizedPrivacyPolicyBody(resolvedCode);
  }

  // ignore: unused_element
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
            onPressed: _openAppleEula,
            child: const Text(
              'EULA',
              style: TextStyle(fontSize: 11),
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
}

class _ProfilePhotoFullscreenViewer extends StatefulWidget {
  final List<String> imageCandidates;
  final String closeLabel;
  final Map<String, String>? headers;

  const _ProfilePhotoFullscreenViewer({
    required this.imageCandidates,
    required this.closeLabel,
    this.headers,
  });

  @override
  State<_ProfilePhotoFullscreenViewer> createState() =>
      _ProfilePhotoFullscreenViewerState();
}

class _ProfilePhotoFullscreenViewerState
    extends State<_ProfilePhotoFullscreenViewer> {
  final TransformationController _zoomController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  int _activeCandidate = 0;
  bool _fallbackScheduled = false;

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  void _scheduleFallbackCandidate() {
    if (_fallbackScheduled) return;
    if (_activeCandidate >= widget.imageCandidates.length - 1) return;
    _fallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _activeCandidate++;
        _fallbackScheduled = false;
        _resetZoom();
      });
    });
  }

  void _handleDoubleTap() {
    final TapDownDetails? tap = _doubleTapDetails;
    if (tap == null) return;
    final bool isZoomed = _zoomController.value.getMaxScaleOnAxis() > 1.05;
    if (isZoomed) {
      _resetZoom();
      return;
    }
    const double scale = 2.2;
    final Offset position = tap.localPosition;
    _zoomController.value = Matrix4.identity()
      ..translate(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
      )
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    final String currentUrl = widget
        .imageCandidates[_activeCandidate % widget.imageCandidates.length];

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _zoomController,
                  minScale: 0.95,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(120),
                  clipBehavior: Clip.none,
                  child: SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 18, 10, 64),
                      child: Center(
                        child: Image.network(
                          currentUrl,
                          fit: BoxFit.contain,
                          headers: widget.headers,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          gaplessPlayback: true,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              _fallbackScheduled = false;
                              return child;
                            }
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            _scheduleFallbackCandidate();
                            if (_activeCandidate <
                                widget.imageCandidates.length - 1) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white));
                            }
                            return const Icon(
                              Icons.broken_image,
                              color: Colors.white70,
                              size: 80,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                iconSize: 28,
                splashRadius: 22,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  widget.closeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
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
  bool _isMuted = false;

  void _goNext() {
    if (!_pageController.hasClients) return;
    if (_currentIndex >= widget.stories.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _goPrevious() {
    if (!_pageController.hasClients) return;
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                final double screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx > screenWidth / 2) {
                  _goNext();
                } else {
                  _goPrevious();
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
                  final StoryItem story = widget.stories[index];
                  return _StoryItemView(
                    story: story,
                    isActive: index == _currentIndex,
                    isMuted: _isMuted,
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.64),
                      Colors.black.withOpacity(0.22),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(widget.stories.length, (index) {
                      final bool isPast = index < _currentIndex;
                      final bool isCurrent = index == _currentIndex;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            height: isCurrent ? 3.6 : 3.0,
                            decoration: BoxDecoration(
                              color: isPast || isCurrent
                                  ? Colors.white
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
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
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.visibility_off_rounded,
                            color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              widget.modeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.74),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isMuted = !_isMuted;
                          });
                        },
                        icon: Icon(_isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded),
                        color: Colors.white,
                        iconSize: 24,
                        splashRadius: 20,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                        iconSize: 28,
                        splashRadius: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                side: const BorderSide(color: Colors.white30),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.closeLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryItemView extends StatefulWidget {
  final StoryItem story;
  final bool isActive;
  final bool isMuted;

  const _StoryItemView({
    required this.story,
    required this.isActive,
    required this.isMuted,
  });

  @override
  State<_StoryItemView> createState() => _StoryItemViewState();
}

class _StoryItemViewState extends State<_StoryItemView> {
  WebViewController? _videoController;
  bool _isVideoInitialized = false;

  Future<void> _syncVideoAudioIfNeeded() async {
    if (!widget.story.isVideo || _videoController == null) return;
    final String mutedJs = widget.isMuted ? 'true' : 'false';
    final String volumeJs = widget.isMuted ? '0.0' : '1.0';
    try {
      await _videoController!.runJavaScript('''
        (function() {
          var v = document.querySelector('video');
          if (!v) return;
          try {
            v.defaultMuted = $mutedJs;
            v.muted = $mutedJs;
            v.volume = $volumeJs;
            if ($mutedJs) {
              v.setAttribute('muted', 'muted');
            } else {
              v.removeAttribute('muted');
            }
          } catch (e) {}
        })();
      ''');
    } catch (_) {}
  }

  Future<void> _playVideoIfNeeded() async {
    if (!widget.story.isVideo || _videoController == null) return;
    await _syncVideoAudioIfNeeded();
    try {
      await _videoController!.runJavaScript('''
        (function() {
          var v = document.querySelector('video');
          if (v) {
            try {
              v.playsInline = true;
              v.play();
            } catch (e) {}
          }
        })();
      ''');
    } catch (_) {}
  }

  Future<void> _pauseVideoIfNeeded() async {
    if (!widget.story.isVideo || _videoController == null) return;
    try {
      await _videoController!.runJavaScript('''
        (function() {
          var v = document.querySelector('video');
          if (v) {
            try { v.pause(); } catch (e) {}
          }
        })();
      ''');
    } catch (_) {}
  }

  Future<void> _clearVideoSurfaceIfNeeded() async {
    if (!widget.story.isVideo || _videoController == null) return;
    try {
      await _videoController!.loadHtmlString('''
        <!DOCTYPE html>
        <html><body style="margin:0;background:black;"></body></html>
      ''');
    } catch (_) {}
  }

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
              if (mounted) {
                setState(() {
                  _isVideoInitialized = true;
                });
              }
              unawaited(_syncVideoAudioIfNeeded());
              if (widget.isActive) {
                unawaited(_playVideoIfNeeded());
              } else {
                unawaited(_pauseVideoIfNeeded());
              }
            },
          ),
        )
        ..loadHtmlString('''
          <!DOCTYPE html>
          <html>
          <body style="margin:0;padding:0;background-color:black;display:flex;align-items:center;justify-content:center;height:100vh;">
            <video width="100%" height="100%" autoplay playsinline webkit-playsinline preload="auto" name="media">
              <source src="${widget.story.url}" type="video/mp4">
            </video>
          </body>
          </html>
        ''');

      _videoController = controller;
    }
  }

  @override
  void didUpdateWidget(covariant _StoryItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.story.isVideo || _videoController == null) return;
    final bool activeChanged = oldWidget.isActive != widget.isActive;
    final bool muteChanged = oldWidget.isMuted != widget.isMuted;

    if (muteChanged) {
      unawaited(_syncVideoAudioIfNeeded());
    }

    if (activeChanged || (muteChanged && widget.isActive)) {
      if (widget.isActive) {
        unawaited(_playVideoIfNeeded());
      } else {
        unawaited(_pauseVideoIfNeeded());
      }
    }
  }

  @override
  void deactivate() {
    if (widget.story.isVideo) {
      unawaited(_pauseVideoIfNeeded());
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (widget.story.isVideo) {
      unawaited(_pauseVideoIfNeeded());
      unawaited(_clearVideoSurfaceIfNeeded());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.isVideo) {
      final WebViewController? controller = _videoController;
      if (controller == null) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      }
      return Stack(
        children: [
          if (!_isVideoInitialized)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          Offstage(
            offstage: !_isVideoInitialized,
            child: IgnorePointer(
              ignoring: true,
              child: WebViewWidget(controller: controller),
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
            filterQuality: FilterQuality.high,
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

class DetailListPage extends StatefulWidget {
  final String title;
  final Map<String, String> items;
  final Color color;
  final bool isDark;
  final Set<String> newItems;
  final String lang;
  final bool adsDisabled;

  const DetailListPage({
    super.key,
    required this.title,
    required this.items,
    required this.color,
    required this.isDark,
    required this.newItems,
    required this.lang,
    required this.adsDisabled,
  });

  @override
  State<DetailListPage> createState() => _DetailListPageState();
}

class _DetailListPageState extends State<DetailListPage> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    await _waitForAdConsentFlow();
    if (!await _adConsentFlow.canRequestAds() || !mounted) return;
    if (widget.adsDisabled) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerLoaded = false;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool premium = prefs.getBool('is_premium') ?? false;
    final bool removeAllAds = prefs.getBool('remove_all_ads') ?? false;
    final bool isAdmin = prefs.getBool('is_admin_user') ?? false;

    if (premium || removeAllAds || isAdmin) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerLoaded = false;
      return;
    }

    final String adUnit = Platform.isAndroid
        ? 'ca-app-pub-7480771330660307/9017777173'
        : 'ca-app-pub-7480771330660307/9017777173';
    final bool useNpa = await shouldUseNonPersonalizedAdsGlobal();

    _bannerAd = BannerAd(
      adUnitId: adUnit,
      size: AdSize.banner,
      request: AdRequest(nonPersonalizedAds: useNpa),
      listener: BannerAdListener(onAdLoaded: (_) {
        if (mounted && !widget.adsDisabled) {
          setState(() => _isBannerLoaded = true);
        }
      }, onAdFailedToLoad: (ad, error) {
        debugPrint(
            '[DetailBanner] failed: code=${error.code}, message=${error.message}');
        ad.dispose();

        if (mounted) {
          setState(() {
            _isBannerLoaded = false;
            _bannerAd = null;
          });
        }

        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && !widget.adsDisabled) {
            _loadBanner();
          }
        });
      }),
    );

    await _bannerAd?.load();
  }

  Future<void> _openProfile(String username) async {
    final Uri url = Uri.parse('https://instagram.com/$username');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: username));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> names = widget.items.keys.toList();
    final Color itemTextColor = widget.isDark ? Colors.white : Colors.black87;
    final Color bgColor = widget.isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.isDark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: widget.isDark ? Colors.white : Colors.black,
      ),
      body: Column(
        children: [
          if (!widget.adsDisabled && _isBannerLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              margin: const EdgeInsets.only(bottom: 5, top: 5),
              child: AdWidget(ad: _bannerAd!),
            ),
          Expanded(
            child: widget.items.isEmpty
                ? Center(
                    child: Text(
                      localizeTrEn(widget.lang, 'Veri yok', 'No data'),
                      style: TextStyle(color: itemTextColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: names.length,
                    itemBuilder: (ctx, i) {
                      final String username = names[i];
                      final bool isNew = widget.newItems.contains(username);
                      final String imageUrl =
                          (widget.items[username] ?? '').trim();
                      final Widget avatar = imageUrl.isEmpty
                          ? Container(
                              width: 40,
                              height: 40,
                              color: widget.isDark
                                  ? Colors.white12
                                  : Colors.black12,
                              child: Icon(
                                Icons.person,
                                color: widget.isDark
                                    ? Colors.white70
                                    : Colors.black45,
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stack) =>
                                  Container(
                                width: 40,
                                height: 40,
                                color: widget.isDark
                                    ? Colors.white12
                                    : Colors.black12,
                                child: Icon(
                                  Icons.person,
                                  color: widget.isDark
                                      ? Colors.white70
                                      : Colors.black45,
                                ),
                              ),
                            );
                      return ListTile(
                        onTap: () => _openProfile(username),
                        leading: ClipOval(child: avatar),
                        title: Row(
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: itemTextColor,
                              ),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  localizeTrEn(widget.lang, 'YENI', 'NEW'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ]
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: _detailOpenProfileTextForLang(widget.lang),
                          onPressed: () => _openProfile(username),
                          icon: Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: itemTextColor.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
  bool _sessionProbeBusy = false;
  bool _loginResultReturned = false;
  Timer? _sessionProbeTimer;
  DateTime? _lastSessionProbeStartedAt;
  DateTime? _lastLoginErrorAt;
  final Random _loginProbeRandom = Random();
  static const Duration _sessionProbeDebounceDelay =
      Duration(milliseconds: 900);
  static const Duration _sessionProbeMinInterval = Duration(seconds: 3);
  static const Duration _loginSessionSettleBaseDelay = Duration(seconds: 2);
  static const int _loginSessionSettleJitterMs = 2000;
  static const Duration _loginErrorMinInterval = Duration(seconds: 8);

  void _showLoginError(String trText, String enText) {
    if (!mounted) return;
    final DateTime now = DateTime.now();
    final DateTime? last = _lastLoginErrorAt;
    if (last != null && now.difference(last) < _loginErrorMinInterval) return;
    _lastLoginErrorAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (change) {
            _queueSessionProbe(change.url ?? '');
          },
          onPageFinished: (url) {
            _queueSessionProbe(url);
          },
        ),
      );
    // Eski oturum izlerini temizleyerek taze bir baÃ…Å¸langÃ„Â±ÃƒÂ§ yap.
    unawaited(_clearInstagramWebSessionStorage());
    _controller
        .loadRequest(Uri.parse('https://www.instagram.com/accounts/login/'));
  }

  @override
  void dispose() {
    _sessionProbeTimer?.cancel();
    super.dispose();
  }

  bool _shouldProbeSessionFromUrl(String rawUrl) {
    if (rawUrl.trim().isEmpty) return false;
    final Uri? uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return false;
    final String host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    return host == 'instagram.com' ||
        host.endsWith('.instagram.com') ||
        host == 'facebook.com' ||
        host.endsWith('.facebook.com');
  }

  bool _isLoginOrSecurityUrl(String rawUrl) {
    final Uri? uri = Uri.tryParse(rawUrl.trim());
    final String path =
        (uri?.path ?? rawUrl).replaceAll('\\', '/').toLowerCase();
    // NOTE: /accounts/onetap is Instagram's "Save your login info?" prompt.
    // It only ever renders once the session is already authenticated
    // (cookies are already set at that point), so it is intentionally NOT
    // included here. Treating it as a login/security obstacle rejected
    // otherwise-successful fresh logins whenever the account.current_user
    // API validation call happened to fail (e.g. while Instagram was
    // temporarily rate-limiting that specific endpoint).
    return path.contains('/accounts/login') ||
        path.contains('/accounts/signup') ||
        path.contains('/challenge') ||
        path.contains('/checkpoint') ||
        path.contains('/two_factor') ||
        path.contains('/consent');
  }

  void _queueSessionProbe(String rawUrl) {
    if (!_shouldProbeSessionFromUrl(rawUrl)) return;
    if (!mounted || isScanning || _sessionProbeBusy || _loginResultReturned) {
      return;
    }
    _sessionProbeTimer?.cancel();
    _sessionProbeTimer = Timer(_sessionProbeDebounceDelay, () {
      if (!mounted || _loginResultReturned) return;
      unawaited(_probeSessionAndStartIfReady(rawUrl));
    });
  }

  Future<String> _currentWebViewUrlOr(String fallback) async {
    try {
      final String? current = await _controller.currentUrl();
      final String clean = (current ?? '').trim();
      if (clean.isNotEmpty) return clean;
    } catch (_) {}
    return fallback.trim();
  }

  bool _canAcceptCookieBackedSession({
    required String cookie,
    required String userId,
    required String visibleUrl,
  }) {
    final String sessionId = _extractCookieValue(cookie, 'sessionid').trim();
    return sessionId.isNotEmpty &&
        userId.trim().isNotEmpty &&
        !_isLoginOrSecurityUrl(visibleUrl);
  }

  void _returnLoginSuccess({
    required String cookie,
    required String userId,
    required String username,
    required String userAgent,
  }) {
    if (!mounted || _loginResultReturned) return;
    _loginResultReturned = true;
    _sessionProbeTimer?.cancel();
    Navigator.pop(context, {
      "status": "success",
      "cookie": cookie,
      "user_id": userId.trim(),
      "username": username.trim().isNotEmpty
          ? username.trim()
          : localizeTrEn(widget.lang, "Kullanici", "User"),
      "user_agent": userAgent,
    });
  }

  Future<void> _probeSessionAndStartIfReady(String rawUrl) async {
    if (!_shouldProbeSessionFromUrl(rawUrl)) return;
    if (!mounted || isScanning || _sessionProbeBusy || _loginResultReturned) {
      return;
    }

    _sessionProbeBusy = true;
    try {
      final String? cookieString = await platform.invokeMethod<String>(
          'getCookies', {'url': 'https://www.instagram.com/'});
      final String cookie = (cookieString ?? '').trim();
      if (cookie.isEmpty) return;

      final String sessionId = _extractCookieValue(cookie, 'sessionid').trim();
      if (sessionId.isEmpty) return;
      final DateTime now = DateTime.now();
      final DateTime? lastStarted = _lastSessionProbeStartedAt;
      if (lastStarted != null &&
          now.difference(lastStarted) < _sessionProbeMinInterval) {
        return;
      }
      _lastSessionProbeStartedAt = now;

      final Duration settleDelay = _loginSessionSettleBaseDelay +
          Duration(
              milliseconds: _loginProbeRandom.nextInt(
            _loginSessionSettleJitterMs + 1,
          ));
      await Future.delayed(settleDelay);
      if (!mounted || isScanning || _loginResultReturned) return;
      await _startSafeApiProcess(rawUrl: rawUrl);
    } catch (_) {
      // Silent probe failures are expected during multi-step web login flows.
    } finally {
      _sessionProbeBusy = false;
    }
  }

  Future<void> _startSafeApiProcess({String rawUrl = ''}) async {
    if (!mounted || _loginResultReturned) return;
    setState(() => isScanning = true);
    try {
      final String? cookieString = await platform
          .invokeMethod('getCookies', {'url': "https://www.instagram.com/"});
      if (cookieString == null || cookieString.trim().isEmpty) {
        if (mounted) setState(() => isScanning = false);
        _showLoginError(
          'Ãƒâ€¡erez alÃ„Â±namadÃ„Â±. LÃƒÂ¼tfen tekrar giriÃ…Å¸ yapÃ„Â±n.',
          'Could not read cookies. Please log in again.',
        );
        return;
      }
      final String dsUserId =
          _extractCookieValue(cookieString, 'ds_user_id').trim();
      String? resolvedUserId = dsUserId.isNotEmpty ? dsUserId : null;
      final String sessionId =
          _extractCookieValue(cookieString, 'sessionid').trim();
      if ((resolvedUserId == null || resolvedUserId.isEmpty) &&
          sessionId.isNotEmpty) {
        final String sessionUserId = _extractIgUserIdFromSessionId(sessionId);
        if (sessionUserId.isNotEmpty) resolvedUserId = sessionUserId;
      }
      final String visibleUrl = await _currentWebViewUrlOr(rawUrl);
      if (sessionId.isEmpty) {
        if (mounted) setState(() => isScanning = false);
        _showLoginError(
          'Oturum ÃƒÂ§erezi eksik. LÃƒÂ¼tfen Instagram giriÃ…Å¸ini tekrar yapÃ„Â±n.',
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
        userAgent = _canonicalPlatformUserAgent();
      }
      try {
        final Stopwatch loginProbeWatch = Stopwatch()..start();
        final infoResponse = await http.get(
            Uri.parse(
                "https://www.instagram.com/api/v1/accounts/current_user/?edit=true"),
            headers: _buildWebHeaders(cookieString, userAgent,
                igWwwClaim: _igWwwClaimToken));
        loginProbeWatch.stop();
        _logIgDiagnosticEntry(
          'login_probe',
          'current_user session validation completed',
          label: 'InstagramApiPage.current_user',
          uri: Uri.parse(
              'https://www.instagram.com/api/v1/accounts/current_user/?edit=true'),
          statusCode: infoResponse.statusCode,
          elapsed: loginProbeWatch.elapsed,
          responseBody: infoResponse.body,
        );
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
            'Oturum bilgisi alÃ„Â±namadÃ„Â±. LÃƒÂ¼tfen Instagram giriÃ…Å¸ini tekrar yapÃ„Â±n.',
            'Session data is missing. Please log in to Instagram again.',
          );
          return;
        }
        try {
          final Stopwatch loginFallbackWatch = Stopwatch()..start();
          final appInfoResponse = await http.get(
            Uri.parse(
                "https://www.instagram.com/api/v1/users/$targetUserId/info/"),
            headers: _buildWebHeaders(cookieString, userAgent,
                dsUserId: targetUserId, igWwwClaim: _igWwwClaimToken),
          );
          loginFallbackWatch.stop();
          _logIgDiagnosticEntry(
            'login_probe',
            'user info fallback validation completed',
            label: 'InstagramApiPage.user_info',
            uri: Uri.parse(
                'https://www.instagram.com/api/v1/users/$targetUserId/info/'),
            statusCode: appInfoResponse.statusCode,
            elapsed: loginFallbackWatch.elapsed,
            responseBody: appInfoResponse.body,
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
        final String fallbackUserId = (resolvedUserId ?? dsUserId).trim();
        if (_canAcceptCookieBackedSession(
          cookie: cookieString,
          userId: fallbackUserId,
          visibleUrl: visibleUrl,
        )) {
          _returnLoginSuccess(
            cookie: cookieString,
            userId: fallbackUserId,
            username: username ?? '',
            userAgent: userAgent,
          );
          return;
        }
        if (mounted) setState(() => isScanning = false);
        _showLoginError(
          'Oturum doÃ„Å¸rulanamadÃ„Â±. LÃƒÂ¼tfen tekrar giriÃ…Å¸ yapÃ„Â±n.',
          'Session verification failed. Please log in again.',
        );
        return;
      }
      _returnLoginSuccess(
        cookie: cookieString,
        userId: resolvedUserId.trim(),
        username: username ?? '',
        userAgent: userAgent,
      );
    } catch (e) {
      if (mounted) setState(() => isScanning = false);
      _showLoginError(
        'Oturum doÃ„Å¸rulamasÃ„Â± sÃ„Â±rasÃ„Â±nda bir hata oluÃ…Å¸tu.',
        'An error occurred while verifying the session.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: widget.isDark ? Colors.black : Colors.white,
        appBar: AppBar(
            title: Text(localizeTrEn(widget.lang, 'GiriÃ…Å¸ Yap', 'Login')),
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
                            'Oturum doÃ„Å¸rulandÃ„Â±, yÃƒÂ¶nlendiriliyorsunuz...',
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
