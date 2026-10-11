unit USB;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,System.StrUtils,Winapi.TlHelp32,
  Vcl.ExtCtrls;

  procedure USBTest(USB2 : Word; USB3 : Word; USB2_Flag : Word; USB3_Flag : Word);
  procedure USB3Test(USB3 : Word);
  procedure USB2Test(USB2 : Word);
  function ScanThread(ThreadName : string) :Boolean;
  function IsFileInUse(AName: string): boolean;
  function killProcessByid(pid:Cardinal):Boolean;
  function findProcessId(pname:string):Cardinal;


implementation

uses
  Test_Project_Demo1,RunPg, UsbCounter;

const
  USB200 : string = 'USB2_No:';
  USB300 : string = 'USB3_No:';

var
    FTimerCounter : Integer;
    FTimer : TTimer;
    U_Flag : boolean;
    sList : TStringList;


function CheckFile : Boolean;
var
  i : Integer;
begin
  Result := False;
  for I := 0 to 60 do
    begin
      Sleep(300);
      if FileExists('C:\Test_Project\usbtest.txt') then
      begin
          if not IsFileInUse('C:\Test_Project\usbtest.txt') then
            Result := True;
          Exit;
      end;
    end;
end;

function IsFileInUse(AName: string): boolean;
var
  hFileRes: HFILE;
