#!/bin/sh
puppet apply --modulepath=/puppet:/puppet/3rdparty "$@"
