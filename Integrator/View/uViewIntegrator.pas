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

unit uViewIntegrator;

interface

{$ifdef WIN32}
uses uIntegrator, uModel, uModelEntity, Controls, Graphics, IniFiles, Classes, uFeedback, Types;
{$endif}
{$ifdef LINUX}
uses uIntegrator, uModel, uModelEntity, QControls, QGraphics, IniFiles, Classes, uFeedback;
{$endif}

type

  //Baseclass for integrators that are parented
  TViewIntegrator = class(TTwowayIntegrator)
  private
    Parent: TWinControl;
    function GetCurrentEntity: TModelEntity;
    class procedure SetCurrentEntity(const Value: TModelEntity);
  protected
    Feedback : IEldeanFeedback;
    procedure CurrentEntityChanged; virtual;
  public
    constructor Create(om: TObjectModel; Parent: TWinControl; Feedback : IEldeanFeedback = nil); virtual;
    destructor Destroy; override;
    //Current entity, all view integratros share the same instance
    property CurrentEntity : TModelEntity read GetCurrentEntity write SetCurrentEntity;
  end;

  //Class to show/edit a model in a powerpointy view
  TDiagramIntegrator = class(TViewIntegrator)
  private
    FOnUpdateToolbar: TNotifyEvent;
    FOnUpdateZoom: TNotifyEvent;
    FShowAssoc: boolean;
  protected
    FVisibilityFilter: TVisibility;
    FPackage: TAbstractPackage;
    procedure SetVisibilityFilter(const Value: TVisibility); virtual;
    procedure SetPackage(const Value: TAbstractPackage); virtual;
    procedure SetShowAssoc(const Value: boolean); virtual;
    function GetStorage(Create : boolean = False) : TCustomIniFile; virtual;
    procedure StoreDiagram; virtual; abstract;
    function FetchDiagram : integer; virtual; abstract;
    procedure DoOnUpdateToolbar;
    procedure DoOnUpdateZoom;
  public
    class function CreateDiagram(om: TObjectModel; Parent: TWinControl; Feedback : IEldeanFeedback = nil) : TDiagramIntegrator;
    procedure GetDiagramSize(var W,H : integer); virtual; abstract;
    function GetSelectedRect : TRect; virtual; abstract;
    procedure PaintTo(Canvas: TCanvas; X, Y: integer; SelectedOnly : boolean); virtual; abstract;
    procedure SaveAsPicture(const FileName : string);
    procedure DoLayout; virtual; abstract;
    function GetClickAreas : TStringList; virtual; abstract;
    procedure DrawZoom(Canvas : TCanvas; W,H : integer); virtual; abstract;
    procedure SetZoomedScroll(ScrollX,ScrollY,W,H : integer); virtual; abstract;
    procedure ScreenCenterEntity(E : TModelEntity); virtual; abstract;

    procedure HideSelectedDiagramElements; virtual; abstract;
    function HasHiddenElements : boolean; virtual; abstract;
    procedure UnHideAllElements; virtual; abstract;

    //Current package
    property Package: TAbstractPackage read FPackage write SetPackage;

    property VisibilityFilter : TVisibility read FVisibilityFilter write SetVisibilityFilter;
    property OnUpdateToolbar : TNotifyEvent read FOnUpdateToolbar write FOnUpdateToolbar;
    property OnUpdateZoom : TNotifyEvent read FOnUpdateZoom write FOnUpdateZoom;
    //True if associations are to be shown
    property ShowAssoc : boolean read FShowAssoc write SetShowAssoc;
  end;

  procedure SetCurrentEntity(Value : TModelEntity);

implementation
{$ifdef WIN32}
uses uRtfdDiagram, SysUtils, Forms, Contnrs, {$ifdef GIF_SUPPORT}gifimage,{$endif} math, uConfig;
{$endif}
{$ifdef LINUX}
uses uRtfdDiagram, SysUtils, QForms;
{$endif}

var
  _CurrentEntity : TModelEntity = nil;
  _ViewIntegrators : TObjectList;

{ TViewIntegrator }

constructor TViewIntegrator.Create(om: TObjectModel; Parent: TWinControl; Feedback : IEldeanFeedback = nil);
begin
  inherited Create(om);
  Self.Parent := Parent;
  if Feedback=nil then
    Self.Feedback := NilFeedback
  else
    Self.Feedback := Feedback;
  _ViewIntegrators.Add(Self);
end;

{ TDiagramIntegrator }

//Factoryfunction, creates an instance of TDiagramIntegrator
class function TDiagramIntegrator.CreateDiagram(om: TObjectModel; Parent: TWinControl; Feedback : IEldeanFeedback = nil): TDiagramIntegrator;
begin
  Result := TRtfdDiagram.Create(om, Parent, Feedback);
