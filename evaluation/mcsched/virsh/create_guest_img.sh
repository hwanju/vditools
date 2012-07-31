#!/bin/sh
if [ $# -lt 2 ]; then
	echo "Usage: $0 <guest name (ubuntu1104|win7_64bit)> <id1 id2 ... (e.g., =0: base image, >0: cloned image>"
        exit
fi
clone_postfix=""
if [ "POSTFIX" == "" ]; then
	echo "POSTFIX must be specified!"
	exit
else
        clone_postfix=$POSTFIX
fi

guest_name=$1
shift

img_dir=/guest_images
init_img=$guest_name-apps-mcsched.qcow2
base_img=$guest_name-apps$POSTFIX.qcow2
clone_prefix=$guest_name
host_prefix=cag

# get ip information from eval_config
cfg_fn=../config/eval_config
if [ ! -e $cfg_fn ]; then
	echo "Error: make sure $cfg_fn exists"
	exit
fi
i=0
for ip in $(grep GUEST_IP $cfg_fn); do
	if [ "$ip" == "GUEST_IP" ]; then
		continue
	fi
	guest_ips[i]=$ip
	i=$(( $i + 1 ))
done
guest_gateway=$(echo ${guest_ips[0]} | sed 's/[[:digit:]]*$/1/g');

if [ $1 -ne 0 -a ! -e $img_dir/$base_img ]; then
	echo "Error: $img_dir/$base_img doesn't exist"
	exit
fi

modprobe nbd max_part=8 2>/dev/null
for i in $*; do
    if [ $i -eq 0 ]; then
	clone_img_path=$img_dir/$base_img
    else
	clone_img_path=$img_dir/${clone_prefix}${clone_postfix}-${i}.qcow2
    fi
    rm -f $clone_img_path
    if [ $i -eq 0 ]; then
	qemu-img create -b $img_dir/$init_img -f qcow2 $clone_img_path
	i=$(( $i + 1 ))
    else
	qemu-img create -b $img_dir/$base_img -f qcow2 $clone_img_path
    fi
    if [ "$guest_name" == "win7_64bit" ]; then
	    continue
    fi
    guest_ip=${guest_ips[$(( $i - 1 ))]}
    qemu-nbd -c /dev/nbd0 $clone_img_path
    sleep 3
    mount /dev/nbd0p1 /mnt
    sleep 3

    cd /mnt

    host_id=$(( 10 + $i ))
    host_name=${host_prefix}${host_id}
    echo "" > etc/udev/rules.d/70-persistent-net.rules
    echo $host_name > etc/hostname
    echo 'auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static' > etc/network/interfaces
    echo "address $guest_ip" >> etc/network/interfaces
    echo "gateway $guest_gateway" >> etc/network/interfaces
    echo "netmask 255.255.255.0" >> etc/network/interfaces

    echo 'nameserver 143.248.1.177
nameserver 143.248.2.177
search kaist.ac.kr' > etc/resolv.conf

    cd ..

    umount /mnt
    qemu-nbd -d /dev/nbd0
done
