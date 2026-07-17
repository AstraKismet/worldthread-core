# 通用單人 TRPG 體驗範本：設計規格

> 狀態：`0.5.0` 已發行；本文件為現行設計依據，並含 `0.6.0`（發行包代理入口檔、契約補洞、可見度操作規則、revision 衝突處理、STATE-UPDATE 語意、RAG 原則條文、主持人操作日誌、extras 全量重產、短團收尾機制、共窗多人〔實驗，Hot Seat〕本地多人；套件更名 `worldthread-core`）之設計。正式專案名為 Worldthread／織世；發行套件名為 `worldthread-core`；授權採 MIT License。

## 1. 目標與範圍

本專案產出一個可直接解壓成專案、可由具資料夾讀寫能力的 AI 服務使用的單人 TRPG 範本。使用者放入規則、世界、角色與劇本素材，完成初始化後，只要以自然語言（文字或語音轉寫）扮演角色即可遊玩。

範本提供資料結構、可攜協定、主持行為、記憶與發行流程；不綁定 Codex、雲端資料庫、嵌入模型或特定 RAG 服務，也不隨附未獲授權的規則書或設定素材。本範本不為行動裝置提供原生遊玩流程：行動裝置玩家應以遠端控制或類似方式，連回實際執行 AI 服務與檔案的環境。

定位：**單人為主、雙形態演進中**。本專案是 Worldthread 生態系的**核心模組**（套件名 `worldthread-core` 由此而來），本身即為可直接遊玩的成品；衍生功能（bot 中繼多人、可視化戰役分析、web UI 等）屬另開專案，引用本專案的協定與資料契約為核心。現行完整支援的形態是「一位玩家＋一位 AI 主持人」的單人戰役；另提供**可選啟用的實驗性本地多人**「共窗多人（實驗，Hot Seat）」——一位主持人與數位玩家共用單一對話窗口（預設關閉、於 `game/session-brief.md` 顯式啟用；每位 PC 各存 `game/state/characters/<pc-id>.json`、行動以事件 `actor` 鍵歸屬。單一窗口物理上無法對在場玩家隱藏資訊，故不支援 PC 間機制化祕密）。核心 schema 已為多人擴充預留——實體 `holder`、事件 `visibility` 與選用 `actor` 鍵皆以 id 指稱、不假設唯一主角（見 `DATA-SCHEMA.md` 多人架構註記）。更完整的**遠端多人**目標形態為「中繼程式聚合多位玩家的頻道發言 ↔ AI 主持」（bot 中繼屬另開專案、引用本範本為核心模組）：其多人流程在中繼專案達到可用里程碑並完成定案前，不落地於本範本。**visibility 一律維持 `public`／`player`／`director` 三值、不因多人擴充。**

## 2. 發行與資料架構

所有可分發內容位於 `dist/worldthread-core/`，並且只從該資料夾封裝。發行結構如下：

```text
dist/worldthread-core/
├─ README.md
├─ AGENTS.md                        # 代理入口：AI 主持人的入口指引與行為規範（工具中立）
├─ CLAUDE.md                        # Claude Code 入口：單行 @AGENTS.md 匯入
├─ ADDING-RULEBOOKS.md
├─ LICENSE
├─ template.json
├─ protocol/
│  ├─ PLAYBOOK.md
│  ├─ DATA-SCHEMA.md
│  ├─ RAG-PROTOCOL.md
│  ├─ VOICE-PROTOCOL.md
│  └─ adapters/
├─ tools/
│  ├─ dice.mjs
│  ├─ dice.py                      # 與 dice.mjs 輸出契約相同的 Python 對等實作
│  ├─ dice.fixtures.jsonl          # 雙工具共用的黃金行契約夾具（CI 契約測試）
│  └─ convert-rulebook-prompt.md
├─ game/
│  ├─ reference/{rules,setting,scenarios,characters}/
│  ├─ private/director/            # fronts/、hook-market.md 與 campaign-arc.md（戰役主線大綱）；盲拆原料 source/ 於戰役期建立
│  └─ templates/{narrators,starter-state}/
└─ examples/
```

