unit Lan;

interface

uses
  Winapi.ShellAPI, System.Classes, Winapi.Windows, Winapi.Messages, System.IniFiles,
  System.SysUtils, Vcl.Dialogs, Vcl.Graphics, Vcl.Forms, System.StrUtils, Winapi.Nb30,
  System.Win.Registry, IdIcmpClient, IdTime, Winapi.ShlObj, System.Win.ComObj,
  Winapi.ActiveX, System.Variants, Show_MAC, Winapi.IpHlpApi, Winapi.IpTypes,
  Winapi.Winsock2, uIperfClient, uIperfCommon, uIperfClientApi, System.RegularExpressions;

  function NBGetAdapterAddress(a: integer): string;
  function GetMacAddr1(MAC,MAC_ADDR : String; Flag : Integer) : Boolean;
  function GetMacAddr(MAC_Addr : string; const MAC_Addr1 : string = 'ECD68A') : Boolean;
  procedure NetConnectTest(PCBA_Type: Integer; MAC_Addr: string; Server_IP: string; Speed1,Speed2: Integer; Num : Integer; Over_Time : Word; Server : Word);overload;stdcall;
  procedure NetConnectTest(NicName : string; MAC_Addr: string; Server_IP: string; SPEED: Integer);overload;stdcall;
  procedure SetEnvPath(Conns: String; sValue : String);
  procedure PingLan(IP: string );
  function SPEED_CONN(NicName: string; Speed : Integer):Boolean;
  procedure ICMPReply(ASender: TComponent; const ReplyStatus: TReplyStatus);
  function GetWMIProperty(WMIType, WMIProperty:AnsiString):String;
  function GetWMISub(WMIType,WMIProperty,WMISearch,WMISearchText:String):String;
  function InsertBlank(MAC_Addr: string):String;       // 在MACID 字串中加入“:”
  function GetLanPNPDeviceID(macid:string; lNum : Integer):Integer;    // 返回网络连接名称
  function RemoveChar(const Source, CharToRemove: string): string;
  function DeleteBlank(MAC_Addr: string):String;
  procedure RTime;

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
  wList1,PList1 : TStringList;
  Lan_Info : string;

implementation

uses
  Test_Project_Demo1,RunPg;

var
  Lan_Result : Integer = 0;
  mac1 : string;
  Num_Lan : array[0..3] of Word;

// 手动定义必要的常量
const
  IF_TYPE_SOFTWARE_LOOPBACK = 24;
  GAA_FLAG_INCLUDE_ALL_INTERFACES = $00000080;
  IF_TYPE_TUNNEL = 131;




function GetMACAddresses: TStringList;
var
  pAdapter, pAdapterAddresses: PIpAdapterAddresses;
  BufLen: ULONG;
  Ret: DWORD;
  i: Integer;
  MacStr: string;
begin
  Result := TStringList.Create;
  BufLen := 0;

  // 第一次调用获取缓冲区大小
  Ret := GetAdaptersAddresses(AF_UNSPEC, GAA_FLAG_INCLUDE_ALL_INTERFACES,
                             nil, nil, @BufLen);
  if Ret <> ERROR_BUFFER_OVERFLOW then Exit;

  GetMem(pAdapterAddresses, BufLen);
  try
    Ret := GetAdaptersAddresses(AF_UNSPEC, GAA_FLAG_INCLUDE_ALL_INTERFACES,
                               nil, pAdapterAddresses, @BufLen);
    if Ret <> ERROR_SUCCESS then Exit;

    pAdapter := pAdapterAddresses;
    while pAdapter <> nil do
    begin
      if (pAdapter.OperStatus = IfOperStatusUp)and(pAdapter.PhysicalAddressLength > 0) and
         (pAdapter.IfType <> IF_TYPE_TUNNEL) and (pAdapter.IfType <> IF_TYPE_SOFTWARE_LOOPBACK) then
      begin
        MacStr := '';
        for i := 0 to pAdapter.PhysicalAddressLength - 1 do
        begin
          //if i > 0 then MacStr := MacStr + '-'; // 使用连字符分隔
          MacStr := MacStr + Format('%.2X', [pAdapter.PhysicalAddress[i]]);
        end;

        Result.Add(Format('%s=%s', [
          string(pAdapter.FriendlyName), // 使用 Description 代替 FriendlyName
          MacStr
        ]));
      end;
      pAdapter := pAdapter.Next;
    end;
  finally
    FreeMem(pAdapterAddresses);
  end;
