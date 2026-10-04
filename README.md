# Claude Code / Codex 社内標準テンプレート

社内向け Web アプリ（TypeScript + React / Python + FastAPI）開発と、資料作成などの事務作業を Claude Code（と Codex）で効率よく回すための設定一式。クローンして 3 ステップで使える。

## 導入（3 ステップ）

```bash
# 1) 指示ファイルを有効化（中身の <...> と仮のカラーコードを埋める）
cp AGENTS.md.template AGENTS.md
cp CLAUDE.md.template CLAUDE.md

# 2) 個人設定（Bedrock 利用者のみ）。AWS_PROFILE を必ず実値に書き換える
cp .claude/settings.local.json.template .claude/settings.local.json

# 3) claude を起動し、trust ダイアログを承認 → プラグインが自動で導入される
claude
```

前提: Claude Code v2.1.281 以上（Bedrock でも AGENTS.md を読める版）、`jq`（フック用）。

## 何が入っているか

| パス | 役割 |
| --- | --- |
| `AGENTS.md.template` | **共通ルールの正本**（Claude Code / Codex 両方が読む）。スタック・コマンド・進め方・KISS 方針 |
| `CLAUDE.md.template` | `@AGENTS.md` を取り込み、Claude 固有の skill の使い分けだけを追記 |
| `.claude/rules/frontend.md` | UI ファイルを触ったときだけ読み込まれる。デザイン方針・ブランドカラー |
| `.claude/rules/backend.md` | `.py` を触ったときだけ読み込まれる。FastAPI 規約 |
| `.claude/skills/` | 同梱スキル（下表）。出典は [ATTRIBUTION.md](./.claude/skills/ATTRIBUTION.md) |
| `.agents/skills` | `.claude/skills` へのシンボリックリンク（Codex 用） |
| `.claude/settings.json` | プラグイン宣言・権限・フック（チーム共有） |
| `.claude/hooks/` | `format.sh`（編集後に prettier / ruff）、`guard.sh`（破壊的コマンドを阻止） |

### プラグイン（settings.json で自動導入）

| プラグイン | 用途 |
| --- | --- |
| `superpowers` | 壁打ち（brainstorming）→ 計画 → TDD → デバッグの型 |
| `frontend-design` | 「AI っぽくない」UI デザイン |
| `document-skills` | Word / PowerPoint / Excel / PDF の作成・読み取り |

### 同梱スキル

| スキル | 用途 |
| --- | --- |
| `vercel-react-best-practices` / `vercel-composition-patterns` | React の性能・コンポーネント設計 |
| `typescript-advanced-types` | 型設計 |
| `fastapi` | FastAPI 本家のベストプラクティス |
| `grilling` | 計画・設計を 1 問ずつ詰める |
| `dataviz`（自作） | 資料・レポート用グラフの選び方と作り方 |

## 設計方針（なぜこの形か）

- **指示は短く**。毎回読み込まれる指示が長いほど遵守率が落ちる（公式目安: 1 ファイル 200 行未満）。モデルが推測できる一般論・リポジトリを読めば分かること・ツールで強制できることは書かない。エージェントが実際に間違えたことだけを足す
- **正本は AGENTS.md**。Claude Code と Codex で同じルールを使う。Claude 固有の内容だけ CLAUDE.md に書く
- **領域別ルールは必要なときだけ読む**。`.claude/rules/` の `paths:` で、フロント/バック作業時だけ読み込まれる
- **手順は skill に**。壁打ち・TDD・資料作成のような手順はルールファイルではなく skill に置き、必要時だけ読み込む
- **KISS・後方互換なし**。「特段の指示がない限り後方互換・データ移行はせず、理想形に書き換えて不要コードを消す」をルール化し、レガシーを溜めない。本番データ・公開 API・IaC だけは事前確認
- **確実に止めたいものはフックと権限で**。指示はあくまで助言。`.env` 読み取りや `rm -rf` は `deny` とフックで機械的に防ぐ

## 日常の流れ

1. 曖昧な要件 → brainstorming で壁打ち → 要件メモ → 計画
2. 実装 → テスト先行（TDD）
3. 仕上げ → `/simplify` → `/code-review`（認証・権限・外部入力を触ったら `/security-review`）
4. 資料 → 「この内容で pptx を作って」など document-skills / dataviz に任せる

## 運用メモ

- **個人設定**: `.claude/settings.local.json` は gitignore 済み（末尾 `*` なしの厳密一致。付けると `.template` まで無視される）。SSO の自動更新が要るなら `awsAuthRefresh` を追加
- **CI / `-p` 実行**: trust を経由しないのでプラグインは自動導入されない。`claude plugin marketplace add anthropics/skills && claude plugin install document-skills@anthropic-agent-skills` のように明示する
- **拡張**: プラグインは `/plugin install` 後に `enabledPlugins` へ 1 行追記。スキルは `npx skills add <owner/repo@skill>` で取得し `.claude/skills/` にコピーして ATTRIBUTION.md に追記
- **外す**: `/plugin disable <name>`、同梱スキルはディレクトリを削除
- **指示の見直し**: ときどき `/doctor prompt-audit` で矛盾・古い指示を洗い出す

| 症状 | 対処 |
| --- | --- |
| プラグインが入らない | `/plugin marketplace list` の名前と `enabledPlugins` のキーを照合 |
| フックが動かない | `jq` の有無、`chmod +x` |
| Bedrock でエラー | `AWS_PROFILE` が雛形のままでないか |
| skill が発火しない | 「○○ skill を使って」と明示。description とずれていないか確認 |

## 参考

- [Claude Code: Memory（CLAUDE.md / AGENTS.md / rules）](https://code.claude.com/docs/en/memory)
- [Claude Code: Skills](https://code.claude.com/docs/en/skills)
- [Claude Code: Settings](https://code.claude.com/docs/en/settings) / [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock)
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) / [anthropics/skills](https://github.com/anthropics/skills) / [skills.sh](https://skills.sh/)
- [Writing a Good AGENTS.md](https://www.philschmid.de/writing-good-agents)
