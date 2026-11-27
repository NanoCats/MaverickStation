/// Quirk holders chose the size floor. Everyone else needs the breast enlargement pref.
/datum/component/bimbo/proc/can_grow()
	if(from_quirk)
		return TRUE
	var/mob/living/carbon/human/holder = parent
	return holder.client?.prefs?.read_preference(/datum/preference/toggle/erp/breast_enlargement)

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
			to_chat(holder, span_purple("Your chest feels warm as it swells a little bigger."))

	var/obj/item/organ/genital/butt/butt = holder.get_organ_slot(ORGAN_SLOT_BUTT)
	if(butt && grow_to_floor(butt, round(BIMBO_BUTT_FLOOR_MAX * fraction), instant))
		changed = TRUE
		if(!instant)
			to_chat(holder, span_purple("Your hips feel heavier."))

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

/// The ray's "Barbie" profile. Each part checks its own existing pref.
/datum/component/bimbo/proc/barbie_conversion()
	var/mob/living/carbon/human/holder = parent

	// set_gender checks the gender change pref itself
	holder.set_gender(FEMALE)
	if(holder.gender == FEMALE && holder.physique != FEMALE)
		holder.physique = FEMALE
		holder.update_body()
		holder.update_appearance(UPDATE_OVERLAYS)

	if(holder.get_organ_slot(ORGAN_SLOT_BREASTS) || !holder.client?.prefs?.read_preference(/datum/preference/toggle/erp/new_genitalia_growth))
		return
	var/list/breast_part = holder.dna?.mutant_bodyparts[ORGAN_SLOT_BREASTS]
	if(!breast_part)
		return
	if(breast_part[MUTANT_INDEX_NAME] == SPRITE_ACCESSORY_NONE)
		breast_part[MUTANT_INDEX_NAME] = "Pair"
	var/obj/item/organ/genital/breasts/new_breasts = new
	new_breasts.build_from_dna(holder.dna, ORGAN_SLOT_BREASTS)
	new_breasts.Insert(holder, FALSE, FALSE)
	new_breasts.set_size(2)
	new_breasts.update_sprite_suffix()
	holder.update_body()
	to_chat(holder, span_purple("Your chest feels warm and tingly as it fills out."))

/**
 * One ray hit or hexacrocin overdose roll.
 * Needs the bimbofication pref. Returns TRUE if anything happened.
 */
/proc/bimbo_hit(mob/living/carbon/human/target, barbie = FALSE)
	if(!istype(target) || !target.client?.prefs?.read_preference(/datum/preference/toggle/erp/bimbofication))
		return FALSE
	var/datum/component/bimbo/bimbo = target.GetComponent(/datum/component/bimbo) || target.AddComponent(/datum/component/bimbo)
	if(!bimbo)
		return FALSE
	if(barbie)
		bimbo.barbie_conversion()
	bimbo.adjust_bonus(BIMBO_HIT_INTENSITY)
	to_chat(target, span_purple("Your head feels light and bubbly."))
	return TRUE
