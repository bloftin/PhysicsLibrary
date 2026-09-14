"""Verify saved brachistochrone CSVs and publication artifacts without Julia."""
import csv, math, sys, json, hashlib, zipfile
from html.parser import HTMLParser
from pathlib import Path
HERE=Path(__file__).resolve().parent
DEFAULT_SITE=HERE.parents[1]/'data/examples/brachistochrone-cycloid'
IDS=("before-bottom","at-bottom","after-bottom")

def ratio(theta):
    if abs(theta)<1e-4:return theta/3+theta**3/90+theta**5/2520+theta**7/75600
    return (theta-math.sin(theta))/(1-math.cos(theta))
def solve_ratio(r):
    lo,hi=1e-12,2*math.pi-1e-10
    for _ in range(200):
        m=(lo+hi)/2
        if ratio(m)<r:lo=m
        else:hi=m
        if hi-lo<=1e-13*max(1.0,abs(m)):return m
    raise AssertionError('root did not converge')
def segment_time(thetaB,a,g,n):
    total=0.;x0=y0=0.
    for k in range(1,n+1):
        th=thetaB*k/n;x1=a*(th-math.sin(th));y1=a*(1-math.cos(th));total+=math.hypot(x1-x0,y1-y0)/math.sqrt(2*g*((y0+y1)/2));x0,y0=x1,y1
    return total
def rows(path):
    with path.open(newline='') as f:return list(csv.DictReader(f))

def verify_results(results=HERE/'results', cfg=None):
    if cfg is None:
        try:
            import tomllib
        except ModuleNotFoundError:
            import tomli as tomllib
        with (HERE/'cases.toml').open('rb') as f:cfg=tomllib.load(f)
    g=cfg['model']['gravity'];meta={}
    for c in cfg['cases']:
        id=c['id'];X,Y=c['x'],c['y'];th=solve_ratio(X/Y);a=Y/(1-math.cos(th));T=th*math.sqrt(a/g);line=math.sqrt(2*(X*X+Y*Y)/(g*Y));lt=math.sqrt(2*Y/g)+X/math.sqrt(2*g*Y);deep=Y if th<=math.pi else 2*a
        data=[{k:float(v) for k,v in r.items()} for r in rows(results/f'{id}.csv')]
        assert len(data)==cfg['model']['samples'];assert abs(data[0]['x_m'])<1e-14 and abs(data[0]['y_m'])<1e-14
        assert abs(data[-1]['x_m']-X)<2e-9 and abs(data[-1]['y_m']-Y)<2e-9 and abs(data[-1]['time_s']-T)<2e-9
        assert all(r['y_m']>=-1e-12 and r['speed_m_s']>=-1e-12 for r in data)
        for r in data[1:]: assert abs(r['speed_m_s']**2-2*g*r['y_m'])<2e-8
        meta[id]={'label':c['label'],'short':id.replace('-',' '),'X':X,'Y':Y,'thetaB':th,'a':a,'time':T,'line_time':line,'l_time':lt,'deepest':deep}
    sweep=rows(results/'endpoint-sweep.csv');assert len(sweep)==46
    rootrows=rows(results/'root-history.csv')
    convrows=rows(results/'time-convergence.csv')
    for id in IDS:
        m=meta[id];rr=[r for r in rootrows if r['case_id']==id];assert 40<=len(rr)<=60
        prev_width=float('inf')
        for j,r in enumerate(rr,1):
            it=int(r['iteration']);lo=float(r['lo_rad']);hi=float(r['hi_rad']);mid=float(r['mid_rad']);val=float(r['ratio_mid']);target=float(r['target_ratio']);res=float(r['residual']);width=float(r['bracket_width_rad'])
            assert it==j and lo<mid<hi and abs(width-(hi-lo))<2e-12 and width<prev_width*1.0000001
            assert abs(val-ratio(mid))<2e-12 and abs(target-m['X']/m['Y'])<2e-12 and abs(res-(val-target))<2e-12
            assert lo-2e-12<=m['thetaB']<=hi+2e-12;prev_width=width
        assert abs(float(rr[-1]['mid_rad'])-m['thetaB'])<2e-12
        cr=[r for r in convrows if r['case_id']==id];expected=cfg['model']['convergence_segments'];assert [int(r['segments']) for r in cr]==expected
        prev=float('inf')
        for r in cr:
            n=int(r['segments']);est=float(r['time_estimate_s']);exact=float(r['exact_time_s']);ae=float(r['absolute_error_s']);re=float(r['relative_error'])
            py=segment_time(m['thetaB'],m['a'],g,n);assert abs(est-py)<3e-12;assert abs(exact-m['time'])<3e-12;assert abs(ae-abs(est-exact))<3e-12;assert abs(re-(est-exact)/exact)<3e-12
            assert ae<prev;prev=ae
    return {'cases':meta,'sweep_rows':len(sweep),'root_rows':len(rootrows),'convergence_rows':len(convrows)}

