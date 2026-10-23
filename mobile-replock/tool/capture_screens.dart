// Run with: flutter test tool/capture_screens.dart
// Captures real Flutter widgets with explicitly illustrative native data for the launch film.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replock/app.dart';
import 'package:replock/platform_bridge.dart';

void main() {
  testWidgets('capture launch demonstration screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fonts = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold', 'black']) {
      fonts.addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '../.tools/flutter/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '../.tools/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
    // Flutter tests default some component text to Ahem; replace that test-only font.
    final componentFont = FontLoader('Ahem')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '../.tools/flutter/bin/cache/artifacts/material_fonts/roboto-bold.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await componentFont.load();
    // Supply test-runner glyph fallback; these OS fonts are not bundled or distributed.
    final symbols = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('C:/Windows/Fonts/seguisym.ttf').readAsBytesSync(),
          ),
        ),
      );
    await symbols.load();
    var data = <String, dynamic>{
      'onboarded': false,
      'balance': 20,
      'earnedToday': 20,
      'totalEarned': 70,
      'workouts': 3,
      'steps': 1500,
      'stepCoins': 10,
      'stepEnabled': true,
      'stepAvailable': true,
      'protection': true,
      'accessEnabled': true,
      'selected': ['com.instagram.android', 'com.google.android.youtube'],
      'history': [
        {'title': 'Squat & unlock', 'coins': 20, 'timestamp': 1792744200000},
        {
          'title': '5 min · Instagram',
          'coins': -10,
          'timestamp': 1792740600000,
        },
      ],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RepBridge.channel, (call) async {
          if (call.method == 'state') return data;
          if (call.method == 'apps') {
            return [
              {'id': 'com.instagram.android', 'name': 'Instagram'},
              {'id': 'com.google.android.youtube', 'name': 'YouTube'},
            ];
          }
          return null;
        });
    final key = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../launch/screens/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const RepLockApp()),
    );
    await capture('onboarding');
    data['onboarded'] = true;
    await tester.pump(const Duration(seconds: 1));
    await capture('move');
    await tester.tap(find.text('Unlock').last);
    await capture('unlock');
    data['remainingSeconds'] = 300;
    data['activeApp'] = 'com.instagram.android';
    data['balance'] = 10;
    await tester.pump(const Duration(seconds: 1));
    await capture('pass');
    await tester.tap(find.text('Activity').last);
    await capture('activity');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
