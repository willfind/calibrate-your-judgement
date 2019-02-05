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


##################################################
## bindings


### Description:
##
## Command bindings and event handler setup
##
## We need absolute method names due to namespaces.

# bot running status
bind dcc P !init ::moxquizz::init
bind dcc P !stop ::moxquizz::stop
bind dcc P !halt ::moxquizz::halt
bind dcc P !pause ::moxquizz::pause
bind dcc P !cont ::moxquizz::cont
bind dcc P !reset ::moxquizz::reset
bind dcc m !exit ::moxquizz::terminate
bind dcc m !aftergame ::moxquizz::aftergame

# bot speaking and hopping stuff
bind dcc P !say ::moxquizz::say
bind dcc P !act ::moxquizz::action
bind dcc m !allsay ::moxquizz::say_everywhere
bind dcc m !allact ::moxquizz::action_everywhere
bind dcc Q !join ::moxquizz::join
bind dcc Q !part ::moxquizz::part
bind dcc Q !quizto ::moxquizz::quizto
bind dcc Q !quizleave ::moxquizz::quizleave

# commands for the questions
bind dcc P !solve ::moxquizz::solve
bind dcc P !tip ::moxquizz::tip
bind dcc P !skipuserquest ::moxquizz::userquest_skip
bind dcc Q !setscore ::moxquizz::questions_set_score

bind dcc m !qsave ::moxquizz::userquest_save
bind dcc Q !reload ::moxquizz::questions_reload


# status and configuration
bind dcc P !status ::moxquizz::status
bind dcc m !load ::moxquizz::cfg_load
bind dcc m !save ::moxquizz::cfg_save
bind dcc m !set ::moxquizz::cfg_set

# userquest and other user (public) commands
bind pubm - * ::moxquizz::moxquizz_pubm
bind pub - !ask ::moxquizz::moxquizz_ask
bind pub - !revolt ::moxquizz::moxquizz_user_revolt

bind msg - !userquest ::moxquizz::userquest_schedule
bind msg - !usercancel ::moxquizz::userquest_cancel
bind msg - !usertip ::moxquizz::userquest_tip
bind msg - !usersolve ::moxquizz::userquest_solve
bind pub P !nuq ::moxquizz::userquest_adm_ignore
bind pub P !uq ::moxquizz::userquest_adm_unignore
bind pub P !listnuq ::moxquizz::userquest_adm_listignores
bind pub P !clearnuq ::moxquizz::userquest_adm_clearignores

bind msg - !qhelp ::moxquizz::moxquizz_help
bind pub - !qhelp ::moxquizz::moxquizz_pub_help
bind pub - !score ::moxquizz::moxquizz_pub_score
bind pub - !rank ::moxquizz::rank_show_to_user
bind pub - !allstars ::moxquizz::allstars_show_to_user
bind pub - !comment ::moxquizz::moxquizz_pub_comment
bind dcc - !comment ::moxquizz::moxquizz_dcc_comment
bind msg - !rules ::moxquizz::moxquizz_rules
bind pub - !rules ::moxquizz::moxquizz_pub_rules
bind msg - !version ::moxquizz::moxquizz_version
bind pub - !version ::moxquizz::moxquizz_pub_version

# mini funstuff
bind pub - !hi ::moxquizz::moxquizz_pub_hi
bind ctcp - action ::moxquizz::moxquizz_purr

# commands to manage players and rank
bind dcc P !allstars ::moxquizz::allstars_show_to_channel
bind dcc m !allstarssend ::moxquizz::allstars_send
bind dcc m !allstarsload ::moxquizz::allstars_load
bind dcc P !rank ::moxquizz::rank_show_to_channel
bind dcc Q !rankdelete ::moxquizz::rank_delete
bind dcc m !rankload ::moxquizz::rank_load
bind dcc m !ranksave ::moxquizz::rank_save
bind dcc Q !rankreset ::moxquizz::rank_reset
bind dcc Q !rankset ::moxquizz::rank_set


# Some events the bot reacts on
bind nick - * ::moxquizz::user_nick_changed
bind join - * ::moxquizz::user_joined_channel
bind mode - "*m" ::moxquizz::moxquizz_on_moderated
bind evnt - prerehash ::moxquizz::eggdrop_event
bind evnt - rehash ::moxquizz::eggdrop_event

## DEBUG
bind dcc n !colors ::moxquizz::color_show
