Unit MemoryCpuUtils;

interface

Uses
Windows, SysUtils;

type
  TVendor = array[0..11] of Char;

{内存区}
//获取物理内存、虚拟内存、交换区(页面)内存的总容量，做初始化动作。
procedure GetMemoryTotalSize(Var iPhysicsMemoryTotalSize,
  iVirtualMemoryTotalSize,
  iPageFileMemoryTotalSize : DWORD);

//获取当前物理内存、虚拟内存、交换区(页面)内存的实时可用容量，做监控显示动作。
procedure GetMemoryCurrentSize(Var iPhysicsMemoryCurrentSize,
  iVirtualMemoryCurrentSize,
  iPageFileMemoryCurrentSize : DWORD);

//返回内存当前使用率 总的是100%，传回的是0-100%间的使用率，可以自己做转换。
function GetMemoryUsage : Double;

{CPU区}
//刷新CPU数据
procedure CollectCPUData;

//获取CPU在系统中的总数
function GetCPUCount: Integer;

//获取CPU使用率
function GetCPUUsage(Index: Integer): Double;

procedure ReleaseCPUData;

//获取CPU制造厂商
function GetCPUVendor : TVendor; assembler; register;

implementation

{$ifndef ver110}

{$ifndef ver90}
{$ifndef ver100}
{$define UseInt64}
{$endif}
{$endif}


{$ifdef UseInt64}
type TInt64 = Int64;
{$else}
type TInt64 = Comp;
{$endif}

{$else}

type TInt64 = TLargeInteger;

{$endif}

type
PInt64 = ^TInt64;

type
    TPERF_DATA_BLOCK = record
    Signature : array[0..4 - 1] of WCHAR;
    LittleEndian : DWORD;
    Version : DWORD;
    Revision : DWORD;
    TotalByteLength : DWORD;
    HeaderLength : DWORD;
    NumObjectTypes : DWORD;
    DefaultObject : Longint;
    SystemTime : TSystemTime;
    Reserved: DWORD;
    PerfTime : TInt64;
    PerfFreq : TInt64;
    PerfTime100nSec : TInt64;
    SystemNameLength : DWORD;
    SystemNameOffset : DWORD;
end;

    PPERF_DATA_BLOCK = ^TPERF_DATA_BLOCK;

    TPERF_OBJECT_TYPE = record
    TotalByteLength : DWORD;
    DefinitionLength : DWORD;
    HeaderLength : DWORD;
    ObjectNameTitleIndex : DWORD;
    ObjectNameTitle : LPWSTR;
    ObjectHelpTitleIndex : DWORD;
    ObjectHelpTitle : LPWSTR;
    DetailLevel : DWORD;
    NumCounters : DWORD;
    DefaultCounter : Longint;
    NumInstances : Longint;
    CodePage : DWORD;
    PerfTime : TInt64;
    PerfFreq : TInt64;
end;

    PPERF_OBJECT_TYPE = ^TPERF_OBJECT_TYPE;

type
    TPERF_COUNTER_DEFINITION = record
    ByteLength : DWORD;
    CounterNameTitleIndex : DWORD;
    CounterNameTitle : LPWSTR;
    CounterHelpTitleIndex : DWORD;
    CounterHelpTitle : LPWSTR;
    DefaultScale : Longint;
    DetailLevel : DWORD;
    CounterType : DWORD;
    CounterSize : DWORD;
    CounterOffset : DWORD;
    end;

    PPERF_COUNTER_DEFINITION = ^TPERF_COUNTER_DEFINITION;

    TPERF_COUNTER_BLOCK = record
    ByteLength : DWORD;
    end;

PPERF_COUNTER_BLOCK = ^TPERF_COUNTER_BLOCK;

TPERF_INSTANCE_DEFINITION = record
ByteLength : DWORD;
ParentObjectTitleIndex : DWORD;
ParentObjectInstance : DWORD;
UniqueID : Longint;
NameOffset : DWORD;
NameLength : DWORD;
end;

PPERF_INSTANCE_DEFINITION = ^TPERF_INSTANCE_DEFINITION;

{$ifdef ver130}
{$L-} // The L+ causes internal error in Delphi 5 compiler
{$O-} // The O+ causes internal error in Delphi 5 compiler
{$Y-} // The Y+ causes internal error in Delphi 5 compiler
{$endif}

{$ifndef ver110}
type
TInt64F = TInt64;
{$else}
type
TInt64F = Extended;
{$endif}

{$ifdef ver110}
function FInt64(Value: TInt64): TInt64F;
function Int64D(Value: DWORD): TInt64;
{$else}
type
FInt64 = TInt64F;
Int64D = TInt64;
{$endif}

{$ifdef ver110}
function FInt64(Value: TInt64): TInt64F;
Var
V: TInt64;
begin
  if (Value.HighPart and $80000000) = 0 then // positive value
  begin
    result:=Value.HighPart;
    result:=result*$10000*$10000;
    result:=result+Value.LowPart;
  end
  else
  begin
    V.HighPart:=Value.HighPart xor $FFFFFFFF;
    V.LowPart:=Value.LowPart xor $FFFFFFFF;
    result:= -1 - FInt64(V);
  end;
