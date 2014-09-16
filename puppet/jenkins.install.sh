wget -q -O - http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | apt-key add -a
puppet apply --modulepath=/puppet -vd -e 'include jenkins'
