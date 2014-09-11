class { "rsyslog::server":
	version => "meta",
	rediser_server => $redis_server,
}
