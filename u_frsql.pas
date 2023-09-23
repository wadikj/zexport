unit u_frSQL;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, IBConnection, SQLite3Conn, Forms, Controls,
  ComCtrls, ExtCtrls, DBGrids, Menus, SynEdit, SynHighlighterSQL, fgl, u_MetaInfo;

type
  {
  можно реализовать протокол для кастмных пунктов меню в дереве объектов БД
  следующим образом
  действия после выполнения элемента меню
  TAfterExecAction = (aeUpdateSQL, aeExecSQL, aeUpdateChildren, aeUpdateParent, aeUpdateItem);
  TAfterExecActions = set of TAfterExecAction;
  обновить поле SQL запроса, выполнить запрос, обновить список детей, обновить список детей у родителя,
  обновить тек элемент (FData)

  в TDBBaseItem добавить

  DoGetMenuItem(var AText:string; var AIndex:integer; var AHandler:TDBItemHandler); - возвращает текст для
  нового пункта меню, в Aindex лежит значение, которое пихается в этото новый пункт меню
  (или для внутреннего итератора), Handler - то, что вызывается при нажатии на этот пункт меню

  и для каждого пункта написать процедуру вида

  procedure TDBItemHandler(var Actions:TAfterExecActions, var SQL:TStrings = nil) of object;

  объявить свой тип менюитема с полем для хранения этого хандлера
  TExMenuItem = class(TMenuItem)
    FHandler:TDBItemHandler;
    procedure Click(Sender:TObject);override;
    begin
      FHandler(Actions,SQL);
      if aeUpdateSQL in Actions then .....
      if aeExecSQL in Action then ...
      if {еще 3 путнка}

    end;

  end;


  и при создании меню в OnPopup сначала валим старые TExMenuItem, а потом вызывать у
  TMyTreeNode.FDBItem  DoGetMenuItem, пока AHandler не станет nil или AText <> '', и
  создавать новые
  у меню убрать все пункты, кроме Update, все остальное создавать руками

  }

  TDBBaseItem = class;

  TConnectionType = class;

  TColSizes = specialize TFPGMap<string, Integer>;

  TDBItemsList = specialize TFPGObjectList<TDBBaseItem>;
  //list of  active connections

  { TConnectionInfo }

  TConnectionInfo = class  //support connection with current DB
    private
      FMetaData: TMetaData;
    protected
      procedure GetNamesList(AMetaType:TMetaType; AList:TStrings; UseFlag:Boolean);virtual;
      procedure FillObject(AMetaObject:TBaseMetaInfo);virtual;
    public
      FRefCount:Integer;
      FConnection:TSQLConnection;
      FDBPath:string;
      FName:string;
      FConnType:TConnectionType;
      FExtraData:TStrings;
      FCols:TColSizes;
      constructor Create;virtual;
      procedure InitCols;
      procedure SaveCols;
      destructor Destroy;override;
      property MetaData:TMetaData read FMetaData;
  end;

  TConnectionList = specialize TFPGMap<string, TConnectionInfo>;

  //list of conections types
  //one per any connection type (create on program stated)
  { TConnectionType }

  TConnectionType = class
    protected
      function GetTypeName:string; virtual;abstract;
      function InternalCreateInfo(AConnData:string):TConnectionInfo;virtual;abstract;
      function GetMultiTransactions: boolean;virtual;abstract;
    public
      constructor Create;virtual;
      destructor Destroy; override;
      property TypeName:string read GetTypeName;
      //AConnData = FName - лезет в ини, и по инфе оттуда создает соединение
      //но сначала смотрит в списке открытых
      function GetConnection(AConnName:string):TConnectionInfo;
      function GetDBItem(AInfo:TConnectionInfo):TDBBaseItem;virtual;abstract;
      property MultiTransactions:boolean read GetMultiTransactions;
  end;

  TCTypesList = specialize TFPGMap<string, TConnectionType>;

  TMyTreeNode = class (TTreeNode)
    public
      FDBItem:TDBBaseItem;
  end;

  TMyTreeNodeClass = class of TMyTreeNode;

  { TfrSQL }

  TfrSQL = class(TFrame)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    ImageList1: TImageList;
    lv: TListView;
    miDataSQL: TMenuItem;
    miShowSQL: TMenuItem;
    miUpdate: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    PopupMenu1: TPopupMenu;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    SQ: TSQLQuery;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    tbCommit: TToolButton;
    tbRollback: TToolButton;
    TR: TSQLTransaction;
    syn: TSynEdit;
    SynSQLSyn1: TSynSQLSyn;
    ToolBar1: TToolBar;
    tbOpen: TToolButton;
    tbRun: TToolButton;
    tv: TTreeView;
    procedure DBGrid1ColumnSized(Sender: TObject);
    procedure miDataSQLClick(Sender: TObject);
    procedure miShowSQLClick(Sender: TObject);
    procedure miUpdateClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure SQLQuery1typeGetText(Sender: TField; var aText: string;
      DisplayText: Boolean);
    procedure tbOpenClick(Sender: TObject);
    procedure tbRollbackClick(Sender: TObject);
    procedure tbRunClick(Sender: TObject);
    procedure tbCommitClick(Sender: TObject);
    procedure tvCreateNodeClass(Sender: TCustomTreeView;
      var NodeClass: TTreeNodeClass);
    procedure tvExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure tvSelectionChanged(Sender: TObject);
  private
    FConnInfo:TConnectionInfo;
    FRootItem:TDBBaseItem;
    FInitColSizes,
    FSized:TColSizes;
    procedure InitFrame;
    procedure RCreateNode(ARoot:TMyTreeNode);
    procedure CheckColSizes;
    procedure SaveColSizes;
    procedure InitColSizes;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TItemFeature = (ifUpdateChildren, ifGetSelect, ifGetSQL);
  TItemFeatures = set of TItemFeature;


  //переделать логику работы на выдачу данных по требованию, а не заполнять все сразу
  //change RCreateNode
  //use tv.OnExpanding
  //CreateChildren - создает детей, если их нет
  //UpdateCildren - тупо валит детей, и приваивает полям nil
  //иначе будет жопа на больших БД с кучей таблиц

  {В потомках надо переопределить - тип поддерживаемых данных
  и имеются ли дети
  если у нас объект содержит что то сложное, то переопределяем
  CreateChildren
  возможно, сначала переопределяем базу для корректных ссылок и вставку туда
  нужного ConnectionInfo, а потом переопределяем списочный и единичный итемы
  }

  { TDBBaseItem }

  TDBBaseItem = class
    protected
      FRootItem:TDBBaseItem;
      FItems:TDBItemsList;
      FData:TStrings;
      function GetChild(I: integer): TDBBaseItem;virtual;
      function GetChildCount: integer;virtual;
      function GetDataCount: integer;virtual;
      function GetDataItem(I: Integer): string;virtual;
      function GetSupported: TItemFeatures;virtual;
    protected
      FDisplayName: string;
      FMetaSupport:TMetaType;
      procedure CreateChildren;virtual;
      procedure CreateData;virtual;
      function HasChildren:boolean;virtual;
      function HasData:boolean;virtual;
    public
      constructor Create(ARoot: TDBBaseItem=nil; AMetaType:TMetaType = mtUnk); virtual;
      destructor Destroy; override;
      property DisplayName:string read FDisplayName;
      property ChildCount:integer read GetChildCount;
      property Child[I:integer]:TDBBaseItem read GetChild;
      property DataCount:integer read GetDataCount;
      property DataItem[I:Integer]:string read GetDataItem;
      procedure UpdateChilds;virtual;
      //features support
      property Supported:TItemFeatures read GetSupported;
      function GetSelect:string;virtual;
      function GetSQL:string;virtual;

  end;

