unit HW;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,System.StrUtils, System.AnsiStrings;

  procedure FanControl(min,max : Integer; IO_TYPE, Flag: string);
  function GetCPUFanSpeed(num :Integer):integer;stdcall;external'GetFanSpeed.dll';
  function GetFanSpeed(IPort_Addr, DPort_Addr, FPort_Val, SPort_Val : Integer):Integer;
  function FGetFanSpeed(IPort_Addr, DPort_Addr, FPort_Val, SPort_Val : Integer):Integer;
  procedure GetCPU_Temp(min,max : Double);
const
  ITE_A35_INDEX = $A35;      // ITE IO INDEX
  ITE_A35_DATA = $A36;       // ITE IO DATA
  ITE_CPU_Index_Val = $19;   // ITE CPU FAN INDEX
  ITE_CPU_DATA_Val = $E;     // ITE CPU FAN DATA
  ITE_SYS_Index_Val = $1A;   // ITE SYS FAN INDEX
  ITE_SYS_DATA_Val = $F;     // ITE SYS FAN DATA
  ITE_295_INDEX = $295;      // ITE IO INDEX
  ITE_295_DATA = $296;       // ITE IO DATA
  ITE1_CPU_Index_Val = $18;   // ITE CPU FAN INDEX
  ITE1_CPU_DATA_Val = $D;     // ITE CPU FAN DATA
  ITE1_SYS_Index_Val = $1A;   // ITE SYS FAN INDEX
  ITE1_SYS_DATA_Val = $F;     // ITE SYS FAN DATA
  FIN_A25_INDEX = $A25;      // FINTEK IO INDEX
  FIN_A25_DATA = $A26;       // FINTEK IO DATA
  FIN_CPU_Index_VAL = $A0;    // FINTEK CPU FAN INDEX
  FIN_CPU_DATA_VAL = $A1;     // FINTEK CPU FAN DATA
  FIN_SYS_Index_VAL = $B0;    // FIN SYS_FAN INDEX
  FIN_SYS_DATA_VAL1 = $B1;    // FIN SYS_FAN DATA
  FIN_SYS1_Index_VAL = $C0;     //FIN sys_fan2 INDEX
  FIN_SYS1_DATA_VAL1 = $C1;     //FIN sys_fan2 DATA

  function InitializeWinIo:Boolean;stdcall;external 'Winio32.dll';
  function InstallWinIoDriver(pszWinIoDriverPath:PString;IsDemandLoaded:boolean=false):Boolean;stdcall;external 'Winio32.dll' name 'InstallWinIoDriver';
  function RemoveWinIoDriver:Boolean;stdcall;external 'Winio32.dll' name 'RemoveWinIoDriver';
  function GetPortVal(PortAddr:Word;PortVal:PDWord;bSize:Byte):Boolean;stdcall;external 'Winio32.dll' name 'GetPortVal';
  function SetPortVal(PortAddr:Word;PortVal:DWord;bSize:Byte):Boolean;stdcall;external 'Winio32.dll' name 'SetPortVal';
  function GetPhysLong(PhysAddr:PByte;PhysVal:PDWord):Boolean;stdcall;external 'Winio32.dll' name 'GetPhysLong';
  function SetPhysLong(PhysAddr:PByte;PhysVal:DWord):Boolean;stdcall;external 'Winio32.dll' name 'SetPhysLong';
  function MapPhysToLin(PhysAddr:PByte;PhysSize:DWord;PhysMemHandle:PHandle):PByte;stdcall;external 'Winio32.dll' name 'MapPhysToLin';
  function UnMapPhysicalMemory(PhysMemHandle:THandle;LinAddr:PByte):Boolean;stdcall;external 'Winio32.dll' name 'UnmapPhysicalMemory';
  procedure ShutdownWinIo;stdcall;external 'Winio32.dll';
  function WaitForFileUnlock(FileName: string; TimeoutMs: Integer = 30000): Boolean;
  function ExecuteAndWait(FileName : string) : Boolean;
  function GetIOType:string;

