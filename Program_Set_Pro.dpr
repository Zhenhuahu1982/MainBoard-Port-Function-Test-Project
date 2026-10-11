program Program_Set_Pro;

uses
  Vcl.Forms,
  Program_Set in 'Program_Set.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
