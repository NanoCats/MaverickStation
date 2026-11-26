// File Labels
//
// Add a label based on if a file is modified in the diff
//
// You can optionally set add_only to make the label one-way -
// if the edit to the file is removed in a later commit,
// the label will not be removed
export const file_labels = {
  GitHub: {
    filepaths: ['.github/'],
  },
  SQL: {
    filepaths: ['SQL/'],
  },
  'Map Edit': {
    filepaths: ['_maps/'],
    file_extensions: ['.dmm'],
  },
  Tools: {
    filepaths: ['tools/'],
  },
  'Config Update': {
    filepaths: ['config/', 'code/controllers/configuration/entries/'],
    add_only: true,
  },
  Sprites: {
    filepaths: ['icons/'],
    file_extensions: ['.dmi'],
    add_only: true,
  },
  Sound: {
    filepaths: ['sound/'],
    file_extensions: ['.ogg'],
    add_only: true,
  },
  UI: {
    filepaths: ['tgui/'],
    add_only: true,
  },
  // MAVERICK EDIT BEGIN - colony gear must never be restricted, so flag any PR that touches it
  'Colony Gear': {
    filepaths: [
      'colony_fabricator/',
      'kahraman_equipment/',
      'colony_gear/',
      'company_imports/akh_frontier',
      'company_imports/kahraman',
      'frontiertoolsdisk',
    ],
  },
  // MAVERICK EDIT END
};

// MAVERICK EDIT BEGIN - outside labels
// Outside Labels
//
// Add a label if any changed file is NOT under one of the given paths.
// Files listed in ignore are skipped entirely (they do not count either way).
export const outside_labels = {
  'Upstream File Edit': {
    allowed_paths: ['modular_~maverick/', 'maverick/'],
    ignore: ['tgstation.dme'],
  },
};

// Labels that leadership applies by hand after a test, and that the bot takes
// off again when new commits are pushed, since the old test no longer covers them.
export const cleared_on_push = ['Testing Completed'];

// When the key label is on a PR, the bot removes the listed labels.
// A push clears Testing Completed, so Needs Playtest comes back by itself.
// Old label name -> new label name. PR history keeps the name a label had
// when it was applied, so list every rename here or the bot re-adds the old one.
export const renamed_labels = {
  'needs-playtest': 'Needs Playtest',
};

export const replaced_labels = {
  'Testing Completed': ['Needs Playtest'],
};
// MAVERICK EDIT END

// Title Labels
//
// Add a label based on keywords in the title
export const title_labels = {
  Logging: {
    keywords: ['log', 'logging'],
  },
  Removal: {
    keywords: ['remove', 'delete'],
  },
  Refactor: {
    keywords: ['refactor'],
  },
  'Unit Tests': {
    keywords: ['unit test'],
  },
  'April Fools': {
    keywords: ['[april fools]'],
  },
  'Do Not Merge': {
    keywords: ['[dnm]', '[do not merge]'],
  },
  'GBP: No Update': {
    keywords: ['[no gbp]'],
  },
  'Test Merge Only': {
    keywords: ['[tm only]', '[test merge only]'],
  },
  // MAVERICK EDIT BEGIN - Maverick title labels
  'Upstream Sync': {
    keywords: ['[sync]', 'upstream sync'],
  },
  // whole_word so "report", "support" and "teleport" do not match
  Port: {
    keywords: ['port', 'ports', 'ported', 'porting'],
    whole_word: true,
  },
  // MAVERICK EDIT END
};

// Changelog Labels
//
// Adds labels based on keywords in the changelog
// TODO use the existing changelog parser
export const changelog_labels = {
  Fix: {
    default_text: 'fixed a few things',
    keywords: ['fix', 'fixes', 'bugfix'],
  },
  QoL: {
    default_text: 'made something easier to use',
    keywords: ['qol'],
  },
  Sound: {
    default_text: 'added/modified/removed audio or sound effects',
    keywords: ['sound'],
  },
  Feature: {
    default_text: 'Added new mechanics or gameplay changes',
    alt_default_text: 'Added more things',
    keywords: ['add', 'adds', 'rscadd'],
  },
  Removal: {
    default_text: 'Removed old things',
    keywords: ['del', 'dels', 'rscdel'],
  },
  Sprites: {
    default_text: 'added/modified/removed some icons or images',
    keywords: ['image'],
  },
  'Grammar and Formatting': {
    default_text: 'fixed a few typos',
    keywords: ['typo', 'spellcheck'],
  },
  Balance: {
    default_text: 'rebalanced something',
    keywords: ['balance'],
  },
  'Code Improvement': {
    default_text: 'changed some code',
    keywords: ['code_imp', 'code'],
  },
  Refactor: {
    default_text: 'refactored some code',
    keywords: ['refactor'],
  },
  'Config Update': {
    default_text: 'changed some config setting',
    keywords: ['config'],
  },
  Administration: {
    default_text: 'messed with admin stuff',
    keywords: ['admin'],
  },
};
