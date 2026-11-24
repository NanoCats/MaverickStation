/// Oldest age the window offers. Answers above MAVERICK_AGE_GATE_MAXIMUM_AGE (config) are banned as implausible.
#define AGE_GATE_MAX_AGE 120
/// The privacy policy shown in the welcome window.
#define PRIVACY_POLICY_FILE "config/maverick/privacy_policy.txt"

/// The welcome window: privacy policy plus, if still needed, the date of birth. One per player, reopens itself until answered.
/datum/age_gate_prompt
	/// The client being asked
	var/client/owner
	/// ckey of the client being asked, kept so we can clean up after a disconnect
	var/owner_ckey
	/// Whether this window asks for a date of birth. If not, it only asks for agreement to the policy.
	var/ask_age = FALSE
	/// Set once the player has answered, so closing the window afterwards does not reopen it
	var/answered = FALSE

/datum/age_gate_prompt/New(client/owner)
	. = ..()
	src.owner = owner
	owner_ckey = owner.ckey
	ask_age = SSage_gate.needs_age(owner)

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

/datum/age_gate_prompt/ui_data(mob/user)
	return list("ask_age" = ask_age)

/datum/age_gate_prompt/ui_static_data(mob/user)
	// The window works out the age against the server's date so the date of birth never leaves the client.
	return list(
		"policy_text" = privacy_policy_text(),
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
	var/client/player = owner
	if(!ask_age)
		answered = TRUE
		ui.close()
		SSage_gate.record_policy(player)
		to_chat(player, span_notice("Thanks. Welcome back."))
		return TRUE

	var/age = text2num(params["age"])
	if(!isnum(age) || age != round(age) || age < 0 || age > AGE_GATE_MAX_AGE)
		return
	answered = TRUE
	ui.close()
	SSage_gate.handle_answer(player, age)
	return TRUE

/datum/age_gate_prompt/ui_close(mob/user)
	. = ..()
	var/client/player = owner
	var/reopen = !answered && player && player.mob == user
	qdel(src)
	if(!reopen)
		return
	to_chat(player, span_warning("You need to finish the welcome window before you can play."))
	INVOKE_ASYNC(SSage_gate, TYPE_PROC_REF(/datum/controller/subsystem/age_gate, open_prompt), player)

/// Reads the privacy policy and fills in the numbers that come from config, so the text cannot drift from what the server does.
/proc/privacy_policy_text()
	var/text = file2text(PRIVACY_POLICY_FILE)
	if(!text)
		return "The privacy policy file is missing. Please tell an admin."
	text = replacetext(text, "%POLICY_VERSION%", "[CONFIG_GET(number/maverick_privacy_policy_version)]")
	text = replacetext(text, "%MINIMUM_AGE%", "[CONFIG_GET(number/maverick_age_gate_minimum_age)]")
	text = replacetext(text, "%LOG_RETENTION_DAYS%", "[CONFIG_GET(number/maverick_log_retention_days)]")
	return text

#undef AGE_GATE_MAX_AGE
#undef PRIVACY_POLICY_FILE
