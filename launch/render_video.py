"""Render the original RepLock launch film. Uses Pillow + imageio-ffmpeg.

python -m pip install --target .tools/video-deps pillow imageio-ffmpeg
python launch/render_video.py
Screens are captured from real Flutter widgets by mobile-replock/tool/capture_screens.dart.
Their values are illustrative demo data; the film labels them accordingly.
"""
from pathlib import Path
import sys, math, subprocess, wave
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/video-deps'))
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import imageio_ffmpeg

W, H, FPS, DURATION = 1920, 1080, 30, 40
INK, LIME, CREAM, ORANGE = '#151a13', '#d3ff4d', '#f5f5ee', '#ff784f'
OUT = ROOT / 'web/dist/replock/media'
OUT.mkdir(parents=True, exist_ok=True)
RENDER = ROOT / 'launch/render'
RENDER.mkdir(parents=True, exist_ok=True)
FONT_DIR = ROOT / '.tools/flutter/bin/cache/artifacts/material_fonts'
fonts = {}
def font(size, heavy=False, condensed=False):
    key = (size, heavy, condensed)
    if key not in fonts:
        filename = 'robotocondensed-bold.ttf' if condensed else 'roboto-black.ttf' if heavy else 'roboto-regular.ttf'
        fonts[key] = ImageFont.truetype(str(FONT_DIR / filename), size)
    return fonts[key]
def text(draw, xy, value, size=28, fill=INK, heavy=False, condensed=False, spacing=4):
    for i,line in enumerate(value.split('\n')):
        draw.text((xy[0],xy[1]+i*(size+spacing)), line, font=font(size,heavy,condensed), fill=fill, anchor='lt')
def ease(x): return 1-(1-max(0,min(1,x)))**3
def roundrect(draw, box, color, radius=28, outline=None, width=1): draw.rounded_rectangle(box,radius=radius,fill=color,outline=outline,width=width)
def arrow(draw,x,y,s,color,width=18):
    draw.line([(x,y+s),(x+s,y)],fill=color,width=width)
    draw.line([(x+s*.28,y),(x+s,y),(x+s,y+s*.72)],fill=color,width=width)
def star(draw,cx,cy,r,color,rotation=0):
    points=[]
    for i in range(24):
        a=i*math.pi/12+rotation;rad=r if i%2==0 else r*.61
        points.append((cx+math.cos(a)*rad,cy+math.sin(a)*rad))
    draw.polygon(points,fill=color)
screens={name:Image.open(ROOT/f'launch/screens/{name}.png').convert('RGB') for name in ['onboarding','move','unlock','pass','activity']}
def phone(image,draw,name,x=1335,y=112,height=870,angle=0):
    shot=screens[name]
    width=round(height*shot.width/shot.height)
    layer=Image.new('RGBA',(width+40,height+40),(0,0,0,0)); ld=ImageDraw.Draw(layer)
    roundrect(ld,(0,0,width+39,height+39),INK,55)
    content=shot.resize((width,height),Image.Resampling.LANCZOS)
    mask=Image.new('L',(width,height),0); ImageDraw.Draw(mask).rounded_rectangle((0,0,width-1,height-1),radius=38,fill=255)
    layer.paste(content,(20,20),mask)
    if angle: layer=layer.rotate(angle,resample=Image.Resampling.BICUBIC,expand=True)
    image.paste(layer,(int(x),int(y)),layer)
def chrome(draw,t,color=INK):
    arrow(draw,96,60,42,color,10);text(draw,(156,59),'replock',46,color,True)
    text(draw,(1445,68),'MOVE / EARN / UNLOCK',20,color,True)
    draw.line((96,1015,1824,1015),fill=color,width=1)
    text(draw,(98,1033),'ANDROID EARLY ACCESS',17,color,True)
    text(draw,(1420,1033),'LESS THUMB. MORE YOU.',17,color,True)
    draw.rectangle((96,1013,96+1728*t/DURATION,1017),fill=ORANGE)
def badge(draw,xy,value,bg=LIME,fg=INK):
    x,y=xy;f=font(23,True);width=int(draw.textlength(value,font=f))+42
    roundrect(draw,(x,y,x+width,y+52),bg,12);text(draw,(x+21,y+14),value,23,fg,True)
def scene(t):
    if t<4: return 0,t,4
    if t<10:return 1,t-4,6
    if t<18:return 2,t-10,8
    if t<23:return 3,t-18,5
    if t<29:return 4,t-23,6
    if t<35:return 5,t-29,6
    return 6,t-35,5

