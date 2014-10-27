puppet apply --modulepath=/puppet -e 'include mongomine::database'
puppet apply --modulepath=/puppet -e 'include mongomine::lsl'
puppet apply --modulepath=/puppet -e 'include mongomine::rsyslogweb'

