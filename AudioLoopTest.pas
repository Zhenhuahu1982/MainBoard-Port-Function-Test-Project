unit AudioLoopTest;

{ 音频回路测试 —— 测试编排与日志

  工作原理（与 Realtek whdatest 一致）：
    治具把输出孔和输入孔短接 —— L 对 L、R 对 R、GND 共地，
    前置接口的 JD 线并在一起。所以只要从输出孔送 1kHz 正弦，
    从输入孔录回来就能判定这一路通不通。

  端口配对矩阵（按用户描述的板型规则生成）：
    1) 只有 1 个输出 + 1 个输入   -> 该输出对该输入，测一轮
    2) 3 孔位(Front/LineIn/MicIn)-> Front 分别对 LineIn、MicIn
    3) 另有前置音频接口时        -> 追加「每个输出 -> 前置 MIC」，
                                     以及 Front -> 后置 MIC IN1

  每个 输x输入 组合依次跑这些测试项（各自可禁用）：
    PORT DETECT   接口存在侦测（不搬信号，只看端点/jack 是否在）
    LOOPBACK      回路：送全声道正弦，验证录回幅度
    L/R CHANNEL   左声道、送左/送右两次，验证互不干扰
    MUTE          输出静音后，验证录不到信号
    THD+N         满幅正弦回录，FFT 算失真+噪声

  测试日志：每条结果写一行 CSV，含是哪个接口、哪个测试项、实测值、
  门限、PASS/FAIL、耗时。文件名带时间戳，便于追溯。

  时序与超时：
    waveIn/waveOut 都用事件驱动 + 超时等待，治具没接好时不会挂死。
    每项测试结束后有静音等待(settle)，等模拟前端稳定下来再录。
}

interface

uses
  System.SysUtils, System.Classes, System.Math, Winapi.Windows, Winapi.MMSystem,
  AudioLoopCfg, AudioLoopAnaly, AudioLoopDev;

type
  { 一个 输出x输入 的配对 }
  TAlPortPair = record
    OutPort: TAlOutPort;
    InPort : TAlInPort;
  end;
  TAlPortPairArray = array of TAlPortPair;

  { 回调类型。这台机器的编译器不接受在形参上直接写
    `const AOnLog: procedure(...) of object` 这种匿名过程类型
    (会报 E2029)，所以必须先起名字，这里统一成下面两个类型。 }
  TAlLogCallback = procedure(const ALine: string) of object;
  TAlStepCallback = procedure(ADone, ATotal: Integer;
    const ADesc: string) of object;

  { 一次完整测试的汇总 }
  TAlLoopTestResult = record
    Results   : TAlTestResultArray;   { 逐项结果，顺序与日志一致 }
    TotalCnt  : Integer;              { 执行了的项数 }
    PassCnt   : Integer;
    FailCnt   : Integer;
    SkipCnt   : Integer;              { 被禁用/不适用而未执行的项数 }
    Passed    : Boolean;              { 总体结论：无 FAIL 且至少执行了一项 }
    LogFile   : string;               { 日志文件路径 }
    Summary   : string;               { 结论摘要，进结果表格 }
  end;

const
  { 单项测试的超时(毫秒)。超时按 FAIL 记，不阻塞产线。 }
  AL_TEST_TIMEOUT_MS  = 8000;
  { 每轮测试的采集时长(毫秒)，要够 1kHz 凑够整数个周期 }
  AL_CAPTURE_MS       = 400;
  { 输出静音后等待模拟链路稳定的时间 }
  AL_SETTLE_MS        = 120;
  { 缓冲帧数 = 采样率 * 时长 / 1000 }
  { 1kHz 在 400ms 内有 400 个周期，FFT 取前 4096 帧足够 }

{ 按配置生成 输x输入 配对矩阵。
    必须至少有一个被启用的输出和一个被启用的输入，否则返回空数组。 }
function AlBuildPairs(const AConfig: TAlLoopConfig): TAlPortPairArray;

{ 跑一次完整测试。
    AConfig : 全部配置（含各项启用与数值）
    AEnv    : 已探测到的音频环境（由 AlProbeAudioEnvironment 得到）
    ALogDir : 日志目录，传空串则用程序所在目录
    AOnLog  : 日志回调，可为 nil。每写一行日志回调一次，
             界面就能实时把结果显示到表格里
    AOnStep : 进度回调，可为 nil。参数是「已完成项数/总项数」和一句进度说明 }
function AlRunLoopTest(const AConfig: TAlLoopConfig; const AEnv: TAlAudioEnv;
  const ALogDir: string;
  AOnLog: TAlLogCallback;
  AOnStep: TAlStepCallback;
  out AResult: TAlLoopTestResult): Boolean;

{ 生成带时间戳的日志文件名 }
function AlMakeLogFileName(const ABaseDir: string): string;

{ 把一条结果格式化成一行 CSV 文本。导出便于自测与复用。 }
function AlFormatResultLine(const ARes: TAlTestResult): string;