def frame(t):
    idx,local,length=scene(t)
    dark=idx in (0,3,6); bg=INK if dark else CREAM
    image=Image.new('RGB',(W,H),bg);d=ImageDraw.Draw(image)
    fg=CREAM if dark else INK
    chrome(d,t,fg)
    offset=round(65*(1-ease(local/.55)))
    if idx==0:
        star(d,1510,545,272,LIME,local*.08)
        arrow(d,1400,440,205,INK,43)
        text(d,(100,240+offset),'MOVE FIRST.',155,CREAM,True,True)
        text(d,(100,417+offset),'SCROLL LATER.',155,LIME,True,True)
        text(d,(108,660),'Turn one more reel into one more rep.',38,CREAM)
        badge(d,(108,800),'MEET REPLOCK',ORANGE)
    elif idx==1:
        d.ellipse((1240,215,1900,875),fill=LIME)
        phone(image,d,'move',x=1340+offset,y=100,height=865,angle=-4)
        text(d,(106,220),'01 / PICK YOUR ENERGY',23,INK,True)
        text(d,(100,290+offset),'CHOOSE YOUR\nCHALLENGE.',124,INK,True,True,8)
        text(d,(108,600),'Squats. Jumping jacks. Knee raises.',34,INK)
        badge(d,(108,705),'10 SQUATS = 20 COINS')
        text(d,(108,900),'Real Flutter screens / illustrative demo data',21,'#687060')
    elif idx==2:
        text(d,(106,230),'02 / LET YOUR MOVEMENT COUNT',23,INK,True)
        text(d,(100,305+offset),'REAL REPS.\nREAL REWARDS.',118,INK,True,True,6)
        text(d,(108,600),'Your phone verifies each complete rep.',32,INK)
        text(d,(108,660),'Camera frames stay on your device.',29,'#687060')
        badge(d,(108,775),'NO RECORDING. NO UPLOADS.',INK,LIME)
        roundrect(d,(1220,180,1800,915),INK,40)
        # Stylized skeleton shows full-cycle verification, not actual captured footage.
        squatting=(1-math.cos(local*2*math.pi*1.25))/2
        head=(1510,330+95*squatting);shoulder=(1510,400+85*squatting);hip=(1495-70*squatting,580+50*squatting)
        knee=(1495+70*squatting,715);ankle=(1495,850)
        pts=[shoulder,hip,knee,ankle]
        d.line(pts,fill=LIME,width=22,joint='curve');d.ellipse((head[0]-32,head[1]-32,head[0]+32,head[1]+32),fill=LIME)
        d.line([shoulder,(1570,495+45*squatting),(1660,475+45*squatting)],fill=LIME,width=19,joint='curve')
        for x,y in pts:d.ellipse((x-13,y-13,x+13,y+13),fill=ORANGE)
        count=min(10,int(local*1.25));text(d,(1270,224),f'{count:02} / 10',44,LIME,True)
        text(d,(1255,940),'CAMERA VERIFICATION / ILLUSTRATION',18,'#687060')
    elif idx==3:
        star(d,1480,550,260,ORANGE,-local*.08)
        text(d,(1280,460),'+20',135,INK,True,True)
        text(d,(1360,615),'COINS',38,INK,True)
        text(d,(106,220),'03 / THAT FEELING? YOU EARNED IT.',23,LIME,True)
        text(d,(100,310+offset),'YOU\nDID THAT.',149,CREAM,True,True,4)
        text(d,(108,715),'A little movement. A fresh start.',36,CREAM)
        badge(d,(108,830),'YOUR NEXT BREAK IS YOURS.',LIME)
    elif idx==4:
        d.ellipse((1170,200,1850,880),fill=ORANGE)
        phone(image,d,'pass',x=1335+offset,y=100,height=865,angle=3)
        text(d,(106,220),'04 / TAKE A BREAK WITH A BOUNDARY',23,INK,True)
        text(d,(100,300+offset),'10 COINS.\n5 MINUTES.',131,INK,True,True,6)
        text(d,(108,635),'Choose an app. Enjoy your earned time.',32,INK)
        text(d,(108,695),'When time is up, the shield is back.',29,'#687060')
        badge(d,(108,800),'5 / 10 / 15 MINUTE PASSES')
        text(d,(108,920),'Timer starts at redemption / illustrative app state',20,'#687060')
    elif idx==5:
        d.ellipse((1190,220,1880,910),fill=LIME)
        phone(image,d,'activity',x=1340+offset,y=100,height=865,angle=-3)
        text(d,(106,220),'MORE OF A WALKER? THAT COUNTS.',23,INK,True)
        text(d,(100,305+offset),'500 STEPS.\n5 COINS.',135,INK,True,True,6)
        text(d,(108,635),'Turn your everyday movement into coins.',31,INK)
        text(d,(108,695),'Opt in. Track your steps. Claim your reward.',28,'#687060')
        badge(d,(108,800),'YOUR PACE. YOUR CHOICE.')
        text(d,(108,920),'Tracked from activation / sensor availability varies',20,'#687060')
    else:
        star(d,1515,540,265,LIME,local*.07);arrow(d,1410,435,200,INK,42)
        text(d,(106,220),'YOUR FIRST REP IS WAITING',24,LIME,True)
        text(d,(100,315+offset),'GET UP.\nGET GOING.',152,CREAM,True,True,3)
        text(d,(108,700),'RepLock for Android. Early access is here.',33,CREAM)
        badge(d,(108,805),'GET REPLOCK AT THE LINK BELOW',LIME)
        text(d,(108,920),'Move comfortably. Pause protection whenever you need.',21,'#b4bfaa')
    # Smooth short branded wipe between scenes, not a flashing cut.
    if 0<local<.18 and idx>0:
        right=int(W*(1-ease(local/.18)));d.rectangle((0,0,right,H),fill=LIME)
    return image

