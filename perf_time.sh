#!/bin/bash
#
#  Author : Shatadru Bandyopadhyay
#
# this script collects time,strace of few commands 
# the concept is to find out if there is any lag from OS end and what is system call which is taking time
#
# Licenced under GPLv3
#
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

function freecache {
echo 3 > /proc/sys/vm/drop_caches
}

function check {

if [ "$1" -eq "0" ];then
echo Command $2 $3 $4 completed successfully
echo
else
echo Command $2 $3 $4 failed
echo
fi
}
SAVE=`pwd`





tempdirname=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1`
mkdir /tmp/$tempdirname/

DIR=/tmp/$tempdirname/

echo "Collecting perf data"
mkdir -p $DIR"perf"; cd $_
perf record -a -g sleep 20
check $? perf record
perf archive
check $? perf archive
cd ..

declare -a arr=("free -m" "rpm -q kernel" "ls" "df -lh" "ps aux" )

## now loop through the above array
for j in "${arr[@]}"
do

i=`echo $j|sed 's/ /_/g'`

   echo "Command for which we are collecting data is : $i"
   echo "-----------------------------------------------------"   
   freecache
   strace   -fTtt -o $DIR"$i".strace_1.out $j >/dev/null
   check $? strace -fTtt
   freecache
   strace     -fc -o $DIR"$i".strace_2.out $j >/dev/null 
   freecache
   check $? strace -fc
   ltrace -S  -fc -o $DIR"$i".ltrace_1.out $j >/dev/null
   check $? ltrace -S -fc
   freecache
   { time $j >/dev/null;             }  2>> $DIR$i.time.out
   check $? time
   freecache
   { /usr/bin/time -v $j >/dev/null; }  2>> $DIR$i.time_v.out
   check $? /usr/bin/time -v

done


echo;echo "Creating tar ball..."
echo "Please standby..."
sleep 5
tar cvf $SAVE/data.tar $DIR > /dev/null
echo;echo "Plese upload data.tar to the case...."
