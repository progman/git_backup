#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# 0.4.9
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
	for i in ${1};
	do
		if [ "$(which ${i})" == "" ];
		then
			echo "$(get_time)! FATAL: you must install \"${i}\", exit";
			return 1;
		fi
	done

	return 0;
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
	local SIZE="$(echo "${1}" | sed -e 's/^[-+]//g')";

	local SIGN="";
	if [ "${1:0:1}" == "-" ];
	then
		SIGN="-";
	fi


	if [ "$(which bc)" == "" ] || [ ${SIZE} -lt 1024 ]; # ${SIZE} < 1024
	then
		echo "${SIGN}${SIZE} B";
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


	echo "${SIGN}${X} ${NAME[$NAME_INDEX]}";

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
	local SIZE=0;

	local TMPFILE=$(mktemp);
	if [ "${?}" != "0" ];
	then
		echo "${SIZE}";
	fi

	find ./ -type f -iname '*\.tar*' -printf '%s\n' > "${TMPFILE}";

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
	local SIZE=0;

	local TMPFILE=$(mktemp);
	if [ "${?}" != "0" ];
	then
		echo "${SIZE}";
	fi

	find ./ -type f -printf '%s\n' > "${TMPFILE}";

	while read -r ITEM_SIZE;
	do
		(( SIZE += ITEM_SIZE ));
	done < "${TMPFILE}";

	rm -rf "${TMPFILE}" &> /dev/null;

	echo "${SIZE}";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# keep N new files and kill other
function kill_ring()
{
	local MAX_ITEM_COUNT="${1}";
	(( MAX_ITEM_COUNT+=0 ))


	if [ "${MAX_ITEM_COUNT}" == "0" ]; # 0 is disable
	then
		return;
	fi


	local FILENAME;
	find ./ -maxdepth 1 -type f -iname '*\.tar\.*' -printf '%T@ %p\n' | sort -nr | sed -e 's/^[0-9]*\.[0-9]*\ \.\///g' |
	{
		while read -r FILENAME;
		do

			if [ "${MAX_ITEM_COUNT}" == "0" ];
			then
				echo "rm -rf \"${FILENAME}\"";
				rm -rf -- "${FILENAME}" &> /dev/null;
				continue;
			fi

			(( MAX_ITEM_COUNT-- ));

		done
	};
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
	ionice -c 3 nice -n 20 tar "${ARCH_OPT}" "${FILE}.tmp" "${NAME_BARE}";
	if [ "${?}" != "0" ];
	then
		rm -rf "${FILE}.tmp" &> /dev/null;
		echo "$(get_time)! ERROR: pack repository error, skip it";
	else
		mv "${FILE}.tmp" "${FILE}";
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# update or clone repo
function get_git()
{
	local URL="${1}";
	local SUBDIR="${2}";

	NAME="$(echo ${URL} | sed -e 's/\.git//g' | sed -e 's/.*:\|.*\///g')";

	HASH=$(echo "${URL}" | sha1sum | awk '{print $1}');

	NAME_BARE="${NAME}.${HASH}.git";

	cd -- "${GIT_BACKUP_DIR}";


# create subdir if is need
	if [ "${SUBDIR}" != "" ];
	then

		if [ "${SUBDIR:${#SUBDIR}-1:1}" != "/" ];
		then
			SUBDIR="${SUBDIR}/";
		fi

		mkdir -p -- "${SUBDIR}" &> /dev/null;
		touch -- "${SUBDIR}" &> /dev/null;

		BASEDIR=$(echo "${SUBDIR}" | sed -e 's/\/.*//g');
		touch -- "${BASEDIR}" &> /dev/null;

		cd -- "${SUBDIR}" &> /dev/null;
	fi


	mkdir -- "${NAME}.${HASH}" &> /dev/null;
	touch -- "${NAME}.${HASH}" &> /dev/null;
	cd -- "${NAME}.${HASH}" &> /dev/null;


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
			echo "$(get_time)  unpack repository \"${SUBDIR}${NAME}\" from last backup \"${ARCH}\"";

			tar xvf "${ARCH}" &> /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)! ERROR: unpack error, need clone repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
				rm -rf -- "${NAME_BARE}" &> /dev/null;
			fi
		fi
	fi


# if repo exist try update
	if [ -e "${NAME_BARE}" ];
	then
		cd "${NAME_BARE}";

		while true;
		do

# is git repo?
			git branch &> /dev/null < /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)! ERROR: is not Git repository, need clone repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
				break;
			fi


