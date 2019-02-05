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
## Handling of ranking stuff
##

namespace eval ::moxquizz {


    ###########################################################################
    #
    # commands to manage the rankings
    #
    ###########################################################################

    ## read ranks from $rankfile
    proc rank_load {handle idx arg} {
        variable rankfile
        variable userlist
        variable timerankreset
        variable lastsolver
        variable lastsolvercount
        variable qnum_thisgame
        variable quizconf

        set timeranksaved [unixtime]
        set fd 0
        set line ""
        set us 0
        set sc 0
        set mask ""

        ## clear old userlist (ranks)
        foreach u [array names userlist] {
            unset userlist($u)
        }

        ## load saved scores
        if {[file exists $rankfile] && [file readable $rankfile]} {
            set fd [open $rankfile r]
            while {![eof $fd]} {
                set line [gets $fd]
                if {![regexp "#.*" $line]} {
                    switch -regexp $line {
                        "^winscore: .+ *$" {
                            scan $line "winscore: %d" quizconf(winscore)
                        }
                        "^rankreset: +[0-9]+ *$" {
                            scan $line "rankreset: %d" timerankreset
                        }
                        "^lastsolver:" {
                            scan $line "lastsolver: %s = %d" lastsolver lastsolvercount
                        }
                        "^ranksave:" {
                            scan $line "ranksave: %d" timeranksaved
                        }
                        "^qnumber:" {
                            scan $line "qnumber: %d" qnum_thisgame
                        }
                        default {
                            scan $line "%d %d : %s at %s" started sc us mask
                            set alist [list "mask" $mask "score" $sc "lastspoken" 0 "started" [expr $started + [unixtime] - $timeranksaved]]
                            set userlist($us) $alist
                        }
                    }
                }
            }
            close $fd
            irc_dcc $idx "Ranks loaded ([llength [array names userlist]]), winscore = $quizconf(winscore), saved at unixtime $timeranksaved."
            log "--- Ranks loaded ([llength [array names userlist]]), winscore = $quizconf(winscore), saved at unixtime $timeranksaved."
        } else {
            irc_dcc $idx "Could not read \"$rankfile\"."
            log "---- could not read \"$rankfile\"."
        }
        return 1
    }


    ## save ranks to $rankfile
    proc rank_save {handle idx arg} {
        variable rankfile
        variable userlist
        variable lastsolver
        variable lastsolvercount
        variable timerankreset
        variable qnum_thisgame
        variable quizconf

        set fd 0

        ## save ranks
        if {[llength [array names userlist]] > 0} {
            set fd [open $rankfile w]
            puts $fd "# rankings from $quizconf(quizchannel) at [ctime [unixtime]]."
            puts $fd "winscore: $quizconf(winscore)"
            puts $fd "rankreset: $timerankreset"
            puts $fd "ranksave: [unixtime]"
            puts $fd "qnumber: $qnum_thisgame"
            if {$lastsolver != ""} {
                puts $fd "lastsolver: $lastsolver = $lastsolvercount"
            }
            foreach u [lsort -command rank_cmp [array names userlist]] {
                array set aa $userlist($u)
                puts $fd [format "%d %d : %s at %s" $aa(started) $aa(score) $u $aa(mask)]
            }
            close $fd
            log "--- Ranks saved to \"$rankfile\"."
            irc_dcc $idx "Ranks saved to \"$rankfile\"."
        } else {
            irc_dcc $idx "Ranks are empty, nothing saved."
        }
        return 1
    }

