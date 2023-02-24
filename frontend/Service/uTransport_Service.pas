unit uTransport_Service;

interface
uses
  System.Net.URLClient,  System.NetEncoding,   System.Classes, System.Types,
  System.Notification, System.DateUtils,
  REST.Types, REST.Client, Data.Bind.ObjectScope, REST.Response.Adapter,
  FireDAC.Comp.Client ,
  System.Sensors.Components, System.Sensors  // GPS

  ;



type
   TWMKLoc = record
    Lat,Lon,Alt  : string;
    date         : string;
   end;

   TKid = record
      name, id   : string;
      idint      : byte;
      location   : TWMKLoc;

   end;

   TTransportData = record
      Action              : string;
      Error               : string;
      AccessKey           : string;
      isRegister          : boolean;
      isLogon             : boolean;
      ServerAvaible       : boolean;
      isThreadRun         : boolean;
      showError           : boolean;
   end;

   TWMKRec = record
      user,mail,passwd    : string;
      parentmail          : string;
      locationMy          : TWMKLoc;
      isKid               : boolean;
      Kids                : array of TKid;
   end;

   TTransportService=class(TThread)
    public
      ServiceLog          : TStringList;
      Request             : TStringList;
      Response            : TStringList;
      Transport           : TTransportData;
      WMKData             : TWMKRec;
      LocationSensor      : TLocationSensor;
      //sAvaible: ^boolean;
      ThreadIsWork        : boolean;
      onSync              : TThreadMethod;

      constructor Create(pAction:string; onTerm : TNotifyEvent);
      destructor  Destroy; override;
      procedure   Execute; override;

    private
      FDConnection: TFDConnection;
      FDQuery: TFDQuery;

      { Main logic }
      function  doCheckAccessKey(AKey: String): boolean;
      procedure doRegister;
      procedure doLogon;
      procedure doLogout;


      procedure getData;
      //procedure getGPS;
      procedure setData;
      procedure setGPS;
      procedure getlocUserData;

      { DB Functions }
      procedure FDConnectionAfterConnect(Sender: TObject);
      function getConfigParam(param_name: string):String;
      function setConfigParam(param_name, param_value: string; param_type: string = 'str'):boolean;
      function getLastLocations:TStringList;

      { Processing logic}
      function    SendRequest(sRequest:string):string;
      procedure   ParseJSON(JSONStr:String; var RespParamList : TStringList);
      function    responseProcessing(RespParamList : TStringList):boolean;
      procedure   startAction(SAction :String; showError: boolean = true);
      function    StartLocationService(SleepTime: Integer;   IterationsCount: Integer = 0  ):Boolean; //MAIN
      procedure   SendNotification( Title, AlertBody: string; UnicName: String = '');
      {Locations logic}
     // procedure LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
      //NewLocation: TLocationCoord2D);
      procedure LocatioSensorChange;
      function BoolToStr(const value: boolean): string;

   end;



implementation
uses
  REST.Json, REST.Utils, StrUtils, System.SysUtils,System.ioutils,
  System.JSON, System.JSON.Readers, System.JSON.Types,
  System.JSON.Writers, System.JSON.Builders,
  uHardwareAndroid, uWMKService ;
var
  HWData              : THWData;

  //
  // DEBUG
  DEBUG : boolean = true;
////////////////////////////////////////////////////////////////////////////////


constructor TTransportService.Create(pAction:string;  onTerm : TNotifyEvent);
begin
  inherited Create(true);
  FreeOnTerminate := true;
  OnTerminate := onTerm;

  Transport.Action := pAction;

  Transport.ServerAvaible := false;
  ServiceLog :=  TStringList.Create;
  Request    :=  TStringList.Create;
  Response   :=  TStringList.Create;
  //LocationSensor := TLocationSensor.Create(nil);
  HWData         := THWData.Create;

  { DB components }
  FDConnection := TFDConnection.Create(Nil);
  FDConnection.LoginPrompt := False;
  FDConnection.Params.Values['DriverID'] := 'SQLite';
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}
     FDConnection.Params.Values['Database'] := TPath.GetDocumentsPath + PathDelim + 'wmk.s3db';
  {$ELSE}
     FDConnection.Params.Values['Database'] := 'C:\Projects\WhereIsMyKid\Frontend\wmk.s3db';
  {$ENDIF}
  //FDConnection.BeforeConnect := FDConnectionBeforeConnect(self);
  //FDConnectionAfterConnect
  FDConnection.AfterConnect := FDConnectionAfterConnect;
  FDQuery := TFDQuery.Create(Nil);
  FDQuery.Connection := FDConnection;
  FDQuery.FetchOptions.RowsetSize := 2000;

