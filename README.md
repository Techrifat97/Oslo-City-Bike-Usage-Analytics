# Oslo city bike – demand and station pressure (May–Oct 2025)

This repo contains an end-to-end analysis of Oslo Bysykkel trips.  
I worked with almost one million rides from May–Oct 2025 to understand:

- when demand is highest during the day  
- which stations act as morning commute hubs (origins vs destinations)  
- where station capacity is under the most pressure (trips per dock)


## Data and questions

Source
- Oslo Bysykkel open data (trip logs and station list)
- Period: May–Oct 2025

**Main questions**
1. When is demand actually highest during the day (weekday vs weekend)?
2. Which stations are key hubs in the morning commute (07–09)?
3. Which stations have the highest trips per dock, and how does this differ by area?

## Stack and process

Tools
- Python (pandas)  
- SQL Server (Docker)  
- Tableau Public  

Steps (high level)

1. Python
   - Download monthly trip CSVs
   - Convert timestamps to Oslo time
   - Derive weekday/weekend, hour of day and time-of-day buckets
   - Join station metadata (name, capacity, coordinates)
   - Use a map/geocoding API with lat/long to assign a rough Area
   - Save cleaned monthly files to `data/processed/`

2. SQL Server
   - Load cleaned trips into `fact_trip`
   - Load stations into `dim_station`
   - Use SQL to calculate:
     - hourly usage (weekday vs weekend)
     - morning net flows (starts vs ends, 07–09)
     - station-level load: `TotalTrips` and `TripsPerDock`

3. Tableau
   - Build a “Commute patterns” dashboard (hourly usage + morning hubs)
   - Build a “Station load vs capacity” map:
   - circle size = total trips
   - colour = trips per dock
   - filters for capacity, trips per dock and area

