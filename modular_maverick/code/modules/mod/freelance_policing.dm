// Freelance policing: makes the policing MODsuit buildable by the crew, tunes it to a small but clear upgrade over the security suit, and gives it a research node full of cop gear.

// Set in New() because the theme's own definition compiles after this file and would win a plain var override.
/datum/mod_theme/policing/New()
	armor_type = /datum/armor/mod_theme_policing/maverick
	hearing_protection = EAR_PROTECTION_NORMAL
	return ..()

// Equal to or better than the security suit in every category.
/datum/armor/mod_theme_policing/maverick
	melee = 40
	bullet = 35
	laser = 30
	energy = 40
	bomb = 40
	bio = 100
	fire = 100
	acid = 75
	wound = 20

/obj/item/mod/construction/plating/policing
	theme = /datum/mod_theme/policing
	post_init_icon_state = "plating"
	// Red and blue stripe, like the lights on a patrol car.
	greyscale_config = /datum/greyscale_config/mod_plating/split
	greyscale_colors = "#2f3a5c#e0303a#4a8cff"
	custom_materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3,
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT,
		/datum/material/plasma = SHEET_MATERIAL_AMOUNT,
		/datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT,
	)

/datum/design/mod_plating/policing
	name = "MOD Policing Plating"
	build_path = /obj/item/mod/construction/plating/policing
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3,
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT,
		/datum/material/plasma = SHEET_MATERIAL_AMOUNT,
		/datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_type = MECHFAB | PROTOLATHE
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/techweb_node/freelance_policing
	display_name = "Advanced Security and Freelance Policing"
	description = "Patrol gear reverse-engineered from a frontier police precinct. The safe word is police brutality. \
		(Note: this equipment is not licensed by the Pan-Slavic Commonwealth Internal Affairs Collegia. \
		You may, ironically, be committing a crime by wearing it in some sectors!)"
	prerequisite_nodes = list(/datum/techweb_node/mod_security)
	unlocked_designs = list(
		/datum/design/mod_plating/policing,
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)
	announce_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_SECURITY)
	// Seized evidence. Running any of these through a destructive analyzer researches the node for free.
	research_on_deconstruct = TRUE
	required_items_to_unlock = list(
		/obj/item/mod/control/pre_equipped/policing,
		/obj/item/modular_computer/pda/nri_police,
		/obj/item/card/id/advanced/nri_police,
		/obj/item/folder/blue/nri_cop,
	)

/datum/techweb_node/freelance_policing/New()
	unlocked_designs += list(
		/datum/design/police_aviators,
		/datum/design/module/megaphone,
		/datum/design/module/quick_cuff,
		/datum/design/module/pepper_shoulders,
		/datum/design/module/paper_dispenser,
		/datum/design/module/stamp,
	)
	return ..()

// The undercover subtype's description always said these show criminals. Now they actually do.
/obj/item/clothing/glasses/hud/spacecop
	clothing_traits = list(TRAIT_SECURITY_HUD)
	custom_materials = list(/datum/material/glass = SHEET_MATERIAL_AMOUNT * 0.8, /datum/material/iron = SHEET_MATERIAL_AMOUNT * 0.55)

/datum/design/police_aviators
	name = "Police Aviators"
	desc = "Security HUD aviators. For thinking you look cool."
	build_type = PROTOLATHE
	materials = list(
		/datum/material/glass = SHEET_MATERIAL_AMOUNT * 0.8,
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 0.55,
	)
	build_path = /obj/item/clothing/glasses/hud/spacecop
	category = list(
		RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/module/megaphone
	name = "Megaphone Module"
	build_path = /obj/item/mod/module/megaphone
	category = list(
		RND_CATEGORY_MODSUIT_MODULES + RND_SUBCATEGORY_MODSUIT_MODULES_SECURITY
	)

/datum/design/module/quick_cuff
	name = "Restraint Assist Module"
	materials = list(
		/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/titanium = HALF_SHEET_MATERIAL_AMOUNT,
	)
	build_path = /obj/item/mod/module/quick_cuff
	category = list(
		RND_CATEGORY_MODSUIT_MODULES + RND_SUBCATEGORY_MODSUIT_MODULES_SECURITY
	)

/datum/design/module/pepper_shoulders
	name = "Pepper Shoulders Module"
	build_path = /obj/item/mod/module/pepper_shoulders
	category = list(
		RND_CATEGORY_MODSUIT_MODULES + RND_SUBCATEGORY_MODSUIT_MODULES_SECURITY
	)

/datum/design/module/paper_dispenser
	name = "Paper Dispenser Module"
	build_path = /obj/item/mod/module/paper_dispenser
	category = list(
		RND_CATEGORY_MODSUIT_MODULES + RND_SUBCATEGORY_MODSUIT_MODULES_SECURITY
	)

/datum/design/module/stamp
	name = "Stamper Module"
	build_path = /obj/item/mod/module/stamp
	category = list(
		RND_CATEGORY_MODSUIT_MODULES + RND_SUBCATEGORY_MODSUIT_MODULES_SECURITY
	)
