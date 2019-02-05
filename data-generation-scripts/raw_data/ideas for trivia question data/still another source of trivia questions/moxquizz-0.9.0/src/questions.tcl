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
## Handling of questions (reading from datafile, selecting, ...)
##

namespace eval ::moxquizz {

    ## read question data
    ## RETURNS:  0 if no error
    ##           1 if no file found
    proc questions_load {questionset} {
        variable qlist
        variable qlistorder
        variable qnumber
        variable datadir
        array set entry ""
        set tipno 0
        set key ""
        set errno 0
        # 0=out 1=in
        set readstate 0

        log "--- Loading questions."


        # keep the old questions safe
        set tmplist $qlist
        set qlist ""

        foreach datafile [glob -nocomplain "$datadir/questions*$questionset"] {

            set fd [open $datafile r]
            while {![eof $fd]} {
                set line [gets $fd]
                # an empty line terminates an entry
                if {[regexp "^ *$" $line]} {
                    if {$readstate == 1} {
                        # reject crippled entries
                        if {[info exists entry(Question)]
                            && [info exists entry(Answer)]} {
                            lappend qlist [array get entry]
                        } else {
                            log "[array get entry] not complete."
                        }
                        set tipno 0
                        unset entry
                    }
                    set readstate 0
                } elseif {![regexp "^#.*" $line]} {
                    set readstate 1
                    set data [split $line {:}]
                    if {![regexp "(Answer|Author|Category|Comment|Level|Question|Regexp|Score|Tip|Tipcycle)" [lindex $data 0]]} {
                        log "---- Key [lindex $data 0] unknown!"
                    } else {
                        set key [string trim [lindex $data 0]]
                        if {$key == "Tip"} {
                            set key "$key$tipno"
                            incr tipno
                        }
                        set entry($key) [string trim [::join [lrange $data 1 end] ":"]]
                    }
                }
            }
            close $fd

            log "---- now [llength $qlist] questions, added $datafile"
        }

        if {[llength $qlist] == 0} {
            set qlist $tmplist
            log "----- reset to prior questions ([llength $qlist] ones)."
            set errno 1
        }

        log "--- Questions loaded."

        set qlistorder ""
        return $errno
    }


    ## returns question numbers (guaranteed to return each number once before starting over)
    proc questions_next_qnumber {} {
        variable qlistorder
        variable qlist

        if {[llength $qlistorder] < 1} {
            for {set i 0} {$i < [llength $qlist]} {incr i} {
                lappend qlistorder "$i"
            }
        }
        set pos [rand [llength $qlistorder]]
        set value [lindex $qlistorder $pos]
        set qlistorder [lreplace $qlistorder $pos $pos]
        return $value
    }


    ## Tool function to get the question introduction text
    proc questions_get_qtext {fmt} {
        variable theq
        variable qnum_thisgame
        variable timeasked
        variable usergame

        set qtext [list "The question no. %d is" \
                       "The question no. %d is worth %d points" \
                       "The question no. %d by %s is" \
                       "The question no. %d by %s is worth %d points" \
                       "The user question no. %d is" \
                       "The user question no. %d is worth %d points" \
                       "The user question no. %d by %s is" \
                       "The user question no. %d by %s is worth %d points" \
                       "The level %s question no. %d is" \
                       "The level %s question no. %d is worth %d points" \
                       "The level %s question no. %d by %s is" \
                       "The level %s question no. %d by %s is worth %d points" \
                       "The level %s user question no. %d is" \
                       "The level %s user question no. %d is worth %d points" \
                       "The level %s user question no. %d by %s is" \
                       "The level %s user question no. %d by %s is worth %d points" ]


        ## game runs, tell user the question via msg
        set qtextnum 0
        set txt [list $qnum_thisgame]

        if {[info exists theq(Level)]} {
            incr qtextnum 8
            set txt [linsert $txt 0 $theq(Level)]
        }

        if {$usergame == 1} { incr qtextnum 4 }

        if {[info exists theq(Author)]} {
            incr qtextnum 2
            lappend txt $theq(Author)
        }

        if {$theq(Score) > 1} {
            incr qtextnum 1
            lappend txt $theq(Score)
        }

        set txt [linsert $txt 0 mc [lindex $qtext $qtextnum]]
        set txt [eval $txt]

        if {$fmt == "long"} {
            set txt [mc "%s, open for %s:" $txt [duration $timeasked]]
            if {[info exists theq(Category)]} {
                set txt "$txt \($theq(Category)\)"
            }
            set txt "$txt $theq(Question)"
        } else {
            set txt "$txt:"
        }

        return "[banner] [botcolor boldtxt]$txt"
    }

