// MaxTac: an extreme-response ERT built to put down one very dangerous target.
// Admin spawn only, through the Summon ERT template list.

/datum/ert/maxtac
	roles = list(/datum/antagonist/ert/maxtac)
	leader_role = /datum/antagonist/ert/maxtac/leader
	rename_team = "MaxTac"
	code = "Black"
	mission = "Locate and neutralize the target. Lethal force is authorized."
	polldesc = "a MaxTac psycho-response squad"
	teamsize = 4
	// Chrome is the point. Keep the player's species.
	enforce_human = FALSE

/datum/antagonist/ert/maxtac
	name = "MaxTac Operative"
	outfit = /datum/outfit/centcom/ert/maxtac
	plasmaman_outfit = /datum/outfit/plasmaman/centcom_commander
	role = "Operative"
	rip_and_tear = TRUE

/datum/antagonist/ert/maxtac/leader
	name = "MaxTac Squad Leader"
	outfit = /datum/outfit/centcom/ert/maxtac/leader
	role = "Squad Leader"

/datum/id_trim/centcom/ert/security/maxtac
	assignment = "MaxTac Operative"

/datum/id_trim/centcom/ert/commander/maxtac
	assignment = "MaxTac Squad Leader"
