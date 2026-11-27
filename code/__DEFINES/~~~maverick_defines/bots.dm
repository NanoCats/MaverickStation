/// Lazylist of the last few navbeacons a patrolling bot reached, oldest first
#define BB_BOT_RECENT_BEACONS "bot_recent_beacons"
/// How many reached beacons a patrolling bot remembers. Nearest-beacon fallback skips these,
/// so a bot at the end of a broken patrol chain can't bounce between the same two beacons forever.
#define BOT_RECENT_BEACON_MEMORY 3
