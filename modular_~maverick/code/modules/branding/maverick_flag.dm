// The cat flag: a teal banner with a band of triangles and a black cat carrying a knife.

/obj/structure/sign/flag/maverick
	name = "flag of the knife cat"
	desc = "A teal banner with a band of bright triangles and a black cat carrying a knife in its teeth. Whoever hung this is not here to negotiate."
	icon = 'modular_~maverick/icons/obj/branding/maverick_flag.dmi'
	icon_state = "flag_maverick"
	item_flag = /obj/item/sign/flag/maverick

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/flag/maverick, 32)

/obj/item/sign/flag/maverick
	name = "folded flag of the knife cat"
	desc = "The folded flag of the knife cat. Hang it somewhere people will see it."
	icon = 'modular_~maverick/icons/obj/branding/maverick_flag.dmi'
	icon_state = "folded_maverick"
	sign_path = /obj/structure/sign/flag/maverick

/datum/loadout_item/inhand/flag_maverick
	name = "Folded Knife Cat Flag"
	item_path = /obj/item/sign/flag/maverick
