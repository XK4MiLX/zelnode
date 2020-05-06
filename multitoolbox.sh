#!/bin/bash

BOOTSTRAP_ZIP='http://77.55.218.93/zel-bootstrap.zip'
BOOTSTRAP_ZIPFILE='zel-bootstrap.zip'
#BOOTSTRAP_ZIP='https://www.dropbox.com/s/kyqe8ji3g1yetfx/zel-bootstrap.zip'
BOOTSTRAP_URL_MONGOD='http://77.55.218.93/mongod_bootstrap.tar.gz'
BOOTSTRAP_ZIPFILE_MONGOD='mongod_bootstrap.tar.gz'

CONFIG_DIR='.zelcash'
CONFIG_FILE='zelcash.conf'

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
dversion="v4.0"

PM2_INSTALL="0"
zelflux_setting_import="0"

#dialog color
export NEWT_COLORS='
title=black,
'

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

echo -e "${ARROW} ${YELLOW}Install config summary:"

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

function ip_confirm() {
    echo -e "${ARROW} ${CYAN}Detecting IP address...${NC}"
    WANIP=$(wget http://ipecho.net/plain -O - -q) 
    if [[ "$WANIP" == "" ]]; then
     WANIP=$(curl ifconfig.me)     
         if [[ "$WANIP" == "" ]]; then
      	 echo -e "${ARROW} ${CYAN}IP address could not be found, installation stopped .........[${X_MARK}${CYAN}]${NC}"
	 echo
	 exit
    	 fi
    fi
   string_limit_check_mark "IP: $WANIP ..........................................." "IP: ${GREEN}$WANIP${CYAN} ..........................................."
    
}

function install_flux() {

echo -e "${GREEN}Module: Re-install ZelFluxr${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

if [ -d /home/$USER/zelflux ]; then

    echo -e "${ARROW} ${CYAN}Importing setting...${NC}"
    zel_id=$(grep -w zelid /home/$USER/zelflux/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
    WANIP=$(grep -w ipaddress /home/$USER/zelflux/config/userconfig.js | sed -e 's/.*ipaddress: .//' | sed -e 's/.\{2\}$//')
    echo -e "${PIN}${CYAN}Zel ID = ${GREEN}$zel_id${NC}" && sleep 1
    echo -e "${PIN}${CYAN}IP = ${GREEN}$WANIP${NC}" && sleep 1   
    echo 
    echo -e "${ARROW} ${CYAN}Removing any instances of zelflux....${NC}"
    sudo rm -rf zelflux
    zelflux_setting_import="1"

fi

echo -e "${ARROW} ${CYAN}ZelFlux downloading...${NC}"
git clone https://github.com/zelcash/zelflux.git

if [ -d /home/$USER/zelflux ]
then
current_ver=$(jq -r '.version' /home/$USER/zelflux/package.json)
string_limit_check_mark "Zelflux v$current_ver downloaded..........................................." "Zelflux ${GREEN}v$current_ver${CYAN} downloaded..........................................."
else
string_limit_x_mark "Zelflux was not downloaded..........................................."
echo
exit
fi


if [[ "$zelflux_setting_import" == "0" ]]; then

ip_confirm

while true
  do
    zel_id="$(whiptail --title "MULTITOOLBOX" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
    if [ $(printf "%s" "$zel_id" | wc -c) -eq "34" ] || [ $(printf "%s" "$zel_id" | wc -c) -eq "33" ]; then
      string_limit_check_mark "Zel ID is valid..........................................."
      break
    else
      string_limit_x_mark "Zel ID is not valid try again..........................................."
      sleep 4
   fi

 done

fi

touch /home/$USER/zelflux/config/userconfig.js
    cat << EOF > /home/$USER/zelflux/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '$WANIP',
        zelid: '$zel_id',
        testnet: false
      }
    }
EOF

if [[ -f /home/$USER/zelflux/config/userconfig.js ]]; then
string_limit_check_mark "Zelflux configuration successfull..........................................."
else
string_limit_x_mark "Zelflux installation failed, missing config file..........................................."
echo
exit
fi

 if pm2 -v > /dev/null 2>&1; then 
 
   rm restart_zelflux.sh > /dev/null 2>&1
   pm2 del zelflux > /dev/null 2>&1
   pm2 save > /dev/null 2>&1
   echo -e "${ARROW} ${CYAN}Starting ZelFlux....${NC}"
   echo
   pm2 start /home/$USER/zelflux/start.sh --name zelflux > /dev/null 2>&1
   pm2 save > /dev/null 2>&1
   pm2 list

 else
 
    pm2_install()
    if [[ "$PM2_INSTALL" == "1" ]]; then
      echo -e "${ARROW} ${CYAN}Starting ZelFlux....${NC}"
      echo
      pm2 list
    fi
 fi

}

