unit Lan_bak;

interface

uses
  Winapi.ShellAPI, System.Classes, Winapi.Windows, Winapi.Messages, System.IniFiles,
  System.SysUtils, Vcl.Dialogs, Vcl.Graphics, Vcl.Forms, System.StrUtils, Winapi.Nb30,
  System.Win.Registry, IdIcmpClient, IdTime;

  function NBGetAdapterAddress(a: integer): string;
  function GetMacAddr1(MAC_Addr : string) : Boolean;
  function GetMacAddr(MAC_Addr : string) : Boolean;
  procedure NetConnectTest(aNicName,sNicName : string; MAC_Addr: string; Server_IP: string; Speed1,Speed2: Integer; Num : Integer; Over_Time : Word);overload;stdcall;
  procedure NetConnectTest(NicName : string; MAC_Addr: string; Server_IP: string; SPEED: Integer);overload;stdcall;
  procedure SetEnvPath(Conns: String; sValue : String);
  function PingLan(IP: string ) : Boolean;
  procedure SPEED_CONN(NicName: string; Speed : Integer);
  procedure ICMPReply(ASender: TComponent; const ReplyStatus: TReplyStatus);

  const
  MAX_HOSTNAME_LEN = 128; { from IPTYPES.H }
  MAX_DOMAIN_NAME_LEN = 128;
  MAX_SCOPE_ID_LEN = 256;
  MAX_ADAPTER_NAME_LENGTH = 256;
  MAX_ADAPTER_DESCRIPTION_LENGTH = 128;
  MAX_ADAPTER_ADDRESS_LENGTH = 8;

type
  TIPAddressString = array[0..4 * 4 - 1] of AnsiChar;
  PIPAddrString = ^TIPAddrString;
  TIPAddrString = record
  Next: PIPAddrString;
  IPAddress: TIPAddressString;
  IPMask: TIPAddressString;
  Context: Integer;
end;

PFixedInfo = ^TFixedInfo;
TFixedInfo = record { FIXED_INFO }
  HostName: array[0..MAX_HOSTNAME_LEN + 3] of AnsiChar;
  DomainName: array[0..MAX_DOMAIN_NAME_LEN + 3] of AnsiChar;
  CurrentDNSServer: PIPAddrString;
  DNSServerList: TIPAddrString;
  NodeType: Integer;
  ScopeId: array[0..MAX_SCOPE_ID_LEN + 3] of AnsiChar;
  EnableRouting: Integer;
  EnableProxy: Integer;
  EnableDNS: Integer;
end;

PIPAdapterInfo = ^TIPAdapterInfo;
TIPAdapterInfo = record { IP_ADAPTER_INFO }
  Next: PIPAdapterInfo;
  ComboIndex: Integer;
  AdapterName: array[0..MAX_ADAPTER_NAME_LENGTH + 3] of AnsiChar;
  Description: array[0..MAX_ADAPTER_DESCRIPTION_LENGTH + 3] of AnsiChar;
  AddressLength: Integer;
  Address: array[1..MAX_ADAPTER_ADDRESS_LENGTH] of Byte;
  Index: Integer;
  _Type: Integer;
  DHCPEnabled: Integer;
  CurrentIPAddress: PIPAddrString;
  IPAddressList: TIPAddrString;
  GatewayList: TIPAddrString;
  DHCPServer: TIPAddrString;
  HaveWINS: Bool;
  PrimaryWINSServer: TIPAddrString;
  SecondaryWINSServer: TIPAddrString;
  LeaseObtained: Integer;
  LeaseExpires: Integer;
end;

TAdapterInfo = class(TObject)
  Index: Integer; //序号
  AdapterName: string; //网卡名
  IPAddress: string; //IP地址
  Subnetmask: string; //子网掩码
  Gateway: string; //网关
  MacAddress: string; //MAC地址
  DHCP: Boolean; //是否是自动分配
  DHCPServer: string; //DHCP服务器地址
end;

function SendARP(ipaddr: ulong; temp: dword; ulmacaddr: pointer;
ulmacaddrleng: pointer): DWord; StdCall;

function GetAdapterInfo: TList;

var
AI, Work: PIPAdapterInfo;
Size: Integer;
Res: Integer;
n: Integer;

implementation

