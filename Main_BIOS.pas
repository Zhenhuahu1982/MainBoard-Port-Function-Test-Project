unit Main_BIOS;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Win.Registry, Vcl.StdCtrls, ActiveX, Comobj,
  System.AnsiStrings;

type
  TFrm_BIOS = class(TForm)
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    function ReadBiosVal : String;
    function GetWMIProperty(WMIType, WMIProperty:AnsiString):String;
    function GetBIOSInfoViaWMI: string;
var
  public
    { Public declarations }
  end;

var
  Frm_BIOS: TFrm_BIOS;

implementation

{$R *.dfm}

procedure TFrm_BIOS.FormCreate(Sender: TObject);
begin
     Edit1.Text := ReadBiosVal;
     Edit1.Text := LeftStr(GetWMIProperty('BIOS','ReleaseDate'),8);
    // Edit1.Text := GetBIOSInfoViaWMI;
end;

function TFrm_BIOS.ReadBiosVal : String;
var
  reg : TRegistry;
  sLMKey : string;
  sCurStr : string;
  sName : String;
begin
  Result := '';
  sLMKey := '\HARDWARE\DESCRIPTION\System\BIOS\';  //环境变量保存在注册表的这个位置
  sName := 'BIOSReleaseDate'; //我们要读取的环境变量
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if reg.OpenKey(sLMKey,False) then
    begin
      sCurStr := reg.ReadString(sName); //读取环境变量
      sCurStr := Trim(sCurStr);
      Result := sCurStr;
      reg.CloseKey;
    end;
  except
    on E: Exception do
    begin
      reg.Free;
      ShowMessage('Error: ' + E.Message);
      Exit;
    end;
  end;
  reg.Free;
end;

function TFrm_BIOS.GetWMIProperty(WMIType, WMIProperty:AnsiString):String;
var
  Wmi, Objs, Obj: oleVariant;
  Enum: IEnumVariant;
  C: Cardinal;
begin
  Wmi:= CreateOleObject('WbemScripting.SWbemLocator');
  Objs := Wmi.ConnectServer('.','root/cimv2').ExecQuery('Select * from Win32_' + WMIType);
  Enum := IEnumVariant(IUnknown(Objs._NewEnum));
  Enum.Reset;
  Enum.Next(1,Obj,C);

      Obj := Obj.Properties_.Item(WMIProperty, 0).Value;

      if VarIsNull(obj) then
      begin
        Result:='Error';
      end;

      if VarIsArray(obj) then
      begin
        Result := Obj[0];
      end;

      if VarIsStr(obj) or VarIsCustom(obj) or VarIsFloat(obj) or VarIsNumeric(obj) or VarIsOrdinal(obj) then
      begin
        Result:= Obj;
      end;

end;

function TFrm_BIOS.GetBIOSInfoViaWMI: string;
var
  objWMIService: OleVariant;
  colItems: OleVariant;
  colItem: OleVariant;
  oEnum: IEnumVariant;
  iValue: LongWord;
begin
  Result := '';
  CoInitialize(nil); // 初始化 COM
  try
    // 正确方式：先创建 SWbemLocator 对象，再调用 ConnectServer
    objWMIService := CreateOleObject('WbemScripting.SWbemLocator');
    objWMIService := objWMIService.ConnectServer('', 'root\cimv2', '', ''); // 本地计算机

    colItems := objWMIService.ExecQuery('SELECT * FROM Win32_BIOS', 'WQL', 0);
    oEnum := IUnknown(colItems._NewEnum) as IEnumVariant;

    while oEnum.Next(1, colItem, iValue) = 0 do
    begin
      Result := VarToStr(colItem.Caption);
     // Result := Result + '版本: ' + VarToStr(colItem.Version) + #13#10;
     // Result := Result + '发布日期: ' + VarToStr(colItem.ReleaseDate) + #13#10;
     // Result := Result + 'SMBIOS 版本: ' + VarToStr(colItem.SMBIOSBIOSVersion) + #13#10;
      Break; // 通常只有一个 BIOS 记录
    end;
  finally
    CoUninitialize;
  end;
end;

end.
