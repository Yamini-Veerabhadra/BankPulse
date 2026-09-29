# BankPulse — Customer & Campaign Opportunity Analytics

## Project Overview

BankPulse is an end-to-end banking analytics project that analyzes **45,211 direct marketing campaign records** using **PostgreSQL, SQL, and Power BI** to understand customer characteristics, campaign effectiveness, and term-deposit subscription patterns.

The project follows a complete analytics workflow: raw data is loaded and validated in PostgreSQL, explored using SQL, segmented through analytical feature engineering, and translated into a two-page Power BI dashboard for business-facing reporting and visualization.

The objective is not simply to identify which records converted, but to understand how customer financial characteristics, existing loan relationships, previous campaign interactions, contact frequency, and campaign timing are associated with subscription outcomes.

> **Overall term-deposit conversion rate: 11.70%**

---

## Business Problem

A retail bank conducting direct marketing campaigns wants to better understand the factors associated with successful term-deposit subscriptions.

The analysis focuses on several business questions:

- Which customer profiles show different observed subscription rates?
- How does existing loan status relate to campaign response?
- How does previous campaign history relate to current campaign outcomes?
- How does repeated contact relate to observed conversion?
- Which campaign periods show stronger or weaker response?
- Which segments generate the most subscriptions versus the highest conversion rates?
- What insights can be derived without incorrectly interpreting association as causation?

---

## Dataset

The project uses the **Bank Marketing dataset** containing **45,211 campaign records**.

The source data contains customer demographic attributes, financial characteristics, loan indicators, campaign interaction information, previous campaign information, and the final term-deposit subscription outcome.

Data Source: UCI Machine Learning Repository — Bank Marketing dataset. The dataset contains direct marketing campaign data from a Portuguese banking institution and is used here for educational and portfolio analysis purposes.

### Main Fields

| Category | Fields |
|---|---|
| Customer Profile | `age`, `job`, `marital`, `education` |
| Financial Profile | `balance`, `credit_default`, `housing_loan`, `personal_loan` |
| Current Campaign | `contact_type`, `contact_day`, `contact_month`, `contact_duration`, `campaign_contacts` |
| Previous Campaign | `days_since_previous_contact`, `previous_contacts`, `previous_outcome` |
| Target Outcome | `subscribed` |

A PostgreSQL `SERIAL` primary key named `customer_id` was added during database creation for technical row identification.

**Important:** this generated ID does not represent a genuine customer identifier. Therefore, the analysis refers to the observations primarily as **records or campaign records**, rather than assuming that every row represents a unique individual.

---

## Technology Stack

- **PostgreSQL 17** — relational database and analytical SQL
- **pgAdmin 4** — database administration and query execution
- **Power BI Desktop** — data modeling, DAX measures, and interactive dashboard development
- **Power Query** — analytical feature creation and data preparation for reporting
- **Visual Studio Code** — SQL development and project organization
- **Git / GitHub** — version control and portfolio hosting

---

## Project Structure

BankPulse/
│
├── data/
│   └── raw/
│       └── bank-full.csv
│
├── docs/
│   └── analysis_summary.md
│
├── powerbi/
│   └── BankPulse_Dashboard.pbix
│
├── screenshots/
│   ├── campaign_overview.png
│   └── customer_campaign_insights.png
│
├── sql/
│   ├── 01_database_setup.sql
│   ├── 02_data_quality.sql
│   ├── 03_exploratory_analysis.sql
│   ├── 04_customer_segmentation.sql
│   ├── 05_campaign_analysis.sql
│   └── 06_advanced_analysis.sql
│
├── README.md
└── .gitignore

The raw dataset is preserved without modification. Data validation and core analytical work are performed in PostgreSQL using SQL, while Power BI is used to create reporting-oriented features, DAX measures, and interactive dashboard visualizations.

---

# Power BI Dashboard

The Power BI dashboard translates the SQL analysis into a two-page reporting experience focused on campaign performance and customer/campaign insights.

## Page 1 — Campaign Overview

