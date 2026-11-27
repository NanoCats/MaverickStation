/// Words a bimbo never forgets, however long: she can always call for help and name a department.
GLOBAL_LIST_INIT(bimbo_kept_words, list(
	"help", "security", "medical", "engineering", "science", "cargo", "service", "command",
	"medbay", "brig", "bridge", "captain", "doctor", "paramedic", "officer", "warden",
	"emergency", "evacuate", "shuttle", "maintenance", "atmospherics", "chemistry", "virology",
	"robotics", "genetics", "kitchen", "botany", "library", "chapel", "janitor", "quartermaster",
	"syndicate", "changeling", "traitor", "cultist", "fire", "plasma", "bleeding", "breach",
))

/datum/component/bimbo/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER
	var/message = speech_args[SPEECH_MESSAGE]
	var/intensity = get_effective_intensity()
	if(!message || intensity <= 0)
		return
	speech_args[SPEECH_MESSAGE] = bimbofy_message(message, intensity)

/// Runs a full message through the filter.
/datum/component/bimbo/proc/bimbofy_message(message, intensity)
	var/list/words = splittext(message, " ")
	var/word_cap = get_word_length_cap(intensity)
	var/list/nearby_names = intensity >= BIMBO_BUBBLEHEADED_INTENSITY ? get_nearby_names() : null
	for(var/i in 1 to length(words))
		words[i] = bimbofy_word(words[i], intensity, word_cap, nearby_names)

	if(length(words) > 2 && prob(intensity / 2))
		words.Insert(rand(2, length(words)), "like,")
	message = jointext(words, " ")

	if(prob(intensity / 3))
		message = "[pick("Um,", "So, like,", "Okay so,", "Hmm,")] [message]"

	if(prob(intensity / 2))
		var/last_char = copytext_char(message, -1)
		if(last_char == ".")
			message = "[copytext_char(message, 1, -1)]?"
		else if(!(last_char in list("!", "?", "~")))
			message += "?"
	return message

/// Runs one word through the filter. Punctuation around the word is kept.
/datum/component/bimbo/proc/bimbofy_word(word, intensity, word_cap, list/nearby_names)
	var/static/regex/word_parts = new(@"^(\W*)([\w'\-]+)(\W*)$")
	var/static/regex/number = new(@"^\d+$")
	if(!word_parts.Find(word))
		return word
	var/lead = word_parts.group[1]
	var/core = word_parts.group[2]
	var/tail = word_parts.group[3]

	if(number.Find(core))
		if(intensity >= BIMBO_BIMBO_INTENSITY && text2num(core) > 10)
			core = pick("like, a bunch", "a lot", "um, lots", "some number", "a big number")
		return "[lead][core][tail]"

	if(nearby_names && (LOWER_TEXT(core) in nearby_names) && prob(40))
		core = pick("babe", "hun", "sweetie", "that one")
	else if(length_char(core) > word_cap && !(LOWER_TEXT(core) in GLOB.bimbo_kept_words) && prob(BIMBO_FORGET_WORD_CHANCE))
		core = pick("thingy", "whatsit", "thingamajig", "the, um, thing", "whatchamacallit")
	return "[lead][core][tail]"

/// Words longer than this can get forgotten. 14 letters at the airhead tier, 10 at full intensity.
/datum/component/bimbo/proc/get_word_length_cap(intensity)
	if(intensity < BIMBO_AIRHEAD_INTENSITY)
		return INFINITY
	return round(14 - 4 * (intensity - BIMBO_AIRHEAD_INTENSITY) / (BIMBO_MAX_INTENSITY - BIMBO_AIRHEAD_INTENSITY))

/// First names of the people we can see, lowercase, for swapping with pet names.
/datum/component/bimbo/proc/get_nearby_names()
	var/list/names = list()
	for(var/mob/living/carbon/human/other in view(7, parent))
		if(other == parent)
			continue
		names |= LOWER_TEXT(first_name(other.name))
	return names

/// Papers stop after this many words. 0 means no limit. 150 words at the airhead tier, 30 at full intensity.
/datum/component/bimbo/proc/get_reading_limit()
	var/intensity = get_effective_intensity()
	if(intensity < BIMBO_AIRHEAD_INTENSITY)
		return 0
	return round(150 - 120 * (intensity - BIMBO_AIRHEAD_INTENSITY) / (BIMBO_MAX_INTENSITY - BIMBO_AIRHEAD_INTENSITY))
