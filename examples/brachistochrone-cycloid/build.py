"""Publish saved brachistochrone results; never execute Julia or accept web input."""
import argparse, csv, hashlib, json, shutil, zipfile
from pathlib import Path
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

HERE=Path(__file__).resolve().parent
DEFAULT_SITE=HERE.parents[1]/'data'/'examples'/'brachistochrone-cycloid'
IDS=("before-bottom","at-bottom","after-bottom")
INPUTS=("brachistochrone.jl","cases.toml","Project.toml","Manifest.toml")
SOURCES=INPUTS+("test/runtests.jl","test/viewer.cjs","README.md","LICENSE.txt","article.tex","preamble.tex","preview.tex","build.py","verify.py","viewer.template.html","style.css","explorer.js","computational-resources.json","catalog-entry.json")
DATASETS=tuple(f"{i}.csv" for i in IDS)+("endpoint-sweep.csv","root-history.csv","time-convergence.csv")

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def read_toml(path):
    with path.open('rb') as f:return tomllib.load(f)

def load_csv(path, numeric=True):
    with path.open(newline='') as f:
        rows=list(csv.DictReader(f))
    if not numeric:return rows
    out=[]
    for row in rows:
        out.append({k:(v if k=='case_id' else float(v)) for k,v in row.items()})
    return out

def load_data(allow_draft=False):
    prov=read_toml(HERE/'results/provenance.toml')
    if prov.get('generator')!='julia' and not allow_draft:
        raise ValueError('Draft reference data: run Julia first, or use --allow-draft for local preview')
    for name in INPUTS:
        expected=prov.get('inputs_sha256',{}).get(name)
        if expected and digest(HERE/name)!=expected:
            raise ValueError(f'Changed {name}; regenerate results/provenance before publishing')
    for name in DATASETS:
        expected=prov.get('outputs_sha256',{}).get(name)
        if expected and digest(HERE/'results'/name)!=expected:
            raise ValueError(f'Changed {name}; regenerate results/provenance before publishing')
    data={i:load_csv(HERE/'results'/f'{i}.csv') for i in IDS}
    roots=load_csv(HERE/'results'/'root-history.csv')
    conv=load_csv(HERE/'results'/'time-convergence.csv')
    return prov,data,roots,conv

