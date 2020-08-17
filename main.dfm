object AFMmain: TAFMmain
  Left = 0
  Top = 0
  Caption = 'AFM ItsyBitsy'
  ClientHeight = 972
  ClientWidth = 1161
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 331
    Width = 1161
    Height = 3
    Cursor = crVSplit
    Align = alTop
    ExplicitTop = 307
    ExplicitWidth = 646
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 953
    Width = 1161
    Height = 19
    Panels = <
      item
        Width = 150
      end
      item
        Width = 150
      end>
    ExplicitTop = 921
    ExplicitWidth = 1142
  end
  object pnlHGraph: TPanel
    Left = 0
    Top = 145
    Width = 1161
    Height = 186
    Align = alTop
    BevelOuter = bvLowered
    Caption = 'pnlHGraph'
    TabOrder = 1
    ExplicitTop = 135
    ExplicitWidth = 1142
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1161
    Height = 145
    Align = alTop
    TabOrder = 2
    object Label2: TLabel
      Left = 297
      Top = 9
      Width = 82
      Height = 13
      Caption = 'Monitoring speed'
    end
    object Label3: TLabel
      Left = 297
      Top = 52
      Width = 55
      Height = 13
      Caption = 'Scan speed'
    end
    object GroupBox2: TGroupBox
      Left = 171
      Top = 9
      Width = 120
      Height = 88
      TabOrder = 0
      object btnMonitoring: TSpeedButton
        Left = 6
        Top = 14
        Width = 109
        Height = 22
        AllowAllUp = True
        GroupIndex = 1
        Caption = 'Monitor'
        OnClick = btnMonitoringClick
      end
      object btnScan: TSpeedButton
        Left = 6
        Top = 38
        Width = 109
        Height = 22
        AllowAllUp = True
        GroupIndex = 1
        Caption = 'Scan'
        OnClick = btnScanClick
      end
      object btnStop: TSpeedButton
        Left = 6
        Top = 62
        Width = 109
        Height = 22
        AllowAllUp = True
        GroupIndex = 1
        Down = True
        Caption = 'Stop'
        OnClick = btnStopClick
      end
    end
    object GroupBox1: TGroupBox
      Left = 11
      Top = 9
      Width = 154
      Height = 72
      Caption = 'AFM controller'
      TabOrder = 1
      object Label1: TLabel
        Left = 7
        Top = 20
        Width = 48
        Height = 16
        Caption = 'Status:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblStatusConnection: TLabel
        Left = 59
        Top = 20
        Width = 87
        Height = 16
        Caption = 'Disconnected'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnConnect: TButton
        Left = 7
        Top = 42
        Width = 114
        Height = 25
        Caption = 'Connect'
        TabOrder = 0
        OnClick = btnConnectClick
      end
    end
    object trbMonInterval: TTrackBar
      Left = 297
      Top = 23
      Width = 264
      Height = 32
      Max = 200
      Frequency = 25
      Position = 100
      ShowSelRange = False
      TabOrder = 2
    end
    object trbScanInterval: TTrackBar
      Left = 297
      Top = 71
      Width = 264
      Height = 32
      Max = 200
      Frequency = 25
      Position = 100
      ShowSelRange = False
      TabOrder = 3
    end
    object lboxLog: TListBox
      Left = 659
      Top = 9
      Width = 337
      Height = 105
      ItemHeight = 13
      TabOrder = 4
    end
    object edtCmd: TEdit
      Left = 19
      Top = 88
      Width = 146
      Height = 21
      TabOrder = 5
      Text = 'LOG IN'
      OnKeyDown = edtCmdKeyDown
    end
    object rgMapX: TRadioGroup
      Left = 562
      Top = 9
      Width = 90
      Height = 105
      Caption = 'rgMapX'
      ItemIndex = 0
      Items.Strings = (
        '256'
        '512'
        '1024'
        '2048'
        '4096'
        '32')
      TabOrder = 6
    end
    object rangeContrast: TsRangeSelector
      Left = 297
      Top = 103
      Width = 264
      Height = 41
      TabOrder = 7
      OnChange = rangeContrastChange
      Max = 511
      Position2 = 511
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 334
    Width = 1161
    Height = 619
    Align = alClient
    Caption = 'Panel1'
    TabOrder = 3
    ExplicitLeft = 8
    ExplicitTop = 337
    ExplicitWidth = 1134
    ExplicitHeight = 603
    DesignSize = (
      1161
      619)
    object pnlLeft: TPanel
      Left = 1
      Top = 1
      Width = 208
      Height = 617
      Align = alLeft
      TabOrder = 0
      ExplicitLeft = 17
      ExplicitTop = 17
      ExplicitHeight = 601
    end
    object pnlMap: TPanel
      Left = 263
      Top = 3
      Width = 600
      Height = 608
      Anchors = [akLeft, akTop, akBottom]
      BevelOuter = bvLowered
      Caption = 'pnlMap'
      TabOrder = 1
      OnResize = pnlMapResize
      ExplicitHeight = 632
    end
  end
  object Timer1: TTimer
    Interval = 25
    OnTimer = Timer1Timer
    Left = 24
    Top = 144
  end
  object Timer250: TTimer
    Interval = 250
    OnTimer = Timer250Timer
    Left = 56
    Top = 144
  end
end
