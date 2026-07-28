# Claude Code 專屬：Workflow 編排與 subagent 分發規範

> **本檔為本 repo 的上位規範。** 全域 `~/.claude/CLAUDE.md`〈Delegating work to sub-agents〉自述為「給沒有自有慣例的專案用的 fallback、下方壓縮重述不是第二真相來源」，故**兩者相見時一律以本檔為準**（2026-07-28 使用者定案）。**全域檔是個人的、只在以 Claude Code 開發時適用，且不入任何 repo——他人 fork 看不到它是設計如此**（對方有自己的開發方式）；入庫的 `AGENTS.md` 與本檔則是**給他人參考、由對方依自身環境調整**的版本。由此推論：**本檔不得把規則外包給全域**——凡本檔刪去的機制條文，在入庫內容裡即無權威落點。因此**本檔維持自足**；全域只作對照參考，不構成刪除本檔內容的理由。
>
> 本檔僅供 Claude Code 使用（其他代理請忽略）。使用者 2026-07-14 定案、2026-07-18 擴充定案（架構設計、對抗審查格式、驗收紀律）、2026-07-20 擴充定案（降級產出 registry）、**2026-07-26 修訂定案（fable 使用範圍收斂至資安領域、架構設計改 opus）**、**2026-07-28 定案（位階＝本檔上位／全域為 fallback；階梯標題改為「通用三級＋fable 領域專用」；明文終局性判準；對抗審查列為常設授權；補共享接縫清單的權威落點指標）**；另一專案的具體示例已改寫為本專案原生條文。

## Model 分發階梯（通用三級 haiku＜sonnet＜opus；fable 為資安領域專用、不在通用階梯內）

> 全域有一份同旨的壓縮重述，但**本表為本專案的權威版本**：它另載全域沒有的**定案沿革**、**升 opus 的例外**與 **session 型態**對應。兩者相左時以本表為準。

主迴圈＝session model，常態為 **opus**。**fable 不是「比 opus 更高一階」，而是資安領域專用**（見下表該列），其餘工作一律不派 fable——2026-07-26 使用者定案，理由＝Opus 5 能力提升後，架構設計等原本上派 fable 的工作以 opus 執行即足。fable 仍要視為不一定能使用。

| 工作類型 | 派發方式 | 說明 |
| --- | --- | --- |
| 純檔案定位／檢索（找 X 在哪、列 caller、grep pattern） | `agentType:'Explore', model:'haiku'` | haiku 只在純 retrieval 安全 |
| 設計／架構調查（dev-research-advisor：seam 測繪＋Options＋cons-mitigation） | `model:'sonnet'` 預設 | 產出餵 ceremony、由主迴圈再合成。**終局性判準（2026-07-28 定案）**：產出**必經主迴圈再合成**＝草稿→`sonnet`；產出**直接送 ceremony／決策看板**、主迴圈不再重推＝**終局選項集→`opus`**，且最終 cons-mitigation 一律主迴圈親做、不下放。**「再合成」的界線**＝主迴圈另跑一輪推導／篩選／補漏並自負最終內容；**只轉貼或潤稿不算**，該產出即屬終局選項集。**除本判準外**另有二種可升 opus 的情形：①把 seam 正確 map 出來本身即難點 ②錯誤事實主迴圈難察覺且代價高（原例外③「無主迴圈再合成的終局性」已被本判準吸收，不另列）。**調查／檢索天花板＝opus**（opus 用於 retrieval 已屬過剩）；非資安主題不派 fable |
| 架構「設計」 | **一律 opus**：主迴圈（Opus session）親做、或 workflow `agent()` 顯式 `model:'opus'` | 2026-07-14 使用者定案「架構設計上派最高階」、2026-07-18 收錄本檔、**2026-07-26 定案改為 opus**（Opus 5 能力提升，不再上派 fable）。判準不變＝輸出是否為**將凍結的架構決策／契約**——schema 形狀、公開 API、跨模組契約、為 ceremony 產 Options＋cons-mitigation 的設計 lane 皆屬之。與「調查／檢索天花板＝opus」不衝突：天花板條款設的是檢索／事實調查的**上限**，本列設的是設計工作的**下限**；sonnet 僅適用「事實測繪／現況盤點」類調查 |
| **資安研究／資安相關設計**（威脅模型、攻擊面與信任邊界分析、密碼學／認證授權設計、漏洞與利用分析、資安審查） | **一律 fable**：主迴圈（Fable session）親做、或 `agent()` 顯式 `model:'fable'` | 2026-07-26 使用者定案：**fable 的唯一適用領域**。fable 不可用時＝以 opus 親做、產出標註降級並登記進 registry（見〈降級產出 registry〉） |
| 程式碼實作 | `model:'sonnet'` lane 或主迴圈（session model）直接做 | |
| 主迴圈合成／ceremony／cons-mitigation／AskUserQuestion／對抗審查驗證誠實（test-honesty）lens | **不下放**：agent() 不帶 model | 繼承 session model、自動對齊主迴圈（常態 Opus session→opus；資安主題的 Fable session→fable） |

