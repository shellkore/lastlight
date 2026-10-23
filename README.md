# RepLock + Lastlight

Two Flutter apps, two landing pages. **RepLock** turns movement into intentional screen time. **Lastlight** keeps the original bedtime story experience.

Published: [RepLock landing page](https://lastlight-concept.shivampathakcse23.chatgpt.site/replock/) · [YouTube launch film](https://youtu.be/nxaQSihabgg) · [Android ARM64 download](https://lastlight-concept.shivampathakcse23.chatgpt.site/replock/downloads/replock-0.1.0-arm64.apk).

## Project layout

- `mobile-replock/` — the new RepLock Flutter app and native Android implementation.
- `mobile-lastlight/` — the previous Lastlight mobile folder, preserved with its original code and tests. Its original project guide is `mobile-lastlight/PROJECT.md`.
- `web/dist/index.html` — the original Lastlight landing page.
- `web/dist/replock/` — RepLock landing page, interactive walkthrough, privacy notice, APK downloads, Flutter UI preview, and launch film.
- `launch/` — reproducible launch-video renderer and actual Flutter screen captures with illustrative data.
- `scripts/build-replock.ps1` — RepLock analysis, tests, APK builds, and website assets.
- `scripts/build-android.ps1` — the existing Lastlight build script, updated to `mobile-lastlight`.

## RepLock's Android loop

1. Choose installed apps. Read the Accessibility disclosure and enable the service in Android Settings. Return to RepLock and enable App protection.
2. Complete 10 squats for 20 coins, 15 jumping jacks for 30, or 20 alternating knee raises for 20. CameraX supplies frames to bundled ML Kit pose detection. Stable, high-confidence movement cycles count; a held pose does not.
3. Alternatively, opt into step tracking. Every 500 tracked steps earns 5 coins. Claim them in the app.
4. Spend 10/20/30 coins for a 5/10/15-minute pass to one selected app. Pass time starts immediately and continues outside that app. The shield returns at expiry.

The native Android layer owns the wallet, verification, and unlock timer. Flutter cannot directly mint coins. Native persistence stores the latest 100 transactions. Workout rewards are capped at 200/day with 45 seconds between completions; step rewards are capped at 100/day. Passes use elapsed device time and fail closed after reboot. Everything is local; coins have no monetary value.

## Build and check

Flutter stable, JDK 21, and the Android SDK are required. The workspace SDK is `.tools/flutter` when available.

```powershell
./scripts/build-replock.ps1 -JavaHome 'C:/Program Files/Java/jdk-21' -AndroidSdk 'C:/Users/shellkore/AppData/Local/Android/Sdk'
```

Or from `mobile-replock/`:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
cd android
./gradlew testDebugUnitTest
```

APK outputs are in `mobile-replock/build/app/outputs/flutter-apk/`. `web/scripts/attach-replock.mjs` copies all three architectures into the website with SHA-256 metadata. Compressed native libraries keep each APK below the Sites 25 MiB asset limit.

## Website

`web/` is shared by both apps. Each landing page's footer links to the other app.

Serve `web/dist/` with a static server. Lastlight is `/`; RepLock is `/replock/`; the Flutter preview is `/replock/preview/`. The browser cannot block apps or verify camera challenges, and is labeled accordingly.

```sh
python -m http.server 4175 --directory web/dist
node web/scripts/verify-all.mjs
```

Vercel can deploy from repository root (`vercel.json`) or `web` (`web/vercel.json`). The verification step checks both apps' binaries, RepLock's local asset links, and the attached YouTube URL. The existing public Sites project is also retained. Sites publication uses an isolated source checkout under ignored `sites/`; binaries are included in the deployment archive, not pushed as Git source objects.

## Release boundaries

This is an **Android early-access** implementation, not an app-store release. APKs use development signing. Real-device validation of camera accuracy, accessibility behavior, and vendor battery restrictions is still required; no Android device was connected during this build. A private release keystore and store permission review are required before store distribution.

The generated iOS target and browser build show a clearly labeled UI preview. iOS native enforcement, camera/step integration, Family Controls entitlements, Device Activity extensions, and a signed Mac/Xcode build remain unfinished. There is no pretend iOS download.

Protection is voluntary: users can pause it, disable Accessibility, or uninstall. Pose detection can miss reps and is not identity or medical verification. Step tracking starts after opt-in and may stop under system restrictions. Daily caps use local dates and are not a financial anti-fraud mechanism.

Technical references: [ML Kit pose detection](https://developers.google.com/ml-kit/vision/pose-detection/android), [Android accessibility services](https://developer.android.com/guide/topics/ui/accessibility/service), [Apple Family Controls](https://developer.apple.com/documentation/familycontrols).
