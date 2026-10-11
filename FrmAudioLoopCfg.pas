unit FrmAudioLoopCfg;

{ 音频回路测试配置窗体

  界面照着 Realtek whdatest 摆：左边 OUT_PORT / IN_PORT 两列勾选框，
  右边一列测试项勾选框，下方是 JD PORT TEST 开关和四个接口数值，
  再下面是测试日志区。目的是让熟悉 whdatest 的产线人员不用重新学一遍。

  纯 VCL 控件，不依赖 Raize，与主工程现有第三方 DCU 不兼容的情况无关，
  方便单独编译验证。

  配置读写走 AudioLoopCfg，测试执行走 AudioLoopTest，
  这个窗体本身不碰 waveIn/waveOut。
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  AudioLoopCfg, AudioLoopDev, AudioLoopTest;

{ 配置与日志文件都放在程序所在目录，和主工程其它 cfg 一致 }
function GetCfgFileName: string;
function GetLogDir: string;
{ 全开默认值，窗体初始化与「恢复默认」都用它 }
function DefaultLoopConfig: TAlLoopConfig;

{ 音频回路参数配置文件（AudioLoopParam.ini）的完整路径。
  由独立的参数设置程序 AudioLoopParamSet.exe 写，测试程序只读。
  放在 exe 同级目录，两边都按 ParamStr(0) 算，天然指向同一个文件。 }
function GetAudioLoopParamFile: string;

type
  TFrmAudioLoopCfg = class(TForm)
  private
    { 端口/测试项的勾选框数组，按枚举顺序一一对应 }
    FChkOut: array[0..2] of TCheckBox;
    FChkOutJD: array[0..2] of TCheckBox;
    FChkIn: array[0..3] of TCheckBox;
    FChkInJD: array[0..3] of TCheckBox;
    FChkTest: array[0..4] of TCheckBox;

    FEdtPeriod: TEdit;
    FEdtVolume: TEdit;
    FEdtData: TEdit;
    FEdtThdn: TEdit;
    FChkThdnCheck: TCheckBox;
    FMemoLog: TMemo;
    FLblEnv: TLabel;
    FProgBar: TProgressBar;

    FEnv: TAlAudioEnv;
    FLogLines: TStringList;
    { 静默模式：自动测试时为 True，不弹任何模态框。
      产线是无人值守的，弹框等于把整条线卡死等人工点掉。 }
    FSilent: Boolean;

    procedure BindComponents;
    procedure Log(const S: string);
    procedure UpdateEnvLabel;

  published
    { 窗体事件处理。必须放 published，否则 Delphi 不会把它们
      绑定到 OnCreate/OnClick 上（CreateForm/Create 时不会触发）。 }
    { ---- 下面这些必须和 .dfm 里的对象名完全一致，Delphi 才能自动关联 ----
      容器与静态标签虽然代码里不直接用，但它们同样要声明，
      否则 .dfm 装载时找不到对应字段会直接抛异常（窗体起不来）。 }
    pnlMain: TPanel;
    grpOut: TGroupBox;   grpIn: TGroupBox;    grpTest: TGroupBox;
    grpValue: TGroupBox; grpEnv: TGroupBox;   grpLog: TGroupBox;
    grpBtn: TPanel;

    lblOutTitle: TLabel; lblInTitle: TLabel;  lblTestTitle: TLabel;
    lblPeriod: TLabel;   lblVolume: TLabel;   lblData: TLabel;
    lblThdn: TLabel;     lblHint: TLabel;

    chkOut0: TCheckBox;  chkOut1: TCheckBox;  chkOut2: TCheckBox;
    chkOutJD0: TCheckBox; chkOutJD1: TCheckBox; chkOutJD2: TCheckBox;
    chkIn0: TCheckBox;   chkIn1: TCheckBox;   chkIn2: TCheckBox;   chkIn3: TCheckBox;
    chkInJD0: TCheckBox; chkInJD1: TCheckBox; chkInJD2: TCheckBox; chkInJD3: TCheckBox;
    chkTest0: TCheckBox; chkTest1: TCheckBox; chkTest2: TCheckBox;
    chkTest3: TCheckBox; chkTest4: TCheckBox;
    chkThdnCheck: TCheckBox;
    edtPeriod: TEdit; edtVolume: TEdit; edtData: TEdit; edtThdn: TEdit;
    memoLog: TMemo; lblEnv: TLabel; progBar: TProgressBar;

    btnProbe: TButton; btnTest: TButton; btnClose: TButton;

    procedure btnProbeClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);

    { 窗体事件。必须放 published —— DFM 里的 OnCreate/OnShow/OnDestroy
      只能引用 published 段声明的方法；放 private 里绑定不上，
      FormCreate 永远不执行，BindComponents 不跑，窗体里那些控件
      引用全是 nil，一用就空指针崩溃。
      另外这三个必须排在所有字段之后：Delphi 不允许方法后再声明字段。 }
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);

  public
    { 最近一次测试的结果摘要，接入主窗体时用它填结果表格。
      字段先于方法声明 —— Delphi 不允许在方法之后再插字段。 }
    LastSummary: string;
    LastPassed: Boolean;
    { 日志文件路径，主窗体可把它显示出来便于追溯 }
    LastLogFile: string;

    { 界面 <-> 配置记录。这两个做成 public：主窗体和冒烟测试都要用，
      主窗体接入时用 FormToConfig 把用户在界面上选的项交给测试引擎。 }
    procedure ConfigToForm(const AConfig: TAlLoopConfig);
    function FormToConfig(out AConfig: TAlLoopConfig): Boolean;

    { 日志/进度回调。做成 public 是因为主窗体要在自己的界面上
      同步显示回路测试进度，它拿到这两个方法引用后直接转发给
      AudioLoopTest，不用再转发一遍消息。 }
    procedure OnTestLog(const ALine: string);
    procedure OnTestStep(ADone, ATotal: Integer; const ADesc: string);

    { 供冒烟测试断言界面绑定是否正确。
      做成只读访问器而不是把字段改成 public，
      是为了让「界面控件数组」这个内部结构保持私有。

      注意：Delphi 不允许 `property X[i]: T read 数组` 这种写法
      （报 E2008），所以下标访问一律给成方法。 }
    function ChkOut(AIdx: Integer): TCheckBox;
    function ChkOutJD(AIdx: Integer): TCheckBox;
    function ChkIn(AIdx: Integer): TCheckBox;
    function ChkInJD(AIdx: Integer): TCheckBox;
    function ChkTest(AIdx: Integer): TCheckBox;
    property PEdtPeriod: TEdit read FEdtPeriod;
    property PEdtVolume: TEdit read FEdtVolume;
    property PEdtData: TEdit read FEdtData;
    property PEdtThdn: TEdit read FEdtThdn;
    property PChkThdnCheck: TCheckBox read FChkThdnCheck;
    property PMemoLog: TMemo read FMemoLog;
    property PProgBar: TProgressBar read FProgBar;
    property PEnv: TAlAudioEnv read FEnv;

    { 静默模式开关。主窗体跑自动测试时置 True，
      跑完只留结果表格/日志，不弹框。 }
    property Silent: Boolean read FSilent write FSilent;
  end;

