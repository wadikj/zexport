unit u_projdata;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  u_data;

type

  { TfrmProjOpts }

  TfrmProjOpts = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    leName: TLabeledEdit;
    LeMainFolder: TLabeledEdit;
    leScrDir: TLabeledEdit;
    leBDDir: TLabeledEdit;
    leDataDir: TLabeledEdit;
    leFlask: TLabeledEdit;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SpeedButton1: TSpeedButton;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure SpeedButton1Click(Sender: TObject);
  private
    FProject:TETLProject;
    procedure Init;
    procedure Save;

  public

  end;

var
  frmProjOpts: TfrmProjOpts;

function SetProjProperties(AProject:TETLProject):Boolean;

implementation

function SetProjProperties(AProject: TETLProject): Boolean;
begin
  Application.CreateForm(TfrmProjOpts,frmProjOpts);
  frmProjOpts.FProject:=AProject;
  frmProjOpts.Init;
  Result:=frmProjOpts.ShowModal=mrOK;
  FreeAndNil(frmProjOpts);
end;

{$R *.lfm}

{ TfrmProjOpts }

procedure TfrmProjOpts.BitBtn1Click(Sender: TObject);
begin
  Save;
end;

procedure TfrmProjOpts.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  CloseAction:=caHide;
end;

procedure TfrmProjOpts.SpeedButton1Click(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then
    LeMainFolder.Text:=SelectDirectoryDialog1.FileName;
end;

procedure TfrmProjOpts.Init;
begin
  if FProject.ProjName='' then begin
    leName.TextHint:='Введите имя нового проекта';
    LeMainFolder.Text:='';
    leName.Text:='';
    leBDDir.Text:='';
    leDataDir.Text:='';
    leFlask.Text:='';
    leScrDir.Text:='';
    Caption:='Новый проект';
  end else begin
    leName.Text:=FProject.ProjName;
    LeMainFolder.Text:=FProject.RootDir;
    leBDDir.Text:=FProject.DBDir;
    leDataDir.Text:=FProject.DataDir;
    leFlask.Text:=FProject.ShellDir;
    leScrDir.Text:=FProject.ScrDir;
  end;
end;

procedure TfrmProjOpts.Save;
begin
  if (leScrDir.Text='') or (leName.Text='') or (LeMainFolder.Text = '') then begin
    ShowMessage('Не заданы минимальные данные проекта');
    Exit;
  end;
  FProject.ProjName:=leName.Text;
  FProject.RootDir:=LeMainFolder.Text;
  FProject.DBDir:=leBDDir.Text;
  FProject.DataDir:=leDataDir.Text;
  FProject.ScrDir:=leScrDir.Text;
  FProject.ShellDir:=leScrDir.Text;
  ModalResult:=mrOK;
end;

end.

