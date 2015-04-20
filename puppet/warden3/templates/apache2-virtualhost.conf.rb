Listen *:<%= port %>
<Virtualhost *:<%= port %>>
	
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
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined


	#warden3
	SSLEngine on
	SSLVerifyClient require
	SSLVerifyDepth 4
	SSLOptions +StdEnvVars +ExportCertData
	#SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
	SSLCertificateFile      /opt/hostcert<%= fqdn %>.crt
	SSLCertificateKeyFile   /opt/hostcert<%= fqdn %>.key
	SSLCACertificateFile    /opt/hostcert/cachain.pem

	WSGIScriptAlias /warden3 <%= install_dir %>/warden_server.wsgi
	<Directory <%= install_dir %>/warden_server.wsgi>
		Order allow,deny
		Allow from all
	</Directory>

</Virtualhost>
