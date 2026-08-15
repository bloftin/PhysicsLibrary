#!/usr/bin/perl

# Parse the access log to get response times that are logged and run stats, find slow stuff
# Need to install Apache::Log::Parser to use

# run as sudo due to needed to access log and pass the log file as argument

use strict;

use Apache::Log::Parser;
use Data::Dumper qw(Dumper); # Import the Dumper() subroutine

sub main {
    # LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" **%T/%D**" plformat
    my @customized_fields = qw( rhost logname user datetime request status bytes referer agent request_duration);

    #my $parser = Apache::Log::Parser->new( fast => [[qw(rhost logname user datetime request status bytes referer agent request_duration )], 'combined'] );
    my $strict_parser = Apache::Log::Parser->new( strict => [
    ["\t", \@customized_fields, sub{my $x=shift;defined($x->{rhost}) and defined($x->{referer}) }], # TABs as separator
    [" ", \@customized_fields, sub{my $x=shift;defined($x->{rhost}) and defined($x->{referer}) }],
    'combined',
    'common',
    'vhost_common',
    ]);
    #my $logline = "92.205.147.238 - - [16/Feb/2025:16:45:29 +0000] \"GET / HTTP/1.1\" 200 23684 \"http://physicslibrary.org\" \"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.5672.93 Safari/537.36\" **0/19923**";
     while (my $line = <>) {
        chomp $line;
        my $log = $strict_parser->parse($line);
        #print Dumper($log);
        my @duration = split /[*,\s\/]+/, $log->{request_duration};
        my $sec = @duration[1];
        my $us  = @duration[2];
        my $duration = $us/1E6;
        if($duration > 1) {
            print Dumper($log,$duration);

        }
        
        #last;
     }

    
}

main();