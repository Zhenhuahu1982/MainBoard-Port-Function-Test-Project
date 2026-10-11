program AudioLoopCfgSmokeTest;

{ 音频回路配置窗体冒烟测试
  构造窗体 -> 触发 FormCreate -> 校验 12 个勾选框与 4 个数值框
  -> 改几个勾选与数值 -> FormToConfig 读回 -> 再灌回 FormToForm 校验往返
  -> 触发一次「探测环境」和「保存/加载 CFG」。
  会短暂弹窗，属正常；不碰声卡、不发信号。 }

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls,
  Vcl.Dialogs,
  AudioLoopCfg, AudioLoopAnaly, AudioLoopDev, AudioLoopTest, FrmAudioLoopCfg;


var
  PassCnt, FailCnt: Integer;

procedure Check(const AName: string; AOk: Boolean; const ADetail: string = '');
begin
  if AOk then
  begin
    Inc(PassCnt);
    Writeln('[OK]   ', AName, '  ', ADetail);
  end
  else
  begin
    Inc(FailCnt);
    Writeln('[FAIL] ', AName, '  ', ADetail);
  end;
end;

var
  Form: TFrmAudioLoopCfg;
  Cfg1, Cfg2: TAlLoopConfig;
  I: Integer;
  CfgFile: string;
  EnvBuf: TAlAudioEnv;
