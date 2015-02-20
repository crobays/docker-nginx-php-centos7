#!/bin/bash

function find_replace_add_string_to_file() {
	find="$1"
	replace="${2//\//\\/}"
	file="$3"
	label="$4"
	if grep -q ";$find" "$file" # The exit status is 0 (true) if the name was found, 1 (false) if not
	then
		action="Uncommented"
		sed -i "s/;$find/$replace/" "$file"
	elif grep -q "#$find" "$file" # The exit status is 0 (true) if the name was found, 1 (false) if not
	then
		action="Uncommented"
		sed -i "s/#$find/$replace/" "$file"
	elif grep -q "$replace" "$file"
	then
		action="Already set"
	elif grep -q "$find" "$file"
	then
		action="Overwritten"
		sed -i "s/$find/$replace/" "$file"
	else
		action="Added"
		echo -e "\n$replace\n" >> "$file"
	fi
	echo " ==> Setting $label ($action) [$replace in $file]"
}

cp /conf/nginx.conf /etc/nginx/nginx.conf
if [ -f "/project/nginx.conf" ]
then
	ln -sf "/project/nginx.conf" /etc/nginx/nginx.conf
fi

find_replace_add_string_to_file "daemon .*" "daemon off;" /etc/nginx/nginx.conf "NGINX daemon off"

rm -rf /var/log/nginx
mkdir /var/log/nginx

file="/conf/nginx-virtual.conf"
if [ -f "/project/$NGINX_CONF" ]
then
	file="/project/$NGINX_CONF"
fi
rm -rf /etc/nginx/conf.d/*
cp -f "$file" /etc/nginx/conf.d/virtual.conf

if [ "$PUBLIC_PATH" ]
then
	mkdir -p "$PUBLIC_PATH"

	if [ ! -f "$PUBLIC_PATH/index.php" ]
	then
		echo " ==> Creating index.php in $PUBLIC_PATH"
		echo "<h1>You are running $PUBLIC_PATH/index.php on NGINX-PHP on Docker!</h1>" > "$PUBLIC_PATH/index.php"
	fi
	find_replace_add_string_to_file "root \/.*" "root $PUBLIC_PATH;" /etc/nginx/conf.d/virtual.conf "NGINX public path"
fi

php_code="echo '('.(array_key_exists('DOMAIN',\$_SERVER) ? str_replace('.', '\\\\\.', implode('|', array_unique(array_map(function(\$domain){\$d = array_reverse(explode('.', \$domain)); return \$d[1].'.'.\$d[0];}, in_array(substr(\$_SERVER['DOMAIN'], 0, 1), array('[', '{')) ? json_decode(str_replace(\"'\", '\"', \$_SERVER['DOMAIN']), 1) : array(\$_SERVER['DOMAIN']))))) : '').')';"
domain="$(php -r "$php_code")"

if [ "$domain" == "()" ]
then
	echo " ==> NOT using Access-Control-Allow-Origin headers"
	php_code="file_put_contents('/etc/nginx/conf.d/virtual.conf', preg_replace('/# == add header ==(.|\n)*# == add header ==/', '', file_get_contents('/etc/nginx/conf.d/virtual.conf')));"
	php -r "$php_code"
elif [ "$domain" ]
then
	find_replace_add_string_to_file "example\\\.com" "$domain" /etc/nginx/conf.d/virtual.conf "Access-Control-Allow-Origin headers for $domain"
fi

