#!/usr/bin/perl -w
# Program: cass_sample.pl
# Note: includes bug fixes for Net::Async::CassandraCQL 0.11 version

use strict;
use warnings;
use 5.10.0;
use FindBin;

use Scalar::Util qw(
        blessed
    );
use Try::Tiny;

use Kafka::Connection;
use Kafka::Producer;

use Data::Dumper;
use CGI qw/:standard/, 'Vars';


my $year = param('year');
if(!$year) {
    exit;
}
my $isGoodWeather = param('isGoodWeather') ? 1 : 0;
my $isArrest = param('isArrest') ? 1 : 0;
my $isDomestic = param('isDomestic') ? 1 : 0;
my $isViolentCrime = param('isViolentCrime') ? 1 : 0;
my $isSexualAssault = param('isSexualAssault') ? 1 : 0;
my $isBurglary = param('isBurglary') ? 1 : 0;
my $isVandalism = param('isVandalism') ? 1 : 0;
my $isProstitution = param('isProstitution') ? 1 : 0;

my ( $connection, $producer );
try {
    #-- Connection
    $connection = Kafka::Connection->new( host => 'localhost', port => 6667 );
 
    #-- Producer
    $producer = Kafka::Producer->new( Connection => $connection );
    # Only put in the elements we care about

    my $message = "<new_crime_occurence><year>K".param("year")."</year><crime>";
    if($isGoodWeather) { $message .= "isGoodWeather "; }
    if($isArrest) { $message .= "isArrest "; }
    if($isDomestic) { $message .= "isDomestic "; }
    if($isViolentCrime) { $message .= "isViolentCrime "; }
    if($isSexualAssault) { $message .= "isSexualAssault "; }
    if($isBurglary) { $message .= "isBurglary "; }
    if($isVandalism) { $message .= "isVandalism "; }
    if($isProstitution) { $message .= "isProstitution "; }
    
    $message .= "</crime></new_crime_occurence>";

    # Sending a single message
    my $response = $producer->send(
	'ramonlrodriguez-crime-events',         # topic		# CREATE TOPIC ON KAFKA
	0,                                 	# partition
	$message                           	# message
        );
} catch {
    if ( blessed( $_ ) && $_->isa( 'Kafka::Exception' ) ) {
	warn 'Error: (', $_->code, ') ',  $_->message, "\n";
	exit;
    } else {
	die $_;
    }
};

# Closes the producer and cleans up
undef $producer;
undef $connection;

# UPDATE THIS SECTION

print header, start_html(-title=>'Submit crime',-head=>Link({-rel=>'stylesheet',-href=>'/table.css',
-type=>'text/css'}));

print table({-class=>'CSS_Table_Example', -style=>'width:80%;'},
            caption('Crime report submitted'),
	    Tr([th(["is good weather?", "is arrest?", "is domestic?", "is violent crime?", "is sexual assault?", 
		"is burglary?", "is vandalism?", "is prostitution?"]),
	        td([$isGoodWeather, $isArrest, $isDomestic, $isViolentCrime, $isSexualAssault, 
		$isBurglary, $isVandalism, $isProstitution])]));

#print $protocol->getTransport->getBuffer;
print end_html;

