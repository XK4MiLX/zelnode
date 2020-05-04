#!/bin/bash

###############################################################################################################################################################################################################
# IF PLANNING TO RUN ZELNODE FROM HOME/OFFICE/PERSONAL EQUIPMENT & NETWORK!!!
# You must understand the implications of running a ZelNode on your on equipment and network. There are many possible security issues. DYOR!!!
# Running a ZelNode from home should only be done by those with experience/knowledge of how to set up the proper security.
# It is recommended for most operators to use a VPS to run a ZelNode
#
# **Potential Issues (not an exhaustive list):**
# 1. Your home network IP address will be displayed to the world. Without proper network security in place, a malicious person sniff around your IP for vulnerabilities to access your network.
# 2. Port forwarding: The p2p port for ZelCash will need to be open.
# 3. DDOS: VPS providers typically provide mitigation tools to resist a DDOS attack, while home networks typically don't have these tools.
# 4. Zelcash daemon is ran with sudo permissions, meaning the daemon has elevated access to your system. **Do not run a ZelNode on equipment that also has a funded wallet loaded.**
# 5. Static vs. Dynamic IPs: If you have a revolving IP, every time the IP address changes, the ZelNode will fail and need to be stood back up.
# 6. Home connections typically have a monthly data cap. ZelNodes will use 2.5 - 6 TB monthly usage depending on ZelNode tier, which can result in overage charges. Check your ISP agreement.
# 7. Many home connections provide adequate download speeds but very low upload speeds. ZelNodes require 100mbps (12.5MB/s) download **AND** upload speeds. Ensure your ISP plan can provide this continually.
# 8. ZelNodes can saturate your network at times. If you are sharing the connection with other devices at home, its possible to fail a benchmark if network is saturated.
###############################################################################################################################################################################################################

###### you must be logged in as a sudo user, not root #######

COIN_NAME='zelcash'
#wallet information
UPDATE_FILE='update.sh'
BOOTSTRAP_ZIP='http://77.55.218.93/zel-bootstrap.zip'
#BOOTSTRAP_ZIP='https://www.dropbox.com/s/kyqe8ji3g1yetfx/zel-bootstrap.zip'
BOOTSTRAP_ZIPFILE='zel-bootstrap.zip'
CONFIG_DIR='.zelcash'
CONFIG_FILE='zelcash.conf'
RPCPORT='16124'
PORT='16125'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
USERNAME="$(whoami)"
IMPORT_ZELCONF="0"
IMPORT_ZELID="0"
CORRUPTED="0"
BOOTSTRAP_SKIP="0"
WATCHDOG_INSTALL="0"

#Zelflux ports
ZELFRONTPORT=16126
LOCPORT=16127
ZELNODEPORT=16128
MDBPORT=27017

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

function string_limit_x_mark() {
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
echo -e "${ARROW} ${CYAN}$string[${X_MARK}${CYAN}]${NC}"
}


function integration_check() {
FILE_ARRAY=( 'zelbench-cli' 'zelbenchd' 'zelcash-cli' 'zelcashd' 'zelcash-fetch-params.sh' 'zelcash-tx' )
ELEMENTS=${#FILE_ARRAY[@]}

for (( i=0;i<$ELEMENTS;i++)); do

string="${FILE_ARRAY[${i}]}................................."
string=${string::40}

if [ -f "$COIN_PATH/${FILE_ARRAY[${i}]}" ]; then
  echo -e "${ARROW}${CYAN} $string[${CHECK_MARK}${CYAN}]${NC}"
else
  echo -e "${ARROW}${CYAN} $string[${X_MARK}${CYAN}]${NC}"
  CORRUPTED="1"
fi

done

if [[ "$CORRUPTED" == "1" ]]; then
  echo -e "${WORNING}${CYAN}Zelcash package corrupted..."
  echo -e "${WORNING}${CYAN}Will exit out so try and run the script again..."
  echo
  exit
fi	
echo -e ""
}


function config_file() {

if [[ -f /home/$USER/install_conf.json ]]; then
import_settings=$(cat /home/$USER/install_conf.json | jq -r '.import_settings')
ssh_port=$(cat /home/$USER/install_conf.json | jq -r '.ssh_port')
firewall_disable=$(cat /home/$USER/install_conf.json | jq -r '.firewall_disable')
bootstrap_url=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_url')
bootstrap_zip_del=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_zip_del')
swapon=$(cat /home/$USER/install_conf.json | jq -r '.swapon')
mongo_bootstrap=$(cat /home/$USER/install_conf.json | jq -r '.mongo_bootstrap')
watchdog=$(cat /home/$USER/install_conf.json | jq -r '.watchdog')
use_old_chain=$(cat /home/$USER/install_conf.json | jq -r '.use_old_chain')
prvkey=$(cat /home/$USER/install_conf.json | jq -r '.prvkey')
outpoint=$(cat /home/$USER/install_conf.json | jq -r '.outpoint')
index=$(cat /home/$USER/install_conf.json | jq -r '.index')
ZELID=$(cat /home/$USER/install_conf.json | jq -r '.zelid')

echo
echo -e "${ARROW} ${YELLOW}Install config:"

if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]];then
echo -e "${PIN}${CYAN}Import settings from install_conf.json...........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else

if [[ "$import_settings" == "1" ]]; then
echo -e "${PIN}${CYAN}Import settings from zelcash.conf and userconfig.js..............[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

fi

if [[ "$ssh_port" != "" ]]; then
echo -e "${PIN}${CYAN}SSH port set.....................................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

if [[ "$firewall_disable" == "1" ]]; then
echo -e "${PIN}${CYAN}Firewall disabled diuring installation...........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else
echo -e "${PIN}${CYAN}Firewall enabled diuring installation............................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

if [[ "$use_old_chain" == "1" ]]; then
echo -e "${PIN}${CYAN}Diuring re-installation old chain will be use....................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1

else

if [[ "$bootstrap_url" == "" ]]; then
echo -e "${PIN}${CYAN}Use Zelcash Bootstrap from source build in scripts...............[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else
echo -e "${PIN}${CYAN}Use Zelcash Bootstrap from own source............................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

if [[ "$bootstrap_zip_del" == "1" ]]; then
echo -e "${PIN}${CYAN}Remove Zelcash Bootstrap archive file............................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else
echo -e "${PIN}${CYAN}Leave Zelcash Bootstrap archive file.............................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

fi

if [[ "$swapon" == "1" ]]; then
echo -e "${PIN}${CYAN}Create a file that will be used for swap.........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

if [[ "$mongo_bootstrap" == "1" ]]; then
echo -e "${PIN}${CYAN}Use Bootstrap for MongoDB........................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

if [[ "$watchdog" == "1" ]]; then
echo -e "${PIN}${CYAN}Install watchdog.................................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi



fi
}

function round() {
  printf "%.${2}f" "${1}"
}

