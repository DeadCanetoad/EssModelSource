{
  ESS-Model
  Copyright (C) 2002  Eldean AB, Peter S�derman, Ville Krumlinde

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

unit uRtfdComponents;

interface
{$ifdef WIN32}
uses Windows, Messages, ExtCtrls, Classes, uModel, uModelEntity, StdCtrls, Controls, uListeners,
  uViewIntegrator, Contnrs, uDiagramFrame;
{$endif}
{$ifdef LINUX}
uses QTypes, QExtCtrls, Classes, uModel, uModelEntity, QStdCtrls, QControls, uListeners,
  uViewIntegrator, Contnrs, uDiagramFrame;
{$endif}

type

  //Baseclass for a diagram-panel
  TRtfdBoxClass = class of TRtfdBox;
  TRtfdBox = class(TPanel, IModelEntityListener)
  private
    FMinVisibility : TVisibility;
    procedure SetMinVisibility(const Value: TVisibility);
    procedure OnChildMouseDown(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
  protected
    procedure Notification(AComponent: TComponent; Operation: Classes.TOperation); override;
  public
    Frame: TDiagramFrame;
    Entity: TModelEntity;
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity; Frame: TDiagramFrame; MinVisibility : TVisibility); reintroduce; virtual;
    procedure RefreshEntities; virtual; abstract;
    procedure Paint; override;
    procedure Change(Sender: TModelEntity); virtual;
    procedure AddChild(Sender: TModelEntity; NewChild: TModelEntity); virtual;
    procedure Remove(Sender: TModelEntity); virtual;
    procedure EntityChange(Sender: TModelEntity); virtual;
    property MinVisibility : TVisibility write SetMinVisibility;
  end;

  TRtfdClass = class(TRtfdBox, IAfterClassListener)
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity; Frame: TDiagramFrame; MinVisibility : TVisibility); override;
    destructor Destroy; override;
    procedure RefreshEntities; override;
    procedure AddChild(Sender: TModelEntity; NewChild: TModelEntity); override;
  end;

  TRtfdInterface = class(TRtfdBox, IAfterInterfaceListener)
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity; Frame: TDiagramFrame; MinVisibility : TVisibility); override;
    destructor Destroy; override;
    procedure RefreshEntities; override;
    procedure AddChild(Sender: TModelEntity; NewChild: TModelEntity); override;
  end;

  TRtfdUnitPackage = class(TRtfdBox)
  public
    P: TUnitPackage;
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity; Frame: TDiagramFrame; MinVisibility : TVisibility); override;
    procedure RefreshEntities; override;
    procedure DblClick; override;
  end;

