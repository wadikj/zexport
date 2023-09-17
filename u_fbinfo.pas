unit u_fbinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, u_frSQL, IBConnection, SQLDB, DB;


type
  TFBDB = class;

  { TFBItem }

  TFBItem = class(TDBBaseItem)
    protected
      function GetDB: TFBDB;
      function GetChildCount: integer;override;
      function GetChild(I: integer): TDBBaseItem;override;
    public
      property DB:TFBDB read GetDB;
  end;

  { TFBDB }

  TFBDB = class(TFBItem)
    private
      function GetDS(ASQL:string):TSQLQuery;
      procedure CloseDS(AQuery:TSQLQuery);
    protected
      FConnection:TIBConnection;
      procedure CreateChildren;override;
    public
      constructor Create(AConnection:TIBConnection);
  end;


  { TFBConnType }

  TFBConnType = class (TConnectionType)
    protected
      function GetTypeName:string; override;
      function InternalCreateInfo(AConnData:string):TConnectionInfo;override;
      function GetMultiTransactions: boolean;override;
    public
      function GetDBItem(AInfo:TConnectionInfo):TDBBaseItem;override;
  end;


  { TFBTableList }

  TFBTableList = class(TFBItem)
    protected
      function HasChildren:boolean;override;
      procedure CreateChildren;override;
    public
      procedure AfterConstruction; override;
  end;

  TFBTable = class (TFBItem)
    protected
      function GetDataCount: integer;override;
      function GetDataItem(I: Integer): string;override;
      function GetSupported: TItemFeatures;override;
      function HasChildren:boolean;override;
      procedure CreateData;override;
    public
      function GetSelect:string;override;
  end;

  { TFBDomainList }

  TFBDomainList = class(TFBItem)
    protected
      procedure CreateChildren;override;
    public
      function GetSelect:string;override;
      procedure AfterConstruction; override;
  end;

  { TFBViewList }

  TFBViewList = class(TFBItem)
    protected
      procedure CreateChildren;override;
    public
      procedure AfterConstruction; override;
  end;

  { TFBProcList }

  TFBProcList = class(TFBItem)
    protected
      procedure CreateChildren;override;
    public
      procedure AfterConstruction; override;
  end;

  { TFBTriggerList }

  TFBTriggerList = class(TFBItem)
    protected
      procedure CreateChildren;override;
    public
      procedure AfterConstruction; override;
  end;

  { TFBGenList }

  TFBGenList = class(TFBItem)
    protected
      procedure CreateChildren;override;
      function HasChildren:boolean;override;

    public
      procedure AfterConstruction; override;

  end;

  { TFBGenerator }

  TFBGenerator  = class (TFBItem)
    private
      procedure CreateData; override;
      function HasChildren: boolean; override;


  end;


  { TFBIndexList }

  TFBIndexList = class(TFBItem)
    protected
      procedure CreateChildren;override;
    public
      procedure AfterConstruction; override;

  end;

implementation

uses u_data;

{ TFBGenerator }

procedure TFBGenerator.CreateData;
var Q:TSQLQuery;
begin
  if FData = nil then
    FData:=TStringList.Create
  else
    Exit;
  try
    Q:=DB.GetDS(' select RDB$GENERATOR_NAME, rdb$generator_id from RDB$GENERATORS '+
      ' where RDB$GENERATOR_NAME = ''%s'' '.Format([FDisplayName]));
    FData.Add('Name: ' + Q.Fields[0].AsString);
    FData.Add('GenID: ' + Q.Fields[1].AsString);
    Q.Close;
    Q.SQL.Text:='select gen_id(%s, 0) from rdb$database '.Format([FDisplayName]);
    Q.Open;
    FData.Add('Value: ' + Q.Fields[0].AsString);
  finally
    DB.CloseDS(Q);
  end;
end;

function TFBGenerator.HasChildren: boolean;
begin
  Result:=False;
end;

{ TFBTable }

function TFBTable.GetDataCount: integer;
begin
  CreateData;
  if FData<>nil then Result:=FData.Count
  else Result:=0;
end;

function TFBTable.GetDataItem(I: Integer): string;
begin
  if FData<>nil then Result:=FData[I]
  else Result:='';
end;

function TFBTable.GetSupported: TItemFeatures;
begin
  Result:=[ifGetSelect,ifGetSQL,ifUpdateChildren];
end;

function TFBTable.HasChildren: boolean;
begin
  Result:=False;
end;

procedure TFBTable.CreateData;
var Q:TSQLQuery;
    S:string;
