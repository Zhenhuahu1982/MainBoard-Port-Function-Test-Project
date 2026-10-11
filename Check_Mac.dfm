object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'MACID'#26816#27979
  ClientHeight = 259
  ClientWidth = 393
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 88
    Top = 80
    Width = 224
    Height = 29
    Caption = #35831#25195#30721'MAC ID'#26465#30721#65306
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Edit1: TEdit
    Left = 40
    Top = 136
    Width = 321
    Height = 21
    Alignment = taCenter
    CharCase = ecUpperCase
    TabOrder = 0
    OnKeyPress = Edit1KeyPress
  end
end
