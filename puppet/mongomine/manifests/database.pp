#!/usr/bin/puppet

class mongomine::database (
	$shards = 4,
) {
	notice($name)
	include mongodb
	
	# Install the MongoDB config server -- mongos
	mongodb::mongod { 'mongod_config':
		mongod_instance  => 'shardproxy',
		mongod_port      => 27018,
		mongod_replSet   => '',
		mongod_configsvr => 'true',
		mongod_bind_ip  => '127.0.0.1',
		notify => Exec["sleep 10"],
	}

	#minos is too fast/slow, we have to wait for config server to come up unless mongos will fail	
	exec { "sleep 10":
		command => "/bin/sleep 10",
		refreshonly => true,
	}
	
	# Install the MongoDB Loadbalancer server -- mongos
	mongodb::mongos { 'mongos_shardproxy':
		mongos_instance      => 'mongoproxy',
		mongos_port          => 27017,
		mongos_configServers => "127.0.0.1:27018",
		mongos_bind_ip  => '127.0.0.1',
		require => [Mongodb::Mongod["mongod_config"], Exec["sleep 10"]],
	}

	# Install the MongoDB shard server
	define mongomineshard {
		mongodb::mongod { "mongod_Shard${name}":
			mongod_instance => "Shard${name}",
			mongod_port     => $name,
			mongod_replSet  => '',
			mongod_shardsvr => 'true',
			mongod_bind_ip  => '127.0.0.1',
			require => [Mongodb::Mongod["mongod_config"], Mongodb::Mongos["mongos_shardproxy"]],
			notify => Exec["setup-mongomine.py"],
		}
	}
	$shards_real = range(30001, 30000+$shards)
	mongomineshard { $shards_real: }



	package { "python-pip": ensure => installed, }
	package { "pymongo":	ensure => installed,
		provider => "pip",	
	}
	#will ensure registering num of shards and setup basic db structures/indexes
	exec { "setup-mongomine.py":
		command => "/usr/bin/python /puppet/mongomine/bin/setup-mongomine.py $shards",
		refreshonly => true,
		require => [Mongodb::Mongod["mongod_config"], Mongodb::Mongos["mongos_shardproxy"], Mongomineshard[$shards_real]],
	}




	#autoconfig
	include metalib::avahi
	file { "/etc/avahi/services/mongomine.service":
		source => "puppet:///modules/${module_name}/etc/avahi/mongomine.service",
		owner => "root", group => "root", mode => "0644",
		require => Package["avahi-daemon"], #tady ma byt class ale tvori kruhovou zavislost
		notify => Service["avahi-daemon"],
	}
}