uses
  Test_Project_Demo1,RunPg,Show_MAC;

var
  Lan_Result : Integer;
  mac1 : string;

function SendARP; external 'Iphlpapi.dll' Name 'SendARP';

function GetAdaptersInfo(AI: PIPAdapterInfo; var BufLen: Integer): Integer;
stdcall; external 'iphlpapi.dll' Name 'GetAdaptersInfo';

function MACToStr(ByteArr: PByte; Len: Integer): string;
begin
  Result := '';
  while (Len > 0) do
  begin
       Result := Result + IntToHex(ByteArr^, 2) + '-';
       ByteArr := Pointer(Integer(ByteArr) + SizeOf(Byte));
       Dec(Len);
  end;
  SetLength(Result, Length(Result) - 1); { remove last dash }
end;

function GetAddrString(Addr: PIPAddrString): string;
begin
  Result := '';
  while (Addr <> nil) do
  begin
       Result := Result + 'A: ' + Addr^.IPAddress + ' M: ' + Addr^.IPMask + #13;
       Addr := Addr^.Next;
  end;
end;

function TimeTToDateTimeStr(TimeT: Integer): string;
const
     UnixDateDelta = 25569; { days between 12/31/1899 and 1/1/1970 }
var
   DT: TDateTime;
   TZ: TTimeZoneInformation;
   Res: DWord;
begin
  if (TimeT = 0) then
     Result := ''
  else
  begin
  { Unix TIME_T is secs since 1/1/1970 }
    DT := UnixDateDelta + (TimeT / (24 * 60 * 60)); { in UTC }
  { calculate bias }
    Res := GetTimeZoneInformation(TZ);
  if (Res = TIME_ZONE_ID_INVALID) then
      RaiseLastOSError;
  if (Res = TIME_ZONE_ID_STANDARD) then
  begin
     DT := DT - ((TZ.Bias + TZ.StandardBias) / (24 * 60));
     Result := DateTimeToStr(DT) + ' ' + WideCharToString(TZ.StandardName);
  end
  else
  begin { daylight saving time }
     DT := DT - ((TZ.Bias + TZ.DaylightBias) / (24 * 60));
     Result := DateTimeToStr(DT) + ' ' + WideCharToString(TZ.DaylightName);
  end;
  end;
end;

function GetAdapterInfo: TList;
var
   AAdapterInfo: TAdapterInfo;
   AAdapterInfos: TList;
begin
    Size := 5120;
    GetMem(AI, Size);
    Res := GetAdaptersInfo(AI, Size);
    if (Res <> ERROR_SUCCESS) then
    begin
        SetLastError(Res);
        RaiseLastOSError;
    end;
    Work := AI;
    n := 1;
    AAdapterInfos := TList.Create;
    repeat
        AAdapterInfo := TAdapterInfo.Create;
        AAdapterInfo.Index := n;
        AAdapterInfo.AdapterName := Work^.Description;
        AAdapterInfo.IPAddress := Copy(GetAddrString(@Work^.IPAddressList),
        Pos('A: ', GetAddrString(@Work^.IPAddressList)) + 3, Pos(' M: ',
        GetAddrString(@Work^.IPAddressList)) - Pos('A: ',
        GetAddrString(@Work^.IPAddressList)) - 3);
        AAdapterInfo.Subnetmask := Copy(GetAddrString(@Work^.IPAddressList),
        Pos(' M: ', GetAddrString(@Work^.IPAddressList)) + 4,
        length(GetAddrString(@Work^.IPAddressList)));
        AAdapterInfo.Gateway := Copy(GetAddrString(@Work^.GatewayList), Pos('A: ',
        GetAddrString(@Work^.GatewayList)) + 3, Pos(' M: ',
        GetAddrString(@Work^.GatewayList)) - Pos('A: ',
        GetAddrString(@Work^.GatewayList)) - 3);
        AAdapterInfo.MacAddress := MACToStr(@Work^.Address, Work^.AddressLength);
        AAdapterInfo.DHCP := Work^.DHCPEnabled > 0;
        AAdapterInfo.DHCPServer := Copy(GetAddrString(@Work^.DHCPServer), Pos('A: ',
        GetAddrString(@Work^.DHCPServer)) + 3, Pos(' M: ',
        GetAddrString(@Work^.DHCPServer)) - Pos('A: ',
        GetAddrString(@Work^.DHCPServer)) - 3);
        AAdapterInfos.Add(AAdapterInfo);
        Inc(n);
        Work := Work^.Next;
    until (Work = nil);
    Result :=AAdapterInfos;
    FreeMem(AI);
    AAdapterInfos.Free;
