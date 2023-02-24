unit uLogon;

interface
uses
  System.Net.URLClient,  System.NetEncoding,   System.Classes, System.Types,
  System.Notification, System.DateUtils,
  REST.Types, REST.Client, Data.Bind.ObjectScope, REST.Response.Adapter,
  FireDAC.Comp.Client,
  uTransport;



  type
    TLogon = class(TObject)

      NotificationCenter1: TNotificationCenter;
      //Transport:  TTransport;
      AccessKey: String;
      LastError: String;
      ServiceLog:  TStringList;
      WKMServerAvaible: boolean;

      constructor Create;
      destructor Destroy; override;

      procedure doRegister;
      procedure doLogon;
      procedure doLogout(uAccessKey: string);
      procedure addParent(email: string);
      procedure getKids();
      procedure takeGPS();
      function getGPS(userid:string):string;

      function getConfigParam(param_name: string):String;
      function setConfigParam(param_name, param_value: string; param_type: string = 'str'):boolean;
      function getLastLocations():TStringDynArray;

      procedure sendData(datatype: string; data : TStringList);
      function getData(datatype: string; userid:string; datakey:string):string;
      function isValid_AccessKey(AKey: String): boolean;

      //Dev Zone
     { function GetFacebookLogon(FURL : string): string;
      function GetFacebookToken(FURL : string): string;
      function GetGoogleLogon(URL:string): string;    }

  public

  private
    FDConnection: TFDConnection;
    FDQuery: TFDQuery;

    procedure FDConnectionBeforeConnect(Sender: TObject);
    procedure FDConnectionAfterConnect;
  end;

implementation
uses
  REST.Json, REST.Utils, StrUtils, System.SysUtils,System.ioutils,
  System.JSON, System.JSON.Readers, System.JSON.Types,
  System.JSON.Writers, System.JSON.Builders  ;
var
  ResultLogon: String;

  // DEBUG
  DEBUG : boolean = true;
////////////////////////////////////////////////////////////////////////////////

constructor TLogon.Create;
begin
  inherited; {¬ начале надо вызвать конструктор класса-родител€}

  ServiceLog := TStringList.Create; {создаем структуры нашего класса}

  //Transport := TTransport.Create;

  FDConnection := TFDConnection.Create(Nil);
  FDConnection.LoginPrompt := False;
  FDConnection.Params.Values['DriverID'] := 'SQLite';
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}
     FDConnection.Params.Values['Database'] := TPath.GetDocumentsPath + PathDelim + 'wmk.s3db';
  {$ELSE}
     FDConnection.Params.Values['Database'] := 'C:\Projects\WhereIsMyKid\Frontend\wmk.s3db';
  {$ENDIF}
  //FDConnection.BeforeConnect := FDConnectionBeforeConnect(self);
  FDConnectionAfterConnect;


  FDQuery := TFDQuery.Create(Nil);
  FDQuery.Connection := FDConnection;
  FDQuery.FetchOptions.RowsetSize := 2000;

end;

destructor TLogon.Destroy;
begin
  FreeAndNil(ServiceLog); {–азрушаем структуры нашего класса}
  FreeAndNil(FDQuery);
  FreeAndNil(FDConnection);
  inherited; {в последнюю очередь вызываем деструктор клсса-родител€}
end;

procedure TLogon.FDConnectionBeforeConnect(Sender: TObject);
begin
  //
end;

procedure TLogon.FDConnectionAfterConnect;
begin

  FDConnection.ExecSQL('CREATE TABLE IF NOT EXISTS config( ' +
    '	id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '	param_name VARCHAR(20), 	param_value VARCHAR(200), param_type VARCHAR(10)   );');

  FDConnection.ExecSQL('CREATE TABLE IF NOT EXISTS locations( ' +
    '	recid INTEGER PRIMARY KEY AUTOINCREMENT,' + ' userid INTEGER NOT NULL,' +
    ' timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
    '	locationX VARCHAR(10), 	locationY VARCHAR(10), altitude VARCHAR(10)  );');

  //FDConnection.ExecSQL('alter table locations add column altitude varchar(10); ');

  // if it uncommect - application - freez on start
  //  FDConnection.ExecSQL('CREATE UNIQUE INDEX IF NOT EXIST idx_config_pname  ON config (param_name);');
end;

