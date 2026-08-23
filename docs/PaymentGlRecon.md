# Technical Design & Operational Runbook: Payment vs. General Ledger Reconciliation

**Object Name:** `stg.usp_Recon_Payments_vs_GeneralLedger`

**Schema / Database:** `FSA_Staging.stg`

**Object Type:** Stored Procedure

**Architecture:** 4-Pillar Financial Reconciliation Framework

**Classification:** Financial Controls / Data Quality Assurance

---

## 1. Overview & Business Purpose

The `stg.usp_Recon_Payments_vs_GeneralLedger` stored procedure verifies monetary consistency between cash-in transactions (`stg.Payments`) and financial accounting postings (`stg.GeneralLedgers`).

It identifies discrepancies across three primary failure modes:

1. **Unposted Payments (Orphan Payments):** Cash collected in operational systems without backing entries in the General Ledger.
2. **Unlinked GL Journals (Orphan GL):** Ledger entries created without a traceable payment transaction.
3. **Monetary Variances:** Matched policy records where total cash payments diverge from the net ledger position beyond an acceptable threshold (`@DiscrepancyThreshold`).

---

## 2. Technical Architecture & Design Principles

```
  ┌─────────────────────────┐          ┌─────────────────────────┐
  │      stg.Payments       │          │   stg.GeneralLedgers    │
  └────────────┬────────────┘          └────────────┬────────────┘
               │                                    │
               ▼                                    ▼
  ┌─────────────────────────┐          ┌─────────────────────────┐
  │ CTE: PaymentSummary     │          │ CTE: GeneralLedgerSummary│
  │  - GROUP BY policy_ref  │          │  - GROUP BY policy_ref  │
  │  - SUM(payment_amount)  │          │  - SUM(Debit - Credit)  │
  └────────────┬────────────┘          └────────────┬────────────┘
               │                                    │
               └───────────────┬────────────────────┘
                               │ FULL OUTER JOIN ON policy_reference
                               ▼
               ┌─────────────────────────────────┐
               │         #ReconResults           │
               │  - Net & Gross Variances        │
               │  - recon_status Classification  │
               │  - Automated Diagnostic Flags   │
               └───────────────┬─────────────────┘
                               │
       ┌───────────────────────┼───────────────────────┐
       ▼                       ▼                       ▼
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│ RESULT SET 1 │        │ RESULT SET 2 │        │ RESULT SET 3 │
│  Pillar 1:   │        │  Pillar 2:   │        │ Pillars 3/4: │
│ Executive KPI│        │   Category   │        │  Exceptions  │
│   Summary    │        │  Breakdown   │        │  & Root Cause│
└──────────────┘        └──────────────┘        └──────────────┘

```

### Key Technical Controls

* **M:N Cartesian Fan-Out Prevention:** Source tables are independently pre-aggregated at `policy_reference` level before joining.
* **Double-Entry Accounting Standard:** Net GL position is calculated strictly as $\text{Debit} - \text{Credit}$.
* **Defensive Variance Tracking:**
* $\text{Net Variance} = \sum(\text{Payment} - \text{GL})$ (Measures overall pipeline balance).
* $\text{Gross Exposure} = \sum \vert{}\text{Payment} - \text{GL}\vert{}$ (Measures cumulative gross financial risk).


* **Targeted Exception Re-Join:** Deep line-item fields are joined only for non-matched policies (`recon_status <> 'Matched'`) to maintain minimal TempDB footprint.

---

## 3. Parameter Specifications

| Parameter | Data Type | Default | Direction | Description |
| --- | --- | --- | --- | --- |
| `@DiscrepancyThreshold` | `DECIMAL(18,2)` | `0.01` | `INPUT` | Monetary tolerance before a record is flagged as an `Amount Mismatch`. |

---

## 4. Reporting Pillars & Result Set Specifications

### Result Set 1: Executive KPI Summary (Pillar 1)

* **Audience:** Leadership, Audit Leads, Data Governance.
* **Granularity:** 1 Row summary.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `total_policies_evaluated` | `INT` | Total unique policy references evaluated across both datasets. |
| `total_payment_records` | `BIGINT` | Total raw payment records processed. |
| `total_payment_amount_gbp` | `DECIMAL(18,2)` | Total monetary value of operational payments. |
| `total_gl_records` | `BIGINT` | Total raw general ledger journal lines processed. |
| `total_gl_amount_gbp` | `DECIMAL(18,2)` | Total net monetary position of ledger postings. |
| `match_rate_percentage` | `DECIMAL(5,2)` | Percentage of policies that balanced cleanly within threshold. |
| `total_net_variance_gbp` | `DECIMAL(18,2)` | Systemic imbalance across entire portfolio. |
| `total_gross_exposure_gbp` | `DECIMAL(18,2)` | Total absolute financial exposure across all discrepant policies. |

