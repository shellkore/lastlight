import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'coast_painter.dart';
import 'platform_bridge.dart';
import 'story.dart';

const night = Color(0xff132731);
const cream = Color(0xfff5f0e4);
const mint = Color(0xffacc9b7);
const coral = Color(0xffe7a78b);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: night,
    ),
  );
  runApp(const LastlightApp());
}

class LastlightApp extends StatelessWidget {
  const LastlightApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lastlight',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: night,
      colorScheme: const ColorScheme.dark(
        primary: mint,
        secondary: coral,
        surface: Color(0xff1e3540),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: cream,
        displayColor: cream,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cream,
          foregroundColor: night,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const CoastHome(),
  );
}

class CoastHome extends StatefulWidget {
  const CoastHome({super.key});
  @override
  State<CoastHome> createState() => _CoastHomeState();
}

class _CoastHomeState extends State<CoastHome> with WidgetsBindingObserver {
  final bridge = LastlightBridge();
  NightState state = const NightState({});
  Timer? timer;
  int tab = 0;
  bool loading = true;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => refresh(silent: true),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      refresh();
    }
  }

  Future<void> refresh({bool silent = false}) async {
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
      if (mounted && !silent) {
        setState(() {
          loading = false;
          error = 'Could not read protection status. Please reopen the app.';
        });
      }
    }
  }

  Future<void> act(Future<void> Function() action) async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
    });
    try {
      await action();
      await refresh();
    } on PlatformException catch (e) {
      message(e.message ?? 'Please try again.');
    } catch (_) {
      message('That action could not finish. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  String clock(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  Future<void> accessDisclosure() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose to enable protection'),
        content: const SingleChildScrollView(
          child: Text(
            'Lastlight uses Android Accessibility to detect which app is open and place a blocking screen over apps you select. '
            'It does not read posts, messages, typed text, or screen contents. App names, timing, and progress stay on this device. '
            'There is no analytics or account.\n\nEnable Lastlight on the next system screen. You can disable this access in Android Settings at any time. '
            'Protection is voluntary and can be bypassed. Battery restrictions or a stopped service may interrupt it.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Android settings'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await act(bridge.openAccess);
    }
  }

  Future<void> bypass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End tonight’s protection?'),
        content: const Text(
          'Selected apps will be available. Tonight’s unclaimed chapter will not be earned. '
          'Earlier chapters stay yours. Automatic protection will resume on the next scheduled night.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep the light on'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End protection'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await act(bridge.bypass);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_twilight, color: coral),
                      const SizedBox(width: 9),
                      const Text(
                        'lastlight.',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Platform.isIOS ? 'iOS PREVIEW' : 'EARLY ACCESS',
                        style: const TextStyle(
                          color: mint,
                          fontSize: 9,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error!, style: const TextStyle(color: coral)),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: switch (tab) {
                      1 => storyBook(),
                      2 => settings(),
                      _ => tonight(),
                    },
                  ),
                ),
              ],
            ),
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: const Color(0xff11232c),
      selectedIndex: tab,
      indicatorColor: const Color(0xff345248),
      onDestinationSelected: (value) => setState(() => tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.nightlight_outlined),
          selectedIcon: Icon(Icons.nightlight),
          label: 'Tonight',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          label: 'Your story',
        ),
        NavigationDestination(icon: Icon(Icons.tune), label: 'Boundaries'),
      ],
    ),
  );
  Widget label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 10, letterSpacing: 1.8, color: mint),
  );
  Widget title(String text, {double size = 34}) => Text(
    text,
    style: TextStyle(
      fontFamily: 'serif',
      fontSize: size,
      height: 1.14,
      color: cream,
    ),
  );
  Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xff203942),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: mint.withValues(alpha: .12)),
    ),
    child: child,
  );
  Widget tonight() {
    final quiet = state.quietSeconds.clamp(0, 900);
    return ListView(
      key: const ValueKey('tonight'),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 18),
        label('THE QUIET COAST'),
        const SizedBox(height: 13),
        title(
          state.active
              ? 'Let the story\ntravel tonight.'
              : 'Leave the scroll.\nFind your story.',
        ),
        const SizedBox(height: 12),
        const Text(
          'A little lighthouse. A lost signal.\nA quieter ending to your day.',
          style: TextStyle(color: mint, height: 1.7),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: CustomPaint(
              painter: CoastPainter(
                lit:
                    (state.active && state.quietSeconds >= 300) ||
                    state.chapters > 0,
                chapter: state.chapters,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!state.supported)
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'iOS is coming soon',
                  style: TextStyle(fontSize: 18, color: coral),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This iOS project includes the Lastlight experience. Native Screen Time authorization and blocking are not enabled yet.',
                  style: TextStyle(color: mint, height: 1.6),
                ),
              ],
            ),
          )
        else if (!state.connected)
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your protection needs permission',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Enable Lastlight Accessibility to detect selected apps and show your boundary. Nothing is being blocked yet.',
                  style: TextStyle(color: mint, height: 1.6),
                ),
                const SizedBox(height: 15),
                FilledButton(
                  onPressed: busy ? null : accessDisclosure,
                  child: const Text('Set up Android protection'),
                ),
              ],
            ),
          ),
        if (state.canClaim) ...[
          const SizedBox(height: 16),
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label('A SIGNAL ARRIVED'),
                const SizedBox(height: 10),
                title('Your next chapter\nis here.', size: 27),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => act(() async {
                          await bridge.claim();
                          if (mounted) {
                            setState(() => tab = 1);
                          }
                        }),
                  child: const Text('Open your morning postcard →'),
                ),
              ],
            ),
          ),
        ],
        if (state.active) ...[
          const SizedBox(height: 16),
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label(
                  state.connected
                      ? 'PROTECTION IS ACTIVE'
                      : 'PROTECTION NEEDS RECONNECTION',
                ),
                const SizedBox(height: 12),
                Text(
                  state.connected
                      ? 'Chosen feeds stay blocked until ${clock(state.endMinute)}.'
                      : 'The service is disconnected. Re-enable it to resume blocking.',
                  style: const TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: quiet / 900,
                  color: mint,
                  backgroundColor: night,
                ),
                const SizedBox(height: 10),
                Text(
                  state.pending
                      ? 'Tonight’s chapter is earned. It opens at ${clock(state.endMinute)}.'
                      : '${quiet ~/ 60} / 15 verified quiet minutes · ${quiet >= 300 ? 'First beacon lit' : 'First beacon at 5 minutes'}',
                  style: const TextStyle(color: mint, fontSize: 12),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Put your phone down. The native service keeps the boundary while you leave this screen.',
                  style: TextStyle(fontSize: 12, color: mint, height: 1.6),
                ),
                TextButton(
                  onPressed: busy ? null : bypass,
                  child: const Text(
                    'I need to end protection',
                    style: TextStyle(color: coral),
                  ),
                ),
              ],
            ),
          ),
        ] else if (state.supported) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy || !state.connected
                ? null
                : () {
                    if (state.packages.isEmpty) {
                      setState(() => tab = 2);
                      message('Choose at least one distracting app first.');
                    } else {
                      act(bridge.start);
                    }
                  },
            child: Text(
              busy
                  ? 'Please wait…'
                  : 'Start quiet time until ${clock(state.endMinute)} →',
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            stat('${state.packages.length}', 'chosen apps'),
            stat('15 min', 'to earn a chapter'),
            stat('${state.chapters} / 7', 'chapters kept'),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'One chapter per night. No lost streaks.\nCalls and unselected apps remain available.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: mint, height: 1.8),
        ),
      ],
    );
  }

  Widget stat(String value, String text) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 19, color: cream)),
      const SizedBox(height: 4),
      Text(text, style: const TextStyle(fontSize: 9, color: mint)),
    ],
  );
  Widget storyBook() => ListView(
    key: const ValueKey('book'),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 18),
      label('SEASON ONE'),
      const SizedBox(height: 14),
      title('Seven nights.\nOne missing signal.'),
      const SizedBox(height: 12),
      const Text(
        'Your earned chapters stay yours. A missed night is simply a night.',
        style: TextStyle(color: mint, height: 1.7),
      ),
      const SizedBox(height: 24),
      for (int i = 0; i < chapters.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: panel(
            i < state.chapters
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      label('CHAPTER 0${i + 1} · KEPT'),
                      const SizedBox(height: 10),
                      title(chapters[i].title, size: 26),
                      const SizedBox(height: 12),
                      Text(
                        chapters[i].body,
                        style: const TextStyle(color: mint, height: 1.85),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.lock_outline, color: mint, size: 18),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            label('CHAPTER 0${i + 1}'),
                            const SizedBox(height: 5),
                            Text(
                              chapters[i].title,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              i == state.chapters && state.pending
                                  ? 'A signal is waiting for morning.'
                                  : 'Another quiet night, another part of the story.',
                              style: const TextStyle(color: mint, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      if (state.chapters == 7)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'The coast is restored. Your boundaries still work, even when the story is complete.',
            style: TextStyle(color: coral, height: 1.7),
          ),
        ),
    ],
  );
  Widget settings() => ListView(
    key: const ValueKey('settings'),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 18),
      label('YOUR EVENING, YOUR CHOICE'),
      const SizedBox(height: 14),
      title('Set a gentler\nboundary.'),
      const SizedBox(height: 22),
      panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('APP PROTECTION'),
            const SizedBox(height: 10),
            Text(
              state.connected
                  ? 'Android service connected'
                  : state.supported
                  ? 'Permission needed'
                  : 'iOS integration coming soon',
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'Only app identifiers and timing are observed. No screen text, messages, or posts are read. Data stays on this device.',
              style: TextStyle(color: mint, fontSize: 12, height: 1.7),
            ),
            if (state.supported)
              TextButton(
                onPressed: accessDisclosure,
                child: const Text('Review accessibility permission →'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      panel(
        Column(
          children: [
            settingLine(
              'Selected distractions',
              '${state.packages.length} apps',
              Icons.apps,
              state.active || !state.supported ? null : chooseApps,
            ),
            const Divider(color: Color(0xff38534f)),
            settingLine(
              'Evening begins',
              clock(state.startMinute),
              Icons.bedtime_outlined,
              state.active ? null : () => pickTime(true),
            ),
            settingLine(
              'Morning begins',
              clock(state.endMinute),
              Icons.wb_sunny_outlined,
              state.active ? null : () => pickTime(false),
            ),
            const Divider(color: Color(0xff38534f)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Evening allowance',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Text(
                '${state.allowance} min',
                style: const TextStyle(color: mint),
              ),
            ),
            Slider(
              min: 5,
              max: 60,
              divisions: 11,
              value: state.allowance.toDouble(),
              label: '${state.allowance} min',
              onChanged: state.active
                  ? null
                  : (value) => setState(() {
                      state = NightState({
                        ...state.data,
                        'allowance': value.round(),
                      });
                    }),
              onChangeEnd: state.active
                  ? null
                  : (value) => save({'allowance': value.round()}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Automatic evening boundary',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Block after your allowance is used during the evening window.',
                style: TextStyle(fontSize: 11, color: mint),
              ),
              value: state.flag('automatic'),
              onChanged: state.active || !state.supported
                  ? null
                  : (value) => save({'automatic': value}),
            ),
          ],
        ),
      ),
      if (state.active)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Settings are held while protection is active. End protection intentionally to change them.',
            style: TextStyle(fontSize: 12, color: coral, height: 1.7),
          ),
        ),
      const SizedBox(height: 20),
      panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('EARLY ACCESS · 0.1.0'),
            const SizedBox(height: 12),
            const Text(
              'This is voluntary protection, not a parental control. Disabling the service or uninstalling the app stops enforcement. Battery restrictions may delay it. No claim is made that it measures sleep.',
              style: TextStyle(fontSize: 12, color: mint, height: 1.75),
            ),
            const SizedBox(height: 14),
            Text(
              'Intentional bypasses: ${state.number('bypasses')}\nApp openings interrupted: ${state.number('blockedAttempts')}',
              style: const TextStyle(fontSize: 12, color: mint, height: 1.8),
            ),
          ],
        ),
      ),
    ],
  );
  Widget settingLine(
    String name,
    String value,
    IconData icon,
    VoidCallback? callback,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: mint, size: 21),
    title: Text(name, style: const TextStyle(fontSize: 13)),
    subtitle: Text(value, style: const TextStyle(color: mint, fontSize: 12)),
    trailing: callback == null
        ? null
        : const Icon(Icons.chevron_right, size: 18),
    onTap: callback,
  );
  Future<void> save(Map<String, dynamic> change) async {
    await act(() => bridge.saveSettings(change));
  }

  Future<void> pickTime(bool start) async {
    final minute = start ? state.startMinute : state.endMinute;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (time != null) {
      await save({
        start ? 'startMinute' : 'endMinute': time.hour * 60 + time.minute,
      });
    }
  }

  Future<void> chooseApps() async {
    try {
      final apps = await bridge.apps();
      if (!mounted) {
        return;
      }
      final selected = state.packages.toSet();
      final chosen = await showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .78,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Choose your distracting apps',
                    style: TextStyle(fontSize: 20),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Keep essentials unselected. Only the apps you choose will be interrupted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mint, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: apps.isEmpty
                        ? const Center(
                            child: Text('No selectable apps were found.'),
                          )
                        : ListView.builder(
                            itemCount: apps.length,
                            itemBuilder: (context, index) {
                              final app = apps[index];
                              return CheckboxListTile(
                                title: Text(app.name),
                                subtitle: Text(
                                  app.packageName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: mint,
                                  ),
                                ),
                                value: selected.contains(app.packageName),
                                onChanged: (checked) => update(() {
                                  checked == true
                                      ? selected.add(app.packageName)
                                      : selected.remove(app.packageName);
                                }),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, selected),
                      child: const Text('Save chosen apps'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (chosen != null) {
        await save({'packages': chosen.toList()});
      }
    } catch (_) {
      message('Could not load installed apps. Please try again.');
    }
  }
}
