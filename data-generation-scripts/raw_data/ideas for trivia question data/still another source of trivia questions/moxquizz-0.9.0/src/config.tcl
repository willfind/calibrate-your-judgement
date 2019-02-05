### This file is part of MoxQuizz -- a quiz/triviabot for eggdrops 1.6.9+
##
### Author: Moxon <moxon@meta-x.de> (AKA Sascha Lüdecke)
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

### Description:
##
## Reading and writing of configuration files
##

namespace eval ::moxquizz {


    ###########################################################################
    #
    # Configuration file reading and writing, setup
    #
    ###########################################################################

    # public interface to set the configuration variables from the config file
    proc cfg_set {handle idx arg} {
        variable quizconf
        set key ""
        set value ""
        set success 0

        # collapse whitespace
        regsub -all " +" $arg " " arg

        # extract key and value
        set list [split $arg]
        for {set i 0} {$i < [llength $list]} {incr i 2} {
            set key [string tolower [lindex $list $i]]
            set value [lindex $list [expr 1 + $i]]

            # first lets see if the key exists
            set keylist [array names quizconf "*$key*"]
            if {[llength $keylist] == 1} { set key [lindex $keylist 0] }

            if {[info exists quizconf($key)]} {
                if {$value == ""} {
                    irc_dcc $idx "$key = $quizconf($key)"
                } else {
                    log "--- config tried $key = $value"
                    set success 0
                    set oldvalue $quizconf($key)
                    switch -regexp $oldvalue {
                        "^(yes|no)" {
                            if {[regexp "^(yes|no)$" $value]} {
                                set quizconf($key) $value
                                set success 1
                            }
                        }
                        "^\[0-9\]+$" {
                            if {[regexp "^\[0-9\]+$" $value]} {
                                set quizconf($key) $value
                                set success 1
                            }
                        }
                        default {
                            set quizconf($key) $value
                            set success 1
                        }
                    }

                    if {$success == 1} {
                        irc_dcc $idx "Config $key successfully set to $value."
                        log "-- config $key set to $value."

                        # action on certain variables
                        cfg_apply $key $oldvalue

                    } else {
                        irc_dcc $idx "Config $key could not be set to '$value', wrong format."
                        log "-- Config $key could not be set to '$value', wrong format."
                    }
                    set success 0
                }
            } else {
                # dump keys with substring
                set keylist [lsort [array names quizconf "*$key*"]]
                if {[llength $keylist] == 0} {
                    irc_dcc $idx "Sorry, no configuration matches '$key'"
                } else {
                    irc_dcc $idx "Matched configuration settings for '$key':"
                    for {set j 0} {$j < [llength $keylist]} {incr j 1} {
                        irc_dcc $idx "[lindex $keylist $j] = $quizconf([lindex $keylist $j])"
                    }
                }
            }
        }

        # check if arg was empty and dump _all_ known keys then
        if {$arg == ""} {
            set keylist [lsort [array names quizconf]]
            irc_dcc $idx "Listing all settings:"
            for {set j 0} {$j < [llength $keylist]} {incr j 1} {
                irc_dcc $idx "[lindex $keylist $j] = $quizconf([lindex $keylist $j])"
            }
        }

        return 1
    }


    # public interface for readconfig
    proc cfg_load {handle idx arg} {
        variable configfile
        irc_dcc $idx "Loaded [cfg_read $configfile] configuration entries."
    }


    # public interface for readconfig
    proc cfg_save {handle idx arg} {
        variable configfile
        irc_dcc $idx "Saved [cfg_write $configfile] configuration entries."
    }