end;

destructor TTransportService.Destroy;
begin
  FreeAndNil(ServiceLog);
  FreeAndNil(FDQuery);
  FreeAndNil(FDConnection);
  FreeAndNil(Request);
  FreeAndNil(Response);

  FreeAndNil(HWData);
  //FreeAndNil(LocationSensor);
  inherited; {в последнюю очередь вызываем деструктор клсса-родител€}
end;


procedure TTransportService.Execute;
begin

    //SendNotification('TTransportService','Start Action: ' + Transport.Action);
    StartLocationService(30000,5);
end;


function TTransportService.BoolToStr(const value: boolean): string;
const
  Values: array [boolean] of string = ('False', 'True');
begin
  Result := Values[value];
end;

procedure TTransportService.SendNotification( Title, AlertBody: string; UnicName: String = '');
var
  MyNotification: TNotification;
  NotificationCenter : TNotificationCenter;
  //NowDate : TDateTime;
begin
  sleep(100);
  NotificationCenter := TNotificationCenter.Create(nil);
  MyNotification := NotificationCenter.CreateNotification;
  //NowDate := Now;
  try
    if UnicName = '' then
      MyNotification.Name := 'Notifi at ' + IntToStr(MilliSecondsBetween(Now, 0) + Random(100))
    else
      MyNotification.Name := UnicName;

    MyNotification.Title := Title;
    MyNotification.AlertBody :=  AlertBody;
    // MyNotification.Number := 18;
    // Fired in 1 seconds
    MyNotification.FireDate := Now + EncodeTime(0, 0, 1, 0);
    // Repeated each minute
    // MyNotification.RepeatInterval := TRepeatInterval.Minute;

    // Schedule notification to the notification center
    NotificationCenter.ScheduleNotification(MyNotification);
  finally
    MyNotification.Free;
    NotificationCenter.Free;
  end;
end;


procedure  TTransportService.startAction(SAction :String; showError: boolean = true);
begin
  //TransportT     := TTransport.Create('');

  Transport.isThreadRun := true;
  Transport.Action := SAction;
  Transport.showError := showError;

  ServiceLog.Add('Starting thread: ' +  SAction);

   // action
   if Transport.Action = 'register' then doRegister else
   if Transport.Action = 'logon'    then doLogon    else
   if Transport.Action = 'logout'   then doLogout   else
   //if Transport.Action = 'getkids'  then getKids    else
   if Transport.Action = 'setgps'   then setGPS     else
   //if Transport.Action = 'getgps'   then getGPS     else
   if Transport.Action = 'getdata'  then getData    else
   if Transport.Action = 'setdata'  then setData    else
   if Transport.Action = 'getlocUserData'  then getlocUserData       ;


end;


procedure TTransportService.FDConnectionAfterConnect(Sender: TObject);
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
function TTransportService.setConfigParam(param_name, param_value: string; param_type: string = 'str'):boolean;
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
function TTransportService.getConfigParam(param_name: string):String;
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


function TTransportService.getLastLocations():TStringList;
var
 i : byte;
begin
   try
     try

          with FDQuery do begin
            SQL.Clear;
            SQL.Add('select strftime(''%s'',timestamp) as timestamp,locationx, locationy, altitude   from locations '+
                          ' WHERE recid = (select MAX(recid) from locations);');
            Open;   // use when return not null value
            if RecordCount > 0 then
              for i := 1 to RecordCount do
                begin
                  result.Values['datatime']   := FieldByName('timestamp').AsString;
                  result.Values['latitude']   := FieldByName('locationx').AsString;
                  result.Values['longitude']  := FieldByName('locationy').AsString;
                  result.Values['altitude']   := FieldByName('altitude').AsString;
                  Next;
                end;

            if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                  ' Func: getLastLocations. result.count = ' + inttostr(result.Count));
          end;
     except
      on e: Exception do
        begin
          if DEBUG then
                 ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+
                      ' Func: getLastLocations. DB: ' + e.Message);
          result.Clear;
        end;
      end;
   finally
      FDQuery.Close;
      FDQuery.Active := false;
      FDConnection.Connected := false;
   end;
