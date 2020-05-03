#!/bin/bash

BOOTSTRAP_ZIP='http://77.55.218.93/zel-bootstrap.zip'
BOOTSTRAP_ZIPFILE='zel-bootstrap.zip'
CONFIG_DIR='.zelcash'
CONFIG_FILE='zelcash.conf'

#color codes
PINK='\033[1;95m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
GREEN='\033[1;32m'
NC='\033[0m'
CYAN='\033[1;36m'
#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9D\x8C${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
dversion="v3.7"
#dialog color
export NEWT_COLORS='
title=black,
'

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
	 echo -e "${NC}"
         DB_HIGHT=572200
         IP=$(wget http://ipecho.net/plain -O - -q)
         BLOCKHIGHT=$(wget -nv -qO - http://"$IP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
         echo -e "${PIN} ${CYAN}IP: ${PINK}$IP"
         echo -e "${PIN} ${CYAN}Node block hight: ${GREEN}$BLOCKHIGHT${NC}"
         echo -e "${PIN} ${CYAN}Bootstrap block hight: ${GREEN}$DB_HIGHT${NC}"
         echo -e ""

      if [[ "$BLOCKHIGHT" -gt "0" && "$BLOCKHIGHT" -lt "$DB_HIGHT" ]]
       then
       
        echo -e "${YELLOW}Downloading db for mongo...${NC}"
        wget http://77.55.218.93/fluxdb_dump.tar.gz
        echo -e "${YELLOW}Unpacking...${NC}"
        tar xvf fluxdb_dump.tar.gz -C /home/$USER && sleep 1
        echo -e "${YELLOW}Stoping zelflux...${NC}"
        pm2 stop zelflux > /dev/null 2>&1
        echo -e "${YELLOW}Importing mongo db...${NC}"
        mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop
        echo -e "${YELLOW}Cleaning...${NC}"
        sudo rm -rf /home/$USER/dump && sleep 1
        sudo rm -rf fluxdb_dump.tar.gz && sleep 1
	pm2 start zelflux > /dev/null 2>&1

      else

      echo -e "${X_MARK} ${CYAN}Current Node block hight ${RED}$BLOCKHIGHT${CYAN} > Bootstrap block hight ${RED}$DB_HIGHT${CYAN}. Datatable is out of date.${NC}"
      echo -e ""

     fi
	  
    else
   	 echo -e "${ARROW} ${CYAN}PM2 was not installed${NC}"
	 string_limit_x_mark "PM2 was not installed................................."
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
echo -e "${PIN} ${YELLOW}You need install first pm2...${NC}"
echo -e ""
else
echo -e "${YELLOW}Cleaning...${NC}"
pm2 del watchdog  > /dev/null 2>&1
pm2 save  > /dev/null 2>&1
sudo rm -rf /home/$USER/watchdog  > /dev/null 2>&1
echo -e "${YELLOW}Downloading...${NC}"
cd && git clone https://github.com/XK4MiLX/watchdog.git
echo -e "${YELLOW}Installing module auto-update....${NC}"
wget https://raw.githubusercontent.com/XK4MiLX/zelnode/master/post-merge
mv post-merge /home/$USER/watchdog/.git/hooks/post-merge 
sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge 
cd watchdog && npm install
pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 10
pm2 save
fi

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

echo -e "${NC}"
if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
echo -e "${YELLOW}Stopping zelcash...${NC}"
sudo systemctl stop zelcash
sudo fuser -k 16125/tcp > /dev/null 2>&1
echo -e "${YELLOW}Cleaning...${NC}"
rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate ~/$CONFIG_DIR/database ~/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/peers.dat	
fi 

if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]
then
echo -e "${YELLOW}Local bootstrap file detected...${NC}"
echo -e "${YELLOW}Installing wallet bootstrap please be patient...${NC}"
unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR
else

echo -e ""
echo -e "${GREEN}Choose a method how to get bootstrap file${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${NC}1 - Download from source build in script${NC}"
echo -e "${NC}2 - Download from own source${NC}"
echo -e "${YELLOW}================================================================${NC}"
read -p "Pick an option: " -n 1 -r
echo -e "${NC}"
while true

do
    case "$REPLY" in

    1 ) 

	echo -e "${YELLOW}Downloading File: $BOOTSTRAP_ZIP ${NC}"
	wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP
	echo -e "${YELLOW}Installing wallet bootstrap please be patient...${NC}"
	unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR
	break
;;
    2 )
    
	BOOTSTRAP_ZIP="$(whiptail --title "Restore Zelcash block chain form bootstrap" --inputbox "Enter your URL" 8 72 3>&1 1>&2 2>&3)"
	echo -e "${YELLOW}Downloading File: $BOOTSTRAP_ZIP ${NC}"
	wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP
	echo -e "${YELLOW}Installing wallet bootstrap please be patient...${NC}"
	unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR
	break
