// The base outfit is the assault operative. Every role shares the suit, uniform, ID style and chrome.

/datum/outfit/centcom/ert/maxtac
	name = "MaxTac Assault"

	id = /obj/item/card/id/advanced/black/deathsquad
	id_trim = /datum/id_trim/centcom/deathsquad/maxtac
	uniform = /obj/item/clothing/under/rank/security/officer/beatcop
	head = /obj/item/clothing/head/helmet/toggleable/riot
	ears = /obj/item/radio/headset/headset_cent/alt/maxtac
	// Shove resistance for when the suit is folded away. The suit gives the real protection.
	suit = /obj/item/clothing/suit/armor/riot
	glasses = /obj/item/clothing/glasses/night
	back = /obj/item/mod/control/pre_equipped/maxtac
	belt = /obj/item/storage/belt/military/assault
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	mask = null // The breathing tube implant covers internals.
	r_pocket = /obj/item/tank/internals/emergency_oxygen/double // Ready to hand for a hull breach. Plasmamen get their own tank.
	l_hand = /obj/item/gun/ballistic/automatic/sol_rifle
	box = /obj/item/storage/box/survival/centcom
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/trappiste = 1,
		/obj/item/ammo_box/magazine/c40sol_rifle/standard = 3,
		/obj/item/storage/medkit/regular = 1,
		/obj/item/storage/box/handcuffs = 1,
	)
	additional_radio = /obj/item/encryptionkey/heads/hos

	belt_contents = list(
		/obj/item/ammo_box/magazine/c585trappiste_pistol = 2,
		/obj/item/grenade/empgrenade = 2,
	)
	/// Implant in each arm's augment slot. Strong-Arm goes in both arms for every role.
	var/right_arm_implant = /obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac
	var/left_arm_implant = /obj/item/organ/cyberimp/arm/toolkit/toolset
	/// If TRUE, organic arms are swapped for advanced robotic ones before anything is equipped.
	var/robotic_arms = FALSE
	/// Heart installed at spawn. The commander gets the voltaic heart.
	var/heart_type = /obj/item/organ/heart/cybernetic/tier3
	/// Cybernetics installed at spawn. The suit's advanced EMP shield protects them while it is active.
	var/list/chrome = list(
		/obj/item/organ/cyberimp/brain/anti_stun,
		/obj/item/organ/cyberimp/brain/anti_drop,
		/obj/item/organ/cyberimp/chest/reviver,
		/obj/item/organ/cyberimp/chest/nutriment/plus,
		/obj/item/organ/cyberimp/chest/spine/atlas,
		/obj/item/organ/cyberimp/eyes/hud/security/maxtac,
		/obj/item/organ/cyberimp/mouth/breathing_tube,
		/obj/item/organ/eyes/robotic/thermals,
		/obj/item/organ/ears/cybernetic/volume,
		/obj/item/organ/lungs/cybernetic/tier3,
		/obj/item/organ/liver/cybernetic/tier3,
		/obj/item/organ/stomach/cybernetic/tier3,
	)

/datum/outfit/centcom/ert/maxtac/pre_equip(mob/living/carbon/human/operative, visuals_only = FALSE)
	. = ..()
	if(!robotic_arms || visuals_only)
		return
	// Done before equipping so nothing held gets dropped. Synth and protean arms are not organic and stay.
	var/list/robotic_arm_types = list(
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/robot/advanced,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/robot/advanced,
	)
	for(var/arm_zone in robotic_arm_types)
		var/obj/item/bodypart/arm = operative.get_bodypart(arm_zone)
		if(arm && !IS_ORGANIC_LIMB(arm))
			continue
		var/arm_type = robotic_arm_types[arm_zone]
		operative.del_and_replace_bodypart(new arm_type(), special = TRUE)

/datum/outfit/centcom/ert/maxtac/post_equip(mob/living/carbon/human/operative, visuals_only = FALSE)
	. = ..()
	if(visuals_only)
		return

	put_id_in_pda(operative)

	for(var/organ_type in chrome + heart_type)
		install_chrome(operative, new organ_type())

	var/list/arm_chrome = list(
		BODY_ZONE_R_ARM = list(right_arm_implant, /obj/item/organ/cyberimp/arm/strongarm),
		BODY_ZONE_L_ARM = list(left_arm_implant, /obj/item/organ/cyberimp/arm/strongarm),
	)
	for(var/arm_zone in arm_chrome)
		for(var/arm_type in arm_chrome[arm_zone])
			var/obj/item/organ/arm_implant = new arm_type()
			arm_implant.swap_zone(arm_zone)
			install_chrome(operative, arm_implant)

/// Moves the ID card into a police PDA and wears the PDA in the ID slot.
/datum/outfit/centcom/ert/maxtac/proc/put_id_in_pda(mob/living/carbon/human/operative)
	var/obj/item/card/id/card = operative.wear_id
	if(!istype(card))
		return
	var/obj/item/modular_computer/pda/nri_police/pda = new(operative)
	pda.name = "\improper MaxTac PDA"
	operative.temporarilyRemoveItemFromInventory(card, force = TRUE)
	pda.insert_id(card)
	if(!operative.equip_to_slot_if_possible(pda, ITEM_SLOT_ID, disable_warning = TRUE))
		// Never leave them without an ID.
		pda.remove_id(silent = TRUE)
		operative.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE)
		qdel(pda)
		return
	pda.imprint_id(operative.real_name, card.assignment)

