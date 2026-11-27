// Cat screams for the custom scream pref: a cute "Cat" and a "Robocat", both from Monkestation.
// The old realistic cat scream existed twice under the same "Cat Scream" name. Both copies now
// share the "Cat (Realistic)" name, so the menu lists it once and neither type is deleted.

/datum/scream_type/tajaran
	name = "Cat (Realistic)"

/datum/scream_type/cat
	name = "Cat (Realistic)"

/datum/scream_type/cat_merowr
	name = "Cat"
	male_screamsounds = list('modular_~maverick/sound/emotes/screams/merowr.ogg')
	female_screamsounds = null

/datum/scream_type/robocat
	name = "Robocat"
	male_screamsounds = list(
		'modular_~maverick/sound/emotes/screams/robocat/catscream1.ogg',
		'modular_~maverick/sound/emotes/screams/robocat/catscream2.ogg',
		'modular_~maverick/sound/emotes/screams/robocat/catscream3.ogg',
		'modular_~maverick/sound/emotes/screams/robocat/catscream4.ogg',
		'modular_~maverick/sound/emotes/screams/robocat/catscream5.ogg',
	)
	female_screamsounds = null
