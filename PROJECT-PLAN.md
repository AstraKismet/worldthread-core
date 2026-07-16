# 建置計畫與風險登錄

> 狀態：`v0.2.0` 已於 2026-07-14 發行（擲骰 Python 對等工具、契約測試與 AI 自骰降級；`v0.1.0` 同日稍早發行）。`0.3.0` 隨附 Fate Core／FAE（CC-BY 3.0）規則範例庫與開局宣告。`0.4.0`（本次迭代）新增**敘事沉浸分層**（PLAYBOOK 分 IC／OOC 兩層、`系統雜訊` 三級預設安靜，修正 revision／工具過程／建檔／機制推導寫進玩家可見敘事的出戲反饋）與**敘事風格萃取範本**（八節空白範本＋萃取提示詞＋示範產物，讓玩家用有權使用的素材萃取專屬說書人風格；narrators/README 為單一權威）。`0.5.0`（本次迭代）為**外部遊玩反饋改善**，見〈階段 5〉。

## 階段 0：決策與入口文件

- [x] 確認正式中英文名（Worldthread／織世）、套件／資料夾名（`worldthread-solo-adventure-template`）與 MIT License。
- [x] 確認第一版範例題材、預設說書人組合及是否只使用原創素材（低魔奇幻邊境謎案；溫和、均衡、高壓三種說書人；範例全為原創）。`0.3.0` 起另隨附明確授權的第三方規則範例：Fate Core／FAE（CC-BY 3.0），四套（中英 × 核心／快速）置於 `extras/` 規則範例庫，擇一複製進 `game/reference/rules/` 啟用；標示見 `dist/worldthread-solo-adventure-template/THIRD-PARTY-NOTICES.md`。
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
- [ ] 在 GitHub 對 `main` 啟用 Pull Request 與 CI 成功的分支保護（2026-07-16 查驗：PR／禁刪除／禁 force push 已生效，尚缺 CI required status checks——補完項見〈階段 5〉末條，完成後兩處一併勾銷）。

具體 GitHub Flow、SemVer、Actions 設定和發行操作保留在不追蹤的 `GITHUB_REMOTE_SETUP.local.md`，避免本計畫與操作手冊重複。

## 階段 5：`0.5.0` 外部遊玩反饋改善（2026-07-16 定案）

外部反饋六項痛點（低階模型不遵規則書創角／判定、規則書預設 4–5 人團、存檔時機不明、庫存／任務找不到紀錄、AI 不主動提醒系統機制），加上角色卡結構化與分支保護補完：

- [x] 角色卡 `system` 通用容器層：規則欄位一律收進 `id`＋`stats`／`pools`／`tracks`／`tags`／`abilities` 五容器（DATA-SCHEMA §角色＋starter-state `character.json`），供未來可視化專案泛用讀取；人類可讀日誌／可視化介面定案另開專案，本範本維持核心模組定位。
- [x] 庫存與任務結構化：`game/state/inventory.json`、`quests.json`（DATA-SCHEMA 定義＋starter-state 骨架）；回合末寫入核對清單明列 character／world／inventory／quests；續玩缺檔自 starter-state 補建。
- [x] 規則速查卡＋強制核對：啟用完整規則系統時開局前必產 `game/state/rules-quickref.md`（創角步驟清單、核心判定流程、玩家可用資源機制表、單人調整摘要）；創角逐項勾核＋OOC 角色卡確認；判定先查卡再回查原書引 `ruling`（PLAYBOOK §初始化／§共同創角／§每回合）。
- [x] 存檔可見性：回合末一行極簡 OOC 存檔確認（`✦ 進度已存`），與資源選項提示同列「不受雜訊層級管制」的兩項 OOC；README／session-brief 明示「看到即可安全關閉對話」。
- [x] 資源機制提醒：擲骰／關鍵判定前，玩家有可影響結果的規則資源時一行 OOC 提示選項與代價，不得代玩家決定（PLAYBOOK §每回合第 2 步）。
- [x] 單人調整：PLAYBOOK 新增 §單人調整（遭遇規模、資源恢復、失敗後果、可選夥伴 NPC，調整記 `ruling`）；`convert-rulebook-prompt.md` 加創角／判定／資源機制章節必轉與「單人化注意」標記；ADDING-RULEBOOKS 同步。
- [ ] `main` 分支保護補完：ruleset 已有禁刪除、禁 force push、必走 PR；補 required status checks（CI job「Verify distributable package」）並將必要核准審查數 1→0（單人 repo 無法自核 PR，實質門祛為 CI 綠燈）（2026-07-16 定案）。

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
- **主持人操作日誌（AI 操作 log）**：稽核主持人是否遵守約束（敘事沉浸分層、規則優先、私有隔離）的 director-private 日誌。約束：絕不洩入玩家可見敘事、絕不洩漏 director 祕密；平台中立（UTF-8、可刪重建或追加式）。候選方案（未定案，留待 milestone ceremony）：① 復用 `events.jsonl` 加 `kind:"op"`＋`visibility:"director"`；② 新增 `game/private/director/host-log.jsonl` 獨立日誌；③ 最小無 schema 版（`除錯` 模式寫自由格式 `session-log.md`）。與 `0.4.0` 系統雜訊 `除錯` 級（聊天內即時 bookkeeping）互補而非重複（2026-07-16 使用者定案排入 backlog）。
