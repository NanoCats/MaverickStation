# MaverickStation: notes for Claude

MaverickStation is the personal SS13 fork of commander Aeri. Upstream chain: /tg/station -> Skyrat -> Bubberstation -> MaverickStation. Aeri is the de-facto owner and operator. Claude is responsible for many aspects of implementation.

## Who decides what

- Aeri makes design decisions. When a choice comes up that she has not decided, stop and ask her. Do not guess.
- Claude may create branches, push to feature branches, open PRs, and file, label and comment on issues in this repo.
- Aeri must sign off before any of these: merging a PR, force pushing, deleting branches, changing repo settings or rulesets, or anything that deploys.
- Never write to the Bubberstation repo or any other upstream. Read only.

## Code rules

- New code, icons and sounds go in `modular_maverick/`, mirroring the layout of `modular_zubbers/`.
- To the extent possible, override and inject in favor of editing. We should predominantly alter upstream behavior with var overrides, proc overrides that call `..()`, signals, and roundstart injection. Map file edits should be avoided, because upstream syncs overwrite them. It is still possible to edit them via the automapper, however it requires enhanced effort.
- If an upstream file must be edited, keep the edit small and wrap it:
  `// MAVERICK EDIT BEGIN - <reason>` ... `// MAVERICK EDIT END`
  For a one-line change, use `// MAVERICK EDIT - <reason>` at the end of the line.
- Files in `modular_maverick/` must be added to `tgstation.dme` like any other modular file.
- No player-facing mention of Bubberstation. Keep the license files, copyright notices and asset credits.

## Upstream sync

- Sync from Bubberstation `master` by hand, at most weekly.
- List every upstream PR in the sync PR with a short summary. Flag PRs that touch areas leadership cares about.
- Check `maverick/upstream_vetoes.md` before the sync. Revert vetoed PRs. Flag later PRs that depend on a vetoed one.

## Writing style

- Keep Claude out of the public record. No `Co-Authored-By` or session trailers in commits, and no "Generated with Claude" footers in PRs or issues.
- Commit without signing (`-c commit.gpgsign=false`), as `Aeri <14065903+NanoCats@users.noreply.github.com>`.

- Never use em dashes in anything you write: code comments, PR bodies, issues, docs or chat.
- Keep commit messages short and descriptive.
- Every PR with player-facing changes gets a `:cl:` changelog block in its body, even while the changelog workflows are off.

## Testing

- CI compiles the game and runs the unit tests on every PR. A green check does not mean a feature plays right.
- Label PRs with visual or gameplay changes `needs-playtest`. Leadership tests those on her local server before hitting GO on merge. 
