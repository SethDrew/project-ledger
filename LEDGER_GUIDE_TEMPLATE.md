# Ledger Guide

The ledger (`docs/ledger.yaml`) is the permanent record of findings, constraints,
and insights for this project. It tracks **how you think about the problem** — not
what you built.

**Log these:**
- Findings with specifics: "Retry logic fails after 3 attempts because the backoff exceeds the timeout"
- Dead ends with reasoning: "Connection pooling doesn't help here because each request needs fresh auth"
- Constraints that affect design: "The API rate-limits at 100 req/min, so batch processing must chunk"
- Hypotheses worth revisiting: "Caching at the gateway layer might eliminate 60% of redundant calls"
- Connections between ideas: "The pagination bug and the timeout issue share a root cause"

**Don't log these:**
- Bug fixes: "Fixed null pointer in handler"
- UI changes: "Moved button to the sidebar"
- Refactors: "Extracted helper function"
- Feature additions: "Added CSV export endpoint"
- Implementation details: "New endpoint at /api/v2/reports"

**Rule of thumb:** If it changes how you *think* — log it. If it's what you *did* to the code — git.

## Entry Format

```yaml
- id: kebab-case-unique-id
  date: 2026-03-22           # when first explored
  touched: 2026-03-22        # when last revisited
  title: Short descriptive title
  summary: >
    1-3 sentences. The core finding or idea.
  status: validated           # see vocabulary below
  confidence: high            # technical certainty: high | medium | low
  source: path/to/evidence    # file path(s), or [] if none
  tags: [relevant, tags]
  relates_to: [other-entry-ids]
  notes: >
    Narrative context, caveats, what's unresolved.
    Why it matters. What it connects to.
```

## Status Vocabulary

| Status | Meaning |
|--------|---------|
| `spark` | Just an idea, untested |
| `exploring` | Actively investigating |
| `validated` | Technically confirmed to work |
| `integrated` | Built into the codebase/workflow |
| `dormant` | Parked — hasn't found its place yet |
| `superseded` | Better approach exists (but might return) |

## Adding Entries

Edit `docs/ledger.yaml` directly. Append to the `entries:` list.

Before adding, check: is this **new**, should it **update** an existing entry, or is it a
**duplicate**?

To UPDATE an existing entry, edit it in place — change the `touched` date and whatever
fields changed. Add a line to `notes` explaining what changed and why.

## Extending the Schema

The base schema uses `confidence` (low/medium/high). Add domain-specific fields as needed:

- **Creative/research projects:** Add `warmth` (high/medium/low) for artistic/intuitive pull
- **Hardware projects:** Add `severity` (high/medium/low) and `scope` (hardware/electrical/protocol)
- **Data projects:** Add `impact` (high/medium/low) for downstream effect

Define any new fields in this guide so the `/ledger` skill and auditor know about them.

## Searching

```
Grep pattern="timeout" path="docs/ledger.yaml"
Grep pattern="dormant" path="docs/ledger.yaml"
Grep pattern="tags:.*performance" path="docs/ledger.yaml"
```