////////////////////////////////////////////////////////////////////////////////
function TLogon.setConfigParam(param_name, param_value: string; param_type: string = 'str'):boolean;
var
  oldval : string;
begin
      //Check if param exist
     oldval := getConfigParam(param_name);
      if (oldval = param_value) then
        exit;


   try
      {
      To execute a query, which does not return a result set, use the ExecSQL methods.
        If a query returns a result set, then exception "[FireDAC][Phys][MSAcc]-310.
        Cannot execute command returning result sets" will be raised.

      To execute a query, returning a result set and open this result set, use the Open methods.
        If a query returns no result sets, then exception "[FireDAC][Phys][MSAcc]-308.
        Cannot open / define command, which does not return result sets" will be raised.

       ≈сли не активировать FDQuery.Activate - то не происходит вставок и ошибок.
      }
     try

          with FDQuery do begin
            SQL.Clear;
            SQL.Add('INSERT INTO config (param_name, param_value, param_type) VALUES(:A,:B,:C);');
            ParamByName('A').AsString := param_name;
            ParamByName('B').AsString := param_value;
            ParamByName('C').AsString := param_type;
          end;
          FDQuery.ExecSQL;    // if only INSERT use
          result := true;

     except
      on e: Exception do
        begin
          result := false;

          if DEBUG then
          begin
           ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: setConfigParam. DB: ' + e.Message);
           // TDialogService.ShowMessage('E.setConfigParam.T007  DB Error:' + e.Message);
          end;

        end;
      end;
  finally
    //SendNotification('T008 Thread DB  DB Insert', 'Rec. insert into DB' );
    FDQuery.Active := false;
    FDConnection.Connected := false;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
function TLogon.getConfigParam(param_name: string):String;
var
 I : byte;
begin
   try
     try

          with FDQuery do begin
            SQL.Clear;
            SQL.Add('SELECT param_value FROM config '+
                      ' WHERE (param_name = :A ) '+
                      ' and id = (select MAX(id) from config WHERE param_name = :A)  ;');
            ParamByName('A').AsString := param_name;
            Open;   // use when return not null value
            if RecordCount > 0 then
              //for I := 1 to RecordCount do
                begin
                  result := FieldByName('param_value').asString;
                  Next;
                end
            else
              result := '';

            if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: getConfigParam. Info: '+ param_name +' = ' + result);
          end;
     except
      on e: Exception do
        begin
          if DEBUG then
          begin
           ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: getConfigParam. DB: ' + e.Message);
          end;
          result := '';
        end;
      end;
   finally
      FDQuery.Close;
      FDQuery.Active := false;
      FDConnection.Connected := false;
   end;
end;

////////////////////////////////////////////////////////////////////////////////
function TLogon.getLastLocations():TStringDynArray;
var
 I : byte;
begin
   try
     try

          with FDQuery do begin
            SQL.Clear;
            SQL.Add('select strftime(''%s'',timestamp) as timestamp,locationx, locationy, altitude   from locations WHERE recid = (select MAX(recid) from locations);');
            Open;   // use when return not null value
            SetLength(result, 4);
            if RecordCount > 0 then
              for I := 1 to RecordCount do
                begin
                  result[0] := FieldByName('timestamp').AsString;
                  result[1] := FieldByName('locationx').AsString;
                  result[2] := FieldByName('locationy').AsString;
                  result[3] := FieldByName('altitude').AsString;
                  Next;
                end
            else
              result[0] := 'none';

            if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                  ' Func: getLastLocations. result: '+' = ' + result[0]);
          end;
     except
      on e: Exception do
        begin
          if DEBUG then
          begin
          ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                      ' Func: getLastLocations. DB: ' + e.Message);
           //TDialogService.ShowMessage('E.getLastLocations.  DB Error: '+ e.Message);
          end;
          result[0] := 'none';
        end;
      end;
   finally
      FDQuery.Close;
      FDQuery.Active := false;
      FDConnection.Connected := false;
   end;
end;


function TLogon.isValid_AccessKey(AKey: String): boolean;
var
  JSONQ, RequestResult : string;
  Params  : TStringList;
