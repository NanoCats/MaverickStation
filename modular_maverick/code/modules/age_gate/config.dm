/// Ask new players for their date of birth and ban anyone under the minimum age.
/datum/config_entry/flag/maverick_age_gate
	default = TRUE

/// Minimum age to pass the age gate.
/datum/config_entry/number/maverick_age_gate_minimum_age
	default = 18
	integer = TRUE
	min_val = 18

/// Ages above this are treated as a fake answer and banned like an underage one.
/datum/config_entry/number/maverick_age_gate_maximum_age
	default = 100
	integer = TRUE
	min_val = 60
	max_val = 120

/// Version of config/maverick/privacy_policy.txt. Raise it for meaningful changes and every player is asked to agree again.
/datum/config_entry/number/maverick_privacy_policy_version
	default = 1
	integer = TRUE
	min_val = 1
