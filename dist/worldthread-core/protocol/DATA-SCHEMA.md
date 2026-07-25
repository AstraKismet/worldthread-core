# 資料格式

## 通用規則

所有文字使用 UTF-8；路徑相對於範本根目錄。`game/reference/` 為來源真相，已發生的 `game/state/` 可優先覆蓋相衝突的來源。`game/private/director/` 永不進玩家可見敘事。

每個狀態 JSON（含 `game/state/` 各檔與前線檔）至少有：

```json
{"revision": 1, "updated_at": "1970-01-01T00:00:00Z"}
```

`updated_at` 採 ISO 8601（UTC、以 `Z` 結尾）。範本內建檔案中的 `1970-01-01T00:00:00Z` 是中性佔位值；開局複製後，由主持人在每次寫入時填入實際時間。寫入前重新讀取目標 `revision`；不符即為衝突，依下方〈revision 衝突處理〉辦理，**不得自行合併**。

**原子寫入（建議慣例）**：覆寫任何狀態檔時，建議先寫入同目錄暫存檔、再改名覆蓋原檔（temp 檔＋rename），避免下游讀取者（如可視化工具的輪詢讀取）讀到寫到一半的檔案；環境不支援原子改名時直接覆寫即可——本慣例只降低讀取端風險，不改變任何行為結果。

**實體修改條件**：實體紀錄（角色、物品、NPC、場景）只能因玩家明確行動、骰判定、主持揭露或已確認的劇情結果而修改，並以 `last_updated_event_id` 回指對應事件。

**推測不升格**：物品能力、NPC 知識不得因一次氣氛描述而新增；未確認者記入該實體的 `unknown_capabilities`／`open_questions`，經事件確認後才移入 confirmed 欄位並留事件 id。

### revision 衝突處理

衝突＝寫入前重讀發現檔案的 `revision` 與本回合開頭讀到的不符，代表本回合期間有其他寫入者（另一個主持 session、外部工具、玩家手動編輯）動過檔案。處理原則（皆為硬性）：

- **不自動合併**：不得猜測兩邊意圖、不得自行產生合併結果，一律停下請玩家仲裁。多寫入者情境下，仲裁對象＝衝突檔對應的行動者玩家；無明確歸屬時由主持人代裁並記入主持人操作日誌。**本禁令的規範範圍是「衝突偵測後、玩家仲裁前」**：玩家明確仲裁後，主持人應依所選選項的定義執行，不得援引本條去質疑或修改玩家已做出的明確指示；但仲裁結果之外，仍不得另行混合兩邊內容。
- **僅衝突檔暫停**：只有衝突的檔案暫停寫入；`game/state/logs/events.jsonl` 是追加式真相準源，照常 append；其他無衝突的 state 檔照常更新（`last_updated_event_id` 溯源本就容許 state 短暫落後於事件，仲裁後依事件補寫即可）。
- **回合末 OOC 提示**：本回合敘事照常輸出，回合末以 OOC 區塊提示衝突並請玩家仲裁，所有雜訊層級皆顯示。提示內容為**極簡三要素**、不多不少：①檔案路徑；②本回合基於的 `revision` 與檔案實際 `revision`；③三個仲裁選項——以檔案現況為準（放棄本回合對此檔的變更，重讀後續行）／以本回合結果為準（**整份取代**：以檔案現況的 `revision` 為基準，把本回合結果整份重新寫入；現況中未包含在本回合版本內的欄位或條目一律不予保留，**不做欄位級合併**——覆寫前先依〈衝突備份〉存下現況原文）／玩家自行檢視檔案後再指示。
- **不展示內容差異**：提示中不引用、不摘要任何一邊的內容——`game/private/director/` 檔案衝突時同樣只給路徑與編號，零洩漏；玩家可見檔玩家可自行開檔查看。
- **衝突備份**：選「以本回合結果為準」而要整份覆寫前，先把**檔案現況的原文**存入 `game/state/archive/conflicts/<檔名>-<現況 revision>.json`（比照〈封存〉的移動不刪除精神；`game/private/director/` 的衝突檔存入 `game/private/director/archive/conflicts/`，不得跨越公私分層）。整份取代因此不會使任何一邊的內容永久消失，讀取端仍只需讀 live 檔、不必合併。備份檔屬歷史紀錄、**不是本局狀態**，不參與每回合讀取與敘事。

