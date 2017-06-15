#!/bin/bash
# Shatadru Bandyopadhyay
# https://github.com/shatadru/SGPD/

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
mkdir -p etc
mkdir -p etc/lvm

cat /etc/lvm/lvm.conf > etc/lvm/lvm.conf
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
cat /etc/multipath.conf > etc/multipath.conf
multipath -l &> multipath_l

# log 
dmesg > dmesg
tail -100 /var/log/messages > messages

ls -laR /dev > ls_laR_dev

tar -cf /tmp/"$FILENAME" $DIR 2>/dev/null

cd -

echo "======================================="
echo "Please upload the file:" /tmp/$FILENAME
echo "======================================="

