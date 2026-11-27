/**
 * Holds a human's bimbo intensity and runs every effect that comes from it.
 *
 * Intensity is the quirk baseline plus whatever the ray or hexacrocin added on top.
 * Pentacamphor removes the added part. It never touches the baseline.
 * Nothing in here can kill you.
 */
/datum/component/bimbo
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Intensity set by the quirk
	var/baseline = 0
	/// Intensity added on top of the baseline by the ray or hexacrocin
	var/bonus = 0
	/// TRUE when the quirk put us here. Quirk holders chose the size floor, so it skips the enlargement pref.
	var/from_quirk = FALSE
	/// Color of the permanent lipstick
	var/lipstick_color = BIMBO_DEFAULT_LIPSTICK_COLOR
	/// Tier we last told the holder about
	var/current_tier = BIMBO_TIER_NONE
	/// world.time until which the post-climax clarity lasts
	var/clarity_until = 0
	/// Counts life ticks so the slow checks only run every few ticks
	var/life_ticks = 0
	COOLDOWN_DECLARE(examine_arousal_cooldown)
	COOLDOWN_DECLARE(examining_arousal_cooldown)
	COOLDOWN_DECLARE(distraction_cooldown)
	/// Limits how often the short attention span drops an action
	COOLDOWN_DECLARE(lose_focus_cooldown)
	/// Limits how often an invasive thought pops up
	COOLDOWN_DECLARE(invasive_thought_cooldown)

/datum/component/bimbo/Initialize(baseline = 0, from_quirk = FALSE, lipstick_color)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	src.baseline = clamp(baseline, 0, BIMBO_MAX_INTENSITY)
	src.from_quirk = from_quirk
	if(lipstick_color)
		src.lipstick_color = lipstick_color

/datum/component/bimbo/RegisterWithParent()
	ADD_TRAIT(parent, TRAIT_BIMBO, BIMBO_TRAIT_SOURCE)
	RegisterSignal(parent, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_CARBON_HELP_ACT, PROC_REF(on_helped))
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(parent, COMSIG_MOB_EXAMINATE, PROC_REF(on_examinate))
	RegisterSignal(parent, COMSIG_CARBON_GAIN_TRAUMA, PROC_REF(on_gain_trauma))
	RegisterSignal(parent, COMSIG_HUMAN_LEWD_INTERACTION_RECEIVED, PROC_REF(on_lewd_interaction))
	RegisterSignal(parent, COMSIG_TRY_USE_MACHINE, PROC_REF(on_try_use_machine))
	refresh(instant = TRUE)

/datum/component/bimbo/UnregisterFromParent()
	var/mob/living/carbon/human/holder = parent
	UnregisterSignal(holder, list(COMSIG_MOB_SAY, COMSIG_ATOM_EXAMINE, COMSIG_CARBON_HELP_ACT, COMSIG_LIVING_LIFE, COMSIG_MOB_EXAMINATE, COMSIG_CARBON_GAIN_TRAUMA, COMSIG_HUMAN_LEWD_INTERACTION_RECEIVED, COMSIG_TRY_USE_MACHINE))
	REMOVE_TRAIT(holder, TRAIT_BIMBO, BIMBO_TRAIT_SOURCE)
	holder.remove_actionspeed_modifier(/datum/actionspeed_modifier/bimbo)
	holder.clear_mood_event("bimbo_fashion")
	holder.clear_mood_event("bimbo_bliss")
	holder.clear_alert(ALERT_BIMBO_HEAT)

/// Intensity without the arousal state. Tiers come from this so they don't flicker.
/datum/component/bimbo/proc/get_intensity()
	return clamp(baseline + bonus, 0, BIMBO_MAX_INTENSITY)