begin
  Writeln('==========================================================');
  Writeln(' 音频回路配置窗体 冒烟测试');
  Writeln('==========================================================');

  Writeln('[1] 构造窗体');
  Application.Initialize;
  { 用 Application.CreateForm 而不是 Create(nil)：
    Create(nil) 会按类名去资源里找 dfm，冒烟测试里报过
    「Resource TFrmAudioLoopCfg not found」；CreateForm 走的是
    正确路径(单元名 = dfm 资源名)，不会踩这个坑。 }
  Application.CreateForm(TFrmAudioLoopCfg, Form);
  try
    { FormCreate 已在 Create 时跑完：探测环境 + 填默认值 }
    Check('窗体创建成功', Assigned(Form));
    Check('勾选框已绑定', Assigned(Form.ChkOut(0)) and Assigned(Form.ChkIn(0)) and
      Assigned(Form.ChkTest(0)));
    Check('数值框已绑定', Assigned(Form.PEdtPeriod) and Assigned(Form.PEdtVolume) and
      Assigned(Form.PEdtData) and Assigned(Form.PEdtThdn));
    Check('日志框已绑定', Assigned(Form.PMemoLog));
    Check('进度条已绑定', Assigned(Form.PProgBar));

    Writeln('[2] 默认勾选状态');
    for I := 0 to AL_OUTPORT_CNT - 1 do
      Check(AlOutPortName(TAlOutPort(I)) + ' 默认勾选', Form.ChkOut(I).Checked);
    for I := 0 to AL_INPORT_CNT - 1 do
      Check(AlInPortName(TAlInPort(I)) + ' 默认勾选', Form.ChkIn(I).Checked);
    for I := 0 to AL_TESTITEM_CNT - 1 do
      Check(AlTestItemName(TAlTestItem(I)) + ' 默认勾选', Form.ChkTest(I).Checked);
    Check('THD+N CHECK 默认勾选', Form.PChkThdnCheck.Checked);

    Writeln('[3] 默认数值');
    Check('PeriodPoint 默认 4', Form.PEdtPeriod.Text = '4', Form.PEdtPeriod.Text);
    Check('VolumeValue 默认 60', Form.PEdtVolume.Text = '60', Form.PEdtVolume.Text);
    Check('DataValue 默认 16384', Form.PEdtData.Text = '16384', Form.PEdtData.Text);
    Check('THD+N 默认 80', Form.PEdtThdn.Text = '80', Form.PEdtThdn.Text);

    Writeln('[4] FormToConfig 读回');
    Check('读回成功', Form.FormToConfig(Cfg1));
    Check('读回 PeriodPoint=4', Cfg1.PeriodPoint = 4, IntToStr(Cfg1.PeriodPoint));
    Check('读回 VolumeValue=60', Cfg1.VolumeValue = 60);
    Check('读回 DataVal=16384', Cfg1.DataVal = 16384);
    Check('读回 ThdnLimit=80', Cfg1.ThdnLimit = 80);
    Check('读回 ThdnCheck=True', Cfg1.ThdnCheck);
    Check('配对数为 3x4=12', Length(AlBuildPairs(Cfg1)) = 12,
      IntToStr(Length(AlBuildPairs(Cfg1))));

    Writeln('[5] 改勾选与数值后读回');
    Form.ChkOut(0).Checked := False;          { 关掉 FRONT OUT }
    Form.ChkIn(1).Checked := False;           { 关掉 MIC IN2 前置 }
    Form.ChkTest(4).Checked := False;         { 关掉 THD+N }
    Form.ChkOutJD(0).Checked := False;
    Form.PEdtPeriod.Text := '7';
    Form.PEdtVolume.Text := '33';
    Form.PEdtData.Text := '20000';
    Form.PEdtThdn.Text := '20';

    Check('再次读回成功', Form.FormToConfig(Cfg1));
    Check('FRONT OUT 已禁用', Cfg1.EnableOut[aopFront] = False);
    Check('MIC IN2 已禁用', Cfg1.EnableIn[aipMicFront] = False);
    Check('THD+N 项已禁用', Cfg1.EnableTest[altThdn] = False);
    Check('JD 开关已更新', Cfg1.EnableJD[aopFront] = False);
    Check('PeriodPoint=7', Cfg1.PeriodPoint = 7);
    Check('VolumeValue=33', Cfg1.VolumeValue = 33);
    Check('DataVal=20000', Cfg1.DataVal = 20000);
    Check('ThdnLimit=20', Cfg1.ThdnLimit = 20);
    Check('配对数降为 2x3=6', Length(AlBuildPairs(Cfg1)) = 6,
      IntToStr(Length(AlBuildPairs(Cfg1))));

    Writeln('[6] 越界数值应被夹紧');
    Form.PEdtPeriod.Text := '999';
    Form.PEdtVolume.Text := '-5';
    Form.PEdtData.Text := '999999';
    Form.PEdtThdn.Text := '888';
    Check('越界值读回成功', Form.FormToConfig(Cfg1));
    Check('PeriodPoint 夹到 10', Cfg1.PeriodPoint = AL_PERIODPOINT_MAX,
      IntToStr(Cfg1.PeriodPoint));
    Check('VolumeValue 夹到 0', Cfg1.VolumeValue = AL_VOLUMEVALUE_MIN);
    Check('DataVal 夹到 32767', Cfg1.DataVal = AL_DATAVALUE_MAX);
    Check('ThdnLimit 夹到 80', Cfg1.ThdnLimit = AL_THDN_MAX);

    Writeln('[7] 非数字输入应回退默认值而不是崩');
    Form.PEdtPeriod.Text := 'abc';
    Form.PEdtVolume.Text := '';
    Check('非数字读回成功', Form.FormToConfig(Cfg1));
    Check('非数字回退默认值 4', Cfg1.PeriodPoint = AL_DEF_PERIODPOINT,
      IntToStr(Cfg1.PeriodPoint));
    Check('空串回退默认值 60', Cfg1.VolumeValue = AL_DEF_VOLUMEVALUE);

    Writeln('[8] ConfigToForm 往返（模拟把 ini 读到的参数灌进界面）');
    AlConfigDefault(Cfg2);
    Cfg2.EnableOut[aopSurr] := False;
    Cfg2.EnableIn[aipLineIn2] := False;
    Cfg2.EnableTest[altMute] := False;
    Cfg2.PeriodPoint := 9;
    Cfg2.VolumeValue := 11;
    Cfg2.DataVal := 9999;
    Cfg2.ThdnLimit := 55;
    Form.ConfigToForm(Cfg2);
    Check('SURR OUT 勾选反映到界面', Form.ChkOut(1).Checked = False);
    Check('LINE IN2 勾选反映到界面', Form.ChkIn(3).Checked = False);
    Check('MUTE 勾选反映到界面', Form.ChkTest(3).Checked = False);
    Check('PeriodPoint 反映到界面', Form.PEdtPeriod.Text = '9', Form.PEdtPeriod.Text);
    Check('VolumeValue 反映到界面', Form.PEdtVolume.Text = '11');
    Check('DataValue 反映到界面', Form.PEdtData.Text = '9999');
    Check('THD+N 反映到界面', Form.PEdtThdn.Text = '55');

    Check('往返后再读回成功', Form.FormToConfig(Cfg1));
    Check('往返后 PeriodPoint=9', Cfg1.PeriodPoint = 9);
    Check('往返后 SURR 仍禁用', Cfg1.EnableOut[aopSurr] = False);
    Check('往返后 MUTE 仍禁用', Cfg1.EnableTest[altMute] = False);

    Writeln('[9] 配置文件名');
  Check('参数配置文件名正确', AL_PARAM_FILE = 'AudioLoopParam.ini',
    AL_PARAM_FILE);
  Check('参数配置与测试程序自己的配置不同名',
    AL_PARAM_FILE <> AL_CFG_FILE);


    Writeln('[10] 环境探测');
    { PEnv 是只读属性，拿到的记录是常量，不能当 out 传，
      所以这里另开一个局部变量来接探测结果。 }
    AlProbeAudioEnvironment(EnvBuf);
    Check('探测到输出端点信息', EnvBuf.Info <> '');
    Check('输入端点数量非负', EnvBuf.WaveInCount >= 0,
      'waveIn=' + IntToStr(EnvBuf.WaveInCount) +
      ' waveOut=' + IntToStr(EnvBuf.WaveOutCount));
    Check('模拟输出端点数组长度非负', Length(EnvBuf.OutDevices) >= 0,
      '模拟输出=' + IntToStr(Length(EnvBuf.OutDevices)) +
      ' 排除数字输出=' + IntToStr(EnvBuf.DigitalOutCnt));
    Writeln('       ', EnvBuf.Info);

    { 结果初始值应为「未测」，主窗体据此判断要不要读 }
    Check('LastPassed 初始为 False', Form.LastPassed = False);
  finally
    Form.Free;
  end;

  Writeln('==========================================================');
  Writeln(Format(' 结果: [OK] %d 项 / [FAIL] %d 项', [PassCnt, FailCnt]));
  if FailCnt = 0 then
    Writeln(' 全部通过')
  else
    Writeln(' 存在失败项');
  Writeln('==========================================================');
  if FailCnt > 0 then
    Halt(1);
end.