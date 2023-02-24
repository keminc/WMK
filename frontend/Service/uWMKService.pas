 unit uWMKService;

interface

uses
  System.SysUtils,
  System.Classes,
    System.Android.Service,
    AndroidApi.JNI.GraphicsContentViewText,
    AndroidApi.JNI.Os,
  System.Notification, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  Data.DB, FireDAC.Comp.Client, FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.UI, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, System.Sensors, System.Sensors.Components,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, Data.Bind.EngExt,
  Data.Bind.Components ;

type
  TDM = class(TAndroidService)
    NotificationCenter1: TNotificationCenter;
    FDConnection1: TFDConnection;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    LocationSensor1: TLocationSensor;
    FDQuery: TFDQuery;
    function AndroidServiceStartCommand(const Sender: TObject;
      const Intent: JIntent; Flags, StartId: Integer): Integer;

    procedure FDConnection1BeforeConnect(Sender: TObject);
    procedure LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure startAction(Sender: TObject; SAction :String; showError: boolean = true);
    procedure responseProcessing(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }

    function BoolToStr(const value: boolean): string;
    procedure SendNotification( Title, AlertBody: string; UnicName: String = '');
    //function GetLocation( LActivate: Boolean;  SleepTime, IterationsCount: Integer ):Boolean;
    function GetLocation(SleepTime: Integer;  IterationsCount: Integer = 0 ):Boolean;
  end;

var
  DM: TDM;

implementation

uses
  System.IOUtils, DateUtils,
  System.Permissions,

  Androidapi.Helpers,
  AndroidApi.JNI.App,
  Androidapi.JNI.JavaTypes,

  //uLogon,
  uTransport_Service,
  uHardwareAndroid  //Hardware data for Android
  ;

var
   DEBUG      : boolean = true;
   userid     : string;
   Transport  : TTransportData;
   WMK        : TWMKRec;
   Request    : TStringList;
   Response   : TStringList;
   ServiceLog : TStringList;

{$R *.dfm}



procedure  TDM.startAction(Sender: TObject; SAction :String; showError: boolean = true);
var
    TransportThread           : TTransportService;
begin
  TransportThread := TTransportService.Create(SAction, responseProcessing );
  Transport.isThreadRun := true;
  Transport.Action := SAction;
  Transport.showError := showError;

  TransportThread.Transport :=  Transport;
  TransportThread.WMKData := WMK;
  TransportThread.Request.Assign(Request);

  Request.Clear;
  ServiceLog.Add('Starting thread: ' +  SAction);
  TransportThread.Resume;
end;



procedure  TDM.responseProcessing(Sender: TObject);
var
  TransportThread     : TTransportService absolute Sender; // очень древняя магия. обозначает th:=TMyThread(Sender)
begin
  ServiceLog.Add('Finished thread: ' + TransportThread.Transport.Action + ' Error: ' + TransportThread.Transport.Error);
  SendNotification('#104. Finish thread','Action: ' + TransportThread.Transport.Action);

  Transport := TransportThread.Transport;  //copy data from transport thread
  Response.Clear;
  Response.Assign(TransportThread.Response);   // copy responcse (do not use " := ")
  WMK :=  TransportThread.WMKData;
  Transport.isThreadRun := false;

  if (Transport.Action <> 'getlocUserData') and
      ((not Transport.ServerAvaible) or (Transport.Error <> '')) then
      begin
        ServiceLog.Insert(0, Transport.Error);
        SendNotification('#116. Finish thread','Error : ' + Transport.Error);
      end;


  if Transport.Action = 'register'      then      //SpeedButton_RegisterClick(Sender)
  else if Transport.Action = 'logon'    then      //  GetLocation(60000,10)
  else if Transport.Action = 'getlocUserData' then //putUserDatatoLogonTab
  else if Transport.Action = 'logout'   then        //ListBoxItemLogoutClick(Sender)
  else if Transport.Action = 'getkids'  then        //GetKidsList(Sender)
  else if Transport.Action = 'getdata'  then        // ShowKidClick(Sender, '')
  else if Transport.Action = 'setdata'  then        //
  else if Transport.Action = 'getgps'   then        //ShowKidClick(Sender, '')
  else if Transport.Action = 'setgps'   then        //
           ;


  Transport.Action := '';
  Transport.Error := '';
  //Response.Clear;
