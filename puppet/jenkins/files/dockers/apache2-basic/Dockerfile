FROM debian:jessie
MAINTAINER DexBodik <dextor.bodik@civ.zcu.cz>

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		apache2 \
		git \
		vim \
		mc \
		krb5-user \
		ca-certificates \
		wget \
	&& wget -O /etc/krb5.conf http://meta.cesnet.cz/metafiles/krb5.conf.zcu \
	&& rm -r /var/lib/apt/lists/* \
	&& apt-get clean

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV TERM xterm

RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2enmod headers
RUN /usr/sbin/a2enmod rewrite

EXPOSE 80 443

COPY start.sh /

CMD ["/start.sh"]