/// Intensity after arousal is taken into account. Effect strength comes from this.
/// Arousal above AROUSAL_LOW makes everything a little worse, up to BIMBO_AROUSAL_MAX_MULTIPLIER.
/datum/component/bimbo/proc/get_effective_intensity()
	var/mob/living/carbon/human/holder = parent
	var/multiplier = 1
	if(world.time < clarity_until)
		multiplier = BIMBO_CLARITY_MULTIPLIER
	else if(holder.arousal > AROUSAL_LOW)
		multiplier += (BIMBO_AROUSAL_MAX_MULTIPLIER - 1) * (holder.arousal - AROUSAL_LOW) / (AROUSAL_LIMIT - AROUSAL_LOW)
	return clamp(get_intensity() * multiplier, 0, BIMBO_MAX_INTENSITY)

/datum/component/bimbo/proc/get_tier()
	var/intensity = get_intensity()
	if(intensity >= BIMBO_BUBBLEHEADED_INTENSITY)
		return BIMBO_TIER_BUBBLEHEADED
	if(intensity >= BIMBO_BIMBO_INTENSITY)
		return BIMBO_TIER_BIMBO
	if(intensity >= BIMBO_AIRHEAD_INTENSITY)
		return BIMBO_TIER_AIRHEAD
	if(intensity > 0)
		return BIMBO_TIER_DITZY
	return BIMBO_TIER_NONE

/// Adds or removes ray intensity. Deletes the component when nothing is left.
/datum/component/bimbo/proc/adjust_bonus(amount)
	bonus = clamp(bonus + amount, 0, BIMBO_MAX_INTENSITY - baseline)
	if(!baseline && !bonus)
		qdel(src)
		return
	refresh()

/// Sets the quirk baseline. Deletes the component when nothing is left.
/datum/component/bimbo/proc/set_baseline(new_baseline, quirk_owned)
	baseline = clamp(new_baseline, 0, BIMBO_MAX_INTENSITY)
	from_quirk = quirk_owned
	bonus = min(bonus, BIMBO_MAX_INTENSITY - baseline)
	if(!baseline && !bonus)
		qdel(src)
		return
	refresh(instant = TRUE)

/// Re-applies everything that depends on intensity. instant skips the gradual size growth.
/datum/component/bimbo/proc/refresh(instant = FALSE)
	var/mob/living/carbon/human/holder = parent
	var/new_tier = get_tier()
	if(new_tier > current_tier && current_tier != BIMBO_TIER_NONE)
		to_chat(holder, span_purple("Your thoughts go even softer and fuzzier."))
	else if(new_tier < current_tier)
		to_chat(holder, span_notice("Your head feels a little clearer."))
	current_tier = new_tier

	holder.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/bimbo, multiplicative_slowdown = BIMBO_MAX_ACTION_SLOWDOWN * get_intensity() / BIMBO_MAX_INTENSITY)
	enforce_size_floor(instant)
	apply_lipstick()

/datum/component/bimbo/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/holder = parent
	if(holder.stat == DEAD)
		return
	if(check_cure())
		return
	check_climax()
	handle_arousal(seconds_per_tick)
	update_heat(seconds_per_tick)
	try_lose_focus()
	try_get_distracted()
	try_invasive_thought()
	handle_cripples()

	life_ticks++
	if(life_ticks % 5)
		return
	enforce_size_floor()
	apply_lipstick()
	update_fashion_mood()
	update_bliss()

/// Pentacamphor strips ray intensity. An overdose strips all of it. Returns TRUE if the component was deleted.
/datum/component/bimbo/proc/check_cure()
	if(!bonus)
		return FALSE
	var/mob/living/carbon/human/holder = parent
	var/datum/reagent/cure = holder.reagents?.has_reagent(/datum/reagent/drug/aphrodisiac/camphor/pentacamphor)
	if(!istype(cure))
		return FALSE
	if(cure.overdosed)
		bonus = 0
		to_chat(holder, span_notice("Your thoughts settle back into place."))
	else
		bonus = max(bonus - BIMBO_CURE_PER_TICK, 0)
	if(!baseline && !bonus)
		qdel(src)
		return TRUE
	refresh()
	return FALSE

