unit paramstorage;

{$mode objfpc}{$H+}
{$WARN 4105 off : Implicit string type conversion with potential data loss from "$1" to "$2"}
{$WARN 4104 off : Implicit string type conversion from "$1" to "$2"}
interface

uses
  Classes, SysUtils, DOM, TZCLSInfo;

{модуль служит для хранения настроек проги
на вход при создании главного класса ему передается имя
файла, он его читает и создает объекты настроек
если имя файла не  передается, то оно автоматом получается
из имени проги  + .xini

}

type

  //процедура для чтения/записи значения свойства
  TBypassProc = procedure (AInfo:TZClassInfo;ANode:TDOMNode);
  {AInfo:TZCLSInfo; в нем храним объект, который обрабатываем
  ANode:TDOMNode; - куда или откуда берем значение свойства}

{$M+}

  { TCustomPropStorage }

  TCustomPropStorage = class (TObject)
    private
      FDoc:TXMLDocument;
      FDataRoot, //пишем сюда свойства наших потомков
      FStrRot,   //пишем сюда наборы строк
      FFormsRoot, //пишем сюда свойства форм
      FCustomRoot:TDOMElement; //пишем сюда что нужно пользователю
      FModified: boolean;
      FPath: string;//путь к активному узлу
      FActiveNode:TDOMElement;//тек активный узел (может на стек переделать?)

    protected
      FFileName:string;//имя файла
      procedure InternalBypass(PropNames:string; Node:TDomNode; AObject:TObject;GetSetProc:TBypassProc;
        ForceNode:boolean);

      //в зависимости от пути вохвращаем элемент, с которым надо работать
      function GetWorkNode(APath:string;Forced:boolean=True):TDOMElement;

    public
      constructor Create(AFileName:string);virtual;
      destructor Destroy;override;

      //пишем TStrings
      //AName - назв узла, куда пишем
      procedure LoadStrings(AName:string;AData:TStrings);
      procedure SaveStrings(AName:string;AData:TStrings);

      //это для записи форм,
      //AName:имя формы - отдельно сделать имя формы
      //AProps:список свойств для сохранения
      procedure LoadComponent(AProps:string;AData:TComponent);
      procedure SaveComponent(AProps:string;AData:TComponent);

      procedure TestSaveComponent(AName:string;AData:TComponent);


      //для произвольных значений, хранящихся в узле <custom>, путь считается именно он этого узла
      procedure OpenPath(APath:string);
      property  CurrentPath:string read FPath;
      procedure ClosePath;
      //эти 3 функции надо сделать через функции модуля, чтобы использовать везде
      procedure ClearValues(APath:string); //удаляет все атрибуты в узле по указанному пути
      procedure DeleteValue(const APath, KeyName: DOMString);//удаляет указанное значение
      procedure DeletePath(APath:string); //удаляет последний узел в пути и всех его детей
      function HasValue(APath,AKey:string):boolean;//проверка на наличие опр значения
      function HasValues(APath:string):boolean;//есть ли вообще ключи в узле
      procedure GetValues(APath:string;AValues:TStrings);//список в виде ключ=значение
      procedure GetChildNodes(APath:string;AValues:TStrings);//список дочерних узлов

      //для работы этих функций должны указать путь к узлу (относительный от UserData)
      //или если путь не указан, то берется из OpenPath
      procedure SetValue(APath, KeyName:string;AValue:string);overload;
      procedure SetValue(APath, KeyName:string;AValue:Integer);overload;
      procedure SetValue(APath, KeyName:string;AValue:Boolean);overload;

      function GetValue(APath, KeyName:string;ADefault:Boolean):boolean;overload;
      function GetValue(APath, KeyName:string;ADefault:Integer):Integer;overload;
      function GetValue(APath, KeyName:string;ADefault:string):string;overload;

      property Modified:boolean read FModified write FModified;
      property ActiveNode:TDOMElement read FActiveNode;
      procedure Load;virtual;
      procedure Save;virtual;
      procedure NewFile;

  end;


//функции, на которых эиа вся фигня пострроена
//пишем и читаем компонент
//и дом и объект <> nil
procedure XLoadObject(AObject:TObject;AData:TDOMElement); //из ДОМ в объект
procedure XSaveObject(AObject:TObject;AData:TDOMElement;SaveAll:boolean=False);//из объекта в дом

