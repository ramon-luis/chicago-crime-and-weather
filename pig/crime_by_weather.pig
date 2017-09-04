-- load combined crime and weather data
CRIME_AND_WEATHER = LOAD '/ramonlrodriguez/final-project/inputs/crime_and_weather' USING PigStorage(',')
as (year:int, month:int, day:int,
   arrest, domestic, fbi_code, crime_weather_station,
   meanTemperature:double, meanVisibility: double, meanWindSpeed:double, fog:long, rain:long,
   snow:long,  hail:long, thunder:long, tornado:long);

-- identify types of crimes & good weather
CRIME_AND_WEATHER_CALC_FIELDS = FOREACH CRIME_AND_WEATHER GENERATE
  year, 1 as isCrime,
  (arrest == 'true' ? 1 : 0) AS isArrest,
  (domestic == 'true' ? 1 : 0) AS isDomestic, 
  (((fbi_code == '01A') OR (fbi_code == '02') OR (fbi_code == '03') OR (fbi_code == '04A') 
	OR (fbi_code == '04B')) ? 1 : 0) AS isViolentCrime,
  (fbi_code == '02' ? 1 : 0) AS isSexualAssault,
  (fbi_code == '05' ? 1 : 0) AS isBurglary,
  (fbi_code == '14' ? 1 : 0) AS isVandalism,
  (fbi_code == '16' ? 1 : 0) AS isProstitution,
  (((meanTemperature > 50) AND (fog != 1) AND (rain != 1) AND (snow != 1) AND (hail != 1) AND
  	     (thunder != 1) AND (tornado != 1)) ? 1 : 0) AS isGoodWeather;

-- identify types of crimes by weather
CRIME_AND_WEATHER_SET_FIELDS = FOREACH CRIME_AND_WEATHER_CALC_FIELDS GENERATE
  year, 
  isCrime, ((isGoodWeather == 1) ? 1 : 0) AS isGoodWeatherCrime,
  isArrest, (((isArrest == 1) AND (isGoodWeather == 1)) ? 1 : 0) AS isGoodWeatherArrest,
  isDomestic, (((isDomestic == 1) AND (isGoodWeather == 1)) ? 1 : 0) AS isGoodWeatherDomestic,
  isViolentCrime, (((isViolentCrime == 1) AND (isGoodWeather == 1)) ? 1 : 0) AS isGoodWeatherViolentCrime,
  isSexualAssault, (((isSexualAssault == 1) AND (isGoodWeather == 1)) ? 1 : 0) AS isGoodWeatherSexualAssault,
  isBurglary, (((isBurglary == 1) AND (isGoodWeather == 1)) ? 1 : 0) AS isGoodWeatherBurglary,
  isVandalism, (((isVandalism == 1) AND (isGoodWeather == 1)) ? 1 : 0) AS isGoodWeatherVandalism,
  isProstitution, (((isProstitution == 1) AND (isGoodWeather == 1)) ? 1 : 0) AS isGoodWeatherProstitution;

-- group by year -> key for hbase table
CRIME_AND_WEATHER_GROUPED_BY_DATE = GROUP CRIME_AND_WEATHER_SET_FIELDS by year;

-- sum types of crimes by weather
SUMMED_CRIME_BY_WEATHER = FOREACH CRIME_AND_WEATHER_GROUPED_BY_DATE
  GENERATE group as crimeYear,
  SUM($1.isCrime) AS totalCrimes, SUM($1.isGoodWeatherCrime) AS goodWeatherCrimes,  
  SUM($1.isArrest) AS totalArrests, SUM($1.isGoodWeatherArrest) AS goodWeatherArrests,
  SUM($1.isDomestic) AS totalDomestics, SUM($1.isGoodWeatherDomestic) AS goodWeatherDomestics,
  SUM($1.isViolentCrime) AS totalViolentCrimes, SUM($1.isGoodWeatherViolentCrime) AS goodWeatherViolentCrimes,
  SUM($1.isSexualAssault) AS totalSexualAssaults, SUM($1.isGoodWeatherSexualAssault) AS goodWeatherSexualAssaults,
  SUM($1.isBurglary) AS totalBurglaries, SUM($1.isGoodWeatherBurglary) AS goodWeatherBurglaries,
  SUM($1.isVandalism) AS totalVandalisms, SUM($1.isGoodWeatherVandalism) AS goodWeatherVandalisms,
  SUM($1.isProstitution) AS totalProstitutions, SUM($1.isGoodWeatherProstitution) AS goodWeatherProstitutions;

-- store final results in hbase
STORE SUMMED_CRIME_BY_WEATHER INTO 'hbase://ramonlrodriguez_summed_crime_by_weather'
  USING org.apache.pig.backend.hadoop.hbase.HBaseStorage(
    'crime:totalCrimes, crime:goodWeatherCrimes, crime:totalArrests, crime:goodWeatherArrests, crime:totalDomestics, crime:goodWeatherDomestics, crime:totalViolentCrimes, crime:goodWeatherViolentCrimes, crime:totalSexualAssaults, crime:goodWeatherSexualAssaults, crime:totalBurglaries, crime:goodWeatherBurglaries, crime:totalVandalisms, crime:goodWeatherVandalisms, crime:totalProstitutions, crime:goodWeatherProstitutions');