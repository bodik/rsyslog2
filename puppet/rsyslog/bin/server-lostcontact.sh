#!/bin/bash

(A="`date \+\%Y/\%m`";find /var/log/hosts/$A -name syslog -mtime +1 -ls | perl -ne '$line=$_ ; m#^.*/(.*?)/syslog$#; my $host=`host $1 2>/dev/null | grep name`; $host =~ /pointer (.*).$/; chomp $line; print "$line $1\n"; ')

#(A="`date \+\%Y/\%m`";find /var/log/hosts/$A -name syslog -mtime +2 -ls)
