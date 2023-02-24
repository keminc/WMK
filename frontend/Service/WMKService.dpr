program WMKService;

uses
  System.Android.ServiceApplication,
  uWMKService in 'uWMKService.pas' {DM: TAndroidService},
  uHardwareAndroid in '..\uHardwareAndroid.pas',
  uTransport_Service in 'uTransport_Service.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDM, DM);
  Application.Run;
end.

