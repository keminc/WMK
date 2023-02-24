# Users actions controle
#
# Kotov E.
# v0.1
#

import datetime 
import re 
import time 
# WMK DB modile 
import check_user_access 
 
def log_add(errstr, PRINT_ERRORS='NO'): 
    try: 
        with open("logs/users.actions.log", "a") as logfile: 
            logfile.write('\n' + str(datetime.datetime.now()) + "\t" + str(errstr)) 
            if (PRINT_ERRORS == 'YES'): 
                print(str(datetime.datetime.now()) + "\t" + str(errstr)) 
        logfile.close() 
    except Exception as e: 
        print("# ERROR. Func log_add: " + str(e)) 
    return 0 
 
def on_GET_JSON(message): 
    # RETURN: JSON_Message, Message 
    userid = '0'   
    try: 
        action = message.get('action', 'None') 
        ac = message.get('accesskey', 'None') 
        #time.sleep(2) 
 
        #Creatae result var. 
        result = {} 
        result['action'] = action 
        result['data'] = {} 
##############################################################         
        # ACTION REGISTER  
        if action == 'register': 
            # curl --data "{\"action\":\"register\",\"data\":{\"username\":\"usertest6\",\"email\":\"user6@mail.ru\",\"pass\":\"pass123\",\"myparent\":\"email2\"}}" --header   "Content-Type: application/json" http://localhost:8099 
            # Create user 
            un = message.get('data').get('username', 'None') 
            ue = message.get('data').get('email', 'None') 
            up = message.get('data').get('pass', 'None') 
            parent_mail = message.get('data').get('myparent', 'None') # get parent e-mail 
             
             
            addcount, mess = check_user_access.user_add(un, ue, up, parent_mail ) 
 
            if addcount == 1: 
                rs = 'done' 
                userid, username = check_user_access.user_get(ue, up) 
                result['data']['username'] = username 
                result['data']['userid'] = userid 
            else: 
                rs = 'error' 
 
##############################################################             
        # ACTION LOGON  
        elif action == 'logon': 
            # curl --data "{\"action\":\"logon\",\"data\":{\"username\":\"usertest6\",\"email\":\"user6@mail.ru\",\"pass\":\"pass123\"}}" --header   "Content-Type: application/json" http://localhost:8009 
            ue = message.get('data').get('email', 'None') 
            up = message.get('data').get('pass', 'None') 
            userid, mess = check_user_access.user_get(ue, up) 
 
            if int(userid) != 0: 
                # Get access key IF logon is - ok 
                accesskey, mess = check_user_access.grant_accesskey(userid) 
                if accesskey != 0: 
                    rs = 'done' 
                    result['data']['accesskey'] = accesskey 
                    result['data']['userid'] = userid 
                else: 
                    rs = 'error' 
            else: 
                rs = 'error' 
 
##############################################################             
        # ACTION LOGOUT  
        elif action == 'logout': 
            # curl --data  *NOT TESTED* 
            ### Twice check user in bouth function, it maybe a performance problem 
            userid, mess = check_user_access.check_assecckey(ac) 
            if (int(userid) != 0): 
                # Access key is - ok 
                ruserid, mess = check_user_access.grant_accesskey(userid, "YES") # LOGOUT. Delete AccessKey from DB 
                rs = 'done' 
            else: 
                rs = 'error' 
 
############################################################## 
        # ACTION GET DATA  
        elif action == 'validAccessKey': 
            # curl --data "{\"action\":\"getdata\",\"data\":{\"accesskey\":\"Cq9aT6Yd8qokWi6wDvw0frstFNukaBe65YeW3jxBH4itYwvFiM\"}}" --header   "Content-Type: application/json" http://localhost:8009 
            userid, mess = check_user_access.check_assecckey(ac) 
 
            if (int(userid) != 0): 
                # Access key is - ok 
                rs = 'done' 
            else: 
                rs = 'error'
                print("# AC: %s" % ac)      
 
        
############################################################## 
        # ACTION ADD PARENTS 
        elif action == 'add_parents': 
            # curl --data "{\"action\":\"add_parents\",\"data\":{\"accesskey\":\"Cq9aT6Yd8qokWi6wDvw0frstFNukaBe65YeW3jxBH4itYwvFiM\", "myparent":"parant@mail.com"}}" --header   "Content-Type: application/json" http://localhost:8009 
            userid, mess = check_user_access.check_assecckey(ac) 
            rs = 'error' 
            if int(userid) != 0: 
                # Access key is - ok 
                parent_mail = message.get('data').get('myparent', 'None') # get parent e-mail 
                puserid, mess = check_user_access.add_parent(userid, parent_mail) 
                if (int(puserid) != 0): 
                    rs = 'done' 
 
            #log_add('LOG. Add parents request. add_parents: '+ rs +'. From user ' + str(userid) + ' parent id: ' + parent_mail + ' / ' + str(puserid) + '. Result: ' + str(mess))   
             
############################################################## 
        # ACTION GET KIDS 
        elif action == 'getkids': 
            # curl --data "{\"action\":\"getkids\",\"data\":{\"accesskey\":\"AQCGsGFjDb2upBntANQlgbNs8Wwjj2iT9M1qk5BaUT51gRpb7y\"}}" --header   "Content-Type: application/json" http://localhost:8099 
            userid, mess = check_user_access.check_assecckey(ac) 
            rs = 'error' 
            if int(userid) != 0: 
                # Access key is - ok 
                
                mykids, mess = check_user_access.get_kids(userid) 
                if (len(mykids) > 1): 
                    rs = 'done' 
                    result['data']['mykids'] = mykids 
  
 
