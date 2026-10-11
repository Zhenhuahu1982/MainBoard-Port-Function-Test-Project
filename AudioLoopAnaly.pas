unit AudioLoopAnaly;

{ 音频回路测试 —— 信号分析单元（纯计算，无硬件依赖）

  这一层只做「拿到一段 16bit PCM 录音 → 得出结论」的事，
  不碰 waveIn/waveOut，所以可以在没有声卡的机器上离线自测。

  各测试项的计算方法（参照通用音频测试做法 + Realtek whdatest 的判据）：

  1) 回路线性度 LOOPBACK
     送 1kHz 正弦，从对应的输入口录回来，算基波幅度。
     判据：录回来的幅度落在「送出去的数据值」对应的合理区间内。
     幅度太小 = 治具没接好/接线断；幅度削顶 = 增益太大。

  2) THD+N
     总谐波失真 + 噪声。用 FFT 找基波 bin，其幅度为 A1，
     其余所有 bin（谐波 2f/3f/... 加带内噪声）能量求和为 N，
       THD+N_dB = 20*log10( sqrt(N) / A1 )
     面板上 THD+N 的取值范围 0-80 就是这个 dB 门限，越小越严格。

  3) 左右声道 L/R
     治具接线是 L 对 L、R 对 R，所以送左-only 信号时右声道应基本干净，
     反之亦然。用互串(dB)作为判据：
       串扰 = 20*log10( 非目标声道 RMS / 目标声道 RMS )
     串扰值越负越好，一般要求 <= -25dB 视为互不干扰。

  4) 静音 MUTE
     输出静音后，录音里不应再有信号。按「绝对电平 + 相对送入幅度」
     两个条件同时判定，避免治具接地不良时的本底噪声被误判成静音失败。

  说明：这些门限是按台式机主板音频的通用水平定的，实测若发现某项
  偏严/偏松，改下面的常量即可，不必动算法。
}

interface

uses
  System.SysUtils, System.Math, System.Classes;

const
  { --- 回路线性度：录音幅度相对送入幅度的可接受区间（线性倍数）--- }
  AL_LOOP_MIN_RATIO = 0.20;   { 低于 20% 视为回路不通 }
  AL_LOOP_MAX_RATIO = 2.50;   { 高于 250% 视为过载/自激 }

  { --- 判定「有信号」的绝对电平门限（16bit 满幅 32767）--- }
  AL_SIGNAL_FLOOR = 60.0;     { RMS 低于此值当作静音底噪 }

  { --- 左右声道互串门限(dB)，越负越严格 --- }
  AL_CROSSTALK_LIMIT_DB = -25.0;

  { --- 静音判定：相对送入电平至少要衰减这么多(dB) --- }
  AL_MUTE_ATTEN_DB = -20.0;

  { --- FFT 规模，必须是 2 的幂 --- }
  AL_FFT_SIZE = 4096;

type
  { 一次分析的结果。通道用下标 0=左 1=右 }
  TAlAnalysis = record
    SampleRate   : Integer;
    Frames       : Integer;      { 有效帧数(每帧含 L/R 两个 sample) }
    L_rms        : Double;       { 左声道 RMS，16bit 幅度 }
    R_rms        : Double;
    Peak_L       : Integer;
    Peak_R       : Integer;
    Fundamental  : Double;       { 基波幅度(FFT 峰值,单边幅度) }
    NoiseRms     : Double;       { 基波以外的 RMS }
    ThdnDb       : Double;       { THD+N(dB)，无有效信号时为 -999 }
    CrosstalkDb  : Double;       { 串扰 dB，负值为好 }
    ActiveCh     : Integer;      { 0=左在响 1=右在响 2=两声道都在响 }
    HasSignal    : Boolean;
  end;

{ ---------------- 正弦波生成 ---------------- }

