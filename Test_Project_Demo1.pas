unit Test_Project_Demo1;
 {
 Author : huzhenhua

 product by : jiaruishidai shenzhen Co.,Ltd

 Last UpDate Date: 2023-02-10

 修改记录：

 0.0.1  通用测试程序功能建立，包括Windows10系统下的COM口，USB2.0,USB3.0接口,音频接口，网络功能，PCI网卡

 0.0.2  优化COM测试程序，网络功能模块

 0.0.3  增加测试把测试记录写入到网络服务器功能

 0.0.4  针对AMD平台及Intel平台的USB接口测试功能支持

 0.0.5  增加无线网卡测试功能，设定搜寻指定的wifi，及其信号强度

 0.0.6  增加部分有风扇接口的主板风扇转速的监测

 0.0.7  修改测试程序界面，以树形目录来列出测试项目，并以表格方式显示测试的结果

 0.0.8  增加测试程序配置文件防修改功能，修改配置文件后，必须进行重加密才可以运行测试程序。增加内存条数，内存容量测试

 0.0.9  增加双网卡测试功能及外接音频测试功能

 0.1.0  优化双网卡测试模块，解决在CB18双网卡主板，测试完毕后会出现‘连接失败’的问题

 0.1.1  优化音频测试程序，解决在GM32主板上有几率出现在没有侦测到音频驱动，也会提示测试PASS的问题

 1.0.0  正式版

 1.0.1  GC42主板在使用USB3.0 TYPE C HUB测试，修正USB3.0 HUB 识别为 USB 3.0 USB 优盘

 1.0.2  增加SIM卡检测

 1.0.3  1. 修正单网卡测试中，存在其他网卡时，部分机器上会有抓取不到正确地MAC地址的问题。
        2. 修正上传记录中，无内存根数及内存容量测试记录的bug
        3. 修正USB2/USB3 单步测试时，程序一直等待测试结果bug

 1.0.4  优化主板风扇转速检测代码，采用DLL方式获取CPU风扇转速。增加CB42 主板风扇转速功能

 1.0.5  增加硬盘容量测试

 1.0.6  增加 Fintek IO 风扇转速测试

 1.0.7  增加COM测试模式2，在此模式下，支持两个485串口对传数据。

 1.0.8  增加COM测试模式3,4，在此模式下，支持多个232，485串口同时测试。

 1.0.9  修改WIFI 测试功能，支持同时测试两个网络信号检测。

 1.1.0   在E30 增加测试中，WIFI 需支持2.4G 和 5G 网络的检测和连接WIFI 测试

 1.1.1   优化网卡测试代码，在部分机型上读取不到网卡连接速度的问题  20240116

 1.1.2   修改FIT IO 机种上 CPU风扇转速为最大转速，侦测风扇最高转速，系统风扇不变

 1.1.3   修改在部分主板上USB测试数量检测不到的bug，修改Lan测试代码，在双网卡机种上显示MAC ID重复问题    20240416

 1.1.4   修改USB 测试代码，上一版的程序测试会有几率USB3设备抓取为0.  修改网卡测试代码，For EB客供主板MAC ID无规律问题  20240925

 1.1.5   在Windows环境下，网卡的连接名称会发生变化。以至于在测试时，会无法确定名称不能测试。修改网络的测试方式，
        按MAC地址来确定网卡的连接名称

 1.1.6   优化内存测试和CPU测试代码

 1.1.7   优化PCIE网卡测试代码，取消使用Windows控制台命令枚举PCIE设置     25/3/10

 1.1.8   修正单网卡上传数据库一处bug    25/4/15

 1.1.9   修正整机测试上传数据库一处bug   25/4/29

 1.2.0   增加工单设定，上传数据库时，可记录工单号

 1.2.1   修复设置双网卡机种时，选择整机测试，数据库中无记录的bug    25/5/29

 1.2.2   增加扫码确认MAC ID号码的功能

 1.2.3   修正 两个网口时，测试数据库无记录的问题

 1.2.4   修复在加入随系统启动时，测试USB 接口数量抓取问题      25/10/28

 1.2.5   重编Config.ini 文件，以解决参数设置程序保存卡死的问题

 1.2.6   增加4个网卡的mac 地址抓取和上传服务器功能    251203

 1.2.7   增加CPU温度测试     260128

 1.2.8    修改一次bug，在不测试风扇时一处flag判断的问题

 1.2.9    修复主板BIOS读取为空的问题

 1.3.0    修复程序启动后，执行USB 程序错误的问题

 1.3.1    修复执行CPU温度有几率执行错误的问题   26/05/14

 1.3.2    修复 风扇转速读取时，有时读取是0的问题

 1.3.3    修改网络数据传输测试，适用iperf3 代码修改up down 数据 显示， 上传100MB/s  下载 850Mbits/s

1.3.4    增加25针打印机(LPT)端口收发数据测试：树形目录新增"打印机接口"项目及打印机图标，
        自动测试与右键菜单均可单独测试。发送与回收数据完全一致判定为PASS     261009

1.3.5    增加音频回路测试(参照 Realtek whdatest 工作方式)：
        输出接口 FRONT OUT / SURR OUT / CEN-LFE OUT，输入接口 MIC IN1(后置) / MIC IN2(前置) /
        LINE IN1 / LINE IN2。测试项：接口存在侦测、LOOPBACK 回路、L/R 左右声道互不干扰、
        MUTE 静音、THD+N 失真+噪声，每一项都能单独启用/禁用。
        四个接口数值可分别设置：PeriodPoint(0-10) / VolumeValue(0-87) / DataValue(0-32767) /
        THD+N(0-80)。HDMI/DP 数字输出按要求排除，不参与回路测试。
        治具按 L-L / R-R / GND 共地接法，最少各启用一个输入和输出接口。
        测试结束给 PASS/FAIL 并产生日志文件，记录每个接口的每个测试项的状况。
        树形目录新增"音频接口"项目及声卡图标，下挂"音频回路测试"。
        音频回路的接口勾选与四个数值由独立的参数设置程序
        AudioLoopParamSet.exe 设置（写 AudioLoopParam.ini），
        测试程序只读取，不再在测试程序里提供设置入口。

 }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, RzTreeVw, Vcl.ExtCtrls, System.IniFiles,
  RzPanel, RzButton, Vcl.StdCtrls, CnCheckTreeView, Winapi.ShellAPI,
  System.ImageList, Vcl.ImgList, Vcl.ShellAnimations, Vcl.Grids, RzGrids,
  RzCommon, WinSkinData, Vcl.Menus, Winapi.CommCtrl, RzListVw, RzLstBox,
  IdRawBase, IdRawClient, Data.DB, Data.Win.ADODB, IdIcmpClient,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdTime,
  Vcl.OleCtrls, MSCommLib_TLB,System.StrUtils,Winapi.ActiveX,
  IdCmdTCPClient, StandardDES,System.UITypes, Vcl.Samples.Spin, RzStatus,
  Vcl.Buttons, CnClasses, CnSkinMagic, CPort, CPortCtl, WinSkinStore,
  bsSkinData, System.Win.ComObj;

const WM_LOCATION = WM_USER + 8001;
      WM_BEGIN = WM_USER + 1;
type
  TForm2 = class(TForm)
    RzPanel1: TRzPanel;
    RzButton1: TRzButton;
    Button1: TButton;
    ImageList2: TImageList;
    RzPanel2: TRzPanel;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    TreeView1: TTreeView;
    RzToolbar1: TRzToolbar;
    ImageList1: TImageList;
    BtnExit: TRzToolButton;
    BtnHelp: TRzToolButton;
    ADOConnection1: TADOConnection;
    ADOQuery1: TADOQuery;
    ADOQuery2: TADOQuery;
    Memo1: TMemo;
    RzStatusBar1: TRzStatusBar;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    TSet_Time: TTimer;
    TFun_Test: TTimer;
    TCal_Time: TTimer;
    TConnDB: TTimer;
    TCheckResult: TTimer;
    RzStatusPane3: TRzStatusPane;
    Panel1: TPanel;
    RzStringGrid1: TRzStringGrid;
    RzFrameController1: TRzFrameController;
    Button2: TButton;
    Button3: TButton;
    TAudio_Check: TTimer;
    Timer1: TTimer;
    IdTime1: TIdTime;
    MSComm1: TMSComm;
    MSComm2: TMSComm;
    MSComm3: TMSComm;
    RzStatusPane4: TRzStatusPane;
    Timer2: TTimer;
    tmr_lan: TTimer;
    procedure RzButton1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RzStringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure TreeView1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TreeView1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MSComm1Comm(Sender: TObject);
    procedure TSet_TimeTimer(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure TFun_TestTimer(Sender: TObject);
    procedure TCal_TimeTimer(Sender: TObject);
    procedure BtnHelpClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TConnDBTimer(Sender: TObject);
    procedure RzStatusPane3DblClick(Sender: TObject);
    procedure TCheckResultTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TAudio_CheckTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MSComm2Comm(Sender: TObject);
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);
    procedure MSComm3Comm(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Test_lan;
    procedure tmr_lanTimer(Sender: TObject);
    //procedure SIM_Check;
  private
    { Private declarations }
    procedure SerialPortTest(Port : string; Factory : Word);overload;
    procedure SerialPortTest(APort : string; BPort : string; Factory : Word); overload;
    procedure tvToggleCheckbox(TreeView: TTreeView;Node: TTreeNode;isclick:boolean =false);
    procedure SetChecked(Node: TTreeNode; Checked: Boolean);
    function IsChecked(Node: TTreeNode): Boolean;
    procedure RefreshStrGrid;
    procedure setstrgrid(strGrid:TStringGrid);
    Procedure RefreshInfo(Var Msg:TMessage); Message WM_LOCATION;
     //procedure SetGridInfo(StrGrid:TStringGrid;sOraQuery:TADOQuery);
    function DataQuery(QueryStr:string):Integer;
    procedure ReadIniFiles;
    procedure SQLInsertData;  //在数据库记录数据，在DOS测试记录表中可以查询到数据时用
    procedure SQLInsertData1;  // 在数据库记录数据，在DOS测试记录表中查询不到数据时用
    procedure SQLInsert2Data;
    procedure SQLInsert2Data4;  // EB客户服务器用，4网络接口
    procedure SQLInsertData_Case;  //整机测试数据库操作
    function ADODBConn(Server_IP: String; User_Name : String; PassWord : string):Boolean;
    procedure SetLocalTime;    //设置系统时间
    procedure FunctionTest;    //所有功能测试
    procedure Final_Result;    //最终结果
    procedure Show_Form;
    procedure SaveIniFiles;
    procedure SendDate(MSComm : TMSComm); // 发送数据
    procedure ReceiveDate(MSComm : TMSComm); // 接收数据
    procedure sSuspend(modes: string);
    procedure sSuspend_Test(modes: string);
    procedure RTime;
    function GetBIOSInfoViaWMI: string;   // 获取主板BIOS Date信息
    procedure LptTest;                // 25针打印机端口收发测试
    procedure BuildPrinterTreeNodes;   // 在树形目录中动态添加打印机测试项目(含打印机图标)
    function  MakePrinterIcon: Integer; // 生成打印机图标并加入ImageList2，返回图标索引
    procedure AudioLoopTest;           // 音频回路测试(输出->输入 回路/THD+N/左右声道/静音)
    procedure BuildAudioLoopTreeNodes; // 在树形目录中动态添加音频回路测试项目(含图标)
    function  MakeAudioIcon: Integer;   // 生成声卡图标并加入ImageList2，返回图标索引
  public
    { Public declarations }
   USB_Result,USB2_Result,USB3_Result,Audio_Result,AudioExt_Result,PCI_Result,DISK_Result : string;
   LanMAC0_Result,LanMAC1_Result,LanMAC2_Result,LanMAC3_Result : string;
   Lan_Result,Lan1_Result,Lan2_Result,Lan3_Result : string;
   LanSend0_Result,LanSend1_Result,LanSend2_Result,LanSend3_Result : string;
   LanSpeed0_Result,LanSpeed1_Result,LanSpeed2_Result,LanSpeed3_Result : string;
   WIFI_Result,WiFi1_Result,CPU_Result,MEMN_Result,MEMS_Result : string;
   Time_Result,COM_Result,S3_Result, cTemp_Result : string;
   mac1_temp,mac2_temp,mac3_temp,mac4_temp,BIOS_Result,SIM_Result,DiskSpace_Result, S4_Result : string;
   cCpu_Result, FAN1_Result, FAN2_Result, FAN3_Result, Fan_Result, USB2_Num, USB3_Num : string;
   Fan1RPM, Fan2RPM, Fan3RPM : string;
   LPT_Result, LPT_Detail : string;   // 25针打印机端口测试结果
   AudioLoop_Result, AudioLoop_Detail : string;   // 音频回路测试结果
   AudioLoop_LogFile : string;         // 音频回路测试日志文件路径

 {  USB_Result,USB2_Result,USB3_Result,Audio_Result,AudioExt_Result,PCI_Result,DISK_Result : string;
   WIFI_Result,WiFi1_Result,CPU_Result,MEMN_Result,MEMS_Result,LanMAC_Result,LanMAC1_Result : string;
   Lan_Result,Lan1_Result,LanSend_Result,LanSend1_Result,LanSpeed_Result,LanSpeed1_Result,Time_Result,COM_Result,S3_Result : string;
   mac1_temp,mac2_temp,mac3_temp,mac4_temp,BIOS_Result,SIM_Result,DiskSpace_Result, S4_Result : string;
   FAN1_Result,FAN2_Result,FAN3_Result, Fan_Result, USB2_Num, USB3_Num : string;
  }
  end;

var
  Form2: TForm2;

  ID,ID1,ID2,ID3,ID4,ID5,ID6,ID7,ID8,ID9,ID10,ID11,ID12,ID13,ID14,ID15 : DWORD;
  CriticalSection: TRTLCriticalSection;
  Flag,Source_Len,HW_Flag : Word;
  THread1,Thread2,Thread3,Thread4,Thread5,Thread6,Thread7,Thread8,Thread9 : DWORD;
  THread10,THread11,THread12,Thread13,Thread14,Thread15,Thread16 : DWORD;
  mList1 : TStringList;  // 用来保存扫描的MAC ID
  Lan_Num, mFlag : Word;

implementation

{$R *.dfm}


uses
  USB,Audio,Lan,CPU,Disk,PCI,MEM,WiFi,HW,RunPg,Test_Result,Test_Result1,fail_pro,About1,ReadBios,
  Show_MAC, Check_Sim, LPT,
  AudioLoopCfg, AudioLoopAnaly, AudioLoopDev, AudioLoopTest, FrmAudioLoopCfg;

const
  TVIS_CHECKED = $2000;
  Source : string = '123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  E30_info : string = 'BIOS Date: 04/06/22 09:34:26 Ver: 05.0000C';     //CB310A18
  E30_info1 : string = 'BIOS Date: 04/06/22 09:34:26 Ver: 05.0000C';
var
   Item : string;
   Test_Flag,USB2_Flag,USB3_Flag,CPU_Flag,Time_Flag,LanSend_Flag,LanMac_Flag,Fan_Flag,LanSpeed_Flag,DiskSpace_Flag : Integer;
   USB2,USB3,BUS_Num,DB_Check,C_Type : Word;
   CPU_Name,PCI1,PCI2,PCI3,MAC_Addr,Serial_Port,Serial_Port2,WiFi_Name : string;
   Disk_Num,Disk_Flag,PCI_Num,SPK_Flag,PCI_Flag,Audio_Flag : Word;
   Lan_Flag,Auto_Run,Shut_down,Serial_Flag,Serial_Fac : Word;
   FinalRe,Test_Num,LNo,Speed1,Speed2,O_Time,Wan_Flag : Word;
   Conn1,Conn2,Server_IP,User_Name,DB_Psd,DB_Psd1,Opt,SIM_Name : String;
  LPT_Port : String;   // 25针打印机端口名，如 LPT1
   Conn_Num,BIOS_Date_Flag,Sim_Flag,WiFi_Conn : Word;
   MemN_Flag,MemS_Flag,Mem_N,WiFi_Flag,WiFi_Qualt,S3_Flag, S4_Flag : Word;
   gd_temp,BIOS_Date, DiskSpace, IO_TYPE : string;
   Result_Temp,zTime,Test,Test_Type, PCBA_TYPE, MEM_S : integer;
   Fan1min, Fan1Max, Fan2min, Fan2Max, Fan3min, Fan3Max : Integer;
   Fan1_Flag, Fan2_Flag, Fan3_Flag, Sus_Flag, Sus1_Flag : Word;
   T1_Out, T2_Out : Word; // 两个COM口对传数据，处理标志，为1时为PASS， 为0时FAIL
   Ctemp_flag ,cTemp_Min, cTemp_Max, Test_Mode : Word;  // 测试模式，0为普通PCBA或者整机测试   1为 服务器测试，2张以上的网卡
   LPT_Flag, LPT_Len, LPT_Timeout, LPT_Invert : Word;   // 25针打印机端口测试参数
   AudioLoop_Flag : Word;         // 音频回路测试：0=启用该项测试，非0=跳过
   FAutoTestRunning : Boolean;    // 自动测试进行中：True 时音频回路测试不弹框

//功能测试

procedure TAudioI_Test;stdcall;
begin
    Audio_Test;
end;

procedure TCtemp_Test;stdcall;
begin
// cpu 温度
  if Ctemp_Flag = 0 then
    GetCPU_Temp(cTemp_Min, cTemp_Max)
    else
      Test_Project_Demo1.Form2.cCpu_Result := '未测试';
end;

procedure TAudioExt_Test;stdcall;
begin
    AudioExt_Test;
end;

procedure TWIFITest;stdcall;
begin
    WIFI_Connect(WiFi_Name,WiFi_Qualt,O_Time);
end;

procedure TWIFI_Con;stdcall;
begin
  //WIFI_Connect(WiFi_Name);
end;

procedure TDiskTest;stdcall;
begin
    DiskTest(Disk_Num);
end;

procedure TDiskSpaceTest;stdcall;
begin
    DiskSpace_Test(DiskSpace);
end;

procedure TCPUTest;stdcall;
begin
    CPUTest(CPU_Name);
end;

procedure TPCITest;stdcall;
begin
   PCITest(PCI1,PCI2,PCI3,PCI_Num);
end;

procedure TUSBTest;stdcall;
begin
   // USBTest(USB2,USB3,USB2_Flag,USB3_Flag);
end;

procedure TFanTest;stdcall;
begin
    InitializeWinIo;
     if Fan1_Flag = 0 then
        FanControl(Fan1min,Fan1Max,IO_TYPE,'CPU_FAN')
        else
            Test_Project_Demo1.Form2.Fan1_Result := '未测试';
     if Fan2_Flag = 0 then
        begin
          SLEEp(500);
          FanControl(Fan2min,Fan2Max,IO_TYPE,'SYS_FAN1');
        end
        else
            Test_Project_Demo1.Form2.Fan2_Result := '未测试';

     if Fan3_Flag = 0 then
        begin
          SLEEp(500);
          FanControl(Fan3min,Fan3Max,IO_TYPE,'SYS_FAN2');
        end
        else
            Test_Project_Demo1.Form2.Fan3_Result := '未测试';
end;

procedure TCheckBios;stdcall;
begin
  CheckBIOS(BIOS_Date);
end;

procedure TLanTest;stdcall;
begin
  //MessageBox(0,PChar('Enter TLanTest'),PChar('TlanTest'),MB_OK);
      if Lan_Num >= 2  then
      begin
        SetEnvPath('Conn1',Conn1);
        SetEnvPath('Conn2',Conn2);
        //MessageBox(0,PChar('Enter TLanTest1'),PChar('TlanTest'),MB_OK);
        NetConnectTest(PCBA_TYPE, MAC_Addr,Server_IP,Speed1,Speed2,Lan_Num,O_Time,Test_Type);
      end
      else if Lan_Num = 1 then
      begin
        SetEnvPath('Conn1',Conn1);
        NetConnectTest(PCBA_TYPE,MAC_Addr,Server_IP,Speed1,Speed2,Lan_Num,O_Time,Test_Type);
        Test_Project_Demo1.Form2.Lansend1_Result := '未测试';
        Test_Project_Demo1.Form2.LanMAC1_Result := '未测试';
        Test_Project_Demo1.Form2.Lan1_Result := '未测试';
        Test_Project_Demo1.Form2.LanSpeed1_Result := '未测试';
      end;

end;


procedure TMEMTest;stdcall;
begin
  if MemN_Flag = 0 then
    MemN_Test(Mem_N)
    else
     Test_Project_demo1.Form2.MEMN_Result := '未测试';
  if MemS_Flag = 0 then
    MemS_Test(Mem_S)
    else
     Test_Project_demo1.Form2.MEMS_Result := '未测试';
end;

//SIM 卡检测
procedure SIM_Check;stdcall;
begin
     Read_Sim(SIM_Name);
end;

procedure TForm2.RefreshInfo(var Msg: TMessage);
begin
  RefreshStrGrid;
end;


procedure TForm2.setstrgrid(strGrid:TStringGrid);
Var
   i,j:integer;
begin
   with strGrid do
   begin
     for i:=fixedrows to rowcount-1 do
       for j:=FixedCols  to colcount-1 do
         cells[j,i]:='';
   end;
end;

procedure TForm2.RefreshStrGrid;
begin
  try
    Screen.Cursor := crSqlWait;
    setstrGrid(RzStringGrid1);
    RzStringGrid1.RowCount := 2;
    if RzStringGrid1.RowCount > 2 then RzStringGrid1.RowCount := RzStringGrid1.RowCount - 1;
  finally
    Screen.Cursor := crDefault;
  end;
end;


procedure TForm2.BtnExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm2.BtnHelpClick(Sender: TObject);
begin
  //ShowMessage('主板通用测试程序Beta,版本Ver: 0.0.1');
  Application.CreateForm(TAboutBox, AboutBox);
  AboutBox.Show;

end;

procedure TForm2.Button1Click(Sender: TObject);
//var
   //Node: TTreeNode;
   //TVI: TTVItem;
begin
   {for Node in TreeView1.Items do
   begin
     TVI.mask := TVIF_STATE;
     TVI.hItem := Node.ItemId;
     TreeView_GetItem(TreeView1.Handle, TVI);
     if TVI.state and $2000 = $2000 then
       ShowMessage(Node.Text);
   end;
   SendMessage(Form2.handle,WM_LOCATION,0,0) }
   //ShowMessage(mac1_temp);
   //MessageBox(0,'信息','警告',MB_OK);

end;

procedure TForm2.Button2Click(Sender: TObject);
//var
  //MyNode1,MyNode2,MyNode3 : TTreeNode;
  //FileName,FileName1,strTemp,tmpItem,imgItem : string;
  //j,i,k,n : Integer;
  //iniFile : TIniFile;
  //ITEM_Number,iUnit_Index,iMage_Index,Image_Num : Integer;
begin
    {FileName := ExtractFilePath(ParamStr(0)) + 'Config.ini';
    iniFile := TIniFile.Create(FileName);
    ITEM_Number := iniFile.ReadInteger('ITEM_HEADER','ITEM_NUM',0);
    //ShowMessage(IntToStr(ITEM_Number));
    MyNode1 := TreeView2.Items.Add(nil,'ALL_TEST_ITEM');
    //MyNode1.ImageIndex := 0;
    n := 0;
    for I := 1 to ITEM_Number do  //创建Tree所有项目,总项目数是ITEM_Number
    begin
      //遍历配置文件中所有 ITEM_NAME项，将其添加到 Treeview中
      with TreeView2.Items do
      begin
       tmpItem := iniFile.ReadString('Test_ITEM_' + IntToStr(i),'ITEM_NAME','');   //读取项目名称
       iUnit_Index := iniFile.ReadInteger('Test_ITEM_' + IntToStr(i),'UNIT_NUM',0); //读取该项目的测试数目
       MyNode2 := AddChild(MyNode1,tmpItem);
       for j := 1 to iUnit_Index do
       begin
         strTemp := iniFile.ReadString('Test_ITEM_' + IntToStr(i),'UNIT_NAME_' + IntToStr(j),'');
         AddChild(MyNode2,strTemp);
       end;
      end;
    end;
    for I := 0 to TreeView2.Items.Count - 1 do  //创建CheckTree所有项目
    begin
        TreeView2.Items[i].ImageIndex := n;
        TreeView2.Items[i].SelectedIndex := n;
        Inc(n);
    end;
    for I := 0 to TreeView2.Items.Count - 1 do  //创建CheckTree所有项目
    begin
      for j := 1 to ITEM_Number do
      begin
         iUnit_Index := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'UNIT_NUM',1);
         //ShowMessage(strTemp);
         Image_Num := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'IMAGE_NUM',0);
         for n := 1 to Image_Num do
         begin
             for k := 1 to iUnit_Index do
             begin
               strTemp := iniFile.ReadString('Test_ITEM_' + IntToStr(j),'UNIT_NAME_' + IntToStr(k),'');
               Test_Flag := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'Enabled_' + IntToStr(k),0);
               if TreeView2.Items[i].Level = 2 then
                begin
                   if (TreeView2.Items[i].Text = strTemp) then begin
                      if ( Test_Flag = 0) then
                      begin
                       //ShowMessage(TreeView1.Items[i].Text);
                        SetChecked(TreeView2.Items[i],True);
                      end
                      else if ( Test_Flag = 1) then
                      begin
                        SetChecked(TreeView2.Items[i],False);
                        TreeView2.Items[i].ImageIndex := 30;
                        TreeView2.Items[i].SelectedIndex := 30;
                      end;
                   end;
                end;
             end;
         end;
      end;
    end;
    TreeView2.TopItem := TreeView2.Items.GetFirstNode;  }
