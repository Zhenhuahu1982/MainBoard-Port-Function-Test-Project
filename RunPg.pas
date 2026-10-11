unit RunPg;

interface

uses
  Winapi.Windows,Vcl.Forms,System.Classes,
  Winapi.Messages,Winapi.ShellAPI,
  Vcl.Graphics;


   function IsProgram_Runing(hProcess:Cardinal):Boolean;
   function RunProgram(ProgramName: String; Wait:Boolean=False):Cardinal;

implementation


function RunProgram(ProgramName: String; Wait:Boolean=False):Cardinal;
var
	StartInfo : STARTUPINFO;
	ProcessInfo:PROCESS_INFORMATION;
begin
	Result := 0;
	if ProgramName = '' then exit;
	GetStartupInfo(StartInfo);
	StartInfo.dwFlags := StartInfo.dwFlags or STARTF_FORCEONFEEDBACK;
	if not CreateProcess(PChar(ProgramName),nil,nil,nil,false,0,nil,nil,StartInfo,ProcessInfo) then exit;
	Result := ProcessInfo.hProcess;
//建立进程成功
//如果异步执行则退出
if not wait then exit;
	while IsProgram_Runing(Result) do Application.ProcessMessages;

end;

//同步执行
function IsProgram_Runing(hProcess:Cardinal):Boolean;
var
	ExitCode: Cardinal;
begin
	GetExitCodeProcess(hProcess,ExitCode);
	Result := ExitCode =STILL_ACTIVE;
end;

end.
