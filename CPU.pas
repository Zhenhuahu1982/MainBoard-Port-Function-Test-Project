unit CPU;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms, System.Win.ComObj,
  Winapi.ActiveX, System.Variants;

  procedure CPUTest(sName: string);stdcall;
  function GetCPUInfo: string;

implementation

uses
  Test_Project_Demo1,RunPg;


procedure CPUTest(sName : String);
var
  i,j : Word;
  FileName,Parame : String;
begin
  try
    Parame := GetCPUInfo;
    if Trim(Parame) = sName then
    begin
      with Test_Project_Demo1.Form2.RzStringGrid1 do
      begin
          for j := 0 to RowCount - 1 do
          begin
            if Cells[0,j] = '' then
            begin
               //ShowMessage(RzStringGrid1.Cells[1,j]);
                 Cells[0,j] :=  'CPU名称测试';
                 Cells[1,j] := 'CPU名称: ' + Parame;
                 Cells[2,j] := 'PASS';
                 Cells[3,j] := '设置名称: ' + #13#10 + sName;
                 RowCount := RowCount + 1;
                 Row := Row + 1;
                 Update;
            end;
          end;
      end;
      Test_Project_Demo1.Form2.CPU_Result := 'PASS';
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
                     Cells[0,j] :=  'CPU名称测试';
                     Cells[1,j] := 'CPU名称: ' + Parame;
                     Cells[2,j] := 'FAIL';
                     Cells[3,j] := '设置名称: ' + #13#10 + sName;
                     RowCount := RowCount + 1;
                     Row := Row + 1;
                     Update;
                end;
              end;
          end;
          Test_Project_Demo1.Form2.CPU_Result := 'FAIL';
       end;
    finally
    end;
end;

function GetCPUInfo: string;
var
  WMIService: OLEVariant;
  WMIObjectSet: OLEVariant;
  WMIObject: OLEVariant;
  Enum: IEnumVariant;
  Value: LongWord;
  CPUInfo: string;
begin
  CPUInfo := '';
  try
    // 初始化 COM 库
    CoInitialize(nil);

    // 创建 WMI 服务对象
    WMIService := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := WMIService.ConnectServer('.', 'root\CIMV2');

    // 查询 CPU 信息
    WMIObjectSet := WMIService.ExecQuery('SELECT * FROM Win32_Processor');

    // 获取查询结果
    Enum := (IUnknown(WMIObjectSet._NewEnum) as IEnumVariant);

    while Enum.Next(1, WMIObject, Value) = 0 do
    begin
      // 累加 CPU 名称信息
      CPUInfo := WMIObject.Name;
    end;
  finally
    // 释放 COM 库
    CoUninitialize;
  end;

  Result := CPUInfo;
end;

end.
