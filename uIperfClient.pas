{*******************************************************************************
  uIperfClient.pas  -  Delphi 版 iperf 客户端
  对应 iperf3 的 src/iperf_client_api.c

  流程：控制连接握手 -> 建 N 条数据连接(TCP/UDP) -> 按方向收发 -> 到点收尾
        -> 双方交换统计报告，从而得到"本端收发"和"对端收发"四个维度的数据

  连接数（和 iperf3 保持一致）：
    正向 / 反向  -> 每个流 1 条数据连接，只发或只收
    双向(TCP)    -> 每个流 **2 条** 数据连接：前 N 条客户端->服务端(只发)，
                    后 N 条服务端->客户端(只收)
                    （iperf3 的 --bidir 就是连着调两次 iperf_create_streams，
                      一次 sender=1 一次 sender=0，见 iperf_client_api.c）
    双向(UDP)    -> 每个流仍 1 个 socket，收发共用（UDP 无流控，不会互相干扰）
  数据连接的握手里 Direction 表示"这条连接承载哪个方向"，服务端据此决定
  自己该收还是该发。
*******************************************************************************}
unit uIperfClient;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections,
  Winapi.Windows, Winapi.Winsock2, uIperfCommon, uIperfWorker;

type
  { 客户端测试参数 }
  TClientConfig = record
    Host       : string;
    Port       : Word;
    Mode       : TIperfMode;
    Direction  : TIperfDirection;
    DurationSec: Integer;
    Streams    : Integer;
    BlockSize  : Integer;
    TargetBps  : Int64;
    IntervalMs : Integer;
    { 数据 socket 缓冲区(KB)。0 = 不设置，交给系统自动调优（推荐，和 iperf3 一致）；
      >0 = 显式设置 SO_SNDBUF/SO_RCVBUF（注意会把 Windows 的接收窗口自动调优关掉） }
    SocketBufKB: Integer;
  end;

  TIperfClientThread = class(TThread)
  private
    FCfg       : TClientConfig;
    FOnSample  : TSampleProc;
    FOnLog     : TLogProc;
    FOnReport  : TReportProc;
    FStop      : TEvent;
    FStats     : TIperfSessionStats;
    FCookie    : TGUID;
    FControl   : TSocket;
    FSrvAddr   : TSockAddr;
    FDataSocks : TArray<TSocket>;
    FDataDirs  : TArray<TIperfDirection>;  // 每条数据连接承载的方向
    FWorkers   : TObjectList<TThread>;
    FLocalRpt  : TReportPacket;
    FRemoteRpt : TReportPacket;
    FError     : string;
    FBlockedCnt: Int64;
    FBlockedMs : Int64;

    function  GetDataConnCount: Integer;
    function  GetSendConnCount: Integer;
    function  GetRecvConnCount: Integer;
    function  BuildHandshake(const Kind: TPacketKind;
      const Dir: TIperfDirection): THandshake;
    function  ConnectControl: Boolean;
    function  OpenTcpData: Boolean;
    function  OpenUdpData: Boolean;
    procedure StartWorkersSend;
    procedure StartWorkersRecv;
    procedure JoinWorkers;
    function  ExchangeReports: Boolean;
    procedure CloseDataSocks;
    procedure LogIt(const S: string);
  protected
    procedure Execute; override;
  public
    constructor Create(const ACfg: TClientConfig; const AOnSample: TSampleProc;
      const AOnLog: TLogProc; const AOnReport: TReportProc);
    destructor Destroy; override;
    procedure Abort;
    property LastError: string read FError;
    property LocalReport: TReportPacket read FLocalRpt;
    property RemoteReport: TReportPacket read FRemoteRpt;
    property Cookie: TGUID read FCookie;
    { 本次建立的数据连接条数（TCP 双向 = 2 × 流数，其余 = 流数） }
    property DataConnCount: Integer read GetDataConnCount;
    { 其中本端负责"发"的连接数 / 负责"收"的连接数（诊断用） }
    property SendConnCount: Integer read GetSendConnCount;
    property RecvConnCount: Integer read GetRecvConnCount;
    { 本端发送线程「发送缓冲区满 -> 等可写」的次数与累计毫秒（诊断用） }
    property SendBlockedCount: Int64 read FBlockedCnt;
    property SendBlockedMs: Int64 read FBlockedMs;
  end;

implementation

