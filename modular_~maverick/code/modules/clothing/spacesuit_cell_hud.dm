/// How many rows the space suit cell bar has. Each lit row is about 9% charge.
#define SPACESUIT_CELL_BAR_ROWS 11

/**
 * Swaps the space suit HUD to the finer cell bar when we know the exact charge.
 * The upstream bar has three segments and big gaps between its states, so it read as low long before the cell was.
 * Missing, empty, coreless and hidden states keep their upstream icons.
 */
/atom/movable/screen/spacesuit/proc/apply_maverick_cell_bar(cell_state, cell_percent)
	icon = initial(icon)
	if(isnull(cell_percent))
		return
	if(!(cell_state in list(SPACESUIT_CELL_HIGH, SPACESUIT_CELL_MID, SPACESUIT_CELL_LOW, SPACESUIT_CELL_VERY_LOW)))
		return
	var/lit_rows = clamp(CEILING(cell_percent * SPACESUIT_CELL_BAR_ROWS / 100, 1), 1, SPACESUIT_CELL_BAR_ROWS)
	icon = 'modular_~maverick/icons/hud/spacesuit_cell.dmi'
	icon_state = "spacesuit_cell_[lit_rows]"

#undef SPACESUIT_CELL_BAR_ROWS