;;

     *) echo "Invalid option $REPLY try again...";;

    esac

done

fi
echo -e "${NC}"
read -p "Would you like remove bootstrap file Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
rm -rf $BOOTSTRAP_ZIPFILE
fi
read -p "Would you like to start zelcash daemon Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo -e "${YELLOW}Starting zelcash...${NC}"
zelcashd -daemon
fi


}

function mongodb_bootstrap(){

echo -e "${GREEN}Module: Restore Mongodb datatable from bootstrap && Install PM2${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

rm restart_zelflux.sh > /dev/null 2>&1
PM2_INTALL="0"
DB_INTALL="0"
sudo rm /home/$USER/fluxdb_dump.tar.gz  > /dev/null 2>&1

if ! pm2 -v > /dev/null 2>&1; then 
  pm2_install  
else
##echo -e "${YELLOW}PM2 installation skipped...${NC}"

echo -e "${NC}"
DB_HIGHT=572200
IP=$(wget http://ipecho.net/plain -O - -q)
BLOCKHIGHT=$(wget -nv -qO - http://"$IP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
echo -e "${PIN} ${CYAN}IP: ${PINK}$IP"
echo -e "${PIN} ${CYAN}Node block hight: ${GREEN}$BLOCKHIGHT${NC}"
echo -e "${PIN} ${CYAN}Bootstrap block hight: ${GREEN}$DB_HIGHT${NC}"
echo -e ""

if [[ "$BLOCKHIGHT" -gt "0" && "$BLOCKHIGHT" -lt "$DB_HIGHT" ]]
    then
    DB_INTALL="1"
    echo -e "${YELLOW}Downloading db for mongo...${NC}"
    wget http://77.55.218.93/fluxdb_dump.tar.gz
    echo -e "${YELLOW}Unpacking...${NC}"
    tar xvf fluxdb_dump.tar.gz -C /home/$USER && sleep 1
    echo -e "${YELLOW}Stoping zelflux...${NC}"
    pm2 stop zelflux > /dev/null 2>&1
    echo -e "${YELLOW}Importing mongo db...${NC}"
    mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop
    echo -e "${YELLOW}Cleaning...${NC}"
    sudo rm -rf /home/$USER/dump && sleep 1
    sudo rm -rf fluxdb_dump.tar.gz && sleep 1
    echo -e "${YELLOW}Starting Zelflux...${NC}"
    pm2 start zelflux > /dev/null 2>&1
    
    else

    echo -e "${X_MARK} ${CYAN}Current Node block hight ${RED}$BLOCKHIGHT${CYAN} > Bootstrap block hight ${RED}$DB_HIGHT${CYAN}. Datatable is out of date.${NC}"
    echo -e ""

   fi


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
usernew="$(whiptail --title "ZELNODE MULTITOOLBOX $dversion" --inputbox "Enter your username" 8 72 3>&1 1>&2 2>&3)"
echo -e "${YELLOW}Creating new user...${NC}"
adduser "$usernew"
usermod -aG sudo "$usernew"
echo -e "${NC}"
echo -e "${YELLOW}Update and upgrade system...${NC}"
apt update && apt upgrade -y
echo -e "${YELLOW}Installing docker...${NC}"

if [[ $(lsb_release -d) = *Debian* ]]
then

sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

else

sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

fi

# echo -e "${YELLOW}Creating docker group..${NC}"
# groupadd docker
echo -e "${NC}"
echo -e "${YELLOW}Adding $usernew to docker group...${NC}"
adduser "$usernew" docker
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
read -p "Would you like to reboot pc Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
sudo reboot -n
fi
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
echo -e "${GREEN}OS: Ubuntu 16.04/18.04, Debian 9.12/10.3${NC}"
echo -e "${GREEN}Created by: XK4MiLX from Zel's team${NC}"
echo -e "${GREEN}Special thanks to dk808, CryptoWrench && jriggs28${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${CYAN}1 - Install Docker${NC}"
echo -e "${CYAN}2 - Install ZelNode${NC}"
echo -e "${CYAN}3 - ZelNode analyzer and fixer${NC}"
echo -e "${CYAN}4 - Install watchdog for zelnode${NC}"
echo -e "${CYAN}5 - Restore Mongodb datatable from bootstrap && Install PM2${NC}"
echo -e "${CYAN}6 - Restore Zelcash blockchain from bootstrap${NC}"
echo -e "${CYAN}7 - Fix your lxc.conf file on host${NC}"
echo -e "${CYAN}8 - Install Linux Kernel 5.X for Ubuntu 18.04${NC}"
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
    fix_lxc_config
 ;;
 
 8)
    clear
    sleep 1
    install_kernel
 ;;

    esac
