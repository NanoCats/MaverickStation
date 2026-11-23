/**
 * Cheat Engine: an admin-only cheat panel for playtesting on a local server.
 *
 * Nothing turns on by itself, because a playtest may be testing the very system a cheat covers.
 * A cheat turned on in the lobby applies when the round starts. One turned on mid-round applies right away.
 * Each cheat records exactly what it added, and turning it off takes that amount back,
 * down to zero if some was spent. Things it changed in place go back to how they were.
 */

#define CHEAT_POWER "power"
#define CHEAT_RESEARCH "research"
#define CHEAT_CARGO "cargo"
#define CHEAT_SILO "silo"
#define CHEAT_COUNTDOWN "countdown"

/// Research points the research cheat adds
#define CHEAT_RESEARCH_POINTS 1000000
/// Credits the cargo cheat adds to the cargo budget
#define CHEAT_CARGO_CREDITS 1000000
/// Sheets of each silo material the silo cheat adds
#define CHEAT_SILO_SHEETS 500
/// Output level of station SMES units while the power cheat is on
#define CHEAT_SMES_OUTPUT (10 MEGA WATTS)

GLOBAL_DATUM_INIT(maverick_cheats, /datum/maverick_cheats, new)

/datum/maverick_cheats
	/// Cheats that are on. Some may not be applied yet (see applied).
	var/list/active = list()
	/// Cheats whose effect is in the game right now
	var/list/applied = list()
	/// Research points this session added and has not taken back
	var/research_added = 0
	/// Credits this session added and has not taken back
	var/cargo_added = 0
	/// Material -> amount added to the silo and not taken back
	var/list/silo_added = list()
	/// Weakref to an SMES -> list(output_level, output_attempt) from before the power cheat
	var/list/smes_saved = list()
	/// The countdown cheat set SSticker.start_immediately, so turning it off should clear it
	var/countdown_set = FALSE
	/// Timer that watches for a ready admin while the countdown cheat is on
	var/countdown_timer

/// The cheats in panel order. Address and type are for the look of the panel only.
/datum/maverick_cheats/proc/cheat_list()
	var/static/list/cheats = list(
		list("key" = CHEAT_POWER, "name" = "Unlimited power (station SMES never drain)", "address" = "0x0BADF00D", "type" = "Double", "value" = "10 MW"),
		list("key" = CHEAT_RESEARCH, "name" = "Research points", "address" = "0x1337C0DE", "type" = "4 Bytes", "value" = "+1,000,000"),
		list("key" = CHEAT_CARGO, "name" = "Cargo budget", "address" = "0x00C4B00D", "type" = "4 Bytes", "value" = "+1,000,000 cr"),
		list("key" = CHEAT_SILO, "name" = "Ore silo materials", "address" = "0x5110BEEF", "type" = "Array of byte", "value" = "+500 sheets each"),
		list("key" = CHEAT_COUNTDOWN, "name" = "Skip lobby countdown (lobby only)", "address" = "0x0000600D", "type" = "Binary", "value" = "Start on ready"),
	)
	return cheats

/datum/maverick_cheats/proc/cheat_name(key)
	for(var/list/cheat as anything in cheat_list())
		if(cheat["key"] == key)
			return cheat["name"]
	return key

/datum/maverick_cheats/proc/toggle(key, mob/user)
	if(active[key])
		disable(key, user)
	else
		enable(key, user)

/datum/maverick_cheats/proc/toggle_all(mob/user)
	var/all_on = TRUE
	for(var/list/cheat as anything in cheat_list())
		if(!active[cheat["key"]])
			all_on = FALSE
			break
	for(var/list/cheat as anything in cheat_list())
		var/key = cheat["key"]
		if(all_on)
			disable(key, user)
		else if(!active[key])
			enable(key, user)

/datum/maverick_cheats/proc/enable(key, mob/user)
	if(active[key])
		return
	active[key] = TRUE
	announce(user, "turned on", key)
	if(key == CHEAT_COUNTDOWN)
		start_countdown_watch()
		return
	if(!SSticker.HasRoundStarted())
		RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_starting), override = TRUE)
		return
	apply(key, user)

/datum/maverick_cheats/proc/disable(key, mob/user)
	if(!active[key])
		return
	active -= key
	announce(user, "turned off", key)
	if(key == CHEAT_COUNTDOWN)
		stop_countdown_watch()
		return
	if(applied[key])
		revert(key)

/datum/maverick_cheats/proc/announce(mob/user, action, key)
	message_admins("[key_name_admin(user)] [action] the \"[cheat_name(key)]\" cheat.")
	log_admin("[key_name(user)] [action] the \"[cheat_name(key)]\" cheat.")

/datum/maverick_cheats/proc/on_round_starting(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING)
	INVOKE_ASYNC(src, PROC_REF(apply_pending))

/datum/maverick_cheats/proc/apply_pending()
	for(var/key in active)
		if(key != CHEAT_COUNTDOWN && !applied[key])
			apply(key)

