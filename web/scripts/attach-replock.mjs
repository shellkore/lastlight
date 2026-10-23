import {copyFileSync, mkdirSync, readFileSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const input = process.argv[2];
if(!input || !path.isAbsolute(input)) throw Error('Pass the absolute split-APK build directory.');
const out = path.join(root,'dist/replock/downloads');mkdirSync(out,{recursive:true});
const variants = [['arm64-v8a','arm64','ARM64'],['armeabi-v7a','arm32','ARM32'],['x86_64','x86_64','x86-64']].map(([abi,suffix,architecture]) => {
  const source=path.join(input,`app-${abi}-release.apk`), bytes=readFileSync(source);
  if(bytes[0]!==0x50||bytes[1]!==0x4b) throw Error('Invalid APK.');
  if(bytes.length>25*1024*1024) throw Error(`${abi} exceeds the Sites asset limit. Enable compressed native libraries before building.`);
  const filename=`replock-0.1.0-${suffix}.apk`;
  copyFileSync(source,path.join(out,filename));
  return {abi,architecture,filename,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')};
});
writeFileSync(path.join(out,'release.json'),JSON.stringify({version:'0.1.0',build:1,minAndroid:'8.0',channel:'early-access',signing:'development-key',builtAt:new Date().toISOString(),variants},null,2)+'\n');
console.log(variants.map(v=>`${v.architecture}: ${(v.bytes/1024/1024).toFixed(1)} MiB`).join('\n'));
