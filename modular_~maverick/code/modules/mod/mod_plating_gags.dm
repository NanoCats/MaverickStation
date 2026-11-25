/// Plating colors used when a theme has no sprite to sample from.
#define MOD_PLATING_FALLBACK_COLORS "#5a5a6e#7df2ff"
/// Pixels darker than this (HSV value, 0-100) count as outline and are ignored when sampling.
#define MOD_PLATING_MIN_VALUE 16
/// Minimum saturation and value (0-100) for a color to be picked as the accent.
#define MOD_PLATING_ACCENT_MIN_SATURATION 40
#define MOD_PLATING_ACCENT_MIN_VALUE 35
/// Minimum hue distance (degrees) between body and accent, unless the body is close to grey.
#define MOD_PLATING_ACCENT_MIN_HUE_DISTANCE 36

/datum/greyscale_config/mod_plating
	name = "MOD External Plating"
	icon_file = 'modular_~maverick/icons/obj/clothing/modsuit/mod_plating_greyscale.dmi'
	json_config = 'modular_~maverick/code/datums/greyscale/json_configs/mod_plating.json'

/// Same plating with a two-tone stripe.
/datum/greyscale_config/mod_plating/split
	name = "MOD External Plating (Split Stripe)"
	json_config = 'modular_~maverick/code/datums/greyscale/json_configs/mod_plating_split.json'

/datum/mod_theme
	/// GAGS colors ("#body#accent") for the generated plating sprite.
	/// Only used when the theme has no hand-made plating sprite. Derived from the suit sprites when null.
	var/plating_colors

/// Returns the GAGS colors for this theme's generated plating, deriving and caching them on first use.
/datum/mod_theme/proc/get_plating_colors()
	if(!plating_colors)
		plating_colors = derive_plating_colors()
	return plating_colors

/// Samples the control unit, chestplate and helmet sprites of the default skin.
/// The most common color becomes the body, the most common clearly different saturated color becomes the accent.
/datum/mod_theme/proc/derive_plating_colors()
	var/list/skin = variants[default_skin]
	var/icon_file = skin?[MOD_ICON_OVERRIDE] || 'icons/obj/clothing/modsuit/mod_clothing.dmi'
	var/list/buckets = list()
	for(var/part in list("control", "chestplate", "helmet"))
		var/state = "[default_skin]-[part]"
		if(!icon_exists(icon_file, state))
			continue
		var/icon/sample = icon(icon_file, state, SOUTH, 1)
		for(var/x in 1 to sample.Width())
			for(var/y in 1 to sample.Height())
				var/pixel = sample.GetPixel(x, y)
				if(!pixel)
					continue
				var/list/rgba = rgb2num(pixel)
				if(length(rgba) > 3 && rgba[4] < 128)
					continue
				var/list/hsv = rgb2num(pixel, COLORSPACE_HSV)
				if(hsv[3] < MOD_PLATING_MIN_VALUE)
					continue
				var/key = "[rgba[1] >> 5]-[rgba[2] >> 5]-[rgba[3] >> 5]"
				var/list/bucket = buckets[key]
				if(!bucket)
					bucket = list(0, 0, 0, 0)
					buckets[key] = bucket
				bucket[1]++
				bucket[2] += rgba[1]
				bucket[3] += rgba[2]
				bucket[4] += rgba[3]

	if(!length(buckets))
		return MOD_PLATING_FALLBACK_COLORS

	// Each entry: list(count, list(hue, saturation, value))
	var/list/entries = list()
	for(var/key in buckets)
		var/list/bucket = buckets[key]
		var/count = bucket[1]
		var/average = rgb(round(bucket[2] / count), round(bucket[3] / count), round(bucket[4] / count))
		entries += list(list(count, rgb2num(average, COLORSPACE_HSV)))
	sortTim(entries, GLOBAL_PROC_REF(cmp_mod_plating_entries))

	var/list/body = entries[1][2]
	var/list/accent
	for(var/i in 2 to length(entries))
		var/list/candidate = entries[i][2]
		if(candidate[2] < MOD_PLATING_ACCENT_MIN_SATURATION || candidate[3] < MOD_PLATING_ACCENT_MIN_VALUE)
			continue
		var/hue_distance = abs(candidate[1] - body[1])
		hue_distance = min(hue_distance, 360 - hue_distance)
		if(body[2] < 30 || hue_distance > MOD_PLATING_ACCENT_MIN_HUE_DISTANCE)
			accent = candidate
			break

	// The template's lit face is near white, so lift the body a little to keep it from going muddy.
	var/body_color = rgb(body[1], body[2], min(100, body[3] * 1.2), space = COLORSPACE_HSV)
	var/accent_color
	if(accent)
		accent_color = rgb(accent[1], accent[2], max(accent[3], 60), space = COLORSPACE_HSV)
	else
		accent_color = rgb(body[1], body[2] * 0.5, min(100, body[3] + 50), space = COLORSPACE_HSV)
	return body_color + accent_color

/proc/cmp_mod_plating_entries(list/a, list/b)
	return b[1] - a[1]

/obj/item/mod/construction/plating/Initialize(mapload)
	. = ..()
	// Hand-made sprites always win.
	if(icon_exists(initial(icon), icon_state))
		return
	var/datum/mod_theme/used_theme = GLOB.mod_themes[theme]
	icon_state = "plating"
	if(greyscale_config && greyscale_colors)
		set_greyscale(greyscale_colors, greyscale_config)
		return
	set_greyscale(used_theme.get_plating_colors(), /datum/greyscale_config/mod_plating)

#undef MOD_PLATING_FALLBACK_COLORS
#undef MOD_PLATING_MIN_VALUE
#undef MOD_PLATING_ACCENT_MIN_SATURATION
#undef MOD_PLATING_ACCENT_MIN_VALUE
#undef MOD_PLATING_ACCENT_MIN_HUE_DISTANCE