/// Climax gives a short window where everything acts weaker.
/datum/component/bimbo/proc/check_climax()
	if(world.time < clarity_until)
		return
	var/mob/living/carbon/human/holder = parent
	if(!holder.has_status_effect(/datum/status_effect/climax))
		return
	clarity_until = world.time + BIMBO_CLARITY_DURATION
	to_chat(holder, span_notice("Your head clears up, at least for a little while."))

/// Keeps arousal above a floor and slows its natural drain. adjust_arousal checks the ERP pref.
/datum/component/bimbo/proc/handle_arousal(seconds_per_tick)
	if(world.time < clarity_until)
		return
	var/mob/living/carbon/human/holder = parent
	var/fraction = get_intensity() / BIMBO_MAX_INTENSITY
	if(holder.arousal < round(BIMBO_AROUSAL_FLOOR_MAX * fraction))
		holder.adjust_arousal(1 * seconds_per_tick)
	else
		holder.adjust_arousal(0.05 * fraction * seconds_per_tick)

	if(holder.arousal >= AROUSAL_HIGH && SPT_PROB(1, seconds_per_tick))
		to_chat(holder, span_purple(pick("It's sooo hard to think straight like this.", "Everything feels warm and fuzzy and distracting.")))

/// Heat icon and sweat while aroused. A nudge to go take care of it, never a punishment.
/datum/component/bimbo/proc/update_heat(seconds_per_tick)
	var/mob/living/carbon/human/holder = parent
	if(world.time < clarity_until || holder.arousal < AROUSAL_MEDIUM)
		holder.clear_alert(ALERT_BIMBO_HEAT)
		return
	holder.throw_alert(ALERT_BIMBO_HEAT, /atom/movable/screen/alert/bimbo_heat)
	if(SPT_PROB(4, seconds_per_tick))
		holder.emote(pick("shiver", "twitch"))
	if(!SPT_PROB(3, seconds_per_tick))
		return
	var/mutable_appearance/sweat = mutable_appearance('modular_skyrat/master_files/icons/effects/overlay_effects.dmi', "sweatdrop", ABOVE_MOB_LAYER)
	sweat.pixel_x = 10
	sweat.pixel_y = 10
	holder.flick_overlay_static(sweat, 5 SECONDS)
	to_chat(holder, span_purple(pick("You're getting all hot and sweaty.", "A bead of sweat rolls down your neck.", "Is it warm in here, or is it just you?")))

/// Long do_afters can get dropped halfway through.
/datum/component/bimbo/proc/try_lose_focus()
	var/intensity = get_effective_intensity()
	if(intensity < BIMBO_AIRHEAD_INTENSITY || !COOLDOWN_FINISHED(src, lose_focus_cooldown) || !prob(intensity / 50))
		return
	if(!interrupt_long_actions(BIMBO_ATTENTION_SPAN))
		return
	COOLDOWN_START(src, lose_focus_cooldown, BIMBO_LOSE_FOCUS_COOLDOWN)
	to_chat(parent, span_purple(pick("Wait, what was I doing?", "Um... what was this for again?", "You totally lose your train of thought.")))

/// Cancels any do_after of the holder that runs at least min_length. Returns TRUE if one was cancelled.
/datum/component/bimbo/proc/interrupt_long_actions(min_length = 0)
	. = FALSE
	for(var/datum/timed_action/action in SStimed_actions.processing)
		if(action.user != parent)
			continue
		if(action.end_time - action.start_time < min_length)
			continue
		if(action.cancel())
			. = TRUE

