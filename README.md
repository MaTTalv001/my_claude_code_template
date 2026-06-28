# Claude Code マイ・スタンダード

CLI で動く Claude Code を **「素朴に使う」状態から一段引き上げる** ための知見メモ。社内 Web アプリ開発（TypeScript / React / Python / FastAPI）・ドキュメント作成・データ分析を主用途として、**何を・なぜ入れ、どう設定し、どう運用するか**をまとめる。

> 前提：Claude Code は導入済みで CLI から動作する状態。本リポジトリはその上で「効果を最大化する」レイヤ（スキル・CLAUDE.md・設定・運用）に集中する。インストールや認証の配管は扱わない。用途別 EC2 の差異は意識せず、**どの環境でも適用できる汎用構成**として記述する。

このリポジトリの構成:

- **推奨プラグイン・スキルと設計方針**（このファイル）
- **導入・設定の手順書**（[install.md](./install.md)）
- **CLAUDE.md テンプレート**（[CLAUDE.md](./CLAUDE.md)）
- **コミット済みの実設定**：リポジトリ直下の `.claude/`。クローンすればそのまま付いてくる。
  - `settings.json` … 権限（permissions）・フック・プラグイン宣言（`enabledPlugins` / `extraKnownMarketplaces`）
  - `skills/` … 同梱（vendoring）したスキル群
  - `hooks/` … フックスクリプト（`format.sh` / `guard.sh`、実行権限付き）
  - `settings.local.json.template` … Bedrock など個人ごとの設定の雛形（コピーして使う）

---

## 0. 用語整理

Claude Code の拡張は「スキル」「プラグイン」「マーケットプレイス」の単位で扱う。混同しやすいので最初に整理する。

| 用語 | 何か | 入手経路 |
| --- | --- | --- |
| **スキル (Skill)** | 特定タスクの専門知識・手順をまとめた最小単位。`SKILL.md` と補助ファイルで構成され、トリガー条件にマッチすると自動で読み込まれる。 | プラグイン同梱、または `npx skills` で単体導入 |
| **プラグイン (Plugin)** | スキル・スラッシュコマンド・サブエージェント・MCP サーバー・フックをまとめた配布単位。 | `/plugin install`（マーケットプレイス経由） |
| **マーケットプレイス (Marketplace)** | プラグインのカタログ。GitHub リポジトリや URL を登録して使う。 | `/plugin marketplace add` |
| **MCP サーバー** | 外部システム連携用のサーバープロトコル。プラグインに同梱されることが多い。 | プラグイン内、または個別設定 |

### 配布ルートは 2 系統ある（重要）

