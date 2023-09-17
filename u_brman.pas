unit u_brman;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;



type

  TBrowserManager = class;// класс - хранитль всего
  TBrowserList = class; // последовательный список открытых браузеров
  TCustomBrowser = class; // хранит в себе браузер (абстрактый), реально есть потоми под каждый браузер
  //содержит в себе только интерфейс и поле, в котором хранится ссылка на компонент браузера
  TScrLink = class; // посредник между браузером и скриптом (абстрактный)
  TCustomBrowserData = class; //потомки хранят данные, специфичные для браузера
  TBrowserClass = class of TCustomBrowser;

{алгоритм работы
при запуске скрипта - обращение к брман, запрос на скрлинк.
далее полученный скрлик сохраняется (пока без браузера). все запросы к браузеру
идут через скрлинк.
при возникновении запроса к браузеру скрлинк, если пустой, пытается получить тек активный браузер
у менеджера. менеджер запрашивает тек активный у приложения.
при каждом запросе скрлинк передает себя браузеру, тот смотрит в бровзердате,
связана ли она с ним, и если нет, то обновляет ее


если же надо создать новый, то менеджер также просит его у приложения

если у нас последовательность скриптов, то скрлинк хранит в себе указатель на
брлист - всегда работаем только с последним активным враузером в цепочке
при подключении к браузеру скрлинк передает себя, а в себе хранит ссылку на
дочерний скрлист и ссылку на брлист

брлист хранит в себе цепочку последовательных браузеров, и при необходимости
возвращает последний из них
все операции ведутся только с последним активным браузером
}

