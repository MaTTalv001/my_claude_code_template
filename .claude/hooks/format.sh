#!/usr/bin/env bash
# PostToolUse(Edit|MultiEdit|Write) フック：編集対象を自動整形する。
# stdin に渡される JSON から編集ファイルパスを取得。
# 依存: jq（必須）, prettier / ruff（対象言語があれば）。未導入なら静かにスキップ。
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

case "$file" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.md|*.html)
    if command -v npx >/dev/null 2>&1; then
      npx --no-install prettier --write "$file" >/dev/null 2>&1 || true
    fi
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file" >/dev/null 2>&1 || true
      ruff check --fix "$file" >/dev/null 2>&1 || true
    fi
    ;;
esac
exit 0
