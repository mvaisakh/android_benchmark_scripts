#!/bin/bash

OUTPUT_FILE=$1
[ -z "$OUTPUT_FILE" ] && OUTPUT_FILE="benchmarks-output"

CPUFREQ_PRESENT="true"

#Benchmarks (Change locations if needed)
MBW=mbw
SYSBENCH=sysbench
CRYPTSETUP=cryptsetup

run_tests()
{
#mbw
echo >> $OUTPUT_FILE
echo "Testing mbw (mbw 1500)" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE
(set -x ; $MBW 1500 >> $OUTPUT_FILE)
sleep 30

#sysbench cpu
echo >> $OUTPUT_FILE
echo "Testing sysbench cpu ( sysbench cpu --threads=8 --time=60 --cpu-max-prime=100000 run )" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE
(set -x; $SYSBENCH cpu --threads=8 --time=60 --cpu-max-prime=100000 run >> $OUTPUT_FILE)
sleep 30

#sysbench memory
echo >> $OUTPUT_FILE
echo "Testing sysbench memory ( sysbench memory --threads=8 --memory-total-size=1G run)" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE
(set -x; $SYSBENCH memory --threads=8 --memory-total-size=1G run >> $OUTPUT_FILE)
}

default_system_test()
{
echo "cpufreq not enabled for some or all cpus" | tee -a $OUTPUT_FILE
echo "Running tests on default system" | tee -a $OUTPUT_FILE
run_tests
echo "Results available at $OUTPUT_FILE"
exit 1
}

rm -Rf $OUTPUT_FILE
policies=$(ls /sys/devices/system/cpu/cpufreq)
[ -z "$policies" ] && default_system_test

declare -A cur_policy=()                                             
                                                            
for policy in $policies;
do      
	[ -f /sys/devices/system/cpu/cpufreq/$policy/scaling_driver ] || default_system_test
	cur_policy[$policy]=$(cat /sys/devices/system/cpu/cpufreq/$policy/scaling_governor)
done
echo "Running tests with default cpufreq governor on all cpus" | tee -a $OUTPUT_FILE
run_tests
sleep 30

# Change the cpufreq governors to performance and run the tests
for policy in $policies;           
do     
	echo performance > /sys/devices/system/cpu/cpufreq/$policy/scaling_governor
done
echo "Running tests with performance governor on all cpus" | tee -a $OUTPUT_FILE
run_tests

# Set back the previous governors
for policy in $policies;                                                                               
do                 
	echo ${cur_policy[$policy]} > /sys/devices/system/cpu/cpufreq/$policy/scaling_governor
done

echo "Results available at $OUTPUT_FILE"
