#!/bin/bash

#const
REPLACE="0"
FLUXCONF="0"
FLUXRESTART="0"
ZELCONF="0"
BTEST="0"
LC_CHECK="0"
ZELFLUX_PORT1="0"
ZELFLUX_PORT2="0"
FLUX_UPDATE="0"
OWNER="0"
SCVESION=v4.0

#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'
ORANGE='\e[38;5;202m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9C\x96${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
HOT="${ORANGE}\xF0\x9F\x94\xA5${NC}"
ARROW="${CYAN}\xE2\x96\xB6${NC}"

#dialog color
export NEWT_COLORS='
title=black,
'
WANIP=$(wget http://ipecho.net/plain -O - -q)
#function
function show_time() {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo -e "${PIN} ${CYAN}Last error was \c"
    echo -e "${RED}$day"d "$hour"h "$min"m "$sec"s"${CYAN} ago.${NC}"
}

function spinning_timer() {
    animation=( ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ )
    end=$((SECONDS+NUM))
    while [ $SECONDS -lt $end ];
    do
        for i in "${animation[@]}";
        do
            echo -ne "${RED}\r$i ${CYAN}${MSG1}${NC}"
            sleep 0.1
        done
    done
    echo -e "${MSG2}"
}

round() {
  printf "%.${2}f" "${1}"
}

function check_listen_ports(){

if ! lsof -v > /dev/null 2>&1; then
sudo apt-get install lsof -y > /dev/null 2>&1 && sleep 2
fi


if sudo lsof -i  -n | grep LISTEN | grep 27017 | grep mongod > /dev/null 2>&1
then
echo -e "${CHECK_MARK} ${CYAN} Mongod listen on port 27017${NC}"
else
echo -e "${X_MARK} ${CYAN} Mongod not listen${NC}"
fi

if sudo lsof -i  -n | grep LISTEN | grep 16125 | grep zelcashd > /dev/null 2>&1
then
echo -e "${CHECK_MARK} ${CYAN} Zelcash listen on port 16125${NC}"
else
echo -e "${X_MARK} ${CYAN} Zelcash not listen${NC}"
fi

if sudo lsof -i  -n | grep LISTEN | grep 16125 | grep zelbenchd > /dev/null 2>&1
then
echo -e "${CHECK_MARK} ${CYAN} Zelbench listen on port 16125${NC}"
else
echo -e "${X_MARK} ${CYAN} Zelbench not listen${NC}"
fi

if sudo lsof -i  -n | grep LISTEN | grep 16126 | grep node > /dev/null 2>&1 
then
ZELFLUX_PORT1="1"
fi

if sudo lsof -i  -n | grep LISTEN | grep 16126 | grep node > /dev/null 2>&1 
then
ZELFLUX_PORT2="1"
fi

if [[ "$ZELFLUX_PORT1" == "1" && "$ZELFLUX_PORT2" == "1"  ]]
then
echo -e "${CHECK_MARK} ${CYAN} Zelflux listen on ports 16126/16127${NC}"
else
echo -e "${X_MARK} ${CYAN} Zelflux not listen${NC}"
fi

}

function integration(){

PATH_TO_FOLDER=( /usr/local/bin/ ) 
FILE_ARRAY=( 'zelbench-cli' 'zelbenchd' 'zelcash-cli' 'zelcashd' 'zelcash-fetch-params.sh' 'zelcash-tx' )
ELEMENTS=${#FILE_ARRAY[@]}
NOT_FOUND="0"

for (( i=0;i<$ELEMENTS;i++)); do
 
        if [ -f $PATH_TO_FOLDER${FILE_ARRAY[${i}]} ]; then
            echo -e "${CHECK_MARK} ${CYAN} ${FILE_ARRAY[${i}]}"
        else
            echo -e "${X_MARK} ${CYAN} ${FILE_ARRAY[${i}]}"
            NOT_FOUND="1"
        fi 
done

}

function check_benchmarks() {
 var_benchmark=$(zelbench-cli getbenchmarks | jq ".$1")
 limit=$2
 if [[ $(echo "$limit>$var_benchmark" | bc) == "1" ]]
 then
  var_round=$(round "$var_benchmark" 2)
  echo -e "${X_MARK} ${CYAN}$3 $var_round $4${NC}"
 fi

}

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi
sleep 1
sudo apt install bc > /dev/null 2>&1

if [ -f /home/$USER/.zelbenchmark/debug.log ]; then
echo -e "${BOOK} ${YELLOW}Checking zelbenchmark debug.log${NC}"
if [[ $(egrep -ac -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log) != "0" ]]; then
echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(egrep -ac -wi --color 'error|failed' /home/$USER/.zelbenchmark/debug.log)${CYAN} error events${NC}"
#egrep -wi --color 'warning|error|critical|failed' ~/.zelbenchmark/debug.log
error_line=$(egrep -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
event_date=$(egrep -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}')
echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
event_time_uxtime=$(date -ud "$event_date" +"%s")
event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
event_time="$event_time_uxtime"
now_date=$(date +%s)
tdiff=$((now_date-event_time))
show_time "$tdiff"
echo -e "${PIN} ${CYAN}Creating zelbenchmark_debug_error.log${NC}"
egrep -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log > /home/$USER/zelbenchmark_debug_error.log
echo
else
echo -e "${GREEN}\xF0\x9F\x94\x8A ${CYAN}Found: ${GREEN}0 errors${NC}"
echo
fi
#else
#echo -e "${RED}Debug file not exists${NC}"
#echo
fi

if [ -f /home/$USER/.zelcash/debug.log ]; then
echo -e "${BOOK} ${YELLOW}Checking zelcash debug.log${NC}"
if [[ $(egrep -ac -wi --color 'error|failed' /home/$USER/.zelcash/debug.log) != "0" ]]; then
echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(egrep -ac -wi --color 'error|failed' /home/$USER/.zelcash/debug.log)${CYAN} error events, ${RED}$(egrep -ac -wi --color 'benchmarking' /home/$USER/.zelcash/debug.log) ${CYAN}related to benchmark${NC}"
if [[ $(egrep -ac -wi --color 'benchmarking' /home/$USER/.zelcash/debug.log) != "0" ]]; then
echo -e "${BOOK} ${CYAN}ZelBench errors info:${NC}"
error_line=$(egrep -wi --color 'benchmarking' /home/$USER/.zelcash/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
event_date=$(egrep -wi --color 'benchmarking' /home/$USER/.zelcash/debug.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}')
echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
event_time_uxtime=$(date -ud "$event_date" +"%s")
event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
event_time="$event_time_uxtime"
now_date=$(date +%s)
tdiff=$((now_date-event_time))
show_time "$tdiff"
fi
echo -e "${PIN} ${CYAN}Creating zelcash_debug_error.log${NC}"
egrep -wi --color 'error|failed' /home/$USER/.zelcash/debug.log > /home/$USER/zelcash_debug_error.log
echo
else
echo -e "${GREEN}\xF0\x9F\x94\x8A ${CYAN}Found: ${GREEN}0 errors${NC}"
echo
fi
#else
#echo -e "${RED}Debug file not exists${NC}"
#echo
fi

if zelcash-cli getinfo > /dev/null 2>&1; then

echo -e "${BOOK} ${YELLOW}ZelBench status:${NC}"
zelbench_getatus=$(zelbench-cli getstatus)
zelbench_status=$(jq -r '.status' <<< "$zelbench_getatus")
zelbench_benchmark=$(jq -r '.benchmarking' <<< "$zelbench_getatus")
zelbench_zelback=$(jq -r '.zelback' <<< "$zelbench_getatus")
zelbench_getinfo=$(zelbench-cli getinfo)
zelbench_version=$(jq -r '.version' <<< "$zelbench_getinfo")

if [[ "$zelbench_benchmark" == "failed" || "$zelbench_benchmark" == "toaster" ]]; then
zelbench_benchmark_color="${RED}$zelbench_benchmark"
else
zelbench_benchmark_color="${SEA}$zelbench_benchmark"
fi

if [[ "$zelbench_status" == "online" ]]; then
zelbench_status_color="${SEA}$zelbench_status"
else
zelbench_status_color="${RED}$zelbench_status"
fi

if [[ "$zelbench_zelback" == "connected" ]]; then
zelbench_zelback_color="${SEA}$zelbench_zelback"
else
zelbench_zelback_color="${RED}$zelbench_zelback"
fi

echo -e "${PIN} ${CYAN}Zelbench version: ${SEA}$zelbench_version${NC}"
echo -e "${PIN} ${CYAN}Zelbench status: $zelbench_status_color${NC}"
echo -e "${PIN} ${CYAN}Benchmark: $zelbench_benchmark_color${NC}"
echo -e "${PIN} ${CYAN}ZelBack: $zelbench_zelback_color${NC}"
echo -e "${NC}"

if [[ "$zelbench_benchmark" == "BASIC" || "$zelbench_benchmark" == "SUPER" || "$zelbench_benchmark" == "BAMF" ]]; then
echo -e "${CHECK_MARK} ${CYAN} ZelBench working correct, all requirements met.${NC}"
fi

if [[ "$zelbench_benchmark" == "failed" ]]; then
echo -e "${X_MARK} ${CYAN} ZelBench problem detected, check zelbenchmark debug.log${NC}"
fi

if [[ "$zelbench_benchmark" == "toaster" ]]; then
BTEST="1"
echo -e "${X_MARK} ${CYAN} ZelBench working correct but minimum system requirements not met.${NC}"
check_benchmarks "eps" "89.99" "CPU speed" "< 90.00 events per second"
check_benchmarks "ddwrite" "159.99" "Disk write speed" "< 160.00 events per second"
fi

if [[ "$zelbench_benchmark" == "toaster" || "$zelbench_benchmark" == "failed" ]]; then
lc_numeric_var=$(locale | grep LC_NUMERIC | sed -e 's/.*LC_NUMERIC=//')
lc_numeric_need='"en_US.UTF-8"'

if [ "$lc_numeric_var" == "$lc_numeric_need" ]
then
echo -e "${CHECK_MARK} ${CYAN}LC_NUMERIC is correct${NC}"
else
echo -e "${X_MARK} ${CYAN}You need set LC_NUMERIC to en_US.UTF-8${NC}"
LC_CHECK="1"
fi

fi

if [[ "$zelbench_zelback" == "disconnected" ]]; then
echo -e "${X_MARK} ${CYAN} ZelBack does not work properly${NC}"
fi


WANIP=$(wget http://ipecho.net/plain -O - -q) 
if [[ "$WANIP" == "" ]]; then
  WANIP=$(curl ifconfig.me)     
fi

device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://')
local_device_ip=$(ip a list $device_name | grep -o $WANIP )

if [[ "$WANIP" != "" && "$local_device_ip" != "" ]]; then

  if [[ "$local_device_ip" == "$WANIP" ]]; then
    echo -e "${CHECK_MARK} ${CYAN} Public IP(${GREEN}$WANIP${CYAN}) matches local device(${GREEN}$device_name${CYAN}) IP(${GREEN}$local_device_ip${CYAN})${NC}"
  else
   echo -e "${X_MARK} ${CYAN} Public IP(${GREEN}$WANIP${CYAN}) not matches local device(${GREEN}$device_name${CYAN}) IP${NC}"
   ## dev_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2"0"}')
   ## sudo ip addr add "$WANPI" dev "$dev_name"
  fi

fi

echo -e "${NC}"
echo -e "${BOOK} ${YELLOW}Zalcash deamon information:${NC}"
zelcash_getinfo=$(zelcash-cli getinfo)
version=$(jq -r '.version' <<< "$zelcash_getinfo")
blocks_hight=$(jq -r '.blocks' <<< "$zelcash_getinfo")
protocolversion=$(jq -r '.protocolversion' <<< "$zelcash_getinfo")
connections=$(jq -r '.connections' <<< "$zelcash_getinfo")

echo -e "${PIN} ${CYAN}Version: ${SEA}$version${NC}"
echo -e "${PIN} ${CYAN}Protocolversion: ${SEA}$protocolversion${NC}"
echo -e "${PIN} ${CYAN}Connections: ${SEA}$connections${NC}"
echo -e "${PIN} ${CYAN}Blocks: ${SEA}$blocks_hight${NC}"

if [[ $(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks') == "$blocks_hight" ]]; then
echo -e "${PIN} ${CYAN}Status: ${GREEN}synced${NC}"
else
echo -e "${PIN} ${CYAN}Status: ${RED}not synced${NC}"
fi

echo -e ""
echo -e "${BOOK} ${YELLOW}Checking node status:${NC}"
zelcash_getzelnodestatus=$(zelcash-cli getzelnodestatus)
node_status=$(jq -r '.status' <<< "$zelcash_getzelnodestatus")
collateral=$(jq -r '.collateral' <<< "$zelcash_getzelnodestatus")

if [ "$node_status" == "CONFIRMED" ]
then
node_status_color="${SEA}$node_status"
elif [ "$node_status" == "STARTED" ]
then
node_status_color="${YELLOW}$node_status"
else
node_status_color="${RED}$node_status"
fi

if [ "$node_status" != "CONFIRMED" ]
then

if whiptail --yesno "Would you like to verify zelcash.conf Y/N?" 8 60; then
ZELCONF="1"
zelnodeprivkey="$(whiptail --title "ZelNode ANALYZER/FiXER $SCVESION" --inputbox "Enter your zelnode Private Key generated by your Zelcore/Zelmate wallet" 8 72 3>&1 1>&2 2>&3)"
zelnodeoutpoint="$(whiptail --title "ZelNode ANALYZER/FiXER $SCVESION" --inputbox "Enter your zelnode Output TX ID" 8 72 3>&1 1>&2 2>&3)"
zelnodeindex="$(whiptail --title "ZelNode ANALYZER/FiXER $SCVESION" --inputbox "Enter your zelnode Output Index" 8 60 3>&1 1>&2 2>&3)"
fi

fi

echo -e "${PIN} ${CYAN}Node status: $node_status_color${NC}"
echo -e "${PIN} ${CYAN}Collateral: ${SEA}$collateral${NC}"
echo -e ""

echo -e "${BOOK} ${YELLOW}Checking collateral:${NC}"
txhash=$(grep -o "\w*" <<< "$collateral")
txhash=$(sed -n "2p" <<< "$txhash")
txhash=$(egrep "\w{10,50}" <<< "$txhash")

if [[ "$txhash" != "" ]]; then

#url_to_check="https://explorer.zel.cash/api/tx/$txhash"
#conf=$(wget -nv -qO - $url_to_check | jq '.confirmations')

	stak_info=$(zelcash-cli decoderawtransaction $(zelcash-cli getrawtransaction $txhash) | jq '.vout[].value' | egrep -n '10000|25000|100000'  | sed 's/:/ /' | awk '{print $1-1" "$2}')

	if [[ "$stak_info" != "" ]]; then

		if [[ -f /home/$USER/.zelcash/zelcash.conf ]]; then

		index_from_file=$(grep -w zelnodeindex /home/$USER/.zelcash/zelcash.conf | sed -e 's/zelnodeindex=//')
		collateral_index=$(awk '{print $1}' <<< "$stak_info")

			if [[ "$index_from_file" == "$collateral_index" ]]; then
			echo -e "${CHECK_MARK} ${CYAN} Zelnodeindex is correct"
			else
			echo -e "${X_MARK} ${CYAN} Zelnodeindex is not correct, correct one is $collateral_index"
			fi

		else
		collateral_index=$(awk '{print $1}' <<< "$stak_info")
		fi

		type=$(awk '{print $2}' <<< "$stak_info")
		conf=$(zelcash-cli gettxout $txhash $collateral_index | jq .confirmations)

		if [[ $conf == ?(-)+([0-9]) ]]; then
    			if [ "$conf" -ge "100" ]; then
     			 echo -e "${CHECK_MARK} ${CYAN} Confirmations numbers >= 100($conf)${NC}"
    			else
      			echo -e "${X_MARK} ${CYAN} Confirmations numbers < 100($conf)${NC}"
   			 fi
		else
		echo -e "${X_MARK} ${CYAN} Zelnodeoutpoint is not valid${NC}"
		fi
		
		
		if [[ $type == ?(-)+([0-9]) ]]; then

		case $type in
 		 "10000") echo -e "${ARROW}  ${CYAN}Tier: ${GREEN}BASIC${NC}" ;;
 		 "25000")  echo -e "${ARROW}  ${CYAN}Tier: ${GREEN}SUPER${NC}";;
	 	 "100000") echo -e "${ARROW}  ${CYAN}Tier: ${GREEN}BAMF${NC}";;
		esac
		
		case $zelbench_benchmark in
 		 "BASIC")  zelbench_benchmark_value=10000 ;;
 		 "SUPER")  zelbench_benchmark_value=25000 ;;
	 	 "BAMF") zelbench_benchmark_value=100000 ;;
		esac
		
		#echo -e "$zelbench_benchmark_value" -> 10000 BASIC
	       # echo -e "$type" -> 25000 SUPER

   		 if [[ -z zelbench_benchmark_value ]]; then
  		  echo -e ""
   		 else
		 
		 	if [[ "$zelbench_benchmark_value" -ge "$type" ]]; then
			
				case $type in
 				 "10000")  zelbench_benchmark_value_name="BASIC" ;;
 				 "25000")  zelbench_benchmark_value_name="SUPER" ;;
	 			 "100000") zelbench_benchmark_value_name="BAMF" ;;
				esac
			
			  echo -e "${CHECK_MARK} ${CYAN} Benchmark passed for ${GREEN}$zelbench_benchmark${CYAN} required ${GREEN}$zelbench_benchmark_value_name${NC}"
			else
			
				case $type in
 				 "10000")  zelbench_benchmark_value_name="BASIC" ;;
 				 "25000")  zelbench_benchmark_value_name="SUPER" ;;
	 			 "100000") zelbench_benchmark_value_name="BAMF" ;;
				esac
			
			  echo -e "${X_MARK} ${CYAN} Benchmark passed for ${GREEN}$zelbench_benchmark${CYAN} required ${RED}$zelbench_benchmark_value_name${NC}"
			fi
  		 fi
			
              fi
		
	else
	echo -e "${X_MARK} ${CYAN} Zelnodeoutpoint is not valid${NC}"
	fi
