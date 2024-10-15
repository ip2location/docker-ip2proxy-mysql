#!/bin/bash

text_primary() { echo -n " $1 $(printf '\055%.0s' {1..70})" | head -c 70; echo -n ' '; }
text_success() { printf "\e[00;92m%s\e[00m\n" "$1"; }
text_danger() { printf "\e[00;91m%s\e[00m\n" "$1"; exit 0; }

USER_AGENT="Mozilla/5.0+(compatible; IP2Proxy/MySQL-Docker; https://hub.docker.com/r/ip2proxy/mysql)"
CODES=("PX1-LITE PX2-LITE PX3-LITE PX4-LITE PX5-LITE PX6-LITE PX7-LITE PX8-LITE PX9-LITE PX10-LITE PX11-LITE PX1 PX2 PX3 PX4 PX5 PX6 PX7 PX8 PX9 PX10 PX11")

if [ -f /ip2proxy.conf ]; then
	/etc/init.d/mariadb restart >/dev/null 2>&1
	tail -f /dev/null
fi

if [ "$TOKEN" == "FALSE" ]; then
	text_error "Missing download token."
fi

if [ "$CODE" == "FALSE" ]; then
	text_error "Missing database code."
fi

if [ "$MYSQL_PASSWORD" == "FALSE" ]; then
	MYSQL_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})"
fi

FOUND=""
for i in "${CODES[@]}"; do
	if [ "$i" == "$CODE" ] ; then
		FOUND="$CODE"
	fi
done

if [ -z $FOUND == "" ]; then
	text_error "Download code is invalid."
fi

CODE=$(echo $CODE | sed 's/-//')

text_primary " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && text_error "[ERROR]" || text_success "[OK]"

cd /_tmp

text_primary " > Download IP2Proxy database "

if [ "$IP_TYPE" == "IPV4" ]; then
	wget -O ipv4.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv4.zip)" ] && text_error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv4.zip)" ] && text_error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_error "[FILE CORRUPTED]"
else
	wget -O ipv6.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv6.zip)" ] && text_error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv6.zip)" ] && text_error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_error "[FILE CORRUPTED]"
fi

text_success "[OK]"

for ZIP in $(ls | grep '.zip'); do
	CSV=$(unzip -l $ZIP | grep -Eo 'IP2PROXY-IP(V6)?.*CSV')

	text_primary " > Decompress $CSV from $ZIP "

	unzip -jq $ZIP $CSV

	if [ ! -f $CSV ]; then
		text_error "[ERROR]"
	fi

	text_success "[OK]"
done

/etc/init.d/mariadb start > /dev/null 2>&1

text_primary " > [MySQL] Create database \"ip2proxy_database\" "
RESPONSE="$(mariadb -e 'CREATE DATABASE IF NOT EXISTS ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[$RESPONSE]" || text_success "[OK]"

text_primary " > [MySQL] Create table \"ip2proxy_database_tmp\" "

RESPONSE="$(mariadb ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database_tmp' 2>&1)"

case "$CODE" in
	PX1|PX1LITE )
		FIELDS=',`country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'
	;;

	PX2|PX2LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'
	;;

	PX3|PX3LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL'
	;;

	PX4|PX4LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL'
	;;

	PX5|PX5LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	PX6|PX6LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL'
	;;

	PX7|PX7LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL'
	;;

	PX8|PX8LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL,`last_seen` INT(10) NOT NULL'
	;;

	PX9|PX9LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL,`last_seen` INT(10) NOT NULL, `threat` VARCHAR(128)'
	;;

	PX10|PX10LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL,`last_seen` INT(10) NOT NULL, `threat` VARCHAR(128)'
	;;

	PX11|PX11LITE )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL,`last_seen` INT(10) NOT NULL, `threat` VARCHAR(128),`provider` VARCHAR(256) NOT NULL'
	;;
esac

RESPONSE="$(mariadb ip2proxy_database -e 'CREATE TABLE ip2proxy_database_tmp (`ip_from` DECIMAL(39,0) UNSIGNED NOT NULL,`ip_to` DECIMAL(39,0) UNSIGNED NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"

for CSV in $(ls | grep '.CSV'); do
	text_primary " > [MySQL] Load $CSV into database "
	RESPONSE="$(mariadb ip2proxy_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2proxy_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\n'\''' 2>&1)"
	[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"
done

text_primary ' > [MySQL] Drop table "ip2proxy_database" '

RESPONSE="$(mariadb ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"

text_primary " > [MySQL] Rename table \"ip2proxy_database_tmp\" to \"ip2proxy_database\" "

RESPONSE="$(mariadb ip2proxy_database -e 'RENAME TABLE ip2proxy_database_tmp TO ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"

echo ' > [MySQL] Create MySQL user "admin"'

mariadb -e "CREATE USER admin@'%' IDENTIFIED BY '$MYSQL_PASSWORD'" > /dev/null 2>&1
mariadb -e "GRANT ALL PRIVILEGES ON *.* TO admin@'%' WITH GRANT OPTION" > /dev/null 2>&1

echo " > Setup completed"
echo ""
echo " > You can now connect to this MySQL Server using:"
echo ""
echo "   mariadb -u admin -p$MYSQL_PASSWORD ip2proxy_database"
echo ""

echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" > /ip2proxy.conf
echo "TOKEN=$TOKEN" >> /ip2proxy.conf
echo "CODE=$CODE" >> /ip2proxy.conf
echo "IP_TYPE=$IP_TYPE" >> /ip2proxy.conf

rm -rf /_tmp

tail -f /dev/null
