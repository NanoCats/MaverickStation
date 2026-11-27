// The Wayward Banner: a black cat with a knife under a band of bright triangles.

/obj/structure/sign/flag/maverick
	name = "Wayward Banner"
	desc = "A vivid banner depicting a knife-wielding black cat beneath a colorful sky. Popular among stubborn idealists, independent thinkers, and people who have discovered that asking nicely only gets you so far."
	icon = 'modular_~maverick/icons/obj/branding/maverick_flag.dmi'
	icon_state = "flag_maverick"
	item_flag = /obj/item/sign/flag/maverick

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/flag/maverick, 32)

/obj/item/sign/flag/maverick
	name = "folded Wayward Banner"
	desc = "A folded Wayward Banner. A knife-wielding black cat beneath a colorful sky, waiting for a wall worth hanging on."
	icon = 'modular_~maverick/icons/obj/branding/maverick_flag.dmi'
	icon_state = "folded_maverick"
	sign_path = /obj/structure/sign/flag/maverick

/datum/loadout_item/inhand/flag_maverick
	name = "Folded Wayward Banner"
	item_path = /obj/item/sign/flag/maverick