procedure AddConnType(AConnType:TConnectionType);
function ConnTypesCount:Integer;
function GetConnType(Index:Integer):TConnectionType;
procedure FillDBTypes(AList:TStrings);

procedure FillDBList(AList:TStrings);
function GetSQLConnection(AName:string):TSQLConnection;


procedure CreateDB(ADB,AType:string);


procedure CreateSQLFrame(ADB:string; AType:string = '');

procedure Log(S:string);

implementation

uses {u_sqliteinfo, }main, u_data, Dialogs, math;

{$R *.lfm}

var FConnList:TConnectionList = nil;
    FCTypesList:TCtypesList = nil;

const EmptyNodeCaption = 'CDBF768B-37D6-4D92-B6A6-F9073461F63C';

procedure AddConnType(AConnType: TConnectionType);
begin
  if FCTypesList = nil then
    FCTypesList:=TCtypesList.Create;
  FCTypesList.Add(AConnType.TypeName, AConnType);
end;

function ConnTypesCount: Integer;
begin
  Result:=0;
  if FCTypesList<>nil then
    Result:=FConnList.Count;
end;

function GetConnType(Index: Integer): TConnectionType;
begin
  Result:=FCTypesList.Data[Index];
end;

procedure FillDBTypes(AList: TStrings);
var
  I: Integer;
