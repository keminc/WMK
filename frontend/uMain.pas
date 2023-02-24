//---------------------------------------------------------------------------

// This software is Copyright (c) 2015 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  StrUtils,  FMX.MultiView.Types,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, Data.FMTBcd,
  System.Rtti, System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope, Data.DB,
  FMX.StdCtrls, FMX.Layouts, FMX.ListBox, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Stan.ExprFuncs,
  FireDAC.FMXUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FMX.Controls.Presentation, System.Sensors,
  System.Sensors.Components, FMX.WebBrowser, IdTCPConnection, IdTCPClient,
  IdRemoteCMDClient, IdRSH, IdBaseComponent, IdComponent, IdUDPBase,
  IdUDPClient, IdFSP, IdExplicitTLSClientServerBase,
  {$IFDEF ANDROID}

  {$ENDIF}
    uTransport,

  System.Net.URLClient,  System.NetEncoding,
  IdFTP, FMX.TabControl, REST.Types, REST.Client, Data.Bind.ObjectScope,
  REST.Authenticator.Simple, FMX.ScrollBox, FMX.Memo, REST.Authenticator.OAuth,
  REST.Response.Adapter, FMX.Edit, FMX.Styles, FMX.MultiView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.Maps, System.ImageList, FMX.ImgList, FMX.Ani, FMX.Effects,
  FMX.Objects; // Unit that contains the methods to work with services.

type
  TFormMain = class(TForm)
    ToolBar1: TToolBar;
    BindSourceDB1: TBindSourceDB;
    Title: TLabel;
    btnMasterMenu: TButton;
    FDQuery: TFDQuery;
    FDConnection: TFDConnection;
    IdFTP1: TIdFTP;
    TabControl: TTabControl;
    TabRegister: TTabItem;
    TabService: TTabItem;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    MemoServiceLog: TMemo;
    Edit_username: TEdit;
    Edit_usermail: TEdit;
    Edit_userpass: TEdit;
    PasswordEditButton1: TPasswordEditButton;
    SpeedButton_Register: TSpeedButton;
    SpeedButton_Logon: TSpeedButton;
    Label_UN: TLabel;
    LabelUE: TLabel;
    LabelUP: TLabel;
    TabClient: TTabItem;
    MultiViewClient: TMultiView;
    ListBox_ClientMenu: TListBox;
    ListBoxItemLogout: TListBoxItem;
    ListBoxItemAddParent: TListBoxItem;
    MultiViewService: TMultiView;
    Layout1: TLayout;
    ListBoxService: TListBox;
    ListBoxItemGPSStart: TListBoxItem;
    ListBoxItemReadCfg: TListBoxItem;
    ListBoxItemReadLoc: TListBoxItem;
    ListBoxItemClearCfg: TListBoxItem;
    ListBoxItemFTPUp: TListBoxItem;
    ListBoxItemClearLog: TListBoxItem;
    ListBoxItem1: TListBoxItem;
    CheckBoxParentReg: TCheckBox;
    Label_parentReg: TLabel;
    Edit_parentReg: TEdit;
    Label_client_menu: TLabel;
    Layout_client: TLayout;
    Label_client_KN: TLabel;
    ListBoxItemSavelog: TListBoxItem;
    MapView1: TMapView;
    FloatAnimation1: TFloatAnimation;
    ListBoxItemclearLoc: TListBoxItem;
    LabelClientBatt: TLabel;
    Image1: TImage;
    Image2: TImage;
    BlurEffect1: TBlurEffect;
    LabelClientPhone: TLabel;
    StyleBook1: TStyleBook;
    Image3: TImage;
    Label_Client_Error: TLabel;
    ListBoxItemAddKid: TListBoxItem;
    AniIndicator1: TAniIndicator;
    Register_AniIndicator: TAniIndicator;
    Client_AniIndicator: TAniIndicator; // For a remote service.

    procedure OpenURLinBrowser(URL:string);
    procedure FormCreate(Sender: TObject);
    procedure FDConnectionBeforeConnect(Sender: TObject);
    procedure SpeedButton_LogonClick(Sender: TObject);
    procedure SpeedButton_RegisterClick(Sender: TObject);
    procedure ListBoxItemLogoutClick(Sender: TObject);

    procedure ListView1Click(Sender: TObject);
    procedure CheckBoxParentRegChange(Sender: TObject);
    procedure ListBoxItemAddParentClick(Sender: TObject);
    procedure btnMasterMenuClick(Sender: TObject);

    procedure ListBox_ClientMenuItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure ListBoxItemSavelogClick(Sender: TObject);
    procedure TabServiceClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure MultiViewClientHidden(Sender: TObject);
    procedure MultiViewClientShown(Sender: TObject);
    procedure ListBoxItemAddKidClick(Sender: TObject);
    procedure TabClientResized(Sender: TObject);

    { DEV / DEBUG ZONE }
    procedure ListBoxItemGPSStartClick(Sender: TObject);
    procedure ListBoxItemGetGPSClick(Sender: TObject);
    procedure ListBoxItemReadCfgClick(Sender: TObject);
    procedure ListBoxItemReadLocClick(Sender: TObject);
    procedure ListBoxItemClearCfgClick(Sender: TObject);
    procedure ListBoxItemFTPUpClick(Sender: TObject);
    procedure ListBoxItemClearLogClick(Sender: TObject);
    procedure ListBoxItemclearLocClick(Sender: TObject);
    procedure ListBoxServiceItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);


  private
    { Private declarations }
   // FPermissionFineLocation: string;
    //FServiceConnection1: TLocalServiceConnection; // For a local service.
    //FServiceConnection2: TRemoteServiceConnection; // For a remote service.
    procedure GetKidsList(Sender: TObject);
    procedure ShowKidClick(Sender: TObject; username: string);
    procedure OnIdle(Sender: TObject; var FDone: Boolean);
    function PutFile2FTP( FileName:String; FileNamePrefix: string = ''; FileNamePostfix: string = '' ):boolean;
    function CheckWMKServer(ServerAvaible: boolean; LastError: string; showDialog : boolean = true):boolean;
    procedure PreloadContent(const Control: TControl);

    procedure  responseProcessing(Sender: TObject);
    procedure  startAction(Sender: TObject; SAction :String; showError: boolean = true);




  public
    { Public declarations }

  end;
 {$POINTERMATH ON}

