{*******************************************************************************
  uIperfWorker.pas  -  数据面工作线程

  对应 iperf3 的：
    * src/iperf_tcp.c  -> TTcpSendThread / TTcpRecvThread
    * src/iperf_udp.c  -> TUdpSendThread / TUdpRecvThread
    * src/iperf_api.c 的 interval 机制 -> TIperfSessionStats

  设计要点：
    1. 每个数据连接 = 1~2 个线程。TCP 是全双工的，双向测试时同一 socket 上
       收发各用一个线程，互不干扰。
    2. 所有数据 socket 设为非阻塞，用 select 等待。这样每 50ms 内一定能检查到
       "测试是否到点"，不会像阻塞 send 那样卡住无法停止。
    3. 计数用 TInterlocked 原子累加，采样线程独立读快照，互不阻塞。
    4. 测试到点后发送方 shutdown(SD_SEND)，接收方把缓冲区里剩余数据 drain 干净
       再退出，保证两端字节数一致。

  适用：Delphi 10.2 Tokyo 及以上
*******************************************************************************}
unit uIperfWorker;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Math,
  Winapi.Windows, Winapi.Winsock2, uIperfCommon;

type
  PUdpHeader = ^TUdpHeader;

  {============================================================================
    TIperfSessionStats - 一次测试会话的统计容器
    客户端 / 服务端各持有一个，把本端观察到的收发量汇总成 TReportPacket
  ============================================================================}
  TIperfSessionStats = class
  private
    FCounters    : TIperfCounters;
    FSampler     : TIperfSampler;
    FLog         : TIperfLog;
    FLock        : TCriticalSection;
    FMode        : TIperfMode;
    FDirection   : TIperfDirection;
    FStreams     : Integer;
    FBlockSize   : Cardinal;
    FIntervalMs  : Int64;
    FDurationMs  : Int64;
    FOnSample    : TSampleProc;
    FStartTick   : UInt64;
    FEndTick     : UInt64;
    FStarted     : Boolean;
    FSawEndTick  : Boolean;
    FCookie      : TGUID;     // 会话标识
    FPeer        : string;    // 对端 "IP:Port"
    FBlockedCnt  : Int64;     // 发送时因"发送缓冲区满"被迫等待的次数
    FBlockedMs   : Int64;     // 上面这些等待累计的毫秒数
  public
    constructor Create(const AMode: TIperfMode; const ADir: TIperfDirection;
      const AStreams: Integer; const ABlockSize: Cardinal;
      const ADurationMs, AIntervalMs: Int64; const AOnSample: TSampleProc);
    destructor Destroy; override;

    { 标记会话身份；逐秒采样和结束报告都会带上
      须在 StartSampling 之前调用（服务端多点并发时必须调用，否则无法区分来源） }
    procedure SetIdentity(const ACookie: TGUID; const APeer: string);

    { 数据面正式开跑的时刻：锁定起止时间（只生效一次） }
    procedure MarkDataStart;
    procedure StartSampling;
    procedure StopSampling;

    { 发送线程报告一次「缓冲区满 -> 等可写」。次数多 = 发送端被链路/对端接收限住了，
      次数为 0 = 发送端自己没被堵（瓶颈在发送端自身，比如 CPU）。 }
    procedure NoteSendBlocked(const WaitMs: Integer);

    function Snapshot: TReportPacket;
    function ElapsedMs: Int64;
    function IsFinished: Boolean;

    property Counters: TIperfCounters read FCounters;
    property Log: TIperfLog read FLog;
    property Mode: TIperfMode read FMode;
    property Direction: TIperfDirection read FDirection;
    property Streams: Integer read FStreams;
    property BlockSize: Cardinal read FBlockSize;
    property DurationMs: Int64 read FDurationMs;
    property IntervalMs: Int64 read FIntervalMs;
    property StartTick: UInt64 read FStartTick;
    property EndTick: UInt64 read FEndTick;
    property SendBlockedCount: Int64 read FBlockedCnt;
    property SendBlockedMs: Int64 read FBlockedMs;
  end;

  {============================================================================
    TCP 发送线程（对应 iperf_tcp_send）：测试时长内不停写 BlockSize 数据块
  ============================================================================}
  TTcpSendThread = class(TThread)
  private
    FSocket: TSocket;
    FStats : TIperfSessionStats;
    FStop  : TEvent;
    FBuf   : PByte;
    FSize  : Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASocket: TSocket; const AStats: TIperfSessionStats;
      const AStop: TEvent);
    destructor Destroy; override;
  end;

  {============================================================================
    TCP 接收线程（对应 iperf_tcp_recv）
  ============================================================================}
  TTcpRecvThread = class(TThread)
  private
    FSocket : TSocket;
    FStats  : TIperfSessionStats;
    FStop   : TEvent;
    FBuf    : PByte;
    FSize   : Integer;
    FDrainMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASocket: TSocket; const AStats: TIperfSessionStats;
      const AStop: TEvent; const ADrainMs: Integer = 3000);
    destructor Destroy; override;
  end;

  {============================================================================
    UDP 发送线程：按目标带宽定速发送，每包带序号和时间戳
  ============================================================================}
  TUdpSendThread = class(TThread)
  private
    FSocket   : TSocket;
    FPeer     : TSockAddr;
    FStats    : TIperfSessionStats;
    FStop     : TEvent;
    FCookie   : TGUID;
    FStream   : Cardinal;
    FPayload  : Cardinal;
    FTotal    : Integer;
    FTargetBps: Int64;
    FBuf      : PByte;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASocket: TSocket; const APeer: TSockAddr;
      const AStats: TIperfSessionStats; const AStop: TEvent;
      const ACookie: TGUID; const AStream: Cardinal;
      const APayload: Cardinal; const ATargetBps: Int64);
    destructor Destroy; override;
  end;

  {============================================================================
    UDP 接收线程：统计报文数 / 字节 / 丢包 / 抖动
  ============================================================================}
  TUdpRecvThread = class(TThread)
  private
    FSocket : TSocket;
    FStats  : TIperfSessionStats;
    FStop   : TEvent;
    FDrainMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASocket: TSocket; const AStats: TIperfSessionStats;
      const AStop: TEvent; const ADrainMs: Integer = 2000);
  end;