begin

  JSONQ := '{"action":"validAccessKey", "data":{"accesskey":'+
        '"'+ AKey +'"'+
        '}}';

  Params  :=  TStringList.Create;
  ////WKMServerAvaible := Transport.sendJSONtoSrv(JSONQ, Params);

  // {"action": "validAccessKey", "data": {"result": "done", "message": "Access key is valid"}}
  // {"action": "validAccessKey", "data": {"result": "error", "message": "Access key not exist"}}

   if DEBUG then
    begin
     ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: isValid_AccessKey. Data from srv:');
     ServiceLog.Insert(0, Params.Text);
    end;


   try
    if Params.Values['data.result'] = 'done' then
      result := true
    else
      result := false;

    LastError := Params.Values['data.message'];

    if Params.Values['ERROR'] = 'ERROR' then
      begin
        result := false;
        LastError := Params.Values['ERROR_MSG'];
        ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                            ' Func: isValid_AccessKey. Some bug: ' +
                             Params.Values['ERROR_MSG']);
      end;

   except on e:Exception do
      begin
        if DEBUG then
         ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: isValid_AccessKey. Some bug:' + e.Message);
       LastError := e.Message;
       result := false;
      end;
   end;

   FreeAndNil(Params);

end;


////////////////////////////////////////////////////////////////////////////////
// M A I N    F U N C
////////////////////////////////////////////////////////////////////////////////
procedure TLogon.doLogon;
var
    Params  : TStringList;
    RequestResult,JSON : String;

begin

  AccessKey := getConfigParam('accesskey');
  if isValid_AccessKey(AccessKey) then
   begin
     ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: doLogon: Access key is valid.');
     exit;
    end
  else
   begin
     AccessKey := 'none';
     ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+ ' Func: doLogon: Access key is NOT valid.');
   end;

  if WKMServerAvaible = False then
  begin
   ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: doLogon: WMKServer NOT avaible.');
   ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Error: '+ LastError);
   //TDialogService.ShowMessage('Logon error. WMKServer NOT avaible: ' + LastError);
   exit;
  end;

  {JSON := Transport.Str2JSON('action  logon  data'+
                    '  username  '+getConfigParam('username')+
                    '  email  '+getConfigParam('usermail')+
                    '  pass  '+getConfigParam('pass'),
                    '  ');

    }
  Params := TStringList.Create;
 // //WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params);


   try
      if Params.Values['ERROR'] = 'ERROR' then
      begin
         LastError := Params.Values['ERROR_MSG'];
         //TDialogService.ShowMessage('Logon error: ' +  Params.Values['ERROR_MSG']);
        if DEBUG then
          begin
           ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doLogon. Get error from srv:' + Params.Values['ERROR_MSG']);
            //FormMain.MemoServiceLog.Lines.Insert(0, '# '+DateTimeToStr(Now)+' Func: isValid_AccessKey. SRV: ' + Params.Values['ERROR_MSG']);
          end;
      end;

      if (Params.Values['data.result'] = 'done')  and  ( (Params.Values['data.accesskey'].Length) > 10 )then
        begin
          LastError := '';
          AccessKey := Params.Values['data.accesskey'];  // ADD ACCESS KEY
          setConfigParam('accesskey', AccessKey);
          setConfigParam('userid', Params.Values['data.userid']);

          if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doLogon. Is SECUSSFULL');
            end;

        end
      else
        begin
          //TDialogService.ShowMessage('Logon error: ' + Params.Values['data.message']);
          ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+'Logon error: ' + Params.Values['data.message']);
          LastError :=   Params.Values['data.message'];
        end;



   except on e:Exception do
      begin
       AccessKey := 'none';
       LastError := e.Message;
       //TDialogService.ShowMessage('Logon Error: No AccessKey');
       //TDialogService.ShowMessage('Logon Er.:' + e.Message);
      end;
   end;

   FreeAndNil(Params);
end;


////////////////////////////////////////////////////////////////////////////////
procedure TLogon.doRegister;
var
    Params  : TStringList;
    RequestResult, JSON: String;