/// Puts a cheat's effect into the game. user, if given, hears about anything that went wrong.
/datum/maverick_cheats/proc/apply(key, mob/user)
	switch(key)
		if(CHEAT_POWER)
			for(var/obj/machinery/power/smes/smes as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/smes))
				if(!is_station_level(smes.z))
					continue
				smes_saved[WEAKREF(smes)] = list(smes.output_level, smes.output_attempt)
				smes.output_attempt = TRUE
				smes.output_level = CHEAT_SMES_OUTPUT
				smes.update_appearance()
		if(CHEAT_RESEARCH)
			var/datum/techweb/science_web = locate(/datum/techweb/science) in SSresearch.techwebs
			if(!science_web)
				to_chat(user, span_warning("No station research network found."))
				return
			science_web.adjust_points(TECHWEB_POINT_TYPE_GENERIC, CHEAT_RESEARCH_POINTS)
			research_added += CHEAT_RESEARCH_POINTS
		if(CHEAT_CARGO)
			var/datum/bank_account/cargo_budget = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if(!cargo_budget)
				to_chat(user, span_warning("No cargo budget found."))
				return
			cargo_budget.adjust_money(CHEAT_CARGO_CREDITS)
			cargo_added += CHEAT_CARGO_CREDITS
		if(CHEAT_SILO)
			var/obj/machinery/ore_silo/silo = GLOB.ore_silo_default
			if(!silo)
				to_chat(user, span_warning("This station has no ore silo."))
				return
			for(var/datum/material/mat as anything in silo.materials.materials.Copy())
				silo_added[mat] += silo.materials.insert_amount_mat(CHEAT_SILO_SHEETS * SHEET_MATERIAL_AMOUNT, mat)
	applied[key] = TRUE

/// Takes a cheat's effect back out of the game
/datum/maverick_cheats/proc/revert(key)
	applied -= key
	switch(key)
		if(CHEAT_POWER)
			for(var/datum/weakref/smes_ref as anything in smes_saved)
				var/obj/machinery/power/smes/smes = smes_ref.resolve()
				if(!smes)
					continue
				var/list/saved = smes_saved[smes_ref]
				smes.output_level = saved[1]
				smes.output_attempt = saved[2]
				smes.update_appearance()
			smes_saved.Cut()
		if(CHEAT_RESEARCH)
			var/datum/techweb/science_web = locate(/datum/techweb/science) in SSresearch.techwebs
			if(science_web)
				var/points_left = science_web.research_points[TECHWEB_POINT_TYPE_GENERIC]
				science_web.adjust_points(TECHWEB_POINT_TYPE_GENERIC, -min(research_added, points_left))
			research_added = 0
		if(CHEAT_CARGO)
			var/datum/bank_account/cargo_budget = SSeconomy.get_dep_account(ACCOUNT_CAR)
			var/credits_back = min(cargo_added, cargo_budget?.account_balance)
			if(credits_back > 0)
				cargo_budget.adjust_money(-credits_back)
			cargo_added = 0
		if(CHEAT_SILO)
			var/obj/machinery/ore_silo/silo = GLOB.ore_silo_default
			if(silo)
				for(var/datum/material/mat as anything in silo_added)
					var/sheets_back = min(silo_added[mat], silo.materials.get_material_amount(mat))
					if(sheets_back > 0)
						silo.materials.use_amount_mat(sheets_back, mat)
			silo_added.Cut()

/datum/maverick_cheats/proc/start_countdown_watch()
	if(SSticker.current_state > GAME_STATE_PREGAME)
		return
	deltimer(countdown_timer)
	countdown_timer = addtimer(CALLBACK(src, PROC_REF(check_countdown)), 1 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/datum/maverick_cheats/proc/stop_countdown_watch()
	deltimer(countdown_timer)
	countdown_timer = null
	if(countdown_set && SSticker.current_state <= GAME_STATE_PREGAME)
		SSticker.start_immediately = FALSE
	countdown_set = FALSE

/// Starts the round once a readied admin is in the lobby
/datum/maverick_cheats/proc/check_countdown()
	if(SSticker.current_state > GAME_STATE_PREGAME)
		deltimer(countdown_timer)
		countdown_timer = null
		return
	if(SSticker.current_state != GAME_STATE_PREGAME || countdown_set)
		return
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.ready == PLAYER_READY_TO_PLAY && player.client?.holder)
			SSticker.start_immediately = TRUE
			countdown_set = TRUE
			return

/datum/maverick_cheats/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/datum/maverick_cheats/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MaverickCheatEngine")
		ui.open()

/datum/maverick_cheats/ui_data(mob/user)
	var/list/cheats = list()
	for(var/list/cheat as anything in cheat_list())
		var/key = cheat["key"]
		var/list/row = cheat.Copy()
		row["active"] = !!active[key]
		row["waiting"] = active[key] && !applied[key] && key != CHEAT_COUNTDOWN
		cheats += list(row)
	return list(
		"cheats" = cheats,
		"round_started" = SSticker.HasRoundStarted(),
	)

/datum/maverick_cheats/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	switch(action)
		if("toggle")
			var/key = params["key"]
			for(var/list/cheat as anything in cheat_list())
				if(cheat["key"] == key)
					toggle(key, user)
					return TRUE
		if("toggle_all")
			toggle_all(user)
			return TRUE

/// While the power cheat is on, station SMES units give power without losing charge
/obj/machinery/power/smes/adjust_charge(charge_adjust)
	if(GLOB.maverick_cheats.applied[CHEAT_POWER] && is_station_level(z))
		return charge_adjust < 0 ? -charge_adjust : 0
	return ..()

ADMIN_VERB(debug_cheats, R_DEBUG, "Debug Cheats", "Opens the Cheat Engine playtest panel.", ADMIN_CATEGORY_DEBUG)
	GLOB.maverick_cheats.ui_interact(user.mob)

#undef CHEAT_POWER
#undef CHEAT_RESEARCH
#undef CHEAT_CARGO
#undef CHEAT_SILO
#undef CHEAT_COUNTDOWN
#undef CHEAT_RESEARCH_POINTS
#undef CHEAT_CARGO_CREDITS
#undef CHEAT_SILO_SHEETS
#undef CHEAT_SMES_OUTPUT
