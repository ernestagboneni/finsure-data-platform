# Incident Report: INC-05

## SQL Agent History Truncated at Default 100 Rows

### FinSure Analytics Group — Data Platform Team

| Field | Value |
|----------|----------|
| Incident ID | INC-05 |
| Date Detected | 2025-04-15 |
| Severity | P3 |
| Status | Resolved |
| Reporter | Raj Patel / Sophie Clarke / System Alert |
| Assignee | Data Platform Team |

## 1. INCIDENT SUMMARY

During investigation of ETL and reconciliation failures, the team discovered that SQL Server Agent history retention remained configured at the default setting. Historical execution records had been overwritten, leaving only a limited evidence window covering recent activity. As a result, investigators could not determine exactly when the reconciliation job first failed or reconstruct the full sequence of events relating to March production failures.

## 2. TIMELINE

| Time (UTC) | Event |
|------------|--------|
| 2025-04-15 | Investigation of reconciliation failures initiated. |
| 2025-04-15 | SQL Agent job history reviewed. |
| 2025-04-15 | Historical evidence found to be incomplete. |
| 2025-04-15 | Root cause identified as default SQL Agent history retention configuration. |
| 2025-04-15 | Retention settings reviewed and remediation planned. |
| 2025-04-16 | Updated retention configuration implemented. |
| 2025-04-16 | Verification completed and incident closed. |

## 3. ROOT CAUSE ANALYSIS

### Primary Root Cause

SQL Server Agent history retention was left at the default configuration, causing older execution records to be overwritten and removed from the investigation evidence trail.

### Contributing Factors

- No review of SQL Server Agent history limits after deployment.
- No operational requirement defining minimum retention periods.
- Reliance on SQL Agent history as a primary troubleshooting source.
- Lack of centralized long-term job execution logging.

### Why Was This Not Caught Earlier?

The retention configuration generated no warnings and did not impact daily processing. The problem only became visible when historical evidence was required for root-cause analysis.

### Evidence

The incident background states:

```text
SQL Server default history retention setting means investigation of March failures is impossible.
The evidence window only covers April.
Cannot see when the reconciliation job first failed.
```

Example validation query:

```sql
SELECT COUNT(*)
FROM msdb.dbo.sysjobhistory;
```

Investigation showed available SQL Agent history records covering April activity while earlier execution history required for March analysis was unavailable.

## 4. IMPACT ASSESSMENT

| Area | Impact |
|--------|--------|
| Data Accuracy | No direct data corruption identified. |
| Business | Root-cause analysis activities were delayed due to missing historical evidence. |
| Client | Resolution timelines for related incidents were extended because historical job execution details were unavailable. |
| Regulatory | No direct FCA or GDPR breach identified. Audit and investigation capability was reduced. |

## 5. RESOLUTION

### Immediate Fix Applied

SQL Agent history retention limits were increased to preserve sufficient troubleshooting history.

```sql
EXEC msdb.dbo.sp_set_sqlagent_properties
    @jobhistory_max_rows = 10000,
    @jobhistory_max_rows_per_job = 1000;
```

### Verification

- SQL Agent properties reviewed successfully.
- Retention thresholds confirmed.
- New job executions persisted to history correctly.
- Historical logging requirements documented.

Verification query:

```sql
EXEC msdb.dbo.sp_get_sqlagent_properties;
```

## 6. PREVENTIVE ACTIONS

| Action | Owner | Due Date | Status |
|----------|----------|----------|----------|
| Increase SQL Agent history retention limits | DBA Team | Completed | Closed |
| Implement centralized operational logging | Data Platform Team | TBD | Open |
| Define minimum log-retention standards | Platform Governance Team | TBD | Open |
| Add monitoring for history retention thresholds | DBA Team | TBD | Open |
| Include retention review in environment readiness checks | Data Platform Team | TBD | Open |

## 7. LESSONS LEARNED

Operational logging is a critical platform dependency. Default SQL Server configurations may be sufficient for development environments but are often inadequate for production support and forensic investigations. Establishing retention standards and centralized logging reduces investigation time and improves incident response effectiveness.

Report authored by: Ernest Agboneni 
Reviewed by: Raj Patel  
Date: 2025-04-16