//пишем и читаем в дом только те свойства, которые заданы в AProps
//в props можно задавать и свойства вложенных объектов, например Memo1.Width
//при этом в атрибуты оно попадет как Memo1_Width вск в одну строку
procedure XLoadObjectProps(AObject:TObject;AData:TDOMElement;AProps:string); //из ДОМ в объект
procedure XSaveObjectProps(AObject:TObject;AData:TDOMElement;AProps:string);//из объекта в дом

//пишем наборы строк
procedure XLoadStrings(AStrings:TStrings;AData:TDOMElement);
procedure XSaveStrings(AStrings:TStrings;AData:TDOMElement);

//коллекция
procedure XLoadCollection(ACollection:TCollection;AData:TDOMElement);
procedure XSaveCollection(ACollection:TCollection;AData:TDOMElement);


//возвращает ноду по пути к ней
function GetNodeFromPath(ARoot:TDomNode;APath:string;Force:boolean=True):TDOMNode;

procedure ClearValues(AElem:TDOMNode);overload; //удаляет все атрибуты в узле
procedure ClearValues(ARoot:TDOMNode;APath:string); overload; //удаляет все атрибуты в узле по указанному пути

procedure DeleteValue(ARoot:TDOMNode;const APath, KeyName: DOMString);//удаляет указанное значение атрибута
procedure DeleteValue(ANode:TDOMNode;const KeyName: DOMString);//удаляет указанное значение атрибута

procedure XDeletePath(ANode:TDOMNode;APath:string); //удаляет последний узел в пути и всех его детей
procedure XDeleteChildren(ANode:TDOMNode);overload;//валит всех детей у ноды
procedure XDeleteChildren(ANode:TDOMNode;APath:string);overload;//валит всех детей у нобы по указанному пути

procedure XChildList(AElem:TDOMNode;AChilds:TStrings);//список дочерних узлов
procedure XAttrList(AElem:TDOMNode;AValues:TStrings);//список атрибутов со значениями

const
  nOptions  = 'options'; //main node
  nStrings  = 'strings'; //node for strings storage
  nForms    = 'forms';//node for form props storage
  nData     = 'data'; //node for storage main options object
  nUser     = 'userdata'; //node for storage user data (use OpenPath, Set/GetValue for acces to data)
  nItem     = 'i'; //пишем TCollectionItem
  nValue    = 'v'; //Value
  nString   = 's'; //TStrings.Item


implementation

uses typinfo, XMLRead, XMLWrite, s_tools, Dialogs, Forms, LCLProc;

procedure XLoadObject(AObject: TObject; AData: TDOMElement);
var Info:TZClassInfo;
    I:Integer;
    ANode:TDOMNode;
    de:TDOMElement;
begin
  if AData=nil then Exit;
  Info:=TZClassInfo.Create(AObject);
  for I:= 0 to Info.PropCount-1 do begin
    Info.PropNumber:=I;
    //S:=Info.PropName;
    if Info.Kind in [tkInteger,tkChar,tkEnumeration,tkFloat,tkSet,tkSString,
      tkLString,tkAString,tkWString,tkWChar,tkBool,tkInt64,tkQWord,tkUString,tkUChar]
      then begin
      if AData.hasAttribute(Info.PropName) then
        Info.Value:=AData[Info.PropName];
    end else
    if Info.Kind=tkClass then begin
      if Info.ObjProp=nil then Continue;
      ANode:=AData.FindNode(Info.PropName);
      if ANode=nil then Continue;
      de:=nil;
      if ANode is TDOMElement then
        de:=ANode as TDOMElement;
      if de=nil then Continue;
      XLoadObject(Info.ObjProp,de);
      if info.ObjProp is TStrings then
        XLoadStrings((Info.ObjProp as TStrings),de)
      else if Info.ObjProp is TCollection then
        XLoadCollection((Info.ObjProp as TCollection),de);
    end;
  end;
end;

procedure XSaveObject(AObject: TObject; AData: TDOMElement; SaveAll: boolean);
var Info:TZClassInfo;
    I:Integer;
    ANode:TDOMNode;
