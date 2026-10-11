unit uCPU;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms;

  function CPUTest(CPU_Name : String):Boolean ; stdcall; export;
  function RunProgram(ProgramName: String; Wait:Boolean=False):Cardinal; stdcall;
  function IsProgram_Runing(hProcess:Cardinal):Boolean; stdcall;

implementation

function CPUTest(CPU_Name : String): Boolean; stdcall; export;
var
  List : TStringList;
  i : Word;
  FileName,Parame : String;
begin
    Result := False;
    FileName := ExtractFilePath(ParamStr(0)) + 'CPU.txt';
    Parame := ExtractFilePath(ParamStr(0)) + 'CPU.exe';
    List := TStringList.Create;
    try
      if RunProgram(Parame,True) > 0 then
      begin
        List.LoadFromFile(FileName);
        for I := 0 to List.Count - 1 do
        begin
          if Trim(List[i]) = CPU_Name then Result := True
             else  Result := False;
        end;
      end
      else Result := False;
    finally
      List.Free;
    end;
end;

function RunProgram(ProgramName: String; Wait:Boolean=False):Cardinal; stdcall;
var
	StartInfo : STARTUPINFO;
	ProcessInfo:PROCESS_INFORMATION;
begin
	Result := 0;
	if ProgramName = '' then exit;
	GetStartupInfo(StartInfo);
	StartInfo.dwFlags := StartInfo.dwFlags or STARTF_FORCEONFEEDBACK;
	if not CreateProcess(nil,PChar(ProgramName),nil,nil,false,0,nil,nil,StartInfo,ProcessInfo) then exit;
	Result := ProcessInfo.hProcess;
//建立进程成功
//如果异步执行则退出
if not wait then exit;
	while IsProgram_Runing(Result) do Application.ProcessMessages;

end;

//同步执行
function IsProgram_Runing(hProcess:Cardinal):Boolean; stdcall;
var
	ExitCode: Cardinal;
begin
	GetExitCodeProcess(hProcess,ExitCode);
	Result := ExitCode =STILL_ACTIVE;
end;

end.
