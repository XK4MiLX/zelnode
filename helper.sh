#!/bin/bash

#information
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
#end of required details

# add to path
PATH=$PATH:"$COIN_PATH"
export PATH

call_type="$1"

function install_package()
{
sudo apt-get purge "$1" -y >/dev/null 2>&1 && sleep 1
sudo rm /etc/apt/sources.list.d/zelcash.list >/dev/null 2>&1 && sleep 1
echo 'deb https://apt.zel.cash/ all main' | sudo tee /etc/apt/sources.list.d/zelcash.list
gpg --keyserver keyserver.ubuntu.com --recv 4B69CA27A986265D
gpg --export 4B69CA27A986265D | sudo apt-key add -
sudo apt-get update
sudo apt-get install "$1" -y
sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
if ! gpg --list-keys Zel >/dev/null; then
  gpg --keyserver na.pool.sks-keyservers.net --recv 4B69CA27A986265D
  gpg --export 4B69CA27A986265D | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install "$1" -y
  sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
  if ! gpg --list-keys Zel >/dev/null; then
    gpg --keyserver eu.pool.sks-keyservers.net --recv 4B69CA27A986265D
    gpg --export 4B69CA27A986265D | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install "$1" -y
    sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
    if ! gpg --list-keys Zel >/dev/null; then
      gpg --keyserver pgpkeys.urown.net --recv 4B69CA27A986265D
      gpg --export 4B69CA27A986265D | sudo apt-key add -
      sudo apt-get update
      sudo apt-get install "$1" -y
      sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
      if ! gpg --list-keys Zel >/dev/null; then
        gpg --keyserver keys.gnupg.net --recv 4B69CA27A986265D
        gpg --export 4B69CA27A986265D | sudo apt-key add -
        sudo apt-get update
        sudo apt-get install "$1" -y
        sudo chmod 755 "$COIN_PATH/$1"* && sleep 2
      fi
    fi
  fi
fi
}


start_zelcash() {

serive_check=$(sudo systemctl list-units --full -all | grep -o 'zelcash.service' | head -n1)

if [[ "$serive_check" != "" ]]; then
  sudo systemctl start zelcash >/dev/null 2>&1
else
  "$COIN_DAEMON"
fi
}

stop_zelcash() {
sudo systemctl stop zelcash >/dev/null 2>&1 && sleep 3
"$COIN_CLI" stop >/dev/null 2>&1 && sleep 5
sudo killall "$COIN_DAEMON" >/dev/null 2>&1
sudo killall -s SIGKILL zelbenchd >/dev/null 2>&1 && sleep 1
sleep 2
}


# main function

function reindex()
{
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
stop_zelcash
start_zelcash
}

function zelbench_update()
{
dpkg_version_before_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')
stop_zelcash
sudo apt-get update
sudo apt-get install --only-upgrade zelbench -y
sudo chmod 755 "$COIN_PATH"/zelbench*
sleep 2
dpkg_version_after_install=$(dpkg -l zelbench | grep -w 'zelbench' | awk '{print $3}')

if [[ "$dpkg_version_before_install" == "$dpkg_version_after_install" ]]; then
start_zelcash
fi

if ! [[ "$dpkg_version_before_install" == "$dpkg_version_after_install" ]]; then
install_package zelbench
start_zelcash
fi

}

function zelcash_update()
{
dpkg_version_before_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')

stop_zelcash
sudo apt-get update
sudo apt-get install --only-upgrade zelcash -y
sudo chmod 755 "$COIN_PATH"/zelcash*
sleep 2

dpkg_version_after_install=$(dpkg -l zelcash | grep -w 'zelcash' | awk '{print $3}')

if [[  "$dpkg_version_before_install" == "$dpkg_version_after_install" ]]; then
start_zelcash
fi

if ! [[ "$dpkg_version_before_install" == "$dpkg_version_after_install" ]]; then
install_package zelcash
start_zelcash
fi
}

case $call_type in

                 "zelcash_update")
zelcash_update
;;
                 "zelbench_update")
zelbench_update
;;
                 "zelcash_restart")
restart_zelcash
;;
                 "zelcash_reindex")
reindex
;;

esac
