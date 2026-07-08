#!/usr/bin/env bash
# install.sh — Install the security-review-starter into an existing repo.
#
# Idempotent, non-destructive: skips any file that already exists.
# Reports skips at the end so you can decide whether to merge manually.
#
# Usage (from inside the target repo's root):
#
#   curl -sSL https://raw.githubusercontent.com/Joshua-Hsu/security-review-starter/main/install.sh | bash
#
# Or download and inspect first (recommended for anything not your own):
#
#   curl -sSL https://raw.githubusercontent.com/Joshua-Hsu/security-review-starter/main/install.sh -o /tmp/security-install.sh
#   less /tmp/security-install.sh
#   bash /tmp/security-install.sh

set -euo pipefail

TEMPLATE_REPO="${SECURITY_STARTER_REPO:-Joshua-Hsu/security-review-starter}"
TEMPLATE_REF="${SECURITY_STARTER_REF:-main}"
BRANCH_PREFIX="${SECURITY_STARTER_BRANCH_PREFIX:-claude/security-bootstrap}"

# Sanity: are we in a git repo?
if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: not inside a git repository. cd into your project root first." >&2
  exit 1
fi

# Operate from repo root so relative paths are stable regardless of where the user invoked us.
cd "$REPO_ROOT"

# Detect the default branch name so PR-flow hints at the end use the right target.
# Order of fallbacks: origin/HEAD symref → local main → local master → 'main' as last resort.
DEFAULT_BRANCH="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
if [ -z "$DEFAULT_BRANCH" ]; then
  if git show-ref --verify --quiet refs/heads/main; then DEFAULT_BRANCH=main
  elif git show-ref --verify --quiet refs/heads/master; then DEFAULT_BRANCH=master
  else DEFAULT_BRANCH=main
  fi
fi

# Sanity: is the working tree clean? (We don't want to mix our changes with in-progress work.)
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is not clean. Commit or stash your changes first." >&2
  echo "" >&2
  git status --short >&2
  exit 1
fi

# Fetch the template into a temp dir
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Fetching template ${TEMPLATE_REPO}@${TEMPLATE_REF} ..."
curl -sSfL "https://github.com/${TEMPLATE_REPO}/archive/refs/heads/${TEMPLATE_REF}.tar.gz" \
  | tar -xz -C "$TMP" --strip-components=1

# Create a fresh branch
suffix="$(head -c 5 /dev/urandom | base32 | tr '[:upper:]' '[:lower:]' | head -c 5)"
branch="${BRANCH_PREFIX}-${suffix}"

echo "==> Creating branch ${branch} ..."
git checkout -b "$branch"

# Marker used for idempotent appends to shared files (CLAUDE.md). If the
# target file already contains this begin marker, we skip the append —
# that's what makes re-runs safe. The matching end marker lives inside
# the append_snippet_* functions.
BEGIN_MARKER="<!-- security-review-starter:begin -->"

# Files we install. Rules:
#   copy_if_absent:   copy only when target doesn't exist
#   copy_as_alt:      if target exists, copy the template file under a different name
#   copy_or_append:   if target exists, append our snippet between markers (idempotent)
#
# Format: "<template_path>|<rule>|<alt_target_path (optional)>"
FILES=(
  "CLAUDE.md|copy_or_append"
  "SETUP.md|copy_as_alt|SETUP-SECURITY.md"
  ".github/workflows/security-audit.yml|copy_as_alt|.github/workflows/security-audit-NEW.yml"
  ".github/workflows/security-audit-weekly-report.yml|copy_as_alt|.github/workflows/security-audit-weekly-report-NEW.yml"
  ".github/dependabot.yml|copy_if_absent"
  ".github/pull_request_template.md|copy_if_absent"
  "docs/standing-rules.md|copy_if_absent"
  "docs/ciso-operating-plan.md|copy_if_absent"
  "docs/review-methodology.md|copy_if_absent"
  "docs/roadmap-methodology.md|copy_if_absent"
  "docs/roadmap.md|copy_if_absent"
  "docs/BOOTSTRAP-EXISTING.md|copy_if_absent"
)

