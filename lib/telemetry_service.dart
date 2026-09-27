import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'turkey_time.dart';

class TelemetryService {
  TelemetryService._();

  static final TelemetryService instance = TelemetryService._();

  static const Duration _writeTimeout = Duration(seconds: 20);

  static const String _userIdPrefKey = 'telemetry_user_id';
  static const String _usernamePrefKey = 'telemetry_username';
  static const String _sessionIdPrefKey = 'telemetry_session_id';

  static const String usersCollection = 'ig_users';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Map<String, dynamic>? _cachedDeviceFields;
  Map<String, dynamic>? _cachedAppFields;
  static const String _lastErrorPrefKey = 'telemetry_last_error';

  String _formatError(Object error, {String? op}) {
    final String prefix = op == null || op.trim().isEmpty ? '' : '[$op] ';
    if (error is FirebaseException) {
      final String code = error.code.trim();
      final String msg = (error.message ?? '').trim();
      if (code.isNotEmpty && msg.isNotEmpty)
        return '${prefix}FirebaseException($code): $msg';
      if (code.isNotEmpty) return '${prefix}FirebaseException($code)';
      if (msg.isNotEmpty) return '${prefix}FirebaseException: $msg';
      return '${prefix}FirebaseException';
    }
    return '$prefix${error.toString()}';
  }

