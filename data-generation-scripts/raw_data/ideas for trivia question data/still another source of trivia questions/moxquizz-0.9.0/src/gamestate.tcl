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
## Handling of gamestate (running, pausing, halting, resetting, ...),
## moving of quiz to other channels
##

namespace eval ::moxquizz {

    ###########################################################################
    #
    # game administration commands (start stop, move etc)
    #
    ###########################################################################

    ## reset game
    proc reset {handle idx arg} {
        variable quizstate

        stop $handle $idx $arg
        rank_reset $handle $idx $arg
        init $handle $idx $arg
    }

    ## initialize
    proc init {handle idx arg} {
        variable qlist
        variable version_moxquizz
        variable quizstate
        variable quizconf
        variable aftergame

        set quizstate "halted"
        set aftergame $quizconf(aftergameaction)
        if {$quizconf(quizchannel) != ""} {
            irc_say $quizconf(quizchannel) [mc "%sHello!  I am a MoxQuizz version %s and ready to squeeze your brain!" "[banner] [botcolor txt]" "[col bold]$version_moxquizz[col bold][botcolor txt]"]
            irc_say $quizconf(quizchannel) [mc "%s%d questions in database, just %s!ask%s.  Report bugs and suggestions to moxon@meta-x.de" "[bannerspace] [botcolor txt]" [llength $qlist]  [col bold] "[col bold][botcolor txt]"]
            log "--- Game initialized"
        } else {
            irc_dcc $idx "ERROR: quizchannel is set to an empty string, use .!quizto to set one."
        }
        return 1
    }

    ## stop
    ## stop everything and kill all timers
    proc stop {handle idx arg} {
        variable quizstate
        variable quizconf

        ## called directly?
        if {[info level] != 1} {
            set prefix [bannerspace]
        } else {
            set prefix [banner]
        }

        set quizstate "stopped"

        ## kill timers
        foreach t [utimers] {
            if {[lindex $t 1] == "mx_timer_ask" || [lindex $t 1] == "mx_timer_tip"} {
                killutimer [lindex $t 2]
            }
        }

        log "--- Game stopped."
        irc_say $quizconf(quizchannel) [mc "%s %sQuiz stopped." $prefix [botcolor boldtxt]]
        return 1
    }


    ## halt
    ## halt everything and kill all timers
    proc halt {handle idx arg} {
        variable quizstate
        variable quizconf

        ## called directly?
        if {[info level] != 1} {
            set prefix [bannerspace]
        } else {
            set prefix [banner]
        }

        set quizstate "halted"

        ## kill timers
        foreach t [utimers] {
            if {[lindex $t 1] == "mx_timer_ask" || [lindex $t 1] == "mx_timer_tip"} {
                killutimer [lindex $t 2]
            }
        }

        log "--- Game halted."
        irc_say $quizconf(quizchannel) [mc "%s %sQuiz halted.  Say !ask for new questions." $prefix [botcolor boldtxt]]
        return 1
    }


    ## pause
    proc pause {handle idx arg} {
        variable quizstate
        variable statepaused
        variable quizconf

        set qwasopen "."

        if {[regexp "(halted|paused)" $quizstate]} {
            irc_dcc $idx "Quiz state is $quizstate.  Command ignored."
        } else {
            if {$quizstate == "asked"} {
                foreach t [utimers] {
                    if {[lindex $t 1] == "mx_timer_tip"} {
                        killutimer [lindex $t 2]
                    }
                }
                set qwasopen [mc " after %s." [duration $timeasked]]
            } elseif {$quizstate == "waittoask"} {
                foreach t [utimers] {
                    if {[lindex $t 1] == "mx_timer_ask"} {
                        killutimer [lindex $t 2]
                    }
                }
            }
            set statepaused $quizstate
            set quizstate "paused"
            log "--- Game paused$qwasopen  Quiz state was: $statepaused"
            irc_say $quizconf(quizchannel) [mc "%sQuiz paused%s" "[banner] [botcolor boldtxt]" $qwasopen]
        }
        return 1
    }


    ## continue
    proc cont {handle idx arg} {
        variable quizstate
        variable timeasked
        variable theq
        variable statepaused
        variable usergame
        variable statemoderated
        variable quizconf

        if {$quizstate != "paused"} {
            irc_dcc $idx "Game not paused, command ignored."
        } else {
            if {$statepaused == "asked"} {
                if {$usergame == 1} {
                    set txt [mc "%sQuiz continued.  The user question open since %s, worth %d point(s):" "[banner] [botcolor boldtxt]" [duration $timeasked] $theq(Score)]
                } else {
                    set txt [mc "%sQuiz continued.  The question open since %s, worth %d point(s):" "[banner] [botcolor boldtxt]" [duration $timeasked] $theq(Score)]
                }
                irc_say $quizconf(quizchannel) $txt
                irc_say $quizconf(quizchannel) "[bannerspace] [botcolor question]$theq(Question)"
                utimer $quizconf(tipdelay) mx_timer_tip
            } else {
                irc_say $quizconf(quizchannel) [mc "%sQuiz continued.  Since there is no open question, a new one will be asked." "[banner] [botcolor boldtxt]"]
                utimer 3 mx_timer_ask
            }
            set quizstate $statepaused
            set statepaused ""
            set statemoderated ""
            log "--- Game continued."
        }
        return 1
    }