implementation

uses
  Test_Project_Demo1,RunPg,WiFi;


function GetIOType:string;
var
  dwVal, dwVal1 : DWORD;
  Data1 : Extended;
  Aw1, Aw2 : Word;
begin
  // 进入Super IO配置模式
  SetPortVal($2E, $87, 1);
  SetPortVal($2E, $1, 1);

  // 进入Super IO配置模式
  SetPortVal($2E, $55, 1);
  SetPortVal($2E, $55, 1);

  // 选择逻辑设备号为0xF (用于芯片ID读取)
  SetPortVal($2E, $7, 1);
  SetPortVal($2F, $4, 1);

  // 读取芯片ID高字节
  SetPortVal($2E, $20, 1);
  GetPortVal($2F, @dwval, 1);

  // 读取芯片ID低字节
  SetPortVal($2E, $21, 1);
  GetPortVal($2F, @dwval1, 1);

  //SetPortVal($2E, $2, 1);
  //SetPortVal($2F, $1, 1);

  //MessageBox(0, PChar('dwval:'+IntToHex(dwVal,2) + 'dwval1:' + IntToHex(dwVal1,2)),PChar('Word'),MB_OK);

   if (dwVal = 15) or (dwVal >= 255) or (dwval1 = 15) or (dwval1 >= 255) then
  begin
    dwVal := 0;
    dwVal1 := 0;
    Result := '0';
  end
  else
  begin
    //Data1 := 675000 / (dwVal1 + dwVal * 255);
    Result := IntToHex(dwval,2) + IntToHex(dwVal1,2);
  end;
end;

  // 从 Winio32 库中   ITE IO
function GetFanSpeed(IPort_Addr, DPort_Addr, FPort_Val, SPort_Val : Integer):Integer;
var
  dwVal, dwVal1 : DWORD;
  Data1 : Extended;
begin
  //ShowMessage('0');
  SetPortVal(IPort_Addr,FPort_Val,1);
  GetPortVal(DPort_Addr,@dwval,1);

  Sleep(500);
  SetPortVal(IPort_Addr,SPort_Val,1);
  GetPortVal(DPort_Addr,@dwval1,1);

   if (dwVal = 15) or (dwVal >= 255) or (dwval1 = 15) or (dwval1 >= 255) then
  begin
    dwVal := 0;
    dwVal1 := 0;
    Result := 0;
  end
  else
  begin
    Data1 := 675000 / (dwVal1 + dwVal * 255);
    Result := Round(Data1);
  end;
end;

function FGetFanSpeed(IPort_Addr, DPort_Addr, FPort_Val, SPort_Val : Integer):Integer;
var
  dwVal, dwVal1 : DWORD;
  Data1 : Extended;
begin
  SetPortVal(IPort_Addr,FPort_Val,1);
  GetPortVal(DPort_Addr,@dwval,1);

 // MessageBox(0, PChar('dwval:'+IntToHex(dwVal,2)),PChar('Word'),MB_OK);
  Sleep(500);
  SetPortVal(IPort_Addr,SPort_Val,1);
  GetPortVal(DPort_Addr,@dwval1,1);

 // MessageBox(0, PChar('dwval1:'+IntToHex(dwVal1,2)),PChar('Word'),MB_OK);
  // F   00FF  0FFF 0F00
  if (dwVal = 15) or (dwVal >= 255) or (dwval1 = 15) or (dwval1 >= 255) then
  begin
    dwVal := 0;
    dwVal1 := 0;
    Result := 0;
  end
  else
  begin
    //MessageBox(0, PChar('dwval:'+IntToStr(dwVal) + 'dwval1:' + IntToStr(dwVal1)),PChar('Word'),MB_OK);
    Data1 := 1500000 / (dwVal1 + dwVal * 255);
    Result := Round(Data1);
  end;