範例提示：

```text
⚠ 存檔衝突：game/state/world.json（本回合基於 revision 5，檔案現為 7）。
請選擇：1) 以檔案現況為準　2) 以本回合結果為準　3) 我自己看過再指示
```

## 版本相容性與寬容讀取

本節定義**跨版本讀取存檔**的行為原則：哪些相容性事實已經確立、遇到舊格式或未知內容時如何讀。**本範本不提供、也不需要任何遷移程式**——跨版本相容由本節與各節條文的讀取規則保證。範本自身的版本見發行包根目錄 `template.json`（唯讀）。

### 已確立的相容性事實

- **事件契約自 0.5.0 起穩定**：事件必要鍵（`id`、`at`、`scene_id`、`kind`、`facts`、`visibility`）與 `visibility` 三值值域（`public`／`player`／`director`）自 0.5.0 起未曾改變；`visibility` 永遠維持三值、不因多人擴充（見〈事件日誌〉〈角色〉）。**讀取合規的舊版存檔（依當時官方格式寫成者）不需要任何遷移動作**——依本檔各節的讀取規則直接續玩即可。
- **事件日誌的「舊資料解讀」規則＝correction 攤平**：解讀既有事件日誌時唯一需要的規則，是〈事件日誌〉已明定的「指向某原事件的**最新** correction 即有效版本」——這是條文層的讀取規則，不是遷移器，無需沿鏈回溯、不改寫舊行。寫入後的批次自查（可解析性與私有識別字串）由 `tools/healthcheck.mjs`／`tools/healthcheck.py` 覆蓋（見 `PLAYBOOK.md`〈狀態健檢〉）。

### 寬容讀取（未知內容的處理，硬性）

讀取任何狀態檔、事件或 `game/state/` 內容時，遇到**本協定未定義**的鍵、欄位、檔案或擴充值——例如個別玩家或外部工具自訂加入者（`audience` 事件鍵、`players.json` 檔這類鍵與檔從未屬於本範本任何版本的官方格式，即屬此類）：

- **一律忽略、不報錯、不臆測語意**：未知欄位不阻礙讀取已定義欄位；不得依名稱猜測其含義並據以敘事或裁定。自訂欄位不是本範本契約的一部分——忽略不代表承認或否定其語意，只代表本協定不裁決它。
- **不修不刪、原樣保留**：不得擅自「修復」或刪除未知內容；更新狀態檔時原樣保留自己不理解的欄位（保留既有欄位不算「新增頂層鍵」——〈角色〉等節的該類禁令規範的是主持人自行創設欄位，不是保留既有資料）。
- **可見度保守（硬性）**：無法依本協定判定可見度的資料——未知檔案的內容、無官方可見度判準的自訂結構——一律**不得**進入玩家可見輸出（敘事、摘要、OOC、RAG 檢索結果、`STATE-UPDATE` 區塊），比照〈事件日誌〉混合可見度讀取過濾義務與〈前線資訊禁止清單〉的精神：**拿不準可見度，就當作不可見。**

範例——事件夾帶非官方鍵：

```json
{"id":"evt-0100","at":"1970-01-01T00:00:00Z","scene_id":"fog-ferry-opening","kind":"fact","facts":["渡口的燈在霧裡亮了一夜。"],"visibility":"player","audience":["自訂值"]}
```

讀取端照官方鍵處理本事件（含依 `visibility` 過濾），對 `audience` 一律忽略、不臆測其語意；事件日誌不可改寫舊行，該鍵自然原樣留存。

### 前向相容（schema 演進的既定慣例）

