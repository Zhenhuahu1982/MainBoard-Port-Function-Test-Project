program _map;
{ 验证 AlFindInputDevice 是否按端口选对端点 }
{$APPTYPE CONSOLE}
uses AudioLoopCfg, AudioLoopDev;
var E: TAlAudioEnv; I: Integer; Idx: Integer; Nm, Why: string;
    Ports: array[0..3] of TAlInPort;
begin
  AlProbeAudioEnvironment(E);
  Ports[0] := aipMicRear;  Ports[1] := aipMicFront;
  Ports[2] := aipLineIn1; Ports[3] := aipLineIn2;
  for I := 0 to 3 do
  begin
    Idx := -1; Nm := ''; Why := '';
    if AlFindInputDevice(E, Ports[I], Idx, Nm, Why) then
      Writeln(AlInPortName(Ports[I]), '  ->  idx=', Idx, '  ', Nm)
    else
      Writeln(AlInPortName(Ports[I]), '  ->  失败: ', Why);
    if Why <> '' then Writeln('      提示: ', Why);
  end;
end.
