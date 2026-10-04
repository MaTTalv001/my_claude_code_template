# Vendored Skills — 出典と帰属

`.claude/skills/` 配下のスキルは、外部リポジトリの `SKILL.md` を**スナップショットとして同梱（vendoring）**したもの。
クローンしただけで `npx skills` 導入なしに使えるようにするための運用。実体は Claude Code がネイティブで読む `.claude/skills/`。Codex 用に `.agents/skills` → `.claude/skills` のシンボリックリンクを置いている。

> **トレードオフ**：同梱なので上流の更新は自動で入らない（凍結される）。更新したい場合は下表の元リポジトリから取り直すこと。
> 各スキルのフロントマター（`license` / `metadata.author`）も帰属情報として保持している。

| スキル | 元リポジトリ | npx skills 識別子 | ライセンス |
| --- | --- | --- | --- |
| `vercel-react-best-practices` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | `vercel-labs/agent-skills@vercel-react-best-practices` | MIT（SKILL.md 記載） |
| `vercel-composition-patterns` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | `vercel-labs/agent-skills@vercel-composition-patterns` | MIT（SKILL.md 記載） |
| `fastapi` | [fastapi/fastapi](https://github.com/fastapi/fastapi) | `fastapi/fastapi@fastapi` | 元リポジトリは MIT（同梱時に要確認） |
| `typescript-advanced-types` | [wshobson/agents](https://github.com/wshobson/agents) | `wshobson/agents@typescript-advanced-types` | 元リポジトリのライセンスに従う（要確認） |
| `grilling` | [mattpocock/skills](https://github.com/mattpocock/skills) | `mattpocock/skills@grilling` | MIT（LICENSE 記載） |

## 更新手順（上流に追従したいとき）

```bash
# 例：vercel-react-best-practices を最新化
npx skills add vercel-labs/agent-skills@vercel-react-best-practices -g -y
cp -R ~/.agents/skills/vercel-react-best-practices .claude/skills/vercel-react-best-practices
```

## 注意

- 配布前に各上流のライセンス・帰属条件を確認すること（特に `license` 未記載の 2 つ）。
- スキルは任意のテキストを Claude に読み込ませる。`.claude/skills/` に第三者のスキルを追加する際は中身を監査してから入れる。

## 自作スキル

- `dataviz` … 本リポジトリで作成。上流なし。
