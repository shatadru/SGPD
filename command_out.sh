#!/bin/bash
# Collects command outputs 

host="$(hostname)"

# Creating temporary directory to save the files
tempdirname=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1`
mkdir /tmp/$tempdirname/
DIR=/tmp/$tempdirname

cd $DIR

FILENAME="command_outputs-$host-$(date +%d%m%y_%H%M%S).tar"

#### Commands to Run #####

# system Info
date &> date
uname -a &> uname
echo $host &> hostname

# lvm 
lvs -o +devices &> lvs
vgs -o +devices &> vgs
pvs  &> pvs
lvdisplay &> lvdisplay
vgdisplay &> vgdisplay
pvdisplay &> pvdisplay

# device mapper 
dmsetup table &> dmestup_table
dmsetup info -c &> dmsetup_info_c

# multipath -l
multipath -l &> multipath_l

# log 
dmesg > dmesg
tail -100 /var/log/messages > messages


tar -cf /tmp/"$FILENAME" $DIR 2>/dev/null

cd -

echo "======================================="
echo "Please upload the file:" /tmp/$FILENAME
echo "======================================="

