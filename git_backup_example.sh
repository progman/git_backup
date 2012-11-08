#!/bin/bash

mkdir /tmp/git_backup &> /dev/null;                 # for example only, delete this
cp ./git_backup.list /tmp/git_backup/ &> /dev/null; # for example only, delete this

#export GIT_BACKUP_FLAG_USE_GZIP=1;       # use only gzip,  default auto
#export GIT_BACKUP_FLAG_USE_BZIP2=1;      # use only bzip2, default auto
#export GIT_BACKUP_FLAG_USE_XZ=1;         # use only xz,    default auto
#export GIT_BACKUP_MAX_ITEM_COUNT=0;      # max backups count. default 0 - disable
#export GIT_BACKUP_FLAG_SMALL_AND_SLOW=0; # delete temporary cache. default 0 - disable

export GIT_BACKUP_DIR='/tmp/git_backup'; # dir for backups
export GIT_BACKUP_REPO_LIST="/tmp/git_backup/git_backup.list"; # repo list, see git_backup.list

#GIT_BACKUP_FILELOG="git_backup.log.$(date +'%Y%m%d_%H%M%S')";
#./git_backup.sh 2>&1 >> "${GIT_BACKUP_DIR}/${GIT_BACKUP_FILELOG}";
./git_backup.sh;
