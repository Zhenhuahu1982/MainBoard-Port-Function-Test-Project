object TFrmAudioLoopCfg
  Left = 100
  Top = 100
  Caption = '音频回路测试'
  ClientHeight = 620
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 620
    Align = alClient
    TabOrder = 0
    object lblOutTitle: TLabel
      Left = 16
      Top = 14
      Width = 200
      Height = 20
      Caption = 'OUT_PORT 输出接口'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
    end
    object lblInTitle: TLabel
      Left = 240
      Top = 14
      Width = 200
      Height = 20
      Caption = 'IN_PORT 输入接口'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
    end
    object lblTestTitle: TLabel
      Left = 464
      Top = 14
      Width = 200
      Height = 20
      Caption = '功能测试项'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
    end
    object grpOut: TGroupBox
      Left = 16
      Top = 40
      Width = 210
      Height = 150
      Caption = 'OUT_PORT 输出接口'
      TabOrder = 0
      object chkOut0: TCheckBox
        Left = 16
        Top = 24
        Width = 110
        Height = 20
        Caption = 'FRONT OUT'
        TabOrder = 0
      end
      object chkOutJD0: TCheckBox
        Left = 116
        Top = 24
        Width = 84
        Height = 20
        Caption = 'JD 侦测'
        TabOrder = 1
      end
      object chkOut1: TCheckBox
        Left = 16
        Top = 48
        Width = 110
        Height = 20
        Caption = 'SURR OUT'
        TabOrder = 2
      end
      object chkOutJD1: TCheckBox
        Left = 116
        Top = 48
        Width = 84
        Height = 20
        Caption = 'JD 侦测'
        TabOrder = 3
      end
      object chkOut2: TCheckBox
        Left = 16
        Top = 72
        Width = 110
        Height = 20
        Caption = 'CEN/LFE OUT'
        TabOrder = 4
      end
      object chkOutJD2: TCheckBox
        Left = 116
        Top = 72
        Width = 84
        Height = 20
        Caption = 'JD 侦测'
        TabOrder = 5
      end
    end
    object grpIn: TGroupBox
      Left = 240
      Top = 40
      Width = 210
      Height = 190
      Caption = 'IN_PORT 输入接口'
      TabOrder = 1
      object chkIn0: TCheckBox
        Left = 16
        Top = 24
        Width = 120
        Height = 20
        Caption = 'MIC IN1 (后置)'
        TabOrder = 0
      end
      object chkInJD0: TCheckBox
        Left = 130
        Top = 24
        Width = 74
        Height = 20
        Caption = 'JD 侦测'
        TabOrder = 1
      end
      object chkIn1: TCheckBox
        Left = 16
        Top = 48
        Width = 120
        Height = 20
        Caption = 'MIC IN2 (前置)'
        TabOrder = 2
      end
      object chkInJD1: TCheckBox
        Left = 130
        Top = 48
        Width = 74
        Height = 20
        Caption = 'JD 侦测'
        TabOrder = 3
      end
      object chkIn2: TCheckBox
        Left = 16
        Top = 72
        Width = 120
        Height = 20
        Caption = 'LINE IN1'
        TabOrder = 4
      end
      object chkInJD2: TCheckBox
        Left = 130
        Top = 72
        Width = 74
        Height = 20
        Caption = 'JD 侦测'
        TabOrder = 5
      end
      object chkIn3: TCheckBox
        Left = 16
        Top = 96
        Width = 120
        Height = 20
        Caption = 'LINE IN2'
        TabOrder = 6
      end
      object chkInJD3: TCheckBox
        Left = 130
        Top = 96
        Width = 74
        Height = 20
        Caption = 'JD 侦测'
        TabOrder = 7
      end
    end
    object grpTest: TGroupBox
      Left = 464
      Top = 40
      Width = 280
      Height = 190
      Caption = '功能测试项（可单独启用/禁用）'
      TabOrder = 2
      object chkTest0: TCheckBox
        Left = 16
        Top = 24
        Width = 250
        Height = 20
        Caption = 'JD PORT TEST (接口存在侦测)'
        TabOrder = 0
      end
      object chkTest1: TCheckBox
        Left = 16
        Top = 48
        Width = 250
        Height = 20
        Caption = 'LOOPBACK TEST (回路)'
        TabOrder = 1
      end
      object chkTest2: TCheckBox
        Left = 16
        Top = 72
        Width = 250
        Height = 20
        Caption = 'L/R CHANNEL TEST (左右声道)'
        TabOrder = 2
      end
      object chkTest3: TCheckBox
        Left = 16
        Top = 96
        Width = 250
        Height = 20
        Caption = 'MUTE TEST (静音)'
        TabOrder = 3
      end
      object chkTest4: TCheckBox
        Left = 16
        Top = 120
        Width = 250
        Height = 20
        Caption = 'THD+N TEST (失真+噪声)'
        TabOrder = 4
      end
      object chkThdnCheck: TCheckBox
        Left = 16
        Top = 148
        Width = 250
        Height = 20
        Caption = 'THD+N CHECK (勾选后 THD+N 参与判定)'
        TabOrder = 5
      end
    end
    object grpValue: TGroupBox
      Left = 16
      Top = 240
      Width = 728
      Height = 80
      Caption = '接口数值设置（每一项可单独设置）'
      TabOrder = 3
      object lblPeriod: TLabel
        Left = 24
        Top = 32
        Width = 160
        Height = 18
        Caption = 'PeriodPoint (0-10)'
      end
      object edtPeriod: TEdit
        Left = 24
        Top = 28
        Width = 56
        Height = 24
        Text = '4'
        TabOrder = 0
      end
      object lblVolume: TLabel
        Left = 200
        Top = 32
        Width = 160
        Height = 18
        Caption = 'VolumeValue (0-87)'
      end
      object edtVolume: TEdit
        Left = 200
        Top = 28
        Width = 56
        Height = 24
        Text = '60'
        TabOrder = 1
      end
      object lblData: TLabel
        Left = 376
        Top = 32
        Width = 160
        Height = 18
        Caption = 'DataValue (0-32767)'
      end
      object edtData: TEdit
        Left = 376
        Top = 28
        Width = 64
        Height = 24
        Text = '16384'
        TabOrder = 2
      end
      object lblThdn: TLabel
        Left = 552
        Top = 32
        Width = 160
        Height = 18
        Caption = 'THD+N (0-80)'
      end
      object edtThdn: TEdit
        Left = 552
        Top = 28
        Width = 56
        Height = 24
        Text = '80'
        TabOrder = 3
      end
    end
    object grpEnv: TGroupBox
      Left = 16
      Top = 330
      Width = 728
      Height = 84
      Caption = '本机音频环境（探测结果）'
      TabOrder = 4
      object lblEnv: TLabel
        Left = 16
        Top = 24
        Width = 696
        Height = 52
        AutoSize = False
        Caption = '尚未探测'
        WordWrap = True
      end
    end
    object grpLog: TGroupBox
      Left = 16
      Top = 424
      Width = 728
      Height = 140
      Caption = '测试日志'
      TabOrder = 5
      object memoLog: TMemo
        Left = 12
        Top = 22
        Width = 704
        Height = 88
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
      end
      object progBar: TProgressBar
        Left = 12
        Top = 116
        Width = 704
        Height = 18
        Visible = False
        TabOrder = 1
      end
    end
    object grpBtn: TPanel
      Left = 16
      Top = 576
      Width = 728
      Height = 32
      BevelOuter = bvNone
      TabOrder = 6
      object lblHint: TLabel
        Left = 8
        Top = 8
        Width = 440
        Height = 20
        Caption = '接口勾选与数值由独立参数设置程序 AudioLoopParamSet.exe 设置'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
      end
      object btnProbe: TButton
        Left = 552
        Top = 2
        Width = 84
        Height = 28
        Caption = '探测环境'
        TabOrder = 0
      end
      object btnTest: TButton
        Left = 644
        Top = 2
        Width = 76
        Height = 28
        Caption = 'TEST 测试'
        TabOrder = 1
      end
      object btnClose: TButton
        Left = 470
        Top = 2
        Width = 74
        Height = 28
        Caption = '关闭'
        TabOrder = 2
      end
    end
  end
end
