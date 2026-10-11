unit WiFi;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, StdCtrls, ExtCtrls, ComCtrls, nduWlanAPI, System.StrUtils,
  nduWlanTypes, RzListVw, Winapi.ShellAPI;


    procedure Scan(WIFI_NAME: string; WIFI_QUALT : Word);
    procedure WIFI_Connect(wName : string; WIFI_QUALT, Over_Time : Word);
    function CPa(wname,wmsg,amsg : string) : integer;
    function Get_Time(T : Integer) : Integer;
    function Wifi_FunTest(wName : string; WIFI_QUALT, Over_Time : Word): Integer;


implementation

uses
  Test_Project_Demo1,Lan,RunPg,GetSystemInfo1;


function DOT11_AUTH_ALGORITHM_To_String
  (Dummy: Tndu_DOT11_AUTH_ALGORITHM): String;
begin
  Result := '';
  case Dummy of
    DOT11_AUTH_ALGO_80211_OPEN:
      Result := '80211_OPEN';
    DOT11_AUTH_ALGO_80211_SHARED_KEY:
      Result := '80211_SHARED_KEY';
    DOT11_AUTH_ALGO_WPA:
      Result := 'WPA';
    DOT11_AUTH_ALGO_WPA_PSK:
      Result := 'WPA_PSK';
    DOT11_AUTH_ALGO_WPA_NONE:
      Result := 'WPA_NONE';
    DOT11_AUTH_ALGO_RSNA:
      Result := 'RSNA';
    DOT11_AUTH_ALGO_RSNA_PSK:
      Result := 'RSNA_PSK';
    DOT11_AUTH_ALGO_IHV_START:
      Result := 'IHV_START';
    DOT11_AUTH_ALGO_IHV_END:
      Result := 'IHV_END';
  end;
end;

function DOT11_CIPHER_ALGORITHM_To_String
  (Dummy: Tndu_DOT11_CIPHER_ALGORITHM): String;
begin
  Result := '';
  case Dummy of
    DOT11_CIPHER_ALGO_NONE:
      Result := 'NONE';
    DOT11_CIPHER_ALGO_WEP40:
      Result := 'WEP40';
    DOT11_CIPHER_ALGO_TKIP:
      Result := 'TKIP';
    DOT11_CIPHER_ALGO_CCMP:
      Result := 'CCMP';
    DOT11_CIPHER_ALGO_WEP104:
      Result := 'WEP104';
    DOT11_CIPHER_ALGO_WPA_USE_GROUP:
      Result := 'WPA_USE_GROUP OR RSN_USE_GROUP';
    // DOT11_CIPHER_ALGO_RSN_USE_GROUP : Result:= 'RSN_USE_GROUP';
    DOT11_CIPHER_ALGO_WEP:
      Result := 'WEP';
    DOT11_CIPHER_ALGO_IHV_START:
      Result := 'IHV_START';
    DOT11_CIPHER_ALGO_IHV_END:
      Result := 'IHV_END';
  end;
end;

procedure Scan(WIFI_NAME : String; WIFI_QUALT : Word);
const
  WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_ADHOC_PROFILES = $00000001;
var
  hClient: THandle;
  dwVersion: DWORD;
  ResultInt: DWORD;
  pInterface: Pndu_WLAN_INTERFACE_INFO_LIST;
  i,a : Integer;
  j,n,cishu : Integer;
  k,w1,w2 : string;
  pAvailableNetworkList: Pndu_WLAN_AVAILABLE_NETWORK_LIST;
  pInterfaceGuid: PGUID;
  SDummy, tName: string;  //tName 用来临时存放信号名称
  List1 : TStringList;
  flag,c1,fg1 : Word;
  T_Qualt : Integer;  // 3次信号的总和
