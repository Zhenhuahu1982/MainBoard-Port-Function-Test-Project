{*******************************************************************************
  uIperfClientApi.pas  -  Delphi 版 iperf 客户端调用接口（无界面）

  把 uIperfClient 的"控制连接 + N 条数据连接 + 报告交换"流程封装成
  "一次函数调用 = 跑完一次测试并拿到带宽"，不需要任何窗体、不需要消息循环，
  可以直接嵌进控制台程序、服务程序或别的 GUI 工程里。

  默认参数（不传就用这些）：
      服务器 IP   127.0.0.1
      端口        5201
      协议        TCP
      方向        客户端 -> 服务端
      时长        10 秒
      并发流      1
      块大小      131072 字节（128 KB）

  ---- 平均值（每秒发了多少）--------------------------------------------------
      结果里除了"一次测试的收发总量/总带宽"，还会把平均值一起返回：
          R.AvgSentBytesPerSec   // 平均每秒发送的字节数 = LocalSentBytes / 实测秒数
          R.AvgSentBlocksPerSec  // 平均每秒发送的块数   = 实际发送次数 / 实测秒数
          R.AvgRecvBytesPerSec   // 平均每秒接收的字节数
          R.AvgRecvBlocksPerSec  // 平均每秒接收的块数
      比如跑 10 秒、发了 10 个 1 秒区间，这两个数就是"这 10 个数加起来除以 10"，
      和 LocalSentBytes / 10 等价。
      另外逐秒明细也一起带回来了，想自己看曲线或者重算别的平均都可以：
          R.Samples              // 第 1 秒、第 2 秒 … 每条的 SentBytes / SentChunks
          R.SentBytesPerSecond   // 只取逐秒字节数的数组
          R.SentBlocksPerSecond  // 只取逐秒块数的数组
          R.AverageText          // 一行文本摘要

  ---- 和 iperf3 数值对不上时 -------------------------------------------------
      结论先说：带宽低通常是**接收窗口**被限住了，不是统计口径不同（两边都是
      1024 进制的 MBytes，都是应用层字节）。
      吞吐上限 = 接收窗口 / RTT，1 Gbit/s 需要窗口 >= 125000 * RTT(ms) 字节。
      本单元默认不动 socket 缓冲区（SocketBufKB = 0，交给 Windows 自动调优，
      和 iperf3 一样）；如果你手工填了值，就会关掉自动调优，反而可能更慢。
      看不出来是谁在限速时，看诊断字段：
          R.DiagnosticText       // 一行：缓冲区设置 + 发送受阻次数/累计等待
          R.SendBlockedCount     // >0 且很大 → 发送端被链路/对端接收限住
          R.SendBlockedMs        // 这些等待一共花了多少毫秒
          R.SocketBufKB          // 本次实际用的缓冲区设置（0 = 自动）

  ---- 双向测试为什么是 2 倍连接 ---------------------------------------------
      双向（idBidir）时每条流会建 **两条** TCP 数据连接：一条只发、一条只收，
      和 iperf3 的 --bidir 完全一致（iperf3 在 BIDIRECTIONAL 时会连着调两次
      iperf_create_streams，一次 sender=1、一次 sender=0）。
      原因：同一条 TCP 连接上同时灌两个方向的数据时，两个方向会互相抢 ACK 和
      接收窗口，双向吞吐会被拖得明显低于 iperf3；拆成两条独立连接后，每个方向
      各有自己的接收窗口和 ACK 通道，单方向速度就和"只跑单向"时基本一致了。
      UDP 没有流控，双向仍共用 1 个 socket，不受影响。

      但请注意链路总带宽是死的：1 Gbit/s 的链路，双向合计也上不去 ~950 Mbit/s，
      所以双向时"每一个方向"的带宽低于单向测试是正常的（iperf3 也一样），
      要比就统一跟 iperf3 --bidir 比。
      实际开了几条连接看这几个字段：
          R.DataConnCount / R.SendConnCount / R.RecvConnCount

  ---- 用法一：最省事，全部默认 ----------------------------------------------
      uses uIperfClientApi;
      var R: TIperfResult;
      R := IperfTest;                       // 阻塞约 10 秒
      if R.Ok then WriteLn(R.BandwidthText) // 发送 1.02 Gbits/sec / 接收 0 bits/sec
      else WriteLn(R.Error);

  ---- 用法二：只改其中几项 --------------------------------------------------
      // IperfTest(服务器IP, 端口, 协议, 方向, 时长, 并发流, 块大小, 报表间隔, UDP速率, socket缓冲区KB)
      R := IperfTest('192.168.1.10');                       // 只换 IP
      R := IperfTest('192.168.1.10', 5201, imTCP, idNormal, 5);
      R := IperfTest('192.168.1.10', 5201, imUDP, idBidir, 10, 4, 1400);

      // 参数记不住顺序就用 MakeOptions（同样是可选的，不填就走默认值）
      R := IperfTest(MakeOptions('192.168.1.10', 5201, imTCP, idNormal, 10, 1, 131072));

  ---- 用法三：不想卡住调用线程（游戏服务端/界面里推荐） ---------------------
      var Sess: TIperfTestSession;
      Sess := TIperfTestSession.Create(MakeOptions('192.168.1.10'));
      Sess.Start;
      while not Sess.Done do Sleep(50);     // 也可以 Sess.WaitFor(30000)
      R := Sess.CurrentResult;
      Sess.Free;
      // 跑的过程中随时可以 Sess.Abort 中止

  说明：
    * 测试跑的是本工程的自有协议，两端都用本工程（服务端 = DelphiIperf.exe）。
      服务端开着就可以，客户端这边跑多少次都行。
    * 带宽单位都是 bit/s，格式化输出用 FormatBitrate（自动进位到 Mbits/sec）。
    * 结果里本端（客户端）和对端（服务端）的收发量、带宽都有，
      TotalBps = 本端发送 + 本端接收 的合计带宽。

  适用：Delphi 10.2 Tokyo 及以上（本单元是纯逻辑单元，不含任何 VCL 依赖）
*******************************************************************************}
unit uIperfClientApi;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  Winapi.Windows,
  uIperfCommon, uIperfWorker, uIperfClient;

