rsyslog2

* masterless puppet + bash automatizace cloudu

* sudo (wget home.zcu.cz/~bodik/bootstrap.install.sh && sh bootstrap.install.sh)
* cd /puppet && ls -l

komponenta.install.sh - nainstaluje/opravi
komponenta.check.sh - zkontroluje (--noop --show_diff)
komponenta/ doprovodne soubory, nekdy templaty pro puppet

templates/ -- vetsina templates a souboru se kterymi operuje puppet

tests/ -- testy komponent


komponenty:

* rsyslog-server, rsyslog-client
* rediser
* elk - elasticsearch,logstash,kibana
* fprobe - testovaci netflow sonda


* jenkins
  system pro automatizaci ukonu, pouziva rozhrani pro ruzne cloudy

	* metacloud.init - dev/ops prostredi

	* kvm.init - pouze lokalni testy, spatne sitovani
	* magrathea.init - neni vhodne vyzaduje specialni kredence
		(ops metacentrum.cz)


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
			/dev/shm/sshkey		- metacloudi klic
			/dev/shm/userkey.pem	- metacloudi klic
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


