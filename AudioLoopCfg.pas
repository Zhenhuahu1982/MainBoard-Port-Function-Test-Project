unit AudioLoopCfg;

{ 音频回路测试 —— 公共类型定义与配置文件读写

  参照 Realtek whdatest(HD Codec Test Program) 的工作方式：
    OUT_PORT  输出接口：FRONT OUT / SURR OUT / CEN-LFE OUT
    IN_PORT   输入接口：MIC IN1(后置) / MIC IN2(前置) / LINE IN1 / LINE IN2
    功能测试项：LOOPBACK(回路) / THD+N / L-R(左右声道) / MUTE(静音)
    JD PORT TEST：接口存在侦测

  设计要点：
    1. 零窗体依赖，只用 RTL，可与 AudioLoopAnaly 一起做离线自测。
    2. 每个接口、每个测试项都能单独启用/禁用，由配置记录里的布尔数组控制。
    3. 四个接口数值可单独设置，取值范围按 Realtek 工具的约定：
         PeriodPoint (0-10)
         VolumeValue (0-87)     0x00~0x57，87 步音量
         DataVal     (0-32767)   16bit 采样数据的波形幅度值
         THD+N       (0-80)      判定门限，单位 dB，越小越严
    4. 配置存 AudioLoopCfg.ini，读写都做范围夹紧，配置文件被改坏也不会让程序崩。

  关于「接口存在」的判定：
    声卡驱动向上层暴露的是端点(endpoint)，而 Front/Rear、Line/Mic 这些物理孔
    是挂在同一个 HDA Codec 下的不同 pin/jack。所以本模块区分两层：
      - 「端点是否存在」：由 AudioLoopDev 枚举 wave 设备时判断（排除 HDMI/DP）。
      - 「物理孔是否存在」：由 jack detection(KS jack description) 判断。
    两者都满足才认为该接口可用于回路测试。
}

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, Winapi.Windows;

const
  { ---- 四个接口数值的取值范围（与 Realtek 工具一致）---- }
  AL_PERIODPOINT_MIN = 0;
  AL_PERIODPOINT_MAX = 10;
  AL_VOLUMEVALUE_MIN = 0;
  AL_VOLUMEVALUE_MAX = 87;
  AL_DATAVALUE_MIN   = 0;
  AL_DATAVALUE_MAX   = 32767;
  AL_THDN_MIN        = 0;
  AL_THDN_MAX        = 80;

  { ---- 默认值：Realtek 量产工具的常用基准 ---- }
  AL_DEF_PERIODPOINT = 4;      { 10ms @48KHz 附近，兼顾稳定性与响应速度 }
  AL_DEF_VOLUMEVALUE = 60;     { 约 69% 音量，留足不失真的余量 }
  AL_DEF_DATAVALUE   = 16384;  { 约 0.5 满幅，避免过载失真 }
  AL_DEF_THDN        = 80;     { 门限放到最大，实际由硬件能力决定 }

  AL_CFG_FILE = 'AudioLoopCfg.ini';

  { 音频回路参数设置程序(AudioLoopParamSet.exe)写的配置文件。
    与上面的 AL_CFG_FILE 是两个不同文件：那个是测试程序自己的，
    这个只由参数设置程序写、测试程序只读。两个程序各写各的，
    不会互相覆盖。 }
  AL_PARAM_FILE = 'AudioLoopParam.ini';