const
  { ---- 客户端默认参数（需求给定的那一组） ---- }
  IPERF_DEFAULT_HOST        = '127.0.0.1';        // 默认服务器 IP
  IPERF_DEFAULT_CLI_PORT    = 5201;               // 默认服务器端口
  IPERF_DEFAULT_CLI_STREAMS = 1;                  // 默认并发流
  IPERF_DEFAULT_CLI_BLOCK   = 131072;             // 默认块大小 128 KB
  IPERF_DEFAULT_CLI_SECONDS = 10;                 // 默认时长 10 秒
  IPERF_DEFAULT_INTERVAL_MS = 1000;               // 逐秒回调间隔

  { WaitFor 用的"一直等" }
  IPERF_WAIT_FOREVER        = Cardinal($FFFFFFFF);

type
  {============================================================================
    一次测试的参数。用 DefaultOptions / MakeOptions 构造，之后字段随便改。
  ============================================================================}
  TIperfOptions = record
    Host       : string;           // 服务器 IP / 主机名，默认 127.0.0.1
    Port       : Integer;          // 服务器端口，默认 5201
    Mode       : TIperfMode;       // 协议：imTCP / imUDP，默认 imTCP
    Direction  : TIperfDirection;  // 方向：idNormal(客户端->服务端) / idReverse / idBidir
    DurationSec: Integer;          // 时长(秒)，默认 10
    Streams    : Integer;          // 并发流数，默认 1
    BlockSize  : Integer;          // 块大小(字节)，默认 131072；UDP 会被限制到 1400
    IntervalMs : Integer;          // 报表间隔(毫秒)，默认 1000，只影响逐秒回调
    TargetBps  : Int64;            // UDP 目标速率(bit/s)，0 = 用默认 10 Mbit/s
    { 数据 socket 缓冲区(KB)。0（默认）= 不动它，交给 Windows 自动调优接收窗口，
      和 iperf3 的行为一致。填 >0 才会显式设置 SO_SNDBUF/SO_RCVBUF，
      注意那会关掉 Windows 的窗口自动调优，吞吐会被卡在「窗口/RTT」上：
          1 Gbit/s 需要 窗口 >= 125000 * RTT(ms) 字节
      只有在确认链路 RTT 很大时再手工调（比如 2048）。 }
    SocketBufKB: Integer;
  end;

  {============================================================================
    一次测试的结果：本端/对端各自的收发量与带宽，外加"每秒平均"的统计
  ============================================================================}
  TIperfResult = record
    Ok             : Boolean;      // True = 测试正常跑完并拿到双方报告
    Error          : string;       // Ok=False 时的原因（连不上、对端无响应…）
    Host           : string;
    Port           : Integer;
    Mode           : TIperfMode;
    Direction      : TIperfDirection;
    Streams        : Integer;
    BlockSize      : Integer;
    ElapsedMs      : Int64;        // 本端实测耗时
    Seconds        : Double;       // 本端实测秒数 = ElapsedMs / 1000

    LocalSentBytes : Int64;        // 本端(客户端)发出的字节
    LocalSentChunks: Int64;        // 本端(客户端)发出的次数(块数)
    LocalRecvBytes : Int64;        // 本端(客户端)收到的字节
    LocalRecvChunks: Int64;        // 本端(客户端)收到的次数(块数)
    LocalSentBps   : Double;       // 本端发送总带宽 bit/s
    LocalRecvBps   : Double;       // 本端接收总带宽 bit/s

    PeerSentBytes  : Int64;        // 对端(服务端)发出的字节
    PeerSentChunks : Int64;
    PeerRecvBytes  : Int64;        // 对端(服务端)收到的字节
    PeerRecvChunks : Int64;
    PeerSentBps    : Double;
    PeerRecvBps    : Double;

    TotalBps       : Double;       // 合计带宽 = 本端发送 + 本端接收

    { ---- 平均值：平均每秒发了多少（跑 10 秒就是"这 10 秒一共 / 10"） ---- }
    AvgSentBytesPerSec  : Double;  // 平均每秒发送字节数 = LocalSentBytes / Seconds
    AvgSentBlocksPerSec : Double;  // 平均每秒发送块数   = LocalSentChunks / Seconds
    AvgRecvBytesPerSec  : Double;  // 平均每秒接收字节数
    AvgRecvBlocksPerSec : Double;  // 平均每秒接收块数

    { ---- 诊断（和 iperf3 数值对不上时看这几个）---- }
    SocketBufKB       : Integer;   // 本次用的数据 socket 缓冲区(KB)，0 = 系统自动调优
    SendBlockedCount  : Int64;     // 发送时"发送缓冲区满 -> 等可写"的次数
    SendBlockedMs     : Int64;     // 上面这些等待累计的毫秒数

    { ---- 数据连接（TCP 双向 = 每流 2 条：一条只发、一条只收）---- }
    DataConnCount     : Integer;   // 本次建立的数据连接条数
    SendConnCount     : Integer;   // 其中本端负责"发"的连接数
    RecvConnCount     : Integer;   // 其中本端负责"收"的连接数

    { ---- 逐秒明细（第 1 秒、第 2 秒 …）：想自己看曲线或重算别的平均用 ---- }
    Samples           : TArray<TIntervalSample>;
    SampleSpanMs      : Int64;     // 采样覆盖的总时长（≈ ElapsedMs）
    SampleSentBytes   : Int64;     // 采样里的每秒发送字节合计
    SampleSentChunks  : Int64;
    SampleRecvBytes   : Int64;
    SampleRecvChunks  : Int64;

    Local          : TReportPacket; // 本端原始统计包（想要更细的数据读这个）
    Peer           : TReportPacket; // 对端原始统计包

    { "发送 1.02 Gbits/sec / 接收 0 bits/sec" 一行文本 }
    function BandwidthText: string;
    { 平均每秒发送/接收多少字节、多少块，一行文本 }
    function AverageText: string;
    { 一行诊断：socket 缓冲区设置 + 发送受阻次数（判断瓶颈在发送端还是链路/对端） }
    function DiagnosticText: string;
    { 逐秒发送字节数（第 1 秒、第 2 秒 …），失败时为空数组 }
    function SentBytesPerSecond: TArray<Int64>;
    { 逐秒发送块数（第 1 秒、第 2 秒 …），失败时为空数组 }
    function SentBlocksPerSecond: TArray<Int64>;
    { 一行完整摘要（含 IP/端口/协议/方向、两端带宽和平均值） }
    function Summary: string;
  end;

  {============================================================================
    逐秒采样收集器：内部用它把测试过程中的每个 1 秒区间攒起来，
    填进 TIperfResult.Samples，从而算出平均值。
    采样在线程里发生，所以这里自己加了锁；外部要用也可以，Add/Snapshot 都是
    线程安全的。
  ============================================================================}
  TIperfSampleCollector = class
  private
    FLock : TCriticalSection;
    FItems: TArray<TIntervalSample>;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const S: TIntervalSample);
    function  Snapshot: TArray<TIntervalSample>;
    property  Count: Integer read GetCount;
  end;

