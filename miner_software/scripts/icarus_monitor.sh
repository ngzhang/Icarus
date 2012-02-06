#!/bin/sh

SCRIPT_PATH=`pwd`

${SCRIPT_PATH}/icarus_undermanager.py > ${SCRIPT_PATH}/u.log 2>&1

TRUE_COUNT=`more ${SCRIPT_PATH}/u.log | grep "\"alive\": true" | wc -l`
if [ "${TRUE_COUNT}" == "0" ]; then
    echo `date`  >> ${SCRIPT_PATH}/restart.log
    ${SCRIPT_PATH}/icarus_restart_miner.sh
fi
