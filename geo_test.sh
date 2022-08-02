#!/bin/bash

source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/flux_common.sh)"

# THIS LOOKS UNUSED. CANDIDATE FOR DELETION.
function server_geolocation(){

ip_output1=$(curl -s -m 10 http://ip-api.com/json/cdn-${rand_by_domain[$i]}.runonflux.io?fields=status,country,timezone 2>/dev/null | jq . 2>/dev/null)
ip_status1=$( jq -r .status 2>/dev/null <<< "$ip_output")

if [[ "$ip_status1" == "success" ]]; then
country1=$(jq -r .country <<< "$ip_output1")
org1=$(jq -r .org <<< "$ip_output1")
continent1=$(jq -r .timezone <<< "$ip_output1")
else
country1="UKNOW"
continent1="UKNOW"
fi

continent1=$(cut -f1 -d"/" <<< "$continent1" )

if [[ "$continent1" =~ "Europe" ]]; then
 server_continent="EU"
fi

if [[ "$continent1" =~ "America" ]]; then
 server_continent="US"
fi

if [[ "$continent1" =~ "Asia" ]]; then
 server_continent="AS"
fi

#echo -e "${ARROW} ${CYAN}Checking bootstrap server location....${NC}"
#echo -e "${ARROW} ${CYAN}Server Location: $country, Continent: $continent ${NC}"

}


if ! jq --version > /dev/null 2>&1; then
  sudo apt install jq -y > /dev/null 2>&1
fi

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
