#!/bin/sh

LOG_DIR=../log
mkdir -p ${LOG_DIR}

ERROR_FILE=${LOG_DIR}/miner.err

#WORKER=http://xiangfu.0:x@pool.ABCPool.co:8332
#WORKER=http://xiangfu.z@gmail.com_0:1234@127.0.0.1:9332/

WORKER=http://xiangfu.z@gmail.com_0:1234@pit.deepbit.net:8332/

./miner.py -u ${WORKER} -s /dev/ttyUSB0 > ${LOG_DIR}/`date +%Y%m%d-%H:%M`.log 2>&1
