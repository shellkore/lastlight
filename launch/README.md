# RepLock launch film

`web/dist/replock/media/replock-launch.mp4` is a 40-second 1920×1080 H.264/AAC launch film with original synthesized music, kinetic typography, original vector illustrations, and real Flutter screen captures. The screen values are illustrative; the camera segment is explicitly labeled as an illustration. It contains no footage of a person and no third-party music samples.

Reproduce from repository root:

```powershell
python -m pip install --target .tools/video-deps pillow imageio-ffmpeg
cd mobile-replock
../.tools/flutter/bin/flutter.bat test tool/capture_screens.dart
cd ..
python launch/render_video.py
```

`render_video.py` also creates a poster and representative frames for visual QA. Its original score and temporary rendered frames are in ignored `launch/render/`. The font sources are Flutter's bundled Roboto/Roboto Condensed fonts; text is rendered into the video. Platform icon generation uses `scripts/generate-replock-icons.py`.

English captions are in `web/dist/replock/media/launch.vtt`. The verified YouTube URL and upload state are stored in `web/dist/replock/launch.json`. The landing page only exposes a YouTube link when that file contains a valid video URL.
