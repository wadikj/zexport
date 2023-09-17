unit u_textview;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit,
  SynHighlighterHTML, SynHighlighterPython, Forms, Controls, ExtCtrls, StdCtrls,
  Dialogs, ComCtrls, u_data;

type

  TFileType = (ftUnknow,ftText, ftPySrct, ftDataScr, ftHTML);

  { TfrTextView }

  TfrTextView = class(TFrame)
    ImageList1: TImageList;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    syn: TSynEdit;
    SynHTMLSyn1: TSynHTMLSyn;
    SynPythonSyn1: TSynPythonSyn;
    ToolBar1: TToolBar;
    tbSave: TToolButton;
    tbOpen: TToolButton;
    tbSaveAs: TToolButton;
    tbRun: TToolButton;
    ToolButton1: TToolButton;
    procedure tbOpenClick(Sender: TObject);
    procedure tbRunClick(Sender: TObject);
    procedure tbSaveAsClick(Sender: TObject);
    procedure tbSaveClick(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
  private
    { private declarations }
    FFileName:string;
    FFileType:TFileType;
    FCaption:string;
    FOnCaptionChange: TOnTabCaptionChange;
    FOnStatusChange: TOnTabCaptionChange;
    procedure CheckFileName;
    procedure SetFileType(AValue: TFileType);
    procedure CaptionChanged;
  public
    { public declarations }
    constructor Create(TheOwner: TComponent); override;
    procedure OpenFile(AFileName:string);
    procedure SetTextData(AData:string; ACaption:string; AFileType:TFileType = ftUnknow);
    function SaveFile:boolean;
    function SaveAs:boolean;
    property FileType:TFileType read FFileType write SetFileType;
    property OnCaptionChange:TOnTabCaptionChange read FOnCaptionChange write FOnCaptionChange;
    property OnStatusChange:TOnTabCaptionChange read FOnStatusChange write FOnStatusChange;
  end;

implementation

uses U_simplescr, main, u_SynSearch, process, LConvEncoding;

{$R *.lfm}


function RunCommandIndir1(const curdir:TProcessString;const exename:TProcessString;const commands:array of TProcessString;out outputstring:string; out ErrorString:string; Options : TProcessOptions = [];SWOptions:TShowWindowOptions=swoNone):boolean;
Var
    p : TProcess;
    i,
    exitstatus : integer;
begin
  p:=DefaultTProcess.create(nil);
  if Options<>[] then
    P.Options:=Options;
  P.ShowWindow:=SwOptions;
  p.Executable:=exename;
  if curdir<>'' then
    p.CurrentDirectory:=curdir;
  if high(commands)>=0 then
   for i:=low(commands) to high(commands) do
     p.Parameters.add(commands[i]);
  try
    result:=p.RunCommandLoop(outputstring,errorstring,exitstatus)=0;
  finally
    p.free;
  end;
  if exitstatus<>0 then result:=false;
end;



{ TfrTextView }

procedure TfrTextView.tbOpenClick(Sender: TObject);
begin
  OpenDialog1.Filter:=SaveDialog1.Filter;
  if OpenDialog1.Execute then begin
    OpenFile(OpenDialog1.FileName);
  end;
end;

procedure TfrTextView.tbRunClick(Sender: TObject);
var S, estr:string;
begin
  if not SaveFile then Exit;
  case FFileType of
    ftPySrct:begin
      if RunCommandIndir1(Options.ActivePrj.FullDataDir, Options.PyPath, [FFileName], S,estr, [poStderrToOutPut])
      then begin
        frmMain.Log('main','py_scr worked. output:'+#13#10+CP1251ToUTF8(S));
      end else begin
        frmMain.Log('main','run PyScr %s failed'.Format([FFileName]));
        frmMain.Log('main',CP1251ToUTF8(S+estr));
      end;
    end;
    ftDataScr:begin
      frmMain.Log('edit', 'FileName = ' + FFileName);
      S:=ExtractFileName(FFileName);
      frmMain.Log('edit', 'FileName = ' + S);
      Exec(S);
    end;
  end;
end;

procedure TfrTextView.tbSaveAsClick(Sender: TObject);
begin
  SaveAs;
end;

procedure TfrTextView.tbSaveClick(Sender: TObject);
begin
  SaveFile;
end;

procedure TfrTextView.ToolButton1Click(Sender: TObject);
begin
  SearchText(syn);
end;

procedure TfrTextView.CheckFileName;
var S:String;
begin
  if FFileName='' then begin
    SetFileType(ftUnknow);
  end;
  S:=LowerCase(ExtractFileExt(FFileName));
  case S of
    '.txt':begin
      SetFileType(ftText);
    end;
    '.py':begin
      SetFileType(ftPySrct);
    end;
    '':begin
      SetFileType(ftDataScr);
    end;
    '.html', '.htm':begin
      SetFileType(ftHTML);
    end;
    else
      SetFileType(ftUnknow);
  end;
  CaptionChanged;
end;

procedure TfrTextView.SetFileType(AValue: TFileType);
begin
  //if FFileType=AValue then Exit;
  FFileType:=AValue;
  case FFileType of
    ftText,ftUnknow:
      syn.Highlighter:=nil;
    ftPySrct:
      syn.Highlighter:=SynPythonSyn1;
    ftDataScr:
      FFileType:=ftDataScr;
    ftHTML:
      syn.Highlighter:=SynHTMLSyn1;
  end;
  tbRun.Visible:=(FFileType in [ftDataScr, ftPySrct]);
end;

procedure TfrTextView.CaptionChanged;
var S:string;
begin
  S:=FFileName;
  if S='' then S:=FCaption
  else begin
    S:=ExtractFileName(S);
  end;
  if Assigned(FOnCaptionChange)and(Parent is TTabSheet) then begin
    FOnCaptionChange(Parent as TTabSheet,S);
  end;
end;

constructor TfrTextView.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  syn.Font.Size:=Options.EditFont;
end;

procedure TfrTextView.OpenFile(AFileName: string);
begin
  if AFileName='' then Exit;
  FFileName:=AFileName;
  syn.Lines.LoadFromFile(AFileName);
  CheckFileName;
  frmMain.DoNewFileOpened(AFileName);
end;

procedure TfrTextView.SetTextData(AData: string; ACaption: string;
  AFileType: TFileType);
begin
  FFileName:='';
  FCaption:=ACaption;
  syn.Lines.Text:=AData;
  SetFileType(AFileType);
  CaptionChanged;
end;

function TfrTextView.SaveFile: boolean;
begin
  Result:=True;
  if FFileName<>'' then begin
    syn.Lines.SaveToFile(FFileName);
    CheckFileName;
  end else
    Result:=SaveAs;
end;

function TfrTextView.SaveAs: boolean;
begin
  Result:=False;
  if not SaveDialog1.Execute then Exit;
  FFileName:=SaveDialog1.FileName;
  Result:=SaveFile;
  frmMain.Log('edit', 'saved filename='+SaveDialog1.FileName);
end;

end.

