/// Key stored in the privacy_policy_acceptances table when a player passes the age gate.
#define AGE_GATE_POLICY_KEY "maverick_age_gate_18"
/// Where results are kept when the database is not available.
#define AGE_GATE_DATA_FILE "data/age_gate.json"
/// Admin ckey written on bans placed by the age gate.
#define AGE_GATE_BAN_ADMIN "age_gate"

/**
 * Asks new players for their date of birth and bans anyone under the minimum age.
 *
 * Only the result is kept. The date of birth itself is never sent to the server,
 * the age gate window works out the age and sends that.
 *
 * Results go to the database when it is connected and to AGE_GATE_DATA_FILE when it is not.
 */
SUBSYSTEM_DEF(age_gate)
	name = "Age Gate"
	ss_flags = SS_NO_FIRE
	/// ckeys known to have passed this round. Checked before anything else so we only hit storage once.
	var/list/passed_ckeys = list()
	/// ckeys that passed while the database was off.
	var/list/file_passed_ckeys
	/// ckeys banned while the database was off. Enforced by /world/IsBanned.
	var/list/file_underage_ckeys
	/// Open age gate windows, ckey -> /datum/age_gate_prompt
	var/list/open_prompts = list()

/datum/controller/subsystem/age_gate/Initialize()
	if(!CONFIG_GET(flag/age_gate))
		return SS_INIT_NO_NEED
	load_data_file()
	RegisterSignal(SSdcs, COMSIG_GLOB_PRE_JOBS_ASSIGNED, PROC_REF(unready_unchecked_players))
	return SS_INIT_SUCCESS

/// Returns TRUE if this client still has to pass the age gate. Only reads the cache, so it never sleeps.
/datum/controller/subsystem/age_gate/proc/needs_check(client/player)
	if(!CONFIG_GET(flag/age_gate))
		return FALSE
	if(!player)
		return FALSE
	return !passed_ckeys[player.ckey]

/// Admins and the host can fail the age gate without being banned, so they can test it and cannot lock themselves out.
/datum/controller/subsystem/age_gate/proc/is_immune(client/player)
	return player.holder || GLOB.deadmins[player.ckey] || player.is_localhost()

/// Looks for a stored pass for this ckey and caches it. Can sleep on the database.
/datum/controller/subsystem/age_gate/proc/lookup(ckey)
	if(passed_ckeys[ckey])
		return TRUE
	load_data_file()
	if(file_passed_ckeys[ckey])
		passed_ckeys[ckey] = TRUE
		return TRUE
	if(!SSdbcore.IsConnected())
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT 1 FROM [format_table_name("privacy_policy_acceptances")] WHERE ckey = :ckey AND policy_key = :policy_key",
		list("ckey" = ckey, "policy_key" = AGE_GATE_POLICY_KEY)
	)
	if(!query.warn_execute())
		qdel(query)
		return FALSE
	var/found = query.NextRow()
	qdel(query)
	if(found)
		passed_ckeys[ckey] = TRUE
	return found

/// Handles an answer from the age gate window.
/datum/controller/subsystem/age_gate/proc/handle_answer(client/player, age)
	var/minimum_age = CONFIG_GET(number/age_gate_minimum_age)
	var/maximum_age = CONFIG_GET(number/age_gate_maximum_age)
	if(age >= minimum_age && age <= maximum_age)
		record_pass(player)
		to_chat(player, span_notice("Thanks. Welcome aboard."))
		return

	var/reason = age < minimum_age ? "an age under [minimum_age]" : "an implausible age over [maximum_age]"
	if(is_immune(player))
		// Kept for this round only, so the next real answer still counts.
		passed_ckeys[player.ckey] = TRUE
		to_chat(player, span_notice("Age verification check failed, but you're an admin, so I'll assume you're testing. Nothing was stored."))
		log_admin("Age gate: [key_name(player)] gave [reason] but is an admin or the host, so was not banned.")
		return
	ban_player(player, reason)

/// Opens the age gate window for this client, or brings the open one back up.
/datum/controller/subsystem/age_gate/proc/open_prompt(client/player)
	if(!player?.mob)
		return
	var/datum/age_gate_prompt/prompt = open_prompts[player.ckey]
	if(QDELETED(prompt))
		prompt = new(player)
		open_prompts[player.ckey] = prompt
	prompt.ui_interact(player.mob)

/// Called when a player gives an age at or over the minimum.
/datum/controller/subsystem/age_gate/proc/record_pass(client/player)
	var/ckey = player.ckey
	passed_ckeys[ckey] = TRUE
	log_access("Age gate: [key_name(player)] passed.")
	INVOKE_ASYNC(src, PROC_REF(store_pass), ckey)

