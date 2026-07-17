# Worldthread 擲骰工具：解析擲骰公式並以密碼學級亂數擲骰，輸出單行 JSON 供事件紀錄使用。
# 零依賴：僅使用 Python 標準庫。相容 Python 3.8+。
# 與 tools/dice.mjs 共用同一份輸出契約：同公式同 --seed 時，兩支工具的輸出逐位元一致，
# 可互為對照組（契約由 tools/dice.fixtures.jsonl 鎖定）。
import hashlib
import json
import re
import secrets
import sys
from datetime import datetime, timezone

HELP = """用法：python dice.py <公式> [--seed <字串>]

公式文法：expr := term (('+'|'-') term)*；term := dice | int
  dice := [N]dM（如 2d6、d20；N 為 1..100 的整數，省略為 1；M 為 2..1000 的整數；d 不分大小寫）
  int  := 0..9999 的整數常數
  減號只能出現在整數常數前；骰組僅支援相加（例：2d6-1d4 不合法）。
  公式內允許任意空白，其餘任何內容一律視為錯誤。

選項：
  --seed <字串>  測試夾具專用：以固定演算法產生決定性亂數結果，並非公平擲骰；
                 輸出會多一個 "seed" 鍵使測試骰可被辨識，時間戳固定為中性佔位值。
  --help         顯示本說明並結束。

信任邊界：本工具以密碼學級亂數擲骰；主持人須逐字引用輸出，改寫數值即可被比對發現。
工具無法防止使用者自行修改結果。
"""


def write_out(text):
    # 直接寫位元組：避免 Windows 文字模式把 \n 轉成 \r\n、或主控台編碼非 UTF-8，
    # 確保輸出與 dice.mjs 逐位元一致。
    sys.stdout.buffer.write(text.encode("utf-8"))
    sys.stdout.buffer.flush()


def fail(message):
    sys.stderr.buffer.write((message + "\n").encode("utf-8"))
    sys.stderr.buffer.flush()
    sys.exit(1)


# 與 dice.mjs 的 JS 正規表達式語意對齊：空白用 JS \s 的集合（含 U+FEFF BOM、不含 \x1c-\x1f 與 NEL \x85）；
# 數字一律 [0-9]（Python 的 \d 會收全形數字，JS 不會）。
JS_WHITESPACE = "[\t\n\v\f\r \u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]"


# 解析公式：先去除空白並轉小寫，再以指標掃描 term/運算子序列。
def parse_formula(raw):
    cleaned = re.sub(JS_WHITESPACE + "+", "", raw).lower()
    if len(cleaned) == 0:
        raise ValueError("錯誤：公式不得為空。")
    if cleaned[0] in "+-":
        raise ValueError("錯誤：公式開頭不得為運算符號。")

    pos = [0]
    format_error = ValueError("錯誤：公式格式錯誤，請使用如 2d6+3 的格式。")

    def assert_no_leading_zero(digits):
        if len(digits) > 1 and digits[0] == "0":
            raise ValueError("錯誤：數字不得有前導零。")

    def read_term():
        i = pos[0]
        lead = re.match(r"[0-9]*", cleaned[i:]).group(0)
        if i + len(lead) < len(cleaned) and cleaned[i + len(lead)] == "d":
            if lead != "":
                assert_no_leading_zero(lead)
            pos[0] = i + len(lead) + 1
            faces = re.match(r"[0-9]+", cleaned[pos[0]:])
            if not faces:
                raise ValueError("錯誤：骰組格式錯誤，需為 [N]d骰面數，例如 2d6。")
            assert_no_leading_zero(faces.group(0))
            pos[0] += len(faces.group(0))
            n = 1 if lead == "" else int(lead)
            m = int(faces.group(0))
            if not (1 <= n <= 100):
                raise ValueError("錯誤：骰數（N）需為 1 至 100 的整數。")
            if not (2 <= m <= 1000):
                raise ValueError("錯誤：骰面數（M）需為 2 至 1000 的整數。")
            return {"type": "dice", "n": n, "m": m}
        num = re.match(r"[0-9]+", cleaned[i:])
        if not num:
            raise format_error
        assert_no_leading_zero(num.group(0))
        pos[0] = i + len(num.group(0))
        v = int(num.group(0))
        if not (0 <= v <= 9999):
            raise ValueError("錯誤：整數常數需為 0 至 9999。")
        return {"type": "int", "value": v}

    first = read_term()
    first["sign"] = 1
    terms = [first]
    while pos[0] < len(cleaned):
        op = cleaned[pos[0]]
        if op not in "+-":
            raise format_error
        pos[0] += 1
        term = read_term()
        if op == "-" and term["type"] == "dice":
            raise ValueError("錯誤：骰組僅支援相加，減號只能用於整數常數前。")
        term["sign"] = -1 if op == "-" else 1
        terms.append(term)
    return {"normalized": cleaned, "terms": terms}


# 以 SHA-256(seed + ':' + 遞增計數器) 之位元組流做拒絕取樣，避免 modulo bias；僅供測試夾具使用，非公平擲骰。
def seeded_roll(seed, counter, max_faces):
    limit = (65536 // max_faces) * max_faces
    while True:
        digest = hashlib.sha256("{0}:{1}".format(seed, counter[0]).encode("utf-8")).digest()
        counter[0] += 1
        v = int.from_bytes(digest[:2], "big")
        if v < limit:
            return (v % max_faces) + 1


def parse_args(argv):
    formula = None
    seed = None
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--seed":
            if i + 1 >= len(argv):
                fail("錯誤：--seed 需要提供字串值。")
            seed = argv[i + 1]
            i += 1
        elif a.startswith("--"):
            fail("錯誤：未知參數：{0}".format(a))
        elif formula is None:
            formula = a
        else:
            fail("錯誤：只能提供一個擲骰公式。")
        i += 1
    if formula is None:
        fail("錯誤：請提供擲骰公式，例如 2d6+3（可用 --help 查看說明）。")
    return formula, seed


def main():
    argv = sys.argv[1:]
    if "--help" in argv or "-h" in argv:
        write_out(HELP)
        return
    formula, seed = parse_args(argv)

    try:
        parsed = parse_formula(formula)
    except ValueError as e:
        fail(str(e))
        return

    rolls = []
    modifier = 0
    counter = [0]
    for term in parsed["terms"]:
        if term["type"] == "dice":
            for _ in range(term["n"]):
                if seed is not None:
                    rolls.append(seeded_roll(seed, counter, term["m"]))
                else:
                    rolls.append(secrets.randbelow(term["m"]) + 1)
        else:
            modifier += term["sign"] * term["value"]
    result = sum(rolls) + modifier

    output = {
        "formula": parsed["normalized"],
        "rolls": rolls,
        "modifier": modifier,
        "result": result,
        "source": "tool",
    }
    if seed is not None:
        output["seed"] = seed
    # seed 模式固定時間戳，讓同 seed 同公式的輸出可逐字元比對（黃金行測試）。
    if seed is not None:
        output["rolled_at"] = "1970-01-01T00:00:00.000Z"
    else:
        now = datetime.now(timezone.utc)
        output["rolled_at"] = "{0}.{1:03d}Z".format(now.strftime("%Y-%m-%dT%H:%M:%S"), now.microsecond // 1000)
    write_out(json.dumps(output, ensure_ascii=False, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    main()
