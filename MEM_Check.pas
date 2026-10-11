unit MEM_Check;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, MemoryCpuUtils, Vcl.StdCtrls;

type
  TForm2 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}
Var      //声明下列变量用来存储读取的数值
    iTotalPhysics, iTotalVirtual, iTotalPageFile,
    iCurPhysics, iCurVirtual, iCurPageFile : DWord;
procedure TForm2.Button1Click(Sender: TObject);
var
 i : Integer;
begin
    //CPU数量
    Format('系统中共有 %d 个CPU中央存储器',[GetCPUCount]);
    //其中i表示获取第几个CPU的使用率
    //Format('CPU使用率为 #%d - %5.2f%%',[i,GetCPUUsage(i)*100]);
    //初始化OR读取各内存总量
    GetMemoryTotalSize(iTotalPhysics ,iTotalVirtual ,iTotalPageFile);
    //物理内存总量
    label1.Caption := InttoStr(iTotalPhysics) + ' MB';
    //虚拟内存总量
    Label2.Caption := IntToStr(Round(iTotalVirtual/1024/1024)) + ' MB';
    //页面内存(交换内存)总量
    Label3.Caption := InttoStr(Round(iTotalPageFile/1024/1024)) + ' MB';
    //读取各内存当前可用容量
    GetMemoryTotalSize(iCurPhysics,iCurVirtual,iCurPageFile);
    //物理内存可用容量
    Label4.Caption := InttoStr(Round(iCurPhysics/1024/1024)) + ' MB';
    //虚拟内存可用容量
    Label5.Caption := InttoStr(Round(iCurVirtual/1024/1024)) + ' MB';
    //页面内存(交换内存)可用容量
    Label6.Caption := InttoStr(Round(iCurPageFile/1024/1024)) + ' MB';
    //获取内存使用率
    Label7.Caption := Format('当前内存使用率为 %5.2f%%',[GetMemoryUsage]);
    //直接获取CPU厂商
    GetCPUVendor;

    //物理内存使用比
    Format('物理内存使用比为 %5.2f%%',[iCurPhysics/iTotalPhysics*100]);
    //虚拟内存使用比
    Format('虚拟内存使用比为 %5.2f%%',[iCurVirtual/iTotalVirtual*100]);
    //页面内存使用比
    Label8.Caption := Format('页面内存使用比为 %5.2f%%',[iCurPageFile/iTotalPageFile*100]);
end;

end.