type
  dStrArray= array[0..30,0..30] of string;
var
  FormMain          : TFormMain;
  isPermissionGPS   : boolean = false;
  WMKAccessKey      : String = 'none';
  WKMServerAvaible  : Boolean = true;
  FAccessToken      : String;   //Facebook Access  Token

  userid            : string = 'none';
  MyKids            : array[0..30,0..1] of string;  // user_id, name
  MapMarker         : array of  TMapMarker;
  //logon             : TLogon;
  WMK               : TWMKRec;
  Transport         : TTransportData;
  Request           : TStringList;
  Response          : TStringList;

  //DEDUG
  DEBUG             : boolean = true;
  ServiceLog        : TStringList;


implementation

uses
  IOUtils, System.Permissions, FMX.DialogService, FMX.MultiView.Presentations,
{$IFDEF ANDROID}

  FMX.Platform.Android,
  //Androidapi.JNI.Telephony,
  //Androidapi.JNI.Provider ,
  //Androidapi.JNIBridge,
  System.Android.Service,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes,
  FMX.Helpers.Android,
  Androidapi.Helpers,
  Androidapi.JNI.Os,

  uHardwareAndroid,  //Hardware data for Android

{$ENDIF}

  REST.Json, REST.Utils,
  System.JSON, System.JSON.Readers, System.JSON.Types,
  System.JSON.Writers, System.JSON.Builders;


{$R *.fmx}

////////////////////////////////////////////////////////////////////////////////
// BEGIN FUNCTIONS
////////////////////////////////////////////////////////////////////////////////

procedure TFormMain.PreloadContent(const Control: TControl);
var
  i: Integer;
begin
  if Control is TStyledControl then
    TStyledControl(Control).ApplyStyleLookup;
  for i := 0 to Control.ControlsCount - 1 do
    PreloadContent(Control.Controls[i]);
end;


procedure putUserDatatoLogonTab;
begin
    FormMain.Edit_username.Text := WMK.user;
    FormMain.Edit_usermail.Text := WMK.mail;
    FormMain.Edit_userpass.Text := WMK.passwd;
    FormMain.Edit_parentReg.Text := WMK.parentmail;
    if (WMK.parentmail = '') then
           FormMain.CheckBoxParentReg.IsChecked := false
     else
          FormMain.CheckBoxParentReg.IsChecked := true;

     FormMain.SpeedButton_LogonClick(nil);
end;


procedure TFormMain.OpenURLinBrowser(URL:string);
{$IFDEF ANDROID}
var
  Intent: JIntent;
{$ENDIF}
begin
{$IFDEF ANDROID}
  // Navigator
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
  Intent.setData(StrToJURI(URL));
  SharedActivity.startActivity(Intent);
 {$ENDIF}
end;


