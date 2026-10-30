# BankPulse — Offline Power BI Field/Visual Audit

> **Important:** This report is an offline integrity and report-binding audit, **not** a Power BI Desktop execution, DAX evaluation, data refresh, or interaction test.

- Approved PBIX revision: **Owner-refreshed and saved report (two-page design unchanged)**
- PBIX SHA-256: `fe5f767cec2741e5e5327cac858967c44b6f17eb3a0081bfd8c9da87b8c3c038`
- Static report package matches approved original: same pages, visual definitions, and other unchanged assets
- The refreshed file changed `DataModel`, `Metadata`, `Settings`, and `SecurityBindings`; their internals were not independently executed
- Pages: **2**, report elements: **17**
- Power BI table referenced by all visual field projections: `Bank Marketing`
- Chart visuals: **10**, KPI cards: **3**, text boxes: **4**

## Field references found in the report

| Type | Field | Validation scope |
|---|---|---|
| Column | `Age Group` | Reference exists in visual metadata; definition/value not executed |
| Column | `Balance Segment` | Reference exists in visual metadata; definition/value not executed |
| Column | `Contact Frequency` | Reference exists in visual metadata; definition/value not executed |
| Column | `Loan Profile` | Reference exists in visual metadata; definition/value not executed |
| Column | `Month Label` | Reference exists in visual metadata; definition/value not executed |
| Column | `Previous Campaign History` | Reference exists in visual metadata; definition/value not executed |
| Column | `contact_duration` | Source column name recognized; no Desktop refresh tested |
| Column | `contact_type` | Source column name recognized; no Desktop refresh tested |
| Column | `job` | Source column name recognized; no Desktop refresh tested |
| Column | `subscribed` | Source column name recognized; no Desktop refresh tested |
| Measure | `Conversion Rate` | Reference exists in visual metadata; definition/value not executed |
| Measure | `Total Campaign Records` | Reference exists in visual metadata; definition/value not executed |
| Measure | `Total Subscriptions` | Reference exists in visual metadata; definition/value not executed |

## Report elements by page

### Campaign Overview

| # | Visual type | Fields referenced |
|---:|---|---|
| 1 | `cardVisual` | `Measure:Conversion Rate` |
| 2 | `cardVisual` | `Measure:Total Subscriptions` |
| 3 | `textbox` | Text / no data field |
| 4 | `clusteredColumnChart` | `Column:Loan Profile`, `Measure:Conversion Rate` |
| 5 | `clusteredColumnChart` | `Column:Contact Frequency`, `Measure:Conversion Rate` |
| 6 | `clusteredColumnChart` | `Column:Month Label`, `Measure:Conversion Rate` |
| 7 | `textbox` | Text / no data field |
| 8 | `cardVisual` | `Measure:Total Campaign Records` |
| 9 | `clusteredBarChart` | `Column:Previous Campaign History`, `Measure:Conversion Rate` |

### Customer & Campaign Insights

| # | Visual type | Fields referenced |
|---:|---|---|
| 1 | `clusteredColumnChart` | `Column:contact_duration`, `Column:subscribed` |
| 2 | `clusteredBarChart` | `Column:job`, `Measure:Total Subscriptions` |
| 3 | `clusteredBarChart` | `Column:Age Group`, `Measure:Conversion Rate` |
| 4 | `textbox` | Text / no data field |
| 5 | `clusteredBarChart` | `Column:job`, `Measure:Conversion Rate` |
| 6 | `textbox` | Text / no data field |
| 7 | `clusteredColumnChart` | `Column:contact_type`, `Measure:Conversion Rate` |
| 8 | `clusteredColumnChart` | `Column:Balance Segment`, `Measure:Conversion Rate` |

## What this check cannot verify

- Actual calculated-column formulas, DAX measure correctness or VertiPaq model values
- Desktop rendering, page visuals, slicers and cross-filter interactions
- Source refresh or local database/file credentials
- Agreement between live Power BI cards and independent CSV-derived numbers

For those checks, open the provided `.pbix` in Power BI Desktop on Windows and follow [`powerbi_crosscheck.md`](powerbi_crosscheck.md).
