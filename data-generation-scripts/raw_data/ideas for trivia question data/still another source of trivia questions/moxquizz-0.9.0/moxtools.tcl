### moxtools.tcl -- some tools for eggdrop
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

set version_moxtools "1.2"

###########################################################################
#
# Announcement : notice $announcement to each user joining a channel the
#                bot is on.
#
###########################################################################

# settings
variable announcement ""

# bindings
bind join - * moxtool_announce
bind dcc m !announce moxtool_set_announce

## notification when a user joins in
proc moxtool_announce {nick host handle channel} {
    global announcement
    if {$announcement != ""} {
	puthelp "NOTICE $nick :$announcement"
    }
}


## show module status
proc moxtool_set_announce {handle idx arg} {
    global announcement
    set arg [string trim $arg]
    if {$arg == ""} {
	putdcc $idx "Current announcement is: \"$announcement\"."
    } elseif {$arg == "-"} {
	set announcement ""
	putdcc $idx "Announcement cleared."
    } else {
	set announcement $arg
	putdcc $idx "Announcement set to: \"$announcement\"."
    }
}

###########################################################################
#
#  Logfile for each channel
#
###########################################################################

bind join - * moxtool_autolog
bind evnt - rehash moxtool_reopenlogs

variable logmodes "kjps"

proc moxtool_autolog {nick host handle channel} {
    global botnick logmodes
    if {$nick == $botnick} {
	set channel [string tolower $channel]
	foreach file [logfile] {
	    if {[lindex $file 1] == $channel} {
		## side exit, BAD STYLE!
		return 0
	    }
	}

	## logfile -> {modes chan filename}
	logfile $logmodes $channel "logs/$channel.log"
    }
}

proc moxtool_reopenlogs {type} {
    global logmodes
    foreach chan [channels] {
	if {[botonchan $chan]} {
	    logfile $logmodes $chan "logs/$chan.log"
	}
    }
}


###########################################################################
#
# nickserv identification
#
###########################################################################

variable nickservpass "botpassword"
variable nickservtext "This nick"
variable nickservmask "mask"
variable nickservaddr "nickserv"

bind notc - "*$nickservtext*" moxtool_nickserv_identify
bind dcc P !identify moxtool_nickserv_identify_manually

proc moxtool_nickserv_identify_manually {handle idx arg} {
    global nickservaddr nickservpass
    puthelp "PRIVMSG $nickservaddr :identify $nickservpass"
}


proc moxtool_nickserv_identify {nick mask handle text {dest ""}} {
    global nickservpass nickservmask nickservaddr
    global botnick

    if {$dest == ""} { set dest $botnick }

    if {$dest == $botnick && [string tolower $mask] == [string tolower $nickservmask] && $nickservpass != ""} {
	puthelp "PRIVMSG $nickservaddr :identify $nickservpass"
    }
}



###########################################################################
#
# VHost registration (brought by ManInBlack)
#
###########################################################################

variable usevhost   0
variable vhostname  "dummyhost.somewhere.ode"
variable vhostlogin "dummylogin"
variable vhostpass  "dummypass"

if ($usevhost) {
    if {![info exists init-server]} {
	set init-server ""
    }

    # on irc.euirc.net uncomment and use:

    #set init-server "
    #   ${init-server}
    #   putserv \"PRIVMSG serv: vhost $vhostlogin $vhostpass\"
    #"


    set init-server "
        ${init-server}
	putserv \"vhost $vhostlogin $vhostpass\"
	putserv \"sethost $vhostname\"
    "
}

###########################################################################
#
# Bad words
#
###########################################################################

variable usebadwords 0
variable badwords [list "f\[iu*\]ck" "bitch" "whore"\
                       "cunt" "suck.*dick" "dickhead" "faggot"]

if ($usebadwords) {

    variable bw_kicked
    variable bw_repeaters_banminutes 30

    bind pubm - * moxtool_badword

    proc moxtool_badword {nick host handle channel text} {
	global badwords bw_kicked botnick
	global bw_repeaters_banminutes
	variable cleantime [expr $bw_repeaters_banminutes * 60]
	variable mask [maskhost $host]

	if {![botisop $channel]} {return 0}

	if {[regexp -nocase "([join $badwords, "|"])" $text]} {

	    if {[info exists bw_kicked($mask)] && [expr [unixtime] - $bw_kicked($mask)] < $cleantime} {
		# ban repeaters
		newchanban $channel $mask $botnick "Too many bad words." $bw_repeaters_banminutes
		flushmode $channel
		putkick $channel $nick [format "Stay out and calm down for %d minutes." $bw_repeaters_banminutes]
		unset bw_kicked($mask)
	    } else {
		# kick the first time
		putkick $channel $nick "Bad words are not allowed here.  You've been warned!"
		set bw_kicked($mask) [unixtime]
	    }
	}
    }
}


###########################################################################
#
# Antispam (dalnet specific)
#
###########################################################################

variable useantispam 0
variable antispamfile "moxquizz/intl/antispam.txt"

# [pending] ensure filesys module loaded
# [pending] enable intl for antispam

if ($useantispam) {

    bind pub - !antispam moxtool_send_antispam_note

    ## send the antispam file
    proc moxtool_send_antispam_note {nick host handle channel arg} {
        global antispamfile

        if {$antispamfile != ""} {
            if {[info commands dccsend] == ""} {
                mxirc_notc $nick "Sorry, module filesys is not loaded, cannot send antispam howto."
            } else {
                set result [dccsend $antispamfile $nick]
                switch -exact -- $result {
                    0 {
                        mxirc_notc $nick "DCC SEND antispam howto: will send now"
                        mx_log  "--- $handle DCC SEND antispam howto: success"
                    }
                    1 {
                        mxirc_notc $nick "DCC SEND antispam howto: dcc table full, try again later"
                        mx_log  "--- $handle DCC SEND antispam howto: dcc table full"
                    }
                    2 {
                        mxirc_notc $nick "DCC SEND antispam howto: can't open socket"
                        mx_log  "--- $handle DCC SEND antispam howto: can't open socket"
                    }
                    3 {
                        mxirc_notc $nick "DCC SEND antispam howto: file doesn't exist"
                        mx_log  "--- $handle DCC SEND antispam howto: file doesn't exist"
                    }
                    4 {
                        mxirc_notc $nick "DCC SEND antispam howto: queued for later transfer"
                        mx_log  "--- $handle DCC SEND antispam howto: queued for later transfer"
                    }
                }
            }
        }
        return 1
    }
}


###########################################################################
#
# .!jump for users with Q flag
#
###########################################################################

variable jumpQ 0

if ($jumpQ) {

    bind dcc Q !jump moxtool_jump
    proc moxtool_jump {handle idx arg} {
        set arg [string trim $arg]
        if {$arg == ""} {
            mx_log "--- JUMP requested by $handle to next server in list"
            mxirc_dcc $idx "Jumping to next server in list"
            mxirc_dcc $idx "hop .."
            jump
        } else {
            mx_log "--- JUMP requested by $handle to $arg"
            mxirc_dcc $idx "Jumping to server $arg"
            mxirc_dcc $idx "hop .."
            jump $arg
        }
        return 1
    }
}