def archive(path, mapping):
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        for name,data in sorted(mapping.items()):
            info=zipfile.ZipInfo(name,(2026,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,data)

def draw_static(site,data,meta,roots,conv):
    import matplotlib;matplotlib.use('Agg');import matplotlib.pyplot as plt
    for id in IDS:
        rows=data[id];m=meta[id]
        fig,ax=plt.subplots(figsize=(6.1,4.0));ax.plot([r['x_m'] for r in rows],[r['y_m'] for r in rows],linewidth=2.4);ax.plot([0,m['X']],[0,m['Y']],linestyle='--',linewidth=1.7);ax.scatter([m['X']],[m['Y']],s=35);ax.invert_yaxis();ax.set_xlabel('x (m)');ax.set_ylabel('depth y (m)');ax.grid(True,linewidth=.6);ax.set_title(m['label'],loc='left');fig.tight_layout();fig.savefig(site/f'{id}.png',dpi=110);plt.close(fig)
    fig,ax=plt.subplots(figsize=(6.1,3.3))
    for id in IDS:
        rows=data[id];ax.plot([r['x_m'] for r in rows],[r['y_m'] for r in rows],linewidth=2.2,label=meta[id]['short'])
    ax.invert_yaxis();ax.set_xlabel('x (m)');ax.set_ylabel('depth y (m)');ax.grid(True,linewidth=.6);ax.legend(frameon=False);fig.tight_layout();fig.savefig(site/'comparison.png',dpi=110);plt.close(fig)
    id='after-bottom';rows=data[id];m=meta[id]
    fig,ax=plt.subplots(figsize=(6.4,4.1));ax.plot([r['x_m'] for r in rows],[r['y_m'] for r in rows],linewidth=2.5,label='cycloid');ax.plot([0,m['X']],[0,m['Y']],linestyle='--',linewidth=2,label='straight line');ax.scatter([m['X']],[m['Y']],s=35);ax.invert_yaxis();ax.set_xlabel('x (m)');ax.set_ylabel('depth y (m)');ax.grid(True,linewidth=.6);ax.legend(frameon=False);fig.tight_layout();fig.savefig(site/'path-straight.png',dpi=110);plt.close(fig)
    crows=[r for r in conv if r['case_id']==id]
    fig,ax=plt.subplots(figsize=(6.4,4.1));ax.loglog([r['segments'] for r in crows],[abs(r['relative_error'])*100 for r in crows],marker='o');ax.set_xlabel('segments');ax.set_ylabel('absolute relative error (%)');ax.grid(True,which='both',linewidth=.6);fig.tight_layout();fig.savefig(site/'time-convergence.png',dpi=110);plt.close(fig)
    rrows=[r for r in roots if r['case_id']==id]
    fig,ax=plt.subplots(figsize=(6.4,4.1));ax.semilogy([r['iteration'] for r in rrows],[max(abs(r['residual']),1e-16) for r in rrows],marker='o',markersize=3);ax.set_xlabel('bisection iteration');ax.set_ylabel('|R(theta_mid) - X/Y|');ax.grid(True,which='both',linewidth=.6);fig.tight_layout();fig.savefig(site/'root-solve.png',dpi=110);plt.close(fig)

def publish(site,allow_draft=False):
    prov,data,roots,conv=load_data(allow_draft)
    from verify import verify_results
    summary=verify_results(HERE/'results')
    site.mkdir(parents=True,exist_ok=True)
    meta=summary['cases']
    draw_static(site,data,meta,roots,conv)
    for name in DATASETS:
        shutil.copyfile(HERE/'results'/name,site/name)
    shutil.copyfile(HERE/'results'/'provenance.toml',site/'provenance.toml')
    for name in ('style.css','explorer.js','LICENSE.txt'):
        shutil.copyfile(HERE/name,site/name)
    by_root={i:[] for i in IDS};by_conv={i:[] for i in IDS}
    for r in roots:by_root[r['case_id']].append(r)
    for r in conv:by_conv[r['case_id']].append(r)
    js={'version':2,'cases':{}}
    for id in IDS:
        m=meta[id]
        js['cases'][id]={**m,
            'rows':[{'theta':r['theta_rad'],'x':r['x_m'],'y':r['y_m'],'t':r['time_s'],'v':r['speed_m_s']} for r in data[id]],
            'convergence':[{'segments':int(r['segments']),'time':r['time_estimate_s'],'exact':r['exact_time_s'],'absolute_error':r['absolute_error_s'],'relative_error':r['relative_error']} for r in by_conv[id]],
            'root_history':[{'iteration':int(r['iteration']),'lo':r['lo_rad'],'hi':r['hi_rad'],'mid':r['mid_rad'],'ratio':r['ratio_mid'],'target':r['target_ratio'],'residual':r['residual'],'width':r['bracket_width_rad']} for r in by_root[id]]}
    (site/'trajectory-data.js').write_text('window.PLBrachistochrone = '+json.dumps(js,separators=(',',':'),allow_nan=False)+';\n',encoding='utf-8')
    page=(HERE/'viewer.template.html').read_text(encoding='utf-8').replace('@@JULIA_VERSION@@',prov.get('julia_version','draft'))
    (site/'index.html').write_text(page.replace('@@ZIP_SIZE@@','ZIP'),encoding='utf-8')
    public_names=['index.html','trajectory-data.js','style.css','explorer.js','comparison.png','path-straight.png','time-convergence.png','root-solve.png','provenance.toml','LICENSE.txt']+list(DATASETS)+[f'{i}.png' for i in IDS]
    bundle={name:(HERE/name).read_bytes() for name in SOURCES}
    bundle.update({'results/'+name:(HERE/'results'/name).read_bytes() for name in DATASETS+('provenance.toml',)})
    for name in public_names:
        if name == 'index.html':
            offline=(site/name).read_text(encoding='utf-8')
            offline=offline.replace('href="brachistochrone-cycloid.zip"','href="../README.md"').replace('Download Julia project','Project README')
            bundle['viewer/'+name]=offline.encode('utf-8')
        else:
            bundle['viewer/'+name]=(site/name).read_bytes()
    bundle['comparison.png']=(site/'comparison.png').read_bytes()
    archive(site/'brachistochrone-cycloid.zip',bundle)
    kb=(site/'brachistochrone-cycloid.zip').stat().st_size/1024
    (site/'index.html').write_text(page.replace('@@ZIP_SIZE@@',f'{kb:.0f} KB'),encoding='utf-8')
    assets=public_names+['brachistochrone-cycloid.zip']
    report={'sources_sha256':{name:digest(HERE/name) for name in SOURCES},'files_sha256':{name:digest(site/name) for name in assets}}
    (site/'build.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    from verify import verify
    verify(site)
    print(f'Published static preview to {site} ({kb:.0f} KiB source ZIP)')

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--output',type=Path,default=DEFAULT_SITE);ap.add_argument('--allow-draft',action='store_true');args=ap.parse_args();publish(args.output,args.allow_draft)
