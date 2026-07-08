# Security + Code Review Starter

A GitHub template that gives a new (or existing) private repository:

- **Automated security auditing** on a daily schedule and on every PR
- **Weekly Slack digest** to a dedicated security channel
- **Auto-remediation** via Dependabot for stale deps and CVEs
- **Standing operational rules + review methodology** for any Claude Code session working in the repo

Multi-language: auto-detects Python, Node/JavaScript, and Go manifests and runs the appropriate scanner for each.

## What's in the box

```
.github/
├── workflows/
│   ├── security-audit.yml            # 7 language-agnostic + N language-specific checks
│   └── security-audit-weekly-report.yml
├── dependabot.yml                    # pip + npm + gomod + github-actions
└── pull_request_template.md
docs/
├── standing-rules.md                 # non-negotiables — read first
├── ciso-operating-plan.md            # security responsibilities & rituals
├── review-methodology.md             # how to review PRs, verdict format
└── roadmap-methodology.md            # Tier A / B / C prioritization
CLAUDE.md                             # auto-load session context
SETUP.md                              # one-time human setup steps
```

## Two ways to use it

### A. New project — GitHub template flow

1. Click **Use this template → Create a new repository** on GitHub.
2. Set the new repo to **private** (or public — your call).
3. Follow [SETUP.md](SETUP.md) for the one-time Slack + Secrets configuration (~5 minutes).
4. Any Claude Code session opening the repo will read `CLAUDE.md` and inherit the CISO + reviewer context.

### B. Existing project — install script

From inside the target repo's root, with a clean working tree:

```bash
curl -sSL https://raw.githubusercontent.com/Joshua-Hsu/security-review-starter/main/install.sh | bash
```

The script:
- Creates a fresh feature branch
- Copies each file only if the target doesn't already have it (never overwrites)
- Reports what was added and what was skipped
- Commits, but does NOT push or open a PR — that's yours to review

Alternative: check the script into `less` first if you're security-conscious about piping curl to bash — see [install.sh](install.sh) for the flags.

### C. Existing project — via a Claude Code session

Start a Claude Code session in the target repo. Paste this prompt:

> Install the security package. Follow the instructions at
> https://github.com/Joshua-Hsu/security-review-starter/blob/main/docs/BOOTSTRAP-EXISTING.md

The session will fetch the template, adapt the workflows to your repo's languages and source directories, and open a PR. It won't merge — standing rule.

## Security posture summary

| Layer | Frequency | Notification path |
|---|---|---|
| Full audit | Daily 01:00 UTC + on every PR to main/master | PR Checks UI + Slack ping on scheduled failures |
| Weekly digest | Monday 02:00 UTC | Dedicated Slack channel |
| Dependency freshness | Weekly Monday 03:00 UTC | Auto-PR grouped by ecosystem |
| CVE response | Immediate | Auto-PR the moment an advisory drops |

## Design philosophy

- **Fire on bad code, don't silence findings** — every check is a hard gate. Fix the underlying issue rather than adding suppressions.
- **Ask before merging** — the human is always in the loop for merges. Automation opens PRs; humans approve them.
- **Explicit standing rules** — non-negotiables are written down, not inferred. Sessions inherit them from `CLAUDE.md`.
- **Blast-radius framing** — every decision is evaluated by "if this breaks / leaks, what's the impact?"
- **Tier A / B / C roadmap** — improvements prioritized by value-per-effort. Long-lived credentials → OIDC is almost always the biggest single upgrade available.

## Adapting to your project

The workflows are designed to be dropped in unchanged for most projects. The two spots that commonly need small edits:

1. **Source directories for scanners** — the partial-value grep and Bandit steps scan `src/ lib/ app/ scripts/ scraper/`. Add or remove paths to match your layout.
2. **Base branch name** — the workflows target `main` and `master`. Adjust if your default branch is something else.

Everything else auto-detects language and adapts.

## Non-negotiables

Every Claude session working here reads [docs/standing-rules.md](docs/standing-rules.md) before doing anything. They should not be interpreted as advisory.
