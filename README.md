# Project Ledger

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-orange.svg)](https://docs.anthropic.com/en/docs/claude-code)

Memory helps agents remember things. **The problem is that agents can't judge what matters.** They often treat implementation bugs the same as architectural flaws. They log what they changed, not what's important. As AI agents continue to operate in our codebases, they take on debt — each change gets a little bit harder to get right.

Project Ledger is a system where the human decides how the system builds its memory. Try it out, and if you don't like it, you'll at least have a record you can port back into your existing memory system.

## What's in the box

1. **A YAML ledger** — structured entries with summaries, confidence, tags, cross-references
2. **A `/ledger` skill** — publishes entries and auto-spawns a Haiku auditor to review them cold
3. **A UserPromptSubmit hook** — runs TF-IDF search on every prompt, injects matching entries automatically

The hook is what makes it work. Without it, you're writing YAML into the void. Agents never go read reference docs unprompted — the hook runs on every prompt, searches the ledger, and injects relevant entries before the agent starts thinking.

For example, weeks after fixing a color rendering issue on an embedded project, I told an agent "remember what we did where we fixed this before." The hook surfaced the exact entry about 8-bit quantization crushing color fidelity at low values — root cause, thresholds, affected components, all there. That only worked because we'd logged the finding, not just the fix.

## Project structure

```
project-ledger/
├── SKILL.md                    # The /ledger skill — copy into .claude/skills/ledger/
├── LEDGER_GUIDE_TEMPLATE.md    # Template for defining what belongs in your ledger
├── hooks/
│   ├── inject-ledger-context.sh  # UserPromptSubmit hook
│   └── search_ledger.py          # TF-IDF search script
└── examples/
    └── ledger.yaml               # Sample entries from a real project
```

## Quick start

### Clone and copy

```bash
git clone https://github.com/SethDrew/project-ledger.git
cd project-ledger
```

Then copy the pieces into your project:

```bash
# 1. Install the skill
mkdir -p .claude/skills/ledger
cp SKILL.md .claude/skills/ledger/SKILL.md

# 2. Set up the ledger guide
cp LEDGER_GUIDE_TEMPLATE.md docs/LEDGER_GUIDE.md

# 3. Create your first ledger
touch docs/ledger.yaml
```

Or just use `/ledger "your first finding"` — the skill creates the file if it doesn't exist.

Edit `docs/LEDGER_GUIDE.md` to define what belongs in your ledger. The template has sensible defaults — adjust for your domain.

### Set up context injection (optional but recommended)

This is the part that makes the ledger actually useful.

a. Copy the hook and search script:
```bash
mkdir -p .claude/hooks tools
cp hooks/inject-ledger-context.sh .claude/hooks/
cp hooks/search_ledger.py tools/
chmod +x .claude/hooks/inject-ledger-context.sh
```

b. Edit `tools/search_ledger.py` — update `LEDGER_PATH` to point to your ledger file.

c. Install dependencies in a venv:
```bash
python3 -m venv venv
source venv/bin/activate
pip install pyyaml scikit-learn
```

d. Edit `.claude/hooks/inject-ledger-context.sh` — verify `VENV_PYTHON` and `SEARCH_SCRIPT` paths match your setup.

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

- **Hardware projects:** Add `severity` and `scope` (hardware/electrical/protocol)
- **Creative/research projects:** Add `warmth` for artistic/intuitive pull — independent of technical confidence
- **Data projects:** Add `impact` for downstream effect

## How it works

**The `/ledger` skill** publishes entries and optionally spawns a Haiku-powered auditor that reviews them cold — no context from the conversation that produced them. It checks format compliance, content specificity, deduplication, and cross-reference validity.

**The context injection hook** fires on every `UserPromptSubmit`:

1. Extracts your prompt text
2. Skips short follow-ups (<25 words) unless they contain implementation keywords
3. Runs TF-IDF cosine similarity against all ledger entries
4. Boosts scores for high-confidence and validated entries
5. Injects the top 5 matches as context before the agent sees your prompt

The search builds a cached index that rebuilds automatically when the ledger changes.

<details>
<summary><strong>Linking to architecture documents</strong></summary>

You can optionally map keywords to architecture doc filenames so they surface alongside matching ledger entries:

```python
REFERENCE_DOCS = {
    "API_DESIGN.md": (
        r"endpoint|route|request|response|auth|rate.?limit",
        "API conventions, authentication, rate limiting",
    ),
}
```

**Use filenames only, never paths.** Architecture docs get moved, directories get restructured, and hardcoded paths go stale silently. A filename is resilient to refactoring — the agent can Glob for it wherever it lives.

</details>

## Tips

- **Log what you learned, not what you changed.** The fix goes in the commit. The finding goes in the ledger.
- **Be specific.** Vague entries produce vague matches. Numbers, thresholds, and root causes are what make TF-IDF match the right entries months later.
- **Review what the skill writes.** It won't write perfect entries on its own. The audit catches format issues but can't judge domain accuracy.
- **Use `relates_to` generously.** Cross-references build a graph of connected insights that surface together.
- **Start small.** Log findings as they come up naturally. You don't need 100 entries on day one.

## Examples

The [`examples/`](examples/) directory has entries from a real project — audio-reactive LED art — showing how specific, well-framed entries look in practice. Entries cover feature extraction insights, algorithm selection rationale, and hardware constraints.

## License

MIT
