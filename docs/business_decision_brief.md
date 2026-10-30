# BankPulse — Business Decision Brief

## Business context and analytical scope

A marketing team needs to understand which historical campaign patterns warrant investigation and where aggregate subscription volume differs from observed response efficiency. This is **retrospective, descriptive analysis** of the UCI Bank Marketing source file (`bank-full.csv`), **not** a deployed recommendation engine or a measure of achieved business improvement.

**Unit of analysis:** a campaign record. The source provides no verified unique customer identifier. **Baseline:** 45,211 eligible campaign records with `y=yes/no`, of which 5,289 show a subscription (11.70%). Conversion is `subscribed campaign records ÷ eligible campaign records × 100`.

Reproducibility: run `python scripts/validate_metrics.py --report docs/validation_report.md`. PostgreSQL equivalents are in `sql/07_business_validation.sql`. The CSV calculation was independently executed; the new PostgreSQL SQL and Power BI measures were not executed in this packaging environment.

## Question 1 — Which categories generate the most subscriptions, rather than just the highest rate?

**SQL evidence:** `sql/07_business_validation.sql`, query **Q1**. The script aggregates campaign records by `job`, calculates their conversion rate, and divides their subscriptions by the **5,289** overall subscriptions.

| Job category | Campaign records | Subscriptions | Conversion | Share of all subscriptions |
|---|---:|---:|---:|---:|
| Student | 938 | 269 | 28.68% | 5.09% |
| Management | 9,458 | 1,301 | 13.76% | 24.60% |
| Technician | 7,597 | 840 | 11.06% | 15.88% |

**Finding:** The student group has higher observed response efficiency, but management produces far more subscription records. Ranking groups only by conversion would miss this volume distinction.

**Decision implication:** An internal campaign report should show **both rate and volume**, with denominators and sample sizes. This supports a more complete assessment of aggregate performance; it is **not** justification for restricting financial-product access or targeting individuals by occupation, age, or other protected/proxy characteristics. Any real use would require bank compliance review, additional contextual variables, and prospective validation.

**Validation:** All job groups reconcile to 45,211 records and 5,289 subscriptions; `management` = 1,301 and `student` = 269 subscriptions in an independent CSV recalculation.

## Question 2 — Is a known prior campaign success associated with a stronger current response?

**SQL evidence:** `sql/07_business_validation.sql`, query **Q2**. Each previous-outcome category is calculated against its own number of eligible campaign records.

| Previous outcome | Records | Subscriptions | Conversion |
|---|---:|---:|---:|
| Success | 1,511 | 978 | 64.73% |
| Failure | 4,901 | 618 | 12.61% |
| Other | 1,840 | 307 | 16.68% |
| Unknown | 36,959 | 3,386 | 9.16% |

**Finding:** Previously successful outcome records have a 64.73% current subscription rate, compared with 9.16% among records with `previous_outcome=unknown` (a **55.57 percentage-point** gap using displayed rounded rates). The `unknown` category includes 36,954 records with no earlier contact (`previous=0`, `pdays=-1`), **but it is not synonymous with no previous contact in every row**.

**Decision implication:** Before any contact-history prioritization, assess previous-outcome completeness and compare like-for-like records. A compliance-reviewed, consent-respecting prospective test would be needed to determine if acting on prior outcomes improves outcomes.

**Validation:** The four categories reconcile to the full dataset. Excluding the `unknown` category entirely changes the observed benchmark from **11.70%** to **23.06%**; never silently drop it.

## Question 3 — How does recorded current-campaign contact frequency relate to observed response?

**SQL evidence:** `sql/07_business_validation.sql`, query **Q3**. Current `campaign` values are partitioned into mutually exclusive buckets with explicit handling for invalid values.

| Contacts in current campaign | Records | Subscriptions | Conversion |
|---|---:|---:|---:|
| 1 | 17,544 | 2,561 | 14.60% |
| 2–3 | 18,026 | 2,019 | 11.20% |
| 4–5 | 5,286 | 456 | 8.63% |
| 6–10 | 3,159 | 206 | 6.52% |
| 11+ | 1,196 | 47 | 3.93% |

**Finding:** Observed conversion is progressively lower at higher contact counts. The comparison between 1 contact and 11+ contacts is **10.67 percentage points**, based on displayed rounded rates.

**Decision implication:** Investigate whether contact intensity correlates with audience mix, channel, timing, or campaign policy. Do **not** claim that the extra attempts *caused* lower response, impose an arbitrary contact cap from this table alone, or count these rows as distinct customers. A controlled experiment and contact-policy review would be needed before operational changes.

**Validation:** The five contact segments sum to exactly 45,211 campaign records and 5,289 subscriptions. All rates were independently recalculated from the CSV.

## Additional data-quality finding — Unknown contact type alters conclusions

- `contact=unknown`: 13,020 records, 530 subscriptions, **4.07%** conversion.
- Known `contact` values combined: 32,191 records, 4,759 subscriptions, **14.78%** conversion.
- Overall including all categories: **11.70%** conversion.

This demonstrates why analysts should **profile `unknown` categories and explain denominator changes**, not treat unknowns as clean nulls or silently exclude them. These differences might reflect different campaign circumstances rather than a direct effect of recorded contact method.

## Handoff checklist for a stakeholder conversation

1. Confirm the business audience and metric definitions (campaign record, subscription, conversion, reporting window).
2. Explain one insight using *count, rate, sample size,* and its comparison group.
3. State at least one limitation (no unique customer ID, observational data, unknown categories, no year, or contact duration known after call).
4. Distinguish **suggested investigation** from a verified operational result or causal business impact.
5. Re-run SQL reconciliation and compare five visible Power BI KPI/visual totals with independently calculated SQL outputs before claiming dashboard cross-validation.

The original Power BI file and screenshots are preserved unchanged. This brief describes findings verified against the CSV; it does not claim a live bank deployment or measured campaign uplift.
