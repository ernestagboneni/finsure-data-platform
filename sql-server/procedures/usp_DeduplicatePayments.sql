-- Procedure: [stg].usp_DeduplicatePayments
-- Purpose: This to remove duplicate payment records from the payment table using the payment reference.
--          Windows function was used to detect the duplicate row in in a CTE
-- Author: Ernest Agboneni | Created: 29/06/2026
CREATE OR ALTER PROCEDURE [stg].usp_DeduplicatePayments 

AS
  

BEGIN
    BEGIN TRY
        DECLARE @DupRowCount INT;

        PRINT 'Starting duplicate payment records removal process...';

        WITH     dupCheck
        AS       (SELECT payment_reference,
                         policy_reference,
                         payment_date,
                         payment_timestamp,
                         payment_method,
                         payment_amount_gbp,
                         payment_status,
                         bank_sort_code,
                         bank_account_number,
                         reconciled_flag,
                         ROW_NUMBER() OVER (PARTITION BY payment_reference ORDER BY payment_timestamp ASC) AS rn
                  FROM   stg.Payments)

        --DELETE stg.Payments
        --FROM stg.Payments p
        --WHERE EXISTS (SELECT 1
        --              FROM dupCheck d
        --              WHERE d.payment_reference = p.payment_reference
        --              AND d.payment_timestamp = p.payment_timestamp
        --              AND d.rn > 1 );

        SELECT @DupRowCount = COUNT(*)      
        FROM dupCheck 
        WHERE rn > 1 ;
        PRINT CONCAT('Duplicate payment records identified successfully. Total records found: ', @DupRowCount);
        
    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_DeduplicatePayments: ' + ERROR_MESSAGE();
    END CATCH
END
RETURN 0 