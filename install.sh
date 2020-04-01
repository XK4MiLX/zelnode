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
BOOTSTRAP_ZIP='http://95.217.155.210:16127/zelapps/zelshare/getfile/zel-bootstrap2.zip'
BOOTSTRAP_ZIPFILE='zel-bootstrap2.zip'
CONFIG_DIR='.zelcash'
CONFIG_FILE='zelcash.conf'
RPCPORT='16124'
PORT='16125'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
USERNAME="$(whoami)"

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
X_MARK="${RED}\xE2\x9D\x8C${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"

#end of required details
#

#Suppressing password prompts for this user so zelnode can operate
clear
sleep 5
sudo echo -e "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo
echo -e "${YELLOW}====================================================================="
echo -e " Zelnode & Zelflux Install"
echo -e "=====================================================================${NC}"
echo -e "${CYAN}MAR 2020, created by dk808 from Zel's team and AltTank Army."
echo -e "Special thanks to Goose-Tech, Skyslayer, & Packetflow."
echo -e "Zelnode setup starting, press [CTRL+C] to cancel.${NC}"
sleep 5
if [ "$USERNAME" = "root" ]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}root${CYAN}, please switch to the username you just created.${NC}"
    sleep 4
    exit
fi

#functions
function wipe_clean() {
    echo -e "${YELLOW}Removing any instances of ${COIN_NAME^}${NC}"
    $COIN_CLI stop > /dev/null 2>&1 && sleep 2
    sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
    sudo killall $COIN_DAEMON > /dev/null 2>&1
    sudo rm ${COIN_PATH}/zel* > /dev/null 2>&1 && sleep 1
    sudo rm /usr/bin/${COIN_NAME}* > /dev/null 2>&1 && sleep 1
    sudo apt-get purge zelcash zelbench -y > /dev/null 2>&1 && sleep 1
    sudo rm /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1 && sleep 1
    sudo rm -rf zelflux && sleep 1
    sudo rm -rf ~/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/database ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate && sleep 1
    sudo rm -rf .zelbenchmark && sleep 1
    rm -rf $BOOTSTRAP_ZIPFILE && sleep 1
    rm $UPDATE_FILE > /dev/null 2>&1
    rm restart_zelflux.sh > /dev/null 2>&1
    rm zelnodeupdate.sh > /dev/null 2>&1
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

function ssh_port() {
    echo -e "${YELLOW}Detecting SSH port being used...${NC}" && sleep 1
    SSHPORT=$(grep -w Port /etc/ssh/sshd_config | sed -e 's/.*Port //')
    if ! whiptail --yesno "Detected you are using $SSHPORT for SSH is this correct?" 8 56; then
        SSHPORT=$(whiptail --inputbox "Please enter port you are using for SSH" 8 43 3>&1 1>&2 2>&3)
        echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    else
        echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    fi
}

function ip_confirm() {
    echo -e "${YELLOW}Detecting IP address being used...${NC}" && sleep 1
    WANIP=$(wget http://ipecho.net/plain -O - -q)
    if ! whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60; then
    	WANIP=$(whiptail --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
    fi
}

function create_swap() {
    echo -e "${YELLOW}Creating swap if none detected...${NC}" && sleep 1
    MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    gb=$(awk "BEGIN {print $MEM/1048576}")
    GB=$(echo "$gb" | awk '{printf("%d\n",$1 + 0.5)}')
    if [ "$GB" -lt 2 ]; then
    	(( swapsize=GB*2 ))
	swap="$swapsize"G
	echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -ge 2 ]] && [[ $GB -le 16 ]]; then
    	swap=4G
	echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -gt 16 ]] && [[ $GB -lt 32 ]]; then
    	swap=2G
	echo -e "${YELLOW}Swap set at $swap...${NC}"
    fi
    if ! grep -q "swapfile" /etc/fstab; then
    	if whiptail --yesno "No swapfile detected would you like to create one?" 8 54; then
	    sudo fallocate -l "$swap" /swapfile
	    sudo chmod 600 /swapfile
	    sudo mkswap /swapfile
	    sudo swapon /swapfile
	    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
	    echo -e "${YELLOW}Created ${SEA}${swap}${YELLOW} swapfile${NC}"
	else
	    echo -e "${YELLOW}You have opted out on creating a swapfile so no swap created...${NC}"
	fi
    fi
    sleep 2
}

