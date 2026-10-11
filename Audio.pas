unit Audio;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,System.AnsiStrings;

  procedure Audio_Test;
  procedure AudioEXT_Test;

implementation

uses
  Test_Project_Demo1,RunPg;

const
   LineOut2Mic1 = 'Fail OUTPORT=14 INPORT=18 Playback/Recording test!';
   L2M_THDN = 'Fail OUTPORT=14 INPORT=18 THD+N test!';
   MIC1 = 'Fail INPORT=18 L/R Channel Short Test!';


procedure AudioExt_Test;
Var
  FileName,FileName1 : String;
  j : Integer;
  sTemp : string;
begin
      sTemp := ' /Speaker';
      FileName := ExtractFilePath(ParamStr(0)) + 'Mp3_Player_Pro.exe';
      FileName1 := ExtractFilePath(ParamStr(0)) + 'SPK_Fail.txt';
      if FileExists(FileName1) then DeleteFile(FileName1);
      ShellExecute(0,'Open','SetDefaultDevice64.exe',PChar(sTemp),nil,0);
      if RunProgram(FileName,True) > 0 then
      begin
           if FileExists(FileName1) then
           begin
             with Test_Project_Demo1.Form2.RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                    if Cells[0,j] = '' then
                    begin
                       //ShowMessage(RzStringGrid1.Cells[1,j]);
                         Cells[0,j] :=  '外接喇叭测试';
                         Cells[1,j] := '左右声道放音测试';
                         Cells[2,j] := 'FAIL';
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                  end;
              end;
              Test_Project_Demo1.Form2.AudioEXT_Result := 'FAIL';
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
                       Cells[0,j] :=  '外接喇叭测试';
                       Cells[1,j] := '左右声道放音测试';
                       Cells[2,j] := 'PASS';
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
                end;
              end;
              Test_Project_Demo1.Form2.AudioEXT_Result := 'PASS';
           end;
      end;

end;

procedure Audio_Test;
Var
  FileName,FileName1,FileName2,FileName3 : String;
  i,j : Integer;
  sTemp : string;
  List1 : TStringList;
  Rt : Cardinal;
begin

      sTemp := ' /Speaker';
      List1 := TStringList.Create;
      FileName := ExtractFilePath(ParamStr(0)) + 'Audio' + '\wautest.exe';
      FileName1 := ExtractFilePath(ParamStr(0)) + 'Audio' + '\Pass.txt';
      FileName2 := ExtractFilePath(ParamStr(0)) + 'Audio' + '\Fail.txt';
      FileName3 := ExtractFilePath(ParamStr(0)) + 'Audio' + '\SetDefaultDevice64.exe';
   try
      ShellExecute(0,'Open',PChar(FileName3),PChar(sTemp),nil,0);  // 设置默认的音频设备
      //List1.LoadFromFile(FileName2);
      if FileExists(FileName1) then DeleteFile(FileName1);
      Rt := RunProgram(FileName,True);
      if  Rt > 0 then
      begin
        if FileExists(Filename2) then   //如果测试Fail
        begin
            List1.LoadFromFile(FileName2);
            for i := 0 to List1.Count - 1 do
            begin
               if LeftStr(List1[i],4) = 'Fail' then
               Begin
               with Test_Project_Demo1.Form2.RzStringGrid1 do
                  begin
                  for j := 0 to RowCount - 1 do
                      begin
                          if Cells[0,j] = '' then
                          begin
                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                               Cells[0,j] :=  '板载音频测试';
                               Cells[1,j] := Trim(List1[i]);
                               Cells[2,j] := 'FAIL';
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                      end;
                  end;
                  Test_Project_Demo1.Form2.Audio_Result := 'FAIL';
               End;
            end;
            Exit;
        end
        else if FileExists(FileName1) then    //如果测试PASS
        begin
          with Test_Project_Demo1.Form2.RzStringGrid1 do
          begin
          for j := 0 to RowCount - 1 do
            begin
              if Cells[0,j] = '' then
              begin
                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                   Cells[0,j] :=  '板载音频测试';
                   Cells[1,j] := '板载音频功能测试';
                   Cells[2,j] := 'PASS';
                   RowCount := RowCount + 1;
                   Row := Row + 1;
                   Update;
              end;
            end;
          end;
          Test_Project_Demo1.Form2.Audio_Result := 'PASS';
          Exit;
        end
        else        //如果找不到PASS或FAIL记录，那么就判断为程序没执行，可能的结果就是声卡是否正常工作或者测试程序有问题
        with Test_Project_Demo1.Form2.RzStringGrid1 do
        begin
        for j := 0 to RowCount - 1 do
          begin
            if Cells[0,j] = '' then
            begin
               //ShowMessage(RzStringGrid1.Cells[1,j]);
                 Cells[0,j] :=  '板载音频测试';
                 Cells[1,j] := '程序未运行,请检查声卡是否正常！';
                 Cells[2,j] := 'FAIL';
                 RowCount := RowCount + 1;
                 Row := Row + 1;
                 Update;
            end;
          end;
        end;
        Test_Project_Demo1.Form2.Audio_Result := 'FAIL';
        Exit
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
                   Cells[0,j] :=  '板载音频测试';
                   Cells[1,j] := '程序未运行';
                   Cells[2,j] := 'FAIL';
                   RowCount := RowCount + 1;
                   Row := Row + 1;
                   Update;
              end;
            end;
          end;
          Test_Project_Demo1.Form2.Audio_Result := 'FAIL';
          Exit;
      end;
   finally
      List1.Destroy;
   end;
end;


end.
