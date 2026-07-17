# 建置計畫與風險登錄

> 狀態：`v0.2.0` 已於 2026-07-14 發行（擲骰 Python 對等工具、契約測試與 AI 自骰降級；`v0.1.0` 同日稍早發行）。`0.3.0` 隨附 Fate Core／FAE（CC-BY 3.0）規則範例庫與開局宣告。`0.4.0`（本次迭代）新增**敘事沉浸分層**（PLAYBOOK 分 IC／OOC 兩層、`系統雜訊` 三級預設安靜，修正 revision／工具過程／建檔／機制推導寫進玩家可見敘事的出戲反饋）與**敘事風格萃取範本**（八節空白範本＋萃取提示詞＋示範產物，讓玩家用有權使用的素材萃取專屬說書人風格；narrators/README 為單一權威）。`0.5.0` 為**外部遊玩反饋改善**，見〈階段 5〉（2026-07-16 發行）。`0.6.0`（本次迭代）範圍經決策看板 ceremony 於 2026-07-16 全數定案，見〈階段 6〉。

## 階段 0：決策與入口文件

- [x] 確認正式中英文名（Worldthread／織世）、套件／資料夾名（`worldthread-core`）與 MIT License。
- [x] 確認第一版範例題材、預設說書人組合及是否只使用原創素材（低魔奇幻邊境謎案；溫和、均衡、高壓三種說書人；範例全為原創）。`0.3.0` 起另隨附明確授權的第三方規則範例：Fate Core／FAE（CC-BY 3.0），四套（中英 × 核心／快速）置於 `extras/` 規則範例庫，擇一複製進 `game/reference/rules/` 啟用；標示見 `dist/worldthread-core/THIRD-PARTY-NOTICES.md`。
- [x] 依上述決策產生資訊完整的發行版 README 與 LICENSE。

## 階段 1：可攜範本骨架

- [x] 建立獨立 `dist/<package-name>/` 發行結構及 `template.json`。
- [x] 建立 `protocol/`、權限分層、狀態／日誌／摘要／索引／導演範本。
- [x] 建立可選語音轉寫格式、骰子紀錄和手動狀態更新降級流程。
- [x] 建立數種預設說書人，並讓使用者可追加設定檔。`0.4.0` 起提供敘事風格萃取範本（`game/templates/narrators/STYLE-EXTRACTION-TEMPLATE.md`、`tools/extract-narrator-style-prompt.md`、`examples/narrator-style-extracted-example.md`），可從素材萃取專屬風格，主持人支援極簡散文與八節結構化兩種顆粒度。
- [x] 建立規則書使用指南與自我劇透防護：`ADDING-RULEBOOKS.md`（權利、放置、轉檔、優先序）、盲拆流程（`private/director/source/` 慣例＋PLAYBOOK 模組盲拆節＋重混選項）、`tools/convert-rulebook-prompt.md` 轉檔提示詞（2026-07-14 定案）。
- [x] 建立平台中立擲骰工具 `tools/dice.mjs`：任何具執行能力的 agent 可呼叫、玩家亦可親自執行；程式擲骰、AI 僅裁定並逐字引用輸出（玩家公平性反饋，2026-07-14 定案納入 `0.1.0`；手機原生情境已於同日定案取消，行動裝置採遠端控制模式）。
- [x] 擲骰工具 Python 對等實作 `tools/dice.py`：同公式同 `--seed` 時與 `dice.mjs` 輸出逐位元一致，聊天沙盒限定單一語言（Python 或 JS）的環境皆有可用工具；契約由 `tools/dice.fixtures.jsonl` 黃金行夾具鎖定，CI 以 `scripts/test-dice-contract.ps1` 雙引擎驗證；PLAYBOOK 擲骰改三級選擇（程式擲骰→玩家擲骰→AI 自骰 `source: "ai"` 最終降級）（2026-07-14 定案，納入 `0.2.0`）。

## 階段 2：主持與記憶流程

- [x] 寫出平台中立 PLAYBOOK、資料 schema、RAG 重建規則與適配端說明。
- [x] 實作既有角色選擇與對話式創角兩條初始化流程。
- [x] 實作前線、鉤子、節奏、驚喜與玩家主導權的檢查表。
- [x] 定義語音歧義確認、回合更正與 TTS 行為。

## 階段 3：範例與測試

