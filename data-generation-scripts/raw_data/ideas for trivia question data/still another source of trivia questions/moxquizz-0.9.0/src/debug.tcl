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
## Produce loads of debugging stuff
##

variable LOGFILE [open debug.log a+]
fconfigure $LOGFILE -buffering none

variable DEBUG_DEPTH 0

puts $LOGFILE {}
puts $LOGFILE "----------------------------------------------------------------------"
puts $LOGFILE "----------------------------------------------------------------------"
puts $LOGFILE {}



## DEBUG ENABLED:
proc mx_trace_leave {cmd code res op} {
    global LOGFILE
    global DEBUG_DEPTH

    switch -exact $op {
        "leave" {
            puts $LOGFILE  "--[string repeat {  } $DEBUG_DEPTH] $cmd (code $code, result $res)"
        }

        "leavestep" {
            puts $LOGFILE  "  [string repeat {  } $DEBUG_DEPTH] - $cmd ($code)"
        }
    }
    incr DEBUG_DEPTH -1
}

proc mx_trace_enter {cmd op} {
    global LOGFILE
    global DEBUG_DEPTH

    incr DEBUG_DEPTH
    switch -exact $op {
        "enter" {
            puts $LOGFILE  "++[string repeat {  } $DEBUG_DEPTH] $cmd"
        }

        "enterstep" {
            puts $LOGFILE  "  [string repeat {  } $DEBUG_DEPTH] + $cmd"
        }
    }
}

puts $LOGFILE " MoxQuizz commands beeing traced: "
puts $LOGFILE "   [info commands ::moxquizz::*]"

foreach cmd [info commands ::moxquizz::*] {
    if {![regexp "::moxquizz::(cmp_|tweak_|str_ieq$|log$|color$|banner|obfs|col$|color_strip$|botcolor$|irc_)" $cmd]} {
        # leave and enter
        trace add execution $cmd enter mx_trace_enter
        trace add execution $cmd leave mx_trace_leave

        # stepping
        #trace add execution $cmd enterstep mx_trace_enter
        #trace add execution $cmd leavestep mx_trace_leave
    } else {
        # NOP
    }
}
