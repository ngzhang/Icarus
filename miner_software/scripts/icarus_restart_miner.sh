#!/bin/bash

killall -s 15 miner.sh
ps ax | grep "python ./miner.py" | grep -v grep | sed 's/^ *//' | cut -d ' ' -f 1 | xargs kill -15

ICARUS_MINING_PATH="/home/xiangfu/PanGu/Icarus/Icarus-Mining"

(cd ${ICARUS_MINING_PATH}/miner0/queue && ./miner.sh &)
(cd ${ICARUS_MINING_PATH}/miner1/queue && ./miner.sh &)