//  TRtfdCustomLabel = class(TCustomLabel, IModelEntityListener)
  TRtfdCustomLabel = class(TGraphicControl, IModelEntityListener)
  private
    FCaption: TCaption;
    FAlignment: TAlignment;
    FTransparent: Boolean;
    Entity: TModelEntity;
    function GetAlignment: TAlignment;
    procedure SetAlignment(const Value: TAlignment);
    procedure SetTransparent(const Value: Boolean);
{$ifdef WIN32}
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure AdjustBounds;
    procedure DoDrawText(var Rect: TRect; Flags: Integer);
{$endif}
  protected
    procedure Paint; override;
{$ifdef LINUX}
    procedure SetText(const Value: TCaption); override;
    function GetText: TCaption; override;
{$endif}
{$ifdef WIN32}
    procedure SetText(const Value: TCaption);
    function GetText: TCaption;
{$endif}
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity); reintroduce; virtual;
    procedure Change(Sender: TModelEntity); virtual;
    procedure AddChild(Sender: TModelEntity; NewChild: TModelEntity); virtual;
    procedure Remove(Sender: TModelEntity); virtual;
    procedure EntityChange(Sender: TModelEntity); virtual;
    function WidthNeeded : integer; virtual;
    property Alignment: TAlignment read GetAlignment write SetAlignment default taLeftJustify;
    property Transparent: Boolean read FTransparent write SetTransparent;
  end;

  TRtfdClassName = class(TRtfdCustomLabel, IAfterClassListener)
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity); override;
    destructor Destroy; override;
    procedure EntityChange(Sender: TModelEntity); override;
  end;

  TRtfdInterfaceName = class(TRtfdCustomLabel, IAfterInterfaceListener)
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity); override;
    destructor Destroy; override;
    procedure EntityChange(Sender: TModelEntity); override;
  end;

  //Left-justified label with visibility-icon
  TVisibilityLabel = class(TRtfdCustomLabel)
    procedure Paint; override;
    function WidthNeeded : integer; override;
  end;

  TRtfdOperation = class(TVisibilityLabel, IAfterOperationListener)
  private
    O: TOperation;
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity); override;
    destructor Destroy; override;
    procedure EntityChange(Sender: TModelEntity); override;
    procedure IAfterOperationListener.EntityChange = EntityChange;
  end;

  TRtfdAttribute = class(TVisibilityLabel, IAfterAttributeListener)
  private
    A: TAttribute;
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity); override;
    destructor Destroy; override;
    procedure EntityChange(Sender: TModelEntity); override;
    procedure IAfterAttributeListener.EntityChange = EntityChange;
  end;

  TRtfdSeparator = class(TGraphicControl)
  public
    constructor Create(Owner: TComponent); override;
    procedure Paint; override;
  end;

  TRtfdStereotype = class(TRtfdCustomLabel)
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity; Caption: string); reintroduce;
  end;

  TRtfdUnitPackageName = class(TRtfdCustomLabel, IAfterUnitPackageListener)
  private
    P: TUnitPackage;
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity); override;
    destructor Destroy; override;
    procedure EntityChange(Sender: TModelEntity); override;
    procedure IAfterUnitPackageListener.EntityChange = EntityChange;
  end;

  //Class to display mame of package at upper-left corner in a unitpackage diagram
  TRtfdUnitPackageDiagram = class(TRtfdCustomLabel, IAfterUnitPackageListener)
  private
    P: TUnitPackage;
  public
    constructor Create(Owner: TComponent; Entity: TModelEntity); override;
    destructor Destroy; override;
    procedure EntityChange(Sender: TModelEntity); override;
    procedure IAfterUnitPackageListener.EntityChange = EntityChange;
  end;

implementation

{$ifdef WIN32}
uses Graphics, uError, SysUtils, essConnectPanel, uIterators,
uConfig, uRtfdDiagramFrame, Math;
{$endif}

{$ifdef LINUX}
uses Types, QGraphics, uError, SysUtils, essConnectPanel, uIterators,
 uConfig, uRtfdDiagramFrame, Math, QForms, Qt;
{$endif}

const
  ClassShadowWidth = 3;
  cDefaultWidth = 185;
  cDefaultHeight = 41;

{ TRtfdBox }
constructor TRtfdBox.Create(Owner: TComponent; Entity: TModelEntity; Frame: TDiagramFrame; MinVisibility : TVisibility);
begin
  inherited Create(Owner);
  {$ifdef LINUX}
  QWidget_Setbackgroundmode(Handle,QWidgetBackgroundMode_NoBackground);
  {$endif}
  Color := clWhite;
  BorderWidth := ClassShadowWidth;
  Self.Frame := Frame;
  Self.Entity := Entity;
  Self.FMinVisibility := MinVisibility;
  ShowHint := True;
  Hint := Entity.Documentation.ShortDescription;
end;

procedure TRtfdBox.Paint;
const
  TopH = 39;
  TopColor : array[boolean] of TColor = ($EAF4F8, clWhite);
var
  R: TRect;
  Sw: integer;