#url_to_check="https://explorer.zel.cash/api/tx/$txhash"
#type=$(wget -nv -qO - $url_to_check | jq '.vout' | grep '"value"' | egrep -o '10000|25000|100000')
#type=$(zelcash-cli gettxout $txhash 0 | jq .value)
fi
fi

echo -e "${NC}"
echo -e "${BOOK} ${YELLOW}Checking listen ports:${NC}"
check_listen_ports
echo -e "${NC}"
echo -e "${BOOK} ${YELLOW}File integration checking:${NC}"
integration
echo -e ""
#if ! whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60; then
   #WANIP=$(whiptail  --title "ZelNode ANALIZER/FiXER $SCVESION" --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
#fi
echo -e "${BOOK} ${YELLOW}Checking service:${NC}"

docker_working=0
snap_docker_running=$(systemctl status snap.docker.dockerd.service 2> /dev/null | grep 'running' | grep -o 'since.*')
snap_docker_inactive=$(systemctl status snap.docker.dockerd.service 2> /dev/null | egrep 'inactive|failed' | grep -o 'since.*')

docker_running=$(systemctl status docker 2> /dev/null  | grep 'running' | grep -o 'since.*')
docker_inactive=$(systemctl status docker 2> /dev/null | egrep 'inactive|failed' | grep -o 'since.*')

