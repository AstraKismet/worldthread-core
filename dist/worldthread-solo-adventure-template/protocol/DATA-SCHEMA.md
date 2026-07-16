# 資料格式

## 通用規則

所有文字使用 UTF-8；路徑相對於範本根目錄。`game/reference/` 為來源真相，已發生的 `game/state/` 可優先覆蓋相衝突的來源。`game/private/director/` 永不進玩家可見敘事。

每個狀態 JSON（含 `game/state/` 各檔與前線檔）至少有：

```json
{"revision": 1, "updated_at": "1970-01-01T00:00:00Z"}
```

`updated_at` 採 ISO 8601（UTC、以 `Z` 結尾）。範本內建檔案中的 `1970-01-01T00:00:00Z` 是中性佔位值；開局複製後，由主持人在每次寫入時填入實際時間。寫入前重新讀取目標 `revision`；不符時先合併或請玩家決定，避免多主持人衝突。

**實體修改條件**：實體紀錄（角色、物品、NPC、場景）只能因玩家明確行動、骰判定、主持揭露或已確認的劇情結果而修改，並以 `last_updated_event_id` 回指對應事件。

**推測不升格**：物品能力、NPC 知識不得因一次氣氛描述而新增；未確認者記入該實體的 `unknown_capabilities`／`open_questions`，經事件確認後才移入 confirmed 欄位並留事件 id。

## 事件日誌 `game/state/logs/events.jsonl`

每行一個不可變事件，必要鍵：`id`、`at`、`scene_id`、`kind`、`facts`、`visibility`。空檔表示尚無事件；解析時跳過空白行。不可改寫舊行。

- `visibility` 值域（全範本統一）：`public`（可公開）、`player`（玩家可知）、`director`（僅主持人可見）。
- `kind` 基礎值域：`fact`（確定事實）、`roll`（擲骰紀錄）、`correction`（修正）。規則書或模組可擴充新值，但不得改變基礎值的語意。
- 選用鍵 `updates`：本事件觸及的實體 id 陣列（如 `["compass","ivra"]`），供實體變更反向追溯。

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

## 當前場景 `game/state/current-scene.json`

主持人每回合的第一讀取點，只存**當下可操作資訊**；完整對話與擲骰在事件日誌。基線鍵：`revision`、`updated_at`、`scene_id`（須對應已宣告場景）、`name`、`location`、`exits`（可見出口）、`threats`（當前威脅、時間壓力與進行中的程序）、`observable_clues`（玩家可直接觀察到的線索）、`entities`（本場景相關實體 id 清單，對應 `entities/` 下的檔案）、`established_facts`（本場景已確認事實）、`open_questions`（仍未知的問題）、`last_updated_event_id`。

與 `world.json` 的分工：`world.json` 保存戰役級事實；`current-scene.json` 是場景級工作紀錄，場景切換時封存舊場景（見〈封存〉）再重建。分工判準與搬移時機見〈世界〉節。

## 世界 `game/state/world.json`

戰役級（跨場景）事實的單一保存處。基線鍵：`revision`、`updated_at`、`current_scene`、`known_facts`、`archived_facts`、`open_questions`。

- `current_scene`：**場景 id 指標字串**，指向某個已宣告的 `scene_id`；場景本身的工作紀錄在 `current-scene.json`（兩者同名但不同東西，勿混淆）。
- `known_facts`：陣列，已確認且**效力跨越場景邊界**的戰役級事實，每項：

  ```json
  {"fact": "失竊的是鐘舌，鐘體仍在。", "established_at_event_id": "evt-0009", "tags": ["鐘塔謎案"]}
  ```

  `fact` 必填；`established_at_event_id` 回指確立該事實的事件（與實體檔 `last_updated_event_id` 同一溯源模式）；`tags` 選用（字串陣列，供分類與檢索）。**舊格式相容**：既有戰役中的純字串項目視為未結構化舊事實，讀取時當作只有 `fact` 的項目，不強制立即改寫；該項下次被修改或搬移時再補齊物件形狀。
- `archived_facts`：與 `known_facts` 同形狀。仍然為真、但不再與進行中劇情高頻相關的事實**移動**（不刪除）至此；重新變得相關時移回。`archived_facts` 不在每回合的讀取範圍內（與 `archive/` 同精神）。
- `open_questions`：字串陣列，戰役級未解問題。

**與 `current-scene.json` `established_facts` 的分工判準**：一個事實**在場景結束後仍然成立、且未來場景可能需要引用**（跨場景效力）→ 記入或搬入 `known_facts`；僅在本場景內有操作意義的暫態觀察 → 留在 `established_facts`，隨場景封存進 `archive/scenes/`。正例：「渡口長真實身分是前走私販」→ `known_facts`；反例：「桌上的蠟燭還亮著」→ `established_facts`。搬移時機：場景切換或摘要更新時（PLAYBOOK 每回合第 6 步）順帶檢視——`established_facts` 中已具跨場景效力者搬入 `known_facts`、`known_facts` 中不再高頻相關者移入 `archived_facts`。