var
  FrmAudioLoopCfgForm: TFrmAudioLoopCfg;

implementation

{ 把窗体布局编进 exe 的资源段。
  必须显式写下面那条资源指令：主工程是用 dcc32 命令行编译的，
  不会像 IDE 那样自动为 dproj 里登记的窗体生成资源引用，
  少了它运行时 Create 会抛 EResNotFound（找不到窗体布局）。
  注意别把这条指令本身写进注释里，编译器会当真的指令解析。 }
{$R *.dfm}

uses
  AudioLoopAnaly;

{ 配置与日志都放在 exe 同级目录，跟着程序走，换机不用改路径 }
function GetCfgFileName: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + AL_CFG_FILE;
end;

function GetLogDir: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'AudioLoopLog';
  if not DirectoryExists(Result) then
    CreateDir(Result);
end;

function GetAudioLoopParamFile: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + AL_PARAM_FILE;
end;

{ 默认配置从 AudioLoopCfg 取，避免在窗体里再抄一份默认值 }
function DefaultLoopConfig: TAlLoopConfig;
begin
  AlConfigDefault(Result);
end;

procedure TFrmAudioLoopCfg.FormCreate(Sender: TObject);
begin
  FLogLines := TStringList.Create;
  FSilent := False;
  BindComponents;
  { 探测只读设备与 jack，不会打开音频流，可以放这里 }
  AlProbeAudioEnvironment(FEnv);
  UpdateEnvLabel;
  ConfigToForm(DefaultLoopConfig);