/datum/controller/subsystem/age_gate/proc/store_pass(ckey)
	if(SSdbcore.IsConnected())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"INSERT IGNORE INTO [format_table_name("privacy_policy_acceptances")] (ckey, policy_key) VALUES (:ckey, :policy_key)",
			list("ckey" = ckey, "policy_key" = AGE_GATE_POLICY_KEY)
		)
		var/stored = query.warn_execute()
		qdel(query)
		if(stored)
			return
	load_data_file()
	file_passed_ckeys[ckey] = TRUE
	save_data_file()

/// Bans and kicks a player who failed the age gate. Reason is a short description of the age they gave.
/datum/controller/subsystem/age_gate/proc/ban_player(client/player, reason)
	var/ckey = player.ckey
	var/player_key = player.key
	var/player_cid = player.computer_id

	message_admins("Age gate: [key_name_admin(player)] gave [reason] and was banned automatically.")
	log_admin_private("Age gate: [key_name(player)] gave [reason] and was banned automatically.")

	to_chat_immediate(player, span_boldannounce("Age verification failed. This server is for adults only. You have been banned."))
	qdel(player)

	INVOKE_ASYNC(src, PROC_REF(store_ban), ckey, player_key, player_cid, reason)

/datum/controller/subsystem/age_gate/proc/store_ban(ckey, player_key, player_cid, reason)
	if(SSdbcore.IsConnected() && insert_db_ban(ckey, player_cid, reason))
		return
	load_data_file()
	file_underage_ckeys[ckey] = TRUE
	save_data_file()
	log_admin_private("Age gate: database unavailable, ban for [player_key] kept in [AGE_GATE_DATA_FILE].")

/// Writes a permanent server ban on the ckey and computer ID. IP is left out so housemates are not caught.
/datum/controller/subsystem/age_gate/proc/insert_db_ban(ckey, player_cid, reason)
	var/list/clients_online = GLOB.clients.Copy()
	var/list/admins_online = list()
	for(var/client/online as anything in clients_online)
		if(online.holder)
			admins_online += online

	var/list/special_columns = list(
		"bantime" = "NOW()",
		"server_ip" = "INET_ATON(?)",
		"a_ip" = "INET_ATON(?)",
	)
	var/list/ban_row = list(list(
		"server_name" = CONFIG_GET(string/serversqlname),
		"server_ip" = world.internet_address || 0,
		"server_port" = world.port,
		"round_id" = GLOB.round_id,
		"role" = "Server",
		"global_ban" = TRUE,
		"applies_to_admins" = FALSE,
		"reason" = "Automatic ban: gave [reason] at the age gate.",
		"ckey" = ckey,
		"computerid" = player_cid || null,
		"a_ckey" = AGE_GATE_BAN_ADMIN,
		"a_ip" = world.internet_address || 0,
		"a_computerid" = "",
		"who" = clients_online.Join(", "),
		"adminwho" = admins_online.Join(", "),
	))
	return SSdbcore.MassInsert(format_table_name("ban"), ban_row, warn = TRUE, special_columns = special_columns)

/// Returns TRUE if this ckey was banned by the age gate while the database was off.
/datum/controller/subsystem/age_gate/proc/is_file_banned(ckey)
	load_data_file()
	return !!file_underage_ckeys[ckey]

/datum/controller/subsystem/age_gate/proc/load_data_file()
	if(file_passed_ckeys)
		return
	file_passed_ckeys = list()
	file_underage_ckeys = list()
	if(!fexists(AGE_GATE_DATA_FILE))
		return
	var/list/contents = json_decode(rustg_file_read(AGE_GATE_DATA_FILE))
	if(!islist(contents))
		return
	for(var/ckey in contents["passed"])
		file_passed_ckeys[ckey] = TRUE
	for(var/ckey in contents["underage"])
		file_underage_ckeys[ckey] = TRUE

/datum/controller/subsystem/age_gate/proc/save_data_file()
	var/list/contents = list(
		"passed" = assoc_to_keys(file_passed_ckeys),
		"underage" = assoc_to_keys(file_underage_ckeys),
	)
	rustg_file_write(json_encode(contents), AGE_GATE_DATA_FILE)

/// Safety net for lobby paths we do not gate directly. Nobody spawns at roundstart without passing.
/datum/controller/subsystem/age_gate/proc/unready_unchecked_players(datum/source)
	SIGNAL_HANDLER
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.ready != PLAYER_READY_TO_PLAY)
			continue
		if(!needs_check(player.client))
			continue
		player.ready = PLAYER_NOT_READY
		to_chat(player, span_warning("You need to enter your date of birth before you can join a round."))

#undef AGE_GATE_POLICY_KEY
#undef AGE_GATE_DATA_FILE
#undef AGE_GATE_BAN_ADMIN
