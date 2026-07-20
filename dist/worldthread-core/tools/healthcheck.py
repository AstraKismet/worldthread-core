# Worldthread 狀態健檢工具：遞迴掃描目錄下的 .json/.jsonl，逐檔回報是否可解析。
# 零依賴：僅使用 Python 標準庫。相容 Python 3.8+。
# 與 tools/healthcheck.mjs 共用同一份輸出契約：同一目錄樹兩支工具的輸出逐位元一致，
# 可互為對照組（契約由 tools/healthcheck.fixtures.jsonl 鎖定）。僅讀取、不修改任何檔案。
# 契約範圍：目標樹為一般檔案與目錄；符號連結一律略過、無法讀取的項目略過而非中止
# （game/state 正常情況下不含符號連結，兩支工具在此範圍內逐位元一致）。
import json
import os
import sys

HELP = """用法：python healthcheck.py [路徑]

  遞迴掃描 [路徑]（省略時預設 game/state）下所有 .json 與 .jsonl 檔，
  逐檔輸出一行 JSON 回報是否可解析，末行輸出彙總；路徑亦可為單一檔案。
  同時檢查玩家可見檔是否夾帶導演私有檔的識別字串（見下）。
  任何檔案未通過時結束碼為 1，全部通過為 0。

輸出每行：{"file":<相對路徑>,"kind":"json"|"jsonl","ok":<布林>,"line":<行號|null>,"leak":<字串|null>}
  line 僅 .jsonl 解析失敗時給出第一個壞行的 1-based 行號，其餘為 null。
  leak 為命中的私有識別字串，未命中為 null。
末行：{"summary":{"scanned":N,"ok":N,"failed":N}}

私有識別字串檢查：
  依 DATA-SCHEMA〈主持人操作日誌〉，game/private/director/ 底下任何檔案的存在、
  檔名與紀錄 id 都不得出現在玩家可見輸出。逐檔判定：位於 game/private/ 或 tools/
  之內的檔案略過本檢查（私有檔本來就會提及自己；夾具檔以 marker 字面為測試資料）。

選項：
  --help  顯示本說明並結束。

本工具僅讀取、不修改任何檔案；它是輔助自查、非寫入驗證的替代（見 PLAYBOOK〈每回合〉第 5 步）。
"""

# 導演私有檔的識別字串：出現在玩家可見檔即違反公私分層（DATA-SCHEMA〈主持人操作日誌〉）。
PRIVATE_MARKERS = ["host-log", "hlog-", "campaign-arc", "hook-market", "fronts/", "private/director"]


# 這些位置提及私有檔名屬正常，不套用上述檢查：
# game/private/ 內的私有檔本來就會提及自己；tools/ 內的夾具檔以 marker 字面為測試資料。
def leak_exempt(abs_path):
    norm = "/" + os.path.abspath(abs_path).replace(os.sep, "/") + "/"
    return "/game/private/" in norm or "/tools/" in norm


def write_out(text):
    # 直接寫位元組：避免 Windows 文字模式把 \n 轉成 \r\n，確保輸出與 healthcheck.mjs 逐位元一致。
    sys.stdout.buffer.write(text.encode("utf-8"))
    sys.stdout.buffer.flush()


def fail(message):
    sys.stderr.buffer.write((message + "\n").encode("utf-8"))
    sys.stderr.buffer.flush()
    sys.exit(1)


# 遞迴收集 .json/.jsonl，回傳 [{abs, rel}]，依 rel（相對於 root 的正斜線路徑）排序。
# 符號連結一律略過（不追蹤目錄符號連結、也不納入檔案符號連結），與 healthcheck.mjs 行為對齊。
def collect(root):
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(
            d for d in dirnames if not os.path.islink(os.path.join(dirpath, d))
        )
        for name in sorted(filenames):
            full = os.path.join(dirpath, name)
            if os.path.islink(full):
                continue
            if name.endswith(".json") or name.endswith(".jsonl"):
                files.append(full)
    entries = [{"abs": f, "rel": os.path.relpath(f, root).replace(os.sep, "/")} for f in files]
    entries.sort(key=lambda e: e["rel"])
    return entries


# 檢查單一檔案，回傳 {kind, ok, line, leak}。
# check_leak 為 False 時（該檔位於 game/private/ 或 tools/ 內）略過私有字串檢查。
def check(abs_path, check_leak):
    kind = "jsonl" if abs_path.endswith(".jsonl") else "json"
    try:
        with open(abs_path, "r", encoding="utf-8") as handle:
            text = handle.read()
    except Exception:
        return {"kind": kind, "ok": False, "line": None, "leak": None}
    leak = None
    if check_leak:
        for marker in PRIVATE_MARKERS:
            if marker in text:
                leak = marker
                break
    if kind == "jsonl":
        lines = text.split("\n")
        for i, raw in enumerate(lines):
            line = raw[:-1] if raw.endswith("\r") else raw
            if line.strip() == "":
                continue
            try:
                json.loads(line)
            except Exception:
                return {"kind": kind, "ok": False, "line": i + 1, "leak": leak}
        return {"kind": kind, "ok": leak is None, "line": None, "leak": leak}
    try:
        json.loads(text)
        return {"kind": kind, "ok": leak is None, "line": None, "leak": leak}
    except Exception:
        return {"kind": kind, "ok": False, "line": None, "leak": leak}


def dumps(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def main():
    argv = sys.argv[1:]
    if "--help" in argv or "-h" in argv:
        write_out(HELP)
        return
    for a in argv:
        if a.startswith("-"):
            fail("錯誤：未知參數：{0}".format(a))
    if len(argv) > 1:
        fail("錯誤：只能提供一個路徑。")
    target = argv[0] if len(argv) == 1 else "game/state"

    if not os.path.exists(target):
        fail("錯誤：路徑不存在：{0}".format(target))

    if os.path.isdir(target):
        entries = collect(target)
    else:
        entries = [{"abs": target, "rel": os.path.basename(target)}]

    ok = 0
    failed = 0
    out = []
    for e in entries:
        # 逐檔判定豁免：祖先目錄掃描時，私有檔與夾具檔仍各自豁免。
        r = check(e["abs"], not leak_exempt(e["abs"]))
        if r["ok"]:
            ok += 1
        else:
            failed += 1
        out.append(
            dumps(
                {
                    "file": e["rel"],
                    "kind": r["kind"],
                    "ok": r["ok"],
                    "line": r["line"],
                    "leak": r["leak"],
                }
            )
        )
    out.append(dumps({"summary": {"scanned": len(entries), "ok": ok, "failed": failed}}))
    write_out("\n".join(out) + "\n")
    sys.exit(1 if failed > 0 else 0)


if __name__ == "__main__":
    main()
