// Extra loadout gates: staff tier locks and ID access locks.
// The checks run from the main loadout loop in code/modules/loadout/loadout_helpers.dm.

/datum/loadout_item
	/// Lowest staff tier that can take this item. See LOADOUT_STAFF_* defines.
	var/required_staff_tier = LOADOUT_STAFF_NONE
	/// Access the spawning job must have this round. The job needs all of them.
	var/list/required_access

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
/proc/loadout_staff_tier_name(tier)
	switch(tier)
		if(LOADOUT_STAFF_DONATOR)
			return "Donators"
		if(LOADOUT_STAFF_MENTOR)
			return "Mentors"
		if(LOADOUT_STAFF_ADMIN)
			return "Admins"
	return "Everyone"

/// Returns TRUE if the client is staff enough for this item.
/datum/loadout_item/proc/passes_staff_tier(client/user)
	if(required_staff_tier <= LOADOUT_STAFF_NONE)
		return TRUE
	return get_loadout_staff_tier(user) >= required_staff_tier

/// Returns TRUE if the job's ID will have all of our required access this round.
/// Reads the job's trim, which already has the round's access config applied.
/datum/loadout_item/proc/passes_access(datum/job/job)
	if(!length(required_access))
		return TRUE
	if(isnull(job?.outfit))
		return FALSE
	var/datum/outfit/job_outfit = job.outfit
	var/trim_path = job_outfit::id_trim
	if(!trim_path)
		return FALSE
	var/datum/id_trim/trim = SSid_access.trim_singletons_by_path[trim_path]
	if(isnull(trim))
		return FALSE
	for(var/needed in required_access)
		if(!(needed in trim.access))
			return FALSE
	return TRUE

/**
 * Checks the Maverick gates when the character spawns.
 * Returns a reason string if the item is blocked, or null if it is fine.
 */
/datum/loadout_item/proc/check_maverick_gates(datum/preferences/preference_source, datum/job/equipping, visuals_only = FALSE)
	if(!passes_staff_tier(preference_source?.parent))
		return "staff restrictions"
	// The preview has no real job, so show access locked items there.
	if(!visuals_only && !passes_access(equipping))
		return "access restrictions"
	return null

/datum/loadout_item/get_item_information()
	. = ..()
	if(required_staff_tier > LOADOUT_STAFF_NONE)
		.[FA_ICON_USER_SHIELD] = "Staff only: [loadout_staff_tier_name(required_staff_tier)]"
	if(length(required_access))
		var/list/access_names = list()
		for(var/needed in required_access)
			access_names += SSid_access.get_access_desc(needed) || needed
		.[FA_ICON_ID_CARD] = "Needs access: [access_names.Join(", ")]\nChecked against your job when you spawn."
