"""Offline audit of PBIX report-package fields and visuals (NOT Power BI Desktop/DAX runtime).

Run: python scripts/audit_powerbi_report.py --check
     python scripts/audit_powerbi_report.py --report docs/powerbi_structural_audit.md
Uses only the Python 3 standard library; never mutates the original PBIX.
"""
import argparse
import hashlib
import json
import zipfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBIX = ROOT / 'powerbi/BankPulse_Dashboard.pbix'
# Approved file revisions. Re-saving the report can update embedded model data, security
# bindings or Power BI metadata. Each new revision must be inspected before adding here.
APPROVED_PBIX_SHA256 = {
    '56697a88aee203c9150e7dba69851bede481039d7c8b7bd941fdd0e1cbcffe9b': 'Original supplied report',
    'fe5f767cec2741e5e5327cac858967c44b6f17eb3a0081bfd8c9da87b8c3c038': 'Owner-refreshed and saved report (two-page design unchanged)',
}
# Fingerprint of the 26 report members that did not change during the owner save.
# This catches unintended edits to page/visual layout or other static report assets.
CHANGING_MEMBERS = {'DataModel', 'Metadata', 'SecurityBindings', 'Settings'}
APPROVED_STATIC_PACKAGE_SHA256 = '172159bb540d7a0ff05585b4d6d0ccd134241a18e5e24e0f4c3ef785be9e7c26'
EXPECTED_PAGE_NAMES = ['Campaign Overview', 'Customer & Campaign Insights']
EXPECTED_VISUAL_COUNTS = [9, 8]
EXPECTED_MEASURES = {'Total Campaign Records', 'Total Subscriptions', 'Conversion Rate'}
# Calculated columns are recorded here as fields referenced by visuals; their DAX expressions are
# embedded in the compressed DataModel and CANNOT be evaluated by this tool.
EXPECTED_CALCULATED_COLUMNS = {'Contact Frequency', 'Month Label', 'Loan Profile',
                               'Previous Campaign History', 'Balance Segment', 'Age Group'}
KNOWN_RAW_FIELDS = {'job', 'contact_type', 'subscribed', 'contact_duration'}


def measures_and_columns(x):
    """Traverse projection/sort metadata and capture field expressions, excluding text/formatting."""
    fields = []
    def visit(obj):
        if isinstance(obj, dict):
            for kind in ('Measure', 'Column'):
                item = obj.get(kind)
                if isinstance(item, dict) and 'Property' in item:
                    src = item.get('Expression', {}).get('SourceRef', {}).get('Entity')
                    fields.append((kind, src, item['Property']))
            for child in obj.values():
                visit(child)
        elif isinstance(obj, list):
            for child in obj:
                visit(child)
    visit(x)
    return sorted(set(fields))


def static_package_hash(z):
    """Hash unchanged report assets including all page/visual JSON definitions."""
    h = hashlib.sha256()
    names = sorted(n for n in z.namelist() if n not in CHANGING_MEMBERS)
    for name in names:
        value = z.read(name)
        h.update(len(name.encode('utf-8')).to_bytes(4, 'big'))
        h.update(name.encode('utf-8'))
        h.update(len(value).to_bytes(8, 'big'))
        h.update(hashlib.sha256(value).digest())
    return h.hexdigest()


