### moxqfun.tcl -- funstuff for the MoxQuiz quizbot
##
### Author: Moxon <moxon@meta-x.de> (AKA Sascha Lüdecke)
##
### Credits:  Many, see README for a complete list
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


set version_moxfun "0.9.4-pre0"


###########################################################################
##
## global variables, config here! (see README for a description)

# stuff for the funcode
variable fundatadir	    moxquizz/intl/en
variable funstuff_enabled   1
variable roll_allowed       1
variable harteierfile       $fundatadir/harteier.txt
variable weicheierfile      $fundatadir/weicheier.txt
variable phrasefile         $fundatadir/phrases.txt

## you should not need to change the stuff below.
##
###########################################################################


##
## funstuff variables
##
variable harteilist ""
variable weicheilist ""
variable phraselist ""
variable fun_ordered

##
## variables in case moxquizz is not used.  You don't need to change them,
## but they must be there.
##
namespace eval ::moxquizz {
    variable quizstate ""
    variable quizconf
}

# funstuff
bind dcc P !fun moxfun_onoff
bind dcc P !roll moxfun_roll_onoff

bind pub - !amok moxfun_amok
bind pub - !applause moxfun_applause
bind pub - !assimilate moxfun_assimilate
bind pub - !blush moxfun_blush
bind pub - !bow moxfun_bow
bind pub - !cry moxfun_cry
bind pub - !damn moxfun_damn
bind pub - !fast moxfun_fast
bind pub - !hartei moxfun_hartei
bind pub - !hossa moxfun_hossa
bind pub - !hug moxfun_hug
bind pub - !kiss moxfun_kiss
bind pub - !miss moxfun_miss
bind pub - !order moxfun_order
bind pub - !phrase moxfun_phrase
bind pub - !relax moxfun_relax
bind pub - !roll moxfun_roll
bind pub - !smoke moxfun_smoke
bind pub - !steal moxfun_steal
bind pub - !strike moxfun_strike
bind pub - !weichei moxfun_weichei


###########################################################################
#
# funstuff control commands
#
###########################################################################

proc moxfun_onoff {handle idx arg} {
    global funstuff_enabled

    set arg [string trim $arg]

    if {$arg == "" || ![regexp "(on|off)" $arg]} {
	mxirc_dcc $idx "Please provide one of (on|off) as parameter.  Funstuff currently is [expr $funstuff_enabled?"enabled":"disabled"]."
    } else {
	if {$arg == "on"} {
	    set funstuff_enabled 1
	    putlog "--- funstuff enabled by $handle."
	    mxirc_dcc $idx "Funstuff is now enabled."
	    mxirc_say_everywhere "Funstuff is now enabled."
	} else {
	    set funstuff_enabled 0
	    putlog "--- funstuff disabled by $handle."
	    mxirc_dcc $idx "Funstuff is now disabled."
	    mxirc_say_everywhere "Funstuff is now disabled."
	}
    }
    return 1
}


proc moxfun_roll_onoff {handle idx arg} {
    global funstuff_enabled roll_allowed

    set arg [string trim $arg]

    if {$arg == "" || ![regexp "(on|off)" $arg]} {
	mxirc_dcc $idx "Please provide one of (on|off) as parameter.  !roll currently is [expr $funstuff_enabled?"enabled":"disabled"]."
    } else {
	if {$arg == "on"} {
	    set roll_allowed 1
	    putlog "--- !roll enabled by $handle."
	    mxirc_dcc $idx "!roll enabled."
	    mxirc_say_everywhere "!roll is now enabled."
	} else {
	    set roll_allowed 0
	    putlog "--- !roll disabled by $handle."
	    mxirc_dcc $idx "!roll disabled."
	    mxirc_say_everywhere "!roll is now disabled."
	}
    }
    return 1
}



