USE FSA_Warehouse
GO

IF OBJECT_ID( 'RegionDimension', 'U') IS NOT NULL
    drop table RegionDimension

CREATE TABLE RegionDimension
(
    region_dim_key INT           IDENTITY (1, 1) PRIMARY KEY,
    region        NVARCHAR (50),
    policy_dim_key INT           --FOREIGN KEY REFERENCES PolicyDimension (policy_dim_key)
 --   agent_dim_key  INT           --FOREIGN KEY REFERENCES AgentDimension (agent_dim_key)
);
--ADD CONSTRAINT FK_RegionDimension_PolicyDimension FOREIGN KEY (policy_dim_key) REFERENCES PolicyDimension (policy_dim_key);