function import_date() {

if [[ -f ~/.zelcash/zelcash.conf ]]; then

if [[ -z "$import_settings" ]]; then

if whiptail --yesno "Would you like to import data from zelcash.conf and userconfig.js Y/N?" 8 60; then
IMPORT_ZELCONF="1"
echo
echo -e "${ARROW} ${YELLOW}Imported settings:${NC}"
zelnodeprivkey=$(grep -w zelnodeprivkey ~/.zelcash/zelcash.conf | sed -e 's/zelnodeprivkey=//')
echo -e "${PIN}${CYAN}Private Key = ${GREEN}$zelnodeprivkey${NC}" && sleep 1
zelnodeoutpoint=$(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf | sed -e 's/zelnodeoutpoint=//')
echo -e "${PIN}${CYAN}Output TX ID = ${GREEN}$zelnodeoutpoint${NC}" && sleep 1
zelnodeindex=$(grep -w zelnodeindex ~/.zelcash/zelcash.conf | sed -e 's/zelnodeindex=//')
echo -e "${PIN}${CYAN}Output Index = ${GREEN}$zelnodeindex${NC}" && sleep 1

if [[ -f ~/zelflux/config/userconfig.js ]]
then
IMPORT_ZELID="1"
ZELID=$(grep -w zelid ~/zelflux/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
echo -e "${PIN}${CYAN}Zel ID = ${GREEN}$ZELID${NC}" && sleep 1
fi
fi


else 

if [[ "$import_settings" == "1" ]]; then
IMPORT_ZELCONF="1"
echo
echo -e "${ARROW} ${YELLOW}Imported settings:${NC}"
zelnodeprivkey=$(grep -w zelnodeprivkey ~/.zelcash/zelcash.conf | sed -e 's/zelnodeprivkey=//')
echo -e "${PIN}${CYAN}Private Key = ${GREEN}$zelnodeprivkey${NC}" && sleep 1
zelnodeoutpoint=$(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf | sed -e 's/zelnodeoutpoint=//')
echo -e "${PIN}${CYAN}Output TX ID = ${GREEN}$zelnodeoutpoint${NC}" && sleep 1
zelnodeindex=$(grep -w zelnodeindex ~/.zelcash/zelcash.conf | sed -e 's/zelnodeindex=//')
echo -e "${PIN}${CYAN}Output Index = ${GREEN}$zelnodeindex${NC}" && sleep 1

if [[ -f ~/zelflux/config/userconfig.js ]]
then
IMPORT_ZELID="1"
ZELID=$(grep -w zelid ~/zelflux/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
echo -e "${PIN}${CYAN}Zel ID = ${GREEN}$ZELID${NC}" && sleep 1
fi
fi

fi
fi
sleep 1
echo
}

#end of required details
#
#Suppressing password prompts for this user so zelnode can operate

sudo echo -e "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo 
echo -e "${CYAN}APRIL 2020, created by dk808 improved by XK4MiLX from Zel's team and AltTank Army."
echo -e "Special thanks to Goose-Tech, Skyslayer, & Packetflow."
echo -e "Zelnode setup starting, press [CTRL+C] to cancel.${NC}"
sleep 2

if jq --version > /dev/null 2>&1; then
echo -e ""
else
echo -e ""
echo -e "${ARROW} ${YELLOW}Installing JQ....${NC}"
sudo apt  install jq > /dev/null 2>&1

  if jq --version > /dev/null 2>&1
  then
    #echo -e "${ARROW} ${CYAN}Nodejs version: ${GREEN}$(node -v)${CYAN} installed${NC}"
    string_limit_check_mark "JQ $(jq --version) installed................................." "JQ ${GREEN}$(jq --version)${CYAN} installed................................."
    echo
  else
    #echo -e "${ARROW} ${CYAN}Nodejs was not installed${NC}"
    string_limit_x_mark "JQ was not installed................................."
    echo
    exit
  fi
fi

if [ "$USERNAME" = "root" ]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}root${CYAN}, please switch to the username you just created.${NC}"
    sleep 4
    exit
fi

start_dir=$(pwd)
correct_dir="/home/$USER"
echo -e "${ARROW} ${YELLOW}Checking directory....${NC}"
if [[ "$start_dir" == "$correct_dir" ]]
then
echo -e "${ARROW} ${CYAN}Correct directory ${GREEN}$(pwd)${CYAN} ................[${CHECK_MARK}${CYAN}]${NC}"
else
echo -e "${ARROW} ${CYAN}Bad directory switching...${NC}"
cd
echo -e "${ARROW} ${CYAN}Current directory ${GREEN}$(pwd)${CYAN}${NC}"
fi
sleep 1

config_file


if [[ -z "$index" || -z "$outpoint" || -z "$index" ]]; then
import_date
else

if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != ""  && "$ZELID" != ""  ]]; then
echo
IMPORT_ZELCONF="1"
IMPORT_ZELID="1"
echo -e "${ARROW} ${YELLOW}Install conf settings:${NC}"
zelnodeprivkey="$prvkey"
echo -e "${PIN}${CYAN}Private Key = ${GREEN}$zelnodeprivkey${NC}" && sleep 1
zelnodeoutpoint="$outpoint"
echo -e "${PIN}${CYAN}Output TX ID = ${GREEN}$zelnodeoutpoint${NC}" && sleep 1
zelnodeindex="$index"
echo -e "${PIN}${CYAN}Output Index = ${GREEN}$zelnodeindex${NC}" && sleep 1
echo -e "${PIN}${CYAN}Zel ID = ${GREEN}$ZELID${NC}" && sleep 1
echo
fi

fi

#functions
function install_watchdog() {
echo -e "${ARROW} ${YELLOW}Install watchdog for zelnode${NC}"
if pm2 -v > /dev/null 2>&1
then
WATCHDOG_INSTALL="1"
echo -e "${ARROW} ${YELLOW}Downloading...${NC}"
cd && git clone https://github.com/XK4MiLX/watchdog.git > /dev/null 2>&1
echo -e "${ARROW} ${YELLOW}Installing git hooks....${NC}"
wget https://raw.githubusercontent.com/XK4MiLX/zelnode/master/post-merge > /dev/null 2>&1
mv post-merge /home/$USER/watchdog/.git/hooks/post-merge
sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge
echo -e "${ARROW} ${YELLOW}Installing watchdog module....${NC}"
cd watchdog && npm install > /dev/null 2>&1
echo -e "${ARROW} ${YELLOW}Starting watchdog...${NC}"
pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 10 > /dev/null 2>&1 
pm2 save > /dev/null 2>&1
if [[ -f /home/$USER/watchdog/watchdog.js ]]
then
current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
#echo -e "${ARROW} ${CYAN}Watchdog ${GREEN}v$current_ver${CYAN} installed successful.${NC}"
string_limit_check_mark "Watchdog v$current_ver installed................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed................................."
else
#echo -e "${ARROW} ${CYAN}Watchdog installion failed.${NC}"
string_limit_x_mark "Watchdog was not installed................................."
fi
else
#echo -e "${ARROW} ${CYAN}Watchdog installion failed.${NC}"
string_limit_x_mark "Watchdog was not installed................................."
fi

}

