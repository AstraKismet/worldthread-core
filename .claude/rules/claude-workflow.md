# Claude Code 專屬：Workflow 編排與 subagent 分發規範

> 本檔僅供 Claude Code 使用（其他代理請忽略）。使用者 2026-07-14 定案、2026-07-18 擴充定案（架構設計＝fable、對抗審查格式、驗收紀律）；另一專案的具體示例已改寫為本專案原生條文。

## Model 分發階梯（四級：haiku＜sonnet＜opus＜fable）

主迴圈＝session model；依狀況每 session 於 Fable/Opus 間切換。**fable 級要視為不一定能使用。**

| 工作類型 | 派發方式 | 說明 |
| --- | --- | --- |
| 純檔案定位／檢索（找 X 在哪、列 caller、grep pattern） | `agentType:'Explore', model:'haiku'` | haiku 只在純 retrieval 安全 |
| 設計／架構調查（dev-research-advisor：seam 測繪＋Options＋cons-mitigation） | `model:'sonnet'` 預設 | 產出餵 ceremony、由主迴圈再合成。升 opus 僅限例外：①把 seam 正確 map 出來本身即難點 ②錯誤事實主迴圈難察覺且代價高 ③該調查無主迴圈再合成的終局性。**調查／檢索天花板＝opus，fable 不對其開放**（opus 用於 retrieval 已屬過剩、fable 更甚） |
| 架構「設計」 | **一律 fable**：主迴圈（Fable session）親做、或 workflow `agent()` 顯式 `model:'fable'` | 2026-07-14 使用者定案、2026-07-18 收錄本檔。判準＝輸出是否為**將凍結的架構決策／契約**——schema 形狀、公開 API、跨模組契約、為 ceremony 產 Options＋cons-mitigation 的設計 lane 皆屬之。與「調查／檢索天花板＝opus」不衝突：天花板條款限檢索／事實調查；sonnet 僅適用「事實測繪／現況盤點」類調查。fable 不可用時＝主迴圈以 session model 親做並於產出標註降級（2026-07-19 定案） |
| 程式碼實作 | `model:'sonnet'` lane 或主迴圈（session model）直接做 | |
| 主迴圈合成／ceremony／cons-mitigation／AskUserQuestion／對抗審查驗證誠實（test-honesty）lens | **不下放**：agent() 不帶 model | 繼承 session model、自動對齊主迴圈（Fable session→fable、Opus session→opus） |

理由：調查產出被主迴圈再合成、事實準確度才是紅線；dev-research-advisor 的判斷／cons-mitigation 用 sonnet 才不逼主迴圈重做。

## Fork 與 model 覆寫

- ⚠ model 覆寫對 fork **無效**（fork 恆繼承父＝主迴圈 model、成本同級）→ 可下放的 fan-out 一律顯式 `agentType`＋`model`，勿用 fork 做檢索／機械工作。
- workflow `agent()` 覆寫須顯式帶 `model` 才生效（enum 含 `'fable'`）。
- `agent()` 必須顯式 `agentType`（ultracode／workflow 不會自動挑自建 agent；先對照 dev-rituals 索引挑對的 specialist）。

## Task brief 撰寫（零設計研究雙刃）

sonnet agent 不自行調查 → 凡未 distill 進 brief 的決策／約束、agent 一律不會知道（→ 靜默簡化、契約鍵名斷裂、覆寫共享接縫的根因）。

task brief 固定格式，必須 distill：

1. milestone 條目；
2. 規格節號（引用 `PROJECT-DESIGN.md`／`protocol/` 節次）；
3. reusable 表（可重用的既有檔案／函式／協定）；
4. distilled 決策／約束：ceremony 定案、研究結論、`AGENTS.md` 紅線、既有架構契約、命名慣例（本專案例：dist-only 封裝、公私分層 `private/director/` 不外洩、平台中立、公開 repo 隱私紅線、visibility 三值 enum 不擴充）、精確契約／鍵名／DTO 形狀。