function TFormMain.CheckWMKServer(ServerAvaible: boolean; LastError: string; showDialog : boolean = true):boolean;
begin
  result := true;

     if not ServerAvaible then
        begin
          if showDialog then
             TDialogService.ShowMessage('Sorry bro, server is not avaible now :( '+
                                      #13+'We work on that!');
         result := false;
        end
     else if  LastError <> '' then
       begin
        if showDialog then
          TDialogService.ShowMessage('Sorry but, '+ LastError +'... '+
                                        #13+'Try it again!');
         result := false;
       end;

end;


procedure  TFormMain.startAction(Sender: TObject; SAction :String; showError: boolean = true);
var
    TransportThread           : TTransportThread;
begin
  TransportThread := TTransportThread.Create(SAction, responseProcessing );
  Transport.isThreadRun := true;
  Transport.Action := SAction;
  Transport.showError := showError;

  TransportThread.Transport :=  Transport;
  TransportThread.WMKData := WMK;
  TransportThread.Request.Assign(Request);

  Request.Clear;
  ServiceLog.Add('Starting SendThread');
  TransportThread.Resume;
end;


procedure  TFormMain.responseProcessing(Sender: TObject);
var
  TransportThread     : TTransportThread absolute Sender; // очень древняя магия. обозначает th:=TMyThread(Sender)
begin
  ServiceLog.Add('Finished Thread: ' + TransportThread.Transport.Action + ' Error: ' + TransportThread.Transport.Error);

  Transport := TransportThread.Transport;  //copy data from transport thread
  Response.Clear;
  Response.Assign(TransportThread.Response);   // copy responcse (do not use := )
  WMK :=  TransportThread.WMKData;
  Transport.isThreadRun := false;

  if (Transport.Action <> 'getlocUserData') and
      CheckWMKServer(Transport.ServerAvaible,  Transport.Error, Transport.showError) then
      ServiceLog.Insert(0, Transport.Error);


  if Transport.Action = 'register' then
                                              SpeedButton_RegisterClick(Sender)
  else if Transport.Action = 'logon' then
                                              SpeedButton_LogonClick(Sender)
  else if Transport.Action = 'getlocUserData' then
                                              putUserDatatoLogonTab
  else if Transport.Action = 'logout' then
                                              ListBoxItemLogoutClick(Sender)
  else if Transport.Action = 'getkids' then
                                              GetKidsList(Sender)
  else if Transport.Action = 'getdata' then
                                              ShowKidClick(Sender, '')
  else if Transport.Action = 'setdata' then
           //
  else if Transport.Action = 'getgps' then
                                              ShowKidClick(Sender, '')
  else if Transport.Action = 'setgps' then
           //
           ;


  Transport.Action := '';
  Transport.Error := '';
  //Response.Clear;


end;


function TFormMain.PutFile2FTP( FileName:String; FileNamePrefix: string = ''; FileNamePostfix: string = '' ):boolean;
var
   Thread :  TThread;
  // Fs : TMemoryStream;
  RESULT_int : boolean;
begin
  RESULT_int := true;
  if not FileExists(FileName) then
  begin
    RESULT := false;
    exit;
  end;


  Thread := TThread.CreateAnonymousThread(
    procedure
    begin
      // IF ftp connection is in use
      while  IdFTP1.Connected  do
      begin
        Sleep(500);
      end;



      IdFTP1.Host := '185.58.193.5';
      IdFTP1.Username := 'wmk.ftp';
      IdFTP1.Password := 'wmkpassword';
      IdFTP1.Passive := True;
      IdFTP1.ConnectTimeout := 20000;
      //IdFTP1.TransferType := IdFTP1.TransferType.ftBinary;


     // Fs := TMemoryStream.Create;
      try
        try
          try

            //IdFTP1.Get(FileName, FS);
            IdFTP1.Connect;
            IdFTP1.Put(FileName, FileNamePrefix + FileNamePostfix + ExtractFileName(FileName));
          except
            RESULT_int := false;
          end;
        finally
          IdFTP1.Disconnect;
        end;
       // FS.Position := 0;
        TThread.Synchronize(Thread.CurrentThread,
          procedure
          begin
            sleep(100);
            //TDialogService.ShowMessage('');
          end );
      finally
        //Fs.Free;
      end;
    end
  );

  //Thread.OnTerminate := ThreadTerminated;
  Thread.Start;
  result := RESULT_int;
end;


function grandGPSPermissions(ptype: string = 'gps' ):boolean;
var
  permission :string;
  pg : boolean;
begin
  result := false;
    {$IFDEF ANDROID}
  //SetLength(permission,1);
  //permission := [   JStringToString(TJManifest_permission.JavaClass.READ_PHONE_STATE) ] ;
  if ptype = 'gps' then
      permission := JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)
   else if ptype = 'phone' then
      permission := JStringToString(TJManifest_permission.JavaClass.READ_PHONE_STATE)
    else
      exit;

    //get GPS permissions

     PermissionsService.RequestPermissions(
            [ permission ],
             procedure(const APermissions: TArray<string>; const AGrantResults: TArray<TPermissionStatus>)
              begin
                if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted)  then
                  begin
                    pg := true;
                  end
                else
                  begin
                    pg := false;
                    TDialogService.ShowMessage('Location permission for '+ptype+' not granted. '+
                             'You can grant it by yourself from the phone menu: Settings-Applications.');
                  end;
              end
          );
      result := pg;
      {$ELSE}
        result := true;
      {$ENDIF}

end;

////////////////////////////////////////////////////////////////////////////////
// END FUNCTIONS
////////////////////////////////////////////////////////////////////////////////


procedure TFormMain.btnMasterMenuClick(Sender: TObject);
begin

 if TabService.IsSelected = true then
   if MultiViewService.IsShowed  = true then
       MultiViewService.HideMaster
    else
       MultiViewService.ShowMaster;

  if TabClient.IsSelected  = true then
   if MultiViewClient.IsShowed  = true then
    begin
       MultiViewClient.HideMaster;

    end
    else
    begin
       MultiViewClient.ShowMaster;

    end;