constructor TIperfClientThread.Create(const ACfg: TClientConfig;
  const AOnSample: TSampleProc; const AOnLog: TLogProc;
  const AOnReport: TReportProc);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCfg       := ACfg;
  FOnSample  := AOnSample;
  FOnLog     := AOnLog;
  FOnReport  := AOnReport;
  FStop      := TEvent.Create(nil, True, False, '');
  FControl   := INVALID_SOCKET;
  FWorkers   := TObjectList<TThread>.Create(True);
  FDataSocks := nil;
  FBlockedCnt := 0;
  FBlockedMs  := 0;
  CreateGUID(FCookie);
  FillChar(FSrvAddr, SizeOf(FSrvAddr), 0);
  FillChar(FLocalRpt, SizeOf(FLocalRpt), 0);
  FillChar(FRemoteRpt, SizeOf(FRemoteRpt), 0);
end;

destructor TIperfClientThread.Destroy;
begin
  Abort;
  JoinWorkers;
  CloseDataSocks;
  if FControl <> INVALID_SOCKET then
  begin
    closesocket(FControl);
    FControl := INVALID_SOCKET;
  end;
  FWorkers.Free;
  FStop.Free;
  inherited;
end;

procedure TIperfClientThread.Abort;
begin
  if Assigned(FStop) then
    FStop.SetEvent;
end;

procedure TIperfClientThread.LogIt(const S: string);
begin
  if Assigned(FOnLog) then
    FOnLog(S);
end;

procedure TIperfClientThread.CloseDataSocks;
var
  I: Integer;
begin
  { 只关 socket，不动数组长度：DataConnCount 在测试结束后还要读，
    清空数组会让"本次开了几条连接"变成 0 }
  for I := 0 to Length(FDataSocks) - 1 do
    if FDataSocks[I] <> INVALID_SOCKET then
    begin
      closesocket(FDataSocks[I]);
      FDataSocks[I] := INVALID_SOCKET;
    end;
end;

function TIperfClientThread.GetDataConnCount: Integer;
begin
  Result := Length(FDataSocks);
end;

function TIperfClientThread.GetSendConnCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FDataDirs) do
    if (FDataDirs[I] = idNormal) or (FDataDirs[I] = idBidir) then
      Inc(Result);
end;

function TIperfClientThread.GetRecvConnCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FDataDirs) do
    if (FDataDirs[I] = idReverse) or (FDataDirs[I] = idBidir) then
      Inc(Result);
end;

function TIperfClientThread.BuildHandshake(const Kind: TPacketKind;
  const Dir: TIperfDirection): THandshake;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Magic      := IPERF_MAGIC;
  Result.Version    := IPERF_VERSION;
  Result.Kind       := Ord(Kind);
  Result.Mode       := Ord(FCfg.Mode);
  { 控制连接上带的是"整个测试的方向"；数据连接上带的是"这条连接承载哪个方向"。
    双向时每条数据连接只负责一个方向，服务端据此决定自己收发。 }
  Result.Direction  := Ord(Dir);
  Result.Streams    := Byte(FCfg.Streams);
  Result.DurationMs := Cardinal(FCfg.DurationSec) * 1000;
  Result.IntervalMs := Cardinal(FCfg.IntervalMs);
  Result.BlockSize  := Cardinal(FCfg.BlockSize);
  Result.TargetBps  := FCfg.TargetBps;
  Result.Cookie     := FCookie;
end;

{==============================================================================
  建链
==============================================================================}
function TIperfClientThread.ConnectControl: Boolean;
var
  Net: u_long;
  Hs : THandshake;
  Ack: Byte;
begin
  Result := False;
  if not ResolveIPv4(FCfg.Host, Net) then
  begin
    FError := '无法解析主机 ' + FCfg.Host;
    Exit;
  end;
  FSrvAddr := MakeSockAddr(Net, FCfg.Port);

  FControl := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if FControl = INVALID_SOCKET then
  begin
    FError := '创建控制 socket 失败: ' + LastSocketErrText;
    Exit;
  end;
  SetNoDelay(FControl);
  SetSockTimeout(FControl, 20000, 20000);

  if connect(FControl, FSrvAddr, SizeOf(FSrvAddr)) = SOCKET_ERROR then
  begin
    FError := Format('连接 %s:%d 失败: %s', [FCfg.Host, FCfg.Port, LastSocketErrText]);
    Exit;
  end;

  Hs := BuildHandshake(pkControl, FCfg.Direction);
  if not SendAll(FControl, Hs, SizeOf(Hs), 8000) then
  begin
    FError := '发送控制握手失败';
    Exit;
  end;
  if not RecvAll(FControl, Ack, 1, 20000) then
  begin
    FError := '服务端未回应控制握手 ACK（对端可能不是本程序的服务端）';
    Exit;
  end;
  Result := True;
