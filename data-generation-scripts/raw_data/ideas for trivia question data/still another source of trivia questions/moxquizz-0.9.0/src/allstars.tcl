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
## Handling of allstars stuff
##

namespace eval ::moxquizz {

    ###########################################################################
    #
    # Commands to handle the allstars list
    #
    ###########################################################################

    ## send the allstars file
    proc allstars_send {handle idx arg} {
        variable allstarsfile

        if {[info commands dccsend] == ""} {
            irc_dcc $idx "Sorry, module filesys is not loaded, cannot send allstars file."
        } else {
            set result [dccsend $allstarsfile [hand2nick $handle]]
            switch -exact -- $result {
                0 {
                    irc_dcc $idx "DCC SEND allstarsfile: will come"
                    log  "--- $handle DCC SEND allstarsfile: success"
                }
                1 {
                    irc_dcc $idx "DCC SEND allstarsfile: dcc table full, try again later"
                    log  "--- $handle DCC SEND allstarsfile: dcc table full"
                }
                2 {
                    irc_dcc $idx "DCC SEND allstarsfile: can't open socket"
                    log  "--- $handle DCC SEND allstarsfile: can't open socket"
                }
                3 {
                    irc_dcc $idx "DCC SEND allstarsfile: file doesn'y exist"
                    log  "--- $handle DCC SEND allstarsfile: file doesn'y exist"
                }
                4 {
                    irc_dcc $idx "DCC SEND allstarsfile: queued for later transfer"
                    log  "--- $handle DCC SEND allstarsfile: queued for later transfer"
                }
            }
        }
        return 1
    }


    ## load allstars list
    proc allstars_load {handle idx arg} {

        variable allstarsarray
        variable allstarsfile
        variable allstars_starttime
        variable quizconf

        variable ignores

        set thismonth 0

        log "--- reading allstars list from $allstarsfile"

        if {$quizconf(monthly_allstars) == "yes"} {
            set thismonth [clock scan [clock format [unixtime] -format "%m/01/%Y"]]
        }

        if {[file exists $allstarsfile] && [file readable $allstarsfile]} {
            # clear old list
            foreach name [array names allstarsarray] {
                unset allstarsarray($name)
            }
            set allstars_starttime -1

            ## read datafile
            set fd [open $allstarsfile r]
            while {![eof $fd]} {
                set line [gets $fd]
                if {[regexp "^#!ignore" $line]} {
                    scan $line "#!ignore %s" nickignore
                    set ignores([string tolower $nickignore]) 1
                } else {
                    if {![regexp "#.*" $line]} {
                        if {[scan $line "%d %d : %d %d --  %s %s " time duration sctotal sc us usermask] == 6} {
                            if {$time >= $thismonth
                                && ![info exists ignores([string tolower $us])]} {
                                if {$allstars_starttime == -1} {
                                    set allstars_starttime $time
                                }
                                if {[info exists allstarsarray($us)]} {
                                    set entry $allstarsarray($us)
                                    set allstarsarray($us) [list \
                                                                [expr [lindex $entry 0] + 1] \
                                                                [expr [lindex $entry 1] + [allstars_calc_points $sctotal $sc $duration]] \
                                                               ]
                                } else {
                                    set allstarsarray($us) [list \
                                                                1 \
                                                                [allstars_calc_points $sctotal $sc $duration] \
                                                               ]
                                }
                            }
                        } else {
                            log "---- allstar line not recognized: \"$line\"."
                        }
                    }
                }
            }
            close $fd
            log "---- allstars list successfully read ([llength [array names allstarsarray]] users)."
            irc_dcc $idx "Allstars list successfully read ([llength [array names allstarsarray]] users)."
        } else {
            log  "---- could not read \"$allstarsfile\", allstars list set empty."
            irc_dcc $idx  "Could not read \"$allstarsfile\", allstars list set empty."
            array set allstarsarray {}
        }
        return 1
    }


    ## list allstars by notice to a user
    proc allstars_show_to_user {nick host handle channel arg} {
        set arg [string trim $arg]
        if {$arg == ""} {
            set arg 10
        } elseif {![regexp "^\[0-9\]+$" $arg]} {
            irc_notc $nick [mc "Sorry, \"%s\" is not an acccepted number." $arg]
        }
        allstars_show "NOTC" $nick $arg
    }

    ## show allstars
    proc allstars_show_to_channel {handle idx arg} {
        variable quizconf

        set arg [string trim $arg]
        if {$arg == ""} {
            set arg 5
        } elseif {![regexp "^\[0-9\]+$" $arg]} {
            irc_dcc $idx "Sorry, \"$arg\" is not an acccepted number."
            return
        }
        allstars_show "CHANNEL" $quizconf(quizchannel) $arg
    }