begin
  //AObject, AData must be <>nil
  Info:=TZClassInfo.Create(AObject);
  for I:=0 to Info.PropCount-1 do begin
    Info.PropNumber:=I;
    //проверяем, надо ли его сохранять
    if (not SaveAll) and (not Info.IsStored) and Info.IsDefValue then Continue;
    if info.Kind in [tkInteger,tkChar,tkEnumeration,tkFloat,tkSet,tkSString,
    tkLString,tkAString,tkWString,tkWChar,tkBool,tkInt64,tkQWord,tkUString,tkUChar]
    then begin
      AData.AttribStrings[Info.PropName]:=Info.Value;
    end else
    if info.Kind=tkClass then begin
      //ищем узел с названием свойства
      ANode:=AData.FindNode(Info.PropName);
{      if not (ANode is TDOMElement) then begin
        AData.DetachChild(ANode);
        FreeAndNil(ANode);
      end;}
      if ANode=nil then begin
        ANode:=AData.OwnerDocument.CreateElement(Info.PropName);
        AData.AppendChild(ANode);
      end;
      XSaveObject(Info.ObjProp,TDOMElement(ANode));
      if Info.ObjProp is TStrings then begin
        XSaveStrings((Info.ObjProp as TStrings),TDOMElement(ANode));
      end else
      if Info.ObjProp is TCollection then begin
        XSaveCollection((Info.ObjProp as TCollection),TDOMElement(ANode));
      end;
    end;
  end;
end;

procedure XLoadObjectProps(AObject: TObject; AData: TDOMElement; AProps: string
  );
begin
  //перетащить сюда реализацию из класса
end;

procedure XSaveObjectProps(AObject: TObject; AData: TDOMElement; AProps: string
  );
begin
  //можно иак width,font.(name,size)),left
  //у шрита пишем только имя и  размер
  //точки меняем на _

end;

procedure XLoadStrings(AStrings: TStrings; AData: TDOMElement);
var I:Integer;
    SNode:TDOMElement;
    nl:TDOMNodeList;
begin
  //пишем только TCollectionItems, если в объекте есть еще свойства, то вызываем XSaveObject
  //пихаем в наш узел дочерние элнемы
  nl:=AData.ChildNodes;
  if (nl=nil) or (nl.Count=0) then Exit;
  for I:=0 to nl.Count-1 do begin
    SNode:=nil;
    if nl.Item[I] is TDOMElement then
      SNode:=nl.Item[I] as TDOMElement;
    if SNode=nil then Continue;
    if SNode.TagName=nString then
      AStrings.Add(SNode.AttribStrings[nValue]);
  end;
end;

procedure XSaveStrings(AStrings: TStrings; AData: TDOMElement);
var I:Integer;
    SNode:TDOMElement;
begin
  //пишем только свми строки, если в объекте есть еще свойства, то вызываем XSaveObject
  //пихаем в наш узел дочерние элнемы
  XDeleteChildren(AData);
  for I:=0 to AStrings.Count-1 do begin
    SNode:=AData.OwnerDocument.CreateElement(nString);
    AData.AppendChild(SNode);
    SNode[nValue]:=AStrings[I];
  end;
end;

procedure XLoadCollection(ACollection: TCollection; AData: TDOMElement);
var I:Integer;
    SNode:TDOMElement;
    nl:TDOMNodeList;
    AItem:TCollectionItem;
begin
  //пишем только TCollectionItems, если в объекте есть еще свойства, то вызываем XSaveObject
  //пихаем в наш узел дочерние элнемы
  nl:=AData.ChildNodes;
  if (nl=nil) or (nl.Count=0) then Exit;
  for I:=0 to nl.Count-1 do begin
    SNode:=nil;
    if nl.Item[I] is TDOMElement then
      SNode:=nl.Item[I] as TDOMElement;
    if SNode=nil then Continue;
    if SNode.TagName=nItem then begin
      AItem:=ACollection.Add;
      XLoadObject(AItem,SNode);
    end;
  end;
end;

procedure XSaveCollection(ACollection: TCollection; AData: TDOMElement);
var I:Integer;
    SNode:TDOMElement;
begin
  //пишем только TCollectionItems, если в объекте есть еще свойства, то вызываем XSaveObject
  //пихаем в наш узел дочерние элнемы
  XDeleteChildren(AData);
  for I:=0 to ACollection.Count-1 do begin
    SNode:=AData.OwnerDocument.CreateElement(nItem);
    AData.AppendChild(SNode);
    XSaveObject(ACollection.Items[I],SNode);
  end;
end;

procedure ClearValues(AElem: TDOMNode);
var nm:TDOMNamedNodeMap;
begin
  if AElem=nil then Exit;
  if AElem.Attributes<>nil then
    nm:=AElem.Attributes
  else
    Exit;
  while nm.Length<>0 do begin
    nm.RemoveNamedItem(nm.Item[0].NodeName).Free;
  end;