{ 生成一帧 1kHz 正弦。
    ADataValue  : 峰值幅度(0-32767)，对应面板上的 DataValue
    ALeftOnly / ARightOnly : 只在一个声道出声，用于 L/R 声道测试。
    APhase     : 相位(弧度)，跨帧递增以避免每段波形都从 0 开始导致 DC 跳变
    AFrames    : 生成帧数
    AChannels  : 声道数(本测试固定 2)
  返回 TArray<SmallInt>，交错存放 L,R,L,R... }
function AlMakeSine(ADataValue: Integer; ALeftOnly, ARightOnly: Boolean;
  APhase: Double; AFrames, AChannels: Integer): TArray<SmallInt>;

{ 生成静音帧(全 0) }
function AlMakeSilence(AFrames, AChannels: Integer): TArray<SmallInt>;

{ ---------------- 分析 ---------------- }

{ 分析一段交错 16bit PCM。
    AData      : 采样数据
    AFrames    : 有效帧数
    ASampleRate: 采样率
    AFundFreq  : 基波频率(默认 1000)
  只取前 min(AFrames, 可用长度) 帧；FFT 用前 AL_FFT_SIZE 帧(不足则补零)。 }
procedure AlAnalyze(const AData: TArray<SmallInt>; AFrames, ASampleRate: Integer;
  AFundFreq: Integer; out AAnalysis: TAlAnalysis);

{ 频域能量比。复用到 THD+N 计算里，导出便于单测。 }
function AlThdnFromSamples(const AData: TArray<SmallInt>; ACount, ASampleRate,
  AFundFreq: Integer; out AFundAmp, ANoiseRms: Double): Boolean;

{ 判定「是否听到了声音」。门限 AL_SIGNAL_FLOOR }
function AlHasAudioEnergy(const AAnalysis: TAlAnalysis): Boolean;

{ 本单元自用的四舍五入取整。
  RTL 只导出 Trunc/Round，没有 RoundToInt；用 System.Math.Round 会走
  banker's rounding（.5 向下），这里自己写一条明确的「四舍五入」，
  免得生成正弦时 .5 边界出现难解释的偏差。 }
function AlRoundToInt(AValue: Double): Int64;

{ ---------------- 判定 ---------------- }

{ 回路线性度判定：录音幅度 / 送入幅度 是否落在合理区间 }
function AlJudgeLoopback(const AAnalysis: TAlAnalysis; ASentDataValue: Integer;
  out AReason: string): Boolean;

{ THD+N 判定：实测值 <= 门限(dB)。门限 0 表示不参与判定 }
function AlJudgeThdn(const AAnalysis: TAlAnalysis; ALimitDb: Integer;
  out AReason: string): Boolean;

{ 左右声道判定：送左时右要干净，送右时左要干净 }
function AlJudgeCrosstalk(const AAnalysis: TAlAnalysis; AExpectLeft: Boolean;
  out AReason: string): Boolean;

{ 静音判定：录音里不应再有与送入电平相当的信号 }
function AlJudgeMute(const AAnalysis: TAlAnalysis; ASentDataValue: Integer;
  out AReason: string): Boolean;

implementation

{ ================= 正弦波生成 ================= }

{ 注意：这台机器的编译器不支持 Int64(Double) 直接强转(会报 E2089)，
  必须走 Trunc。Trunc 走 x86 截断指令，对我们的幅度范围完全够用。 }
function AlRoundToInt(AValue: Double): Int64;
begin
  if AValue >= 0 then
    Result := Trunc(AValue + 0.5)
  else
    Result := -Trunc(-AValue + 0.5);
end;

function AlMakeSine(ADataValue: Integer; ALeftOnly, ARightOnly: Boolean;
  APhase: Double; AFrames, AChannels: Integer): TArray<SmallInt>;
var
  I, J: Integer;
  LSample, RSample: Double;
  Inc: Double;
