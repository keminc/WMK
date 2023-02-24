!---- Connection-------
185.58.193.5:3306

yum install mariadb mariadb-libs mariadb-server
mysql: root / MSQL#psw0rd43

/usr/bin/mysqladmin -u root password MSQL#psw0rd43

mysql -uroot -p 


!----------------------


CREATE DATABASE wmk;
GRANT ALL ON wmk.* TO 'wmkru'@'%' IDENTIFIED BY 'wmkru_p@s0rd';
GRANT ALL ON wmk.* TO 'wmkru'@'localhost' IDENTIFIED BY 'wmkru_p@s0rd';

CREATE TABLE locations(
	id INTEGER PRIMARY KEY AUTO_INCREMENT ,
	userid INTEGER NOT NULL,
	timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	longitude VARCHAR(10),
	latitude VARCHAR(10));
	
	
INSERT INTO 	locations SET userid=0, longitude='55,669', latitude='52,669';
	
SELECT * FROM locations;