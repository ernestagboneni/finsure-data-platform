/*
================================================================================
Script:      usp_Load_ClaimsFact.sql
Author:      Ernest Agboneni — Phase 6
Date:        [Date]
Description: Loads claim facts into the warehouse.
Change Log:
  [Date] [Author] Initial version
================================================================================
*/
CREATE OR ALTER PROCEDURE warehouse.usp_Load_ClaimsFact 
    @rowCount INT OUTPUT ,
    @lastSuccessTimestamp   DATETIME = NULL,
    @isIncrement            BIT = 0
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

    BEGIN TRY
    BEGIN TRANSACTION;   
    IF @isIncrement = 1
    BEGIN 

        INSERT INTO warehouse.ClaimsFact (
            policy_dim_key,
            date_dim_key,
            agent_dim_key,
            region_dim_key,
            claim_reference,
            claim_type,
            claim_status,
            reserve_amount_gbp,
            paid_amount_gbp,
            handler_id,
            days_open
        )
        SELECT 
            p.policy_dim_key,
            d.date_dim_key,
            a.agent_dim_key,
            r.region_dim_key,
            c.claim_reference,
            c.claim_type,
            UPPER(c.claim_status) AS claim_status,
            c.reserve_amount_gbp,
            c.paid_amount_gbp,
            c.handler_id,
            (CASE WHEN c.claim_status = 'OPEN' THEN DATEDIFF(DAY, c.claim_date, GETDATE())
                ELSE c.days_open
            END) AS days_open
        FROM 
            FSA_Staging.stg.Claims c
            LEFT JOIN warehouse.PolicyDimension p ON c.policy_reference = p.policy_id
            LEFT JOIN FSA_Staging.stg.policies pol ON c.policy_reference = pol.policy_id
            LEFT JOIN warehouse.DateDimension d ON c.claim_date = d.date
            LEFT JOIN warehouse.AgentDimension a ON pol.agent_id = a.agent_id
            LEFT JOIN warehouse.RegionDimension r ON pol.region = r.region
        WHERE c.claim_date > @lastSuccessTimestamp;
        SET @rowCount = @@ROWCOUNT;

    END
    ELSE
    BEGIN
        INSERT INTO warehouse.ClaimsFact (
            policy_dim_key,
            date_dim_key,
            agent_dim_key,
            region_dim_key,
            claim_reference,
            claim_type,
            claim_status,
            reserve_amount_gbp,
            paid_amount_gbp,
            handler_id,
            days_open
        )
        SELECT 
            p.policy_dim_key,
            d.date_dim_key,
            a.agent_dim_key,
            r.region_dim_key,
            c.claim_reference,
            c.claim_type,
            UPPER(c.claim_status) AS claim_status,
            c.reserve_amount_gbp,
            c.paid_amount_gbp,
            c.handler_id,
            (CASE WHEN c.claim_status = 'OPEN' THEN DATEDIFF(DAY, c.claim_date, GETDATE())
                ELSE c.days_open
            END) AS days_open
        FROM 
            FSA_Staging.stg.Claims c
            LEFT JOIN warehouse.PolicyDimension p ON c.policy_reference = p.policy_id
            LEFT JOIN FSA_Staging.stg.policies pol ON c.policy_reference = pol.policy_id
            LEFT JOIN warehouse.DateDimension d ON c.claim_date = d.date
            LEFT JOIN warehouse.AgentDimension a ON pol.agent_id = a.agent_id
            LEFT JOIN warehouse.RegionDimension r ON pol.region = r.region;

        SET @rowCount = @@ROWCOUNT;
    END    

    COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH

RETURN 0 
END