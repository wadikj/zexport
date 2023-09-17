unit u_miniLog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons;

type

  { TfrmMiniLog }

  TfrmMiniLog = class(TForm)
    mmLog: TMemo;
    Panel1: TPanel;
    SaveDialog1: TSaveDialog;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmMiniLog: TfrmMiniLog = nil;

implementation

uses u_data;

const SavedProps = 'Left,Top,Width,Height';

{$R *.lfm}

{ TfrmMiniLog }

procedure TfrmMiniLog.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caHide;
end;

procedure TfrmMiniLog.FormCreate(Sender: TObject);
begin
  Data.LoadComponent(Self,SavedProps);
  mmLog.Font.Size:=Options.MiniFont;
end;

procedure TfrmMiniLog.FormDestroy(Sender: TObject);
begin
  Data.SaveComponent(Self,SavedProps);
end;

procedure TfrmMiniLog.SpeedButton1Click(Sender: TObject);
begin
  mmLog.Clear;
end;

procedure TfrmMiniLog.SpeedButton2Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    mmLog.Lines.SaveToFile(SaveDialog1.FileName);
end;

end.

