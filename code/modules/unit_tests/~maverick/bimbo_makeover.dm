/// The Bimbonium overdose makeover swaps jumpsuit and shoes, retrims the ID, and leaves pockets and access alone.
/datum/unit_test/bimbo_full_makeover

/datum/unit_test/bimbo_full_makeover/Run()
	var/mob/living/carbon/human/consistent/target = allocate(/mob/living/carbon/human/consistent)
	target.equipOutfit(/datum/outfit/job/assistant/consistent)
	qdel(target.wear_id)
	var/obj/item/card/id/advanced/card = new(target)
	TEST_ASSERT(target.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "Could not equip the test ID")
	var/list/old_access = card.access.Copy()
	var/obj/item/pen/pocketed = new(target)
	TEST_ASSERT(target.equip_to_slot_if_possible(pocketed, ITEM_SLOT_LPOCKET, disable_warning = TRUE), "Could not pocket the pen")

	var/datum/component/bimbo/bimbo = target.AddComponent(/datum/component/bimbo)
	bimbo.full_makeover()

	TEST_ASSERT(istype(target.w_uniform, /obj/item/clothing/under/stripper_outfit/bimbo), "Jumpsuit was not turned into the stripper outfit")
	TEST_ASSERT(istype(target.shoes, /obj/item/clothing/shoes/high_heels/bimbo), "Shoes were not turned into heels")
	TEST_ASSERT_EQUAL(target.wear_id, card, "The ID card left its slot")
	TEST_ASSERT_EQUAL(card.trim_assignment_override, BIMBO_ID_ASSIGNMENT, "The ID was not retrimmed")
	TEST_ASSERT(card.access ~= old_access, "The makeover changed ID access")
	TEST_ASSERT_EQUAL(target.l_store, pocketed, "The pocketed pen fell out")
