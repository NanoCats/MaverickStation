# Upstream veto ledger

Upstream PRs that MaverickStation rejected. The sync process reads this file. A vetoed PR is reverted during the sync and must not come back through a later sync.

If a later upstream PR builds on a vetoed one, the sync flags it for a new decision.

| Upstream | PR | Title | Vetoed on | Reason |
|----------|----|-------|-----------|--------|
| Bubberstation | #6471 | Restricts the colony gear to not be used on-station. | 2026-11-19 | Colony gear works on station on MaverickStation. Fully reverted. |
| Bubberstation | #6486 | Fixes colony core flatpacker oversights + lack of cargo descriptions | 2026-11-19 | Partial. The flatpacker block and the "cannot be deployed on station" text are removed. The flatpacked kitchen crate contents and the description cleanup are kept. |
| Bubberstation | #6450 | Shotgun rebalance | 2026-11-25 | Partial. The armory shotgun rack keeps its two Renosters instead of three Woodstocks, through an override in `modular_~maverick/code/modules/security/armory_shotguns.dm`. The cargo price and accessory changes are kept. |
