"""Publish the saved Julia inclined-plane calculation and offline assets."""
import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import shutil
import zipfile
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / 'data/examples/inclined-plane'
IDS = ('frictionless', 'sliding', 'sticking')
SOURCES = ('motion.jl', 'cases.toml', 'Project.toml', 'Manifest.toml', 'test/runtests.jl',
           'test/viewer.cjs', 'build.py', 'verify.py', 'README.md', 'LICENSE.txt', 'COPYING',
           'article.tex', 'preamble.tex', 'preview.tex', 'computational-resources.json',
           'viewer.template.html', 'style.css', 'explorer.js')
ATTACHMENTS = ('article.tex', 'preamble.tex', 'computational-resources.json', 'README.md',
               'LICENSE.txt', 'inclined-plane-forces.png', 'comparison.png')

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def archive(path, files):
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, data)

def publish(site):
    from verify import check_case, offline_page
    config = tomllib.loads((HERE/'cases.toml').read_text())
    provenance = tomllib.loads((HERE/'results/provenance.toml').read_text())
    for section, root in (('inputs_sha256', HERE), ('outputs_sha256', HERE/'results')):
        for name, expected in provenance[section].items():
            if digest(root/name) != expected:
                raise ValueError('Regenerate Julia results: changed '+name)
    common = {k:v for k,v in config.items() if k != 'cases'}
    cases = []
    for raw in config['cases']:
        c = dict(common, **raw)
        theta = math.radians(c['angle_deg'])
        c['weight'] = c['mass']*c['gravity']
        c['normal'] = c['weight']*math.cos(theta)
        c['downhill'] = c['weight']*math.sin(theta)
        c['stuck'] = c['downhill'] <= c['mu_s']*c['normal']
        c['friction'] = c['downhill'] if c['stuck'] else c['mu_k']*c['normal']
        with (HERE/'results'/(c['id']+'.csv')).open() as f:
            reader = csv.reader(f)
            next(reader)
            c['rows'] = [[float(v) for v in r] for r in reader]
        c['duration'] = c['rows'][-1][0]
        check_case(c)
        cases.append(c)
    if tuple(c['id'] for c in cases) != IDS:
        raise ValueError('Update article and viewer before changing cases')
    site.mkdir(parents=True, exist_ok=True)
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon, FancyArrowPatch, Arc
    colors = ('#137b70', '#b23958', '#286caf')
    for mobile in (False, True):
        fig, axes = plt.subplots(3, 1, figsize=(4.3 if mobile else 10.8, 8.4), sharex=True)
        for ax, column, label in zip(axes, (1,2,6), ('Distance (m)', 'Speed (m/s)', 'Dissipated energy (J)')):
            for c, color, line in zip(cases, colors, ('-', '--', ':')):
                ax.plot([r[0] for r in c['rows']], [r[column] for r in c['rows']],
                        color=color, linestyle=line, linewidth=2, label=c['label'])
            ax.set_ylabel(label)
            ax.grid(color='#e2e8e4', linewidth=0.7)
            ax.spines[['top','right']].set_visible(False)
            ax.set_xlim(0,4)
        axes[0].legend(fontsize=8, loc='upper left', frameon=False)
        axes[-1].set_xlabel('Time since release (s)')
        fig.tight_layout()
        fig.savefig(site/('comparison-mobile.png' if mobile else 'comparison.png'), dpi=100)
        plt.close(fig)
    fig, ax = plt.subplots(figsize=(10,5.8))
    theta=math.pi/6
    sn,cs=math.sin(theta),math.cos(theta)
    ax.add_patch(Polygon([(0,5),(10*cs,0),(0,0)], facecolor='#e0e9e2', edgecolor='#5a7467'))
    x,y=3*cs,5-3*sn
    centre=(x+.3*sn,y+.3*cs)
    corners=[(centre[0]+u*cs+v*sn,centre[1]-u*sn+v*cs) for u,v in ((-.5,-.3),(.5,-.3),(.5,.3),(-.5,.3))]
    ax.add_patch(Polygon(corners,facecolor='#137b70'))
    c=cases[1]
    for dx,dy,color,label in ((0,-c['weight'],'#b23958','Weight mg'),
                              (c['normal']*sn,c['normal']*cs,'#286caf','Normal N'),
                              (-c['friction']*cs,c['friction']*sn,'#ad7908','Friction f')):
        end=(centre[0]+dx*.12,centre[1]+dy*.12)
        ax.add_patch(FancyArrowPatch(centre,end,arrowstyle='-|>',mutation_scale=18,color=color,linewidth=2))
        offset=(-1.45,.35) if label=='Friction f' else (.12,.1)
        ax.text(end[0]+offset[0],end[1]+offset[1],label,color=color,fontsize=12)
    ax.add_patch(Arc((10*cs,0),3,3,theta1=150,theta2=180,color='#5a7467'))
    ax.text(10*cs-2.1,.2,'30 degrees',fontsize=11)
    ax.text(5,2.6,'s positive downhill',rotation=-30,fontsize=12)
    ax.set(xlim=(-1,10),ylim=(-.5,7),aspect='equal')
    ax.axis('off')
    fig.tight_layout()
    fig.savefig(site/'inclined-plane-forces.png',dpi=130)
    plt.close(fig)
    for name in ('comparison.png','inclined-plane-forces.png'):
        shutil.copyfile(site/name,HERE/name)
    for name in ('style.css','explorer.js','LICENSE.txt','COPYING','article.tex'):
        shutil.copyfile(HERE/name,site/name)
    for name in [i+'.csv' for i in IDS]+['provenance.toml']:
        shutil.copyfile(HERE/'results'/name,site/name)
    logo=HERE.parents[1]/'data/images/physicslibrarylogotransparent.png'
    if not logo.is_file():
        logo=HERE/'viewer/logo.png'
    if logo.resolve() != (site/'logo.png').resolve():
        shutil.copyfile(logo,site/'logo.png')
    page=(HERE/'viewer.template.html').read_text().replace('@@VERSION@@',provenance['julia_version'])
    (site/'index.html').write_text(page,encoding='utf-8')
    (site/'trajectory-data.js').write_text('window.PLInclinedPlane = '+json.dumps(cases,allow_nan=False,separators=(',',':'))+';\n')
    assets=['index.html','trajectory-data.js','style.css','explorer.js','logo.png','comparison.png',
            'comparison-mobile.png','inclined-plane-forces.png','LICENSE.txt','COPYING','article.tex','provenance.toml']+[i+'.csv' for i in IDS]
    archive(site/'article-attachments.zip',{n:(HERE/n).read_bytes() for n in ATTACHMENTS})
    files={n:(HERE/n).read_bytes() for n in SOURCES}
    files.update({n:(HERE/n).read_bytes() for n in ('comparison.png','inclined-plane-forces.png')})
    files.update({'results/'+n:(HERE/'results'/n).read_bytes() for n in [i+'.csv' for i in IDS]+['provenance.toml']})
    files.update({'viewer/'+n:(site/n).read_bytes() for n in assets+['article-attachments.zip']})
    files['viewer/index.html']=offline_page(page).encode()
    archive(site/'inclined-plane.zip',files)
    assets+=['inclined-plane.zip','article-attachments.zip']
    report=dict(sources_sha256={n:digest(HERE/n) for n in SOURCES},files_sha256={n:digest(site/n) for n in assets})
    (site/'build.json').write_text(json.dumps(report,indent=2)+'\n')
    from verify import verify
    verify(site)

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=SITE)
    publish(parser.parse_args().output)
