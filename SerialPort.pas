unit SerialPort;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,MSCommLib_TLB;

  procedure SerialPortTest(Port : String;Flag : Word; Factory : Word);

implementation

uses
  Test_Project;

var
  MSCOMM1 : TMSCOMM;



procedure SerialPortTest(Port : String;Flag : Word; Factory : Word);
begin
  if Flag = 0 then
  begin

  end
  else
    ShowMessage('COMΩ”ø⁄Œ¥≤‚ ‘!');


end;


end.
