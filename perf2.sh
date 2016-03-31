#!/bin/bash
ITERATION=30
INTERVAL=2  # default interval
if [ -n "$1" ]; then
     ITERATION=$2
fi

if [ -n "$2" ]; then
     INTERVAL=$1
fi

echo "Start collecting data."
echo "Running for approximately " $(($ITERATION * $INTERVAL)) " seconds"

#ITERATION=$((ITERATION / 2))
rm -rf /tmp/*.out

# One time data
#~~~
cat /proc/cpuinfo >> /tmp/cpu.out
dmesg >> /tmp/dmesg.out
#~~~


#~~~ Continuous collection by will run outside loop ~~~
date >> /tmp/vmstat.out; vmstat $INTERVAL $ITERATION >> /tmp/vmstat.out &
iostat -t -z -x $INTERVAL $ITERATION >> /tmp/iostat.out &
sar $INTERVAL $ITERATION >> /tmp/sar.out &
sar -A $INTERVAL $ITERATION -p >> /tmp/sarA.out &
mpstat $INTERVAL $ITERATION -P ALL >> /tmp/mpstat.out &
#~~~

# ~~~ Loop begins to collect data ~~~
((count=0))
((CURRENT_ITERATION=1))
while true
do
	if((CURRENT_ITERATION <= ${ITERATION}))
	then	
		echo "Collecting data : Iteration "$(($CURRENT_ITERATION))
		date >> /tmp/top.out; top -n 1 -b >> /tmp/top.out
		date >> /tmp/iotop.out; iotop -n 1 -b >> /tmp/iotop.out
		date >> /tmp/mem.out; cat /proc/meminfo >> /tmp/mem.out
		date >> /tmp/free.out; free -m >> /tmp/free.out
		date >> /tmp/psf.out; ps auxf >> /tmp/psf.out
		date >> /tmp/ps.out  ; ps aux >> /tmp/ps.out  
		date >> /tmp/pidstat.out ; pidstat >> /tmp/pidstat.out &
		((CURRENT_ITERATION++))
		sleep $INTERVAL
		
		continue;
	else
		break;
	fi
	
done
#~~~ Collection End ~~~

#Creating tarball of outputs
FILENAME="outputs-`date +%d%m%y_%H%M%S`.tar.bz2"
tar -cjvf "$FILENAME" /tmp/*.out
echo "Please upload the file:" $FILENAME