理由：調查產出被主迴圈再合成、事實準確度才是紅線；dev-research-advisor 的判斷／cons-mitigation 用 sonnet 才不逼主迴圈重做——**此理由只涵蓋「草稿型」調查**；產出即終局選項集者依上表〈終局性判準〉走 opus。

## 降級產出 registry（2026-07-20 使用者定案；2026-07-26 隨 fable 收斂修訂）

未以該工作類型應有階級產出的成果，除了在產出處標註降級之外，**必須登記進 registry**：`DEGRADED-DESIGN-REGISTRY.local.md`（repo 根、`.gitignore` 排除；本條慣例入版控、registry 本體屬工作狀態不入版控）。不登記＝日後無從得知哪些設計該回頭覆核。**兩種登記情形**：

- **架構設計未達 opus**：應由 opus 產出的架構設計改由更低階模型（sonnet／haiku）產出。
- **資安設計未達 fable**：應由 fable 產出的資安研究／資安相關設計因 fable 不可用而以 opus 代做。

🔴 **過渡條文（2026-07-26 使用者定案）**：registry 中既有登記為「**待 fable 覆核**」的架構設計條目，**一律改排以當前版本 opus 重作／覆核**——不再等待 fable。逐筆把「覆核者」改記為 opus 後照〈覆核作業〉辦理；此變更本身不改變各條目的覆核 gate 與風險等級。

**登記欄位**：id（永不重用）／日期／產出物（檔案＋節次）／設計內容一句話／實際使用模型／降級原因／風險等級（是否將凍結成契約、有無下游消費者）／**覆核 gate**／狀態／覆核紀錄。

**覆核 gate 是關鍵欄位——覆核要發生在決策之前，不是之後。** 降級產出分兩類，風險不同：

- **已凍結進協定的設計**：錯了要改版、有下游成本，但至少經過驗證與對抗審查。
- **尚未定案、要送進 ceremony 的 Options＋cons-mitigation**：**使用者是從這些選項裡挑的**——選項集若因降級而漏了方案或誤判 cons，定案就建立在殘缺基礎上，且事後看不出來。**此類 gate 一律為「開板前」。**

**狀態值**：`待覆核`／`已覆核-無需修改`／`已覆核-已修改`／`已失效`。**「已失效」不可省**——設計被後續變更取代時即標記，否則 registry 只增不減、無法收斂，也會浪費覆核成本在死條目上。

**不算降級產出、不必登記**：使用者親自定案的決策（那是人的決定，不是模型產出）；事實測繪／現況盤點類調查（依天花板條款本就 sonnet 即可）；程式碼實作。

