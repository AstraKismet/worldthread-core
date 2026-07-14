# 資料格式

## 通用規則

所有文字使用 UTF-8；路徑相對於範本根目錄。`game/reference/` 為來源真相，已發生的 `game/state/` 可優先覆蓋相衝突的來源。`game/private/director/` 永不進玩家可見敘事。

每個狀態 JSON（含 `game/state/` 各檔與前線檔）至少有：

```json
{"revision": 1, "updated_at": "1970-01-01T00:00:00Z"}
```

`updated_at` 採 ISO 8601（UTC、以 `Z` 結尾）。範本內建檔案中的 `1970-01-01T00:00:00Z` 是中性佔位值；開局複製後，由主持人在每次寫入時填入實際時間。寫入前重新讀取目標 `revision`；不符時先合併或請玩家決定，避免多主持人衝突。

## 事件日誌 `game/state/logs/events.jsonl`

每行一個不可變事件，必要鍵：`id`、`at`、`scene_id`、`kind`、`facts`、`visibility`。空檔表示尚無事件；解析時跳過空白行。不可改寫舊行。

- `visibility` 值域（全範本統一）：`public`（可公開）、`player`（玩家可知）、`director`（僅主持人可見）。
- `kind` 基礎值域：`fact`（確定事實）、`roll`（擲骰紀錄）、`correction`（修正）。規則書或模組可擴充新值，但不得改變基礎值的語意。

範例事件：

```json
{"id":"evt-0001","at":"1970-01-01T00:00:00Z","scene_id":"fog-ferry-opening","kind":"fact","facts":["鐘塔的鐘在黎明前失竊。"],"visibility":"player"}
```

修正事件以 `kind: "correction"`，並以 `corrects` 鍵指向原事件的 `id`；修正是追加，不是改寫：

```json
{"id":"evt-0009","at":"1970-01-01T00:00:00Z","scene_id":"fog-ferry-opening","kind":"correction","corrects":"evt-0007","facts":["更正：失竊的是鐘舌，鐘體仍在。"],"visibility":"player"}
```

## 擲骰紀錄

擲骰以 `kind: "roll"` 事件記入 `events.jsonl`，除通用鍵外包含：`formula`、`rolls`（各骰個別結果，依公式順序）、`modifier`（常數項含正負號之總和）、`result`（骰子總和加 `modifier`）、`source`、`rolled_at`，以及主持人裁定後補上的 `ruling`。

`source` 值域（信任等級由高至低）：

- `player`：玩家親自擲骰後回報。
- `tool`：程式擲骰工具輸出（`tools/dice.mjs` 與 `tools/dice.py` 皆屬此類；兩者輸出契約相同）。
- `agreed-random`：雙方事先約定的其他隨機程序。
- `ai`：主持人在無任何工具可用、玩家亦不自擲時自行產生的骰值。信任等級最低，僅限 `PLAYBOOK.md` 擲骰節的最終降級；必須據實標記，不得偽稱其他來源。

```json
{"id":"evt-0002","at":"1970-01-01T00:00:00Z","scene_id":"fog-ferry-opening","kind":"roll","formula":"2d6+3","rolls":[4,2],"modifier":3,"result":9,"source":"tool","rolled_at":"1970-01-01T00:00:00Z","ruling":"成功：你在鐘塔斷繩上找到銀色纖維。","facts":[],"visibility":"player"}
```

## 場景與 `scene_id`

場景檔位於 `game/reference/scenarios/`，必須以 YAML front matter 顯式宣告 `scene_id`：

```markdown
---
scene_id: fog-ferry-opening
---
```

事件的 `scene_id` 必須等於某個場景檔宣告的值；新增場景時先宣告、再引用。

## 角色 `game/state/character.json`

基線鍵：`revision`、`updated_at`、`name`、`concept`、`goals`、`fears`、`strengths`、`bonds`、`notes`。共同創角四問的對應：想追求→`goals`、怕失去→`fears`、擅長→`strengths`、牽絆→`bonds`。

角色卡欄位依玩家放入的規則書擴充：規則書要求的屬性、技能、資源等欄位，由主持人於開局時增列；增列欄位不得移除或改變基線鍵的語意。

## NPC 狀態

每個 NPC 一檔：`game/state/npcs/<npc-id>.json`（`npc-id` 用小寫連字號），狀態 JSON 通用規則（`revision`、`updated_at`、寫入前重讀）一體適用。

## 前線 `game/private/director/fronts/<front-id>.json`

前線屬狀態 JSON，必要鍵：`revision`、`updated_at`、`id`、`name`、`goal`、`resources`、`clocks`、`omens`、`next_reasonable_action`、`secret`。`clocks` 為陣列，每個時鐘含 `name`、`segments`、`current`（0 至 `segments` 的整數）。推進前線（修改 `current`）視同狀態寫入，適用重讀規則。
