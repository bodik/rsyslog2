wget -q -O - http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | apt-key add -a
(cd /puppet && sh phase2.install.sh)
puppet apply jenkins.pp