end;

// 风扇控制接收参数， min,max 对应最小，最大风扇转速. IO_TYPE表示IO类型： ITE FIN两种 Flag 表示风扇描述，CPU_FAN  SYS_FAN1  SYS_FAN2
procedure FanControl(min,max : Integer; IO_TYPE, Flag : string);
Var
  i, j, Fan1, Fan2, TFlag : Integer;
  IO_T : Integer;
begin
  Fan1 := 0;
  Fan2 := 0;
  Application.ProcessMessages;
  try
      SetCurrentDir('C:\Test_Project');
      //InitializeWinio;
      if IO_TYPE = 'ITE' then
      begin
          if Flag = 'CPU_FAN' then TFlag := 1;
          if Flag = 'SYS_FAN1' then  TFlag := 2;


         // IO_T := GetIOType;
          case TFlag of
            1:
            begin
              if GetIOType = '8637' then
              begin
                for i := 0 to 2 do
                begin
                   Sleep(3000);
                   //
                   Fan1 := Fan1 + GetFanSpeed(ITE_295_INDEX,ITE_295_DATA,ITE1_CPU_Index_Val,ITE1_CPU_DATA_Val);
                  // MessageBox(0,PChar(IntToStr(Fan1)),PChar('CFan1'),MB_OK);
                  // MessageBox(0,PChar(GetIOType),PChar('TYPE'),MB_OK);
                end
              end
              else
              begin
                  Fan1 := Fan1 + GetFanSpeed(ITE_A35_INDEX,ITE_A35_DATA,ITE_CPU_Index_Val,ITE_CPU_DATA_Val);
                  //MessageBox(0,PChar(IntToStr(Fan1)),PChar('CFan2'),MB_OK);
                  //MessageBox(0,PChar(GetIOType),PChar('TYPE'),MB_OK);
              end;
            end;
            2:
            begin
              if IO_T = 189 then
              begin
               for I := 0 to 2 do
                begin
                  Sleep(3000);
                  Fan1 := Fan1 + GetFanSpeed(ITE_295_INDEX,ITE_295_DATA,ITE1_SYS_Index_Val,ITE1_SYS_DATA_Val)
                end
              end
              else
              begin
                for I := 0 to 2 do
                begin
                  Sleep(3000);
                  Fan1 := Fan1 + GetFanSpeed(ITE_A35_INDEX,ITE_A35_DATA,ITE_SYS_Index_Val,ITE_SYS_DATA_Val);
                end;
              end;
            end;
          end;
      end;
      if IO_TYPE = 'FIN' then
      begin
          if Flag = 'CPU_FAN' then TFlag := 1;
          if Flag = 'SYS_FAN1' then  TFlag := 2;
          if Flag = 'SYS_FAN2' then  TFlag := 3;

          case TFlag of
            1:
            begin
              for I := 0 to 2 do
              begin
                Sleep(3000);
                Fan1 := Fan1 + FGetFanSpeed(FIN_A25_INDEX,FIN_A25_DATA,FIN_CPU_Index_VAL,FIN_CPU_DATA_VAL);
                //MessageBox(0,PChar(IntToStr(Fan1)),PChar('CFan1'),MB_OK);
              end;
              if Fan1 = 0 then
              begin
                 ShutdownWinIo;
                 InitializeWinIo;
                 Sleep(2000);
                for I := 0 to 2 do
                begin
                  Sleep(3000);
                  Fan1 := Fan1 + FGetFanSpeed(FIN_A25_INDEX,FIN_A25_DATA,FIN_CPU_Index_VAL,FIN_CPU_DATA_VAL);
                  //MessageBox(0,PChar(IntToStr(Fan1)),PChar('CFan1'),MB_OK);

                end;
              end;
            end;
            2:
              begin
                for I := 0 to 2 do
                begin
                  Sleep(3000);
                  Fan1 := Fan1 + FGetFanSpeed(FIN_A25_INDEX,FIN_A25_DATA,FIN_SYS_Index_Val,FIN_SYS_DATA_VAL1);
                end;
                if Fan1 = 0 then
                begin
                  ShutdownWinIo;
                  InitializeWinIo;
                  Sleep(2000);
                  for I := 0 to 2 do
                  begin
                    Sleep(3000);
                    Fan1 := Fan1 + FGetFanSpeed(FIN_A25_INDEX,FIN_A25_DATA,FIN_SYS_Index_Val,FIN_CPU_DATA_VAL);
                    //MessageBox(0,PChar(IntToStr(Fan1)),PChar('CFan1'),MB_OK);
                  end;
                end;
              end;
            3:
            begin
              for I := 0 to 2 do
              begin
                Sleep(3000);
                Fan1 := Fan1 + FGetFanSpeed(FIN_A25_INDEX,FIN_A25_DATA,FIN_SYS1_Index_Val,FIN_SYS1_DATA_VAL1);
              end;
              if Fan1 = 0 then
                begin
                  ShutdownWinIo;
                  InitializeWinIo;
                  Sleep(2000);
                  for I := 0 to 2 do
                  begin
                    Sleep(3000);
                    Fan1 := Fan1 + FGetFanSpeed(FIN_A25_INDEX,FIN_A25_DATA,FIN_SYS1_Index_Val,FIN_CPU_DATA_VAL);
                    //MessageBox(0,PChar(IntToStr(Fan1)),PChar('CFan1'),MB_OK);
                  end;
                end;
            end;
          end;
      end;

      Test_Project_Demo1.HW_Flag := 1;
      //MessageBox(0,PChar(IntToStr(Fan1)),PChar(Flag+'RPM'),MB_OK);
      Fan2 :=  Trunc ( Fan1 / 3);
      if (Fan2 >= min) and (Fan2 <= max)then
          begin
              with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  '风扇转速测试';
                           Cells[1,j] := Flag + '转速：' + IntToStr(Fan2) +  ' RPM';
                           Cells[2,j] := 'PASS';
                           Cells[3,j] := '设置最低: ' + IntToStr(min) + '设置最高: ' + IntToStr(max);
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;

              if Flag = 'CPU_FAN' then
                 Test_Project_Demo1.Form2.FAN1_Result := 'PASS'
                 else if Flag = 'SYS_FAN1' then
                      Test_Project_Demo1.Form2.FAN2_Result := 'PASS'
                      else if Flag = 'SYS_FAN2' then
                        Test_Project_Demo1.Form2.FAN3_Result := 'PASS';

             Test_Project_Demo1.HW_Flag := 0;
             exit;
          end
      else
          begin
             with Test_Project_Demo1.Form2.RzStringGrid1 do
                begin
                    for j := 0 to RowCount - 1 do
                    begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  '风扇转速测试';
                           Cells[1,j] := Flag + ' 转速错误: ' + IntToStr(Fan2) +  ' RPM';
                           Cells[2,j] := 'FAIL';
                           Cells[3,j] := '设置最低: ' + IntToStr(min) + '设置最高: ' + IntToStr(max);
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                    end;
                end;
                if Flag = 'CPU_Fan' then
                 Test_Project_Demo1.Form2.FAN1_Result := 'FAIL'
                 else if Flag = 'SYS_Fan1' then
                      Test_Project_Demo1.Form2.FAN2_Result := 'FAIL'
                      else if Flag = 'SYS_FAN2' then
                        Test_Project_Demo1.Form2.FAN3_Result := 'FAIL';
                //Test_Project_Demo1.Form2.FAN5_Result := 'PASS';
               // Test_Project_Demo1.HW_Flag := 1;
                Exit;
           end ;
  except on e: Exception  do
    begin
        //ShutdownWinio;
       SetPortVal($2E, $2, 1);
       SetPortVal($2F, $1, 1);
    end;
  end;

