/**
 * The AMAS AI core.
 *
 * AMAS installs one in an unused secondary AI spot at roundstart. For now it only announces itself.
 * Door requests, research and the rest of the station AI work come later.
 *
 * Sprite: the "ai-girl" AI display from /vg/station, by way of Monkestation.
 */
/obj/machinery/amas_ai_core
	name = "AMAS unit"
	desc = "A Micron Control Systems station intelligence, installed by AMAS to manage the station when no AI is on duty. It looks happy to see you."
	icon = 'modular_maverick/icons/mob/silicon/amas_ai.dmi'
	icon_state = "ai-girl"
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	use_power = IDLE_POWER_USE

/obj/machinery/amas_ai_core/proc/announce_online()
	minor_announce("AMAS Unit online! Have a great shift!", "AMAS")

/// Puts the AMAS AI core on the first free secondary AI spot. Does nothing if every spot is taken.
/datum/controller/subsystem/amas/proc/install_ai_core()
	SIGNAL_HANDLER
	for(var/obj/effect/landmark/start/ai/secondary/spawn_point in GLOB.start_landmarks_list)
		if(spawn_point.used)
			continue
		var/turf/core_turf = get_turf(spawn_point)
		if(locate(/mob/living/silicon/ai) in core_turf)
			continue
		spawn_point.used = TRUE
		var/obj/machinery/amas_ai_core/core = new(core_turf)
		core.announce_online()
		log_game("AMAS: AI core installed at [AREACOORD(core)].")
		return
	log_game("AMAS: no free secondary AI spot for the AI core.")