begin
  Sw := ClassShadowWidth;
  R := GetClientRect;
  with Canvas do
  begin
    //Shadow
    Brush.Color := clSilver;
    Pen.Color := clSilver;
    RoundRect(R.Right - Sw - 8, R.Top + Sw, R.Right, R.Bottom, 8, 8);
    FillRect(Rect(Sw, R.Bottom - Sw, R.Right, R.Bottom));

    //Holes
    Brush.Color := (Parent as TessConnectPanel).Color;
    FillRect(Rect(R.Left, R.Bottom - Sw, R.Left + Sw, R.Bottom));
    FillRect(Rect(R.Right - Sw, R.Top, R.Right, R.Top + Sw));

    //Background
    Brush.Color := clWhite;
    Pen.Color := clBlack;

    Brush.Color := TopColor[ Config.IsLimitedColors ];
    RoundRect(R.Left, R.Top, R.Right - Sw, R.Top + TopH, 8, 8);
    Brush.Color := clWhite;
    Rectangle(R.Left, R.Top + TopH - 8, R.Right - Sw, R.Bottom - Sw);
    FillRect( Rect(R.Left+1,R.Top + TopH - 8, R.Right - Sw - 1, R.Top + TopH + 1 - 8) );
  end;
end;

procedure TRtfdBox.AddChild(Sender, NewChild: TModelEntity);
begin
  //Stub
end;

procedure TRtfdBox.Change(Sender: TModelEntity);
begin
  //Stub
end;

procedure TRtfdBox.EntityChange(Sender: TModelEntity);
begin
  //Stub
end;

procedure TRtfdBox.Remove(Sender: TModelEntity);
begin
  //Stub
end;


procedure TRtfdBox.SetMinVisibility(const Value: TVisibility);
begin
  if Value<>FMinVisibility then
  begin
    FMinVisibility := Value;
    RefreshEntities;
  end;
end;


//F�ljande deklarationer beh�vs f�r att hj�lpa till essconnectpanel att
//f�nga alla musactions. Alla controls som infogas (klassnamn etc) i
//rtfdbox f�r sina mousedown omdefinierade.
type
  TCrackControl = class(TControl);

procedure TRtfdBox.Notification(AComponent: TComponent; Operation: Classes.TOperation);
begin
  inherited;
  //Owner=Self m�ste testas eftersom notifikationer skickas f�r alla komponenter i
  //hela formul�ret, �ven ovanf�r denna. TRtfdLabels skapas med owner=box.
  if (Operation = opInsert) and (Acomponent.Owner = Self) and (Acomponent is TControl) then
    TCrackControl(AComponent).OnMouseDown := OnChildMouseDown;
end;

procedure TRtfdBox.OnChildMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  pt: TPoint;
begin
  pt.X := X;
  pt.Y := Y;
  pt := TControl(Sender).ClientToScreen(pt);
  pt := ScreenToClient(pt);
  MouseDown(Button,Shift,pt.X,pt.Y);
end;



{ TRtfdClass }

constructor TRtfdClass.Create(Owner: TComponent; Entity: TModelEntity; Frame: TDiagramFrame; MinVisibility : TVisibility);
begin
  inherited Create(Owner, Entity, Frame, MinVisibility);
  PopupMenu := Frame.ClassInterfacePopupMenu;
  Entity.AddListener(IAfterClassListener(Self));
  RefreshEntities;
end;

destructor TRtfdClass.Destroy;
begin
  Entity.RemoveListener(IAfterClassListener(Self));
  inherited;
end;

procedure TRtfdClass.AddChild(Sender: TModelEntity; NewChild: TModelEntity);
begin
  RefreshEntities;
end;

procedure TRtfdClass.RefreshEntities;
var
  NeedH,NeedW,I : integer;
  C: TClass;
  Omi,Ami : IModelIterator;
  WasVisible : boolean;
