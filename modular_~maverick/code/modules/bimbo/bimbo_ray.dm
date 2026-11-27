/obj/item/gun/energy/bimbo_ray
	name = "bimbo pulse rifle"
	desc = "A death squad pulse rifle that LustWish got their hands on and gave a glossy white paint job with hot pink lights. It no longer destroys anything except attention spans. A tiny reactor recharges it on its own. Use it in hand to change its settings."
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
	/// If TRUE, hits also give the "Barbie" makeover (each part still needs its own pref)
	var/barbie = TRUE
	/// What the makeover does to hair: BIMBO_RAY_HAIR_KEEP, BIMBO_RAY_HAIR_BLONDE or BIMBO_RAY_HAIR_CUSTOM
	var/hair_mode = BIMBO_RAY_HAIR_KEEP
	/// Hair color for BIMBO_RAY_HAIR_CUSTOM
	var/custom_hair_color = "#ff69b4"

/obj/item/gun/energy/bimbo_ray/examine(mob/user)
	. = ..()
	. += span_notice("Makeover: <b>[barbie ? "on" : "off"]</b>. Hair: <b>[hair_mode][hair_mode == BIMBO_RAY_HAIR_CUSTOM ? " ([custom_hair_color])" : ""]</b>.")

/obj/item/gun/energy/bimbo_ray/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return
	var/list/options = list(
		"Makeover: [barbie ? "on" : "off"]" = "makeover",
		"Hair: [hair_mode]" = "hair",
	)
	var/choice = tgui_input_list(user, "Change a setting.", "Bimbo pulse rifle", options)
	if(!choice || !user.is_holding(src))
		return TRUE
	switch(options[choice])
		if("makeover")
			barbie = !barbie
			balloon_alert(user, "makeover [barbie ? "on" : "off"]")
		if("hair")
			var/new_mode = tgui_input_list(user, "What should the makeover do to hair?", "Bimbo pulse rifle", list(BIMBO_RAY_HAIR_KEEP, BIMBO_RAY_HAIR_BLONDE, BIMBO_RAY_HAIR_CUSTOM), hair_mode)
			if(!new_mode || !user.is_holding(src))
				return TRUE
			if(new_mode == BIMBO_RAY_HAIR_CUSTOM)
				var/new_color = input(user, "Pick a hair color.", "Bimbo pulse rifle", custom_hair_color) as color|null
				if(!new_color || !user.is_holding(src))
					return TRUE
				custom_hair_color = new_color
			hair_mode = new_mode
			balloon_alert(user, "hair: [lowertext(hair_mode)]")
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	return TRUE

/// The hair color the makeover should apply, or null to leave hair alone
/obj/item/gun/energy/bimbo_ray/proc/get_hair_color()
	if(!barbie)
		return null
	switch(hair_mode)
		if(BIMBO_RAY_HAIR_BLONDE)
			return BIMBO_RAY_BLONDE_COLOR
		if(BIMBO_RAY_HAIR_CUSTOM)
			return custom_hair_color
	return null

/obj/item/ammo_casing/energy/bimbo_ray
	projectile_type = /obj/projectile/energy/bimbo_ray
	select_name = "bimbo"
	fire_sound = 'sound/items/weapons/pulse.ogg'
	muzzle_flash_color = "#ff69b4"
	harmful = FALSE
	e_cost = LASER_SHOTS(4, STANDARD_CELL_CHARGE)

/obj/projectile/energy/bimbo_ray
	name = "endocrine modification pulse"
	icon = 'modular_~maverick/icons/obj/weapons/bimbo_ray.dmi'
	icon_state = "bimbo_beam"
	light_color = "#ff69b4"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/purple_laser
	damage = 0
	damage_type = STAMINA
	armor_flag = ENERGY

/obj/projectile/energy/bimbo_ray/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(!ishuman(target))
		return
	var/obj/item/gun/energy/bimbo_ray/ray = fired_from
	var/barbie = istype(ray) ? ray.barbie : TRUE
	var/hair_color = istype(ray) ? ray.get_hair_color() : null
	if(!bimbo_hit(target, barbie, hair_color))
		to_chat(target, span_notice("A pink tingle washes over you and fades."))

/obj/machinery/vending/dorms/build_inventories(start_empty)
	contraband[/obj/item/gun/energy/bimbo_ray] = 2
	return ..()