{==============================================================================
  UDP 握手工具：发 hello(-1) 等 ack(-2)，用于让服务端学到客户端 UDP 端点
==============================================================================}
function UdpSendHello(const Sock: TSocket; const Peer: TSockAddr;
  const Cookie: TGUID; const Stream: Cardinal;
  const Retry, TimeoutMs: Integer): Boolean;

{ 构造一个已填好内容的数据块（测试用，非全零便于抓包识别） }
function AllocPayload(const Size: Integer): PByte;

implementation

{==============================================================================
  工具
==============================================================================}
function AllocPayload(const Size: Integer): PByte;
var
  I: Integer;
begin
  if Size <= 0 then
    Exit(nil);
  GetMem(Result, Size);
  for I := 0 to Size - 1 do
    Result[I] := Byte(I and $FF);
end;

{==============================================================================
  TIperfSessionStats
==============================================================================}
constructor TIperfSessionStats.Create(const AMode: TIperfMode;
  const ADir: TIperfDirection; const AStreams: Integer; const ABlockSize: Cardinal;
  const ADurationMs, AIntervalMs: Int64; const AOnSample: TSampleProc);
begin
  inherited Create;
  FMode       := AMode;
  FDirection  := ADir;
  FStreams    := AStreams;
  if FStreams < 1 then
    FStreams := 1;
  FBlockSize  := ABlockSize;
  FDurationMs := ADurationMs;
  if FDurationMs < 100 then
    FDurationMs := 100;
  FIntervalMs := AIntervalMs;
  if FIntervalMs < 100 then
    FIntervalMs := 1000;
  FOnSample   := AOnSample;

  FCounters := TIperfCounters.Create;
  FLog      := TIperfLog.Create;
  FLock     := TCriticalSection.Create;

  FStartTick := IperfTickMs;
  FEndTick   := FStartTick + UInt64(FDurationMs);
  FStarted   := False;
  FSawEndTick := False;
  FBlockedCnt := 0;
  FBlockedMs  := 0;
  FillChar(FCookie, SizeOf(FCookie), 0);
  FPeer      := '';
end;

procedure TIperfSessionStats.NoteSendBlocked(const WaitMs: Integer);
begin
  TInterlocked.Increment(FBlockedCnt);
  if WaitMs > 0 then
    TInterlocked.Add(FBlockedMs, WaitMs);
end;

destructor TIperfSessionStats.Destroy;
begin
  StopSampling;
  FLock.Free;
  FLog.Free;
  FCounters.Free;
  inherited;
end;

