import { strict as assert } from 'node:assert';
import { get_updated_label_set } from './autoLabel.js';

const empty_pr = {
  action: 'opened',
  pull_request: {
    body: 'This PR will have no labels',
    title: 'Pr with no labels',
    mergeable: true,
  },
};
const empty_label_set = await get_updated_label_set({
  github: null,
  context: { payload: empty_pr },
});
assert.equal(empty_label_set.length, 0, 'No labels should be added');

const cl = `
My Awesome PR

:cl: Awesome Dude
add: Adds Awesome Stuff
refactor: refactored some code
:/cl:
`;
const cl_pr = {
  action: 'opened',
  pull_request: {
    body: cl,
    title: 'Awesome PR',
    mergeable: false,
  },
};
const cl_label_set = await get_updated_label_set({
  github: null,
  context: { payload: cl_pr },
});
assert.ok(
  cl_label_set.includes('Merge Conflict'),
  'Merge Conflict label should be added',
);
assert.ok(cl_label_set.includes('Feature'), 'Feature label should be added');
assert.ok(
  !cl_label_set.includes('Refactor'),
  'Refactor label should not be added',
);

const title_pr = {
  action: 'opened',
  pull_request: {
    title: 'Logging is important',
    mergeable: true,
  },
};
const title_label_set = await get_updated_label_set({
  github: null,
  context: { payload: title_pr },
});
assert.ok(title_label_set.includes('Logging'), 'Logging label should be added');

// MAVERICK EDIT BEGIN - Maverick label tests
const mock_github = (files, events = []) => ({
  paginate: async (fn) => fn(),
  rest: {
    pulls: { listFiles: () => files.map((filename) => ({ filename })) },
    issues: { listEventsForTimeline: () => events },
  },
});
const run = (action, title, files, events) =>
  get_updated_label_set({
    github: mock_github(files, events),
    context: {
      repo: { owner: 'o', repo: 'r' },
      payload: {
        action,
        pull_request: {
          number: 1,
          title,
          body: '',
          diff_url: 'x',
          mergeable: true,
        },
      },
    },
  });
const tested = [
  {
    event: 'labeled',
    actor: { login: 'NanoCats' },
    label: { name: 'Testing Completed' },
  },
];

let labels = await run('opened', 'Thing', ['modular_maverick/a.dm'], tested);
assert.ok(labels.includes('Testing Completed'), 'manual label kept on open');
assert.ok(
  !labels.includes('Upstream File Edit'),
  'modular only is not an upstream edit',
);

labels = await run('synchronize', 'Thing', ['modular_maverick/a.dm'], tested);
assert.ok(
  !labels.includes('Testing Completed'),
  'cleared when commits are pushed',
);

labels = await run('opened', 'Thing', ['code/game/x.dm', 'tgstation.dme'], []);
assert.ok(labels.includes('Upstream File Edit'), 'upstream file flagged');

labels = await run(
  'opened',
  'Thing',
  ['tgstation.dme', 'maverick/upstream_vetoes.md'],
  [],
);
assert.ok(
  !labels.includes('Upstream File Edit'),
  'dme and maverick docs ignored',
);

labels = await run(
  'opened',
  'Thing',
  ['modular_skyrat/modules/colony_fabricator/code/machines/rtg.dm'],
  [],
);
assert.ok(labels.includes('Colony Gear'), 'colony gear flagged');

labels = await run('opened', '[Sync] Bubber master 2026-11-20', [], []);
assert.ok(labels.includes('Upstream Sync'), 'sync title');

labels = await run('opened', 'Port anime halos from Monke', [], []);
assert.ok(labels.includes('Port'), 'port title');
for (const t of ['Fix report console', 'Teleporter support', 'Portable fan']) {
  labels = await run('opened', t, [], []);
  assert.ok(!labels.includes('Port'), `no Port label for "${t}"`);
}
const playtest = [
  {
    event: 'labeled',
    actor: { login: 'NanoCats' },
    label: { name: 'Needs Playtest' },
  },
  ...tested,
];
labels = await run('labeled', 'Thing', ['modular_maverick/a.dm'], playtest);
assert.ok(!labels.includes('Needs Playtest'), 'tested PR drops Needs Playtest');
labels = await run('synchronize', 'Thing', ['modular_maverick/a.dm'], playtest);
assert.ok(labels.includes('Needs Playtest'), 'push brings Needs Playtest back');
assert.ok(
  !labels.includes('Testing Completed'),
  'push clears Testing Completed',
);
console.log('Maverick label tests passed');
// MAVERICK EDIT END
