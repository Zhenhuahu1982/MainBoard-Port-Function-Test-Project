unit AudioLoopDev;

{ 音频回路测试 —— 设备枚举与接口存在侦测

  三层判定，逐层收紧：

    第1层 端点层(wave 设备)：枚举 waveOut/waveIn 设备数量与名称。
           用户明确要求「不是 HDMI 和 DP 的输出」，所以这里按设备名
           把 HDMI / DisplayPort / DP 这类数字输出剔除。

    第2层 模拟输出层：一个模拟声卡端点(比如 Realtek ALC)背后挂着
           Front/Surr/Cen-Lfe 三个 DAC 方向。驱动层面我们无法直接
           「点亮」某一个 speaker 而不动其它，所以本模块的做法是
           记录端点能力(wChannels/dwSupport)，供上层决定可测哪些方向。

    第3层 物理孔层(Jack Detection)：HDA Codec 每个 pin 都有 jack 描述符，
           通过 KS 属性 KSPROPERTY_JACK_DESCRIPTION 读 JackSubType
           (Speaker / Headphone / LineIn / Microphone …) 和 IsConnected，
           才能确认 Front/Mic 孔位物理上真的插了治具。

  第3层需要 SetupAPI 枚举 KS 音频接口。RTL 里没有 Winapi.SetupAPI 单元，
  这里直接声明所需的少数几个 API，按 winmm/ksuser 动态加载，
  拿不到时降级为「不启用 jack 精细判定」，保证主流程仍能跑。

  关键约束：
    - 任何一步失败都不抛异常，只把结果写进状态结构，由上层决定跳过还是判 FAIL。
    - 打开/关闭成对，任何异常路径都要把句柄还回去，避免声卡被独占占用。
}

interface

uses
  System.SysUtils, System.Classes, System.Math, Winapi.Windows, Winapi.MMSystem,
  AudioLoopCfg;

type
  { 一个枚举到的 wave 设备 }
  TAlDeviceInfo = record
    Index      : Integer;
    Name       : string;
    Channels   : Integer;
    IsDigital  : Boolean;    { True = HDMI/DP 等数字输出，按要求排除 }
    SupportsVolume: Boolean;
  end;
  TAlDeviceList = array of TAlDeviceInfo;

  { 接口存在侦测的结果 }
  TAlJackInfo = record
    Port        : Integer;      { 对应 TAlOutPort / TAlInPort 的序号 }
    Found       : Boolean;      { 是否找到了对应的 jack 描述符 }
    IsConnected : Boolean;      { 插孔里有没有插东西(治具) }
    JackSubType : Cardinal;     { KS jack subtype 常量，0 = 未知 }
    Description : string;
  end;
  TAlJackArray = array of TAlJackInfo;

  { 整体设备情况 }
  TAlAudioEnv = record
    WaveOutCount  : Integer;
    WaveInCount   : Integer;
    OutDevices    : TAlDeviceList;   { 排除数字输出后的模拟输出端点 }
    InDevices     : TAlDeviceList;
    DefaultOutIdx : Integer;         { 建议使用的输出端点序号，-1 = 无可用端点 }
    DefaultInIdx  : Integer;
    DigitalOutCnt : Integer;         { 提示：被排除的数字输出端点个数 }
    HasHdmiOrDp   : Boolean;         { 系统里存在数字输出，但本测试不测它 }
    JackSupported : Boolean;         { 是否成功读到 jack 描述符 }
    OutJacks      : TAlJackArray;    { 长度 = AL_OUTPORT_CNT - 1 }
    InJacks       : TAlJackArray;    { 长度 = AL_INPORT_CNT - 1 }
    Info          : string;          { 人类可读的环境摘要，进日志 }
  end;

const
  { KS jack subtype。只列出本测试关心的几类，其余视为未知。
    值来自 ks.h 的 JACK_SUBTYPE_* }
  AL_JACK_UNKNOWN      = 0;
  AL_JACK_SPEAKER      = $00000001;   { 内置扬声器 }
  AL_JACK_HEADPHONE    = $00000002;   { 耳机孔 = Front Audio 孔位 }
  AL_JACK_MICROPHONE   = $00000004;   { 麦克风孔 }
  AL_JACK_LINEIN       = $00000008;   { 线路输入孔 }
  AL_JACK_LINEOUT      = $00000010;   { 线路输出孔 }

  { 超过这个设备名的部分按数字输出处理(排除) }
  { 匹配在 AlIsDigitalOutputName 里实现 }

{ ---------------- 环境探测 ---------------- }

{ 枚举当前机器的音频环境：可用输出/输入端点、是否有 HDMI/DP、
  jack 描述符能否读到。全程不抛异常。 }
procedure AlProbeAudioEnvironment(out AEnv: TAlAudioEnv);

{ 判断一个 wave 设备名是否属于 HDMI/DP 这类数字输出 }
function AlIsDigitalOutputName(const AName: string): Boolean;

{ 某输出端口的 jack 状态。JackInfo 未探测到时返回 Found=False }
function AlGetOutJack(const AEnv: TAlAudioEnv; AIndex: TAlOutPort): TAlJackInfo;
function AlGetInJack(const AEnv: TAlAudioEnv; AIndex: TAlInPort): TAlJackInfo;

