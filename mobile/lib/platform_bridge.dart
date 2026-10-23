import 'package:flutter/services.dart';

class NativeApp {
  final String packageName;
  final String name;
  const NativeApp(this.packageName, this.name);
  factory NativeApp.fromMap(Map<dynamic, dynamic> map) =>
      NativeApp(map['packageName'] as String, map['name'] as String);
}

class NightState {
  final Map<String, dynamic> data;
  const NightState(this.data);
  factory NightState.fromMap(Map<dynamic, dynamic> map) =>
      NightState(Map<String, dynamic>.from(map));
  int number(String key, [int fallback = 0]) =>
      (data[key] as num?)?.toInt() ?? fallback;
  bool flag(String key) => data[key] == true;
  bool get supported => flag('supported');
  bool get connected => flag('connected');
  bool get active => flag('active');
  bool get pending => flag('pending');
  bool get canClaim => flag('canClaim');
  int get quietSeconds => number('quietSeconds');
  int get chapters => number('chapters');
  int get startMinute => number('startMinute', 1320);
  int get endMinute => number('endMinute', 420);
  int get allowance => number('allowance', 20);
  List<String> get packages =>
      List<String>.from(data['packages'] as List? ?? []);
  DateTime? get endAt => number('endAt') > 0
      ? DateTime.fromMillisecondsSinceEpoch(number('endAt'))
      : null;
  DateTime? get revealAt => number('revealAt') > 0
      ? DateTime.fromMillisecondsSinceEpoch(number('revealAt'))
      : null;
}

class LastlightBridge {
  static const channel = MethodChannel('app.lastlight/night');
  Future<NightState> state() async => NightState.fromMap(
    await channel.invokeMapMethod<dynamic, dynamic>('state') ?? {},
  );
  Future<List<NativeApp>> apps() async {
    final result = await channel.invokeListMethod<dynamic>('apps') ?? [];
    return result.map((app) => NativeApp.fromMap(app as Map)).toList();
  }

  Future<void> saveSettings(Map<String, dynamic> settings) =>
      channel.invokeMethod<void>('saveSettings', settings);
  Future<void> openAccess() => channel.invokeMethod<void>('openAccess');
  Future<void> start() => channel.invokeMethod<void>('start');
  Future<void> bypass() => channel.invokeMethod<void>('bypass');
  Future<void> claim() => channel.invokeMethod<void>('claim');
}
