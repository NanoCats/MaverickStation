// Tech shell boxes: the boxes for the shells you craft from a technological shell (pulse, FRAG-12, ion, meteor).
// A shell box is the ammo workbench's key for its round, so these boxes must not come cheap.
// You refit any empty shotgun shell box with a screwdriver, the same way the improvised shell box is made,
// and calibrate the new chip with a few finished shells of that type, which the refit uses up.
// The spent buckshot box from cargo is the cheap box to start from.
// Dangerous rounds still need a hacked bench or the ammo disk before they print.

/// How many finished shells a tech shell box refit uses up
#define TECH_SHELL_BOX_SAMPLES 3

/datum/crafting_recipe/tech_shell_box
	abstract_type = /datum/crafting_recipe/tech_shell_box
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_MULTITOOL)
	blacklist = list(/obj/item/ammo_box/advanced/s12gauge/junk)
	steps = list(
		"Any empty shotgun shell box works, even a spent buckshot box",
		"The finished shells calibrate the new chip and are used up",
	)
	time = 5 SECONDS
	category = CAT_WEAPON_AMMO
	// the box you started with decides the materials, so there's no fixed value to match
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_COLLECT_REQUIREMENTS | CRAFT_SKIP_MATERIALS_PARITY

// refuse while any box in reach still has shells, so nobody loses a box of buckshot to this
/datum/crafting_recipe/tech_shell_box/check_requirements(mob/user, list/collected_requirements)
	for(var/obj/item/ammo_box/box as anything in collected_requirements[/obj/item/ammo_box/advanced/s12gauge])
		if(length(box.stored_ammo))
			return FALSE
	return TRUE

/datum/crafting_recipe/tech_shell_box/pulse
	name = "Pulse Slug Box"
	desc = "Swap the chip in an empty shotgun shell box for one calibrated to pulse slugs."
	result = /obj/item/ammo_box/advanced/s12gauge/pulse/empty
	reqs = list(
		/obj/item/ammo_box/advanced/s12gauge = 1,
		/obj/item/ammo_casing/shotgun/pulseslug = TECH_SHELL_BOX_SAMPLES,
	)

/datum/crafting_recipe/tech_shell_box/frag12
	name = "FRAG-12 Slug Box"
	desc = "Swap the chip in an empty shotgun shell box for one calibrated to FRAG-12 slugs."
	result = /obj/item/ammo_box/advanced/s12gauge/frag12/empty
	reqs = list(
		/obj/item/ammo_box/advanced/s12gauge = 1,
		/obj/item/ammo_casing/shotgun/frag12 = TECH_SHELL_BOX_SAMPLES,
	)

/datum/crafting_recipe/tech_shell_box/ion
	name = "Ion Shell Box"
	desc = "Swap the chip in an empty shotgun shell box for one calibrated to ion scatter shells."
	result = /obj/item/ammo_box/advanced/s12gauge/ion/empty
	reqs = list(
		/obj/item/ammo_box/advanced/s12gauge = 1,
		/obj/item/ammo_casing/shotgun/ion = TECH_SHELL_BOX_SAMPLES,
	)

/datum/crafting_recipe/tech_shell_box/meteor
	name = "Meteor Slug Box"
	desc = "Swap the chip in an empty shotgun shell box for one calibrated to meteor slugs."
	result = /obj/item/ammo_box/advanced/s12gauge/meteor/empty
	reqs = list(
		/obj/item/ammo_box/advanced/s12gauge = 1,
		/obj/item/ammo_casing/shotgun/meteorslug = TECH_SHELL_BOX_SAMPLES,
	)

/obj/item/ammo_box/advanced/s12gauge/pulse/empty
	start_empty = TRUE

/obj/item/ammo_box/advanced/s12gauge/frag12/empty
	start_empty = TRUE

/obj/item/ammo_box/advanced/s12gauge/ion/empty
	start_empty = TRUE

/obj/item/ammo_box/advanced/s12gauge/meteor/empty
	start_empty = TRUE

#undef TECH_SHELL_BOX_SAMPLES
