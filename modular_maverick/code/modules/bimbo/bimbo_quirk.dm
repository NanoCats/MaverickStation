/datum/quirk/bimbo
	name = "Bimbo"
	desc = "Thinking is hard, and you would rather look cute anyway. Your speech, focus and reading suffer, your figure never drops below a minimum size, and your lipstick never comes off."
	icon = FA_ICON_FACE_KISS_WINK_HEART
	value = -6
	gain_text = span_purple("Your thoughts go all soft and fuzzy.")
	lose_text = span_notice("Your head feels clear and sharp again.")
	medical_record_text = "Patient shows a short attention span and poor recall of long words. Responds well to compliments."
	mail_goodies = list(/obj/item/lipstick/quantum)
	erp_quirk = TRUE

/datum/quirk_constant_data/bimbo
	associated_typepath = /datum/quirk/bimbo
	customization_options = list(
		/datum/preference/numeric/bimbo_intensity,
		/datum/preference/color/bimbo_lipstick_color,
	)

/datum/quirk/bimbo/add(client/client_source)
	var/intensity = client_source?.prefs.read_preference(/datum/preference/numeric/bimbo_intensity) || BIMBO_QUIRK_MIN_INTENSITY
	var/color = client_source?.prefs.read_preference(/datum/preference/color/bimbo_lipstick_color) || BIMBO_DEFAULT_LIPSTICK_COLOR
	var/datum/component/bimbo/bimbo = quirk_holder.GetComponent(/datum/component/bimbo)
	if(!bimbo)
		quirk_holder.AddComponent(/datum/component/bimbo, intensity, TRUE, color)
		return
	bimbo.lipstick_color = color
	bimbo.set_baseline(intensity, TRUE)

/datum/quirk/bimbo/remove()
	var/datum/component/bimbo/bimbo = quirk_holder.GetComponent(/datum/component/bimbo)
	bimbo?.set_baseline(0, FALSE)

/datum/preference/numeric/bimbo_intensity
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	savefile_key = "bimbo_intensity"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE
	minimum = BIMBO_QUIRK_MIN_INTENSITY
	maximum = BIMBO_MAX_INTENSITY
	step = 5

/datum/preference/numeric/bimbo_intensity/create_default_value()
	return BIMBO_QUIRK_MIN_INTENSITY

/datum/preference/numeric/bimbo_intensity/is_accessible(datum/preferences/preferences)
	if(!..())
		return FALSE
	return /datum/quirk/bimbo::name in preferences.all_quirks

/datum/preference/numeric/bimbo_intensity/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/color/bimbo_lipstick_color
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	savefile_key = "bimbo_lipstick_color"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE

/datum/preference/color/bimbo_lipstick_color/create_default_value()
	return BIMBO_DEFAULT_LIPSTICK_COLOR

/datum/preference/color/bimbo_lipstick_color/is_accessible(datum/preferences/preferences)
	if(!..())
		return FALSE
	return /datum/quirk/bimbo::name in preferences.all_quirks

/datum/preference/color/bimbo_lipstick_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return
