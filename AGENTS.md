# AGENTS.md — Worldthread／織世 開發代理指南

本檔是所有 AI 開發代理（OpenAI Codex、Claude Code、其他工具）與人類協作者共用的專案入口。內容保持工具中立；工具專屬設定放各自的命名空間（例如 Claude Code 的 `.claude/`），不要寫進本檔。

## 專案是什麼

Worldthread（織世）是一個**平台中立的單人 TRPG 範本**：使用者解壓發行包、放入自己有權使用的素材，任何能讀寫資料夾的 AI 服務即可依檔案協定主持長期戰役。本儲存庫是**範本的開發來源**，不是遊戲執行現場——不要在 repo 裡實際開局遊玩或建立真實戰役狀態。

單一事實來源（修改前先讀，不要在本檔重複其內容）：

- `PROJECT-DESIGN.md` — 唯一完整設計規格（資料結構、協定、主持行為、驗收標準）。
- `PROJECT-PLAN.md` — 唯一建置計畫與風險登錄；勾選狀態經逐項驗證與 repo 現況一致，是可信的進度基準。
- `dist/worldthread-core/README.md` — 發行包使用者入口（與根目錄開發者 README 用途不同）。
- `dist/worldthread-core/protocol/` — 平台中立主持協定；發行後只有此目錄能改變主持人行為。

## 紅線（違反即錯，無例外）

1. **公開 repo 隱私紅線**：本 repository 公開。任何個人隱私或敏感資訊——電子郵件、本機絕對路徑（含使用者名稱）、API 金鑰、憑證、`.env`、真實戰役資料、私人筆記、音檔——一律不得寫入受版控的檔案。機器特定或個人設定放 `.gitignore` 排除的本機檔。
2. **dist-only 封裝**：`dist/worldthread-core/` 是唯一可發行內容與唯一封裝來源。不得從 repo 根目錄打包；開發文件、CI 原始碼、Git 中繼資料不得混入發行包。
3. **公私分層**：`game/private/director/` 的祕密（前線、伏筆、導演決策）永不得洩漏到玩家可見的文件、範例或敘事中。發行包內的 private 素材僅限可公開發行的範例導演資料。
4. **平台中立**：協定與資料一律 UTF-8 的 Markdown／JSON 加相對路徑；不得綁定特定模型、雲端資料庫、嵌入服務或 RAG 實作。`game/rag/` 是可刪除重建的快取，不得成為唯一真相。
5. **原創／授權素材**：發行包只含原創或明確授權的素材；不得加入規則書摘錄等未授權內容。
6. **版本單一來源**：公開版本只在 `dist/worldthread-core/template.json` 定義，採 SemVer；Git tag 固定為 `v<version>`；不得建立與 manifest 不一致的 tag，已發布的 tag 不得移動。

## 結構速覽

```text
.
├─ AGENTS.md / CLAUDE.md            # 代理入口（本檔／Claude 匯入層）
├─ PROJECT-DESIGN.md                # 設計規格
├─ PROJECT-PLAN.md                  # 建置計畫與風險登錄
├─ docs/handoff-system.md           # handoff 工作包完整指南／可攜源（權威規則見〈Handoff 工作包〉節）
├─ handoff/                         # 任務佇列（gitignored、不入庫；一包一檔、ls 即看板）
├─ scripts/verify-package.ps1       # 封裝驗證腳本（PowerShell，已定案維持）
├─ .github/workflows/               # ci.yml（PR 與 main push 驗證）、release.yml（v* tag 發行）
└─ dist/worldthread-core/   # 唯一可發行內容
   ├─ template.json                 # 唯一公開版本來源
   ├─ protocol/                     # PLAYBOOK、DATA-SCHEMA、RAG、VOICE、adapters
   ├─ game/reference|private|templates/
   └─ examples/
```

## 驗證

