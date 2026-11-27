// Paid arm and eye augments for the augments menu. Costs are quirk points.
// Useful implants carry a steep price; leadership tunes the numbers.

/obj/item/organ/cyberimp/arm/toolkit/toolset/left_arm
	zone = BODY_ZONE_L_ARM
	slot = ORGAN_SLOT_LEFT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/surgery/left_arm
	zone = BODY_ZONE_L_ARM
	slot = ORGAN_SLOT_LEFT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/janitor/left_arm
	zone = BODY_ZONE_L_ARM
	slot = ORGAN_SLOT_LEFT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/botany/left_arm
	zone = BODY_ZONE_L_ARM
	slot = ORGAN_SLOT_LEFT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/paperwork/left_arm
	zone = BODY_ZONE_L_ARM
	slot = ORGAN_SLOT_LEFT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/toolset/right_arm
	zone = BODY_ZONE_R_ARM
	slot = ORGAN_SLOT_RIGHT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/surgery/right_arm
	zone = BODY_ZONE_R_ARM
	slot = ORGAN_SLOT_RIGHT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/janitor/right_arm
	zone = BODY_ZONE_R_ARM
	slot = ORGAN_SLOT_RIGHT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/botany/right_arm
	zone = BODY_ZONE_R_ARM
	slot = ORGAN_SLOT_RIGHT_ARM_AUG

/obj/item/organ/cyberimp/arm/toolkit/paperwork/right_arm
	zone = BODY_ZONE_R_ARM
	slot = ORGAN_SLOT_RIGHT_ARM_AUG

/datum/augment_item/implant/l_arm/toolset
	name = "Left Toolset Implant"
	cost = 10
	path = /obj/item/organ/cyberimp/arm/toolkit/toolset/left_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/l_arm/surgery
	name = "Left Surgical Toolset Implant"
	cost = 10
	path = /obj/item/organ/cyberimp/arm/toolkit/surgery/left_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/l_arm/janitor
	name = "Left Janitorial Toolset Implant"
	cost = 6
	path = /obj/item/organ/cyberimp/arm/toolkit/janitor/left_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/l_arm/botany
	name = "Left Botanical Toolset Implant"
	cost = 6
	path = /obj/item/organ/cyberimp/arm/toolkit/botany/left_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/l_arm/paperwork
	name = "Left Paperwork Toolset Implant"
	cost = 3
	path = /obj/item/organ/cyberimp/arm/toolkit/paperwork/left_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/r_arm/toolset
	name = "Right Toolset Implant"
	cost = 10
	path = /obj/item/organ/cyberimp/arm/toolkit/toolset/right_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/r_arm/surgery
	name = "Right Surgical Toolset Implant"
	cost = 10
	path = /obj/item/organ/cyberimp/arm/toolkit/surgery/right_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/r_arm/janitor
	name = "Right Janitorial Toolset Implant"
	cost = 6
	path = /obj/item/organ/cyberimp/arm/toolkit/janitor/right_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/r_arm/botany
	name = "Right Botanical Toolset Implant"
	cost = 6
	path = /obj/item/organ/cyberimp/arm/toolkit/botany/right_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/r_arm/paperwork
	name = "Right Paperwork Toolset Implant"
	cost = 3
	path = /obj/item/organ/cyberimp/arm/toolkit/paperwork/right_arm
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/organ/eyes/cybernetic/shield
	name = "Welding shield eyes"
	path = /obj/item/organ/eyes/robotic/shield/loadout
	cost = 4

/datum/augment_item/organ/eyes/cybernetic/shield_moth
	name = "Welding shield moth eyes"
	path = /obj/item/organ/eyes/robotic/shield/moth/loadout
	cost = 4

// Loadout copies of the welding shield eyes. The stock ones are painted dark grey; these take the character's
// own eye color when they go in, like other robotic eyes, and a multitool can still recolor them.
/obj/item/organ/eyes/robotic/shield/loadout
	eye_color_left = null
	eye_color_right = null

/obj/item/organ/eyes/robotic/shield/moth/loadout
	eye_color_left = null
	eye_color_right = null
