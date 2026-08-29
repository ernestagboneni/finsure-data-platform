# Incident Report: INC-04

## Ex-Employee Production Database Access

### FinSure Analytics Group — Data Platform Team

| Field | Value |
|----------|----------|
| Incident ID | INC-04 |
| Date detected | 2025-06-01 |
| Date resolved | TBD |
| Duration | TBD |
| Severity | P2 |
| Status | Resolved |
| Reporter | Raj Patel / Sophie Clarke / System Alert |
| Assignee | Data Platform Team |

## 1. INCIDENT SUMMARY

An RBAC review identified that two former employees retained active `db_datareader` access to the `FSA_Warehouse` production database. One of the former employees was reported to be working for a competitor. The issue represented a security and compliance risk because production warehouse data remained accessible after employment termination. The incident created potential GDPR Article 32 and FCA SYSC 8.1 compliance concerns.

## 2. TIMELINE

| Time (UTC) | Event |
|------------|--------|
| 2025-06-01 | RBAC review identified unexpected active production access for former employees. |
| 2025-06-01 | Investigation initiated by Data Platform Team. |
| 2025-06-01 | Review of database principals and role memberships performed. |
| 2025-06-01 | Root cause identified as incomplete user deprovisioning process. |
| 2025-06-01 | Production access revoked for affected accounts. |
| 2025-06-01 | Access review completed and remediation verified. |

## 3. ROOT CAUSE ANALYSIS

### Primary Root Cause

Former employees were not removed from production database role memberships during the offboarding process, leaving active `db_datareader` permissions in place.

### Contributing Factors

- RBAC reviews had not been completed since 2023.
- User access recertification was not performed regularly.
- No automated process existed to remove database access following employment termination.
- Security ownership and review responsibilities were not formally documented.

### Why Was This Not Caught Earlier?

The environment lacked periodic access certification and production access audits. As a result, dormant accounts remained assigned to database roles without being detected.

### Evidence

Background information states:

```text
RBAC review identifies two former employees with active db_datareader access to FSA_Warehouse.
One now works for a competitor.
GDPR Article 32 breach risk.
FCA SYSC 8.1 concern.
```

Example validation query:

```sql
SELECT dp.name, rp.name AS role_name
FROM sys.database_role_members drm
INNER JOIN sys.database_principals dp
    ON drm.member_principal_id = dp.principal_id
INNER JOIN sys.database_principals rp
    ON drm.role_principal_id = rp.principal_id
WHERE rp.name = 'db_datareader';
```

## 4. IMPACT ASSESSMENT

| Area | Impact |
|--------|--------|
| Data accuracy | No evidence of data modification or corruption was identified. |
| Business | Security and governance control failure requiring immediate remediation. |
| Client | Potential exposure risk to production warehouse information. |
| Regulatory | GDPR Article 32 and FCA SYSC 8.1 compliance risk. |

## 5. RESOLUTION

### Immediate Fix Applied

Removed affected users from production database roles and revoked unnecessary access.

```sql
ALTER ROLE db_datareader DROP MEMBER [user_account];
```

### Verification

- Reviewed current role memberships.
- Confirmed former employee accounts no longer had database access.
- Completed follow-up RBAC validation.
- Documented remediation actions.

## 6. PREVENTIVE ACTIONS

| Action | Owner | Due Date | Status |
|----------|----------|----------|----------|
| Perform quarterly RBAC reviews | Data Governance Team | TBD | Open |
| Implement joiner/mover/leaver access controls | Security Team | TBD | Open |
| Automate removal of terminated-user access | IT Operations | TBD | Open |
| Maintain access certification register | Data Governance Team | TBD | Open |
| Review all production database roles | DBA Team | TBD | Open |

## 7. LESSONS LEARNED

Production access reviews must be treated as a formal operational control. User deprovisioning and periodic access certification should be automated and audited to reduce security and compliance risk.

Report authored by: Ernest Agboneni

Reviewed by: Raj Patel
