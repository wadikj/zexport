unit wrapIE;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, u_brman, MSHTML_4_0_TLB, SHDocVw_1_1_TLB;

//IWebBrowser wrapper  for SimpeScript


type

  { TIEBrowserData }

  TIEBrowserData = class (TCustomBrowserData)
    private
      FCurrent:IHTMLElement;
      FLRoot:IHTMLElement;
      FSavedCurrent:IHTMLElement;
    protected
      procedure SaveCurrent;override;
      procedure LoadCurrent;override;
    public
      constructor Create;override;
      destructor Destroy; override;
  end;

  { TIEWrapper }

  TIEWrapper = class (TCustomBrowser)
    private
      FBrowser:TAxcWebBrowser;
      function GetBData(ALink:TScrLink):TIEBrowserData;
    protected
      procedure UpdateBrowserData(AParentScrLink, AScrLink:TScrLink);override;
      //тупо задает FLocalRoot из FCurrent парента, вызывается при вызове нового скрипта
      procedure CheckBrowserData(ALink:TScrLink);override;//проверяет, что тек BrowserData связана с ним же, иначе пересоздает ее
      function CurrentExists(ALink:TScrLink):boolean;override;
      function GetAttrValue(ALink:TScrLink): string; override;
      function GetLocation: string; override;
      function GetTag(ALink:TScrLink): string; override;
      procedure SetAttrValue(ALink:TScrLink; AValue: string);override;
      procedure SetCurrent(ALink:TScrLink; APath:string; FromLocal:boolean = True);override;
      procedure SetLocation(ALocation: string); override;
      procedure SetLr(ALink:TScrLink); override;
      procedure GetLr(ALink:TScrLink); override;
      function  AttrExists(ALink:TScrLink):boolean; override;
      function  GetTextFrom(ALink:TScrLink; AFrom:string):string;override;
      procedure Click(ALink:TScrLink); override;
      function GetHead:string;override;
      function GetBody:string;override;
      procedure SavePage(AFileName:string);override;
      procedure CurrentByID(ALink:TScrLink;AID:string);override;
      procedure CurrentByName(ALink:TScrLink;AID:string);override;
      procedure GoBack;override;
      procedure Select(ALink:TScrLink);override;
      procedure SelectIndex(ALink:TScrLink;AIndex:Integer);override;
      procedure Submit(ALink:TScrLink);override;

      //
      class function SelByPath(ARoot, ALoc:IDispatch;APath:string):IDispatch;
      class function SelByName(AItem:IDispatch;AName:string):IDispatch;
      class function SelByID(AItem:IDispatch;AName:string):IDispatch;

    public
      constructor Create(ABrowser:TObject);override;
      destructor Destroy; override;
      function GetBrowserControl:TObject;override;
      function Complete:boolean;override;
  end;

implementation

uses Variants, h_tools, u_data;

{ TIEWrapper }

function TIEWrapper.GetBData(ALink: TScrLink): TIEBrowserData;
begin
  CheckBrowserData(ALink);
  Result:=TIEBrowserData(BrowserData[ALink]);
end;

procedure TIEWrapper.UpdateBrowserData(AParentScrLink, AScrLink: TScrLink);
begin
  CheckBrowserData(AScrLink);
  if (Assigned(BrowserData[AParentScrLink]))and
      (BrowserData[AParentScrLink] is TIEBrowserData) and
      (BrowserData[AParentScrLink].FBrowser = Self) then
  begin
      (BrowserData[AScrLink] as TIEBrowserData).FLRoot :=
      (BrowserData[AParentScrLink] as TIEBrowserData).FCurrent;
      (BrowserData[AScrLink] as TIEBrowserData).FCurrent :=
      (BrowserData[AParentScrLink] as TIEBrowserData).FCurrent;
  end;
end;

