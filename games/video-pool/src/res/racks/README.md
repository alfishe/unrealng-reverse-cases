# Racks

The rack-in scripts as text (`tools/res_formats.py`, section "The rack-in scripts"): how the six object balls roll
into the rack before each frame.

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `RackScripts.txt` | `$A0C4-$A701` | 1598 | text: `org`, `sets`, one set a line, one script command a line (`wait N`, `place X Y`, `move N DX DY`, `end`); `#` lines are comments | RackBalls `$9F6F` (the set by `$9F83`: RackSets[((frame - 1) / 2) mod 6]), RackStep `$A05E` (one command step a frame for each ball) | RackSets `$A0C4` (6 words), then the six sets in turn: six words (the scripts of balls 1-6) and the six scripts. Set 0 `$A0D0` (frames 1-2), set 1 `$A162`, set 2 `$A1E4`, set 3 `$A29C`, set 4 `$A38E`, set 5 `$A4F8`; 36 scripts, each ending with a `place` on its ball's rack position and `end` |

The bytes: `wait N` = 3 N, `place X Y` = 1 X Y, `move N DX DY` = 2 N DX DY (DX, DY signed bytes, added on each of
the next N frames), `end` = 0. The set table and the sets are absolute pointers: the build lays the items out from
`org $A0C4` in the order of the file and writes each label's address, so a script may grow or shrink, but the labels
of `src/game/racking.asm` and `rackscripts.asm` (RackScripts0, Rack1Ball1, ...) cut the INCBIN at the original
offsets: a change of length moves the bytes under them (rebuild the .ann's entries, or keep the lengths).

The maps of the six sets, drawn from this file, are in `../maps`.
