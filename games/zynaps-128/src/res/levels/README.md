# The level data

`levels.lev.txt` is the game's level data, `$6800-$7E59` (5722 bytes), as text. `tools/res_levels.py` turns it into
the bytes (`build/res/levels/levels.bin`, INCBIN in `leveldata.asm`) and back; every byte is decoded, the round trip
is exact.

The file is a list of sections. Each starts at the address the code reads it from and has to end where the next one
starts (the encoder refuses anything else). Inside a section `name:` is a label (an entry point the tables name) and
the lines decode the bytes in address order. A byte that is no whole item before the next label, or whose item would
not encode back the same, is written `db $xx` (in this data: `shape30` and `shape31`, two stray bytes in front of shape
32). Numbers are decimal, `$` marks hex; `#` starts a comment.

| Section | Address | Read by | Contents |
| --- | --- | --- | --- |
| `path-starts` | `$6800` | LaunchWave `$9324` | 28 path labels; the byte is (label - `$681C`) / 2, so a path starts on an even offset |
| `paths` | `$681C` | RunPath `$94CB` | the path bytecode |
| `wave-index` | `$6926` | LaunchWave `$921A` | 29 wave labels; the byte is (label - `$6943`) / 2 |
| `waves` | `$6943` | LaunchWave `$921F` | the wave definitions, one a line |
| `kinds` | `$6A65` | LaunchWave `$9261` | 22 enemy kinds of 8 bytes |
| `kind-colours` | `$6B15` | LaunchWave `$927E` | 8 colour sets of 3 bytes |
| `levels` | `$6B2D` | LevelStart `$B062` | 12 level records |
| `scripts` | `$6B8D` | ScriptStep `$AD66` | the level scripts |
| `patterns` | `$72A9` | ScriptSetCell `$8EC5` | 7 colour patterns of 8 attributes |
| `scenery-scripts` | `$72E1` | RunScript `$8D7A` | a table of 39 labels, then the scenery scripts |
| `groups` | `$749A` | DrawGroup `$8DCA` | a table of 61 labels, then the object groups |
| `shapes` | `$7783` | DrawGroup `$8E15`, PlaceColumn `$8EA1` | a table of 79 labels, then the shapes |

## Paths

An enemy runs its path one command a frame (RunPath, record `+$1D/+$1E` the pointer, `+$1C` the command, `+$1B` the
frames left). Tokens, comma-separated:

- `*N`: the byte `$80 + N`: the next command runs N frames (0: for ever).
- `accel+x-x+y-y`: command 0 with its flags (bits 3-6): add (`+`) or subtract (`-`) the kind's acceleration to the X or
  Y speed, then move. `accel` alone only moves.
- `setloop P`, `interval P`, `bounce P`, `homeplayer P`, `direction P`, `hometarget P`: commands 1-6 with the
  parameter P (0-15) in bits 3-6 (`direction P`: the direction P * 4 of 64, then move).
- `scroll stop randomdir driftmiddle aimplayer scrollalways move home tocentre land randomspeed bouncearena dive
  movefragile wait`: command 7, the extended ops 0-2 and 4-15 of PathExtOps `$8124`.
- `loop LABEL`: extended op 3 with its word: back to LABEL while the loop counter (`setloop`) counts down.

## Waves

A script's `wave N` launches the definition WaveIndex[N] names:

    bonus $40 kind 3 [path N [skip M]] gap G : x,y x,y ...

`bonus` is the wave record's bonus byte (bits 6-7 the pod drop, bits 0-5 the bonus score), `kind` the enemy kind,
`path` a path number for all its enemies (without it each takes the path of its kind's number; in the data the byte
after it, `skip`, repeats the path number and is not read), `gap` the frames between two enemies. Then one `x,y` per
enemy: X is halved and added to `$C0` (the right edge), Y to the script's row offset; `?` is `$FF`, a random row.

## Kinds and colours