**覆核作業（「升級回去」）**：**由當前版本的 opus session 執行**（架構設計條目）或 fable session 執行（資安條目）——讀 registry → 依 gate 與風險排序 → 逐筆重新推導該設計 → 標記狀態並寫覆核紀錄；判定需修改者，修正一律走正常變更流程（分支＋PR），不在覆核當下逕改。**覆核＝重新推導，不是重讀後點頭**：條目若原本就由當時的 opus 產出，仍須以現行 opus 重作一次推導才可標記已覆核。

## Fork 與 model 覆寫

- ⚠ model 覆寫對 fork **無效**（fork 恆繼承父＝主迴圈 model、成本同級）→ 可下放的 fan-out 一律顯式 `agentType`＋`model`，勿用 fork 做檢索／機械工作。
- workflow `agent()` 覆寫須顯式帶 `model` 才生效（省略即靜默繼承 session model；enum 含 `'fable'`，但依〈Model 分發階梯〉**只有資安領域才派 fable**）。
- `agent()` 必須顯式 `agentType`（ultracode／workflow 不會自動挑自建 agent；先對照 dev-rituals 索引挑對的 specialist）。

## Task brief 撰寫（零設計研究雙刃）

sonnet agent 不自行調查 → 凡未 distill 進 brief 的決策／約束、agent 一律不會知道（→ 靜默簡化、契約鍵名斷裂、覆寫共享接縫的根因）。

task brief 固定格式，必須 distill：

1. milestone 條目；
2. 規格節號（引用 `PROJECT-DESIGN.md`／`protocol/` 節次）；
3. reusable 表（可重用的既有檔案／函式／協定）；
4. distilled 決策／約束：ceremony 定案、研究結論、`AGENTS.md` 紅線、既有架構契約、命名慣例（本專案例：dist-only 封裝、公私分層 `private/director/` 不外洩、平台中立、公開 repo 隱私紅線、visibility 三值 enum 不擴充）、精確契約／鍵名／DTO 形狀。

**發 agent 前主迴圈必須核對「研究結論／設計決策／約束條件是否已 distill 進 task prompt」，缺則補齊再發。**

🔴 **brief 內引用的外部檔案須附當下實讀內容或時間戳**：貼進 brief 的是 session 起始的快照，該檔可能已在本輪被改。凡以「某檔已載明 X」為由做刪除或收斂的判斷，**動手前必須重讀該檔磁碟本體**（2026-07-28 對抗審查實例：全域 `~/.claude/CLAUDE.md` 在本輪被改動，主迴圈拿過期副本推導出相反的位階結論）。

## 平行 sonnet 實作六坑

①測試遷就假綠 ②契約鍵名斷裂 ③衍生／複製檔未同步 ④註解混入非專案語言（本專案語言為繁體中文）⑤共享接縫被平行 agent 重實作覆寫 ⑥agent 任務漂移漏交付

對策：**對抗審查必開**（格式見〈對抗審查格式〉）＋主迴圈核對交付物清單＋重跑；平行 lane 須 disjoint 檔＋brief 明文「不碰對方檔／bundle」；**共享接縫單檔改一律主迴圈 surgical 手做、不發平行 agent**。**共享接縫檔清單的權威定義處＝ `AGENTS.md`〈Handoff 工作包〉末條**；`docs/handoff-system.md` §10 存有一份逐字鏡像複本，兩者相左時以 `AGENTS.md` 為準——**改清單須同步兩處**（此即上列第③坑本身）。

## 對抗審查格式

> 本節之 3-reviewer fan-out 屬 2026-07-18 使用者**常設定案**：每輪逕行開啟、不需另問（2026-07-28 明文化）。全域「多代理只在使用者要求時才跑」的預設對本專案不適用——本檔為上位，且此常設定案即該條所稱之「已要求」。