end;

procedure TFormMain.CheckBoxParentRegChange(Sender: TObject);
begin
 Edit_parentReg.Visible := CheckBoxParentReg.IsChecked;
 Label_parentReg.Visible := CheckBoxParentReg.IsChecked;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin

  Request    :=  TStringList.Create;
  Response   :=  TStringList.Create;


  Application.OnIdle := OnIdle;
  btnMasterMenu.Visible := false;
  Register_AniIndicator.Visible := false;
  //TAB
  TabControl.ActiveTab := TabRegister;
  TabClient.Visible := false;
  if not DEBUG  then
    TabService.Visible := false;
   ServiceLog := TStringList.Create;

  //EDITS
  Edit_parentReg.Visible := false;
  Label_parentReg.Visible :=  false;
  //Label_Client_Error.Visible := false;

  //MENU
  MultiViewClient.DrawerOptions.TouchAreaSize := 50;
  MultiViewService.DrawerOptions.TouchAreaSize := 50;
  PreloadContent(MultiViewClient);

   // Input logon data from config file

   startAction(Sender, 'getlocUserData');

  {
  // If data is in config Db file then logon
  if  (FormMain.Edit_usermail.Text <> '') and
      //(FormMain.Edit_username.Text <> '') and
      (FormMain.Edit_userpass.Text <> '') then
    SpeedButton_LogonClick(Sender);

    }
end;



procedure TFormMain.FormDestroy(Sender: TObject);
begin
  //FreeAndNil(logon);
  FreeAndNil(Request);
  FreeAndNil(Response);
end;

procedure TFormMain.ListBoxItemAddKidClick(Sender: TObject);
begin
  MultiViewClient.HideMaster;
  TDialogService.ShowMessage('You can connect you account to kid from kids device by using "Add Parent" menu item. ');
end;

procedure TFormMain.ListBoxItemAddParentClick(Sender: TObject);
var
    LDefaultValue, LPrompt, TaskName: string;
begin
   try
      LPrompt := 'Parent must be already registered in app.';
      LDefaultValue := '';
      TDialogService.InputQuery('Enter parent e-mail', [LPrompt], [LDefaultValue],
        procedure(const AResult: TModalResult; const AValues: array of string)
        begin
          if AResult = mrOk then
            TaskName := AValues[0]
          else
            TaskName := '';
          if not (TaskName.Trim = '') then
          begin
           // logon.addParent(TaskName.Trim);
            //CheckWMKServer;
          end;
        end);
  except  on e: Exception do
    begin
      ShowMessage(e.Message);
    end;
  end;

end;


procedure TFormMain.ListBoxItemClearCfgClick(Sender: TObject);
begin


   try
        FDConnection.Connected := true;
      // Fill list with GPS data
      try

        FDQuery.Close;
        FDQuery.SQL.Text := 'DELETE FROM config;';   //param_name, param_value, param_type
        //FDQuery.ParamByName('userid').AsInteger :=  userid;
        FDQuery.ExecSQL;

      except
        on e: Exception do
        begin
          TDialogService.ShowMessage('ESelect 8: ' + e.Message);
        end;
      end;

   finally
      FDQuery.Close;
      FDQuery.Active := false;
      FDConnection.Connected := false;
   end;
end;

procedure TFormMain.ListBoxItemclearLocClick(Sender: TObject);
begin

   try
        FDConnection.Connected := true;
      // Fill list with GPS data
      try

        FDQuery.Close;
        FDQuery.SQL.Text := 'DELETE FROM locations;';   //param_name, param_value, param_type
        //FDQuery.ParamByName('userid').AsInteger :=  userid;
        FDQuery.ExecSQL;

      except
        on e: Exception do
        begin
          TDialogService.ShowMessage('ESelect 9: ' + e.Message);
        end;
      end;

   finally
      FDQuery.Close;
      FDQuery.Active := false;
      FDConnection.Connected := false;
   end;
end;

procedure TFormMain.ListBoxItemClearLogClick(Sender: TObject);
begin
  MemoServiceLog.Lines.Clear;
end;

procedure TFormMain.ListBoxItemFTPUpClick(Sender: TObject);
var
  FN: string;
begin
  AniIndicator1.Visible := true;
  AniIndicator1.Enabled := true;
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}

  {$ELSE}
        TDialogService.ShowMessage('Windows OS detected. ');
  {$ENDIF}
        // Upload local DB to the FTP Server
        //FN := FDConnection.Params.Values['Database'];
        FN := TPath.GetDocumentsPath + PathDelim + 'wmk.s3db';
        if  PutFile2FTP(FN, 'uID' + WMK.mail + '_','') then
           TDialogService.ShowMessage('File OK Uploaded : ' + FN)
        else
           TDialogService.ShowMessage('File NOT uploaded: ' + FN) ;
       //////////////////////
       sleep(2000);
       FN := TPath.GetDocumentsPath + PathDelim + 'wmk.client.log';
       if PutFile2FTP(FN, 'uID' +  WMK.mail + '_','') then
            TDialogService.ShowMessage('File OK Uploaded : '+ FN)
       else
            TDialogService.ShowMessage('File NOT uploaded: '+ FN);


      AniIndicator1.Enabled := false;
      AniIndicator1.Visible := false;