end;


function TDM.BoolToStr(const value: boolean): string;
const
  Values: array [boolean] of string = ('False', 'True');
begin
  Result := Values[value];
end;


procedure TDM.SendNotification( Title, AlertBody: string; UnicName: String = '');
var
  MyNotification: TNotification;
  //NowDate : TDateTime;
begin
  sleep(100);
  MyNotification := NotificationCenter1.CreateNotification;
  //NowDate := Now;
  try
    if UnicName = '' then
      MyNotification.Name := 'Notifi at ' + IntToStr(DateUtils.MilliSecondsBetween(Now, 0) + Random(100))
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
    NotificationCenter1.ScheduleNotification(MyNotification);
  finally
    MyNotification.Free;
  end;
end;





function TDM.GetLocation(SleepTime: Integer;  IterationsCount: Integer = 0 ):Boolean;
var
  //Thread :  TThread;
  Rst : boolean;
  isFirst: boolean;
  iCounter : integer;
  // Fs : TMemoryStream;
begin
  Rst := true;
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}

  {$ELSE}
    LocationSensor1.Active := false;
    result := false;
    exit;
  {$ENDIF}
  SendNotification('#197. GetLocation','Starting');
  iCounter := 0;
  isFirst  := true;
  while ( iCounter <= IterationsCount ) do
  begin
    if DEBUG then
     SendNotification('#128. Service thread ','Iteration: ' + inttostr(iCounter) +
                        ' from ' + inttostr(IterationsCount)  );
     LocationSensor1.Active := true;    // if activate GPS in thread, thread - died / stone


         // START THREAD
         TThread.CreateAnonymousThread(
            procedure
             var
                //LocationSensorT : TLocationSensor;
                ENUSLat, ENUSLong, ENUSAtl: String; // holders for URL strings
                gpsCounter: integer;
                //logon : TLogon;
                hw: THWData;
            begin

               try
                  //logon := TLogon.Create;
                  hw    := THWData.Create;
               except on e: Exception do
                 SendNotification('#148. Service thread','Error : ' + e.Message);
               end;

               //userid := logon.getConfigParam('userid');

               if not Transport.isLogon then
                 begin
                   //FreeAndNil(logon);
                   FreeAndNil(hw);
                   SendNotification('#156. Service thread','Can not read user from the db, please relogin to the application.');
                   exit;
                 end;
               //LocationSensorT :=  TLocationSensor.Create(LocationSensorT);
                //LocationSensorT.Active := SLActivate;

               gpsCounter := 0;
               ENUSLat := 'NAN';
               while ((ENUSLat='NAN') or (ENUSLat='')) and (gpsCounter <= 5) do
                 begin
                     if DEBUG then
                        SendNotification('#165. Service thread ','GPS Circle # '+ inttostr(gpsCounter) + ' Lat: '+ ENUSLat);
                     sleep(5000);
                     ENUSLat  := 'NAN';
                     ENUSLong := 'NAN';
                     ENUSAtl  := 'NAN';
                     // Fs := TMemoryStream.Create;

                     ENUSLat  := LocationSensor1.Sensor.Latitude.ToString(ffGeneral, 9, 2, TFormatSettings.Create('en-US')).Replace(',', '.');
                     ENUSLong := LocationSensor1.Sensor.Longitude.ToString(ffGeneral, 9, 2, TFormatSettings.Create('en-US')).Replace(',', '.');
                     ENUSAtl  := System.Round(LocationSensor1.Sensor.Altitude).ToString.Replace(',', '.');
                     inc(gpsCounter);
                  end;

               if (ENUSLat <> 'NAN') or (ENUSLat <> '') then
                 begin

                    try
                        Rst := true; // get GPS location
                        {
                        To execute a query, which does not return a result set, use the ExecSQL methods.
                          If a query returns a result set, then exception "[FireDAC][Phys][MSAcc]-310.
                          Cannot execute command returning result sets" will be raised.

                        To execute a query, returning a result set and open this result set, use the Open methods.
                          If a query returns no result sets, then exception "[FireDAC][Phys][MSAcc]-308.
                          Cannot open / define command, which does not return result sets" will be raised.

                         Если не активировать FDQuery.Activate - то не происходит вставок и ошибок.
                        }
                         try
                              with FDQuery do begin
                                SQL.Clear;
                                SQL.Add('INSERT INTO locations(userid,locationx,locationy, altitude)'+
                                                    ' VALUES(:userid, :locX, :locY, :locAlt);');
                                ParamByName('userid').AsInteger := StrToInt(userid);
                                ParamByName('locX').AsString := ENUSLat;
                                ParamByName('locY').AsString := ENUSLong;
                                ParamByName('locAlt').AsString := ENUSAtl;
                              end;
                              FDQuery.ExecSQL;
                              FDQuery.Close;

                         except on e: Exception do
                            begin
                              SendNotification('#207. Service thread. DB Error', e.Message);
                              iCounter := IterationsCount +1 ; // end WHILE
                              Rst := false;
                            end;
                         end;
                    finally
                      begin
                        if DEBUG then
                          SendNotification('#217. Service thread.', 'GPS rec. insert into DB.' );
                        FDQuery.Active := false;
                        FDConnection1.Connected := false;
                      end;
                    end;


                    //logon.takeGPS;
                    startAction(nil, 'setgps');
                 end;

               // Send hardwaredata
               Request.Values['datatype'] :=  'hwinfo';
               Request.AddStrings(hw.getBatteryCharge);
               startAction(nil, 'setdata');

               //logon.sendData('hwinfo', hw.getBatteryCharge);
               if isFirst then
               begin
                  Request.Values['datatype'] :=  'hwinfo';
                  Request.AddStrings(hw.getHardwareData);
                  startAction(nil, 'setdata');
                  //logon.sendData('hwinfo', hw.getHardwareData);
               end;
               isFirst := false;

               //FreeAndNil(logon);
               FreeAndNil(hw);

            end).Start;

     //LocationSensor1.Active := false;

    //sleep(SleepTime);  // time for gps can locate position in first start
    inc(iCounter);
    if IterationsCount = 0 then    //forever   work
      iCounter := 0;

   end;
  //Thread.OnTerminate := ThreadTerminated;


  Result := Rst;
