// Hooks for MODsuit GAGS that would otherwise be additions inside upstream files.

/obj/item
	/// If TRUE, species fallback sprites sample colors from the worn sprite even when the item uses GAGS.
	var/sample_worn_colors_for_fallback = FALSE

/// The paint kit sits next to the spray cans in the loadout
/datum/loadout_item/toys/art/mod_paint_kit
	name = "MOD Paint Kit"
	item_path = /obj/item/mod/paint

/// Surplus Frontline suits start with a darker paint job instead of a grey tint
/datum/mod_theme/frontline/surplus/get_gags_default_colors(datum/mod_gags_skin/entry)
	if(entry.skin == "frontline")
		return "#323a29#ffce23#ffc601"
	return ..()

/// Closes the window when the target is deleted. Before, the menu was deleted and the window stayed open on it.
/datum/greyscale_modify_menu/proc/on_target_deleted(datum/source)
	SIGNAL_HANDLER
	SStgui.close_uis(src)
	if(!QDELETED(src))
		qdel(src)

/obj/item/mod/control/pre_equipped/protean
	/// Our own skin, kept while we wear an assimilated suit
	var/own_skin
	/// Our own paint colors, kept while we wear an assimilated suit
	var/own_gags_colors

/// Paint on an assimilated suit goes to the stored suit too, so it keeps the same colors when it comes out
/obj/item/mod/control/pre_equipped/protean/set_gags_colors(colors)
	. = ..()
	if(.)
		sync_stored_look()

/// Copies our current skin and paint to the assimilated suit, so it comes out looking the way we wore it
/obj/item/mod/control/pre_equipped/protean/proc/sync_stored_look()
	if(!stored_theme || QDELETED(stored_modsuit))
		return
	if(stored_modsuit.skin != skin)
		stored_modsuit.theme.set_skin(stored_modsuit, skin)
	if(greyscale_colors && stored_modsuit.get_gags_skin())
		stored_modsuit.set_gags_colors(greyscale_colors)
