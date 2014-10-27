#!/usr/bin/puppet

class mongomine::database {
  notice($name)
  include mongodb

  # Install the MongoDB shard server

  mongodb::mongod { 'mongod_Shard1':
    mongod_instance => 'Shard1',
    mongod_port     => 27019,
    mongod_replSet  => 'Shard1',
    mongod_shardsvr => 'true',
    mongod_bind_ip  => '127.0.0.1',
  }

  mongodb::mongod { 'mongod_Shard2':
    mongod_instance => 'Shard2',
    mongod_port     => 27020,
    mongod_replSet  => 'Shard2',
    mongod_shardsvr => 'true',
    mongod_bind_ip  => '127.0.0.1',
  }

  mongodb::mongod { 'mongod_Shard3':
    mongod_instance => 'Shard3',
    mongod_port     => 27021,
    mongod_replSet  => 'Shard3',
    mongod_shardsvr => 'true',
    mongod_bind_ip  => '127.0.0.1',
  }

  mongodb::mongod { 'mongod_Shard4':
    mongod_instance => 'Shard4',
    mongod_port     => 27022,
    mongod_replSet  => 'Shard4',
    mongod_shardsvr => 'true',
    mongod_bind_ip  => '127.0.0.1',
  }

  # Install the MongoDB Loadbalancer server

  mongodb::mongos { 'mongos_shardproxy':
    mongos_instance      => 'mongoproxy',
    mongos_port          => 27017,
    mongos_configServers => "127.0.0.1:27018",
    mongos_bind_ip  => '127.0.0.1',
  }

  mongodb::mongod { 'mongod_config':
    mongod_instance  => 'shardproxy',
    mongod_port      => 27018,
    mongod_replSet   => '',
    mongod_configsvr => 'true',
    mongod_bind_ip  => '127.0.0.1',
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