end;

procedure TFormMain.ListBoxItemGetGPSClick(Sender: TObject);
//const
  //LGoogleMapsURL: String = 'https://maps.google.com/maps?q=%s,%s';
var
  ENUSLat, ENUSLong: String; // holders for URL strings
begin
   with FDQuery do begin
     SQL.Text := 'select * from locations WHERE recid = (select MAX(recid) from locations);';
     FDQuery.Open;   // use when return not null value
     ENUSLat  := FDQuery.FieldByName('locationx').AsString;
     ENUSLong := FDQuery.FieldByName('locationy').AsString;
     FDQuery.Close;
   end;
 { and track the location via Google Maps }
  MemoServiceLog.Lines.Insert(0,' ');
  MemoServiceLog.Lines.Insert(0,'GPS: '+ ENUSLat + ' '+ENUSLong);
end;



procedure TFormMain.ListBoxItemReadCfgClick(Sender: TObject);
Var
  asql:string;
  i: integer;
begin
   try
        MemoServiceLog.Lines.Insert(0,' ');
        FDConnection.Connected := true;
      // Fill list with GPS data
      try

        FDQuery.Close;
        FDQuery.SQL.Text := 'SELECT param_name, param_value FROM config;';   //param_name, param_value, param_type
        //FDQuery.ParamByName('userid').AsInteger :=  userid;
        FDQuery.Open;

        if FDQuery.RecordCount = 0 then
               MemoServiceLog.Lines.Insert(0,'No records in DB');

        FDQuery.First;
        for i:= 1 to FDQuery.RecordCount do
            begin
              asql := FDQuery.FieldByName('param_name').AsString + '  = '+
                      FDQuery.FieldByName('param_value').AsString;
              MemoServiceLog.Lines.Insert(0,asql);
              FDQuery.Next;
            end;

       except   on e: Exception do
        begin
              TDialogService.ShowMessage('ESelect 5: ' + e.Message);
        end;
      end;

   finally
     begin
      FDQuery.Close;
      FDQuery.Active := false;
      FDConnection.Connected := false;
     end;
   end;
end;

procedure TFormMain.ListBoxItemReadLocClick(Sender: TObject);
Var
  asql:string;
  i: integer;
begin
   try
        FDConnection.Connected := true;
      // Fill list with GPS data
      try
        MemoServiceLog.Lines.Insert(0,' ');
        FDQuery.Close;
        FDQuery.SQL.Text := 'SELECT * FROM  locations;';
        //FDQuery.ParamByName('userid').AsInteger :=  userid;
        FDQuery.Open;

        if FDQuery.RecordCount = 0 then
               MemoServiceLog.Lines.Insert(0,'No records in DB');

        FDQuery.First;
        for i:= 1 to FDQuery.RecordCount do
          if (i > FDQuery.RecordCount - 10) then
            begin

              asql := FDQuery.FieldByName('timestamp').AsString + ' '+
                      FDQuery.FieldByName('locationx').AsString + ' '+
                      FDQuery.FieldByName('locationy').AsString + ' '+
                      FDQuery.FieldByName('altitude').AsString;
              MemoServiceLog.Lines.Insert(0,asql);

              FDQuery.Next;
            end
          else
            FDQuery.Next;

      except
        on e: Exception do
        begin
          TDialogService.ShowMessage('ESelect 3: ' + e.Message);
        end;
      end;

   finally
      FDQuery.Close;
      FDQuery.Active := false;
      FDConnection.Connected := false;
   end;
end;

procedure TFormMain.ListBoxItemSavelogClick(Sender: TObject);
begin
  ServiceLog.SaveToFile(TPath.GetDocumentsPath + PathDelim + 'wmk.client.log');
  //FDConnection.Params.SaveToFile(TPath.GetDocumentsPath + PathDelim + 'wmk.FDConnection.cfg');

end;

procedure TFormMain.ListBoxServiceItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  Item.IsSelected := False;
  MultiViewService.HideMaster;
end;

procedure TFormMain.ListBox_ClientMenuItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin

  Item.IsSelected := False;
  MultiViewClient.HideMaster;

  Application.ProcessMessages;

  if not MatchStr(Item.Text, ['Add parent','Add kid', 'Logout'])  then
    //TThread.Synchronize(nil, procedure
    //begin
      ShowKidClick(Sender,Item.Text);
   // end);




end;

procedure TFormMain.ListView1Click(Sender: TObject);
begin
  //MultiViewClient.HideMaster;
end;

procedure TFormMain.MultiViewClientHidden(Sender: TObject);
begin
  MapView1.Visible := true;
end;

procedure TFormMain.MultiViewClientShown(Sender: TObject);
begin
  MapView1.Visible := false;
end;

procedure TFormMain.OnIdle(Sender: TObject; var FDone: Boolean);
begin
   //
