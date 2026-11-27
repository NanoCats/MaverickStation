/**
 * TF toolgun: turns a consenting person into an object, and back.
 *
 * Modes (use in hand to switch):
 * - Sample: takes in one item. That item is what the next person becomes, so nothing gets duplicated.
 * - Transform: turns a person into the sampled item. Needs their Object transformation pref.
 * - Restore: turns an object back into the person inside it.
 */
/obj/item/tf_toolgun
	name = "TF toolgun"
	desc = "A LustWish novelty built around a strange revolver frame. Sample an item, then share its shape with a willing friend. Use it in hand to switch modes. Alt-click to take back the sampled item."
	icon = 'modular_zubbers/icons/obj/equipment/architector_items.dmi'
	icon_state = "toolgun"
	inhand_icon_state = "toolgun"
	worn_icon_state = "toolgun"
	worn_icon = 'modular_zubbers/icons/mob/inhands/architector_items_belt.dmi'
	lefthand_file = 'modular_zubbers/icons/mob/inhands/architector_items_lefthand.dmi'
	righthand_file = 'modular_zubbers/icons/mob/inhands/architector_items_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	pickup_sound = 'modular_zubbers/sound/phystools/toolgun_select.ogg'
	/// TF_TOOLGUN_SAMPLE, TF_TOOLGUN_TRANSFORM or TF_TOOLGUN_RESTORE
	var/mode = TF_TOOLGUN_SAMPLE
	/// The item the next person becomes. Kept inside the toolgun.
	var/obj/item/sampled_item
	/// TRUE while a transformation is playing out
	var/busy = FALSE
	COOLDOWN_DECLARE(use_cooldown)

/obj/item/tf_toolgun/Destroy(force)
	if(sampled_item)
		sampled_item.forceMove(drop_location())
	return ..()

/obj/item/tf_toolgun/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == sampled_item)
		sampled_item = null

/obj/item/tf_toolgun/examine(mob/user)
	. = ..()
	. += span_notice("Mode: <b>[mode]</b>.")
	. += span_notice("Sampled: <b>[sampled_item ? sampled_item.name : "nothing"]</b>.")

/obj/item/tf_toolgun/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return
	var/static/list/modes = list(TF_TOOLGUN_SAMPLE, TF_TOOLGUN_TRANSFORM, TF_TOOLGUN_RESTORE)
	var/index = modes.Find(mode) + 1
	mode = modes[index > length(modes) ? 1 : index]
	balloon_alert(user, "mode: [mode]")
	playsound(src, 'modular_zubbers/sound/phystools/toolgun_select.ogg', 50, TRUE)
	return TRUE

/obj/item/tf_toolgun/click_alt(mob/user)
	if(!sampled_item)
		balloon_alert(user, "nothing sampled!")
		return CLICK_ACTION_BLOCKING
	var/obj/item/returned = sampled_item
	returned.forceMove(drop_location())
	user.put_in_hands(returned)
	balloon_alert(user, "ejected [returned.name]")
	return CLICK_ACTION_SUCCESS

/obj/item/tf_toolgun/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	return use_tool_on(interacting_with, user)

/obj/item/tf_toolgun/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(get_dist(user, interacting_with) > TF_TOOLGUN_RANGE || !can_see(user, interacting_with, TF_TOOLGUN_RANGE))
		return NONE
	return use_tool_on(interacting_with, user)

/// Does whatever the current mode does to the target.
/obj/item/tf_toolgun/proc/use_tool_on(atom/target, mob/living/user)
	// Leave other clicks alone, so the toolgun can still be put on tables and so on
	if(mode == TF_TOOLGUN_TRANSFORM ? !ishuman(target) : !isitem(target))
		return NONE
	if(!COOLDOWN_FINISHED(src, use_cooldown) || busy)
		balloon_alert(user, "recharging!")
		return ITEM_INTERACT_BLOCKING
	var/error
	switch(mode)
		if(TF_TOOLGUN_SAMPLE)
			error = try_sample(target, user)
		if(TF_TOOLGUN_TRANSFORM)
			error = try_transform(target, user)
		if(TF_TOOLGUN_RESTORE)
			error = try_restore(target, user)
	if(error)
		balloon_alert(user, error)
		playsound(src, 'modular_zubbers/sound/phystools/toolgun_error.ogg', 50, TRUE)
		return ITEM_INTERACT_BLOCKING
	COOLDOWN_START(src, use_cooldown, TF_TOOLGUN_COOLDOWN)
	playsound(src, pick('modular_zubbers/sound/phystools/toolgun_shot1.ogg', 'modular_zubbers/sound/phystools/toolgun_shot2.ogg'), 50, TRUE)
	if(target.loc != user && target != user)
		user.Beam(target, "light_beam", time = 3)
	return ITEM_INTERACT_SUCCESS