- 根目錄 `AGENTS.md`／`CLAUDE.md` 是**代理入口檔**：供會自動載入工作區規範的 agent 工具（Claude Code、Codex CLI 等）在收到開局提示前就取得入口指引（先讀 `session-brief.md`／`PLAYBOOK.md`）與行為規範（私有隔離、協定不可改、隱私、玩家主導）。內容僅指路與紅線，權威內容仍在 `game/session-brief.md` 與 `protocol/`；與開發儲存庫根目錄的同名檔用途不同（該檔屬開發代理指南、不隨發行包散布）。
- `game/reference/`：通常不直接修改的來源真相。
- `game/state/`：本局已發生、玩家可知或可公開的變化；與來源衝突時優先。**不隨發行包提供**——玩家開局時將 `game/templates/starter-state/` 複製為 `game/state/`，其下的 `entities/{items,npcs}/`、`archive/`、`logs/`、`summaries/`（及共窗多人時的 `characters/<pc-id>.json`）等於遊玩時建立；CI 禁止 `game/state/` 進入封裝。
- `game/private/director/`：未揭露秘密、勢力目標、伏筆與導演決策；不能直接進玩家可見內容。發行包內僅含可公開發行的範例導演素材。
- `game/rag/`：可再生索引，不能是唯一真相來源。**不隨發行包提供**，由接入服務於執行期建立；CI 禁止其進入封裝。

## 3. 平台中立與 RAG

協定與資料全部使用 UTF-8 Markdown、JSON 及相對路徑。任一服務只要能讀取、搜尋並寫回資料夾，就能依 `PLAYBOOK.md` 處理回合、依 `RAG-PROTOCOL.md` 檢索並依 schema 寫回。

索引分為 `public`、`player`、`director` 權限範圍；每個分塊有穩定 ID、來源、標籤、權限、摘要及更新時間。原生向量檢索可以匯入這些資料，但必須保留檔案式索引與來源，讓使用者能移轉服務或重建索引。沒有直接檔案寫入能力的平台可輸出結構化狀態更新區塊，由使用者貼回檔案。

## 4. 語音遊玩

語音是傳輸層：STT 將玩家發言轉為文字、TTS 可朗讀回覆，文字才是遊戲真相。語音回合包含 `speaker`、`transcript`、`confidence`、`uncertain_spans` 與 `mode`（角色內／角色外／命令）。重要歧義、專有名詞或安全界線必須自然地確認；玩家可用「更正」修訂尚未結算的輸入。

原始音檔預設不保存；若使用者選擇保留，只可放在私有區並排除於提交及發行包。

## 5. 主動、沉浸而公平的主持

主持人以敘事與 NPC 對話呈現世界，不暴露工具或模型存在；不能替主角決定意圖、台詞或關鍵選擇。規則以原始規則書優先；缺漏時採一致、可記錄的臨時裁定，並保留至少一條合理回應路徑。

**敘事沉浸分層**：主持產出分兩層，玩家可見的只有 IC 沉浸敘事。狀態 bookkeeping（`revision`、pending、檔名、`scene_id`）、工具執行過程（讀狀態、擲骰工具選擇與 fallback、路徑失敗）與規則機制的逐步推導都是主持人私下的作業，不得織進 IC 敘事；只有為信任或操作所必需者（骰值原始結果、無法寫檔的 `STATE-UPDATE` 區塊）才進入明確分隔的 OOC 系統區。可見詳略由 `系統雜訊` 設定分三級（`安靜` 預設／`標準`／`除錯`），玩家於 `session-brief.md` B 段選擇。**兩項 OOC 不受雜訊層級管制**（屬玩家的信任與決策權，非系統雜訊，所有層級皆顯示）：回合末一行極簡存檔確認（例：`✦ 進度已存`），與判定關鍵點的資源選項提示。權威定義見 `protocol/PLAYBOOK.md` §敘事沉浸分層。

