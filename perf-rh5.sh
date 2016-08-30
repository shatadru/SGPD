#!/bin/bash
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
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
lsbyes=1
iotopyes=0
iostatold=0
function pkg_check(){
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
		else
		echo "Install $1 package (#yum install $1) and run the script again. exiting..."
		exit
	fi
fi

}

pkg_check sar
pkg_check lsb_release

## OS CHECK ##

if [ $lsbyes -eq "1" ]; then
version=`lsb_release -r|cut -f2`
else
version=`cat /etc/redhat-release |cut -f7 -d " "`
fi

v=`echo $version|cut -f1 -d "."`

if [ $v -ge "6" ];then
pkg_check iotop
iotopyes=1
else
echo "iotop command will not be collected as system is RHEL 5 or lower"
iotopyes=0
iostatold=1
fi

ITERATION=30
INTERVAL=2  # default interval
if [ -n "$1" ]; then
     ITERATION=$2
fi

if [ -n "$2" ]; then
     INTERVAL=$1
fi

echo "Start collecting data."
echo "Running for $ITERATION times, after $INTERVAL seconds interval"

#ITERATION=$((ITERATION / 2))
rm -rf /tmp/*.out

# One time data
#~~~
cat /proc/cpuinfo >> /tmp/cpu.out
dmesg >> /tmp/dmesg1.out
#~~~

function end () {
dmesg >> /tmp/dmesg2.out
#Creating tarball of outputs
FILENAME="outputs-`date +%d%m%y_%H%M%S`.tar.bz2"
tar -cjvf "$FILENAME" /tmp/*.out
echo "Please upload the file:" $FILENAME
exit
}
trap end SIGHUP SIGINT SIGTERM



#~~~ Continuous collection by will run outside loop ~~~
date >> /tmp/vmstat.out; vmstat $INTERVAL $ITERATION >> /tmp/vmstat.out &
if [ "$iostatold" -eq "1" ]; then
	iostat -t  -x $INTERVAL $ITERATION >> /tmp/iostat.out &
	else
	iostat -t -z -x $INTERVAL $ITERATION >> /tmp/iostat.out &
fi
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
		echo "$(date +%T): Collecting data : Iteration "$(($CURRENT_ITERATION))
		date >> /tmp/top.out; top -n 1 -b >> /tmp/top.out
		if [ "$iotopyes" -eq "1" ]; then
			date >> /tmp/iotop.out; iotop -n 1 -b >> /tmp/iotop.out
		fi
		date >> /tmp/mem.out; cat /proc/meminfo >> /tmp/mem.out
		date >> /tmp/free.out; free -m >> /tmp/free.out
		date >> /tmp/psf.out; ps auxf >> /tmp/psf.out
		date >> /tmp/ps_auxwwwm.out; ps auxwwwm >> /tmp/ps_auxwwwm.out
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
end
