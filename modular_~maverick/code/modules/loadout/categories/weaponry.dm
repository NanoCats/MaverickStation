// Weaponry loadout section. Empty for now, stock it later.
// Weapons should set required_access. Use ACCESS_WEAPONS (the weapon permit) where it fits.

/datum/loadout_category/weaponry
	category_name = "Weaponry"
	category_ui_icon = FA_ICON_GUN
	type_to_generate = /datum/loadout_item/weaponry
	tab_order = /datum/loadout_category/head::tab_order + 14

/datum/loadout_item/weaponry
	abstract_type = /datum/loadout_item/weaponry
