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

# This file contains stuff for user help like !qhelp, rules,
# channeltips or other information.

namespace eval ::moxquizz {

    ###########################################################################
    #
    # Commands for help texts
    #
    ###########################################################################



    ## pubm help wrapper
    proc moxquizz_pub_help {nick host handle channel arg} {
        variable quizconf

        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return 0
        } else {
            moxquizz_help $nick $host $handle $arg
            return 1
        }
    }


    ## help
    proc moxquizz_help {nick host handle arg} {
        global botnick
        variable version_moxquizz
        variable quizconf
        variable quizhelp
        variable funstuff_enabled

        set lines ""
        set help ""
        set topics [lsort [array names quizhelp]]

        set itmp [lsearch -exact $topics "idx"]
        set topics [lreplace $topics $itmp $itmp]

        set arg [string tolower [string trim $arg]]

        # choose help text
        log "--- help requested by $nick about '$arg'."

        if {[array size quizhelp] == 0} {
            set lines [list [mc "Sorry, there is no help text loaded for the quiz."]]
        } else {

            # elide some help text based on configuration
            if {$quizconf(userquestions) == "no"} {
                set index [lsearch $topics "userquestions"]
                set topics [lreplace $topics $index $index]
            }

            if {![info exists funstuff_enabled] || $funstuff_enabled != 1} {
                set index [lsearch $topics "fun"]
                set topics [lreplace $topics $index $index]
            }


            # select help text
            if {$arg == "" || $arg == "idx"} {
                set lines $quizhelp(idx)
                set ltmp ""
                for {set i 0} {$i < [llength $lines]} {incr i} {
                    lappend ltmp [format [lindex $lines $i] $topics]
                }
                set lines $ltmp
            } else {
                if {[lsearch $topics $arg] != -1} {
                    set lines $quizhelp($arg)
                } else {
                    set lines [list [mc "Can't help you about '%s'.  Choose a topic from: %s" $arg $topics]]
                }
            }
        }

        # dump help
        irc_notc $nick [mc "%s Help for %s version %s" [banner] $botnick $version_moxquizz]
        foreach line $lines {
            irc_notc $nick $line
        }

        return 1
    }


    proc mx_read_help {helpfile} {
        variable quizhelp

        set key ""
        set values ""

        foreach k [array names quizhelp] {
            unset quizhelp($k)
        }

        log "--- Reading help texts from $helpfile"

        if {[file exists $helpfile]} {
            set fd [open $helpfile r]
            while {![eof $fd]} {
                set line [gets $fd]
                switch -regexp $line {
                    "^(#.*|[ \t]*)$" { # ignore it
                    }
                    "^\\[.+\\]" {
                        if {$key != ""} {
                            set quizhelp($key) $values
                        }
                        regexp "^\\\[(.+)\\\]" $line foo key
                        set values ""
                    }
                    default {
                        lappend values $line
                    }
                }
            }
            # save last entry
            set quizhelp($key) $values
            close $fd
            log "--- Sucessfully read [array size quizhelp] help entries."
        } else {
            log "--- ERROR:  $helpfile not found, no help will be available to users."
        }
    }

    ###########################################################################
    #
    # Handling of channel tips (regular tips)
    #
    ###########################################################################

    ## read the list of channeltips
    proc mx_read_channeltips {ctipfile} {
        variable quizconf
        variable channeltips
        set line ""

        # [pending] hm, this looks strange since we check it below
        set channeltips ""

        log "--- Reading channeltips from $ctipfile"

        if {$quizconf(channeltips) != "yes"} {
            log "--- Channeltips not read since feature disabled."
        } else {
            if {[file exists $ctipfile]} {
                set fd [open $ctipfile r]
                while {![eof $fd]} {
                    set line [gets $fd]
                    if {![regexp "^ *$" $line] && ![regexp "^#.*" $line]} {
                        lappend channeltips $line
                    }
                }
                close $fd
                log "---- Read [llength $channeltips] channeltips."
            } else {
                log "---- no such file: $ctipfile"
            }
        }

        if {[llength $channeltips] == 0} {
            set quizconf(channeltips) "no"
            log "---- Channeltips disabled since no tips loaded."
        }

        return 1
    }

    ###########################################################################
    #
    # Handling of channel rules
    #
    ###########################################################################

    ## read rules
    proc mx_read_rules {rulesfile} {
        variable quizconf
        variable channelrules
        set num 0

        # [pending] this looks strange since we check below
        set channelrules ""

        log "--- Loading channel rules from $rulesfile ..."

        if {[file exists $rulesfile]} {
            set fd [open $rulesfile r]
            while {![eof $fd]} {
                gets $fd line

                if {![regexp "^ *#.*$" $line] && ![regexp "^ *$" $line]} {
                    lappend channelrules $line
                    incr num
                }
            }
            close $fd

            log "---- $num channel rules loaded from $rulesfile"
        } else {
            log "---- no such file: $rulesfile"
        }

        if {$num == 0} {
            set quizconf(channelrules) no
            log "---- Channel rules command disabled, since no rules found."
        }

        return 1
    }


    ## pubm !rules wrapper
    proc moxquizz_pub_rules {nick host handle channel arg} {
        variable quizconf

        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return 0
        } else {
            moxquizz_rules $nick $host $handle $arg
            return 1
        }
    }

    ## tells a user about the rules
    proc moxquizz_rules {nick host handle arg} {
        variable quizconf
        variable channelrules
        variable botnick

        if {$quizconf(channelrules) == "no" || $channelrules == ""} {
            irc_notc $nick [mc "No rules loaded.  This doesn't mean there are no rules for this channel.  Beware!"]
            log "WARNING: !rules called by $nick while no rules are loaded."
            return 0
        }


        # dump rules
        irc_notc $nick [mc "%s Rules for %s" [banner] $quizconf(quizchannel)]
        foreach line $channelrules {
            irc_notc $nick $line
        }

        return 1

    }

    ## pubm !version wrapper
    proc moxquizz_pub_version {nick host handle channel arg} {
        variable quizconf

        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return 0
        } else {
            moxquizz_version $nick $host $handle $arg
            return 1
        }
    }

    ## tells a user the scritp version
    proc moxquizz_version {nick host handle arg} {
        variable qlist
        variable version_moxquizz
        variable quizconf

        set text [mc "Welcome to %sversion %s, © by Moxon <moxon@meta-x.de>.  Say \"!ask\" to get the current question or \"!qhelp\" to get an help text." \
                      "[banner] [botcolor norm]" $version_moxquizz]

        set text [mc "%s  I know about %d questions." $text [llength $qlist]]
        irc_notc $nick [string trim $text]

        return 1
    }


    ###########################################################################
    #
    # Handling prices to win
    #
    ###########################################################################

    proc mx_read_prices {pricefile} {
        variable quizconf
        variable prices
        set line ""

        # [pending] this looks strange since we check below
        set prices ""

        log "--- Reading prices from $pricefile"

        if {$quizconf(prices) != "yes"} {
            log "--- Prices not read since feature disabled."
        } else {
            if {[file exists $pricefile]} {
                set fd [open $pricefile r]
                while {![eof $fd]} {
                    set line [gets $fd]
                    if {![regexp "^ *$" $line] && ![regexp "^#.*" $line]} {
                        lappend prices $line
                    }
                }
                close $fd
                log "---- Read [llength $prices] prices."
            } else {
                log "---- no such file: $pricefile"
            }
        }

        if {[llength $prices] == 0} {
            set quizconf(prices) "no"
            log "---- Prices disabled since no prices found."
        }

        return 1
    }

}