end;


procedure TTransportService.ParseJSON(JSONStr:String; var RespParamList : TStringList);
var
   Sr     : TStringReader;
   Reader : TJsonTextReader;
   JSON : string;
begin
  {
      Pars  JSONText and return   ParamList as ParamList['Named_Id'] = 'valuse'
  }
   JSON := JSONStr.Replace('\','');
   JSON := JSON.Replace('"{','{');
   JSON := JSON.Replace('}"','}');


   RespParamList.clear;
   Sr := TStringReader.Create(JSON);
   Reader := TJsonTextReader.Create(Sr);
  try
    try
     while Reader.read do
       case Reader.TokenType of
          //TJsonToken.startobject:
           //MemoServiceLog.Lines.Insert(0, '(StartObject) ' + '- Token Path : ' + Reader.Path);
          //TJsonToken.StartArray:
           //MemoServiceLog.Lines.Insert(0, '(StartArray) ' + '- Token Path : ' + Reader.Path );
          //TJsonToken.PropertyName:
           //MemoServiceLog.Lines.Insert(0, 'PropertyName : ' + Reader.Value.ToString + '- Token Path : ' + Reader.Path );
          TJsonToken.String:
            RespParamList.AddPair(Reader.Path, Reader.Value.ToString);
           //MemoServiceLog.Lines.Insert(0, 'String Value : ' + Reader.Value.ToString + '- Token Path : ' + Reader.Path);
          TJsonToken.Integer:
            RespParamList.AddPair(Reader.Path, Reader.Value.ToString);
           //MemoServiceLog.Lines.Insert(0, 'Integer Value : ' + Reader.Value.ToString + '- Token Path : ' + Reader.Path);
          TJsonToken.Float:
            RespParamList.AddPair(Reader.Path, Reader.Value.ToString);
           //MemoServiceLog.Lines.Insert(0, 'Float Value : ' + Reader.Value.ToString + '- Token Path : ' + Reader.Path);
          TJsonToken.Boolean:
            RespParamList.AddPair(Reader.Path, Reader.Value.ToString);
           //MemoServiceLog.Lines.Insert(0, 'Boolean Value : ' + Reader.Value.ToString + '- Token Path : ' + Reader.Path);
          TJsonToken.Null:
            RespParamList.AddPair(Reader.Path, Reader.Value.ToString);
           //MemoServiceLog.Lines.Insert(0, 'Null Value : ' + Reader.Value.ToString + '- Token Path : ' + Reader.Path);
          //TJsonToken.EndArray:
           //MemoServiceLog.Lines.Insert(0, '(EndArray) ' + '- Token Path : ' + Reader.Path);
          //TJsonToken.EndObject:
           //MemoServiceLog.Lines.Insert(0, '(EndObject) ' + '- Token Path : ' + Reader.Path);}
       end;
    except on e:Exception do
       begin
         RespParamList.Clear;
         RespParamList.AddPair('error', 'internal error');
         RespParamList.AddPair('data.result', 'error');
         RespParamList.AddPair('data.message', 'JSON parsing Exception: ' + e.Message);
       end;
    end;

  finally
    FreeAndNil(Reader);
    FreeAndNil(Sr);
  end;
end;




function TTransportService.SendRequest(sRequest:string):string;
var
  //g:TGUID;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
begin
  //CreateGuid(g);
  // g.ToString;
  try
      try
        RESTClient1 := TRESTClient.Create('http://185.58.193.5:8099/');
        RESTRequest1 := TRESTRequest.Create(RESTClient1);
        RESTResponse1 := TRESTResponse.Create(RESTRequest1);
        RESTRequest1.Response := RESTResponse1;

        //RESTClient1.ResetToDefaults;
        //RESTRequest1.ResetToDefaults;
        //RESTResponse1.ResetToDefaults;

        RESTClient1.Accept:='*/*';
        RESTClient1.AcceptCharset:='UTF-8, *;q=0.8';
        RESTClient1.UserAgent:='agent';
        RESTClient1.BaseURL := 'http://185.58.193.5:8099/';
        RESTClient1.ContentType := 'application/json';

        RESTRequest1.Accept:='*/*';
        RESTRequest1.AcceptCharset:='UTF-8, *;q=0.8';
        RESTRequest1.Resource:='';
        RESTRequest1.Timeout:=10000;
        RESTRequest1.Method := rmPOST;
        RESTRequest1.Params.AddHeader('Connection', 'Close');
        //RESTRequest1.Params.AddHeader('Content-Type','application/json');
        RESTRequest1.AddBody(sRequest, ctAPPLICATION_JSON);

        RESTRequest1.Execute;

        result := RESTResponse1.Content;   // RESPONSE CONTENT
        //  MemoServiceLog.Lines.Insert(0, RESTResponse1.JSONValue.ToString);

         // set server avaible var to true
        //sAvaible^ := true;
        Transport.ServerAvaible := true;


      except on e:Exception do
        begin
         result := '{"error":"Exception error","data":{"result":"error ", "message": "internal exception: '+e.Message+'"}}';
         //sAvaible^ := false;
         Transport.ServerAvaible := false;

        end;
      end;
  finally
    FreeAndNil(RESTResponse1);
    FreeAndNil(RESTRequest1);
    FreeAndNil(RESTClient1);
   end;
end;


{
procedure TTransportService.RESTRequest1HTTPProtocolError(Sender: TCustomRESTRequest);
begin
   ServiceLog.Insert(0,'-------');
   ServiceLog.Insert(0,'# RESTRequest1HTTPProtocolError');
   ServiceLog.Insert(0,Sender.Response.StatusText);
   ServiceLog.Insert(0,Sender.Response.Content);
end;
}


procedure TTransportService.getlocUserData;
begin
   WMKData.user       := getConfigParam('username');
   WMKData.mail       := getConfigParam('usermail');
   WMKData.passwd     := getConfigParam('pass');
   WMKData.parentmail := getConfigParam('myparent');
   //Transport.AccessKey := getConfigParam('myparent');
end;



function TTransportService.responseProcessing(RespParamList : TStringList):boolean;
var
  pAction  : string;
begin
  pAction := RespParamList.Values['action'];
  //SendNotification('#512. uTransport','responseProcessing: ' + pAction);
  if Transport.ServerAvaible = False then
  begin
    if DEBUG then
      ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' WMKSrv not avaible. ' + RespParamList.Values['data.message']);
    Transport.Error := RespParamList.Values['data.message'];
    result := false;
    exit;
  end;

   try
      if (RespParamList.Values['data.result'] = 'done')then
        begin
          Transport.Error := '';
          result := false;
        {-----------  ACTIONS -----------}
          if  pAction =  'validAccessKey' then
            begin
              result := true;
              Transport.isLogon := true;
            end else

          if  pAction =  'register' then
              begin
                // set config to db
                setConfigParam('username', WMKData.user );
                setConfigParam('usermail', WMKData.passwd);
                setConfigParam('pass', WMKData.passwd);
                setConfigParam('myparent', WMKData.parentmail);
                result := true;
              end else

          if  pAction =  'logon' then
              begin
               Transport.AccessKey :=  RespParamList.Values['data.accesskey']; // ADD ACCESS KEY
               setConfigParam('accesskey', RespParamList.Values['data.accesskey']);
               setConfigParam('userid', RespParamList.Values['data.userid']);
               result := true;
              end  else

          if  pAction =  'getkids' then
              begin
                 setConfigParam('mykids', RespParamList.Values['data.mykids']);
                 Response.Assign(RespParamList);
                 result := true;
              end else

          if  pAction =  'setgps' then
              begin
                 result := true;
              end else
          if  pAction =  'getgps' then
              begin
                 Response.Assign(RespParamList);
                 result := true;
              end else
          if  pAction =  'logout' then
              begin
                 result := true;
                 setConfigParam('accesskey', '');
                 Transport.AccessKey := '';
              end else

          if  pAction =  'getdata' then
              begin
                 result := true;
                 Response.Assign(RespParamList);
              end else

          if  pAction =  'setdata' then
              begin
                 result := true;
              end;
        {-----------  END -----------}
        end
       else   // 'data.result' = error
        begin
          Transport.Error := RespParamList.Values['data.message'];
          Response.Assign(RespParamList);
          result := false;
          if DEBUG then
               ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+ ' Get error: ' + RespParamList.Values['data.message']);

        end;

   except on e:Exception do
      begin
       Transport.Error := e.Message;
       result := false;
       if DEBUG then
             ServiceLog.Insert(0, '# '+DateTimeToStr(Now)+  ' Get exception: '+ e.Message);
      end;
   end;

   Transport.isThreadRun := false;
