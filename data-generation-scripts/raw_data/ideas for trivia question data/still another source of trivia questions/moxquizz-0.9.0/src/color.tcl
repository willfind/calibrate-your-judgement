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
## Colorization of messages
##

namespace eval ::moxquizz {

    # return botcolor
    proc botcolor {thing} {
        variable quizconf
        if {$quizconf(colorize) != "yes"} {return ""}
        #      if {$thing == "question"} {return "\003[col dblue][col uline]"}
        #      if {$thing == "answer"} {return "\003[col dblue]"}
        #      if {$thing == "tip"} {return "\003[col dblue]"}
        if {$thing == "question"} {return "[color dblue white][col uline]"}
        if {$thing == "answer"} {return "[color dblue white]"}
        if {$thing == "tip"} {return "[color dblue white]"}
        if {$thing == "nick"} {return "[color lightgreen black]"}
        if {$thing == "nickscore"} {return "[color lightgreen blue]"}
        if {$thing == "highscore"} {return "\003[col turqois][col uline][col bold]"}
        #    if {$thing == "txt"} {return "[color red yellow]"}
        if {$thing == "txt"} {return "[color blue lightblue]"}
        if {$thing == "boldtxt"} {return "[col bold][color blue lightblue]"}
        if {$thing == "own"} {return "[color red black]"}
        if {$thing == "norm"} {return "\017"}
        if {$thing == "grats"} {return "[color purple norm]"}
        if {$thing == "score"} {return "[color blue lightblue]"}
        if {$thing == ""} {return "\003"}
    }

    # internal function, never used from ouside. (doesn't check colorize!)
    proc color {fg bg} {
        return "\003[col $fg],[col $bg]"
    }

    # taken from eggdrop mailinglist archive
    proc col {acolor} {
        variable quizconf
        if {$quizconf(colorize) != "yes"} {return ""}

        if {$acolor == "norm"} {return "00"}
        if {$acolor == "white"} {return "00"}
        if {$acolor == "black"} {return "01"}
        if {$acolor == "blue"} {return "02"}
        if {$acolor == "green"} {return "03"}
        if {$acolor == "red"} {return "04"}
        if {$acolor == "brown"} {return "05"}
        if {$acolor == "purple"} {return "06"}
        if {$acolor == "orange"} {return "07"}
        if {$acolor == "yellow"} {return "08"}
        if {$acolor == "lightgreen"} {return "09"}
        if {$acolor == "turqois"} {return "10"}
        if {$acolor == "lightblue"} {return "11"}
        if {$acolor == "dblue"} {return "12"}
        if {$acolor == "pink"} {return "13"}
        if {$acolor == "grey"} {return "14"}


        if {$acolor == "bold"} {return "\002"}
        if {$acolor == "uline"} {return "\037"}
        #    if {$color == "reverse"} {return "\022"}
    }


    ###########################################################################
    #
    # debug stuff
    #
    ###########################################################################

    proc color_show {handle idx arg} {
        variable quizconf

        irc_say $quizconf(quizchannel) "[banner] [botcolor norm]printing colors"

        if {$arg != ""} {
            irc_say $quizconf(quizchannel) "NORMAL:"

            irc_say $quizconf(quizchannel) "[color norm norm]norm"
            irc_say $quizconf(quizchannel) "[color black norm]black"
            irc_say $quizconf(quizchannel) "[color blue norm]blue"
            irc_say $quizconf(quizchannel) "[color green norm]green"
            irc_say $quizconf(quizchannel) "[color red norm]red"
            irc_say $quizconf(quizchannel) "[color brown norm]brown"
            irc_say $quizconf(quizchannel) "[color purple norm]purple"
            irc_say $quizconf(quizchannel) "[color orange norm]orange"
            irc_say $quizconf(quizchannel) "[color yellow norm]yellow"
            irc_say $quizconf(quizchannel) "[color blue norm]blue"

            irc_say $quizconf(quizchannel) "BOLD:"

            irc_say $quizconf(quizchannel) "[color norm norm][col bold]norm"
            irc_say $quizconf(quizchannel) "[color black norm][col bold]black"
            irc_say $quizconf(quizchannel) "[color blue norm][col bold]blue"
            irc_say $quizconf(quizchannel) "[color green norm][col bold]green"
            irc_say $quizconf(quizchannel) "[color red norm][col bold]red"
            irc_say $quizconf(quizchannel) "[color brown norm][col bold]brown"
            irc_say $quizconf(quizchannel) "[color purple norm][col bold]purple"
            irc_say $quizconf(quizchannel) "[color orange norm][col bold]orange"
            irc_say $quizconf(quizchannel) "[color yellow norm][col bold]yellow"
            irc_say $quizconf(quizchannel) "[color blue norm][col bold]blue"

            irc_say $quizconf(quizchannel) "BOLD underlined:"

            irc_say $quizconf(quizchannel) "[color norm norm][col bold][col uline]norm"
            irc_say $quizconf(quizchannel) "[color black norm][col bold][col uline]black"
            irc_say $quizconf(quizchannel) "[color blue norm][col bold][col uline]blue"
            irc_say $quizconf(quizchannel) "[color green norm][col bold][col uline]green"
            irc_say $quizconf(quizchannel) "[color red norm][col bold][col uline]red"
            irc_say $quizconf(quizchannel) "[color brown norm][col bold][col uline]brown"
            irc_say $quizconf(quizchannel) "[color purple norm][col bold][col uline]purple"
            irc_say $quizconf(quizchannel) "[color orange norm][col bold][col uline]orange"
            irc_say $quizconf(quizchannel) "[color yellow norm][col bold][col uline]yellow"
            irc_say $quizconf(quizchannel) "[color blue norm][col bold][col uline]blue"
            
            irc_say $quizconf(quizchannel) "[col bold] bold"
            irc_say $quizconf(quizchannel) "[col uline] uline"
        }

        irc_say $quizconf(quizchannel) "Botcolors:"

        irc_say $quizconf(quizchannel) "[botcolor nick]nick"
        irc_say $quizconf(quizchannel) "[botcolor nickscore]nickscore"
        irc_say $quizconf(quizchannel) "[botcolor highscore]highscore"
        irc_say $quizconf(quizchannel) "[botcolor txt]txt"
        irc_say $quizconf(quizchannel) "[botcolor own]own"
        irc_say $quizconf(quizchannel) "[botcolor norm]norm"
        irc_say $quizconf(quizchannel) "[botcolor ""]none"
        irc_say $quizconf(quizchannel) "[botcolor boldtxt]bold txt"
        irc_say $quizconf(quizchannel) "[botcolor question]question"
        irc_say $quizconf(quizchannel) "[botcolor answer]answer"
        irc_say $quizconf(quizchannel) "[botcolor grats]* Congrats *"
        irc_say $quizconf(quizchannel) "[botcolor tip]tip"
        irc_say $quizconf(quizchannel) "[botcolor score]score"
        return 1
    }


    ## strip color codes from a string
    proc color_strip {txt} {
        set result ""

        regsub -all "\[\002\017\]" $txt "" result
        regsub -all "\003\[0-9\]\[0-9\]?\(,\[0-9\]\[0-9\]?\)?" $result "" result

        return $result
    }
}
