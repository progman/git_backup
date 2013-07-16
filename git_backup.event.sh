#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Event for run backup in cron now
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# check depends
function check_prog()
{
	for i in ${CHECK_PROG_LIST};
	do
		if [ "$(which ${i})" == "" ];
		then
			echo "$(get_time)[!]FATAL: you must install \"${i}\"...";
			echo;
			echo;
			exit 1;
		fi
	done
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
# general function
function main()
{
	touch "${EVENTFILE}";


	CHECK_PROG_LIST='date sed printf';
	check_prog;


	NEW_MIN=$(date '+%M' | sed -e 's/^0//g');
	(( NEW_MIN += 1 ));

	if [ "${NEW_MIN}" == "60" ];
	then
		NEW_MIN="0";
	fi


	while true;
	do
		CUR_MIN=$(date '+%M' | sed -e 's/^0//g');

		if [ "${CUR_MIN}" == "${NEW_MIN}" ];
		then
			break;
		fi

		CUR_SEC=$(date '+%S' | sed -e 's/^0//g');

		(( XSEC = 60 - CUR_SEC ));
		XSEC_STR=$(printf '%02u' "${XSEC}");

		echo -en "\revent left time: ${XSEC_STR}";

		sleep 1;
	done
	echo -en "\r                   \r";
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
EVENTFILE="/tmp/git_backup.event";

main;
exit 0;
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
