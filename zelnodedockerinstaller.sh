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

echo -e "${YELLOW}================================================================${NC}"
echo -e "${GREEN}           ZelNode Docker Installer v1.0 for Ubuntu by XK4MiLX${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${NC}"

if [[ "$USER" != "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${CYAN}, please switch to the root accont.${NC}"
    sleep 2
    exit
fi
	usernew="$(whiptail --title "ZelNode Docker Installer v1.0" --inputbox "Enter your username" 8 72 3>&1 1>&2 
	adduser $usernew
	usermod -aG sudo $usernew
	apt update && apt install snapd -y
	snap install docker
	groupadd docker
	adduser $usernew docker

	echo -e "$${YELLOW}Running through some checks...${NC}"
	echo -e "${YELLOW}=====================================================${NC}"

	if [[ $(docker -v) == *"Docker"* ]]
	then
		echo -e "${CHECK_MARK} ${CYAN}Docker is installed${NC}"
	else
		echo -e "${X_MARK} ${CYAN}Docker did not installed${NC}"
	fi

	if [[ $(groups | grep docker) && $(groups | grep "$usernew")  ]] 
	then
	echo -e "${CHECK_MARK} ${CYAN}User $usernew belongs to docker group${NC}"
	else
	echo -e "${X_MARK} ${CYAN}User $usernew was not added to docker group${NC}"
	fi

	echo -e "${YELLOW}=====================================================${NC}"
	echo -e "${NC}"
	read -p "Would you like to reboot pc Y/N?" -n 1 -r
	echo -e "${NC}"

	if [[ $REPLY =~ ^[Yy]$ ]]
	then
	sudo reboot -n
	fi
