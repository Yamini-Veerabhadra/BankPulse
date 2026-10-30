# BankPulse — Independent CSV Metric Validation

**Scope:** Source CSV re-calculation using only Python standard library; not a PostgreSQL or Power BI runtime audit.
**Method:** All source rows with binary `y` = `yes`/`no` count as eligible campaign records. Rows are not unique identified customers.

- Campaign records: **45,211**
- Subscribed records: **5,289**
- Overall response rate: **11.70%**
- Exact duplicate source rows (all 17 original fields): **0**
- Rows matching `previous=0`, `pdays=-1`, `poutcome=unknown`: **36,954**

## Contact frequency

| Current-campaign contacts | Records | Subscriptions | Conversion | Share of subscriptions |
|---|---:|---:|---:|---:|
| 1 | 17,544 | 2,561 | 14.60% | 48.42% |
| 2-3 | 18,026 | 2,019 | 11.20% | 38.17% |
| 4-5 | 5,286 | 456 | 8.63% | 8.62% |
| 6-10 | 3,159 | 206 | 6.52% | 3.89% |
| 11+ | 1,196 | 47 | 3.93% | 0.89% |

## Job categories — selected comparisons

| Job category | Records | Subscriptions | Conversion | Share of subscriptions |
|---|---:|---:|---:|---:|
| management | 9,458 | 1,301 | 13.76% | 24.60% |
| student | 938 | 269 | 28.68% | 5.09% |
| retired | 2,264 | 516 | 22.79% | 9.76% |
| technician | 7,597 | 840 | 11.06% | 15.88% |
| blue-collar | 9,732 | 708 | 7.27% | 13.39% |

## Previous campaign outcome

| Previous outcome | Records | Subscriptions | Conversion | Share of subscriptions |
|---|---:|---:|---:|---:|
| success | 1,511 | 978 | 64.73% | 18.49% |
| other | 1,840 | 307 | 16.68% | 5.80% |
| failure | 4,901 | 618 | 12.61% | 11.68% |
| unknown | 36,959 | 3,386 | 9.16% | 64.02% |

## Loan profiles

| Loan profile | Records | Subscriptions | Conversion | Share of subscriptions |
|---|---:|---:|---:|---:|
| No housing or personal loan | 17,204 | 3,135 | 18.22% | 59.27% |
| Housing loan only | 20,763 | 1,670 | 8.04% | 31.57% |
| Personal loan only | 2,877 | 219 | 7.61% | 4.14% |
| Both loan types | 4,367 | 265 | 6.07% | 5.01% |

## Unknown-category sensitivity

| Field | Unknown rows | Unknown conversion | Known rows | Known-only conversion |
|---|---:|---:|---:|---:|
| `job` | 288 | 11.81% | 44,923 | 11.70% |
| `education` | 1,857 | 13.57% | 43,354 | 11.62% |
| `contact` | 13,020 | 4.07% | 32,191 | 14.78% |
| `poutcome` | 36,959 | 9.16% | 8,252 | 23.06% |

## Source completeness

- Empty-string fields: **0** occurrences across all original attributes.
- Fields containing blank strings: **none**.

## Reconciliation checks

| Partition | Records reconcile | Subscriptions reconcile |
|---|---|---|
| `contact_frequency` | PASS | PASS |
| `job_category` | PASS | PASS |
| `previous_outcome` | PASS | PASS |
| `loan_profile` | PASS | PASS |

The original CSV was not modified. Power BI measure correctness and PostgreSQL execution require separate verification.
Associations are observational; no causal effect or real-world campaign improvement was measured.