function create_config() {
if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

echo -e "${GREEN}Module: Create zelnode installation config file${NC}"
echo -e "${YELLOW}================================================================${NC}"


if jq --version > /dev/null 2>&1; then
sleep 0.2
else
echo -e "${ARROW} ${YELLOW}Installing JQ....${NC}"
sudo apt  install jq -y > /dev/null 2>&1

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

skip_zelcash_config='0'
skip_bootstrap='0'

if [[ -d /home/$USER/.zelcash ]]; then

  if whiptail --yesno "Would you like import old settings from zelcash and zelflux?" 8 56; then
     import_settings='1'
     skip_zelcash_config='1'
     sleep 1
  else
     import_settings='0'
     sleep 1
  fi

  if whiptail --yesno "Would you like use exist zelcash chain?" 8 56; then
    use_old_chain='1'
    skip_bootstrap='1'
    sleep 1
  else
    use_old_chain='0'
    sleep 1
  fi


fi

if [[ "$skip_zelcash_config" == "1" ]]; then
prvkey=""
outpoint=""
index=""
zelid=""
else

prvkey=$(whiptail --inputbox "Enter your ZelNode Private Key from Zelcore/Zelmate" 8 43 3>&1 1>&2 2>&3)
sleep 1
outpoint=$(whiptail --inputbox "Enter your ZelNode Output TX ID from Zelcore/Zelmate" 8 43 3>&1 1>&2 2>&3)
sleep 1
index=$(whiptail --inputbox "Enter your ZelNode Output Index from Zelcore/Zelmate" 8 43 3>&1 1>&2 2>&3)
sleep 1
zelid=$(whiptail --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 43 3>&1 1>&2 2>&3)
sleep 1

fi

ssh_port=$(whiptail --inputbox "Enter port you are using for SSH (default 22)" 8 43 3>&1 1>&2 2>&3)
sleep 1


pettern='^[0-9]+$'
if [[ $ssh_port =~ $pettern ]] ; then
sleep 1
else
echo -e "${ARROW} ${CYAN}SSH port must be integer................[${X_MARK}${CYAN}]${NC}}"
echo
exit
fi


if whiptail --yesno "Would you like disable firewall diuring installation?" 8 56; then
firewall_disable='1'
sleep 1
else
firewall_disable='0'
sleep 1
fi


if [[ "$skip_bootstrap" == "0" ]]; then

if whiptail --yesno "Would you like use zelcash bootstrap from script source?" 8 56; then
bootstrap_url='http://77.55.218.93/zel-bootstrap.zip'
sleep 1
else
bootstrap_url=$(whiptail --inputbox "Enter your zelcash bootstrap URL" 8 43 3>&1 1>&2 2>&3)
sleep 1
fi

if whiptail --yesno "Would you like keep bootstrap archive file localy?" 8 56; then
bootstrap_zip_del='1'
sleep 1
else
bootstrap_zip_del='0'
sleep 1
fi
fi

if whiptail --yesno "Would you like create swapfile?" 8 56; then
swapon='1'
sleep 1
else
swapon='0'
sleep 1
fi


if whiptail --yesno "Would you like use mongod bootstrap file?" 8 56; then
mongo_bootstrap='1'
sleep 1
else
mongo_bootstrap='0'
sleep 1
fi


if whiptail --yesno "Would you like install zelnode watchdog?" 8 56; then
watchdog='1'
sleep 1
else
watchdog='0'
sleep 1
fi

rm /home/$USER/install_conf.json > /dev/null 2>&1
sudo touch /home/$USER/install_conf.json
sudo chown $USER:$USER /home/$USER/install_conf.json
    cat << EOF > /home/$USER/install_conf.json
{
  "import_settings": "${import_settings}",
  "prvkey": "${prvkey}",
  "outpoint": "${outpoint}",
  "index": "${index}",
  "zelid": "${zelid}",
  "ssh_port": "${ssh_port}",
  "firewall_disable": "${firewall_disable}",
  "bootstrap_url": "${bootstrap_url}",
  "bootstrap_zip_del": "${bootstrap_zip_del}",
  "swapon": "${swapon}",
  "mongo_bootstrap": "${mongo_bootstrap}",
  "use_old_chain": "${use_old_chain}",
  "watchdog": "${watchdog}"
}
EOF
config_file
echo



}

