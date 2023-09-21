unit u_metainfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type

  {надо реализовать хранение информации о таблицах, вьюхах и индексах, а может о чем то еще,
  в виде набора спец классов вида
    TDomainInfo = class
      Name:string;
      DataType:TDataType;
      DataLen:Integer;
      Precision:Integer;
      Scale:Integer;
      NullFlag:boolean;
      Check:string;
      DefValue:string;
      Computed:string;
    end;

    TFieldInfo = class
      Name:string;
      Position:Integer;
      Info:TDomainInfo;
      UpdateFlag:boolean; 0 if computed, 1 - normal
      NullFlag:boolean;
      DefValue:string;
    end;

    TIndexInfo = class
      IndexName:string;
      TableName:string;
      Fields:TStrings;
      Unique:Boolean;
      Askending:boolean;
    end;

    TFKeyInfo = class
      MainTable:string;
      RefTable:string;
      RefFields:TStrings(MainItem:RefItem)
      UpdateAction:string;
      DeleteAction:string;
    end

    TTableInfo = class
      Name:string;
      Fields:ListOfTFieldInfo;
      Checks:TStrings;
      PrimaryKey:TIndex;
      FogernKeys:ListOfFKeys;
      Constains:TStrings;
    end;

    TTriggerInfo = class

    end;

    TProcInfo = class



    end;

  зачем нужны отдельные объекты для манипуляции с метаданными?
  1. упрощения манипуляций с метаданными
    - один и тот же объект может использоваться в нескольких узлах дерева объектов,
      зачем его извлекать несколько раз
    - если метеданные хранятся в структурированной форме, то с нимим проще работать,
      например, построить SQL создания объекта
  2. Для переноса метаданных. Если необходимо перенести метаданные из одной БД
    в другую, и эти БД разных типов, то проще производить анализ совместимости

  3. Упрощение каких до других операций с данными, например, визуалтизация БД со
  всеми связями

  что есть
  иерархия объектов для отображения (привязанных к элементам дерева)
  - объекты, отображающие инфу
  - объекты, содержащие списки других объектов

  какие то списки объектов, хранящих метаданные

  что делаем
  1. построение SQL создания элемента
  2. получение информации об одних элементах, используя другие (о таблице используя ее индексы)

  для метаобъектов есть 2 способа добычи
  1. по имени объекта (оно есть всегда, либо руками, либо системное, под именем может рассматриваться
    и какой то ИД)
  2. по привязке к какому то другому объекту

  Для полного счастья, все метаобъекты не имеют ссылок друг на друга, добывать их
  можно только используя поля этих метаобъектов

  метаобъекты добываются двумя методами
  1. получение списка объектов (извлекается имя объекта и SYSTEM_FLAG)
  2. получение полной инфы по отдельному объекту
  3. Операция проверки списка - это когда вызывается Update для списка элементов
    - при этом получается новый список и сравнивается со старым, удаляются отсутствующие в старом
    - все оставшиеся помечаются как непрочитанные
  Полная инфа по объекту получается только тогда, когда объект необходимо использовать
     - отсюда - все метаобъекты должны храниться в одном месте, при запросе метаобъекта
     происходит проверка на валидность и он считывется из базы и отдается для
     дальнейшего использования
  !!! видно, что у всех объектов есть 3 общих характеристики
    1. Имя
    2. Валидность
    3. SystemFlag.
    А также метод Clear (если у нас они хранятся только в одном месте и ссылки только
    по именам, то можно обойтись созданием нового пустого объекта вместо очистки старого)
  с учетом использования объектов для переноса метаданных, эти объекты являются

  1. пассивными - инфу в них помещает кто то другой
  2. они должны охватывать все возможные комбинации данных все используемых БД
  3. они должны храниться в чем то, что позволяет их заполнить
  4. они должны храниться так, чтобы к ним имел возможность получить доступ кто то
    другой, не только из модуля текущей БД
  5. они должны иметь доступ друг к другу
  6. они должны иметь возможность обновляться независимо от объектов отображения
  7. Для получения метаобъекта используется только имя
  8. Ссылки на эти объекты имеют валидность толко в контексте выполнения текущей
    операции (группы операций) пользователя. (это значит, что пользователь, задав
    какую то команду и получив метаобъект, не может расситывать на то, что в
    следующей же такой же команде он получит тот же метаобъект. Но, имея имя этого
    метаобъекта, в следующей команде он все же что то получит(возможно, ошибку что
    объект не существует)).
  9. по внешнему запросу нужна возможность передать весь набор метаобъектов
  10. С учетом того, что метаобъекты заполняются динамически, запросы на получение
    метаобъекта как то должны передаваться связанному объекту БД для выполнения

  Итого, получается должен быть общий класс-хранилище метаобъектов (TMetaInfo), из которого
  доступны все метаобъекты текущей БД

  2 варианта реализации
  1. Имеется пассивный TMetaInfo, проксирующий запросы БД
  2. Активный TMetaInfo(потомок для конкретной БД), получающий ссылку на БД и
    работающий с ней.

  Итого

  Database - ConnectionType - MetaInfo - TDBItem - VisualControls

  Database - физическая БД

  ConnectionInfo - доступ к физической БД

  MetaInfo - Хранит инфу о типах БД

  TDBItem - Преобразует инфу о типах в физической БД в вид для отображения
  Также корневой БД итем хранит ссылку на ConnectionType

  VisualControls отображает инфу пользователю

  MetaInfo + TDBItem ?  - тогда под каждую БД должен быть свой MetaInfo, часть логики
  по заполнению ляжет на контролы, либо MetaInfo должен знать, как себя отображать -
  в общем, не то


  Под каждую БД должен быть свой набор потомков TDBItem и ConnectionInfo
  Набор потомков должен знать о том, что может лежать в БД и как его показывать

  Итого, MetaInfo один для всех БД, без наследования для каждой БД

  Хранится в ConnectionInfo (ci одна на каждую БД). ConnectionInfo определяет 2
  процедуры
    - GetList(AMetaType:TMetaType); - возвращает список элементов заданного типа
    - FillItem(AItem:TBaseMetaItem); - заполняет переданный ей Итем данными полностью

  Metainfo Экспортирует одну служебную функцию
    GetEmptyItem(AMetaType):TBaseMetaItem; - возвращает пустой метаитем, уже
      запихнутый в нужный список
    DropItem(TBaseMetaItem) - валит переданный метаитем, с удалением из нужного списка


  процесс заполнения дерева выглядит следующим образом
  Получение списка итемов
  TTreeNode обращается к своему TDBItem - дай список
  TDBItem лезет в свой FDBRootItem и запрашивает мету на предмет списка итемов заданного
  типа.
  если мета не имеет такой список, она его запрашивает у ConnectionInfo
  тот его стоит, далее все в обратном порядке идет

  получение свойств итема идет аналогично
  узел дерева лезет в дбитем, тот просит у меты конкретный итем
  мета проверяет, есть ли такой итем, если нет, то проверяется, есть ли вообще
  список итемов такого типа
  если нет, создается список, если итема нет в списке, то список перестраиватеся
  если итема опять нет, то возбуждается исключение, которое ловит
  дбитем и сигнализирует пользователю, что произошел косяк получения
  данных от меты по причине отсутствия источника данных (где то неправильно прочлась мета
  или итем удолили
  надо перенести GetDS CloseDS из рутдбитема в ConnectionInfo

  И создать отдельно класс TRootDBItem -  он хранит в себе ссылку на TConmnectionInfo


    }

  TDataType = (dtUnk, dtSmallInt, dtInteger, dtBigInt, dtFloat, dtDate, dtTime,
    dtTimeStamp, dtChar, dtVarChar, dtDoublePrec, dtBlob, dtDecimal, dtNumeric);

  TMetaType = (mtUnk, mtDomain, mtField, mtTable, mtView, mtIndex, mtTrigger,
    mtFKey);

  TAutoIncMethod = (aimNone, aimDataType, aimTrigger);

  TTriggerEvent = (teUnk, teBeforeInsert, teBeforeUpdate, teBeforeDelete,
    teAfterInsert, teAfterUpdate, teAfterDelete, teOnConnect, teOnDisconnect,
    teOnTransactionStart, teOnTransactionCommin, teOnTransactionRollback);

  TTriggerEvents = set of TTriggerEvent;

  //если попытаться получить инфу об метаобъекте, которого нет в БД, вызывается
  //исключение - EInvalidObject;

  EInvalidObject = class(Exception)
    public
      ObjectName:string;
      ObjectType:TMetaType
  end;

  { TBaseMetaInfo }

  TBaseMetaInfo = class
    private
      FLoaded: boolean;
      FMetaType: TMetaType;
      FName: string;
      FSystemFlag: boolean;
      FSystemName: boolean;
    public
      constructor Create;virtual;
      function GetEmpty:TBaseMetaInfo;
      property Name:string read FName write FName; // имя элемента
      property SystemFlag:boolean read FSystemFlag write FSystemFlag; //элемент системный
      property Loaded:boolean read FLoaded write FLoaded; // данный элемент полностью загружен
      property MetaType:TMetaType read FMetaType write FMetaType; // тип меты, в общем то можно было обойтись и типом класса - они должэны дублировать друг друга
      property SystemName:boolean read FSystemName write FSystemName;//имя элемента задано системой
  end;

  TBaseMetaClass = class of TBaseMetaInfo;

  TMetaList = specialize TFPGObjectList<TBaseMetaInfo>;

  { TDomainInfo }

  TDomainInfo = class(TBaseMetaInfo)
    private
      FCheck: string;
      FComputed: string;
      FDataLen: Integer;
      FDataType: TDataType;
      FDefValue: string;
      FNullFlag: boolean;
      FPrecision: Integer;
      FScale: Integer;
      FSubType: Integer;
    public
      constructor Create;override;
      property DataType:TDataType read FDataType write FDataType;
      property SubType:Integer read FSubType write FSubType;
      property DataLen:Integer read FDataLen write FDataLen;
      property Precision:Integer read FPrecision write FPrecision;
      property Scale:Integer read FScale write FScale;
      property NullFlag:boolean read FNullFlag write FNullFlag;//True if NOT NULL
      property Check:string read FCheck write FCheck;
      property DefValue:string read FDefValue write FDefValue;
      property Computed:string read FComputed write FComputed;
  end;

  { TFieldInfo }

  TFieldInfo = class(TBaseMetaInfo)
    private
      FAutoInc: TAutoIncMethod;
      FBaseField: string;
      FCheck: string;
      FDefValue: string;
      FDomainInfo: string;//other data for field meta //fb - use system domain
      FNullFlag: boolean;
      FPosition: Integer;
      FTable: string;
      FUpdateFlag: boolean;
      FViewContext: Integer;
    public
      constructor Create;override;
      destructor Destroy;override;
      property Position:Integer read FPosition write FPosition;
      property DomainInfo:string read FDomainInfo write FDomainInfo;
      property UpdateFlag:boolean read FUpdateFlag write FUpdateFlag; //0 if computed(read-only), 1 - normal
      property NullFlag:boolean read FNullFlag write FNullFlag;//True if NOT NULL
      property DefValue:string read FDefValue write FDefValue;
      property Check:string read FCheck write FCheck;
      property BaseField:string read FBaseField write FBaseField;       //for views
      property ViewContext:Integer read FViewContext write FViewContext; //for views
      property Table:string read FTable write FTable;

      property AutoInc:TAutoIncMethod read FAutoInc write FAutoInc;//none if  not AI
    end;

  { TIndexInfo }

  TIndexInfo = class(TBaseMetaInfo) //indices
    private
      FAskending: boolean;
      FFields: TStringList;
      FForeignKey: string;
      FTableName: string;
      FUnique: Boolean;
    public
      constructor Create;override;
      destructor Destroy; override;
      property TableName:string read FTableName write FTableName;
      property Fields:TStringList read FFields;
      property Unique:Boolean read FUnique write FUnique;
      property Askending:boolean read FAskending write FAskending;
      property ForeignKey:string read FForeignKey write FForeignKey;
  end;

  { TFKeyInfo }

  TFKeyInfo = class(TBaseMetaInfo)  // foreign key support
    private
      FDeleteAction: string;
      FIndexName: string;
      FMainTable: string;
      FRefFields: TStringList;
      FRefTable: string;
      FUpdateAction: string;
    public
      constructor Create;override;
      destructor Destroy; override;
      property MainTable:string read FMainTable write FMainTable;//наша таблица
      property RefTable:string read FRefTable write FRefTable;//таблица, на которую ссылаемся
      property RefFields:TStringList read FRefFields;//(MainItem:RefItem)//соотношение наших полей ина которые ссылаемся
      property UpdateAction:string read FUpdateAction write FUpdateAction;
      property DeleteAction:string read FDeleteAction write FDeleteAction;
      property IndexName:string read FIndexName write FIndexName;
  end;


  TFieldsList = specialize TFPGObjectList<TFieldInfo>;

  { TTableInfo }

  TTableInfo = class(TBaseMetaInfo)
    private
      FForeignKeys: TStringList;
      FIndices: TStringList;
      FPrimaryKey: string;
      FTriggers: TStringList;
      FFields:TFieldsList;
      function GetFieldCount: Integer;
      function GetFields(I: Integer): TFieldInfo;
    public
      constructor Create;override;
      destructor Destroy; override;
      property Fields[I:Integer]:TFieldInfo read GetFields;//fields - use only in table context
      property FieldCount:Integer read GetFieldCount;
      property PrimaryKey:string read FPrimaryKey write FPrimaryKey;//index use for primary key constraint
      property ForeignKeys:TStringList read FForeignKeys;//foreign keys
      property Triggers:TStringList read FTriggers;//list of trigger names on this table
      property Indices:TStringList read FIndices;//list of index names on this table
      function AddField:TFieldInfo;
      procedure DeleteField(Info:TFieldInfo);
    end;


  { TViewInfo }

  TViewInfo = class (TBaseMetaInfo)
    private
      FTables: TStringList;
      FTriggers: TStringList;
      FFields:TFieldsList;
      function GetFieldCount: Integer;
      function GetFields(I: Integer): TFieldInfo;

    public
      constructor Create;override;
      destructor Destroy; override;
      property Fields[I:Integer]:TFieldInfo read GetFields;//fields - use only in table context
      property FieldCount:Integer read GetFieldCount;
      property Triggers:TStringList read FTriggers;//list of trigger names on this table
      property Tables:TStringList read FTables;
      function AddField:TFieldInfo;
  end;


  { TTriggerInfo }

  TTriggerInfo = class (TBaseMetaInfo)
    private
      FCheckSupport: boolean;
      FEventSupport: TTriggerEvents;
      FPosition: Integer;
      FTableName: string;
      FText: string;
    public
      constructor Create;override;
      destructor Destroy; override;
      property TableName:string read FTableName write FTableName;
      property Position:Integer read FPosition write FPosition;
      property EventSupport:TTriggerEvents read FEventSupport write FEventSupport; //events was trigger run
      property CheckSupport:boolean read FCheckSupport write FCheckSupport;//trigger used for constraints support
      property Text:string read FText write FText;//trigger text
  end;


  TGetNamesListEvent = procedure (AMetaType:TMetaType; AList:TStrings; UseFlag:Boolean) of object;
  //if UseFlags, then format of string is Name:SystemFlag:SystemName (SystemFlag and SystemName in (0,1));
  //else List contain names only
  TFillObjectEvent  = procedure (AMetaObject:TBaseMetaInfo) of object;

  TMetaMap = specialize TFPGMap<string, TBaseMetaInfo>;

  TMetaArray = array [TMetaType] of TMetaMap;

  { TMetaData }

  TMetaData = class
    private
      FArray:TMetaArray;
      FOnFillObject: TFillObjectEvent;
      FOnGetNames: TGetNamesListEvent;

      function GetDomains(AName: string): TDomainInfo;
      function GetForeignKeys(AName: string): TFKeyInfo;
      function GetIndices(AName: string): TIndexInfo;
      function GetObjects(AName: string): TBaseMetaInfo;
      function GetTables(AName: string): TTableInfo;
      function GetTriggers(AName: string): TTriggerInfo;
      procedure DoFillObject(AMetaInfo:TBaseMetaInfo);
      procedure DoGetNames(AMetaType:TMetaType);//if Need Force, clear Array
      function GetTypedObject(AMetaType:TMetaType; AName:string):TBaseMetaInfo;
      function GetViews(AName: string): TViewInfo;
    public
      constructor Create;
      destructor Destroy; override;
      property Objects[AName:string]:TBaseMetaInfo read GetObjects;
      property Tables[AName:string]:TTableInfo read GetTables;
      property Domains[AName:string]:TDomainInfo read GetDomains;
      property Indices[AName:string]:TIndexInfo read GetIndices;
      property Triggers[AName:string]:TTriggerInfo read GetTriggers;
      property Views[AName:string]:TViewInfo read GetViews;
      property ForeignKeys[AName:string]:TFKeyInfo read GetForeignKeys;
      function GetNamesList(AMetaType:TMetaType):TStringList;
      function GetEmptyObject(AName:string; AMetaType:TMetaType):TBaseMetaInfo;
      property OnGetNames:TGetNamesListEvent read FOnGetNames write FOnGetNames;
      property OnFillObject:TFillObjectEvent read FOnFillObject write FOnFillObject;
  end;



implementation


const MetaTypes : array [TMetaType] of TBaseMetaClass = (TBaseMetaInfo, TDomainInfo,
  TFieldInfo, TTableInfo, TViewInfo, TIndexInfo, TTriggerInfo, TFKeyInfo);

const MetaNames : array [TMetaType] of string = ('Unknow', 'Domain', 'Field', 'Table',
  'View', 'Index', 'Trigger', 'ForeignKey');

{ TViewInfo }

function TViewInfo.GetFieldCount: Integer;
begin
  Result:=FFields.Count;
end;

function TViewInfo.GetFields(I: Integer): TFieldInfo;
begin
  Result:=FFields[I];
end;

constructor TViewInfo.Create;
begin
  inherited Create;
  FMetaType:=mtView;
  FTables:=TStringList.Create;
  FTriggers:=TStringList.Create;
  FFields:=TFieldsList.Create(True);
end;

destructor TViewInfo.Destroy;
begin
  FTables.Free;
  FFields.Free;
  FTriggers.Free;
  inherited Destroy;
end;

function TViewInfo.AddField: TFieldInfo;
begin
  Result:=TFieldInfo.Create;
  FFields.Add(Result);
end;


{ TMetaData }

function TMetaData.GetDomains(AName: string): TDomainInfo;
begin
  Result:=GetTypedObject(mtDomain,AName) as TDomainInfo;
end;

function TMetaData.GetForeignKeys(AName: string): TFKeyInfo;
begin
    Result:=GetTypedObject(mtFKey,AName) as TFKeyInfo;
end;

function TMetaData.GetIndices(AName: string): TIndexInfo;
begin
  Result:=GetTypedObject(mtIndex,AName) as TIndexInfo;
end;

function TMetaData.GetObjects(AName: string): TBaseMetaInfo;
var
  I: TMetaType;
  J:Integer;
begin
  Result:=nil;
  for I:=Low(TMetaType) to High(TMetaType) do begin
    J:=FArray[I].IndexOf(AName);
    if J<>-1 then begin
      Result:=FArray[I].Data[J];
      if not Result.FLoaded then
        DoFillObject(Result);
      Exit;
    end;
  end;
end;

function TMetaData.GetTables(AName: string): TTableInfo;
begin
  Result:=GetTypedObject(mtTable,AName) as TTableInfo;
end;

function TMetaData.GetTriggers(AName: string): TTriggerInfo;
begin
  Result:=GetTypedObject(mtTrigger,AName) as TTriggerInfo;
end;

procedure TMetaData.DoFillObject(AMetaInfo: TBaseMetaInfo);
begin
  if AMetaInfo.FLoaded then Exit;
  if Assigned(FOnFillObject) then
    FOnFillObject(AMetaInfo);
end;

procedure TMetaData.DoGetNames(AMetaType: TMetaType);
var SL:TStringList;
  procedure LoadNames;
  var I:Integer;
      SA:TStringArray;
      mi:TBaseMetaInfo;
      CClass:TBaseMetaClass;
  begin
    //Name:SystemFlag:SystemName
    CClass:=MetaTypes[AMetaType];
    for I:=0 to SL.Count-1 do begin
      SA:=SL[I].Split([':']);
      mi:=CClass.Create;
      mi.FName:=SA[0];
      if SA[1] = '1' then
        mi.FSystemFlag:=True;
      if SA[2] = '1' then
        mi.FSystemName:=True;
      FArray[AMetaType].KeyData[mi.FName]:=mi;
    end;
  end;

begin
  //get names for AMetaType
  if FArray[AMetaType].Count<>0 then Exit;
  if Assigned(FOnGetNames) then begin
    try
      SL:=TStringList.Create;
      FOnGetNames(AMetaType,SL, True);
      LoadNames;
    finally
      SL.Free;
    end;
  end;
end;

function TMetaData.GetTypedObject(AMetaType: TMetaType; AName: string
  ): TBaseMetaInfo;
begin
  Result:=nil;
  if FArray[AMetaType].Count=0 then
    DoGetNames(AMetaType);
  Result:=FArray[AMetaType].KeyData[AName];
  if not Result.FLoaded then
    DoFillObject(Result);
end;

function TMetaData.GetViews(AName: string): TViewInfo;
begin
  Result:=GetTypedObject(mtView,AName) as TViewInfo;
end;

constructor TMetaData.Create;
var
  I: TMetaType;
begin
  for I:=Low(TMetaType) to High(TMetaType) do
    FArray[I]:=TMetaMap.Create;
end;

destructor TMetaData.Destroy;
var
  I: TMetaType;
  J: Integer;
begin
  for I:=Low(TMetaType) to High(TMetaType) do
    for J:=0 to FArray[I].Count-1 do begin
      FArray[I].Data[J].Free;
    end;
    FArray[I].Free;
  inherited Destroy;
end;

function TMetaData.GetNamesList(AMetaType: TMetaType): TStringList;
var
  I: Integer;
begin
  Result:=nil;
  DoGetNames(AMetaType);
  if FArray[AMetaType].Count=0 then
    Exit;
  Result:=TStringList.Create;
  for I:=0 to FArray[AMetaType].Count-1 do begin
    Result.Add(FArray[AMetaType].Keys[I]);
  end;
end;

function TMetaData.GetEmptyObject(AName: string; AMetaType: TMetaType
  ): TBaseMetaInfo;
begin
  Result:=nil;
  Result:=MetaTypes[AMetaType].Create;
  Result.FName:=AName;
  FArray[AMetaType].KeyData[AName]:=Result;
end;

{ TTriggerInfo }

constructor TTriggerInfo.Create;
begin
  inherited Create;
  FMetaType:=mtTrigger;
  FCheckSupport:=False;
  FEventSupport:=[];
  FPosition:=0;
  FTableName:='';
  FText:='';
end;

destructor TTriggerInfo.Destroy;
begin
  inherited Destroy;
end;

{ TTableInfo }

function TTableInfo.GetFieldCount: Integer;
begin
  Result:=FFields.Count;
end;

function TTableInfo.GetFields(I: Integer): TFieldInfo;
begin
  Result:=FFields[I];
end;

constructor TTableInfo.Create;
begin
  inherited Create;
  FForeignKeys:=TStringList.Create;
  FIndices:=TStringList.Create;
  FPrimaryKey:='';
  FTriggers:= TStringList.Create;
  FFields:=TFieldsList.Create(True);
end;

destructor TTableInfo.Destroy;
begin
  FForeignKeys.Free;
  FIndices.Free;
  FTriggers.Free;
  FFields.Free;;
  inherited Destroy;
end;

function TTableInfo.AddField: TFieldInfo;
begin
  Result:=TFieldInfo.Create;
  FFields.Add(Result);
end;

procedure TTableInfo.DeleteField(Info: TFieldInfo);
begin
  FFields.Remove(Info);
end;

{ TDomainInfo }

constructor TDomainInfo.Create;
begin
  inherited Create;
  FMetaType:=mtDomain;
  FDataType:=dtUnk;
  FSubType:=-1;
  FDataLen:=0;
  FPrecision:=0;
  FScale:=0;
  FNullFlag:=False;
  FCheck:='';
  FDefValue:='';
  FComputed:='';
end;

{ TBaseMetaInfo }

constructor TBaseMetaInfo.Create;
begin
  FName:='';
  FSystemFlag:=False;
  FLoaded:=False;
  FMetaType:=mtUnk;
  FSystemName:=False;
end;

function TBaseMetaInfo.GetEmpty: TBaseMetaInfo;
begin
  Result:=TBaseMetaClass(ClassType).Create;
  Result.FName:=FName;
  Result.FSystemFlag:=FSystemFlag;
  Result.FLoaded:=False;
  Result.FMetaType:=FMetaType;
end;

{ TFKeyInfo }

constructor TFKeyInfo.Create;
begin
  inherited Create;
  FMetaType:=mtFKey;
  FRefFields:=TStringList.Create;
  FMainTable:='';
  FRefTable:='';
  FUpdateAction:='';
  FDeleteAction:='';
end;

destructor TFKeyInfo.Destroy;
begin
  FRefFields.Free;
  inherited Destroy;
end;

{ TIndexInfo }

constructor TIndexInfo.Create;
begin
  inherited Create;
  FMetaType:=mtIndex;
  FAskending:=True;
  FTableName:='';
  FUnique:=False;
  FFields:=TStringList.Create;
  FForeignKey:='';
end;

destructor TIndexInfo.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;


{ TFieldInfo }

constructor TFieldInfo.Create;
begin
  inherited Create;
  FMetaType:=mtField;
  FPosition:=-1;
  FUpdateFlag:=False;
  FNullFlag:=False;
  FDefValue:='';
  FCheck:='';
  FAutoInc:=aimNone;
end;

destructor TFieldInfo.Destroy;
begin
  inherited Destroy;
end;

end.

