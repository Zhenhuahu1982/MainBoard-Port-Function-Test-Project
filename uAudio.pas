unit uAudio;

interface

uses
  Winapi.ShellAPI,Winapi.Windows,Vcl.Graphics,Vcl.Dialogs,System.Classes,
  System.SysUtils,Vcl.Forms,Test_Project,System.ShareMem;

  function Audio_Test:Boolean; stdcall; export;
  function RunProgram(ProgramName: String; Wait:Boolean=False):Cardinal; stdcall;
  function IsProgram_Runing(hProcess:Cardinal):Boolean; stdcall;

implementation

function Audio_Test:Boolean; stdcall; export;
Var
  FileName,FileName1 : String;
begin
  Result := False;
  try
    FileName := ExtractFilePath(ParamStr(0)) + 'Audio' + '\wautest.exe';
    FileName1 := ExtractFilePath(ParamStr(0)) + 'Audio' + '\Pass.txt';
    {Strs := TStringList.Create;
    ShellExecute(0,nil,PChar(FileName),nil,nil,0);}
    if RunProgram(FileName,True) = 0 then Result := False;
    if FileExists(FileName1) then Result := True
      else
        Result := False;
  except on E:Exception do
    ShowMessage(E.Message);
  end;
  Application.ProcessMessages;
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
