"""Verify publication integrity and mechanics with Python's standard library."""
import argparse
import csv
import hashlib
from html.parser import HTMLParser
import json
import math
from pathlib import Path
from urllib.parse import urlsplit
import zipfile

HERE=Path(__file__).resolve().parent
IDS=('frictionless','sliding','sticking')

def close(a,b):
    assert math.isclose(a,b,abs_tol=1e-8,rel_tol=1e-9), (a,b)

def check_case(c):
    # The prose and controls describe these specific reviewed parameters.
    assert c['id'] in IDS
    for key,value in dict(mass=2,gravity=9.81,angle_deg=30,length=10,samples=181).items():
        assert c[key]==value, 'Update article/viewer for new parameters'
    mus=dict(frictionless=(0,0),sliding=(.3,.2),sticking=(.7,.5))
    assert (c['mu_s'],c['mu_k'])==mus[c['id']]
    theta=math.radians(c['angle_deg'])
    weight=c['mass']*c['gravity']
    normal=weight*math.cos(theta)
    down=weight*math.sin(theta)
    stuck=math.tan(theta)<=c['mu_s']
    friction=down if stuck else c['mu_k']*normal
    a=(down-friction)/c['mass']
    duration=4 if stuck else math.sqrt(2*c['length']/a)
    assert c['stuck']==stuck
    for key,value in dict(weight=weight,normal=normal,downhill=down,friction=friction,duration=duration).items():
        close(c[key],value)
    assert len(c['rows'])==181
    for i,row in enumerate(c['rows']):
        assert len(row)==7 and all(math.isfinite(v) for v in row)
        t=duration*i/180
        s=a*t*t/2
        v=a*t
        expected=(t,s,v,a,c['mass']*v*v/2,down*(c['length']-s),friction*s)
        for actual,wanted in zip(row,expected):
            close(actual,wanted)
        close(sum(row[4:]),down*c['length'])
        close(row[4],(down-friction)*row[1])
    close(c['rows'][-1][1],0 if stuck else c['length'])

def offline_page(page):
    return page.replace('href="inclined-plane.zip"','href="../README.md"').replace('Download Julia project','Project README')

class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links=set()
        self.scripts=[]
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        assert tag not in ('iframe','object','embed','form')
        assert not any(key.startswith('on') for key in attrs)
        if tag=='script':
            assert attrs.get('src') in ('trajectory-data.js','explorer.js') and 'defer' in attrs
            self.scripts.append(attrs['src'])
        for key in ('href','src','srcset'):
            if key not in attrs:
                continue
            value=attrs[key]
            parsed=urlsplit(value)
            if parsed.scheme or parsed.netloc:
                assert key=='href' and parsed.scheme=='https' and parsed.netloc=='physicslibrary.org'
            else:
                assert value and not any(char in value for char in '/\\?#')
                self.links.add(value)

def verify(site):
    report=json.loads((site/'build.json').read_text())
    for section,root in (('sources_sha256',HERE),('files_sha256',site)):
        for name,expected in report[section].items():
            path=(root/name).resolve()
            assert root.resolve() in path.parents
            assert hashlib.sha256(path.read_bytes()).hexdigest()==expected, 'Changed file: '+name
    page=(site/'index.html').read_text()
    parser=Page()
    parser.feed(page)
    assert parser.scripts==['trajectory-data.js','explorer.js']
    assert all((site/n).is_file() for n in parser.links), 'Missing linked asset'
    script=(site/'trajectory-data.js').read_text()
    prefix='window.PLInclinedPlane = '
    assert script.startswith(prefix) and script.endswith(';\n')
    cases=json.loads(script[len(prefix):-2])
    assert [c['id'] for c in cases]==list(IDS)
    for c in cases:
        check_case(c)
        with (site/(c['id']+'.csv')).open() as stream:
            reader=csv.reader(stream)
            assert next(reader)==['time_s','distance_m','speed_m_s','acceleration_m_s2','kinetic_J','potential_J','dissipated_J']
            assert [[float(v) for v in row] for row in reader]==c['rows']
    with zipfile.ZipFile(site/'inclined-plane.zip') as z:
        assert z.testzip() is None
        for name,expected in report['sources_sha256'].items():
            assert hashlib.sha256(z.read(name)).hexdigest()==expected
        for name in report['files_sha256']:
            if name=='inclined-plane.zip':
                continue
            expected=offline_page(page).encode() if name=='index.html' else (site/name).read_bytes()
            assert z.read('viewer/'+name)==expected, 'Stale offline asset: '+name
        for name in [i+'.csv' for i in IDS]+['provenance.toml']:
            assert z.read('results/'+name)==(site/name).read_bytes()
    with zipfile.ZipFile(site/'article-attachments.zip') as z:
        assert z.testzip() is None
        for name in ('article.tex','preamble.tex','computational-resources.json','README.md','LICENSE.txt','comparison.png','inclined-plane-forces.png'):
            assert z.read(name)==(HERE/name).read_bytes()
    total=sum(p.stat().st_size for p in site.iterdir() if p.is_file())
    assert total<2*1024*1024, 'Publication exceeds 2 MiB'
    print('PASS: three trajectories, static equilibrium, arrival, energy, CSV parity, hashes, archives, local assets; %d KiB'%(total//1024))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--site',type=Path,default=HERE.parents[1]/'data/examples/inclined-plane')
    verify(parser.parse_args().site)
