unit Program_Set;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzButton, RzRadChk, RzPanel, RzTabs,
  Vcl.ExtCtrls, RzRadGrp, RzDBRGrp, RzBckgnd, System.IniFiles, StandardDES,Winapi.ShellAPI;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    RzPageControl1: TRzPageControl;
    TabSheet1: TRzTabSheet;
    RzPanel2: TRzPanel;
    TabSheet2: TRzTabSheet;
    RzGroupBox1: TRzGroupBox;
    RzPanel1: TRzPanel;
    Start_Run: TRzRadioButton;
    Start_No: TRzRadioButton;
    RzPanel3: TRzPanel;
    RzDBRadioGroup1: TRzDBRadioGroup;
    RzBitBtn2: TRzBitBtn;
    RzDBRadioGroup2: TRzDBRadioGroup;
    Shut_Down: TRzRadioButton;
    Close_No: TRzRadioButton;
    RzBitBtn1: TRzBitBtn;
    RzSeparator1: TRzSeparator;
    RzCheckBox1: TRzCheckBox;
    RzCheckBox2: TRzCheckBox;
    procedure RzBitBtn1Click(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

uses
    RunPg;

procedure TForm2.RzBitBtn1Click(Sender: TObject);
var
   iniFile : TIniFile;
   FileName,FileName1,FileName2 : string;
   List1 : TStringList;
   Time3,Time4 : Integer;
   str1,str2,str3 : string;
begin
   try
      Try
         FileName := ExtractFilePath(ParamStr(0)) + 'Config.ini';
         FileName1 := ExtractFilePath(ParamStr(0)) + 'Audio\' + 'hdatest.cfg';
         Filename2 := ExtractFilePath(ParamStr(0)) + '0.d';
         if not (FileExists(FileName) and FileExists(FileName1))  then
         begin
           MessageBox(0,'文件不存在,请把本程序放到测试程序目录下','错误', MB_OK + MB_ICONERROR);
           Exit;
         end;
         iniFile := TIniFile.Create(FileName);
         List1 := TStringList.Create;
         if Start_Run.Checked then
            iniFile.WriteInteger('ITEM_HEADER','AUTORUN',0);
         if Start_No.Checked then
                iniFile.WriteInteger('ITEM_HEADER','AUTORUN',1);
         if Shut_Down.Checked then
                iniFile.WriteInteger('ITEM_HEADER','ShutDown',0);
         if Close_No.Checked then
                iniFile.WriteInteger('ITEM_HEADER','ShutDown',1);

         Time3 := FileAge(FileName);
         Time4 := FileAge(FileName1);
         str3 := EncryStrHex(IntToStr(Time3 + Time4),'111111222');
         Str1 := EncryStrHex(IntToStr(Time3),'111111222');
         Str2 := EncryStrHex(IntToStr(Time4),'111111222');
         List1.Add(Str1);
         List1.Add(Str2);
         List1.Add(Str3);
         List1.SaveToFile(FileName2);
      except on E:Exception do begin
             List1.Free;
             iniFile.Destroy;
             MessageBox(0,PChar(E.Message),'错误',MB_OK+MB_ICONERROR);
             Exit;
         end;
      End;
      MessageBox(0,'保存成功!','提示',MB_OK+MB_ICONWARNING);
      List1.Free;
      iniFile.Destroy;
   finally

   end;
end;

procedure TForm2.RzBitBtn2Click(Sender: TObject);
var
   sTemp : string;
begin
   sTemp := '/SetDefault "扬声器" 1';
   if ShellExecute(0,nil,'SoundVolumeView.exe',PChar(STemp),nil,SW_HIDE) > 32 then
      MessageBox(0,'设置成功','提示信息',MB_OK + MB_ICONWARNING)
      else
          MessageBox(0,'设置失败','错误', MB_OK + MB_ICONWARNING);

end;

end.
