unit u_sqliteinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, u_frSQL, DB, SQLDB, SQLite3Conn, fgl , u_metainfo;

type

  TSQLiteDB = class;

  { TItemsList }

  TItemsList = class(TDBBaseItem)
    private
      function GetDB: TSQLiteDB;
    protected
      function GetChild(I: integer): TDBBaseItem;override;
      function GetChildCount: integer;override;
      property DB:TSQLiteDB read GetDB;
    public
      constructor Create(ARoot:TDBBaseItem; AMetaType:TMetaType);override;
  end;

  { TSQLiteDB }

  TSQLiteDB = class(TItemsList)
    private
      function GetDS(ASQL:string):TSQLQuery;
      procedure CloseDS(AQuery:TSQLQuery);
    protected
      FConnection:TSQLite3Connection;
      procedure CreateChildren;override;
    public
      constructor Create(AConnection:TSQLite3Connection);
  end;

  { TSQLiteTableList }

  TSQLiteTableList = class(TItemsList)
    protected
      procedure CreateChildren;override;
      function HasChildren:boolean;override;

  end;

  TSQLiteTable = class (TDBBaseItem)
    protected
      function GetDataCount: integer;override;
      function GetDataItem(I: Integer): string;override;
      procedure CreateChildren; override;
      procedure CreateData;override;
      function GetSupported: TItemFeatures;override;
      function HasChildren:boolean;override;

    public
      function GetSelect:string;override;
      function GetSQL:string;override;
      procedure UpdateChilds; override;
  end;

  { TSQLiteConnType }

  TSQLiteConnType = class (TConnectionType)
    protected
      function GetTypeName:string; override;
      function InternalCreateInfo(AConnData:string):TConnectionInfo;override;
      function GetMultiTransactions: boolean;override;
    public
      function GetDBItem(AInfo:TConnectionInfo):TDBBaseItem;override;
  end;

implementation

uses u_data;

{ TSQLiteConnType }

function TSQLiteConnType.GetTypeName: string;
begin
  Result:='SQLite';
end;

function TSQLiteConnType.InternalCreateInfo(AConnData: string): TConnectionInfo;
var Tran:TSQLTransaction;
    dbc:TDBColItem;
begin
  Result:=TConnectionInfo.Create;
  Result.FConnection:=TSQLite3Connection.Create(nil);
  Result.FConnType:=Self;
  Result.FName:=AConnData;
  dbc:=Options.GetDBInfo(AConnData,TypeName);
  if dbc = nil then
    raise Exception.CreateFmt('Can''t find database named %s, typed %s', [AConnData, TypeName]);
  Result.FDBPath:=dbc.DBPath;
  Result.FConnection.DatabaseName:=dbc.DBPath;
  Tran:=TSQLTransaction.Create(nil);
  Result.FConnection.Transaction:=Tran;
end;

function TSQLiteConnType.GetMultiTransactions: boolean;
begin
  Result:=False;
end;

function TSQLiteConnType.GetDBItem(AInfo: TConnectionInfo): TDBBaseItem;
begin
  Result:=TSQLiteDB.Create(AInfo.FConnection as TSQLite3Connection);
  Result.UpdateChilds;
end;

{ TSQLiteTable }

function TSQLiteTable.GetDataCount: integer;
begin
  if FData = nil then
    CreateData;
  Result:=FData.Count;
end;

function TSQLiteTable.GetDataItem(I: Integer): string;
begin
  Result:=FData[I];
end;

procedure TSQLiteTable.CreateChildren;
begin
end;

procedure TSQLiteTable.CreateData;
var q:TSQLQuery;
    S:string;
begin
  //читаем поля
  //Log('SQLite Table (%s)- Create Data'.Format([FDisplayName]));
  if FData = nil then
    FData:=TStringList.Create
  else begin
    Log('Table Data not empty: ' + FDisplayName);
    Exit;
  end;
  S:='pragma table_info(''%s'')';
  q:=TSQLiteDB(FRootItem).GetDS(S.Format([FDisplayName]));
  try
    while not Q.EOF do begin
      S:=q.Fields[1].AsString+': ';
      case Q.Fields[2].AsString of
        '':S:=S+'? ';
        'INTEGER':s:=s+'INT ';
        'LONGVARCHAR':S:=S+'LVCHAR ';
      else
        S:=S+Q.Fields[2].AsString+' ';
      end;
      if Q.Fields[3].AsInteger=1 then S:=S+'NN ';
      if Q.Fields[4].AsString<>'' then S:=S+'DEF='+Q.Fields[4].AsString+ ' ';
      if Q.Fields[5].AsString = '1' then S:=S+'PK';
      FData.Add(S);
      q.Next;
    end;
  finally
    TSQLiteDB(FRootItem).CloseDS(q);
  end;