end;

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

//单网卡测试
function GetMacAddr(MAC_Addr: string; const MAC_Addr1: string = 'ECD68A') : boolean;
var
  i,j,Ln,Total : Integer;
  Temp, Temp1,str1 : string;
begin
   Result := False;
   Ln := 0;
   Total := Test_Project_Demo1.mList1.Count;

  // MessageBox(0,PChar( MAC_Addr ),PChar('测试号码'), MB_OK + MB_ICONSTOP);
   try
      if Total > 0 then          // 测试时要扫码才需要
      begin
          for i := 0 to Total - 1 do
          begin
                Temp := Test_Project_Demo1.mList1[i];
                if (MAC_Addr = Temp) then
                begin
                     with Test_Project_Demo1.Form2.RzStringGrid1 do
                      begin
                          for j := 0 to RowCount - 1 do
                          begin
                              if Cells[0,j] = '' then
                              begin
                                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                                   Cells[0,j] :=  'MAC地址测试';
                                   Cells[1,j] := 'MAC地址: ' + MAC_Addr;
                                   Cells[2,j] := 'PASS';
                                   Cells[3,j] := '测试号码: ' + Temp;
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                          end;
                      end;
                      Lan_Info := Temp;
                      Result := True;
                      Exit;
                end;
                  Inc(Ln);
                  if (SameText(Trim(Temp),Trim(MAC_Addr)) = false) and (SameText(Trim(Temp),Trim(Lan_Info)) = false) then
                  begin
                   str1 :=  Temp;
                  end;
            if Ln >= Total then
            begin
             with Test_Project_Demo1.Form2.RzStringGrid1 do
                begin
                    for j := 0 to RowCount - 1 do
                    begin
                        if Cells[0,j] = '' then
                        begin
                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                             Cells[0,j] :=  'MAC地址测试';
                             Cells[1,j] := 'MAC地址: ' + MAC_Addr;
                             Cells[2,j] := 'FAIL';
                             Cells[3,j] := '测试号码: ' + str1;
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
      end
      else if (LeftStr(MAC_Addr,6) = MAC_Addr1) then
      begin
        with Test_Project_Demo1.Form2.RzStringGrid1 do
          begin
              for j := 0 to RowCount - 1 do
              begin
                  if Cells[0,j] = '' then
                  begin
                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                       Cells[0,j] :=  'MAC地址测试';
                       Cells[1,j] := 'MAC地址: ' + MAC_Addr;
                       Cells[2,j] := 'PASS';
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
              end;
          end;
          Result := True;
          Exit;
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
                         Cells[0,j] :=  'MAC地址测试';
                         Cells[1,j] := 'MAC地址: ' + MAC_Addr;
                         Cells[2,j] := 'FAIL';
                         Cells[3,j] := '测试号码: ' + str1;
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                end;
            end;
            Result := False;
           Exit;
      end;
   except on E:Exception do  begin
       //MessageBox(0,PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
       //RaiseLastOSError;
       Temp := '';
       Result := False;

     end;
   end;
end;


//单网卡测试
function GetMacAddr1(MAC, MAC_ADDR: String; Flag : Integer):Boolean;
var
  mac1 : string;
  i,j : Integer;
