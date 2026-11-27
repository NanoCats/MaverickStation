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
	/// Every AMAS cyborg in the round, and the brain running it
	var/list/mob/living/silicon/robot/units = list()

/datum/controller/subsystem/amas/Initialize()
	if(CONFIG_GET(flag/maverick_amas_disabled))
		can_fire = FALSE
		return SS_INIT_NO_NEED

	for(var/watchdog_type in subtypesof(/datum/amas_watchdog))
		watchdogs[watchdog_type] = new watchdog_type
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(install_ai_core))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/amas/fire(resumed)
	for(var/watchdog_type in watchdogs)
		var/datum/amas_watchdog/watchdog = watchdogs[watchdog_type]
		watchdog.evaluate()

/datum/controller/subsystem/amas/stat_entry(msg)
	msg = "W:[length(watchdogs)]|A:[length(automatons)]|U:[length(units)]"
	return ..()

/**
 * Called by a watchdog when its function has been short for longer than its grace period.
 *
 * If the watchdog has a cyborg for the job and no unit of that model is already working, AMAS builds one at a cyborg factory.
 * Otherwise the shortfall is only logged, since automaton dispatch is not built yet.
 */
/datum/controller/subsystem/amas/proc/report_shortfall(datum/amas_watchdog/watchdog)
	if(watchdog.shortfall_reported)
		return
	watchdog.shortfall_reported = TRUE
	if(dispatch_unit(watchdog))
		return
	log_game("AMAS: shortfall in [watchdog.name] ([watchdog.status_text]). Would dispatch: [watchdog.dispatch_job ? initial(watchdog.dispatch_job.title) : "nothing"].")

/// Builds a cyborg for the watchdog's function. Returns the unit, or null if none was built.
/datum/controller/subsystem/amas/proc/dispatch_unit(datum/amas_watchdog/watchdog)
	if(isnull(watchdog.dispatch_unit_model))
		return null
	for(var/mob/living/silicon/robot/unit as anything in units)
		if(unit.type == watchdog.dispatch_unit_model && unit.stat != DEAD)
			return null
	var/obj/machinery/cyborg_factory/factory = pick_factory()
	if(isnull(factory))
		log_game("AMAS: shortfall in [watchdog.name], but there is no working cyborg factory.")
		return null
	var/mob/living/silicon/robot/unit = factory.build_amas_unit(watchdog.dispatch_unit_model, watchdog.dispatch_brain)
	minor_announce("[watchdog.name] is below target. [unit.real_name] has been built to help out.", "AMAS")
	return unit

/// A powered factory on a station level, or null
/datum/controller/subsystem/amas/proc/pick_factory()
	var/list/working = list()
	for(var/obj/machinery/cyborg_factory/factory as anything in GLOB.cyborg_factories)
		if(is_station_level(factory.z) && !(factory.machine_stat & NOPOWER))
			working += factory
	if(length(working))
		return pick(working)
	return null

/datum/controller/subsystem/amas/proc/register_unit(mob/living/silicon/robot/unit, datum/amas_brain/brain)
	units[unit] = brain
	RegisterSignal(unit, COMSIG_QDELETING, PROC_REF(on_unit_deleted))

/datum/controller/subsystem/amas/proc/on_unit_deleted(mob/living/silicon/robot/unit)
	SIGNAL_HANDLER
	units -= unit

/datum/controller/subsystem/amas/proc/register_automaton(mob/living/carbon/human/automaton)
	automatons += automaton
	RegisterSignal(automaton, COMSIG_QDELETING, PROC_REF(on_automaton_deleted))

/datum/controller/subsystem/amas/proc/on_automaton_deleted(mob/living/carbon/human/automaton)
	SIGNAL_HANDLER
	automatons -= automaton