## Initialize the funstuff (under all circumstances)
proc moxfun_init {} {
    global harteilist harteierfile weicheilist weicheierfile
    global phraselist phrasefile fundatadir
    variable fd
    variable line

    set harteierfile       $fundatadir/harteier.txt
    set weicheierfile      $fundatadir/weicheier.txt
    set phrasefile         $fundatadir/phrases.txt

    putlog "--- Initializing funstuff ..."

    ## harteier
    set harteilist ""
    if {[file readable $harteierfile]} {
	set fd [open $harteierfile r]
	while {![eof $fd]} {
	    set line [gets $fd]
	    if {![regexp "^#.*" $line] && ![regexp "^ *$" $line]} {
		lappend harteilist [string trim $line]
	    }
	}
	close $fd

	putlog "---- read !hartei file, [llength $harteilist] entries."
    } else {
	putlog "---- could not read !hartei file: \"$harteierfile\"."
    }

    ## weicheier
    set weicheilist ""
    if {[file readable $weicheierfile]} {
	set fd [open $weicheierfile r]
	while {![eof $fd]} {
	    set line [gets $fd]
	    if {![regexp "^#.*" $line] && ![regexp "^ *$" $line]} {
		lappend weicheilist [string trim $line]
	    }
	}
	close $fd

	putlog "---- read !weichei file, [llength $weicheilist] entries."
    } else {
	putlog "---- could not read !weichei file: \"$weicheierfile\"."
    }


    ## phrases
    set phraselist ""
    if {[file readable $phrasefile]} {
	set fd [open $phrasefile r]
	while {![eof $fd]} {
	    set line [gets $fd]
	    if {![regexp "^#.*" $line] && ![regexp "^ *$" $line]} {
		lappend phraselist [string trim $line]
	    }
	}
	close $fd

	putlog "---- read !phrase file, [llength $phraselist] entries."
    } else {
	putlog "---- could not read !phrase file: \"$phrasefile\"."
    }

    putlog "--- Initializing funstuff ... done."
}


###########################################################################
#
#  fun commands
#
###########################################################################


proc moxfun_amok {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set text [string trim $text]

    if {$text != ""} {
	if {[onchan $text $channel]} {
	    set txt "chains $text to the channel-heating as requested."
	} else {
	    set txt "sees: $nick fumbles while trying to chain $text and gets chained."
	}
    } else {
	set txt "chains $nick to the channel-heating."
    }

    mxirc_action $channel $txt
}


proc moxfun_applause {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set arg [string trim $text]
    if {$arg != "" && [onchan $arg $channel]} {
	    set txt "sees: $nick applauds $arg."
    } else {
	set txt "sees: The audience applauds."
    }

    if {[rand 10] > 6} {
	set txt "$txt  Wow, standing ovations!"
    }
    mxirc_action $channel $txt
}


proc moxfun_assimilate {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    if {[rand 10] > 7} {
	mxirc_say $channel "Resistance wasn't futile!"
	return
    }

    set arg [string trim $text]
    if {$arg != ""} {
	if {[mx_str_ieq $arg $nick]} {
	    set txt "sees: $nick, you can't assimilate yourself.  Think about it!"
	} elseif {[onchan $arg $channel]} {
	    set txt "sees: $nick assimilates $arg.  Resistance is futile!"
	} else {
	    set txt "sees: $nick tries to assimilate $arg ... not found.  Check your bionic implants."
	}
    } else {
	set txt "assimilates $nick."
    }

    if {[rand 10] > 7 && $arg != "" && [onchan $arg $channel]} {
	set txt "$txt  YES, another cube filled."
    }
    mxirc_action $channel $txt
}


proc moxfun_blush {nick host handle channel arg} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set arg [string trim $arg]

    set tlist [list "$nick blushes."\
	    "$nick crimsons."\
	    "$nick turns red like a tomato."\
	    "$nick blushes, how cute!"\
	    "$nick blushes.  It's a nice, deep red."]

    if {$arg != "" && [onchan $arg $channel]} {
	set txt "sees: $nick makes $arg blush."
    } else {
	set txt "sees: [lindex $tlist [rand [llength $tlist]]]"
    }

    mxirc_action $channel $txt

}

