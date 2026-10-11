unit fail_pro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

type
  TFrm_Result_Fail = class(TForm)
    tmr1: TTimer;
    pnl1: TPanel;
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Frm_Result_Fail: TFrm_Result_Fail;

implementation

{$R *.dfm}

procedure TFrm_Result_Fail.tmr1Timer(Sender: TObject);
begin
  if pnl1.Caption = 'FAIL' then
    pnl1.Caption := ''
    else
      pnl1.Caption := 'FAIL';
end;

end.
