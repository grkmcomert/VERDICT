import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:unfollowerscurrent/ad_consent_flow.dart';

void main() {
  testWidgets('reading GDPR beyond 12 seconds cannot trigger ATT or ads',
      (tester) async {
    final gdprDismissed = Completer<void>();
    final attDismissed = Completer<void>();
    final sdkInitialized = Completer<void>();
    final events = <String>[];
    // Cached UMP consent must not bypass the current prompt sequence.
    final flow = AdConsentFlow(canRequestAds: () async => true);
    final startup = flow.start(
      gatherConsent: () {
        events.add('gdpr');
        return gdprDismissed.future;
      },
      requestTracking: () {
        events.add('att');
        return attDismissed.future;
      },
      initializeAds: () {
        events.add('sdk');
        return sdkInitialized.future;
      },
      onError: (error) => fail('$error'),
    );

    await tester.pump(const Duration(seconds: 30));
    expect(events, ['gdpr']);
    expect(await flow.canRequestAds(), isFalse);

    gdprDismissed.complete();
    await tester.pump();
    expect(events, ['gdpr', 'att']);
    expect(await flow.canRequestAds(), isFalse);

    attDismissed.complete();
    await tester.pump();
    expect(events, ['gdpr', 'att', 'sdk']);
    expect(await flow.canRequestAds(), isFalse);

    sdkInitialized.complete();
    await startup;
    expect(await flow.canRequestAds(), isTrue);
  });

  test('concurrent startup calls share one permission sequence', () async {
    final dismissed = Completer<void>();
    final flow = AdConsentFlow(canRequestAds: () async => true);
    var prompts = 0;
    Future<void> start() => flow.start(
          gatherConsent: () => dismissed.future,
          requestTracking: () async => prompts++,
          initializeAds: () async {},
          onError: (error) => fail('$error'),
        );
    final first = start();
    final second = start();
    dismissed.complete();
    await Future.wait([first, second]);
    await start();
    expect(prompts, 1);
  });

  test('UMP disallowing ad requests skips ATT and SDK initialization',
      () async {
    final flow = AdConsentFlow(canRequestAds: () async => false);
    await flow.start(
      gatherConsent: () async {},
      requestTracking: () async => fail('ATT must not be requested'),
      initializeAds: () async => fail('Ads must not initialize'),
      onError: (error) => fail('$error'),
    );
    await flow.completed;
    expect(await flow.canRequestAds(), isFalse);
  });

  for (final failedStage in ['gdpr', 'att', 'sdk']) {
    test('$failedStage failure completes startup with ads disabled', () async {
      final flow = AdConsentFlow(canRequestAds: () async => true);
      final events = <String>[];
      final errors = <Object>[];
      Future<void> stage(String name) async {
        events.add(name);
        if (name == failedStage) throw StateError(name);
      }

      await flow.start(
        gatherConsent: () => stage('gdpr'),
        requestTracking: () => stage('att'),
        initializeAds: () => stage('sdk'),
        onError: errors.add,
      );
      await flow.completed;
      expect(events.last, failedStage);
      expect(errors, hasLength(1));
      expect(await flow.canRequestAds(), isFalse);
    });
  }

  test('every request rechecks UMP and handles errors conservatively',
      () async {
    var allowed = true;
    var failed = false;
    final flow = AdConsentFlow(canRequestAds: () async {
      if (failed) throw StateError('UMP unavailable');
      return allowed;
    });
    expect(await flow.canRequestAds(), isFalse);
    await flow.start(
      gatherConsent: () async {},
      requestTracking: () async {},
      initializeAds: () async {},
      onError: (error) => fail('$error'),
    );
    expect(await flow.canRequestAds(), isTrue);
    allowed = false;
    expect(await flow.canRequestAds(), isFalse);
    allowed = true;
    failed = true;
    expect(await flow.canRequestAds(), isFalse);
  });
}