begin
  C := Entity as TClass;

  WasVisible := Visible;
  Hide;
  DestroyComponents;

  NeedW := 0;
  NeedH := (ClassShadowWidth * 2) + 4;
  Inc(NeedH, TRtfdClassName.Create(Self, Entity).Height);

  //Sortera i visibility order
  if FMinVisibility > Low(TVisibility) then
  begin
    Omi := TModelIterator.Create(C.GetOperations,TOperation,FMinVisibility,ioVisibility);
    Ami := TModelIterator.Create(C.GetAttributes,TAttribute,FMinVisibility,ioVisibility);
  end
  else
  begin
    Omi := TModelIterator.Create(C.GetOperations,ioVisibility);
    Ami := TModelIterator.Create(C.GetAttributes,ioVisibility);
  end;

  //Separator
  if (Ami.Count>0) or (Omi.Count>0) then
    Inc(NeedH, TRtfdSeparator.Create(Self).Height);

  //Attributes
  while Ami.HasNext do
    Inc(NeedH, TRtfdAttribute.Create(Self,Ami.Next).Height);

  //Separator
  if (Ami.Count>0) and (Omi.Count>0) then
    Inc(NeedH, TRtfdSeparator.Create(Self).Height);

  //Operations
  while Omi.HasNext do
    Inc(NeedH, TRtfdOperation.Create(Self,Omi.Next).Height);

  for I := 0 to ControlCount-1 do
    if Controls[I] is TRtfdCustomLabel then
      NeedW := Max( TRtfdCustomLabel(Controls[I]).WidthNeeded,NeedW);

  Height :=  Max(NeedH,cDefaultHeight);
  Width  :=  Max(NeedW,cDefaultWidth);

  Visible := WasVisible;
end;

{ TRtfdUnitPackage }

constructor TRtfdUnitPackage.Create(Owner: TComponent; Entity: TModelEntity; Frame: TDiagramFrame; MinVisibility : TVisibility);
begin
  inherited Create(Owner, Entity, Frame, MinVisibility);
  PopupMenu := Frame.PackagePopupMenu;
  P := Entity as TUnitPackage;
  RefreshEntities;
end;

procedure TRtfdUnitPackage.DblClick;
{$ifdef LINUX}
var
  Msg: QCustomEventH;
{$endif}
begin
{$ifdef WIN32}
  PostMessage(Frame.Handle, WM_ChangePackage, 0, 0);
{$endif}
{$ifdef LINUX}
  //QApplication_processEvents(Application.Handle);
  Msg := QCustomEvent_create(WM_ChangePackage);
  QApplication_postEvent(Frame.Handle,Msg);
  { TODO : Fix for Linux }
{$endif}
end;

procedure TRtfdUnitPackage.RefreshEntities;
begin
  DestroyComponents;
  TRtfdUnitPackageName.Create(Self, P);
  Height := 45;
end;

{ TRtfdCustomLabel }

constructor TRtfdCustomLabel.Create(Owner: TComponent;
  Entity: TModelEntity);
begin
  inherited Create(Owner);
  Parent := Owner as TWinControl;
  Self.Entity := Entity;
  Align := alTop;
  Height := Abs(Font.Height);
  FAlignment := taLeftJustify;
  FTransparent := True;
  //Top m�ste s�ttas s� att alla labels l�gger sig under varandra n�r align=top
  Top := MaxInt;
end;

procedure TRtfdCustomLabel.EntityChange(Sender: TModelEntity);
begin
  //Stub
end;

procedure TRtfdCustomLabel.Remove(Sender: TModelEntity);
begin
  //Stub
end;

procedure TRtfdCustomLabel.AddChild(Sender, NewChild: TModelEntity);
begin
  //Stub
end;

procedure TRtfdCustomLabel.Change(Sender: TModelEntity);
begin
  //Stub
end;

function TRtfdCustomLabel.WidthNeeded: integer;
begin
  Result := Width + 4 + (2 * ClassShadowWidth);
end;


{ TVisibilityLabel }

const
  IconW = 10;

procedure TVisibilityLabel.Paint;
var
  Rect : TRect;
{$ifdef WIN32}
  Pic : Graphics.TBitmap;
{$endif}
{$ifdef LINUX}
  Pic : QGraphics.TBitmap;
{$endif}
begin
{ifdef WIN32}
  Rect := ClientRect;

  case Entity.Visibility of
    viPrivate : Pic := ((Parent as TRtfdBox).Frame as TRtfdDiagramFrame).VisPrivateImage.Picture.Bitmap;
    viProtected : Pic := ((Parent as TRtfdBox).Frame as TRtfdDiagramFrame).VisProtectedImage.Picture.Bitmap;
    viPublic : Pic := ((Parent as TRtfdBox).Frame as TRtfdDiagramFrame).VisPublicImage.Picture.Bitmap;
  else
    Pic := ((Parent as TRtfdBox).Frame as TRtfdDiagramFrame).VisPublicImage.Picture.Bitmap;
  end;
  Canvas.Draw(Rect.Left,Rect.Top + 1, Pic );

  Canvas.Font := Font;
  Canvas.TextOut(Rect.Left + IconW + 4, Rect.Top, Caption);
{endif}
end;


