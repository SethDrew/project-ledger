# Project Ledger

A human-in-the-loop system for tracking findings, constraints, and insights during AI-assisted development — with automatic context injection so the right entries surface at the right time.

## The problem

AI coding agents struggle to frame their work in the broader context of the systems they operate in. They treat implementation details and bugs that point to architectural flaws with equal weight. They log what they changed, not what they learned. The fix goes in the commit, but the constraint it revealed — the design assumption it invalidated — that context just evaporates.

Tools like memory and CLAUDE.md help with persistence, but they don't solve the judgment problem. The agent still can't tell the difference between a one-off fix and a finding that should shape every future conversation. And it won't go read your reference docs unprompted to find out.

## How it works

Project Ledger is three things working together:

1. **A YAML ledger** — structured entries with id, date, status, confidence, tags, cross-references, and notes. Not a knowledge base or wiki — a curated log of specific findings.

2. **A `/ledger` skill** — a Claude Code slash command that publishes entries to the right ledger, checks for duplicates, and spawns an independent auditor (using Haiku) to review entries cold.

3. **A context hook** — a `UserPromptSubmit` hook that runs TF-IDF semantic search against your ledger on every prompt. Relevant entries get injected automatically. No manual lookup needed.

The key insight: **agents don't go read your docs on their own.** The hook closes that loop — when your prompt touches a topic you've investigated before, the hook finds the relevant ledger entries and injects them before the agent even starts thinking.

## When to use this

- Research projects where insights are hard-won and easily forgotten
- Hardware/embedded projects with physical constraints that keep biting you
- Any project where you're building institutional knowledge across many conversations
- Small-to-medium codebases where a full knowledge management system is overkill

This is simpler than production knowledge-base systems. No database, no server — just a YAML file, a skill, and a hook.

## Quick start

### 1. Copy the skill

Copy `SKILL.md` to your Claude Code skills directory:

```bash
mkdir -p .claude/skills/ledger
cp SKILL.md .claude/skills/ledger/SKILL.md
```

### 2. Set up the ledger guide

Copy the template and customize it for your project:

```bash
cp LEDGER_GUIDE_TEMPLATE.md docs/LEDGER_GUIDE.md
```

Edit `docs/LEDGER_GUIDE.md` to define what belongs in YOUR ledger. The template has sensible defaults — adjust the "what to log" section for your domain.

### 3. Create your first ledger

```bash
touch docs/ledger.yaml
```

Or use `/ledger "your first finding"` — the skill will create the file if it doesn't exist.

### 4. Set up context injection (optional but recommended)

This is the part that makes the ledger actually useful — automatic injection of relevant entries on every prompt.

a. Copy the hook and search script:
```bash
mkdir -p .claude/hooks tools
cp hooks/inject-ledger-context.sh .claude/hooks/
cp hooks/search_ledger.py tools/
chmod +x .claude/hooks/inject-ledger-context.sh
```

b. Edit `tools/search_ledger.py` — update `LEDGER_PATH` to point to your ledger file.

c. The search script needs `pyyaml` and `scikit-learn`. Set up a venv:
```bash
python3 -m venv venv
source venv/bin/activate
pip install pyyaml scikit-learn
```

d. Edit `.claude/hooks/inject-ledger-context.sh` — update `VENV_PYTHON` and `SEARCH_SCRIPT` paths.

e. Register the hook in `.claude/settings.local.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/inject-ledger-context.sh"
          }
        ]
      }
    ]
  }
}
```

## Entry format

```yaml
entries:
  - id: kebab-case-unique-id
    date: 2026-03-22
    touched: 2026-03-22
    title: Short descriptive title
    summary: >
      1-3 sentences. The core finding. Be specific — include
      numbers, comparisons, or the key constraint.
    status: validated
    confidence: high
    source: []
    tags: [relevant, tags]
    relates_to: [other-entry-ids]
    notes: >
      Why this matters. What it connects to. What's unresolved.
```

### Status vocabulary

| Status | Meaning |
|--------|---------|
| `spark` | Just an idea, untested |
| `exploring` | Actively investigating |
| `validated` | Technically confirmed |
| `integrated` | Built into the codebase |
| `dormant` | Parked — hasn't found its place yet |
| `superseded` | Better approach exists |

### Extending the schema

The base schema uses `confidence` (low/medium/high). Add domain-specific fields as needed:

- **Hardware projects:** Add `severity` (high/medium/low) and `scope` (hardware/electrical/protocol)
- **Creative/research projects:** Add `warmth` (high/medium/low) for artistic/intuitive pull — independent of technical confidence
- **Data projects:** Add `impact` (high/medium/low) for downstream effect

## How the audit works

When you publish via `/ledger`, the skill automatically spawns a Haiku-powered auditor that reviews your new entries "cold" — with no context from the conversation that produced them. It checks:

- Format compliance (required fields, valid status values, unique IDs)
- Content specificity (is the summary vague or precise?)
- Deduplication (should this update an existing entry instead?)
- Cross-reference validity (do `relates_to` IDs actually exist?)

The auditor reports PASS, MINOR ISSUES, or NEEDS REVISION with specific feedback.

## How context injection works

The hook fires on every `UserPromptSubmit`. It:

1. Extracts your prompt text
2. Skips short follow-ups (<25 words) unless they contain implementation keywords
3. Runs TF-IDF cosine similarity against all ledger entries
4. Boosts scores for high-confidence and validated entries
5. Injects the top 5 matches as context before the agent sees your prompt

The search builds a cached index (rebuilds automatically when the ledger file changes), so it adds negligible latency.

## Linking to architecture documents

If your project has architecture docs, design documents, or reference material, you can link the ledger to them so that relevant docs surface alongside matching entries. The search script supports an optional keyword-to-document mapping — when a prompt matches certain patterns, it suggests the relevant doc by name.

Example mapping (add to `search_ledger.py`):

```python
REFERENCE_DOCS = {
    "API_DESIGN.md": (
        r"endpoint|route|request|response|auth|rate.?limit",
        "API conventions, authentication, rate limiting",
    ),
    "DATA_MODEL.md": (
        r"schema|migration|index|query|join|foreign.?key",
        "database schema, migrations, query patterns",
    ),
}
```

**Use filenames only, never paths.** This is important. Architecture docs get moved, directories get restructured, and hardcoded paths go stale silently. When the search script outputs `API_DESIGN.md`, the agent uses Glob to find it wherever it currently lives. A filename is resilient to refactoring. A path like `docs/architecture/api/API_DESIGN.md` breaks the first time someone reorganizes the repo.

The same applies to `source:` fields in ledger entries. Use relative paths if you need them, but prefer filenames or short references that the agent can locate dynamically. The more brittle the reference, the less useful it becomes over time.

Linking is optional — the ledger works fine without it. But if you have architecture docs that you want the agent to consult alongside ledger findings, this is how to connect them.

## Tips

- **Quality in, quality out.** Vague entries produce vague matches. The more specific your summary — with numbers, thresholds, and root causes — the better TF-IDF will match it to relevant future prompts. Entries that describe what you learned, not just what you fixed, are the ones that compound.
- **The skill won't write perfect entries on its own.** Review what it publishes. Edit summaries to be more specific. The audit catches format issues but can't judge domain accuracy.
- **Use `relates_to` generously.** Cross-references build a graph of connected insights that surface together.
- **Prune regularly.** Mark superseded entries. Update touched dates. A stale ledger is worse than no ledger.
- **Start small.** You don't need 100 entries on day one. Log findings as they come up naturally.

## Examples

See the `examples/` directory for a sample ledger with realistic entries.

## License

MIT
