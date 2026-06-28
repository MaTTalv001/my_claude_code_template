# 導入・設定ガイド

[README.md](./README.md) で選定したスキル・設定方針を、実際に Claude Code へ適用するためのガイド。

本リポジトリは設定の実体（`.claude/`）と `CLAUDE.md` テンプレを**コミット済み**で配っている。そのため導入は「手でコマンドを連打する」のではなく、**クローンして trust（信頼）を押すだけ**が基本。本ガイドは「何が同梱されていて、何が手作業として残るか」を説明する。

> **前提**：Claude Code は導入済みで CLI から動作する状態。認証・ネットワーク・本体インストールは扱わない。

---

## 0. このリポジトリに同梱されているもの

クローンするとリポジトリ直下に `.claude/` が付いてくる。

| パス | 役割 | git |
| --- | --- | --- |
| `.claude/settings.json` | 権限（permissions）・フック・**プラグイン宣言**（`enabledPlugins` / `extraKnownMarketplaces`） | コミット |
| `.claude/skills/` | **同梱（vendoring）したスキル**（Tier 2 ＋ grill-me 等）＋ `ATTRIBUTION.md` | コミット |
| `.claude/hooks/format.sh` `guard.sh` | フックスクリプト（実行権限付き） | コミット |
| `.claude/settings.local.json.template` | Bedrock 等、**個人ごとの設定の雛形** | コミット |
| `.claude/settings.local.json` | 各自がコピーして実値を入れる本番ローカル設定 | **gitignore（厳密一致）** |
| `CLAUDE.md` | プロジェクト用 `CLAUDE.md` のテンプレ（リポジトリ直下。`（仮）` を埋めて使う） | コミット |

---

## 1. セットアップ手順（最小）

```bash
# 1) クローン
git clone <this-repo> && cd <this-repo>

# 2) Claude Code で開く → 初回の trust（信頼）ダイアログを承認
#    → settings.json の宣言に従い Tier 1 / Tier 3 プラグインの導入導線が出る（superpowers / frontend-design / document-skills）
#    → Tier 2 スキルは .claude/skills/ に同梱済みなので何もしなくてよい

# 3) Bedrock など個人設定（人ごとに値が違う）
cp .claude/settings.local.json.template .claude/settings.local.json
$EDITOR .claude/settings.local.json   # AWS_PROFILE 等を自分の実値へ。※雛形のままだと認証失敗

# 4) プロジェクト用 CLAUDE.md を埋める（リポジトリ直下に同梱済み）
$EDITOR ./CLAUDE.md   # 出力先パス・ブランドカラー #XXXXXX（仮）を実値へ
```

**確認**：

```bash
/plugin                 # Tier 1/3 プラグインが enable されているか
/permissions            # allow/ask/deny の状態
cat .claude/settings.json
ls .claude/skills/      # 同梱スキルが見えるか
```

---

## 2. 自動 / 手作業の線引き

| 区分 | 対象 | やること |
| --- | --- | --- |
| **自動（trust で入る）** | Tier 1 / Tier 3 プラグイン（superpowers / frontend-design / document-skills、任意で codspeed / coderabbit） | クローン後の trust 承認のみ |
| **同梱（クローンで付属）** | Tier 2 スキル・フックスクリプト・権限・CLAUDE.md テンプレ | 何もしない（`CLAUDE.md` は値を埋める） |
| **手作業が残る** | Bedrock 等の個人設定 / 前提依存の用意 / ブランドカラーの実値 / CI 経路 | 下記 3〜6 を参照 |

---

## 3. 同梱プラグイン（settings.json の宣言）

`.claude/settings.json` に以下を宣言済み。trust 承認時に導入導線が出る。

```json
{
  "extraKnownMarketplaces": {
    "superpowers-marketplace": { "source": { "source": "github", "repo": "obra/superpowers-marketplace" } },
    "anthropic-agent-skills":  { "source": { "source": "github", "repo": "anthropics/skills" } }
  },
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "frontend-design@claude-plugins-official": true,
    "document-skills@anthropic-agent-skills": true
  }
}
```

- `frontend-design` は公式マーケット（`claude-plugins-official`）が既定で既知なので、マーケット宣言なしで enable のみ。
- **Tier 3 を足す**場合は `enabledPlugins` に 1 行追加するだけ：`"codspeed@claude-plugins-official": true` / `"coderabbit@claude-plugins-official": true`。
- **注意**：`enabledPlugins` のキーは `プラグイン名@マーケットプレイス名`。マーケット名は各マーケットの `marketplace.json` の `name` 由来でリポジトリ名とは限らない。時期で変動するので、入らないときは `/plugin marketplace list` の実名と突き合わせる。
- **セキュリティ**：プラグインは任意コードを実行しうる。`enabledPlugins` に足す前に作者・リポジトリを確認すること。

