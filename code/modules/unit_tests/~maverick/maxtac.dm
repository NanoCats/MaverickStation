/// Equips every MaxTac role and checks the kit, the ID, and that species organs survive the chrome.
/datum/unit_test/maxtac

/datum/unit_test/maxtac/Run()
	var/list/roles = list(
		/datum/outfit/centcom/ert/maxtac = "assault",
		/datum/outfit/centcom/ert/maxtac/commander = "commander",
		/datum/outfit/centcom/ert/maxtac/mantis = "mantis",
		/datum/outfit/centcom/ert/maxtac/heavy = "heavy",
		/datum/outfit/centcom/ert/maxtac/sniper = "sniper",
		/datum/outfit/centcom/ert/maxtac/medic = "medic",
	)
	for(var/outfit_type in roles)
		var/mob/living/carbon/human/operative = equip_operative(outfit_type)
		check_common(operative, roles[outfit_type])

	var/mob/living/carbon/human/assault = equip_operative(/datum/outfit/centcom/ert/maxtac)
	TEST_ASSERT(istype(assault.get_organ_slot(ORGAN_SLOT_LEFT_ARM_AUG), /obj/item/organ/cyberimp/arm/toolkit/toolset), "Assault has no toolset.")
	TEST_ASSERT(istype(assault.get_organ_slot(ORGAN_SLOT_HEART), /obj/item/organ/heart/cybernetic/tier3), "Assault has no tier 3 heart.")
	TEST_ASSERT(istype(assault.get_organ_slot(ORGAN_SLOT_LUNGS), /obj/item/organ/lungs/cybernetic/tier3), "Assault has no tier 3 lungs.")

	var/mob/living/carbon/human/commander = equip_operative(/datum/outfit/centcom/ert/maxtac/commander)
	TEST_ASSERT(istype(commander.get_bodypart(BODY_ZONE_R_ARM), /obj/item/bodypart/arm/right/robot/advanced), "Commander right arm is not robotic.")
	TEST_ASSERT(istype(commander.get_bodypart(BODY_ZONE_L_ARM), /obj/item/bodypart/arm/left/robot/advanced), "Commander left arm is not robotic.")
	TEST_ASSERT(istype(commander.get_organ_slot(ORGAN_SLOT_LEFT_ARM_MUSCLE), /obj/item/organ/cyberimp/arm/strongarm), "Commander robotic arm has no Strong-Arm.")
	TEST_ASSERT(istype(commander.get_organ_slot(ORGAN_SLOT_HEART), /obj/item/organ/heart/cybernetic/anomalock/prebuilt), "Commander has no voltaic heart.")
	TEST_ASSERT(locate(/obj/item/gun/ballistic/automatic/pistol/robohand) in commander.back.atom_storage.real_location.contents, "Commander has no Malorian.")

	var/mob/living/carbon/human/mantis = equip_operative(/datum/outfit/centcom/ert/maxtac/mantis)
	TEST_ASSERT(istype(mantis.get_organ_slot(ORGAN_SLOT_LEFT_ARM_AUG), /obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac), "Mantis has no left blade.")

	var/mob/living/carbon/human/heavy = equip_operative(/datum/outfit/centcom/ert/maxtac/heavy)
	var/obj/item/mod/control/heavy_suit = heavy.back
	TEST_ASSERT(locate(/obj/item/mod/module/smartgun) in heavy_suit.modules, "Heavy suit has no smartgun.")
	TEST_ASSERT(locate(/obj/item/mod/module/shove_blocker) in heavy_suit.modules, "Heavy suit has no bulwark.")

	var/mob/living/carbon/human/medic = equip_operative(/datum/outfit/centcom/ert/maxtac/medic)
	var/obj/item/mod/control/medic_suit = medic.back
	TEST_ASSERT(locate(/obj/item/mod/module/medbeam) in medic_suit.modules, "Medic suit has no medbeam.")

	// Synths keep their own organs, and still take the voltaic heart. The toolset replaces the power cord.
	var/mob/living/carbon/human/synth = equip_operative(/datum/outfit/centcom/ert/maxtac/commander, /datum/species/synthetic)
	TEST_ASSERT(istype(synth.get_organ_slot(ORGAN_SLOT_HEART), /obj/item/organ/heart/cybernetic/anomalock/prebuilt), "Synth commander has no voltaic heart.")
	TEST_ASSERT(istype(synth.get_organ_slot(ORGAN_SLOT_STOMACH), /obj/item/organ/stomach/synth), "Synth stomach was replaced.")
	TEST_ASSERT(istype(synth.get_organ_slot(ORGAN_SLOT_LUNGS), /obj/item/organ/lungs/synth), "Synth lungs were replaced.")
	TEST_ASSERT(istype(synth.get_organ_slot(ORGAN_SLOT_LEFT_ARM_AUG), /obj/item/organ/cyberimp/arm/toolkit/toolset), "Synth commander has no toolset.")
	TEST_ASSERT(!istype(synth.get_bodypart(BODY_ZONE_R_ARM), /obj/item/bodypart/arm/right/robot/advanced), "Synth arm was replaced.")

	// Proteans keep the orchestrator and refactory, get no lungs, and keep the suit's EMP shield.
	var/mob/living/carbon/human/protean = equip_operative(/datum/outfit/centcom/ert/maxtac/commander, /datum/species/protean)
	TEST_ASSERT(istype(protean.get_organ_slot(ORGAN_SLOT_HEART), /obj/item/organ/heart/protean), "Protean orchestrator was replaced.")
	TEST_ASSERT(istype(protean.get_organ_slot(ORGAN_SLOT_STOMACH), /obj/item/organ/stomach/protean), "Protean refactory was replaced.")
	TEST_ASSERT(istype(protean.get_organ_slot(ORGAN_SLOT_LIVER), /obj/item/organ/liver/protean), "Protean liver was replaced.")
	TEST_ASSERT_NULL(protean.get_organ_slot(ORGAN_SLOT_LUNGS), "Protean was given lungs.")
	TEST_ASSERT(!istype(protean.get_bodypart(BODY_ZONE_R_ARM), /obj/item/bodypart/arm/right/robot/advanced), "Protean arm was replaced.")
	var/datum/species/protean/protean_species = protean.dna.species
	TEST_ASSERT(locate(/obj/item/mod/module/emp_shield/advanced) in protean_species.species_modsuit.modules, "Protean suit did not take the advanced EMP shield.")

	// Plasmamen keep their own lungs.
	var/mob/living/carbon/human/plasmaman = equip_operative(/datum/outfit/centcom/ert/maxtac, /datum/species/plasmaman)
	TEST_ASSERT(istype(plasmaman.get_organ_slot(ORGAN_SLOT_LUNGS), /obj/item/organ/lungs/plasmaman), "Plasmaman lungs were replaced.")

