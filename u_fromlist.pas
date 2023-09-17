unit u_fromlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmWinList }

  TfrmWinList = class(TForm)
    btShow: TButton;
    btCancel: TButton;
    btClose: TButton;
    btCenter: TButton;
    lb: TListBox;
    procedure btCenterClick(Sender: TObject);
    procedure btShowClick(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
    procedure btCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lbDblClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure Init;
  end;

var
  frmWinList: TfrmWinList;


procedure ShowForms;

implementation

uses u_data;

procedure ShowForms;
begin
  Application.CreateForm(TfrmWinList,frmWinList);
  frmWinList.Init;
  frmWinList.Show;
end;

{$R *.lfm}

{ TfrmWinList }

procedure TfrmWinList.btCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmWinList.btCloseClick(Sender: TObject);
var cf:TCustomForm;
begin
  if  lb.ItemIndex<0 then Exit;
  cf:=TCustomForm(lb.Items.Objects[lb.ItemIndex]);
  cf.Close;
end;

procedure TfrmWinList.btShowClick(Sender: TObject);
var cf:TCustomForm;
begin
  if lb.ItemIndex<0 then Exit;
  cf:=TCustomForm(lb.Items.Objects[lb.ItemIndex]);
  cf.Show;
  Close;
end;

procedure TfrmWinList.btCenterClick(Sender: TObject);
var cf:TCustomForm;
begin
  if lb.ItemIndex<0 then Exit;
  cf:=TCustomForm(lb.Items.Objects[lb.ItemIndex]);
  if cf.Height>Screen.Height then cf.Top:=0
  else cf.Top:=(Screen.Height-cf.Height) div 2;
  if cf.Width>Screen.Width then cf.Left:=0
  else cf.Left:=(Screen.Width-cf.Width) div 2;
  cf.Show;
  Close;
end;

procedure TfrmWinList.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfrmWinList.FormCreate(Sender: TObject);
begin
  Font.Size:=Options.IntfFont;
end;

procedure TfrmWinList.lbDblClick(Sender: TObject);
begin
  btShow.Click;
end;

procedure TfrmWinList.Init;
var I:Integer;
    cf:TCustomForm;
begin
  for I:=0 to Screen.CustomFormCount-1 do begin
     cf:=Screen.CustomForms[I];
     if cf=Self then Continue;
     if not cf.Visible then Continue;
     lb.Items.AddObject(cf.Caption,cf);
  end;
end;

end.

