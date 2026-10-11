object frm_Result: Tfrm_Result
  Left = 0
  Top = 0
  ParentCustomHint = False
  BiDiMode = bdLeftToRight
  BorderStyle = bsDialog
  Caption = #27979#35797#32467#26524
  ClientHeight = 225
  ClientWidth = 328
  Color = clBtnFace
  TransparentColorValue = clBtnFace
  UseDockManager = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clGreen
  Font.Height = -120
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ParentBiDiMode = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 145
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 328
    Height = 225
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clGreen
    Font.Height = -120
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentColor = True
    ParentFont = False
    TabOrder = 0
    object Label1: TLabel
      Left = 24
      Top = 45
      Width = 285
      Height = 135
      ParentCustomHint = False
      AutoSize = False
      BiDiMode = bdLeftToRight
      Caption = 'PASS'
      Color = clBtnFace
      Font.Charset = ANSI_CHARSET
      Font.Color = clGreen
      Font.Height = -120
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentBiDiMode = False
      ParentColor = False
      ParentFont = False
      ParentShowHint = False
      ShowAccelChar = False
      ShowHint = False
      Transparent = False
      StyleElements = [seClient, seBorder]
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 232
    Top = 136
  end
  object WMPEffects1: TWMPEffects
    AutoConnect = False
    ConnectKind = ckRunningOrNew
    Left = 112
    Top = 136
  end
end