begin
   try
      Result := False;
      if Flag = 1 then
      begin
          if CompareText(MAC,MAC_ADDR) = 0 then
           begin

            with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  'MAC地址测试';
                           Cells[1,j] := 'MAC地址: ' + MAC;
                           Cells[2,j] := 'PASS';
                           Cells[3,j] := '设置号码: ' + MAC_Addr;
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
              //Test_Project_Demo1.Form2.mac1_temp := mac1;
              Result := True;
              Exit;
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
                           Cells[0,j] :=  'MAC地址测试';
                           Cells[1,j] := 'MAC地址: ' + MAC;
                           Cells[2,j] := 'FAIL';
                           Cells[3,j] := '设置号码: ' + MAC_Addr;
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
             // Test_Project_Demo1.Form2.mac1_temp := mac1;
              Result := False;
              Exit;
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

procedure RTime;
var
  rNowTime, rOkTime : Integer;
begin
  rOkTime := GetTickCount();
  repeat
    Application.ProcessMessages;
    rNowTime := GetTickCount();
  until (rNowTime - rOkTime >= 2000);

end;


procedure PingLan(IP: string );
var
  i,j,k : Integer;
  R : TIperfResult;
  Match: TMatch;
  Matches, Matches1: TMatchCollection;
  n: Integer;
  Tarr, Tarr1 : TArray<Double>;
  s : string;
begin
  Lan_Result := 0;
  try
    //MessageBox(0,PChar('Pinglan'),'info', MB_OK + MB_ICONSTOP);
    RTime;
     //R := IperfTest(MakeOptions('192.168.1.10', 5201, imTCP, idNormal, 10, 1, 131072));
       R := IperfTest(IP, 5201, imTCP, idNormal, 10, 1, 131072);
     // MessageBox(0,PChar(R.AverageText),PChar('R.TEXT'),MB_OK);
      //MessageBox(0,PChar(R.BandwidthText),PChar('R1.TEXT'),MB_OK);
      // 处理发送的数据，每秒发送多少字节
      Matches := TRegEx.Matches(R.AverageText, '\d+(\.\d+)?');
      SetLength(Tarr, Matches.Count);
      for n := 0 to Matches.Count - 1 do
      begin
        Tarr[n] := StrToFloat(Matches[n].Value);
       end;
      R := IperfTest(IP, 5201, imTCP, idReverse, 10, 1, 131072);
      // 处理接收的数据  总的带宽
      Matches1 := TRegEx.Matches(R.BandwidthText, '\d+(\.\d+)?');
      SetLength(Tarr1, Matches1.Count);
      for n := 0 to Matches1.Count - 1 do
      begin
        Tarr1[n] := StrToFloat(Matches1[n].Value);
       end;

      //MessageBox(0,PChar(FloatToStr(Tarr1[1])),PChar('R1.TEXT'),MB_OK);

       try
          // 如果上传的速度大于 100Mbytes/s  下载的速度 大于 850Mbits/s 则pass
          if (Tarr[0] >= 100 ) and ( Tarr1[1] >= 850 ) then
            Lan_Result := 1
            else
              Lan_Result := 2;

          if Lan_Result = 2 then begin
             with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  '数据传输测试';
                           Cells[1,j] := '网络数据上传' + FloatToStr(Tarr[0]) + 'MB/s' + '下载' + FloatToStr(Tarr1[1]) + 'Mbits/s';
                           Cells[2,j] := 'FAIL';
                           Cells[3,j] := '设定值: 上传100MB/s;下载850MBits/s';
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                           //Exit;
                      end;
                  end;
              end;
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
                           Cells[1,j] := '网络数据上传' + FloatToStr(Tarr[0]) + 'MB/s' + '下载' + FloatToStr(Tarr1[1]) + 'Mbits/s';
                           Cells[2,j] := 'PASS';
                           Cells[3,j] := '设定值: 上传100MB/s;下载850MBits/s';
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                           //Exit;
                      end;
                  end;
              end;
          end;
       except on E:Exception do
         //MessageBox(0,PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
         //ShowMessage(E.GetBaseException.ToString);
       end;
  finally

  end;
end;


