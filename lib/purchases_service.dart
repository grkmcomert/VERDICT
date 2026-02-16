import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseAttemptResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;

  const PurchaseAttemptResult({
    required this.success,
    required this.cancelled,
    this.errorMessage,
  });
}

class SubscriptionDisplayInfo {
  final String title;
  final String price;
  final String currencyCode;
  final String periodLabel;

  const SubscriptionDisplayInfo({
    required this.title,
    required this.price,
    required this.currencyCode,
    required this.periodLabel,
  });
}

class PurchasesService {
  PurchasesService._();

  static final PurchasesService instance = PurchasesService._();

  static const String monthlyProductId = 'verdict_premium_monthly';
  static const String entitlementId = 'VERDICT Pro';
  static const String _premiumPrefKey = 'is_premium';

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);
  final ValueNotifier<String> lastPurchaseError = ValueNotifier<String>('');
  final ValueNotifier<List<String>> diagnosticEvents =
      ValueNotifier<List<String>>(<String>[]);

  static const int _maxDiagnosticEvents = 240;

  bool _configured = false;
  bool _checking = false;

  bool get isConfigured => _configured;

  Future<void> loadCachedPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isPremium.value = prefs.getBool(_premiumPrefKey) ?? false;
      _addDiagnosticEvent(
        'cache',
        'loadCachedPremiumStatus: isPremium=${isPremium.value}',
      );
    } catch (_) {}
  }

  Future<void> configure({
    required String androidApiKey,
    required String iosApiKey,
  }) async {
    if (_configured) {
      _addDiagnosticEvent('configure', 'skip: already configured');
      return;
    }

    final String apiKey = Platform.isIOS ? iosApiKey : androidApiKey;
    _addDiagnosticEvent(
      'configure',
      'start: platform=${Platform.operatingSystem} keyLength=${apiKey.trim().length}',
    );
    if (apiKey.trim().isEmpty) {
      debugPrint('[PurchasesService] RevenueCat API key missing; skipping.');
      _setLastPurchaseError(
          'RevenueCat API key missing (${Platform.isIOS ? 'iOS' : 'Android'})');
      _addDiagnosticEvent(
        'configure',
        'RevenueCat API key missing',
        isError: true,
      );
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
    } catch (_) {}

    try {
      final PurchasesConfiguration config = PurchasesConfiguration(apiKey);

      // iOS: Prefer StoreKit 1 for stability and to avoid StoreKit 2
      // configuration requirements breaking purchases in production.
      if (Platform.isIOS) {
        config.storeKitVersion = StoreKitVersion.storeKit1;
      }

      await Purchases.configure(config);
      _configured = true;
      _addDiagnosticEvent('configure', 'success');
    } catch (e) {
      debugPrint('[PurchasesService] configure error: $e');
      _setLastPurchaseError('RevenueCat configure error: $e');
      _addDiagnosticEvent('configure', 'error: $e', isError: true);
    }

    if (!_configured) return;

    try {
      Purchases.addCustomerInfoUpdateListener((info) {
        final bool premium = _isPremiumFromCustomerInfo(info);
        _addDiagnosticEvent(
          'customer_info_listener',
          'update received: premium=$premium activeSubscriptions=${info.activeSubscriptions.length}',
        );
        unawaited(_setPremium(premium));
      });
      _addDiagnosticEvent('configure', 'customer info listener attached');
    } catch (_) {}
  }

  Future<void> checkPurchaseStatus() async {
    if (!_configured) return;
    if (_checking) return;
    _checking = true;
    _addDiagnosticEvent('checkPurchaseStatus', 'start');

    try {
      final info = await Purchases.getCustomerInfo();
      final bool premium = _isPremiumFromCustomerInfo(info);
      await _setPremium(premium);
      _addDiagnosticEvent(
        'checkPurchaseStatus',
        'success: premium=$premium activeSubscriptions=${info.activeSubscriptions.length}',
      );
    } catch (e) {
      debugPrint('[PurchasesService] checkPurchaseStatus error: $e');
      _addDiagnosticEvent('checkPurchaseStatus', 'error: $e', isError: true);
    } finally {
      _checking = false;
    }
  }

  void clearLastPurchaseError() {
    lastPurchaseError.value = '';
    _addDiagnosticEvent('error', 'last purchase error cleared');
  }

  void clearDiagnosticEvents() {
    diagnosticEvents.value = <String>[];
  }

  void _setLastPurchaseError(String message) {
    final String clean = message.trim();
    lastPurchaseError.value = clean;
    if (clean.isNotEmpty) {
      _addDiagnosticEvent('error', clean, isError: true);
    }
  }

  void _addDiagnosticEvent(
    String op,
    String message, {
    bool isError = false,
  }) {
    final String cleanOp = op.trim().isEmpty ? 'unknown' : op.trim();
    String cleanMessage = message.replaceAll('\r\n', '\n').trim();
    if (cleanMessage.isEmpty) cleanMessage = '(empty)';
    if (cleanMessage.length > 3500) {
      cleanMessage = '${cleanMessage.substring(0, 3500)}...';
    }
    final String level = isError ? 'ERROR' : 'INFO';
    final String line =
        '[${DateTime.now().toIso8601String()}][$level][$cleanOp] $cleanMessage';

    final List<String> next = List<String>.from(diagnosticEvents.value);
    next.insert(0, line);
    if (next.length > _maxDiagnosticEvents) {
      next.removeRange(_maxDiagnosticEvents, next.length);
    }
    diagnosticEvents.value = next;
  }

  String _formatPlatformException(
      PlatformException e, PurchasesErrorCode code) {
    final List<String> parts = <String>[
      '[${DateTime.now().toIso8601String()}] ${Platform.operatingSystem.toUpperCase()}',
      'PurchasesErrorCode=$code',
      if (e.code.trim().isNotEmpty) 'PlatformException.code=${e.code.trim()}',
      if ((e.message ?? '').trim().isNotEmpty)
        'PlatformException.message=${(e.message ?? '').trim()}',
    ];

    final dynamic details = e.details;
    if (details != null) {
      String rendered;
      if (details is Map || details is List) {
        try {
          rendered = const JsonEncoder.withIndent('  ').convert(details);
        } catch (_) {
          rendered = details.toString();
        }
      } else {
        rendered = details.toString();
      }
      rendered = rendered.trim();
      if (rendered.isNotEmpty) {
        if (rendered.length > 6000) {
          rendered = '${rendered.substring(0, 6000)}...';
        }
        parts.add('PlatformException.details=$rendered');
      }
    }

    return parts.join('\n');
  }

  String _normalizeIdentifier(String input) {
    final String v = input.trim().toLowerCase();
    if (v.isEmpty) return v;
    return v.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Future<Package?> _getPreferredPackage() async {
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final Offering? current = offerings.current;
      if (current == null) {
        _addDiagnosticEvent('offerings', 'current offering is null');
        return null;
      }
      if (current.monthly != null) {
        _addDiagnosticEvent('offerings', 'using current.monthly package');
        return current.monthly;
      }
      if (current.availablePackages.isEmpty) {
        _addDiagnosticEvent('offerings', 'availablePackages is empty');
        return null;
      }
      _addDiagnosticEvent(
        'offerings',
        'using fallback package type=${current.availablePackages.first.packageType.name}',
      );
      return current.availablePackages.firstWhere(
        (p) => p.packageType == PackageType.monthly,
        orElse: () => current.availablePackages.first,
      );
    } catch (e) {
      debugPrint('[PurchasesService] getOfferings error: $e');
      _addDiagnosticEvent('offerings', 'error: $e', isError: true);
      return null;
    }
  }

  Future<SubscriptionDisplayInfo?> getMonthlySubscriptionDisplayInfo() async {
    if (!_configured) return null;
    try {
      final Package? package = await _getPreferredPackage();
      if (package == null) return null;
      final StoreProduct product = package.storeProduct;
      final String title = product.title.trim().isEmpty
          ? 'VERDICT Premium'
          : product.title.trim();
      String price = (product.pricePerMonthString ?? product.priceString).trim();
      final String currencyCode = product.currencyCode.trim().toUpperCase();
      if (price.isEmpty) {
        final double rawPrice = product.pricePerMonth ?? product.price;
        final String numeric = rawPrice.toStringAsFixed(2);
        price = currencyCode.isEmpty ? numeric : '$currencyCode $numeric';
      }
      return SubscriptionDisplayInfo(
        title: title,
        price: price,
        currencyCode: currencyCode,
        periodLabel: '1 month',
      );
    } catch (e) {
      _addDiagnosticEvent(
        'offerings',
        'display info error: $e',
        isError: true,
      );
      return null;
    }
  }

  Future<PurchaseAttemptResult> makePurchaseMonthly() async {
    _addDiagnosticEvent('purchase', 'start monthly purchase');
    if (!_configured) {
      if (lastPurchaseError.value.trim().isEmpty) {
        _setLastPurchaseError('Purchases not configured');
      }
      _addDiagnosticEvent('purchase', 'blocked: not configured', isError: true);
      return const PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: 'Purchases not configured',
      );
    }

    try {
      clearLastPurchaseError();

      final Package? package = await _getPreferredPackage();
      _addDiagnosticEvent(
        'purchase',
        package != null
            ? 'selected package=${package.identifier}'
            : 'selected fallback productId=$monthlyProductId',
      );
      final PurchaseResult result = package != null
          ? await Purchases.purchasePackage(package)
          : await Purchases.purchaseProduct(monthlyProductId);

      bool premium = _isPremiumFromCustomerInfo(result.customerInfo);
      if (!premium) {
        try {
          await Purchases.syncPurchases();
          final CustomerInfo info = await Purchases.getCustomerInfo();
          premium = _isPremiumFromCustomerInfo(info);
        } catch (_) {}
      }
      await _setPremium(premium);
      if (!premium) {
        _setLastPurchaseError('premium_not_active');
      }
      _addDiagnosticEvent('purchase', 'completed: premium=$premium');
      return PurchaseAttemptResult(
        success: premium,
        cancelled: false,
        errorMessage: premium ? null : 'premium_not_active',
      );
    } on PlatformException catch (e) {
      final PurchasesErrorCode code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        clearLastPurchaseError();
        _addDiagnosticEvent('purchase', 'cancelled by user');
        return const PurchaseAttemptResult(success: false, cancelled: true);
      }
      _setLastPurchaseError(_formatPlatformException(e, code));
      final String msg = e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : e.toString();
      debugPrint('[PurchasesService] purchase error code=$code msg=$msg');
      _addDiagnosticEvent(
        'purchase',
        'platform exception code=$code msg=$msg',
        isError: true,
      );
      return PurchaseAttemptResult(
          success: false, cancelled: false, errorMessage: msg);
    } catch (e) {
      _setLastPurchaseError(e.toString());
      _addDiagnosticEvent('purchase', 'unexpected error: $e', isError: true);
      return PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<PurchaseAttemptResult> makePurchase() {
    return makePurchaseMonthly();
  }

  Future<PurchaseAttemptResult> restorePurchases() async {
    _addDiagnosticEvent('restore', 'start restore');
    if (!_configured) {
      if (lastPurchaseError.value.trim().isEmpty) {
        _setLastPurchaseError('Purchases not configured');
      }
      _addDiagnosticEvent('restore', 'blocked: not configured', isError: true);
      return const PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: 'Purchases not configured',
      );
    }

    try {
      clearLastPurchaseError();
      final CustomerInfo info = await Purchases.restorePurchases();
      final bool premium = _isPremiumFromCustomerInfo(info);
      await _setPremium(premium);
      if (!premium) {
        _setLastPurchaseError('premium_not_active');
      }
      _addDiagnosticEvent('restore', 'completed: premium=$premium');
      return PurchaseAttemptResult(
        success: premium,
        cancelled: false,
      );
    } on PlatformException catch (e) {
      final PurchasesErrorCode code = PurchasesErrorHelper.getErrorCode(e);
      _setLastPurchaseError(_formatPlatformException(e, code));
      final String msg = e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : e.toString();
      _addDiagnosticEvent(
        'restore',
        'platform exception code=$code msg=$msg',
        isError: true,
      );
      return PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: msg,
      );
    } catch (e) {
      _addDiagnosticEvent('restore', 'unexpected error: $e', isError: true);
      return PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: e.toString(),
      );
    }
  }

  bool _isPremiumFromCustomerInfo(CustomerInfo info) {
    try {
      if (info.activeSubscriptions.contains(monthlyProductId)) return true;

      final String normalizedMonthly = _normalizeIdentifier(monthlyProductId);
      if (normalizedMonthly.isNotEmpty) {
        if (info.activeSubscriptions
            .any((id) => _normalizeIdentifier(id) == normalizedMonthly)) {
          return true;
        }
        if (info.allPurchasedProductIdentifiers
            .any((id) => _normalizeIdentifier(id) == normalizedMonthly)) {
          return true;
        }
      }

      final active = info.entitlements.active;
      if (active.containsKey('premium') || active.containsKey('Premium')) {
        return true;
      }
      if (active.containsKey(entitlementId)) return true;

      final String normalizedEntitlement = _normalizeIdentifier(entitlementId);
      if (normalizedEntitlement.isNotEmpty) {
        for (final key in active.keys) {
          final String nk = _normalizeIdentifier(key);
          if (nk == normalizedEntitlement || nk == 'premium') return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _setPremium(bool value) async {
    isPremium.value = value;
    _addDiagnosticEvent('premium', 'setPremium: $value');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumPrefKey, value);
    } catch (_) {}
  }
}
