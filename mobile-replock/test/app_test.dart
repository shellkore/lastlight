import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replock/app.dart';
import 'package:replock/models.dart';
import 'package:replock/platform_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(RepBridge.channel, null));
  test('state preserves native wallet values and timer formatting', () {
    final state = RepState.fromMap({
      'balance': 30,
      'remainingSeconds': 305,
      'selected': ['test.app'],
      'history': [
        {'title': 'Squats', 'coins': 20, 'timestamp': 1},
      ],
    });
    expect(state.clock, '5:05');
    expect(state.balance, 30);
    expect(state.history.single.coins, 20);
  });
  testWidgets('first launch explains the loop and onboarding is persisted', (
    tester,
  ) async {
    bool onboarded = false;
    messenger.setMockMethodCallHandler(RepBridge.channel, (call) async {
      if (call.method == 'state') return {'onboarded': onboarded};
      if (call.method == 'apps') return <dynamic>[];
      if (call.method == 'onboard') onboarded = true;
      return null;
    });
    await tester.pumpWidget(const RepLockApp());
    await tester.pumpAndSettle();
    expect(find.text('MOVE FIRST.\nSCROLL\nLATER.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text("LET'S GET MOVING"), 250);
    await tester.tap(find.text("LET'S GET MOVING"));
    await tester.pumpAndSettle();
    expect(onboarded, true);
    expect(find.text('Your phone.\nYour rules.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('permission errors are shown and do not mint coins', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(RepBridge.channel, (call) async {
      if (call.method == 'state') return {'onboarded': true, 'balance': 0};
      if (call.method == 'apps') return <dynamic>[];
      if (call.method == 'challenge') {
        throw PlatformException(
          code: 'camera',
          message: 'Camera permission declined.',
        );
      }
      return null;
    });
    await tester.pumpWidget(const RepLockApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squat & unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start camera challenge  ↗'));
    await tester.pumpAndSettle();
    expect(find.text('Camera permission declined.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('coin-balance'))).data,
      '0',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