procedure TIperfSessionStats.MarkDataStart;
begin
  FLock.Enter;
  try
    if not FStarted then
    begin
      FStarted   := True;
      FStartTick := IperfTickMs;
      FEndTick   := FStartTick + UInt64(FDurationMs);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TIperfSessionStats.StartSampling;
begin
  StopSampling;
  FSampler := TIperfSampler.Create(FCounters, FIntervalMs, FOnSample, FDurationMs);
  FSampler.SetIdentity(FCookie, FPeer);
  FSampler.Start;
end;

procedure TIperfSessionStats.SetIdentity(const ACookie: TGUID;
  const APeer: string);
begin
  FLock.Enter;
  try
    FCookie := ACookie;
    FPeer   := APeer;
    if FSampler <> nil then
      FSampler.SetIdentity(ACookie, APeer);
  finally
    FLock.Leave;
  end;
end;

procedure TIperfSessionStats.StopSampling;
var
  T: TIperfSampler;
begin
  T := FSampler;
  FSampler := nil;
  if T = nil then
    Exit;
  T.Stop;
  T.WaitFor;
  T.Free;
end;

function TIperfSessionStats.ElapsedMs: Int64;
var
  NowTick: UInt64;
begin
  NowTick := IperfTickMs;
  if NowTick > FEndTick then
    Result := Int64(FEndTick - FStartTick)
  else
    Result := Int64(NowTick - FStartTick);
  if Result <= 0 then
    Result := 1;
end;

function TIperfSessionStats.IsFinished: Boolean;
begin
  Result := IperfTickMs >= FEndTick;
end;

function TIperfSessionStats.Snapshot: TReportPacket;
var
  El: Int64;
begin
  El := ElapsedMs;
  FillChar(Result, SizeOf(Result), 0);
  Result.Magic      := IPERF_MAGIC;
  Result.Kind       := Ord(pkReport);
  Result.Mode       := Ord(FMode);
  Result.Direction  := Ord(FDirection);
  Result.Streams    := FStreams;
  Result.SentBytes  := FCounters.SentBytes;
  Result.SentChunks := FCounters.SentChunks;
  Result.RecvBytes  := FCounters.RecvBytes;
  Result.RecvChunks := FCounters.RecvChunks;
  Result.LostChunks := FCounters.LostChunks;
  Result.ElapsedMs  := El;
  Result.JitterUs   := FCounters.JitterUs;
  Result.BlockSize  := FBlockSize;
  { 优先用会话身份里的 Cookie（调用方仍可覆盖） }
  if FCookie.D1 <> 0 then
    Result.Cookie := FCookie;
end;

{==============================================================================
  TTcpSendThread
==============================================================================}
constructor TTcpSendThread.Create(const ASocket: TSocket;
  const AStats: TIperfSessionStats; const AStop: TEvent);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSocket := ASocket;
  FStats  := AStats;
  FStop   := AStop;
  FSize   := Integer(AStats.BlockSize);
  if FSize < 1024 then
    FSize := 1024;
  FBuf := AllocPayload(FSize);
end;

destructor TTcpSendThread.Destroy;
begin
  if FBuf <> nil then
    FreeMem(FBuf);
  inherited;
end;

procedure TTcpSendThread.Execute;
var
  Off, N, Err: Integer;
  T0, WaitMs : UInt64;
begin
  Off := 0;
  while not Terminated do
  begin
    if IperfTickMs >= FStats.EndTick then
      Break;
    if FStop.WaitFor(0) = wrSignaled then
      Break;

    N := send(FSocket, (FBuf + Off)^, FSize - Off, 0);
    if N > 0 then
    begin
      Inc(Off, N);
      FStats.Counters.IncSent(N);
      if Off >= FSize then
        Off := 0;
      Continue;
    end;

    if N = SOCKET_ERROR then
    begin
      Err := WSAGetLastError;
      if Err = WSAEWOULDBLOCK then
      begin
        { 发送缓冲区满了：等可写，最多等 20ms 就回来重新判断是否到点。
          这里的等待次数/时长会累计进统计对象，出结果时能看出
          "是本端发得太快被堵，还是链路/对端接收能力就只有这么多"。 }
        T0 := IperfTickMs;
        WaitWritable(FSocket, 20);
        WaitMs := IperfTickMs - T0;
        FStats.NoteSendBlocked(Integer(WaitMs));
      end
      else
        Break;
    end
    else
      Break;
  end;
  { 通知对端"我不再发了"，对端 recv 会拿到 0 从而把残留数据收完 }
  shutdown(FSocket, SD_SEND);
end;

