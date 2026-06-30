-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA [stg]');
END
GO

/*

DROP TABLE stg.Claims
DROP TABLE stg.GeneralLedgers
DROP TABLE stg.Payments
DROP TABLE stg.Policies

*/

BEGIN TRY
    CREATE TABLE [stg].[Claims]
    (
        claim_reference     NVARCHAR(100)  NOT NULL ,--PRIMARY KEY,
        policy_reference    NVARCHAR(100)  NULL,
        claim_date          DATE           NULL,
        claim_type          NVARCHAR(50)   NULL,
        claim_status        NVARCHAR(50)   NULL,
        reserve_amount_gbp  DECIMAL(18,2)  NULL,
        paid_amount_gbp     DECIMAL(18,2)  NULL,
        handler_id          CHAR(6)        NULL,
        days_open           INT            NULL,
        source_system       NVARCHAR(100)  NULL
    );
END TRY
BEGIN CATCH
    PRINT CONCAT('Error Occured ',
         ' - ErrorNumber: ',ERROR_NUMBER()  ,
         ' - Severity: ',ERROR_SEVERITY() ,
         ' - State: ',ERROR_STATE()    ,
         ' - Line: ',ERROR_LINE()     ,
         ' - ErrorMessage: ', ERROR_MESSAGE()  );
END CATCH;
GO

BEGIN TRY
    CREATE TABLE [stg].[GeneralLedgers]
    (
        gl_entry_id         NVARCHAR(100)  NOT NULL ,--PRIMARY KEY,
        entry_date          DATE           NULL,
        gl_account_code     NVARCHAR(50)   NULL,
        account_description NVARCHAR(250)  NULL,
        entry_type          NVARCHAR(50)   NULL,
        debit_gbp           DECIMAL(18,2)  NULL,
        credit_gbp          DECIMAL(18,2)  NULL,
        policy_reference    NVARCHAR(100)  NULL,
        period              CHAR(7)        NULL, 
        posted_by           NVARCHAR(100)  NULL,
        approved            CHAR(1) DEFAULT 'N'
    );
END TRY
BEGIN CATCH
    PRINT CONCAT('Error Occured ',
         ' - ErrorNumber: ',ERROR_NUMBER()  ,
         ' - Severity: ',ERROR_SEVERITY() ,
         ' - State: ',ERROR_STATE()    ,
         ' - Line: ',ERROR_LINE()     ,
         ' - ErrorMessage: ', ERROR_MESSAGE()  );
END CATCH;
GO


BEGIN TRY
    CREATE TABLE [stg].[Payments]
    (
        payment_reference      NVARCHAR(100) NOT NULL, -- PRIMARY KEY,
        policy_reference       NVARCHAR(100) NULL,
        payment_date           DATE NULL,
        payment_timestamp      DATETIME2(3) NULL,
        payment_method         NVARCHAR(50) NULL,
        payment_amount_gbp     DECIMAL(18,2) NULL,
        payment_status         NVARCHAR(50) NULL,
        bank_sort_code         NVARCHAR(20) NULL,
        bank_account_number    NVARCHAR(34) NULL,
        reconciled_flag        CHAR(1) DEFAULT 'N'
    );
END TRY
BEGIN CATCH
    PRINT CONCAT('Error Occured ',
         ' - ErrorNumber: ',ERROR_NUMBER()  ,
         ' - Severity: ',ERROR_SEVERITY() ,
         ' - State: ',ERROR_STATE()    ,
         ' - Line: ',ERROR_LINE()     ,
         ' - ErrorMessage: ', ERROR_MESSAGE()  );
END CATCH;
GO


BEGIN TRY
    CREATE TABLE [stg].Policies
    (
        policy_id                NVARCHAR(100)   NOT NULL,-- PRIMARY KEY,
        underwriter_code         CHAR(3)    NULL,
        policy_type              NVARCHAR(50)    NULL,
        risk_band                NVARCHAR(50)    NULL,
        region                   NVARCHAR(100)   NULL,
        agent_id                 NVARCHAR(100)   NULL,
        policy_start_date        VARCHAR(20)     NULL,
        policy_end_date          VARCHAR(20)     NULL,
        payment_frequency        NVARCHAR(50)    NULL,
        premium_amount           VARCHAR(50)   NULL,
        warehouse_premium_gbp    VARCHAR(30)   NULL,
        premium_variance_gbp     VARCHAR(30)   NULL,
        etl_status               NVARCHAR(50)    NULL,
        etl_processed_week       CHAR(3)         NULL, -- format 'YYYY-WW' recommended
        source_system            NVARCHAR(100)   NULL,
        data_quality_flag        CHAR(1)         DEFAULT 'N'
    );
END TRY
BEGIN CATCH
    PRINT CONCAT('Error Occured ',
         ' - ErrorNumber: ',ERROR_NUMBER()  ,
         ' - Severity: ',ERROR_SEVERITY() ,
         ' - State: ',ERROR_STATE()    ,
         ' - Line: ',ERROR_LINE()     ,
         ' - ErrorMessage: ', ERROR_MESSAGE()  );
END CATCH;
GO