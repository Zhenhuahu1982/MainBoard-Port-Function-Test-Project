program AudioLoopSelfTest;

{ 音频回路测试 —— 离线自测套件
  不需要声卡 / 治具 / 线程，纯验证 AudioLoopAnaly + AudioLoopCfg 的算法与配置逻辑。
  输出 [OK] / [FAIL] 打点，统计通过项数。}

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Math, System.Classes, System.IniFiles, Winapi.Windows,
  AudioLoopCfg, AudioLoopAnaly, AudioLoopDev, AudioLoopTest;

var
  PassCnt, FailCnt: Integer;

{ ---------------- 12. 输入端口 -> 录音端点映射 ---------------- }
{ 回归测试：原来不管选 MIC IN1 还是 MIC IN2，都硬编码打开
  InDevices[0]。用户接前置面板(MicIn2)时就录错端点，
  报「无有效信号，无法测 THD+N(L=2 R=2)」；
  而选 MIC In1 反而"对"了 —— 因为端点 0 恰好就是麦克风孔，
  治具也确实接在麦克风孔上。那是巧合，不是正确。 }
procedure TestInDeviceMapping;
var
  Env: TAlAudioEnv;
  I, Idx, RIdx, FIdx: Integer;
  Nm, Why: string;
begin
  Writeln('[12] 输入端口 -> 录音端点映射');
  AlProbeAudioEnvironment(Env);

  if Length(Env.InDevices) = 0 then
  begin
    Check('本机有输入端点(跳过映射测试)', False, '无输入端点，本机无法测');
    Exit;
  end;
  Check('本机有输入端点', True, '端点数=' + IntToStr(Length(Env.InDevices)));

  { --- 各端口都应能选到一个端点 --- }
  for I := 0 to AL_INPORT_CNT - 1 do
  begin
    Idx := -1; Nm := ''; Why := '';
    Check(AlFindInputDevice(Env, TAlInPort(I), Idx, Nm, Why),
      AlInPortName(TAlInPort(I)) + ' 能选出端点', 'idx=' + IntToStr(Idx) + ' ' + Nm);
    Check(Idx >= 0, AlInPortName(TAlInPort(I)) + ' 端点序号有效',
      IntToStr(Idx));
  end;

  { --- 核心：MIC IN1 与 MIC IN2 不能选到同一个端点 ---
      整机有两个物理麦克风孔(前置/后置)，系统里是两个独立端点。
      选前置就必须录前置那个，否则录的是后置孔，等于没接治具。 }
  if Length(Env.InDevices) >= 2 then
  begin
    Idx := -1; AlFindInputDevice(Env, aipMicRear, Idx, Nm, Why);
    RIdx := Idx;
    Idx := -1; AlFindInputDevice(Env, aipMicFront, Idx, Nm, Why);
    FIdx := Idx;

    { 设备名里能同时区分出前后置时才断言不等 ——
      有些机型只有一个麦克风端点，两个口物理上并到同一个端点，
      那种情况选谁都一样，不该判失败。 }
    if AlNameDistinguishesFrontRear(Env) then
      Check(RIdx <> FIdx, 'MIC IN1 与 MIC IN2 选到不同端点',
        '后置=idx' + IntToStr(RIdx) + ' 前置=idx' + IntToStr(FIdx))
    else
      Check(True, '本机前后置麦克风共用一个端点，跳过不等断言');
  end
  else
    Check(True, '输入端点不足 2 个，跳过前后置不等断言');
end;


procedure Check(const AName: string; AOk: Boolean; const ADetail: string = '');
begin
  if AOk then
  begin
    Inc(PassCnt);
    Writeln('[OK]   ', AName, '  ', ADetail);
  end
  else
  begin
    Inc(FailCnt);
    Writeln('[FAIL] ', AName, '  ', ADetail);
  end;
end;

