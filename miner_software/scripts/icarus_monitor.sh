#!/bin/bash

DATE=`date +%Y%m%d-%H:%M`

MONITOR_MSG=`mktemp`
/home/xiangfu/PanGu/Icarus/undermanager/undermanager > ${MONITOR_MSG} 2>&1

FALSE_COUNT=`more ${MONITOR_PATH}/${DATE}.xiangfu.log | grep "\"alive\": false" | wc -l`

if [ "${FALSE_COUNT}" != "1" ]; then
    /home/xiangfu/bin/restart_miner.sh      >> ${MONITOR_PATH}/restart.log 2>&1
fi