# repo URL and exist repo URL equal?
			URL_CUR=$(git config -l | grep '^remote.origin.url' | sed -e 's/remote.origin.url=//g');
			if [ "${URL}" != "${URL_CUR}" ];
			then
				echo "$(get_time)! ERROR: alien remote.origin.url, need clone repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
				break;
			fi


# fsck repo if enabled
			if [ "${GIT_BACKUP_FLAG_REPO_FSCK}" != "0" ];
			then
				git fsck --full &> /dev/null < /dev/null;
				if [ "${?}" != "0" ];
				then
					echo "$(get_time)! ERROR: fsck error, need clone repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
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
		rm -rf -- "${NAME}.git"; &> /dev/null; # for old versions compatibility
		rm -rf -- "${NAME_BARE}" &> /dev/null;
		echo "$(get_time)+ clone  repository \"${SUBDIR}${NAME}\" from \"${URL}\"";
		git clone --mirror "${URL}" "${NAME_BARE}" &> /dev/null < /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)! ERROR: clone error, skip repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
			return;
		fi
		FLAG_REPO_UPDATE='1';
	fi


	touch -- "${NAME_BARE}" &> /dev/null;
	cd -- "${NAME_BARE}";


# get old commit
	local OLD_LAST_COMMIT_HASH;
#	OLD_LAST_COMMIT_HASH="$(git log -n 1 --format=%H 2>&1)";
#	OLD_LAST_COMMIT_HASH="$(git rev-parse FETCH_HEAD 2>&1)";
	OLD_LAST_COMMIT_HASH="$(sha1sum FETCH_HEAD 2>&1)";
	if [ "${?}" != "0" ];
	then
		if [ "${FLAG_CLONE}" == "0" ];
		then
			echo "$(get_time)! WARNING: hash error, update anyway repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
		fi
		FLAG_REPO_UPDATE='1';
	fi


# fetch all
	git fetch --all -p &> /dev/null < /dev/null;
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)! ERROR: fetch error, skip repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
		return;
	fi


# get new commit
	local NEW_LAST_COMMIT_HASH;
#	NEW_LAST_COMMIT_HASH="$(git log -n 1 --format=%H 2>&1)";
#	NEW_LAST_COMMIT_HASH="$(git rev-parse FETCH_HEAD 2>&1)";
	NEW_LAST_COMMIT_HASH="$(sha1sum FETCH_HEAD 2>&1)";
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)! WARNING: hash error, update anyway repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
		FLAG_REPO_UPDATE='1';
	fi


# cmp old and new commit
	if [ "${OLD_LAST_COMMIT_HASH}" != "${NEW_LAST_COMMIT_HASH}" ];
	then
		FLAG_REPO_UPDATE='1';
	fi


# show update status
	if [ "${FLAG_CLONE}" == "0" ];
	then
		if [ "${FLAG_REPO_UPDATE}" == "1" ];
		then
			echo "$(get_time)+ update repository \"${SUBDIR}${NAME}\" from \"${URL}\"";
		else
			echo "$(get_time)  update repository \"${SUBDIR}${NAME}\" from \"${URL}\"";
		fi
	fi


# fsck repo if enabled
	if [ "${GIT_BACKUP_FLAG_REPO_FSCK}" != "0" ];
	then
		git fsck --full &> /dev/null < /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)! ERROR: fsck error, skip repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
			return;
		fi
	fi





# garbage collect cache repository
	if [ "${GIT_BACKUP_FLAG_REPO_GC}" == "1" ] && [ "${GIT_BACKUP_FLAG_REPO_CACHE}" != "0" ];
	then
		if [ "${GIT_BACKUP_FLAG_REPO_GC_PRUNE}" == "1" ];
		then
			git gc --aggressive --prune=now &> /dev/null < /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)! ERROR: gc error, into repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
			fi
		else
			git gc --aggressive --no-prune &> /dev/null < /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)! ERROR: gc error, into repo \"${SUBDIR}${NAME}\" from \"${URL}\"";
			fi
		fi
	fi


	cd ..;


# pack modify repository
	if [ "${FLAG_REPO_UPDATE}" == "1" ] || [ "${GIT_BACKUP_FLAG_FORCE_PACK}" == "1" ];
	then
		pack;
	fi