end;

function Int64D(Value: DWORD): TInt64;
begin
    Result.LowPart:=Value;
    Result.HighPart := 0; // positive only
end;
{$endif}

Const
    Processor_IDX_Str = '238';
    Processor_IDX = 238;
    CPUUsageIDX = 6;

type
    AInt64F = array[0..$FFFF] of TInt64F;
    PAInt64F = ^AInt64F;

Var
    _PerfData : PPERF_DATA_BLOCK;
    _BufferSize: Integer;
    _POT : PPERF_OBJECT_TYPE;
    _PCD: PPerf_Counter_Definition;
    _ProcessorsCount: Integer;
    _Counters: PAInt64F;
    _PrevCounters: PAInt64F;
    _SysTime: TInt64F;
    _PrevSysTime: TInt64F;
    _IsWinNT: Boolean;

    _W9xCollecting: Boolean;
    _W9xCpuUsage: DWORD;
    _W9xCpuKey: HKEY;

procedure GetMemoryTotalSize(Var iPhysicsMemoryTotalSize,
    iVirtualMemoryTotalSize,
    iPageFileMemoryTotalSize : DWORD);
{
iPhysicsMemoryTotalSize 物理内存总容量
iVirtualMemoryTotalSize 虚拟内存总容量
iPageFileMemoryTotalSize 交换内存（页面）总容量
}
Var
msMemory : TMemoryStatus;
begin
    msMemory.dwLength := SizeOf(msMemory);
    GlobalMemoryStatus(msMemory);
    iPhysicsMemoryTotalSize := msMemory.dwTotalPhys;
    iVirtualMemoryTotalSize := msMemory.dwTotalVirtual;
    iPageFileMemoryTotalSize := msMemory.dwTotalPageFile;
end;

procedure GetMemoryCurrentSize(Var iPhysicsMemoryCurrentSize,
iVirtualMemoryCurrentSize,
iPageFileMemoryCurrentSize : DWORD);
{
iPhysicsMemoryCurrentSize 物理内存可用容量
iVirtualMemoryCurrentSize 虚拟内存可用容量
iPageFileMemoryCurrentSize 交换内存（页面）可用容量
}
Var
msMemory : TMemoryStatus;
begin
    msMemory.dwLength := SizeOf(msMemory);
    GlobalMemoryStatus(msMemory);
    iPhysicsMemoryCurrentSize := msMemory.dwAvailPhys;
    iVirtualMemoryCurrentSize := msMemory.dwAvailVirtual;
    iPageFileMemoryCurrentSize := msMemory.dwAvailPageFile;
end;

function GetMemoryUsage : Double;
{
返回内存当前使用率 总的是100%，传回的是0-100%间的使用率，可以自己做转换。
}
Var
msMemory : TMemoryStatus;
begin
try
    msMemory.dwLength := SizeOf(msMemory);
    GlobalMemoryStatus(msMemory);
    Result := msMemory.dwMemoryLoad;
except
    Result := 0;
end;
end;

function GetCPUCount: Integer;
{
获取CPU数量
}
begin
if _IsWinNT then
begin
if _ProcessorsCount < 0 then
    CollectCPUData;
    Result:=_ProcessorsCount;
end
else
begin
    Result:=1;
end;
end;

procedure ReleaseCPUData;
Var
H: HKEY;
R: DWORD;
DwDataSize, DwType: DWORD;
begin
    if _IsWinNT then Exit;
    if Not _W9xCollecting then Exit;
    _W9xCollecting := False;
    RegCloseKey(_W9xCpuKey);
    R := RegOpenKeyEx( HKEY_DYN_DATA, 'PerfStats\StopStat', 0, KEY_ALL_ACCESS, H);
    if R <> ERROR_SUCCESS then Exit;
    dwDataSize := Sizeof(DWORD);
    RegQueryValueEx(H,'KERNEL\CPUUsage', Nil, @DwType, PBYTE(@_W9xCpuUsage), @DwDataSize);
    RegCloseKey(H);
end;

function GetCPUUsage(Index: Integer): Double;
{
获取CPU当前使用率
}
begin
if _IsWinNT then
    begin
      if _ProcessorsCount < 0 then CollectCPUData;
      if (Index >= _ProcessorsCount) Or (Index < 0) then
      Raise Exception.Create('CPU index out of bounds');
      if _PrevSysTime = _SysTime then
      Result := 0
      else
      Result := 1-(_Counters[index] - _PrevCounters[index])/(_SysTime-_PrevSysTime);
    end
    else
    begin
      if Index <> 0 then
      Raise Exception.Create('CPU index out of bounds');
      if Not _W9xCollecting then
      CollectCPUData;
      Result := _W9xCpuUsage/100;
    end;
end;

Var
VI: TOSVERSIONINFO;

