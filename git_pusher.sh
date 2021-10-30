#!/bin/bash
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# 0.0.2
# git clone git://github.com/progman/git_backup.git
# Alexey Potehin <gnuplanet@gmail.com>, http://www.gnuplanet.ru/doc/cv
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# view current time
function get_time()
{
	if [ "$(command -v date)" != "" ];
	then
		echo "[$(date +'%Y-%m-%d %H:%M:%S')]: ";
	fi
}
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# check depends
function check_prog()
{
	for i in ${1};
	do
		if [ "$(command -v ${i})" == "" ];
		then
			echo "$(get_time)! FATAL: you must install \"${i}\", exit";
			return 1;
		fi
	done

	return 0;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# pull from source repo to tmp dir, push from tmp dir to target repo
function do_repo()
{
	local SOURCE_GIT_URL="${1}";
	local TARGET_GIT_URL="${2}";


	local NICE='nice -n 20';
	if [ "$(command -v ionice)" != "" ];
	then
		NICE='ionice -c 3 nice -n 20';
	fi


	local HASH;
	HASH=$(echo "${SOURCE_GIT_URL}" | sha3sum --algorithm 256 | awk '{print $1}');


# set ssh key if need
	if [ "${GIT_PUSHER_PULL_SSH_COMMAND}" != "" ];
	then
		export GIT_SSH_COMMAND="${GIT_PUSHER_PULL_SSH_COMMAND}";
	fi


	local FLAG_CLONE="0";
	if [ ! -d "${HASH}" ];
	then
		FLAG_CLONE="1";
# clone git repo
#		echo "$(get_time)  clone repo \"${SOURCE_GIT_URL}\" to tmp dir";
		${NICE} git clone --mirror "${SOURCE_GIT_URL}" "${HASH}" &> /dev/null < /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)! ERROR: clone error, skip repo \"${SOURCE_GIT_URL}\"";
			return 1;
		fi
		cd -- "${HASH}" &> /dev/null < /dev/null;
	else
		cd -- "${HASH}" &> /dev/null < /dev/null;


# set source url
#		echo "$(get_time)  set source url \"${SOURCE_GIT_URL}\"";
		${NICE} git remote set-url origin "${SOURCE_GIT_URL}";
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)! ERROR: set_url error, skip repo \"${SOURCE_GIT_URL}\"";
			return 1;
		fi


# fetch all
#		echo "$(get_time)  fetch repo \"${SOURCE_GIT_URL}\" to tmp dir";
		${NICE} git fetch --all -p &> /dev/null < /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)! ERROR: fetch error, skip repo \"${SOURCE_GIT_URL}\"";
			return 1;
		fi
	fi


# set target url
#	echo "$(get_time)  set target url \"${TARGET_GIT_URL}\"";
	${NICE} git remote set-url origin "${TARGET_GIT_URL}";
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)! ERROR: set_url error, skip repo \"${SOURCE_GIT_URL}\"";
		return 1;
	fi


# set ssh key if need
	if [ "${GIT_PUSHER_PUSH_SSH_COMMAND}" != "" ];
	then
		export GIT_SSH_COMMAND="${GIT_PUSHER_PUSH_SSH_COMMAND}";
	fi


# push set target url
#	echo "$(get_time)  push from tmp dir to \"${TARGET_GIT_URL}\"";
	${NICE} git push --mirror &> /dev/null < /dev/null;
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)! ERROR: push error, skip repo \"${TARGET_GIT_URL}\"";
		return 1;
	fi


	if [ "${FLAG_CLONE}" == "1" ];
	then
		echo "$(get_time)  clone repo from \"${SOURCE_GIT_URL}\" and push to \"${TARGET_GIT_URL}\"";
	else
		echo "$(get_time)  fetch repo from \"${SOURCE_GIT_URL}\" and push to \"${TARGET_GIT_URL}\"";
	fi


	return 0;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# general function
function main()
{
	echo "$(get_time)  run git_pusher v0.0.2 (https://github.com/progman/git_backup.git)";
	echo "$(get_time)  use backup dir \"${GIT_PUSHER_CACHE_DIR}\"";


# check minimal depends tools
	check_prog "awk echo date git mkdir mktemp nice sed sha3sum";
	if [ "${?}" != "0" ];
	then
		return 1;
	fi


# get start time
	local HEAD_DATE="$(date +'%s')";


# make tmp dir
	local TMP;
	TMP="$(mktemp)";
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)! FATAL: can't make tmp file, exit";
		echo;
		echo;
		return 1;
	fi


# create cache dir
	if [ ! -d "${GIT_PUSHER_CACHE_DIR}" ];
	then
		mkdir -- "${GIT_PUSHER_CACHE_DIR}" &> /dev/null < /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)! ERROR: dir GIT_PUSHER_CACHE_DIR not found";
			echo;
			echo;
			return 1;
		fi
	fi


# get list
	if [ ! -f "${GIT_PUSHER_LIST}" ];
	then
		echo "$(get_time)! ERROR: file GIT_PUSHER_LIST not found";
		echo;
		echo;
		return 1;
	fi


	local REPO_COUNT=0;


	sed -e 's/#.*//' "${GIT_PUSHER_LIST}" | sed -e 's/\ *$//g' | sed -e '/^$/d' > "${TMP}";
	while read -r SOURCE_GIT_URL TARGET_GIT_URL;
	do
		cd -- "${GIT_PUSHER_CACHE_DIR}" &> /dev/null < /dev/null;

		if [ "${SOURCE_GIT_URL}" == "" ] || [ "${TARGET_GIT_URL}" == "" ];
		then
			continue;
		fi

		(( REPO_COUNT++ ));
		do_repo "${SOURCE_GIT_URL}" "${TARGET_GIT_URL}";
		if [ "${?}" != "0" ];
		then
			continue;
		fi

	done < "${TMP}";


	rm -- "${TMP}" &> /dev/null;


# get stop time
	local TAIL_DATE="$(date +'%s')";


# view run time
	(( TAIL_DATE -= HEAD_DATE ));
	echo "$(get_time)  processed ${REPO_COUNT} repos, work time: ${TAIL_DATE} secs";

	echo "$(get_time)  Done.";
	echo;
	echo;


	return 0;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
main "${@}";

exit "${?}";
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
