#!/bin/bash

#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9C\x96${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
CLOCK="${GREEN}\xE2\x8C\x9B${NC}"
ARROW="${SEA}\xE2\x96\xB6${NC}"
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
HOT="${ORANGE}\xF0\x9F\x94\xA5${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"

#dialog color
export NEWT_COLORS='
title=black,
'

function round() {
  printf "%.${2}f" "${1}"
}

function max(){
    m="0"
    for n in "$@"
    do        
        if egrep -o "^[0-9]+$" <<< "$n" &>/dev/null; then
            [ "$n" -gt "$m" ] && m="$n"
        fi
    done
    echo "$m"
}

function string_limit_x_mark() {
    if [[ -z "$2" ]]; then
        string="$1"
        string=${string::50}
    else
        string=$1
        string_color=$2
        string_leght=${#string}
        string_leght_color=${#string_color}
        string_diff=$((string_leght_color-string_leght))
        string=${string_color::50+string_diff}
    fi
        echo -e "${ARROW} ${CYAN}$string[${X_MARK}${CYAN}]${NC}"
}

function string_limit_check_mark_port() {
    if [[ -z "$2" ]]; then
        string="$1"
        string=${string::65}
    else
        string=$1
        string_color=$2
        string_leght=${#string}
        string_leght_color=${#string_color}
        string_diff=$((string_leght_color-string_leght))
        string=${string_color::65+string_diff}
    fi
        echo -e "${PIN}${CYAN}$string[${CHECK_MARK}${CYAN}]${NC}"
}

function string_limit_check_mark() {
    if [[ -z "$2" ]]; then
        string="$1"
        string=${string::40}
    else
        string=$1
        string_color=$2
        string_leght=${#string}
        string_leght_color=${#string_color}
        string_diff=$((string_leght_color-string_leght))
        string=${string_color::40+string_diff}
    fi
    echo -e "${ARROW} ${CYAN}$string[${CHECK_MARK}${CYAN}]${NC}"
}

function spinning_timer() {
    animation=( ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ )
    end=$((SECONDS+NUM))
    while [ $SECONDS -lt $end ];
    do
        for i in "${animation[@]}";
        do
	    echo -e ""
            echo -ne "${RED}\r\033[1A\033[0K$i ${CYAN}${MSG1}${NC}"
            sleep 0.1
	    
        done
    done
    echo -ne "${MSG2}"
}