{ ---------------- 1. 正弦波生成 ---------------- }
procedure TestSineGen;
var
  Buf: TArray<SmallInt>;
  I, Peak: Integer;
  SumSq: Double;
begin
  Writeln('[1] 正弦波生成');

  { 幅度 16384 应产生接近 16384 的峰值 }
  Buf := AlMakeSine(16384, False, False, 0.0, 4800, 2);
  Check('生成帧数正确', Length(Buf) = 4800 * 2, 'len=' + IntToStr(Length(Buf)));

  Peak := 0;
  for I := 0 to High(Buf) do
    if Abs(Buf[I]) > Peak then Peak := Abs(Buf[I]);
  Check('峰值接近设定幅度', (Peak > 16000) and (Peak <= 16384), 'peak=' + IntToStr(Peak));

  { 双声道信号 L 和 R 必须完全一致(治具是 L-L / R-R) }
  Check('双声道默认一致', Buf[0] = Buf[1]);

  { RMS 理论值 = 峰值/sqrt(2) ≈ 11585 }
  SumSq := 0.0;
  for I := 0 to 4799 do SumSq := SumSq + Buf[I * 2] * Buf[I * 2];
  SumSq := Sqrt(SumSq / 4800);
  Check('RMS 接近 峰值/sqrt(2)', (SumSq > 11000) and (SumSq < 12000),
    Format('rms=%.0f expect=%.0f', [SumSq, 16384 / Sqrt(2.0)]));

  { LeftOnly：右声道必须全 0 }
  Buf := AlMakeSine(16384, True, False, 0.0, 4800, 2);
  Check('LeftOnly 右声道为 0', Buf[1] = 0, 'R[0]=' + IntToStr(Buf[1]));

  { RightOnly：左声道必须全 0 }
  Buf := AlMakeSine(16384, False, True, 0.0, 4800, 2);
  Check('RightOnly 左声道为 0', Buf[0] = 0, 'L[0]=' + IntToStr(Buf[0]));

  { 静音帧全 0 }
  Buf := AlMakeSilence(100, 2);
  Check('静音帧全 0', (Buf[0] = 0) and (Buf[199] = 0));
end;

{ ---------------- 2. 理想信号分析 ---------------- }
procedure TestIdealAnalysis;
var
  Buf: TArray<SmallInt>;
  An: TAlAnalysis;
