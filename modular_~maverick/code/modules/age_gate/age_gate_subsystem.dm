/// Key stored in the privacy_policy_acceptances table when a player passes the age gate.
#define AGE_GATE_POLICY_KEY "maverick_age_gate_18"
/// Prefix of the key stored when a player agrees to the privacy policy. The policy version goes after it.
#define AGE_GATE_PRIVACY_KEY_PREFIX "maverick_privacy_v"
/// Where results are kept when the database is not available.
#define AGE_GATE_DATA_FILE "data/age_gate.json"
/// Admin ckey written on bans placed by the age gate.
#define AGE_GATE_BAN_ADMIN "age_gate"

/**
 * The welcome window every player sees before they can play: the privacy policy and the age gate.
 *
 * The age check is asked once. The privacy policy is asked again whenever MAVERICK_PRIVACY_POLICY_VERSION goes up.
 * Players under the minimum age, or over the plausible maximum, are banned.
 *
 * Only results are kept. The date of birth itself is never sent to the server,
 * the window works out the age and sends that.
 *
 * Results go to the database when it is connected and to AGE_GATE_DATA_FILE when it is not.
 */
SUBSYSTEM_DEF(age_gate)
	name = "Age Gate"
	ss_flags = SS_NO_FIRE
	/// ckeys known to have passed the age check. Checked before anything else so we only hit storage once.
	var/list/passed_ckeys = list()
	/// ckeys known to have agreed to the current privacy policy version.
	var/list/policy_ckeys = list()
	/// ckeys that passed the age check while the database was off.
	var/list/file_passed_ckeys
	/// ckey -> highest privacy policy version agreed to while the database was off.
	var/list/file_policy_versions
	/// ckeys banned while the database was off. Enforced by /world/IsBanned.
	var/list/file_underage_ckeys
	/// Open welcome windows, ckey -> /datum/age_gate_prompt
	var/list/open_prompts = list()
	/// ckeys of admins who failed the age check while testing. They may play this round, but it is not a real pass.
	var/list/test_pass_ckeys = list()

/datum/controller/subsystem/age_gate/Initialize()
	if(!CONFIG_GET(flag/maverick_age_gate))
		return SS_INIT_NO_NEED
	load_data_file()
	RegisterSignal(SSdcs, COMSIG_GLOB_PRE_JOBS_ASSIGNED, PROC_REF(unready_unchecked_players))
	return SS_INIT_SUCCESS

/// Returns TRUE if this client still has to finish the welcome window. Only reads the cache, so it never sleeps.
/datum/controller/subsystem/age_gate/proc/needs_check(client/player)
	if(!CONFIG_GET(flag/maverick_age_gate))
		return FALSE
	if(!player)
		return FALSE
	return needs_age(player) || needs_policy(player)

/// Returns TRUE if this client has not passed the age check yet.
/datum/controller/subsystem/age_gate/proc/needs_age(client/player)
	return !passed_ckeys[player.ckey]

/// Returns TRUE if this client has not agreed to the current privacy policy yet.
/datum/controller/subsystem/age_gate/proc/needs_policy(client/player)
	return !policy_ckeys[player.ckey]

/// Admins and the host can fail the age gate without being banned, so they can test it and cannot lock themselves out.
/datum/controller/subsystem/age_gate/proc/is_immune(client/player)
	return player.holder || GLOB.deadmins[player.ckey] || player.is_localhost()

/// Database key for the current privacy policy version.
/datum/controller/subsystem/age_gate/proc/policy_key()
	return "[AGE_GATE_PRIVACY_KEY_PREFIX][CONFIG_GET(number/maverick_privacy_policy_version)]"

/// Looks for a stored age pass and policy agreement for this ckey and caches them. Can sleep on the database.
/// Returns TRUE if nothing more is needed from this player.
/datum/controller/subsystem/age_gate/proc/lookup(ckey)
	load_data_file()
	if(file_passed_ckeys[ckey])
		passed_ckeys[ckey] = TRUE
	if(file_policy_versions[ckey] >= CONFIG_GET(number/maverick_privacy_policy_version))
		policy_ckeys[ckey] = TRUE
	sync_vetted(ckey)
	if(passed_ckeys[ckey] && policy_ckeys[ckey])
		return TRUE
	if(!SSdbcore.IsConnected())
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT policy_key FROM [format_table_name("privacy_policy_acceptances")] WHERE ckey = :ckey AND policy_key IN (:age_key, :privacy_key)",
		list("ckey" = ckey, "age_key" = AGE_GATE_POLICY_KEY, "privacy_key" = policy_key())
	)
	if(!query.warn_execute())
		qdel(query)
		return FALSE
	while(query.NextRow())
		if(query.item[1] == AGE_GATE_POLICY_KEY)
			passed_ckeys[ckey] = TRUE
		else
			policy_ckeys[ckey] = TRUE
	qdel(query)
	sync_vetted(ckey)
	return passed_ckeys[ckey] && policy_ckeys[ckey]

