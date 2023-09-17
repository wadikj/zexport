unit u_scr;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ComCtrls, Menus, U_simplescr;

type

  { TfrmScr }

  TfrmScr = class(TForm)
    ImageList1: TImageList;
    mmCode: TMemo;
    MenuItem1: TMenuItem;
    OpenDialog1: TOpenDialog;
    pm: TPopupMenu;
    SaveDialog1: TSaveDialog;
    ToolBar1: TToolBar;
    tbRun: TToolButton;
    tbSave: TToolButton;
    tbNewWin: TToolButton;
    tbSavePos: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    tbAdd: TToolButton;
    tbDel: TToolButton;
    procedure bbRunClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sbAddClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { private declarations }
    FScrName:string;
    procedure DoScrClick(Sender:TObject);
    procedure LoadScr(AName:string);
    procedure DoCreateScrMenu;
  public

    { public declarations }
  end;

var
  frmScr: TfrmScr;

procedure ShowScrForms;


implementation

uses s_tools, main, u_data;

procedure ShowScrForms;
var frm:TfrmScr;
    SL:TStringList;
    I:Integer;
    S:string;
begin
  try
    SL:=TStringList.Create;
    Options.LoadStrings('scrpos',SL);
    for I:=0 to SL.Count-1 do begin
      S:=SL[I];
      Application.CreateForm(TfrmScr,frm);
      frm.Position:=poDesigned;
      frm.Left:=StrToInt(DivStr(S,'@'));
      frm.Top:=StrToInt(DivStr(S,'@'));
      frm.Width:=StrToInt(DivStr(S,'@'));
      frm.Height:=StrToInt(DivStr(S,'@'));
      frm.LoadScr(S);
      frm.Show;
    end;
    if SL.Count=0 then begin
      Application.CreateForm(TfrmScr,frm);
      frm.Show;
    end;
  finally
    SL.Free;
  end;
end;

{$R *.lfm}

{ TfrmScr }

procedure TfrmScr.bbSaveClick(Sender: TObject);
begin
  mmCode.Lines.SaveToFile(Options.ActivePrj.FullScrPath(FScrName));
  mmCode.Modified:=False;
end;

procedure TfrmScr.BitBtn1Click(Sender: TObject);
var I:Integer;
    SL:TStringList;
    frm:TForm;
begin
  SL:=TStringList.Create;
  try
    for I:=0 to Screen.FormCount-1 do begin
      frm:=Screen.Forms[I];
      if frm is TfrmScr then begin
        SL.Add(IntToStr(frm.Left)+'@'+IntToStr(frm.Top)+'@'+
        IntToStr(frm.Width)+'@'+IntToStr(frm.Height)+'@'+
        (frm as TfrmScr).FScrName);
      end;
    end;
      Options.SaveStrings('scrpos',SL);
  finally
    SL.Free;
  end;
end;

procedure TfrmScr.bbRunClick(Sender: TObject);
begin
  if FScrName<>'' then
    Exec(FScrName,nil);
end;

procedure TfrmScr.ComboBox1Change(Sender: TObject);
begin
end;

procedure TfrmScr.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfrmScr.FormCreate(Sender: TObject);
begin
  FScrName:='';
  Caption:='[*NO SCRIPT HERE*]';
  DoCreateScrMenu;
  mmCode.Font.Size:=Options.EditFont;
end;

procedure TfrmScr.sbAddClick(Sender: TObject);
var S:string;
begin
  S:='';
  if InputQuery('New srcript','Input name of a new scr',S) then begin
    LoadScr(S);
  end;
end;

procedure TfrmScr.SpeedButton1Click(Sender: TObject);
var frm:TfrmScr;
begin
  Application.CreateForm(TfrmScr,frm);
  frm.Show;
end;

procedure TfrmScr.DoScrClick(Sender: TObject);
begin
  if not (Sender is TMenuItem) then Exit;
  LoadScr((Sender as TMenuItem).Caption);
end;

procedure TfrmScr.LoadScr(AName: string);
var S:string;
begin
  if mmCode.Modified then begin
    if FScrName<>'' then
      mmCode.Lines.SaveToFile(Options.ActivePrj.FullScrPath(FScrName));
  end;
  mmCode.Clear;
  S:=Options.ActivePrj.FullScrPath(AName);
  if FileExists(S) then begin
    mmCode.Lines.LoadFromFile(S);
  end;
  FScrName:=AName;
  Caption:='['+AName+']';
  Options.ActivePrj.AddMRUScr(AName);
end;

procedure TfrmScr.DoCreateScrMenu;
var I: Integer;
    mi:TMenuItem;
begin
  pm.Items.Clear;
  for i :=0 to Options.ActivePrj.SCR.Count-1 do begin
    mi:=TMenuItem.Create(Self);
    mi.Caption:=Options.ActivePrj.SCR[I];
    mi.OnClick:=@DoScrClick;
    pm.Items.Add(mi);
  end;

end;

end.

