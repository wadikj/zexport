program blank_zexp;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, SHDocVw_1_1_TLB, MSHTML_4_0_TLB, u_data, main, u_browse, u_htree, u_textview,
  h_tools, u_scr, datetimectrls,
  U_simplescr
  { you can add units after this }
  , u_miniLog, u_fromlist, testreg, u_setfolders, u_buttons, u_SynSearch,
  u_findtree, u_frSQL, u_sqliteinfo, u_projdata, u_connList, u_newConn,
  u_fbinfo, u_fsizes;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TData, Data);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

