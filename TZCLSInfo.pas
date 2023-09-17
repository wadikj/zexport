unit TZCLSInfo;

interface
uses TypInfo,Classes, SysUtils;

type
{$M+}
  TWPropType = (twSimple,twClass, twComp, twProp);
	{twSimple  - простое свойство (не класс)
  twClass - свойство - класс (TFont)
  twComp - свойство - ссылка на компонент (ActiveControl)
	twProp - то же, что и twClass,  но только компонент (VertScrollBAr)
	}
	EClassInfo = class (Exception);

	TZClassInfo = class(TObject)
		private
			FPropTData:PTypeData;
      FPropList:PPropList;
      FPropInfo:PPropInfo;
      FTypeData:PTypeData;
    	FPropCount: integer;
    	FPropName: string;
    	FObj: TObject;
			FKind: TTypeKind;
    	FPropNumber: Integer;
    	procedure SetObj(const Value: TObject);
    	procedure SetPropName(const Value: string);
    	procedure SetValue(const Value: string);
    	procedure SetPropNumber(const Value: Integer);
      procedure SetObjProp(Const Value:TObject);
      function GetValue:string;
      function GetObjProp:TObject;
      function GetDefValue:LongInt;
      function GetIsDef:boolean;
      function GetPropertyType:TWPropType;
	    function GetStored: boolean;
      function GetEnumCount: Integer;
	    function GetDate: TDateTime;
		protected

		public
  		destructor Destroy; override;
  		Constructor Create(AClass:TObject);
			property Obj:TObject read FObj write SetObj;
      	//read/write указатель на текущий объект
			property PropCount:integer read FPropCount; //ReadOnly
			property Value:string read GetValue write SetValue; //read/write
			property PropNumber:Integer read FPropNumber write SetPropNumber;
      	//read/write с помощью этого свойства устанавливается/
				//считывается номер свойства, значение которого отражается в свойстве Value
			property PropName:string read FPropName write SetPropName;
				//с помощью этого свойства устанавливается/считывается
				//название свойства, значение которого отражается в свойстве Value
			property TypeData:PTypeData read FTypeData;
			property PropInfo:PPropInfo read FPropInfo;
			property PropTData:PTypeData read FPropTData;
			property ObjProp:TObject read GetObjProp write SetObjProp;
			property DefValue:LongInt Read GetDefValue;
			property IsDefValue:boolean read GetIsDef;
			procedure GetEnumType(EnumType:TStrings);
      property  EnumCount:Integer read GetEnumCount;
			property SType:TWPropType read GetPropertyType;
			property IsStored:boolean read GetStored;
			property AsDate:TDateTime read GetDate;
		published
			property Kind:TTypeKind read FKind;//тип текущего свойства

  end;


implementation
uses Dialogs;
type
TIntegerSet = set of 0..SizeOf(Integer) * 8 - 1;

{ TZClassInfo }

constructor TZClassInfo.Create(AClass: TObject);
begin
	Inherited Create;
  FObj:=nil;
  FPropList:=nil;
  SetObj(AClass);
end;

destructor TZClassInfo.Destroy;
begin
	if FObj<>nil then
  FreeMem(FPropList,FPropCount*SizeOf(Pointer));
  Inherited;
end;


function TZClassInfo.GetValue: string;
var TypeInfo:PTypeInfo;
		ATypeData:PTypeData;
		I,I1:LongInt;
    //I64:Int64;
begin
	case FKind of
		tkInteger:Result:=IntToStr(GetOrdProp(FObj,FPropInfo));
		tkString, tkAString,tkChar,tkLString:Result:=GetStrProp(FObj,FPropInfo);
		tkClass: begin
			 TypeInfo:=FPropInfo^.PropType;
			 ATypeData:=GetTypeData(TypeInfo);
			 Result:=ATypeData^.ClassType.ClassName;
    end;
		tkEnumeration, tkBool:begin
      I:=GetOrdProp(FObj,FPropInfo);
    	Result:=GetEnumName(FPropInfo^.PropType,I);
    end;
    tkSet:begin
    	I1:=GetOrdProp(FObj,FPropInfo);
      TypeInfo:=FPropTData^.CompType;
      Result:='[';
      for I := 0 to SizeOf(TIntegerSet) * 8 - 1 do
	      if I in TIntegerSet(I1) then Result:=Result+GetEnumName(TypeInfo, I)+',';
      if Length(Result)=1 then Result:=Result+']' else
      Result[Length(Result)]:=']';
		end;
    tkInt64:Result:=IntToStr(GetInt64Prop(FObj,FPropInfo));
    tkFloat:Result:=FloatToStr(GetFloatProp(FObj,FPropInfo));
	else Result:='Unknown:'+IntToStr(Integer(FKind));
	end;
