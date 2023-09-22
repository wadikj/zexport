unit u_fbinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, u_frSQL, IBConnection, SQLDB, DB, u_MetaInfo;


type

  TGetNamesProc   = procedure (AList:TStrings; UseFlag:Boolean) of object;
  TFillObjectProc = procedure (AMetaObject:TBaseMetaInfo) of object;

  { TFBConnectionInfo }

  TFBConnectionInfo = class(TConnectionInfo)
    protected
      FGet: array [TMetaType] of TGetNamesProc;
      FFill: array [TMetaType] of TFillObjectProc;

      procedure GetNamesList(AMetaType:TMetaType; AList:TStrings; UseFlag:Boolean);override;
      procedure FillObject(AMetaObject:TBaseMetaInfo);override;

      procedure GetDomainList(AList:TStrings; UseFlag:Boolean);
      procedure FillDomain(ADomain:TBaseMetaInfo);

      procedure GetViewList(AList:TStrings; UseFlag:Boolean);
      procedure FillView(AView:TBaseMetaInfo);

      procedure FillField(AField:TBaseMetaInfo);

      procedure GetIndexList(AList:TStrings; UseFlag:Boolean);
      procedure FillIndex(AIndex:TBaseMetaInfo);

      procedure GetGenList(AList:TStrings; UseFlag:Boolean);
      procedure FillGen(AGen:TBaseMetaInfo);


    public
      constructor Create;override;
      function GetDS(ASQL:string):TSQLQuery;
      procedure CloseDS(AQuery:TSQLQuery);
  end;

  TFBDB = class;

  { TFBConnType }

  TFBConnType = class (TConnectionType)
    protected
      function GetTypeName:string; override;
      function InternalCreateInfo(AConnData:string):TConnectionInfo;override;
      function GetMultiTransactions: boolean;override;
    public
      function GetDBItem(AInfo:TConnectionInfo):TDBBaseItem;override;
  end;

  { TFBItem }

  TFBItem = class(TDBBaseItem)
    protected
      function GetDB: TFBDB;
      function GetChild(I: integer): TDBBaseItem;override;
    public
      property DB:TFBDB read GetDB;
  end;

  { TFBDB }

  TFBDB = class(TFBItem)
    private
      FBConnInfo:TFBConnectionInfo;
      function GetDS(ASQL:string):TSQLQuery;
      procedure CloseDS(AQuery:TSQLQuery);
    protected
      procedure CreateChildren;override;
    public
      constructor Create(AConnection:TIBConnection);
  end;


  //эти 2 класса пееропределяются только в случае, если они должны поддерживать
  //иное взаимодействие с пользователем, нежели базовое

  { TFBItemsList }

  TFBItemsList = class(TFBItem)
    protected
      function HasData: boolean; override;
      procedure CreateChildren;override;
  end;

  { TFBChildItem }

  TFBChildItem = class(TFBItem)
    protected
      function HasData: boolean; override;
      function HasChildren: boolean; override;
      procedure CreateData; override;
  end;

  //класы ниже надо завалить
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


implementation

uses u_data;


{  TDataType = (dtUnk, dtSmallInt, dtInteger, dtBigInt, dtFloat, dtDate, dtTime,
    dtTimeStamp, dtChar, dtVarChar, dtDoublePrec, dtBlob, dtDecimal, dtNumeric);
}
{ TFBChildItem }

function TFBChildItem.HasData: boolean;
begin
  Result:=True;
end;

function TFBChildItem.HasChildren: boolean;
begin
  Result:=False;
end;

procedure TFBChildItem.CreateData;
var mi:TBaseMetaInfo;
begin
  if FData<>nil then Exit;
  mi:=TFBDB(FRootItem).FBConnInfo.MetaData.GetTypedObject(FMetaSupport,FDisplayName);
  if mi=nil then Exit;
  FData:=mi.GetData(0);
end;

{ TFBItemsList }

function TFBItemsList.HasData: boolean;
begin
  Result:=False;
end;

procedure TFBItemsList.CreateChildren;
var SL:TStringList;
    I:Integer;
    T:TFBChildItem;
begin
  Log('Create Children - ' + MetaNames[FMetaSupport]);
  if FItems<>nil then Exit;
  FItems:=TDBItemsList.Create(True);
  SL:=TFBDB(FRootItem).FBConnInfo.MetaData.GetNamesList(FMetaSupport);
  if SL=nil then Exit;
  for I:=0 to SL.Count-1 do begin
    T:=TFBChildItem.Create(Self.FRootItem, FMetaSupport);
    T.FDisplayName:=SL[I];
    FItems.Add(T);
  end;
  SL.Free;
