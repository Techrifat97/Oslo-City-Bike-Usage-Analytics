-- Trips By Area
SELECT
    s.Area,
    COUNT(*) AS TripCount
FROM fact_trip AS t
JOIN dim_station AS s
    ON t.StartStationId = s.StationId
GROUP BY
    s.Area
ORDER BY
    TripCount DESC;


-- Area - time of day- weekend or weekday
SELECT
    s.Area,
    t.IsWeekend,
    t.TimeOfDay,
    COUNT(*)           AS TripCount,
    AVG(t.DurationMin) AS AvgDurationMin
FROM fact_trip AS t
JOIN dim_station AS s
    ON t.StartStationId = s.StationId
GROUP BY
    s.Area,
    t.IsWeekend,
    t.TimeOfDay
ORDER BY
    s.Area,
    t.IsWeekend,
    TripCount DESC;

USE OsloBike;
GO

-- Overall trips by TimeOfDay (all areas, all days)
SELECT
    TimeOfDay,
    COUNT(*)           AS TripCount,
    AVG(DurationMin)   AS AvgDurationMin
FROM fact_trip
GROUP BY
    TimeOfDay
ORDER BY
    TripCount DESC;

-- Weekday
SELECT
    TimeOfDay,
    COUNT(*) AS TripCount
FROM fact_trip
WHERE IsWeekend = 0
GROUP BY TimeOfDay
ORDER BY TripCount DESC;


-- Trips by Area and TimeOfDay
SELECT
    s.Area,
    t.TimeOfDay,
    COUNT(*)           AS TripCount,
    AVG(t.DurationMin) AS AvgDurationMin
FROM dbo.fact_trip AS t
JOIN dbo.dim_station AS s
    ON t.StartStationId = s.StationId
GROUP BY
    s.Area,
    t.TimeOfDay
ORDER BY
    s.Area,
    TripCount DESC;

-- Area × TimeOfDay, weekdays only (commuter focus)
SELECT
    s.Area,
    t.TimeOfDay,
    COUNT(*) AS TripCount
FROM dbo.fact_trip AS t
JOIN dbo.dim_station AS s
    ON t.StartStationId = s.StationId
WHERE t.IsWeekend = 0
GROUP BY
    s.Area,
    t.TimeOfDay
ORDER BY
    s.Area,
    TripCount DESC;

    -- Top start stations in weekday mornings
SELECT TOP 20
    s.StationName,
    s.Area,
    COUNT(*) AS TripCount
FROM dbo.fact_trip AS t
JOIN dbo.dim_station AS s
    ON t.StartStationId = s.StationId
WHERE t.IsWeekend = 0
  AND t.TimeOfDay = 'Morning'
GROUP BY
    s.StationName,
    s.Area
ORDER BY
    TripCount DESC;

-- Top end stations in weekday mornings
SELECT TOP 20
    s.StationName,
    s.Area,
    COUNT(*) AS TripCount
FROM dbo.fact_trip AS t
JOIN dbo.dim_station AS s
    ON t.EndStationId = s.StationId
WHERE t.IsWeekend = 0
  AND t.TimeOfDay = 'Morning'
GROUP BY
    s.StationName,
    s.Area
ORDER BY
    TripCount DESC;


--' Hour of day analysis
SELECT
    StartHourOslo AS HourOfDay,
    COUNT(*)  AS TripCount,
    AVG(DurationMin) AS AvgDurationMin
FROM dbo.fact_trip
GROUP BY
    StartHourOslo
ORDER BY
    HourOfDay;

-- commute vs leisure
SELECT
    IsWeekend,
    StartHourOslo  AS HourOfDay,
    COUNT(*) AS TripCount
FROM dbo.fact_trip
GROUP BY
    IsWeekend,
    StartHourOslo
ORDER BY
    IsWeekend,
    HourOfDay;

-- Top morning *start* stations on weekdays (commuter origins)
SELECT TOP 20
    s.StationName,
    s.Area,
    COUNT(*) AS TripCount
FROM dbo.fact_trip AS t
JOIN dbo.dim_station AS s
    ON t.StartStationId = s.StationId
WHERE t.IsWeekend = 0
  AND t.TimeOfDay = 'Morning'
GROUP BY
    s.StationName,
    s.Area
ORDER BY
    TripCount DESC;

-- Top morning *end* stations on weekdays (commuter destinations)
SELECT TOP 20
    s.StationName,
    s.Area,
    COUNT(*) AS TripCount
FROM dbo.fact_trip AS t
JOIN dbo.dim_station AS s
    ON t.EndStationId = s.StationId
WHERE t.IsWeekend = 0
  AND t.TimeOfDay = 'Morning'
GROUP BY
    s.StationName,
    s.Area
ORDER BY
    TripCount DESC;

USE OsloBike;
GO

-- Weekday morning net flow per station (starts - ends)
WITH MorningWeekday AS (
    SELECT
        t.StartStationId,
        t.EndStationId
    FROM dbo.fact_trip AS t
    WHERE t.IsWeekend = 0
      AND t.TimeOfDay = 'Morning'
)

