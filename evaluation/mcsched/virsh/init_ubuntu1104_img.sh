#!/bin/sh
if [ $# -eq 0 ]; then
        echo "Usage: $0 <ubuntu vm id1 id2 ...>"
        exit
fi
clone_postfix=""
if [ "BASE_POSTFIX" == "" ]; then
	echo "BASE_POSTFIX must be specified!"
	exit
else
        clone_postfix=$BASE_POSTFIX
fi

img_dir=/guest_images
#base_img=ubuntu1104-small.qcow2
#clone_prefix=ubuntu1104-small-
base_img=ubuntu1104-apps$BASE_POSTFIX.qcow2
clone_prefix=ubuntu1104
host_prefix=cag
guest_ips=( 143.248.92.95 143.248.92.96 143.248.92.97 143.248.92.98 143.248.92.196 143.248.92.201 143.248.92.202 143.248.92.102 143.248.92.103 143.248.92.104 )
guest_gateway=143.248.92.1

if [ ! -e $img_dir/$base_img ]; then
	echo "Error: $img_dir/$base_img doesn't exist"
	exit
fi

modprobe nbd max_part=8 2>/dev/null
for i in $*; do 
    clone_img_path=$img_dir/${clone_prefix}${clone_postfix}-${i}.qcow2
    rm -f $clone_img_path
    qemu-img create -b $img_dir/$base_img -f qcow2 $clone_img_path
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