end;

{ TFBIndex }

{ TFBConnectionInfo }

procedure TFBConnectionInfo.GetNamesList(AMetaType: TMetaType; AList: TStrings;
  UseFlag: Boolean);
var Proc:TGetNamesProc;
begin
  Proc:=FGet[AMetaType];
  if Assigned(Proc) then
    Proc(AList,UseFlag);
end;

procedure TFBConnectionInfo.FillObject(AMetaObject: TBaseMetaInfo);
var Proc:TFillObjectProc;
begin
  Proc:=FFill[AMetaObject.MetaType];
  if Assigned(Proc) then
    Proc(AMetaObject)
  else
    Log('Procedure Fill not defined for object named '+AMetaObject.Name);
end;

procedure TFBConnectionInfo.GetDomainList(AList: TStrings; UseFlag: Boolean);
var SQL:string;
    DS:TSQLQuery;
    S,S1:string;
begin
  //name:sf:sn
  SQL:='select RDB$FIELD_NAME, rdb$system_flag from rdb$fields where rdb$system_flag <> 1';
  DS:=GetDS(SQL);
  while not DS.EOF do begin
    S:=DS.Fields[0].AsString.Trim();
    if UseFlag then begin
      if (not DS.Fields[1].IsNull) and (DS.Fields[1].AsInteger=1) then
        S1:='1'
      else S1:='0';
      S:=S+':'+S1;
      if Pos('RDB$',S) = 1 then S1:='1'
      else S1:='0';
      S:=S+':'+S1;
    end;
    AList.Add(S);
    DS.Next;
  end;
  CloseDS(DS);
end;

procedure TFBConnectionInfo.FillDomain(ADomain: TBaseMetaInfo);
var DI:TDomainInfo absolute ADomain;
    SQL:string;
    DS:TSQLQuery;
    F:TField;
    V:Integer;