---

## 4. 同梱スキル（vendoring：.claude/skills/）

Tier 2 系（元は `npx skills` 配布）は中身がただの `SKILL.md` なので、`.claude/skills/` に直接コピーしてコミットしてある。Claude Code はネイティブで `.claude/skills/` を読むため、**`npx skills` の実行は不要**でクローンに付いてくる。

| スキル | 用途 |
| --- | --- |
| `vercel-react-best-practices` | React / Next.js のパフォーマンス最適化 |
| `vercel-composition-patterns` | React コンポジション設計（React 19 含む） |
| `fastapi` | FastAPI の async / Pydantic / DI / 認証パターン |
| `typescript-advanced-types` | 型ガード・ジェネリクス・ユーティリティ型 |
| `grill-me` / `grilling` | 計画・設計を 1 問ずつ詰める壁打ち（実装前のストレステスト） |

- **トレードオフ**：同梱なので上流の更新は自動で入らない（凍結される）。出典・ライセンス・**更新手順**は [.claude/skills/ATTRIBUTION.md](./.claude/skills/ATTRIBUTION.md) にまとめてある。
- `grill-me` は `/grilling` を呼ぶ薄いラッパーなので、本体の `grilling` も併せて同梱している（片方だけだと機能しない）。
- **セキュリティ**：スキルは任意テキストを Claude に読み込ませる。第三者スキルを `.claude/skills/` に足すときは中身を監査してから入れる。

---

## 5. settings.json：権限（permissions）

毎回承認を減らすための allow/ask/deny を同梱済み。考え方:

- `defaultMode: "acceptEdits"` … ファイル編集の都度承認を省く（実行系の allow とは別軸）。
- `allow` … ビルド・テスト・lint・git 読み取り＋ commit・`docker compose` 等、安全で頻出の操作を自動許可。
- `ask` … 不可逆だが時々やる操作（`git push`）は毎回確認。
- `deny` … 破壊的操作（`rm -rf` / `sudo`）と秘匿ファイル読み取り（`.env` / `*.pem`）を抑止。
- ルールは `Tool(specifier)` 形式。`Bash(npm run build:*)` の `:*` は引数ワイルドカード。

> 実体は `.claude/settings.json` の `permissions` ブロック。対象は環境に合わせて調整する。`/permissions` でも確認・編集でき、承認時に「今後確認しない」を選ぶと settings に追記される。全許可（`bypassPermissions`）は使わず allow を足していく運用が安全。

---

## 6. settings.json / hooks：フック

ツール実行の前後などで自分のシェルを自動実行する仕組み。本リポジトリは 2 つを同梱:

- **編集後の自動フォーマット**（`PostToolUse` × `Edit|MultiEdit|Write` → `format.sh`）：TS 系は Prettier、Python は ruff で整形。
- **危険コマンドのガード**（`PreToolUse` × `Bash` → `guard.sh`）：`rm -rf /` 等を実行前にブロック（`deny` と二重化）。`exit 2` でブロックされ stderr が Claude に伝わる。

**前提依存（hooks 共通）**：

- 両スクリプトとも **`jq` に依存**。未導入だと判定できず素通し/スキップになる（settings.json では配れない前提依存）。
- 実行権限が必要。同梱済みで `chmod +x` 済みだが、git 経由で実行ビットが落ちた場合は `git update-index --chmod=+x .claude/hooks/*.sh` で戻す。
- フォーマッタ（`prettier` / `ruff`）が無い言語・環境では、その分は静かにスキップするよう書いてある。

> settings.json の hooks に書く＝**チーム全員のマシンで同じシェルスクリプトが走る**。配布前に `format.sh` / `guard.sh` の中身を確認すること。

---

## 7. settings.local.json：個人ごとの設定（Bedrock 等）

開発者ごとに異なる値（Bedrock の region/profile 等）は `settings.local.json` に置く。`settings.json` と同じ効力を持ち、deep-merge され、`settings.local.json` が優先される。

```bash
cp .claude/settings.local.json.template .claude/settings.local.json
```

