import sqlite3
import datetime
import random
import string
#########################
DBNAME = "wmk.s3db"
#########################

def randomStringDigits(stringLength=50):
    """Generate a random string of letters and digits """
    lettersAndDigits = string.ascii_letters + string.digits
    return ''.join(random.choice(lettersAndDigits) for i in range(stringLength))

    
def log_add(errstr, PRINT_ERRORS='NO'):
    try:
        with open("logs/check_user_access.log", "a") as logfile:
            logfile.write('\n' + str(datetime.datetime.now()) + "\t" + str(errstr))
            if (PRINT_ERRORS == 'YES'):
                print(str(datetime.datetime.now()) + "\t" + str(errstr))
        logfile.close()
    except Exception as err:
        print("# ERROR. Func log_add: " + str(err))
    return 0
    

def check_assecckey(accesskey):
    # Create access key fom userid, message_str
    # if ERROR 0, message_str
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ###########################
        # Check IF user exist
        cursor.execute("SELECT userid,access_key FROM access_keys WHERE access_key=?;", (accesskey,))
        rowcount = cursor.fetchall() # при исп. fetchone если нет результата вылетает ошибка
        if (len(rowcount) == 0):
            result = 0,"Access key does not exist."
        elif  (len(rowcount) > 1):
            result = 0, "DB errors 75"
        elif  (len(rowcount) == 1):
            # if find ONE record then return ID, uName
            result = int(rowcount[0][0]), 'Access key is valid.' #rowcount[0][1] #ID, UserName


    except sqlite3.DatabaseError as err:
        cursor.close()
        log_add("E_SQLite_func_check_assecckey: "+ str(err))
        return 0, "BE. check_assecckey error #49. Text: "+ str(err)
    else:
        cursor.close()
    return result


def grant_accesskey(userid, logout='NO'):
    # Create access key fom userid, message_str
    # if ERROR 0, message_str
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ###########################
        # Check IF user exist
        uid, uname = user_get('','',userid)
        if (uid == 0):
            cursor.close()
            return 0, "User not exist" #exit
        ##########################
        # Check accesskey
        cursor.execute("SELECT userid FROM access_keys WHERE userid=? ;", (uid,))
        #print(cursor.fetchall()) # or use fetchone() для получения первого результата
        rowcount = cursor.fetchall() # при исп. fetchone если нет результата вылетает ошибка
        
        if  (len(rowcount) > 0):
            cursor.execute("DELETE FROM access_keys WHERE userid=? ;", (uid,))
            conn.commit()
            # LOGOUT
            if (logout == 'YES'):
                cursor.close()
                log_add("I_func_grant_accesskey: " + "delete access_keys from userid: " + str(uid))
                # I must get delete from DB confurm and the send userdata <>0 status
                return uid, "AccessKey deleted" #exit

        ##########################
        # ADD accesskey
        accesskey = randomStringDigits(50)
        cursor.execute("INSERT INTO access_keys (userid,access_key) VALUES (?, ?);", (userid, accesskey))
        if (cursor.rowcount == 0):
            userdata = 0, "Error on insert accesskey to db."
            log_add("W_func_grant_accesskey: " + "Error on insert accesskey to db for userid: " + str(uid))
        else:
            conn.commit()
            userdata = accesskey, "Access key added."
            log_add("I_func_grant_accesskey: " + "Insert accesskey to db for userid: " + str(uid))

    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_func_grant_accesskey: "+ str(err))
        cursor.close()
        return 0, "BE. grant_accesskey error #97. Text: "+ str(err)
    else:
        cursor.close()
    return userdata


def user_get(email, passphrase, userid=0):
    # If OK return userid, username
    # else return 0,"User not exist"
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()

        cursor.execute("SELECT userid, username FROM users WHERE (email=lower(?) AND passphrase=?) OR userid=? ;", (email, passphrase, userid))

        #print(cursor.fetchall()) # or use fetchone() для получения первого результата
        rowcount = cursor.fetchall() # при исп. fetchone если нет результата вылетает ошибка
        if (len(rowcount) == 0):
            userdata = 0,"user not exist"
        elif  (len(rowcount) > 1):
            userdata = 0, "E_func_user_get 56"
        elif  (len(rowcount) == 1):
            # if find ONE record then return ID, uName
            userdata = rowcount[0][0], rowcount[0][1] #ID, UserName

        log_add("I_func_user_get: " + str(userdata))
    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_func_user_get: "+ str(err))
        cursor.close()
        userdata = 0, "user_add user_get error #128. Text: " + str(err)
    else:
        cursor.close()

    return userdata