{
браузеры - есть враппер (TCustomBrowser и потомки), есть сами браузеры (ОС)- что то
  в OleContainer если не указано, то браузер - их связка

создание браузера - 2 способа

1. +++Явно - newbrowser, GetActive - идет через команды, через линк, и только так
2. Неявно - при выполнении команды, открывающей новое окно - вызов метода BrMan,передача туда
  нового браузера и того, что вызвало создание нового (старый) - BrMan ищет в активных
  старый браузер и цепляет к нему новый с созданием враппера
  или новый уже обернутый браузер передается


+++Разрушение браузеров происходит только явно, путем вызова команды close. Также при
    окончании выполнения скрипта разрушается связаннай с ним цепочка браузеров
    (брлист). Здесь скрипт - тот, который запустился первоночально.При этом если
    есть откр. вкладки, то они остаются.

+++close - идет брману с указанием линка. брман валит враппер????, а затем вызывает событие
OnCloseBrowser(в этом событии внешняя программа валит вкладку) передается компонент из
враппера. если этот компонент не требует вкладки, то все равно, передаем во внешку, просто там
ничего не сделается

создание браузера
все, что можно создать, предварительно регистриуется (классы врапперов)
брман создает враппер(по запросу от линка), затем смотрит, нужно ли запрашиваться на
создание вкладки
если нужно, то вызывается OnNewBrowser, который возвращает компонент ОС, который пихается
во враппер.(у нас может быть невидимый браузер, без окна просмотра графики и без вкладки, он
сразу враппером и создается и с ним же и дохнет)
После этого враппер добавляется в список брлист текущего линка

+++---++у линка есть поле FFirst:boolean. Оно инициализируется брманом в True, если при создании
линка не был передан родительский линк. При разрушении такого линка также валится связанный с
ним брлист.

По приколу добавить глобальные переменные - начинаются с $$, доступны во всех скриптах
сделать, чтобы в GetLSData были такие же возможности, как и в CreateFileName
или добавить команду format=$template,$v1,$v2 - первая переменная шаблон, остальные просто
туда запихиваются

Удолить из модуля U_scr MSHTML и SH_DOC_VW, все должно быть в брмане и связаных с ним}


  ///перенесено сюда из u_simplescr - там нафиг вальнуть
  //нужно для newbrowser
  TInternalProc = procedure (Sender:TScrLink; AData:string) of object;
  //работа по созданию/удалению браузеров
  TGetActiveBrowserProc = function : TCustomBrowser of object; //оборачиваем компонент в нашу обертку
  TGetNewBrowserProc = function(AData:string) : TCustomBrowser of object;
  TCloseBrowserProc = procedure(Browser : TComponent) of object;
  TParentBrowserProc = procedure (Parent, Browser:TComponent) of object;

  TListOfBrowserList = specialize TFPGObjectList<TBrowserList>;

  TListOfBrowsers = specialize TFPGObjectList<TCustomBrowser>;
  TOnBMLog = procedure (S,S1:string) of object;

  { TBrowserManager }

  TBrowserManager = class
    private
      FListOfList:TListOfBrowserList;
      FDefBrowser:string;//имя тек браузера по умолчанию, если не указано, то создавать
      FOnBMlog: TOnBMLog;
      FOnCloseBrowser: TCloseBrowserProc;
      FOnGetActiveBrowser: TGetActiveBrowserProc;
      FOnGetParentProwser: TParentBrowserProc;
      FOnNewBrowser: TGetNewBrowserProc;
      FInsertMode:Boolean;
      procedure SetOnCloseBrowser(AValue: TCloseBrowserProc);
      procedure SetOnGetActiveBrowser(AValue: TGetActiveBrowserProc);
      procedure SetOnGetParentProwser(AValue: TParentBrowserProc);
      procedure SetOnNewBrowser(AValue: TGetNewBrowserProc);
      //новые цепочки скриптов нельзя, можно только начинать с активного видимого в программе

      //для создания нового из скриптов
      procedure DoInternalNewBrowser(ALink:TScrLink; AData:string);//newbrowser - вызывается из скриптов при команде newbr
      //валим браузер из скрипта
      procedure DoInternalCloseBrowser(ALink:TScrLink);//close -вызывается из скриптов при команде close
      //окончание выполнения
      procedure EndExecute(ALink:TScrLink);
    public
      constructor Create;
      destructor Destroy; override;
      function GetScrLink(AParent:TScrLink):TScrLink;//скрипт запрашивает линк у менеджера, передавая дочерний, или nil
      procedure DoGetActiveBrowser(ALink:TScrLink);//active in app, if browser needed - вызывается из скрипта, если тербуется тек активный браузер
      procedure RegisterBrowser(BrowserClass:TBrowserClass; AName:string; HideMode:boolean);
      //эти свойства устанвливаются при инициализации модуля внешней программой, и при необходтмости выполнить действие вызываютмя потом скриптом
      property OnNewBrowser:TGetNewBrowserProc read FOnNewBrowser write SetOnNewBrowser ; //свойства для получения нового браузера - вызывается из программы, когда создался новый браузер
      property OnCloseBrowser:TCloseBrowserProc read FOnCloseBrowser write SetOnCloseBrowser; //для закрытия
      property OnGetActiveBrowser:TGetActiveBrowserProc read FOnGetActiveBrowser write SetOnGetActiveBrowser;//для тек активного
      property OnGetParentProwser:TParentBrowserProc read FOnGetParentProwser write SetOnGetParentProwser;//при порождении нового браузера, например, в результате Click
      property OnLog :TOnBMLog read FOnBMlog write FOnBMlog;
      //это вызывается из программы, когда в резултате работиы скрипта создается новый браузер
      function DoExtNewBrowser(AParent:TObject; ANewBrowser:TCustomBrowser):boolean;
      procedure Log(S:string);
  end;

  { TBrowserList }

  TBrowserList = class
    private
      FList:TListOfBrowsers;
      FHideMode:boolean;//при установке в True скрытые браузеры создаются менеджером самостоятельно
      function GetActiveBrowser: TCustomBrowser;
      procedure AddBrowser(ABrowser:TCustomBrowser);
      procedure DeleteActive;
      //и разрушаются при окончании работы скриптов
    public
      constructor Create;
      destructor Destroy; override;
      property ActiveBrowser:TCustomBrowser read GetActiveBrowser;
  end;

  { TCustomBrowser }

  TCustomBrowser = class
    private
      FBList:TBrowserList;//в какой иерархии он сидит
      function GetBrowserData(ALink: TScrLink): TCustomBrowserData;
      procedure SetBrowserData(ALink: TScrLink; AValue: TCustomBrowserData);
    protected
      property BrowserList:TBrowserList read FBList;
      procedure UpdateBrowserData(AParentScrLink, AScrLink:TScrLink);virtual;abstract;

      property BrowserData[ALink:TScrLink]:TCustomBrowserData read GetBrowserData write SetBrowserData;
      //тупо задает FLocalRoot из FCurrent парента, вызывается при вызове нового скрипта
      procedure CheckBrowserData(ALink:TScrLink);virtual;abstract;//проверяет, что тек BrowserData связана с ним же, иначе пересоздает ее
      function CurrentExists(ALink:TScrLink):boolean;virtual;
      function GetAttrValue(ALink:TScrLink): string; virtual;abstract;
      function GetLocation: string; virtual;abstract;
      function GetTag(ALink:TScrLink): string; virtual;abstract;
      procedure SetAttrValue(ALink:TScrLink; AValue: string);virtual;abstract;
      procedure SetCurrent(ALink:TScrLink; APath:string; FromLocal:boolean = True); virtual;abstract;
      procedure SetLocation(ALocation: string); virtual;abstract;
      procedure SetLr(ALink:TScrLink); virtual;abstract;
      procedure GetLr(ALink:TScrLink); virtual;abstract;
      function  AttrExists(ALink:TScrLink):boolean; virtual;abstract;
      function  GetTextFrom(ALink:TScrLink; AFrom:string):string;virtual;abstract;
      procedure Click(ALink:TScrLink); virtual;abstract;
      function GetHead:string;virtual;abstract;
      function GetBody:string;virtual;abstract;
      procedure SavePage(AFileName:string);virtual;abstract;
      procedure CurrentByID(ALink:TScrLink;AID:string);virtual;abstract;
      procedure CurrentByName(ALink:TScrLink;AID:string);virtual;abstract;
      procedure GoBack;virtual;abstract;
      procedure Select(ALink:TScrLink);virtual;abstract;
      procedure SelectIndex(ALink:TScrLink;AIndex:Integer);virtual;abstract;
      procedure Submit(ALink:TScrLink);virtual;abstract;
    public
      constructor Create(ABrowser:TObject);virtual;
      destructor Destroy; override;
      property Location: string read GetLocation write SetLocation;
      function GetBrowserControl:TObject;virtual;abstract;
      function Complete:boolean;virtual;abstract;
  end;

  //класс для связи браузера и скриптов.
  //все команды к браузеру идут через линк
  //браузер хранит информацию о скриптах в поле FBrowserData
  //класс разрушается вместе с владеющим им скриптом
  //при разрушении поcылает информацию об этом FData.FBrowserList
  //в случае, если у скрипта, с которым связан линк, нет родителя

  { TScrLink }

  TScrLink = class
    private
      FData:TCustomBrowserData;
      FBrList:TBrowserList;
      FAttr: string;
      FFirst: boolean;
      function GetAttrValue: string;
      function GetCurrentExists: boolean;
      function GetLocation: string;
      function GetTag: string;
      procedure SetAttrValue(AValue: string);
      procedure SetLocation(AValue: string);
    protected
      procedure CheckBrowser;
    public
      constructor Create;virtual;
      destructor Destroy; override;
      //команды скриптов
      //переадресуются через менеджер текущему активному бровзеру
      //или обращаются напряямую в тек браузер
      //доступ к браузеру

      //path
      procedure SetCurrent(AValue:string;FromLocal:boolean = True);
      property CurrentExists:boolean read GetCurrentExists;
      property Attr:string read FAttr write FAttr;//имя атрибута
      property AttrValue: string read GetAttrValue write SetAttrValue;
      function AttrExists:boolean;//must be set attr!!!
      property Tag:string read GetTag;
      property Location:string read GetLocation write SetLocation;
      procedure SelByID(AID:string);
      procedure SelByName(AName:string);
      function GetTextFrom(AFrom:string):string;//извлечение данных из узла
      procedure Click;
      procedure ExecJS(AJSScript:string);
      procedure FireEvent(AName:string);
      procedure SetLr;//set current as local root
      procedure GetLr;//set local root as current
      procedure SaveCurrent;
      procedure LoadCurrent;
      //остальные переадресуются менеджеру
      procedure NewBrowser(AData:string);
      procedure CloseBrowser(AData:string);
      function GetHead:string;
      function GetBody:string;
      procedure SavePage(AFileName:string);
      function Complete:boolean;
      procedure GoBack;
      procedure Select;
      procedure SelectIndex(AIndex:Integer);
      procedure Submit;
  end;

  //класс - хранитель информации для браузера

  { TCustomBrowserData }

  TCustomBrowserData = class
    private

    protected
      procedure SaveCurrent;virtual; abstract;
      procedure LoadCurrent;virtual; abstract;
    public
      FBrowser:TCustomBrowser;
      constructor Create;virtual;
      //дополнительные поля находятся в потомках класса
  end;


