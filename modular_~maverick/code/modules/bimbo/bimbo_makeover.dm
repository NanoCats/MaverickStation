// What a Bimbonium overdose turns your clothes and ID into.

/obj/item/clothing/under/stripper_outfit/bimbo
	name = "pink stripper outfit"
	desc = "Glossy, pink and very short on fabric. It used to be a much more sensible piece of clothing."
	icon_state = "stripper_white"

/obj/item/clothing/under/stripper_outfit/bimbo/Initialize(mapload)
	. = ..()
	add_atom_colour(BIMBO_MAKEOVER_PINK, FIXED_COLOUR_PRIORITY)

/obj/item/clothing/shoes/high_heels/bimbo
	name = "pink high heels"
	desc = "Tall, glossy and pink. They used to be a much more sensible pair of shoes."
	greyscale_colors = BIMBO_MAKEOVER_PINK

/// Cosmetic trim for the makeover. Applied as an override, so the card keeps its real trim and access underneath.
/datum/id_trim/maverick_bimbo
	assignment = BIMBO_ID_ASSIGNMENT
	trim_icon = 'modular_~maverick/icons/obj/card/bimbo_trim.dmi'
	trim_state = "trim_slut"
	department_color = BIMBO_MAKEOVER_PINK
	subdepartment_color = BIMBO_MAKEOVER_PINK
	sechud_icon = 'modular_~maverick/icons/obj/card/bimbo_hud.dmi'
	sechud_icon_state = "hudslut"

// Trim overrides only carry the sechud icon state, not the file. Point at our file while the makeover state is showing.
/obj/item/card/id/advanced/get_trim_sechud_icon()
	if(sechud_icon_state_override == "hudslut")
		return 'modular_~maverick/icons/obj/card/bimbo_hud.dmi'
	return ..()