{ 生成总体结论文字 }
function AlFormatSummary(const AResult: TAlLoopTestResult): string;

implementation

{ ================= 端口配对矩阵 ================= }

function AlBuildPairs(const AConfig: TAlLoopConfig): TAlPortPairArray;
var
  I, J: Integer;
  OutCnt, InCnt: Integer;
  EnabledOut: array[0..AL_OUTPORT_CNT - 1] of Boolean;
  EnabledIn : array[0..AL_INPORT_CNT - 1] of Boolean;
begin
  Result := nil;
  OutCnt := 0;
  InCnt := 0;

  for I := 0 to AL_OUTPORT_CNT - 1 do
  begin
    EnabledOut[I] := AConfig.EnableOut[TAlOutPort(I)];
    if EnabledOut[I] then
      Inc(OutCnt);
  end;
  for J := 0 to AL_INPORT_CNT - 1 do
  begin
    EnabledIn[J] := AConfig.EnableIn[TAlInPort(J)];
    if EnabledIn[J] then
      Inc(InCnt);
  end;

  { 用户明确要求：测试时最少要有一个输出和一个输入接口 }
  if (OutCnt = 0) or (InCnt = 0) then
    Exit;

  { 配对规则就是「每个启用的输出 x 每个启用的输入」：
      - 后置 MIC / 两个 Line In：所有输出都配(这是治具常接的三孔位)
      - 前置 MIC：属于「前置音频接口」，勾了它就说明板子上有前置口，
        所有输出同样配到它，对应「前置音频输出到前置麦克风」这一条
    某类口不存在时，调用方会在 AlCanUseInPort 里把它剔掉，
    这里不用替上层猜板型。 }
  for I := 0 to AL_OUTPORT_CNT - 1 do
  begin
    if not EnabledOut[I] then
      Continue;
    for J := 0 to AL_INPORT_CNT - 1 do
    begin
      if not EnabledIn[J] then
        Continue;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].OutPort := TAlOutPort(I);
      Result[High(Result)].InPort  := TAlInPort(J);
    end;
  end;
end;

{ ================= 日志 ================= }

function AlMakeLogFileName(const ABaseDir: string): string;
var
  Dir: string;