## 摘要 `game/state/summaries/current.md`

玩家可見的目前戰役摘要；續玩時的前情提要與每回合的背景脈絡皆讀此檔。以 YAML front matter 存中繼欄位、內文存敘事：

```markdown
---
updated_at: 1970-01-01T00:00:00Z
covers_scene_ids: []
---
```

- `updated_at`：最近一次重寫時間（ISO 8601 UTC）；`covers_scene_ids`：本摘要涵蓋的場景 id 陣列。**舊格式相容**：缺 front matter 視為未結構化舊摘要，續玩仍照常讀取純文字內容，不強制立即改寫；下次重寫摘要時補齊。
- 必要章節（列章節即可，措辭與長度由主持人依敘事風格決定）：
  1. **前情提要**：戰役至今發生過什麼的濃縮敘事。
  2. **當前處境**：主角現在在哪、正在做什麼、迫近的壓力。
  3. **未決線頭**：仍欠玩家的答案、進行中的承諾與懸念；可順帶提及關鍵 NPC 態度的變化（敘事化概括即可，不抄實體檔欄位值——實體檔才是單一事實來源）。
- 更新時機：場景結束或累積約 6–10 事件時重寫（PLAYBOOK 每回合第 6 步）。
- **可見性**：摘要是玩家可見文件，全部章節適用〈前線〉節的「前線資訊禁止清單」；「未決線頭」只寫玩家已知的懸念，不得寫入導演私下追蹤的節奏線索。

## 角色 `game/state/character.json`

基線鍵：`revision`、`updated_at`、`name`、`concept`、`goals`、`fears`、`strengths`、`bonds`、`notes`、`system`。共同創角四問的對應：想追求→`goals`、怕失去→`fears`、擅長→`strengths`、牽絆→`bonds`。

規則書要求的屬性、技能、資源等欄位，一律收進 `system` 通用容器（見下節），不得在 `system` 之外新增頂層鍵，也不得移除或改變基線鍵的語意。未啟用完整規則系統（僅用內附輕量裁定）時，`system` 為 `null`。

### `system` 通用容器

`system` 是固定形狀的容器層：任何規則系統的角色欄位都映射進五種容器，讓下游工具（如可視化介面）不需理解個別規則系統即可讀取。容器內的名稱沿用規則書原文詞彙。

- `id`：字串，active 規則系統識別，與規則優先序宣告一致。
- `stats`：物件，靜態數值或等級（屬性值、edge、tier、技能等級等）。
- `pools`：陣列，會消耗與恢復的資源池，每項 `{name, current, max}`（生命值、法力、Numenera 三池、Fate 點等）。
- `tracks`：陣列，狀態或傷害軌，每項 `{name, steps, current}`；`steps` 為階段名稱陣列，`current` 為目前階段的索引（0 起算）。勾格式的軌（如 Fate 壓力）以 `steps` 列出格名、`current` 記已勾格數。
- `tags`：字串陣列，標籤型特徵（aspects、descriptor/focus、職業標籤等）。
- `abilities`：陣列，能力、專長或戲法，每項 `{name, notes}`；可主動花費資源影響擲骰或結果的機制（如 Numenera 的 Effort）必須列於此，與規則速查卡的資源機制表對齊。

```json
{
  "id": "numenera",
  "stats": { "Tier": 1, "Might Edge": 1 },
  "pools": [ { "name": "Might", "current": 8, "max": 10 } ],
  "tracks": [ { "name": "Damage Track", "steps": ["Hale", "Impaired", "Debilitated"], "current": 0 } ],
  "tags": [ "Glaive", "Bears a Halo of Fire" ],
  "abilities": [ { "name": "Effort", "notes": "花費 3 點資源池降低任務難度一級" } ]
}
```

開局創角時由主持人依規則速查卡（`game/state/rules-quickref.md`）建立 `system`。既有戰役的角色卡若缺 `system` 鍵，視為未結構化舊卡：不強制立即改寫，於下次創角級變更（升級、重塑）時遷移。

進度資源（XP 等）的當前值記於 `system.stats`；其取得與消耗（含用途，例如「花 1 XP 重擲」）以事件記錄，事件 id 即溯源，不在角色卡重複保存歷史。

**多人架構預留（僅註記，現行只支援單人）**：schema 不假設唯一主角——實體的 `holder`、關係與事件的 `visibility` 一律使用角色／實體 id 指稱。未來多人擴充將採 `game/state/characters/<pc-id>.json` 目錄、屆時 `character.json` 遷移；在該擴充定案前，`character.json` 仍是唯一玩家角色檔，不實作任何多人流程。

## 庫存 `game/state/inventory.json`

基線鍵：`revision`、`updated_at`、`currency`、`items`。