end;

procedure TForm2.Button3Click(Sender: TObject);
//var
//  j : Integer;
  //MyNode1,MyNode2 : TTreeNode;
  //FileName,FileName1,strTemp,tmpItem : string;
  //j,i,k,n : Integer;
  //iniFile : TIniFile;
  //ITEM_Number,iUnit_Index : Integer;
begin
   //ComPort1.Port := 'COM4';
   //ComSend;

    {FileName := ExtractFilePath(ParamStr(0)) + 'Config.ini';
    iniFile := TIniFile.Create(FileName);
    ITEM_Number := iniFile.ReadInteger('ITEM_HEADER','ITEM_NUM',0);
  for I := 0 to TreeView2.Items.Count - 1 do  //创建CheckTree所有项目
    begin
      for j := 1 to ITEM_Number do
      begin
       iUnit_Index := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'UNIT_NUM',1);
       //ShowMessage(strTemp);
       for k := 1 to iUnit_Index do
       begin
         strTemp := iniFile.ReadString('Test_ITEM_' + IntToStr(j),'UNIT_NAME_' + IntToStr(k),'');
         Test_Flag := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'Enabled_' + IntToStr(k),0);
         if TreeView2.Items[i].Level = 2 then
          begin
             if (TreeView2.Items[i].Text = strTemp) then begin
              if ( Test_Flag = 0) then
              begin
               //ShowMessage(TreeView1.Items[i].Text);
                SetChecked(TreeView2.Items[i],True);
              end
              else if ( Test_Flag = 1) then
              begin
                SetChecked(TreeView2.Items[i],False);
                TreeView2.Items[i].ImageIndex := 26;
                TreeView2.Items[i].SelectedIndex := 26;
              end;
             end;
          end;
       end;
      end;
    end;   }
end;

procedure TForm2.ComPort1RxChar(Sender: TObject; Count: Integer);
//var
//  rStr : string;
//  j : Integer;
begin
 { ComPort1.ReadStr(rStr, Count);
  Memo1.Text := Memo1.Text + rStr;

  if CompareStr(Source,Memo1.Text) = 0 then
  begin
  for j := 0 to RzStringGrid1.RowCount - 1 do
        begin
          if RzStringGrid1.Cells[0,j] = '' then
          begin
             //ShowMessage(RzStringGrid1.Cells[1,j]);
               RzStringGrid1.Cells[0,j] :=  'COM测试';
               RzStringGrid1.Cells[1,j] := 'COM端口: '+ ComPort1.Port + ' 测试正常';
               RzStringGrid1.Cells[2,j] := 'PASS';
               RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
               RzStringGrid1.Row := RzStringGrid1.Row + 1;
               RzStringGrid1.Update;
          end;
        end;
  //ShowMessage(rStr);

  end;    }
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //FileName := ExtractFilePath(ParamStr(0)) + 'usbtest.txt';
  TCal_Time.Enabled := False;
  if MSComm1.PortOpen then MSComm1.PortOpen := False;
  ADOQuery1.Close;
  ADOConnection1.Close;
  Action := cafree;
  CloseHandle(Thread1);
  CloseHandle(Thread2);
  CloseHandle(Thread3);
  CloseHandle(Thread4);
  CloseHandle(Thread5);
  CloseHandle(Thread6);
  CloseHandle(Thread7);
  CloseHandle(Thread8);
  CloseHandle(Thread9);
  CloseHandle(Thread10);
  CloseHandle(Thread11);
  CloseHandle(Thread12);
  CloseHandle(Thread14);
  CloseHandle(Thread15);
  CloseHandle(Thread16);
  //if FileExists(FileName) then DeleteFile(FileName);

  ShellExecute(0,'open',PChar('cmd.exe'),PChar('/c del *.txt'),nil,0);

  mList1.Free;
  if Fan_Flag = 0 then
       ShutdownWinio;
end;

procedure TForm2.FormCreate(Sender: TObject);
VAR
  FileName1,FileName2,FileName3 : string;
  Time1 : Integer;
  List  : TStrings;
  publicCipherTextString1,plaintextStr1 : String;
begin
  FileName2 := ExtractFilePath(ParamStr(0)) + '0.d';
  FileName1 := ExtractFilePath(ParamStr(0)) + 'Config.ini';
  FileName3 := ExtractFilePath(ParamStr(0)) + 'Audio' + '\hdatest.cfg';
  //FileName4 := ExtractFilePath(ParamStr(0)) + 'USB.exe';
  //FileName5 := '/k dir UsbTreeView.exe -r:usbtest.txt';
  if FileExists('usbtest.txt') then DeleteFile('usbtest.txt');

  SetCurrentDir('C:\Test_Project');
  Conn_Num := 0;
  Source_Len := 0;
  //mac1_temp := '';
  //mac2_temp := '';
  mFlag := 0;
  List := TStringList.Create;
  try
     if not FileExists(FileName2) then begin
        MessageBox(0,'文件不存在','错误',MB_OK + MB_ICONSTOP);
        Application.Terminate;
     end;
     List.LoadFromFile(FileName2);
    try
      publicCipherTextString1 := List[0];
      plaintextStr1 := DecryStrHex(publicCipherTextString1,'111111222');
      //publicCipherTextString2 := List[1];
      //plaintextStr2 := DecryStrHex(publicCipherTextString2,'111111222');
      Time1 := FileAge(FileName1);
      //Time2 := FileAge(FileName3);
      if CompareStr(IntToStr(Time1),plaintextStr1) = 0 then
      begin
        ReadIniFiles;
        FinalRe := 2;

        //ShellExecute(Handle, 'open', PChar(FileName4), nil, nil, SW_HIDE);
        //ShellExecute(Handle, 'open', PChar('command.com'), PChar(FileName5), nil, SW_HIDE);
      end
      else
      begin
        Application.MessageBox('数据错误,程序退出','错误',MB_OK);
        Application.Terminate;
      end;
    except On E:Exception do
      begin
        Application.MessageBox(PChar(E.Message),'错误', MB_OK + MB_ICONSTOP);
        Application.Terminate;
      end;
    end;
  finally
    List.Destroy;
  end;
end;

procedure TForm2.FormResize(Sender: TObject);
var
   factor : Double;
begin
     factor := Width / RzStringGrid1.Width;
     with RzStringGrid1 do
     begin
       ColWidths[0] := Trunc(0.15*Rzstringgrid1.Width*factor);
       ColWidths[1] := Trunc(0.35*RzStringGrid1.Width*factor);
       ColWidths[2] := Trunc(0.09*RzStringGrid1.Width*factor);
       ColWidths[3] := Trunc(0.25*RzStringGrid1.Width*factor);
     end;
end;


procedure TForm2.FormShow(Sender: TObject);
VAR
  iniFile : TiniFile;
  FileName, FileName1 : string;
  i,j,k : Integer;
  strTemp,str0 : string;
  iUnit_Index,ITEM_Number : Integer;
  //MyNode1,MyNode2 : TTreeNode;
begin
  SetWindowLong(TreeView1.Handle, GWL_STYLE, GetWindowLong(TreeView1.Handle, GWL_STYLE) or $00000100);
  //SetWindowLong(TreeView2.Handle, GWL_STYLE, GetWindowLong(TreeView1.Handle, GWL_STYLE) or $00000100);
  str0 := '/c netsh wlan show networks';
  HW_Flag := 1;
  BuildPrinterTreeNodes;      // 补上打印机测试节点（要在按ini 匹配勾选状态之前）
  BuildAudioLoopTreeNodes;    // 补上音频回路测试节点（同样要在按ini 匹配勾选状态之前）
  TreeView1.Items[0].Expand(True);
  TreeView1.RightClickSelect := True;
  Item := '';
  zTime := 0;
  Test := 0;
  mList1 := TStringList.Create;
  RzStringGrid1.Cells[0,0] := '测试项目';
  RzStringGrid1.Cells[1,0] := '测试信息';
  RzStringGrid1.Cells[2,0] := '测试结果';
  RzStringGrid1.Cells[3,0] := '其他信息';
  RzStringGrid1.ColWidths[0] := 190;
  RzStringGrid1.ColWidths[1] := 380;
  RzStringGrid1.ColWidths[2] := 120;
  RzStringGrid1.ColWidths[3] := 280;
    FileName1 := ExtractFilePath(ParamStr(0)) + 'usbtest.txt';
    if FileExists(FileName1) then DeleteFile(FileName1);

    FileName := ExtractFilePath(ParamStr(0)) + 'Config.ini';
    iniFile := TIniFile.Create(FileName);
    ITEM_Number := iniFile.ReadInteger('ITEM_HEADER','ITEM_NUM',0);

    SaveIniFiles;

    if WiFi_Flag = 0 then
    begin
      ShellExecute(0,'open','cmd.exe',PChar(str0),nil,HIDE_WINDOW);
    end;
    //ShowMessage(IntToStr(ITEM_Number));
    //MyNode1 := CnCheckTreeView1.Items.AddFirst(nil,'ALL_TEST_ITEM');
    //MyNode1.ImageIndex := 0;
  try
    for I := 0 to TreeView1.Items.Count - 1 do  //创建CheckTree所有项目
    begin
      for j := 1 to ITEM_Number do
      begin
       iUnit_Index := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'UNIT_NUM',1);
       //ShowMessage(strTemp);
       for k := 1 to iUnit_Index do
       begin
         strTemp := iniFile.ReadString('Test_ITEM_' + IntToStr(j),'UNIT_NAME_' + IntToStr(k),'');
         Test_Flag := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'Enabled_' + IntToStr(k),0);
          if TreeView1.Items[i].Level = 2 then
          begin
             if (TreeView1.Items[i].Text = strTemp) then begin
              if ( Test_Flag = 0) then
              begin
               //ShowMessage(TreeView1.Items[i].Text);
                SetChecked(TreeView1.Items[i],True);
              end
              else if ( Test_Flag = 1) then
              begin
                SetChecked(TreeView1.Items[i],False);
                TreeView1.Items[i].ImageIndex := 26;
                TreeView1.Items[i].SelectedIndex := 26;
              end;
             end;
          end;
       end;
      end;
    end;
    TreeView1.TopItem := TreeView1.Items.GetFirstNode;
    if DB_Check = 0 then  begin
       TConnDB.Enabled := True;
    end;
    {    // 这一部分代码只是用于EB产品。核对BIOS版本用
      if (CompareText(Trim(GetBIOSInfoViaWMI),E30_info) <> 0) or (CompareText(Trim(GetBIOSInfoViaWMI),E30_info1) <> 0 ) then
    begin
     if (FinalRe = 2) and (Auto_Run = 0) then
       FunctionTest;
    end
    else
    begin
      MessageBox(0,PChar('测试程序不匹配'),PChar('程序错误'),MB_OK + MB_ICONSTOP);
      Application.Terminate;
    end;
    }
      // 其他产品不核对 直接启动即可
     if (FinalRe = 2) and (Auto_Run = 0) then
       FunctionTest;

  finally
    iniFile.Destroy;
  end;
