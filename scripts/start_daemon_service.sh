#!/bin/bash
#color codes
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'
#emoji codes
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
directory="/usr/local/bin"
current_user="$USER"
sleep 2
# Check if the directory exists
if [ -d "$directory" ]; then
    echo "Checking for files in $directory..."
    # Use find to search for all files in the directory
    all_files=$(find "$directory" -maxdepth 1)
    if [ -n "$all_files" ]; then
        # Identify files not owned by the current user
        non_user_files=$(find "$directory" -maxdepth 1 ! -user "$current_user")
        if [ -n "$non_user_files" ]; then
            echo "Files not owned by $current_user found:"
            echo "$non_user_files"
            # Change ownership of non-user files to the current user
            echo "Changing ownership to $current_user..."
            sudo chown "$current_user":"$current_user" $non_user_files
            echo "Ownership changed successfully."
        else
            echo "All files are owned by $current_user."
        fi
    else
        echo "No files found in $directory."
    fi
else
    echo "Directory $directory does not exist."
fi
echo -e "${BOOK} ${CYAN}Pre-start process starting...${NC}"
echo -e "${BOOK} ${CYAN}Checking if benchmark or daemon is running${NC}"
bench_status_pind=$(pgrep fluxbenchd)
daemon_status_pind=$(pgrep fluxd)
if [[ "$bench_status_pind" == "" && "$daemon_status_pind" == "" ]]; then
  echo -e "${BOOK} ${CYAN}No running instance detected...${NC}"
else
  if [[ "$bench_status_pind" != "" ]]; then
  echo -e "${WORNING} Running benchmark process detected${NC}"
  echo -e "${WORNING} Killing benchmark...${NC}"
  sudo killall -9 fluxbenchd > /dev/null 2>&1  && sleep 2
  fi
  if [[ "$daemon_status_pind" != "" ]]; then
  echo -e "${WORNING} Running daemon process detected${NC}"
  echo -e "${WORNING} Killing daemon...${NC}"
  sudo killall -9 fluxd > /dev/null 2>&1  && sleep 2
  fi
  sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
fi
bench_status_pind=$(pgrep zelbenchd)
daemon_status_pind=$(pgrep zelcashd)
if [[ "$bench_status_pind" == "" && "$daemon_status_pind" == "" ]]; then
  echo -e "${BOOK} ${CYAN}No running instance detected...${NC}"
else
  if [[ "$bench_status_pind" != "" ]]; then
  echo -e "${WORNING} Running benchmark process detected${NC}"
  echo -e "${WORNING} Killing benchmark...${NC}"
  sudo killall -9 zelbenchd > /dev/null 2>&1  && sleep 2
  fi
  if [[ "$daemon_status_pind" != "" ]]; then
  echo -e "${WORNING} Running daemon process detected${NC}"
  echo -e "${WORNING} Killing daemon...${NC}"
  sudo killall -9 zelcashd > /dev/null 2>&1  && sleep 2
  fi
  sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
fi
if [[ -f /usr/local/bin/fluxd ]]; then
bash -c "fluxd"
 exit
else
  bash -c "zelcashd"
  exit
fi