function TVisibilityLabel.WidthNeeded: integer;
begin
  Result := Width + IconW;
end;

{ TRtfdClassName }

constructor TRtfdClassName.Create(Owner: TComponent; Entity: TModelEntity);
begin
  inherited Create(Owner, Entity);
  Font.Style := [fsBold];
  Alignment := taCenter;
  Entity.AddListener(IAfterClassListener(Self));
  EntityChange(nil);
end;

destructor TRtfdClassName.Destroy;
begin
  Entity.RemoveListener(IAfterClassListener(Self));
  inherited;
end;

procedure TRtfdClassName.EntityChange(Sender: TModelEntity);
begin
  if ((Owner as TRtfdBox).Frame as TDiagramFrame).Diagram.Package<>Entity.Owner then
    Caption := Entity.FullName
  else
    Caption := Entity.Name;
end;


{ TRtfdInterfaceName }

constructor TRtfdInterfaceName.Create(Owner: TComponent;
  Entity: TModelEntity);
begin
  inherited Create(Owner, Entity);
  Font.Style := [fsBold];
  Alignment := taCenter;
  Entity.AddListener(IAfterInterfaceListener(Self));
  EntityChange(nil);
end;

destructor TRtfdInterfaceName.Destroy;
begin
  Entity.RemoveListener(IAfterInterfaceListener(Self));
  inherited;
end;

procedure TRtfdInterfaceName.EntityChange(Sender: TModelEntity);
begin
  if ((Owner as TRtfdBox).Frame as TDiagramFrame).Diagram.Package<>Entity.Owner then
    Caption := Entity.FullName
  else
    Caption := Entity.Name;
end;


{ TRtfdSeparator }

constructor TRtfdSeparator.Create(Owner: TComponent);
begin
  //Cannot inherit from TCustomLabel in Kylix because it does not have a paint-method
  inherited Create(Owner);
  Parent := Owner as TWinControl;
  {$ifdef WIN32}
  AutoSize := False;
  {$endif}
  {$ifdef LINUX}
  { TODO : Fix for Linux }
  {$endif}
  Height := 16;
  //Top must be assigned so that all labels appears beneath each other when align=top
  Top := MaxInt;
  Align := alTop;
end;

procedure TRtfdSeparator.Paint;
var
  R: TRect;
begin
  R := ClientRect;
  //Canvas.FillRect(R);
  Canvas.Pen.Color := clBlack;
  Canvas.MoveTo(R.Left, R.Top + (Height div 2));
  Canvas.LineTo(R.Right, R.Top + (Height div 2));
end;

{ TRtfdPackageName }

constructor TRtfdUnitPackageName.Create(Owner: TComponent;
  Entity: TModelEntity);
begin
  inherited Create(Owner, Entity);
  Font.Style := [fsBold];
  Alignment := taCenter;
  P := Entity as TUnitPackage;
  P.AddListener(IAfterUnitPackageListener(Self));
  EntityChange(nil);
end;

destructor TRtfdUnitPackageName.Destroy;
begin
  P.RemoveListener(IAfterUnitPackageListener(Self));
  inherited;
end;

procedure TRtfdUnitPackageName.EntityChange(Sender: TModelEntity);
begin
  Caption := P.Name;
end;

{ TRtfdOperation }

constructor TRtfdOperation.Create(Owner: TComponent; Entity: TModelEntity);
begin
  inherited Create(Owner, Entity);
  O := Entity as TOperation;
  O.AddListener(IAfterOperationListener(Self));
  EntityChange(nil);
end;

destructor TRtfdOperation.Destroy;
begin
  O.RemoveListener(IAfterOperationListener(Self));
  inherited;
end;

procedure TRtfdOperation.EntityChange(Sender: TModelEntity);
const
  ColorMap: array[TOperationType] of TColor = (clGreen, clRed, clBlack, clGray);
  //   otConstructor,otDestructor,otProcedure,otFunction);