end;

//------------------获取本机MAC地址-------------------//
function NBGetAdapterAddress(a: integer): string;
var
  NETCard: TNCB;
  ADAPTE: TADAPTERSTATUS;
  LANAENU: TLANAENUM;
  intId: integer;
  cR: Char;
  strTem: string;
begin
  Result := '';
  try
    ZeroMemory(@NETCard, SizeOf(NETCard));
    NETCard.ncb_command := Chr(NCBENUM);
    cR := WideChar(NetBios(@NETCard));
    NETCard.ncb_buffer := @LANAENU;
    NETCard.ncb_length := SizeOf(LANAENU);
    cR := WideChar(NetBios(@NETCard));
    if Ord(cR) <> 0 then
      exit;
    ZeroMemory(@NETCard, SizeOf(NETCard));
    NETCard.ncb_command := Chr(NCBRESET);
    NETCard.ncb_lana_num := LANAENU.lana[a];
    cR := WideChar(NetBios(@NETCard));
    if Ord(cR) <> 0 then
      exit;
    ZeroMemory(@NETCard, SizeOf(NETCard));
    NETCard.ncb_command := Chr(NCBASTAT);
    NETCard.ncb_lana_num := LANAENU.lana[a];
    StrPCopy(NETCard.ncb_callname, '*');
    NETCard.ncb_buffer := @ADAPTE;
    NETCard.ncb_length := SizeOf(ADAPTE);
    cR := WideChar(NetBios(@NETCard));
    strTem := '';
    for intId := 0 to 5 do
      strTem := strTem + InttoHex(integer(ADAPTE.adapter_address[intId]), 2);
    Result := strTem;
  finally

  end;
end;

//双网卡测试
function GetMacAddr(MAC_Addr: string) : boolean;
var
  i,j,Ln : Integer;
  aList : TList;
begin
   Result := False;
   i := 0;
   aList := TList.Create;
   try
      aList := GetAdapterInfo;
      for Ln := 0 to aList.Count - 1 do
      begin
        Inc(i);
        mac1 := NBGetAdapterAddress(Ln);
        if LeftStr(mac1,6) = MAC_Addr then begin
            with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  'MAC地址测试';
                           Cells[1,j] := 'MAC地址: ' + mac1;
                           Cells[2,j] := 'PASS';
                           Cells[3,j] := '设置前缀: ' + MAC_Addr;
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
              Result := True;
              Exit;
        end
        else if i >= aList.Count then
          begin
           with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  'MAC地址测试';
                           Cells[1,j] := 'MAC地址: ' + mac1;
                           Cells[2,j] := 'FAIL';
                           Cells[3,j] := '设置前缀: ' + MAC_Addr;
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
              Result := False;
              Exit;
          end;
      end;
   except on E:Exception do  begin
       //MessageBox(0,PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
       //RaiseLastOSError;
       Result := False;

     end;
   end;
   aList.Free;
end;


//单网卡测试
function GetMacAddr1(MAC_Addr: string):Boolean;
var
  mac1 : string;
  i,j : Integer;
begin
   try
      Sleep(1000);
      Result := False;
      for i := 0 to 4 do
      begin
          mac1 := NBGetAdapterAddress(0);
          if LeftStr(mac1,6) = MAC_Addr then
          begin
            with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  'MAC地址测试';
                           Cells[1,j] := 'MAC地址: ' + mac1;
                           Cells[2,j] := 'PASS';
                           Cells[3,j] := '设置前缀: ' + MAC_Addr;
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
              Test_Project_Demo1.Form2.mac1_temp := mac1;
              Result := True;
              Exit;
          end
          else if i >= 4 then
          begin
           with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  'MAC地址测试';
                           Cells[1,j] := 'MAC地址: ' + mac1;
                           Cells[2,j] := 'FAIL';
                           Cells[3,j] := '设置前缀: ' + MAC_Addr;
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
              Result := False;
          end;
      end;
   except on E:Exception do
     //MessageBox(0,PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
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


