---
name: pull-request
description: "Full PR lifecycle: branch creation, commits, PR creation via gh CLI, review, and merge. Integrates with Law 40 branch isolation. Use when creating PRs, writing PR descriptions, or managing the merge workflow."
when_to_use: "When creating a new pull request, writing a PR description, managing the branch-to-merge lifecycle, running gh CLI commands, or applying Law 40 branch isolation to a completed feature."
allowed-tools: [Bash]
---

# Pull Request Lifecycle

Integrates directly with the protocol's Law 40 branch isolation model.

## Foundations

- **Short-lived branches outperform long-lived ones.** Trunk-Based Development and DORA *Accelerate* both find elite teams merge to trunk multiple times per day, with branches living hours not weeks. Long-lived branches accumulate merge debt and shrink the window in which CI feedback is actionable.
- **Pick one workflow and stay in it.** GitFlow suits versioned product releases with parallel maintenance lines. GitHub Flow / Trunk-Based suits continuously deployed services. Mixing produces the worst of both.
- **The PR is a unit of review, not a unit of work.** ~200–400 changed lines is the empirical sweet spot for review effectiveness. Large PRs are a process smell, not a constraint to respect.
- **Branch isolation is mechanical.** Law 40 forbids agent writes to `main`/`master`; the destructive-guard hook enforces it. Promotion to main is a human-only operation.

## PR Velocity

- **Merge queues** — GitHub merge queue, Mergify, Aviator. Serialise merges, re-run required checks against the post-merge tree, prevent the "green-PR-red-main" race common with parallel merges.
- **Stacked PRs** — Graphite, Sapling (Meta), `git absorb`, `spr`. One feature broken into a chain of 3–7 small dependent PRs; each reviewed independently; merge in stack order. Replaces the 2K-line "everything PR" anti-pattern.
- **Release automation** — Changesets (Node monorepos), `release-please` (Google, multi-language), `semantic-release`. Conventional commits drive auto-generated CHANGELOG + version bump + tag at merge time.
- **Branch protection rules** — require PR, require linear history, require ≥1 review, require status checks (CI green + merge-queue clean), required signed commits for production branches.
- **AI-generated summaries** — acceptable as a first draft; never as the final body. The author still owns the "why" — diffs show the "what."

## Branch → PR → Merge Flow

```
git checkout master
git checkout -b {operation}/{slug}   ← Law 40 Step 0
[commits on operation branch]
git push -u origin {operation}/{slug}
gh pr create ...
[review + approval]
git checkout master && git merge --no-ff {operation}/{slug}
```

## PR Creation

```bash
gh pr create \
  --title "<type>: <short description under 70 chars>" \
  --body "$(cat <<'EOF'
## Summary
- [bullet 1]
- [bullet 2]

## Test plan
- [ ] Unit tests pass
- [ ] Integration tests pass (if applicable)
- [ ] Manual golden path verified
EOF
)"
```

## Title Conventions

- Prefix: `feat` | `fix` | `refactor` | `docs` | `chore` | `test` | `perf` | `ci` | `build` | `style`
- Max 70 characters total
- No parenthesised scope — ZERO `(` or `)` in subject (commit-msg hook enforced)
- Capital letter after colon: `feat: Add login flow.`
- Trailing period REQUIRED

## Body Template

```markdown
## Summary
- What changed and why (not how — the diff shows how)
- Motivation or ticket reference if applicable

## Test plan
- [ ] Describe what was tested and how
- [ ] Edge cases covered
- [ ] Regression check on adjacent features
```

## Merge Strategy

For this protocol system, always use `--no-ff` to preserve branch history:

```bash
git merge --no-ff {operation}/{slug} -m "chore: Merge {operation}/{slug} into master with <summary>."
```

**HUMAN-ONLY**: Agents never execute the merge. The protocol emits this block at Phase 6 for manual execution.

## Post-Merge Cleanup

```bash
git branch -d {operation}/{slug}
git push origin --delete {operation}/{slug}
```

## gh CLI Reference

| Command | Purpose |
|---------|---------|
| `gh pr create` | Open PR from current branch |
| `gh pr view` | Show PR details |
| `gh pr list` | List open PRs |
| `gh pr checks` | Show CI status |
| `gh pr merge --no-ff` | Merge (human only) |
| `gh pr close` | Close without merging |

## Source

Forsgren et al., Accelerate, 2018; DORA, State of DevOps Report, 2024.
