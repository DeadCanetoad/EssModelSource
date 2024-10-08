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

unit uUseful;

interface

{$ifdef WIN32}
uses Classes, Forms, ComCtrls, shlobj;
{$endif}
{$ifdef LINUX}
uses Classes, QForms, QComCtrls;
{$endif}


type
  IEldeanProgress = interface(IUnknown)
    ['{E446EEFB-DABB-4AD9-BE49-104A6F265CB4}']
    procedure Tick;
  end;

  TEldeanProgress = class(TInterfacedObject,IEldeanProgress)
   public
     constructor Create(Text : string; Max : integer); reintroduce;
     destructor Destroy; override;
     procedure Tick;
   private
     P : TProgressBar;
     F : TForm;
     AbortNext : boolean;
   end;

  TBrowseForFolderDialog = class
  private
    FTitle,FPath : string;
  public
    property Title: string read FTitle write FTitle;
    function Execute: Boolean;
    property Path: string read FPath write FPath;
  end;

  function MakeTempDir : string;

implementation

{$ifdef WIN32}
uses Controls, SysUtils,
  Windows, activex, StdCtrls;
{$endif}
{$ifdef LINUX}
uses QControls, SysUtils;
{$endif}

constructor TEldeanProgress.Create(Text: string; Max: integer);
begin
  F := TForm.Create(Application.MainForm);

  F.BorderIcons := [];
  F.BorderStyle := bsDialog; { TODO : Fix for Linux }
  F.Caption := Text;
  F.ClientHeight := 22;
  F.ClientWidth := 390;
  F.Position := poScreenCenter;

  P := TProgressBar.Create(F);
  P.Parent := F;
  P.Align := alTop;
  P.Height := 22;
  P.Max := Max;
  P.Step := 1;
  P.Smooth := True;

  F.Show;
end;

destructor TEldeanProgress.Destroy;
begin
  FreeAndNil(F);
  inherited;
end;

procedure TEldeanProgress.Tick;
begin
  if AbortNext then
    Abort;
  P.StepIt;
  Application.ProcessMessages;
end;



{$IFDEF Win32}

function SetSelProc(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
begin
  if uMsg=BFFM_INITIALIZED then
    Windows.SendMessage(Wnd, BFFM_SETSELECTION, 1, lpData );
  Result := 0;
end;

function TBrowseForFolderDialog.Execute: Boolean;
var
  bi: TBROWSEINFO;
  pIDListItem: PItemIDList;
  str: array[0..1024] of Char;
  pStr: PChar;
begin
  Str[0]:=#0;
  FillChar(Bi,SizeOf(Bi),0);
  bi.lpszTitle := PChar(FTitle);
  bi.hwndOwner := GetActiveWindow;
  bi.pidlRoot := nil;
  bi.pszDisplayName := @str;
  bi.ulFlags := BIF_RETURNONLYFSDIRS;

  if FPath<>'' then
  begin
    bi.lpfn := SetSelProc;
    bi.lParam := Integer( PChar(FPath) );
  end;

  pIDListItem := SHBrowseForFolder(bi);
  if pIDListItem <> nil then
  begin
    pStr := @Str;
    SHGetPathFromIDList(pIDListItem, pStr);
    CoTaskMemFree(pIDListItem);
    FPath := Copy(pStr,1,Length(PStr));
    Result := True;
  end
  else
    Result := False;
end;
{$ENDIF}

{$IFDEF Linux}
function TBrowseForFolderDialog.Execute: Boolean;
begin
{ TODO : Fix for Linux }
  Result := False;
end;
{$ENDIF}


var
  CleanUp : TStringList;

function MakeTempDir : string;
var
  Buf: array[0..200] of byte;
  TempPath : string;
  I : integer;
  Ok : boolean;
begin
  GetTempPath(200, @Buf);
  TempPath := PChar(@Buf);
  Ok := False;
  for I := 0 to 50 do
  begin
    Result := TempPath + 'Essmodel' + IntToStr(I);
    if not DirectoryExists(Result) then
    begin
      MkDir( Result );
      Ok := True;
      Result := Result;
      CleanUp.Add(Result);
      Break;
    end;
  end;
  if not Ok then
    raise Exception.Create('Failed to create temp directory');
end;

procedure DoCleanUp;
var
  I : integer;
  DirInfo: TSearchRec;
  Res: integer;
  S : string;
begin
  for I := 0 to CleanUp.Count-1 do
  begin
    S := CleanUp[I];
    if Pos('Essmodel',S)=0 then
      Continue;  //Safety
    Res := SysUtils.FindFirst(S + '\*.*', 0, DirInfo);
    while Res = 0 do
    begin
      SysUtils.DeleteFile(S + '\' + DirInfo.Name);
      Res := SysUtils.FindNext(DirInfo);
    end;
    SysUtils.FindClose(DirInfo);
    RemoveDir(S);
  end;
end;

initialization
  CleanUp := TStringList.Create;
finalization
  DoCleanUp;
  CleanUp.Free;
end.
