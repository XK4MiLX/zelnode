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

# add to path
PATH=$PATH:"$COIN_PATH"
export PATH

call_type="$1"
type="$2"

echo -e "${BOOK} ${YELLOW}Helper action: ${GREEN}$1${NC}"

function install_package()
{

echo -e "${ARROW} ${CYAN}Install package for: ${GREEN}$1${NC}"

sudo apt-get purge "$1" -y >/dev/null 2>&1 && sleep 1
sudo rm /etc/apt/sources.list.d/zelcash.list >/dev/null 2>&1 && sleep 1
echo -e "${ARROW} ${CYAN}Adding apt sources...{NC}"
echo 'deb https://apt.zel.cash/ all main' | sudo tee /etc/apt/sources.list.d/zelcash.list
gpg --keyserver keyserver.ubuntu.com --recv 4B69CA27A986265D
gpg --export 4B69CA27A986265D | sudo apt-key add -
sudo apt-get update >/dev/null 2>&1
sudo apt-get install "$1" -y >/dev/null 2>&1
sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
if ! gpg --list-keys Zel >/dev/null; then
  gpg --keyserver na.pool.sks-keyservers.net --recv 4B69CA27A986265D
  gpg --export 4B69CA27A986265D | sudo apt-key add -
  sudo apt-get update >/dev/null 2>&1
  sudo apt-get install "$1" -y >/dev/null 2>&1
  sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
  if ! gpg --list-keys Zel >/dev/null; then
    gpg --keyserver eu.pool.sks-keyservers.net --recv 4B69CA27A986265D
    gpg --export 4B69CA27A986265D | sudo apt-key add -
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install "$1" -y >/dev/null 2>&1
    sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
    if ! gpg --list-keys Zel >/dev/null; then
      gpg --keyserver pgpkeys.urown.net --recv 4B69CA27A986265D
      gpg --export 4B69CA27A986265D | sudo apt-key add -
      sudo apt-get update >/dev/null 2>&1
      sudo apt-get install "$1" -y >/dev/null 2>&1
      sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
      if ! gpg --list-keys Zel >/dev/null; then
        gpg --keyserver keys.gnupg.net --recv 4B69CA27A986265D
        gpg --export 4B69CA27A986265D | sudo apt-key add -
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
"$COIN_CLI" stop >/dev/null 2>&1 && sleep 5
sudo killall "$COIN_DAEMON" >/dev/null 2>&1
sudo killall -s SIGKILL zelbenchd >/dev/null 2>&1 && sleep 1
sleep 2
}


# main function
function reindex()
{
echo -e "${ARROW} ${CYAN}Reindexing...${NC}"
stop_zelcash
"$COIN_DAEMON" -reindex && sleep 5
serive_check=$(sudo systemctl list-units --full -all | grep -o 'zelcash.service' | head -n1)
if [[ "$serive_check" != "" ]]; then
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

remote_version=$(curl -s -m 3 https://zelcore.io/zelflux/zelbenchinfo.php | jq -r .version)
dpkg_version_before_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')

if [[ "$remote_version" == "" ]]; then
echo -e "${ARROW} ${CYAN}Problem with checking remote version...${NC}"
echo
exit
fi

if [[ "$remote_version" == "$dpkg_version_before_install" && "$type" != "force" ]]; then
echo -e "${ARROW} ${CYAN}You have the current version of Zelbench ${GREEN}($remote_version)${NC}"
echo
exit
fi

echo -e "${ARROW} ${CYAN}Updating zelbench...${NC}"
stop_zelcash
sudo apt-get update >/dev/null 2>&1
sudo apt-get install --only-upgrade zelbench -y >/dev/null 2>&1
sudo chmod 755 "$COIN_PATH"/zelbench*
sleep 2

dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
echo -e "${ARROW} ${CYAN}Zelbench version before update: ${GREEN}$dpkg_version_before_install${NC}"
echo -e "${ARROW} ${CYAN}Zelbench version after update: ${GREEN}$dpkg_version_after_install${NC}"

if [[ "$dpkg_version_after_install" == "" ]]; then

install_package zelbench
dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
    
  if [[ "$dpkg_version_after_install" != "" ]]; then
    echo -e "${ARROW} ${CYAN}Zelbench update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
  fi

start_zelcash

else

  if [[ "$remote_version" == "$dpkg_version_after_install" ]]; then
  
    echo -e "${ARROW} ${CYAN}Zelbench update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
    start_zelcash
  fi

  if [[ "$dpkg_version_before_install" == "$dpkg_version_after_install" ]]; then
    install_package zelbench
    dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
    
    if [[ "dpkg_version_after_install" == "$remote_version" ]]; then
      echo -e "${ARROW} ${CYAN}Zelbench update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
    fi
    
    start_zelcash
  fi

fi

}

function zelcash_update()
{

dpkg_version_before_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')

stop_zelcash
sudo apt-get update >/dev/null 2>&1
sudo apt-get install --only-upgrade zelcash -y >/dev/null 2>&1
sudo chmod 755 "$COIN_PATH"/zelcash*
sleep 2

dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')
echo -e "${ARROW} ${CYAN}Zelcash version before update: ${GREEN}$dpkg_version_before_install${NC}"
echo -e "${ARROW} ${CYAN}Zelcash version after update: ${GREEN}$dpkg_version_after_install${NC}"

if [[ "$dpkg_version_after_install" == "" ]]; then

install_package zelcash
dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')

  if [[ "$dpkg_version_after_install" != "" ]]; then
    echo -e "${ARROW} ${CYAN}Zelcash update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
  fi

start_zelcash

else

  if [[ "$dpkg_version_before_install" != "$dpkg_version_after_install" ]]; then
  
    echo -e "${ARROW} ${CYAN}Zelcash update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
    start_zelcash
  fi

  if [[ "$dpkg_version_before_install" == "$dpkg_version_after_install" ]]; then
    install_package zelcash
    dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')
    
    if [[ "$dpkg_version_after_install" != "$dpkg_version_before_install" ]]; then
      echo -e "${ARROW} ${CYAN}Zelcash update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
    fi
    
    start_zelcash
  fi

fi

}

case $call_type in

                 "zelcash_update")
zelcash_update
echo
;;
                 "zelbench_update")
zelbench_update
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

esac