begin
  Result := nil;
  if AFrames <= 0 then
    Exit;
  if AChannels < 1 then
    AChannels := 2;
  if ADataValue < 0 then
    ADataValue := 0;
  if ADataValue > 32767 then
    ADataValue := 32767;

  SetLength(Result, AFrames * AChannels);
  { 一个 1kHz 的相位步进。注意这里只按 1kHz 算，
    真正测试时调用方要保证 AFundFreq 与这里一致(都是 1000)。 }
  Inc := 2.0 * Pi * 1000.0 / 48000.0;

  for I := 0 to AFrames - 1 do
  begin
    { LSample 是本帧的基波值；RSample 先取成同一个值，
      下面再按声道开关单独改，这样两个变量在任何分支下都被赋值过，
      不会留下未初始化的值混进输出缓冲。 }
    LSample := ADataValue * Sin(APhase);
    RSample := LSample;

    if ALeftOnly then
      RSample := 0.0
    else if ARightOnly then
      LSample := 0.0;

    for J := 0 to AChannels - 1 do
    begin
      if (J mod 2) = 0 then
        Result[I * AChannels + J] := SmallInt(AlRoundToInt(LSample))
      else
        Result[I * AChannels + J] := SmallInt(AlRoundToInt(RSample));
    end;
    APhase := APhase + Inc;
    { 相位回绕，避免长时间累加后 double 精度退化 }
    if APhase > 2.0 * Pi then
      APhase := APhase - 2.0 * Pi;
  end;
end;

function AlMakeSilence(AFrames, AChannels: Integer): TArray<SmallInt>;
var
  I: Integer;
begin
  Result := nil;
  if (AFrames <= 0) or (AChannels < 1) then
    Exit;
  SetLength(Result, AFrames * AChannels);
  for I := 0 to Length(Result) - 1 do
    Result[I] := 0;
end;

{ ================= FFT ================= }

type
  TComplex = record
    Re, Im: Double;
  end;
  TComplexArray = array of TComplex;

{ 原地迭代基2 Cooley-Tukey FFT。
    AData 的前 ACount 个元素为输入，结束后复数结果写回同一个数组。

  注意位反转那一圈必须正好走 ACount 次：写成 ACount-1 会漏掉最后一轮
  递增，J 停在最大值，末尾交换时 AData[J] 越界直接崩。 }
procedure AlFFT(var AData: TComplexArray; ACount: Integer);
var
  I, J, M, MMax, Step: Integer;
  TR, TI, WR, WI, Theta: Double;
begin
  if (ACount < 2) or (Length(AData) < ACount) then
    Exit;

  { 位反转重排。
    这里用一个显式的计数器来推进 J，每轮必须保证 0 <= J < ACount。
    之前踩过的坑：循环写 ACount-1 次会漏掉最后一轮递增；
    或者在 I 递增前就先做交换，导致 J 越界。这里按标准写法走：
    先交换、再用 M 逐位把 J 往回退，退到 0 位后前进一位。 }
  J := 0;
  for I := 0 to ACount - 1 do
  begin
    if (I < J) and (J < ACount) then
    begin
      TR := AData[I].Re; AData[I].Re := AData[J].Re; AData[J].Re := TR;
      TI := AData[I].Im; AData[I].Im := AData[J].Im; AData[J].Im := TI;
    end;
    M := ACount shr 1;
    while (M > 0) and (J >= M) do
    begin
      J := J - M;
      M := M shr 1;
    end;
    J := J + M;
    { 正常情况下最后一次 J 会正好等于 ACount（循环随即结束）。
      这里再加一道保险，避免任何意外把下标带出界。 }
    if J >= ACount then
      Break;
  end;

  MMax := 2;
  while MMax <= ACount do
  begin
    Step := MMax shr 1;
    { 这一级的基本旋转因子 W = exp(-2*pi*i/MMax) }
    Theta := -2.0 * Pi / MMax;

    M := 0;
    while M < ACount do
    begin
      I := M;
      while I < M + Step do
      begin
        { 关键：块内第 J 个蝶形(I-M = J)要乘 W^J。
          之前写成 Theta*(M div MMax) —— 那个只跟块号有关、
          跟块内位置无关，等于每个蝶形都用同一个因子，
          算出来根本不是频谱（实测 16000 的基波只能读到 688）。
          这里 J=I-M，角度就是 Theta*J。
          用三角函数直接算而不是靠 W^J 递推：递推连乘上千次后
          模长会偏离 1，4096 点时足以触发 EOverflow 浮点溢出。 }
        J := I - M;
        WR := Cos(Theta * J);
        WI := Sin(Theta * J);

        TR := AData[I + Step].Re * WR - AData[I + Step].Im * WI;
        TI := AData[I + Step].Re * WI + AData[I + Step].Im * WR;
        AData[I + Step].Re := AData[I].Re - TR;
        AData[I + Step].Im := AData[I].Im - TI;
        AData[I].Re := AData[I].Re + TR;
        AData[I].Im := AData[I].Im + TI;
        I := I + 1;
      end;
      M := M + MMax;
    end;
    MMax := MMax shl 1;
  end;
