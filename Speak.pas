unit Speak;

interface

uses
  Winapi.ShellAPI,Winapi.Windows,Vcl.Graphics,Vcl.Dialogs,System.Classes,
  System.SysUtils,Vcl.Forms,System.IniFiles;

  function SpeakerTest:Boolean;

implementation

uses
  Test_Project,RunPg;

function SpeakerTest:Boolean;
Var
  FileName,FileName1 : String;
begin
    Result := False;
    FileName := ExtractFilePath(ParamStr(0)) + 'MP3_Player.exe';
    FileName1 := ExtractFilePath(ParamStr(0)) + 'SPK_Fail.txt';
    if RunProgram(FileName,True) = 0 then Result := False;
    if not FileExists(FileName1) then Result := True
        else Result := False;
end;

end.
