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
SCVESION=v3.5

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
X_MARK="${RED}\xE2\x9D\x8C${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"

#dialog color
export NEWT_COLORS='
title=black,
'

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
    echo -e "${RED}$day"d "$hour"h "$min"m "$sec"s"${NC}"
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

function update_zelcash(){
COIN_NAME='zelcash'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'

# add to path
PATH=$PATH:"$COIN_PATH"
export PATH

echo -e "${YELLOW}Closing zelcash daemon and purge apt package${NC}"
#Closing zelcash daemon and purge apt package
"$COIN_CLI" stop >/dev/null 2>&1 && sleep 2
sudo systemctl stop "$COIN_NAME" && sleep 1
sudo killall "$COIN_DAEMON" >/dev/null 2>&1
sudo rm "$COIN_PATH/$COIN_NAME"* >/dev/null 2>&1 && sleep 1
sudo apt-get purge "$COIN_NAME" -y >/dev/null 2>&1 && sleep 1
sudo killall -s SIGKILL zelbenchd >/dev/null 2>&1 && sleep 1
sudo fuser -k 16125/tcp > /dev/null 2>&1
sudo rm /etc/apt/sources.list.d/zelcash.list >/dev/null 2>&1 && sleep 1

echo -e "${YELLOW}Install zelcash apt package${NC}"
echo 'deb https://apt.zel.cash/ all main' | sudo tee /etc/apt/sources.list.d/zelcash.list
gpg --keyserver keyserver.ubuntu.com --recv 4B69CA27A986265D
gpg --export 4B69CA27A986265D | sudo apt-key add -
sudo apt-get update
sudo apt-get install "$COIN_NAME" -y
sudo chmod 755 "$COIN_PATH/$COIN_NAME"* && sleep 2
if ! gpg --list-keys Zel >/dev/null; then
  gpg --keyserver na.pool.sks-keyservers.net --recv 4B69CA27A986265D
  gpg --export 4B69CA27A986265D | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install "$COIN_NAME" -y
  sudo chmod 755 "$COIN_PATH/$COIN_NAME"* && sleep 2
  if ! gpg --list-keys Zel >/dev/null; then
    gpg --keyserver eu.pool.sks-keyservers.net --recv 4B69CA27A986265D
    gpg --export 4B69CA27A986265D | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install "$COIN_NAME" -y
    sudo chmod 755 "$COIN_PATH/$COIN_NAME"* && sleep 2
    if ! gpg --list-keys Zel >/dev/null; then
      gpg --keyserver pgpkeys.urown.net --recv 4B69CA27A986265D
      gpg --export 4B69CA27A986265D | sudo apt-key add -
      sudo apt-get update
      sudo apt-get install "$COIN_NAME" -y
      sudo chmod 755 "$COIN_PATH/$COIN_NAME"* && sleep 2
      if ! gpg --list-keys Zel >/dev/null; then
        gpg --keyserver keys.gnupg.net --recv 4B69CA27A986265D
        gpg --export 4B69CA27A986265D | sudo apt-key add -
        sudo apt-get update
        sudo apt-get install "$COIN_NAME" -y
        sudo chmod 755 "$COIN_PATH/$COIN_NAME"* && sleep 2
      fi
    fi
  fi
fi

echo -e "${YELLOW}Restarting service${NC}"
"$COIN_DAEMON"

}

function check_listen_ports(){

if sudo lsof -i  -n | grep LISTEN | grep 27017 | grep mongod > /dev/null 2>&1
then
echo -e "${CHECK_MARK} ${CYAN}Mongod listen on port 27017${NC}"
else
echo -e "${X_MARK} ${CYAN}Mongod not listen${NC}"
fi

if sudo lsof -i  -n | grep LISTEN | grep 16125 | grep zelcashd > /dev/null 2>&1
then
echo -e "${CHECK_MARK} ${CYAN}Zelcash listen on port 16125${NC}"
else
echo -e "${X_MARK} ${CYAN}Zelcash not listen${NC}"
fi

if sudo lsof -i  -n | grep LISTEN | grep 16125 | grep zelbenchd > /dev/null 2>&1
then
echo -e "${CHECK_MARK} ${CYAN}Zelbench listen on port 16125${NC}"
else
echo -e "${X_MARK} ${CYAN}Zelbench not listen${NC}"
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
echo -e "${CHECK_MARK} ${CYAN}Zelflux listen on ports 16126/16127${NC}"
else
echo -e "${X_MARK} ${CYAN}Zelflux not listen${NC}"
fi

}