**發 agent 前主迴圈必須核對「研究結論／設計決策／約束條件是否已 distill 進 task prompt」，缺則補齊再發。**

## 平行 sonnet 實作六坑

①測試遷就假綠 ②契約鍵名斷裂 ③衍生／複製檔未同步 ④註解混入非專案語言（本專案語言為繁體中文）⑤共享接縫被平行 agent 重實作覆寫 ⑥agent 任務漂移漏交付

對策：**對抗審查必開**（格式見〈對抗審查格式〉）＋主迴圈核對交付物清單＋重跑；平行 lane 須 disjoint 檔＋brief 明文「不碰對方檔／bundle」；**共享接縫單檔改一律主迴圈 surgical 手做、不發平行 agent**。

## 對抗審查格式

- 每輪實作後 fan-out **3 獨立 reviewer**，lens：①**驗證誠實（test-honesty）**〔最關鍵：假綠、恆真斷言、守衛短路跳過斷言、數值逐項核算、確定性；不得把未跑過的驗證宣稱為綠〕②**correctness 或 docs-accuracy**〔依變更性質二擇一：協定／文件變更→docs-accuracy、腳本／CI 變更→correctness〕③**contract-integration**〔契約完整性：DATA-SCHEMA 鍵名、`template.json` 版本單一來源、visibility 三值 enum 不擴充、衍生專案 checksum 契約、PLAYBOOK／DATA-SCHEMA／發行包 README／session-brief／DESIGN 交叉引用一致〕。
- **model**：①驗證誠實＝主迴圈同級（`agent()` 不帶 `model` 繼承 session model；假綠守門、不下放）；②③預設 `sonnet`，高風險工作項（schema 契約、公私分層、revision 衝突／擲骰確定性）可升 `opus`。
- reviewer **唯讀主樹、不可 `isolation:'worktree'`**（worktree 看不到未 commit 改動）；**reviewer 不得 Edit／不得動檔**（mutation 親證與所有修正一律主迴圈做）。
- 每 finding 標 **BLOCKER／MAJOR／MINOR／NIT**＋file:line＋具體修法；末給明確 **verdict（SAFE／NOT SAFE）**＋單一最重要 finding。schema 強制 StructuredOutput；agent StructuredOutput 失敗 → 改無 schema 的 prose Agent 重跑。
- 主迴圈採納 BLOCKER／MAJOR（＋值得的 MINOR）→ 修 → 重親驗。

## 驗收紀律（集中驗收與人工測試）

- **per 工作項必附驗證**：`dist/` 內任何改動必跑 `./scripts/verify-package.ps1 -OutputDirectory artifacts`；文件／協定變更必做 grep 交叉引用核對（PLAYBOOK／DATA-SCHEMA／發行包 README／session-brief／DESIGN 全庫一致）；改變主持人行為的協定變更另登記 playground 實測項。
- **機械驗證通過≠驗收**：verify-package 綠、CI 綠只代表封裝與格式合法，不代表主持行為正確；協定行為驗證累積至 playground 實測清單，由使用者擇期批次回收。
- **AI 不自行宣稱驗收通過、不自行勾銷**：`PROJECT-PLAN.md` 勾選與 handoff「已完成」判定，以使用者驗收為準。

## Workflow script 撰寫坑

- template literal 內反引號會提早終止字串 → 改 `array.join('\n')`＋單引號；launch 前自掃反引號。
- 禁 TS 語法；meta 純字面（無變數／呼叫）；無 Date.now／Math.random／argless new Date。

## Lane 平行

只在無依賴的 milestone 間用。

## 本 repo 的 dev-rituals 設定

`.claude/dev-rituals.config.json` 為最小導入（handoffFile、memoryRoot），含本機絕對路徑故被 `.gitignore` 排除——換機器時依 dev-rituals schema 重建即可。plan 文件維持單一 `PROJECT-PLAN.md` 慣例，未導入 plansDir 多檔結構（2026-07-14 定案，日後可另行升級）。
