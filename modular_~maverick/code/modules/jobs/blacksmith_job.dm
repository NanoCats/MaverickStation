// The Blacksmith job is off unless the Maverick config turns it on. Forging itself stays:
// the Lavaland smithy, cargo forge imports and buildable forges all still work.

/// Gives the station its Blacksmith job slot
/datum/config_entry/flag/maverick_blacksmith_job

/datum/job/blacksmith/New()
	. = ..()
	if(CONFIG_GET(flag/maverick_blacksmith_job))
		return
	total_positions = 0
	spawn_positions = 0
