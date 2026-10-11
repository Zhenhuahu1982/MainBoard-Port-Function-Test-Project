unit LPT;

{ 25针打印机端口(LPT/并行口)数据收发测试核心单元

  用途：测试主板上的 25 针打印机端口(LPT1/LPT2/LPT3)。
        端口上接的是自测治具(loopback)，治具把打印机端口的输出数据回环到输入，
        因此本单元发送 N 字节、回收 N 字节，逐字节比对，完全一致判定为 PASS。

  设计要点：
    1. 零窗体依赖，只用 RTL + Winapi，可独立编译、独立跑命令行自测。
    2. 全部 I/O 走 overlapped(异步) + 事件超时，治具没接好时不会把主程序卡死。
    3. 测试前先排空端口里可能残留的旧数据，避免脏数据影响比对。
    4. 测试数据用 0,1,2..255 循环递增：既能验证数据搬运正确，
       也能暴露"某根线常断/粘连/移位"这类硬件故障。
    5. 部分治具中间串了反相器件，可用 AllowInverted 允许按位取反后比对，
       比对成功时会在结果里标记，避免把硬件接法问题误判成程序 bug。

  典型错误码：
    2  ERROR_FILE_NOT_FOUND  -> 系统没有该 LPT 端口
    5  ERROR_ACCESS_DENIED   -> 端口被打印后台(spooler)或别的程序占用
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;

const
  LPT_MAX_DATA = 65536;   { 单次测试最大数据量，防止误配把内存吃满 }

type
  TLptTestResult = record
    PortName    : string;       { 端口名，如 LPT1 }
    Opened      : Boolean;      { 端口是否成功打开 }
    SentBytes   : Integer;      { 实际发送字节数 }
    RecvBytes   : Integer;      { 实际回收字节数 }
    SameCount   : Integer;      { 从头开始连续一致的字节数 }
    FirstDiffPos: Integer;      { 第一个不一致的位置，-1 表示全部一致 }
    Inverted    : Boolean;      { 是否是靠"按位取反"才比对上的 }
    Passed      : Boolean;      { 最终结论 }
    ElapsedMs   : Cardinal;     { 耗时(毫秒) }
    ErrorMsg    : string;       { 失败原因 / 结果描述 }
  end;

{ 生成测试数据：0,1,2,...,255,0,1,... 循环 }
function LptMakeTestData(ALen: Integer): AnsiString;

{ 把 LPT1 转成设备路径 \\.\LPT1 }
function LptDevicePath(const APortName: string): string;

{ 打开端口，成功返回 True；失败时 ErrCode 为 GetLastError 的值 }
function LptOpenPort(const APortName: string; out AHandle: THandle;
  out ErrCode: Cardinal): Boolean;

{ 关闭端口 }
procedure LptClosePort(var AHandle: THandle);

{ 完整测试流程：
    打开端口 -> 排空残留 -> 发送 ADataLen 字节 -> 回收 -> 比对
  AllowInverted = True 时，比对不通过会再试一次"按位取反"比对 }
function LptRunTest(const APortName: string; ADataLen: Integer; ATimeoutMs: Integer;
  AllowInverted: Boolean; out ARes: TLptTestResult): Boolean;

{ 前 ACount 字节里逐字节比对。
  完全一致时 FirstDiff = -1 并返回 True；
  否则 FirstDiff = 第一个不一致的位置(从0 开始)并返回 False。
  Invert = True 时把接收端数据按位取反后再比对(用于串了反相器件的治具)。
  导出到接口层，方便脱离硬件做单元自测。 }
function LptCompare(const ASent, ARecv: AnsiString; ACount: Integer;
  Invert: Boolean; out FirstDiff: Integer): Boolean;

implementation

const
  LPT_READ_CHUNK = 64;   { 单次 ReadFile 最多读这么多字节 }

{ ---------------- 基本工具 ---------------- }

function LptMakeTestData(ALen: Integer): AnsiString;
var
  I: Integer;
begin
  if ALen < 0 then
    ALen := 0;
  if ALen > LPT_MAX_DATA then
    ALen := LPT_MAX_DATA;      { 夹住上限，调用方传再大也不会越界 }
  SetLength(Result, ALen);
  for I := 1 to ALen do
    Result[I] := AnsiChar((I - 1) and $FF);
end;

function LptDevicePath(const APortName: string): string;
var
  P: string;
begin
  P := Trim(APortName);
  if P = '' then
    P := 'LPT1';
  if Copy(P, 1, 4) = '\\.\' then
    Result := P
  else
    Result := '\\.\' + P;
end;

function LptOpenPort(const APortName: string; out AHandle: THandle;
  out ErrCode: Cardinal): Boolean;
begin
  AHandle := INVALID_HANDLE_VALUE;
  ErrCode := 0;
  { 独占打开：并行口必须独占，否则读到的可能是打印后台缓存的数据 }
  AHandle := CreateFile(PChar(LptDevicePath(APortName)),
    GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING,
    FILE_FLAG_OVERLAPPED, 0);
  Result := AHandle <> INVALID_HANDLE_VALUE;
  if not Result then
    ErrCode := GetLastError;
end;

procedure LptClosePort(var AHandle: THandle);
begin
  if (AHandle <> INVALID_HANDLE_VALUE) and (AHandle <> 0) then
  begin
    CloseHandle(AHandle);
    AHandle := INVALID_HANDLE_VALUE;
  end;
end;

{ ---------------- 异步 I/O 辅助 ---------------- }

type
  { CancelIoEx 的函数指针类型。
    Delphi 10 的 RTL 里 CancelIoEx 只有
      function CancelIoEx; external kernel32 name 'CancelIoEx';
    这种没有签名、没有参数的声明，编译器不知道它怎么调用（E2003）。
    这里自己定义签名，再用 GetProcAddress 从 kernel32 取地址，
    这样既能在 Delphi 10 编过，行为也和直接调用一致。 }
  TCancelIoEx = function(hFile: THandle; lpOverlapped: POverlapped): BOOL; stdcall;

var
  { CancelIoEx 的取址结果。
    注意：Delphi 10 下"函数指针变量 = nil"这种比较在 if 语句里会报
    E2035，所以这里不比较函数指针本身，另外用 CancelIoReady 布尔标志表示可用性。 }
  CancelIoExPtr: TCancelIoEx = nil;
  CancelIoReady: Boolean = False;

procedure InitCancelIoEx;
var
  hKernel: HMODULE;
  raw: Pointer;
begin
  if CancelIoReady then
    Exit;

  hKernel := GetModuleHandle('kernel32.dll');
  if hKernel = 0 then
    Exit;

  { 必须先把 GetProcAddress 的结果转成 Pointer 存进普通变量，再赋给函数指针变量。
    Delphi 10 不允许把函数指针类型转换直接写在函数指针变量的赋值右侧
    （会报 E2035）；GetProcAddress 有 A/W 两个重载，内联调用还会歧义。 }
  raw := Pointer(GetProcAddress(hKernel, 'CancelIoEx'));
  if raw = nil then
    Exit;             { 取不到就保持未就绪，下次调用还会重试 }

  CancelIoExPtr := TCancelIoEx(raw);
  CancelIoReady := True;
end;

{ 取消一次挂起的 I/O，并等到驱动真正放手缓冲区。
  取消之后必须等事件，否则关句柄/复用缓冲区会踩到驱动还在写。 }
procedure LptCancelIo(H: THandle; Ov: POverlapped; Ev: THandle);
begin
  if CancelIoReady then
    CancelIoExPtr(H, Ov);
  WaitForSingleObject(Ev, 3000);
end;

{ 排空端口输入缓冲里可能残留的旧数据。
  治具没接好时，驱动里可能攒着上一次测试的数据，不清掉会误判。 }
procedure LptDrainInput(H: THandle; MaxDrainMs: Cardinal);
var
  Ov: TOverlapped;
  Ev: THandle;
  Buf: array[0..LPT_READ_CHUNK - 1] of Byte;
  NRead, NGot: DWORD;
  T0: Cardinal;
begin
  Ev := CreateEvent(nil, True, False, nil);
  if Ev = 0 then
    Exit;
  try
    T0 := GetTickCount;
    while GetTickCount - T0 < MaxDrainMs do
    begin
      FillChar(Ov, SizeOf(Ov), 0);
      Ov.hEvent := Ev;
      ResetEvent(Ev);
      NRead := 0;

      if not ReadFile(H, Buf[0], SizeOf(Buf), NRead, @Ov) then
      begin
        if GetLastError <> ERROR_IO_PENDING then
          Break;                       { 真错误，不排了 }
        { 立刻还是挂起 = 缓冲已空，没有残留数据 }
        if WaitForSingleObject(Ev, 0) <> WAIT_OBJECT_0 then
          Break;
      end;

      NGot := 0;
      if not GetOverlappedResult(H, Ov, NGot, False) then
      begin
        LptCancelIo(H, @Ov, Ev);
        Break;
      end;

      if NGot = 0 then
        Break;                         { 缓冲已空 }
    end;
  finally
    CloseHandle(Ev);
  end;
end;

{ 发送缓冲区。返回 True 表示全部字节都写出去了 }
function LptSendAll(H: THandle; const AData: AnsiString; TimeoutMs: Cardinal;
  out ErrCode: Cardinal): Boolean;
var
  Ov: TOverlapped;
  Ev: THandle;
  NWritten: DWORD;
begin
  Result := False;
  ErrCode := 0;
  if Length(AData) = 0 then
  begin
    Result := True;
    Exit;
  end;

  Ev := CreateEvent(nil, True, False, nil);
  if Ev = 0 then
  begin
    ErrCode := GetLastError;
    Exit;
  end;
  try
    FillChar(Ov, SizeOf(Ov), 0);
    Ov.hEvent := Ev;
    ResetEvent(Ev);
    NWritten := 0;

    if not WriteFile(H, Pointer(AData), DWORD(Length(AData)), NWritten, @Ov) then
    begin
      ErrCode := GetLastError;
      if ErrCode <> ERROR_IO_PENDING then
        Exit;
      if WaitForSingleObject(Ev, TimeoutMs) <> WAIT_OBJECT_0 then
      begin
        ErrCode := WAIT_TIMEOUT;
        LptCancelIo(H, @Ov, Ev);
        Exit;
      end;
    end;

    { 同步完成或等待成功，都用 GetOverlappedResult 取实际字节数。
      注意 GetOverlappedResult 会改写 GetLastError，
      所以上面保存的 ErrCode 不能在这里再用来判断成败。 }
    NWritten := 0;
    if not GetOverlappedResult(H, Ov, NWritten, False) then
    begin
      ErrCode := GetLastError;
      Exit;
    end;

    ErrCode := 0;
    Result := NWritten = DWORD(Length(AData));
    if not Result then
      ErrCode := ERROR_WRITE_FAULT;
  finally
    CloseHandle(Ev);
  end;
end;

{ 读取指定字节数。返回 True 表示读满了 AWant 字节；
  返回 False 时 AErrCode = WAIT_TIMEOUT 表示"读不够就超时了"(治具没回环)。
  PartBytes 无论成功失败都会带回实际读到的字节数，用于给用户定位。 }
function LptRecvExact(H: THandle; var ABuffer: AnsiString; AWant: Integer;
  Deadline: Cardinal; out PartBytes: Integer;
  out AErrCode: Cardinal): Boolean;
var
  Ov: TOverlapped;
  Ev: THandle;
  Total, Want, NRead, NGot: DWORD;
  Remain: Cardinal;
  WR: DWORD;
begin
  Result := False;
  AErrCode := 0;
  PartBytes := 0;
  Total := 0;

  Ev := CreateEvent(nil, True, False, nil);
  if Ev = 0 then
  begin
    AErrCode := GetLastError;
    Exit;
  end;
  try
    while Total < DWORD(AWant) do
    begin
      { 剩余时间。Deadline 是 GetTickCount 的绝对值，用无符号比较避免回绕 }
      if Deadline > GetTickCount then
        Remain := Deadline - GetTickCount
      else
        Remain := 0;
      if Remain = 0 then
      begin
        AErrCode := WAIT_TIMEOUT;
        Exit;
      end;

      Want := DWORD(AWant) - Total;
      if Want > LPT_READ_CHUNK then
        Want := LPT_READ_CHUNK;

      FillChar(Ov, SizeOf(Ov), 0);
      Ov.hEvent := Ev;
      ResetEvent(Ev);
      NRead := 0;

      if not ReadFile(H, ABuffer[Total + 1], Want, NRead, @Ov) then
      begin
        if GetLastError <> ERROR_IO_PENDING then
        begin
          AErrCode := GetLastError;
          Exit;
        end;
        WR := WaitForSingleObject(Ev, Remain);
        if WR <> WAIT_OBJECT_0 then
        begin
          if WR = WAIT_TIMEOUT then
            AErrCode := WAIT_TIMEOUT
          else
            AErrCode := GetLastError;
          LptCancelIo(H, @Ov, Ev);
          Exit;
        end;
      end;

      NGot := 0;
      if not GetOverlappedResult(H, Ov, NGot, False) then
      begin
        AErrCode := GetLastError;
        LptCancelIo(H, @Ov, Ev);
        Exit;
      end;

      if NGot = 0 then
      begin
        { 立刻完成但读到 0 字节，视为无数据 }
        AErrCode := WAIT_TIMEOUT;
        Exit;
      end;

      Inc(Total, NGot);
    end;
    Result := True;
  finally
    PartBytes := Integer(Total);   { 成功/失败都要如实上报读回多少 }
    CloseHandle(Ev);
  end;
end;

{ ---------------- 比对 ---------------- }

{ 前 ACount 字节里，从头开始连续一致的字节数；
  完全一致时 FirstDiff = -1，否则返回第一个不一致的位置 }
function LptCompare(const ASent, ARecv: AnsiString; ACount: Integer;
  Invert: Boolean; out FirstDiff: Integer): Boolean;
var
  I: Integer;
  SB, RB: Byte;
begin
  FirstDiff := -1;
  for I := 1 to ACount do
  begin
    SB := Byte(ASent[I]);
    RB := Byte(ARecv[I]);
    if Invert then
      RB := RB xor $FF;               { 反相治具：接收端每位取反后比对 }
    if SB <> RB then
    begin
      FirstDiff := I - 1;
      Break;
    end;
  end;
  Result := FirstDiff = -1;
end;

{ ---------------- 主流程 ---------------- }

function LptRunTest(const APortName: string; ADataLen: Integer; ATimeoutMs: Integer;
  AllowInverted: Boolean; out ARes: TLptTestResult): Boolean;
var
  H: THandle;
  Err, RecvErr: Cardinal;
  SendBuf, RecvBuf: AnsiString;
  PartRecv: Integer;
  T0, Now_, Deadline: Cardinal;
  DiffNorm, DiffInv: Integer;
  bOK: Boolean;
begin
  FillChar(ARes, SizeOf(ARes), 0);
  ARes.PortName := APortName;
  ARes.FirstDiffPos := -1;

  if ADataLen <= 0 then
    ADataLen := 64;
  if ADataLen > LPT_MAX_DATA then
    ADataLen := LPT_MAX_DATA;
  if ATimeoutMs <= 0 then
    ATimeoutMs := 2000;

  InitCancelIoEx;      { 首次调用时取CancelIoEx 地址 }

  T0 := GetTickCount;
  Deadline := T0 + Cardinal(ATimeoutMs);

  { ---- 1. 打开端口 ---- }
  if not LptOpenPort(APortName, H, Err) then
  begin
    ARes.Opened := False;
    case Err of
      ERROR_FILE_NOT_FOUND:
        ARes.ErrorMsg := '系统不存在 ' + APortName + ' 端口(设备管理器里没有打印机端口)';
      ERROR_ACCESS_DENIED:
        ARes.ErrorMsg := APortName + ' 端口被打印后台或其它程序占用';
      ERROR_SHARING_VIOLATION:
        ARes.ErrorMsg := APortName + ' 端口正被其它程序独占';
    else
      ARes.ErrorMsg := '打开 ' + APortName + ' 端口失败: ' +
        SysErrorMessage(Err) + '(错误码 ' + IntToStr(Err) + ')';
    end;
    ARes.ElapsedMs := GetTickCount - T0;
    Result := False;
    Exit;
  end;
  ARes.Opened := True;

  try
    { ---- 2. 排空残留数据(最多 200ms) ---- }
    LptDrainInput(H, 200);
    Now_ := GetTickCount;

    { ---- 3. 发送 ---- }
    SendBuf := LptMakeTestData(ADataLen);
    if not LptSendAll(H, SendBuf, Deadline - Now_, Err) then
    begin
      ARes.SentBytes := 0;
      ARes.ElapsedMs := GetTickCount - T0;
      if Err = WAIT_TIMEOUT then
        ARes.ErrorMsg := APortName + ' 发送超时，端口无响应(治具未上电或未接好)'
      else
        ARes.ErrorMsg := APortName + ' 发送失败: ' + SysErrorMessage(Err) +
          '(错误码 ' + IntToStr(Err) + ')';
      Result := False;
      Exit;
    end;
    ARes.SentBytes := Length(SendBuf);

    { ---- 4. 回收 ---- }
    SetLength(RecvBuf, ADataLen);
    if LptRecvExact(H, RecvBuf, ADataLen, Deadline, PartRecv, RecvErr) then
      ARes.RecvBytes := ADataLen
    else
    begin
      { 没读满，但已经读回来的部分仍要如实上报，用于给用户定位 }
      ARes.RecvBytes := PartRecv;
      if RecvErr = WAIT_TIMEOUT then
      begin
        if PartRecv = 0 then
          ARes.ErrorMsg := APortName + ' 发送了 ' + IntToStr(Length(SendBuf)) +
            ' 字节但一个字节都没回收，端口未回环(治具未接好或未上电)'
        else
          ARes.ErrorMsg := Format('%s 发送 %d 字节，只回收 %d 字节，数据不完整',
            [APortName, Length(SendBuf), PartRecv]);
      end
      else
        ARes.ErrorMsg := APortName + ' 接收失败: ' + SysErrorMessage(RecvErr) +
          '(错误码 ' + IntToStr(RecvErr) + ')';
      ARes.ElapsedMs := GetTickCount - T0;
      Result := False;
      Exit;
    end;

    { ---- 5. 比对 ---- }
    bOK := LptCompare(SendBuf, RecvBuf, ADataLen, False, DiffNorm);
    DiffInv := 0;
    if (not bOK) and AllowInverted then
    begin
      bOK := LptCompare(SendBuf, RecvBuf, ADataLen, True, DiffInv);
      if bOK then
      begin
        ARes.Inverted := True;
        DiffNorm := -1;
      end;
    end;

    if bOK then
    begin
      ARes.SameCount := ADataLen;
      ARes.FirstDiffPos := -1;
      ARes.Passed := True;
      if ARes.Inverted then
        ARes.ErrorMsg := Format('%s 端口收发数据一致(按位取反比对)，共 %d 字节',
          [APortName, ADataLen])
      else
        ARes.ErrorMsg := Format('%s 端口收发数据一致，共 %d 字节',
          [APortName, ADataLen]);
    end
    else
    begin
      ARes.FirstDiffPos := DiffNorm;
      ARes.SameCount := DiffNorm;      { 前面这些字节是对的 }
      ARes.Passed := False;
      ARes.ErrorMsg := Format('%s 端口数据不一致：第 %d 字节 发出 0x%2.2X 收到 0x%2.2X',
        [APortName, DiffNorm,
         Byte(SendBuf[DiffNorm + 1]), Byte(RecvBuf[DiffNorm + 1])]);
    end;

    ARes.ElapsedMs := GetTickCount - T0;
    Result := ARes.Passed;
  finally
    LptClosePort(H);
  end;
end;

end.