{ ---- 默认参数 ---- }
function DefaultOptions: TIperfOptions;

{ 构造参数，每一项都能省（省略 = 用默认值） }
function MakeOptions(const Host: string = IPERF_DEFAULT_HOST;
  const Port: Integer = IPERF_DEFAULT_CLI_PORT;
  const Mode: TIperfMode = imTCP;
  const Direction: TIperfDirection = idNormal;
  const DurationSec: Integer = IPERF_DEFAULT_CLI_SECONDS;
  const Streams: Integer = IPERF_DEFAULT_CLI_STREAMS;
  const BlockSize: Integer = IPERF_DEFAULT_CLI_BLOCK;
  const IntervalMs: Integer = IPERF_DEFAULT_INTERVAL_MS;
  const TargetBps: Int64 = 0;
  const SocketBufKB: Integer = IPERF_DEFAULT_SOCK_BUF_KB): TIperfOptions;

{==============================================================================
  跑一次测试（阻塞到跑完为止），返回收发总带宽。
  两种调用形式等价：IperfTest(Options) / IperfTest(Host, Port, Mode, ...)
==============================================================================}
function IperfTest(const Options: TIperfOptions): TIperfResult; overload;
function IperfTest(const Host: string = IPERF_DEFAULT_HOST;
  const Port: Integer = IPERF_DEFAULT_CLI_PORT;
  const Mode: TIperfMode = imTCP;
  const Direction: TIperfDirection = idNormal;
  const DurationSec: Integer = IPERF_DEFAULT_CLI_SECONDS;
  const Streams: Integer = IPERF_DEFAULT_CLI_STREAMS;
  const BlockSize: Integer = IPERF_DEFAULT_CLI_BLOCK;
  const IntervalMs: Integer = IPERF_DEFAULT_INTERVAL_MS;
  const TargetBps: Int64 = 0;
  const SocketBufKB: Integer = IPERF_DEFAULT_SOCK_BUF_KB): TIperfResult; overload;