{ 把 jack subtype 翻成人能看懂的文本 }
function AlJackSubTypeName(ASubType: Cardinal): string;

{ 某输出端口按当前环境是否「可用于回路测试」。
    判据：模拟输出端点存在 + (若开启了 jack 判定则 jack 必须在且已插入)。
    AWhy 返回不通过的原因，进日志。 }
function AlCanUseOutPort(const AEnv: TAlAudioEnv; const AConfig: TAlLoopConfig;
  AIndex: TAlOutPort; out AWhy: string): Boolean;

function AlCanUseInPort(const AEnv: TAlAudioEnv; const AConfig: TAlLoopConfig;
  AIndex: TAlInPort; out AWhy: string): Boolean;

{ 按「输入端口」挑出真正该打开的录音端点。

  这是修一个很隐蔽的缺陷用的：原来无论用户在界面上选 MIC IN1 还是 MIC IN2，
  代码都硬编码打开 InDevices[0]。本机 4 个输入端点时，选 MIC IN2(前置)
  实际录的是端点 0（麦克风），治具却接在前置孔上，于是录到接近静音
  (L=2 R=2)，报「无有效信号」。选 MIC IN1 反而"对"了——因为端点 0
  恰好就是麦克风，治具也确实接在麦克风孔上。这是巧合，不是正确。

  现在按端口名匹配设备名，各端点典型命名（Realtek 驱动实测）：
    MIC IN1  -> 麦克风 / Microphone / Mic / Rear Mic
    MIC IN2  -> FrontMic / 前置麦克风 / Front Microphone
    LINE IN1 -> 线路输入 / Line In / Line1
    LINE IN2 -> 第二个线路输入 / Line In 2 / Aux
  匹配不上就退回 AlFindInputDevice 的结果（第一个端点），
  并在 AWhy 里说明「按名字没匹配上，用了第 N 个端点」，
  这样日志里能看出是名不符导致的，不是静默走错设备。 }
function AlFindInputDevice(const AEnv: TAlAudioEnv; AIndex: TAlInPort;
  out ADevIdx: Integer; out ADevName: string; out AWhy: string): Boolean;

{ 本机的录音端点里能不能区分出「前置麦克风」和「后置/普通麦克风」。
  有些机型只有一个麦克风端点(前后置物理并到同一个)，那种情况
  MIC IN1 与 MIC IN2 选到同一个端点是对的，调用方据此决定
  要不要断言「两者必须不同」。 }
function AlNameDistinguishesFrontRear(const AEnv: TAlAudioEnv): Boolean;

implementation

{ ================= 设备名分类 ================= }

function AlIsDigitalOutputName(const AName: string): Boolean;
var
  S: string;
begin
  { 归一化成大写，便于匹配。设备名常带中文/全角，这里只做 ASCII 关键字匹配 }
  S := UpperCase(AName);
  Result := (Pos('HDMI', S) > 0) or
            (Pos('DISPLAYPORT', S) > 0) or
            (Pos('DISPLAY PORT', S) > 0) or
            (Pos(' DP ', ' ' + S + ' ') > 0) or
            (Pos('DVI', S) > 0);
end;

function AlJackSubTypeName(ASubType: Cardinal): string;
begin
  case ASubType of
    AL_JACK_SPEAKER:   Result := 'SPEAKER';
    AL_JACK_HEADPHONE: Result := 'HEADPHONE(Front)';
    AL_JACK_MICROPHONE:Result := 'MICROPHONE';
    AL_JACK_LINEIN:    Result := 'LINE IN';
    AL_JACK_LINEOUT:   Result := 'LINE OUT';
  else
    Result := Format('0x%X', [ASubType]);
  end;
end;

{ ================= SetupAPI 动态声明 ================= }
{ RTL 不带 Winapi.SetupAPI，这里按需声明最小集合。
  全部走动态加载，任何一个函数取不到就把 JackSupported 置 False 降级。 }

type
  PSP_DEVINFO_DATA = ^TSP_DEVINFO_DATA;
  TSP_DEVINFO_DATA = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: Pointer;
  end;

  PSP_DEV_INTERFACE_DATA = ^TSP_DEV_INTERFACE_DATA;
  TSP_DEV_INTERFACE_DATA = record
    cbSize: DWORD;
    InterfaceClassGuid: TGUID;
    Flags: DWORD;
    Reserved: ULONG_PTR;
  end;

  PSP_DEVICE_INTERFACE_DETAIL_DATA_A = ^TSP_DEVICE_INTERFACE_DETAIL_DATA_A;
  TSP_DEVICE_INTERFACE_DETAIL_DATA_A = record
    cbSize: DWORD;
    DevicePath: array[0..0] of AnsiChar;
  end;

const
  DIGCF_PRESENT          = $00000002;
  DIGCF_DEVICEINTERFACE  = $00000010;
  INVALID_HANDLE_VALUE   = THandle(-1);

{ SetupAPI 的函数指针类型。ClassGuid 用 PAnsiChar 而不是 PGUID：
  Delphi 生成的 PGUID 与 C 结构布局兼容，但传参按 PGUID 会被编译器
  当成 interface 强转而报错，统一按指针传最省事。 }
