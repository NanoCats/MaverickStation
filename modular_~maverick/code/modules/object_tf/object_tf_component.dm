/**
 * Someone who has been turned into an object.
 *
 * The mob sits inside the object in stasis: no hunger, no breathing, no moving or using hands.
 * They can still see, hear, talk and emote.
 * Trying to move only makes the object wobble.
 * They come back out when:
 * - a TF toolgun restores them,
 * - they use the OOC Safe Word verb,
 * - the object is destroyed.
 */
/datum/component/object_tf
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// The object they became
	var/obj/item/container
	COOLDOWN_DECLARE(wobble_cooldown)

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
	RegisterSignal(living_parent, COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, PROC_REF(on_move_attempt))
	RegisterSignal(living_parent, COMSIG_OOC_ESCAPE, PROC_REF(on_safeword))
	RegisterSignal(container, COMSIG_QDELETING, PROC_REF(on_container_deleted))
	RegisterSignal(container, COMSIG_ATOM_EXAMINE, PROC_REF(on_container_examine))

/datum/component/object_tf/UnregisterFromParent()
	var/mob/living/living_parent = parent
	living_parent.remove_status_effect(/datum/status_effect/grouped/stasis, REF(src))
	UnregisterSignal(living_parent, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, COMSIG_OOC_ESCAPE))
	if(container)
		UnregisterSignal(container, list(COMSIG_QDELETING, COMSIG_ATOM_EXAMINE))

/datum/component/object_tf/Destroy(force)
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

/// Trying to move makes the object wobble a little, and nothing else.
/datum/component/object_tf/proc/on_move_attempt(datum/source, new_loc, direct)
	SIGNAL_HANDLER
	if(COOLDOWN_FINISHED(src, wobble_cooldown))
		COOLDOWN_START(src, wobble_cooldown, OBJECT_TF_WOBBLE_COOLDOWN)
		container.Shake(1, 1, 0.5 SECONDS)
		container.visible_message(span_notice("[container] moves slightly."), ignored_mobs = parent)
		to_chat(parent, span_notice("You try to move, but [container] only shifts slightly."))
	return COMSIG_MOB_CLIENT_BLOCK_PRE_LIVING_MOVE

/datum/component/object_tf/proc/on_safeword(datum/source)
	SIGNAL_HANDLER
	release()
