USE FSA_Staging;
GO
CREATE OR ALTER PROCEDURE stg.usp_premium_claims_reconciliation   

AS
BEGIN

WITH recon AS (
    SELECT p.policy_id, c.claim_reference,p.underwriter_code, c.claim_status ,
            p.premium_amount_numeric ,c.reserve_amount_gbp, 
            ABS(p.premium_amount_numeric - c.reserve_amount_gbp) AS Variance,
            ROW_NUMBER() OVER(PARTITION BY c.claim_reference ORDER BY p.policy_id) AS rn
    FROM stg.Policies p
    LEFT JOIN stg.Claims c ON p.policy_id = c.policy_reference
    WHERE underwriter_code = 'MER'
    and c.policy_reference IS NOT NULL
)
SELECT * 
FROM recon 
WHERE rn = 2
AND Variance >= 500
AND underwriter_code = 'MER'
--AND claim_status = 'CLOSED';
--RETURN 0 
END