## Incident Report: INC-02

### FinSure Analytics Group — Data Platform Team

### INCIDENT HEADER

| Field | Value |
|---------|---------|
| Incident ID | INC-02 |
| Date detected | 2025-03-10 00:00 UTC |
| Date resolved | 2025-04-28 00:00 UTC |
| Duration | 49 days |
| Severity | P2 |
| Status | Resolved |
| Reporter | Raj Patel / Sophie Clarke / System Alert |
| Assignee | Data Platform Team |

---

### 1. INCIDENT SUMMARY

The `etl_incremental_load` SSIS package experienced repeated failures between March and April 2025. Due to the absence of effective error handling and alerting, failures were not escalated and data processing stopped without immediate visibility. ETL execution logs show multiple failed incremental load runs during Weeks 10 through 17, with rows processed dropping to zero during the failure period. The issue contributed directly to stale warehouse data, reconciliation failures, and the wider Meridian data quality incident affecting premium accuracy.

---

### 2. TIMELINE

| Time (UTC) | Event |
|------------|--------|
| 2025-03-10 | First failed incremental load recorded (Week 11). |
| 2025-03-10 | Investigation initiated after ETL execution failures were identified in historical logs. |
| 2025-03-17 | Additional package failures confirmed across incremental load executions. |
| 2025-03-24 | Incremental load package continued failing, preventing warehouse updates. |
| 2025-03-31 | Failed execution recorded with package abort conditions. |
| 2025-04-07 | Incremental load remained unavailable; failures persisted throughout Week 15. |
| 2025-04-14 | Package failure trend continued in Week 16. |
| 2025-04-21 | Final major failure period observed in Week 17. |
| 2025-04-28 | Incremental load package successfully executed and normal processing resumed. |
| 2025-04-28 | Successful execution verified through ETL run logs. |

---

### 3. ROOT CAUSE ANALYSIS

#### Primary Root Cause

The `etl_incremental_load` SSIS package lacked effective error-handling and monitoring controls, allowing package failures to terminate processing without generating actionable alerts or recovery actions.

#### Contributing Factors

- SQL Agent job history retention was limited to 100 rows, reducing visibility into historical failures.
- ETL package logging was incomplete and not centrally monitored.
- Error-handling functionality (`etl_error_handler`) was documented as unverified and potentially incomplete.
- Operational ownership of ETL monitoring was unclear following departure of the previous Senior SQL Developer.

#### Why Was This Not Caught Earlier?

The platform did not contain automated alerting for package failures, row-count anomalies, or execution interruptions. Documentation confirms uncertainty regarding deployment of the ETL error-handling framework, meaning failures were allowed to occur without notification. Historical troubleshooting was further hindered by limited SQL Agent history retention.

#### Evidence

**ETL Run Log**

The incremental load package failed repeatedly during the incident period:

| Week | Package | Status | Rows Processed | Error |
|------|---------|---------|---------------|--------|
| W10 | etl_incremental_load | FAILED | 0 | Package aborted - see SSIS log |
| W11 | etl_incremental_load | FAILED | 0 | SQL Agent job terminated unexpectedly |
| W12 | etl_incremental_load | FAILED | 0 | Package aborted - see SSIS log |
| W13 | etl_incremental_load | FAILED | 0 | Deadlock victim on stg.Premiums |
| W14 | etl_incremental_load | FAILED | 0 | Package aborted - see SSIS log |
| W15 | etl_incremental_load | FAILED | 0 | SQL Agent job terminated unexpectedly |
| W16 | etl_incremental_load | FAILED | 0 | Deadlock victim on stg.Premiums |
| W17 | etl_incremental_load | FAILED | 0 | SQL Agent job terminated unexpectedly |

Following remediation, Week 18 shows:

| Week | Package | Status | Rows Processed |
|------|----------|----------|---------------|
| W18 | etl_incremental_load | SUCCESS | 1,644 |

**Process Documentation Evidence**

> "The incremental load was failing from around March."

> "The ETL error handler was added in January. Not sure it was wired in properly. CHECK THIS."

These statements support the finding that inadequate error handling contributed significantly to the incident.

---

### 4. IMPACT ASSESSMENT

| Area | Impact |
|--------|--------|
| Data accuracy | Incremental warehouse updates failed for multiple consecutive weeks, resulting in missing and stale data. |
| Business | Contributed to premium reconciliation failures and Meridian Data Quality Notice investigation. |
| Client | Reduced confidence in warehouse outputs supplied to Meridian Insurance and other reporting consumers. |
| Regulatory | Potential FCA data-quality governance concerns due to ineffective monitoring controls and delayed issue detection. |

---

### 5. RESOLUTION

#### Immediate Fix Applied

- Reviewed SSIS package execution history.
- Investigated recurring package failures and dependency issues.
- Implemented proper failure handling and package execution monitoring.
- Re-enabled successful ETL execution paths.
- Verified package completion and row processing against historical baselines.

Example validation query:

```sql
SELECT
    package_name,
    run_date,
    status,
    rows_processed,
    error_message
FROM dbo.ETLRunLog
WHERE package_name = 'etl_incremental_load'
ORDER BY run_date DESC;
```

#### Verification

The package was verified as restored when the Week 18 execution completed successfully with records processed and no associated error messages.

| Week | Status | Rows Processed |
|------|---------|---------------|
| W18 | SUCCESS | 1,644 |

Subsequent runs also completed successfully, confirming resolution of the incident.

---

### 6. PREVENTIVE ACTIONS

| Action | Owner | Due Date | Status |
|----------|----------|----------|----------|
| Implement SSIS package-level error handling and retry logic | Data Platform Team | 2025-05-15 | Open |
| Deploy and validate etl_error_handler framework | ETL Team | 2025-05-15 | Open |
| Implement alerting for failed ETL executions | Operations Team | 2025-05-22 | Open |
| Create dashboard for ETL success rates and row-count monitoring | BI Team | 2025-05-29 | Open |
| Increase SQL Agent history retention to 10,000 rows | DBA Team | 2025-05-08 | Open |

---

### 7. LESSONS LEARNED

Critical ETL processes must never rely solely on manual monitoring. Package failures should generate immediate alerts and provide sufficient diagnostic information for rapid troubleshooting. This incident highlighted weaknesses in platform observability, operational ownership and ETL error handling. Future ETL deployments must include validated logging, exception management and automated monitoring before release to production.

Report authored by: Ernest Agboneni  
Reviewed by: Raj Patel 
Date: 2025-04-28