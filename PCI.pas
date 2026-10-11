unit PCI;

interface
uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,System.StrUtils;


  function PCITest(PCI1 : string; PCI2 : string; PCI3 : string; PCI_Num : Word) : Dword;


implementation

uses
  Test_Project_Demo1,RunPg;

function PCITest(PCI1 : string; PCI2 : string; PCI3 : string; PCI_Num : Word) : DWORD;
var
  List : TStringList;
 i,j,Num : Word;
 Parame,FileName : String;
begin
  Num := 0;
  FileName := ExtractFilePath(ParamStr(0)) + 'PCITest.txt';
  Parame := ExtractFilePath(ParamStr(0)) + 'Get_Nic.exe';
  List := TStringList.Create;
  DeleteFile(FileName);
  try
      if RunProgram(Parame,True) = 0 then
      begin
            with Test_Project_Demo1.Form2.RzStringGrid1 do
            begin
                for j := 0 to RowCount - 1 do
                begin
                  if Cells[0,j] = '' then
                  begin
                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                       Cells[0,j] :=  'PCI设备测试';
                       Cells[1,j] := '程序运行出错';
                       Cells[2,j] := 'FAIL';
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
                end;
            end;
            Test_Project_Demo1.Form2.PCI_Result := 'FAIL';
      end
      else
      begin
          if not FileExists(FileName) then Exit;

          List.LoadFromFile(FileName);

          if StrToInt(List[i]) = PCI_Num then
          begin
              with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                    if Cells[0,j] = '' then
                    begin
                       //ShowMessage(RzStringGrid1.Cells[1,j]);
                         Cells[0,j] :=  'PCI设备测试';
                         Cells[1,j] := '检测到PCI设备个数:  ' + List[i] + ' 张';
                         Cells[2,j] := 'PASS';
                         Cells[3,j] := '设置个数: ' + List[i];
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                  end;
              end;
              Test_Project_Demo1.Form2.PCI_Result := 'PASS';
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
                         Cells[0,j] :=  'PCI设备测试';
                         Cells[1,j] := '检测到PCI设备个数:  ' + List[i] + ' 张';
                         Cells[2,j] := 'FAIL';
                         Cells[3,j] := '设置个数: ' + List[i];
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                  end;
              end;
              Test_Project_Demo1.Form2.PCI_Result := 'FAIL';
          end;
      end;
  finally
    List.Destroy;
  end;
  Result := 90;
end;


end.
