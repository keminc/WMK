-------------------------
--Create WMK db SQLite
-------------------------
CREATE TABLE IF NOT EXISTS locations(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	userid INTEGER NOT NULL,
	timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	datatimestamp INTEGER DEFAULT 0,
	longitude VARCHAR(10), 	
	latitude VARCHAR(10)  );
	
CREATE  INDEX idx_loc_userid ON locations (userid);
	
--INSERT INTO 	locations SET userid=0, longitude='55,669', latitude='52,669';
--SELECT * FROM locations;

CREATE TABLE IF NOT EXISTS access_keys(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	userid INTEGER NOT NULL,
	crtimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
	access_key VARCHAR(50));
	
CREATE TABLE IF NOT EXISTS users(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	userid INTEGER DEFAULT  (cast(strftime('%s','now') as int) + (ABS(RANDOM()) % (100))),
	crtimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
	email VARCHAR(50),
	passphrase VARCHAR(50),
	username VARCHAR(50)  NOT NULL,
	parent_uid VARCHAR(10)	DEFAULT '0');	

---  INSERT INTO users (username,email,passphrase) VALUES ('keminc','kem@kem.ru','passphrase');	

CREATE TABLE userconfig( 	
    id INTEGER  AUTOINCREMENT,
	userid INTEGER NOT NULL,
	timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	param_name VARCHAR(20), 	
	param_value VARCHAR(200), 
	param_type VARCHAR(10) DEFAULT ''  );
			    
CREATE  INDEX idx_uconfig_userid ON userconfig (userid);	
