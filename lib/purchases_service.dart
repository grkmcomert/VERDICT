import 'dart:async';
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

class PurchasesService {
  PurchasesService._();

  static final PurchasesService instance = PurchasesService._();

  static const String monthlyProductId = 'verdict_premium_monthly';
  static const String entitlementId = 'VERDICT Pro';
  static const String _premiumPrefKey = 'is_premium';

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  bool _configured = false;
  bool _checking = false;

  bool get isConfigured => _configured;

  Future<void> loadCachedPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isPremium.value = prefs.getBool(_premiumPrefKey) ?? false;
    } catch (_) {}
  }

  Future<void> configure({
    required String androidApiKey,
    required String iosApiKey,
  }) async {
    if (_configured) return;

    final String apiKey = Platform.isIOS ? iosApiKey : androidApiKey;
    if (apiKey.trim().isEmpty) {
      debugPrint('[PurchasesService] RevenueCat API key missing; skipping.');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
    } catch (_) {}

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
    } catch (e) {
      debugPrint('[PurchasesService] configure error: $e');
    }

    if (!_configured) return;

    try {
      Purchases.addCustomerInfoUpdateListener((info) {
        final bool premium = _isPremiumFromCustomerInfo(info);
        unawaited(_setPremium(premium));
      });
    } catch (_) {}
  }

  Future<void> checkPurchaseStatus() async {
    if (!_configured) return;
    if (_checking) return;
    _checking = true;

    try {
      final info = await Purchases.getCustomerInfo();
      final bool premium = _isPremiumFromCustomerInfo(info);
      await _setPremium(premium);
    } catch (e) {
      debugPrint('[PurchasesService] checkPurchaseStatus error: $e');
    } finally {
      _checking = false;
    }
  }

  Future<PurchaseAttemptResult> makePurchaseMonthly() async {
    if (!_configured) {
      return const PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: 'Purchases not configured',
      );
    }

    try {
      final PurchaseResult result =
          await Purchases.purchaseProduct(monthlyProductId);
      final bool premium = _isPremiumFromCustomerInfo(result.customerInfo);
      await _setPremium(premium);
      return PurchaseAttemptResult(
        success: premium,
        cancelled: false,
        errorMessage: premium ? null : 'premium_not_active',
      );
    } on PlatformException catch (e) {
      final PurchasesErrorCode code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseAttemptResult(success: false, cancelled: true);
      }
      final String msg = e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : e.toString();
      return PurchaseAttemptResult(
          success: false, cancelled: false, errorMessage: msg);
    } catch (e) {
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
    if (!_configured) {
      return const PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: 'Purchases not configured',
      );
    }

    try {
      final CustomerInfo info = await Purchases.restorePurchases();
      final bool premium = _isPremiumFromCustomerInfo(info);
      await _setPremium(premium);
      return PurchaseAttemptResult(
        success: premium,
        cancelled: false,
      );
    } on PlatformException catch (e) {
      final String msg = e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : e.toString();
      return PurchaseAttemptResult(
        success: false,
        cancelled: false,
        errorMessage: msg,
      );
    } catch (e) {
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
      final active = info.entitlements.active;
      if (active.containsKey('premium') || active.containsKey('Premium')) return true;
      if (active.containsKey(entitlementId)) return true;
    } catch (_) {}
    return false;
  }

  Future<void> _setPremium(bool value) async {
    isPremium.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumPrefKey, value);
    } catch (_) {}
  }
}
