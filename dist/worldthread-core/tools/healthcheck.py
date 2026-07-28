# Worldthread 狀態健檢工具：遞迴掃描目錄下的 .json/.jsonl，逐檔回報是否可解析。
# 零依賴：僅使用 Python 標準庫。相容 Python 3.8+。
# 與 tools/healthcheck.mjs 共用同一份輸出契約：同一目錄樹兩支工具的輸出逐位元一致，
# 可互為對照組（契約由 tools/healthcheck.fixtures.jsonl 鎖定）。僅讀取、不修改任何檔案。
# 契約範圍：目標樹為一般檔案與目錄；符號連結一律略過、無法讀取的項目略過而非中止
# （game/state 正常情況下不含符號連結，兩支工具在此範圍內逐位元一致）。
# 發行包根上溯（find_base）的契約範圍：於 POSIX 根、Windows 磁碟根與一般 UNC 根
# （\\server\share）皆會終止；\\?\UNC\ 延伸路徑的走訪深度兩支實作不同，但在其上找不到
# template.json 時 base 結果仍相同，故不產生輸出差異。豁免比對前提是 base 必為掃描目標
# 的祖先（故與檔案同磁碟）——若日後允許外部指定 base，須先補跨磁碟的雙實作契約案例：
# path.relative 會回傳絕對路徑，而 os.path.relpath 會丟 ValueError。
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
  檔名與紀錄 id 都不得出現在玩家可見輸出。逐檔判定，且**錨定在發行包根**：只有
  發行包根底下的 game/private/、tools/、example-campaign/ 三個目錄之內的檔案略過
  本檢查（私有檔與隨包範例導演素材本來就會提及自己；夾具檔以 marker 字面為測試
  資料）。發行包根＝自掃描目標往上尋找到的第一個含 template.json 的目錄；找不到
  時退回以掃描起點為基準（掃描目標為單一檔案時＝該檔所在目錄）。
  往上不以絕對路徑比對，因為發行包會被解壓到任意位置、祖先目錄名不受控（例如整包
  放在名為 tools 的資料夾下，絕對路徑比對會讓整棵樹靜默豁免＝隱私偽陰性）；往下
  豁免不遞及更深層的同名目錄（自建的 game/state/tools/ 底下照樣會被檢查）。

路徑語意：
  路徑不存在 → 結束碼 1 並於 stderr 報錯；路徑存在但其下無可掃檔案 → 結束碼 0
  且彙總為 {"scanned":0,...}。兩者可據此區分，供自動化盲跑使用。

選項：
  --help  顯示本說明並結束。

本工具僅讀取、不修改任何檔案；它是輔助自查、非寫入驗證的替代（見 PLAYBOOK〈每回合〉第 5 步）。
"""

# 導演私有檔的識別字串：出現在玩家可見檔即違反公私分層（DATA-SCHEMA〈主持人操作日誌〉）。
PRIVATE_MARKERS = ["host-log", "hlog-", "campaign-arc", "hook-market", "fronts/", "private/director"]


# 這些位置提及私有檔名屬正常，不套用上述檢查：game/private/ 內的私有檔本來就會提及
# 自己；tools/ 內的夾具檔以 marker 字面為測試資料；example-campaign/ 是隨包出貨的範例
# 導演素材，與私有素材同等待遇（見 PLAYBOOK〈狀態健檢〉）。
EXEMPT_SEGMENTS = ["/game/private/", "/tools/", "/example-campaign/"]


# 發行包根＝自 start_dir 往上第一個含 template.json 的目錄；找不到則回傳 fallback。
# 豁免必須以發行包根為基準：發行包會被解壓到任意位置，用絕對路徑比對時祖先目錄名
# （例如某層剛好叫 tools）會讓整棵樹靜默豁免，形成隱私偽陰性。
def find_base(start_dir, fallback):
    d = os.path.abspath(start_dir)
    while True:
        if os.path.isfile(os.path.join(d, "template.json")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return os.path.abspath(fallback)
        d = parent


# 前綴錨定（startswith）而非任意位置比對：豁免的是「發行包根底下這三個目錄」，不是
# 「路徑裡任何一層叫這個名字」。用任意位置比對時，玩家自建的 game/state/tools/ 會讓
# 其下檔案靜默豁免——那是玩家可寫區，正是最需要檢查的地方。
def leak_exempt(abs_path, base):
    rel = os.path.relpath(os.path.abspath(abs_path), base).replace(os.sep, "/")
    norm = "/" + rel + "/"
    for seg in EXEMPT_SEGMENTS:
        if norm.startswith(seg):
            return True
    return False


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
# check_leak 為 False 時（該檔相對發行包根落在 EXEMPT_SEGMENTS 之內）略過私有字串檢查。
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
        start_dir = target
    else:
        entries = [{"abs": target, "rel": os.path.basename(target)}]
        start_dir = os.path.dirname(os.path.abspath(target))

    # 豁免基準：目標為檔案時自其所在目錄起算；找不到發行包根時退回掃描起點。
    base = find_base(start_dir, start_dir)

    ok = 0
    failed = 0
    out = []
    for e in entries:
        # 逐檔判定豁免：祖先目錄掃描時，私有檔與夾具檔仍各自豁免。
        r = check(e["abs"], not leak_exempt(e["abs"], base))
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
