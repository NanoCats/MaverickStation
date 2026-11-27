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

/**
 * Takes the next step of the THOT Accelerator makeover, one per call: hair, then figure, then breasts.
 * Each part checks its own pref. Returns TRUE if anything changed.
 */
/datum/component/bimbo/proc/makeover_step(hair_color)
	var/mob/living/carbon/human/holder = parent

	if(hair_color && holder.hair_color != hair_color && holder.get_bodypart(BODY_ZONE_HEAD))
		holder.set_haircolor(hair_color, update = TRUE)
		holder.visible_message(
			span_userlove("[holder]'s hair shimmers and turns a glossy new shade."),
			span_userlove("Your scalp tingles as your hair changes color."),
		)
		return TRUE

	if(holder.gender != FEMALE || holder.physique != FEMALE)
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
			return TRUE

	if(!holder.get_organ_slot(ORGAN_SLOT_BREASTS) && holder.dna?.mutant_bodyparts[ORGAN_SLOT_BREASTS])
		// Same growth, text and pref check as a succubus milk overdose
		return !!succubus_milk().create_breasts(holder)

	return FALSE

/**
 * The full makeover from a Bimbonium overdose.
 * The jumpsuit becomes a pink stripper outfit and the shoes become pink heels. Pocket, belt and ID contents stay put.
 * An advanced ID card gets the cosmetic "Slut" trim. Access is not touched.
 */
/datum/component/bimbo/proc/full_makeover()
	var/mob/living/carbon/human/holder = parent
	var/list/changed = list()

	var/obj/item/clothing/under/old_uniform = holder.w_uniform
	if(!istype(old_uniform, /obj/item/clothing/under/stripper_outfit/bimbo) && (!old_uniform || can_transform(old_uniform)))
		if(transform_worn(old_uniform, new /obj/item/clothing/under/stripper_outfit/bimbo(holder.drop_location()), ITEM_SLOT_ICLOTHING))
			changed += "clothes"

	var/obj/item/clothing/shoes/old_shoes = holder.shoes
	if(!istype(old_shoes, /obj/item/clothing/shoes/high_heels/bimbo) && (!old_shoes || can_transform(old_shoes)))
		if(transform_worn(old_shoes, new /obj/item/clothing/shoes/high_heels/bimbo(holder.drop_location()), ITEM_SLOT_FEET))
			changed += "shoes"

	var/obj/item/card/id/advanced/card = holder.wear_id?.GetID()
	if(istype(card) && card.trim_assignment_override != BIMBO_ID_ASSIGNMENT)
		SSid_access.apply_trim_override(card, /datum/id_trim/maverick_bimbo, check_forged = FALSE)
		card.update_label()
		card.update_icon()
		changed += "ID"

	if(!length(changed))
		return
	bimbo_heart_burst(get_turf(holder))
	holder.visible_message(
		span_userlove("In a flash of pink, [holder]'s [english_list(changed)] melt into something much sluttier!"),
		span_userlove("In a flash of pink, your [english_list(changed)] melt into something much sluttier!"),
	)

/// Worn items the makeover may replace. Never MOD pieces, no-drop items or anything indestructible.
/datum/component/bimbo/proc/can_transform(obj/item/worn)
	return !HAS_TRAIT(worn, TRAIT_NODROP) && !istype(worn, /obj/item/mod) && !(worn.resistance_flags & INDESTRUCTIBLE)

/// Swaps old_item (may be null) for new_item in a slot. Things that hang off the old item stay on the mob.
/datum/component/bimbo/proc/transform_worn(obj/item/old_item, obj/item/new_item, slot)
	var/mob/living/carbon/human/holder = parent
	if(old_item && !holder.temporarilyRemoveItemFromInventory(old_item, force = TRUE, idrop = FALSE))
		qdel(new_item)
		return FALSE
	if(!holder.equip_to_slot_if_possible(new_item, slot, disable_warning = TRUE, bypass_equip_delay_self = TRUE))
		// Could not wear it: put the old item back
		if(old_item)
			holder.equip_to_slot_if_possible(old_item, slot, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		qdel(new_item)
		return FALSE
	qdel(old_item)
	return TRUE

/**
 * One hexacrocin overdose roll.
 * Needs the bimbofication pref. Returns TRUE if anything happened.
 */
/proc/bimbo_hit(mob/living/carbon/human/target)
	if(!istype(target) || !target.mob_consents(/datum/preference/toggle/erp/bimbofication))
		return FALSE
	var/datum/component/bimbo/bimbo = target.GetComponent(/datum/component/bimbo) || target.AddComponent(/datum/component/bimbo)
	if(!bimbo)
		return FALSE
	bimbo.adjust_bonus(BIMBO_HIT_INTENSITY)
	target.visible_message(
		span_userlove("[target] blinks, then breaks into a bubbly, airheaded giggle."),
		span_userlove("Your head feels light and bubbly."),
	)
	return TRUE

/// A burst of pink hearts and a little sparkle sound
/proc/bimbo_heart_burst(turf/where)
	if(!where)
		return
	for(var/i in 1 to 3)
		new /obj/effect/temp_visual/heart(where)
	playsound(where, 'sound/effects/magic/charge.ogg', 40, TRUE, frequency = 1.5)
