USE FSA_Warehouse
GO

IF OBJECT_ID( 'warehouse.ClaimsFact', 'U') IS NOT NULL
    drop table warehouse.ClaimsFact

CREATE TABLE warehouse.ClaimsFact
(
    claims_fact_id     INT             IDENTITY (1, 1) PRIMARY KEY,
    policy_dim_key      INT             FOREIGN KEY REFERENCES warehouse.PolicyDimension (policy_dim_key),
    date_dim_key        INT             FOREIGN KEY REFERENCES warehouse.DateDimension (date_dim_key),
    agent_dim_key       INT             FOREIGN KEY REFERENCES warehouse.AgentDimension (agent_dim_key),
    region_dim_key      INT             FOREIGN KEY REFERENCES warehouse.RegionDimension (region_dim_key),
    claim_reference    NVARCHAR (50)  ,
    claim_type         NVARCHAR (50)  ,
    claim_status       NVARCHAR (50)  ,
    reserve_amount_gbp DECIMAL (18, 2),
    paid_amount_gbp    DECIMAL (18, 2),
    handler_id         CHAR (6)       ,
    days_open          INT            
);
