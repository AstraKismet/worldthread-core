# AGENTS.md — Worldthread／織世 開發代理指南

本檔是所有 AI 開發代理（OpenAI Codex、Claude Code、其他工具）與人類協作者共用的專案入口。內容保持工具中立；工具專屬設定放各自的命名空間（例如 Claude Code 的 `.claude/`），不要寫進本檔。

## 專案是什麼

Worldthread（織世）是一個**平台中立的單人 TRPG 範本**：使用者解壓發行包、放入自己有權使用的素材，任何能讀寫資料夾的 AI 服務即可依檔案協定主持長期戰役。本儲存庫是**範本的開發來源**，不是遊戲執行現場——不要在 repo 裡實際開局遊玩或建立真實戰役狀態。

單一事實來源（修改前先讀，不要在本檔重複其內容）：

- `PROJECT-DESIGN.md` — 唯一完整設計規格（資料結構、協定、主持行為、驗收標準）。
- `PROJECT-PLAN.md` — 唯一建置計畫與風險登錄；勾選狀態經逐項驗證與 repo 現況一致，是可信的進度基準。
- `dist/worldthread-solo-adventure-template/README.md` — 發行包使用者入口（與根目錄開發者 README 用途不同）。
- `dist/worldthread-solo-adventure-template/protocol/` — 平台中立主持協定；發行後只有此目錄能改變主持人行為。

## 紅線（違反即錯，無例外）

1. **公開 repo 隱私紅線**：本 repository 公開。任何個人隱私或敏感資訊——電子郵件、本機絕對路徑（含使用者名稱）、API 金鑰、憑證、`.env`、真實戰役資料、私人筆記、音檔——一律不得寫入受版控的檔案。機器特定或個人設定放 `.gitignore` 排除的本機檔。
2. **dist-only 封裝**：`dist/worldthread-solo-adventure-template/` 是唯一可發行內容與唯一封裝來源。不得從 repo 根目錄打包；開發文件、CI 原始碼、Git 中繼資料不得混入發行包。
3. **公私分層**：`game/private/director/` 的祕密（前線、伏筆、導演決策）永不得洩漏到玩家可見的文件、範例或敘事中。發行包內的 private 素材僅限可公開發行的範例導演資料。
4. **平台中立**：協定與資料一律 UTF-8 的 Markdown／JSON 加相對路徑；不得綁定特定模型、雲端資料庫、嵌入服務或 RAG 實作。`game/rag/` 是可刪除重建的快取，不得成為唯一真相。
5. **原創／授權素材**：發行包只含原創或明確授權的素材；不得加入規則書摘錄等未授權內容。
6. **版本單一來源**：公開版本只在 `dist/worldthread-solo-adventure-template/template.json` 定義，採 SemVer；Git tag 固定為 `v<version>`；不得建立與 manifest 不一致的 tag，已發布的 tag 不得移動。

## 結構速覽

```text
.
├─ AGENTS.md / CLAUDE.md            # 代理入口（本檔／Claude 匯入層）
├─ PROJECT-DESIGN.md                # 設計規格
├─ PROJECT-PLAN.md                  # 建置計畫與風險登錄
├─ scripts/verify-package.ps1       # 封裝驗證腳本（PowerShell，已定案維持）
├─ .github/workflows/ci.yml         # PR 與 main push 時執行封裝驗證
└─ dist/worldthread-solo-adventure-template/   # 唯一可發行內容
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
- **語言**：專案文件與對使用者輸出一律繁體中文；程式碼註解不得混入其他專案語言。
- **交接**：跨 session 脈絡見本機交接檔 `WORLDTHREAD-HANDOFF.local.md`（`.gitignore` 排除）；接手時先讀它與 `PROJECT-PLAN.md`，完成階段工作後更新它。

## 本機、不追蹤的檔案（供理解，內容不進版控）

- `WORLDTHREAD-HANDOFF.local.md` — 跨 session 交接脈絡（agent 中立）。
- `GITHUB_REMOTE_SETUP.local.md` — GitHub 遠端、tag 與 Release 操作備忘。
- `.claude/dev-rituals.config.json` — Claude Code 個人方法論設定（含本機絕對路徑，依隱私紅線不追蹤）。