- `currency`：物件，幣別為自由鍵（例：`{"銀幣": 12}`）。
- `items`：陣列，每項 `{id, name, qty, notes}`；`id` 用小寫連字號。規則書要求的欄位（負重、位置等）由主持人擴充，不得移除基線鍵的語意。

物品的取得、失去與數量變化屬確定事實：寫入事件日誌的同時必須同步更新本檔。

## 任務 `game/state/quests.json`

基線鍵：`revision`、`updated_at`、`quests`。

- `quests`：陣列，每項 `{id, name, status, objectives, notes}`。
- `status` 值域：`active`（進行中）、`completed`（完成）、`failed`（失敗）、`abandoned`（放棄）。
- `objectives`：陣列，每項 `{text, done}`。

任務的承接、目標進度與結局屬確定事實：寫入事件日誌的同時必須同步更新本檔。

## 規則速查卡 `game/state/rules-quickref.md`

啟用完整規則系統時，主持人於開局前依 `PLAYBOOK.md`〈初始化〉產出的速查卡，必要章節：創角步驟清單、核心判定流程、玩家可用資源機制表、單人調整摘要。屬戰役期產物，不隨發行包提供。

## 實體 `game/state/entities/`

會影響劇情的重要物品與 NPC 各自獨立建檔，每個重要實體的當前能力與狀態**只在其實體檔中定義**（單一事實來源）；場景、事件與其他實體只以 id 互相引用，不複製完整敘事。路人與一次性物品不必建檔（留在事件與庫存即可）。id 用小寫連字號。

### 物品 `game/state/entities/items/<item-id>.json`

僅重要物品（有名字、能力特殊、反覆出現或承載劇情）建檔。基線鍵：`revision`、`updated_at`、`id`、`name`、`aliases`、`appearance`、`holder`（持有者的角色／NPC id 或位置）、`confirmed_abilities`（已在劇中確認的能力）、`unknown_capabilities`（只記「還不知道什麼」，**不得填入推測能力**）、`limitations`（明確不能做什麼）、`current_state`（如封印、啟動、損壞、組合）、`relationships`（與其他實體的關係，以 id 引用）、`last_updated_event_id`。

`inventory.json` 維持總帳（數量與貨幣）；重要物品另建實體檔，兩處共用同一 `id` 互引，能力與狀態只寫在實體檔。

### NPC `game/state/entities/npcs/<npc-id>.json`

僅重要 NPC（有名字或明確身分、掌握關鍵情報、反覆出現、與玩家有關係）建檔。基線鍵：`revision`、`updated_at`、`id`、`name`、`aliases`、`identity`（身分與外觀）、`voice`（說話特徵）、`stance`（立場／陣營）、`goals`、`known_info`（此 NPC **確實知道**的情報）、`attitude`（對玩家的態度與關係變化）、`abilities`、`limitations`、`last_seen`（最後出現位置與狀態）、`last_updated_event_id`。規則書要求數值時可選用與角色卡相同的 `system` 容器形狀，不強制。

「誰知道什麼」與「世界真相」分開：NPC 只能說出其 `known_info` 已載（或本回合經事件揭露）的情報。**公私分層**：state 內的 NPC 檔只放玩家已知或可知的內容；NPC 的未揭露祕密、真實動機與導演備註放 `game/private/director/npcs/<npc-id>.json`（可選目錄，永不外洩給玩家）。

舊戰役相容：`game/state/npcs/` 為舊路徑，續玩時視同 `entities/npcs/` 讀取並搬遷一次。

## 封存 `game/state/archive/`

場景結束時，不再活躍的實體檔**移動**（不刪除）至 `archive/items/`、`archive/npcs/`；切換場景前把 `current-scene.json` 快照存為 `archive/scenes/<scene_id>.json`。archive 不在每回合的讀取範圍內，實體重新登場時把檔案移回 `entities/` 即可，歷史事件不受影響。

## 前線 `game/private/director/fronts/<front-id>.json`

前線屬狀態 JSON，必要鍵：`revision`、`updated_at`、`id`、`name`、`goal`、`resources`、`clocks`、`omens`、`next_reasonable_action`、`secret`。`clocks` 為陣列，每個時鐘含 `name`、`segments`、`current`（0 至 `segments` 的整數）。推進前線（修改 `current`）視同狀態寫入，適用重讀規則。

### 前線資訊禁止清單（玩家可見文件的界線）

前線的節奏壓力**可以**被玩家感覺到，但其識別資訊**不得**出現在任何玩家可見的文件或輸出（摘要、場景敘事、OOC 提示、correction）：

- 禁止：前線 `id`、前線 `name`、任何 `clocks` 的 `segments`／`current` 讀數、`omens` 與 `secret` 原文、`next_reasonable_action` 原文。
- 允許：不含識別資訊的敘事化節奏描述。
- 正例：「碼頭的氣氛一天比一天緊，巡夜的人變多了。」
- 反例：「『霧渡口陰謀』前線時鐘推進到 3/6。」（含前線名稱與時鐘讀數，即使玩家追問也不得給出）
