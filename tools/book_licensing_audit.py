#!/usr/bin/env python3
import csv, gzip, io, json, os, re, tarfile, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SNAP = ROOT / 'data/snapshots/PlanetPhysics-snapshot_2011-04-01.tar.gz'
OUT = ROOT / 'Reports'
OUT.mkdir(exist_ok=True)

with tempfile.TemporaryDirectory() as td:
    td = Path(td)
    with tarfile.open(SNAP, 'r:gz') as tf:
        members = tf.getmembers()
        tf.extractall(td)

    manifest = []
    candidates = []
    for p in td.rglob('*'):
        if not p.is_file():
            continue
        rel = str(p.relative_to(td))
        size = p.stat().st_size
        manifest.append((rel, size))
        low = rel.lower()
        if 'book' in low or p.suffix.lower() in {'.sql','.dump','.xml','.json','.txt','.dat'}:
            candidates.append(p)

    diag = []
    diag.append('# PhysicsLibrary Book Licensing Audit — Snapshot Discovery\n')
    diag.append(f'- Snapshot: `{SNAP.name}`\n- Archive files: **{len(manifest)}**\n- Candidate metadata files: **{len(candidates)}**\n')
    diag.append('## Candidate files\n')
    for p in sorted(candidates, key=lambda x: str(x))[:500]:
        rel = str(p.relative_to(td))
        diag.append(f'### `{rel}` ({p.stat().st_size:,} bytes)\n')
        try:
            data = p.read_bytes()[:200000]
            text = data.decode('utf-8', errors='replace')
        except Exception as e:
            diag.append(f'_Unreadable: {e}_\n')
            continue
        # Surface only lines likely relevant to discovering book schema/records.
        lines = text.splitlines()
        hits = []
        pats = ('book', 'rights', 'copyright', 'author', 'abstract', 'isbn', 'license')
        for i,line in enumerate(lines):
            if any(k in line.lower() for k in pats):
                hits.append((i+1,line[:600]))
                if len(hits) >= 40:
                    break
        if hits:
            diag.append('```text\n')
            for n,line in hits:
                diag.append(f'{n}: {line}\n')
            diag.append('```\n')
        else:
            diag.append('_No book/right/license keywords in first 200 KB._\n')

    (OUT/'Book_Licensing_Audit_Discovery.md').write_text(''.join(diag), encoding='utf-8')
    with (OUT/'Book_Licensing_Audit_Manifest.csv').open('w', newline='', encoding='utf-8') as f:
        w=csv.writer(f); w.writerow(['path','bytes']); w.writerows(sorted(manifest))

print(f'Wrote discovery report for {len(manifest)} archive files')
