unit ReadBios;

interface

uses
    Vcl.Graphics, System.Classes, Winapi.Windows, Winapi.Messages, System.SysUtils,
    Vcl.Dialogs, Vcl.Forms, System.Win.Registry, Test_Project_Demo1, ActiveX, Comobj,
    System.Variants, System.AnsiStrings;

    function ReadBiosVal : String;
    procedure CheckBIOS(BIOS:string);
    function GetWMIProperty(WMIType, WMIProperty:AnsiString):String;

implementation

procedure CheckBIOS(BIOS : string);
var
 j : Integer;
 sBios : string;
begin
//    MessageBox(0,PChar(BIOS),PChar('info'),MB_OK);
     sBios := LeftStr(GetWMIProperty('BIOS','ReleaseDate'),8);
    // sBios := ReadBiosVal;
    //MessageBox(0,PChar(sBIOS),PChar('info'),MB_OK);
    if Trim(BIOS) = Trim(sBios) then
       begin
         with Test_Project_Demo1.Form2.RzStringGrid1 do
          begin
              for j := 0 to RowCount - 1 do
              begin
                if Cells[0,j] = '' then
                begin
                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                     Cells[0,j] :=  'BIOS日期测试';
                     Cells[1,j] := 'BIOS日期测试';
                     Cells[2,j] := 'PASS';
                     RowCount := RowCount + 1;
                     Row := Row + 1;
                     Update;
                end;
              end;
          end;
          Test_Project_Demo1.Form2.BIOS_Result := 'PASS';
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
                   Cells[0,j] :=  'BIOS日期测试';
                   Cells[1,j] := 'BIOS日期测试';
                   Cells[2,j] := 'FAIL';
                   RowCount := RowCount + 1;
                   Row := Row + 1;
                   Update;
              end;
            end;
          end;
          Test_Project_Demo1.Form2.BIOS_Result := 'FAIL';
       end;
 //     MessageBox(0,PChar('BIOS'),PChar('info'),MB_OK);
end;

function ReadBiosVal : String;
var
  reg : TRegistry;
  sLMKey : string;
  sCurStr : string;
  sName : String;
begin
  Result := '';
  sLMKey := '\HARDWARE\DESCRIPTION\System\BIOS\';  //环境变量保存在注册表的这个位置
  sName := 'BIOSReleaseDate'; //我们要读取的环境变量
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if reg.OpenKey(sLMKey,False) then
    begin
      sCurStr := reg.ReadString(sName); //读取环境变量
      sCurStr := Trim(sCurStr);
      Result := sCurStr;
      reg.CloseKey;
    end;
  except
    on E: Exception do
    begin
      reg.Free;
      ShowMessage('Error: ' + E.Message);
      Exit;
    end;
  end;
  reg.Free;
end;

function GetWMIProperty(WMIType, WMIProperty:AnsiString):String;
var
  Wmi, Objs, Obj: oleVariant;
  Enum: IEnumVariant;
  C: Cardinal;
begin
  CoInitialize(nil);
  try
      Wmi:= CreateOleObject('WbemScripting.SWbemLocator');
      Objs := Wmi.ConnectServer('.','root/cimv2').ExecQuery('Select * from Win32_' + WMIType);
      Enum := IEnumVariant(IUnknown(Objs._NewEnum));
      Enum.Reset;
      Enum.Next(1,Obj,C);

      Obj := Obj.Properties_.Item(WMIProperty, 0).Value;

      if VarIsNull(obj) then
      begin
        Result:='Error';
      end;

      if VarIsArray(obj) then
      begin
        Result := Obj[0];
      end;

      if VarIsStr(obj) or VarIsCustom(obj) or VarIsFloat(obj) or VarIsNumeric(obj) or VarIsOrdinal(obj) then
      begin
        Result:= Obj;
      end;
  finally
    CoUninitialize;
  end;
end;

end.
