// GAGS items whose icon_state is their own typepath, but whose icon still points at an older file.
// The loadout menu shows icon + icon_state, so these need the map icon file that has the state.

/obj/item/clothing/neck/kink_collar/locked/gps
	icon = 'icons/map_icons/clothing/neck.dmi'

// Upstream sets icon twice on this type, and the second line wins
/obj/item/clothing/suit/croptop
	icon = 'icons/map_icons/clothing/suit/_suit.dmi'
