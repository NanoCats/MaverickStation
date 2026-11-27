#define TRAIT_GEAR_WEAR "Wear it"
#define TRAIT_GEAR_BAG "Put it in my bag"
#define TRAIT_GEAR_NONE "Don't give it to me"

/// What to do with cosmetic gear that station traits hand out at spawn: party hats, wallets and scryers.
/datum/preference/choiced/maverick_trait_gear
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "maverick_trait_gear"
	savefile_identifier = PREFERENCE_PLAYER

/datum/preference/choiced/maverick_trait_gear/init_possible_values()
	return list(TRAIT_GEAR_WEAR, TRAIT_GEAR_BAG, TRAIT_GEAR_NONE)

/datum/preference/choiced/maverick_trait_gear/create_default_value()
	return TRAIT_GEAR_WEAR

/datum/preference/choiced/maverick_trait_gear/apply_to_client(client/client, value)
	return

/// The trait gear choice of whoever plays this mob. Mobs without a player wear it.
/proc/get_trait_gear_choice(mob/living/spawned)
	return spawned.client?.prefs?.read_preference(/datum/preference/choiced/maverick_trait_gear) || TRAIT_GEAR_WEAR

/// Puts trait gear the player does not want worn into their bag, or deletes it
/proc/handle_unwanted_trait_gear(mob/living/spawned, obj/item/gear, choice)
	if(QDELETED(gear) || choice == TRAIT_GEAR_WEAR)
		return
	spawned.temporarilyRemoveItemFromInventory(gear, force = TRUE)
	if(choice == TRAIT_GEAR_NONE || !spawned.equip_to_storage(gear, ITEM_SLOT_BACK, indirect_action = TRUE))
		qdel(gear)

/datum/station_trait/birthday/on_job_after_spawn(datum/source, datum/job/job, mob/living/spawned_mob)
	SIGNAL_HANDLER
	var/choice = get_trait_gear_choice(spawned_mob)
	var/obj/item/old_hat = spawned_mob.get_item_by_slot(ITEM_SLOT_HEAD)
	. = ..()
	var/obj/item/new_hat = spawned_mob.get_item_by_slot(ITEM_SLOT_HEAD)
	if(new_hat != old_hat)
		handle_unwanted_trait_gear(spawned_mob, new_hat, choice)

/datum/station_trait/wallets/on_job_after_spawn(datum/source, datum/job/job, mob/living/living_mob, mob/M, joined_late)
	SIGNAL_HANDLER
	var/choice = get_trait_gear_choice(living_mob)
	if(choice == TRAIT_GEAR_WEAR)
		return ..()
	if(choice == TRAIT_GEAR_BAG)
		var/obj/item/storage/wallet/wallet = new(living_mob)
		if(!living_mob.equip_to_storage(wallet, ITEM_SLOT_BACK, indirect_action = TRUE))
			qdel(wallet)

/// Scryers move your neck item to make room. With the pref off, the scryer goes in the bag and the neck item stays put.
/datum/station_trait/scryers/on_job_after_spawn(datum/source, datum/job/job, mob/living/spawned, client/player_client)
	SIGNAL_HANDLER
	var/choice = get_trait_gear_choice(spawned)
	if(choice == TRAIT_GEAR_WEAR)
		return ..()
	if(choice == TRAIT_GEAR_NONE)
		return
	var/obj/item/clothing/neck/link_scryer/loaded/new_scryer = new(spawned)
	new_scryer.label = spawned.name
	new_scryer.update_name()
	if(!spawned.equip_to_storage(new_scryer, ITEM_SLOT_BACK, indirect_action = TRUE))
		qdel(new_scryer)

#undef TRAIT_GEAR_WEAR
#undef TRAIT_GEAR_BAG
#undef TRAIT_GEAR_NONE
