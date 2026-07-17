# extras／規則範例庫（staging）

本資料夾是**隨附的規則範例庫**：以開放授權（CC-BY 3.0）合法收錄的 Fate 規則全文，供你**擇一啟用**。它位於遊玩區 `game/` **之外**，因此**預設完全不參與主持與裁定**——主持人平時只讀 `game/` 之下的內容。預設的「霧渡口」範例不綁定系統（`game/reference/rules/lightweight-rulings.md`）。

| 規則範例 | 語言 | 結構 | 位置 |
| --- | --- | --- | --- |
| 命運核心版 Fate Core | 繁體中文 | 12 章＋索引 | [`fate-core-zh/`](fate-core-zh/README.md) |
| 命運快速版 FAE | 繁體中文 | 單檔（輕量） | [`fate-accelerated-zh/`](fate-accelerated-zh/README.md) |
| Fate Core System | English | 12 章＋索引 | [`fate-core-en/`](fate-core-en/README.md) |
| Fate Accelerated Edition | English | 單檔 | [`fate-accelerated-en/`](fate-accelerated-en/README.md) |
| Fate System Toolkit（設計參考） | English | 9 章＋索引 | [`fate-system-toolkit-en/`](fate-system-toolkit-en/README.md) |

**Fate System Toolkit 的定位不同**：它不是可啟用的規則系統，而是官方的 Fate 改造設計指南（自製魔法系統、載具／怪物／超能等子系統、規模與財富機制）。**不要**把它複製進 `game/reference/rules/` 當作裁定系統；主持人在玩家想把特定題材機制壓到 Fate 上、或裁定無前例可循時，把它當設計參考引用（引用時記入 `ruling`）。下方「擇一啟用」規則不適用於它。無繁中譯本。

## 如何啟用／替換（本節為唯一權威說明，其他檔案指向這裡）

多套完整規則系統**不應同時**放進遊玩區——技能制（Core）與行事風格制（FAE）互斥，混在一起會造成檢索污染與跨 session 不一致。因此請一次只啟用一套：

1. **選一套**，把整個資料夾（例如 `extras/fate-accelerated-zh/`）**複製**到 `game/reference/rules/` 之下。
2. **同時只留一套完整系統**：複製前，先移除 `game/reference/rules/` 內其他完整規則系統，只保留內附的 fallback 輕量裁定檔（目前為 `lightweight-rulings.md`）。換系統時，先刪舊的那套資料夾再複製新的。
3. **告訴主持人用哪套**：在 `game/session-brief.md` 的「規則系統」欄填該路徑即可，例如 `命運快速版 = game/reference/rules/fate-accelerated-zh/`。**只放一套時不需要 `priority.md`**；只有在你放了多本書、需要指定先後順序時，才寫 `game/reference/rules/priority.md`。
4. **開局**：對主持人送出 `game/session-brief.md` 的開局那一句。角色卡欄位可依 `protocol/DATA-SCHEMA.md` 擴充規則增列（基線鍵不動）。
5. **擲骰**：本包 `tools/dice.mjs`／`tools/dice.py` 支援 `NdM`、**不支援** `dF`；用命運骰時執行 `node tools/dice.mjs 4d6`，每顆 5–6 記 `+`、3–4 記 `0`、1–2 記 `−`，四顆相加即結果，並逐字引用原始骰值；或改用實體命運骰。

> 為什麼是「複製進去」而非預先放好？把每套完整系統都預置在遊玩區，會讓主持人的檢索同時撈到互斥系統、續玩時容易出錯。擇一複製能結構性地保證「同時只有一套」。

## 中英替換

中英是同一套規則的兩種語言：把 `fate-core-en/` 換成 `fate-core-zh/`（或反之）即切換語言，作法同上——複製你要的那個目錄進 `game/reference/rules/`、移除另一個，並更新 `game/session-brief.md` 的「規則系統」欄。

## 授權

`extras/` 內全部採 **CC-BY 3.0**，只含文字、不含商標 logo／字型／骰面圖像。再散布須保留規定標示——完整條款見各子資料夾 `README.md` 與發行包根目錄 [`THIRD-PARTY-NOTICES.md`](../THIRD-PARTY-NOTICES.md)。

每個內容檔檔首附 **YAML frontmatter**（`source`／`license`／`attribution`／`modified`）：依 `protocol/RAG-PROTOCOL.md`，主持人建 RAG 分塊時由此繼承授權欄位，使衍生快取仍可追溯來源與授權。

關於本包為何把核心版拆成 12 章、快速版維持單檔（以及你自己的規則書該不該拆章），見 [`../ADDING-RULEBOOKS.md`](../ADDING-RULEBOOKS.md) 的〈拆章基準〉。