end;

// CPU 温度测试
procedure GetCPU_Temp(min,max : Double);
Var
  FileName, FileName1 : string;
  j  : Integer;
  cTemp : Double;
  cTemp1, cTemp2, Line : string;
  list1 : TStringList;
  F : TextFile;
begin
  FileName := ExtractFilePath(ParamStr(0)) + 'CPU_Temp.exe';
  FileName1 := ExtractFilePath(ParamStr(0)) + 'tTemp.txt';
  list1 := TStringList.Create;
  cTemp := 0;
  Application.ProcessMessages;
  try


     //if ShellExecute(0,'open',PChar(FileName),nil,nil,0) > 32 then
     // if RunProgram(FileName, True) > 0 then
     //   MessageBox(0,PChar('CPUTemp'),PChar('Cpu Temp'),MB_OK);
     with Test_Project_Demo1.Form2.RzStringGrid1 do
    begin
        for j := 0 to RowCount - 1 do
        begin
            if Cells[0,j] = '' then
            begin
               //ShowMessage(RzStringGrid1.Cells[1,j]);
                 Cells[0,j] :=  'CPU温度测试';
                 Cells[1,j] :=  'CPU温度测试';
               //  Cells[2,j] := 'PASS';
                 Cells[3,j] := '设置最低: ' + FloatToStr(min) + '设置最高: ' + FloatToStr(max);
                 RowCount := RowCount + 1;
                 Row := Row + 1;
                 Update;
            end;
        end;
    end;

        if ExecuteAndWait(FileName) then
         begin
            Sleep(4000);
            if FileExists(FileName1) then
            begin
              //list1.LoadFromFile(FileName1);
              //MessageBox(0,PChar('Fail'),PChar('List1'),MB_OK);
              AssignFile(F,FileName1);

              try
                 Reset(F);
                while not Eof(F) do
                begin
                  Readln(F, line);
                end;
              except
                on E: Exception do
                  ShowMessage('读取失败：' + E.Message);
              end;

              CloseFile(F);
              //if list1.Count > 0 then
              //  begin
              //    cTemp1 := list1[0];
              if Line = '0' then
                 Line := '1';

                cTemp := StrToFloat(Line) / 3;

                if Length(FloatToStr(cTemp)) >= 4 then
                  cTemp2 := LeftStr(FloatToStr(Ctemp), 2)
                  else
                     cTemp2 := LeftStr(FloatToStr(Ctemp), 2);

                Test_Project_Demo1.Form2.cTemp_Result := cTemp2;

                if (cTemp >= Min) and (cTemp <= Max)  then
                begin
                    with Test_Project_Demo1.Form2.RzStringGrid1 do
                    begin
                        for j := 0 to RowCount - 1 do
                        begin
                            if Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 Cells[0,j] :=  'CPU温度测试';
                                 Cells[1,j] :=  'CPU温度：' + cTemp2 +  '°C';
                                 Cells[2,j] := 'PASS';
                                 Cells[3,j] := '设置最低: ' + FloatToStr(min) + '设置最高: ' + FloatToStr(max);
                                 RowCount := RowCount + 1;
                                 Row := Row + 1;
                                 Update;
                            end;
                        end;
                    end;

                   Test_Project_Demo1.Form2.cCpu_Result := 'PASS';
                   exit;
                end
                else
                 begin
                   with Test_Project_Demo1.Form2.RzStringGrid1 do
                      begin
                          for j := 0 to RowCount - 1 do
                          begin
                            if Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 Cells[0,j] :=  'CPU温度测试';
                                 Cells[1,j] := 'CPU温度: ' + cTemp2 +  '°C';
                                 Cells[2,j] := 'FAIL';
                                 Cells[3,j] := '设置最低: ' + FloatToStr(min) + '设置最高: ' + FloatToStr(max);
                                 RowCount := RowCount + 1;
                                 Row := Row + 1;
                                 Update;
                            end;
                          end;
                      end;
                      Test_Project_Demo1.Form2.cCpu_Result := 'FAIL';
                      //Test_Project_Demo1.Form2.FAN5_Result := 'PASS';
                     // Test_Project_Demo1.HW_Flag := 1;
                      Exit;
                 end;
                end
                else
                begin
                 with Test_Project_Demo1.Form2.RzStringGrid1 do
                    begin
                        for j := 0 to RowCount - 1 do
                        begin
                          if Cells[0,j] = '' then
                          begin
                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                               Cells[0,j] :=  'CPU温度测试';
                               Cells[1,j] := 'CPU温度程序执行错误';
                               Cells[2,j] := 'FAIL';
                               Cells[3,j] := '设置最低: ' + FloatToStr(min) + '设置最高: ' + FloatToStr(max);
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                        end;
                    end;
                    Test_Project_Demo1.Form2.cCpu_Result := 'FAIL';
                    //Test_Project_Demo1.Form2.FAN5_Result := 'PASS';
                   // Test_Project_Demo1.HW_Flag := 1;
                    Exit;
                 end;

         end;
        //MessageBox(0, PChar(IntToStr(list1.Count)),PChar('List1'),MB_OK);

  finally
      //ShutdownWinio;

      list1.Free;
  end;

