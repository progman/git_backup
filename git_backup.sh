#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# 0.1.0
# Alexey Potehin http://www.gnuplanet.ru/doc/cv
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# view current time
function get_time()
{
	if [ "$(which date)" != "" ];
	then
		echo "[$(date +'%Y-%m-%d %H-%M-%S')]: ";
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# check depends
function check_prog()
{
	for i in ${CHECK_PROG_LIST};
	do
		if [ "$(which ${i})" == "" ];
		then
			echo "$(get_time)ERROR: you must install \"${i}\"...";
			echo;
			echo;
			exit 1;
		fi
	done
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# do beep
function alarm()
{
	if [ "$(which beep)" != "" ];
	then
		beep -r 1 -f 3000;
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# kill old backups (default disable)
function kill_ring()
{
	if [ "${KILL_RING_MAX_ITEM_COUNT}" == "0" ] || [ "${KILL_RING_MAX_ITEM_COUNT}" == "" ];
	then
		return;
	fi


	KILL_RING_CUR_ITEM_COUNT=$(ls -1 "${KILL_RING_PATH}" | grep '\.tar' | wc -l);

	if [ "${KILL_RING_CUR_ITEM_COUNT}" -gt "${KILL_RING_MAX_ITEM_COUNT}" ];
	then
		echo "$(get_time)time to kill old...";

		KILL_RING_ITEM_COUNT="${KILL_RING_CUR_ITEM_COUNT}";

		(( KILL_RING_ITEM_COUNT -= KILL_RING_MAX_ITEM_COUNT ));


		if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
		then
			echo "$(get_time)kill_ring(): KILL_RING_MAX_ITEM_COUNT=\"${KILL_RING_MAX_ITEM_COUNT}\"";
			echo "$(get_time)kill_ring(): KILL_RING_CUR_ITEM_COUNT=\"${KILL_RING_CUR_ITEM_COUNT}\"";
			echo "$(get_time)kill_ring(): KILL_RING_ITEM_COUNT=\"${KILL_RING_ITEM_COUNT}\"";
		fi


		ls -1 --color=none "${KILL_RING_PATH}" | grep '\.tar' | sort -n | head -n "${KILL_RING_ITEM_COUNT}" | xargs rm -rf --;
	fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# make archive
function pack()
{
	NAME="${1}";

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


	FILE="${NAME}-$(date +'%Y%m%d_%H%M%S').${ARCH_EXT}";
	echo "$(get_time)make ${FILE}";
	ionice -c 3 nice -n 20 tar "${ARCH_OPT}" "${FILE}.tmp" "${NAME}";
	if [ "${?}" != "0" ];
	then
		echo "$(get_time)unknown error";
		echo;
		echo;
		exit 1;
	fi
	mv "${FILE}.tmp" "${FILE}";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# update or clone repo
function get_git()
{
	NAME="$(echo ${URL} | sed -e 's/\.git//g' | sed -e 's/.*:\|.*\///g')";


	mkdir "${NAME}" &> /dev/null;
	cd "${NAME}" &> /dev/null;


	FLAG_REPO_UPDATE='0';


# clone or update git repo
	FLAG_CLONE='1';


# if repo exist try update
	if [ -e "${NAME}" ];
	then
		cd "${NAME}";

# is git repo?
		git branch &> /dev/null;
		if [ "${?}" == "0" ];
		then

# is not modify?
			if [ "$(git status --porcelain | wc -l)" == "0" ];
			then

# repo URL and exist repo URL equal?
				URL_CUR=$(git config -l | grep '^remote.origin.url' | sed -e 's/remote.origin.url=//g');
				if [ "${URL}" == "${URL_CUR}" ];
				then
					echo "$(get_time)update repository \"${NAME}\" from \"${URL}\"";
					git fetch --all -p &> /dev/null;
					if [ "${?}" == "0" ];
					then
						FLAG_CLONE=0;
					fi
				fi
			fi
		fi

		cd ..;
	fi


# if repo not exist try unpack last archive and update
	if [ "${FLAG_CLONE}" == "1" ];
	then
		ARCH="$(ls -1 --color=none | grep '\.tar' | sort -n | tail -n 1)";

		if [ "${ARCH}" != "" ];
		then
			echo "$(get_time)unpack repository \"${NAME}\" from last backup \"${ARCH}\"";

			tar xvf "${ARCH}" &> /dev/null;
			if [ "${?}" == "0" ];
			then
				cd "${NAME}";

# is git repo?
				git branch &> /dev/null;
				if [ "${?}" == "0" ];
				then

# is not modify?
					if [ "$(git status --porcelain | wc -l)" == "0" ];
					then

# repo URL and exist repo URL equal?
						URL_CUR=$(git config -l | grep '^remote.origin.url' | sed -e 's/remote.origin.url=//g');
						if [ "${URL}" == "${URL_CUR}" ];
						then
							echo "$(get_time)update repository \"${NAME}\" from \"${URL}\"";
							git fetch --all -p &> /dev/null;
							if [ "${?}" == "0" ];
							then
								FLAG_CLONE=0;
							fi
						fi
					fi
				fi

				cd ..;
			fi
		fi
	fi


# clone git repo
	if [ "${FLAG_CLONE}" != "0" ];
	then
		rm -rf "${NAME}" &> /dev/null;
		echo "$(get_time)clone repository \"${NAME}\" from \"${URL}\"";
		git clone "${URL}" "${NAME}" &> /dev/null;
		if [ "${?}" != "0" ];
		then
			echo "$(get_time)ERROR: unknown error";
			echo;
			echo;
			exit 1;
		fi
		FLAG_REPO_UPDATE='1';
	fi


	touch "${NAME}" &> /dev/null;
	cd "${NAME}";


# save default branch, may be 'master'
	DEFAULT_BRANCH=$(git branch | grep '^\*' | sed -e 's/\*\ //g');


# choice all branches if BRANCH_LIST is empty
	if [ "${BRANCH_LIST}" == "" ];
	then
		if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
		then
			echo "$(get_time)get_git(): detect empty BRANCH_LIST";
		fi

		for BRANCH in $(git branch -r | sed -e 's/\ *origin\///g' | grep -v '\ ->');
		do
			if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
			then
				echo "$(get_time)get_git(): add branch:\"${BRANCH}\"";
			fi

			if [ "${BRANCH_LIST}" != "" ];
			then
				BRANCH_LIST="${BRANCH_LIST} ";
			fi
			BRANCH_LIST="${BRANCH_LIST}${BRANCH}";
		done
	fi


	if [ "${GIT_BACKUP_FLAG_DEBUG}" == "1" ];
	then
		echo "$(get_time)get_git(): use BRANCH_LIST:\"${BRANCH_LIST}\"";
	fi


# update or clone branches
	for BRANCH in ${BRANCH_LIST};
	do
		if [ "${BRANCH}" == "" ];
		then
			continue;
		fi


		FLAG_GLOBAL_FOUND="$(git branch -r | sed -e 's/\ *origin\///g' | grep "^${BRANCH}$" | wc -l)";
		if [ "${FLAG_GLOBAL_FOUND}" == "0" ];
		then
			echo "$(get_time)    ignore branch \"${BRANCH}\"";
			continue;
		fi


		FLAG_LOCAL_FOUND="$(git branch | sed -e 's/\*\ //g' | grep "${BRANCH}" | wc -l)";
		if [ "${FLAG_LOCAL_FOUND}" == "1" ];
		then
			echo "$(get_time)    update branch \"${BRANCH}\"";
			git checkout "${BRANCH}" &> /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)ERROR: unknown error";
				echo;
				echo;
				exit 1;
			fi


			LAST_COMMIT_HASH="$(git log -n 1 --format=%H)";


			git pull origin "${BRANCH}" &> /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)ERROR: unknown error";
				echo;
				echo;
				exit 1;
			fi


			LAST_COMMIT_HASH_CUR="$(git log -n 1 --format=%H)";


			if [ "${LAST_COMMIT_HASH}" != "${LAST_COMMIT_HASH_CUR}" ];
			then
				FLAG_REPO_UPDATE='1';
			fi
		else
			echo "$(get_time)    clone branch \"${BRANCH}\"";
			git checkout -b "${BRANCH}" remotes/origin/"${BRANCH}" &> /dev/null;
			if [ "${?}" != "0" ];
			then
				echo "$(get_time)ERROR: unknown error";
				echo;
				echo;
				exit 1;
			fi
			FLAG_REPO_UPDATE='1';
		fi
	done


# back to default branch
	git checkout "${DEFAULT_BRANCH}" &> /dev/null;


	cd ..;


# pack modify repository
	if [ "${FLAG_REPO_UPDATE}" == "0" ];
	then
		echo "$(get_time)repository \"${NAME}\" NOT modify";
	else
		pack "${NAME}";
	fi


# delete clone repo
	if [ "${GIT_BACKUP_FLAG_SMALL_AND_SLOW}" == "1" ];
	then
		rm -rf "${NAME}" &> /dev/null;
	fi


	KILL_RING_PATH="${GIT_BACKUP_DIR}/${NAME}";
	KILL_RING_MAX_ITEM_COUNT="${GIT_BACKUP_MAX_ITEM_COUNT}";
	kill_ring;


	cd ..;
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# parse repo list
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
			echo "$(get_time)parse(): REPO_ITEM=\"${REPO_ITEM}\"";
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
				echo "$(get_time)parse(): BRANCH=\"${BRANCH}\"";
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
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# general function
function main()
{
	echo "$(get_time)run git_backup v0.1.0";


	CHECK_PROG_LIST='awk date git grep head ionice ls mkdir mv nice rm sed sort tar wc xargs';
	check_prog;


	HEAD_DATE="$(date +'%s')";


	if [ "${GIT_BACKUP_REPO_LIST}" == "" ];
	then
		echo "$(get_time)ERROR: variable \"GIT_BACKUP_REPO_LIST\" not found...";
		echo;
		echo;
		exit 1;
	fi

	if [ "${GIT_BACKUP_DIR}" == "" ];
	then
		echo "$(get_time)ERROR: variable \"GIT_BACKUP_DIR\" not found...";
		echo;
		echo;
		exit 1;
	fi

	mkdir -p "${GIT_BACKUP_DIR}" &> /dev/null;

	if [ ! -d "${GIT_BACKUP_DIR}" ];
	then
		echo "$(get_time)ERROR: dir \"GIT_BACKUP_DIR\" not found...";
		echo;
		echo;
		exit 1;
	fi


	alarm;
	echo "$(get_time)use backup dir \"${GIT_BACKUP_DIR}\"";
	cd "${GIT_BACKUP_DIR}";


	parse;


	TAIL_DATE="$(date +'%s')";


	(( TAIL_DATE -= HEAD_DATE ));
	echo "$(get_time)work time: ${TAIL_DATE} secs";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
main;

echo "$(get_time)Ok.";
echo;
echo;
exit 0;
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
