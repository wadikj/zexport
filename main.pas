unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ActnList, Menus, u_browse, Variants, MSHTML_4_0_TLB, u_htree,
  u_scr, U_simplescr, u_fromlist, u_brman, wrapIE, u_projdata;

type
  TFrameClass = class of TFrame;

  { TfrmMain }

  TfrmMain = class(TForm)
    acNewBrowser: TAction;
    acCloseActive: TAction;
    acExit: TAction;
    acOptions: TAction;
    acStop: TAction;
    acMiniLog: TAction;
    acForms: TAction;
    acNewText: TAction;
    acNewDataScr: TAction;
    acNewPyScr: TAction;
    acNewHTML: TAction;
    acSaveProj: TAction;
    acNewProject: TAction;
    acOpenProject: TAction;
    acDBs: TAction;
    acFontSizes: TAction;
    acHideButtons: TAction;
    acHideTabs: TAction;
    acShowLog: TAction;
    acViewText: TAction;
    acTree: TAction;
    ActionList1: TActionList;
    ApplicationProperties1: TApplicationProperties;
    bttree: TToolButton;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    miMasterDetail: TMenuItem;
    miTabs: TMenuItem;
    miView: TMenuItem;
    miDBListStart: TMenuItem;
    miSQL: TMenuItem;
    miMiniLog: TMenuItem;
    miExit: TMenuItem;
    miNewText: TMenuItem;
    miNewPy: TMenuItem;
    miNewProject: TMenuItem;
    miNewDataScr: TMenuItem;
    miSavePrj: TMenuItem;
    miDBs: TMenuItem;
    N1: TMenuItem;
    miNewHTML: TMenuItem;
    miMRUEnd: TMenuItem;
    miMRUStart: TMenuItem;
    N2: TMenuItem;
    miProj: TMenuItem;
    miNew: TMenuItem;
    miOpenProjects: TMenuItem;
    miOpenPrj: TMenuItem;
    miPrjListStart: TMenuItem;
    OpenDialog1: TOpenDialog;
    tbNewIE: TToolButton;
    tbOptions: TToolButton;
    tbStopExec: TToolButton;
    tbCloseActive: TToolButton;
    tbPageCode: TToolButton;
    tbHideWin: TToolButton;
    tbScr: TToolButton;
    MainMenu1: TMainMenu;
    miBrowser: TMenuItem;
    miUser: TMenuItem;
    miSaveSettings: TMenuItem;
    miEditButtons: TMenuItem;
    miSetFolders: TMenuItem;
    miIEVer: TMenuItem;
    miTools: TMenuItem;
    miNewIE: TMenuItem;
    miCloseActive: TMenuItem;
    miTree: TMenuItem;
    miViewAsText: TMenuItem;
    mmLog: TMemo;
    PageControl1: TPageControl;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    tb: TToolBar;
    procedure acCloseActiveExecute(Sender: TObject);
    procedure acDBsExecute(Sender: TObject);
    procedure acExitExecute(Sender: TObject);
    procedure acFontSizesExecute(Sender: TObject);
    procedure acFormsExecute(Sender: TObject);
    procedure acHideButtonsExecute(Sender: TObject);
    procedure acHideButtonsUpdate(Sender: TObject);
    procedure acHideTabsExecute(Sender: TObject);
    procedure acHideTabsUpdate(Sender: TObject);
    procedure acMiniLogExecute(Sender: TObject);
    procedure acNewBrowserExecute(Sender: TObject);
    procedure acNewProjectExecute(Sender: TObject);
    procedure acOpenProjectExecute(Sender: TObject);
    procedure acSaveProjExecute(Sender: TObject);
    procedure acShowLogExecute(Sender: TObject);
    procedure acShowLogUpdate(Sender: TObject);
    procedure acTreeExecute(Sender: TObject);
    procedure acViewTextExecute(Sender: TObject);
    procedure ApplicationProperties1Hint(Sender: TObject);
    procedure miMasterDetailClick(Sender: TObject);
    procedure tbStopExecClick(Sender: TObject);
    procedure tbHideWinClick(Sender: TObject);
    procedure tbScrClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure miExitClick(Sender: TObject);
    procedure miIEVerClick(Sender: TObject);
    procedure acNewDataScriptClick(Sender: TObject);
    procedure miEditButtonsClick(Sender: TObject);
    procedure miNewHTMLClick(Sender: TObject);
    procedure acNewPyScriptClick(Sender: TObject);
    procedure miSaveSettingsClick(Sender: TObject);
    procedure miSetFoldersClick(Sender: TObject);
    procedure acNewTextClick(Sender: TObject);
    procedure PageControl1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { private declarations }
    procedure ViewAsText;
    procedure ViewText(ACaption,AData:string);
    //коллбэки для фреймов
    procedure DoCaptionChanged(ATab:TWinControl;ACaption:string);
    procedure DoStatusChanged(ATab:TWinControl;ACaption:string);
    procedure ViewScrRes(AStr:string);

    procedure DoMRUClick(Sender:TObject);
    procedure DoPrjClick(Sender:TObject);
    procedure DoDBClick(Sender:TObject);
    procedure DoMiTabsClick(Sender:TObject);
    procedure StartLoadPrj;
    function OpenProj:boolean;
    function NewProj:boolean;
  public
    { public declarations }
    function NewWin2(AURL:string):TfrBrowse;//для создания новой вкладки при переходе
    function CreateFrame(fr:TFrameClass;TabCaption:string='NewTab'):TFrame;//Tab - parent of frame

    procedure Log(AFrom:string;Msg:string);
    procedure LogScr(AStr:string);///!!!в др модуль

    //for scripts
    function DoGetActiveBrowser: TCustomBrowser;
    function DoGetNewBrowser(AData:string):TCustomBrowser;
    procedure DoCloseBrowser(ABrowser:TComponent);
    function GetActiveDocument:IDispatch;
    function GetActiveBrowser:IDispatch;
    procedure CloseActive;
    procedure Wait; ////!!!нах не нужен


    procedure UpdateButtons;
    procedure UpdateMRUMenu;
    procedure UpdateProjMRU;
    procedure UpdateDBMenu;
    procedure UpdateTabsMenu;

    procedure DoNewFileOpened(AFileName:string);

  end;

