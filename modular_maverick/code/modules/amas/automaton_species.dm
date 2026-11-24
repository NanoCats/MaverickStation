/// The body AMAS automatons are built on. A human frame with full cybernetics, head and torso included.
/datum/species/android/amas_automaton
	name = "Automaton"
	id = SPECIES_AMAS_AUTOMATON
	changesource_flags = MIRROR_BADMIN
	// Synth brain and synthetic parts, so the same reboot surgery that revives synths revives automatons
	mutantbrain = /obj/item/organ/brain/synth
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/robot/android/amas_automaton,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/robot/android/amas_automaton,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/robot/advanced/amas_automaton,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/robot/advanced/amas_automaton,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/robot/advanced/amas_automaton,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/robot/advanced/amas_automaton,
	)

/obj/item/bodypart/head/robot/android/amas_automaton
	bodytype = BODYTYPE_ROBOTIC | BODYTYPE_SYNTHETIC

/obj/item/bodypart/chest/robot/android/amas_automaton
	bodytype = BODYTYPE_ROBOTIC | BODYTYPE_SYNTHETIC

// Robotic limbs normally survive a species change. Species limbs must not, or the old limbs stay stuck on the mob.
/obj/item/bodypart/arm/left/robot/advanced/amas_automaton
	bodytype = BODYTYPE_ROBOTIC | BODYTYPE_SYNTHETIC
	change_exempt_flags = NONE

/obj/item/bodypart/arm/right/robot/advanced/amas_automaton
	bodytype = BODYTYPE_ROBOTIC | BODYTYPE_SYNTHETIC
	change_exempt_flags = NONE

/obj/item/bodypart/leg/left/robot/advanced/amas_automaton
	bodytype = BODYTYPE_ROBOTIC | BODYTYPE_SYNTHETIC
	change_exempt_flags = NONE

/obj/item/bodypart/leg/right/robot/advanced/amas_automaton
	bodytype = BODYTYPE_ROBOTIC | BODYTYPE_SYNTHETIC
	change_exempt_flags = NONE

/datum/species/android/amas_automaton/get_species_description()
	return "Synthetic staff built by Micron Control Systems to fill crew shortages on the frontier."

/datum/species/android/amas_automaton/get_species_lore()
	return list(AMAS_AUTOMATON_FLAVOR_TEXT)

/datum/species/android/amas_automaton/on_species_gain(mob/living/carbon/human/human_who_gained_species, datum/species/old_species, pref_load, regenerate_icons = TRUE, replace_missing = TRUE)
	. = ..()
	RegisterSignal(human_who_gained_species, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/species/android/amas_automaton/on_species_loss(mob/living/carbon/human/human, datum/species/new_species, pref_load)
	UnregisterSignal(human, COMSIG_ATOM_EXAMINE)
	return ..()

/// Every automaton is clearly marked on examine, so nobody mistakes one for a crewmember
/datum/species/android/amas_automaton/proc/on_examine(mob/living/carbon/human/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("[source.p_They()] [source.p_are()] an AMAS automaton, built by Micron Control Systems.")

/// Returns TRUE if the mob is an AMAS automaton
/proc/is_amas_automaton(mob/living/target)
	if(!ishuman(target))
		return FALSE
	var/mob/living/carbon/human/human_target = target
	return istype(human_target.dna?.species, /datum/species/android/amas_automaton)
