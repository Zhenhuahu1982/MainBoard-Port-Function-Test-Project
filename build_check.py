"""给新建的 Delphi 单元补 UTF-8 BOM，并可选编译验证。

Delphi 对没有 BOM 的 .pas 按系统 ANSI(GBK) 解析，中文注释会变成乱码并报
Warning: W1057 Implicit string cast from 'AnsiString' to 'string'。
"""
import os
import subprocess
import sys

DCC32 = r"D:\Program Files (x86)\Embarcadero\Studio\21.0\bin\dcc32.exe"
LIB = r"D:\Program Files (x86)\Embarcadero\Studio\21.0\lib\win32\release"


def add_bom(path):
    if not os.path.exists(path):
        print("missing:", path)
        return False
    data = open(path, "rb").read()
    if data[:3] == b"\xef\xbb\xbf":
        print("BOM ok  :", os.path.basename(path))
        return False
    open(path, "wb").write(b"\xef\xbb\xbf" + data)
    print("BOM add :", os.path.basename(path))
    return True


def compile_dpr(dpr, outdir=None):
    """编译一个 dpr，返回 (ok, stdout)。"""
    projdir = os.path.dirname(os.path.abspath(dpr))
    search = projdir if not outdir else outdir + ";" + projdir
    cmd = [
        DCC32, "-B", "-Q",
        "-U%s;%s" % (LIB, search),
        "-I%s;%s" % (LIB, search),
        "-R%s;%s" % (LIB, search),
        os.path.abspath(dpr),
    ]
    p = subprocess.run(cmd, capture_output=True, cwd=projdir)
    txt = p.stdout.decode("gbk", errors="replace") + p.stderr.decode("gbk", errors="replace")
    bad = [l for l in txt.splitlines()
           if "Error:" in l or "Fatal:" in l or "Warning:" in l or "W1057" in l]
    ok = not bad
    print("=" * 60)
    print("COMPILE", os.path.basename(dpr), "->", "OK" if ok else "FAILED")
    if bad:
        for l in bad:
            print("   ", l)
    else:
        for l in txt.splitlines():
            if "lines," in l:
                print("   ", l.strip())
    return ok, txt


if __name__ == "__main__":
    for f in sys.argv[1:]:
        if f.lower().endswith(".dpr"):
            ok, _ = compile_dpr(f)
            sys.exit(0 if ok else 1)
        else:
            add_bom(f)