end;




////////////////////////////////////////////////////////////////////////////////
// M A I N    F U N C
////////////////////////////////////////////////////////////////////////////////

procedure TTransportService.doRegister;
var
    RespParamList  : TStringList;
    JSON: String;

begin
  if DEBUG then
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Starting: doRegister.');
   //  AccessKey := getConfigParam('accesskey');

   JSON := '{"action" : "register",'+
              ' "data":{ '+
                    '"username" :"' + WMKData.user  +'", '+
                    '"email" :"'    + WMKData.mail  +'", '+
                    '"pass" :"'     + WMKData.passwd     +'", '+
                    '"myparent" :"' + WMKData.parentmail  +'"'+
              ' }'+
              '}';

  JSON := SendRequest(JSON);

  RespParamList := TStringList.Create;
  ParseJSON(JSON, RespParamList);
  Transport.isRegister := responseProcessing(RespParamList);

  FreeAndNil(RespParamList);

end;



function TTransportService.doCheckAccessKey(AKey: string):boolean ;
var
  JSON : string;
  RespParamList : TStringList;
begin

  JSON := '{"action":"validAccessKey",'
              +' "accesskey":'
             +'"'+ AKey +'"'+''
             +'}';


  JSON := SendRequest(JSON);

  RespParamList := TStringList.Create;
  ParseJSON(JSON, RespParamList);
  result := responseProcessing(RespParamList);

  // {"action": "validAccessKey", "data": {"result": "done", "message": "Access key is valid"}}
  // {"action": "validAccessKey", "data": {"result": "error", "message": "Access key not exist"}}


   FreeAndNil(RespParamList);

