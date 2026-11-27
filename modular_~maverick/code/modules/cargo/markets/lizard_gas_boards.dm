// The Lizard's Gas machines (resequencer, bio-regenerator, organic fabricator) only exist as boards in that ruin.
// They're strong machines, so the black market only has them now and then.

/datum/market_item/tool/lizard_gas_colonial
	name = "Colonial Marine Resequencer Board"
	desc = "Pulled from a dead filling station way out on the frontier. Prints clothing, gear and building materials from plant matter."
	item = /obj/item/circuitboard/machine/biogenerator/lizard_gas_colonial
	price_min = CARGO_CRATE_VALUE * 5
	price_max = CARGO_CRATE_VALUE * 8
	stock_max = 1
	availability_prob = 25

/datum/market_item/tool/lizard_gas_medvendor
	name = "DeForest Bio-Regenerator Board"
	desc = "A frontier medical fabricator, sold in limited numbers and mostly to colonies that could not wait for a doctor. Turns plant matter into medicine and injectors."
	item = /obj/item/circuitboard/machine/biogenerator/lizard_gas_medvendor
	price_min = CARGO_CRATE_VALUE * 5
	price_max = CARGO_CRATE_VALUE * 8
	stock_max = 1
	availability_prob = 25

/datum/market_item/tool/lizard_gas_smartfridge
	name = "SmartFridge Organic Fabricator Board"
	desc = "A chef's best friend where the deliveries never come. Turns plant matter into food and ingredients."
	item = /obj/item/circuitboard/machine/biogenerator/lizard_gas_smartfridge
	price_min = CARGO_CRATE_VALUE * 4
	price_max = CARGO_CRATE_VALUE * 6
	stock_max = 1
	availability_prob = 25