type
  TSetupDiGetClassDevsA = function(ClassGuid, Enumerator: Pointer;
    hwndParent: HWND; Flags: DWORD): THandle; stdcall;
  TSetupDiDestroyClassInfoList = function(DeviceInfoSet: THandle): Boolean; stdcall;
  TSetupDiEnumDeviceInterfaces = function(DeviceInfoSet: THandle;
    DeviceInfoData: PSP_DEVINFO_DATA; InterfaceClassGuid: Pointer;
    MemberIndex: DWORD; DeviceInterfaceData: PSP_DEV_INTERFACE_DATA): Boolean; stdcall;
  TSetupDiGetDeviceInterfaceDetailA = function(DeviceInfoSet: THandle;
    DeviceInterfaceData: PSP_DEV_INTERFACE_DATA;
    DeviceInterfaceDetailData: PSP_DEVICE_INTERFACE_DETAIL_DATA_A;
    DeviceInterfaceDetailDataSize: DWORD;
    RequiredSize: PDWORD): Boolean; stdcall;

var
  SetupDiGetClassDevsA: TSetupDiGetClassDevsA;
  SetupDiDestroyClassInfoList: TSetupDiDestroyClassInfoList;
  SetupDiEnumDeviceInterfaces: TSetupDiEnumDeviceInterfaces;
  SetupDiGetDeviceInterfaceDetailA: TSetupDiGetDeviceInterfaceDetailA;

{ KS 相关结构（手写，对应 Windows SDK 的 ks.h / ksmedia.h 公开定义） }

const
  METHOD_BASIC        = 1;
  KSPROPERTY_TYPE_JACK_DESCRIPTION = 18;
  KSSTATE_CHANGE      = 0;

  { CTL_CODE(FILE_DEVICE_KS=0x0F, KSCTL_PROPERTY=3, METHOD_BUFFERED, FILE_READ_ACCESS=1) }
  IOCTL_KS_PROPERTY   = Cardinal(($0000000F shl 16) or (3 shl 2) or 1);

  { KS 音频设备的接口类 GUID：1c15d430-0f47-11d0-a8c0-00a0c90348f6。
  Winapi.Windows 里 TGUID 是 interface 类型，不能当 record 赋值，
  所以走 RTL 的字符串转 GUID 函数 StringToGUID。 }
function AlKsCategoryAudio: TGUID;
begin
  Result := StringToGUID('{1c15d430-0f47-11d0-a8c0-00a0c90348f6}');
end;

type
  KS_JACK_DESCRIPTION = record
    JackId: DWORD;
    JackSubType: DWORD;
  end;
  PKS_JACK_DESCRIPTION = ^KS_JACK_DESCRIPTION;

  { 驱动的返回缓冲：头(PropertySize+VariableSize) + 描述符数组 + 每个 jack 的连接状态数组 }
  KSJACK_DESCRIPTION2 = record
    PropertySize: DWORD;
    VariableSize: DWORD;
    Jacks: array[0..0] of KS_JACK_DESCRIPTION;
    States: array[0..0] of DWORD;
  end;
  PKSJACK_DESCRIPTION2 = ^KSJACK_DESCRIPTION2;

  KSSTREAM_STATE = record
    Instance: TGUID;
    State: DWORD;
  end;

  KSPRIORITY = record
    Priority: DWORD;
    Importance: DWORD;
  end;

  TKSPROPERTY = record
    Key: DWORD;            { PropertyType，取 KSPROPERTY_TYPE_JACK_DESCRIPTION }
    Flags: DWORD;          { METHOD_BASIC }
    PinId: DWORD;
    InstanceNumber: DWORD;
  end;

  { KS 属性查询请求。字段顺序与内核期望一致：
      StreamState(含对齐) -> Priority(含对齐) -> Property 偏移 -> InstanceId 偏移 -> 属性体
    这里不写死偏移值，全部在 AlBuildJackQuery 里按实际地址算，
    免得以后在前面插字段导致偏移错位（错位不会报错，只会静默拿不到 jack）。 }
  TKSPropertyQuery = record
    StreamState: KSSTREAM_STATE;
    Priority: KSPRIORITY;
    PropertyOffset: DWORD;
    InstanceIdOffset: DWORD;
    Prop: TKSPROPERTY;     { 字段名避开保留字 Property }
  end;

{ 构造查询请求，并给出驱动至少会返回的字节数。
  PropertyId / PinId / InstanceNumber 全传 0，意思是「问驱动要所有 jack」。 }
function AlBuildJackQuery(out AQuery: TKSPropertyQuery;
  out AHdrBytes, AMinReturnBytes: Cardinal): Boolean;
begin
  FillChar(AQuery, SizeOf(AQuery), 0);

  AQuery.StreamState.State := KSSTATE_CHANGE;
  { StreamState.Instance 保持全 0 = GUID_NULL，表示不针对特定实例 }
  AQuery.Priority.Priority := 0;
  AQuery.Priority.Importance := 0;

  AQuery.PropertyOffset := DWORD(@AQuery.Prop) - DWORD(@AQuery);
  AQuery.InstanceIdOffset := DWORD(@AQuery.StreamState.Instance) - DWORD(@AQuery);

  AQuery.Prop.Key := KSPROPERTY_TYPE_JACK_DESCRIPTION;
  AQuery.Prop.Flags := METHOD_BASIC;
  AQuery.Prop.PinId := 0;
  AQuery.Prop.InstanceNumber := 0;

  AHdrBytes := AQuery.PropertyOffset + SizeOf(TKSPROPERTY);
  AMinReturnBytes := SizeOf(DWORD) * 2 + SizeOf(KS_JACK_DESCRIPTION) + SizeOf(DWORD);
  Result := True;
