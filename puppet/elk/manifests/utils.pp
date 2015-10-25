class elk::utils() {

	# needed for elk script queries
	package { ["curl"]:
		ensure => installed,
	}

	exec { "gem install elasticsearch":
		command => "/usr/bin/gem install elasticsearch",
		unless => "/usr/bin/gem list | /bin/grep elasticsearch",
	}

	package { ["nodejs", "npm"]: 
		ensure => installed, 
	}
	file { "/usr/local/bin/node":
		ensure => link,
		target => "/usr/bin/nodejs",
	}
	exec { "install elasticdump":
		command => "/usr/bin/npm install elasticdump -g",
		unless => "/usr/bin/npm -g list | /usr/bin/tr -c '[:print:][:cntrl:]' '?' | /bin/grep elasticdump",
		require => Package["npm"],
	}
}
