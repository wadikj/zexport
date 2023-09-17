unit testreg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TfrmSetIEVer }

  TfrmSetIEVer = class(TForm)
    btSetKey: TButton;
    Label1: TLabel;
    lbVer: TListBox;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure btSetKeyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function GetParamName:string;

  public

  end;


procedure SetIEVersion;

implementation

uses Registry, s_tools, u_data;

const KeyName = 'SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION\';

procedure StartTestReg;
begin
end;

procedure SetIEVersion;
var F:TfrmSetIEVer;
begin
  Application.CreateForm(TfrmSetIEVer, F);
  F.ShowModal;
end;

{$R *.lfm}

{ TfrmSetIEVer }

procedure TfrmSetIEVer.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfrmSetIEVer.btSetKeyClick(Sender: TObject);
var reg:TRegistry;
    S:string;
    I:LongInt;
begin
  if lbVer.ItemIndex<0 then begin
    ShowMessage('For set IE version need select it!!!');
    Exit;
  end;
  S:=lbVer.Items[lbVer.ItemIndex];
  DivStr(S,' - ');
  I:=StrToInt(S);
  reg:=TRegistry.Create();
  if reg.OpenKey(KeyName, False)
  then begin
    reg.WriteInteger(GetParamName,I);
  end;
  reg.Free;
end;

procedure TfrmSetIEVer.FormCreate(Sender: TObject);
var reg:TRegistry;
    ver, I: Integer;
    S, S1:string;
begin
  Font.Size:=Options.IntfFont;
  //лезем в реестр и ищем, что у нас там есть
  reg:=TRegistry.Create();
  ver := 7000;
  if reg.OpenKey(KeyName,False) then
    if reg.ValueExists(GetParamName) then
      ver:=reg.ReadInteger(GetParamName)
    else
      ver := 7000;
  reg.Free;
  S1:=IntToStr(ver);
  for I:=0 to lbVer.Count - 1 do begin
    S:=lbVer.Items[I];
    DivStr(S, ' - ');
    if S=S1 then begin
      lbVer.ItemIndex:=I;
      Break;
    end;
  end;
  if lbVer.ItemIndex = -1 then
    lbVer.ItemIndex:=lbVer.Items.Count-1;
end;

function TfrmSetIEVer.GetParamName: string;
begin
  Result:=ExtractFileName(Application.ExeName);
end;

end.

