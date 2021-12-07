#!/bin/bash

#CPU_BASE=cpu4
#CPU_GROUP=$(cat /sys/devices/system/cpu/$CPU_BASE/cpufreq/related_cpus)
#NR_CPUS=$(echo $CPU_GROUP | wc -w)
#CPU_GROUP=$(echo $CPU_GROUP | tr ' ' ',')
MSG=10000

OUTPUT_FILE="dhry-output"
rm -Rf $OUTPUT_FILE

#Check if workload cpu and stat cpu are valid
if [ "$#" -ne  "2" ];
then
	echo "Please specify workload cpu and stat collection cpu"
	echo "./dhrystone-performance-opp.sh <workload_cpunum> <stat_collection_cpunum>"
	exit 1
fi
WORK_CPU=$1
STAT_CPU=$2
if [ "$WORK_CPU" -lt "0" ] || [ "$WORK_CPU" -gt "7" ];
then
	echo "Invalid workload cpu. Enter cpu number between 0 and 7"
	exit 1
fi
if [ "$STAT_CPU" -lt "0" ] || [ "$STAT_CPU" -gt "7" ];
then
	echo "Invalid stat collection cpu. Enter cpu number between 0 and 7"
	exit 1
fi

#WORK_CPU=$(echo "cpu"$WORK_CPU)

echo "Workload cpu is: $WORK_CPU; Stat Collection cpu is: $STAT_CPU"
# Check we are root
if [ "$(id -u)" != "0" ]; then
   echo "Script needs the root privilege"
   exit 1
fi

# Check the userspace governor exists
cat /sys/devices/system/cpu/cpu$WORK_CPU/cpufreq/scaling_available_governors | grep -q userspace
RET=$?
if [ "$RET" != "0" ];
then
    echo "No 'userspace' governor available"
    exit 1
fi

# Check the dhrystone binary is accessible
#DHRYSTONE=$(which dhrystone)
#if [ "$DHRYSTONE" == "" ]; then
#    echo "No dhrystone program found"
#    exit 1
#fi

DHRYSTONE="bin/dhrystone"

# Grab all the frequencies
FREQUENCIES=$(cat /sys/devices/system/cpu/cpu$WORK_CPU/cpufreq/scaling_available_frequencies)

# Save the old governor
OLD_GOVERNOR=$(cat /sys/devices/system/cpu/cpu$WORK_CPU/cpufreq/scaling_governor)

#Change governor to userspace
echo userspace > /sys/devices/system/cpu/cpu$WORK_CPU/cpufreq/scaling_governor


# Run test pinning to WORK_CPU

echo
echo "Testing one process pinned to cpu $WORK_CPU"
echo

for i in $FREQUENCIES;
do
     echo "Testing at frequency: "$i
     echo "##### Testing at frequency: $i #####" >> $OUTPUT_FILE
     echo $i > /sys/devices/system/cpu/cpu$WORK_CPU/cpufreq/scaling_setspeed
     taskset -c $STAT_CPU ./record-temp.sh $WORK_CPU >> $OUTPUT_FILE &
     pid=$!
     taskset -c $WORK_CPU $DHRYSTONE -t 1 -l $MSG >> $OUTPUT_FILE
     echo >> $OUTPUT_FILE
     kill $pid
     sleep 1
     echo >> $OUTPUT_FILE
     echo >> $OUTPUT_FILE
done

# Set back the previous governor
echo $OLD_GOVERNOR > /sys/devices/system/cpu/cpu$WORK_CPU/cpufreq/scaling_governor

echo "Testing Done. Results Available in "$OUTPUT_FILE
