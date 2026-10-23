import { copyFileSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const input = process.argv[2];
if (!input || !path.isAbsolute(input)) throw new Error('Pass the absolute path of the built APK.');
const bytes = readFileSync(input);
if (bytes[0] !== 0x50 || bytes[1] !== 0x4b) throw new Error('APK must be an Android ZIP package.');
mkdirSync(path.join(root, 'dist/downloads'), {recursive:true});
const filename = 'lastlight-0.1.0.apk';
copyFileSync(input, path.join(root, 'dist/downloads', filename));
const data = {version:'0.1.0', build:1, filename, bytes:statSync(input).size,
  sha256:createHash('sha256').update(bytes).digest('hex'), minAndroid:'8.0', channel:'early-access',
  builtAt:new Date().toISOString()};
writeFileSync(path.join(root,'dist/downloads/release.json'),JSON.stringify(data,null,2)+'\n');
console.log(JSON.stringify(data));