本範本的 schema 演進一律**只增選用欄位、不改既有欄位語意、缺欄有保守預設、不強制既有戰役立即改寫**。因此新版寫出的存檔被舊版讀取端讀到時，未知欄位依上節原則忽略即可，既有行為不受影響；官方增欄的實例如事件選用鍵 `actor`（後續版本增列，舊存檔一律缺此鍵、讀取端照缺欄處理）。本檔各節既有的「舊格式相容」條款都是這條原則的個別實例：

- `world.json` `known_facts` 純字串項＝未結構化舊事實，讀時視為只有 `fact`（見〈世界〉）。
- `world.json` 缺 `campaign_status` 欄＝視為 `active`（見〈世界〉）。
- `summaries/current.md` 缺 front matter＝未結構化舊摘要，照常讀取純文字（見〈摘要〉）。
- `character.json` 缺 `system` 鍵＝未結構化舊卡，於下次創角級變更才遷移（見〈角色〉）。
- 舊路徑 `game/state/npcs/` 續玩時視同 `entities/npcs/` 讀取並搬遷一次（見〈NPC〉）。

## 事件日誌 `game/state/logs/events.jsonl`

每行一個不可變事件，必要鍵：`id`、`at`、`scene_id`、`kind`、`facts`、`visibility`。空檔表示尚無事件；解析時跳過空白行。不可改寫舊行。

- `visibility` 值域（全範本統一）：`public`（可公開）、`player`（玩家可知）、`director`（僅主持人可見）。
- **混合可見度讀取過濾義務**：本檔是單一檔案、混雜三種可見度。把事件內容轉入任何玩家可見輸出（敘事、摘要、OOC、RAG 檢索結果、`STATE-UPDATE` 區塊）之前，必須先按 `visibility` 過濾；`director` 行對玩家視同不存在——玩家 OOC 問起也不揭示該行存在，只以敘事化後果與徵兆回應（比照〈前線〉節禁止清單的精神）。
- `kind` 基礎值域：`fact`（確定事實）、`roll`（擲骰紀錄）、`correction`（修正）。規則書或模組可擴充新值，但不得改變基礎值的語意。
- 選用鍵 `updates`：本事件觸及的實體 id 陣列（如 `["compass","ivra"]`），供實體變更反向追溯。
- 選用鍵 `actor`：本事件行動者的角色 id——記「誰做的」，與 `updates`（動到誰）正交。單人局可省略；共窗多人（實驗）與遠端多人下用於發言與行動歸屬（共窗多人模式建議必填，見 `PLAYBOOK.md`〈共窗多人〉）。

範例事件：

```json
{"id":"evt-0001","at":"1970-01-01T00:00:00Z","scene_id":"fog-ferry-opening","kind":"fact","facts":["鐘塔的鐘在黎明前失竊。"],"visibility":"player"}
```

修正事件以 `kind: "correction"`，並以 `corrects` 鍵指向被修正的原事件 `id`；修正是追加，不是改寫。**`corrects` 一律指向非 correction 的原事件**：要撤銷或再次修正一則先前的修正時，**寫一則新的 correction、再次指向同一個原事件**（不指向前一則 correction）；同一原事件若有多則 correction，**以最新（事件序最後）的一則為有效版本**。讀取端因此只需取「指向某原事件的最新 correction」即可解析有效內容，無需沿鏈回溯、也不會出現二階修正鏈。**correction 撰寫義務——完整重述**：`facts` 須完整重述被修正事件此刻**仍然成立的全部內容**，不能只寫本次變更的差異；原事件的某個子事實若在最新 correction 中未被提及，視為**已不再屬於有效版本的一部分**，而非自動延續。撰寫前先讀原事件的 `facts`，逐項重述或明確捨棄。只是要補充、而非推翻既有內容時，改以新的 `kind: "fact"` 事件記載，不用 correction。**visibility 繼承**：correction 的 `visibility` 必須等於被修正事件的 `visibility`——修正只改內容、不改可見度；若某事實需要改變可見度（如導演祕密進入玩家可知範圍），那是「揭露」不是「修正」，以新的 `kind: "fact"` 事件記載，原事件不動：

