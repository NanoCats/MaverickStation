/obj/item/gun/energy/bimbo_ray
	name = "bimbo ray"
	desc = "A pink ray gun from the LustWish catalogue. One zap and your head feels lighter. It recharges on its own."
	icon = 'modular_~maverick/icons/obj/weapons/bimbo_ray.dmi'
	icon_state = "bimbo_ray"
	lefthand_file = 'modular_~maverick/icons/mob/inhands/bimbo_ray_lefthand.dmi'
	righthand_file = 'modular_~maverick/icons/mob/inhands/bimbo_ray_righthand.dmi'
	inhand_icon_state = "bimbo_ray"
	ammo_type = list(/obj/item/ammo_casing/energy/bimbo_ray)
	automatic_charge_overlays = FALSE
	selfcharge = 1
	charge_delay = 20
	gun_flags = NOT_A_REAL_GUN

/obj/item/ammo_casing/energy/bimbo_ray
	projectile_type = /obj/projectile/energy/bimbo_ray
	select_name = "bimbo"
	fire_sound = 'sound/effects/stealthoff.ogg'
	harmful = FALSE
	e_cost = LASER_SHOTS(4, STANDARD_CELL_CHARGE)

/obj/projectile/energy/bimbo_ray
	name = "bimbo beam"
	icon = 'modular_~maverick/icons/obj/weapons/bimbo_ray.dmi'
	icon_state = "bimbo_beam"
	light_color = "#ff69b4"
	damage = 0
	damage_type = STAMINA
	armor_flag = ENERGY

/obj/projectile/energy/bimbo_ray/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(!ishuman(target))
		return
	if(!bimbo_hit(target, barbie = TRUE))
		to_chat(target, span_notice("A pink tingle washes over you and fades."))

/obj/machinery/vending/dorms/build_inventories(start_empty)
	contraband[/obj/item/gun/energy/bimbo_ray] = 2
	return ..()
