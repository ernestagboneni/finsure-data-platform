
## SQL Agent Reconciliation Job Disabled

#### FinSure Analytics Group — Data Platform Team

| Field | Value |
|---------|---------|
| Incident ID | INC-01 |
| Date detected | 2025-03-03 08:15 UTC |
| Date resolved | 2025-03-04 10:30 UTC |
| Duration | 26:15 |
| Severity | P1 |
| Status | Resolved |
| Reporter | Raj Patel / Sophie Clarke / System Alert |
| Assignee | Data Platform Team |

## 1. INCIDENT SUMMARY

The SQL Agent job FSA_Reconciliation_Check became disabled following repeated execution failures. As a result, the premium reconciliation process stopped running and data quality checks were no longer performed on inbound policy data. The failure contributed to the Meridian Data Quality Notice and affected 3,847 policies that were not reconciled correctly.

## 2. TIMELINE

| Time (UTC) | Event |
|------------|--------|
| 2025-03-03 08:15 | Reconciliation agent was disabled. |
| 2025-03-03 08:30 | Investigation initiated by Data Platform Team. |
| 2025-03-03 09:05 | Review of SQL Agent jobs identified FSA_Reconciliation_Check as disabled. |
| 2025-03-03 09:30 | Historical job failures reviewed through SQL Agent job history. |
| 2025-03-03 10:15 | Root cause confirmed as disabled SQL Agent reconciliation job. |
| 2025-03-04 09:45 | Job re-enabled and reconciliation process executed successfully. |
| 2025-03-04 10:30 | Validation completed and incident marked resolved. |

## 3. ROOT CAUSE ANALYSIS
FSA_Reconciliation_Check SQL Agent job was disabled after repeated failures.
### Primary Root Cause

The FSA_Reconciliation_Check SQL Agent job was disabled after previous execution failures and was not subsequently re-enabled, preventing premium reconciliation processes from running.

### Contributing Factors

- No monitoring existed to alert administrators when critical SQL Agent jobs became disabled.
- SQL Agent history retention was limited, reducing visibility into historical failures.
- Reconciliation processing relied on a single scheduled job without secondary validation controls.
- Operational procedures did not require verification that critical jobs remained enabled following remediation.

### Why Was This Not Caught Earlier?

The environment lacked proactive monitoring for job state changes. Existing alerting focused on job failures but not on disabled jobs. Because the reconciliation process stopped silently after the job was disabled, the issue remained undetected until downstream data quality discrepancies became visible.

## 4. IMPACT ASSESSMENT

| Area | Impact |
|--------|--------|
| Data accuracy | Premium reconciliation processing failed, impacting 3,847 policy records. |
| Business | Data quality controls were not executed, resulting in operational investigation and remediation effort. |
| Client | Meridian received a Data Quality Notice due to unreconciled premium data. |
| Regulatory | Potential reporting and audit risk due to failure of a key data quality control process. |

## 5. RESOLUTION

### Immediate Fix Applied

```sql
EXEC msdb.dbo.sp_update_job
    @job_name = 'FSA_Reconciliation_Check',
    @enabled = 1;
GO

EXEC msdb.dbo.sp_start_job
    @job_name = 'FSA_Reconciliation_Check';

SELECT name, enabled
FROM msdb.dbo.sysjobs
WHERE name = 'FSA_Reconciliation_Check';


## 6. PREVENTIVE ACTIONS
 
| Action                                                   | Owner              | Due Date   | Status |
| -------------------------------------------------------- | ------------------ | ---------- | ------ |
| Implement monitoring for disabled SQL Agent jobs         | DBA Team           | 2025-03-14 | Open   |
| Create alert for reconciliation job failures             | Data Operations    | 2025-03-14 | Open   |
| Increase SQL Agent history retention settings            | DBA Team           | 2025-03-10 | Open   |
| Implement daily reconciliation control dashboard         | Data Quality Team  | 2025-03-21 | Open   |
| Review all critical production jobs for dependency risks | Data Platform Team | 2025-03-21 | Open   |

7. LESSONS LEARNED

Critical reconciliation processes should never depend on a single scheduled job without health monitoring. This incident demonstrated that disabled jobs can create silent failures that bypass traditional error monitoring.

Report authored by: Ernest Agboneni
Reviewed by: Raj Patel
Date: 2025-03-04 '''