var
  frmMain: TfrmMain = nil;

implementation

uses SHDocVw_1_1_TLB, u_textview, DateUtils, u_miniLog, testreg, u_setfolders,
  u_data, u_buttons, u_frSQL, u_connList, u_fsizes, u_mast_det, LConvEncoding,
  Math;


{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.acNewBrowserExecute(Sender: TObject);
begin
  CreateFrame(TfrBrowse,'New Tab');
end;

procedure TfrmMain.acNewProjectExecute(Sender: TObject);
begin
  if NewProj then begin
    UpdateButtons;
    UpdateDBMenu;
    UpdateProjMRU;
  end;
end;

procedure TfrmMain.acOpenProjectExecute(Sender: TObject);
begin
  if OpenProj then begin
    UpdateProjMRU;
    UpdateButtons;
    UpdateDBMenu;
  end;
end;

procedure TfrmMain.acSaveProjExecute(Sender: TObject);
begin
  Options.ActivePrj.Save;
end;

procedure TfrmMain.acShowLogExecute(Sender: TObject);
begin
  PageControl1.ActivePageIndex:=0;
end;

procedure TfrmMain.acShowLogUpdate(Sender: TObject);
begin
  UpdateTabsMenu;
end;

procedure TfrmMain.acTreeExecute(Sender: TObject);
var D:IDispatch;
    fr:TfrTree;
begin
	D:=GetActiveDocument;
  if D=nil then Exit;
  fr:=CreateFrame(TfrTree) AS TfrTree;
  fr.ViewDoc(D);
  fr.Caption:='Tree of '+UTF8Encode((D as IHTMLDocument2).title);
end;

procedure TfrmMain.acViewTextExecute(Sender: TObject);
begin
  ViewAsText;
end;

procedure TfrmMain.ApplicationProperties1Hint(Sender: TObject);
begin
  if Sender is TControl then
    StatusBar1.SimpleText:=(Sender as TControl).Hint
  else
    StatusBar1.SimpleText:=Application.Hint;
end;

procedure TfrmMain.miMasterDetailClick(Sender: TObject);
begin
  CreateFrame(TfrMD,'Master-Detail');
end;

procedure TfrmMain.acCloseActiveExecute(Sender: TObject);
var T:TTabSheet;
begin
  T:=PageControl1.ActivePage;
  if T.PageIndex<>0 then begin
    T.free;
  end;
end;

procedure TfrmMain.acDBsExecute(Sender: TObject);
var S:string;
begin
  S:=SelectDB;
  if S<>'' then begin
    CreateSQLFrame(S);
    //добавляем эту БД в список МРУ проекта
    if Options.ActivePrj.AddMRUDB(S) then
      UpdateDBMenu;
  end;
end;

procedure TfrmMain.acExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.acFontSizesExecute(Sender: TObject);
begin
  SetFSizes;
end;

procedure TfrmMain.acFormsExecute(Sender: TObject);
begin
  ShowForms;
end;

procedure TfrmMain.acHideButtonsExecute(Sender: TObject);
begin
  tb.Visible:=not tb.Visible;
end;

procedure TfrmMain.acHideButtonsUpdate(Sender: TObject);
begin
  acHideButtons.Checked:=not tb.Visible;
end;

procedure TfrmMain.acHideTabsExecute(Sender: TObject);
begin
  PageControl1.ShowTabs:=not PageControl1.ShowTabs;
end;

procedure TfrmMain.acHideTabsUpdate(Sender: TObject);
begin
  acHideTabs.Checked:=not PageControl1.ShowTabs;
end;

procedure TfrmMain.acMiniLogExecute(Sender: TObject);
begin
  if frmMiniLog=nil then
    Application.CreateForm(TfrmMiniLog,frmMiniLog);
  frmMiniLog.Show;
end;

procedure TfrmMain.tbStopExecClick(Sender: TObject);
begin
  BreakExec;
end;

procedure TfrmMain.tbHideWinClick(Sender: TObject);
begin
  Height:=42+5;
end;

procedure TfrmMain.tbScrClick(Sender: TObject);
begin
  ShowScrForms;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SetGetProcs(@LogScr, @ViewScrRes);
  BrMan.OnGetActiveBrowser:=@DoGetActiveBrowser;
  BrMan.OnNewBrowser:=@DoGetNewBrowser;
  BrMan.OnCloseBrowser:=@DoCloseBrowser;
  BrMan.OnLog:=@Log;
  //load last project
  StartLoadPrj;
  UpdateProjMRU;
  UpdateButtons;
  UpdateMRUMenu;
  UpdateDBMenu;
  //interface
  Font.Size:=Options.IntfFont;
  PageControl1.Font.Size:=Options.IntfFont;
  tb.Font.Size:=Options.BtnFont;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  mmLog:=nil;
end;

procedure TfrmMain.FormShowHint(Sender: TObject; HintInfo: PHintInfo);
begin
  StatusBar1.SimpleText:=HintInfo^.HintControl.Hint;
end;

procedure TfrmMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.miIEVerClick(Sender: TObject);
begin
  SetIEVersion;
end;

procedure TfrmMain.acNewDataScriptClick(Sender: TObject);
begin
  (CreateFrame(TfrTextView) as TfrTextView).SetTextData('','New DataScript', ftDataScr);
end;

procedure TfrmMain.miEditButtonsClick(Sender: TObject);
begin
  if EditButtons then
    UpdateButtons;
end;

procedure TfrmMain.miNewHTMLClick(Sender: TObject);
begin
  (CreateFrame(TfrTextView) as TfrTextView).SetTextData('','New HTML', ftHTML);
end;

procedure TfrmMain.acNewPyScriptClick(Sender: TObject);
begin
  (CreateFrame(TfrTextView) as TfrTextView).SetTextData('','New PyScr', ftPySrct);
end;

procedure TfrmMain.miSaveSettingsClick(Sender: TObject);
begin
  Options.Save;
end;

procedure TfrmMain.miSetFoldersClick(Sender: TObject);
begin
  SetAppFolders;
end;

procedure TfrmMain.acNewTextClick(Sender: TObject);
begin
  (CreateFrame(TfrTextView,'New Text') as TfrTextView).SetTextData('','New Text', ftText);
end;

procedure TfrmMain.PageControl1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var I:Integer;
begin
  I:=PageControl1.IndexOfTabAt(X,Y);
  if I<>-1 then begin
    if PageControl1.Hint<>PageControl1.Pages[I].Hint then begin
      PageControl1.Hint:=PageControl1.Pages[I].Hint;
      Application.CancelHint;
    end;
  end;
end;

procedure TfrmMain.ViewAsText;
var fr:TfrTextView;
    I:IWebBrowser2;
    B:TfrBrowse;
begin
  I:=nil;
  if PageControl1.ActivePage.Controls[0] is TfrBrowse then begin
    B:=PageControl1.ActivePage.Controls[0] as TfrBrowse;
    I:=B.Browser.OleServer;
  end;
  if I=nil then Exit;
  fr:=CreateFrame(TfrTextView,'') as TfrTextView;
  fr.SetTextData(UTF8Encode(((I.Document as IHTMLDocument3).documentElement as IHTMLElement).innerHTML),
    'HTML from '+string((I.Document as IHTMLDocument2).title),ftHTML);
end;

procedure TfrmMain.ViewText(ACaption, AData: string);
var fr:TfrTextView;
begin
  fr:=CreateFrame(TfrTextView,'')as TfrTextView;
  fr.SetTextData(ACaption,AData,ftDataScr);
end;

procedure TfrmMain.DoCaptionChanged(ATab: TWinControl; ACaption: string);
var S:string;
begin
  S:=ACaption;
  if Length(S)>20 then begin
    Delete(S,20,Length(S));
    S:=S+'...';
  end;
  ATab.Caption:=S;
  ATab.Hint:=ACaption;
  //ATab.ParentShowHint:=False;
  //ATab.ShowHint:=False;
end;

procedure TfrmMain.DoStatusChanged(ATab: TWinControl; ACaption: string);
begin
  StatusBar1.SimpleText:=ACaption;
end;

function TfrmMain.NewWin2(AURL: string): TfrBrowse;
var T:TTabSheet;
begin
  T:=(CreateFrame(TfrBrowse,'NewTab').Parent as TTabSheet);
  if T.Controls[0] is TfrBrowse then begin
    Result:=T.Controls[0] as TfrBrowse;
    Result.Browser.Active:=True;
  end;
end;

procedure TfrmMain.Log(AFrom: string; Msg: string);
begin
  if Assigned(mmLog) and (MSG<>'') then begin
    mmLog.Lines.Add(AFrom+':'+UTF8Encode(Msg));
    if frmMiniLog<>nil then
      frmMiniLog.mmLog.Lines.Add(AFrom+':'+UTF8Encode(Msg));
  end;
end;

procedure TfrmMain.LogScr(AStr: string);
begin
  Log('scr',AStr);
end;

procedure TfrmMain.ViewScrRes(AStr: string);
begin
  ViewText(AStr,'scr');
end;

procedure TfrmMain.DoMRUClick(Sender: TObject);
var FName:string;
begin
  if Sender is TMenuItem then
    FName:=TMenuItem(Sender).Caption;
  TfrTextView(CreateFrame(TfrTextView)).OpenFile(FName);
end;

procedure TfrmMain.DoPrjClick(Sender: TObject);
begin
  if FileExists((Sender as TMenuItem).Caption) then begin
    Options.LoadPrj((Sender as TMenuItem).Caption);
    Log('MRUprj','open '+(Sender as TMenuItem).Caption);
    UpdateProjMRU;
    UpdateButtons;
    UpdateDBMenu;
  end;
end;

procedure TfrmMain.DoDBClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    CreateSQLFrame(TMenuItem(Sender).Caption);
end;

procedure TfrmMain.DoMiTabsClick(Sender: TObject);
begin
  PageControl1.ActivePageIndex:=(Sender as TMenuItem).Tag;
end;

procedure TfrmMain.StartLoadPrj;
begin
  //и при необходимости мы еще должны уметь грузануть проект, переданный в ком строке
  //либо грузим тот, что последний
  if Options.ActiveProject<>'' then begin
    Options.LoadPrj(Options.ActiveProject);
    Log('loadprj',Options.ActiveProject);
    Exit;
  end;
  //если нет, пытаемся грузануть хоть какой то
  if Options.PrjList.Count>0 then begin
    Options.LoadPrj(Options.PrjList[0]);
    Log('loadprj',Options.PrjList[0]);
    Exit;
  end;
  //если нет, то пытаемся открыть
  ShowMessage('Ддя корректной работы программы необходим открытый проект. ' + #13 + 'Откройте его, пожалуйста ');
  if OpenProj then Exit;
  //если нет, то создаем новый
  ShowMessage('Ддя корректной работы программы необходим открытый проект.' +#13+'Создайте его, пожалуйста ');
  if not NewProj then Close;
end;

function TfrmMain.OpenProj: boolean;
begin
  Result:=False;
  if OpenDialog1.Execute then begin
    Options.LoadPrj(OpenDialog1.FileName);
    Result:=True;
    Log('loadprj',OpenDialog1.FileName);
  end;
end;

function TfrmMain.NewProj: boolean;
var ep:TETLProject;
begin
  Result:=False;
  ep:=Options.NewProj;
  if SetProjProperties(ep) then begin
    ep.CreateNewProj;
    ep.DirsChanged;
    Options.SetActivePrj(ep);
    Log('createprj',ep.ProjName);
    Result:=True;
  end else begin
    ep.Free;
  end;
end;

function TfrmMain.DoGetActiveBrowser: TCustomBrowser;
var B:TfrBrowse;
begin
  //в зависимости от браузера возвращаем враппер
  Result:=nil;
  if PageControl1.ActivePage.Controls[0] is TfrBrowse then begin
    B:=PageControl1.ActivePage.Controls[0] as TfrBrowse;
    Result:=TIEWrapper.Create(B.Browser);
  end;
end;

function TfrmMain.DoGetNewBrowser(AData: string): TCustomBrowser;
var B:TfrBrowse;
begin
  //тут надо еще дописать онализ даты, и в зависимости от этого создавать браузер (IE or Cromium)
  Result:=nil;
  B:=(CreateFrame(TfrBrowse)as TfrBrowse);
  Result:=TIEWrapper.Create(B.Browser);
end;

procedure TfrmMain.DoCloseBrowser(ABrowser: TComponent);
var I:Integer;
    B:TfrBrowse;
begin
  for I:=0 to PageControl1.PageCount-1 do begin
    if not (PageControl1.Pages[I].Controls[0] is TfrBrowse) then Continue;
    B:=PageControl1.Pages[I].Controls[0] as TfrBrowse;
    if B.Browser = ABrowser then
      PageControl1.Pages[I].Free;
  end;
end;

function TfrmMain.GetActiveDocument: IDispatch;
begin
  Result:=GetActiveBrowser;
  if Result<>nil then
    Result:=(Result as IWebBrowser).Document;
end;

function TfrmMain.GetActiveBrowser: IDispatch;
var B:TfrBrowse;
begin
  Result:=nil;
  if PageControl1.ActivePage.Controls[0] is TfrBrowse then begin
    B:=PageControl1.ActivePage.Controls[0] as TfrBrowse;
    Result:=B.Browser.OleServer;
  end;
end;

procedure TfrmMain.CloseActive;
var Tab:TTabSheet;
begin
  //берем текущую активную страницу
  //закрываем
  //а в качестве активной назначаем такую страницу, которая ближайшая левее нашей
  if PageControl1.ActivePage.Controls[0] is TfrBrowse then begin
    Tab:=PageControl1.ActivePage;
    PageControl1.SelectNextPage(False);
    if Tab.TabIndex=0 then Exit;
    Tab.Free;
  end;
end;

procedure TfrmMain.Wait;
var B:IWebBrowser2;
begin
	B:=GetActiveBrowser as IWebBrowser2;
  while B.ReadyState<>READYSTATE_COMPLETE do begin
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  	Application.ProcessMessages;
  end;
end;

function TfrmMain.CreateFrame(fr: TFrameClass; TabCaption: string): TFrame;
var TS:TTabSheet;
    FB:TFrame;
begin
  Result:=nil;
  TS:=PageControl1.AddTabSheet;
  TS.Caption:=TabCaption;
  TS.HandleNeeded;
  FB:=fr.CreateParented(TS.Handle);
  FB.Parent:=TS;
  TS.ShowHint:=True;
  FB.Align:=alClient;
  FB.Visible:=True;
  PageControl1.ActivePage:=TS;
  Result:=FB;
  TS.InsertComponent(Result);
  if FB is TfrTextView then begin
    TfrTextView(FB).OnCaptionChange:=@DoCaptionChanged;
    TfrTextView(FB).OnStatusChange:=@DoStatusChanged;
  end else
  if FB is TfrBrowse then begin
    TfrBrowse(FB).OnCaptionChange:=@DoCaptionChanged;
    TfrBrowse(FB).OnStatusChange:=@DoStatusChanged;
    TfrBrowse(FB).Browser.Active:=True;
  end else
  if FB is TfrTree then begin
    TfrTree(FB).OnCaptionChange:=@DoCaptionChanged;
    TfrTree(FB).OnStatusChange:=@DoStatusChanged;
    TfrTree(FB).OnLog:=@Log;
  end;
end;

procedure TfrmMain.UpdateButtons;
var I:Integer;
    B:TToolButton;
    A:TAdvAction;
    M:TMenuItem;
    bi:TBtnColItem;
    _min:Integer;
begin
  _min:=0;
  ///сначала валим все менюшки и кнобки, у которых наш экшен
  while miUser.Count<>0 do miUser.Delete(0);
  for I := ComponentCount-1 downto 0 do begin
    if (Components[I] is TToolButton) then begin
      B:=(Components[I] as TToolButton);
      if B.Action is TAdvAction then
        B.Free
      else
        _min:=Max(_min,B.Left+B.Width);
    end;
  end;
  Inc(_min,30);
  //потом валим все наши экшены
  for I:=ActionList1.ActionCount-1 downto 0 do
    if ActionList1.Actions[I] is TAdvAction then
      ActionList1.Actions[I].Free;
  //потом создаем наши экшены, меню и кнобки
  for I:=0 to Options.ActivePrj.Buttons.Count-1 do begin
    bi:=TBtnColItem(Options.ActivePrj.Buttons.Items[I]);
    A:=TAdvAction.Create(Self);
    A.ActionList:=ActionList1;
    A.ColItem:=bi;
    A.ShortCut:=bi.ShortCut;
    A.Hint:=bi.Hint;
    if bi.MenuText<>'' then begin
      M:=TMenuItem.Create(Self);
      miUser.Add(M);
      M.Action:=A;
      M.Caption:=bi.MenuText;
    end;
    if bi.BntText<>'' then begin
      B:=TToolButton.Create(Self);
      B.Action:=A;
      B.Caption:=bi.BntText;
      B.Parent:=tb;
      B.Left:=_min;
      Inc(_min,B.Width);
    end;
  end;
end;

procedure TfrmMain.UpdateMRUMenu;
var mi:TMenuItem;
    I:Integer;
begin
  //сначала валим все, что у нас после miMRUStart
  //потом смотрим, что у нас есть для добавления
  //если ничего нет, то miMRUEnd.Visible := False
  I:=miMRUStart.MenuIndex+1;
  while True do begin
    if miProj.Items[I]<>miMRUEnd then
      miProj.Items[I].Free
    else
      Break;
  end;
  miMRUEnd.Visible:=Options.MRUList.Count<>0;
  for I:=Options.MRUList.Count-1 downto 0 do begin
    mi:=TMenuItem.Create(Self);
    mi.Caption:=Options.MRUList[I];
    mi.OnClick:=@DoMRUClick;
    miProj.Insert(miMRUStart.MenuIndex+1,mi);
  end;
end;

procedure TfrmMain.UpdateProjMRU;
var I:Integer;
    mi:TMenuItem;
begin
  //обновляем список проектов и заголовок проги
  if Options.ActivePrj<>nil then
    Caption:='ZExport - [' + Options.ActivePrj.ProjName + ']';
  while True do begin
    if miPrjListStart<>miOpenProjects[miOpenProjects.Count-1] then
      miOpenProjects[miOpenProjects.Count-1].Free
    else Break;
  end;
  miPrjListStart.Visible := Options.PrjList.Count<>0;
  if miPrjListStart.Visible then
    for I:=0 to Options.PrjList.Count-1 do begin
      mi:=TMenuItem.Create(Self);
      mi.Caption:=Options.PrjList[i];
      mi.OnClick:=@DoPrjClick;
      miOpenProjects.Add(mi);
    end;
end;

procedure TfrmMain.UpdateDBMenu;
var I:Integer;
    mi:TMenuItem;
begin
  while True do begin
    if miDBListStart<>miSQL[miSQL.Count-1] then
      miSQL[miSQL.Count-1].Free
    else Break;
  end;
  miDBListStart.Visible := Options.ActivePrj.LinkedDataBases.Count<>0;
  if miDBListStart.Visible then
    for I:=0 to Options.ActivePrj.LinkedDataBases.Count-1 do begin
      mi:=TMenuItem.Create(Self);
      mi.Caption:=Options.ActivePrj.LinkedDataBases[I];
      mi.OnClick:=@DoDBClick;
      miSQL.Add(mi);
    end;
end;

procedure TfrmMain.UpdateTabsMenu;
var
  I: Integer;
  mi:TMenuItem;
begin
  while miTabs.Count>1 do
    miTabs[miTabs.Count-1].Free;
  for I:=1 to PageControl1.PageCount-1 do begin
    mi:=TMenuItem.Create(Self);
    mi.Caption:=PageControl1.Pages[I].Caption;
    mi.Tag:=I;
    mi.OnClick:=@DoMiTabsClick;
    miTabs.Add(mi);
  end;
end;

procedure TfrmMain.DoNewFileOpened(AFileName: string);
begin
  Options.AddMRUFile(AFileName);
  UpdateMRUMenu;
end;

end.

