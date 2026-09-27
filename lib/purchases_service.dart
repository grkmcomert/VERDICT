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
  final String subscriptionPeriod;
  final String? pricePerWeek;
  final String? pricePerMonth;
  final String? pricePerYear;

  const SubscriptionDisplayInfo({
    required this.title,
    required this.price,
    required this.currencyCode,
    required this.subscriptionPeriod,
    this.pricePerWeek,
    this.pricePerMonth,
    this.pricePerYear,
  });
}

class PurchaseDebugEntitlement {
  final String identifier;
  final bool isActive;
  final bool willRenew;
  final String latestPurchaseDate;
  final String originalPurchaseDate;
  final String productIdentifier;
  final bool isSandbox;
  final String ownershipType;
  final String store;
  final String periodType;
  final String? expirationDate;
  final String? unsubscribeDetectedAt;
  final String? billingIssueDetectedAt;
  final String? productPlanIdentifier;
  final String verification;

  const PurchaseDebugEntitlement({
    required this.identifier,
    required this.isActive,
    required this.willRenew,
    required this.latestPurchaseDate,
    required this.originalPurchaseDate,
    required this.productIdentifier,
    required this.isSandbox,
    required this.ownershipType,
    required this.store,
    required this.periodType,
    this.expirationDate,
    this.unsubscribeDetectedAt,
    this.billingIssueDetectedAt,
    this.productPlanIdentifier,
    required this.verification,
  });

  factory PurchaseDebugEntitlement.fromInfo(EntitlementInfo info) {
    String enumLabel(Object value) {
      final String raw = value.toString();
      final int dot = raw.lastIndexOf('.');
      return dot >= 0 ? raw.substring(dot + 1) : raw;
    }

    return PurchaseDebugEntitlement(
      identifier: info.identifier,
      isActive: info.isActive,
      willRenew: info.willRenew,
      latestPurchaseDate: info.latestPurchaseDate,
      originalPurchaseDate: info.originalPurchaseDate,
      productIdentifier: info.productIdentifier,
      isSandbox: info.isSandbox,
      ownershipType: enumLabel(info.ownershipType),
      store: enumLabel(info.store),
      periodType: enumLabel(info.periodType),
      expirationDate: info.expirationDate,
      unsubscribeDetectedAt: info.unsubscribeDetectedAt,
      billingIssueDetectedAt: info.billingIssueDetectedAt,
      productPlanIdentifier: info.productPlanIdentifier,
      verification: enumLabel(info.verification),
    );
  }
}

class PurchaseDebugSnapshot {
  final DateTime? updatedAt;
  final String source;
  final bool configured;
  final bool premium;
  final String originalAppUserId;
  final String firstSeen;
  final String requestDate;
  final String? latestExpirationDate;
  final String? originalPurchaseDate;
  final String? originalApplicationVersion;
  final String? managementURL;
  final List<String> activeSubscriptions;
  final List<String> allPurchasedProductIdentifiers;
  final Map<String, String?> allPurchaseDates;
  final Map<String, String?> allExpirationDates;
  final List<PurchaseDebugEntitlement> activeEntitlements;
  final List<PurchaseDebugEntitlement> allEntitlements;
  final String? lastTransactionIdentifier;
  final String? lastTransactionProductIdentifier;
  final String? lastTransactionPurchaseDate;
  final String lastError;

  const PurchaseDebugSnapshot({
    required this.updatedAt,
    required this.source,
    required this.configured,
    required this.premium,
    required this.originalAppUserId,
    required this.firstSeen,
    required this.requestDate,
    this.latestExpirationDate,
    this.originalPurchaseDate,
    this.originalApplicationVersion,
    this.managementURL,
    required this.activeSubscriptions,
    required this.allPurchasedProductIdentifiers,
    required this.allPurchaseDates,
    required this.allExpirationDates,
    required this.activeEntitlements,
    required this.allEntitlements,
    this.lastTransactionIdentifier,
    this.lastTransactionProductIdentifier,
    this.lastTransactionPurchaseDate,
    required this.lastError,
  });

  static const PurchaseDebugSnapshot empty = PurchaseDebugSnapshot(
    updatedAt: null,
    source: 'not_loaded',
    configured: false,
    premium: false,
    originalAppUserId: '',
    firstSeen: '',
    requestDate: '',
    activeSubscriptions: <String>[],
    allPurchasedProductIdentifiers: <String>[],
    allPurchaseDates: <String, String?>{},
    allExpirationDates: <String, String?>{},
    activeEntitlements: <PurchaseDebugEntitlement>[],
    allEntitlements: <PurchaseDebugEntitlement>[],
    lastError: '',
  );

