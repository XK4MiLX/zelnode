#!/usr/bin/env bash
SSD=0
HDD=0
LC_ALL="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LANG="en_US.UTF-8"
LANGUAGE="en_US:en"
##########
command_exists()
{
    command -v "$@" > /dev/null 2>&1
}

Bps_to_MiBps()
{
    awk '{ printf "%.2f\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "error" } }'
}

B_to_MiB()
{
    awk '{ printf "%.0f MiB\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "error" } }'
}

finish()
{
    printf '\n'
    sudo rm -f test_$$
    exit
}

trap finish EXIT INT TERM

dd_benchmark()
{
  cd $HOME && sudo LC_ALL=C timeout 30s dd if=/dev/zero of=$1/test_$$ bs=64k count=16k conv=fdatasync 2>&1 | \
    awk -F, '
          {
              io=$NF
          }
          END {
              if (io ~ /TB\/s/) {printf("%.0f\n", 1000*1000*1000*1000*io)}
              else if (io ~ /GB\/s/) {printf("%.0f\n", 1000*1000*1000*io)}
              else if (io ~ /MB\/s/) {printf("%.0f\n", 1000*1000*io)}
              else if (io ~ /KB\/s/) {printf("%.0f\n", 1000*io)}
              else { printf("%.0f", 1*io)}
          }'
  sudo rm -f $1/test_*
}

if ! command_exists dd; then
  printf '%s\n' 'This script requires dd, but it could not be found.' 1>&2
  exit 1
fi


if [[ "$(sysbench --version)" == "" ]]; then
  curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash > /dev/null 2>&1
  sudo apt -y install sysbench  > /dev/null 2>&1
fi

vcore=$(getconf _NPROCESSORS_ONLN)
ram=$(LC_ALL=C free -b 2> /dev/null | awk 'NR==2 {print $2}' | grep -Eo '[0-9]+'| printf "%.2fGB\n" $(awk '{ print $1/1024/1024/1024 }'))
core=$(awk -F: '/cpu cores/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \\t]*//;s/[ \\t]*$//')

echo -e ""
echo -e "-------------------------"
echo -e "| MEMORY BENCHMARK"
echo -e "-------------------------"
echo -e "| RAM: $ram"
echo -e "-------------------------"
echo -e "| CPU BENCHMARK"
echo -e "-------------------------"
eps=$(LC_ALL=C sysbench cpu --cpu-max-prime=60000 --time=20 run 2> /dev/null | grep 'events per second' | awk -v cpu=$vcore '{print $4*cpu}')

if [[ "${ram%%.*}" -ge  7 ]] && [[ "$core" -ge  2 ]] && [[ "$vcore" -ge 4 ]] &&  [[ "${eps%%.*}" -ge 240 ]]; then
  status="CUMULUS"
fi

if [[ "${ram%%.*}" -ge  31 ]] && [[ "$core" -ge  4 ]] && [[ "$vcore" -ge 8 ]] && [[ "${eps%%.*}" -ge  640 ]]; then
  status="NIMBUS"
fi

if [[ "${ram%%.*}" -ge  62 ]] && [[ "$core" -ge 8 ]]  && [[ "$vcore" -ge 16 ]] && [[ "${eps%%.*}" -ge  1520 ]]; then
  status="STRATUS"
fi

if [[ "$status" == "" ]]; then
  status="FAILED"
fi

echo -e "| CPU vcores: $vcore"
echo -e "| CPU cores: $core"
echo -e "| EPS: $eps"

