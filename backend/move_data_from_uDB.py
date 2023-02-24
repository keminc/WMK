# WMK. Move data from DB
#
# Kotov E.
# v0.1
#

import datetime
import sqlite3
from os.path import isfile, join

'''
Actions:
    Get fresh files from inputdir
    Move file to user cache dir
    Update Backend WMK DB, in locations table
'''
####################################################################
# V A R
####################################################################
PRINT_ERRORS = 'YES'
DBNAME = "wmk.s3db"
InputDir= "../ftp/"
UserCacheDir = "userCache/"

####################################################################
# F U N C T I O N S
####################################################################
def add_to_log(errstr):
    with open("logs/backend.log", "a") as logfile:
        logfile.write(str(datetime.datetime.now()) +"\t" + errstr)
        if (PRINT_ERRORS == 'YES'):
            print(str(datetime.datetime.now()) +"\t" + errstr)
    logfile.close()
    return 0


def move_userDBfiles():
    # Get user DB files list
    import glob
    ufiles = []
    for file in glob.glob(InputDir + "*s3db"):
        ufiles.append(file)
    #print(str(len(ufiles)))
    #print(*ufiles)
    
    # Move files to the cache
    import os
    import re

    # Get user id from file name
    # Reg Exp: https://habr.com/ru/post/349860/
    iserror = 0
    usersIDandDBfiles = []
    for file in ufiles:
        uid = re.search(r'\d{5,}', 'r' + file)  # get user id from file name
        if uid:
            try:
                os.replace(file, UserCacheDir + os.path.basename(file))
            except:
                add_to_log('Error.\t[move_userDBfiles]\tError on move user DB file: ' + os.path.basename(file))
                iserror = iserror + 1
            else:
                add_to_log('Log.\t[move_userDBfiles]\tMove to cache user DB file id: ' + uid[0] + ' file name: ' + os.path.basename(file))
                usersIDandDBfiles.append([uid[0], os.getcwd() + '/' + UserCacheDir + os.path.basename(file)]) # Двумерный массив

    return iserror, usersIDandDBfiles


def move_data_from_userDB(usersIDandDBfiles):
    """
     Upload Data from User App DB file to the Local Backend DB
     If -OK: return rec_count, "Status OK"
     else: 0,"Error. SQLite_func_get_data_from_userDB"

    """
    try:
        #Connect to backend DB
        connect  = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor  = connect .cursor()

        userid = usersIDandDBfiles[0]
        userDBfile = usersIDandDBfiles[1]
        # SQL TRACE
        #connect .set_trace_callback(print)
        cursor .execute("ATTACH DATABASE ? as userDB;", [userDBfile])
        add_to_log("Log.\t[move_data_from_userDB]\tATTACH DATABASE: " +userDBfile)
        cursor .execute("PRAGMA   database_list;")
        #print(cursor .fetchall())
        SQL = """INSERT INTO main.locations (userid, timestamp, longitude, latitude)
            SELECT userid,timestamp,locationX,locationY from userDB.locations
            WHERE (locations.userid = ?)
                AND (length(locationX) BETWEEN 5 AND 6)
                AND (length(locationY) BETWEEN 5 AND 6)
                AND(length(timestamp) BETWEEN 22 AND 25) ;"""
        cursor .execute(SQL, [userid])
        add_to_log('Log.\t[move_data_from_userDB]\tRecords add:' + str(cursor .rowcount) +' from DB: '+ userDBfile);
        connect .commit()
        cursor .execute("DETACH DATABASE userDB;")
        add_to_log("Log.\t[move_data_from_userDB]\tDETACH DATABASE: " + userDBfile)
    except sqlite3.DatabaseError as err:
        add_to_log("Error.\t[move_data_from_userDB]\tSQLite_func_move_data_from_userDB: ", err)
        cursor .close()
        return 123
        #userdata = 0, "move_data_from_userDB - error - 4"
    else:
        connect .close()

    return 0

####################################################################
# M A I N
####################################################################

iserror, usersIDandDBfiles = move_userDBfiles()

for userdb in usersIDandDBfiles:
    iserror = move_data_from_userDB(userdb)




