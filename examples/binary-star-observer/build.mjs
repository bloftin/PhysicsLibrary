import {build} from 'esbuild';
import {access,mkdir,readFile,writeFile} from 'node:fs/promises';
import {dirname,resolve,parse} from 'node:path';
import {fileURLToPath} from 'node:url';
const here=fileURLToPath(new URL('.',import.meta.url));
let inRepo=true;
try{await access(new URL('../../lib/Noosphere/ComputationalResources.pm',import.meta.url));}catch{inRepo=false;}
const site=fileURLToPath(new URL(inRepo?'../../data/examples/binary-star-observer/':'./dist/',import.meta.url));
await mkdir(site,{recursive:true});
const result=await build({entryPoints:[here+'explorer.js'],outfile:site+'viewer.js',bundle:true,format:'iife',platform:'browser',target:'es2020',minify:true,legalComments:'inline',metafile:true});
const packages=new Map();
for(const input of Object.keys(result.metafile.inputs)){
  if(!input.includes('node_modules'))continue;
  let folder=dirname(resolve(here,input));
  while(folder!==parse(folder).root){
    try{
      const pkg=JSON.parse(await readFile(resolve(folder,'package.json'),'utf8'));
      if(pkg.name){packages.set(pkg.name+'@'+pkg.version,{pkg,folder});break;}
    }catch{}
    folder=dirname(folder);
  }
}
let licenses='Original resource code: GPLv3 or later. Bundled software retains its own licenses.\n\n';
for(const [id,{pkg,folder}] of [...packages].sort(([a],[b])=>a.localeCompare(b))){
  let license;
  for(const name of ['LICENSE','LICENSE.md','LICENSE.txt','LICENSE-MIT']){
    try{license=await readFile(resolve(folder,name),'utf8');break;}catch{}
  }
  if(!license)throw new Error('Missing license for '+id);
  licenses+=`===== ${id} (${pkg.license}) =====\n${license}\n\n`;
}
licenses+='===== Transits.jl 0.4.1: offline kernel generation (MIT) =====\n'+await readFile(here+'TRANSITS-LICENSE.txt','utf8');
await writeFile(site+'THIRD-PARTY.txt',licenses.trimEnd()+'\n');
console.log('Bundled local viewer, limb kernel and '+packages.size+' dependency licenses:',site);
