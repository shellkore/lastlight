"""Generate RepLock's own arrow mark at platform icon sizes."""
from pathlib import Path
import json,sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.tools/video-deps'))
from PIL import Image,ImageDraw
def icon(file,size):
    scale=4;canvas=Image.new('RGB',(size*scale,size*scale),'#d3ff4d');d=ImageDraw.Draw(canvas)
    pts=[(28,29),(71,29),(71,72),(59,72),(59,50),(34,75),(25,66),(50,41),(28,41)]
    d.polygon([(int(x/100*size*scale),int(y/100*size*scale)) for x,y in pts],fill='#151a13')
    file.parent.mkdir(parents=True,exist_ok=True);canvas.resize((size,size),Image.Resampling.LANCZOS).save(file)
ios=root/'mobile-replock/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((ios/'Contents.json').read_text())['images']:
    if 'filename' in entry:icon(ios/entry['filename'],round(float(entry['size'].split('x')[0])*float(entry['scale'].replace('x',''))))
for size in (192,512):
    for name in (f'Icon-{size}.png',f'Icon-maskable-{size}.png'):icon(root/'mobile-replock/web/icons'/name,size)
icon(root/'mobile-replock/web/favicon.png',64)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:icon(root/f'mobile-replock/android/app/src/main/res/mipmap-{density}/ic_launcher.png',size)
print('Generated platform icons from the RepLock arrow mark.')
