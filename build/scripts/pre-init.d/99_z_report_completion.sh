#!/usr/bin/env sh
START_TIME=`cat /tmp/start_time`
NOW=`date +%s`
STARTUP_TIME=`expr $NOW - $START_TIME`

printf "\nDeployment Complete!\n\n"
column /tmp/deploy_time.txt -t -s "|"
printf "\n"
printf "> Total Container Startup Time: %ss" ${STARTUP_TIME}
printf "\n"