end;

procedure ClearValues(ARoot: TDOMNode; APath: string);
var N:TDOMNode;
begin
  n:=GetNodeFromPath(ARoot,APath,False);
  if n=nil then Exit;
  ClearValues(N);
end;

procedure DeleteValue(ARoot: TDOMNode; const APath, KeyName: DOMString);
var N:TDOMNode;
begin
  N:=GetNodeFromPath(ARoot,APath,False);
  if N<>nil then
    DeleteValue(N,KeyName);
end;

procedure DeleteValue(ANode: TDOMNode; const KeyName: DOMString);
var nm:TDOMNamedNodeMap;
begin
  if ANode=nil then Exit;
  if ANode.Attributes<>nil then
    nm:=ANode.Attributes
  else
    Exit;
  nm.RemoveNamedItem(KeyName).Free;
end;

procedure XDeletePath(ANode: TDOMNode; APath: string);
var N:TDOMNode;
begin
  //валим узел с указаным путем или текущий
  N:=GetNodeFromPath(ANode,APath,false);
  if N<>nil then begin
    N.ParentNode.DetachChild(N);
    FreeAndNil(N);
  end;
end;

procedure XDeleteChildren(ANode: TDOMNode);
var N:TDOMNode;
begin
  if ANode=nil then Exit;
  if ANode.ChildNodes=nil then Exit;
  while ANode.ChildNodes.Length<>0 do begin
    N:=ANode.DetachChild(ANode.ChildNodes.Item[0]);
    FreeAndNil(N);
  end;
end;

procedure XDeleteChildren(ANode: TDOMNode; APath: string);
var N:TDOMNode;
begin
  N:=GetNodeFromPath(ANode,APath,False);
  if N<>nil then
    XDeleteChildren(N);
end;

procedure XChildList(AElem: TDOMNode; AChilds: TStrings);
var N:TDOMNode;
begin
  if AChilds=nil then Exit;
  if not AElem.HasChildNodes then Exit;
  N:=AElem.FirstChild;
  while Assigned(N) do begin
    AChilds.Add(N.NodeName);
    N:=N.NextSibling;
  end;
end;

procedure XAttrList(AElem: TDOMNode; AValues: TStrings);
var AttrList:TDOMNamedNodeMap;
    I:Integer;
begin
  if AValues=nil then Exit;
  AttrList:=AElem.Attributes;
  if AttrList.Length=0 then Exit;
  for I:=0 to AttrList.Length-1 do
    AValues.Add(AttrList.Item[I].NodeName+'='+AttrList.Item[I].NodeValue);
end;

function GetNodeFromPath(ARoot: TDomNode; APath: string; Force: boolean
  ): TDOMNode;
var S:string;
    Tmp:TDOMNode;
begin
  //force : result must be not nil
  Result:=ARoot;
  while APath<>'' do begin
    S:=Trim(DivStr(APath,'/'));
    if S='' then Continue;
    Tmp:=Result.FindNode(S);
    if (Tmp=nil) then begin
      if Force then begin
        Tmp:=ARoot.OwnerDocument.CreateElement(S);
        Result.AppendChild(Tmp);
        Result:=Tmp;
      end else begin
        Result:=nil;
        Break;
      end;
    end else
      Result:=Tmp;
  end;
end;

{ TCustomPropStorage }

procedure TCustomPropStorage.InternalBypass(PropNames: string; Node: TDomNode;
  AObject: TObject; GetSetProc: TBypassProc; ForceNode: boolean);
var
  I, J: Integer;
  SubProp: Boolean;
  S, S1: String;
  Info: TZClassInfo;
  N:TDOMNode;
  pObj:TObject;
