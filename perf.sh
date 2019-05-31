#!/bin/bash
#  Author / Maintainer : Shatadru Bandyopadhyay sbandyop@redhat.com
#  Early contribution  : Ganesh Gore            ggore@redhat.com
#
# OBTAIN THE LATEST VERSION OF THE SCRIPT AT :  https://github.com/shatadru/SGPD/blob/master/perf.sh
#                       DIRECT DOWNLOAD LINK : https://raw.githubusercontent.com/shatadru/SGPD/master/perf.sh
# 
# Licenced under GPLv3, check LICENSE.txt
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Initiating variables...

perf=0
lsbyes=1
iotopyes=0
iostatold=0
ver=`uname -r`
ITERATION=60 # default 
INTERVAL=1   # default 
D_INTERVAL=10 # default
# Command line arg handling #

args=( "$@" )
numarg=$#
argnum=$((numarg-1))

for i in `seq 0 "$argnum"`
	do
	key=${args[$i]}
	case $key in
    		-p|--perf)
    			perf="1"
		;;
    		-h|--help)

			help="1"
		;;
    		-d|--daemon)

			daemon="1"
		;;
		-v|--verbose)

			verbose="1"
		;;
		-n|--non-interactive)

			noninteractive="1"
		;;
    		-w|--no-warn|--nowarn)
    			no_warn="1"
		;;

 		*)
    		;;
	esac
done

# Command line arg parsing #

for i in `seq 0 "$argnum"`
        do
        key1=${args[$i]}
	case $key1 in  ''|*[!0-9]*) 
				#do nothing
				;;     
				*) INTERVAL=${args[$i]}; ITERATION=${args[(($i+1))]}; D_INTERVAL=`echo $INTERVAL`;break
				;; 
	esac
done


case $INTERVAL in
    ''|*[!0-9]*) echo "Error while parsing command line argument, check help" ; exit ;;
    *)  ;;
esac

# Command line arg parsing #



