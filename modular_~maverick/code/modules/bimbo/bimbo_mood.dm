/// Cute clothes feel good. Bulky protective gear does not.
/datum/component/bimbo/proc/update_fashion_mood()
	var/static/list/bulky_gear = typecacheof(list(
		/obj/item/clothing/suit/bio_suit,
		/obj/item/clothing/suit/hazardvest,
		/obj/item/clothing/suit/mod,
		/obj/item/clothing/suit/space,
		/obj/item/clothing/suit/utility,
	))
	var/mob/living/carbon/human/holder = parent
	var/new_mood
	if(holder.wear_suit && is_type_in_typecache(holder.wear_suit, bulky_gear))
		new_mood = /datum/mood_event/bimbo_ugly_outfit
	else if(is_wearing_cute_outfit())
		new_mood = /datum/mood_event/bimbo_cute_outfit

	var/datum/mood_event/current = holder.mob_mood?.mood_events["bimbo_fashion"]
	if(current?.type == new_mood)
		return
	if(new_mood)
		holder.add_mood_event("bimbo_fashion", new_mood)
	else
		holder.clear_mood_event("bimbo_fashion")

/datum/component/bimbo/proc/is_wearing_cute_outfit()
	var/mob/living/carbon/human/holder = parent
	if(has_synergy(/datum/quirk/equipping/seamless_clothes))
		return TRUE
	if(istype(holder.w_uniform, /obj/item/clothing/under/dress))
		return TRUE
	var/uniform_name = LOWER_TEXT(holder.w_uniform?.name)
	if(findtext(uniform_name, "skirt") || findtext(uniform_name, "dress") || findtext(uniform_name, "maid"))
		return TRUE
	return !!findtext(LOWER_TEXT(holder.shoes?.name), "heel")

/// Cancels part of the holder's negative mood. Thinking about bad stuff is hard.
/datum/component/bimbo/proc/update_bliss()
	var/mob/living/carbon/human/holder = parent
	var/datum/mood/mood = holder.mob_mood
	if(!mood)
		return
	var/negative_total = 0
	for(var/category in mood.mood_events)
		if(category == "bimbo_bliss" || category == "bimbo_fashion")
			continue
		var/datum/mood_event/event = mood.mood_events[category]
		if(event.mood_change < 0)
			negative_total -= event.mood_change

	var/offset = round(negative_total * BIMBO_BLISS_MAX * get_effective_intensity() / BIMBO_MAX_INTENSITY)
	var/datum/mood_event/bliss = mood.mood_events["bimbo_bliss"]
	if(offset < 1)
		if(bliss)
			holder.clear_mood_event("bimbo_bliss")
		return
	if(!bliss)
		holder.add_mood_event("bimbo_bliss", /datum/mood_event/bimbo_bliss)
		bliss = mood.mood_events["bimbo_bliss"]
	if(bliss && bliss.mood_change != offset)
		bliss.mood_change = offset
		mood.update_mood()

/datum/mood_event/bimbo_attention
	description = "Ooh, somebody's paying attention to me!"
	mood_change = 3
	timeout = 2 MINUTES

/datum/mood_event/bimbo_mirror
	description = "I look sooo good."
	mood_change = 2
	timeout = 3 MINUTES

/datum/mood_event/bimbo_cute_outfit
	description = "This outfit is super cute."
	mood_change = 2

/datum/mood_event/bimbo_ugly_outfit
	description = "Ugh, this is so not cute."
	mood_change = -2

/// mood_change is set at runtime by the bimbo component
/datum/mood_event/bimbo_bliss
	description = "Thinking about bad stuff is hard, so I just don't."
	mood_change = 0