end;



procedure TFormMain.TabClientResized(Sender: TObject);
begin
     if  length(MyKids[0,0]) > 5 then
         begin
            ListBox_ClientMenu.OnItemClick(ListBox_ClientMenu, ListBox_ClientMenu.ItemByIndex(0));
         end;
end;

procedure TFormMain.TabServiceClick(Sender: TObject);
begin
  MemoServiceLog.Lines.Clear;
  MemoServiceLog.Lines.AddStrings(ServiceLog);
end;

procedure TFormMain.FDConnectionBeforeConnect(Sender: TObject);
begin
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}
    FDConnection.Params.Values['Database'] := TPath.GetDocumentsPath + PathDelim + 'wmk.s3db';
    FDConnection.Params.Values['DriverID'] := 'SQLite';
    FDQuery.FetchOptions.RowsetSize := 2000;
    //ShowMessage( FDConnection.Params.Values['Database'] );
  {$ELSE}
    FDConnection.Params.Values['Database'] := 'C:\Projects\WhereIsMyKid\Frontend\wmk.s3db';
  {$ENDIF}
end;

procedure TFormMain.SpeedButton_LogonClick(Sender: TObject);
begin
 if (Transport.isLogon = false) and  (Transport.Error = '') then //first run
     begin
        if  ( Edit_usermail.Text.Length < 4)
          or ( Edit_userpass.Text.Length < 4 )  then
          begin
            TDialogService.ShowMessage('Please, enter all fields.');
            exit;
          end;

        WMK.user    := FormMain.Edit_username.Text;
        WMK.mail    := FormMain.Edit_usermail.Text;
        WMK.passwd  := FormMain.Edit_userpass.Text;

        SpeedButton_Logon.Enabled := false;
        SpeedButton_Register.Enabled := false;
        Register_AniIndicator.Visible := true;
        Register_AniIndicator.Enabled := true;

        startAction(Sender, 'logon');
     end
 else
 if (Transport.isLogon = false) and  (Transport.Error <> '') then //error on logon
     begin
        SpeedButton_Logon.Enabled := true;
        SpeedButton_Register.Enabled := true;
        Register_AniIndicator.Visible := false;
        Register_AniIndicator.Enabled := false;
        Transport.Error := '';
        exit;
     end
 else
 if (Transport.isLogon = true) and  (Transport.Error = '') then
    begin
     Register_AniIndicator.Visible := false;
     Register_AniIndicator.Enabled := false;
     if grandGPSPermissions then
         begin
           // GET Kids kist from server
           if CheckBoxParentReg.IsChecked then
             begin
              ListBoxItemAddKid.Visible := false;
              ListBoxItemAddParent.Visible := true;
             end
           else
            begin
              ListBoxItemAddParent.Visible := false;
              ListBoxItemAddKid.Visible := true;
              startAction(Sender, 'getkids')
            end;

           startAction(Sender, 'setgps');

            Register_AniIndicator.Enabled := false;
            Register_AniIndicator.Visible := false;



           TabRegister.Visible := false;
           TabClient.Visible := true;
           TabControl.ActiveTab := TabClient;
           btnMasterMenu.Visible := true;

         end
     else
        begin
          TDialogService.ShowMessage('Please, click Login and grand permissions.');
          SpeedButton_Logon.Enabled := true;
          //SpeedButton_Register.Enabled := true;
        end;
    end;
end;

procedure TFormMain.SpeedButton_RegisterClick(Sender: TObject);
begin
 if (Transport.isRegister = false) and  (Transport.Error = '') then //first run
    begin
     if  ( Edit_username.Text.Length < 4)
          or ( Edit_usermail.Text.Length < 4)
          or ( Edit_userpass.Text.Length < 4 )
          or (CheckBoxParentReg.IsChecked and (Edit_parentReg.Text.Length < 4))
      then
          begin
            TDialogService.ShowMessage('Please, enter all fields.');
            exit
          end;

      SpeedButton_Logon.Enabled := false;
      SpeedButton_Register.Enabled := false;

       WMK.user     := FormMain.Edit_username.Text;
       WMK.passwd   := FormMain.Edit_userpass.Text;
       WMK.mail     := FormMain.Edit_usermail.Text;
       WMK.isKid    := FormMain.CheckBoxParentReg.IsChecked;
       if WMK.isKid  then
        WMK.parentmail := FormMain.Edit_parentReg.Text;


     // logon.doRegister;
       Register_AniIndicator.Visible := true;
       Register_AniIndicator.Enabled := true;
       startAction(Sender, 'register');

    end
 else if (Transport.isRegister = false) and  (Transport.Error <> '') then //error on logon
    begin
      SpeedButton_Logon.Enabled := true;
      SpeedButton_Register.Enabled := true;
      Register_AniIndicator.Visible := false;
      Register_AniIndicator.Enabled := false;
      Transport.Error := '';
      exit;
    end
 else  if (Transport.isRegister = true) and (Transport.Error = '') then  // on ok
    begin
        // set data to DB going in Tranport module


        Register_AniIndicator.Visible := false;
        Register_AniIndicator.Enabled := false;
        SpeedButton_LogonClick(Sender);
    end;