end;

{ 解析驱动返回的 jack 描述符缓冲。
  返回读到的 jack 个数，0 表示没有有效数据。全程只读缓冲，不写。 }
function AlParseJackBuffer(const ABuffer: Pointer; ABytes: Cardinal;
  out AJacks: TAlJackArray): Integer;
var
  Hdr: PKSJACK_DESCRIPTION2;
  Count, I: Integer;
  DescPtr, StatePtr: PByte;
  JackBytes, StateBytes: Cardinal;
  Raw: Cardinal;
  Need: Cardinal;
begin
  Result := 0;
  AJacks := nil;
  if (ABuffer = nil) or (ABytes < 8) then
    Exit;

  { Hdr 指向缓冲头部，只读 PropertySize / VariableSize 两个 DWORD，
    后面实际解析用 PByte 逐个偏移走，避免直接下标访问
    那个 0 长度数组（Delphi 不允许 record 里的开放数组下标访问）。 }
  Hdr := PKSJACK_DESCRIPTION2(ABuffer);
  { PropertySize 是驱动报告的整个结构大小，用它兜住畸形返回 }
  Raw := Hdr^.PropertySize;
  if (Raw < 8) or (Raw > ABytes) then
    Exit;

  JackBytes := SizeOf(KS_JACK_DESCRIPTION);
  StateBytes := SizeOf(DWORD);

  { VariableSize 装的是「描述符 + 状态」的总长，用它算 jack 个数比
    拿 PropertySize 减更贴近驱动本意（后者可能含对齐填充）。 }
  Raw := Hdr^.VariableSize;
  if Raw >= (JackBytes + StateBytes) then
    Count := Integer((Raw - StateBytes) div (JackBytes + StateBytes))
  else
    Count := 1;

  { 上限保护：返回缓冲放不下这么多描述符+状态就截断 }
  Need := 8 + Cardinal(Count) * (JackBytes + StateBytes);
  if Need > ABytes then
  begin
    if ABytes <= 8 then
      Exit;
    Count := Integer(ABytes - 8) div Integer(JackBytes + StateBytes);
  end;
  if Count <= 0 then
    Exit;

  DescPtr := PByte(ABuffer) + 8;
  StatePtr := DescPtr + Cardinal(Count) * JackBytes;

  SetLength(AJacks, Count);
  for I := 0 to Count - 1 do
  begin
    AJacks[I].Port := I;
    AJacks[I].JackSubType := PKS_JACK_DESCRIPTION(DescPtr + Cardinal(I) * JackBytes)^.JackSubType;
    AJacks[I].Found := True;
    AJacks[I].IsConnected := False;
    { 状态位 bit0 = 已插入(HD Jack Connected) }
    AJacks[I].IsConnected :=
      (PDWord(StatePtr + Cardinal(I) * StateBytes)^ and 1) <> 0;
    AJacks[I].Description := AlJackSubTypeName(AJacks[I].JackSubType);
  end;
  Result := Count;
end;

var
  SetupLoaded: Boolean = False;

function AlLoadSetupApi: Boolean;
var
  H: HMODULE;
begin
  if SetupLoaded then
    Exit(True);
  H := LoadLibrary('setupapi.dll');
  if H = 0 then
  begin
    SetupLoaded := False;
    Exit(False);
  end;

  { GetProcAddress 收 PAnsiChar，且 Delphi 不允许把指针直接赋给函数变量，
    所以先取成 FARPROC/NativeUInt 再转。 }
  SetupDiGetClassDevsA :=
    TSetupDiGetClassDevsA(GetProcAddress(H, PAnsiChar('SetupDiGetClassDevsA')));
  SetupDiDestroyClassInfoList :=
    TSetupDiDestroyClassInfoList(GetProcAddress(H, PAnsiChar('SetupDiDestroyClassInfoList')));
  SetupDiEnumDeviceInterfaces :=
    TSetupDiEnumDeviceInterfaces(GetProcAddress(H, PAnsiChar('SetupDiEnumDeviceInterfaces')));
  SetupDiGetDeviceInterfaceDetailA :=
    TSetupDiGetDeviceInterfaceDetailA(GetProcAddress(H, PAnsiChar('SetupDiGetDeviceInterfaceDetailA')));

  SetupLoaded := Assigned(SetupDiGetClassDevsA) and
                 Assigned(SetupDiEnumDeviceInterfaces) and
                 Assigned(SetupDiGetDeviceInterfaceDetailA) and
                 Assigned(SetupDiDestroyClassInfoList);
  Result := SetupLoaded;
end;

{ ================= jack 探测 ================= }

{ 清空 jack 数组，全标成「没找到」 }
procedure AlResetJacks(out AOutJacks: TAlJackArray; out AInJacks: TAlJackArray);
var
  I: Integer;