The Campaign Overview provides a high-level view of campaign performance, including:

- **45,211** campaign records
- **5,289** term-deposit subscriptions
- **11.70%** overall conversion rate
- Monthly conversion patterns
- Conversion by campaign contact frequency
- Conversion by loan profile
- Conversion by previous campaign outcome

![BankPulse Campaign Overview](screenshots/campaign_overview.png)

## Page 2 — Customer & Campaign Insights

The second page provides deeper segment and interaction analysis, including:

- Conversion rate by job
- Total subscriptions by job
- Conversion rate by balance segment
- Conversion rate by age group
- Conversion rate by contact type
- Average contact duration by subscription outcome

![BankPulse Customer and Campaign Insights](screenshots/customer_campaign_insights.png)

The dashboard intentionally presents both **conversion rate** and **subscription volume** because a segment with a high response rate does not necessarily contribute the largest number of total subscriptions.

Call duration is included only as a retrospective descriptive measure. Because duration is known during or after the campaign interaction, it should not be interpreted as a pre-call targeting or predictive feature.

# Analytical Workflow

## 1. Database Setup

The raw CSV dataset was imported into PostgreSQL and stored in a structured relational table.

Column names were standardized to improve readability and make subsequent SQL analysis easier to understand.

Examples include:

```text
default   → credit_default
housing   → housing_loan
loan      → personal_loan
contact   → contact_type
campaign  → campaign_contacts
pdays     → days_since_previous_contact
previous  → previous_contacts
poutcome  → previous_outcome
y         → subscribed
```

---

## 2. Data Quality Assessment

Before performing business analysis, the dataset was profiled for completeness, validity, duplicates, and categorical consistency.

### Validation Performed

- Confirmed **45,211 records**
- Checked SQL `NULL` values across key analytical fields
- Validated numeric ranges
- Examined business-coded `unknown` values
- Checked exact duplicate records across the original source attributes
- Validated categorical domains
- Investigated negative account balances
- Investigated special previous-campaign values

### Key Data Quality Findings

No SQL `NULL` values were found in the major analytical fields.

Several variables instead use `unknown` as a legitimate source-system category:

- Job: approximately **0.64% unknown**
- Education: approximately **4.11% unknown**
- Contact type: approximately **28.80% unknown**
- Previous campaign outcome: approximately **81.75% unknown**

Negative balances were retained because a negative balance can represent a legitimate financial state and should not automatically be classified as erroneous data.

No exact duplicate records were identified across all original source attributes.

The combination:

```text
previous_contacts = 0
days_since_previous_contact = -1
previous_outcome = 'unknown'
```

occurred in **36,954 records** and was interpreted as indicating no usable previous campaign history.

---

# Key Findings

## Overall Campaign Performance

Across **45,211 campaign records**, there were **5,289 term-deposit subscriptions**, producing an overall observed conversion rate of:

### **11.70%**

This rate is used throughout the project as a baseline for evaluating individual segments.

---

## 1. Contact Frequency and Campaign Response

Observed conversion decreased across progressively higher campaign-contact frequency groups.

| Campaign Contacts | Records | Subscriptions | Conversion |
|---|---:|---:|---:|
| 1 Contact | 17,544 | 2,561 | **14.60%** |
| 2–3 Contacts | 18,026 | 2,019 | **11.20%** |
| 4–5 Contacts | 5,286 | 456 | **8.63%** |
| 6–10 Contacts | 3,159 | 206 | **6.52%** |
| 11+ Contacts | 1,196 | 47 | **3.93%** |

Compared with the first-contact group, the 11+ contact group had an observed conversion rate **10.67 percentage points lower**.

### Interpretation

Repeatedly contacted records showed progressively lower observed response rates.

This may indicate diminishing campaign opportunity among records requiring many attempts. However, the analysis is observational and does **not** establish that additional contacts caused lower conversion. More difficult-to-convert prospects may naturally receive more contact attempts.

---

## 2. Existing Loan Relationships

