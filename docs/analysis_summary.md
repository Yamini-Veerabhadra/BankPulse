# BankPulse — Analysis Summary

## Objective

The objective of BankPulse is to analyze historical bank marketing campaign records and identify patterns associated with term-deposit subscriptions.

The analysis focuses on campaign performance, customer financial characteristics, previous campaign interactions, contact frequency, and multi-dimensional segmentation.

---

## Dataset Summary

- Total campaign records: 45,211
- Total subscriptions: 5,289
- Overall conversion rate: 11.70%
- Database: PostgreSQL

The dataset does not contain a genuine unique customer identifier. The `customer_id` used in PostgreSQL is a generated technical row identifier.

---

## Key Findings

### 1. Overall Campaign Conversion

The campaign produced an overall observed term-deposit conversion rate of 11.70%.

This rate was used as the baseline when evaluating individual segments.

---

### 2. Campaign Contact Frequency

Observed conversion declined across higher contact-frequency groups:

- 1 contact: 14.60%
- 2–3 contacts: 11.20%
- 4–5 contacts: 8.63%
- 6–10 contacts: 6.52%
- 11+ contacts: 3.93%

The 11+ contact group converted 10.67 percentage points below the first-contact group.

This is an association and does not establish that repeated contact caused lower conversion.

---

### 3. Existing Loan Status

Records with neither a housing loan nor a personal loan showed an 18.22% conversion rate.

Records with both loan types showed a 6.07% conversion rate.

Loan status therefore showed a strong association with historical campaign response.

---

### 4. Previous Campaign Performance

Previous campaign success was strongly associated with current campaign response.

Records with a previous successful outcome converted at 64.73%, compared with the overall campaign baseline of 11.70%.

Records with no usable previous campaign history converted at approximately 9.16%.

---

### 5. Previous Contact Recency

Among records with usable previous-contact history:

- 0–30 days: 14.89%
- 31–90 days: 42.08%
- 91–180 days: 27.42%
- 181–365 days: 17.80%
- 366+ days: 29.24%

The pattern was not monotonic, indicating that response did not simply increase or decrease as previous contact became more recent.

---

### 6. Campaign Month

Several lower-volume months showed substantially higher observed conversion.

Examples:

- March: 51.99%
- December: 46.73%
- September: 46.46%
- October: 43.77%

May contained 13,766 records but converted at 6.72%.

Because the analytical dataset does not contain a year field, these results are interpreted as month-level descriptive patterns rather than a continuous chronological trend.

---

### 7. Conversion Rate vs Subscription Volume

High conversion rate did not necessarily mean high total business contribution.

Students had the highest job-category conversion rate at 28.68%, but accounted for only 5.09% of total subscriptions.

Management converted at 13.76% but generated 1,301 subscriptions, representing 24.60% of all subscriptions.

This demonstrates the importance of evaluating both conversion efficiency and absolute business volume.

---

### 8. Multi-Factor Segmentation

Combining age, balance, and loan status revealed several above-baseline segments.

Among segments containing at least 500 records:

- 60+ / Lower Balance / No Loans: 38.22%
- 60+ / Higher Balance / No Loans: 37.42%
- Under 30 / Higher Balance / No Loans: 35.95%
- Under 30 / Lower Balance / No Loans: 31.11%
- 30–39 / Higher Balance / No Loans: 21.80%

These results are descriptive and are not recommendations for age-based targeting.

---

### 9. Call Duration

Average call duration differed substantially by campaign outcome:

- Non-subscribers: 221.18 seconds
- Subscribers: 537.29 seconds

Observed conversion by duration:

- Under 1 minute: 0.19%
- 1–3 minutes: 3.87%
- 3–5 minutes: 10.84%
- 5–10 minutes: 19.12%
- 10+ minutes: 48.32%

Call duration is only known after an interaction occurs.

Therefore, it is useful for retrospective campaign analysis but should not be used as a pre-call targeting feature because doing so would introduce data leakage.

---

## Analytical Considerations

The analysis follows several important principles:

- Association is not treated as causation.
- Segment percentages are evaluated alongside sample sizes.
- Source-system `unknown` values are preserved rather than automatically deleted.
- Negative balances are treated as potentially legitimate financial values.
- Analyst-defined segmentation thresholds are documented.
- Post-interaction variables are not treated as pre-interaction predictors.
- Historical demographic patterns are not automatically converted into targeting recommendations.

---

## Conclusion

BankPulse demonstrates how SQL can be used to transform raw campaign data into structured business analysis.

The project identifies meaningful differences in campaign response across contact frequency, loan status, previous campaign history, timing, and customer profiles while maintaining appropriate analytical limitations.

The analysis also demonstrates that campaign evaluation should consider both conversion efficiency and absolute subscription volume rather than relying on a single performance metric.