begin
  Writeln('[2] 理想信号分析');

  { 满幅 1kHz 正弦应当：THD+N 极低、有信号、两声道都在响 }
  Buf := AlMakeSine(16000, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('识别到信号', An.HasSignal);
  Check('两声道都在响', An.ActiveCh = 2, 'ActiveCh=' + IntToStr(An.ActiveCh));
  Check('基波幅度接近设定', (An.Fundamental > 14000) and (An.Fundamental < 18000),
    Format('fund=%.0f', [An.Fundamental]));
  Check('纯正弦 THD+N 很低', An.ThdnDb < -40.0, Format('THD+N=%.1f dB', [An.ThdnDb]));

  { 静音输入：无信号 }
  Buf := AlMakeSilence(8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('静音判为无信号', not An.HasSignal);
end;

{ ---------------- 3. FFT 正确性 ---------------- }
procedure TestFFT;
var
  Fund, Noise: Double;
  Cnt, I: Integer;
  Buf: TArray<SmallInt>;
  Mono: TArray<SmallInt>;
begin
  Writeln('[3] FFT / THD+N 计算');

  { AlThdnFromSamples 收的是「单声道」序列，所以这里先把交错的 L/R
    混成单声道再喂进去 —— 直接把立体声交错数据丢进去，
    读到的会是 L,R,L,R 交替的锯齿，基波会落在 2kHz 附近而不是 1kHz。
    AlAnalyze 内部也是这么做的。 }
  Buf := AlMakeSine(16384, False, False, 0.0, 4096, 2);
  Cnt := Length(Buf) div 2;
  SetLength(Mono, Cnt);
  for I := 0 to Cnt - 1 do
    Mono[I] := Buf[I * 2];

  { 4096 点、1kHz：bin 间隔 =48000/4096=11.72Hz，1kHz 落在 bin 85 附近。
    理论上单 bin 还原出的幅度约 0.93*16384 ≈ 15200（1kHz 没正好落在
    bin 中心，有少量泄漏），所以判 14000~17000 这个区间。 }
  Check('THD+N 可计算', AlThdnFromSamples(Mono, Cnt, 48000, 1000, Fund, Noise));
  Check('基波幅度接近 16384', (Fund > 14000) and (Fund < 17000),
    Format('fund=%.0f', [Fund]));
  Check('噪声远小于基波', Noise < Fund * 0.1,
    Format('noise=%.0f fund=%.0f ratio=%.4f', [Noise, Fund, Noise / Fund]));

  { 数据不足时应返回 False 而不是崩 }
  Buf := AlMakeSine(16384, False, False, 0.0, 32, 2);
  Cnt := Length(Buf) div 2;
  SetLength(Mono, Cnt);
  for I := 0 to Cnt - 1 do
    Mono[I] := Buf[I * 2];
  Check('点数过少时安全返回 False',
    not AlThdnFromSamples(Mono, Cnt, 48000, 1000, Fund, Noise));
end;

{ ---------------- 4. 左右声道互不干扰 ---------------- }
procedure TestLRCrosstalk;
var
  Buf: TArray<SmallInt>;
  An: TAlAnalysis;
  Reason: string;
begin
  Writeln('[4] 左右声道互不干扰');

  { 送左声道：左响、右静 -> 应判为 PASS }
  Buf := AlMakeSine(16384, True, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('左声道在响', An.ActiveCh = 0, 'ActiveCh=' + IntToStr(An.ActiveCh));
  Check('左声道测试 PASS', AlJudgeCrosstalk(An, True, Reason), Reason);

  { 送右声道：右响、左静 -> 应判为 PASS }
  Buf := AlMakeSine(16384, False, True, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('右声道在响', An.ActiveCh = 1, 'ActiveCh=' + IntToStr(An.ActiveCh));
  Check('右声道测试 PASS', AlJudgeCrosstalk(An, False, Reason), Reason);

  { 两声道串扰：两个声道都有信号 -> 应判 FAIL(互相干扰) }
  Buf := AlMakeSine(16384, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('双声道同时响判为串扰 FAIL',
    not AlJudgeCrosstalk(An, True, Reason), Reason);

  { 目标声道没声音 -> FAIL(无法验证) }
  Buf := AlMakeSine(16384, True, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('右声道期望时无信号判 FAIL',
    not AlJudgeCrosstalk(An, False, Reason), Reason);
end;

{ ---------------- 5. 静音判定 ---------------- }
procedure TestMute;
var
  Buf: TArray<SmallInt>;
  An: TAlAnalysis;
  Reason: string;
begin
  Writeln('[5] 静音判定');

  { 静音帧 -> PASS }
  Buf := AlMakeSilence(8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('静音后无残留信号 PASS', AlJudgeMute(An, 16384, Reason), Reason);

  { 静音后仍有满幅信号 -> FAIL(静音无效) }
  Buf := AlMakeSine(16384, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('静音后仍有大信号 FAIL', not AlJudgeMute(An, 16384, Reason), Reason);
end;

{ ---------------- 6. 回路线性度 ---------------- }
procedure TestLoopback;
var
  Buf: TArray<SmallInt>;
  An: TAlAnalysis;
  Reason: string;
begin
  Writeln('[6] 回路线性度');

  { 送 16384、收~16384 -> PASS }
  Buf := AlMakeSine(16384, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('幅度 1:1 PASS', AlJudgeLoopback(An, 16384, Reason), Reason);

  { 送 16384、只收到很小信号 -> FAIL(回路不通) }
  Buf := AlMakeSine(800, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('信号过小 FAIL', not AlJudgeLoopback(An, 16384, Reason), Reason);

  { 完全没信号 -> FAIL }
  Buf := AlMakeSilence(8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('完全无信号 FAIL', not AlJudgeLoopback(An, 16384, Reason), Reason);

  { 收到的幅度超过送入的 2.5 倍 -> FAIL(削顶/自激)。
    送 32767(接近满幅)、按送入值 10000 判定，比值 3.3 倍，越过上限。
    注意这里「送入值」和「生成幅度」是分开的：现实里回环增益不为 1，
    判定基准是操作员在面板上填的 DataValue。 }
  Buf := AlMakeSine(32767, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('幅度过大 FAIL', not AlJudgeLoopback(An, 10000, Reason), Reason);
end;

{ ---------------- 7. THD+N 判定 ---------------- }
procedure TestThdnJudge;
var
  Buf: TArray<SmallInt>;
  An: TAlAnalysis;
  Reason: string;
begin
  Writeln('[7] THD+N 判定');

  Buf := AlMakeSine(16384, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);

  Check('门限 80dB 时 PASS', AlJudgeThdn(An, 80, Reason), Reason);
  Check('门限 0 表示不参与判定 PASS', AlJudgeThdn(An, 0, Reason), Reason);

  { 无信号时即使门限很大也应 FAIL(测不出 THD+N 属异常) }
  Buf := AlMakeSilence(8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  Check('无信号时 THD+N FAIL', not AlJudgeThdn(An, 80, Reason), Reason);
end;

{ ---------------- 8. 加谐波验证 THD+N 灵敏度 ---------------- }
procedure TestThdnSensitivity;
var
  Buf: TArray<SmallInt>;
  An: TAlAnalysis;
  I: Integer;
  Ph: Double;
  CleanDb, DirtyDb: Double;
begin
  Writeln('[8] THD+N 对谐波的灵敏度');

  { 基波 16000 + 3% 的三次谐波(480)。
    理论 THD+N = 20*log10(480/16000) ≈ -30.5 dB，
    实测应该在 -35 ~ -25 dB 之间。判「明显抬升」不能只看 > -10，
    因为数值算对了之后纯正弦的 THD+N 本来就在 -100 dB 以下，
    -27.9 dB 恰好说明算法把谐波能量算对了。 }
  SetLength(Buf, 8192 * 2);
  Ph := 0.0;
  for I := 0 to 8191 do
  begin
    Buf[I * 2] := SmallInt(AlRoundToInt(16000 * Sin(Ph) + 480.0 * Sin(3.0 * Ph)));
    Buf[I * 2 + 1] := Buf[I * 2];
    Ph := Ph + 2.0 * Pi * 1000.0 / 48000.0;
  end;
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  DirtyDb := An.ThdnDb;
  Check('加谐波后 THD+N 接近理论值 -30.5dB',
    (DirtyDb > -40.0) and (DirtyDb < -22.0),
    Format('THD+N=%.1f dB (理论 -30.5)', [DirtyDb]));

  { 同样长度的纯正弦作对照，必须比带谐波的干净
    (THD+N 三次谐波理论值 = 20log10(480/16000) ≈ -30.5dB) }
  Buf := AlMakeSine(16000, False, False, 0.0, 8192, 2);
  AlAnalyze(Buf, 8192, 48000, 1000, An);
  CleanDb := An.ThdnDb;
  Check('纯正弦明显优于带谐波', CleanDb < DirtyDb - 10.0,
    Format('clean=%.1f dB  dirty=%.1f dB', [CleanDb, DirtyDb]));
end;

{ ---------------- 9. 配置读写 ---------------- }
procedure TestConfig;
var
  Cfg, Cfg2: TAlLoopConfig;
  TmpFile: string;
  I: Integer;
begin
  Writeln('[9] 配置读写');

  AlConfigDefault(Cfg);
  Check('默认 PeriodPoint 在范围内',
    (Cfg.PeriodPoint >= AL_PERIODPOINT_MIN) and (Cfg.PeriodPoint <= AL_PERIODPOINT_MAX));
  Check('默认 VolumeValue 在范围内',
    (Cfg.VolumeValue >= AL_VOLUMEVALUE_MIN) and (Cfg.VolumeValue <= AL_VOLUMEVALUE_MAX));
  Check('默认 DataValue 在范围内',
    (Cfg.DataVal >= AL_DATAVALUE_MIN) and (Cfg.DataVal <= AL_DATAVALUE_MAX));
  Check('默认 THD+N 在范围内',
    (Cfg.ThdnLimit >= AL_THDN_MIN) and (Cfg.ThdnLimit <= AL_THDN_MAX));

  { 越界值应被夹紧 }
  Check('夹紧上限', AlClampInt(9999, 0, 87) = 87);
  Check('夹紧下限', AlClampInt(-5, 0, 87) = 0);
  Check('范围内不动', AlClampInt(50, 0, 87) = 50);

  Cfg.PeriodPoint := 7;
  Cfg.VolumeValue := 33;
  Cfg.DataVal := 20000;
  Cfg.ThdnLimit := 20;
  Cfg.EnableOut[aopSurr] := False;
  Cfg.EnableIn[aipLineIn2] := False;
  Cfg.EnableTest[altThdn] := False;

  TmpFile := ExtractFilePath(ParamStr(0)) + 'AudioLoopCfgTest.ini';
  Check('配置保存成功', AlConfigSave(TmpFile, Cfg));
  Check('配置读回成功', AlConfigLoad(TmpFile, Cfg2));
  Check('PeriodPoint 往返一致', Cfg2.PeriodPoint = 7, IntToStr(Cfg2.PeriodPoint));
  Check('VolumeValue 往返一致', Cfg2.VolumeValue = 33);
  Check('DataVal 往返一致', Cfg2.DataVal = 20000);
  Check('THD+N 往返一致', Cfg2.ThdnLimit = 20);
  Check('禁用的输出端口往返一致', Cfg2.EnableOut[aopSurr] = False);
  Check('禁用的输入端口往返一致', Cfg2.EnableIn[aipLineIn2] = False);
  Check('禁用的测试项往返一致', Cfg2.EnableTest[altThdn] = False);
  Check('其它端口保持启用', Cfg2.EnableOut[aopFront] = True);

  { 文件不存在时应自动生成默认配置而不是报错 }
  DeleteFile(PWideChar(TmpFile + '.notexist'));
  Check('缺文件时生成默认配置', AlConfigLoad(TmpFile + '.notexist', Cfg2));
  Check('缺文件时默认值正确', Cfg2.VolumeValue = AL_DEF_VOLUMEVALUE);

  { 枚举名互转 }
  for I := 0 to AL_OUTPORT_CNT - 1 do
    Check('输出端口名往返 ' + AlOutPortName(TAlOutPort(I)),
      AlOutPortIndex(AlOutPortName(TAlOutPort(I))) = TAlOutPort(I));
  for I := 0 to AL_INPORT_CNT - 1 do
    Check('输入端口名往返 ' + AlInPortName(TAlInPort(I)),
      AlInPortIndex(AlInPortName(TAlInPort(I))) = TAlInPort(I));
  for I := 0 to AL_TESTITEM_CNT - 1 do
    Check('测试项名往返 ' + AlTestItemName(TAlTestItem(I)),
      AlTestItemIndex(AlTestItemName(TAlTestItem(I))) = TAlTestItem(I));

  DeleteFile(PWideChar(TmpFile));
  DeleteFile(PWideChar(TmpFile + '.notexist'));
end;
{ ---------------- 11. 读取独立参数设置程序写的配置 ---------------- }
{ 独立参数设置程序(AudioLoopParamSet.exe)写 AudioLoopParam.ini，
  格式是逗号串：[AudioLoopOut] Enable = 1,0,1
  测试程序只读这一个文件，读到什么按什么测。 }
procedure TestParamFile;
var
  FName: string;
  Ini: TIniFile;
  Cfg, Cfg2: TAlLoopConfig;
  Why: string;
begin
  Writeln('[11] 读取独立参数设置程序的配置');

  FName := ExtractFilePath(ParamStr(0)) + '_AudioLoopParamTest.ini';
  DeleteFile(PWideChar(FName));

  { --- 关键：文件不存在时必须报错，不能默默用默认值 ---
      产线语义下「参数设置程序没运行过」不等于「参数就是默认值」。
      默默拿默认值去测，板子真坏了也会判成合格。 }
  Check('文件不存在时返回 False', not AlParamLoadFromFile(FName, Cfg, Why));
  Check('文件不存在时给出原因', Why <> '', '长度=' + IntToStr(Length(Why)));
  Check('原因里点名了配置文件', Pos('AudioLoopParam', Why) > 0,
    Copy(Why, 1, 40));

  { 手工写出参数设置程序那套格式：关掉 FRONT OUT 和 MIC IN2 }
  Ini := TIniFile.Create(FName);
  try
    Ini.WriteString('AudioLoop', 'SampleRate', '44100');
    Ini.WriteString('AudioLoop', 'PeriodPoint', '7');
    Ini.WriteString('AudioLoop', 'VolumeValue', '33');
    Ini.WriteString('AudioLoop', 'DataValue', '20000');
    Ini.WriteString('AudioLoop', 'ThdnLimit', '20');
    Ini.WriteString('AudioLoop', 'ThdnCheck', '0');
    Ini.WriteString('AudioLoopOut', 'Enable', '0,1,1');
    Ini.WriteString('AudioLoopOut', 'EnableJD', '0,1,0');
    Ini.WriteString('AudioLoopIn', 'Enable', '1,0,1,0');
    Ini.WriteString('AudioLoopIn', 'EnableJD', '1,1,0,0');
    Ini.WriteString('AudioLoopTest', 'Enable', '1,1,0,1,0');
  finally
    Ini.Free;
  end;

  Why := '';
  Check('能读参数设置程序的格式', AlParamLoadFromFile(FName, Cfg, Why), Why);
  Check('FRONT OUT 读到禁用', Cfg.EnableOut[aopFront] = False);
  Check('SURR OUT 读到启用', Cfg.EnableOut[aopSurr] = True);
  Check('CEN/LFE OUT 读到启用', Cfg.EnableOut[aopCenLfe] = True);
  Check('OutJD FRONT 禁用', Cfg.EnableJD[aopFront] = False);
  Check('OutJD SURR 启用', Cfg.EnableJD[aopSurr] = True);
  Check('OutJD CENLFE 禁用', Cfg.EnableJD[aopCenLfe] = False);
  Check('MIC IN1 读到启用', Cfg.EnableIn[aipMicRear] = True);
  Check('MIC IN2 读到禁用', Cfg.EnableIn[aipMicFront] = False);
  Check('LINE IN1 读到启用', Cfg.EnableIn[aipLineIn1] = True);
  Check('LINE IN2 读到禁用', Cfg.EnableIn[aipLineIn2] = False);
  Check('InJD MIC1 启用', Cfg.EnableJDIn[aipMicRear] = True);
  Check('InJD LINE1 禁用', Cfg.EnableJDIn[aipLineIn1] = False);
  Check('DETECT 读到启用', Cfg.EnableTest[altDetect] = True);
  Check('LOOPBACK 读到启用', Cfg.EnableTest[altLoopback] = True);
  Check('L/R 读到禁用', Cfg.EnableTest[altLR] = False);
  Check('MUTE 读到启用', Cfg.EnableTest[altMute] = True);
  Check('THD+N 读到禁用', Cfg.EnableTest[altThdn] = False);
  Check('PeriodPoint 读到 7', Cfg.PeriodPoint = 7, IntToStr(Cfg.PeriodPoint));
  Check('VolumeValue 读到 33', Cfg.VolumeValue = 33);
  Check('DataVal 读到 20000', Cfg.DataVal = 20000);
  Check('ThdnLimit 读到 20', Cfg.ThdnLimit = 20);
  Check('ThdnCheck 读到 False', Cfg.ThdnCheck = False);
  Check('SampleRate 读到 44100', Cfg.SampleRate = 44100);

  { 配对矩阵应随之变成 2 输出 x 2 输入 = 4 组 }
  Check('配对数 = 2x2 = 4', Length(AlBuildPairs(Cfg)) = 4,
    IntToStr(Length(AlBuildPairs(Cfg))));

  { 列表位数不足时补默认(启用)，不能默默少测 }
  Ini := TIniFile.Create(FName);
  try
    Ini.WriteString('AudioLoopOut', 'Enable', '0,1');
  finally
    Ini.Free;
  end;
  Check('重读成功', AlParamLoadFromFile(FName, Cfg, Why), Why);
  Check('只给 2 位: FRONT 禁用', Cfg.EnableOut[aopFront] = False);
  Check('只给 2 位: SURR 启用', Cfg.EnableOut[aopSurr] = True);
  Check('只给 2 位: CENLFE 补为启用', Cfg.EnableOut[aopCenLfe] = True);

  { 缺关键节时也要报错，不能读成全默认 }
  DeleteFile(PWideChar(FName));
  Ini := TIniFile.Create(FName);
  try
    Ini.WriteString('AudioLoop', 'PeriodPoint', '4');
  finally
    Ini.Free;
  end;
  Why := '';
  Check('缺 [AudioLoopOut] 时返回 False', not AlParamLoadFromFile(FName, Cfg2, Why));
  Check('缺节时给出原因', Why <> '');

  DeleteFile(PWideChar(FName));
end;

{ ---------------- 10. 端口配对矩阵 ---------------- }
procedure TestPairing;
var
  Cfg: TAlLoopConfig;
  Pairs: TAlPortPairArray;
  I, J: Integer;
  HasFrontLineIn, HasFrontMicRear: Boolean;
  DupCnt: Integer;
begin
  Writeln('[10] 端口配对矩阵');

  { 场景1：只有 1 个输出 + 1 个输入 -> 应产生 1 对 }
  AlConfigDefault(Cfg);
  for I := 0 to AL_OUTPORT_CNT - 1 do
    if TAlOutPort(I) <> aopFront then Cfg.EnableOut[TAlOutPort(I)] := False;
  for I := 0 to AL_INPORT_CNT - 1 do
    if TAlInPort(I) <> aipLineIn1 then Cfg.EnableIn[TAlInPort(I)] := False;
  Pairs := AlBuildPairs(Cfg);
  Check('单输出+单输入 = 1 对', Length(Pairs) = 1, 'pairs=' + IntToStr(Length(Pairs)));
  if Length(Pairs) = 1 then
  begin
    Check('配对为 FRONT->LINE IN1',
      (Pairs[0].OutPort = aopFront) and (Pairs[0].InPort = aipLineIn1),
      AlOutPortName(Pairs[0].OutPort) + ' -> ' + AlInPortName(Pairs[0].InPort));
  end;

  { 场景2：3 孔位(Front, LineIn, MicIn) -> Front 应配 LineIn 和 MicIn }
  AlConfigDefault(Cfg);
  for I := 0 to AL_OUTPORT_CNT - 1 do
    if TAlOutPort(I) <> aopFront then Cfg.EnableOut[TAlOutPort(I)] := False;
  for I := 0 to AL_INPORT_CNT - 1 do
    if not ((TAlInPort(I) = aipLineIn1) or (TAlInPort(I) = aipMicRear))
       then Cfg.EnableIn[TAlInPort(I)] := False;
  Pairs := AlBuildPairs(Cfg);
  Check('3 孔位产生 2 对', Length(Pairs) = 2, 'pairs=' + IntToStr(Length(Pairs)));
  HasFrontLineIn := False;
  HasFrontMicRear := False;
  for I := 0 to High(Pairs) do
  begin
    if (Pairs[I].OutPort = aopFront) and (Pairs[I].InPort = aipLineIn1) then HasFrontLineIn := True;
    if (Pairs[I].OutPort = aopFront) and (Pairs[I].InPort = aipMicRear) then HasFrontMicRear := True;
  end;
  Check('含 Front->LineIn1', HasFrontLineIn);
  Check('含 Front->MIC IN1', HasFrontMicRear);

  { 场景3：含前置音频接口时应额外增加 Front->前置MIC、其它输出->前置MIC }
  AlConfigDefault(Cfg);
  for I := 0 to AL_INPORT_CNT - 1 do
    if TAlInPort(I) <> aipMicFront then Cfg.EnableIn[TAlInPort(I)] := False;
  Pairs := AlBuildPairs(Cfg);
  Check('含前置MIC时所有输出都配对', Length(Pairs) = 3,
    'pairs=' + IntToStr(Length(Pairs)));

  { 场景4：全禁 -> 无配对(必须有至少一个输出和一个输入) }
  AlConfigDefault(Cfg);
  for I := 0 to AL_OUTPORT_CNT - 1 do Cfg.EnableOut[TAlOutPort(I)] := False;
  Pairs := AlBuildPairs(Cfg);
  Check('无输出接口时不产生配对', Length(Pairs) = 0);
  AlConfigDefault(Cfg);
  for I := 0 to AL_INPORT_CNT - 1 do Cfg.EnableIn[TAlInPort(I)] := False;
  Pairs := AlBuildPairs(Cfg);
  Check('无输入接口时不产生配对', Length(Pairs) = 0);

  { 场景5：Surr 输出只配 LineIn/MicIn，不配前置 MIC(前置MIC是输入口，配给每个输出才对) }
  AlConfigDefault(Cfg);
  Pairs := AlBuildPairs(Cfg);
  { 查重：只比较下标不同的一对，否则自己跟自己比必然「重复」 }
  DupCnt := 0;
  for I := 0 to High(Pairs) do
    for J := I + 1 to High(Pairs) do
      if (Pairs[I].OutPort = Pairs[J].OutPort) and (Pairs[I].InPort = Pairs[J].InPort) then
      begin
        Inc(DupCnt);
        Writeln('       重复: ', AlOutPortName(Pairs[I].OutPort), '->',
          AlInPortName(Pairs[I].InPort));
      end;
  Check('配对无重复', DupCnt = 0, '重复数=' + IntToStr(DupCnt));
  Check('全开时配对数 = 3输出 x 4输入', Length(Pairs) = 12,
    'pairs=' + IntToStr(Length(Pairs)));
end;

var
  StartTicks: Cardinal;
begin
  StartTicks := GetTickCount;
  Writeln('==========================================================');
  Writeln(' 音频回路测试 离线自测套件');
  Writeln('==========================================================');

  TestSineGen;
  TestIdealAnalysis;
  TestFFT;
  TestLRCrosstalk;
  TestMute;
  TestLoopback;
  TestThdnJudge;
  TestThdnSensitivity;
  TestConfig;
  TestPairing;
  TestParamFile;
  TestInDeviceMapping;

  Writeln('==========================================================');
  Writeln(Format(' 结果: [OK] %d 项 / [FAIL] %d 项，耗时 %d ms',
    [PassCnt, FailCnt, GetTickCount - StartTicks]));
  if FailCnt = 0 then
    Writeln(' 全部通过')
  else
    Writeln(' 存在失败项');
  Writeln('==========================================================');
  if FailCnt > 0 then
    Halt(1);
end.