rsyslog metacentrum.cz
======================

This software suite is designed to aid creating and maintaining data processing
cloud within a realm of cesnet.cz and beyond. It is based on masterless puppet 
and bash.

rsyslog
-------

logstash
--------

elasticsearch
-------------

mongodb
-------

mongomine
---------

puppet
------

Creating and maintaining component of this suite is managed by masterless
puppet.  Each major component should provide a puppet module and set of
install/check and other scripts within itself. Whole suite is bootsrapped from
git.

	wget home.zcu.cz/~bodik/bootstrap.install.sh && sh bootstrap.install.sh
	cd /puppet && ls -l

*****


komponenta.install.sh - nainstaluje/opravi
komponenta.check.sh - zkontroluje (--noop --show_diff)
komponenta/ doprovodne soubory, nekdy templaty pro puppet

templates/ -- vetsina templates a souboru se kterymi operuje puppet

tests/ -- testy komponent



*****

komponenty:

* rsyslog-server, rsyslog-client
* rediser
* elk - elasticsearch,logstash,kibana
* fprobe - testovaci netflow sonda

* jenkins
  system pro automatizaci ukonu, pouziva rozhrani pro ruzne cloudy

	* metacloud.init - dev/ops prostredi
	* kvm.init - pouze lokalni testy, spatne sitovani
	* magrathea.init - vyzaduje specialni prava (ops metacentrum.cz)


usecases:
	* jenkins -- lokalni vm debian wheezy, NAT
		* sh bootstrap.install.sh
		* sh jenkins.install.sh
		* metacloud.init creds
			$ ### jako jenkins vyrobit kredence
			$ scp odkudsi:tajnyadresar/* /dev/shm/
			$ ### vyrobit oneauth susenku
			$ metacloud.init login
			$ exit

			/dev/shm/username	- 
			/dev/shm/usercert.pem	- metacloudi certifikat
			/dev/shm/one_x509	- metacloudi susenka
	
		* metacloud.init templates	- instalace templates
		* browser debian.localdomain:8081
			* spousteni scenaru pres jenkins, vysledky v jobs console output
		* rucni prace VMNAME=XXX metacloud.init start, ssh, ...


	* ops/dev
		* sh bootstrap.install.sh -- update repo
		* sh check_stddev.sh -- kontrola zmen
		* sh .install.sh / puppet apply -- provedeni zmen
		* sh tests/ testy