function BrMan:TBrowserManager;

{
работа
1. при первом создании скрипта он лезет в менеджер и получает скрлинк. Сразу же создается
брлист, но пустой.
2. при запросе данных браузера, если брлист пустой, то он запрашивает браузер у менеджера,
  А ТОТ  - У ПРИЛОЖЕНИЯ
3. если идет команда newbrowser, то в зависимоти от параметров, этот браузер
  создает либо приложение, либо сам менеджер (если Silent = True).
4. команды работы с браузерами запихнуты в брлист
5. команды для получения данных из браузера - внутренние методы линка. Тот переадресует
    их напрямую текущему активному браузеру, передавая в том числе и себя
6. текущий браузер при получении команды проверяет брдату в линке. если в линке
  указан он не он, то брдата переделывается под себя
  потом выполняется команда
7. при запуске скрипта, если он не первый, то данные из линка родителя копируются в
  свой линк, при этом перенастраивается поле LocalRoot
8. Переписать все процедуры, работающие с браузером напрямую. Если у нас есть списки,
  то использовать адресацию через пути
9. линк хранит не только элементы, но и пути к ним. более того, скрипт не имеет доступа
  напрямую к элементам браузера, он может работать с ними только через указание
  путей к элементам(path, setlr, команды доступа к атрибутам, проверка существования
  текущего элемента). Например, команды цикла просто по очереди устанавливают path
10. при всех операциях с DOM предполагается, что сначала выдается команда на задание
  FCurrent, а затем идут манипуляции с данными. Если path не задан, то FCurrent =
  FRoot (а FRoot - указатель на элемент <body> страницы). Поэтому надо проверять
  Bowser при любой команде, чобы не было ошибок, если мы хотим в тек открытой странице
  пройтись, например, по всем потомкам страницы.
11. Если у нас поменялся Location, то FCurrent b FLocaloot - недействительны. Если
  программит к ним обращается - то это проблемы программиста.


}