end;

procedure TForm2.RzButton1Click(Sender: TObject);
VAR
  iniFile : TiniFile;
  FileName : string;
  i,j,k : Integer;
  strTemp : string;
  iUnit_Index,ITEM_Number : Integer;
  //MyNode1,MyNode2 : TTreeNode;
begin

    FileName := ExtractFilePath(ParamStr(0)) + 'Config.ini';
    iniFile := TIniFile.Create(FileName);
    ITEM_Number := iniFile.ReadInteger('ITEM_HEADER','ITEM_NUM',0);
  try
    for I := 0 to TreeView1.Items.Count - 1 do  //创建CheckTree所有项目
    begin
      for j := 1 to ITEM_Number do
      begin
       iUnit_Index := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'UNIT_NUM',1);
       //ShowMessage(strTemp);
       for k := 1 to iUnit_Index do
       begin
         strTemp := iniFile.ReadString('Test_ITEM_' + IntToStr(j),'UNIT_NAME_' + IntToStr(k),'');
         Test_Flag := iniFile.ReadInteger('Test_ITEM_' + IntToStr(j),'Enabled_' + IntToStr(k),0);
         if TreeView1.Items[i].Level = 2 then
          begin
             if (TreeView1.Items[i].Text = strTemp) and ( Test_Flag = 0) then
             begin
               if TreeView1.Items[i].StateIndex = 1 then
                TreeView1.Items[i].StateIndex := 2;
             end;
          end;
       end;
      end;
    end;
  finally
    iniFile.Destroy;
  end;
end;

procedure TForm2.RzStatusPane3DblClick(Sender: TObject);
begin
   TConnDB.Enabled := True;
end;

procedure TForm2.RzStringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
str: String;
R: TRect;
begin
  with RzStringGrid1 do
  begin
    //Canvas.FillRect(Rect);
    //Canvas.Font.Size := 12;
    Canvas.Font.Color := clblue;
    Canvas.Pen.Color := clTeal;
    //Canvas.Pen.Width := 1;
    //Canvas.Brush.Style := bsClear;

    if   ARow=0 then
    begin
      Canvas.Font.Color := clBlack;
      Canvas.Font.Size := 16;
    end;
    if   ACol=0 then Canvas.Font.Color := clBlack;
      Canvas.Font.Size := 14;
    if Cells[ACol,ARow] = 'FAIL' then //找到内容为'变色'的单元格然后进行设置
    begin
      Canvas.Font.Color := clRed; //字体颜色
      //Canvas.Brush.color:=clMoneyGreen; //背景颜色
      Canvas.FillRect(Rect);
      Canvas.TextOut(Rect.Left+1,Rect.Top+1,Cells[ACol,ARow]);
    end;
    //
    //Canvas.FillRect(CellRect(ACol,ARow));
    Canvas.MoveTo(Rect.Left+1,Rect.Top);
    Canvas.LineTo(Rect.Right+1,Rect.Bottom);
    Canvas.Rectangle(CellRect(ACol,ARow));
    Str := Cells[ACol,ARow];
    R := Rect;
    DrawText(Canvas.Handle,PChar(Str),Length(Str),r,DT_CENTER or DT_SINGLELINE or DT_VCENTER); //文字居中

  end;
  {
  with DrawGrid1 do
  begin
    sText := CellRect[ACol,ARow];
    if sText <> '' then
    begin
      Canvas.FillRect(Rect);
      DrawText(Canvas.Handle,PChar(sText),Length(sText),Rect,DT_CENTER);
    end;
    if gdFocused in State then begin //同意camel_luo//我来加一条
      Rect.Left := Rect.Left + 1;
      Rect.Top := Rect.Top + 1;
      Rect.Right := Rect.Right - 1;
      Rect.Bottom := Rect.Bottom - 1;
      Canvas.DrawFocusRect(Rect);
    end;

  end;
end;}
 {var
CellString:string;
begin
  if ARow<RzStringgrid1.FixedRows then                //字体居中,抬头部分居中
    begin
       CellString:=RzStringgrid1.Cells[ACol,ARow];
       RzStringgrid1.Canvas.TextRect(rect,rect.Left+(rect.Right-rect.Left-Rzstringgrid1.Canvas.TextWidth(CellString)) div 2,rect.Top+(rect.Bottom-rect.Top-RzStringgrid1.Canvas.TextHeight(CellString)) div 2,CellString);
    end; }
end;

//检查某个节点是否被 选中
function TForm2.IsChecked(Node: TTreeNode): Boolean;
var
TvItem :TTVItem;
begin
  TvItem.Mask := TVIF_STATE;
  TvItem.hItem := Node.ItemId;
  TreeView_GetItem(Node.TreeView.Handle, TvItem);
  Result := (TvItem.State and TVIS_CHECKED) = TVIS_CHECKED;
end;

//右键测试项
procedure TForm2.N1Click(Sender: TObject);
begin
  if Item = 'USB2.0接口测试' then begin
    if Test < 3 then  begin
      if USB2_Flag = 0 then begin
         USB2Test(USB2);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = 'USB3.0接口测试' then begin
    if Test < 3 then begin
      if USB3_Flag = 0 then
      begin
        USB3Test(USB3);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = 'CPU名称测试' then  begin
      if Test < 3 then begin
        if CPU_Flag = 0 then begin
          CPUTest(CPU_Name);
          Test := Test + 1;
        end;
      end;
    end;

  if Item = 'PCI设备测试' then begin
    if Test < 3 then begin
       if PCI_Flag = 0 then begin
         PCITEST(PCI1,PCI2,PCI3,PCI_Num);
         Test := Test + 1;
      end;
    end;
  end;

  if Item = '磁盘个数测试' then  begin
    if Test < 3 then begin
      if Disk_Flag =0 then begin
        DiskTest(Disk_Num);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '磁盘容量测试' then  begin
    if Test < 3 then begin
      if Disk_Flag =0 then begin
        DiskSpace_Test(DiskSpace);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '板载音频测试' then begin
    if Test < 3 then begin
      if Audio_Flag = 0 then begin
         Audio_Test;
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '外接喇叭测试' then begin
    if Test < 3 then begin
      if SPK_Flag = 0 then begin
         AudioEXT_Test;
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '系统时间校正' then begin
    if Time_Flag = 0 then
    begin
      if Test < 3 then begin
        SetLocalTime;
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '数据传输测试' then begin
    if Lan_Flag = 0 then
    begin
        if Test < 3 then begin
          NetConnectTest(Conn1,MAC_Addr,Server_IP,Speed1);
          Test := Test + 1;
        end;
    end;
  end;

  if Item = 'MAC地址测试' then begin
    if Lan_Flag = 0 then
    begin
      if Test < 3 then begin
        GetMacAddr(MAC_Addr);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '网络速度测试' then
  begin
    if Lan_Flag = 0 then
    begin
      if Test < 3 then begin
        SPEED_CONN(Conn1,Speed1);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = 'COM接口测试' then begin
    if Test < 3 then begin
      if Serial_Flag = 0 then begin
        case Serial_Fac of
          0: SerialPortTest(Serial_Port,Serial_Fac);
          1: SerialPortTest(Serial_Port2,Serial_Fac);
          2: SerialPortTest(Serial_Port2,Serial_Fac);
          3: SerialPortTest(Serial_Port,Serial_Port2,Serial_Fac);
          4: SerialPortTest(Serial_Port,Serial_Port2,Serial_Fac);
        end;

        Test := Test + 1;
      end;
    end;
  end;

  if Item = '内存条数测试' then begin
    if Test < 3 then begin
      if MemN_Flag = 0 then begin
        MemN_Test(Mem_N);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '内存容量测试' then
  begin
    if Test < 3 then begin
      if MemS_Flag = 0 then begin
        MemS_Test(Mem_S);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '无线信号强度' then begin
    if Test < 3 then begin
      if WiFi_Flag = 0 then begin
        WIFI_Connect(WiFi_Name,WiFi_Qualt,o_time);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = 'CPU温度测试' then begin
    if Test < 3 then begin
      if Cpu_Flag = 0 then  begin
        GetCPU_Temp(cTemp_Min,cTemp_Max);
        Test := Test + 1;
        end;
    end;
  end;

  if Item = '风扇测试' then begin
    if Test < 3 then begin
      if Fan1_Flag = 0 then  begin
        FanControl(Fan1min,Fan1Max,IO_TYPE,'CPU_FAN');
        Test := Test + 1;
        end;

     if Fan2_Flag = 0  then begin
        FanControl(Fan2min,Fan2Max,IO_TYPE,'SYS_FAN1');
        Test := Test + 1;
        end;

     if Fan3_Flag = 0  then begin
        FanControl(Fan2min,Fan2Max,IO_TYPE,'SYS_FAN2');
        Test := Test + 1;
        end;
    end;
  end;

  if Item = 'BIOS日期' then begin
    if Test < 3 then begin
      if BIOS_Date_Flag = 0 then begin
        CheckBIOS(BIOS_Date);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = 'SIM卡检测' then begin
    if Test < 3 then begin
      if Sim_Flag = 0 then begin
        Read_Sim(SIM_Name);
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '25针打印机端口测试' then begin
    if Test < 3 then begin
      if LPT_Flag = 0 then begin
        LptTest;
        Test := Test + 1;
      end;
    end;
  end;

  if Item = '音频回路测试' then begin
    if Test < 3 then begin
      if AudioLoop_Flag = 0 then begin
        AudioLoopTest;
        Test := Test + 1;
      end;
    end;
  end;
end;


//让 某个节点被 选中
procedure TForm2.SetChecked(Node: TTreeNode; Checked: Boolean);
var
TvItem :TTVItem;
begin
  FillChar(TvItem, SizeOf(TvItem), 0);
  with TvItem do begin
    hItem := Node.ItemId;
    Mask := TVIF_STATE;
    StateMask := TVIS_STATEIMAGEMASK;
  if Checked then
    TvItem.State :=TVIS_CHECKED
  else
    TvItem.State :=TVIS_CHECKED shr 1;
    TreeView_SetItem(Node.TreeView.Handle, TvItem);
  end;
end;


// 对节点中所有 子节点 都 选中或 未选中 状态
procedure TForm2.tvToggleCheckbox(TreeView: TTreeView; Node: TTreeNode; isclick :boolean=false);
var
  CurNode, ParentNode, GrandSonNode,sonNode: TTreeNode;
  flg1: boolean;
begin
  CurNode :=node;
  with TreeView do begin
  if IsChecked(CurNode) then //
  begin
    sonNode := CurNode.GetFirstChild; //遍历子树,选中 则子节点 全部 为选中；
    while sonNode<>nil do
    begin
    SetChecked(sonNode, true);
    tvToggleCheckbox(TreeView,sonNode,true);
    sonNode := sonNode.GetNextSibling;
    end;

    ParentNode:= CurNode.Parent; //父；
    if ParentNode<>nil then
    begin
    if not isChecked(parentNode) then begin
      GrandSonNode := ParentNode.GetFirstChild; //遍历子树；
      flg1 := false;
      while GrandSonNode<>nil do
      begin
      if (not IsChecked(GrandSonNode)) then //true,有未选中
        flg1 := true;
      if flg1 then //已有、退出loop;
        GrandSonNode := nil
      else
        GrandSonNode := GrandSonNode.GetNextSibling;
      end;
        SetChecked(ParentNode, not flg1);
        tvToggleCheckbox(TreeView,ParentNode,false);
      end;
    end; // end parentNode 不等于空
  end
  else if not IsChecked(CurNode) then
  begin
      ParentNode := CurNode.Parent; //父；
      if ParentNode<>nil then
      begin
        if isChecked(parentNode) then begin
          SetChecked(ParentNode, false);
          tvToggleCheckbox(TreeView,ParentNode);
        end;
      end; //end parentnode

      if (isclick) then begin
        sonNode := CurNode.GetFirstChild; //遍历子树,未选中 则子节点 全部 为未选中；
        while sonNode<>nil do
        begin
          SetChecked(sonNode, false);
          tvToggleCheckbox(TreeView,sonNode,true);
          sonNode := sonNode.GetNextSibling;
        end;
      end;

  end;
  end;
end;

procedure TForm2.TSet_TimeTimer(Sender: TObject);
begin
    RzStatusPane2.Caption := '当前系统时间: ' + FormatDateTime('YYYY-MM-DD HH:NN:SS',now);
    RzStatusPane4.Caption := 'Ver: 1.3.3';
end;

{ ---------------- 25针打印机(LPT)端口测试 ---------------- }

// 画一个打印机图标(32x32)，加入ImageList2并返回索引
function TForm2.MakePrinterIcon: Integer;
var
  Bmp : TBitmap;
  PR : TRect;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Width := 32;
    Bmp.Height := 32;
    { 背景填充成淡灰，和其它图标风格一致
      注意：TCanvas.FillRect 只有 FillRect(const Rect: TRect) 一个重载，
      没有 FillRect(X1,Y1,X2,Y2)，必须包一层 Rect() }
    Bmp.Canvas.Brush.Style := bsSolid;
    Bmp.Canvas.Brush.Color := clBtnFace;
    Bmp.Canvas.FillRect(Rect(0, 0, 32, 32));

    { 上方进纸的纸 }
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.Pen.Color := clGray;
    Bmp.Canvas.Rectangle(10, 2, 21, 11);

    { 打印机机身 }
    Bmp.Canvas.Brush.Color := $00C0C0C0;
    Bmp.Canvas.Pen.Color := clBlack;
    PR := Rect(4, 10, 27, 23);
    Bmp.Canvas.Rectangle(PR.Left, PR.Top, PR.Right, PR.Bottom);

    { 出纸口 }
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.Rectangle(8, 19, 23, 21);

    { 底部输出的纸 }
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.Pen.Color := clGray;
    Bmp.Canvas.Rectangle(9, 22, 22, 29);

    { 指示灯 }
    Bmp.Canvas.Brush.Color := clGreen;
    Bmp.Canvas.Ellipse(24, 12, 26, 14);

    { Delphi 10 的 TImageList.Add 只有 Add(Image, Mask: TBitmap) 一个签名，
      第二个参数是掩码位图，必须传 nil，不能像新版那样传掩码颜色 }
    Result := ImageList2.Add(Bmp, nil);
  finally
    Bmp.Free;
  end;
end;

// 在树形目录里动态补出"打印机接口 / 25针打印机端口测试"两个节点
// dfm里的树节点是二进制流，不便手工插入，改为按父节点动态追加，
// 这样节点文本/图标都在代码里可见，后续维护不用去解二进制。
procedure TForm2.BuildPrinterTreeNodes;
var
  RootNode, GroupNode, ItemNode : TTreeNode;
  IconIdx : Integer;
  N : TTreeNode;
begin
  if TreeView1.Items.Count = 0 then Exit;
  RootNode := TreeView1.Items[0];

  { FormShow 可能被触发多次，这里按节点文本查重，避免重复添加 }
  N := TreeView1.Items.GetFirstNode;
  while N <> nil do
  begin
    if (N.Level = 1) and (N.Text = '打印机接口') then
      Exit;
    N := N.GetNextSibling;
  end;

  IconIdx := MakePrinterIcon;

  // 一级节点：打印机接口
  GroupNode := TreeView1.Items.AddChild(RootNode, '打印机接口');
  GroupNode.ImageIndex := IconIdx;
  GroupNode.SelectedIndex := IconIdx;

  // 二级节点：25针打印机端口测试（自动测试就是按 Level=2 匹配 ini 项的）
  ItemNode := TreeView1.Items.AddChild(GroupNode, '25针打印机端口测试');
  ItemNode.ImageIndex := IconIdx;
  ItemNode.SelectedIndex := IconIdx;

  // 让新节点在启动时处于勾选状态，与 ini 的 Enabled_1=0 保持一致
  SetChecked(ItemNode, True);
  GroupNode.Expanded := True;
end;

// 生成声卡图标(画一个声卡+音波)，加入 ImageList2 并返回索引。
{ 和 MakePrinterIcon 一样用 Canvas 画，不引额外资源，
  免得新增图片资源还得同步改 res。 }
