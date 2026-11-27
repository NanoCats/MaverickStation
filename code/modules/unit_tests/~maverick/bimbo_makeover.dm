/// The Bimbonium overdose reality overwrite swaps the outfit, retrims the ID, and leaves pockets and access alone.
/datum/unit_test/bimbo_reality_overwrite

/datum/unit_test/bimbo_reality_overwrite/Run()
	var/mob/living/carbon/human/consistent/target = allocate(/mob/living/carbon/human/consistent)
	target.equipOutfit(/datum/outfit/job/assistant/consistent)
	qdel(target.wear_id)
	var/obj/item/card/id/advanced/card = new(target)
	TEST_ASSERT(target.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "Could not equip the test ID")
	var/list/old_access = card.access.Copy()
	var/obj/item/pen/pocketed = new(target)
	TEST_ASSERT(target.equip_to_slot_if_possible(pocketed, ITEM_SLOT_LPOCKET, disable_warning = TRUE), "Could not pocket the pen")
	var/obj/item/clothing/head/soft/cap = new(target)
	target.equip_to_slot_if_possible(cap, ITEM_SLOT_HEAD, disable_warning = TRUE)

	var/datum/component/bimbo/bimbo = target.AddComponent(/datum/component/bimbo)
	bimbo.reality_overwrite()

	TEST_ASSERT(istype(target.w_uniform, /obj/item/clothing/under/stripper_outfit/bimbo), "Jumpsuit was not turned into the stripper outfit")
	TEST_ASSERT(istype(target.shoes, /obj/item/clothing/shoes/high_heels/bimbo), "Shoes were not turned into heels")
	TEST_ASSERT(istype(target.head, /obj/item/clothing/head/sweet_bow/bimbo), "Hat was not turned into a bow")
	TEST_ASSERT_EQUAL(target.wear_id, card, "The ID card left its slot")
	TEST_ASSERT_EQUAL(card.trim_assignment_override, BIMBO_ID_ASSIGNMENT, "The ID was not retrimmed")
	TEST_ASSERT(card.access ~= old_access, "The overwrite changed ID access")
	TEST_ASSERT_EQUAL(target.l_store, pocketed, "The pocketed pen fell out")

/// With no ID on you at all, the overwrite makes one.
/datum/unit_test/bimbo_reality_overwrite_new_id

/datum/unit_test/bimbo_reality_overwrite_new_id/Run()
	var/mob/living/carbon/human/consistent/target = allocate(/mob/living/carbon/human/consistent)
	var/datum/component/bimbo/bimbo = target.AddComponent(/datum/component/bimbo)
	bimbo.reality_overwrite()
	var/obj/item/card/id/advanced/card = target.get_idcard(hand_first = FALSE)
	TEST_ASSERT(istype(card), "No ID was made")
	TEST_ASSERT_EQUAL(card.registered_name, target.real_name, "The new ID is not registered to the target")
	TEST_ASSERT_EQUAL(card.assignment, BIMBO_ID_ASSIGNMENT, "The new ID does not read Slut")