**規則遵循與資源機制提醒**：啟用完整規則系統時，主持人開局前必先依 active 規則書產出規則速查卡 `game/state/rules-quickref.md`（創角步驟清單、核心判定流程、玩家可用資源機制表、單人調整摘要；規則書含觸發鏈、狀態疊加或明確優先權機制時另加「觸發條件與例外覆蓋表」，輕量系統可省略）。創角必須逐項對照速查卡勾核並向玩家做 OOC 角色卡確認；判定先查速查卡再回查規則書原文引 `ruling`；進入擲骰或關鍵判定前，若玩家有可影響結果的規則資源（消耗品、燒屬性、命運點等），以一行 OOC 提示選項與代價，交由玩家決定、不得代決。

**單人調整**：規則書多預設 4–5 人團隊；套用於單人遊玩時依 `PLAYBOOK.md` §單人調整縮放——遭遇規模以單角色行動經濟為準、資源與恢復節奏對應放寬、失敗後果傾向代價與挫折而非終局、可選主持人控制的夥伴 NPC（不得奪走玩家能動性）；每項調整記入 `ruling` 保持全戰役一致。

主持不只回應，而是持續運作的劇情導演。初始化設定「說書人檔」：壓力頻率、恢復節奏、偏好鉤子、後果強度、規則嚴謹度、敘事調性及題材界線。使用者可新增或修改此類設定檔；發行包至少提供數種可選設定，並附敘事風格萃取範本與提示詞，讓使用者以有權使用的參考素材萃取專屬說書人風格（極簡散文或八節結構化皆可作為依據）。

導演層以五項機制維持主觀能動性：

1. **前線與倒數鐘**：各勢力和危機有目標、資源、徵兆與下一個合理行動；有意義的時間流逝或場景結束時推進。
2. **鉤子市場**：從未解問題、關係、地點與前線生成多個候選鉤子，依節奏和玩家興趣引入，而非預寫單一路線。
3. **節奏與驚喜預算**：以壓力／恢復循環控制介入密度；驚喜須可從既有線索回溯、符合界線、不推翻既定事實，且創造新選擇。
4. **玩家主導權閘門**：世界和 NPC 可行動，但不得代替玩家決定主角；不可逆事件也要保留合理的反應空間。
5. **回顧校正**：摘要時盤點未回收的線索、承諾與關係，調整後續鉤子權重。

## 6. 回合、記憶與資料完整性

每回合：讀取當前場景、主角、相關世界／NPC 狀態與摘要；檢索規則及素材（啟用規則系統時先查速查卡再回查原書）；敘事與裁定；把確定結果追加至事件日誌；更新受影響狀態；在場景或門檻結束時壓縮摘要。事件日誌只記錄已確定事實。

玩家可見的戰役紀錄結構化存於 `game/state/`：`character.json`（角色卡；規則欄位一律收進 `system` 通用容器——`id`＋`stats`／`pools`／`tracks`／`tags`／`abilities` 五容器，讓下游工具不需理解個別規則系統即可讀取，形狀見 `DATA-SCHEMA.md`）、`inventory.json`（庫存與貨幣）、`quests.json`（任務與目標進度）、`current-scene.json`（場景級工作紀錄：威脅、線索、在場實體、已確認事實）、`entities/{items,npcs}/`（重要實體各一檔，單一事實來源：已確認能力／限制／已知情報與 `last_updated_event_id` 事件溯源）、`world.json`（戰役級事實）、`logs/events.jsonl`、`summaries/`、`archive/`（場景結束時封存不再活躍的場景快照與實體，移動不刪除）。回合末寫入前逐項核對受影響檔案皆已更新（含庫存與任務——物品得失、任務進度屬確定事實，與事件日誌同步）；寫入完成後以一行極簡 OOC 存檔確認告知玩家。

主持每回合採**分層讀取**（current-scene → 主角 → 場景所列實體 → 最近事件與摘要；必要時才讀 archive／director），並在敘事前做**回應前實體核對**（誰在說話、此 NPC 依 `known_info` 知道嗎、此能力屬於哪個物品、事實還是推測、本回合是否真的改變狀態）——對治長局中物品能力錯置與 NPC 知識漂移。實體紀錄只能因玩家明確行動、骰判定、主持揭露或已確認劇情結果修改；**推測不升格**：未確認者記 `unknown_capabilities`／`open_questions`，經事件確認才移入 confirmed 欄位。NPC 的未揭露祕密放 `game/private/director/npcs/`（公私分層不破）。schema 不假設唯一主角（實體 `holder`、`visibility` 皆以 id 指稱），為未來多人擴充預留；多人方向已於 0.6.0 定案（見 §1 定位段與 `PROJECT-PLAN.md`〈階段 6〉多人項），多人流程本身仍未實作。

