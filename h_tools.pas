unit h_tools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MSHTML_4_0_TLB;


function elemByPath(root:IHTMLElement;Path:string):IHTMLElement;
function SupportsList(D:IDispatch):TStrings;
function SupportStr(D:IDispatch):String;

implementation

uses s_tools;

function elemByPath(root: IHTMLElement; Path: string): IHTMLElement;
var hc:IHTMLElementCollection;
    S:string;
begin
  Result:=nil;
	S:=DivStr(Path,'\');
  if root=nil then Exit;
  hc:=root.children as IHTMLElementCollection;
  if hc=nil then Exit;
  if S='' then begin
    Result:=root;
    Exit;
  end;
  Result:=hc.Item(StrToInt(S),0) as IHTMLElement;
  if Path<>'' then
  	Result:=elemByPath(Result,Path);
end;

function SupportsList(D: IDispatch): TStrings;
begin
  Result:=TStringList.Create;
  if D is IHTMLDocument then Result.Add('IHTMLDocument');
  if D is IHTMLDocument2 then Result.Add('IHTMLDocument2');
  if D is IHTMLDocument3 then Result.Add('IHTMLDocument3');
  if D is IHTMLDocument4 then Result.Add('IHTMLDocument4');
  if D is IHTMLDocument5 then Result.Add('IHTMLDocument5');
  if D is IHTMLDocument6 then Result.Add('IHTMLDocument6');
  if D is IHTMLDocument7 then Result.Add('IHTMLDocument7');
  if D is IHTMLElement then Result.Add('IHTMLElement');
  if D is IHTMLElement2 then Result.Add('IHTMLElement2');
  if D is IHTMLElement3 then Result.Add('IHTMLElement3');
  if D is IHTMLElement4 then Result.Add('IHTMLElement4');
  if D is IHTMLElement5 then Result.Add('IHTMLElement5');
  if D is IHTMLElement6 then Result.Add('IHTMLElement6');
  if D is IHTMLElement7 then Result.Add('IHTMLElement7');
  if D is IHTMLElementCollection then Result.Add('IHTMLElementCollection');
  if D is IHTMLElementCollection2 then Result.Add('IHTMLElementCollection2');
  if D is IHTMLElementCollection3 then Result.Add('IHTMLElementCollection3');
  if D is IHTMLElementCollection4 then Result.Add('IHTMLElementCollection4');
  if D is IHTMLInputElement then Result.Add('IHTMLInputElement');
  if D is IHTMLInputElement2 then Result.Add('IHTMLInputElement2');
  if D is IHTMLInputElement3 then Result.Add('IHTMLInputElement3');
  if D is IHTMLAnchorElement then Result.Add('IHTMLAnchorElement');
  if D is IHTMLAreaElement then Result.Add('IHTMLAreaElement');
  if D is IHTMLApplicationCache then Result.Add('IHTMLApplicationCache');
  if D is IHTMLAreasCollection then Result.Add('IHTMLAreasCollection');
  if D is IHTMLAttributeCollection then Result.Add('IHTMLAttributeCollection');
  if D is IHTMLBaseElement then Result.Add('IHTMLBaseElement');
  if D is IHTMLBlockElement then Result.Add('IHTMLBlockElement');
  if D is IHTMLBodyElement then Result.Add('IHTMLBodyElement');
  if D is IHTMLButtonElement then Result.Add('IHTMLButtonElement');
  if D is IHTMLCanvasElement then Result.Add('IHTMLCanvasElement');
  if D is IHTMLCaret then Result.Add('IHTMLCaret');
  if D is IHTMLCommentElement then Result.Add('IHTMLCommentElement');
  if D is IHTMLControlElement then Result.Add('IHTMLControlElement');
  if D is IHTMLControlRange then Result.Add('IHTMLControlRange');
  if D is IHTMLCSSRule then Result.Add('IHTMLCSSRule');
  if D is IHTMLCSSStyleDeclaration then Result.Add('IHTMLCSSStyleDeclaration');
  if D is IHTMLControlRange then Result.Add('IHTMLControlRange');
  if D is IHTMLCurrentStyle then Result.Add('IHTMLCurrentStyle');
  if D is IHTMLDatabinding then Result.Add('IHTMLDatabinding');
  if D is IHTMLDialog then Result.Add('IHTMLDialog');
  if D is IHTMLDivElement then Result.Add('IHTMLDivElement');
  if D is IHTMLDivPosition then Result.Add('IHTMLDivPosition');
  if D is IHTMLDListElement then Result.Add('IHTMLDListElement');
  if D is IHTMLDOMAttribute then Result.Add('IHTMLDOMAttribute');
  if D is IHTMLEditDesigner then Result.Add('IHTMLEditDesigner');
  if D is IHTMLElementCollection then Result.Add('IHTMLElementCollection');
  if D is IHTMLEventObj then Result.Add('IHTMLEventObj');
  if D is IHTMLFieldSetElement then Result.Add('IHTMLFieldSetElement');
  if D is IHTMLFontElement then Result.Add('IHTMLFontElement');
  if D is IHTMLFormElement then Result.Add('IHTMLFormElement');
//  if D is IHTML then Result.Add('');
  if D is IHTMLFrameBase then Result.Add('IHTMLFrameBase');
  if D is IHTMLFrameElement then Result.Add('IHTMLFrameElement');
  if D is IHTMLFrameSetElement then Result.Add('IHTMLFrameSetElement');
  if D is IHTMLGenericElement then Result.Add('IHTMLGenericElement');
  if D is IHTMLHeadElement then Result.Add('IHTMLHeadElement');
  if D is IHTMLHeaderElement then Result.Add('IHTMLHeaderElement');
  if D is IHTMLHRElement then Result.Add('IHTMLHRElement');
  if D is IHTMLHtmlElement then Result.Add('IHTMLHtmlElement');
  if D is IHTMLIFrameElement then Result.Add('IHTMLIFrameElement');
  if D is IHTMLImgElement then Result.Add('IHTMLImgElement');
  if D is IHTMLImageElementFactory then Result.Add('IHTMLImageElementFactory');
  if D is IHTMLInputButtonElement then Result.Add('IHTMLInputButtonElement');
  if D is IHTMLInputElement then Result.Add('IHTMLInputElement');
  if D is IHTMLInputImage then Result.Add('IHTMLInputImage');
  if D is IHTMLInputFileElement then Result.Add('IHTMLInputFileElement');
  if D is IHTMLInputHiddenElement then Result.Add('IHTMLInputHiddenElement');
  if D is IHTMLInputRangeElement then Result.Add('IHTMLInputRangeElement');
  if D is IHTMLInputTextElement then Result.Add('IHTMLInputTextElement');
  if D is IHTMLIsIndexElement then Result.Add('IHTMLIsIndexElement');
  if D is IHTMLLabelElement then Result.Add('IHTMLLabelElement');
  if D is IHTMLLegendElement then Result.Add('IHTMLLegendElement');
  if D is IHTMLLIElement then Result.Add('IHTMLLIElement');
  if D is IHTMLLinkElement then Result.Add('IHTMLLinkElement');
  if D is IHTMLBaseElement then Result.Add('IHTMLBaseElement');
  if D is IHTMLLocation then Result.Add('IHTMLLocation');
  if D is IHTMLMapElement then Result.Add('IHTMLMapElement');
  if D is IHTMLMarqueeElement then Result.Add('IHTMLMarqueeElement');
  if D is IHTMLMediaElement then Result.Add('IHTMLMediaElement');
  if D is IHTMLMetaElement then Result.Add('IHTMLMetaElement');
  if D is IHTMLModelessInit then Result.Add('IHTMLModelessInit');
  if D is IHTMLMSImgElement then Result.Add('IHTMLMSImgElement');
  if D is IHTMLNamespace then Result.Add('IHTMLNamespace');
  if D is IHTMLNextIdElement then Result.Add('IHTMLNextIdElement');
  if D is IHTMLNoShowElement then Result.Add('IHTMLNoShowElement');
  if D is IHTMLObjectElement then Result.Add('IHTMLObjectElement');
  if D is IHTMLOListElement then Result.Add('IHTMLOListElement');
  if D is IHTMLOptionButtonElement then Result.Add('IHTMLOptionButtonElement');
  if D is IHTMLOptionElement then Result.Add('IHTMLOptionElement');
  if D is IHTMLOptionsHolder then Result.Add('IHTMLOptionsHolder');
  if D is IHTMLPainter then Result.Add('IHTMLPainter');
  if D is IHTMLPaintSite then Result.Add('IHTMLPaintSite');
  if D is IHTMLParaElement then Result.Add('IHTMLParaElement');
  if D is IHTMLParamElement then Result.Add('IHTMLParamElement');
  if D is IHTMLPerformance then Result.Add('IHTMLPerformance');
  if D is IHTMLPhraseElement then Result.Add('IHTMLPhraseElement');
  if D is IHTMLPopup then Result.Add('IHTMLPopup');
  if D is IHTMLProgressElement then Result.Add('IHTMLProgressElement');
  if D is IHTMLRect then Result.Add('IHTMLRect');
  if D is IHTMLRuleStyle then Result.Add('IHTMLRuleStyle');
  if D is IHTMLScreen then Result.Add('IHTMLScreen');
  if D is IHTMLScriptElement then Result.Add('IHTMLScriptElement');
  if D is IHTMLSelectElement then Result.Add('IHTMLSelectElement');
  if D is IHTMLSelection then Result.Add('IHTMLSelection');
  if D is IHTMLSelectionObject then Result.Add('IHTMLSelectionObject');
  if D is IHTMLSourceElement then Result.Add('IHTMLSourceElement');
  if D is IHTMLSpanElement then Result.Add('IHTMLSpanElement');
  if D is IHTMLSpanFlow then Result.Add('IHTMLSpanFlow');
  if D is IHTMLStorage then Result.Add('IHTMLStorage');
  if D is IHTMLStyle then Result.Add('IHTMLStyle');
  if D is IHTMLStyleElement then Result.Add('IHTMLStyleElement');
  if D is IHTMLStyleSheet then Result.Add('IHTMLStyleSheet');
  if D is IHTMLSubmitData then Result.Add('IHTMLSubmitData');
  if D is IHTMLTable then Result.Add('IHTMLTable');
  if D is IHTMLTableCaption then Result.Add('IHTMLTableCaption');
  if D is IHTMLTableCell then Result.Add('IHTMLTableCell');
  if D is IHTMLTableCol then Result.Add('IHTMLTableCol');
  if D is IHTMLTableRow then Result.Add('IHTMLTableRow');
  if D is IHTMLTableSection then Result.Add('IHTMLTableSection');
  if D is IHTMLTextAreaElement then Result.Add('IHTMLTextAreaElement');
  if D is IHTMLTextContainer then Result.Add('IHTMLTextContainer');
  if D is IHTMLTextElement then Result.Add('IHTMLTextElement');
  if D is IHTMLTimeRanges then Result.Add('IHTMLTimeRanges');
  if D is IHTMLTitleElement then Result.Add('IHTMLTitleElement');
  if D is IHTMLTxtRange then Result.Add('IHTMLTxtRange');
  if D is IHTMLUListElement then Result.Add('IHTMLUListElement');
  if D is IHTMLUniqueName then Result.Add('IHTMLUniqueName');
  if D is IHTMLUnknownElement then Result.Add('IHTMLUnknownElement');
  if D is IHTMLWindow2 then Result.Add('IHTMLWindow2');

end;

function SupportStr(D: IDispatch): String;
var S:TStrings;
begin
  S:=SupportsList(D);
  Result:=S.CommaText;
  S.Free;
end;

end.

