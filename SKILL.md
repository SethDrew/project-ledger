---
name: ledger
description: Publish a finding to the project ledger, then spawn an independent audit
argument-hint: "what to publish, e.g. retry logic fails after 3 attempts"
allowed-tools: Read, Edit, Write, Grep, Glob, Task
---

# Ledger Publish + Audit

You are publishing entries to a project ledger, then spawning an independent auditor.

## Phase 0: Discover the Ledger

Find the project's ledger file(s) and guide(s). Search in order:

1. **Look for a guide first:** `Glob pattern="**/LEDGER_GUIDE.md"` — if found, read it. It defines the format, sections, and entry schema.
2. **Look for ledger files:** `Glob pattern="**/*ledger*.yaml"` then `Glob pattern="**/*ledger*.md"` (exclude node_modules, .git, venv).
3. **Check for multiple ledgers:** Some projects split into domains (research/engineering, etc). If multiple ledgers exist, read their guides to decide which one(s) the finding belongs in.
4. **If no ledger exists yet:** Ask the user where to create one. Default to `docs/ledger.yaml`. Create both a `LEDGER_GUIDE.md` and the ledger file.

**Format detection:** The ledger can be YAML or Markdown. Read the existing file to match the format exactly.

## Phase 1: Publish

The user said: **$ARGUMENTS**

### Rules

1. **Read the guide first** (if one exists). Understand the entry format, status vocabulary, and section organization.

2. **Read the existing ledger.** Check for duplicates and find the right section.

3. **Scope control — this is critical:**
   - If the user named a specific concept or finding, publish ONLY that. Do not invent related entries.
   - If the user said something like "just publish findings" or "publish everything", then review the conversation history and publish all findings that qualify.
   - When in doubt, publish LESS, not more. The user can always ask for more.

4. **Before adding, decide:** Is this a NEW entry, should it UPDATE an existing entry (edit in place, bump `touched`), or is it a DUPLICATE (skip it)?

5. **Entry quality:**
   - `id`: kebab-case, unique, descriptive
   - `date`: the date the finding was first explored (use today if new)
   - `touched`: today's date
   - `summary`: 1-3 sentences, the core finding. Be specific — include numbers, comparisons, or the key insight.
   - `status`: use the vocabulary from the guide (or defaults: `spark`, `exploring`, `validated`, `integrated`, `dormant`, `superseded`)
   - `confidence`: `high`, `medium`, or `low` (add other rating fields like `impact` or `severity` if the project's guide defines them)
   - `relates_to`: link to existing entry IDs where relevant
   - `notes`: narrative context, caveats, what's unresolved

6. **Placement:** Add entries at the end of the entries list, or under the appropriate section if the ledger is organized.

7. **Report back:** After publishing, show the user exactly what you added or changed. Quote the entry.

## Phase 2: Audit (optional)

After the publish edit is complete, if the Task tool is available, spawn an audit agent using it with these exact parameters. If the Task tool is not available, skip this phase — the publish is still valid without it.
- `subagent_type`: `general-purpose`
- `model`: `haiku`
- `description`: `Audit newest ledger entries`
- `prompt`: Use the prompt below, filling in the LEDGER_PATH and GUIDE_PATH:

```
You are an independent auditor reviewing recent additions to a project ledger. You have NO context about the conversation that produced these entries — review them cold.

## Steps

1. Read the guide (if it exists): GUIDE_PATH

2. Read the ledger: LEDGER_PATH

3. Find the newest entries (most recent `date` or `touched` fields).

4. Audit each new entry:

   **Format**: All required fields present per the guide? Valid status values? Unique id?

   **Content**: Does the summary contain a specific finding (not vague)? Are rating fields honest? Does relates_to reference real entry IDs?

   **Dedup**: Is this genuinely new, or should it have updated an existing entry?

   **Value**: Will a future reader understand WHY this matters?

5. For each entry, report:
   - **Verdict**: PASS, MINOR ISSUES, or NEEDS REVISION
   - **Issues** (if any): be specific
   - **One suggestion** to improve the entry

Keep it concise. Actionable feedback only.
```

Then relay the audit results to the user.