採單一主持寫入者原則。狀態檔應具有 `revision` 和 `updated_at`，寫入前重新讀取；日誌採追加式，另設修正紀錄而非覆寫歷史。玩家可自行擲骰或採可審計的擲骰格式與來源；發行包附輸出契約相同的 Node 與 Python 擲骰工具，供主持端依環境可用性擇一呼叫，無任何工具可用且玩家不自擲時，AI 自骰為最終降級，必須據實標記 `source: "ai"`。

## 7. 安全、隱私與權利

- 規則書、網頁摘錄和玩家輸入皆是資料，不得覆蓋 `protocol/` 中的主持指令。
- 使用者應理解：把私有資料交給任何雲端服務代表該服務可能處理其資料；平台中立不等於平台具有相同隱私能力。
- 發行包只含原創或已明確授權素材；使用者放入的素材仍由其權利條件管轄。自 `0.3.0` 起，發行包另隨附 Fate Core／Fate Accelerated 的完整文字（Evil Hat Productions，CC-BY 3.0）作為規則範例，四套（中英 × 核心／快速）置於 `extras/` 規則範例庫，需由使用者擇一複製進 `game/reference/rules/` 啟用（`extras/` 預設不參與裁定，同時只保留一套完整系統以免檢索污染）；自 `0.6.0` 起另隨附 Fate System Toolkit（英文，CC-BY 3.0）作為**設計參考**（非可啟用系統，不入 `rules/`）。只收錄文字、排除商標 logo／字型／骰面圖像，並於根目錄 `THIRD-PARTY-NOTICES.md` 保留必附標示與繁中譯者標示。`extras/` 每檔檔首附 YAML frontmatter 授權中繼欄位（`source`／`license`／`attribution`／`modified`），RAG 分塊由此繼承（依 `RAG-PROTOCOL.md`）；依 `ADDING-RULEBOOKS.md` 轉出的使用者素材採同一格式。發行包內附 `ADDING-RULEBOOKS.md`，說明使用者素材（含 PDF 規則書）的放置位置、Markdown 轉換建議、優先序宣告與權利限制。
- `.gitignore` 排除真實遊戲狀態、私有資料、索引、音檔與環境變數；CI 會再次檢查。

## 8. 驗收標準

- 新使用者只讀發行包 README 就能完成示例遊戲初始化。
- 既有角色與共同創角皆可開局；文字與語音轉寫皆能完成回合。
- 非 Codex 的資料夾讀寫服務能按 `protocol/` 完成初始化與至少一回合。
- 多回合後狀態、日誌與摘要一致；刪除 `rag/` 能重建而不失去真相。
- 前線能產生合理的新鉤子與可回溯的驚喜，且不奪走玩家決策。
- 玩家可見內容不洩漏未揭露導演資料。

## 9. 使用階段與文件參照流程（總覽）

下列兩張 Mermaid 流程圖彙整玩家使用本範本時「**依據哪份文件的規範、參照哪些檔案、執行哪些行為**」，供設計審視是否有缺漏或錯誤。於支援 Mermaid 的檢視器（如 GitHub）渲染為圖，其餘顯示為等效文字。節點以「依據／讀／寫／行為」標明各步所依循的規範文件與動作；貫穿全流程的界線列於文末。

### 9.1 設置與調整規範流程（使用者，開局前）

