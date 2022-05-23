

## Admin 서버에서 접근 가능한 위치에 DB 서버를 구성한다. 

모든 구성은 mysql 을 기준으로 테스트 하였으며 Admin 서버에 직접 설치하였다.

```console
$ sudo  apt-get update
$ sudo  apt-get install mysql-server﻿
$ sudo  ufw allow mysql
$ sudo  systemctl start mysql
$ sudo systemctl enable mysql
$ sudo /usr/bin/mysql -u root -p
비번 ubuntu
mysql>  show variables like "%version%";
mysql> CREATE DATABASE master;
mysql> SHOW DATABASES;
mysql> CREATE USER 'linux'@'%' IDENTIFIED BY 'PASSWORD';
mysql> GRANT ALL PRIVILEGES ON *.* TO 'linux'@'%' WITH GRANT OPTION;
mysql> GRANT PROXY ON ''@'' TO 'linux'@'%' WITH GRANT OPTION;
mysql> FLUSH PRIVILEGES;
mysql> SHOW GRANTS FOR 'linux'@'%';

// 외부 접속 허용
$ sudo  vi /etc/mysql/my.cnf
..
[mysqld]
bind-address            = 0.0.0.0
$ sudo systemctl restart mysql
$ netstat -ntlp | grep mysql
tcp    0    0 0.0.0.0:3306     0.0.0.0:*     LISTEN      7206/mysqld
```
