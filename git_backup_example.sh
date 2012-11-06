#!/bin/bash

mkdir /tmp/git_backup;
cp ./git_backup.list /tmp/git_backup/;

#export GIT_BACKUP_FLAG_USE_GZIP=1;       # use only gzip,  default auto
#export GIT_BACKUP_FLAG_USE_BZIP2=1;      # use only bzip2, default auto
#export GIT_BACKUP_FLAG_USE_XZ=1;         # use only xz,    default auto
#export GIT_BACKUP_MAX_ITEM_COUNT=0;      # max backups count. default 0 - disable
#export GIT_BACKUP_FLAG_SMALL_AND_SLOW=0; # delete temporary cache. default 0 - disable

export GIT_BACKUP_DIR='/tmp/git_backup'; # dir for backups
export GIT_BACKUP_REPO_LIST="/tmp/git_backup/git_backup.list"; # repo list, see git_backup.list

./git_backup.sh
