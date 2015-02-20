FROM centos:centos7
ENV HOME /root
# RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]

MAINTAINER Crobays <crobays@userex.nl>
ENV DOCKER_NAME nginx-php-centos

ADD /conf/nginx.repo /etc/yum.repos.d/nginx.repo
RUN rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm

RUN yum -y update && \
	yum clean all
RUN yum -y install epel-release && \
	yum clean all
RUN yum -y install nginx && \
	yum clean all
RUN yum install -y \
	php-gd \
	php-cli \
	php-fpm \
	php-mysql \
	php-pgsql \
	php-sqlite \
	php-curl \
	php-mcrypt \
	php-memcache \
	php-intl \
	php-imap \
	php-redis \
	php-tidy \
	php-xml \
	pwgen \
	supervisor \
	bash-completion \
	openssh-server \
	psmisc tar

RUN yum clean all

# Exposed ENV
ENV TIMEZONE Etc/UTC
ENV ENVIRONMENT prod
ENV PUBLIC_PATH /project/public
ENV NGINX_CONF nginx-virtual.conf

VOLUME  ["/project"]
WORKDIR /project

# HTTP ports
EXPOSE 80 443

RUN echo '/sbin/my_init' > /root/.bash_history

RUN mkdir -p /etc/service/nginx && echo -e "#!/bin/bash\nnginx" > /etc/service/nginx/run
RUN mkdir -p /etc/service/php && echo -e "#!/bin/bash\nphp-fpm -c /etc/php.ini" > /etc/service/php/run

RUN mkdir -p /etc/my_init.d && \
	echo -e "#!/bin/bash\nln -sf \"/usr/share/zoneinfo/$TIMEZONE\" /etc/localtime" > /etc/my_init.d/01-timezone.sh

ADD /scripts/nginx-config.sh /etc/my_init.d/02-nginx-config.sh
ADD /scripts/php-config.sh /etc/my_init.d/03-php-config.sh
ADD /scripts/my_init /sbin/my_init

RUN chmod +x /etc/my_init.d/* && chmod +x /etc/service/*/run && chmod +x /sbin/my_init

# Clean up APT when done.
RUN yum clean all && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD /conf /conf