begin
  for I:=0 to FCTypesList.Count-1 do
    AList.Add(FCTypesList.Keys[I]);
end;

procedure FillDBList(AList: TStrings);
var
  I: Integer;
begin
  if FConnList=nil then Exit;
  if FConnList.Count = 0 then Exit;
  for I:=0 to FConnList.Count-1 do
    AList.Add(FConnList.Keys[I]);
end;

function GetSQLConnection(AName: string): TSQLConnection;
var
  I: Integer;
begin
  Result:=nil;
  if FConnList=nil then Exit;
  if FConnList.Count = 0 then Exit;
  for I:=0 to FConnList.Count-1 do
    if AName=FConnList.Keys[I] then begin
      Result:=FConnList.Data[I].FConnection;
      Break;
    end;
end;

procedure CreateDB(ADB, AType: string);
var sa:TStringArray;
    ct:TConnectionType;
    ci:TConnectionInfo;
begin
  if AType = '' then begin
    sa:=ADB.Split(['(',')']);
    ADB:=sa[0];
    AType:=sa[1];
  end;
  Log('name=%s, type=%s'.Format([ADB,AType]));
  ct:=FCTypesList.KeyData[AType];
  if ct=nil then begin
    Log('this connection type not found!!!');
    Exit;
  end;
  ci:=ct.GetConnection(ADB);
  if ci=nil then begin
    Log('can''t create connection - connection info not found!!!');
    Exit;
  end;
  ci.FConnection.CreateDB;
end;

procedure CreateSQLFrame(ADB: string; AType: string);
var sa:TStringArray;
    ct:TConnectionType;
    ci:TConnectionInfo;
    f:TfrSQL;
begin
  if AType = '' then begin
    sa:=ADB.Split(['(',')']);
    ADB:=sa[0];
    AType:=sa[1];
  end;
  Log('name=%s, type=%s'.Format([ADB,AType]));
  ct:=FCTypesList.KeyData[AType];
  if ct=nil then begin
    Log('this connection type not found!!!');
    Exit;
  end;
  ci:=ct.GetConnection(ADB);
  if ci=nil then begin
    Log('can''t create connection - connection info not found!!!');
    Exit;
  end;
  f:=(frmMain.CreateFrame(TfrSQL,'SQL of ' + ADB) as TfrSQL);
  f.FConnInfo:=ci;
  try
    f.InitFrame;
  except;
    Log('error create frame!!!');
  end;
end;

procedure Log(S: string);
begin
  if frmMain<>nil then
    frmMain.Log('db',S);
end;

{ TConnectionType }

constructor TConnectionType.Create;
begin

end;

destructor TConnectionType.Destroy;
begin
  inherited Destroy;
end;

function TConnectionType.GetConnection(AConnName: string): TConnectionInfo;
var Key:string;
    I:Integer;
begin
  //ищем в списке активных
  //по имени коннекта идем в ини и достаем оттуда данные
  //по ним ищем в списке активных (ключ - "Name(Type)", напр "Histiry(SQLite)")
  //если нашли - аддреф и выдаем
  //если нет - вызываем InternameCreate и возвр что получилось
  Key:=AConnName + '('+GetTypeName+')';
  if FConnList.Find(Key,I) then begin
    Result:=FConnList.Data[I];
    Inc(Result.FRefCount);
    Exit;
  end;
  Result:=InternalCreateInfo(AConnName);
  Result.InitCols;
  FConnList.KeyData[Key]:=Result;
  Inc(Result.FRefCount);
end;

{ TConnectionInfo }

procedure TConnectionInfo.GetNamesList(AMetaType: TMetaType; AList: TStrings;
  UseFlag: Boolean);
begin
  raise EInvalidObject.Create('GetNamesList not implemented');
end;

procedure TConnectionInfo.FillObject(AMetaObject: TBaseMetaInfo);
begin
  raise EInvalidObject.Create('FillObject not implemented');
end;

