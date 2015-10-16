#!/bin/sh

if [ -z $1 ]; then
	echo "ERROR: install_dir missing
fi
install_dir=$1

free -m > ${install_dir}/txtcmds/usr/bin/free
cat /etc/hostname > ${install_dir}/honeyfs/etc/hostname
cat /etc/hosts > ${install_dir}/honeyfs/etc/hosts
cat /proc/cpuinfo > ${install_dir}/honeyfs/proc/cpuinfo 
cat /proc/meminfo > ${install_dir}/honeyfs/proc/meminfo
cat /proc/version > ${install_dir}/honeyfs/proc/version
