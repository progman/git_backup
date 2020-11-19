#!/bin/bash
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Just run for test it
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
mkdir /tmp/git_pusher &> /dev/null;                 # for example only, delete this
cp ./git_pusher.list /tmp/git_pusher/ &> /dev/null; # for example only, delete this

#export GIT_PUSHER_PULL_SSH_COMMAND='ssh -i /home/user/.ssh/other  -o IdentitiesOnly=yes -o StrictHostKeyChecking=no'; # it's not obligatory
#export GIT_PUSHER_PUSH_SSH_COMMAND='ssh -i /home/user/.ssh/id_rsa -o IdentitiesOnly=yes -o StrictHostKeyChecking=no'; # it's not obligatory

export GIT_PUSHER_CACHE_DIR='/tmp/git_pusher/GIT_PUSHER_CACHE_DIR';
export GIT_PUSHER_LIST='/tmp/git_pusher/git_pusher.list';

#GIT_PUSHER_FILELOG="git_pusher.log.$(date +'%Y%m%d_%H%M%S')";
#./git_pusher.sh 2>&1 >> "/tmp/${GIT_PUSHER_FILELOG}";
./git_pusher.sh
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
