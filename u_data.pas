unit u_data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, FileUtil, UTF8Process, Dialogs,
  Graphics, DBGrids, paramstorage, ActnList, ComCtrls, Controls ;

type


  TOnTabCaptionChange = procedure (AParent:TWinControl; AText:string) of object;

  TETLProject = class;

  { TData }

  TData = class(TDataModule)
      ProcessUTF8_1: TProcessUTF8;
      procedure DataModuleCreate(Sender: TObject);
      procedure DataModuleDestroy(Sender: TObject);
    private

    public
      { public declarations }
      procedure SaveComponent(Cmp:TComponent; Props:string);
      procedure LoadComponent(Cmp:TComponent; Props:string);
      function GetGW(AColumns:tdbgridColumns):string;
      procedure SetCW(AColumns:tdbgridColumns;W:string);

  end;

  {$M+}

  TAdvType = (atScr, atPy, atExe);

  { TBtnColItem }

  TBtnColItem = class (TCollectionItem)
    private
      FAdvType: TAdvType;
      FBntText: string;
      FCmd: string;
      FHint: string;
      FMenuText: string;
      FShortCut: TShortCut;
    protected
      procedure DoExecute(Sender:TObject);
      function GetDisplayName: string; override;
    published
      property AdvType:TAdvType read FAdvType write FAdvType;
      property Cmd:string read FCmd write FCmd;
      property BntText:string read FBntText write FBntText;
      property MenuText:string read FMenuText write FMenuText;
      property Hint:string read FHint write FHint;
      property ShortCut:TShortCut read FShortCut write FShortCut;
  end;

  TBtnColItemClass = class of TBtnColItem;


  { TAdvAction }

  TAdvAction = class (TAction)
    private
      FColItem: TBtnColItem;
      procedure DoExecute(Sender:TObject);
    public
      constructor Create(AOwner:TComponent);override;
      property ColItem:TBtnColItem read FColItem write FColItem;
  end;

  { TDBColWidth }

  TDBColWidth = class (TCollectionItem)
    private
      FColName: string;
      FColWidth: integer;
    published
      property ColName:string read FColName write FColName;
      property ColWidth:integer read FColWidth write FColWidth;
  end;

  { TDBColItem }

  TDBColItem = class (TCollectionItem)
    private
      FColumns: TCollection;
      FDBPath: string;
      FName: string;
      FParams:TStrings;
      FTypeName: string;
      function GetAsText: string;
      function GetColCount: integer;
      function GetColumns(I: integer): TDBColWidth;
      function GetParams: TStrings;
      procedure SetParams(AValue: TStrings);
    public
      constructor Create(ACollection:TCollection);override;
      destructor Destroy; override;
      property AsText:string read GetAsText;
      function NewCol:TDBColWidth;
      property Columns[I:integer]:TDBColWidth read GetColumns;
      property ColCount:integer read GetColCount;
    published
      property Name:string read FName write FName;
      property TypeName:string  read FTypeName write FTypeName;
      property DBPath:string read FDBPath write FDBPath;
      property Params:TStrings read GetParams write SetParams;
      property Cols:TCollection read FColumns;
  end;

  { TOptions }

  TOptions = class(TCustomPropStorage)
    private
      //FButtons: TCollection;
      FDataBases: TCollection;
      FPrjList: TStrings;
      FETLProj: TETLProject;
      FMRUList:TStringList;

      FPyPath: string;
      FActiveProject: string;

      FIntfFont: Integer;
      FMiniFont: Integer;
      FEditFont: Integer;
      FTreeFont: Integer;
      FBtnFont: Integer;
      FUID: Integer;
      function GetMRUList: TStrings;
      procedure SetMRUList(AValue: TStrings);
    public
      constructor Create(AFileName: string); override;
      destructor Destroy; override;
      function GetFullPath(AShort:string):string; // по относительному пути возвращает абсолютный
      function GetFullPath(AShort,AFileName: string): string;overload; //тоже но с имя файла
      //в проект - для каждого проекта свой МРУ
      property MRUList:TStrings read GetMRUList write SetMRUList;
      procedure AddMRUFile(AFileName:string);
      procedure Load;override;
      procedure Save;override;

      //Project support
      property ActivePrj:TETLProject read FETLProj;
      function NewProj:TETLProject; //при содании нового
      procedure SetActivePrj(APrj:TETLProject);//задаем текущий
      procedure CloseActivePrj;//закрываем - при выходе из проги или при создании нового
      procedure LoadPrj(AFileName:string);//автоматич закрываем предыдущий и сохраняем его
      procedure AddLastProject(AProject:string);
      property PrjList:TStrings read FPrjList;
      function GetDBInfo(AName, AType:string):TDBColItem;
      function GetUID:string;
    published
      //в проект
      //property ScrDir:string read FScrDir write FScrDir; //путь к папке со скритами
      //property DataDir:string read FDataDir write FDataDir; //путь к папке с данными
      property PyPath:string read FPyPath write FPyPath;
      //property Buttons:TCollection read FButtons;
      property DataBases:TCollection read FDataBases;
      property ActiveProject:string read FActiveProject write FActiveProject; //путь к файлу проекта
      //все размры и положение форм - хранятся здесь, а не в проекте
      property IntfFont:Integer read FIntfFont write FIntfFont;
      property BtnFont:Integer read FBtnFont write FBtnFont;
      property TreeFont:Integer read FTreeFont write FTreeFont;
      property EditFont:Integer read FEditFont write FEditFont;
      property MiniFont:Integer read FMiniFont write FMiniFont;
      property UID:Integer read FUID write FUID;

  end;

  {тут также должен быть класс, который содержит проект
    загружется из файла проекта
    файл проекта находится в папке, которая является коневой папкой проекта
    все остальные папки проекта, если они находятся внутри, хранятся в виде относительных путей
    но работа с папками ведется с помощью абсолютных путей, котрые читаются из соотв свойств
    также автоматически делаются файлы для питона с путями
    В проекте также нужно предусмотреть задание переменных таким образом, чтобы
    их могли бы прочитать скрипты, как питоньи, так и SS. (в файл, где пути, пишем не только их, но
    и какие то дополнительные данные)

    основная задача - при копировании проекта на новое место он там должен нормально работать

    все компьютрозависимые вещи хранятся в настройках программы
    напр, список скриптов - в проекте, а положение фоорм скриптов - в настройках
    настр программы
      - список проектов
      - список окон и положение окон
      - настройка питона
      - шрифты
      - доступные БД (при создании подключения к БД она попадает и сюда, и в активный проект)

    парамеры, хрянящиеся в проекте
      - список скриптов(надо как о этим списком управлять)(должна быть команда view (она раньше была!!!- подключить событие!!!))
      - пути к папкам (свой диалог открытия файла, сначала предлагать из папок проекта)
        (питоноскрипы должны и ошибки в лог выводить!!!)
      - кнопки панели инструментов, создаваемые в проекте
      - история браузера
      - подключенные к проекту БД (если мы хотим открыть уже существующие БД, мы сначала
        лезем в список программы и спрашиваем, нужно ли ее подключить к проекту)

    прога не может работать без открытого проекта. в начале работы автоматически открывается последний проект,
    либо она переходит в режим создания нового проекта
    в новом проекте нужно указать название  проекта и его котологи (если не указан, то не используется)
      может быть опционально
      - запускать скрипты с их перечислением
      - указать переменные проекта
      - что то еще...


    для полного кайфа надо сделать мастер по переносу данных из хромохистори в прогу
    (иначе она нафиг будет не нужна, руками дрочиться по переносу 50 книг заебешься)

  }

  { TETLProject }

  TETLProject = class(TCustomPropStorage)
    private
      FButtons: TCollection;
      FProjName: string;
      FRootDir:string;
      FDataDir: string;
      FDBDir: string;
      FSCR: TStrings;
      FScrDir: string;
      FShellDir: string;
      FLinkedDataBases:TStrings;
      procedure SetRootDir(AValue:string);
      function GetFullDataDir: string;
      function GetFullDBDir: string;
      function GetFullScrDir: string;
      function GetFullShellDir: string;
      function GetLinkedDataBases: TStrings;
      procedure SetDataDir(AValue: string);
      procedure SetDBDir(AValue: string);
      procedure SetScrDir(AValue: string);
      procedure SetShellDir(AValue: string);
    public
      constructor Create(AFileName: string); override;
      destructor Destroy; override;
      procedure CreateNewProj;

      property FullDataDir:string read GetFullDataDir;
      property FullScrDir:string read GetFullScrDir ;
      property FullDBDir:string read GetFullDBDir;
      property FullShellDir:string read GetFullShellDir;
      function FullScrPath(AName:string):string;
      procedure DirsChanged;
      property RootDir:string read FRootDir write SetRootDir;
      procedure Load;override;
      procedure Save;override;
      function AddMRUDB(ADB:string):boolean;
      procedure AddMRUScr(AScr:string);
    published
      property ProjName:string read FProjName write FProjName;
      property DataDir:string read FDataDir write SetDataDir;
      property ScrDir:string read FScrDir write SetScrDir;
      property DBDir:string read FDBDir write SetDBDir;
      property ShellDir:string read FShellDir write SetShellDir;
      property LinkedDataBases:TStrings read GetLinkedDataBases;
      property SCR:TStrings read FSCR;
      property Buttons:TCollection read FButtons;

  end;