type
  { 输出接口。Front/Surr/Cen-Lfe 对应 HDA 的三个 DAC pin 方向 }
  TAlOutPort = (aopFront, aopSurr, aopCenLfe, aopOutCount);
  { 输入接口。后置 MIC / 前置 MIC / 两个 Line In }
  TAlInPort  = (aipMicRear, aipMicFront, aipLineIn1, aipLineIn2, aipInCount);

  { 功能测试项，与 Realtek 工具的勾选项一一对应 }
  TAlTestItem = (altDetect, altLoopback, altLR, altMute, altThdn, altTestCount);

  { 一条测试结果：一个 输出接口 x 一个 输入接口 x 一个 测试项 }
  TAlTestResult = record
    OutPort    : TAlOutPort;
    InPort     : TAlInPort;
    TestItem   : TAlTestItem;
    Executed   : Boolean;      { False = 该项被禁用或被跳过(未执行) }
    Passed     : Boolean;
    Measured   : Double;       { 实测值：能量/THD+N/串扰量，随测试项而变 }
    Threshold  : Double;       { 该项的判定门限 }
    ElapsedMs  : Cardinal;
    Message    : string;       { 结论描述，进日志文件 }
  end;

  TAlTestResultArray = array of TAlTestResult;

  { 全部配置。每一项都可单独设置 }
  TAlLoopConfig = record
    { --- 端口启用开关 --- }
    EnableOut  : array[TAlOutPort] of Boolean;
    EnableIn   : array[TAlInPort] of Boolean;
    { --- 测试项启用开关 --- }
    EnableTest: array[TAlTestItem] of Boolean;
    { --- JD(接口存在侦测)开关，与端口一一对应 --- }
    EnableJD  : array[TAlOutPort] of Boolean;   { 输出侧 jack 侦测 }
    EnableJDIn: array[TAlInPort] of Boolean;    { 输入侧 jack 侦测 }
    { --- 四个接口数值 --- }
    PeriodPoint: Integer;      { 0-10 }
    VolumeValue: Integer;      { 0-87 }
    DataVal  : Integer;      { 0-32767 }
    ThdnLimit  : Integer;      { 0-80 }
    { --- THD+N 是否参与判定（对应界面 Get Value 区的勾选）--- }
    ThdnCheck  : Boolean;
    { --- 采样率，48000 优先，失败自动回退 --- }
    SampleRate : Integer;
  end;

const
  { 端口/测试项的「有效个数」上限。
    重要：aopOutCount / aipInCount / altTestCount 都只是数组长度哨兵，
    High() 取到的是哨兵本身而不是最后一个真实成员，所以照 High() 循环
    会多遍历一个哨兵，界面上就会出现 "OUT3 / IN4 / TEST5" 这种
    不存在的项。一律用下面这三个常量做循环上界。 }
  AL_OUTPORT_CNT   = Ord(aopOutCount);    { 3 个真实输出接口 }
  AL_INPORT_CNT    = Ord(aipInCount);     { 4 个真实输入接口 }
  AL_TESTITEM_CNT  = Ord(altTestCount);   { 5 个测试项 }

{ ---------------- 枚举 <-> 文本 互转（给 ini 与日志用）---------------- }
function AlOutPortName(AIndex: TAlOutPort): string;
function AlInPortName(AIndex: TAlInPort): string;
function AlTestItemName(AIndex: TAlTestItem): string;
function AlOutPortIndex(const AName: string): TAlOutPort;
function AlInPortIndex(const AName: string): TAlInPort;
function AlTestItemIndex(const AName: string): TAlTestItem;

{ 把范围夹到合法区间。给 ini 里被手改坏的数值兜底 }
function AlClampInt(AValue, AMin, AMax: Integer): Integer;

{ 填入 Realtek 工具的默认配置：所有端口和测试项默认全开 }
procedure AlConfigDefault(out AConfig: TAlLoopConfig);

{ 把配置里所有数值夹到合法范围 }
procedure AlConfigNormalize(var AConfig: TAlLoopConfig);

{ ---------------- 配置文件读写 ---------------- }
{ 从 ini 读配置。文件不存在时先写一份默认配置再返回默认值，
  保证界面上第一次打开就能看到完整可用的勾选状态 }
function AlConfigLoad(const AFileName: string; out AConfig: TAlLoopConfig): Boolean;

