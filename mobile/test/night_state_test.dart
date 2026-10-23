import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lastlight/platform_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = LastlightBridge.channel;
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test(
    'native overnight session remains active after chapter is earned',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => {
              'supported': true,
              'connected': true,
              'active': true,
              'pending': true,
              'quietSeconds': 900,
              'canClaim': false,
              'chapters': 2,
              'packages': ['com.test.feed'],
            },
          );
      final state = await LastlightBridge().state();
      expect(state.active, isTrue);
      expect(state.pending, isTrue);
      expect(state.canClaim, isFalse);
      expect(state.chapters, 2);
      expect(state.packages, ['com.test.feed']);
    },
  );
  test(
    'permission errors are propagated instead of pretending protection started',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(
              code: 'permission',
              message: 'Enable accessibility first.',
            );
          });
      expect(LastlightBridge().start(), throwsA(isA<PlatformException>()));
    },
  );
}
