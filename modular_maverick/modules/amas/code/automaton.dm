/**
 * Builds an AMAS automaton on the given turf, dressed and carded for the given job.
 *
 * This does not touch job slots. The automaton gets the job's outfit, ID access and a bank account, but SSjob never knows it exists.
 */
/proc/create_amas_automaton(turf/spawn_turf, datum/job/job)
	var/mob/living/carbon/human/automaton = new(spawn_turf)
	automaton.set_species(/datum/species/android/amas_automaton)
	automaton.fully_replace_character_name(automaton.real_name, SSamas.generate_automaton_name())
	automaton.dna.features["flavor_text"] = AMAS_AUTOMATON_FLAVOR_TEXT
	automaton.job = job.title
	automaton.on_job_equipping(job, null)
	SSamas.register_automaton(automaton)
	return automaton
