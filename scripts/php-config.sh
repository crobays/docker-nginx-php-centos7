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
	elif grep -xq "$find" "$file"
	then
		action="Overwritten"
		sed -i "s/$find/$replace/" "$file"
	else
		action="Added"
		echo -e "\n$replace\n" >> "$file"
	fi
	echo " ==> Setting $label ($action) [$replace in $file]"
}

#php5enmod mcrypt

if [ "$TIMEZONE" != "" ]
then
	find_replace_add_string_to_file "date.timezone =.*" "date.timezone = $TIMEZONE" /etc/php.ini "PHP timezone"
else
	echo " ==> Timezone not set (not given TIMEZONE)"
fi

find_replace_add_string_to_file "daemonize =.*" "daemonize = no" /etc/php-fpm.conf "PHP daemon off"
#find_replace_add_string_to_file "daemonize =.*" "daemonize = no" /etc/php.d/cli/php.ini "PHP daemon off"

if [ "${ENVIRONMENT:0:4}" != "prod" ]
then
	find_replace_add_string_to_file "display_errors =.*" "display_errors = On" /etc/php.ini "PHP display errors on"
	find_replace_add_string_to_file "display_startup_errors =.*" "display_startup_errors = On" /etc/php.ini "PHP display startup errors on"
	#find_replace_add_string_to_file "display_startup_errors =.*" "display_startup_errors = On" /etc/php.d/cli/php.ini "PHP display startup errors on"
fi

# Disable default mimetype
# find_replace_add_string_to_file "default_mimetype =.*" "default_mimetype = \"\"/" /etc/php.ini "PHP default mimetype none"
# find_replace_add_string_to_file "default_mimetype =.*/default_mimetype = \"\"/" /etc/php.d/cli/php.ini "PHP "

find_replace_add_string_to_file ";listen.owner =.*" "listen.owner = nginx/" /etc/php-fpm.d/www.conf "PHP owner to nginx"
find_replace_add_string_to_file ";listen.group =.*" "listen.group = nginx/" /etc/php-fpm.d/www.conf "PHP group to nginx"
find_replace_add_string_to_file ";listen.mode =.*" "listen.mode = 0660/" /etc/php-fpm.d/www.conf "PHP owner to 0660"

if [ -f "/project/php-fpm.ini" ]
then
	ln -sf "/project/php-fpm.ini" /etc/php.ini
fi

# if [ -f "/project/php-cli.ini" ]
# then
# 	ln -sf "/project/php-cli.ini" /etc/php.d/cli/php.ini
# fi

if [ -f "/project/php-fpm.conf" ]
then
	ln -sf "/project/php-fpm.conf" /etc/php-fpm.d/php-fpm.conf
fi

if [ -f "/project/php-fpm-www.conf" ]
then
	cp -f "/project/php-fpm-www.conf" /etc/php-fpm.d/www.conf
fi

while read -r e
do
	strlen="${#e}"
	if [ "${e:$strlen-1:1}" == "=" ] || [ "$e" == "${e/=/}" ] || [ $strlen -gt 100 ]
	then
		continue
	fi
	
	echo "env[${e/=/] = \"}\"" >> /etc/php-fpm.d/www.conf
done <<< "$(env)"

chown nginx:nginx /var/run/php-fpm
