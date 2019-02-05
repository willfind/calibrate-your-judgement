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
## Comment handling, other misc stuff
##

namespace eval ::moxquizz {

    # say Hi to "known" users
    proc moxquizz_pub_hi {nick host handle channel arg} {
        variable quizconf
        variable allstarsarray
        if {[str_ieq $channel $quizconf(quizchannel)] &&
            ([validuser $handle] || [info exists allstarsarray($nick)]) } {
            irc_say $quizconf(quizchannel) [mc "Hi %s!  Nice to see you." $nick]
        }
    }



    # say Hi to "known" users
    proc moxquizz_purr {nick host handle channel action arg} {
        global ::botnick

        variable quizconf
        variable allstarsarray

        # [pending] translate this
        set tlist [list "purrs." \
                       "meows." \
                       "happily hops around."]

        if {$action == "ACTION" && [string trim $arg] == "pats $botnick" &&
            [str_ieq $channel $quizconf(quizchannel)] &&
            ([validuser $handle] || [info exists allstarsarray($nick)]) } {
            irc_action $quizconf(quizchannel) [lindex $tlist [rand [llength $tlist]]]
        }
    }


    bind msg - !adver ::moxquizz::mx_adver
    ## advertisement
    proc mx_adver {nick host handle arg} {
        global ::botnick

        variable quizconf

        irc_say $quizconf(quizchannel) "[banner] $botnick is a MoxQuizz © by Moxon <moxon@meta-x.de>"
        irc_say $quizconf(quizchannel) "[bannerspace] and can be downloaded from http://moxquizz.de"

        return 0
    }
}
