#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

USER_AGENT="Mozilla/5.0+(compatible; IP2Proxy/MySQL-Docker; https://hub.docker.com/r/ip2proxy/mysql)"
CODES=("PX1-LITE PX2-LITE PX3-LITE PX4-LITE PX5-LITE PX6-LITE PX7-LITE PX8-LITE PX9-LITE PX10-LITE PX11-LITE PX1 PX2 PX3 PX4 PX5 PX6 PX7 PX8 PX9 PX10 PX11")

if [ -f /ip2proxy.conf ]; then
	/etc/init.d/mysql restart >/dev/null 2>&1
	tail -f /dev/null
fi

if [ "$TOKEN" == "FALSE" ]; then
	error "Missing download token."
fi

if [ "$CODE" == "FALSE" ]; then
	error "Missing database code."
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
	error "Download code is invalid."
fi

CODE=$(echo $CODE | sed 's/-//')

echo -n " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && error "[ERROR]" || success "[OK]"

cd /_tmp

echo -n " > Download IP2Proxy database "

if [ "$IP_TYPE" == "IPV4" ]; then
	wget -O ipv4.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
elif [ "$IP_TYPE" == "IPV6" ]; then
	wget -O ipv6.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
else
	wget -O ipv4.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1
	wget -O ipv6.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv4.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv4.zip)" ] && error "[QUOTA EXCEEDED]"

	[ ! -z "$(grep 'NO PERMISSION' ipv6.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv6.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)
	[ $? -ne 0 ] && error "[FILE CORRUPTED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)
	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
fi

success "[OK]"

for ZIP in $(ls | grep '.zip'); do
	CSV=$(unzip -l $ZIP | grep -Eo 'IP2PROXY-IP(V6)?.*CSV')

	echo -n " > Decompress $CSV from $ZIP "

	unzip -jq $ZIP $CSV

	if [ ! -f $CSV ]; then
		error "[ERROR]"
	fi

	success "[OK]"
done

/etc/init.d/mysql start > /dev/null 2>&1

echo -n " > [MySQL] Create database \"ip2proxy_database\" "
RESPONSE="$(mysql -e 'CREATE DATABASE IF NOT EXISTS ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[$RESPONSE]" || success "[OK]"

echo -n " > [MySQL] Create table \"ip2proxy_database_tmp\" "

RESPONSE="$(mysql ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database_tmp' 2>&1)"

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

RESPONSE="$(mysql ip2proxy_database -e 'CREATE TABLE ip2proxy_database_tmp (`ip_from` DECIMAL(39,0) UNSIGNED NOT NULL,`ip_to` DECIMAL(39,0) UNSIGNED NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

for CSV in $(ls | grep '.CSV'); do
	echo -n " > [MySQL] Load $CSV into database "
	RESPONSE="$(mysql ip2proxy_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2proxy_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\n'\''' 2>&1)"
	[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"
done

echo -n " > [MySQL] Drop table \"ip2proxy_database\" "

RESPONSE="$(mysql ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Rename table \"ip2proxy_database_tmp\" to \"ip2proxy_database\" "

RESPONSE="$(mysql ip2proxy_database -e 'RENAME TABLE ip2proxy_database_tmp TO ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo " > [MySQL] Create MySQL user \"admin\""

mysql -e "CREATE USER admin@'%' IDENTIFIED BY '$MYSQL_PASSWORD'" > /dev/null 2>&1
mysql -e "GRANT ALL PRIVILEGES ON *.* TO admin@'%' WITH GRANT OPTION" > /dev/null 2>&1

echo " > Setup completed"
echo ""
echo " > You can now connect to this MySQL Server using:"
echo ""
echo "   mysql -u admin -p$MYSQL_PASSWORD ip2proxy_database"
echo ""

echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" > /ip2proxy.conf
echo "TOKEN=$TOKEN" >> /ip2proxy.conf
echo "CODE=$CODE" >> /ip2proxy.conf
echo "IP_TYPE=$IP_TYPE" >> /ip2proxy.conf

rm -rf /_tmp

tail -f /dev/null