{==============================================================================
  TTcpRecvThread
==============================================================================}
constructor TTcpRecvThread.Create(const ASocket: TSocket;
  const AStats: TIperfSessionStats; const AStop: TEvent; const ADrainMs: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSocket  := ASocket;
  FStats   := AStats;
  FStop    := AStop;
  FDrainMs := ADrainMs;
  FSize    := Integer(AStats.BlockSize) * 2;
  if FSize < 65536 then
    FSize := 65536;
  FBuf := AllocPayload(FSize);
  Priority := tpHigher;
end;

destructor TTcpRecvThread.Destroy;
begin
  if FBuf <> nil then
    FreeMem(FBuf);
  inherited;
end;

procedure TTcpRecvThread.Execute;
var
  N, Err  : Integer;
  Draining: Boolean;
  DrainEnd: UInt64;
begin
  Draining := False;
  DrainEnd := 0;
  while not Terminated do
  begin
    if IperfTickMs >= FStats.EndTick then
    begin
      { 到点了，但先把内核/网络里还在路上的数据收干净再退出 }
      if not Draining then
      begin
        Draining := True;
        DrainEnd := IperfTickMs + UInt64(FDrainMs);
      end
      else if IperfTickMs >= DrainEnd then
        Break;
    end
    else if FStop.WaitFor(0) = wrSignaled then
      Break;

    N := recv(FSocket, FBuf^, FSize, 0);
    if N > 0 then
    begin
      FStats.Counters.IncRecv(N);
      Continue;
    end;
    if N = 0 then
      Break;                          // 对端 shutdown(SD_SEND)，数据已收完
    Err := WSAGetLastError;
    if Err = WSAEWOULDBLOCK then
    begin
      if FStop.WaitFor(0) = wrSignaled then
        Break;
      WaitReadable(FSocket, 20);
    end
    else
      Break;
  end;
end;

{==============================================================================
  TUdpSendThread
==============================================================================}
constructor TUdpSendThread.Create(const ASocket: TSocket; const APeer: TSockAddr;
  const AStats: TIperfSessionStats; const AStop: TEvent; const ACookie: TGUID;
  const AStream: Cardinal; const APayload: Cardinal; const ATargetBps: Int64);
var
  Hdr: PUdpHeader;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSocket    := ASocket;
  FPeer      := APeer;
  FStats     := AStats;
  FStop      := AStop;
  FCookie    := ACookie;
  FStream    := AStream;
  FPayload   := APayload;
  FTargetBps := ATargetBps;
  FTotal     := SizeOf(TUdpHeader) + Integer(FPayload);

  FBuf := AllocPayload(FTotal);
  if FBuf <> nil then
  begin
    Hdr := PUdpHeader(FBuf);
    Hdr^.Cookie := FCookie;
    Hdr^.Stream := FStream;
  end;
end;

destructor TUdpSendThread.Destroy;
begin
  if FBuf <> nil then
    FreeMem(FBuf);
  inherited;
end;

procedure TUdpSendThread.Execute;
var
  Hdr     : PUdpHeader;
  N, Err  : Integer;
  Allowed : Int64;
  Sent    : Int64;
  Seq     : Int64;
  StartTick, NowTick: UInt64;
begin
  if FBuf = nil then
    Exit;
  Hdr       := PUdpHeader(FBuf);
  StartTick := IperfTickMs;
  Sent      := 0;
  Seq       := 0;

  while not Terminated do
  begin
    NowTick := IperfTickMs;
    if NowTick >= FStats.EndTick then
      Break;
    if FStop.WaitFor(0) = wrSignaled then
      Break;

    { 定速：按已流逝时间算出"允许发多少字节"，多发一个包的水位 }
    if FTargetBps > 0 then
    begin
      Allowed := Int64(NowTick - StartTick) * FTargetBps div 8000 + Int64(FPayload);
      if Sent >= Allowed then
      begin
        FStop.WaitFor(1);
        Continue;
      end;
    end;

    Hdr^.Seq    := Seq;
    Hdr^.TickMs := Int64(NowTick);

    N := sendto(FSocket, FBuf^, FTotal, 0, @FPeer, SizeOf(FPeer));
    if N > 0 then
    begin
      Inc(Sent, Int64(FPayload));
      FStats.Counters.IncSent(FPayload);   { 统计只算 payload，不含 36 字节包头 }
      Inc(Seq);
    end
    else if N = SOCKET_ERROR then
    begin
      Err := WSAGetLastError;
      if Err <> WSAEWOULDBLOCK then
        Break;
      FStop.WaitFor(1);
    end;
  end;
end;

{==============================================================================
  TUdpRecvThread
==============================================================================}
constructor TUdpRecvThread.Create(const ASocket: TSocket;
  const AStats: TIperfSessionStats; const AStop: TEvent; const ADrainMs: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSocket  := ASocket;
  FStats   := AStats;
  FStop    := AStop;
  FDrainMs := ADrainMs;
end;

procedure TUdpRecvThread.Execute;
const
  BUFSZ = 65536;
var
  Buf      : array[0..BUFSZ - 1] of Byte;
  From     : TSockAddr;
  N, Alen  : Integer;
  Hdr      : PUdpHeader;
  Transit  : Int64;
  Delta    : Double;
  Jitter   : Double;
  LastTran : Int64;
  HaveLast : Boolean;
  Expected : Int64;
  Draining : Boolean;
  DrainEnd : UInt64;
begin
  Jitter    := 0;
  LastTran  := 0;
  HaveLast  := False;
  Expected  := 0;
  Draining  := False;
  DrainEnd  := 0;

  while not Terminated do
  begin
    if IperfTickMs >= FStats.EndTick then
    begin
      if not Draining then
      begin
        Draining := True;
        DrainEnd := IperfTickMs + UInt64(FDrainMs);
      end
      else if IperfTickMs >= DrainEnd then
        Break;
    end
    else if FStop.WaitFor(0) = wrSignaled then
      Break;

    Alen := SizeOf(From);
    N := recvfrom(FSocket, Buf[0], BUFSZ, 0, From, Alen);
    if N >= SizeOf(TUdpHeader) then
    begin
      Hdr := PUdpHeader(@Buf[0]);
      if Hdr^.Seq >= 0 then
      begin
        { --- 丢包估算（按序号缺口，TCP 无此逻辑） --- }
        if Hdr^.Seq > Expected then
        begin
          FStats.Counters.AddLost(Hdr^.Seq - Expected);
          Expected := Hdr^.Seq + 1;
        end
        else if Hdr^.Seq = Expected then
          Inc(Expected);

        { --- 抖动：RFC1889 那套 J += (|D| - J) / 16 --- }
        Transit := Int64(IperfTickMs) - Hdr^.TickMs;
        if HaveLast then
        begin
          Delta  := Abs(Transit - LastTran);
          Jitter := Jitter + (Delta - Jitter) / 16.0;
          FStats.Counters.SetJitterUs(Round(Jitter * 1000));
        end;
        LastTran := Transit;
        HaveLast := True;

        FStats.Counters.IncRecv(N - SizeOf(TUdpHeader));
      end;
    end
    else if N = SOCKET_ERROR then
    begin
      if WSAGetLastError <> WSAEWOULDBLOCK then
        Break;
      if FStop.WaitFor(0) = wrSignaled then
        Break;
      WaitReadable(FSocket, 20);
    end;
  end;
end;

{==============================================================================
  UdpSendHello
==============================================================================}
function UdpSendHello(const Sock: TSocket; const Peer: TSockAddr;
  const Cookie: TGUID; const Stream: Cardinal;
  const Retry, TimeoutMs: Integer): Boolean;
var
  Buf : array[0..127] of Byte;
  Hdr : PUdpHeader;
  From: TSockAddr;
  I, N, Alen: Integer;
begin
  Result := False;
  FillChar(Buf, SizeOf(Buf), 0);
  Hdr := PUdpHeader(@Buf[0]);
  Hdr^.Cookie := Cookie;
  Hdr^.Stream := Stream;
  Hdr^.Seq    := UDP_HELLO;
  Hdr^.TickMs := Int64(IperfTickMs);

  for I := 1 to Retry do
  begin
    N := sendto(Sock, Buf[0], SizeOf(TUdpHeader), 0, @Peer, SizeOf(Peer));
    if N = SOCKET_ERROR then
      Exit;
    if not WaitReadable(Sock, TimeoutMs) then
      Continue;
    Alen := SizeOf(From);
    N := recvfrom(Sock, Buf[0], SizeOf(Buf), 0, From, Alen);
    if N >= SizeOf(TUdpHeader) then
    begin
      Hdr := PUdpHeader(@Buf[0]);
      if (Hdr^.Seq = UDP_HELLO_ACK) and IsEqualGUID(Hdr^.Cookie, Cookie) then
        Exit(True);
    end;
  end;
end;

end.