procedure TIEWrapper.CheckBrowserData(ALink: TScrLink);
var bd:TIEBrowserData;
begin
  bd:=BrowserData[ALink] as TIEBrowserData;
  if bd <> nil then begin
    if bd.FBrowser = Self then Exit;
    bd.Free;
  end;
  bd:=TIEBrowserData.Create;
  bd.FBrowser:=Self;
  BrowserData[ALink]:=bd;
end;

function TIEWrapper.CurrentExists(ALink: TScrLink): boolean;
var bd:TIEBrowserData;
begin
  bd:=GetBData(ALink);
  Result:=bd.FCurrent<>nil;
end;

function TIEWrapper.GetAttrValue(ALink: TScrLink): string;
var bd:TIEBrowserData;
begin
  Result:='';
  bd:=GetBData(ALink);
  if (bd.FCurrent<>nil)and(bd.FCurrent is IHTMLElement5) then
    Result:=(bd.FCurrent as IHTMLElement5).getAttribute(WideString(ALink.Attr));
end;

function TIEWrapper.GetLocation: string;
begin
  Result:=FBrowser.OleServer.Get_LocationURL;
end;

function TIEWrapper.GetTag(ALink: TScrLink): string;
var bd:TIEBrowserData;
begin
  bd := GetBData(ALink);
  Result:=string(bd.FCurrent.tagName);
end;

procedure TIEWrapper.SetAttrValue(ALink: TScrLink; AValue: string);
var bd:TIEBrowserData;
begin
  bd := GetBData(ALink);
  if (bd.FCurrent is IHTMLElement5) then
    (bd.FCurrent as IHTMLElement5).setAttribute(Widestring(ALink.Attr),widestring(AValue));
end;

procedure TIEWrapper.SetCurrent(ALink: TScrLink; APath: string;
  FromLocal: boolean);
var bd:TIEBrowserData;
begin
  bd := GetBData(ALink);
  if FromLocal then
    bd.FCurrent:=SelByPath((FBrowser.OleServer.Document as IHTMLDocument2).body as IDispatch,
    bd.FLRoot as IDispatch,APath) as IHTMLElement
  else
    bd.FCurrent:=SelByPath((FBrowser.OleServer.Document as IHTMLDocument2).body as IDispatch,
    bd.FCurrent as IDispatch, APath) as IHTMLElement
end;

procedure TIEWrapper.SetLocation(ALocation: string);
var ov, ONULL: OleVariant;
begin
  ov:=Utf8Decode(ALocation);
  ONULL:= NULL;
  FBrowser.Active:=True;
  //FBrowser.OleServer.Stop;
  FBrowser.OleServer.Navigate(ALocation, ONULL, ONULL, ONULL, ONULL);
end;

procedure TIEWrapper.SetLr(ALink: TScrLink);
var bd:TIEBrowserData;
begin
  bd := GetBData(ALink);
  bd.FLRoot := bd.FCurrent;
end;

procedure TIEWrapper.GetLr(ALink: TScrLink);
var bd:TIEBrowserData;
begin
  bd := GetBData(ALink);
  bd.FCurrent := bd.FLRoot;
end;

function TIEWrapper.AttrExists(ALink: TScrLink): boolean;
var bd:TIEBrowserData;
begin
  bd:=GetBData(ALink);
  Result:=(bd.FCurrent as IHTMLElement5).hasAttribute(WideString(ALink.Attr));
end;

function TIEWrapper.GetTextFrom(ALink: TScrLink; AFrom: string): string;
var bd:TIEBrowserData;
    ov:OleVariant;
