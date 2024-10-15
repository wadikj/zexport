unit U_simplescr;

{$mode objfpc}{$H+}
{$WARN 4105 off : Implicit string type conversion with potential data loss from "$1" to "$2"}
{$WARN 4104 off : Implicit string type conversion from "$1" to "$2"}
interface

uses
  Classes, SysUtils, Variants{-}, DateUtils, Dialogs,
  u_brman, process;

type

  TSimpleScript = class;

  TOnGetHRoot = function (): IDispatch of object;
  TInternalProc = procedure (Sender:TSimpleScript; AParam:string) of object;
  TCloseWinProc  =  procedure of object;
  TLogProc = procedure (AData:string) of object;


  TExtItem=record
    Name:string;
    Proc:TInternalProc;
  end;

  TExtList = array of TExtItem;


  { TSimpleScript }

  TSimpleScript = class
    private
      FCode:TStringList;
      FDlm:string;
      FResStr:string;
      FName:string;
      //flags
      FBreakScr:boolean;
      //new items
      FLink:TScrLink;
      function GetVars(AName: string): string; ///+++
      function Get_Text: TStrings; ///+++
      procedure SetVars(AName: string; AValue: string); ///+++
      function GetScrRoot:TSimpleScript; ///+++
    protected
      FParent:TSimpleScript;
      FVars:TStringList;
      FData:TStringList;
      FCurrStr:Integer;
    public
      constructor Create(AName:string); ////+++
      destructor Destroy;override; ///+++
      procedure Exec(AName:string='');     ///+++
      procedure FireEvent(S:string); ///---
      procedure SaveScr;///++
      procedure RunScr(Line:Integer = 0);   ///+++

      procedure ExecStr(AStr:string); ///+++

      procedure SaveRes(s:string); ///+++
      procedure ExecJS(S:string); ///---
      property _Text:TStrings read Get_Text;///+++
      procedure ForEach(scr:string); ///+++
      procedure _for(Scr:string);    ///+++
      procedure IfBreak(scr:string); ///+++
      procedure _goto(S:string);     ///+++
      procedure _ifexist(S:string; e:boolean); ///+++
      procedure _if(S:string);          ///+++
      procedure _run_py(S:string);     ///+++
      procedure _vload(S:string);     ///+++
      procedure _vsave(S:string);     ///+++
      procedure _uid(S:string);
      procedure _inc(S:string);
      procedure _rnd(S:string);
      procedure Log(S:string);        ///+++
      procedure AddStr(S:string);     ///+++
      function GetLSData(S:string):string ; ///+++
      property BreakScr:boolean read FBreakScr write FBreakScr;
      procedure SaveData(S:String); ///+++
      procedure WaitFor(S:String); ///+++
      procedure WaitDiff(S:string);   ///+++
      function CreateFileName(S:string):string; ////нужно через нее команду сделать!!!
      procedure ConcatStr(S:string);

      property ResStr:string read FResStr write FResStr;
      property Vars[AName:string]:string read GetVars write SetVars;
      property Name:string read FName;
      function GetData:TStringlist;
      procedure FreeData;
      procedure Delay(I:Integer);
  end;

procedure Exec(AName:string; AParent:TSimpleScript = nil); /// запускает скрипт работать только через эту процедуру
function GetScript(AName:string):TSimpleScript;//возвращает объект скрипта по имени
procedure RegisterInternalProc(ProcName:string;AProc:TInternalProc);//добавляет новую внешнюю процедуру
procedure UnRegisterInternalProc(ProcName:string);//удаляет ее
//устанавливает стандартные обработчики
procedure SetGetProcs(OnLog, OnView:TLogProc);
///!!!и это убрать //через там какой-то менеджер
procedure BreakExec;

implementation

uses s_tools, u_data, Forms, LazUTF8, LConvEncoding;

const DefVarsName = 'vars';