function TForm2.MakeAudioIcon: Integer;
var
  Bmp : TBitmap;
  I   : Integer;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Width := 32;
    Bmp.Height := 32;
    { 背景透明，树形目录里看起来更干净
      FillRect 只能接受 TRect，不能用 4 个整数 }
    Bmp.Canvas.Brush.Style := bsClear;
    Bmp.Canvas.Brush.Color := clBtnFace;
    Bmp.Canvas.FillRect(Rect(0, 0, 32, 32));

    { 声卡主体 }
    Bmp.Canvas.Brush.Color := $00D8D0C8;
    Bmp.Canvas.Pen.Color := clBlack;
    Bmp.Canvas.Rectangle(3, 8, 28, 26);

    { 播放/录音孔位：小方块，代表 3 孔位 }
    Bmp.Canvas.Brush.Color := $00404040;
    Bmp.Canvas.Rectangle(7, 19, 11, 23);
    Bmp.Canvas.Rectangle(14, 19, 18, 23);
    Bmp.Canvas.Rectangle(21, 19, 25, 23);

    { 音波：表示声音信号 }
    Bmp.Canvas.Pen.Color := $00008000;
    for I := 0 to 4 do
      Bmp.Canvas.Polyline([Point(7 + I * 4, 13), Point(9 + I * 4, 13 - (I mod 2 + 1) * 2),
                           Point(11 + I * 4, 13)]);

    { Delphi 10 的 Add 需要两个 TBitmap 参数，掩码传 nil }
    Result := ImageList2.Add(Bmp, nil);
  finally
    Bmp.Free;
  end;
end;

// 在树形目录里动态补出"音频接口 / 音频回路测试"两个节点
{ 和打印机节点同样的做法：dfm 里 TreeView1 的节点是二进制流
  (Items.NodeData)，不便手工插入，改为运行时追加。 }
procedure TForm2.BuildAudioLoopTreeNodes;
var
  RootNode, GroupNode, ItemNode : TTreeNode;
  IconIdx : Integer;
  N : TTreeNode;
begin
  if TreeView1.Items.Count = 0 then Exit;
  RootNode := TreeView1.Items[0];

  { FormShow 可能被触发多次，这里按节点文本查重，避免重复添加 }
  N := TreeView1.Items.GetFirstNode;
  while N <> nil do
  begin
    if (N.Level = 1) and (N.Text = '音频接口') then
      Exit;
    N := N.GetNextSibling;
  end;

  IconIdx := MakeAudioIcon;

  { 一级节点：音频接口 }
  GroupNode := TreeView1.Items.AddChild(RootNode, '音频接口');
  GroupNode.ImageIndex := IconIdx;
  GroupNode.SelectedIndex := IconIdx;

  { 二级节点：音频回路测试(自动测试就是按 Level=2 匹配 ini 项的) }
  ItemNode := TreeView1.Items.AddChild(GroupNode, '音频回路测试');
  ItemNode.ImageIndex := IconIdx;
  ItemNode.SelectedIndex := IconIdx;

  { 这里不再挂「参数设置」节点 —— 参数设置已独立成
    AudioLoopParamSet.exe（参数设置程序），由操作员单独运行。
    测试程序只负责读 AudioLoopParam.ini 里的设置来跑测试，
    不再自己提供设置入口，避免两处设置打架。 }

  SetChecked(ItemNode, True);
  GroupNode.Expanded := True;
end;

// 执行打印机端口收发测试，并把结果写入结果表格
procedure TForm2.LptTest;
var
  Res : TLptTestResult;
  j : Integer;
begin
  if LPT_Flag <> 0 then
  begin
    LPT_Result := '未测试';
    LPT_Detail := '';
    Exit;
  end;

  LptRunTest(LPT_Port, LPT_Len, LPT_Timeout, LPT_Invert = 1, Res);

  LPT_Detail := Res.ErrorMsg;
  with RzStringGrid1 do
  begin
    for j := 0 to RowCount - 1 do
    begin
      if Cells[0, j] = '' then
      begin
        Cells[0, j] := '打印机端口测试';
        Cells[1, j] := Res.PortName + ' 端口 ' + Res.ErrorMsg;
        if Res.Passed then
          Cells[2, j] := 'PASS'
        else
          Cells[2, j] := 'FAIL';
        Cells[3, j] := Format('发送: %d 字节  回收: %d 字节  耗时: %d ms',
          [Res.SentBytes, Res.RecvBytes, Res.ElapsedMs]);
        RowCount := RowCount + 1;
        Row := Row + 1;
        Update;
        Break;
      end;
    end;
  end;

  if Res.Passed then
    LPT_Result := 'PASS'
  else
    LPT_Result := 'FAIL';
end;

// 后台线程入口，避免阻塞界面
procedure TLptTest;stdcall;
begin
  Test_Project_Demo1.Form2.LptTest;
end;

// ---------------- 音频回路测试 ----------------

{ 音频回路测试主体。
  走配置窗体：先把用户选好的端口/测试项/四个数值取过来，
  再调 AudioLoopTest 跑一遍，把逐项结果填进结果表格。

  这里不用后台线程：回路测试每项都要播信号再录音，本身是串行且耗时的，
  但它会操作界面上的日志/进度，必须在主线程跑（放到线程里就得跨线程
  同步 UI，比直接跑还麻烦）。耗时以 12 组配对 x 5 项计，
  正常在十几秒内完成。 }
procedure TForm2.AudioLoopTest;
var
  Cfg: TAlLoopConfig;
  Res: TAlLoopTestResult;
  LgCb: TAlLogCallback;
  StCb: TAlStepCallback;
  j: Integer;
  Why: string;
  Frm: TFrmAudioLoopCfg;
begin
  if AudioLoop_Flag <> 0 then
  begin
    AudioLoop_Result := '未测试';
    AudioLoop_Detail := '';
    Exit;
  end;

  { 参数从独立的参数设置程序(AudioLoopParamSet.exe)写的
    AudioLoopParam.ini 读。测试程序不再提供设置入口，
    也就不会再出现「两处设置打架」的情况。

    读不到就明确判 FAIL —— 不能默默退回窗体默认值：
    产线上参数没设置过不等于「参数就是默认值」，
    那样测出来的 PASS 没有依据，板子真坏了也会判合格。 }
  if not AlParamLoadFromFile(GetAudioLoopParamFile, Cfg, Why) then
  begin
    AudioLoop_Result := 'FAIL';
    AudioLoop_Detail := Why;
    with RzStringGrid1 do
    begin
      for j := 0 to RowCount - 1 do
        if Cells[0, j] = '' then
        begin
          Cells[0,j] := '音频回路测试';
          Cells[1,j] := '参数未设置';
          Cells[2,j] := 'FAIL';
          Cells[3,j] := Why;
          RowCount := RowCount + 1;
          Row := Row + 1;
          break;
        end;
    end;
    RzStringGrid1.Update;
    exit;
  end;

  Frm := TFrmAudioLoopCfg.Create(nil);
  try
    { 自动测试里跑就静默，不弹框；右键菜单手动跑时保持默认(弹框)，
      操作员能立刻看到结论。 }
    Frm.Silent := FAutoTestRunning;
    { 窗体只是跑测试的载体，参数以刚读进来的 ini 为准，
      不要用窗体里那套默认值覆盖回去。 }
    Frm.ConfigToForm(Cfg);

    LgCb := nil;
    StCb := nil;
    LgCb := Frm.OnTestLog;
    StCb := Frm.OnTestStep;

    if not AlRunLoopTest(Cfg, Frm.PEnv, GetLogDir, LgCb, StCb, Res) then
    begin
      { 引擎自己没能跑起来(没有模拟端点/没有配对/测试项全禁等)，
        原因写在 Summary 里，直接作为 FAIL 记。 }
      AudioLoop_Result := 'FAIL';
      AudioLoop_Detail := Res.Summary;
      AudioLoop_LogFile := Res.LogFile;
      exit;
    end;

    { 逐项结果写进表格：每一行是「哪个接口的哪个测试项」。

      按要求：只显示 PASS 和 FAIL，跳过的项(未执行)不进表格。
      跳过的原因写进日志文件即可 —— 表格是给产线看结论的，
      混着一堆 SKIP 会让人以为测试项没配好；真要追查
      「为什么这项没测」，看 AudioLoopLog 目录下的日志文件。

      注意：这里 continue 的是结果循环，不是外层的空行查找，
      所以必须把「找空行」整个重写一遍 —— 跳过一项后
      不能沿用上一次的 j。 }
    for j := 0 to Length(Res.Results) - 1 do
    begin
      { 跳过的项不显示，直接下一条 }
      if not Res.Results[j].Executed then
        Continue;

      with RzStringGrid1 do
      begin
        if Cells[0,j] = '' then
        begin
          Cells[0,j] := '音频回路测试';
          Cells[1,j] := AlOutPortName(Res.Results[j].OutPort) + '->' +
                        AlInPortName(Res.Results[j].InPort) + ' ' +
                        AlTestItemName(Res.Results[j].TestItem);
          if Res.Results[j].Passed then
            Cells[2,j] := 'PASS'
          else
            Cells[2,j] := 'FAIL';
          Cells[3,j] := Res.Results[j].Message;
          RowCount := RowCount + 1;
          Row := Row + 1;
        end;
      end;
    end;
    RzStringGrid1.Update;

    AudioLoop_Detail := Res.Summary;
    AudioLoop_LogFile := Res.LogFile;
    if Res.Passed then
      AudioLoop_Result := 'PASS'
    else
      AudioLoop_Result := 'FAIL';
  finally
    Frm.Free;
  end;
end;


procedure TForm2.Test_lan;
begin
   if mFlag = 1 then
   begin
      Thread10 := BeginThread(nil,0,@TLANTest,nil,0,ID9);
      tmr_lan.Enabled := False;
   end;
end;

procedure TForm2.TFun_TestTimer(Sender: TObject);
begin
  if TFun_Test.Enabled then TFun_Test.Enabled := False;
  { 置位后，下面各测试(含音频回路)都按"自动测试"处理：
    不弹模态框，结论只落结果表格/状态栏/日志文件。 }
  FAutoTestRunning := True;
  if Audio_Flag = 0 then
    //Audio_Test;
    Thread1 := BeginThread(nil,0,@Audio_Test,nil,0,ID);
  if SPK_Flag = 0 then
    //AudioEXT_Test;
    Thread2 := BeginThread(nil,0,@AudioEXT_Test,nil,0,ID1);
  if USB2_Flag = 0 then
    //USB2Test(USB2);
    Thread3 := BeginThread(nil,0,@TUSBTest,nil,0,ID2);
  if CPU_Flag = 0 then
    //CPUTest(CPU_Name);
    Thread5 := BeginThread(nil,0,@TCPUTest,nil,0,ID4);
  {if PCI_Flag = 0 then
    //PCITEST;
    Thread6 := BeginThread(nil,0,@TPCITest,nil,0,ID5);
  {if Disk_Flag =0 then
      //DiskTest(Disk_Num);
    Thread7 := BeginThread(nil,0,@TDiskTest,nil,0,ID6);}
  if Lan_Flag = 0 then begin
    SetLocalTime;
    //NetConnectTest(MAC_Addr,Server_IP,Speed1,Lan_Num,O_Time);
    {
      if not Assigned(Frm_showmac) then
    begin
      Frm_showmac:=TFrm_showmac.Create(nil);
      Frm_showmac.Show;
    end
    else
    begin
      Frm_showmac.Show;
    end;
     }
  end;

  if Serial_Flag = 0 then begin
    case Serial_Fac of
          0: SerialPortTest(Serial_Port,Serial_Fac);
          1: SerialPortTest(Serial_Port2,Serial_Fac);
          2: SerialPortTest(Serial_Port2,Serial_Fac);
          3: SerialPortTest(Serial_Port,Serial_Port2,Serial_Fac);
          4: SerialPortTest(Serial_Port,Serial_Port2,Serial_Fac);
    end;
  end;
  //  Thread8 := BeginThread(nil,0,@TMEMTest,nil,0,ID7);
  if WiFi_Flag = 0 then  begin
      Thread9 := BeginThread(nil,0,@TWIFITest,nil,0,ID8);
  end;
  if Fan_Flag = 0 then
  begin
   // InitializeWinio;
    Thread11 := BeginThread(nil,0,@TFanTest,nil,0,ID10);
  end;

  if BIOS_Date_Flag = 0 then
     Thread13 := BeginThread(nil,0,@TCheckBios,nil,0,ID12);
  if Sim_Flag = 0 then
     Read_Sim(SIM_Name);

  { 音频回路测试放最后，且不同步在线程里。
    两个原因：
      1) 它要往结果表格和状态栏写东西，跨线程碰 VCL 控件迟早出问题；
      2) 它要独占声卡(打开 waveOut/waveIn 发信号再录回来)，
         必须排在上面 Audio_Test / AudioEXT_Test 这两个用声卡的项之后，
         否则两路同时开声卡会互相抢设备、测出来的结果全是噪声。
    耗时正常在十几秒内，产线可以接受。 }
  if AudioLoop_Flag = 0 then
    AudioLoopTest;
end;

procedure TForm2.Timer1Timer(Sender: TObject);
begin
  TCheckResult.Interval := 1000;
  TCheckResult.Enabled := True;
  Timer1.Enabled := False;
end;

procedure TForm2.Timer2Timer(Sender: TObject);
begin
  ShowMessage( 'Audio_Result:' + Audio_Result + ' ;AudioExt_Result:' + AudioExt_Result + ' ;PCI_Result:' + PCI_Result + ' ;DISK_Result:' +
   Disk_Result + ' ;WIFI_Result:' + WIFI_Result +  ' ;WIFI1_Result:' + WIFI1_Result + ' ;CPU_Result:' + CPU_Result +
   ' ;FAN1_Result:' + FAN1_Result + ' ;MEMN_Result:' + MEMN_Result + ' ;MEMS_Result:' + MEMS_Result +
   ' ;LanMAC0_Result:' + LanMAC0_Result  + ' ;LanSend0_Result:' + LanSend0_Result + ' ;LanSpeed0_Result:' + LanSpeed0_Result +
   ' ;Time_Result:' + Time_Result + ' ;COM_Result:' + COM_Result + ' ;USB2_Result:' + USB2_Result + ' ;USB3_Result:' + USB3_Result +
   ' ;BIOS_Result:' + BIOS_Result + ' ;LanMAC1_Result:' + LanMAC1_Result + ' ;LanSend1_Result:' + LanSend1_Result +
   ' ;LanSpeed1_Result:;' + LanSpeed1_Result + ' ;SIM_Result:' + SIM_Result + ' ;DiskSpace_Result:' + DiskSpace_Result +
   ' ;FAN2_Result:' + FAN2_Result );
end;

procedure TForm2.tmr_lanTimer(Sender: TObject);
begin
  Test_lan;
end;

procedure TForm2.TConnDBTimer(Sender: TObject);
begin
   Inc(Conn_Num);

   if Conn_Num > 5 then
   begin
     TConnDB.Enabled := False;
     Exit;
   end
   else begin
      if DB_Check = 0 then begin
        if not ADOConnection1.Connected then begin
           Application.ProcessMessages;
           ADODBConn(Server_IP,User_Name,DB_Psd1);
        end
        else
          TConnDB.Enabled := False;
      end;
   end;
end;

procedure TForm2.TAudio_CheckTimer(Sender: TObject);
begin
    if AudioEXT_Result = 'PASS' then
    begin
        TAudio_Check.Enabled := False;
        if Audio_Flag = 0 then begin
          //Audio_Test;
          Application.MessageBox('外接喇叭测试完毕，移除治具后，换接音频治具', '注意', MB_OK +
            MB_ICONINFORMATION);
          Thread1 := BeginThread(nil,0,@TAudioI_Test,nil,0,ID);
        end
        else
          Audio_Result := '未测试';
    end;
end;

procedure TForm2.TCal_TimeTimer(Sender: TObject);
begin
  zTime := zTime + 1;
  RzStatusPane1.Caption := '测试时长: ' + IntToStr(zTime) + ' 秒';
end;


procedure TForm2.TCheckResultTimer(Sender: TObject);
begin
  Final_Result;
end;

procedure TForm2.TreeView1Click(Sender: TObject);
var
P:TPoint;
treenode :TTreeNode;
begin
  GetCursorPos(P);
  P := TreeView1.ScreenToClient(P);
  if (htOnStateIcon in TreeView1.GetHitTestInfoAt(P.X,P.Y)) then begin
    treenode := TreeView1.GetNodeAt(P.X,P.Y);
    tvToggleCheckbox(TreeView1,treenode ,true);
  end;
end;

procedure TForm2.TreeView1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var
    Node : TTreeNode;
begin
  if Button <> mbRight then Exit;
    node := TreeView1.GetNodeAt(X,Y);
  if Node <> nil then begin
      //PopupMenu1.Popup(P.X,P.Y);
      //TreeView1.Selected := Node;
      if TreeView1.Selected.Text = 'USB2.0接口测试' then
        Item := 'USB2.0接口测试';
      if TreeView1.Selected.Text = 'USB3.0接口测试' then
        Item := 'USB3.0接口测试';
      if TreeView1.Selected.Text = 'COM接口测试' then
        Item := 'COM接口测试';
      if TreeView1.Selected.Text = '磁盘测试' then
        Item := '磁盘测试';
      if TreeView1.Selected.Text = 'CPU名称测试' then
        Item := 'CPU名称测试';
      if TreeView1.Selected.Text = 'PCI设备测试' then
        Item := 'PCI设备测试';
      if TreeView1.Selected.Text = '板载音频测试' then
        Item := '板载音频测试';
      if TreeView1.Selected.Text = '外接喇叭测试' then
        Item := '外接喇叭测试';
      if TreeView1.Selected.Text = '系统时间校正' then
        Item := '系统时间校正';
      if TreeView1.Selected.Text = '数据传输测试' then
        Item := '数据传输测试';
      if TreeView1.Selected.Text = 'MAC地址测试' then
        Item := 'MAC地址测试';
      if TreeView1.Selected.Text = '网络速度测试' then
        Item := '网络速度测试';
      if TreeView1.Selected.Text = '内存条数测试' then
        Item := '内存条数测试';
      if TreeView1.Selected.Text = '内存容量测试' then
        Item := '内存容量测试';
      if TreeView1.Selected.Text = '无线网络名称' then
        Item := '无线网络名称';
      if TreeView1.Selected.Text = '无线信号强度' then
        Item := '无线信号强度';
      if TreeView1.Selected.Text = '风扇测试' then
        Item := '风扇测试';
      if TreeView1.Selected.Text = '休眠测试' then
        Item := '休眠测试';
      if TreeView1.Selected.Text = 'BIOS日期' then
        Item := 'BIOS日期';
      if TreeView1.Selected.Text = 'SIM卡检测' then
        Item := 'SIM卡检测';
      if TreeView1.Selected.Text = '25针打印机端口测试' then
        Item := '25针打印机端口测试';
      if TreeView1.Selected.Text = '音频回路测试' then
        Item := '音频回路测试';
  end;