proc moxfun_bow {nick host handle channel arg} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set arg [string trim $arg]

    set tlist [list "Hey, you find a cyberpenny on the channel floor."\
	    "Hey, you find a cyberpenny on the channel floor and take it.  Cheapskate!"\
	    "Your nose touches the dusty floor and you have to sneeze."\
	    "You clothes derange ... funny, an underwear with pink little flowers on it."\
	    "The channel considers you as very polite."]

    set txt "sees: $nick bows deeply"
    if {$arg != ""} {
	if {[mx_str_ieq $arg $nick]} {
	    ## SIDE EXIT!
	    mxirc_action $channel "sees: $nick makes a reflexive bow ... and disappears in a puff of logic."
	    return
	} elseif {[onchan $arg $channel]} {
	    set txt "$txt before $arg."
	} else {
	    set txt "$txt."
	}
    } else {
	set txt "$txt."
    }

    if {[rand 10] > 7} {
	set txt "$txt  [lindex $tlist [rand [llength $tlist]]]"
    }

    mxirc_action $channel $txt
}


proc moxfun_cry {nick host handle channel text} {
    global funstuff_enabled botnick

    if {!$funstuff_enabled} {
	return
    }

    set tlist [list "$nick starts to weep.  Poor little!"\
                  "$nick bursts into tears."\
                  "$nick cries."]

    set txt "sees: [lindex $tlist [rand [llength $tlist]]]"

    mxirc_action $channel $txt

    switch [rand 7] {
        0 { mxirc_action $channel "pats $nick.  C'mon, world isn't that bad." }
        1 { mxirc_say $channel "here $nick, have a tissue." }
        2 {
            mxirc_say $channel "!hug $nick"
            moxfun_hug $botnick $host $handle $channel $nick
        }
        default {}
    }
}

proc moxfun_damn {nick host handle channel text} {
    global funstuff_enabled botnick

    if {!$funstuff_enabled} {
	return
    }

    set tlist [list "$nick hisses some strange words."\
	    "$nick looks extremely annoyed."\
	    "$nick cries out loud and tears the keyboard apart."\
	    "*CRASH*  $nick's monitor just smashed on the road."\
	    "*KNACK*  $nick bites the keyboard."\
	    "*GOSH*  $botnick cools down $nick with a buck of water."\
	    "$nick damns the world for being bad."\
	    "$nick wishes $botnick to hell."\
	    "$nick shouts: \"Hell's bell's, WHY?\""\
	    "$nick draws a disruptor and starts to fire at random targets."\
	    "$nick picks up a laser sword and swings it wildly.  Luckily no one gets hurt."]

    set txt "sees: [lindex $tlist [rand [llength $tlist]]]"

    mxirc_action $channel $txt
    if {$txt == "sees: $nick wishes $botnick to hell."} {
	mxirc_action $channel "will meet $nick there .... harharhar.  You hear devilish laughter ... but from where? "
    }

}


proc moxfun_fast {nick host handle channel text} {
    global funstuff_enabled botnick

    if {!$funstuff_enabled} {
	return
    }

    set tlist [list "$nick is scared - how can anyone answer a question that fast?"\
	    "$nick wishes (s)he could have finished reading that question before seeing the answer come up!"\
	    "$nick steps out of the time machine ... darn, missed that one again."\
	    "$nick must have blinked again - (s)he missed that one by hours!"]

    set txt "sees: [lindex $tlist [rand [llength $tlist]]]"

    mxirc_action $channel $txt
}


proc moxfun_hartei {nick host handle channel text} {
    global harteilist funstuff_enabled
    global botnick
    variable ::moxquizz::quizstate
    variable quizchannel [mx_fun_quizchannel]


    if {!$funstuff_enabled} {
	return
    }

    if {[llength $harteilist] == 0} {
	mxirc_notc $nick "Sorry, no hartei texts available."
	return
    }

    if {$quizstate == "asked" && [mx_str_ieq $channel $quizchannel]} {
	mxirc_notc $nick "No no, only between questions!"
	return
    }

    set text [string trim $text]

    if {$text != ""} {
	if {[mx_str_ieq $text $botnick] && [rand 10] > 4} {
	    set txt "laughs at you, you are a"
	} elseif {[onchan $text $channel]} {
	    set txt "sees: $nick calls $text a"
	} else {
	    set txt "sees: $nick failed to affront, must be a"
	}
    } else {
	set txt "calls $nick a"
    }

    set off "[lindex $harteilist [rand [llength $harteilist]]]"
    if {[string match "\[aeiouhAEIOUH\]" [string index $off 0]]} {
	append txt "n"
    }

    mxirc_action $channel "$txt $off."

}


