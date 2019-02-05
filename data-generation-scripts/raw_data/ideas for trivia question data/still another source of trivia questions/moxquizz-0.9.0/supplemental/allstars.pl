#!/usr/bin/perl

##
### allstars.pl -- prettyprint the allstars table for MoxQuizz
##
### Author: Moxon <moxon@meta-x.de>  (AKA Sascha Lüdecke)
##
### Copyright (C) 2000 Moxon AKA Sascha Lüdecke
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##

my $allstarsfile = 'rankallstars.data';
my $format = "TXT";
my $monthly = 0;
my $currentmonthonly = 0;

my $monthlybase = 'allstars';

while ($_ = shift @ARGV) {
    # options first
    /--file/ && do { $allstarsfile = shift @ARGV;
		     print STDERR "Reading from $allstarsfile\n";
		     next };

    /--html/ && do { $format = "HTML";
		     next };

    /--xml/ && do { $format = "XML";
		    next };

    /--text/ && do { $format = "TXT";
		     next };

    /--monthly-prefix/ && do { $prefix = shift @ARGV;
			       $monthlybase = $prefix . "." . $monthlybase;
			       next };

    /--monthly/ && do { $monthly = 1;
			next };

    /--current-month-only/ && do { $currentmonthonly = 1;
                                   next };

    # commands last
    /--list/ && do {  list_entries();
		      exit 0 };
    /--table/ && do { calc_table();
		      exit 0 };
    /--help/ && do { print_help();
		     exit 0 };
    print STDERR "Unknown parameter: \"$_\"\n";
}

print STDERR "No command found, use --help to get help.\n";

exit 1;


###########################################################################
#
# list all entries
#
###########################################################################

## SAMPLE
##
##   # this file records all won games.  Format is:
##   #!ignore SAMPLENICK
##   # time,  duration, num of questions, winscore, nick, hostmask
##   964263720 371 : 41 15 -- MindMaster *!whistle@*.blowup.net
##

sub list_entries () {
    if (open FILE, "$allstarsfile") {
	while (<FILE>) {
	    chomp;
	    # skip comments
	    if ($_ !~ /^\#.*/) {
		$_ =~ /(\d+) (\d+) : (\d+) (\d+) -- ([^ ]+) ([^ ]+)/;
		print localtime($1) . " $1  $2\t$3\t$4  $5  $6\n";
	    }
	}
	close FILE;
    } else {
	die "Could not open $allstarsfile.";
    }
}


###########################################################################
#
# calculate table(s in case of monthly tables)
#
###########################################################################

sub calc_table () {
    local %games, %score, %durations, %ignores;
    local $lastmonth = "";
    $| = 1;
    # read the file
    if (open FILE, "$allstarsfile") {
	while (<FILE>) {
	    chomp;
            if ($_ =~ /^\#!ignore (.+)/) {
                $ignores{lc $1} = 1;
            }
	    elsif ($_ !~ /^\#.*/ && $_ !~ /^\s*$/ ) {
		$_ =~ /(\d+) (\d+) : (\d+) (\d+) -- ([^ ]+) ([^ ]+)/;
		($when, $duration, $sumscore, $score, $name, $host) = ($1, $2, $3, $4, $5, $6);

                if (!exists $ignores{lc $name}) {
                    if ($lastmonth eq "") {
                        $lastmonth = getYearMonth($when);
                    }

                    if ($monthly && getYearMonth($when) ne $lastmonth) {
                        if (!$currentmonthonly) {
                            print_table();
                        } else {
                            print STDERR "Skipping $lastmonth.\n"
                            }
                        $lastmonth = getYearMonth($when);
                        undef %games;
                        undef %durations;
                        undef %score;
                    }

                    $games{$name} += 1;
                    $durations{$name} += $duration;
                    $score{$name} += 10 * $sumscore / ( log10($score) * $duration );
                }
	    }
	}
	close FILE;
	print_table();
    } else {
	die "Could not open $allstarsfile.";
    }

}

###########################################################################
#
# print a table -- assumes %games, %score and %duration to be filled
#
###########################################################################

sub print_table () {

    if ($monthly) {
	print STDERR "Writing month: $monthlybase.$lastmonth\n";
	open (STDOUT,  ">$monthlybase.$lastmonth");
    }

    local $numignores = scalar %ignores;

    # set page length so show everything on a single page
    $= = 1_000_000;
    $- = 0;

    # set format
    $^ = $format . "HEAD";
    $~ = $format . "BODY";

    # show the table
    $pos = 1;
    foreach $n (sort {$score{$b} <=> $score{$a}} keys %games) {

	write;
	$pos += 1;
	$games{"Summary"} += $games{$n};
	$durations{"Summary"} += $durations{$n};
	$score{"Summary"} += $score{$n};
    }

    # show some summaries
    $~ = $format . "SUMS";
    $pos = "";
    $n = "Summary";
    write;


    # print footer
    $~ = $format . "FOOT";
    write;

    if ($monthly) {
	close (STDOUT);
    }
}

###########################################################################
#
# print a help text
#
###########################################################################

