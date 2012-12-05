#!/bin/bash

mkdir /tmp/git_backup &> /dev/null;                 # for example only, delete this
cp ./git_backup.list /tmp/git_backup/ &> /dev/null; # for example only, delete this

#export GIT_BACKUP_FLAG_USE_GZIP=0;      # use only gzip,  default 0 - auto
#export GIT_BACKUP_FLAG_USE_BZIP2=0;     # use only bzip2, default 0 - auto
#export GIT_BACKUP_FLAG_USE_XZ=0;        # use only xz,    default 0 - auto
#export GIT_BACKUP_MAX_ITEM_COUNT=0;     # max backups count. default 0 - disable
#export GIT_BACKUP_FLAG_REPO_CACHE=1;    # keep clone or unpack repo. big size and fast work. default 1 - enable
#export GIT_BACKUP_FLAG_VIEW_SIZE=1;     # view total backup size. default 1 - enable
#export GIT_BACKUP_FLAG_REPO_FSCK=1;     # fsck exist or unpack repo. default 1 - enable
#export GIT_BACKUP_FLAG_REPO_GC=0;       # garbage collect cache repo. default 0 - disable
#export GIT_BACKUP_FLAG_FORCE_PACK=0;    # pack repo anyway. default 0 - disable

export GIT_BACKUP_DIR='/tmp/git_backup'; # dir for backups
export GIT_BACKUP_REPO_LIST="/tmp/git_backup/git_backup.list"; # repo list, see git_backup.list

#GIT_BACKUP_FILELOG="git_backup.log.$(date +'%Y%m%d_%H%M%S')";
#./git_backup.sh 2>&1 >> "${GIT_BACKUP_DIR}/${GIT_BACKUP_FILELOG}";
./git_backup.sh;
