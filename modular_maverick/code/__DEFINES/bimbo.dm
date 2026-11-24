// Bimbo quirk and ray. See modular_maverick/code/modules/bimbo/

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

/// Effects act this much stronger while very aroused
#define BIMBO_PENT_UP_MULTIPLIER 1.15
/// Effects act this much weaker during the clarity window after climax
#define BIMBO_CLARITY_MULTIPLIER 0.75
/// How long the clarity window lasts
#define BIMBO_CLARITY_DURATION (3 MINUTES)

/// Arousal floor at full intensity. Scales down with intensity.
#define BIMBO_AROUSAL_FLOOR_MAX 40
/// Arousal gained when someone examines you while you are exposed
#define BIMBO_EXAMINE_AROUSAL 8

/// Breast size floor at full intensity. 19 is BREAST_SIZE_S, the largest the prefs allow.
#define BIMBO_BREAST_FLOOR_MAX 19

/// Long actions shorter than this never get interrupted by the short attention span
#define BIMBO_ATTENTION_SPAN (5 SECONDS)
/// How far away shiny things can distract you
#define BIMBO_SHINY_RANGE 2

/// Share of negative mood that blissful ignorance cancels at full intensity
#define BIMBO_BLISS_MAX 0.5
/// Do-after slowdown at full intensity
#define BIMBO_MAX_ACTION_SLOWDOWN 0.4
