# Lastlight web

Buildless landing page and interactive demonstration. Serve `dist/` directly. The demonstration is a simulation; only the native Android app can enforce an app boundary.

## Refresh the download

```sh
node scripts/attach-apk.mjs /absolute/path/to/flutter-apk
```

This copies three architecture-specific APKs into `dist/downloads/`: ARM64 (the default for most current phones), ARM32, and x86-64. It writes `release.json` with each package's size and SHA-256 checksum, plus the version and build date. Keep the packages and metadata together. Each APK must fit the hosting limit of 25 MiB per file.

The APK is a deployment asset, excluded from Git to respect the source repository's object-size limit. Its release metadata and checksum verifier are tracked. Run `node scripts/verify-release.mjs` before packaging; the static deployment archive includes the actual APK. Re-run the mobile build and attachment script if the deployment asset is missing after a fresh checkout.

The iOS card is explicitly coming soon. The privacy notice explains app-local data and permissions. `.openai/hosting.json` keeps the existing public Sites identity.
