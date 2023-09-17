unit u_setfolders;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons;

type

  { TfrmSetFolders }

  TfrmSetFolders = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    lePyPAth: TLabeledEdit;
    OpenDialog1: TOpenDialog;
    sbPyPath: TSpeedButton;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sbPyPathClick(Sender: TObject);
  private
    procedure Init;
  public

  end;

var
  frmSetFolders: TfrmSetFolders;

procedure SetAppFolders;

implementation

uses u_data;

procedure SetAppFolders;
begin
  Application.CreateForm(TfrmSetFolders, frmSetFolders);
  frmSetFolders.init;
  frmSetFolders.ShowModal;
end;

{$R *.lfm}

{ TfrmSetFolders }

procedure TfrmSetFolders.sbPyPathClick(Sender: TObject);
begin
  if lePyPAth.Text<>'' then
    OpenDialog1.FileName:=lePyPAth.Text;
  if OpenDialog1.Execute then
    lePyPAth.Text:=OpenDialog1.FileName;
end;

procedure TfrmSetFolders.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TfrmSetFolders.FormCreate(Sender: TObject);
begin
  Font.size:=Options.IntfFont;
end;

procedure TfrmSetFolders.BitBtn1Click(Sender: TObject);
begin
  Options.PyPath:=lePyPAth.Text;
  ModalResult:=mrOK;
end;

procedure TfrmSetFolders.Init;
begin
  lePyPAth.Text:=Options.PyPath;
end;

end.

