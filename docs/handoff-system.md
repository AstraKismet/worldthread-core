# Handoff 工作包系統——完整指南（worldthread-core）

> **本檔定位**：handoff 工作包系統的完整教學、設計理據與可攜移植底稿。**版控內權威規則以 `AGENTS.md`〈Handoff 工作包〉節為準**（該節精簡、always-load）；本檔提供該節的展開、理據與移植 checklist，屬 on-demand 參考——衝突時以 `AGENTS.md` 節優先。
>
> **可攜性**：本檔即對外移植源——要把本系統帶到其他專案，複製本檔為底稿、依 §8 checklist 調整即可。
>
> 來源：worldthread-journal `handoff/HANDOFF-SYSTEM-GUIDE.md`（Celurion 起源）＋本專案 2026-07-21 導入 ceremony 定案（①A′ 規範拆兩層／②A 主題式精簡／③A 敘事檔拆分／④A 可認領可完成交付）。

## 1. 核心概念與設計理念

**一個 handoff 檔＝一個已排定的工作包。** 新 session（人或 AI）指定參照檔執行；完成即刪除該檔。

| 設計 | 理念 |
|---|---|
| 檔案即佇列（file-per-package） | 不依賴外部工具；`ls handoff/` 即看板；git 不追蹤（`handoff/` 進 `.gitignore`），避免工作流噪音污染版本史——**規範本身寫在 `AGENTS.md`／本檔才是唯一持久紀錄** |
| 完成＝刪檔 | 佇列永遠只剩「未做的事」；刪檔同時自動清除他包對它的 `blocked-by` 依賴（引用消失＝解鎖），零記賬成本 |
| 工作包必須自足 | 執行 session 無前一 session 的記憶——定案／契約／紅線必須 **distill 進包內**，不能只給文件指標（遠期包例外，見 §4 末） |
| id 全域唯一、永不重用 | 供 `blocked-by` 引用與未來遷移 issue 系統的對映錨點 |
| 資料夾＝里程碑＝執行順序 | 數字前綴字典序即優先序；搬資料夾＝插隊，id 不變 |
| 定案不存在 handoff 裡 | handoff 只是**交棒載體**；定案的正式落點見 §7 分級落點；handoff 包會被刪 |

## 2. 目錄結構與 id 段（本專案定案＝②A 主題式精簡）

```
handoff/
  00-inbox/                新排程尚未定序者先落此（整理時移入對應里程碑資料夾）
  10-handoff-bootstrap/    目前里程碑（id 範圍 001–099）
  90-later/                遠期確定項（id 範圍 901–999；只有指標＋摘要）
```

- 資料夾數字前綴＝執行順序（字典序）；里程碑以**功能／主題名**命名。
- **已發行的版本號可入資料夾名、未發行者不預占**（版本號須經 user 確認）。
- 新增里程碑＝新資料夾＋新 id 段：`20-<主題>/`＝101–199、`30-<主題>/`＝201–299，依此類推。
- **檔案搬資料夾時 id 不變**（id 屬於包、不屬於里程碑）；**id 永不重用**（哪怕包被取消）。
- 檔名格式：`HANDOFF-{id}-{kebab-case-slug}.md`。
- **開新里程碑**（新資料夾＋新 id 段）先建一個 **prep／scoping 包**（產出＝該里程碑的細顆粒度包拆分計畫），再依拆分結果建近期包；不確定／尚早的子項落 `90-later/` 只留指標＋摘要。

## 3. 取包規則（每次開工的定位演算法）

最小資料夾（字典序）→ 最小 `priority`（1=最高；同值依 id）→ **跳過任何 `blocked-by` 未全數清除者** → **跳過 `90-later/`**（遠期包只有「指標＋摘要」、未 distill，恆不參與自動取包，須經 user 指示搬入近期資料夾並補完 distill 後才可執行）。

啟動語：
- 「依 `handoff/<資料夾>/HANDOFF-xxx` 執行」——指定包。
- 「取下一個可執行 handoff」——按上述演算法自動定位。

動工前必改檔內 `status: in-progress（<日期>）` 認領，防兩個 session 搶同一包。

## 4. 工作包模板（全欄位）

