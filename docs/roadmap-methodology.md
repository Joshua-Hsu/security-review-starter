# Roadmap methodology — Tier A / B / C

How to think about security improvements: sort every candidate by **value-per-effort** into three tiers. Do Tier A first, always; Tier B when you have breathing room; Tier C when it moves the needle.

## Tier A — Foundations (~1 hour total)

Non-optional. Every project should have all of these before doing anything else. If any are missing on your project, that's your first day of work.

| Item | Effort | What it prevents |
|---|---|---|
| Daily security-audit workflow | Ship this starter | Silent drift into vulnerable state |
| Weekly Slack digest | Ship this starter | Missed failures |
| Dependabot alerts + security updates | Toggle in repo settings | Manually tracking CVEs |
| Dependabot version updates | Ship this starter's `dependabot.yml` | Stale deps that accumulate breaking changes |
| Secret Scanning + Push Protection | Toggle in repo settings (if available on your plan) | Committing new secrets |
| Branch protection on default branch | Toggle in repo settings (see SETUP.md) | Accidental destructive push to master |
| CodeQL / language SAST | Toggle in repo settings (if available on your plan) | Deep code-level vulnerabilities |

## Tier B — Hardening (~2-3 hours total)

Real improvements to security posture. Do these after Tier A is solid.

| Item | Effort | What it improves |
|---|---|---|
| Pin GitHub Actions to commit SHAs | ~30 min refactor | Defeats tag-moving supply-chain attacks |
| Explicit `permissions:` on every workflow | ~15 min | Closes default-permission over-scoping |
| OSV-Scanner (ships in starter) | Already in starter | Broader vuln DB than language-specific tools |
| Bandit / gosec / eslint-plugin-security (ships in starter for detected langs) | Already in starter | Language-specific antipattern detection |
| `actionlint` in the audit (ships in starter) | Already in starter | Workflow YAML bugs |
| Pre-commit hooks | ~15 min | Catches problems before they reach CI |
| SBOM generation | ~30 min | Compliance / supply-chain visibility |

## Tier C — Structural (1+ hours per item, big payoff)

Bigger lifts. Do when the value clearly exceeds the effort, or when a Tier A/B improvement wouldn't cover the same risk.

| Item | Effort | Payoff |
|---|---|---|
| OIDC for cloud auth (GCP / AWS / Azure) | ~1 hour | Eliminates long-lived credential — the single biggest posture upgrade for most projects |
| Secrets in managed vault (Vault, GCP Secret Manager, AWS SM) | ~2 hours | Central rotation, audit log, revocation without touching repos |
| Move repo to an organization | ~30 min migration | GitHub Advanced Security features (CodeQL / secret scanning push protection) become free for private repos |
| Signed commits + verification | ~1 hour | Cryptographically prove who wrote each commit |
| Container/image scanning (if applicable) | ~1 hour | Catches base-image CVEs |

## How to decide what to do next

At any moment, the "next item" should be:

1. Highest-blast-radius risk not yet covered
2. Cheapest to implement among items of equivalent risk

**Example: real-world CISO reasoning.** A project with a long-lived Google service account JSON in GitHub Secrets has one dominant remaining risk (that credential leaking). Migrating to OIDC (Tier C, ~1 hour) is higher-value than another 5 Tier B items combined, even though Tier B items are individually cheaper.

**Corollary: don't fill in Tier B just because it's the middle tier.** If Tier A is done and Tier C dominates the remaining risk, jump.

## Declined items — document them

If the user explicitly declines an item, record it in the project's `docs/roadmap.md` (create it if it doesn't exist yet) with:

- Date of decision
- What was declined
- User's stated rationale
- Trigger conditions that would justify reopening the decision (e.g., "reconsider if repo goes public", "reconsider if we add collaborators")

Do not silently drop declined items. Future sessions need to see the reasoning to avoid re-proposing the same thing.
