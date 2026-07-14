# Worldthread／織世：單人 TRPG 範本

Worldthread（織世）是一個用來單人遊玩 TRPG 的配置範本。它讓具備資料夾讀寫能力的 AI 服務，以文字或語音轉寫主持長期戰役；使用者只需放入自己有權使用的規則、世界、角色與劇本素材，即可初始化並遊玩。

本儲存庫是**範本的開發來源**。給一般使用者解壓、開局時閱讀的文件位於發行包中：[`dist/worldthread-solo-adventure-template/README.md`](dist/worldthread-solo-adventure-template/README.md)。

## 如何取得與開始遊玩

範本內容全部是文字檔，**沒有安裝程式**；取得資料夾後即可使用。

### 方式一：下載發行版（建議）

1. 到本儲存庫的 [Releases 頁面](https://github.com/Isida-kserpg/worldthread-solo-adventure-template/releases)，下載最新版的 `worldthread-solo-adventure-template-vX.Y.Z.zip`（以及同名 `.sha256` 檔）。
2. （建議）驗證下載完整性，比對輸出與 `.sha256` 檔內容：

   ```powershell
   # Windows PowerShell
   Get-FileHash .\worldthread-solo-adventure-template-vX.Y.Z.zip -Algorithm SHA256
   ```

   ```sh
   # macOS / Linux
   shasum -a 256 -c worldthread-solo-adventure-template-vX.Y.Z.zip.sha256
   ```

3. 解壓縮到你想放戰役的位置，會得到一個 `worldthread-solo-adventure-template/` 資料夾。
4. 閱讀資料夾內的 `README.md`，照「三分鐘開始」開局。

### 方式二：從原始碼取得

1. 點 GitHub 頁面右上的 **Code ▾ → Download ZIP**，或 `git clone` 本儲存庫。
2. 把 [`dist/worldthread-solo-adventure-template/`](dist/worldthread-solo-adventure-template/) 整個資料夾**複製到儲存庫外**你想放戰役的位置——不要直接在儲存庫裡開戰役，真實戰役狀態不屬於這裡。
3. 之後與方式一相同：讀複製出來的 `README.md`，照「三分鐘開始」開局。

### 需求

- 一個能讀取、搜尋並寫入資料夾的 AI 服務（不限定廠牌；無寫檔能力的純聊天服務也可用降級模式遊玩，見發行包 README）。
- （可選）Node.js 18 以上**或** Python 3.8 以上：發行包附的擲骰工具（`tools/dice.mjs`／`tools/dice.py`，輸出契約相同）擇一環境即可；都沒有也能玩，改用實體骰或協定內的最終降級。

### 下一步

- 想放入自己的規則書（含 PDF）？先讀發行包內的 [`ADDING-RULEBOOKS.md`](dist/worldthread-solo-adventure-template/ADDING-RULEBOOKS.md)。
- 想跑含謎底的冒險模組又不想劇透自己？同一份文件的「盲拆流程」就是為此設計的。

## 設計目標

- 平台中立：不綁定 Codex、特定模型、雲端資料庫或 RAG 服務。
- 檔案優先：以 UTF-8 Markdown、JSON 與相對路徑保存資料；索引可刪除重建，不能是唯一真相。
- 公私分層：玩家可知狀態與主持人私有導演資料明確隔離。
- 主動而公平的主持：前線、倒數鐘、鉤子與節奏會推動世界，但不替玩家決定主角行動。
- 隱私與可攜：語音只作傳輸層；沒有寫檔能力的服務能輸出結構化狀態更新，供使用者手動貼回。

完整設計依據請見 [PROJECT-DESIGN.md](PROJECT-DESIGN.md)，建置進度與風險請見 [PROJECT-PLAN.md](PROJECT-PLAN.md)。

## 目前狀態

目前版本為 `0.2.0`，發行內容：

- 可攜主持手冊、資料 schema、RAG 與語音協定；規則書使用指南與盲拆流程。
- 三種預設說書人：溫和引路人、均衡織局者、風暴守望者。
- 完全原創的低魔奇幻邊境謎案範例：「霧渡口的失竊鐘聲」。
- 既有角色、共同創角流程、可複製初始狀態、無法寫檔時的降級格式，與可審計擲骰工具（Node 與 Python 雙實作，同種子輸出逐位元一致，由契約測試夾具鎖定）。

CI（封裝驗證與擲骰工具契約測試）在 Pull Request 與推送 `main` 時自動執行；發行由 `v*` tag 觸發（重驗證 → ZIP＋SHA-256 → GitHub Release）。`main` 分支保護尚未啟用。

## 儲存庫結構

```text
.
├─ dist/worldthread-solo-adventure-template/  # 唯一可發行內容
│  ├─ README.md                               # 玩家／使用者入口
│  ├─ ADDING-RULEBOOKS.md                     # 放入自有規則書的指南
│  ├─ LICENSE                                 # MIT 授權
│  ├─ template.json                           # 唯一公開版本來源
│  ├─ protocol/                               # 平台中立的主持與資料協定
│  ├─ tools/                                  # 玩家工具（擲骰、規則書轉檔提示詞）
│  ├─ game/reference/                         # 原始規則、世界與範例素材
│  ├─ game/private/director/                  # 僅主持人可讀的祕密與前線
│  ├─ game/templates/                         # 可複製的狀態與說書人設定
│  └─ examples/                               # 範例回合
├─ scripts/verify-package.ps1                 # 封裝驗證腳本（CI 同款）
├─ .github/workflows/                         # CI 與 tag 發行流程
├─ AGENTS.md / CLAUDE.md                      # 開發代理入口
├─ PROJECT-DESIGN.md                          # 設計規格
├─ PROJECT-PLAN.md                            # 建置計畫與風險登錄
└─ .gitignore                                 # 私有戰役資料與機密排除規則
```

發行包不應包含真實戰役的 `game/state/`、RAG 快取、音檔、`.env`、憑證或 Git 中繼資料。範例與範本所需的 `game/private/director/` 可以隨包提供，但其中只能有可公開發行的導演素材，不能混入玩家的私有筆記。範例的初始狀態應保存在 `game/templates/starter-state/`，由使用者複製後開始自己的戰役。

## 本機檢查

改動 `dist/` 內任何內容後，執行與 CI 相同的完整封裝驗證：

```powershell
./scripts/verify-package.ps1 -OutputDirectory artifacts
```

提交前也應確認發行目錄只含可公開分發的內容：

```powershell
git status --short
Get-ChildItem -Recurse dist/worldthread-solo-adventure-template
```

## 開發與發行原則

`dist/worldthread-solo-adventure-template/` 是唯一封裝來源；不要從儲存庫根目錄建立玩家 ZIP。公開版本只在該資料夾的 `template.json` 中定義，並採 SemVer（首版為 `0.1.0`）；Git tag 固定為 `v<版本號>`，推送 tag 即觸發發行流程。

專案採 GitHub Flow：改動使用短生命週期分支與 Pull Request，`main` 永遠保持可發行。開發代理的共同規範見 [AGENTS.md](AGENTS.md)。

## 授權與內容

發行包與其原創範例採 [MIT License](dist/worldthread-solo-adventure-template/LICENSE)。使用者自行加入的規則書、設定、網頁摘錄與戰役資料，仍由其原始授權或權利條件約束；請只加入有權使用與分享的內容。