Loan status showed a substantial association with campaign response.

| Loan Profile | Conversion |
|---|---:|
| No Housing or Personal Loan | **18.22%** |
| Housing Loan Only | **8.04%** |
| Personal Loan Only | **7.61%** |
| Both Loan Types | **6.07%** |

Records with neither housing nor personal loans showed considerably higher observed term-deposit conversion than records carrying existing loans.

This relationship is treated as an observed association rather than evidence that loan ownership itself causes differences in subscription behavior.

---

## 3. Previous Campaign Outcome

Previous campaign results were strongly associated with current subscription behavior.

| Previous Outcome | Records | Subscriptions | Conversion |
|---|---:|---:|---:|
| Success | 1,511 | 978 | **64.73%** |
| Other | 1,840 | 307 | **16.68%** |
| Failure | 4,901 | 618 | **12.61%** |
| Unknown | 36,959 | 3,386 | **9.16%** |

Records associated with a previous successful campaign showed a **64.73%** current conversion rate, substantially above the overall **11.70%** baseline.

A separate engineered campaign-history variable distinguished records with no previous campaign history from ambiguous `unknown` values.

---

## 4. Previous Contact Recency

Among records with usable previous-contact history, conversion varied across recency groups.

| Previous Contact Recency | Records | Subscriptions | Conversion |
|---|---:|---:|---:|
| 0–30 Days | 188 | 28 | **14.89%** |
| 31–90 Days | 530 | 223 | **42.08%** |
| 91–180 Days | 2,480 | 680 | **27.42%** |
| 181–365 Days | 4,416 | 786 | **17.80%** |
| 366+ Days | 643 | 188 | **29.24%** |

The relationship is not monotonic. The highest observed conversion occurred in the **31–90 day** group rather than simply increasing or decreasing with recency.

---

## 5. Campaign Performance by Month

Campaign response varied considerably by contact month.

| Month | Records | Subscriptions | Conversion | Difference vs Overall |
|---|---:|---:|---:|---:|
| March | 477 | 248 | **51.99%** | +40.29 pp |
| December | 214 | 100 | **46.73%** | +35.03 pp |
| September | 579 | 269 | **46.46%** | +34.76 pp |
| October | 738 | 323 | **43.77%** | +32.07 pp |
| April | 2,932 | 577 | **19.68%** | +7.98 pp |
| February | 2,649 | 441 | **16.65%** | +4.95 pp |
| August | 6,247 | 688 | 11.01% | -0.69 pp |
| June | 5,341 | 546 | 10.22% | -1.48 pp |
| November | 3,970 | 403 | 10.15% | -1.55 pp |
| January | 1,403 | 142 | 10.12% | -1.58 pp |
| July | 6,895 | 627 | 9.09% | -2.60 pp |
| May | 13,766 | 925 | **6.72%** | -4.98 pp |

Several lower-volume months showed substantially higher observed conversion rates.

However, the dataset does not contain a year field in the analytical table. Therefore, these results are treated as **month-level descriptive patterns**, not as a continuous chronological time-series trend.

---

## 6. Conversion Rate vs Subscription Volume

The analysis demonstrates why conversion rate alone is not sufficient for evaluating business contribution.

For example:

| Job Category | Conversion | Subscriptions | Share of All Subscriptions |
|---|---:|---:|---:|
| Student | **28.68%** | 269 | 5.09% |
| Retired | **22.79%** | 516 | 9.76% |
| Management | 13.76% | **1,301** | **24.60%** |
| Technician | 11.06% | **840** | **15.88%** |
| Blue-collar | 7.27% | **708** | **13.39%** |

Students showed the highest observed conversion rate, but management generated the largest absolute number of subscriptions.

### Business Insight

A segment can have a strong conversion rate while contributing relatively little total volume, while a lower-converting high-volume segment may generate more total subscriptions.

For this reason, the project evaluates both:

- **Response efficiency — conversion rate**
- **Business contribution — subscription volume**

---

## 7. Multi-Factor Segmentation

