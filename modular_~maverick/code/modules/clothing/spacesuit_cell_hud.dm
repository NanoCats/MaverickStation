/// How many rows the space suit cell bar has. Each lit row is about 9% charge.
#define SPACESUIT_CELL_BAR_ROWS 11
/// At or under this much runtime the whole bar flashes red. Get inside.
#define SPACESUIT_CELL_FLASH_SECONDS 60
/// At or under this much runtime the bar is red.
#define SPACESUIT_CELL_RED_SECONDS (3 MINUTES / (1 SECONDS))
/// At or under this much runtime the bar is yellow.
#define SPACESUIT_CELL_YELLOW_SECONDS (6 MINUTES / (1 SECONDS))

/**
 * Swaps the space suit HUD to the finer cell bar when we know the exact charge.
 * The upstream bar has three segments and big gaps between its states, so it read as low long before the cell was.
 *
 * The height of the bar is the charge. The colour is how worried you should be:
 * - With a known runtime (a space suit with its regulator on), colour comes from seconds left, because the regulator
 *   drains a fixed amount per tick and a big cell lasts far longer than a small one at the same percent.
 * - Otherwise (MODsuits, regulator off) colour comes from percent.
 *
 * Missing, empty, coreless and hidden states keep their upstream icons.
 */
/atom/movable/screen/spacesuit/proc/apply_maverick_cell_bar(cell_state, cell_percent, seconds_left)
	icon = initial(icon)
	if(isnull(cell_percent))
		return
	if(!(cell_state in list(SPACESUIT_CELL_HIGH, SPACESUIT_CELL_MID, SPACESUIT_CELL_LOW, SPACESUIT_CELL_VERY_LOW)))
		return
	var/lit_rows = clamp(CEILING(cell_percent * SPACESUIT_CELL_BAR_ROWS / 100, 1), 1, SPACESUIT_CELL_BAR_ROWS)
	var/bar_style
	if(!isnull(seconds_left))
		if(seconds_left <= SPACESUIT_CELL_FLASH_SECONDS)
			bar_style = "flash"
		else if(seconds_left <= SPACESUIT_CELL_RED_SECONDS)
			bar_style = "red"
		else if(seconds_left <= SPACESUIT_CELL_YELLOW_SECONDS)
			bar_style = "yellow"
		else
			bar_style = "green"
	else if(lit_rows == 1)
		bar_style = "flash"
	else if(cell_percent >= 50)
		bar_style = "green"
	else if(cell_percent >= 25)
		bar_style = "yellow"
	else
		bar_style = "red"
	icon = 'modular_~maverick/icons/hud/spacesuit_cell.dmi'
	icon_state = "spacesuit_cell_[bar_style]_[lit_rows]"

/// Text under the cell bar: the percent always, with minutes and seconds left above it when given (on hover).
/atom/movable/screen/spacesuit/proc/maverick_cell_maptext(cell_percent, seconds_left)
	var/text = "[round(cell_percent, 0.1)]%"
	if(!isnull(seconds_left))
		var/whole_seconds = floor(seconds_left)
		var/secs = whole_seconds % 60
		text = "[floor(whole_seconds / 60)]:[secs < 10 ? "0" : ""][secs]<br>[text]"
	return MAPTEXT("<div align='right'>[text]</div>")

/// How far back the MODsuit runtime estimate looks at charge use.
#define MOD_RUNTIME_WINDOW (30 SECONDS)
/// How much history the estimate needs before it shows a time.
#define MOD_RUNTIME_MIN_WINDOW (5 SECONDS)

/obj/item/mod/control
	/// Recent (world.time, charge) samples, used to estimate how long the core lasts at the current drain.
	var/list/maverick_charge_samples

/// Core charge as a percent for the HUD, or null when there's nothing to show.
/obj/item/mod/control/proc/maverick_core_percent()
	if(isnull(core))
		return null
	var/charge = core.charge_amount()
	var/max_charge = core.max_charge_amount()
	if(charge == INFINITY)
		return 100
	if(!max_charge)
		return null
	return 100 * charge / max_charge

/**
 * Seconds of power left at the recent rate of use, or null if we can't tell.
 * MODsuit drain changes with modules, so this averages the last 30 seconds instead of using a fixed cost.
 */
/obj/item/mod/control/proc/maverick_runtime_left()
	if(!active || isnull(core))
		maverick_charge_samples = null
		return null
	var/charge = core.charge_amount()
	if(charge == INFINITY)
		return null
	var/list/newest = LAZYACCESS(maverick_charge_samples, length(maverick_charge_samples))
	if(isnull(newest) || world.time - newest[1] >= 1 SECONDS)
		LAZYADD(maverick_charge_samples, list(list(world.time, charge)))
	while(length(maverick_charge_samples) > 2 && world.time - maverick_charge_samples[2][1] >= MOD_RUNTIME_WINDOW)
		maverick_charge_samples.Cut(1, 2)
	var/list/oldest = maverick_charge_samples[1]
	var/elapsed = world.time - oldest[1]
	if(elapsed < MOD_RUNTIME_MIN_WINDOW)
		return null
	var/drained = oldest[2] - charge
	if(drained <= 0)
		return null // Charging, or not draining
	return charge / (drained / (elapsed / (1 SECONDS)))

#undef MOD_RUNTIME_WINDOW
#undef MOD_RUNTIME_MIN_WINDOW
#undef SPACESUIT_CELL_BAR_ROWS
#undef SPACESUIT_CELL_FLASH_SECONDS
#undef SPACESUIT_CELL_RED_SECONDS
#undef SPACESUIT_CELL_YELLOW_SECONDS
