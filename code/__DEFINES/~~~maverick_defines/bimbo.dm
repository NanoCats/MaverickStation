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

/// Breast size floor at full intensity. 16 is a P cup (leadership's pick). The sizes past P take much bigger leaps.
/// The floor scales with intensity, so 25% is a D, 50% an H and 75% an L. Bigger is up to the player.
#define BIMBO_BREAST_FLOOR_MAX 16
/// Butt size floor at full intensity. 5 is one step past "hefty".
#define BIMBO_BUTT_FLOOR_MAX 5

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

// THOT Accelerator (the bimbo pulse rifle)
/// Label shown when examining the rifle
#define COMPANY_LUSTWISH "It has a glossy <b>[span_purple("LustWish")]</b> label on it."
/// Shots per full pulse rifle cell
#define BIMBO_RIFLE_SHOTS 100
/// Bimbonium injected by one brain-melt pulse
#define BIMBO_PULSE_DOSE 5
/// Arousal gained the moment a pulse hits
#define BIMBO_PULSE_AROUSAL 8
/// Chance that a pulse makes the target giggle, moan or similar
#define BIMBO_PULSE_EMOTE_CHANCE 60

/// Pink for the makeover outfit, heels and ID trim
#define BIMBO_MAKEOVER_PINK "#ff69b4"
/// The job title the makeover puts on your ID
#define BIMBO_ID_ASSIGNMENT "Slut"

// Bimbonium, the reagent the pulses inject
/// Intensity added per life tick while Bimbonium is in your system. About 3 per pulse, so roughly 30 pulses to max.
#define BIMBONIUM_INTENSITY_PER_TICK 0.3
/// Arousal added per life tick while Bimbonium is in your system
#define BIMBONIUM_AROUSAL_PER_TICK 2
/// Chance per life tick to take the next makeover step (hair, figure, breasts)
#define BIMBONIUM_MAKEOVER_STEP_CHANCE 25
/// Stamina lost per tick while overdosed on Bimbonium
#define BIMBONIUM_OVERDOSE_STAMINA 4
/// How long the reality overwrite knocks you out
#define BIMBO_OVERWRITE_KNOCKOUT (4 SECONDS)
/// PDA colors after the reality overwrite
#define BIMBO_PDA_COLORS "#ff69b4#ffffff"
/// Overdose amount. About six pulses in a short time.
#define BIMBONIUM_OVERDOSE 30

// Bimbo ray hair settings
#define BIMBO_RAY_HAIR_KEEP "Leave it alone"
#define BIMBO_RAY_HAIR_BLONDE "Platinum blonde"
#define BIMBO_RAY_HAIR_CUSTOM "Custom color"
/// The ray's blonde
#define BIMBO_RAY_BLONDE_COLOR "#f3e3b5"
