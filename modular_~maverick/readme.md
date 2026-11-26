# modular_~maverick

MaverickStation code and assets live here, apart from the upstream code, so upstream merges stay simple. The `~` makes this folder sort and compile after TG, Skyrat and Bubber code, so our overrides win.

## Folder layout

Put files on the same path they would have in /tg/, with `modular_~maverick/` in front.

- Code goes in `modular_~maverick/code/`. Example: a new item goes in `modular_~maverick/code/game/objects/items/`. A feature with no clear /tg/ home gets its own folder in `modular_~maverick/code/modules/<feature>/`.
- Icons go in `modular_~maverick/icons/`, sounds in `modular_~maverick/sound/`, and HTML in `modular_~maverick/html/`.
- Do not use the old `modules/<feature>/code` layout. It is the Skyrat layout that upstream is removing.
- Keep the include lines in `tgstation.dme` in alphabetical order.

## Defines

Defines go in `code/__DEFINES/~~~maverick_defines/`, not in this folder. They have to load with the other defines, before any upstream code that uses them. One file per feature. A define that only one file uses goes at the top of that file and is `#undef`'d at the bottom instead.

## Config entries

- Define config entries in `modular_~maverick/code/controllers/configuration/entries/`, or next to the feature that uses them.
- Start every entry name with `maverick_`, for example `/datum/config_entry/flag/maverick_lobby_desktop`. This stops clashes with upstream entries.
- Add a matching line to `config/maverick/maverick_config.txt`, with a short note on what it does.

## Upstream features

Switch upstream features off with a config entry, a define or an early return. Do not delete them, so they can come back later.

Prefer overrides to edits: var overrides, proc overrides that call `..()`, signals and roundstart injection. If an upstream file must be edited, keep the edit small and mark it:

- Several lines: `// MAVERICK EDIT BEGIN - <reason>` and `// MAVERICK EDIT END` around the change.
- One line: `// MAVERICK EDIT - <reason>` at the end of the line.

Upstream PRs that MaverickStation rejects are listed in `maverick/upstream_vetoes.md`.