//单网卡测试
procedure NetConnectTest(NicName : string; MAC_ADDR: string; Server_IP: string; SPEED: Integer);
begin
    if GetMacAddr1('', MAC_ADDR,1) then    //如果MAC 测试PASS，则继续执行网络数据传输，测试网络连接速度
    begin
        Test_Project_Demo1.Form2.LanMac0_Result := 'PASS';
        PingLan(Server_IP);
        if Lan_Result = 1 then
            Test_Project_Demo1.Form2.Lansend0_Result := 'PASS'
        else
            Test_Project_Demo1.Form2.Lansend0_Result := 'FAIL';
        SPEED_CONN(NicName, SPEED);
    end
    else
    begin
        Test_Project_Demo1.Form2.LanMac0_Result := 'FAIL';
        Test_Project_Demo1.Form2.mac1_temp := mac1;
    end;

end;

//双网卡测试，用于自动测试
procedure NetConnectTest(PCBA_TYPE: Integer; MAC_ADDR: string; Server_IP: string; Speed1,Speed2 : Integer; Num : Integer; Over_Time : Word; Server : Word);
var
  pa1,pa2,pa3,pa4,pa5 : string;
  i,j,speed : Integer;
  t,t1,L1 : DWORD;
  List1 : TStringList;
  LeftPart, RightPart, Temp : string;
begin
   wList1 := TStringList.Create;          // 记录MAC 地址列表
   PList1 := TStringList.Create;          // 记录网络连接名称列表

   List1 := TStringList.Create;
   SetCurrentDir('C:\Test_Project');

     //MessageBox(0,PChar('Enter 2Lan Test'),PChar('Net Function'),MB_OK);
     CoInitialize(nil);
     //测试前，先抓取所有网卡的MAC 地址，将其存于对应的列表中
     try
          List1 := GetMACAddresses;
          for i := 0 to List1.Count - 1 do
            begin
              Temp := List1[i];
              t := Pos('=', Temp);
              if t > 0 then
              begin
                // 提取等号左侧内容
                LeftPart := Copy(Temp, 1, t - 1);
                //MessageBox(0,PChar(LeftPart),PChar('list2.LeftPart'),MB_OK);
                // 提取等号右侧内容
                RightPart := Copy(Temp, t + 1, Length(Temp));
                if ((LeftStr(Trim(LeftPart),3) = '以太网') or (LeftStr(Trim(LeftPart),4) = '本地连接')  or
                (LeftStr(Trim(LeftPart),8) = 'Ethernet'))  then
                  begin
                    PList1.Add(LeftPart);
                    wList1.Add(RightPart);
                  end;
              end;
            end;

          L1 := Num;
          if ( L1 <> 0 ) then
          begin
              // if (L1 = 4) and (Server = 2) then      //双网卡测试
              // begin
                 //MessageBox(0,PChar('Enter 4Lan Test '),PChar('Lan4'),MB_OK);
                 if (wList1.Count = L1 ) and (PList1.Count = L1) then
                 begin
                  //  MessageBox(0,PChar('First Lan Test '),PChar('Lan1'),MB_OK);
                  //  Test_Project_Demo1.Form2.mac3_temp := DeleteBlank(wList1[2]);
                  //  Test_Project_Demo1.Form2.mac4_temp := DeleteBlank(wList1[3]); }
                    for i := 0 to L1 - 1 do      // 测试的网卡序号
                      begin
                           for j := 0 to PList1.Count - 1 do    // 记录网卡列表与网卡序号逐一比对，符合条件的就打开，不符合就关闭
                           begin
                              if j = i then
                                ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(' "' + PList1[j] + '" "enable"'),PChar(ExtractFilePath(ParamStr(0))),0)
                              else
                                ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(' "' + PList1[j] + '" "disable"'),PChar(ExtractFilePath(ParamStr(0))),0);
                           end;