def user_add(username, email, passphrase, parent_mail = 'none'):
    # Check IF user exist return 0,"User exist"
    # else: 1,"user_add - e@mail - ok"
    if ( (len(email) < 4) or (len(passphrase) < 4)  \
        or \
       (len(username) > 30) or (len(email) > 40) or (len(passphrase) > 40) or (len(parent_mail) > 40) ):
        return 0,"Inconnect input user data (to short or to long)"
        
        
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        
        ###########################
        # Check IF user exist
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM users WHERE (email=lower(?));", (email,))
        rowcount = cursor.fetchall() # cursor.fetchall())  or use fetchone() для получения первого результата
        if (len(rowcount) > 0):
            cursor.close()
            return 0,"User already exist." #exit
            

        ##########################
        # ADD user
        cursor.execute("INSERT INTO users (username, email, passphrase, parent_uid) VALUES ( ?, lower(?), ?, 0);", (username, email, passphrase,))
        if (cursor.rowcount == 0):
            userdata = 0, "User added error #154. Something going wrong..."
        else:
            conn.commit()
            ###########################
            # Add parent 
            if ((parent_mail != 'None') and (parent_mail != '')):
                    userid, username = user_get(email, passphrase)
                    puserid, mess = add_parent(userid, parent_mail)
                    if (int(puserid) != 0):
                        userdata = 1, "User added secussfuly: "+ email + '. Parent: '+ parent_mail
                    else:  
                        userdata = 1, "User added secussfuly: "+ email + '. But on connected parent e-mail: '+ parent_mail + ' we got error: ' +  mess + '. You can add parent in app. menu.'
            else:
                userdata = 1, "User added secussfuly: "+ email

    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_func_user_add" + str(err))
        cursor.close()
        userdata = 0, "BE. user_add error #172. Text: "+ str(err)
    else:
        cursor.close()
    return userdata


def add_parent(userid, parent_mail):
    # On ERROR return 0 and message
    # 
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ###########################
        # Get parent id
        cursor.execute("SELECT userid FROM users WHERE (email=lower(?));", (parent_mail,))
        rowcount = cursor.fetchall() # cursor.fetchall())  or use fetchone() для получения первого результата
        if (len(rowcount) != 1):
            cursor.close()
            if (len(rowcount) > 1):
                return 0,"more than one e-mail found" #exit
            elif  (len(rowcount) == 0):
                return 0,"we can not find this e-mail " #exit
        else:
            puserid = rowcount[0][0]
        
        if (puserid == userid):
                 return 0,"parent email cannot be the same as kid has. " #exit
        ##########################
        # ADD user
        
        cursor.execute("UPDATE users SET parent_uid = ? WHERE userid = ? ;", (puserid, userid))
        if (cursor.rowcount == 0):
            userdata = 0, "E_add_parent error - #204"
            log_add("W_add_parent. Parentid: " + str(puserid) +' for userid: ' + str(userid))
        else:
            conn.commit()
            userdata = int(puserid), "Parent: "+ parent_mail +" connected to account."
            log_add("I_add_parent. Success. Parent id: " + str(puserid) +' for user id: ' + str(userid))
         
         
         
    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_add_parent" + str(err))
        cursor.close()
        userdata = 0, "BE. E_add_parent error #216. Text: "+ str(err)
    else:
        cursor.close()
    return userdata
    
    
def get_kids(userid):
    # On ERROR return 0 and message
    # 
    
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ###########################
        # Get parent id
        cursor.execute("SELECT userid, username FROM users WHERE (parent_uid=?);", (userid,))
        rows = cursor.fetchall() # cursor.fetchall())  or use fetchone() для получения первого результата
        if (len(rows) == 0):
                userdata = '',"Kid not found." #exit
        else:
            kids_list = '';
            for row in rows:
                kids_list = kids_list + str(row[0]) + ' ' + str(row[1]) + ' '
            kids_list = kids_list[:len(kids_list)-1] #cut last space
            userdata = kids_list, 'Kids count: ' + str(len(rows))
         
    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_add_parent" + str(err))
        cursor.close()
        userdata = '', "BE. get_kids error - #261. Text: "+ str(err)
    else:
        cursor.close()
    return userdata    
 

def takegps(userid, gpsdatatime, gpslatitude, gpslongitude, gpsaltitude):
    # Get GPS location and put in into db
    # On ERROR return 0 and message
    # 
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ##########################
        # ADD GPS
        
        cursor.execute("INSERT INTO  locations (userid, datatimestamp, latitude, longitude, altitude) VALUES (?, ?, ?, ?, ?);", (userid, gpsdatatime, gpslatitude, gpslongitude, gpsaltitude))
        if (cursor.rowcount == 0):
            userdata = 0, "Error on insert gps to db."
            log_add("W_func_takegps: " + "Error on insert gps to db for userid: " + str(userid)) +'GPS: ' + str(gpslatitude) + ' '+ str(gpslongitude) + ' '+ str(gpsaltitude)
        else:
            conn.commit()
            userdata = userid, "GPS data added."
            log_add("I_func_takegps: " + "Insert accesskey to db for userid: " + str(userid))
         
         
         
    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_takegps: " + str(err))
        cursor.close()
        userdata = 0, "BE. E_func_takegps error #275. Text: "+ str(err)
    else:
        cursor.close()
    return userdata 
    
