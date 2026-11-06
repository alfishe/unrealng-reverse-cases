# Figure rule: every figure must explain itself

Every docs brief cites this rule; as a brief of its own it is a figure audit of the documents assigned to you.
Open every figure (read the PNG; a GIF shows a frame) and judge it as a reader who knows the ZX Spectrum but not
this game. The owner on the first kit charts: "a pile of vague lines: why? what do they illustrate?"

## A figure passes when

1. **Its point is on it.** A title that says what to see ("the copy crosses the beam at line 110: the tear"), not
   what tool drew it.
2. **Every mark is named on the figure.** Lines, colours, dots, boxes: a label or an arrow at the mark, or a legend
   in plain words. A legend of a dozen routine names is not an explanation: group them by meaning or drop the ones
   that do not matter to the point.
3. **The numbers that make the point are on it** (the tear line, a count, a time), and they agree with the text.
4. **It is readable at the width GitHub shows** (about 900 px): no stacked slivers, no text over text, no cut title.
5. **The text next to it says how to read it** when the chart is not obvious (the axes, what one mark means), in a
   short list, with the claim the figure proves and the command that drew it.
6. **It earns its place.** If a neighbour says it better, drop it (the file and the reference) or merge them.

## Model

`R/games/nether-earth/docs/img/beam-turn.png` (doc 04 4.5, with its "How to read the figure" list) and
`R/games/nether-earth/docs/img/render/tear-beam.png`, drawn by `R/games/nether-earth/tools/fig_beam_turn.py`.

## How to fix

- Redraw in a case script `C/tools/fig_*.py` (copy a kit or sibling script and adapt; never edit R/kit). Data from
  the cached traces and recordings under `work/`; most figures need no emulator. If one does: your own instance on
  your port base, muted, stopped when done.
- Images in `C/docs/img/<topic>/`; every one linked from a document (`check_docs.py` fails on an unlinked one).
- Update the caption command; keep the text's numbers consistent with the figure, and say in the report what the
  redraw corrected.
- Only your documents and their images; an image another document uses gets a new file instead of a change.
- Never edit src/, the `.ann`, R/kit. No commits.

`python3 R/kit/check_docs.py --case C` prints "docs: ok". Report: per document, figures kept / redrawn / dropped,
text corrections with the reason.
