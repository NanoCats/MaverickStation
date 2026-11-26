// Combat MOD themes hold a gun in suit storage, the same as armor vests do.
// Upstream only lets most of these hold melee and restraints, so a gun needs the magnetic harness module.

/datum/mod_theme
	/// If TRUE, guns and holsters fit in this theme's suit storage
	var/combat_suit = FALSE

/datum/mod_theme/New()
	. = ..()
	if(!combat_suit)
		return
	allowed_suit_storage |= list(
		/obj/item/gun/ballistic,
		/obj/item/gun/energy,
		/obj/item/storage/belt/holster/detective,
		/obj/item/storage/belt/holster/nukie,
		/obj/item/storage/belt/holster/energy,
	)

/datum/mod_theme/apocryphal
	combat_suit = TRUE

/datum/mod_theme/asset_protection
	combat_suit = TRUE

/datum/mod_theme/blueshield
	combat_suit = TRUE

/datum/mod_theme/contractor
	combat_suit = TRUE

/datum/mod_theme/corporate
	combat_suit = TRUE

/datum/mod_theme/covert
	combat_suit = TRUE

/datum/mod_theme/daimyo
	combat_suit = TRUE

/datum/mod_theme/elite
	combat_suit = TRUE

/datum/mod_theme/frontline
	combat_suit = TRUE

/datum/mod_theme/infiltrator
	combat_suit = TRUE

/datum/mod_theme/interdyne
	combat_suit = TRUE

/datum/mod_theme/magnate
	combat_suit = TRUE

/datum/mod_theme/marines
	combat_suit = TRUE

/datum/mod_theme/medical/corpsman
	combat_suit = TRUE

/datum/mod_theme/ninja
	combat_suit = TRUE

/datum/mod_theme/policing
	combat_suit = TRUE

/datum/mod_theme/responsory
	combat_suit = TRUE

/datum/mod_theme/safeguard
	combat_suit = TRUE

/datum/mod_theme/security
	combat_suit = TRUE

/datum/mod_theme/syndicate
	combat_suit = TRUE

/datum/mod_theme/tarkon
	combat_suit = TRUE

/datum/mod_theme/voskhod
	combat_suit = TRUE
