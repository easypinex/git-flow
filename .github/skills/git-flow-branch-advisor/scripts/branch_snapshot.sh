#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "找不到 git（PATH 內無 git 指令）" >&2
  exit 127
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "目前不在 git repository 內。"
  exit 0
fi

top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
repo_name="$(basename "${top:-.}")"

echo "# Git 分支快照"
echo
echo "- repo：${repo_name}"
echo "- 根目錄（toplevel）：${top:-unknown}"

current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [[ -n "${current_branch}" ]]; then
  echo "- 目前分支：${current_branch}"
else
  echo "- 目前分支：（detached HEAD 或尚未建立首個 commit）"
fi

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  head_sha="$(git rev-parse --short HEAD)"
  echo "- HEAD：${head_sha}"
else
  echo "- HEAD：（尚無 commit）"
fi

echo
echo "## 工作目錄狀態（Working Tree）"
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git -c core.quotePath=false status -sb --porcelain=v1
else
  git -c core.quotePath=false status -sb
fi

echo
echo "## Remote"
if git remote >/dev/null 2>&1 && [[ -n "$(git remote)" ]]; then
  git remote -v
else
  echo "（尚未設定 remote）"
fi

echo
echo "## 關鍵分支是否存在（local 或 origin/*）"
head_ref="$(git symbolic-ref -q HEAD 2>/dev/null || true)"
for b in main sit uat prod; do
  if [[ "${head_ref}" == "refs/heads/${b}" ]]; then
    echo "- ${b}：有（目前所在分支；可能尚未有 commit）"
  elif git show-ref --verify --quiet "refs/heads/${b}" || git show-ref --verify --quiet "refs/remotes/origin/${b}"; then
    echo "- ${b}：有"
  else
    echo "- ${b}：沒有"
  fi
done

echo
echo "## release/* 分支（local + origin）"
releases="$(
  {
    git for-each-ref --format='%(refname:short)' refs/heads/release/ 2>/dev/null || true
    git for-each-ref --format='%(refname:short)' refs/remotes/origin/release/ 2>/dev/null || true
  } | sed 's#^origin/##' | sort -u
)"

if [[ -n "${releases}" ]]; then
  echo "${releases}" | sed 's/^/- /'
else
  echo "（找不到 release/*）"
fi

echo
echo "## Upstream 狀態（若已設定）"
if git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" >/dev/null 2>&1; then
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}")"
  echo "- upstream：${upstream}"
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    counts="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null || true)"
    if [[ -n "${counts}" ]]; then
      behind="${counts%% *}"
      ahead="${counts##* }"
      echo "- ahead/behind：+${ahead} / -${behind}"
    fi
  fi
else
  echo "（尚未設定 upstream）"
fi

echo
echo "## 近期 commits（HEAD）"
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git -c core.quotePath=false log --oneline --decorate -n 15
else
  echo "（尚無 commit）"
fi