var
  Data: TData;

function GetAppPath:string;

function Options:TOptions;


implementation

uses s_tools, U_simplescr, DateUtils, main, process, LConvEncoding;

//const oName = '.otypes';

var FOptions:TOptions = nil;

function GetAppPath: string;
begin
  Result:=ExtractFileDir(ParamStr(0));
end;

function Options: TOptions;
begin
  if FOptions=nil then
    FOptions:=TOptions.Create('');
  Result:=FOptions;
end;

{$R *.lfm}

{ TDBColItem }

function TDBColItem.GetParams: TStrings;
begin
  Result:=FParams;
end;


function TDBColItem.GetAsText: string;
begin
  Result:='%s(%s)'.Format([FName,FTypeName]);
end;

function TDBColItem.GetColCount: integer;
begin
  Result:=FColumns.Count;
end;

function TDBColItem.GetColumns(I: integer): TDBColWidth;
begin
  Result:=(FColumns.Items[I] as TDBColWidth);
end;

procedure TDBColItem.SetParams(AValue: TStrings);
begin
  FParams.Assign(AValue);
end;

constructor TDBColItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FParams:=TStringList.Create;
  FColumns:=TCollection.Create(TDBColWidth);
end;

destructor TDBColItem.Destroy;
begin
  FParams.Free;
  FColumns.Free;
  inherited Destroy;