- [x] 提供可立即試玩的原創極小世界、角色及場景。
- [x] 以既有角色和共同創角各走一次初始化（2026-07-14 模擬演練＋對抗驗證通過；發行後由真實玩家再驗）。
- [x] 演練語音更正、規則裁定、前線推進、驚喜事件、私有資訊隔離及 RAG 重建（2026-07-14 五場隔離演練，含 NTFS 時間戳鑑識；發現的協定缺口記於交接檔 backlog）。
- [x] 以至少一種非 Codex 接入情境完成桌面驗證（Claude Code 全程接手開發並實走初始化與回合，即非 Codex 接入實證）。

## 階段 4：版本、CI/CD 與發行

- [x] 以 `template.json` 為單一版本來源，採 SemVer；`0.x` 為預穩定階段（CI 驗證 SemVer 與名稱一致性）。
- [x] Pull Request 與 `main` CI 檢查結構、版本、連結、範例、封裝與機密排除。
- [x] `vX.Y.Z` tag CD 驗證版本一致、封裝 `dist/`、產生 SHA-256 並發布 GitHub Release（2026-07-14 `v0.1.0` 首次 tag 觸發實測成功；同日 `v0.2.0` 再次驗證，Release 均含 ZIP 與 `.sha256` 資產）。
- [x] 在 GitHub 對 `main` 啟用 Pull Request 與 CI 成功的分支保護（2026-07-16 完成：ruleset「GitHub Flow main protect」——必走 PR、禁刪除、禁 force push、required status checks「Verify distributable package」（strict）、必要核准審查 0、無 bypass；經 API 查驗生效）。

具體 GitHub Flow、SemVer、Actions 設定和發行操作保留在不追蹤的 `GITHUB_REMOTE_SETUP.local.md`，避免本計畫與操作手冊重複。

## 階段 5：`0.5.0` 外部遊玩反饋改善（2026-07-16 定案）

外部反饋六項痛點（低階模型不遵規則書創角／判定、規則書預設 4–5 人團、存檔時機不明、庫存／任務找不到紀錄、AI 不主動提醒系統機制），加上角色卡結構化與分支保護補完：

- [x] 角色卡 `system` 通用容器層：規則欄位一律收進 `id`＋`stats`／`pools`／`tracks`／`tags`／`abilities` 五容器（DATA-SCHEMA §角色＋starter-state `character.json`），供未來可視化專案泛用讀取；人類可讀日誌／可視化介面定案另開專案，本範本維持核心模組定位。
- [x] 庫存與任務結構化：`game/state/inventory.json`、`quests.json`（DATA-SCHEMA 定義＋starter-state 骨架）；回合末寫入核對清單明列 character／world／inventory／quests；續玩缺檔自 starter-state 補建。
- [x] 規則速查卡＋強制核對：啟用完整規則系統時開局前必產 `game/state/rules-quickref.md`（創角步驟清單、核心判定流程、玩家可用資源機制表、單人調整摘要）；創角逐項勾核＋OOC 角色卡確認；判定先查卡再回查原書引 `ruling`（PLAYBOOK §初始化／§共同創角／§每回合）。
- [x] 存檔可見性：回合末一行極簡 OOC 存檔確認（`✦ 進度已存`），與資源選項提示同列「不受雜訊層級管制」的兩項 OOC；README／session-brief 明示「看到即可安全關閉對話」。
- [x] 資源機制提醒：擲骰／關鍵判定前，玩家有可影響結果的規則資源時一行 OOC 提示選項與代價，不得代玩家決定（PLAYBOOK §每回合第 2 步）。
- [x] 單人調整：PLAYBOOK 新增 §單人調整（遭遇規模、資源恢復、失敗後果、可選夥伴 NPC，調整記 `ruling`）；`convert-rulebook-prompt.md` 加創角／判定／資源機制章節必轉與「單人化注意」標記；ADDING-RULEBOOKS 同步。
- [x] 實體分層架構（playground 實跑回饋《WORLDTHREAD-0.4-架構更新需求》＋複盤紀錄，2026-07-16 第三輪定案併入本迭代）：`current-scene.json`（場景級工作紀錄）＋`entities/{items,npcs}/`（重要實體各一檔、單一事實來源、`confirmed_abilities`／`unknown_capabilities`／`known_info`、`last_updated_event_id` 事件溯源）＋`archive/` 封存（移動不刪除）；PLAYBOOK 分層讀取順序與「回應前實體核對」（對治物品能力錯置／NPC 知識漂移）；推測不升格條文；NPC 未揭露祕密置 `private/director/npcs/`（公私分層）；多人擴充僅 schema 預留（`holder`／`visibility` 以 id 指稱、不假設唯一主角），流程實作需先重議專案定位。
- [x] `main` 分支保護補完：ruleset 已有禁刪除、禁 force push、必走 PR；補 required status checks（CI job「Verify distributable package」，strict）並將必要核准審查數 1→0（單人 repo 無法自核 PR，實質門祛為 CI 綠燈）（2026-07-16 定案並完成，API 查驗生效）。