{ 保存配置。返回 False 表示写文件失败（磁盘满/权限） }
function AlConfigSave(const AFileName: string; const AConfig: TAlLoopConfig): Boolean;

{ 从独立的参数设置程序(AudioLoopParamSet.exe)写的 AudioLoopParam.ini
  读音频回路参数。文件不存在或格式不对时返回 False，
  AWhy 里给出原因（给产线看的提示文案）。
  实际测试时用这个，而不是 AlConfigLoad。 }
function AlParamLoadFromFile(const AFileName: string;
  out AConfig: TAlLoopConfig; out AWhy: string): Boolean;

implementation

function AlOutPortName(AIndex: TAlOutPort): string;
begin
  case AIndex of
    aopFront:  Result := 'FRONT OUT';
    aopSurr:   Result := 'SURR OUT';
    aopCenLfe: Result := 'CEN/LFE OUT';
  else
    Result := 'OUT' + IntToStr(Ord(AIndex));
  end;
end;

function AlInPortName(AIndex: TAlInPort): string;
begin
  case AIndex of
    aipMicRear:  Result := 'MIC IN1';
    aipMicFront: Result := 'MIC IN2';
    aipLineIn1:  Result := 'LINE IN1';
    aipLineIn2:  Result := 'LINE IN2';
  else
    Result := 'IN' + IntToStr(Ord(AIndex));
  end;
end;

function AlTestItemName(AIndex: TAlTestItem): string;
begin
  case AIndex of
    altDetect:   Result := 'PORT DETECT';
    altLoopback: Result := 'LOOPBACK TEST';
    altLR:       Result := 'L/R CHANNEL TEST';
    altMute:     Result := 'MUTE TEST';
    altThdn:     Result := 'THD+N TEST';
  else
    Result := 'TEST' + IntToStr(Ord(AIndex));
  end;
end;

function AlOutPortIndex(const AName: string): TAlOutPort;
var
  I: TAlOutPort;
begin
  for I := Low(TAlOutPort) to High(TAlOutPort) do
    if SameText(AName, AlOutPortName(I)) then
      Exit(I);
  Result := aopFront;
end;

function AlInPortIndex(const AName: string): TAlInPort;
var
  I: TAlInPort;
begin
  for I := Low(TAlInPort) to High(TAlInPort) do
    if SameText(AName, AlInPortName(I)) then
      Exit(I);
  Result := aipMicRear;
end;

function AlTestItemIndex(const AName: string): TAlTestItem;
var
  I: TAlTestItem;
begin
  for I := Low(TAlTestItem) to High(TAlTestItem) do
    if SameText(AName, AlTestItemName(I)) then
      Exit(I);
  Result := altDetect;
end;

function AlClampInt(AValue, AMin, AMax: Integer): Integer;
begin
  if AValue < AMin then
    Result := AMin
  else if AValue > AMax then
    Result := AMax
  else
    Result := AValue;
end;

procedure AlConfigDefault(out AConfig: TAlLoopConfig);
var
  I: Integer;
begin
  { 默认全部启用：量产工具首次运行时不想让人再去点一遍勾选框。
    不存在的端口会在「接口存在侦测」那一步被自动剔除，不影响结果。 }
  for I := 0 to AL_OUTPORT_CNT - 1 do
  begin
    AConfig.EnableOut[TAlOutPort(I)] := True;
    AConfig.EnableJD[TAlOutPort(I)] := True;
  end;

  for I := 0 to AL_INPORT_CNT - 1 do
  begin
    AConfig.EnableIn[TAlInPort(I)] := True;
    AConfig.EnableJDIn[TAlInPort(I)] := True;
  end;

  for I := 0 to AL_TESTITEM_CNT - 1 do
    AConfig.EnableTest[TAlTestItem(I)] := True;

  AConfig.PeriodPoint := AL_DEF_PERIODPOINT;
  AConfig.VolumeValue := AL_DEF_VOLUMEVALUE;
  AConfig.DataVal   := AL_DEF_DATAVALUE;
  AConfig.ThdnLimit   := AL_DEF_THDN;
  AConfig.ThdnCheck   := True;
  AConfig.SampleRate  := 48000;
