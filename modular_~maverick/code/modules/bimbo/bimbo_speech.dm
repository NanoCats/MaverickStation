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

/// The bimbo accent: everyday words swapped for ditzier ones. Applied per word, more often at higher intensity.
GLOBAL_LIST_INIT(bimbo_accent, list(
	"yes" = "totally",
	"yeah" = "totally",
	"yep" = "uh-huh",
	"no" = "no way",
	"nope" = "nuh-uh",
	"very" = "super",
	"really" = "literally",
	"so" = "sooo",
	"good" = "cute",
	"great" = "amazing",
	"nice" = "cute",
	"bad" = "icky",
	"terrible" = "sooo gross",
	"awful" = "gross",
	"hello" = "hiii",
	"hi" = "hiii",
	"hey" = "heyyy",
	"bye" = "byeee",
	"goodbye" = "byeee",
	"thanks" = "thank youuu",
	"friend" = "bestie",
	"friends" = "besties",
	"buddy" = "bestie",
	"guy" = "cutie",
	"man" = "babe",
	"dude" = "babe",
	"okay" = "kay",
	"ok" = "kay",
	"sure" = "for sure",
	"think" = "feel like",
	"believe" = "feel like",
	"know" = "know, like,",
	"understand" = "get it",
	"problem" = "drama",
	"issue" = "drama",
	"fight" = "drama",
	"dangerous" = "super scary",
	"weapon" = "scary thing",
	"gun" = "pew pew thing",
	"firearm" = "pew pew thing",
	"injured" = "hurt",
	"wounded" = "all owie",
	"pretty" = "gorgeous",
	"beautiful" = "gorgeous",
	"hot" = "sooo hot",
	"strange" = "weird",
	"suspicious" = "sketchy",
	"interesting" = "cool",
	"excellent" = "amazing",
	"important" = "super important",
	"wow" = "omg",
	"what" = "wait, what",
))

/// Openers a line can already start with. A line that starts with one gets no extra interjection.
GLOBAL_LIST_INIT(bimbo_openers, list("um", "uh", "so", "okay", "ok", "like", "hey", "oh", "omg", "well", "hmm", "wait", "hi", "hello"))

/// Runs a full message through the accent.
/datum/component/bimbo/proc/bimbofy_message(message, intensity)
	var/list/words = splittext(message, " ")
	if(!length(words))
		return message
	var/word_cap = get_word_length_cap(intensity)
	var/list/nearby_names = intensity >= BIMBO_BUBBLEHEADED_INTENSITY ? get_nearby_names() : null
	var/first_word = LOWER_TEXT(replacetext(words[1], regex(@"\W", "g"), ""))
	for(var/i in 1 to length(words))
		words[i] = bimbofy_word(words[i], intensity, word_cap, nearby_names)

	// One "like," at most, somewhere in the middle
	if(intensity >= BIMBO_AIRHEAD_INTENSITY && length(words) > 3 && prob(intensity / 3))
		words.Insert(rand(2, length(words) - 1), "like,")
	message = jointext(words, " ")

	// An opener, unless the line already has one
	if(intensity >= BIMBO_AIRHEAD_INTENSITY && !(first_word in GLOB.bimbo_openers) && prob(intensity / 4))
		// Lowercase the old first letter, except for "I" and its contractions
		var/keep_capital = first_word == "i" || findtext(words[1], "I'") == 1
		var/rest = keep_capital ? message : "[lowertext(copytext_char(message, 1, 2))][copytext_char(message, 2)]"
		message = "[pick("Um,", "Like,", "Omg,", "Okay so,")] [rest]"

	// Uptalk on plain statements
	if(prob(intensity / 4))
		var/last_char = copytext_char(message, -1)
		if(last_char == ".")
			message = "[copytext_char(message, 1, -1)]?"
		else if(!(last_char in list("!", "?", "~", ",")))
			message += "?"
	return message

/// Runs one word through the accent. Punctuation around the word and a leading capital are kept.
/datum/component/bimbo/proc/bimbofy_word(word, intensity, word_cap, list/nearby_names)
	var/static/regex/word_parts = new(@"^(\W*)([\w'\-]+)(\W*)$")
	var/static/regex/number = new(@"^\d+$")
	if(!word_parts.Find(word))
		return word
	var/lead = word_parts.group[1]
	var/core = word_parts.group[2]
	var/tail = word_parts.group[3]
	var/lower = LOWER_TEXT(core)

	if(number.Find(core))
		if(intensity >= BIMBO_BIMBO_INTENSITY && text2num(core) > 10 && prob(intensity / 2))
			core = pick("like, a bunch", "a lot", "um, lots", "a big number")
		return "[lead][core][tail]"

	if(lower in GLOB.bimbo_kept_words)
		return word

	if(nearby_names && (lower in nearby_names) && prob(40))
		core = pick("babe", "hun", "sweetie", "bestie")
	else if(GLOB.bimbo_accent[lower] && prob(intensity * 0.6))
		var/swapped = GLOB.bimbo_accent[lower]
		core = (core != lower && length(core)) ? "[uppertext(copytext_char(swapped, 1, 2))][copytext_char(swapped, 2)]" : swapped
	else if(intensity >= BIMBO_BUBBLEHEADED_INTENSITY && length_char(core) > word_cap && prob(BIMBO_FORGET_WORD_CHANCE))
		core = pick("thingy", "whatsit", "thingamajig", "whatchamacallit")
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