    ## show module status
    # [pending] rework this to be more flexible
    proc status {handle idx arg} {
        global ::uptime

        variable quizstate
        variable statepaused
        variable qlist
        variable version_moxquizz
        variable userlist
        variable timeasked
        variable usergame
        variable userqlist
        variable theq
        variable qnumber
        variable qnum_thisgame
        variable aftergame
        variable quizconf

        set askleft 0
        set rankleft 0
        set tipleft 0
        set txt ""
        set chansjoined ""

        ## banner and where I am
        set txt "I am [color_strip [banner]] version $version_moxquizz, up for [duration $uptime]"
        if {$quizconf(quizchannel) == ""} {
            set txt "$txt, not quizzing on any channel."
        } else {
            set txt "$txt, quizzing on channel \"$quizconf(quizchannel)\"."
        }
        irc_dcc $idx $txt

        irc_dcc $idx "I know the channels [channels]."

        foreach chan [channels] {
            if {[botonchan $chan]} {
                set chansjoined "$chansjoined $chan"
            }
        }
        if {$chansjoined == ""} {
            set chansjoined " none"
        }
        irc_dcc $idx "I currently joined:$chansjoined."

        if {$quizstate == "asked" || $statepaused == "asked"} {
            ## Game running?  User game?
            set txt "There is a"
            if {$usergame == 1} {
                set txt "$txt user"
            }
            set txt "$txt game running."
            if {[userquest_queuelength]} {
                set txt "$txt  [userquest_queuelength] user quests scheduled."
            } else {
                set txt "$txt  No user quest is scheduled."
            }
            set txt "$txt  Quiz state is: $quizstate."
            irc_dcc $idx $txt

            ## Open question?  Quiz state?
            set txt "The"
            if {[info exists theq(Level)]} {
                set txt "$txt level $theq(Level)"
            }
            set txt "$txt question no. $qnum_thisgame is:"
            if {[info exists theq(Category)]} {
                set txt "$txt ($theq(Category))"
            }
            irc_dcc $idx "$txt \"$theq(Question)\" open for [duration $timeasked], worth $theq(Score) points."
        } else {
            ## no open question, no game running
            set txt "There is no question open."
            set txt "$txt  Quiz state is: $quizstate."
            if {[userquest_queuelength]} {
                set txt "$txt  [userquest_queuelength] user quests scheduled."
            } else {
                set txt "$txt  No user quest is scheduled."
            }
            irc_dcc $idx $txt
        }

        irc_dcc $idx "Action after game won: $aftergame"

        foreach t [utimers] {
            if {[lindex $t 1] == "mx_timer_ask"} {
                set askleft [lindex $t 0]
            }
            if {[lindex $t 1] == "mx_timer_tip"} {
                set tipleft [lindex $t 0]
            }
        }

        irc_dcc $idx "Tipdelay: $quizconf(tipdelay) ($tipleft)  Askdelay: $quizconf(askdelay) ($askleft) Tipcycle: $quizconf(tipcycle)"
        irc_dcc $idx "I know about [llength $qlist] normal and [llength $userqlist] user questions.  Question number is $qnumber."
        irc_dcc $idx "There are [llength [array names userlist]] known people, winscore is $quizconf(winscore)."
        irc_dcc $idx "Game row restriction: $quizconf(lastwinner_restriction), row length: $quizconf(lastwinner_max_games)"
        return 1
    }


    ## exit -- finish da thing and logoff
    proc terminate {handle idx arg} {
        global ::botnick
        global ::uptime

        variable rankfile
        variable statsfilefd
        variable quizconf

        log "--- EXIT requested."
        irc_say $quizconf(quizchannel) [mc "%sI am leaving now, after running for %s." "[banner] [botcolor boldtxt]" [duration $uptime]]
        if {$arg != ""} {
            irc_say $quizconf(quizchannel) "[bannerspace] $arg"
        }
        # quizleave $handle $idx $arg
        moxquiz_rank_save $handle $idx {}
        moxquiz_saveuserquests $handle $idx "all"
        moxquiz_config_save $handle $idx {}
        if {$statsfilefd != "closed"} { close $statsfilefd }
        irc_dcc $idx "$botnick now exits."
        log "--- $botnick exited"
        log "**********************************************************************"

        utimer 10 die
    }

    ## aftergame -- what to do if the game is over (won or desert detection)
    proc aftergame {handle idx arg} {
        variable aftergame
        variable quizstate

        set thisnext "this"

        if {$quizstate == "stopped" || $quizstate == "halted"} {
            set thisnext "next"
        }

        if {$arg == ""} {
            irc_dcc $idx "After $thisnext game I am planning to: \"$aftergame\"."
            irc_dcc $idx "Possible values are: exit, halt, stop, newgame."
        } else {
            switch -regexp $arg {
                "(exit|halt|stop|newgame)" {
                    set aftergame $arg
                    irc_dcc $idx "After $thisnext game I now will: \"$aftergame\"."
                }
                default {
                    irc_dcc $idx "Invalid action.  Chosse from: exit, halt, stop and newgame."
                }
            }
        }
        return 1
    }


