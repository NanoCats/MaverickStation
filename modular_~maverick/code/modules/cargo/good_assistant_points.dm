// Good Assistant Points are off unless the Maverick config turns them on.
// Assistants start without a punchcard, punchcards and redemption machines delete themselves,
// and the machine board can't be printed. Nothing upstream is removed.

/// Turns the Good Assistant Points punchcard program on
/datum/config_entry/flag/maverick_good_assistant_points

/datum/outfit/job/assistant/pre_equip(mob/living/carbon/human/target, visualsOnly)
	. = ..()
	if(!CONFIG_GET(flag/maverick_good_assistant_points))
		backpack_contents -= /obj/item/gbp_punchcard/starting

/obj/item/gbp_punchcard/Initialize(mapload)
	. = ..()
	if(!CONFIG_GET(flag/maverick_good_assistant_points))
		return INITIALIZE_HINT_QDEL

/obj/machinery/gbp_redemption/Initialize(mapload)
	. = ..()
	if(!CONFIG_GET(flag/maverick_good_assistant_points))
		return INITIALIZE_HINT_QDEL

/datum/design/board/gbp_machine/New()
	. = ..()
	if(!CONFIG_GET(flag/maverick_good_assistant_points))
		build_type = NONE