outputdiskbench="Disks Bench:";
#checking loop for lxc only if mount == '/'
loop_mount=$(cd $HOME && LC_ALL=C lsblk -l -b -n | grep ' loop' | awk '{ if ($7 == "/") printf("%.2f\n", $4/(1024*1024*1024))}')
if [[ "$loop_mount" != "" ]]; then

  #echo -e "Device type: loop"
  mount_path="/"
  io1=$( dd_benchmark "$mount_path" )
  io2=$( dd_benchmark "$mount_path" )
  io3=$( dd_benchmark "$mount_path" )

  if [[ "$io1" -le "$io2" ]] && [[ "$io1" -le "$io3" ]]; then
    ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io2"' + '"$io3"')/2)}' | Bps_to_MiBps )
  elif [[ "$io2" -le "$io1" ]]  && [[ "$io2" -le "$io3" ]]; then
    ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io1"' + '"$io3"')/2)}' | Bps_to_MiBps )
  else
    ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io1"' + '"$io2"')/2)}' | Bps_to_MiBps )
  fi

  outputdiskbench+=" loop $loop_mount $ioavg"
  if [[ "${ioavg%%.*}" -ge "180" ]]; then
    SSD=$(awk 'BEGIN{printf("%d",'"$SSD"'+'"$loop_mount"')}')
  else
    HDD=$(awk 'BEGIN{printf("%d",'"$HDD"'+'"$loop_mount"')}')
  fi