end;

procedure AlConfigNormalize(var AConfig: TAlLoopConfig);
begin
  AConfig.PeriodPoint := AlClampInt(AConfig.PeriodPoint, AL_PERIODPOINT_MIN, AL_PERIODPOINT_MAX);
  AConfig.VolumeValue := AlClampInt(AConfig.VolumeValue, AL_VOLUMEVALUE_MIN, AL_VOLUMEVALUE_MAX);
  AConfig.DataVal   := AlClampInt(AConfig.DataVal,   AL_DATAVALUE_MIN,   AL_DATAVALUE_MAX);
  AConfig.ThdnLimit   := AlClampInt(AConfig.ThdnLimit,   AL_THDN_MIN,        AL_THDN_MAX);
  if AConfig.SampleRate <= 0 then
    AConfig.SampleRate := 48000;
end;

{ 从「音频回路参数设置程序」写的 AudioLoopParam.ini 读参数。

  独立的参数设置程序(AudioLoopParamSet.exe)写的是逗号串格式：
    [AudioLoopOut] Enable = 1,0,1
  测试程序只读这一个文件，读到什么就按什么测。

  文件不存在时返回 False —— 这里刻意不像其它配置函数那样
  「自动生成一份默认配置」，因为那是产线语义：
  参数设置程序从没运行过 ≠ 「参数就是默认值」。
  默默用默认值去测，测出来的 PASS 没有依据，
  板子真坏了也会判成合格。宁可让测试程序明确报「没设置过」。 }
function AlParamLoadFromFile(const AFileName: string;
  out AConfig: TAlLoopConfig; out AWhy: string): Boolean;