begin
  if FData = nil then FData:=TStringList.Create
  else FData.Clear;
  log(FDisplayName+' - CreateData');
  Q:=DB.GetDS('select rdb$relation_fields.rdb$field_name, rdb$field_type, rdb$field_length, '+
    'rdb$relation_name from RDB$RELATION_FIELDS join rdb$fields on  '+
    'RDB$RELATION_FIELDS.rdb$field_source = rdb$fields.rdb$field_name '+
    'and rdb$relation_name='''+FDisplayName + ''' order by rdb$field_position');

  {base select for check field type
  for views it small different
  select r.rdb$field_name, f.rdb$field_name as dom_name, rdb$field_type, rdb$field_scale,
    f.rdb$default_source as field_def, r.rdb$default_source as table_def, rdb$field_length,
    rdb$relation_name, rdb$validation_source, rdb$field_sub_TYPE,
    r.RDB$NULL_FLAG as Not_NULLS
from RDB$RELATION_FIELDS r join rdb$fields f on
    r.rdb$field_source = f.rdb$field_name
where
     /*rdb$relation_name='''+FDisplayName + '''*/
     r.rdb$system_flag <> 1

order by rdb$relation_name, rdb$field_position     }
  while not Q.EOF do begin
    S:=Trim(Q.Fields[0].AsString) + ': ';
    case Q.Fields[1].AsInteger of
      7:S:=S+'SMALLINT';
      8:S:=S+'INTEGER';
      10:S:=S+'FLOAT';
      12:S:=S+'DATE';
      13:S:=S+'TIME';
      14:S:=S+'CHAR(' + Q.Fields[2].AsString + ')';
      16:S:=S+'BIGINT';
      27:S:=S+'DOUBLE PRECESION';
      35:S:=S+'TIMESATMP';
      37:S:=S+'VARCHAR(' + Q.Fields[2].AsString + ')';
      261:S:=S+'BLOB';
    end;
    FData.Add(S);
    Q.Next;
  end;
  DB.CloseDS(Q);
end;

function TFBTable.GetSelect: string;
var I:Integer;
begin
  Result:=FData[0].Split(':')[0];
  for I:=1 to FData.Count-1 do
    Result:=Result + ', ' + FData[I].Split(':')[0];
  Result:='select '+Result+#13+'from '+DisplayName;
end;


{ TFBConnType }

function TFBConnType.GetTypeName: string;
begin
  Result:='FireBird';
end;

function TFBConnType.InternalCreateInfo(AConnData: string): TConnectionInfo;
var Tran:TSQLTransaction;
    dbc:TDBColItem;
begin
  Result:=TConnectionInfo.Create;
  Result.FConnection:=TIBConnection.Create(nil);
  Result.FConnType:=Self;
  Result.FName:=AConnData;
  dbc:=Options.GetDBInfo(AConnData,TypeName);
  if dbc = nil then
    raise Exception.CreateFmt('Can''t find database named %s, typed %s', [AConnData, TypeName]);
  Result.FDBPath:=dbc.DBPath;
  Result.FConnection.DatabaseName:=dbc.DBPath;
  Tran:=TSQLTransaction.Create(nil);
  Result.FConnection.Transaction:=Tran;
  if dbc.Params.IndexOfName('user_name')<>-1 then
    TIBConnection(Result.FConnection).UserName:=dbc.Params.Values['user_name'];
  if dbc.Params.IndexOfName('password')<>-1 then
    TIBConnection(Result.FConnection).Password:=dbc.Params.Values['password'];
  if dbc.Params.IndexOfName('lc_ctype')<>-1 then
    TIBConnection(Result.FConnection).CharSet:=dbc.Params.Values['lc_ctype'];
end;

function TFBConnType.GetMultiTransactions: boolean;
begin
  Result:=True;
end;

function TFBConnType.GetDBItem(AInfo: TConnectionInfo): TDBBaseItem;
begin
  Result:=TFBDB.Create(AInfo.FConnection as TIBConnection);
  Result.UpdateChilds;
end;

{ TFBIndexList }

procedure TFBIndexList.CreateChildren;
begin
  FDisplayName:='Indexes';
end;

procedure TFBIndexList.AfterConstruction;
begin
  inherited AfterConstruction;
  FDisplayName:='Indicies';
end;

{ TFBGenList }

procedure TFBGenList.CreateChildren;
var Q:TSQLQuery;
    fg:TFBGenerator;
begin
  if FItems = nil then
    FItems:=TDBItemsList.Create(True)
  else
    Exit;
  try
    Q:=DB.GetDS('select rdb$generator_name from RDB$GENERATORS where RDB$SYSTEM_FLAG = 0');
    while not Q.EOF do begin
      fg:=TFBGenerator.Create(DB);
      fg.FDisplayName:=Trim(Q.Fields[0].AsString);
      FItems.Add(fg);
      Q.Next;
    end;
  finally
    DB.CloseDS(Q);
  end;
end;

function TFBGenList.HasChildren: boolean;
var Q:TSQLQuery;
begin
  Result:=False;
  try
    Q:=DB.GetDS('select 1 from rdb$database '+
      ' where exists ( ' +
      ' select rdb$generator_id from RDB$GENERATORS where RDB$SYSTEM_FLAG = 0)');
    Result:=not Q.IsEmpty;
  finally
    DB.CloseDS(Q);
  end;
end;

procedure TFBGenList.AfterConstruction;
begin
  inherited AfterConstruction;
  FDisplayName:='Generators';
end;

{ TFBTriggerList }

procedure TFBTriggerList.CreateChildren;
begin
  FDisplayName:='Triggers';
end;

procedure TFBTriggerList.AfterConstruction;
begin
  inherited AfterConstruction;
  FDisplayName:='Triggers';
end;

{ TFBProcList }

procedure TFBProcList.CreateChildren;
begin
  FDisplayName:='Pocedures';
end;

procedure TFBProcList.AfterConstruction;
begin
  inherited AfterConstruction;
  FDisplayName:='Procedures';
end;

{ TFBViewList }

procedure TFBViewList.CreateChildren;
begin
  FDisplayName:='Views';
end;

procedure TFBViewList.AfterConstruction;
begin
  inherited AfterConstruction;
  FDisplayName:='Views';
end;

{ TFBDomainList }

procedure TFBDomainList.CreateChildren;
begin
end;

function TFBDomainList.GetSelect: string;
begin
  Result:=''
end;

procedure TFBDomainList.AfterConstruction;
begin
  inherited AfterConstruction;
  FDisplayName:='Domains';
end;

{ TFBTableList }

function TFBTableList.HasChildren: boolean;
var Q:TSQLQuery;
    T:TFBTable;
begin
  FDisplayName:='Tables';
  Q:=DB.GetDS('select 1 from rdb$database where '+
    'exists (select rdb$relation_name from RDB$RELATIONS where rdb$system_flag<>1 and rdb$relation_type <> 1)');
  Result:=not Q.IsEmpty;
  DB.CloseDS(Q);
end;

procedure TFBTableList.CreateChildren;
var Q:TSQLQuery;
    T:TFBTable;
begin
  Log('Table list create children!');
  if FItems = nil then
    FItems:=TDBItemsList.Create(True)
  else begin
    Log('Table list exists!');
    Exit;
  end;
  FDisplayName:='Tables';
  Q:=DB.GetDS('select rdb$relation_name from RDB$RELATIONS where rdb$system_flag<>1 and rdb$relation_type <> 1');
  while not Q.EOF do begin
    T:=TFBTable.Create(Self.FRootItem);
    T.FDisplayName:=Q.Fields[0].AsString.Trim;
    FItems.Add(T);
    Q.Next;
  end;
  DB.CloseDS(Q);
end;

procedure TFBTableList.AfterConstruction;
begin
  inherited AfterConstruction;
  FDisplayName:='Tables';
end;

{ TFBDB }

function TFBDB.GetDS(ASQL: string): TSQLQuery;
var T:TSQLTransaction;
begin
  Result:=TSQLQuery.Create(nil);
  Result.DataBase:=FConnection;
  T:=TSQLTransaction.Create(nil);
  T.DataBase:=FConnection;
  Result.Transaction:=T;
  if ASQL<>'' then begin
    Result.SQL.Text:=ASQL;
    Result.Active:=True;
  end;
end;

procedure TFBDB.CloseDS(AQuery: TSQLQuery);
var T:TDBTransaction;
begin
  AQuery.Active:=False;
  T:=AQuery.Transaction;
  AQuery.Transaction:=nil;
  T.Free;
  AQuery.Free;
end;

procedure TFBDB.CreateChildren;
var AItem:TFBItem;
begin
  //таблицы, домены, вьюхи, процедуры, триггеры, генераторы, индексы
  Log('FBDB -CreateChildren');
  if FItems = nil then
    FItems:=TDBItemsList.Create(True)
  else begin
    Exit;
  end;
  AItem:=TFBTableList.Create(Self);
  //AItem.UpdateChilds;
  FItems.Add(AItem);
  AItem:=TFBViewList.Create(Self);
  //AItem.UpdateChilds;
  FItems.Add(AItem);
  AItem:=TFBDomainList.Create(Self);
  //AItem.UpdateChilds;
  FItems.Add(AItem);
  AItem:=TFBIndexList.Create(Self);
  //AItem.UpdateChilds;
  FItems.Add(AItem);
  AItem:=TFBGenList.Create(Self);
  //AItem.UpdateChilds;
  FItems.Add(AItem);
  AItem:=TFBProcList.Create(Self);
  //AItem.UpdateChilds;
  FItems.Add(AItem);
  AItem:=TFBTriggerList.Create(Self);
  //AItem.UpdateChilds;
  FItems.Add(AItem);
end;

constructor TFBDB.Create(AConnection: TIBConnection);
begin
  FConnection := AConnection;
  FDisplayName:=ExtractFileName(FConnection.DatabaseName);
  //UpdateChilds;
end;

{ TFBItem }

function TFBItem.GetDB: TFBDB;
begin
  Result:=TFBDB(FRootItem);
end;

function TFBItem.GetChildCount: integer;
begin
  if FItems = nil then
    CreateChildren;
  if FItems<>nil then
    Result:=FItems.Count
  else begin
    Result:=0;
  end;
end;

function TFBItem.GetChild(I: integer): TDBBaseItem;
begin
  if FItems<>nil then
    Result:=FItems[I]
  else
    Result:=nil;
end;

initialization
  AddConnType(TFBConnType.Create);

end.

