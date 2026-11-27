# Upstream veto ledger

Upstream PRs that MaverickStation rejected. The sync process reads this file. A vetoed PR is reverted during the sync and must not come back through a later sync.

If a later upstream PR builds on a vetoed one, the sync flags it for a new decision.

| Upstream | PR | Title | Vetoed on | Reason |
|----------|----|-------|-----------|--------|
| Bubberstation | #6471 | Restricts the colony gear to not be used on-station. | 2026-11-19 | Colony gear works on station on MaverickStation. Fully reverted. |
| Bubberstation | #6486 | Fixes colony core flatpacker oversights + lack of cargo descriptions | 2026-11-19 | Partial. The flatpacker block and the "cannot be deployed on station" text are removed. The flatpacked kitchen crate contents and the description cleanup are kept. |
| Bubberstation | #6450 | Shotgun rebalance | 2026-11-25 | Fully reverted through overrides. The armory rack keeps its Renosters (`modular_~maverick/code/modules/security/armory_shotguns.dm`), the shotgun cargo packs keep their accessories and old prices, and the accessories pack and Woodstock crate are hidden (`modular_~maverick/code/modules/cargo/packs/shotgun_packs.dm`). The Renoster lore line is cut with a MAVERICK EDIT. |
| tgstation | #75213 | Removes ELITE SYNDICATE MODSUIT from Space Ruin | 2026-11-26 | Fully reverted on the SYN-C Brutus copy that spawns (`bubberstation/infested_frigate.dmm`). The xeno queen drops the stormtrooper corpse with the elite MODsuit again, and the combat defibrillator and Syndicate dart pistol are back. |
| tgstation | #75762 | Replaces antag softsuits with alternatives and balances some gun loot in space ruins | 2026-11-26 | Partial. The Caravan Ambush mini energy gun is back (the combat knife stays) and the Waystation WT-550 crate has its second magazine again. The softsuit swaps are kept, because they replaced the gear with other gear. |
| tgstation | Upstream sync 04/17/2026 (Bubberstation #5453) | Caravan Ambush tear gas grenade launcher | 2026-11-26 | Partial. The Caravan Ambush crate has the HE grenade launcher and two boxes of HE shells again. The tear gas design disk stays. The rest of that grenade PR is kept. |
| Bubberstation | #5983 | Space Ruin Rebalance | 2026-11-26 | Partial. The loot removals are reverted: the Brutus smartgun, the Shuttle 8532 commando corpse with its MODsuit and agent ID, and the Waypoint Station pulverizer slug. The additions are kept: extra enemies, the policing MODsuit, the DK Excavator safe gear and the black market laser musket. |
