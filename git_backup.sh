#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# 0.3.8
# git clone git://github.com/progman/git_backup.git
# Alexey Potehin <gnuplanet@gmail.com>, http://www.gnuplanet.ru/doc/cv
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# view current time
function get_time()
{
	if [ "$(which date)" != "" ];
	then
		echo "[$(date +'%Y-%m-%d %H:%M:%S')]: ";
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# check depends
function check_prog()
{
	local FLAG_OK=1;
	for i in ${CHECK_PROG_LIST};
	do
		if [ "$(which ${i})" == "" ];
		then
			echo "$(get_time)[!]FATAL: you must install \"${i}\"...";
			echo;
			echo;
			FLAG_OK=0;
			break;
		fi
	done

	return ${FLAG_OK};
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# do beep
function alarm()
{
	if [ "$(which beep)" != "" ] && [ "${GIT_BACKUP_FLAG_ALARM}" == "1" ];
	then
		beep -r 1 -f 3000;
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# convert SIZE to human readable string
function human_size()
{
	local SIZE="${1}";

	if [ "$(which bc)" == "" ] || [ ${1} -lt 1024 ]; # ${1} < 1024
	then
		echo "${SIZE} B";
		return;
	fi


	local NAME=( "B" "kB" "MB" "GB" "TB" "PB" "EB" "ZB" "YB" );
	local NAME_INDEX=0;

	while true;
	do
		local EXPR="scale=1; ${SIZE} / (1024 ^ ${NAME_INDEX})";
		local X=$(echo "${EXPR}" | bc);
		local Y=$(echo "${X}" | sed -e 's/\..*//g');

		if [ ${Y} -lt 1024 ]; # ${Y} < 1024
		then
			break;
		fi

		(( NAME_INDEX++ ));
	done


	echo "${X} ${NAME[$NAME_INDEX]}";

#	while true;
#	do
#		if [ ${SIZE} -le 1024 ];
#		then
#			break;
#		fi
#
#		(( NEW_SIZE = SIZE / 1024 ));
#		(( PART = SIZE % 1024 ));
#		SIZE=${NEW_SIZE};
#
#		(( NAME_INDEX++ ));
#	done
#
#	PART_VALUE=${PART:0:1};
#	HUMAN_SIZE="${SIZE}.${PART_VALUE} ${NAME[$NAME_INDEX]}";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# get size of tar backup files
function get_size_min()
{
	local TMPFILE=$(mktemp);
	find ./ -maxdepth 2 -type f -iname '*\.tar*' -printf '%s\n' > "${TMPFILE}";

	local SIZE=0;
	while read -r ITEM_SIZE;
	do
		(( SIZE += ITEM_SIZE ));
	done < "${TMPFILE}";

	rm -rf "${TMPFILE}" &> /dev/null;

	echo "${SIZE}";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# get size of tar backup files + cache files
function get_size_max()
{
	local TMPFILE=$(mktemp);
	find ./ -type f -printf '%s\n' > "${TMPFILE}";

	local SIZE=0;
	while read -r ITEM_SIZE;
	do
		(( SIZE += ITEM_SIZE ));
	done < "${TMPFILE}";

	rm -rf "${TMPFILE}" &> /dev/null;

	echo "${SIZE}";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# kill old backups (default disable)
function kill_ring()
{
	if [ "${KILL_RING_MAX_ITEM_COUNT}" == "0" ] || [ "${KILL_RING_MAX_ITEM_COUNT}" == "" ];
	then
		return;
	fi

	if [ ! -e "${KILL_RING_PATH}" ];
	then
		return;
	fi

	TMPFILE="$(mktemp)";

	find "${KILL_RING_PATH}" -maxdepth 1 -type f -iname '*\.tar*' -printf '%T@ %p\n' | sort -n &> "${TMPFILE}";

	KILL_RING_CUR_ITEM_COUNT=$(cat "${TMPFILE}" | wc -l);

	if [ "${KILL_RING_CUR_ITEM_COUNT}" -gt "${KILL_RING_MAX_ITEM_COUNT}" ];
	then
		if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
		then
			echo "$(get_time)time to kill old...";
		fi

		KILL_RING_ITEM_COUNT="${KILL_RING_CUR_ITEM_COUNT}";

		(( KILL_RING_ITEM_COUNT -= KILL_RING_MAX_ITEM_COUNT ));


		if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
		then
			echo "$(get_time)kill_ring(): KILL_RING_MAX_ITEM_COUNT=\"${KILL_RING_MAX_ITEM_COUNT}\"";
			echo "$(get_time)kill_ring(): KILL_RING_CUR_ITEM_COUNT=\"${KILL_RING_CUR_ITEM_COUNT}\"";
			echo "$(get_time)kill_ring(): KILL_RING_ITEM_COUNT=\"${KILL_RING_ITEM_COUNT}\"";
		fi


		head -n "${KILL_RING_ITEM_COUNT}" "${TMPFILE}" | while read -r TIMESTAMP FILENAME;
		do
			if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
			then
				echo "rm -rf \"${FILENAME}\"";
			fi
			rm -rf "${FILENAME}";
		done;
	fi

	rm -rf "${TMPFILE}" &> /dev/null;
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# make archive
function pack()
{
	ARCH_EXT='tar';
	ARCH_OPT='cf';


	if [ "$(which gzip)" != "" ];
	then
		if [ "${GIT_BACKUP_FLAG_USE_BZIP2}" != "1" ] && [ "${GIT_BACKUP_FLAG_USE_XZ}" != "1" ];
		then
			ARCH_EXT='tar.gz';
			ARCH_OPT='cfz';

			if [ "${GZIP}" == "" ];
			then
				export GZIP='-9';
			fi
		fi
	fi


	if [ "$(which bzip2)" != "" ];
	then
		if [ "${GIT_BACKUP_FLAG_USE_GZIP}" != "1" ] && [ "${GIT_BACKUP_FLAG_USE_XZ}" != "1" ];
		then
			ARCH_EXT='tar.bz2';
			ARCH_OPT='cfj';

			if [ "${BZIP2}" == "" ];
			then
				export BZIP2='-9';
			fi
		fi
	fi


	if [ "$(which xz)" != "" ];
	then
		if [ "${GIT_BACKUP_FLAG_USE_GZIP}" != "1" ] && [ "${GIT_BACKUP_FLAG_USE_BZIP2}" != "1" ];
		then
			ARCH_EXT='tar.xz';
			ARCH_OPT='cfJ';

			if [ "${XZ_OPT}" == "" ];
			then
				export XZ_OPT='-9 --extreme';
			fi
		fi
	fi


	FILE="${NAME_BARE}.$(date +'%Y%m%d_%H%M%S').${ARCH_EXT}";
	echo "$(get_time)[+]pack repository \"${NAME}\"";
	ionice -c 3 nice -n 20 tar "${ARCH_OPT}" "${FILE}.tmp" "${NAME_BARE}";
	if [ "${?}" != "0" ];
	then
		rm -rf "${FILE}.tmp" &> /dev/null;
		echo "$(get_time)[!]ERROR: pack repository archive error...";
#		echo;
#		echo;
#		exit 1;
	else
		mv "${FILE}.tmp" "${FILE}";
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# for old versions compatibility, auto convert from old format
function stupid_compatibility()
{
	if [ -e "${NAME}" ];
	then
		cd "${NAME}";

		for i in $(find ./ -maxdepth 1 -type d | grep -v '^./$');
		do
			rm -rf "${i}" &> /dev/null;
		done

		FLAG_RENAME='0';

		ARCH="$(ls -1 --color=none | grep '\.tar' | sort -n | tail -n 1)";
		if [ "${ARCH}" != "" ];
		then
			tar xvf "${ARCH}" &> /dev/null;
			if [ "${?}" == "0" ];
			then

				if [ -e "${NAME}" ];
				then
					cd "${NAME}";
					XURL=$(git config -l | grep remote.origin.url | sed -e 's/remote.origin.url=//g');
					XHASH=$(echo "${XURL}" | sha1sum | awk '{print $1}');
					cd ..;
					if [ "${XURL}" != "" ];
					then
						FLAG_RENAME='1';
						rm -rf "${NAME}" &> /dev/null;
					fi
				fi

				if [ -e "${NAME}.git" ];
				then
					cd "${NAME}.git";
					XURL=$(git config -l | grep remote.origin.url | sed -e 's/remote.origin.url=//g');
					XHASH=$(echo "${XURL}" | sha1sum | awk '{print $1}');
					cd ..;
					if [ "${XURL}" != "" ];
					then
						FLAG_RENAME='1';
						rm -rf "${NAME}.git" &> /dev/null;
					fi
				fi

				if [ -e "${NAME}.${HASH}.git" ];
				then
					cd "${NAME}.${HASH}.git";
					XURL=$(git config -l | grep remote.origin.url | sed -e 's/remote.origin.url=//g');
					XHASH=$(echo "${XURL}" | sha1sum | awk '{print $1}');
					cd ..;
					if [ "${XURL}" != "" ];
					then
						FLAG_RENAME='1';
						rm -rf "${NAME}.${HASH}.git" &> /dev/null;
					fi
				fi
			fi
		fi

		cd ..;

		if [ "${FLAG_RENAME}" == "1" ];
		then
			mv "${NAME}" "${NAME}.${XHASH}" &> /dev/null;
		fi
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# update or clone repo
function get_git()
{
	NAME="$(echo ${URL} | sed -e 's/\.git//g' | sed -e 's/.*:\|.*\///g')";

	HASH=$(echo "${URL}" | sha1sum | awk '{print $1}');

	NAME_BARE="${NAME}.${HASH}.git";


	stupid_compatibility; # kill me


	mkdir "${NAME}.${HASH}" &> /dev/null;
	touch "${NAME}.${HASH}" &> /dev/null;
	cd "${NAME}.${HASH}" &> /dev/null;


# create archive or not
	FLAG_REPO_UPDATE='0';


# clone or update git repo
	FLAG_CLONE='1';


# if repo not exist try unpack last archive and update
	if [ ! -e "${NAME_BARE}" ];
	then
		ARCH="$(ls -1 --color=none | grep '\.tar' | sort -n | tail -n 1)";

		if [ "${ARCH}" != "" ];
		then
			echo "$(get_time)unpack repository \"${NAME}\" from last backup \"${ARCH}\"";

			tar xvf "${ARCH}" &> /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)[!]error unpack, skip it...";
				rm -rf "${NAME_BARE}" &> /dev/null;
			fi
		fi
	fi


# if repo exist try update
	if [ -e "${NAME_BARE}" ];
	then
		cd "${NAME_BARE}";
		echo "$(get_time)update repository \"${NAME}\" from \"${URL}\"";

		while true;
		do


# is git repo?
			git branch &> /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)[!]error update, is NOT repository, skip it...";
				break;
			fi


# is not modify?
#			if [ "$(git status --porcelain | wc -l)" != "0" ];
#			then
#				echo "$(get_time)[!]error update, this repository modify, skip it...";
#				break;
#			fi


# repo URL and exist repo URL equal?
			URL_CUR=$(git config -l | grep '^remote.origin.url' | sed -e 's/remote.origin.url=//g');
			if [ "${URL}" != "${URL_CUR}" ];
			then
				echo "$(get_time)[!]error update, alien remote.origin.url, skip it...";
				break;
			fi


# fsck repo if enabled
			if [ "${GIT_BACKUP_FLAG_REPO_FSCK}" != "0" ];
			then
				git fsck --full &> /dev/null;
				if [ "${?}" != "0" ];
				then
					echo "$(get_time)[!]error update, fsck error, skip it...";
					break;
				fi
			fi


			FLAG_CLONE='0';


			break;
		done

		cd ..;
	fi


# clone git repo
	if [ "${FLAG_CLONE}" != "0" ];
	then
		rm -rf "${NAME}.git"; &> /dev/null; # for old versions compatibility
		rm -rf "${NAME_BARE}" &> /dev/null;
		echo "$(get_time)clone repository \"${NAME}\" from \"${URL}\"";
		git clone --mirror "${URL}" "${NAME_BARE}" &> /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)[!]ERROR: clone error, skip repo...";
			cd ..;
#			echo;
#			echo;
			return;
		fi
		FLAG_REPO_UPDATE='1';
	fi


	touch "${NAME_BARE}" &> /dev/null;
	cd "${NAME_BARE}";


# fetch all
#	OLD_LAST_COMMIT_HASH="$(git log -n 1 --format=%H 2>&1)";
	OLD_LAST_COMMIT_HASH="$(git rev-parse FETCH_HEAD 2>&1)";
	git fetch --all -p &> /dev/null;
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)[!]ERROR: fetch error, skip repo...";
		cd ..;
		cd ..;
#		echo;
#		echo;
		return;
	fi


#	NEW_LAST_COMMIT_HASH="$(git log -n 1 --format=%H 2>&1)";
	NEW_LAST_COMMIT_HASH="$(git rev-parse FETCH_HEAD 2>&1)";
	if [ "${OLD_LAST_COMMIT_HASH}" != "${NEW_LAST_COMMIT_HASH}" ];
	then
		FLAG_REPO_UPDATE='1';
	fi


# fsck repo if enabled
	if [ "${GIT_BACKUP_FLAG_REPO_FSCK}" != "0" ];
	then
		git fsck --full &> /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)[!]ERROR: fsck error, skip repo...";
			cd ..;
			cd ..;
#			echo;
#			echo;
			return;
		fi
	fi


# garbage collect cache repository
	if [ "${GIT_BACKUP_FLAG_REPO_GC}" == "1" ] && [ "${GIT_BACKUP_FLAG_REPO_CACHE}" != "0" ];
	then
		git gc --aggressive --no-prune &> /dev/null;
		git repack -ad &> /dev/null;
	fi


	cd ..;


# pack modify repository
	if [ "${FLAG_REPO_UPDATE}" == "1" ] || [ "${GIT_BACKUP_FLAG_FORCE_PACK}" == "1" ];
	then
		pack;
	else
		if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
		then
			echo "$(get_time)repository \"${NAME}\" NOT modify";
		fi
	fi


# delete clone repository
	if [ "${GIT_BACKUP_FLAG_REPO_CACHE}" == "0" ];
	then
		rm -rf "${NAME_BARE}" &> /dev/null;
	fi


	KILL_RING_PATH="${GIT_BACKUP_DIR}/${NAME}.${HASH}";
	KILL_RING_MAX_ITEM_COUNT="${GIT_BACKUP_MAX_ITEM_COUNT}";
	kill_ring;


	cd ..;
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# parse repo list
function parse()
{
	TMP="$(mktemp)";

	sed -e 's/#.*//' "${GIT_BACKUP_REPO_LIST}" | sed -e 's/\ *$//g' | sed -e '/^$/d' > "${TMP}";


	while read -r REPO_ITEM;
	do
		URL=$(echo "${REPO_ITEM}" | awk -F' ' "{print $1}"); # for old versions compatibility

		if [ "${URL}" != "" ];
		then
			get_git;
		fi

	done < "${TMP}";


	rm "${TMP}" &> /dev/null;
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# general function
function main()
{
# check minimal depends tools
	check_prog "cat kill echo";
	if [ "${?}" == "0" ];
	then
		exit 1;
	fi


# check race condition
	if [ "${GIT_BACKUP_PIDFILE}" == "" ];
	then
		GIT_BACKUP_PIDFILE="/var/run/git_backup.pid";
	fi
	if [ -e "${GIT_BACKUP_PIDFILE}" ];
	then
		PID="$(cat ${GIT_BACKUP_PIDFILE})";

		kill -0 "${PID}" &> /dev/null;
		if [ "${?}" == "0" ];
		then
			exit 1; # program already run
		fi
	fi
	echo "${BASHPID}" > "${GIT_BACKUP_PIDFILE}";


# view program name
	echo "$(get_time)run git_backup v0.3.8 (https://github.com/progman/git_backup)";


# check depends tools
	check_prog "awk date echo git grep head ionice ls mkdir mktemp mv nice rm sed sort tail tar test touch wc xargs sha1sum";
	if [ "${?}" == "0" ];
	then
		exit 1;
	fi


# get start time
	HEAD_DATE="$(date +'%s')";


# check variables
	if [ "${GIT_BACKUP_REPO_LIST}" == "" ];
	then
		echo "$(get_time)[!]FATAL: variable \"GIT_BACKUP_REPO_LIST\" is not set...";
		echo;
		echo;
		exit 1;
	fi

	if [ ! -e "${GIT_BACKUP_REPO_LIST}" ];
	then
		echo "$(get_time)[!]FATAL: file \"GIT_BACKUP_REPO_LIST\" not found...";
		echo;
		echo;
		exit 1;
	fi

	if [ "${GIT_BACKUP_DIR}" == "" ];
	then
		echo "$(get_time)[!]FATAL: variable \"GIT_BACKUP_DIR\" is not set...";
		echo;
		echo;
		exit 1;
	fi

	mkdir -p "${GIT_BACKUP_DIR}" &> /dev/null;

	if [ ! -d "${GIT_BACKUP_DIR}" ];
	then
		echo "$(get_time)[!]FATAL: dir \"GIT_BACKUP_DIR\" not found...";
		echo;
		echo;
		exit 1;
	fi


	alarm;
	echo "$(get_time)use backup dir \"${GIT_BACKUP_DIR}\"";
	touch "${GIT_BACKUP_DIR}" &> /dev/null;
	cd "${GIT_BACKUP_DIR}";


# do it
	parse;


# view stats
	if [ "${GIT_BACKUP_FLAG_VIEW_SIZE}" != "0" ];
	then
		local SIZE_MIN=$(get_size_min);
		local HUMAN_SIZE_MIN="$(human_size ${SIZE_MIN})";

		local SIZE_MAX=$(get_size_max);
		local HUMAN_SIZE_MAX="$(human_size ${SIZE_MAX})";

		echo "$(get_time)total backup size min/max: ${HUMAN_SIZE_MIN}/${HUMAN_SIZE_MAX}";
	fi


# get stop time
	TAIL_DATE="$(date +'%s')";


# view run time
	(( TAIL_DATE -= HEAD_DATE ));
	echo "$(get_time)work time: ${TAIL_DATE} secs";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
main;

echo "$(get_time)Done.";
echo;
echo;
exit 0;
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
