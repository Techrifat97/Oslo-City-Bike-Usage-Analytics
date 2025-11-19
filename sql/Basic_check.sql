CREATE DATABASE OsloBike;
GO
USE OsloBike;
GO

SELECT TOP 5 * FROM dbo.dim_station;
SELECT TOP 5 * FROM dbo.fact_trip;

SELECT COUNT(*) FROM dbo.dim_station;
SELECT COUNT(*) FROM dbo.fact_trip;