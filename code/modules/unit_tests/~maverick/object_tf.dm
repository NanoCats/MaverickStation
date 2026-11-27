/// Someone turned into an object comes back out when the object is destroyed, with stasis gone.
/datum/unit_test/object_tf_release

/datum/unit_test/object_tf_release/Run()
	var/mob/living/carbon/human/consistent/victim = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/pen/shape = allocate(/obj/item/pen)
	var/turf/start = get_turf(victim)

	victim.AddComponent(/datum/component/object_tf, shape)
	TEST_ASSERT_EQUAL(victim.loc, shape, "Victim was not moved into the object")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_STASIS), "Victim was not put in stasis")

	qdel(shape)
	TEST_ASSERT_EQUAL(victim.loc, start, "Victim was not released onto the floor when the object was destroyed")
	TEST_ASSERT_NULL(victim.GetComponent(/datum/component/object_tf), "Component stayed after release")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_STASIS), "Victim stayed in stasis after release")

/// The OOC Safe Word gets someone out of an object.
/datum/unit_test/object_tf_safeword

/datum/unit_test/object_tf_safeword/Run()
	var/mob/living/carbon/human/consistent/victim = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/pen/shape = allocate(/obj/item/pen)
	var/turf/start = get_turf(victim)

	victim.AddComponent(/datum/component/object_tf, shape)
	TEST_ASSERT_EQUAL(victim.loc, shape, "Victim was not moved into the object")
	victim.__gvb_safeword(list()) // The verb body; the verb itself queues through SSverbs and needs a player
	TEST_ASSERT_EQUAL(victim.loc, start, "Safe word did not release the victim")
	TEST_ASSERT_NULL(victim.GetComponent(/datum/component/object_tf), "Component stayed after the safe word")
