ADMIN_VERB(amas_status, R_DEBUG, "AMAS Status", "Show what each AMAS watchdog measures and every automaton in the round.", ADMIN_CATEGORY_DEBUG)
	if(!SSamas.initialized || !SSamas.can_fire)
		to_chat(user, span_warning("AMAS is not running."))
		return

	var/list/lines = list("<b>AMAS watchdogs</b>")
	for(var/watchdog_type in SSamas.watchdogs)
		var/datum/amas_watchdog/watchdog = SSamas.watchdogs[watchdog_type]
		lines += watchdog.get_status_line()

	lines += "<b>Units: [length(SSamas.units)]</b>"
	for(var/mob/living/silicon/robot/unit as anything in SSamas.units)
		var/datum/amas_brain/brain = SSamas.units[unit]
		var/doing = brain.current_task ? "working on [brain.current_task.target] at [AREACOORD(brain.current_task.target)]" : "on standby"
		lines += "[unit.real_name] [unit.stat == DEAD ? "DEAD" : doing], cell [unit.cell ? round(unit.cell.percent()) : 0]%"

	lines += "<b>Automatons: [length(SSamas.automatons)]</b>"
	for(var/mob/living/carbon/human/automaton as anything in SSamas.automatons)
		lines += "[automaton.real_name] ([automaton.job]) [automaton.stat == DEAD ? "DEAD" : "active"] at [AREACOORD(automaton)]"

	to_chat(user, boxed_message(jointext(lines, "\n")))
	BLACKBOX_LOG_ADMIN_VERB("AMAS Status")

ADMIN_VERB(amas_spawn_automaton, R_SPAWN, "Spawn AMAS Automaton", "Build an AMAS automaton for a job where you stand. Takes no job slot.", ADMIN_CATEGORY_DEBUG)
	var/list/jobs_by_title = list()
	for(var/datum/job/job as anything in SSjob.joinable_occupations)
		jobs_by_title[job.title] = job

	var/picked_title = tgui_input_list(user, "Which job?", "Spawn AMAS Automaton", sort_list(jobs_by_title))
	var/datum/job/picked_job = jobs_by_title[picked_title]
	if(isnull(picked_job) || isnull(user.mob))
		return

	var/mob/living/carbon/human/automaton = create_amas_automaton(get_turf(user.mob), picked_job)
	log_admin("[key_name(user)] spawned AMAS automaton [automaton.real_name] ([picked_job.title]) at [AREACOORD(automaton)].")
	message_admins("[key_name_admin(user)] spawned AMAS automaton [automaton.real_name] ([picked_job.title]) at [ADMIN_VERBOSEJMP(automaton)].")
	BLACKBOX_LOG_ADMIN_VERB("Spawn AMAS Automaton")

ADMIN_VERB(amas_build_unit, R_SPAWN, "Build AMAS Unit", "Have AMAS build the cyborg for a watchdog right now, skipping its warmup and grace period.", ADMIN_CATEGORY_DEBUG)
	var/list/watchdogs_by_name = list()
	for(var/watchdog_type in SSamas.watchdogs)
		var/datum/amas_watchdog/watchdog = SSamas.watchdogs[watchdog_type]
		if(watchdog.dispatch_unit_model)
			watchdogs_by_name[watchdog.name] = watchdog
	if(!length(watchdogs_by_name))
		to_chat(user, span_warning("No AMAS watchdog has a cyborg yet."))
		return

	var/picked_name = tgui_input_list(user, "Build a unit for which function?", "Build AMAS Unit", sort_list(watchdogs_by_name))
	var/datum/amas_watchdog/picked = watchdogs_by_name[picked_name]
	if(isnull(picked))
		return

	var/mob/living/silicon/robot/unit = SSamas.dispatch_unit(picked)
	if(isnull(unit))
		to_chat(user, span_warning("AMAS built nothing. A unit for [picked.name] may already be working, or there is no powered cyborg factory."))
		return
	log_admin("[key_name(user)] had AMAS build [unit.real_name] for [picked.name].")
	message_admins("[key_name_admin(user)] had AMAS build [unit.real_name] for [picked.name] at [ADMIN_VERBOSEJMP(unit)].")
	BLACKBOX_LOG_ADMIN_VERB("Build AMAS Unit")
