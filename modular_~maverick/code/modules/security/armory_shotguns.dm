// Puts the Renoster back in the armory shotgun rack.
// Upstream swapped the two Renosters here for three Woodstocks (Bubberstation #6450).
// MaverickStation vetoes that part, see maverick/upstream_vetoes.md.
/obj/effect/spawner/armory_spawn/shotguns
	guns = list(
		/obj/item/gun/ballistic/shotgun/riot/sol,
		/obj/item/gun/ballistic/shotgun/riot/sol,
		/obj/item/gun/ballistic/shotgun/riot/sol/lesslethal,
		/obj/item/gun/ballistic/shotgun/riot/sol/lesslethal,
		/obj/item/gun/ballistic/bow/security,
	)
