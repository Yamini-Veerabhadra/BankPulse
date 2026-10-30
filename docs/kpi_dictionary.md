# BankPulse — KPI and Data-Grain Dictionary

| Metric | Numerator / calculation | Denominator or grain | Important exclusions / caveats |
|---|---|---|---|
| Eligible campaign records | Count of records with `y` in (`yes`, `no`) (in PostgreSQL, `subscribed`) | Each CSV row / imported SQL row | Does **not** mean unique customers; the imported `customer_id` is a generated row key |
| Subscribed records | Count with `y='yes'` | Eligible campaign records | Invalid target codes must be flagged, not silently included as negative |
| Overall conversion (%) | `100 × subscribed eligible records / all eligible records` | All eligible records | 5,289 / 45,211 = 11.70% in supplied source |
| Segment conversion (%) | `100 × yes records in group / eligible records in group` | Eligible records in specified group | Display counts and segment definitions alongside percentage; retain `unknown` |
| Share of all subscriptions (%) | `100 × group subscribed records / all subscribed records` | All 5,289 subscribed records | Measures **observed volume contribution**, not prospective campaign ROI |
| Contact-frequency bucket | `campaign` = 1, 2–3, 4–5, 6–10, 11+ | Source field `campaign` / SQL `campaign_contacts` | Frequency refers to current campaign record; not a unique-customer contact history |
| Previous outcome | Source `poutcome`, SQL `previous_outcome` | `success`, `failure`, `other`, `unknown` | `unknown` is not always equivalent to no prior history |
| Known-only conversion | Count of yes among rows where selected field is not `unknown` / count of those rows | Known-only subset for a **specified** field | Must be labelled as a subset; don't compare with overall without noting denominator change |
| Loan profile | `housing` and `loan` yes/no combined | Each eligible record | Descriptive association, not a financial eligibility or individual-targeting rule |
| Call duration | Source `duration` / SQL `contact_duration` | Completed campaign interaction | Post-interaction feature only; don't use for pre-call targeting |

## Import-column mapping

Source CSV fields use `default`, `housing`, `loan`, `contact`, `day`, `month`, `duration`, `campaign`, `pdays`, `previous`, `poutcome`, `y`. The SQL import table maps those by **position** to `credit_default`, `housing_loan`, `personal_loan`, `contact_type`, `contact_day`, `contact_month`, `contact_duration`, `campaign_contacts`, `days_since_previous_contact`, `previous_contacts`, `previous_outcome`, `subscribed`. The generated `customer_id` must not be populated by source CSV data.

## Definition and validation ownership

The CSV validator (`scripts/validate_metrics.py`) checks four non-overlapping partitions, counts invalid outcomes, checks exact duplicate *source* rows, and reports unknown categories without deleting them. `sql/07_business_validation.sql` expresses parallel PostgreSQL checks. The validator does **not** certify the Power BI semantic model or its visual calculations; compare those separately before treating dashboard values as independently verified.