begin
  {JSON := Transport.Str2JSON('action  register  data'+
                    '  username  '+getConfigParam('username')+
                    '  email  '+getConfigParam('usermail')+
                    '  pass  '+getConfigParam('pass')+
                    '  myparent  '+getConfigParam('myparent'),
                    '  '); }


  Params := TStringList.Create;
  ////WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params);


  if WKMServerAvaible = False then
    begin
      AccessKey := 'none';
      ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: doLogout: SRV not Avaible');
      //TDialogService.ShowMessage('Sorry bro, server is not avaible now :( '+#13+'We work on that!');
      exit;
    end;


   try
      if Params.Values['ERROR'] = 'ERROR' then
        begin
          //TDialogService.ShowMessage('Register error: ' +  Params.Values['ERROR_MSG']);
          if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doRegister. Get error from server:' + Params.Values['ERROR_MSG']);
              //FormMain.MemoServiceLog.Lines.Insert(0, '# '+DateTimeToStr(Now)+' Func: isValid_AccessKey. SRV: ' + Params.Values['ERROR_MSG']);
            end;
          end;


      if (Params.Values['data.result'] = 'done')  and  ( (Params.Values['data.message'].Length) > 10 )then
        begin
          if pos('error', Params.Values['data.message']) > 0 then
             ServiceLog.Insert(0, Params.Values['data.message']);

          LastError := '';
          if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doRegister. Is Secussfull');
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doRegister. Get params: ');
             ServiceLog.Insert(0, Params.Text);
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Access key from DB: ' + getConfigParam('accesskey'));
            end;

        end
       else
        begin
          LastError :=   Params.Values['data.message'];
           //TDialogService.ShowMessage('Register error: ' + Params.Values['data.message']);
           ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Register error: ' + Params.Values['data.message']);

        end;



   except on e:Exception do
      begin
        if DEBUG then
          ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doRegister. Error: '  + e.Message);
      // TDialogService.ShowMessage('doRegister Er.:' + e.Message);
      end;
   end;
     FreeAndNil(Params);
end;


////////////////////////////////////////////////////////////////////////////////
procedure TLogon.doLogout(uAccessKey: string);
var
    Params  : TStringList;
    RequestResult, JSON : String;

begin

  ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: doLogout.');

  {JSON := Transport.Str2JSON('action  logout  '+
                              'accesskey  '+uAccessKey, '  ');
   }
  Params := TStringList.Create;
  //////WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params);

  if WKMServerAvaible = False then
  begin
    AccessKey := 'none';
   ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: doLogout: SRV not Avaible');
    //TDialogService.ShowMessage('Sorry bro, server is not avaible now :( '+#13+'We work on that!');
    exit;
  end;



   try
      if Params.Values['ERROR'] = 'ERROR' then
      begin
        LastError := Params.Values['ERROR_MSG'];
         // TDialogService.ShowMessage('Logout error: ' +  Params.Values['ERROR_MSG']);
        if DEBUG then
          begin
           ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doLogout. Get error from srv:' +
                                       Params.Values['ERROR_MSG']);
            {FormMain.MemoServiceLog.Lines.Insert(0, '# '+DateTimeToStr(Now)+
                                                    ' Func: isValid_AccessKey. SRV: ' +
                                                    Params.Values['ERROR_MSG']);}
          end;
      end;

      if (Params.Values['data.result'] = 'done')then
        begin
          setConfigParam('accesskey', 'none');
          AccessKey := 'none';
          LastError := '';
          if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doLogout. Is SECUSSFULL');
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doLogout. Get params: ');
             ServiceLog.Insert(0,Params.Text);
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doLogout. Access key from DB: ' +
                                           getConfigParam('accesskey'));
            end;

        end
        else
          begin
            LastError := Params.Values['data.message'];
            //TDialogService.ShowMessage('Logout error: ' + Params.Values['data.message']);
            ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+'Logout error: ' + Params.Values['data.message']);
          end;



   except on e:Exception do
      begin
       AccessKey := 'none';
       //TDialogService.ShowMessage('Logout Error: No AccessKey');
       LastError := e.Message;
       if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: doLogout. Except: '+ e.Message);
            end;
      end;
   end;

   FreeAndNil(Params);
end;


////////////////////////////////////////////////////////////////////////////////
procedure TLogon.addParent(email: string);
var
    Params  : TStringList;
    RequestResult, JSON : String;

