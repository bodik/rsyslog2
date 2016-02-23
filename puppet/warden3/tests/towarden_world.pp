warden3::towarden { "upstream":
	install_dir => "/opt/warden_towarden_upstream",
	receiver_warden_server => "took2.ics.muni.cz",
	receiver_cert_path => "/opt/hostcert",
	sender_warden_server => "minos47-2.zcu.cz",
	sender_cert_path => "/opt/warden_towarden_upstream/sendercert",
}
