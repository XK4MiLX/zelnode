#!/bin/bash
url_array=(
    "https://api4.my-ip.io/ip"
    "https://checkip.amazonaws.com"
    "https://api.ipify.org"
)

function get_ip() {
    for url in "$@"; do
        WANIP=$(curl --silent -m 15 "$url" | tr -dc '[:alnum:].')
        # Remove dots from the IP address
        IP_NO_DOTS=$(echo "$WANIP" | tr -d '.')
        # Check if the result is a valid number
        if [[ "$IP_NO_DOTS" != "" && "$IP_NO_DOTS" =~ ^[0-9]+$ ]]; then
            break
        fi
    done
}

function get_device_name(){
  if [[ -f /home/$USER/device_conf.json ]]; then
    device_name=$(jq -r .device_name /home/$USER/device_conf.json)
  else
    device_name=$(ip addr | grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | head -n1 | awk '{print $2}' | sed 's/://' | sed 's/@/ /' | awk '{print $1}')
  fi
}

if [[ $1 == "restart" ]]; then
  #give 3min to connect with internet
  sleep 180
  get_ip "${url_array[@]}"
  get_device_name
  if [[ "$device_name" != "" && "$WANIP" != "" ]]; then
  date_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "New IP detected during $1, IP: $WANIP was added to $device_name at $date_timestamp" >> /home/$USER/ip_history.log
  sudo ip addr add $WANIP dev $device_name && sleep 2
  fi
fi
if [[ $1 == "ip_check" ]]; then
  get_ip "${url_array[@]}"
  get_device_name
  api_port=$(grep -w apiport /home/$USER/zelflux/config/userconfig.js | grep -o '[[:digit:]]*')
  if [[ "$api_port" == "" ]]; then
  api_port="16127"
  fi
  confirmed_ip=$(curl -SsL -m 10 http://localhost:$api_port/flux/info 2>/dev/null | jq -r .data.node.status.ip | sed -r 's/:.+//')
  if [[ "$WANIP" != "" && "$confirmed_ip" != "" && "$confirmed_ip" != "null" ]]; then
   if [[ "$WANIP" != "$confirmed_ip" ]]; then
    date_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "New IP detected during $1, IP: $WANIP was added to $device_name at $date_timestamp" >> /home/$USER/ip_history.log
    sudo ip addr add $WANIP dev $device_name && sleep 2
   fi
  fi
fi