```json
{"id":"evt-0009","at":"1970-01-01T00:00:00Z","scene_id":"fog-ferry-opening","kind":"correction","corrects":"evt-0007","facts":["更正：失竊的是鐘舌，鐘體仍在。"],"visibility":"player"}
```

若稍後發現**某則修正本身有誤**、要撤銷或再修正，同樣寫一則新的 correction **再次指向被修正的原事件**（而非指向前一則 correction）。以另一條修正鏈為例：原事件 `evt-0020` 曾以 `evt-0023` 修正，之後發現 `evt-0023` 有誤，寫 `evt-0031` **再次指向 `evt-0020`**：

```json
{"id":"evt-0031","at":"1970-01-01T00:00:00Z","scene_id":"fog-ferry-opening","kind":"correction","corrects":"evt-0020","facts":["再更正：河霧其實整日未散。"],"visibility":"player"}
```

此時指向 `evt-0020` 的最新 correction 為 `evt-0031`，即有效版本；`evt-0023` 自動被取代（不刪除、留在日誌）。**溯源欄位指向有效事件**：實體／世界／場景檔的 `last_updated_event_id`、`established_at_event_id` 等溯源欄位，應指向仍有效的確立或修正事件，不指向已被後續 correction 取代的修正。

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

**導演可見度擲骰**（`visibility: "director"` 的 roll 事件，如前線推進、NPC 暗中行動的判定）：照實記入本檔（含 `source` 與骰值）供稽核，但玩家可見層**只呈現後果與徵兆**——不呈現骰值與公式、也不告知「擲了骰」這件事；`PLAYBOOK.md`〈擲骰〉的 OOC 骰值揭示規則僅適用於玩家可見（`public`／`player`）的擲骰。

## 場景與 `scene_id`

場景檔位於 `game/reference/scenarios/`，必須以 YAML front matter 顯式宣告 `scene_id`：

```markdown
---
scene_id: fog-ferry-opening
---
```

事件的 `scene_id` 必須等於某個場景檔宣告的值；新增場景時先宣告、再引用。

**場景切換判準**：敘事移動到新的地點或時間段，且舊場景的 `threats`／`observable_clues`／`exits` 大多不再適用時，即屬場景切換——先宣告（或沿用）新場景檔，再依〈封存〉處理舊場景並重建 `current-scene.json`。同一地點的連續行動、或短暫走動後折返，視為同場景的自然延伸、不需切換。**存疑時傾向切換**：封存採移動不刪除、成本低，切換能保持 `current-scene.json` 精簡並讓 `archive/` 忠實累積歷史；長時間停在同一 `scene_id` 而敘事地點已數度改變，是判準被低估的訊號。

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
- `campaign_status`（選用）：戰役生命週期旗標，值域 `active`（進行中，預設）／`concluded`（本弧／本章已抵達尾聲）。**缺欄視為 `active`**（舊格式相容，既有戰役不需改寫）。搭配選用 `concluded_at_event_id`（回指促成收尾的事件，與 `established_at_event_id` 同一溯源模式）。**完結≠封存**：檔案留原地供回顧，此旗標供下游（如可視化）判讀戰役是否已收束，不改變任何既有欄位語意。**可續玩**：玩家要延續舊紀錄開新冒險時把 `campaign_status` 改回 `active`（或標記新弧），事件日誌、角色、世界一律延續不重置（收尾與續玩流程見 `PLAYBOOK.md`〈戰役收尾〉）。

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
  3. **未決線頭**：仍欠玩家的答案、進行中的承諾與懸念；可順帶提及關鍵 NPC 態度的變化（敘事化概括即可，不抄實體檔欄位值——實體檔才是單一事實來源）。戰役收尾時，本節改記各線頭的**最終處置**（收束或刻意留白）。
  4. **尾聲（epilogue）** *(僅戰役收尾時出現的條件式必要章節)*：本弧抵達的結局敘事，回應玩家一路的關鍵選擇；未完結的戰役無此節。詳見 `PLAYBOOK.md`〈戰役收尾〉。