- 每輪實作後 fan-out **3 獨立 reviewer**，lens：①**驗證誠實（test-honesty）**〔最關鍵：假綠、恆真斷言、守衛短路跳過斷言、數值逐項核算、確定性；不得把未跑過的驗證宣稱為綠〕②**correctness 或 docs-accuracy**〔依變更性質二擇一：協定／文件變更→docs-accuracy、腳本／CI 變更→correctness〕③**contract-integration**〔契約完整性：DATA-SCHEMA 鍵名、`template.json` 版本單一來源、visibility 三值 enum 不擴充、衍生專案 checksum 契約、PLAYBOOK／DATA-SCHEMA／發行包 README／session-brief／DESIGN 交叉引用一致〕。
- **model**：①驗證誠實＝主迴圈同級（`agent()` 不帶 `model` 繼承 session model；假綠守門、不下放）；②③預設 `sonnet`，高風險工作項（schema 契約、公私分層、revision 衝突／擲骰確定性）可升 `opus`；審查標的屬資安研究／資安設計時，該 lens 可升 `fable`。
- reviewer **唯讀主樹、不可 `isolation:'worktree'`**（worktree 看不到未 commit 改動）；**reviewer 不得 Edit／不得動檔**（mutation 親證與所有修正一律主迴圈做）。
- 每 finding 標 **BLOCKER／MAJOR／MINOR／NIT**＋file:line＋具體修法；末給明確 **verdict（SAFE／NOT SAFE）**＋單一最重要 finding。schema 強制 StructuredOutput；agent StructuredOutput 失敗 → 改無 schema 的 prose Agent 重跑。
- 主迴圈採納 BLOCKER／MAJOR（＋值得的 MINOR）→ 修 → 重親驗。
- **reviewer 指控主迴圈的驗證不實時，主迴圈必須自己重跑該驗證**，不得以「已核對過」帶過（2026-07-28 實例：BLOCKER 成立）。
- 涉 handoff 工作包者：三份 verdict＋單一最重要 finding **另須寫入該輪實作 commit 的 message body**（包完成即刪、留痕不落刪檔包）——見 `AGENTS.md`〈Handoff 工作包〉。**非 handoff 場合**（如本輪這類插入工作）此義務不自動成立，但 verdict 仍應寫入該輪 commit body，否則審查結論只存在於對話輪次、事後無從稽核。

## 驗收紀律（集中驗收與人工測試）

- **per 工作項必附驗證**：`dist/` 內任何改動必跑 `./scripts/verify-package.ps1 -OutputDirectory artifacts`；文件／協定變更必做 grep 交叉引用核對（PLAYBOOK／DATA-SCHEMA／發行包 README／session-brief／DESIGN 全庫一致）；改變主持人行為的協定變更另登記 playground 實測項。
- **宣稱跑過的驗證須列出實際 pattern／指令**：只說「已 grep 核對」不算數，措辭不得高於實際覆蓋率。
- **機械驗證通過≠驗收**：verify-package 綠、CI 綠只代表封裝與格式合法，不代表主持行為正確；協定行為驗證累積至 playground 實測清單，由使用者擇期批次回收。
- **AI 不自行宣稱驗收通過、不自行勾銷**：`PROJECT-PLAN.md` 勾選與 handoff「已完成」判定，以使用者驗收為準。

## Workflow script 撰寫坑

- template literal 內反引號會提早終止字串 → 改 `array.join('\n')`＋單引號；launch 前自掃反引號。
- 禁 TS 語法；meta 純字面（無變數／呼叫）；無 Date.now／Math.random／argless new Date。

## Lane 平行

只在無依賴的 milestone 間用；平行 lane 須 disjoint 檔。

## 本 repo 的 dev-rituals 設定

`.claude/dev-rituals.config.json` 為最小導入（handoffFile、memoryRoot），含本機絕對路徑故被 `.gitignore` 排除——換機器時依 dev-rituals schema 重建即可。plan 文件維持單一 `PROJECT-PLAN.md` 慣例，未導入 plansDir 多檔結構（2026-07-14 定案，日後可另行升級）。
