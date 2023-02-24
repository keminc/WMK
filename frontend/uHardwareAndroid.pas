unit uHardwareAndroid;

interface
uses
  System.Classes, System.Types, System.DateUtils ;

 type
   THWData = class(TObject)
      ServiceLog : TStringList;

      function getHardwareData:TStringList;
      function getBatteryCharge:TStringList;

      constructor Create;
      destructor Destroy; override;
   public

   private

   end;

implementation
uses
 system.sysutils,
  Androidapi.JNI.Telephony,
  Androidapi.JNI.Provider ,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes,
  Androidapi.Helpers,
  androidapi.JNI.Os
  {
   # Using of this units - kill android service
    FMX.Platform.Android,
    TDialog unit
  }

 ;



constructor THWData.Create;
begin
  inherited; {В начале надо вызвать конструктор класса-родителя}
  ServiceLog := TStringList.Create; {создаем структуры нашего класса}
end;

destructor THWData.Destroy;
begin
  FreeAndNil(ServiceLog); {Разрушаем структуры нашего класса}
  inherited; {в последнюю очередь вызываем деструктор клсса-родителя}
end;


function THWData.getHardwareData:TStringList;
var
  obj: JObject;
  tm: JTelephonyManager;
  identifier: String;
  Res : TStringList;
begin
  Res := TStringList.Create;

  Res.AddPair('device type',    Format('%s', [JStringToString(TJBuild.JavaClass.MODEL)]));
  Res.AddPair('device brand',   Format('%s', [JStringToString(TJBuild.JavaClass.BRAND)]));
  Res.AddPair('device display', Format('%s', [JStringToString(TJBuild.JavaClass.DISPLAY)]));
  Res.AddPair('device manuf.',  Format('%s', [JStringToString(TJBuild.JavaClass.MANUFACTURER)]));
  Res.AddPair('device model',   Format('%s', [JStringToString(TJBuild.JavaClass.MODEL)]));
  Res.AddPair('device serial',  Format('%s', [JStringToString(TJBuild.JavaClass.SERIAL)]));


  obj := SharedActivityContext.getSystemService(TJContext.JavaClass.TELEPHONY_SERVICE);
    if obj <> nil then
    begin
      tm := TJTelephonyManager.Wrap((obj as ILocalObject).GetObjectID);
      if tm <> nil then
        identifier := JStringToString(tm.getDeviceId);
       Res.AddPair('device imei 1', identifier);
    end;


    if identifier = '' then
    begin
      identifier := JStringToString(TJSettings_Secure.JavaClass.getString
        (SharedActivity.getContentResolver,
        TJSettings_Secure.JavaClass.ANDROID_ID));
      Res.AddPair('device imei 2', identifier);
    end;


    result := Res;
    FreeAndNil(Res);
end;


function THWData.getBatteryCharge:TStringList;
const
  BateryHealthStr: array [1..7] of string =
    ('unknown', 'Good', 'Overhead', 'Dead', 'Over voltage', 'unspecified failure', 'Cold');
  BateryPluggedStr: array [1..4] of string =
    ('AC plugged', 'USB plugged', 'unknown',  'Wireless plugged');
  BateryStatusStr: array [1..5] of string =
    ('Unknown', 'Charging', 'Discharging', 'Not charging', 'Full');
  BATTERY_HEALTH_COLD = 7;
  BATTERY_HEALTH_DEAD = 4;
  BATTERY_HEALTH_GOOD = 2;
  BATTERY_HEALTH_OVERHEAT = 3;
  BATTERY_HEALTH_OVER_VOLTAGE = 5;
  BATTERY_HEALTH_UNKNOWN = 1;
  BATTERY_HEALTH_UNSPECIFIED_FAILURE = 6;
var
  filter: JIntentFilter;
  intentBatt: JIntent;
  iLevel, iScale: Integer;
  i:Integer;
  Str:JString;
  b:boolean;
  myContext: JContext;
  Res : TStringList;
begin
  Res := TStringList.Create;
  myContext := SharedActivityContext;

  filter := TJIntentFilter.Create;
  filter.addAction(TJIntent.JavaClass.ACTION_BATTERY_CHANGED);
  intentBatt := myContext.registerReceiver(nil, filter);


  i := intentBatt.getIntExtra(StringToJString('health'), -1);
  Res.AddPair('battery status', BateryHealthStr[i]);

  iLevel := intentBatt.getIntExtra(StringToJString('level'), -1);
  Res.AddPair('battery level', IntToStr(iLevel));

  i := intentBatt.getIntExtra(StringToJString('plugged'), -1);
  Res.AddPair('battery plugged', BateryPluggedStr[i]);

  b := intentBatt.getBooleanExtra(StringToJString('present'), False);
  Res.AddPair('battery present', BoolToStr(b, True));

  iScale := intentBatt.getIntExtra(StringToJString('scale'), -1);
  Res.AddPair('battery escala',  IntToStr(iScale));

  i := intentBatt.getIntExtra(StringToJString('status'), -1);
  Res.AddPair('battery state',  BateryStatusStr[i]);

  Str := intentBatt.getStringExtra(StringToJString('technology'));
  Res.AddPair('battery type',  JStringToString(Str));

  i := intentBatt.getIntExtra(StringToJString('temperature'), -1);
  Res.AddPair('battery temperature',  FloatToStr(i / 10) + '°');

  i := intentBatt.getIntExtra(StringToJString('voltage'), -1);
  Res.AddPair('battery voltage',  FloatToStr(i/1000) + ' v.');

  Res.AddPair('battery percent', IntToStr((100 * iLevel) div iScale));

  result := Res;
  FreeAndNil(Res);

end;



end.
