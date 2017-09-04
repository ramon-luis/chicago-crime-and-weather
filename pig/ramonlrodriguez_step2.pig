REGISTER /home/mpcs53013/ramonlrodriguez/final-project/usr/elephant-bird-core-4.14.jar;
REGISTER /home/mpcs53013/ramonlrodriguez/final-project/usr/elephant-bird-pig-4.14.jar;
REGISTER /home/mpcs53013/ramonlrodriguez/final-project/usr/elephant-bird-hadoop-compat-4.14.jar;
REGISTER /home/mpcs53013/ramonlrodriguez/final-project/usr/piggybank-0.16.0.jar;
REGISTER /home/mpcs53013/ramonlrodriguez/final-project/usr/libthrift-0.9.0.jar;
REGISTER /home/mpcs53013/ramonlrodriguez/final-project/uber-weatherIngest-0.0.1-SNAPSHOT.jar;

DEFINE WSThriftBytesToTuple com.twitter.elephantbird.pig.piggybank.ThriftBytesToTuple('edu.uchicago.mpcs53013.weatherSummary.WeatherSummary');

-- get crime data
CRIME_DATA = LOAD '/ramonlrodriguez/final-project/inputs/crime/part*' USING PigStorage(',')
  AS (crime_year, crime_month, crime_day, arrest, domestic, fbi_code, crime_weather_station);

-- get weather data
RAW_WEATHER_DATA = LOAD '/ramonlrodriguez/final-project/inputs/thriftWeather' 
	USING org.apache.pig.piggybank.storage.SequenceFileLoader AS (key:long, value: bytearray);
WEATHER_SUMMARY = FOREACH RAW_WEATHER_DATA GENERATE FLATTEN(WSThriftBytesToTuple(value));

-- join crime and weather
CRIME_AND_WEATHER_RAW = JOIN WEATHER_SUMMARY BY ((int) WeatherSummary::year, (int) WeatherSummary::month, (int) WeatherSummary::day, 
	(int) WeatherSummary::station), CRIME_DATA BY ((int) crime_year, (int) crime_month, (int) crime_day, (int) crime_weather_station);

-- get rid of duplicate columns
CRIME_AND_WEATHER = FOREACH CRIME_AND_WEATHER_RAW GENERATE WeatherSummary::year, WeatherSummary::month,
		  WeatherSummary::day, arrest, domestic, fbi_code, crime_weather_station, meanTemperature,
		  meanVisibility, meanWindSpeed, fog, rain, snow, hail, thunder, tornado;

-- store in HDFS
STORE CRIME_AND_WEATHER into '/ramonlrodriguez/final-project/inputs/crime_and_weather' USING PigStorage(',');
