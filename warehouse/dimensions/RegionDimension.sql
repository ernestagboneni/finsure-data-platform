USE FSA_Warehouse
GO

IF OBJECT_ID( 'warehouse.RegionDimension', 'U') IS NOT NULL
    drop table warehouse.RegionDimension

CREATE TABLE warehouse.RegionDimension
(
    region_dim_key INT           IDENTITY (1, 1) PRIMARY KEY,
    region        NVARCHAR (50)
);