begin
  Result:='';
  if AFrom='' then Exit;
  bd:=GetBData(ALink);
  if bd.FCurrent=nil then Exit;
  if AFrom[1]='.' then try
    if AFrom='.' then begin
      Result:=bd.FCurrent.innerText;
    end else
    if AFrom = '.id' then begin
      Result:=string(bd.FCurrent.Get_id);
    end else
    if AFrom = '.bb' then begin
      Result:=string((bd.FCurrent as IHTMLElement2).getAdjacentText('beforeBegin'))
    end else
    if AFrom = '.ab' then begin
      Result:=string((bd.FCurrent as IHTMLElement2).getAdjacentText('afterBegin'))
    end else
    if AFrom = '.be' then begin
      Result:=string((bd.FCurrent as IHTMLElement2).getAdjacentText('beforeEnd'))
    end else
    if AFrom = '.ae' then begin
      Result:=string((bd.FCurrent as IHTMLElement2).getAdjacentText('afterEnd'))
    end else
    if AFrom = '.it' then begin
      Result:=string((bd.FCurrent as IHTMLElement).innerText)
    end else
    if AFrom = '.ih' then begin
      Result:=string((bd.FCurrent as IHTMLElement).innerHTML)
    end else
    if AFrom = '.ot' then begin
      Result:=string((bd.FCurrent as IHTMLElement).outerText)
    end else
    if AFrom = '.oh' then begin
      Result:=string((bd.FCurrent as IHTMLElement).outerHTML)
    end else
    if AFrom = '.loc' then begin
      Result:=GetLocation;
      //((FBrowser.OleServer as IWebBrowser).Document as IHTMLDocument2).location.href);
    end else
    if AFrom = '.ti' then begin
      Result:=TimeToStr(Now);
    end else begin
      Delete(AFrom,1,1);
      ov:=string((bd.FCurrent as IHTMLElement5).getAttribute(UTF8Decode(AFrom)));
      if not VarIsNull(ov) then Result:=string(ov);
    end;
  except
    Result:='';;
  end
  else
    if AFrom[1]='@' then begin
      Delete(AFrom,1,1);
      ov:=(bd.FCurrent as IHTMLElement5).getAttribute(UTF8Decode(AFrom));
      if not VarIsNull(ov) then Result:=string(Ov);
    end;
end;

procedure TIEWrapper.Click(ALink: TScrLink);
var bd:TIEBrowserData;
begin
  bd:=GetBData(ALink);
  //BrMan.Log('IEWrap.click check');
  if (bd.FCurrent<>nil) then begin
    bd.FCurrent.click;
    //BrMan.Log('IEWrap.click');
  end;
end;

function TIEWrapper.GetHead: string;
var elem:IHTMLElement;
    col:IHTMLElementCollection;
begin
  col:=(FBrowser.OleServer.Document as IHTMLDocument3).getElementsByTagName('head');
  elem:=(col.item(0,Unassigned) as IHTMLElement);
  Result:=elem.innerHTML;
end;

function TIEWrapper.GetBody: string;
var elem:IHTMLElement;
    col:IHTMLElementCollection;
begin
  col:=(FBrowser.OleServer.Document as IHTMLDocument3).getElementsByTagName('body');
  elem:=(col.item(0,Unassigned) as IHTMLElement);
  Result:=elem.innerHTML;
end;