/// Handles an answer from the welcome window that included an age.
// No local vars in here on purpose: adding them sets off a false unused_var warning in BYOND 516.1659 elsewhere in the codebase.
/datum/controller/subsystem/age_gate/proc/handle_answer(client/player, age)
	if(age >= CONFIG_GET(number/maverick_age_gate_minimum_age) && age <= CONFIG_GET(number/maverick_age_gate_maximum_age))
		record_pass(player)
		record_policy(player)
		to_chat(player, span_notice("Thanks. Welcome aboard."))
		return
	if(is_immune(player))
		// Kept for this round only, so the next real answer still counts.
		passed_ckeys[player.ckey] = TRUE
		policy_ckeys[player.ckey] = TRUE
		test_pass_ckeys[player.ckey] = TRUE
		to_chat(player, span_notice("Age verification check failed, but you're an admin, so I'll assume you're testing. Nothing was stored."))
		log_admin("Age gate: [key_name(player)] gave [describe_failed_age(age)] but is an admin or the host, so was not banned.")
		return
	ban_player(player, describe_failed_age(age))

/// Short description of a failed answer for logs and the ban reason.
/datum/controller/subsystem/age_gate/proc/describe_failed_age(age)
	if(age < CONFIG_GET(number/maverick_age_gate_minimum_age))
		return "an age under [CONFIG_GET(number/maverick_age_gate_minimum_age)]"
	return "an implausible age over [CONFIG_GET(number/maverick_age_gate_maximum_age)]"

/// Opens the welcome window for this client, or brings the open one back up.
/// test_age asks for a date of birth even if they already passed, for the Test Age Gate verb.
/datum/controller/subsystem/age_gate/proc/open_prompt(client/player, test_age = FALSE)
	if(!player?.mob)
		return
	var/datum/age_gate_prompt/prompt = open_prompts[player.ckey]
	if(QDELETED(prompt))
		prompt = new(player)
		open_prompts[player.ckey] = prompt
	if(test_age)
		prompt.ask_age = TRUE
	prompt.ui_interact(player.mob)

/// Called when a player gives an age in the allowed range.
/datum/controller/subsystem/age_gate/proc/record_pass(client/player)
	passed_ckeys[player.ckey] = TRUE
	test_pass_ckeys -= player.ckey
	log_access("Age gate: [key_name(player)] passed.")
	INVOKE_ASYNC(src, PROC_REF(store_result), player.ckey, AGE_GATE_POLICY_KEY)
	sync_vetted(player.ckey)
	INVOKE_ASYNC(src, PROC_REF(store_vetted), player.ckey)

/// Called when a player agrees to the current privacy policy.
/datum/controller/subsystem/age_gate/proc/record_policy(client/player)
	policy_ckeys[player.ckey] = TRUE
	log_access("Privacy policy: [key_name(player)] agreed to version [CONFIG_GET(number/maverick_privacy_policy_version)].")
	INVOKE_ASYNC(src, PROC_REF(store_result), player.ckey, policy_key())

/// Stores an age pass or a policy agreement. Falls back to the data file if the database is off or fails.
/datum/controller/subsystem/age_gate/proc/store_result(ckey, result_key)
	if(SSdbcore.IsConnected())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"INSERT IGNORE INTO [format_table_name("privacy_policy_acceptances")] (ckey, policy_key) VALUES (:ckey, :policy_key)",
			list("ckey" = ckey, "policy_key" = result_key)
		)
		var/stored = query.warn_execute()
		qdel(query)
		if(stored)
			return
	load_data_file()
	if(result_key == AGE_GATE_POLICY_KEY)
		file_passed_ckeys[ckey] = TRUE
	else
		file_policy_versions[ckey] = CONFIG_GET(number/maverick_privacy_policy_version)
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
	file_policy_versions = list()
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
	var/list/policy_versions = contents["policy"]
	if(islist(policy_versions))
		file_policy_versions = policy_versions

/datum/controller/subsystem/age_gate/proc/save_data_file()
	var/list/contents = list(
		"passed" = assoc_to_keys(file_passed_ckeys),
		"policy" = file_policy_versions,
		"underage" = assoc_to_keys(file_underage_ckeys),
	)
	rustg_file_write(json_encode(contents), AGE_GATE_DATA_FILE)

/// Safety net for lobby paths we do not gate directly. Nobody spawns at roundstart without finishing the welcome window.
/datum/controller/subsystem/age_gate/proc/unready_unchecked_players(datum/source)
	SIGNAL_HANDLER
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.ready != PLAYER_READY_TO_PLAY)
			continue
		if(!needs_check(player.client))
			continue
		player.ready = PLAYER_NOT_READY
		to_chat(player, span_warning("You need to finish the welcome window before you can join a round."))

#undef AGE_GATE_POLICY_KEY
#undef AGE_GATE_PRIVACY_KEY_PREFIX
#undef AGE_GATE_DATA_FILE
#undef AGE_GATE_BAN_ADMIN