- 更新時機：場景結束或累積約 6–10 事件時重寫（PLAYBOOK 每回合第 6 步）。
- **可見性**：摘要是玩家可見文件，全部章節適用〈前線〉節的「前線資訊禁止清單」；「未決線頭」只寫玩家已知的懸念，不得寫入導演私下追蹤的節奏線索。
- **玩家編輯優先**：玩家可直接編輯本檔；主持人重寫摘要前先讀現況，玩家的人工編輯視為已確認內容、優先於 AI 重新生成，不得逕自覆蓋或改回。
- **戰役收尾與續玩**：收尾時於 `world.json` 設 `campaign_status: "concluded"`（見〈世界〉）、本檔加寫〈尾聲〉節。玩家續玩新冒險時，把收尾時的本檔快照存入 `archive/summaries/<arc-id>.md`（移動不刪除、比照〈封存〉精神），再重寫 `current.md`（舊尾聲折入新「前情提要」），`campaign_status` 回 `active`。

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

**多人架構與共窗多人（實驗）**：schema 不假設唯一主角——實體的 `holder`、關係與事件的 `visibility` 一律使用角色／實體 id 指稱。**共窗多人（實驗，Hot Seat）** 啟用時，每位 PC 各存 `game/state/characters/<pc-id>.json`（形狀同 `character.json`、各自 `system` 容器），行動以事件選用 `actor` 鍵歸屬（本模式建議必填），玩家發言以第三人稱自標角色；**單人預設維持單一 `character.json` 不遷移**（既有戰役零影響；流程見 `PLAYBOOK.md`〈共窗多人〉）。**visibility 仍為三值、不因多人擴充**——單一共用窗口物理上無法對在場玩家隱藏資訊，PC 間祕密的機制化留待有獨立頻道的遠端形態。更完整的**遠端多人**目標形態（另開專案、僅方向註記）：由中繼程式把多位玩家在頻道的發言聚合成一次回合輸入後與主持人溝通（中繼引用本範本為核心模組）；其多人流程在中繼專案完成定案前不落地於本範本。

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

啟用完整規則系統時，主持人於開局前依 `PLAYBOOK.md`〈初始化〉產出的速查卡，必要章節：創角步驟清單、核心判定流程、玩家可用資源機制表、單人調整摘要。**條件式必要章節**：規則書含觸發鏈、狀態疊加或明確優先權（特例蓋過通則）機制時，另須產出「觸發條件與例外覆蓋表」——哪條規則在什麼條件下觸發、誰蓋過誰、優先權順序；輕量系統可省略。屬戰役期產物，不隨發行包提供。

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

場景結束時，不再活躍的實體檔**移動**（不刪除）至 `archive/items/`、`archive/npcs/`；切換場景前把 `current-scene.json` 快照存為 `archive/scenes/<scene_id>.json`。archive 不在每回合的讀取範圍內，實體重新登場時把檔案移回 `entities/` 即可，歷史事件不受影響。戰役收尾後玩家續玩新弧時，把收尾時的 `summaries/current.md` 快照存為 `archive/summaries/<arc-id>.md`（見〈摘要〉）。`revision` 衝突仲裁選「以本回合結果為準」而整份覆寫時，被覆寫的現況原文存為 `archive/conflicts/<檔名>-<現況 revision>.json`（見〈revision 衝突處理·衝突備份〉）——同屬歷史紀錄、不是本局狀態，一樣不在每回合讀取範圍內。

## 前線 `game/private/director/fronts/<front-id>.json`

前線屬狀態 JSON，必要鍵：`revision`、`updated_at`、`id`、`name`、`goal`、`resources`、`clocks`、`omens`、`next_reasonable_action`、`secret`。`clocks` 為陣列，每個時鐘含 `name`、`segments`、`current`（0 至 `segments` 的整數）。推進前線（修改 `current`）視同狀態寫入，適用重讀規則。

### 前線資訊禁止清單（玩家可見文件的界線）