def audit():
    digest = hashlib.sha256(PBIX.read_bytes()).hexdigest()
    assert digest in APPROVED_PBIX_SHA256, (
        'Unreviewed PBIX revision; compare saved report with approved file and audit changes before release. '
        f'SHA-256: {digest}'
    )
    with zipfile.ZipFile(PBIX) as z:
        assert z.testzip() is None, 'Corrupted PBIX archive'
        assert len(z.namelist()) == len(set(z.namelist())) == 30, 'Unexpected/missing PBIX archive members'
        assert CHANGING_MEMBERS <= set(z.namelist()), 'Expected model/settings entries missing'
        assert static_package_hash(z) == APPROVED_STATIC_PACKAGE_SHA256, (
            'Static report asset differences detected: review report/page/visual definitions'
        )
        assert 'DataModel' in z.namelist(), 'DataModel missing'
        pages_config = json.loads(z.read('Report/definition/pages/pages.json'))
        page_ids = pages_config['pageOrder']
        names = []
        result = []
        visual_types = Counter()
        all_fields = set()
        for page_id in page_ids:
            pgpath = f'Report/definition/pages/{page_id}'
            page = json.loads(z.read(f'{pgpath}/page.json'))
            name = page['displayName']
            names.append(name)
            items = []
            visual_files = sorted(n for n in z.namelist()
                                  if n.startswith(f'{pgpath}/visuals/') and n.endswith('/visual.json'))
            for vf in visual_files:
                v = json.loads(z.read(vf))
                data = v.get('visual', {})
                visual_type = data.get('visualType', '(unknown)')
                visual_types[visual_type] += 1
                used = measures_and_columns(data.get('query', {}))
                for kind, source, field in used:
                    assert source == 'Bank Marketing', f'Unexpected report source: {source} in {vf}'
                    all_fields.add((kind, field))
                items.append((visual_type, used))
            result.append((name, items))
        assert names == EXPECTED_PAGE_NAMES, names
        assert [len(items) for _, items in result] == EXPECTED_VISUAL_COUNTS
        assert sum(visual_types.values()) == 17
        assert EXPECTED_MEASURES <= {x for kind, x in all_fields if kind == 'Measure'}
        assert EXPECTED_CALCULATED_COLUMNS <= {x for kind, x in all_fields if kind == 'Column'}
        assert KNOWN_RAW_FIELDS <= {x for kind, x in all_fields if kind == 'Column'}
    return digest, result, visual_types, all_fields


def report_text(digest, pages, types, fields):
    out = [
        '# BankPulse — Offline Power BI Field/Visual Audit',
        '',
        '> **Important:** This report is an offline integrity and report-binding audit, **not** a Power BI Desktop execution, DAX evaluation, data refresh, or interaction test.',
        '',
        f'- Approved PBIX revision: **{APPROVED_PBIX_SHA256[digest]}**',
        f'- PBIX SHA-256: `{digest}`',
        '- Static report package matches approved original: same pages, visual definitions, and other unchanged assets',
        '- The refreshed file changed `DataModel`, `Metadata`, `Settings`, and `SecurityBindings`; their internals were not independently executed',
        f'- Pages: **{len(pages)}**, report elements: **{sum(types.values())}**',
        '- Power BI table referenced by all visual field projections: `Bank Marketing`',
        '- Chart visuals: **10**, KPI cards: **3**, text boxes: **4**',
        '',
        '## Field references found in the report',
        '',
        '| Type | Field | Validation scope |',
        '|---|---|---|',
    ]
    for kind, field in sorted(fields):
        scope = 'Reference exists in visual metadata; definition/value not executed'
        if kind == 'Column' and field in KNOWN_RAW_FIELDS:
            scope = 'Source column name recognized; no Desktop refresh tested'
        out.append(f'| {kind} | `{field}` | {scope} |')
    out += ['', '## Report elements by page', '']
    for name, items in pages:
        out += [f'### {name}', '', '| # | Visual type | Fields referenced |', '|---:|---|---|']
        for i, (vtype, flds) in enumerate(items, 1):
            desc = ', '.join(f'`{kind}:{field}`' for kind, _, field in flds)
            out.append(f'| {i} | `{vtype}` | {desc or "Text / no data field"} |')
        out.append('')
    out += [
        '## What this check cannot verify', '',
        '- Actual calculated-column formulas, DAX measure correctness or VertiPaq model values',
        '- Desktop rendering, page visuals, slicers and cross-filter interactions',
        '- Source refresh or local database/file credentials',
        '- Agreement between live Power BI cards and independent CSV-derived numbers',
        '',
        'For those checks, open the provided `.pbix` in Power BI Desktop on Windows and follow [`powerbi_crosscheck.md`](powerbi_crosscheck.md).',
        '',
    ]
    return '\n'.join(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true', help='Run assertions and print concise check summary')
    parser.add_argument('--report', type=Path, help='Save detailed Markdown audit')
    args = parser.parse_args()
    digest, pages, types, fields = audit()
    if args.report:
        p = args.report if args.report.is_absolute() else ROOT / args.report
        p.write_text(report_text(digest, pages, types, fields), encoding='utf-8')
        print('Wrote audit report:', p)
    print(f'PASS: Approved PBIX revision ({APPROVED_PBIX_SHA256[digest]}); 2 pages, 17 visuals; static report definitions unchanged')
    print('NOTE: offline validation does NOT execute DAX, inspect all DataModel semantics, or itself refresh Power BI Desktop')


if __name__ == '__main__':
    main()
