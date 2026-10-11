unit Disk;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms, System.Math;

  procedure DiskTest(Num : Word);
  procedure DiskSpace_Test( Space : string);
  function RoundFloat(sFloat: Extended;sInt: Word): Extended;

implementation

uses
  Test_Project_Demo1,RunPg;

const
  DiskType : string = 'IDE';

function RoundFloat(sFloat: Extended; sInt: Word):Extended;
var
vS:string;
begin
  result:=0;
  if sFloat=0 then
     Exit;
  if( (-0.5<sFloat) and (sFloat<0.5)
  and (sInt=0) )then
      Exit;
  vS:='#.'+ StringOfChar('0',sInt);
  result:=StrToFloat(FormatFloat(vS,sFloat));
end;

procedure DiskTest(Num : Word);
var
  DiskList : TStringList;
  i,j,k : Integer;
  FileName,FileName2 : String;
begin
  k := 0;
  FileName := ExtractFilePath(ParamStr(0)) + 'Diskqua.txt';
  FileName2 := ExtractFilePath(ParamStr(0)) + 'Disk.exe';
  DiskList := TStringList.Create;
    try
      if RunProgram(FileName2,True) > 0 then
      begin
        Sleep(3000);
        DiskList.LoadFromFile(FileName);
        if DiskList.Count <> 0 then   k := StrToInt(DiskList[0]);

        if  k = Num then
        begin
          with Test_Project_Demo1.Form2.RzStringGrid1 do
            begin
                for j := 0 to RowCount - 1 do
                begin
                  if Cells[0,j] = '' then
                  begin
                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                       Cells[0,j] :=  '¥≈≈Ã≤‚ ‘';
                       Cells[1,j] := 'ºÏ≤‚µΩ¥≈≈Ã∏ˆ ˝:  ' + IntToStr(k) + ' ∏ˆ';
                       Cells[2,j] := 'PASS';
                       Cells[3,j] := '…Ë÷√∏ˆ ˝: ' + IntToStr(Num);
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
                end;
            end;
            Test_Project_Demo1.Form2.DISK_Result := 'PASS';
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
                       Cells[0,j] :=  '¥≈≈Ã≤‚ ‘';
                       Cells[1,j] := 'ºÏ≤‚µΩ¥≈≈Ã∏ˆ ˝:  ' + IntToStr(k) + ' ∏ˆ';
                       Cells[2,j] := 'FAIL';
                       Cells[3,j] := '…Ë÷√∏ˆ ˝: ' + IntToStr(Num);
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
                end;
            end;
            Test_Project_Demo1.Form2.DISK_Result := 'FAIL';
        end;
      end;
    finally
      DiskList.Free;
    end;
end;

procedure DiskSpace_Test( Space : string);
var
  DiskList,List1 : TStringList;
  i,j : Integer;
  l : Int64;
  k : Int64;
  FileName1,FileName2,Temp : String;
begin
  FileName1 := ExtractFilePath(ParamStr(0)) + 'diskcap.txt';
  FileName2 := ExtractFilePath(ParamStr(0)) + 'Disk.exe';
  DiskList := TStringList.Create;
  Temp := Space;
  if Temp = '' then Exit;
  List1 := TStringList.Create;
  List1.Delimiter := ',';
  List1.DelimitedText := Temp;
  if FileExists(FileName1) then DeleteFile(FileName1);
    try
      if RunProgram(FileName2,True) > 0 then
      begin
        DiskList.LoadFromFile(FileName1);
        if DiskList.Count > 1 then
        begin
          for I := 0 to DiskList.Count - 1 do
          begin
              if (DiskList[0] >= List1.Strings[0])  then
              begin
              //Spacea := RoundFloat(k,2);
                  with Test_Project_Demo1.Form2.RzStringGrid1 do
                    begin
                        for j := 0 to RowCount - 1 do
                        begin
                          if Cells[0,j] = '' then
                          begin
                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                               Cells[0,j] :=  '¥≈≈Ã≤‚ ‘';
                               Cells[1,j] := 'ºÏ≤‚µΩ¥≈≈Ã»›¡ø:  ' + IntToStr(k) + ' G';
                               Cells[2,j] := 'PASS';
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                        end;
                    end;
                    Test_Project_Demo1.Form2.DiskSpace_Result := 'PASS';
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
                             Cells[0,j] :=  '¥≈≈Ã≤‚ ‘';
                             Cells[1,j] := 'ºÏ≤‚µΩ¥≈≈Ã»›¡ø:  ' + IntToStr(k) + ' G';
                             Cells[2,j] := 'FAIL';
                             RowCount := RowCount + 1;
                             Row := Row + 1;
                             Update;
                        end;
                      end;
                  end;
                  Test_Project_Demo1.Form2.DiskSpace_Result := 'FAIL';
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
                         Cells[0,j] :=  '¥≈≈Ã≤‚ ‘';
                         Cells[1,j] := 'ºÏ≤‚¥≈≈Ã»›¡ø¥ÌŒÛ';
                         Cells[2,j] := 'FAIL';
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                  end;
              end;
              Test_Project_Demo1.Form2.DiskSpace_Result := 'FAIL';
        end;
      end;
    finally
      DiskList.Free;
    end;
end;

end.
