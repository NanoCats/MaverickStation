/obj/item/gun/energy/bimbo_ray
	name = "LustWish THOT Accelerator"
	desc = "A death squad pulse rifle lovingly refurbished by LustWish in glossy white and aggressively slutty pink. Its original emitters have been replaced with proprietary bimbofication technology."
	icon = 'modular_~maverick/icons/obj/weapons/bimbo_ray.dmi'
	icon_state = "bimbo_pulse"
	lefthand_file = 'modular_~maverick/icons/mob/inhands/bimbo_ray_lefthand.dmi'
	righthand_file = 'modular_~maverick/icons/mob/inhands/bimbo_ray_righthand.dmi'
	worn_icon = 'modular_~maverick/icons/mob/clothing/bimbo_ray_back.dmi'
	// Built from the charge level, like the pulse rifle: "bimbo_pulse0" to "bimbo_pulse4"
	inhand_icon_state = null
	worn_icon_state = null
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	light_color = "#ff69b4"
	ammo_type = list(/obj/item/ammo_casing/energy/bimbo_ray)
	selfcharge = 1
	charge_delay = 10 // Same rate as the advanced energy gun
	can_charge = FALSE
	gun_flags = NOT_A_REAL_GUN
	/// Makeover on: hair, figure and breasts change step by step
	var/makeover = TRUE
	/// Wardrobe on: an overdose turns clothes, shoes and ID slutty
	var/wardrobe = TRUE
	/// What the makeover does to hair: BIMBO_RAY_HAIR_KEEP, BIMBO_RAY_HAIR_BLONDE or BIMBO_RAY_HAIR_CUSTOM
	var/hair_mode = BIMBO_RAY_HAIR_KEEP
	/// Hair color for BIMBO_RAY_HAIR_CUSTOM
	var/custom_hair_color = "#ff69b4"

/obj/item/gun/energy/bimbo_ray/give_manufacturer_examine()
	AddElement(/datum/element/manufacturer_examine, COMPANY_LUSTWISH)

/obj/item/gun/energy/bimbo_ray/examine(mob/user)
	. = ..()
	. += span_notice("Use it in hand to change its settings.")

/obj/item/gun/energy/bimbo_ray/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/item/gun/energy/bimbo_ray/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ThotAccelerator")
		ui.open()

/obj/item/gun/energy/bimbo_ray/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/gun/energy/bimbo_ray/ui_data(mob/user)
	return list(
		"charge" = cell ? round(cell.charge / cell.maxcharge * 100) : 0,
		"makeover" = makeover,
		"wardrobe" = wardrobe,
		"hair_mode" = hair_mode,
		"hair_color" = custom_hair_color,
	)

/obj/item/gun/energy/bimbo_ray/ui_static_data(mob/user)
	return list("hair_modes" = list(BIMBO_RAY_HAIR_KEEP, BIMBO_RAY_HAIR_BLONDE, BIMBO_RAY_HAIR_CUSTOM))

/obj/item/gun/energy/bimbo_ray/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle_makeover")
			makeover = !makeover
		if("toggle_wardrobe")
			wardrobe = !wardrobe
		if("set_hair_mode")
			var/new_mode = params["mode"]
			if(!(new_mode in list(BIMBO_RAY_HAIR_KEEP, BIMBO_RAY_HAIR_BLONDE, BIMBO_RAY_HAIR_CUSTOM)))
				return FALSE
			hair_mode = new_mode
		if("pick_hair_color")
			var/new_color = input(usr, "Pick a hair color.", name, custom_hair_color) as color|null
			if(!new_color || !usr.is_holding(src))
				return FALSE
			custom_hair_color = new_color
			hair_mode = BIMBO_RAY_HAIR_CUSTOM
		else
			return FALSE
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	return TRUE

/// The hair color the makeover should apply, or null to leave hair alone
/obj/item/gun/energy/bimbo_ray/proc/get_hair_color()
	if(!makeover)
		return null
	switch(hair_mode)
		if(BIMBO_RAY_HAIR_BLONDE)
			return BIMBO_RAY_BLONDE_COLOR
		if(BIMBO_RAY_HAIR_CUSTOM)
			return custom_hair_color
	return null

/// Settings passed to Bimbonium in its reagent data
/obj/item/gun/energy/bimbo_ray/proc/get_pulse_settings()
	return list("makeover" = makeover, "wardrobe" = wardrobe, "hair" = get_hair_color())

/obj/item/ammo_casing/energy/bimbo_ray
	projectile_type = /obj/projectile/energy/bimbo_ray
	select_name = "bimbo"
	fire_sound = 'sound/items/weapons/pulse.ogg'
	muzzle_flash_color = "#ff69b4"
	harmful = FALSE
	e_cost = LASER_SHOTS(4, STANDARD_CELL_CHARGE)

/obj/projectile/energy/bimbo_ray
	name = "brain-melt pulse"
	icon = 'modular_~maverick/icons/obj/weapons/bimbo_ray.dmi'
	icon_state = "bimbo_beam"
	light_color = "#ff69b4"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/purple_laser
	hitsound = 'sound/effects/pop.ogg'
	hitsound_wall = 'sound/effects/pop.ogg'
	damage = 0
	damage_type = STAMINA
	armor_flag = ENERGY

/obj/projectile/energy/bimbo_ray/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	var/mob/living/carbon/human/victim = target
	if(!istype(victim) || blocked >= 100)
		return
	if(!victim.mob_consents(/datum/preference/toggle/erp/bimbofication))
		to_chat(victim, span_notice("A pink tingle washes over you and fades."))
		return

	var/obj/item/gun/energy/bimbo_ray/rifle = find_rifle()
	var/list/settings = rifle ? rifle.get_pulse_settings() : list("makeover" = TRUE, "wardrobe" = TRUE)
	victim.reagents?.add_reagent(/datum/reagent/drug/aphrodisiac/bimbonium, BIMBO_PULSE_DOSE, settings)

	// The hit itself should feel like something
	flash_color(victim, flash_color = "#ff69b4", flash_time = 1.5 SECONDS)
	bimbo_heart_burst(get_turf(victim))
	victim.adjust_arousal(BIMBO_PULSE_AROUSAL)
	victim.add_mood_event("bimbo_pulse", /datum/mood_event/bimbo_pulse)
	if(prob(BIMBO_PULSE_EMOTE_CHANCE))
		victim.emote(pick("giggle", "moan", "gasp", "blush"))
	to_chat(victim, span_userlove(pick(
		"Pink floods your vision and your thoughts go all soft and fuzzy!",
		"A warm, giggly tingle melts through your head!",
		"Your brain goes pleasantly blank for a second. What were you doing?",
		"A rush of pink warmth spreads all through your body!",
	)))

/// The rifle this pulse came from, held directly or mounted in a turret
/obj/projectile/energy/bimbo_ray/proc/find_rifle()
	if(istype(fired_from, /obj/item/gun/energy/bimbo_ray))
		return fired_from
	var/obj/machinery/porta_turret/turret = fired_from
	if(istype(turret) && istype(turret.stored_gun, /obj/item/gun/energy/bimbo_ray))
		return turret.stored_gun
	return null

/obj/machinery/vending/dorms/build_inventories(start_empty)
	contraband[/obj/item/gun/energy/bimbo_ray] = 2
	return ..()
