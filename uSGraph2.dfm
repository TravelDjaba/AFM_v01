object SGraph2: TSGraph2
  Left = 0
  Top = 0
  Caption = 'SGraph2'
  ClientHeight = 520
  ClientWidth = 1026
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 40
    Height = 472
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'Panel1'
    TabOrder = 0
    object imgAxisY: TImage32
      Left = 0
      Top = 0
      Width = 40
      Height = 472
      Align = alClient
      Bitmap.ResamplerClassName = 'TNearestResampler'
      BitmapAlign = baTopLeft
      Scale = 1.000000000000000000
      ScaleMode = smNormal
      TabOrder = 0
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 472
    Width = 1026
    Height = 26
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'Panel2'
    TabOrder = 1
    object imgAxisX: TImage32
      Left = 0
      Top = 0
      Width = 1026
      Height = 26
      Align = alClient
      Bitmap.ResamplerClassName = 'TNearestResampler'
      BitmapAlign = baTopLeft
      Scale = 1.000000000000000000
      ScaleMode = smNormal
      TabOrder = 0
    end
  end
  object Panel4: TPanel
    Left = 40
    Top = 0
    Width = 986
    Height = 472
    Align = alClient
    BevelOuter = bvNone
    Caption = 'Panel4'
    TabOrder = 2
    object img: TImage32
      Left = 0
      Top = 0
      Width = 986
      Height = 472
      Align = alClient
      Bitmap.ResamplerClassName = 'TNearestResampler'
      BitmapAlign = baTopLeft
      Scale = 1.000000000000000000
      ScaleMode = smNormal
      TabOrder = 0
      OnMouseDown = imgMouseDown
      OnMouseMove = imgMouseMove
      OnMouseUp = imgMouseUp
      OnMouseWheel = imgMouseWheel
      OnResize = imgResize
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 498
    Width = 1026
    Height = 22
    Panels = <
      item
        Width = 150
      end
      item
        Width = 150
      end>
  end
end
