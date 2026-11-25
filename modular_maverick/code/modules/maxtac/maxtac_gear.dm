// MOD

/datum/mod_theme/policing/maxtac
	name = "MaxTac"
	desc = "A heavy assault build of the policing suit, refitted for psycho-response squads."
	extended_desc = "The policing frame with its thin plating stripped out and replaced by layered plastitanium and ablative ceramics. \
		Power draw is brutal, but the extra system headroom lets the squad run a full combat loadout and an inhibitor field \
		that keeps the wearer's augmentations online through electromagnetic pulses."
	complexity_max = DEFAULT_MAX_COMPLEXITY + 7

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
	// 17 of 22 complexity. Always keep at least 1 free for the plasma stabilizer plasmamen get on spawn.
	applied_modules = list(
		/obj/item/mod/module/emp_shield/advanced,
		/obj/item/mod/module/storage/large_capacity,
		/obj/item/mod/module/status_readout/operational,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/shooting_assistant,
		/obj/item/mod/module/thermal_regulator,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/magboot,
		// Thermals for synths and proteans, who keep their own eyes.
		/obj/item/mod/module/visor/thermal,
	)
	default_pins = list(
		/obj/item/mod/module/shooting_assistant,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/magboot,
		/obj/item/mod/module/visor/thermal,
	)

// Heavy: trades the shooting assistant for the suit-mounted smartgun and the bulwark. 20 of 22 complexity.
/obj/item/mod/control/pre_equipped/maxtac/heavy
	applied_modules = list(
		/obj/item/mod/module/emp_shield/advanced,
		/obj/item/mod/module/storage/large_capacity,
		/obj/item/mod/module/status_readout/operational,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/smartgun,
		/obj/item/mod/module/shove_blocker,
		/obj/item/mod/module/thermal_regulator,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/magboot,
		/obj/item/mod/module/visor/thermal,
	)
	default_pins = list(
		/obj/item/mod/module/smartgun,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/magboot,
		/obj/item/mod/module/visor/thermal,
	)

// Medic: adds the medical beamgun. 18 of 22 complexity.
/obj/item/mod/control/pre_equipped/maxtac/medic
	applied_modules = list(
		/obj/item/mod/module/emp_shield/advanced,
		/obj/item/mod/module/storage/large_capacity,
		/obj/item/mod/module/status_readout/operational,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/shooting_assistant,
		/obj/item/mod/module/medbeam,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/thermal_regulator,
		/obj/item/mod/module/magboot,
		/obj/item/mod/module/visor/thermal,
	)
	default_pins = list(
		/obj/item/mod/module/medbeam,
		/obj/item/mod/module/shooting_assistant,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/magboot,
		/obj/item/mod/module/visor/thermal,
	)

// Implants

/obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac
	name = "MaxTac mantis blade implant"
	desc = "A military energy blade implant. Not legal for civilians anywhere."
	icon = 'modular_maverick/icons/obj/maxtac/maxtac_implanted_blade.dmi'
	// One blade only, so the use key deploys it straight away with no menu.
	items_to_create = list(/obj/item/melee/implantarmblade/energy/maxtac)

// The energy blade, in police blue.
/obj/item/melee/implantarmblade/energy/maxtac
	icon = 'modular_maverick/icons/obj/maxtac/maxtac_implanted_blade.dmi'
	lefthand_file = 'modular_maverick/icons/mob/inhands/maxtac/maxtac_implanted_blade_lefthand.dmi'
	righthand_file = 'modular_maverick/icons/mob/inhands/maxtac/maxtac_implanted_blade_righthand.dmi'

// The blade ships unlocked already.
/obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac/emag_act(mob/user, obj/item/card/emag/emag_card)
	return FALSE

/obj/item/organ/cyberimp/eyes/hud/security/maxtac
	name = "MaxTac combat HUD implant"
	desc = "A HUD implant that shows security records and vitals at the same time. Squad, target, everyone."
	HUD_traits = list(TRAIT_SECURITY_HUD, TRAIT_MEDICAL_HUD)

// Headsets. The CentCom bowman, on the guard bowman frame in MaxTac colors: dark body, police blue stripe.
/obj/item/radio/headset/headset_cent/alt/maxtac
	name = "MaxTac bowman headset"
	desc = "A bowman headset for MaxTac operatives. Protects ears from flashbangs."
	icon = 'modular_zubbers/icons/obj/devices/guard_bowman.dmi'
	worn_icon = 'modular_zubbers/icons/mob/clothing/guard_bowman_worn.dmi'
	icon_state = "guard_bowman"
	worn_icon_state = "guard_bowman"
	post_init_icon_state = "guard_bowman"
	greyscale_config = /datum/greyscale_config/guard_bowman
	greyscale_config_worn = /datum/greyscale_config/guard_bowman/worn
	greyscale_colors = "#2a2b38#2f62d8"

/obj/item/radio/headset/headset_cent/alt/maxtac/Initialize(mapload)
	. = ..()
	update_icon(UPDATE_OVERLAYS)

/obj/item/radio/headset/headset_cent/alt/maxtac/leader
	name = "MaxTac commander bowman headset"
	command = TRUE
