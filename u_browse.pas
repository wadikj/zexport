unit u_browse;

{$mode objfpc}{$H+}
{$WARN 4105 off : Implicit string type conversion with potential data loss from "$1" to "$2"}
interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ExtCtrls, StdCtrls,
  SHDocVw_1_1_TLB, Dialogs, ComCtrls, Buttons, activexcontainer, u_data, Types;

type

  { TfrBrowse }

  TfrBrowse = class(TFrame)
    bbOpenFile: TBitBtn;
    bbSave: TBitBtn;
    bbGo: TBitBtn;
    Browser: TAxcWebBrowser;
    ComboBox1: TComboBox;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    procedure bbOpenFileClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure BrowserBeforeNavigate2(Sender: TObject; pDisp: IDispatch;
      var URL: OleVariant; var Flags: OleVariant;
      var TargetFrameName: OleVariant; var PostData: OleVariant;
      var Headers: OleVariant; var Cancel: WordBool);
    procedure BrowserDocumentComplete(Sender: TObject; pDisp: IDispatch;
      var URL: OleVariant);
    procedure BrowserNavigateComplete2(Sender: TObject; pDisp: IDispatch;
      var URL: OleVariant);
    procedure BrowserNavigateError(Sender: TObject; pDisp: IDispatch;
      var URL: OleVariant; var Frame: OleVariant; var StatusCode: OleVariant;
      var Cancel: WordBool);
    procedure BrowserNewWindow3(Sender: TObject; var ppDisp: IDispatch;
      var Cancel: WordBool; dwFlags: LongWord; bstrUrlContext: WideString;
      bstrUrl: WideString);
    procedure BrowserStatusTextChange(Sender: TObject; Text_: WideString);
    procedure BrowserTitleChange(Sender: TObject; Text_: WideString);
    procedure BrowserUpdatePageStatus(Sender: TObject; pDisp: IDispatch;
      var nPage: OleVariant; var fDone: OleVariant);
    procedure Button1Click(Sender: TObject);
    function RS:string;
  private
    FOnCaptionChange: TOnTabCaptionChange;
    FOnStatusChange: TOnTabCaptionChange;
    { private declarations }
    procedure LoadHistory;
  public
    { public declarations }
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy;override;
    property OnCaptionChange:TOnTabCaptionChange read FOnCaptionChange write FOnCaptionChange;
    property OnStatusChange:TOnTabCaptionChange read FOnStatusChange write FOnStatusChange;
  end;

implementation

uses main, wrapIE, u_brman;

{$R *.lfm}

{ TfrBrowse }

