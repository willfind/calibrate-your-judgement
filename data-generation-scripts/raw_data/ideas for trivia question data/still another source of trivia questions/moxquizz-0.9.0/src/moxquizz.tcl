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
## Global variables and remaining methods which didn't fit (yet)
## elsewhere.
##

namespace eval ::moxquizz {

    ###########################################################################
    ##
    ## ATTENTION:
    ##
    ## Defaults for bot configuration.  Don't edit here, edit the file
    ## moxquizz.rc instead!  Values here are used as fallbacks only.
    ##
    ###########################################################################


    # system stuff
    variable quizbasedir        moxquizz
    variable datadir            $quizbasedir/quizdata
    variable configfile         $quizbasedir/moxquizz.rc
    variable intldir            $quizbasedir/intl

    variable rankfile           $datadir/rank.data
    variable allstarsfile       $datadir/rankallstars.data
    variable statsfile          $datadir/stats.data
    variable userqfile          $datadir/questions.user.new
    variable commentsfile       $datadir/comments.txt

    variable quizhelp

    # these will be searched in $intldir/$quizconf(language)
    variable channeltipfile     channeltips.txt
    variable channelrulesfile   channelrules.txt
    variable pricesfile         prices.txt
    variable helpfile           help.txt


    #
    # Configuration map
    #
    variable quizconf

    # [pending] those seem to be no longer usable due to namespaces
    set quizconf(quizchannel)        "#moxquizz"
    set quizconf(quizloglevel)       1

    # several global numbers
    set quizconf(maxranklines)       25
    set quizconf(tipcycle)           5
    set quizconf(useractivetime)     240
    set quizconf(userqbufferlength)  5
    set quizconf(winscore)           30
    set quizconf(overrunlimit)       15

    # timer delays in seconds
    set quizconf(askdelay)           15
    set quizconf(tipdelay)           30

    # safety features and other configs
    set quizconf(lastwinner_restriction)  yes
    set quizconf(lastwinner_max_games)    2
    set quizconf(overrun_protection)      yes
    set quizconf(colorize)                yes
    set quizconf(monthly_allstars)        yes
    set quizconf(channeltips)             yes
    set quizconf(pausemoderated)          no
    set quizconf(userquestions)           yes
    set quizconf(msgwhisper)              no
    set quizconf(channelrules)            yes
    set quizconf(prices)                  no
    set quizconf(stripumlauts)            no
    set quizconf(statslog)                yes
    set quizconf(aftergameaction)         newgame

    set quizconf(language)                en


    ##
    ###########################################################################

    ##
    ## stuff for the game state
    ##
    # values = stopped, paused, asked, waittoask, halted
    variable quizstate "halted"
    variable statepaused ""
    variable statemoderated ""
    variable usergame 0
    variable timeasked [unixtime]
    variable revoltmax 0
    # values = newgame, stop, halt, exit
    variable aftergame $quizconf(aftergameaction)
    variable channeltips ""
    variable channelrules ""
    variable prices ""

    #
    # variables for the ranks and user handling
    #
    variable timerankreset [unixtime]
    variable userlist
    variable allstarsarray
    variable revoltlist ""
    variable lastsolver ""
    variable lastsolvercount 0
    variable lastwinner ""
    variable lastwinnercount 0
    variable allstars_starttime 0
    variable ignore_for_userquest ""

    #
    # stuff for the question
    #
    variable tiplist ""
    variable theq
    variable qnumber 0
    variable qnum_thisgame 0
    variable userqnumber 0
    variable tipno 0
    variable qlist ""
    variable qlistorder ""
    variable userqlist ""

    #
    # doesn't fit elsewhere
    #
    variable whisperprefix "NOTICE"
    variable statsfilefd "closed"

    ###########################################################################
    #
    # commands for the questions
    #
    ###########################################################################

    ## something was said. Solution?
    proc moxquizz_pubm {nick host handle channel text} {
        global ::botnick

        variable quizstate
        variable timeasked
        variable theq
        variable aftergame
        variable usergame
        variable revoltlist
        variable lastsolver
        variable lastsolvercount
        variable lastwinner
        variable lastwinnercount
        variable userlist
        variable channeltips
        variable prices
        variable quizconf

        ## variable userarray
        set bestscore 0
        set lastbestscore 0
        set lastbest ""
        set authorsolved 0
        set waitforrank 0
        set gameend 0

        ## only accept chatter from quizchannel
        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return
        }

