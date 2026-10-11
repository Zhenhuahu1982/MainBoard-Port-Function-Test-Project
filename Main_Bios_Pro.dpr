program Main_Bios_Pro;

uses
  Vcl.Forms,
  Main_BIOS in 'Main_BIOS.pas' {Frm_BIOS};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrm_BIOS, Frm_BIOS);
  Application.Run;
end.