begin
  //Default uml-syntax
  //visibility name ( parameter-list ) : return-type-expression { property-string }
  { TODO : show parameters and returntype for operation }
  Caption := O.Name + '(...)';
  Font.Style := [];
  Font.Color := ColorMap[O.OperationType];
  if O.IsAbstract then
    Font.Style := [fsItalic];
end;

{ TRtfdAttribute }

constructor TRtfdAttribute.Create(Owner: TComponent; Entity: TModelEntity);
begin
  inherited Create(Owner, Entity);
  A := Entity as TAttribute;
  A.AddListener(IAfterAttributeListener(Self));
  EntityChange(nil);
end;

destructor TRtfdAttribute.Destroy;
begin
  A.RemoveListener(IAfterAttributeListener(Self));
  inherited;
end;

procedure TRtfdAttribute.EntityChange(Sender: TModelEntity);
begin
  //uml standard syntax is:
  //visibility name [ multiplicity ] : type-expression = initial-value { property-string }
  if Assigned(A.TypeClassifier) then
    Caption := A.Name + ' : ' + A.TypeClassifier.Name
  else
    Caption := A.Name;
end;

{ TRtfdUnitPackageDiagram }

constructor TRtfdUnitPackageDiagram.Create(Owner: TComponent;
  Entity: TModelEntity);
begin
  //This class is the caption in upper left corner for a unitdiagram
  inherited Create(Owner, Entity);
  Color := clBtnFace;
  Font.Name := 'Times New Roman';
  Font.Style := [fsBold];
  Font.Size := 12;
  Alignment := taLeftJustify;
  P := Entity as TUnitPackage;
  P.AddListener(IAfterUnitPackageListener(Self));
  EntityChange(nil);
end;

destructor TRtfdUnitPackageDiagram.Destroy;
begin
  P.RemoveListener(IAfterUnitPackageListener(Self));
  inherited;
end;

procedure TRtfdUnitPackageDiagram.EntityChange(Sender: TModelEntity);
begin
  Caption := '   ' + P.FullName;
end;


{ TRtfdInterface }

constructor TRtfdInterface.Create(Owner: TComponent; Entity: TModelEntity;
  Frame: TDiagramFrame; MinVisibility : TVisibility);
begin
  inherited Create(Owner, Entity, Frame, MinVisibility);
  Entity.AddListener(IAfterInterfaceListener(Self));
  PopupMenu := Frame.ClassInterfacePopupMenu;
  RefreshEntities;
end;

destructor TRtfdInterface.Destroy;
begin
  Entity.RemoveListener(IAfterInterfaceListener(Self));
  inherited;
end;

procedure TRtfdInterface.RefreshEntities;
var
  NeedW,NeedH,I : integer;
  Mi : IModelIterator;
  WasVisible : boolean;
begin
  WasVisible := Visible;
  Hide;
  DestroyComponents;

  NeedW := 0;
  NeedH := (ClassShadowWidth * 2) + 4;

  Inc(NeedH, TRtfdStereotype.Create(Self, nil, 'interface').Height);
  Inc(NeedH, TRtfdInterfaceName.Create(Self, Entity).Height);

  //Get operations in visibility order
  if FMinVisibility > Low(TVisibility) then
    Mi := TModelIterator.Create((Entity as TInterface).GetOperations,TOperation,FMinVisibility,ioVisibility)
  else
    Mi := TModelIterator.Create((Entity as TInterface).GetOperations,ioVisibility);

  //Separator
  if Mi.HasNext then
    Inc(NeedH, TRtfdSeparator.Create(Self).Height);

  //Operations
  while Mi.HasNext do
    Inc(NeedH, TRtfdOperation.Create(Self,Mi.Next).Height);

  for I := 0 to ControlCount-1 do
    if Controls[I] is TRtfdCustomLabel then
      NeedW := Max( TRtfdCustomLabel(Controls[I]).WidthNeeded,NeedW);

  Height :=  Max(NeedH,cDefaultHeight);
  Width  :=  Max(NeedW,cDefaultWidth);

  Visible := WasVisible;