function PingLan(IP: string ): boolean;
var
  id : TIdIcmpClient;
  i,j,k : Integer;
begin
  Result := False;
  i :=0;	//标记掉包数量
  k :=0;	//执行Ping操作
  id := TIdIcmpClient.Create(nil);
  try
       id.ReceiveTimeout := 1000;
       id.Host := IP;
       try
        while (i < 10) and (k = 0) do
        begin
            //Application.ProcessMessages;
            Inc(i);
           id.Ping;
           Application.ProcessMessages;
           //if (id.ReplyStatus.FromIpAddress <> '0.0.0.0') and (id.ReplyStatus.FromIpAddress <> '')
           //    and (id.ReplyStatus.BytesReceived > 0) and (id.ReplyStatus.TimeToLive > 0) then
           if id.ReplyStatus.ReplyStatusType = rsEcho then begin
              Lan_Result := 0;
              k := 0;
           end
           else
           begin
             k := 1;
           end;
        end;
          if Lan_Result = 1 then begin
             with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  '数据传输测试';
                           Cells[1,j] := '网络数据传输测试';
                           Cells[2,j] := 'FAIL';
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                           //Exit;
                      end;
                  end;
              end;
              Result := False;
          end
          else
          begin
            with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  '数据传输测试';
                           Cells[1,j] := '网络数据传输测试';
                           Cells[2,j] := 'PASS';
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                           //Exit;
                      end;
                  end;
              end;
              Result := True;
          end;
       except on E:Exception do
         //MessageBox(0,PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
         //ShowMessage(E.GetBaseException.ToString);
       end;
    finally
      id.Free;
    end;
end;


//单网卡测试
procedure NetConnectTest(NicName : string; MAC_ADDR: string; Server_IP: string; SPEED: Integer);
begin
    if GetMacAddr1(MAC_ADDR) then    //如果MAC 测试PASS，则继续执行网络数据传输，测试网络连接速度
    begin
        Test_Project_Demo1.Form2.LanMac_Result := 'PASS';
        if PingLan(Server_IP) then
            Test_Project_Demo1.Form2.Lansend_Result := 'PASS'
        else
            Test_Project_Demo1.Form2.Lansend_Result := 'FAIL';
        SPEED_CONN(NicName, SPEED);
    end
    else
    begin
        Test_Project_Demo1.Form2.LanMac_Result := 'FAIL';
        Test_Project_Demo1.Form2.mac1_temp := mac1;
    end;

end;

//双网卡测试，用于自动测试
procedure NetConnectTest(aNicName,sNicName: string; MAC_ADDR: string; Server_IP: string; Speed1,Speed2 : Integer; Num : Integer; Over_Time : Word);
var
  pa1,pa2,pa3,pa4,pa5 : string;
  j : Integer;
begin
  try
    pa1 := ' "' + aNicName + '" "enable"';
    pa2 := ' "' + sNicName + '" "enable"';
    pa3 := ' "' + aNicName + '" "' + sNicName + '" "enable"';
    pa4 := ' "' + aNicName + '" "disable"';
    pa5 := ' "' + sNicName + '" "disable"';
    
    //测试网络1，先关闭网络连接2
    //if RunProgram(FileName5,True) = 0 then Exit;        //关闭网络2
    //if RunProgram(FileName2,True) = 0 then Exit;      //打开网络1
    ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(pa1),PChar(ExtractFilePath(ParamStr(0))),0);
    ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(pa5),PChar(ExtractFilePath(ParamStr(0))),0);
    Sleep(2000);
    if GetMacAddr1(MAC_ADDR) then
        Test_Project_Demo1.Form2.LanMAC_Result := 'PASS'
        else
          Test_Project_Demo1.Form2.LanMAC_Result := 'FAIL';
      if PingLan(Server_IP) then
            Test_Project_Demo1.Form2.Lansend_Result := 'PASS'
      else
        Test_Project_Demo1.Form2.Lansend_Result := 'FAIL';
      SPEED_CONN(aNicName,Speed1);

    //测试网络2，关闭网络连接1
    ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(pa2),PChar(ExtractFilePath(ParamStr(0))),0);
    ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(pa4),PChar(ExtractFilePath(ParamStr(0))),0);
    Sleep(Over_Time);
    if GetMacAddr1(MAC_ADDR) then
        Test_Project_Demo1.Form2.LanMAC1_Result := 'PASS'
        else
          Test_Project_Demo1.Form2.LanMAC1_Result := 'FAIL';
    if PingLan(Server_IP) then
            Test_Project_Demo1.Form2.Lansend1_Result := 'PASS'
    else
            Test_Project_Demo1.Form2.Lansend1_Result := 'FAIL';
    SPEED_CONN(sNicName,Speed2);

  finally
    ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(pa1),PChar(ExtractFilePath(ParamStr(0))),0);
    ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(pa2),PChar(ExtractFilePath(ParamStr(0))),0);
    Sleep(2000);
  end;

