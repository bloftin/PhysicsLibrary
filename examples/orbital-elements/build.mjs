import { build } from 'esbuild';
import { mkdir, writeFile, readFile, access } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const here=fileURLToPath(new URL('.',import.meta.url));
let inRepo=true;
try{await access(new URL('../../lib/Noosphere/ComputationalResources.pm',import.meta.url));}catch{inRepo=false;}
const site=fileURLToPath(new URL(inRepo?'../../data/examples/orbital-elements/':'./dist/',import.meta.url));
await mkdir(site,{recursive:true});
await build({entryPoints:[here+'explorer.js'],outfile:site+'viewer.js',bundle:true,format:'iife',platform:'browser',target:'es2020',minify:true,legalComments:'inline'});
const packages=['three','astronomia','lucide'];
let licenses='Bundled third-party software. Original resource code: GPLv3 or later.\n\n';
for(const name of packages){
  const root=here+'node_modules/'+name+'/';
  const pkg=JSON.parse(await readFile(root+'package.json','utf8'));
  let license;
  for(const file of ['LICENSE','LICENSE.md','LICENSE.txt']){
    try{license=await readFile(root+file,'utf8');break;}catch{}
  }
  if(!license)throw new Error('Missing license for '+name);
  licenses+=`===== ${name} ${pkg.version} (${pkg.license}) =====\n${license}\n\n`;
}
await writeFile(site+'THIRD-PARTY.txt',licenses.trimEnd()+'\n');
console.log('Bundled offline viewer and dependency licenses:',site);
