#!/usr/bin/env python3
"""Independently reconcile BankPulse metrics against the unchanged UCI CSV.

No PostgreSQL, Power BI, or third-party Python packages are needed.
Usage: python scripts/validate_metrics.py
       python scripts/validate_metrics.py --report docs/validation_report.md
"""

import argparse
import csv
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CSV = ROOT / 'data' / 'raw' / 'bank-full.csv'
EXPECTED_COLUMNS = (
    'age', 'job', 'marital', 'education', 'default', 'balance', 'housing',
    'loan', 'contact', 'day', 'month', 'duration', 'campaign', 'pdays',
    'previous', 'poutcome', 'y',
)


def rate(subscriptions, records):
    return 100.0 * subscriptions / records if records else 0.0


def contact_bucket(raw_contacts):
    contacts = int(raw_contacts)
    if contacts == 1:
        return '1'
    if 2 <= contacts <= 3:
        return '2-3'
    if 4 <= contacts <= 5:
        return '4-5'
    if 6 <= contacts <= 10:
        return '6-10'
    if contacts >= 11:
        return '11+'
    return 'Invalid (under 1)'


def loan_bucket(row):
    housing, personal = row['housing'], row['loan']
    if housing == 'no' and personal == 'no':
        return 'No housing or personal loan'
    if housing == 'yes' and personal == 'no':
        return 'Housing loan only'
    if housing == 'no' and personal == 'yes':
        return 'Personal loan only'
    if housing == 'yes' and personal == 'yes':
        return 'Both loan types'
    return 'Unknown loan status'


def load_rows(path=DEFAULT_CSV):
    with open(path, encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f, delimiter=';', quotechar='"')
        if tuple(reader.fieldnames or ()) != EXPECTED_COLUMNS:
            raise ValueError('Unexpected source header: expected the unmodified UCI bank-full.csv columns')
        rows = list(reader)
    if any(None in row or any(v is None for v in row.values()) for row in rows):
        raise ValueError('Malformed source CSV rows (unexpected field count)')
    return rows


def analyze(rows):
    total = len(rows)
    if total == 0:
        raise ValueError('The source dataset is empty')
    bad_outcomes = sum(r['y'] not in ('yes', 'no') for r in rows)
    if bad_outcomes:
        raise ValueError(f'{bad_outcomes} records have an invalid target outcome')

    yes = sum(r['y'] == 'yes' for r in rows)
    dimensions = {
        'contact_frequency': lambda r: contact_bucket(r['campaign']),
        'job_category': lambda r: r['job'],
        'previous_outcome': lambda r: r['poutcome'],
        'loan_profile': loan_bucket,
    }
    groups = {}
    reconciliations = {}
    for name, classifier in dimensions.items():
        by = defaultdict(lambda: [0, 0])
        for row in rows:
            agg = by[classifier(row)]
            agg[0] += 1
            agg[1] += (row['y'] == 'yes')
        groups[name] = {key: {'records': n, 'subscriptions': s, 'conversion_pct': rate(s, n)}
                        for key, (n, s) in sorted(by.items())}
        observed_records = sum(v['records'] for v in groups[name].values())
        observed_yes = sum(v['subscriptions'] for v in groups[name].values())
        reconciliations[name] = {
            'records_match': observed_records == total,
            'subscriptions_match': observed_yes == yes,
        }
        if not all(reconciliations[name].values()):
            raise AssertionError(f'{name} partition failed to reconcile')

    known_unknown = {}
    for field in ('job', 'education', 'contact', 'poutcome'):
        known = [r for r in rows if r[field] != 'unknown']
        unknown = [r for r in rows if r[field] == 'unknown']
        known_yes = sum(r['y'] == 'yes' for r in known)
        unknown_yes = sum(r['y'] == 'yes' for r in unknown)
        known_unknown[field] = {
            'known_records': len(known), 'known_subscriptions': known_yes,
            'known_conversion_pct': rate(known_yes, len(known)),
            'unknown_records': len(unknown), 'unknown_subscriptions': unknown_yes,
            'unknown_conversion_pct': rate(unknown_yes, len(unknown)),
        }
        if len(known) + len(unknown) != total or known_yes + unknown_yes != yes:
            raise AssertionError(f'Unknown sensitivity for {field} does not reconcile')

    original_record_tuples = [tuple(r[c] for c in EXPECTED_COLUMNS) for r in rows]
    repeated_rows = total - len(set(original_record_tuples))
    blanks = {field: sum(row[field] == '' for row in rows) for field in EXPECTED_COLUMNS}
    prior_no_history = sum(r['previous'] == '0' and r['pdays'] == '-1' and
                           r['poutcome'] == 'unknown' for r in rows)
    return {
        'total_records': total,
        'total_subscriptions': yes,
        'overall_conversion_pct': rate(yes, total),
        'invalid_target_values': bad_outcomes,
        'exact_duplicate_source_rows': repeated_rows,
        'blank_field_counts': blanks,
        'no_prior_contact_pattern_records': prior_no_history,
        'groups': groups,
        'reconciliations': reconciliations,
        'unknown_sensitivity': known_unknown,
    }