begin
  ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: addParent.');
  AccessKey := getConfigParam('accesskey');
  {JSON := Transport.Str2JSON('action  add_parents  '+
                              'accesskey  '+AccessKey +
                              '  data  myparent  '+ email, '  ');
  }
  Params := TStringList.Create;
  //WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params);


  if WKMServerAvaible = False then
  begin
    AccessKey := 'none';
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: addParent: SRV not Avaible');
    //TDialogService.ShowMessage('Sorry bro, server is not avaible now :( '+#13+'We work on that!');
    exit;
  end;


   try
      if Params.Values['ERROR'] = 'ERROR' then
      begin
         LastError := Params.Values['ERROR_MSG'];
         // TDialogService.ShowMessage('addParent error: ' +  Params.Values['ERROR_MSG']);
        if DEBUG then
          begin
           ServiceLog.Insert(0, '# ' + DateTimeToStr(Now)+
              ' Func: addParent. Get error from srv:' +
              Params.Values['ERROR_MSG']);
            //FormMain.MemoServiceLog.Lines.Insert(0, '# '+DateTimeToStr(Now)+' Func: isValid_AccessKey. SRV: ' + Params.Values['ERROR_MSG']);
          end;
      end;

      if (Params.Values['data.result'] = 'done')then
        begin
          setConfigParam('myparent', email);
           LastError := '';
          // for gui
          //TDialogService.ShowMessage('Added parent successfully: ' + Params.Values['data.message']);
          if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: addParent. Is successfully');
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: addParent. Get params: ');
             ServiceLog.Insert(0,Params.Text);
            end;

        end
      else
        begin
             LastError := Params.Values['data.message'];
            ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Added parent error: ' + Params.Values['data.message']);
        end;

   except on e:Exception do
      begin
        LastError :=  e.Message;
       if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: addParent. Except: '+ e.Message);
            end;
      end;
   end;

   FreeAndNil(Params);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TLogon.getKids();
var
    Params  : TStringList;
    RequestResult, KidsList,
    JSON : String;
begin
  if DEBUG then
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: getKids.');
     AccessKey := getConfigParam('accesskey');

    //JSON := Transport.Str2JSON('action  getkids  '+
     //                           'accesskey  ' +AccessKey, '  ');
  Params := TStringList.Create;
  if Length(JSON) > 20 then
    //WKMServerAvaible := Transport.sendJSONtoSrv(JSON,Params)
  else
    exit;

  if WKMServerAvaible = False then
  begin
    AccessKey := 'none';
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: getKids: SRV not Avaible');
    //for gui
    //TDialogService.ShowMessage('Sorry bro, server is not avaible now :( '+#13+'We work on that!');
       ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+'Sorry bro, server is not avaible now');
    exit;
  end;

   try
      if (Params.Values['data.result'] = 'done')then
        begin
          LastError := '';
          KidsList :=  Params.Values['data.mykids'];
          setConfigParam('mykids', KidsList);
          //TDialogService.ShowMessage('Added parent successfully: ' + Params.Values['data.message']);
          if DEBUG then
            begin
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: getKids. Is successfully');
            end;

        end
      else
        begin
            LastError :=  Params.Values['data.message'];
            setConfigParam('mykids', '');
            ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+ 'Get kids error: ' + Params.Values['data.message']);
        end;



   except on e:Exception do
     begin
       LastError := e.Message;
       if DEBUG then
        begin
         ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+' Func: getKids. Except: '+ e.Message);
        end;
     end;
   end;
   FreeAndNil(Params);
end;




procedure TLogon.takeGPS();
var
  JSON, RequestResult : string;
  Params : TStringList;
  LastGPS : TStringDynArray;
begin
  AccessKey := getConfigParam('accesskey');
  LastGPS :=  getLastLocations();
  if LastGPS[0] = 'none' then
    begin
      if DEBUG then
       ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: takeGPS: no GPS fount in DB.');
      exit
    end;


  {JSON := Transport.Str2JSON('action  takegps  accesskey  '+AccessKey+
                    '  data'+
                    '  datatime  '  + LastGPS[0]+
                    '  latitude  '  + LastGPS[1]+
                    '  longitude  ' + LastGPS[2]+
                    '  altitude  '  + LastGPS[3],
                    '  ');
    }
  Params := TStringList.Create;
  if Length(JSON) > 20 then
    //WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params)
  else
    exit;

  if WKMServerAvaible = False then
  begin
    if DEBUG then
      ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: takeGPS: SRV not Avaible');
    exit;
  end;

   try
      if (Params.Values['data.result'] = 'done')then
        begin
          LastError := '';
          //TDialogService.ShowMessage('Added parent successfully: ' + Params.Values['data.message']);
          if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                        ' Func: takeGPS. Is successfully');
        end
      else
        begin
           LastError := Params.Values['data.message'];
           ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+ 'Get send gps error: ' + Params.Values['data.message']);
        end;



   except on e:Exception do
      begin
       LastError := e.Message;
       if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                  ' Func: takeGPS. Except: '+ e.Message);

      end;
   end;

   FreeAndNil(Params);

