#!/bin/bash

WORKER=http://xiangfu.0:x@pool.ABCPool.co:8332 
SERIAL=/dev/ttyUSB0

LOG_DIR=../log
mkdir -p ${LOG_DIR}

ERROR_FILE=${LOG_DIR}/miner.err

COUNTER=1

while [ true ]
do
    echo `date` : Start ... >> ${ERROR_FILE}
    python miner.py -u ${WORKER} -s ${SERIAL} > ${LOG_DIR}/`date +%Y%m%d`.${COUNTER}.log 2>&1
    echo `date` : Exit with: $?. Counter: ${COUNTER} >> ${ERROR_FILE}
    let COUNTER=COUNTER+1 
done
