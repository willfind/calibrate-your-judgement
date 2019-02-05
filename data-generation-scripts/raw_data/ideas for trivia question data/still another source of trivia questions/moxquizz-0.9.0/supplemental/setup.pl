#! /usr/bin/env perl

##
### setup.pl -- setup some variables in your config and moxtools
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

local $conffile = chooseconfig('moxquizz.conf', 'provided eggdrop config');
local $toolfile = chooseconfig('moxtools.tcl', 'MoxTools file');
local $rcfile   = chooseconfig('moxquizz.rc', 'MoxQuizz config file');

if (!(-f $conffile & -f $toolfile & -f $rcfile)) {
    die "Cannot find all configfiles.  Check for $conffile, $toolfile and $rcfile.";
}



###########################################################################

## Mangle eggdrop configuration first

print "Setting up eggdrop.\n";

$content = suckfile($conffile);
study $content;

$admin = readval("Enter botadmin:", 1);
$owner = readval("Enter botowner:", 1);
$botnick = readval("Enter botnick:", 1);
$server = readval("Enter IRC-Server:", 1);
$port = readval("Enter telnetport:", 0);


print "Eggdrop setup finished, changing config ... ";

if ($admin ne "") { $content =~ s/set admin \".*\"/set admin \"$admin\"/; }
if ($owner ne "") { $content =~ s/set owner \".*\"/set owner \"$owner\"/; }
if ($botnick ne "") { $content =~ s/set nick \".*\"/set nick \"$botnick\"/; }
if ($server ne "") {
    $content =~ s/set network \".*\"/set network \"$server\"/;
    $content =~ s/^(\s+)[a-zA-Z0-9.]+:([0-9]+)$/$1$server:$2/m;
}

if ($port ne "") { $content =~ s/listen [0-9]+ all/listen $port all/; }

print "writing ... ";

#print $content;

open FILE, ">$conffile";
print FILE $content;
close FILE;

print "done.\n";

###########################################################################

## Setting up quizrelated variables (moxquizz.rc)

print "Setting up quiz.\n";

$content = suckfile($rcfile);

$channel = readval("Enter quizchannel:", 1);
$qset = readval("Enter questionset (e.g. de = german, en = english):", 0);
$qlang = readval("Enter language (e.g. de = german, en = english):", 0);
$overrun = yesno("Enable overrun-protection (y/n)?");

print "Quiz setup finished, changing config ... ";

if ($channel ne "") { $content =~ s/(quizchannel\s+=).*$/$1 $channel/m; }
if ($qset ne "") { $content =~ s/(questionset\s+=).*$/$1 $qset/m; }
if ($qlang ne "") { $content =~ s/(language\s+=).*$/$1 $qlang/m; }
if ($overrun == 1) {
    $content =~ s/(overrun_protection\s+=).*$/$1 yes/m;
} else {
    $content =~ s/(overrun_protection\s+=).*$/$1 no/m;
}

print "writing ... ";

open FILE, ">$rcfile";
print FILE $content;
close FILE;

print "done.\n";


###########################################################################

## Mangling moxtools

print "Now asking values for moxtools (nickserv, vhost, badwords, antispam file)\n";
print "All values can safely be untouched.\n";

$content = suckfile($toolfile);
study $content;

local $nickmask, $nickaddr, $nickpass, 
    $vhostname, $vhostlogin, $vhostpass, $usevhost,
    $enablejumpq;

##
## Nickserv identification
##
if (yesno("Use nickserv identification?")) {

    $nickmask = readval("Enter exact hostmask for nickserv:", 0);
    $nickaddr = readval("Some ircnets (e.g. DALNet) use special addresses for the nickserv who\n"
                        . "receives the identification.  Enter exact address for nickserv used\n"
                        . "to send identification to (defaults to \"nickserv\"):", 0);
    $nickpass = readval("Enter Botpassword for nickserv:", 0);
}

##
## VHost
##
$content =~ /variable usevhost\s+([10])/;
local $vhostinuse = $1;
if (yesno("Use VHost?")) {
    if (!$vhostinuse) { $usevhost = "1"; }
    $vhostname = readval("Enter your vhostname:", 0);
    $vhostlogin = readval("Enter your vhost login:", 0);
    $vhostpass = readval("Enter your vhost password:", 0);

} else {
    if ($vhostinuse) { $usevhost = "0"; }
}


##
## Bad word detection
##
$content =~ /variable usebadwords\s+([10])/;
local $badwordsinuse = $1;
if (yesno("Use badword detection?")) {
    if (!$badwordsinuse) { $usebadwords = "1"; }
} else {
    if ($badwordsinuse) { $usebadwords = "0"; }
}

##
## Antispam file
##
$useantispam = yesno("Enable !antispam command (sends intl/antispam.txt, DALNet specific):");


##
## .!jump for users with flag Q
##
$content =~ /variable jumpQ\s+([10])/;
local $jumpison = $1;
if (yesno("Enable .!jump for users with flag Q?")) {
    if (!$jumpison) { $enablejumpq = "1"; }
} else {
    if ($jumpison) { $enablejumpq = "0"; }
}


print "Moxtool setup finished, changing config ... ";

if ($nickmask ne "") { $content =~ s/(variable nickservmask\s+)\".*\"/$1\"$nickmask\"/; }
if ($nickaddr ne "") { $content =~ s/(variable nickservaddr\s+)\".*\"/$1\"$nickaddr\"/; }
if ($nickpass ne "") { $content =~ s/(variable nickservpass\s+)\".*\"/$1\"$nickpass\"/; }

if ($usevhost ne "") { $content =~ s/(variable usevhost\s+).*/$1$usevhost/; }
if ($vhostname ne "") { $content =~ s/(variable vhostname\s+)\".*\"/$1\"$vhostname\"/; }
if ($vhostlogin ne "") { $content =~ s/(variable vhostlogin\s+)\".*\"/$1\"$vhostlogin\"/; }
if ($vhostpass ne "") { $content =~ s/(variable vhostpass\s+)\".*\"/$1\"$vhostpass\"/; }

if ($usebadwords ne "") { $content =~ s/(variable usebadwords\s+).*/$1$usebadwords/;}
if ($enablejumpq ne "") { $content =~ s/(variable jumpQ\s+).*/$1$enablejumpq/;}

if ($useantispam) { $content =~ s/(variable useantispam\s+).*/$1$useantispam/;}

if ($nickmask ne "" || $nickaddr ne "" || $nickpass ne ""
    || $vhostname ne "" || $vhostlogin ne "" || $vhostpass ne ""
    || $usevhost ne "" || $usebadwords ne "" || $useantispam) {
    print "writing ... ";

    open FILE, ">$toolfile";
    print FILE $content;
    close FILE;
    
    print "done.\n";
} else {
    print "no changes, done.\n";
}

###########################################################################
###########################################################################

###########################################################################
#
# read a value from STDIN.  $mode = 0  means optional, 1 means required
#
###########################################################################

sub readval ($$) {
    my ($prompt, $mode) = @_;
    local $value;

    if ($mode == 0) {
	print "(Optional)";
    } else {
	print "(Required)";
    }
    
    print " $prompt ";
    $value = <STDIN>;
    chomp $value;

    if ($value eq "" && $mode == 1) {
	print "You left a required value untouched!\n";
    }

    return $value;
}

###########################################################################
#
# ask a yes no question
#
###########################################################################

sub yesno ($) {
    my $prompt = shift;
    local $answer;
    
    print "$prompt ";
    $answer = <STDIN>;
    while ($answer !~ /^(y|n)/i) {
	print "Please answer yes or no.\n";
	print "$prompt ";
	$answer = <STDIN>;
	chomp $answer;
    }

    if ($answer =~ /^y/i) {
	return 1;
    } else {
	return 0;
    }
}


###########################################################################
#
# read a whole file
#
###########################################################################

sub suckfile($) {
    local $file = shift;
    local $tmpsep = $/;
    undef $/;

    open FILE, "$file";
    $content = <FILE>;
    close FILE;
    $/ = $tmpsep;

    return $content;
}


###########################################################################
#
# Find a configuration file
#
###########################################################################

sub chooseconfig($$) {
    local $file = shift;
    local $desc = shift;

    print "Looking for $desc ($file) ...";

    while (! -f $file) {
        print " not found.\n";
        print "Please enter filename for $desc: ";
        $file = <STDIN>;
        chomp($file);
        print "Looking for $file ...";
    }

    print " found.\n";
    return $file;
}
