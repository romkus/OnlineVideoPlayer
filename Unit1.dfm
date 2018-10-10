object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 523
  ClientWidth = 944
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object SplitterChannels: TSplitter
    Left = 0
    Top = 180
    Width = 944
    Height = 4
    Cursor = crVSplit
    Align = alBottom
    Beveled = True
    ResizeStyle = rsUpdate
    ExplicitTop = 182
    ExplicitWidth = 526
  end
  object SplitterEvents: TSplitter
    Left = 0
    Top = 352
    Width = 944
    Height = 4
    Cursor = crVSplit
    Align = alBottom
    Beveled = True
    ResizeStyle = rsUpdate
    ExplicitTop = 353
    ExplicitWidth = 526
  end
  object PanelButtons: TPanel
    Left = 0
    Top = 480
    Width = 944
    Height = 43
    Align = alBottom
    TabOrder = 0
    ExplicitWidth = 752
    DesignSize = (
      944
      43)
    object Button1: TButton
      AlignWithMargins = True
      Left = 859
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1044#1086#1073#1072#1074#1080#1090#1100
      TabOrder = 0
      OnClick = Button1Click
      ExplicitLeft = 667
    end
    object Button2: TButton
      AlignWithMargins = True
      Left = 778
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1059#1076#1072#1083#1080#1090#1100
      TabOrder = 1
      OnClick = Button2Click
      ExplicitLeft = 586
    end
    object ButtonHideList: TButton
      Left = 3
      Top = 6
      Width = 113
      Height = 25
      Caption = #1047#1072#1093#1086#1074#1072#1090#1080' '#1089#1087#1080#1089#1086#1082
      TabOrder = 2
      WordWrap = True
      OnClick = ButtonHideListClick
    end
    object ButtonHideEventLog: TButton
      Left = 122
      Top = 6
      Width = 114
      Height = 25
      Caption = #1047#1072#1093#1086#1074#1072#1090#1080' '#1078#1091#1088#1085#1072#1083
      TabOrder = 3
      WordWrap = True
      OnClick = ButtonHideEventLogClick
    end
    object ButtonSaveGraph: TButton
      Left = 242
      Top = 6
      Width = 112
      Height = 25
      Hint = 
        #1047#1072#1087#1080#1089#1072#1090#1080' '#1075#1088#1072#1092' '#1087#1077#1088#1077#1090#1074#1086#1088#1077#1085#1085#1103' '#1091' '#1092#1072#1081#1083' '#1076#1083#1103' '#1087#1077#1088#1077#1074#1110#1088#1082#1080' '#1091' GraphEdit '#1072#1073#1086' ' +
        'GraphStudio.'
      Caption = #1047#1072#1087#1080#1089#1072#1090#1080' '#1075#1088#1072#1092
      TabOrder = 4
      OnClick = ButtonSaveGraphClick
    end
  end
  object PanelEvents: TPanel
    Left = 0
    Top = 356
    Width = 944
    Height = 124
    Align = alBottom
    TabOrder = 1
    ExplicitWidth = 752
    object MemoEvents: TMemo
      Left = 1
      Top = 1
      Width = 915
      Height = 122
      Align = alClient
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      Lines.Strings = (
        'MemoEvents')
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      ExplicitWidth = 723
    end
    object ButtonClearLog: TButton
      Left = 916
      Top = 1
      Width = 27
      Height = 122
      Align = alRight
      Caption = 'X'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = ButtonClearLogClick
      ExplicitLeft = 724
    end
  end
  object PanelChannels: TPanel
    Left = 0
    Top = 184
    Width = 944
    Height = 168
    Align = alBottom
    TabOrder = 2
    ExplicitWidth = 752
    object ValueListEditor1: TValueListEditor
      AlignWithMargins = True
      Left = 4
      Top = 73
      Width = 936
      Height = 91
      Align = alClient
      Ctl3D = True
      KeyOptions = [keyEdit, keyAdd, keyDelete]
      Options = [goFixedVertLine, goVertLine, goHorzLine, goColSizing, goRowSelect, goThumbTracking]
      ParentCtl3D = False
      Strings.Strings = (
        '')
      TabOrder = 0
      TitleCaptions.Strings = (
        #1053#1072#1079#1074#1072#1085#1080#1077' '#1082#1072#1085#1072#1083#1072
        'URL '#1072#1076#1088#1077#1089' '#1082#1072#1085#1072#1083#1072)
      OnDblClick = ValueListEditor1DblClick
      ExplicitLeft = 69
      ExplicitTop = 43
      ExplicitWidth = 871
      ExplicitHeight = 121
      ColWidths = (
        178
        752)
    end
    object PanelControl: TPanel
      Left = 1
      Top = 1
      Width = 942
      Height = 33
      Align = alTop
      TabOrder = 1
      object ButtonPlayChannel: TSpeedButton
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 93
        Height = 25
        Align = alLeft
        AllowAllUp = True
        GroupIndex = 1
        Caption = #1042#1110#1076#1090#1074#1086#1088#1077#1085#1085#1103
        OnClick = ButtonPlayChannelClick
        ExplicitTop = 5
        ExplicitHeight = 31
      end
      object ButtonPause: TSpeedButton
        AlignWithMargins = True
        Left = 103
        Top = 4
        Width = 85
        Height = 25
        Align = alLeft
        AllowAllUp = True
        GroupIndex = 1
        Caption = #1055#1072#1091#1079#1072
        OnClick = ButtonPauseClick
        ExplicitTop = 5
        ExplicitHeight = 31
      end
      object ButtonStop: TSpeedButton
        AlignWithMargins = True
        Left = 194
        Top = 4
        Width = 85
        Height = 25
        Align = alLeft
        AllowAllUp = True
        GroupIndex = 1
        Down = True
        Caption = #1057#1090#1086#1087
        Enabled = False
        OnClick = ButtonStopClick
        ExplicitLeft = 215
        ExplicitTop = 5
        ExplicitHeight = 31
      end
      object LabelState: TLabel
        Left = 282
        Top = 1
        Width = 34
        Height = 31
        Align = alLeft
        Caption = 'State'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBackground
        Font.Height = -15
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ExplicitHeight = 18
      end
      object CheckBoxAudioOn: TCheckBox
        Left = 316
        Top = 1
        Width = 68
        Height = 31
        Align = alLeft
        Caption = #1047#1074#1091#1082
        TabOrder = 1
        ExplicitLeft = 336
        ExplicitTop = 19
        ExplicitHeight = 17
      end
      object CheckBoxVideoOn: TCheckBox
        Left = 384
        Top = 1
        Width = 68
        Height = 31
        Align = alLeft
        Caption = #1042#1110#1076#1077#1086
        TabOrder = 0
        ExplicitLeft = 336
        ExplicitHeight = 17
      end
      object CheckBoxPhotoOn: TCheckBox
        Left = 452
        Top = 1
        Width = 65
        Height = 31
        Align = alLeft
        Caption = #1050#1072#1076#1088#1080
        TabOrder = 2
        ExplicitLeft = 455
        ExplicitTop = 5
        ExplicitHeight = 37
      end
    end
    object PanelControl2: TPanel
      Left = 1
      Top = 34
      Width = 942
      Height = 36
      Align = alTop
      TabOrder = 2
      object LabelSampleCount: TLabel
        Left = 198
        Top = 1
        Width = 51
        Height = 34
        Align = alLeft
        Caption = #1082#1072#1076#1088#1110#1074'. '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ExplicitLeft = 544
        ExplicitHeight = 18
      end
      object LabelJpegQuality: TLabel
        Left = 249
        Top = 1
        Width = 81
        Height = 34
        Hint = #1071#1082#1110#1089#1090#1100' '#1089#1090#1080#1089#1082#1072#1085#1085#1103' '#1079#1072#1093#1086#1087#1083#1077#1085#1080#1093' '#1082#1072#1076#1088#1110#1074' '#1091' '#1092#1072#1081#1083#1080' Jpeg ('#1091' '#1087#1072#1087#1094#1110' Jpeg)'
        Align = alLeft
        Caption = #1071#1082#1110#1089#1090#1100' Jpeg:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        ExplicitLeft = 704
        ExplicitHeight = 18
      end
      object ButtonGetImage: TButton
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 82
        Height = 28
        Align = alLeft
        Caption = #1047#1072#1093#1086#1087#1080#1090#1080
        Enabled = False
        TabOrder = 0
        WordWrap = True
        OnClick = ButtonGetImageClick
        ExplicitLeft = 680
        ExplicitTop = 5
        ExplicitHeight = 31
      end
      object EditSampleCount: TEdit
        Left = 89
        Top = 1
        Width = 109
        Height = 34
        Align = alLeft
        Alignment = taCenter
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = 'EditSampleCount'
        ExplicitLeft = 404
        ExplicitHeight = 37
      end
      object EditJpegQuality: TEdit
        Left = 330
        Top = 1
        Width = 68
        Height = 34
        Align = alLeft
        Alignment = taCenter
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        Text = 'EditJpegQuality'
        ExplicitLeft = 896
        ExplicitTop = -1
        ExplicitHeight = 37
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 944
    Height = 180
    Align = alClient
    FullRepaint = False
    ParentBackground = False
    ParentShowHint = False
    ShowHint = False
    TabOrder = 3
    OnResize = Panel1Resize
    ExplicitWidth = 752
  end
  object SaveDialogForGraph: TSaveDialog
    DefaultExt = 'grf'
    Filter = #1060#1072#1081#1083#1080' '#1075#1088#1072#1092#1110#1074' DirectShow|*.grf'
    Title = #1053#1072#1079#1074#1110#1090#1100' '#1092#1072#1081#1083' '#1076#1083#1103' '#1079#1072#1087#1080#1089#1091' '#1075#1088#1072#1092#1072' '#1087#1077#1088#1077#1090#1074#1086#1088#1077#1085#1085#1103
    Left = 32
    Top = 16
  end
end