function integration(){

PATH_TO_FOLDER=( /usr/local/bin/ ) 
FILE_ARRAY=( 'zelbench-cli' 'zelbenchd' 'zelcash-cli' 'zelcashd' 'zelcash-fetch-params.sh' 'zelcash-tx' )
ELEMENTS=${#FILE_ARRAY[@]}
NOT_FOUND="0"

for (( i=0;i<$ELEMENTS;i++)); do
 
        if [ -f $PATH_TO_FOLDER${FILE_ARRAY[${i}]} ]; then
            echo -e "${CHECK_MARK} ${CYAN}${FILE_ARRAY[${i}]}"
        else
            echo -e "${X_MARK} ${CYAN}${FILE_ARRAY[${i}]}"
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
echo -e "${YELLOW}Checking zelbenchmark debug.log${NC}"
if [ -f /home/$USER/.zelbenchmark/debug.log ]; then
if [[ $(egrep -ac -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log) != "0" ]]; then
echo -e "${CYAN}Found: ${RED}$(egrep -ac -wi --color 'error|failed' /home/$USER/.zelbenchmark/debug.log)${CYAN} error events${NC}"
#egrep -wi --color 'warning|error|critical|failed' ~/.zelbenchmark/debug.log
error_line=$(egrep -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
event_date=$(egrep -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}')
data_now_format=$(date +%F_%H-%M-%S)
echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_date ago.${NC}"
event_time=$(date --date "$event_date" +%s)
now_date=$(date +%s)
tdiff=$((now_date-event_time))
show_time "$tdiff"
echo -e "${PIN} ${CYAN}Creating zelbenchmark_debug_error.log${NC}"
egrep -wi --color 'warning|error|critical|failed' /home/$USER/.zelbenchmark/debug.log > /home/$USER/zelbenchmark_debug_error.log
echo
fi
echo
else
echo -e "${RED}Debug file not exists${NC}"
echo
fi
echo -e "${YELLOW}Checking zelcash debug.log${NC}"
if [ -f /home/$USER/.zelcash/debug.log ]; then
if [[ $(egrep -ac -wi --color 'error|failed' /home/$USER/.zelcash/debug.log) != "0" ]]; then
echo -e "${CYAN}Found: ${RED}$(egrep -ac -wi --color 'error|failed' /home/$USER/.zelcash/debug.log)${CYAN} error events, ${RED}$(egrep -ac -wi --color 'benchmarking' /home/$USER/.zelcash/debug.log) ${CYAN}related to Benchmark${NC}"
echo -e "${BOOK} ${CYAN}ZelBench errors info:${NC}"
error_line=$(egrep -wi --color 'ZelBenchd isn' /home/$USER/.zelcash/debug.log | tail -1 | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.//')
event_date=$(egrep -wi --color 'ZelBenchd isn' /home/$USER/.zelcash/debug.log | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}')
data_now_format=$(date +%F_%H-%M-%S)
echo -e "${PIN} ${CYAN}Last error line: $error_line${NC}"
echo -e "${PIN} ${CYAN}Last error time: ${SEA}$event_date$ ago.${NC}"
event_time=$(date --date "$event_date" +%s)
now_date=$(date +%s)
tdiff=$((now_date-event_time))
show_time "$tdiff"
##echo -e "${CYAN}Benchmark errors:${NC}"
##egrep -wi --color 'benchmarking' /home/$USER/.zelcash/debug.log
fi
echo -e "${PIN} ${CYAN}Creating zelcash_debug_error.log${NC}"
egrep -wi --color 'error|failed' /home/$USER/.zelcash/debug.log > /home/$USER/zelcash_debug_error.log
echo
else
echo -e "${RED}Debug file not exists${NC}"
echo
fi

echo -e "${NC}"
echo -e "${YELLOW}Checking benchmark status...${NC}"
zelbench-cli getstatus
echo -e "${NC}"
echo -e "${YELLOW}Checking benchmarks details...${NC}"
zelbench-cli getbenchmarks
echo -e "${NC}"
echo -e "${YELLOW}Checking zelcash information...${NC}"
zelcash-cli getinfo
echo -e "${NC}"
echo -e "${YELLOW}Checking node status...${NC}"
zelcash-cli getzelnodestatus
echo -e "${NC}"
echo -e "${YELLOW}Checking listen ports...${NC}"
check_listen_ports
echo -e "${NC}"
echo -e "${YELLOW}File integration checking...${NC}"
integration
echo -e ""

WANIP=$(wget http://ipecho.net/plain -O - -q)
if ! whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60; then
   WANIP=$(whiptail  --title "ZelNode ANALIZER/FiXER $SCVESION" --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
fi
if whiptail --yesno "Would you like to verify zelcash.conf Y/N?" 8 60; then
ZELCONF="1"
zelnodeprivkey="$(whiptail --title "ZelNode ANALYZER/FiXER $SCVESION" --inputbox "Enter your zelnode Private Key generated by your Zelcore/Zelmate wallet" 8 72 3>&1 1>&2 2>&3)"
zelnodeoutpoint="$(whiptail --title "ZelNode ANALYZER/FiXER $SCVESION" --inputbox "Enter your zelnode Output TX ID" 8 72 3>&1 1>&2 2>&3)"
zelnodeindex="$(whiptail --title "ZelNode ANALYZER/FiXER $SCVESION" --inputbox "Enter your zelnode Output Index" 8 60 3>&1 1>&2 2>&3)"
fi


echo -e "${YELLOW}=====================================================${NC}"
echo -e "${GREEN}SUMMARY REPORT${NC}"
echo -e "${YELLOW}=====================================================${NC}"


if [[ "$ZELCONF" == "1" ]]
then

if [[ $zelnodeprivkey == $(grep -w zelnodeprivkey ~/.zelcash/zelcash.conf | sed -e 's/zelnodeprivkey=//') ]]
then
echo -e "${CHECK_MARK} ${CYAN}Zelnodeprivkey matches${NC}"
else
REPLACE="1"
echo -e "${X_MARK} ${CYAN}Zelnodeprivkey does not match${NC}"
fi

if [[ $zelnodeoutpoint == $(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf | sed -e 's/zelnodeoutpoint=//') ]]
then
echo -e "${CHECK_MARK} ${CYAN}Zelnodeoutpoint matches${NC}"
else
REPLACE="1"
echo -e "${X_MARK} ${CYAN}Zelnodeoutpoint does not match${NC}"
fi

if [[ $zelnodeindex == $(grep -w zelnodeindex ~/.zelcash/zelcash.conf | sed -e 's/zelnodeindex=//') ]]
then
echo -e "${CHECK_MARK} ${CYAN}Zelnodeindex matches${NC}"
else
REPLACE="1"
echo -e "${X_MARK} ${CYAN}Zelnodeindex does not match${NC}"
fi

fi


if ls -la ~/.zelcash | grep root > /dev/null; then
echo -e "${X_MARK} ${CYAN}Zelcash directory root ownership detected${NC}"
OWNER="1"
else
echo -e "${CHECK_MARK} ${CYAN}Zelcash directory ownership correct${NC}"
fi

if [[ "$NOT_FOUND" == "0" ]]
then
echo -e "${CHECK_MARK} ${CYAN}Files integration [OK]${NC}"
else
echo -e "${X_MARK} ${CYAN}Checking integration failed missing files${NC}"
fi


if pgrep zelcashd > /dev/null; then
    	echo -e "${CHECK_MARK} ${CYAN}Zelcash daemon is installed and running${NC}"
else
    	echo -e "${X_MARK} ${CYAN}Zelcash daemon is not running${NC}"
fi

if pgrep mongod > /dev/null; then
  echo -e "${CHECK_MARK} ${CYAN}Mongodb is installed and running${NC}"
else

if mongod --version > /dev/null 
then
echo -e "${X_MARK} ${CYAN}Mongodb is not running${NC}"
else
echo -e "${X_MARK} ${CYAN}Mongodb not installed${NC}"
fi  

fi

if node -v > /dev/null 2>&1; then
    	echo -e "${CHECK_MARK} ${CYAN}Nodejs is installed${NC}"
else
    	echo -e "${X_MARK} ${CYAN}Nodejs did not install${NC}"
fi

if sudo docker run hello-world > /dev/null 2>&1
then
echo -e "${CHECK_MARK} ${CYAN}Docker is installed${NC}"
else
echo -e "${X_MARK} ${CYAN}Docker did not installed${NC}"
fi

if [[ $(groups | grep docker) && $(groups | grep "$USER")  ]] 
then
echo -e "${CHECK_MARK} ${CYAN}User $USER is member of 'docker'${NC}"
else
echo -e "${X_MARK} ${CYAN}User $USER is not member of 'docker'${NC}"
fi

b_status=$(zelbench-cli getstatus | jq '.benchmarking')
zelback=$(zelbench-cli getstatus | jq '.zelback')

good_zelback='"connected"'
good_benchamrk1='"BASIC"'
good_benchamrk2='"SUPER"'
good_benchamrk3='"BAMF"'
failed_benchamrk='"failed"'

if [[ "$b_status"  == "$good_benchamrk1" || "$b_status"  == "$good_benchamrk2" || "$b_status"  == "$good_benchamrk3" ]]
then
echo -e "${CHECK_MARK} ${CYAN}Benchmark [OK]($b_status)${NC}"
else
BTEST="1"
echo -e "${X_MARK} ${CYAN}Benchmark [Failed]${NC}"

bench_status=$(zelbench-cli getbenchmarks | jq '.status')
if [[ "$bench_status" == "$failed_benchamrk" ]] 
then
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

check_benchmarks "eps" "89.99" "CPU speed" "< 90.00 events per second"
check_benchmarks "ddwrite" "159.99" "Disk write speed" "< 160.00 events per second"

fi

if [ "$good_zelback" == "$zelback" ]
then
echo -e "${CHECK_MARK} ${CYAN}ZelBack is working${NC}"
else
echo -e "${X_MARK} ${CYAN}ZelBack is not working${NC}"
fi

if [[ $(curl -s --head "$WANIP:16126" | head -n 1 | grep "200 OK") ]]
then
echo -e "${CHECK_MARK} ${CYAN}ZelFront is working${NC}"
else
echo -e "${X_MARK} ${CYAN}ZelFront is not working${NC}"
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
      echo -e "${CHECK_MARK} ${CYAN}You have the current version of Zelflux ${GREEN}(v$required_ver)${NC}"     
   else
      echo -e "${X_MARK} ${CYAN}New version of Zelflux available${NC}"
      FLUX_UPDATE="1"
   fi
 fi

echo -e "${CHECK_MARK} ${CYAN}Zelflux config  ~/zelflux/config/userconfig.js exists${NC}"

ZELIDLG=`echo -n $(grep -w zelid ~/zelflux/config/userconfig.js | sed -e 's/.*zelid: .//') | wc -m`
if [ "$ZELIDLG" -eq "36" ] || [ "$ZELIDLG" -eq "35" ]
then
echo -e "${CHECK_MARK} ${CYAN}Zel ID is valid${NC}"
else
echo -e "${X_MARK} ${CYAN}Zel ID is not valid${NC}"
fi

else
FLUXCONF="1"
    echo -e "${X_MARK} ${CYAN}Zelflux config ~/zelflux/config/userconfig.js does not exists${NC}"
fi

else
    echo -e "${X_MARK} ${CYAN}Directory ~/zelflux does not exists${CYAN}"
fi

if pm2 -v > /dev/null 2>&1
 then
 echo -e "${CHECK_MARK} ${CYAN}Pm2 is installed${NC}"
 
if [ -f /home/$USER/zelflux/start.sh ]; then
echo -e "${CHECK_MARK} ${CYAN}ZelFlux start script /home/$USER/zelflux/start.sh exists${NC}"
else
echo -e "${X_MARK} ${CYAN}ZelFlux start script /home/$USER/zelflux/start.sh does not exists${NC}"
FLUXRESTART="1"
fi
 
 else
 echo -e "${X_MARK} ${CYAN}Pm2 is not installed${NC}"
   if tmux ls | grep created &> /dev/null; then
     echo -e "${CHECK_MARK} ${CYAN}Tmux session exists${NC}"
    else
     echo -e "${X_MARK} ${CYAN}Tmux session does not exists${NC}"
   fi
fi

if [ "$ZELCONF" == "1" ]; then

url_to_check="https://explorer.zel.cash/api/tx/$zelnodeoutpoint"
conf=$(wget -nv -qO - $url_to_check | jq '.confirmations')

if [[ $conf == ?(-)+([0-9]) ]]; then
if [ "$conf" -ge "100" ]; then
echo -e "${CHECK_MARK} ${CYAN}Confirmations numbers >= 100($conf)${NC}"
else
echo -e "${X_MARK} ${CYAN}Confirmations numbers < 100($conf)${NC}"
fi
else
echo -e "${X_MARK} ${CYAN}Zelnodeoutpoint is not valid or explorer.zel.cash is unavailable${NC}"
fi

fi
 

if [[ $(ping -c1 $(hostname | grep .) | sed -nE 's/^PING[^(]+\(([^)]+)\).*/\1/p') =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${CHECK_MARK} ${CYAN}IP detected successful ${NC}"
else
        echo -e "${X_MARK} ${CYAN}IP was not detected try edit /etc/hosts and add there 'your_external_ip hostname' your hostname is $(hostname) ${RED}(only if zelback status is disconnected)${CYAN}"
fi
echo -e "${YELLOW}=====================================================${NC}"

if [ "$OWNER" = "1" ]; then
read -p "Would you like to fix ownership Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo -e "${YELLOW}Stoping Zelcash serivce...${NC}"
sudo systemctl stop zelcash && sleep 2
sudo killall -s SIGKILL zelcashd > /dev/null 2>&1
sudo fuser -k 16125/tcp > /dev/null 2>&1
echo -e "${YELLOW}Changing ownerhip${NC}" && sleep 1
sudo chown -R $USER:$USER ~/.zelcash
echo -e "${YELLOW}Updating zelflux scripts...${NC}" && sleep 1
cd zelflux && git pull
echo -e "${YELLOW}Starting Zelcash serivce...${NC}" && sleep 2
sudo systemctl start zelcash
fi
fi

if [[ "$FLUX_UPDATE" == "1" ]]; then
read -p "Would you like to update Zelflux Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
cd /home/$USER/zelflux && git pull && cd
echo -e "${CHECK_MARK} {GREEN}Zelfux updated...${NC}"
echo -e ""
fi
fi


if [ ! -d ~/zelflux ]; then
read -p "Would you like to clone zelflux from github Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo -e "${YELLOW}ZelFlux downloading...${NC}"
git clone https://github.com/zelcash/zelflux.git
if [ -d ~/zelflux ]; then
echo -e "${CHECK_MARK} ${GREEN}Zelfux was downloaded successfully${NC}"
FLUXCONF="1"
else
 echo -e "${X_MARK} {RED}Zelfux download failed${NC}"
fi
fi
fi
if [ "$FLUXCONF" == "1" ]; then
read -p "Would you like to create zelflux userconfig.js Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
while true
do
zel_id="$(whiptail --title "ZelNode ANALYZER/FiXER $SCVESION" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
if [ $(printf "%s" "$zel_id" | wc -c) -eq "34" ] || [ $(printf "%s" "$zel_id" | wc -c) -eq "33" ]; then
echo -e "${CHECK_MARK} ${GREEN}Zel ID is valid${NC}"
break
else
echo -e "${X_MARK} ${RED}Zel ID is not valid try again...${NC}"
sleep 4
fi
done

touch ~/zelflux/config/userconfig.js
    cat << EOF > ~/zelflux/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '$WANIP',
        zelid: '$zel_id',
        testnet: false
      }
    }
EOF
FILE1=~/zelflux/config/userconfig.js
if [ -f "$FILE1" ]; then
    echo -e "${CHECK_MARK} ${GREEN}File ~/zelflux/config/userconfig.js created successful${NC}${NC}"
else
    echo -e "${X_MARK} ${RED}File ~/zelflux/config/userconfig.js file create failed${NC}"
fi
fi
fi

#sudo env PATH=$PATH:/home/$USER/.nvm/versions/node/v12.16.1/bin pm2 startup systemd -u $USER --hp /home/$USER
FILE2="/home/$USER/update-zelflux.sh"
if [ -f "$FILE2" ]; then
echo -e "\c"
else
read -p "Would you like to add auto-update zelflux via crontab Y/N" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo "cd /home/$USER/zelflux" >> "/home/$USER/update-zelflux.sh"
echo "git pull" >> "/home/$USER/update-zelflux.sh"
chmod +x "/home/$USER/update-zelflux.sh"
(crontab -l -u "$USER" 2>/dev/null; echo "0 0 * * 0 /home/$USER/update-zelflux.sh") | crontab -

if [[ $(crontab -l | grep -i update-zelflux) ]]; then
echo -e "${CHECK_MARK} ${GREEN}Zelflux auto-update was installed successfully${NC}"
else
echo -e "${X_MARK} ${RED}Zelflux auto-update installation has failed${NC}"
fi
fi
fi

if [ "$NOT_FOUND" == "1" ]; then
read -p "Would you like to correct missing files errors Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo -e "${YELLOW}Installing...${NC}"
sudo apt-get update && sleep 1
sudo apt install zelbench -y && sleep 1
sudo apt install zelcash -y && sleep 1
echo -e "${YELLOW}Restarting service...${NC}"
sudo systemctl stop zelcash && sleep 1
sudo fuser -k 16125/tcp > /dev/null 2>&1
sudo systemctl start zelcash && sleep 1
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
                        echo -e "${CHECK_MARK} ${GREEN}Zelnodeprivkey replaced successful${NC}"
                fi
fi
if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf) ]]; then
echo -e "\c"
        else
        sed -i "s/$(grep -e zelnodeoutpoint ~/.zelcash/zelcash.conf)/zelnodeoutpoint=$zelnodeoutpoint/" ~/.zelcash/zelcash.conf
                if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf) ]]; then
                        echo -e "${CHECK_MARK} ${GREEN}Zelnodeoutpoint replaced successful${NC}"
                fi
fi
if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/.zelcash/zelcash.conf) ]]; then
echo -e ""
        else
        sed -i "s/$(grep -w zelnodeindex ~/.zelcash/zelcash.conf)/zelnodeindex=$zelnodeindex/" ~/.zelcash/zelcash.conf
                if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/.zelcash/zelcash.conf) ]]; then
                        echo -e "${CHECK_MARK} ${GREEN}Zelnodeindex replaced successful${NC}"
                fi
fi
echo -e ""
sudo systemctl start zelcash
NUM='35'
MSG1='Restarting zelcash serivce...'
MSG2="${CHECK_MARK}"
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
if [ "$BTEST" == "1" ]; then
read -p "Would you like to restart node benchmarks Y/N?" -n 1 -r
echo -e ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
zelbench-cli restartnodebenchmarks
NUM='45'
MSG1='Restarting benchmark...'
MSG2="${CHECK_MARK}"
echo && spinning_timer
echo -e ""
zelbench-cli getbenchmarks
fi
fi