begin
  ADomain.Loaded:=True;
  SQL:='select RDB$FIELD_NAME, rdb$validation_source, rdb$computed_source, rdb$default_source, rdb$field_length, '+
     'rdb$field_scale, rdb$field_type, rdb$field_sub_type, rdb$null_flag, '+
     'rdb$character_length, rdb$field_precision '+
     ' from rdb$fields where RDB$FIELD_NAME='''+ADomain.Name+'''';
  DS:=GetDS(SQL);
  if DS.RecordCount<>1 then begin
    EInvalidObject.CreateFmt('Domain %s have error info in meta tables', [ADomain.Name]);
  end;
  DI.Check:=DS.FieldByName('rdb$validation_source').AsString;
  DI.Computed:=DS.FieldByName('rdb$computed_source').AsString;
  DI.DefValue:=DS.FieldByName('rdb$default_source').AsString;
  DI.DataLen:=DS.FieldByName('rdb$field_length').AsInteger;
  F:=DS.FieldByName('RDB$NULL_FLAG');
  if not (f.IsNull) and (F.AsInteger=1) then
    DI.NullFlag:=True;
  F:=DS.FieldByName('RDB$FIELD_TYPE');
  case F.AsInteger of
    7:DI.DataType:=dtSmallInt;
    8:DI.DataType:=dtInteger;
    10:DI.DataType:=dtFloat;
    12:DI.DataType:=dtDate;
    13:DI.DataType:=dtSmallInt;
    14:DI.DataType:=dtChar;
    16:DI.DataType:=dtBigInt;
    27:DI.DataType:=dtDoublePrec;
    35:DI.DataType:=dtTimeStamp;
    37:DI.DataType:=dtVarChar;
    261:DI.DataType:=dtBlob;
  end;
  F:=DS.FieldByName('RDB$FIELD_SUB_TYPE');
  V:=0;
  if not F.IsNull then V:=F.AsInteger;
  DI.SubType:=V;
  DI.Precision:=DS.FieldByName('rdb$field_precision').AsInteger;
  DI.Scale:=-DS.FieldByName('rdb$field_scale').AsInteger;
  if (DI.Scale<>0) or (DI.Precision<>0) then begin
    if DI.SubType=1 then DI.DataType:=dtNumeric;
    if DI.SubType=2 then DI.DataType:=dtDecimal;
  end;
end;

procedure TFBConnectionInfo.GetViewList(AList: TStrings; UseFlag: Boolean);
var SQL:string;
    DS:TSQLQuery;
    S:string;
begin
  //name:sf:sn
  SQL:='select rdb$view_name from rdb$view_relations';
  DS:=GetDS(SQL);
  while not DS.EOF do begin
    S:=DS.Fields[0].AsString.Trim();
    if UseFlag then begin
      S:=S+':0:0';
    end;
    AList.Add(S);
    DS.Next;
  end;
  CloseDS(DS);
end;

procedure TFBConnectionInfo.FillView(AView: TBaseMetaInfo);
var DS:TSQLQuery;
    S:string;
    F:TFieldInfo;
    V:TViewInfo absolute AView;
begin
  //поля вьюхи
  AView.Loaded:=True;
  S:='select RDB$FIELD_NAME from RDB$Relation_fields where rdb$relation_NAME='''
    +AView.Name+''' order by rdb$field_position';
  DS:=GetDS(S);
  while not DS.EOF do begin
    F:=V.AddField;
    F.Name:=DS.Fields[0].AsString.Trim;
    F.Table:=AView.Name;
    FillField(F);
    DS.Next;
  end;
  S:='select rdb$view_name, rdb$relation_name, rdb$view_context '+
    'from rdb$view_relations where rdb$view_name='''+AView.Name+''' '+
    'order by 3';
  DS.Close;
  DS.SQL.Text:=S;
  DS.Open;
  while not DS.EOF do begin
    V.Tables.Add(DS.FieldByName('rdb$relation_name').AsString.Trim);
    DS.Next;
  end;
  CloseDS(DS);
end;

procedure TFBConnectionInfo.FillField(AField: TBaseMetaInfo);
var SQL:string;
    FI:TFieldInfo absolute AField;
    DS:TSQLQuery;
begin
  SQL:='select rdb$field_name, RDB$FIELD_SOURCE, rdb$base_field, rdb$field_position, ' +
    'RDB$UPDATE_FLAG, RDB$NULL_FLAG, rdb$default_source, rdb$view_context '+
    'from RDB$RELATION_FIELDS where rdb$field_name = ''' + FI.Name+''' and '+
    'RDB$RELATION_NAME = '''+FI.Table+'''';
  DS:=GetDS(SQL);
  FI.DomainInfo:=DS.FieldByName('RDB$FIELD_SOURCE').AsString;
  FI.BaseField:=DS.FieldByName('rdb$base_field').AsString;
  FI.Position:=DS.FieldByName('rdb$field_position').AsInteger;
  FI.UpdateFlag:=DS.FieldByName('RDB$UPDATE_FLAG').AsInteger = 1;
  FI.NullFlag:=DS.FieldByName('RDB$NULL_FLAG').AsInteger=1;
  FI.DefValue:=DS.FieldByName('rdb$default_source').AsString;
  FI.ViewContext:=DS.FieldByName('rdb$view_context').AsInteger;
  FI.Loaded:=True;
end;

procedure TFBConnectionInfo.GetIndexList(AList: TStrings; UseFlag: Boolean);
var S:string;
    DS:TSQLQuery;
begin
  S:='select RDB$INDEX_NAME from rdb$indices WHERE RDB$SYSTEM_FLAG <> 1';
  DS:=GetDS(S);
  while not DS.EOF do begin
    S:=DS.FieldByName('RDB$INDEX_NAME').AsString.Trim;
    if UseFlag then begin
      S:=S+':0:';
      if Pos('RDB$',S)=1 then S:=S+'1'
      else S:=S+'0';
    end;
    AList.Add(S);
    DS.Next;
  end;
end;

procedure TFBConnectionInfo.FillIndex(AIndex: TBaseMetaInfo);
var S:string;
    DS:TSQLQuery;
    AI:TIndexInfo absolute AIndex;
begin
  S:='select RDB$INDEX_NAME, RDB$RELATION_NAME, RDB$UNIQUE_FLAG, RDB$INDEX_TYPE, '+
    ' RDB$FOREIGN_KEY from rdb$indices WHERE RDB$INDEX_NAME = '''+AIndex.Name+'''';
  DS:=GetDS(S);
  if DS.RecordCount<>1 then
    raise EInvalidObject('Invalid index '+AIndex.Name);
  AI.Askending:=DS.FieldByName('RDB$INDEX_TYPE').AsInteger<>1;
  AI.Unique:=DS.FieldByName('RDB$UNIQUE_FLAG').AsInteger=1;
  AI.TableName:=DS.FieldByName('RDB$RELATION_NAME').AsString;
  AI.ForeignKey:=DS.FieldByName('RDB$FOREIGN_KEY').AsString;
  DS.Close;
  DS.SQL.Text:='select rdb$field_name from rdb$index_segments '+
    ' where RDB$INDEX_NAME=''%s'' order by RDB$field_POSITION'.Format([AI.Name]);
  DS.Open;
  while not DS.EOF do begin
    S:=DS.Fields[0].AsString.Trim;
    AI.Fields.Add(S);
    DS.Next;
  end;
  CloseDS(DS);
end;

procedure TFBConnectionInfo.GetGenList(AList: TStrings; UseFlag: Boolean);
var Q:TSQLQuery;
    S:string;
begin
  Q:=GetDS('select rdb$generator_name from RDB$GENERATORS where RDB$SYSTEM_FLAG = 0');
  while not Q.EOF do begin
    S:=Q.Fields[0].AsString.Trim;
    if UseFlag then
      S:=S+':0:0';
    AList.Add(S);
    Q.Next;
  end;
  CloseDS(Q);
end;

procedure TFBConnectionInfo.FillGen(AGen: TBaseMetaInfo);
var gi:TGenInfo absolute AGen;
    DS:TSQLQuery;
begin
  DS:=GetDS(' select RDB$GENERATOR_NAME, rdb$generator_id from RDB$GENERATORS '+
      ' where RDB$GENERATOR_NAME = ''%s'' '.Format([AGen.Name]));
  gi.GenID:=DS.Fields[1].AsInteger;
  DS.Close;
  DS.SQL.Text:='select gen_id(%s, 0) from rdb$database '.Format([gi.Name]);
  DS.Open;
  gi.Value:=DS.Fields[0].AsInteger;
  CloseDS(DS);
end;

constructor TFBConnectionInfo.Create;
var I:TMetaType;
begin
  inherited Create;
  for I:=Low(TMetaType) to High(TMetaType) do begin
    FGet[I]:=nil;
    FFill[I]:=nil;
  end;
  FGet[mtDomain]:=@GetDomainList;
  FFill[mtDomain]:=@FillDomain;

  FGet[mtView]:=@GetViewList;
  FFill[mtView]:=@FillView;

  FGet[mtIndex]:=@GetIndexList;
  FFill[mtIndex]:=@FillIndex;

  FGet[mtGen]:=@GetGenList;
  FFill[mtGen]:=@FillGen;

end;

function TFBConnectionInfo.GetDS(ASQL: string): TSQLQuery;
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

procedure TFBConnectionInfo.CloseDS(AQuery: TSQLQuery);
var T:TDBTransaction;
begin
  AQuery.Active:=False;
  T:=AQuery.Transaction;
  AQuery.Transaction:=nil;
  T.Free;
  AQuery.Free;
end;

{ TFBGenerator }

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
  Result:=TFBConnectionInfo.Create;
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
  TFBDB(Result).FBConnInfo:=AInfo as TFBConnectionInfo;
  //Result.UpdateChilds;
end;


{ TFBTableList }

function TFBTableList.HasChildren: boolean;
var Q:TSQLQuery;
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
//var T:TSQLTransaction;
begin
  Result:=FBConnInfo.GetDS(ASQL);
end;

procedure TFBDB.CloseDS(AQuery: TSQLQuery);
//var T:TDBTransaction;
begin
  FBConnInfo.CloseDS(AQuery);
end;

procedure TFBDB.CreateChildren;
begin
  //таблицы, домены, вьюхи, процедуры, триггеры, генераторы, индексы
  Log('FBDB - CreateChildren');
  FRootItem:=nil;
  FMetaSupport:=mtUnk;
  if FItems <> nil then Exit;
  FItems:=TDBItemsList.Create(True);
  FItems.Add(TFBTableList.Create(Self));
  FItems.Add(TFBItemsList.Create(Self, mtView));
  FItems.Add(TFBItemsList.Create(Self,mtDomain));
  FItems.Add(TFBItemsList.Create(Self,mtIndex));
  FItems.Add(TFBItemsList.Create(Self,mtGen));
  FItems.Add(TFBItemsList.Create(Self,mtProc));
  FItems.Add(TFBItemsList.Create(Self,mtTrigger));
end;

constructor TFBDB.Create(AConnection: TIBConnection);
begin
  FDisplayName:=ExtractFileName(AConnection.DatabaseName);
end;

{ TFBItem }

function TFBItem.GetDB: TFBDB;
begin
  Result:=TFBDB(FRootItem);
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

