/// The shared succubus milk datum. Bimbo growth borrows its growth procs so the text matches the chem.
/datum/component/bimbo/proc/succubus_milk()
	RETURN_TYPE(/datum/reagent/drug/aphrodisiac/succubus_milk)
	return GLOB.chemical_reagents_list[/datum/reagent/drug/aphrodisiac/succubus_milk]

/// Quirk holders chose the size floor. Everyone else needs the breast enlargement pref.
/datum/component/bimbo/proc/can_grow()
	if(from_quirk)
		return TRUE
	var/mob/living/carbon/human/holder = parent
	return holder.mob_consents(/datum/preference/toggle/erp/breast_enlargement)

/**
 * Raises breast and butt size to the floor for the current intensity.
 * Only touches organs the holder already has. Never shrinks anything.
 * instant snaps straight to the floor, otherwise it grows one size per call.
 */
/datum/component/bimbo/proc/enforce_size_floor(instant = FALSE)
	if(!can_grow())
		return
	var/mob/living/carbon/human/holder = parent
	var/fraction = get_intensity() / BIMBO_MAX_INTENSITY
	var/changed = FALSE

	var/obj/item/organ/genital/breasts/breasts = holder.get_organ_slot(ORGAN_SLOT_BREASTS)
	if(breasts && grow_to_floor(breasts, round(BIMBO_BREAST_FLOOR_MAX * fraction), instant))
		changed = TRUE
		if(!instant)
			succubus_milk().growth_to_chat(holder, breasts)

	var/obj/item/organ/genital/butt/butt = holder.get_organ_slot(ORGAN_SLOT_BUTT)
	if(butt && grow_to_floor(butt, round(BIMBO_BUTT_FLOOR_MAX * fraction), instant))
		changed = TRUE
		if(!instant)
			holder.visible_message(
				span_userlove("[holder]'s hips round out, a little curvier than a moment ago."),
				span_userlove("Your hips feel heavier[holder.w_uniform ? ", and your clothes hug them tighter" : ""]."),
			)

	if(changed)
		holder.update_body()

/// Returns TRUE if the genital grew.
/datum/component/bimbo/proc/grow_to_floor(obj/item/organ/genital/genital, floor, instant)
	if(genital.genital_size >= floor)
		return FALSE
	genital.set_size(instant ? floor : genital.genital_size + 1)
	genital.update_sprite_suffix()
	return TRUE

/// Puts the lipstick back on if it was washed off or changed.
/datum/component/bimbo/proc/apply_lipstick()
	var/mob/living/carbon/human/holder = parent
	if(holder.lip_style && holder.lip_color == lipstick_color)
		return
	if(!holder.get_bodypart(BODY_ZONE_HEAD))
		return
	holder.update_lips("lipstick", lipstick_color)
	holder.visible_message(
		span_userlove("[holder]'s lips shimmer as a fresh coat of glossy lipstick appears on them."),
		span_userlove("Your lips tingle as a fresh coat of lipstick blooms across them."),
	)

/// The ray's "Barbie" profile. Each part checks its own existing pref.
/datum/component/bimbo/proc/barbie_conversion(hair_color)
	var/mob/living/carbon/human/holder = parent

	if(hair_color && holder.hair_color != hair_color && holder.get_bodypart(BODY_ZONE_HEAD))
		holder.set_haircolor(hair_color, update = TRUE)
		holder.visible_message(
			span_userlove("[holder]'s hair shimmers and turns a glossy new shade."),
			span_userlove("Your scalp tingles as your hair changes color."),
		)

	// set_gender checks the gender change pref itself
	holder.set_gender(FEMALE)
	if(holder.gender == FEMALE && holder.physique != FEMALE)
		holder.physique = FEMALE
		holder.update_body()
		holder.update_appearance(UPDATE_OVERLAYS)
		holder.visible_message(
			span_userlove("[holder]'s figure softens and reshapes into a curvier silhouette."),
			span_userlove("Your whole body tingles as your figure softens and curves."),
		)

	if(holder.get_organ_slot(ORGAN_SLOT_BREASTS) || !holder.dna?.mutant_bodyparts[ORGAN_SLOT_BREASTS])
		return
	// Same growth, text and pref check as a succubus milk overdose
	succubus_milk().create_breasts(holder)

/**
 * One ray hit or hexacrocin overdose roll.
 * Needs the bimbofication pref. Returns TRUE if anything happened.
 */
/proc/bimbo_hit(mob/living/carbon/human/target, barbie = FALSE, hair_color = null)
	if(!istype(target) || !target.mob_consents(/datum/preference/toggle/erp/bimbofication))
		return FALSE
	var/datum/component/bimbo/bimbo = target.GetComponent(/datum/component/bimbo) || target.AddComponent(/datum/component/bimbo)
	if(!bimbo)
		return FALSE
	if(barbie)
		bimbo.barbie_conversion(hair_color)
	bimbo.adjust_bonus(BIMBO_HIT_INTENSITY)
	target.visible_message(
		span_userlove("[target] blinks, then breaks into a bubbly, airheaded giggle."),
		span_userlove("Your head feels light and bubbly."),
	)
	return TRUE
