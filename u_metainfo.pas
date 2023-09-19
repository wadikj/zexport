unit u_metainfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

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

  TDataType = (dtUnk, dtSmallInt, dtInteger, dtBigInt, dtFloat, tdDate, tdTime,
    tdTimeStamp, tdChar, tsVarChar, tdDoublePrec, tdBlob);

  TMetaType = (mtUnk, mtDomain, mtField, mtTable, mtView, mtIndex, mtTrigger,
    mtFKey);

  TAutoIncMethod = (aimNone, aimDataType, aimTrigger);

  { TBaseMetaInfo }

  TBaseMetaInfo = class
    private
      FLoaded: boolean;
      FMetaType: TMetaType;
      FName: string;
      FSystemFlag: boolean;
    public
      constructor Create;virtual;
      function GetEmpty:TBaseMetaInfo;
      property Name:string read FName write FName; // имя элемента
      property SystemFlag:boolean read FSystemFlag write FSystemFlag; //элемент системный
      property Loaded:boolean read FLoaded write FLoaded; // данный элемент полностью загружен
      property MetaType:TMetaType read FMetaType write FMetaType; // тип меты, в общем то можно было обойтись и типом класса - они должэны дублировать друг друга
      property SystemName:boolean read FSystemName write FSystemName;//имя элемента задано системой
  end;

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
      FDefValue: string;
      FDomainInfo: TDomainInfo;//other data for field meta //fb - use system domain
      FNullFlag: boolean;
      FPosition: Integer;
      FUpdateFlag: boolean;
    public
      constructor Create;override;
      destructor Destroy;override;
      property Position:Integer read FPosition write FPosition;
      property DomainInfo:string read FDomainInfo write FDomainInfo;
      property UpdateFlag:boolean read FUpdateFlag write FUpdateFlag; //0 if computed(read-only), 1 - normal
      property NullFlag:boolean read FNullFlag write FNullFlag;//True if NOT NULL
      property DefValue:string read FDefValue write FDefValue;
      property AutoInc:TAutoIncMethod read FAutoInc write FAutoInc;//none if  not AI
    end;

  { TIndexInfo }

  TIndexInfo = class(TBaseMetaInfo) //indices
    private
      FAskending: boolean;
      FFields: TStringList;
      FTableName: string;
      FUnique: Boolean;
    public
      constructor Create;override;
      destructor Destroy; override;
      property TableName:string read FTableName write FTableName;
      property Fields:TStringList read FFields;
      property Unique:Boolean read FUnique write FUnique;
      property Askending:boolean read FAskending write FAskending;
  end;

  { TFKeyInfo }

  TFKeyInfo = class(TBaseMetaInfo)  // foreign key support
    private
      FDeleteAction: string;
      FIndexName: string;
      FMainTable: string;
      FName: string;
      FRefFields: TStringList;
      FRefTable: string;
      FUpdateAction: string;
      UpdateAction: string;
    public
      constructor Create;override;
      destructor Destroy; override;
      property MainTable:string read FMainTable write FMainTable;//наша таблица
      property RefTable:string read FRefTable write FRefTable;//таблица, на которую ссылаемся
      property RefFields:TStringList read FRefFields;//(MainItem:RefItem)//соотношение наших полей ина которые ссылаемся
      property UpdateAction:string read FUpdateAction write UpdateAction;
      property DeleteAction:string read FDeleteAction write FDeleteAction;
      property IndexName:string read FIndexName write FIndexName;
  end;



  TTableInfo = class(TBaseMetaInfo)
    private

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
      procedure DeleteField(TFieldInfo);
    end;





implementation

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
  FSystemFlag:=True;
  FLoaded:=False;
  FMetaType:=mtUnk;
end;

function TBaseMetaInfo.GetEmpty: TBaseMetaInfo;
begin
  Result:=ClassType.Create;
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
  FDomainInfo:=TDomainInfo.Create;
  FPosition:=-1;
  FUpdateFlag:=False;
  FNullFlag:=False;
  FDefValue:='';
  FAutoInc:=aimNone;
end;

destructor TFieldInfo.Destroy;
begin
  FDomainInfo.Free;
  inherited Destroy;
end;

end.
