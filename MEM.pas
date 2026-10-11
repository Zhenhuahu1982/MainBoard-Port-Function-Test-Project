unit MEM;

interface

uses
  Winapi.Windows,System.IniFiles,System.StrUtils,Vcl.Forms,System.Classes,
  System.SysUtils,Winapi.Messages,Winapi.ShellAPI, System.Win.ComObj,
  Winapi.ActiveX, System.Variants, system.Types,
  Vcl.Graphics;

  procedure MemN_Test(mem_Num : Word);
  procedure MemS_Test(mem_size : Integer);

implementation

uses
  Test_Project_Demo1,RunPg;


var
  sList : TStringList;

function GetMemorySize: Int64;
var
  WMIService: OLEVariant;
  WMIObjectSet: OLEVariant;
  WMIObject: OLEVariant;
  Enum: IEnumVariant;
  Value: LongWord;
  MemoryInfo: Int64;
begin
  MemoryInfo := 0;
  try
    // 初始化 COM 库
    CoInitialize(nil);

    // 创建 WMI 服务对象
    WMIService := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := WMIService.ConnectServer('.', 'root\CIMV2');

    // 查询内存信息
    WMIObjectSet := WMIService.ExecQuery('SELECT * FROM Win32_PhysicalMemory');

    // 获取查询结果
    Enum := (IUnknown(WMIObjectSet._NewEnum) as IEnumVariant);

    while Enum.Next(1, WMIObject, Value) = 0 do
    begin
      // 累加内存信息
      MemoryInfo := MemoryInfo + WMIObject.Capacity;

      {MemoryInfo +
        'Capacity: ' + VarToStr(WMIObject.Capacity) + ' bytes' + sLineBreak +
        'Speed: ' + VarToStr(WMIObject.Speed) + ' MHz' + sLineBreak +
        'Bank: ' + VarToStr(WMIObject.Banklabel) + sLineBreak;
        }
    end;
  finally
    // 释放 COM 库
    CoUninitialize;
  end;

  Result := MemoryInfo;
end;

function GetMemoryCount: String;
var
  WMIService: OLEVariant;
  WMIObjectSet: OLEVariant;
  WMIObject: OLEVariant;
  Enum: IEnumVariant;
  Value: LongWord;
  MemoryInfo: string;
begin
  MemoryInfo := '';
  try
    // 初始化 COM 库
    CoInitialize(nil);

    // 创建 WMI 服务对象
    WMIService := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := WMIService.ConnectServer('.', 'root\CIMV2');

    // 查询内存信息
    WMIObjectSet := WMIService.ExecQuery('SELECT * FROM Win32_PhysicalMemory');

    // 获取查询结果
    Enum := (IUnknown(WMIObjectSet._NewEnum) as IEnumVariant);

    while Enum.Next(1, WMIObject, Value) = 0 do
    begin
      // 累加内存信息
      //if WMIObject.Banklabel <>  then
      MemoryInfo := MemoryInfo + WMIObject.Banklabel;
      if WMIObject.Banklabel <> '' then
         sList.Add(WMIObject.Banklabel);
    end;
  finally
    // 释放 COM 库
    CoUninitialize;
  end;

  Result := MemoryInfo;
end;


procedure MemN_Test(Mem_Num : Word);
var
  j,sum : Int64;
  str1 : string;
begin

  sList := TStringList.Create;
  str1 := GetMemoryCount;

  sum := sList.Count;
  try
      if sum = mem_Num then begin
       with Test_Project_Demo1.Form2.RzStringGrid1 do
            begin
                for j := 0 to RowCount - 1 do
                begin
                    if Cells[0,j] = '' then
                    begin
                       //ShowMessage(RzStringGrid1.Cells[1,j]);
                         Cells[0,j] :=  '内存测试';
                         Cells[1,j] := '内存条数测试: ' + IntToStr(sum) + ' 条';
                         Cells[2,j] := 'PASS';
                         Cells[3,j] := '设置内存条数: ' + #13#10 + IntToStr(Mem_Num);
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                end;
            end;
            Test_Project_Demo1.Form2.MEMN_Result := 'PASS';
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
                         Cells[0,j] :=  '内存测试';
                         Cells[1,j] := '内存条数测试: ' + IntToStr(sum) + ' 条';
                         Cells[2,j] := 'FAIL';
                         Cells[3,j] := '设置内存条数: ' + #13#10 + IntToStr(Mem_Num);
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                end;
            end;
            Test_Project_Demo1.Form2.MEMN_Result := 'FAIL';
       end;
  Finally
    sList.Destroy;
  End;
end;

procedure MemS_Test(Mem_Size : Integer);
var
  i,j,sum : Int64;

begin
  sum := 0;
  //messagebox(0,PChar(inttostr(Mem_size)), PChar('MEM SIZE'),mb_ok);
  Try
    i := GetMemorySize;
    sum := sum + Trunc(i/1024/1024);

      if sum = Mem_Size then begin
       with Test_Project_Demo1.Form2.RzStringGrid1 do
            begin
                for j := 0 to RowCount - 1 do
                begin
                  if Cells[0,j] = '' then
                  begin
                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                       Cells[0,j] :=  '内存测试';
                       Cells[1,j] := '内存容量测试: ' + IntToStr(sum) + ' MB';
                       Cells[2,j] := 'PASS';
                       Cells[3,j] := '设置容量: ' + #13#10 + IntToStr(Mem_Size);
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
                end;
            end;
            Test_Project_Demo1.Form2.MEMS_Result := 'PASS';
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
                       Cells[0,j] :=  '内存测试';
                       Cells[1,j] := '内存容量测试: ' + IntToStr(sum) + ' MB';
                       Cells[2,j] := 'FAIL';
                       Cells[3,j] := '设置容量: ' + #13#10 + IntToStr(Mem_Size);
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
                end;
            end;
            Test_Project_Demo1.Form2.MEMS_Result := 'FAIL';
      end;

  Finally

  End;


end;

end.