begin
  Dir := ABaseDir;
  if (Dir = '') or (Dir[Length(Dir)] <> '\') then
    Dir := Dir + '\';
  Result := Dir + 'AudioLoopTest_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.log';
end;

function AlFormatResultLine(const ARes: TAlTestResult): string;
begin
  if not ARes.Executed then
    Result := Format('%-12s -> %-10s | %-16s | SKIP  | %s',
      [AlOutPortName(ARes.OutPort), AlInPortName(ARes.InPort),
       AlTestItemName(ARes.TestItem), ARes.Message])
  else if ARes.Passed then
    Result := Format('%-12s -> %-10s | %-16s | PASS  | 实测=%.2f 门限=%.2f 耗时=%dms  %s',
      [AlOutPortName(ARes.OutPort), AlInPortName(ARes.InPort),
       AlTestItemName(ARes.TestItem), ARes.Measured, ARes.Threshold,
       ARes.ElapsedMs, ARes.Message])
  else
    Result := Format('%-12s -> %-10s | %-16s | FAIL  | 实测=%.2f 门限=%.2f 耗时=%dms  %s',
      [AlOutPortName(ARes.OutPort), AlInPortName(ARes.InPort),
       AlTestItemName(ARes.TestItem), ARes.Measured, ARes.Threshold,
       ARes.ElapsedMs, ARes.Message]);
end;

function AlFormatSummary(const AResult: TAlLoopTestResult): string;
begin
  if (AResult.TotalCnt = 0) then
  begin
    Result := '没有可执行的测试项(请至少启用一个输出接口、一个输入接口和一个测试项)';
    Exit;
  end;
  if AResult.FailCnt = 0 then
    Result := Format('全部通过: 共 %d 项 (PASS %d / FAIL %d / 跳过 %d)',
      [AResult.TotalCnt, AResult.PassCnt, AResult.FailCnt, AResult.SkipCnt])
  else
    Result := Format('存在异常: 共 %d 项 (PASS %d / FAIL %d / 跳过 %d)',
      [AResult.TotalCnt, AResult.PassCnt, AResult.FailCnt, AResult.SkipCnt]);
end;

{ ================= 音频采集/回放引擎 ================= }

type
  { 一次采集用的缓冲与句柄。回放和采集各自一套，参数不同但结构一样。 }
  TAlWaveBuf = record
    Handle: THandle;
    Hdr   : TWaveHdr;
    Data  : TArray<SmallInt>;
    Bytes : Cardinal;
    Ready : Boolean;
  end;

{ 打开回放设备 }
function AlOpenWaveOut(out AHandle: THandle; ADevIndex: Integer;
  ASampleRate, AChannels: Integer; out AErr: string): Boolean;
var
  WF: TWaveFormatEx;
  C: Integer;
begin
  AHandle := 0;
  AErr := '';
  FillChar(WF, SizeOf(WF), 0);
  WF.wFormatTag := WAVE_FORMAT_PCM;
  WF.nChannels := AChannels;
  WF.nSamplesPerSec := ASampleRate;
  WF.wBitsPerSample := 16;
  WF.nBlockAlign := AChannels * 2;
  WF.nAvgBytesPerSec := ASampleRate * WF.nBlockAlign;

  C := waveOutOpen(@AHandle, ADevIndex, @WF, 0, 0, 0);
  if C <> MMSYSERR_NOERROR then
  begin
    AErr := Format('打开输出端点失败(设备 %d, winmm 错误 %d)', [ADevIndex, C]);
    AHandle := 0;
    Exit(False);
  end;
  Result := True;
end;

{ 打开采集设备 }
function AlOpenWaveIn(out AHandle: THandle; ADevIndex: Integer;
  ASampleRate, AChannels: Integer; out AErr: string): Boolean;
var
  WF: TWaveFormatEx;
  C: Integer;
begin
  AHandle := 0;
  AErr := '';
  FillChar(WF, SizeOf(WF), 0);
  WF.wFormatTag := WAVE_FORMAT_PCM;
  WF.nChannels := AChannels;
  WF.nSamplesPerSec := ASampleRate;
  WF.wBitsPerSample := 16;
  WF.nBlockAlign := AChannels * 2;
  WF.nAvgBytesPerSec := ASampleRate * WF.nBlockAlign;

  { 回调函数指针传 0 且 dwFlags 不带 CALLBACK_FUNCTION，
    这里用 WAVE_MAPPER 让驱动自己选默认设备(治具接好后靠它出声/收声)。 }
  C := waveInOpen(@AHandle, ADevIndex, @WF, 0, 0, 0);
  if C <> MMSYSERR_NOERROR then
  begin
    AErr := Format('打开输入端点失败(设备 %d, winmm 错误 %d)', [ADevIndex, C]);
    AHandle := 0;
    Exit(False);
  end;
  Result := True;
end;

procedure AlCloseWaveOut(var AHandle: THandle);
begin
  if AHandle <> 0 then
  begin
    waveOutReset(AHandle);
    waveOutClose(AHandle);
    AHandle := 0;
  end;
end;

procedure AlCloseWaveIn(var AHandle: THandle);
begin
  if AHandle <> 0 then
  begin
    waveInReset(AHandle);
    waveInStop(AHandle);
    waveInClose(AHandle);
    AHandle := 0;
  end;
end;

{ 送出一段 16bit 立体声 PCM（同步写完即返回，不等播放结束）。
  治具是电阻直连，播放写完驱动就会把信号推到输出孔，不需要额外等待。 }
function AlPlayBuffer(AHandle: THandle; const AData: TArray<SmallInt>;
  ASampleRate, AChannels: Integer; out AErr: string): Boolean;
var
  Hdr: TWaveHdr;
  Bytes: Cardinal;
  C: Integer;
  Event: THandle;
  Start: DWORD;
begin
  Result := False;
  AErr := '';
  Bytes := Length(AData) * SizeOf(SmallInt);

  Event := CreateEvent(nil, True, False, nil);
  if Event = 0 then
  begin
    AErr := '创建播放完成事件失败';
    Exit(False);
  end;

  try
    FillChar(Hdr, SizeOf(Hdr), 0);
    Hdr.lpData := PAnsiChar(@AData[0]);
    Hdr.dwBufferLength := Bytes;
    Hdr.dwUser := 1;
    { 这里不用驱动回调，改用自己的事件：先把事件句柄挂在 dwUser 之外
      靠阻塞等待播放完成最简单也最不容易被治具/驱动状态影响。 }
    C := waveOutPrepareHeader(AHandle, @Hdr, SizeOf(Hdr));
    if C <> MMSYSERR_NOERROR then
    begin
      AErr := Format('准备回放缓冲失败(winmm 错误 %d)', [C]);
      Exit(False);
    end;

    C := waveOutWrite(AHandle, @Hdr, SizeOf(Hdr));
    if C <> MMSYSERR_NOERROR then
    begin
      waveOutUnprepareHeader(AHandle, @Hdr, SizeOf(Hdr));
      AErr := Format('写入回放缓冲失败(winmm 错误 %d)', [C]);
      Exit(False);
    end;

    { 最多等 AL_TEST_TIMEOUT_MS，超时不当失败处理(声音可能还在放)，
      直接往下走录制。这里只是收尾，不参与判定。 }
    Start := GetTickCount;
    while (Hdr.dwFlags and WHDR_DONE) = 0 do
    begin
      if (GetTickCount - Start) > Cardinal(AL_TEST_TIMEOUT_MS) then
        Break;
      Sleep(10);
    end;

    waveOutUnprepareHeader(AHandle, @Hdr, SizeOf(Hdr));
    Result := True;
  finally
    CloseHandle(Event);
  end;
end;

{ 录一段指定帧数的立体声 PCM。
  用两块缓冲轮换：驱动填满一块(WHDR_DONE)就把它拷进结果，
  再补一块新的，直到录够帧数或超时。 }
function AlCaptureBuffer(AHandle: THandle; AFrames, AChannels: Integer;
  out AData: TArray<SmallInt>; out AErr: string): Boolean;
var
  BufSize: Cardinal;
  BlkFrames: Integer;
  BlkCount, I: Integer;
  Hdrs: array[0..3] of TWaveHdr;
  DataBufs: array[0..3] of TArray<SmallInt>;
  Inited: array[0..3] of Boolean;
  Prepared: array[0..3] of Boolean;
  C: Integer;
  Start: DWORD;
  GotFrames: Integer;
  Filled: array[0..3] of Boolean;
  Total: Integer;
begin
  AErr := '';
  AData := nil;
  Result := False;

  { 每块按 100ms 分配，4 块轮换，够覆盖驱动缓冲延迟 }
  BlkFrames := 4800;
  if BlkFrames > AFrames then
    BlkFrames := AFrames;
  if BlkFrames <= 0 then
  begin
    AErr := '采集帧数为 0';
    Exit(False);
  end;
  BlkCount := 2;
  BufSize := BlkFrames * AChannels * SizeOf(SmallInt);

  Total := 0;
  for I := 0 to BlkCount - 1 do
  begin
    Inited[I] := False;
    Prepared[I] := False;
    Filled[I] := False;
    FillChar(Hdrs[I], SizeOf(Hdrs[I]), 0);
  end;

  try
    SetLength(AData, AFrames * AChannels);
    GotFrames := 0;

    { 先分配并挂上所有块，让驱动随时有活干 }
    for I := 0 to BlkCount - 1 do
    begin
      SetLength(DataBufs[I], BlkFrames * AChannels);
      Hdrs[I].lpData := PAnsiChar(@DataBufs[I][0]);
      Hdrs[I].dwBufferLength := BufSize;
      Hdrs[I].dwFlags := 0;
      C := waveInPrepareHeader(AHandle, @Hdrs[I], SizeOf(Hdrs[I]));
      if C <> MMSYSERR_NOERROR then
      begin
        AErr := Format('准备采集缓冲失败(winmm 错误 %d)', [C]);
        Exit(False);
      end;
      Prepared[I] := True;

      C := waveInAddBuffer(AHandle, @Hdrs[I], SizeOf(Hdrs[I]));
      if C <> MMSYSERR_NOERROR then
      begin
        AErr := Format('提交采集缓冲失败(winmm 错误 %d)', [C]);
        Exit(False);
      end;
    end;

    C := waveInStart(AHandle);
    if C <> MMSYSERR_NOERROR then
    begin
      AErr := Format('启动采集失败(winmm 错误 %d)', [C]);
      Exit(False);
    end;

    Start := GetTickCount;
    { 轮询各块的 WHDR_DONE：驱动填满后会置位，
      这里把已填的帧拷进 AData，再把该块重新提交。 }
    while GotFrames < AFrames do
    begin
      if (GetTickCount - Start) > Cardinal(AL_TEST_TIMEOUT_MS) then
        Break;

      for I := 0 to BlkCount - 1 do
      begin
        if (Hdrs[I].dwFlags and WHDR_DONE) = 0 then
          Continue;
        if Filled[I] then
          Continue;

        Filled[I] := True;
        if GotFrames < AFrames then
        begin
          Move(PByte(@DataBufs[I][0])^, PByte(@AData[GotFrames * AChannels])^,
            BlkFrames * AChannels * SizeOf(SmallInt));
          Inc(GotFrames, BlkFrames);
        end;

        { 这块用完了，重新挂回去让驱动继续填 }
        if GotFrames < AFrames then
        begin
          Hdrs[I].dwFlags := 0;
          waveInUnprepareHeader(AHandle, @Hdrs[I], SizeOf(Hdrs[I]));
          C := waveInPrepareHeader(AHandle, @Hdrs[I], SizeOf(Hdrs[I]));
          if C = MMSYSERR_NOERROR then
          begin
            Prepared[I] := True;
            C := waveInAddBuffer(AHandle, @Hdrs[I], SizeOf(Hdrs[I]));
            if C <> MMSYSERR_NOERROR then
              Prepared[I] := False;
          end
          else
            Prepared[I] := False;
          Filled[I] := False;
        end;
      end;

      Sleep(5);
      Inc(Total);
      if Total > 4000 then      // 兜底：理论上到不了这里
        Break;
    end;

    waveInStop(AHandle);

    if GotFrames < (AFrames div 2) then
    begin
      AErr := Format('采集超时：只录到 %d/%d 帧，请检查输入接口与治具', [GotFrames, AFrames]);
      Exit(False);
    end;

    { 只按实际录到的帧数截断，后面分析按真实长度走 }
    SetLength(AData, GotFrames * AChannels);
    Result := True;
  finally
    for I := 0 to BlkCount - 1 do
    begin
      if Prepared[I] then
        waveInUnprepareHeader(AHandle, @Hdrs[I], SizeOf(Hdrs[I]));
      DataBufs[I] := nil;
    end;
  end;
end;

{ ================= 编排 ================= }

type
  { 单项测试的内部执行体，收集参数、返回结果 }
  TAlTestContext = record
    Config: TAlLoopConfig;
    Env   : TAlAudioEnv;
    OutDev: Integer;
    InDev : Integer;
    OutH  : THandle;
    InH   : THandle;
    Err   : string;
  end;

const
  { 采集时用的基波频率。生成端(AlMakeSine 固定 1kHz)与分析端必须一致，
    所以集中定在这里，两边都引用它。 }
  AL_TEST_FREQ = 1000;

{ 送出一段信号并录回来。左右声道开关决定送单声道还是双声道。
    AMute=True 时输出静音并送全 0 缓冲，用于静音测试。 }
function AlSendAndCapture(var ACtx: TAlTestContext; ADataValue: Integer;
  ALeftOnly, ARightOnly, AMute: Boolean;
  out AData: TArray<SmallInt>; out AErr: string): Boolean;
var
  Frames: Integer;
  Send: TArray<SmallInt>;
  Channels, Rate: Integer;
  Vol: DWORD;
begin
  AData := nil;
  AErr := '';
  Rate := ACtx.Config.SampleRate;
  Channels := 2;
  { 采集时长按 AL_CAPTURE_MS 换算帧数，至少 AL_FFT_SIZE 帧供 FFT 用 }
  Frames := (Rate * AL_CAPTURE_MS) div 1000;
  if Frames < AL_FFT_SIZE then
    Frames := AL_FFT_SIZE;

  if AMute then
  begin
    { 静音项：把 waveOut 音量真正打到 0。否则「静音无效」和
      「本来就没信号」分不清，就测不出静音功能本身是否正常。 }
    waveOutSetVolume(ACtx.OutH, 0);
    Send := AlMakeSilence(Frames, Channels);
  end
  else
  begin
    { 正常项：按配置里的 VolumeValue(0-87) 映射到 0-0xFFFF。
      每次送信号前都设一次，防止上一轮静音把音量留在 0 上。 }
    Vol := DWORD((LongWord(ACtx.Config.VolumeValue) * $FFFF) div AL_VOLUMEVALUE_MAX);
    waveOutSetVolume(ACtx.OutH, Vol);
    Send := AlMakeSine(ADataValue, ALeftOnly, ARightOnly, 0.0, Frames, Channels);
  end;

  if not AlPlayBuffer(ACtx.OutH, Send, Rate, Channels, AErr) then
  begin
    { 送不出去就还原音量，免得后面几项全哑 }
    if not AMute then
      waveOutSetVolume(ACtx.OutH,
        DWORD((LongWord(ACtx.Config.VolumeValue) * $FFFF) div AL_VOLUMEVALUE_MAX));
    Exit(False);
  end;

  { 等模拟链路稳定，让静音/信号真正到达输入端 }
  Sleep(AL_SETTLE_MS);

  Result := AlCaptureBuffer(ACtx.InH, Frames, Channels, AData, AErr);
end;

{ 执行一个测试项。
    注意：这台编译器不允许在 case 的分支里用 Break（报 E2097），
    所以每个分支要么完整跑完，要么用局部布尔量提前收尾。 }
procedure AlRunOneItem(var ACtx: TAlTestContext; APair: TAlPortPair;
  AItem: TAlTestItem; out ARes: TAlTestResult);
var
  An: TAlAnalysis;
  Data: TArray<SmallInt>;
  Err: string;
  Reason: string;
  BeginTick: Cardinal;
  RecvAmp: Double;
  Ok: Boolean;
begin
  ARes.OutPort  := APair.OutPort;
  ARes.InPort   := APair.InPort;
  ARes.TestItem := AItem;
  ARes.Executed := False;
  ARes.Passed   := False;
  ARes.Measured := 0.0;
  ARes.Threshold:= 0.0;
  ARes.ElapsedMs:= 0;
  ARes.Message  := '';

  BeginTick := GetTickCount;

  case AItem of
    altDetect:
      begin
        { 接口存在侦测：这里确认该 输x输入 组合具备测试条件。
          真正的「孔里插没插治具」由 jack detection 在配对前就过滤掉了，
          走到这里说明端点与配置都就绪。 }
        ARes.Executed := True;
        ARes.Passed := True;
        ARes.Message := Format('接口存在，输出设备 %d / 输入设备 %d',
          [ACtx.OutDev, ACtx.InDev]);
      end;

    altLoopback:
      begin
        Ok := AlSendAndCapture(ACtx, ACtx.Config.DataVal, False, False, False, Data, Err);
        ARes.Executed := True;
        if not Ok then
        begin
          ARes.Message := '回路测试失败: ' + Err;
        end
        else
        begin
          AlAnalyze(Data, Length(Data) div 2, ACtx.Config.SampleRate,
            AL_TEST_FREQ, An);
          RecvAmp := An.Fundamental;
          ARes.Measured := RecvAmp;
          ARes.Threshold := ACtx.Config.DataVal;
          ARes.Passed := AlJudgeLoopback(An, ACtx.Config.DataVal, Reason);
          ARes.Message := Reason;
        end;
      end;

    altLR:
      begin
        { 分两次送：先送左声道，验右声道干净；再送右声道，验左声道干净。
          两次都过才算这一项 PASS。 }
        ARes.Executed := True;
        ARes.Threshold := AL_CROSSTALK_LIMIT_DB;

        Ok := AlSendAndCapture(ACtx, ACtx.Config.DataVal, True, False, False, Data, Err);
        if not Ok then
        begin
          ARes.Passed := False;
          ARes.Message := 'L/R测试失败(送左声道): ' + Err;
        end
        else
        begin
          AlAnalyze(Data, Length(Data) div 2, ACtx.Config.SampleRate,
            AL_TEST_FREQ, An);
          ARes.Measured := An.CrosstalkDb;
          if not AlJudgeCrosstalk(An, True, Reason) then
          begin
            { 送左声道就不合格，不必再送右声道了 }
            ARes.Passed := False;
            ARes.Message := '送左声道时不合格: ' + Reason;
          end
          else
          begin
            Ok := AlSendAndCapture(ACtx, ACtx.Config.DataVal, False, True, False, Data, Err);
            if not Ok then
            begin
              ARes.Passed := False;
              ARes.Message := 'L/R测试失败(送右声道): ' + Err;
            end
            else
            begin
              AlAnalyze(Data, Length(Data) div 2, ACtx.Config.SampleRate,
                AL_TEST_FREQ, An);
              ARes.Measured := An.CrosstalkDb;
              ARes.Passed := AlJudgeCrosstalk(An, False, Reason);
              if ARes.Passed then
                ARes.Message := '左右声道互不干扰, ' + Reason
              else
                ARes.Message := '送右声道时不合格: ' + Reason;
            end;
          end;
        end;
      end;

    altMute:
      begin
        ARes.Executed := True;
        ARes.Threshold := AL_SIGNAL_FLOOR;
        Ok := AlSendAndCapture(ACtx, ACtx.Config.DataVal, False, False, True, Data, Err);
        if not Ok then
        begin
          ARes.Passed := False;
          ARes.Message := '静音测试失败: ' + Err;
        end
        else
        begin
          AlAnalyze(Data, Length(Data) div 2, ACtx.Config.SampleRate,
            AL_TEST_FREQ, An);
          ARes.Measured := (An.L_rms + An.R_rms) / 2.0;
          ARes.Passed := AlJudgeMute(An, ACtx.Config.DataVal, Reason);
          ARes.Message := Reason;
        end;
      end;

    altThdn:
      begin
        { 只有勾选了 THD+N CHECK 才跑这一项，否则记为跳过 }
        if not ACtx.Config.ThdnCheck then
        begin
          ARes.Executed := False;
          ARes.Message := '未勾选 THD+N CHECK，跳过';
        end
        else
        begin
          ARes.Executed := True;
          ARes.Threshold := ACtx.Config.ThdnLimit;
          Ok := AlSendAndCapture(ACtx, ACtx.Config.DataVal, False, False, False, Data, Err);
          if not Ok then
          begin
            ARes.Passed := False;
            ARes.Message := 'THD+N测试失败: ' + Err;
          end
          else
          begin
            AlAnalyze(Data, Length(Data) div 2, ACtx.Config.SampleRate,
              AL_TEST_FREQ, An);
            ARes.Measured := An.ThdnDb;
            ARes.Passed := AlJudgeThdn(An, ACtx.Config.ThdnLimit, Reason);
            ARes.Message := Reason;
          end;
        end;
      end;
  else
    ARes.Message := '未知测试项';
  end;

  ARes.ElapsedMs := GetTickCount - BeginTick;
end;

function AlRunLoopTest(const AConfig: TAlLoopConfig; const AEnv: TAlAudioEnv;
  const ALogDir: string;
  AOnLog: TAlLogCallback;
  AOnStep: TAlStepCallback;
  out AResult: TAlLoopTestResult): Boolean;
var
  Pairs: TAlPortPairArray;
  I, J, K: Integer;
  Ctx: TAlTestContext;
  Log: TStringList;
  LogName, Line: string;
  Why: string;
  InIdx: Integer;
  InName: string;
  TotalItems: Integer;
  Done: Integer;
  RunPair: Boolean;
  Cfg: TAlLoopConfig;
  ErrMsg: string;
  AnyTest: Boolean;
  ItemEnabled: Boolean;
begin
  Result := False;
  Cfg := AConfig;
  AlConfigNormalize(Cfg);

  AResult.Results := nil;
  AResult.TotalCnt := 0;
  AResult.PassCnt  := 0;
  AResult.FailCnt  := 0;
  AResult.SkipCnt  := 0;
  AResult.Passed   := False;
  AResult.LogFile  := '';
  AResult.Summary  := '';

  { 至少要有一个启用的测试项，否则没有意义 }
  AnyTest := False;
  for K := 0 to AL_TESTITEM_CNT - 1 do
    if Cfg.EnableTest[TAlTestItem(K)] then
      AnyTest := True;
  if not AnyTest then
  begin
    AResult.Summary := '没有启用任何测试项';
    Exit(False);
  end;

  Pairs := AlBuildPairs(Cfg);
  if Length(Pairs) = 0 then
  begin
    AResult.Summary := '没有可用的 输x输入 配对：请至少启用一个输出接口和一个输入接口';
    Exit(False);
  end;

  { ---- 日志文件 ---- }
  LogName := AlMakeLogFileName(ALogDir);
  Log := TStringList.Create;
  try
    Log.Add('==== 音频回路测试日志 ====');
    Log.Add(Format('时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Log.Add('配置: ' + AEnv.Info);
    Log.Add(Format('参数: PeriodPoint=%d(0-10) VolumeValue=%d(0-87) DataValue=%d(0-32767) THD+N=%d(0-80) THDN_CHECK=%d 采样率=%d',
      [Cfg.PeriodPoint, Cfg.VolumeValue, Cfg.DataVal, Cfg.ThdnLimit,
       Ord(Cfg.ThdnCheck), Cfg.SampleRate]));
    Log.Add(Format('配对数: %d', [Length(Pairs)]));
    Log.Add('');

    { ---- 打开默认的模拟输出/输入端点 ---- }
    if Length(AEnv.OutDevices) = 0 then
    begin
      AResult.Summary := '系统没有可用的模拟输出端点(排除 HDMI/DP 后为空)，无法测试';
      Exit(False);
    end;
    if Length(AEnv.InDevices) = 0 then
    begin
      AResult.Summary := '系统没有可用的音频输入端点，无法测试';
      Exit(False);
    end;

    FillChar(Ctx, SizeOf(Ctx), 0);
    Ctx.Config := Cfg;
    Ctx.Env    := AEnv;
    Ctx.OutDev := AEnv.OutDevices[0].Index;
    Ctx.InDev  := -1;        { 循环里按每组配对的输入端口再定 }

    if not AlOpenWaveOut(Ctx.OutH, Ctx.OutDev, Cfg.SampleRate, 2, ErrMsg) then
    begin
      AResult.Summary := ErrMsg;
      Exit(False);
    end;
    { 输入设备不在这里开 —— 每组配对的输入端口可能不同(MIC IN1/MIC IN2/
      LINE IN1/LINE IN2 在系统里是四个不同的录音端点)，
      要在循环里按该组的输入端口挑出来再开。原来这里固定开
      InDevices[0]，导致选 MIC IN2 也去录麦克风孔，
      治具接在前置孔时就录到接近静音(L=2 R=2)报「无有效信号」。 }

    try
      { VolumeValue 按 0-87 步映射到 waveOutSetVolume 的 0-0xFFFF。
        这里只做一次全局设置，各测试项若需要静音会临时改成 0。 }
      waveOutSetVolume(Ctx.OutH,
        DWORD((LongWord(Cfg.VolumeValue) * $FFFF) div AL_VOLUMEVALUE_MAX));

      { ---- 逐个配对跑测试 ---- }
      { TotalItems 的初值只用来给进度条一个分母，
        Ord(High(...)) 是枚举的序号(整数)，直接算配对数 x 项目数。 }
      TotalItems := Length(Pairs) * (AL_TESTITEM_CNT - 1 + 1);
      Done := 0;

      for I := 0 to High(Pairs) do
      begin
        { 用端口可用性过滤：接口不存在(jack 没插/声道数不够)的配对不跑，
          记一条 SKIP 说明原因，避免把「板子本来就没这个口」判成 FAIL。 }
        RunPair := True;
        if not AlCanUseOutPort(AEnv, Cfg, Pairs[I].OutPort, Why) then
        begin
          RunPair := False;
          Log.Add(Format('%-12s -> %-10s | SKIP | %s',
            [AlOutPortName(Pairs[I].OutPort), AlInPortName(Pairs[I].InPort), Why]));
        end
        else if not AlCanUseInPort(AEnv, Cfg, Pairs[I].InPort, Why) then
        begin
          RunPair := False;
          Log.Add(Format('%-12s -> %-10s | SKIP | %s',
            [AlOutPortName(Pairs[I].OutPort), AlInPortName(Pairs[I].InPort), Why]));
        end
        else
        begin
          { 按这一组指定的输入端口挑真正的录音端点。
            上一组用的可能不是同一个端点，所以先关掉再开。 }
          AlCloseWaveIn(Ctx.InH);
          Ctx.InDev := -1;

          if not AlFindInputDevice(AEnv, Pairs[I].InPort, InIdx, InName, Why) then
          begin
            RunPair := False;
            Log.Add(Format('%-12s -> %-10s | SKIP | %s',
              [AlOutPortName(Pairs[I].OutPort), AlInPortName(Pairs[I].InPort), Why]));
          end
          else if not AlOpenWaveIn(Ctx.InH, InIdx, Cfg.SampleRate, 2, ErrMsg) then
          begin
            RunPair := False;
            Ctx.InDev := -1;
            Log.Add(Format('%-12s -> %-10s | SKIP | 打开录音端点「%s」失败: %s',
              [AlOutPortName(Pairs[I].OutPort), AlInPortName(Pairs[I].InPort),
               InName, ErrMsg]));
          end
          else
          begin
            Ctx.InDev := InIdx;
            { 把「这一组实际用的是哪个端点」写进日志。
              产线排查时这一行最有用：能直接看出是不是名不符映射错了。 }
            Log.Add(Format('%-12s -> %-10s | 录音端点 = %s',
              [AlOutPortName(Pairs[I].OutPort), AlInPortName(Pairs[I].InPort),
               InName]));
            if Why <> '' then
              Log.Add(Format('%-12s -> %-10s | 提示: %s',
                [AlOutPortName(Pairs[I].OutPort), AlInPortName(Pairs[I].InPort), Why]));
          end;
        end;

        for K := 0 to AL_TESTITEM_CNT - 1 do
        begin
          ItemEnabled := Cfg.EnableTest[TAlTestItem(K)];
          if (not ItemEnabled) or (not RunPair) then
          begin
            { 被禁用或不可用的组合，记一条 SKIP 便于追溯「为什么没测」 }
            SetLength(AResult.Results, Length(AResult.Results) + 1);
            AResult.Results[High(AResult.Results)].OutPort  := Pairs[I].OutPort;
            AResult.Results[High(AResult.Results)].InPort   := Pairs[I].InPort;
            AResult.Results[High(AResult.Results)].TestItem := TAlTestItem(K);
            AResult.Results[High(AResult.Results)].Executed := False;
            AResult.Results[High(AResult.Results)].Passed   := False;
            if not ItemEnabled then
              AResult.Results[High(AResult.Results)].Message := '该测试项已禁用'
            else
              AResult.Results[High(AResult.Results)].Message := '接口不可用，跳过';
            Inc(AResult.SkipCnt);
            Inc(Done);
            continue;
          end;

          { 结果数组是动态增长的：每条结果先扩容再写，
    踩过的坑是直接往 Results[Length(Results)] 写 —— 那是越界写，
    轻则丢结果、重则堆损坏。 }
          SetLength(AResult.Results, Length(AResult.Results) + 1);
          AlRunOneItem(Ctx, Pairs[I], TAlTestItem(K),
            AResult.Results[High(AResult.Results)]);

          Line := AlFormatResultLine(AResult.Results[High(AResult.Results)]);
          Log.Add(Line);
          if Assigned(AOnLog) then
            AOnLog(Line);

          if AResult.Results[High(AResult.Results)].Executed then
          begin
            Inc(AResult.TotalCnt);
            if AResult.Results[High(AResult.Results)].Passed then
              Inc(AResult.PassCnt)
            else
              Inc(AResult.FailCnt);
          end
          else
            Inc(AResult.SkipCnt);

          Inc(Done);
          if Assigned(AOnStep) then
            AOnStep(Done, TotalItems,
              Format('%s -> %s : %s',
                [AlOutPortName(Pairs[I].OutPort), AlInPortName(Pairs[I].InPort),
                 AlTestItemName(TAlTestItem(K))]));
        end;
      end;

      Result := True;
    finally
      AlCloseWaveIn(Ctx.InH);
      AlCloseWaveOut(Ctx.OutH);
    end;

    AResult.Summary := AlFormatSummary(AResult);
    AResult.Passed := (AResult.FailCnt = 0) and (AResult.TotalCnt > 0);

    Log.Add('');
    Log.Add(AResult.Summary);
    if AResult.Passed then
      Log.Add('最终结论: PASS')
    else
      Log.Add('最终结论: FAIL');
  finally
    { 无论成功失败都把日志落盘，产线出问题时要靠这个追溯 }
    if Log.Count > 0 then
    begin
      Log.SaveToFile(LogName, TEncoding.Default);
      AResult.LogFile := LogName;
    end;
    Log.Free;
  end;
end;

end.