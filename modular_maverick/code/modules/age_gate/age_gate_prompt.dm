/// Oldest age the age gate window will accept. Anything older is treated as a typo.
#define AGE_GATE_MAX_AGE 120

/// The age gate window. One per player, reopens itself until answered.
/datum/age_gate_prompt
	/// The client being asked
	var/client/owner
	/// ckey of the client being asked, kept so we can clean up after a disconnect
	var/owner_ckey
	/// Set once the player has answered, so closing the window afterwards does not reopen it
	var/answered = FALSE

/datum/age_gate_prompt/New(client/owner)
	. = ..()
	src.owner = owner
	owner_ckey = owner.ckey

/datum/age_gate_prompt/Destroy()
	if(SSage_gate.open_prompts[owner_ckey] == src)
		SSage_gate.open_prompts -= owner_ckey
	owner = null
	return ..()

/datum/age_gate_prompt/ui_state(mob/user)
	return GLOB.always_state

/datum/age_gate_prompt/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "AgeGate")
	ui.set_autoupdate(FALSE)
	ui.open()

/datum/age_gate_prompt/ui_static_data(mob/user)
	// The window works out the age against the server's date so the date of birth never leaves the client.
	return list(
		"current_year" = text2num(time2text(world.realtime, "YYYY")),
		"current_month" = text2num(time2text(world.realtime, "MM")),
		"current_day" = text2num(time2text(world.realtime, "DD")),
		"max_age" = AGE_GATE_MAX_AGE,
	)

/datum/age_gate_prompt/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action != "submit" || answered || !owner)
		return
	var/age = text2num(params["age"])
	if(!isnum(age) || age != round(age) || age < 0 || age > AGE_GATE_MAX_AGE)
		return

	answered = TRUE
	var/client/player = owner
	ui.close()
	if(age >= CONFIG_GET(number/age_gate_minimum_age))
		SSage_gate.record_pass(player)
		to_chat(player, span_notice("Thanks. Welcome aboard."))
	else
		SSage_gate.ban_underage(player)
	return TRUE

/datum/age_gate_prompt/ui_close(mob/user)
	. = ..()
	var/client/player = owner
	var/reopen = !answered && player && player.mob == user
	qdel(src)
	if(!reopen)
		return
	to_chat(player, span_warning("You need to enter your date of birth before you can play."))
	SSage_gate.open_prompt(player)

#undef AGE_GATE_MAX_AGE
