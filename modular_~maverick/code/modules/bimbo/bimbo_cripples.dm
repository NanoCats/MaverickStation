// What makes going full bimbo hurt: butterfingers, too many buttons, and compulsions.
// All of these switch on at the top tiers only. Below that the quirk stays flavor.

/datum/component/bimbo
	/// Limits butterfingers
	COOLDOWN_DECLARE(butterfingers_cooldown)
	/// Limits compulsions
	COOLDOWN_DECLARE(compulsion_cooldown)
	/// Consoles stay usable until this time without another roll
	var/buttons_ok_until = 0
	/// Consoles refuse to work until this time
	var/buttons_confused_until = 0

/// Called from on_life
/datum/component/bimbo/proc/handle_cripples()
	var/intensity = get_effective_intensity()
	if(intensity < BIMBO_BUBBLEHEADED_INTENSITY)
		return
	try_butterfingers(intensity)
	try_compulsion(intensity)

/// Bubbleheaded: now and then whatever you are holding slips out of your hands.
/datum/component/bimbo/proc/try_butterfingers(intensity)
	if(!COOLDOWN_FINISHED(src, butterfingers_cooldown) || !prob((intensity - BIMBO_BUBBLEHEADED_INTENSITY) / 10))
		return
	var/mob/living/carbon/human/holder = parent
	var/obj/item/held = holder.get_active_held_item() || holder.get_inactive_held_item()
	if(!held || HAS_TRAIT(held, TRAIT_NODROP) || !holder.dropItemToGround(held))
		return
	COOLDOWN_START(src, butterfingers_cooldown, BIMBO_BUTTERFINGERS_COOLDOWN)
	holder.visible_message(
		span_notice("[held] slips right out of [holder]'s hands."),
		span_userlove(pick("Oopsie! [held] just slipped right out of your hands!", "Whoops! Butterfingers!", "Hehe, oops. You dropped [held].")),
	)

/// Bubbleheaded: you sometimes wander toward a mirror or someone cute, and giggle about it.
/datum/component/bimbo/proc/try_compulsion(intensity)
	if(!COOLDOWN_FINISHED(src, compulsion_cooldown) || !prob(intensity / 40))
		return
	var/mob/living/carbon/human/holder = parent
	if(holder.incapacitated || holder.buckled || holder.pulledby || !(holder.mobility_flags & MOBILITY_MOVE))
		return
	var/atom/lure = find_lure()
	if(!lure)
		return
	COOLDOWN_START(src, compulsion_cooldown, BIMBO_COMPULSION_COOLDOWN)
	interrupt_long_actions()
	if(ishuman(lure))
		to_chat(holder, span_userlove(pick("[lure] is sooo cute... you just have to get closer.", "Your feet carry you toward [lure] all on their own.")))
	else
		to_chat(holder, span_userlove(pick("Ooh, a mirror! You just need one little look.", "You totally have to check your makeup in [lure].")))
	for(var/step in 1 to BIMBO_COMPULSION_STEPS)
		addtimer(CALLBACK(src, PROC_REF(compulsion_step), lure), step * 0.4 SECONDS)
	if(prob(50))
		holder.emote("giggle")

/datum/component/bimbo/proc/compulsion_step(atom/lure)
	var/mob/living/carbon/human/holder = parent
	if(QDELETED(lure) || holder.incapacitated || get_dist(holder, lure) <= 1)
		return
	step_towards(holder, lure)

/// A mirror, or someone cute nearby
/datum/component/bimbo/proc/find_lure()
	for(var/obj/structure/mirror/mirror in view(BIMBO_COMPULSION_RANGE, parent))
		return mirror
	var/list/candidates = list()
	for(var/mob/living/carbon/human/other in view(BIMBO_COMPULSION_RANGE, parent))
		if(other != parent && !other.stat)
			candidates += other
	return length(candidates) ? pick(candidates) : null

/// Bimbo tier and up: consoles and computers sometimes have way too many buttons.
/datum/component/bimbo/proc/on_try_use_machine(datum/source, obj/machinery/machine)
	SIGNAL_HANDLER
	if(!istype(machine, /obj/machinery/computer) && !istype(machine, /obj/machinery/modular_computer))
		return NONE
	if(world.time < buttons_confused_until)
		return COMPONENT_CANT_USE_MACHINE_INTERACT
	if(world.time < buttons_ok_until)
		return NONE
	var/intensity = get_effective_intensity()
	if(intensity < BIMBO_BIMBO_INTENSITY)
		return NONE
	// One roll covers a stretch of use, so open windows do not flicker
	if(!prob((intensity - BIMBO_BIMBO_INTENSITY) / 2))
		buttons_ok_until = world.time + BIMBO_BUTTONS_OK_TIME
		return NONE
	buttons_confused_until = world.time + BIMBO_BUTTONS_CONFUSED_TIME
	to_chat(parent, span_userlove(pick("Ugh, there are, like, way too many buttons.", "Which one was the... um. Hmm.", "You poke at [machine] and it beeps at you. Rude.")))
	return COMPONENT_CANT_USE_MACHINE_INTERACT