end;

function IsFileInUse(FileName: string): Boolean;
var
  HFileRes: HFILE;
begin
  Result := False;
  if not FileExists(FileName) then Exit; // 确保文件存在

  // 尝试以读写模式、独占方式打开文件
  HFileRes := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := (HFileRes = INVALID_HANDLE_VALUE);

  if not Result then
    CloseHandle(HFileRes); // 如果成功打开，立即关闭句柄
end;

function WaitForFileUnlock(FileName: string; TimeoutMs: Integer = 30000): Boolean;
var
  StartTime: Cardinal;
begin
  StartTime := GetTickCount;
  while IsFileInUse(FileName) do
  begin
    if (GetTickCount - StartTime) >= TimeoutMs then
    begin
      Result := False; // 超时
      Exit;
    end;
    Sleep(500); // 避免CPU过度占用，每次循环暂停100毫秒
  end;
  Result := True;
end;

function ExecuteAndWait(FileName : string) : Boolean;
var
  ShellExecuteInfo: TShellExecuteInfo;
  aRESULT : DWORD;
begin
  // 初始化 ShellExecuteInfo 结构
  FillChar(ShellExecuteInfo, SizeOf(ShellExecuteInfo), 0);
  ShellExecuteInfo.cbSize := SizeOf(TShellExecuteInfo);
  ShellExecuteInfo.fMask := SEE_MASK_NOCLOSEPROCESS; // 关键：请求进程句柄
  ShellExecuteInfo.Wnd := 0; // 父窗口句柄，可为0
  ShellExecuteInfo.lpFile := PChar(FileName); // 要执行的文件
  ShellExecuteInfo.lpParameters := PChar(''); // 命令行参数，若无则为nil或''
  ShellExecuteInfo.nShow := SW_HIDE; // 程序窗口显示方式

  // 执行程序
  if ShellExecuteEx(@ShellExecuteInfo) then
  begin
    // 等待进程结束，INFINITE表示无限等待
    aRESULT := WaitForSingleObject(ShellExecuteInfo.hProcess, 15000);
    

    // 等待结束后，不要忘记关闭进程句柄
    CloseHandle(ShellExecuteInfo.hProcess);
    if aRESULT = WAIT_OBJECT_0 then
      Result := True
      else
        Result := False;

    // 在这里可以继续你的后续代码...
    //ShowMessage('外部程序已执行完毕！');
  end
  else
  begin
    // 处理执行失败的情况
    //ShowMessage('启动外部程序失败！');
    Result := False;
  end;
end;

end.

