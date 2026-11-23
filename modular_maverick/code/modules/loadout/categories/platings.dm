// Protean plating loadout section.
// A picked plating is not spawned as an item. It is copied straight onto the protean's suit at spawn.
// LustWish is left out, it already lives in the Pocket section.
// Station platings need the matching department access. Off-station and antag platings are admin only.

/datum/loadout_category/platings
	category_name = "Platings"
	category_ui_icon = FA_ICON_ROBOT
	category_info = "(Proteans)"
	type_to_generate = /datum/loadout_item/plating
	tab_order = /datum/loadout_category/head::tab_order + 15

/datum/loadout_item/plating
	abstract_type = /datum/loadout_item/plating
	restricted_species = list(SPECIES_PROTEAN)
	spawns_item = FALSE

/datum/loadout_item/plating/insert_path_into_outfit(datum/outfit/outfit, mob/living/carbon/human/equipper, visuals_only = FALSE, loadout_placement_preference)
	return

/datum/loadout_item/plating/on_equip_item(obj/item/equipped_item, list/item_details, mob/living/carbon/human/equipper, datum/outfit/outfit, visuals_only = FALSE)
	if(visuals_only)
		return NONE
	var/datum/species/protean/protean = equipper.dna?.species
	if(!istype(protean) || isnull(protean.species_modsuit))
		return NONE
	var/obj/item/mod/construction/plating/plates = new item_path(null)
	protean.assimilate_theme(equipper, plates)
	qdel(plates)
	return NONE

// Station platings

/datum/loadout_item/plating/civilian
	name = "Civilian Plating"
	item_path = /obj/item/mod/construction/plating/civilian

/datum/loadout_item/plating/frontier_colonist
	name = "Frontier Colonist Plating"
	item_path = /obj/item/mod/construction/plating/frontier_colonist

/datum/loadout_item/plating/engineering
	name = "Engineering Plating"
	item_path = /obj/item/mod/construction/plating/engineering
	required_access = list(ACCESS_ENGINEERING)

/datum/loadout_item/plating/atmospheric
	name = "Atmospherics Plating"
	item_path = /obj/item/mod/construction/plating/atmospheric
	required_access = list(ACCESS_ATMOSPHERICS)

/datum/loadout_item/plating/prototype
	name = "Prototype Plating"
	item_path = /obj/item/mod/construction/plating/prototype
	required_access = list(ACCESS_ENGINEERING)

/datum/loadout_item/plating/advanced
	name = "Advanced Plating"
	item_path = /obj/item/mod/construction/plating/advanced
	required_access = list(ACCESS_CE)

/datum/loadout_item/plating/advanced_atmos
	name = "Advanced Atmospherics Plating"
	item_path = /obj/item/mod/construction/plating/advanced/atmos
	required_access = list(ACCESS_CE)

/datum/loadout_item/plating/medical
	name = "Medical Plating"
	item_path = /obj/item/mod/construction/plating/medical
	required_access = list(ACCESS_MEDICAL)

/datum/loadout_item/plating/rescue
	name = "Rescue Plating"
	item_path = /obj/item/mod/construction/plating/rescue
	required_access = list(ACCESS_CMO)

/datum/loadout_item/plating/research
	name = "Research Plating"
	item_path = /obj/item/mod/construction/plating/research
	required_access = list(ACCESS_RD)

/datum/loadout_item/plating/loader
	name = "Loader Plating"
	item_path = /obj/item/mod/construction/plating/loader
	required_access = list(ACCESS_CARGO)

/datum/loadout_item/plating/prototype_hauler
	name = "Hauler Plating"
	item_path = /obj/item/mod/construction/plating/prototype/hauler
	required_access = list(ACCESS_CARGO)

/datum/loadout_item/plating/mining
	name = "Mining Plating"
	item_path = /obj/item/mod/construction/plating/mining
	required_access = list(ACCESS_MINING)

/datum/loadout_item/plating/security
	name = "Security Plating"
	item_path = /obj/item/mod/construction/plating/security
	required_access = list(ACCESS_SECURITY)

/datum/loadout_item/plating/policing
	name = "Policing Plating"
	item_path = /obj/item/mod/construction/plating/policing
	required_access = list(ACCESS_SECURITY)

