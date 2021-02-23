#!/bin/bash

#information
FLUX_APPS_DIR='ZelApps'
FLUX_DIR='zelflux'
COIN_NAME='zelcash'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
CONFIG_DIR='.zelcash'
CONFIG_FILE='zelcash.conf'
BENCH_NAME='zelbench'
BENCH_DAEMON='zelbenchd'
BENCH_CLI='zelbench-cli'
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

BOOTSTRAP_ZIP='https://fluxnodeservice.com/daemon_bootstrap.tar.gz'
BOOTSTRAP_ZIPFILE='daemon_bootstrap.tar.gz'
BOOTSTRAP_URL_MONGOD='https://fluxnodeservice.com/mongod_bootstrap.tar.gz'
BOOTSTRAP_ZIPFILE_MONGOD='mongod_bootstrap.tar.gz'
KDA_BOOTSTRAP_ZIPFILE='kda_bootstrap.tar.gz'
KDA_BOOTSTRAP_ZIP='https://fluxnodeservice.com/kda_bootstrap.tar.gz'

#dialog color
export NEWT_COLORS='
title=black,
'
# add to path
PATH=$PATH:"$COIN_PATH"
export PATH

call_type="$1"
type="$2"

echo -e "${BOOK}${YELLOW}Helper action: ${GREEN}$1${NC}"

