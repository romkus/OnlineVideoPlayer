program Project1;

uses
  SysUtils,
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  UDirectShowHelp in 'SharedSource\UDirectShowHelp.pas',
  DataHelper in 'SharedSource\DataHelper.pas',
  OSFuncHelper in 'SharedSource\OSFuncHelper.pas',
  ShLwApi in 'SharedSource\ShLwApi.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
