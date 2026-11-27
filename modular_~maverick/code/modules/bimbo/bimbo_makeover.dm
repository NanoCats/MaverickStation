// What a Bimbonium overdose turns your clothes and ID into.

/obj/item/clothing/under/stripper_outfit/bimbo
	name = "pink stripper outfit"
	desc = "Glossy, pink and very short on fabric. It used to be a much more sensible piece of clothing."
	icon = 'modular_~maverick/icons/obj/clothing/bimbo_stripper.dmi'
	worn_icon = 'modular_~maverick/icons/mob/clothing/bimbo/bimbo_stripper.dmi'
	worn_icon_digi = 'modular_~maverick/icons/mob/clothing/bimbo/bimbo_stripper-digi.dmi'
	worn_icon_taur_snake = 'modular_~maverick/icons/mob/clothing/bimbo/bimbo_stripper-snake.dmi'
	worn_icon_taur_paw = 'modular_~maverick/icons/mob/clothing/bimbo/bimbo_stripper-paw.dmi'
	worn_icon_taur_hoof = 'modular_~maverick/icons/mob/clothing/bimbo/bimbo_stripper-hoof.dmi'
	icon_state = "stripper_bimbo"

/obj/item/clothing/under/stripper_outfit/bimbo/Initialize(mapload)
	. = ..()
	// Its own pink sprite. The parent's color skins point at sprites our files don't have.
	for(var/datum/component/reskinable_item/reskin as anything in GetComponents(/datum/component/reskinable_item))
		qdel(reskin)

/obj/item/clothing/head/sweet_bow/bimbo
	name = "pink sweet bow"
	greyscale_colors = BIMBO_MAKEOVER_PINK

/obj/item/clothing/neck/human_petcollar/choker/bimbo
	name = "pink choker"
	greyscale_colors = BIMBO_MAKEOVER_PINK

/obj/item/clothing/gloves/latex_gloves/bimbo
	name = "pink latex gloves"
	desc = "Glossy pink latex. They used to be a much more sensible pair of gloves."
	icon = 'modular_~maverick/icons/obj/clothing/bimbo_gloves.dmi'
	worn_icon = 'modular_~maverick/icons/mob/clothing/bimbo/bimbo_gloves.dmi'
	icon_state = "bimbo_gloves"

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
