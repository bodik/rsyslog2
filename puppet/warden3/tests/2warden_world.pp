warden3::2warden { "upstream":
	install_dir => "/opt/warden_2warden_upstream",
	receiver_warden_server => "minos47-2.zcu.cz",
	receiver_cert_path => "/opt/hostcert",
	sender_warden_server => "took2.ics.muni.cz",
	sender_cert_path => "/opt/warden_2warden_upstream/sendercert",
}
