// MaverickStation species roster.
//
// Upstream decides which species are pickable with ROUNDSTART_RACES in config/game_options.txt.
// We leave that file alone so upstream syncs do not conflict, and adjust the result from
// config/maverick/maverick_config.txt instead:
//   MAVERICK_SPECIES_DISABLED <id>  removes a species from character setup
//   MAVERICK_SPECIES_ENABLED <id>   adds a species to character setup
// Disabled wins if a species is on both lists, and also beats upstream holiday unlocks.

/// Species IDs removed from character setup, whatever upstream config says
/datum/config_entry/keyed_list/maverick_species_disabled
	key_mode = KEY_MODE_TEXT
	value_mode = VALUE_MODE_FLAG

/datum/config_entry/keyed_list/maverick_species_disabled/ValidateListEntry(key_name, key_value)
	if(key_name in GLOB.species_list)
		return TRUE
	log_config("ERROR: [key_name] is not a valid species ID.")
	return FALSE

/// Species IDs added to character setup, whatever upstream config says
/datum/config_entry/keyed_list/maverick_species_enabled
	key_mode = KEY_MODE_TEXT
	value_mode = VALUE_MODE_FLAG

/datum/config_entry/keyed_list/maverick_species_enabled/ValidateListEntry(key_name, key_value)
	if(key_name in GLOB.species_list)
		return TRUE
	log_config("ERROR: [key_name] is not a valid species ID.")
	return FALSE

/// Returns TRUE if the Maverick roster removes this species from character setup
/datum/species/proc/maverick_roster_disabled()
	return (id in CONFIG_GET(keyed_list/maverick_species_disabled))

/datum/species/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	if(id in CONFIG_GET(keyed_list/maverick_species_enabled))
		return TRUE
	return ..()

// Some species have their own override that unlocks them on a holiday and returns before
// reaching the base proc above. Wrap each one so a disabled species stays disabled on holidays too.
/datum/species/dullahan/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()

/datum/species/human/vampire/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()

/datum/species/monkey/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()

/datum/species/mutant/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()

/datum/species/shadow/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()

/datum/species/skeleton/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()

/datum/species/spirit/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()

/datum/species/zombie/check_roundstart_eligible()
	if(maverick_roster_disabled())
		return FALSE
	return ..()
