// Robotics can print security MOD plating again, once the Security Modular Suits node is researched.

/obj/item/mod/construction/plating/security
	custom_materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT,
		/datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/plasma = HALF_SHEET_MATERIAL_AMOUNT,
	)

/datum/design/mod_plating/security
	name = "MOD Security Plating"
	build_path = /obj/item/mod/construction/plating/security
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT,
		/datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/plasma = HALF_SHEET_MATERIAL_AMOUNT,
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
	research_icon_state = "security-plating"

/datum/techweb_node/mod_security/New()
	unlocked_designs += /datum/design/mod_plating/security
	return ..()