end;

function TSQLiteTable.GetSupported: TItemFeatures;
begin
  Result:=inherited GetSupported + [ifGetSQL, ifGetSelect];
end;

function TSQLiteTable.HasChildren: boolean;
begin
  //Log('SQlite Table %s - Has Children'.Format([FDisplayName]));
  Result:=False;
end;

function TSQLiteTable.GetSelect: string;
var I:Integer;
begin
  Result:=FData[0].Split(':')[0];
  for I:=1 to FData.Count-1 do
    Result:=Result + ', ' + FData[I].Split(':')[0];
  Result:='select '+Result+#13+'from '+DisplayName;
end;

function TSQLiteTable.GetSQL: string;
var Q:TSQLQuery;
    S:string;
begin
  S:='select sql from sqlite_master where type=''table'' and name=''%s''';
  S:=S.Format([FDisplayName]);
  Q:=TSQLiteDB(FRootItem).GetDS(S);
  Q.Open;
  if not Q.IsEmpty then begin
    Result:=Q.Fields[0].AsString;
  end else
    Result:='';
  TSQLiteDB(FRootItem).CloseDS(Q);
end;

procedure TSQLiteTable.UpdateChilds;
begin
  FreeAndNil(FData);
  CreateData;
end;

{ TSQLiteTableList }

procedure TSQLiteTableList.CreateChildren;
var Q:TSQLQuery;
    st:TSQLiteTable;
begin
  //Log('SQLiteTableList - Create Children');
  if FItems = nil then begin
    FItems:=TDBItemsList.Create(True);
  end else begin
    Log('SQLiteTableList - Children not Empty');
    Exit;
  end;
  FDisplayName:='Tables';
  Q:=TSQLiteDB(FRootItem).GetDS('select name from sqlite_master where type = ''table'' and name <> ''sqlite_sequence''');
  try
    while not Q.EOF do begin
      st:=TSQLiteTable.Create(FRootItem);
      st.FDisplayName:=Q.Fields[0].AsString;
      FItems.Add(st);
      //st.UpdateChilds;
      Q.Next;
    end;
  finally
    TSQLiteDB(FRootItem).CloseDS(Q);
  end;
end;

function TSQLiteTableList.HasChildren: boolean;
var Q:TSQLQuery;
begin
  //Log('SQLiteTableList - Has Children');
  Result:=False;
  try
    Q:=TSQLiteDB(FRootItem).GetDS('select count(*)from sqlite_master where type = ''table'' and name <> ''sqlite_sequence''');
    if not Q.EOF then
      Result:=Q.Fields[0].AsInteger <> 0;
  finally
    TSQLiteDB(FRootItem).CloseDS(Q);
  end;
end;

{ TSQLiteDB }

function TSQLiteDB.GetDS(ASQL: string): TSQLQuery;
begin
  Result:=TSQLQuery.Create(nil);
  Result.DataBase:=FConnection;
  if ASQL<>'' then begin
    Result.SQL.Text:=ASQL;
    Result.Active:=True;
  end;
end;

procedure TSQLiteDB.CloseDS(AQuery: TSQLQuery);
//var T:TDBTransaction;
begin
  AQuery.Active:=False;
  AQuery.Free;
end;

procedure TSQLiteDB.CreateChildren;
var il:TItemsList;
begin
  //тут создаем узлы таблиц, индексов и так далее
  //Log('TableList - CreateChildren');
  if FItems = nil then
    FItems:=TDBItemsList.Create(True)
  else
    Exit;
  il:=TSQLiteTableList.Create(Self,mtTable);
  FItems.Add(il);
end;

constructor TSQLiteDB.Create(AConnection: TSQLite3Connection);
begin
  FConnection := AConnection;
  FDisplayName:=ExtractFileName(FConnection.DatabaseName);
  UpdateChilds;
end;


{ TItemsList }

function TItemsList.GetDB: TSQLiteDB;
begin
  Result:=TSQLiteDB(FRootItem);
end;

function TItemsList.GetChild(I: integer): TDBBaseItem;
begin
  Result:=FItems[I];
end;

function TItemsList.GetChildCount: integer;
begin
  Result:=FItems.Count;
end;

constructor TItemsList.Create(ARoot: TDBBaseItem; AMetaType: TMetaType);
begin
  inherited Create(ARoot, AMetaType);
  FItems:=TDBItemsList.Create(True);
  UpdateChilds;
end;

initialization
  AddConnType(TSQLiteConnType.Create);

end.

