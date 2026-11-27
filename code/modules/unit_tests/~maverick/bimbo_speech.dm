/// The bimbo accent should sound ditzy, not broken: one opener at most, important words intact.
/datum/unit_test/bimbo_speech

/datum/unit_test/bimbo_speech/Run()
	var/mob/living/carbon/human/consistent/speaker = allocate(/mob/living/carbon/human/consistent)
	var/datum/component/bimbo/bimbo = speaker.AddComponent(/datum/component/bimbo, BIMBO_MAX_INTENSITY)
	var/static/list/stacked_openers = list("Um, hey", "Like, hey", "Omg, hey", "Okay so, hey")
	for(var/i in 1 to 50)
		var/result = bimbo.bimbofy_message("Hey so I got shot with a firearm and I feel weird, medical.", BIMBO_MAX_INTENSITY)
		TEST_ASSERT(findtext(result, "medical"), "A kept word was lost: [result]")
		for(var/opener in stacked_openers)
			TEST_ASSERT(!findtext(result, opener), "Stacked an opener onto a line that already had one: [result]")
		TEST_ASSERT(length(splittext(result, "like,")) <= 3, "Too many likes: [result]")

