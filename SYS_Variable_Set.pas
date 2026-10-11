unit SYS_Variable_Set;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,System.Win.Registry, Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
var
  reg : TRegistry;
  sLMKey : string;
  sCurStr : string;
  sStrToAdd: string;
  sName : String;

begin
  sLMKey := '\System\CurrentControlSet\Control\Session Manager\Environment';  //环境变量保存在注册表的这个位置
  sName := Trim(Edit1.Text); //我们要修改的是Path环境变量
  sStrToAdd := Trim(Edit2.Text); //要添加的环境变量
  if (sName <> '') and (sStrToAdd <> '') then
  begin
    try
      reg := TRegistry.Create;
      try
          reg.RootKey := HKEY_LOCAL_MACHINE;
          if reg.OpenKey(sLMKey,False) then
          begin
              sCurStr := reg.ReadString(sName); //读取环境变量
              sCurStr := Trim(sCurStr);
              sStrToAdd := Trim(sStrToAdd);
              if Pos(sStrToAdd,sCurStr) = 0 then  //判断此环境变量是否已经存在
              begin
                sCurStr := sCurStr + sStrToAdd;  //把'C:/Ora_Cli/bin'这个值加入到环境变量的最后

                {网上看到的方法都是用WriteString这个函数来写Path环境变量， 可是我用了就有问题
                 用了这个函数后，系统对%systemroot%,这带%的变量就不翻译了，有很多命令如ping就不能用了，
                 会说ping不是可执行命令等等，后来经高手提醒说：用WriteExpandString就没问题了。
                 看了Delphi的帮助，有这么一句：
                 Call WriteExpandString to store a string that contains unexpanded references to environment variables such as %PATH%
                }
                //reg.WriteString(sName,sCurStr);   //用这句就有问题
                reg.WriteExpandString(sName,sStrToAdd);  //把值写到注册表里
                reg.CloseKey;
                SetEnvironmentVariable(PChar(sName),PChar(sCurStr));//更新当前进程的环境变量
                SendMessage(HWND_BROADCAST,WM_SETTINGCHANGE,0,Integer(PChar('Environment'))); //通知所有上层窗口，环境参数变化
                ShowMessage('设置成功');
              end;
          end;
      except
        on E: Exception do
        begin
            ShowMessage('Error: ' + E.Message);
            Exit;
        end;
      end;
    finally
      reg.Free;
    end;
  end
  else
  begin
    Messagebox(0,'注册表键或者值不能为空!','错误',MB_ICONHAND+MB_OK);
  end;
end;

procedure TForm2.Button2Click(Sender: TObject);
var
  reg : TRegistry;
  sLMKey : string;
  sCurStr : string;
  sStrToAdd: string;
  sName : String;
begin
  sLMKey := '\System\CurrentControlSet\Control\Session Manager\Environment';  //环境变量保存在注册表的这个位置
  sName := Trim(Edit1.Text); //我们要修改的是Path环境变量
  sStrToAdd := Trim(Edit2.Text); //要添加的环境变量
  if sName <> '' then
  begin
    try
      reg := TRegistry.Create;
      try
          reg.RootKey := HKEY_LOCAL_MACHINE;
          if reg.OpenKey(sLMKey,False) then
          begin
              sCurStr := reg.ReadString(sName); //读取环境变量
              sCurStr := Trim(sCurStr);
              //sStrToAdd := Trim(sStrToAdd);

              MessageBox(0,PWideChar('注册表键: ' + sName + ' 的值是: ' + sCurStr),'查询信息',0);
          end;
      except
        on E: Exception do
        begin
            ShowMessage('Error: ' + E.Message);
            Exit;
        end;
      end;
    finally
      reg.Free;
    end;
  end
  else
  begin
    //ShowMessage('');
    MessageBox(0,'请输入要查询的注册表环境变量','错误',MB_ICONHAND+MB_OK);
  end;
end;

end.
