#!/bin/bash
if [ "$#" != "4" ]
then
	echo $#
        echo "Usage: $0 <id> <data_dir>  <config_file> <journal_dir>"
        exit
fi

#set -v
#set -x

id=$1
osd_data=$2/osd.$id  #the dir where osd device is mounted to
conf_file=$3
journal_file=$4/osd.$id.journal
auth_file=$2/auth-keyring

osd_host=`hostname -s`   #host name, where osd running

if [ ! -f $conf_file ];
then
   echo "$conf_file not exists."
   exit
fi

if [ -f $journal_file ];
then
        read -r -p "$journal_file already exists, delete it? [y/N] " response
        response=${response,,}    # tolower
        if [[ $response =~ ^(yes|y)$ ]]
        then
                rm -f $journal_file
        else
                exit
        fi
fi

if [ ! -d $osd_data ];
then
        mkdir -p $osd_data
fi
echo "OSD data dir: $osd_data"

osd_img=$2/osd.$id.img
if [ -f $osd_img ];
then
        read -r -p "Disk image file $osd_img already exists, delete it? [y/N] " response
        response=${response,,}    # tolower
        if [[ $response =~ ^(yes|y)$ ]]
        then
                rm -f $osd_img
        else
                exit
        fi
fi

#dd if=/dev/zero of=$osd_img bs=1M count=0 seek=$osd_size #2048ä¸.M blockï¼~L?E?G
#mkfs.xfs -f $osd_img

sed -i "/\[osd\.$id\]/, +5 d" $conf_file #delete old config for this osd

echo "[osd.$id]" >> $conf_file
echo "	host = $osd_host" >> $conf_file
echo "	devs = $osd_img" >> $conf_file
echo "	osd journal = $journal_file" >> $conf_file
echo "	osd data = $osd_data" >> $conf_file
#mount -o loop $osd_img $osd_data

ceph osd create  -c $conf_file

ceph-osd  -i $id --mkfs --mkkey -c $conf_file &> $auth_file

#for ceph 0.82, at least on ARM matrix, should run above command like:
#ceph-osd -i 0 --osd-data=$osd_data --osd-journal=$journal_file --mkfs --mkjournal --convert-filestore
ceph auth add osd.$id osd 'allow *' mon 'allow profile osd' -i $osd_data/keyring -c $conf_file

#?@~Pæ·»å~J| ç¬.?L?]~WOSD?W¶ä?M?I§è?Læ­¤å~Q½ä»¤?@~Q
if  ceph osd tree -c $conf_file | grep "host $osd_host"  ;
then
        echo Host $osd_host existing in bucket.
else
        echo Add new host "$osd_host" into bucket
        ceph osd crush add-bucket $osd_host host    -c $conf_file
        ceph osd crush move $osd_host root=default -c $conf_file
fi

ceph osd crush add osd.$id 1.0 host=$osd_host -c $conf_file

#run the osd service
echo Now start OSD service ...
echo "ceph-osd -i $id -c $conf_file"
set -v
ceph-osd -i $id  -c $conf_file
                                                                                  