end;


procedure TForm2.MSComm1Comm(Sender: TObject);
var
  s : String;
  j : Integer;
begin
          Memo1.Clear;
          if MSComm1.CommEvent = comEvReceive then
            begin
                s := MSComm1.Input;
                memo1.Lines.Text := Memo1.Lines.Text + s;
                Inc(Source_Len);
            end ;
                //ShowMessage(IntToStr(Source_Len));
                if Length(Memo1.Text) = Length(Source) then
                begin
                  for j := 0 to RzStringGrid1.RowCount - 1 do
                    begin
                      if RzStringGrid1.Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           RzStringGrid1.Cells[0,j] :=  'COM测试';
                           RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '数据传输测试正常';
                           RzStringGrid1.Cells[2,j] := 'PASS';
                           RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                           RzStringGrid1.Row := RzStringGrid1.Row + 1;
                           RzStringGrid1.Update;
                      end;
                    end;
                    COM_Result := 'PASS';
                    T1_Out := 1;
                    Exit;
                end
                else
                  begin

                    for j := 0 to RzStringGrid1.RowCount - 1 do
                      begin
                        if RzStringGrid1.Cells[0,j] = '' then
                        begin
                           //ShowMessage(RzStringGrid1.Cells[1,j]);
                             RzStringGrid1.Cells[0,j] :=  'COM测试';
                             RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '数据传输测试异常';
                             RzStringGrid1.Cells[2,j] := 'FAIL';
                             RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                             RzStringGrid1.Row := RzStringGrid1.Row + 1;
                             RzStringGrid1.Update;
                        end;
                      end;
                      COM_Result := 'FAIL';
                  end;

end;

procedure TForm2.MSComm2Comm(Sender: TObject);
var
  s : String;
  j : Integer;
begin
  Memo1.Clear;
  if MSComm2.CommEvent = comEvReceive then
    begin
        s := MSComm2.Input;
        memo1.Lines.Text := Memo1.Lines.Text + s;
        memo1.SelStart := Memo1.MaxLength;
        Memo1.SelLength := 1;
    end;
    if Length(Memo1.Text) = Length(Source) then
    begin
      for j := 0 to RzStringGrid1.RowCount - 1 do
        begin
          if RzStringGrid1.Cells[0,j] = '' then
          begin
             //ShowMessage(RzStringGrid1.Cells[1,j]);
               RzStringGrid1.Cells[0,j] :=  'COM测试';
               RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm2.CommPort) + '数据传输测试正常';
               RzStringGrid1.Cells[2,j] := 'PASS';
               RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
               RzStringGrid1.Row := RzStringGrid1.Row + 1;
               RzStringGrid1.Update;
          end;
        end;
        COM_Result := 'PASS';
        T2_Out := 1;
        exit;
    end
    else
      begin
          for j := 0 to RzStringGrid1.RowCount - 1 do
            begin
                if RzStringGrid1.Cells[0,j] = '' then
                begin
                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                     RzStringGrid1.Cells[0,j] :=  'COM测试';
                     RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm2.CommPort) + '数据传输测试异常';
                     RzStringGrid1.Cells[2,j] := 'FAIL';
                     RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                     RzStringGrid1.Row := RzStringGrid1.Row + 1;
                     RzStringGrid1.Update;
                end;
            end;
            COM_Result := 'FAIL';
      end;
end;

procedure TForm2.MSComm3Comm(Sender: TObject);
var
  s : String;
  j : Integer;
begin
  Memo1.Clear;
  if MSComm3.CommEvent = comEvReceive then
    begin
        s := MSComm3.Input;
        memo1.Lines.Text := Memo1.Lines.Text + s;
        memo1.SelStart := Memo1.MaxLength;
        Memo1.SelLength := 1;
    end;
    if Length(Memo1.Text) = Length(Source) then
    begin
      for j := 0 to RzStringGrid1.RowCount - 1 do
        begin
          if RzStringGrid1.Cells[0,j] = '' then
          begin
             //ShowMessage(RzStringGrid1.Cells[1,j]);
               RzStringGrid1.Cells[0,j] :=  'COM测试';
               RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm3.CommPort) + '数据传输测试正常';
               RzStringGrid1.Cells[2,j] := 'PASS';
               RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
               RzStringGrid1.Row := RzStringGrid1.Row + 1;
               RzStringGrid1.Update;
          end;
        end;
        COM_Result := 'PASS';
        T2_Out := 1;
        Exit;
    end
    else
      begin
          for j := 0 to RzStringGrid1.RowCount - 1 do
            begin
                if RzStringGrid1.Cells[0,j] = '' then
                begin
                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                     RzStringGrid1.Cells[0,j] :=  'COM测试';
                     RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm3.CommPort) + '数据传输测试异常';
                     RzStringGrid1.Cells[2,j] := 'FAIL';
                     RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                     RzStringGrid1.Row := RzStringGrid1.Row + 1;
                     RzStringGrid1.Update;
                end;
            end;
            COM_Result := 'FAIL';
      end;
end;

procedure TForm2.SerialPortTest(APort : string; BPort : string; Factory : Word);
var
  List1,List2 : TStringList;
  Temp,Temp1 : string;
  i,j : Integer;
  t : DWORD;
begin
  T1_Out := 0;
  T2_Out := 0;
  Temp := APort;  // 存储 232协议端口
  Temp1 := BPort;  // 存储 485协议端口
  if Temp = '' then Exit;
  List1 := TStringList.Create;
  List1.Delimiter := ',';
  List1.DelimitedText := Temp;
  if Temp1 = '' then Exit;
  List2 := TStringList.Create;
  List2.Delimiter := ',';
  List2.DelimitedText := Temp1;
  Memo1.Lines.Clear;
  try
      try
           if Factory = 3 then
           begin
            // 232 协议 测试
            for I := 0 to List1.Count - 1 do
              begin
                  if MSComm1.PortOpen then MSComm1.PortOpen := False;
                  MSCOMM1.CommPort := StrToInt(List1.Strings[i]);
                  MSCOMM1.Settings := '9600,N,8,1';
                  //MSComm1.InputMode := comInputModeText;
                  MSComm1.OutBufferCount := 0;
                  MSComm1.InBufferCount := 0;
                  MSCOMM1.PortOpen := True;
                  if (MSComm1.CDHolding = True) and (MSComm1.DSRHolding = True) and (MSComm1.CTSHolding = True)then
                  begin
                    MSComm1.Output := Source;
                    while MSComm1.OutBufferCount > 0 do Application.ProcessMessages;
                    t := GetTickCount;
                    while GetTickCount - t < 500 do Application.ProcessMessages ;
                    //ShowMessage(IntToStr(MSComm1.CommEvent));
                  end
                  else
                  begin
                    if MSComm1.CDHolding = False then
                      begin
                        for j := 0 to RzStringGrid1.RowCount - 1 do
                          begin
                            if RzStringGrid1.Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 RzStringGrid1.Cells[0,j] :=  'COM测试';
                                 RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'CD线路状态错误';
                                 RzStringGrid1.Cells[2,j] := 'FAIL';
                                 RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                 RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                 RzStringGrid1.Update;
                            end;
                          end;
                          COM_Result := 'FAIL';
                      end;
                    if MSComm1.DSRHolding = False then
                      begin
                        for j := 0 to RzStringGrid1.RowCount - 1 do
                          begin
                            if RzStringGrid1.Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 RzStringGrid1.Cells[0,j] :=  'COM测试';
                                 RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'DSR线路状态错误';
                                 RzStringGrid1.Cells[2,j] := 'FAIL';
                                 RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                 RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                 RzStringGrid1.Update;
                            end;
                          end;
                          COM_Result := 'FAIL';
                      end;
                    if MSComm1.CTSHolding = False then
                    begin
                      for j := 0 to RzStringGrid1.RowCount - 1 do
                          begin
                            if RzStringGrid1.Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 RzStringGrid1.Cells[0,j] :=  'COM测试';
                                 RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'CTS线路状态错误';
                                 RzStringGrid1.Cells[2,j] := 'FAIL';
                                 RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                 RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                 RzStringGrid1.Update;
                            end;
                          end;
                          COM_Result := 'FAIL';
                    end;
                  end;


              end;
              //Memo1.Clear;
              // 485 协议测试
             for I := 0 to List2.Count - 1 do
              begin
               if MSComm2.PortOpen then MSComm2.PortOpen := False;
                  MSCOMM2.CommPort := StrToInt(List2.Strings[i]);
                  MSComm2.Handshaking := 0;
                  MSComm2.DTREnable := False;
                  MSComm2.RTSEnable := False;
                  MSComm2.InputLen:=0;//  一次读取所有数据
                  MSComm2.SThreshold:=0;
                  MSComm2.RThreshold:=57;
                  MSComm2.InBufferSize:=1024;    //  接受缓冲区大小
                  MSComm2.OutBufferSize:=1024;   //  发送缓冲区大小
                  MSComm2.InBufferCount:=0;     //清空接受缓冲区
                  MSComm2.OutBufferCount:=0;    //清空发送缓冲区
                  MSCOMM2.PortOpen := True;
                  MSComm2.Output := Source;

                  //ShowMessage('2');
                  while MSComm2.OutBufferCount > 0 do Application.ProcessMessages;
                  t := GetTickCount;
                  while  GetTickCount - t < 500 do Application.ProcessMessages ;
               //if MSComm1.PortOpen then MSComm1.PortOpen := False;
              end;
              Memo1.Clear;
              //ShowMessage('1');
          end
          else if Factory = 4 then
           begin
               // 232 协议 测试
                for I := 0 to List1.Count - 1 do
                  begin
                      if MSComm1.PortOpen then MSComm1.PortOpen := False;
                      MSCOMM1.CommPort := StrToInt(List1.Strings[i]);
                      MSCOMM1.Settings := '9600,N,8,1';
                      //MSComm1.InputMode := comInputModeText;
                      MSComm1.OutBufferCount := 0;
                      MSComm1.InBufferCount := 0;
                      MSCOMM1.PortOpen := True;
                      if (MSComm1.CDHolding = True) and (MSComm1.DSRHolding = True) and (MSComm1.CTSHolding = True)then
                      begin
                        MSComm1.Output := Source;
                        while MSComm1.OutBufferCount > 0 do Application.ProcessMessages;
                        t := GetTickCount;
                        while GetTickCount - t < 500 do Application.ProcessMessages ;
                        //ShowMessage(IntToStr(MSComm1.CommEvent));
                      end
                      else
                      begin
                        if MSComm1.CDHolding = False then
                          begin
                            for j := 0 to RzStringGrid1.RowCount - 1 do
                              begin
                                if RzStringGrid1.Cells[0,j] = '' then
                                begin
                                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                                     RzStringGrid1.Cells[0,j] :=  'COM测试';
                                     RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'CD线路状态错误';
                                     RzStringGrid1.Cells[2,j] := 'FAIL';
                                     RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                     RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                     RzStringGrid1.Update;
                                end;
                              end;
                              COM_Result := 'FAIL';
                          end;
                        if MSComm1.DSRHolding = False then
                          begin
                            for j := 0 to RzStringGrid1.RowCount - 1 do
                              begin
                                if RzStringGrid1.Cells[0,j] = '' then
                                begin
                                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                                     RzStringGrid1.Cells[0,j] :=  'COM测试';
                                     RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'DSR线路状态错误';
                                     RzStringGrid1.Cells[2,j] := 'FAIL';
                                     RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                     RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                     RzStringGrid1.Update;
                                end;
                              end;
                              COM_Result := 'FAIL';
                          end;
                        if MSComm1.CTSHolding = False then
                        begin
                          for j := 0 to RzStringGrid1.RowCount - 1 do
                              begin
                                if RzStringGrid1.Cells[0,j] = '' then
                                begin
                                   //ShowMessage(RzStringGrid1.Cells[1,j]);
                                     RzStringGrid1.Cells[0,j] :=  'COM测试';
                                     RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'CTS线路状态错误';
                                     RzStringGrid1.Cells[2,j] := 'FAIL';
                                     RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                     RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                     RzStringGrid1.Update;
                                end;
                              end;
                              COM_Result := 'FAIL';
                        end;
                      end;


                  end;

               MSComm3.CommPort := StrToInt(List1.Strings[0]);
               MSComm2.CommPort := StrToInt(List2.Strings[1]);
               if MSComm3.PortOpen then MSComm3.PortOpen := False;
               if MSComm2.PortOpen then MSComm2.PortOpen := False;
               with MSComm3 do
               begin
                 Handshaking := 0;
                 DTREnable := False;
                 RTSEnable := False;
                 InputLen:=0;//  一次读取所有数据
                 SThreshold:=0;  // 一次发送所有数据
                 RThreshold:=57;
                 inBufferSize:=1024;    //  接受缓冲区大小
                 InBufferCount:=0;     //清空接受缓冲区
                 OutBufferCount:=0;    //清空发送缓冲区
               end;
               with MSComm2 do
               begin
                 Handshaking := 0;
                 DTREnable := False;
                 RTSEnable := False;
                 InputLen:=0;//  一次读取所有数据
                 SThreshold:=0;   // 一次发送所有数据
                 RThreshold:=57;
                 inBufferSize:=1024;    //  接受缓冲区大小
                 InBufferCount:=0;     //清空接受缓冲区
                 OutBufferCount:=0;    //清空发送缓冲区
               end;

               if not MSComm3.PortOpen then MSComm3.PortOpen := True;
               if not MSComm2.PortOpen then MSComm2.PortOpen := True;
               //MSComm1.Output := Source;
               SendDate(MSComm3);
               SendDate(MSComm2);
               ReceiveDate(MSComm3);
               ReceiveDate(MSComm2);
           end
           else
             begin
               //showmessage();
             end;
      except
          on E:Exception do
          begin
             ShowMessage(E.Message);
          end;

      end;

  finally
    List1.Free;
    List2.Free;
    //if MSComm1.PortOpen then MSComm1.PortOpen := False;
    Memo1.Clear;
  end;
end;

procedure TForm2.SerialPortTest(Port : string; Factory : Word);
var
  List : TStringList;
  Temp : string;
  i,j : Integer;
  t : DWORD;
