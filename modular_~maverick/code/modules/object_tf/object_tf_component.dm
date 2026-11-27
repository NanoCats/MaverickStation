/**
 * Someone who has been turned into an object.
 *
 * The mob sits inside the object in stasis: no hunger, no breathing, no moving or using hands.
 * They can still see, hear, talk and emote.
 * They come back out when:
 * - a TF toolgun restores them,
 * - they struggle free with Resist (OBJECT_TF_ESCAPE_TIME),
 * - the object is destroyed.
 */
/datum/component/object_tf
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// The object they became
	var/obj/item/container
	/// Timer for struggling free
	var/escape_timer

/datum/component/object_tf/Initialize(obj/item/container)
	if(!isliving(parent) || !istype(container) || QDELETED(container))
		return COMPONENT_INCOMPATIBLE
	src.container = container
	var/mob/living/living_parent = parent
	living_parent.forceMove(container)

/datum/component/object_tf/RegisterWithParent()
	var/mob/living/living_parent = parent
	living_parent.apply_status_effect(/datum/status_effect/grouped/stasis, REF(src))
	RegisterSignal(living_parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_moved))
	RegisterSignal(living_parent, COMSIG_LIVING_RESIST, PROC_REF(on_resist))
	RegisterSignal(container, COMSIG_QDELETING, PROC_REF(on_container_deleted))
	RegisterSignal(container, COMSIG_ATOM_EXAMINE, PROC_REF(on_container_examine))

/datum/component/object_tf/UnregisterFromParent()
	var/mob/living/living_parent = parent
	living_parent.remove_status_effect(/datum/status_effect/grouped/stasis, REF(src))
	UnregisterSignal(living_parent, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_RESIST))
	if(container)
		UnregisterSignal(container, list(COMSIG_QDELETING, COMSIG_ATOM_EXAMINE))

/datum/component/object_tf/Destroy(force)
	deltimer(escape_timer)
	container = null
	return ..()

/// Puts them back on the floor where the object is, then removes the component.
/datum/component/object_tf/proc/release(message = TRUE)
	var/mob/living/living_parent = parent
	var/turf/drop_turf = get_turf(container) || get_turf(living_parent)
	var/container_name = "[container]"
	UnregisterSignal(living_parent, COMSIG_MOVABLE_MOVED)
	if(drop_turf)
		living_parent.forceMove(drop_turf)
	if(message)
		living_parent.visible_message(
			span_userlove("[container_name] shimmers and unfolds back into [living_parent]!"),
			span_userlove("You unfold out of [container_name] and back into your own body."),
		)
	qdel(src)

/datum/component/object_tf/proc/on_parent_moved(mob/living/source)
	SIGNAL_HANDLER
	// Moved out by something else (an admin, a teleport). Nothing left to hold.
	if(QDELETED(container) || source.loc != container)
		qdel(src)

/datum/component/object_tf/proc/on_container_deleted(datum/source)
	SIGNAL_HANDLER
	release()

/datum/component/object_tf/proc/on_container_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_userlove("Something about [container.p_them()] feels warm and alive. [container.p_they(TRUE)] look[container.p_s()] a lot like [parent].")

/datum/component/object_tf/proc/on_resist(datum/source)
	SIGNAL_HANDLER
	var/mob/living/living_parent = parent
	if(escape_timer)
		to_chat(living_parent, span_notice("You are still wriggling free of [container]. [DisplayTimeText(timeleft(escape_timer))] to go."))
		return COMPONENT_BLOCK_RESIST
	to_chat(living_parent, span_notice("You start wriggling free of [container]. This will take [DisplayTimeText(OBJECT_TF_ESCAPE_TIME)]."))
	container.visible_message(span_notice("[container] wobbles a little."))
	escape_timer = addtimer(CALLBACK(src, PROC_REF(release)), OBJECT_TF_ESCAPE_TIME, TIMER_STOPPABLE)
	return COMPONENT_BLOCK_RESIST