function pm2_install(){

    echo -e "${ARROW} ${CYAN}PM2 installing...${NC}"
    npm install pm2@latest -g > /dev/null 2>&1
    
    if pm2 -v > /dev/null 2>&1
    then
        rm restart_zelflux.sh > /dev/null 2>&1
     	echo -e "${ARROW} ${CYAN}Configuring PM2...${NC}"
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
	string_limit_check_mark "PM2 v$(pm2 -v) installed....................................................." "PM2 ${GREEN}v$(pm2 -v)${CYAN} installed....................................................." 
  	PM2_INSTALL="1"

    else

	 string_limit_x_mark "PM2 was not installed....................................................."
	 echo
    fi 

}


function install_watchdog() {

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

echo -e "${GREEN}Module: Install watchdog for zelnode${NC}"
echo -e "${YELLOW}================================================================${NC}"

if ! pm2 -v > /dev/null 2>&1
then
pm2_install
 if [[ "$PM2_INSTALL" == "0" ]]; then
   exit
 fi
echo -e ""
fi

echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
pm2 del watchdog  > /dev/null 2>&1
pm2 save  > /dev/null 2>&1
sudo rm -rf /home/$USER/watchdog  > /dev/null 2>&1

echo -e "${ARROW} ${CYAN}Downloading...${NC}"
cd && git clone https://github.com/XK4MiLX/watchdog.git > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Installing git hooks....${NC}"
wget https://raw.githubusercontent.com/XK4MiLX/zelnode/master/post-merge > /dev/null 2>&1
mv post-merge /home/$USER/watchdog/.git/hooks/post-merge
sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge
echo -e "${ARROW} ${CYAN}Installing watchdog module....${NC}"
cd watchdog && npm install > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Starting watchdog...${NC}"
pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 10 > /dev/null 2>&1 
pm2 save > /dev/null 2>&1
if [[ -f /home/$USER/watchdog/watchdog.js ]]
then
current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
#echo -e "${ARROW} ${CYAN}Watchdog ${GREEN}v$current_ver${CYAN} installed successful.${NC}"
string_limit_check_mark "Watchdog v$current_ver installed..........................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed..........................................."
else
#echo -e "${ARROW} ${CYAN}Watchdog installion failed.${NC}"
string_limit_x_mark "Watchdog was not installed..........................................."
fi
echo
}