```mermaid
flowchart TD
  A0(["解壓發行包，複製整個資料夾作為你的戰役"]) --> A1
  A1["編輯 game/session-brief.md 的 B 段「可調整區塊」<br/>依據：README.md §三分鐘開始；session-brief.md（A 段＝固定規範入口／目錄）<br/>設定：說書人、系統雜訊（安靜／標準／除錯，預設安靜）、規則系統、題材界線、壓力、嚴謹度、主角"]
  A1 --> AN{"說書人風格？"}
  AN -->|內附三種| A2
  AN -->|自訂萃取（可選）| ANX["依據：game/templates/narrators/README.md、tools/extract-narrator-style-prompt.md<br/>用有權使用的素材依 STYLE-EXTRACTION-TEMPLATE.md 萃取八節風格指南<br/>存成 game/templates/narrators/&lt;風格名&gt;.md，於 session-brief 說書人欄填該名稱"]
  ANX --> A2
  A2{"本局用哪種規則？"}
  A2 -->|內附輕量裁定| A3["不動 game/reference/rules/（保留 fallback 裁定檔）<br/>session-brief 規則系統欄留「無」"]
  A2 -->|隨附的 Fate（擇一）| A4["依據：extras/README.md、ADDING-RULEBOOKS.md<br/>① 先移除 rules/ 內其他完整系統（保留 fallback 裁定檔，目前為 lightweight-rulings.md）<br/>② 從 extras/ 複製你要的『一套』 → game/reference/rules/<br/>③ 在 session-brief 規則系統欄填該路徑（只放一套不需 priority.md）"]
  A2 -->|自帶規則書| A5["依據：ADDING-RULEBOOKS.md（含〈拆章基準〉）、tools/convert-rulebook-prompt.md<br/>轉成 Markdown 放 game/reference/rules/（依拆章基準拆章或單檔）<br/>含謎底模組→game/private/director/source/ 交由 §模組盲拆<br/>放多本書、需指定先後順序時才寫 priority.md"]
  A3 --> A6
  A4 --> A6
  A5 --> A6
  A6["複製 game/templates/starter-state/ → game/state/<br/>（玩內附範例霧渡口則直接用既有 game/reference/，主角可填 lin-yao）"]
  A6 --> A7(["就緒 → 進入開局（見 9.2）"])
```

### 9.2 開局與遊玩行為流程（玩家 ↔ 主持 AI，從初次開局起）

```mermaid
flowchart TD
  P0["〔玩家〕開局：送出 session-brief 的開局一句<br/>「讀取 game/session-brief.md，依其規範與我的設定為我開局」"] --> I1
  I1["〔AI〕初始化（依據：PLAYBOOK §初始化 ＋ session-brief A 段）<br/>讀 session-brief、PLAYBOOK、所選 narrator（極簡散文或八節結構化皆可）、game/reference/、game/state/（無則由 starter-state 建）<br/>讀但不外洩 game/private/director/<br/>多套互斥系統時擇一設 active（§規則來源與優先序）；啟用完整系統→先產規則速查卡 game/state/rules-quickref.md（§初始化）；讀取系統雜訊層級"] --> I2
  I2["〔AI〕開場（依據：PLAYBOOK §共同創角）<br/>依 session-brief 問題材界線／壓力／嚴謹度；選既有角色或帶玩家共同創角（規則欄位入 DATA-SCHEMA 的 system 容器；規則系統 active 時逐項對照速查卡勾核＋OOC 角色卡確認）；佈置第一個場景"] --> T0
  T0["〔玩家〕回合：以角色行動／對話／OOC 指令表達意圖（可語音）"] --> T1
  T1["〔AI〕主持（依據：PLAYBOOK §每回合／§擲骰／§主動但公平／§敘事沉浸分層；DATA-SCHEMA；RAG；VOICE）<br/>分層讀取：current-scene→主角→場景所列實體（entities/）→最近事件與摘要（必要時才讀 archive／director）＋revision；依 active 規則系統檢索 reference/rules（有 rag 只索引 active 套）＝私下作業<br/>解釋意圖（不替主角決定）；回應前實體核對（誰在說話／NPC known_info／物品 confirmed_abilities／事實或推測）；判定先查 rules-quickref 再回查原書引 ruling；擲骰前若玩家有可用規則資源→一行 OOC 資源選項提示（各雜訊級皆顯示）；具體敘事＋NPC／世界行動（單人調整見 §單人調整）；需隨機→dice.mjs／dice.py（禁編造，最終降級記 source:ai）<br/>依系統雜訊層級呈現：bookkeeping／工具過程／建檔不入 IC 敘事，骰值與降級區塊置 OOC"] --> T2
  T2["〔AI〕寫入（依據：DATA-SCHEMA；PLAYBOOK §無法寫檔降級）<br/>只寫已確定事實→state/logs/events.jsonl（追加）；逐項核對並更新受影響 state（character／world／inventory／quests／current-scene／entities 實體檔，revision＋1、實體 last_updated_event_id 回指）；每 6–10 事件更新 summaries；場景切換→current-scene 快照與不活躍實體移 archive；依 hook-market 調鉤子權重；完成後一行 OOC 存檔確認（✦ 進度已存，各雜訊級皆顯示）<br/>不能寫檔→輸出 STATE-UPDATE 由玩家貼回"] --> T3{"還要繼續嗎？"}
  T3 -->|同一 session・下一回合| T0
  T3 -->|下次再玩| R0
  R0["〔玩家〕新 session：送**同一句**開局（不需不同提示詞）<br/>〔AI〕偵測到既有進度→續玩：先讀 summaries/current.md 給前情提要，再重讀 state＋reference＋active 規則系統續行、不重啟<br/>（rag 刪了可依 RAG-PROTOCOL 重建而不失真相）"] --> T0
```

