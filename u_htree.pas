unit u_htree;

{$mode objfpc}{$H+}
{$WARN 4105 off : Implicit string type conversion with potential data loss from "$1" to "$2"}
interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterHTML, Forms, Controls,
  ComCtrls, ValEdit, ExtCtrls, StdCtrls, MSHTML_4_0_TLB, u_data,
  u_findtree;

type

  TLogEvent = procedure (AFrom, S:string) of object;

  TTreeIterator = class;

  TMyTN = class (TTreeNode)
    public
      IHTMElem : IHTMLElement;
  end;


  { TfrTree }

  TfrTree = class(TFrame)
    ImageList1: TImageList;
    leNodePath: TLabeledEdit;
    leRelRoot: TLabeledEdit;
    leRelPath: TLabeledEdit;
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    syn: TSynEdit;
    Splitter2: TSplitter;
    SynHTMLSyn1: TSynHTMLSyn;
    TabControl1: TTabControl;
    ToolBar1: TToolBar;
    tbInfo: TToolButton;
    tbAttrs: TToolButton;
    tbGoPath: TToolButton;
    tbFind: TToolButton;
    ToolButton4: TToolButton;
    tbSetRelPath: TToolButton;
    tbGoRelPath: TToolButton;
    tv: TTreeView;
    vlProps: TValueListEditor;
    procedure btSetRelRootClick(Sender: TObject);
    procedure btGoPathClick(Sender: TObject);
    procedure brGoRelPathClick(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure tbAttrsClick(Sender: TObject);
    procedure tbInfoClick(Sender: TObject);
    procedure tbFindClick(Sender: TObject);
    procedure tvChange(Sender: TObject; Node: TTreeNode);
    procedure tvCreateNodeClass(Sender: TCustomTreeView;
      var NodeClass: TTreeNodeClass);
    procedure tvExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
  private
    FOnCaptionChange: TOnTabCaptionChange;
    FOnLog: TLogEvent;
    FOnStatusChange: TOnTabCaptionChange;
    { private declarations }
    hdoc:IDispatch;//IHTMLDocument2;
    hbody:IHTMLElement;
    helem:IHTMLElement;
    FCaption:string;
    FIter:TTreeIterator;
    procedure ROpenNode(N:TTreeNode;Path:string);
    procedure Log(S:string);
    procedure SetCaption(AValue: string);
  public
    { public declarations }
    constructor Create(TheOwner: TComponent); override;
    procedure ViewDoc(idoc:IDispatch);
    procedure ShowNodeInfo;
    procedure ShowNodeAttrs;
    procedure ExpandNode(Node:TTreeNode);
    procedure ViewHTML;
    procedure FreeHDoc;
    function CreatePath(ANode:TTreeNode):string; //
    procedure OpenPath(APath:string);
    destructor Destroy;override;
    property OnLog : TLogEvent read FOnLog write FOnLog;
    property OnCaptionChange:TOnTabCaptionChange read FOnCaptionChange write FOnCaptionChange;
    property OnStatusChange:TOnTabCaptionChange read FOnStatusChange write FOnStatusChange;
    property Caption:string read FCaption write SetCaption;
  end;

  { TTreeIterator }

  TTreeIterator = class(TCustomTreeIterator)
    private
      FFrame:TfrTree;
      function GetTreeItem: TMyTN;
    protected
      function GetNextSibling(Item:Pointer = nil):Pointer;override;
      function GetParent(Item:Pointer=nil):Pointer;override;
      function GetFirstChild(Item:Pointer=nil):Pointer;override;
      property TreeItem:TMyTN read GetTreeItem;
    public
      procedure StartSearch(Area:TSearchStart);override;
      function GetData(ADataType:TDataType):TStrings;override;
      procedure ItemChecked;override;
  end;



implementation

uses h_tools, s_tools, Variants
  //, main
  ;

{$R *.lfm}


const
  EmptyData = '{F5749B35-8782-4A06-9892-11A11A93A014}';

{ TTreeIterator }

function TTreeIterator.GetTreeItem: TMyTN;
begin
  Result:=TMyTN(FCurrent);
end;

function TTreeIterator.GetNextSibling(Item: Pointer): Pointer;
begin
  if Item=nil then Item:=FCurrent;
  Result:=TMyTN(Item).GetNextSibling;
end;

function TTreeIterator.GetParent(Item: Pointer): Pointer;
begin
  if Item=nil then Item:=FCurrent;
  Result:=TMyTN(Item).Parent;
end;

function TTreeIterator.GetFirstChild(Item: Pointer): Pointer;
begin
  if Item=nil then Item:=FCurrent;
  FFrame.ExpandNode(TMyTN(Item));
  Result:=TMyTN(Item).GetFirstChild;
end;

procedure TTreeIterator.StartSearch(Area: TSearchStart);
begin
  inherited;
  if Area=saFromBegin then
    FStart:=FFrame.tv.Items[0]
  else
    FStart:=FFrame.tv.Selected;
  if FStart =  nil then
    FStart:=FFrame.tv.Items[0];
end;

function TTreeIterator.GetData(ADataType: TDataType): TStrings;
var N:TMyTN;
    col:IHTMLAttributeCollection3;
    J:Integer;
    S:string;
    ov:OleVariant;
begin
  Result:=FData;
  FData.Clear;
  if FCurrent=nil then Exit;
  N:=TMyTN(FCurrent);
  case ADataType of
    dtTag:FData.Add(N.IHTMElem.tagName);
    dtParam, dtParamValues:begin
      if N.IHTMElem is IHTMLElement5 then begin
        col:=(N.IHTMElem as IHTMLElement5).attributes;
        for J:=0 to col.length-1 do
          if ADataType=dtParam then
            FData.Add(col.item(J).nodeName)
          else begin
            ov:=col.item(J).nodeValue;
            if (not VarIsEmpty(ov)) and (not VarIsNull(ov)) then
              FData.Add(col.item(J).nodeValue);
          end;
      end;
    end;
    dtText:begin FData.Add((N.IHTMElem as IHTMLElement2).getAdjacentText('afterBegin'));
      S:=(N.IHTMElem as IHTMLElement2).getAdjacentText('beforeEnd');
      if S<>'' then
        FData[FData.Count-1]:=FData[FData.Count-1]+'...'+S;
    end;
  end;
end;

procedure TTreeIterator.ItemChecked;
begin
  if FCurrent<>nil then
    TMyTN(FCurrent).Selected:=True;
end;


{ TfrTree }

procedure TfrTree.tvCreateNodeClass(Sender: TCustomTreeView;
  var NodeClass: TTreeNodeClass);
begin
  NodeClass:=TMYTN;
end;

procedure TfrTree.tvExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
begin
  ExpandNode(Node);
end;

procedure TfrTree.ROpenNode(N: TTreeNode; Path: string);
var curr:TTreeNode;
    S:string;
    I:Integer;
begin
  S:=DivStr(Path,'\');
  if S='' then begin
    N.Selected:=True;
    Exit;
  end;
  I:=StrToInt(S);
  N.Expand(False);
  if I<N.Count then begin;
    curr:=N.Items[I];
    ROpenNode(curr,Path);
  end;
end;

procedure TfrTree.Log(S: string);
begin
  if Assigned(FOnLog) then
    FOnLog('htree',S);
end;

procedure TfrTree.SetCaption(AValue: string);
begin
  if FCaption=AValue then Exit;
  FCaption:=AValue;
  if Assigned(FOnCaptionChange) then
    FOnCaptionChange(Parent as TTabSheet, FCaption);

end;

constructor TfrTree.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FIter:=nil;
  Font.Size:=Options.IntfFont;
  tv.Font.Size:=Options.TreeFont;
  syn.Font.Size:=Options.EditFont;
end;

procedure TfrTree.TabControl1Change(Sender: TObject);
begin
  ViewHTML;
end;

procedure TfrTree.tbAttrsClick(Sender: TObject);
begin
  ShowNodeAttrs;
end;

procedure TfrTree.tbInfoClick(Sender: TObject);
begin
  ShowNodeInfo;
end;

procedure TfrTree.tbFindClick(Sender: TObject);
begin
  if FIter = nil then begin
    FIter:=TTreeIterator.Create;
    FIter.FFrame:=Self;
  end;
  CreateSearchForm(FIter);
end;

procedure TfrTree.btSetRelRootClick(Sender: TObject);
begin
  leRelRoot.Text:=leNodePath.Text;
end;

procedure TfrTree.btGoPathClick(Sender: TObject);
begin
  OpenPath(leNodePath.Text);
end;

procedure TfrTree.brGoRelPathClick(Sender: TObject);
begin
  if (leRelRoot.Text<>'')and(leRelPath.Text<>'') then
    OpenPath(leRelRoot.Text+leRelPath.Text);
end;

procedure TfrTree.tvChange(Sender: TObject; Node: TTreeNode);
var S:string;
begin
  if Node=nil then Exit;
  if Node.Selected then begin
    helem:=TMYTN(Node).IHTMElem;
    leNodePath.Text:=CreatePath(Node);
    if Pos(leRelRoot.Text,leNodePath.Text)=1 then begin
      S:=leNodePath.Text;
      Delete(S,1,Length(leRelRoot.Text));
      leRelPath.Text:=S;
    end else
      leRelPath.Text:='';
  end else begin
    helem:=nil;
    leNodePath.Text:='';
  end;
  if tbInfo.Down then
    ShowNodeInfo
  else
    ShowNodeAttrs;
  ViewHTML;
end;

procedure TfrTree.ViewDoc(idoc: IDispatch);
var
  N:TTreeNode;
  id:IDispatch;
  V:Variant;
begin
  ///!!!main entry point
  leNodePath.Text:='';
  leRelPath.Text:='';
  leRelRoot.Text:='';
	V:=idoc;

  syn.Lines.Add('Title '+ V.title);
  syn.Lines.Add('url '+V.url);
  syn.Lines.Add('defaultCharset '+V.defaultCharset) ;

  id:= V.body;
  hbody:=id as IHTMLElement;
  N:=tv.Items.AddChild(nil,'body');
  TMyTN(N).IHTMElem:=IHTMLElement(hbody);
  tv.Items.AddChild(N,EmptyData);
end;

procedure TfrTree.ShowNodeInfo;
var hstyle:IHTMLStyle;
  procedure AddData(Name,Value:string);
  begin
    vlProps.Values[Name]:=UTF8Encode(Value);
  end;
begin
  vlProps.TitleCaptions[0]:='Keys';
  if helem=nil then Exit;
  try
  try
    vlProps.BeginUpdate;
    vlProps.Clear;
    AddData('id',helem.id{%H-});
    AddData('tagName',helem.tagName);
    AddData('title',helem.title);
    AddData('language',helem.language);
    AddData('sourceindex',IntToStr(helem.sourceIndex));
    AddData('lang',helem.lang);
    AddData('classname',helem.className);
    AddData('text',(helem as IHTMLElement2).getAdjacentText('afterBegin'));
    hstyle:=helem.style;
    if (hstyle<>nil) and (hstyle is IHTMLStyle6) then
      AddData('style', (hstyle as IHTMLStyle6).content);
    if helem is IHTMLElement2 then begin;
      AddData('AdjacentText:beforeBegin',(helem as IHTMLElement2).getAdjacentText('beforeBegin'));
      AddData('AdjacentText:afterBegin',(helem as IHTMLElement2).getAdjacentText('afterBegin'));
      AddData('AdjacentText:beforeEnd',(helem as IHTMLElement2).getAdjacentText('beforeEnd'));
      AddData('AdjacentText:afterEnd',(helem as IHTMLElement2).getAdjacentText('afterEnd'));

    end;
  finally
    vlProps.EndUpdate;
  end;
  except
    on E:Exception do begin
      Log(e.Message);
    end;
  end;
end;

procedure TfrTree.ShowNodeAttrs;
var col:IHTMLAttributeCollection3;
  I,J:Integer;
  nn,nv:string;
  procedure AddData(Name,Value:string);
  begin
    vlProps.Values[Name]:=UTF8Encode(Value);
  end;
begin
  vlProps.TitleCaptions[0]:='Attributes';
  if helem=nil then Exit;
  try
    try
      vlProps.BeginUpdate;
      vlProps.Clear;
      if helem is IHTMLElement5 then begin
        col:=(helem as IHTMLElement5).attributes;
        if col<>nil then begin
          J:=col.length;
          for I:=0 to J-1 do begin
            nn:=string(col.item(I).NodeName);
            nv:=string(col.item(I).NodeValue);
            AddData(nn,nv);
          end;
        end;
      end;
    finally
      vlProps.EndUpdate;
    end;
  except
    on E:Exception do begin
      Log(e.Message);
    end;
  end;
end;

procedure TfrTree.ExpandNode(Node: TTreeNode);
var he:IHTMLElement;
    hc:IHTMLElementCollection;
    I:Integer;
    n:TTreeNode;
    d:IDispatch;
  function HasChildren(elem:IHTMLElement):boolean;
  begin
    Result:=False;
    if elem.children<>nil then
      if (elem.children as IHTMLElementCollection).length<>0 then
        Result:=True;
  end;
begin
  if (node.Count=1)and(Node.getFirstChild.Text=EmptyData) then
  try
    tv.Items.BeginUpdate;
    Node.DeleteChildren;
    he:=(TMYTN(Node).IHTMElem)as IHTMLElement;;
    hc:=he.children as IHTMLElementCollection;
    if (hc=nil)or(hc.length=0) then begin
      Exit;
    end;
    for I:=0 to hc.length-1 do begin
      d:=hc.item(I,0);
      if d=nil then Continue;
      he:= D as IHTMLElement;
      if he = nil then Continue;
      n:=tv.Items.AddChild(Node,he.tagName);
      TMYTN(N).IHTMElem:=he;
      if HasChildren(he) then
        tv.Items.AddChild(n,EmptyData);
    end;
  finally
    tv.Items.EndUpdate;
  end;
end;

procedure TfrTree.ViewHTML;
var SL:TStrings;
    S:string;
begin
  if helem<>nil then begin
    case TabControl1.TabIndex of
      0:syn.Lines.Text:=UTF8Encode(helem.innerHTML);
      1:syn.Lines.Text:=UTF8Encode(helem.innerText);
      2:syn.Lines.Text:=UTF8Encode(helem.outerHTML);
      3:syn.Lines.Text:=UTF8Encode(helem.outerText);
      4:begin
			  SL:=SupportsList(helem);
        syn.Text:=SL.Text;
        SL.Free;
      end;
    end;
    S:=TabControl1.Tabs[TabControl1.TabIndex];
    if Pos('HTML', S)>0 then
      syn.Highlighter:=SynHTMLSyn1
    else
      syn.Highlighter:=nil;
  end;
end;

procedure TfrTree.FreeHDoc;
var N:TMYTN;
    I:integer;
begin
  for I:=0 to tv.Items.Count-1 do begin
    N:=TMYTN(tv.Items[I]);
    N.IHTMElem:=nil;
  end;
  hdoc:=nil;
  hbody:=nil;
  helem:=nil;
  tv.Items.Clear;
end;

function TfrTree.CreatePath(ANode: TTreeNode): string;
var I:Integer;
    P:TTreeNode;
begin
  //идем от переданной ноды вверх
  Result:='';
  while ANode<>tv.Items[0] do begin
    //сначала смотрим, есть ли ИД
    //потом смотрим на номер
    P:=ANode.Parent;
    I:=P.IndexOf(ANode);
    Result:='\'+IntToStr(I)+Result;
    ANode:=P;
  end;
  Delete(Result,1,1);
end;

procedure TfrTree.OpenPath(APath: string);
var N:TTreeNode;
begin
  try
    tv.Items.BeginUpdate;
    N:=tv.Items[0];
    ROpenNode(N,APath);
  finally
    tv.Items.EndUpdate;
  end;
end;

destructor TfrTree.Destroy;
begin
  FreeHDoc;
  FreeAndNil(FIter);
  inherited Destroy;
end;

end.

