/// Jobs whose crew get a themed name in place of a normal one, and the name preference that rolls it
GLOBAL_LIST_INIT(amas_job_name_preferences, list(
	/datum/job/clown = /datum/preference/name/clown,
	/datum/job/mime = /datum/preference/name/mime,
))

/**
 * Builds an AMAS automaton on the given turf, dressed and carded for the given job.
 *
 * This does not touch job slots. The automaton gets the job's outfit, ID access and a bank account, but SSjob never knows it exists.
 */
/proc/create_amas_automaton(turf/spawn_turf, datum/job/job)
	var/mob/living/carbon/human/automaton = new(spawn_turf)
	automaton.set_species(/datum/species/android/amas_automaton)
	automaton.gender = pick(MALE, FEMALE)
	automaton.physique = automaton.gender
	automaton.voice = SStts.random_tts_voice(automaton.gender)
	automaton.fully_replace_character_name(automaton.real_name, generate_random_name(automaton.gender, unique = TRUE))
	automaton.dna.features["flavor_text"] = AMAS_AUTOMATON_FLAVOR_TEXT
	automaton.job = job.title
	automaton.on_job_equipping(job, null)

	// Renamed after equipping so the ID card and PDA pick up the new name
	var/name_preference = GLOB.amas_job_name_preferences[job.type]
	if(name_preference)
		automaton.apply_pref_name(name_preference)

	automaton.update_body(is_creating = TRUE)
	SSamas.register_automaton(automaton)
	return automaton