end;

procedure TTransportService.doLogon;
var
    RespParamList  : TStringList;
    JSON : String;

begin
  if DEBUG then
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Starting: getKids.');

  Transport.AccessKey := getConfigParam('accesskey');
  if doCheckAccessKey(Transport.AccessKey) or (Transport.ServerAvaible = false) then
     exit
  else
     Transport.AccessKey := '';

  JSON := '{"action":"logon",'+
              ' "data":{'+
                        '"username":' +'"'+ WMKData.user +'",'+
                        '"email":'    +'"'+ WMKData.mail +'",'+
                        '"pass":'     +'"'+ WMKData.passwd +'"'+
              '}}';

  JSON := SendRequest(JSON);

  RespParamList := TStringList.Create;
  ParseJSON(JSON, RespParamList);
  Transport.isLogon := responseProcessing(RespParamList);

  FreeAndNil(RespParamList);

end;




procedure TTransportService.setGPS;
var
  JSON, RequestResult : string;
  RespParamList : TStringList;
  LastGPS : TStringList;
begin
  if DEBUG then
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Starting: setGPS.');

   LastGPS :=  getLastLocations();
   if LastGPS.Count = 0 then
    begin
      ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Finish: setGPS. No GPS data found');
      exit
    end;

   JSON := '{"action" : "setgps",'+
                        '"accesskey":' +'"'+ Transport.AccessKey +'", '+
              '"data":{ '+
                    '"datatime" :"'+ LastGPS.Values['datatime']   +'", '+
                    '"latitude" :"'+ LastGPS.Values['latitude']   +'", '+
                    '"longitude":"'+ LastGPS.Values['longitude']  +'", '+
                    '"altitude" :"'+ LastGPS.Values['altitude']   +'"'+
              ' }'+
              '}';

  SendNotification('#775 setGPS',JSON);
  JSON := SendRequest(JSON);
  SendNotification('#777 setGPS. Resp',JSON);

  RespParamList := TStringList.Create;
  ParseJSON(JSON, RespParamList);
  responseProcessing(RespParamList);

  FreeAndNil(RespParamList);
end;



