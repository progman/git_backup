#!/bin/bash


export GIT_BACKUP_DIR='/tmp/git_backup'; # dir for backups
#export GIT_BACKUP_FLAG_USE_GZIP=1;       # use gzip,  default auto
#export GIT_BACKUP_FLAG_USE_BZIP2=1;      # use bzip2, default auto
#export GIT_BACKUP_FLAG_USE_XZ=1;         # use xz,    default auto
#export GIT_BACKUP_MAX_ITEM_COUNT=0;      # max backups count. default 0 - disable
#export GIT_BACKUP_FLAG_SMALL_AND_SLOW=0; # delete temporary cache. default 0 - disable


#export GIT_BACKUP_REPO_LIST='REPO1, REPO2 BRANCH1 BRANCH2, REPO3, REPO4 BRANCH1';
# this is repo list
# REPO1 - get ALL branch
# REPO2 - get ONLY BRANCH1 and BRANCH2
# REPO3 - get ALL branch
# REPO4 - get ONLY BRANCH1
export GIT_BACKUP_REPO_LIST="\
git://github.com/progman/gitbash.git, \
git://github.com/progman/git_backup.git master \
";

./git_backup.sh