begin
  T1_Out := 0;
  T2_Out := 0;
  Temp := Port;
  if Temp = '' then Exit;
  List := TStringList.Create;
  List.Delimiter := ',';
  List.DelimitedText := Temp;
  Memo1.Lines.Clear;
  try
      try
          if Factory = 0 then
          begin
            for I := 0 to List.Count - 1 do
              begin
                  if MSComm1.PortOpen then MSComm1.PortOpen := False;
                  MSCOMM1.CommPort := StrToInt(List.Strings[i]);
                  MSCOMM1.Settings := '9600,N,8,1';
                  //MSComm1.InputMode := comInputModeText;
                  MSComm1.OutBufferCount := 0;
                  MSComm1.InBufferCount := 0;
                  MSComm1.InputLen := 0;
                  MSCOMM1.PortOpen := True;
                  if (MSComm1.CDHolding = True) and (MSComm1.DSRHolding = True) and (MSComm1.CTSHolding = True)then
                  begin
                    MSComm1.Output := Source;
                    while MSComm1.OutBufferCount > 0 do Application.ProcessMessages;
                    t := GetTickCount;
                    while GetTickCount - t < 500 do Application.ProcessMessages ;
                    //ShowMessage(IntToStr(MSComm1.CommEvent));
                  end
                  else
                  begin
                    if MSComm1.CDHolding = False then
                      begin
                        for j := 0 to RzStringGrid1.RowCount - 1 do
                          begin
                            if RzStringGrid1.Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 RzStringGrid1.Cells[0,j] :=  'COM测试';
                                 RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'CD线路状态错误';
                                 RzStringGrid1.Cells[2,j] := 'FAIL';
                                 RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                 RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                 RzStringGrid1.Update;
                            end;
                          end;
                          COM_Result := 'FAIL';
                      end;
                    if MSComm1.DSRHolding = False then
                      begin
                        for j := 0 to RzStringGrid1.RowCount - 1 do
                          begin
                            if RzStringGrid1.Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 RzStringGrid1.Cells[0,j] :=  'COM测试';
                                 RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'DSR线路状态错误';
                                 RzStringGrid1.Cells[2,j] := 'FAIL';
                                 RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                 RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                 RzStringGrid1.Update;
                            end;
                          end;
                          COM_Result := 'FAIL';
                      end;
                    if MSComm1.CTSHolding = False then
                    begin
                      for j := 0 to RzStringGrid1.RowCount - 1 do
                          begin
                            if RzStringGrid1.Cells[0,j] = '' then
                            begin
                               //ShowMessage(RzStringGrid1.Cells[1,j]);
                                 RzStringGrid1.Cells[0,j] :=  'COM测试';
                                 RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm1.CommPort) + '测试异常,'+ 'CTS线路状态错误';
                                 RzStringGrid1.Cells[2,j] := 'FAIL';
                                 RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                                 RzStringGrid1.Row := RzStringGrid1.Row + 1;
                                 RzStringGrid1.Update;
                            end;
                          end;
                          COM_Result := 'FAIL';
                    end;
                  end;


              end;
              //Memo1.Clear;
          end
          else if Factory = 1 then
          begin
            for I := 0 to List.Count - 1 do
              begin
               if MSComm1.PortOpen then MSComm1.PortOpen := False;
                  MSCOMM1.CommPort := StrToInt(List.Strings[i]);
                  MSComm1.Handshaking := 0;
                  MSComm1.DTREnable := False;
                  MSComm1.RTSEnable := False;
                  MSComm1.InputLen:=0;//  一次读取所有数据
                  MSComm1.SThreshold:=1;
                  MSComm1.RThreshold:=1;
                  MSComm1.InBufferSize:=1024;    //  接受缓冲区大小
                  MSComm1.OutBufferSize:=1024;   //  发送缓冲区大小
                  MSComm1.InBufferCount:=0;     //清空接受缓冲区
                  MSComm1.OutBufferCount:=0;    //清空发送缓冲区
                  MSCOMM1.PortOpen := True;
                  MSComm1.Output := Source;

                  //ShowMessage('2');
                  while MSComm1.OutBufferCount > 0 do Application.ProcessMessages;
                  t := GetTickCount;
                  while  GetTickCount - t < 500 do Application.ProcessMessages ;
               //if MSComm1.PortOpen then MSComm1.PortOpen := False;
              end;
              Memo1.Clear;
              //ShowMessage('1');
          end
          else if Factory = 2 then
               begin
                   MSComm1.CommPort := StrToInt(List.Strings[0]);
                   MSComm2.CommPort := StrToInt(List.Strings[1]);
                   if MSComm1.PortOpen then MSComm1.PortOpen := False;
                   if MSComm2.PortOpen then MSComm2.PortOpen := False;
                   with MSComm1 do
                   begin
                     Handshaking := 0;
                     DTREnable := False;
                     RTSEnable := False;
                     InputLen:=0;//  一次读取所有数据
                     SThreshold:=0;  // 一次发送所有数据
                     RThreshold:=57;
                     inBufferSize:=1024;    //  接受缓冲区大小
                     InBufferCount:=0;     //清空接受缓冲区
                     OutBufferCount:=0;    //清空发送缓冲区
                   end;
                   with MSComm2 do
                   begin
                     Handshaking := 0;
                     DTREnable := False;
                     RTSEnable := False;
                     InputLen:=0;//  一次读取所有数据
                     SThreshold:=0;   // 一次发送所有数据
                     RThreshold:=57;
                     inBufferSize:=1024;    //  接受缓冲区大小
                     InBufferCount:=0;     //清空接受缓冲区
                     OutBufferCount:=0;    //清空发送缓冲区
                   end;

                   if not MSComm1.PortOpen then MSComm1.PortOpen := True;
                   if not MSComm2.PortOpen then MSComm2.PortOpen := True;
                   //MSComm1.Output := Source;
                   SendDate(MSComm1);
                   SendDate(MSComm2);
                   ReceiveDate(MSComm1);
                   ReceiveDate(MSComm2);
               end
               else
                 begin
                   //showmessage();
                 end;
      except
          on E:Exception do
          begin
             ShowMessage(E.Message);
          end;

      end;

  finally
    List.Free;
    //if MSComm1.PortOpen then MSComm1.PortOpen := False;
    Memo1.Clear;
  end;

end;

// 从指定串口发送数据
procedure TForm2.SendDate(MSComm: TMSComm);
var
  t : DWORD;
begin
     t := GetTickCount;
     MSComm.Output := Source;

     while MSComm.OutBufferCount > 0 do Application.ProcessMessages;
     while GetTickCount - t < 500 do Application.ProcessMessages;

     Memo1.Clear;
end;


procedure TForm2.ReceiveDate(MSComm : TMSComm);
var
   j : integer;
begin
     if (T1_Out = 0) and (MSComm = MSComm1)then
     begin
         if (MSComm.InBufferCount = 0) then
         begin
           for j := 0 to RzStringGrid1.RowCount - 1 do
            begin
              if RzStringGrid1.Cells[0,j] = '' then
              begin
                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                   RzStringGrid1.Cells[0,j] :=  'COM测试';
                   RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm.CommPort) + '测试异常,'+ '发送数据异常';
                   RzStringGrid1.Cells[2,j] := 'FAIL';
                   RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                   RzStringGrid1.Row := RzStringGrid1.Row + 1;
                   RzStringGrid1.Update;
              end;
            end;
            COM_Result := 'FAIL';
         end;
     end;
     if (T2_Out = 0) and (MSComm = MSComm2) then
     begin
         if (MSComm.InBufferCount = 0) then
         begin
           for j := 0 to RzStringGrid1.RowCount - 1 do
            begin
              if RzStringGrid1.Cells[0,j] = '' then
              begin
                 //ShowMessage(RzStringGrid1.Cells[1,j]);
                   RzStringGrid1.Cells[0,j] :=  'COM测试';
                   RzStringGrid1.Cells[1,j] := 'COM'+IntToStr(MSComm.CommPort) + '测试异常,'+ '发送数据异常';
                   RzStringGrid1.Cells[2,j] := 'FAIL';
                   RzStringGrid1.RowCount := RzStringGrid1.RowCount + 1;
                   RzStringGrid1.Row := RzStringGrid1.Row + 1;
                   RzStringGrid1.Update;
              end;
            end;
            COM_Result := 'FAIL';
         end;
     end;
     if MSComm.PortOpen then MSComm.PortOpen := False;

end;

//读取INI配置信息
procedure TForm2.ReadIniFiles;
var
  iniFile,ainiFile : TiniFile;
  FileName,FileName1 : String;
begin

  FileName := ExtractFilePath(Paramstr(0)) + 'Config.ini';
  iniFile := TiniFile.Create(FileName);
  FileName1 := ExtractFilePath(Paramstr(0)) + 'Operator.ini';
  ainiFile := TiniFile.Create(FileName1);
  try
    //USB
    USB2_Flag := iniFile.ReadInteger('Test_ITEM_1','Enabled_1',0);
    USB3_Flag := iniFile.ReadInteger('Test_ITEM_1','Enabled_2',0);
    USB2 := iniFile.ReadInteger('Test_ITEM_1','U2_Num',2);
    USB3 := iniFile.ReadInteger('Test_ITEM_1','U3_Num',2);
    //CPU
    CPU_Flag := iniFile.ReadInteger('Test_ITEM_2','Enabled_1',0);
    CPU_Name := iniFile.ReadString('Test_ITEM_2','CPU_Name','');
    //disk
    Disk_Flag := iniFile.ReadInteger('Test_ITEM_3','Enabled_1',0);
    Disk_Num := iniFile.ReadInteger('Test_ITEM_3','Disk_N_Num',0);
    DiskSpace_Flag := iniFile.ReadInteger('Test_ITEM_3','Enabled_2',0);
    DiskSpace := iniFile.ReadString('Test_ITEM_3','Disk_C_Num','');
    //PCI
    PCI_Flag := iniFile.ReadInteger('Test_ITEM_4','Enabled_1',0);
    PCI_Num := iniFile.ReadInteger('Test_ITEM_4','PCI_NUM',0);
    PCI1 := IniFile.ReadString('Test_ITEM_4','PCI_DEV1','');
    PCI2 := IniFile.ReadString('Test_ITEM_4','PCI_DEV2','');
    PCI3 := IniFIle.ReadString('Test_ITEM_4','PCI_DEV3','');
    //Audio
    Audio_Flag := iniFile.ReadInteger('Test_ITEM_5','Enabled_1',0);
    Spk_Flag := iniFile.ReadInteger('Test_ITEM_5','Enabled_2',0);
    //Lan
    Lan_Flag := iniFile.ReadInteger('Test_ITEM_6','LAN1_Check',0);
    Lan_Num := iniFile.ReadInteger('Test_ITEM_6','Lan_Num',1);
    MAC_Addr := iniFile.ReadString('Test_ITEM_6','LAN_MAC_ADDR','');
    Conn1 := inifile.ReadString('Test_ITEM_6','LAN1_CONN','以太网');
    Conn2 := iniFile.ReadString('Test_ITEM_7','LAN2_CONN','以太网 2');
    Server_IP := IniFile.ReadString('Test_ITEM_6','Server_IP','');
    DB_Check := iniFile.ReadInteger('Test_ITEM_6','Conn_DB',0);
    User_Name := iniFile.ReadString('Test_ITEM_6','UserName','');
    DB_Psd := iniFile.ReadString('Test_ITEM_6','Password','');
    Speed1 := iniFile.ReadInteger('Test_ITEM_6','Lan1_SPEED',1000);
    Speed2 := iniFile.ReadInteger('Test_ITEM_7','Lan2_SPEED',1000);
    O_Time := iniFile.ReadInteger('Test_ITEM_6','TimeOut',5000);
    Wan_Flag := iniFile.ReadInteger('Test_ITEM_6','WAN_Check',1);
    Test_Mode := inifile.ReadInteger('Test_ITEM_6','Multi_Lan',0);
    //Serial Port
    Serial_Flag := iniFile.ReadInteger('Test_ITEM_8','Enabled_1',1);
    Serial_Port := iniFile.ReadString('Test_ITEM_8','COM_232','');
    Serial_Port2 := iniFile.ReadString('Test_ITEM_8','COM_422','');
    Serial_Fac := iniFile.ReadInteger('Test_ITEM_8','COM_MODE',0);
    //Read Memory
    MemN_Flag := iniFile.ReadInteger('Test_ITEM_9','Enabled_1',0);
    MemS_Flag := iniFile.ReadInteger('Test_ITEM_9','Enabled_2',0);
    Mem_N := iniFile.ReadInteger('Test_ITEM_9','MEM_BANK_NUM',1);
    Mem_S := iniFile.ReadInteger('Test_ITEM_9','MEM_SIZE',1024);
    //Read WLAN
    WIFI_Flag := iniFile.ReadInteger('Test_ITEM_10','Enabled_1',1);
    WIFI_Conn := iniFile.ReadInteger('Test_ITEM_10','Enabled_2',1);
    WIFI_Name := iniFile.ReadString('Test_ITEM_10','WAN_NAME','');
    WIFI_Qualt := iniFile.ReadInteger('Test_ITEM_10','WAN_QUAL',90);
    //HardWare Monitor

    Ctemp_Flag := iniFile.ReadInteger('Test_ITEM_11','Enabled_1',1);
    cTemp_Min := iniFile.ReadInteger('Test_ITEM_11','cTemp_MIN',30);
    cTemp_Max := iniFile.ReadInteger('Test_ITEM_11','cTemp_MAX',80);
    Fan_Flag := iniFile.ReadInteger('Test_ITEM_11','Enabled_2',1);
    Fan1min := iniFile.ReadInteger('Test_ITEM_11','FAN1_MIN',1200);
    Fan1Max := iniFile.ReadInteger('Test_ITEM_11','FAN1_MAX',3500);
    IO_TYPE := iniFile.ReadString('Test_ITEM_11','IO_TYPE','');
    if iniFile.ReadInteger('Test_ITEM_11','Enabled_3',1) = 0 then
          Fan1_Flag := 0
    else
          Fan1_Flag := 1;
    Fan2min := iniFile.ReadInteger('Test_ITEM_11','FAN2_MIN',1200);
    Fan2Max := iniFile.ReadInteger('Test_ITEM_11','FAN2_MAX',3500);
    if iniFile.ReadInteger('Test_ITEM_11','Enabled_4',1) = 0 then
          Fan2_Flag := 0
    else
          Fan2_Flag := 1;

    Fan3min := iniFile.ReadInteger('Test_ITEM_11','FAN3_MIN',1200);
    Fan3Max := iniFile.ReadInteger('Test_ITEM_11','FAN3_MAX',3500);
    if iniFile.ReadInteger('Test_ITEM_11','Enabled_5',1) = 0 then
          Fan3_Flag := 0
    else
          Fan3_Flag := 1;

    //休眠测试
    Sus_Flag := iniFile.ReadInteger('Test_ITEM_12','Enabled_1',1);
    S3_Flag := iniFile.ReadInteger('Test_ITEM_12','SUS3_MODE',1);
    S4_Flag := iniFile.ReadInteger('Test_ITEM_12','SUS4_MODE',1);
    // BIOS日期
    BIOS_Date := iniFile.ReadString('Test_ITEM_13','BIOS_DATE','');
    BIOS_Date_Flag := iniFile.ReadInteger('Test_ITEM_13','Enabled_1',1);
    // SIM卡
    SIM_Name := iniFile.ReadString('Test_ITEM_14','SIM_NAME','中国联通');
    Sim_Flag := iniFile.ReadInteger('Test_ITEM_14','Enabled_1',1);
    //Time
    Time_Flag := iniFile.ReadInteger('Test_ITEM_15','Enabled_1',0);
    //25针打印机(LPT)端口测试
    LPT_Flag := iniFile.ReadInteger('Test_ITEM_16','Enabled_1',1);
    LPT_Port := iniFile.ReadString('Test_ITEM_16','LPT_PORT','LPT1');
    LPT_Len := iniFile.ReadInteger('Test_ITEM_16','LPT_LEN',256);
    LPT_Timeout := iniFile.ReadInteger('Test_ITEM_16','LPT_TIMEOUT',3000);
    //治具中间串了反相器件时置1，允许按位取反后比对
    LPT_Invert := iniFile.ReadInteger('Test_ITEM_16','LPT_INVERT',0);
    //音频回路测试
    AudioLoop_Flag := iniFile.ReadInteger('Test_ITEM_17','Enabled_1',1);

    //Read Opt, LineNo
    Opt := ainiFile.ReadString('Opt','Operator','');
    LNo := ainiFile.ReadInteger('Opt','LineNo',1);
    // Auro run
    Auto_Run := iniFile.ReadInteger('ITEM_HEADER','AUTORUN',0);
    Shut_down := iniFile.ReadInteger('ITEM_HEADER','ShutDown',0);
    //测试类型，0为PCBA, 1为整机
    Test_Type := iniFile.ReadInteger('ITEM_HEADER','Type',0);
    PCBA_TYPE := iniFile.ReadInteger('ITEM_HEADER','Custom',0);
    //读取工单信息
    gd_temp := iniFile.ReadString('ITEM_HEADER','GD','');
  except on E:Exception do
    Application.MessageBox(PChar(E.Message), '错误', MB_OK + MB_ICONSTOP);
  end;
  iniFile.Free;
  ainiFile.Destroy;
  DB_Psd1 := DecryStrHex(Trim(DB_Psd),'111111222');
end;

//单网卡,向数据库插入数据
procedure TForm2.SQLInsertData;
begin
     //MessageBox(0,'执行SQLInsertDB过程','注意',MB_OK+MB_ICONWARNING);
    //sql
    //Sqlstr := 'Insert into Full_Func_Test(MAC_ID,LineNo,Operator,Result,Msg,DataTime) Values(:A,:B,:C,:D,:E,:F)';
   // MessageBox(0,PChar(mac1_temp),'Single',MB_OK);
      if Length(mac1_temp) = 0 then   Exit
      else
      begin

          if not ADOConnection1.Connected then ADOConnection1.open
          else begin

              with ADOQuery1 do
              try
                  Connection := AdoConnection1;
                 { if DataQuery(mac1_temp) = 1 then
                  begin
                    ShowMessage('前站测试FAIL');
                    exit;
                  end;  }
                  Close;
                  SQL.Clear;
                  SQL.Add('Insert into Full_Func_Test(GDID,MACID,MACID1,[LineNo],Result,Msg,Operator,DateTime,Time) ');
                  SQL.Add('Values(:A,:B,:C,:D,:E,:F,:G,:H,:I)');
                  Parameters.ParamByName('A').Value := gd_temp;
                  Parameters.ParamByName('B').Value := mac1_Temp;
                  Parameters.ParamByName('C').Value := '';
                  Parameters.ParamByName('D').Value := LNo;
                  Parameters.ParamByName('E').Value := FinalRe;
                  Parameters.ParamByName('F').Value := '网络数据传输:'+ LanSend0_Result + ',网卡MAC地址:' + LanMAC0_Result
                  + ',网络速度:' +LanSpeed0_Result +',时间校正:'+ Time_Result + ',COM接口:' + COM_Result
                  + ',PCI设备:' + PCI_Result + ',硬盘:' + DISK_Result + ',板载音频:' + Audio_Result + ',外接音频:'
                  + AudioExt_Result + ',USB2.0:' + USB2_Result + ',' + USB2_Num + ';USB3.0:' + USB3_Result + ','
                  + USB3_Num + ';CPU:' + CPU_Result + ',WIFI测试:' + WIFI_Result + WiFi1_Result + ',BIOS日期:'
                  + BIOS_Result + ',SIM卡测试:' + SIM_Result + ',内存条数测试:' + Memn_Result + ',内存容量测试:'
                  + MemS_Result + ';CPU温度:' + cTemp_Result + ',打印机端口:' + LPT_Result + ',音频回路:' + AudioLoop_Result;
                  Parameters.ParamByName('G').Value := Opt;
                  Parameters.ParamByName('H').Value := Now();
                  Parameters.ParamByName('I').Value := zTime;
                  ExecSQL;
              Finally
                  ADOQuery1.Close;
                  TCheckResult.Enabled := False;
                 // MessageBox(0,PChar(mac1_temp),'Exit',MB_OK);
              End;
          end;

      end;

end;

