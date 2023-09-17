unit u_findtree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type
  //заводим клас интератор по дереву, он сам делает метод GetNext
  //и возвращает по запросу элементы текущего узла
  //в зависимости от того, через что у нас идет работа, в модуле дерева
  //делается потомок, рассчитанный на конкретный браузер


  ////этот объкт итератор и передается в форму при ее создании,
  //при нажатии кнобки "поезг" итератору передаются даные как искать
  //он запоминает то, от чего ищем и прочиие нужные параметры

  //поиск следующего узла
  //0. если текущий = nil, то текущий равен стартовому
  //1. берем первого детя
  //2. если нет, следующего сиблинга
  //3. если нет, то пока не найдем
  //    берем родителя, (равен таровому, и только в детях- - выходим)
  //      а потом его следующего сиблинга
  //    если нет родителя, то сваливаем
  //если следкющий равен nil, то мы обошли все узля


  //в форме при нажатии "поиск" мы сначала инициализирем переданный итератор,
  //а потом вызываем у него метод "некст", который возвращает нужный элемент
  //мы его оцениваем, и если он подходит, говорим об этом итератору
  //и так до тех пор, пока итератор скажет, что ничего больше нет(дошли до конца деоева)
  //и надо будет предложить поезг с начала

  TSearchStart = (saFromBegin, saFromCurrent, saChildsOnly);

  TDataType = (dtTag, dtParam, dtParamValues, dtText);

  { TCustomTreeIterator }

  TCustomTreeIterator = class
    private
      FForm:TComponent;
    protected
      FStart:Pointer;
      FCurrent:Pointer;
      FStartArea:TSearchStart;
      FData:TStrings;
      function GetNextSibling(Item:Pointer=nil):Pointer;virtual;abstract;
      function GetParent(Item:Pointer=nil):Pointer;virtual;abstract;
      function GetFirstChild(Item:Pointer=nil):Pointer;virtual;abstract;
    public
      constructor Create;virtual;
      destructor Destroy;override;
      procedure StartSearch(Area:TSearchStart);virtual;
      function GetNext:Pointer;
      function GetData(ADataType:TDataType):TStrings;virtual;abstract;
      procedure ItemChecked;virtual;abstract;
      property Data:TStrings read FData;
  end;

  { TfrmTreeFind }

  TfrmTreeFind = class(TForm)
    brStart: TButton;
    btClose: TButton;
    cbCaseSens: TCheckBox;
    cgArea: TCheckGroup;
    leText: TLabeledEdit;
    rgStart: TRadioGroup;
    procedure brStartClick(Sender: TObject);
    procedure btCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    FIter:TCustomTreeIterator;
    destructor Destroy; override;
    function CheckItem:boolean;
    function CheckData:boolean;
    function FindNext:boolean;

  public

  end;

var
  frmTreeFind: TfrmTreeFind;


function CreateSearchForm(AIter:TCustomTreeIterator):TfrmTreeFind;

implementation

uses u_data;

function CreateSearchForm(AIter: TCustomTreeIterator): TfrmTreeFind;
begin
  if AIter.FForm=nil then begin
    Application.CreateForm(TfrmTreeFind,Result);
    Result.FIter:=AIter;
  end else
    Result:=AIter.FForm as TfrmTreeFind;
  AIter.FForm:=Result;
  Result.Show;
end;

{$R *.lfm}

{ TfrmTreeFind }

procedure TfrmTreeFind.brStartClick(Sender: TObject);
begin
  if leText.Modified then begin
    FIter.StartSearch(TSearchStart(rgStart.ItemIndex));
  end;
  leText.Modified:=False;
  if not FindNext then
    ShowMessage('Search complete!!!');
end;

procedure TfrmTreeFind.btCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmTreeFind.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  CloseAction:=caHide;
end;

procedure TfrmTreeFind.FormCreate(Sender: TObject);
begin
  Font.Size:=Options.IntfFont;
end;

destructor TfrmTreeFind.Destroy;
begin
  if FIter<>nil then
    FIter.FForm:=nil;
  inherited Destroy;
end;

function TfrmTreeFind.CheckItem: boolean;
var I:TDataType;
begin
  Result:=False;
  for I:=dtTag to dtText do begin
    if cgArea.Checked[Integer(I)] then begin
      FIter.GetData(I);
      Result:=CheckData;
    end;
    if Result then Break;
  end;
end;

function TfrmTreeFind.CheckData: boolean;
var I:Integer;
    S,Ptrn:string;
begin
  Result:=False;
  Ptrn:=leText.Text;
  if not cbCaseSens.Checked then
    Ptrn:=Ptrn.ToLower;
  for I:=0 to FIter.Data.Count-1 do begin
    S:=FIter.Data[I];
    if not cbCaseSens.Checked then
      S:=S.ToLower;
    if Pos(Ptrn,S)>0 then begin
      Result:=True;
      Break;
    end;
  end;
end;

function TfrmTreeFind.FindNext: boolean;
var
  P: Pointer;
begin
  Result:=False;
  while True do begin
    P:=FIter.GetNext;
    if P<>nil then begin
      if CheckItem then begin
        FIter.ItemChecked;
        Result:=True;
        Break;
      end;
    end else begin
      Break;
    end;
  end;
end;

{ TCustomTreeIterator }

constructor TCustomTreeIterator.Create;
begin
  FData:=TStringList.Create;
  FForm:=nil;
end;

destructor TCustomTreeIterator.Destroy;
begin
  FData.Free;
  if FForm<>nil then
    TfrmTreeFind(FForm).FIter:=nil;
  FForm.Free;
  inherited Destroy;
end;

procedure TCustomTreeIterator.StartSearch(Area: TSearchStart);
begin
  FStartArea:=Area;
  FCurrent:=nil;
  FStart:=nil; //в потомке устанавливается правильно
end;

function TCustomTreeIterator.GetNext: Pointer;
begin
  if FStart = nil then
    raise Exception.Create('Start item must be set!');

  Result:=nil;

  if FCurrent = nil then begin
    FCurrent:=FStart;
    Result:=FStart;
    Exit;
  end;

  Result:=GetFirstChild(FCurrent);

  if Result = nil then
    Result:=GetNextSibling(FCurrent);

  while Result = nil do begin
    FCurrent:=GetParent(FCurrent);
    if FCurrent<>nil then
      Result:=GetNextSibling(FCurrent)
    else
      Break;
  end;
  FCurrent:=Result;
end;


end.

