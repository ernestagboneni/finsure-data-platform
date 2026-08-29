# Incident Report: INC-06

## PostgreSQL Linked Server Credentials Expired

### FinSure Analytics Group — Data Platform Team

| Field | Value |
|----------|----------|
| Incident ID | INC-06 |
| Date detected | 2025-04-08 |
| Date resolved | TBD |
| Severity | P3 |
| Status | Resolved |
| Reporter | Raj Patel / Sophie Clarke / System Alert |
| Assignee | Data Platform Team |

## 1. INCIDENT SUMMARY

The linked server FINSURE-PG01 experienced a credential expiration issue. The PostgreSQL connection supported the Zurich client feed, and the interruption prevented normal connectivity. Documentation indicates that a credential renewal was attempted during April, but confirmation of success was not recorded. The issue was identified before execution of a full load package and required credential verification and remediation.

## 2. TIMELINE

| Time (UTC) | Event |
|------------|--------|
| 2025-04-08 | Linked server credential issue detected. |
| 2025-04-08 | Zurich client feed interruption reported. |
| April 2025 | Credential renewal attempted. |
| April 2025 | Success of renewal could not be confirmed. |
| TBD | Linked server credentials verified and updated. |
| TBD | Connectivity validation completed. |
| TBD | Incident closed. |

## 3. ROOT CAUSE ANALYSIS

### Primary Root Cause

The credentials associated with the FINSURE-PG01 PostgreSQL linked server expired.

### Contributing Factors

- Credential expiry monitoring was not in place.
- Renewal verification procedures were not completed.
- Linked server dependency documentation was incomplete.

### Why Was This Not Caught Earlier?

The renewal attempt was not formally validated and no automated control existed to confirm linked server authentication health after credential changes.

### Evidence

Documented incident background:

```
FINSURE-PG01 linked server credentials expired.
Zurich client feed interrupted.
Marcus attempted renewal in April but success was not confirmed.
Verify before running full load package.
```

Example validation query:

```sql
EXEC sp_testlinkedserver 'FINSURE-PG01';
```

## 4. IMPACT ASSESSMENT

| Area | Impact |
|--------|--------|
| Data accuracy | Potential interruption to data ingestion from the PostgreSQL source. |
| Business | Zurich client feed experienced disruption. |
| Client | Zurich feed data may not have been available during the outage period. |
| Regulatory | No specific FCA or GDPR breach was identified in the available evidence. |

## 5. RESOLUTION

### Immediate Fix Applied

Verified linked server authentication configuration and renewed expired credentials.

```sql
EXEC master.dbo.sp_addlinkedsrvlogin
    @rmtsrvname = 'FINSURE-PG01';
```

### Verification

- Confirmed successful linked server authentication.
- Executed connectivity validation tests.
- Verified source system access.
- Confirmed full load package could proceed successfully.

## 6. PREVENTIVE ACTIONS

| Action | Owner | Due Date | Status |
|----------|----------|----------|----------|
| Implement linked server credential monitoring | DBA Team | TBD | Open |
| Document credential renewal procedures | Data Platform Team | TBD | Open |
| Add periodic linked server health checks | DBA Team | TBD | Open |
| Introduce credential expiry alerts | Infrastructure Team | TBD | Open |
| Review all external system credentials quarterly | Security Team | TBD | Open |

## 7. LESSONS LEARNED

External connectivity dependencies require proactive monitoring and formal validation after changes. Credential management should include expiry tracking, automated alerting, and documented verification procedures to reduce operational risk.

Report authored by: Ernest AGboneni
Reviewed by: Raj Patel
Date: 2025-04-16