//整机测试向数据库插入数据
procedure TForm2.SQLInsertData_Case;
begin
     //MessageBox(0,'执行SQLInsertDB过程','注意',MB_OK+MB_ICONWARNING);
    //sql
    //Sqlstr := 'Insert into Full_Func_Test(MAC_ID,LineNo,Operator,Result,Msg,DataTime) Values(:A,:B,:C,:D,:E,:F)';
   // MessageBox(0,PChar(GD_temp),'case',MB_OK);

      if Length(mac1_temp) = 0 then   Exit
      else
      begin
          ADODBConn(Server_IP,User_Name,DB_Psd1);
          if not ADOConnection1.Connected then ADOConnection1.open
          else begin
              with ADOQuery1 do
              try
                  Connection := AdoConnection1;
                 { if DataQuery(mac1_temp) = 1 then
                  begin
                    ShowMessage('前站测试FAIL');
                    exit;
                  end;  }
                  Close;
                  SQL.Clear;
                  SQL.Add('Insert into Full_Case_Test(GDID,MACID1,MACID2,Result,Msg,DateTime,Operator,Time) ');
                  SQL.Add('Values(:A,:B,:C,:D,:E,:F,:G,:H)');
                  Parameters.ParamByName('A').Value := gd_temp;
                  Parameters.ParamByName('B').Value := mac1_Temp;
                  Parameters.ParamByName('C').Value := mac2_Temp;
                  Parameters.ParamByName('D').Value := FinalRe;
                  Parameters.ParamByName('E').Value := '网络数据传输:'+ LanSend0_Result + ',网卡MAC地址:' + LanMAC0_Result
                  + ',网络速度:' +LanSpeed0_Result + '网络2数据传输:'+ LanSend1_Result + ',网卡2MAC地址:' + LanMAC1_Result
                  + ',网络2速度:' +LanSpeed1_Result +',时间校正:'+ Time_Result + ',COM接口:' + COM_Result
                  + ',PCI设备:' + PCI_Result + ',硬盘:' + DISK_Result + ',板载音频:' + Audio_Result + ',外接音频:'
                  + AudioExt_Result + ',USB2.0:' + USB2_Result + ',' + USB2_Num + ';USB3.0:' + USB3_Result + ','
                  + USB3_Num + ';CPU:' + CPU_Result + ',WIFI测试:' + WIFI_Result + WiFi1_Result + ',BIOS日期:' + BIOS_Result
                  + ',SIM卡检测:' + SIM_Result + ',内存条数测试:' + Memn_Result + ',内存容量测试:' + MemS_Result
                  + ';CPU温度:' + cTemp_Result + ',打印机端口:' + LPT_Result + ',音频回路:' + AudioLoop_Result;
                  Parameters.ParamByName('F').Value := Now();
                  Parameters.ParamByName('G').Value := Opt;
                  Parameters.ParamByName('H').Value := zTime;
                  ExecSQL;
              Finally
                  ADOQuery1.Close;
                  TCheckResult.Enabled := False;
              End;
          end;
      end;

end;

//单网卡查询DOS测试数据
procedure TForm2.SQLInsertData1;
begin
      //sql
      //Sqlstr := 'Insert into Full_Func_Test(MAC_ID,LineNo,Operator,Result,Msg,DataTime) Values(:A,:B,:C,:D,:E,:F)';
      //MessageBox(0,PChar(mac1_temp),'single1',MB_OK);
        if Length(mac1_temp) = 0 then Exit
        else
        begin
            if not ADOConnection1.Connected then  ADOConnection1.Open
            else begin
              with ADOQuery1 do
              try
                //Connection := AdoConnection1;
                with ADOQuery1 do
                begin
                    Close;
                    SQL.Clear;
                    SQL.Add('select * from Full_DOS_Test where MAC_ID1=:a');
                    Parameters.ParamByName('a').Value := mac1_Temp;
                    Open;
                    if RecordCount <= 0 then Exit;
                    First;
                    while not Eof do
                    begin
                      gd_temp := FieldByName('GDID').AsString;
                      Result_Temp := FieldByName('Result').AsInteger;
                      Next;
                    end;
                end;
                Close;
                SQL.Clear;
                SQL.Add('Insert into Full_Func_Test(GDID,MACID1,MACID2,Result,Msg,DateTime,Operator,Time) ');
                SQL.Add('Values(:A,:B,:C,:D,:E,:F,:G,:H)');
                Parameters.ParamByName('A').Value := gd_temp;
                Parameters.ParamByName('B').Value := mac1_Temp;
                if Length(mac2_Temp) = 0 then
                   Parameters.ParamByName('C').Value := 'NULL'
                   else
                    Parameters.ParamByName('C').Value := mac2_Temp;
                if Result_Temp = 0 then
                   Parameters.ParamByName('D').Value := 0
                else
                   Parameters.ParamByName('D').Value := FinalRe;
                Parameters.ParamByName('E').Value := '网络数据传输:'+ LanSend0_Result + ',网卡MAC地址:' + LanMAC0_Result
                + ',网络速度:' +LanSpeed0_Result +',时间校正:'+ Time_Result + ',COM接口:' + COM_Result
                + ',PCI设备:' + PCI_Result + ',硬盘:' + DISK_Result + ',板载音频:' + Audio_Result + ',外接音频:'
                + AudioExt_Result + ',USB2.0:' + USB2_Result +',' + USB2_Num + ';USB3.0:' + USB3_Result +','
                + USB3_Num+ ';CPU:' + CPU_Result + ',WIFI测试:' + WIFI_Result + WiFi1_Result + ',BIOS日期:'
                + BIOS_Result + ',SIM卡测试:' + SIM_Result + ',内存条数测试:' + Memn_Result + ',内存容量测试:'
                + MemS_Result + ',磁盘容量测试:' + DiskSpace_Result + ';CPU温度:' + cTemp_Result
                  + ',打印机端口:' + LPT_Result + ',音频回路:' + AudioLoop_Result;
                Parameters.ParamByName('F').Value := Now();
                Parameters.ParamByName('G').Value := Opt;
                Parameters.ParamByName('H').Value := IntToStr(zTime) + '秒';
                ExecSQL;
              Finally
                ADOQuery1.Close;
              End;
            end;
        end;
end;

//双网卡,向数据库插入数据
procedure TForm2.SQLInsert2Data;
begin

      if (Length(mac1_temp) = 0) and (Length(mac2_temp) = 0) then
      begin
        Application.MessageBox('MAC地址检测错误', '错误', MB_OK + MB_ICONSTOP);
        Exit;
      end
      else
      begin
          ADODBConn(Server_IP,User_Name,DB_Psd1);
          if not ADOConnection1.Connected then ADOConnection1.Open
          else begin
              with ADOQuery1 do
              try
                 try
                  Connection := AdoConnection1;
                 { if DataQuery(mac1_temp) = 1 then
                  begin
                    ShowMessage('前站测试FAIL');
                    exit;
                  end;  }
                  Close;
                  SQL.Clear;
                  SQL.Add('Insert into Full_Func_Test(GDID,MACID,MACID1,[LineNo],Result,Msg,Operator,DateTime,Time) ');
                  SQL.Add('Values(:A,:B,:C,:D,:E,:F,:G,:H,:I)');
                  Parameters.ParamByName('A').Value := gd_temp;
                  Parameters.ParamByName('B').Value := mac1_Temp;
                  Parameters.ParamByName('C').Value := mac2_Temp;
                  Parameters.ParamByName('D').Value := LNo;
                  Parameters.ParamByName('E').Value := FinalRe;
                  Parameters.ParamByName('F').Value := '网络数据传输:'+ LanSend0_Result + ',网卡MAC地址:' + LanMAC0_Result
                  + ',网络速度:' +LanSpeed0_Result + '网络2数据传输:'+ LanSend1_Result + ',网卡2MAC地址:' + LanMAC1_Result
                  + ',网络2速度:' +LanSpeed1_Result +',时间校正:'+ Time_Result + ',COM接口:' + COM_Result
                  + ',PCI设备:' + PCI_Result + ',硬盘:' + DISK_Result + ',硬盘容量:' + DiskSpace_Result + ',板载音频:'
                  + Audio_Result + ',外接音频:' + AudioExt_Result + ',USB2.0:' + USB2_Result + ',' + USB2_Num + ';USB3.0:'
                  + USB3_Result + ',' + USB3_Num + ';CPU:' + CPU_Result + ',WIFI测试:' + WIFI_Result + WiFi1_Result
                  + ',BIOS日期:' + BIOS_Result + ',SIM卡检测:' + SIM_Result + ',内存条数测试:' + Memn_Result
                  + ',内存容量测试:' + MemS_Result + ';CPU温度:' + cTemp_Result + ',打印机端口:' + LPT_Result + ',音频回路:' + AudioLoop_Result;
                  Parameters.ParamByName('G').Value := Opt;
                  Parameters.ParamByName('H').Value := Now();
                  Parameters.ParamByName('I').Value := zTime;
                  ExecSQL;
                 Except
                   on E:Exception do
                   begin
                     Application.MessageBox(PChar(E.Message), '错误', MB_OK +
                       MB_ICONSTOP);
                   end;
                 end;
              Finally
                  ADOQuery1.Close;
                  TCheckResult.Enabled := False;
              End;
          end;

      end;

end;


//BE客户服务器用，4个网卡 向数据库插入数据
procedure TForm2.SQLInsert2Data4;
begin

      if (Length(mac1_temp) = 0) and (Length(mac2_temp) = 0) and (Length(mac3_temp) = 0) and (Length(mac4_temp) = 0)then
      begin
        Application.MessageBox('MAC地址检测错误', '错误', MB_OK + MB_ICONSTOP);
        Exit;
      end
      else
      begin
          ADODBConn(Server_IP,User_Name,DB_Psd1);
          if not ADOConnection1.Connected then ADOConnection1.Open
          else begin
              with ADOQuery1 do
              try
                 try
                  Connection := AdoConnection1;
                 { if DataQuery(mac1_temp) = 1 then
                  begin
                    ShowMessage('前站测试FAIL');
                    exit;
                  end;  }
                  Close;
                  SQL.Clear;
                  SQL.Add('Insert into Full_SFunc_Test(GDID,MACID1,MACID2,MACID3,MACID4,[LineNo],Result,Msg,Operator,DateTime,Time) ');
                  SQL.Add('Values(:A,:B,:C,:D,:E,:F,:G,:H,:I,:J,:K)');
                  Parameters.ParamByName('A').Value := gd_temp;
                  Parameters.ParamByName('B').Value := mac1_Temp;
                  Parameters.ParamByName('C').Value := mac2_Temp;
                  Parameters.ParamByName('D').Value := mac3_Temp;
                  Parameters.ParamByName('E').Value := mac4_Temp;
                  Parameters.ParamByName('F').Value := LNo;
                  Parameters.ParamByName('G').Value := FinalRe;
                  Parameters.ParamByName('H').Value := '网络数据传输:'+ LanSend0_Result + ',网卡MAC地址:' + LanMAC0_Result
                  + ',网络速度:' +LanSpeed0_Result + '网络2数据传输:'+ LanSend1_Result + ',网卡2MAC地址:' + LanMAC1_Result
                  + ',网络2速度:' +LanSpeed1_Result +',时间校正:'+ Time_Result + ',COM接口:' + COM_Result
                  + ',PCI设备:' + PCI_Result + ',硬盘:' + DISK_Result + ',硬盘容量:' + DiskSpace_Result + ',板载音频:'
                  + Audio_Result + ',外接音频:' + AudioExt_Result + ',USB2.0:' + USB2_Result + ',' + USB2_Num + ';USB3.0:'
                  + USB3_Result + ',' + USB3_Num + ';CPU:' + CPU_Result + ',WIFI测试:' + WIFI_Result + WiFi1_Result
                  + ',BIOS日期:' + BIOS_Result + ',SIM卡检测:' + SIM_Result + ',内存条数测试:' + Memn_Result
                  + ',内存容量测试:' + MemS_Result + ';CPU温度:' + cTemp_Result + ',打印机端口:' + LPT_Result + ',音频回路:' + AudioLoop_Result;
                  Parameters.ParamByName('I').Value := Opt;
                  Parameters.ParamByName('J').Value := Now();
                  Parameters.ParamByName('K').Value := zTime;
                  ExecSQL;
                 Except
                   on E:Exception do
                   begin
                     Application.MessageBox(PChar(E.Message), '错误', MB_OK +
                       MB_ICONSTOP);
                   end;
                 end;
              Finally
                  ADOQuery1.Close;
                  TCheckResult.Enabled := False;
              End;
          end;

      end;

end;

function TForm2.ADODBConn(Server_IP: String; User_Name : String; PassWord : string):Boolean;
begin
    CoInitialize(nil);
    if ADOConnection1 <> nil then ADOConnection1.Close;
        ADOConnection1 := TADOConnection.Create(nil);
        ADOConnection1.ConnectionString := '';
        ADOConnection1.ConnectionString :='Provider=SQLOLEDB.1;'
        + 'Persist Security Info=False;' + 'User ID='
        + User_Name + ';Password=' + PassWord
        + ';Initial Catalog=' + 'Test_DB'+';Data Source=' + Server_IP +';';
        ADOConnection1.ConnectionTimeout := 15;
        ADOConnection1.LoginPrompt := False;
        // Test_123456789
    try
        Application.ProcessMessages;
        ADOConnection1.Open;
        if ADOConnection1.Connected then
        begin
          RzStatusPane3.Font.Color := clGreen;
          RzStatusPane3.Caption := '数据库已连接';
          Result := True;
          TConnDB.Enabled := False;
        end
        else
        begin
          RzStatusPane3.Font.Color := clRed;
          RzStatusPane3.Caption := '数据库未连接';
          Result := False;
        end;
    except
      on E:Exception do
        begin
         ADOConnection1.Close;
         RzStatusPane3.Font.Color := clRed;
         RzStatusPane3.Caption := '数据库连接错误';
         Result := False;
        end;
    end;
    CoUninitialize;
end;

function TForm2.DataQuery(QueryStr: string):Integer;
begin
  Result := 1; //1表示前站Fail，0表示Pass
  if ADOConnection1 <> nil then ADOConnection1.Close;
        ADOConnection1 := TADOConnection.Create(nil);
        ADOConnection1.ConnectionString := '';
        ADOConnection1.ConnectionString :='Provider=SQLOLEDB.1;'
        + 'Persist Security Info=False;' + 'User ID='
        + User_Name + ';Password=' + DB_Psd1
        + ';Initial Catalog=' + 'Test_DB'+';Data Source=' + Server_IP +';';
        ADOConnection1.ConnectionTimeout := 15;
        ADOConnection1.LoginPrompt := False;
  try
    Application.ProcessMessages;
    ADOConnection1.Open;
    if ADOConnection1.Connected then
    begin
      with ADOQuery2 do
      begin
        Connection := ADOConnection1;
        Close;
        SQL.Clear;
        SQL.Add('Select * from Full_DOS_Test where MAC_ID1=:a');  //  order by DateTime asc | desc  排序
        //SQL.Add(' ORDER by ''DateTime''');
        Parameters.ParamByName('a').Value := Trim(QueryStr);
        Open;
        //Sort := 'DateTime asc';
        if RecordCount <= 0 then Exit;
        First;
        while not Eof do
        begin
          gd_temp := FieldByName('GDID').AsString;
          Result_Temp := FieldByName('Result').AsInteger;
          Next;
        end;
        if Result_Temp = 1 then
          Result := 0
          else
            Result := 1;
      end;
    end;
  finally
    ADOQuery2.Close;
    ADOConnection1.Close;
  end;
end;

procedure TForm2.SetLocalTime;
var
  j : Integer;
begin
    try
      IdTime1.Host := Server_IP;
      if IdTime1.SyncTime then
      begin
          with RzStringGrid1 do
          begin
              for j := 0 to RowCount - 1 do
              begin
                  if Cells[0,j] = '' then
                  begin
                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                       Cells[0,j] :=  '系统时间校正';
                       Cells[1,j] := '连接服务器校正系统时间';
                       Cells[2,j] := 'PASS';
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
              end;
          end;
          Time_Result := 'PASS';
      end
      else
      begin
        with RzStringGrid1 do
          begin
              for j := 0 to RowCount - 1 do
              begin
                  if Cells[0,j] = '' then
                  begin
                     //ShowMessage(RzStringGrid1.Cells[1,j]);
                       Cells[0,j] :=  '系统时间校正';
                       Cells[1,j] := '连接服务器校正系统时间';
                       Cells[2,j] := 'FAIL';
                       RowCount := RowCount + 1;
                       Row := Row + 1;
                       Update;
                  end;
              end;
          end;
          Time_Result := 'FAIL';
      end;
    except
      on E:Exception do
        begin
          with RzStringGrid1 do
            begin
                for j := 0 to RowCount - 1 do
                begin
                    if Cells[0,j] = '' then
                    begin
                       //ShowMessage(RzStringGrid1.Cells[1,j]);
                         Cells[0,j] :=  '系统时间校正';
                         Cells[1,j] := '连接服务器校正系统时间';
                         Cells[2,j] := 'FAIL';
                         RowCount := RowCount + 1;
                         Row := Row + 1;
                         Update;
                    end;
                end;
            end;
            Time_Result := 'FAIL';
        end;
    end;
end;

procedure TForm2.FunctionTest;
var
  ModalForm : TForm;
 // sNum : Integer;
