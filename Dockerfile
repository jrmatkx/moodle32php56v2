# Docker-Moodle
# Dockerfile for moodle instance. more dockerish version of https://github.com/sergiogomez/docker-moodle
# Forked from Jon Auer's docker version. https://github.com/jda/docker-moodle
FROM ubuntu:16.04
MAINTAINER Jonathan Hardison <jmh@jonathanhardison.com>

VOLUME ["/var/moodledata"]
EXPOSE 80 443

COPY moodle-config.php /var/www/html/config.php

# Keep upstart from complaining
# RUN dpkg-divert --local --rename --add /sbin/initctl
# RUN ln -sf /bin/true /sbin/initctl

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Database info and other connection information derrived from env variables. See readme.
# Set ENV Variables externally Moodle_URL should be overridden.
ENV MOODLE_URL http://127.0.0.1

ADD ./foreground.sh /etc/apache2/foreground.sh

RUN apt-get update && \
    apt-get install -y python-software-properties software-properties-common && \
    LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && \
    apt-get update && \
	apt-get -y install mysql-client pwgen python-setuptools curl git unzip apache2 php5.6 \
		php5.6-gd libapache2-mod-php5.6 postfix wget supervisor php5.6-pgsql curl libcurl3 \
		libcurl3-dev php5.6-curl php5.6-xmlrpc php5.6-intl php5.6-mysql git-core php5.6-xml php5.6-mbstring php5.6-zip php5.6-soap cron && \
	cd /var/www/html && \
	mkdir moodle && \
	cd /tmp && \
	git clone -b MOODLE_32_STABLE git://git.moodle.org/moodle.git --depth=1 && \
	mv /tmp/moodle/* /var/www/html/moodle && \
	rm /var/www/html/index.html && \
	chown -R www-data:www-data /var/www/html/moodle && \
	chmod +x /etc/apache2/foreground.sh

#cron
COPY moodlecron /etc/cron.d/moodlecron
RUN chmod 0644 /etc/cron.d/moodlecron

# Enable SSL, moodle requires it
RUN a2enmod ssl && a2ensite default-ssl  #if using proxy dont need actually secure connection

# Cleanup, this is ran to reduce the resulting size of the image.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/dpkg/* /var/lib/cache/* /var/lib/log/*

CMD ["/etc/apache2/foreground.sh"]
