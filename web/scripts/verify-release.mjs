import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const release=JSON.parse(readFileSync(path.join(root,'dist/downloads/release.json'),'utf8'));
for(const variant of release.variants){
  if(path.basename(variant.filename)!==variant.filename)throw new Error('Invalid release filename.');
  const bytes=readFileSync(path.join(root,'dist/downloads',variant.filename));
  const hash=createHash('sha256').update(bytes).digest('hex');
  if(bytes.length!==variant.bytes||hash!==variant.sha256||bytes.length>25*1024*1024)throw new Error('An APK does not match the committed metadata or hosting size limit. Rebuild and reattach it.');
  console.log(`Verified ${variant.architecture}: ${bytes.length} bytes; SHA-256 matches.`);
}