mongod_running=$(systemctl status mongod 2> /dev/null | grep 'running' | grep -o 'since.*')
mongod_inactive=$(systemctl status mongod 2> /dev/null | egrep 'inactive|failed' | grep -o 'since.*')

zelcash_running=$(systemctl status zelcash 2> /dev/null | grep 'running' | grep -o 'since.*')
zelcash_inactive=$(systemctl status zelcash 2> /dev/null | egrep 'inactive|failed' | grep -o 'since.*')


if systemctl list-units | grep snap.docker.dockerd.service | egrep -wi 'running' > /dev/null 2>&1; then
echo -e "${ARROW}  ${CYAN}Docker(SNAP) service running ${SEA}$snap_docker_running${NC}"
docker_working=1
else

if [ "$snap_docker_inactive" != "" ]; then
echo -e "${ARROW}  ${CYAN}Docker(SNAP) service not running ${RED}$snap_docker_inactive${NC}"
else
echo -e "${ARROW}  ${CYAN}Docker(SNAP) is not installed${NC}"
fi

fi

if systemctl list-units | grep docker.service | egrep -wi 'running' > /dev/null 2>&1; then
echo -e "${ARROW}  ${CYAN}Docker service running ${SEA}$docker_running${NC}"
docker_working=1
else
if [[ "$docker_inactive" != "" ]]; then
echo -e "${ARROW}  ${CYAN}Docker service not running ${RED}$docker_inactive${NC}"
else
echo -e "${ARROW}  ${CYAN}Docker is not installed${NC}"
fi

