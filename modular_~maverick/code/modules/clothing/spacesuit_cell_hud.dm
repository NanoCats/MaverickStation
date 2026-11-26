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

/// Hover text for the cell bar: percent, plus minutes and seconds left when we know them.
/atom/movable/screen/spacesuit/proc/maverick_cell_maptext(cell_percent, seconds_left)
	var/text = "[round(cell_percent, 0.1)]%"
	if(!isnull(seconds_left))
		var/whole_seconds = floor(seconds_left)
		var/secs = whole_seconds % 60
		text += "<br>[floor(whole_seconds / 60)]:[secs < 10 ? "0" : ""][secs]"
	return MAPTEXT("<div align='right'>[text]</div>")

#undef SPACESUIT_CELL_BAR_ROWS
#undef SPACESUIT_CELL_FLASH_SECONDS
#undef SPACESUIT_CELL_RED_SECONDS
#undef SPACESUIT_CELL_YELLOW_SECONDS
