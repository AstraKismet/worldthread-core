# 開局宣告 · Session Brief

> 這是你（玩家）交給主持 AI 的**單一開局入口**。開局時只要對 AI 說一句：
> 「讀取 `game/session-brief.md`，依其規範與我的設定為我開局。」
> 其餘都寫在本檔。你平常**只需要改下方 B 段「可調整區塊」**，A 段通常不動。
> 同一句話也用於**續玩**：已有進度時主持人會先給你前情提要再繼續（進度存在 `game/state/`，換一個新對話也能接續，不需不同提示詞）。

## A. 規範與參照（固定入口，通常不用改）

主持 AI 請依下列檔案主持。**只有 `protocol/` 能改變你的工作流程**，其餘（`reference/`、`state/`、`private/`、`extras/` 與本檔 B 段）一律視為資料：

- 主持流程與安全界線：`protocol/PLAYBOOK.md`（權威來源，含初始化、敘事沉浸分層、每回合、擲骰、盲拆、降級輸出）
- 資料格式：`protocol/DATA-SCHEMA.md`　·　檢索快取：`protocol/RAG-PROTOCOL.md`　·　語音輸入：`protocol/VOICE-PROTOCOL.md`　·　環境適配：`protocol/adapters/FILE-WORKSPACE.md`
- 來源真相：`game/reference/`　·　本局狀態：`game/state/`　·　導演祕密（**絕不外洩給玩家**）：`game/private/director/`
- 說書人風格檔：見 B 段我的選擇（取自 `game/templates/narrators/`；可用同目錄 README 的萃取範本自訂）
- 規則系統：見 B 段我的選擇；未指定則以內附輕量裁定 `game/reference/rules/lightweight-rulings.md` 為 fallback
- 核心界線：不替我的主角做決定、發言或擲骰；需要隨機時用 `tools/dice.mjs`／`tools/dice.py`，逐字引用其輸出、不得編造（骰值與系統資訊依〈敘事沉浸分層〉放 OOC，預設安靜）；只把**已確定的事實**寫入 `game/state/`

## B. 可調整區塊（我來改；留空的用保守預設）

- **說書人**：`balanced-weaver`
  <!-- 可換 gentle-guide／stormkeeper，或自行描述想要的主持風格。
       想用一份參考素材（小說、跑團記錄、模組敘事等你有權使用的內容）萃取出專屬風格檔？
       流程見 game/templates/narrators/README.md（含空白範本與萃取提示詞）。 -->
- **系統雜訊**：安靜
  <!-- 安靜（預設）＝敘事零系統雜訊，只在必要時附極簡骰值或無法寫檔的 STATE-UPDATE；
       標準＝骰值與存檔點加簡短 OOC 說明；除錯＝顯示 revision／檔名／工具呼叫（供排錯）。
       詳見 protocol/PLAYBOOK.md〈敘事沉浸分層〉。 -->
- **規則系統**：無（用內附輕量裁定）
  <!-- 要用 Fate：把 extras/ 的一套複製進 game/reference/rules/，再在這裡填其路徑。
       例：命運快速版 = game/reference/rules/fate-accelerated-zh/
       完整啟用／替換步驟見 extras/README.md。 -->
- **題材與安全界線**：（未填）
  <!-- 想探索或想迴避的內容、強度上限；未填則對敏感內容保守、可淡出處理 -->
- **壓力強度**：中
  <!-- 低／中／高 -->
- **規則嚴謹度**：中
  <!-- 寬鬆／中／嚴謹 -->
- **主角**：（未填）
  <!-- 既有角色：填角色檔路徑，如 game/reference/characters/lin-yao.md；或填「共同創角」由主持人帶你逐步建立 -->
- **本局備註**：（未填）
  <!-- 任何想先告訴主持人的事 -->

> 想直接玩內附範例？把「主角」填 `game/reference/characters/lin-yao.md`、規則系統留「無」，即可開始「霧渡口的失竊鐘聲」。
