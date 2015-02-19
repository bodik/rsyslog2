puppet apply --modulepath=/puppet -e 'class { "elk::esd": esd_heap_size => "6g" }'