{==============================================================================
  非阻塞版本：Start 之后立刻返回，调用线程自己轮询 Done 或等 WaitFor
  （这是个很薄的包装，真正的干活线程是 uIperfClient.TIperfClientThread）
==============================================================================}
type
  TIperfTestSession = class
  private
    FOptions  : TIperfOptions;
    FThread   : TIperfClientThread;
    FCollector: TIperfSampleCollector;
    FStarted  : Boolean;
    function GetDone: Boolean;
    function GetRunning: Boolean;
  public
    constructor Create(const Options: TIperfOptions);
    destructor Destroy; override;

    { 发起测试，立刻返回；重复调用无副作用 }
    procedure Start;
    { 停在指定毫秒内跑完；返回 False 表示等到超时还没结束 }
    function  WaitFor(const TimeoutMs: Cardinal = IPERF_WAIT_FOREVER): Boolean;
    { 中止（已经结束就什么都不做） }
    procedure Abort;

    { 取当前结果；没跑完时 Ok=False、Error='测试尚未完成'。
      跑的过程中也可以随时读，Samples 是当时已经攒到的逐秒数据 }
    function  CurrentResult: TIperfResult;

    { 已经攒到的逐秒采样（跑的过程中也能读） }
    function  CurrentSamples: TArray<TIntervalSample>;

    property Options: TIperfOptions read FOptions;
    property Done: Boolean read GetDone;
    property Running: Boolean read GetRunning;
  end;

implementation

{==============================================================================
  参数处理
==============================================================================}
function DefaultOptions: TIperfOptions;
begin
  Result.Host        := IPERF_DEFAULT_HOST;
  Result.Port        := IPERF_DEFAULT_CLI_PORT;
  Result.Mode        := imTCP;
  Result.Direction   := idNormal;
  Result.DurationSec := IPERF_DEFAULT_CLI_SECONDS;
  Result.Streams     := IPERF_DEFAULT_CLI_STREAMS;
  Result.BlockSize   := IPERF_DEFAULT_CLI_BLOCK;
  Result.IntervalMs  := IPERF_DEFAULT_INTERVAL_MS;
  Result.TargetBps   := 0;
  Result.SocketBufKB := IPERF_DEFAULT_SOCK_BUF_KB;
end;

function MakeOptions(const Host: string; const Port: Integer;
  const Mode: TIperfMode; const Direction: TIperfDirection;
  const DurationSec, Streams, BlockSize, IntervalMs: Integer;
  const TargetBps: Int64; const SocketBufKB: Integer): TIperfOptions;
