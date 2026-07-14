# 可攜檢索協定

`game/rag/` 是可再生快取，不是唯一真相。每個分塊有穩定 `id`、`source`、`tags`、`visibility`（`public`、`player`、`director`）、`summary` 與 `updated_at`。檢索只可在同等或更低權限範圍內進行：玩家回覆不得使用 director 分塊的祕密。

重建時掃描 `reference/`、`state/`、`private/director/`，保留來源相對路徑。先以關鍵字／標籤取得候選，再讀取原檔確認上下文。刪除 `rag/` 不得損失任何遊戲事實。
