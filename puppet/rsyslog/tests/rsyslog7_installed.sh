#!/bin/sh
set -e

dpkg -l rsyslog | grep " 7\.[0-9]"
dpkg -l rsyslog-gssapi | grep " 7\.[0-9]"

echo "RESUTL: OK $0"