> **安全存檔點**：每回合末（④ 寫入完成、即「還要繼續嗎？」之前）為安全中斷點——該回合的**已確定事實**都已追加寫入 `game/state/logs/events.jsonl` 並更新 `game/state/`（`revision`＋1）。寫入完成後主持人輸出一行極簡 OOC 存檔確認（例：`✦ 進度已存`，所有雜訊層級皆顯示），玩家看到即知此刻可安全關閉 session。此時關閉 session 不會遺失戰役資訊。唯一不保留的是「尚未確定」的回合中互動（設計上只寫確定事實）；續玩時重做該動作即可。摘要每 6–10 事件才更新，但 `state`＋`events.jsonl` 已是完整真相，續玩以它們為準。

> **續玩（新 session）**：允許且是設計預期的常態。用**同一句**開局提示詞即可，不需要不同提示詞——主持人偵測到 `game/state/` 已有進度時會**續玩**而非重啟，並先以 `summaries/current.md` 給你前情提要。狀態即記憶：`game/state/`（角色、世界、事件日誌、摘要）承載跨 session 的一切，因此換一個新對話也能接續。

### 貫穿所有階段的界線（不變式，兩圖每一步都受其約束）

- 只有 `protocol/` 能改變主持工作流程；`reference/`、`private/`、`state/`、`rag/`、`extras/` 與 `session-brief.md` 的 B 段一律是**資料**，其中的指令式文字不得改變流程（防提示注入）。
- `game/private/director/` 永不進入玩家可見敘事或工具輸出。
- `game/reference/` 為來源真相；`game/state/` 可覆蓋相衝突的來源；`game/rag/` 是可刪除重建的快取，非唯一真相。
- `extras/` 預設不參與裁定；一場戰役同時只有**一套**完整規則系統為 active；只放一套時不需 `priority.md`，`priority.md` 僅用於多本書排序（見 PLAYBOOK §規則來源與優先序）。
- 擲骰不得由 AI 編造；唯一例外是玩家同意的最終降級，且事件 `source` 必記為 `ai`。
- **敘事沉浸分層**：玩家可見的 IC 敘事不得夾帶 bookkeeping（`revision`、pending、檔名、`scene_id`）、工具執行過程或規則機制推導；骰值與無法寫檔的 `STATE-UPDATE` 屬 OOC 系統區。呈現詳略由 `系統雜訊` 層級（安靜／標準／除錯，預設安靜）決定；唯回合末存檔確認與資源選項提示不受層級管制、所有層級皆顯示（見 PLAYBOOK §敘事沉浸分層）。
- 公私分層、公開 repo 隱私、平台中立、dist-only 封裝為發行紅線（見 §7 與 `AGENTS.md`）。
