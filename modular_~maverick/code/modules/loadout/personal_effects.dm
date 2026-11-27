// Small loadout items go in a personal effects box inside your bag instead of straight into the bag.
// The bag only has so much room, and upstream deletes whatever doesn't fit, which made a loose cap of about ten items.
// The box makes as much room as it needs, so nothing you picked gets lost.

/obj/item/storage/box/personal_effects
	name = "personal effects box"
	desc = "A box for the little things you brought from home. It holds more than it looks like it should."
	icon = 'modular_~maverick/icons/obj/storage/personal_effects.dmi'
	icon_state = "personal_effects"
	illustration = null

/**
 * Takes the small loadout items out of this outfit's backpack list and returns their paths.
 * Run before the outfit is equipped, so the bag never has to fit them.
 */
/datum/outfit/proc/take_personal_effects(list/datum/loadout_item/loadout_datums)
	. = list()
	for(var/datum/loadout_item/item as anything in loadout_datums)
		var/obj/item/item_type = item.item_path
		if(!ispath(item_type, /obj/item) || !(item_type in backpack_contents))
			continue
		if(initial(item_type.w_class) > WEIGHT_CLASS_SMALL)
			continue
		backpack_contents -= item_type
		. += item_type

/**
 * Puts the given item paths in a personal effects box and puts the box in our bag.
 * The box grows to fit everything. If the bag is full too, the box goes in our hands, or at our feet.
 */
/mob/living/carbon/human/proc/pack_personal_effects(list/item_paths)
	if(!length(item_paths))
		return
	var/obj/item/storage/box/personal_effects/box = new(null)
	var/total_weight = 0
	for(var/obj/item/item_type as anything in item_paths)
		total_weight += initial(item_type.w_class)
	box.atom_storage.max_slots = max(box.atom_storage.max_slots, length(item_paths))
	box.atom_storage.max_total_storage = max(box.atom_storage.max_total_storage, total_weight)
	for(var/item_type in item_paths)
		new item_type(box)
	if(equip_to_storage(box, ITEM_SLOT_BACK, indirect_action = TRUE))
		return
	if(put_in_hands(box))
		return
	box.forceMove(drop_location())