end;

procedure TFrmAudioLoopCfg.FormDestroy(Sender: TObject);
begin
  FLogLines.Free;
end;

procedure TFrmAudioLoopCfg.FormShow(Sender: TObject);
begin
  UpdateEnvLabel;
end;

{ 把设计器里的控件挂到数组上。
  这样后面读写配置只要按枚举下标循环，不用给 12 个勾选框逐个写代码，
  以后加端口也只要在这里补一行。 }
procedure TFrmAudioLoopCfg.BindComponents;
begin
  FChkOut[0] := chkOut0;   FChkOutJD[0] := chkOutJD0;
  FChkOut[1] := chkOut1;   FChkOutJD[1] := chkOutJD1;
  FChkOut[2] := chkOut2;   FChkOutJD[2] := chkOutJD2;

  FChkIn[0] := chkIn0;     FChkInJD[0] := chkInJD0;
  FChkIn[1] := chkIn1;     FChkInJD[1] := chkInJD1;
  FChkIn[2] := chkIn2;     FChkInJD[2] := chkInJD2;
  FChkIn[3] := chkIn3;     FChkInJD[3] := chkInJD3;

  FChkTest[0] := chkTest0;
  FChkTest[1] := chkTest1;
  FChkTest[2] := chkTest2;
  FChkTest[3] := chkTest3;
  FChkTest[4] := chkTest4;

  FEdtPeriod := edtPeriod;
  FEdtVolume := edtVolume;
  FEdtData   := edtData;
  FEdtThdn   := edtThdn;
  FChkThdnCheck := chkThdnCheck;
  FMemoLog := memoLog;
  FLblEnv    := lblEnv;
  FProgBar   := progBar;

  { 把按钮事件挂上。dfm 里配 OnClick 也可以，这里在代码里挂更直观，
    改按钮名时不容易漏。 }
  btnProbe.OnClick := btnProbeClick;
  btnTest.OnClick  := btnTestClick;
  btnClose.OnClick := btnCloseClick;
end;

function TFrmAudioLoopCfg.ChkOut(AIdx: Integer): TCheckBox;
begin
  Result := FChkOut[AIdx];
end;

function TFrmAudioLoopCfg.ChkOutJD(AIdx: Integer): TCheckBox;
begin
  Result := FChkOutJD[AIdx];
end;

function TFrmAudioLoopCfg.ChkIn(AIdx: Integer): TCheckBox;
begin
  Result := FChkIn[AIdx];
end;

function TFrmAudioLoopCfg.ChkInJD(AIdx: Integer): TCheckBox;
begin
  Result := FChkInJD[AIdx];
end;

function TFrmAudioLoopCfg.ChkTest(AIdx: Integer): TCheckBox;
begin
  Result := FChkTest[AIdx];
end;

procedure TFrmAudioLoopCfg.ConfigToForm(const AConfig: TAlLoopConfig);
var
  I: Integer;
