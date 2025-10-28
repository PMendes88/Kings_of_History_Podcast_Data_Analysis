--- Create the podcast_stats database
CREATE DATABASE podcast_stats;


-- Platform downloads table
CREATE TABLE platform_downloads (
    app TEXT,
    downloads INT
);

-- Geography downloads table
CREATE TABLE geo_downloads (
    city TEXT,
    state TEXT,
    country TEXT,
    continent TEXT,
    downloads INT
);

-- Episode downloads table
CREATE TABLE episode_downloads (
    episode_title TEXT,
    episode_id INT,
    publish_date DATE,
    publish_status TEXT,
    downloads_last_7d INT,
    downloads_last_30d INT,
    downloads_last_90d INT,
    all_time_downloads INT
);

/* ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
Database Load Issues (follow if receiving permission denied when running SQL code below)

Possible Errors: 

- ERROR >> could not open file "C:\Users\...\....csv" for reading: Permission denied

1. Drop the Database 
            DROP DATABASE IF EXISTS sql_course;
2. Repeat steps to create database and load table schemas
            - 1_create_database.sql
            - 2_create_tables.sql
3. Open pgAdmin
4. In Object Explorer (left-hand pane), navigate to `sql_course` database
5. Right-click `sql_course` and select `PSQL Tool`
            - This opens a terminal window to write the following code
6. Get the absolute file path of your csv files
            1. Find path by right-clicking a CSV file in VS Code and selecting “Copy Path”
7. Paste the following into `PSQL Tool`, (with the CORRECT file path)

\copy platform_downloads FROM 'C:/Users/Pedro/Desktop/Data Analysis Project 3/Podcast Dataset/stats_agent_report.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');
\copy geo_downloads FROM 'C:/Users/Pedro/Desktop/Data Analysis Project 3/Podcast Dataset/stats_locations_report.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');
\copy episode_downloads FROM 'C:/Users/Pedro/Desktop/Data Analysis Project 3/Podcast Dataset/stats_overview_report.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Load data into the orders table

*/


-- Import downloads table
COPY platform_downloads (app, downloads)
FROM 'C:/Users/Pedro/Desktop/Data Analysis Project 3/Podcast Dataset/stats_agent_report.csv'
DELIMITER ','
CSV HEADER;

-- Import geography table
COPY geo_downloads (city, state, country, continent, downloads)
FROM 'C:\Users\Pedro\Desktop\Data Analysis Project 3\Podcast Dataset\stats_locations_report.csv'
DELIMITER ','
CSV HEADER;

-- Import episdes table
COPY episodes (episode_title, episode_id, publish_date, publish_status,
               downloads_7d, downloads_30d, downloads_90d, all_time_downloads)
FROM 'C:\Users\Pedro\Desktop\Data Analysis Project 3\Podcast Dataset\stats_overview_report.csv'
DELIMITER ','
CSV HEADER;