| ルート | コマンド | 配布元 | 主に何が来るか |
| --- | --- | --- | --- |
| **公式プラグイン** | `/plugin install …` | `claude-plugins-official` / `anthropics/skills` 等のマーケットプレイス（GitHub） | superpowers, frontend-design, document-skills, skill-creator など |
| **オープンスキル** | `npx skills add …` | [skills.sh](https://skills.sh/) エコシステム | React / FastAPI / TypeScript などのベストプラクティス系 |

> 「ベストプラクティス系スキルが公式マーケットに無い」のは正常。それらは skills.sh 側で配布されており `npx skills` で入れる。両系統は併存して問題ない。

> **本リポジトリでの扱い（重要）**：上の 2 系統を踏まえた上で、メンバーの導入を「**クローンして trust を押すだけ**」に圧縮している。手で `/plugin install` や `npx skills add` を叩く必要は基本的に無い。
>
> | 対象 | 元の入手経路 | 本リポジトリでの配り方 |
> | --- | --- | --- |
> | Tier 1 / Tier 3 プラグイン | `/plugin install` | `.claude/settings.json` に宣言済み → **trust 承認時に自動導入** |
> | Tier 2 スキル | `npx skills add` | `.claude/skills/` に **同梱（vendoring）** → 実行不要でクローンに付属 |
> | CLAUDE.md / 権限 / フック | 手作業で配置 | `.claude/` と `CLAUDE.md` に **コミット済み** |
> | Bedrock の region/profile 等の個人設定 | 各自で環境変数 | `.claude/settings.local.json.template` を**コピーして記入**（gitignore 対象） |
>
> 手順の実体は [install.md](./install.md) を参照。

---

## 1. 設計方針

- **常駐で得するものだけ入れる**：トリガー条件が広いスキルは常に読み込まれてコンテキストを圧迫する。用途が明確なものを選ぶ。
- **汎用で書く**：どの用途の環境でも同じ手順で再現できる構成にする。環境固有の差分は CLAUDE.md 側に寄せる。
- **公式・有力 OSS を優先**：Anthropic 公式または実績のある OSS（superpowers, Vercel Labs 等）を一次選定し、メンテと品質の安全マージンを取る。
- **後から外せる粒度**：プラグイン/スキル単位で扱い、簡単に止め外しできる状態を保つ。プラグインは `/plugin disable`、同梱スキルは `.claude/skills/<skill>` を削除（手順は [install.md](./install.md) 11 節）。

---

## 2. 推奨セット概要（先に結論）

社内 Web アプリ開発＋ドキュメント作成＋分析向けの推奨構成。

### 🟢 Tier 1: ほぼ全環境で入れて損なし

| 名称 | 種別 | ルート | 目的 |
| --- | --- | --- | --- |
| **superpowers** | プラグイン | `/plugin` | 要件の壁打ち（brainstorming）・TDD・計画駆動の構造化ワークフロー |
| **frontend-design**（公式） | プラグイン | `/plugin` | フロントのデザインを「AI っぽくない」記憶に残るものにする |
| **document-skills**（docx/pptx/xlsx/pdf） | プラグイン | `/plugin` | 資料作成を Claude にやらせる |
| **skill-creator** | スキル | document-skills 同梱 | 自分専用スキルを短時間でスキャフォールドするメタスキル |

### 🟡 Tier 2: スタック適合度が高いもの

> 元は `npx skills` 配布だが、本リポジトリでは **`.claude/skills/` に同梱（vendoring）済み**。クローンで付いてくるので個別導入は不要。出典・ライセンス・更新方法は [.claude/skills/ATTRIBUTION.md](./.claude/skills/ATTRIBUTION.md) を参照。

| 名称 | 種別 | 配り方 | 目的 |
| --- | --- | --- | --- |
| **vercel-react-best-practices** | スキル | 同梱 | React / Next.js のパフォーマンス最適化指針 |
| **vercel-composition-patterns** | スキル | 同梱 | React のコンポジション設計（React 19 API 含む） |
| **fastapi（本家）** | スキル | 同梱 | FastAPI の async / Pydantic / 認証等の実装パターン |
| **typescript-advanced-types** | スキル | 同梱 | 型ガード・ジェネリクス・ユーティリティ型の体系的指針 |
| **grill-me** / **grilling** | スキル | 同梱 | 計画・設計を 1 問ずつ詰めて壁打ちする（実装前のストレステスト）|

### 🔵 Tier 3: 品質ゲート系（任意）

| 名称 | 種別 | ルート | 目的 |
| --- | --- | --- | --- |
| **simplify** / **review** / **security-review** | スキル | 標準同梱 | リファクタ・PR レビュー・セキュリティレビュー |
| **codspeed** | プラグイン | `/plugin` | パフォーマンスベンチマーク（必要になってから） |
| **coderabbit** | プラグイン | `/plugin` | 自動 PR レビュー（チーム導入時に検討） |

導入コマンドは [install.md](./install.md) を参照。

---

## 3. Tier 1 詳細：必須レベル

### 3-1. superpowers（要件壁打ち & 構造化ワークフロー）

- **brainstorming**：コードを書く前に要件を質問で深掘りし、代替案提示・セクション単位での合意形成を行う。「仕様があいまいな時の壁打ち」がこれ。
- **writing-plans**：壁打ちで固まった文脈を計画ドキュメント化。
- **test-driven-development**：Red → Green → Refactor の強制サイクル。
- **subagent-driven-development**：並列実行と二段階レビュー。
- **systematic-debugging**：根本原因分析を強制するデバッグ手順。

**なぜ効くか**：社内ツールは仕様が口頭で曖昧になりがち。最初に brainstorming を通すと手戻りが激減する。スキル単位で必要なときだけ呼べるので軽い修正の邪魔にならない。

### 3-2. frontend-design（公式）

- コード生成の前に **配色・タイポグラフィ・空間構成などの美学方針** を意図的に決めさせる。
- AI が選びがちな汎用フォント/配色を回避し、記憶に残る UI にする。

**なぜ効くか**：社内向けでも UI が良いと使われ続ける。ただし **配色は会社ブランドカラーを使う**運用なので、本スキルは**レイアウト・タイポ・情報設計の参考**として使い、色は CLAUDE.md で定義したトークンに固定する（[CLAUDE.md](./CLAUDE.md) 参照）。

### 3-3. document-skills（Word / PowerPoint / Excel / PDF）

- **pptx**：プレゼン資料の生成。**docx**：Word 文書。**xlsx**：Excel（数式・スタイル含む）。**pdf**：抽出・生成。

**なぜ効くか**：資料作成・分析レポートの叩き台を Claude に作らせ、人は中身を磨く分業ができる。

### 3-4. skill-creator

- 対話形式の Q&A で `SKILL.md` をスキャフォールド。フロントマター・トリガー条件・ファイル構成を自動整備。

**なぜ効くか**：社内固有業務（申請書チェック、社内 API ラッパ生成 等）を自分のスキルとして雛形化でき、このスタンダード自身を育てる土台になる。

---

## 4. Tier 2 詳細：スタック適合

### 4-1. TypeScript / React

- **vercel-react-best-practices**：再レンダリング削減・メモ化・データフェッチ等のパフォーマンス指針。
- **vercel-composition-patterns**：コンポジション設計、プロップのバケツリレー回避、React 19 API の取り回し。
- **typescript-advanced-types**：型ガード・ジェネリクス・ユーティリティ型。

「常駐」より「設計判断時・PR 前にスポット起動」が合う。

### 4-2. Python / FastAPI

- **fastapi（本家プロジェクト配布）**：async / Pydantic v2 / 依存性注入 / 認証の実装パターン。本家リポジトリが公開しているため権威性が高い。

### 4-3. 品質ゲート（標準同梱）

- `claude-api`：Anthropic SDK を使った Python/TS のコード生成・モデル移行に対応。社内で API ラッパを書くなら活用。

---

## 5. Tier 3 詳細：品質ゲート（任意）

- **simplify / review / security-review**：機能実装の終わり際に `/simplify` → `/review` の二段で回す。認証・権限・外部入力を触ったら `/security-review` を追加。
- **codspeed**：パフォーマンス退行を CI でガードしたいとき。
- **coderabbit**：チーム導入で PR 自動レビューを定常化したいとき。

---

## 6. CLAUDE.md 設計（効果最大化の本丸）

`CLAUDE.md` はリポジトリに置く「Claude への永続コンテキスト」。**ドキュメントではなくプロンプト**として扱うのがコツ。

### 3 階層構造

1. **Global（個人グローバル）**：`~/.claude/CLAUDE.md` — どのプロジェクトでも効かせたい指示（「テストを先に書く」「冗長なコメントを増やさない」等）。
2. **Project（共有）**：リポジトリ直下の `CLAUDE.md` — スタック・コマンド・規約。git にコミットしてチームで共有。**ここがメイン。**
3. **Local（個人ローカル）**：`CLAUDE.local.md`（gitignore）— 自分用の検証パスや一時メモ。

### 書き方の原則

- **指示は簡潔・命令形**。背景説明より「守ってほしいルール」を箇条書きで。
- **守ってほしいことと NG を両方書く**。「やらないこと」リストは効果が大きい。
- **導入スキルを前提に書く**：「要件があいまいなら `/superpowers:brainstorm` で壁打ち」「実装は TDD」「資料は document-skills で生成」のように、入れたスキルを呼び出す導線を CLAUDE.md に明記すると発火率が上がる。
- **長すぎない**。常時読み込まれるのでコンテキストを食う。ルールに絞る。

### このスタンダードでの標準内容

[CLAUDE.md](./CLAUDE.md) に、以下を反映したコピペ用テンプレを用意:

- **技術スタック宣言**：フロント TS+React / バック Python+FastAPI / `npm run build` の成果物をバックエンド配下へ出力し FastAPI が配信 / Docker Compose 管理 / IaC があればその仕様に準拠。
- **開発フロー**：要件は brainstorming の壁打ちから → 実装は必ずテスト（TDD）→ 完了時に `/simplify`・`/review`。
- **フロントデザイン**：`frontend-design` はレイアウト等の参考に留め、配色はブランドカラートークン（仮置き）を厳守。
- **NG リスト**：テスト省略・無断大規模リファクタ・ブランドカラー以外の使用・IaC 無断変更 など。

> ブランドカラーのカラーコードはテンプレ内で `#XXXXXX（仮）` にしてある。確定したら差し替える。

---

## 7. 設定・フック・権限・subagent・MCP

「効かせ方」はスキルだけでなく `settings.json` による運用設計も大きい。**本リポジトリでは下記の権限・フックは `.claude/settings.json` と `.claude/hooks/` にコミット済み**で、クローンすればそのまま効く。ここでは方針だけ示し、実体・調整方法は [install.md](./install.md) の該当節へ。

### 7-1. 権限（毎回承認の手間を減らす）

- 安全な定常コマンド（ビルド・テスト・lint・git の読み取り系・`docker compose` 等）は **allow リスト**に入れて自動許可。
- 破壊的・不可逆な操作（`rm -rf`、`git push`、`sudo`、本番反映 等）は **allow に入れず**、毎回確認 or `deny` で抑止。
- 編集は `defaultMode: "acceptEdits"` でファイル編集の都度承認を省く（実行系コマンドの allow とは別軸）。
- 迷ったら全許可（`bypassPermissions`）ではなく **allow リストを足していく**運用にする。`/permissions` UI や「今後確認しない」承認でも settings に追記できる。

### 7-2. フック（hooks）

特定イベント（ツール実行前後、応答終了時 等）で**自分のシェルコマンドを自動実行**する仕組み。初心者がまず入れて得するものに絞ると:

1. **編集後の自動フォーマット**（最有効）：ファイル編集のたびに Prettier（TS）/ ruff（Python）を自動実行。整形のブレが消える。
2. **危険コマンドのガード**：`rm -rf` 等を実行前にブロック（allow/deny と二重の安全網）。
3. **秘匿ファイルの保護**：`.env` 等の読み取りを実行前にブロック（本リポジトリでは 7-1 の `deny` で代替）。

本リポジトリでは 1・2 を `.claude/hooks/format.sh` / `guard.sh` として同梱済み（実行権限付き）。**`jq` に依存**するので未導入だと発火しない点だけ注意。

### 7-3. settings.local.json（個人ごとの設定・Bedrock）

- `settings.json`（チーム共有）と同じ効力を持つが、**開発者ごとに異なる値**を置く場所。`settings.local.json` の方が優先され、deep-merge される。
- Bedrock 利用時の `AWS_REGION` / `AWS_PROFILE` / `CLAUDE_CODE_USE_BEDROCK` などは `env` ブロックに書く。雛形を [.claude/settings.local.json.template](./.claude/settings.local.json.template) として用意してあるので、**コピーして自分の値を記入**する。
- 実ファイル `settings.local.json` は `.gitignore`（厳密一致）で共有しない。雛形（`.template`）だけ共有する。
- 注意：`env` は置いた瞬間にセッションへ反映される。`AWS_PROFILE` を雛形のまま起動すると認証に失敗するので、コピー後は必ず実値へ書き換える。

### 7-4. subagent / MCP

- **subagent**：大きめの調査・並列タスクを別コンテキストに切り出す。superpowers の subagent-driven-development が定石を提供。乱用するとコストが増えるので「独立した重い調査」に限定。
- **MCP**：社内 DB・チケット・ドキュメント基盤などと連携したくなったら検討。まずはスキル＋CLAUDE.md で十分なことが多い。

---

## 8. 運用ワークフロー（日常の回し方）

1. **要件があいまい** → `/superpowers:brainstorm` で壁打ち → 計画化。
2. **実装** → TDD（テスト先行）。既存パターンに合わせる。
3. **動作確認** → `docker compose up` 等で実環境に近い形で確認。
4. **仕上げ** → `/simplify`（重複・冗長の整理）→ `/review`（PR 観点）。
5. **セキュリティ影響あり**（認証・権限・外部入力）→ `/security-review`。
6. **資料・分析が必要** → document-skills で生成。

> ポイント：これらの導線を CLAUDE.md にも書いておくと、Claude が自発的に正しいスキルを呼びにいくようになる。

---

## 9. 参考リンク

### 公式

- [Anthropic 公式プラグインカタログ](https://github.com/anthropics/claude-plugins-official)
- [Anthropic Skills 公式リポジトリ](https://github.com/anthropics/skills)
- [Claude Code Plugin Marketplaces ドキュメント](https://code.claude.com/docs/en/plugin-marketplaces)
- [Claude Code Settings / Hooks ドキュメント](https://code.claude.com/docs/en/settings)

### スキルエコシステム

- [skills.sh（`npx skills`）](https://skills.sh/) — React / FastAPI / TypeScript 等のベストプラクティス系
- [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)

### superpowers

- [obra/superpowers (GitHub)](https://github.com/obra/superpowers)

### CLAUDE.md

- [CLAUDE.md ベストプラクティス（DEV.to）](https://dev.to/gunnargrosch/teaching-claude-code-how-you-work-claudemd-in-practice-21d9)
- [CLAUDE.md テンプレ集](https://github.com/abhishekray07/claude-md-templates)