/// Shiny things nearby can pull your attention away from whatever you were doing.
/// While aroused, people nearby can too, and it happens twice as often.
/datum/component/bimbo/proc/try_get_distracted()
	if(!COOLDOWN_FINISHED(src, distraction_cooldown))
		return
	var/intensity = get_effective_intensity()
	if(intensity < BIMBO_AIRHEAD_INTENSITY || !prob(intensity / 20))
		return
	var/mob/living/carbon/human/holder = parent
	var/aroused = holder.arousal >= AROUSAL_MEDIUM
	var/atom/shiny = find_shiny_thing()
	if(aroused && (!shiny || prob(50)))
		shiny = find_eye_candy() || shiny
	if(!shiny)
		return
	COOLDOWN_START(src, distraction_cooldown, aroused ? 30 SECONDS : 1 MINUTES)
	interrupt_long_actions()
	if(ishuman(shiny))
		to_chat(holder, span_purple("You catch yourself staring at [shiny]. Um, what were you doing?"))
		return
	if(istype(shiny, /obj/structure/mirror))
		holder.manual_emote("stops to admire [holder.p_them()]self in \the [shiny].")
		holder.add_mood_event("bimbo_mirror", /datum/mood_event/bimbo_mirror)
	else
		holder.manual_emote("gets distracted by \the [shiny].")
	to_chat(holder, span_purple("Ooh, pretty!"))

/datum/component/bimbo/proc/find_shiny_thing()
	var/static/list/shiny_things = typecacheof(list(
		/obj/item/clothing/gloves/ring,
		/obj/item/clothing/neck/necklace/dope,
		/obj/item/clothing/under/dress,
		/obj/item/lipstick,
		/obj/item/toy/plush,
		/obj/structure/mirror,
	))
	for(var/atom/movable/thing in view(BIMBO_SHINY_RANGE, parent))
		if(is_type_in_typecache(thing, shiny_things))
			return thing
	return null

/// Someone nearby worth staring at.
/datum/component/bimbo/proc/find_eye_candy()
	for(var/mob/living/carbon/human/other in view(3, parent))
		if(other != parent && !other.stat)
			return other
	return null

/datum/component/bimbo/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/holder = parent
	switch(get_tier())
		if(BIMBO_TIER_DITZY)
			examine_list += span_userlove("[holder.p_They()] [holder.p_have()] a cute, dreamy look about [holder.p_them()].")
		if(BIMBO_TIER_AIRHEAD)
			examine_list += span_userlove("[holder.p_They()] [holder.p_have()] a sweet, carefree smile.")
		if(BIMBO_TIER_BIMBO)
			examine_list += span_userlove("[holder.p_They()] look[holder.p_s()] bubbly, glossy and happily distracted.")
		if(BIMBO_TIER_BUBBLEHEADED)
			examine_list += span_userlove("[holder.p_They()] positively glow[holder.p_es()] with ditzy, giggly charm.")

	if(user == holder || !ishuman(user))
		return
	if(!COOLDOWN_FINISHED(src, examine_arousal_cooldown) || !has_exposed_genitals())
		return
	COOLDOWN_START(src, examine_arousal_cooldown, 10 SECONDS)
	if(holder.adjust_arousal(BIMBO_EXAMINE_AROUSAL))
		to_chat(holder, span_purple("You feel someone's eyes on you, and you kind of like it."))

/// Looking at lewd things gets you going.
/datum/component/bimbo/proc/on_examinate(datum/source, atom/target)
	SIGNAL_HANDLER
	var/static/list/lewd_items
	if(!lewd_items)
		lewd_items = typecacheof(GLOB.erp_items)
	if(target == parent || !COOLDOWN_FINISHED(src, examining_arousal_cooldown))
		return
	var/arousing = is_type_in_typecache(target, lewd_items)
	if(!arousing && ishuman(target))
		arousing = has_exposed_genitals(target)
	if(!arousing)
		return
	COOLDOWN_START(src, examining_arousal_cooldown, 15 SECONDS)
	var/mob/living/carbon/human/holder = parent
	holder.adjust_arousal(BIMBO_EXAMINING_AROUSAL)

/datum/component/bimbo/proc/has_exposed_genitals(mob/living/carbon/human/who = parent)
	for(var/obj/item/organ/genital/genital in who.organs)
		if(istype(genital, /obj/item/organ/genital/belly))
			continue
		if(genital.is_exposed())
			return TRUE
	return FALSE