function zelcash_bootstrap() {

echo -e "${GREEN}Module: Restore Zelcash blockchain form bootstrap${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

echo -e "${ARROW} ${CYAN}Stopping zelcash service${NC}"
sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 2
sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1

if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate ~/$CONFIG_DIR/determ_zelnodes
fi


if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
echo -e "${ARROW} ${CYAN}Local bootstrap file detected...${NC}"
echo -e "${ARROW} ${CYAN}Checking if zip file is corrupted...${NC}"


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
echo -e "${ARROW} ${CYAN}Unpacking wallet bootstrap please be patient...${NC}"
unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
else


CHOICE=$(
whiptail --title "ZELNODE INSTALLATION" --menu "Choose a method how to get bootstrap file" 10 47 2  \
        "1)" "Download from source build in script" \
        "2)" "Download from own source" 3>&2 2>&1 1>&3
)


case $CHOICE in
	"1)")   
		echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
       		wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
       		echo -e "${ARROW} ${CYAN}Unpacking wallet bootstrap please be patient...${NC}"
        	unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1


	;;
	"2)")   
  		BOOTSTRAP_ZIP="$(whiptail --title "MULTITOOLBOX" --inputbox "Enter your URL" 8 72 3>&1 1>&2 2>&3)"
		echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
		wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
		echo -e "${ARROW} ${CYAN}Unpacking wallet bootstrap please be patient...${NC}"
		unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
	;;
esac

fi

if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
    rm -rf $BOOTSTRAP_ZIPFILE
fi

echo -e "${ARROW} ${CYAN}Starting zelcash service${NC}"
sudo systemctl start zelcash > /dev/null 2>&1 && sleep 2
echo

}

