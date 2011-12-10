#!/bin/bash

LOG_DIR=./log
mkdir -p ${LOG_DIR}

ERROR_FILE=log/miner.err

COUNTER=0

while [ true ]
do
    echo `date` : Start ... >> ${ERROR_FILE}
    tclsh8.5 mine.tcl
    RESULT="$?"
    let COUNTER=COUNTER+1 
    echo `date` : Exit. Result: ${RESULT} Counter: ${COUNTER} >> ${ERROR_FILE}
    mv miner.log log/miner.${COUNTER}.log
done