# Creating temporary directory to save the files
tempdirname=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1`
mkdir /tmp/$tempdirname/
DIR=/tmp/$tempdirname/


# Check if --help of -h #
if [ "$help" == "1" ]; then
cat > /tmp/perfsh-readme <<EOF
.\" Manpage for perf.sh.
.\" Contact sbandyop@redhat.com to correct errors or typos.
.TH per.sh MAN "13 May 2017" "1.0" "perf.sh man page"
.SH NAME
perf.sh \- Collects generic performance data from all subsystem (CPU, Memory, I/O ) 
.SH SYNOPSIS
perf.sh [OPTION] [Interval] [Iterations]
.SH DESCRIPTION
 Collects generic performance data from all subsystem (CPU, Memory, I/O )
 
1. By default the script will run in interval of 2 seconds and 30 times.

2. This script can be stopped using ctrl+c and still will capture the data.

3. This will collect data like sar, vmstat, iostat, iotop, ps, top and create a tarball inside current directory which can be helpful finding out 
   reason of high CPU/Memory usage, high load average, high iowait.

4. This script is tested to work in RHEL/CentOS 5,6,7 and Fedora 23,24. You should have tools like systat, iotop installed for the script to work.

5. Tools such as collectl are available which does this better, however it was created keeping simplycity in mind.

6. It does not capture huge ammount of data like collectl and much easier to use.

.SH OPTIONS

-p : Collect perf data perf(1) , Not to be confused with name of this script - perf.sh

-d : Run in daemon mode, for this the script needs to be run using setsid.
     This is useful when the performance issue is sporadic and can not be reproduced at will


	$ setsid ./perf.sh -d 2> /dev/null &
	

     To end the data collection kill the script with SIGNAL 15

	$ pkill perf.sh    	
   
.SH SEE ALSO
 sar(1) free(1) ps(1) iostat(1) iotop(8) 

 https://github.com/shatadru/SGPD 

.SH BUGS
No known bugs. Report Bugs at : https://github.com/shatadru/SGPD/issues/new

.SH TODO
Collect network related data apart from stuffs collected by SAR

.SH AUTHOR
Shatadru Bandyopadhyay (sbandyop@redhat.com)
EOF
man /tmp/perfsh-readme
exit
fi

###################### Function Definations ##########################################################


function com_check(){
# Function to check if a command is available #
which $1 > /dev/null 2> /dev/null
if [ "$?" -ne "0" ];then
	echo Command : $1 Not found...
	if [ "$1" == "iotop" ]; then
		echo "Install iotop package (#yum install iotop) and run the script again. exiting..."
		exit
	elif [ "$1" == "sar" ]; then 
		echo "Install systat package (#yum install sysstat) and run the script again. exiting..."
		exit
	elif [ "$1" == "lsb_release" ]; then 
		lsbyes=0
	elif  [ "$1" == "perf" ]; then 
		echo "$1 is not installed"
		echo "Refer : https://access.redhat.com/solutions/386343"
		echo "Do you want to skip collection of perf data and continue ? (Y/N)"
		read a		
		if  [ "$a" == "Y" ] ||  [ "$a" == "y" ] ||  [ "$a" == "Yes" ] ; then
			perf=0
			sleep 1;
		else
			echo "Install $1 package (#yum install $1) and run the script again. exiting..."
			exit
		fi


	else
		echo "Install $1 package (#yum install $1) and run the script again. exiting..."
		exit
	fi
fi

}


function pkg_check() {
# Function to check if a package is available 

rpm -q $1 > /dev/null 2> /dev/null
if [ "$?" -ne "0" ];then
	echo Package : $1 Not found...
	if  [ "$1" == "kernel-debuginfo-$ver" ]; then 
		echo "Refer : https://access.redhat.com/solutions/386343"
		echo "Do you want to skip collection of perf data and continue ? (Y/N)"
		read a		
		if  [ "$a" == "Y" ] ||  [ "$a" == "y" ] ||  [ "$a" == "Yes" ] ; then
			perf=0
			sleep 1;
		else
			echo "Install $1 package (#yum install $1) and run the script again. exiting..."
			echo "Refer : [How can I download or install debuginfo packages for RHEL systems?] https://access.redhat.com/solutions/9907"
			exit
		fi
	fi	
fi
}

function one_time_data_capture() {
# Runs outside loop :
# Collects cpuinfo, dmesg  and perf "-p" is given

# One time data
#~~~
cat /proc/cpuinfo >> $DIR/cpu.out
dmesg >> $DIR/dmesg1.out
#~~~
# One time perf 
if [ "$perf" == "1" ]; then
	
	echo "Collecting perf data for 30 seconds..."
	mkdir -p $DIR"perf"; cd $_
	perf record -a -g sleep 30
	perf archive
	echo "Collected perf"
	cd -
fi
#~~~

}

function loop_data_capture() {
echo
echo "Start collecting data."
echo "Running for $ITERATION times, after $INTERVAL seconds interval"

#~~~ Continuous collection by will run outside loop ~~~
#date >> $DIR/vmstat.out; vmstat $INTERVAL $ITERATION >> $DIR/vmstat.out &
if [ "$iostatold" -eq "1" ]; then
	iostat -t  -x $INTERVAL $ITERATION >> $DIR/iostat.out &
	else
	iostat -t -z -x $INTERVAL $ITERATION >> $DIR/iostat.out &
fi
sar $INTERVAL $ITERATION >> $DIR/sar.out &
sar -A $INTERVAL $ITERATION -p >> $DIR/sarA.out &
mpstat $INTERVAL $ITERATION -P ALL >> $DIR/mpstat.out &
nfsiostat $INTERVAL $ITERATION  >> $DIR/nfsiostat.out &
#~~~

# ~~~ Loop begins to collect data ~~~
((count=0))
((CURRENT_ITERATION=1))
while true
do
	if((CURRENT_ITERATION <= ${ITERATION}))
	then	
		echo "$(date +%T): Collecting data : Iteration "$(($CURRENT_ITERATION))
		date >> $DIR/top.out; top -n 1 -b >> $DIR/top.out
		if [ "$iotopyes" -eq "1" ]; then
			date >> $DIR/iotop.out; iotop -n 1 -b >> $DIR/iotop.out
			date >> $DIR/pidstat.out ; pidstat >> $DIR/pidstat.out &
		fi
		date >> $DIR/mem.out; cat /proc/meminfo >> $DIR/mem.out
		date >> $DIR/free.out; free -m >> $DIR/free.out
		date >> $DIR/psf.out; ps auxf >> $DIR/psf.out
		date >> $DIR/ps_auxwwwm.out; ps auxwwwm >> $DIR/ps_auxwwwm.out
		date >> $DIR/ps.out  ; ps aux >> $DIR/ps.out  
		((CURRENT_ITERATION++))
		sleep $INTERVAL
		
		continue;
	else
		break;
	fi
	
done

}


function loop_data_capture_daemon() {
#overwrite Interval with daemon interval
if [ "$D_INTERVAL" == "5" ];then
	sleep 0;
else 
	INTERVAL=`echo $D_INTERVAL`
fi
echo
echo "Started perf.sh as a daemon with PID $$"
echo "Start collecting data."
echo "Will be running in background as a daemn till terminated manualy, will collect data in $INTERVAL seconds interval"
echo "To terminate run #pkill perf.sh or # kill -15 $$"
echo

logger perf.sh: "Started perf.sh as a daemon with PID $$"
logger perf.sh: "Start collecting data. PID : $$"
logger perf.sh: "Will be running in background as a daemon till terminated manualy, will collect data in $INTERVAL seconds interval"
logger  "To terminate run #pkill perf.sh or # kill -15 $$"


#~~~ Continuous collection by will run outside loop ~~~
#date >> $DIR/vmstat.out; vmstat $INTERVAL $ITERATION >> $DIR/vmstat.out &
if [ "$iostatold" -eq "1" ]; then
	iostat -t  -x $INTERVAL  >> $DIR/iostat.out &
	else
	iostat -t -z -x $INTERVAL  >> $DIR/iostat.out &
fi
sar $INTERVAL  >> $DIR/sar.out &
sar -A $INTERVAL  -p >> $DIR/sarA.out &
mpstat $INTERVAL  -P ALL >> $DIR/mpstat.out &
#nfsiostat $INTERVAL  >> $DIR/nfsiostat.out &
#
#~~~

# ~~~ Loop begins to collect data ~~~
((count=0))
((CURRENT_ITERATION=1))
while true
do

		#echo "$(date +%T): Collecting data : Iteration "$(($CURRENT_ITERATION))
		date >> $DIR/top.out; top -n 1 -b >> $DIR/top.out
		if [ "$iotopyes" -eq "1" ]; then
			date >> $DIR/iotop.out; iotop -n 1 -b >> $DIR/iotop.out
			date >> $DIR/pidstat.out ; pidstat >> $DIR/pidstat.out &
		fi
		date >> $DIR/mem.out; cat /proc/meminfo >> $DIR/mem.out
		date >> $DIR/free.out; free -m >> $DIR/free.out
		date >> $DIR/psf.out; ps auxf >> $DIR/psf.out
		date >> $DIR/ps_auxwwwm.out; ps auxwwwm >> $DIR/ps_auxwwwm.out
		date >> $DIR/ps_-eL-w_-o_pid,ppid,tid,tgid,stat,pcpu,psr,vsz,rss,comm,cmd.out; ps -eL -w -o pid,ppid,tid,tgid,stat,pcpu,psr,vsz,rss,comm,cmd >> $DIR/ps_-eL-o_pid,ppid,tid,tgid,stat,pcpu,psr,vsz,rss,comm,cmd.out		date >> $DIR/ps.out  ; ps aux >> $DIR/ps.out  
		((CURRENT_ITERATION++))
		sleep $INTERVAL
		
		continue;
	
done

}


function end () {
### End function ###
# Wraps up things ##

dmesg >> $DIR/dmesg2.out

#Creating tarball of outputs

FILENAME="outputs-`date +%d%m%y_%H%M%S`.tar"
if [ "$perf" == "1" ]; then
	tar -v -cvf "$FILENAME" $DIR/*.out $DIR"perf"
else
	tar -cvf "$FILENAME" $DIR/*.out
fi

echo "==================================="
echo "Please upload the file:" $PWD/$FILENAME
echo "==================================="

if [ "$daemon" == "1" ];then
	#Kill child threads
	for i in $(ps -o pid,ppid,comm --ppid "$$"|tail -n +2|awk '{print $1}'); do
		kill -9 "$i";
	done
	# removing lock file ; exiting cleanly
	rm -rf /var/lock/perfsh_started
	logger perf.sh: "==================================="
	logger perf.sh: "Please upload the file:" $PWD/$FILENAME
	logger perf.sh: "==================================="
fi

rm -rf "$DIR"/*
rmdir "$DIR"

exit
}



function sanity_check () {
######Checking for required packages / commands 
com_check sar
com_check lsb_release
if [ "$perf" -eq "1" ]; then

	com_check perf
#uncommet this TODO
	#pkg_check kernel-debuginfo-$ver
fi
## OS CHECK ##

if [ $lsbyes -eq "1" ]; then
version=`lsb_release -r|cut -f2`
else
version=`cat /etc/redhat-release |cut -f7 -d " "`
fi

v=`echo $version|cut -f1 -d "."`

if [ $v -ge "6" ];then
	com_check iotop
	iotopyes=1
else
	echo "iotop and pidstat command will not be collected as system is RHEL 5 or lower"
	iotopyes=0
	iostatold=1
fi

}

############################################################################################

sanity_check


### Check if we are run in daemon mode ###

if [ "$daemon" == "1" ]; then
	mkdir -p /var/lock
	if [ -f /var/lock/perfsh_started ]; then
		echo "Lock file exits, checking if perf.sh is already running"

	perfcount=`ps aux|grep -iv grep|grep -i perf.sh|wc -l`
#	echo ---- $perfcount ----
#	ps aux|grep -i perf.sh|grep -iv grep 
		if [ "$perfcount" == "3" ]; then
			echo "Another instance of perf.sh running... Exiting..."
			exit
		elif [ "$perfcount" == "2" ]; then
			echo "Stale lock file exists, overwritting the same."
			rm -rf /var/lock/perfsh_started
			echo $tempdirname > /var/lock/perfsh_started
			chmod 777 /var/lock/perfsh_started


		fi
	else
		echo $tempdirname > /var/lock/perfsh_started
		chmod 777 /var/lock/perfsh_started
	fi

	
	# Lets check if perf.sh was started correctly i.e. it's parent is init / systemd
	ps -f $PPID|egrep "systemd|init" >/dev/null
	if [ "$?" == "0" ];then

		echo "Starting perf.sh as daemon..."
		
		trap end SIGHUP SIGINT SIGTERM

		one_time_data_capture

		loop_data_capture_daemon

	else	
		echo
		echo "perf.sh was not started to run as daemon"
		echo
		echo "Run below command to start perf.sh as daemon :"
		echo "~~~"
		echo "# setsid ./perf.sh -d 2> /dev/null &"
		echo "~~~"
		echo
		echo "Exiting..."
		exit
	fi	
fi




#ITERATION=$((ITERATION / 2))



trap end SIGHUP SIGINT SIGTERM

one_time_data_capture

loop_data_capture




#~~~ Collection End ~~~
end
