# Bootstrap: install the security package into an existing repo

Instructions for a Claude Code session that has been asked to install this package into an existing project.

**Trigger:** the user says something like "install the security package", "arm this repo with the security workflows", "add our CISO setup to this project", or points you at this file's URL.

**Assume nothing:** the target repo may or may not have any of the files this package ships. Be idempotent and non-destructive.

## Rules for the install

1. **Never overwrite an existing file.** If a file already exists in the target repo, do not touch it — leave a note in the PR body about what was skipped and what the user should manually merge.
2. **Never merge the PR yourself.** Open it and hand off. This is a standing rule that applies to every session.
3. **Never commit directly to `main`/`master`.** Always work on a feature branch (recommended: `claude/security-bootstrap-<random-suffix>`).
4. **Never delete anything.** Additive only.
5. **Report what happened.** At the end, write a clear summary of what was added, what was skipped and why, and what the user needs to do manually.

## Step-by-step

### 1. Orient

Run these first, in parallel:

```
git status
git log --oneline -5
git branch --show-current
ls -la .github/ 2>/dev/null
ls -la .github/workflows/ 2>/dev/null
```

Look for signs of existing security infrastructure:
- `.github/workflows/security-audit.yml` (or similarly-named)
- `.github/dependabot.yml`
- `CLAUDE.md`
- A `docs/` folder that might have overlapping doc names

### 2. Detect languages

Check which of these manifests exist and note them:
- Python: `requirements.txt`, `pyproject.toml`, `Pipfile`, `setup.py`
- Node/JS/TS: `package.json`
- Go: `go.mod`
- Rust: `Cargo.toml`

Also identify the source directories (usually `src/`, `lib/`, `app/`, `scripts/`, or a language-specific name).

### 3. Fetch this template

Use `git clone` or `curl`/`gh` to fetch the current version of the security-review-starter template. Options:

```
# If gh is available and the template repo is accessible:
gh repo clone Joshua-Hsu/security-review-starter /tmp/security-starter --depth 1

# Or via curl-tarball:
mkdir -p /tmp/security-starter
curl -sSL https://github.com/Joshua-Hsu/security-review-starter/archive/refs/heads/main.tar.gz | \
  tar -xz -C /tmp/security-starter --strip-components=1
```

If neither works (network blocked, private repo without access), stop and tell the user — do not fabricate the files.

### 4. Create the branch

```
git checkout -b claude/security-bootstrap-$(head -c 5 /dev/urandom | base32 | tr '[:upper:]' '[:lower:]' | head -c 5)
```

### 5. Copy files, respecting existing state

For each file in the template, install with these rules:

| Template file | Rule |
|---|---|
| `CLAUDE.md` | If target has CLAUDE.md, **append** our CISO section under `<!-- security-review-starter:begin -->` / `<!-- security-review-starter:end -->` markers. Idempotent — check for the begin marker first and skip if present. If target has NO CLAUDE.md, copy ours in full. |
| `docs/standing-rules.md` | Same rule — copy only if absent. |
| `docs/ciso-operating-plan.md` | Same. |
| `docs/review-methodology.md` | Same. |
| `docs/roadmap-methodology.md` | Same. |
| `docs/roadmap.md` | Copy only if absent. If it exists, do NOT touch — it may have project-specific content. |
| `.github/workflows/security-audit.yml` | If a file with the same name exists, install ours as `security-audit-NEW.yml` and note the collision in the PR. |
| `.github/workflows/security-audit-weekly-report.yml` | Same collision rule. |
| `.github/dependabot.yml` | If exists, do NOT overwrite. Instead, leave both files' contents in the PR body so the user can manually merge entries. |
| `.github/pull_request_template.md` | If exists, do NOT overwrite. Copy ours to `docs/pull_request_template.example.md` and note. |
| `docs/BOOTSTRAP-EXISTING.md` | Copy only if absent — leaves a self-serve reference in the target repo for future re-installs. |
| `SETUP.md` | If exists, copy ours to `SETUP-SECURITY.md`. |

Files the install NEVER touches:
- `README.md` — project-owned
- Any existing source code (`src/`, `lib/`, `app/`, etc.)
- Existing test files

### 6. Adapt the audit workflow to the target's languages and source dirs

Read `.github/workflows/security-audit.yml` in the new location. Two edits are needed:

**a. The partial-value-prints grep**: it defaults to scanning `src/ lib/ app/ scripts/ scraper/`. Edit that path list to match the target repo's actual source directories.

**b. The Bandit step**: it iterates over the same directories. Same edit.

If any of the default directories don't exist in the target, leaving them in the list is safe (the grep silently ignores missing paths) but noisy. Trim for clarity.

### 7. Verify locally before pushing

```
# YAML parses
python -c "import yaml; yaml.safe_load(open('.github/workflows/security-audit.yml'))"
python -c "import yaml; yaml.safe_load(open('.github/dependabot.yml'))"

# The custom grep checks pass (they should, since we haven't changed anything yet)
grep -rnE "^\s*pull_request_target:" .github/workflows/ && echo "FAIL" || echo "OK"
```

### 8. Commit and open the PR

```
git add .github/ docs/ CLAUDE.md SETUP-SECURITY.md 2>/dev/null
git commit -m "Bootstrap security package (audit + Slack digest + Dependabot + docs)"
git push -u origin HEAD
```

Then open a PR with a body like:

```
## Summary

Installed the security-review-starter package into this repository.

## What was added

- .github/workflows/security-audit.yml — daily + PR audit
- .github/workflows/security-audit-weekly-report.yml — Monday Slack digest
- .github/dependabot.yml — grouped weekly updates
- .github/pull_request_template.md
- CLAUDE.md — auto-load CISO + reviewer role
- docs/standing-rules.md
- docs/ciso-operating-plan.md
- docs/review-methodology.md
- docs/roadmap-methodology.md
- docs/roadmap.md — starts empty, populate as work happens
- SETUP.md (or SETUP-SECURITY.md if a SETUP.md already existed)

## What was SKIPPED (needs your manual attention)

[List every file that already existed. For each, explain what the user should do.]

## What the user needs to do next

1. Follow SETUP.md steps 1-3 (Slack webhook + SLACK_SECURITY_WEBHOOK_URL secret + enable Dependabot toggles)
2. Trigger 'Audit - Security' manually to verify the first run passes
3. Review the roadmap doc and add project-specific items
```

### 9. Do NOT merge

Standing rule. Ask the user to review and merge when ready.

## Things to avoid

- Do not run `git push --force`
- Do not modify any existing source code
- Do not modify existing workflows to add the security-audit as a required check — that's a branch protection decision, and the user should make it
- Do not change the target repo's default branch name — read whatever `git symbolic-ref refs/remotes/origin/HEAD` returns and use that in the workflow `pull_request:` trigger
- Do not add or reference `SLACK_SECURITY_WEBHOOK_URL` in test files or examples — it's a real secret name, not a fixture

## After the PR is open

The audit will run on the PR itself (assuming the target repo's default branch is `main` or `master`, which we default to). If it turns red, investigate the specific failing step — most likely causes on a first install:

- gitleaks finds a real committed secret in the target's history → tell the user immediately, do not merge
- `.env` file already committed → same, coordinate with user
- Existing tests intentionally include suspicious-looking values that Bandit flags → suggest a Bandit config exclusion, don't silently ignore

If it goes green, you've successfully bootstrapped. The user handles Slack setup and merge from here.
