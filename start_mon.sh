#!/bin/bash
if [ "$#" != "2" ]
then
        echo "Usage: $0 <config_file>  <mon_data_dir>"
        exit
fi

conf_file=$1
echo "Generate new config file to: $conf_file"


#set -v
#set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
monid=`uuidgen`
echo Monitor ID is: $monid

mon_host=`hostname -s`   #host name, where mon running
mon_ip=`ip -4 -o addr | /bin/grep -E '(eth0|wlan)' |  awk '{split($4,a,"/");print a[1]}'`
mon_dir=$2/mon.$mon_host
net_mask=`echo $mon_ip | awk -F. '{print $1"."$2"."$3".0/24"}'`

if [ -d $mon_dir ];
then
   echo "$mon_dir already exists."
   exit
else
   echo "Monitor dir: $mon_dir"
fi

function get_mon_port
{
        port=6789
    until ! nc -z $mon_ip $port > /dev/null ; do
        let port+=1
    done
        echo $port
}

mon_port=`get_mon_port`
sed "s/__FSID__/$monid/" $DIR/ceph_template.conf > $conf_file
sed -i "s/6789/$mon_port/"  $conf_file

sed -i "s/__MON_IP__/$mon_ip/"  $conf_file
esc_str=`echo $mon_dir | sed 's/\//\\\\\//g'`
sed -i "s/__MON_DATA_DIR__/$esc_str/"  $conf_file
sed -i "s/__MON_HOST__/$mon_host/"  $conf_file
esc_str=`echo $net_mask | sed 's/\//\\\\\//g'`
sed -i "s/__PUB_NET_MASK__/$esc_str/" $conf_file

ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'

ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'

ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring

monmaptool --create --add $mon_host $mon_ip --fsid $monid /tmp/monmap
mkdir -p $mon_dir
ceph-mon --mkfs -i $mon_host --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring -c $conf_file

echo "Starting monitor service."
set -v
ceph-mon -i $mon_host --pid-file $mon_dir/../mon.$mon_host.pid -c $conf_file
                                                                              