  bool get hasCustomerInfo =>
      originalAppUserId.trim().isNotEmpty || requestDate.trim().isNotEmpty;

  PurchaseDebugSnapshot copyWithState({
    DateTime? updatedAt,
    String? source,
    required bool configured,
    required bool premium,
    required String lastError,
  }) {
    return PurchaseDebugSnapshot(
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      configured: configured,
      premium: premium,
      originalAppUserId: originalAppUserId,
      firstSeen: firstSeen,
      requestDate: requestDate,
      latestExpirationDate: latestExpirationDate,
      originalPurchaseDate: originalPurchaseDate,
      originalApplicationVersion: originalApplicationVersion,
      managementURL: managementURL,
      activeSubscriptions: activeSubscriptions,
      allPurchasedProductIdentifiers: allPurchasedProductIdentifiers,
      allPurchaseDates: allPurchaseDates,
      allExpirationDates: allExpirationDates,
      activeEntitlements: activeEntitlements,
      allEntitlements: allEntitlements,
      lastTransactionIdentifier: lastTransactionIdentifier,
      lastTransactionProductIdentifier: lastTransactionProductIdentifier,
      lastTransactionPurchaseDate: lastTransactionPurchaseDate,
      lastError: lastError,
    );
  }

  factory PurchaseDebugSnapshot.fromCustomerInfo({
    required CustomerInfo info,
    required bool configured,
    required bool premium,
    required String source,
    required String lastError,
    StoreTransaction? transaction,
    PurchaseDebugSnapshot? previous,
  }) {
    List<PurchaseDebugEntitlement> entitlementsFrom(
      Map<String, EntitlementInfo> items,
    ) {
      final List<PurchaseDebugEntitlement> values = items.values
          .map(PurchaseDebugEntitlement.fromInfo)
          .toList(growable: false);
      return List<PurchaseDebugEntitlement>.unmodifiable(values);
    }

    return PurchaseDebugSnapshot(
      updatedAt: DateTime.now(),
      source: source,
      configured: configured,
      premium: premium,
      originalAppUserId: info.originalAppUserId,
      firstSeen: info.firstSeen,
      requestDate: info.requestDate,
      latestExpirationDate: info.latestExpirationDate,
      originalPurchaseDate: info.originalPurchaseDate,
      originalApplicationVersion: info.originalApplicationVersion,
      managementURL: info.managementURL,
      activeSubscriptions: List<String>.unmodifiable(info.activeSubscriptions),
      allPurchasedProductIdentifiers:
          List<String>.unmodifiable(info.allPurchasedProductIdentifiers),
      allPurchaseDates:
          Map<String, String?>.unmodifiable(info.allPurchaseDates),
      allExpirationDates:
          Map<String, String?>.unmodifiable(info.allExpirationDates),
      activeEntitlements: entitlementsFrom(info.entitlements.active),
      allEntitlements: entitlementsFrom(info.entitlements.all),
      lastTransactionIdentifier: transaction?.transactionIdentifier ??
          previous?.lastTransactionIdentifier,
      lastTransactionProductIdentifier: transaction?.productIdentifier ??
          previous?.lastTransactionProductIdentifier,
      lastTransactionPurchaseDate:
          transaction?.purchaseDate ?? previous?.lastTransactionPurchaseDate,
      lastError: lastError,
    );
  }
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
  final ValueNotifier<PurchaseDebugSnapshot> debugSnapshot =
      ValueNotifier<PurchaseDebugSnapshot>(PurchaseDebugSnapshot.empty);

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
      _publishDebugSnapshot(source: 'cache');
    } catch (_) {}
  }

  Future<void> configure({
    required String androidApiKey,
    required String iosApiKey,
  }) async {
    if (_configured) {
      _addDiagnosticEvent('configure', 'skip: already configured');
      _publishDebugSnapshot(source: 'configure_skip');
      return;
    }

    final String apiKey = Platform.isIOS ? iosApiKey : androidApiKey;
    _addDiagnosticEvent(
      'configure',
      'start: platform=${Platform.operatingSystem} keyLength=${apiKey.trim().length}',
    );
    _publishDebugSnapshot(source: 'configure_start');
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
      _publishDebugSnapshot(source: 'configure_success');
    } catch (e) {
      debugPrint('[PurchasesService] configure error: $e');
      _setLastPurchaseError('RevenueCat configure error: $e');
      _addDiagnosticEvent('configure', 'error: $e', isError: true);
    }

    if (!_configured) return;

    try {
      Purchases.addCustomerInfoUpdateListener((info) {
        final bool premium = _isPremiumFromCustomerInfo(info);
        _publishDebugSnapshot(
          source: 'customer_info_listener',
          customerInfo: info,
        );
        _addDiagnosticEvent(
          'customer_info_listener',
          'update received: premium=$premium ${_formatCustomerInfoSummary(info)}',
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
      _publishDebugSnapshot(
        source: 'checkPurchaseStatus',
        customerInfo: info,
      );
      await _setPremium(premium);
      _addDiagnosticEvent(
        'checkPurchaseStatus',
        'success: premium=$premium ${_formatCustomerInfoSummary(info)}',
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
    _publishDebugSnapshot(source: 'clear_error');
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
    _publishDebugSnapshot(source: 'error');
  }

  void _publishDebugSnapshot({
    required String source,
    CustomerInfo? customerInfo,
    StoreTransaction? transaction,
  }) {
    final String cleanSource = source.trim().isEmpty ? 'state' : source.trim();
    final String error = lastPurchaseError.value.trim();
    if (customerInfo == null) {
      debugSnapshot.value = debugSnapshot.value.copyWithState(
        updatedAt: DateTime.now(),
        source: cleanSource,
        configured: _configured,
        premium: isPremium.value,
        lastError: error,
      );
      return;
    }

    debugSnapshot.value = PurchaseDebugSnapshot.fromCustomerInfo(
      info: customerInfo,
      configured: _configured,
      premium: _isPremiumFromCustomerInfo(customerInfo),
      source: cleanSource,
      lastError: error,
      transaction: transaction,
      previous: debugSnapshot.value,
    );
  }

  String _joinOrNone(Iterable<String> values) {
    final List<String> clean = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (clean.isEmpty) return '(none)';
    return clean.join(',');
  }

  String _formatCustomerInfoSummary(CustomerInfo info) {
    return 'customer=${info.originalAppUserId.trim().isEmpty ? '(empty)' : info.originalAppUserId.trim()} '
        'activeSubscriptions=${_joinOrNone(info.activeSubscriptions)} '
        'activeEntitlements=${_joinOrNone(info.entitlements.active.keys)} '
        'allProducts=${_joinOrNone(info.allPurchasedProductIdentifiers)} '
        'latestExpiration=${info.latestExpirationDate ?? '(none)'} '
        'requestDate=${info.requestDate}';
  }

  Future<PurchaseDebugSnapshot?> refreshCustomerInfoForDebug() async {
    _addDiagnosticEvent('debug_refresh', 'start customer info refresh');
    if (!_configured) {
      if (lastPurchaseError.value.trim().isEmpty) {
        _setLastPurchaseError('Purchases not configured');
      }
      _addDiagnosticEvent(
        'debug_refresh',
        'blocked: not configured',
        isError: true,
      );
      return null;
    }

    try {
      final CustomerInfo info = await Purchases.getCustomerInfo();
      final bool premium = _isPremiumFromCustomerInfo(info);
      _publishDebugSnapshot(
        source: 'debug_refresh',
        customerInfo: info,
      );
      await _setPremium(premium);
      _addDiagnosticEvent(
        'debug_refresh',
        'success: premium=$premium ${_formatCustomerInfoSummary(info)}',
      );
      return debugSnapshot.value;
    } catch (e) {
      _setLastPurchaseError('RevenueCat debug refresh error: $e');
      _addDiagnosticEvent(
        'debug_refresh',
        'error: $e',
        isError: true,
      );
      return null;
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
      final String subscriptionPeriod =
          (product.subscriptionPeriod ?? '').trim().isEmpty
              ? 'P1M'
              : product.subscriptionPeriod!.trim();
      String price = (product.priceString).trim();
      final String currencyCode = product.currencyCode.trim().toUpperCase();
      if (price.isEmpty) {
        final double rawPrice = product.price;
        final String numeric = rawPrice.toStringAsFixed(2);
        price = currencyCode.isEmpty ? numeric : '$currencyCode $numeric';
      }
      String? pricePerWeek = product.pricePerWeekString?.trim();
      String? pricePerMonth = product.pricePerMonthString?.trim();
      String? pricePerYear = product.pricePerYearString?.trim();

      if ((pricePerWeek ?? '').isEmpty && subscriptionPeriod == 'P1W') {
        pricePerWeek = price;
      }
      if ((pricePerMonth ?? '').isEmpty && subscriptionPeriod == 'P1M') {
        pricePerMonth = price;
      }
      if ((pricePerYear ?? '').isEmpty && subscriptionPeriod == 'P1Y') {
        pricePerYear = price;
      }

      return SubscriptionDisplayInfo(
        title: title,
        price: price,
        currencyCode: currencyCode,
        subscriptionPeriod: subscriptionPeriod,
        pricePerWeek:
            (pricePerWeek ?? '').isEmpty ? null : pricePerWeek?.trim(),
        pricePerMonth:
            (pricePerMonth ?? '').isEmpty ? null : pricePerMonth?.trim(),
        pricePerYear:
            (pricePerYear ?? '').isEmpty ? null : pricePerYear?.trim(),
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

  Future<bool> hasEligibleThreeDayTrialForMonthly() async {
    if (!_configured) return false;
    try {
      final Package? package = await _getPreferredPackage();
      final StoreProduct? product = package?.storeProduct;
      final IntroductoryPrice? intro = product?.introductoryPrice;
      if (intro == null) return false;

      final int days = _introductoryOfferLengthInDays(intro);
      if (days != 3) return false;

      // Apple review requirement here is specifically about App Store trial
      // eligibility. On iOS we should only show the free-trial copy when
      // RevenueCat confirms the user is eligible.
      if (!Platform.isIOS) {
        return false;
      }

      final String productIdentifier = product?.identifier.trim() ?? '';
      if (productIdentifier.isEmpty) {
        _addDiagnosticEvent(
          'offerings',
          'trial eligibility check skipped: empty product identifier',
          isError: true,
        );
        return false;
      }

      final Map<String, IntroEligibility> eligibility =
          await Purchases.checkTrialOrIntroductoryPriceEligibility(
        <String>[productIdentifier],
      );
      final IntroEligibility? result = eligibility[productIdentifier];
      final IntroEligibilityStatus? status = result?.status;
      _addDiagnosticEvent(
        'offerings',
        'trial eligibility status for $productIdentifier: ${status?.name ?? 'null'}',
      );

      return status == IntroEligibilityStatus.introEligibilityStatusEligible;
    } catch (e) {
      _addDiagnosticEvent(
        'offerings',
        'trial eligibility check error: $e',
        isError: true,
      );
      return false;
    }
  }

  int _introductoryOfferLengthInDays(IntroductoryPrice intro) {
    final int units =
        intro.periodNumberOfUnits <= 0 ? 1 : intro.periodNumberOfUnits;
    final int cycles = intro.cycles <= 0 ? 1 : intro.cycles;
    final int totalUnits = units * cycles;

    switch (intro.periodUnit) {
      case PeriodUnit.day:
        return totalUnits;
      case PeriodUnit.week:
        return totalUnits * 7;
      case PeriodUnit.month:
      case PeriodUnit.year:
      case PeriodUnit.unknown:
        return -1;
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
      _publishDebugSnapshot(
        source: 'purchase_result',
        customerInfo: result.customerInfo,
        transaction: result.storeTransaction,
      );

      bool premium = _isPremiumFromCustomerInfo(result.customerInfo);
      if (!premium) {
        try {
          await Purchases.syncPurchases();
          final CustomerInfo info = await Purchases.getCustomerInfo();
          premium = _isPremiumFromCustomerInfo(info);
          _publishDebugSnapshot(
            source: 'purchase_sync',
            customerInfo: info,
            transaction: result.storeTransaction,
          );
        } catch (_) {}
      }
      await _setPremium(premium);
      if (!premium) {
        _setLastPurchaseError('premium_not_active');
      }
      _addDiagnosticEvent(
        'purchase',
        'completed: premium=$premium transaction=${result.storeTransaction.transactionIdentifier} product=${result.storeTransaction.productIdentifier}',
      );
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
      _publishDebugSnapshot(
        source: 'restore',
        customerInfo: info,
      );
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
        // Do not treat expired purchases as premium. activeSubscriptions
        // already indicates current entitlement status for subscriptions.
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
    final PurchaseDebugSnapshot current = debugSnapshot.value;
    debugSnapshot.value = current.copyWithState(
      updatedAt: DateTime.now(),
      source: current.hasCustomerInfo ? current.source : 'premium',
      configured: _configured,
      premium: value,
      lastError: lastPurchaseError.value.trim(),
    );
  }
}
