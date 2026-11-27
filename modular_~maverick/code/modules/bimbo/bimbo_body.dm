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
 * The reality overwrite from a Bimbonium overdose.
 *
 * Reality decides you were always a bimbo:
 * - Clothes: jumpsuit, shoes, hat, neck and gloves turn into slutty pink versions; mask and suit vanish.
 *   Pressure and internals gear is never touched. Pockets, accessories and anything stored inside drop or carry over.
 * - Job: every ID card registered to you reads "Slut", and so does the crew manifest. With no ID, you get one.
 *   Access is never touched. PDAs registered to you turn pink.
 * - You black out for a moment and come to confused.
 */
/datum/component/bimbo/proc/reality_overwrite()
	var/mob/living/carbon/human/holder = parent
	overwrite_wardrobe()
	overwrite_job()

	bimbo_heart_burst(get_turf(holder))
	holder.visible_message(
		span_userlove("Reality hiccups around [holder] in a flash of pink, and [holder.p_they()] crumple[holder.p_s()] in a giggly heap!"),
		span_userlove("Everything goes pink and the world rewrites itself around you!"),
	)
	holder.Unconscious(BIMBO_OVERWRITE_KNOCKOUT)
	addtimer(CALLBACK(src, PROC_REF(wake_from_overwrite)), BIMBO_OVERWRITE_KNOCKOUT)

/datum/component/bimbo/proc/wake_from_overwrite()
	var/mob/living/carbon/human/holder = parent
	to_chat(holder, span_userlove(span_big("Like, oh my god, what happened? You don't remember... Like, what was your job again?")))
	to_chat(holder, span_notice("Your ID says \"[BIMBO_ID_ASSIGNMENT]\" now. That seems right."))

/// Swaps each worn piece for its slutty version. Mask and suit just go.
/datum/component/bimbo/proc/overwrite_wardrobe()
	var/mob/living/carbon/human/holder = parent
	var/static/list/replacements = list(
		"[ITEM_SLOT_ICLOTHING]" = /obj/item/clothing/under/stripper_outfit/bimbo,
		"[ITEM_SLOT_FEET]" = /obj/item/clothing/shoes/high_heels/bimbo,
		"[ITEM_SLOT_HEAD]" = /obj/item/clothing/head/sweet_bow/bimbo,
		"[ITEM_SLOT_NECK]" = /obj/item/clothing/neck/human_petcollar/choker/bimbo,
		"[ITEM_SLOT_GLOVES]" = /obj/item/clothing/gloves/latex_gloves/bimbo,
	)
	for(var/slot_text in replacements)
		var/slot = text2num(slot_text)
		var/new_type = replacements[slot_text]
		var/obj/item/old_item = holder.get_item_by_slot(slot)
		if(istype(old_item, new_type) || (old_item && !can_transform(old_item)))
			continue
		transform_worn(old_item, new new_type(holder.drop_location()), slot)

	for(var/slot in list(ITEM_SLOT_MASK, ITEM_SLOT_OCLOTHING))
		var/obj/item/old_item = holder.get_item_by_slot(slot)
		if(!old_item || !can_transform(old_item))
			continue
		if(holder.temporarilyRemoveItemFromInventory(old_item, force = TRUE, idrop = FALSE))
			spill_contents(old_item)
			qdel(old_item)

/**
 * Worn items the overwrite may replace or delete.
 * Never MOD pieces, no-drop or indestructible items, anything that keeps out vacuum, or a mask feeding internals.
 */
/datum/component/bimbo/proc/can_transform(obj/item/worn)
	var/mob/living/carbon/human/holder = parent
	if(HAS_TRAIT(worn, TRAIT_NODROP) || istype(worn, /obj/item/mod) || (worn.resistance_flags & INDESTRUCTIBLE))
		return FALSE
	if(isclothing(worn))
		var/obj/item/clothing/clothes = worn
		if(clothes.clothing_flags & STOPSPRESSUREDAMAGE)
			return FALSE
		if((clothes.clothing_flags & MASKINTERNALS) && holder.internal)
			return FALSE
	return TRUE

/// Swaps old_item (may be null) for new_item in a slot. Accessories move over, and anything inside drops.
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
	if(old_item)
		var/obj/item/clothing/under/old_uniform = old_item
		var/obj/item/clothing/under/new_uniform = new_item
		if(istype(old_uniform) && istype(new_uniform))
			for(var/obj/item/clothing/accessory/accessory as anything in old_uniform.attached_accessories)
				old_uniform.remove_accessory(accessory)
				if(!new_uniform.attach_accessory(accessory, attach_message = FALSE))
					accessory.forceMove(holder.drop_location())
		spill_contents(old_item)
		qdel(old_item)
	return TRUE

/// Drops whatever was stored in an item that is about to vanish
/datum/component/bimbo/proc/spill_contents(obj/item/vanishing)
	var/mob/living/carbon/human/holder = parent
	var/atom/drop_spot = holder.drop_location()
	if(vanishing.atom_storage)
		vanishing.atom_storage.remove_all(drop_spot)
	for(var/obj/item/inside in vanishing)
		inside.forceMove(drop_spot)

/**
 * Every ID registered to you reads "Slut", wherever it is, and so does the manifest.
 * PDAs registered to you turn pink. With no ID at all, a new one appears on you.
 */
/datum/component/bimbo/proc/overwrite_job()
	var/mob/living/carbon/human/holder = parent
	var/list/obj/item/card/id/advanced/cards = list()
	for(var/obj/item/card/id/advanced/card in holder.get_all_contents())
		cards |= card
	var/datum/bank_account/account = SSeconomy.bank_accounts_by_id["[holder.account_id]"]
	for(var/obj/item/card/id/advanced/card in account?.bank_cards)
		cards |= card

	if(!length(cards))
		var/obj/item/card/id/advanced/new_card = new(holder.drop_location())
		new_card.registered_name = holder.real_name
		new_card.registered_age = holder.age
		if(account)
			new_card.registered_account = account
			LAZYADD(account.bank_cards, new_card)
		SSid_access.apply_trim_to_card(new_card, /datum/id_trim/maverick_bimbo)
		new_card.update_label()
		new_card.update_icon()
		if(!holder.equip_to_slot_if_possible(new_card, ITEM_SLOT_ID, disable_warning = TRUE))
			holder.put_in_hands(new_card)
		cards += new_card

	for(var/obj/item/card/id/advanced/card as anything in cards)
		if(card.trim_assignment_override == BIMBO_ID_ASSIGNMENT || card.trim?.assignment == BIMBO_ID_ASSIGNMENT)
			continue
		SSid_access.apply_trim_override(card, /datum/id_trim/maverick_bimbo, check_forged = FALSE)
		card.update_label()
		card.update_icon()

	GLOB.manifest.modify(holder.real_name, BIMBO_ID_ASSIGNMENT, BIMBO_ID_ASSIGNMENT)

	var/list/obj/item/modular_computer/pdas = list()
	for(var/obj/item/modular_computer/pda/pda in holder.get_all_contents())
		pdas |= pda
	for(var/messenger_ref in GLOB.pda_messengers)
		var/datum/computer_file/program/messenger/messenger = GLOB.pda_messengers[messenger_ref]
		var/obj/item/modular_computer/pda/pda = messenger?.computer
		if(istype(pda) && pda.saved_identification == holder.real_name)
			pdas |= pda
	for(var/obj/item/modular_computer/pda/pda as anything in pdas)
		pda.set_greyscale(BIMBO_PDA_COLORS)
		pda.imprint_id(holder.real_name, BIMBO_ID_ASSIGNMENT)

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
