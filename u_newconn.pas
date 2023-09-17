unit u_newConn;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, u_data;

type

  { TfrmNewConn }

  TfrmNewConn = class(TForm)
    btOK: TButton;
    btCancel: TButton;
    btNewDB: TButton;
    cbType: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    leName: TLabeledEdit;
    lePath: TLabeledEdit;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    SpeedButton1: TSpeedButton;
    procedure btNewDBClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    FDBItem:TDBColItem;
    FNewDB:boolean;
    function GetDBType:string;
    procedure SaveData;
    procedure LoadData;
    procedure FillTypes;

  public

  end;

var
  frmNewConn: TfrmNewConn;

//return name(type) of conection or blank ctring
function CreateConnection:string;
function EditConnection(AName, AType: string):boolean;

implementation

uses u_frSQL;

function CreateConnection: string;
begin
  Result:='';
  Application.CreateForm(TfrmNewConn, frmNewConn);
  frmNewConn.LoadData;
  frmNewConn.FNewDB:=False;
  if frmNewConn.ShowModal = mrOK then begin
    frmNewConn.SaveData;
    if frmNewConn.FNewDB then
      u_frSQL.CreateDB(frmNewConn.FDBItem.Name, frmNewConn.FDBItem.TypeName);
    Result:='%s(%s)'.Format([frmNewConn.FDBItem.Name,frmNewConn.FDBItem.TypeName]);
  end;
  FreeAndNil(frmNewConn);
end;

function EditConnection(AName, AType: string): boolean;
begin
  Result:=False;
  Application.CreateForm(TfrmNewConn, frmNewConn);
  frmNewConn.FDBItem:=Options.GetDBInfo(AName,AType);
  frmNewConn.LoadData;
  frmNewConn.btNewDB.Visible:=False;
  If frmNewConn.ShowModal =  mrok then begin
    frmNewConn.SaveData;
    Result:=True;
  end;
end;

{$R *.lfm}

{ TfrmNewConn }

procedure TfrmNewConn.FormCreate(Sender: TObject);
begin
  FDBItem:=nil;
  Font.Size:=Options.IntfFont;
end;

procedure TfrmNewConn.SpeedButton1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    lePath.Text:=OpenDialog1.FileName;
end;

procedure TfrmNewConn.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caHide;
end;

procedure TfrmNewConn.btNewDBClick(Sender: TObject);
begin

end;

function TfrmNewConn.GetDBType: string;
begin
  Result:=cbType.Text;
end;

procedure TfrmNewConn.SaveData;
begin
  if FDBItem = nil then begin
    FDBItem:=TDBColItem(Options.DataBases.Add);
  end;
  FDBItem.DBPath:=lePath.Text;
  FDBItem.Name:=leName.Text;
  FDBItem.TypeName:=GetDBType;
  FDBItem.Params.Text:=Memo1.Lines.Text;
end;

procedure TfrmNewConn.LoadData;
begin
  FillTypes;
  if FDBItem<>nil then begin
    leName.Text:=FDBItem.Name;
    cbType.ItemIndex:=cbType.Items.IndexOf(FDBItem.TypeName);
    lePath.Text:=FDBItem.DBPath;
    Memo1.Lines.Text:=FDBItem.Params.Text;
  end else begin
    leName.Text:='';
    lePath.Text:='';
    cbType.ItemIndex:=-1;
    Memo1.Clear;
  end;
end;

procedure TfrmNewConn.FillTypes;
begin
  cbType.Clear;
  FillDBTypes(cbType.Items);
end;

end.

