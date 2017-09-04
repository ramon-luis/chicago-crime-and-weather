FINAL PROJECT: CHICAGO CRIME AND WEATHER
MPCS 53013 - FALL 2016
Ramon Rodriguez
CNET: ramonlrodriguez

URLs
view crime report: http://104.197.248.161/ramonlrodriguez/crime-report.html
submit new crime report: http://104.197.248.161/ramonlrodriguez/submit-crime.html

Data Sources
weather: ftp://ftp.ncdc.noaa.gov/pub/data/gsod/
crime: https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-present/ijzp-q8t2

HBase Tables
ramonlrodriguez-summed-crime-by-year
ramonlrodriguez-current-crime

Kafka Topic
ramonlrodriguez-crime-events

File Locations on Cluster
hdp-m:~/ramonlrodriguez/final-project
webserver:~/ramonrodriguez
webserver:~/usr/lib/cgi-bin/ramonlrodriguez
webserver:~/var/www/html/ramonlrodriguez

Project Summary
Chicago Crime and Weather app uses weather and crime data from 2001 to 2016 to summarize types of crime
committed during good and bad weather conditions.

Crime is categorized based on tags within the Chicago data set: CPD records (1) if a crime is an arrest 
or domestic crime (based on IL statutues), as well as (2) the fbi code of the crime which can be used to 
identify if a crime is a violent crime, sexual assault,burglary, act of vandalism, or prostitution.

Weather is categorized based on mean temperature and existince of bad weather conditions of: fog, rain, 
snow, hail, thunder, and tornado. A "good weather" day has a mean temperature above 50 degrees with no
bad weather conditions.  Any other day is a "bad weather" day.

Weather data is ingested as a sequence file into HDFS by the Java program weatherIngest. 
Crime data is stored in HDFS in csv format and then processed by Pig.

Pig scripts are used to pre-compute the crime reports.  Crime data is loaded into Pig where the date is 
formatted to match weather data and a weather station is assigned (725340 = MDW).  Next, crime and weather
data are joined together into a single table.  Lastly, the joined data is processed to identify good weather
and types of crime.  This final table is grouped by year and loaded into HBase.

The main website uses a perl script to pull a crime report based on year.  The Hbase table is queried to find
the key that matches the input year and returns the number of crime incidents for each type of crime that
occurred in good and bad weather.

A separate website is used to manually load new crime into the Hbase table ramonlrodriguez-current-crime. A
form is used to submit data, which calls a perl script to send the data to a kafka messsage queue. The Java 
program crimeTopology is used to manage loading new data contained in the messages into the Hbase table.

Issues with Project
(1) Due to cluster stability issues, I was unable to create a kafka message topic or hbase table to process 
the new data.

(2) The design and interface of my application is poor.  I do not have any experience with HTML or web 
development.  Similar to issue (1), I was unable to debug the design and interface due to cluster
stability issues.

Additional Comments
All relevant files are located on the cluster and in this git.  I have attempted to provide sufficient proof
of my understanding of Big Data architecture in the README such that I will not be penalized for cluster
issues.

