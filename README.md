docker-ip2proxy-mysql
========================

This is a pre-configured, ready-to-run MySQL server with IP2Proxy Proxy IP database. It simplifies the development team to install and set up the proxy IP database in MySQL server. The setup script supports the [commercial database packages](https://www.ip2location.com/database/ip2proxy) and [free LITE package](https://lite.ip2location.com). Please register for a download account before running this image.

### Usage

1. Run this image as daemon with your username, password, and download code registered from [IP2Location](https://www.ip2location.com).

       docker run --name ip2proxy -d -e TOKEN={DOWNLOAD_TOKEN} -e CODE={DOWNLOAD_CODE} -e MYSQL_PASSWORD={MYSQL_PASSWORD} ip2proxy/mysql

    **ENV VARIABLE**

    TOKEN – Download token obtained from IP2Location.

    CODE – The CSV file download code (PX1... PX11). You may get the download code from your account panel.

    MYSQL_PASSWORD - Password for MySQL admin.

2. The installation may take minutes to hour depending on your internet speed and hardware. You may check the installation status by viewing the container logs. Run the below command to check the container log:

        docker logs -f ip2proxy

    You should see the line of `> Setup completed` if you have successfully complete the installation.

### Connect to it from an application

    docker run --link ip2proxy:ip2proxy-db -t -i application_using_the_ip2proxy_data

### Make the query

    mysql -u admin -pYOUR_MYSQL_PASSWORD -h ip2proxy-db ip2proxy_database -e 'SELECT * FROM `ip2proxy_database` WHERE INET_ATON("8.8.8.8") BETWEEN ip_from AND ip_to LIMIT 1'

**Notes:** If not result returned, the lookup IP address is not a proxy IP address.



### Update IP2Proxy Database

To update your IP2Proxy database to latest version, please run the following  command:

```
docker exec -it ip2proxy ./update.sh
```



### Sample Code Reference

[https://www.ip2location.com/tutorials](https://www.ip2location.com/tutorials)