end;

{ 加 Hann 窗。
    实际 THD+N 测量里，不加窗时基波能量会泄漏到相邻 bin，
    被当成噪声算进去，测出来的 THD+N 会偏大。 }
procedure AlApplyHannWindow(var AData: TComplexArray; ACount: Integer);
var
  I: Integer;
  W: Double;
begin
  for I := 0 to ACount - 1 do
  begin
    W := 0.5 * (1.0 - Cos(2.0 * Pi * I / (ACount - 1)));
    AData[I].Re := AData[I].Re * W;
  end;
end;

function AlThdnFromSamples(const AData: TArray<SmallInt>; ACount, ASampleRate,
  AFundFreq: Integer; out AFundAmp, ANoiseRms: Double): Boolean;
var
  Buf: TComplexArray;
  N, NLimit, I, K0, KPeak, KH: Integer;
  Mag, PeakMag, Sum: Double;
  Re, Im: Double;
  SigPower, NoisePower: Double;
  Scale: Double;
  WindowGain: Double;
begin
  AFundAmp := 0.0;
  ANoiseRms := 0.0;
  Result := False;
  if (ASampleRate <= 0) or (AFundFreq <= 0) then
    Exit;

N := ACount;
  if N > AL_FFT_SIZE then
    N := AL_FFT_SIZE;
  if N < 64 then
    Exit;

  { 只支持 2 的幂，把 N 向下取整到「不超过它的最大 2 的幂」。
    注意不能用 `while (N and (N-1)) <> 0 do Dec(N)`：
    那个写法在 N=4095 时会因 4095 and 4094 = 0 而提前退出，
    于是把一个非 2 的幂传进 FFT，位反转那圈下标算错直接崩。
    这里从 64 起不断翻倍，直到超过原始长度就停。 }
  NLimit := N;
  N := 64;
  while (N * 2) <= NLimit do
    N := N * 2;

  SetLength(Buf, N);
  for I := 0 to N - 1 do
  begin
    Buf[I].Re := AData[I];
    Buf[I].Im := 0.0;
  end;

  AlApplyHannWindow(Buf, N);
  AlFFT(Buf, N);

  { 基波大致落在哪个 bin。K0 至少留 1，避免落到 DC }
  K0 := (AFundFreq * N) div ASampleRate;
  if K0 < 2 then
    K0 := 2;
  if K0 > (N div 2 - 2) then
    K0 := N div 2 - 2;

  { 关键：1kHz 在 48kHz/4096 点下落在 bin 85.33 —— 不是整数。
    加 Hann 窗之后能量会摊到相邻 bin 上，所以先在 K0 附近找出
    真正的峰值 bin，再按单边谱公式还原时域幅度：
      幅度 = 2 * |X[峰值]| / (N * 窗相干增益)
    实测：峰值 bin 85 还原出 ~14880，接近真实的 16000
    （差的那点是因为 1kHz 没正好落在 bin 中心，有少量泄漏）。
    注意不能用「相邻 3 个 bin 相加」，那会算成 3 倍，直接虚高。 }
  KPeak := K0;
  PeakMag := -1.0;
  for I := K0 - 2 to K0 + 2 do
  begin
    if (I < 1) or (I > N div 2 - 1) then
      Continue;
    Mag := Sqrt(Buf[I].Re * Buf[I].Re + Buf[I].Im * Buf[I].Im);
    if Mag > PeakMag then
    begin
      PeakMag := Mag;
      KPeak := I;
    end;
  end;

  { Hann 窗相干增益 0.5；单边幅度还原公式 2/(N*相干增益) }
  WindowGain := 0.5;
  Scale := 2.0 / (N * WindowGain);

  AFundAmp := PeakMag * Scale;

  Re := Buf[KPeak].Re;
  Im := Buf[KPeak].Im;
  SigPower := Buf[KPeak].Re * Buf[KPeak].Re + Buf[KPeak].Im * Buf[KPeak].Im;
  K0 := KPeak;

  { 基波相邻的 bin 也算作基波能量，否则加窗泄漏会被误算成噪声。
    上面用 KPeak±1 还原幅度，所以这里要排除 KPeak±3 才够。 }
  NoisePower := 0.0;
  for I := 1 to N div 2 - 1 do
  begin
    KH := I - K0;
    if (KH >= -3) and (KH <= 3) then
      Continue;
    NoisePower := NoisePower + Buf[I].Re * Buf[I].Re + Buf[I].Im * Buf[I].Im;
  end;

  if SigPower <= 0.0 then
    Exit;
  if NoisePower <= 0.0 then
  begin
    ANoiseRms := 0.0;
    Result := True;     { 极干净，THD+N 视为 -inf，用一个很大的负值代表 }
    Exit;
  end;

  { 噪声换算回时域 RMS，再和基波幅度比 }
  ANoiseRms := Sqrt(NoisePower) * Scale;
  Result := True;
