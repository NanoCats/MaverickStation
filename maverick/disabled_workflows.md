# Disabled workflows

These GitHub Actions workflows came from Bubberstation. They are disabled in the repo settings, not deleted. The files stay unchanged so upstream syncs do not conflict.

To turn one back on: Actions tab, pick the workflow, then "Enable workflow". Most of them need secrets (Discord webhooks, tokens) added under Settings, Secrets and variables, Actions.

| Workflow | What it does | Why it is off |
|----------|--------------|---------------|
| discord_pr_announce.yml | Posts new PRs to Discord | No Discord server yet |
| discord_discussions.yml | Opens Discord threads for PRs | No Discord server yet |
| stale.yml | Marks old issues and PRs as stale | Not wanted for a solo repo |
| test_merge_bot.yml | Manages test merges on the live server | No live server yet |
| auto_changelog.yml | Writes changelog entries from PR bodies | Pushes to master, which the ruleset blocks |
| compile_changelogs.yml | Compiles changelogs on a schedule | Pushes to master, which the ruleset blocks |
| autowiki.yml | Updates the wiki | No wiki |
| generate_documentation.yml | Publishes code docs | Not needed yet |
| generate_client_storage.yml | Uploads client assets | Needs upstream secrets |
| update_tgs_dmapi.yml | Opens PRs to update the TGS DMAPI | Upstream syncs bring these updates |

Disabled on 2026-11-19.
