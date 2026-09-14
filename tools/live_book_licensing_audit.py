#!/usr/bin/env python3
"""Inventory and conservatively triage PhysicsLibrary book objects.

This is intentionally evidence-first. It never infers a permissive license merely
from the site's global license/footer. Ambiguous records are routed to manual review.
"""
from __future__ import annotations

import csv
import html
import re
import ssl
import time
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


class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text = []
        self.links = []
        self._anchor = None
        self._anchor_text = []
        self.title = []
        self._in_title = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag.lower() == "a":
            self._anchor = attrs.get("href", "")
            self._anchor_text = []
        if tag.lower() == "title":
            self._in_title = True

    def handle_endtag(self, tag):
        if tag.lower() == "a" and self._anchor is not None:
            self.links.append((self._anchor, " ".join(self._anchor_text).strip()))
            self._anchor = None
            self._anchor_text = []
        if tag.lower() == "title":
            self._in_title = False

    def handle_data(self, data):
        s = " ".join(data.split())
        if not s:
            return
        self.text.append(s)
        if self._anchor is not None:
            self._anchor_text.append(s)
        if self._in_title:
            self.title.append(s)


def normalize(s: str) -> str:
    return " ".join(html.unescape(s).split())


def fetch_one(book_id: int):
    url = BASE.format(book_id)
    req = urllib.request.Request(url, headers={"User-Agent": "PhysicsLibraryBookLicenseAudit/1.0 (+repository audit)"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT, context=ssl.create_default_context()) as r:
            raw = r.read(2_000_000)
            final_url = r.geturl()
            status = getattr(r, "status", 200)
            ctype = r.headers.get("Content-Type", "")
    except urllib.error.HTTPError as e:
        return {"id": book_id, "url": url, "status": e.code, "error": f"HTTP {e.code}"}
    except Exception as e:
        return {"id": book_id, "url": url, "status": 0, "error": f"{type(e).__name__}: {e}"}

    text = raw.decode("utf-8", errors="replace")
    parser = TextExtractor()
    try:
        parser.feed(text)
    except Exception:
        pass
    body = normalize(" ".join(parser.text))
    title_tag = normalize(" ".join(parser.title))

    # Extract likely object title from common PlanetMath/Noosphere markup before falling back.
    title_candidates = []
    for pat in [
        r'<h1[^>]*>(.*?)</h1>', r'<h2[^>]*>(.*?)</h2>',
        r'<font[^>]*size=["\']?\+?3["\']?[^>]*>(.*?)</font>'
    ]:
        for m in re.finditer(pat, text, re.I | re.S):
            val = normalize(re.sub(r"<[^>]+>", " ", m.group(1)))
            if val:
                title_candidates.append(val)
    title = title_candidates[0] if title_candidates else title_tag

    low = body.lower()
    # A failed getobj commonly renders a generic/home/error page. These indicators are
    # deliberately conservative; ambiguous responses are retained as probes below.
    invalid_phrases = [
        "object not found", "no such object", "requested object does not exist",
        "invalid object", "could not find object"
    ]
    explicit_invalid = any(p in low for p in invalid_phrases)

    # Evidence snippets, centered on licensing-related terms.
    evidence_terms = [
        "creative commons", "cc by", "cc-by", "gnu free documentation", "gfdl",
        "public domain", "all rights reserved", "copyright", "private use", "permission",
        "license", "licence", "redistribut", "reproduc"
    ]
    snippets = []
    for term in evidence_terms:
        start = 0
        while True:
            i = low.find(term, start)
            if i < 0:
                break
            a, b = max(0, i - 180), min(len(body), i + 320)
            snip = body[a:b]
            if snip not in snippets:
                snippets.append(snip)
            start = i + len(term)
            if len(snippets) >= 10:
                break
        if len(snippets) >= 10:
            break

    links = [(normalize(href), normalize(anchor)) for href, anchor in parser.links]
    bookish_link_count = sum(1 for href, _ in links if "from=books" in href.lower())
    attachment_links = [href for href, _ in links if re.search(r'\.(?:pdf|djvu|ps|tex|zip|gz)(?:$|[?#])', href, re.I)]

    # Heuristic validity: an explicit getobj/books self-reference, attachment, book-ish
    # content, or a non-generic title. Generic pages are excluded later by duplicated hash/text.
    bookish_words = sum(low.count(w) for w in ("book", "author", "isbn", "publisher", "download"))
    valid_signal = (not explicit_invalid) and (bookish_link_count > 0 or attachment_links or bookish_words >= 2)

    return {
        "id": book_id,
        "url": url,
        "status": status,
        "final_url": final_url,
        "content_type": ctype,
        "title": title[:500],
        "body": body,
        "body_len": len(body),
        "body_prefix": body[:1000],
        "evidence": " || ".join(snippets)[:12000],
        "attachment_links": " | ".join(attachment_links[:20]),
        "bookish_link_count": bookish_link_count,
        "valid_signal": valid_signal,
        "error": "",
    }


def classify(rec):
    body = rec.get("body", "")
    low = body.lower()
    evidence = rec.get("evidence", "")

    cc = bool(re.search(r'creative commons|\bcc[- ]?by(?:[- ][a-z]+)*\b', low))
    gfdl = "gnu free documentation license" in low or "gfdl" in low
    pd_explicit = "public domain" in low
    private = "private use" in low or "personal use only" in low
    all_rights = "all rights reserved" in low

    # A global site GFDL statement is not sufficient for an uploaded third-party book.
    # We only auto-assign GFDL if another strong book-local term appears nearby in a
    # licensing snippet, otherwise leave it for review.
    book_local_gfdl = gfdl and any(k in evidence.lower() for k in (
        "this book", "this work", "this document", "released under", "licensed under",
        "copyrighted under", "gnu terms", "gnu fdl"
    ))

    if cc:
        return "CC", "high", "Explicit Creative Commons marker on book page"
    if pd_explicit:
        return "U.S. public domain", "medium", "Explicit public-domain marker; jurisdiction/source still worth confirming"
    if book_local_gfdl:
        return "GFDL", "medium", "Book-local GFDL/GNU licensing language detected"
    if private or all_rights:
        return "do-not-publish", "high" if all_rights else "medium", "Restrictive rights/use language detected"
    if gfdl:
        return "questionable/manual review", "low", "GFDL appears on page but may be global site boilerplate"
    return "questionable/manual review", "low", "No explicit reusable-license or public-domain evidence on catalog page"


# Fetch conservatively with a small worker pool to avoid hammering the site.
records = []
with ThreadPoolExecutor(max_workers=WORKERS) as ex:
    futures = {ex.submit(fetch_one, i): i for i in range(1, MAX_ID + 1)}
    for fut in as_completed(futures):
        records.append(fut.result())
records.sort(key=lambda x: x["id"])

# Identify generic response bodies by prefix frequency. Invalid IDs often return exactly
# the same home/error page. Do not let those inflate the catalog count.
prefix_counts = Counter(r.get("body_prefix", "") for r in records if r.get("status") == 200 and r.get("body_prefix"))
common_generic = {p for p, n in prefix_counts.items() if n >= 20}

valid = []
for r in records:
    if r.get("status") != 200 or not r.get("body"):
        continue
    if r.get("body_prefix", "") in common_generic:
        continue
    if not r.get("valid_signal"):
        continue
    category, confidence, reason = classify(r)
    r["category"] = category
    r["confidence"] = confidence
    r["reason"] = reason
    valid.append(r)

# CSV: one row per detected book object.
with (OUT / "Book_Licensing_Audit.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow([
        "book_id", "title", "url", "category", "confidence", "reason",
        "license_evidence", "attachment_links", "body_length"
    ])
    for r in valid:
        w.writerow([
            r["id"], r.get("title", ""), r["url"], r["category"], r["confidence"],
            r["reason"], r.get("evidence", ""), r.get("attachment_links", ""), r.get("body_len", 0)
        ])