constructor TConnectionInfo.Create;
begin
  FRefCount:=0;
  FDBPath:='';
  FName:='';
  FConnection:=nil;
  FConnType:=nil;
  FExtraData:=nil;
  FCols:=TColSizes.Create;
  FMetaData:=TMetaData.Create;
  FMetaData.OnFillObject:=@FillObject;
  FMetaData.OnGetNames:=@GetNamesList;
end;

procedure TConnectionInfo.InitCols;
var dbc:TDBColItem;
    I:Integer;
begin
  dbc:=Options.GetDBInfo(FName,FConnType.TypeName);
  if dbc = nil then Exit;
  for I:=0 to dbc.ColCount-1 do
    FCols[dbc.Columns[I].ColName]:=dbc.Columns[I].ColWidth;
end;

procedure TConnectionInfo.SaveCols;
var dbc:TDBColItem;
    I,J:Integer;
    cw:TDBColWidth;
begin
  dbc:=Options.GetDBInfo(FName,FConnType.TypeName);
  if dbc = nil then Exit;
  for I:=0 to dbc.ColCount-1 do begin
    J:=FCols.IndexOf(dbc.Columns[i].ColName);
    if J<>-1 then begin
      dbc.Columns[I].ColWidth:=FCols.Data[J];
      FCols.Delete(J);
    end;
  end;
  for I:=0 to FCols.Count-1 do begin
    cw:=dbc.NewCol;
    cw.ColName:=FCols.Keys[I];
    cw.ColWidth:=FCols.Data[I];
  end;
  FCols.Clear;
end;

destructor TConnectionInfo.Destroy;
begin
  FConnection.Free;
  FExtraData.Free;
  SaveCols;
  FCols.Free;
  inherited Destroy;
end;

{ TDBBaseItem }

function TDBBaseItem.GetSupported: TItemFeatures;
begin
  Result:=[ifUpdateChildren];
end;

procedure TDBBaseItem.CreateChildren;
begin
  //must be empty
end;

procedure TDBBaseItem.CreateData;
begin
  //must be empty
end;

function TDBBaseItem.HasChildren: boolean;
begin
  Result:=True;
end;

function TDBBaseItem.HasData: boolean;
begin
  Result:=False;
end;

function TDBBaseItem.GetChild(I: integer): TDBBaseItem;
begin
  Result:=nil;
end;

function TDBBaseItem.GetChildCount: integer;
begin
  if FItems = nil then
    CreateChildren;
  if FItems = nil then begin
    Result := 0;
    Exit;
  end;
  Result:=FItems.Count;
end;

function TDBBaseItem.GetDataCount: integer;
begin
  if FData = nil then
    CreateData;
  if FData = nil then
    Result:=0
  else
    Result:=FData.Count;
end;

function TDBBaseItem.GetDataItem(I: Integer): string;
begin
  if FData<> nil then
    Result:=FData[I]
  else
    Result:='';
end;

constructor TDBBaseItem.Create(ARoot: TDBBaseItem; AMetaType: TMetaType);
begin
  FRootItem:=ARoot;
  FItems:=nil;
  FData:=nil;
  FMetaSupport:=AMetaType;
  FDisplayName:=MetaNames[FMetaSupport];
end;

destructor TDBBaseItem.Destroy;
begin
  //вальнуть детей
  FreeAndNil(FItems);
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TDBBaseItem.UpdateChilds;
begin
  FreeAndNil(FItems);
  FreeAndNil(FData);
  CreateChildren;
  CreateData;
end;

function TDBBaseItem.GetSelect: string;
begin
  Result:='';
end;

function TDBBaseItem.GetSQL: string;
begin
  Result:='';
end;


{ TfrSQL }

procedure TfrSQL.SQLQuery1typeGetText(Sender: TField; var aText: string;
  DisplayText: Boolean);
begin
  if Sender is TMemoField then begin
    aText:=TMemoField(Sender).Value;
  end;
end;

procedure TfrSQL.PopupMenu1Popup(Sender: TObject);
var bi:TDBBaseItem;
begin
  //в зависимости от выделенного элемента скрывем или показываем меню
  if tv.Selected<> nil then begin
    bi:=TMyTreeNode(tv.Selected).FDBItem;
    miUpdate.Visible:=ifUpdateChildren in bi.Supported;
    miDataSQL.Visible:=ifGetSelect in bi.Supported;
    miShowSQL.Visible:=ifGetSQL in bi.Supported;
  end;
end;