end;

procedure SPEED_CONN(NicName: string; Speed : Integer);
var
  FileName : String;
  List : TStringList;
  i,j : Integer;
  str1 : string;
  Ccode : Cardinal;
begin
  List := TStringList.Create;
  FileName := ExtractFilePath(ParamStr(0)) + 'lspeed.txt';
  str1 := ' "' + NicName + '"';
  try
      Ccode := ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(str1),PChar(ExtractFilePath(ParamStr(0))),0);
      Sleep(2000);
      if FileExists(FileName) then
      begin
        List.LoadFromFile(FileName);
        for I := 0 to List.Count - 1 do
        begin
            if (Trim(List[i]) <> '') then
            begin
                if StrToInt(Trim(List[i])) = Speed then
                begin
                  with Test_Project_Demo1.Form2.RzStringGrid1 do
                  begin
                      for j := 0 to RowCount - 1 do
                      begin
                        if Cells[0,j] = '' then
                        begin
                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                             Cells[0,j] :=  '网络速度测试';
                             Cells[1,j] := '网络速度测试: ' + Trim(List[i]) + 'Mb';
                             Cells[2,j] := 'PASS';
                             Cells[3,j] := '设置速度: ' + IntToStr(Speed) +'Mb';
                             RowCount := RowCount + 1;
                             Row := Row + 1;
                             Update;
                        end;
                      end;
                  end;
                  Test_Project_Demo1.Form2.LanSpeed_Result := 'PASS';
                end
                else
                begin
                  with Test_Project_Demo1.Form2.RzStringGrid1 do
                  begin
                      for j := 0 to RowCount - 1 do
                      begin
                          if Cells[0,j] = '' then
                          begin
                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                               Cells[0,j] :=  '网络速度测试';
                               Cells[1,j] := '网络速度测试: ' + Trim(List[i]) + 'Mb';
                               Cells[2,j] := 'FAIL';
                               Cells[3,j] := '设置速度: ' + IntToStr(Speed) + 'Mb';
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                      end;
                  end;
                  Test_Project_Demo1.Form2.LanSpeed_Result := 'FAIL';
                end;
            end;
        end;
      end;
  finally
    List.Destroy;
    if FileExists(FileName) then DeleteFile(FileName);
    //if FileExists(FileName1) then DeleteFile(FileName1);

  end;

end;

procedure ICMPReply(ASender: TComponent; const ReplyStatus: TReplyStatus);
var
 sTime : string;
begin
if (ReplyStatus.MsRoundTripTime = 0) then
    sTime := '<1'
  else
    sTime := '=';

    {ListBox1.Items.Add(Format('%d bytes from %s: icmp_seq=%d ttl=%d time%s%d ms',
    [ReplyStatus.BytesReceived,
    ReplyStatus.FromIpAddress,
    ReplyStatus.SequenceId,
    ReplyStatus.TimeToLive,
    sTime,
    ReplyStatus.MsRoundTripTime]));}
end;

procedure SetEnvPath(Conns: String; sValue : String);
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
      //if Pos(sStrToAdd,sCurStr) = 0 then  //判断此环境变量是否已经存在
      //begin
        sCurStr := sCurStr + sStrToAdd;  //把'C:/Ora_Cli/bin'这个值加入到环境变量的最后
        //MessageBox(0,PChar(sStrToAdd),PChar(sCurStr+'的值'),MB_OK);
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
    //end;
    end;
  except
    on E: Exception do
    begin
      reg.Free;
      MessageBox(0,PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
      Exit;
    end;
  end;
  reg.Free;
end;

end.