begin
  list1 := TStringList.Create;
  list1.Text := AnsiReplaceText(WIFI_NAME,';',#13#10);
  w1 := List1[0];
  if List1.Count = 2 then
  begin
    w2 := List1[1];
    flag := 0;
    c1 := 2;
  end
  else if List1.Count = 1 then
  begin
    flag := 1;
    Test_Project_Demo1.Form2.WIFI1_Result := '未测试';
  end;
  cishu := 1;  //记录wifi 核对次数
  tName := '';
  T_Qualt := 0;
  //k := 0;
  try
      ResultInt := WlanOpenHandle(1, nil, @dwVersion, @hClient);
      try
          if ResultInt <> ERROR_SUCCESS then
          begin
            ResultInt := GetLastError();
            WriteLn('Error Open CLient' + IntToStr(ResultInt));
            with Test_Project_Demo1.Form2.RzStringGrid1 do
                    begin
                        for n := 0 to RowCount - 1 do
                        begin
                          if Cells[0,n] = '' then
                          begin
                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                               Cells[0,n] := 'WIFI测试';
                               Cells[1,n] := '打开客户端错误';
                               Cells[2,n] := 'FAIL';
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                        end;
                    end;
            Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
          end;

          ResultInt := WlanEnumInterfaces(hClient, nil, @pInterface);
          if ResultInt <> ERROR_SUCCESS then
          begin
            WriteLn('Error Enum Interfaces ' + IntToStr(ResultInt));
            with Test_Project_Demo1.Form2.RzStringGrid1 do
                    begin
                        for n := 0 to RowCount - 1 do
                        begin
                          if Cells[0,n] = '' then
                          begin
                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                               Cells[0,n] := 'WIFI测试';
                               Cells[1,n] := '打开枚举接口错误';
                               Cells[2,n] := 'FAIL';
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                        end;
                    end;
            Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
          end;

          for i := 0 to pInterface^.dwNumberOfItems - 1 do
          begin
            //ComboBox1.Items.Add('Interface       ' + pInterface^.InterfaceInfo[i]
            //  .strInterfaceDescription);
           // Edit1.Text := ('GUID            ' + GUIDToString(pInterface^.InterfaceInfo
           //   [i].InterfaceGuid));

              pInterfaceGuid := @pInterface^.InterfaceInfo[pInterface^.dwIndex]
                .InterfaceGuid;

              ResultInt := WlanGetAvailableNetworkList(hClient, pInterfaceGuid,
                WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_ADHOC_PROFILES, nil,
                pAvailableNetworkList);
              if ResultInt <> ERROR_SUCCESS then
              begin
                WriteLn('Error WlanGetAvailableNetworkList ' + IntToStr(ResultInt));
                with Test_Project_Demo1.Form2.RzStringGrid1 do
                      begin
                          for n := 0 to RowCount - 1 do
                          begin
                            if Cells[0,n] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 Cells[0,n] := 'WIFI测试';
                                 Cells[1,n] := '获取WLAN网络错误';
                                 Cells[2,n] := 'FAIL';
                                 RowCount := RowCount + 1;
                                 Row := Row + 1;
                                 Update;
                            end;
                          end;
                      end;
                Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
              end;
            end;
      Except on e: Exception do
        begin
            with Test_Project_Demo1.Form2.RzStringGrid1 do
                  begin
                      for n := 0 to RowCount - 1 do
                      begin
                        if Cells[0,n] = '' then
                        begin
                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                             Cells[0,n] := 'WIFI测试';
                             Cells[1,n] := '获取WLAN网络错误';
                             Cells[2,n] := 'FAIL';
                             RowCount := RowCount + 1;
                             Row := Row + 1;
                             Update;
                        end;
                      end;
                  end;
            Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
            Exit;
        end;
      end;

      for j := 0 to pAvailableNetworkList^.dwNumberOfItems - 1 do
      Begin
        //l := RzLV1.Items.Add;
            Inc(cishu);

            SDummy := AnsiString(PAnsiChar(@pAvailableNetworkList^.Network[j].dot11Ssid.ucSSID));
            if (SDummy = w1) then
            begin
                  Dec(c1);
                  if Length(tName) = 0 then
                  begin
                    tName := SDummy;
                    fg1 := 0;
                  end
                  else
                    if AnsiCompareStr(tName, SDummy) <> 0 then fg1 := 0
                    else
                      fg1 := 1;

                if fg1 = 0 then
                begin
                    for i := 0 to 2 do
                    begin
                      k := Format('%d',
                      [pAvailableNetworkList^.Network[j].wlanSignalQuality]);
                      T_Qualt := T_Qualt + StrToInt(K);
                    end;
                    //MessageBox(0,PChar(w1),PChar('提示'),MB_OK);
                    if (T_Qualt / 3) >= WIFI_QUALT then
                    begin
                    with Test_Project_Demo1.Form2.RzStringGrid1 do
                      begin
                          for n := 0 to RowCount - 1 do
                          begin
                              if Cells[0,n] = '' then
                              begin
                                   Cells[0,n] := 'WIFI测试';
                                   Cells[1,n] := 'WIFI名称: ' + SDummy + '; WIFI信号强度: ' + k + '%';
                                   Cells[2,n] := 'PASS';
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                          end;
                      end;
                      Test_Project_Demo1.Form2.WIFI_Result := 'PASS';
                      //Exit;
                      //WiFi_Connect(w1);
                      if flag = 1 then
                      begin
                        Test_Project_Demo1.Form2.WIFI1_Result := '未测试';
                        exit;
                      end;
                      if c1 <= 0 then Exit;

                    end
                    else
                    begin
                      with Test_Project_Demo1.Form2.RzStringGrid1 do
                        begin
                            for n := 0 to RowCount - 1 do
                            begin
                              if Cells[0,n] = '' then
                              begin
                                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                                   Cells[0,n] := 'WIFI测试';
                                   Cells[1,n] := 'WIFI名称: ' + SDummy + '; WIFI信号强度: ' + k + '%';
                                   Cells[2,n] := 'FAIL';
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                            end;
                        end;
                        Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
                        //Exit;
                        if flag = 1 then
                        begin
                          Test_Project_Demo1.Form2.WIFI1_Result := '未测试';
                          exit;
                        end;
                        if c1 <= 0 then Exit;
                    end;
                end;
            end
            else if (SDummy = w2) then
            begin
                  Dec(c1);
                  if Length(tName) = 0 then
                  begin
                    tName := SDummy;
                    fg1 := 0;
                  end
                  else
                    if AnsiCompareStr(tName, SDummy) <> 0 then fg1 := 0
                    else
                      fg1 := 1;

                if fg1 = 0 then
                begin
                    for i := 0 to 2 do
                    begin
                      k := Format('%d',
                      [pAvailableNetworkList^.Network[j].wlanSignalQuality]);
                      T_Qualt := T_Qualt + StrToInt(K);
                    end;
                    //MessageBox(0,PChar(SDummy + ': ' +IntToStr(T_Qualt)),PChar('提示'),MB_OK);
                    //MessageBox(0,PChar(w2),PChar('提示'),MB_OK);
                    if (T_Qualt / 3) >= WIFI_QUALT then
                    begin
                    with Test_Project_Demo1.Form2.RzStringGrid1 do
                      begin
                          for n := 0 to RowCount - 1 do
                          begin
                              if Cells[0,n] = '' then
                              begin
                                   Cells[0,n] := 'WIFI测试';
                                   Cells[1,n] := 'WIFI名称: ' + SDummy + '; WIFI信号强度: ' + k + '%';
                                   Cells[2,n] := 'PASS';
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                          end;
                      end;
                      Test_Project_Demo1.Form2.WIFI1_Result := 'PASS';
                      //Exit;
                      //WiFi_Connect(w2);
                      if flag = 1 then begin
                                  Test_Project_Demo1.Form2.WIFI1_Result := '未测试';
                                  exit;
                      end;
                      if c1 <= 0 then Exit;

                    end
                    else
                    begin
                      with Test_Project_Demo1.Form2.RzStringGrid1 do
                        begin
                            for n := 0 to RowCount - 1 do
                            begin
                              if Cells[0,n] = '' then
                              begin
                                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                                   Cells[0,n] := 'WIFI测试';
                                   Cells[1,n] := 'WIFI名称: ' + SDummy + '; WIFI信号强度: ' + k + '%';
                                   Cells[2,n] := 'FAIL';
                                   RowCount := RowCount + 1;
                                   Row := Row + 1;
                                   Update;
                              end;
                            end;
                        end;
                        Test_Project_Demo1.Form2.WIFI1_Result := 'FAIL';
                        //Exit;
                        if flag = 1 then begin
                            Test_Project_Demo1.Form2.WIFI1_Result := '未测试';
                            exit;
                        end;
                        if c1 <= 0 then Exit;
                    end;
                end
            end
            else if (cishu >= pAvailableNetworkList^.dwNumberOfItems) then
                begin
                   with Test_Project_Demo1.Form2.RzStringGrid1 do
                      begin
                          for n := 0 to RowCount - 1 do
                          begin
                            if Cells[0,n] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 Cells[0,n] := 'WIFI测试';
                                 Cells[1,n] := '找不到WIFI名称相匹配的信号源';
                                 Cells[2,n] := 'FAIL';
                                 RowCount := RowCount + 1;
                                 Row := Row + 1;
                                 Update;
                            end;
                          end;
                      end;
                      Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
                      if flag = 1 then begin
                            Test_Project_Demo1.Form2.WIFI1_Result := '未测试';
                            //exit;
                      end;
                end;
        {SDummy := GetEnumName(TypeInfo(Tndu_DOT11_AUTH_ALGORITHM),integer(pAvailableNetworkList^.Network[j].dot11DefaultAuthAlgorithm)) ;
        SDummy := DOT11_AUTH_ALGORITHM_To_String(pAvailableNetworkList^.Network[j]
          .dot11DefaultAuthAlgorithm);
        l.SubItems.Add(SDummy);
        SDummy := DOT11_CIPHER_ALGORITHM_To_String
          (pAvailableNetworkList^.Network[j].dot11DefaultCipherAlgorithm);
        l.SubItems.Add(SDummy); }
      End;
    finally
      WlanCloseHandle(hClient, nil);
      List1.Free;
  end;

end;


procedure WIFI_Connect(wName : string; WIFI_QUALT, Over_Time : Word);
var
  FileName,FileName1,FileName2,FileName3 : string;
  aName,wQuaty : string;
  w1,w2,winver : string;
  List1 : TStringList;
begin
  List1 := TStringList.Create;
  FileName := ExtractFilePath(Application.ExeName) + 'wifi1.exe';
  FileName1 := ExtractFilePath(Application.ExeName) + 'wifi2.exe';
  list1.Text := AnsiReplaceText(wName,';',#13#10);
  w1 := Trim(List1[0]);
  if List1.Count = 2 then
  begin
    w2 := Trim(List1[1]);
    flag := 0;
  end
  else if List1.Count = 1 then
  begin
    flag := 1;
    Test_Project_Demo1.Form2.WIFI1_Result := '未测试';
  end;
  //MessageBox(0,PChar(FileName),PChar('提示'),MB_OK);

  if not FileExists(FileName) then  exit;
  if not FileExists(FileName1) then Exit;

  try
    try
    if Flag = 0 then begin
      winver := GetSystemVersion;
      //MessageBox(0,PChar(winver),PChar('提示'),MB_OK);
      if winver = 'Windows7' then
      begin
        //Get_Time(2000);
        //ShellExecute(0,'open',PChar(FileName),nil,nil, HIDE_WINDOW);
        //MessageBox(0,PChar(winver),PChar('提示'),MB_OK);
        if ShellExecute(0,'open',PChar(FileName),nil,nil, HIDE_WINDOW) > 32 then
        begin
          Sleep(3000);
          if Wifi_FunTest(w1,WIFI_QUALT, Over_Time) = 0 then
            Test_Project_Demo1.Form2.WIFI_Result := 'PASS'
            else
              Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
        end;
        if ShellExecute(0,'open',PChar(FileName1),nil,nil, HIDE_WINDOW) > 32 then
        begin
          Sleep(3000);
          if Wifi_FunTest(w2,WIFI_QUALT, Over_Time) = 0 then
            Test_Project_Demo1.Form2.WIFI1_Result := 'PASS'
            else
              Test_Project_Demo1.Form2.WIFI1_Result := 'FAIL';
        end;
      end
      else if winver = 'Windows10' then
           begin
              Get_Time(2000);
              //ShellExecute(0,'open',PChar(FileName),nil,nil, HIDE_WINDOW);
              //MessageBox(0,PChar(winver),PChar('提示'),MB_OK);
              if RunProgram(FileName, True) > 32 then
              begin
                Get_Time(3000);
                if Wifi_FunTest(w1,WIFI_QUALT, Over_Time) = 0 then
                  Test_Project_Demo1.Form2.WIFI_Result := 'PASS'
                  else
                    Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
              end;
              Get_Time(1000);
              if RunProgram(FileName1, True) > 32 then
              begin
                Get_Time(3000);
                if Wifi_FunTest(w2,WIFI_QUALT, Over_Time) = 0 then
                  Test_Project_Demo1.Form2.WIFI1_Result := 'PASS'
                  else
                    Test_Project_Demo1.Form2.WIFI1_Result := 'FAIL';
              end;
           end;
    end
    else if Flag =1 then
    begin
      winver := GetSystemVersion;
      if winver = 'Windows7' then
      begin
        //MessageBox(0,PChar(winver),PChar('提示'),MB_OK);
        if ShellExecute(0,'open',PChar(FileName),nil,nil, HIDE_WINDOW) > 32 then
        begin
           Sleep(5000);
          if Wifi_FunTest(w1,WIFI_QUALT, Over_Time) = 0 then
            Test_Project_Demo1.Form2.WIFI_Result := 'PASS'
            else
              Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
        end;
      end
      else if winver = 'Windows10' then
           begin
              Get_Time(2000);
              //ShellExecute(0,'open',PChar(FileName),nil,nil, HIDE_WINDOW);
              //MessageBox(0,PChar(winver),PChar('提示'),MB_OK);
              if RunProgram(FileName, True) > 32 then
              begin
                Get_Time(3000);
                if Wifi_FunTest(w1,WIFI_QUALT, Over_Time) = 0 then
                  Test_Project_Demo1.Form2.WIFI_Result := 'PASS'
                  else
                    Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
              end;
           end;
      
    end;

    Except
      on E:Exception do
      begin
         ShowMessage(e.Message);
      end;

    end;
  finally
    List1.Free;
  end;

end;

function Wifi_FunTest(wName : string; WIFI_QUALT, Over_Time : Word): Integer;
var
  str2,str3,str5 : string;
  FileName,FileName1 : string;
  aName,wQuaty : string;
  List1, List2 : TStringList;
  n,i : integer;
begin
      Result := 1;
      List1 := TStringList.Create;
      List2 := TStringList.Create;
      FileName := ExtractFilePath(Application.ExeName) + wName + '.txt';
      FileName1 := ExtractFilePath(Application.ExeName) + wName + '1.txt';
      //str1 := '/c netsh wlan connect name=' + wName  + ' > ' +  FileName;
      //str4 := '/c netsh wlan show interfaces > ' +  FileName1;
      //str7 := '/c netsh wlan disconnect';

      try
         if FileExists(FileName1) then
            List1.LoadFromFile(FileName1);

         if FileExists(FileName) then
            List2.LoadFromFile(FileName);

         if List1.Count <> 0 then
         begin
           if Trim(List1[0]) = 'Connect Fail' then
            begin
              with Test_Project_Demo1.Form2.RzStringGrid1 do
               begin
                 for n := 0 to RowCount - 1 do
                 begin
                      if Cells[0,n] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,n] := 'WIFI测试';
                           Cells[1,n] := 'WIFI: ' + wName + ' 连接失败';
                           Cells[2,n] := 'FAIL';
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
                end;
              Result := 1;
             Exit;
            end;

         end;
         if List2.Count > 18 then
          begin


              for i := 0 to List2.Count - 1 do begin

                if Trim(LeftStr(List2[i],9)) = 'SSID' then
                begin
                   aName := List2[i];
                end;
                if Trim(LeftStr(List2[i],8)) = '信号' then
                begin
                   wQuaty := List2[i];
                end;
              end;

                str2 := RightStr(aName,Length(aName) - 28);
                str3 := RightStr(wQuaty,Length(wQuaty) - 27);
                str5 := LeftStr(str3,Length(str3)-1);

                if (AnsiCompareStr(Trim(str2),wName) = 0) and (StrToInt(str5) >= WIFI_QUALT) then   //如果信号大于等于设定值，那么判定PASS
                begin
                  with Test_Project_Demo1.Form2.RzStringGrid1 do
                  begin
                      for n := 0 to RowCount - 1 do
                      begin
                          if Cells[0,n] = '' then
                          begin
                             //ShowMessage(RzStringGrid1.Cells[1,j]);
                               Cells[0,n] := 'WIFI测试';
                               Cells[1,n] := 'WIFI: ' + wname + ' 连接成功' + '信号强度: ' + str3;
                               Cells[2,n] := 'PASS';
                               RowCount := RowCount + 1;
                               Row := Row + 1;
                               Update;
                          end;
                      end;
                  end;
                  Result := 0;
                end
                else
                begin
                    with Test_Project_Demo1.Form2.RzStringGrid1 do
                     begin
                       for n := 0 to RowCount - 1 do
                       begin
                            if Cells[0,n] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 Cells[0,n] := 'WIFI测试';
                                 Cells[1,n] := 'WIFI: ' + wName + ' 测试失败' + '信号强度: ' + str3;
                                 Cells[2,n] := 'FAIL';
                                 RowCount := RowCount + 1;
                                 Row := Row + 1;
                                 Update;
                            end;
                        end;
                      end;
                   Result := 1;
                end;
          end
          else
            begin
                with Test_Project_Demo1.Form2.RzStringGrid1 do
                 begin
                   for n := 0 to RowCount - 1 do
                   begin
                        if Cells[0,n] = '' then
                        begin
                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                             Cells[0,n] := 'WIFI测试';
                             Cells[1,n] := 'WIFI: ' + wName + ' 连接失败';
                             Cells[2,n] := 'FAIL';
                             RowCount := RowCount + 1;
                             Row := Row + 1;
                             Update;
                        end;
                    end;
                  end;
               Result := 1;

            end;

      finally
        if FileExists(FileName) then DeleteFile(FileName);
        if FileExists(FileName1) then DeleteFile(FileName1);
        //ShellExecute(0,'open','cmd.exe',PChar(str7),nil, HIDE_WIif FileExists(FileName) then DeleteFile(FileName);NDOW);
        List1.Free;
        List2.Free;
      end;
end;

function Get_Time(T : Integer) : Integer;
var
  eStart, eEnd : Integer;
  i : Integer;
begin
  Result := 1;
  i := 1;
  eStart := GetTickCount;
  while i = 1 do
  begin
    eEnd := GetTickCount;
    if (eEnd - eStart) = T then
      i := 0;
  end;
  Result := 0;
end;

function CPa(wname,wmsg,amsg : string) : integer;
const
  succes : string = '已成功完成连接请求。';

var
  n : Integer;

begin
  Result := 1;
  if (AnsiCompareStr(wmsg,succes) = 0) and (Length(amsg) <> 0) then
  begin
    with Test_Project_Demo1.Form2.RzStringGrid1 do
    begin
        for n := 0 to RowCount - 1 do
        begin
            if Cells[0,n] = '' then
            begin
               //ShowMessage(RzStringGrid1.Cells[1,j]);
                 Cells[0,n] := 'WIFI连接测试';
                 Cells[1,n] := 'WIFI: ' + wname + ' 连接成功';
                 Cells[2,n] := 'PASS';
                 RowCount := RowCount + 1;
                 Row := Row + 1;
                 Update;
            end;
        end;
    end;
    Test_Project_Demo1.Form2.WIFI_Result := 'PASS';
    //Exit;
    Result := 0;
  end
  else
  begin
    with Test_Project_Demo1.Form2.RzStringGrid1 do
      begin
          for n := 0 to RowCount - 1 do
          begin
            if Cells[0,n] = '' then
            begin
               //ShowMessage(RzStringGrid1.Cells[1,j]);
                 Cells[0,n] := 'WIFI连接测试';
                 Cells[1,n] := 'WIFI: ' + wname + ' 连接失败';
                 Cells[2,n] := 'FAIL';
                 RowCount := RowCount + 1;
                 Row := Row + 1;
                 Update;
            end;
          end;
      end;
      Test_Project_Demo1.Form2.WIFI_Result := 'FAIL';
      Test_Project_Demo1.Form2.WIFI1_Result := 'FAIL';
      //Exit;
      Result := 1;
  end;

end;



end.
