program ConvertKIMtapetoTXT;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, convertjuniortodosunit;


{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='Convert KIMtape toText';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainform, Mainform);
  Application.Run;
end.

