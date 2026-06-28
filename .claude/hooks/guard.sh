#!/usr/bin/env bash
# PreToolUse(Bash) フック：破壊的コマンドを実行前にブロックする安全網。
# exit 2 でツール呼び出しがブロックされ、stderr の内容が Claude に伝わる。
# 依存: jq（必須）。未導入なら判定できないので素通し（権限 deny 側で二重防御）。
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# rm -rf /, mkfs, dd if=, fork bomb 等の代表的な破壊パターン
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*rf?[a-zA-Z]*[[:space:]]+/|mkfs|dd[[:space:]]+if=|:\(\)\{|>[[:space:]]*/dev/sd'; then
  echo "危険なコマンドをブロックしました: $cmd" >&2
  exit 2
fi
exit 0