end;

function TIperfClientThread.OpenTcpData: Boolean;
var
  I, N, NConn: Integer;
  S   : TSocket;
  Hs  : THandshake;
  Ack : Byte;
begin
  Result := False;
  N := FCfg.Streams;
  if N < 1 then
    N := 1;
  if N > IPERF_MAX_STREAMS then
    N := IPERF_MAX_STREAMS;

  { 双向：每个流开两条连接（前 N 条只发、后 N 条只收），和 iperf3 的 --bidir 一致。
    为什么不能一条连接收发共用：同一条 TCP 连接上两个方向会互相挤 ACK 和窗口，
    双向吞吐会明显低于 iperf3；拆开后每个方向各有独立的窗口/ACK 通道。 }
  if FCfg.Direction = idBidir then
  begin
    if N > IPERF_MAX_STREAMS div 2 then
      N := IPERF_MAX_STREAMS div 2;
    NConn := N * 2;
  end
  else
    NConn := N;
  FCfg.Streams := N;              { 收敛后的流数：握手和报告都用它 }

  SetLength(FDataSocks, NConn);
  SetLength(FDataDirs, NConn);
  for I := 0 to NConn - 1 do
  begin
    FDataSocks[I] := INVALID_SOCKET;
    { 每条连接只承载一个方向：前 N 条 = 客户端发（idNormal），
      后 N 条 = 客户端收（idReverse）；非双向就保持原方向 }
    if FCfg.Direction = idBidir then
    begin
      if I < N then
        FDataDirs[I] := idNormal
      else
        FDataDirs[I] := idReverse
    end
    else
      FDataDirs[I] := FCfg.Direction;
  end;

  for I := 0 to NConn - 1 do
  begin
    S := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if S = INVALID_SOCKET then
    begin
      FError := '创建数据 socket 失败: ' + LastSocketErrText;
      Exit;
    end;
    FDataSocks[I] := S;
    SetNoDelay(S);
    { 默认不动 socket 缓冲区（SocketBufKB=0），交给系统自动调优 —— 和 iperf3 一致。
      一旦显式设 SO_RCVBUF，Windows 就关掉接收窗口自动调优，
      吞吐会被卡在「窗口 / RTT」：1 Gbit/s 需要窗口 >= 125000 * RTT(ms) 字节。 }
    if FCfg.SocketBufKB > 0 then
    begin
      SetSockBufSize(S, SO_SNDBUF, FCfg.SocketBufKB * 1024);
      SetSockBufSize(S, SO_RCVBUF, FCfg.SocketBufKB * 1024);
    end;
    SetSockTimeout(S, 15000, 15000);

    if connect(S, FSrvAddr, SizeOf(FSrvAddr)) = SOCKET_ERROR then
    begin
      FError := Format('第 %d 条数据连接失败: %s', [I + 1, LastSocketErrText]);
      Exit;
    end;
    Hs := BuildHandshake(pkData, FDataDirs[I]);
    if not SendAll(S, Hs, SizeOf(Hs), 8000) then
    begin
      FError := Format('第 %d 条数据连接发送握手失败', [I + 1]);
      Exit;
    end;
    if not RecvAll(S, Ack, 1, 10000) then
    begin
      FError := Format('第 %d 条数据连接未收到 ACK', [I + 1]);
      Exit;
    end;
    SetNonBlocking(S, True);
  end;

  if FCfg.Direction = idBidir then
    LogIt(Format('[客户端] 已建立 %d 条 TCP 数据连接（双向：%d 条只发 + %d 条只收，每流 2 条）',
      [NConn, N, N]))
  else
    LogIt(Format('[客户端] 已建立 %d 条 TCP 数据连接', [NConn]));
  Result := True;
end;

function TIperfClientThread.OpenUdpData: Boolean;
var
  I, N: Integer;
  S   : TSocket;
  Sa  : TSockAddr;
