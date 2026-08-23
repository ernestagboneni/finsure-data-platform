USE FSA_Warehouse
GO

IF OBJECT_ID( 'warehouse.AgentDimension', 'U') IS NOT NULL
drop table warehouse.AgentDimension

CREATE TABLE warehouse.AgentDimension
(
    agent_dim_key  INT           IDENTITY (1, 1) PRIMARY KEY,
    agent_id      NVARCHAR (50) NOT NULL
);