//                         ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(' "' + PList1[0] + '" "enable"'),PChar(ExtractFilePath(ParamStr(0))),0);
//                         ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(' "' + PList1[1] + '" "disable"'),PChar(ExtractFilePath(ParamStr(0))),0);
                          Sleep(Over_Time);
                          if GetMacAddr(wList1[i], MAC_Addr) then
                          begin
                            //  MessageBox(0,PChar('Enter GetMacAddr'),PChar('GetMacAddr'),MB_OK);
                             case i of
                                0:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC0_Result := 'PASS';
                                  Test_Project_Demo1.Form2.mac1_temp := DeleteBlank(wList1[i]);
                                end;
                                1:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC1_Result := 'PASS';
                                  Test_Project_Demo1.Form2.mac2_temp := DeleteBlank(wList1[i]);
                                end;
                                2:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC2_Result := 'PASS';
                                  Test_Project_Demo1.Form2.mac3_temp := DeleteBlank(wList1[i]);
                                end;
                                3:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC3_Result := 'PASS';
                                  Test_Project_Demo1.Form2.mac4_temp := DeleteBlank(wList1[i]);
                                end;
                             end;
                          end
                          else
                          begin
                            case i of
                                0:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC0_Result := 'FAIL';
                                end;
                                1:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC1_Result := 'FAIL';
                                end;
                                2:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC2_Result := 'FAIL';
                                end;
                                3:
                                begin
                                  Test_Project_Demo1.Form2.LanMAC3_Result := 'FAIL';
                                end;
                             end;
                          end;
                         PingLan(Server_IP);
                         if Lan_Result = 1 then
                         begin
                          //  MessageBox(0,PChar('Enter PingLan'),PChar('PingLan'),MB_OK);
                            case i of
                                0:
                                begin
                                  Test_Project_Demo1.Form2.Lansend0_Result := 'PASS';
                                end;
                                1:
                                begin
                                  Test_Project_Demo1.Form2.Lansend1_Result := 'PASS';
                                end;
                                2:
                                begin
                                  Test_Project_Demo1.Form2.Lansend2_Result := 'PASS';
                                end;
                                3:
                                begin
                                  Test_Project_Demo1.Form2.Lansend3_Result := 'PASS';
                                end;
                             end;
                         end
                         else
                         begin
                           case i of
                                0:
                                begin
                                  Test_Project_Demo1.Form2.Lansend0_Result := 'FAIL';
                                end;
                                1:
                                begin
                                  Test_Project_Demo1.Form2.Lansend1_Result := 'FAIL';
                                end;
                                2:
                                begin
                                  Test_Project_Demo1.Form2.Lansend2_Result := 'FAIL';
                                end;
                                3:
                                begin
                                  Test_Project_Demo1.Form2.Lansend3_Result := 'FAIL';
                                end;
                             end;
                          end;

                          if i = 1 then speed := Speed2
                            else
                              speed := Speed1;

                          if SPEED_CONN(PList1[i],Speed) then
                          begin
                          //    MessageBox(0,PChar('Enter SPEED_CONN'),PChar('SPEED_CONN'),MB_OK);
                              case i of
                                0:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed0_Result := 'PASS';
                                end;
                                1:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed1_Result := 'PASS';
                                end;
                                2:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed2_Result := 'PASS';
                                end;
                                3:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed3_Result := 'PASS';
                                end;
                             end;
                          end
                          else
                          begin
                             case i of
                                0:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed0_Result := 'FAIL';
                                end;
                                1:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed1_Result := 'FAIL';
                                end;
                                2:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed2_Result := 'FAIL';
                                end;
                                3:
                                begin
                                  Test_Project_Demo1.Form2.LanSpeed3_Result := 'FAIL';
                                end;
                             end;
                          end;
                      end;
                 end
                 else
                 begin
                   MessageBox(0,PChar('请确认网卡是否都处于打开状态！'), PChar('出错了') , MB_ICONERROR);
                 end;
                 for i := 0 to (L1 - 1) do    //测试完成后，全部网卡打开
                   begin
                     ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(' "' + PList1[i] + '" "enable"'),PChar(ExtractFilePath(ParamStr(0))),0)
                   end;
          end
          else
            begin
                  MessageBox(0,PChar('请确认网卡是否都处于打开状态！'), PChar('出错了') , MB_ICONERROR);
            end;

     finally
        Sleep(2000);
        //Frm_showmac.Free;
        wList1.Destroy;
        PList1.Destroy;
        List1.Destroy;
     end;
     CoUninitialize;
