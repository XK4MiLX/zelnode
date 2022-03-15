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

function get_ip(){
 WANIP=$(curl --silent -m 10 https://api4.my-ip.io/ip | tr -dc '[:alnum:].')

  if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
   WANIP=$(curl --silent -m 10 https://checkip.amazonaws.com | tr -dc '[:alnum:].')
  fi

  if [[ "$WANIP" == "" || "$WANIP" = *html* ]]; then
   WANIP=$(curl --silent -m 10 https://api.ipify.org | tr -dc '[:alnum:].')
  fi
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
string=${string::50}
else
string=$1
string_color=$2
string_leght=${#string}
string_leght_color=${#string_color}
string_diff=$((string_leght_color-string_leght))
string=${string_color::50+string_diff}
fi
echo -e "${ARROW} ${CYAN}$string[${CHECK_MARK}${CYAN}]${NC}"
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


 function insertAfter
{
   local file="$1" line="$2" newText="$3"
   sudo sed -i -e "/$line/a"$'\\\n'"$newText"$'\n' "$file"
}


echo -e ""
get_ip

  while true
     do

        echo -e "${ARROW}${YELLOW} Checking port validation.....${NC}"
        FLUX_PORT=$(whiptail --inputbox "Enter your FluxOS port (Ports allowed are: 16127, 16137, 16147, 16157, 16167, 16177, 16187, 16197)" 8 120 3>&1 1>&2 2>&3)
        if [[ $FLUX_PORT == "16127" || $FLUX_PORT == "16137" || $FLUX_PORT == "16147" || $FLUX_PORT == "16157" || $FLUX_PORT == "16167" || $FLUX_PORT == "16177" || $FLUX_PORT == "16187" || $FLUX_PORT == "16187" ]]; then

           string_limit_check_mark "Port is valid..........................................."

           echo -e "${ARROW}${YELLOW} Checking port availability.....${NC}"
           port_check=$(curl -s -m 5 http://$WANIP:$FLUX_PORT/id/loginphrase 2>/dev/null | jq -r .status 2>/dev/null )
           if [[ "$port_check" == "" && $(cat /home/$USER/zelflux/config/userconfig.js | grep "$FLUX_PORT") == "" ]]; then
             string_limit_check_mark "Port $FLUX_PORT is OK..........................................."
             break
           else
             string_limit_x_mark "Port $FLUX_PORT is already in use..............................."
             sleep 1
           fi



         else
           string_limit_x_mark "Port $FLUX_PORT is not allowed..............................."
           sleep 1
        fi
    done


if [[ $(cat /home/$USER/zelflux/config/userconfig.js | grep "apiport") != "" ]]; then

  sed -i "s/$(grep -e apiport /home/$USER/zelflux/config/userconfig.js)/apiport: '$FLUX_PORT',/" /home/$USER/zelflux/config/userconfig.js

  if [[ $(grep -w $FLUX_PORT /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
     echo -e "${ARROW} ${CYAN}FluxOS port replaced successful...................[${CHECK_MARK}${CYAN}]${NC}"
  fi

else

   insertAfter "/home/$USER/zelflux/config/userconfig.js" "zelid" "apiport: '$FLUX_PORT',"
   echo -e "${ARROW} ${CYAN}FluxOS port set successful........................[${CHECK_MARK}${CYAN}]${NC}"


fi

if [[ -d /home/$USER/.fluxbenchmark ]]; then
  sudo mkdir -p /home/$USER/.fluxbenchmark 2>/dev/null
  echo "fluxport=$FLUX_PORT" | sudo tee "/home/$USER/.fluxbenchmark/fluxbench.conf" > /dev/null
else
  echo "fluxport=$$FLUX_PORT" | sudo tee "/home/$USER/.fluxbenchmark/fluxbench.conf" > /dev/null
fi

if [[ -f /home/$USER/.fluxbenchmark/fluxbench.conf ]]; then
  echo -e "${ARROW} ${CYAN}Fluxbench port set successful.....................[${CHECK_MARK}${CYAN}]${NC}"
  echo -e "${ARROW} ${YELLOW}Restarting FluxOS and Benchmark.....${NC}"
  sudo systemctl restart zelcash  > /dev/null 2>&1
  pm2 restart flux  > /dev/null 2>&1
  sleep 180
fi

echo -e ""
