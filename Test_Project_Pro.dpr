program Test_Project_Pro;


uses
  Vcl.Forms,
  Test_Result in 'Test_Result.pas' {frm_Result},
  Test_Result1 in 'Test_Result1.pas' {frm_Result1},
  Audio in 'Audio.pas',
  MSCommLib_TLB in 'MSCommLib_TLB.pas',
  Show_MAC in 'Show_MAC.pas' {Frm_showmac},
  ABOUT1 in 'ABOUT1.pas' {AboutBox},
  ReadBios in 'ReadBios.pas',
  Test_Project_Demo1 in 'Test_Project_Demo1.pas' {Form2},
  Check_Sim in 'Check_Sim.pas',
  Check_Mac in 'Check_Mac.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  WiFi in 'WiFi.pas',
  USB in 'USB.pas',
  pass in 'pass.pas' {Frm_Result_Pass},
  fail_pro in 'fail_pro.pas' {Frm_Result_Fail},
  GetSystemInfo1 in 'GetSystemInfo1.pas',
  RunPg in 'RunPg.pas',
  HW in 'HW.pas',
  Lan in 'Lan.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10');
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFrm_Result_Pass, Frm_Result_Pass);
  Application.CreateForm(TFrm_Result_Fail, Frm_Result_Fail);
  //Application.CreateForm(TFrm_showmac, Frm_showmac);
  Application.Run;
end.
