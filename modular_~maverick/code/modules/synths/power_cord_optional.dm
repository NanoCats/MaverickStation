// The synth power cord is an optional augment instead of something every synth is born with.
// Synths can still refuel by drinking welding fuel or using a cyborg recharger. Anyone who wants
// the cord picks the free "Synth Interfacing Hardware" arm implant in the augments menu.

/datum/species/synthetic
	mutant_organs = list()

/datum/augment_item/implant/l_arm/power_cord
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC

/datum/augment_item/implant/r_arm/power_cord
	allowed_biotypes = MOB_ORGANIC | MOB_ROBOTIC
