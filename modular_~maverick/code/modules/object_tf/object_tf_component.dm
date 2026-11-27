/**
 * Someone who has been turned into an object.
 *
 * The mob sits inside the object in stasis: no hunger, no breathing, no moving or using hands.
 * They can still see, hear, talk and emote. Speech and custom emotes come out as the object, so nobody learns who is inside.
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
	RegisterSignal(living_parent, COMSIG_MOB_SAY, PROC_REF(on_say))
	RegisterSignal(living_parent, COMSIG_MOB_PRE_EMOTED, PROC_REF(on_emote))
	RegisterSignal(container, COMSIG_QDELETING, PROC_REF(on_container_deleted))

/datum/component/object_tf/UnregisterFromParent()
	var/mob/living/living_parent = parent
	living_parent.remove_status_effect(/datum/status_effect/grouped/stasis, REF(src))
	UnregisterSignal(living_parent, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, COMSIG_OOC_ESCAPE, COMSIG_MOB_SAY, COMSIG_MOB_PRE_EMOTED))
	if(container)
		UnregisterSignal(container, COMSIG_QDELETING)

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
		if(drop_turf)
			tf_heart_burst(drop_turf)
	qdel(src)

/datum/component/object_tf/proc/on_parent_moved(mob/living/source)
	SIGNAL_HANDLER
	// Moved out by something else (an admin, a teleport). Nothing left to hold.
	if(QDELETED(container) || source.loc != container)
		qdel(src)

/datum/component/object_tf/proc/on_container_deleted(datum/source)
	SIGNAL_HANDLER
	release()

/// Speech comes out of the object instead of the person.
/datum/component/object_tf/proc/on_say(mob/living/source, list/speech_args)
	SIGNAL_HANDLER
	var/message = speech_args[SPEECH_MESSAGE]
	if(!message)
		return
	// Blank the person's own line, then let the object say it
	speech_args[SPEECH_MESSAGE] = ""
	source.log_talk(message, LOG_SAY, tag = "as object ([container])")
	INVOKE_ASYNC(src, PROC_REF(speak_as_object), message, speech_args[SPEECH_LANGUAGE])

/datum/component/object_tf/proc/speak_as_object(message, datum/language/language)
	if(QDELETED(container))
		return
	// Already sanitized by the person's own say
	container.say(message, sanitize = FALSE, language = language, message_mods = list(MODE_RELAY = TRUE))

/// Custom emotes show as the object. Other emotes would name the person, so they are blocked.
/datum/component/object_tf/proc/on_emote(mob/living/source, key, param, type_override, intentional, datum/emote/emote)
	SIGNAL_HANDLER
	if(!intentional)
		return COMPONENT_CANT_EMOTE
	if(key == "me" && param)
		source.log_message("emoted as object ([container]): [param]", LOG_EMOTE)
		container.visible_message("<b>[container]</b> [param]", vision_distance = COMBAT_MESSAGE_RANGE)
	else
		to_chat(source, span_notice("You can't do that as [container]. A custom emote works, like <b>*me wobbles.</b>"))
	return COMPONENT_CANT_EMOTE

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

/// A puff of pink hearts, for turning into or out of an object.
/proc/tf_heart_burst(turf/where)
	for(var/i in 1 to 3)
		new /obj/effect/temp_visual/heart(where)
	playsound(where, 'sound/effects/magic/charge.ogg', 40, TRUE, frequency = 1.5)
