#!/bin/bash
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# 0.0.4
# Alexey Potehin http://www.gnuplanet.ru/doc/cv
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function check_prog()
{
    for i in ${CHECK_PROG_LIST};
    do
	if [ "$(which ${i})" == "" ];
	then
	    echo "ERROR: you must install \"${i}\"...";
	    exit 1;
	fi
    done
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function alarm()
{
    if [ "$(which beep)" != "" ];
    then
	beep -r 1 -f 3000;
    fi
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function kill_ring()
{
    if [ "${KILL_RING_MAX_ITEM_COUNT}" == "0" ] || [ "${KILL_RING_MAX_ITEM_COUNT}" == "" ];
    then
	return;
    fi


    KILL_RING_CUR_ITEM_COUNT=$(ls -1 "${KILL_RING_PATH}" | grep '\.tar' | sort | wc -l);

    if [ "${KILL_RING_CUR_ITEM_COUNT}" -gt "${KILL_RING_MAX_ITEM_COUNT}" ];
    then
	echo "- time to kill old...";

	KILL_RING_ITEM_COUNT="${KILL_RING_CUR_ITEM_COUNT}";

	(( KILL_RING_ITEM_COUNT -= KILL_RING_MAX_ITEM_COUNT ));


	if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
	then
	    echo "kill_ring(): KILL_RING_MAX_ITEM_COUNT=\"${KILL_RING_MAX_ITEM_COUNT}\"";
	    echo "kill_ring(): KILL_RING_CUR_ITEM_COUNT=\"${KILL_RING_CUR_ITEM_COUNT}\"";
	    echo "kill_ring(): KILL_RING_ITEM_COUNT=\"${KILL_RING_ITEM_COUNT}\"";
	fi


	ls -1 "${KILL_RING_PATH}" | grep '\.tar' | head -n "${KILL_RING_ITEM_COUNT}" | xargs rm -rf --;
    fi
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function get_git()
{
    NAME="$(echo ${URL} | sed -e 's/\.git//g' | sed -e 's/.*:\|.*\///g')";


    echo "- get project \"${NAME}\" from \"${URL}\"";
    git clone "${URL}" "${NAME}" &> /dev/null;
    if [ "${?}" != "0" ];
    then
	echo "ERROR: unknown error";
	exit 1;
    fi
    cd "${NAME}";


# choice all branches if BRANCH_LIST is empty
    if [ "${BRANCH_LIST}" == "" ];
    then
	if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
	then
	    echo "get_git(): detect empty BRANCH_LIST";
	fi

	for BRANCH in $(git branch -r | sed -e 's/\ *origin\///g' | grep -v '\ ->' | grep -v '^master$');
	do
	    if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
	    then
		echo "get_git(): add branch:\"${BRANCH}\"";
	    fi

	    if [ "${BRANCH_LIST}" != "" ];
	    then
		BRANCH_LIST="${BRANCH_LIST} ";
	    fi
	    BRANCH_LIST="${BRANCH_LIST} ${BRANCH}";
	done
    fi


    if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
    then
	echo "get_git(): use BRANCH_LIST:\"${BRANCH_LIST}\"";
    fi


    for BRANCH in ${BRANCH_LIST};
    do
	if [ "${BRANCH}" == "" ] || [ "${BRANCH}" == "master" ];
	then
	    continue;
	fi


	FLAG_GLOBAL_FOUND="$(git branch -r | sed -e 's/\ *origin\///g' | grep "^${BRANCH}$" | wc -l)";
	if [ "${FLAG_GLOBAL_FOUND}" == "0" ];
	then
	    echo "  - ignore branch \"${BRANCH}\"";
	    continue;
	fi


	FLAG_LOCAL_FOUND="$(git branch | sed -e 's/\*\ //g' | grep "${BRANCH}" | wc -l)";
	if [ "${FLAG_LOCAL_FOUND}" == "0" ];
	then
	    echo "  - get branch \"${BRANCH}\"";
	    git checkout -b "${BRANCH}" remotes/origin/"${BRANCH}" &> /dev/null;
	    if [ "${?}" != "0" ];
	    then
		echo "ERROR: unknown error";
		exit 1;
	    fi
	fi
    done


    cd ..;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function parse()
{
    REPO_ITEM_INDEX=1;
    while true;
    do
	REPO_ITEM=$(echo "${GIT_BACKUP_REPO_LIST}" | awk -F',' "{print \$${REPO_ITEM_INDEX}}");

	if [ "${REPO_ITEM}" == "" ];
	then
	    break;
	fi

	if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
	then
	    echo "parse(): REPO_ITEM=\"${REPO_ITEM}\"";
	fi


	URL='';
	BRANCH_LIST='';


	BRANCH_INDEX=1;
	while true;
	do
	    BRANCH=$(echo "${REPO_ITEM}" | awk -F' ' "{print \$${BRANCH_INDEX}}");

	    if [ "${BRANCH}" == "" ];
	    then
		break;
	    fi


	    if [ "${BRANCH_INDEX}" == "1" ];
	    then
		URL="${BRANCH}";
	    else
		if [ "${BRANCH_LIST}" != "" ];
		then
		    BRANCH_LIST="${BRANCH_LIST} ";
		fi
		BRANCH_LIST="${BRANCH_LIST} ${BRANCH}";
	    fi


	    if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
	    then
		echo "parse(): BRANCH=\"${BRANCH}\"";
	    fi


	    (( BRANCH_INDEX++ ));
	done


	if [ "${URL}" != "" ];
	then
	    get_git;
	fi


	(( REPO_ITEM_INDEX++ ));
    done
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function pack()
{
    if [ "$(which gzip)" != "" ];
    then
	if [ "${GIT_BACKUP_FLAG_USE_BZIP2}" != "1" ] && [ "${GIT_BACKUP_FLAG_USE_XZ}" != "1" ];
	then
	    ARCH_EXT='tar.gz';
	    ARCH_OPT='cfz';
	fi
    fi


    if [ "$(which bzip2)" != "" ];
    then
	if [ "${GIT_BACKUP_FLAG_USE_GZIP}" != "1" ] && [ "${GIT_BACKUP_FLAG_USE_XZ}" != "1" ];
	then
	    ARCH_EXT='tar.bz2';
	    ARCH_OPT='cfj';
	fi
    fi


    if [ "$(which xz)" != "" ];
    then
	if [ "${GIT_BACKUP_FLAG_USE_GZIP}" != "1" ] && [ "${GIT_BACKUP_FLAG_USE_BZIP2}" != "1" ];
	then
	    ARCH_EXT='tar.xz';
	    ARCH_OPT='cfJ';
	fi
    fi


    FILE="${GIT_BACKUP_NAME}-$(date +'%Y%m%d_%H%M%S').${ARCH_EXT}";
    echo "- make ${FILE}";
    ionice -c 3 nice -n 20 tar "${ARCH_OPT}" "${FILE}.tmp" git_backup;
    if [ "${?}" != "0" ];
    then
	echo "unknown error";
	exit 1;
    fi
    mv "${FILE}.tmp" "${FILE}";
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
function main()
{
    echo "git_backup 0.0.4";


    CHECK_PROG_LIST='git tar grep sed ls head xargs rm ionice nice awk date';
    check_prog;


    HEAD_DATE="$(date +'%s')";


    if [ "${GIT_BACKUP_REPO_LIST}" == "" ];
    then
	echo "ERROR: variable \"GIT_BACKUP_REPO_LIST\" not found...";
	exit 1;
    fi

    if [ "${GIT_BACKUP_DIR}" == "" ];
    then
	echo "ERROR: variable \"GIT_BACKUP_DIR\" not found...";
	exit 1;
    fi

    if [ "${GIT_BACKUP_NAME}" == "" ];
    then
	echo "ERROR: variable \"GIT_BACKUP_NAME\" not found...";
	exit 1;
    fi

    if [ ! -d "${GIT_BACKUP_DIR}" ];
    then
	echo "ERROR: variable \"GIT_BACKUP_DIR\" not found...";
	exit 1;
    fi


    alarm;
    echo "- use \"${GIT_BACKUP_DIR}\"";
    cd "${GIT_BACKUP_DIR}";


    rm -rf git_backup &> /dev/null;
    mkdir git_backup &> /dev/null;


    cd git_backup;
    parse;
    cd ..;


    pack;


    KILL_RING_PATH="${GIT_BACKUP_DIR}";
    KILL_RING_MAX_ITEM_COUNT="${GIT_BACKUP_MAX_ITEM_COUNT}";
    kill_ring;


    rm -rf git_backup &> /dev/null;


    TAIL_DATE="$(date +'%s')";


    (( TAIL_DATE -= HEAD_DATE ));
    echo "- work time: ${TAIL_DATE} secs";
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
main;

echo "Ok.";
exit 0;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