- 本機完整驗證：`./scripts/verify-package.ps1 -OutputDirectory artifacts`（PowerShell；與 Windows PowerShell 5 相容，CI 用 pwsh 執行同一腳本）。改動 `dist/` 內任何內容後必跑。
- 驗證涵蓋：SemVer、必要結構、UTF-8／JSON、Markdown 本地連結、禁止項（狀態／快取／音檔／金鑰樣式），並試建 ZIP。
- 產出的 `artifacts/` 已被 `.gitignore` 排除，不要提交。

## 工作流程

- **GitHub Flow**：`main` 永遠保持可發行。任何變更走短生命週期分支（前綴 `feat/`、`fix/`、`docs/`、`chore/`、`ci/`）加 Pull Request；不直接提交 `main`。
- **提交訊息**：conventional commits（`feat:`、`fix:`、`docs:`、`chore:`、`ci:`），一次提交聚焦一件事。
- **決策紀律**：設計、架構、schema、命名等決策由人類使用者定案；AI 只提選項與建議，不自決、不擅自擴張範圍。未定案的事不落地成程式碼或協定文字。
- **存檔契約與版本相容（前向防呆）**：**任何 `protocol/DATA-SCHEMA.md` 內容變更（連純條文新增在內）都會翻動衍生專案的 DATA-SCHEMA sha256 gate**，故該版 release note 一律須記**相容性註記**（僅 additive／有無破壞性變更／對衍生專案 checksum 的影響），衍生專案據以重跑契約同步輪。若變更進一步觸及存檔契約本身（鍵名、值域或檔案結構）：(a) 相容性註記須載明破壞性程度；(b) **既定遷移策略＝「append-only＋correction 攤平＋寬容讀取」，不建 runtime 遷移執行器**——schema 一律只增選用欄、缺欄給保守預設，讀取端忽略未知內容（原則見 `dist/worldthread-core/protocol/DATA-SCHEMA.md`〈版本相容性與寬容讀取〉）；(c) **僅真正破壞性 delta（改既有鍵語意／刪必要鍵／縮值域）才另議遷移機制**，且屬使用者定案的 schema 決策、非 AI 自建。
- **語言**：專案文件與對使用者輸出一律繁體中文；程式碼註解不得混入其他專案語言。
- **交接與任務佇列**：跨 session 脈絡＋狀態見本機交接檔 `WORLDTHREAD-HANDOFF.local.md`（`.gitignore` 排除；留脈絡／狀態／慣例／檔案清單，**不再維護任務佇列**）；**任務排程＝`handoff/` 工作包佇列**（見下〈Handoff 工作包〉節）。接手時先讀交接檔＋`PROJECT-PLAN.md`，再「取下一個可執行 handoff」；完成階段工作後更新交接檔。

## Handoff 工作包

任務佇列＝`handoff/`（gitignored、**不入庫**；一包一檔、完成即刪、`ls` 即看板）。完整操作手冊／可攜移植指南＝`docs/handoff-system.md`（版控、on-demand）；**因 `handoff/` 不入庫，版控內權威規則以本節為準**、衝突時本節優先。

