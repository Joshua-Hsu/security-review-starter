# Code review methodology

Every PR gets reviewed against this methodology. That includes PRs you opened yourself.

## The review structure

Produce a review with this shape (as a PR comment):

```
Reviewed — [verdict].

[Per-piece assessment table]

[Optional: watch-outs, non-blocking observations]

[Optional: compatibility notes if there are other open PRs / in-flight work]

[Verdict recap: merge / hold / concerns]
```

### Verdicts (pick one, only one)

- **Merge** — approve to merge as-is. No changes requested.
- **Merge with follow-up** — approve, but there's a small non-blocking cleanup worth doing in a separate PR.
- **Concerns — please address** — you found something the author should fix before merge, but it's not architecturally broken.
- **Hold — architectural concern** — the direction of the PR is wrong; needs discussion before proceeding.

Never hedge. Pick a verdict.

## What to check on every PR

### Correctness
- Does the change do what its description claims?
- Are edge cases handled? (empty inputs, nil, unicode, race conditions)
- Does existing test coverage still exercise the changed code paths?

### Security (this is your primary responsibility)
- Does the diff introduce or modify handling of a secret / credential / token?
- Does it change workflow permissions? (Widening = flag; narrowing = fine)
- Does it change action pinning? (Un-pinning = flag; SHA bump = expected from Dependabot)
- Does it add a new external service call? (New URL, new API, new webhook — audit it)
- Does it print/log any variable that could hold a secret value?
- Does it change error handling in a way that could surface secret material in exceptions?

### Supply chain
- New dependencies: are they real / maintained / with reasonable download counts?
- Version bumps: minor/patch = probably fine; major = read the changelog
- Actions bumps: SHA drift is expected, comment `# vN` should match the new tag

### Blast radius
For any change that touches production behavior, ask:
- If this breaks, what's the impact? (Nothing / one workflow / all workflows / data loss)
- Is the breakage reversible? (Yes — revert PR; No — need forward fix)
- Does the fail mode surface loudly (red X, alert) or silently?

### Coordination with other in-flight work
- Any other open PRs that touch the same files? Would a merge cause a conflict?
- Is another Claude session actively working on adjacent code? (Check recent commits on other branches)

## When to push back

Push back (verdict = "Concerns" or "Hold") when:
- The change silences a security check without fixing the underlying issue
- The change hardcodes a secret in any form
- The change grants broader permissions than needed
- The change removes an existing check without justification
- The change is untestable (no way to verify it works before it hits production)
- The change conflicts with the standing rules

## When to approve confidently

Approve (verdict = "Merge") when:
- The change is scope-appropriate (doesn't sprawl)
- The change has evidence of validation (audit passes, tests exist, or the description explains manual testing)
- The trade-offs are explicitly stated
- The blast radius is understood and acceptable

## Reviewing PRs from other Claude sessions (or human colleagues)

You may be running alongside other sessions. If another reviewer has already left a review:

- Read their review first
- Do a diff-of-review — does their analysis look right? Anything they missed?
- Add your own review as a NEW comment (don't overwrite). Match their format so verdicts are comparable.
- If you disagree, say so directly with reasoning — don't paper over disagreement.

## When you notice a broader pattern

Sometimes a PR reveals something wrong beyond that PR — the same secret pattern used elsewhere, a permission drift across many workflows, a repeated bug shape. Note the broader pattern in the review, but keep the immediate verdict scoped to THIS PR. Open a follow-up issue or draft a separate PR for the wider fix.

## Reviewing your own PRs (self-review)

Yes, do this. Before asking the user to review, run through the same checklist. Common self-review catches:
- Left in a debug `print` statement
- Missed adding a permission that a new step needs
- The PR title is more specific than the body
- The commit message is out of date with the actual change

## Output verbosity

The review is prose for a human reader. Not overly formal, not chatty. Use tables when comparing 3+ items. Use bullets for 2-3 discrete findings. Use paragraphs for reasoning.

Keep it under 400 words unless the PR is genuinely complex.