# The snippet appended to an existing CLAUDE.md (Flow: copy_or_append).
# Kept small and inert — points at the real docs rather than duplicating them.
append_snippet_claude() {
  cat <<'SNIPPET'


<!-- security-review-starter:begin -->

## Security & code-review session context

You are also the CISO and code reviewer for this repository. Read these before doing anything else:

- [docs/standing-rules.md](docs/standing-rules.md) — non-negotiables (never merge without permission, etc.)
- [docs/ciso-operating-plan.md](docs/ciso-operating-plan.md) — role, triggers, rituals
- [docs/review-methodology.md](docs/review-methodology.md) — how to review PRs, verdict format
- [docs/roadmap.md](docs/roadmap.md) — current security state for this project

Standing rule that overrides everything else in this file: never merge a PR without explicit user permission.

<!-- security-review-starter:end -->
SNIPPET
}

added=()
skipped=()

for entry in "${FILES[@]}"; do
  IFS='|' read -r src rule alt <<<"$entry"
  target="$src"
  src_full="${TMP}/${src}"

  if [ ! -f "$src_full" ]; then
    echo "  (template file missing: ${src} — skipping)"
    continue
  fi

  if [ ! -e "$target" ]; then
    mkdir -p "$(dirname "$target")"
    cp "$src_full" "$target"
    added+=("$target")
    echo "  + $target"
    continue
  fi

  case "$rule" in
    copy_if_absent)
      skipped+=("$target (already exists — not touched)")
      echo "  ! $target already exists — skipped"
      ;;
    copy_as_alt)
      if [ -e "$alt" ]; then
        skipped+=("$alt (both original and alt exist — resolve manually)")
        echo "  ! $target AND $alt both exist — skipped"
      else
        mkdir -p "$(dirname "$alt")"
        cp "$src_full" "$alt"
        added+=("$alt (installed as alt because $target exists)")
        echo "  + $alt (installed as alt because $target exists)"
      fi
      ;;
    copy_or_append)
      # Idempotent: if our BEGIN_MARKER is already in the file, don't append again.
      if grep -qF "$BEGIN_MARKER" "$target"; then
        skipped+=("$target (marker already present — no change needed)")
        echo "  = $target already has our marker — skipped"
      else
        # Only CLAUDE.md uses this rule today. Extend by dispatching on $target if more join.
        case "$target" in
          CLAUDE.md) append_snippet_claude >> "$target" ;;
          *)
            echo "  ! No append snippet defined for $target — skipped" >&2
            skipped+=("$target (no append snippet)")
            continue
            ;;
        esac
        added+=("$target (appended CISO section under marker)")
        echo "  ~ $target — appended CISO section under marker"
      fi
      ;;
  esac
done

if [ "${#added[@]}" -eq 0 ]; then
  echo ""
  echo "Nothing to add — everything is already in place. Removing branch."
  git checkout - >/dev/null
  git branch -D "$branch" >/dev/null
  exit 0
fi

git add -A
git commit -m "Bootstrap security package via install.sh

Installed ${#added[@]} file(s). Skipped ${#skipped[@]} that already existed."

echo ""
echo "================================================================"
echo "Bootstrap complete on branch: ${branch}"
echo "================================================================"
echo ""
echo "Added (${#added[@]}):"
for f in "${added[@]}"; do echo "  + $f"; done
if [ "${#skipped[@]}" -gt 0 ]; then
  echo ""
  echo "Skipped (${#skipped[@]}):"
  for f in "${skipped[@]}"; do echo "  ! $f"; done
  echo ""
  echo "Review the skipped files and decide whether to merge template content into your existing versions."
fi
echo ""
echo "Next steps:"
echo "  1. Review the changes:      git diff ${DEFAULT_BRANCH}..${branch}"
echo "  2. Push the branch:         git push -u origin ${branch}"
echo "  3. Open a PR from ${branch} → ${DEFAULT_BRANCH}"
echo "  4. Follow SETUP.md (or SETUP-SECURITY.md if renamed) for the Slack + Dependabot config"
echo ""
echo "This script did NOT push, open a PR, or merge. That's on you."
