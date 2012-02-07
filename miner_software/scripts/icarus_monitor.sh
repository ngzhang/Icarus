#!/bin/sh

SCRIPT_PATH=`pwd`

${SCRIPT_PATH}/icarus_undermanager.py > ${SCRIPT_PATH}/u.log 2>&1

TRUE_COUNT=`more ${SCRIPT_PATH}/u.log | grep "\"alive\": true"   | wc -l`
HASHRATE=`more ${SCRIPT_PATH}/u.log | grep "\"hashrate\": 0,"  | wc -l`

if [ "${TRUE_COUNT}" == "0" ] || [ "${HASHRATE}" == "1" ]; then
    echo `date`  >> ${SCRIPT_PATH}/restart.log

    killall -s 15 miner.sh
    ps ax | grep "python ./miner.py" | grep -v grep | sed 's/^ *//' | cut -d ' ' -f 1 | xargs kill -15

    ICARUS_MINING_PATH="../queue_ver"
    (cd ${ICARUS_MINING_PATH} && ./miner.sh &)
fi
