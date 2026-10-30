# BankPulse — Power BI Manual Cross-Check Checklist

**Status:** The project owner confirmed a successful Power BI Desktop refresh and matched the three main cards (45,211; 5,289; 11.70%) to local PostgreSQL. Both pages were opened, interactions tested, and selections reset successfully. **The remaining three segment-level checklist values were not individually attested in Desktop.** Reference values below were independently calculated from the source CSV; they do not prove every measure is correct.

Compare each displayed Power BI value using matching filters / slicers (reset all report filters first):

- [x] **Campaign records:** 45,211 (make sure it is record count, not unique customers)
- [x] **Subscriptions:** 5,289 (rows with `subscribed='yes'`)
- [x] **Overall conversion:** 11.70% (= 5,289 / 45,211 × 100)
- [ ] **1-contact group:** 17,544 records, 2,561 subscriptions, 14.60% conversion
- [ ] **Prior-success group:** 1,511 records, 978 subscriptions, 64.73% conversion
- [ ] **Management job category:** 9,458 records, 1,301 subscriptions, 13.76% conversion

If a metric differs: check page-level filters, model relationships, DAX numerator/denominator, unknown-category handling, and whether the visual uses `DISTINCTCOUNT` on the generated row key versus row count. A unique-customer count cannot be computed from this source because the CSV lacks a genuine customer identifier.

Optional extra checks:

- [ ] Student category: 938 records, 269 subscriptions, 28.68% conversion
- [ ] Contact type `unknown`: 13,020 records, 530 subscriptions, 4.07% conversion
- [ ] No-housing/no-personal-loan: 17,204 records, 3,135 subscriptions, 18.22% conversion

Document any differences rather than silently changing reference values. **Only mark a check complete after personally inspecting the Power BI visual.** The ZIP contains the owner-refreshed/saved dashboard; its page and visual definitions match the original.


## Structural verification performed for this release

The `.pbix` file is a valid ZIP-based Power BI report package with **2 pages** and **17 visual definitions** (including text boxes). The report/page/visual JSON files parse successfully, and all expected page titles and the three top-level KPI card field references are present. Both screenshot files decode successfully. This does **not** establish that every embedded DAX calculation, refresh credential, filter interaction, or rendering behavior works in Power BI Desktop.

**Small-sample warning:** the Campaign Overview screenshot contains an `Unknown Previous History` segment with **40.00%** observed response. This is **2 subscriptions out of only 5 records**; it must not be interpreted as strong evidence of a campaign opportunity. The much larger `No Previous Campaign History` category has a separate **9.16%** rate. The report design was preserved; the refreshed model data and metadata were not manually edited.


## Additional offline checks performed

The values printed in the **original screenshots** were independently recomputed from the unchanged CSV for all 12 month categories, all three contact methods, all five age groups, five selected job categories, and the two call-duration outcome groups. The stored screenshot figures match to the displayed precision. See `tests/test_dashboard_reference_values.py` and [powerbi_structural_audit.md](powerbi_structural_audit.md).

**Scope warning:** The owner subsequently confirmed an actual refresh, the three main KPIs, and two-page interactions on Windows. Original screenshot consistency is not proof of every embedded DAX expression or the three additional segment KPIs; these require separate checks.
