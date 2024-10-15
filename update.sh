#!/bin/bash

text_primary() { echo -n " $1 $(printf '\055%.0s' {1..80})" | head -c 80; echo -n ' '; }
text_success() { printf "\e[00;92m%s\e[00m\n" "$1"; }
text_danger() { printf "\e[00;91m%s\e[00m\n" "$1"; exit 0; }

if [ ! -f /ip2proxy.conf ]; then
	text_error "Missing configuration file."
fi

TOKEN=$(grep 'TOKEN' /ip2proxy.conf | cut -d= -f2)
CODE=$(grep 'CODE' /ip2proxy.conf | cut -d= -f2)
IP_TYPE=$(grep 'IP_TYPE' /ip2proxy.conf | cut -d= -f2)
MYSQL_PASSWORD=$(grep 'MYSQL_PASSWORD' /ip2proxy.conf | cut -d= -f2)

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

text_primary " > [MySQL] Create table \"ip2proxy_database_tmp\" "

RESPONSE="$(mysql ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database_tmp; CREATE TABLE ip2proxy_database_tmp LIKE ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"

for CSV in $(ls | grep '.CSV'); do
	text_primary " > [MySQL] Load $CSV into database "
	RESPONSE="$(mysql ip2proxy_database -e 'LOAD DATA LOCAL INFILE '\'''$CSV''\'' INTO TABLE ip2proxy_database_tmp FIELDS TERMINATED BY '\'','\'' ENCLOSED BY '\''\"'\'' LINES TERMINATED BY '\''\n'\''' 2>&1)"
	[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"
done

text_primary " > [MySQL] Rename table \"ip2proxy_database\" to \"ip2proxy_database_drop\" "

RESPONSE="$(mysql ip2proxy_database -e 'RENAME TABLE ip2proxy_database TO ip2proxy_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"

text_primary " > [MySQL] Rename table \"ip2proxy_database_tmp\" to \"ip2proxy_database\" "

RESPONSE="$(mysql ip2proxy_database -e 'RENAME TABLE ip2proxy_database_tmp TO ip2proxy_database' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"

text_primary " > [MySQL] Drop table \"ip2proxy_database_drop\" "

RESPONSE="$(mysql ip2proxy_database -e 'DROP TABLE IF EXISTS ip2proxy_database_drop' 2>&1)"

[ ! -z "$(echo $RESPONSE)" ] && text_error "[ERROR]" || text_success "[OK]"

rm -rf /_tmp

text_success "   [UPDATE COMPLETED]"