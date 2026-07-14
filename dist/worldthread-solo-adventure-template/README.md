# Worldthread／織世：單人 TRPG 範本

版本：`0.1.0`。這是一個可複製、解壓後即可交給具資料夾讀寫能力之 AI 服務使用的繁體中文單人 TRPG 範本；不綁定特定模型或平台。

## 三分鐘開始

1. 複製整個資料夾，勿直接在發行包中進行你的戰役。
2. 閱讀 `protocol/PLAYBOOK.md`，選擇 `game/templates/narrators/` 的一個說書人檔。
3. 將 `game/templates/starter-state/` 複製為 `game/state/`，再填寫主角與開場場景。也可直接使用本包的「霧渡口」範例。
4. 對 AI 說：「讀取 `protocol/PLAYBOOK.md`、`game/reference/`、`game/state/` 與說書人檔 `game/templates/narrators/balanced-weaver.md`；作為主持人為我開局。不要替我的主角做決定。」（說書人檔路徑換成你在第 2 步選的那一個。）
5. 以角色行動、對話或 OOC 指令遊玩。每回合依協定追加事件與更新狀態。

## 範例：霧渡口的失竊鐘聲

這是完全原創、低魔奇幻邊境謎案。可用既有角色 `game/reference/characters/lin-yao.md`，或依 PLAYBOOK 共同創角。起始場景與玩家可知內容位於 `game/reference/scenarios/fog-ferry-opening.md`；只有主持人可讀取 `game/private/director/`。

範例起手句：

> 我是林曜。我在霧渡口鐘塔下醒來，先檢查自己有沒有受傷，再問附近的人發生什麼事。

## 擲骰與公平性

為避免 AI 憑空生成偏頗的骰值，本包附 `tools/dice.mjs`（需 Node 18+）。主持協定要求 AI 需要隨機結果時呼叫此工具，並**逐字引用**其輸出的 JSON 行，不得自行編造或改寫。信任邊界請誠實理解：

- 骰值由你裝置上的密碼學級亂數產生，AI 無法影響。
- AI 代為執行時，你可以在對話介面的工具呼叫紀錄中核對原始輸出；逐字引用規則讓改寫立即可被發現。
- 你隨時有權自行擲骰（`node tools/dice.mjs 2d6+3`，或實體骰後回報公式與結果），AI 必須接受並如實記錄 `source`。
- 此機制針對的是 AI 編造骰點；它無法防止使用者自行修改結果。

## 資料分層與隱私

`game/reference/` 是通常不直接變更的來源素材；`game/state/` 是已確定、玩家可知的本局真相；`game/private/director/` 是不可向玩家揭露的祕密與前線；`game/rag/` 是可刪除重建的索引快取。不要把私有筆記、錄音、金鑰或真實戰役存檔發佈或提交。

語音只是輸入／輸出管道：STT 文字才是遊戲真相，原始音檔預設不保存。沒有檔案寫入能力的服務，請讓它輸出 `STATE-UPDATE` 區塊，再由你手動貼回。本範本不提供手機原生遊玩流程；若要在行動裝置上遊玩，請以遠端控制或類似方式，連回實際執行 AI 服務與檔案的環境。

## 內容與權利

範本與「霧渡口」範例採 MIT 授權。你加入的規則書、世界設定和玩家內容仍受其原始權利條件約束；只放入你有權使用的內容。要放入自己的規則書（含 PDF）或其他素材，請先讀 [ADDING-RULEBOOKS.md](ADDING-RULEBOOKS.md)：位置、Markdown 轉換建議、優先序宣告與權利注意事項都在裡面。詳見 `protocol/DATA-SCHEMA.md`、`protocol/RAG-PROTOCOL.md` 與 `protocol/VOICE-PROTOCOL.md`。