procedure TTransportService.doLogout;
var
    RespParamList  : TStringList;
    JSON : String;

begin
  if DEBUG then
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Starting: doLogout.');
   //  AccessKey := getConfigParam('accesskey');
  JSON := '{"action" : "logout", "accesskey" : ' +'"'+ Transport.AccessKey +'"}';
  JSON := SendRequest(JSON);
  RespParamList := TStringList.Create;
  ParseJSON(JSON, RespParamList);
  Transport.isLogon := not responseProcessing(RespParamList);

  FreeAndNil(RespParamList);
end;



procedure TTransportService.getData;
var
  JSON : string;
  RespParamList : TStringList;
begin
  if DEBUG then
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Starting: getData.');

   JSON := '{"action" : "getdata",'+
                        '"accesskey":' +'"'+ Transport.AccessKey +'", '+
              '"data":{ '+
                    '"datatype" :"' + Request.Values['datatype']  +'", '+
                    '"datakey" :"'  + Request.Values['datakey']   +'", '+
                    '"userid":"'    + Request.Values['userid']    +'" '+
              ' }'+
              '}';

  JSON := SendRequest(JSON);

  RespParamList := TStringList.Create;
  ParseJSON(JSON, RespParamList);
  responseProcessing(RespParamList);

  FreeAndNil(RespParamList);
end;




procedure TTransportService.setData;
var
  JSON, Jsondata : string;
  RespParamList : TStringList;
  i : byte;
begin

  if DEBUG then
    ServiceLog.Insert(0, '# '+DateTimeToStr(Now) + ' Starting: setData.');

  Jsondata := '';
  for i := 0 to Request.Count - 1  do
    if Request.Names[i] <> 'datatype' then
      Jsondata := Jsondata + '  ' + Request.Names[i] + '  ' +  Request.ValueFromIndex[i];

   JSON := '{"action" : "setdata",'+
                        '"accesskey":' +'"'+ Transport.AccessKey +'", '+
                        '"datatype":' +'"'+ Request.Values['datatype'] +'", '+
              '"data":{ ' + Jsondata + ' }'+
              '}';
  SendNotification('#857 setData',JSON);
  JSON := SendRequest(JSON);
  SendNotification('#859 setData',JSON);

  RespParamList := TStringList.Create;
  ParseJSON(JSON, RespParamList);
  responseProcessing(RespParamList);

  FreeAndNil(RespParamList);
end;


procedure TTransportService.LocatioSensorChange;
begin
 // DM.LocationSensor1.Active := not DM.LocationSensor1.Active;
end;


function TTransportService.StartLocationService(SleepTime: Integer; IterationsCount: Integer = 0 ):Boolean;
var

  Rst, isFirst                :   boolean;
  ENUSLat, ENUSLong, ENUSAtl  :   String; // holders for URL strings
  gpsCounter,iCounter         :   integer;

  //LocationSensor              :   TLocationSensor;
  //hw                          :   THWData;
  //WMK                         :   TWMKRec;

  // Fs : TMemoryStream;
  //Thread :  TThread;
