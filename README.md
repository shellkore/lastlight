# Lastlight web

Buildless landing page and interactive demonstration. Serve `dist/` directly. The demonstration is a simulation; only the native Android app can enforce an app boundary.

## Deploy on Vercel

Import `https://github.com/shellkore/lastlight` into Vercel. This repository contains the contents of the local `web/` folder, so leave **Root Directory** at the repository root (`.`) and select **Other** as the framework preset.

`vercel.json` sets the build command to `node scripts/verify-release.mjs` and the output directory to `dist`. No dependencies, environment variables, or Flutter installation are needed. The build verifies the committed APK sizes and SHA-256 checksums before publishing. All three APKs are included so download links work on a fresh checkout.

Vercel configuration reference: https://vercel.com/docs/project-configuration

## Refresh the download

```sh
node scripts/attach-apk.mjs /absolute/path/to/flutter-apk
```

This copies three architecture-specific APKs into `dist/downloads/`: ARM64 (the default for most current phones), ARM32, and x86-64. It writes `release.json` with each package's size and SHA-256 checksum, plus the version and build date. Keep the packages and metadata together. Each APK must fit the hosting limit of 25 MiB per file.

The APKs and release metadata are tracked in this GitHub repository. After attaching a new build, commit the updated packages together with `release.json`. Run `node scripts/verify-release.mjs` before pushing.

These are early-access APKs signed with the Android debug key for sideload testing. The native Flutter source is maintained separately in the sibling `mobile/` folder in the original workspace. The browser demonstration does not enforce app boundaries.

The iOS card is explicitly coming soon. The privacy notice explains app-local data and permissions. `.openai/hosting.json` retains the original public Sites identity; Vercel uses `vercel.json`. Sites source hosting has a smaller Git object limit, so do not push this APK-containing branch to the Sites source server.
