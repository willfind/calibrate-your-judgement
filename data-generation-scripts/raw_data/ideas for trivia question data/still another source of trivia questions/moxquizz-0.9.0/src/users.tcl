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
## User record handling
##

namespace eval ::moxquizz {

    ###########################################################################
    #
    # Handling of certain events, like +m, nickchanges and others
    #
    ###########################################################################

    ## player has changed nick.  Adjust ranking
    proc user_nick_changed {nick host handle channel newnick} {
        variable userlist
        variable quizconf
        set addscore 0
        set ascore 0

        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return
        }

        log "--- $nick changed to $newnick noted."
        log "---- hostmask: [maskhost $host]"
        statslog "nickchange" [list [unixtime] $nick $newnick]

        # see, if we can collect some old scores
        if {[info exists userlist($newnick)]} {
            log "---- old entry: $userlist($newnick)"
            # check if we know the host
            array set oldentry $userlist($newnick)
            if {$oldentry(mask) == [maskhost $host]} {
                set addscore $oldentry(score)
                log "---- adding score: $addscore"
                if {$addscore != 0} {
                    irc_notc $newnick [mc "Your old scores of %d were collected, since I know your host." $addscore]
                }
            } else {
                set addscore 0
                log "---- hosts differed, replacing score."
                if {$oldentry(score) != 0} {
                    irc_notc $newnick [mc "Your host was new to me, old scores deleted."]
                }
            }

            # new score gathered, sum up!
            if {[info exists userlist($nick)]} {
                array set newentry $userlist($nick)
                incr newentry(score) $addscore
                set newentry(started) $oldentry(started)
                set userlist($newnick) [array get newentry]
                unset userlist($nick)
            }
            # else, the newnick is still in ranks.
            # do nothing.

        } elseif {[info exists userlist($nick)]} {
            set userlist($newnick) $userlist($nick)
            array set afoo $userlist($newnick)
            unset userlist($nick)
            log "---- Known, scores transferred."
            if {$afoo(score) > 0} {
                irc_notc $newnick [mc "I saw you renaming and transferred scores."]
            }
        }
    }


    ## notification when a user joins in
    proc user_joined_channel {nick host handle channel} {
        variable qlist
        variable version_moxquizz
        variable userlist
        variable quizconf
        variable quizstate
        variable qnum_thisgame

        set text ""

        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return
        }

        set text [mc "Welcome to %sversion %s, © by Moxon <moxon@meta-x.de>.  Say \"!ask\" to get the current question or \"!qhelp\" to get an help text." \
                      "[banner] [botcolor norm]" $version_moxquizz]

        if {$quizconf(channelrules) == "yes"} {
            set text [mc "%s  Check the channel rules with !rules." $text]
        }

        irc_notc $nick $text

        if {$quizstate == "paused"} {
            set text [mc "The current game is paused after %d questions." $qnum_thisgame]
        } elseif {$qnum_thisgame != 0} {
            set text [mc "There is a game running, %d questions have already been asked." $qnum_thisgame]
        } else {
            set text ""
        }
        set text [mc "%s  I know about %d questions." $text [llength $qlist]]
        irc_notc $nick [string trim $text]

        if {[info exists userlist($nick)]} {
            array set aa $userlist($nick)
            if {$aa(mask) == [maskhost $host]} {
                if {$aa(score) > 0} {
                    irc_notc $nick [mc "You are listed with %d points on rank %d." $aa(score) [rank_get_pos $nick]]
                }
            } else {
                irc_notc $nick [mc "Your hostmask is new to me, deleting old scores."]
                unset userlist($nick)
            }
        }

        log "--- $nick joined the channel."
    }


    ## create an entry in the userlist or update an existing
    ## then entry is returned
    proc user_getcreate {nick host} {
        global ::botnick

        variable userlist

        ## prevent myself from being added, though this will never happen
        if {[str_ieq $nick $botnick]} {
            return
        }

        if {[info exists userlist($nick)]} {
            array set anarray $userlist($nick)
            set anarray(lastspoken) [unixtime]
            set userlist($nick) [array get anarray]
        } else {
            set userlist($nick) [list "mask" [maskhost $host] "score" 0 "started" [unixtime] "lastspoken" [unixtime]]
            log "---- new user $nick: $userlist($nick)"
            array set anarray $userlist($nick)
        }
    }

}
