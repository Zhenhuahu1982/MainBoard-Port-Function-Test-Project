unit UsbCounter;
{ ===========================================================================
  UsbCounter.pas - usbcounter.dll 的 Delphi 10 声明单元（动态加载版）

  用法:
    1. 把 usbcounter.dll 复制到【exe 实际所在目录】:
         - 32 位 Delphi 程序(Win32)  -> 用 x86\usbcounter.dll  (必须!)
         - 64 位 Delphi 程序(Win64)  -> 用 x64\usbcounter.dll
       注意: 在 IDE 里按 F9 调试运行时, exe 输出在 Win32\Debug(或 Release,
       取决于工程配置), DLL 必须放在那个目录下, 放错目录 = 找不到 DLL。
       放错位数 = 启动报 0xc000007b。
    2. uses UsbCounter;
       首次调用任一函数时自动 LoadLibrary; 若 DLL 缺失/位数不对,
       会抛出带说明的异常, 而不是直接把程序搞崩。

    示例 (统计):
      var C2, C3: Integer;
      begin
        if GetUsbDeviceCounts(C2, C3) then
          ShowMessage(Format('USB2.0 设备: %d 个'#13#10'USB3.0 设备: %d 个', [C2, C3]));
      end;

    示例 (列出设备名):
      var I, Total: Integer; Buf: array[0..255] of AnsiChar; Sp: Integer;
      begin
        Total := GetUsbDeviceTotal;
        for I := 0 to Total - 1 do
          if GetUsbDeviceNameA(I, Buf, SizeOf(Buf)) then
          begin
            if GetUsbDeviceSpeed(I) = SPEED_SUPER then Sp := 3 else Sp := 2;
            Memo1.Lines.Add(Format('[USB%d.0] %s', [Sp, StrPas(Buf)]));
          end;
      end;

    示例 (导出到文件):
      ExportUsbCountsW(PWideChar('C:\temp\usb.txt'));
  =========================================================================== }

interface

// 枚举并返回 USB2.0 / USB3.0 设备个数（每次调用都会重新枚举）
// 口径: 仅按“设备当前实际运行的速度”分类 ——
//   运行在 SuperSpeed(5G+) 才算 USB3.0 设备(即插在 USB3.0 端口上);
//   USB3.x 世代设备若插在 USB2.0 端口上降速运行, 计入 USB2.0。
//   不包含 HUB / 根集线器; 复合设备(键鼠一体等)按 1 个物理设备计。
function GetUsbDeviceCounts(var Usb2Count: Integer; var Usb3Count: Integer): LongBool; stdcall;

// 取个数（Kind = 2 或 3；首次调用时自动枚举，之后用缓存）
function GetUsbDeviceCount(Kind: Integer): Integer; stdcall;

// 设备总数（USB2.0 + USB3.0，不含 HUB / 根集线器）
function GetUsbDeviceTotal: Integer; stdcall;

// 按索引取设备名（ANSI 版，Index 从 0 开始）
function GetUsbDeviceNameA(Index: Integer; Buf: PAnsiChar; BufSize: Integer): LongBool; stdcall;

// 按索引取设备名（Unicode 版）
function GetUsbDeviceNameW(Index: Integer; Buf: PWideChar; BufChars: Integer): LongBool; stdcall;

// 按索引取速度: 0=Low 1=Full 2=High 3=Super(Speed) -1=未知
function GetUsbDeviceSpeed(Index: Integer): Integer; stdcall;

// 按索引取设备实例 ID（Unicode）
function GetUsbDeviceIdW(Index: Integer; Buf: PWideChar; BufChars: Integer): LongBool; stdcall;

// 导出 USB2.0 / USB3.0 个数到文本文件（Unicode 路径）
function ExportUsbCountsW(FileName: PWideChar): LongBool; stdcall;

// 手动预加载 DLL（可选）。返回是否成功；失败时 LastError 可查原因。
function UsbCounterLoadDll: Boolean;

// 释放 DLL（程序退出前调用可选，进程结束会自动释放）
procedure UsbCounterUnloadDll;

const
  SPEED_LOW   = 0;
  SPEED_FULL  = 1;
  SPEED_HIGH  = 2;
  SPEED_SUPER = 3;

implementation

uses
  Winapi.Windows, System.SysUtils;

const
  DllName = 'usbcounter.dll';

type
  TFnCounts = function(var C2: Integer; var C3: Integer): LongBool; stdcall;
  TFnCount  = function(Kind: Integer): Integer; stdcall;
  TFnTotal  = function: Integer; stdcall;
  TFnNameA  = function(Index: Integer; Buf: PAnsiChar; BufSize: Integer): LongBool; stdcall;
  TFnNameW  = function(Index: Integer; Buf: PWideChar; BufChars: Integer): LongBool; stdcall;
  TFnSpeed  = function(Index: Integer): Integer; stdcall;
  TFnIdW    = function(Index: Integer; Buf: PWideChar; BufChars: Integer): LongBool; stdcall;
  TFnExpW   = function(FileName: PWideChar): LongBool; stdcall;

var
  GDll: THandle = 0;
  _Counts: TFnCounts = nil;
  _Count: TFnCount = nil;
  _Total: TFnTotal = nil;
  _NameA: TFnNameA = nil;
  _NameW: TFnNameW = nil;
  _Speed: TFnSpeed = nil;
  _IdW: TFnIdW = nil;
  _ExpW: TFnExpW = nil;

procedure LoadDll;
  function ReqProc(const Name: PAnsiChar): Pointer;
  begin
    Result := GetProcAddress(GDll, Name);
    if Result = nil then
      raise Exception.CreateFmt('usbcounter.dll 缺少导出函数 %s, DLL 文件可能不完整或版本过旧。',
        [AnsiString(Name)]);
  end;
begin
  if GDll <> 0 then
    Exit;
  GDll := LoadLibrary(DllName);
  if GDll = 0 then
  begin
    if GetLastError = ERROR_BAD_EXE_FORMAT then
      raise Exception.Create(
        '加载 usbcounter.dll 失败: DLL 位数与程序不一致!' + #13#10 +
        '32 位程序(Win32)必须使用 x86\usbcounter.dll, 64 位程序用 x64\usbcounter.dll。')
    else
      raise Exception.CreateFmt(
        '加载 usbcounter.dll 失败 (Win32 错误码 %d)。' + #13#10 +
        '请确认 32 位程序使用 x86\usbcounter.dll, 且 DLL 与 exe 在同一目录。', [GetLastError]);
  end;
  _Counts := TFnCounts(ReqProc('GetUsbDeviceCounts'));
  _Count  := TFnCount(ReqProc('GetUsbDeviceCount'));
  _Total  := TFnTotal(ReqProc('GetUsbDeviceTotal'));
  _NameA  := TFnNameA(ReqProc('GetUsbDeviceNameA'));
  _NameW  := TFnNameW(ReqProc('GetUsbDeviceNameW'));
  _Speed  := TFnSpeed(ReqProc('GetUsbDeviceSpeed'));
  _IdW    := TFnIdW(ReqProc('GetUsbDeviceIdW'));
  _ExpW   := TFnExpW(ReqProc('ExportUsbCountsW'));
end;

function UsbCounterLoadDll: Boolean;
begin
  try
    LoadDll;
    Result := True;
  except
    Result := False;
  end;
end;

procedure UsbCounterUnloadDll;
begin
  if GDll <> 0 then
  begin
    FreeLibrary(GDll);
    GDll := 0;
    _Counts := nil; _Count := nil; _Total := nil; _NameA := nil;
    _NameW := nil; _Speed := nil; _IdW := nil; _ExpW := nil;
  end;
end;

function GetUsbDeviceCounts(var Usb2Count: Integer; var Usb3Count: Integer): LongBool; stdcall;
begin
  LoadDll;
  Result := _Counts(Usb2Count, Usb3Count);
end;

function GetUsbDeviceCount(Kind: Integer): Integer; stdcall;
begin
  LoadDll;
  Result := _Count(Kind);
end;

function GetUsbDeviceTotal: Integer; stdcall;
begin
  LoadDll;
  Result := _Total;
end;

function GetUsbDeviceNameA(Index: Integer; Buf: PAnsiChar; BufSize: Integer): LongBool; stdcall;
begin
  LoadDll;
  Result := _NameA(Index, Buf, BufSize);
end;

function GetUsbDeviceNameW(Index: Integer; Buf: PWideChar; BufChars: Integer): LongBool; stdcall;
begin
  LoadDll;
  Result := _NameW(Index, Buf, BufChars);
end;

function GetUsbDeviceSpeed(Index: Integer): Integer; stdcall;
begin
  LoadDll;
  Result := _Speed(Index);
end;

function GetUsbDeviceIdW(Index: Integer; Buf: PWideChar; BufChars: Integer): LongBool; stdcall;
begin
  LoadDll;
  Result := _IdW(Index, Buf, BufChars);
end;

function ExportUsbCountsW(FileName: PWideChar): LongBool; stdcall;
begin
  LoadDll;
  Result := _ExpW(FileName);
end;

end.