end;

function SPEED_CONN(NicName: string; Speed : Integer):Boolean;
var
  FileName : String;
  List : TStringList;
  i,j : Integer;
  str1 : string;
  Ccode : Cardinal;
begin
  Result := False;
  List := TStringList.Create;
  FileName := ExtractFilePath(ParamStr(0)) + 'lspeed.txt';
  str1 := ' "' + NicName + '"';
  try
      Ccode := ShellExecute(0,'open','GetLanSpeed_C.exe',PChar(str1),PChar(ExtractFilePath(ParamStr(0))),0);
      Sleep(1000);
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
                  Result := True;
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
                  Result := False;
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


function GetWMIProperty(WMIType, WMIProperty:AnsiString):String;
var
  Wmi, Objs, Obj: oleVariant;
  Enum: IEnumVariant;
  C: Cardinal;
begin

  Wmi:= CreateOleObject('WbemScripting.SWbemLocator');
  Objs := Wmi.ConnectServer('.','root/cimv2').ExecQuery('Select * from Win32_' + WMIType);
  Enum := IEnumVariant(IUnknown(Objs._NewEnum));
  Enum.Reset;
  Enum.Next(1,Obj,C);

      Obj := Obj.Properties_.Item(WMIProperty, 0).Value;

      if VarIsNull(obj) then
      begin
        Result:='Error';
      end;

      if VarIsArray(obj) then
      begin
        Result := Obj[0];
      end;

      if VarIsStr(obj) or VarIsCustom(obj) or VarIsFloat(obj) or VarIsNumeric(obj) or VarIsOrdinal(obj) then
      begin
        Result:= Obj;
      end;

end;


function GetWMISub(WMIType,WMIProperty,WMISearch,WMISearchText:String):String;
var
  Wmi, Objs, Obj: oleVariant;
  Enum: IEnumVariant;
  C: Cardinal;
begin

  Wmi:= CreateOleObject('WbemScripting.SWbemLocator');
  Objs := Wmi.ConnectServer('.','root/cimv2').ExecQuery('Select * from Win32_' + WMIType + ' where '+WMISearch+' = '+ '"'+WMISearchText+'"');
  Enum := IEnumVariant(IUnknown(Objs._NewEnum));
  Enum.Reset;
  Enum.Next(1,Obj,C);

      Obj := Obj.Properties_.Item(WMIProperty, 0).Value;

      if VarIsNull(obj) then
      begin
        Result:='Unknow';
      end;

      if VarIsArray(obj) then
      begin
        Result := Obj[0];
      end;

      if VarIsStr(obj) or VarIsCustom(obj) or VarIsFloat(obj) or VarIsNumeric(obj) or VarIsOrdinal(obj) then
      begin
        Result:= Obj;
      end;

end;


function GetLanPNPDeviceID(macid:string; lNum : Integer):Integer;
var
  Wmi, Objs, Obj: oleVariant;
  Enum: IEnumVariant;
  C: Cardinal;
  Str,str1:string;
  Temp,PNPDevID : string;
  Num,i : Word;
begin
  result := 0;
  Num := 0;
  i := 0;
  Wmi:= CreateOleObject('WbemScripting.SWbemLocator');
  Objs := Wmi.ConnectServer('.','root/cimv2').ExecQuery('Select * from Win32_NetworkAdapter');//此处是查询网卡的WMI库
  Enum := IEnumVariant(IUnknown(Objs._NewEnum));
  Enum.Reset;
  while (Enum.Next(1,Obj,C)=s_ok) do  //循环查询网卡信息
  begin
      str1:='Index';//将INDEX当作网卡唯一的识别码
      Obj := Obj.Properties_.Item(str1, 0).Value;
      Inc(i);
      if VarIsNull(obj) then
      begin
        Str:='ERROR';
      end;

      if VarIsArray(obj) then
      begin
        str:=Obj[0];
      end;

      if VarIsStr(obj) or VarIsCustom(obj) or VarIsFloat(obj) or VarIsNumeric(obj) or VarIsOrdinal(obj) then
      begin
        str:=Obj;
      end;

      //在循环的过程当调用获取网卡信息的函数，并将查询的参数传给函数
      Temp := Trim(GetWMISub('NetworkAdapter','MACAddress',str1,Str));
      PNPDevID :=  Trim(GetWMISub('NetworkAdapter','NetConnectionID',str1,Str));

      if  (LeftStr(Temp,8) = macid) and ( (LeftStr(Trim(PNPDevID),3) = '以太网') or (LeftStr(Trim(PNPDevID),4) = '本地连接')  or (LeftStr(Trim(PNPDevID),8) = 'Ethernet')) then
      begin
//        MessageBox(0,PChar(PNPDevID),'Message',MB_OK);
        wList1.Add(Temp);
        PList1.Add(PNPDevID);
        Inc(Num);
        if Num = lNum then
        begin
          Result := Num;
        end;

      end
      else if (LeftStr(Trim(Temp),7) <> 'Unknow') and (macid = 'no') and ( (LeftStr(Trim(PNPDevID),3) = '以太网') or (LeftStr(Trim(PNPDevID),4) = '本地连接') or (LeftStr(Trim(PNPDevID),8) = 'Ethernet')) then     // 如果没有提供macid前缀，那就表示现在测试的是客供主板
           begin

              wList1.Add(Temp);
              PList1.Add(PNPDevID);
              Inc(Num);
              if Num = lNum then
              begin
                Result := Num;
              end;

           end;
  end;

end;

{
function GetLanIPAddress();
var
  WbemLocator: OleVariant;
  WbemServices: OleVariant;
  WbemObjectSet: OleVariant;
  WbemObject: OleVariant;
  oEnum: IEnumVariant;
  MAC, IP, Description: string;
  Value: LongWord;
begin
  Memo1.Clear;
  CoInitialize(nil);
  try
    WbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    WbemServices := WbemLocator.ConnectServer('localhost', 'root\CIMV2');
    WbemObjectSet := WbemServices.ExecQuery('SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True');
    oEnum := IUnknown(WbemObjectSet._NewEnum) as IEnumVariant;

    while oEnum.Next(1, WbemObject, Value) = S_OK do
    begin
      MAC := WbemObject.MACAddress;
      if not VarIsNull(WbemObject.IPAddress) then
        IP := VarToStr(WbemObject.IPAddress[0])
      else
        IP := 'N/A';
      Description := WbemObject.Description;

      Memo1.Lines.Add('Adapter: ' + Description);
      Memo1.Lines.Add('MAC: ' + MAC);
      Memo1.Lines.Add('IP: ' + IP);
      Memo1.Lines.Add('------------------------');

      WbemObject := Unassigned;
    end;
  finally
    CoUninitialize;
  end;
end;
    */
  }
function InsertBlank(MAC_Addr: string):String;
var
  //List: TStringList;
  i : integer;
  MAC : string;
begin

   MAC := MAC_Addr;
   i := 3;
   repeat
      Insert(':',MAC,i);
      inc(i,3);
   until i > Length(MAC);
   Result := Trim(MAC);
end;

function DeleteBlank(MAC_Addr: string):String;
var
  //List: TStringList;
  i : integer;
  MAC : string;
begin
   MAC := StringReplace(MAC_Addr, ':', '', [rfReplaceAll, rfIgnoreCase]);

   Result := Trim(MAC);
end;

function RemoveChar(const Source, CharToRemove: string): string;
begin
  Result := StringReplace(Source, CharToRemove, '', [rfReplaceAll]);
end;

end.
