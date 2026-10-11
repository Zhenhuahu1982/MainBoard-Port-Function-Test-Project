unit pass;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, WinSkinData,
  Vcl.StdCtrls, EnPngGr, Vcl.Imaging.jpeg, EnJpgGr, System.ImageList,
  Vcl.ImgList;

type
  TFrm_Result_Pass = class(TForm)
    tmr1: TTimer;
    ImageList1: TImageList;
    pnl1: TPanel;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    flag : Word;
  end;

var
  Frm_Result_Pass: TFrm_Result_Pass;
  pass0,fail: TJPEGImage;
  resStream_Pass0,resStream_Fail : TResourceStream;
  p : Word;

implementation

{$R *.dfm}
{$R result.res}

procedure TFrm_Result_Pass.FormCreate(Sender: TObject);
begin
  flag := 0;

end;

procedure TFrm_Result_Pass.FormShow(Sender: TObject);
begin
  pass0 := TJPEGImage.Create;

  fail := TJPEGImage.Create;

  resStream_Pass0 := TResourceStream.Create(HInstance, 'pass', RT_RCDATA);
  resStream_Fail := TResourceStream.Create(HInstance, 'fail', RT_RCDATA);
  pass0.LoadFromStream(resStream_Pass0);
  fail.LoadFromStream(resStream_Fail);



  if flag = 1 then
   begin
      Image1.Picture.Bitmap.Assign(pass0);
      p := 0;
   end
    else if flag = 2 then
    begin
      Image1.Picture.Bitmap.Assign(Fail);
      p := 3;
    end;
    tmr1.Enabled := True;
   pass0.Free;
   fail.Free;
   resStream_Pass0.Free;
   resStream_Fail.Free;
end;

procedure TFrm_Result_Pass.tmr1Timer(Sender: TObject);
begin
  if p = 0 then
  begin
     pnl1.Color := clWhite;
     Image1.Visible := False;
     p := 1;

  end
  else if p = 1 then
     begin
       Image1.Visible := True;
       p := 0;
     end;
  if p = 3 then
  begin
     Image1.Visible := False;
     p := 4;
     
  end
  else
  if p = 4 then
     begin
         Image1.Visible := True;
         p := 3;
     end;
end;

end.
