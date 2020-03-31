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
echo -e "${GREEN}	ZelNode Docker Installer v2.0 for Ubuntu by XK4MiLX${NC}"
echo -e "${YELLOW}================================================================${NC}"
if [[ "$USER" != "root" ]]
then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the root accont.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi


prompt="Pick an option:"
options=("Install docker on VPS/Inside LXC Continer" "Fix your lxc.conf file on host")

PS3="$prompt "
select opt in "${options[@]}" "Quit"; do 

    case "$REPLY" in

    1 ) echo "You picked $opt which is option $REPLY";;
    2 ) echo "You picked $opt which is option $REPLY";;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo -e "${X_MARK} ${CYAN}Invalid option. Try another one.${NC}";continue;;

    esac

done

exit

usernew="$(whiptail --title "ZelNode Docker Installer v1.0" --inputbox "Enter your username" 8 72 3>&1 1>&2 2>&3)"
echo -e "${YELLOW}Creating new user...${NC}"
adduser "$usernew"
usermod -aG sudo "$usernew"
echo -e "${NC}"
echo -e "${YELLOW}Update and upgrade system...${NC}"
apt update && apt upgrade -y
## if [[ $(cat /proc/1/mountinfo | egrep '/proc/.+lxcfs') ]]
## then
## echo -e "${CHECK_MARK} ${CYAN}LXC container detected${NC}"		
## echo -e "${YELLOW}Installing squashfuse...${NC}"	
## apt install squashfuse -y	
## fi
## echo -e "${NC}"
## echo -e "${YELLOW}Installing snap...${NC}"
## apt install snapd -y
## echo -e "${NC}"
## echo -e "${YELLOW}Installing docker...${NC}"
## snap install docker
## if [[ $(docker -v) != *"Docker"* ]]
## then
## snap install docker
## fi
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

echo -e "${NC}"
echo -e "${YELLOW}Creating docker group..${NC}"
groupadd docker
echo -e "${NC}"
echo -e "${YELLOW}Adding $usernew to docker group...${NC}"
adduser "$usernew" docker
echo -e "${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}Running through some checks...${NC}"
echo -e "${YELLOW}=====================================================${NC}"

if [[ $(docker -v) == *"Docker"* ]]
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
## read -p "Would you like to reboot pc Y/N?" -n 1 -r
## echo -e "${NC}"
##
## if [[ $REPLY =~ ^[Yy]$ ]]
## then
## sudo reboot -n
## fi