function spinning_timer() 
{
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

function string_limit_check_mark_port() 
{

    if [[ -z "$2" ]]; then
        string="$1"
        string=${string::65}
    else
        string=$1
        string_color=$2
        string_leght=${#string}
        string_leght_color=${#string_color}
        string_diff=$((string_leght_color-string_leght))
        string=${string_color::65+string_diff}
    fi
    echo -e "${PIN}${CYAN}$string[${CHECK_MARK}${CYAN}]${NC}"
}

function string_limit_check_mark() 
{

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

function string_limit_x_mark() 
{

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

function local_version_check() 
{

    local_version=$(dpkg -l $1 | grep -w $1 | awk '{print $3}')  
}

function remote_version_check(){

    #variable null
    remote_version=""
    package_name=""
    
    remote_version=$(curl -s -m 3 https://apt.zel.network/pool/main/z/"$1"/ | grep -o '[0-9].[0-9].[0-9]' | head -n1)
    
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
    echo 'deb https://apt.zel.network/ all main' | sudo tee /etc/apt/sources.list.d/zelcash.list
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

start_fluxdaemon() 
{

    serive_check=$(sudo systemctl list-units --full -all | grep -o "$COIN_NAME.service" | head -n1)

    if [[ "$serive_check" != "" ]]; then
        echo -e "${ARROW} ${CYAN}Starting Flux daemon service...${NC}"
        sudo systemctl start $COIN_NAME >/dev/null 2>&1
    else
        echo -e "${ARROW} ${CYAN}Starting Flux daemon process...${NC}"
        "$COIN_DAEMON" >/dev/null 2>&1
    fi
    
}

stop_fluxdaemon() {

    echo -e "${ARROW} ${CYAN}Stopping Flux daemon...${NC}"
    sudo systemctl stop $COIN_NAME >/dev/null 2>&1 && sleep 5
    "$COIN_CLI" stop >/dev/null 2>&1 && sleep 5
    sudo killall "$COIN_DAEMON" >/dev/null 2>&1
    sudo killall -s SIGKILL $BENCH_NAME >/dev/null 2>&1 && sleep 1
    sleep 4

}


function reindex()
{
    echo -e "${ARROW} ${CYAN}Reindexing...${NC}"
    stop_fluxdaemon
    "$COIN_DAEMON" -reindex
    serive_check=$(sudo systemctl list-units --full -all | grep -o "$COIN_NAM.service" | head -n1)
    if [[ "$serive_check" != "" ]]; then
        sleep 60
        stop_fluxdaemon
        start_fluxdaemon
    fi
}

function restart_fluxdaemon()
{

    echo -e "${ARROW} ${CYAN}Restarting Flux daemon...${NC}"
    serive_check=$(sudo systemctl list-units --full -all | grep -o "$COIN_NAME.service" | head -n1)
    if [[ "$serive_check" != "" ]]; then
        sudo systemctl restart $COIN_NAME >/dev/null 2>&1 && sleep 3
       else
        stop_fluxdaemon
        start_fluxdaemon
    fi

}

function fluxbench_update()
{

    local_version=$(dpkg -l $BENCH_NAME | grep -w "$BENCH_NAME" | awk '{print $3}')

    if [[ "$type" == "force" ]]; then
        echo -e "${ARROW} ${CYAN}Force Flux benchmark updating...${NC}"
        stop_fluxdaemon
        install_package $BENCH_NAME
        dpkg_version_after_install=$(dpkg -l $BENCH_NAME | grep -w "$BENCH_NAME" | awk '{print $3}')
        echo -e "${ARROW} ${CYAN}Flux benchmark version before update: ${GREEN}$local_version${NC}"
        echo -e "${ARROW} ${CYAN}Flux benchmark version after update: ${GREEN}$dpkg_version_after_install${NC}"
        start_fluxdaemon
        return
    fi

    remote_version_check "$BENCH_NAME"
    #remote_version=$(curl -s -m 3 https://zelcore.io/zelflux/zelbenchinfo.php | jq -r .version)

    if [[ "$call_type" != "update_all" ]]; then

        if [[ "$remote_version" == "" ]]; then
            echo -e "${ARROW} ${CYAN}Problem with version veryfication...Flux benchmark installation skipped...${NC}"
            return
        fi

        if [[ "$remote_version" == "$local_version" ]]; then
            echo -e "${ARROW} ${CYAN}You have the current version of Flux benchamrk ${GREEN}($remote_version)${NC}"
            return
        fi

    fi

    echo -e "${ARROW} ${CYAN}Updating Flux benchmark...${NC}"
    #stop_zelcash
    echo -e "${ARROW} ${CYAN}Flux benchmark stopping...${NC}"
    $BENCH_CLI stop >/dev/null 2>&1 && sleep 2
    sudo killall -s SIGKILL $BENCH_DAEMON >/dev/null 2>&1 && sleep 1
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install --only-upgrade $BENCH_NAME -y >/dev/null 2>&1
    sudo chmod 755 "$COIN_PATH"/$BENCH_NAME*
    sleep 2

    dpkg_version_after_install=$(dpkg -l $BENCH_NAME | grep -w "$BENCH_NAME" | awk '{print $3}')
    echo -e "${ARROW} ${CYAN}Flux benchmark version before update: ${GREEN}$local_version${NC}"
    #echo -e "${ARROW} ${CYAN}Zelbench version after update: ${GREEN}$dpkg_version_after_install${NC}"

    if [[ "$dpkg_version_after_install" == "" ]]; then

        install_package "$BENCH_NAME"
        dpkg_version_after_install=$(dpkg -l $BENCH_NAME | grep -w "$BENCH_NAME" | awk '{print $3}')
    
        if [[ "$dpkg_version_after_install" != "" ]]; then
            echo -e "${ARROW} ${CYAN}Flux benchmark update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
        fi

        start_fluxdaemon
        echo -e "${ARROW} ${CYAN}Flux benchmark starting...${NC}"
        #zelbenchd -daemon >/dev/null 2>&1
    else

        if [[ "$remote_version" == "$dpkg_version_after_install" ]]; then
  
            echo -e "${ARROW} ${CYAN}Flux benchmark update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
            start_fluxdaemon
            echo -e "${ARROW} ${CYAN}Flux benchmark starting...${NC}"
            #zelbenchd -daemon >/dev/null 2>&1
        else

            if [[ "$local_version" == "$dpkg_version_after_install" ]]; then
	    
                install_package $BENCH_NAME
                dpkg_version_after_install=$(dpkg -l $BENCH_NAME | grep -w "$BENCH_NAME" | awk '{print $3}')
    
                if [[ "dpkg_version_after_install" == "$remote_version" ]]; then
		
                    echo -e "${ARROW} ${CYAN}Flux benchmark update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
		    
                fi
		
                start_fluxdaemon
		echo -e "${ARROW} ${CYAN}Flux benchmark starting...${NC}"
		#zelbenchd -daemon >/dev/null 2>&1
            fi
        fi
    fi

}

function flux_update()
{

	current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
	required_ver=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')

    if [[ "$required_ver" != "" && "$call_type" != "update_all" ]]; then
	
        if [ "$(printf '%s\n' "$required_ver" "$current_ver" | sort -V | head -n1)" = "$required_ver" ]; then 
	    
            echo -e "${ARROW} ${CYAN}You have the current version of Flux ${GREEN}($required_ver)${NC}"  
            return 
	    
        else
            #echo -e "${HOT} ${CYAN}New version of Flux available ${SEA}$required_ver${NC}"
            FLUX_UPDATE="1"
        fi
       
    fi

    if [[ "$FLUX_UPDATE" == "1" ]]; then
        cd /home/$USER/$FLUX_DIR && git pull > /dev/null 2>&1 && cd
        current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
        required_ver=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')
        if [[ "$required_ver" == "$current_ver" ]]; then
            echo -e "${ARROW} ${CYAN}Flux updated successfully ${GREEN}($required_ver)${NC}"
        else
            echo -e "${ARROW} ${CYAN}Flux was not updated.${NC}"
            echo -e "${ARROW} ${CYAN}Flux force update....${NC}"
            rm /home/$USER/$FLUX_DIR/.git/HEAD.lock >/dev/null 2>&1
            #cd /home/$USER/$FLUX_DIR && npm run hardupdatezelflux
            cd /home/$USER/$FLUX_DIR && git reset --hard HEAD && git clean -f -d && git pull

            current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
            required_ver=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')

            if [[ "$required_ver" == "$current_ver" ]]; then
                echo -e "${ARROW} ${CYAN}Flux updated successfully ${GREEN}($required_ver)${NC}"
            fi
        fi

    else
    
        echo -e "${ARROW} ${CYAN}Problem with version veryfication...Flux installation skipped...${NC}"
    fi

}

function fluxdaemon_update()
{

    local_version=$(dpkg -l $COIN_NAME | grep -w "$COIN_NAME" | awk '{print $3}')

    if [[ "$type" == "force" ]]; then
        echo -e "${ARROW} ${CYAN}Force Flux daemon updating...${NC}"
        stop_fluxdaemon
        install_package "$COIN_NAME"
        dpkg_version_after_install=$(dpkg -l $COIN_NAME | grep -w "$COIN_NAME" | awk '{print $3}')
        echo -e "${ARROW} ${CYAN}Flux daemon version before update: ${GREEN}$local_version${NC}"
        echo -e "${ARROW} ${CYAN}Flux daemon version after update: ${GREEN}$dpkg_version_after_install${NC}"
        start_fluxdaemon
        return
    fi


    remote_version_check "$COIN_NAME"
    #local_version=$($COIN_CLI getinfo | jq -r .version)
    #remote_version=$(curl -s -m3  https://zelcore.io/zelflux/zelcashinfo.php | jq -r .version)

    if [[ "$call_type" != "update_all" ]]; then

        if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
	
            echo -e "${ARROW} ${CYAN}Problem with version veryfication...Flux daemon installation skipped...${NC}"
            return
	    
        fi

        if [[ "$local_version" == "$remote_version" ]]; then
	
            echo -e "${ARROW} ${CYAN}You have the current version of Flux daemon ${GREEN}($remote_version)${NC}"
            return
	    
        fi
	
    fi

    dpkg_version_before_install=$(dpkg -l $COIN_NAME | grep -w "$COIN_NAME" | awk '{print $3}')
    stop_fluxdaemon

    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install --only-upgrade $COIN_NAME -y >/dev/null 2>&1
    sudo chmod 755 "$COIN_PATH"/$COIN_NAME*
    sleep 2

    dpkg_version_after_install=$(dpkg -l $COIN_NAME | grep -w "$COIN_NAME" | awk '{print $3}')
    echo -e "${ARROW} ${CYAN}Flux daemon version before update: ${GREEN}$local_version${NC}"
    #echo -e "${ARROW} ${CYAN}Flux daemon version after update: ${GREEN}$dpkg_version_after_install${NC}"

    if [[ "$dpkg_version_after_install" == "" ]]; then

        install_package "$COIN_NAME"
        dpkg_version_after_install=$(dpkg -l $COIN_NAME | grep -w "$COIN_NAME" | awk '{print $3}')

        if [[ "$dpkg_version_after_install" != "" ]]; then
	
            echo -e "${ARROW} ${CYAN}Flux daemon update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
        fi

        start_fluxdaemon

    else

        if [[ "$local_version" != "$dpkg_version_after_install" ]]; then
  
            echo -e "${ARROW} ${CYAN}Flux daemon update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
            start_fluxdaemon
	    
        fi

        if [[ "local_version" == "$dpkg_version_after_install" ]]; then
	
            install_package "$COIN_NAME"
            dpkg_version_after_install=$(dpkg -l $COIN_NAME | grep -w "$COIN_NAME" | awk '{print $3}')
    
            if [[ "$dpkg_version_after_install" == "$remote_version" ]]; then
	    
                echo -e "${ARROW} ${CYAN}Flux daemon update successful ${CYAN}(${GREEN}$dpkg_version_after_install${CYAN})${NC}"
            fi
    
            start_fluxdaemon
        fi

    fi

}

function check_update() 
{

    update_fluxbench="0"
    update_fluxdaemon="0"
    update_flux="0"

    local_version_check "$COIN_NAME"
    remote_version_check "$COIN_NAME"

    if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
        echo -e "${RED}${ARROW} ${CYAN}Problem with version veryfication...Flux daemon installation skipped...${NC}"
    else

        if [[ "$local_version" != "$remote_version" ]]; then
	
            echo -e "${RED}${HOT}${CYAN}New version of Flux daemon available ${SEA}$remote_version${NC}"
            update_fluxdaemon="1"
	    
        else
	
            echo -e "${ARROW} ${CYAN}You have the current version of Flux daemon ${GREEN}($remote_version)${NC}"
	    
        fi
  
    fi

    local_version_check "$BENCH_NAME"
    remote_version_check "$BENCH_NAME"

    if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
        echo -e "${RED}${ARROW} ${CYAN}Problem with version veryfication...Flux benchmark installation skipped...${NC}"
    else

        if [[ "$local_version" != "$remote_version" ]]; then
	
            echo -e "${RED}${HOT}${CYAN}New version of Flux benchmark available ${SEA}$remote_version${NC}"
            update_fluxbench="1"
	    
        else
	
            echo -e "${ARROW} ${CYAN}You have the current version of Flux benchmark ${GREEN}($remote_version)${NC}"
	    
        fi

    fi

    local_version=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
    remote_version=$(curl -s -m 3 https://raw.githubusercontent.com/zelcash/zelflux/master/package.json | jq -r '.version')

    if [[ "$local_version" == "" || "$remote_version" == "" ]]; then
        echo -e "${RED}${ARROW} ${CYAN}Problem with version veryfication...Flux installation skipped...${NC}"
    else

        if [[ "$local_version" != "$remote_version" ]]; then
	
            echo -e "${RED}${HOT}${CYAN}New version of Flux available ${SEA}$remote_version${NC}"
            update_flux="1"
            FLUX_UPDATE="1"
	    
        else
	
            echo -e "${ARROW} ${CYAN}You have the current version of Flux ${GREEN}($remote_version)${NC}"
	    
        fi

    fi

    if [[ "$update_fluxbench" == "1" || "$update_fluxdaemon" == "1" || "$update_flux" == "1" ]]; then
        echo -e ""
    fi

}

#tar_file_unpack file/file_path dir_to_compress
function tar_file_unpack()
{
    echo -e "${ARROW} ${YELLOW}Unpacking bootstrap archive file...${NC}"
    pv $1 | tar -zx -C $2
}


#tar_file_pack path_to_pack path_to_archive_file_to_save
function tar_file_pack()
{
    echo -e "${ARROW} ${YELLOW}Creating bootstrap archive file...${NC}"
    tar -c --use-compress-program=pigz -f $2 $1
    #tar -czf --use-compress-program=pigz - $1 | (pv -p --timer --rate --bytes > $2) 2>&1
}




#check_tar file_name
function check_tar()
{
    echo -e "${ARROW} ${YELLOW}Checking  bootstrap file integration...${NC}"
    
    if gzip -t "$1" &>/dev/null; then
    
        echo -e "${ARROW} ${CYAN}Bootstrap file is valid.................[${CHECK_MARK}${CYAN}]${NC}"
	
    else
    
        echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
	rm -rf $1
	
    fi

}


function create_daemon_bootstrap()
{

    sudo apt install zip >/dev/null 2>&1

    if "$COIN_CLI" getinfo > /dev/null 2>&1; then


        local_network_hight=$("$COIN_CLI" getinfo | jq -r .blocks)
        echo -e "${ARROW} ${CYAN}Local Network Block Hight: ${GREEN}$local_network_hight${NC}"
        explorer_network_hight=$(curl -s -m 3 https://explorer.zel.network/api/status?q=getInfo | jq '.info.blocks')
        echo -e "${ARROW} ${CYAN}Global Network Block Hight: ${GREEN}$explorer_network_hight${NC}"

        if [[ "$explorer_network_hight" == "" || "$local_network_hight" == "" ]]; then
    
            echo -e "${ARROW} ${CYAN}Flux network veryfication failed...${NC}"
            return
	
        fi
 

        check_height=$((explorer_network_hight-local_network_hight))

        if [[ "$check_height" -lt 0 ]]; then
    
                check_height=$((check_height*(-1)))	
		
        fi

        if [[ "$check_height" -lt 15 ]]; then
    
                echo -e "${ARROW} ${CYAN}Local and Global network are synced, diff: ${GREEN}$check_height${NC}"
	else
    
                echo -e "${ARROW} ${CYAN}Local and Global network are not synced, try again later (diff: ${RED}$check_height${CYAN})${NC}"
                return	
        fi
    
        data=$(date -u)
        unix=$(date +%s)
        stop_fluxdaemon
        check_zip=$(zip -L | head -n1)
    
        if [[ "$check_zip" != "" ]]; then
	
            echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
            rm -rf /home/$USER/$BOOTSTRAP_ZIPFILE >/dev/null 2>&1 && sleep 5
            #echo -e "${ARROW} ${CYAN}Flux daemon bootstrap creating...${NC}"
            cd /home/$USER/$CONFIG_DIR  
	    tar_file_pack "blocks chainstate determ_zelnodes" "/home/$USER/$BOOTSTRAP_ZIPFILE"
            #zip /home/$USER/$BOOTSTRAP_ZIPFILE -r blocks chainstate determ_zelnodes
            cd

            if [[ -f /home/$USER/$BOOTSTRAP_ZIPFILE ]]; then
	    
                echo -e "${ARROW} ${CYAN}Flux daemon bootstrap created successful ${GREEN}($local_network_hight)${NC}"
                rm -rf /home/$USER/daemon_bootstrap.json >/dev/null 2>&1

                sudo touch /home/$USER/daemon_bootstrap.json
                sudo chown $USER:$USER /home/$USER/daemon_bootstrap.json
	        cat << EOF > /home/$USER/daemon_bootstrap.json
		{
		"block_height": "${explorer_network_hight}",
		"time": "${data}",
		"unix_timestamp": "${unix}"
		}
EOF
            else
	    
                echo -e "${ARROW} ${CYAN}Flux daemon bootstrap creating failed${NC}"
	
            fi

        fi
    
        start_fluxdaemon

    else
    
        echo -e "${ARROW} ${CYAN}Flux network veryfication failed...Flux daemon not working...${NC}"
        echo
	
    fi

}

function create_mongod_bootstrap()
{
    
    WANIP=$(wget --timeout=3 --tries=2 http://ipecho.net/plain -O - -q)
    
    if [[ "$WANIP" == "" ]]; then
    
        WANIP=$(curl -s -m 3 ifconfig.me) 
	
        if [[ "$WANIP" == "" ]]; then
	
            echo -e "${ARROW} ${CYAN}Public IP address could not be found, action stopped .........[${X_MARK}${CYAN}]${NC}"
            echo
	    exit
	    
    	fi
    fi

    local_network_hight=$(curl -s -m 3 http://"$WANIP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
    echo -e "${ARROW} ${CYAN}Mongod Network Block Hight: ${GREEN}$local_network_hight${NC}"
    explorer_network_hight=$(curl -s -m 3 https://explorer.zel.network/api/status?q=getInfo | jq '.info.blocks')
    echo -e "${ARROW} ${CYAN}Global Network Block Hight: ${GREEN}$explorer_network_hight${NC}"

    if [[ "$explorer_network_hight" == "" || "$local_network_hight" == "" ]]; then
    
        echo -e "${ARROW} ${CYAN}Flux network veryfication failed...${NC}"
        return
	
    fi

    check_height=$((explorer_network_hight-local_network_hight))

    if [[ "$check_height" -lt 0 ]]; then
    
        check_height=$((check_height*(-1)))
	
    fi

    if [[ "$check_height" -lt 15 ]]; then
    
        echo -e "${ARROW} ${CYAN}Local and Global network are synced, diff: ${GREEN}$check_height${NC}"
	
    else
    
        echo -e "${ARROW} ${CYAN}Local and Global network are not synced, try again later (diff: ${RED}$check_height${CYAN})${NC}"
        return
	
    fi

    data=$(date -u)
    unix=$(date +%s)
    echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
    sudo rm -rf /home/$USER/dump >/dev/null 2>&1 && sleep 2
    sudo rm -rf /home/$USER/$BOOTSTRAP_ZIPFILE_MONGOD >/dev/null 2>&1 && sleep 2

    echo -e "${ARROW} ${CYAN}Exporting Mongod datetable...${NC}"
    mongodump --port 27017 --db zelcashdata --out /home/$USER/dump/ >/dev/null 2>&1

    tar_file_pack "dump" "/home/$USER/$BOOTSTRAP_ZIPFILE_MONGOD"
    #tar -cvzf /home/$USER/$BOOTSTRAP_ZIPFILE_MONGOD dump
    sudo rm -rf /home/$USER/dump >/dev/null 2>&1 && sleep 2

    if [[ -f /home/$USER/$BOOTSTRAP_ZIPFILE_MONGOD ]]; then
        echo -e "${ARROW} ${CYAN}Mongod bootstrap created successful ${GREEN}($local_network_hight)${NC}"
        rm -rf /home/$USER/mongodb_bootstrap.json >/dev/null 2>&1

        sudo touch /home/$USER/mongodb_bootstrap.json
        sudo chown $USER:$USER /home/$USER/mongodb_bootstrap.json
	cat << EOF > /home/$USER/mongodb_bootstrap.json
	{
	"block_height": "${explorer_network_hight}",
	"time": "${data}",
	"unix_timestamp": "${unix}"
	}
EOF
	
    else
    
        echo -e "${ARROW} ${CYAN}Mongod bootstrap creating failed${NC}"
	
    fi

}

function clean_mongod() {

    echo -e "${ARROW} ${CYAN}Stopping Flux...${NC}"
    pm2 stop flux >/dev/null 2>&1 && sleep 2
    echo -e "${ARROW} ${CYAN}Stopping MongoDB...${NC}"
    sudo systemctl stop mongod >/dev/null 2>&1 && sleep 2
    echo -e "${ARROW} ${CYAN}Removing MongoDB datatable...${NC}"
    sudo rm -r /var/lib/mongodb >/dev/null 2>&1 && sleep 2
    install_mongod
    mongodb_bootstrap
    
}


function mongodb_bootstrap(){

    WANIP=$(wget --timeout=3 --tries=2 http://ipecho.net/plain -O - -q)
    
    if [[ "$WANIP" == "" ]]; then
    
        WANIP=$(curl -s -m 3 ifconfig.me) 
	
        if [[ "$WANIP" == "" ]]; then
	
            echo -e "${ARROW} ${CYAN}Public IP address could not be found, action stopped .........[${X_MARK}${CYAN}]${NC}"
            echo
	    exit
	    
    	fi
    fi
    
    BLOCKHIGHT=100
     #DB_HIGHT=$(curl -s -m 3 https://fluxnodeservice.com/mongodb_bootstrap.json | jq -r '.block_height')
    DB_HIGHT=$(curl -s -m 3 https://fluxnodeservice.com/mongodb_bootstrap.json | jq -r '.block_height')
    echo -e "${ARROW} ${CYAN}Bootstrap block hight: ${GREEN}$DB_HIGHT${NC}"

    if [[ "$BLOCKHIGHT" -gt "0" && "$BLOCKHIGHT" -lt "$DB_HIGHT" ]]; then
    
        echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$BOOTSTRAP_URL_MONGOD${NC}"
        wget $BOOTSTRAP_URL_MONGOD -q --show-progress 
        echo -e "${ARROW} ${CYAN}Unpacking...${NC}"
        #tar xvf $BOOTSTRAP_ZIPFILE_MONGOD -C /home/$USER > /dev/null 2>&1 && sleep 1
        tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE_MONGOD" "/home/$USER" 

        echo -e "${ARROW} ${CYAN}Importing mongodb datatable...${NC}"
        mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop
        echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
        sudo rm -rf /home/$USER/dump > /dev/null 2>&1 && sleep 1
        sudo rm -rf $BOOTSTRAP_ZIPFILE_MONGOD > /dev/null 2>&1  && sleep 1
        pm2 start flux > /dev/null 2>&1
        pm2 save > /dev/null 2>&1

        NUM='120'
        MSG1='Flux starting...'
        MSG2="${CYAN}.....................[${CHECK_MARK}${CYAN}]${NC}"
        spinning_timer
        echo
        BLOCKHIGHT_AFTER_BOOTSTRAP=$(curl -s -m 3 http://"$WANIP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
        echo -e ${ARROW} ${CYAN}Node block hight after restored: ${GREEN}$BLOCKHIGHT_AFTER_BOOTSTRAP${NC}

        if [[ "$BLOCKHIGHT" != "" ]]; then

            if [[ "$BLOCKHIGHT" -gt "0" && "$BLOCKHIGHT" -lt "$DB_HIGHT" ]]; then
	    
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
    fi

}

function install_mongod() {
   
    sudo rm /etc/apt/sources.list.d/mongodb*.list > /dev/null 2>&1
    if [[ $(lsb_release -r) = *16.* ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
    elif [[ $(lsb_release -r) = *18.* || $(lsb_release -r) = *19.*  ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
    elif [[ $(lsb_release -r) = *20.*   ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.4 main" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *10* ]]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc 2> /dev/null | sudo apt-key add - > /dev/null 2>&1
        echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" 2> /dev/null | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list > /dev/null 2>&1
	
    else
   	  echo -e "${WORNING}${CYAN}ERROR: OS version not supported: $(lsb_release -d)"
   	  echo -e "${WORNING}${CYAN}Installation stopped..."
	  echo
   	  exit
    fi
    
    sleep 2 
    echo -e "${ARROW} ${YELLOW}Removing any instances of Mongodb...${NC}"
    sudo apt remove mongod* -y > /dev/null 2>&1 && sleep 1
    sudo apt purge mongod* -y > /dev/null 2>&1 && sleep 1
    sudo apt autoremove -y > /dev/null 2>&1 && sleep 1
    echo -e "${ARROW} ${YELLOW}Mongodb installing...${NC}"
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get install mongodb-org -y > /dev/null 2>&1 && sleep 2
    sudo systemctl enable mongod > /dev/null 2>&1
    sudo systemctl start  mongod > /dev/null 2>&1
    
    if mongod --version > /dev/null 2>&1 
    then
        #echo -e "${ARROW} ${CYAN}MongoDB version: ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed${NC}"
        string_limit_check_mark "MongoDB $(mongod --version | grep 'db version' | sed 's/db version.//') installed................................." "MongoDB ${GREEN}$(mongod --version | grep 'db version' | sed 's/db version.//')${CYAN} installed................................."
        echo
    else
        #echo -e "${ARROW} ${CYAN}MongoDB was not installed${NC}" 
        string_limit_x_mark "MongoDB was not installed................................."
        echo
    fi
}

function swapon_create()
{
    MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    gb=$(awk "BEGIN {print $MEM/1048576}")
    GB=$(echo "$gb" | awk '{printf("%d\n",$1 + 0.5)}')
    if [ "$GB" -lt 2 ]; then
        (( swapsize=GB*2 ))
        swap="$swapsize"G
        #echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -ge 2 ]] && [[ $GB -le 16 ]]; then
        swap=4G
       # echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -gt 16 ]] && [[ $GB -lt 32 ]]; then
        swap=2G
        #echo -e "${YELLOW}Swap set at $swap...${NC}"
    fi
    
    if ! grep -q "swapfile" /etc/fstab; then
    
        if whiptail --yesno "No swapfile detected would you like to create one?" 8 54; then
            sudo fallocate -l "$swap" /swapfile > /dev/null 2>&1
            sudo chmod 600 /swapfile > /dev/null 2>&1
            sudo mkswap /swapfile > /dev/null 2>&1
            sudo swapon /swapfile > /dev/null 2>&1
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null 2>&1
            echo -e "${ARROW} ${YELLOW}Created ${SEA}${swap}${YELLOW} swapfile${NC}"
        else
            echo -e "${ARROW} ${YELLOW}Creating a swapfile skipped...${NC}"
        fi
	
    fi
}



function unlock_flux_resouce()
{

     docker_check=$(docker ps |  grep -Eo "^[0-9a-z]{8,}\b"  | wc -l)
     resource_check=$(df | egrep 'flux' | awk '{ print $1}' | wc -l)
     mongod_check=$(mongoexport -d localzelapps -c zelappsinformation --jsonArray --pretty --quiet  | jq -r .[].name | head -n1)

    if [[ "$mongod_check" != "" && "$mongod_check" != "null" && "$1" == "clean_db" ]]; then
    
        echo -e "${ARROW} ${YELLOW}Detected Flux MongoDB local apps collection ...${NC}" && sleep 1
        echo -e "${ARROW} ${CYAN}Cleaning MongoDB Flux local apps collection...${NC}" && sleep 1
        echo "db.zelappsinformation.drop()" | mongo localzelapps > /dev/null 2>&1
	
    fi

    if [[ $docker_check != 0 ]]; then
        echo -e "${ARROW} ${YELLOW}Detected running docker container...${NC}" && sleep 1
        echo -e "${ARROW} ${CYAN}Stopping containers...${NC}"
        docker ps | grep -Eo "^[0-9a-z]{8,}\b" |
	
        while read line; do
            sudo docker stop $line && sleep 2
	    sudo docker rm $line && sleep 2
        done
    fi

    if [[ $resource_check != 0 ]]; then
        echo -e "${ARROW} ${YELLOW}Detected locked resource${NC}" && sleep 1
        echo -e "${ARROW} ${CYAN}Unmounting locked Flux resource${NC}" && sleep 1
        df | egrep 'flux' | awk '{ print $1}' |

        while read line; do
        sudo umount $line && sleep 1
        done	
    fi
    
    echo
}

function max(){

    local m="$1"
    for n in "$@"
    do
        [ "$n" -gt "$m" ] && m="$n"
    done
    echo "$m"
    
}

function create_kda_bootstrap {

    kda_bootstrap_daemon="0"

    WANIP=$(wget --timeout=3 --tries=2 http://ipecho.net/plain -O - -q) 
    if [[ "$WANIP" == "" ]]; then
        WANIP=$(curl -s -m 3 ifconfig.me)     
        if [[ "$WANIP" == "" ]]; then
            echo -e "${ARROW} ${CYAN}Local IP address could not be found, action stopped .........[${X_MARK}${CYAN}]${NC}"
	    echo
	    exit
    	 fi
    fi
    
    if [ ! -d /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode/chainweb-db ]; then
        echo -e "${ARROW} ${CYAN}Kadena Node chain directory does not exist, operation stopped...${NC}"
        echo
        exit
    fi
    
    network_height_node_01=$(curl -sk -m 3 https://us-e1.chainweb.com/chainweb/0.0/mainnet01/cut | jq '.height')
    network_height_node_02=$(curl -sk -m 3 https://us-e2.chainweb.com/chainweb/0.0/mainnet01/cut | jq '.height')
    network_height_node_03=$(curl -sk -m 3 https://fr1.chainweb.com/chainweb/0.0/mainnet01/cut | jq '.height')

    network_height=$(max "$network_height_node_01" "$network_height_node_02" "$network_height_node_03")
    echo -e "${ARROW} ${CYAN}Kadena Global Network Height: ${GREEN}$network_height${NC}"
    kda_height=$(curl -sk https://$WANIP:30004/chainweb/0.0/mainnet01/cut | jq '.height')
    echo -e "${ARROW} ${CYAN}Kadena Local Node Height: ${GREEN}$kda_height${NC}"

    check_height=$((network_height-kda_height))

    if [[ "$check_height" -lt 0 ]]; then
        check_height=$((check_height*(-1)))
    fi

    if [[ "$check_height" -lt 2000 ]]; then
        echo -e "${ARROW} ${CYAN}Local and Global network are synced, diff: ${GREEN}$check_height${NC}"
        echo
    else
        echo -e "${ARROW} ${CYAN}Local and Global network are not synced, try again later (diff: ${RED}$check_height${CYAN})${NC}"
        echo
        exit
    fi

    if [[ "$kda_height" != "" && "$kda_height" != "null" ]]; then

        sudo rm -rf /home/$USER/$KDA_BOOTSTRAP_ZIPFILE >/dev/null 2>&1 && sleep 2

        data=$(date -u)
        unix=$(date +%s)
        docker_check=$(docker ps | grep 'zelKadenaChainWebNode' | wc -l)

        if [[ "$docker_check" != "" && "$docker_check" != "0" ]]; then

            echo -e "${ARROW} ${CYAN}Stopping Kadena Node...${NC}"
            docker stop zelKadenaChainWebNode > /dev/null 2>&1

            echo -e "${ARROW} ${CYAN}Bootstrap file creating...${NC}"
            cd /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode  	    
            #zip /home/$USER/$KDA_BOOTSTRAP_ZIPFILE -r chainweb-db
	    tar_file_pack "chainweb-db" "/home/$USER/$KDA_BOOTSTRAP_ZIPFILE"
            cd

            if [[ -f /home/$USER/$KDA_BOOTSTRAP_ZIPFILE ]]; then
                kda_bootstrap_daemon="1"
                rm -rf /home/$USER/kda_bootstrap.json >/dev/null 2>&1

                sudo touch /home/$USER/kda_bootstrap.json
                sudo chown $USER:$USER /home/$USER/kda_bootstrap.json
		cat << EOF > /home/$USER/kda_bootstrap.json
		{
		"block_height": "${kda_height}",
		"time": "${data}",
		"unix_timestamp": "${unix}"
		}
EOF
            fi

            echo -e "${ARROW} ${CYAN}Starting Kadena Node...${NC}"
            docker start zelKadenaChainWebNode > /dev/null 2>&1

        fi
	
    fi


    if [[ "$kda_bootstrap_daemon" == "0" ]]; then
        echo -e "${ARROW} ${CYAN}Kadena Node bootstrap creating failed...${NC}"
    else
        echo -e "${ARROW} ${CYAN}Kadena Node bootstrap created successful ${GREEN}($kda_height)${NC}"
    fi

}

function daemon_bootstrap() {


    echo -e "${ARROW} ${CYAN}Stopping Flux daemon service${NC}"
    sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
    sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1

    if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
        echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
        rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate ~/$CONFIG_DIR/determ_zelnodes
    fi


    if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
    
        echo -e "${ARROW} ${CYAN}Local bootstrap file detected...${NC}"
        check_tar "/home/$USER/$BOOTSTRAP_ZIPFILE"   
	
    fi


    if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
    
     
	tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
	sleep 2
        #unzip -o $KDA_BOOTSTRAP_ZIPFILE -d /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode > /dev/null 2>&1
	
    else

        echo -e "${ARROW} ${CYAN}Bootstrap file downloading...${NC}" && sleep 2

        CHOICE=$(
        whiptail --title "Bootstrap installation" --menu "Choose a method how to get bootstrap file" 10 47 2  \
            "1)" "Download from source build in script" \
            "2)" "Download from own source" 3>&2 2>&1 1>&3
        )


            case $CHOICE in
	    "1)")   
	         DB_HIGHT=$(curl -s -m 3 https://fluxnodeservice.com/daemon_bootstrap.json | jq -r '.block_height')
		 echo -e "${ARROW} ${CYAN}Flux daemon bootstrap height: ${GREEN}$DB_HIGHT${NC}"
		 echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
       		 wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
		 tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR" 
		 sleep 2

	    ;;
	    "2)")   
  		 BOOTSTRAP_ZIP="$(whiptail --title "Flux daemon bootstrap source" --inputbox "Enter your URL" 8 72 3>&1 1>&2 2>&3)"
		 echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
		 wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress		 
		 tar_file_unpack "/home/$USER/BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
		 sleep 2
		 #unzip -o $KDA_BOOTSTRAP_ZIPFILE -d /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode > /dev/null 2>&1
	    ;;
            esac

    fi

    if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
        rm -rf $BOOTSTRAP_ZIPFILE
    fi

    sudo systemctl start $COIN_NAME  > /dev/null 2>&1 && sleep 2
    NUM='35'
    MSG1='Starting Flux daemon service...'
    MSG2="${CYAN}........................[${CHECK_MARK}${CYAN}]${NC}"
    spinning_timer
    echo -e "" && echo -e ""

}

function kda_bootstrap() {

    sudo chown -R $USER:$USER /home/$USER/$FLUX_DIR
    echo -e "${ARROW} ${CYAN}Stopping Kadena Node...${NC}"
    docker stop zelKadenaChainWebNode > /dev/null 2>&1

    if [[ -e /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode/chainweb-db  ]]; then
        echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
        rm -rf /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode/chainweb-dbs
    fi


    if [ -f "/home/$USER/$KDA_BOOTSTRAP_ZIPFILE" ]; then
    
        echo -e "${ARROW} ${CYAN}Local bootstrap file detected...${NC}"
        check_tar "/home/$USER/$KDA_BOOTSTRAP_ZIPFILE"   
	
    fi


    if [ -f "/home/$USER/$KDA_BOOTSTRAP_ZIPFILE" ]; then
    
	tar_file_unpack "/home/$USER/$KDA_BOOTSTRAP_ZIPFILE" "/home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode"
	sleep 2
        #unzip -o $KDA_BOOTSTRAP_ZIPFILE -d /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode > /dev/null 2>&1
	
    else

        echo -e "${ARROW} ${CYAN}Bootstrap file downloading...${NC}" && sleep 2

        CHOICE=$(
        whiptail --title "Bootstrap installation" --menu "Choose a method how to get bootstrap file" 10 47 2  \
            "1)" "Download from source build in script" \
            "2)" "Download from own source" 3>&2 2>&1 1>&3
        )


            case $CHOICE in
	    "1)")   
	         DB_HIGHT=$(curl -s -m 3 https://fluxnodeservice.com/kda_bootstrap.json | jq -r '.block_height')
		 echo -e "${ARROW} ${CYAN}KDA Bootstrap height: ${GREEN}$DB_HIGHT${NC}"
		 echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$KDA_BOOTSTRAP_ZIP ${NC}"
       		 wget -O $KDA_BOOTSTRAP_ZIPFILE $KDA_BOOTSTRAP_ZIP -q --show-progress
		 tar_file_unpack "/home/$USER/$KDA_BOOTSTRAP_ZIPFILE" "/home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode" 
		 sleep 2

	    ;;
	    "2)")   
  		 KDA_BOOTSTRAP_ZIP="$(whiptail --title "Kadena node bootstrap source (*.tar.gz, *.zip file supported)" --inputbox "Enter your URL" 8 72 3>&1 1>&2 2>&3)"
		 KDA_BOOTSTRAP_ZIPFILE="${KDA_BOOTSTRAP_ZIP##*/}"
		 echo -e "${ARROW} ${CYAN}Downloading File: ${GREEN}$KDA_BOOTSTRAP_ZIP ${NC}"
		 wget -O $KDA_BOOTSTRAP_ZIPFILE $KDA_BOOTSTRAP_ZIP -q --show-progress	
		 
		 if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
 		    echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
                    unzip -o $KDA_BOOTSTRAP_ZIPFILE -d /home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode > /dev/null 2>&1
		else	       
		    tar_file_unpack "/home/$USER/$KDA_BOOTSTRAP_ZIPFILE" "/home/$USER/$FLUX_DIR/$FLUX_APPS_DIR/zelKadenaChainWebNode"
		   
		fi		
		  sleep 2
	    ;;
            esac

    fi

    if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
        rm -rf $KDA_BOOTSTRAP_ZIPFILE
    fi

    docker start zelKadenaChainWebNode > /dev/null 2>&1
    NUM='15'
    MSG1='Starting Kadena Node...'
    MSG2="${CYAN}........................[${CHECK_MARK}${CYAN}]${NC}"
    spinning_timer
    echo -e "" 
    echo -e "${ARROW} ${CYAN}Kadena Node initial process can take about ~15min. ${NC}"
    echo -e "" 

}

if ! pv -V > /dev/null 2>&1
then
sudo apt-get install -y pv > /dev/null 2>&1
fi

if ! gzip -V > /dev/null 2>&1
then
sudo apt-get install -y gzip > /dev/null 2>&1
fi

if ! zip -v > /dev/null 2>&1
then
sudo apt-get install -y zip > /dev/null 2>&1
fi

if ! pigz -V > /dev/null 2>&1
then
sudo apt-get install -y pigz > /dev/null 2>&1
fi





    case $call_type in

        "update_all")
		 
            check_update
                if [[ "$update_flux" == "1" ]]; then
                    flux_update
                fi

                if [[ "$update_fluxbench" == "1" ]]; then
                    fluxbench_update
                fi

                if [[ "$update_fluxdaemon" == "1" ]]; then
                   fluxdaemon_update
                fi
                echo
        ;;

        "fluxdaemon_update")
            echo		 
            fluxdaemon_update
            echo
        ;;
	
        "fluxbench_update")
            echo		 
            fluxbench_update
            echo
        ;;
	
        "flux_update")
            echo		 
            flux_update
            echo
        ;;
	
        "flux_restart")
            echo		 
            restart_fluxdaemon
            echo
        ;;
	
        "flux_reindex")
            echo
            reindex
            echo
        ;;
	
        "create_daemon_bootstrap")
            echo
            create_daemon_bootstrap
            echo
        ;;
	
	"daemon_bootstrap")
            echo
            daemon_bootstrap
            echo
        ;;
	
        "mongod_bootstrap")
            echo
	    echo -e "${ARROW} ${CYAN}Stopping Flux...${NC}"
            pm2 stop flux >/dev/null 2>&1 && sleep 2
            mongodb_bootstrap
            echo
        ;;
	
        "create_mongod_bootstrap")
            echo
            create_mongod_bootstrap
            echo
        ;;

        "create_kda_bootstrap")
            echo	
            create_kda_bootstrap
            echo
        ;;
           
        "clean_mongod")
            echo
            clean_mongod
            echo
        ;;

        "swapon_create")
            echo
            swapon_create
            echo
        ;;

        "unlock_flux_resouce")
            echo
            unlock_flux_resouce "$type"
            echo
        ;;

        "kda_bootstrap")
            echo
            kda_bootstrap
            echo
         ;;

    esac
