#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

if [ -f /config ]; then
	exit 0
fi

if [ "$TOKEN" == "FALSE" ]; then
	error "Missing download token."
fi

if [ "$CODE" == "FALSE" ]; then
	error "Missing product code."
fi

if [ "$MYSQL_PASSWORD" == "FALSE" ]; then
	error "Missing MySQL password."
fi

if [ -z "$(echo $CODE | grep 'PX')" ]; then
	error "Download code is invalid."
fi

echo -n " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && error "[ERROR]" || success "[OK]"

cd /_tmp

echo -n " > Download IP2Proxy database "

wget -O database.zip -q --user-agent="Docker-IP2Proxy/MySQL" http://www.ip2location.com/download?token=${TOKEN}\&productcode=${CODE} 2>&1

[ ! -f database.zip ] && error "[ERROR]"

[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[PERMISSION DENIED]"

[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

[ $(wc -c < database.zip) -lt 512000 ] && error "[FILE CORRUPTED]"

success "[OK]"

echo -n " > Decompress downloaded package "

unzip -q -o database.zip

CSV="$(find . -name 'IP2PROXY*.CSV')"

[ -z "$CSV" ] && error "[ERROR]" || success "[OK]"

/etc/init.d/mysql start >/dev/null 2>&1

echo -n " > [MySQL] Create database \"ip2proxy_database\" "
RESPONSE="$(mysql -e 'CREATE DATABASE IF NOT EXISTS ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[$RESPONSE]" || success "[OK]"

echo -n " > [MySQL] Create table \"ip2proxy_database_tmp\" "

RESPONSE="$(mysql ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database_tmp' 2>&1)"

case "$CODE" in
	PX1|PX1IPV6|PX1LITECSV|PX1LITECSVIPV6 )
		FIELDS=',`country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'
	;;

	PX2|PX2IPV6|PX2LITECSV|PX2LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL'
	;;

	PX3|PX3IPV6|PX3LITECSV|PX3LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL'
	;;

	PX4|PX4IPV6|PX4LITECSV|PX4LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL'
	;;

	PX5|PX5IPV6|PX5LITECSV|PX5LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL'
	;;

	PX6|PX6IPV6|PX6LITECSV|PX6LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL'
	;;

	PX7|PX7IPV6|PX7LITECSV|PX7LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL'
	;;

	PX8|PX8IPV6|PX8LITECSV|PX8LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL,`last_seen` INT(10) NOT NULL'
	;;

	PX9|PX9IPV6|PX9LITECSV|PX9LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL,`last_seen` INT(10) NOT NULL, `threat` VARCHAR(128)'
	;;

	PX10|PX10IPV6|PX10LITECSV|PX10LITECSVIPV6 )
		FIELDS=',`proxy_type` VARCHAR(3) NOT NULL, `country_code` CHAR(2) NOT NULL,`country_name` VARCHAR(64) NOT NULL,`region_name` VARCHAR(128) NOT NULL,`city_name` VARCHAR(128) NOT NULL,`isp` VARCHAR(255) NOT NULL,`domain` VARCHAR(128) NOT NULL,`usage_type` VARCHAR(11) NOT NULL,`asn` VARCHAR(6) NOT NULL,`as` VARCHAR(256) NOT NULL,`last_seen` INT(10) NOT NULL, `threat` VARCHAR(128)'
	;;
esac

if [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
	RESPONSE="$(mysql ip2proxy_database -e 'CREATE TABLE ip2proxy_database_tmp (`ip_from` DECIMAL(39,0) UNSIGNED NOT NULL,`ip_to` DECIMAL(39,0) UNSIGNED NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"
else
	RESPONSE="$(mysql ip2proxy_database -e 'CREATE TABLE ip2proxy_database_tmp (`ip_from` INT(11) UNSIGNED NOT NULL,`ip_to` INT(11) UNSIGNED NOT NULL'"$FIELDS"',INDEX `idx_ip_to` (`ip_to`)) ENGINE=MyISAM' 2>&1)"
fi

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Load CSV data into \"ip2proxy_database_tmp\" "

RESPONSE="$(mysql ip2proxy_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2proxy_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\n'\''' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

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

echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" > /config
echo "TOKEN=$TOKEN" >> /config
echo "CODE=$CODE" >> /config

rm -rf /_tmp

tail -f /dev/null