function mongodb_bootstrap(){

echo -e "${GREEN}Module: Restore Mongodb datatable from bootstrap${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

sudo rm /home/$USER/fluxdb_dump.tar.gz  > /dev/null 2>&1
sudo rm /home/$USER/mongod_bootstrap.tar.gz  > /dev/null 2>&1

if ! pm2 -v > /dev/null 2>&1; then
 
   pm2_install 

   if [[ "$PM2_INSTALL" == "0" ]]; then
    exit
   fi

fi

WANIP=$(wget http://ipecho.net/plain -O - -q)
DB_HIGHT=590910
BLOCKHIGHT=$(wget -nv -qO - http://"$WANIP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
echo -e "${ARROW} ${CYAN}IP: ${RED}$WANIP${NC}"
echo -e "${ARROW} ${CYAN}Node block hight: ${GREEN}$BLOCKHIGHT${NC}"
echo -e "${ARROW} ${CYAN}Bootstrap block hight: ${GREEN}$DB_HIGHT${NC}"
echo -e ""

if [[ "$BLOCKHIGHT" != "" ]]; then

if [[ "$BLOCKHIGHT" -gt "0" && "$BLOCKHIGHT" -lt "$DB_HIGHT" ]]
then
echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$BOOTSTRAP_URL_MONGOD${NC}"
wget $BOOTSTRAP_URL_MONGOD -q --show-progress 
echo -e "${ARROW} ${CYAN}Unpacking...${NC}"
tar xvf $BOOTSTRAP_ZIPFILE_MONGOD -C /home/$USER > /dev/null 2>&1 && sleep 1
echo -e "${ARROW} ${CYAN}Stoping zelflux...${NC}"
pm2 stop zelflux > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Importing mongodb datatable...${NC}"
mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
sudo rm -rf /home/$USER/dump > /dev/null 2>&1 && sleep 1
sudo rm -rf $BOOTSTRAP_ZIPFILE_MONGOD > /dev/null 2>&1  && sleep 1
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
#echo -e "${ARROW} ${CYAN}Mongo bootstrap installed successful.${NC}"
string_limit_check_mark "Mongo bootstrap installed successful.................................."
echo -e ""
else
#echo -e "${ARROW} ${CYAN}Mongo bootstrap installation failed.${NC}"
string_limit_x_mark "Mongo bootstrap installation failed.................................."
echo -e ""
fi
else
echo -e "${ARROW} ${CYAN}Current Node block hight ${RED}$BLOCKHIGHT${CYAN} > Bootstrap block hight ${RED}$DB_HIGHT${CYAN}. Datatable is out of date.${NC}"
echo -e ""
fi

else
string_limit_x_mark "Local Explorer not responding........................................"
echo -e ""
fi
}

function install_kernel(){


echo -e "${GREEN}Module: Install Linux Kernel 5.X for Ubuntu 18.04${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

echo -e "${NC}"
echo -e "${YELLOW}Installing Linux Kernel 5.x${NC}"
sudo apt-get install --install-recommends linux-generic-hwe-18.04 -y
read -p "Would you like to reboot pc Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
sudo reboot -n
fi

}

function analyzer_and_fixer(){

echo -e "${GREEN}Module: ZelNode analyzer and fixer${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi
echo -e "${NC}"
bash -i <(curl -s https://raw.githubusercontent.com/XK4MiLX/zelnode/master/nodeanalizerandfixer.sh)

}

 function insertAfter
{
   local file="$1" line="$2" newText="$3"
   sudo sed -i -e "/$line/a"$'\\\n'"$newText"$'\n' "$file"
}

function fix_lxc_config(){

echo -e "${GREEN}Module: Fix your lxc.conf file on host${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e ""

continer_name="$(whiptail --title "ZELNODE MULTITOOLBOX $dversion" --inputbox "Enter your LXC continer name" 8 72 3>&1 1>&2 2>&3)"
echo -e "${YELLOW}================================================================${NC}"
if [[ $(grep -w "features: mount=fuse,nesting=1" /etc/pve/lxc/$continer_name.conf) && $(grep -w "lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0" /etc/pve/lxc/$continer_name.conf) ]] 
then
echo -e "${CHECK_MARK} ${CYAN}LXC configurate file $continer_name.conf [OK]${NC}"
fi

insertAfter "/etc/pve/lxc/$continer_name.conf" "cores" "features: mount=fuse,nesting=1"
sudo bash -c "echo 'lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0' >>/etc/pve/lxc/$continer_name.conf"
sudo bash -c "echo 'lxc.cap.drop:' >>/etc/pve/lxc/$continer_name.conf"
sudo bash -c "echo 'lxc.cap.drop: mac_override sys_time sys_module sys_rawio' >>/etc/pve/lxc/$continer_name.conf"
sudo bash -c "echo 'lxc.apparmor.profile: unconfined' >>/etc/pve/lxc/$continer_name.conf"
sudo bash -c "echo 'lxc.cgroup.devices.allow: a' >>/etc/pve/lxc/$continer_name.conf"
sudo bash -c "echo 'lxc.cap.drop:' >>/etc/pve/lxc/$continer_name.conf"   

if [[ $(grep -w "features: mount=fuse,nesting=1" /etc/pve/lxc/$continer_name.conf) && $(grep -w "lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0" /etc/pve/lxc/$continer_name.conf) ]] 
then
echo -e "${CHECK_MARK} ${CYAN}LXC configurate file $continer_name.conf [FiXED]${NC}"
else
echo -e "${X_MARK} ${CYAN}LXC configurate file $continer_name.conf fix [Failed]${NC}"
fi  

}

function install_zelnode(){

echo -e "${GREEN}Module: Install ZelNode${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

if sudo docker run hello-world > /dev/null 2>&1
then
echo -e "${NC}"
else
echo -e "${WORNING}${CYAN}Docker is not installed.${NC}"
echo -e "${WORNING}${CYAN}First install docker from root accont.${NC}"
exit
fi



#bash -i <(curl -s https://raw.githubusercontent.com/XK4MiLX/zelnode/master/install.sh)
bash -i <(curl -s https://raw.githubusercontent.com/XK4MiLX/zelnode/master/install_pro.sh)


}

function install_docker(){

echo -e "${GREEN}Module: Install Docker${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" != "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the root accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

echo -e "${NC}"
usernew="$(whiptail --title "MULTITOOLBOX $dversion" --inputbox "Enter your username" 8 72 3>&1 1>&2 2>&3)"
echo -e "${ARROW} ${YELLOW}Creating new user...${NC}"
adduser --gecos "" "$usernew"
usermod -aG sudo "$usernew"
echo -e "${NC}"
echo -e "${ARROW} ${YELLOW}Update and upgrade system...${NC}"
apt update -y > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1
echo -e "{ARROW} ${YELLOW}Installing docker...${NC}"

if [[ $(lsb_release -d) = *Debian* ]]
then

sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
sudo apt-get update -y  > /dev/null 2>&1
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y > /dev/null 2>&1
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - > /dev/null 2>&1
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable" > /dev/null 2>&1
sudo apt-get update -y  > /dev/null 2>&1
sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1  

else

sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y > /dev/null 2>&1 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" > /dev/null 2>&1
sudo apt-get update -y > /dev/null 2>&1 
sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1  

fi

# echo -e "${YELLOW}Creating docker group..${NC}"
# groupadd docker
echo -e "${NC}"
echo -e "${ARROW} ${YELLOW}Adding $usernew to docker group...${NC}"
adduser "$usernew" docker > /dev/null 2>&1
echo -e "${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}Running through some checks...${NC}"
echo -e "${YELLOW}=====================================================${NC}"

if sudo docker run hello-world > /dev/null 2>&1
then
	echo -e "${CHECK_MARK} ${CYAN}Docker is installed${NC}"
else
	echo -e "${X_MARK} ${CYAN}Docker did not installed${NC}"
fi

if [[ $(getent group docker | grep "$usernew") ]] 
then
	echo -e "${CHECK_MARK} ${CYAN}User $usernew is member of 'docker'${NC}"
else
	echo -e "${X_MARK} ${CYAN}User $usernew is not member of 'docker'${NC}"
fi

echo -e "${YELLOW}=====================================================${NC}"
echo -e "${NC}"
read -p "Would you like switch to user accont Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
su - $usernew
fi

}

if ! figlet -v > /dev/null 2>&1
then
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y figlet > /dev/null 2>&1
fi

clear
sleep 1
echo -e "${BLUE}"
figlet -f slant "Multitoolbox"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${GREEN}Version: $dversion${NC}"
echo -e "${GREEN}OS: Ubuntu 16.04/18.04/20.04, Debian 9.12/10.3${NC}"
echo -e "${GREEN}Created by: XK4MiLX from Zel's team${NC}"
echo -e "${GREEN}Special thanks to dk808, CryptoWrench && jriggs28${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${CYAN}1 - Install Docker${NC}"
echo -e "${CYAN}2 - Install ZelNode${NC}"
echo -e "${CYAN}3 - ZelNode analyzer and fixer${NC}"
echo -e "${CYAN}4 - Install watchdog for ZelNode${NC}"
echo -e "${CYAN}5 - Restore Mongodb datatable from bootstrap${NC}"
echo -e "${CYAN}6 - Restore Zelcash blockchain from bootstrap${NC}"
echo -e "${CYAN}7 - Create ZelNode installation config file${NC}"
echo -e "${CYAN}8 - Re-install ZelFlux${NC}"
#echo -e "${CYAN}7 - Fix your lxc.conf file on host${NC}"
#echo -e "${CYAN}8 - Install Linux Kernel 5.X for Ubuntu 18.04${NC}"
echo -e "${YELLOW}================================================================${NC}"

read -p "Pick an option: " -n 1 -r

  case "$REPLY" in

 1)  
    clear
    sleep 1
    install_docker
 ;;
 2) 
    clear
    sleep 1
    install_zelnode
 ;;
 3)     
    clear
    sleep 1
    analyzer_and_fixer
 ;;
  4)  
    clear
    sleep 1
    install_watchdog   
 ;;
 
 5)  
    clear
    sleep 1
    mongodb_bootstrap     
 ;;
  6)  
    clear
    sleep 1
    zelcash_bootstrap     
 ;; 
  7)
    clear
    sleep 1
    create_config
 ;;
   8)
    clear
    sleep 1
    install_flux
 ;;
 #7)
   # clear
  #  sleep 1
   # fix_lxc_config
# ;;
 
# 8)
    #clear
   # sleep 1
    #install_kernel
# ;;

    esac
