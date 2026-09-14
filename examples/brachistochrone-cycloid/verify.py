"""Verify saved brachistochrone CSVs and publication artifacts without Julia."""
import csv, math, sys
from pathlib import Path
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
HERE=Path(__file__).resolve().parent
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

def verify_results(results=HERE/'results'):
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

def verify(site=HERE/'published'):
    out=verify_results()
    needed=('index.html','comparison.png','path-straight.png','time-convergence.png','root-solve.png','trajectory-data.js','brachistochrone-cycloid.zip','provenance.toml','LICENSE.txt','root-history.csv','time-convergence.csv','build.json')
    for name in needed:assert (site/name).is_file(),name
    text=(site/'index.html').read_text(encoding='utf-8')
    for marker in ('path-plot','time-plot','convergence-plot','root-plot','root-history.csv','time-convergence.csv'):assert marker in text,marker
    js=(site/'trajectory-data.js').read_text(encoding='utf-8');assert 'root_history' in js and 'convergence' in js
    print('Verified saved results and static site:',out)
if __name__=='__main__':verify(Path(sys.argv[1]) if len(sys.argv)>1 else HERE/'published')
