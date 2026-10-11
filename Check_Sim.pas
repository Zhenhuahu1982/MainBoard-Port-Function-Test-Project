unit Check_Sim;

interface
uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,System.StrUtils,Winapi.Nb30,
  System.Win.Registry,IdIcmpClient,IdTime;

  procedure Read_Sim(sValue: string);

implementation

uses
    Test_Project_Demo1;

procedure Read_Sim(sValue : String);
var
  reg : TRegistry;
  sLMKey : string;
  sCurStr : string;
  sStrToAdd: string;
  j : Integer;
begin
  sLMKey := '\SOFTWARE\Microsoft\Cellular\MVSettings\ICCIDSpecific\89860619130033298497\CellUX';  //环境变量保存在注册表的这个位置
  //我们要修改的是Path环境变量
  sStrToAdd := sValue; //要添加的环境变量
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.KeyExists(sLMKey) then
    begin
      if reg.OpenKey(sLMKey,False) then
      begin
        sCurStr := reg.ReadString('BrandingName'); //读取环境变量
        if sCurStr = sValue then
        begin
             with Test_Project_Demo1.Form2.RzStringGrid1 do
            begin
                for j := 0 to RowCount - 1 do
                begin
                    if Cells[0,j] = '' then
                    begin
                       //ShowMessage(RzStringGrid1.Cells[1,j]);
                         Cells[0,j] :=  'SIM卡测试';
                         Cells[1,j] := 'SIM卡检测: ' + sCurStr;
                         Cells[2,j] := 'PASS';
                         Cells[3,j] := '设置名称: ' + sValue;
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                end;
            end;
            Test_Project_Demo1.Form2.SIM_Result := 'PASS';
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
                         Cells[0,j] :=  'SIM卡测试';
                         Cells[1,j] := 'SIM卡检测: ' + sCurStr;
                         Cells[2,j] := 'FAIL';
                         Cells[3,j] := '设置名称: ' + sValue;
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                end;
            end;
            Test_Project_Demo1.Form2.SIM_Result := 'FAIL';
        end;
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
                         Cells[0,j] :=  'SIM卡测试';
                         Cells[1,j] := 'SIM卡检测: ' + '未侦测到设备';
                         Cells[2,j] := 'FAIL';
                         Cells[3,j] := '设置名称: ' + sValue;
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                end;
            end;
            Test_Project_Demo1.Form2.SIM_Result := 'FAIL';
    end;
  except
    on E: Exception do
    begin
      reg.Free;
      MessageBox(0,PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
      Exit;
    end;
  end;
  reg.Free;
end;

end.
