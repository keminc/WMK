object DM: TDM
  OldCreateOrder = False
  OnStartCommand = AndroidServiceStartCommand
  Height = 238
  Width = 324
  object NotificationCenter1: TNotificationCenter
    Left = 184
    Top = 24
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'Database=C:\Projects\WhereIsMyKid\Frontend\wmk.s3db'
      'DriverID=SQLite')
    LoginPrompt = False
    BeforeConnect = FDConnection1BeforeConnect
    Left = 24
    Top = 24
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Console'
    Left = 104
    Top = 24
  end
  object LocationSensor1: TLocationSensor
    OnLocationChanged = LocationSensor1LocationChanged
    Left = 176
    Top = 88
  end
  object FDQuery: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      'SELECT * FROM locations;')
    Left = 24
    Top = 76
  end
end
