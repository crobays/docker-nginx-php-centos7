## Run NGINX in a container with PHP-FPM on top of CentOS 7

	docker build \
		 --tag crobays/nginx-php-centos7 \
		 .

	docker run \
		-v ./:/project \
		-e PUBLIC_PATH=/project/public \
		-e TIMEZONE=Etc/UTC \
		-it --rm \
		crobays/nginx-php-centos7
