unit Test_Result1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.OleServer, WMPLib_TLB;

type
  Tfrm_Result1 = class(TForm)
    Panel1: TPanel;
    Timer1: TTimer;
    WMPEffects1: TWMPEffects;
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm_Result1: Tfrm_Result1;

implementation

{$R *.dfm}

procedure Tfrm_Result1.FormShow(Sender: TObject);
begin
  Timer1.Interval := 500;
  Timer1.Enabled := True;
end;

procedure Tfrm_Result1.Timer1Timer(Sender: TObject);
begin
  if Panel1.Caption = 'FAIL' then
        Panel1.Caption := ''
        else
          Panel1.Caption := 'FAIL'
end;

end.
