# Setup (one-time, ~5 minutes)

Two things to configure before the workflows will run cleanly.

## 1. Slack incoming webhook for the security channel (~3 min)

1. Create a Slack channel dedicated to security alerts — recommended name: `#{project}-security-audit`.
2. Go to https://api.slack.com/apps → **Create New App** → From scratch.
3. App Name: `{Project} Security Audit`. Pick your workspace. Click Create App.
4. Left sidebar → **Incoming Webhooks** → toggle **Activate Incoming Webhooks** to **On**.
5. Scroll down → **Add New Webhook to Workspace** → pick the security channel → **Allow**.
6. Copy the URL (starts with `https://hooks.slack.com/services/…`). Treat it like a password — anyone with it can post to your channel.

## 2. Add the webhook to GitHub Secrets (~1 min)

1. Your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
2. Name: `SLACK_SECURITY_WEBHOOK_URL`
3. Value: the URL from step 1.
4. Add secret.

## 3. Enable Dependabot (~30 sec)

1. Your repo → **Settings** → **Advanced Security** (or **Code security & analysis** on older UIs).
2. Enable **Dependabot alerts**.
3. Enable **Dependabot security updates**.
4. Enable **Grouped security updates** (belt-and-suspenders to `.github/dependabot.yml`).
5. Dependabot version updates is picked up automatically from `.github/dependabot.yml` — no toggle needed.

## 4. (Optional) Configure branch protection

If you want the security-audit check to be a required gate for merging to main:

1. Repo → **Settings** → **Branches** → **Add branch protection rule** (or **Rulesets** on newer UIs).
2. Branch name pattern: `main` (or `master`).
3. ✅ Require a pull request before merging
4. ✅ Require status checks to pass before merging → search for and add `audit`
5. Optionally: ✅ Require branches to be up to date before merging

Whether to enable this is a preference. It prevents accidental force-pushes and merges-while-red. Skip if you prefer the lighter-touch discipline of following [docs/standing-rules.md](docs/standing-rules.md) instead.

## 5. Verify

Once secrets and Dependabot are set:

1. Repo → **Actions** → **Audit - Security** → **Run workflow** → Run.
2. Wait ~30-60 seconds. Check that it completes green.
3. Repo → **Actions** → **Audit - Security weekly report** → **Run workflow** → Run.
4. Confirm a message lands in your Slack channel.

You're done. The daily schedule kicks in at 01:00 UTC nightly.

## Troubleshooting

- **Audit red on first run**: read the failed step's log. Most likely: a leftover `.env` file, a real leaked secret in git history (gitleaks catches these), or a stale-version CVE. Fix the underlying issue; don't add a suppression.
- **No Slack message on manual weekly-report run**: confirm `SLACK_SECURITY_WEBHOOK_URL` is set exactly (case-sensitive). The workflow's first step verifies this and prints a clear error.
- **`pip-audit` fails on transitive dep**: bump the transitive dep directly in `requirements.txt` (see the `idna>=3.15` pattern for an example).
- **`actionlint` complains about `SC2129` style suggestion**: that's a shellcheck style-only rule — already filtered out by default. If you see it, verify the workflow still has `-shellcheck "shellcheck -S warning"` on the actionlint step.
