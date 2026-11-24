/**
 * The AMAS core.
 *
 * AMAS installs one in an unused secondary AI spot at roundstart. For now it only announces itself.
 * Door requests, research and the rest of the station AI work come later.
 *
 * Like a real AI, it dies when it takes enough damage: the screen goes dark and it stops working, but the core stays.
 * Wrecking a dead core completely still destroys it.
 *
 * Sprite: the "ai-girl" AI display from /vg/station, by way of Monkestation.
 */
/obj/machinery/amas_ai_core
	name = "AMAS core"
	desc = "A Micron Control Systems station intelligence, installed by AMAS to manage the station when no AI is on duty. It looks happy to see you."
	icon = 'modular_maverick/icons/mob/silicon/amas_ai.dmi'
	icon_state = "ai-girl"
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	integrity_failure = 0.5
	use_power = IDLE_POWER_USE
	/// Set when the core has been knocked offline
	var/dead = FALSE

/obj/machinery/amas_ai_core/examine(mob/user)
	. = ..()
	if(dead)
		. += span_warning("Its screen is dark. It is offline.")

/obj/machinery/amas_ai_core/atom_break(damage_flag)
	. = ..()
	die()

/// Knocks the core offline the way an AI dies: dead screen, no more work, the core stays put
/obj/machinery/amas_ai_core/proc/die()
	if(dead)
		return
	dead = TRUE
	icon = 'icons/mob/silicon/ai.dmi'
	icon_state = "ai_dead"
	playsound(src, 'sound/machines/beep/twobeep.ogg', 50, FALSE)
	visible_message(span_warning("[src]'s screen flickers and goes dark."))
	if(SSticker.HasRoundStarted())
		minor_announce("AMAS core offline.", "AMAS")
	log_game("AMAS: AI core knocked offline at [AREACOORD(src)].")

/obj/machinery/amas_ai_core/proc/announce_online()
	minor_announce("AMAS core online! Have a great shift!", "AMAS")

/// Puts the AMAS core on the first free secondary AI spot. Does nothing if every spot is taken.
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
