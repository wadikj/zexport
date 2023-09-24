unit u_linkParams;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TfrmParamsLinks }

  TfrmParamsLinks = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Memo1: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private

  public

  end;

var
  frmParamsLinks: TfrmParamsLinks;

function LinkParams(AParams:TStrings):boolean;

implementation

function LinkParams(AParams: TStrings): boolean;
begin
  Application.CreateForm(TfrmParamsLinks,frmParamsLinks);
  frmParamsLinks.Memo1.Lines.Assign(AParams);
  Result:=False;
  if frmParamsLinks.ShowModal = mrOK then begin
    Result:=True;
    AParams.Assign(frmParamsLinks.Memo1.Lines);
  end;
  FreeAndNil(frmParamsLinks);
end;

{$R *.lfm}

{ TfrmParamsLinks }

procedure TfrmParamsLinks.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caHide;
end;

end.

