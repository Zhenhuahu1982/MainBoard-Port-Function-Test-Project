unit Encrypt;

interface

uses
  SysUtils,Dialogs;

//标准DES加密
function  encryptcharBridge(buf:PChar ; buflen:Integer ; key:PChar):Integer;cdecl;external 'EncryptDecrypt.dll';
function  decryptcharBridge(buf:PChar ; buflen:Integer ; key:PChar):Integer;cdecl;external 'EncryptDecrypt.dll';

//字符串加密
procedure  StrEncrypt(PlaintextStr:string;KeyStr:string;CiphertextPChar:PChar);
procedure  StrDecrypt(CiphertextStr:string;KeyStr:string;PlaintextPChar:PChar);

implementation

procedure  StrEncrypt(PlaintextStr:string;KeyStr:string;CiphertextPChar:PChar);
var
   BufArray:array[0..2048] of char;
   BufPChar:pchar;
   PlaintextStrLen:Integer;

   KeyArray:array[0..50] of char;
   KeyPChar:pchar;

   BufLen:Integer;

   CiphertextStr:string;
begin
   PlaintextStrLen:=Length(PlaintextStr);

   BufPChar:=Pchar(@BufArray);
   StrPCopy(BufPChar,PlaintextStr);

   KeyPChar:=Pchar(@KeyArray);
   StrPCopy(KeyPChar,KeyStr);

   encryptcharBridge(BufPChar,PlaintextStrLen,KeyPChar);

   CiphertextStr:=string(BufPChar);//强转时，只会对结束符#0之前字符串强转
   StrPCopy(CiphertextPChar,CiphertextStr);//拷贝过去的字符串会自动在后面加结束符#0，所以原来的字符数组无需初始化

end;

procedure  StrDecrypt(CiphertextStr:string;KeyStr:string;PlaintextPChar:PChar);
var
   BufArray:array[0..2048] of char;
   BufPChar:pchar;
   CiphertextStrLen:Integer;

   KeyArray:array[0..50] of char;
   KeyPChar:pchar;

   BufLen:Integer;

   PlaintextStr:string;
begin
   CiphertextStrLen:=Length(CiphertextStr);

   BufPChar:=PChar(@BufArray);
   StrPCopy(BufPChar,CiphertextStr);

   KeyPChar:=Pchar(@KeyArray);
   StrPCopy(KeyPChar,KeyStr);

   decryptcharBridge(BufPChar,CiphertextStrLen,KeyPChar);

   PlaintextStr:=string(BufPChar);//强转时，只会对结束符#0之前字符串强转
   StrPCopy(PlaintextPChar,PlaintextStr);//拷贝过去的字符串会自动在后面加结束符#0，所以原来的字符数组无需初始化

end;


end.
