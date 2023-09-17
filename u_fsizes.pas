unit u_fsizes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  Buttons;

type

  { TfrmFSizes }

  TfrmFSizes = class(TForm)
    btCancel: TBitBtn;
    btOk: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    seIntf: TSpinEdit;
    seBtn: TSpinEdit;
    seTrees: TSpinEdit;
    seEditors: TSpinEdit;
    seMiniLog: TSpinEdit;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    procedure Init;
    procedure Done;
  public

  end;

var
  frmFSizes: TfrmFSizes;

procedure SetFSizes;

implementation

uses u_data;

procedure SetFSizes;
begin
  Application.CreateForm(TfrmFSizes,frmFSizes);
  frmFSizes.Init;
  if frmFSizes.ShowModal=mrOK then
    frmFSizes.Done;
  FreeAndNil(frmFSizes);
end;

{$R *.lfm}

{ TfrmFSizes }

procedure TfrmFSizes.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caHide;
end;

procedure TfrmFSizes.FormCreate(Sender: TObject);
begin
  //init sizes
  Font.Size:=Options.IntfFont;
end;

procedure TfrmFSizes.Init;
begin
  seIntf.Value:=Options.IntfFont;
  seBtn.Value:=Options.BtnFont;
  seTrees.Value:=Options.TreeFont;
  seEditors.Value:=Options.EditFont;
  seMiniLog.Value:=Options.MiniFont;
end;

procedure TfrmFSizes.Done;
begin
  Options.IntfFont:=seIntf.Value;
  Options.BtnFont:=seBtn.Value;
  Options.TreeFont:=seTrees.Value;
  Options.EditFont:=seEditors.Value;
  Options.MiniFont:=seMiniLog.Value;
end;

end.

