// The technological shell box can't be bought or printed. You refit any empty shotgun shell box into one,
// the same way the improvised shell box is made, but it costs real parts. Once you have it, the box is the
// ammo workbench's key for techshells. The spent buckshot box from cargo is the cheap box to start from.

/obj/item/ammo_box/advanced/s12gauge/techshell/empty
	start_empty = TRUE

/datum/crafting_recipe/techshell_box
	name = "Technological Shell Box"
	desc = "Swap the chip in an empty shotgun shell box for one that takes technological shells. The new chip needs real parts."
	result = /obj/item/ammo_box/advanced/s12gauge/techshell/empty
	reqs = list(
		/obj/item/ammo_box/advanced/s12gauge = 1,
		/obj/item/stock_parts/capacitor/super = 1,
		/obj/item/stack/sheet/mineral/plasma = 2,
		/obj/item/stack/cable_coil = 5,
	)
	blacklist = list(
		/obj/item/ammo_box/advanced/s12gauge/techshell,
		/obj/item/ammo_box/advanced/s12gauge/techshell/empty,
	)
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_MULTITOOL)
	steps = list("Any empty shotgun shell box works, even a spent buckshot box")
	time = 5 SECONDS
	category = CAT_WEAPON_AMMO
	// the box you started with decides the materials, so there's no fixed value to match
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_COLLECT_REQUIREMENTS | CRAFT_SKIP_MATERIALS_PARITY

// refuse while any box in reach still has shells, so nobody loses a box of buckshot to this
/datum/crafting_recipe/techshell_box/check_requirements(mob/user, list/collected_requirements)
	for(var/obj/item/ammo_box/box as anything in collected_requirements[/obj/item/ammo_box/advanced/s12gauge])
		if(length(box.stored_ammo))
			return FALSE
	return TRUE