end;

{ ================= 综合分析 ================= }

procedure AlAnalyze(const AData: TArray<SmallInt>; AFrames, ASampleRate: Integer;
  AFundFreq: Integer; out AAnalysis: TAlAnalysis);
var
  I, L, R: Integer;
  SumL, SumR, PeakL, PeakR: Double;
  Mono: TArray<SmallInt>;
  Count: Integer;
begin
  FillChar(AAnalysis, SizeOf(AAnalysis), 0);
  AAnalysis.SampleRate := ASampleRate;
  AAnalysis.ThdnDb := -999.0;
  AAnalysis.CrosstalkDb := -999.0;
  AAnalysis.ActiveCh := -1;

  Count := AFrames * 2;
  if Length(AData) < Count then
    Count := Length(AData);
  if (Count < 4) or (AData = nil) then
    Exit;
  Count := Count div 2;            { 换回帧数 }

  SumL := 0.0; SumR := 0.0;
  PeakL := 0.0; PeakR := 0.0;
  for I := 0 to Count - 1 do
  begin
    L := AData[I * 2];
    R := AData[I * 2 + 1];
    SumL := SumL + L * L;
    SumR := SumR + R * R;
    if Abs(L) > PeakL then PeakL := Abs(L);
    if Abs(R) > PeakR then PeakR := Abs(R);
  end;

  AAnalysis.Frames := Count;
  AAnalysis.L_rms := Sqrt(SumL / Count);
  AAnalysis.R_rms := Sqrt(SumR / Count);
  AAnalysis.Peak_L := AlRoundToInt(PeakL);
  AAnalysis.Peak_R := AlRoundToInt(PeakR);

  { 两个声道都取出来分析；左右声道测试只需要单声道信息，
    这里为省事统一用 L+ 混成单声道做频域分析 }
  SetLength(Mono, Count);
  for I := 0 to Count - 1 do
    Mono[I] := SmallInt(AlRoundToInt((AData[I * 2] + AData[I * 2 + 1]) / 2.0));

  if AFundFreq <= 0 then
    AFundFreq := 1000;

  if AlThdnFromSamples(Mono, Count, ASampleRate, AFundFreq,
       AAnalysis.Fundamental, AAnalysis.NoiseRms) then
  begin
    if AAnalysis.NoiseRms <= 0.0 then
      AAnalysis.ThdnDb := -120.0        { 用有限值代表极低失真，日志里可读 }
    else if AAnalysis.Fundamental > 0.0 then
      AAnalysis.ThdnDb := 20.0 * Log10(AAnalysis.NoiseRms / AAnalysis.Fundamental)
    else
      AAnalysis.ThdnDb := 0.0;
  end;

  { 串扰：较强声道当基准，弱声道相对它的 dB }
  if AAnalysis.L_rms >= AAnalysis.R_rms then
  begin
    if AAnalysis.L_rms > 0.0 then
    begin
      if AAnalysis.R_rms > 0.0 then
        AAnalysis.CrosstalkDb := 20.0 * Log10(AAnalysis.R_rms / AAnalysis.L_rms)
      else
        AAnalysis.CrosstalkDb := -120.0;  { 右声道完全是 0，串扰极低 }
    end;
    if AAnalysis.L_rms >= AL_SIGNAL_FLOOR then
      AAnalysis.ActiveCh := 0;
  end
  else
  begin
    if AAnalysis.R_rms > 0.0 then
    begin
      if AAnalysis.L_rms > 0.0 then
        AAnalysis.CrosstalkDb := 20.0 * Log10(AAnalysis.L_rms / AAnalysis.R_rms)
      else
        AAnalysis.CrosstalkDb := -120.0;
    end;
    if AAnalysis.R_rms >= AL_SIGNAL_FLOOR then
      AAnalysis.ActiveCh := 1;
  end;

  { 两个声道都有信号 -> 判定为「两声道都在响」 }
  if (AAnalysis.L_rms >= AL_SIGNAL_FLOOR) and (AAnalysis.R_rms >= AL_SIGNAL_FLOOR) then
    AAnalysis.ActiveCh := 2;

  AAnalysis.HasSignal := AlHasAudioEnergy(AAnalysis);