end;




function TLogon.getGPS(userid:string):string;
var
  JSON, RequestResult : string;
  Params : TStringList;
  LastGPS : TStringDynArray;
begin
  result := '';
  AccessKey := getConfigParam('accesskey');
  {JSON := Transport.Str2JSON('action  getgps  accesskey  '+AccessKey+
                             '  userid  '+userid,
                             '  ');
   }
  Params := TStringList.Create;
  if Length(JSON) > 20 then
    //WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params)
  else
    exit;

  if WKMServerAvaible = False then
  begin
    if DEBUG then
      ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: getGPS: SRV not Avaible');
    exit;
  end;

   try
      if (Params.Values['data.result'] = 'done') then
        begin
          LastError := '';
          result :=  Params.Values['data.latitude'] + ' ' +
                     Params.Values['data.longitude']+ ' ' +
                     Params.Values['data.altitude'] + ' ' +
                     Params.Values['data.date'];
        end
      else
          LastError := Params.Values['data.message'];

      if DEBUG then
          ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                        ' Func: getGPS. Result: ' + Params.Values['data.message']);



   except on e:Exception do
      begin
       LastError := e.Message;
       if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                  ' Func: getGPS. Except: '+ e.Message);

      end;
   end;

   FreeAndNil(Params);

end;


procedure TLogon.sendData(datatype: string; data : TStringList);
var
  JSON, RequestResult, Jsondata : string;
  Params : TStringList;
  i : byte;
begin
  AccessKey := getConfigParam('accesskey');
  Jsondata := '';

  for i := 0 to data.Count - 1  do
    Jsondata := Jsondata + '  ' + data.Names[i] + '  ' +  data.ValueFromIndex[i];

  {JSON := Transport.Str2JSON('action  setdata'+
                                     '  datatype  '  + datatype  +
                                     '  accesskey  ' + AccessKey +
                                     '  data' + Jsondata   ,
                                      '  ');
   }
  Params := TStringList.Create;
  if Length(JSON) > 20 then
    //WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params)
  else
    exit;

  if WKMServerAvaible = False then
  begin
    if DEBUG then
      ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: takeGPS: SRV not Avaible');
    exit;
  end;

   try
      if (Params.Values['data.result'] = 'done')then
        begin
          LastError := '';
          //TDialogService.ShowMessage('Added parent successfully: ' + Params.Values['data.message']);
          if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                        ' Func: setdata. Is successfully');
        end
      else
        begin
           LastError := Params.Values['data.message'];
           ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+ 'setdata error: ' + Params.Values['data.message']);
        end;



   except on e:Exception do
      begin
       LastError := e.Message;
       if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                  ' Func: takeGPS. Except: '+ e.Message);

      end;
   end;

   FreeAndNil(Params);

end;



function TLogon.getData(datatype: string; userid:string; datakey:string):string;
var
  JSON, RequestResult : string;
  Params : TStringList;
  LastGPS : TStringDynArray;
begin
  result := '';
  AccessKey := getConfigParam('accesskey');
  {JSON := Transport.Str2JSON('action  getdata'+
                             '  datatype  ' + datatype  +
                             '  datakey  '  + datakey  +
                             '  userid  '   + userid+
                             '  accesskey  '  + AccessKey,
                             '  ');
    }
  Params := TStringList.Create;
  if Length(JSON) > 20 then
    //WKMServerAvaible := Transport.sendJSONtoSrv(JSON, Params)
  else
    exit;

  if WKMServerAvaible = False then
  begin
    if DEBUG then
      ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Func: getdata: SRV not Avaible');
    exit;
  end;

   try
      if (Params.Values['data.result'] = 'done') then
        begin
          LastError := '';
          result :=  Params.Values['data.datetime'] + ' ' +
                     Params.Values['data.'+datakey];
        end
      else
          LastError := Params.Values['data.message'];

      if DEBUG then
          ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                        ' Func: getdata. Result: ' + Params.Values['data.message']);



   except on e:Exception do
      begin
       LastError := e.Message;
       result := '';
       if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                  ' Func: getdata. Except: '+ e.Message);

      end;
   end;

   FreeAndNil(Params);

end;




end.
