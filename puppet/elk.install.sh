
puppet apply --modulepath=/puppet -e 'include elk::esd'
puppet apply --modulepath=/puppet -e 'include elk::lsl'
puppet apply --modulepath=/puppet -e 'include elk::kbn'


