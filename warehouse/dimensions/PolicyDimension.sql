USE FSA_Warehouse
GO

IF OBJECT_ID( 'warehouse.PolicyDimension', 'U') IS NOT NULL
    drop table warehouse.PolicyDimension

CREATE TABLE warehouse.PolicyDimension
(
    policy_dim_key     INT           IDENTITY (1, 1) PRIMARY KEY,
    policy_id          NVARCHAR (50) NOT NULL,
    underwriter_code  CHAR (3)     ,
    policy_type       NVARCHAR (50),
    risk_band         NVARCHAR (50),
    region            NVARCHAR (50),
    payment_frequency NVARCHAR (50),
    effective_from    DATE         ,
    effective_to      DATE         ,
    is_current        BIT NOT NULL DEFAULT 1,
    load_timestamp      DATETIME DEFAULT GETDATE()       
);