proc moxfun_hossa {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set tlist [list "Oops, the last was a warp jump.  You find yourself floating in the delta quadrant."\
	    "You land on a peanut and slip."\
	    "Your head hits an hidden bumper and you receive double laser."\
	    "Your head hits an hidden bumper and you receive double speed."\
	    "Your head hits an hidden bumper and you receive the energy shield."\
	    "Your head hits an hidden bumper and you receive auto-beam."\
	    "You hit the light switch.  Darkness covers the channel."\
	    "You make a new world record in jumping.  Guiness is ringing your phone."\
	    "Some people see you jumping before your computer like crazy ... they call the men with the white jacket."]

    set txt "sees: You jump around happily."
    if {[rand 10] > 4} {
	set txt "$txt  [lindex $tlist [rand [llength $tlist]]]"
    }
    mxirc_action $channel $txt
}


proc moxfun_hug {nick host handle channel arg} {
    global funstuff_enabled botnick
    variable howto
    variable success 1

    if {!$funstuff_enabled} {
	return
    }

    set arg [string trim $arg]

    set tlist [list "hugs" "cuddles" "nuzzles" "snuggles" "draws close" "nestles"]
    set howto [lindex $tlist [rand [llength $tlist]]]

    if {[mx_str_ieq $arg $nick]} {
	set txt "sees: $nick, we know you love yourself."
	set success 0
    } elseif {$arg == ""} {
	set txt "$howto $nick"
    } elseif {[onchan $arg $channel]} {
	set txt "sees: $nick $howto $arg"
    } else {
	set txt "sees: You can't, since $arg appears not to be here."
	set success 0
    }

    # no success :)
    if {$success && [rand 10] > 7 && $arg != ""} {
        set tlist [list "$nick tries to hug $arg but struggles.  ${nick}s lips hit the feet ... indeed $nick KISSES ${arg}s feet."\
                "$nick runs to hug $arg, but misses.  Maybe you need new glasses?"\
                "$nick runs to hug $arg, hits the chandelier and has now sweetest dreams of $arg *boing*"\
                "$nick $howto $arg, opens the eyes and sees:  It's ${arg}s father."\
                "$nick $howto $arg, opens the eyes and sees:  It's ${arg}s mother."\
                "$nick $howto $arg, opens the eyes and sees:  It's ${arg}s fellow."\
                "$nick $howto $arg, but STOP: whats that on my neck?  $nick opens the eyes and realizes:  It's a VAMPIRE! *horrifying*"\
                "$nick $howto $arg, but STOP: whats that on my neck?  $nick opens the eyes and realizes:  It's a BORG! *getting assimilated*"]

	set txt "sees: [lindex $tlist [rand [llength $tlist]]]"
	set success 0
    }

    if {$success} {
	if {[rand 10] > 7} {
	    set tlist [list "warmly" "lovingly" "heartly" "fondly" "passionately"]
	    set txt "$txt [lindex $tlist [rand [llength $tlist]]]."
	} else {
	    set txt "$txt."
	}
    }

    mxirc_action $channel $txt
}



proc moxfun_kiss {nick host handle channel arg} {
    global funstuff_enabled botnick
    variable howto
    variable success 1

    if {!$funstuff_enabled} {
	return
    }

    set arg [string trim $arg]

    set tlist [list "kisses" "busses"]
    set howto [lindex $tlist [rand [llength $tlist]]]

    if {[mx_str_ieq $arg $nick]} {
	set txt "sees: $nick, we know you love yourself."
	set success 0
    } elseif {$arg == ""} {
	set txt "$howto $nick"
    } elseif {[onchan $arg $channel]} {
	set txt "sees: $nick $howto $arg"
    } else {
	set txt "sees: You can't, since $arg appears not to be here."
	set success 0
    }

    # no success :)
    if {$success && [rand 10] > 7 && $arg != ""} {
        set tlist [list "$nick tries to kiss $arg but struggles.  ${nick}s lips hit the feet ... indeed $nick KISSES ${arg}s feet."\
                "$nick rushes to $howto $arg, but misses.  Maybe you need new glasses?"\
                "$nick $howto $arg, opens the eyes and sees:  It's ${arg}s father."\
                "$nick $howto $arg, opens the eyes and sees:  It's ${arg}s mother."\
                "$nick $howto $arg, opens the eyes and sees:  It's ${arg}s fellow."]

	set txt "sees: [lindex $tlist [rand [llength $tlist]]]"
	set success 0
    }

    mxirc_action $channel $txt
}