{///!!!хранить не список объектов скриптов, а либо имена, либор вместе
с текстом, и при каждом запуске создавать новый объект
надо прибумать сособ, как связать с цепочкой скриптов цепочку
открытых окон браузера, (передавать в каждую браузерную команду
текущий объект скрипта, либо сразу же привызывать
к браузеру корневой скрипт, и в нем хранить список окон)

и да, надо сделать так, чтобы можно было извне задавать,
это у нас будет визуальный браузер или невидимый

должна быть какая то прокладка, которая хранит связь между браузером
и цепочкой скриптов времени выполнения

}
var
  ExternalList:TExtList;
  //FScrList:TStringList = nil;
  FOnLog:TLogProc = nil;
  FOnView:TLogProc = nil;


procedure CallExt(AScr:TSimpleScript;AName:string);
var I:Integer;
begin
  ///AName  = оно уже в нижнем регистре
  for I:=Low(ExternalList) to High(ExternalList) do begin
    if AName=ExternalList[I].Name then begin
      ExternalList[I].Proc(AScr,'');
      Break;
    end;
  end;
end;

procedure Exec(AName: string; AParent: TSimpleScript);
var I:Integer;
    scr:TSimpleScript;
    ProcName,S:string;
begin
  try
    //получаем имя скрипта
    S:=DivStr(AName,'@');
    if S='' then S:=AParent.FName;
    scr:=TSimpleScript.Create(S);
    I:=0;
    if AName<>'' then begin
      ProcName:='@'+AName;
      I:=scr.FCode.IndexOf(ProcName);
    end;
    if I<>-1 then begin
      scr.FParent:=AParent;
      if scr.FParent<>nil then begin
        scr.FLink:=BrMan.GetScrLink(AParent.FLink);
      end else begin
        scr.FLink:=BrMan.GetScrLink(nil);
      end;
      if I<>0 then Inc(I);
      scr.RunScr(I);
    end;
    scr.Free;
  except    //при ошибке цепочка скриптов не уничтожается
    ShowMessage('failed to exec script '+AName);
    if AParent=nil then
      ShowMessage('parent = nil!!!');
  end;
end;

function GetScript(AName: string): TSimpleScript;
begin
  Result:=TSimpleScript.Create(AName);
end;


procedure RegisterInternalProc(ProcName: string; AProc: TInternalProc);
begin
  SetLength(ExternalList,Length(ExternalList)+1);
  ExternalList[High(ExternalList)].Name:=LowerCase(ProcName);
  ExternalList[High(ExternalList)].Proc:=AProc;
end;

procedure UnRegisterInternalProc(ProcName: string);
var I:Integer;
begin
  ///ProcName  = оно уже в нижнем регистре
  ProcName:=LowerCase(ProcName);
  for I:=Low(ExternalList) to High(ExternalList) do begin
    if ProcName=ExternalList[I].Name then begin
      ExternalList[I].Name:='';
      ExternalList[I].Proc:=nil;
      Break;
    end;
  end;
end;

procedure SetGetProcs(OnLog, OnView: TLogProc);
begin
  FOnLog:=OnLog;
  FOnView:=OnView;
end;

procedure NewScr(ANewName: string);
begin
   //FScrList.Add(ANewName);
end;

procedure InitModule(SL: TStrings);
//var I:Integer;
begin
{  if FScrList=nil then FScrList:=TStringList.Create;
  if SL<>nil then FScrList.Assign(SL);
  for I:=0 to FScrList.Count-1 do begin
      FScrList.Objects[I]:=TSimpleScript.Create(FScrList[I]);
  end;}
end;


procedure BreakExec;
var I:Integer;
    S:TSimpleScript;
begin
  ShowMessage('This method must be deleted!!!');
  {for I:=0 to FScrList.Count-1 do begin
    S:=TSimpleScript(FScrList.Objects[I]);
    S.BreakScr:=True;
  end;}
end;

procedure NewSct(ANewName: string);
begin
  //FScrList.Add(ANewName);
end;

{ TSimpleScript }

