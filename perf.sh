#!/bin/bash
#  Author : Shatadru Bandyopadhyay
#         : Ganesh Gore
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
for i in `seq 0 "$argnum"`
        do
        key1=${args[$i]}
	case $key1 in  ''|*[!0-9]*) 
				#do nothing
				;;     
				*) INTERVAL=${args[$i]}; ITERATION=${args[(($i+1))]}; break
				;; 
	esac
done


case $INTERVAL in
    ''|*[!0-9]*) echo "Error while parsing command line argument, check help" ; exit ;;
    *)  ;;
esac

# Command line arg handling #


# Creating temporary directory to save the files
tempdirname=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1`
mkdir /tmp/$tempdirname/
DIR=/tmp/$tempdirname/


# Function to check if a command is available 
function com_check(){
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


# Function to check if a package is available 
function pkg_check() {
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

#Checking for required packages / commands 
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




#ITERATION=$((ITERATION / 2))


### End function ###
function end () {
dmesg >> $DIR/dmesg2.out
#Creating tarball of outputs
FILENAME="outputs-`date +%d%m%y_%H%M%S`.tar.bz2"
if [ "$perf" == "1" ]; then
	tar -v -cjvf "$FILENAME" $DIR/*.out $DIR"perf"
else
	tar -cjvf "$FILENAME" $DIR/*.out
fi
echo "==================================="
echo "Please upload the file:" $FILENAME
echo "==================================="
rm -rf "$DIR"/*
rmdir "$DIR"
exit
}
trap end SIGHUP SIGINT SIGTERM



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
#~~~ Collection End ~~~
end