def verify(site=DEFAULT_SITE, allow_draft=False):
    report=json.loads((site/'build.json').read_text(encoding='utf-8'))
    provenance=report['provenance']
    assert allow_draft or provenance['generator']=='julia', 'Publication needs Julia-generated results'
    assert allow_draft or provenance['julia_version']=='1.10.12', 'Unexpected Julia version'
    for group,root in (('sources_sha256',HERE),('files_sha256',site)):
        for name,expected in report[group].items():
            file=(root/name).resolve()
            assert root.resolve() in file.parents, 'Invalid asset path'
            assert hashlib.sha256(file.read_bytes()).hexdigest()==expected, 'Changed file: '+name
    for group,root in (('inputs_sha256',HERE),('outputs_sha256',site)):
        for name,expected in provenance[group].items():
            assert hashlib.sha256((root/name).read_bytes()).hexdigest()==expected, 'Provenance mismatch: '+name
    out=verify_results(site,report['configuration'])
    needed=('index.html','comparison.png','path-straight.png','time-convergence.png','root-solve.png','trajectory-data.js','brachistochrone-cycloid.zip','provenance.toml','LICENSE.txt','root-history.csv','time-convergence.csv','build.json')
    for name in needed:assert (site/name).is_file(),name
    text=(site/'index.html').read_text(encoding='utf-8')
    for marker in ('path-plot','time-plot','convergence-plot','root-plot','root-history.csv','time-convergence.csv'):assert marker in text,marker
    js=(site/'trajectory-data.js').read_text(encoding='utf-8');assert 'root_history' in js and 'convergence' in js
    prefix='window.PLBrachistochrone = '
    assert js.startswith(prefix) and js.endswith(';\n')
    data=json.loads(js[len(prefix):-2])
    for id in IDS:
        case=data['cases'][id]
        for key,value in out['cases'][id].items():
            matches=math.isclose(case[key],value,rel_tol=1e-12,abs_tol=1e-12) if isinstance(value,(int,float)) else case[key]==value
            assert matches, 'Explorer metadata differs from verified results'
        trajectory=[{k:float(v) for k,v in r.items()} for r in rows(site/(id+'.csv'))]
        expected=[dict(theta=r['theta_rad'],x=r['x_m'],y=r['y_m'],t=r['time_s'],v=r['speed_m_s']) for r in trajectory]
        assert case['rows']==expected, 'Explorer trajectory differs from CSV'
        for field,file,mapping in (
            ('convergence','time-convergence.csv',dict(segments='segments',time='time_estimate_s',exact='exact_time_s',absolute_error='absolute_error_s',relative_error='relative_error')),
            ('root_history','root-history.csv',dict(iteration='iteration',lo='lo_rad',hi='hi_rad',mid='mid_rad',ratio='ratio_mid',target='target_ratio',residual='residual',width='bracket_width_rad'))):
            expected=[{k:float(r[v]) for k,v in mapping.items()} for r in rows(site/file) if r['case_id']==id]
            assert case[field]==expected, 'Explorer diagnostic differs from CSV'
    class Assets(HTMLParser):
        def handle_starttag(self,tag,attrs):
            for key,value in attrs:
                if key in ('src','href'):
                    assert value and '/' not in value and '\\' not in value, 'Expected a local asset'
                    assert (site/value).is_file(), 'Missing linked asset: '+value
    Assets().feed(text)
    with zipfile.ZipFile(site/'brachistochrone-cycloid.zip') as z:
        assert z.testzip() is None
        for name,expected in report['sources_sha256'].items():
            assert hashlib.sha256(z.read(name)).hexdigest()==expected, 'Stale bundled source: '+name
        for name in report['files_sha256']:
            if name.endswith('.zip'):continue
            expected=(site/name).read_bytes()
            if name=='index.html':
                expected=text.replace('href="brachistochrone-cycloid.zip"','href="../README.md"').replace('Download Julia project','Project README').encode('utf-8')
            assert z.read('viewer/'+name)==expected, 'Stale bundled viewer: '+name
        for name in provenance['outputs_sha256']:
            assert z.read('results/'+name)==(site/name).read_bytes(), 'Stale bundled dataset'
    print('PASS: Julia provenance, publication hashes, numerical results, CSV/explorer parity, local links and offline ZIP')
if __name__=='__main__':verify(Path(sys.argv[1]) if len(sys.argv)>1 else DEFAULT_SITE)
