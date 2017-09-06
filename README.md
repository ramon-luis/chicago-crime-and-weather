# Chicago Crime and Weather

Chicago Crime and Weather is a big data web application that analyzes the relationship between weather and violent crime in Chicago daily from 2001-2016.  The application uses a lambda architecture to process large amounts of data in a scalable form: data from multiple sources is serialized and grouped together into a single, fact-based distrubuted data table in batch processing with pre-computed common queries while a separate speed layer handles new data that has not yet been batch processed.

Much of the code was adapted from code provided in MPCS 53013 Big Data at the University of Chicago.  The emphasis of project the was on architecture & functionality, not elegance... and it shows in the code.  Apologies in advance.

## What's Here

* `crimeTopology/` streams CSV crime data into HDFS using Kafka
* `html/` handles the (admittedly crude) HTML and CSS that for the front-end
* `perl/` runs scripts to query data or add new data (to speed layer)
* `pig/` combines weather and crime into single HBase table that is stored in HDFS
* `weatherIngest/` serializes & stores weather data in HDFS as a sequence file

## How It Works
Crime is categorized based on tags within the Chicago data set: CPD records (1) if a crime is an arrest or domestic crime (based on IL statutues), as well as (2) the FBI code of the crime which can be used to identify if a crime is a violent crime, sexual assault,burglary, act of vandalism, or prostitution.

Weather is categorized based on mean temperature and existince of bad weather conditions of: fog, rain, snow, hail, thunder, and tornado. A "good weather" day has a mean temperature above 50 degrees with no bad weather conditions.  Any other day is a "bad weather" day.

Weather data is ingested as a sequence file into HDFS by the Java program weatherIngest. 
Crime data is stored in HDFS in csv format and then processed by Pig.

Pig scripts are used to pre-compute the crime reports.  Crime data is loaded into Pig where the date is formatted to match weather data and a weather station is assigned (725340 = MDW).  Next, crime and weather data are joined together into a single table.  Lastly, the joined data is processed to identify good weather and types of crime.  This final table is grouped by year and loaded into HBase.

The main website uses a perl script to pull a crime report based on year.  The Hbase table is queried to find the key that matches the input year and returns the number of crime incidents for each type of crime that occurred in good and bad weather.

A separate website is used to manually load new crime into the Hbase table ramonlrodriguez-current-crime. A form is used to submit data, which calls a perl script to send the data to a kafka messsage queue. The Java program crimeTopology is used to manage loading new data contained in the messages into the Hbase table.

## Availability

This project was originally hosted on a Google cloud server by The University of Chicagom which is no longer available.  This is somewhat merciful as the front end was far from pretty.

Source data is available at:
* weather: ftp://ftp.ncdc.noaa.gov/pub/data/gsod/
* crime: https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-present/ijzp-q8t2

## Installing / Deploying

Feel free to use these files as a resource, but I'd advise against attempting to install/deploy them directly.  Setting up a working big data environment can be painful.  It is often advised to use a virtual machine that is already configured.  In other words, I'm not certain the current file architecture would easily transfer and it's probably not worth the pain of trying :)

## Built With

* Java - Used for data ingestion
* [Apache Maven](https://maven.apache.org/) - Dependency Management
* [Apache Hadoop HDFS file system](http://hadoop.apache.org/) - Used to store data
* [Apache Kafka](https://kafka.apache.org/) - Used for data streaming
* [Apache Storm](http://storm.apache.org/) - Used for processing streams of data
* [Apache Thrift](http://thrift.apache.org/) - Used to serialize data
* [Apache Pig](http://pig.apache.org/) - Used to analyze data
* [Apache HBase](http://hbase.apache.org/) - Used to store data
* [Perl](https://www.perl.org/) - Used to query data and add data to speed layer
* HTML & CSS- Used for front-end
* [Google Cloud](https://cloud.google.com/) - Used to host data

## Author

* [**Ramon-Luis**](https://github.com/ramon-luis)

## Acknowledgments

* Thank you to Michael Spertus at the University of Chicago for providing the base code & knowledge about big data systems.