procedure TfrBrowse.Button1Click(Sender: TObject);
var url,onull:Olevariant;
begin
  try;
    url:=Utf8Decode(ComboBox1.Text);
    onull:=NULL;
    {Browser.Active:=True;
    ShowMessage('Browser active state:'+BoolToStr(Browser.Active,'True', 'False'));
    Browser.OleServer.Silent:=True;
    Browser.OleServer.Stop;}
    Browser.OleServer.Navigate(url,onull,onull,onull,onull);
  except
    on E:Exception do
      ShowMessage(AnsiToUtf8(E.Message)+#13+Utf8ToAnsi(E.Message));
  end;
end;

function TfrBrowse.RS: string;
var I:integer;
begin
  I:=Browser.OleServer.ReadyState;
  Result:='Uninitialized('+IntToStr(I)+')';
  case I of
    1:Result:='LOADING';
    2:Result:='LOADED';
    3:Result:='INTERACTIVE';
    4:Result:='COMPLETE';
  end;
  Result:='(ReadyState:'+Result+')';
end;

procedure TfrBrowse.LoadHistory;
var J:Integer;
    SL:TStringList;
begin
  SL:=TStringList.Create;
  J:=Options.GetValue('history','index',0);
  Options.LoadStrings('history',SL);
  try
    ComboBox1.Items.Clear;
    ComboBox1.Items.AddStrings(SL);
    ComboBox1.ItemIndex:=J;
  finally
    SL.Free;
  end;
end;

constructor TfrBrowse.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  LoadHistory;
  Browser.OleServer.Silent:=True;
  Font.Size:=Options.IntfFont;
end;

destructor TfrBrowse.Destroy;
begin
  Browser.Active:=False;
  inherited Destroy;
end;

procedure TfrBrowse.bbOpenFileClick(Sender: TObject);
begin
  if OpenDialog1.Execute then begin
    ComboBox1.Text:='file:\\\'+OpenDialog1.FileName;
  end;
end;

procedure TfrBrowse.bbSaveClick(Sender: TObject);
var I:Integer;
    SL:TStringList;
begin
  I:=0;
  if ComboBox1.ItemIndex=-1 then begin
    I:=ComboBox1.Items.Add(ComboBox1.Text);
  end else
    I:=ComboBox1.ItemIndex;
  SL:=TStringList.Create;
  try
    Options.SetValue('history','index',I);
    for I:=0 to ComboBox1.Items.Count-1 do
      SL.Add(ComboBox1.Items[I]);
    Options.SaveStrings('history',SL);
  finally
    SL.Free;
  end;
end;

procedure TfrBrowse.BrowserBeforeNavigate2(Sender: TObject; pDisp: IDispatch;
  var URL: OleVariant; var Flags: OleVariant; var TargetFrameName: OleVariant;
  var PostData: OleVariant; var Headers: OleVariant; var Cancel: WordBool);
begin
  frmMain.Log('browser before nav', URL);
end;

procedure TfrBrowse.BrowserDocumentComplete(Sender: TObject; pDisp: IDispatch;
  var URL: OleVariant);
begin
  //frmMain.Log('OnDocumentComplete:',URL);
end;

procedure TfrBrowse.BrowserNavigateComplete2(Sender: TObject; pDisp: IDispatch;
  var URL: OleVariant);
begin
  ComboBox1.Text:=Browser.OleServer.Get_LocationURL;
  //frmMain.Log('browser nav complete', Browser.OleServer.Get_LocationURL);
end;

procedure TfrBrowse.BrowserNavigateError(Sender: TObject; pDisp: IDispatch;
  var URL: OleVariant; var Frame: OleVariant; var StatusCode: OleVariant;
  var Cancel: WordBool);
begin
  //frmMain.Log('browser nav error',Url);
end;

procedure TfrBrowse.BrowserNewWindow3(Sender: TObject; var ppDisp: IDispatch;
  var Cancel: WordBool; dwFlags: LongWord; bstrUrlContext: WideString;
  bstrUrl: WideString);
var iewrap:TIEWrapper;
    B:TfrBrowse;
begin
  B:=frmMain.CreateFrame(TfrBrowse,'New Tab') as TfrBrowse;
  ppDisp:=B.Browser.OleServer;
  iewrap:=TIEWrapper.Create(B.Browser);
  //frmMain.Log('browser','New win request - '+ bstrUrl);
  if not BrMan.DoExtNewBrowser(Browser,iewrap) then begin
    iewrap.Free;
    frmMain.log('Browser','New win request failed');
  end;
  ///frmMain.Log('browser NEW WINDOW', Browser.OleServer.Get_LocationURL);
  //frmMain.Log('NEW WINDOW:CONTEXT', bstrUrlContext);
  //frmMain.Log('NEW WINDOW:URL', bstrUrl);
end;

procedure TfrBrowse.BrowserStatusTextChange(Sender: TObject; Text_: WideString);
begin
  if Assigned(FOnStatusChange) then
    FOnStatusChange((Parent as TTabSheet), UTF8Encode(Text_));
  frmMain.Log('ie',UTF8Encode(Text_));
end;

procedure TfrBrowse.BrowserTitleChange(Sender: TObject; Text_: WideString);
begin
  if Assigned(FOnCaptionChange) then
    FOnCaptionChange((Self.Parent as TTabSheet), Text_);
{  if Parent is TTabSheet then
    (Parent as TTabSheet).Caption:=UTF8Encode(Text_);}
end;

procedure TfrBrowse.BrowserUpdatePageStatus(Sender: TObject; pDisp: IDispatch;
  var nPage: OleVariant; var fDone: OleVariant);
begin
  frmMain.Log('browser','page status = ' + string(nPage));
end;

end.