sub print_help () {
    print <<"HELP";
$0 -- prettyprint the allstars table from MoxQuizz

Usage:
    $0 [parameter] command

Commands:
	--list      Just print all entries with human understandable dates.
	--table     Prettyprint the table.
	--help      Print this text.

Paramter:
	--file <f>  Use <f> instead of \'$allstarsfile\' for input.
	--monthly   Calculate allstars per month and write to files like
	            $monthlybase.2001-01
	--monthly-prefix <prefix>
                    Prepend <prefix> to above filenames

     Output formats in case of --table:

	--html      Generated HTML output
	--xml       Generate XML output
	--text      Generate Text output (this is the default)

Example:
    allstars.pl --file rankallstars --monthly --monthly-prefix en --xml --table

    Generates XML allstars table from file 'rankallstars' on a monthly base
    into files named alike en.$monthlybase.2001-01

HELP
}


###########################################################################
#
# help routines like log10 and getMonth
#
###########################################################################

sub log10 ($) {
    my $n = shift;
    return log($n)/log(10);
}


sub getYearMonth($) {
    my $secs = shift;
    ($_, $_, $_, $_, $month, $year, $_, $_, $_) = localtime $secs;

    return sprintf("%d-%02d", 1900 + $year, $month + 1);
}

###########################################################################
#
# output formats
#
# To get a new format, give it a tag (e.g. XML) and write formats named
# <TAG>HEAD, <TAG>BODY, <TAG>SUMS, <TAG>FOOT
#
###########################################################################

###########################################################################
# TXT
###########################################################################

format TXTHEAD =
Allstars table
--------------

Ignored: @#####
$numignores

Rank |       Name       |  Games |     Score | Avg score | Avg duration
-----+------------------+--------+-----------+-----------+-------------
.


format TXTBODY =
@>>> | @<<<<<<<<<<<<<<< | @##### | @####.### |   @##.### | @#######.###
$pos, $n, $games{$n}, $score{$n}, $score{$n}/$games{$n}, $durations{$n}/$games{$n}
.


format TXTSUMS =
-----+------------------+--------+-----------+-----------+-------------
@>>> | @<<<<<<<<<<<<<<< | @##### | @####.### |   @##.### | @#######.###
$pos, $n, $games{$n}, $score{$n}, $score{$n}/$games{$n},  $durations{$n}/$games{$n}
.


format TXTFOOT =
.

###########################################################################
# HTML
###########################################################################

format HTMLHEAD =
<table align="CENTER" border="1" cellspacing="0"><tr><td>
<table align="CENTER" cellspacing="0" border="0" cellpadding="2">
<tr><td align="RIGHT" colspan="8"><font size="-1">Ignored Nicks: @####</font></td></tr>
$numignores
<tr bgcolor="#EAEAEA"><th>Rank&nbsp;</th> <th align="LEFT">Name</th> <th>Games</th>
<th>&nbsp;</th> <th colspan="2">Score</th> <th>&nbsp;Avg score&nbsp;</th> <th>&nbsp;Avg duration&nbsp;</th></tr>
.

format HTMLBODY =
<tr><td align="CENTER"> @>>> </td> <td> @<<<<<<<<<<<<<<<<<<<< </td> <td align="RIGHT">@######</td> <td>&nbsp;</td> <td align="RIGHT">@#####.###</td> <td>&nbsp;</td> <td align="CENTER">@##.###</td> <td align="CENTER">@#####.###</td></tr>
$pos, $n, $games{$n}, $score{$n}, $score{$n}/$games{$n},  $durations{$n}/$games{$n}
.

format HTMLSUMS =
<tr bgcolor="#F0F5F5"><td align="CENTER"> @>>> </td> <td> @<<<<<<<<<<<<<<<<<<<< </td> <td align="RIGHT">@######</td> <td>&nbsp;</td> <td align="RIGHT">@#####.###</td> <td>&nbsp;</td> <td align="CENTER">@##.###</td> <td align="CENTER">@#####.###</td></tr>
$pos, $n, $games{$n}, $score{$n}, $score{$n}/$games{$n},  $durations{$n}/$games{$n}
.


format HTMLFOOT =
</table>
</td></tr></table>
<div align="CENTER">This table was created on <b>@<<<<<<<<<<<<<<<<<<<<<<< </b>.</div>
"" . localtime(time)
.


###########################################################################
# XML
###########################################################################

format XMLHEAD =
<?xml version="1.0" encoding="UTF-8"?>
<allstars>
  <ignored>@####</ignored>
$numignores
.

format XMLBODY =
  <rank>
    <pos>@>>>></pos>
$pos
    <name>@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< </name>
$n
    <games>@#####</games>
$games{$n}
    <score>@###.###</score>
$score{$n}
    <avgscore>@###.###</avgscore>
$score{$n}/$games{$n}
    <avgduration>@###.###</avgduration>
$durations{$n}/$games{$n}
  </rank>
.

format XMLSUMS =
  <totals>
    <pos>@>>>></pos>
$pos
    <name>@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< </name>
$n
    <games>@#####</games>
$games{$n}
    <score>@###.####</score>
$score{$n}
    <avgscore>@###.####</avgscore>
$score{$n}/$games{$n}
    <avgduration>@###.####</avgduration>
$durations{$n}/$games{$n}
  </totals>
.

format XMLFOOT =
<created>@>>>>>>>>>>>>>>>>>>>>>>>>>>></created>
"" . localtime(time)
</allstars>
.
