object Form2: TForm2
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #31995#32479#21464#37327#35774#32622
  ClientHeight = 189
  ClientWidth = 260
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 260
    Height = 189
    Align = alClient
    TabOrder = 0
    object Label1: TLabel
      Left = 34
      Top = 40
      Width = 60
      Height = 13
      Caption = #27880#20876#34920#39033#65306
    end
    object Label2: TLabel
      Left = 34
      Top = 92
      Width = 60
      Height = 13
      Caption = #27880#20876#34920#20540#65306
    end
    object Button1: TButton
      Left = 144
      Top = 135
      Width = 75
      Height = 25
      Caption = #35774'  '#32622
      TabOrder = 0
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 98
      Top = 37
      Width = 121
      Height = 21
      TabOrder = 1
    end
    object Edit2: TEdit
      Left = 98
      Top = 89
      Width = 121
      Height = 21
      TabOrder = 2
    end
  end
  object Button2: TButton
    Left = 34
    Top = 135
    Width = 75
    Height = 25
    Caption = #35835#21462
    TabOrder = 1
    OnClick = Button2Click
  end
end