    ## show all-star rankings
    proc allstars_show {how where length} {
        variable allstarsarray
        variable allstars_starttime
        variable quizconf

        set score 0
        set games 0
        set numofgames 0
        set lines ""

        if {[llength [array names allstarsarray]] == 0} {
            lappend lines [mc "%sAllstars list is empty." "[banner] [botcolor boldtxt]"]
        } else {
            # limit num of lines
            if {$length > $quizconf(maxranklines)} {
                set length $quizconf(maxranklines)
                lappend lines [mc "Your requested too many lines, limiting to %d." $quizconf(maxranklines)]
            }

            # build table
            set aline "[banner] [botcolor highscore]"
            if {$quizconf(monthly_allstars) == "yes"} {
                set aline "$aline[clock format $allstars_starttime -format %B] "
            }
            set aline [mc "%sAll-Stars top %d:" $aline $length]
            lappend lines $aline
            set pos 1
            set prevscore 0
            foreach u [lsort -command allstars_cmp [array names allstarsarray]] {
                set entry $allstarsarray($u)
                set games [lindex $entry 0]
                set score [lindex $entry 1]
                incr numofgames $games

                # if {$score == 0} { break }
                ## continue counting num of games played!!
                if {$pos > $length && $score != $prevscore} { continue }
                if {$score == $prevscore} {
                    set text "[bannerspace] [botcolor score] = "
                } else {
                    set text [format "[bannerspace] [botcolor score]%2d " $pos]
                }
                set text [format "$text[botcolor nickscore]%18s [botcolor score] -- %5.3f [mc pts], %2d [mc games]." $u $score $games]
                if {$pos == 1} {
                    set text [mc "%s* Congrats! *" "$text[botcolor norm] [botcolor grats]"]
                }
                lappend lines $text
                set prevscore $score
                incr pos
            }
            lappend lines [mc "%sThere were %d users playing %d games." \
                               "[bannerspace] [botcolor boldtxt]" [llength [array names allstarsarray]] $numofgames]
        }

        # spit table
        foreach line $lines {
            if {$how == "NOTC"} {
                irc_notc $where $line
            } else {
                irc_say $where $line
            }
        }

        return 1
    }


    proc allstars_save {time duration score name mask} {
        global ::botnick

        variable allstarsfile
        variable userlist
        variable allstarsarray
        variable allstars_starttime
        variable quizconf

        set scoretotal 0

        # compute sum of scores in this game
        foreach u [array names userlist] {
            array set afoo $userlist($u)
            incr scoretotal $afoo(score)
        }

        if {$scoretotal == $score} {
            irc_action $quizconf(quizchannel) [mc "does not record you in the allstars table, since you played alone."]
            log "--- $name was not saved to allstars since he/she was playing alone."
        } else {
            # save entry
            set fd [open $allstarsfile a]
            puts $fd "$time $duration : $scoretotal $score -- $name $mask"
            close $fd
            if {[info exists allstarsarray($name)]} {
                set entry $allstarsarray($name)
                set allstarsarray($name) [list \
                                              [expr [lindex $entry 0] + 1] \
                                              [expr [lindex $entry 1] + [allstars_calc_points $scoretotal $score $duration]] \
                                             ]
            } else {
                set allstarsarray($name) [list \
                                              1 \
                                              [allstars_calc_points $scoretotal $score $duration] \
                                             ]
            }

            # reload allstars table if a new month began
            if {$quizconf(monthly_allstars) == "yes" &&
                $allstars_starttime < [clock scan [clock format [unixtime] -format "%m/01/%Y"]]} {
                log "--- new month, reloading allstars table"
                allstars_load $botnick 0 {}
            }

            irc_action $quizconf(quizchannel) [mc "records %s with %5.3f points on the all-stars table (now %5.3f points, pos %d)." \
                                                    $name [allstars_calc_points $scoretotal $score $duration] \
                                                    [lindex $allstarsarray($name) 1] [allstars_get_pos $name]]
            log "--- saved $name with [allstars_calc_points $scoretotal $score $duration] points (now [format "%5.3f" [lindex $allstarsarray($name) 1]] points, pos [allstars_get_pos $name]) to the allstars file. Time: $time"
        }
    }


    ## compute position of $nick in allstarsarray
    proc allstars_get_pos {nick} {
        variable allstarsarray

        set pos 0
        set prevscore 0

        if {[llength [array names allstarsarray]] == 0 || \
                ![info exists allstarsarray($nick)]} {
            return 0
        }

        # calc position
        foreach name [lsort -command allstars_cmp [array names allstarsarray]] {
            if {[lindex $allstarsarray($name) 1] != $prevscore} {
                incr pos
            }

            set prevscore [lindex $allstarsarray($name) 1]
            if {[str_ieq $name $nick]} {
                break
            }
        }
        return $pos
    }


    ## calculate entry in allstar table
    proc allstars_calc_points {sum score duration} {
        if {$sum == $score} {
            return 0
        } else {
            return [expr (10 * double($sum)) / (log10($score) * $duration)]
        }
    }


    ## sort routine for the allstars
    proc allstars_cmp {a b} {
        variable allstarsarray

        set sca [lindex $allstarsarray($a) 1]
        set scb [lindex $allstarsarray($b) 1]

        if {$sca == $scb} {
            return 0
        } elseif {$sca > $scb} {
            return -1
        } else {
            return 1
        }
    }
}
