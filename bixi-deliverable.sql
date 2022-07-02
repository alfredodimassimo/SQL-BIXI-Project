 ##################
### BIXI PROJECT ###
 ##################

### Initial data analysis ### 
SELECT *
FROM stations;

SELECT COUNT(*)
FROM stations; -- The data includes information pertaining to 540 different stations.

SELECT *
FROM trips;

SELECT COUNT(*)
FROM trips; -- The table includes data gathered from 8,584,166 trips.

### QUESTION 1 ### Gaining an overall view of the volume usage and what factors may influence it.
# PART 1: To determine the number of trips that occurred in 2016.

SELECT
	COUNT(YEAR(end_date)) AS num_trips_2016
FROM trips
WHERE YEAR(end_date) = 2016;
-- There were 3,917,401 trips in 2016.
    
# PART 2: To determine the number of trips that occurred in 2017.

SELECT
	COUNT(YEAR(end_date)) AS num_trips_2017
FROM trips
WHERE YEAR(end_date) = 2017;
-- The result was 4,666,765 trips

#NOTE: Performing the same query for subsequent years could also indicate growing popularity of the Bixi bike service

# PART 3: To determine the total number of trips in 2016 by month.

SELECT
	COUNT(*)
FROM trips
WHERE MONTH(start_date) != MONTH(end_date); -- This returned a total of 1,549 trips where users started a trip on the last day of one month
-- and returned it on the first day of the next month.
-- Rather than confirming query results with both start_date and end_date, only start_date was used unless specified by the question
-- to avoid differing results in monthly breakdown of number of trips.

SELECT
	MONTH(start_date) AS month,
    COUNT(*) AS num_trips_2016
FROM trips
WHERE YEAR(start_date) = 2016
GROUP BY month
ORDER BY num_trips_2016 DESC;
-- By grouping by month, but ordering by descending number of trips, increased usage can be observed in the summer months of June, July and August, 
-- given the colder weather in Montreal during the Fall and Spring.

# PART 4: To determine the total number of trips in 2017 by month.

SELECT
	MONTH(start_date) AS month,
    COUNT(*) AS num_trips_2017 
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY month
ORDER BY num_trips_2017 DESC;
-- The same note of increased usage during the summer months is observed for 2017.

-- The following query demonstrates part 3 & part 4 side by side to better compare the volumes in each months, demonstrating
-- the increased usage for the year 2017 once again as well as the consistent increase in volumee during the sumemr months.

SELECT
	monthly_2017.month,
    monthly_2016.num_trips_2016,
    monthly_2017.num_trips_2017    
FROM
	(
    SELECT
		EXTRACT(MONTH FROM start_date) AS month,
        COUNT(*) AS num_trips_2017
	WHERE YEAR(start_date) = 2017
	GROUP BY month) AS monthly_2017
LEFT JOIN 
	(SELECT
		EXTRACT(MONTH FROM start_date) AS month,
        COUNT(*) AS num_trips_2016
	FROM trips
	WHERE YEAR(start_date) = 2016
	GROUP BY month) AS monthly_2016
ON monthly_2016.month = monthly_2017.month;


# PART 5: To determine the average number of daily trips in a given month for each year.

SELECT 
	MONTH(start_date) AS month,
    ROUND(SUM(YEAR(start_date) = 2016) / COUNT(DISTINCT CASE WHEN YEAR(start_date) = 2016 THEN DAY(start_date) END), 0)  AS avg_daily_trips_2016,
	ROUND(SUM(YEAR(start_date) = 2017) / COUNT(DISTINCT CASE WHEN YEAR(start_date) = 2017 THEN DAY(start_date) END), 0)  AS avg_daily_trips_2017
FROM trips
WHERE YEAR(start_date) IN (2016, 2017)
GROUP BY month;

# PART 6: Store the results of part 5 into a new table

DROP TABLE IF EXISTS working_table1;
CREATE TABLE working_table1 AS
SELECT 
	MONTH(start_date) AS month,
    ROUND(SUM(YEAR(start_date) = 2016) / COUNT(DISTINCT CASE WHEN YEAR(start_date) = 2016 THEN DAY(start_date) END), 0)  AS avg_daily_trips_2016,
	ROUND(SUM(YEAR(start_date) = 2017) / COUNT(DISTINCT CASE WHEN YEAR(start_date) = 2017 THEN DAY(start_date) END), 0)  AS avg_daily_trips_2017
FROM trips
WHERE YEAR(start_date) IN (2016, 2017)
GROUP BY month;

SELECT *
FROM working_table1;

### QUESTION 2 ### Provide a better understanding of member vs non-member behaviour.
# PART 1: Determine the number of member and non-member trips in 2017

SELECT 
	COUNT(start_date) AS num_trips,
    is_member -- Assumption: 1 is member, 0 is non-member
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY is_member;
-- There were 3,784,682 member trips and 882,083 non-member trips in 2017.

# PART 2: Calculating the fraction of monthly member trips to total monthly trips for each month in 2017
 
SELECT
	MONTH(start_date) AS month,
    AVG(CASE WHEN is_member = 1 THEN 1 ELSE 0 END) AS pct_member_trips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY month;
-- The data shows that the vast majority of monthly trips are by members.

### QUESTION 3 ### Using all previous queries, we can gain better insight into the monthly usage of the service.
# PART 1: 
/* It's not surprising to see that the peak usage of Bixi rentals can be observed in the summer months. During the winter months
the Bixi service is temporarily suspended and the bikes are stored from November 15th until April 15th. This not only explains
the lack of data for December through march, but the reduced usage in April and November are also explained by the fact that the service is only available
for half of those months. */