implementation

var FBrMan:TBrowserManager = nil;

function BrMan: TBrowserManager;
begin
  if FBrMan=nil then
    FBrMan:=TBrowserManager.Create;
  Result:=FBrMan;
end;

{ TCustomBrowserData }

constructor TCustomBrowserData.Create;
begin
  inherited Create;
end;


{ TCustomBrowser }

function TCustomBrowser.CurrentExists(ALink: TScrLink): boolean;
begin
  Result:=False;
end;

function TCustomBrowser.GetBrowserData(ALink: TScrLink): TCustomBrowserData;
begin
  Result:=ALink.FData;
end;

procedure TCustomBrowser.SetBrowserData(ALink: TScrLink;
  AValue: TCustomBrowserData);
begin
  ALink.FData:=AValue;
end;

constructor TCustomBrowser.Create(ABrowser: TObject);
begin
  //передается компонтет браузера или еще что то
  ///оно его в себе хранит и запрашивается к нему, если надо
  FBList:=nil; //походу надо его вальнуть
end;

destructor TCustomBrowser.Destroy;
begin
  FBList:=nil;
  inherited Destroy;
end;

{ TBrowserList }

function TBrowserList.GetActiveBrowser: TCustomBrowser;
begin
  Result:=nil;
  //если у нас хотят активный браузер, то мы должны его выдать
  //если надо проерить, есть ли он, то Flist.Count
  if FList.Count<>0 then
    Result:=FList[FList.Count-1]
  else begin
    //запрашиваем браузер у менеджера
    if BrMan.FOnGetActiveBrowser<>nil then begin
      Result:=BrMan.FOnGetActiveBrowser();
      AddBrowser(Result);
    end else
      raise Exception.Create('can''t get active browser!!!');
  end;
