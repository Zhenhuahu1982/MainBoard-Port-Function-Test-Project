unit Show_MAC;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, RzLabel, Vcl.Imaging.jpeg,
  RzPanel, EnPngGr;

type
  TFrm_showmac = class(TForm)
    Timer1: TTimer;
    Panel1: TPanel;
    edtScan_mac: TEdit;
    RzLabel2: TRzLabel;
    Timer2: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtScan_macKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

  end;

var
  Frm_showmac: TFrm_showmac;
  Flag : BOOL;
implementation

{$R *.dfm}


uses
  Test_Project_Demo1;

var
  Num:Integer; //扫码执行次数

procedure TFrm_showmac.edtScan_macKeyPress(Sender: TObject; var Key: Char);
var
  i, LNum : Integer;
  mac1 : string;
begin
  LNum :=  Test_Project_Demo1.Lan_Num;

  if not (key in ['0'..'9','A'..'F','a'..'f',#8, #13]) then Key := #0;
  Application.ProcessMessages;
  if Key = #13 then
  begin
     Label3.Caption := '';
     label3.Visible := False;
     if LNum >= 2 then
      begin

            if Length(Trim(edtScan_mac.Text)) = 12  then
             begin
                mac1 := Trim(edtScan_mac.Text);
                if Test_Project_Demo1.mList1.Count = 0 then Test_Project_Demo1.mList1.Add(mac1)
                  else
                  begin
                    for I := 0 to Test_Project_Demo1.mList1.Count - 1 do       // 查看数据是否重复
                    begin
                      if SameText(mac1,Test_Project_Demo1.mList1[i]) then
                      begin
                          Label3.Font.Color := clRed;
                          Label3.Caption:= '号码重复,请重输';
                          label3.Visible := True;
                          mac1 := '';
                          edtScan_mac.Text := '';
                          edtScan_mac.SetFocus;
                          Exit;
                      end;
                    end;
                    Test_Project_Demo1.mList1.Add(mac1);
                  end;

                   Inc(num);
                   if num > LNum then    //如果扫码次数，小于等于网卡数
                    begin
                      Test_Project_Demo1.mFlag := 1;
                      Timer1.Enabled := True;
                    end
                    else
                    begin
                       Label1.Caption := '请扫描第2个MACID条码';
                       edtScan_mac.Text := '';
                       mac1 := '';
                       Label2.Caption:= IntToStr(Num);
                    end;
             end
             else
             begin
               Label2.Caption:= IntToStr(Num);
               edtScan_mac.Text := '';
               edtScan_mac.SetFocus;
               Label1.Caption := '输入的号码长度不对';
               Exit;
             end;
      end
      else if LNum = 1 then
      begin
        if Length(Trim(edtScan_mac.Text)) = 12  then
         begin
            Test_Project_Demo1.mList1.Add(Trim(edtScan_mac.Text));
            Test_Project_Demo1.mFlag := 1;
            Timer1.Enabled := True;
         end
         else
         begin
           edtScan_mac.Text := '';
           edtScan_mac.SetFocus;
           Label1.Caption := '输入的号码长度不对';
           Exit;
         end;
      end;
  end;
end;

procedure TFrm_showmac.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//     Frm_showmac := nil;
//     Action := caFree;
      ModalResult := mrAbort;
end;

procedure TFrm_showmac.FormShow(Sender: TObject);
begin
      Num := 1;
      edtScan_mac.Text := '';
      edtScan_mac.SetFocus;
      Label1.Font.Color := clBlue;
      Label1.Caption := '请扫描第1个MACID条码';
      Label2.Caption:= IntToStr(Num);

end;

procedure TFrm_showmac.Timer1Timer(Sender: TObject);
begin
   RzLabel2.Caption := IntToStr(StrToInt(RzLabel2.Caption) - 1);
   if StrToInt(RzLabel2.Caption) <= 0 then
   begin

     Timer1.Enabled := False;
     ModalResult := mrOk;
   end;
end;

end.
