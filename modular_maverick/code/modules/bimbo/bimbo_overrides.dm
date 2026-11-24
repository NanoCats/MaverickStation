// Small overrides of upstream procs for the bimbo component.

/// Bimbos are easy to hypnotize. Mindshields still protect them.
/mob/living/carbon/human/hypnosis_vulnerable()
	. = ..()
	if(. || HAS_MIND_TRAIT(src, TRAIT_UNCONVERTABLE))
		return
	var/datum/component/bimbo/bimbo = GetComponent(/datum/component/bimbo)
	if(!bimbo)
		return
	var/intensity = bimbo.get_effective_intensity()
	return intensity >= BIMBO_BIMBO_INTENSITY || prob(intensity)

/// Long papers stop after a word limit.
/obj/item/paper/ui_static_data(mob/user)
	. = ..()
	var/datum/component/bimbo/bimbo = user?.GetComponent(/datum/component/bimbo)
	var/word_limit = bimbo?.get_reading_limit()
	if(!word_limit)
		return
	var/list/static_data = .
	var/list/kept_inputs = list()
	var/words_left = word_limit
	for(var/list/text_input as anything in static_data[LIST_PAPER_RAW_TEXT_INPUT])
		var/list/words = splittext(text_input[LIST_PAPER_RAW_TEXT], " ")
		if(length(words) > words_left)
			text_input[LIST_PAPER_RAW_TEXT] = "[jointext(words.Copy(1, words_left + 1), " ")]... ugh, too many words."
			kept_inputs += list(text_input)
			break
		words_left -= length(words)
		kept_inputs += list(text_input)
	static_data[LIST_PAPER_RAW_TEXT_INPUT] = kept_inputs
