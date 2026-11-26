// set_up_parts() makes new suit parts. The magnetic harness lets guns into the old chestplate's suit storage
// when it is installed, so a theme change (protean assimilation, platings) loses that until it is reinstalled.
// Apply it again to the new chestplate after every rebuild.

/datum/mod_theme/set_up_parts(obj/item/mod/control/mod, skin)
	. = ..()
	for(var/obj/item/mod/module/magnetic_harness/harness in mod.modules)
		harness.reapply_gun_storage()

/// Lets guns into the current chestplate's suit storage again
/obj/item/mod/module/magnetic_harness/proc/reapply_gun_storage()
	var/obj/item/clothing/suit = mod?.get_part_from_slot(ITEM_SLOT_OCLOTHING)
	if(!istype(suit))
		return
	already_allowed_guns = guns_typecache & suit.allowed
	suit.allowed |= guns_typecache