begin
  Result.Host        := Host;
  Result.Port        := Port;
  Result.Mode        := Mode;
  Result.Direction   := Direction;
  Result.DurationSec := DurationSec;
  Result.Streams     := Streams;
  Result.BlockSize   := BlockSize;
  Result.IntervalMs  := IntervalMs;
  Result.TargetBps   := TargetBps;
  Result.SocketBufKB := SocketBufKB;
end;

{ 越界/留空的参数补成默认值，保证底层拿到的一定是合法值 }
function NormalizeOptions(const O: TIperfOptions): TIperfOptions;
begin
  Result := O;

  if Trim(Result.Host) = '' then
    Result.Host := IPERF_DEFAULT_HOST;
  if (Result.Port < 1) or (Result.Port > 65535) then
    Result.Port := IPERF_DEFAULT_CLI_PORT;

  if Result.DurationSec < 1 then
    Result.DurationSec := IPERF_DEFAULT_CLI_SECONDS
  else if Result.DurationSec > 86400 then
    Result.DurationSec := 86400;

  if Result.Streams < 1 then
    Result.Streams := IPERF_DEFAULT_CLI_STREAMS
  else if Result.Streams > IPERF_MAX_STREAMS then
    Result.Streams := IPERF_MAX_STREAMS;
  { TCP 双向每个流要开 2 条连接，流数上限折半，免得连接数翻倍超限 }
  if (Result.Mode = imTCP) and (Result.Direction = idBidir) and
     (Result.Streams > IPERF_MAX_STREAMS div 2) then
    Result.Streams := IPERF_MAX_STREAMS div 2;

  if Result.IntervalMs < 100 then
    Result.IntervalMs := IPERF_DEFAULT_INTERVAL_MS;

  if Result.Mode = imUDP then
  begin
    { UDP 单包超过 1400 会被 IP 分片，和界面上的处理保持一致 }
    if (Result.BlockSize < 64) or (Result.BlockSize > IPERF_DEFAULT_UDP_BLOCK) then
      Result.BlockSize := IPERF_DEFAULT_UDP_BLOCK;
    if Result.TargetBps <= 0 then
      Result.TargetBps := IPERF_DEFAULT_UDP_RATE;
  end
  else
  begin
    if Result.BlockSize < 512 then
      Result.BlockSize := IPERF_DEFAULT_CLI_BLOCK;
    Result.TargetBps := 0;
  end;

  { socket 缓冲区：<=0 一律当成"自动调优"，太小的值（<8KB）没意义也当自动 }
  if Result.SocketBufKB < 8 then
    Result.SocketBufKB := IPERF_DEFAULT_SOCK_BUF_KB
  else if Result.SocketBufKB > IPERF_MAX_SOCK_BUF_KB then
    Result.SocketBufKB := IPERF_MAX_SOCK_BUF_KB;
end;

function ToClientConfig(const O: TIperfOptions): TClientConfig;
begin
  Result.Host        := O.Host;
  Result.Port        := Word(O.Port);
  Result.Mode        := O.Mode;
  Result.Direction   := O.Direction;
  Result.DurationSec := O.DurationSec;
  Result.Streams     := O.Streams;
  Result.BlockSize   := O.BlockSize;
  Result.TargetBps   := O.TargetBps;
  Result.IntervalMs  := O.IntervalMs;
  Result.SocketBufKB := O.SocketBufKB;
end;

{==============================================================================
  逐秒采样收集器
==============================================================================}
constructor TIperfSampleCollector.Create;
begin
  inherited Create;
  FLock  := TCriticalSection.Create;
  FItems := nil;
end;

destructor TIperfSampleCollector.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TIperfSampleCollector.Add(const S: TIntervalSample);
var
  N: Integer;
begin
  FLock.Enter;
  try
    N := Length(FItems);
    SetLength(FItems, N + 1);
    FItems[N] := S;
  finally
    FLock.Leave;
  end;
end;

function TIperfSampleCollector.Snapshot: TArray<TIntervalSample>;
begin
  FLock.Enter;
  try
    Result := Copy(FItems);
  finally
    FLock.Leave;
  end;
end;

function TIperfSampleCollector.GetCount: Integer;
begin
  FLock.Enter;
  try
    Result := Length(FItems);
  finally
    FLock.Leave;
  end;
end;

{==============================================================================
  结果组装
==============================================================================}
function BitsPerSec(const Bytes, Ms: Int64): Double;
var
  Sec: Double;
begin
  if Bytes <= 0 then
    Exit(0);
  if Ms <= 0 then
    Sec := 1.0
  else
    Sec := Ms / 1000.0;
  Result := Bytes * 8.0 / Sec;