# delete clone repository
	if [ "${GIT_BACKUP_FLAG_REPO_CACHE}" == "0" ];
	then
		rm -rf -- "${NAME_BARE}" &> /dev/null;
	fi


	if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
	then
		kill_ring "${GIT_BACKUP_MAX_ITEM_COUNT}";
	else
		kill_ring "${GIT_BACKUP_MAX_ITEM_COUNT}" &> /dev/null;
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# parse repo list
function parse()
{
	local TMP="$(mktemp)";
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)! FATAL: can't make tmp file, exit";
		echo;
		echo;
		return 1;
	fi

	sed -e 's/#.*//' "${GIT_BACKUP_REPO_LIST}" | sed -e 's/\ *$//g' | sed -e '/^$/d' > "${TMP}";


	local SUBDIR;
	local URL;
	while read -r SUBDIR URL;
	do
		if [ "${SUBDIR}" == "" ] && [ "${URL}" == "" ];
		then
			continue;
		fi

		if [ "${SUBDIR}" != "" ] && [ "${URL}" == "" ];
		then
			get_git "${SUBDIR}" "${URL}";
			continue;
		fi

		get_git "${URL}" "${SUBDIR}";

	done < "${TMP}";


	rm -- "${TMP}" &> /dev/null;
	return 0;
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# check run
function check_run()
{
	local PID;
	read PID < "${1}";

#	kill -0 "${PID}" &> /dev/null;
#	if [ "${?}" == "0" ];

#	if [ "$(ps -e -o pid | grep ${PID} | { read a b; echo ${a}; })" == "${PID}" ];
	if [ "$(ps -hp ${PID} | wc -l | { read a b; echo ${a}; })" != "0" ];
	then
		return 1; # program already run
	fi


	return 0;
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# general function
function main()
{
# check minimal depends tools
	check_prog "echo ps wc";
	if [ "${?}" != "0" ];
	then
		return 1;
	fi


# check run
	if [ "${GIT_BACKUP_PIDFILE}" == "" ];
	then
		GIT_BACKUP_PIDFILE="/var/run/git_backup.pid";
	fi
	if [ -e "${GIT_BACKUP_PIDFILE}" ];
	then
		check_run "${GIT_BACKUP_PIDFILE}";
		if [ "${?}" != "0" ];
		then
			return 0; # program already run
		fi
	fi
	echo "${BASHPID}" > "${GIT_BACKUP_PIDFILE}";


# view program name
	echo "$(get_time)  run git_backup v0.4.9 (https://github.com/progman/git_backup.git)";


# check depends tools
	check_prog "awk date echo git grep ionice ls mkdir mktemp mv nice ps rm sed sort tail tar test touch wc xargs sha1sum";
	if [ "${?}" != "0" ];
	then
		return 1;
	fi


# get start time
	HEAD_DATE="$(date +'%s')";


# check variables
	if [ "${GIT_BACKUP_REPO_LIST}" == "" ];
	then
		echo "$(get_time)! FATAL: variable \"GIT_BACKUP_REPO_LIST\" is not set, exit";
		echo;
		echo;
		return 1;
	fi

	if [ ! -e "${GIT_BACKUP_REPO_LIST}" ];
	then
		echo "$(get_time)! FATAL: file \"GIT_BACKUP_REPO_LIST\" not found, exit";
		echo;
		echo;
		return 1;
	fi

	if [ "${GIT_BACKUP_DIR}" == "" ];
	then
		echo "$(get_time)! FATAL: variable \"GIT_BACKUP_DIR\" is not set, exit";
		echo;
		echo;
		return 1;
	fi

	mkdir -p "${GIT_BACKUP_DIR}" &> /dev/null;

	if [ ! -d "${GIT_BACKUP_DIR}" ];
	then
		echo "$(get_time)! FATAL: dir \"GIT_BACKUP_DIR\" not found, exit";
		echo;
		echo;
		return 1;
	fi


	alarm;
	echo "$(get_time)  use backup dir \"${GIT_BACKUP_DIR}\"";
	touch "${GIT_BACKUP_DIR}" &> /dev/null;


# do it
	parse;
	if [ "${?}" != "0" ];
	then
		return 1;
	fi


# view stats
	if [ "${GIT_BACKUP_FLAG_VIEW_SIZE}" != "0" ];
	then
		cd -- "${GIT_BACKUP_DIR}";
		local SIZE_MIN=$(get_size_min);
		local HUMAN_SIZE_MIN="$(human_size ${SIZE_MIN})";

		local SIZE_MAX=$(get_size_max);
		local HUMAN_SIZE_MAX="$(human_size ${SIZE_MAX})";

		echo "$(get_time)  total backup size min/max: ${HUMAN_SIZE_MIN}/${HUMAN_SIZE_MAX}";
	fi


# get stop time
	TAIL_DATE="$(date +'%s')";


# view run time
	(( TAIL_DATE -= HEAD_DATE ));
	echo "$(get_time)  work time: ${TAIL_DATE} secs";

	echo "$(get_time)  Done.";
	echo;
	echo;
	return 0;
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
main "${@}";

exit "${?}";
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