begin
  Result := False;
  N := FCfg.Streams;
  if N < 1 then
    N := 1;
  if N > IPERF_MAX_STREAMS then
    N := IPERF_MAX_STREAMS;
  SetLength(FDataSocks, N);
  SetLength(FDataDirs, N);
  for I := 0 to N - 1 do
  begin
    FDataSocks[I] := INVALID_SOCKET;
    { UDP 没有流控/窗口，双向时同一个 socket 收发不会互相拖累，
      所以照旧每流 1 个 socket（iperf3 的 UDP 双向也是这个路子） }
    FDataDirs[I] := FCfg.Direction;
  end;

  Sa := MakeSockAddr(0, 0);          { 0.0.0.0:0，本地端口由系统分配 }
  for I := 0 to N - 1 do
  begin
    S := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if S = INVALID_SOCKET then
    begin
      FError := '创建 UDP socket 失败: ' + LastSocketErrText;
      Exit;
    end;
    FDataSocks[I] := S;
    if FCfg.SocketBufKB > 0 then
    begin
      SetSockBufSize(S, SO_SNDBUF, FCfg.SocketBufKB * 1024);
      SetSockBufSize(S, SO_RCVBUF, FCfg.SocketBufKB * 1024);
    end
    else
    begin
      { UDP 没有"窗口自动调优"，收得不及时就直接丢包，所以默认给大一点的收缓冲 }
      SetSockBufSize(S, SO_SNDBUF, 256 * 1024);
      SetSockBufSize(S, SO_RCVBUF, 1024 * 1024);
    end;

    if bind(S, Sa, SizeOf(Sa)) = SOCKET_ERROR then
    begin
      FError := Format('第 %d 个 UDP socket 绑定本地端口失败: %s',
        [I + 1, LastSocketErrText]);
      Exit;
    end;
    { 反向/双向必需：先让服务端学到本端 UDP 端点 }
    if not UdpSendHello(S, FSrvAddr, FCookie, Cardinal(I), 5, 600) then
    begin
      FError := Format('第 %d 个 UDP 流与服务端握手失败（服务端未响应）', [I + 1]);
      Exit;
    end;
  end;

  for I := 0 to N - 1 do
    SetNonBlocking(FDataSocks[I], True);

  LogIt(Format('[客户端] 已建立 %d 个 UDP 流并完成端点握手', [N]));
  Result := True;
end;

{==============================================================================
  启动 / 等待工作线程
==============================================================================}
procedure TIperfClientThread.StartWorkersSend;
var
  I : Integer;
  Th: TThread;
  D : TIperfDirection;
begin
  for I := 0 to High(FDataSocks) do
  begin
    { 逐条连接判断：双向时只有"只发"的那几条连接需要发送线程 }
    D := FDataDirs[I];
    if (D <> idNormal) and (D <> idBidir) then
      Continue;
    if FCfg.Mode = imTCP then
      Th := TTcpSendThread.Create(FDataSocks[I], FStats, FStop)
    else
      Th := TUdpSendThread.Create(FDataSocks[I], FSrvAddr, FStats, FStop,
        FCookie, Cardinal(I), Cardinal(FCfg.BlockSize), FCfg.TargetBps);
    FWorkers.Add(Th);
    Th.Start;
  end;
end;

procedure TIperfClientThread.StartWorkersRecv;
var
  I : Integer;
  Th: TThread;
  D : TIperfDirection;
begin
  for I := 0 to High(FDataSocks) do
  begin
    { 逐条连接判断：双向时只有"只收"的那几条连接需要接收线程 }
    D := FDataDirs[I];
    if (D <> idReverse) and (D <> idBidir) then
      Continue;
    if FCfg.Mode = imTCP then
      Th := TTcpRecvThread.Create(FDataSocks[I], FStats, FStop)
    else
      Th := TUdpRecvThread.Create(FDataSocks[I], FStats, FStop);
    FWorkers.Add(Th);
    Th.Start;
  end;
end;

procedure TIperfClientThread.JoinWorkers;
var
  I: Integer;
begin
  for I := 0 to FWorkers.Count - 1 do
    FWorkers[I].WaitFor;
end;

{==============================================================================
  交换统计报告：本端 -> 服务端，服务端 -> 本端
==============================================================================}
function TIperfClientThread.ExchangeReports: Boolean;
var
  Local: TReportPacket;
begin
  Result := False;
  Local := FStats.Snapshot;
  Local.Cookie := FCookie;
  FLocalRpt := Local;

  if not SendAll(FControl, Local, SizeOf(Local), 8000) then
  begin
    FError := '回传统计报告失败';
    Exit;
  end;
  if not RecvAll(FControl, FRemoteRpt, SizeOf(FRemoteRpt), 30000) then
  begin
    FError := '未收到服务端统计报告';
    Exit;
  end;
  if FRemoteRpt.Magic <> IPERF_MAGIC then
  begin
    FError := '服务端报告格式错误';
    Exit;
  end;
  Result := True;
