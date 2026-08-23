
USE FSA_Audit;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
    EXEC sp_executesql N'CREATE SCHEMA audit;';
GO

IF OBJECT_ID('audit.ETL_RunLog','U') IS NOT NULL
    DROP TABLE audit.ETL_RunLog;
GO

CREATE TABLE audit.ETL_RunLog
(
    run_id           INT IDENTITY(1,1) PRIMARY KEY,
    package_name     NVARCHAR(100)    NOT NULL,
    run_date         DATE             NOT NULL,
    run_week         CHAR(3)          NOT NULL,
    status           NVARCHAR(20)     NOT NULL,       -- RUNNING / SUCCESS / FAILED / PARTIAL
    rows_processed   INT              NULL,
    rows_rejected    INT              NULL,
    dimAgentCount    INT              NULL,
    dimRegionCount   INT              NULL,
    dimPolicyCount   INT              NULL,
    stagingClaimsCount     INT        NULL,
    stagingPoliciesCount   INT        NULL,
    stagingGeneralLedgerCount   INT   NULL,
    stagingPaymentsCount        INT   NULL,
    premiumsFactCount           INT   NULL,
    claimsFactCount             INT   NULL,
    duration_seconds INT              NULL,
    error_message    NVARCHAR(500)    NULL,
    triggered_by     NVARCHAR(50)     NULL,
    start_timestamp DATETIME      NULL,
    end_timestamp DATETIME      NULL
);
GO

IF OBJECT_ID('audit.ErrorLog','U') IS NOT NULL
    DROP TABLE audit.ErrorLog;
GO

CREATE TABLE audit.ErrorLog
(
    ErrorLogID INT IDENTITY(1,1) PRIMARY KEY,
    Package_name NVARCHAR(50) NOT NULL,
    Task_name NVARCHAR(50) NOT NULL,
    Error_code INT NOT NULL,
    Error_description NVARCHAR(500) NULL,
    Log_date_time DATETIME DEFAULT GETDATE()   
);

select * from audit.ETL_RunLog;