var
  Ini: TIniFile;
  I: Integer;
  Tmp: array[0..7] of Boolean;
  S: string;
  { Parts 要声明在嵌套过程之前 —— Delphi 里嵌套过程只能看到
    声明在它前面的变量，写在后面会报 Undeclared identifier。 }
  Parts: TStringList;

  { 解析 "1,0,1,1" 这样的串到布尔数组。
    位数不够时缺的按默认值填，不要默默当成禁用 ——
    宁可多测一项，也不要因为文件是旧版就少测一项。 }
  procedure ParseList(const AVal: string; ADefault: Boolean; ACount: Integer);
  var
    K: Integer;
  begin
    for K := 0 to ACount - 1 do
      Tmp[K] := ADefault;
    if Trim(AVal) = '' then
      Exit;
    Parts := TStringList.Create;
    try
      Parts.Text := StringReplace(Trim(AVal), ',', #13#10, [rfReplaceAll]);
      for K := 0 to ACount - 1 do
        if K < Parts.Count then
          Tmp[K] := (Trim(Parts[K]) <> '0');
    finally
      Parts.Free;
    end;
  end;

begin
  Result := False;
  AWhy := '';

  if not FileExists(AFileName) then
  begin
    AWhy := '未找到音频回路参数设置文件：' + AFileName + sLineBreak +
      '请先运行「音频回路参数设置程序」AudioLoopParamSet.exe 设置参数。';
    Exit;
  end;

  Ini := TIniFile.Create(AFileName);
  try
    S := Ini.ReadString('AudioLoopOut', 'Enable', '');
    if S = '' then
    begin
      AWhy := AFileName + ' 里没有 [AudioLoopOut] Enable 配置，' +
        '文件可能不是参数设置程序写的。';
      Exit;
    end;

    AlConfigDefault(AConfig);

    ParseList(S, True, AL_OUTPORT_CNT);
    for I := 0 to AL_OUTPORT_CNT - 1 do
      AConfig.EnableOut[TAlOutPort(I)] := Tmp[I];

    S := Ini.ReadString('AudioLoopOut', 'EnableJD', '');
    ParseList(S, True, AL_OUTPORT_CNT);
    for I := 0 to AL_OUTPORT_CNT - 1 do
      AConfig.EnableJD[TAlOutPort(I)] := Tmp[I];

    S := Ini.ReadString('AudioLoopIn', 'Enable', '');
    if S = '' then
    begin
      AWhy := AFileName + ' 里没有 [AudioLoopIn] Enable 配置。';
      Exit;
    end;
    ParseList(S, True, AL_INPORT_CNT);
    for I := 0 to AL_INPORT_CNT - 1 do
      AConfig.EnableIn[TAlInPort(I)] := Tmp[I];

    S := Ini.ReadString('AudioLoopIn', 'EnableJD', '');
    ParseList(S, True, AL_INPORT_CNT);
    for I := 0 to AL_INPORT_CNT - 1 do
      AConfig.EnableJDIn[TAlInPort(I)] := Tmp[I];

    S := Ini.ReadString('AudioLoopTest', 'Enable', '');
    ParseList(S, True, AL_TESTITEM_CNT);
    for I := 0 to AL_TESTITEM_CNT - 1 do
      AConfig.EnableTest[TAlTestItem(I)] := Tmp[I];

    AConfig.PeriodPoint := Ini.ReadInteger('AudioLoop', 'PeriodPoint', AL_DEF_PERIODPOINT);
    AConfig.VolumeValue := Ini.ReadInteger('AudioLoop', 'VolumeValue', AL_DEF_VOLUMEVALUE);
    AConfig.DataVal     := Ini.ReadInteger('AudioLoop', 'DataValue',   AL_DEF_DATAVALUE);
    AConfig.ThdnLimit   := Ini.ReadInteger('AudioLoop', 'ThdnLimit',   AL_DEF_THDN);
    AConfig.ThdnCheck   := Ini.ReadInteger('AudioLoop', 'ThdnCheck',   1) <> 0;
    AConfig.SampleRate  := Ini.ReadInteger('AudioLoop', 'SampleRate',  48000);

    AlConfigNormalize(AConfig);
    Result := True;
  finally
    Ini.Free;
  end;
end;

function AlConfigLoad(const AFileName: string; out AConfig: TAlLoopConfig): Boolean;
var
  Ini: TIniFile;
  I: Integer;
begin
  if not FileExists(AFileName) then
  begin
    { 首次运行：给一份默认配置，让界面上所有勾选/数值都是现成的 }
    AlConfigDefault(AConfig);
    AlConfigSave(AFileName, AConfig);
    Exit(True);
  end;

  Ini := TIniFile.Create(AFileName);
  try
    AlConfigDefault(AConfig);

    { ---- 端口启用 ---- }
    for I := 0 to AL_OUTPORT_CNT - 1 do
      AConfig.EnableOut[TAlOutPort(I)] :=
        Ini.ReadInteger('OUT_PORT', AlOutPortName(TAlOutPort(I)), 1) <> 0;
    for I := 0 to AL_INPORT_CNT - 1 do
      AConfig.EnableIn[TAlInPort(I)] :=
        Ini.ReadInteger('IN_PORT', AlInPortName(TAlInPort(I)), 1) <> 0;

    { ---- 测试项启用 ---- }
    for I := 0 to AL_TESTITEM_CNT - 1 do
      AConfig.EnableTest[TAlTestItem(I)] :=
        Ini.ReadInteger('TEST_ITEM', AlTestItemName(TAlTestItem(I)), 1) <> 0;

    { ---- JD(接口存在)侦测开关 ---- }
    for I := 0 to AL_OUTPORT_CNT - 1 do
      AConfig.EnableJD[TAlOutPort(I)] :=
        Ini.ReadInteger('JD_OUT', AlOutPortName(TAlOutPort(I)), 1) <> 0;
    for I := 0 to AL_INPORT_CNT - 1 do
      AConfig.EnableJDIn[TAlInPort(I)] :=
        Ini.ReadInteger('JD_IN', AlInPortName(TAlInPort(I)), 1) <> 0;

    { ---- 四个接口数值。ini 键名与 Realtek 工具保持一致(DataValue)，
           字段名 DataVal 里的 Val 是为了避开 Pascal 保留字 ---- }
    AConfig.PeriodPoint := Ini.ReadInteger('VALUE', 'PeriodPoint', AL_DEF_PERIODPOINT);
    AConfig.VolumeValue := Ini.ReadInteger('VALUE', 'VolumeValue', AL_DEF_VOLUMEVALUE);
    AConfig.DataVal     := Ini.ReadInteger('VALUE', 'DataValue',   AL_DEF_DATAVALUE);
    AConfig.ThdnLimit   := Ini.ReadInteger('VALUE', 'THD+N',       AL_DEF_THDN);
    AConfig.ThdnCheck   := Ini.ReadInteger('VALUE', 'THDN_CHECK',  1) <> 0;
    AConfig.SampleRate  := Ini.ReadInteger('VALUE', 'SampleRate',  48000);

    AlConfigNormalize(AConfig);
    Result := True;
  finally
    Ini.Free;
  end;
end;

function AlConfigSave(const AFileName: string; const AConfig: TAlLoopConfig): Boolean;
var
  Ini: TIniFile;
  I: Integer;
begin
  { 磁盘满/无权限时不能把异常抛到测试流程里，只返回 False。
    Delphi 不允许 except 与 finally 同用，所以这里手动管理 Ini 的释放。 }
  Ini := nil;
  Result := False;
  try
    Ini := TIniFile.Create(AFileName);
    for I := 0 to AL_OUTPORT_CNT - 1 do
      Ini.WriteInteger('OUT_PORT', AlOutPortName(TAlOutPort(I)),
        Ord(AConfig.EnableOut[TAlOutPort(I)]));
    for I := 0 to AL_INPORT_CNT - 1 do
      Ini.WriteInteger('IN_PORT', AlInPortName(TAlInPort(I)),
        Ord(AConfig.EnableIn[TAlInPort(I)]));

    for I := 0 to AL_TESTITEM_CNT - 1 do
      Ini.WriteInteger('TEST_ITEM', AlTestItemName(TAlTestItem(I)),
        Ord(AConfig.EnableTest[TAlTestItem(I)]));

    for I := 0 to AL_OUTPORT_CNT - 1 do
      Ini.WriteInteger('JD_OUT', AlOutPortName(TAlOutPort(I)),
        Ord(AConfig.EnableJD[TAlOutPort(I)]));
    for I := 0 to AL_INPORT_CNT - 1 do
      Ini.WriteInteger('JD_IN', AlInPortName(TAlInPort(I)),
        Ord(AConfig.EnableJDIn[TAlInPort(I)]));

    { 注意：这里保持 Realtek 工具的键名 DataValue 不变，
      这样两种工具的配置可以互相参照。Pascal 里 DataValue 是保留字，
      所以字段名改成了 DataVal，只在写 ini 时用回原名。 }
    Ini.WriteInteger('VALUE', 'PeriodPoint', AConfig.PeriodPoint);
    Ini.WriteInteger('VALUE', 'VolumeValue', AConfig.VolumeValue);
    Ini.WriteInteger('VALUE', 'DataValue',   AConfig.DataVal);
    Ini.WriteInteger('VALUE', 'THD+N',       AConfig.ThdnLimit);
    Ini.WriteInteger('VALUE', 'THDN_CHECK',  Ord(AConfig.ThdnCheck));
    Ini.WriteInteger('VALUE', 'SampleRate',  AConfig.SampleRate);

    Result := True;
  except
    Result := False;
  end;
  Ini.Free;
end;

end.