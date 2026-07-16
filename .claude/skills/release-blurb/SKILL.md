---
name: release-blurb
description: 於新版本 tag 完成（Release 發佈）後，依「本版與前一版本的差異」產出一份可貼在社群通訊軟體（Discord／Telegram／LINE）的繁體中文版本介紹，聚焦玩家實際好處而非開發內部細節。觸發詞：release-blurb／社群介紹／版本介紹／分享文。僅產出介紹文字，不建立版本標籤、不發 Release、不動 git。
---

# /release-blurb

把「本專案某個版本相對前一版的差異」整理成一段**社群分享用的版本介紹**。專為 Worldthread／織世 客製：繁體中文、通訊軟體友善、以玩家能感受到的好處為主軸，把 commit 與程式差異翻譯成「這對你玩起來有什麼不同」。

## 何時觸發（前置條件，硬性）

**在新版本 `v<version>` tag 完成、Release 已發佈之後才執行本 skill。** 介紹文結尾的下載連結指向該版 Release，tag／Release 尚未存在時連結會失效（404）。因此開始合成前**必先驗證**：

- 確認 tag 存在：`git tag -l v<version>`（version 取自 `dist/worldthread-solo-adventure-template/template.json`）。
- 確認 Release 已發佈：`gh release view v<version>`（或對應的 GitHub CLI 路徑）成功回傳。
- 若 tag／Release 尚未完成：**停下並告知使用者「請先完成版本標註與發行，再產出社群介紹」**，不要輸出帶失效連結的介紹，也不要代為建立 tag／Release（那不在本 skill 範圍）。

## 邊界（硬性）

- **只產出介紹文字**。**不**建立 tag、**不**發 Release、**不**做任何 git 寫入或推送——版本標籤與發行由既有發行流程（`release.yml` 於 `v*` tag 觸發）負責，不在本 skill 範圍。
- 遵守專案紅線：繁體中文輸出；不外洩任何隱私／本機路徑／金鑰；平台中立（不吹捧特定模型或雲端）；不洩漏 `game/private/director/` 的祕密性內容。
- 只講「**已在此版落地**」的變更；未定案或 backlog 項目不寫進對外介紹。

## 流程

1. **定版本**：目前版本以單一來源 `dist/worldthread-solo-adventure-template/template.json` 的 `version` 為準。前一版本取前一個 release tag：
   - `git tag --sort=-v:refname | head -n 5` 查最近的 tag；本版對應 `v<version>`，前一版取其下一個。
   - 若使用者在觸發時指定了版本區間（例如 `/release-blurb v0.3.0..v0.4.0`），以其為準。
2. **撈差異**（只讀，不寫）：
   - `git log <prev>..HEAD --oneline` 看提交主題。
   - `git diff --stat <prev> HEAD -- dist/` 聚焦發行內容的實際改動（忽略純開發文件如 `PROJECT-*.md`、CI）。
   - 對**玩家可感知**的改動，實際讀改動檔理解其意義：優先 `dist/.../README.md`、`protocol/PLAYBOOK.md`、`game/session-brief.md`、新增的 `game/templates/`、`tools/`、`examples/`。開發內部檔（schema 細節、verify 腳本、計畫）不入對外介紹。
3. **翻譯成玩家語言**：每個重點回答「玩家玩起來有什麼不同」，不用內部術語（revision、schema、OOC 等）當賣點；必要時把術語轉成生活化說法（例：把「系統雜訊三級」講成「主持人幕後碎念可以一鍵關掉／打開」）。
4. **合成介紹**，結構建議：
   - 一句**鉤子**（產品是什麼＋這版的一句話亮點）。
   - **2–4 個重點**，每點一個 emoji 標題＋2–3 句白話說明好處；亮點多時取最有感的前幾個。
   - 結尾一行**下載／Release 連結**：`https://github.com/AstraKismet/worldthread-solo-adventure-template/releases/tag/v<version>`。
   - 長度控制在通訊軟體一則可讀完（約 120–200 字為主）；語氣親切、可用 emoji，但不浮誇。
5. **交付**：以可直接複製的 code block 呈現在對話中。可另提供一個**精簡版**（1–2 句＋連結）供限字數平台使用。若使用者指定平台（Discord／Telegram／LINE／Threads 等），依其排版習慣微調。

## 品質自查

- [ ] 每個重點都是玩家視角的好處，不是開發內部細節？
- [ ] 沒有洩漏隱私／本機路徑／director 祕密？全繁體中文？
- [ ] 只寫已落地的變更，連結指向正確的 `v<version>` Release？
- [ ] 已先驗證 `v<version>` tag 與 Release 存在，才產出含連結的介紹？
- [ ] 沒有做任何 git 寫入、建 tag 或發 Release？