前線的節奏壓力**可以**被玩家感覺到，但其識別資訊**不得**出現在任何玩家可見的文件或輸出（摘要、場景敘事、OOC 提示、correction）：

- 禁止：前線 `id`、前線 `name`、任何 `clocks` 的 `segments`／`current` 讀數、`omens` 與 `secret` 原文、`next_reasonable_action` 原文。
- 允許：不含識別資訊的敘事化節奏描述。
- 正例：「碼頭的氣氛一天比一天緊，巡夜的人變多了。」
- 反例：「『霧渡口陰謀』前線時鐘推進到 3/6。」（含前線名稱與時鐘讀數，即使玩家追問也不得給出）

## 主持人操作日誌 `game/private/director/host-log.jsonl`

主持過程的**例外紀錄**，供使用者事後稽核主持品質；位於 `game/private/director/`，靠目錄隔離保密，**刻意不設 `visibility` 欄**。追加式、每行一筆，必要鍵：`id`、`at`、`kind`、`facts`；選配 `refs_event_id` 關聯對應事件。**例外時寫**（不逐回合寫）、預設啟用、不綁系統雜訊層級（寫入本檔是私下作業，任何雜訊層級都不對玩家陳述）。

- `kind` 基礎值域（可擴充）：`ruling`（規則缺漏時的臨時裁定及其依據，供後續一致適用）、`violation`（發現自己違反協定或規範的情形與修正方式）、`boundary`（私有邊界的例外操作，如決定將原屬導演可見的資訊揭露給玩家的理由）、`conflict`（`revision` 衝突的偵測、暫停與仲裁結果）。
- **私有檔案的存在本身即機密**（硬性，適用整個 `game/private/director/`）：該目錄下**任何檔案的存在、檔名與紀錄 id**，皆不得出現在任何玩家可見輸出——包含 `events.jsonl` 的 `ruling` 欄、實體檔的 `notes`、摘要、場景檔與敘事本身。需要在玩家可見處說明某項裁定時，只陳述玩家需知的裁定內容，不提它被記在哪裡。（此為結構性紅線：玩家可自行開啟 `game/state/` 的任何檔案，凡寫進去的就等於說出口。）
- 檔案不存在＝尚無紀錄，首次寫入時建立；解析時跳過空白行。不可改寫舊行。
- 輪替比照 `archive/` 封存模式：檔案過大（約數百行）時整檔移至 `game/private/director/archive/host-log-<序號>.jsonl`（移動、不刪除），以新檔續寫。

範例：

```json
{"id":"hlog-0001","at":"1970-01-01T00:00:00Z","kind":"ruling","facts":["規則書未涵蓋水下射擊；臨時裁定沿用遠射並提高一級難度，後續一致適用。"],"refs_event_id":"evt-0012"}
```

## 戰役主線大綱 `game/private/director/campaign-arc.md`

戰役級的**導演私有**主線藍圖，初始化時由主持人依 `game/session-brief.md` 的題材與**戰役長度預期**設計（見 `PLAYBOOK.md`〈初始化〉〈戰役收尾〉）。用途：即使玩家的自由行動發散出支線，主線大綱確保戰役最終能抵達一個尾聲。屬 `game/private/director/`，靠目錄隔離保密——**內容永不得出現在任何玩家可見的敘事、摘要或輸出**（比照〈前線〉的資訊禁止清單精神）。

自由格式 Markdown（以主持人使用效益優先，不遷就人類閱讀版式），建議涵蓋：

- **大方向／前提**：本戰役的核心衝突與基調。
- **潛在尾聲形狀**：一或多個可抵達的結局輪廓（非鎖死單一結局，隨玩家選擇調整）。
- **主線里程碑**：抵達尾聲途中的關鍵節點，允許支線發散而不脫軌。

戰役長度預期（session-brief B 段）決定里程碑密度與前線／倒數鐘配速：短團收斂、長團鋪展。收尾後玩家續開新弧時，更新或改寫本檔為新弧的大綱。
