/* 
Bixit Project
Rachel Kessler
SQL Queries 
*/

-- The total number of trips for the years of 2016.
SELECT COUNT(*)
FROM trips
WHERE YEAR(start_date) = 2016;

-- The total number of trips for the years of 2017.
SELECT COUNT(*)
FROM trips
WHERE YEAR(start_date) = 2017;

-- The total number of trips for the years of 2016 broken-down by month.
SELECT MONTH(start_date) AS Month, COUNT(id) AS Trips
FROM trips
WHERE YEAR(start_date) = 2016
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);

-- The total number of trips for the years of 2017 broken-down by month.
SELECT MONTH(start_date) AS Month, COUNT(id) AS Trips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);

-- The average number of trips a day for each year-month combination in the dataset.
SELECT MONTH(start_date) AS Month, COUNT(id)/DAY(LAST_DAY(start_date)) AS AvgTrips
FROM trips
GROUP BY YEAR(start_date), MONTH(start_date);

-- The total number of trips in the year 2017 broken-down by membership status (member/non-member).
SELECT is_member, COUNT(id)
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY is_member;

-- The fraction of total trips that were done by members for the year of 2017 broken-down by month.
SELECT MONTH(start_date), COUNT(*)/(SELECT COUNT(*) FROM trips WHERE YEAR(start_date) = 2017 AND is_member =1)
FROM trips
WHERE YEAR(start_date) = 2017 AND is_member =1
GROUP BY MONTH(start_date);

-- Calculate the average trip time across the entire dataset.
SELECT AVG(duration_sec)
FROM trips;

-- Calculate the average trip time broken-down by:	Membership status, Month, Day of the week, Station name
SELECT is_member, AVG(duration_sec)
FROM trips
GROUP BY is_member;

-- By Month
SELECT MONTH(start_date), AVG(duration_sec)
FROM trips
GROUP BY MONTH(start_date);

-- By Day of the Week
SELECT DAYOFWEEK(start_date), AVG(duration_sec)
FROM trips
GROUP BY DAYOFWEEK(start_date)
ORDER BY DAYOFWEEK(start_date);

-- By Station Name
SELECT stations.name, StationAvg.*
FROM ( 
		SELECT start_station_code, AVG(duration_sec) AS AvgDuration
        FROM trips
        GROUP BY start_station_code
	) AS StationAvg 
JOIN stations
ON stationavg.start_station_code = stations.code
ORDER BY StationAvg.AvgDuration DESC;

-- Calculate the fraction of trips that were round trips and break it down by:
-- Membership status
SELECT is_member, SUM(roundtrip)/COUNT(*) AS frac_roundtrip
FROM(
    SELECT is_member, IF(start_station_code = end_station_code, 1, 0) AS roundtrip
	FROM trips
    ) AS RoundTrips
GROUP BY is_member;

-- Day of the week
SELECT dotw, SUM(roundtrip)/COUNT(*) AS frac_roundtrip
FROM(
    SELECT DAYOFWEEK(start_date) AS dotw, IF(start_station_code = end_station_code, 1, 0) AS roundtrip
	FROM trips
    ) AS RoundTrips
GROUP BY dotw
ORDER BY dotw;

-- What are the names of the 5 most popular starting stations (i.e. the 5 stations with most trips starting from them)?
SELECT stations.name, StationTrips.*
FROM ( 
		SELECT start_station_code, COUNT(*) AS NumTrips
        FROM trips
        GROUP BY start_station_code
        ORDER BY NumTrips DESC 
        LIMIT 5
	) AS StationTrips
JOIN stations
ON stationtrips.start_station_code = stations.code;

-- What are the names of the 5 most popular ending stations (i.e. the 5 stations with most trips ending from them)?
SELECT stations.name, EndStationTrips.*
FROM ( 
		SELECT end_station_code, COUNT(*) AS NumTripsEnd
        FROM trips
        GROUP BY end_station_code
        ORDER BY NumTripsEnd DESC 
        LIMIT 5
	) AS EndStationTrips
JOIN stations
ON endstationtrips.end_station_code = stations.code;

-- If we break-up the hours of the day
-- How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?
-- Starts:
SELECT CASE
	WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
	WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
	WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
	ELSE "night"
 END AS "time_of_day", COUNT(*) AS NumTrips
FROM (
	SELECT *
	FROM trips
	WHERE start_station_code = 6100) AS MackayStartTrips
GROUP BY time_of_day;

-- Ends:
SELECT CASE
	WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
	WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
	WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
	ELSE "night"
 END AS "time_of_day", COUNT(*) AS NumTrips
FROM (
	SELECT *
	FROM trips
	WHERE end_station_code = 6100) AS MackayEndTrips
GROUP BY time_of_day;

-- Which station has proportionally the least number of member trips? How about the most? 
SELECT stations.name, MemberTrips.start_station_code AS Code, MemberTrips.MemberFrac
FROM stations 
	JOIN
		(
        SELECT start_station_code, SUM(is_member)/COUNT(start_station_code) AS MemberFrac
		FROM trips
		GROUP BY start_station_code
		HAVING COUNT(start_station_code) >= 10 AND COUNT(end_station_code) >= 10
        )
        AS MemberTrips
	ON stations.code = MemberTrips.start_station_code
ORDER BY MemberFrac DESC;


-- Write a query that counts the number of starting trips per station.
SELECT start_station_code, COUNT(start_station_code) AS TotalTripsStarted
FROM trips
GROUP BY start_station_code;
-- Write a query that counts, for each station, the number of round trips.
SELECT start_station_code, COUNT(start_station_code) AS TotalRoundTrips
FROM trips
WHERE start_station_code = end_station_code
GROUP BY start_station_code;
-- Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station.
SELECT TripsStarted.start_station_code, TotalRoundTrips/TotalTripsStarted AS FracRoundTrips
FROM 
	(SELECT start_station_code, COUNT(start_station_code) AS TotalTripsStarted
	FROM trips
	GROUP BY start_station_code) AS TripsStarted
JOIN
	(SELECT start_station_code, COUNT(start_station_code) AS TotalRoundTrips
	FROM trips
	WHERE start_station_code = end_station_code
	GROUP BY start_station_code) AS RoundTrips
ON TripsStarted.start_station_code = RoundTrips.start_station_code
ORDER BY FracRoundTrips DESC;

-- Filter down to stations with at least 50 trips originating from them.
SELECT TripsStarted.start_station_code, TotalRoundTrips/TotalTripsStarted AS FracRoundTrips
FROM 
	(SELECT start_station_code, COUNT(start_station_code) AS TotalTripsStarted
	FROM trips
	GROUP BY start_station_code
	HAVING TotalTripsStarted >= 50) AS TripsStarted
JOIN
	(SELECT start_station_code, COUNT(start_station_code) AS TotalRoundTrips
	FROM trips
	WHERE start_station_code = end_station_code
	GROUP BY start_station_code) AS RoundTrips
ON TripsStarted.start_station_code = RoundTrips.start_station_code
ORDER BY FracRoundTrips DESC;
