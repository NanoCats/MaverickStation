// Extra loadout gates: staff tier locks and ID access locks.
// The checks run from the main loadout loop in code/modules/loadout/loadout_helpers.dm.

/datum/loadout_item
	/// Lowest staff tier that can take this item. See LOADOUT_STAFF_* defines.
	var/required_staff_tier = LOADOUT_STAFF_NONE
	/// Access the spawning ID must have this round. The ID needs all of them, or one of them if access_match_any is set.
	var/list/required_access
	/// If TRUE, any one access in required_access is enough.
	var/access_match_any = FALSE
	/// If FALSE, the item is never spawned as an object, even in the travel case. It only acts in on_equip_item.
	var/spawns_item = TRUE

/// Returns the staff tier of a client. Higher tiers include lower ones.
/proc/get_loadout_staff_tier(client/user)
	if(!istype(user))
		return LOADOUT_STAFF_NONE
	if(check_rights_for(user, R_ADMIN))
		return LOADOUT_STAFF_ADMIN
	if(user.is_mentor(admin_bypass = FALSE))
		return LOADOUT_STAFF_MENTOR
	if(SSplayer_ranks.is_donator(user, admin_bypass = FALSE))
		return LOADOUT_STAFF_DONATOR
	return LOADOUT_STAFF_NONE

/// Returns the name of a staff tier for tooltips and warnings.
/proc/loadout_staff_tier_name(tier, plural = TRUE)
	switch(tier)
		if(LOADOUT_STAFF_DONATOR)
			return plural ? "Donators" : "Donator"
		if(LOADOUT_STAFF_MENTOR)
			return plural ? "Mentors" : "Mentor"
		if(LOADOUT_STAFF_ADMIN)
			return plural ? "Admins" : "Admin"
	return "Everyone"

/// Returns TRUE if the client is staff enough for this item.
/datum/loadout_item/proc/passes_staff_tier(client/user)
	if(required_staff_tier <= LOADOUT_STAFF_NONE)
		return TRUE
	return get_loadout_staff_tier(user) >= required_staff_tier

/// Returns TRUE if the ID this outfit gives has all of our required access.
/// Reads the outfit's trim, which already has the round's access config applied.
/// Using the outfit instead of the job means admin spawns and ghost roles are judged by the ID they really get.
/datum/loadout_item/proc/passes_access(datum/outfit/outfit)
	if(!length(required_access))
		return TRUE
	var/trim_path = outfit?.id_trim
	if(!trim_path)
		return FALSE
	var/datum/id_trim/trim = SSid_access.trim_singletons_by_path[trim_path]
	if(isnull(trim))
		return FALSE
	for(var/needed in required_access)
		var/has_it = (needed in trim.access)
		if(access_match_any && has_it)
			return TRUE
		if(!access_match_any && !has_it)
			return FALSE
	return !access_match_any

/**
 * Checks the Maverick gates when the character spawns.
 * Returns a reason string if the item is blocked, or null if it is fine.
 */
/datum/loadout_item/proc/check_maverick_gates(datum/preferences/preference_source, datum/outfit/outfit, visuals_only = FALSE)
	if(!passes_staff_tier(preference_source?.parent))
		return "staff restrictions"
	// The preview has no real ID, so show access locked items there.
	// Admins skip the access lock. They can spawn the item anyway.
	if(!visuals_only && !passes_access(outfit) && get_loadout_staff_tier(preference_source?.parent) < LOADOUT_STAFF_ADMIN)
		return "access restrictions"
	return null

/datum/loadout_item/get_item_information()
	. = ..()
	if(required_staff_tier > LOADOUT_STAFF_NONE)
		.[FA_ICON_USER_SHIELD] = "[loadout_staff_tier_name(required_staff_tier, plural = FALSE)] only"
	if(length(required_access))
		var/list/access_names = list()
		for(var/needed in required_access)
			access_names += SSid_access.get_access_desc(needed) || needed
		.[FA_ICON_ID_CARD] = "Access whitelist: [access_names.Join(access_match_any ? " or " : ", ")]"

// Sends the staff tier to the loadout UI so it can hide items above the viewer's tier, like ckey locked items.
/datum/loadout_item/to_ui_data()
	. = ..()
	.["staff_tier"] = required_staff_tier

/datum/preference_middleware/loadout/get_ui_static_data(mob/user)
	. = ..()
	.["staff_tier"] = get_loadout_staff_tier(user?.client)