function TSimpleScript.Get_Text: TStrings;
begin
  Result:=FCode;
end;

function TSimpleScript.GetVars(AName: string): string;
begin
  if Self=Self.FParent then
    Exit;
  Result:='';
  if FParent<>nil then Result:=FParent.GetVars(AName)
  else begin
    if FVars<>nil then Result:=FVars.Values[AName];
  end;
end;

procedure TSimpleScript.SetVars(AName: string; AValue: string);
begin
  if FParent=Self then begin
    ShowMessage('Parent = self');
    Exit;
  end;
  if FParent<>nil then FParent.SetVars(AName,AValue)
  else begin
    if FVars=nil then FVars:=TStringList.Create;
    FVars.Values[AName]:=AValue;
  end;
end;

function TSimpleScript.GetScrRoot: TSimpleScript;
begin
  Result:=Self;
  if FParent=nil then Exit;
  Result:=FParent.GetScrRoot;
end;

constructor TSimpleScript.Create(AName: string);
var S:string;
begin
  ///Log('scr '+AName+' created');
  FBreakScr:=False;
  FDlm:='|';
  FCode:=TStringList.Create;
  FName:=AName;
  FParent:=nil;
  FVars:=nil;
  FData:=nil;
  //и тут надо сразу же загрузить этот скрипт
  //S:=Options.GetFullPath(Options.ScrDir,AName);
  S:=Options.ActivePrj.FullScrDir+'\'+AName;
  if FileExists(S) then
    FCode.LoadFromFile(S);
end;

destructor TSimpleScript.Destroy;
begin
  ///Log('scr '+FName+' Destroyed');
  FCode.Free;
  FreeAndNil(FData);
  FreeAndNil(FLink);
  inherited Destroy;
end;

procedure TSimpleScript.Exec(AName: string);
begin
  if AName='' then Exit;
  if AName[1]='@' then
    AName:=FName+AName;
  U_simplescr.exec(AName,Self);
end;

procedure TSimpleScript.FireEvent(S: string);
//var ov:OleVariant;
begin
  {try
    if FCurrent<>nil then begin
      ov:=FCurrent;
      ov.FireEvent(S);
    end;
  except
    on e :exception do
      ShowMessage(UTF8Encode(e.Message));
  end;}
end;

procedure TSimpleScript.SaveScr;
begin
  FCode.SaveToFile(
  //Options.GetFullPath(Options.ScrDir,FName)
  Options.ActivePrj.FullScrDir+'\'+FName
  );
end;

procedure TSimpleScript.RunScr(Line: Integer);
var I:Integer;
begin
  FResStr:='';
  FCurrStr:=Line;
  FBreakScr:=False;
  I:=0;
  while True do begin
    if (FCurrStr>=FCode.Count) or (FCurrStr<0) then Break;
    if (FCode[FCurrStr]<>'')and(FCode[FCurrStr][1]='@') then Break;
    ExecStr(FCode[FCurrStr]);
    if FBreakScr then Break;
    Application.ProcessMessages;
    Application.ProcessMessages;
    Application.ProcessMessages;
    Application.ProcessMessages;
    Application.ProcessMessages;
    Inc(FCurrStr);
    Inc(I);
    if I > 1000 then begin
      Log('Too many iterations!!!');
      Break;
    end;
  end;
end;

procedure TSimpleScript.ExecStr(AStr:string);
var S,Cmd:string;
    SL:TStrings;
