unit u_connList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls;

type

  { TfrmConnList }

  TfrmConnList = class(TForm)
    btConnect: TButton;
    bChangeConn: TButton;
    btNotUset: TButton;
    btNewConn: TButton;
    btDelConn: TButton;
    btClose: TButton;
    ImageList1: TImageList;
    lv: TListView;
    procedure bChangeConnClick(Sender: TObject);
    procedure btDelConnClick(Sender: TObject);
    procedure btNewConnClick(Sender: TObject);
    procedure btNotUsetClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    FSavedIndex:Integer;
    procedure FillList;
  public

  end;

var
  frmConnList: TfrmConnList;

function SelectDB:string;

implementation

uses u_data, u_newConn, math;

function SelectDB: string;
var li:TListItem;
begin
  Result:='';
  Application.CreateForm(TfrmConnList,frmConnList);
  frmConnList.FillList;
  if frmConnList.ShowModal = mrOK then begin
    if frmConnList.lv.ItemIndex <> -1 then begin
      li:=frmConnList.lv.Items[frmConnList.lv.ItemIndex];
      Result:='%s(%s)'.Format([li.Caption,li.SubItems[0]]);
    end;
  end;
  FreeAndNil(frmConnList);
end;

{$R *.lfm}

{ TfrmConnList }

procedure TfrmConnList.FormCreate(Sender: TObject);
begin
  FSavedIndex:=-1;
  Font.Size:=Options.IntfFont;
end;

procedure TfrmConnList.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  CloseAction:=caHide;
end;

procedure TfrmConnList.btNewConnClick(Sender: TObject);
begin
  if CreateConnection<>'' then begin
    FillList;
    lv.ItemIndex:=lv.Items.Count-1;
  end;
end;

procedure TfrmConnList.btNotUsetClick(Sender: TObject);
var I,J:Integer;
    S:string;
    li:TListItem;
begin
  I:=lv.ItemIndex;
  if I = -1 then Exit;
  li:=lv.Items[I];
  S:='%s(%s)'.Format([li.Caption,li.SubItems[0]]);
  J:=Options.ActivePrj.LinkedDataBases.IndexOf(S);
  if J<>-1 then begin
    Options.ActivePrj.LinkedDataBases.Delete(J);
    FillList;
    lv.ItemIndex:=I;
  end;
end;

procedure TfrmConnList.bChangeConnClick(Sender: TObject);
var li:TListItem;
    I:Integer;
begin
  I:=lv.ItemIndex;
  if I = -1 then Exit;
  li:=lv.Items[I];
  if EditConnection(li.Caption,li.SubItems[0]) then begin
    FillList;
    lv.ItemIndex:=I;
  end;
end;

procedure TfrmConnList.btDelConnClick(Sender: TObject);
var I:Integer;
    li:TListItem;
    dbi:TDBColItem;
begin
  I:=lv.ItemIndex;
  if I = -1 then Exit;
  li:=lv.Items[I];
  dbi:=Options.GetDBInfo(li.Caption,li.SubItems[0]);
  if dbi<>nil then begin
    Options.DataBases.Delete(dbi.Index);
    FillList;
    I:=Min(I,lv.Items.Count-1);
    if I>-1 then
      lv.ItemIndex:=I;
  end;
end;

procedure TfrmConnList.FillList;
var I:Integer;
    li:TListItem;
    dbi:TDBColItem;
begin
  lv.Items.BeginUpdate;
  lv.Clear;
  try
    for I:=0 to Options.DataBases.Count-1 do begin
      dbi:=TDBColItem(Options.DataBases.Items[I]);
      li:=lv.Items.Add;
      li.Caption:=dbi.Name;
      li.SubItems.Add(dbi.TypeName);
      li.ImageIndex:=IfThen(Options.ActivePrj.LinkedDataBases.IndexOf(dbi.AsText)<>-1,0,1);
    end;
  finally
    lv.Items.EndUpdate;
  end;
end;

end.