begin
  {
  идем по строке
  нашли , все что до нее - название свойства, задаем его
  нашли .  - тоже название свойства - но это объект ,по любому надо будет прыгать вниз
    смотрим, что за ней
    S - список свойств
    если скобка, то в S все что в них
      если не скобка, то дальше у нас   [!!! может быть pop1.prop2.(p3,p4)]
      не, если есть такое, то должно быть так pop1.(prop2.(p3,p4)) - чтобы проще
      было вылезать из рекурсии
      если не скобка, то згачит, там просто одиночное задание свойства
      пихаем его в S
    и вызываем себя рекурсивно
    и так до тех пор, пока строка со свойствами <>""
  }
  if AObject=nil then Exit;
  Info:=TZClassInfo.Create(AObject);
  while PropNames<>'' do begin
    SubProp:=False;
    pObj:=nil;
    I:=s_tools.DelimiterIndex(PropNames,',.');
    if I=0 then begin
      S:=PropNames;
      PropNames:='';
    end
    else begin
      if PropNames[I]='.' then begin
        s:=DivStr(PropNames,'.');
        SubProp:=True;
      end else begin
        S:=DivStr(PropNames,',');
      end;
    end;
    if  SubProp and (AObject is TForm) then begin
      pObj:=(AObject as TForm).FindComponent(S);
    end;
    if pObj=nil then
    try
      Info.PropName:=S;
    except
      on e:EClassInfo do begin
        if (SubProp)and (AObject is TForm) then begin
          pObj:=(AObject as TForm).FindComponent(S);
        end else raise;
      end;
    end;
    if SubProp then begin
      //если скобка, то извлекаем все до парной
      if PropNames[1]='(' then begin
        J:=FindMatchBrace(PropNames);
        ///!!!
        S1:=Copy(PropNames,1,J-1);
        Delete(s1,1,1);
        Delete(PropNames,1,J+1);
      end else begin
        //иначе все до след запятой
        S1:=DivStr(PropNames);
      end;
      //
      if (pObj=nil) and (Info.Kind=tkClass)and (Info.ObjProp<>nil) then
        pObj:=Info.ObjProp;
      N:=GetNodeFromPath(Node,S,ForceNode);
      if (N<>nil)and(pObj<>nil) then begin
        InternalBypass(S1,N,pObj,GetSetProc,ForceNode);
      end;
    end else begin
      GetSetProc(Info,Node);
    end;
  end;
end;

function TCustomPropStorage.GetWorkNode(APath: string; Forced: boolean
  ): TDOMElement;
var N:TDOMNode;
begin
  Result:=FActiveNode;
  if APath='' then
    Exit;
  N:=FCustomRoot;
  if APath[1]='/' then begin
    N:=FActiveNode;
    Delete(APath,1,1);
  end;
  N:=GetNodeFromPath(N,APath,Forced);
  if N<>nil then Result:=N as TDOMElement
  else Result:=nil;
end;

constructor TCustomPropStorage.Create(AFileName: string);
begin
  FDoc:=nil;
  FActiveNode:=nil;
  FFileName:='';
  FPath:='';
  FModified:=False;
  if AFileName='' then begin
    AFileName:=ParamStr(0);
    AFileName:=ChangeFileExt(AFileName,'.xini');
  end;
  FFileName:=AFileName;;
  if FileExists(FFileName) then
    try
      Load;
    except
      ShowMessage('Error read INI-File.');
      NewFile;
    end
  else
    NewFile;
end;

destructor TCustomPropStorage.Destroy;
begin
  FreeAndNil(FDoc);
end;

procedure TCustomPropStorage.LoadStrings(AName: string; AData: TStrings);
var e:TDOMElement;
begin
  e:=TDOMElement(GetNodeFromPath(FStrRot,AName,False));
  if e=nil then Exit;
  XLoadStrings(AData,e);
end;

procedure TCustomPropStorage.SaveStrings(AName: string; AData: TStrings);
var e:TDOMElement;
begin
  e:=TDOMElement(GetNodeFromPath(FStrRot,AName,True));
  XDeleteChildren(e);
  XSaveStrings(AData,e);
end;


procedure LoadProperty(AInfo:TZClassInfo;ANode:TDOMNode);
begin
  if (ANode as TDOMElement).hasAttribute(AInfo.PropName) then begin
    AInfo.Value:=(ANode as TDOMElement)[AInfo.PropName];
    //DebugLn('load objtype:'+AInfo.Obj.ClassName+' prop: '+AInfo.PropName+' value:'+AInfo.Value);
  end;
end;


procedure TCustomPropStorage.LoadComponent(AProps: string; AData: TComponent);
var N:TDOMNode;
begin
  //DebugLn('Load Component');
  N:=GetNodeFromPath(FFormsRoot,AData.Name,False);
  if N<>nil then
    InternalBypass(AProps,N,AData,@LoadProperty,False);
end;

