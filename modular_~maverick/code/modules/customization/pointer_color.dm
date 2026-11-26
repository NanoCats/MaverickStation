// Pointer color: a character pref that tints the arrow you point with.
// The Kommand skillchip still works and can change the color in the round, the same as before.

/mob/living/carbon/human
	/// Color of this character's pointing arrow, from the pointer color pref. Null keeps the stock arrow.
	var/pointer_color

/mob/living/carbon/human/proc/color_pointer(datum/source, atom/pointed, obj/effect/temp_visual/point/point)
	SIGNAL_HANDLER
	if(!pointer_color || HAS_TRAIT(src, TRAIT_UNKNOWN_APPEARANCE))
		return
	// Bigger arrows from command ID trims or the Kommand chip keep their size, only the color changes.
	var/obj/item/card/id/card = get_idcard(hand_first = FALSE)
	var/large = findtext(point.icon_state, "arrow_large") || card?.big_pointer
	point.icon_state = large ? "arrow_large_white" : "arrow_white"
	point.color = pointer_color
	point.cut_overlays()
	point.add_overlay(mutable_appearance(point.icon, "[point.icon_state]_highlights", appearance_flags = RESET_COLOR))

/datum/preference/toggle/pointer_color
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "pointer_color_toggle"
	default_value = FALSE

/datum/preference/toggle/pointer_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return // The color preference reads this toggle and does the work.

/datum/preference/color/pointer_color
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "pointer_color"

/datum/preference/color/pointer_color/create_default_value()
	return "#ffffff"

/datum/preference/color/pointer_color/is_accessible(datum/preferences/preferences)
	if(!..())
		return FALSE
	return preferences.read_preference(/datum/preference/toggle/pointer_color)

/datum/preference/color/pointer_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	if(!preferences?.read_preference(/datum/preference/toggle/pointer_color))
		target.pointer_color = null
		target.UnregisterSignal(target, COMSIG_MOVABLE_POINTED)
		return
	target.pointer_color = value
	target.RegisterSignal(target, COMSIG_MOVABLE_POINTED, TYPE_PROC_REF(/mob/living/carbon/human, color_pointer), override = TRUE)
