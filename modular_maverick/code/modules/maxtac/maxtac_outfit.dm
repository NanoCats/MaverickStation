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

	/// Cybernetics installed at spawn. Every one of them is EMP hardened.
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
		/obj/item/organ/heart/cybernetic/tier3,
		/obj/item/organ/lungs/cybernetic/tier3,
		/obj/item/organ/liver/cybernetic/tier3,
		/obj/item/organ/stomach/cybernetic/tier3,
	)

/datum/outfit/centcom/ert/maxtac/post_equip(mob/living/carbon/human/operative, visuals_only = FALSE)
	. = ..()
	if(visuals_only)
		return

	for(var/organ_type in chrome)
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

	harden_against_emp(operative)

/// Installs an implant, unless that slot holds a robotic organ the species needs (synth power cord, protean heart, and so on).
/datum/outfit/centcom/ert/maxtac/proc/install_chrome(mob/living/carbon/human/operative, obj/item/organ/implant)
	var/obj/item/organ/current = operative.get_organ_slot(implant.slot)
	if(current && IS_ROBOTIC_ORGAN(current))
		var/species_type = operative.dna.species.get_mutant_organ_type_for_slot(implant.slot)
		if(species_type && istype(current, species_type))
			qdel(implant)
			return
	implant.Insert(operative, movement_flags = DELETE_IF_REPLACED)

/// Makes every organ and limb the operative has EMP proof, so their chrome (and a synth's whole body) keeps working.
/datum/outfit/centcom/ert/maxtac/proc/harden_against_emp(mob/living/carbon/human/operative)
	for(var/obj/item/organ/organ as anything in operative.organs)
		organ.AddElement(/datum/element/empprotection, EMP_PROTECT_SELF)
	for(var/obj/item/bodypart/limb as anything in operative.bodyparts)
		limb.AddElement(/datum/element/empprotection, EMP_PROTECT_SELF)

/datum/outfit/centcom/ert/maxtac/leader
	name = "MaxTac Squad Leader"

	id = /obj/item/card/id/advanced/centcom/ert/commander
	id_trim = /datum/id_trim/centcom/ert/commander/maxtac
	ears = /obj/item/radio/headset/headset_cent/alt/leader
	r_hand = /obj/item/gun/energy/ionrifle
