class { "rsyslog::server":
	version => "meta",
	rediser_server => $rediser_server,
}
