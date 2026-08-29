# Incident Report: INC-03

## Semantic View Column Reference Broken

### FinSure Analytics Group — Data Platform Team

| Field | Value |
|----------|----------|
| Incident ID | INC-03 |
| Date Detected | 2025-03-21 |
| Severity | HIGH |
| Status | Resolved |
| Reporter | Raj Patel / Sophie Clarke / System Alert |
| Assignee | Data Platform Team |

## 1. INCIDENT SUMMARY

During a schema change, the column `premium_amount_normalised` was renamed to `premium_amount_gbp` in the `PremiumFact` table. Three dependent semantic views within the `FSA_Semantic` layer continued to reference the old column name. As a result, three Power BI reports were unable to refresh with current data and consumers received stale reporting outputs.

## 2. TIMELINE

| Time (UTC) | Event |
|------------|--------|
| 2025-03-21 | Issue detected following Power BI refresh failures. |
| 2025-03-21 | Investigation initiated by the Data Platform Team. |
| 2025-03-21 | Failed semantic views identified within the `FSA_Semantic` layer. |
| 2025-03-21 | Root cause identified as a renamed column in `PremiumFact`. |
| 2025-03-21 | Affected semantic views updated. |
| 2025-03-21 | Power BI dataset refreshes validated successfully. |
| 2025-03-21 | Incident closed. |

## 3. ROOT CAUSE ANALYSIS

### Primary Root Cause

A schema change renamed `premium_amount_normalised` to `premium_amount_gbp` in `PremiumFact`, but dependent semantic views were not updated to reflect the new column name.

### Contributing Factors

- No dependency analysis was performed prior to deployment.
- Semantic views were tightly coupled to physical database column names.
- No automated regression testing existed for semantic-layer objects.
- Report refresh monitoring identified the issue only after deployment.

### Why Was This Not Caught Earlier?

The deployment process validated the table change itself but did not validate downstream semantic views, Power BI datasets, or reporting dependencies.

### Evidence

The incident background explicitly states:

```
Marcus renamed premium_amount_normalised to premium_amount_gbp in PremiumFact during a March schema change.
Three dependent semantic views in FSA_Semantic broke.
Three Power BI reports stopped refreshing with current data.
```

Example dependency check:

```sql
SELECT OBJECT_NAME(object_id) AS view_name
FROM sys.sql_modules
WHERE definition LIKE '%premium_amount_normalised%';
```

Example error condition:

Invalid column name 'premium_amount_normalised'


## 4. IMPACT ASSESSMENT

| Area | Impact |
|--------|--------|
| Data Accuracy | Reports displayed stale data because refresh operations could not complete successfully. |
| Business | Three reporting assets became unavailable for current operational reporting. |
| Client | Users consuming Power BI outputs experienced delayed or outdated information. |
| Regulatory | No direct FCA or GDPR breach identified, but reporting reliability was reduced. |

## 5. RESOLUTION

### Immediate Fix Applied

Updated all affected semantic views to reference the renamed column.

```sql
ALTER VIEW SEM.vw_MeridianPremiumSummary
AS
SELECT premium_amount_gbp
FROM warehouse.PremiumFact;
```

The same update was performed on the remaining affected semantic views.

### Verification

- Semantic views compiled successfully.
- Validation queries executed without error.
- Power BI datasets refreshed successfully.
- Report consumers confirmed access to current data.

Verification query:

```sql
SELECT TOP 10 premium_amount_gbp
FROM warehouse.PremiumFact;
```

## 6. PREVENTIVE ACTIONS

| Action | Owner | Due Date | Status |
|----------|----------|----------|----------|
| Perform dependency analysis prior to schema changes | Data Platform Team | TBD | Open |
| Implement automated semantic-layer regression testing | BI Team | TBD | Open |
| Add Power BI refresh monitoring and alerting | Data Operations | TBD | Open |
| Introduce schema change checklist and peer review | Data Platform Team | TBD | Open |
| Document all semantic view dependencies | Data Architecture Team | TBD | Open |

## 7. LESSONS LEARNED

Successful database changes can still break downstream reporting systems when dependencies are not assessed. Future releases must include impact analysis, automated validation of semantic assets, and Power BI refresh verification before production sign-off.

Report authored by: Ernest Agboneni 
Reviewed by: Raj Patel
Date: 2025-03-21