end;


procedure TDM.LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
  NewLocation: TLocationCoord2D);
begin
    {  SendNotification('SLC01 Locations', BoolToStr(LocationSensor1.Active)+' '+
              LocationSensor1.Sensor.Latitude.ToString(ffGeneral, 5, 2, TFormatSettings.Create('en-US')) + ' ' +
              LocationSensor1.Sensor.Longitude.ToString(ffGeneral, 5, 2, TFormatSettings.Create('en-US')));
     }

end;

procedure TDM.FDConnection1BeforeConnect(Sender: TObject);
begin
{$IF DEFINED(IOS) or DEFINED(ANDROID)}
  FDConnection1.Params.Values['Database'] := TPath.GetDocumentsPath + PathDelim + 'wmk.s3db';
  FDQuery.FetchOptions.RowsetSize := 2000;
  //SendNotification('DB01 Find DB', 'File is '+BoolToStr(FileExists(FDConnection1.Params.Values['Database']))+' '+FDConnection1.Params.Values['Database']+'\n is exist: ' );
{$ELSE}
  FDConnection1.Connected := false;
  // FDConnection1.Params.Values['Database'] := 'C:\Projects\WhereIsMyKid\Frontend\wmk.s3db';
{$ENDIF}
end;



function TDM.AndroidServiceStartCommand(const Sender: TObject;
  const Intent: JIntent; Flags, StartId: Integer): Integer;
begin
  Request    :=  TStringList.Create;
  Response   :=  TStringList.Create;
  ServiceLog :=  TStringList.Create;


  //startAction(Sender, 'getlocUserData');   //Get config data to local Vars


  startAction(Sender, 'logon');


  //JavaService.stopSelf;
  // The service stops itselfs after presenting the notification.  }
  if DEBUG then
    Result := TJService.JavaClass.START_NOT_STICKY
  else
     Result := TJService.JavaClass.START_STICKY;
end;



end.