/datum/loadout_item/plating/medical_corpsman
	name = "Corpsman Plating"
	item_path = /obj/item/mod/construction/plating/medical/corpsman
	required_access = list(ACCESS_SECURITY, ACCESS_MEDICAL)

/datum/loadout_item/plating/safeguard
	name = "Safeguard Plating"
	item_path = /obj/item/mod/construction/plating/safeguard
	required_access = list(ACCESS_HOS)

/datum/loadout_item/plating/blueshield
	name = "Blueshield Plating"
	item_path = /obj/item/mod/construction/plating/blueshield
	required_access = list(ACCESS_COMMAND)

/datum/loadout_item/plating/magnate
	name = "Magnate Plating"
	item_path = /obj/item/mod/construction/plating/magnate
	required_access = list(ACCESS_CAPTAIN)

/datum/loadout_item/plating/cosmohonk
	name = "Cosmohonk Plating"
	item_path = /obj/item/mod/construction/plating/cosmohonk
	required_access = list(ACCESS_THEATRE)

// Admin only platings

/datum/loadout_item/plating/administrative
	name = "Administrative Plating"
	item_path = /obj/item/mod/construction/plating/administrative
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/apocryphal
	name = "Apocryphal Plating"
	item_path = /obj/item/mod/construction/plating/apocryphal
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/asset_protection
	name = "Asset Protection Plating"
	item_path = /obj/item/mod/construction/plating/asset_protection
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/chrono
	name = "Chrono Plating"
	item_path = /obj/item/mod/construction/plating/chrono
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/contractor
	name = "Contractor Plating"
	item_path = /obj/item/mod/construction/plating/contractor
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/corporate
	name = "Corporate Plating"
	item_path = /obj/item/mod/construction/plating/corporate
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/covert
	name = "Covert Plating"
	item_path = /obj/item/mod/construction/plating/covert
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/daimyo
	name = "Daimyo Plating"
	item_path = /obj/item/mod/construction/plating/daimyo
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/debug
	name = "Debug Plating"
	item_path = /obj/item/mod/construction/plating/debug
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/elite
	name = "Elite Plating"
	item_path = /obj/item/mod/construction/plating/elite
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/enchanted
	name = "Enchanted Plating"
	item_path = /obj/item/mod/construction/plating/enchanted
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/frontline
	name = "Frontline Plating"
	item_path = /obj/item/mod/construction/plating/frontline
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/frontline_surplus
	name = "Frontline Surplus Plating"
	item_path = /obj/item/mod/construction/plating/frontline/surplus
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/glitch
	name = "Glitch Plating"
	item_path = /obj/item/mod/construction/plating/glitch
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/infiltrator
	name = "Infiltrator Plating"
	item_path = /obj/item/mod/construction/plating/infiltrator
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/infiltrator_persistence
	name = "Infiltrator Persistence Plating"
	item_path = /obj/item/mod/construction/plating/infiltrator/persistence
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/interdyne
	name = "Interdyne Plating"
	item_path = /obj/item/mod/construction/plating/interdyne
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/marines
	name = "Marines Plating"
	item_path = /obj/item/mod/construction/plating/marines
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/ninja
	name = "Ninja Plating"
	item_path = /obj/item/mod/construction/plating/ninja
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/responsory
	name = "Responsory Plating"
	item_path = /obj/item/mod/construction/plating/responsory
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/responsory_ancient_milsim
	name = "Responsory Ancient Milsim Plating"
	item_path = /obj/item/mod/construction/plating/responsory/ancient_milsim
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/responsory_traitor
	name = "Responsory Traitor Plating"
	item_path = /obj/item/mod/construction/plating/responsory/traitor
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/syndicate
	name = "Syndicate Plating"
	item_path = /obj/item/mod/construction/plating/syndicate
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/tarkon
	name = "Tarkon Plating"
	item_path = /obj/item/mod/construction/plating/tarkon
	required_staff_tier = LOADOUT_STAFF_ADMIN

/datum/loadout_item/plating/voskhod
	name = "Voskhod Plating"
	item_path = /obj/item/mod/construction/plating/voskhod
	required_staff_tier = LOADOUT_STAFF_ADMIN
