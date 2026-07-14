USE FSA_Warehouse
GO

IF OBJECT_ID( 'AgentDimension', 'U') IS NOT NULL
drop table AgentDimension

CREATE TABLE AgentDimension
(
    agent_dim_key  INT           IDENTITY (1, 1) PRIMARY KEY,
    agent_id      NVARCHAR (50) NOT NULL,
    region_dim_id INT           --FOREIGN KEY REFERENCES RegionDimension (region_dim_id)
);
--ADD CONSTRAINT FK_AgentDimension_RegionDimension FOREIGN KEY (region_dim_id) REFERENCES RegionDimension (region_dim_key);


