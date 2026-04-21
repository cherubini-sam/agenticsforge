---
name: pull-request
description: "Full PR lifecycle: branch creation, commits, PR creation via gh CLI, review, and merge. Integrates with Law 40 branch isolation. Use when creating PRs, writing PR descriptions, or managing the merge workflow."
---

# Pull Request Lifecycle

Integrates directly with the protocol's Law 40 branch isolation model.

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
