# Lastlight mobile

Flutter mobile source for Android and iOS. See PROJECT.md in this folder for behavior, platform limitations, and release steps.

Screens: Tonight, Your story, Boundaries. The Android platform channel owns persisted settings and session state. The accessibility service owns foreground-app observation, quiet-time verification, overnight overlays, and scheduled enforcement, so the Flutter screen does not need to stay open.

The iOS target is a preview with native blocking intentionally unavailable. A Mac/Xcode build, Apple entitlements, and Screen Time integration remain required.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

Early-access APKs use debug signing. Configure a private release keystore before a store release. Permission-dependent behavior must be tested on physical Android devices.