# PART 2:
/* Given the lower usage of the Bixi service between April to May and October to November, it would be ideal to offer non-members a membership discount
between the Spring and Autumn months to promote higher usage. These are also the months with the lowest proportion of non-member usage so there is also 
a greater opportunity to promote the service to this segment of the market throughout these months.*/

### QUESTION 4 ### Examining the popularity of different stations.

# PART 1: Determine the 5 most popular starting stations without using a sub-query.

SELECT
	COUNT(*) AS num_trips,
    s.name
FROM trips AS t
LEFT JOIN stations AS s
	ON s.code = t.start_station_code
GROUP BY s.name
ORDER BY num_trips DESC
LIMIT 5;
-- The above query had a run time of 25.078 seconds.

# PART 2: Determine the 5 most popular starting stations by using a sub-query.
SELECT
	s.code,
    s.name,
    start_stations.num_trips
FROM stations s
INNER JOIN (
	SELECT
		COUNT(*) AS num_trips,
		start_station_code
	FROM trips
    GROUP BY start_station_code
    ORDER BY num_trips DESC
    LIMIT 10) AS start_stations
ON start_stations.start_station_code = s.code;
-- The above query had a run time of 3.922 seconds.
-- This demonstrates that filtering within a sub-query is much more efficient than doing so after joining to larger tables.

### QUESTION 5 ### Analyzing usage of the Bixi service at different times in the day.

# PART 1: Breaking down the data based on time of day.

SELECT
	s.name,
    trips.time_of_day,
    COUNT(*) AS num_trips
FROM
	(SELECT *,
		CASE
		   WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
		   WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
		   WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
		   ELSE "night"
		   END AS "time_of_day"
	from trips) AS trips
RIGHT JOIN stations s
	ON s.code = trips.start_station_code
WHERE name = 'Mackay / de Maisonneuve' 
GROUP BY trips.time_of_day
ORDER BY num_trips DESC;

-- We can observe the following breakdown when this station is the starting point of a trip:
-- Morning: 17,384
-- Afternoon: 30,718
-- Evening: 36,781
-- Night: 12,267

SELECT
	s.name,
    trips.time_of_day,
    COUNT(*) AS num_trips
FROM
	(SELECT *,
		CASE
		   WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
		   WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
		   WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
		   ELSE "night"
		   END AS "time_of_day"
	from trips) AS trips
LEFT JOIN stations s
	ON s.code = trips.end_station_code
WHERE name = 'Mackay / de Maisonneuve' 
GROUP BY trips.time_of_day
ORDER BY num_trips DESC;

-- We can observe the following breakdown when this station is the ending point of a trip:
-- Morning: 26,390
-- Afternoon: 30,429
-- Evening: 31,983
-- Night: 10,326

/* The primary differences can be seen between the morning and the evening, essentially when people are arriving and leaving for work.
Given that there's a higher number of trips in the evening for when this station is a starting point, but a higher number
in the morning when this station is an ending point, it can be concluded that this station is likely a commercial
area of the city where people are working and starting their day as opposed to a residential area where people are liekly
ending their day. */

### QUESTION 6 ### Analyzing stations that are used for round trips.

# PART 1: Query the number of starting trips per station

SELECT
	trips.num_trips,
    s.name
FROM 
	(
    SELECT
		COUNT(*) AS num_trips,
        start_station_code
	FROM trips
    GROUP BY start_station_code
    ORDER BY num_trips DESC) AS trips
LEFT JOIN stations s
	ON s.code = trips.start_station_code;
    
# PART 2: Query the number of round trips per station

SELECT
	s.name AS station_name,
	SUM(IF(start_station_code = end_station_code, 1, 0)) AS num_round_trips
FROM trips t
LEFT JOIN stations s
	ON s.code = t.start_station_code
GROUP BY station_name
ORDER BY num_round_trips DESC;
    
# PART 3: Combine PART 1 & PART 2 to calculate the fraction of round trips to the total number of trips for each station

SELECT 
    (round_trips.num_trips / start_trips.num_trips) AS fraction_of_round_trips,
    s.name AS station_name
FROM
    (SELECT 
        COUNT(*) AS num_trips, 
        start_station_code
    FROM trips
    WHERE start_station_code = end_station_code
    GROUP BY start_station_code
    ORDER BY num_trips DESC) AS round_trips
LEFT JOIN stations AS s 
	ON s.code = round_trips.start_station_code
RIGHT JOIN
    (SELECT 
        COUNT(*) AS num_trips, 
        start_station_code
    FROM
        trips
    GROUP BY start_station_code
    ORDER BY num_trips) AS start_trips 
	ON s.code = start_trips.start_station_code;

# PART 4: Filter the stations with at least 500 trips that start with them and have at least 10% of their trips as round trips.

SELECT
	(round_trips.num_trips / start_trips.num_trips) AS fraction_of_round_trips,
	start_trips.num_trips AS num_trips,
    s.name AS station_name
FROM 
	(SELECT 
        COUNT(*) AS num_trips, 
        start_station_code
    FROM trips
    WHERE start_station_code = end_station_code
    GROUP BY start_station_code
    ORDER BY num_trips DESC) AS round_trips
LEFT JOIN stations s
	ON s.code = round_trips.start_station_code
RIGHT JOIN
	(SELECT 
        COUNT(*) AS num_trips, 
        start_station_code
    FROM
        trips
    GROUP BY start_station_code
    ORDER BY num_trips) AS start_trips
ON s.code = start_trips.start_station_code
WHERE start_trips.num_trips >= 500
	AND (round_trips.num_trips / start_trips.num_trips) >= 0.1;
    
# PART 5: 
/* We can expect to find stations with a high fraction of round trips near tourism sectors as people will likely start a trip
to visit different tourist attractions in the area, but return the bike to the same station once they are done with their tour. */