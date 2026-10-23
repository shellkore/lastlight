# RepLock mobile

Energetic Flutter UI with a native Android implementation. See the repository README for build and release steps.

## Ownership of state

`lib/app.dart` implements onboarding, challenges, the wallet, app selection, timed passes, activity history, settings, consent, and error states. `lib/platform_bridge.dart` exposes a narrow method channel. Unsupported platforms use a labeled preview and cannot earn coins or claim protection is enabled.

Android code lives in `android/app/src/main/kotlin/app/replock/replock/`:

- `RepPolicy.kt`: reward catalog, pass prices, reboot-aware expiry, stable-frame rep counting with hysteresis, confidence gates, and alternating-knee rules.
- `RepStore.kt`: synchronized persistent wallet, bounded history, daily reward caps, cooldown, pass state, and step baselines.
- `ChallengeActivity.kt`: non-exported CameraX activity, on-device ML Kit detection, lifecycle cancellation, and native-only reward completion.
- `RepAccessibilityService.kt`: foreground app identifier events, overlay shielding, expiry polling, and an accessible exit to Home or RepLock. Screen content retrieval is disabled.
- `StepService.kt`: opt-in step-counter sensor with a foreground-service notification. No GPS.
- `MainActivity.kt`: permission flow, installed-app picker, and validated Flutter commands. Home, default dialer, Settings, and RepLock are excluded from selection.

## Validation

`flutter test` checks state mapping, onboarding persistence, and camera-permission failure without coin credits. `./gradlew testDebugUnitTest` checks prices, caps, expiry/reboot, full squat cycles, stationary holds, low confidence, camera gaps, noisy frames, jumping-jack geometry, and alternating knee raises.

`flutter test tool/capture_screens.dart` produces launch assets using explicit illustrative native data. It requires the workspace Flutter font cache and Windows Segoe symbol font; these captures do not exercise real camera or sensor hardware.

Before production, test on physical Android devices: permission refusal/regrant; full challenge completion and cancellation; poor light/occlusion; app backgrounding; no duplicate rewards; pass expiry while a selected app stays open; service disable/re-enable; step sensor reset; midnight; reboot; uninstall/reset; OEM battery restrictions; and both default/large text sizes.

## iPhone

The generated iOS project is a UI preview. Native iPhone blocking, verified movement, and step rewards are not implemented. Implement and sign Family Controls/Managed Settings plus a Device Activity extension on macOS before advertising an iPhone release. Apple requires separate entitlement approval; short unlock schedules also need platform-specific design. Android behavior must not be claimed on iOS.

## Privacy

No account or app-owned cloud service. Camera frames are not stored or uploaded by RepLock. ML Kit is bundled and performs inference on-device. The third-party SDK has its own terms; the website privacy notice links them. Selected app identifiers, coins, counters, and recent history stay local. Backup is disabled. Reset progress or uninstall to clear data.