############################################################## 
        # ACTION TAKE GPS  
        elif action == 'takegps': 
            # curl --data "{\"action\":\"takegps\",\"data\":{\"accesskey\":\"rMGg4UdMW9prOlyzOpgxj1ljpvTu0G3TVjvkiLvWeXFqD4tsuk\",\"datatime\":\"1586879435\", \"latitude\":\"37.706\",\"longitude\":\"55.811\"}}" --header   "Content-Type: application/json" http://localhost:8099 
            gpsdatatime = message.get('data').get('datatime', 'None') 
            gpslatitude  = message.get('data').get('latitude', 'None') 
            gpslongitude  = message.get('data').get('longitude', 'None') 
            gpsaltitude  = message.get('data').get('altitude', 'None') 
            rs = 'error' 
            if not (re.match(r"[0-9]{2}\.[0-9]*", gpslatitude) and re.match(r"[0-9]{2}\.[0-9]*", gpslongitude) and ((len(gpsaltitude) > 0) and (len(gpsaltitude) < 7)) and gpsdatatime != 'None'): 
                mess = 'Incorrect GPS data.' 
            else: 
                userid, mess = check_user_access.check_assecckey(ac) 
                if int(userid) != 0: 
                    # Access key is - ok 
                    fres, mess = check_user_access.takegps(userid, gpsdatatime, gpslatitude, gpslongitude, gpsaltitude) 
                    if (fres > 0): 
                        rs = 'done' 
                     
############################################################## 
        # ACTION GET GPS  
        elif action == 'getgps': 
            # curl --data "{\"action\":\"getgps\",\"data\":{\"accesskey\":\"C035CughUmZpzxuX7DhLstj54tLgMry9prvfN2u8tOR5N7jXV5\","userid":"123123123"}}" --header   "Content-Type: application/json" http://localhost:8099 
            kuserid = message.get('data').get('userid', 'None') 
            rs = 'error' 
 
            userid, mess = check_user_access.check_assecckey(ac) 
            if int(userid) != 0: 
                # Access key is - ok 
                    
                fres, date, la, lo, alt, mess = check_user_access.getgps(userid, kuserid) 
                result['data']['datakey']  = 'gpslocation'
                result['data']['datatype'] = 'gpslocation'
                if (fres > 0): 
                    rs = 'done'
                    result['data']['datatype'] = 'gpslocation'
                    result['data']['date'] = date 
                    result['data']['latitude'] = la 
                    result['data']['longitude'] = lo 
                    result['data']['altitude'] = alt 
############################################################## 
        # ACTION SET DATA 
        elif action == 'setdata': 
            # curl --data  "{ \"action\": \"setdata\", \"datatype\":\"hwinfo\", \"accesskey\": \"zsrOx7VZTqBknlMVqDhpY29fJ59bRkmL9U5f0GPkS5tiQ2hmE0\",   \"data\": { \"device type\":\"SM-G930F\", \"device brand\":\"samsung\",  \"device display\":\"R16NW.G........\",  \"device manuf.\":\"samsung\",  \"device model\":\"SM-G930F\",  \"device serial\":\"ce011754654544xasd3s\",  \"IMEI 1\":\"2212588446741\"    }}"  --header   "Content-Type: application/json" http://localhost:8099 
            #datatype = message.get('data').get('datatype') #"hwinfo" 
            uid = message.get('userid', '') 
 
            userid, mess = check_user_access.check_assecckey(ac) 
            rs = 'error' 
            if int(userid) != 0:  # Access key is - ok 
                if len(uid) < 4:  #if data set for same user 
                    uid = userid    
                rs, mess = check_user_access.setdata(str(uid), message.get('data').get('datatype',''), message.get('data','')) 
 
############################################################## 
        # ACTION GET DATA  
        elif action == 'getdata': 
            #  
            datatype = message.get('data').get('datatype') #"hwinfo" 
            datakey  = message.get('data').get('datakey')  
            #ac       = message.get('accesskey') 
            kuserid  = message.get('data').get('userid', 'None') 
             
            rs = 'error' 
            userid, mess = check_user_access.check_assecckey(ac) 
            if int(userid) != 0: 
                # Access key is - ok 
                fres, mess, datetime, dataval = check_user_access.getdata(str(userid), kuserid, datatype, datakey) 
                result['data']['datatype'] = datatype 
                result['data']['datakey']  = datakey
                if (fres > 0): 
                    rs = 'done' 
                    #for key, value in data.items(): 
                    #    result['data'][key] = value 
                    
                    result['data'][datakey] = dataval 
                    result['data']['datetime'] = datetime 
                     
############################################################## 
        # ACTION  ELSE 
        else: 
            mess = 'Data JSON unknow action. Text: ' + str(action) 
            rs = 'error' 
         
        # Compile result 
        result['data']['result'] = rs 
        result['data']['message'] = mess 
         
        log_add('LOG. Action: '+action+'. From user ' + str(userid) + '. Result: ' + str(rs) + '. Message: ' + str(mess), 'YES')     
        return result, 'LOG. User action: %s. Result: %s. Message: %s' % (action, rs, mess) 
 
    except KeyError as e: 
        error_str = 'ERROR. Data JSON KeyError. Text:  ' + str(e) 
        #log_add(error_str) 
        return '{"error" : "%s"}' % error_str, error_str 
    # except Exception as e: 
    #     error_str = 'ERROR. Data JSON Exception. Text:  ' + str(e) 
    #     #log_add(error_str) 
    #     return '{"Error_Code" : "%s"}' % error_str, error_str 
 
 