    ## solve question
    proc solve {handle idx arg} {
        global ::botnick 

        variable quizstate
        variable theq
        variable lastsolvercount
        variable lastsolver
        variable timeasked
        variable quizconf

        set txt ""
        set answer ""

        if {$quizstate != "asked"} {
            irc_dcc $idx "There is no open question."
        } else {
            mx_answered
            set lastsolver ""
            set lastsolvercount 0

            if {[str_ieq $botnick $handle]} {
                set txt [mc "%sAutomatically solved after %s." \
                             "[banner] [botcolor boldtxt]" [duration $timeasked]]
            } else {
                set txt [mc "%sManually solved after %s by %s" \
                             "[banner] [botcolor boldtxt]" [duration $timeasked] $handle]
            }
            irc_say $quizconf(quizchannel) $txt

            # remove area of tip generation tags
            regsub -all "\#(\[^\#\]*\)\#" $theq(Answer) "\\1" answer
            irc_say $quizconf(quizchannel) [mc "%sThe answer is:%s%s" \
                                                 "[bannerspace] [botcolor txt]" "[botcolor norm] [botcolor answer]" $answer]

            # remove protection of numbers from regexp
            if {[info exists theq(Oldexp)]} {
                set theexp $theq(Oldexp)
            } else {
                set theexp $theq(Regexp)
            }

            if {$answer != $theexp} {
                irc_say $quizconf(quizchannel) [mc "%sAnd should match:%s%s" \
                                                     "[bannerspace] [botcolor txt]" "[botcolor norm] [botcolor answer]" $theexp]
            }

            log "--- solved by $handle manually."
            # schedule ask
            utimer $quizconf(askdelay) mx_timer_ask
        }
        return 1
    }


    ## show a tip
    proc tip {handle idx arg} {
        global ::botnick 

        variable tipno
        variable quizstate
        variable tiplist
        variable quizconf

        if {$quizstate == "asked"} {
            if {$arg != ""} {
                irc_dcc $idx "Extra tip \'$arg\' will be given."
                set tiplist [linsert $tiplist $tipno $arg]
            }
            if {$tipno == [llength $tiplist]} {
                # enough tips, solve!
                set tipno 0
                solve $botnick 0 {}
            } else {
                set tiptext [lindex $tiplist $tipno]
                irc_say $quizconf(quizchannel) [mc "%sHint %d:" "[banner] [botcolor boldtxt]" [expr $tipno + 1]]
                irc_say $quizconf(quizchannel) "[bannerspace] [botcolor tip]$tiptext"
                foreach j [utimers] {
                    if {[lindex $j 1] == "mx_timer_tip"} {
                        killutimer [lindex $j 2]
                    }
                }
                log "----- Tip number $tipno: $tiptext"
                # only short delay after last tip
                incr tipno
                if {$tipno == [llength $tiplist]} {
                    utimer 15 mx_timer_tip
                } else {
                    utimer $quizconf(tipdelay) mx_timer_tip
                }
            }
        } else {
            irc_dcc $idx "Sorry, no question is open."
        }
        return 1
    }

    ###########################################################################
    #
    # bot administration commands
    #
    ###########################################################################

    ## quiz to another channel
    proc quizto {handle idx arg} {
        variable quizconf
        if {[regexp "^#.*" $arg] == 0} {
            irc_dcc $idx "$arg not a valid channel."
        } else {
            if {$quizconf(quizchannel) != ""} {
                # channel set $quizconf(quizchannel) +inactive
                irc_say $quizconf(quizchannel) [mc "Quiz is leaving to %s.  Goodbye!" $arg]
            }
            set quizconf(quizchannel) [string tolower $arg]
            channel add $quizconf(quizchannel)
            channel set $quizconf(quizchannel) -inactive
            irc_say $quizconf(quizchannel) [mc "Quiz is now on this channel.  Hello!"]
            irc_dcc $idx "quiz to channel $quizconf(quizchannel)."
            log "--- quizto channel $quizconf(quizchannel)"
        }
        return 1
    }


    ## quiz leave a channel
    proc quizleave {handle idx arg} {
        variable quizconf
        if {$arg == ""} {
            irc_say $quizconf(quizchannel) [mc "%s Goodbye." [banner]]
        } else {
            irc_say $quizconf(quizchannel) "[banner] $arg"
        }
        if {$quizconf(quizchannel) != ""} {
            channel set $quizconf(quizchannel) +inactive
            log "--- quizleave channel $quizconf(quizchannel)"
            irc_dcc $idx "quiz left channel $quizconf(quizchannel)"
            set quizconf(quizchannel) ""
        } else {
            irc_dcc $idx "I'm not quizzing on any channel."
        }
        return 1
    }
}
