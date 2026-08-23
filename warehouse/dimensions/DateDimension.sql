USE FSA_Warehouse
GO

IF OBJECT_ID( 'warehouse.DateDimension', 'U') IS NOT NULL
    drop table warehouse.DateDimension


CREATE TABLE warehouse.DateDimension
(
    date_dim_key  INT  IDENTITY (1, 1) PRIMARY KEY,
    date         DATE,
    year         INT ,
    quarter      INT ,
    month        INT ,
    day          INT ,
    week_of_year INT ,
    is_weekend   BIT 
);

