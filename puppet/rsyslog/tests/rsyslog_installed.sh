#!/bin/sh
set -e

dpkg -l rsyslog | grep " 8\.[0-9]"
dpkg -l rsyslog-gssapi | grep " 8\.[0-9]"
dpkg -l rsyslog-relp | grep " 8\.[0-9]"

echo "RESUTL: OK $0"