end;

procedure TFormMain.GetKidsList(Sender: TObject);
var
   //resultStr : string;
   mykidsList : TStringList;
   i,x : byte;
   //ListBoxItem : TListBoxItem;
begin
      mykidsList := TStringList.Create;
      mykidsList.Delimiter := ' ';
      mykidsList.StrictDelimiter := true;
      mykidsList.DelimitedText := Response.Values['data.mykids'];

      if mykidsList.Count > 0 then
      begin
       {$IFDEF WINDOWS}
         //MultiViewClient.ShowMaster;
         //MultiViewClient.Visible := true;
       {$ENDIF}
        WMK.Kids := nil;
        ListBox_ClientMenu.BeginUpdate;
        try
          x := 0;
          for i := 0 to mykidsList.Count - 1 do
          begin

            if (i mod 2)  = 0 then
             begin
              MyKids[x,0] :=  mykidsList.Strings[i] ;
              SetLength(WMK.Kids, Length(WMK.Kids) +1);
              WMK.Kids[High(WMK.Kids)].id :=  mykidsList.Strings[i];
             end
            else
              begin
                MyKids[x,1] := mykidsList.Strings[i];
                WMK.Kids[High(WMK.Kids)].name :=  mykidsList.Strings[i];
                {
                ListBoxItem := TListBoxItem.Create(ListBox_ClientMenu);
                ListBoxItem.Text :=  MyKids[x,1];
                ListBoxItem.Name :=  MyKids[x,1];
                ListBox_ClientMenu.InsertObject(0, ListBoxItem);
                }

                ListBox_ClientMenu.Items.Insert(0,WMK.Kids[High(WMK.Kids)].name);
                inc(x);
              end;
          end;
        except on e: Exception do
          TDialogService.ShowMessage('Create list: '+ e.Message);
        end;
        ListBox_ClientMenu.EndUpdate;

        if Length(WMK.Kids) > 0  then
            ShowKidClick(Sender, WMK.Kids[0].name );

       end;

      FreeAndNil(mykidsList);

      Register_AniIndicator.Enabled := false;
      Register_AniIndicator.Visible := false;
      TabClient.Repaint;
      //MultiViewClient.ShowMaster;
      //sleep(500);
      //MultiViewClient.HideMaster;

end;

procedure TFormMain.ListBoxItemGPSStartClick(Sender: TObject);
begin
  {$IFDEF ANDROID}
    TLocalServiceConnection.StartService('WMKService');
  {$ENDIF}
end;

procedure TFormMain.ListBoxItemLogoutClick(Sender: TObject);
var
  i,x: integer;
begin
    if (Transport.isLogon = true) and  (Transport.Error = '') then   //first
        begin
          Client_AniIndicator.Visible := true;
          Client_AniIndicator.Enabled := true;
          TabClient.Enabled := false;
          startAction(sender, 'logout');
        end
    else
    if (Transport.isLogon = true) and  (Transport.Error <> '') then  // on error
        begin
          Client_AniIndicator.Visible := false;
          Client_AniIndicator.Enabled := false;
          TabClient.Enabled := true;
        end
    else  if (Transport.isLogon = false) and  (Transport.Error = '') then  //on ok
        begin
            LabelClientBatt.Text  :=  'Battery: no data';
            LabelClientPhone.Text :=  'Phone: no data';
            //MapView1.Location.Zero;
            MapView1.Zoom := 10;
            Image2.Scale.X := 0;
            SpeedButton_Logon.Enabled := true;
            SpeedButton_Register.Enabled := true;
            TabRegister.Visible := true;
            TabControl.ActiveTab := TabRegister;
            TabClient.Visible := false;
            TabClient.Enabled := true;
            btnMasterMenu.Visible := false;
            Client_AniIndicator.Visible := false;
            Client_AniIndicator.Enabled := false;

            //Clear marker
            if high(MapMarker) > -1 then
             for i:=0 to high(MapMarker) do
              if Assigned(MapMarker[i]) then
                 MapMarker[i].Remove;
            setlength(MapMarker,0);

             ListBox_ClientMenu.BeginUpdate;
            try
              // Delete kind list from Client menu
              i := 0;
              while i < ListBox_ClientMenu.Items.Count-1 do
                begin
                  for x := 0 to High(WMK.Kids) do
                    //if (ListBox_ClientMenu.ItemByIndex(i).Name = MyKids[x,1]) and (MyKids[x,1] <> '')then
                    if (ListBox_ClientMenu.ListItems[i].Text = WMK.Kids[x].name) then
                      begin
                        ListBox_ClientMenu.Items.Delete(i);
                       //ListBox_ClientMenu.ItemByIndex(i).Destroy;
                       //ListBox_ClientMenu.ListItems[i].Destroy;
                       i := i - 1 ;
                       break;
                      end;
                   inc(i);
                end;
            except  on e: Exception do
              begin
                if DEBUG then TDialogService.ShowMessage(e.Message);
              end;
            end;
            ListBox_ClientMenu.EndUpdate;

            // remove kids
            for x := 0 to 30 do
             begin
               MyKids[x,1] := '';
               MyKids[x,0] := '';
             end;

             WMK.Kids := nil;
        end;