proc moxfun_miss {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set txt "sees: You hack wildly and miss."
    if {[rand 10] > 7} {
	set txt "$txt  Unluckily you strain a muscle."
    }
    mxirc_action $channel $txt
}


proc moxfun_order {nick host handle channel arg} {
    global funstuff_enabled botnick
    global fun_ordered
    variable order

    if {!$funstuff_enabled} {
	return
    }

    if {[info exists fun_ordered($channel)]} {
	mxirc_action $channel "won't order another round before the first one was served."
	return
    }

    set arg [string trim $arg]
    set txt "orders a round of"

    if  {$arg == ""} {
	## look at www.webtender.com for receipts of those
	set tlist [list "coffee" "vodka" "beer" "coke" "water" "lemon juice"\
	    "tea" "arabian coffee" "fresh air" "bot oil" "Cuba Libre"\
	    "Strawberry Magherita" "ACID" "Ambrosia" "Banana Milk Shake"\
	    "Bloody Mary" "the usual" "nectar"]
	set order [lindex $tlist [rand [llength $tlist]]]
    } else {
	set txt "sees: $nick $txt"
	set order $arg
        if {[rand 10] > 6} {
            set order "blessed $order"
        }
        if {[rand 10] > 7} {
            set order "$order (+[rand 5])"
        }
    }

    set txt "$txt $order."
    set fun_ordered($channel) $order
    mxirc_action $channel $txt
    utimer [expr 5 + [rand 10]] moxfun_orderserve
}


## timer target to deliver an order
proc moxfun_orderserve {} {
    global fun_ordered
    variable waiter "waiter"
    variable channel
    variable order

    if {[llength [array names fun_ordered]] == 0} {
	putlog "--- ERROR: moxfun_orderserve met an empty order list."
	return
    }

    set channel [lindex [array names fun_ordered] 0]
    set order $fun_ordered($channel)
    unset fun_ordered($channel)

    if {[rand 10] > 4} {
	set waiter "waitress"
    }

    if {[rand 10] > 8} {
	set txt "sees: The $waiter arrives and slips unluckily so that all of the $order covers the floor."
    } else {
	set txt "sees: The $waiter arrives and serves a round of $order."
    }
    mxirc_action $channel $txt
}


proc moxfun_phrase {nick host handle channel text} {
    global funstuff_enabled phraselist
    global botnick

    if {!$funstuff_enabled} {
	return
    }

    if {[llength $phraselist] == 0} {
	mxirc_notc $nick "Sorry, no phrases available."
	return
    }

    set txt "says:"
    set phrase [lindex $phraselist [rand [llength $phraselist]]]

    mxirc_action $channel "$txt $phrase"
}


proc moxfun_relax {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set tlist [list "Ouch, you slipped of the seat."\
	    "It smells burned ... did you turn of the cooker?"\
	    "You start to feel very comfortable."\
	    "Relaxing is a hard job, you have to stop to draw breath."]

    set txt "sees: $nick sits back and relaxes."

    if {[rand 10] > 4} {
	set txt "$txt  [lindex $tlist [rand [llength $tlist]]]"
    }

    mxirc_action $channel $txt
}


proc moxfun_roll {nick host handle channel text} {
    global roll_allowed funstuff_enabled
    variable a 0 b 0

    if {!$funstuff_enabled} {
	return
    }

    if {$roll_allowed && [rand 20] > 2} {
	set a [expr [rand 6] + 1]
	set b [expr [rand 6] + 1]
	mxirc_action $channel "rolls the dices for $nick (2d6): $a and $b = [expr $a + $b]."
    } else {
	mxirc_action $channel "*lol*  look, how $nick is rolling on the floor collecting dust..."
    }
}


proc moxfun_smoke {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set tlist [list "You drop your lighter and your feet start burning."\
	    "Smoking quizz does not enlight you."\
	    "thinks, that smoking quizz generally is a very bad idea."]
    mxirc_action $channel "sees: [lindex $tlist [rand [llength $tlist]]]"
}


