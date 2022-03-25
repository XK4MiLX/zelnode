#!/bin/bash

function CORES(){

  local -i SOCKETS=$(grep -w "physical id" /proc/cpuinfo | sort -u | wc -l)
  [ "${SOCKETS}" -eq 0 ] && SOCKETS="1"
  local -i CORES=$(grep -w "core id" /proc/cpuinfo | sort -u | wc -l)
  [ "${CORES}" -eq 0 ] && CORES="1"
  local -r MODEL=$(grep -w "model name" /proc/cpuinfo | sort -u | awk -F:     '{print $2}')
  local -ir THREADS=$(grep -w "processor" /proc/cpuinfo | sort -u | wc -l)
  local -ir TOTAL_CORES=$(echo $((${SOCKETS}*${CORES})))
  local -ir THREADS_PER_CORE=$(echo $((${THREADS}/${TOTAL_CORES})))

  echo -e "ModelName\t: " $MODEL
  echo -e "Sockets\t\t: " $SOCKETS
  echo -e "Cores/Socket\t: " $CORES
  echo -e "Threads/Core\t: " $THREADS_PER_CORE
  echo -e "TotalCores\t: " $TOTAL_CORES
  echo -e "TotalThreads\t: " $THREADS

}

CORES
