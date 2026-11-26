/// Checks that an overlay light leaves every spatial grid cell it joined.
/// Shrinking the range of a lit light used to strand the component in the outer cells,
/// which showed up as a random overlay_lighting hard delete in create_and_destroy.
/datum/unit_test/overlay_lighting_cells

/obj/item/overlay_lighting_cells_test
	name = "overlay lighting test light"
	light_system = OVERLAY_LIGHT
	light_range = 6
	light_on = FALSE

/datum/unit_test/overlay_lighting_cells/Run()
	// Two tiles short of a cell edge: range 6 reaches past the edge, range 1 does not.
	var/edge_x = GET_SPATIAL_INDEX(run_loc_floor_bottom_left.x) * SPATIAL_GRID_CELLSIZE - 2
	var/edge_y = GET_SPATIAL_INDEX(run_loc_floor_bottom_left.y) * SPATIAL_GRID_CELLSIZE - 2
	var/turf/spot = locate(edge_x, edge_y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(spot, "Could not find a turf next to a grid cell edge.")

	var/obj/item/overlay_lighting_cells_test/light = allocate(/obj/item/overlay_lighting_cells_test, spot)
	var/datum/component/overlay_lighting/light_component = light.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT_NOTNULL(light_component, "The test light has no overlay_lighting component.")

	light.set_light_on(TRUE)
	TEST_ASSERT(cells_holding(light_component, spot) > 1, "A range 6 light next to a cell edge should be in more than one cell.")

	light.set_light_range(1)
	light.set_light_on(FALSE)
	TEST_ASSERT_EQUAL(cells_holding(light_component, spot), 0, "A light that was shrunk and turned off is still in a spatial grid cell.")

	light.set_light_range(6)
	light.set_light_on(TRUE)
	light.set_light_range(1)
	qdel(light)
	TEST_ASSERT_EQUAL(cells_holding(light_component, spot), 0, "A light that was shrunk and deleted is still in a spatial grid cell.")

/// Counts the grid cells near center that list the light as a dynamic light source.
/datum/unit_test/overlay_lighting_cells/proc/cells_holding(datum/component/overlay_lighting/light_component, turf/center)
	. = 0
	for(var/datum/spatial_grid_cell/grid_cell as anything in SSspatial_grid.get_cells_in_range(center, SPATIAL_GRID_CELLSIZE * 2))
		if(light_component in grid_cell.dynamic_light_sources)
			.++
