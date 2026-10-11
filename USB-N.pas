unit USB;

interface

uses
  Winapi.ShellAPI,System.Classes,Winapi.Windows,Winapi.Messages,System.IniFiles,
  System.SysUtils,Vcl.Dialogs,Vcl.Graphics,Vcl.Forms,System.StrUtils,Winapi.TlHelp32;

  procedure USBTest(USB2 : Word; USB3 : Word; USB2_Flag : Word; USB3_Flag : Word);
  procedure USB3Test(USB3 : Word);
  procedure USB2Test(USB2 : Word);
  function ScanThread(ThreadName : string) :Boolean;

implementation

uses
  Test_Project_Demo1,RunPg,GetSystemInfo1;


procedure USBTest(USB2 : Word; USB3 : Word; USB2_Flag : Word; USB3_Flag : Word);
var
  SStr : TStringlist;
  j,usb2_num,usb3_num : Word;
  sFileName,Params,Parms : string;
begin
    usb2_num := 0;
    usb3_num := 0;
    j := 0;
     sFileName := ExtractFilePath(ParamStr(0)) + 'USB.exe';
     Params := ExtractFilePath(ParamStr(0)) + 'usbtest.txt';
     SStr := TStringList.Create;
    try
        try
        if FileExists(sFileName) then
        begin
            if RunProgram(sFileName,True) > 0 then
            begin
                  Sleep(2000);
                  SStr.LoadFromFile(Params);
                  //j := StrToInt(RightStr(Trim(SStr[11]),2));
                  if USB2_Flag = 0 then
                  begin
                      if SStr.Count <> 0 then
                      begin
                          usb2_num := StrToInt(Trim(RightStr(SStr[0],Length(SStr[0]) - 5)));
                           if GetSystemVersion = 'Windows7' then
                           begin
                              if  usb2_num = USB2 then
                              begin
                                  with Test_Project_Demo1.Form2.RzStringGrid1 do
                                  begin
                                      for j := 0 to RowCount - 1 do
                                      begin
                                        if Cells[0,j] = '' then
                                        begin
                                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                                           Cells[0,j] :=  'USB2.0接口测试';
                                           Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                                             Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                            end
                            else if GetSystemVersion = 'Windows10' then
                            begin
                              if ( usb2_num = USB2) then
                              begin
                                  with Test_Project_Demo1.Form2.RzStringGrid1 do
                                  begin
                                      for j := 0 to RowCount - 1 do
                                      begin
                                        if Cells[0,j] = '' then
                                        begin
                                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                                           Cells[0,j] :=  'USB2.0接口测试';
                                           Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                                             Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                      end;
                  end
                  else
                    Test_Project_Demo1.Form2.USB2_Result := '未测试';


                  //usb3.0
                  //sum2 := m + Hub1;             //sum2 为 USB3.0 + HUB 的总数
                  if USB3_Flag = 0 then
                  begin
                      if SStr.Count > 1 then
                      begin
                        if Trim(RightStr(SStr[1],Length(SStr[1]) - 5)) <> '' then
                            usb3_num := StrToInt(Trim(RightStr(SStr[1],Length(SStr[1]) - 5)))
                            else
                              usb3_num := 0;
                            if GetSystemVersion = 'Windows7' then
                            begin
                                if ( usb3_num = USB3) then
                                begin
                                    with Test_Project_Demo1.Form2.RzStringGrid1 do
                                    begin
                                        for j := 0 to RowCount - 1 do
                                        begin
                                          if Cells[0,j] = '' then
                                          begin
                                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                                             Cells[0,j] :=  'USB3.0接口测试';
                                             Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                                               Cells[0,j] :=  'USB3.0接口测试';
                                               Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                            end
                            else if GetSystemVersion = 'Windows10' then
                            begin
                                  if ( usb3_num = USB3) then
                                  begin
                                      with Test_Project_Demo1.Form2.RzStringGrid1 do
                                      begin
                                          for j := 0 to RowCount - 1 do
                                          begin
                                            if Cells[0,j] = '' then
                                            begin
                                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                               Cells[0,j] :=  'USB3.0接口测试';
                                               Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                                 Cells[0,j] :=  'USB3.0接口测试';
                                                 Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                          end;
                      end
                  else
                       Test_Project_Demo1.Form2.USB3_Result := '未测试';
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
                               Cells[0,j] :=  'USB接口测试';
                               Cells[1,j] := '程序执行错误';
                               Cells[2,j] := 'FAIL';
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                        end;
                    end;
                   Test_Project_Demo1.Form2.USB2_Result := 'FAIL';
                   Test_Project_Demo1.Form2.USB3_Result := 'FAIL';
            end;
        end;
        except on e:Exception do
          begin
            MessageBox(0,PChar(e.Message),'错误',MB_OK + MB_ICONSTOP);
          end;

        end;
    finally
      SStr.Free;
      //if FileExists(Params) then DeleteFile(Params);
    end;

end;

procedure USB2Test(USB2 : Word);
var
  //iniFile : TIniFile;
  SStr : TStringlist;
  j,usb2_num : Word;
  sFileName,Params : string;
