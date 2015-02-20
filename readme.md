# Run NGINX in a container with PHP-FPM on top of CentOS7

	docker build \
		 --name crobays/nginx-php-centos7 \
		 .

	docker run \
		-v ./:/project \
		-e PUBLIC_PATH: /project/public \
		-e TIMEZONE: Europe/Amsterdam \
		 crobays/nginx-php-centos7
