unit u_buttons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ActnList, Menus, Buttons;

type


  { TfrmEditButtons }

  TfrmEditButtons = class(TForm)
    btNew: TButton;
    btChange: TButton;
    btDel: TButton;
    BtClose: TButton;
    cbType: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    leBtnText: TLabeledEdit;
    leMenuText: TLabeledEdit;
    leCmd: TLabeledEdit;
    leHotKey: TLabeledEdit;
    lbItems: TListBox;
    mmHint: TMemo;
    SpeedButton1: TSpeedButton;
    procedure btChangeClick(Sender: TObject);
    procedure BtCloseClick(Sender: TObject);
    procedure btDelClick(Sender: TObject);
    procedure btNewClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lbItemsSelectionChange(Sender: TObject; User: boolean);
  private
    FModified:boolean;
    procedure InitView;
    procedure UpdateView;
    procedure SelectItem;
    procedure UpdateItem;
    procedure SetItemData(AIndex:Integer);
    procedure NewItem;
    procedure DelItem;
  public

  end;

var
  frmEditButtons: TfrmEditButtons;


function EditButtons:boolean;

implementation

uses u_data, LCLProc;

function EditButtons: boolean;
begin
  Application.CreateForm(TfrmEditButtons,frmEditButtons);
  frmEditButtons.InitView;
  frmEditButtons.FModified:=False;
  frmEditButtons.ShowModal;
  Result:=frmEditButtons.FModified;
  FreeAndNil(frmEditButtons);
end;


{$R *.lfm}

{ TfrmEditButtons }

procedure TfrmEditButtons.lbItemsSelectionChange(Sender: TObject; User: boolean
  );
begin
  if User then
    SelectItem;
end;

procedure TfrmEditButtons.BtCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmEditButtons.btDelClick(Sender: TObject);
begin
  DelItem;
end;

procedure TfrmEditButtons.btChangeClick(Sender: TObject);
begin
  UpdateItem;
end;

procedure TfrmEditButtons.btNewClick(Sender: TObject);
begin
  NewItem;
end;

procedure TfrmEditButtons.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=caHide;
end;

procedure TfrmEditButtons.FormCreate(Sender: TObject);
begin
  Font.Size:=Options.IntfFont;
end;

procedure TfrmEditButtons.InitView;
var
  Item: TCollectionItem;
begin
  //он должен быть пустым
  for Item in Options.ActivePrj.Buttons do begin
    lbItems.AddItem(Item.DisplayName,Item);
  end;
  if lbItems.Count>0 then begin
    lbItems.ItemIndex:=0;
    SelectItem;
  end;
end;

procedure TfrmEditButtons.UpdateView;
var I:Integer;
begin
  //chanded item or itemcount
  I:=lbItems.ItemIndex;
  try
    lbItems.Items.BeginUpdate;
    lbItems.Clear;
    InitView;
    if lbItems.Count=0 then Exit;
    if I>=lbItems.Count then
      I:=lbItems.Count-1;
    lbItems.ItemIndex:=I;
    SelectItem;
  finally
    lbItems.Items.EndUpdate;
  end;
end;

procedure TfrmEditButtons.SelectItem;
var bi:TBtnColItem;
begin
  //in lbItems;
  if (lbItems.ItemIndex<0)or(lbItems.ItemIndex>=lbItems.Count) then begin
    cbType.ItemIndex:=0;
    leCmd.Text:='';
    leBtnText.Text:='';
    leMenuText.Text:='';
    leHotKey.Text:='';
    mmHint.Text:='';
    Exit;
  end;
  bi:=TBtnColItem(lbItems.Items.Objects[lbItems.ItemIndex]);
  leCmd.Text:=bi.Cmd;
  leBtnText.Text:=bi.BntText;
  leMenuText.Text:=bi.MenuText;
  leHotKey.Text:=ShortCutToText(bi.ShortCut);
  mmHint.Text:=bi.Hint;
  cbType.ItemIndex:=Integer(bi.AdvType);
end;

procedure TfrmEditButtons.UpdateItem;
begin
  //Update from form data
  if (lbItems.ItemIndex<0)or(lbItems.ItemIndex>=lbItems.Count) then begin
    ShowMessage('Item for update not selected!!!');
    Exit;
  end;
  SetItemData(lbItems.ItemIndex);
end;

procedure TfrmEditButtons.SetItemData(AIndex: Integer);
var bi:TBtnColItem;
begin
  //set itemdata from form
  bi:=TBtnColItem(lbItems.Items.Objects[AIndex]);
  bi.Cmd:=leCmd.Text;
  bi.AdvType:=TAdvType(cbType.ItemIndex);
  bi.BntText:=leBtnText.Text;
  bi.Hint:=mmHint.Text;
  bi.MenuText:=leMenuText.Text;
  bi.ShortCut:=TextToShortCut(leHotKey.Text);
  lbItems.Items[AIndex]:=bi.DisplayName;
  FModified:=True;
end;

procedure TfrmEditButtons.NewItem;
var bi:TBtnColItem;
    I:Integer;
begin
  //new created from form data
  bi:=TBtnColItem(Options.ActivePrj.Buttons.Add);
  lbItems.AddItem('newitem',bi);
  I:=lbItems.Count-1;
  SetItemData(I);
  lbItems.ItemIndex:=I;
end;

procedure TfrmEditButtons.DelItem;
var bi:TBtnColItem;
begin
  //del selected item
  bi:=TBtnColItem(lbItems.Items.Objects[lbItems.ItemIndex]);
  bi.Free;
  UpdateView;
  FModified:=True;
end;


end.

