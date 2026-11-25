// MOD

/datum/mod_theme/policing/maxtac
	name = "MaxTac"
	desc = "A heavy assault build of the policing suit, refitted for psycho-response squads."
	extended_desc = "The policing frame with its thin plating stripped out and replaced by layered plastitanium and ablative ceramics. \
		Power draw is brutal, but the extra system headroom lets the squad run a full combat loadout and an inhibitor field \
		that keeps the wearer's augmentations online through electromagnetic pulses."
	complexity_max = DEFAULT_MAX_COMPLEXITY + 5

/datum/mod_theme/policing/maxtac/New()
	. = ..()
	// Set after the parent so the freelance policing armor does not replace it.
	armor_type = /datum/armor/mod_theme_maxtac

// Between the elite and apocryphal suits.
/datum/armor/mod_theme_maxtac
	melee = 70
	bullet = 70
	laser = 50
	energy = 55
	bomb = 70
	bio = 100
	fire = 100
	acid = 100
	wound = 30

/obj/item/mod/control/pre_equipped/maxtac
	theme = /datum/mod_theme/policing/maxtac
	starting_frequency = MODLINK_FREQ_CENTCOM
	applied_cell = /obj/item/stock_parts/power_store/cell/bluespace
	req_access = list(ACCESS_CENT_SPECOPS)
	// 19 of 20 complexity. Keep 1 free for the plasma stabilizer plasmamen get on spawn.
	applied_modules = list(
		/obj/item/mod/module/emp_shield/advanced,
		/obj/item/mod/module/storage/large_capacity,
		/obj/item/mod/module/status_readout/operational,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/jump_jet,
		/obj/item/mod/module/shooting_assistant,
		/obj/item/mod/module/thermal_regulator,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/magboot,
		// Thermals for synths and proteans, who keep their own eyes.
		/obj/item/mod/module/visor/thermal,
	)
	default_pins = list(
		/obj/item/mod/module/jump_jet,
		/obj/item/mod/module/shooting_assistant,
		/obj/item/mod/module/magboot,
	)

// Implants

/obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac
	name = "MaxTac mantis blade implant"
	desc = "A military arm blade implant with both a hardened steel blade and an energy blade. Not legal for civilians anywhere."
	icon = 'modular_maverick/icons/obj/maxtac/maxtac_implanted_blade.dmi'
	items_to_create = list(
		/obj/item/melee/implantarmblade/maxtac,
		/obj/item/melee/implantarmblade/energy/maxtac,
	)

// Same blades, in police blue.
/obj/item/melee/implantarmblade/maxtac
	icon = 'modular_maverick/icons/obj/maxtac/maxtac_implanted_blade.dmi'
	lefthand_file = 'modular_maverick/icons/mob/inhands/maxtac/maxtac_implanted_blade_lefthand.dmi'
	righthand_file = 'modular_maverick/icons/mob/inhands/maxtac/maxtac_implanted_blade_righthand.dmi'

/obj/item/melee/implantarmblade/energy/maxtac
	icon = 'modular_maverick/icons/obj/maxtac/maxtac_implanted_blade.dmi'
	lefthand_file = 'modular_maverick/icons/mob/inhands/maxtac/maxtac_implanted_blade_lefthand.dmi'
	righthand_file = 'modular_maverick/icons/mob/inhands/maxtac/maxtac_implanted_blade_righthand.dmi'

// Both blades ship unlocked already.
/obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac/emag_act(mob/user, obj/item/card/emag/emag_card)
	return FALSE

/obj/item/organ/cyberimp/eyes/hud/security/maxtac
	name = "MaxTac combat HUD implant"
	desc = "A HUD implant that shows security records and vitals at the same time. Squad, target, everyone."
	HUD_traits = list(TRAIT_SECURITY_HUD, TRAIT_MEDICAL_HUD)

// Belt

/obj/item/storage/belt/military/assault/maxtac

/obj/item/storage/belt/military/assault/maxtac/PopulateContents()
	generate_items_inside(list(
		/obj/item/ammo_box/magazine/smartgun = 4,
		/obj/item/grenade/empgrenade = 2,
	), src)
