/**
 * AMAS: Automated Management And Staffing
 *
 * Watches the vital functions of the station and staffs them with automatons when the crew does not.
 * Automatons never take job slots and never count as players.
 */
SUBSYSTEM_DEF(amas)
	name = "AMAS"
	wait = 30 SECONDS
	runlevels = RUNLEVEL_GAME
	ss_flags = SS_BACKGROUND

	/// All watchdogs, keyed by type
	var/list/datum/amas_watchdog/watchdogs = list()
	/// Every automaton in the round
	var/list/mob/living/carbon/human/automatons = list()

/datum/controller/subsystem/amas/Initialize()
	if(CONFIG_GET(flag/amas_disabled))
		can_fire = FALSE
		return SS_INIT_NO_NEED

	for(var/watchdog_type in subtypesof(/datum/amas_watchdog))
		watchdogs[watchdog_type] = new watchdog_type
	return SS_INIT_SUCCESS

/datum/controller/subsystem/amas/fire(resumed)
	for(var/watchdog_type in watchdogs)
		var/datum/amas_watchdog/watchdog = watchdogs[watchdog_type]
		watchdog.evaluate()

/datum/controller/subsystem/amas/stat_entry(msg)
	msg = "W:[length(watchdogs)]|A:[length(automatons)]"
	return ..()

/**
 * Called by a watchdog when its function has been short for longer than its grace period.
 *
 * Dispatch is not built yet, so for now this only logs the shortfall once.
 */
/datum/controller/subsystem/amas/proc/report_shortfall(datum/amas_watchdog/watchdog)
	if(watchdog.shortfall_reported)
		return
	watchdog.shortfall_reported = TRUE
	log_game("AMAS: shortfall in [watchdog.name] ([watchdog.status_text]). Would dispatch: [watchdog.dispatch_job ? initial(watchdog.dispatch_job.title) : "nothing"].")

/datum/controller/subsystem/amas/proc/register_automaton(mob/living/carbon/human/automaton)
	automatons += automaton
	RegisterSignal(automaton, COMSIG_QDELETING, PROC_REF(on_automaton_deleted))

/datum/controller/subsystem/amas/proc/on_automaton_deleted(mob/living/carbon/human/automaton)
	SIGNAL_HANDLER
	automatons -= automaton
