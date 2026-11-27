/// Every loadout item shows a real icon in the loadout menu, not a blank or a wrong one.
/// A GAGS item whose icon_state is its own typepath needs its icon pointed at the map icon file that holds that state.
/datum/unit_test/loadout_icons

/datum/unit_test/loadout_icons/Run()
	for(var/item_type in GLOB.all_loadout_datums)
		var/datum/loadout_item/item = GLOB.all_loadout_datums[item_type]
		if(isnull(item.ui_icon) || isnull(item.ui_icon_state))
			continue
		if(!icon_exists(item.ui_icon, item.ui_icon_state))
			TEST_FAIL("[item.type] ([item.name]) shows icon state \"[item.ui_icon_state]\" from [item.ui_icon], which has no such state.")
