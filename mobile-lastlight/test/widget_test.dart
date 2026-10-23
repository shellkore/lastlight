import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lastlight/main.dart';
import 'package:lastlight/platform_bridge.dart';

void main() {
  testWidgets('permission is required before protection can start', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          LastlightBridge.channel,
          (call) async => {
            'supported': true,
            'connected': false,
            'active': false,
            'packages': <String>[],
            'chapters': 0,
          },
        );
    await tester.pumpWidget(const LastlightApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Your protection needs permission'),
      150,
    );
    expect(find.text('Your protection needs permission'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start quiet time until 07:00 →'),
      100,
    );
    final start = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start quiet time until 07:00 →'),
    );
    expect(start.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LastlightBridge.channel, null);
  });
}
