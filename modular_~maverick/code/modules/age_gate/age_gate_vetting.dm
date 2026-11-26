/**
 * Passing the age gate makes a player vetted, so they get the adult features
 * without a staff member adding them by hand. Staff can still add players by hand.
 * Admins who fail the check while testing are not vetted by it.
 */

/// TRUE if this ckey has a real age gate pass. Only reads the cache, so it never sleeps.
/datum/controller/subsystem/age_gate/proc/counts_as_vetted(ckey)
	if(!CONFIG_GET(flag/maverick_age_gate))
		return FALSE
	return passed_ckeys[ckey] && !test_pass_ckeys[ckey]

/// Marks a connected player as vetted if their age gate pass counts.
/// is_vetted() reads this var before anything else, so setting it is enough.
/datum/controller/subsystem/age_gate/proc/sync_vetted(ckey)
	if(!counts_as_vetted(ckey))
		return
	var/client/player = GLOB.directory[ckey]
	if(player)
		player.is_vetted = TRUE

/// Adds a new pass to the vetted table, so staff tools and the player panel show it. Can sleep on the database.
/datum/controller/subsystem/age_gate/proc/store_vetted(ckey)
	if(!SSdbcore.IsConnected() || SSplayer_ranks.get_user_vetted_status_hot(ckey))
		return
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO vetted_list (ckey, admin_who_added) VALUES (:ckey, :admin_who_added)",
		list("ckey" = ckey, "admin_who_added" = "Age gate"),
	)
	query.warn_execute()
	qdel(query)
