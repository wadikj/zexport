unit u_SynSearch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  SynEdit;

type

  { TfrmFind }

  TfrmFind = class(TForm)
    btFind: TButton;
    btClose: TButton;
    cbWholeWord: TCheckBox;
    cbCaseSensitive: TCheckBox;
    cbWholeScope: TCheckBox;
    cbBackward: TCheckBox;
    lePattern: TLabeledEdit;
    procedure btCloseClick(Sender: TObject);
    procedure btFindClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    FEdit:TSynEdit;
  public

  end;

var
  frmFind: TfrmFind = nil;

procedure SearchText(AEdit:TSynEdit);


implementation

uses SynEditTypes, u_data;

procedure SearchText(AEdit: TSynEdit);
begin
  if frmFind = nil then
    Application.CreateForm(TfrmFind,frmFind);
  frmFind.FEdit:=AEdit;
  frmFind.lePattern.Text:=frmFind.FEdit.SelText;
  frmFind.Show;
end;

{$R *.lfm}

{ TfrmFind }

procedure TfrmFind.btFindClick(Sender: TObject);
var Options:TSynSearchOptions;
begin
  Options:=[];
  if cbWholeScope.Checked then Options:=[ssoEntireScope];
  if cbBackward.Checked then Options:=Options + [ssoBackwards];
  if cbCaseSensitive.Checked then Options:=Options + [ssoMatchCase];
  if cbWholeWord.Checked then Options:=Options+[ssoWholeWord];
  FEdit.SearchReplace(lePattern.Text,'',Options);
end;

procedure TfrmFind.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
  frmFind:=nil;
end;

procedure TfrmFind.FormCreate(Sender: TObject);
begin
  Font.Size:=Options.IntfFont;
end;

procedure TfrmFind.btCloseClick(Sender: TObject);
begin
  Close;
end;


end.