end;

{==============================================================================
  主流程
==============================================================================}
procedure TIperfClientThread.Execute;
var
  Dur    : Integer;
  BufDesc: string;
begin
  FStats := nil;
  try
    Dur := FCfg.DurationSec;
    if Dur < 1 then
      Dur := 1;
    if Dur > 86400 then
      Dur := 86400;

    { 流数先收敛到合法范围：TCP 双向要开 2 倍连接，所以上限是一半 }
    if FCfg.Streams < 1 then
      FCfg.Streams := 1
    else if FCfg.Streams > IPERF_MAX_STREAMS then
      FCfg.Streams := IPERF_MAX_STREAMS;
    if (FCfg.Mode = imTCP) and (FCfg.Direction = idBidir) and
       (FCfg.Streams > IPERF_MAX_STREAMS div 2) then
      FCfg.Streams := IPERF_MAX_STREAMS div 2;

    FStats := TIperfSessionStats.Create(FCfg.Mode, FCfg.Direction, FCfg.Streams,
      Cardinal(FCfg.BlockSize), Int64(Dur) * 1000, Int64(FCfg.IntervalMs), FOnSample);
    { 客户端也带上身份，逐秒行会显示「服务端地址|本端 Cookie」 }
    FStats.SetIdentity(FCookie, Format('%s:%d', [FCfg.Host, FCfg.Port]));

    if not ConnectControl then
      Exit;
    LogIt(Format('[客户端] 已连接 %s:%d  %s / %s  时长 %d 秒  流数 %d  块 %d 字节',
      [FCfg.Host, FCfg.Port, ModeToStr(FCfg.Mode), DirectionToCn(FCfg.Direction),
       Dur, FCfg.Streams, FCfg.BlockSize]));

    if FCfg.Mode = imTCP then
    begin
      if not OpenTcpData then
        Exit;
    end
    else
    begin
      if not OpenUdpData then
        Exit;
    end;

    { 数据面正式开始计时 }
    FStats.MarkDataStart;
    FStats.StartSampling;
    LogIt(Format('[客户端] 测试开始，预计 %d 秒后结束 ...', [Dur]));

    StartWorkersSend;
    StartWorkersRecv;

    JoinWorkers;              { 各线程到达各自截止时间后自行退出 }
    FStats.StopSampling;

    { 发送线程已经全部结束，把诊断计数取出来（结果里会带回去） }
    FBlockedCnt := FStats.SendBlockedCount;
    FBlockedMs  := FStats.SendBlockedMs;
    if FCfg.SocketBufKB > 0 then
      BufDesc := Format('%d KB', [FCfg.SocketBufKB])
    else
      BufDesc := '系统自动调优';
    LogIt(Format('[客户端] 诊断: socket 缓冲区 %s, 发送受阻 %d 次 / 累计 %d ms, '
      + '数据连接 %d 条（发 %d / 收 %d）',
      [BufDesc, FBlockedCnt, FBlockedMs,
       DataConnCount, SendConnCount, RecvConnCount]));

    if not ExchangeReports then
      Exit;

    LogIt(Format('[客户端] 测试结束: 发 %s / %s 块, 收 %s / %s 块, 耗时 %s',
      [FormatBytes(FLocalRpt.SentBytes), FormatCount(FLocalRpt.SentChunks),
       FormatBytes(FLocalRpt.RecvBytes), FormatCount(FLocalRpt.RecvChunks),
       FormatDuration(FLocalRpt.ElapsedMs)]));

    if Assigned(FOnReport) then
      FOnReport(FLocalRpt, FRemoteRpt);
  except
    on E: Exception do
    begin
      FError := E.ClassName + ': ' + E.Message;
      LogIt('[客户端] 异常: ' + FError);
    end;
  end;

  { 收尾：先停线程，再释放统计对象 }
  FStop.SetEvent;
  JoinWorkers;
  CloseDataSocks;
  if Assigned(FStats) then
  begin
    FStats.StopSampling;
    FreeAndNil(FStats);
  end;
  if FControl <> INVALID_SOCKET then
  begin
    closesocket(FControl);
    FControl := INVALID_SOCKET;
  end;
end;

end.
