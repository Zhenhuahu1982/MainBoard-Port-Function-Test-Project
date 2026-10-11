unit Lan;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,Winapi.Nb30,
  System.Win.Registry,IdIcmpClient;

  function NBGetAdapterAddress(a: integer): string; stdcall;
  function GetMacAddr(MAC_Addr: string; Num : Integer): String; stdcall; export;
  function NetConnectTest(Server_IP: string;Num : Integer):Boolean; stdcall; export;
  procedure SetEnvPath(Conns: String; sValue : String); stdcall; export;
  function RunProgram(ProgramName: String; Wait:Boolean=False):Cardinal; stdcall;
  function IsProgram_Runing(hProcess:Cardinal):Boolean; stdcall;
  function PingLan(IP: string):Boolean;stdcall; export;

implementation


//------------------获取本机MAC地址-------------------//
function NBGetAdapterAddress(a: integer): string; stdcall;
var
  NC: TNCB;
  ADAPTE: TADAPTERSTATUS;
  LANAENU: TLANAENUM;
  intId: integer;
  cR: Char;
  strTem: string;
begin
  Result := '';
  try
    ZeroMemory(@NC, SizeOf(NC));
    NC.ncb_command := Chr(NCBENUM);
    cR := WideChar(NetBios(@NC));
    // Reissue enum command
    NC.ncb_buffer := @LANAENU;
    NC.ncb_length := SizeOf(LANAENU);
    cR := WideChar(NetBios(@NC));
    if Ord(cR) <> 0 then
      exit;
    ZeroMemory(@NC, SizeOf(NC));
    NC.ncb_command := Chr(NCBRESET);
    NC.ncb_lana_num := LANAENU.lana[a];
    cR := WideChar(NetBios(@NC));
    if Ord(cR) <> 0 then
      exit;
    ZeroMemory(@NC, SizeOf(NC));
    NC.ncb_command := Chr(NCBASTAT);
    NC.ncb_lana_num := LANAENU.lana[a];
    StrPCopy(NC.ncb_callname, '*');
    NC.ncb_buffer := @ADAPTE;
    NC.ncb_length := SizeOf(ADAPTE);
    cR := WideChar(NetBios(@NC));
    strTem := '';
    for intId := 0 to 5 do
      strTem := strTem + InttoHex(integer(ADAPTE.adapter_address[intId]), 2);
    Result := strTem;
  finally

  end;
end;

function GetMacAddr(MAC_Addr: string; Num : Integer): string; stdcall; export;
var
  mac1 : string;
begin
   Result := '';
   try
      mac1 := NBGetAdapterAddress(1);
      if Copy(mac1,0,6) = MAC_Addr then Result := mac1
          else Result := '';
    except on E:Exception do
       //ShowMessage(E.Message);
       Result := '';
    end;
      Application.ProcessMessages;
end;

function GetMacAddress:string;
var
lib:Cardinal;
Func: function(GUID:PGUID):Longint;stdcall;
GUID1,GUID2:TGUID;
begin
 Result :='';
 Lib := Loadlibrary('rpcrt4.dll');
 if Lib <> 0 then
  begin
   if Win32Platform <> VER_PLATFORM_WIN32_NT then
    @Func := GetProcAddress(lib,'UuidCreate')
   else @Func := GetProcAddress(lib,'UuidCreateSequential');
   if Assigned(Func) then
     begin
       if (Func(@GUID1)=0) and (Func(@GUID2)=0) and
       (GUID1.D4[2] = GUID2.D4[2]) and
       (GUID1.D4[3] = GUID2.D4[3]) and
       (GUID1.D4[4] = GUID2.D4[4]) and
       (GUID1.D4[5] = GUID2.D4[5]) and
       (GUID1.D4[6] = GUID2.D4[6]) and
       (GUID1.D4[7] = GUID2.D4[7]) then
        begin
          result := IntToHex(GUID1.D4[2],2) +
          IntToHex(GUID1.D4[3],2) +
          IntToHex(GUID1.D4[4],2) +
          IntToHex(GUID1.D4[5],2) +
          IntToHex(GUID1.D4[6],2) +
          IntToHex(GUID1.D4[7],2);
        end;
     end;
  FreeLibrary(Lib);
  end;
end;

function PingLan(IP: string):Boolean; stdcall; export;
var
  id : TIdIcmpClient;
  j,k : Integer;