`kind N: b0 .. b7` is copied into the wave template `$803E`: b0 to `+$18`; b1 the colour select (with
WeaponRatingLevel `$80E9`: the set ((`$80E9` + b1) & `$1C`) / 4 of `kind-colours`; b1 & `$E3` to `+$21`); b2's low
nibble to `+$0C` (the score), high nibble to `+$17` (the speed); b3 to `+$10` (X acceleration); b4 to `+$14`
(Y acceleration); b5 to `+$07` (the handler kind, KindHandlers `$80FA`); b6 to `+$25` (the colour); b7 to `+$0D`
(the hit points, `$FF` invulnerable). `colours N: c0 c1 c2` go to `+$19`, `+$20`, `+$22`.

## Levels

    level 0: byte $00 script level0 flags $FF scroll $0040 scenery 1 speed 0

copied to ScriptState `$81D7-$81DE` (through the player record's `+$0D`): the unused byte, the script's start, PlayFlags
`$81DA` (bit 5 the scroll, bit 7 the stars), ScrollCount `$81DB`, the scenery script ScriptNumber `$81DD`, and
ScriptLevelBias `$81DE` (added to the weapon rating `$80E8`: the later levels' enemies fire more often). The game plays the records in
LevelOrder (`$8003`): 0, 1, 2, then 3-8 shuffled for each game, then 9, 10, 11.

## Level scripts

A line is a step: the frames to wait (ScriptWaitCount `$81E1` counts up to it), then the command.

- `nop`, `scrollresume` (op 1: the scroll starts again at the next phase 4), `scrolloff`, `starson`, `starsoff`,
  `levelend` (op 5: the scroll stops, EndPending = 2, the side weapon lost), `nop6`, `return` (op 13), `save` (op 14:
  the state back into the player record, a checkpoint), `clearrows` (op 15: the 18 row records reset to empty span
  lists, CmdResetRecords `$AEE3`), `escapefirst` (op 16: the first enemy record, when active, escapes and its slot is
  freed: `$994A`, `$992A`), `anyenemies` (op 17: NZ while one of the five enemy records is active and not dying).
- `poke ADDR VALUE`, `copy DST SRC`, `dec ADDR`, `inc ADDR`, `test ADDR`, `add ADDR VALUE` (ops 7-12, words; the flags
  of `dec`, `inc`, `test`, `add` go to ScriptFlags `$81E2`). The scripts only count with `$81E4` (ScriptCounter).
- `jp [cond] LABEL`, `call [cond] LABEL`: cond one of `z nz c nc p m`, none = always (ScriptConditions `$8223`). A call
  pushes onto the script's stack (`$81DF`); no script calls.
- `wave N y Y`: launch wave N with the row offset Y.
- `op N`: an op without a name (none in this data).

All twelve scripts end with `6 levelend` and `255 nop`.

## Scenery

`pattern N` (`$C0+N`) copies colour pattern N to WorkCell `$FFD8`; `mask $X0` (`$E0+X`) sets the variant mask
ScriptVariant `$8021`; `group N` places object group N into the map ring and waits for 16 columns of scroll; `call N`
(`$80 N`) runs scenery script N and restores the variant mask; `end` (`$FF`) ends a script (the level's own script
starts again).

A group is a list of objects and an `end`:

    put shape 37 row 10 col 1 mask $F0 [hflip] [vflip]

byte 0: the row (bits 0-4), bit 6 `hflip` (the shape mirrored left to right), bit 5 `vflip` (drawn bottom up); byte 1:
`mask` (the high nibble, AND the variant mask: 0 skips the object) and `col` (the low nibble, the column in the 16);
byte 2: the shape. `sub $8x group N` is a sub-group taken when (`$8x` << 1) meets the variant mask (none in the data).

A shape is `rows N` and N rows. A row is its attribute and eight cells:

    p2  | .. 3B 1D 2C 2D 3B 1B 26

the attribute is `$xx` (an even byte: that attribute) or `pK` (the byte `$B1 + 2K`: WorkCell byte K, the pattern's
colour); a cell is a tile number (the tiles at `$5C00`) or `..` (the cell left as it is). The cells are the bits of
the row's mask byte from bit 7.

Groups 59 and 60 point at the shape table and are used only by scenery script 15, which no level runs; shapes 30 and
31 point at two bytes in front of shape 32 and no group uses them.