end;

procedure TFormMain.ShowKidClick(Sender: TObject; username: string);
//const
  //LGoogleMapsURL: String = 'https://maps.google.com/maps?q=%s,%s';
var
  MapCenter: TMapCoordinate;
  KidMarker: TMapMarkerDescriptor;
  GPS, Binfo: TStringDynArray;
  i : byte;
begin
 try

    if (username <> '') and  (Transport.Error = '') then // first
      begin
        Client_AniIndicator.Visible := true;
        Client_AniIndicator.Enabled := true;
        //TabClient.Enabled           := false;

         for i := 0 to High(WMK.Kids) do
           if username = WMK.Kids[i].name then
            begin
               Label_client_KN.Text :=  WMK.Kids[i].name;
               Request.Values['userid']   :=  WMK.Kids[i].id;
               Request.Values['datatype'] :=  'hwinfo';
               Request.Values['datakey']  :=  'device brand';
               startAction(Sender, 'getdata', false);

               {Request.Values['userid']   :=  WMK.Kids[i].id;
               Request.Values['datatype'] :=  'hwinfo';
               Request.Values['datakey']  :=  'device model';
               startAction(Sender, 'getdata');}

               Request.Values['userid']   :=  WMK.Kids[i].id;
               Request.Values['datatype'] :=  'hwinfo';
               Request.Values['datakey']  :=  'battery percent';
               startAction(Sender, 'getdata', false);

               Request.Values['userid']   :=  WMK.Kids[i].id;
               Request.Values['username']   :=  WMK.Kids[i].name;
               startAction(Sender, 'getgps', false);
               break;
            end;

        //Clear marker
        if Length(MapMarker) > 0 then
         for i:=0 to high(MapMarker) do
          if Assigned(MapMarker[i]) then
             MapMarker[i].Remove;

        setlength(MapMarker,0);
        LabelClientBatt.Text  := 'Searching...';
        LabelClientPhone.Text := 'Searching...';
        Label_Client_Error.Text := '';
        Label_Client_Error.Visible := false;
      end   else

    if (username = '') and  (Transport.Error <> '')  then //on error
      begin
        Label_Client_Error.Visible := true;
        if Response.Values['data.datakey']  =  'battery percent' then
          LabelClientBatt.Text  :=  'Battery: no data';
        if Response.Values['data.datakey']  =  'device brand' then
          LabelClientPhone.Text :=  'Phone: no data';
        if Response.Values['data.datakey']  =  'gpslocation' then
          Label_Client_Error.Text :=  'No GPS data found for '+username+'.';

        Image2.Scale.X := 0;
        MapView1.Location.Zero;
        MapView1.Zoom := 10;

        Client_AniIndicator.Visible := false;
        Client_AniIndicator.Enabled := false;
        Transport.Error := '';
        //TabClient.Enabled           := true;
      end else

    if (username = '') and  (Transport.Error = '') and (Response.Values['data.datatype'] =  'hwinfo') then //on ok
      begin
        Label_Client_Error.Visible := false;
        if Length(Response.Values['data.battery percent']) > 0 then
           begin
             LabelClientBatt.Text :=  'Battery ' +  Response.Values['data.battery percent'] + ' % at ' + '...' + ' ' +  '...';
             Image2.Scale.X := (Response.Values['data.battery percent'].ToInt64 / 100 );
           end else
        if Length(Response.Values['data.device brand']) > 0 then
           begin
              LabelClientPhone.Text :=  'Phone: '+Response.Values['data.device brand'] + ' ';  //* Add model name
            end;

        Client_AniIndicator.Visible := false;
        Client_AniIndicator.Enabled := false;
      end else

    if (username = '') and  (Transport.Error = '') and (Response.Values['data.datatype'] =  'gpslocation') then //on ok
      begin
               MapCenter := TMapCoordinate.Create(StrToFloat(Response.Values['data.latitude'], TFormatSettings.Invariant),
                                                  StrToFloat(Response.Values['data.longitude'], TFormatSettings.Invariant));
               KidMarker := TMapMarkerDescriptor.Create(MapCenter);
               KidMarker.Draggable := false;
               KidMarker.Appearance := TMarkerAppearance(1);
               KidMarker.Visible   := True;
               KidMarker.Title     := Response.Values['data.username']; //name
               KidMarker.Snippet   := 'Was here: '+ Response.Values['data.date'] ; //date
               setlength(MapMarker,length(MapMarker)+1);
               MapMarker[high(MapMarker)] := MapView1.AddMarker(KidMarker);



               MapView1.Location := MapCenter;
               MapView1.Zoom := 15;
               MapView1.ShowHint := true;
      end;


 except
    on e: Exception do
    begin
       if DEBUG then ShowMessage('Some error: ' + e.Message);
    end;
  end;



 end;

end.
