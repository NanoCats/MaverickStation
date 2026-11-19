# Upstream veto ledger

Upstream PRs that MaverickStation rejected. The sync process reads this file. A vetoed PR is reverted during the sync and must not come back through a later sync.

If a later upstream PR builds on a vetoed one, the sync flags it for a new decision.

| Upstream | PR | Title | Vetoed on | Reason |
|----------|----|-------|-----------|--------|
