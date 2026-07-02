-- Procedure: [stg].usp_StandardiseClaimStatus
-- Purpose: This is to convert the claim_status column in the stg.Claims table to a standardised format of capitalised. This ensures consistency in the claim status values across the database.
-- Author: Ernest Agboneni | Created: 29/06/2026
CREATE OR ALTER PROCEDURE stg.usp_StandardiseClaimStatus
AS
DECLARE @rowCount AS INT;
BEGIN TRY
    UPDATE stg.Claims
    SET    claim_status = UPPER(TRIM(claim_status))
    WHERE  claim_status IS NOT NULL
           AND claim_status COLLATE Latin1_General_CS_A <> UPPER(TRIM(claim_status));
    SELECT @rowCount = @@ROWCOUNT;
    PRINT @rowCount; 
    
    ---- 2) Add CHECK constraint if not present (no UPPER needed because values standardized) --IF NOT EXISTS ( --    SELECT 1 --    FROM sys.check_constraints cc --    WHERE cc.name = 'CK_Claims_ClaimStatus_Allowed' --        AND cc.parent_object_id = OBJECT_ID('stg.Claims') --) --BEGIN --    ALTER TABLE stg.Claims --    ADD CONSTRAINT CK_Claims_ClaimStatus_Allowed --    CHECK (claim_status IN ('OPEN','PENDING','CLOSED','REJECTED')); --END
END TRY
BEGIN CATCH
    THROW;
    PRINT 'Error occurred while standardising claim_status: ' + ERROR_MESSAGE();
END CATCH
RETURN 0;