procedure TfrSQL.miShowSQLClick(Sender: TObject);
begin
  if tv.Selected<>nil then begin
    syn.Lines.Text:=TMyTreeNode(tv.Selected).FDBItem.GetSQL;
  end;
end;

procedure TfrSQL.miUpdateClick(Sender: TObject);
var bi:TDBBaseItem;
begin
  if tv.Selected=nil then Exit;
  bi:=TMyTreeNode(tv.Selected).FDBItem;
  bi.UpdateChilds;
  tv.Selected.DeleteChildren;
  RCreateNode(TMyTreeNode(tv.Selected));
end;

procedure TfrSQL.miDataSQLClick(Sender: TObject);
begin
  if tv.Selected<>nil then begin
    syn.Lines.Text:=TMyTreeNode(tv.Selected).FDBItem.GetSelect;
  end;
end;

function IfThen(b:boolean; a1:string; a2:string = ''):string;
begin
  if b then result:=a1
  else result:=a2
end;

procedure TfrSQL.DBGrid1ColumnSized(Sender: TObject);
var
  i: Integer;
begin
  //Log(Sender.ClassName + ' - rezized');
  CheckColSizes;
end;

procedure TfrSQL.tbOpenClick(Sender: TObject);
var
  I: Integer;
begin
  SaveColSizes;
  SQ.Active:=False;
  SQ.SQL.Text:=syn.Text;
  try
    SQ.Open;
    InitColSizes;
    for I:=0 to SQ.FieldCount-1 do begin
      if SQ.Fields[I] is  TMemoField then
        SQ.Fields[i].OnGetText:=@SQLQuery1typeGetText;
    end;
  finally
  end;
end;

procedure TfrSQL.tbRollbackClick(Sender: TObject);
begin
  SaveColSizes;
  if SQ.Transaction is TSQLTransaction then
    TSQLTransaction(SQ.Transaction).Rollback;
end;

