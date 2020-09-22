#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

if [ ! -f /config ]; then
	error "Missing configuration file."
fi

TOKEN=$(grep 'TOKEN' /config | cut -d= -f2)
CODE=$(grep 'CODE' /config | cut -d= -f2)
MYSQL_PASSWORD=$(grep 'MYSQL_PASSWORD' /config | cut -d= -f2)

echo -n " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && error "[ERROR]" || success "[OK]"

cd /_tmp

echo -n " > Download IP2Proxy database "

wget -O database.zip -q --user-agent="Docker-IP2Proxy/MySQL" http://www.ip2location.com/download?token=${TOKEN}\&productcode=${CODE} > /dev/null 2>&1

[ ! -f database.zip ] && error "[DOWNLOAD FAILED]"

[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[DENIED]"

[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

[ $(wc -c < database.zip) -lt 512000 ] && error "[FILE CORRUPTED]"

success "[OK]"

echo -n " > Decompress downloaded package "

unzip -q -o database.zip

CSV="$(find . -name 'IP2PROXY*.CSV')"

[ -z "$CSV" ] && error "[FILE CORRUPTED]" || success "[OK]"

echo -n " > [MySQL] Create table \"ip2proxy_database_tmp\" "

RESPONSE="$(mysql ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database_tmp; CREATE TABLE ip2proxy_database_tmp LIKE ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Load CSV data into \"ip2proxy_database_tmp\" "

RESPONSE="$(mysql ip2proxy_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2proxy_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\r\n'\''' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Rename table \"ip2proxy_database\" to \"ip2proxy_database_drop\" "

RESPONSE="$(mysql ip2proxy_database -e 'RENAME TABLE ip2proxy_database TO ip2proxy_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Rename table \"ip2proxy_database_tmp\" to \"ip2proxy_database\" "

RESPONSE="$(mysql ip2proxy_database -e 'RENAME TABLE ip2proxy_database_tmp TO ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

echo -n " > [MySQL] Drop table \"ip2proxy_database_drop\" "

RESPONSE="$(mysql ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && error "[ERROR]" || success "[OK]"

rm -rf /_tmp

success "   [UPDATE COMPLETED]"