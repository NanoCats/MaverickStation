ADMIN_VERB(amas_status, R_DEBUG, "AMAS Status", "Show what each AMAS watchdog measures and every automaton in the round.", ADMIN_CATEGORY_DEBUG)
	if(!SSamas.initialized || !SSamas.can_fire)
		to_chat(user, span_warning("AMAS is not running."))
		return

	var/list/lines = list("<b>AMAS watchdogs</b>")
	for(var/watchdog_type in SSamas.watchdogs)
		var/datum/amas_watchdog/watchdog = SSamas.watchdogs[watchdog_type]
		lines += watchdog.get_status_line()

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
