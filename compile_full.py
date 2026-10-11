"""完整编译一个 dpr 并打印全部输出（不做错误过滤），用于排查奇怪的语法错误。"""
import os
import subprocess
import sys

DCC32 = r"D:\Program Files (x86)\Embarcadero\Studio\21.0\bin\dcc32.exe"
LIB = r"D:\Program Files (x86)\Embarcadero\Studio\21.0\lib\win32\release"


def main(dpr):
    projdir = os.path.dirname(os.path.abspath(dpr))
    cmd = [DCC32, "-B", "-U%s;%s" % (LIB, projdir),
           "-I%s;%s" % (LIB, projdir),
           "-R%s;%s" % (LIB, projdir),
           os.path.abspath(dpr)]
    p = subprocess.run(cmd, capture_output=True, cwd=projdir)
    out = p.stdout.decode("gbk", errors="replace")
    out += p.stderr.decode("gbk", errors="replace")
    print(out)


if __name__ == "__main__":
    main(sys.argv[1])