        ## record that the $nick spoke and create entries for unknown people
        user_getcreate $nick $host
        array set userarray $userlist($nick)
        set hostmask $userarray(mask)

        ## not in asking state?
        if {$quizstate != "asked"} {
            return
        }

        # nick has revolted
        if {[lsearch -exact $revoltlist $hostmask] != -1} {
            return
        }

        # tweak umlauts in input
        set text [tweak_umlauts $text]

        if {[regexp -nocase -- $theq(Regexp) $text]} {

            ## ignore games_max in a row winner
            if {[str_ieq [maskhost $host] $lastwinner]
                && $lastwinnercount >= $quizconf(lastwinner_max_games)
                && $quizconf(lastwinner_restriction) == "yes"} {
                irc_notc $nick [mc "No, you've won the last %d games." $quizconf(lastwinner_max_games)]
                return
            }

            # nick is author of userquest
            if {([info exists theq(Author)] && [str_ieq $nick $theq(Author)])
                || ([info exists theq(Hostmask)] && [str_ieq [maskhost $host] $theq(Hostmask)])} {
                set authorsolved 1
            }

            ## return if overrunprotection set and limit reached
            if {$quizconf(overrun_protection) == "yes"
                && $userarray(score) == 0
                && [rank_users_in_rank] > 2
                && [mx_overrun_limit_reached]} {
                # [pending] TRANSLATE!
                irc_notc $nick [mc "Sorry, overrun protection enabled.  Wait till end of game."]
                return
            }

            ## reset quiz state related stuff (and save userquestions)
            mx_answered
            set duration [duration $timeasked]

            # if it wasn't the author
            if {!$authorsolved} {
                ## save last top score for the test if reset is near (later below)
                set lastbest [lindex [lsort -command rank_cmp [array names userlist]] 0]
                if {$lastbest == ""} {
                    set lastbestscore 0
                } else {
                    array set aa $userlist($lastbest)
                    set lastbestscore $aa(score)
                }

                ## record nick for bonus points
                if {[str_ieq [maskhost $host] $lastsolver]} {
                    incr lastsolvercount
                } else {
                    set lastsolver [maskhost $host]
                    set lastsolvercount 1
                }

                ## save score (set started time to time of first point)
                incr userarray(score) $theq(Score)
                if {$userarray(score) == 1} {
                    set userarray(started) [unixtime]
                }
                set userlist($nick) [array get userarray]

                ## tell channel, that the question is solved
                log "--- solved after $duration by $nick with \"$text\", now $userarray(score) points"
                statslog "solved" [list [unixtime] $nick $duration $userarray(score) $theq(Score)]

                irc_say $channel [mc "%s solved after %s and now has %s<%d>%s points (+%d) on rank %d." "[banner] [botcolor nick]$nick[botcolor txt]" $duration [botcolor nick] $userarray(score) [botcolor txt] $theq(Score) [rank_get_pos $nick]]
                # remove area of tip generation tags
                regsub -all "\#(\[^\#\]*\)\#" $theq(Answer) "\\1" answer
                irc_say $channel [mc "%sThe answer was:%s%s" "[bannerspace] [botcolor txt]" "[botcolor norm] [botcolor answer]" $answer]
                ## honor good games!
                if {$lastsolvercount == 3} {
                    irc_say $channel [mc "%sThree in a row!" "[bannerspace] [botcolor txt]"]
                    log "--- $nick has three in a row."
                    statslog "tiar" [list [unixtime] $nick 3 0]
                } elseif {$lastsolvercount == 5} {
                    irc_say $channel [mc "%sCongratulation, five in a row! You receive an extra point." "[bannerspace] [botcolor txt]"]
                    log "--- $nick has five in a row.  score++"
                    statslog "tiar" [list [unixtime] $nick 5 1]
                    rank_set $botnick 0 "$nick +1"
                } elseif {$lastsolvercount == 10} {
                    irc_say $channel [mc "%sTen in a row! This is really rare, so you get 3 extra points." "[bannerspace] [botcolor txt]"]
                    log "--- $nick has ten in a row.  score += 3"
                    statslog "tiar" [list [unixtime] $nick 10 3]
                    rank_set $botnick 0 "$nick +3"
                } elseif {$lastsolvercount == 20} {
                    irc_say $channel [mc "%sTwenty in a row! This is extremely rare, so you get 5 extra points." "[bannerspace] [botcolor txt]"]
                    log "--- $nick has twenty in a row.  score += 5"
                    statslog "tiar" [list [unixtime] $nick 20 5]
                    rank_set $botnick 0 "$nick +5"
                }

                ## rankreset, if above winscore
                # notify if this comes near
                set best [lindex [lsort -command rank_cmp [array names userlist]] 0]
                if {$best == ""} {
                    set bestscore 0
                } else {
                    array set aa $userlist($best)
                    set bestscore $aa(score)
                }

                set waitforrank 0
                if {[str_ieq $best $nick] && $bestscore > $lastbestscore} {
                    array set aa $userlist($best)
                    # tell the end is near
                    if {$bestscore >= $quizconf(winscore)} {
                        set price "."

                        if {$quizconf(prices) == "yes"} {
                            set price " [lindex $prices [rand [llength $prices]]]"
                        }

                        irc_say $channel [mc "%s%s reaches %d points and wins%s" "[bannerspace] [botcolor txt]" $nick $quizconf(winscore) $price]
                        set now [unixtime]
                        if {[str_ieq [maskhost $host] $lastwinner]} {
                            incr lastwinnercount
                            if {$lastwinnercount >= $quizconf(lastwinner_max_games)
                                && $quizconf(lastwinner_restriction) == "yes"} {
                                irc_say $channel [mc "%s: since you won %d games in a row, you will be ignored for the next game." $nick $quizconf(lastwinner_max_games)]
                            }
                        } else {
                            set lastwinner [maskhost $host]
                            set lastwinnercount 1
                        }
                        # save $nick in allstars table
                        allstars_save $now [expr $now - $aa(started)] $bestscore $nick [maskhost $host]
                        statslog "gamewon" [list $now $nick $bestscore $quizconf(winscore) [expr $now - $aa(started)]]
                        rank_show_to_channel $botnick 0 {}
                        rank_reset $botnick {} {}
                        set gameend 1
                        set waitforrank 15
                    } elseif {$bestscore == [expr $quizconf(winscore) / 2]} {
                        irc_say $channel [mc "%sHalftime.  Game is won at %d points." \
                                               "[bannerspace] [botcolor txt]" $quizconf(winscore)]
                    } elseif {$bestscore == [expr $quizconf(winscore) - 10]} {
                        irc_say $channel [mc "%s%s has 10 points to go." "[bannerspace] [botcolor txt]" $best]
                    } elseif {$bestscore == [expr $quizconf(winscore) - 5]} {
                        irc_say $channel [mc "%s%s has 5 points to go." "[bannerspace] [botcolor txt]" $best]
                    } elseif {$bestscore >= [expr $quizconf(winscore) - 3]} {
                        irc_say $channel [mc "%s%s has %d point(s) to go." \
                                               "[bannerspace] [botcolor txt]" $best [expr $quizconf(winscore) - $bestscore]]
                    }

                    # show rank at 1/3, 2/3 of and 5 before winscore
                    set spitrank 1
                    foreach third [list [expr $quizconf(winscore) / 3] [expr 2 * $quizconf(winscore) / 3] [expr $quizconf(winscore) - 5]] {
                        if {$lastbestscore < $third && $bestscore >= $third && $spitrank} {
                            rank_show_to_channel $botnick 0 {}
                            set spitrank 0
                            set waitforrank 15
                        }
                    }

                }
            } else {
                ## tell channel, that the question is solved by author
                log "--- solved after $duration by $nick with \"$text\" by author"
                irc_say $channel [mc "%s solved own question after %s and gets no points, keeping %s<%d>%s points on rank %d." \
                                       "[banner] [botcolor nick]$nick[botcolor txt]" $duration [botcolor nick] $userarray(score) [botcolor txt] [rank_get_pos $nick]]
                # remove area of tip generation tags
                regsub -all "\#(\[^\#\]*\)\#" $theq(Answer) "\\1" answer
                irc_say $channel [mc "%sThe answer was:%s%s" "[bannerspace] [botcolor txt]" "[botcolor norm] [botcolor answer]" $answer]
            }

            ## Give some occasional tips
            if {$quizconf(channeltips) == "yes" && [rand 30] == 0} {
                irc_say $channel [mc "%sHint: %s" "[bannerspace] [botcolor txt]" [lindex $channeltips [rand [llength $channeltips]]]]
            }

            ## check if game has ended and react
            if {!$gameend || $aftergame == "newgame"} {
                # set up ask timer
                utimer [expr $waitforrank + $quizconf(askdelay)] ::mx_timer_ask
            } else {
                mx_aftergameaction
            }
        }
    }


    ## ask a question, start game
    proc moxquizz_ask {nick host handle channel arg} {
        global ::botnick

        variable qlist
        variable quizstate
        variable tipno
        variable timeasked
        variable theq
        variable qnum_thisgame
        variable timerankreset
        variable quizconf

        set anum 0
        set txt ""

        ## only accept chatter on quizchannel
        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return
        }

        switch -exact $quizstate {
            "paused" {
                irc_notc $nick [mc "Game is paused."]
                return 1
            }
            "stopped" {
                irc_notc $nick [mc "Game is stopped."]
                return 1
            }
        }

        ## record that $nick spoke (prevents desert detection from stopping,
        ## when an user joins and starts the game with !ask)
        if {![str_ieq $nick $botnick]} {
            user_getcreate $nick $host
        }

        ## any questions available?
        if {[llength $qlist] == 0 && [userquest_queuelength] == 0} {
            irc_say $channel [mc "%sSorry, my database is empty." "[banner] [botcolor boldtxt]"]
        } elseif {$quizstate == "asked"} {
            irc_notc $nick [questions_get_qtext "long"]
        } elseif {$quizstate == "waittoask" && ![str_ieq $nick $botnick]} {
            ## no, user has to be patient
            irc_notc $nick [mc "Please stand by, the next question comes in less than %d seconds." $quizconf(askdelay)]
        } else {

            ## select next question
            questions_select_next

            if {$qnum_thisgame == 1} {
                set timerankreset [unixtime]
                log "---- it's the no. $qnum_thisgame in this game, rank timer started at: $timerankreset"
                statslog "gamestart" [list $timerankreset]
            } else {
                log "---- it's the no. $qnum_thisgame in this game."
            }

            ## print question with an header
            irc_say $channel [questions_get_qtext "short"]

            set txt "[bannerspace] [botcolor question]"
            if {[info exists theq(Category)]} {
                set txt "$txt\($theq(Category)\) $theq(Question)"
            } else {
                set txt "$txt$theq(Question)"
            }
            irc_say $channel $txt

            set quizstate "asked"
            set tipno 0
            set timeasked [unixtime]
            ## set up tip timer
            utimer $quizconf(tipdelay) ::mx_timer_tip
        }
    }


    ## A user dislikes the question
    proc moxquizz_user_revolt {nick host handle channel text} {
        global ::botnick

        variable revoltlist
        variable revoltmax
        variable tipno
        variable quizstate
        variable userlist
        variable quizconf

        ## only accept revolts on the quizchannel
        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return
        }

        if {$quizstate == "asked"} {
            if {$tipno < 1} {
                irc_action $channel [mc "does not react on revolts before at least one tip was given."]
                return
            }

            ## ensure that the revolting user has an entry
            if {![info exists userlist($nick)]} {
                user_getcreate $nick $host
            }

            ## calculate people needed to make a revolution (50% of active users)
            log "--- a game runs, !revolt.  revoltmax = $revoltmax"
            if {$revoltmax == 0} {
                set now [unixtime]
                foreach u [array names userlist] {
                    array set afoo $userlist($u)
                    if {[expr $now - $afoo(lastspoken)] <= $quizconf(useractivetime)} {
                        incr revoltmax
                    }
                }
                log "---- active people are $revoltmax"
                # one and two player shoud revolt "both"
                if {$revoltmax > 2} {
                    set revoltmax [expr int(ceil(double($revoltmax) / 2))]
                }
                log "---- people needed for a successful revolution: $revoltmax"
            }

            # records known users dislike
            if {[info exists userlist($nick)]} {
                array set anarray $userlist($nick)
                set hostmask $anarray(mask)
                if {[lsearch -exact $revoltlist $hostmask] == -1} {
                    irc_quick_notc $nick [mc "Since you are revolting, you will be ignored for this question."]
                    irc_action $channel [mc "sees that %s and %d other dislike the question, you need %d people." \
                                              $nick [llength $revoltlist] $revoltmax]
                    lappend revoltlist $hostmask
                    set anarray(lastspoken) [unixtime]
                    set userlist($nick) [array get anarray]
                    log "--- $nick is revolting, revoltmax is $revoltmax"
                    statslog "revolt" [list [unixtime] $nick [llength $revoltlist] $revoltmax]
                }
            }
            if {[llength $revoltlist] >= $revoltmax} {
                set revoltmax 0
                log "--- solution forced by revolting."
                statslog "revoltsolve" [list [unixtime] $revoltmax]
                irc_action $channel [mc "will solve the question immediately."]
                solve $botnick 0 {}
            }
        }
    }


    ## pubm !score to report scores
    # [pending] move me to .. rank? allstars?
    proc moxquizz_pub_score {nick host handle channel arg} {
        variable allstarsarray
        variable userlist
        variable quizconf

        set allstarspos 0
        set pos 0
        set target ""
        set self 0

        if {![str_ieq $channel $quizconf(quizchannel)]} {
            return 0
        } else {
            set arg [string trim "$arg"]

            if {$arg != "" && $arg != $nick} {
                set target $arg
            } else {
                set target $nick
                set self 1
            }

            # report rank entries
            if {[info exists userlist($target)]} {
                array set userarray $userlist($target)
                if {$userarray(score)} {
                    # calc position
                    set pos [rank_get_pos $target]
                    if {$self} {
                        irc_notc $nick [mc "You made %d points and are on rank %d in the current game (%d more needed to win)." \
                                             $userarray(score) $pos [expr $quizconf(winscore) - $userarray(score)]]
                    } else {
                        irc_notc $nick [mc "%s made %d points and is on rank %d in the current game (%d more needed to win)." \
                                             $target $userarray(score) $pos [expr $quizconf(winscore) - $userarray(score)]]
                    }
                } else {
                    if {$self} {
                        irc_notc $nick [mc "You did not make any points in this game yet."]
                    } else {
                        irc_notc $nick [mc "%s did not make any points in this game yet." $target]
                    }
                }
            } else {
                if {$self} {
                    irc_notc $nick [mc "You are not yet listed for the current game."]
                } else {
                    irc_notc $nick [mc "%s is not yet listed for the current game." $target]
                }
            }

            # report allstars entries
            if {[allstars_get_pos $target]} {
                if {$self} {
                    irc_notc $nick [mc "You accumulated %5.3f points in the all-stars table and keep position %d after %d games." \
                                         [lindex $allstarsarray($target) 1] [allstars_get_pos $target] [lindex $allstarsarray($target) 0]]
                } else {
                    irc_notc $nick [mc "%s accumulated %5.3f points in the all-stars table and keep position %d after %d games." \
                                         $target [lindex $allstarsarray($target) 1] [allstars_get_pos $target] [lindex $allstarsarray($target) 0]]
                }
            } else {
                if {$self} {
                    irc_notc $nick [mc "You have not yet reached the all-stars table."]
                } else {
                    irc_notc $nick [mc "%s not yet reached the all-stars table." $target]
                }
            }

            return 1
        }
    }


    ###########################################################################
    #
    # Handling of certain events like +m
    #
    ###########################################################################

    ## react if channel gets moderated
    proc moxquizz_on_moderated {nick mask handle channel mode victim} {
        global ::botnick

        variable quizconf
        variable statemoderated
        variable quizstate

        if {$channel == $quizconf(quizchannel) && $quizconf(pausemoderated) == "yes"} {
            switch -exact -- $mode {
                "+m" {
                    if {$quizstate == "asked" || $quizstate == "waittoask"} {
                        set statemoderated $quizstate
                        log "--- Quiz paused since channel got moderated."
                        pause $botnick {} {}
                    }
                }
                "-m" {
                    if {$statemoderated != ""} {
                        set statemoderated ""
                        log "--- Quiz continued since channel no longer moderated."
                        cont $botnick {} {}
                    }
                }
                default {
                    log "!!! ERROR: can't handle mode: $mode on channel $channel."
                }
            }
        }
        return 1
    }

    ###########################################################################
    ###########################################################################
    ##
    ## internal routines
    ##
    ###########################################################################
    ###########################################################################


    ## ----------------------------------------------------------------------
    ## react on certain eggdrop events
    ## ----------------------------------------------------------------------

    proc eggdrop_event {type} {
        global ::botnick

        variable quizstate

        switch -exact $type {
            "prerehash" {
                log "--- Preparing for rehashing"
                if {$quizstate != "halted"} {
                    halt $botnick 0 {}
                }
                rank_save $botnick 0 {}
                userquest_save $botnick 0 "all"
                cfg_save $botnick 0 {}
                set tmp_logfiles [logfile]
                log "---- will reopen logfiles: $tmp_logfiles"
                log "--- Ready for rehashing"
            }
            "rehash" {
                # [pending] reopen logfiles, since this event happens
                # directly after the rehash
            }
        }
    }


    ## ----------------------------------------------------------------------
    ## mx.... generic tool functions and internal functions
    ## ----------------------------------------------------------------------

    ## func to act according to the value of $aftergame
    proc mx_aftergameaction {} {
        global ::botnick

        variable aftergame
        variable quizconf

        switch -exact $aftergame {
            "stop" {
                stop $botnick 0 {}
                set aftergame $quizconf(aftergameaction)
            }
            "halt" {
                halt $botnick 0 {}
                set aftergame $quizconf(aftergameaction)
            }
            "exit" {
                # sleep some milliseconds
                stop $botnick 0 {}
                irc_say $quizconf(quizchannel) [mc "Thanks for playing ppl, I'll exit now (and thanks for all the fish)."]
                utimer 2 ::mx_timer_aftergame_exit
            }
            "newgame" {
                # do nothing special here
                set aftergame $quizconf(aftergameaction)
            }
            default {
                log "ERROR: Bad aftergame-value: \"$aftergame\" -- halted"
                halt $botnick 0 {}
            }
        }
    }


    ## timer to shut the bot down from aftergameaction
    proc ::mx_timer_aftergame_exit {} {
        global ::botnick

        ::moxquizz::log "--- aftergame timer entered, queuesize = [queuesize]"

        if {[queuesize] != 0} {
            utimer 2 ::mx_timer_aftergame_exit
        } else {
            ::moxquizz::terminate $botnick 0 {}
        }
    }

    ## sets back all variables when a question is solved
    ## and goes to state waittoask (no timer set !!)
    proc mx_answered {} {
        variable quizstate
        variable tipno
        variable usergame
        variable qlistfinished
        variable userqnumber
        variable userqlist
        variable tiplist
        variable revoltlist
        variable revoltmax

        if {$quizstate == "asked"} {
            if {$usergame == 1} {
                ## save usergame
                # [pending] replace with call to userquest.tcl and
                # save each question to disc immediatly
                set pos [expr $userqnumber - 1]
                set alist [lindex $userqlist $pos]
                log "---- userquest stored: $alist"
                set i 0
                foreach t $tiplist {
                    lappend alist "Tip$i" [lindex $tiplist $i]
                    incr i
                }
                set userqlist [lreplace $userqlist $pos $pos $alist]
            }
            set quizstate "waittoask"
            set tipno 0
            set revoltlist ""
            set revoltmax 0

            foreach j [utimers] {
                if {[lindex $j 1] == "mx_timer_tip"} {
                    killutimer [lindex $j 2]
                }
            }
        }
    }

    # timer commands must be in global namespace since eggdrop doesn't
    # seem to support namespaces (up to 1.6.15)
    proc ::mx_timer_ask {} {
        global ::botnick

        ## variable ::moxquizz::quizconf

        namespace eval ::moxquizz {
            moxquizz_ask $botnick {} {} $quizconf(quizchannel) {}
        }
    }


    ## give a tip and check if channel is deserted!
    proc ::mx_timer_tip {} {
        global ::botnick

        namespace eval ::moxquizz {
            # variable userlist
            # variable aftergame
            # variable timerankreset
            # variable qnum_thisgame
            # variable quizconf

            set desert 1

            foreach u [array names userlist] {
                array set afoo $userlist($u)
                if {$afoo(lastspoken) >= [expr [unixtime] - ($quizconf(tipcycle) * $quizconf(tipdelay) * 2) - $quizconf(askdelay)]} {
                    set desert 0
                    break
                }
            }

            # ask at least one question
            if {$desert && $qnum_thisgame > 2} {
                irc_say $quizconf(quizchannel) [mc "%s Channel found deserted." [banner]]
                log "--- Channel found deserted."
                rank_reset $botnick {} {}
                if {$aftergame != "exit"} {
                    halt $botnick 0 {}
                } else {
                    mx_aftergameaction
                }
            } else {
                tip $botnick 0 {}
            }
        }
    }


    ## return score of the leading player in the current game
    proc mx_overrun_limit_reached {} {
        variable userlist
        variable quizconf

        foreach nick [array names userlist] {
            array set x $userlist($nick)
            if {$x(score) >= $quizconf(overrunlimit)} {
                return 1
            }
        }
        return 0
    }
}