雛形（`.template`）の中身:

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_REGION": "us-east-1",
    "AWS_PROFILE": "REPLACE_WITH_YOUR_AWS_PROFILE"
  }
}
```

- `AWS_PROFILE` を**自分の実プロファイル名へ必ず書き換える**。`env` は置いた瞬間にセッションへ反映されるため、雛形のまま起動すると Bedrock 認証に失敗してエラーになる。
- SSO 等でトークンを定期更新したい場合は `awsAuthRefresh` / `awsCredentialExport` も使える。単純な profile/region 指定なら `env` だけで十分。
- `.gitignore` は `.claude/settings.local.json`（**末尾 `*` なしの厳密一致**）。`*` を付けると `.template` まで無視されて型を共有できなくなるので注意。

---

## 8. CLAUDE.md の配置

`CLAUDE.md` は Claude Code が毎回読み込む永続コンテキスト。**ドキュメントではなくプロンプト**として書く（[README.md](./README.md) 6 節参照）。3 階層で使い分ける:

- **Project（共有）**：リポジトリ直下の `CLAUDE.md`（テンプレ同梱済み）。出力先パスとブランドカラー `#XXXXXX（仮）` を実値へ埋める。**ここがメイン。** git にコミットして共有。
- **Global（個人）**：`~/.claude/CLAUDE.md`。全プロジェクト共通の指示（「テストを先に書く」「日本語で応答」等）。
- **Local（個人）**：`CLAUDE.local.md`（gitignore）。自分用の検証パスや一時メモ。

テンプレ（[CLAUDE.md](./CLAUDE.md)）に反映済みの内容：スタック宣言／開発フロー（brainstorming → TDD →`/simplify`・`/review`）／フロントは配色だけブランドカラートークン厳守／NG リスト。

---

## 9. CI / headless（`-p`）での注意

trust ダイアログを前提とする自動導入は、**`-p`（headless / CI）では trust がスキップされ `extraKnownMarketplaces` / `enabledPlugins` が処理されない**。CI でプラグインを使うなら、ワークフロー内で明示的に追加する:

```bash
claude plugin marketplace add anthropics/skills
claude plugin install document-skills@anthropic-agent-skills
```

（公式 GitHub Action を使う場合は `plugin_marketplaces` 入力で宣言する。）同梱スキル（`.claude/skills/`）・hooks・権限はファイルなので CI でもそのまま効く。`jq` 等の前提依存は CI イメージ側に入れておく。

---

## 10. 拡張を後から足す

クローン後に個別で増やしたくなったときの手順（A=プラグイン、B=スキル）。

```bash
# A. プラグイン：導入してから settings.json の enabledPlugins に1行追記して共有
/plugin marketplace add <owner>/<repo>
/plugin install <plugin>@<marketplace>

# B. スキル：npx skills で取得 → .claude/skills/ にコピーして vendoring（ATTRIBUTION.md に追記）
npx skills find <query>
npx skills add <owner/repo@skill> -g -y
cp -R ~/.agents/skills/<skill> .claude/skills/<skill>
```

---

## 11. アンインストール / 一時停止

```bash
# プラグイン
/plugin disable <name>     # 一時無効化（/plugin enable で復帰）
/plugin uninstall <name>   # 完全削除（settings.json の enabledPlugins からも消す）

# 同梱スキル
rm -rf .claude/skills/<skill>   # ATTRIBUTION.md からも該当行を削除
```

---

## 12. トラブルシュート

| 症状 | 対処 |
| --- | --- |
| trust 後もプラグインが入らない | `/plugin marketplace list` でマーケット名を確認し、`enabledPlugins` のキー（`名前@マーケット名`）と突き合わせる。 |
| CI でプラグインが無い | `-p` では trust 非経由。9 節のとおりワークフローで明示 `add` / `install` する。 |
| 同梱スキルがトリガーされない | `description` とプロンプト文面の乖離。「○○スキルを使って」と明示。CLAUDE.md に呼び出し導線を書くと発火しやすい。 |
| hooks が動かない | `chmod +x` があるか、`jq` が入っているか、パスが正しいか。 |
| Bedrock でエラー | `settings.local.json` の `AWS_PROFILE` が雛形のまま／無効でないか。`AWS_REGION` と合わせて実値か確認。 |
| `.template` を gitignore してしまう | `.gitignore` を `.claude/settings.local.json`（末尾 `*` なし）にする。 |
| Office 文書系で実行エラー | Python 依存（`python-pptx` 等）の欠落。エラーの `pip install` を許可。 |

---

## 13. 参考

- [Plugin Marketplaces 公式ドキュメント](https://code.claude.com/docs/en/plugin-marketplaces)
- [Settings / Hooks 公式ドキュメント](https://code.claude.com/docs/en/settings)
- [Amazon Bedrock 連携（Claude Code）](https://code.claude.com/docs/en/amazon-bedrock)
- [Anthropic Plugins Official Catalog](https://github.com/anthropics/claude-plugins-official)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [skills.sh（オープンスキルエコシステム / `npx skills`）](https://skills.sh/)