def music():
    rate=48000;n=rate*DURATION;rng=np.random.default_rng(7);mix=np.zeros(n,dtype=np.float64)
    def add(start,sound,gain=1):
        a=int(start*rate);b=min(n,a+len(sound));mix[a:b]+=sound[:b-a]*gain
    # Original 120 BPM percussion, bass and pluck pattern. No sampled/third-party music.
    for beat in np.arange(0,DURATION,.5):
        tt=np.arange(int(.36*rate))/rate
        kick=np.sin(2*np.pi*(46*tt+85*.038*(1-np.exp(-tt/.038))))*np.exp(-tt*12)
        add(beat,kick,.62)
        if int(round(beat*2))%2:
            tt=np.arange(int(.16*rate))/rate;add(beat,rng.normal(size=len(tt))*np.exp(-tt*29),.11)
        for shift in (0,.25):
            tt=np.arange(int(.055*rate))/rate;noise=rng.normal(size=len(tt));noise=np.concatenate(([0],np.diff(noise)))
            add(beat+shift,noise*np.exp(-tt*80),.028)
        notes=[73.416,73.416,87.307,65.406,55,55,65.406,87.307]
        freq=notes[int(beat//2)%len(notes)];tt=np.arange(int(.38*rate))/rate
        bass=(np.sin(2*np.pi*freq*tt)+.18*np.sin(4*np.pi*freq*tt))*np.minimum(1,tt*80)*np.exp(-tt*8)
        add(beat,bass,.18)
        if 4<=beat<35 and int(beat*2)%2==0:
            melody=[293.665,349.228,440,523.251,440,349.228,261.626,293.665]
            f=melody[int(beat)%len(melody)];tt=np.arange(int(.6*rate))/rate
            pluck=(np.sin(2*np.pi*f*tt)+.3*np.sin(2*np.pi*f*2*tt))*np.minimum(1,tt*120)*np.exp(-tt*7)
            add(beat,pluck,.09);add(beat+.25,pluck,.025)
    fade=np.minimum(1,np.arange(n)/rate/.25)*np.minimum(1,(n-1-np.arange(n))/rate/1.4)
    mix=np.tanh(mix)*fade*.75
    stereo=np.column_stack((mix,np.roll(mix,17)*.96));pcm=(stereo*32767).astype('<i2')
    audio=RENDER/'original-score.wav'
    with wave.open(str(audio),'wb') as out:out.setnchannels(2);out.setsampwidth(2);out.setframerate(rate);out.writeframes(pcm.tobytes())
    return audio

def main():
    audio=music();output=OUT/'replock-launch.mp4'
    ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
    args=[ffmpeg,'-y','-f','rawvideo','-vcodec','rawvideo','-s',f'{W}x{H}','-pix_fmt','rgb24','-r',str(FPS),'-i','-','-i',str(audio),'-c:v','libx264','-preset','fast','-crf','22','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-movflags','+faststart','-t',str(DURATION),str(output)]
    log=open(RENDER/'ffmpeg.log','w',encoding='utf8');proc=subprocess.Popen(args,stdin=subprocess.PIPE,stderr=log,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    try:
        for i in range(DURATION*FPS):
            image=frame(i/FPS);proc.stdin.write(image.tobytes())
            if i%180==0:print(f'Rendered {i//FPS}/{DURATION} seconds',flush=True)
    finally:proc.stdin.close()
    code=proc.wait();log.close()
    if code:raise RuntimeError('FFmpeg failed. See launch/render/ffmpeg.log')
    for moment in (2,7,14,20,26,32,37):frame(moment).save(RENDER/f'frame-{moment:02}.jpg',quality=90)
    frame(2).save(OUT/'launch-poster.jpg',quality=94)
    print(f'Created {output} ({output.stat().st_size/1024/1024:.1f} MiB)',flush=True)

if __name__=='__main__':main()
