// MaxTac: an extreme-response ERT built to put down one very dangerous target.
// Admin spawn only, through the Summon ERT template list.

/datum/ert/maxtac
	// The spawner hands these out by list position. A squad of four gets the commander and three
	// different roles from the first four. Larger squads also get assault.
	roles = list(
		/datum/antagonist/ert/maxtac/mantis,
		/datum/antagonist/ert/maxtac/heavy,
		/datum/antagonist/ert/maxtac/medic,
		/datum/antagonist/ert/maxtac/sniper,
		/datum/antagonist/ert/maxtac,
	)
	leader_role = /datum/antagonist/ert/maxtac/commander
	rename_team = "MaxTac"
	code = "Black"
	mission = "Locate and neutralize the target. Lethal force is authorized."
	polldesc = "a MaxTac psycho-response squad"
	teamsize = 4
	// Chrome is the point. Keep the player's species.
	enforce_human = FALSE

// Antagonist roles. The base type is the assault operative.

/datum/antagonist/ert/maxtac
	name = "MaxTac Assault"
	outfit = /datum/outfit/centcom/ert/maxtac
	plasmaman_outfit = /datum/outfit/plasmaman/centcom_commander
	role = "Assault"
	rip_and_tear = TRUE

/datum/antagonist/ert/maxtac/commander
	name = "MaxTac Commander"
	outfit = /datum/outfit/centcom/ert/maxtac/commander
	role = "Commander"

/datum/antagonist/ert/maxtac/mantis
	name = "MaxTac Mantis"
	outfit = /datum/outfit/centcom/ert/maxtac/mantis
	role = "Mantis"

/datum/antagonist/ert/maxtac/heavy
	name = "MaxTac Heavy"
	outfit = /datum/outfit/centcom/ert/maxtac/heavy
	role = "Heavy"

/datum/antagonist/ert/maxtac/sniper
	name = "MaxTac Sniper"
	outfit = /datum/outfit/centcom/ert/maxtac/sniper
	role = "Sniper"

/datum/antagonist/ert/maxtac/medic
	name = "MaxTac Medic"
	outfit = /datum/outfit/centcom/ert/maxtac/medic
	role = "Medic"

// ID trims. Death squad cards and access, with the MaxTac role as the job.

/datum/id_trim/centcom/deathsquad/maxtac
	assignment = "MaxTac Assault"
	honorifics = list("Officer")

/datum/id_trim/centcom/deathsquad/maxtac/commander
	assignment = "MaxTac Commander"
	honorifics = list("Commander")

/datum/id_trim/centcom/deathsquad/maxtac/mantis
	assignment = "MaxTac Mantis"

/datum/id_trim/centcom/deathsquad/maxtac/heavy
	assignment = "MaxTac Heavy"

/datum/id_trim/centcom/deathsquad/maxtac/sniper
	assignment = "MaxTac Sniper"

/datum/id_trim/centcom/deathsquad/maxtac/medic
	assignment = "MaxTac Medic"
