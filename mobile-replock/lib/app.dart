import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'platform_bridge.dart';

const ink = Color(0xFF151A13),
    lime = Color(0xFFD3FF4D),
    cream = Color(0xFFF5F5EE),
    orange = Color(0xFFFF784F),
    muted = Color(0xFF687060);

class RepLockApp extends StatelessWidget {
  const RepLockApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RepLock',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lime,
        primary: ink,
        secondary: lime,
        surface: cream,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: cream,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
      ),
    ),
    home: const RepHome(),
  );
}

class RepHome extends StatefulWidget {
  const RepHome({super.key});
  @override
  State<RepHome> createState() => _RepHomeState();
}

class _RepHomeState extends State<RepHome> with WidgetsBindingObserver {
  final bridge = RepBridge();
  RepState state = const RepState();
  List<ProtectedApp> apps = [];
  Timer? timer;
  bool loading = true, busy = false, polling = false, foreground = true;
  String? error;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (foreground && !busy) refresh();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    foreground = value == AppLifecycleState.resumed;
    if (foreground) {
      refresh();
      loadApps();
    }
  }

  Future<void> loadApps() async {
    try {
      final a = await bridge.apps();
      if (mounted) setState(() => apps = a);
    } catch (_) {
      /* State exposes device errors with retry. */
    }
  }

  Future<void> load() async {
    await loadApps();
    await refresh();
  }

  Future<void> refresh() async {
    if (polling) return;
    polling = true;
    try {
      final next = await bridge.state();
      if (mounted) {
        setState(() {
          state = next;
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e is PlatformException
              ? e.message
              : 'Device connection unavailable. Please retry.';
          loading = false;
        });
      }
    } finally {
      polling = false;
    }
  }

  void toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> action(String method, [Map<String, dynamic>? args]) async {
    if (busy) return false;
    setState(() => busy = true);
    try {
      await bridge.call(method, args);
      await refresh();
      return true;
    } catch (e) {
      toast(
        e is PlatformException
            ? e.message ?? 'Try again.'
            : 'Could not complete that action. Try again.',
      );
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String appName(String id) =>
      apps.where((a) => a.id == id).firstOrNull?.name ?? 'Selected app';
  Widget title(String small, String large, [String? subtitle]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      eyebrow(small),
      const SizedBox(height: 10),
      Text(
        large,
        style: const TextStyle(
          fontSize: 36,
          height: 1.04,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.4,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(color: muted, height: 1.5, fontSize: 15),
        ),
      ],
      const SizedBox(height: 26),
    ],
  );
  Widget panel({
    required Widget child,
    Color color = Colors.white,
    EdgeInsets padding = const EdgeInsets.all(22),
  }) => Material(
    color: color,
    borderRadius: BorderRadius.circular(26),
    child: Padding(padding: padding, child: child),
  );
  Widget page(List<Widget> children) => ListView(
    key: ValueKey('${state.onboarded}-$tab'),
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
    children: children,
  );
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sensors_off, size: 50),
                const SizedBox(height: 16),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: load,
                  child: const Text('Retry connection'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.north_east_rounded, size: 28),
                      const SizedBox(width: 6),
                      const Text(
                        'replock',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      if (state.onboarded)
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => setState(() => tab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: lime,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.toll, size: 17),
                                const SizedBox(width: 7),
                                Text(
                                  '${state.balance}',
                                  key: const ValueKey('coin-balance'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        eyebrow('MOVE / EARN / UNLOCK'),
                    ],
                  ),
                ),
                if (state.preview)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFFE4D9),
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'PREVIEW · Device features require Android',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: !state.onboarded
                      ? onboarding()
                      : switch (tab) {
                          0 => movePage(),
                          1 => unlockPage(),
                          2 => activityPage(),
                          _ => settingsPage(),
                        },
                ),
                if (state.onboarded)
                  NavigationBar(
                    backgroundColor: cream,
                    indicatorColor: lime,
                    selectedIndex: tab,
                    onDestinationSelected: (i) => setState(() => tab = i),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.bolt_outlined),
                        selectedIcon: Icon(Icons.bolt),
                        label: 'Move',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.lock_open_outlined),
                        label: 'Unlock',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bar_chart_rounded),
                        label: 'Activity',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.tune),
                        label: 'Setup',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget onboarding() => page([
    const SizedBox(height: 10),
    eyebrow('LESS THUMB. MORE YOU.'),
    const SizedBox(height: 18),
    const Text(
      'MOVE FIRST.\nSCROLL\nLATER.',
      style: TextStyle(
        fontSize: 58,
        height: .94,
        fontWeight: FontWeight.w900,
        letterSpacing: -3,
      ),
    ),
    const SizedBox(height: 22),
    Container(
      height: 205,
      decoration: BoxDecoration(
        color: lime,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Stack(
        children: [
          Positioned(
            left: 20,
            top: 20,
            child: Text(
              'MAKE YOUR\nNEXT MOVE.',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Positioned.fill(child: AthleteArt()),
          Positioned(
            right: 16,
            bottom: 14,
            child: Icon(Icons.north_east_rounded, size: 40),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    const Text(
      'Turn “one more reel” into one more rep.',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 10),
    const Text(
      'Choose your distracting apps. Complete a camera-verified challenge or earn coins with your steps. Spend coins on a short scroll break.',
      style: TextStyle(color: muted, fontSize: 15, height: 1.5),
    ),
    const SizedBox(height: 24),
    FilledButton(
      onPressed: busy
          ? null
          : () async {
              if (await action('onboard') && mounted) setState(() => tab = 3);
            },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text("LET'S GET MOVING"), Icon(Icons.arrow_forward)],
      ),
    ),
    const SizedBox(height: 14),
    const Text(
      'Your pace. Your choice. Your data stays on your phone.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: muted),
    ),
  ]);
  Widget movePage() => page([
    Row(
      children: [
        eyebrow('YOUR NEXT REP STARTS HERE'),
        const Spacer(),
        Icon(
          state.protection && state.accessEnabled
              ? Icons.shield
              : Icons.shield_outlined,
          size: 18,
          color: muted,
        ),
      ],
    ),
    const SizedBox(height: 12),
    const Text(
      'Less scrolling.\nMore living.',
      style: TextStyle(
        fontSize: 38,
        height: 1.02,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.7,
      ),
    ),
    const SizedBox(height: 22),
    if (!state.protection || !state.accessEnabled) ...[
      InkWell(
        onTap: () => setState(() => tab = 3),
        child: panel(
          color: const Color(0xFFFFE2D5),
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Set up your app shield',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
    ],
    if (state.remainingSeconds > 0) ...[
      activePass(),
      const SizedBox(height: 18),
    ],
    panel(
      color: lime,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                eyebrow('PICK YOUR ENERGY'),
                const SizedBox(height: 12),
                const Text(
                  'A little sweat.\nA fresh start.',
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${state.earnedToday} / 200 workout coins today',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 104, height: 140, child: AthleteArt()),
        ],
      ),
    ),
    const SizedBox(height: 28),
    const Row(
      children: [
        Expanded(
          child: Text(
            'Choose your challenge',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
        ),
        Icon(Icons.north_east, size: 20),
      ],
    ),
    const SizedBox(height: 14),
    for (var i = 0; i < Challenge.all.length; i++) ...[
      challengeCard(Challenge.all[i], i),
      const SizedBox(height: 12),
    ],
    const SizedBox(height: 10),
    stepCard(),
    const SizedBox(height: 18),
    const Text(
      'Move at your own pace. Stop if anything hurts. Step rewards are an alternative to camera challenges.',
      style: TextStyle(fontSize: 12, height: 1.5, color: muted),
    ),
  ]);
  Widget challengeCard(Challenge c, int index) => Semantics(
    button: true,
    label: '${c.name}, ${c.reps} repetitions, ${c.coins} coins',
    child: InkWell(
      onTap: busy ? null : () => challengeSheet(c),
      borderRadius: BorderRadius.circular(24),
      child: panel(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 62,
              decoration: BoxDecoration(
                color: [
                  const Color(0xFFE8EEDB),
                  const Color(0xFFFFE0D4),
                  const Color(0xFFE9E3FA),
                ][index],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                [
                  Icons.fitness_center,
                  Icons.accessibility_new,
                  Icons.directions_walk,
                ][index],
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.subtitle,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Icon(Icons.videocam_outlined, size: 13, color: muted),
                      SizedBox(width: 4),
                      Text(
                        'Camera verified',
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '+${c.coins}\ncoins',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
  Widget stepCard() {
    final claimable = math.max(
      0,
      math.min(100, state.steps ~/ 500 * 5) - state.stepCoins,
    );
    return panel(
      color: ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk, color: lime),
              SizedBox(width: 8),
              Text(
                'YOUR STEPS HAVE VALUE',
                style: TextStyle(
                  color: lime,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${state.steps} steps',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: cream,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: state.steps % 500 / 500,
            backgroundColor: Colors.white24,
            color: lime,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 14),
          Text(
            state.stepEnabled
                ? '${500 - state.steps % 500} to the next 5 coins · up to 100/day'
                : '500 tracked steps = 5 coins. Start tracking in Setup.',
            style: const TextStyle(
              color: Color(0xFFB8C0AE),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: ink,
              ),
              onPressed: busy
                  ? null
                  : claimable > 0
                  ? () => action('claimSteps')
                  : () => setState(() => tab = 3),
              child: Text(
                claimable > 0
                    ? 'Claim $claimable coins  ↗'
                    : state.stepEnabled
                    ? 'Manage step tracking'
                    : 'Turn steps into coins  ↗',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget activePass() => panel(
    color: ink,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR BREAK IS LIVE',
                style: TextStyle(
                  color: lime,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${appName(state.activeApp)} · ${state.clock}',
                style: const TextStyle(
                  color: cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Re-locks when time runs out.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Open unlocked app',
          onPressed: busy
              ? null
              : () => action('launchApp', {'id': state.activeApp}),
          icon: const Icon(Icons.north_east, color: lime),
        ),
      ],
    ),
  );
  Widget unlockPage() => page([
    title(
      'YOU EARNED YOUR BREAK',
      'A little scroll.\nOn your terms.',
      'Trade coins for one app at a time. The timer starts when you redeem, even if you leave the app.',
    ),
    if (state.remainingSeconds > 0) ...[
      activePass(),
      TextButton(
        onPressed: busy ? null : confirmEnd,
        child: const Text('End this pass early'),
      ),
      const SizedBox(height: 12),
    ],
    panel(
      color: lime,
      child: Row(
        children: [
          const Icon(Icons.toll, size: 36),
          const SizedBox(width: 16),
          Text(
            '${state.balance}',
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 10),
          const Text(
            'coins to spend',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
    const SizedBox(height: 26),
    const Text(
      'Choose an app',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 12),
    if (state.selected.isEmpty)
      panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your lineup is empty.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose which apps should take a break first.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: selectApps,
              child: const Text('Choose apps'),
            ),
          ],
        ),
      ),
    for (final id in state.selected) ...[
      panel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            appIcon(appName(id)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                appName(id),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            FilledButton(
              onPressed: busy || state.remainingSeconds > 0
                  ? null
                  : () => redeemSheet(id),
              style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
    ],
    TextButton(onPressed: selectApps, child: const Text('Edit protected apps')),
    const SizedBox(height: 16),
    const Text(
      '5 min = 10 coins  /  10 min = 20 coins  /  15 min = 30 coins',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: muted, height: 1.6),
    ),
  ]);
  Widget activityPage() => page([
    title(
      'SMALL MOVES ADD UP',
      'Look at you go.',
      'Every completed challenge counts. No streak to lose. Just your progress.',
    ),
    Row(
      children: [
        Expanded(child: stat('${state.workouts}', 'challenges done', lime)),
        const SizedBox(width: 12),
        Expanded(
          child: stat(
            '${state.totalEarned}',
            'coins earned',
            const Color(0xFFFFDECF),
          ),
        ),
      ],
    ),
    const SizedBox(height: 18),
    stepCard(),
    const SizedBox(height: 26),
    const Text(
      'Your coin trail',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 14),
    if (state.history.isEmpty)
      panel(
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, size: 32),
            SizedBox(height: 16),
            Text(
              'Your first win is waiting.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Finish a challenge or claim your step coins. Your earned and spent coins will appear here.',
              style: TextStyle(color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    for (final entry in state.history)
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
        leading: CircleAvatar(
          backgroundColor: entry.coins > 0 ? lime : Colors.white,
          child: Icon(
            entry.coins > 0 ? Icons.north_east : Icons.lock_open,
            color: ink,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          dateLabel(entry.timestamp),
          style: const TextStyle(fontSize: 12, color: muted),
        ),
        trailing: Text(
          '${entry.coins > 0 ? '+' : ''}${entry.coins}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
  ]);
  Widget stat(String value, String label, Color color) => panel(
    color: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
  String dateLabel(int value) {
    final d = DateTime.fromMillisecondsSinceEpoch(value);
    return '${d.day}/${d.month} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget settingsPage() => page([
    title(
      'BUILD YOUR BOUNDARY',
      'Your phone.\nYour rules.',
      'Two quick steps to protect your attention. Add step tracking whenever you like.',
    ),
    panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eyebrow('01 / CHOOSE YOUR DISTRACTIONS'),
          const SizedBox(height: 14),
          Text(
            '${state.selected.length} apps in your lineup',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Leave calls, maps, and essential apps available.',
            style: TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : selectApps,
              child: const Text('Choose apps  ↗'),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eyebrow('02 / SWITCH ON YOUR SHIELD'),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'App protection',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              state.protection && state.accessEnabled
                  ? 'On. Selected apps need an earned pass.'
                  : 'Off. Your apps are currently accessible.',
            ),
            value: state.protection && state.accessEnabled,
            onChanged: busy
                ? null
                : (enabled) async {
                    if (enabled && !state.accessEnabled) {
                      await accessDisclosure();
                    } else {
                      await action('protect', {'enabled': enabled});
                    }
                  },
          ),
          if (!state.accessEnabled)
            TextButton(
              onPressed: busy ? null : accessDisclosure,
              child: const Text('Enable Android Accessibility →'),
            ),
          const SizedBox(height: 8),
          const Text(
            'You can pause protection here at any time. This is a voluntary boundary, not an unbreakable lock.',
            style: TextStyle(fontSize: 12, color: muted, height: 1.5),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eyebrow('BONUS / WALK YOUR WAY THERE'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Step rewards',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              state.stepAvailable
                  ? 'Tracks from activation. A visible notification keeps you informed.'
                  : 'A step-counter sensor is unavailable on this device.',
            ),
            value: state.stepEnabled,
            onChanged: busy || !state.stepAvailable
                ? null
                : (value) => action('steps', {'enabled': value}),
          ),
          const Text(
            '500 steps = 5 coins, up to 100 coins per day. Re-enable tracking after a reboot or if your phone stops the service.',
            style: TextStyle(fontSize: 12, color: muted, height: 1.5),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.privacy_tip_outlined),
      title: const Text('Privacy & how it works'),
      trailing: const Icon(Icons.arrow_forward, size: 18),
      onTap: privacy,
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.restart_alt),
      title: const Text('Reset local progress'),
      subtitle: const Text('Clears coins, passes, and selected apps'),
      onTap: busy ? null : reset,
    ),
    const SizedBox(height: 18),
    const Text(
      'REPLOCK  /  0.1.0 EARLY ACCESS\nMade for moving. Built with Flutter.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11, color: muted, height: 1.8),
    ),
  ]);
  Widget appIcon(String name) => Container(
    width: 45,
    height: 45,
    decoration: BoxDecoration(
      color: const Color(0xFFE8ECDD),
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: Text(
      name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
    ),
  );
  Future<void> selectApps() async {
    await loadApps();
    if (!mounted) return;
    final picked = state.selected.toSet();
    String query = '';
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final filtered = apps
              .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * .8,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  0,
                  22,
                  MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pick your lineup.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Only the apps you select will be protected.',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search installed apps',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => update(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching apps found.'))
                          : ListView(
                              children: [
                                for (final a in filtered)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    secondary: appIcon(a.name),
                                    title: Text(a.name),
                                    value: picked.contains(a.id),
                                    onChanged: (v) => update(() {
                                      if (v == true) {
                                        picked.add(a.id);
                                      } else {
                                        picked.remove(a.id);
                                      }
                                    }),
                                  ),
                              ],
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, picked.toList()),
                        child: Text('Save ${picked.length} apps'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (result != null) await action('selectApps', {'ids': result});
  }

  Future<void> accessDisclosure() async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your app shield needs permission'),
        content: const Text(
          'RepLock uses Android Accessibility to detect the foreground app and cover the apps you choose.\n\nIt observes app identifiers, not messages, posts, passwords, typed text, or screen content. Identifiers stay on this device and are not shared.\n\nEnable RepLock in Accessibility settings, then return here and switch on App protection. You can disable it at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agree & open settings'),
          ),
        ],
      ),
    );
    if (consent == true) await action('openAccess');
  }

  Future<void> challengeSheet(Challenge c) async {
    final start = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cream,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              eyebrow('YOUR NEXT WIN  /  +${c.coins} COINS'),
              const SizedBox(height: 14),
              Text(
                c.name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Text(c.cue, style: const TextStyle(fontSize: 17, height: 1.5)),
              const SizedBox(height: 16),
              const Text(
                'Set your phone on a stable surface, allow space, and use good lighting. The camera checks complete reps on this device. Frames are not recorded or uploaded.\n\nOnly move within a comfortable range. You can stop any time or earn with steps instead.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Start camera challenge  ↗'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (start != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      final coins = await bridge.challenge(c.id);
      await refresh();
      if (coins > 0 && mounted) {
        HapticFeedback.heavyImpact();
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: lime,
            title: const Text(
              'YOU DID THAT. ↗',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Text(
              '+$coins coins.\nA little movement. A real win.',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep moving'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => tab = 1);
                },
                child: const Text('Use my coins'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      toast(
        e is PlatformException
            ? e.message ?? 'Camera unavailable.'
            : 'The challenge could not start. Try again.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> redeemSheet(String id) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: cream,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock ${appName(id)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${state.balance} coins available · timer starts immediately',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              for (final minutes in [5, 10, 15])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.balance >= minutes * 2
                          ? () => Navigator.pop(ctx, minutes)
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$minutes minutes'),
                          Text('${minutes * 2} coins  ↗'),
                        ],
                      ),
                    ),
                  ),
                ),
              const Text(
                'Passes keep counting when you leave the app. Ending a pass early does not refund coins.',
                style: TextStyle(fontSize: 12, color: muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
    if (minutes != null &&
        await action('redeem', {'id': id, 'minutes': minutes})) {
      toast('Pass is live. Tap the arrow to open ${appName(id)}.');
    }
  }

  Future<void> confirmEnd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Done scrolling?'),
        content: const Text(
          'End this pass and re-lock the app now. Spent coins will not be refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep pass'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End pass'),
          ),
        ],
      ),
    );
    if (yes == true) await action('endPass');
  }

  Future<void> reset() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start fresh?'),
        content: const Text(
          'This deletes your local coins, activity history, app selections, and active pass. Protection and step tracking will stop. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep my progress'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset progress'),
          ),
        ],
      ),
    );
    if (yes == true) await action('reset');
  }

  void privacy() => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Built around your privacy.'),
      content: const SingleChildScrollView(
        child: Text(
          'No account. No ads. No cloud wallet.\n\nCamera frames are processed on-device with ML Kit to estimate body landmarks. RepLock does not save photos or videos. Camera access is used only during a challenge. Pose estimation can miss reps and is not proof of identity or a fitness assessment.\n\nAndroid Accessibility observes foreground app identifiers for the blocking overlay. Screen content retrieval is disabled.\n\nStep tracking uses the device step counter after you opt in. Battery restrictions and service interruptions can affect tracking. No steps before activation are credited.\n\nCoins, selected apps, step totals, and the latest 100 wallet entries are stored locally. App backup is disabled. Reset local progress or uninstall to delete them.\n\nWorkout rewards: up to 200 coins per day, with 45 seconds between completions. Step rewards: 5 coins per 500 steps, up to 100 per day. Coins have no cash value.\n\nProtection is voluntary. It stops if Accessibility is disabled or the app is removed. Passes end on reboot. Essential apps should stay unselected.\n\nRepLock 0.1.0 is an Android early-access build. iOS availability is pending native integration and Apple approval.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

Widget eyebrow(String text) => Text(
  text,
  style: const TextStyle(
    fontSize: 10,
    letterSpacing: 1.3,
    fontWeight: FontWeight.w800,
    color: muted,
  ),
);

class AthleteArt extends StatelessWidget {
  const AthleteArt({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _AthletePainter());
}

class _AthletePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * .51, size.height * .16);
    final scale = math.min(size.width / 140, size.height / 155);
    canvas.scale(scale);
    final p = Paint()
      ..color = ink
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13;
    canvas.drawCircle(const Offset(0, 5), 14, Paint()..color = ink);
    canvas.drawPath(
      Path()
        ..moveTo(-5, 31)
        ..lineTo(-12, 62)
        ..lineTo(12, 80)
        ..lineTo(-3, 119),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 62)
        ..lineTo(-42, 88)
        ..lineTo(-31, 120),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-5, 33)
        ..lineTo(20, 50)
        ..lineTo(40, 28),
      p..strokeWidth = 10,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-6, 35)
        ..lineTo(-32, 45)
        ..lineTo(-47, 29),
      p,
    );
    canvas.drawLine(
      const Offset(-45, 135),
      const Offset(44, 135),
      Paint()
        ..color = ink.withValues(alpha: .18)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
