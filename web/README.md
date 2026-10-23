# RepLock + Lastlight web

Serve `dist/` directly. Lastlight remains at `/`; RepLock lives at `/replock/`. Both browser walkthroughs are simulations. RepLock's native Android app implements the camera, step sensor, wallet, and app protection; `/replock/preview/` shows the Flutter interface only.

## Validate and deploy

From the repository root, run `node web/scripts/verify-all.mjs`. This verifies both sets of APK checksums, RepLock's local links, and its YouTube launch link. Root `vercel.json` publishes `web/dist`; `web/vercel.json` supports choosing `web` as Vercel's root directory. Keep the APKs and generated release metadata together when committing changes.

The existing Sites identity is retained in `.openai/hosting.json`. Sites uses an isolated source checkout and a locally packaged static archive, because its source Git server has a smaller object limit than the APK downloads. Do not push the APK-containing application repository to the Sites source server.

## Refresh releases

- Lastlight: `node web/scripts/attach-apk.mjs /absolute/path/to/flutter-apk`.
- RepLock: `node web/scripts/attach-replock.mjs /absolute/path/to/flutter-apk`.
- RepLock's complete build: `powershell -ExecutionPolicy Bypass -File scripts/build-replock.ps1`.

RepLock's source is in `mobile-replock/`; Lastlight's preserved source is in `mobile-lastlight/`. These are Android early-access builds signed with the development key. Physical-device verification and production signing are release prerequisites. iOS native protection is not implemented.

## Launch film

RepLock's original 1080p film, poster, and English captions are in `dist/replock/media/`. `dist/replock/launch.json` holds the verified YouTube link, displayed beside the local video player. See `../launch/README.md` for reproducible rendering instructions.