    ## set score of a player
    proc rank_set {handle idx arg} {
        global ::botnick

        variable userlist
        variable quizconf

        set user ""
        set newscore 0
        set oldscore 0

        ## called directly?
        if {[info level] != 1} {
            set prefix [bannerspace]
        } else {
            set prefix [banner]
        }

        log "--- rankset requested by $handle: $arg"
        statslog "rankset" [list [unixtime] $handle $arg]

        set list [split $arg]
        for {set i 0} {$i < [llength $list]} {incr i 2} {
            set user [lindex $list $i]
            set newscore [lindex $list [expr 1 + $i]]
            if {($newscore == "") || ($user == "")} {
                irc_dcc $idx "Wrong number of parameters.  Cannot set \"$user\" to \"$newscore\"."
            } elseif {[regexp {^[\+\-]?[0-9]+$} $newscore] == 0} {
                irc_dcc $idx "$newscore is not a number.  Ignoring set for $user."
            } else {
                if {![info exists userlist($user)]} {
                    if {[onchan $user $quizconf(quizchannel)]} {
                        user_getcreate $user [getchanhost $user $quizconf(quizchannel)]
                    } else {
                        irc_dcc $idx "Could not set rank for $user.  Not in list nor in quizchannel."
                        continue
                    }
                }
                array set aa $userlist($user)
                set oldscore $aa(score)
                if {[regexp {^[\+\-][0-9]+$} $newscore]} {
                    set newscore [expr $oldscore + $newscore]
                    if {$newscore < 0} {
                        irc_dcc $idx "You set the score of $user to $newscore.  Will be corrected to 0."
                        set newscore 0
                    }
                }
                set aa(score) $newscore
                set userlist($user) [array get aa]
                ## did we change something?
                if {[expr $newscore - $oldscore] != 0} {
                    set txt [mc "%s %s has new score %s<%d>%s (%+d) on rank %d." \
                                 $prefix "[botcolor nick]$user[botcolor boldtxt]" "[col bold][botcolor nick]" \
                                 $newscore [botcolor boldtxt] [expr $newscore - $oldscore] [rank_get_pos $user]]
                    set prefix [bannerspace]
                    if {![str_ieq $handle $botnick] && [hand2nick $handle] != ""} {
                        set txt [mc "%s  Set by %s." $txt [hand2nick $handle]]
                    }
                    irc_say $quizconf(quizchannel) $txt
                }

                irc_dcc $idx "$user has new score $newscore ([format "%+d" [expr $newscore - $oldscore]]) on rank [rank_get_pos $user]."
            }
        }
        return 1
    }


    ## delete a player from rank
    proc rank_delete {handle idx arg} {
        variable userlist

        log "--- rank delete requested by $handle: $arg"

        if {$arg == ""} {
            irc_dcc $idx "Tell me whom to delete."
        } else {
            foreach u [split $arg " "] {
                if {[info exists userlist($u)]} {
                    array set aa $userlist($u)
                    irc_dcc $idx "Nick $u removed from ranks.  Score was $aa(score) points."
                    unset userlist($u)
                } else {
                    irc_dcc $idx "Nick $u not in ranks."
                }
            }
        }
        return 1
    }


    ## list ranks by notice to a user
    proc rank_show_to_user {nick host handle channel arg} {
        set arg [string trim $arg]
        if {$arg == ""} {
            set arg 10
        } elseif {![regexp "^\[0-9\]+$" $arg]} {
            irc_notc $nick [mc "Sorry, \"%s\" is not an acccepted number." $arg]
            return
        }
        rank_show "NOTC" $nick $arg
    }

    ## show rankings
    proc rank_show_to_channel {handle idx arg} {
        variable quizconf

        set arg [string trim $arg]
        if {$arg == ""} {
            set arg 5
        } elseif {![regexp "^\[0-9\]+$" $arg]} {
            irc_dcc $idx "Sorry, \"$arg\" is not an acccepted number."
        }
        rank_show "CHANNEL" $quizconf(quizchannel) $arg
    }