fi

if [[ "$docker_working" == "1" ]]; then
echo -e "${CHECK_MARK} ${CYAN} Docker is working correct${NC}"
else
echo -e "${X_MARK} ${CYAN} Docker is not working${NC}"
fi

#if systemctl list-units | grep docker.socket | egrep -wi 'running' > /dev/null 2>&1; then
#echo -e "${CHECK_MARK} ${CYAN} Docker Socket for the API running ${SEA}$docker_socket_running${NC}"
#else
#if [[ "$docker_socket_inactive" != "" ]]; then
#echo -e "${X_MARK} ${CYAN}Docker Socket for the API not running ${RED}$docker_socket_inactive ${NC}"
#else
#echo -e "${X_MARK} ${CYAN}Docker Socket for the API is not installed${NC}"
#fi
#fi

if systemctl list-units | grep mongod | egrep -wi 'running' > /dev/null 2>&1; then
echo -e "${CHECK_MARK} ${CYAN} MongoDB service running ${SEA}$mongod_running${NC}"
else

if [[ "$mongod_inactive" != "" ]]; then
echo -e "${X_MARK} ${CYAN} MongoDB service not running ${RED}$mongod_inactive${NC}"
else
echo -e "${X_MARK} ${CYAN} MongoDB service is not installed${NC}"
fi

