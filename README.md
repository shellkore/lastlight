# Lastlight

Lastlight is a Flutter app for a quieter bedtime, paired with a static website and interactive browser demonstration.

## Layout

- `mobile/`: Flutter UI, seven story chapters, native Android accessibility protection, and generated iOS project.
- `web/dist/`: published landing page, interactive simulation, privacy notice, and downloadable APK.
- `web/scripts/attach-apk.mjs`: copies a built APK into the website and generates size/SHA-256 release metadata.
- `scripts/build-android.ps1`: repeatable analysis, tests, Android build, and APK publishing preparation.
- `.tools/`: workspace-local Flutter SDK, not application source.
- `vercel.json`: deploys `web/dist/` from the repository root.

The local `sites/` folder is an archived concept checkout and is excluded from this repository. The current website source is `web/`.

## Deploy on Vercel

Import [shellkore/lastlight](https://github.com/shellkore/lastlight), select the **Other** framework preset, and keep **Root Directory** as `.`. The root `vercel.json` runs `node web/scripts/verify-release.mjs` and serves `web/dist/`. No environment variables, dependencies, or Flutter build are required for the website. All three Android APKs are committed with their release metadata.

If the project already has manually overridden build settings from the earlier web-only repository, update the build command to `node web/scripts/verify-release.mjs` and output directory to `web/dist`, or clear those overrides to use the configuration file. Selecting `web` as Root Directory is also supported by its own `vercel.json`.

## Android behavior

The user explicitly enables Lastlight Accessibility after an in-app disclosure. Only window-state events and app identifiers are observed; window content retrieval is disabled. Selected apps are covered with an accessibility overlay during an active quiet session. The user can leave for Home or return to Lastlight to intentionally end the session.

Manual sessions last until the chosen morning boundary. Automatic sessions begin after the configured allowance is observed inside the evening window. Five verified quiet minutes light a checkpoint; fifteen earn a chapter, but blocking continues until morning. There is at most one earned chapter per night. Bypassing clears that night's unclaimed reward and suppresses automatic retriggering that night. Previously claimed chapters remain.

App selection, settings, counters, and stories persist locally. There are no accounts, ads, analytics SDKs, or release-app network requests. Android app-data backup is disabled.

This is an early-access voluntary blocker. Disabling Accessibility, uninstalling, battery restrictions, service interruption, and device-clock changes can affect protection. It is not an unbreakable parental control and does not measure sleep. Physical-device verification is still required before treating it as production-ready.

## Build

Use Flutter stable (this build uses 3.47.7 / Dart 3.13.5), JDK 21, and the Android SDK. Install dependencies with `flutter pub get` in `mobile/`.

```powershell
cd mobile
flutter analyze
flutter test
flutter build apk --release --split-per-abi
cd ..
node web/scripts/attach-apk.mjs (Resolve-Path mobile/build/app/outputs/flutter-apk)
```

The generated release configuration currently signs with the Android debug key for early sideload testing. Configure and retain a private release keystore before a store release or wider distribution. Never put a signing key or password in the website.

Run native schedule tests from `mobile/android` using `./gradlew testDebugUnitTest` with a suitable JDK and SDK configured.

## iOS

`mobile/ios/Runner.xcworkspace` and the iOS Flutter target are generated. The iOS bridge provides a clearly marked preview; Screen Time authorization, Family Controls/Managed Settings extensions, and enforcement are not implemented. The website says **Coming soon** and has no pretend App Store link.

Compiling or signing an iOS binary requires macOS, Xcode, and the appropriate Apple signing setup. On a Mac, run `flutter pub get`, then `flutter build ios --no-codesign` to verify compilation. No IPA is produced on Windows.

## Website

```powershell
python -m http.server 4174 --directory web/dist
```

The browser demonstration simulates progress and does not control other apps. The actual APK and generated release metadata live in `web/dist/downloads/`. The original Sites project identity is retained in `web/.openai/hosting.json`; Vercel uses `vercel.json`. This GitHub branch includes APK binaries that exceed the Sites source server's Git object limit; use a separate source-only checkout if publishing to the original Sites host.
