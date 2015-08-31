rm -fr /data1/ceph_data/*
rm -fr /data2/ceph_data/*

kill -9  `pidof ceph-osd`
kill -9  `pidof ceph-mon`
kill -9  `pidof ceph-mds`

./start_mon.sh /etc/ceph/ceph.conf /data1/ceph_data/
./start_osd_pyth.sh  0 /data1/ceph_data/ /etc/ceph/ceph.conf /data2/ceph_data

ceph osd pool create testpool 128 128
rbd create testimg --size 100000 -p testpool                                             