    ## set score of open question
    proc questions_set_score {handle idx arg} {
        ## [pending] obeye state!
        variable quizstate
        variable theq
        variable quizconf

        log "--- set_score by $handle: $arg"
        if {![regexp {^[0-9]+$} $arg]} {
            irc_dcc $idx "$arg not a valid number."
        } elseif {$arg == $theq(Score)} {
            irc_dcc $idx "New score is same as old score."
        } else {
            irc_dcc $idx "Setting score for the question to $arg points ([format "%+d" [expr $arg - $theq(Score)]])."
            irc_say $quizconf(quizchannel) [mc "%s Setting score for the question to %d points (%+d)." \
                                                 [banner] $arg [expr $arg - $theq(Score)]]
            set theq(Score) $arg
        }
        return 1
    }

    ## fill global variables theq and tiplist with a fresh question
    ## (consumes list of userquests first)
    proc questions_select_next {} {
        variable theq
        variable qlist
        variable usergame
        variable userqnumber
        variable userqlist
        variable userlist
        variable quizconf
        variable qnum_thisgame
        variable qnumber
        variable tiplist

        ##
        ## ok, now lets see, which question to ask (normal or user)
        ##

        ## clear old question
        foreach k [array names theq] {
            unset theq($k)
        }

        if {[userquest_queuelength]} {
            ## select a user question
            array set theq [lindex $userqlist $userqnumber]
            set usergame 1
            incr userqnumber
            log "--- asking a user question: $theq(Question)"
        } else {
            set ok 0
            while {!$ok} {
                array set theq [lindex $qlist [questions_next_qnumber]]
                set usergame 0

                # skip question if author is about to win
                if {[info exists theq(Author)] && [info exists userlist($theq(Author))]} {
                    array set auser $userlist($theq(Author))
                    if {$auser(score) >= [expr $quizconf(winscore) - 5]} {
                        log "--- skipping question number $qnumber, author is about to win"
                        ## clear old question
                        foreach k [array names theq] {
                            unset theq($k)
                        }
                    } else {
                        log "--- asking question number $qnumber: $theq(Question)"
                        set ok 1
                    }
                } else {
                    log "--- asking question number $qnumber: $theq(Question)"
                    set ok 1
                }
                incr qnumber
            }
        }
        incr qnum_thisgame

        ##
        ## ok, set some minimal required fields like score, regexp and the tiplist.
        ##

        ## set regexp to match
        if {![info exists theq(Regexp)]} {
            ## mask all regexp special chars except "."
            set aexp [tweak_umlauts $theq(Answer)]
            regsub -all "(\\+|\\?|\\*|\\^|\\$|\\(|\\)|\\\[|\\\]|\\||\\\\)" $aexp "\\\\\\1" aexp
            # get #...# area tags for tipgeneration as regexp
            regsub -all ".*\#(\[^\#\]*\)\#.*" $aexp "\\1" aexp
            set theq(Regexp) $aexp
        } else {
            set theq(Regexp) [tweak_umlauts $theq(Regexp)]
        }

        # protect embedded numbers
        if {[regexp "\[0-9\]+" $theq(Regexp)]} {
            set newexp ""
            set oldexp $theq(Regexp)
            set theq(Oldexp) $oldexp

            while {[regexp -indices "(\[0-9\]+)" $oldexp pair]} {
                set subexp [string range $oldexp [lindex $pair 0]  [lindex $pair 1]]
                set newexp "${newexp}[string range $oldexp -1 [expr [lindex $pair 0] - 1]]"
                if {[regexp -- $theq(Regexp) $subexp]} {
                    set newexp "${newexp}(^|\[^0-9\])${subexp}(\$|\[^0-9\])"
                } else {
                    set newexp "${newexp}${subexp}"
                }
                set oldexp "[string range $oldexp [expr [lindex $pair 1] + 1] [string length $oldexp]]"
            }
            set newexp "${newexp}${oldexp}"
            set theq(Regexp) $newexp
            #log "---- replaced regexp '$theq(Oldexp)' with '$newexp' to protect numbers."
        }

        ## set score
        if {![info exists theq(Score)]} {
            set theq(Score) 1
        }

        ## initialize tiplist
        set anum 0
        set tiplist ""
        while {[info exists theq(Tip$anum)]} {
            lappend tiplist $theq(Tip$anum)
            incr anum
        }
        # No tips found?  construct standard list
        if {$anum == 0} {
            set add "·"

            # extract area of tip generation tags (side effect sets answer)
            if {![regsub -all ".*\#(\[^\#\]*\)\#.*" $theq(Answer) "\\1" answer]} {
                set answer $theq(Answer)
            }

            ## use tipcycle from questions or
            ## generate less tips if all words shorter than $tipcycle
            if {[info exists theq(Tipcycle)]} {
                set limit $theq(Tipcycle)
            } else {
                set limit $quizconf(tipcycle)
                ## check if at least one word long enough
                set tmplist [lsort -command cmp_length -decreasing [split $answer " "]]
                # not a big word
                if {[string length [lindex $tmplist 0]] < $quizconf(tipcycle)} {
                    set limit [string length [lindex $tmplist 0]]
                }
            }

            for {set anum 0} {$anum < $limit} {incr anum} {
                set tiptext ""
                set letterno 0
                for {set i 0} {$i < [string length $answer]} {incr i} {
                    if {([expr [expr $letterno - $anum] % $quizconf(tipcycle)] == 0) ||
                        ([regexp "\[- \.,`'\"\]" [string range $answer $i $i] foo])} {
                        set tiptext "$tiptext[string range $answer $i $i]"
                        if {[regexp "\[- \.,`'\"\]" [string range $answer $i $i] foo]} {
                            set letterno -1
                        }
                    } else {
                        set tiptext "$tiptext$add"
                    }
                    incr letterno
                }
                lappend tiplist $tiptext
            }

            # reverse tips for numeric questions
            if {[regexp "^\[0-9\]+$" $answer]} {
                set foo ""
                for {set i [expr [llength $tiplist] - 1]} {$i >= 0} {set i [expr $i - 1]} {
                    lappend foo [lindex $tiplist $i]
                }
                set tiplist $foo
            }
        }
        # done.
    }



