unit u_mast_det;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, ExtCtrls, DBGrids, ComCtrls,
  StdCtrls, SynEdit, SynHighlighterSQL;

type

  { TfrMD }

  TfrMD = class(TFrame)
    cbMaster: TComboBox;
    cbDetail: TComboBox;
    dsMaster: TDataSource;
    dsDetail: TDataSource;
    dgMaster: TDBGrid;
    dgDetail: TDBGrid;
    ImageList1: TImageList;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    sqMaster: TSQLQuery;
    sqDetail: TSQLQuery;
    trMaster: TSQLTransaction;
    trDetail: TSQLTransaction;
    seMaster: TSynEdit;
    seDetail: TSynEdit;
    SynSQLSyn1: TSynSQLSyn;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    tbMasRun: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    tbDetRun: TToolButton;
    procedure cbMasterGetItems(Sender: TObject);
    procedure cbMasterSelect(Sender: TObject);
    procedure sqMasterAfterScroll(DataSet: TDataSet);
    procedure tbDetRunClick(Sender: TObject);
    procedure tbMasRunClick(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
  private
    FLinks:TStringList;
    procedure FillCombo(ACombo:TComboBox);
    procedure SelectDB(ACombo:TComboBox);

  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses u_frSQL, u_linkParams;

{$R *.lfm}

{ TfrMD }

procedure TfrMD.cbMasterGetItems(Sender: TObject);
begin
  //fill opened db
  FillCombo(Sender as TComboBox);
end;

procedure TfrMD.cbMasterSelect(Sender: TObject);
begin
  //set selected DB
  SelectDB(Sender as TComboBox);
end;

procedure TfrMD.sqMasterAfterScroll(DataSet: TDataSet);
var I:Integer;
  SA:TStringArray;
begin
  if not sqDetail.Active then Exit;
  if not sqMaster.Active then Exit;
  try
    sqDetail.Prepare;
    sqDetail.DisableControls;
    sqDetail.Close;
    for I:=0 to FLinks.Count-1 do begin
      SA:=FLinks[I].Split([':']);
      if (SA[0] = '') or (SA[1] = '') then Exit;
      sqDetail.ParamByName(SA[0]).AsString:=sqMaster.FieldByName(SA[1]).AsString;

    end;
    sqDetail.Open;
  finally
    sqDetail.EnableControls;
  end;
end;

procedure TfrMD.tbDetRunClick(Sender: TObject);
begin
  sqDetail.Close;
  sqDetail.SQL.Text:=seDetail.Lines.Text;
  if sqMaster.Active then
    sqDetail.Open;
end;

procedure TfrMD.tbMasRunClick(Sender: TObject);
begin
  sqMaster.Close;
  sqMaster.SQL.Text:=seMaster.Lines.Text;
  sqMaster.Open;
end;

procedure TfrMD.ToolButton3Click(Sender: TObject);
begin
  LinkParams(FLinks);
end;

procedure TfrMD.FillCombo(ACombo: TComboBox);
begin
  try
    ACombo.Items.BeginUpdate;
    ACombo.Items.Clear;
    FillDBList(ACombo.Items);
    if ACombo.Items.Count=1 then
      ACombo.ItemHeight:=0;
  finally
    ACombo.Items.EndUpdate;
  end;
end;

procedure TfrMD.SelectDB(ACombo: TComboBox);
var Conn:TSQLConnection;
begin
  Conn:=GetSQLConnection(ACombo.Text);
  if Conn=nil then begin
    Log('can'' t get connection named ' + ACombo.Text);
    Exit;
  end;
  if ACombo=cbMaster then begin
    sqMaster.SQLConnection:=Conn;
    trMaster.SQLConnection:=Conn;
  end else begin
    sqDetail.SQLConnection:=Conn;
    trDetail.SQLConnection:=Conn;
  end;
end;

constructor TfrMD.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FLinks:=TStringList.Create;
end;

destructor TfrMD.Destroy;
begin
  FreeAndNil(FLinks);
  inherited Destroy;
end;

end.

