unit GetSystemInfo1;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,System.StrUtils,Winapi.TlHelp32;


{$IFDEF CONDITIONALEXPRESSIONS}
{$IF Defined(TOSVersionInfoEx)}
{$DEFINE TOSVERSIONINFOEX_DEFINED}
{$IFEND}
{$ENDIF}
{$IFNDEF TOSVERSIONINFOEX_DEFINED}

type

  TWinVer = (WinNone, Win8, Win8_1, Win10, Win95, Win98, WinMe, Win2000, WinServer2000, WinXp, WinXp64, WinServer2003, WinHomeServer, WinServer2003R2, WinVista, WinServer2008, WinServer2008R2, Win7);

const
  VER_SERVER_NT = $80000000;
{$EXTERNALSYM VER_SERVER_NT}
  VER_WORKSTATION_NT = $40000000;
{$EXTERNALSYM VER_WORKSTATION_NT}
  VER_SUITE_SMALLBUSINESS = $00000001;
{$EXTERNALSYM VER_SUITE_SMALLBUSINESS}
  VER_SUITE_ENTERPRISE = $00000002;
{$EXTERNALSYM VER_SUITE_ENTERPRISE}
  VER_SUITE_BACKOFFICE = $00000004;
{$EXTERNALSYM VER_SUITE_BACKOFFICE}
  VER_SUITE_COMMUNICATIONS = $00000008;
{$EXTERNALSYM VER_SUITE_COMMUNICATIONS}
  VER_SUITE_TERMINAL = $00000010;
{$EXTERNALSYM VER_SUITE_TERMINAL}
  VER_SUITE_SMALLBUSINESS_RESTRICTED = $00000020;
{$EXTERNALSYM VER_SUITE_SMALLBUSINESS_RESTRICTED}
  VER_SUITE_EMBEDDEDNT = $00000040;
{$EXTERNALSYM VER_SUITE_EMBEDDEDNT}
  VER_SUITE_DATACENTER = $00000080;
{$EXTERNALSYM VER_SUITE_DATACENTER}
  VER_SUITE_SINGLEUSERTS = $00000100;
{$EXTERNALSYM VER_SUITE_SINGLEUSERTS}
  VER_SUITE_PERSONAL = $00000200;
{$EXTERNALSYM VER_SUITE_PERSONAL}
  VER_SUITE_BLADE = $00000400;
{$EXTERNALSYM VER_SUITE_BLADE}
  VER_SUITE_EMBEDDED_RESTRICTED = $00000800;
{$EXTERNALSYM VER_SUITE_EMBEDDED_RESTRICTED}
  VER_SUITE_SECURITY_APPLIANCE = $00001000;
{$EXTERNALSYM VER_SUITE_SECURITY_APPLIANCE}
  VER_SUITE_WH_SERVER = $00008000;
{$EXTERNALSYM VER_SUITE_WH_SERVER}
  PROCESSOR_ARCHITECTURE_AMD64 = 9;
{$EXTERNALSYM PROCESSOR_ARCHITECTURE_AMD64}
  SM_SERVERR2 = 89;
{$EXTERNALSYM SM_SERVERR2}

const
  VER_NT_WORKSTATION = $0000001;
{$EXTERNALSYM VER_NT_WORKSTATION}
  VER_NT_DOMAIN_CONTROLLER = $0000002;
{$EXTERNALSYM VER_NT_DOMAIN_CONTROLLER}
  VER_NT_SERVER = $0000003;
{$EXTERNALSYM VER_NT_SERVER}

{$ENDIF} // TOSVERSIONINFOEX_DEFINED

    function GetOSVersionInfo(var Info: TOSVersionInfoEx): Boolean;
    function GetWindowsSystemType: integer;
    function GetWindowsSystemVersion: Twinver;
    function GetSystemVersion : string;

implementation


function GetWindowsSystemType: integer;
var
  info: TOSVersionInfoEx;