---

### Result Set 2: Category Breakdown & Risk Distribution (Pillar 2)

* **Audience:** Financial Controllers, Operations Managers.
* **Granularity:** Grouped by `recon_status` (Ordered by `category_gross_exposure_gbp DESC`).

| Column Name | Data Type | Description |
| --- | --- | --- |
| `recon_status` | `VARCHAR(30)` | Bucket: `Matched`, `Amount Mismatch`, `Orphan Payment`, `Orphan GL`. |
| `total_policies` | `INT` | Policy volume within the category. |
| `total_payment_records` | `BIGINT` | Total payment transactions in this category. |
| `total_payment_amount_gbp` | `DECIMAL(18,2)` | Total payments value in this category. |
| `total_gl_records` | `BIGINT` | Total GL entries in this category. |
| `total_gl_amount_gbp` | `DECIMAL(18,2)` | Total GL net value in this category. |
| `category_net_variance_gbp` | `DECIMAL(18,2)` | Net balancing error within this category. |
| `category_gross_exposure_gbp` | `DECIMAL(18,2)` | Total absolute financial risk concentrated in this category. |
| `pct_of_total_exposure` | `DECIMAL(5,2)` | Percentage contribution of this category to overall pipeline exposure. |

---

### Result Set 3: Actionable Exception Detail & Diagnostics (Pillars 3 & 4)

* **Audience:** Operations Analysts, Data Engineers, Claims Handlers.
* **Granularity:** Line-item detail for exceptions only (`recon_status <> 'Matched'`).

| Column Name | Source | Description |
| --- | --- | --- |
| `policy_reference` | `#ReconResults` | The reconciliation key. |
| `recon_status` | `#ReconResults` | Specific category of failure. |
| `gross_variance` | `#ReconResults` | Policy-level total exposure (used for triage ordering). |
| `net_variance` | `#ReconResults` | Directional variance ($\text{Payment} - \text{GL}$). |
| `payment_reference` | `stg.Payments` | Raw payment reference identifier. |
| `payment_amount_gbp` | `stg.Payments` | Raw payment transaction amount. |
| `payment_date` | `stg.Payments` | Execution date of the payment. |
| `payment_method` | `stg.Payments` | Card, BACS, Direct Debit, Cheque. |
| `gl_entry_id` | `stg.GeneralLedgers` | Ledger journal line identifier. |
| `credit_gbp` | `stg.GeneralLedgers` | Raw credit posting value. |
| `debit_gbp` | `stg.GeneralLedgers` | Raw debit posting value. |
| `entry_date` | `stg.GeneralLedgers` | Effective posting date in the ledger. |
| `is_rounding_break` | Diagnostic Flag | `1` if $\vert{}Variance\vert{} \le £0.05$ (penny rounding / FX difference). |
| `is_multi_split_break` | Diagnostic Flag | `1` if multiple payments or GL lines exist for the policy. |
| `is_timing_lag` | Diagnostic Flag | `1` if timing gap between payment and GL entry exceeds 30 days. |

---

## 5. Operations & Triage Runbook

When reconciling month-end figures or executing scheduled quality checks, follow this operational workflow:

```
[Execute SP] ──► [Check Pillar 1 Match Rate]
                         │
                         ├─► Match Rate >= 99.5% ──► PASS / Operational Sign-Off
                         │
                         └─► Match Rate < 99.5%
                                 │
                                 ▼
                     [Inspect Pillar 2 % Exposure]
                                 │
                                 ├─► Highest % in Orphan GL ────► Route to Finance/Ledger Team
                                 ├─► Highest % in Orphan Pay ───► Route to Payments/ETL Team
                                 └─► Highest % in Mismatch ─────► Route to Operations/Billing
                                 │
                                 ▼
                     [Triage Pillar 3 by Diagnostics]
                                 │
                                 ├─► is_rounding_break = 1 ─────► Batch Write-off / Auto-clear
                                 ├─► is_timing_lag = 1 ─────────► Mark 'In Transit'
                                 └─► Unflagged Breaks ──────────► Manual Investigation (Top Exposure First)

```

---

## 6. Execution Examples

```sql
-- Standard Run (Default £0.01 tolerance)
EXEC stg.usp_Recon_Payments_vs_GeneralLedger;

-- Material Discrepancy Investigation (Tolerance £10.00)
EXEC stg.usp_Recon_Payments_vs_GeneralLedger 
    @DiscrepancyThreshold = 10.00;
