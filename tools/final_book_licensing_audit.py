#!/usr/bin/env python3
"""Final evidence-first PhysicsLibrary books licensing audit.

The script inventories every distinct live books-object response in IDs 1..600,
removes repeated generic/error pages, captures catalog metadata and rights text,
and assigns only conservative classifications. Missing evidence stays in manual review.
"""
from __future__ import annotations

import csv
import hashlib
import html
import re
import ssl
import urllib.error
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Reports"
OUT.mkdir(exist_ok=True)
BASE = "https://physicslibrary.org/?op=getobj;from=books;id={}"
MAX_ID = 600
WORKERS = 6
TIMEOUT = 20
CATEGORIES = ["CC", "GFDL", "U.S. public domain", "do-not-publish", "questionable/manual review"]


class PageParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.links = []
        self.title_parts = []
        self._in_title = False
        self._href = None
        self._anchor_parts = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag.lower() == "title":
            self._in_title = True
        if tag.lower() == "a":
            self._href = attrs.get("href", "")
            self._anchor_parts = []

    def handle_endtag(self, tag):
        if tag.lower() == "title":
            self._in_title = False
        if tag.lower() == "a" and self._href is not None:
            self.links.append((self._href, " ".join(self._anchor_parts).strip()))
            self._href = None
            self._anchor_parts = []

    def handle_data(self, data):
        s = " ".join(data.split())
        if not s:
            return
        self.parts.append(s)
        if self._in_title:
            self.title_parts.append(s)
        if self._href is not None:
            self._anchor_parts.append(s)


def norm(s: str) -> str:
    return " ".join(html.unescape(s or "").split())


def title_from_html(source: str, parser: PageParser) -> str:
    for pat in [r"<h1[^>]*>(.*?)</h1>", r"<h2[^>]*>(.*?)</h2>"]:
        m = re.search(pat, source, re.I | re.S)
        if m:
            t = norm(re.sub(r"<[^>]+>", " ", m.group(1)))
            if t:
                return t
    return norm(" ".join(parser.title_parts))


def snippets(text: str) -> list[str]:
    low = text.lower()
    terms = [
        "creative commons", "cc by", "cc-by", "gnu free documentation", "gfdl",
        "public domain", "all rights reserved", "copyright", "private use", "personal use",
        "permission", "license", "licence", "redistribut", "reproduc"
    ]
    out = []
    for term in terms:
        start = 0
        while len(out) < 12:
            i = low.find(term, start)
            if i < 0:
                break
            s = norm(text[max(0, i-220):min(len(text), i+420)])
            if s and s not in out:
                out.append(s)
            start = i + len(term)
    return out


def field(text: str, labels: list[str], stop_labels: list[str] | None = None) -> str:
    # Catalog metadata is rendered as human-readable label/value text. Capture a short
    # value after the label and stop at the next common field label.
    stop_labels = stop_labels or [
        "author", "authors", "publisher", "publication", "published", "date", "edition",
        "copyright", "license", "licence", "rights", "owner", "files", "download",
        "subject", "keywords", "classification", "description", "comments"
    ]
    lab = "|".join(re.escape(x) for x in labels)
    stop = "|".join(re.escape(x) for x in stop_labels)
    m = re.search(rf"(?:^|\s)(?:{lab})\s*:?\s*(.{{1,220}}?)(?=\s+(?:{stop})\s*:?|$)", text, re.I)
    return norm(m.group(1))[:220] if m else ""


def publication_year(text: str) -> str:
    for pat in [
        r"(?:publication\s+date|published|publication|edition)\s*:?\s*[^0-9]{0,40}((?:18|19|20)\d{2})",
        r"copyright\s*(?:\(c\)|©)?\s*((?:18|19|20)\d{2})",
    ]:
        m = re.search(pat, text, re.I)
        if m:
            return m.group(1)
    return ""