end;

procedure TBrowserList.DeleteActive;
begin
  FList.Delete(FList.Count-1);
end;

constructor TBrowserList.Create;
begin
  FList:=TListOfBrowsers.Create(True);
  //BrMan.Log('BrowserList Created');
end;

destructor TBrowserList.Destroy;
begin
  FreeAndNil(FList);
  //BrMan.Log('BrowserList Destroyed');
  inherited Destroy;
end;

procedure TBrowserList.AddBrowser(ABrowser: TCustomBrowser);
begin
  FList.Add(ABrowser);
  ABrowser.FBList:=Self;
end;

{ TScrLink }

function TScrLink.GetCurrentExists: boolean;
begin
  CheckBrowser;
  Result:=FBrList.ActiveBrowser.CurrentExists(Self);
end;

function TScrLink.GetAttrValue: string;
begin
  CheckBrowser;
  Result:=FBrList.ActiveBrowser.GetAttrValue(Self);
end;

function TScrLink.GetLocation: string;
begin
  CheckBrowser;
  Result:=FBrList.ActiveBrowser.Location;
end;

function TScrLink.GetTag: string;
begin
  CheckBrowser;
  Result:=UpperCase(FBrList.ActiveBrowser.GetTag(Self));
end;

procedure TScrLink.SetAttrValue(AValue: string);
begin
  CheckBrowser;
  FBrList.ActiveBrowser.SetAttrValue(Self,AValue);
end;

procedure TScrLink.SetLocation(AValue: string);
begin
  CheckBrowser;
  FBrList.ActiveBrowser.Location:=AValue;
end;

procedure TScrLink.CheckBrowser;
begin
  //смотрим, есть ли у нас хот какой то браузер, и если нет, то просим у менеджера
  //тек активный приложения
  if FBrList.FList.Count>0 then Exit;
  FBrMan.DoGetActiveBrowser(Self);
end;

constructor TScrLink.Create;
begin
  //BrMan.Log('Scrlink Created');
  FData:=nil;
  FBrList:=nil;
  FFirst:=False;
end;

destructor TScrLink.Destroy;
begin
  //BrMan.Log('Scrlink Destroyed');
  FreeAndNil(FData);
  if FFirst then
    BrMan.EndExecute(Self);
  FBrList:=nil;
  inherited Destroy;
end;

procedure TScrLink.SetCurrent(AValue: string; FromLocal: boolean);
begin
  CheckBrowser;
  FBrList.ActiveBrowser.SetCurrent(Self, AValue, FromLocal);
end;

function TScrLink.AttrExists: boolean;
begin
  Result:=False;
  if FAttr = '' then Exit;
  CheckBrowser;
  FBrList.ActiveBrowser.AttrExists(Self);
end;

procedure TScrLink.SelByID(AID: string);
begin
  CheckBrowser;
  FBrList.ActiveBrowser.CurrentByID(Self,AID);
end;

procedure TScrLink.SelByName(AName: string);
begin
  CheckBrowser;
  FBrList.ActiveBrowser.CurrentByName(Self,AName);
end;

