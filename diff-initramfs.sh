#!/bin/bash
#Author Shatadru Bandyopadhyay
# By default it will show files only available in working initramfs (or files missing from non working )
# -v/-a will show all differnce ###TODO



caseid=$(zenity --entry --text "Case id :" --title "initramfs analyser" --width 300 --height 150 2>/dev/null);
if [ -z "$caseid" ];then
	tempdirname=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1`
	echo "caseid not mentioned,,, files will be saved in /tmp/$tempdirname/"
else
	tempdirname=`echo $caseid`
	echo "files will be saved in /tmp/$tempdirname/"
fi
mkdir /tmp/$tempdirname/

badinit=$(zenity --file-selection --text "Select bad initramfs : "  --title "Select bad initramfs : " --width 300 --height 150 2>/dev/null);
goodinit=$(zenity --file-selection --text "Select good initramfs : "  --title  "Select good initramfs : " --width 300 --height 150 2>/dev/null);

if [ "$badinit" -eq "$goodinit" ];then
	echo "You have selected same file... exiting... try again";
fi

mkdir -p /tmp/$tempdirname/good
mkdir  -p /tmp/$tempdirname/bad

cp $goodinit /tmp/$tempdirname/good
cp $badinit  /tmp/$tempdirname/bad


function extract_initramfs (){
zcat `ls` | cpio -id

if [ "$?" -ne "0" ];then
	 /usr/lib/dracut/skipcpio `ls` | gunzip -c | cpio -i -d
	 if [ "$?" -ne "0" ];then
		xz -dc < `ls` | cpio --quiet -i --make-directories
		 if [ "$?" -ne "0" ];then
			echo "FAILED TO EXTRACT FILE.. exiting"
		       	exit
		fi
	
	fi

 fi

}

cd /tmp/$tempdirname/good/
extract_initramfs
cd /tmp/$tempdirname/bad
extract_initramfs

cd ..

tree /tmp/$tempdirname/good/ > good.tree
tree /tmp/$tempdirname/bad > bad.tree

rm -rf /tmp/$tempdirname/out.txt
outfile="/tmp/$tempdirname/out.txt"
echo "=================================" |tee -a $outfile
echo "Below files are only available in working initramfs  :" |tee -a $outfile

echo " diff -y -t good.tree bad.tree |grep -i '<'" |tee -a $outfile
echo "=================================" |tee -a $outfile
echo |tee -a $outfile

diff -y -t good.tree bad.tree > diff.tree 
diff -y -t good.tree bad.tree|grep -i '<' |tee -a $outfile
echo "=================================" |tee -a $outfile

echo |tee -a $outfile

echo "Files have been extracted in /tmp/$tempdirname"

gedit $outfile
