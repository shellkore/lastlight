import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class RepBridge {
  bool get isPreview =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.android;
  static const channel = MethodChannel('app.replock/device');
  // Web is a labeled UI preview. It never simulates completed verification or mints coins.
  final Map<String, dynamic> _preview = {
    'preview': true,
    'platform': 'Browser preview',
    'onboarded': false,
  };
  Future<RepState> state() async => RepState.fromMap(
    isPreview
        ? _preview
        : await channel.invokeMapMethod<String, dynamic>('state') ?? {},
  );
  Future<List<ProtectedApp>> apps() async {
    if (isPreview) {
      return const [
        ProtectedApp('com.instagram.android', 'Instagram'),
        ProtectedApp('com.google.android.youtube', 'YouTube'),
        ProtectedApp('com.zhiliaoapp.musically', 'TikTok'),
        ProtectedApp('com.twitter.android', 'X'),
        ProtectedApp('com.reddit.frontpage', 'Reddit'),
        ProtectedApp('com.snapchat.android', 'Snapchat'),
      ];
    }
    final values = await channel.invokeListMethod<dynamic>('apps') ?? [];
    return values.map((e) => ProtectedApp.fromMap(e as Map)).toList();
  }

  Future<void> call(String method, [Map<String, dynamic>? args]) async {
    if (isPreview) {
      if (method == 'onboard') {
        _preview['onboarded'] = true;
        return;
      }
      if (method == 'selectApps') {
        _preview['selected'] = args?['ids'];
        return;
      }
      throw PlatformException(
        code: 'preview',
        message: 'Install RepLock on Android to use device permissions, verify movement, and unlock apps.',
      );
    }
    await channel.invokeMethod<dynamic>(method, args);
  }

  Future<int> challenge(String id) async {
    if (isPreview) {
      throw PlatformException(
        code: 'preview',
        message: 'Camera verification runs on your Android phone. No coins are awarded in the browser preview.',
      );
    }
    return await channel.invokeMethod<int>('challenge', {'id': id}) ?? 0;
  }
}