begin
    //sNum := 0;
      if Sus_Flag = 0 then
       begin
         if S3_Flag = 0 then
            begin
               sSuspend_Test('S3');
               if Sus1_Flag = 1 then
                  sSuspend('S3');
            end
            else
            begin
              S3_Result := '未测试';
            end;
         if S4_Flag = 0 then
            begin
               sSuspend_Test('S4');
               if Sus1_Flag = 1 then
                  sSuspend('S4');
            end
            else
            begin
              S4_Result := '未测试';
            end;
       end
       else if (Sus_Flag = 1) or (Sus1_Flag = 1) then
       begin
            //音频测试
            //MessageBox(0,'1','Message',MB_OK);
            if (SPK_Flag = 0) then begin
              begin
                 //Thread2 := BeginThread(nil,0,@TAudioEXT_Test,nil,0,ID1);
                 AudioEXT_Test;
                 TAudio_Check.Enabled := True;
              end
            end
            else if (SPK_Flag = 1) then
            begin
                  AudioExt_Result := '未测试';
                  if Audio_Flag = 0 then
                     Thread1 := BeginThread(nil,0,@TAudioI_Test,nil,0,ID)
                     //Audio_Test
                     else
                       Audio_Result := '未测试';
            end;
            // USB 测试
            if (USB2_Flag = 0) and (USB3_Flag = 0) then  begin
              //USB2Test(USB2);
              //Thread3 := BeginThread(nil,0,@TUSBTest,nil,0,ID2);

              USBTest(USB2,USB3,USB2_Flag,USB3_Flag);
            end
            else if (USB2_Flag = 0) and (USB3_Flag = 1) then
            begin
                 USB2Test(USB2);
                 USB3_Result := '未测试';
            end
            else if (USB2_Flag = 1) and (USB3_Flag = 0) then
            begin
                USB3Test(USB3);
                USB2_Result := '未测试';
            end
            else
            begin
              USB2_Result := '未测试';
              USB3_Result := '未测试';
            end;
            // WiFi
            if WiFi_Flag = 0 then begin
                Thread9 := BeginThread(nil,0,@TWIFITest,nil,0,ID8);
            end
                ELSE begin
                  WIFI_Result := '未测试';
                  WiFi1_Result := '未测试';
                end;

            // CPU测试
            if CPU_Flag = 0 then begin
              //CPUTest(CPU_Name);
              //ShowMessage('Start CPU Test AutoRun');
              Thread5 := BeginThread(nil,0,@TCPUTest,nil,0,ID4);
            end
            else
              CPU_Result := '未测试';
            // PCI 测试
            if PCI_Flag = 0 then begin
              //PCITEST;
              Thread6 := BeginThread(nil,0,@TPCITest,nil,0,ID5);
            end
            else
              PCI_Result := '未测试';
            // 磁盘 测试
            if Disk_Flag = 0 then  begin
                //DiskTest(Disk_Num);
              Thread7 := BeginThread(nil,0,@TDiskTest,nil,0,ID6);
            end
            else
              DISK_Result := '未测试';
            // 磁盘容量 测试
            if DiskSpace_Flag = 0 then  begin
              Thread14 := BeginThread(nil,0,@TDiskSpaceTest,nil,0,ID13);
            end
            else
                DiskSpace_Result := '未测试';
            // 时间
            if Time_Flag = 0 then
                SetLocalTime
                else
                  Time_Result := '未测试';
            // 网络
            if Lan_Flag = 0 then begin
              //Inc(sNum);
               //MessageBox(0,PChar('Start Lan Test'),PChar('Lan Test'),MB_OK);
              //SetLocalTime;
              //NetConnectTest(MAC_Addr,Server_IP,Speed1,Lan_Num,O_Time);
              if Wan_Flag = 0 then
              begin
                  ModalForm := TFrm_showmac.Create(Application);//动态创建窗体
                  // Application.CreateForm(TFrm_showmac, Frm_showmac);
                 // if not Assigned(Frm_showmac) then
                 // begin
                    //Frm_showmac:=TFrm_showmac.Create(nil);
                     try

                       if ModalForm.ShowModal = mrok then //显示模式窗体
                        begin
                          //ShowMessage('Result is ok');
                        end;
                      finally
                        ModalForm.Free; //释放窗体实例
                        //ShowMessage(BoolToStr(ModalForm = nil));
                        ModalForm := nil; //把窗体变量设为nil
                        //ShowMessage(BoolToStr(ModalForm = nil));
                      end;
                 // end
                 // else
                //  begin
                 //   Frm_showmac.Free;
              end
             else
              begin
                Thread10 := BeginThread(nil,0,@TLANTest,nil,0,ID9);
              end;
            end
            else
            begin
              Lan_Result := '未测试';
              LanSend0_Result := '未测试';
              LanSend1_Result := '未测试';
              LanMAC0_Result := '未测试';
              LanMAC1_Result := '未测试';
              LanSpeed0_Result := '未测试';
              LanSpeed1_Result := '未测试';
            end;
            // 串口
            if Serial_Flag = 0 then begin
              case Serial_Fac of
                0: SerialPortTest(Serial_Port,Serial_Fac);
                1: SerialPortTest(Serial_Port2,Serial_Fac);
                2: SerialPortTest(Serial_Port2,Serial_Fac);
                3: SerialPortTest(Serial_Port,Serial_Port2,Serial_Fac);
                4: SerialPortTest(Serial_Port,Serial_Port2,Serial_Fac);
              end;
            end
            else
              COM_Result := '未测试';
            // 内存
            if (MemN_Flag = 0) or (MemS_Flag = 0) then
              Thread8 := BeginThread(nil,0,@TMEMTest,nil,0,ID7)
              else
              begin
                MEMS_Result := '未测试';
                MEMN_Result := '未测试';
              end;

            if Fan_Flag = 0 then
            begin
              //InitializeWinIo;
              Thread11 := BeginThread(nil,0,@TFanTest,nil,0,ID10);
              //FanControl(min,max,Fan_num)
              end
              else
              begin
                FAN1_Result := '未测试';
                FAN2_Result := '未测试';
                FAN3_Result := '未测试';
              end;

            if Ctemp_flag = 0 then
            begin
              //InitializeWinIo;
              Thread15 := BeginThread(nil,0,@TCtemp_Test,nil,0,ID14);
              //FanControl(min,max,Fan_num)
              end
              else
              begin
                cCpu_Result := '未测试';
              end;
            // BIOS
            if BIOS_Date_Flag = 0 then
               Thread13 := BeginThread(nil,0,@TCheckBios,nil,0,ID12)
               //CheckBIOS(BIOS_Date)
               else
                   BIOS_Result := '未测试';
            // SIM Card check
            if Sim_Flag = 0 then begin
               Thread12 := BeginThread(nil,0,@Sim_Check,nil,0,ID11);
               //Read_Sim(SIM_Name);
               end
               else
                   SIM_Result := '未测试';
            // 25针打印机(LPT)端口测试
            if LPT_Flag = 0 then
               Thread16 := BeginThread(nil,0,@TLptTest,nil,0,ID15)
               else
                   LPT_Result := '未测试';
       end;
end;

procedure TForm2.Final_Result;
begin
  if ((Audio_Result = 'PASS') or (Audio_Result = '未测试')) and ((AudioExt_Result = 'PASS') or (AudioExt_Result = '未测试')) and
    ((PCI_Result = 'PASS') or (PCI_Result = '未测试')) and ((DISK_Result = 'PASS') or (DISK_Result = '未测试'))
   and ((WIFI_Result = 'PASS') or (WIFI_Result = '未测试')) and ((WIFI1_Result = 'PASS') or (WIFI1_Result = '未测试'))
   and ((CPU_Result = 'PASS') or (CPU_Result = '未测试'))
   and ((FAN1_Result ='PASS') or (FAN1_Result ='未测试')) and ((MEMN_Result = 'PASS') or (MEMN_Result = '未测试'))
   and ((MEMS_Result = 'PASS') or (MEMS_Result = '未测试')) and ((LanMAC0_Result = 'PASS') or (LanMAC0_Result = '未测试'))
   and ((LanSend0_Result = 'PASS') or (LanSend0_Result = '未测试')) and ((LanSpeed0_Result = 'PASS') or (LanSpeed0_Result = '未测试'))
   and ((Time_Result ='PASS') or (Time_Result ='未测试')) and ((COM_Result = 'PASS') or (COM_Result = '未测试'))
   and ((USB2_Result = 'PASS') or (USB2_Result = '未测试')) and ((USB3_Result = 'PASS') or (USB3_Result = '未测试'))
   and ((BIOS_Result = 'PASS') or (BIOS_Result = '未测试')) and ((LanMAC1_Result = 'PASS') or (LanMAC1_Result = '未测试'))
   and ((LanSend1_Result = 'PASS') or (LanSend1_Result = '未测试')) and ((LanSpeed1_Result = 'PASS') or (LanSpeed1_Result = '未测试'))
   and ((SIM_Result = 'PASS') or (SIM_Result = '未测试')) and ((DiskSpace_Result = 'PASS') or (DiskSpace_Result = '未测试'))
   and ((FAN2_Result ='PASS') or (FAN2_Result ='未测试')) and ((cCpu_Result ='PASS') or (cCpu_Result ='未测试'))
   and ((FAN3_Result ='PASS') or (FAN3_Result ='未测试'))
   and ((LPT_Result ='PASS') or (LPT_Result ='未测试'))
   and ((AudioLoop_Result ='PASS') or (AudioLoop_Result ='未测试'))
   then begin
      FinalRe := 0;
      TCheckResult.Enabled := False;
      { 自动测试已出结论，复位标志。之后操作员右键手动测音频回路时
        又会弹框提示，符合直觉。 }
      FAutoTestRunning := False;
      Show_Form;
//      MessageBox(0,PChar(mac1_temp),'message',MB_OK);
   end
   else
   begin
      FinalRe := 1;
      FAutoTestRunning := False;
     {
      ShowMessage('Audio: ' + Audio_Result + ';AudioExt: ' + AudioExt_Result + ';PCI: '+ PCI_Result + ';DISK:' + DISK_Result +
      ';WIFI:' + WIFI_Result + ';CPU: ' + CPU_Result + ';MEMN: ' + MEMN_Result + ';MEMS' + MEMS_Result +
      ';LanMAC: ' + LanMAC0_Result + ';LanSpeed:' + LanSpeed0_Result + ';LanSend: ' + LanSend0_Result + ';Time: ' + Time_Result + ';COM:' + COM_Result + ';usb2:' +
      USB2_Result + 'USB3:' + USB3_Result + 'BIOS: ' + BIOS_Result + 'LanSend1: ' + LanSend1_Result +
      ';LanMAC1: ' + LanMAC1_Result + ';LanSpeed1:' + LanSpeed1_Result + ';SIM:' + SIM_Result+ ';cCpu_Result:' + cCpu_Result +
      ';FAN2_Result: ' + FAN2_Result + ';FAN3_Result: ' + FAN3_Result +';FAN1_Result: ' + FAN1_Result  + ';WIFI1_Result: ' + WIFI1_Result
       + ';DiskSpace_Result: ' + DiskSpace_Result );
      Sleep(10000);  }
   end;
end;

procedure TForm2.RTime;
var
  rNowTime, rOkTime : Integer;
begin
  rOkTime := GetTickCount();
  repeat
    Application.ProcessMessages;
    rNowTime := GetTickCount();
  until (rNowTime - rOkTime >= 5000);

end;

procedure TForm2.Show_Form;
var
  param1,param2 : string;
  FileName : string;
begin
  param1 := '/p /f';
  param2 := '/t 2 /r';
  FileName := ExtractFilePath(ParamStr(0)) + 'usbtest.txt';
  if FileExists(FileName) then DeleteFile(FileName);
//  MessageBox(0,PChar('Final'),'mac0',MB_OK);
  if FinalRe = 0 then
  begin
      if (DB_Check = 0) then
      begin
          if (Test_Type = 0) then        //如果是PCBA测试
          begin
            if Lan_Num = 2 then
            begin
//              MessageBox(0,PChar('Final'),'mac1',MB_OK);
    //
              SQLInsert2Data;
            end
            else
            begin
                SQLInsertData;
            end;
          end
          else if (Test_Type = 1) then    //如果是整机测试
          begin
             SQLInsertData_Case;
          end
          else if (Test_Type = 2) then    //如果是服务器测试
          begin
             SQLInsert2Data4;
          end;
      end;



      Application.CreateForm(Tfrm_Result, frm_Result);
      frm_Result.Show;
      RTime;
      if Shut_down = 0 then                // 关机
      begin

        ShellExecute(0,'Open','shutdown.exe',PChar(param1),nil,0);
      end
      else if Shut_down = 1 then          // 重启
      begin
        ShellExecute(0,'Open','shutdown.exe',PChar(param2),nil,0);
      end;
  end
  else
  begin
     if (Test >= 3) and (DB_Check = 0) then
      begin
        TCheckResult.Enabled := False;
        if Test_Type = 0 then        //如果是PCBA测试
        begin
          if Lan_Num = 2 then SQLInsert2Data
          else
             SQLInsertData;
        end
        else if Test_Type = 1 then     //如果是整机测试
          begin
               SQLInsertData_Case;
          end;

        if TCheckResult.Enabled = True then
           TCheckResult.Enabled := False;
        Application.CreateForm(Tfrm_Result1, frm_Result1);
        frm_Result1.Show;
      end;
  end;
end;

procedure TForm2.SaveIniFiles;
VAR
  FileName1,FileName2,FileName3,str1,str3 : string;
  Time1,Time2 : Integer;
  List  : TStrings;
  publicCipherTextString1,plaintextStr1 : String;
begin
  FileName2 := ExtractFilePath(ParamStr(0)) + '0.d';
  FileName1 := ExtractFilePath(ParamStr(0)) + 'Config.ini';
  FileName3 := ExtractFilePath(ParamStr(0)) + 'Audio' + '\hdatest.cfg';
  //FileName4 := ExtractFilePath(ParamStr(0)) + 'USB.exe';
  //FileName5 := '/k dir UsbTreeView.exe -r:usbtest.txt';
  Conn_Num := 0;
  //mac1_temp := '';
  //mac2_temp := '';
  List := TStringList.Create;
  try
     Time1 := FileAge(FileName3);
     Time2 := FileAge(FileName1);
     str3 := EncryStrHex(IntToStr(Time2)+'ABC','111111222');    //配置加密代码
     Str1 := EncryStrHex(IntToStr(Time2),'111111222');
     //Str2 := EncryStrHex(IntToStr(Time4),'111111222');
     List.Add(Str1);
     //List1.Add(Str2);
     List.Add(Str3);
     List.SaveToFile(FileName2);
  finally
    List.Destroy;

  end;
end;

procedure TForm2.sSuspend_Test(modes: string);
var
   FileName, FileName1, str : string;
   mds : string;
begin
     FileName := ExtractFilePath(ParamStr(0)) + 'pwrtest.exe';
     FileName1 := ExtractFilePath(ParamStr(0)) + 'pwrtest.log';

     if FileExists(FileName1) then DeleteFile(FileName1);

     if modes = 's3'then
        mds := '3'
        else
        begin
             mds := '4';
        end;

     str := '/sleep /s:' + mds + ' /p:60';
     //ShellExecute(0,'open',PChar(FileName),PChar(str),nil,SW_HIDE);
     //休眠模式执行标志
     Sus1_Flag := 1;


end;

procedure TForm2.sSuspend(modes : string);
var
   List : TStringList;
   FileName,temp : string;
   i,j : integer;
begin

       List := TStringList.Create;
       FileName := ExtractFilePath(ParamStr(0)) + 'pwrtest.log';
       try
       List.LoadFromFile(FileName);
       for i := 0 to List.Count - 1 do
        begin

           temp := StrPos(PChar(List[i]),'failed');
           if temp <> '' then
           begin
               with RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  '系统休眠测试';
                           Cells[1,j] := modes + '休眠测试出错';
                           Cells[2,j] := 'FAIL';
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
              if modes = 'S3' then S3_Result:= 'FAIL' else S4_Result := 'FAIL';
              exit;
           end
           else if i = List.Count - 1 then
           begin
               with RzStringGrid1 do
              begin
                  for j := 0 to RowCount - 1 do
                  begin
                      if Cells[0,j] = '' then
                      begin
                         //ShowMessage(RzStringGrid1.Cells[1,j]);
                           Cells[0,j] :=  '系统休眠测试';
                           Cells[1,j] := modes + '休眠测试PASS';
                           Cells[2,j] := 'PASS';
                           RowCount := RowCount + 1;
                           Row := Row + 1;
                           Update;
                      end;
                  end;
              end;
              if modes = 'S3' then S3_Result := 'PASS' else S4_Result := 'PASS';
           end;

        end;
       finally
           MessageBox(0,PChar(UTF8ToAnsi('SUSPEND')),'信息',MB_OK);
           List.Free;
       end;


end;

function TForm2.GetBIOSInfoViaWMI: string;
var
  objWMIService: OleVariant;
  colItems: OleVariant;
  colItem: OleVariant;
  oEnum: IEnumVariant;
  iValue: LongWord;
begin
  Result := '';
  CoInitialize(nil); // 初始化 COM
  try
    // 正确方式：先创建 SWbemLocator 对象，再调用 ConnectServer
    objWMIService := CreateOleObject('WbemScripting.SWbemLocator');
    objWMIService := objWMIService.ConnectServer('', 'root\cimv2', '', ''); // 本地计算机

    colItems := objWMIService.ExecQuery('SELECT * FROM Win32_BIOS', 'WQL', 0);
    oEnum := IUnknown(colItems._NewEnum) as IEnumVariant;

    while oEnum.Next(1, colItem, iValue) = 0 do
    begin
      Result := VarToStr(colItem.Caption);
     // Result := Result + '版本: ' + VarToStr(colItem.Version) + #13#10;
     // Result := Result + '发布日期: ' + VarToStr(colItem.ReleaseDate) + #13#10;
     // Result := Result + 'SMBIOS 版本: ' + VarToStr(colItem.SMBIOSBIOSVersion) + #13#10;
      Break; // 通常只有一个 BIOS 记录
    end;
  finally
    CoUninitialize;
  end;
end;

end.
