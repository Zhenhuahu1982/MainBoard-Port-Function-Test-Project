program MEM_Check_Project1;

uses
  Vcl.Forms,
  MEM_Check in 'MEM_Check.pas' {Form2},
  MemoryCpuUtils in 'MemoryCpuUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
