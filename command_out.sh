#!/bin/bash
# Collects command outputs 

host="$(hostname)"

dir="/tmp/${host}_command_out"
mkdir $dir

#### Commands to Run #####

# system Info
date > date
uname -a > uname
echo $host > hostname

# lvm 
lvs -o +devices > lvs
vgs -o +devices > vgs
pvs  > pvs
lvdisplay > lvdisplay
vgdisplay > vgdisplay
pvdisplay > pvdisplay

# device mapper 
dmsetup table > dmestup_table
dmsetup info -c > dmsetup_info_c

# multipath -l
multipath -l > multipath_l

# log 
dmesg > dmesg
tail -100 /var/log/messages > messages


tar -cvf ${host}_command_out.tar.bz2 $dir