end;

function EmptyReport: TReportPacket;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{ 把逐秒采样汇总，并算出"平均每秒多少字节 / 多少块"。
  平均值口径就是题目要的那个：总量 / 实测秒数（10 秒的测试 = 10 个每秒值求平均）。 }
procedure FillSamplesAndAverages(var R: TIperfResult;
  const Samples: TArray<TIntervalSample>);
var
  I                 : Integer;
  Span, SB, SC, RB, RC: Int64;
begin
  R.Samples := Samples;

  Span := 0; SB := 0; SC := 0; RB := 0; RC := 0;
  for I := 0 to High(Samples) do
  begin
    Inc(Span, Samples[I].SpanMs);
    Inc(SB,   Samples[I].SentBytes);
    Inc(SC,   Samples[I].SentChunks);
    Inc(RB,   Samples[I].RecvBytes);
    Inc(RC,   Samples[I].RecvChunks);
  end;
  R.SampleSpanMs     := Span;
  R.SampleSentBytes  := SB;
  R.SampleSentChunks := SC;
  R.SampleRecvBytes  := RB;
  R.SampleRecvChunks := RC;

  { 失败或没跑起来：平均值一律留 0，避免调用方拿到看起来像真的数字 }
  if (not R.Ok) or (R.ElapsedMs <= 0) then
    Exit;

  R.Seconds := R.ElapsedMs / 1000.0;

  R.AvgSentBytesPerSec  := R.LocalSentBytes / R.Seconds;
  R.AvgSentBlocksPerSec := R.LocalSentChunks / R.Seconds;
  R.AvgRecvBytesPerSec  := R.LocalRecvBytes / R.Seconds;
  R.AvgRecvBlocksPerSec := R.LocalRecvChunks / R.Seconds;
end;

function BuildResult(const Opt: TIperfOptions; const Local, Peer: TReportPacket;
  const ErrMsg: string; const Samples: TArray<TIntervalSample>;
  const BlockedCount, BlockedMs: Int64;
  const ConnCount, SendConns, RecvConns: Integer): TIperfResult;
begin
  Result.Ok             := ErrMsg = '';
  Result.Error          := ErrMsg;
  Result.Host           := Opt.Host;
  Result.Port           := Opt.Port;
  Result.Mode           := Opt.Mode;
  Result.Direction      := Opt.Direction;
  Result.Streams        := Opt.Streams;
  Result.BlockSize      := Opt.BlockSize;
  Result.SocketBufKB    := Opt.SocketBufKB;
  Result.Local          := Local;
  Result.Peer           := Peer;
  Result.SendBlockedCount := BlockedCount;
  Result.SendBlockedMs    := BlockedMs;
  Result.DataConnCount    := ConnCount;
  Result.SendConnCount    := SendConns;
  Result.RecvConnCount    := RecvConns;

  Result.ElapsedMs      := Local.ElapsedMs;
  Result.Seconds        := Local.ElapsedMs / 1000.0;
  Result.LocalSentBytes := Local.SentBytes;
  Result.LocalSentChunks:= Local.SentChunks;
  Result.LocalRecvBytes := Local.RecvBytes;
  Result.LocalRecvChunks:= Local.RecvChunks;
  Result.LocalSentBps   := BitsPerSec(Local.SentBytes, Local.ElapsedMs);
  Result.LocalRecvBps   := BitsPerSec(Local.RecvBytes, Local.ElapsedMs);

  Result.PeerSentBytes  := Peer.SentBytes;
  Result.PeerSentChunks := Peer.SentChunks;
  Result.PeerRecvBytes  := Peer.RecvBytes;
  Result.PeerRecvChunks := Peer.RecvChunks;
  Result.PeerSentBps    := BitsPerSec(Peer.SentBytes, Peer.ElapsedMs);
  Result.PeerRecvBps    := BitsPerSec(Peer.RecvBytes, Peer.ElapsedMs);

  { 合计：本端发出去的 + 本端收回来的（正向就是发送带宽，双向是两边之和） }
  Result.TotalBps       := Result.LocalSentBps + Result.LocalRecvBps;

  FillSamplesAndAverages(Result, Samples);
end;

function TIperfResult.BandwidthText: string;
begin
  if not Ok then
    Result := '发送 0 bits/sec / 接收 0 bits/sec'
  else
    Result := Format('发送 %s / 接收 %s',
      [FormatBitrate(LocalSentBps), FormatBitrate(LocalRecvBps)]);
end;

