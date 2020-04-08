#!/bin/bash

#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
GREEN='\033[1;32m'
NC='\033[0m'
CYAN='\033[1;36m'
#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9D\x8C${NC}"
dversion="v2.5"

clear
sleep 1
echo -e "${YELLOW}================================================================${NC}"
echo -e "${GREEN}ZELNODE MULTITOOLBOX $dversion FOR UBUNTU BY XK4MiLX${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${YELLOW}1 - Install Docker${NC}"
echo -e "${YELLOW}2 - Install ZelNode${NC}"
echo -e "${YELLOW}3 - ZelNode analyzer and fixer${NC}"
echo -e "${YELLOW}4 - Install Mongodb datatable && PM2${NC}"
echo -e "${YELLOW}5 - Fix your lxc.conf file on host${NC}"
echo -e "${YELLOW}6 - Install Linux Kernel 5.X for Ubuntu 18.04${NC}"
echo -e "${YELLOW}================================================================${NC}"


read -p "Pick an option: " -n 1 -r
echo -e "${NC}"
#prompt="Pick an option:"
#options=("Install docker on VPS/Inside LXC Continer" "Fix your lxc.conf file on host" "Install zelnode" "Zelnode analizer and fixer")
#PS3="$prompt "
#select opt in "${options[@]}" "Quit"; do 

    case "$REPLY" in

    1 ) 
    
    if [[ "$USER" != "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the root accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

usernew="$(whiptail --title "ZELNODE MULTITOOLBOX $dversion" --inputbox "Enter your username" 8 72 3>&1 1>&2 2>&3)"
echo -e "${YELLOW}Creating new user...${NC}"
adduser "$usernew"
usermod -aG sudo "$usernew"
echo -e "${NC}"
echo -e "${YELLOW}Update and upgrade system...${NC}"
apt update && apt upgrade -y
echo -e "${YELLOW}Installing docker...${NC}"
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


;;
    5 ) 
    
 function insertAfter
{
   local file="$1" line="$2" newText="$3"
   sudo sed -i -e "/$line/a"$'\\\n'"$newText"$'\n' "$file"
}

continer_name="$(whiptail --title "ZELNODE MULTITOOLBOX $dversion" --inputbox "Enter your LXC continer name" 8 72 3>&1 1>&2 2>&3)"
echo -e "${YELLOW}================================================================${NC}"
if [[ $(grep -w "features: mount=fuse,nesting=1" /etc/pve/lxc/$continer_name.conf) && $(grep -w "lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0" /etc/pve/lxc/$continer_name.conf) ]] 
then
echo -e "${CHECK_MARK} ${CYAN}LXC configurate file $continer_name.conf [OK]${NC}"
exit
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
exit
else
echo -e "${X_MARK} ${CYAN}LXC configurate file $continer_name.conf fix [Failed]${NC}"
exit
fi    
    
    
 ;;
 2 ) 
 if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi
bash -i <(curl -s https://raw.githubusercontent.com/XK4MiLX/zelnode/master/install.sh)
 exit
 ;;
 
  3 ) 
 if [[ "$USER" == "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi
bash -i <(curl -s https://raw.githubusercontent.com/XK4MiLX/zelnode/master/nodeanalizerandfixer.sh)
 exit
 ;;
 
 6)
echo -e ""
echo -e "${YELLOW}Installing Linux Kernel 5.x...${NC}"
sudo apt-get install --install-recommends linux-generic-hwe-18.04 -y
read -p "Would you like to reboot pc Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
sudo reboot -n
fi
 
 ;;
  4)
clear
sleep 2
echo -e "${YELLOW}================================================================${NC}"
echo -e "${GREEN}Install Mongodb datatable && PM2 ${NC}"
echo -e "${GREEN}Special thx for CryptoWrench :) ${NC}"
echo -e "${YELLOW}================================================================${NC}"

DB_HIGHT=572500
IP=$(wget http://ipecho.net/plain -O - -q)
BLOCKHIGHT=$(wget -nv -qO - http://"$IP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
echo "IP: $IP"
echo "BLOCK HIGHT: $BLOCKHIGHT"

if [[ $BLOCKHIGHT > 0 && $BLOCKHIGHT < $DB_HIGHT ]]
then

if ! pm2 -v > /dev/null 2>&1; then 
    tmux kill-server 
    echo -e "${YELLOW}Installing PM2...${NC}"
    npm i -g pm2 > /dev/null 2>&1
    echo -e "${YELLOW}Configuring PM2...${NC}"
    cmd=$(pm2 startup systemd -u $USER | grep sudo)
    sudo bash -c "$cmd"
    sudo chmod +x /home/$USER/zelflux/start.sh
    pm2 start ~/zelflux/start.sh --name zelflux
    pm2 save
    pm2 install pm2-logrotate
    pm2 set pm2-logrotate:max_size 5K >/dev/null
    pm2 set pm2-logrotate:retain 6 >/dev/null
    pm2 set pm2-logrotate:compress true >/dev/null
    pm2 set pm2-logrotate:workerInterval 3600 >/dev/null
    pm2 set pm2-logrotate:rotateInterval 0 12 * * 0 >/dev/null  
fi

echo -e "${YELLOW}Downloading db for mongo...${NC}"
wget http://77.55.218.93/fluxdb_dump.tar.gz
echo -e "${YELLOW}Unpacking...${NC}"
tar xvf fluxdb_dump.tar.gz -C /home/$USER && sleep 1
echo -e "${YELLOW}Stoping zelflux...${NC}"
pm2 stop zelflux > /dev/null 2>&1
echo -e "${YELLOW}Importing mongo db...${NC}"
mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop
echo -e "${YELLOW}Starting Zelflux...${NC}"
pm2 start zelflux > /dev/null 2>&1
echo -e "${YELLOW}Cleaning...${NC}"
sudo rm -rf /home/$USER/dump && sleep 1
sudo rm -rf fluxdb_dump.tar.gz && sleep 1

else

echo -e "${X_MARK} ${CYAN}Block Hight $BLOCKHIGHT > $DB_HIGHT datatable is out of date ${NC}"
echo -e ""

fi





;;
    # $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    # *) echo -e "${X_MARK} ${CYAN}Invalid option. Try another one.${NC}";continue;;

    esac
