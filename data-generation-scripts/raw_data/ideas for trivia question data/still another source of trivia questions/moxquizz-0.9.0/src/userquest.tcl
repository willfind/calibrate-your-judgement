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
## Handling of user posted questions
##


## Stuff to handle userquests
namespace eval ::moxquizz {

    ## schedule a userquest
    proc userquest_schedule {nick host handle arg} {
        variable userqlist
        variable ignore_for_userquest
        variable quizconf
        variable usebadwords
        variable badwords

        set uanswer ""
        set uquestion ""
        set umatch ""
        set tmptext ""

        if {$quizconf(userquestions) == "no"} {
            irc_notc $nick [mc "Sorry, userquestions are disabled."]
            return
        }

        if {[lsearch $ignore_for_userquest [string tolower $nick]] != -1 || [lsearch $ignore_for_userquest [maskhost $host]] != -1} {
            irc_notc $nick "Sorry, you are not allowed to post userquestions at this time."
            return
        }

        if {![onchan $nick $quizconf(quizchannel)]} {
            irc_notc $nick [mc "Sorry, you MUST be in the quizchannel to ask questions."]
        } else {
            if {[userquest_queuelength] >= $quizconf(userqbufferlength)} {
                irc_notc $nick [mc "Sorry, there are already %d user questions scheduled.  Try again later." $quizconf(userqbufferlength)]
            } elseif {[info exists usebadwords] && $usebadwords && [regexp -nocase "([join $badwords, "|"])" $arg]} {
                irc_notc $nick [mc "Sorry, your userquest would trigger the badwords detection and will not be asked."]
            } else {
                set arg [color_strip $arg]
                if {$quizconf(stripumlauts) == "yes"} {
                    set arg [tweak_umlauts $arg]
                }
                if {[regexp "^(.+)::(.+)::(.+)$" $arg foo uquestion uanswer umatch] || \
                        [regexp "(.+)::(.+)" $arg foo uquestion uanswer]} {
                    set uquestion [string trim $uquestion]
                    set uanswer [string trim $uanswer]
                    set alist [list "Question" "$uquestion" "Answer" "$uanswer" "Author" "$nick" "Date" [ctime [unixtime]] "TipGiven" "no"]
                    if {$umatch != ""} {
                        set umatch [string trim $umatch]
                        lappend alist "Regexp" "$umatch"
                        set tmptext [mc " (regexp \"%s\")" $umatch]
                    }
                    lappend userqlist $alist

                    irc_notc $nick [mc "Your quest \"%s\" is scheduled with answer \"%s\"%s and will be asked after %d questions." \
                                        $uquestion $uanswer $tmptext [expr [userquest_queuelength] - 1]]
                    log "--- Userquest scheduled by $nick: \"$uquestion\"."
                } else {
                    irc_notc $nick [mc "Wrong number of parameters.  Use alike <question>::<answer>::<regexp>.  The regexp is optional and used with care."]
                    irc_notc $nick [mc "You said: \"%s\".  I recognize this as: \"%s\" and \"%s\", regexp: \"%s\"." \
                                        $arg $uquestion $uanswer $umatch]
                    log "--- userquest from $nick failed with: \"$arg\""
                }
            }
        }
        return
    }


    ## usertip
    proc userquest_tip {nick host handle arg} {
        variable quizstate
        variable usergame
        variable theq
        variable quizconf

        if {[onchan $nick $quizconf(quizchannel)]} {
            log "--- Usertip requested by $nick: \"$arg\"."
            if {$quizstate == "asked" && $usergame == 1} {
                if {[info exists theq(Author)] && ![str_ieq $nick $theq(Author)]} {
                    irc_notc $nick [mc "No, only %s can give tips here!" $theq(Author)]
                } else {
                    tip $nick 0 $arg
                    if {$arg != ""} {
                        set theq(TipGiven) "yes"
                    }
                }
            } else {
                irc_notc $nick [mc "No usergame running."]
            }
        } else {
            irc_notc $nick [mc "Sorry, you MUST be in the quizchannel to give tips."]
        }
        return 1
    }


