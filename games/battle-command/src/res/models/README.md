# 3D models

The models are scripts of RunScript `$990F` (src/game/render.asm), kept as bytes where the game keeps them: in each
mission block (../missions, the `bytes` lines from the header's `models` word on) and in the bank parts (bank 3
SharedModels `$CA8B-$CFCC`; smaller ones in bank 0 `$D5D0`, `$D934`, `$FE80`, bank 2 `$8739-$87D5`, bank 5
`$7E8F-$7FAF`, bank 6 `$E512-$E560`). The files here are views of them, written by `python3 tools/fig_models.py`:

- `NN-NAME.txt`: every model inside the block that a template of mission NN uses (the template's word at +26; the words `$67DC`, `$B612` and 0 point at resident code or no model), its script decoded
  instruction by instruction (tools/models3d.py; the opcodes are in its docstring);
- `NN-NAME.png`: each of those models drawn from the front and above with the heading 0;
- `bank3-shared.txt` / `.png`: bank 3's library.

The figures rebuild the corners with the box generators' formulas (BoxSquare `$AA63`, BoxRect `$AB7B`, BoxRect16
`$AAF5` with 64 times the radius, BoxTilted `$ABFF` drawn untilted), run the vertex program, then fill every face
and draw every line, all parts of a model at once and back to front for this one view (the game draws only the
faces its winding test shows). Colours are the scripts' colour numbers, not the Spectrum's. A model that is a
routine of the mission's code, a sub-part called by another model (bank 3 `$CDF8`) or an empty polar-point model
draws nothing.

Mission 2's library is broken from `$E964` on (the Ocean tape's damaged block, ../missions/README.md): its listing
marks the 19 broken models and the figure leaves them out.

| Library | Models | From |
| --- | --- | --- |
| 01-blast-em-mission | 28 | `$EC57` |
| 02-missile-battery | 21 (19 broken) | `$E80B` |
| 03-hostage-rescue | 24 | `$E994` |
| 04-railway-ambush | 15 | `$E93F` |
| 05-night-moves | 25 | `$EB06` |
| 06-escort-duty | 23 | `$EC77` |
| 07-satellite-search | 28 | `$EA73` |
| 08-river-raid | 21 | `$E9A3` |
| 09-hideout | 25 | `$E8C4` |
| 10-grand-finale | 23 | `$EB09` |
| bank3-shared | 4 (with their parts) | `$CA8B` |