end;

function AlHasAudioEnergy(const AAnalysis: TAlAnalysis): Boolean;
begin
  Result := (AAnalysis.L_rms >= AL_SIGNAL_FLOOR) or
            (AAnalysis.R_rms >= AL_SIGNAL_FLOOR);
end;

{ ================= 判定 ================= }

function AlJudgeLoopback(const AAnalysis: TAlAnalysis; ASentDataValue: Integer;
  out AReason: string): Boolean;
var
  Recv, Ratio: Double;
begin
  Recv := AAnalysis.Fundamental;
  if Recv <= 0.0 then
    Recv := (AAnalysis.L_rms + AAnalysis.R_rms) / 2.0;

  if not AAnalysis.HasSignal then
  begin
    AReason := Format('回路无信号(L=%.0f R=%.0f,门限=%.0f)',
      [AAnalysis.L_rms, AAnalysis.R_rms, AL_SIGNAL_FLOOR]);
    Exit(False);
  end;

  if ASentDataValue <= 0 then
  begin
    AReason := Format('回路有信号 基波=%.0f', [Recv]);
    Exit(True);
  end;

  Ratio := Recv / ASentDataValue;
  if (Ratio >= AL_LOOP_MIN_RATIO) and (Ratio <= AL_LOOP_MAX_RATIO) then
  begin
    AReason := Format('回路幅度正常 基波=%.0f 送入=%d 比值=%.2f',
      [Recv, ASentDataValue, Ratio]);
    Exit(True);
  end;

  if Ratio < AL_LOOP_MIN_RATIO then
    AReason := Format('回路幅度偏小(比值=%.2f<%.2f) 基波=%.0f 送入=%d',
      [Ratio, AL_LOOP_MIN_RATIO, Recv, ASentDataValue])
  else
    AReason := Format('回路幅度偏大/削顶(比值=%.2f>%.2f) 基波=%.0f 送入=%d',
      [Ratio, AL_LOOP_MAX_RATIO, Recv, ASentDataValue]);
  Result := False;