procedure SaveProperty(AInfo:TZClassInfo;ANode:TDOMNode);
begin
  (ANode as TDOMElement)[AInfo.PropName]:=AInfo.Value;
  //DebugLn('save objtype:'+AInfo.Obj.ClassName+' prop: '+AInfo.PropName+' value:'+AInfo.Value);
end;

procedure TCustomPropStorage.SaveComponent(AProps: string; AData: TComponent);
var N:TDOMNode;
begin
  DebugLn('Save Component');
  N:=GetNodeFromPath(FDoc.DocumentElement,nForms+'/'+AData.Name,True);
  InternalBypass(AProps,N,AData,@SaveProperty,True);
end;

procedure TCustomPropStorage.TestSaveComponent(AName: string; AData: TComponent
  );
var N:TDOMNode;
begin
  //вальнуть потом нафмг
  N:=GetNodeFromPath(FCustomRoot,AName,True);
  if N=nil then begin
    ShowMessage('node from test save not found!!');
    Exit;
  end;
  if N is  TDOMElement then ;
  XSaveObject(AData,TDOMElement(N));
end;

procedure TCustomPropStorage.OpenPath(APath: string);
var N:TDOMNode;
    RelFlag:boolean;
begin
  //отыскиваем среди дочерних узла userdata наш с указанным путем
  //и запоминаем его
  //надо учесть, что если путь начинается с /, то это путь относительно тек узла
  //иначе относительно FCustomRoot
  //пока не сделано
  if APath='' then begin
    FActiveNode:=FCustomRoot;
    FPath:='';
    Exit;
  end;
  RelFlag:=False;
  N:=FCustomRoot;
  if APath[1]='/' then begin
    N:=FActiveNode;
    Delete(APath,1,1);
    RelFlag:=True;
  end;
  N:=GetNodeFromPath(N,APath,True);
  FActiveNode:=N as TDOMElement;
  if RelFlag then FPath:=FPath+'/'+APath
  else FPath:=APath;
end;

procedure TCustomPropStorage.ClosePath;
begin
  //пока ничего не делаем
  FPath:='';;
  FActiveNode:=FCustomRoot;
end;

procedure TCustomPropStorage.ClearValues(APath: string);
var N:TDOMNode;
begin
  N:=GetWorkNode(APath,False);
  if N<>nil then begin
    paramstorage.ClearValues(N);
    FModified:=True;
  end;
end;

procedure TCustomPropStorage.DeleteValue(const APath, KeyName: DOMString);
var N:TDOMNode;
begin
  //валим атрибут с указанным именем в узле с указанным путем или в текущем
  N:=GetWorkNode(APath,False);
  if N<>nil then begin
    paramstorage.DeleteValue(N,KeyName);
    FModified:=True;
  end;
end;

procedure TCustomPropStorage.DeletePath(APath: string);
var N:TDOMNode;
begin
  //тут надо еще проверить, чтобы если валим активный, то переходим к коорню
  //проверить, чтобы тек путь не
  N:=GetWorkNode(APath,False);
  if N=nil then Exit;
  //вот тут проверяем
  if N<>FCustomRoot then begin
    N.ParentNode.DetachChild(N);
    FreeAndNil(N);
    if APath='' then begin
      FActiveNode:=FCustomRoot;
      FPath:='';
      FModified:=True;
      Exit;
    end;
    if APath[1]='/' then Exit; //если относительный, то ничего не меняется
    //если у нас переданный путь входит в текущий полностью, то сбасываем текущий
    if Pos(APath,FPath)=1 then begin
      FActiveNode:=FCustomRoot;
      FPath:='';
      FModified:=True;
    end;
  end else begin//если у нас текущим является кастомрут, то валим его и заново создаем
    N:=FCustomRoot.ParentNode;
    FCustomRoot.ParentNode.DetachChild(FCustomRoot);
    FreeAndNil(FCustomRoot);
    FCustomRoot:=FDoc.CreateElement(nUser);
    N.AppendChild(FCustomRoot);
    FActiveNode:=FCustomRoot;
    FPath:='';
    FModified:=True;
  end;
end;

function TCustomPropStorage.HasValue(APath, AKey: string): boolean;
var N:TDOMNode;
begin
  Result:=False;
  N:=GetWorkNode(APath,False);
  if N=nil then Exit;
  Result:=(N as TDOMElement).hasAttribute(AKey);
end;