procedure TfrSQL.tbRunClick(Sender: TObject);
begin
  SaveColSizes;
  SQ.Active:=False;
  SQ.SQL.Text:=syn.Text;
  try
    SQ.ExecSQL;
  except
    on E:Exception do
      ShowMessage('При выполнении запроса произошла ошибка:'+#13 + E.Message);
  end;
end;

procedure TfrSQL.tbCommitClick(Sender: TObject);
begin
  SaveColSizes;
  if SQ.Transaction is TSQLTransaction then
    TSQLTransaction(SQ.Transaction).Commit;
end;

procedure TfrSQL.tvCreateNodeClass(Sender: TCustomTreeView;
  var NodeClass: TTreeNodeClass);
begin
  NodeClass:=TMyTreeNode;
end;

procedure TfrSQL.tvExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
var N:TTreeNode;
    MN, CN:TMyTreeNode;
    di:TDBBaseItem;
    I:Integer;
begin
  N:=Node.GetFirstChild;
  if (N=nil) then Exit;
  if N.Text <> EmptyNodeCaption then Exit;
  N.Delete;
  MN:=TMyTreeNode(Node);
  for I:=0 to TMyTreeNode(Node).FDBItem.ChildCount-1  do begin
    di:=MN.FDBItem.Child[I];
    CN:=TMyTreeNode(tv.Items.AddChild(Node, di.DisplayName));
    CN.FDBItem:=di;
    if di.HasChildren then
      tv.Items.AddChild(CN, EmptyNodeCaption);
  end;
end;

procedure TfrSQL.tvSelectionChanged(Sender: TObject);
var mn:TMyTreeNode;
    li:TListItem;
    I: Integer;
begin
  mn:=TMyTreeNode(tv.Selected);
  if mn=nil then exit;
  try
    lv.Items.BeginUpdate;
    lv.Items.Clear;
    //if mn.FDBItem.DataCount=0 then Exit;
    for I:=0 to mn.FDBItem.DataCount-1 do begin
      li:=lv.Items.Add;
      li.Caption:=mn.FDBItem.DataItem[I];
    end;
  finally
    lv.Items.EndUpdate;
  end;
end;

procedure TfrSQL.InitFrame;
var T:TMyTreeNode;
begin
  //настройка датасетов
  SQ.DataBase:=FConnInfo.FConnection;
  if FConnInfo.FConnType.MultiTransactions then begin
    TR.DataBase:=FConnInfo.FConnection;
    SQ.Transaction:=TR;
  end else
    SQ.Transaction:=FConnInfo.FConnection.Transaction;
  FRootItem:=FConnInfo.FConnType.GetDBItem(FConnInfo);
  //насройка дерева
  T:=TMyTreeNode(tv.Items.Add(nil,FRootItem.DisplayName));
  T.FDBItem:=FRootItem;
  T.Owner.AddChild(T,EmptyNodeCaption);
  //RCreateNode(T);
end;

procedure TfrSQL.RCreateNode(ARoot: TMyTreeNode);
var I:Integer;
    mn:TMyTreeNode;
begin
   for I:=0 to ARoot.FDBItem.ChildCount-1 do begin
    mn:=TMyTreeNode(tv.Items.AddChild(ARoot,ARoot.FDBItem.Child[I].DisplayName));
    mn.FDBItem:=ARoot.FDBItem.Child[I];
    RCreateNode(mn);
  end;
end;

procedure TfrSQL.CheckColSizes;
var I:Integer;
begin
  //вызывается при получении обытия об изменении размеров колонок
  //сравнивает начальные размеры с текущими, и если есть разница - пихает их в
  //измененные
  for I:=0 to DBGrid1.Columns.Count-1 do begin
    if DBGrid1.Columns[I].Width<>FInitColSizes.KeyData[DBGrid1.Columns[I].FieldName] then begin
      FSized[DBGrid1.Columns[I].FieldName]:=DBGrid1.Columns[I].Width;
      //Log('sized - '+DBGrid1.Columns[I].FieldName)
    end;
  end;
end;

procedure TfrSQL.SaveColSizes;
var I:Integer;
    S:string;
begin
  for i:=0 to FSized.Count-1 do begin
    FConnInfo.FCols.KeyData[FSized.Keys[I]]:=FSized.Data[I];
    S:=S + ' - ' + FSized.Keys[I]+'('+IntToStr(FSized.Data[I])+')';
  end;
  //Log('saved' + S);
end;

procedure TfrSQL.InitColSizes;
var I,J:Integer;
    S,S1:string;
begin
  FInitColSizes.Clear;
  FSized.Clear;
  if not DBGrid1.DataSource.DataSet.Active then Exit;
  for I:=0 to DBGrid1.Columns.Count-1 do begin
    FInitColSizes[DBGrid1.Columns[i].FieldName]:= DBGrid1.Columns[I].Width;
    S:=S + ' - ' + DBGrid1.Columns[i].FieldName+'('+IntToStr(FInitColSizes.KeyData[DBGrid1.Columns[i].FieldName])+')';
  end;
  //Log('inited'+S);
  S:='';
  for I:=0 to DBGrid1.Columns.Count-1 do begin
    J:=FConnInfo.FCols.IndexOf(DBGrid1.Columns[I].FieldName);
    if J<>-1 then begin
      DBGrid1.Columns[I].Width:=FConnInfo.FCols.Data[J];
      S:=S+' - ' + DBGrid1.Columns[I].FieldName+'('+IntToStr(FConnInfo.FCols.Data[J])+')';
    end;
  end;
  //Log('changed'+S);
end;

constructor TfrSQL.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Font.Size:=Options.IntfFont;
  tv.Font.Size:=Options.TreeFont;
  lv.Font.Size:=Options.TreeFont;
  syn.Font.Size:=Options.EditFont;
  FInitColSizes:=TColSizes.Create;
  FSized:=TColSizes.Create;
end;

destructor TfrSQL.Destroy;
var T:TSQLTransaction;
begin
  inherited Destroy;
  FreeAndNil(FRootItem);
  FConnInfo.FRefCount:=FConnInfo.FRefCount-1;
  FInitColSizes.Free;
  FSized.Free;
  if FConnInfo.FRefCount <=0 then begin
    FConnInfo.FConnection.CloseTransactions;
    FConnInfo.FConnection.Close(True);
    FConnInfo.SaveCols;
    //походу тут неправильно удаляется транзакция в случае, когда их много

    T:=FConnInfo.FConnection.Transaction;
    FConnInfo.FConnection.Transaction:=nil;
    T.Free;
    FConnList.Remove(FConnInfo.FName + '(' + FConnInfo.FConnType.TypeName+')');//тут его и валят заодно
    FConnInfo:=nil;
  end;
end;

initialization
  FConnList:=TConnectionList.Create;
  FConnList.Sorted:=True;

finalization
  FCTypesList.Clear;
  FreeAndNil(FCTypesList);
  FreeAndNil(FConnList);

end.

