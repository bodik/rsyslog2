Listen *:<%= @port %>
<Virtualhost *:<%= @port %>>
	
	#defaults
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory /var/www/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride None
		Order allow,deny
		allow from all
	</Directory>

	LogLevel warn
	ErrorLog ${APACHE_LOG_DIR}/warden3-server-error.log
	CustomLog ${APACHE_LOG_DIR}/warden3-server-access.log combined


	#warden3
	SSLEngine on
	SSLVerifyClient require
	SSLVerifyDepth 4
	SSLOptions +StdEnvVars +ExportCertData
	#SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
	SSLCertificateFile      /opt/hostcert/<%= @fqdn %>.crt
	SSLCertificateKeyFile   /opt/hostcert/<%= @fqdn %>.key
	SSLCACertificateFile    /opt/hostcert/cachain.pem

	WSGIProcessGroup warden3
        WSGIDaemonProcess warden3 threads=1
	WSGIScriptAlias /warden3 <%= @install_dir %>/warden_server.wsgi
	<Directory <%= @install_dir %>>
		Require all granted
	</Directory>

</Virtualhost>
