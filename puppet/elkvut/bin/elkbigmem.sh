puppet apply --modulepath=/puppet -e 'class { "elk::esd": esd_heap_size => "6g" }'
#sh forall_esd.sh "puppet apply --modulepath=/puppet -e \"class { 'elk::esd': esd_heap_size => '3g' }\""