Age, balance, and loan status were combined to investigate whether multi-dimensional profiles reveal patterns that are hidden when variables are analyzed independently.

Only segments containing at least **500 records** were retained for this exploratory comparison to reduce emphasis on very small groups.

Several no-loan profiles produced conversion rates above the overall **11.70%** baseline.

Examples included:

- 60+ / Lower Balance / No Loans — **38.22%**
- 60+ / Higher Balance / No Loans — **37.42%**
- Under 30 / Higher Balance / No Loans — **35.95%**
- Under 30 / Lower Balance / No Loans — **31.11%**
- 30–39 / Higher Balance / No Loans — **21.80%**

These results demonstrate the value of analyzing combinations of attributes rather than relying exclusively on single-variable comparisons.

The age analysis is descriptive and is not presented as a recommendation for age-based automated targeting.

---

## 8. Call Duration and Subscription Outcome

Call duration showed a strong descriptive relationship with subscription outcome.

Average duration:

| Outcome | Average Duration |
|---|---:|
| Did Not Subscribe | **221.18 seconds** |
| Subscribed | **537.29 seconds** |

Conversion also increased across duration groups:

| Call Duration | Records | Subscriptions | Conversion |
|---|---:|---:|---:|
| Under 1 Minute | 4,659 | 9 | **0.19%** |
| 1–3 Minutes | 17,878 | 692 | **3.87%** |
| 3–5 Minutes | 10,345 | 1,121 | **10.84%** |
| 5–10 Minutes | 8,527 | 1,630 | **19.12%** |
| 10+ Minutes | 3,802 | 1,837 | **48.32%** |

### Important Analytical Limitation

`contact_duration` is only known **after a campaign interaction has occurred**.

Therefore, although it is useful for retrospective campaign analysis, it should **not be used as a pre-call targeting or prediction feature**.

Using post-interaction duration to predict an outcome before the call would introduce **data leakage**.

---

# Advanced SQL Techniques Demonstrated

The project progresses beyond basic aggregation and demonstrates:

### Common Table Expressions (CTEs)

CTEs were used to separate feature engineering, aggregation, and final reporting logic.

```sql
WITH segment_performance AS (
    ...
)
SELECT *
FROM segment_performance;
```

### Conditional Aggregation

```sql
SUM(
    CASE
        WHEN subscribed = 'yes' THEN 1
        ELSE 0
    END
)
```

This pattern was used extensively to calculate subscriptions and conversion rates.

### Window Functions

The advanced analysis uses:

```sql
RANK()
DENSE_RANK()
LAG()
FIRST_VALUE()
SUM() OVER()
```

### PARTITION BY

Segment rankings were calculated independently within customer groups.

```sql
DENSE_RANK() OVER (
    PARTITION BY age_group
    ORDER BY conversion_rate_pct DESC
)
```

### LAG()

`LAG()` was used to compare each month-level conversion rate with the preceding month in calendar order.

### Cumulative Window Calculations