/datum/unit_test/maxtac/proc/equip_operative(outfit_type, species_type)
	var/mob/living/carbon/human/consistent/operative = allocate(/mob/living/carbon/human/consistent)
	if(species_type)
		operative.set_species(species_type)
	operative.equipOutfit(outfit_type)
	return operative

/datum/unit_test/maxtac/proc/check_common(mob/living/carbon/human/operative, role)
	var/obj/item/card/id/card = operative.wear_id
	TEST_ASSERT(istype(card, /obj/item/card/id/advanced/black/deathsquad), "[role]: wrong ID card [card?.type].")
	TEST_ASSERT_EQUAL(card.assignment, "MaxTac [capitalize(role)]", "[role]: wrong ID assignment.")
	TEST_ASSERT(istype(operative.w_uniform, /obj/item/clothing/under/rank/security/officer/beatcop), "[role]: wrong uniform.")
	TEST_ASSERT(istype(operative.glasses, /obj/item/clothing/glasses/night), "[role]: no night vision goggles.")
	var/obj/item/mod/control/pre_equipped/suit = operative.back
	TEST_ASSERT(istype(suit), "[role]: no MODsuit.")
	TEST_ASSERT_EQUAL(length(suit.modules), length(suit.applied_modules), "[role]: suit is missing modules.")
	TEST_ASSERT(locate(/obj/item/mod/module/holster) in suit.modules, "[role]: suit has no holster.")
	// The suit deploys at spawn, so the beret and riot armor sit inside the helmet and chestplate until it folds away.
	var/datum/mod_part/helmet_part = suit.get_part_datum_from_slot(ITEM_SLOT_HEAD)
	var/datum/mod_part/chest_part = suit.get_part_datum_from_slot(ITEM_SLOT_OCLOTHING)
	TEST_ASSERT(istype(helmet_part?.overslotting, /obj/item/clothing/head/beret/sec), "[role]: no beret under the helmet.")
	TEST_ASSERT(istype(chest_part?.overslotting, /obj/item/clothing/suit/armor/riot), "[role]: no riot armor under the chestplate.")
	TEST_ASSERT(istype(operative.get_organ_slot(ORGAN_SLOT_RIGHT_ARM_AUG), /obj/item/organ/cyberimp/arm/toolkit/armblade/maxtac), "[role]: no right mantis blade.")
	TEST_ASSERT(istype(operative.get_organ_slot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/robotic/thermals), "[role]: no thermal eyes.")
	TEST_ASSERT(istype(operative.get_organ_slot(ORGAN_SLOT_EARS), /obj/item/organ/ears/cybernetic/volume), "[role]: no volume ears.")
	TEST_ASSERT(HAS_TRAIT(operative, TRAIT_MEDICAL_HUD) && HAS_TRAIT(operative, TRAIT_SECURITY_HUD), "[role]: HUD implant is not working.")
	for(var/obj/item/spilled in get_turf(operative))
		TEST_FAIL("[role]: [spilled.type] did not fit and fell on the floor.")
