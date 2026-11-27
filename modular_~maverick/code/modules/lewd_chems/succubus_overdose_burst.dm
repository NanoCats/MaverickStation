/// How much breast milk spills on the floor when a succubus milk overdose bursts someone's clothes
#define SUCCUBUS_BURST_MILK_SPILL 5

/datum/reagent/drug/aphrodisiac/succubus_milk
	/// TRUE once this overdose has burst the drinker out of their clothes. Once per overdose.
	var/burst_clothes = FALSE

/datum/reagent/drug/aphrodisiac/succubus_milk/overdose_effects(mob/living/carbon/human/exposed_mob)
	. = ..()
	if(burst_clothes || !istype(exposed_mob) || !exposed_mob.get_organ_slot(ORGAN_SLOT_BREASTS))
		return
	if(!exposed_mob.mob_consents(/datum/preference/toggle/erp/breast_enlargement))
		return
	burst_clothes = TRUE
	burst_out_of_clothes(exposed_mob)

/datum/reagent/drug/aphrodisiac/succubus_milk/on_mob_end_metabolize(mob/living/affected_mob)
	. = ..()
	burst_clothes = FALSE

/**
 * The chest swells until the clothes over it rip apart, and a little milk spills on the floor.
 *
 * Shreds the jumpsuit and any suit over the chest, the same way heavy damage does, so they can be mended.
 * Never touches pressure-proof suits (space suits, MODsuits), so nobody gets popped in space.
 */
/datum/reagent/drug/aphrodisiac/succubus_milk/proc/burst_out_of_clothes(mob/living/carbon/human/exposed_mob)
	var/list/obj/item/clothing/to_burst = list()
	for(var/obj/item/clothing/worn in list(exposed_mob.w_uniform, exposed_mob.wear_suit))
		if(!(worn.body_parts_covered & CHEST))
			continue
		if((worn.clothing_flags & STOPSPRESSUREDAMAGE) || (worn.resistance_flags & INDESTRUCTIBLE) || !worn.uses_integrity)
			continue
		to_burst += worn
	if(!length(to_burst))
		return

	// Name every article that rips, outermost first: "labcoat and grey jumpsuit"
	var/list/article_names = list()
	for(var/i in length(to_burst) to 1 step -1)
		var/obj/item/clothing/worn = to_burst[i]
		article_names += worn.name
	var/articles = english_list(article_names)
	exposed_mob.visible_message(
		span_userlove("[exposed_mob]'s [pick(bigger_boob_text_list)] swell against [exposed_mob.p_their()] [articles] until the fabric gives way with a loud rip!"),
		span_userlove("Your [pick(bigger_boob_text_list)] swell against your [articles] until the fabric gives way with a loud rip!"),
	)
	playsound(exposed_mob, 'sound/effects/cloth_rip.ogg', 50, TRUE)
	for(var/obj/item/clothing/worn as anything in to_burst)
		worn.update_integrity(0)
		worn.atom_destruction(MELEE)

	var/turf/spill_turf = get_turf(exposed_mob)
	if(!isopenturf(spill_turf))
		return
	spill_turf.add_liquid(/datum/reagent/consumable/breast_milk, SUCCUBUS_BURST_MILK_SPILL)
	exposed_mob.visible_message(span_notice("A little milk splashes onto the floor."), vision_distance = COMBAT_MESSAGE_RANGE)

#undef SUCCUBUS_BURST_MILK_SPILL