begin
  Rst := true;
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}

  {$ELSE}
    result := false;
    exit;
  {$ENDIF}

    startAction('getlocUserData');   //Get config data to local Vars
    startAction('logon');


    if not Transport.isLogon then
       begin
        SendNotification('#900. Service thread','Can not read user from the db, please relogin to the application.');
        exit;
       end
     else if DEBUG then
        SendNotification('#904. Service thread. ',' Transport.isLogon. User: ' + WMKData.user + ' is logon: ' + BoolToStr( Transport.isLogon));



          iCounter := 0;
          isFirst  := true;
        while ( iCounter <= IterationsCount ) do
          begin
            if DEBUG then
             SendNotification('#913. Service. ','Iteration: ' + inttostr(iCounter) +
                                ' from ' + inttostr(IterationsCount)  );

             //LocationSensor.Active := true;    // if activate GPS in thread, thread - died / stone
            { Synchronize(nil, procedure
                              begin
                                DM.LocationSensor1.Active := true;
                              end);    }



                       //LocationSensorT :=  TLocationSensor.Create(LocationSensorT);
                        //LocationSensorT.Active := SLActivate;

                       gpsCounter := 0;
                       ENUSLat := 'NAN';
                       while ((ENUSLat='NAN') or (ENUSLat='')) and (gpsCounter <= 5) do
                         begin
                             //if DEBUG then
                              //  SendNotification('#980. Service thread ','GPS Circle: '+ inttostr(gpsCounter) + ' Lat: '+ ENUSLat);
                             sleep(5000);
                             ENUSLat  := 'NAN';
                             ENUSLong := 'NAN';
                             ENUSAtl  := 'NAN';
                             // Fs := TMemoryStream.Create;
                            { Synchronize(nil,
                              procedure
                              begin
                                 ENUSLat  := DM.LocationSensor1.Sensor.Latitude.ToString(ffGeneral, 9, 2, TFormatSettings.Create('en-US')).Replace(',', '.');
                                 ENUSLong := DM.LocationSensor1.Sensor.Longitude.ToString(ffGeneral, 9, 2, TFormatSettings.Create('en-US')).Replace(',', '.');
                                 ENUSAtl  := System.Round(DM.LocationSensor1.Sensor.Altitude).ToString.Replace(',', '.');
                              end
                             );   }

                             inc(gpsCounter);
                          end;

                       if (ENUSLat <> 'NAN') and (ENUSLat <> '') then
                         begin
                              //SendNotification('#995. Service thread ','Put GPS to DB');
                            try
                                Rst := true; // get GPS location
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
                                        SQL.Add('INSERT INTO locations(userid,locationx,locationy, altitude)'+
                                                            ' VALUES(:userid, :locX, :locY, :locAlt);');
                                        ParamByName('userid').AsInteger := 0;  // userid - didt use
                                        ParamByName('locX').AsString := ENUSLat;
                                        ParamByName('locY').AsString := ENUSLong;
                                        ParamByName('locAlt').AsString := ENUSAtl;
                                      end;
                                      FDQuery.ExecSQL;
                                      FDQuery.Close;

                                 except on e: Exception do
                                    begin
                                      SendNotification('#10024. Service thread. DB Error', e.Message);
                                      iCounter := IterationsCount +1 ; // end WHILE
                                      Rst := false;
                                    end;
                                 end;
                            finally
                              begin
                                if DEBUG then
                                  SendNotification('#989. Service thread.', 'GPS rec. insert into DB.' );
                                FDQuery.Active := false;
                                FDConnection.Connected := false;
                              end;
                            end;


                            //logon.takeGPS;
                            startAction('setgps');
                            SendNotification('#1041. Service thread ','setgps');
                            SendNotification('#1041. Service thread ', ServiceLog.Strings[ServiceLog.Count+1]);
                         end
                         else
                          SendNotification('#1005. Service thread ','Cant get GPS');

                       // Send hardwaredata
                       Request.Values['datatype'] :=  'hwinfo';
                       Request.AddStrings(HWData.getBatteryCharge);
                       startAction('setdata');
                       SendNotification('#1011. Service thread ', ServiceLog.Strings[ServiceLog.Count+1]);


                       //logon.sendData('hwinfo', hw.getBatteryCharge);
                       if isFirst then
                       begin
                          Request.Values['datatype'] :=  'hwinfo';
                          Request.AddStrings(HWData.getHardwareData);
                          startAction('setdata');
                          //logon.sendData('hwinfo', hw.getHardwareData);
                       end;
                       isFirst := false;

                       //FreeAndNil(logon);




            //LocationSensor.Active := false;
                          Synchronize(nil, procedure
                              begin
                                DM.LocationSensor1.Active := false;
                              end);

            sleep(SleepTime);  // time for gps can locate position in first start
            inc(iCounter);
            if IterationsCount = 0 then    //forever   work
              iCounter := 0;

           end;
          //Thread.OnTerminate := ThreadTerminated;


  Result := Rst;
end;


(*
procedure TTransportService.LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
  NewLocation: TLocationCoord2D);
begin
    {  SendNotification('SLC01 Locations', BoolToStr(LocationSensor1.Active)+' '+
              LocationSensor1.Sensor.Latitude.ToString(ffGeneral, 5, 2, TFormatSettings.Create('en-US')) + ' ' +
              LocationSensor1.Sensor.Longitude.ToString(ffGeneral, 5, 2, TFormatSettings.Create('en-US')));
     }

end;
  *)




end.


