/// A succubus milk overdose with breast enlargement consent shreds the jumpsuit and spills milk, once.
/datum/unit_test/succubus_overdose_burst

/datum/unit_test/succubus_overdose_burst/Run()
	var/mob/living/carbon/human/consistent/drinker = allocate(/mob/living/carbon/human/consistent)
	drinker.equipOutfit(/datum/outfit/job/assistant/consistent)
	var/obj/item/clothing/under/uniform = drinker.w_uniform
	TEST_ASSERT_NOTNULL(uniform, "Test human has no jumpsuit")
	var/obj/item/organ/genital/breasts/breasts = new
	breasts.Insert(drinker, FALSE, FALSE)

	var/datum/reagent/drug/aphrodisiac/succubus_milk/milk = new
	milk.burst_out_of_clothes(drinker)

	TEST_ASSERT_EQUAL(uniform.damaged_clothes, CLOTHING_SHREDDED, "Jumpsuit was not shredded")
	TEST_ASSERT_NULL(drinker.w_uniform, "Shredded jumpsuit stayed on")
	var/turf/floor = get_turf(drinker)
	TEST_ASSERT(floor.liquids?.reagent_list[/datum/reagent/consumable/breast_milk], "No milk was spilled")
	qdel(milk)
	if(floor.liquids)
		qdel(floor.liquids)
