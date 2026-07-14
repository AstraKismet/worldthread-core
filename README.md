# Worldthread／織世：單人 TRPG 範本

Worldthread（織世）是一個平台中立的單人 TRPG 範本專案。它讓具備資料夾讀寫能力的 AI 服務，以文字或語音轉寫主持長期戰役；使用者只需放入自己有權使用的規則、世界、角色與劇本素材，即可初始化並遊玩。

本儲存庫是**範本的開發來源**。給一般使用者解壓、開局時閱讀的文件位於發行包中：[`dist/worldthread-solo-adventure-template/README.md`](dist/worldthread-solo-adventure-template/README.md)。

## 設計目標

- 平台中立：不綁定 Codex、特定模型、雲端資料庫或 RAG 服務。
- 檔案優先：以 UTF-8 Markdown、JSON 與相對路徑保存資料；索引可刪除重建，不能是唯一真相。
- 公私分層：玩家可知狀態與主持人私有導演資料明確隔離。
- 主動而公平的主持：前線、倒數鐘、鉤子與節奏會推動世界，但不替玩家決定主角行動。
- 隱私與可攜：語音只作傳輸層；沒有寫檔能力的服務能輸出結構化狀態更新，供使用者手動貼回。

完整設計依據請見 [PROJECT-DESIGN.md](PROJECT-DESIGN.md)，建置進度與風險請見 [PROJECT-PLAN.md](PROJECT-PLAN.md)。

## 目前狀態

首個目標版本為 `0.1.0`，目前已具備可試玩的初版發行內容：

- 可攜主持手冊、資料 schema、RAG 與語音協定。
- 三種預設說書人：溫和引路人、均衡織局者、風暴守望者。
- 完全原創的低魔奇幻邊境謎案範例：「霧渡口的失竊鐘聲」。
- 既有角色、共同創角流程、可複製初始狀態與無法寫檔時的降級格式。

尚未完成自動化 CI/CD、正式封裝與 GitHub Release；詳情見建置計畫的階段 3–4。

## 儲存庫結構

```text
.
├─ dist/worldthread-solo-adventure-template/  # 唯一可發行內容
│  ├─ README.md                               # 玩家／使用者入口
│  ├─ template.json                           # 唯一公開版本來源
│  ├─ protocol/                               # 平台中立的主持與資料協定
│  ├─ game/reference/                         # 原始規則、世界與範例素材
│  ├─ game/private/director/                  # 僅主持人可讀的祕密與前線
│  ├─ game/templates/                         # 可複製的狀態與說書人設定
│  └─ examples/                               # 範例回合
├─ PROJECT-DESIGN.md                          # 設計規格
├─ PROJECT-PLAN.md                            # 建置計畫與風險登錄
└─ .gitignore                                 # 私有戰役資料與機密排除規則
```

發行包不應包含真實的 `game/state/`、`game/private/`、`game/rag/`、音檔、`.env`、憑證或 Git 中繼資料。範例的初始狀態應保存在 `game/templates/starter-state/`，由使用者複製後開始自己的戰役。

## 本機檢查

PowerShell 下可先做基本結構與 JSON 驗證：

```powershell
$package = 'dist/worldthread-solo-adventure-template'
Get-ChildItem $package -Recurse -Filter *.json |
  ForEach-Object { Get-Content -Raw -Encoding utf8 $_ | ConvertFrom-Json | Out-Null }
```

在加入 CI 前，提交前也應確認發行目錄只含可公開分發的內容：

```powershell
git status --short
Get-ChildItem -Recurse dist/worldthread-solo-adventure-template
```

## 開發與發行原則

`dist/worldthread-solo-adventure-template/` 是唯一封裝來源；不要從儲存庫根目錄建立玩家 ZIP。公開版本只在該資料夾的 `template.json` 中定義，並採 SemVer（首版為 `0.1.0`）。

專案採 GitHub Flow：首次建立可直接提交至 `main`；後續改動使用短生命週期分支與 Pull Request。遠端接入、分支保護、Actions、tag 與 Release 的本機操作備忘不納入版控，見 `GITHUB_REMOTE_SETUP.local.md`。

## 授權與內容

發行包與其原創範例採 [MIT License](dist/worldthread-solo-adventure-template/LICENSE)。使用者自行加入的規則書、設定、網頁摘錄與戰役資料，仍由其原始授權或權利條件約束；請只加入有權使用與分享的內容。