begin
  for I := 0 to AL_OUTPORT_CNT - 1 do
  begin
    FChkOut[I].Checked := AConfig.EnableOut[TAlOutPort(I)];
    FChkOutJD[I].Checked := AConfig.EnableJD[TAlOutPort(I)];
  end;
  for I := 0 to AL_INPORT_CNT - 1 do
  begin
    FChkIn[I].Checked := AConfig.EnableIn[TAlInPort(I)];
    FChkInJD[I].Checked := AConfig.EnableJDIn[TAlInPort(I)];
  end;
  for I := 0 to AL_TESTITEM_CNT - 1 do
    FChkTest[I].Checked := AConfig.EnableTest[TAlTestItem(I)];

  FEdtPeriod.Text := IntToStr(AConfig.PeriodPoint);
  FEdtVolume.Text := IntToStr(AConfig.VolumeValue);
  FEdtData.Text   := IntToStr(AConfig.DataVal);
  FEdtThdn.Text   := IntToStr(AConfig.ThdnLimit);
  FChkThdnCheck.Checked := AConfig.ThdnCheck;
end;

{ 把界面上的值读回配置记录。
  四个数值框允许用户填错，这里读出来先夹到合法范围再存，
  并在日志里提示夹了什么，避免「填了 999 就默默当 87 用」不知道。 }
function TFrmAudioLoopCfg.FormToConfig(out AConfig: TAlLoopConfig): Boolean;
var
  I, V: Integer;
  MaxV: array[0..3] of Integer;
begin
  Result := True;
  AlConfigDefault(AConfig);

  for I := 0 to AL_OUTPORT_CNT - 1 do
  begin
    AConfig.EnableOut[TAlOutPort(I)] := FChkOut[I].Checked;
    AConfig.EnableJD[TAlOutPort(I)] := FChkOutJD[I].Checked;
  end;
  for I := 0 to AL_INPORT_CNT - 1 do
  begin
    AConfig.EnableIn[TAlInPort(I)] := FChkIn[I].Checked;
    AConfig.EnableJDIn[TAlInPort(I)] := FChkInJD[I].Checked;
  end;
  for I := 0 to AL_TESTITEM_CNT - 1 do
    AConfig.EnableTest[TAlTestItem(I)] := FChkTest[I].Checked;

  MaxV[0] := AL_PERIODPOINT_MAX;
  MaxV[1] := AL_VOLUMEVALUE_MAX;
  MaxV[2] := AL_DATAVALUE_MAX;
  MaxV[3] := AL_THDN_MAX;

  { 逐个读四个数值框。填了非数字就当默认值处理，不弹框打断产线节奏。 }
  V := StrToIntDef(FEdtPeriod.Text, AConfig.PeriodPoint);
  if (V < AL_PERIODPOINT_MIN) or (V > AL_PERIODPOINT_MAX) then
    Log(Format('PeriodPoint 填的 %d 超出 0-%d，已夹紧', [V, AL_PERIODPOINT_MAX]));
  AConfig.PeriodPoint := AlClampInt(V, AL_PERIODPOINT_MIN, AL_PERIODPOINT_MAX);

  V := StrToIntDef(FEdtVolume.Text, AConfig.VolumeValue);
  if (V < AL_VOLUMEVALUE_MIN) or (V > AL_VOLUMEVALUE_MAX) then
    Log(Format('VolumeValue 填的 %d 超出 0-%d，已夹紧', [V, AL_VOLUMEVALUE_MAX]));
  AConfig.VolumeValue := AlClampInt(V, AL_VOLUMEVALUE_MIN, AL_VOLUMEVALUE_MAX);

  V := StrToIntDef(FEdtData.Text, AConfig.DataVal);
  if (V < AL_DATAVALUE_MIN) or (V > AL_DATAVALUE_MAX) then
    Log(Format('DataValue 填的 %d 超出 0-%d，已夹紧', [V, AL_DATAVALUE_MAX]));
  AConfig.DataVal := AlClampInt(V, AL_DATAVALUE_MIN, AL_DATAVALUE_MAX);

  V := StrToIntDef(FEdtThdn.Text, AConfig.ThdnLimit);
  if (V < AL_THDN_MIN) or (V > AL_THDN_MAX) then
    Log(Format('THD+N 填的 %d 超出 0-%d，已夹紧', [V, AL_THDN_MAX]));
  AConfig.ThdnLimit := AlClampInt(V, AL_THDN_MIN, AL_THDN_MAX);

  AConfig.ThdnCheck := FChkThdnCheck.Checked;
