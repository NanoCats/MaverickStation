// Config entries for MaverickStation features. Values are set in config/maverick/maverick_config.txt.
//
// Add one entry per feature switch, with a doc comment, like this:
//
// /// Turns the example feature on
// /datum/config_entry/flag/maverick_example
//
// Then read it in code with CONFIG_GET(flag/maverick_example), and add a matching
// line to the config file. Start entry names with maverick_ so they never clash with upstream.

/// Turns game debugging on when someone connects from localhost with the localhost admin rank on, so runtimes show in the Debug Log chat tab
/datum/config_entry/flag/maverick_local_debug

/// Turns the old hexacrocin overdose bimbo trauma back on. Off by default, the overdose feeds the bimbo component instead.
/datum/config_entry/flag/maverick_legacy_bimbo_trauma