end;

function AlJudgeThdn(const AAnalysis: TAlAnalysis; ALimitDb: Integer;
  out AReason: string): Boolean;
var
  Limit: Double;
begin
  if ALimitDb <= 0 then
  begin
    AReason := 'THD+N 未参与判定(门限=0)';
    Exit(True);
  end;
  Limit := ALimitDb;

  if not AAnalysis.HasSignal then
  begin
    AReason := Format('无有效信号，无法测 THD+N(L=%.0f R=%.0f)',
      [AAnalysis.L_rms, AAnalysis.R_rms]);
    Exit(False);
  end;

  if AAnalysis.ThdnDb <= Limit then
  begin
    AReason := Format('THD+N=%.1f dB <= 门限 %d dB', [AAnalysis.ThdnDb, ALimitDb]);
    Exit(True);
  end;

  AReason := Format('THD+N=%.1f dB > 门限 %d dB', [AAnalysis.ThdnDb, ALimitDb]);
  Result := False;
end;

function AlJudgeCrosstalk(const AAnalysis: TAlAnalysis; AExpectLeft: Boolean;
  out AReason: string): Boolean;
var
  Target, Other, Cross: Double;
  ChName: string;
begin
  Target := AAnalysis.L_rms;
  Other  := AAnalysis.R_rms;
  if not AExpectLeft then
  begin
    Target := AAnalysis.R_rms;
    Other  := AAnalysis.L_rms;
  end;

  { RTL 的 IfThen 没有 string 重载，这里直接算出声道名 }
  if AExpectLeft then
    ChName := '左'
  else
    ChName := '右';

  if Target < AL_SIGNAL_FLOOR then
  begin
    AReason := Format('%s声道无信号(%.0f),无法验证', [ChName, Target]);
    Exit(False);
  end;

  if Other <= 0.0 then
  begin
    AReason := Format('%s声道 %.0f,另一声道为 0,互不干扰', [ChName, Target]);
    Exit(True);
  end;

  Cross := 20.0 * Log10(Other / Target);
  if Cross <= AL_CROSSTALK_LIMIT_DB then
  begin
    AReason := Format('%s声道 %.0f,串扰 %.1f dB <= %.0f dB,互不干扰',
      [ChName, Target, Cross, AL_CROSSTALK_LIMIT_DB]);
    Exit(True);
  end;

  AReason := Format('%s声道 %.0f,串扰 %.1f dB > %.0f dB,两声道互相干扰',
    [ChName, Target, Cross, AL_CROSSTALK_LIMIT_DB]);
  Result := False;
end;

function AlJudgeMute(const AAnalysis: TAlAnalysis; ASentDataValue: Integer;
  out AReason: string): Boolean;
var
  Level, AttenDb: Double;
begin
  Level := (AAnalysis.L_rms + AAnalysis.R_rms) / 2.0;

  { 条件1：绝对电平必须低于底噪门限 }
  if Level < AL_SIGNAL_FLOOR then
  begin
    AReason := Format('静音正常(电平=%.0f < 底噪门限 %.0f)', [Level, AL_SIGNAL_FLOOR]);
    Exit(True);
  end;

  { 条件2：或相对送入幅度已衰减足够多(防止本底噪声被误判) }
  if ASentDataValue > 0 then
  begin
    AttenDb := 20.0 * Log10(Level / ASentDataValue);
    if AttenDb <= AL_MUTE_ATTEN_DB then
    begin
      AReason := Format('静音正常(电平=%.0f,相对送入衰减 %.1f dB)',
        [Level, AttenDb]);
      Exit(True);
    end;
    AReason := Format('静音异常(电平=%.0f,相对送入 %d 仅衰减 %.1f dB)',
      [Level, ASentDataValue, AttenDb]);
    Exit(False);
  end;

  AReason := Format('静音异常(电平=%.0f > 底噪门限 %.0f)', [Level, AL_SIGNAL_FLOOR]);
  Result := False;
end;

end.