    ## usersolve
    proc userquest_solve {nick host handle arg} {
        variable quizstate
        variable usergame
        variable theq

        log "--- Usersolve requested by $nick."
        if {$quizstate == "asked" && $usergame == 1} {
            if {[info exists theq(Author)] && ![str_ieq $nick $theq(Author)]} {
                irc_notc $nick [mc "No, only %s can solve this question!" $theq(Author)]
            } else {
                solve $nick 0 {}
            }
        } else {
            irc_notc $nick [mc "No usergame running."]
        }
        return 1
    }


    ## usercancel
    proc userquest_cancel {nick host handle arg} {
        variable quizstate
        variable usergame
        variable theq
        variable userqnumber
        variable userqlist

        log "--- Usercancel requested by $nick."
        if {$quizstate == "asked" && $usergame == 1} {
            if {[info exists theq(Author)] && ![str_ieq $nick $theq(Author)]} {
                irc_notc $nick [mc "No, only %s can cancel this question!" $theq(Author)]
            } else {
                irc_notc $nick [mc "Your question is canceled and will be solved."]
                set theq(Comment) "canceled by user"
                solve "user canceling" 0 {}
            }
        } elseif {[userquest_queuelength]} {
            array set aq [lindex $userqlist $userqnumber]
            if {[str_ieq $aq(Author) $nick]} {
                irc_notc $nick [mc "Your question \"%s\" will be skipped." $aq(Question)]
                set aq(Comment) "canceled by user"
                set userqlist [lreplace $userqlist $userqnumber $userqnumber [array get aq]]
                incr userqnumber
            } else {
                irc_notc $nick [mc "Sorry, the next question is by %s." $aq(Author)]
            }
        } else {
            irc_notc $nick [mc "No usergame running."]
        }
        return 1
    }




    ## ignore nick!*@* and *!ident@*.subdomain.domain for userquests for 45 minutes
    proc userquest_adm_ignore {nick host handle channel arg} {
        variable quizconf
        variable ignore_for_userquest

        regsub -all " +" [string trim $arg] " " arg

        set nicks [split $arg]
        set n ""

        for {set pos 0} {$pos < [llength $nicks]} {incr pos} {
            set n [string tolower [lindex $nicks $pos]]
            irc_notc $nick "Ignoring userquestions from $n for 45 minutes."
            lappend ignore_for_userquest $n
            if {[onchan $n $quizconf(quizchannel)]} {
                lappend ignore_for_userquest [maskhost [getchanhost $n $quizconf(quizchannel)]]
            } else {
                lappend ignore_for_userquest "-!-@-"
            }

        }
        timer 45 userquest_timer_ignore_expire
        return 1
    }

    ## unignore nick!*@* and *!ident@*.subdomain.domain for userquests for 45 minutes
    proc userquest_adm_unignore {nick host handle channel arg} {
        ## replace each [split $arg] and associated hostmask with some impossible values
        variable quizconf
        variable ignore_for_userquest

        regsub -all " +" [string trim $arg] " " arg

        set nicks [split $arg]
        set n ""

        for {set pos 0} {$pos < [llength $nicks]} {incr pos} {
            set n [string tolower [lindex $nicks $pos]]
            set listpos [lsearch -exact $ignore_for_userquest $n]
            if {$listpos != -1} {
                set ignore_for_userquest [lreplace $ignore_for_userquest $listpos [expr $listpos + 1] "@" "-!-@-"]
                irc_notc $nick "User $n removed from ignore list for userquestions."
            } else {
                irc_notc $nick "User $n was not in the ignore list for userquestions."
            }
        }
        return 1
    }

