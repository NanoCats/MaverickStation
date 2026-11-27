/// Every cyborg factory in the world
GLOBAL_LIST_EMPTY(cyborg_factories)

/**
 * The cyborg factory.
 *
 * Cyborgs always came out of thin air on the AI satellite. This pad is where they come from now.
 * One is placed on every cyborg spawn point at mapload, so no map edits are needed.
 * Player cyborgs, roundstart and latejoin, are built here. AMAS builds its own units here too.
 *
 * Sprite: the Automatic Robotic Factory 5000 from the malf AI module, which already looks the part.
 */
/obj/machinery/cyborg_factory
	name = "cyborg factory"
	desc = "A Micron Control Systems assembly line. Frames, wiring and plating go in one end, finished cyborgs come out the other."
	icon = 'icons/obj/machines/recycling.dmi'
	icon_state = "separator-AO1"
	density = FALSE
	anchored = TRUE
	layer = ABOVE_ALL_MOB_LAYER
	plane = ABOVE_GAME_PLANE
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 5
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/machinery/cyborg_factory/Initialize(mapload)
	. = ..()
	GLOB.cyborg_factories += src

/obj/machinery/cyborg_factory/Destroy()
	GLOB.cyborg_factories -= src
	return ..()

/obj/machinery/cyborg_factory/update_icon_state()
	icon_state = is_operational ? "separator-AO1" : "separator-AO0"
	return ..()

/// Plays the assembly flourish over a cyborg that was just built here
/obj/machinery/cyborg_factory/proc/show_assembly(mob/living/silicon/robot/new_borg)
	update_use_power(ACTIVE_POWER_USE)
	playsound(src, 'sound/items/tools/rped.ogg', 50, TRUE)
	do_sparks(3, FALSE, src)
	visible_message(span_notice("[src] whirs and rolls out a freshly assembled [new_borg]."))
	addtimer(CALLBACK(src, PROC_REF(finish_assembly)), 2 SECONDS)

/obj/machinery/cyborg_factory/proc/finish_assembly()
	update_use_power(IDLE_POWER_USE)

/**
 * Builds an AMAS unit of the given model on this pad and starts its brain.
 *
 * AMAS units are plain cyborgs with no AI link and the default lawset. No player controls them.
 */
/obj/machinery/cyborg_factory/proc/build_amas_unit(model_type, datum/amas_brain/brain_type)
	var/mob/living/silicon/robot/unit = new model_type(loc, null, null, FALSE, FALSE)
	var/prefix = uppertext(copytext(unit.model.name, 1, 4))
	unit.fully_replace_character_name(unit.real_name, "AMAS [prefix]-[rand(100, 999)]")
	unit.custom_name = unit.real_name
	new brain_type(unit, src)
	show_assembly(unit)
	log_game("AMAS: built [unit.real_name] at [AREACOORD(src)].")
	return unit

/// Places a factory on every cyborg spawn point
/obj/effect/landmark/start/cyborg/Initialize(mapload)
	. = ..()
	if(!mapload || (locate(/obj/machinery/cyborg_factory) in loc))
		return
	new /obj/machinery/cyborg_factory(loc)

/datum/job/cyborg/after_spawn(mob/living/spawned, client/player_client)
	. = ..()
	var/obj/machinery/cyborg_factory/factory = locate() in get_turf(spawned)
	factory?.show_assembly(spawned)
