#!/bin/sh
apt-get update
apt-get install -y git puppet
cd /puppet
sh phase2.install.sh
sh rediser.install.sh
sh elk.install.sh
sh fprobe.install.sh
sh elk/tests/elk.sh
sh netflow/tests/nfdump.sh
sh rediser/tests/rediser.sh

