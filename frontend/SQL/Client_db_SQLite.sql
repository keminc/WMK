---  CLIENT DB
CREATE TABLE locations( 	
	recid INTEGER PRIMARY KEY AUTOINCREMENT, 
	userid INTEGER NOT NULL, timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 	
	locationX VARCHAR(10), 	
	locationY VARCHAR(10)  , 
	altitude varchar(10));

CREATE TABLE config( 	
	id INTEGER PRIMARY KEY AUTOINCREMENT,	
	param_name VARCHAR(20), 	
	param_value VARCHAR(200), 
	param_type VARCHAR(10)   );