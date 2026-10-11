program _env;
{$APPTYPE CONSOLE}
uses AudioLoopCfg, AudioLoopDev;
var E: TAlAudioEnv; I: Integer;
begin
  AlProbeAudioEnvironment(E);
  Writeln('输入端点数=', Length(E.InDevices));
  for I := 0 to High(E.InDevices) do
    Writeln('  [', I, '] idx=', E.InDevices[I].Index, ' name=', E.InDevices[I].Name);
  Writeln('默认输入序号=', E.DefaultInIdx);
  Writeln('输出端点数=', Length(E.OutDevices));
  for I := 0 to High(E.OutDevices) do
    Writeln('  [', I, '] idx=', E.OutDevices[I].Index, ' name=', E.OutDevices[I].Name);
  Writeln('jack支持=', E.JackSupported);
  Writeln(E.Info);
end.
