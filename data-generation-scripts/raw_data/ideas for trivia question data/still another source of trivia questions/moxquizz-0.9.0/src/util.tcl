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
## internal utilities for logging and other common computations
##


namespace eval ::moxquizz {

    ## log progress of games to a file
    proc statslog {event params} {
        variable quizconf
        variable statsfile
        variable statsfilefd

        if {$quizconf(statslog) == "no"} { return }

        if {$statsfilefd == "closed"} {
            set statsfilefd [open $statsfile a]
        }

        switch -regexp $event {
            "(revolt|revoltsolve|solved|tiar|gamestart|gamewon|rankset|nickchange)" {
                puts $statsfilefd "$event $params"
                #flush $statsfilefd
            }
            default {
                log "--- ERROR:  unknown event for stats: $event $params"
            }
        }

    }

    ## func to log stuff
    proc log {text} {
        variable quizconf
        putloglev $quizconf(quizloglevel) $quizconf(quizchannel) $text
    }

    ## return a duration as a string
    proc duration {time} {
        set dur [::duration [expr [unixtime] - $time]]

        regsub -all "seconds" $dur [mc "seconds"] dur
        regsub -all "second" $dur [mc "second"] dur
        regsub -all "minutes" $dur [mc "minutes"] dur
        regsub -all "minute" $dur [mc "minute"] dur
        regsub -all "hours" $dur [mc "hours"] dur
        regsub -all "hour" $dur [mc "hour"] dur
        regsub -all "days" $dur [mc "days"] dur
        regsub -all "day" $dur [mc "day"] dur
        regsub -all "weeks" $dur [mc "weeks"] dur
        regsub -all "week" $dur [mc "week"] dur
        regsub -all "months" $dur [mc "months"] dur
        regsub -all "month" $dur [mc "month"] dur

        return $dur
    }

    ## return if strings are equal case ignored
    proc str_ieq {a b} {
        if {[string tolower $a] == [string tolower $b]} {
            return 1
        } else {
            return 0
        }
    }

    ## compare length of two elements
    proc cmp_length {a b} {
        set la [string length $a]
        set lb [string length $b]
        if {$la == $lb} {
            return 0
        } elseif {$la > $lb} {
            return 1
        } else {
            return -1
        }
    }


    ## string
    proc obfs {text} {
        return $text
        # [pending] 
        # [pending] USEME!
        # [pending] 
#         set tmp ""
#         for {set i 0} {$i < [string length $text]} {incr i} {
#             set x [string index $text $i]
#             if {$x != " "} {
#                 append tmp $x
#             } else {
#                 if {[rand 10] > 6}  {
#                     append tmp " "
#                 } else {
#                     append tmp " "
#                 }
#             }
#         }
#         return $tmp
    }

    ## convert some latin1 special chars
    proc tweak_umlauts {text} {
        regsub -all "ä" $text "ae" text
        regsub -all "ö" $text "oe" text
        regsub -all "ü" $text "ue" text
        regsub -all "Ä" $text "AE" text
        regsub -all "Ö" $text "OE" text
        regsub -all "Ü" $text "UE" text
        regsub -all "ß" $text "ss" text
        regsub -all "è" $text "e" text
        regsub -all "È" $text "E" text
        regsub -all "é" $text "e" text
        regsub -all "É" $text "E" text
        return $text
    }


    ## Banner:
    proc banner {} {
        return "[botcolor grats]\{MoxQuizz\}[botcolor norm]"
    }

    # should return as much spaces as the banner needs (for best results)
    proc bannerspace {} {
        return "          "
    }
}
