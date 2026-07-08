# Standing rules — non-negotiable

These rules apply to every Claude session working in this repository. They are not defaults, opinions, or suggestions. Never break them without explicit user permission — and even then, log why in the PR description.

## 1. Never merge a PR without explicit user permission

- Green audit ≠ permission to merge
- "Should we merge?" ≠ "merge it" — always wait for a direct "yes" / "merge" / "go ahead"
- If you opened the PR yourself, still ask
- If a Dependabot PR opens overnight, still ask
- If the user has said "you can merge X, Y, Z from now on" — that is durable authorization for those specific items; ask if you're not sure whether a new PR falls in scope

## 2. Never push directly to master

- All changes go through feature branches and PRs
- Even one-line hotfixes go through a PR
- Exception: never, without explicit written user request

## 3. Never force-push master

- No `git push --force`, `--force-with-lease`, or any equivalent
- No `git reset --hard <old-sha>` followed by any push to master
- Force-pushing feature branches is fine when it makes sense (e.g., rewinding session work), but master is off-limits

## 4. Never include a secret value anywhere Claude writes

Applies to:
- Source code (including string literals, config files, tests)
- Comments in code
- Commit messages
- PR titles and bodies
- Issue comments
- Log lines (`print`, `log.info`, etc.) — including PARTIAL slices like `token[:8]` (GitHub Actions only masks exact secret matches)
- Shell `echo` inside workflow steps
- Anything written to `data/`, artifacts, or output files

**Safe:** the *name* of an env var (`SLACK_WEBHOOK_URL not set; skipping`).
**Unsafe:** the *value* of an env var (never print, log, or write it in any form).

## 5. Never silence a failing security check

If a check fails:
- Investigate the underlying finding
- Fix the actual issue (bump a dep, tighten a permission, remove a leaked value)
- If you're uncertain whether it's a real problem, ask the user
- Never add an ignore / whitelist / skip flag as your first move

## 6. Rotate credentials only with cause

- Confirmed leak (in logs, in git history, in a screenshot)
- Third party has disclosed suspected compromise
- A team member with access has left
- The user explicitly requests rotation
- Never rotate as ritual — it's operational friction with no marginal benefit unless one of the above is true

## 7. Ask before any destructive operation

Includes but not limited to:
- `git reset --hard`, `git checkout .`, `git restore .`, `git clean -f`
- `git branch -D` on any branch
- `rm -rf`
- Database `DROP TABLE`, `TRUNCATE`, mass `DELETE`
- Revoking API keys or GitHub tokens
- Force-pushing anywhere
- Deleting workflow runs, artifacts, or logs
- Disabling a security check

## 8. Never disable a hook or bypass signing without explicit request

- No `--no-verify` on `git commit` or `git push`
- No `--no-gpg-sign` / `-c commit.gpgsign=false`
- If a pre-commit hook fails, investigate and fix the underlying issue

## 9. Never take an action that has a shorter reversal path than "ask first"

Loose test: if reversing your action would take more than 30 seconds, ask first. This is a good default whenever you're unsure.

## 10. Log destructive-decision reasoning in the PR body

If the user authorizes a destructive action, describe:
- What you did
- Why the reversal path is acceptable
- What state exists after the action

This creates an audit trail for future sessions and future you.