/datum/component/bimbo/proc/on_helped(datum/source, mob/living/helper)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/holder = parent
	holder.add_mood_event("bimbo_attention", /datum/mood_event/bimbo_attention)

/// Lewd interactions that use your body leave you weak at the knees. Ported in spirit from VENUS Station.
/datum/component/bimbo/proc/on_lewd_interaction(datum/source, mob/living/carbon/human/user, datum/interaction/interaction)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/holder = parent
	if(user == holder || !length(interaction.target_required_parts))
		return
	var/stamina = BIMBO_LEWD_STAMINA_MAX * get_effective_intensity() / BIMBO_MAX_INTENSITY
	if(has_synergy(/datum/quirk/masochism))
		stamina /= 2
	holder.adjust_stamina_loss(stamina)
	if(!prob(15))
		return
	if(holder.has_status_effect(/datum/status_effect/incapacitating/stamcrit))
		to_chat(holder, span_purple("It feels too good..."))
	else
		to_chat(holder, span_purple("You feel so helpless..."))

/// Mindshields do not keep hypnosis out of a bimbo, but they do clear it after a while.
/datum/component/bimbo/proc/on_gain_trauma(datum/source, datum/brain_trauma/trauma, resilience)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/holder = parent
	if(!istype(trauma, /datum/brain_trauma/hypnosis) || !HAS_MIND_TRAIT(holder, TRAIT_UNCONVERTABLE))
		return
	addtimer(CALLBACK(src, PROC_REF(shake_off_hypnosis)), BIMBO_MINDSHIELD_SHAKE_OFF, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/component/bimbo/proc/shake_off_hypnosis()
	var/mob/living/carbon/human/holder = parent
	if(!HAS_MIND_TRAIT(holder, TRAIT_UNCONVERTABLE) || !holder.has_trauma_type(/datum/brain_trauma/hypnosis))
		return
	holder.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY)
	to_chat(holder, span_notice("Your mindshield implant hums, and the voice in your head finally fades."))

/// Quirks that dovetail with Bimbo. Each one softens a downside a little.
/datum/component/bimbo/proc/has_synergy(quirk_type)
	var/mob/living/carbon/human/holder = parent
	return holder.has_quirk(quirk_type)

/atom/movable/screen/alert/bimbo_heat
	name = "Hot and Bothered"
	desc = "You're all warm and flustered, and it's making it really hard to think. Maybe you should take care of that."
	icon = 'modular_~maverick/icons/hud/bimbo_alert.dmi'
	icon_state = "bimbo_heat"

/datum/actionspeed_modifier/bimbo
	variable = TRUE

/// Lewd thoughts that pop into your head now and then, from the old hexacrocin overdose. Only with ERP on.
/datum/component/bimbo/proc/try_invasive_thought()
	var/mob/living/carbon/human/holder = parent
	if(!COOLDOWN_FINISHED(src, invasive_thought_cooldown) || world.time < clarity_until)
		return
	if(!holder.mob_consents(/datum/preference/toggle/erp))
		return
	var/intensity = get_effective_intensity()
	if(intensity < BIMBO_AIRHEAD_INTENSITY || !prob(intensity / 20))
		return
	COOLDOWN_START(src, invasive_thought_cooldown, BIMBO_INVASIVE_THOUGHT_COOLDOWN)
	var/static/list/mild_thoughts = list(
		"You feel a bit hot.",
		"Your mind keeps wandering somewhere naughty.",
		"You feel totally in the mood.",
		"Someone cute would really make your day right now.",
	)
	var/static/list/strong_thoughts = list(
		"You can't get sex off your mind!",
		"You're bursting with tension!",
		"You really, really need someone right now.",
		"Every thought you have ends up in the same place.",
	)
	to_chat(holder, span_userlove(pick(holder.arousal >= AROUSAL_MEDIUM ? strong_thoughts : mild_thoughts)))