begin
  SetLength(AOutJacks, AL_OUTPORT_CNT - 1 + 1);
  for I := 0 to High(AOutJacks) do
  begin
    AOutJacks[I].Port := I;
    AOutJacks[I].Found := False;
    AOutJacks[I].IsConnected := False;
    AOutJacks[I].JackSubType := AL_JACK_UNKNOWN;
    AOutJacks[I].Description := '';
  end;
  SetLength(AInJacks, AL_INPORT_CNT - 1 + 1);
  for I := 0 to High(AInJacks) do
  begin
    AInJacks[I].Port := I;
    AInJacks[I].Found := False;
    AInJacks[I].IsConnected := False;
    AInJacks[I].JackSubType := AL_JACK_UNKNOWN;
    AInJacks[I].Description := '';
  end;
end;

{ 对一个 KS 音频接口发 IOCTL_KS_PROPERTY 取 jack 描述符。
  返回读到的 jack 数组（空 = 没取到）。 }
function AlQueryJacksOnDevice(const ADevicePath: string): TAlJackArray;
var
  H: THandle;
  Query: TKSPropertyQuery;
  HdrBytes, MinBytes, BytesReturned, OutLen: DWORD;
  Buf: array[0..4095] of Byte;
  Raw: TAlJackArray;
begin
  Raw := nil;
  H := CreateFile(PChar(ADevicePath), 0, 0, nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then
    Exit(Raw);

  try
    if not AlBuildJackQuery(Query, HdrBytes, MinBytes) then
      Exit(Raw);

    BytesReturned := 0;
    { DeviceIoControl 的长度参数都是 DWORD，SizeOf 返回的是 NativeInt，
      这里显式转一下，避免 64 位下隐式窄化带来的截断隐患。 }
    OutLen := DWORD(SizeOf(Buf));
    if not DeviceIoControl(H, IOCTL_KS_PROPERTY, @Query, HdrBytes,
           @Buf[0], OutLen, BytesReturned, nil) then
      Exit(Raw);

    if (BytesReturned < MinBytes) or (BytesReturned > SizeOf(Buf)) then
      Exit(Raw);

    AlParseJackBuffer(@Buf[0], BytesReturned, Raw);
  finally
    CloseHandle(H);
  end;
  Result := Raw;
end;

{ 遍历所有 KS 音频接口，把取到的 jack 按 subtype 归到逻辑端口上。
  同一端口命中多次时保留「已插入」的那条 —— 量产线上多路 jack
  常常只插了一路，但只要有一条通，就认为该端口可用。 }
procedure AlProbeJacks(out AOutJacks: TAlJackArray; out AInJacks: TAlJackArray);
var
  DevInfoSet: THandle;
  MemberIndex: DWORD;
  IfData: TSP_DEV_INTERFACE_DATA;
  DetailBuf: array[0..4095] of Byte;
  Detail: PSP_DEVICE_INTERFACE_DETAIL_DATA_A;
  ReqSize, BytesReturned: DWORD;
  DevicePath: string;
  Raw: TAlJackArray;
  I: Integer;
  P: Integer;
  Sub: Cardinal;
  Connected, WasConnected: Boolean;
  CatGuid: TGUID;
begin
  AlResetJacks(AOutJacks, AInJacks);

  if not AlLoadSetupApi then
    Exit;

  Detail := PSP_DEVICE_INTERFACE_DETAIL_DATA_A(@DetailBuf);

  { GUID 是 interface，SetupAPI 这两个函数要的是指针，所以先转成 Pointer 传。
    GUID 实例在栈上，全程有效，不会出现悬垂指针。 }
  CatGuid := AlKsCategoryAudio;
  DevInfoSet := SetupDiGetClassDevsA(Pointer(@CatGuid), nil, 0,
                DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);
  if DevInfoSet = THandle(INVALID_HANDLE_VALUE) then
    Exit;

  try
    MemberIndex := 0;
    FillChar(IfData, SizeOf(IfData), 0);
    IfData.cbSize := SizeOf(IfData);

    while SetupDiEnumDeviceInterfaces(DevInfoSet, nil, Pointer(@CatGuid),
                                      MemberIndex, @IfData) do
    begin
      Inc(MemberIndex);

      { 先问需要多大，再取内容。cbSize 要填结构本身大小(不是 +4，
        那个 +4 是 Unicode 版本的差异，A 版不能加) }
      FillChar(DetailBuf, SizeOf(DetailBuf), 0);
      ReqSize := 0;
      if not SetupDiGetDeviceInterfaceDetailA(DevInfoSet, @IfData, nil, 0, @ReqSize) then
        Continue;
      if (ReqSize = 0) or (ReqSize > SizeOf(DetailBuf)) then
        Continue;

      Detail.cbSize := SizeOf(TSP_DEVICE_INTERFACE_DETAIL_DATA_A) - SizeOf(AnsiChar) + 1;
      if not SetupDiGetDeviceInterfaceDetailA(DevInfoSet, @IfData, @Detail, ReqSize, @BytesReturned) then
        Continue;

      DevicePath := PChar(@DetailBuf[4]);
      if DevicePath = '' then
        Continue;

      Raw := AlQueryJacksOnDevice(DevicePath);
      if Length(Raw) = 0 then
        Continue;

      for I := 0 to High(Raw) do
      begin
        Sub := Raw[I].JackSubType;
        Connected := Raw[I].IsConnected;

        { --- 归到输出端口 --- }
        P := -1;
        if Sub = AL_JACK_HEADPHONE then
          P := Ord(aopFront)          { 前置耳机孔 = Front Audio }
        else if Sub = AL_JACK_SPEAKER then
          P := Ord(aopFront)
        else if Sub = AL_JACK_LINEOUT then
          P := Ord(aopFront);

        if (P >= 0) and (P <= High(AOutJacks)) then
        begin
          WasConnected := AOutJacks[P].IsConnected;
          AOutJacks[P].Found := True;
          AOutJacks[P].JackSubType := Sub;
          AOutJacks[P].Description := AlJackSubTypeName(Sub);
          AOutJacks[P].IsConnected := WasConnected or Connected;
        end;

        { --- 归到输入端口 --- }
        P := -1;
        if Sub = AL_JACK_MICROPHONE then
          P := Ord(aipMicRear)
        else if Sub = AL_JACK_LINEIN then
          P := Ord(aipLineIn1);

        if (P >= 0) and (P <= High(AInJacks)) then
        begin
          WasConnected := AInJacks[P].IsConnected;
          AInJacks[P].Found := True;
          AInJacks[P].JackSubType := Sub;
          AInJacks[P].Description := AlJackSubTypeName(Sub);
          AInJacks[P].IsConnected := WasConnected or Connected;
        end;
      end;
    end;
  finally
    SetupDiDestroyClassInfoList(DevInfoSet);
  end;
end;

{ ================= 环境探测主流程 ================= }

{ 读 wave 设备名。设备名是定长的、以 0 结尾的宽字符数组，
  用 Wide 版 API 取，避免中文设备名被按 ANSI 截断成乱码
  （WAVEOUTCAPSA 只有 32 字节，中文很容易不够）。 }
function AlReadDevNameW(Caps: PWideChar; AMaxChars: Integer): string;
var
  I: Integer;
begin
  Result := '';
  if Caps = nil then
    Exit;
  { 直接按宽字符逐个取，遇到 0 结束。这样即使 RTL 里的字段类型
    是定长数组而不是 PWideChar，也能靠指针偏移取到首地址。 }
  for I := 0 to AMaxChars - 1 do
  begin
    if Caps[I] = #0 then
      Break;
    Result := Result + WideChar(Caps[I]);
  end;
end;

procedure AlProbeAudioEnvironment(out AEnv: TAlAudioEnv);
var
  I, N: Integer;
  Caps: TWaveOutCapsW;
  CapsIn: TWaveInCapsW;
  Item: TAlDeviceInfo;
  JackText: string;
  DevCount: Integer;
begin
  FillChar(AEnv, SizeOf(AEnv), 0);
  AEnv.DefaultOutIdx := -1;
  AEnv.DefaultInIdx := -1;
  AEnv.OutDevices := nil;
  AEnv.InDevices := nil;

  { ---- 输出端点枚举 ---- }
  N := waveOutGetNumDevs;
  AEnv.WaveOutCount := N;

  for I := 0 to N - 1 do
  begin
    FillChar(Caps, SizeOf(Caps), 0);
    if waveOutGetDevCapsW(UIntPtr(I), @Caps, SizeOf(Caps)) <> MMSYSERR_NOERROR then
      Continue;

    Item.Index := I;
    Item.Name := AlReadDevNameW(Caps.szPname, MAXPNAMELEN);
    Item.Channels := Caps.wChannels;
    Item.SupportsVolume := (Caps.dwSupport and WAVECAPS_VOLUME) <> 0;
    Item.IsDigital := AlIsDigitalOutputName(Item.Name);

    if Item.IsDigital then
    begin
      { 数字输出(HDMI/DP)按要求排除，不作为回路测试对象 }
      Inc(AEnv.DigitalOutCnt);
      AEnv.HasHdmiOrDp := True;
      Continue;
    end;

    DevCount := Length(AEnv.OutDevices);
    SetLength(AEnv.OutDevices, DevCount + 1);
    AEnv.OutDevices[DevCount] := Item;

    if AEnv.DefaultOutIdx < 0 then
      AEnv.DefaultOutIdx := Item.Index;
  end;

  { ---- 输入端点枚举 ---- }
  N := waveInGetNumDevs;
  AEnv.WaveInCount := N;
  for I := 0 to N - 1 do
  begin
    FillChar(CapsIn, SizeOf(CapsIn), 0);
    if waveInGetDevCapsW(UIntPtr(I), @CapsIn, SizeOf(CapsIn)) <> MMSYSERR_NOERROR then
      Continue;

    Item.Index := I;
    Item.Name := AlReadDevNameW(CapsIn.szPname, MAXPNAMELEN);
    Item.Channels := CapsIn.wChannels;
    Item.SupportsVolume := False;
    Item.IsDigital := AlIsDigitalOutputName(Item.Name);

    DevCount := Length(AEnv.InDevices);
    SetLength(AEnv.InDevices, DevCount + 1);
    AEnv.InDevices[DevCount] := Item;

    if AEnv.DefaultInIdx < 0 then
      AEnv.DefaultInIdx := Item.Index;
  end;

  { ---- jack 探测(可失败)---- }
  AlProbeJacks(AEnv.OutJacks, AEnv.InJacks);
  AEnv.JackSupported := AlLoadSetupApi;

  { ---- 人类可读摘要 ---- }
  if AEnv.JackSupported then
    JackText := '可用'
  else
    JackText := '不可用(降级)';
  AEnv.Info := Format('输出端点=%d(可用模拟=%d,排除数字输出=%d) 输入端点=%d jack探测=%s',
    [AEnv.WaveOutCount, Length(AEnv.OutDevices), AEnv.DigitalOutCnt,
     AEnv.WaveInCount, JackText]);
end;

function AlGetOutJack(const AEnv: TAlAudioEnv; AIndex: TAlOutPort): TAlJackInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Port := Ord(AIndex);
  Result.JackSubType := AL_JACK_UNKNOWN;
  if Ord(AIndex) <= High(AEnv.OutJacks) then
    Result := AEnv.OutJacks[Ord(AIndex)];
end;

function AlGetInJack(const AEnv: TAlAudioEnv; AIndex: TAlInPort): TAlJackInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Port := Ord(AIndex);
  Result.JackSubType := AL_JACK_UNKNOWN;
  if Ord(AIndex) <= High(AEnv.InJacks) then
    Result := AEnv.InJacks[Ord(AIndex)];
end;

{ ================= 按端口挑录音端点 ================= }

{ 设备名里是否含某个关键字（不区分大小写）。
  用「整词优先」策略：先找更具体的词，避免 "Line In" 抢走
  "Front Line In" 这类名字。 }
function AlNameHas(const AName, AKey: string): Boolean;
begin
  Result := Pos(UpperCase(AKey), UpperCase(AName)) > 0;
end;

{ 按输入端口挑录音端点。找不到就退回第 0 个端点并说明原因 ——
  宁可退回一个能用的，也不要静默录错设备让测试结果失去意义。 }
function AlFindInputDevice(const AEnv: TAlAudioEnv; AIndex: TAlInPort;
  out ADevIdx: Integer; out ADevName: string; out AWhy: string): Boolean;
var
  I: Integer;
  Keys, Key: string;
  D: Integer;
begin
  ADevIdx := -1;
  ADevName := '';
  AWhy := '';

  if Length(AEnv.InDevices) = 0 then
  begin
    AWhy := '没有任何输入端点';
    Exit(False);
  end;

  { 每个端口的候选关键字，用 | 分隔，**前面的优先**。
    顺序很要紧：'MIC' 是 'FrontMic' 的子串，MIC IN1 必须先试
    'MICROPHONE'、'麦克风' 这些不含 Front 语义的词，
    否则 MIC IN1 也会选到前置麦克风上去。 }
  case AIndex of
    aipMicRear:  Keys := 'MICROPHONE|REAR MIC|REARMIC|麦克风|后置麦克风|MIC|';
    aipMicFront: Keys := 'FRONTMIC|FRONT MIC|FRONT MICROPHONE|前置麦克风|前面板麦克风|MIC2|MIC 2|';
    aipLineIn1:  Keys := 'LINE IN|LINEIN|线路输入|LINE1|LINE 1|';
    aipLineIn2:  Keys := 'LINE IN 2|LINEIN2|LINE 2|LINE2|AUX|第二个线路|';
  else
    Keys := '';
  end;

  if Keys <> '' then
  begin
    D := Pos('|', Keys);
    while D > 0 do
    begin
      Key := Copy(Keys, 1, D - 1);
      if Key <> '' then
        for I := 0 to High(AEnv.InDevices) do
          if AlNameHas(AEnv.InDevices[I].Name, Key) then
          begin
            ADevIdx := AEnv.InDevices[I].Index;
            ADevName := AEnv.InDevices[I].Name;
            Exit(True);
          end;
      Keys := Copy(Keys, D + 1, Length(Keys));
      D := Pos('|', Keys);
    end;
  end;

  { 没按名字匹配上：退回第 0 个端点，但把这件事写进日志。
    产线上「名字对不上」是常态（驱动/机型各不同），
    静默退回会让测试结果没有依据。 }
  ADevIdx := AEnv.InDevices[0].Index;
  ADevName := AEnv.InDevices[0].Name;
  AWhy := Format('按名字没匹配到该端口对应的端点，已退回第 1 个输入端点「%s」。' +
    '若接的是前置孔，请确认该项该选 MIC IN2；若仍不对，需更新本程序的端点匹配表。',
    [ADevName]);
  Result := True;
end;

function AlNameDistinguishesFrontRear(const AEnv: TAlAudioEnv): Boolean;
var
  I: Integer;
  HasFront, HasPlain: Boolean;
begin
  HasFront := False;
  HasPlain := False;
  for I := 0 to High(AEnv.InDevices) do
  begin
    if AlNameHas(AEnv.InDevices[I].Name, 'FRONTMIC') or
       AlNameHas(AEnv.InDevices[I].Name, 'FRONT MIC') or
       AlNameHas(AEnv.InDevices[I].Name, '前置') then
      HasFront := True
    else if AlNameHas(AEnv.InDevices[I].Name, 'MIC') or
            AlNameHas(AEnv.InDevices[I].Name, '麦克风') then
      HasPlain := True;
  end;
  Result := HasFront and HasPlain;
end;
var
  I: Integer;
  Keys: string;
  Key: string;
  D: Integer;
begin
  ADevIdx := -1;
  ADevName := '';
  AWhy := '';

  if Length(AEnv.InDevices) = 0 then
  begin
    AWhy := '没有任何输入端点';
    Exit(False);
  end;

  { 每个端口的候选关键字，用 | 分隔。前面的优先。
    Realtek 驱动实测的端点名见这条函数的注释。 }
  case AIndex of
    aipMicRear:  Keys := 'MICROPHONE|REAR MIC|REARMIC|麦克风|后置麦克风|MIC|';
    aipMicFront: Keys := 'FRONTMIC|FRONT MIC|FRONT MICROPHONE|前置麦克风|前面板麦克风|MIC2|MIC 2|';
    aipLineIn1:  Keys := 'LINE IN|LINEIN|线路输入|LINE1|LINE 1|';
    aipLineIn2:  Keys := 'LINE IN 2|LINEIN2|LINE 2|LINE2|AUX|第二个线路|';
  else
    Keys := '';
  end;

  if Keys <> '' then
  begin
    D := Pos('|', Keys);
    while D > 0 do
    begin
      Key := Copy(Keys, 1, D - 1);
      if Key <> '' then
        for I := 0 to High(AEnv.InDevices) do
          if AlNameHas(AEnv.InDevices[I].Name, Key) then
          begin
            ADevIdx := AEnv.InDevices[I].Index;
            ADevName := AEnv.InDevices[I].Name;
            Exit(True);
          end;
      Keys := Copy(Keys, D + 1, Length(Keys));
      D := Pos('|', Keys);
    end;
  end;

  { 没按名字匹配上：退回第 0 个端点，但把这件事写进日志。
    产线上「名字对不上」是常态（驱动/机型各不同），
    静默退回会让测试结果没有依据。 }
  ADevIdx := AEnv.InDevices[0].Index;
  ADevName := AEnv.InDevices[0].Name;
  AWhy := Format('按名字没匹配到该端口对应的端点，已退回第 1 个输入端点「%s」。' +
    '若接的前置孔，请检查该项是否该用 MIC IN2，或更新本程序的端点匹配表。',
    [ADevName]);
  Result := True;
end;

function AlCanUseOutPort(const AEnv: TAlAudioEnv; const AConfig: TAlLoopConfig;
  AIndex: TAlOutPort; out AWhy: string): Boolean;
var
  J: TAlJackInfo;
begin
  { 必须有模拟输出端点。若系统只有 HDMI/DP 输出，本测试无从下手。 }
  if Length(AEnv.OutDevices) = 0 then
  begin
    AWhy := '系统没有可用的模拟输出端点(仅 HDMI/DP 或无音频设备)';
    Exit(False);
  end;

  { 多声道端点才有 Front/Surr/Cen-Lfe 之分 }
  if AEnv.OutDevices[0].Channels > 0 then
  begin
    case AIndex of
      aopCenLfe:
        if AEnv.OutDevices[0].Channels < 6 then
        begin
          AWhy := Format('该输出端点只支持 %d 声道,无 CENTER/LFE 输出',
            [AEnv.OutDevices[0].Channels]);
          Exit(False);
        end;
      aopSurr:
        if AEnv.OutDevices[0].Channels < 4 then
        begin
          AWhy := Format('该输出端点只支持 %d 声道,无环绕输出',
            [AEnv.OutDevices[0].Channels]);
          Exit(False);
        end;
    end;
  end;

  { JD(接口存在侦测)：勾选了才做强判定 }
  if AConfig.EnableJD[AIndex] and AEnv.JackSupported then
  begin
    J := AlGetOutJack(AEnv, AIndex);
    if J.Found then
    begin
      if not J.IsConnected then
      begin
        AWhy := Format('%s 未检测到治具插入', [AlOutPortName(AIndex)]);
        Exit(False);
      end;
    end;
    { Jack 没找到描述符 -> 不据此否决，交给回路实测确认。
      不同 Codec 的 jack 拓扑差异大，宁可放过也不要误杀。 }
  end;

  AWhy := Format('%s 可用于回路测试', [AlOutPortName(AIndex)]);
  Result := True;
end;

function AlCanUseInPort(const AEnv: TAlAudioEnv; const AConfig: TAlLoopConfig;
  AIndex: TAlInPort; out AWhy: string): Boolean;
var
  J: TAlJackInfo;
begin
  if Length(AEnv.InDevices) = 0 then
  begin
    AWhy := '系统没有可用的音频输入端点';
    Exit(False);
  end;

  if AConfig.EnableJDIn[AIndex] and AEnv.JackSupported then
  begin
    J := AlGetInJack(AEnv, AIndex);
    if J.Found then
    begin
      if not J.IsConnected then
      begin
        AWhy := Format('%s 未检测到治具插入', [AlInPortName(AIndex)]);
        Exit(False);
      end;
    end;
  end;

  AWhy := Format('%s 可用于回路测试', [AlInPortName(AIndex)]);
  Result := True;
end;

end.