```markdown
---
id: HANDOFF-xxx          # 全域唯一、永不重用
title: <一句話標題>
status: pending          # pending | in-progress（認領時改、附日期）
created: <YYYY-MM-DD>
milestone: <與所在資料夾一致>
priority: <資料夾內排序，1=最高；同 priority 依 id>
labels: [<見 §10 labels 池>]
acceptance: self-station # 必填；self-station | deferred | none（見下）
blocked-by:
  - "<kind>: <說明>"     # 空陣列 = 可立即執行；kind 見 §5
blocked-cleared: []      # 已清除的阻塞（附清除日期），供稽核
---
## 目標（一段話）
## 背景與定案引用（distilled——執行時不必重查原始文件即可動工）
## 範圍（IN / OUT）
## 實作指引（檔案清單、接縫所有權、紅線）
## 驗收標準（可執行的檢核，含測試指令）
## 完成後動作（固定：驗收→落點→刪本檔→寫下一包；另列特殊事項）
```

**`acceptance` 值域**（對接本專案「AI 不自行勾銷、驗收以 user 為準」紅線）：

- `self-station`＝自身即驗收站，**須 user 明確表態才可刪包**（凡涉協定行為、playground 實測、打 tag、PLAN 勾選者）。
- `deferred`＝驗收累積至後續某驗收包（刪包前須把走查項逐條追加進該驗收包）。
- `none`＝無 user 表態產出（純機械、無行為變更）。
- 🔴 **缺此欄一律視為 `self-station`**（倒向安全側，漏寫不得靜默降級為「AI 可自刪」）。

**自足性分級**：近期包（目前／下一里程碑）必須完整 distill；`90-later/` 允許「背景＝指標＋關鍵約束摘要」，但**升級搬入近期資料夾時必須補完 distill**（這是搬移動作的一部分、不是可選項）。

## 5. blocked-by 結構化（每項一條 `kind: 說明` 格式）

| kind | 語意 | 清除方式 |
|---|---|---|
| `user:` | 需 user 輸入／定案 | user 表態後移入 `blocked-cleared` 附日期 |
| `package: HANDOFF-xxx` | 依賴另一包 | 該包**刪除（＝完成）即自動清除**——無需回頭改檔 |
| `data:` | 缺資料 | 資料落地即清除 |
| `design:` | 需先跑設計 ceremony／架構定案 | 定案落協定條文／`docs/`／memory 即清除 |
| `external:` | 外部服務／基建 | 外部條件滿足即清除 |

## 6. 生命週期（五個時刻）

1. **階段完成→寫下一包**：若已有「待啟動」包且內容因本階段而過時→**替換其內容**（沿用 id）；否則建新 id 檔。
2. **未啟動期間出現新排程**→**新增**檔案（未定序先進 `00-inbox/`；不覆蓋既有待啟動包）；插隊＝搬資料夾或改 `priority`；id 永不重用。
3. **session 認領**→檔內改 `status: in-progress（<日期>）` 再動工——防兩個 session 搶同一包。
4. **完成**→驗收標準全數通過→**先落點（§7）再刪檔**（引用它的 `blocked-by` 隨之視為清除）→依規則 1 寫下一包。
5. **中斷未完**→檔尾加／更新「## 進度」節：已完成什麼、續作方式（下個 session 讀什麼、照什麼順序做）、執行期間收到的 user 臨時指示（對本包持續有效者）。

### 運行經驗補充

- **進度節是模型切換／額度中斷的保險**：長任務先建骨架＋把「續作指引」寫進包與產出文件，任何 session（甚至換模型）讀包即可無縫接手。
- **執行中收到的 user 定向**：立即落到包的進度節＋產出文件本身（雙落點），不要只留在對話裡。

## 7. 與其他機制的關係（定案落點分級）

**定案不落 handoff 包內**（包會被刪）。落點分級：

- **協定行為** → `dist/worldthread-core/protocol/` 條文（發行後唯一能改主持行為處）。
- **架構／契約決策、開發慣例** → `AGENTS.md`（升格為常駐規範者）或 `docs/`。
- **跨 session 狀態／進度快照** → 敘事交接檔 `WORLDTHREAD-HANDOFF.local.md`（本機、不入庫）。③A 定案：敘事檔留脈絡／狀態／慣例／檔案清單，**不再維護任務佇列**。
- **durable 事實** → AI memory（一事實一檔）。
- **驗證留痕** → commit message body（🔴 **不落會被刪的包內**：對抗審查三份 verdict＋單一最重要 finding 一律寫入該輪實作 commit）。
- **git**：`handoff/` 全目錄 gitignore；工作產出照專案常規 commit（里程碑式）；包的刪除不留 git 痕跡——這是特性不是缺陷（佇列狀態不值得版控，規範與定案才值得）。
- **session-handoff skill／dev-rituals**：③A 定案下 skill 職能不變（仍更新敘事檔），`dev-rituals.config.json` 的 `handoffFile` 仍指向敘事檔；skill 只更新敘事檔的脈絡／狀態、**不重建佇列**。⚠ 若未來改走「整併退場」（③B、須改 skill target）須另出具給其他用同 skill 專案的遷移指示文件。
- **降級產出台帳**：`DEGRADED-DESIGN-REGISTRY.local.md` 結構上即一個包佇列，屬本系統首批遷移對象之一。
- **未來遷移 issue 系統**：frontmatter 即 issue 欄位對映（title／labels／milestone／blocked-by→依賴）；屆時「建包」→開 issue、「刪包」→關 issue，模板與生命週期不變。