function TScrLink.GetTextFrom(AFrom: string): string;
begin
  Result:='';
  if AFrom = '' then Exit;
  CheckBrowser;
  if not CurrentExists then Exit;
  Result:=FBrList.ActiveBrowser.GetTextFrom(Self, AFrom);
end;

procedure TScrLink.Click;
begin
  CheckBrowser;
  //тута у нас может появится новый браузер!!! и добавиться в список браузеров
  try
    FBrMan.FInsertMode:=True;
    FBrList.ActiveBrowser.Click(Self);
  finally
    FBrMan.FInsertMode:=False;
  end;
end;

procedure TScrLink.ExecJS(AJSScript: string);
begin
  raise Exception.Create('not implemented!!!');
end;

procedure TScrLink.FireEvent(AName: string);
begin
  raise Exception.Create('not implemented!!!');
end;

procedure TScrLink.SetLr;
begin
  CheckBrowser;
  FBrList.ActiveBrowser.SetLr(Self);
end;

procedure TScrLink.GetLr;
begin
  CheckBrowser;
  FBrList.ActiveBrowser.GetLr(Self);
end;

procedure TScrLink.SaveCurrent;
begin
  FData.SaveCurrent;
end;

procedure TScrLink.LoadCurrent;
begin
  FData.LoadCurrent;
end;

procedure TScrLink.NewBrowser(AData: string);
begin
  BrMan.DoInternalNewBrowser(Self, AData);
end;

procedure TScrLink.CloseBrowser(AData: string);
begin
  FreeAndNil(FData);
  BrMan.DoInternalCloseBrowser(Self);
end;

function TScrLink.GetHead: string;
begin
  CheckBrowser;
  Result:=FBrList.ActiveBrowser.GetHead;
end;

function TScrLink.GetBody: string;
begin
  CheckBrowser;
  Result:=FBrList.ActiveBrowser.GetBody;
end;

procedure TScrLink.SavePage(AFileName: string);
begin
  CheckBrowser;
  FBrList.ActiveBrowser.SavePage(AFileName);
end;

function TScrLink.Complete: boolean;
begin
  Result:=FBrList.ActiveBrowser.Complete;
end;

procedure TScrLink.GoBack;
begin
  CheckBrowser;
  FBrList.ActiveBrowser.GoBack;
end;

procedure TScrLink.Select;
begin
  CheckBrowser;
  FBrList.ActiveBrowser.Select(Self);
end;

procedure TScrLink.SelectIndex(AIndex: Integer);
begin
  CheckBrowser;
  FBrList.ActiveBrowser.SelectIndex(Self,AIndex);
end;

procedure TScrLink.Submit;
begin
  CheckBrowser;


end;

{ TBrowserManager }

procedure TBrowserManager.SetOnCloseBrowser(AValue: TCloseBrowserProc);
begin
  if FOnCloseBrowser=AValue then Exit;
  FOnCloseBrowser:=AValue;
end;

procedure TBrowserManager.SetOnGetActiveBrowser(AValue: TGetActiveBrowserProc);
begin
  if FOnGetActiveBrowser=AValue then Exit;
  FOnGetActiveBrowser:=AValue;
end;

procedure TBrowserManager.SetOnGetParentProwser(AValue: TParentBrowserProc);
begin
  if FOnGetParentProwser=AValue then Exit;
  FOnGetParentProwser:=AValue;
end;

procedure TBrowserManager.SetOnNewBrowser(AValue: TGetNewBrowserProc);
begin
  if FOnNewBrowser=AValue then Exit;
  FOnNewBrowser:=AValue;
end;

constructor TBrowserManager.Create;
begin
  FDefBrowser:='';//тащим из настроек
  FListOfList:=TListOfBrowserList.Create(True);
  FOnBMlog:=nil;
  //задаем обработчики на newbrowser и close
  //raise Exception.Create('');//чтобы не забыть!!!
  FInsertMode:=False;
end;

destructor TBrowserManager.Destroy;
begin
  FListOfList.Free;
  inherited Destroy;
end;

