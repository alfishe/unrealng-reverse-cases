# <Case>: doc 13, the differences from <base>

R = the repository, C = R/games/<case>, B = R/games/<base>. Written only after the full reverse of both: the
comparison is computed from the two complete sources, never from patches. R/recipes/10-derived-case.md step 8 is
the procedure.

## Before writing

- Both build identical: `B/tools/build.sh`, `C/tools/build.sh` (the diff tools read the builds).
- The diff tools of the case (copy the nearest sibling's into C/tools/ and adapt): an image and listing diff
  (same / differ / only-in, address by address), an entry diff with label operands masked (same / operands / moved /
  changed / retargeted / only-in), a resource diff per section, one routine aligned on both sides, and the byte map
  of the classes for `docs/img/diff/`.
- The agents' C/work/docs/<id>-diff-notes.md: each note checked against the diff. A difference B shares is not a
  difference (zynaps-gs's draft took the level shuffle for the conversion's own; the 48K has the same shuffle).

## The document

`C/docs/13-differences-from-<base>.md`:

1. A "How compared" list naming each tool, then: "The figures are in `docs/img/diff/` and `docs/img/compare/`.
   Every command is run from this case's root."
2. A summary table (the diff tool's `--summary`), then one section per subsystem: what changed, where (addresses on
   both sides, the entry names), why it matters to a player, each with its witness command (`--show PlayLoop`,
   `--section strings`).
3. The screenshots side by side (`docs/img/compare/`) and the texts (`docs/texts/`).
4. A tools section and a figure table (`| file | section | command |`).

Hex in code spans; figures by [figures.md](figures.md). `python3 R/kit/check_docs.py --case C` prints "docs: ok".
