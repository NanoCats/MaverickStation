## AMAS: Automated Management And Staffing

Module ID: AMAS

### Description

The station is on the frontier, where real crew are hard to find. AMAS watches the vital functions of the station and staffs them with automatons built by Micron Control Systems when the crew does not.

Rules the module follows:

- Automatons never take a job slot and never count as players.
- AMAS watches output, not headcount. A job that is filled but not worked counts as a shortfall.
- Automatons step back when a real person is doing the work.

### Current state

- `SSamas` runs watchdogs. The materials watchdog measures ore silo inflow against a target that scales with living players.
- A shortfall that lasts past its grace period is logged. Dispatch is not built yet.
- Automatons can be spawned by admins. They have the job outfit, ID, access, a bank account and a random name and gender, and no AI yet.
- Automatons have a synth brain and synthetic parts. A dead automaton is repaired and revived with the same reboot surgery as a synth.

### Admin verbs (Debug tab)

- AMAS Status: watchdog readings and the automaton roster.
- Spawn AMAS Automaton: builds an automaton for a job where you stand.

### Config

- `MAVERICK_AMAS_DISABLED` turns the whole module off.
