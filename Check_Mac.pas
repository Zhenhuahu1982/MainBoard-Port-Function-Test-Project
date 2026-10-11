unit Check_Mac;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    Edit1: TEdit;
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
    Test_Project_Demo1;

procedure TForm1.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
    if not (CharInSet(Key, ['A'..'F','a'..'f','0'..'9',#8,#13])) then
    begin
       Key := #0;
       //Edit1.Text := '';
    end;

    if Key = #13 then
    begin
       if Edit1.Text <> '' then
       begin
          if Length(Edit1.Text) <> 12 then
          begin
            Edit1.Text := '';
            Edit1.SetFocus;
            Exit;
          end
          else
          begin
            Test_Project_Demo1.Form2.mac1_temp := Trim(edit1.Text);
          end;
       end;
    end;
end;

end.
