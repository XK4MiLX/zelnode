#!/bin/bash

BOOTSTRAP_ZIPFILE='flux_explorer_bootstrap.tar.gz'

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

  if [[ "$WANIP" == "" ]]; then
   WANIP=$(curl --silent -m 10 https://checkip.amazonaws.com | tr -dc '[:alnum:].')
  fi

  if [[ "$WANIP" == "" ]]; then
   WANIP=$(curl --silent -m 10 https://api.ipify.org | tr -dc '[:alnum:].')
  fi
}

function bootstrap_geolocation(){

IP=$WANIP
ip_output=$(curl -s -m 10 http://ip-api.com/json/$1?fields=status,country,timezone | jq .)
ip_status=$( jq -r .status <<< "$ip_output")

if [[ "$ip_status" == "success" ]]; then
country=$(jq -r .country <<< "$ip_output")
org=$(jq -r .org <<< "$ip_output")
continent=$(jq -r .timezone <<< "$ip_output")
else
country="UKNOW"
continent="UKNOW"
fi

continent=$(cut -f1 -d"/" <<< "$continent" )

if [[ "$continent" =~ "Europe" ]]; then
 continent="EU"
elif [[ "$continent" =~ "America" ]]; then
 continent="US"
elif [[ "$continent" =~ "Asia" ]]; then
 continent="AS"
else
 continent="ALL"
fi

echo -e "${ARROW} ${CYAN}Selecting bootstrap server....${NC}"
echo -e "${ARROW} ${CYAN}Node Location -> IP:$IP, Country: $country, Continent: $continent ${NC}"
echo -e "${ARROW} ${CYAN}Searching in $continent....${NC}"
bootstrap_server $continent


}

function bootstrap_server(){
rand_by_domain=("1" "2" "3" "5" "6" "7" "8" "9" "10" "11")
richable=()
richable_eu=()
richable_us=()
richable_as=()

i=0
len=${#rand_by_domain[@]}
#echo -e "Bootstrap on list: $len"
while [ $i -lt $len ];
do

    #echo ${rand_by_domain[$i]}
    bootstrap_check=$(curl -sSL -m 10 http://cdn-${rand_by_domain[$i]}.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.json | jq -r '.block_height' 2>/dev/null)
    #echo -e "Height: $bootstrap_check"
    if [[ "$bootstrap_check" != "" ]]; then
    #echo -e "Adding:  ${rand_by_domain[$i]}"

       if [[ "${rand_by_domain[$i]}" -le "3" ]]; then
         richable_eu+=( ${rand_by_domain[$i]}  )
       fi

       if [[ "${rand_by_domain[$i]}" -gt "3" &&  "${rand_by_domain[$i]}" -le "10" ]]; then
         richable_us+=( ${rand_by_domain[$i]}  )
       fi

       if [[ "${rand_by_domain[$i]}" -gt "10" ]]; then
         richable_as+=( ${rand_by_domain[$i]}  )
       fi

        richable+=( ${rand_by_domain[$i]} )
    fi

    i=$(($i+1))

done

server_found="1"
if [[ "$continent" == "EU" ]]; then
  len_eu=${#richable_eu[@]}
  if [[ "$len_eu" -gt "0" ]]; then
    richable=( ${richable_eu[*]} )
    echo -e "Final: ${richable[*]}"
  fi
  if [[ "$len_eu" == "0" ]]; then
     continent="EU"
     echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
     len_us=${#richable_us[@]}
     if [[ "$len_us" -gt "0" ]]; then
      richable=( ${richable_us[*]} )
     fi
     if [[ "$len_us" == "0" ]]; then
       continent="US"
       echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
       server_found="0"
     fi
   fi
elif [[ "$continent" == "US" ]]; then
  len_us=${#richable_us[@]}
  if [[ "$len_us" -gt "0" ]]; then
    richable=( ${richable_us[*]} )
    echo -e "Final: ${richable[*]}"
  fi
  if [[ "$len_us" == "0" ]]; then
    continent="US"
    echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
    len_as=${#richable_as[@]}
    if [[ "$len_as" -gt "0" ]]; then
     richable=( ${richable_as[*]} )
     echo -e "Final: ${richable[*]}"
    fi
    if [[ "$len_as" == "0" ]]; then
      continent="AS"
      echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
      len_eu=${#richable_eu[@]}
        if [[ "$len_eu" -gt "0" ]]; then
          richable=( ${richable_eu[*]} )
          echo -e "Final: ${richable[*]}"
        fi
       if [[ "$len_eu" == "0" ]]; then
        continent="EU"
        echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
        server_found="0"
       fi
    fi
  fi
elif [[ "$continent" == "AS" ]]; then
  len_as=${#richable_as[@]}
  if [[ "$len_as" -gt "0" ]]; then
    richable=( ${richable_as[*]} )
    echo -e "Final: ${richable[*]}"
  fi
  if [[ "$len_as" == "0" ]]; then
    continent="AS"
    echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
    len_us=${#richable_us[@]}
    if [[ "$len_us" -gt "0" ]]; then
      richable=( ${richable_us[*]} )
      echo -e "Final: ${richable[*]}"
    fi
    if [[ "$len_us" == "0" ]]; then
      continent="US"
      echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
      len_eu=${#richable_eu[@]}
       if [[ "$len_eu" -gt "0" ]]; then
         richable=( ${richable_eu[*]} )
         echo -e "Final: ${richable[*]}"
       fi
       if [[ "$len_eu" == "0" ]]; then
        continent="EU"
        echo -e "${WORNING} ${CYAN}All Bootstrap in $continent are offline, checking other location...${NC}" && sleep 1
        server_found="0"
       fi
    fi
  fi
else
   len=${#richable[@]}
   if [[ "$len" == "0" ]]; then
    echo -e "${WORNING} ${CYAN}All Bootstrap server offline, operation skipped.. ${NC}" && sleep 1
    Server_offline=1
    return 1
   fi
fi



if [[ "$server_found" == "0" ]]; then
  len=${#richable[@]}
  if [[ "$len" == "0" ]]; then
    echo -e "${WORNING} ${CYAN}All Bootstrap server offline, operation skipped.. ${NC}" && sleep 1
    Server_offline=1
    return 1
  fi
fi

Server_offline=0

}



get_ip
bootstrap_geolocation

if [[ "$Server_offline" == "1" ]]; then
     exit 1
fi

    #bootstrap_rand_ip
    bootstrap_index=$((${#richable[@]}-1))
    r=$(shuf -i 0-$bootstrap_index -n 1)
    indexb=${richable[$r]}
    BOOTSTRAP_ZIP="http://cdn-$indexb.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.tar.gz"
    echo -e "$BOOTSTRAP_ZIP"
