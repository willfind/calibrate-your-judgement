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
## Basic IRC communication routines (speaking, actions, etc)
##

namespace eval ::moxquizz {

    ## ----------------------------------------------------------------------
    ##
    ## Joining and parting channels
    ##
    ## ----------------------------------------------------------------------

    ## hop to another channel
    proc join {handle idx arg} {
        variable quizconf
        if {[regexp -nocase "^(#\[^ \]+)( +.*)?" $arg foo channel arg]} {
            set channel [string tolower $channel]
            if {[validchan $channel] && [botonchan $channel]} {
                set txt "I am already on $channel."
                if {$channel == $quizconf(quizchannel)} {
                    set txt "$txt  It's the quizchannel."
                }
                irc_dcc $idx $txt
            } else {
                channel add $channel
                channel set $channel -inactive
                irc_dcc $idx "Joined channel $channel."
            }
        } else {
            irc_dcc $idx "Please specify the channel to join. \"$arg\" not recognized."
        }
    }


    ## part an channel
    proc part {handle idx arg} {
        variable quizconf
        if {[regexp -nocase "^(#\[^ \]+)( +.*)?" $arg foo channel arg]} {
            set channel [string tolower $channel]
            if {[validchan $channel]} {
                if {$channel == $quizconf(quizchannel)} {
                    irc_dcc $idx "Cannot leave quizchannel via part.  User !quizleave or !quizto to do this."
                } else {
                    channel set $channel +inactive
                    irc_dcc $idx "Left channel $channel."
                }
            } else {
                irc_dcc $idx "I am not on $channel."
            }
        } else {
            irc_dcc $idx "Please specify the channel to part. \"$arg\" not recognized."
        }
    }

    ## ----------------------------------------------------------------------
    ##
    ## Talking to quiz-channel or all channels
    ##
    ## ----------------------------------------------------------------------

    ## echo a text send by /msg
    ##
    ## if arg begins with # then first word is taken as channel to
    ## talk to
    proc say {handle idx arg} {
        global ::botnick

        variable funstuff_enabled
        variable quizconf

        set channel ""

        set arg [string trim $arg]
        if {[regexp -nocase "^(#\[^ \]+)( +.*)?" $arg foo channel arg]} {
            ## check if on channel $channel
            if {[validchan $channel] && ![botonchan $channel]} {
                irc_dcc $idx "Sorry, I'm not on channel \"$channel\"."
                return
            }
        } else {
            set channel $quizconf(quizchannel)
        }
        set arg [string trim $arg]

        irc_say $channel "$arg"
        variable unused "" cmd "" rest ""

        # if it was a fun command, execute it with some delay
        if {$funstuff_enabled &&
            [regexp "^(!\[^ \]+)(( *)(.*))?" $arg unused cmd waste spaces rest] &&
            [llength [bind pub - $cmd]] != 0} {
            if {$rest == ""} {
                set rest "{}"
            } else {
                set rest "{$rest}"
            }
            eval "[bind pub - $cmd] {$botnick} {} {} {$channel} $rest"
        }
    }


    ## say something on al channels
    proc say_everywhere {handle idx arg} {
        if {$arg != ""} {
            irc_say_everywhere $arg
        } else {
            irc_dcc $idx "What shall I say on every channel?"
        }
    }


    ## act as sent by /msg
    ##
    ## if arg begins with # then first word is taken as channel to act
    ## in
    proc action {handle idx arg} {
        variable quizconf
        set channel ""

        set arg [string trim $arg]
        if {[regexp -nocase "^(#\[^ \]+)( +.*)?" $arg foo channel arg]} {
            ## check if on channel $channel
            if {[validchan $channel] && ![botonchan $channel]} {
                irc_dc $idx "Sorry, I'm not on channel \"$channel\"."
                return
            }
        } else {
            set channel $quizconf(quizchannel)
        }
        set arg [string trim $arg]

        irc_action $channel "$arg"
    }


    ## say something on al channels
    proc action_everywhere {handle idx arg} {
        if {$arg != ""} {
            irc_action_everywhere $arg
        } else {
            irc_dcc $idx "What shall act like on every channel?"
        }
    }


    ## ----------------------------------------------------------------------
    ##
    ## low level stuff to communicate over IRC
    ##
    ## ----------------------------------------------------------------------

    ## say something on quizchannel
    proc irc_say {channel text} {
        putserv "PRIVMSG $channel :[obfs $text]"
    }

    ## say something on quizchannel (raw, no obfs)
    proc irc_rsay {channel text} {
        putserv "PRIVMSG $channel :$text"
    }

    ## say something on all channels
    proc irc_say_everywhere {text} {
        foreach channel [channels] {
            if {[validchan $channel] && [botonchan $channel]} {
                say $channel $text
            }
        }
    }


    ## act in some way (/me)
    proc irc_action {channel text} {
        putserv "PRIVMSG $channel :\001ACTION [obfs $text]\001"
    }


    ## act on all channels
    proc irc_action_everywhere {text} {
        foreach channel [channels] {
            if {[validchan $channel] && [botonchan $channel]} {
                action $channel $text
            }
        }
    }


    ## say something through another buffer
    proc irc_quick {channel text} {
        putquick "PRIVMSG $channel :$text"
    }


    ## say something to a user
    proc irc_msg {nick text} {
        global ::botnick
        if {![str_ieq $botnick $nick]} {
            puthelp "PRIVMSG $nick :$text"
        }
    }


    ## say something through another buffer
    proc irc_quick_notc {nick text} {
        global ::botnick
        variable whisperprefix
        if {![str_ieq $botnick $nick]} {
            putquick "$whisperprefix $nick :$text"
        }
    }


    ## notice something to a user (whisper)
    proc irc_notc {nick text} {
        global ::botnick
        variable whisperprefix
        if {![str_ieq $botnick $nick]} {
            puthelp "$whisperprefix $nick :$text"
        }
    }



    ## notice something to a user
    proc irc_dcc {idx text} {
        if {[valididx $idx]} {
            putdcc $idx $text
        }
    }
}