begin
  Result := False;
  j :=0;	//记录Ping的总次数
  k :=0;	//执行Ping操作
  id := TIdIcmpClient.Create(nil);
  try
       id.ReceiveTimeout := 1000;
       id.Host := IP;
       try
        while (j < 10) and (k = 0) do
        begin
          //Application.ProcessMessages;
          j := j + 1;
         id.Ping();
         if (id.ReplyStatus.FromIpAddress <> '0.0.0.0') and (id.ReplyStatus.FromIpAddress <> '')
             and (id.ReplyStatus.BytesReceived > 3) and (id.ReplyStatus.TimeToLive > 0) then
             Result := True
             else
             begin
               k := 1;
               Result := False;
             end;
        end;
       except on E:Exception do
         ShowMessage(E.Message);
       end;
    finally
      id.Free;
    end;
end;

function NetConnectTest(Server_IP: string;  Num : Integer):Boolean; stdcall; export;
var
  FileName1,FileName2,FileName3,FileName4,FileName5 : string;
begin
  Result := False;
  if Num = 2 then
  begin
    FileName1 := ExtractFilePath(ParamStr(0)) + 'LanErr.Txt';    //打开和禁用网络记录错误信息
    FileName2 := ExtractFilePath(ParamStr(0)) + 'ELan.exe';      //打开网络连接1
    FileName3 := ExtractFilePath(ParamStr(0)) + 'DLan.exe';      // 禁用网络连接1
    FileName4 := ExtractFilePath(ParamStr(0)) + 'ELan1.exe';      //打开网络连接2
    FileName5 := ExtractFilePath(ParamStr(0)) + 'Dlan1.exe';      //禁用网络连接2
    if RunProgram(FileName2,True) = 0 then Exit;        //先打开网络1
    if RunProgram(FileName5,True) = 0 then Exit;      //关闭网络2
    if FileExists(FileName1) then Exit;            //如果出现错误，则不再执行
    if not PingLan(Server_IP) then Exit;           //测试网络连接1
    if RunProgram(FileName3,True) = 0 then Exit;
    if RunProgram(FileName4,True) = 0 then Exit;
    if FileExists(FileName1) then Exit;            //如果出现错误，则不再执行
    if not PingLan(Server_IP) then Exit;
    RunProgram(FileName2,False);
    RunProgram(FileName4,False);
    if not FileExists(FileName1) then
      begin
        Result := True;
      end
      else Result := False;
  end;

end;

procedure SetEnvPath(Conns: String; sValue : String); stdcall; export;
var
  reg : TRegistry;
  sLMKey : string;
  sCurStr : string;
  sStrToAdd: string;
  sName : String;

begin
  sLMKey := '\System\CurrentControlSet\Control\Session Manager\Environment';  //环境变量保存在注册表的这个位置
  sName := Conns; //我们要修改的是Path环境变量
  sStrToAdd := sValue; //要添加的环境变量
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if reg.OpenKey(sLMKey,False) then
    begin
      sCurStr := reg.ReadString(sName); //读取环境变量
      sCurStr := Trim(sCurStr);
      sStrToAdd := Trim(sStrToAdd);
      if Pos(sStrToAdd,sCurStr) = 0 then  //判断此环境变量是否已经存在
      begin
        //sCurStr := sCurStr + sStrToAdd;  //把'C:/Ora_Cli/bin'这个值加入到环境变量的最后

        {网上看到的方法都是用WriteString这个函数来写Path环境变量， 可是我用了就有问题
         用了这个函数后，系统对%systemroot%,这带%的变量就不翻译了，有很多命令如ping就不能用了，
         会说ping不是可执行命令等等，后来经高手提醒说：用WriteExpandString就没问题了。
         看了Delphi的帮助，有这么一句：
         Call WriteExpandString to store a string that contains unexpanded references to environment variables such as %PATH%
        }
        //reg.WriteString(sName,sCurStr);   //用这句就有问题
        reg.WriteExpandString(sName,sStrToAdd);  //把值写到注册表里
        reg.CloseKey;
        SetEnvironmentVariable(PChar(sName),PChar(sCurStr));//更新当前进程的环境变量
        SendMessage(HWND_BROADCAST,WM_SETTINGCHANGE,0,Integer(PChar('Environment'))); //通知所有上层窗口，环境参数变化
        //ShowMessage('设置成功');
      end;
    end;
  except
    on E: Exception do
    begin
      reg.Free;
      ShowMessage('Error: ' + E.Message);
      Exit;
    end;
  end;
  reg.Free;
end;

function RunProgram(ProgramName: String; Wait:Boolean=False):Cardinal;
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
function IsProgram_Runing(hProcess:Cardinal):Boolean;
var
	ExitCode: Cardinal;
begin
	GetExitCodeProcess(hProcess,ExitCode);
	Result := ExitCode =STILL_ACTIVE;
end;

end.