/// Returns why the item can't be sampled, or null if it can.
/obj/item/tf_toolgun/proc/sample_error(obj/item/item, mob/user)
	if(!istype(item) || item == src)
		return "not an item!"
	if(!isturf(item.loc) && item.loc != user)
		return "can't reach it!"
	if(item.anchored || (item.item_flags & ABSTRACT) || HAS_TRAIT(item, TRAIT_NODROP))
		return "won't budge!"
	if(item.atom_storage)
		return "too roomy inside!"
	if(item.GetComponent(/datum/component/stationloving))
		return "too important!"
	if(locate(/mob) in item.get_all_contents())
		return "someone's in there!"
	return null

/obj/item/tf_toolgun/proc/try_sample(atom/target, mob/user)
	var/obj/item/item = target
	var/error = sample_error(item, user)
	if(error)
		return error
	if(item.loc == user && !user.temporarilyRemoveItemFromInventory(item))
		return "won't budge!"
	if(sampled_item)
		sampled_item.forceMove(get_turf(item))
	item.forceMove(src)
	sampled_item = item
	balloon_alert(user, "sampled [item.name]")
	return null

/obj/item/tf_toolgun/proc/try_transform(atom/target, mob/living/user)
	var/mob/living/carbon/human/victim = target
	if(!istype(victim))
		return "only works on people!"
	if(!sampled_item)
		return "sample an item first!"
	if(victim.stat == DEAD)
		return "they're dead!"
	if(victim.GetComponent(/datum/component/object_tf))
		return "already an object!"
	if(!victim.mob_consents(/datum/preference/toggle/erp/object_tf))
		to_chat(victim, span_notice("A strange tingle washes over you and fades."))
		return "they resist the change!"

	busy = TRUE
	var/mutable_appearance/result = new(sampled_item)
	result.pixel_x = 0
	result.pixel_y = 0
	var/mutable_appearance/scanline = mutable_appearance('icons/effects/effects.dmi', "transform_effect")
	victim.transformation_animation(result, TF_TOOLGUN_TRANSFORM_TIME, scanline.appearance)
	victim.Immobilize(TF_TOOLGUN_TRANSFORM_TIME, ignore_canstun = TRUE)
	victim.visible_message(
		span_userlove("[victim] starts to shimmer and fold into the shape of [sampled_item]!"),
		span_userlove("Your body starts to shimmer and fold into the shape of [sampled_item]!"),
	)
	log_combat(user, victim, "began turning into [sampled_item] ([sampled_item.type])", src)
	addtimer(CALLBACK(src, PROC_REF(finish_transform), victim, user), TF_TOOLGUN_TRANSFORM_TIME)
	return null

/obj/item/tf_toolgun/proc/finish_transform(mob/living/carbon/human/victim, mob/living/user)
	busy = FALSE
	if(QDELETED(victim) || victim.stat == DEAD || QDELETED(sampled_item) || victim.GetComponent(/datum/component/object_tf))
		return
	var/obj/item/new_shape = sampled_item
	new_shape.forceMove(get_turf(victim))
	victim.AddComponent(/datum/component/object_tf, new_shape)
	new_shape.visible_message(span_userlove("[victim] is now [new_shape]!"))
	to_chat(victim, span_userlove("You are [new_shape] now. You can still talk. Use Resist to wriggle free."))
	log_combat(user, victim, "turned into [new_shape] ([new_shape.type])", src)

/obj/item/tf_toolgun/proc/try_restore(atom/target, mob/user)
	if(!isitem(target))
		return "not an object!"
	for(var/mob/living/inside in target)
		var/datum/component/object_tf/tf = inside.GetComponent(/datum/component/object_tf)
		if(tf?.container == target)
			log_combat(user, inside, "restored from [target]", src)
			tf.release()
			return null
	return "nobody in there!"

/obj/machinery/vending/dorms/build_inventories(start_empty)
	contraband[/obj/item/tf_toolgun] = 1
	return ..()
