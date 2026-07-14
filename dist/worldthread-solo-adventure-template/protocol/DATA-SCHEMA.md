# 資料格式

所有文字使用 UTF-8；路徑相對於範本根目錄。`reference/` 為來源真相，已發生的 `state/` 可優先覆蓋相衝突的來源。`private/director/` 永不進玩家可見敘事。每個狀態 JSON 至少有：

```json
{"revision": 1, "updated_at": "2026-07-14T00:00:00Z"}
```

`events.jsonl` 每行一個不可變事件：`id`、`at`、`scene_id`、`kind`、`facts`、`visibility`。修正事件以 `kind: "correction"` 並指向原事件 ID；不可改寫舊行。

範例事件：

```json
{"id":"evt-0001","at":"2026-07-14T00:00:00Z","scene_id":"fog-ferry-opening","kind":"fact","facts":["鐘塔的鐘在黎明前失竊。"],"visibility":"player"}
```

寫入前重新讀取目標 revision；不符時先合併或請玩家決定，避免多主持人衝突。骰子記錄包含 `formula`、`result`、`source`（`player`、`tool` 或 `agreed-random`）及裁定。