end;

procedure TZClassInfo.SetObj(const Value: TObject);
begin
	{если передан пустой обект, то выйти}
	if Value=FObj then Exit;
	{получение информации о типе}
			FTypeData:=GetTypeData(Value.ClassInfo);
	{если свойств не найдено у данного объекта, то выйти}
			if FTypeData^.PropCount = 0 then Exit;
	{освобождение памяти, занимаемой информацией о свойствах старого объекта}
			if FObj<>nil then FreeMem(FPropList,FPropCount*sizeOf(Pointer));
	{сохранение переданного объекта для работы с его свойствами}
			FObj := Value;
			if Value<>nil then Begin
			{получение информации о типе переданного объекта}
  	      FTypeData:=GetTypeData(Value.ClassInfo);
      {получение счисла свойств объекта и выделение места под
       информацию о них}
  	      FPropCount:=FTypeData^.PropCount;
  	      GetMem(FPropList,FPropCount*SizeOf(Pointer));
  	      GetPropInfos(FObj.ClassInfo,FPropList);
  	      PropNumber:=0;
      end;
end;


procedure TZClassInfo.SetPropName(const Value: string);
var PI:PPropInfo;
	  TypeInfo:PTypeinfo;
begin
  FPropName := Value;
  PI:=GetPropInfo(FObj.ClassInfo,Value);
  if PI=nil then
  		raise EClassInfo.CreateFmt('Cвойствo %s не найдено',[Value])
  else begin
  	FPropInfo:=PI;
	  FPropNumber:=PI^.NameIndex;
    TypeInfo:=FPropinfo^.PropType;
    FKind:=TypeInfo^.Kind;
    FPropTData:=GetTypeData(Typeinfo);
  end;
end;

procedure TZClassInfo.SetPropNumber(const Value: Integer);
var TypeInfo:PTypeInfo;
begin
	if Value<PropCount then begin
  	FPropNumber := Value;
  	FPropInfo:=FPropList^[Value];
    FPropName:=FPropInfo^.Name;
    TypeInfo:=FPropInfo^.PropType;
    FPropTData:=GetTypeData(Typeinfo);
    FKind:=TypeInfo^.Kind;
  end else
  		raise EClassInfo.CreateFmt('Свойство %d не найдено,%s',[Value,FPropName]);
end;

procedure TZClassInfo.SetValue(const Value: string);
var I:LongInt;
		TypeInfo:PTypeInfo;
    IZ:TIntegerSet;
    S,S1:string;
