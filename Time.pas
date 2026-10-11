unit Time;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdTime, System.IniFiles;

type
  TForm2 = class(TForm)
    IdTime1: TIdTime;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.FormCreate(Sender: TObject);
var
  iniFile : TIniFile;
  FileName,FileName1,FileName2,Server_IP : String;
  F : TextFile;
begin

    FileName := ExtractFilePath(ParamStr(0)) + 'Config.ini';
    FileName1 := ExtractFilePath(ParamStr(0)) + 'PassTime.Txt';
    FileName2 := ExtractFilePath(ParamStr(0)) + 'ErrTime.Txt';
    if FileExists(FileName1) then DeleteFile(FileName1);
    if FileExists(FileName2) then DeleteFile(FileName2);
    iniFile := TIniFile.Create(FileName);
   try
    Server_IP := iniFile.ReadString('Lan','Server_IP','');
    try
      IdTime1.Host := Server_IP;
      Label1.Caption := '网络服务器时间: '+DateTimeToStr(IdTime1.DateTime);
      if IdTime1.SyncTime then
      begin
        AssignFile(F,FileName1);
        Rewrite(F);
        Writeln(F,'Set Time Pass');
        CloseFile(F);
        Label1.Font.Color := clGreen;
        Label1.Caption := 'PASS';
      end
      else
      begin
        AssignFile(F,FileName2);
        Rewrite(F);
        Writeln(F,'Set Time Fail');
        CloseFile(F);
        Label1.Font.Color := clRed;
        Label1.Caption := 'FAIL';
      end;
    except
    on E:Exception do
      begin
        AssignFile(F,FileName2);
        Rewrite(F);
        Writeln(F,'Set Time Fail');
        CloseFile(F);
        Label1.Font.Color := clRed;
        Label1.Caption := 'FAIL';
      end;
    end;
   finally
     iniFile.Free;
     Application.Terminate;
   end;
end;

end.
