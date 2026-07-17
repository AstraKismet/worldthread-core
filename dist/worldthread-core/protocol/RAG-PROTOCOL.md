# 可攜檢索協定

`game/rag/` 是可再生快取，不是唯一真相。每個分塊有穩定 `id`、`source`、`tags`、`visibility`（`public`、`player`、`director`）、`summary` 與 `updated_at`。選配鍵 `license`、`attribution`、`modified`：來源素材具授權標示義務（如 CC BY）時隨分塊保留，使衍生資料仍可追溯來源與授權；來源檔檔首有 YAML frontmatter 同名欄位（如 `extras/` 隨附規則與依 `ADDING-RULEBOOKS.md` 轉出的檔案）時，分塊直接繼承之。檢索只可在同等或更低權限範圍內進行：玩家回覆不得使用 director 分塊的祕密。

重建時掃描 `game/reference/`、`game/state/`、`game/private/director/`，保留來源相對路徑。先以關鍵字／標籤取得候選，再讀取原檔確認上下文。刪除 `game/rag/` 不得損失任何遊戲事實。

## 原則條文

- **失效判準**：分塊的 `updated_at` 早於其來源檔案的最後更新即視為失效；失效分塊不得直接引用，必須回讀原檔（或重建該分塊後再用）。
- **降級原則**：`game/rag/` 不存在或不可用時，一律直接檢索原檔。快取只是加速層，其缺席不得改變任何行為結果。
- **visibility 繼承**：分塊的 `visibility` 繼承其來源——`game/private/director/` 來源一律 `director`；混合可見度檔案（如 `game/state/logs/events.jsonl`）逐行歸屬，不得整檔套用單一值。無法判定歸屬時一律標 `director`（寧嚴勿寬：標錯即洩密）。
- **重建屬私下作業**：建立、更新或重建快取比照 `PLAYBOOK.md`〈敘事沉浸分層〉，不對玩家陳述過程。
