program SYS_Variable_Set_Pro;

uses
  Vcl.Forms,
  SYS_Variable_Set in 'SYS_Variable_Set.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