SELECT
    s.StationName,
    s.Area,
    SUM(CASE WHEN m.StartStationId = s.StationId THEN 1 ELSE 0 END) AS Starts,
    SUM(CASE WHEN m.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS Ends,
    SUM(CASE WHEN m.StartStationId = s.StationId THEN 1 ELSE 0 END)
      - SUM(CASE WHEN m.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS NetFlow
FROM MorningWeekday AS m
JOIN dbo.dim_station AS s
    ON s.StationId IN (m.StartStationId, m.EndStationId)
GROUP BY
    s.StationName,
    s.Area
ORDER BY
    NetFlow DESC;   -- big positive = more departures than arrivals


-- Weekday evening net flow per station (starts - ends)
WITH EveningCommute AS (
    SELECT
        t.StartStationId,
        t.EndStationId
    FROM dbo.fact_trip AS t
    WHERE t.IsWeekend = 0
      AND t.StartHourOslo BETWEEN 15 AND 18   -- commute home window
)

SELECT
    s.StationName,
    s.Area,
    SUM(CASE WHEN e.StartStationId = s.StationId THEN 1 ELSE 0 END) AS Starts,
    SUM(CASE WHEN e.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS Ends,
    SUM(CASE WHEN e.StartStationId = s.StationId THEN 1 ELSE 0 END)
      - SUM(CASE WHEN e.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS NetFlow
FROM EveningCommute AS e
JOIN dbo.dim_station AS s
    ON s.StationId IN (e.StartStationId, e.EndStationId)
GROUP BY
    s.StationName,
    s.Area
ORDER BY
    NetFlow DESC;


CREATE VIEW dbo.v_morning_commute_netflow AS
WITH MorningCommute AS (
    SELECT
        StartStationId,
        EndStationId
    FROM dbo.fact_trip
    WHERE IsWeekend = 0
      AND StartHourOslo BETWEEN 7 AND 9
)
SELECT
    s.StationName,
    s.Area,
    SUM(CASE WHEN m.StartStationId = s.StationId THEN 1 ELSE 0 END) AS Starts,
    SUM(CASE WHEN m.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS Ends,
    SUM(CASE WHEN m.StartStationId = s.StationId THEN 1 ELSE 0 END)
      - SUM(CASE WHEN m.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS NetFlow
FROM MorningCommute AS m
JOIN dbo.dim_station AS s
    ON s.StationId IN (m.StartStationId, m.EndStationId)
GROUP BY
    s.StationName,
    s.Area;

CREATE VIEW dbo.v_evening_commute_netflow AS
WITH EveningCommute AS (
    SELECT
        StartStationId,
        EndStationId
    FROM dbo.fact_trip
    WHERE IsWeekend = 0
      AND StartHourOslo BETWEEN 15 AND 18
)
SELECT
    s.StationName,
    s.Area,
    SUM(CASE WHEN e.StartStationId = s.StationId THEN 1 ELSE 0 END) AS Starts,
    SUM(CASE WHEN e.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS Ends,
    SUM(CASE WHEN e.StartStationId = s.StationId THEN 1 ELSE 0 END)
      - SUM(CASE WHEN e.EndStationId   = s.StationId THEN 1 ELSE 0 END) AS NetFlow
FROM EveningCommute AS e
JOIN dbo.dim_station AS s
    ON s.StationId IN (e.StartStationId, e.EndStationId)
GROUP BY
    s.StationName,
    s.Area;

CREATE VIEW dbo.v_station_load AS
WITH TripStarts AS (
    SELECT
        StartStationId AS StationId,
        COUNT(*)       AS Starts
    FROM dbo.fact_trip
    GROUP BY StartStationId
),
TripEnds AS (
    SELECT
        EndStationId AS StationId,
        COUNT(*)     AS Ends
    FROM dbo.fact_trip
    GROUP BY EndStationId
)
SELECT
    s.StationName,
    s.Area,
    s.Capacity,
    COALESCE(ts.Starts, 0) AS TripsStarted,
    COALESCE(te.Ends,   0) AS TripsEnded,
    COALESCE(ts.Starts, 0) + COALESCE(te.Ends, 0) AS TotalTrips,
    CASE
        WHEN s.Capacity IS NULL OR s.Capacity = 0 THEN NULL
        ELSE CAST(COALESCE(ts.Starts, 0) + COALESCE(te.Ends, 0) AS FLOAT) / s.Capacity
    END AS TripsPerDock
FROM dbo.dim_station AS s
LEFT JOIN TripStarts AS ts ON ts.StationId = s.StationId
LEFT JOIN TripEnds   AS te ON te.StationId = s.StationId
WHERE COALESCE(ts.Starts, 0) + COALESCE(te.Ends, 0) > 0;

SELECT * FROM dbo.v_station_load ORDER BY TripsPerDock DESC;
