/datum/outfit/centcom/ert/maxtac
	name = "MaxTac Operative"

	id = /obj/item/card/id/advanced/centcom/ert/security
	id_trim = /datum/id_trim/centcom/ert/security/maxtac
	uniform = /obj/item/clothing/under/syndicate/combat
	back = /obj/item/mod/control/pre_equipped/maxtac
	belt = /obj/item/storage/belt/military/assault/maxtac
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	mask = null // The breathing tube implant covers internals.
	l_hand = /obj/item/gun/ballistic/automatic/smartgun
	box = /obj/item/storage/box/survival/centcom
	backpack_contents = list(
		/obj/item/storage/medkit/regular = 1,
		/obj/item/storage/box/handcuffs = 1,
	)
	additional_radio = /obj/item/encryptionkey/heads/hos

	/// Heart installed at spawn. The leader gets the voltaic heart.
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
		/obj/item/organ/ears/cybernetic/upgraded,
		/obj/item/organ/lungs/cybernetic/tier3,
		/obj/item/organ/liver/cybernetic/tier3,
		/obj/item/organ/stomach/cybernetic/tier3,
	)

/datum/outfit/centcom/ert/maxtac/post_equip(mob/living/carbon/human/operative, visuals_only = FALSE)
	. = ..()
	if(visuals_only)
		return

	for(var/organ_type in chrome + heart_type)
		install_chrome(operative, new organ_type())

	// Strong-Arm musculature in both arms, the mantis blade in the right and a toolset in the left.
	// Synths keep their power cord in the left arm, so they lose the toolset but keep the blade.
	var/list/arm_chrome = list(
		BODY_ZONE_R_ARM = list(/obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac, /obj/item/organ/cyberimp/arm/strongarm),
		BODY_ZONE_L_ARM = list(/obj/item/organ/cyberimp/arm/toolkit/toolset, /obj/item/organ/cyberimp/arm/strongarm),
	)
	for(var/arm_zone in arm_chrome)
		for(var/arm_type in arm_chrome[arm_zone])
			var/obj/item/organ/arm_implant = new arm_type()
			arm_implant.swap_zone(arm_zone)
			install_chrome(operative, arm_implant)


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
 * the ethereal stomach, synth organs. For the standard organ slots we only swap in chrome when the species uses
 * the plain organ. For implant slots we keep any robotic organ the species gives, like the synth power cord.
 */
/datum/outfit/centcom/ert/maxtac/proc/can_install_chrome(mob/living/carbon/human/operative, obj/item/organ/implant)
	var/static/list/standard_organs = list(
		ORGAN_SLOT_HEART = /obj/item/organ/heart,
		ORGAN_SLOT_LUNGS = /obj/item/organ/lungs,
		ORGAN_SLOT_LIVER = /obj/item/organ/liver,
		ORGAN_SLOT_STOMACH = /obj/item/organ/stomach,
		ORGAN_SLOT_EYES = /obj/item/organ/eyes,
		ORGAN_SLOT_EARS = /obj/item/organ/ears,
	)
	var/obj/item/organ/current = operative.get_organ_slot(implant.slot)
	// Protean core organs. Without the orchestrator they cannot stand, without the refactory they cannot repair.
	if(current && (current.organ_flags & (ORGAN_NANOMACHINE | ORGAN_UNREMOVABLE)))
		return FALSE
	// The voltaic heart runs any other body.
	if(istype(implant, /obj/item/organ/heart/cybernetic/anomalock))
		return TRUE
	var/species_type = operative.dna.species.get_mutant_organ_type_for_slot(implant.slot)
	var/standard_type = standard_organs[implant.slot]
	if(standard_type)
		return species_type == standard_type
	return !(current && IS_ROBOTIC_ORGAN(current) && species_type && istype(current, species_type))

/datum/outfit/centcom/ert/maxtac/leader
	name = "MaxTac Squad Leader"

	id = /obj/item/card/id/advanced/centcom/ert/commander
	id_trim = /datum/id_trim/centcom/ert/commander/maxtac
	ears = /obj/item/radio/headset/headset_cent/alt/leader
	r_hand = /obj/item/gun/energy/ionrifle
	heart_type = /obj/item/organ/heart/cybernetic/anomalock/prebuilt
