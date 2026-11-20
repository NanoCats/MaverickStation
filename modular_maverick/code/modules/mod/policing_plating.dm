// Makes the policing MODsuit buildable by the crew, and tunes it to a small but clear upgrade over the security suit.

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

/datum/techweb_node/mod_security_adv
	display_name = "Advanced Security Modular Suits"
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
