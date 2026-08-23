USE FSA_Warehouse
GO

IF OBJECT_ID( 'warehouse.PremiumFact', 'U') IS NOT NULL
 drop table warehouse.PremiumFact 

CREATE TABLE warehouse.PremiumFact
(
    premium_fact_id       BIGINT             IDENTITY (1, 1) PRIMARY KEY,
    policy_dim_key         INT NOT NULL    FOREIGN KEY REFERENCES warehouse.PolicyDimension (policy_dim_key),
    date_dim_key           INT NOT NULL            FOREIGN KEY REFERENCES warehouse.DateDimension (date_dim_key),
    agent_dim_key          INT NOT NULL             FOREIGN KEY REFERENCES warehouse.AgentDimension (agent_dim_key),
    region_dim_key         INT NOT NULL             FOREIGN KEY REFERENCES warehouse.RegionDimension (region_dim_key),
    policy_id              NVARCHAR (50)  ,
    underwriter_code         NVARCHAR (50)  ,
    payment_frequency          NVARCHAR (50)  ,
    premium_amount_gbp    DECIMAL (18, 2) NOT NULL,
    premium_variance_gbp  DECIMAL (18, 2),    
    data_quality_flag       CHAR(1),
    etl_status              NVARCHAR(20),
    source_system           NVARCHAR(50),
    load_timestamp          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    is_reconciled           BIT NOT NULL DEFAULT 0
);