begin
  case FKind Of
  	tkInteger:SetOrdProp(FObj,FPropInfo,StrToInt(Value));
    tkInt64:SetInt64Prop(FObj,FPropInfo,StrToInt64(Value));
    tkString,tkLString,tkAString:SetStrProp(FObj,FPropInfo,Value);
    tkFloat:SetFloatProp(FObj,FPropInfo,StrToFloat(Value));
    //tkBool:;
    tkEnumeration, tkBool:begin
    	I:=GetEnumValue(FPropInfo^.PropType,Value);
      SetOrdProp(FObj,FPropInfo,I);
    end;
    tkSet:begin
    	TypeInfo:=FPropTData^.CompType;
      IZ:=[];
      S:=Value;S1:='';
      for I:=1 to Length(S) do begin
				if not(S[I]in[#0..#32,'[',']']) then S1:=S1+S[i];
      end;
      S:=S1;
      while True do begin
        if S='' then Break;
        I:=Pos(',',S);
        if I=0 then begin
        	S1:=S;
          S:='';
        end else begin
					S1:=Copy(S,1,I-1);
          Delete(S,1,I);
        end;
      	Include(IZ, GetEnumValue(TypeInfo,S1));
    	end;
      SetOrdProp(FObj,FPropInfo,Integer(IZ));
    end;
  else Raise EClassInfo.CreateFmt('Invalid property value: %s',[Value]);
	end;
end;

function TZClassInfo.GetObjProp:TObject;
begin
	Result:=TObject(GetOrdProp(FObj,FPropInfo));
end;

function TZClassInfo.GetDefValue:LongInt;
begin
	Result:=FPropInfo^.Default;
end;

function TZClassInfo.GetIsDef:Boolean;
begin
	Result:=(FPropInfo^.Default)=(GetOrdProp(FObj,FPropInfo));
end;

procedure TZClassInfo.GetEnumType(EnumType: TStrings);
var TypeInfo:PTypeInfo;
//		S:String;
    I:Integer;
    ATypeData:PTypeData;
begin
	TypeInfo:=nil;
  ATypeData:=nil;
	if Kind=tkEnumeration then begin
  	TypeInfo:=FPropInfo^.PropType;
    ATypeData:=FPropTdata;
//      I:=GetOrdProp(FObj,FPropInfo);
//    	Result:=GetEnumName(FPropInfo^.PropType^,I);
	end else if Kind=tkSet  then begin
    TypeInfo:=FPropTData^.CompType;
		ATypeData:=GetTypedata(TypeInfo);
	end {else errorhandler};
  //I1:=GetOrdProp(FObj,FPropInfo);
  //TypeInfo:=FPropTData^.CompType^;
  //Result:='[';
	if Kind=tkEnumeration then begin
  	for i:=TypeData^.MinValue to ATypeData^.MaxValue do
	    EnumType.Add(GetEnumName(TypeInfo,I));
  end else begin
  	for i:=ATypeData^.MinValue to ATypeData^.MaxValue do
	    EnumType.Add(GetEnumName(TypeInfo,I));
  //  TypeInfo:=FPropTData^.CompType^;
   // ShowMessage('Value Type is '+IntToStr(Integer(TypeInfo^.Kind)));
  end;
  {for I := 0 to SizeOf(TIntegerSet) * 8 - 1 do begin
  	S:=GetEnumName(FPropInfo^.PropType^,I);
    if S<>'' then EnumType.Add(S);
  //if I in TIntegerSet(I1) then Result:=Result+GetEnumName(TypeInfo, I)+',';
      //if Length(Result)=1 then Result:=Result+']' else
      //Result[Length(Result)]:=']';
  end; }


end;

function TZClassInfo.GetPropertyType: TWPropType;
//var S:string;
begin
//смотрит на свойство и говорит, как это свойство записывается и
//взаимодействует с инспектором объектов
  if FKind<>tkClass then begin
  	Result:=twSimple;
    Exit;
  end;
	Result:=twClass;
  if ObjProp=nil then begin Result:=twComp;Exit;end;
  if (ObjProp is TComponent) then begin
		{S:=TComponent(ObjProp).Name;
		if S='' then begin Result:=twProp;exit;end
    else begin    }
    	Result:=twComp;
      Exit;
    //end;
		//if TComponent(FObj).FindComponent(S)<>nil then Result:=twComp
    //else Result:=twProp;
  end;
end;

procedure TZClassInfo.SetObjProp(const Value: TObject);
begin
	SetOrdProp(FObj,FPropInfo,ptrint(Value));
end;

function TZClassInfo.GetStored: boolean;
begin
	Result:=IsStoredProp(FObj,FPropName);
end;

function TZClassInfo.GetEnumCount: Integer;
var TypeInfo:PTypeInfo;
    ATypeData:PTypeData;
begin
  Result:=0;
	if Kind=tkEnumeration then begin
    ATypeData:=FPropTdata;
  end else if Kind=tkSet  then begin
    TypeInfo:=FPropTData^.CompType;
		ATypeData:=GetTypedata(TypeInfo);
	end else Exit;
  Result:=ATypeData^.MaxValue - ATypeData^.MinValue;
end;

function TZClassInfo.GetDate: TDateTime;
var D:Double;
begin
	Result:=0;
	if FKind=tkFloat then begin
		D:=(GetFloatProp(FObj,FPropInfo));
		Result:=TDateTime(D);
	end
end;

end.
