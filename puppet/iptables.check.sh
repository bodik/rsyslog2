echo "INFO: IPTABLESCHECK ======================="
puppet apply --modulepath=/puppet --noop --show_diff -e 'include iptables'
