"""在 Config.ini 末尾追加音频回路测试的 Test_ITEM_17 段，并把 ITEM_NUM 16->17。

文件是 GBK + CRLF + 无 BOM，必须按原样保持，否则主工程读中文会乱码。
追加前先备份成 .bak_audiolooop。
"""
import os
import re
import shutil
import sys

SECTION = """
[Test_ITEM_17]
ITEM_NAME = 音频回路
UNIT_NUM = 1
UNIT_NAME_1 = 音频回路测试
//0为测试该项，非0为跳过
Enabled_1 = 1
UNIT_INDEX_1 = 1
"""


def update(path):
    if not os.path.exists(path):
        print("skip (not found):", path)
        return
    raw = open(path, "rb").read()
    text = raw.decode("gbk")

    if "[Test_ITEM_17]" in text:
        print("already has Test_ITEM_17:", path)
        return

    backup = path + ".bak_audiolooop"
    if not os.path.exists(backup):
        shutil.copy2(path, backup)
        print("backup ->", backup)

    # ITEM_NUM 16 -> 17
    text = re.sub(r"(?m)^ITEM_NUM\s*=\s*16\s*$", "ITEM_NUM = 17", text, count=1)

    # 追加段落，保持 CRLF
    if not text.endswith("\r\n"):
        text += "\r\n"
    text += SECTION.replace("\n", "\r\n")

    open(path, "wb").write(text.encode("gbk"))
    print("updated:", path)

    # 校验：能读回、中文不乱码、ITEM_NUM 已改
    back = open(path, "rb").read().decode("gbk")
    assert "[Test_ITEM_17]" in back, "section missing"
    assert "ITEM_NUM = 17" in back, "ITEM_NUM not bumped"
    assert "音频回路测试" in back, "chinese broken"
    assert b"\r\n" in open(path, "rb").read(), "CRLF lost"
    print("   verify OK")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        update(p)