end;


procedure TDiagramIntegrator.SetPackage(const Value: TAbstractPackage);
begin
  FPackage := Value;
end;

//Creates storage space for the diagram
function TDiagramIntegrator.GetStorage(Create: boolean): TCustomIniFile;
var
  F : string;
begin
  Result := nil;
  if Assigned(FPackage) then
  begin
    F := FPackage.GetConfigFile;
    if F='' then
      F := ChangeFileExt(Application.ExeName,ConfigFileExt);
    if FileExists(F) or Create then
      Result := TMemIniFile.Create(F);
  end;
end;


procedure TDiagramIntegrator.SetVisibilityFilter(const Value: TVisibility);
begin
  if FVisibilityFilter<>Value then
  begin
    FVisibilityFilter := Value;
    DoOnUpdateToolbar;
    DoOnUpdateZoom;
  end;
end;

procedure TDiagramIntegrator.DoOnUpdateToolbar;
begin
  if Assigned(FOnUpdateToolbar) then
    FOnUpdateToolbar(Self);
end;

procedure TDiagramIntegrator.DoOnUpdateZoom;
begin
  if Assigned(FOnUpdateZoom) then
    FOnUpdateZoom(Self);
end;

procedure TDiagramIntegrator.SaveAsPicture(const FileName: string);
var
  W,H : integer;

  {$ifdef GIF_SUPPORT}
  procedure InToGif;
  var
    Bitmap : Graphics.TBitmap;
    Gif : TGifImage;
    OldColors,UseMono : boolean;
  begin
    Bitmap := Graphics.TBitmap.Create;
    Gif := TGifImage.Create;
    try
      //Use b/w for large pictures to reduce memory consumption
      UseMono := Max(W,H)>16000;
      OldColors := Config.IsLimitedColors;
      if UseMono then
      begin
        Bitmap.Monochrome := True;
        Config.IsLimitedColors := True;
      end;
      Bitmap.Width := W;
      Bitmap.Height := H;

      PaintTo(Bitmap.Canvas,0,0,False);

      if UseMono then
        Config.IsLimitedColors := OldColors;

      //Change to 8-bit so that gifimage don't have to do a colorreduction (takes forever)
      if Bitmap.PixelFormat<>pf8bit then
        Bitmap.PixelFormat := pf8bit;

      Gif.Compression := gcRle;
      Gif.ColorReduction := rmQuantizeWindows;
      Gif.Assign(Bitmap);
      Gif.SaveToFile( FileName );
    finally
      Bitmap.Free;
    end;
  end;
  {$endif}

  procedure InToWMF;
  var
    Wmf : TMetaFile;
    WmfCanvas : TMetaFileCanvas;
  begin
    Wmf := TMetafile.Create;
    try
      Wmf.Width := W;
      Wmf.Height := H;
      WmfCanvas := TMetafileCanvas.Create(Wmf, 0);
      try
        PaintTo(WmfCanvas, 0, 0, False);
      finally
        WmfCanvas.Free;
      end;
      Wmf.SaveToFile( FileName );
    finally
      Wmf.Free;
    end;
  end;

begin
  GetDiagramSize(W,H);
  if Pos( 'wmf' , LowerCase( ExtractFileExt( FileName ) ))>0 then
    InToWmf
  else
    {$ifdef GIF_SUPPORT}
    InToGif
    {$endif}
    ;
end;

//--------------------------------------

procedure TViewIntegrator.CurrentEntityChanged;
begin
//stub
end;

destructor TViewIntegrator.Destroy;
begin
  _ViewIntegrators.Remove(Self);
  inherited;
end;

function TViewIntegrator.GetCurrentEntity: TModelEntity;
begin
  Result := _CurrentEntity;
end;


procedure SetCurrentEntity(Value : TModelEntity);
var
  I : integer;
begin
  if Value<>_CurrentEntity then
  begin
    _CurrentEntity := Value;
    for I := 0 to _ViewIntegrators.Count-1 do
      (_ViewIntegrators[I] as TViewIntegrator).CurrentEntityChanged;
  end;
end;

class procedure TViewIntegrator.SetCurrentEntity(const Value: TModelEntity);
begin
  uViewIntegrator.SetCurrentEntity(Value);
end;


procedure TDiagramIntegrator.SetShowAssoc(const Value: boolean);
begin
  FShowAssoc := Value;
end;

initialization
  _ViewIntegrators := TObjectList.Create(False);
finalization
  _ViewIntegrators.Free;
end.