## 8. 移植到其他專案的 checklist

1. 建 `handoff/` 目錄結構（§2；依專案節奏調整資料夾與 id 段）＋`.gitignore` 加 `handoff/`。
2. 把權威規則寫進目標專案的 agent 入口檔（本專案＝`AGENTS.md`〈Handoff 工作包〉節）——**規則必須在版控內**；完整指南（本檔）複製一份到目標專案的版控 `docs/`。
3. 長期記憶／onboarding 加一行：「工作排程一律看 `handoff/`；取包規則見 `AGENTS.md`〈Handoff 工作包〉」。
4. 盤點既有待辦（issue／TODO／舊 plan／敘事檔佇列）→逐項轉包：近期完整 distill、遠期指標＋摘要；舊佇列轉完即移除。
5. 定義該專案的 **labels 池**與（若多 agent 平行）**共享接縫清單**——「單點所有權、兩個 lane 不同時碰同一接縫」寫進規範。
6. 第一次運行驗證：跑一輪「取下一個可執行 handoff→認領→完成→刪檔→寫下一包」全循環，確認 `blocked-by` 解鎖語意被正確執行。

## 9. 常見陷阱

- **包不自足**：執行 session 花半天重查上下文＝distill 失職。驗收：新 session 只讀包能否直接動工。
- **忘記認領**：兩個 session 撞包。動工前必改 `status`。
- **完成不刪檔**：佇列腐化、依賴不解鎖。驗收過就刪，猶豫的部分寫進下一包。
- **把定案只寫在包裡**：包會被刪——定案必須先落分級落點（§7）再刪包。
- **覆蓋待啟動包**：只有「內容因剛完成階段而過時」才允許替換內容（沿 id）；新需求一律新檔。
- **id 重用**：永不。哪怕包被取消（取消＝刪檔＋在對應落點記一行取消緣由）。
- **在包內自我認證**：留痕不落刪檔包（§7）；三份 verdict 進 commit message。

## 10. worldthread-core 專屬

- **labels 池**：`protocol｜schema｜packaging｜tooling｜ci｜docs｜playtest｜journal-sync｜ceremony｜acceptance｜decision-board｜modularization｜privacy`。
- **共享接縫**（單點所有權、平行 lane 不同時碰；**單檔改一律主迴圈 surgical 手做**）：`dist/…/protocol/*.md`（PLAYBOOK／DATA-SCHEMA 等契約條文）｜`dist/…/template.json`（版本單一來源）｜`scripts/verify-package.ps1`｜`dist/…/tools/healthcheck.{mjs,py}`＋`healthcheck.fixtures.jsonl`（雙實作 mjs/py 必同輪同步）｜`scripts/test-dice-contract.ps1`／`test-healthcheck-contract.ps1`｜`PROJECT-DESIGN.md`／`PROJECT-PLAN.md`｜`AGENTS.md`。
- **驗收接合**：機械驗證（`verify-package`／CI／契約測試綠）**≠ 驗收**；`acceptance:self-station` 包須 user 明確表態才可刪；PLAN 勾選以 user 驗收為準（AI 不自行勾銷）。
- **隱私紅線**：包內若列真實路徑／識別碼／外部戰役資料僅供本機操作，**不得沿用進任何入庫檔案（含 commit message、程式註解）或對外發布物**（`AGENTS.md` 紅線 1、3）。
- **對抗審查**：涉版控／協定／腳本的包，每輪實作後照 `.claude/rules/claude-workflow.md`〈對抗審查格式〉發三 lens、主迴圈採納修正後重親驗；verdict 進 commit message。
