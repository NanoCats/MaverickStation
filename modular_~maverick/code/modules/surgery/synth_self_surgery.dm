/**
 * Synthetics can already do their mechanic maintenance on themselves, so the
 * rest of the surgery list follows suit. No skillchip needed and no self-surgery
 * penalty; the skillchip route stays as it is for everyone else.
 */
/datum/surgery_operation/proc/synth_can_self_operate(mob/living/surgeon)
	return HAS_TRAIT(surgeon, TRAIT_SYNTHETIC)
