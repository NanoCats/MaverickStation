// Makes the policing MODsuit buildable by the crew, and tones it down to a modest upgrade over the security suit.

/datum/mod_theme/policing
	plating_colors = "#2f3a5c#5a8dff"

// Set in New() because the theme's own definition compiles after this file and would win a plain var override.
/datum/mod_theme/policing/New()
	armor_type = /datum/armor/mod_theme_policing/maverick
	hearing_protection = EAR_PROTECTION_NORMAL
	return ..()

/datum/armor/mod_theme_policing/maverick
	melee = 40
	bullet = 35
	laser = 30
	energy = 30
	bomb = 40
	bio = 100
	fire = 75
	acid = 75
	wound = 20

/obj/item/mod/construction/plating/policing
	theme = /datum/mod_theme/policing
	post_init_icon_state = "plating"
	greyscale_config = /datum/greyscale_config/mod_plating
	greyscale_colors = "#2f3a5c#5a8dff"
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
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/techweb_node/mod_security_adv
	display_name = "Advanced Security Modular Suits"
	description = "Patrol-grade suit plating for officers who expect to be shot at."
	prerequisite_nodes = list(/datum/techweb_node/mod_security)
	unlocked_designs = list(
		/datum/design/mod_plating/policing,
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)
	announce_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_SECURITY)