end;

procedure TRtfdInterface.AddChild(Sender, NewChild: TModelEntity);
begin
  RefreshEntities;
end;

{ TRtfdStereotype }

constructor TRtfdStereotype.Create(Owner: TComponent; Entity: TModelEntity; Caption: string);
begin
  inherited Create(Owner, Entity);
  Alignment := taCenter;
  Self.Caption := '<<' + Caption + '>>';
end;

function TRtfdCustomLabel.GetAlignment: TAlignment;
begin
  Result := FAlignment;
end;

procedure TRtfdCustomLabel.SetAlignment(const Value: TAlignment);
begin
  if Value <> FAlignment then
    begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TRtfdCustomLabel.Paint;
var
  Al: Integer;
  oldFont: TFont;
  r: TRect;
begin
  inherited;
  { TODO : Fix }
  oldFont := Canvas.Font;
  Canvas.Font := Font;
  if FTransparent then
    Canvas.Brush.Style := bsClear
  else
    Canvas.Brush.Style := bsSolid;
{$ifdef WIN32}
  Al := DT_LEFT;
  case FAlignment of
    taLeftJustify: Al := DT_LEFT;
    taRightJustify: Al := DT_RIGHT;
    taCenter: Al := DT_CENTER;
  end;
  r := ClientRect;
  DrawText(Canvas.Handle,PChar(Caption),Length(Caption),r,Al);
{$endif}
{$ifdef LINUX}
  case FAlignment of
    taLeftJustify: Al := Ord(AlignmentFlags_AlignLeft);
    taRightJustify: Al := Ord(AlignmentFlags_AlignRight);
    taCenter: Al := Ord(AlignmentFlags_AlignCenter);
  end;

  Canvas.TextRect(ClientRect,0,0,Caption,Ord(AlignmentFlags_AlignVCenter)+Al);
{$endif}
  Canvas.Font := oldFont;
end;

procedure TRtfdCustomLabel.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    Invalidate;
  end;
end;


function TRtfdCustomLabel.GetText: TCaption;
begin
  Result := FCaption;
end;

procedure TRtfdCustomLabel.SetText(const Value: TCaption);
begin
  inherited;
  if FCaption <> Value then
  begin
    FCaption := Value;
    Invalidate;
  end;
end;

{$ifdef WIN32}
procedure TRtfdCustomLabel.CMTextChanged(var Message: TMessage);
begin
  Invalidate;
  Adjustbounds;
end;

procedure TRtfdCustomLabel.AdjustBounds;
const
  WordWraps: array[Boolean] of Word = (0, DT_WORDBREAK);
var
  DC: HDC;
  X: Integer;
  Rect: TRect;
  AAlignment: TAlignment;
begin
  if not (csReading in ComponentState) then
  begin
    Rect := ClientRect;
    DC := GetDC(0);
    Canvas.Handle := DC;
    DoDrawText(Rect, (DT_EXPANDTABS or DT_CALCRECT));
    Canvas.Handle := 0;
    ReleaseDC(0, DC);
    X := Left;
    AAlignment := FAlignment;
    if UseRightToLeftAlignment then ChangeBiDiModeAlignment(AAlignment);
    if AAlignment = taRightJustify then Inc(X, Width - Rect.Right);
    SetBounds(X, Top, Rect.Right, Rect.Bottom);
  end;
end;

procedure TRtfdCustomLabel.DoDrawText(var Rect: TRect; Flags: Longint);
var
  Text: string;
begin
  Text := Caption;
  if (Flags and DT_CALCRECT <> 0) and ((Text = '') and
    (Text[1] = '&') and (Text[2] = #0)) then Text := Text + ' ';
  Flags := Flags or DT_NOPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);
  Canvas.Font := Font;
  if not Enabled then
  begin
    OffsetRect(Rect, 1, 1);
    Canvas.Font.Color := clBtnHighlight;
    DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect, Flags);
    OffsetRect(Rect, -1, -1);
    Canvas.Font.Color := clBtnShadow;
    DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect, Flags);
  end
  else
    DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect, Flags);
end;
{$endif}


end.