proc moxfun_steal {nick host handle channel arg} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set arg [string trim $arg]

    set tlist [list "$nick is happy about a great steal!"\
	    "$nick is proud of having stolen this one."\
	    "$nick gains 100XP for the succesful steal.  Level up!"]

    if {$arg != "" && [onchan $arg $channel]} {
	set txt "sees: $nick steals another one from $arg."
    } else {
	set txt "sees: [lindex $tlist [rand [llength $tlist]]]"
    }

    mxirc_action $channel $txt

}

proc moxfun_strike {nick host handle channel text} {
    global funstuff_enabled

    if {!$funstuff_enabled} {
	return
    }

    set txt "sees: You hit it!"
    if {[rand 10] > 7} {
	set txt "$txt  Good Luck, its a full strike."
    }
    mxirc_action $channel $txt
}


proc moxfun_weichei {nick host handle channel text} {
    global weicheilist funstuff_enabled
    global botnick
    variable ::moxquizz::quizstate
    variable quizchannel [mx_fun_quizchannel]

    if {!$funstuff_enabled} {
	return
    }

    if {[llength $weicheilist] == 0} {
	mxirc_notc $nick "Sorry, no weichei texts available."
	return
    }

    if {$quizstate == "asked" && [mx_str_ieq $channel $quizchannel]} {
	mxirc_notc $nick "No no, only between questions!"
	return
    }

    set text [string trim $text]

    if {$text != ""} {
	if {[mx_str_ieq $text $botnick] && [rand 10] > 4} {
	    set txt "laughs at you, you are a"
	} elseif {[onchan $text $channel]} {
	    set txt "sees: $nick calls $text a"
	} else {
	    set txt "sees: $nick failed to affront, must be a"
	}
    } else {
	set txt "calls $nick a"
    }

    set off "[lindex $weicheilist [rand [llength $weicheilist]]]"
    if {[string match "\[aeiouhAEIOUH\]" [string index $off 0]]} {
	append txt "n"
    }

    mxirc_action $channel "$txt $off."
}


###########################################################################
#
# Bot speaking commands (mxirc_...)
#
###########################################################################


## say something on channel
proc mxirc_say {channel text} {
    putserv "PRIVMSG $channel :$text"
}

## say something on all channels
proc mxirc_say_everywhere {text} {
    foreach channel [channels] {
	if {[validchan $channel] && [botonchan $channel]} {
	    mxirc_say $channel $text
	}
    }
}

## act on all channels
proc mxirc_action_everywhere {text} {
    foreach channel [channels] {
	if {[validchan $channel] && [botonchan $channel]} {
	    mxirc_action $channel $text
	}
    }
}

## say something through another buffer
proc mxirc_quick {channel text} {
    putquick "PRIVMSG $channel :$text"
}

## act in some way (/me)
proc mxirc_action {channel text} {
    putserv "PRIVMSG $channel :\001ACTION $text\001"
}


## say something to a user
proc mxirc_msg {nick text} {
    global botnick
    if {![mx_str_ieq $botnick $nick]} {
	puthelp "PRIVMSG $nick :$text"
    }
}


## say something through another buffer
proc mxirc_quick_notc {nick text} {
    global botnick
    if {![mx_str_ieq $botnick $nick]} {
	putquick "NOTICE $nick :$text"
    }
}


## notice something to a user
proc mxirc_notc {nick text} {
    global botnick
    if {![mx_str_ieq $botnick $nick]} {
	puthelp "NOTICE $nick :$text"
    }
}



## notice something to a user
proc mxirc_dcc {idx text} {
    if {[valididx $idx]} {
	putdcc $idx $text
    }
}

###########################################################################
#
#  mx_....   tool functions
#
###########################################################################


## return if strings are equal case ignored
proc mx_str_ieq {a b} {
    if {[string tolower $a] == [string tolower $b]} {
        return 1
    } else {
        return 0
    }
}

## returns the quizchannel if it exists
proc mx_fun_quizchannel {} {
    variable ::moxquizz::quizconf


    if {[info exists quizconf(quizchannel)] } {
	return $quizconf(quizchannel)
    } else {
	return ""
    }

}


###########################################################################
#
# Initialize
#

moxfun_init