  Future<void> _setLastError(String message) async {
    final String msg = message.trim();
    if (msg.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastErrorPrefKey, msg);
    } catch (_) {}
  }

  Future<void> _clearLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastErrorPrefKey);
    } catch (_) {}
  }

  Future<String?> getLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String v = (prefs.getString(_lastErrorPrefKey) ?? '').trim();
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _getLocaleFields() {
    try {
      final String raw = Platform.localeName.trim();
      if (raw.isEmpty) return {};

      final String cleaned = raw.split('.').first.trim();
      final List<String> parts = cleaned.split(RegExp(r'[_-]'));

      final String languageCode =
          parts.isNotEmpty ? parts.first.trim().toLowerCase() : '';
      final String countryCode =
          parts.length >= 2 ? parts[1].trim().toUpperCase() : '';

      return {
        'locale': cleaned,
        if (languageCode.isNotEmpty) 'language_code': languageCode,
        if (countryCode.isNotEmpty) 'country_code': countryCode,
      };
    } catch (_) {
      return {};
    }
  }

  Future<_TelemetryContext?> _getContext(
      {required bool createSessionIfMissing}) async {
    final prefs = await SharedPreferences.getInstance();

    String userId = (prefs.getString(_userIdPrefKey) ?? '').trim();
    String username = (prefs.getString(_usernamePrefKey) ?? '').trim();
    String sessionId = (prefs.getString(_sessionIdPrefKey) ?? '').trim();

    if (userId.isEmpty) {
      userId = (prefs.getString('session_user_id') ?? '').trim();
    }
    if (username.isEmpty) {
      username = (prefs.getString('session_username') ?? '').trim();
    }

    if (userId.isEmpty) return null;

    if (createSessionIfMissing && sessionId.isEmpty) {
      sessionId = _generateSessionId();
      try {
        await prefs.setString(_userIdPrefKey, userId);
        if (username.isNotEmpty) {
          await prefs.setString(_usernamePrefKey, username);
        }
        await prefs.setString(_sessionIdPrefKey, sessionId);
      } catch (_) {}
    }

    if (sessionId.isNotEmpty) {
      try {
        if ((prefs.getString(_userIdPrefKey) ?? '').trim().isEmpty) {
          await prefs.setString(_userIdPrefKey, userId);
        }
        if ((prefs.getString(_usernamePrefKey) ?? '').trim().isEmpty &&
            username.isNotEmpty) {
          await prefs.setString(_usernamePrefKey, username);
        }
        if ((prefs.getString(_sessionIdPrefKey) ?? '').trim().isEmpty) {
          await prefs.setString(_sessionIdPrefKey, sessionId);
        }
      } catch (_) {}
    }

    return _TelemetryContext(
      userId: userId,
      username: username,
      sessionId: sessionId,
    );
  }

  Future<Map<String, dynamic>> _getDeviceFields() async {
    if (_cachedDeviceFields != null) return _cachedDeviceFields!;

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
        _cachedDeviceFields = {
          'device_model': info.model,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo info = await _deviceInfo.iosInfo;
        _cachedDeviceFields = {
          'device_model': info.model,
          'device_machine': info.utsname.machine,
        };
      } else {
        _cachedDeviceFields = {};
      }
    } catch (e) {
      debugPrint('[TelemetryService] device_info error: $e');
      _cachedDeviceFields = {};
    }

    return _cachedDeviceFields!;
  }

  Future<Map<String, dynamic>> _getAppFields() async {
    if (_cachedAppFields != null) return _cachedAppFields!;

    try {
      final info = await PackageInfo.fromPlatform();
      _cachedAppFields = {
        'app_version': info.version,
      };
    } catch (e) {
      debugPrint('[TelemetryService] package_info error: $e');
      _cachedAppFields = {};
    }

    return _cachedAppFields!;
  }

  String _generateSessionId() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int rand = Random.secure().nextInt(1 << 32);
    return '${now}_${rand.toRadixString(16)}';
  }

  String _userDocIdFromUsername(String username) {
    String value = username.trim().toLowerCase();
    if (value.startsWith('@')) value = value.substring(1);
    value = value.replaceAll('/', '_').replaceAll(RegExp(r'\s+'), '');
    if (value == '.' || value == '..') return '';
    return value;
  }

  Map<String, dynamic> _cleanupUserFields() {
    return <String, dynamic>{
      'app_build': FieldValue.delete(),
      'app_package': FieldValue.delete(),
      'country_source': FieldValue.delete(),
      'updated_at': FieldValue.delete(),
      'last_session_id': FieldValue.delete(),
      'user_id': FieldValue.delete(),
      'userId': FieldValue.delete(),
      'last_seen_at': FieldValue.delete(),
      'platform': FieldValue.delete(),
      'os_version': FieldValue.delete(),
      'device_manufacturer': FieldValue.delete(),
      'device_brand': FieldValue.delete(),
      'last_analysis_duration_ms': FieldValue.delete(),
      'last_analysis_followers_count': FieldValue.delete(),
      'last_analysis_following_count': FieldValue.delete(),
    };
  }

  Map<String, dynamic> _cleanupSessionFields() {
    return <String, dynamic>{
      'updated_at': FieldValue.delete(),
      'user_id': FieldValue.delete(),
      'last_seen_at': FieldValue.delete(),
      'platform': FieldValue.delete(),
      'os_version': FieldValue.delete(),
      'device_manufacturer': FieldValue.delete(),
      'device_brand': FieldValue.delete(),
    };
  }

  Future<bool> recordLogin({
    required String userId,
    required String username,
    required bool isPremium,
  }) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final String sessionId = _generateSessionId();
    await prefs.setString(_userIdPrefKey, cleanUserId);
    await prefs.setString(_usernamePrefKey, username);
    await prefs.setString(_sessionIdPrefKey, sessionId);

    final Map<String, dynamic> device = await _getDeviceFields();
    final Map<String, dynamic> app = await _getAppFields();
    final Map<String, dynamic> locale = _getLocaleFields();

    return await _writeLogin(
      username: username,
      sessionId: sessionId,
      isPremium: isPremium,
      device: device,
      app: app,
      locale: locale,
    );
  }

  Future<bool> recordLogout() async {
    final _TelemetryContext? ctx =
        await _getContext(createSessionIfMissing: false);
    if (ctx == null) return false;

    final Map<String, dynamic> device = await _getDeviceFields();
    final Map<String, dynamic> app = await _getAppFields();
    final Map<String, dynamic> locale = _getLocaleFields();

    return await _writeLogout(
      username: ctx.username,
      sessionId: ctx.sessionId.isEmpty ? null : ctx.sessionId,
      device: device,
      app: app,
      locale: locale,
    );
  }

  Future<bool> recordRewardedAdWatched() async {
    final _TelemetryContext? ctx =
        await _getContext(createSessionIfMissing: true);
    if (ctx == null) return false;
    if (ctx.sessionId.isEmpty) return false;

    final Map<String, dynamic> device = await _getDeviceFields();
    final Map<String, dynamic> app = await _getAppFields();
    final Map<String, dynamic> locale = _getLocaleFields();

    return await _writeRewardedAdWatched(
      username: ctx.username,
      sessionId: ctx.sessionId,
      device: device,
      app: app,
      locale: locale,
    );
  }

  Future<bool> recordSeen() async {
    final _TelemetryContext? ctx =
        await _getContext(createSessionIfMissing: true);
    if (ctx == null) return false;

    final Map<String, dynamic> device = await _getDeviceFields();
    final Map<String, dynamic> app = await _getAppFields();
    final Map<String, dynamic> locale = _getLocaleFields();

    return await _writeSeen(
      username: ctx.username,
      sessionId: ctx.sessionId.isEmpty ? null : ctx.sessionId,
      device: device,
      app: app,
      locale: locale,
    );
  }

  Future<bool> recordAnalysisCompleted({
    required int followersCount,
    required int followingCount,
    Duration? duration,
  }) async {
    final _TelemetryContext? ctx =
        await _getContext(createSessionIfMissing: true);
    if (ctx == null) return false;

    final Map<String, dynamic> device = await _getDeviceFields();
    final Map<String, dynamic> app = await _getAppFields();
    final Map<String, dynamic> locale = _getLocaleFields();

    return await _writeAnalysisCompleted(
      username: ctx.username,
      sessionId: ctx.sessionId.isEmpty ? null : ctx.sessionId,
      followersCount: followersCount,
      followingCount: followingCount,
      duration: duration,
      device: device,
      app: app,
      locale: locale,
    );
  }

  Future<bool> _writeLogin({
    required String username,
    required String sessionId,
    required bool isPremium,
    required Map<String, dynamic> device,
    required Map<String, dynamic> app,
    required Map<String, dynamic> locale,
  }) async {
    try {
      final String now = nowTurkeyIso8601();
      final String userDocId = _userDocIdFromUsername(username);
      if (userDocId.isEmpty) return false;
      final userRef =
          FirebaseFirestore.instance.collection(usersCollection).doc(userDocId);

      await userRef.set({
        'username': username,
        ...device,
        ...app,
        ...locale,
        'is_premium': isPremium,
        'last_seen': now,
        'last_login_at': now,
        ..._cleanupUserFields(),
      }, SetOptions(merge: true)).timeout(_writeTimeout);

      await userRef.collection('sessions').doc(sessionId).set({
        'username': username,
        'session_id': sessionId,
        ...device,
        ...app,
        ...locale,
        'is_premium_at_login': isPremium,
        'last_seen': now,
        'login_at': now,
        ..._cleanupSessionFields(),
      }, SetOptions(merge: true)).timeout(_writeTimeout);

      unawaited(_clearLastError());
      return true;
    } catch (e) {
      debugPrint('[TelemetryService] writeLogin error: $e');
      await _setLastError(_formatError(e, op: 'writeLogin'));
      return false;
    }
  }

  Future<bool> _writeLogout({
    required String username,
    required String? sessionId,
    required Map<String, dynamic> device,
    required Map<String, dynamic> app,
    required Map<String, dynamic> locale,
  }) async {
    try {
      final String now = nowTurkeyIso8601();
      final String userDocId = _userDocIdFromUsername(username);
      if (userDocId.isEmpty) return false;
      final userRef =
          FirebaseFirestore.instance.collection(usersCollection).doc(userDocId);

      await userRef.set({
        'username': username,
        ...device,
        ...app,
        ...locale,
        'last_seen': now,
        'last_logout_at': now,
        ..._cleanupUserFields(),
      }, SetOptions(merge: true)).timeout(_writeTimeout);

      if (sessionId != null && sessionId.trim().isNotEmpty) {
        await userRef.collection('sessions').doc(sessionId).set({
          'username': username,
          'last_seen': now,
          'logout_at': now,
          ...locale,
          ..._cleanupSessionFields(),
        }, SetOptions(merge: true)).timeout(_writeTimeout);
      }
      unawaited(_clearLastError());
      return true;
    } catch (e) {
      debugPrint('[TelemetryService] writeLogout error: $e');
      await _setLastError(_formatError(e, op: 'writeLogout'));
      return false;
    }
  }

  Future<bool> _writeRewardedAdWatched({
    required String username,
    required String sessionId,
    required Map<String, dynamic> device,
    required Map<String, dynamic> app,
    required Map<String, dynamic> locale,
  }) async {
    try {
      final String now = nowTurkeyIso8601();
      final String userDocId = _userDocIdFromUsername(username);
      if (userDocId.isEmpty) return false;
      final userRef =
          FirebaseFirestore.instance.collection(usersCollection).doc(userDocId);
      final sessionRef = userRef.collection('sessions').doc(sessionId);

      await userRef.set({
        'username': username,
        ...device,
        ...app,
        ...locale,
        'has_watched_rewarded_ad': true,
        'rewarded_ad_watched_count': FieldValue.increment(1),
        'last_seen': now,
        'last_rewarded_ad_at': now,
        ..._cleanupUserFields(),
      }, SetOptions(merge: true)).timeout(_writeTimeout);

      await sessionRef.set({
        'username': username,
        ...device,
        ...app,
        ...locale,
        'has_watched_rewarded_ad': true,
        'rewarded_ad_watched_count': FieldValue.increment(1),
        'last_seen': now,
        'last_rewarded_ad_at': now,
        ..._cleanupSessionFields(),
      }, SetOptions(merge: true)).timeout(_writeTimeout);

      unawaited(_clearLastError());
      return true;
    } catch (e) {
      debugPrint('[TelemetryService] writeRewardedAdWatched error: $e');
      await _setLastError(_formatError(e, op: 'writeRewardedAdWatched'));
      return false;
    }
  }

  Future<bool> _writeSeen({
    required String username,
    required String? sessionId,
    required Map<String, dynamic> device,
    required Map<String, dynamic> app,
    required Map<String, dynamic> locale,
  }) async {
    try {
      final String now = nowTurkeyIso8601();
      final String userDocId = _userDocIdFromUsername(username);
      if (userDocId.isEmpty) return false;
      final userRef =
          FirebaseFirestore.instance.collection(usersCollection).doc(userDocId);

      await userRef.set({
        'username': username,
        ...device,
        ...app,
        ...locale,
        'last_seen': now,
        ..._cleanupUserFields(),
      }, SetOptions(merge: true)).timeout(_writeTimeout);

      if (sessionId != null && sessionId.trim().isNotEmpty) {
        await userRef.collection('sessions').doc(sessionId).set({
          'username': username,
          ...device,
          ...app,
          ...locale,
          'last_seen': now,
          ..._cleanupSessionFields(),
        }, SetOptions(merge: true)).timeout(_writeTimeout);
      }
      unawaited(_clearLastError());
      return true;
    } catch (e) {
      debugPrint('[TelemetryService] writeSeen error: $e');
      await _setLastError(_formatError(e, op: 'writeSeen'));
      return false;
    }
  }

  Future<bool> _writeAnalysisCompleted({
    required String username,
    required String? sessionId,
    required int followersCount,
    required int followingCount,
    required Duration? duration,
    required Map<String, dynamic> device,
    required Map<String, dynamic> app,
    required Map<String, dynamic> locale,
  }) async {
    try {
      final String now = nowTurkeyIso8601();
      final String userDocId = _userDocIdFromUsername(username);
      if (userDocId.isEmpty) return false;
      final userRef =
          FirebaseFirestore.instance.collection(usersCollection).doc(userDocId);

      await userRef.set({
        'username': username,
        ...device,
        ...app,
        ...locale,
        'analysis_count': FieldValue.increment(1),
        'last_seen': now,
        'last_analysis_at': FieldValue.serverTimestamp(),
        ..._cleanupUserFields(),
      }, SetOptions(merge: true)).timeout(_writeTimeout);

      if (sessionId != null && sessionId.trim().isNotEmpty) {
        await userRef.collection('sessions').doc(sessionId).set({
          'username': username,
          ...app,
          ...locale,
          'last_seen': now,
          'analysis_at': now,
          'analysis_followers_count': followersCount,
          'analysis_following_count': followingCount,
          if (duration != null) 'analysis_duration_ms': duration.inMilliseconds,
          ..._cleanupSessionFields(),
        }, SetOptions(merge: true)).timeout(_writeTimeout);
      }
      unawaited(_clearLastError());
      return true;
    } catch (e) {
      debugPrint('[TelemetryService] writeAnalysisCompleted error: $e');
      await _setLastError(_formatError(e, op: 'writeAnalysisCompleted'));
      return false;
    }
  }
}

class _TelemetryContext {
  final String userId;
  final String username;
  final String sessionId;

  const _TelemetryContext({
    required this.userId,
    required this.username,
    required this.sessionId,
  });
}
