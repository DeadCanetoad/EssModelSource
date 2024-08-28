object SettingsForm: TSettingsForm
  Left = 206
  Top = 110
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 188
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    306
    188)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 13
    Top = 83
    Width = 141
    Height = 13
    Caption = 'Save changed diagram layout'
  end
  object OkButton: TButton
    Left = 143
    Top = 156
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    TabOrder = 0
    OnClick = OkButtonClick
  end
  object ShellCheck: TCheckBox
    Left = 13
    Top = 16
    Width = 255
    Height = 17
    Caption = 'Shortcut on contextmenu for sourcefiles'
    TabOrder = 1
    OnClick = ShellCheckClick
  end
  object DelphiIDECheck: TCheckBox
    Left = 14
    Top = 41
    Width = 222
    Height = 17
    Caption = 'Shortcut on Tools menu in Delphi IDE'
    TabOrder = 2
    OnClick = DelphiIDECheckClick
  end
  object DiSaveCombo: TComboBox
    Left = 163
    Top = 81
    Width = 70
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 3
    Items.Strings = (
      'always'
      'ask'
      'never')
  end
  object Button2: TButton
    Left = 225
    Top = 156
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