    # applies a configuration and makes neccessary setup
    proc cfg_apply {key oldvalue} {
        global ::botnick
        global ::fundatadir

        variable intldir
        variable whisperprefix
        variable quizconf 
        variable channeltipfile
        variable pricesfile
        variable helpfile
        variable channelrulesfile
        set value $quizconf($key)

        switch -exact $key {
            "winscore" {
                if {$oldvalue != {}} {
                    irc_say $quizconf(quizchannel) [mc "%sScore to win set from %d to %d (%+d)." \
                                                         [botcolor txt] $oldvalue $value [expr $value - $oldvalue]]
                }
            }
            "msgwhisper" {
                if {$value == "yes"} {
                    set whisperprefix "PRIVMSG"
                } else {
                    set whisperprefix "NOTICE"
                }
            }
            "channelrules" {
                if {$value == "yes"} {
                    bind msg - !rules ::moxquizz::moxquizz_rules
                    bind pub - !rules ::moxquizz::moxquizz_pub_rules
                    mx_read_rules $intldir/$quizconf(language)/$channelrulesfile
                } else {
                    unbind msg - !rules ::moxquizz::moxquizz_rules
                    unbind pub - !rules ::moxquizz::moxquizz_pub_rules
                }
            }
            "prices" {
                if {$value == "yes"} {
                    mx_read_prices $intldir/$quizconf(language)/$pricesfile
                }
            }
            "language" {
                if {[file exists $intldir/$value.msg] || $value == "en"} {
                    log "--- changing language from $oldvalue to $value"
                    mclocale $value
                    if {$value != "en"} {
                        msgcat::mcload $intldir
                    }
                    mx_read_channeltips $intldir/$quizconf(language)/$channeltipfile
                    mx_read_prices $intldir/$quizconf(language)/$pricesfile
                    mx_read_rules $intldir/$quizconf(language)/$channelrulesfile
                    mx_read_help $intldir/$quizconf(language)/$helpfile

                    if {[llength [info commands moxfun_init]] != 0} {
                        set fundatadir $intldir/$quizconf(language)
                        moxfun_init
                    }

                } else {
                    log "--- Sorry, no $value.msg file in $intldir, staying with old language set."
                }
            }
        }
    }

    # reads configuration from cfile into global variable quizconf
    proc cfg_read {cfile} {
        variable quizconf

        set num 0

        log "--- Loading configuration from $cfile ..."

        set fd [open $cfile r]
        while {![eof $fd]} {
            gets $fd line
            if {![regexp "^ *#.*$" $line] && ![regexp "^ *$" $line]} {
                set content [split $line {=}]
                set key [string trim [lindex $content 0]]
                set value [string trim [lindex $content 1]]
                set quizconf($key) $value
                incr num
            }
        }
        close $fd

        log "--- Configuration loaded: $num settings."

        foreach $key [array names quizconf] {
            cfg_apply $key {}
        }

        return $num
    }


    # writes configuration from global quizconf to cfile
    proc cfg_write {cfile} {
        variable quizconf

        set num 0
        set written ""

        log "--- Saving configuration to $cfile ..."

        set fdin [open $cfile r]
        set fdout [open "$cfile.tmp" w]

        # replace known configs
        while {![eof $fdin]} {
            gets $fdin line
            switch -regexp $line {
                "(^ *$|^ *#.*$)" {
                    puts $fdout $line
                }
                "^(.*)=(.*)$" {
                    set content [split $line {=}]
                    set key [string trim [lindex $content 0]]
                    set value [string trim [lindex $content 1]]
                    if {[info exists quizconf([string trim $key])]} {
                        puts $fdout "$key = $quizconf([string trim $key])"
                        incr num
                    } else {
                        puts $fdout $line
                    }
                    lappend written [string trim $key]
                }
            }
        }

        # append "new" configs not mentioned in the file
        set keys [array names quizconf]
        for {set i 0} {$i < [llength $keys]} {incr i} {
            set key [lindex $keys $i]
            if {[lsearch -exact $written $key] == -1} {
                puts $fdout "$key = $quizconf($key)"
            }
        }

        close $fdin
        close $fdout

        # delete old config
        file rename -force "$cfile.tmp" $cfile

        log "--- Configuration saved: $num settings."
        return $num
    }

}
