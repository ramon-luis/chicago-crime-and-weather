-- Import the CSVLoader plugin (available from the 3rd party piggybank modules collection)
REGISTER /home/mpcs53013/ramonlrodriguez/final-project/usr/piggybank-0.16.0.jar;

-- Load raw data
RAW_CRIME_DATA = LOAD '/ramonlrodriguez/final-project/crimeData.csv' USING
	       org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'NO_MULTILINE', 'NOCHANGE', 'SKIP_INPUT_HEADER'); 

-- define columns
CRIME_DATA_BAD_DATE_FORMAT = FOREACH RAW_CRIME_DATA GENERATE $2 AS date, $8 AS arrest, $9 AS domestic, $14 AS fbi_code;

-- convert date to PIG date format, then extract year, month, day as columns
CRIME_DATA_WITH_DATES = FOREACH CRIME_DATA_BAD_DATE_FORMAT GENERATE GetYear(ToDate(date, 'MM/dd/yyyy hh:mm:ss a'))
		      AS crime_year, GetMonth(ToDate(date, 'MM/dd/yyyy hh:mm:ss a')) AS crime_month,
		      GetDay(ToDate(date, 'MM/dd/yyyy hh:mm:ss a')) AS crime_day, arrest, domestic, fbi_code;

-- add weather_station: 725340 is MDW
CRIME_DATA = FOREACH CRIME_DATA_WITH_DATES GENERATE crime_year, crime_month, crime_day, arrest, domestic, fbi_code, '725340' AS crime_weather_station;
  
-- store in HDFS
STORE CRIME_DATA INTO '/ramonlrodriguez/final-project/inputs/crime/' USING PigStorage(',');
