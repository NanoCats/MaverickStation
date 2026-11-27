/mob/living/carbon/human/proc/adjust_pleasure(pleas = 0)
	#ifndef TESTING
	if(stat >= DEAD || !mob_consents(/datum/preference/toggle/erp)) // MAVERICK EDIT - Debug consent: mob_consents() in place of client?.prefs?.read_preference()
		return
	#endif

	pleasure = clamp(pleasure + pleas, AROUSAL_MINIMUM, AROUSAL_LIMIT)

	if(pleasure >= AROUSAL_AUTO_CLIMAX_THRESHOLD) // lets cum
		climax(manual = FALSE)
