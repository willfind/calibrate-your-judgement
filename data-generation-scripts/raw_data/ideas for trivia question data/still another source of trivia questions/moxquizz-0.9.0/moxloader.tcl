### moxquizz.tcl -- quizzbot for eggdrop 1.6.9+
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

### Note about prior versions:
##
##
## Versions before 0.9.0 contained all the functions in a single file,
## which got more and more messy over the time.  Since I didn't
## refactor in time, I ended up with features spread all over the
## code, badly orthogonalized and hard to maintain (boiling frog,
## *quak*).  This version aims at changing this.

package require msgcat

namespace import -force msgcat::*

source moxquizz/src/allstars.tcl
source moxquizz/src/color.tcl
source moxquizz/src/config.tcl
source moxquizz/src/gamestate.tcl
source moxquizz/src/help.tcl
source moxquizz/src/irc.tcl
source moxquizz/src/misc.tcl
source moxquizz/src/questions.tcl
source moxquizz/src/ranking.tcl
source moxquizz/src/userquest.tcl
source moxquizz/src/users.tcl
source moxquizz/src/util.tcl

source moxquizz/src/moxquizz.tcl

source moxquizz/src/bindings.tcl

# You don't need this as it produced large files with little or no
# useful information
# [pending] This doesn't work on moxquizz.de due to tcl version!
source moxquizz/src/debug.tcl

# Main initialization routine
namespace eval ::moxquizz {

    set version_moxquizz "0.9.0"

    #
    # Initialize
    #

    cfg_read $configfile

    puts $configfile
    puts $quizconf(questionset)
    puts $quizconf(language)

    log "**********************************************************************"
    log "--- $botnick started"

    # this makes sure, that the funstuff will be initialized correcty, if loaded
    cfg_apply "language" $quizconf(language)

    questions_load $quizconf(questionset)

    rank_load $botnick 0 {}
    allstars_load $botnick 0 {}

    if {$quizconf(quizchannel) != ""} {
        set quizconf(quizchannel) [string tolower $quizconf(quizchannel)]
        channel add $quizconf(quizchannel)
    }
}
