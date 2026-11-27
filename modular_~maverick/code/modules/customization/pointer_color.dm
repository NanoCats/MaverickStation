// Pointer color: a character pref that tints the arrow you point with.
// A Kommand skillchip takes over while it is active: it starts with the pref color, and its action can change it in the round.

/mob/living/carbon/human
	/// Color of this character's pointing arrow, from the pointer color pref. Null keeps the stock arrow.
	var/pointer_color
	/// TRUE while a Kommand skillchip is active. The chip colors the arrow then, so the pref handler stands down.
	var/pointer_kommand_active = FALSE

/mob/living/carbon/human/proc/color_pointer(datum/source, atom/pointed, obj/effect/temp_visual/point/point)
	SIGNAL_HANDLER
	if(!pointer_color || pointer_kommand_active || HAS_TRAIT(src, TRAIT_UNKNOWN_APPEARANCE))
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

/obj/item/skillchip/big_pointer/on_activate(mob/living/carbon/user, silent = FALSE)
	. = ..()
	var/mob/living/carbon/human/human_user = user
	if(!istype(human_user))
		return
	human_user.pointer_kommand_active = TRUE
	if(!human_user.pointer_color)
		return
	var/datum/action/change_pointer_color/action = locate() in actions
	if(action && !action.arrow_color)
		action.arrow_color = human_user.pointer_color
		action.build_all_button_icons(update_flags = UPDATE_BUTTON_ICON, force = TRUE)

/obj/item/skillchip/big_pointer/on_deactivate(mob/living/carbon/user, silent = FALSE)
	var/mob/living/carbon/human/human_user = user
	if(istype(human_user))
		human_user.pointer_kommand_active = FALSE
	return ..()
