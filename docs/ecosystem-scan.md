# Monthly security ecosystem scan — procedure

Standing procedure for the monthly qualitative security review. A Slack
reminder (from `security-ecosystem-reminder.yml`) fires on the 1st of each
month; the user starts a Claude session and pastes the trigger prompt. The
session then follows this document.

**Approval gate:** this scan only ever runs when the user explicitly starts
it. No automation launches it. If you are a Claude session reading this
without the user having asked for the scan in this conversation, stop.

## Scope

Complementary to (not duplicating) the automated checks:

| Already automated — do NOT redo | This scan — qualitative, needs judgment |
|---|---|
| Scanner version drift (`security-tool-currency.yml`) | New tools worth adopting; existing tools deprecated/abandoned |
| Dependency CVEs (pip-audit, OSV, Dependabot) | New *classes* of attack the checks don't cover |
| Committed secrets (gitleaks) | Changes to GitHub's security feature set / pricing |
| Workflow misconfig (actionlint + greps) | Best-practice evolution (e.g. new hardening guidance) |

## Procedure

1. **Web-search sweep** (~4 searches, adjust as sensible):
   - `GitHub Actions security best practices <current year>`
   - `supply chain attack GitHub Actions <recent months>`
   - `new security scanning tools open source <current year>`
   - `GitHub security features changelog <current year>` (check if CodeQL /
     secret scanning / push protection availability changed for personal
     private repos — that's a standing Tier A upgrade waiting on GitHub)

2. **Compare findings against the current package** (the workflows in
   `.github/workflows/` and the docs in `docs/`). For each candidate change,
   classify: Tier A (adopt now), Tier B (adopt when convenient), Tier C
   (structural), or Not-applicable (with one-line reason).

3. **Check the declined-items list** in `docs/roadmap.md` — has any trigger
   condition been met that justifies reopening a declined decision?

4. **Deliverable:** a summary message in the conversation with:
   - What changed in the ecosystem this month (2-5 bullets)
   - Recommended package changes, tiered, with effort estimates
   - "No changes recommended" is a perfectly good outcome — say it plainly
   - Open PRs only if the user approves specific items

## Standing rules apply

As always: no merges without explicit permission, no pushes to master,
additive PRs only, report faithfully.