fi

if systemctl list-units | grep zelcash | egrep -wi 'running' > /dev/null 2>&1; then
echo -e "${CHECK_MARK} ${CYAN} Zelcash service running ${SEA}$zelcash_running${NC}"
else
if [[ "$zelcash_inactive" != "" ]]; then
echo -e "${X_MARK} ${CYAN} Zelcash service not running ${RED}$zelcash_inactive${NC}"
else
echo -e "${X_MARK} ${CYAN} Zelcash service is not installed${NC}"
fi
fi
echo -e ""

echo -e "${BOOK} ${YELLOW}Checking ZelFlux:${NC}"

if pm2 -v > /dev/null 2>&1; then
pm2_zelflux_status=$(pm2 info zelflux 2> /dev/null | grep 'status' | sed -r 's/│//gi' | sed 's/status.//g' | xargs)
if [[ "$pm2_zelflux_status" == "online" ]]; then
pm2_zelflux_uptime=$(pm2 info zelflux | grep 'uptime' | sed -r 's/│//gi' | sed 's/uptime//g' | xargs)
pm2_zelflux_restarts=$(pm2 info zelflux | grep 'restarts' | sed -r 's/│//gi' | xargs)
echo -e "${CHECK_MARK} ${CYAN} Pm2 Zelflux info => status: ${GREEN}$pm2_zelflux_status${CYAN}, uptime: ${GREEN}$pm2_zelflux_uptime${NC} ${SEA}$pm2_zelflux_restarts${NC}" 
else
if [[ "$pm2_zelflux_status" != "" ]]; then
echo -e "${X_MARK} ${CYAN} Pm2 Zelflux status: ${RED}$pm2_zelflux_status ${NC}" 
fi
fi
else
echo -e "${X_MARK} ${CYAN} Pm2 is not installed${NC}"
if tmux ls | grep created &> /dev/null; then
echo -e "${CHECK_MARK} ${CYAN} Tmux session exists${NC}"
else
echo -e "${X_MARK} ${CYAN} Tmux session does not exists${NC}"
fi
fi