begin

    usb2_num := 0;
    j := 0;
     sFileName := ExtractFilePath(ParamStr(0)) + 'USB.exe';
     Params := ExtractFilePath(ParamStr(0)) + 'usbtest.txt';
     SStr := TStringList.Create;
    try
            if RunProgram(sFileName,True) > 0 then
            begin
              SStr.LoadFromFile(Params);
              if SStr.Count <> 0 then
              begin
                  usb2_num := StrToInt(Trim(RightStr(SStr[0],Length(SStr[0]) - 5)));
                   if GetSystemVersion = 'Windows7' then
                   begin
                      if  usb2_num = USB2 then
                      begin
                          with Test_Project_Demo1.Form2.RzStringGrid1 do
                          begin
                              for j := 0 to RowCount - 1 do
                              begin
                                if Cells[0,j] = '' then
                                begin
                                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                                   Cells[0,j] :=  'USB2.0接口测试';
                                   Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                                     Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                    end
                    else if GetSystemVersion = 'Windows10' then
                    begin
                      if ( usb2_num = USB2) then
                      begin
                          with Test_Project_Demo1.Form2.RzStringGrid1 do
                          begin
                              for j := 0 to RowCount - 1 do
                              begin
                                if Cells[0,j] = '' then
                                begin
                                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                                   Cells[0,j] :=  'USB2.0接口测试';
                                   Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                                     Cells[1,j] := '检测到USB2.0个数为:  ' + IntToStr(usb2_num) + ' 个';
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
                           Cells[0,j] :=  'USB2.0接口测试';
                           Cells[1,j] := '程序执行错误';
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

    finally
      SStr.Free;

    end;
end;


procedure USB3Test(USB3 : Word);
var
  //iniFile : TIniFile;
  SStr : TStringlist;
  j,usb3_num : Word;
  sFileName,Params : string;
begin

    sFileName := ExtractFilePath(ParamStr(0)) + 'USB.exe';
    Params := ExtractFilePath(ParamStr(0)) + 'usbtest.txt';
    SStr := TStringList.Create;
    try
            if RunProgram(sFileName,True) > 0 then
            begin
              SStr.LoadFromFile(Params);
              if SStr.Count > 1 then
              begin
                if Trim(RightStr(SStr[1],Length(SStr[1]) - 5)) <> '' then
                    usb3_num := StrToInt(Trim(RightStr(SStr[1],Length(SStr[1]) - 5)))
                    else
                      usb3_num := 0;
                    if GetSystemVersion = 'Windows7' then
                    begin
                        if ( usb3_num = USB3) then
                        begin
                            with Test_Project_Demo1.Form2.RzStringGrid1 do
                            begin
                                for j := 0 to RowCount - 1 do
                                begin
                                  if Cells[0,j] = '' then
                                  begin
                                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                                     Cells[0,j] :=  'USB3.0接口测试';
                                     Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                                       Cells[0,j] :=  'USB3.0接口测试';
                                       Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                    end
                    else if GetSystemVersion = 'Windows10' then
                    begin
                          if ( usb3_num = USB3) then
                          begin
                              with Test_Project_Demo1.Form2.RzStringGrid1 do
                              begin
                                  for j := 0 to RowCount - 1 do
                                  begin
                                    if Cells[0,j] = '' then
                                    begin
                                       //ShowMessage(RzStringGrid1.Cells[1,j]);
                                       Cells[0,j] :=  'USB3.0接口测试';
                                       Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                                       //ShowMessage(RzStringGrid1.Cells[1,j]);
                                         Cells[0,j] :=  'USB3.0接口测试';
                                         Cells[1,j] := '检测到USB3.0个数为:  ' + IntToStr(usb3_num) + ' 个';
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
                  end
              else
                 Test_Project_Demo1.Form2.USB3_Result := '未测试';
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
                         Cells[1,j] := '程序执行错误';
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
    finally
      SStr.Free;
      //if FileExists(Params) then DeleteFile(Params);

    end;
end;

function ScanThread(ThreadName : string):Boolean;
var
hHand : hwnd;//句柄
fprocessentry32 : TProcessEntry32; //结构类型的变量
zhenjia : Boolean;   //返回一个布尔值（用来判断是否找到进程信息）
//processid : dword; //储存找到的进程ID
mingcheng : string; //储存找到的进程名称 end;
List : TStringList;
i : Integer;
begin
   Result := False;
   List := TStringList.Create;
   try
     hHand := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);   //获得进程快照句柄
     fprocessentry32.dwSize := sizeof(fprocessentry32); //给TProcessEntry32结构的第一个参数赋值（也可以理解为把这个结构的第一个参数初始化）
      zhenjia := Process32First(hHand,fprocessentry32); //使用 Process32First函数取得第一个进程的信息
      while zhenjia = true do //如果 Process32First函数执行成功也就是说找到进程列表里的第一个进程时开始循环
        begin
       zhenjia := Process32Next(hHand,FprocessEntry32); //取得第下一个进程信息
        mingcheng := fprocessentry32.szExeFile; //取得一个进程的名称
        if mingcheng = ThreadName then //如果进程名等于这个字符串
          List.Add(mingcheng);
      end;
      for i := 0 to List.Count - 1 do
        begin

        end;
   finally
     List.Free;
   end;
end;

end.
