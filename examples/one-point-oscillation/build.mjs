import {build} from 'esbuild';
import {access,mkdir,readFile,writeFile} from 'node:fs/promises';
import {dirname,resolve,parse} from 'node:path';
import {fileURLToPath} from 'node:url';
const here=fileURLToPath(new URL('.',import.meta.url));
let inRepo=true;
try{await access(new URL('../../lib/Noosphere/ComputationalResources.pm',import.meta.url));}catch{inRepo=false;}
const site=fileURLToPath(new URL(inRepo?'../../data/examples/one-point-oscillation/':'./dist/',import.meta.url));
await mkdir(site,{recursive:true});
const result=await build({entryPoints:[here+'explorer.js'],outfile:site+'viewer.js',bundle:true,format:'iife',platform:'browser',target:'es2020',minify:true,legalComments:'inline',metafile:true});
const packages=new Map();
const inputs=new Set(Object.values(result.metafile.outputs).flatMap(output=>Object.entries(output.inputs).filter(([,v])=>v.bytesInOutput>0).map(([name])=>name)));
for(const input of inputs){
  if(!input.includes('node_modules'))continue;
  let folder=dirname(resolve(here,input));
  while(folder!==parse(folder).root){
    try{const pkg=JSON.parse(await readFile(resolve(folder,'package.json'),'utf8'));if(pkg.name){packages.set(pkg.name+'@'+pkg.version,{pkg,folder});break;}}catch{}
    folder=dirname(folder);
  }
}
let licenses='Original resource code: GPLv3 or later. Bundled software retains its own licenses.\n\n';
for(const [id,{pkg,folder}] of [...packages].sort(([a],[b])=>a.localeCompare(b))){
  let license;for(const name of ['LICENSE','LICENSE.md','LICENSE.txt','LICENSE-MIT','LICENCE','LICENCE.md']){try{license=await readFile(resolve(folder,name),'utf8');break;}catch{}}
  if(!license)throw new Error('Missing license for '+id);
  licenses+=`===== ${id} (${pkg.license}) =====\n${license}\n\n`;
}
licenses+='===== fmin bisect (BSD-3-Clause; commit 6b155c9f4a6ecf73ea5d71666da8e5dcd418b18b) =====\n'+await readFile(here+'vendor/LICENSE.fmin','utf8')+'\n';
await writeFile(site+'THIRD-PARTY.txt',licenses.replace(/\r\n/g,'\n').trimEnd()+'\n');
console.log('Bundled offline viewer and '+packages.size+' dependency licenses:',site);