def fetch(book_id: int) -> dict:
    url = BASE.format(book_id)
    req = urllib.request.Request(url, headers={"User-Agent": "PhysicsLibraryBookLicenseAudit/1.1"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT, context=ssl.create_default_context()) as r:
            raw = r.read(2_500_000)
            status = getattr(r, "status", 200)
            final_url = r.geturl()
    except urllib.error.HTTPError as e:
        return {"book_id": book_id, "url": url, "status": e.code, "error": f"HTTP {e.code}"}
    except Exception as e:
        return {"book_id": book_id, "url": url, "status": 0, "error": f"{type(e).__name__}: {e}"}

    source = raw.decode("utf-8", errors="replace")
    p = PageParser()
    try:
        p.feed(source)
    except Exception:
        pass
    body = norm(" ".join(p.parts))
    low = body.lower()
    invalid = any(x in low for x in [
        "object not found", "no such object", "requested object does not exist",
        "invalid object", "could not find object"
    ])
    links = [(norm(h), norm(a)) for h, a in p.links]
    attachments = [h for h, _ in links if re.search(r"\.(pdf|djvu|ps|tex|zip|gz)(?:$|[?#])", h, re.I)]
    ev = snippets(body)
    prefix = body[:1200]
    digest = hashlib.sha256(prefix.encode("utf-8", errors="ignore")).hexdigest()

    return {
        "book_id": book_id,
        "url": url,
        "status": status,
        "final_url": final_url,
        "title": title_from_html(source, p)[:500],
        "body": body,
        "body_len": len(body),
        "prefix": prefix,
        "prefix_hash": digest,
        "invalid": invalid,
        "author": field(body, ["Author(s)", "Authors", "Author", "Written by"]),
        "publication_edition": field(body, ["Publication date", "Published", "Publication", "Edition", "Date"]),
        "publication_year": publication_year(body),
        "pl_rights_statement": " || ".join(ev)[:14000],
        "attachments": " | ".join(attachments[:30]),
        "error": "",
    }


def classify(r: dict) -> tuple[str, str, str, str, str, str]:
    body = r["body"]
    low = body.lower()
    evidence = r["pl_rights_statement"]

    cc = bool(re.search(r"creative commons|\bcc[- ]?by(?:[- ][a-z]+)*\b", low))
    pd_explicit = "public domain" in low
    restrictive = "all rights reserved" in low or "personal use only" in low or "private use only" in low
    private_use = "private use" in low

    # GFDL must be tied to the book/document, not to generic PlanetPhysics boilerplate.
    local_gfdl_patterns = [
        r"(?:this|the)\s+(?:book|document|work).{0,160}(?:gnu free documentation license|gfdl|gnu\s+(?:fdl|terms))",
        r"(?:book|document|work).{0,100}(?:released|licensed|copyrighted).{0,120}(?:gnu free documentation license|gfdl|gnu\s+(?:fdl|terms))",
        r"(?:gnu free documentation license|gfdl).{0,160}(?:this|the)\s+(?:book|document|work)",
    ]
    local_gfdl = any(re.search(p, low, re.I | re.S) for p in local_gfdl_patterns)

    if cc:
        category, confidence, reason = "CC", "high", "Explicit Creative Commons language on the book object page"
        us_status = "Reusable under stated CC license; verify exact variant/attribution in evidence"
        intl = "License-based reuse; follow exact CC terms in all jurisdictions"
        action = "Eligible to retain/rehost after exact CC variant and attribution are recorded"
    elif pd_explicit:
        category, confidence, reason = "U.S. public domain", "medium", "Book object page explicitly identifies the work/source as public domain"
        us_status = "Catalog claims public domain; source/provenance should be confirmed before final publication"
        intl = "Public-domain status can differ outside the U.S., especially for foreign works"
        action = "Retain candidate; confirm edition/source and U.S. public-domain basis"
    elif local_gfdl:
        category, confidence, reason = "GFDL", "medium", "GFDL/GNU licensing language is tied to the book/document rather than only site boilerplate"
        us_status = "Reusable under GFDL if the captured statement applies to the uploaded edition"
        intl = "License-based reuse; preserve notices, attribution, license text, and any invariant-section requirements"
        action = "Retain candidate; verify GFDL version/notices in the downloadable file"
    elif restrictive or private_use:
        category, confidence, reason = "do-not-publish", "high" if restrictive else "medium", "Restrictive/private-use language appears on the book object page"
        us_status = "No affirmative republication right established"
        intl = "Assume copyright restrictions remain unless a separate license is verified"
        action = "Do not rehost; keep bibliographic/link-only record unless permission is documented"
    else:
        category, confidence, reason = "questionable/manual review", "low", "No book-local CC/GFDL/public-domain grant or decisive restrictive statement found"
        us_status = "Undetermined from PhysicsLibrary catalog evidence"
        intl = "Undetermined; foreign-origin works require country-of-origin/term review where relevant"
        action = "Hold from rehosting pending source/license or public-domain verification"
    return category, confidence, reason, us_status, intl, action


# Crawl the ID space. Six workers is intentionally modest for the legacy site.
raw = []
with ThreadPoolExecutor(max_workers=WORKERS) as ex:
    futs = [ex.submit(fetch, i) for i in range(1, MAX_ID + 1)]
    for f in as_completed(futs):
        raw.append(f.result())
raw.sort(key=lambda r: r["book_id"])

# Invalid IDs on this legacy application generally render the same generic page. Treat a
# response prefix repeated >=20 times as generic. Every other non-error, non-explicit-invalid
# response is retained; we do not require book-ish keywords, which avoids false negatives.
hash_counts = Counter(r.get("prefix_hash") for r in raw if r.get("status") == 200 and r.get("prefix_hash"))
generic_hashes = {h for h, n in hash_counts.items() if n >= 20}
books = []
for r in raw:
    if r.get("status") != 200 or not r.get("body") or r.get("invalid"):
        continue
    if r.get("prefix_hash") in generic_hashes:
        continue
    category, confidence, reason, us_status, intl, action = classify(r)
    r.update(category=category, confidence=confidence, reason=reason,
             us_status=us_status, international_caveat=intl, recommended_action=action)
    books.append(r)

# Main detailed CSV follows the fields agreed for the licensing review.
columns = [
    "book_id", "title", "author", "publication_edition", "publication_year", "url",
    "pl_rights_statement", "normalized_license", "source_licensing_evidence",
    "us_status", "international_uk_caveat", "confidence", "recommended_action",
    "manual_review_explanation", "attachment_links"
]
with (OUT / "Book_Licensing_Audit.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=columns)
    w.writeheader()
    for r in books:
        row = {
            "book_id": r["book_id"], "title": r["title"], "author": r["author"],
            "publication_edition": r["publication_edition"], "publication_year": r["publication_year"],
            "url": r["url"], "pl_rights_statement": r["pl_rights_statement"],
            "normalized_license": r["category"], "source_licensing_evidence": r["pl_rights_statement"],
            "us_status": r["us_status"], "international_uk_caveat": r["international_caveat"],
            "confidence": r["confidence"], "recommended_action": r["recommended_action"],
            "manual_review_explanation": r["reason"] if r["category"] == "questionable/manual review" else "",
            "attachment_links": r["attachments"],
        }
        w.writerow(row)

# Separate category files emulate the agreed separate review tabs while remaining dependency-free.
for cat in CATEGORIES:
    safe = {"CC":"CC", "GFDL":"GFDL", "U.S. public domain":"Public_Domain",
            "do-not-publish":"Do_Not_Publish", "questionable/manual review":"Manual_Review"}[cat]
    subset = [r for r in books if r["category"] == cat]
    with (OUT / f"Book_Licensing_Audit_{safe}.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["book_id", "title", "author", "publication_year", "confidence", "recommended_action", "url"])
        for r in subset:
            w.writerow([r["book_id"], r["title"], r["author"], r["publication_year"], r["confidence"], r["recommended_action"], r["url"]])

with (OUT / "Book_Licensing_Live_Probe.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["id", "status", "title", "body_len", "prefix_hash", "is_generic", "explicit_invalid", "error"])
    for r in raw:
        w.writerow([r["book_id"], r.get("status",0), r.get("title",""), r.get("body_len",0),
                    r.get("prefix_hash",""), r.get("prefix_hash") in generic_hashes,
                    r.get("invalid",False), r.get("error","")])

counts = Counter(r["category"] for r in books)
conf = Counter(r["confidence"] for r in books)
ids = [r["book_id"] for r in books]
report = []
report.append("# PhysicsLibrary Book Licensing Audit\n\n")
report.append("## Executive summary\n\n")
report.append(f"The live scan probed PhysicsLibrary book object IDs **1–{MAX_ID}** and detected **{len(books)} distinct book records** after removing repeated generic/error responses. ")
if ids:
    report.append(f"Detected records span IDs **{min(ids)}–{max(ids)}**. ")
report.append("The 2011 PlanetPhysics static snapshot is retained as an independent historical cross-check, but it contains rendered encyclopedia entries rather than the uploaded book objects.\n\n")
report.append("This is a conservative triage audit: platform-wide GFDL boilerplate is not treated as a license for an uploaded third-party book. A permissive bucket requires book-local evidence. Ambiguous records remain in manual review.\n\n")
report.append("### Classification counts\n\n")
report.append("| Bucket | Count |\n|---|---:|\n")
for cat in CATEGORIES:
    report.append(f"| {cat} | {counts.get(cat,0)} |\n")
report.append(f"| **Total** | **{len(books)}** |\n\n")
report.append(f"Confidence totals: **high {conf.get('high',0)}**, **medium {conf.get('medium',0)}**, **low {conf.get('low',0)}**.\n\n")
report.append("## Audit rules\n\n")
report.append("- **CC:** explicit Creative Commons grant on the book page; exact CC variant still needs to be recorded before republication.\n")
report.append("- **GFDL:** GNU/GFDL language must be tied to the book/document, not merely the site footer.\n")
report.append("- **U.S. public domain:** the catalog explicitly claims public-domain status; edition/provenance remains a confirmation step, particularly for foreign works.\n")
report.append("- **do-not-publish:** restrictive/private-use language is present and no affirmative reuse license is established.\n")
report.append("- **questionable/manual review:** insufficient evidence either way; do not rehost until verified.\n\n")
report.append("## Per-book results\n\n")
report.append("| ID | Title | Author | Year | Bucket | Confidence | Recommended action |\n|---:|---|---|---:|---|---|---|\n")
for r in books:
    def esc(x, n=100): return norm(str(x)).replace("|", "\\|")[:n]
    report.append(f"| {r['book_id']} | {esc(r['title'])} | {esc(r['author'],70)} | {esc(r['publication_year'],8)} | {r['category']} | {r['confidence']} | {esc(r['recommended_action'],120)} |\n")
report.append("\n## Review files\n\n")
report.append("`Book_Licensing_Audit.csv` is the master evidence table. Separate CSVs are generated for CC, GFDL, public-domain, do-not-publish, and manual-review records. `Book_Licensing_Live_Probe.csv` preserves crawl diagnostics; `Book_Licensing_Audit_Discovery.md` and `Book_Link_References.csv` preserve the historical snapshot cross-check.\n")
(OUT / "Book_Licensing_Audit.md").write_text("".join(report), encoding="utf-8")

print(f"Final audit: detected {len(books)} records, IDs {min(ids) if ids else '-'}..{max(ids) if ids else '-'}, counts={dict(counts)}")