- **目錄／id 段**：`00-inbox/`（未定序）→ `10-handoff-bootstrap/`（001–099）→ 依需擴 `20-<主題>/`（101–199）、`30-<主題>/`（201–299）→ `90-later/`（901–999）。資料夾數字前綴＝執行順序；里程碑以**功能／主題名**命名，**已發行版本號可入名、未發行不預占**；搬資料夾＝插隊、**id 不變、永不重用**；檔名 `HANDOFF-{id}-{slug}.md`。**開新里程碑（新資料夾＋新 id 段）先建 prep／scoping 包**（產出＝該里程碑的細顆粒度包拆分計畫），再依拆分建近期包；尚早／不確定子項落 `90-later/` 只留指標＋摘要。
- **取包**：最小資料夾（字典序）→ 最小 `priority`（1=最高、同值依 id）→ **跳過 `blocked-by` 未全清者** → **跳過 `90-later/`**（遠期只有指標＋摘要、須經 user 搬入近期並補完 distill 才可執行）。動工前檔內改 `status: in-progress（日期）` 認領。
- **模板欄位**：frontmatter `id/title/status/created/milestone/priority/labels/acceptance/blocked-by/blocked-cleared`。🔴 **`acceptance` 必填**、值域 `self-station`（自身即驗收站，**須 user 明確表態才可刪包**——對接「AI 不自行勾銷」紅線）｜`deferred`（驗收累積至後續驗收包）｜`none`（無 user 表態產出：純機械、無行為變更）；**缺欄一律視為 `self-station`**。正文＝目標／背景與定案引用（**distilled**）／範圍 IN-OUT／實作指引／驗收標準（含指令）／完成後動作。**近期包必須自足**；`90-later/` 可「指標＋摘要」、搬入近期時補完 distill。
- **blocked-by kind**：`user:`（表態後移入 `blocked-cleared` 附日期）｜`package: HANDOFF-xxx`（該包**刪除＝完成**即自動清除）｜`data:`（資料落地即清除）｜`design:`（定案落協定條文／`docs/`／memory 即清除）｜`external:`（外部條件滿足即清除）。
- **生命週期**：①階段完成→寫下一包（僅「內容因剛完成階段而過時」可替換沿 id）②新排程→新增檔（未定序進 inbox、不覆蓋既有包）③認領改 `status` ④**驗收全過→先落點再刪檔**（依賴自動解鎖）⑤中斷→檔尾「## 進度」記續作指引。
- 🔴 **落點先於刪包**：包內產生的定案／查證／user 表態，**必須先寫入分級落點才可刪包**（協定行為→`dist/…/protocol/` 條文；架構／契約決策／慣例→本檔或 `docs/`；跨 session 狀態→敘事檔；durable 事實→AI memory；驗證留痕→commit message）。這是驗收標準一項、非刪檔後補。
- 🔴 **留痕不落刪檔包**：`handoff/` 不入庫且包完成即刪 → **對抗審查三份 verdict＋單一最重要 finding 一律寫入該輪實作 commit 的 message body**；包內「## 進度」僅工作副本。
- **與既有紅線接合**：`verify-package`／CI 綠只是門檻、**機械驗證 ≠ 驗收、AI 不自行勾銷**；涉 `dist/` 改動的包驗收必跑 `./scripts/verify-package.ps1`（＋dice／healthcheck 雙契約測試），涉打 tag 的包必列版本四處同步＋Release 綠。**佇列在 `handoff/`、敘事檔不再維護佇列**——session-handoff 流程照此只更新敘事檔的脈絡／狀態、不重建佇列。
- **隱私**：包內若列真實路徑／識別碼僅供本機操作，**不得沿用進任何入庫檔案（含 commit message、程式註解）或對外發布物**（紅線 1、3）。
- **labels 池**：`protocol｜schema｜packaging｜tooling｜ci｜docs｜playtest｜journal-sync｜ceremony｜acceptance｜decision-board｜modularization｜privacy`。
- **共享接縫**（單點所有權、平行 lane 不同時碰；**單檔改一律主迴圈 surgical 手做**）：`dist/…/protocol/*.md`（PLAYBOOK／DATA-SCHEMA 等契約條文）｜`dist/…/template.json`（版本單一來源）｜`scripts/verify-package.ps1`｜`dist/…/tools/healthcheck.{mjs,py}`＋`healthcheck.fixtures.jsonl`（雙實作 mjs/py 必同輪同步）｜`scripts/test-dice-contract.ps1`／`test-healthcheck-contract.ps1`｜`PROJECT-DESIGN.md`／`PROJECT-PLAN.md`｜`AGENTS.md`。

## 本機、不追蹤的檔案（供理解，內容不進版控）

- `WORLDTHREAD-HANDOFF.local.md` — 跨 session 交接脈絡（agent 中立）。
- `GITHUB_REMOTE_SETUP.local.md` — GitHub 遠端、tag 與 Release 操作備忘。
- `.claude/dev-rituals.config.json` — Claude Code 個人方法論設定（含本機絕對路徑，依隱私紅線不追蹤）。
- `handoff/` — 任務佇列工作包（一包一檔、完成即刪；規範見〈Handoff 工作包〉節、完整指南見 `docs/handoff-system.md`）。