end;

function TDBColItem.NewCol: TDBColWidth;
begin
  Result:=TDBColWidth(FColumns.Add);
end;

{ TETLProject }

procedure TETLProject.SetRootDir(AValue: string);
begin
  if FRootDir <> AValue then
    FRootDir:=AValue;
end;

function TETLProject.GetFullDataDir: string;
begin
  Result:=FRootDir+'\'+FDataDir;
end;

function TETLProject.GetFullDBDir: string;
begin
  Result:=FRootDir+'\'+FDBDir;
end;

function TETLProject.GetFullScrDir: string;
begin
  Result:=FRootDir+'\'+FScrDir;
end;

function TETLProject.GetFullShellDir: string;
begin
  Result:=FRootDir+'\'+FShellDir;
end;

function TETLProject.GetLinkedDataBases: TStrings;
begin
  Result:=FLinkedDataBases;
end;

procedure TETLProject.SetDataDir(AValue: string);
begin
  if FDataDir=AValue then Exit;
  FDataDir:=AValue;
end;

procedure TETLProject.SetDBDir(AValue: string);
begin
  if FDBDir=AValue then Exit;
  FDBDir:=AValue;
end;

procedure TETLProject.SetScrDir(AValue: string);
begin
  if FScrDir=AValue then Exit;
  FScrDir:=AValue;
end;

procedure TETLProject.SetShellDir(AValue: string);
begin
  if FShellDir=AValue then Exit;
  FShellDir:=AValue;
end;

constructor TETLProject.Create(AFileName: string);
begin
  if AFileName=' ' then
    raise Exception.Create('Invalid Project Name!!!');
  FLinkedDataBases:=TStringList.Create;
  FSCR:=TStringList.Create;
  FButtons:=TCollection.Create(TBtnColItem);
  if not FileExists(AFileName) then begin
    frmMain.Log('loadprj','File '+ AFileName+' not found!');
  end;
  if AFileName<>'' then
    FRootDir:=ExtractFileDir(AFileName);
  if FRootDir = '' then
    FRootDir:=GetCurrentDir;
  FDataDir:='';
  FScrDir:='';
  FShellDir:='';
  FDBDir:='';
  if AFileName='' then AFileName:=' ';
  inherited Create(AFileName);
  if AFileName=' ' then begin
    AFileName:='';
  end;
end;

destructor TETLProject.Destroy;
begin
  inherited Destroy;
  FLinkedDataBases.Free;
  FreeAndNil(FButtons);
  FSCR.Free;
end;

procedure TETLProject.CreateNewProj;
begin
  //создает все котологи проекта, которые заданы
  //!!!
  if FDataDir<>'' then
    ForceDirectories(FullDataDir);
  if FDBDir<>'' then
    ForceDirectories(FullDBDir);
  if FShellDir<>'' then
    ForceDirectories(FullShellDir);
  if FScrDir<>'' then
    ForceDirectories(FullScrDir);
  FFileName:=FRootDir+'\'+FProjName+'.zexp';
  Save;
  Options.AddLastProject(FFileName);
