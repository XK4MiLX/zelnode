#!/bin/bash

#information
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
#end of required details

#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
ORANGE='\e[38;5;202m'
NC='\033[0m'
FLUX_UPDATE="0"

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9C\x96${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
CLOCK="${GREEN}\xE2\x8C\x9B${NC}"
ARROW="${SEA}\xE2\x96\xB6${NC}"
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
HOT="${ORANGE}\xF0\x9F\x94\xA5${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"

# add to path
PATH=$PATH:"$COIN_PATH"
export PATH

call_type="$1"
type="$2"

echo -e "${BOOK}${YELLOW}Helper action: ${GREEN}$1${NC}"

function local_version_check() {
local_version=$(dpkg -l $1 | grep -w $1 | awk '{print $3}')
}

function remote_version_check(){
#variable null
remote_version=""
package_name=""
remote_version=$(curl -s -m 3 https://apt.zel.cash/pool/main/z/"$1"/ | grep -o '[0-9].[0-9].[0-9]' | head -n1)
if [[ "$remote_version" != "" ]]; then
package_name=$(echo "$1_"$remote_version"_all.deb")
fi

}

function install_package()
{
echo -e "${ARROW} ${CYAN}Install package for: ${GREEN}$1${NC}"

sudo apt-get purge "$1" -y >/dev/null 2>&1 && sleep 1
sudo rm /etc/apt/sources.list.d/zelcash.list >/dev/null 2>&1 && sleep 1
echo -e "${ARROW} ${CYAN}Adding apt source...${NC}"
echo 'deb https://apt.zel.cash/ all main' | sudo tee /etc/apt/sources.list.d/zelcash.list
gpg --keyserver keyserver.ubuntu.com --recv 4B69CA27A986265D >/dev/null 2>&1
gpg --export 4B69CA27A986265D | sudo apt-key add - >/dev/null 2>&1
sudo apt-get update >/dev/null 2>&1
sudo apt-get install "$1" -y >/dev/null 2>&1
sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
if ! gpg --list-keys Zel >/dev/null; then
  gpg --keyserver na.pool.sks-keyservers.net --recv 4B69CA27A986265D >/dev/null 2>&1
  gpg --export 4B69CA27A986265D | sudo apt-key add - >/dev/null 2>&1
  sudo apt-get update >/dev/null 2>&1 
  sudo apt-get install "$1" -y >/dev/null 2>&1
  sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
  if ! gpg --list-keys Zel >/dev/null; then
    gpg --keyserver eu.pool.sks-keyservers.net --recv 4B69CA27A986265D >/dev/null 2>&1
    gpg --export 4B69CA27A986265D | sudo apt-key add - >/dev/null 2>&1
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install "$1" -y >/dev/null 2>&1
    sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
    if ! gpg --list-keys Zel >/dev/null; then
      gpg --keyserver pgpkeys.urown.net --recv 4B69CA27A986265D >/dev/null 2>&1
      gpg --export 4B69CA27A986265D | sudo apt-key add - >/dev/null 2>&1
      sudo apt-get update >/dev/null 2>&1
      sudo apt-get install "$1" -y >/dev/null 2>&1
      sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
      if ! gpg --list-keys Zel >/dev/null; then
        gpg --keyserver keys.gnupg.net --recv 4B69CA27A986265D >/dev/null 2>&1  
        gpg --export 4B69CA27A986265D | sudo apt-key add - >/dev/null 2>&1
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install "$1" -y >/dev/null 2>&1
        sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
      fi
    fi
  fi
fi
}

start_zelcash() {
serive_check=$(sudo systemctl list-units --full -all | grep -o 'zelcash.service' | head -n1)

if [[ "$serive_check" != "" ]]; then
echo -e "${ARROW} ${CYAN}Starting zelcash service...${NC}"
  sudo systemctl start zelcash >/dev/null 2>&1
else
echo -e "${ARROW} ${CYAN}Starting zelcash daemon process...${NC}"
  "$COIN_DAEMON" >/dev/null 2>&1
fi
}

stop_zelcash() {

echo -e "${ARROW} ${CYAN}Stopping zelcash...${NC}"
sudo systemctl stop zelcash >/dev/null 2>&1 && sleep 3
"$COIN_CLI" stop >/dev/null 2>&1 && sleep 3
sudo killall "$COIN_DAEMON" >/dev/null 2>&1
sudo killall -s SIGKILL zelbenchd >/dev/null 2>&1 && sleep 1
sleep 2

}


# main function
function reindex()
{
echo -e "${ARROW} ${CYAN}Reindexing...${NC}"
stop_zelcash
"$COIN_DAEMON" -reindex
serive_check=$(sudo systemctl list-units --full -all | grep -o 'zelcash.service' | head -n1)
if [[ "$serive_check" != "" ]]; then
sleep 60
stop_zelcash
start_zelcash
fi
}

function restart_zelcash()
{

echo -e "${ARROW} ${CYAN}Restarting zelcash...${NC}"
serive_check=$(sudo systemctl list-units --full -all | grep -o 'zelcash.service' | head -n1)
if [[ "$serive_check" != "" ]]; then
sudo systemctl restart zelcash >/dev/null 2>&1 && sleep 3
else
stop_zelcash
start_zelcash
fi

}

function zelbench_update()
{

local_version=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')

if [[ "$type" == "force" ]]; then
echo -e "${ARROW} ${CYAN}Force zelbench updating...${NC}"
stop_zelcash
install_package zelbench
dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
echo -e "${ARROW} ${CYAN}Zelbench version before update: ${GREEN}$local_version${NC}"
echo -e "${ARROW} ${CYAN}Zelbench version after update: ${GREEN}$dpkg_version_after_install${NC}"
start_zelcash
return
fi

remote_version_check zelbench
#remote_version=$(curl -s -m 3 https://zelcore.io/zelflux/zelbenchinfo.php | jq -r .version)

if [[ "$call_type" != "update_all" ]]; then

  if [[ "$remote_version" == "" ]]; then
   echo -e "${ARROW} ${CYAN}Problem with version veryfication...Zelbench installation skipped...${NC}"
   return
  fi

  if [[ "$remote_version" == "$local_version" ]]; then
   echo -e "${ARROW} ${CYAN}You have the current version of Zelbench ${GREEN}($remote_version)${NC}"
   return
  fi

fi

echo -e "${ARROW} ${CYAN}Updating zelbench...${NC}"
#stop_zelcash
echo -e "${ARROW} ${CYAN}Zelbench server stopping...${NC}"
zelbench-cli stop >/dev/null 2>&1 && sleep 2
sudo killall -s SIGKILL zelbenchd >/dev/null 2>&1 && sleep 1
sudo apt-get update >/dev/null 2>&1
sudo apt-get install --only-upgrade zelbench -y >/dev/null 2>&1
sudo chmod 755 "$COIN_PATH"/zelbench*
sleep 2

dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
echo -e "${ARROW} ${CYAN}Zelbench version before update: ${GREEN}$local_version${NC}"
#echo -e "${ARROW} ${CYAN}Zelbench version after update: ${GREEN}$dpkg_version_after_install${NC}"

if [[ "$dpkg_version_after_install" == "" ]]; then

install_package zelbench
dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
    
  if [[ "$dpkg_version_after_install" != "" ]]; then
    echo -e "${ARROW} ${CYAN}Zelbench update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
  fi

start_zelcash
echo -e "${ARROW} ${CYAN}Zelbench server starting...${NC}"
#zelbenchd -daemon >/dev/null 2>&1
else

  if [[ "$remote_version" == "$dpkg_version_after_install" ]]; then
  
    echo -e "${ARROW} ${CYAN}Zelbench update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
    start_zelcash
    echo -e "${ARROW} ${CYAN}Zelbench server starting...${NC}"
    #zelbenchd -daemon >/dev/null 2>&1
  else

    if [[ "$local_version" == "$dpkg_version_after_install" ]]; then
      install_package zelbench
      dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
    
      if [[ "dpkg_version_after_install" == "$remote_version" ]]; then
        echo -e "${ARROW} ${CYAN}Zelbench update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
      fi
      start_zelcash
      echo -e "${ARROW} ${CYAN}Zelbench server starting...${NC}"
      #zelbenchd -daemon >/dev/null 2>&1
    fi
  fi
fi

}

function zelflux_update()
{

current_ver=$(jq -r '.version' /home/$USER/zelflux/package.json)
required_ver=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')

if [[ "$required_ver" != "" && "$call_type" != "update_all" ]]; then
   if [ "$(printf '%s\n' "$required_ver" "$current_ver" | sort -V | head -n1)" = "$required_ver" ]; then 
      echo -e "${ARROW} ${CYAN}You have the current version of Zelflux ${GREEN}($required_ver)${NC}"  
      return 
   else
      #echo -e "${HOT} ${CYAN}New version of Zelflux available ${SEA}$required_ver${NC}"
      FLUX_UPDATE="1"
   fi
 fi

if [[ "$FLUX_UPDATE" == "1" ]]; then
  cd /home/$USER/zelflux && git pull > /dev/null 2>&1 && cd
  current_ver=$(jq -r '.version' /home/$USER/zelflux/package.json)
  required_ver=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')
    if [[ "$required_ver" == "$current_ver" ]]; then
      echo -e "${ARROW} ${CYAN}Zelfux updated successfully ${GREEN}($required_ver)${NC}"
    else
      echo -e "${ARROW} ${CYAN}Zelfux was not updated.${NC}"
      echo -e "${ARROW} ${CYAN}Zelfux force update....${NC}"
      rm /home/$USER/zelflux/.git/HEAD.lock >/dev/null 2>&1
      #cd /home/$USER/zelflux && npm run hardupdatezelflux
      cd /home/$USER/zelflux && git reset --hard HEAD && git clean -f -d && git pull


      current_ver=$(jq -r '.version' /home/$USER/zelflux/package.json)
      required_ver=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')

        if [[ "$required_ver" == "$current_ver" ]]; then
          echo -e "${ARROW} ${CYAN}Zelfux updated successfully ${GREEN}($required_ver)${NC}"
        fi
    fi

else
echo -e "${ARROW} ${CYAN}Problem with version veryfication...Zelflux installation skipped...${NC}"
fi


}

function zelcash_update()
{

local_version=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')

if [[ "$type" == "force" ]]; then
echo -e "${ARROW} ${CYAN}Force zelcash updating...${NC}"
stop_zelcash
install_package zelcash
dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')
echo -e "${ARROW} ${CYAN}Zelcash version before update: ${GREEN}$local_version${NC}"
echo -e "${ARROW} ${CYAN}Zelcash version after update: ${GREEN}$dpkg_version_after_install${NC}"
start_zelcash
return
fi


remote_version_check zelcash
#local_version=$(zelcash-cli getinfo | jq -r .version)
#remote_version=$(curl -s -m3  https://zelcore.io/zelflux/zelcashinfo.php | jq -r .version)

if [[ "$call_type" != "update_all" ]]; then

  if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
   echo -e "${ARROW} ${CYAN}Problem with version veryfication...Zelcash installation skipped...${NC}"
   return
  fi

  if [[ "$local_version" == "$remote_version" ]]; then
   echo -e "${ARROW} ${CYAN}You have the current version of Zelcash ${GREEN}($remote_version)${NC}"
   return
  fi

fi

dpkg_version_before_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')
stop_zelcash

sudo apt-get update >/dev/null 2>&1
sudo apt-get install --only-upgrade zelcash -y >/dev/null 2>&1
sudo chmod 755 "$COIN_PATH"/zelcash*
sleep 2

dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')
echo -e "${ARROW} ${CYAN}Zelcash version before update: ${GREEN}$local_version${NC}"
#echo -e "${ARROW} ${CYAN}Zelcash version after update: ${GREEN}$dpkg_version_after_install${NC}"

if [[ "$dpkg_version_after_install" == "" ]]; then

install_package zelcash
dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')

  if [[ "$dpkg_version_after_install" != "" ]]; then
    echo -e "${ARROW} ${CYAN}Zelcash update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
  fi

start_zelcash

else

  if [[ "$local_version" != "$dpkg_version_after_install" ]]; then
  
    echo -e "${ARROW} ${CYAN}Zelcash update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
    start_zelcash
  fi

  if [[ "local_version" == "$dpkg_version_after_install" ]]; then
    install_package zelcash
    dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')
    
    if [[ "$dpkg_version_after_install" == "$remote_version" ]]; then
      echo -e "${ARROW} ${CYAN}Zelcash update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
    fi
    
    start_zelcash
  fi

fi

}

function check_update() {

update_zelbench="0"
update_zelcash="0"
update_zelflux="0"

local_version_check zelcash
remote_version_check zelcash

if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
echo -e "${RED}${ARROW} ${CYAN}Problem with version veryfication...Zelcash installation skipped...${NC}"
else

  if [[ "$local_version" != "$remote_version" ]]; then
  echo -e "${RED}${HOT}${CYAN}New version of Zelcash available ${SEA}$remote_version${NC}"
  update_zelcash="1"
  else
  echo -e "${ARROW} ${CYAN}You have the current version of Zelcash ${GREEN}($remote_version)${NC}"
  fi
  
fi

local_version_check zelbench
remote_version_check zelbench

if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
echo -e "${RED}${ARROW} ${CYAN}Problem with version veryfication...Zelbench installation skipped...${NC}"
else

  if [[ "$local_version" != "$remote_version" ]]; then
  echo -e "${RED}${HOT}${CYAN}New version of Zelbench available ${SEA}$remote_version${NC}"
  update_zelbench="1"
  else
  echo -e "${ARROW} ${CYAN}You have the current version of Zelbench ${GREEN}($remote_version)${NC}"
  fi

fi

local_version=$(jq -r '.version' /home/$USER/zelflux/package.json)
remote_version=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')

if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
echo -e "${RED}${ARROW} ${CYAN}Problem with version veryfication...Zelflux installation skipped...${NC}"
else

  if [[ "$local_version" != "$remote_version" ]]; then
  echo -e "${RED}${HOT}${CYAN}New version of ZelFlux available ${SEA}$remote_version${NC}"
  update_zelflux="1"
  FLUX_UPDATE="1"
  else
  echo -e "${ARROW} ${CYAN}You have the current version of ZelFlux ${GREEN}($remote_version)${NC}"
  fi

fi

if [[ "$update_zelbench" == "1" || "$update_zelcash" == "1" || "$update_zelflux" == "1" ]]; then
echo -e ""
fi

}

function create_zel_bootstrap()
{

if zelcash-cli getinfo > /dev/null 2>&1; then

local_network_hight=$(zelcash-cli getinfo | jq -r .blocks)
echo -e "${ARROW} ${CYAN}Local Network Block Hight: ${GREEN}$local_network_hight${NC}"
explorer_network_hight=$(curl -s -m 3 https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks')
echo -e "${ARROW} ${CYAN}Global Network Block Hight: ${GREEN}$explorer_network_hight${NC}"

 if [[ "$explorer_network_hight" == "" || "$local_network_hight" == "" ]]; then
 echo -e "${ARROW} ${CYAN}Zelcash network veryfication failed...${NC}"
 exit
 fi
 
if [[ "$explorer_network_hight" == "$local_network_hight" ]]; then
 echo -e "${ARROW} ${CYAN}Node is full synced with Zelcash Network...${NC}"
else
 echo -e "${ARROW} ${CYAN}Node is not full synced with Zelcash Network...${NC}"
 echo
exit
fi

stop_zelcash
check_zip=$(zip -L | head -n1)

if [[ "$check_zip" != "" ]]; then
echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
rm -rf /home/$USER/zel-bootstrap.zip >/dev/null 2>&1 && sleep 5
echo -e "${ARROW} ${CYAN}Zelcash bootstrap creating...${NC}"
cd /home/$USER/.zelcash && zip /home/$USER/zel-bootstrap.zip -r blocks chainstate determ_zelnodes
cd

if [[ -f /home/$USER/zel-bootstrap.zip ]]; then
echo -e "${ARROW} ${CYAN}Zelcash bootstrap created successful ${GREEN}($local_network_hight)${NC}"
else
echo -e "${ARROW} ${CYAN}Zelcash bootstrap creating failed${NC}"
fi

fi
start_zelcash

else
echo -e "${ARROW} ${CYAN}Zelcash network veryfication failed...zelcash daemon not working...${NC}"
echo
fi

}

function create_mongod_bootstrap()
{
    echo -e "${ARROW} ${YELLOW}Detecting IP address...${NC}"
    WANIP=$(wget --timeout=3 --tries=2 http://ipecho.net/plain -O - -q) 
    if [[ "$WANIP" == "" ]]; then
      WANIP=$(curl -s -m 3 ifconfig.me)     
         if [[ "$WANIP" == "" ]]; then
      	   echo -e "${ARROW} ${CYAN}IP address could not be found, action stopped .........[${X_MARK}${CYAN}]${NC}"
	   echo
	   exit
    	 fi
    fi

local_network_hight=$(curl -s -m 3 http://"$WANIP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
echo -e "${ARROW} ${CYAN}Mongod Network Block Hight: ${GREEN}$local_network_hight${NC}"
explorer_network_hight=$(curl -s -m 3 https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks')
echo -e "${ARROW} ${CYAN}Global Network Block Hight: ${GREEN}$explorer_network_hight${NC}"

 if [[ "$explorer_network_hight" == "" || "$local_network_hight" == "" ]]; then
 echo -e "${ARROW} ${CYAN}Zelcash network veryfication failed...${NC}"
 return
 fi

 if [[ "$explorer_network_hight" == "$local_network_hight" ]]; then
  echo -e "${ARROW} ${CYAN}Mongod is full synced with Zelcash Network...${NC}"
 else
  echo -e "${ARROW} ${CYAN}Mongod is not full synced with Zelcash Network...${NC}"
  return
 fi
 
echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
sudo rm -rf /home/$USER/dump >/dev/null 2>&1 && sleep 2
sudo rm -rf /home/$USER/mongod_bootstrap.tar.gz >/dev/null 2>&1 && sleep 2

echo -e "${ARROW} ${CYAN}Exporting Mongod datetable...${NC}"
mongodump --port 27017 --db zelcashdata --out /home/$USER/dump/
echo -e "${ARROW} ${CYAN}Creating bootstrap file...${NC}"
tar -cvzf /home/$USER/mongod_bootstrap.tar.gz dump

if [[ -f /home/$USER/mongod_bootstrap.tar.gz ]]; then
echo -e "${ARROW} ${CYAN}Mongod bootstrap created successful ${GREEN}($local_network_hight)${NC}"
else
echo -e "${ARROW} ${CYAN}Mongod bootstrap creating failed${NC}"
fi

}

function send_to_host() {

#if [[ "$1" != "mongod" || "$1" != "zelcash" ]]; then
#echo "$1"
#exit
#fi

sudo ufw disable >/dev/null 2>&1
echo -e "${CYAN}Firewall Stopping...${NC}"
echo -e "${CYAN}RSYNC Configuration...${NC}"
read -p 'IP: ' ipservar
read -p 'USERNAME: ' uservar

if [[ "$1" == "zelcash" ]]; then
rsync -rv ~/zel-bootstrap.zip -e ssh "$uservar"@"$ipservar":~/zel-bootstrap.zip
echo -e "${ARROW} ${CYAN}Type on destination server: ${ORANGE}rsync -rv ~/zel-bootstrap.zip -e ssh${NC}"
fi

if [[ "$1" == "mongod" ]]; then
rsync -rv ~/mongod_bootstrap.tar.gz -e ssh "$uservar"@"$ipservar":~/mongod_bootstrap.tar.gz
echo -e "${ARROW} ${CYAN}Type on destination server: ${ORANGE}rsync -rv ~/mongod_bootstrap.tar.gz -e ssh${NC}"
fi

echo
read -p 'Awaiting for input to enable firewall...' firewall
sudo ufw --force enable

}

case $call_type in

                 "update_all")
		 
check_update
if [[ "$update_zelflux" == "1" ]]; then
zelflux_update
fi

if [[ "$update_zelbench" == "1" ]]; then
zelbench_update
fi

if [[ "$update_zelcash" == "1" ]]; then
zelcash_update
fi
echo
;;

                 "zelcash_update")
zelcash_update
echo
;;
                 "zelbench_update")
zelbench_update
echo
;;
                 "zelflux_update")
zelflux_update
echo
;;
                 "zelcash_restart")
restart_zelcash
echo
;;
                 "zelcash_reindex")
reindex
echo
;;
                "create_zel_bootstrap")
create_zel_bootstrap
echo
;;
                "create_mongod_bootstrap")
create_mongod_bootstrap
echo
;;

                "send_to_host")
		
send_to_host $type
echo
;;

esac
