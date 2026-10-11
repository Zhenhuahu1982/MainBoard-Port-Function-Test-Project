object Frm_Result_Fail: TFrm_Result_Fail
  Left = 100
  Top = 100
  Caption = 'Fail'
  ClientHeight = 208
  ClientWidth = 413
  Color = clWhite
  Font.Charset = ANSI_CHARSET
  Font.Color = clRed
  Font.Height = -147
  Font.Name = 'Times New Roman'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 192
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 413
    Height = 208
    Align = alClient
    BiDiMode = bdLeftToRight
    Color = clWhite
    Ctl3D = True
    UseDockManager = False
    DoubleBuffered = False
    Font.Charset = ANSI_CHARSET
    Font.Color = clRed
    Font.Height = -147
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentBiDiMode = False
    ParentBackground = False
    ParentCtl3D = False
    ParentDoubleBuffered = False
    ParentFont = False
    ShowCaption = False
    TabOrder = 0
  end
  object tmr1: TTimer
    Enabled = False
    Interval = 500
    Left = 80
    Top = 16
  end
end