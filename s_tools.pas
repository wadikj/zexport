unit s_tools;

interface

uses SysUtils;

//����� ������ �� 2 ����� �� ����������� �����������
function DivStr(var S:string;const Dlm:string=','):string;overload;
function DivStr(var S:widestring;const Dlm:widestring=','):widestring;overload;

//��������� � ��������� ������ �������
function StrListAdd(AList,AItem:string;const AListDlm:string=','):string;
//��������� �� ���������� ������ �������
function StrListGet(var AList:string;const AListDlm:string=','):string;
//���������� ������� ������� ����������� ����������� �� ����������� �������
function DelimiterIndex(S,Delimiters:string):Integer;
//� ������ ���������� ������ ������, ������ ���������, ��� ���������� ��� ����
function FindMatchBrace(const S:string;Index:Integer=1):Integer;
//IntToStr, ������� ����� �� ��, ��� � ��� �������� ���. ������.
function IsNumber(S:string):boolean;


implementation

function DivStr(var S: string; const Dlm: string): string;
var I:Integer;
begin
//������� ������� � ������ ����������� � ����� ������ �� ���� �� ��� �����
//������ - �������, ������ ����������� � ��������
//���� ����������� �� ������, �� ��� ������ ������������  � ���������
  Result:=S;
	I:=Pos(Dlm,S);
  if I=0 then begin
    S:='';
    Exit;
  end;
  Delete(Result,I,Length(Result));
  Delete(S,1,I+Length(Dlm)-1);
end;

function DivStr(var S: widestring; const Dlm: widestring): widestring;
var I:Integer;
begin
//������� ������� � ������ ����������� � ����� ������ �� ���� �� ��� �����
//������ - �������, ������ ����������� � ��������
//���� ����������� �� ������, �� ��� ������ ������������  � ���������
  Result:=S;
	I:=Pos(Dlm,S);
  if I=0 then begin
    S:='';
    Exit;
  end;
  Delete(Result,I,Length(Result));
  Delete(S,1,I+Length(Dlm)-1);
end;

function StrListAdd(AList,AItem:string;const AListDlm:string=','):string;
begin
	if AList<>'' then AList:=AList+AListDlm;
  Result:=AList+AItem;
end;

function StrListGet(var AList:string;const AListDlm:string=','):string;
begin
  Result:=DivStr(AList,AListDlm);
end;

function DelimiterIndex(S,Delimiters:string):Integer;
var I:Integer;
begin
	Result:=0;
	for I:=1 to Length(S) do begin
		if IsDelimiter(Delimiters,S,I) then begin
			Result:=I;
			Break;
		end;
	end;
end;

function FindMatchBrace(const S:string;Index:Integer):Integer;
var LC,RC:Char;
		Lvl:Integer;
begin
	LC:=S[Index];
  case LC of
  	'(':RC:=')';
    '[':RC:=']';
    '<':RC:='>';
    '{':RC:='}';
    else RC:=LC;
  end;
  Result:=Index+1;
  Lvl:=1;
  while Result<=Length(S) do begin
  	if S[Result]=RC then begin
    	Dec(Lvl);
      if Lvl=0 then Exit;
    end;
    if S[Result]=LC then Inc(Lvl);
    Inc(Result);
  end;
  if Lvl<>0 then Result:=0;
end;

function IsNumber(S: string): boolean;
var I:integer;
    Start:Integer;
begin
  Result:=False;
  Start:=1;
  if (Length(S)>1) and (S[1]='-') then begin// ������� - � ������������� �����
    Start:=2;
    //Result:=True;
  end;
  for I:=Start to Length(S) do begin
    Result:=S[I] in ['0'..'9'];
    if not Result then Break;
  end;
end;

end.
