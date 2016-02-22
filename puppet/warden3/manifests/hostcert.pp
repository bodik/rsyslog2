# == Resource: warden3::hostcert
#
# Resource will ensure provisioning of SSL certificated used by other w3 components.
# If certificate is not present in install_dir, module will generate new key and
# request signing it from warden ca service located on warden server. Formelly class 
# truned into reusable resource.
#
# TODO: allow changing ca service port
#
# === Parameters
#
# [*dest_dir*]
#   directory to generate certificate
#
# [*warden_server*]
#   name or ip of warden server, overrides autodiscovery
#
# [*warden_server_auto*]
#   enables warden server autodiscovery
#
# [*warden_server_service*]
#   service name to be discovered
#
define warden3::hostcert (
	$dest_dir = "/opt/hostcert",

        $warden_server = undef,
        $warden_server_auto = true,
        $warden_server_service = "_warden-server._tcp",
) {
	#notice("INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include ${name}\"")

        if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }
	
	ensure_resource( 'package', 'curl', {} )

	ensure_resource( 'file', "$dest_dir", { "ensure" => directory, "owner" => "root", "group" => "root", "mode" => "0755",} )

	exec { "gen cert ${name}":
		command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca.sh -s ${warden_server_real} -d ${dest_dir}",
		creates => "${dest_dir}/${fqdn}.crt",
		require => [File["$dest_dir"], Package["curl"]],
	}
}
