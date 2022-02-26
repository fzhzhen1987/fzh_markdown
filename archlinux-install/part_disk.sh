#!/bin/sh
lsblk

read -p "input disk>" disk
echo -e "part = $disk"

read -p "input password>"  -s passwd
echo -e "\n"

echo $passwd |sudo -S fdisk /dev/$disk <<\__EOF__
o
n
p
1

+1200M
n
p
2

+2000M
n
p
3

+2000M
t
1
c
t
2
83
t
3
83
a
1
w
__EOF__

echo $passwd |sudo -S mkfs.fat  /dev/$disk1
echo $passwd |sudo -S mkfs.ext4  /dev/$disk2
echo $passwd |sudo -S mkfs.ext4  /dev/$disk3
未完成