def getgps(userid, kuserid):
    # Get last gps loatons for parent request 
    # On ERROR return 0 and message
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ##########################
        # Get parent id
        cursor.execute("SELECT userid FROM users WHERE (parent_uid=? and userid=?);", (userid, kuserid,))
        rowcount = cursor.fetchall() # cursor.fetchall())  or use fetchone() для получения первого результата
        if (len(rowcount) == 0):
            #userdata =   0,'','','','','Kid ['+ str(kuserid) +'] was not found.' #exit
            userdata =   0,'','','','','Kid was not found.' #exit
        else:   
            # Get gps id
            cursor.execute("SELECT datetime(datatimestamp,'unixepoch'), latitude, longitude, altitude FROM locations WHERE (userid=?) and (id = (select MAX(id) from locations  WHERE userid = ?));", (kuserid, kuserid,))
            rowcount = cursor.fetchall() # cursor.fetchall())  or use fetchone() для получения первого результата
            if (len(rowcount) == 0):
                #userdata =  0,'','','','','GPS data for ['+ str(kuserid) +'] was not found.' #exit
                userdata =  0,'','','','','GPS data for was not found.' #exit
                
            else:
                #           1             datatimestamp   latitude        longitude         altitude
                userdata = len(rowcount), rowcount[0][0], rowcount[0][1], rowcount[0][2], rowcount[0][3], 'GPS found.' 

    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_takegps: " + str(err))
        cursor.close()
        userdata = 0,'','','','','Function getgps DB error: '+str(err)
    else:
        cursor.close()
    return userdata  


def setdata(userid, datatype, data):
    # put data into db
    # On ERROR return "error" and message
    # 
    if (len(userid) < 5) or (datatype == '') or (len(data) == 0) or (not type(data) is dict):
        return "error", "setdata -  wrong JSON data format "+str(userid) +' '+ datatype+ ' ' + str(len(data)) +' ' + str(type(data))
    
    
    try:
        
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ##########################
        
        if (datatype == 'hwinfo'):
            for key, value in data.items():
                if len(key) < 3:
                    continue
                cursor.execute("INSERT INTO  userconfig (userid, param_name, param_value, param_type) VALUES (?, ?, ?, ?);", (userid, key, value, datatype))
                if (cursor.rowcount == 0):
                    userdata = "done", "Error on insert " + datatype + " to db."
                    log_add("W_func_setdata: " + "Error on insert " + datatype + " to db for userid: " + str(userid) +'key/value: ' + str(key) + ' / '+ str(value))
                else:
                    
                    userdata = "done", datatype + " data added."
                    log_add("I_func_setdata: " + "Insert " + datatype + " data to db for userid: " + str(userid))
         
            conn.commit()
                
    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_takegps: " + str(err))
        cursor.close()
        userdata = "error", "BE. E_func_takegps error #275. Text: "+ str(err)
    else:
        cursor.close()
    return userdata  




def getdata(userid, kuserid, datatype, param):
    # Get last user data 
    # On ERROR return 0 and message
    
    if (len(userid) < 5) or (len(kuserid) < 5) or (len(datatype) < 3) or (len(param) < 3):
        return 0, "getdata. Wrong JSON data format: Val. " + str(userid) + ' ' + str(kuserid) + ' ' + str(datatype) + ' ' + str(param),'',''
        
    try:
        conn = sqlite3.connect(DBNAME)  # или :memory: чтобы сохранить в RAM
        cursor = conn.cursor()
        ##########################
        # Get parent id
        cursor.execute("SELECT userid FROM users WHERE (parent_uid=? and userid=?);", (userid, kuserid,))
        rowcount = cursor.fetchall() # cursor.fetchall())  or use fetchone() для получения первого результата
        if (len(rowcount) == 0):
            userdata =   0,'Kid was not found.','','' #exit
        else:   
            # Get data
            # !   in next use dict for returrn many results
            #print(str(kuserid) + ' ' + datatype + ' ' +  param)
            cursor.execute("SELECT datetime(timestamp,'localtime'), param_value FROM userconfig WHERE id = (select MAX(id) from userconfig  WHERE userid = ?  AND param_type = ?  AND param_name = ? );", (kuserid, datatype, param,))
            rowcount = cursor.fetchall() # cursor.fetchall())  or use fetchone() для получения первого результата
            if (len(rowcount) == 0):
                userdata =  0,'Data not found.','','' #exit
            else:
                #           1                              Datatime        Value
                userdata = len(rowcount), 'Data found.',  rowcount[0][0], rowcount[0][1]

    except sqlite3.DatabaseError as err:
        log_add("E_SQLite_getdata: " + str(err))
        cursor.close()
        userdata = 0,'Function getdata DB error: '+str(err),'',''
    else:
        cursor.close()
    return userdata  
    
########################################################################################################################

# userid, uname = user_get("kem@kem.ru", "passphrase", "0")
# print(userid, uname)
# userid, uname = user_add("keminc5", "kem5@kem.ru", "passphraseZ")
# print(userid, uname)