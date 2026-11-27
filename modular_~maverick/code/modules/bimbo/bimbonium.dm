/**
 * Bimbonium: what the THOT Accelerator's brain-melt pulses inject.
 *
 * Works like the other aphrodisiacs: the changes come gradually while it metabolizes.
 * - Each tick adds a little intensity and arousal.
 * - With the makeover on, each tick may take the next step: hair, then figure, then breasts.
 * - Breast and butt growth follow the bimbo size floor, one size at a time.
 * Overdosing (about six pulses in a short time) drains stamina and does the reality overwrite once:
 * slutty pink outfit, a "Slut" job everywhere, a pink PDA, and a short blackout.
 *
 * Needs the Bimbofication pref, checked by the aphrodisiac base type.
 */
/datum/reagent/drug/aphrodisiac/bimbonium
	name = "Bimbonium"
	description = "A glittering pink fluid from LustWish. It melts inhibitions, attention spans and dress codes."
	color = "#ff69b4"
	taste_description = "bubblegum and bad decisions"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = BIMBONIUM_OVERDOSE
	life_pref_datum = /datum/preference/toggle/erp/bimbofication
	overdose_pref_datum = /datum/preference/toggle/erp/bimbofication
	/// TRUE once this overdose has done the full makeover. Once per overdose.
	var/did_full_makeover = FALSE

// Settings ride along in the reagent data: list("hair" = color or null, "lipstick" = color or null)
/datum/reagent/drug/aphrodisiac/bimbonium/on_merge(list/mix_data, amount)
	. = ..()
	if(islist(mix_data))
		data = mix_data.Copy()

/datum/reagent/drug/aphrodisiac/bimbonium/life_effects(mob/living/carbon/human/exposed_mob)
	var/datum/component/bimbo/bimbo = exposed_mob.GetComponent(/datum/component/bimbo) || exposed_mob.AddComponent(/datum/component/bimbo)
	if(!bimbo)
		return
	bimbo.adjust_bonus(BIMBONIUM_INTENSITY_PER_TICK)
	exposed_mob.adjust_arousal(BIMBONIUM_AROUSAL_PER_TICK)
	var/lipstick = get_setting("lipstick")
	if(lipstick && bimbo.lipstick_color != lipstick)
		bimbo.lipstick_color = lipstick
	if(prob(BIMBONIUM_MAKEOVER_STEP_CHANCE))
		bimbo.makeover_step(get_setting("hair"))

// No ordinary overdose message or moodlet. This overdose is the point.
/datum/reagent/drug/aphrodisiac/bimbonium/overdose_start(mob/living/carbon/human/exposed_mob)
	if(!ishuman(exposed_mob) || !exposed_mob.mob_consents(overdose_pref_datum))
		return
	to_chat(exposed_mob, span_userlove("So much pink! Your thoughts melt into a warm, giggly haze!"))

/datum/reagent/drug/aphrodisiac/bimbonium/overdose_effects(mob/living/carbon/human/exposed_mob)
	// Like the old hexacrocin overdose, it takes it out of you. Stamina only.
	exposed_mob.adjust_stamina_loss(BIMBONIUM_OVERDOSE_STAMINA)
	if(did_full_makeover)
		return
	var/datum/component/bimbo/bimbo = exposed_mob.GetComponent(/datum/component/bimbo)
	if(!bimbo)
		return
	did_full_makeover = TRUE
	bimbo.reality_overwrite()

/datum/reagent/drug/aphrodisiac/bimbonium/on_mob_end_metabolize(mob/living/affected_mob)
	. = ..()
	did_full_makeover = FALSE

/// Reads a setting the rifle passed in the reagent data
/datum/reagent/drug/aphrodisiac/bimbonium/proc/get_setting(key, default_value = null)
	if(!islist(data) || !(key in data))
		return default_value
	return data[key]
