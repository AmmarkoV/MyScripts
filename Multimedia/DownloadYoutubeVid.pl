#!/usr/bin/perl

use strict;
use warnings;

#
##  Calomel.org  ,:,  Download Youtube videos and music using wget
##    Script Name : youtube_get_video.pl
##    Version     : 0.30
##    Valid from  : December 2012
##    URL Page    : https://calomel.org/youtube_wget.html
##    OS Support  : Linux, Mac OSX, OpenBSD, FreeBSD or any system with perl
#                `:`
## Two arguments
##    $1 Youtube URL from the browser
##    $2 prefix to the file name of the video (optional)
#

## collect the URL from the command line argument
my $url = $ARGV[0] or die "\nError: You need to specify a YouTube URL\n\n";

## declare the user defined file name prefix 
my $prefix = defined($ARGV[1]) ? $ARGV[1] : "";

## download the html code from the youtube page
my $html = `wget -Ncq -e "convert-links=off" --keep-session-cookies --save-cookies /dev/null --no-check-certificate "$url" -O-`  or die  "\nThere was a problem downloading the HTML file.\n\n";

## collect the title of the page to use as the file name
my ($title) = $html =~ m/<title>(.+)<\/title>/si;
$title =~ s/[^\w\d]+/_/g;
$title =~ s/_youtube//ig;
$title =~ s/^_//ig;
$title = lc ($title);

## collect the URL of the video
my ($download) = $html =~ /"url_encoded_fmt_stream_map"([\s\S]+?)\,/ig;

## clean up the url by translating unicode and removing unwanted strings
$download =~ s/\:\ \"//;
$download =~ s/%3A/:/g;
$download =~ s/%2F/\//g;
$download =~ s/%3F/\?/g;
$download =~ s/%3D/\=/g;
$download =~ s/%252C/%2C/g;
$download =~ s/%26/\&/g;
$download =~ s/sig=/signature=/g;
$download =~ s/\\u0026/\&/g;
$download =~ s/(type=[^&]+)//g;
$download =~ s/(fallback_host=[^&]+)//g;
$download =~ s/(quality=[^&]+)//g;

## collect the url and signature since the html page randomizes the order
my ($signature) = $download =~ /(signature=[^&]+)/;
my ($youtubeurl) = $download =~ /(http.+)/;
$youtubeurl =~ s/&signature.+$//;

## combine the url and signature in order to use in wget
$download = "$youtubeurl\&$signature";

## a bit more cleanup
$download =~ s/&+/&/g;
$download =~ s/&itag=\d+&signature=/&signature=/g;

## print the file name of the video collected from the web page title for us to see on the cli
print "\n Download: $prefix$title.webm\n\n";

## Download the file using wget and background the wget process
system("wget -Ncq -e \"convert-links=off\" --load-cookies /dev/null --tries=50 --timeout=45 --no-check-certificate \"$download\" -O $prefix$title.webm ");

#### EOF #####