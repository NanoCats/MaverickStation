// Lets a node be researched outright by feeding one of its required_items_to_unlock to a destructive analyzer.
// Upstream only uses those items to reveal hidden nodes; this turns them into an alternative to paying points.

/datum/techweb_node
	/// If TRUE, deconstructing one of required_items_to_unlock researches this node for free, prerequisites or not.
	var/research_on_deconstruct = FALSE

/obj/machinery/rnd/destructive_analyzer/try_deconstruct_loaded_item(node_path)
	var/datum/techweb_node/node = SSresearch.techweb_nodes[node_path]
	// Checked before the parent destroys the item. The UI hands us any node path, so make sure this item really unlocks it.
	var/free_research = node?.research_on_deconstruct && stored_research && loaded_item \
		&& (loaded_item.type in node.required_items_to_unlock) && !stored_research.researched_nodes[node.type]
	. = ..()
	if(. && free_research)
		stored_research.research_node(node, force = TRUE, auto_adjust_cost = FALSE, research_source = src)

/obj/machinery/rnd/destructive_analyzer/ui_data(mob/user)
	. = ..()
	if(!stored_research)
		return
	// The UI only enables the button for hidden nodes, so report ours as available until researched.
	for(var/list/node_entry as anything in .["node_data"])
		var/datum/techweb_node/node = SSresearch.techweb_nodes[node_entry["node_path"]]
		if(node?.research_on_deconstruct)
			node_entry["node_hidden"] = !stored_research.researched_nodes[node.type]