fi
if [[ $outputdiskbench == "Disks Bench:" ]]; then

  lvm_mount=""
  raid_list=()
  disc__array=($(cd $HOME && LC_ALL=C lsblk -o NAME,SIZE,TYPE -b -n | grep ' disk' | awk '{ if ($2 > 2147483648 && $1 != "mmcblk0" && $1 != "mmcblk0p1") print                                         $1}'))
  for((i=0;i<${#disc__array[@]};i++));
  do

    #checking if disk structure is accessable
    cd $HOME && lsblk -l -b -n /dev/${disc__array[i]} > /dev/null 2>&1
    if [ $? != 0 ]; then
      #echo -e "Disk name: ${disc__array[i]}"
      #echo -e "Error: Can't grab device stucture... device skipped!"
      #echo -e "-----------------------------"
      continue
    fi
    #checking direct mount
    disk_mount_check=$(cd $HOME && LC_ALL=C lsblk -l -b -n /dev/${disc__array[i]} | grep ' disk' | awk '{ if ( $7 == "") print "no"; else print "yes"}')
    #echo -e "Direct mount: $disk_mount_check"
    if [[ "$disk_mount_check" == "no" ]]; then
      #checking lvm mount
      lvm_mount=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --sort SIZE | egrep ' lvm| dm' |  tail -n1 | awk '{ print $7 }' )
      lvm_name=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --sort SIZE | egrep ' lvm| dm' |  tail -n1 | awk '{ print $1 }' )
      if [[ "$lvm_name" != "" ]]; then
        count=$(echo ${mount_list[@]} | tr ' ' '\n' | awk '$1 == "'"$lvm_mount"'"{print $0}' | wc -l)
        if [[ "$count" == "0" ]]; then
          mount_list+=("$lvm_mount")
        else
          #echo -e "Disk name: ${disc__array[i]}"
          #echo -e "Error: Mount point already checked... device skipped!"
          #echo -e "-----------------------------"
          continue
        fi
      fi

      if [[  "$lvm_name" != "" && "$lvm_mount" == "" ]]; then
        if [[ ! -d /.benchmark_test ]]; then
          sudo mkdir /.benchmark_test
        fi
        sudo mount /dev/mapper/$lvm_name /.benchmark_test
      fi

      lvm_mount=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --sort SIZE | egrep ' lvm| dm' |  tail -n1 | awk '{ print $7 }' )
      if [[ "$lvm_mount" != "" ]]; then
        partition_output=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --sort SIZE | egrep ' lvm| dm' |  tail -n1 | awk '{print $1 " " $4/(1024*10                                        24*1024) }')
      else
        #checking if disk partition type is LVM2_member
        part_type_check=$(cd $HOME && LC_ALL=C lsblk -o NAME,TYPE,FSTYPE,SIZE -b -n /dev/${disc__array[i]} --sort SIZE | egrep ' part' | egrep 'LVM2_member' |                                          tail -n1 | wc -l)
        if [[  "$part_type_check" != "0" ]]; then
          #skipp disk
          partition_name=$(awk '{print $1}' <<< $part_type_check)
          #echo -e "Disk name: ${disc__array[i]}"
          #echo -e "Error: LVM2_member partition detected... device skipped!"
          #echo -e "-----------------------------"
          continue
        fi

        #checking raid
        partition_output=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --sort SIZE | egrep ' raid' |  tail -n1 | awk '{print $1 " " $4/(1024*1024*                                        1024) }')
        if  [[ "$partition_output"  == "" ]]; then
          #checking  part ( when not lvm and raid )
          #echo -e "Checking partition on device: /dev/${disc__array[i]}"
          partition_output=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --sort SIZE | egrep ' part' |  tail -n1 | awk '{print $1 " " $4/(1024*102                                        4*1024) }')
          #echo -e "$partition_output"
          #echo -e "-----------------------------"
        else
          partition_name=$(awk '{print $1}' <<< $partition_output)
          #add raid name to skip list
          if [[ ! " ${raid_list[@]} " =~ " ${partition_name} " ]]; then
            raid_list+=("$partition_name")
          else
            #skipped raid already tested
            #echo -e "Disk name: ${disc__array[i]}"
            #echo -e "Info: Disk skipped - raid already tested!"
            #echo -e "-----------------------------"
            continue
          fi
        fi
      fi

    else
      #echo -e "Checking partition on device: /dev/${disc__array[i]} (STEP2)..."
      partition_output=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --sort SIZE | tail -n1 | awk '{print $1 " " $4/(1024*1024*1024) }')
      #echo -e "$partition_output"
      #echo -e ""
    fi

    partition_name=$(awk '{print $1}' <<< $partition_output)
    partition_size=$(awk '{printf("%.2f",$2)}' <<< $partition_output)
    if [[ "$lvm_mount" == "" && "$raid_list" == "" ]]; then
      disk_size=$(cd $HOME && LC_ALL=C lsblk -l -b /dev/${disc__array[i]} --noheadings | head -n1 | awk '{printf("%.2f",$4/(1024*1024*1024))}')
    else
      disk_size=$partition_size
    fi

    if [[ "$lvm_mount" == "" ]]; then
      if [[ ! -d /.benchmark_test ]]; then
        sudo mkdir /.benchmark_test
      fi
      sudo mount /dev/$partition_name /.benchmark_test
      available_space=$(LC_ALL=C df /dev/$partition_name | grep $partition_name | tail -n1 | awk '{ if ($4 > 2097152) printf("%.2f",$4/(1024*1024)); else prin                                        t "null"}')
    else
      available_space=$(LC_ALL=C df /dev/mapper/$partition_name | grep $partition_name | tail -n1 | awk '{ if ($4 > 2097152) printf("%.2f",$4/(1024*1024)); el                                        se print "null"}')
    fi

    if [[ "$available_space" != "null" &&  "$available_space" != "" ]]; then

      if [[ "$lvm_mount" == "" ]]; then
        mount_path="/.benchmark_test"
      else
        mount_path="$lvm_mount"
      fi

      #echo -e "Mount point: $mount_path"
      io1=$( dd_benchmark "$mount_path" )
      io2=$( dd_benchmark "$mount_path" )
      io3=$( dd_benchmark "$mount_path" )

      if [[ "$io1" -le "$io2" ]] && [[ "$io1" -le "$io3" ]]; then
        ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io2"' + '"$io3"')/2)}' | Bps_to_MiBps )
      elif [[ "$io2" -le "$io1" ]]  && [[ "$io2" -le "$io3" ]]; then
        ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io1"' + '"$io3"')/2)}' | Bps_to_MiBps )
      else
        ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io1"' + '"$io2"')/2)}' | Bps_to_MiBps )
      fi

      outputdiskbench+=" ${disc__array[i]} $disk_size $ioavg"
      if [[ "${ioavg%%.*}" -ge "180" ]]; then
        SSD=$(awk 'BEGIN{printf("%d",'"$SSD"'+'"$disk_size"')}')
      else
        HDD=$(awk 'BEGIN{printf("%d",'"$HDD"'+'"$disk_size"')}')
      fi

      if [[ "$lvm_mount" == "" ]]; then
        sudo umount /.benchmark_test
        if [[ $(cd $HOME && lsblk -l | grep "benchmark_test") ]]; then
          echo -e ""
        else
          sudo rm -rf /.benchmark_test
        fi
      fi

      #check if test point mounted if exist unmount it LVM case
      if [[ $(cd $HOME && lsblk -l | grep "benchmark_test") ]]; then
        sudo umount /.benchmark_test
        if [[ $(cd $HOME && lsblk -l | grep "benchmark_test") ]]; then
          echo -e ""
        else
          sudo rm -rf /.benchmark_test
        fi
      fi

    else

      #echo -e "Error: space not enough... write test skipped!"
      #echo -e "-----------------------------"
      if [[ "$lvm_mount" == "" ]]; then

        sudo umount /.benchmark_test
        if [[ $(cd $HOME && lsblk -l | grep "benchmark_test") ]]; then
          echo -e ""
        else
          sudo rm -rf /.benchmark_test
        fi
      fi
    fi

  done

  if [[ "$outputdiskbench" == "Disks Bench:" ]]; then
    # lsblk failed checking direct mount from df
    df_direct_mount=$(LC_ALL=C df --output=source,fstype,size,avail,target | grep 'dev' | awk '{ if ($5 == "/") printf("%s %.2f %.2f\n", $1,$3/(1024*1024),$4/                                        (1024*1024))}')
    if [[ df_direct_mount != "" ]]; then
      device_name=$(awk '{print $1}' <<< $df_direct_mount)
      partition_size=$(awk '{print $2}' <<< $df_direct_mount)
      mount_path="/"
      io1=$( dd_benchmark "$mount_path" )
      io2=$( dd_benchmark "$mount_path" )
      io3=$( dd_benchmark "$mount_path" )
      if [[ "$io1" -le "$io2" ]] && [[ "$io1" -le "$io3" ]]; then
        ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io2"' + '"$io3"')/2)}' | Bps_to_MiBps )
      elif [[ "$io2" -le "$io1" ]]  && [[ "$io2" -le "$io3" ]]; then
        ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io1"' + '"$io3"')/2)}' | Bps_to_MiBps )
      else
        ioavg=$( awk 'BEGIN{printf("%.0f", ('"$io1"' + '"$io2"')/2)}' | Bps_to_MiBps )
      fi

      outputdiskbench+=" $device_name $partition_size $ioavg"
      if [[ "${ioavg%%.*}" -ge "180" ]]; then
        SSD=$(awk 'BEGIN{printf("%d",'"$SSD"'+'"$partition_size"')}')
      else
        HDD=$(awk 'BEGIN{printf("%d",'"$HDD"'+'"$partition_size"')}')
      fi
    fi

  fi

fi

echo -e "-------------------------"
echo -e "| DISK INFO"
echo -e "-------------------------"
echo -e "| SSD: $SSD"
echo -e "| HDD: $HDD"
echo -e "-------------------------"

score=0
if [[ $status == "CUMULUS" ]]; then
  score=1
fi

if [[ $status == "NIMBUS" ]]; then
  score=2
fi

if [[ $status == "STRATUS" ]]; then
  score=3
fi


if [[ "$SSD" -lt 220 ]] || [[ "$score" == 0 ]] ; then
  status="FAILED"
fi

if [[ "$SSD" -ge 220 ]] && [[ "$score" -ge 1 ]]; then
  status="CUMULUS"
fi

if [[ "$SSD" -ge 440 ]] && [[ "$score" -ge 2 ]]; then
  status="NIMBUS"
fi

if [[ "$SSD" -ge 880 ]] && [[ "$score" -ge 3 ]] ; then
  status="STRATUS"
fi

echo -e "| Benchmark: $status"
echo -e "-------------------------"