function TIperfResult.AverageText: string;
begin
  if not Ok then
    Exit('平均每秒 发送 0 Bytes(0 块) / 接收 0 Bytes(0 块)');
  Result := Format('平均每秒 发送 %s（%s 块） / 接收 %s（%s 块）  '
    + '[共 %.2f 秒 / %d 个采样区间 / 块大小 %d 字节]',
    [FormatBytes(Round(AvgSentBytesPerSec)), FormatCount(Round(AvgSentBlocksPerSec)),
     FormatBytes(Round(AvgRecvBytesPerSec)), FormatCount(Round(AvgRecvBlocksPerSec)),
     Seconds, Length(Samples), BlockSize]);
end;

function TIperfResult.SentBytesPerSecond: TArray<Int64>;
var
  I: Integer;
begin
  SetLength(Result, Length(Samples));
  for I := 0 to High(Samples) do
    Result[I] := Samples[I].SentBytes;
end;

function TIperfResult.SentBlocksPerSecond: TArray<Int64>;
var
  I: Integer;
begin
  SetLength(Result, Length(Samples));
  for I := 0 to High(Samples) do
    Result[I] := Samples[I].SentChunks;
end;

function TIperfResult.DiagnosticText: string;
var
  BufDesc: string;
begin
  if SocketBufKB > 0 then
    BufDesc := Format('%d KB（显式设置）', [SocketBufKB])
  else
    BufDesc := '系统自动调优';

  if not Ok then
    Exit(Format('测试未完成，无诊断数据（socket 缓冲区 %s）', [BufDesc]));

  Result := Format('数据连接 %d 条（发 %d / 收 %d）  |  socket 缓冲区 %s  |  '
    + '发送受阻 %s 次 / 累计 %d ms',
    [DataConnCount, SendConnCount, RecvConnCount, BufDesc,
     FormatCount(SendBlockedCount), SendBlockedMs]);
  if Direction = idBidir then
    Result := Result + Format('（双向按 iperf3 的方式拆成 %d 条只发 + %d 条只收）',
      [SendConnCount, RecvConnCount]);
  if SendBlockedCount > 0 then
    Result := Result + Format('；平均每次等 %.1f ms：发送端被链路或对端接收限住了，'
      + '对比 iperf3 偏慢时优先查这个', [SendBlockedMs / SendBlockedCount])
  else
    Result := Result + '；发送端全程没被堵：瓶颈在发送端自身/参数，不在链路';
end;

function TIperfResult.Summary: string;
var
  Sec: Double;
begin
  if not Ok then
    Exit(Format('%s:%d 测试失败: %s', [Host, Port, Error]));

  Sec := ElapsedMs / 1000.0;
  Result := Format('%s:%d %s %s  耗时 %.2f 秒 / %d 流 / %d 字节块  |  '
    + '本端 发送 %s 接收 %s  |  对端 发送 %s 接收 %s  |  合计 %s  |  '
    + '平均每秒 发送 %s(%s 块) 接收 %s(%s 块)',
    [Host, Port, ModeToStr(Mode), DirectionToCn(Direction),
     Sec, Streams, BlockSize,
     FormatBitrate(LocalSentBps), FormatBitrate(LocalRecvBps),
     FormatBitrate(PeerSentBps), FormatBitrate(PeerRecvBps),
     FormatBitrate(TotalBps),
     FormatBytes(Round(AvgSentBytesPerSec)), FormatCount(Round(AvgSentBlocksPerSec)),
     FormatBytes(Round(AvgRecvBytesPerSec)), FormatCount(Round(AvgRecvBlocksPerSec))]);
end;

{==============================================================================
  同步接口
==============================================================================}
function IperfTest(const Options: TIperfOptions): TIperfResult;
var
  Opt          : TIperfOptions;
  Th           : TIperfClientThread;
  Col          : TIperfSampleCollector;
  Samples      : TArray<TIntervalSample>;
  Local, Peer  : TReportPacket;
  Err          : string;
  BlockedCnt   : Int64;
  BlockedMs    : Int64;
  ConnCnt      : Integer;
  SendConns    : Integer;
  RecvConns    : Integer;