end;

procedure TFrmAudioLoopCfg.Log(const S: string);
begin
  FLogLines.Add(S);
  FMemoLog.Lines.Add(S);
end;

procedure TFrmAudioLoopCfg.UpdateEnvLabel;
var
  S: string;
  I: Integer;
begin
  S := FEnv.Info + sLineBreak;
  if Length(FEnv.OutDevices) > 0 then
  begin
    S := S + '可用模拟输出端点：';
    for I := 0 to High(FEnv.OutDevices) do
      S := S + Format('[%d]%s(%dch) ', [FEnv.OutDevices[I].Index,
        FEnv.OutDevices[I].Name, FEnv.OutDevices[I].Channels]);
    S := S + sLineBreak;
  end;
  if Length(FEnv.InDevices) > 0 then
  begin
    S := S + '可用输入端点：';
    for I := 0 to High(FEnv.InDevices) do
      S := S + Format('[%d]%s ', [FEnv.InDevices[I].Index, FEnv.InDevices[I].Name]);
    S := S + sLineBreak;
  end;
  if FEnv.HasHdmiOrDp then
    S := S + '注意：检测到 ' + IntToStr(FEnv.DigitalOutCnt) +
         ' 个 HDMI/DP 数字输出，按要求已排除，不参与回路测试。';
  FLblEnv.Caption := S;
end;

procedure TFrmAudioLoopCfg.btnProbeClick(Sender: TObject);
begin
  Log('正在探测音频环境...');
  AlProbeAudioEnvironment(FEnv);
  UpdateEnvLabel;
  Log('探测完成: ' + FEnv.Info);
end;


procedure TFrmAudioLoopCfg.OnTestLog(const ALine: string);
begin
  Log(ALine);
end;

procedure TFrmAudioLoopCfg.OnTestStep(ADone, ATotal: Integer; const ADesc: string);
begin
  FProgBar.Position := ADone;
  FProgBar.Max := ATotal;
end;

procedure TFrmAudioLoopCfg.btnTestClick(Sender: TObject);
var
  Cfg: TAlLoopConfig;
  Res: TAlLoopTestResult;
  LgCb: TAlLogCallback;
  StCb: TAlStepCallback;
begin
  if not FormToConfig(Cfg) then
    Exit;

  Log('');
  Log('=== 开始音频回路测试 ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' ===');
  FMemoLog.Clear;
  FLogLines.Clear;
  FProgBar.Position := 0;

  { 每次测试前重新探测一次：产线可能会中途插治具/换治具，
    上一次的设备状态不一定还准。 }
  AlProbeAudioEnvironment(FEnv);
  UpdateEnvLabel;

  FProgBar.Visible := True;
  try
    { 方法引用必须先存进有类型的局部变量再传，不能直接写 @OnTestLog：
      那样 Delphi 会把方法名当变量去取地址，报 E2036 Variable required。 }
    LgCb := OnTestLog;
    StCb := OnTestStep;
    AlRunLoopTest(Cfg, FEnv, GetLogDir(), LgCb, StCb, Res);
  finally
    FProgBar.Visible := False;
  end;

  LastSummary := Res.Summary;
  LastPassed  := Res.Passed;
  LastLogFile := Res.LogFile;

  Log('');
  Log(Res.Summary);
  if Res.LogFile <> '' then
    Log('测试日志文件: ' + Res.LogFile);

  if Res.Passed then
  begin
    if not FSilent then
      ShowMessage('音频回路测试 PASS' + sLineBreak + sLineBreak + Res.Summary);
  end
  else
  begin
    { 自动测试(静默模式)下不弹框：产线是无人的，弹框会直接卡住整条线。
      失败信息照样写进结果表格、状态栏和日志文件，操作员事后能查。 }
    if not FSilent then
      ShowMessage('音频回路测试 FAIL' + sLineBreak + sLineBreak + Res.Summary +
        sLineBreak + sLineBreak + '详细记录见日志窗口与测试日志文件。');
  end;
end;

procedure TFrmAudioLoopCfg.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.