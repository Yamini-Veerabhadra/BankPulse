# BankPulse — Quality Assurance and Verification Record

## Completed checks

| Check | Evidence / scope | Status |
|---|---|---|
| Source CSV metrics | Independently recalculated 45,211 rows, 5,289 subscriptions and 11.70% conversion | **PASS** |
| Python automated suite | Run from project root; validates metrics, SQL queries against SQLite, screenshots, assets, and the approved refreshed report binary | **PASS — 22 tests** |
| PostgreSQL source table | Owner verified the expected 18 columns and baseline 45,211 / 5,289 / 11.70% in local pgAdmin | **PASS, owner-reported** |
| PostgreSQL analysis scripts 02–07 | Owner reported successful execution of each file in pgAdmin | **PASS, owner-reported** |
| PostgreSQL native assertions 08 | Owner shared both PASS notices from local PostgreSQL | **PASS, owner-reported** |
| Power BI Desktop refresh | Owner confirmed refresh with no errors on Windows | **PASS, owner-reported** |
| Power BI cards | Owner screenshot showed 45,211 / 5,289 / 11.70%; these reconcile with PostgreSQL | **PASS, screenshot and owner report** |
| Power BI interactions | Owner screenshots/reports confirmed selections and resets on both pages | **PASS, owner-reported** |
| Uploaded refreshed PBIX vs original | 30 ZIP members compared; only `DataModel`, `Metadata`, `Settings`, `SecurityBindings` differ; 26 others are identical | **PASS, static comparison** |
| PBIX approved-revision audit | Full SHA-256, ZIP integrity, design fingerprint, 2 pages, 17 visuals and field references | **PASS** |

## Pending / not established

- A successful public GitHub Actions PostgreSQL 17 run: **PENDING**. The YAML workflow has been provided but is not a passing CI run on its own.
- Independent execution and review of **every DAX measure and every Power BI visual value**: **NOT EXHAUSTIVELY VALIDATED**.
- For the three optional/segment KPI cross-checks, see [`powerbi_crosscheck.md`](powerbi_crosscheck.md); only the top three KPI cards are confirmed in Desktop.
- DataModel and SecurityBindings internal changes could not be fully interpreted offline. Local data-source and privacy settings should be checked before publishing.

## Reproduce packaged-release checks

From the `BankPulse` directory:

```powershell
python -m unittest discover -s tests -v
python scripts/validate_metrics.py --report docs/validation_report.md
python scripts/audit_powerbi_report.py --check
```

For a **fresh empty PostgreSQL database only**, the GitHub Actions workflow imports the supplied CSV and runs SQL scripts 02–08 with native PostgreSQL 17. Avoid rerunning imports into an existing populated database.

See [`powerbi_revision_comparison.md`](powerbi_revision_comparison.md) and [`powerbi_structural_audit.md`](powerbi_structural_audit.md) for exact report details.