    ## function to show the rank to a nick or channel
    proc rank_show {how where length} {
        variable timerankreset
        variable userlist
        variable quizconf

        set pos 1
        set prevscore 0
        set entries 0
        set lines ""

        # anybody with a point?
        foreach u [array names userlist] {
            array set aa $userlist($u)
            if {$aa(score) > 0} {
                set entries 1
                break
            }
        }

        # build list
        if {$entries == 0} {
            lappend lines [mc "%sRank list is empty." "[banner] [botcolor highscore]"]
        } else {
            if {$length > $quizconf(maxranklines)} {
                set length $quizconf(maxranklines)
                lappend lines [mc "You requested too many lines, limiting to %d." $quizconf(maxranklines)]
            }
            lappend lines [mc "%sCurrent Top %d (game won at %d pts):" \
                               "[banner] [botcolor highscore]" $length $quizconf(winscore)]
            set pos 1
            set prevscore 0
            foreach u [lsort -command rank_cmp [array names userlist]] {
                array set aa $userlist($u)
                if {$aa(score) == 0} { break }
                if {$pos > $length && $aa(score) != $prevscore} { break }

                if {$aa(score) == $prevscore} {
                    set text "[bannerspace] [botcolor score] = "
                } else {
                    set text [format "[bannerspace] [botcolor score]%2d " $pos]
                }
                set text [format "$text[botcolor nickscore]%18s [botcolor score] -- %2d [mc pts]." $u $aa(score)]
                if {$pos == 1} {
                    set text [mc "%s* Congrats! *" "$text[botcolor norm] [botcolor grats]"]
                }
                lappend lines $text
                set prevscore $aa(score)
                incr pos
            }
            lappend lines [mc "%sRank started %s ago." "[bannerspace] [botcolor txt]" "[duration $timerankreset]"]
        }

        # spit lines
        foreach line $lines {
            if {$how == "NOTC"} {
                irc_notc $where $line
            } else {
                irc_rsay $where $line
            }
        }

        return 1
    }


    ## reset rankings
    proc rank_reset {handle idx arg} {
        variable timerankreset
        variable userlist
        variable lastsolver
        variable lastsolvercount
        variable quizconf
        variable qnum_thisgame
        variable aftergame
        variable rankfile

        ## called directly?
        if {[info level] != 1} {
            set prefix [bannerspace]
        } else {
            set prefix [banner]
        }

        # forget last solver
        set lastsolver ""
        set lastsolvercount 0

        # clear userlist
        foreach u [array names userlist] {
            unset userlist($u)
        }
        set timerankreset [unixtime]
        irc_say $quizconf(quizchannel) [mc "%sRanks reset by %s after %d questions." \
                                             "$prefix [botcolor boldtxt]" $handle $qnum_thisgame]
        irc_dcc $idx "Ranks are resetted.  Note that the value of aftergame was neither considered nor changed."
        file delete $rankfile
        set qnum_thisgame 0
        log "--- Ranks reset by $handle at [unixtime]."
        return 1
    }


    ## return number of ppl with a point
    proc rank_users_in_rank {} {
        variable userlist
        variable quizconf

        set num 0

        foreach nick [array names userlist] {
            array set x $userlist($nick)
            if {$x(score) > 0} {
                incr num
            }
        }
        return $num
    }

    ## calculate position of nick in the rank table
    proc rank_get_pos {nick} {
        variable userlist

        set pos 0
        set prevscore 0

        if {[llength [array names userlist]] == 0 || \
                ![info exists userlist($nick)]} {
            return 0
        }

        # calc position
        foreach name [lsort -command rank_cmp [array names userlist]] {
            array set afoo $userlist($name)
            if {$afoo(score) != $prevscore} {
                incr pos
            }

            set prevscore $afoo(score)
            if {[str_ieq $name $nick]} {
                break
            }
        }
        return $pos
    }


    ## sort routine for the rankings
    proc rank_cmp {a b} {
        variable userlist

        array set aa $userlist($a)
        array set bb $userlist($b)
        if {$aa(score) == $bb(score)} {
            return 0
        } elseif {$aa(score) > $bb(score)} {
            return -1
        } else {
            return 1
        }
    }

}