begin
  result := 0;
  if (GetOSVersionInfo(info) = false) then
    exit;
  case info.wProductType of
    VER_NT_WORKSTATION:
      begin
        Result := 1; //非服务器
      end;
    VER_NT_SERVER:
      begin
        Result := 2; //服务器版
      end;
    VER_NT_DOMAIN_CONTROLLER:
      begin
        Result := 2; //域服务器
      end;
  end;
end;

function GetWindowsSystemVersion: Twinver;
var
  info: TOSVersionInfoEx;
  sysInfo: Tsysteminfo;
begin
  Result := WinNone;
  GetSystemInfo(sysInfo); //系统信息
  try
    if (GetOSVersionInfo(info) = false) then
      exit;
    OutputDebugString(PWideChar(IntToStr(info.dwMajorVersion)));
    case info.dwMajorVersion of //主版本
      4:
        begin
          case info.dwMinorVersion of //次版本
            0:
              Result := Win95;
            1:
              Result := Win98;
            9:
              Result := WinMe;
          end;
        end;
      5:
        begin
          case info.dwMinorVersion of
            0:
              begin
                if info.wProductType = VER_NT_WORKSTATION then
                  Result := Win2000
                else
                  Result := WinServer2000;
              end;
            1:
              Result := WinXp;
            2:
              begin
                if ((info.wProductType = VER_NT_WORKSTATION) and (sysInfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64)) then //PROCESSOR_ARCHITECTURE_AMD64
                  Result := WinXp64;
                  //SM_SERVERR2
                if GetSystemMetrics(SM_SERVERR2) = 0 then
                  Result := WinServer2003
                else
                  Result := WinServer2003R2;
                if info.wSuiteMask = VER_SUITE_WH_SERVER then
                  Result := WinHomeServer;
              end;
          end;
        end;
      6:
        begin
          case info.dwMinorVersion of
            0:
              begin
                if info.wProductType = VER_NT_WORKSTATION then
                  Result := WinVista
                else
                  Result := WinServer2008;
              end;
            1:
              begin
                if info.wProductType = VER_NT_WORKSTATION then
                  Result := Win7
                else
                  Result := WinServer2008R2;
              end;
            2:
              begin
                Result := Win8;
              end;
            3:
              begin
                Result := Win8_1;
              end;
          end;
        end;
      10:
        begin
          case info.dwMinorVersion of
            0:
              begin
                Result := Win10;
              end;
          end;
        end;

    end;
  except
    exit;
  end;
end;

function GetSystemVersion : string;
var
  AWin32Version : Extended;
begin
  AWin32Version := StrToFloat(Format('%d.%d',[Win32MajorVersion, Win32MinorVersion]));
  if Win32Platform = VER_PLATFORM_WIN32s then
    Result := 'Windows 32'
    else if Win32Platform=VER_PLATFORM_WIN32_WINDOWS then
    begin
    if AWin32Version=4.0 then
    Result := 'Windows 95'
    else if AWin32Version=4.1 then
    Result := 'Windows 98'
    else if AWin32Version=4.9 then
    Result := 'Windows Me'
    else
    Result := 'Windows 9x'
    end
    else if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
    if AWin32Version=3.51 then
      Result := 'Windows NT 3.51'
      else if AWin32Version=4.0 then
        Result := 'Windows NT 4.0'
        else if AWin32Version=5.0 then
          Result := 'Windows 2000'
          else if AWin32Version=5.1 then
            Result := 'Windows Xp'
            else if AWin32Version=5.2 then
              Result := 'Windows 2003'
              else if AWin32Version=6.1 then
                Result := 'Windows7'
                else if AWin32Version=10.0 then
                  Result := 'Windows10';
    end
    // else if Win32Platform = VER_PLATFORM_WIN32_CE then
    // Result := 'Windows CE'
    else
    Result := 'Windows ??';
end;

function GetOSVersionInfo(var Info: TOSVersionInfoEx): Boolean;
begin
  FillChar(Info, SizeOf(TOSVersionInfoEx), 0);
  Info.dwOSVersionInfoSize := SizeOf(TOSVersionInfoEx);
  Result := GetVersionEx(TOSVersionInfo(Addr(Info)^));
  if (not Result) then
    Info.dwOSVersionInfoSize := 0;
end;


end.
