import { copyFileSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const input = process.argv[2];
if (!input || !path.isAbsolute(input)) throw new Error('Pass the absolute path of the split-APK output directory.');
const directory = statSync(input).isDirectory() ? input : path.dirname(input);
mkdirSync(path.join(root, 'dist/downloads'), {recursive:true});
const definitions = [
  ['arm64-v8a','arm64','ARM64'],
  ['armeabi-v7a','arm32','ARM32'],
  ['x86_64','x86_64','x86-64'],
];
const variants = definitions.map(([abi,suffix,label]) => {
  const source = path.join(directory, `app-${abi}-release.apk`);
  const bytes=readFileSync(source);
  if(bytes[0]!==0x50||bytes[1]!==0x4b)throw new Error(`Invalid Android package: ${abi}`);
  if(bytes.length>25*1024*1024)throw new Error(`${abi} exceeds the hosting per-file limit.`);
  return {abi,architecture:label,filename:`lastlight-0.1.0-${suffix}.apk`,bytes:bytes.length,
    sha256:createHash('sha256').update(bytes).digest('hex'),source};
});
for(const variant of variants)copyFileSync(variant.source,path.join(root,'dist/downloads',variant.filename));
const clean=variants.map(({source,...variant})=>variant);
const data = {version:'0.1.0', build:1, ...clean[0], variants:clean, minAndroid:'8.0', channel:'early-access',
  builtAt:new Date().toISOString()};
writeFileSync(path.join(root,'dist/downloads/release.json'),JSON.stringify(data,null,2)+'\n');
console.log(JSON.stringify(data));
