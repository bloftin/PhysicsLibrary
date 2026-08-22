#!/usr/bin/env python3
import csv
import html
import re
import tarfile
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SNAP = ROOT / 'data/snapshots/PlanetPhysics-snapshot_2011-04-01.tar.gz'
OUT = ROOT / 'Reports'
OUT.mkdir(exist_ok=True)

BOOK_URL_RE = re.compile(
    r'href=["\']([^"\']*?(?:planetphysics|planetmath)\.org/\?op=getobj(?:&amp;|&|;)from=books(?:&amp;|&|;)id=(\d+)[^"\']*)["\'][^>]*>(.*?)</a>',
    re.I | re.S,
)
BOOK_ID_RE = re.compile(r'(?:from=books(?:&amp;|&|;).*?id=|from=books&id=|from=books;id=)(\d+)', re.I)
TAG_RE = re.compile(r'<[^>]+>')


def clean_anchor(s: str) -> str:
    s = TAG_RE.sub(' ', s)
    s = html.unescape(s)
    return ' '.join(s.split())


with tempfile.TemporaryDirectory() as td_raw:
    td = Path(td_raw)
    with tarfile.open(SNAP, 'r:gz') as tf:
        tf.extractall(td)

    files = [p for p in td.rglob('*') if p.is_file()]
    manifest = []
    ext_counts = Counter()
    top_counts = Counter()
    book_refs = defaultdict(list)
    generic_book_ids = Counter()
    keyword_candidates = []

    for p in files:
        relp = p.relative_to(td)
        rel = str(relp)
        size = p.stat().st_size
        manifest.append((rel, size))
        ext_counts[p.suffix.lower() or '[none]'] += 1
        parts = relp.parts
        top_counts['/'.join(parts[:2]) if len(parts) >= 2 else parts[0]] += 1

        # The snapshot is mostly rendered HTML/TeX. Scan all reasonably sized text-like files
        # for links into the historical Books object table.
        if p.suffix.lower() in {'.html', '.htm', '.tex', '.txt', '.xml', '.css', '.bib'} and size <= 5_000_000:
            try:
                text = p.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue
            for m in BOOK_URL_RE.finditer(text):
                url, bid, anchor = m.groups()
                title = clean_anchor(anchor)
                book_refs[int(bid)].append((title, rel, html.unescape(url)))
            for bid in BOOK_ID_RE.findall(text):
                generic_book_ids[int(bid)] += 1

            low = text.lower()
            if any(k in low for k in ('copyright', 'license', 'public domain', 'creative commons', 'gnu free documentation')):
                keyword_candidates.append((rel, size))

    # Per-book reference inventory. This is useful even when the snapshot does not contain
    # the book objects themselves because it establishes which historical IDs are referenced.
    all_ids = sorted(set(generic_book_ids) | set(book_refs))
    with (OUT / 'Book_Link_References.csv').open('w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['book_id', 'reference_count', 'best_anchor_text', 'example_source', 'example_url'])
        for bid in all_ids:
            refs = book_refs.get(bid, [])
            titles = Counter(t for t, _, _ in refs if t)
            best = titles.most_common(1)[0][0] if titles else ''
            src = refs[0][1] if refs else ''
            url = refs[0][2] if refs else ''
            w.writerow([bid, generic_book_ids.get(bid, len(refs)), best, src, url])

    with (OUT / 'Book_Licensing_Audit_Manifest.csv').open('w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['path', 'bytes'])
        w.writerows(sorted(manifest))

    diag = []
    diag.append('# PhysicsLibrary Book Licensing Audit — Snapshot Discovery\n\n')
    diag.append(f'- Snapshot: `{SNAP.name}`\n')
    diag.append(f'- Archive files: **{len(manifest)}**\n')
    diag.append(f'- Distinct historical book IDs referenced anywhere in snapshot: **{len(all_ids)}**\n')
    if all_ids:
        diag.append(f'- Referenced book ID range: **{min(all_ids)}–{max(all_ids)}**\n')
    diag.append(f'- Files containing licensing/copyright-related terms: **{len(keyword_candidates)}**\n\n')

    diag.append('## Archive layout\n\n')
    diag.append('| Path prefix | Files |\n|---|---:|\n')
    for prefix, n in top_counts.most_common(30):
        diag.append(f'| `{prefix}` | {n} |\n')

    diag.append('\n## File extensions\n\n| Extension | Files |\n|---|---:|\n')
    for ext, n in ext_counts.most_common():
        diag.append(f'| `{ext}` | {n} |\n')

    diag.append('\n## Historical book IDs referenced by the snapshot\n\n')
    diag.append('The full reference inventory is in `Reports/Book_Link_References.csv`. A reference does **not** by itself establish a license; it is an index for later title-level verification.\n\n')
    diag.append('| ID | Refs | Best visible anchor text |\n|---:|---:|---|\n')
    for bid in all_ids:
        refs = book_refs.get(bid, [])
        titles = Counter(t for t, _, _ in refs if t)
        best = titles.most_common(1)[0][0] if titles else ''
        best = best.replace('|', '\\|')[:180]
        diag.append(f'| {bid} | {generic_book_ids.get(bid, len(refs))} | {best} |\n')

    diag.append('\n## Licensing evidence in rendered entry files\n\n')
    diag.append('The snapshot contains rendered encyclopedia/exposition entry files. Many generated `.tex` files carry the standard header `PlanetPhysics is released under the GNU Free Documentation License.` This is evidence for those rendered entries, **not automatically for separately uploaded books**. Book objects therefore require title-level source/license verification rather than blanket assignment of the site GFDL.\n')

    (OUT / 'Book_Licensing_Audit_Discovery.md').write_text(''.join(diag), encoding='utf-8')

print(f'Wrote discovery report for {len(manifest)} archive files and {len(all_ids)} referenced book IDs')
