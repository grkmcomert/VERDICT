import 'dart:async';

/// Serializes startup privacy prompts and keeps every ad placement behind them.
class AdConsentFlow {
  AdConsentFlow({required Future<bool> Function() canRequestAds})
      : _canRequestAds = canRequestAds;

  final Future<bool> Function() _canRequestAds;
  final Completer<void> _completed = Completer<void>();
  bool _started = false;
  bool _adsInitialized = false;

  Future<void> get completed => _completed.future;

  Future<void> start({
    required Future<void> Function() gatherConsent,
    required Future<void> Function() requestTracking,
    required Future<void> Function() initializeAds,
    required void Function(Object error) onError,
  }) async {
    if (_started) return completed;
    _started = true;
    try {
      // A user may read a form for any length of time. Never time this out
      // and advance to another permission prompt while it is still visible.
      await gatherConsent();
      if (!await _canRequestAds()) return;
      await requestTracking();
      if (!await _canRequestAds()) return;
      await initializeAds();
      _adsInitialized = true;
    } catch (error) {
      // A failed consent flow must not start ATT or ads with uncertain state.
      onError(error);
    } finally {
      _completed.complete();
    }
  }

  Future<bool> canRequestAds() async {
    if (!_completed.isCompleted || !_adsInitialized) return false;
    try {
      return await _canRequestAds();
    } catch (_) {
      return false;
    }
  }
}
