#!/usr/bin/perl -w
# Creates an html table of crime pct by type and weather

# Needed includes
use strict;
use warnings;
use 5.10.0;
use HBase::JSONRest;
use CGI qw/:standard/;

# Read the year as CGI parameter
my $year = param('year');
 
# Define a connection template to access the HBase REST server
# If you are on our cluster, hadoop-m will resolve to our Hadoop master
# node, which is running the HBase REST server. The first version
# is for our VM, the second is for running on the class cluster
# my $hbase = HBase::JSONRest->new(host => "localhost:8080");
my $hbase = HBase::JSONRest->new(host => "hdp-m:2056");

# # This function takes a row and gives you the value of the given column
# # E.g., cellValue($row, 'delay:rain_delay') gives the value of the
# # rain_delay column in the delay family.
# # It uses somewhat tricky perl, so you can treat it as a black box
sub cellValue {
     my $row = $_[0];
     my $field_name = $_[1];
     my $row_cells = ${$row}{'columns'};
     foreach my $cell (@$row_cells) {
 	if ($$cell{'name'} eq $field_name) {
	    return $$cell{'value'};
 	}
     }
     return 'missing';
}

# # Query hbase for the crime data by weather.
my $records = $hbase->get({
  table => 'ramonlrodriguez_summed_crime_by_weather',
  where => {
    key_equals => $year
  },
});

# There will only be one record for the table which will be the "zeroth" row returned
my $row = @$records[0];

# Get the value of all the columns we need and store them in named variables
my ($totalCrimes, $goodWeatherCrimes, 
    $totalDomestics, $goodWeatherDomestics, 
    $totalArrests, $goodWeatherArrests, 
    $totalViolentCrimes, $goodWeatherViolentCrimes, 
    $totalSexualAssaults, $goodWeatherSexualAssaults, 
    $totalBurglaries, $goodWeatherBurglaries, 
    $totalVandalisms, $goodWeatherVandalisms,
    $totalProstitutions, $goodWeatherProstitutions) =

   (cellValue($row, 'crime:totalCrimes'), cellValue($row, 'crime:goodWeatherCrimes'),
    cellValue($row, 'crime:totalDomestics'), cellValue($row, 'crime:goodWeatherDomestics'),
    cellValue($row, 'crime:totalArrests'), cellValue($row, 'crime:goodWeatherArrests'),
    cellValue($row, 'crime:totalViolentCrimes'), cellValue($row, 'crime:goodWeatherViolentCrimes'),
    cellValue($row, 'crime:totalSexualAssaults'), cellValue($row, 'crime:goodWeatherSexualAssaults'), 
    cellValue($row, 'crime:totalBurglaries'), cellValue($row, 'crime:goodWeatherBurglaries'),
    cellValue($row, 'crime:totalVandalisms'), cellValue($row, 'crime:goodWeatherVandalisms'),
    cellValue($row, 'crime:totalProstitutions'), cellValue($row, 'crime:goodWeatherProstitutions'));
		
# set variables for badWeather crimes: calculated from existing variables that come from the columns				     
my ($badWeatherCrimes, $badWeatherArrests, 
    $badWeatherDomestics, $badWeatherViolentCrimes, 
    $badWeatherSexualAssaults, $badWeatherBurglaries, 
    $badWeatherVandalisms, $badWeatherProstitutions) = 

   ($totalCrimes - $goodWeatherCrimes, $totalArrests - $goodWeatherArrests, 
    $totalDomestics - $goodWeatherDomestics, $totalViolentCrimes - $goodWeatherViolentCrimes, 
    $totalSexualAssaults - $goodWeatherSexualAssaults, $totalBurglaries - $goodWeatherBurglaries, 
    $totalVandalisms - $goodWeatherVandalisms, $totalProstitutions - $goodWeatherProstitutions);

# calculate the pct of total # occurences that occur in that weather
sub weather_pct {
  my($weatherCrimeOccurence, $totalCrimeOccurence) = @_;
  return $totalCrimeOccurence == 0 ? 0 : sprintf("%.1f", $weatherCrimeOccurence/$totalCrimeOccurence);
}

# Print an HTML page with the table.
print header, start_html(-title=>'crime data',-head=>Link({-rel=>'stylesheet',-href=>'/table.css',-type=>'text/css'}));

print div({-style=>'margin-left:275px;margin-right:auto;display:inline-block;box-shadow: 10px 10px 5px #888888;
    border:1px solid #000000;-moz-border-radius-bottomleft:9px;-webkit-border-bottom-left-radius:9px;
    border-bottom-left-radius:9px;-moz-border-radius-bottomright:9px;-webkit-border-bottom-right-radius:9px;
    border-bottom-right-radius:9px;-moz-border-radius-topright:9px;-webkit-border-top-right-radius:9px;
    border-top-right-radius:9px;-moz-border-radius-topleft:9px;-webkit-border-top-left-radius:9px;border-top-left-radius:9px;
    background:white'}, '&nbsp;Crime Data for 2001-2016 by Weather&nbsp;GoodWeather: temp &gt; 50 degrees F, no fog, no rain, no snow, no hail, no thunder, no tornados&nbsp;BadWeather: cold, foggy, raining, snowing, hailing, thunder, or tornados&nbsp;');

print p({-style=>"bottom-margin:10px"});

print table({-class=>'CSS_Table_Example', -style=>'width:90%;margin:auto;'},

	    Tr([
              td(['Crime', 'Total Occurences', 'Good Weather', '%', 'Bad Weather', '%']),
              td(['All Crime', $totalCrimes, $goodWeatherCrimes, weather_pct($goodWeatherCrimes, $totalCrimes), 
                 $badWeatherCrimes, weather_pct($badWeatherCrimes, $totalCrimes)]),
              td(['Arrests', $totalArrests, $goodWeatherArrests, weather_pct($goodWeatherArrests, $totalArrests), 
                 $badWeatherArrests, weather_pct($badWeatherArrests, $totalArrests)]),
              td(['Domestic Crime', $totalDomestics, $goodWeatherDomestics, weather_pct($goodWeatherDomestics, $totalDomestics), 
                 $badWeatherDomestics, weather_pct($badWeatherDomestics, $totalDomestics)]),
              td(['Violent Crime', $totalViolentCrimes, $goodWeatherViolentCrimes, weather_pct($goodWeatherViolentCrimes, $totalViolentCrimes), 
                 $badWeatherViolentCrimes, weather_pct($badWeatherViolentCrimes, $totalViolentCrimes)]),
              td(['Sexual Assault', $totalSexualAssaults, $goodWeatherSexualAssaults, weather_pct($goodWeatherSexualAssaults, 
                 $totalSexualAssaults), $badWeatherSexualAssaults, weather_pct($badWeatherSexualAssaults, $totalSexualAssaults)]),
              td(['Burglary', $totalBurglaries, $goodWeatherBurglaries, weather_pct($goodWeatherBurglaries, $totalBurglaries), 
                 $badWeatherBurglaries, weather_pct($badWeatherBurglaries, $totalBurglaries)]),
              td(['Vandalism', $totalVandalisms, $goodWeatherVandalisms, weather_pct($goodWeatherVandalisms, $totalVandalisms), 
                 $badWeatherVandalisms, weather_pct($badWeatherVandalisms, $totalVandalisms)]),
              td(['Prostitution', $totalProstitutions, $goodWeatherProstitutions, weather_pct($goodWeatherProstitutions, $totalProstitutions), 
                 $badWeatherProstitutions, weather_pct($badWeatherProstitutions, $totalProstitutions)])])),
	    p({-style=>"bottom-margin:10px"})
    ;
		
print end_html;