function TCustomPropStorage.HasValues(APath: string): boolean;
var N:TDOMNode;
begin
  Result:=False;
  N:=GetWorkNode(APath,False);
  if N=nil then Exit;
  Result:=N.HasAttributes;
end;

procedure TCustomPropStorage.GetValues(APath: string; AValues: TStrings);
var N:TDOMNode;
begin
  N:=GetWorkNode(APath,False);
  if N=nil then Exit;
  XAttrList(N,AValues);
end;

procedure TCustomPropStorage.GetChildNodes(APath: string; AValues: TStrings);
var N:TDOMNode;
begin
  N:=GetWorkNode(APath,False);
  if N=nil then Exit;
  XChildList(N,AValues);
end;

procedure TCustomPropStorage.SetValue(APath, KeyName: string; AValue: string);
begin
  (GetWorkNode(APath,True) as TDOMElement).AttribStrings[KeyName]:=AValue;
  FModified:=True;
end;

procedure TCustomPropStorage.SetValue(APath, KeyName: string; AValue: Integer);
begin
  (GetWorkNode(APath,True) as TDOMElement).AttribStrings[KeyName]:=IntToStr(AValue);
  FModified:=True;
end;

procedure TCustomPropStorage.SetValue(APath, KeyName: string; AValue: Boolean);
var S:string;
begin
  S:='0';
  if AValue then S:='1';
  (GetWorkNode(APath,True) as TDOMElement).AttribStrings[KeyName]:=S;
  FModified:=True;
end;

function TCustomPropStorage.GetValue(APath, KeyName: string; ADefault: Boolean
  ): boolean;
var N:TDOMNode;
begin
  N:=GetWorkNode(APath,False);
  Result:=ADefault;
  if (N=nil) then Exit;
  if not (N as TDOMElement).hasAttribute(KeyName) then Exit;
  Result:=StrToInt((N as TDOMElement).AttribStrings[KeyName])<>0;
end;

function TCustomPropStorage.GetValue(APath, KeyName: string; ADefault: Integer
  ): Integer;
var N:TDOMNode;
begin
  N:=GetWorkNode(APath,False);
  Result:=ADefault;
  if (N=nil) then Exit;
  if not (N as TDOMElement).hasAttribute(KeyName) then Exit;
  Result:=StrToInt((N as TDOMElement).AttribStrings[KeyName]);
end;

function TCustomPropStorage.GetValue(APath, KeyName: string; ADefault: string
  ): string;
var N:TDOMNode;
begin
  N:=GetWorkNode(APath,False);
  Result:=ADefault;
  if (N=nil) then Exit;
  if not (N as TDOMElement).hasAttribute(KeyName) then Exit;
  Result:=(N as TDOMElement).AttribStrings[KeyName];
end;

procedure TCustomPropStorage.Load;
var R:TDOMElement;
begin
  //загрузка узлов
  ReadXMLFile(FDoc,FFileName);
  R:=FDoc.DocumentElement;
  FDataRoot:=R.FindNode(nData) as TDOMElement;
  FFormsRoot:=R.FindNode(nForms)as TDOMElement;
  FCustomRoot:=R.FindNode(nUser)as TDOMElement;
  FStrRot:=R.FindNode(nStrings)as TDOMElement;
  XLoadObject(Self,FDataRoot);
  FActiveNode:=FCustomRoot;
  FPath:='';
end;

procedure TCustomPropStorage.Save;
begin
  //соранение узлов
  XSaveObject(Self,FDataRoot,FModified);
  XMLWrite.WriteXMLFile(FDoc,FFileName);
end;

procedure TCustomPropStorage.NewFile;
var R:TDOMElement;
begin
  //создание нового файла
  FActiveNode:=nil;
  FDoc:=TXMLDocument.Create;
  FDoc.XMLStandalone:=True;
  FDoc.XMLVersion:='1.0';
  R:=FDoc.CreateElement(nOptions);
  FDoc.AppendChild(R);
  FDataRoot:=FDoc.CreateElement(nData);
  R.AppendChild(FDataRoot);

  FStrRot:=FDoc.CreateElement(nStrings);
  R.AppendChild(FStrRot);

  FFormsRoot:=FDoc.CreateElement(nForms);
  R.AppendChild(FStrRot);

  FCustomRoot:=FDoc.CreateElement(nUser);
  R.AppendChild(FCustomRoot);
  FActiveNode:=FCustomRoot;
  FPath:='';
end;

end.

