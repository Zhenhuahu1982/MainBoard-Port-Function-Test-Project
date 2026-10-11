object frm_Result1: Tfrm_Result1
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #27979#35797#32467#26524
  ClientHeight = 225
  ClientWidth = 328
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 328
    Height = 225
    Align = alClient
    Caption = 'FAIL'
    Font.Charset = ANSI_CHARSET
    Font.Color = clRed
    Font.Height = -120
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 264
    Top = 168
  end
  object WMPEffects1: TWMPEffects
    AutoConnect = False
    ConnectKind = ckRunningOrNew
    Left = 200
    Top = 120
  end
end