if [[ $(curl -s --head "$WANIP:16126" | head -n 1 | grep "200 OK") ]]
then
echo -e "${CHECK_MARK} ${CYAN} ZelFront is working${NC}"
else
echo -e "${X_MARK} ${CYAN} ZelFront is not working${NC}"
fi

if [ -d ~/zelflux ]
then
FILE=~/zelflux/config/userconfig.js
if [ -f "$FILE" ]
then

 current_ver=$(jq -r '.version' /home/$USER/zelflux/package.json)
 required_ver=$(curl -sS https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')

if [[ "$required_ver" != "" ]]; then
   if [ "$(printf '%s\n' "$required_ver" "$current_ver" | sort -V | head -n1)" = "$required_ver" ]; then 
      echo -e "${CHECK_MARK} ${CYAN} You have the current version of Zelflux ${GREEN}(v$required_ver)${NC}"     
   else
      echo -e "${HOT} ${CYAN}New version of Zelflux available ${SEA}$required_ver${NC}"
      FLUX_UPDATE="1"
   fi
 fi

echo -e "${CHECK_MARK} ${CYAN} Zelflux config  ~/zelflux/config/userconfig.js exists${NC}"

ZELIDLG=`echo -n $(grep -w zelid ~/zelflux/config/userconfig.js | sed -e 's/.*zelid: .//') | wc -m`
if [ "$ZELIDLG" -eq "36" ] || [ "$ZELIDLG" -eq "35" ]
then
echo -e "${CHECK_MARK} ${CYAN} Zel ID is valid${NC}"
else
echo -e "${X_MARK} ${CYAN} Zel ID is not valid${NC}"
fi

if [ -f ~/zelflux/error.log ]
then
echo
echo -e "${BOOK} ${YELLOW}Zelflux error.log file detected, check ~/zelflux/error.log"
echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(wc -l  < /home/$USER/zelflux/error.log)${CYAN} error events${NC}"
error_line=$(cat /home/$USER/zelflux/error.log | grep 'Error' | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{3\}Z//' | xargs)
echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
event_date=$(cat /home/$USER/zelflux/error.log | grep 'Error' | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{3\}Z')
event_time_uxtime=$(date -d "$event_date" +"%s")
event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
now_date=$(date +%s)
tdiff=$((now_date-event_time_uxtime))
show_time "$tdiff"
fi

if [ ! -f ~/zelflux/ZelFront/dist/index.html ]
then
echo -e "${WORNING} ${CYAN}Zelflux problem detected, missing ~/zelflux/ZelFront/dist/index.html"
fi

else
FLUXCONF="1"
    echo -e "${X_MARK} ${CYAN} Zelflux config ~/zelflux/config/userconfig.js does not exists${NC}"
fi

else
    echo -e "${X_MARK} ${CYAN} Directory ~/zelflux does not exists${CYAN}"
fi

if [[ "$ZELCONF" == "1" ]]
then
echo 
echo -e "${BOOK} ${YELLOW}Checking ~/.zelcash/zelcash.conf${NC}"
if [[ $zelnodeprivkey == $(grep -w zelnodeprivkey ~/.zelcash/zelcash.conf | sed -e 's/zelnodeprivkey=//') ]]
then
echo -e "${CHECK_MARK} ${CYAN} Zelnodeprivkey matches${NC}"
else
REPLACE="1"
echo -e "${X_MARK} ${CYAN} Zelnodeprivkey does not match${NC}"
fi

if [[ $zelnodeoutpoint == $(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf | sed -e 's/zelnodeoutpoint=//') ]]
then
echo -e "${CHECK_MARK} ${CYAN} Zelnodeoutpoint matches${NC}"
else
REPLACE="1"
echo -e "${X_MARK} ${CYAN} Zelnodeoutpoint does not match${NC}"
fi

if [[ $zelnodeindex == $(grep -w zelnodeindex ~/.zelcash/zelcash.conf | sed -e 's/zelnodeindex=//') ]]
then
echo -e "${CHECK_MARK} ${CYAN} Zelnodeindex matches${NC}"
else
REPLACE="1"
echo -e "${X_MARK} ${CYAN} Zelnodeindex does not match${NC}"
fi

fi

if [[ -f /home/$USER/watchdog/package.json ]]; then
echo
echo -e "${BOOK} ${YELLOW}Checking Watchdog:${NC}"

current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
required_ver=$(curl -sS https://raw.githubusercontent.com/XK4MiLX/watchdog/master/package.json | jq -r '.version')

  if [[ "$required_ver" != "" ]]; then
     if [ "$(printf '%s\n' "$required_ver" "$current_ver" | sort -V | head -n1)" = "$required_ver" ]; then 
        echo -e "${CHECK_MARK} ${CYAN} You have the current version of Watchdog ${GREEN}(v$required_ver)${NC}"     
     else
        echo -e "${HOT} ${CYAN}New version of Watchdog available ${SEA}$required_ver${NC}"
     fi
  fi

fi


if [[ -f /home/$USER/watchdog/watchdog_error.log ]]; then
echo
echo -e "${BOOK} ${YELLOW}Watchdog watchdog_error.log file detected, check ~/watchdog/watchdog_error.log"
echo -e "${YELLOW}${WORNING} ${CYAN}Found: ${RED}$(wc -l  < /home/$USER/watchdog/watchdog_error.log)${CYAN} error events${NC}"
error_line=$(cat /home/$USER/watchdog/watchdog_error.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
event_date=$(cat /home/$USER/watchdog/watchdog_error.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}' | head -n1)
event_time_uxtime=$(date -ud "$event_date" +"%s")

event_human_time_local=$(date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')
event_human_time_utc=$(TZ=GMT date -d @"$event_time_uxtime" +'%Y-%m-%d %H:%M:%S [%z]')

echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_human_time_local${NC} / ${GREEN}$event_human_time_utc${NC}"
now_date=$(date +%s)
tdiff=$((now_date-event_time_uxtime))
show_time "$tdiff"
fi 
echo -e "${YELLOW}===================================================${NC}"
if [[ "$FLUX_UPDATE" == "1" ]]; then
read -p "Would you like to update Zelflux Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
cd /home/$USER/zelflux && git pull > /dev/null 2>&1 && cd
current_ver=$(jq -r '.version' /home/$USER/zelflux/package.json)
required_ver=$(curl -sS https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')
if [[ "$required_ver" == "$current_ver" ]]; then
echo -e "${CHECK_MARK} ${CYAN}Zelfux updated successfully.${NC}"
echo -e ""
else
echo -e "${X_MARK} ${CYAN}Zelfux was not updated.${NC}"
echo -e ""
fi
fi
fi

if [[ "$REPLACE" == "1" ]]; then
read -p "Would you like to correct zelcash.conf errors Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo -e "${YELLOW}Stopping Zelcash serivce...${NC}"
sudo systemctl stop zelcash
sudo fuser -k 16125/tcp > /dev/null 2>&1
echo -e ""

if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/.zelcash/zelcash.conf) ]]; then
echo -e "\c"
        else
        sed -i "s/$(grep -e zelnodeprivkey ~/.zelcash/zelcash.conf)/zelnodeprivkey=$zelnodeprivkey/" ~/.zelcash/zelcash.conf
                if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/.zelcash/zelcash.conf) ]]; then
                        echo -e " ${CYAN}Zelnodeprivkey replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
                fi
fi
if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf) ]]; then
echo -e "\c"
        else
        sed -i "s/$(grep -e zelnodeoutpoint ~/.zelcash/zelcash.conf)/zelnodeoutpoint=$zelnodeoutpoint/" ~/.zelcash/zelcash.conf
                if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf) ]]; then
                        echo -e " ${CYAN}Zelnodeoutpoint replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
                fi
fi
if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/.zelcash/zelcash.conf) ]]; then
echo -e "\c"
        else
        sed -i "s/$(grep -w zelnodeindex ~/.zelcash/zelcash.conf)/zelnodeindex=$zelnodeindex/" ~/.zelcash/zelcash.conf
                if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/.zelcash/zelcash.conf) ]]; then
                        echo -e " ${CYAN}Zelnodeindex replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
                fi
fi
echo -e ""
sudo systemctl start zelcash
NUM='35'
MSG1=' Restarting zelcash serivce...'
MSG2="${CYAN}............[${CHECK_MARK}${CYAN}]${NC}"
spinning_timer
echo -e ""
fi
fi

if [ "$LC_CHECK" == "1" ]; then
read -p "Would you like to change LC_NUMERIC to en_US.UTF-8 Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
sudo bash -c 'echo "LC_NUMERIC="en_US.UTF-8"" >>/etc/default/locale'
echo -e ""
echo -e "${CHECK_MARK} ${CYAN}LC_NUMERIC changed to en_US.UTF-8 now you need restart pc${NC}"
read -p "Would you like to reboot pc Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
sudo reboot -n
fi
fi
fi