def metric_row(label, data, total_subs=None):
    n, s = data['records'], data['subscriptions']
    share = f"{rate(s, total_subs):.2f}%" if total_subs is not None else '—'
    return f"| {label} | {n:,} | {s:,} | {rate(s, n):.2f}% | {share} |"


def render_report(metrics):
    n = metrics['total_records']
    y = metrics['total_subscriptions']
    groups = metrics['groups']
    output = [
        '# BankPulse — Independent CSV Metric Validation', '',
        '**Scope:** Source CSV re-calculation using only Python standard library; not a PostgreSQL or Power BI runtime audit.',
        '**Method:** All source rows with binary `y` = `yes`/`no` count as eligible campaign records. Rows are not unique identified customers.', '',
        f'- Campaign records: **{n:,}**',
        f'- Subscribed records: **{y:,}**',
        f'- Overall response rate: **{rate(y, n):.2f}%**',
        f"- Exact duplicate source rows (all 17 original fields): **{metrics['exact_duplicate_source_rows']:,}**",
        f"- Rows matching `previous=0`, `pdays=-1`, `poutcome=unknown`: **{metrics['no_prior_contact_pattern_records']:,}**", '',
        '## Contact frequency', '',
        '| Current-campaign contacts | Records | Subscriptions | Conversion | Share of subscriptions |',
        '|---|---:|---:|---:|---:|',
    ]
    for label in ('1', '2-3', '4-5', '6-10', '11+'):
        output.append(metric_row(label, groups['contact_frequency'][label], y))
    output.extend(['', '## Job categories — selected comparisons', '',
                   '| Job category | Records | Subscriptions | Conversion | Share of subscriptions |',
                   '|---|---:|---:|---:|---:|'])
    for label in ('management', 'student', 'retired', 'technician', 'blue-collar'):
        output.append(metric_row(label, groups['job_category'][label], y))
    output.extend(['', '## Previous campaign outcome', '',
                   '| Previous outcome | Records | Subscriptions | Conversion | Share of subscriptions |',
                   '|---|---:|---:|---:|---:|'])
    for label in ('success', 'other', 'failure', 'unknown'):
        output.append(metric_row(label, groups['previous_outcome'][label], y))
    output.extend(['', '## Loan profiles', '',
                   '| Loan profile | Records | Subscriptions | Conversion | Share of subscriptions |',
                   '|---|---:|---:|---:|---:|'])
    for label in ('No housing or personal loan', 'Housing loan only',
                  'Personal loan only', 'Both loan types'):
        output.append(metric_row(label, groups['loan_profile'][label], y))
    output.extend(['', '## Unknown-category sensitivity', '',
                   '| Field | Unknown rows | Unknown conversion | Known rows | Known-only conversion |',
                   '|---|---:|---:|---:|---:|'])
    for label in ('job', 'education', 'contact', 'poutcome'):
        v = metrics['unknown_sensitivity'][label]
        output.append(f"| `{label}` | {v['unknown_records']:,} | {v['unknown_conversion_pct']:.2f}% | "
                      f"{v['known_records']:,} | {v['known_conversion_pct']:.2f}% |")
    blank_fields = {k: v for k, v in metrics['blank_field_counts'].items() if v}
    output.extend(['', '## Source completeness', '',
                   f"- Empty-string fields: **{sum(metrics['blank_field_counts'].values()):,}** occurrences across all original attributes.",
                   f"- Fields containing blank strings: **{', '.join(f'{k} ({v})' for k, v in blank_fields.items()) if blank_fields else 'none'}**.",
                   '', '## Reconciliation checks', '',
                   '| Partition | Records reconcile | Subscriptions reconcile |',
                   '|---|---|---|'])
    for key, v in metrics['reconciliations'].items():
        output.append(f"| `{key}` | {'PASS' if v['records_match'] else 'FAIL'} | "
                      f"{'PASS' if v['subscriptions_match'] else 'FAIL'} |")
    output.extend(['', 'The original CSV was not modified. Power BI measure correctness and PostgreSQL execution require separate verification.',
                   'Associations are observational; no causal effect or real-world campaign improvement was measured.', ''])
    return '\n'.join(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--csv', type=Path, default=DEFAULT_CSV,
                        help='Unmodified semicolon-delimited UCI bank-full.csv')
    parser.add_argument('--report', type=Path, help='Optional output Markdown report path')
    args = parser.parse_args()
    metrics = analyze(load_rows(args.csv))
    report = render_report(metrics)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report, encoding='utf-8')
        print(f'Wrote: {args.report}')
    else:
        print(report)


if __name__ == '__main__':
    main()