## 階段 6：`0.6.0`（2026-07-16 決策看板 ceremony 定案，14 題全數定案）

範圍主軸四條全納入：0.5.0 實測回饋、演練缺口 backlog 補洞、主持人操作日誌、多人擴充；另納入本輪新發現的發行包代理入口檔缺口。閘門採**局部制**：僅「動 `system` 容器／`entities` schema」的工作項須先核對 0.5.0 實測回饋，其餘平行推進。

- [ ] **0.5.0 實測清單**：產出六機制（rules-quickref 強制核對、單人調整、存檔確認、inventory/quests、system 容器、實體分層＋回應前實體核對）逐項檢核清單（勾選＋一句話、≤15 條）；置本機不追蹤檔自用，回饋由使用者手動摘要帶回（不含逐字戰役內容）。
- [x] **發行包代理入口檔**（PR #8）：dist 補建 `AGENTS.md`（工具中立主持入口＋遊戲守則以外的 agent 行為規範：先讀 session-brief／PLAYBOOK、玩家可見輸出不得引用 `private/director/`、不得修改 `protocol/`、探索邊界與隱私紀律）＋`CLAUDE.md`（一行 `@AGENTS.md` 匯入）；同步 PROJECT-DESIGN §2 結構圖、`verify-package.ps1` 結構斷言、發行包 README。
- [x] **契約補洞（缺口①②⑫，同批同 PR）**：DATA-SCHEMA 補 `summaries/current.md` 專節與 `world.json` 專節；⑫前線資訊禁止清單明文化。動工前 mini-ceremony 定案（2026-07-17）：摘要採最小三章節（前情提要／當前處境／未決線頭）；`known_facts` 升格物件陣列（`{fact, established_at_event_id, tags?}`）＋新增 `archived_facts` 封存分流（舊存檔採寬容模式不強制改寫）；frontmatter 僅 summaries 試點（`updated_at`／`covers_scene_ids`，推廣另案）；summaries 全章節受⑫同套禁止清單管轄。
- [x] **可見度操作規則（缺口④⑤）**：④ `events.jsonl` 混合可見度單檔的讀取過濾義務與祕密擲骰呈現方式；⑤ correction 的 `visibility` 繼承規則；與代理入口檔協同（AGENTS.md 補混合可見度過濾一句）。mini-ceremony 定案（2026-07-17）：⑤ correction 的 visibility **必須等於**原事件，改變可見度屬「揭露」另發 fact 事件；④ 導演可見度擲骰照實記檔供稽核，玩家可見層**只呈現後果與徵兆**（不呈現骰值、不告知擲骰），OOC 骰值揭示僅適用玩家可見擲骰。
- [x] **revision 衝突（缺口⑥，保守版）**：不自動合併、偵測衝突即停下請玩家仲裁。mini-ceremony 定案（2026-07-17）：提示時機＝**回合末 OOC 區塊**（敘事照常輸出、事件日誌照常 append）；提示內容＝**極簡三要素**（檔案路徑＋本回合基於的 revision 與檔案實際 revision＋三個仲裁選項），一律**不展示內容差異**（`private/director/` 檔零洩漏）；寫入範圍＝**僅衝突檔暫停**、其他無衝突檔照常更新（溯源機制容許 state 短暫落後於事件）。落地：DATA-SCHEMA 新增〈revision 衝突處理〉專節＋PLAYBOOK 每回合第 5 步引用。同批：發行包 `AGENTS.md` 去重修正（行為規範第 1、3 條改指路寫法消除與 DATA-SCHEMA 的雙準源、第 2 條防注入句擴為涵蓋全部規範的原則性一句；2026-07-17 使用者定案 B＋C 方案）。
- [x] **STATE-UPDATE 語意（缺口⑨⑩）**：檔案類型對應表——小檔（character/inventory/quests/world/current-scene）整檔 replace、`events.jsonl` 一律 append；不引入通用 patch 語法。落地（2026-07-17，大 ceremony 定案已覆蓋、無新增設計點）：PLAYBOOK〈降級輸出〉節補對應表（狀態 JSON／`.jsonl`／Markdown 狀態文件三類）＋單一 target 原則＋`expected_revision` 僅 replace 適用＋貼回前 revision 不符比照〈revision 衝突處理〉。
- [x] **RAG（缺口⑦⑧）**：補原則層級最小條文（不寫死數字／演算法）；另研究仿擲骰工具模式的可攜 RAG 工具。落地（2026-07-17 使用者定案）：RAG-PROTOCOL 新增〈原則條文〉四條——失效判準（分塊 `updated_at` 早於來源檔即失效、不得直接引用）、降級原則（無 rag 一律直接檢索原檔、快取缺席不得改變行為結果）、visibility 繼承（繼承來源、混合檔逐行歸屬、無法判定一律 `director` 寧嚴勿寬）、重建屬私下作業。可攜工具研究結論（採建議）：**現階段不做**——檢索無擲骰式信任邊界問題、中文分詞／浮點計分使零依賴雙實作維護成本過高；日後素材庫規模成為實際痛點時再議「純機械 chunker」（只掃描切塊、語意摘要留給 AI），屆時仍須先定案；嵌入向量觸平台中立紅線已排除、引入詞庫套件屬零依賴放寬須另定案。
- [x] **規則書知識庫外部筆記吸收（2026-07-17 使用者提供設計筆記《RAG vs Graphify》）**：對照分析定案——不推翻既有定案（可攜 RAG 工具暫不做、RAG 四原則、多人結論皆維持；graphify／決策樹裁決與「範本不綁定規則系統」結構性衝突且屬過度工程、sqlite＋embedding 觸平台中立紅線、開局 attribution OOC 顯示不採由 THIRD-PARTY-NOTICES 靜態滿足）。吸收的洞見：速查卡新增**條件式必要章節**「觸發條件與例外覆蓋表」（規則書含觸發鏈／狀態疊加／優先權機制時必產、輕量系統可省略）；RAG 分塊補選配 `license`／`attribution`／`modified` 授權欄位（自帶 CC 授權素材建快取時的來源追溯）。
- [x] **extras 全量重產（2026-07-17 使用者定案三題＋toolkit 定案）**：以 PR #17 新架構從來源重新處理 Fate 規則庫。定案：①全量重抓中英四套（英文＝brunobord/fate-srd-markdown 鏡像 clone；繁中＝faterpg Google Sites 86 頁 curl 抓取＋確定性 HTML→Markdown 抽取，不經模型轉述）；②extras 每檔改用 **YAML frontmatter** 承載 `source`／`license`／`attribution`／`modified`（與 RAG 分塊鍵一對一；**frontmatter 試點範圍正式由 summaries 擴大至 extras**；設計原則＝轉換規則書文件與遊玩狀態架構一律以 **AI 主持人使用效益優先**、不遷就人類閱讀）；③文件同步同批（ADDING-RULEBOOKS 補速查卡⑤與 frontmatter 轉檔規格、convert-rulebook-prompt 第 3／9 條、RAG-PROTOCOL 繼承句、DESIGN、根 README、發行包 AGENTS 路徑地圖）；④**Fate System Toolkit 納入**為第五套 `extras/fate-system-toolkit-en/`（CC-BY 3.0、9 章、僅英文；定位＝設計參考非可玩系統、不入 `rules/`；THIRD-PARTY-NOTICES 獨立段、作者名單依 SRD 署名 Robert Donoghue、Brian Engard、Brennan Taylor、Mike Olson、Mark Diaz Truman、Fred Hicks、Matthew Gandy）。忠實度驗證：英文新舊文字層逐字 diff 歸零，並修正舊版真實缺陷（骰面範例掉減號、段落重複收錄、abbr 中繼行殘留）；繁中差異全屬補齊舊版漏抄（各章索引頁導言、`<pre>` 範例區塊、範例角色表格欄）與剝除站方逐頁頁尾，無內容損失；Hacking Contests 英文標示依授權義務就地保留於繁中 04 章。
- [x] **主持人操作日誌（兼解缺口⑪）**：獨立 `game/private/director/host-log.jsonl`——追加式、最小鍵 `id/at/kind/facts`、靠目錄隔離刻意不設 `visibility` 欄、選配 `refs_event_id` 關聯事件；例外時寫（違規、例外裁定、私有邊界操作）＋預設啟用、不綁系統雜訊層級；保存／輪替比照 `archive/` 封存模式避免無界成長。落地（2026-07-17）：DATA-SCHEMA 新增〈主持人操作日誌〉專節（`kind` 基礎值域 `ruling`／`violation`／`boundary`、首次寫入時建檔、輪替移至 `private/director/archive/`）＋PLAYBOOK〈規則來源與優先序〉節補寫入義務、第 4 步臨時裁定指向本日誌；發行包不附空檔（戰役執行期資料不入 dist）。
- [x] **多人擴充**：目標形態＝「bot 中繼 Discord／Telegram 頻道 ↔ AI」遠端多人（bot 為另開專案，引用本範本為核心模組使溝通架構一致）；分人方式未定（第三人稱自標／論壇團式主持統整為候選）。0.6.0 先做架構研究（分人方式、訊息流、本範本需預留的接縫），研究結論可行即動工最小多人協定並依結果起草 §1 定位文字交使用者定案；**動 schema 前受局部閘門約束（須先核對 0.5.0 實測回饋，並顧可視化專案讀取契約相容）**。若定位定案為支援多人，**套件改名（移除 `-solo-`）綁定同一版本一起做**（dist 資料夾名＝manifest name＝ZIP 根目錄名三處一次協調變更；GitHub repo 改名自動重導、既有 tag 不動）（2026-07-17 使用者提出、綁定原則定案）。**架構研究完成＋定案（2026-07-17）**：分人方式＝第三人稱自標（bot 側可 user→pc-id 自動歸屬強化）＋戰鬥／高風險判定分層疊加點名 spotlight；訊息流＝收集窗口聚合結算（即時逐條因結構性踩 revision 衝突面排除；窗口參數屬 bot 專案）；擲骰＝bot 側執行 `dice.mjs` 頻道公開原始輸出（信任邊界升級、嚴守逐字回填 `source: "tool"`）；**PC 間祕密＝需要**——未來走與 visibility 正交的 `visible_to: [pc-ids]` 選用欄、**絕不擴充 visibility 三值 enum**（可視化契約相依），受局部閘門、本版只標記不落地；§1 定位＝D2（單人為主＋雙定位預告）。0.6.0 最小動作集已落地：DATA-SCHEMA 多人註記擴充（bot 中繼目標形態）＋events 選用 `actor` 鍵（行動者歸屬，與 `updates` 正交、additive 不受閘門）＋revision 仲裁歸屬原則一句。**改名決策更新（2026-07-17 使用者定案，取代「延至雙定位版」原議）**：改名**提前至 0.6.0 執行**——中性化名稱不承諾多人、無名實不符空窗，且外部引用累積最少的時點成本最低；新名 **`worldthread-core`**（生態系核心定位：衍生專案 bot／可視化／web UI 引用本專案為核心模組），dist 資料夾＝manifest name＝ZIP 根目錄＝GitHub repo 四處一致變更；§1（含生態系定位句）／§6 文字同批落地。舊 tag 與已發行 ZIP 不動。

## 主要風險與處置

| 風險 | 第一版處置 |
| --- | --- |
| 提示注入型素材 | 將素材視為資料；只有 `protocol/` 能改變流程。 |
| 私有資訊與雲端處理 | 清楚記錄信任邊界、私有區隔離及手動／本機降級路徑。 |
| 多端寫入衝突 | 單一主持寫入、revision、重讀、追加日誌與修正紀錄。 |
| 主持錯誤與長局遺忘 | 狀態、事件、摘要分層；可由日誌、Git 或備份回復。 |
| 骰點不可信 | 記錄骰子來源、結果與裁定；允許玩家自擲；AI 自骰僅限最終降級且必須標記 `source: "ai"`。 |
| 著作權與發行污染 | 僅用原創／授權範例；CI 拒絕私有內容、音檔、金鑰和 `.git`。 |

## 後續擴展（不阻擋 `0.1.0`）

- 可攜向量索引與嵌入模型版本契約。
- 戰役快照匯出、社群模組 manifest 與相容性宣告。
- 多代理鎖定機制、在地化、無障礙與進階內容安全工具。
- ~~主持人操作日誌~~：2026-07-16 決策看板定案採獨立 `host-log.jsonl` 方案並排入 `0.6.0`，見〈階段 6〉。
