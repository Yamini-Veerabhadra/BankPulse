# BankPulse — Power BI revision comparison

## Why the hash changed

The project owner refreshed and saved `powerbi/BankPulse_Dashboard.pbix` in Power BI Desktop after connecting to a local PostgreSQL `Bankpulse` database. The previous offline auditor required the **original** file hash, so it failed when run on the saved file. A hash mismatch by itself is not evidence of a broken report.

| Attribute | Original in supplied ZIP | Uploaded refreshed/saved report |
|---|---|---|
| PBIX bytes | 873,080 | 878,053 |
| SHA-256 | `56697a88aee203c9150e7dba69851bede481039d7c8b7bd941fdd0e1cbcffe9b` | `fe5f767cec2741e5e5327cac858967c44b6f17eb3a0081bfd8c9da87b8c3c038` |
| Container / ZIP integrity | PASS | PASS |
| Archive members | 30 | 30 (same names) |
| Pages | 2 | 2 (identical definitions) |
| Report elements | 17 | 17 (identical visual JSON definitions) |

### Precise archive comparison

Exactly **4** members changed: `DataModel`, `Metadata`, `Settings`, and `SecurityBindings`. All other **26** archive members are byte-for-byte identical, including every `Report/definition/...` file and the Power BI report's visual bindings and page layouts.

- `Metadata` changed its `Created_From_Release` value from `2026.09` to `2026.10`.
- `DataModel` changed in length and content, consistent with a model refresh/save; its internal semantic definitions were **not independently reconstructed or evaluated**.
- `Settings` changed (removed the `Run_Background_Analysis` flag).
- `SecurityBindings` changed; its opaque contents were not semantically audited.

The current `audit_powerbi_report.py` requires an approved full-file SHA-256 plus an invariant fingerprint for the other 26 report members. It validates ZIP CRCs, expected pages, visuals and referenced fields. An unreviewed future PBIX save intentionally requires another comparison; the integrity check is not disabled.

### Windows/runtime evidence reported by the project owner

- Local PostgreSQL data contained 45,211 campaign records and 5,289 subscriptions (11.70%), and 18 expected columns.
- Scripts 02–07 were reported to execute successfully in pgAdmin and native assertions 08 returned PASS notices.
- Power BI Desktop refresh completed without errors; three top-level KPIs matched PostgreSQL.
- Cross-filtering and deselection returned the expected overall KPIs, across both pages.

**Limits:** The offline binary audit does not establish that every DAX formula, model relationship, embedded data value or security-binding record stayed the same. Native PostgreSQL 17 GitHub Actions integration still requires a green run after uploading the repository. Before publishing any PBIX, review Power BI data-source details and credential settings locally; no automated binary scan can guarantee the absence of all confidential metadata.
