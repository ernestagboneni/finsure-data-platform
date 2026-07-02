-- Procedure: [stg].usp_NormalisePremiumAmount
-- Purpose: This to remove surrency symbol and commas from amount and shows  
--        total count of affected rows. The procedure also normalises the date format to YYYY-MM-DD.
--          Windows function was used to detect the duplicate row in in a CTE
-- Author: Ernest Agboneni | Created: 29/06/2026
CREATE OR ALTER PROCEDURE stg.usp_NormalisePremiumAmount
AS
BEGIN
    BEGIN TRY

        UPDATE stg.Policies
        SET    premium_amount    = TRIM(REPLACE(REPLACE(premium_amount, '£', ''), ',', '')),
               policy_start_date = CONVERT (VARCHAR (10), COALESCE (TRY_CONVERT (DATE, policy_start_date, 120), TRY_CONVERT (DATE, policy_start_date, 103)), 23)
        WHERE  policy_start_date IS NOT NULL
        AND premium_amount LIKE '%£%'
        OR premium_amount LIKE '%,%'
        ;
                
        PRINT CONCAT('Dirty rows count with currency symbol: ', @@ROWCOUNT)

        UPDATE stg.Policies
        SET    policy_start_date = CONVERT (VARCHAR (10), COALESCE (TRY_CONVERT (DATE, policy_start_date, 120), TRY_CONVERT (DATE, policy_start_date, 103)), 23); 
        
        PRINT CONCAT('Rows count with date issues: ', @@ROWCOUNT)
       
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while normalizing premium amounts: ' + ERROR_MESSAGE();
    END CATCH
END
RETURN 0;