begin
  try
    S:=Trim(AStr);
    if Length(S)=0 then Exit;
    if S[1] = '@' then begin
      FBreakScr:=True;
      Exit;
    end;
    if S[1]='*' then Exit;
    if S[1]='#' then Exit;
  	Cmd:=LowerCase(DivStr(S,'='));
    if Cmd<>'' then
    if Cmd[1]='$' then begin
       Vars[Cmd]:=GetLSData(S);
    end else
    case Cmd of
      'wait':
        while not FLink.Complete do
          Delay(200);
      'name':
    		FLink.SelByName(S);
      'id':
        FLink.SelByID(S);
      'attr':begin
  		  Cmd:=DivStr(S,',');
        FLink.Attr:=Cmd;
        FLink.AttrValue:=S;
      end;
      'click':begin
        ///Log('Click start');
        FLink.Click;
        ///Log('Click end');
      end;
      'path':
        FLink.SetCurrent(S);
      'idx':
        FLink.SelectIndex(StrToInt(GetLSData(S)));
      'select':begin
        FLink.Select;
      end;
      'location':
        FLink.Location:=GetLSData(S);
      'delay':begin
        if S='' then S:='3000';
        Delay(StrToInt(S))
      end;
      'msg':begin
        ShowMessage(GetLSData(S));
      end;
      'submit':
        FLink.Submit;
      'view':
        if Assigned(FOnView) then begin
          SL:=GetData;
          if SL<>nil then
            FOnView(SL.Text)
        end
        else
          Log('Error view data!!!');
      'foreach':
        ForEach(S);
      'execjs':
        ExecJS(S);
      'setlr':
        FLink.SetLr;
      'test':
        //frmMain.Log('test',SupportStr(FCurrent));
        ;
      'exit':
        FBreakScr:=True;
      'exec':
        //ExecJS((FCurrent as IHTMLElement).innerHTML)
        ;
      'event':
        FireEvent(S);
      'log':
        Log(S);
      'addstr':
        AddStr(S);
      'scr':
        Exec(GetLSData(S));
      'getlr':
        FLink.GetLr;
      'savedata':
        SaveData(CreateFileName(S));
      'savepage':
        FLink.SavePage(CreateFileName(S));
      'waitfor':
        WaitFor(S);
      'waitdiff':
        WaitDiff(S);
      'saveres':begin
        SaveRes(FResStr);
        FResStr:='';
      end;
      'for':
        _for(S);
      'goback':
        FLink.GoBack;
      'ifbreak':
        IfBreak(S);
      'goto':
        _goto(s);
      'ifexist':
        _ifexist(S,True);
      'ifnexist':
        _ifexist(S,false);
      'if':
        _if(S);
      'run_py':
        _run_py(S);
      'vload':
        _vload(S);
      'vsave':
        _vsave(S);
      'gethead':
        SaveRes(FLink.GetHead);
      'getbody':
        SaveRes(FLink.GetBody);
      'newbrowser':
        FLink.NewBrowser(S);
      'close':
        FLink.CloseBrowser(S);
      'concat':
        ConcatStr(S);
      'inc':_inc(S);//если 1 парам число, то увеличивает на 1, или добавл 2 число, если есть
      'rnd':_rnd(S);//в 1 парам пихается случ, 2 и 3 парам - границы, если 3 нет, то нижн граница 0
      'uid':begin//возвр уникальный ид (типа AUTOINC)
        _uid(S);
      end;
      else begin
        CallExt(Self,Cmd);
      end;
    end;
  except
    on E:exception do
      Log('Exception '+E.ClassName + ' with message '+E.Message + ' at str:' + AStr);
  end;
end;

procedure TSimpleScript.SaveRes(s: string);
begin
  if FParent<> nil then
    FParent.SaveRes(S)
  else begin
    if FData=nil then FData:=TStringList.Create;
    FData.Add(S);
  end;
end;

procedure TSimpleScript.ExecJS(S: string);
{var win: IHTMLWindow2;
    D:IHTMLDocument2;}
begin
  {D:=(GetDoc as IHTMLDocument2);
  win:=D.parentWindow;
  if win <> nil then begin
    try
      try
        win.ExecScript(widestring(S), 'javascript');
      except
        on e :exception do
          ShowMessage(UTF8Encode(e.Message));
      end;
    finally
      win := nil;
    end;
  end;}
end;

