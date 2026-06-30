-- Procedure: [stg].usp_StandardiseClaimStatus
-- Purpose: This is to convert the claim_status column in the stg.Claims table to a standardised format where the first letter is capitalised and the rest are in lowercase. This ensures consistency in the claim status values across the database.
-- Author: Ernest Agboneni | Created: 29/06/2026
CREATE OR ALTER PROCEDURE stg.usp_StandardiseClaimStatus
AS
DECLARE @rowCount AS INT;
BEGIN TRY
    UPDATE stg.Claims
    SET    claim_status = UPPER(LEFT(claim_status, 1)) + LOWER(SUBSTRING(claim_status, 2, LEN(claim_status)))
    FROM   stg.Claims
    WHERE  claim_status COLLATE Latin1_General_CS_AS NOT IN ('Closed', 'Rejected', 'Pending', 'Open');
    SELECT @rowCount = @@ROWCOUNT;
    PRINT @rowCount;
END TRY
BEGIN CATCH
    PRINT 'Error occurred while standardising claim_status: ' + ERROR_MESSAGE();
END CATCH
RETURN 0;