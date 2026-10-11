object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #27979#35797#31243#24207#35774#32622
  ClientHeight = 243
  ClientWidth = 398
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
    Width = 398
    Height = 243
    Align = alClient
    TabOrder = 0
    object RzPageControl1: TRzPageControl
      Left = 1
      Top = 1
      Width = 396
      Height = 241
      Hint = ''
      ActivePage = TabSheet2
      Align = alClient
      TabIndex = 1
      TabOrder = 0
      FixedDimension = 19
      object TabSheet1: TRzTabSheet
        Caption = #31243#24207#35774#32622
        object RzPanel2: TRzPanel
          Left = 0
          Top = 0
          Width = 392
          Height = 218
          Align = alClient
          BorderOuter = fsGroove
          TabOrder = 0
          object RzSeparator1: TRzSeparator
            Left = 2
            Top = 107
            Width = 388
            Height = 3
            HighlightColor = clHotLight
            ShowGradient = True
            Align = alTop
            Color = clBtnFace
          end
          object RzGroupBox1: TRzGroupBox
            Left = 2
            Top = 9
            Width = 388
            Height = 98
            Align = alTop
            Caption = #31243#24207#36816#34892#35774#32622
            TabOrder = 0
            object Start_Run: TRzRadioButton
              Left = 44
              Top = 30
              Width = 67
              Height = 15
              Caption = #33258#21160#27979#35797
              Checked = True
              TabOrder = 0
              TabStop = True
            end
            object Start_No: TRzRadioButton
              Left = 44
              Top = 67
              Width = 55
              Height = 15
              Caption = #26080#21160#20316
              TabOrder = 1
            end
          end
          object RzPanel1: TRzPanel
            Left = 2
            Top = 2
            Width = 388
            Height = 7
            Align = alTop
            BorderOuter = fsGroove
            TabOrder = 1
          end
          object RzDBRadioGroup2: TRzDBRadioGroup
            Left = 2
            Top = 110
            Width = 388
            Height = 106
            Align = alClient
            Caption = #27979#35797#23436#25104#21518#35774#32622
            TabOrder = 2
            object Shut_Down: TRzRadioButton
              Left = 44
              Top = 32
              Width = 43
              Height = 15
              Caption = #20851#26426
              Checked = True
              TabOrder = 0
              TabStop = True
            end
            object Close_No: TRzRadioButton
              Left = 44
              Top = 72
              Width = 55
              Height = 15
              Caption = #26080#21160#20316
              TabOrder = 1
            end
            object RzBitBtn1: TRzBitBtn
              Left = 288
              Top = 64
              Align = alCustom
              Caption = #30830'  '#23450
              TabOrder = 2
              OnClick = RzBitBtn1Click
              Kind = bkOK
            end
          end
        end
      end
      object TabSheet2: TRzTabSheet
        Caption = #31995#32479#35774#32622
        object RzPanel3: TRzPanel
          Left = 0
          Top = 0
          Width = 392
          Height = 9
          Align = alTop
          BorderOuter = fsGroove
          TabOrder = 0
        end
        object RzDBRadioGroup1: TRzDBRadioGroup
          Left = 0
          Top = 9
          Width = 392
          Height = 209
          Align = alClient
          Caption = #31995#32479#30456#20851#35774#32622
          TabOrder = 1
          object RzBitBtn2: TRzBitBtn
            Left = 288
            Top = 160
            Caption = #30830'  '#35748
            TabOrder = 0
            OnClick = RzBitBtn2Click
            Kind = bkOK
          end
          object RzCheckBox1: TRzCheckBox
            Left = 64
            Top = 48
            Width = 223
            Height = 15
            Caption = #35774#32622#31995#32479#40664#35748#38899#39057#36755#20986#35774#22791#20026#65306#25196#22768#22120
            State = cbUnchecked
            TabOrder = 1
          end
          object RzCheckBox2: TRzCheckBox
            Left = 64
            Top = 99
            Width = 183
            Height = 15
            Caption = #35774#32622#31995#32479#30561#30496#21151#33021'('#38656#22266#20214#25903#25345')'
            State = cbUnchecked
            TabOrder = 2
          end
        end
      end
    end
  end
end
