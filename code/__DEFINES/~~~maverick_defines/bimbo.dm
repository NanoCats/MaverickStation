// Bimbo quirk and ray. See modular_~maverick/code/modules/bimbo/

/// Trait source for everything the bimbo component adds
#define BIMBO_TRAIT_SOURCE "bimbo_component"

/// Highest intensity anyone can reach
#define BIMBO_MAX_INTENSITY 100
/// Lowest intensity the quirk slider allows, so the quirk is never free points
#define BIMBO_QUIRK_MIN_INTENSITY 25
/// Intensity added by one ray hit or one hexacrocin overdose roll
#define BIMBO_HIT_INTENSITY 10
/// Ray intensity removed per life tick while pentacamphor is in the system
#define BIMBO_CURE_PER_TICK 2

/// Pink used for the lipstick when nothing else is set
#define BIMBO_DEFAULT_LIPSTICK_COLOR "#ff69b4"

// Tiers. A tier starts at the listed intensity.
#define BIMBO_TIER_NONE 0
#define BIMBO_TIER_DITZY 1
#define BIMBO_TIER_AIRHEAD 2
#define BIMBO_TIER_BIMBO 3
#define BIMBO_TIER_BUBBLEHEADED 4

#define BIMBO_AIRHEAD_INTENSITY 25
#define BIMBO_BIMBO_INTENSITY 50
#define BIMBO_BUBBLEHEADED_INTENSITY 75

/// Effects act this much stronger at full arousal. Scales up from AROUSAL_LOW.
#define BIMBO_AROUSAL_MAX_MULTIPLIER 1.25
/// Effects act this much weaker during the clarity window after climax
#define BIMBO_CLARITY_MULTIPLIER 0.75
/// How long the clarity window lasts
#define BIMBO_CLARITY_DURATION (3 MINUTES)

/// Arousal floor at full intensity. Scales down with intensity.
#define BIMBO_AROUSAL_FLOOR_MAX 40
/// Arousal gained when someone examines you while you are exposed
#define BIMBO_EXAMINE_AROUSAL 8
/// Arousal gained when you examine something lewd
#define BIMBO_EXAMINING_AROUSAL 5
/// Stamina lost per lewd interaction on you at full intensity
#define BIMBO_LEWD_STAMINA_MAX 30
/// How long hypnosis lasts on a mindshielded bimbo before the implant clears it
#define BIMBO_MINDSHIELD_SHAKE_OFF (2 MINUTES)
/// Alert category for the heat icon
#define ALERT_BIMBO_HEAT "bimbo_heat"

/// Breast size floor at full intensity. 8 is an H cup: big, but still something a real person could have.
/// The floor scales with intensity, so 25% is a B, 50% a D and 75% an F. Bigger is up to the player.
#define BIMBO_BREAST_FLOOR_MAX 8
/// Butt size floor at full intensity. 4 is "hefty"; the sizes above that are hyper territory.
#define BIMBO_BUTT_FLOOR_MAX 4

/// Long actions shorter than this never get interrupted by the short attention span
#define BIMBO_ATTENTION_SPAN (10 SECONDS)
/// An invasive lewd thought pops up at most this often
#define BIMBO_INVASIVE_THOUGHT_COOLDOWN (1 MINUTES)
/// The short attention span drops an action at most this often
#define BIMBO_LOSE_FOCUS_COOLDOWN (1 MINUTES)
/// How far away shiny things can distract you
#define BIMBO_SHINY_RANGE 2

/// Share of negative mood that blissful ignorance cancels at full intensity
#define BIMBO_BLISS_MAX 0.5
/// Do-after slowdown at full intensity
#define BIMBO_MAX_ACTION_SLOWDOWN 0.2
/// Chance that a word over the length cap gets forgotten
#define BIMBO_FORGET_WORD_CHANCE 50

/// From /datum/interaction/act() on the target of a lewd interaction: (mob/living/carbon/human/user, datum/interaction/interaction)
#define COMSIG_HUMAN_LEWD_INTERACTION_RECEIVED "human_lewd_interaction_received"

// Bimbo ray hair settings
#define BIMBO_RAY_HAIR_KEEP "Leave it alone"
#define BIMBO_RAY_HAIR_BLONDE "Platinum blonde"
#define BIMBO_RAY_HAIR_CUSTOM "Custom color"
/// The ray's blonde
#define BIMBO_RAY_BLONDE_COLOR "#f3e3b5"