begin
  Result := False;
  if not FileExists(AName) then exit;
  hFileRes := CreateFile(PChar(AName), GENERIC_READ or GENERIC_WRITE, 0,
  nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := hFileRes = INVALID_HANDLE_VALUE;
  if not Result then
  CloseHandle(hFileRes);
end;

procedure USBTest(USB2 : Word; USB3 : Word; USB2_Flag : Word; USB3_Flag : Word);
var
  j : Word;
  C2, C3: Integer;
begin
    try
        if GetUsbDeviceCounts(C2, C3) then
          //ShowMessage(Format('USB2.0 设备: %d 个'#13#10'USB3.0 设备: %d 个', [C2, C3]));
        begin
              if USB2_Flag = 0 then
              begin
                  if ( C2 = USB2) then
                    begin
                        with Test_Project_Demo1.Form2.RzStringGrid1 do
                        begin
                            for j := 0 to RowCount - 1 do
                            begin
                              if Cells[0,j] = '' then
                              begin
                                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                                   Cells[0,j] :=  'USB2.0接口测试';
                                   Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(C2) + ' 个';
                                   Cells[2,j] := 'PASS';
                                   Cells[3,j] := '设置个数: ' + IntToStr(USB2);
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                            end;
                        end;
                        Test_Project_Demo1.Form2.USB2_Result := 'PASS';
                        Test_Project_Demo1.Form2.USB2_Num := IntToStr(C2);
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
                                   Cells[0,j] :=  'USB2.0接口测试';
                                   Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(C2) + ' 个';
                                   Cells[2,j] := 'FAIL';
                                   Cells[3,j] := '设置个数: ' + IntToStr(USB2);
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                            end;
                        end;
                        Test_Project_Demo1.Form2.USB2_Result := 'FAIL';
                        Test_Project_Demo1.Form2.USB2_Num := IntToStr(C2);
                  end;
              end
              else
                Test_Project_Demo1.Form2.USB2_Result := '未测试';
              //usb3.0
              if USB3_Flag = 0 then
              begin
                if ( C3 = USB3 ) then
                    begin
                        with Test_Project_Demo1.Form2.RzStringGrid1 do
                        begin
                            for j := 0 to RowCount - 1 do
                            begin
                              if Cells[0,j] = '' then
                              begin
                                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                                   Cells[0,j] :=  'USB3.0接口测试';
                                   Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(C3) + ' 个';
                                   Cells[2,j] := 'PASS';
                                   Cells[3,j] := '设置个数: ' + IntToStr(USB3);
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                            end;
                        end;
                        Test_Project_Demo1.Form2.USB3_Result := 'PASS';
                        Test_Project_Demo1.Form2.USB3_Num := IntToStr(C3);
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
                                   Cells[0,j] :=  'USB3.0接口测试';
                                   Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(C3) + ' 个';
                                   Cells[2,j] := 'FAIL';
                                   Cells[3,j] := '设置个数: ' + IntToStr(USB3);
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                            end;
                        end;
                        Test_Project_Demo1.Form2.USB3_Result := 'FAIL';
                        Test_Project_Demo1.Form2.USB3_Num := IntToStr(C3);
                    end;
              end
              else
                 Test_Project_Demo1.Form2.USB3_Result := '未测试';

        end;
    finally
      FTimer.Free;
    end;
end;

procedure USB2Test(USB2 : Word);
var
  j : Word;
  C2, C3: Integer;
begin
    try

        if GetUsbDeviceCounts(C2, C3) then
        Begin
            if ( C2 = USB2) then
              begin
                  with Test_Project_Demo1.Form2.RzStringGrid1 do
                  begin
                      for j := 0 to RowCount - 1 do
                      begin
                        if Cells[0,j] = '' then
                        begin
                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                             Cells[0,j] :=  'USB2.0接口测试';
                             Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(C2) + ' 个';
                             Cells[2,j] := 'PASS';
                             Cells[3,j] := '设置个数: ' + IntToStr(USB2);
                             RowCount := RowCount + 1;
                             Row := Row + 1;
                             Update;
                        end;
                      end;
                  end;
                  Test_Project_Demo1.Form2.USB2_Result := 'PASS';
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
                           Cells[0,j] :=  'USB2.0接口测试';
                           Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(C2) + ' 个';
                           Cells[2,j] := 'FAIL';
                           Cells[3,j] := '设置个数: ' + IntToStr(USB2);
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                    end;
                end;
                Test_Project_Demo1.Form2.USB2_Result := 'FAIL';
            end;

        end;
    finally

    end;
end;


procedure USB3Test(USB3 : Word);
var
  j : Word;
  C2, C3 : Integer;
begin
    try

        if GetUsbDeviceCounts(C2, C3) then
        begin
          if (C3 = USB3) then
            begin
              with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                    if Cells[0,j] = '' then
                    begin
                         Cells[0,j] :=  'USB3.0接口测试';
                         Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(C3) + ' 个';
                         Cells[2,j] := 'PASS';
                         Cells[3,j] := '设置个数: ' + IntToStr(USB3);
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                  end;
              end;
              Test_Project_Demo1.Form2.USB3_Result := 'PASS';
            end
            else
            begin
              with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                    if Cells[0,j] = '' then
                    begin
                         Cells[0,j] :=  'USB3.0接口测试';
                         Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(C3) + ' 个';
                         Cells[2,j] := 'FAIL';
                         Cells[3,j] := '设置个数: ' + IntToStr(USB3);
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                  end;
              end;
              Test_Project_Demo1.Form2.USB3_Result := 'FAIL';
            end;
          end;
    finally

    end;
end;

function ScanThread(ThreadName : string):Boolean;
var
jubing : hwnd;//句柄
fprocessentry32 : TProcessEntry32; //结构类型的变量
zhenjia : Boolean;   //返回一个布尔值（用来判断是否找到进程信息）
processid : dword; //储存找到的进程ID
mingcheng : string; //储存找到的进程名称 end;
i : Integer;
begin
   try

     jubing := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);   //获得进程快照句柄
     fprocessentry32.dwSize := sizeof(fprocessentry32); //给TProcessEntry32结构的第一个参数赋值（也可以理解为把这个结构的第一个参数初始化）
      zhenjia := Process32First(jubing,fprocessentry32); //使用 Process32First函数取得第一个进程的信息
      while zhenjia = true do //如果 Process32First函数执行成功也就是说找到进程列表里的第一个进程时开始循环
        begin
       zhenjia := Process32Next(jubing,FprocessEntry32); //取得第下一个进程信息
        mingcheng := fprocessentry32.szExeFile; //取得一个进程的名称
        if mingcheng = ThreadName then //如果进程名等于这个字符串
          sList.Add(mingcheng);
      end;

   finally
     //List.Free;
   end;
end;

//需要引用tlhelp32单元//查找进程
function findProcessId(pname:string):Cardinal;
var
    hsnapshot:THandle;
    lpe:TProcessEntry32;
    found:Boolean;
begin
  Result:=0;
  if pname<>'' then
  begin
    hsnapshot:=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
   try
      lpe.dwSize := SizeOf(TProcessEntry32);//在调用Process32First API之前，需要初始化lppe记录的大小
      found:=Process32First(hsnapshot,lpe);
      while found do
      begin
        if UpperCase(lpe.szExeFile)=UpperCase(pname) then
        begin
          Result:=lpe.th32ProcessID;
          Break;
        end;
        found:=Process32Next(hsnapshot,lpe);
      end;
    finally  //关闭快照句柄　　　
      closehandle(hsnapshot);
    end;
  end;
end;

//杀死进程
function killProcessByid(pid:Cardinal):Boolean;
var hd:THandle;
begin
  Result:=False;
  if pid<>0 then
  begin
    hd:=OpenProcess(PROCESS_ALL_ACCESS,true,pid);
    try
      if hd<>0 then
      begin
        Result:=TerminateProcess(hd,0);
      end;
    finally
      CloseHandle(hd);
    end;
  end;
end;

end.