procedure TSimpleScript.ForEach(scr: string);
var I:Integer;
begin
  if not FLink.CurrentExists then Exit;
  FLink.SaveCurrent;
  I:=0;
  while True do begin
    FLink.LoadCurrent;
    FLink.SetCurrent('\'+IntToStr(I),False);
    if not FLink.CurrentExists then Break;
    if FBreakScr then Break;
    Exec(Scr);
    Inc(I);
  end;
  FLink.LoadCurrent;
end;

procedure TSimpleScript._for(Scr: string);
var DefPath,
    VarName,S:string;
    I:Integer;
begin
  {тут нужен for, такой, чтобы он работал при обновлении строки между итерациями
  во внешней переменной храним рабочий индекс
  на вход передаем путь, по которому лезем, переменную для хранения индекса и имя
  процедуры, которую вызываем в цикле
  }
  //Var must be empty or number (int)
  //for=DefPath,VarName,Scr
  DefPath:=DivStr(Scr);
  VarName:=DivStr(SCR);
  S:=Vars[VarName];
  if S='' then Vars[VarName]:='0';
  while True do begin
    S:=DefPath+'\'+Vars[VarName];
    FLink.SetCurrent(S);
    if FLink.CurrentExists then Break;
    if FBreakScr then Break;
    Exec(Scr);
    I:=StrToInt(Vars[VarName]);
    Inc(I);
    Vars[VarName]:=IntToStr(I);
  end;
end;

procedure TSimpleScript.IfBreak(scr: string);
var S1,S2:string;
    B:Boolean;
begin
  {также нужен какой нить breakif, чтобы он прерывал цикл, если 2 переменные на входе (не)совпадают}
  {и следует помнить, что любая команда может изменить текущий узел, поэтому нам всегда надо быть точно уверенным
  (специально задавать) путь перед какой нлибо операщией}
  S1:=GetLSData(DivStr(scr));
  S2:=GetLSData(DivStr(scr));
  B:=S1=S2;
  if scr='1' then b:=not B;
  FBreakScr:=B;
end;

procedure TSimpleScript._goto(S: string);
var I:Integer;
begin
  if Trim(S) = '' then begin
    FCurrStr:=FCode.Count;
    Exit;
  end;
  if S[1] = '#' then begin
    I:=FCode.IndexOf(s);
    if I<>-1 then
      FCurrStr:=I
    else
      FCurrStr:=FCode.Count;
  end else begin
    I:=StrToInt(S);
    FCurrStr:=FCurrStr+I-1;
  end
end;

procedure TSimpleScript._ifexist(S: string; e: boolean);
var go:string;
    param:string;
    R:boolean;
begin
  R:=False;
  //e - true - exist, false - not exist
  go:=DivStr(S);
  param:=S;
  //param $ - var, other - path, if none - currpath
  if param='' then begin
    if FLink.CurrentExists then
      R:=True;
  end else
  if (param[1]='$') or (param[1]='.')or(param[1]='@') then begin
    param:=GetLSData(param);
    R:=param<>'';
  end else begin
    FLink.SaveCurrent;
    FLink.SetCurrent(param);
    R:=FLink.CurrentExists;
    FLink.LoadCurrent;
  end;
  if not e then R:=not R;
  if R then
    _goto(go);
end;

procedure TSimpleScript._if(S: string);
var go: string;
    p1, p2: string;
    op:string;
    R:boolean;
begin
  {params:
    0 - offset
    1 - first compare
    2 - compare operator
    3 - last copare}
  {operators
    =, <, >, ! - equ, , greater, not equ
    @, !@ - contain, not contain
  }
  go:=DivStr(S);
  p1:=DivStr(S);
  op:=DivStr(S);
  p2:=S;
  p1:=GetLSData(p1);
  p2:=GetLSData(p2);
  //если ничего нет, то равно
  case op of
    '<': R:=p1<p2;
    '>': R:=p1>p2;
    '!': R:=p1<>p2;
    '@': R:=Pos(p1,p2)>0;
    '!@':R:=Pos(p1,p2)=0;
    else
      R:=p1=p2;
  end;
  if R then _goto(go);
end;

procedure TSimpleScript._run_py(S: string);
var S1,S2:string;
begin
  //запускаем переданный скрипт
  //из каталога скриптов
  //может быть указано что то, что рассматривается как параметры команд
  //vload, vsave
  //если не указан, то имя файл не требуется
  ///!!!также надо сделать, чтобы в команде scr можно было
  ///использовать имена переменных
  if Options.PyPath='' then begin
    Log('Path to python interpreter not set!!!');
    Exit;
  end;
  S1:=DivStr(S);//file name
  if S<>'' then
    _vsave(S);
  if RunCommandIndir(Options.ActivePrj.FullDataDir, Options.PyPath, [Options.ActivePrj.FullScrDir+'\'+S1], S2, [poStderrToOutPut])
  then begin
    Log('py_scr worked. output:'+#13#10+CP1251ToUTF8(s2));
    if S<>'' then
      _vload(S);
  end
  else begin
    Log('Error run script');
    Log(S2);
  end;
end;

procedure TSimpleScript._vload(S: string);
var FileName,S1:String;
    SL:TStringList;
    I:integer;
begin
  //грузим переменные из файла, если список пуст, то пишем все
  ///!!!нужна поддержка котолога Data
  FileName:=DivStr(s);
  if FileName = '' then FileName := DefVarsName;
  FileName:=Options.ActivePrj.FullScrDir+'\'+FileName;
  if FileExists(FileName) then try
    SL:=TStringList.Create;
    SL.LoadFromFile(FileName);
    if S = '' then begin
      for I:=0 to SL.Count-1 do begin
        S1:=SL.Names[I];
        if (S1<>'') and (S1[1]='$') then
          Vars[S1]:=SL.ValueFromIndex[I];
      end;
    end else begin
      while S<>'' do begin
        S1:=DivStr(S);
        Vars[S1]:=SL.Values[S1];
      end;
    end;
  finally
    SL.Free;
  end;
end;

procedure TSimpleScript._vsave(S: string);
var SL:TStringList;
    S1,FileName:string;
begin
  FileName:=DivStr(S);
  if FileName = '' then FileName := DefVarsName;
  FileName:=Options.ActivePrj.FullScrDir + '\' + FileName;
  if S<>'' then begin
    SL:=TStringList.Create;
    while S<>'' do begin
      S1:=DivStr(S);
      SL.Add(S1+'='+Vars[S1]);
    end;
    SL.SaveToFile(FileName);
    SL.Free;
  end else begin
    GetScrRoot.FVars.SaveToFile(FileName);
  end;
end;

procedure TSimpleScript._uid(S: string);
var param:string;
begin
  param:=DivStr(S,',');
  Vars[param]:=Options.GetUID;
end;

procedure TSimpleScript._inc(S: string);
var VName,V,Add:string;
begin
  VName:=DivStr(S);
  V:=Vars[VName];
  Add:=GetLSData(DivStr(S));
  if Add='' then Add:='1';
  if IsNumber(V) and IsNumber(Add) then
    Vars[VName]:=IntToStr(StrToInt(V)+StrToInt(Add))
  else
    Vars[VName]:=V+Add;
end;

procedure TSimpleScript._rnd(S: string);
var VName, Min, Max:string;
    M1,M2,R:Integer;
begin
  //по умолчанию от 0 до 1000
  VName:=DivStr(S);
  Min:=DivStr(S);
  Max:=DivStr(S);
  if Max = '' then begin
    Max := Min;
    Min:='0';
  end;
  if (Max = '') or (Min='') then begin
    Max:='1000';
    Min:='0';
  end;
  M1:=StrToInt(GetLSData(Min));
  M2:=StrToInt(GetLSData(Max));
  R:=Random(M2-M1);
  Vars[VName]:=IntToStr(R+M1);
end;

procedure TSimpleScript.Log(S: string);
var S1:String;
begin
  S1:=GetLSData(S);
  if S='' then
    S1:=FResStr;
  if Assigned(FOnLog) then
    FOnLog(S1);
end;

procedure TSimpleScript.AddStr(S: string);
begin
  FResStr:=StrListAdd(FResStr,GetLSData(S),FDlm);
end;

function TSimpleScript.GetLSData(S: string): string;
begin
  Result:='';
  if S='' then Exit;
  if (S[1]='.') or (S[1]='@') then begin
    if S='.ti' then begin
      Result:=TimeToStr(Now);
      Exit;
    end else
    if S='.dt' then begin
      Result:=DateToStr(Now);
      Exit;
    end else
    if S='.loc' then begin
      Result:=FLink.Location;
      Exit;
    end;
    Result:=FLink.GetTextFrom(S);
    Exit;
  end;
  if S[1]='$' then begin
    Result:=Vars[S];
    Exit;
  end;
  Result:=S;
end;

procedure TSimpleScript.SaveData(S: String);
var SL:TStrings;
begin
  SL:=GetData;
  if SL<>nil then begin
    SL.SaveToFile(
      Options.ActivePrj.FullDataDir+'\'+S
    );
    FreeData;
  end;
end;

procedure TSimpleScript.WaitFor(S: String);
var T:TTime;
begin
  ///!!! в функциях WaitXXX можно забить на сохранение FCurrent, так как они
  ///вызываются в тех случаях, когда вся страница обновляется
  T:=Now();
  repeat
    Delay(200);
    FLink.SetCurrent(S);
  until (not FLink.CurrentExists)or(SecondsBetween(T,Now)<30);
end;

procedure TSimpleScript.WaitDiff(S: string);
var I:Integer;
    path,param, VarName, VarValue:string;
begin
  //передается 3 переметра
  //1 - имя переменной
  //2 - путь к узлу и
  //3 - что из него брать
  //ждем до тех пор, пока у нас будет не совпадать значение переменной и то, что мы белер из узла
  //если ухел не найден, то тоже ждем
  VarName:=DivStr(S,',');
  path:=DivStr(S,',');
  param:=S;
  VarValue:=Vars[VarName];
  S:='';
  for I:=0 to 5*30 do begin
    Delay(200);
    FLink.SetCurrent(path);
    if not FLink.CurrentExists then Continue;
    S:=GetLSData(param);
    if (S<>'') and (S<>VarValue) then begin
      Break;
    end;
  end;
  Vars[VarName]:=S;
end;

function TSimpleScript.CreateFileName(S: string): string;
var ws,wname,Res:WideString;
begin
  //тут могут быть имена переменных в кв скобках и рросто текст вне скобок
  ws:=WideString(S);
  res:='';
  while ws<>'' do begin
    Res:=Res+DivStr(ws,'[');
    wname:=DivStr(ws,']');
    if wname<>'' then
      Res:=Res+WideString(GetLSData(string(wname)));
  end;
  Result:=UTF8Encode(Trim(Res));
end;

procedure TSimpleScript.ConcatStr(S: string);
var
  vname: String;
begin
  vname:=DivStr(S,',');
  Vars[vname]:=CreateFileName(S);
end;

function TSimpleScript.GetData: TStringlist;
begin
  if FParent<>nil then
    Result:=FParent.GetData
  else
    Result:=FData;
end;

procedure TSimpleScript.FreeData;
begin
  Log('freedata at line' + IntToStr(FCurrStr));
  if FParent<>nil then
    FParent.FreeData
  else
    FreeAndNil(FData);
end;

procedure TSimpleScript.Delay(I: Integer);
var T1:TTime;
    J:Integer;
begin
  T1:=Time;
  while MilliSecondsBetween(Time,T1)<I do
    for J:=0 to 100 do
      Application.ProcessMessages;
end;

initialization
  SetLength(ExternalList,0);
finalization

end.

