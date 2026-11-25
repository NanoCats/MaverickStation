/// Adds Maverick items to the maintenance loot tables before the map loads and spawners roll.
SUBSYSTEM_DEF(maverick_loot)
	name = "Maverick Loot"
	init_stage = INITSTAGE_EARLY
	ss_flags = SS_NO_FIRE

	/// Rare tier additions, typepath = weight
	var/list/rarity_additions = list(
		/obj/item/salvaged_policing_chestplate = 10,
	)

/datum/controller/subsystem/maverick_loot/Initialize()
	for(var/path in rarity_additions)
		GLOB.rarity_loot[path] = rarity_additions[path]
	return SS_INIT_SUCCESS
