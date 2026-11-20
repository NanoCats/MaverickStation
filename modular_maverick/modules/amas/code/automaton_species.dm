/// The body AMAS automatons are built on. A human frame with full cybernetics, head and torso included.
/datum/species/android/amas_automaton
	name = "Automaton"
	id = SPECIES_AMAS_AUTOMATON
	changesource_flags = MIRROR_BADMIN
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/robot,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/robot,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/robot/advanced,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/robot/advanced,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/robot/advanced,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/robot/advanced,
	)

/datum/species/android/amas_automaton/get_species_description()
	return "Synthetic staff built by Micron Control Systems to fill crew shortages on the frontier."

/datum/species/android/amas_automaton/get_species_lore()
	return list(AMAS_AUTOMATON_FLAVOR_TEXT)

/// Returns TRUE if the mob is an AMAS automaton
/proc/is_amas_automaton(mob/living/target)
	if(!ishuman(target))
		return FALSE
	var/mob/living/carbon/human/human_target = target
	return istype(human_target.dna?.species, /datum/species/android/amas_automaton)
