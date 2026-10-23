class Challenge {
  final String id, name, subtitle, cue;
  final int reps, coins;
  const Challenge(
    this.id,
    this.name,
    this.subtitle,
    this.cue,
    this.reps,
    this.coins,
  );
  static const all = [
    Challenge(
      'squats',
      'Squat & unlock',
      '10 squats · about 45 sec',
      'Stand sideways, keep your full body in frame. Lower comfortably, then stand tall.',
      10,
      20,
    ),
    Challenge(
      'jacks',
      'Jump into it',
      '15 jumping jacks · about 40 sec',
      'Face the camera. Start with feet together and arms down. Open your feet and raise both arms, then return.',
      15,
      30,
    ),
    Challenge(
      'march',
      'Find your stride',
      '20 knee raises · about 60 sec',
      'Face the camera. Lift one knee toward hip height, lower it, then alternate. No jumping needed.',
      20,
      20,
    ),
  ];
}

class ProtectedApp {
  final String id, name;
  const ProtectedApp(this.id, this.name);
  factory ProtectedApp.fromMap(Map<dynamic, dynamic> map) =>
      ProtectedApp(map['id'] as String, map['name'] as String);
}

class WalletEntry {
  final String title;
  final int coins, timestamp;
  const WalletEntry(this.title, this.coins, this.timestamp);
  factory WalletEntry.fromMap(Map<dynamic, dynamic> map) => WalletEntry(
    map['title'] as String,
    (map['coins'] as num).toInt(),
    (map['timestamp'] as num).toInt(),
  );
}

class RepState {
  final bool onboarded,
      protection,
      accessEnabled,
      stepEnabled,
      stepAvailable,
      preview;
  final int balance,
      earnedToday,
      steps,
      stepCoins,
      workouts,
      totalEarned,
      remainingSeconds;
  final String activeApp, platform;
  final List<String> selected;
  final List<WalletEntry> history;
  const RepState({
    this.onboarded = false,
    this.protection = false,
    this.accessEnabled = false,
    this.stepEnabled = false,
    this.stepAvailable = false,
    this.preview = false,
    this.balance = 0,
    this.earnedToday = 0,
    this.steps = 0,
    this.stepCoins = 0,
    this.workouts = 0,
    this.totalEarned = 0,
    this.remainingSeconds = 0,
    this.activeApp = '',
    this.platform = 'Android',
    this.selected = const [],
    this.history = const [],
  });
  factory RepState.fromMap(Map<dynamic, dynamic> m) => RepState(
    onboarded: m['onboarded'] == true,
    protection: m['protection'] == true,
    accessEnabled: m['accessEnabled'] == true,
    stepEnabled: m['stepEnabled'] == true,
    stepAvailable: m['stepAvailable'] == true,
    preview: m['preview'] == true,
    balance: (m['balance'] as num? ?? 0).toInt(),
    earnedToday: (m['earnedToday'] as num? ?? 0).toInt(),
    steps: (m['steps'] as num? ?? 0).toInt(),
    stepCoins: (m['stepCoins'] as num? ?? 0).toInt(),
    workouts: (m['workouts'] as num? ?? 0).toInt(),
    totalEarned: (m['totalEarned'] as num? ?? 0).toInt(),
    remainingSeconds: (m['remainingSeconds'] as num? ?? 0).toInt(),
    activeApp: m['activeApp'] as String? ?? '',
    platform: m['platform'] as String? ?? 'Android',
    selected: (m['selected'] as List? ?? []).cast<String>(),
    history: (m['history'] as List? ?? [])
        .map((e) => WalletEntry.fromMap(e as Map))
        .toList(),
  );
  String get clock =>
      '${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';
}
