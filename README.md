# Lastlight web

Buildless landing page and interactive demonstration. Serve `dist/` directly. The demonstration is a simulation; only the native Android app can enforce an app boundary.

## Refresh the download

```sh
node scripts/attach-apk.mjs /absolute/path/to/app-release.apk
```

This copies the actual APK into `dist/downloads/lastlight-0.1.0.apk` and writes `release.json` with its version, size, build date, and SHA-256 checksum. Keep the APK and metadata together.

The APK is a deployment asset, excluded from Git to respect the source repository's object-size limit. Its release metadata and checksum verifier are tracked. Run `node scripts/verify-release.mjs` before packaging; the static deployment archive includes the actual APK. Re-run the mobile build and attachment script if the deployment asset is missing after a fresh checkout.

The iOS card is explicitly coming soon. The privacy notice explains app-local data and permissions. `.openai/hosting.json` keeps the existing public Sites identity.