function TBrowserManager.GetScrLink(AParent: TScrLink): TScrLink;
var brlist:TBrowserList;
begin
  Result:=TScrLink.Create;
  if AParent=nil then begin
    brlist:=TBrowserList.Create;
    FListOfList.Add(brlist);
    Result.FBrList:=brlist;
    Result.FFirst:=True;
  end else begin
    Result.FBrList:=AParent.FBrList;
    if Result.FBrList.FList.Count>0 then
      Result.FBrList.ActiveBrowser.UpdateBrowserData(AParent, Result);
  end;
end;

procedure TBrowserManager.DoInternalNewBrowser(ALink: TScrLink; AData: string);
var cb:TCustomBrowser;
begin
  //у нас просят новый браузер. если скрытый, то создаем сами
  //если в приложении, то просим приложение
  //покеа без регистрации скрытых
  if not Assigned(FOnNewBrowser) then Exit;
  cb:=FOnNewBrowser(AData);
  ALink.FBrList.AddBrowser(cb);
end;

procedure TBrowserManager.DoInternalCloseBrowser(ALink: TScrLink);
begin
  //команда "закрыть браузер"
  //валим нашу обертку
  //и во внешку отправляем команду(если надо)
  if Assigned(FOnCloseBrowser) then
    FOnCloseBrowser(ALink.FBrList.ActiveBrowser.GetBrowserControl as TComponent);
  ALink.FBrList.DeleteActive;
end;

procedure TBrowserManager.DoGetActiveBrowser(ALink: TScrLink);
var br:TCustomBrowser;
begin
  if Assigned(FOnGetActiveBrowser) then begin
    //приложение само оборачивает браузевр в обертку, потму что оно точно знает
    //что это за браузер
    ///!!!дописать во фреймы с браузерами код создания обертки
    br := FOnGetActiveBrowser();
    if Assigned(br) then
      ALink.FBrList.FList.Add(br);
  end;
  if ALink.FBrList.FList.Count=0 then begin
    raise Exception.Create('Can''t get Active browser!!!');
  end;
end;

procedure TBrowserManager.RegisterBrowser(BrowserClass: TBrowserClass;
  AName: string; HideMode: boolean);
begin
  ///!!!для создания браузеров в себе
end;

function TBrowserManager.DoExtNewBrowser(AParent: TObject;
  ANewBrowser: TCustomBrowser): boolean;
var I:Integer;
begin
  ///!!!передается браузер, который сгенерировал создание, и то, что создалось
  //если у нас просто был вызов nrebrowser, то оно тоже прилетит сюда,
  //но Parent будет nil
  //если у нас парент = nil, то выходим. Если мы новый браузер хотим создать,
  //то есть спец команда, которая его вернет
  Result:=False;
  if AParent = nil then Exit;
  //тупо ищем среди активных браузеров тот, который совпадает с Parent
  if not FInsertMode then Exit;
  //тут передается сам объект браузера, и обертка
  //если у нас какой то браузер из последней в списке обертки совпадает с парентом,
  //то эт уобертку добавлям
  //иначе - это левая обертка
  for I:=0 to FListOfList.Count-1 do begin
    if FListOfList[I].ActiveBrowser.GetBrowserControl = AParent then begin
      FListOfList[i].AddBrowser(ANewBrowser);
      Result:=True;
      Break;
    end;
  end;
end;

procedure TBrowserManager.Log(S: string);
begin
  if Assigned(FOnBMlog) then
    FOnBMlog('brman', S);
end;

procedure TBrowserManager.EndExecute(ALink: TScrLink);
var I:Integer;
begin
  //окончание выполнения скриптов
  I:=FListOfList.IndexOf(ALink.FBrList);
  //BrMan.Log('Wrappers.count='+IntToStr(ALink.FBrList.FList.Count));
  //BrMan.Log('blistOfList.count='+IntToStr(FListOfList.Count));
  if I<>-1 then begin
    //валим наш список браузеров
    FListOfList.Delete(I);
  end;
end;

end.


