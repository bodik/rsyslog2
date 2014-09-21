#!/bin/sh
apt-get update
apt-get install -y git puppet
cd /puppet
sh rediser.install.sh
sh elk.install.sh
sh fprobe.install.sh

