USE FSA_Staging
GO

CREATE OR ALTER PROCEDURE stg.usp_Recon_Payments_vs_GeneralLedger
    @DiscrepancyThreshold DECIMAL(18,2) = 0.01
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#ReconResults') IS NOT NULL
            DROP TABLE #ReconResults;


        WITH PaymentSummary AS (    
        SELECT policy_reference,
               COUNT(payment_reference) AS payment_count,
               SUM(payment_amount_gbp) AS payment_amount,
               MAX(payment_date) AS max_payment_date
        FROM   stg.payments AS p
        GROUP BY policy_reference
        ),
        GeneralLedgerSummary AS (
        select policy_reference,
               COUNT(gl_entry_id) AS gl_count,
               SUM(debit_gbp) AS total_debit,
               SUM(credit_gbp) AS total_credit,
               SUM(ISNULL(debit_gbp, 0) - ISNULL(credit_gbp, 0)) AS total_gl_amount,
               MAX(entry_date) AS max_gl_date
        from stg.GeneralLedgers
        group by policy_reference
        )

        SELECT COALESCE(ps.policy_reference, gls.policy_reference) AS policy_reference,
               ISNULL(ps.payment_count, 0) AS payment_count,
               ISNULL(ps.payment_amount, 0) AS payment_amount,
               ISNULL(gls.gl_count, 0) AS gl_count,
               ISNULL(gls.total_gl_amount, 0) AS gl_amount,
               (ISNULL(ps.payment_amount, 0) - ISNULL(gls.total_gl_amount, 0)) AS net_variance,
               ABS(ISNULL(ps.payment_amount, 0) - ISNULL(gls.total_gl_amount, 0)) AS gross_variance,
               CASE 
                    WHEN ps.policy_reference IS NULL THEN 'Orphan GL'
                    WHEN gls.policy_reference IS NULL THEN 'Orphan Payment'
                   WHEN ABS(ISNULL(ps.payment_amount, 0) - ISNULL(gls.total_gl_amount, 0)) > 500 THEN 'Amount Mismatch' --@DiscrepancyThreshold 
                   ELSE 'Matched'
               END AS recon_status,
            CASE 
                WHEN DATEDIFF(day, max_payment_date, max_gl_date) > 30 THEN 1 ELSE 0 
            END AS is_timing_lag
        INTO #ReconResults       
        FROM PaymentSummary AS ps
        FULL OUTER JOIN GeneralLedgerSummary AS gls
        ON ps.policy_reference = gls.policy_reference;

        -- Pillar 1: Identify discrepancies based on the discrepancy threshold
        SELECT 
               COUNT(*) AS Total_policies_evaluated,
               SUM(payment_count) AS Total_payment_records,
               SUM(payment_amount) AS Total_payment_amount,
               SUM(gl_count) AS Total_gl_records,
               SUM(gl_amount) AS Total_gl_amount,
               CAST(SUM(CASE WHEN recon_status = 'Matched' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(18,2)) AS Match_rate_Percentage,
               SUM(net_variance) AS Total_net_variance,
               SUM(gross_variance) AS total_gross_exposure
        FROM #ReconResults

        --Pillar 2: Identify policies with discrepancies exceeding the threshold
        SELECT 
            recon_status,
               COUNT(*) AS Total_policies_evaluated,
               SUM(payment_count) AS Total_payment_records,
               SUM(payment_amount) AS Total_payment_amount,
               SUM(gl_count) AS Total_gl_records,
               SUM(gl_amount) AS Total_gl_amount,
               SUM(net_variance) AS Total_net_variance,
               SUM(gross_variance) AS total_gross_exposure,
               CAST(
                    SUM(gross_variance) * 100.0 / NULLIF(SUM(SUM(gross_variance)) OVER(), 0) 
                    AS DECIMAL(5,2)
                ) AS pct_of_total_exposure
        FROM #ReconResults
        GROUP BY recon_status
        ORDER BY pct_of_total_exposure DESC;

    --- Pillar 3: Exception list
        SELECT 
            r.policy_reference,
            r.recon_status,
            r.gross_variance,
            p.payment_reference,
            p.payment_amount_gbp,
            p.payment_date,
            p.payment_method,
            g.gl_entry_id,
            g.credit_gbp,
            g.debit_gbp,
            g.entry_date,
            CASE 
                WHEN ABS(net_variance) > 0.00 AND ABS(net_variance) <= 0.05 THEN 1 ELSE 0 
            END AS is_rounding_break,
            CASE 
                WHEN payment_count > 1 OR gl_count > 1 
                    THEN 1 ELSE 0 
            END AS is_multi_split_break,
            is_timing_lag
        FROM #ReconResults r
        LEFT JOIN stg.Payments p ON r.policy_reference = p.policy_reference
        LEFT JOIN stg.GeneralLedgers g ON r.policy_reference = g.policy_reference
        WHERE recon_status <> 'Matched'
        ORDER BY gross_variance DESC;


    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO