{*******************************************************************************
  uIperfCommon.pas  -  Delphi 版 iperf3 公共基础层

  本单元从 iperf3 的 C 代码 (src/iperf.h, src/units.c, src/net.c) 移植而来，
  提供：
    * 协议常量 / 枚举 / 数据结构（握手包、统计包、UDP 包头、区间采样）
    * 字节数 / 带宽 / 时长的格式化（对应 iperf3 units.c 的 unit_snprintf）
    * 线程安全的计数器 TIperfCounters（对应 struct iperf_stream_result）
    * 每秒采样器 TIperfSampler（对应 iperf3 的 interval 统计线程）
    * WinSock 封装（启动/解析地址/非阻塞/超时/收发全量数据）

  适用：Delphi 10.2 Tokyo 及以上（在 10.4 Sydney / Winapi.Winsock2 上核对通过）
*******************************************************************************}
unit uIperfCommon;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  Winapi.Windows, Winapi.Winsock2;

const
  { ---- 协议常量 ---- }
  IPERF_MAGIC             = Cardinal($49504633);   // 'IPF3'
  IPERF_VERSION           = Word(1);
  IPERF_DEFAULT_PORT      = 5201;                  // 与 iperf3 默认端口一致
  IPERF_DEFAULT_TIME      = 10;                    // 默认测试 10 秒
  IPERF_DEFAULT_TCP_BLOCK = 128 * 1024;            // TCP 单次发送块大小
  IPERF_DEFAULT_UDP_BLOCK = 1400;                  // UDP 单包 payload 大小
  IPERF_DEFAULT_UDP_RATE  = Int64(10) * 1000 * 1000;// 默认 10 Mbit/s
  IPERF_MAX_STREAMS       = 64;

  { ---- 数据 socket 缓冲区（KB）----
    0 = 不设置，交给系统自动调优（和 iperf3 一样，默认、推荐）。
    一旦显式设置 SO_RCVBUF，Windows 就会关掉该连接的接收窗口自动调优，
    吞吐会被卡在「窗口 / RTT」这个上限上：
        1 Gbit/s 需要 窗口 >= 125000 * RTT(ms) 字节
        例如 RTT 2ms → 需要 250 KB，硬设 256 KB 就正好卡在 800 Mbit/s 左右。
    所以只有在明确知道链路 RTT 很大、系统调优不够时才手工填这个值（比如 2048）。 }
  IPERF_DEFAULT_SOCK_BUF_KB = 0;
  IPERF_MAX_SOCK_BUF_KB     = 65536;

  { ---- Windows Winsock 常量（避免依赖 Winapi.Winsock 单元） ---- }
  SD_RECEIVE              = 0;
  SD_SEND                 = 1;
  SD_BOTH                 = 2;

  { ---- UDP 控制报文序号标记 ---- }
  UDP_HELLO               = Int64(-1);   // 客户端 -> 服务端：端点发现
  UDP_HELLO_ACK           = Int64(-2);   // 服务端 -> 客户端：应答

type
  { 传输协议 }
  TIperfMode = (imTCP, imUDP);

  { 测试方向：正向(客户端发) / 反向(服务端发) / 双向同时 }
  TIperfDirection = (idNormal, idReverse, idBidir);

  { 端点角色 }
  TIperfRole = (irClient, irServer);

  { 握手包类型 }
  TPacketKind = (pkControl = 0, pkData = 1, pkUdpHello = 2, pkUdpHelloAck = 3,
                 pkReport = 4);

  { ---- 一次测试的控制握手（46 字节，客户端 -> 服务端） ---- }
  THandshake = packed record
    Magic      : Cardinal;   // IPERF_MAGIC
    Version    : Word;       // IPERF_VERSION
    Kind       : Byte;       // TPacketKind
    Mode       : Byte;       // 0=TCP 1=UDP
    Direction  : Byte;       // 0=正常 1=反向 2=双向
    Streams    : Byte;       // 并发流数
    DurationMs : Cardinal;   // 测试时长(毫秒)
    IntervalMs : Cardinal;   // 报表间隔(毫秒)
    BlockSize  : Cardinal;   // 每次发送的数据块大小 / UDP payload 大小
    TargetBps   : Int64;     // UDP 目标带宽(bit/s)，0=不限速
    Cookie     : TGUID;      // 本次测试的唯一标识
  end;

  { ---- UDP 数据包头（36 字节） ---- }
  TUdpHeader = packed record
    Cookie : TGUID;          // 所属测试
    Stream : Cardinal;       // 流编号
    Seq    : Int64;          // 序号，-1=hello -2=hello ack
    TickMs : Int64;          // 发送时刻(IperfTickMs)
  end;

  { ---- 测试结束后两个端点互相交换的统计报告 ---- }
  TReportPacket = packed record
    Magic      : Cardinal;
    Kind       : Byte;       // pkReport
    Mode       : Byte;
    Direction  : Byte;
    Reserved   : Byte;
    Streams    : Integer;
    SentBytes  : Int64;      // 本端累计发出的应用层字节
    SentChunks : Int64;      // 本端累计发出的次数(块数 / 报文数)
    RecvBytes  : Int64;      // 本端累计收到的应用层字节
    RecvChunks : Int64;      // 本端累计收到的次数
    LostChunks : Int64;      // UDP 丢失报文数(估算)
    ElapsedMs  : Int64;      // 实际测试耗时(毫秒)
    JitterUs   : Int64;      // UDP 抖动(微秒)
    BlockSize  : Cardinal;   // 块大小 / 报文 payload 大小
    Cookie     : TGUID;
  end;

  { ---- 每秒区间采样（对应 iperf3 的 [SUM] 行） ---- }
  TIntervalSample = record
    Sec        : Integer;    // 第几个区间，从 1 开始
    ElapsedMs  : Int64;      // 从测试开始到本区间结束的毫秒数
    SpanMs     : Int64;      // 本区间实际时长
    SentBytes  : Int64;      // 本区间发出的字节
    SentChunks : Int64;
    RecvBytes  : Int64;      // 本区间收到的字节
    RecvChunks : Int64;
    { ---- 会话标识：服务端同时服务多个客户端时用来区分数据来源 ---- }
    Cookie     : TGUID;      // 所属会话的 Cookie
    Peer       : string;     // 对端地址 "IP:Port"（服务端=客户端地址）
  end;

  { 采样回调（在采样线程中调用，GUI 需自行切回主线程） }
  TSampleProc = reference to procedure(const S: TIntervalSample);
  { 日志回调（在工作线程中调用） }
  TLogProc = reference to procedure(const Msg: string);
  { 测试完成回调 }
  TReportProc = reference to procedure(const Local, Remote: TReportPacket);
  { 服务端专用的测试完成回调：额外带上客户端地址 "IP:Port"，
    服务端界面按会话展示时用它标识是哪一台客户端跑完的 }
  TSrvReportProc = reference to procedure(const Peer: string;
    const Local, Remote: TReportPacket);

{==============================================================================
  格式化函数（对应 iperf3 units.c）
==============================================================================}
function FormatBytes(const Bytes: Int64): string;              // 1.25 MBytes
function FormatBitrate(const BitsPerSec: Double): string;      // 9.42 Mbits/sec
function FormatDuration(const Ms: Int64): string;              // 10.00 secs
function FormatCount(const N: Int64): string;                  // 1,234,567
function ModeToStr(const M: TIperfMode): string;
function DirectionToStr(const D: TIperfDirection): string;
function DirectionToCn(const D: TIperfDirection): string;
function CookieTag(const Cookie: TGUID): string;               // "A1B2C3D4" 短标识
function SessionTag(const S: TIntervalSample): string;         // "127.0.0.1:5231|A1B2C3D4"

{ 生成一行 iperf3 风格的实时统计文本
  WithTag=True 时行首带会话标识，服务端多点并发时用来区分属于哪个客户端 }
function BuildIntervalLine(const S: TIntervalSample;
  const WithTag: Boolean = False): string;

{==============================================================================
  WinSock 辅助
==============================================================================}
function IperfWinsockStartup: Boolean;
procedure IperfWinsockCleanup;
function ResolveIPv4(const Host: string; out NetAddr: u_long): Boolean;
function NetAddrToStr(const A: u_long): string;
function MakeSockAddr(const NetAddr: u_long; const Port: Word): TSockAddr;
function SockAddrToNetAddr(const SA: TSockAddr): u_long;
function SockAddrToPort(const SA: TSockAddr): Word;
function SockAddrToPeer(const SA: TSockAddr): string;          // "IP:Port"
function SocketErrText(const Code: Integer): string;
function LastSocketErrText: string;

{ 单调递增的毫秒时钟。
  GetTickCount64 在 Delphi 10.3 之前未在 Winapi.Windows 中声明，所以这里
  动态从 kernel32 取；万一取不到（XP 等）再退回 32 位 GetTickCount。 }
function IperfTickMs: UInt64;

procedure SetNonBlocking(const S: TSocket; const Value: Boolean);
procedure SetNoDelay(const S: TSocket);
procedure SetSockBufSize(const S: TSocket; const OptName, Bytes: Integer);
procedure SetSockTimeout(const S: TSocket; const RecvMs, SendMs: Integer);

function WaitReadable(const S: TSocket; const Ms: Integer): Boolean;
function WaitWritable(const S: TSocket; const Ms: Integer): Boolean;

{ 阻塞式收/发指定长度，内部用 select 分片，避免死等 }
function SendAll(const S: TSocket; const Buf; const Len, TimeoutMs: Integer): Boolean;
function RecvAll(const S: TSocket; var Buf; const Len, TimeoutMs: Integer): Boolean;

{==============================================================================
  TIperfCounters - 线程安全计数器
==============================================================================}
type
  TIperfCounters = class
  private
    FSentBytes : Int64;
    FSentChunks: Int64;
    FRecvBytes : Int64;
    FRecvChunks: Int64;
    FLostChunks: Int64;
    FJitterUs  : Int64;
  public
    procedure Reset;
    procedure IncSent(const Bytes: Int64; const Chunks: Int64 = 1);
    procedure IncRecv(const Bytes: Int64; const Chunks: Int64 = 1);
    procedure AddLost(const N: Int64);
    procedure SetJitterUs(const Us: Int64);
    property SentBytes : Int64 read FSentBytes;
    property SentChunks: Int64 read FSentChunks;
    property RecvBytes : Int64 read FRecvBytes;
    property RecvChunks: Int64 read FRecvChunks;
    property LostChunks: Int64 read FLostChunks;
    property JitterUs  : Int64 read FJitterUs;
  end;

{==============================================================================
  TIperfSampler - 每 N 毫秒轮询一次，跨过区间边界就产出一条采样
  对应 iperf3 中 iperf_print_intermediate() 的每秒统计
==============================================================================}
  TIperfSampler = class(TThread)
  private
    FCounters  : TIperfCounters;
    FIntervalMs: Int64;
    FDurationMs: Int64;
    FOnSample  : TSampleProc;
    FStartTick : UInt64;
    FLastTick  : UInt64;
    FLastSentB : Int64;
    FLastSentC : Int64;
    FLastRecvB : Int64;
    FLastRecvC : Int64;
    FSecIndex  : Integer;
    FStop      : TEvent;
    FCookie    : TGUID;      // 会话标识，多客户端并发时随采样一起送出
    FPeer      : string;     // 对端 "IP:Port"
    procedure Emit;
  protected
    procedure Execute; override;
  public
    { ADurationMs > 0 时，跑满时长就不再产生新的区间，改为等 Stop 时把最后一段
      （含数据面收尾的尾巴）一次性吐出，这样"逐秒相加 == 总量"。
      不传（0）就一直按间隔采样，直到 Stop。 }
    constructor Create(const ACounters: TIperfCounters; const AIntervalMs: Int64;
      const AOnSample: TSampleProc; const ADurationMs: Int64 = 0);
    destructor Destroy; override;
    procedure Stop;
    { 标记本采样器属于哪个会话（须在 Start 之前调用） }
    procedure SetIdentity(const ACookie: TGUID; const APeer: string);
  end;

{==============================================================================
  TIperfLog - 线程安全日志队列（GUI 定时器拉取）
==============================================================================}
  TIperfLog = class
  private
    FLock : TCriticalSection;
    FLines: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const S: string);
    function Drain: TArray<string>;
  end;

implementation

const
  BYTE_SUFFIX: array[0..5] of string =
    ('Bytes', 'KBytes', 'MBytes', 'GBytes', 'TBytes', 'PBytes');
  BIT_SUFFIX: array[0..5] of string =
    ('bits/sec', 'Kbits/sec', 'Mbits/sec', 'Gbits/sec', 'Tbits/sec', 'Pbits/sec');

  { 时长跑满之后，采样器最多再多等这么久（等调用方 StopSampling 来收尾）。
    正常情况下数据面线程收尾只要几毫秒；这个上限只是防止调用方忘了 Stop 时线程悬着。 }
  SAMPLER_TAIL_WAIT_MS = 5000;

function FormatBytes(const Bytes: Int64): string;
var
  V: Double;
  I: Integer;
begin
  if Bytes < 0 then
    Exit('0 Bytes');
  V := Bytes;
  I := 0;
  while (V >= 1024) and (I < High(BYTE_SUFFIX)) do
  begin
    V := V / 1024;
    Inc(I);
  end;
  if I = 0 then
    Result := Format('%.0f %s', [V, BYTE_SUFFIX[I]])
  else
    Result := Format('%.2f %s', [V, BYTE_SUFFIX[I]]);
end;

function FormatBitrate(const BitsPerSec: Double): string;
var
  V: Double;
  I: Integer;
begin
  V := BitsPerSec;
  if V < 0 then
    V := 0;
  I := 0;
  while (V >= 1000) and (I < High(BIT_SUFFIX)) do
  begin
    V := V / 1000;
    Inc(I);
  end;
  if I = 0 then
    Result := Format('%.0f %s', [V, BIT_SUFFIX[I]])
  else
    Result := Format('%.2f %s', [V, BIT_SUFFIX[I]]);
end;

function FormatDuration(const Ms: Int64): string;
begin
  Result := Format('%.2f secs', [Ms / 1000.0]);
end;

function FormatCount(const N: Int64): string;
var
  S: string;
  I: Integer;
begin
  S := IntToStr(Abs(N));
  I := Length(S) - 3;
  while I > 0 do
  begin
    Insert(',', S, I + 1);
    Dec(I, 3);
  end;
  if N < 0 then
    S := '-' + S;
  Result := S;
end;

function ModeToStr(const M: TIperfMode): string;
begin
  if M = imTCP then
    Result := 'TCP'
  else
    Result := 'UDP';
end;

function DirectionToStr(const D: TIperfDirection): string;
begin
  case D of
    idReverse: Result := 'reverse';
    idBidir  : Result := 'bidir';
  else
    Result := 'normal';
  end;
end;

function DirectionToCn(const D: TIperfDirection): string;
begin
  case D of
    idReverse: Result := '反向(服务端->客户端)';
    idBidir  : Result := '双向(同时收发)';
  else
    Result := '正向(客户端->服务端)';
  end;
end;

function CookieTag(const Cookie: TGUID): string;
var
  S: string;
begin
  S := GUIDToString(Cookie);
  if Length(S) >= 8 then
    Result := Copy(S, 2, 8)
  else
    Result := S;
end;

function SessionTag(const S: TIntervalSample): string;
begin
  Result := '';
  if S.Peer <> '' then
    Result := S.Peer;
  if S.Cookie.D1 <> 0 then
  begin
    if Result <> '' then
      Result := Result + '|';
    Result := Result + CookieTag(S.Cookie);
  end;
end;

function BuildIntervalLine(const S: TIntervalSample;
  const WithTag: Boolean): string;
var
  SpanSec  : Double;
  TxRate   : Double;
  RxRate   : Double;
  Tag      : string;
begin
  if S.SpanMs <= 0 then
    SpanSec := 1.0
  else
    SpanSec := S.SpanMs / 1000.0;

  TxRate := S.SentBytes * 8.0 / SpanSec;
  RxRate := S.RecvBytes * 8.0 / SpanSec;

  Tag := '';
  if WithTag then
  begin
    Tag := SessionTag(S);
    if Tag <> '' then
      Tag := '[' + Tag + '] ';
  end;

  Result := Tag + Format('%6.2f-%6.2f sec   ', [S.ElapsedMs / 1000.0 - SpanSec,
    S.ElapsedMs / 1000.0])
    + Format('发送 %s (%s 块) %s | 接收 %s (%s 块) %s',
      [FormatBytes(S.SentBytes), FormatCount(S.SentChunks), FormatBitrate(TxRate),
       FormatBytes(S.RecvBytes), FormatCount(S.RecvChunks), FormatBitrate(RxRate)]);
end;

{==============================================================================
  WinSock
==============================================================================}
var
  GWinsockStarted: Boolean = False;

type
  TGetTickCount64Fn = function: UInt64; stdcall;

var
  GGetTickCount64: TGetTickCount64Fn = nil;
  GTickProbed    : Boolean = False;

function IperfTickMs: UInt64;
var
  H: HMODULE;
  P: Pointer;
begin
  if not GTickProbed then
  begin
    GTickProbed := True;
    H := GetModuleHandleA('kernel32.dll');
    if H <> 0 then
    begin
      P := GetProcAddress(H, 'GetTickCount64');
      if P <> nil then
        @GGetTickCount64 := P;
    end;
  end;
  if Assigned(GGetTickCount64) then
    Result := GGetTickCount64
  else
    Result := UInt64(GetTickCount);
end;

function IperfWinsockStartup: Boolean;
var
  Data: TWSAData;
begin
  if GWinsockStarted then
    Exit(True);
  Result := WSAStartup($0202, Data) = 0;
  GWinsockStarted := Result;
end;

procedure IperfWinsockCleanup;
begin
  if GWinsockStarted then
  begin
    WSACleanup;
    GWinsockStarted := False;
  end;
end;

function ResolveIPv4(const Host: string; out NetAddr: u_long): Boolean;
var
  H : string;
  Nm: AnsiString;
  A : u_long;
  He: PHostEnt;
begin
  Result  := False;
  NetAddr := 0;
  H := Trim(Host);
  if H = '' then
    H := '127.0.0.1';
  Nm := AnsiString(H);
  A := inet_addr(MarshaledAString(PAnsiChar(Nm)));
  if (A <> u_long(INADDR_NONE)) and (A <> 0) then
  begin
    NetAddr := A;
    Exit(True);
  end;
  { 不是点分十进制，尝试通过 DNS 解析主机名 }
  He := gethostbyname(MarshaledAString(PAnsiChar(Nm)));
  if He = nil then
    Exit;
  if (He^.h_addrtype <> AF_INET) or (He^.h_length <> 4) or (He^.h_addr_list = nil) then
    Exit;
  NetAddr := PCardinal(He^.h_addr_list^)^;
  Result  := NetAddr <> 0;
end;

function NetAddrToStr(const A: u_long): string;
var
  Ia: in_addr;
  P : MarshaledAString;
begin
  Ia.S_addr := A;
  P := inet_ntoa(Ia);
  if P = nil then
    Result := '0.0.0.0'
  else
    Result := string(AnsiString(P));
end;

type
  PIperfSockAddrIn = ^TSockAddrIn;

function MakeSockAddr(const NetAddr: u_long; const Port: Word): TSockAddr;
var
  Si: PIperfSockAddrIn;
begin
  FillChar(Result, SizeOf(Result), 0);
  Si := PIperfSockAddrIn(@Result);
  Si^.sin_family     := AF_INET;
  Si^.sin_port       := htons(Port);
  Si^.sin_addr.S_addr := NetAddr;
end;

function SockAddrToNetAddr(const SA: TSockAddr): u_long;
begin
  Result := PIperfSockAddrIn(@SA)^.sin_addr.S_addr;
end;

function SockAddrToPort(const SA: TSockAddr): Word;
begin
  Result := ntohs(PIperfSockAddrIn(@SA)^.sin_port);
end;

function SockAddrToPeer(const SA: TSockAddr): string;
begin
  Result := Format('%s:%d', [NetAddrToStr(SockAddrToNetAddr(SA)),
    SockAddrToPort(SA)]);
end;

function SocketErrText(const Code: Integer): string;
begin
  case Code of
    WSAEWOULDBLOCK      : Result := 'WSAEWOULDBLOCK(暂时无法完成)';
    WSAETIMEDOUT        : Result := 'WSAETIMEDOUT(超时)';
    WSAECONNRESET       : Result := 'WSAECONNRESET(连接被重置)';
    WSAECONNABORTED     : Result := 'WSAECONNABORTED(连接被中止)';
    WSAENOTCONN         : Result := 'WSAENOTCONN(未连接)';
    WSAEADDRINUSE       : Result := 'WSAEADDRINUSE(端口被占用)';
    WSAECONNREFUSED     : Result := 'WSAECONNREFUSED(连接被拒绝，服务端未监听)';
    WSAEHOSTUNREACH     : Result := 'WSAEHOSTUNREACH(主机不可达)';
    WSAENETUNREACH      : Result := 'WSAENETUNREACH(网络不可达)';
  else
    Result := Format('Winsock 错误码 %d', [Code]);
  end;
end;

function LastSocketErrText: string;
begin
  Result := SocketErrText(WSAGetLastError);
end;

procedure SetNonBlocking(const S: TSocket; const Value: Boolean);
var
  V: u_long;
begin
  if Value then
    V := 1
  else
    V := 0;
  ioctlsocket(S, Integer(FIONBIO), V);
end;

procedure SetNoDelay(const S: TSocket);
var
  V: Integer;
begin
  V := 1;
  setsockopt(S, IPPROTO_TCP, TCP_NODELAY, MarshaledAString(@V), SizeOf(V));
end;

procedure SetSockBufSize(const S: TSocket; const OptName, Bytes: Integer);
var
  V: Integer;
begin
  V := Bytes;
  setsockopt(S, SOL_SOCKET, OptName, MarshaledAString(@V), SizeOf(V));
end;

procedure SetSockTimeout(const S: TSocket; const RecvMs, SendMs: Integer);
var
  V: Integer;
begin
  if RecvMs >= 0 then
  begin
    V := RecvMs;
    setsockopt(S, SOL_SOCKET, SO_RCVTIMEO, MarshaledAString(@V), SizeOf(V));
  end;
  if SendMs >= 0 then
  begin
    V := SendMs;
    setsockopt(S, SOL_SOCKET, SO_SNDTIMEO, MarshaledAString(@V), SizeOf(V));
  end;
end;

function WaitReadable(const S: TSocket; const Ms: Integer): Boolean;
var
  Fs: TFDSet;
  Tv: TTimeVal;
begin
  Fs.fd_count := 1;
  Fs.fd_array[0] := S;
  Tv.tv_sec  := Ms div 1000;
  Tv.tv_usec := (Ms mod 1000) * 1000;
  Result := select(0, @Fs, nil, nil, @Tv) > 0;
end;

function WaitWritable(const S: TSocket; const Ms: Integer): Boolean;
var
  Fs: TFDSet;
  Tv: TTimeVal;
begin
  Fs.fd_count := 1;
  Fs.fd_array[0] := S;
  Tv.tv_sec  := Ms div 1000;
  Tv.tv_usec := (Ms mod 1000) * 1000;
  Result := select(0, nil, @Fs, nil, @Tv) > 0;
end;

function SendAll(const S: TSocket; const Buf; const Len, TimeoutMs: Integer): Boolean;
var
  P      : PByte;
  N, Sent: Integer;
  Waited : Integer;
  Err    : Integer;
begin
  Result := False;
  P := @Buf;
  Sent := 0;
  Waited := 0;
  while Sent < Len do
  begin
    N := send(S, P^, Len - Sent, 0);
    if N > 0 then
    begin
      Inc(Sent, N);
      Inc(P, N);
      Waited := 0;
      Continue;
    end;
    if N = 0 then
      Exit;
    Err := WSAGetLastError;
    if Err <> WSAEWOULDBLOCK then
      Exit;
    if not WaitWritable(S, 100) then
    begin
      Inc(Waited, 100);
      if Waited >= TimeoutMs then
        Exit;
    end;
  end;
  Result := True;
end;

function RecvAll(const S: TSocket; var Buf; const Len, TimeoutMs: Integer): Boolean;
var
  P      : PByte;
  N, Got : Integer;
  Waited : Integer;
  Err    : Integer;
begin
  Result := False;
  P := @Buf;
  Got := 0;
  Waited := 0;
  while Got < Len do
  begin
    N := recv(S, P^, Len - Got, 0);
    if N > 0 then
    begin
      Inc(Got, N);
      Inc(P, N);
      Waited := 0;
      Continue;
    end;
    if N = 0 then
      Exit;                       // 对端正常关闭
    Err := WSAGetLastError;
    if Err <> WSAEWOULDBLOCK then
      Exit;
    if not WaitReadable(S, 100) then
    begin
      Inc(Waited, 100);
      if Waited >= TimeoutMs then
        Exit;
    end;
  end;
  Result := True;
end;

{==============================================================================
  TIperfCounters
==============================================================================}
procedure TIperfCounters.Reset;
begin
  TInterlocked.Exchange(FSentBytes, 0);
  TInterlocked.Exchange(FSentChunks, 0);
  TInterlocked.Exchange(FRecvBytes, 0);
  TInterlocked.Exchange(FRecvChunks, 0);
  TInterlocked.Exchange(FLostChunks, 0);
  TInterlocked.Exchange(FJitterUs, 0);
end;

procedure TIperfCounters.IncSent(const Bytes, Chunks: Int64);
begin
  TInterlocked.Add(FSentBytes, Bytes);
  TInterlocked.Add(FSentChunks, Chunks);
end;

procedure TIperfCounters.IncRecv(const Bytes, Chunks: Int64);
begin
  TInterlocked.Add(FRecvBytes, Bytes);
  TInterlocked.Add(FRecvChunks, Chunks);
end;

procedure TIperfCounters.AddLost(const N: Int64);
begin
  TInterlocked.Add(FLostChunks, N);
end;

procedure TIperfCounters.SetJitterUs(const Us: Int64);
begin
  TInterlocked.Exchange(FJitterUs, Us);
end;

{==============================================================================
  TIperfSampler
==============================================================================}
constructor TIperfSampler.Create(const ACounters: TIperfCounters;
  const AIntervalMs: Int64; const AOnSample: TSampleProc;
  const ADurationMs: Int64);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCounters   := ACounters;
  FIntervalMs := AIntervalMs;
  if FIntervalMs < 100 then
    FIntervalMs := 1000;
  FDurationMs := ADurationMs;
  FOnSample := AOnSample;
  FStop     := TEvent.Create(nil, True, False, '');
  { 采样线程只做统计，但多点并发时数据面会把 CPU 吃满，
    稍微提一点优先级，保证每秒统计不会因为被饿着而漏段 }
  Priority  := tpHigher;
  FStartTick := IperfTickMs;
  FLastTick  := FStartTick;
  FSecIndex  := 0;
  FillChar(FCookie, SizeOf(FCookie), 0);
  FPeer      := '';
end;

procedure TIperfSampler.SetIdentity(const ACookie: TGUID; const APeer: string);
begin
  FCookie := ACookie;
  FPeer   := APeer;
end;

destructor TIperfSampler.Destroy;
begin
  Stop;
  FStop.Free;
  inherited;
end;

procedure TIperfSampler.Stop;
begin
  if Assigned(FStop) then
    FStop.SetEvent;
end;

procedure TIperfSampler.Emit;
var
  Sb, Sc, Rb, Rc: Int64;
  S: TIntervalSample;
begin
  Sb := FCounters.SentBytes;
  Sc := FCounters.SentChunks;
  Rb := FCounters.RecvBytes;
  Rc := FCounters.RecvChunks;

  S.Sec        := FSecIndex + 1;
  S.ElapsedMs  := Int64(IperfTickMs - FStartTick);
  S.SpanMs     := Int64(IperfTickMs - FLastTick);
  S.SentBytes  := Sb - FLastSentB;
  S.SentChunks := Sc - FLastSentC;
  S.RecvBytes  := Rb - FLastRecvB;
  S.RecvChunks := Rc - FLastRecvC;
  S.Cookie     := FCookie;
  S.Peer       := FPeer;

  FLastSentB := Sb;
  FLastSentC := Sc;
  FLastRecvB := Rb;
  FLastRecvC := Rc;
  FLastTick  := IperfTickMs;
  Inc(FSecIndex);

  if Assigned(FOnSample) then
    FOnSample(S);
end;

procedure TIperfSampler.Execute;
var
  NowTick  : UInt64;
  Due      : UInt64;
  ElapsedMs: Int64;
begin
  while not Terminated do
  begin
    { 5ms 轮询：区间边界最坏延迟 5ms，多会话并发时也能稳定落在边界上 }
    if FStop.WaitFor(5) = wrSignaled then
      Break;
    NowTick   := IperfTickMs;
    ElapsedMs := Int64(NowTick - FStartTick);

    { 时长跑满之后不再制造新的区间边界，而是等 StopSampling 来收尾。
      因为数据面线程收尾（最后一次 send 的返回、drain 残留数据）常常比时长边界
      晚几十微秒到几毫秒，把这段补进"最后一段"才能保证：
          逐秒采样相加 == 测试总量
      最多多等 SAMPLER_TAIL_WAIT_MS，防止调用方忘了 StopSampling 时线程一直悬着。 }
    if (FDurationMs > 0) and (ElapsedMs >= FDurationMs) then
    begin
      if ElapsedMs >= FDurationMs + SAMPLER_TAIL_WAIT_MS then
        Break;
      Continue;
    end;

    Due := FStartTick + UInt64(FSecIndex + 1) * UInt64(FIntervalMs);
    while (not Terminated) and (NowTick >= Due) do
    begin
      Emit;
      Due := FStartTick + UInt64(FSecIndex + 1) * UInt64(FIntervalMs);
    end;
  end;
  { 收尾：把最后一个不完整区间也吐出来，保证逐秒累加与总量一致 }
  Emit;
end;

{==============================================================================
  TIperfLog
==============================================================================}
constructor TIperfLog.Create;
begin
  inherited Create;
  FLock  := TCriticalSection.Create;
  FLines := TStringList.Create;
end;

destructor TIperfLog.Destroy;
begin
  FLines.Free;
  FLock.Free;
  inherited;
end;

procedure TIperfLog.Add(const S: string);
begin
  FLock.Enter;
  try
    if FLines.Count < 5000 then
      FLines.Add(S);
  finally
    FLock.Leave;
  end;
end;

function TIperfLog.Drain: TArray<string>;
var
  I: Integer;
begin
  Result := nil;
  FLock.Enter;
  try
    SetLength(Result, FLines.Count);
    for I := 0 to FLines.Count - 1 do
      Result[I] := FLines[I];
    FLines.Clear;
  finally
    FLock.Leave;
  end;
end;

initialization
  IperfWinsockStartup;

finalization
  IperfWinsockCleanup;

end.
