---
name: git-flow-branch-advisor
description: 依照本專案 main→feature→release→(sit/uat/prod) 的分支流程分析 repo 分支現況，並詢問開發者目前要做什麼（新功能/修 bug/hotfix/release/部署/PR 審核），再根據 分支策略說明手冊.md 推薦正確分支、PR 目的地與安全的 git 指令。
metadata:
  short-description: Git flow 分支策略顧問
---

# Git Flow 分支顧問（Branch Advisor）

目標：協助新人工程師快速選對分支/PR 目的地，並給出符合本專案分支策略的下一步行動。

依據來源（Source of Truth）：當前 repo 的 `分支策略說明手冊.md`。只讀取你需要的段落，不要整份貼出手冊全文。

## 操作原則

- 預設只做「**建議**」（指令 + PR 目的地 + 風險），除非使用者明確要求，否則不要代替使用者 push/merge/改寫歷史。
- 如果 repo 狀態與手冊假設不一致（例如沒有 remote、分支不齊），要先說清楚，再用最少的問題補齊資訊。

## 工作流程（照順序做）

### 1) 找到手冊

1. 若 repo root 有 `分支策略說明手冊.md`，以它為準。
2. 否則用：`rg -n \"分支策略說明手冊\" -S .` 搜尋並打開最接近的文件。

常用搜尋 pattern（只挑需要的）：
- `rg -n \"核心原則|禁止事項\" 分支策略說明手冊.md`
- `rg -n \"開始新功能開發|PR 目的地規則\" 分支策略說明手冊.md`
- `rg -n \"Hotfix\" 分支策略說明手冊.md`
- `rg -n \"SIT/UAT\" 分支策略說明手冊.md`
- `rg -n \"Release 管理流程|Release Freeze\" 分支策略說明手冊.md`
- `rg -n \"分支保護規則\" 分支策略說明手冊.md`

### 2) 取得 repo 分支快照（只讀）

執行：

`bash ~/.codex/skills/git-flow-branch-advisor/scripts/branch_snapshot.sh`

如果失敗，改用以下指令（只讀）：
- `git status -sb`
- `git branch -a`
- `git remote -v`
- `git log --oneline --decorate -n 20`

### 3) 向開發者問最少但關鍵的問題

依序詢問（若上下文已回答就不要重問）：

1. **你現在要做哪一種事情？**
   - A) 新功能 `feature/*`
   - B) 一般修 bug（尚未進 SIT/UAT）`bugfix/*`
   - C) SIT/UAT 測試發現 bug（修正要跟著 release 走）
   - D) 緊急線上 hotfix `hotfix/*`
   - E) 推進版本到 `sit/uat/prod`
   - F) release 管理（建立/整合/freeze/上線/回 main）
   - G) PR 審核（檢查分支來源/目的地/門檻）
2. **目標環境/目標版本是？**（`sit` / `uat` / `prod` / 或僅合併到 `release/*`）
3. **目前 active 的 release 分支是哪一條？**（如果 snapshot 已能推斷就提出你的推斷並請確認）
4. **你目前所在分支與是否已有 PR？**（分支名、PR 來源/目的地）

需要升級請求/找人確認的提示（資訊不足或不清楚時使用）：
- 「請問誰是這次 release owner？目前 release 是否已 freeze？」
- 「我沒有看到 `release/*` 分支/或不確定版本號，能請你確認這次要用哪個 `release/x.y.z` 嗎？」
- 「你有權限對受保護分支開 PR/觸發部署嗎？如果沒有，需要找誰協助？」

### 4) 做出判斷並輸出建議

輸出內容固定包含：
- **現在立刻要做什麼**（1–3 點）
- **應該在哪個分支做**（建立/切換）+ **PR 目的地**
- **可直接複製貼上的指令**（安全、最小集合）
- **合併/部署前檢查**（CI、approve、tasks）
- **從快照偵測到的風險/違規點**
- **需要人協助的事項**（明確要找誰/問什麼）

## 判斷規則（依手冊）

- `main` = **已上線（或可視為 prod baseline）**。未確定要上線的功能不要進 `main`。
- 新工作一律從 `main` 開始：
  - `git checkout main && git pull origin main`
  - `git checkout -b feature/<ticket>-<desc>`
- **禁止** `feature/*` → `main`。PR 目的地應為 `feature/*` → `release/x.y.z`。
- `release/*` 是**唯一允許多功能整合**的分支。
- `sit`/`uat`/`prod` 是**部署分支**，不是開發分支。
- SIT/UAT 發現 bug 的修正：
  - 從 `release/x.y.z` 切 `bugfix/*` → PR 回 `release/x.y.z` → 再推進到 `sit`/`uat`。
- 緊急 hotfix：
  - 從 `prod` 切 `hotfix/*` → PR 到 `prod` + `main`（若有進行中的 release，視狀況同步到 `release/*`）。