function install_packages() {
    echo -e "${YELLOW}Installing Packages...${NC}"
    if [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
    	sudo apt-get install dirmngr apt-transport-https -y
    fi
    sudo apt-get install software-properties-common -y
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install nano htop pwgen ufw figlet tmux jq -y
    sudo apt-get install build-essential libtool pkg-config -y
    sudo apt-get install libc6-dev m4 g++-multilib -y
    sudo apt-get install autoconf ncurses-dev unzip git python python-zmq -y
    sudo apt-get install wget curl bsdmainutils automake fail2ban -y
    sudo apt-get remove sysbench -y
    echo -e "${YELLOW}Packages complete...${NC}"
}

function create_conf() {
    echo -e "${YELLOW}Creating Conf File...${NC}"
    if [ -f ~/$CONFIG_DIR/$CONFIG_FILE ]; then
    	echo -e "${CYAN}Existing conf file found backing up to $COIN_NAME.old ...${NC}"
	mv ~/$CONFIG_DIR/$CONFIG_FILE ~/$CONFIG_DIR/$COIN_NAME.old;
    fi
    RPCUSER=$(pwgen -1 8 -n)
    PASSWORD=$(pwgen -1 20 -n)
    zelnodeprivkey=$(whiptail --title "ZELNODE PRIVKEY" --inputbox "Enter your Zelnode Privkey generated by your Zelcore/Zelmate wallet" 8 72 3>&1 1>&2 2>&3)
    zelnodeoutpoint=$(whiptail --title "ZELNODE OUTPOINT" --inputbox "Enter your Zelnode collateral txid" 8 72 3>&1 1>&2 2>&3)
    zelnodeindex=$(whiptail --title "ZELNODE INDEX" --inputbox "Enter your Zelnode collateral output index usually a 0/1" 8 60 3>&1 1>&2 2>&3)
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
bind=$WANIP
addnode=explorer.zel.cash
addnode=explorer2.zel.cash
addnode=explorer.zel.zelcore.io
addnode=blockbook.zel.network
maxconnections=256
EOF
    sleep 2
}

function zel_package() {
    sudo apt-get update
    sudo apt install zelcash zelbench -y
    sudo chmod 755 $COIN_PATH/${COIN_NAME}*
}

function install_zel() {
    echo -e "${YELLOW}Installing Zel apt packages...${NC}"
    echo 'deb https://apt.zel.cash/ all main' | sudo tee /etc/apt/sources.list.d/zelcash.list
    sleep 1
    if [ ! -f /etc/apt/sources.list.d/zelcash.list ]; then
    	echo 'deb https://zelcash.github.io/aptrepo/ all main' | sudo tee --append /etc/apt/sources.list.d/zelcash.list
    fi
    gpg --keyserver keyserver.ubuntu.com --recv 4B69CA27A986265D
    gpg --export 4B69CA27A986265D | sudo apt-key add -
    zel_package && sleep 2
    if ! gpg --list-keys Zel > /dev/null; then
    	echo -e "${YELLOW}First attempt to retrieve keys failed will try a different keyserver.${NC}"
	gpg --keyserver na.pool.sks-keyservers.net --recv 4B69CA27A986265D
	gpg --export 4B69CA27A986265D | sudo apt-key add -
	zel_package && sleep 2
	if ! gpg --list-keys Zel > /dev/null; then
	    echo -e "${YELLOW}Second keyserver also failed will try a different keyserver.${NC}"
	    gpg --keyserver eu.pool.sks-keyservers.net --recv 4B69CA27A986265D
	    gpg --export 4B69CA27A986265D | sudo apt-key add -
	    zel_package && sleep 2
	    if ! gpg --list-keys Zel > /dev/null; then
	    	echo -e "${YELLOW}Third keyserver also failed will try a different keyserver.${NC}"
		gpg --keyserver pgpkeys.urown.net --recv 4B69CA27A986265D
		gpg --export 4B69CA27A986265D | sudo apt-key add -
		zel_package && sleep 2
		if ! gpg --list-keys Zel > /dev/null; then
		    echo -e "${YELLOW}Last keyserver also failed will try one last keyserver.${NC}"
		    gpg --keyserver keys.gnupg.net --recv 4B69CA27A986265D
		    gpg --export 4B69CA27A986265D | sudo apt-key add -
		    zel_package && sleep 2
		fi
	    fi
	fi
    fi
}

function zk_params() {
    echo -e "${YELLOW}Installing zkSNARK params...${NC}"
    bash zelcash-fetch-params.sh
    sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"
}

function bootstrap() {

echo -e "${NC}"
read -p "Would you like to download bootstrap Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
    if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
    	rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate
	echo -e "${YELLOW}Downloading and installing wallet bootstrap please be patient...${NC}"
	wget $BOOTSTRAP_ZIP
	unzip $BOOTSTRAP_ZIPFILE -d ~/$CONFIG_DIR
	rm -rf $BOOTSTRAP_ZIPFILE
    else
    	echo -e "${YELLOW}Downloading and installing wallet bootstrap please be patient...${NC}"
	wget $BOOTSTRAP_ZIP
	unzip $BOOTSTRAP_ZIPFILE -d ~/$CONFIG_DIR
	rm -rf $BOOTSTRAP_ZIPFILE
    fi
fi
}

function create_service() {
    echo -e "${YELLOW}Creating ${COIN_NAME^} service...${NC}"
    sudo touch /etc/systemd/system/$COIN_NAME.service
    sudo chown "$USERNAME":"$USERNAME" /etc/systemd/system/$COIN_NAME.service
    cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
Type=forking
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME/$CONFIG_DIR/
ExecStart=$COIN_PATH/$COIN_DAEMON -datadir=/home/$USERNAME/$CONFIG_DIR/ -conf=/home/$USERNAME/$CONFIG_DIR/$CONFIG_FILE -daemon
ExecStop=-$COIN_PATH/$COIN_CLI stop
Restart=always
RestartSec=3
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
    sudo chown root:root /etc/systemd/system/$COIN_NAME.service
    sudo systemctl daemon-reload
    sleep 4
    sudo systemctl enable $COIN_NAME.service > /dev/null 2>&1
    sudo systemctl stop zelcash
    sleep 4
    sudo systemctl start zelcash
    
}

function basic_security() {
    echo -e "${YELLOW}Configuring firewall and enabling fail2ban...${NC}"
    sudo ufw allow "$SSHPORT"/tcp
    sudo ufw allow "$PORT"/tcp
    sudo ufw logging on
    sudo ufw default deny incoming
    sudo ufw limit OpenSSH
    echo "y" | sudo ufw enable > /dev/null 2>&1
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
}

function start_daemon() {
    NUM='105'
    MSG1='Starting daemon & syncing with chain please be patient this will take about 2 min...'
    MSG2=''
    if $COIN_DAEMON > /dev/null 2>&1; then
    	echo && spinning_timer
	NUM='10'
	MSG1='Getting info...'
	MSG2="${CHECK_MARK}"
	echo && spinning_timer
	echo
	$COIN_CLI getinfo
	sleep 5
    else
    	echo -e "${RED}Something is not right the daemon did not start. Will exit out so try and run the script again.${NC}"
	exit
    fi
}

function log_rotate() {
    echo -e "${YELLOW}Configuring log rotate function for debug logs...${NC}"
    sleep 1
    if [ -f /etc/logrotate.d/zeldebuglog ]; then
        echo -e "${YELLOW}Existing log rotate conf found, backing up to ~/zeldebuglogrotate.old ...${NC}"
	sudo mv /etc/logrotate.d/zeldebuglog ~/zeldebuglogrotate.old;
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

function kill_sessions() {
    echo -e "${YELLOW}If you have made a previous run of the script and have a session running for Zelflux it must be removed before starting a new one."
    echo -e "${YELLOW}Detecting sessions please remove any that is running Zelflux...${NC}" && sleep 5
    tmux ls | sed -e 's/://g' | cut -d' ' -f 1 | tee tempfile > /dev/null 2>&1
    grep -v '^ *#' < tempfile | while IFS= read -r line
    do
        if whiptail --yesno "Would you like to kill session ${line}?" 8 43; then
	    tmux kill-sess -t "$line"
	fi
    done
    rm tempfile
}

function install_zelflux() {
    echo -e "${YELLOW}Detect OS version to install Mongodb, Nodejs, and updating firewall to install Zelflux...${NC}"
    sudo ufw allow $ZELFRONTPORT/tcp
    sudo ufw allow $LOCPORT/tcp
    sudo ufw allow $ZELNODEPORT/tcp
    sudo ufw allow $MDBPORT/tcp
    if [[ $(lsb_release -r) = *16.04* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    elif [[ $(lsb_release -r) = *18.04* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *10* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    fi
    sleep 2
}

function install_mongod() {
    sudo apt-get update
    sudo apt-get install mongodb-org -y
    sudo service mongod start
    sudo systemctl enable mongod
}

function install_nodejs() {
    if ! node -v > /dev/null 2>&1; then
    	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
	. ~/.profile
	nvm install --lts
    else
    	echo -e "${YELLOW}Nodejs already installed will skip installing it.${NC}"
    fi
}

function zelflux() {
    
    
   if [[ $(pm2 -v) ]]
   then
   echo -e "${YELLOW}Deleting old pm2 settings.${NC}"
   pm2 del zelflux
   fi
    
    if [ -d "./zelflux" ]; then
    	sudo rm -rf zelflux
    fi
    if whiptail --yesno "If you would like admin privileges to Zelflux select <Yes>(Recommended) and prepare to enter your ZelID. If you don't have one or don't want to have admin privileges to Zelflux select <No>." 9 108; then
    	ZELID=$(whiptail --inputbox "Enter your ZelID found in the Zelcore+/Apps section of your Zelcore" 8 71 3>&1 1>&2 2>&3)
    else
    	ZELID='132hG26CFTNhLM3MRsLEJhp9DpBrK6vg5N'
    fi
    git clone https://github.com/zelcash/zelflux.git
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
    npm i -g pm2
    pm2 startup systemd -u $USERNAME
    sudo env PATH=$PATH:/home/$USERNAME/.nvm/versions/node/v12.16.1/bin pm2 startup systemd -u $USERNAME --hp /home/$USERNAME
    pm2 start start.sh --name zelflux
    pm2 save
}
	
function status_loop() {
    while true
    do
    	clear
	echo -e "${YELLOW}======================================================================================"
	echo -e "${GREEN} ZELNODE IS SYNCING"
	echo -e " THIS SCREEN REFRESHES EVERY 30 SECONDS"
	echo -e " CHECK BLOCK HEIGHT AT https://explorer.zel.cash/"
	echo -e " YOU COULD START YOUR ZELNODE FROM YOUR CONTROL WALLET WHILE IT SYNCS"
	echo -e "${YELLOW}======================================================================================${NC}"
	echo
	$COIN_CLI getinfo
	sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"
	NUM='30'
	MSG1="${CYAN}Refreshes every 30 seconds while syncing to chain. Refresh loop will stop automatically once it's fully synced.${NC}"
	MSG2=''
	spinning_timer
	if [[ $(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks') == $(${COIN_CLI} getinfo | jq '.blocks') ]]; then
	    break
	fi
    done
    check
    display_banner
}

function update_script() {
    echo -e "${YELLOW}Creating a script to update binaries for future updates...${NC}"
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
    sudo chmod +x update.sh
}

function restart_script() {
    echo -e "${YELLOW}Creating a script to restart Zelflux in case server reboots...${NC}"
    touch /home/"$USERNAME"/start.sh
    cat << EOF > /home/"$USERNAME"/start.sh
#!/bin/bash
cd zelflux && npm start
EOF
    sudo chmod +x start.sh
}

function check() {
    echo && echo && echo
    echo -e "${YELLOW}Running through some checks...${NC}"
    if pgrep zelcashd > /dev/null; then
    	echo -e "${CHECK_MARK} ${CYAN}${COIN_NAME^} daemon is installed and running${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}${COIN_NAME^} daemon is not running${NC}" && sleep 1
    fi
    if [ -d "/home/$USERNAME/.zcash-params" ]; then
    	echo -e "${CHECK_MARK} ${CYAN}zkSNARK params installed${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}zkSNARK params not installed${NC}" && sleep 1
    fi
    if pgrep mongod > /dev/null; then
    	echo -e "${CHECK_MARK} ${CYAN}Mongodb is installed and running${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Mongodb is not running or failed to install${NC}" && sleep 1
    fi
    if node -v > /dev/null 2>&1; then
    	echo -e "${CHECK_MARK} ${CYAN}Nodejs installed${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Nodejs did not install${NC}" && sleep 1
    fi
    if [ -d "/home/$USERNAME/zelflux" ]; then
    	echo -e "${CHECK_MARK} ${CYAN}Zelflux installed${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Zelflux did not install${NC}" && sleep 1
    fi
    if [ -f "/home/$USERNAME/$UPDATE_FILE" ]; then
    	echo -e "${CHECK_MARK} ${CYAN}Update script created${NC}" && sleep 3
    else
    	echo -e "${X_MARK} ${CYAN}Update script not installed${NC}" && sleep 3
    fi
    if [ -f "/home/$USERNAME/start.sh" ]; then
    	echo -e "${CHECK_MARK} ${CYAN}Restart script for Zelflux created${NC}" && sleep 3
    else
    	echo -e "${X_MARK} ${CYAN}Restart script not installed${NC}" && sleep 3
    fi
    echo && echo && echo
}

function display_banner() {
    echo -e "${BLUE}"
    figlet -t -k "ZELNODES  &  ZELFLUX"
    echo -e "${NC}"
    echo -e "${YELLOW}================================================================================================================================"
    echo -e " PLEASE COMPLETE THE ZELNODE SETUP AND START YOUR ZELNODE${NC}"
    echo -e "${CYAN} COURTESY OF DK808${NC}"
    echo
    echo -e "${YELLOW}   Commands to manage ${COIN_NAME}. Note that you have to be in the zelcash directory when entering commands.${NC}"
    echo -e "${PIN} ${CYAN}TO START: ${SEA}${COIN_DAEMON}${NC}"
    echo -e "${PIN} ${CYAN}TO STOP : ${SEA}${COIN_CLI} stop${NC}"
    echo -e "${PIN} ${CYAN}RPC LIST: ${SEA}${COIN_CLI} help${NC}"
    echo
    echo -e "${PIN} ${YELLOW}To update binaries wait for announcement that update is ready then enter:${NC} ${SEA}./${UPDATE_FILE}${NC}"
    echo
    echo -e "${YELLOW}   PM2 is now managing Zelflux to start up on reboots.${NC}"
    echo -e "${YELLOW}   Commands to manage PM2.${NC}"
    echo -e "${PIN} ${CYAN}TO START: ${SEA}pm2 start zelflux${NC}"
    echo -e "${PIN} ${CYAN}TO STOP : ${SEA}pm2 stop zelflux${NC}"
    echo -e "${PIN} ${CYAN}LOGS: ${SEA}pm2 monit${NC}"
    echo -e "${PIN} ${CYAN}STATUS: ${SEA}pm2 list${NC}"
    echo
    echo -e "${PIN} ${CYAN}To access your frontend to Zelflux enter this in as your url: ${SEA}${WANIP}:${ZELFRONTPORT}${NC}"
    echo -e "${YELLOW}================================================================================================================================${NC}"
}
#
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
    bootstrap
    create_service
    basic_security
    start_daemon
    restart_script
    install_zelflux
    log_rotate
    update_script
    status_loop
    