```sql
SUM(monthly_subscriptions) OVER (
    ORDER BY month_number
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

### Benchmark Comparisons

Overall campaign conversion was calculated once and attached to segment-level results using CTEs and `CROSS JOIN`, enabling comparison against the **11.70% overall benchmark**.

### Custom Feature Engineering

Raw attributes were transformed into analytical categories such as:

- Age groups
- Balance profiles
- Loan profiles
- Campaign contact-frequency groups
- Previous-contact recency
- Previous campaign-history classifications
- Call-duration groups

---

# Analytical Principles Applied

Several analytical guardrails were followed throughout the project.

### Association Is Not Causation

The dataset is observational.

For example, higher campaign-contact frequency is associated with lower observed conversion, but this does not demonstrate that additional contact attempts caused lower conversion.

### Sample Size Matters

Conversion percentages were interpreted alongside record counts.

A high percentage from a small segment was not treated as equivalent evidence to the same percentage from a much larger segment.

### Unknown Does Not Automatically Mean Missing

Source-system values labeled `unknown` were retained rather than arbitrarily deleted.

### Raw Data Was Preserved

The original dataset was kept unchanged in the raw-data layer. Analytical transformations were implemented through SQL.

### Avoiding Data Leakage

Call duration was restricted to retrospective analysis because it is not available before the interaction takes place.

---

# Data Limitations

The analysis has several important limitations:

1. The dataset does not provide a genuine unique customer identifier. The generated PostgreSQL `customer_id` is only a technical row identifier.

2. The dataset contains campaign-level information rather than detailed transaction history.

3. `unknown` values occur in several categorical fields and may represent unavailable or unrecorded source-system information.

4. Month and day are available, but the analytical table does not contain a year field. Month-level analysis should therefore not be interpreted as a continuous chronological time series.

5. Segmentation thresholds such as balance bands, age groups, and the 500-record minimum were analyst-defined for exploratory analysis.

6. The analysis identifies associations within historical data and does not establish causal relationships.

7. Contact duration is a post-interaction variable and cannot safely be used for pre-call targeting.

8. Observed historical differences should not automatically be converted into targeting rules without considering fairness, compliance, business context, and additional validation.

---

# SQL Files

### `01_database_setup.sql`

Creates the PostgreSQL table structure used for the project.

### `02_data_quality.sql`

Performs data validation, NULL checks, unknown-category profiling, range checks, duplicate analysis, and categorical validation.

### `03_exploratory_analysis.sql`

Establishes baseline campaign performance and explores relationships involving job, balance, loans, campaign contacts, previous outcomes, contact type, and age.

### `04_customer_segmentation.sql`

Creates multi-dimensional customer profiles using age, balance, loan status, and previous campaign behavior.

### `05_campaign_analysis.sql`

Analyzes campaign-contact efficiency, timing, communication channel, previous campaign behavior, recency, and post-contact duration patterns.

### `06_advanced_analysis.sql`

Demonstrates advanced SQL techniques including window functions, ranking, `PARTITION BY`, `LAG()`, cumulative calculations, benchmark comparisons, and multi-CTE analysis.

---

# How to Run the Project

## 1. Create a PostgreSQL Database

Create a local PostgreSQL database for the project.

Example:

```sql
CREATE DATABASE bankpulse;
```

## 2. Run the Database Setup

Execute:

```text
sql/01_database_setup.sql
```

## 3. Import the Dataset

Import:

```text
data/raw/bank-full.csv
```

into the `bank_marketing_raw` table.

CSV import configuration:

```text
Header:    Yes
Delimiter: ;
Quote:     "
Escape:    "
```

The generated `customer_id` column should be excluded from the CSV import because PostgreSQL creates it automatically.

## 4. Run the Analytical SQL Files

Execute the scripts in sequence:

```text
02_data_quality.sql
03_exploratory_analysis.sql
04_customer_segmentation.sql
05_campaign_analysis.sql
06_advanced_analysis.sql
```

## 5. Open the Power BI Dashboard

The completed Power BI report is available at:

```text
powerbi/BankPulse_Dashboard.pbix
```

Open the file using Power BI Desktop.

The report contains two pages:

- **Campaign Overview** — overall campaign KPIs, monthly conversion patterns, contact-frequency performance, loan-profile performance, and previous campaign outcomes.
- **Customer & Campaign Insights** — job-level conversion and subscription volume, balance segments, age groups, contact types, and retrospective contact-duration analysis.

The dashboard screenshots can also be viewed directly in the `screenshots/` folder without opening Power BI Desktop.

---
# Project Takeaways

BankPulse demonstrates an end-to-end analytics workflow covering:

**raw data → PostgreSQL → data validation → SQL analysis → segmentation → advanced SQL → Power BI visualization → business interpretation**

The project emphasizes both technical execution and analytical reasoning: validating data before analysis, distinguishing conversion efficiency from business volume, considering sample sizes, avoiding causal overstatement, identifying data leakage, documenting limitations, and communicating findings through an interactive Power BI dashboard.