    ## lists current names on ignore for userquestions
    proc userquest_adm_clearignores {nick host handle channel arg} {
        variable ignore_for_userquest
        for {set pos 0} {$pos < [llength $ignore_for_userquest]} {incr pos 2} {
            set ignore_for_userquest [lreplace $ignore_for_userquest $pos [expr $pos + 1] "@" "-!-@-"]
        }
        irc_notc $nick "Cleared ignore list for userquestions."
        return 1
    }

    ## lists current names on ignore for userquestions
    proc userquest_adm_listignores {nick host handle channel arg} {
        variable ignore_for_userquest
        variable nicks ""
        for {set pos 0} {$pos < [llength $ignore_for_userquest]} {incr pos 2} {
            if {[lindex $ignore_for_userquest $pos] != "@"} {
                lappend nicks [lindex $ignore_for_userquest $pos]
            }
        }
        if {$nicks != ""} {
            irc_notc $nick "Currently ignored for userquestions: $nicks"
        } else {
            irc_notc $nick "Currently ignoring nobody for userquestions."
        }
        return 1
    }

    ## removes the first two elements from ignore_for_userquest (nick and mask)
    proc userquest_timer_ignore_expire {} {
        variable ignore_for_userquest
        set ignore_for_userquest [lreplace $ignore_for_userquest 0 1]
    }

    ## skipuserquest  -- removes a scheduled userquest
    proc userquest_skip {handle idx arg} {
        variable userqnumber
        variable userqlist
        if {[userquest_queuelength]} {
            irc_dcc $idx "Skipping the userquest [lindex $userqlist $userqnumber]"
            incr userqnumber
        } else {
            irc_dcc $idx "No usergame scheduled."
        }
        return 1
    }


    ## saveuserquest  -- append all asked user questions to $userqfile
    proc userquest_save  {handle idx arg} {
        variable userqfile
        variable userqlist
        variable userqnumber

        set uptonum $userqnumber
        array set aq ""

        if {[llength $userqlist] == 0 || ($userqnumber == 0 && $arg == "")} {
            irc_dcc $idx "No user questions to save."
        } else {
            # save all questions?
            if {[string tolower [string trim $arg]] == "all"} {
                set uptonum [llength $userqlist]
            }

            log "--- Saving userquestions ..."
            if {[file exists $userqfile] && ![file writable $userqfile]} {
                irc_dcc $idx "Cannot save user questions to \"$userqfile\"."
                log "--- Saving userquestions ... failed."
            } else {
                set fd [open $userqfile a+]
                ## assumes, that userqlist is correct!!
                for {set anum 0} {$anum < $uptonum} {incr anum} {
                    set q [lindex $userqlist $anum]
                    # clear old values
                    foreach val [array names aq] {
                        unset aq($val)
                    }
                    array set aq $q

                    # write some first elements
                    foreach n [list "Question" "Answer" "Regexp"] {
                        if {[info exists aq($n)]} {
                            puts $fd "$n: $aq($n)"
                            unset aq($n)
                        }
                    }

                    # spit the rest
                    foreach n [lsort -dictionary [array names aq]] {
                        if {[regexp "^Tip\[0-9\]" $n]} {
                            if {$aq(TipGiven) == "yes"} {
                                puts $fd "$n: $aq($n)"
                            }
                        } else {
                            puts $fd "$n: $aq($n)"
                        }
                    }
                    puts $fd ""
                }
                close $fd

                # prune saved and asked questions
                for {set i 0} {$i < $userqnumber} {incr i} {
                    set userqlist [lreplace $userqlist 0 0]
                }

                irc_dcc $idx "Saved $userqnumber user questions."
                log "--- Saving userquestions ... done"

                ## reset userqnumber
                set userqnumber 0
            }
        }
        return 1
    }

    ## returns number of open userquests
    proc userquest_queuelength {} {
        variable userqlist
        variable userqnumber

        set num [expr [llength $userqlist] - $userqnumber]

        if {$num < 0} {
            return 0
        } else {
            return $num
        }
    }
}
