#!/bin/bash
 echo 'select id, userid, datetime(timestamp,"localtime" ), datetime(datatimestamp,"unixepoch"),datatimestamp , longitude, latitude from locations ;' | sqlite3 wmk.s3db
 