procedure CollectCPUData;
Var
BS, i : Integer;
_PCB_Instance : PPERF_COUNTER_BLOCK;
_PID_Instance : PPERF_INSTANCE_DEFINITION;
ST : TFileTime;
H : HKEY;
R : DWORD;
DwDataSize, dwType: DWORD;
begin
    if _IsWinNT then
    begin
    BS:=_BufferSize;
    while RegQueryValueEx( HKEY_PERFORMANCE_DATA, Processor_IDX_Str, nil, nil,
    PByte(_PerfData), @BS ) = ERROR_MORE_DATA do
    begin
    INC(_BufferSize,$1000);
    BS:=_BufferSize;
    ReallocMem( _PerfData, _BufferSize );
    end;

    _POT := PPERF_OBJECT_TYPE(DWORD(_PerfData) + _PerfData.HeaderLength);
    for i := 1 to _PerfData.NumObjectTypes do
    begin
    if _POT.ObjectNameTitleIndex = Processor_IDX then Break;
    _POT := PPERF_OBJECT_TYPE(DWORD(_POT) + _POT.TotalByteLength);
    end;

    if _POT.ObjectNameTitleIndex <> Processor_IDX then
    Raise Exception.Create('Unable to locate the "Processor" performance object');

    if _ProcessorsCount < 0 then
    begin
    _ProcessorsCount:=_POT.NumInstances;
    GetMem(_Counters,_ProcessorsCount*SizeOf(TInt64));
    GetMem(_PrevCounters,_ProcessorsCount*SizeOf(TInt64));
    end;

    _PCD := PPERF_Counter_DEFINITION(DWORD(_POT) + _POT.HeaderLength);
    for i := 1 to _POT.NumCounters do
    begin
    if _PCD.CounterNameTitleIndex = CPUUsageIDX then Break;
    _PCD := PPERF_COUNTER_DEFINITION(DWORD(_PCD) + _PCD.ByteLength);
    end;

    if _PCD.CounterNameTitleIndex <> CPUUsageIDX then
    Raise Exception.Create('Unable to locate the "% of CPU usage" performance counter');

    _PID_Instance := PPERF_INSTANCE_DEFINITION(DWORD(_POT) + _POT.DefinitionLength);
    for i := 0 to _ProcessorsCount-1 do
    begin
      _PCB_Instance := PPERF_COUNTER_BLOCK(DWORD(_PID_Instance) + _PID_Instance.ByteLength);
      _PrevCounters[i]:=_Counters[i];
      _Counters[i]:=FInt64(PInt64(DWORD(_PCB_Instance) + _PCD.CounterOffset)^);
      _PID_Instance := PPERF_INSTANCE_DEFINITION(DWORD(_PCB_Instance) + _PCB_Instance.ByteLength);
    end;

      _PrevSysTime:=_SysTime;
      SystemTimeToFileTime(_PerfData.SystemTime, ST);
      _SysTime:=FInt64(TInt64(ST));
    end
    else
    begin
    if Not _W9xCollecting then
    begin
      R:=RegOpenKeyEx( HKEY_DYN_DATA, 'PerfStats\StartStat', 0, KEY_ALL_ACCESS, H );
      if R <> ERROR_SUCCESS then
        Raise Exception.Create('Unable to start performance monitoring');
        dwDataSize:=sizeof(DWORD);
        RegQueryValueEx( H, 'KERNEL\CPUUsage', nil, @dwType, PBYTE(@_W9xCpuUsage), @dwDataSize );
        RegCloseKey(H);
        R:=RegOpenKeyEx( HKEY_DYN_DATA, 'PerfStats\StatData', 0,KEY_READ, _W9xCpuKey );
      if R <> ERROR_SUCCESS then
        Raise Exception.Create('Unable to read performance data');
        _W9xCollecting:=True;
    end;

    dwDataSize:=sizeof(DWORD);
    RegQueryValueEx( _W9xCpuKey, 'KERNEL\CPUUsage', nil,@dwType, PBYTE(@_W9xCpuUsage), @dwDataSize );
    end;
    end;

    function GetCPUVendor : TVendor; assembler; register;
    asm
    PUSH EBX {Save affected register}
    PUSH EDI
    MOV EDI,EAX {@Result (TVendor)}
    MOV EAX,0
    DW $A20F {CPUID Command}
    MOV EAX,EBX
    XCHG EBX,ECX {save ECX result}
    MOV ECX,4
    @1:
    STOSB
    SHR EAX,8
    LOOP @1
    MOV EAX,EDX
    MOV ECX,4
    @2:
    STOSB
    SHR EAX,8
    LOOP @2
    MOV EAX,EBX
    MOV ECX,4
    @3:
    STOSB
    SHR EAX,8
    LOOP @3
    POP EDI {Restore registers}
    POP EBX
end;

initialization
_ProcessorsCount:= -1;
_BufferSize:= $2000;
_PerfData := AllocMem(_BufferSize);
VI.dwOSVersionInfoSize := SizeOf(VI);
if Not GetVersionEx(VI) then
Raise Exception.Create('Can''t get the Windows version');
_IsWinNT := VI.dwPlatformId = VER_PLATFORM_WIN32_NT;

finalization
ReleaseCPUData;
FreeMem(_PerfData);

end.