# Diagnostic raw probe data for every attempted ID, useful for improving validity detection.
with (OUT / "Book_Licensing_Live_Probe.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["id", "status", "final_url", "title", "valid_signal", "body_len", "body_prefix", "error"])
    for r in records:
        w.writerow([
            r["id"], r.get("status", 0), r.get("final_url", ""), r.get("title", ""),
            r.get("valid_signal", False), r.get("body_len", 0), r.get("body_prefix", ""), r.get("error", "")
        ])

counts = Counter(r["category"] for r in valid)
conf = Counter(r["confidence"] for r in valid)
report = []
report.append("# PhysicsLibrary Book Licensing Audit\n\n")
report.append("## Scope and method\n\n")
report.append(f"This report probed live PhysicsLibrary `books` object IDs **1–{MAX_ID}** and retained responses that behaved as book-object pages rather than repeated generic/error pages. The 2011 static PlanetPhysics snapshot is used separately as a historical cross-check; it does not itself contain the uploaded book objects.\n\n")
report.append("Classification is deliberately conservative. A site-wide footer or platform license is **not** treated as proof that an uploaded third-party book is reusable. Only book-local evidence supports CC/GFDL/public-domain assignment. Anything ambiguous is routed to manual review.\n\n")
report.append("The buckets are exactly: **CC**, **GFDL**, **U.S. public domain**, **do-not-publish**, and **questionable/manual review**.\n\n")
report.append("## Results\n\n")
report.append(f"- Detected book objects: **{len(valid)}**\n")
for cat in ["CC", "GFDL", "U.S. public domain", "do-not-publish", "questionable/manual review"]:
    report.append(f"- {cat}: **{counts.get(cat, 0)}**\n")
report.append(f"- Confidence: high **{conf.get('high',0)}**, medium **{conf.get('medium',0)}**, low **{conf.get('low',0)}**\n\n")

report.append("## Per-book audit\n\n")
report.append("| ID | Title | Classification | Confidence | Evidence/rationale |\n|---:|---|---|---|---|\n")
for r in valid:
    title = (r.get("title") or "(untitled)").replace("|", "\\|")[:100]
    reason = r["reason"].replace("|", "\\|")
    report.append(f"| {r['id']} | {title} | {r['category']} | {r['confidence']} | {reason} |\n")

report.append("\n## Interpretation\n\n")
report.append("`questionable/manual review` does not mean the book is infringing; it means the catalog page did not provide sufficient evidence for PhysicsLibrary to affirmatively republish the book under the audit rules. `do-not-publish` is reserved for records where restrictive language was actually detected.\n\n")
report.append("The CSV contains the captured license/copyright snippets and attachment links so every classification can be reviewed and upgraded with source evidence.\n")

(OUT / "Book_Licensing_Audit.md").write_text("".join(report), encoding="utf-8")

print(f"Probed {MAX_ID} IDs; retained {len(valid)} book-like objects; categories={dict(counts)}")
