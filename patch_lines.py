"""按行号区间替换 .pas 文件内容（BOM 与 CRLF 保持原样）。"""
import sys


def main():
    path = sys.argv[1]
    start = int(sys.argv[2])   # 1-indexed, inclusive
    end = int(sys.argv[3])     # 1-indexed, inclusive
    newfile = sys.argv[4]

    raw = open(path, "rb").read()
    bom = b""
    if raw[:3] == b"\xef\xbb\xbf":
        bom = raw[:3]
        raw = raw[3:]

    crlf = b"\r\n" in raw
    text = raw.decode("utf-8").replace("\r\n", "\n")
    lines = text.split("\n")

    repl = open(newfile, encoding="utf-8").read().replace("\r\n", "\n")
    if repl.endswith("\n"):
        repl = repl[:-1]
    repl_lines = repl.split("\n")

    new_lines = lines[: start - 1] + repl_lines + lines[end:]
    out = "\n".join(new_lines)
    data = out.encode("utf-8")
    if crlf:
        data = data.replace(b"\n", b"\r\n")
    open(path, "wb").write(bom + data)
    print("replaced lines %d-%d of %s (%d lines -> %d)"
          % (start, end, path, len(lines), len(new_lines)))


if __name__ == "__main__":
    main()