# MaverickStation: notes for Claude

MaverickStation is Aeri's personal SS13 fork. Upstream chain: /tg/station -> Skyrat -> Bubberstation -> MaverickStation. Aeri is the only maintainer. Claude does most of the implementation.

## Who decides what

- Aeri makes design decisions. When a choice comes up that she has not decided, stop and ask her. Do not guess.
- Claude may create branches, push to feature branches, open PRs, and file, label and comment on issues in this repo.
- Aeri must sign off before any of these: merging a PR, force pushing, deleting branches, changing repo settings or rulesets, or anything that deploys.
- Never write to the Bubberstation repo or any other upstream. Read only.

## Code rules

- New code, icons and sounds go in `modular_maverick/`, mirroring the layout of `modular_zubbers/`.
- Override and inject, do not edit. Change upstream behavior with var overrides, proc overrides that call `..()`, signals, and roundstart injection. Map files are never edited, because upstream syncs overwrite them.
- If an upstream file must be edited, keep the edit small and wrap it:
  `// MAVERICK EDIT BEGIN - <reason>` ... `// MAVERICK EDIT END`
  For a one-line change, use `// MAVERICK EDIT - <reason>` at the end of the line.
- Files in `modular_maverick/` must be added to `tgstation.dme` like any other modular file.
- No player-facing mention of Bubberstation. Keep the license files, copyright notices and asset credits.

## Upstream sync

- Sync from Bubberstation `master` by hand, at most weekly.
- List every upstream PR in the sync PR with a short summary. Flag PRs that touch areas Aeri cares about.
- Check `maverick/upstream_vetoes.md` before the sync. Revert vetoed PRs. Flag later PRs that depend on a vetoed one.

## Writing style

- Keep Claude out of the public record. No `Co-Authored-By` or session trailers in commits, and no "Generated with Claude" footers in PRs or issues.
- Commit without signing (`-c commit.gpgsign=false`), as `Aeri <14065903+NanoCats@users.noreply.github.com>`.

- Never use em dashes in anything you write: code comments, PR bodies, issues, docs or chat.
- Prose for Aeri (PR bodies, issues, docs) uses short, plain, direct sentences.
- Keep commit messages short and descriptive.

## Testing

- CI compiles the game and runs the unit tests on every PR. A green check does not mean a feature plays right.
- Label PRs with visual or gameplay changes `needs-playtest`. Aeri tests those on her local server before she merges.
