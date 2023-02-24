 //---------------------------------------------------------------------------

// This software is Copyright (c) 2015 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

program WMK;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain,
  {$IFDEF ANDROID}
  uWMKService in 'Service\uWMKService.pas' {DM: TAndroidService},
  {$ENDIF }
  uTransport in 'uTransport.pas',
  uTransport_Service in 'Service\uTransport_Service.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