    ## reload questions
    proc questions_reload {handle idx arg} {
        variable qlist
        variable quizconf
        variable datadir

        set alist ""
        array set banks ""
        set suffix ""

        set arg [string trim $arg]
        if {$arg == ""} {
            # get question files
            set alist [glob -nocomplain "$datadir/questions.*"]

            # get suffixes
            foreach file $alist {
                regexp "^.*\\.(\[^\\.\]+)$" $file foo suffix
                set banks($suffix) 1
            }

            # report them
            irc_dcc $idx "There are the following question banks available (current: $quizconf(questionset)): [lsort [array names banks]]"
        } else {
            if {[questions_load $arg] != 0} {
                irc_dcc $idx "There was an error reading files for $arg."
                irc_dcc $idx "There are [llength $qlist] questions available."
            } else {
                irc_dcc $idx "Reloaded database, [llength $qlist] questions."
                set quizconf(questionset) $arg
            }
        }

        return 1
    }



    ###########################################################################
    #
    # User comment handling
    #
    ###########################################################################

    ## record a comment
    proc moxquizz_pub_comment {nick host handle channel arg} {
        variable commentsfile

        set arg [string trim $arg]
        if {$arg != ""} {
            set fd [open $commentsfile a]
            puts $fd "\[[ctime [unixtime]]\] $nick on $channel comments: $arg"
            close $fd

            irc_notc $nick [mc "Your comment was logged."]
        } else {
            irc_notc $nick [mc "Well, comment something *g*"]
        }
    }

    ## record a comment
    proc moxquizz_dcc_comment {handle idx arg} {
        variable commentsfile

        set arg [string trim $arg]
        if {$arg != ""} {
            set fd [open $commentsfile a]
            puts $fd "\[[ctime [unixtime]]\] $handle comments: $arg"
            close $fd

            irc_dcc $idx "Your comment was logged."
        } else {
            irc_dcc $idx "Well, comment something *g*"
        }
    }
}
