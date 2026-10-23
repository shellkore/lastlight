import {readFileSync, existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../dist/replock');
const release=JSON.parse(readFileSync(path.join(root,'downloads/release.json'),'utf8'));
if(release.version!=='0.1.0'||release.variants.length!==3)throw Error('Unexpected RepLock release manifest.');
for(const variant of release.variants){
  if(path.basename(variant.filename)!==variant.filename)throw Error('Invalid filename.');
  const bytes=readFileSync(path.join(root,'downloads',variant.filename));
  if(bytes.length!==variant.bytes||createHash('sha256').update(bytes).digest('hex')!==variant.sha256||bytes.length>25*1024*1024)throw Error('RepLock APK verification failed.');
  console.log(`Verified RepLock ${variant.architecture}`);
}
const html=readFileSync(path.join(root,'index.html'),'utf8');
for(const match of html.matchAll(/(?:href|src)="([^"#]+)"/g)){
  const value=match[1];if(/^(https?:|data:)/.test(value))continue;
  const target=path.resolve(root,value.split('#')[0]);
  if(!existsSync(target))throw Error(`Missing landing-page asset: ${value}`);
}
const launch=JSON.parse(readFileSync(path.join(root,'launch.json'),'utf8'));
if(!/^https:\/\/(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)[\w-]{11}$/.test(launch.youtubeUrl||''))throw Error('The verified YouTube launch link has not been attached.');
console.log('Landing-page assets and YouTube URL verified.');