begin
  Opt     := NormalizeOptions(Options);
  Local   := EmptyReport;
  Peer    := EmptyReport;
  Err     := '';
  Samples := nil;

  Col := TIperfSampleCollector.Create;
  try
    { 挂上逐秒采样：跑完之后 Samples 里就是第 1 秒、第 2 秒 … 各自发了多少 }
    Th := TIperfClientThread.Create(ToClientConfig(Opt),
      procedure(const S: TIntervalSample)
      begin
        Col.Add(S);
      end, nil, nil);
    try
      Th.Start;
      Th.WaitFor;                 { 真正的耗时都在这里，工作线程自己到点收尾 }
      Err        := Th.LastError;
      Local      := Th.LocalReport;
      Peer       := Th.RemoteReport;
      BlockedCnt := Th.SendBlockedCount;
      BlockedMs  := Th.SendBlockedMs;
      ConnCnt    := Th.DataConnCount;
      SendConns  := Th.SendConnCount;
      RecvConns  := Th.RecvConnCount;
    finally
      Th.Free;
    end;
    { 线程已经结束，采样线程也停了，这时候取是安全的 }
    Samples := Col.Snapshot;
  finally
    Col.Free;
  end;

  if (Err = '') and (Local.Magic <> IPERF_MAGIC) then
    Err := '测试没有产生统计结果';
  if (Err = '') and (Peer.Magic <> IPERF_MAGIC) then
    Err := '没有收到服务端的统计报告';

  Result := BuildResult(Opt, Local, Peer, Err, Samples, BlockedCnt, BlockedMs,
    ConnCnt, SendConns, RecvConns);
end;

function IperfTest(const Host: string; const Port: Integer; const Mode: TIperfMode;
  const Direction: TIperfDirection; const DurationSec, Streams, BlockSize,
  IntervalMs: Integer; const TargetBps: Int64;
  const SocketBufKB: Integer): TIperfResult;
begin
  Result := IperfTest(MakeOptions(Host, Port, Mode, Direction, DurationSec,
    Streams, BlockSize, IntervalMs, TargetBps, SocketBufKB));
end;

{==============================================================================
  异步接口
==============================================================================}
constructor TIperfTestSession.Create(const Options: TIperfOptions);
begin
  inherited Create;
  FOptions   := NormalizeOptions(Options);
  FThread    := nil;
  FStarted   := False;
  FCollector := TIperfSampleCollector.Create;
end;

destructor TIperfTestSession.Destroy;
begin
  Abort;
  if FThread <> nil then
  begin
    FThread.WaitFor;
    FreeAndNil(FThread);      { 线程结束 = 采样线程也停了，之后才能释放收集器 }
  end;
  FCollector.Free;
  inherited;
end;

procedure TIperfTestSession.Start;
begin
  if FStarted then
    Exit;
  FStarted := True;
  FThread  := TIperfClientThread.Create(ToClientConfig(FOptions),
    procedure(const S: TIntervalSample)      { 逐秒采样攒进收集器 }
    begin
      FCollector.Add(S);
    end, nil, nil);
  FThread.Start;
end;

procedure TIperfTestSession.Abort;
begin
  if FThread <> nil then
    FThread.Abort;
end;

function TIperfTestSession.WaitFor(const TimeoutMs: Cardinal): Boolean;
begin
  if FThread = nil then
    Exit(False);
  { TThread.WaitFor 不带超时参数，所以直接等线程句柄 }
  Result := WaitForSingleObject(FThread.Handle, TimeoutMs) = WAIT_OBJECT_0;
end;

function TIperfTestSession.GetDone: Boolean;
begin
  Result := (FThread <> nil) and FThread.Finished;
end;

function TIperfTestSession.GetRunning: Boolean;
begin
  Result := (FThread <> nil) and (not FThread.Finished);
end;

function TIperfTestSession.CurrentSamples: TArray<TIntervalSample>;
begin
  Result := FCollector.Snapshot;
end;

function TIperfTestSession.CurrentResult: TIperfResult;
var
  Local, Peer: TReportPacket;
  Err        : string;
begin
  Local := EmptyReport;
  Peer  := EmptyReport;

  if FThread = nil then
  begin
    { 还没 Start：给一个"尚未开始"的空结果 }
    Exit(BuildResult(FOptions, Local, Peer, '测试尚未开始',
      FCollector.Snapshot, 0, 0, 0, 0, 0));
  end;

  Err   := FThread.LastError;
  Local := FThread.LocalReport;
  Peer  := FThread.RemoteReport;

  if (Err = '') and (Local.Magic <> IPERF_MAGIC) then
    Err := '测试尚未完成';

  Result := BuildResult(FOptions, Local, Peer, Err, FCollector.Snapshot,
    FThread.SendBlockedCount, FThread.SendBlockedMs,
    FThread.DataConnCount, FThread.SendConnCount, FThread.RecvConnCount);
end;

end.
