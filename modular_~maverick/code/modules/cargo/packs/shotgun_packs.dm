// Shotgun cargo packs as they were before Bubberstation #6450, which MaverickStation vetoes.
// See maverick/upstream_vetoes.md. Each shotgun comes with its pouch, bandolier and shells again,
// so the separate accessories pack and the Woodstock armory crate are hidden instead of deleted.

/datum/supply_pack/goody/ballistic_single
	name = "Peacekeeper Combat Shotgun Single-Pack"
	contains = list(
		/obj/item/gun/ballistic/shotgun/automatic/combat,
		/obj/item/storage/pouch/ammo,
		/obj/item/storage/belt/bandolier,
	)

/datum/supply_pack/goody/nt_shotgun
	desc = "A classic shotgun used by hunters, police and frontiersmen alike, now at an affordable price."
	cost = PAYCHECK_COMMAND * 12
	contains = list(
		/obj/item/gun/ballistic/shotgun/riot,
		/obj/item/storage/pouch/ammo,
		/obj/item/storage/belt/bandolier,
		/obj/item/ammo_box/advanced/s12gauge/hunter,
	)

/datum/supply_pack/goody/renoster_shotgun
	desc = "A common modern shotgun used by Terran Government Police."
	cost = PAYCHECK_COMMAND * 14
	contains = list(
		/obj/item/gun/ballistic/shotgun/riot/sol,
		/obj/item/storage/pouch/ammo,
		/obj/item/storage/belt/bandolier,
		/obj/item/ammo_box/advanced/s12gauge/rubber,
	)

/datum/supply_pack/goody/renoster_shotgun_lesslethal
	name = "Ystervark LTL Shotgun Single-Pack"
	desc = "The police refit of the Renoster, modified to only fire less-lethal rounds."
	contains = list(
		/obj/item/gun/ballistic/shotgun/riot/sol/lesslethal,
		/obj/item/storage/pouch/ammo,
		/obj/item/storage/belt/bandolier,
		/obj/item/ammo_box/advanced/s12gauge/bean,
	)

/datum/supply_pack/goody/double_barrel
	desc = "Lost your beloved bunny to a demonic invasion? Clown broke in and stole your beloved gun? No worries! Get a new gun as long as you can pay the absurd fees."
	cost = PAYCHECK_COMMAND * 10

/datum/supply_pack/goody/shotgun_addons
	order_flags = ORDER_GOODY | ORDER_INVISIBLE

/datum/supply_pack/security/armory/woodstocks
	order_flags = ORDER_INVISIBLE

/datum/supply_pack/security/armory/peacekeepers
	desc = "Three Renoster pump-action shotguns to restock your armories with."
	cost = CARGO_CRATE_VALUE * 10

/datum/supply_pack/security/armory/peacekeepers_plus
	name = "Ystervark LTL Shotgun Crate"
	desc = "Three Ystervark less-lethal pump-action shotguns to restock your armories with, each with a box of beanbag slugs."
	contains = list(
		/obj/item/gun/ballistic/shotgun/riot/sol/lesslethal = 3,
		/obj/item/ammo_box/advanced/s12gauge/bean = 3,
	)