procedure TIEWrapper.SavePage(AFileName: string);
var SL:TStringList;
begin
  SL:=TStringList.Create;
  try
    SL.Text:=UTF8Encode(((FBrowser.OleServer.Document as IHTMLDocument3).documentElement as IHTMLElement).innerHTML);
    SL.SaveToFile(Options.ActivePrj.FullDataDir +'\' + AFileName);
  finally
    SL.Free;
  end;
end;

procedure TIEWrapper.CurrentByID(ALink: TScrLink; AID: string);
var bd:TIEBrowserData;
    idisp:IDispatch;
begin
  bd:=GetBData(ALink);
  idisp:=SelByID(FBrowser.OleServer.Document,AID);
  if idisp<>nil then
    bd.FCurrent:=idisp as IHTMLElement
  else
    bd.FCurrent:=nil;
end;

procedure TIEWrapper.CurrentByName(ALink: TScrLink; AID: string);
var bd:TIEBrowserData;
    idisp:IDispatch;
begin
  bd:=GetBData(ALink);
  idisp:=SelByName(FBrowser.OleServer.Document,AID);
  if idisp<>nil then
    bd.FCurrent:=idisp as IHTMLElement
  else
    bd.FCurrent:=nil;
end;

procedure TIEWrapper.GoBack;
begin
  FBrowser.OleServer.GoBack;
end;

procedure TIEWrapper.Select(ALink: TScrLink);
var bd:TIEBrowserData;
begin
  bd:=GetBData(ALink);
  if bd.FCurrent is IHTMLOptionElement then begin
    (bd.FCurrent as IHTMLOptionElement).selected:=True;
  end;
end;

procedure TIEWrapper.SelectIndex(ALink: TScrLink; AIndex: Integer);
var bd:TIEBrowserData;
begin
  bd:=GetBData(ALink);
  if bd.FCurrent=nil then Exit;
  if bd.FCurrent is IHTMLSelectElement then begin
    (bd.FCurrent as IHTMLSelectElement).selectedIndex:=AIndex
  end;
end;

procedure TIEWrapper.Submit(ALink: TScrLink);
var bd:TIEBrowserData;
begin
  bd:=GetBData(ALink);
  if bd.FCurrent is IHTMLFormElement then begin
    (bd.FCurrent as IHTMLFormElement).submit;
  end;
end;

class function TIEWrapper.SelByPath(ARoot, ALoc: IDispatch; APath: string
  ): IDispatch;
begin
  Result:=nil;
  if (ARoot=nil) and (ALoc=nil) then Exit;
  if APath='' then begin
    if ARoot<>nil then begin
      Result:=ARoot;
    end;
    Exit;
  end;
  if APath[1]='\' then begin
    if ALoc=nil then
      ALoc:=ARoot;
    Delete(APath,1,1);
    Result:=elemByPath((ALoc as IHTMLElement) ,APath);
  end else begin
    Result:=elemByPath((ARoot as IHTMLElement),APath);
  end;
end;

class function TIEWrapper.SelByName(AItem: IDispatch; AName: string): IDispatch;
var col:IHTMLElementCollection;
begin
  if AItem=nil then Exit;
  col:=(AItem as IHTMLDocument3).getElementsByName(widestring(AName));
  Result:=Unassigned;
  if col <> nil then
    if col.length>0 then begin
      Result:=col.item(Unassigned,0);
    end;
end;

class function TIEWrapper.SelByID(AItem: IDispatch; AName: string): IDispatch;
begin
  if AItem=nil then Exit;
  Result:=(AItem as IHTMLDocument6).getElementById(widestring(AName));
end;

constructor TIEWrapper.Create(ABrowser: TObject);
begin
  inherited Create(ABrowser);
  FBrowser:=ABrowser as TAxcWebBrowser;
  //BrMan.Log('IEWrapper Create');
end;

destructor TIEWrapper.Destroy;
begin
  FBrowser:=nil;
  //BrMan.Log('IEWrapper Destroy');
  inherited Destroy;
end;

function TIEWrapper.GetBrowserControl: TObject;
begin
  Result:=FBrowser;
end;

function TIEWrapper.Complete: boolean;
begin
  Result:=(FBrowser.OleServer as IWebBrowser2).ReadyState = READYSTATE_COMPLETE;
end;

{ TIEBrowserData }

constructor TIEBrowserData.Create;
begin
  inherited Create;
  FCurrent:=nil;
  FLRoot:=nil;
  FSavedCurrent:=nil;
  //BrMan.Log('IEBrowserData Created');
end;

destructor TIEBrowserData.Destroy;
begin
  FCurrent:=nil;
  FLRoot:=nil;
  FSavedCurrent:=nil;
  //BrMan.Log('IEBrowserData Destroyed');
  inherited Destroy;
end;

procedure TIEBrowserData.SaveCurrent;
begin
  FSavedCurrent:=FCurrent;
end;

procedure TIEBrowserData.LoadCurrent;
begin
  FCurrent:=FSavedCurrent;
end;

end.