/// Installs an implant if it is safe for this species, deletes it if not.
/datum/outfit/centcom/ert/maxtac/proc/install_chrome(mob/living/carbon/human/operative, obj/item/organ/implant)
	if(!can_install_chrome(operative, implant))
		qdel(implant)
		return
	implant.Insert(operative, movement_flags = DELETE_IF_REPLACED)

/**
 * Checks if an implant can go in without breaking the operative's body.
 *
 * Some species depend on their own organs: the protean orchestrator and refactory, plasmaman and vox lungs,
 * the ethereal stomach, synth organs. For the heart, lungs, liver and stomach we only swap in chrome when the species
 * uses the plain organ. Arm implants always go in, even over the synth power cord. For other implant slots
 * we keep any robotic organ the species gives.
 */
/datum/outfit/centcom/ert/maxtac/proc/can_install_chrome(mob/living/carbon/human/operative, obj/item/organ/implant)
	var/static/list/standard_organs = list(
		ORGAN_SLOT_HEART = /obj/item/organ/heart,
		ORGAN_SLOT_LUNGS = /obj/item/organ/lungs,
		ORGAN_SLOT_LIVER = /obj/item/organ/liver,
		ORGAN_SLOT_STOMACH = /obj/item/organ/stomach,
	)
	var/obj/item/organ/current = operative.get_organ_slot(implant.slot)
	// Protean core organs. Without the orchestrator they cannot stand, without the refactory they cannot repair.
	if(current && (current.organ_flags & (ORGAN_NANOMACHINE | ORGAN_UNREMOVABLE)))
		return FALSE
	// The voltaic heart runs any other body. Eyes and ears only sense, so any species can take cybernetic ones.
	// Proteans grow their own back only if those are missing, so they keep the chrome.
	if(istype(implant, /obj/item/organ/heart/cybernetic/anomalock) || (implant.slot in list(ORGAN_SLOT_EYES, ORGAN_SLOT_EARS)))
		return TRUE
	// The toolset and blades are the squad's kit. They win over whatever the species put in that arm.
	if(istype(implant, /obj/item/organ/cyberimp/arm))
		return TRUE
	var/species_type = operative.dna.species.get_mutant_organ_type_for_slot(implant.slot)
	var/standard_type = standard_organs[implant.slot]
	if(standard_type)
		return species_type == standard_type
	return !(current && IS_ROBOTIC_ORGAN(current) && species_type && istype(current, species_type))

// Roles

/// Squad leader. Robotic arms so they can fire the Malorian, plus the voltaic heart.
/datum/outfit/centcom/ert/maxtac/commander
	name = "MaxTac Commander"

	id_trim = /datum/id_trim/centcom/deathsquad/maxtac/commander
	ears = /obj/item/radio/headset/headset_cent/alt/maxtac/leader
	r_hand = /obj/item/gun/energy/ionrifle/carbine
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/robohand = 1,
		/obj/item/ammo_box/maxtac_14mm = 1,
		/obj/item/ammo_box/magazine/c40sol_rifle/standard = 2,
		/obj/item/storage/medkit/regular = 1,
		/obj/item/storage/box/handcuffs = 1,
	)
	belt_contents = list(
		/obj/item/ammo_box/magazine/m14mm = 3,
		/obj/item/grenade/empgrenade = 2,
	)
	robotic_arms = TRUE
	heart_type = /obj/item/organ/heart/cybernetic/anomalock/prebuilt

/// Close quarters. Mantis blades in both arms, the heavy pistol as backup.
/datum/outfit/centcom/ert/maxtac/mantis
	name = "MaxTac Mantis"

	id_trim = /datum/id_trim/centcom/deathsquad/maxtac/mantis
	l_hand = null
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/trappiste = 1,
		/obj/item/storage/medkit/regular = 1,
		/obj/item/storage/box/handcuffs = 1,
	)
	left_arm_implant = /obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac

/// Walking tank. Suit-mounted smartgun and the bulwark module.
/datum/outfit/centcom/ert/maxtac/heavy
	name = "MaxTac Heavy"

	id_trim = /datum/id_trim/centcom/deathsquad/maxtac/heavy
	back = /obj/item/mod/control/pre_equipped/maxtac/heavy
	l_hand = null
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/trappiste = 1,
		/obj/item/ammo_box/magazine/smartgun_drum = 1,
		/obj/item/storage/medkit/regular = 1,
		/obj/item/storage/box/handcuffs = 1,
	)

/// Long range. Anti-materiel rifle.
/datum/outfit/centcom/ert/maxtac/sniper
	name = "MaxTac Sniper"

	id_trim = /datum/id_trim/centcom/deathsquad/maxtac/sniper
	l_hand = /obj/item/gun/ballistic/automatic/wylom
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/trappiste = 1,
		/obj/item/ammo_box/magazine/wylom = 3,
		/obj/item/storage/medkit/regular = 1,
		/obj/item/storage/box/handcuffs = 1,
	)

/// Squad support. Suit medbeam, combat hypospray, and the smart SMG.
/datum/outfit/centcom/ert/maxtac/medic
	name = "MaxTac Medic"

	id_trim = /datum/id_trim/centcom/deathsquad/maxtac/medic
	back = /obj/item/mod/control/pre_equipped/maxtac/medic
	l_hand = /obj/item/gun/ballistic/automatic/smartgun
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol/trappiste = 1,
		/obj/item/storage/medkit/tactical = 1,
		/obj/item/reagent_containers/hypospray/combat = 1,
		/obj/item/storage/box/handcuffs = 1,
	)
	belt_contents = list(
		/obj/item/ammo_box/magazine/smartgun = 3,
		/obj/item/ammo_box/magazine/c585trappiste_pistol = 1,
		/obj/item/grenade/empgrenade = 2,
	)