end;

function TETLProject.FullScrPath(AName: string): string;
begin
  Result:=FullScrDir+'\'+AName;
end;

procedure TETLProject.DirsChanged;
var SL:TStringList;
begin
  try
    SL:=TStringList.Create;
    SL.Add('#параметры настройки для файлоф python');
    SL.Add('ZEXP_DATA_DIR = r'''+FullDataDir+'''');
    SL.Add('ZEXP_DB_DIR = r'''+FullDBDir+'''');
    SL.Add('ZEXP_SCR_DIR = r'''+FullScrDir+'''');
    SL.Add('ZEXP_SHELL_DIR = r'''+FullShellDir+'''');
    SL.SaveToFile(FullScrDir+'\'+'zexp_params.py');
    SL.SaveToFile(FullShellDir+'\'+'zexp_params.py');
  finally
    SL.Free;
  end;
end;

procedure TETLProject.Load;
begin
  if FFileName<>'' then
    inherited Load;
end;

procedure TETLProject.Save;
begin
  if FFileName='' then Exit;
  inherited Save;
end;

function TETLProject.AddMRUDB(ADB: string): boolean;
var I:Integer;
begin
  Result:=True;
  I:=FLinkedDataBases.IndexOf(ADB);
  if I=0 then begin
    Result:=False;
    Exit;
  end;
  if I=-1 then begin
    FLinkedDataBases.Insert(0,ADB);
    while FLinkedDataBases.Count>5 do
      FLinkedDataBases.Delete(FLinkedDataBases.Count-1);
  end else begin
    FLinkedDataBases.Move(I,0);
  end;
end;

procedure TETLProject.AddMRUScr(AScr: string);
begin
  if FSCR.IndexOf(AScr)=-1 then
    FSCR.Add(AScr);
end;

{ TAdvAction }

procedure TAdvAction.DoExecute(Sender: TObject);
begin
  if Assigned(FColItem) then
    FColItem.DoExecute(Self);
end;

constructor TAdvAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColItem:=nil;
  OnExecute:=@DoExecute;
end;

{ TBtnColItem }

procedure TBtnColItem.DoExecute(Sender: TObject);
var S2:string;
  //PWChar:PWideChar;
  //StartupInfo:TSTARTUPINFOW;
  //ProcessInfo:TPROCESSINFORMATION;
begin
  case FAdvType of
    atScr:Exec(Cmd);
    atPy: if RunCommandIndir(Options.ActivePrj.FullDataDir, Options.PyPath, [Options.ActivePrj.FullScrDir+'\'+Cmd], S2, [poStderrToOutPut])
        then begin
          frmMain.Log('main','py_scr worked. output:'+#13#10+CP1251ToUTF8(S2));
        end else begin
          frmMain.Log('main','run PyScr %s failed'.Format([Cmd]))
        end;
    atExe:begin//if
      frmMain.Log('main','starting: ' + Cmd);
      Data.ProcessUTF8_1.Executable:=Cmd;
      Data.ProcessUTF8_1.Execute;
    end;
  end;
end;

function TBtnColItem.GetDisplayName: string;
begin
  Result:=FBntText;
  if Result='' then Result:=FMenuText;
  if Result='' then Result:=FCmd;
  if Result='' then Result:=inherited GetDisplayName; //такого не должно быть
end;

{ TOptions }

function TOptions.GetMRUList: TStrings;
begin
  Result:=FMRUList;
end;

procedure TOptions.SetMRUList(AValue: TStrings);
begin
  FMRUList.Clear;
  FMRUList.Assign(AValue);
end;

constructor TOptions.Create(AFileName: string);
begin
  //FButtons:=TCollection.Create(TBtnColItem);
  FDataBases:=TCollection.Create(TDBColItem);
  FMRUList:=TStringList.Create;
  FPrjList:=TStringList.Create;
  FActiveProject:='';
  FBtnFont:=10;
  FEditFont:=10;
  FIntfFont:=10;
  FMiniFont:=10;
  FTreeFont:=10;
  inherited Create(AFileName);
end;

destructor TOptions.Destroy;
begin
  inherited Destroy;
  //FreeAndNil(FButtons);
  FreeAndNil(FDataBases);
  FreeAndNil(FMRUList);
  FreeAndNil(FPrjList);
end;

function TOptions.GetFullPath(AShort: string): string;
begin
  Result:=AShort;
  if Pos(':',AShort)>0 then begin
  end else begin
    Result:=ExtractFileDir(ParamStr(0)) + '\'+AShort;
  end;
end;

function TOptions.GetFullPath(AShort, AFileName: string): string;
begin
  Result:=GetFullPath(AShort)+'\'+AFileName;
end;

procedure TOptions.AddMRUFile(AFileName: string);
var I:Integer;
begin
  if AFileName = '' then Exit;
  I:=FMRUList.IndexOf(AFileName);
  if I<>-1 then begin
    FMRUList.Move(I,0);
    Exit;
  end;
  FMRUList.Insert(0,AFileName);
  while FMRUList.Count>10 do
    FMRUList.Delete(FMRUList.Count-1);
end;

procedure TOptions.AddLastProject(AProject: string);
var
  I: Integer;
begin
  FActiveProject:=AProject;
  I:=FPrjList.IndexOf(AProject);
  if I= -1 then begin
    FPrjList.Insert(0,AProject);
    while FPrjList.Count > 5 do
      FPrjList.Delete(FPrjList.Count-1)
  end
  else
    FPrjList.Move(I,0)
end;

function TOptions.GetDBInfo(AName, AType: string): TDBColItem;
var
  i: TCollectionItem;
begin
  Result:=nil;
  for i in FDataBases do
    if (TDBColItem(i).FName = AName) and (TDBColItem(i).FTypeName = AType) then begin
      Result:=TDBColItem(I);
      Break;
    end;
end;

function TOptions.GetUID: string;
begin
  Result:=IntToStr(InterlockedIncrement(FUID));
end;

procedure TOptions.Load;
begin
  inherited Load;
  LoadStrings('mru',FMRUList);
  LoadStrings('proj',FPrjList);
end;

procedure TOptions.Save;
begin
  SaveStrings('mru',FMRUList);
  SaveStrings('proj',FPrjList);
  inherited Save;
  FETLProj.Save;
end;

function TOptions.NewProj: TETLProject;
begin
  Result:=TETLProject.Create('');
end;

procedure TOptions.SetActivePrj(APrj: TETLProject);
begin
  CloseActivePrj;
  FETLProj:=APrj;
  AddLastProject(APrj.FFileName);
  //после вызова, а также в иных случаях (измененя папок), необходимо пересоздавать в котологе
  //скриптов пути к папкам проекта
end;

procedure TOptions.CloseActivePrj;
begin
  if FETLProj=nil then Exit;
  if FETLProj.FFileName<>'' then
    FETLProj.Save
  else
    FETLProj.Modified:=False;
  FreeAndNil(FETLProj);
end;

procedure TOptions.LoadPrj(AFileName: string);
begin
  if FETLProj<>nil then begin
    AddLastProject(FETLProj.FFileName);
    CloseActivePrj;
  end;
  FETLProj:=TETLProject.Create(AFileName);
  AddLastProject(AFileName);
end;

{ TData }

procedure TData.DataModuleCreate(Sender: TObject);
//var SL:TStringList;
begin
  //SL:=TStringList.Create;
  //Options.LoadStrings('scripts',SL);
  //U_simplescr.InitModule(SL);
  //SL.Free;
end;

procedure TData.DataModuleDestroy(Sender: TObject);
var SL:TStringList;
begin
  SL:=TStringList.Create;
  try
    //U_simplescr.GetScrNames(SL);
    //Options.SaveStrings('scripts',SL);
  finally
    SL.Free;
  end;
end;

procedure TData.SaveComponent(Cmp: TComponent; Props: string);
begin
  Options.SaveComponent(Props,Cmp);
end;

procedure TData.LoadComponent(Cmp: TComponent; Props: string);
begin
  Options.LoadComponent(Props,Cmp);
end;

function TData.GetGW(AColumns: tdbgridColumns): string;
var I:integer;
begin
  Result:='';
  for I:=0 to AColumns.Count-1 do begin
    if Result<>'' then Result:=Result+'@';
    Result:=Result+IntToStr(AColumns[I].Width);
  end;
end;

procedure TData.SetCW(AColumns: tdbgridColumns; W: string);
var I:Integer;
begin
  for I:=0 to AColumns.Count-1 do begin
    if W='' then Break;
    AColumns[I].Width:=StrToInt(DivStr(W,'@'));
  end;
end;

initialization

finalization
  FOptions.Modified:=True;
  FOptions.Save;
  FreeAndNil(FOptions);


end.

