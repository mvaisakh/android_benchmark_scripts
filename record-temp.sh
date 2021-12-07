#!/bin/bash

tzone_array=( "$@" )
OUTPUT_DIR="output"

trap 'gather_results' EXIT
gather_results()
{
	for tzone in ${tzone_array[@]}
	do
		echo "Thermal Zone "$tzone":"
		FILE="$OUTPUT_DIR/temp_tzone_$tzone"
		awk 'BEGIN 	{ total = 0
				  count=0 
			  	}
				{ if(max== "" || $1 > max) {max=$1}
				  total=total+$1
				  count++
				}
			END 	{ avg=total/count
			print ("Max Temp: " max, "Avg Temp: " avg)
				}' $FILE
	done
	exit
}

mkdir -p $OUTPUT_DIR

for tzone in ${tzone_array[@]}
do
	FILE="$OUTPUT_DIR/temp_tzone_$tzone"
	rm -Rf $FILE
done

while :
do
	for tzone in ${tzone_array[@]}
	do
		temp=$(cat /sys/class/thermal/thermal_zone$tzone/temp)
		FILE="$OUTPUT_DIR/temp_tzone_$tzone"
		echo $temp >> $FILE
	done
	sleep 1
done
