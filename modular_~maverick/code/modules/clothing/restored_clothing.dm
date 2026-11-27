// Clothing that was deleted outright upstream when the security colors changed, not just recolored.
// The sprites never left the icon files, so these only bring the item types back.

/obj/item/clothing/suit/armor/vest/brit
	name = "high vis armored vest"
	desc = "Oi bruv, you got a loicence for that?"
	icon = 'modular_skyrat/master_files/icons/obj/clothing/suits.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/suit.dmi'
	icon_state = "hazardbg"
	worn_icon_state = "hazardbg"

/obj/item/clothing/suit/armor/vest/brit/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/toggle_icon, "zipper")

/obj/item/clothing/suit/british_officer
	name = "british officers coat"
	desc = "Whether you're commanding a colonial crusade or commanding a battalion for the British Empire, this coat will suit you."
	icon = 'modular_skyrat/master_files/icons/obj/clothing/suits.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/suit.dmi'
	icon_state = "british_officer"
	supports_variations_flags = CLOTHING_DIGITIGRADE_VARIATION_NO_NEW_ICON
	body_parts_covered = CHEST|GROIN|ARMS
	cold_protection = CHEST|GROIN|ARMS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	armor_type = /datum/armor/suit_british_officer

/datum/armor/suit_british_officer
	melee = 10
	bullet = 10

/obj/item/clothing/gloves/combat/peacekeeper
	name = "peacekeeper gloves"
	desc = "These tactical gloves are fireproof."
	icon = 'modular_skyrat/master_files/icons/obj/clothing/gloves.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/hands.dmi'
	icon_state = "peacekeeper_gloves"
	worn_icon_state = "peacekeeper"
	siemens_coefficient = 0.5
	strip_delay = 2 SECONDS
	cold_protection = NONE
	min_cold_protection_temperature = null
	heat_protection = NONE
	max_heat_protection_temperature = null
	resistance_flags = FLAMMABLE
	armor_type = /datum/armor/none
	cut_type = null

/obj/item/clothing/head/helmet/sec/terra
	name = "sol police helmet"
	desc = "A helmet to protect any officer from bludgeoning attacks, or the occasional bullet."
	icon = 'modular_skyrat/master_files/icons/obj/clothing/head/helmet.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/head/helmet.dmi'
	icon_state = "security_helmet-novisor"
	base_icon_state = "security_helmet-novisor"
	supports_variations_flags = CLOTHING_SNOUTED_VARIATION_NO_NEW_ICON
	armor_type = /datum/armor/head_helmet

/obj/item/clothing/suit/armor/vest/armadyne
	name = "armadyne jacket"
	desc = "An Armadyne branded track jacket, with a thin nanocarbon lining inside for protective purposes. Worn by Armadyne corporate, or wealthy supporters."
	icon = 'modular_skyrat/master_files/icons/obj/clothing/suits.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/suit.dmi'
	icon_state = "armadyne_jacket"
	worn_icon_state = "armadyne_jacket"
	supports_variations_flags = CLOTHING_DIGITIGRADE_VARIATION_NO_NEW_ICON

/obj/item/clothing/suit/armor/vest/armadyne/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/toggle_icon, "zipper")

/obj/item/clothing/suit/armor/vest/armadyne/armor
	name = "armadyne armor vest"
	desc = "A nanocarbon and high-grade polymer vest, with the worn-red Armadyne logo printed on the back. Used by Armadyne corporate when they need emergency armor."
	icon_state = "armadyne_armor"
	worn_icon_state = "armadyne_armor"

/obj/item/clothing/glasses/hud/security/sunglasses/armadyne
	name = "armadyne hud glasses"
	icon = 'modular_skyrat/master_files/icons/obj/clothing/glasses.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/eyes.dmi'
	icon_state = "armadyne_glasses"

/obj/item/clothing/gloves/combat/armadyne
	name = "armadyne combat gloves"
	desc = "Tactical and sleek. Worn by Armadyne representatives."
	icon = 'modular_skyrat/master_files/icons/obj/clothing/gloves.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/hands.dmi'
	icon_state = "armadyne_gloves"
	worn_icon_state = "armadyne_gloves"
	cut_type = null

/obj/item/clothing/shoes/jackboots/armadyne
	name = "armadyne combat boots"
	desc = "Tactical and sleek. Worn by Armadyne representatives."
	icon = 'modular_skyrat/master_files/icons/obj/clothing/shoes.dmi'
	worn_icon = 'modular_skyrat/master_files/icons/mob/clothing/feet.dmi'
	icon_state = "armadyne_boots"
	inhand_icon_state = "jackboots"
	worn_icon_state = "armadyne_boots"
