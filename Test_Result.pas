unit Test_Result;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.OleServer, WMPLib_TLB;

type
  Tfrm_Result = class(TForm)
    Panel1: TPanel;
    Timer1: TTimer;
    Label1: TLabel;
    WMPEffects1: TWMPEffects;
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm_Result: Tfrm_Result;

implementation

{$R *.dfm}

procedure Tfrm_Result.FormCreate(Sender: TObject);
begin
  Label1.Font.Size := 92;
  Label1.Font.Color := clGreen;
end;

procedure Tfrm_Result.FormShow(Sender: TObject);
begin
   Timer1.Interval := 500;
   Timer1.Enabled := True;
end;

procedure Tfrm_Result.Timer1Timer(Sender: TObject);
begin
   if Label1.Caption = 'PASS' then
        Label1.Caption := ''
        else
          Label1.Caption := 'PASS';
end;

end.