function mongodb_bootstrap(){

echo -e "${ARROW} ${YELLOW}Restore mongodb datatable from bootstrap${NC}"
NUM='95'
MSG1='Zelflux loading...'
MSG2="${CYAN}......................[${CHECK_MARK}${CYAN}]${NC}"
spinning_timer
echo && echo
DB_HIGHT=590910
BLOCKHIGHT=$(wget -nv -qO - http://"$WANIP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
#echo -e "${PIN} ${CYAN}IP: ${PINK}$IP"
echo -e "${PIN} ${CYAN}Node block hight: ${GREEN}$BLOCKHIGHT${NC}"
echo -e "${PIN} ${CYAN}Bootstrap block hight: ${GREEN}$DB_HIGHT${NC}"
echo -e ""
if [[ "$BLOCKHIGHT" -gt "0" && "$BLOCKHIGHT" -lt "$DB_HIGHT" ]]
then
echo -e "${ARROW} ${YELLOW}Downloading db for mongodb...${NC}"
wget http://77.55.218.93/mongod_bootstrap.tar.gz -q --show-progress 
echo -e "${ARROW} ${YELLOW}Unpacking...${NC}"
tar xvf mongod_bootstrap.tar.gz -C /home/$USER > /dev/null 2>&1 && sleep 1
echo -e "${ARROW} ${YELLOW}Stoping zelflux...${NC}"
pm2 stop zelflux > /dev/null 2>&1
echo -e "${ARROW} ${YELLOW}Importing mongodb datatable...${NC}"
mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop > /dev/null 2>&1
echo -e "${ARROW} ${YELLOW}Cleaning...${NC}"
sudo rm -rf /home/$USER/dump > /dev/null 2>&1 && sleep 1
sudo rm -rf mongod_bootstrap.tar.gz > /dev/null 2>&1  && sleep 1
pm2 start zelflux > /dev/null 2>&1
pm2 save > /dev/null 2>&1

NUM='120'
MSG1='Zelflux starting...'
MSG2="${CYAN}.....................[${CHECK_MARK}${CYAN}]${NC}"
spinning_timer
echo
BLOCKHIGHT_AFTER_BOOTSTRAP=$(wget -nv -qO - http://"$WANIP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
echo -e ${ARROW} ${CYAN}Node block hight after restored: ${GREEN}$BLOCKHIGHT_AFTER_BOOTSTRAP${NC}
if [[ "$BLOCKHIGHT_AFTER_BOOTSTRAP" -ge  "$DB_HIGHT" ]]
then
echo -e "${ARROW} ${CYAN}Mongo bootstrap installed successful.${NC}"
echo -e ""
else
echo -e "${ARROW} ${CYAN}Mongo bootstrap installation failed.${NC}"
echo -e ""
fi
else
echo -e "${ARROW} ${CYAN}Current Node block hight ${RED}$BLOCKHIGHT${CYAN} > Bootstrap block hight ${RED}$DB_HIGHT${CYAN}. Datatable is out of date.${NC}"
echo -e ""
fi

}

function wipe_clean() {
    echo -e "${ARROW} ${YELLOW}Removing any instances of ${COIN_NAME^}${NC}"
    apt_number=$(ps aux | grep 'apt' | wc -l)
    
    if [[ "$apt_number" > 1 ]]; then
    
        sudo killall apt > /dev/null 2>&1
        sudo killall apt-get > /dev/null 2>&1
	sudo dpkg --configure -a > /dev/null 2>&1
	
    fi
    
    echo -e "${ARROW} ${CYAN}Stopping all services and running processes...${NC}"
    sudo killall nano > /dev/null 2>&1
    "$COIN_CLI" stop > /dev/null 2>&1 && sleep 2
    sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
    sudo killall -s SIGKILL $COIN_DAEMON > /dev/null 2>&1 && sleep 2
    zelbench-cli stop > /dev/null 2>&1 && sleep 2
    sudo killall -s SIGKILL zelbenchd > /dev/null 2>&1 && sleep 1
    sudo fuser -k 16127/tcp > /dev/null 2>&1 && sleep 1
    sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
    sudo rm -rf  ${COIN_PATH}/zel* > /dev/null 2>&1 && sleep 1
    sudo rm -rf /usr/bin/${COIN_NAME}* > /dev/null 2>&1 && sleep 1
    sudo rm -rf /usr/local/bin/zel* > /dev/null 2>&1 && sleep 1
    echo -e "${ARROW} ${CYAN}Removing zelcash && zelbench...${NC}"
    sudo apt-get remove zelcash zelbench -y > /dev/null 2>&1 && sleep 1
    sudo apt-get purge zelcash zelbench -y > /dev/null 2>&1 && sleep 1
    sudo apt-get autoremove -y > /dev/null 2>&1 && sleep 1
    sudo rm -rf /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1 && sleep 1
    tmux kill-server > /dev/null 2>&1 && sleep 1
    echo -e "${ARROW} ${CYAN}Removing PM2...${NC}"
    pm2 del zelflux > /dev/null 2>&1 && sleep 1
    pm2 del watchdog > /dev/null 2>&1 && sleep 1
    pm2 save > /dev/null 2>&1
    pm2 unstartup > /dev/null 2>&1 && sleep 1
    pm2 flush > /dev/null 2>&1 && sleep 1
    pm2 save > /dev/null 2>&1 && sleep 1
    pm2 kill > /dev/null 2>&1  && sleep 1
    npm remove pm2 -g > /dev/null 2>&1 && sleep 1
    echo -e "${ARROW} ${CYAN}Removing Zelflux...${NC}"
    sudo rm -rf watchgod > /dev/null 2>&1 && sleep 1
    sudo rm -rf zelflux > /dev/null 2>&1  && sleep 1

    
    sudo rm -rf .zelbenchmark && sleep 1
    ## rm -rf $BOOTSTRAP_ZIPFILE && sleep 1
    echo -e "${ARROW} ${CYAN}Removing others files and scripts...${NC}"
    rm $UPDATE_FILE > /dev/null 2>&1
    rm restart_zelflux.sh > /dev/null 2>&1
    rm zelnodeupdate.sh > /dev/null 2>&1
    rm start.sh > /dev/null 2>&1
    rm update-zelflux.sh > /dev/null 2>&1
    
 if [[ -d /home/$USER/$CONFIG_DIR ]]; then
    
    if [[ -z "$use_old_chain" ]]; then
    
    if  ! whiptail --yesno "Would you like to use old chain from zelcash config directory?" 8 60; then
    echo -e "${ARROW} ${CYAN}Removing Zelcash config directory...${NC}"
    sudo rm -rf /home/$USER/.zelcash  > /dev/null 2>&1 && sleep 2
    sudo rm -rf ~/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/database ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate && sleep 2
    else
        BOOTSTRAP_SKIP="1"
	sudo rm -rf /home/$USER/$CONFIG_DIR/fee_estimates.dat 
	sudo rm -rf /home/$USER/$CONFIG_DIR/peers.dat && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/zelnode.conf 
	sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodecache.dat && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodepayments.dat
	sudo rm -rf /home/$USER/$CONFIG_DIR/db.log
	sudo rm -rf /home/$USER/$CONFIG_DIR/debug.log && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/zelcash.conf && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/database && sleep 1
	sudo rm -rf /home/$USER/$CONFIG_DIR/sporks && sleep 1
    fi
    
    else
    
    if [[ "$use_old_chain" == "1" ]]; then
    
      BOOTSTRAP_SKIP="1"
      sudo rm -rf /home/$USER/$CONFIG_DIR/fee_estimates.dat 
      sudo rm -rf /home/$USER/$CONFIG_DIR/peers.dat && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/zelnode.conf 
      sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodecache.dat && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/zelnodepayments.dat
      sudo rm -rf /home/$USER/$CONFIG_DIR/db.log
      sudo rm -rf /home/$USER/$CONFIG_DIR/debug.log && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/zelcash.conf && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/database && sleep 1
      sudo rm -rf /home/$USER/$CONFIG_DIR/sporks && sleep 1
    
    else
    
      echo -e "${ARROW} ${CYAN}Removing Zelcash config directory...${NC}"
      sudo rm -rf /home/$USER/.zelcash  > /dev/null 2>&1 && sleep 2
      sudo rm -rf ~/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/database ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate && sleep 2
    
    fi
    fi
fi

    sudo rm /home/$USER/fluxdb_dump.tar.gz > /dev/null 2>&1
    sudo rm -rf /home/$USER/watchdog > /dev/null 2>&1
    sudo rm -rf /home/$USER/stop_zelcash_service.sh > /dev/null 2>&1
    sudo rm -rf /home/$USER/start_zelcash_service.sh > /dev/null 2>&1
    echo -e ""

   # if [ ! -d "/home/$USER/$CONFIG_DIR" ]; then
       # echo -e "${CHECK_MARK} ${CYAN} Config directory /home/$USER/$CONFIG_DIR cleaned [OK]${NC}" && sleep 1
    #else
        #echo -e "${X_MARK} ${CYAN}Config directory /home/$USER/$CONFIG_DIR cleaned [Failed]${NC}" && sleep 1
    #fi

   # if ! ls '/usr/local/bin/' | grep zel > /dev/null 2>&1 ; then
        #echo -e "${CHECK_MARK} ${CYAN} Bin directory cleaned [OK]${NC}" && sleep 1
    #else
        #echo -e "${X_MARK} ${CYAN}Bin directory cleaned [Failed]${NC}" && sleep 1
    #fi
  echo -e "${ARROW} ${YELLOW}Checking firewall status...${NC}" && sleep 1
 if [[ $(sudo ufw status | grep "Status: active") ]]
  then
    if [[ -z "$firewall_disable" ]]; then    
      if   whiptail --yesno "Firewall is active and enabled. Do you want disable it during install process?<Yes>(Recommended)" 8 60; then
         sudo ufw disable > /dev/null 2>&1
	 echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
      else	 
	 echo -e "${ARROW} ${CYAN}Firewall status: ${GREEN}Enabled${NC}"
      fi
    else
    
      if [[ "$firewall_disable" == "1" ]]; then
  	 sudo ufw disable > /dev/null 2>&1
	 echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
      else
        echo -e "${ARROW} ${CYAN}Firewall status: ${GREEN}Enabled${NC}"
      fi
    fi
    
    else
        echo -e "${ARROW} ${CYAN}Firewall status: ${RED}Disabled${NC}"
 fi
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

#function spinning_timer() {
    
   # echo -ne "${RED}\r\033[1A\033[0K$i ${CYAN}${MSG1}${NC}"
    
   # end=$((SECONDS+NUM))
    #while [ $SECONDS -lt $end ];
    #do       
        # sleep 0.1
	 
   # done
    
    #echo -ne "${MSG2}"
#}

function ssh_port() {
    #echo -e "${YELLOW}Detecting SSH port being used...${NC}" && sleep 1
    
    if [[ -z "$ssh_port" ]]; then
    
    SSHPORT=$(grep -w Port /etc/ssh/sshd_config | sed -e 's/.*Port //')
    if ! whiptail --yesno "Detected you are using $SSHPORT for SSH is this correct?" 8 56; then
        SSHPORT=$(whiptail --inputbox "Please enter port you are using for SSH" 8 43 3>&1 1>&2 2>&3)
        echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    else
        echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    fi
    
    else   		
	pettern='^[0-9]+$'
	if [[ $ssh_port =~ $pettern ]] ; then
	  SSHPORT="$ssh_port"
	  echo -e "${ARROW} ${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
	else
	 echo -e "${ARROW} ${CYAN}SSH port must be integer................[${X_MARK}${CYAN}]${NC}}"
	 echo
	 exit
	fi	   
    fi
}

function ip_confirm() {
    echo -e "${ARROW} ${YELLOW}Detecting IP address...${NC}"
    WANIP=$(wget http://ipecho.net/plain -O - -q) 
    if [[ "$WANIP" == "" ]]; then
     WANIP=$(curl ifconfig.me)     
         if [[ "$WANIP" == "" ]]; then
      	 echo -e "${ARROW} ${CYAN}IP address could not be found, installation stopped .........[${X_MARK}${CYAN}]${NC}"
	 echo
	 exit
    	 fi
    fi
   string_limit_check_mark "Detected IP: $WANIP ................................." "Detected IP: ${GREEN}$WANIP${CYAN} ................................."
   # if ! whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60; then
        #WANIP=$(whiptail --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
   # fi
    
}

function create_swap() {

 if [[ -z "$swapon" ]]; then
    #echo -e "${YELLOW}Creating swap if none detected...${NC}" && sleep 1
    MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    gb=$(awk "BEGIN {print $MEM/1048576}")
    GB=$(echo "$gb" | awk '{printf("%d\n",$1 + 0.5)}')
    if [ "$GB" -lt 2 ]; then
        (( swapsize=GB*2 ))
        swap="$swapsize"G
        #echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -ge 2 ]] && [[ $GB -le 16 ]]; then
        swap=4G
       # echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -gt 16 ]] && [[ $GB -lt 32 ]]; then
        swap=2G
        #echo -e "${YELLOW}Swap set at $swap...${NC}"
    fi
    if ! grep -q "swapfile" /etc/fstab; then
        if whiptail --yesno "No swapfile detected would you like to create one?" 8 54; then
            sudo fallocate -l "$swap" /swapfile > /dev/null 2>&1
            sudo chmod 600 /swapfile > /dev/null 2>&1
            sudo mkswap /swapfile > /dev/null 2>&1
            sudo swapon /swapfile > /dev/null 2>&1
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null 2>&1
            echo -e "${ARROW} ${YELLOW}Created ${SEA}${swap}${YELLOW} swapfile${NC}"
        else
            echo -e "${ARROW} ${YELLOW}Creating a swapfile skipped...${NC}"
        fi
    fi
    
    else
    
     if [[ "$swapon" == "1" ]]; then
     
    MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    gb=$(awk "BEGIN {print $MEM/1048576}")
    GB=$(echo "$gb" | awk '{printf("%d\n",$1 + 0.5)}')
    if [ "$GB" -lt 2 ]; then
        (( swapsize=GB*2 ))
        swap="$swapsize"G
        #echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -ge 2 ]] && [[ $GB -le 16 ]]; then
        swap=4G
       # echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -gt 16 ]] && [[ $GB -lt 32 ]]; then
        swap=2G
        #echo -e "${YELLOW}Swap set at $swap...${NC}"
    fi
    if ! grep -q "swapfile" /etc/fstab; then
        #if whiptail --yesno "No swapfile detected would you like to create one?" 8 54; then
            sudo fallocate -l "$swap" /swapfile > /dev/null 2>&1
            sudo chmod 600 /swapfile > /dev/null 2>&1
            sudo mkswap /swapfile > /dev/null 2>&1
            sudo swapon /swapfile > /dev/null 2>&1
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null 2>&1
            echo -e "${ARROW} ${YELLOW}Created ${SEA}${swap}${YELLOW} swapfile${NC}"
      else
            echo -e "${ARROW} ${YELLOW}Creating a swapfile skipped...${NC}"
      fi
    #fi
     
     fi
    
    
    fi
    sleep 2
}

function install_packages() {
    echo
    echo -e "${ARROW} ${YELLOW}Installing Packages...${NC}"
    if [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
        sudo apt-get install dirmngr apt-transport-https -y > /dev/null 2>&1
    fi
    sudo apt-get install software-properties-common -y > /dev/null 2>&1
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get upgrade -y > /dev/null 2>&1
    sudo apt-get install nano htop pwgen ufw figlet tmux jq unzip -y > /dev/null 2>&1
    sudo apt-get install build-essential libtool pkg-config -y > /dev/null 2>&1
    sudo apt-get install libc6-dev m4 g++-multilib -y > /dev/null 2>&1
    sudo apt-get install autoconf ncurses-dev unzip git python python-zmq -y > /dev/null 2>&1
    sudo apt-get install wget curl bsdmainutils automake fail2ban -y > /dev/null 2>&1
    sudo apt-get remove sysbench -y > /dev/null 2>&1
    echo -e "${ARROW} ${YELLOW}Packages complete...${NC}"
}

function create_conf() {
    echo -e "${ARROW} ${YELLOW}Creating zelcash config file...${NC}"
    if [ -f ~/$CONFIG_DIR/$CONFIG_FILE ]; then
        echo -e "${ARROW} ${CYAN}Existing conf file found backing up to $COIN_NAME.old ...${NC}"
        mv ~/$CONFIG_DIR/$CONFIG_FILE ~/$CONFIG_DIR/$COIN_NAME.old;
    fi
    RPCUSER=$(pwgen -1 8 -n)
    PASSWORD=$(pwgen -1 20 -n)

    if [[ "$IMPORT_ZELCONF" == "0" ]]
    then
    zelnodeprivkey=$(whiptail --title "ZELNODE PRIVKEY" --inputbox "Enter your Zelnode Privkey generated by your Zelcore/Zelmate wallet" 8 72 3>&1 1>&2 2>&3)
    zelnodeoutpoint=$(whiptail --title "ZELNODE OUTPOINT" --inputbox "Enter your Zelnode collateral txid" 8 72 3>&1 1>&2 2>&3)
    zelnodeindex=$(whiptail --title "ZELNODE INDEX" --inputbox "Enter your Zelnode collateral output index usually a 0/1" 8 60 3>&1 1>&2 2>&3)
    fi


    if [ "x$PASSWORD" = "x" ]; then
        PASSWORD=${WANIP}-$(date +%s)
    fi
    mkdir ~/$CONFIG_DIR > /dev/null 2>&1
    touch ~/$CONFIG_DIR/$CONFIG_FILE
    cat << EOF > ~/$CONFIG_DIR/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcallowip=172.18.0.1
rpcport=$RPCPORT
port=$PORT
zelnode=1
zelnodeprivkey=$zelnodeprivkey
zelnodeoutpoint=$zelnodeoutpoint
zelnodeindex=$zelnodeindex
server=1
daemon=1
txindex=1
listen=1
externalip=$WANIP
bind=0.0.0.0
addnode=explorer.zel.cash
addnode=explorer2.zel.cash
addnode=explorer.zel.zelcore.io
addnode=blockbook.zel.network
maxconnections=256
EOF
    sleep 2
}

function zel_package() {
    sudo apt-get update > /dev/null 2>&1 && sleep 2
    echo -e "${ARROW} ${YELLOW}Zelcash && Zelbench installing...${NC}"
    sudo apt install zelcash zelbench -y > /dev/null 2>&1 && sleep 2
    sudo chmod 755 $COIN_PATH/${COIN_NAME}* > /dev/null 2>&1 && sleep 2
    integration_check
}

function install_zel() {
    echo 'deb https://apt.zel.cash/ all main' 2> /dev/null | sudo tee /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1
    sleep 1
    if [ ! -f /etc/apt/sources.list.d/zelcash.list ]; then
        echo 'deb https://zelcash.github.io/aptrepo/ all main' 2> /dev/null | sudo tee --append /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1
    fi
    gpg --keyserver keyserver.ubuntu.com --recv 4B69CA27A986265D > /dev/null 2>&1 && sleep 2
    gpg --export 4B69CA27A986265D | sudo apt-key add - > /dev/null 2>&1 && sleep 2
    zel_package && sleep 2
    if ! gpg --list-keys Zel > /dev/null; then
        echo -e "${YELLOW}First attempt to retrieve keys failed will try a different keyserver.${NC}"
        gpg --keyserver na.pool.sks-keyservers.net --recv 4B69CA27A986265D > /dev/null 2>&1 && sleep 2
        gpg --export 4B69CA27A986265D | sudo apt-key add - > /dev/null 2>&1 && sleep 2
        zel_package && sleep 2
        if ! gpg --list-keys Zel > /dev/null; then
            echo -e "${YELLOW}Second keyserver also failed will try a different keyserver.${NC}"
            gpg --keyserver eu.pool.sks-keyservers.net --recv 4B69CA27A986265D > /dev/null 2>&1 && sleep 2
            gpg --export 4B69CA27A986265D | sudo apt-key add - > /dev/null 2>&1 && sleep 2
            zel_package && sleep 2
            if ! gpg --list-keys Zel > /dev/null; then
                echo -e "${YELLOW}Third keyserver also failed will try a different keyserver.${NC}"
                gpg --keyserver pgpkeys.urown.net --recv 4B69CA27A986265D > /dev/null 2>&1 && sleep 2
                gpg --export 4B69CA27A986265D | sudo apt-key add - > /dev/null 2>&1 && sleep 2
                zel_package && sleep 2
                if ! gpg --list-keys Zel > /dev/null; then
                    echo -e "${YELLOW}Last keyserver also failed will try one last keyserver.${NC}"
                    gpg --keyserver keys.gnupg.net --recv 4B69CA27A986265D > /dev/null 2>&1 && sleep 2
                    gpg --export 4B69CA27A986265D | sudo apt-key add - > /dev/null 2>&1 && sleep 2
                    zel_package && sleep 2
                fi
            fi
        fi
    fi
}

function zk_params() {
    echo -e "${ARROW} ${YELLOW}Installing zkSNARK params...${NC}"
    bash zelcash-fetch-params.sh > /dev/null 2>&1 && sleep 2
    sudo chown -R $USER:$USER /home/$USER  > /dev/null 2>&1
}

function bootstrap() {

if [[ -z "$bootstrap_url" ]]; then

if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
echo -e "${ARROW} ${YELLOW}Cleaning...${NC}"
rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate
fi

if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
echo -e "${ARROW} ${YELLOW}Local bootstrap file detected...${NC}"
echo -e "${ARROW} ${YELLOW}Checking if zip file is corrupted...${NC}"


if unzip -t zel-bootstrap.zip | grep 'No errors' > /dev/null 2>&1
then
echo -e "${ARROW} ${CYAN}Bootstrap zip file is valid.............[${CHECK_MARK}${CYAN}]${NC}"
else
printf '\e[A\e[K'
printf '\e[A\e[K'
printf '\e[A\e[K'
printf '\e[A\e[K'
printf '\e[A\e[K'
printf '\e[A\e[K'
echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
rm -rf zel-bootstrap.zip
fi
fi


if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]
then
echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"

#lsof +d /home/$USER/.zelcash
#sleep 4
unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
else


CHOICE=$(
whiptail --title "ZELNODE INSTALLATION" --menu "Choose a method how to get bootstrap file" 10 47 2  \
        "1)" "Download from source build in script" \
        "2)" "Download from own source" 3>&2 2>&1 1>&3
)


case $CHOICE in
	"1)")   
		echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
       		wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
       		echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
        	unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1


	;;
	"2)")   
  		BOOTSTRAP_ZIP="$(whiptail --title "ZELNODE INSTALLATION" --inputbox "Enter your URL" 8 72 3>&1 1>&2 2>&3)"
		echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
		wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
		echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
		unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
	;;
esac

fi

else

if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
    echo -e "${ARROW} ${YELLOW}Cleaning...${NC}"
    rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate
fi

if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
    echo -e "${ARROW} ${YELLOW}Local bootstrap file detected...${NC}"
    echo -e "${ARROW} ${YELLOW}Checking if zip file is corrupted...${NC}"

    if unzip -t zel-bootstrap.zip | grep 'No errors' > /dev/null 2>&1
    then
      echo -e "${ARROW} ${CYAN}Bootstrap zip file is valid.............[${CHECK_MARK}${CYAN}]${NC}"
    else
      printf '\e[A\e[K'
      printf '\e[A\e[K'
      printf '\e[A\e[K'
      printf '\e[A\e[K'
      printf '\e[A\e[K'
      printf '\e[A\e[K'
      echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
      rm -rf zel-bootstrap.zip
    fi
fi


if [[ "$bootstrap_url" == "" ]]; then

if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
else
echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
fi
else
if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
else
BOOTSTRAP_ZIP="$bootstrap_url"
echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
fi
fi



fi

if [[ -z "$bootstrap_zip_del" ]]; then
 if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
    rm -rf $BOOTSTRAP_ZIPFILE
 fi
else

if [[ "$bootstrap_zip_del" == "1" ]]; then
  rm -rf $BOOTSTRAP_ZIPFILE
fi
  
fi

}


function create_service_scripts() {

echo -e "${ARROW} ${YELLOW}Creating ${COIN_NAME^} service custom scripts...${NC}" && sleep 1
sudo touch /home/$USER/start_zelcash_service.sh
sudo chown $USER:$USER /home/$USER/start_zelcash_service.sh
    cat <<'EOF' > /home/$USER/start_zelcash_service.sh
#!/bin/bash
#color codes
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'
#emoji codes
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
sleep 2
echo -e "${BOOK} ${CYAN}Pre-start process starting...${NC}"
echo -e "${BOOK} ${CYAN}Checking if zelbenchd or zelcashd is running${NC}"
zelbenchd_status_pind=$(pgrep zelbenchd)
zelcashd_status_pind=$(pgrep zelcashd)
if [[ "$zelbenchd_status_pind" == "" && "$zelcashd_status_pind" == "" ]]; then
echo -e "${BOOK} ${CYAN}The service can be safely started${NC}"
else
if [[ "$zelbenchd_status_pind" != "" ]]; then
echo -e "${WORNING} Running zelbanchd process detected${NC}"
echo -e "${WORNING} Killing zelbanchd...${NC}"
sudo killall zelbenchd > /dev/null 2>&1  && sleep 2
fi
if [[ "$zelcashd_status_pind" != "" ]]; then
echo -e "${WORNING} Running zelcashd process detected${NC}"
echo -e "${WORNING} Killing zelcashd...${NC}"
sudo killall zelcashd > /dev/null 2>&1  && sleep 2
fi
sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
fi
bash -c "zelcashd"
exit
EOF


sudo touch /home/$USER/stop_zelcash_service.sh
sudo chown $USER:$USER /home/$USER/stop_zelcash_service.sh
    cat <<'EOF' > /home/$USER/stop_zelcash_service.sh
#!/bin/bash
bash -c "zelcash-cli stop"
exit
EOF

sudo chmod +x /home/$USER/stop_zelcash_service.sh
sudo chmod +x /home/$USER/start_zelcash_service.sh

}

function create_service() {
    echo -e "${ARROW} ${YELLOW}Creating ${COIN_NAME^} service...${NC}" && sleep 1
    sudo touch /etc/systemd/system/$COIN_NAME.service
    sudo chown $USER:$USER /etc/systemd/system/$COIN_NAME.service
    cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
Type=forking
User=$USER
Group=$USER
WorkingDirectory=/home/$USER/$CONFIG_DIR/
ExecStart=/home/$USER/start_zelcash_service.sh
ExecStop=-/home/$USER/stop_zelcash_service.sh
Restart=always
RestartSec=10
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=15s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
    sudo chown root:root /etc/systemd/system/$COIN_NAME.service
    sudo systemctl daemon-reload
}

function basic_security() {
    echo -e "${ARROW} ${YELLOW}Configuring firewall and enabling fail2ban...${NC}"
    sudo ufw allow 16124/tcp > /dev/null 2>&1
    sudo ufw allow "$SSHPORT"/tcp > /dev/null 2>&1
    sudo ufw allow "$PORT"/tcp > /dev/null 2>&1
    sudo ufw logging on > /dev/null 2>&1
    sudo ufw default deny incoming > /dev/null 2>&1
    
    sudo ufw allow out to any port 80 > /dev/null 2>&1
    sudo ufw allow out to any port 443 > /dev/null 2>&1
    sudo ufw allow out to any port 53 > /dev/null 2>&1
    sudo ufw allow out to any port 16124 > /dev/null 2>&1
    sudo ufw allow out to any port 16125 > /dev/null 2>&1
    
    sudo ufw default deny outgoing > /dev/null 2>&1
    sudo ufw limit OpenSSH > /dev/null 2>&1
    echo "y" | sudo ufw enable > /dev/null 2>&1
    sudo ufw reload > /dev/null 2>&1
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
}

function pm2_install(){

    echo -e "${ARROW} ${YELLOW}PM2 installing...${NC}"
    npm install pm2@latest -g > /dev/null 2>&1
    
    if pm2 -v > /dev/null 2>&1
    then
     	echo -e "${ARROW} ${YELLOW}Configuring PM2...${NC}"
   	pm2 startup systemd -u $USER > /dev/null 2>&1
   	sudo env PATH=$PATH:/home/$USER/.nvm/versions/node/$(node -v)/bin pm2 startup systemd -u $USER --hp /home/$USER > /dev/null 2>&1
   	pm2 start ~/zelflux/start.sh --name zelflux > /dev/null 2>&1
    	pm2 save > /dev/null 2>&1
	pm2 install pm2-logrotate > /dev/null 2>&1
	pm2 set pm2-logrotate:max_size 6M > /dev/null 2>&1
	pm2 set pm2-logrotate:retain 6 > /dev/null 2>&1
    	pm2 set pm2-logrotate:compress true > /dev/null 2>&1
    	pm2 set pm2-logrotate:workerInterval 3600 > /dev/null 2>&1
    	pm2 set pm2-logrotate:rotateInterval '0 12 * * 0' > /dev/null 2>&1
	source ~/.bashrc
	#echo -e "${ARROW} ${CYAN}PM2 version: ${GREEN}v$(pm2 -v)${CYAN} installed${NC}"
	 string_limit_check_mark "PM2 v$(pm2 -v) installed................................." "PM2 ${GREEN}v$(pm2 -v)${CYAN} installed................................."
	 echo
    else
   	 echo -e "${ARROW} ${CYAN}PM2 was not installed${NC}"
	 string_limit_x_mark "PM2 was not installed................................."
	 echo
    fi 

}

function start_daemon() {

    sudo systemctl enable $COIN_NAME.service > /dev/null 2>&1
    sudo systemctl start zelcash > /dev/null 2>&1
    
    NUM='120'
    MSG1='Starting daemon & syncing with chain please be patient this will take about 2 min...'
    MSG2=''
    if $COIN_DAEMON > /dev/null 2>&1; then
        spinning_timer
        NUM='2'
        MSG1='Getting info...'
        MSG2="${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
        spinning_timer
        echo && echo
	
	zelcash_version=$(zelcash-cli getinfo | jq -r '.version')
	string_limit_check_mark "Zelcash v$zelcash_version installed................................." "Zelcash ${GREEN}v$zelcash_version${CYAN} installed................................."
	#echo -e "Zelcash version: ${GREEN}v$zelcash_version${CYAN} installed................................."
	zelbench_version=$(zelbench-cli getinfo | jq -r '.version')
	string_limit_check_mark "Zelbench v$zelbench_version installed................................." "Zelbench ${GREEN}v$zelbench_version${CYAN} installed................................."
	#echo -e "${ARROW} ${CYAN}Zelbench version: ${GREEN}v$zelbench_version${CYAN} installed${NC}"
	echo
	pm2_install
	#zelbench-cli stop > /dev/null 2>&1  && sleep 2
    else
        echo -e "${WORNING} ${RED}Something is not right the daemon did not start. Will exit out so try and run the script again.${NC}"
	echo
        exit
    fi
}

function log_rotate() {
    echo -e "${ARROW} ${YELLOW}Configuring log rotate function for debug logs...${NC}"
    sleep 1
    if [ -f /etc/logrotate.d/zeldebuglog ]; then
        echo -e "${ARROW} ${YELLOW}Existing log rotate conf found, backing up to ~/zeldebuglogrotate.old ...${NC}"
	sudo mv /etc/logrotate.d/zeldebuglog ~/zeldebuglogrotate.old
	sleep 2
    fi
    sudo touch /etc/logrotate.d/zeldebuglog
    sudo chown "$USERNAME":"$USERNAME" /etc/logrotate.d/zeldebuglog
    cat << EOF > /etc/logrotate.d/zeldebuglog
/home/$USERNAME/.zelcash/debug.log {
  compress
  copytruncate
  missingok
  weekly
  rotate 4
}
/home/$USERNAME/.zelbenchmark/debug.log {
  compress
  copytruncate
  missingok
  monthly
  rotate 2
}
EOF
    sudo chown root:root /etc/logrotate.d/zeldebuglog
}

function install_zelflux() {
    #echo 
    echo -e "${ARROW} ${YELLOW}Configuring firewall...${NC}"
    sudo ufw allow $ZELFRONTPORT/tcp > /dev/null 2>&1
    sudo ufw allow $LOCPORT/tcp > /dev/null 2>&1
    sudo ufw allow $ZELNODEPORT/tcp > /dev/null 2>&1
    sudo ufw allow $MDBPORT/tcp > /dev/null 2>&1

    echo -e "${ARROW} ${YELLOW}Configuring service repositories...${NC}"
    if ! sysbench --version > /dev/null 2>&1; then
        curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh 2> /dev/null | sudo bash > /dev/null 2>&1
        sudo apt -y install sysbench > /dev/null 2>&1
    fi

    sudo rm /etc/apt/sources.list.d/mongodb*.list > /dev/null 2>&1
    if [[ $(lsb_release -r) = *16.04* ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" 2> /dev/null| sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list > /dev/null 2>&1
        install_mongod
        install_nodejs
        zelflux
    elif [[ $(lsb_release -r) = *18.04* ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list > /dev/null 2>&1
        install_mongod
        install_nodejs
        zelflux
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.2 main" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list > /dev/null 2>&1
        install_mongod
        install_nodejs
        zelflux
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *10* ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list > /dev/null 2>&1
        install_mongod
        install_nodejs
        zelflux
    fi
    sleep 2
}

function install_mongod() {
echo
echo -e "${ARROW} ${YELLOW}Removing any instances of Mongodb...${NC}"
sudo apt remove mongod* -y > /dev/null 2>&1 && sleep 1
sudo apt purge mongod* -y > /dev/null 2>&1 && sleep 1
sudo apt autoremove -y > /dev/null 2>&1 && sleep 1
echo -e "${ARROW} ${YELLOW}Mongodb installing...${NC}"
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install mongodb-org -y > /dev/null 2>&1 && sleep 2
sudo systemctl enable mongod > /dev/null 2>&1
sudo systemctl start  mongod > /dev/null 2>&1
if mongod --version > /dev/null 2>&1 
then
 #echo -e "${ARROW} ${CYAN}MongoDB version: ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed${NC}"
 string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
 echo
else
 #echo -e "${ARROW} ${CYAN}MongoDB was not installed${NC}" 
 string_limit_x_mark "MongoDB was not installed................................."
 echo
fi
}

function install_nodejs() {
echo -e "${ARROW} ${YELLOW}Removing any instances of Nodejs...${NC}"
n-uninstall -y > /dev/null 2>&1 && sleep 1
rm -rf ~/n
sudo apt-get remove nodejs npm nvm -y > /dev/null 2>&1 && sleep 1
sudo apt-get purge nodejs nvm -y > /dev/null 2>&1 && sleep 1
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/share/man/man1/node*
sudo rm -rf /usr/local/lib/dtrace/node.d
sudo rm -rf ~/.npm
sudo rm -rf ~/.nvm
sudo rm -rf ~/.pm2
sudo rm -rf ~/.node-gyp
sudo rm -rf /opt/local/bin/node
sudo rm -rf opt/local/include/node
sudo rm -rf /opt/local/lib/node_modules
sudo rm -rf /usr/local/lib/node*
sudo rm -rf /usr/local/include/node*
sudo rm -rf /usr/local/bin/node*
echo -e "${ARROW} ${YELLOW}Nodejs installing...${NC}"
#export NVM_DIR="$HOME/.nvm" && (
 # git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" > /dev/null 2>&1 
 # cd "$NVM_DIR"
 # git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` > /dev/null 2>&1
#) && \. "$NVM_DIR/nvm.sh"
#cd
curl --silent -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash > /dev/null 2>&1
. ~/.profile
bash -c "source /home/$USER/.bashrc"
sleep 1
#nvm install v12.16.1
nvm install --lts > /dev/null 2>&1
if node -v > /dev/null 2>&1
then
#echo -e "${ARROW} ${CYAN}Nodejs version: ${GREEN}$(node -v)${CYAN} installed${NC}"
string_limit_check_mark "Nodejs $(node -v) installed................................." "Nodejs ${GREEN}$(node -v)${CYAN} installed................................."
echo
else
#echo -e "${ARROW} ${CYAN}Nodejs was not installed${NC}"
string_limit_x_mark "Nodejs was not installed................................."
echo
fi

}

function zelflux() {
   
    if [ -d "./zelflux" ]; then
         echo -e "${ARROW} ${YELLOW}Removing any instances of zelflux....${NC}"
         sudo rm -rf zelflux
    fi



    echo -e "${ARROW} ${YELLOW}Zelflux installing...${NC}"
    git clone https://github.com/zelcash/zelflux.git > /dev/null 2>&1
    echo -e "${ARROW} ${YELLOW}Creating zelflux configuration file...${NC}"
    
    
            if [[ "$IMPORT_ZELID" == "0" ]]
        then

        while true
                do
                ZELID="$(whiptail --title "ZelFlux Configuration" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
                if [ $(printf "%s" "$ZELID" | wc -c) -eq "34" ] || [ $(printf "%s" "$ZELID" | wc -c) -eq "33" ]
                then
                echo -e "${ARROW} ${CYAN}Zel ID is valid${CYAN}.........................[${CHECK_MARK}${CYAN}]${NC}"
                break
                else
                echo -e "${ARROW} ${CYAN}Zel ID is not valid try again...........[${X_MARK}${CYAN}]${NC}}"
                sleep 4
                fi
        done

        fi
      
    touch ~/zelflux/config/userconfig.js
    cat << EOF > ~/zelflux/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '${WANIP}',
        zelid: '${ZELID}',
        testnet: false
      }
    }
EOF

if [ -d ~/zelflux ]
then
current_ver=$(jq -r '.version' /home/$USER/zelflux/package.json)

string_limit_check_mark "Zelflux v$current_ver installed................................." "Zelflux ${GREEN}v$current_ver${CYAN} installed................................."
#echo -e "${ARROW} ${CYAN}Zelflux version: ${GREEN}v$current_ver${CYAN} installed${NC}"

echo
else
string_limit_x_mark "Zelflux was not installed................................."
#echo -e "${ARROW} ${CYAN}Zelflux was not installed${NC}"
echo
fi

}


function status_loop() {

if [[ $(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks') == $(${COIN_CLI} getinfo | jq '.blocks') ]]; then
echo
echo -e "${CLOCK}${GREEN}ZELNODE SYNCING...${NC}"

EXPLORER_BLOCK_HIGHT=$(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks')
LOCAL_BLOCK_HIGHT=$(${COIN_CLI} getinfo 2> /dev/null | jq '.blocks')
CONNECTIONS=$(${COIN_CLI} getinfo 2> /dev/null | jq '.connections')
LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))

NUM='2'
MSG1="Syncing progress >> Local block hight: ${GREEN}$LOCAL_BLOCK_HIGHT${CYAN} Explorer block hight: ${RED}$EXPLORER_BLOCK_HIGHT${CYAN} Left: ${YELLOW}$LEFT${CYAN} blocks, Connections: ${YELLOW}$CONNECTIONS${CYAN}"
MSG2="${CYAN} ................[${CHECK_MARK}${CYAN}]${NC}"
spinning_timer
echo && echo

else
	
   echo
   echo -e "${CLOCK}${GREEN}ZELNODE SYNCING...${NC}"
   
   f=0
 #  c=0
	
    while true
    do
        
        EXPLORER_BLOCK_HIGHT=$(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks')
        LOCAL_BLOCK_HIGHT=$(${COIN_CLI} getinfo 2> /dev/null | jq '.blocks')
	CONNECTIONS=$(${COIN_CLI} getinfo 2> /dev/null | jq '.connections')
	LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))
	
	if [[ "$LEFT" == "0" ]]; then	
	  time_break='5'
	else
	  time_break='20'
	fi
	
	#if [[ "$CONNECTIONS" == "0" ]]; then
	 # c=$((c+1))
	 # if [[ "$c" > 3 ]]; then
	  # c=0;
	   #LOCAL_BLOCK_HIGHT=""
	#  fi
	
	#fi
	#
	if [[ $LOCAL_BLOCK_HIGHT == "" ]]; then
	f=$((f+1))
	LOCAL_BLOCK_HIGHT="N/A"
	LEFT="N/A"
	CONNECTIONS="N/A"
	sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 2
	sudo systemctl start zelcash > /dev/null 2>&1
	
          NUM='60'
          MSG1="Syncing progress => Local block hight: ${GREEN}$LOCAL_BLOCK_HIGHT${CYAN} Explorer block hight: ${RED}$EXPLORER_BLOCK_HIGHT${CYAN} Left: ${YELLOW}$LEFT${CYAN} blocks, Connections: ${YELLOW}$CONNECTIONS${CYAN} Failed: ${RED}$f${NC}"
          MSG2=''
          spinning_timer
	  
	  EXPLORER_BLOCK_HIGHT=$(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks')
       	  LOCAL_BLOCK_HIGHT=$(${COIN_CLI} getinfo 2> /dev/null | jq '.blocks')
	  CONNECTIONS=$(${COIN_CLI} getinfo 2> /dev/null | jq '.connections')
	  LEFT=$((EXPLORER_BLOCK_HIGHT-LOCAL_BLOCK_HIGHT))

	fi
	
	NUM="$time_break"
        MSG1="Syncing progress >> Local block hight: ${GREEN}$LOCAL_BLOCK_HIGHT${CYAN} Explorer block hight: ${RED}$EXPLORER_BLOCK_HIGHT${CYAN} Left: ${YELLOW}$LEFT${CYAN} blocks, Connections: ${YELLOW}$CONNECTIONS${CYAN} Failed: ${RED}$f${NC}"
        MSG2=''
        spinning_timer
	
        if [[ "$EXPLORER_BLOCK_HIGHT" == "$LOCAL_BLOCK_HIGHT" ]]; then	
	    echo -e "${CYAN} ................[${CHECK_MARK}${CYAN}]${NC}"
	    echo
            break
        fi
    done
    
    fi

   
  if [[ -z "$mongo_bootstrap" ]]; then
    
    if   whiptail --yesno "Would you like to restore Mongodb datatable from bootstrap?" 8 60; then
         mongodb_bootstrap
    else
        echo -e "${ARROW} ${YELLOW}Restore Mongodb datatable skipped...${NC}"
    fi
  else
   
    if [[ "$mongo_bootstrap" == "1" ]]; then
      mongodb_bootstrap
    else
      echo -e "${ARROW} ${YELLOW}Restore Mongodb datatable skipped...${NC}"
    fi
   
  fi
    
    
  if [[ -z "$watchdog" ]]; then
    if   whiptail --yesno "Would you like to install watchdog for zelnode?" 8 60; then
         install_watchdog
    else
        echo -e "${ARROW} ${YELLOW}Watchdog installation skipped...${NC}"
    fi
   else
   
     if [[ "$watchdog" == "1" ]]; then
      install_watchdog
     else
      echo -e "${ARROW} ${YELLOW}Watchdog installation skipped...${NC}"
     fi
   
   fi

    check
    display_banner
}

function update_script() {
    echo -e "${ARROW} ${YELLOW}Creating a script to update binaries for future updates...${NC}"
    touch /home/"$USERNAME"/update.sh
    cat << EOF > /home/"$USERNAME"/update.sh
#!/bin/bash
COIN_NAME='zelcash'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
\$COIN_CLI stop > /dev/null 2>&1 && sleep 2
sudo killall \$COIN_DAEMON > /dev/null 2>&1
sudo apt-get update
sudo apt-get install --only-upgrade \$COIN_NAME -y
sudo chmod 755 \${COIN_PATH}/\${COIN_NAME}*
\$COIN_DAEMON > /dev/null 2>&1
EOF

#sudo chmod +x update.sh
#echo "cd /home/$USER/zelflux" >> "/home/$USER/update-zelflux.sh"
#echo "git pull" >> "/home/$USER/update-zelflux.sh"
#chmod +x "/home/$USER/update-zelflux.sh"
#(crontab -l -u "$USER" 2>/dev/null; echo "0 0 * * 0 /home/$USER/update-zelflux.sh") | crontab -

}


function check() {
    NUM='60'
    MSG1='Finalizing installation please be patient this will take about 1min...'
    MSG2="${CYAN}.............[${CHECK_MARK}${CYAN}]${NC}"
    echo && spinning_timer
    echo && echo
        
echo -e "${BOOK}${YELLOW}ZelBench benchmarks:${NC}"
echo -e "${YELLOW}======================${NC}"
zelbench_benchmarks=$(zelbench-cli getbenchmarks)

if [[ "zelbench_benchmarks" != "" ]]; then
zelbench_status=$(jq -r '.status' <<< "$zelbench_benchmarks")
if [[ "$zelbench_status" == "failed" ]]; then
echo -e "${ARROW} ${CYAN}Zelbench benchmark failed...............[${X_MARK}${CYAN}]${NC}"
else
echo -e "${BOOK}${CYAN}STATUS: ${GREEN}$zelbench_status${NC}"
zelbench_cores=$(jq -r '.cores' <<< "$zelbench_benchmarks")
echo -e "${BOOK}${CYAN}CORES: ${GREEN}$zelbench_cores${NC}"
zelbench_ram=$(jq -r '.ram' <<< "$zelbench_benchmarks")
zelbench_ram=$(round "$zelbench_ram" 2)
echo -e "${BOOK}${CYAN}RAM: ${GREEN}$zelbench_ram${NC}"
zelbench_ssd=$(jq -r '.ssd' <<< "$zelbench_benchmarks")
zelbench_ssd=$(round "$zelbench_ssd" 2)
echo -e "${BOOK}${CYAN}SSD: ${GREEN}$zelbench_ssd${NC}"
zelbench_hdd=$(jq -r '.hdd' <<< "$zelbench_benchmarks")
zelbench_hdd=$(round "$zelbench_hdd" 2)
echo -e "${BOOK}${CYAN}HDD: ${GREEN}$zelbench_hdd${NC}"
zelbench_ddwrite=$(jq -r '.ddwrite' <<< "$zelbench_benchmarks")
zelbench_ddwrite=$(round "$zelbench_ddwrite" 2)
echo -e "${BOOK}${CYAN}DDWRITE: ${GREEN}$zelbench_ddwrite${NC}"
zelbench_eps=$(jq -r '.eps' <<< "$zelbench_benchmarks")
zelbench_eps=$(round "$zelbench_eps" 2)
echo -e "${BOOK}${CYAN}EPS: ${GREEN}$zelbench_eps${NC}"
fi

else
echo -e "${ARROW} ${CYAN}Zelbench not responding.................[${X_MARK}${CYAN}]${NC}"
fi
}

function display_banner() {
    echo -e "${BLUE}"
    figlet -t -k "ZELNODES  &  ZELFLUX"
    echo -e "${YELLOW}================================================================================================================================"
    echo -e "PLEASE COMPLETE THE ZELNODE SETUP AND START YOUR ZELNODE${NC}"
    echo -e "${CYAN}COURTESY OF DK808/XK4MiLX${NC}"
    echo
    if pm2 -v > /dev/null 2>&1; then
	pm2_zelflux_status=$(pm2 info zelflux 2> /dev/null | grep 'status' | sed -r 's/│//gi' | sed 's/status.//g' | xargs)
	if [[ "$pm2_zelflux_status" == "online" ]]; then
	pm2_zelflux_uptime=$(pm2 info zelflux | grep 'uptime' | sed -r 's/│//gi' | sed 's/uptime//g' | xargs)
	pm2_zelflux_restarts=$(pm2 info zelflux | grep 'restarts' | sed -r 's/│//gi' | xargs)
	echo -e "${BOOK} ${CYAN}Pm2 Zelflux info => status: ${GREEN}$pm2_zelflux_status${CYAN}, uptime: ${GREEN}$pm2_zelflux_uptime${NC} ${SEA}$pm2_zelflux_restarts${NC}" 
	else
		if [[ "$pm2_zelflux_status" != "" ]]; then
		echo -e "${PIN} ${CYAN}PM2 Zelflux status: ${RED}$pm2_zelflux_status ${NC}" 
		fi
	fi
	    echo
     fi
    echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE ZELCASH.${NC}" 
    echo -e "${PIN} ${CYAN}Start zelcash: ${SEA}sudo systemctl start zelcash${NC}"
    echo -e "${PIN} ${CYAN}Stop zelcash: ${SEA}sudo systemctl stop zelcash${NC}"
    echo -e "${PIN} ${CYAN}Help list: ${SEA}${COIN_CLI} help${NC}"
    echo
    echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE ZELBENCH.${NC}" 
    echo -e "${PIN} ${CYAN}Get info: ${SEA}zelbench-cli getinfo${NC}"
    echo -e "${PIN} ${CYAN}Check benchmark: ${SEA}zelbench-cli getbenchmarks${NC}"
    echo -e "${PIN} ${CYAN}Restart benchmark: ${SEA}zelbench-cli restartnodebenchmarks${NC}"
    echo -e "${PIN} ${CYAN}Stop benchmark: ${SEA}zelbench-cli stop${NC}"
    echo -e "${PIN} ${CYAN}Start benchmark: ${SEA}sudo systemctl restart zelcash${NC}"
    echo
    echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE ZELFLUX.${NC}"
    echo -e "${PIN} ${CYAN}Summary info: ${SEA}pm2 info zelflux${NC}"
    echo -e "${PIN} ${CYAN}Logs in real time: ${SEA}pm2 monit${NC}"
    echo -e "${PIN} ${CYAN}Stop zelflux: ${SEA}pm2 stop zelflux${NC}"
    echo -e "${PIN} ${CYAN}Start zelflux: ${SEA}pm2 start zelflux${NC}"
    echo
    if [[ "$WATCHDOG_INSTALL" == "1" ]]; then
    echo -e "${ARROW}${YELLOW}  COMMANDS TO MANAGE WATCHDOG.${NC}"
    echo -e "${PIN} ${CYAN}Stop watchdog: ${SEA}pm2 stop watchdog${NC}"
    echo -e "${PIN} ${CYAN}Start watchdog: ${SEA}pm2 start watchdog --watch${NC}"
    echo -e "${PIN} ${CYAN}Restart watchdog: ${SEA}pm2 reload watchdog --watch${NC}"
    echo -e "${PIN} ${CYAN}Error logs: ${SEA}~/watchdog/watchdog_error.log${NC}"
    echo -e "${PIN} ${CYAN}Logs in real time: ${SEA}pm2 monit${NC}"
    echo
    echo -e "${PIN} ${RED}IMPORTANT: After installation check ${SEA}'pm2 list'${RED} if not work, type ${SEA}'source /home/$USER/.bashrc'${NC}"
    echo
    fi
    echo -e "${PIN} ${CYAN}To access your frontend to Zelflux enter this in as your url: ${SEA}${WANIP}:${ZELFRONTPORT}${NC}"
    echo -e "${YELLOW}================================================================================================================================${NC}"
    sleep 1
}

#end of functions
#run functions
    wipe_clean
    ssh_port
    ip_confirm
    create_swap
    install_packages
    create_conf
    install_zel
    zk_params
    if [[ "$BOOTSTRAP_SKIP" == "0" ]]; then
    bootstrap
    fi
    create_service_scripts
    create_service
    install_zelflux
    start_daemon
    log_rotate
    update_script
    basic_security
    status_loop
