# Levels

The five level blocks (21 760 bytes each at `$A800-$FCFF`, side B; level 1 also on side A) hold the same kinds of
data at the same places up to the sprites, then each its own maps, sections and kinds. `levelN/` holds level N's
resources as `src/levels/levels.ann` names them (`level/NAME`); `levelN/README.md` gives each file's address and
size. `tools/res_formats.py build` writes them back as `build/lres/levelN/res/level/NAME.bin` for
`src/levels/levelN/levelN.asm`; `tools/fig_rooms.py OUT` draws every section and each level's map from them.

The block: CellFlags `$A800` (256), CellGraphics `$A900` (2048), CellAttrs `$B100` (256), Blocks `$B200` (4096),
LevelHeader `$C200` (words: KindTable, SectionTable, the maps' base; `$C206`/`$C209` level 5's hooks `JP $F7E6` /
`JP $F8D0`, text "CORE  " / "DESIGN" in levels 1-4, never run), LevelNumber `$C20C`, SpriteFrameMap `$C20E` (95),
Sprites `$C26D` (128 bytes a sprite), the maps, SectionTable and its lists, KindTable, TrapAnims, TrapPaths,
KindRecords, then zeros (level 5: its code `$F7E6-$FB32`, src/levels/level5/fatguy.asm). The maps' last 768 bytes
(maps + `$600`) are enciphered on tape (`tools/mktape.py`) and deciphered at `$894E`: they are where level 2's
sections 10-12, level 3's 7-9 and level 4's 10-12 start (reached only with CheatExits `$8067`).

## Formats

The level texts are read back the same way: `#` starts a comment line, `;` a comment to the line's end, a token
ending in `:` is a label and a word of letters a keyword (both ignored); `NAME=VALUE` is VALUE; `$hhhh` is a
little-endian word, `>$hhhh` a big-endian word, `$hh` or a decimal a byte. The order of the lines is the order of the
bytes: a line may be edited, moved or added as long as the offsets that point at it are changed with it.

- **`cell-flags.csv`**: cell, then bits 0-7: 0 the level's special surface (level 1 weak jump, 2 ice, 3 bounce,
  4 mud, 5 launch pad; feet row only), 1 solid, 2 a floor one jumps up through, 3 ladder, 4 ladder top, 5 deadly,
  6 unused, 7 drawn in front of the sprites (the composer `$7755` leaves the cell).
- **`cells.png`**: 256 cells, 16 a row, each in its attribute's colours (a cell of one colour keeps its other colour
  in the PNG's text chunk).
- **`blocks.txt`**: `n: a b c d / e f g h / ...`, four rows of four cell numbers.
- **`maps.txt`**: `row R: b0 ... b7`, eight block numbers a row, one screen wide. A section's map starts at row
  `map / 8` (sections.txt); the screen shows its rows 2 to `limit / 4 + 7`. The height is stored nowhere, so the maps
  overlap: a section's hidden rows 0-1 are usually the previous section's last two shown rows, and in a few short
  sections (level 1 section 1, level 2 sections 3-5, level 3 section 0, level 5 section 4) the shown rows run into the
  next map. Moving a map means changing its `map` offset.
- **`sections.txt`**: the table, `section S: map=>$hhhh pad=0 limit=L exits=>$hhhh objects=>$hhhh` (big-endian
  offsets: the map from the maps' base, the lists from the table), then the lists in byte order, each after a comment
  naming its offset and section:
  - `exit flags=$ff row=R to=S arrive=A`: flags bits 0-1 the side (1 left, 2 right), 4 a level end that stays one
    under CheatExits, 5 Rick arrives riding, 6 LevelHookOn `$8A24` = 20 (the Fat Guy), 7 the level ends; R the
    section row of Rick's feet; S the section entered; A the feet row there. `end $00` (a byte with `AND $0B` = 0).
  - `object kind=$kk row=R col=$cc param=$pp`: kind below `$74` a trap or pickup (a KindTable index), `$78` / `$7C` the
    countdown bonus start / stop, other kinds from `$74` an enemy (bits 0-1 the behaviour: 0 / 3 wander, 1 patrol,
    2 chase, 3 also climbs); R the cell row; col bits 0-4 the column (x = 8 col), 5 x + 4, 6 y + 3, 7 spawn when it
    comes into view (clear: when a box fires); param bits 0-1 the boxes after it, 2-5 the trap behaviour (`$20`
    treasure, `$28` ammunition, `$2C` detonators) or the enemy's patrol, 6 one-shot. `box x=X row=R size=$sz who=$ww`:
    a trigger box (size: rows - 1 high nibble, columns - 1 low; who: bit 0 Rick, 1 the bullet, 2 the blast, 3 the
    punch, 4 an enemy, 5 a trap, 6 every pass). `end 0`.
  - The comment after each line decodes it. The section count is SectionCounts `$8374` (tables/section-counts.csv);
    the entries after it are fillers whose lists may point past the file (into KindTable).
- **`kinds.txt`**: `[kinds.bin]` the table, `kind K: $hhhh` (the record's address; kind 0 unused); `[anims.bin]` the
  animation scripts (`N` a frame for a pass, `N+K` frame N for K more passes, `fx=N` an effect, `jump=$hhhh`);
  `[paths.bin]` the path scripts (`C*(dx,dy)` C passes of the step, dx and dy signed nibbles in pixels, 7 = 8,
  `fx=N`, `jump=$hhhh`); `[kinds-2.bin]` the records, `record $hhhh: width height flags path anim [path2 anim2]`
  (flags bit 6 deadly, 7 the detonator test, bits 0-5 the behaviour after the switch). A kind that never switches
  has a 7-byte record; the next record starts there. Every script line starts with its address; jumps are absolute,
  so a script that moves needs its jumps and the records that point to it changed. The four blocks follow each other
  in memory in this order.
- **`frame-map.csv`**: frame (1-95), sprite, mirrored; sprite 127 = none. A frame of an animation shows that sprite.
- **`sprites.png`**: the sprites, 8 a row, 24 x 21 each; index 0 paper (mask 0, data 0), 1 ink (mask 0, data 1), 3
  transparent (mask 1, data 0), 4 red = ink over a transparent pixel (mask 1, data 1). The two head bytes (line
  offset, rows) are in the PNG text chunk. Sprites 0-26 are the same in every level: 0-16 Rick, 17 the bullet, 18-19
  the detonator, 20-24 the blast, 25 ammunition, 26 detonators; 27 the treasure, 28-39 the enemies, then the traps
  (level 5: 40-45 the Fat Guy, 62 his shot).
- **`fat-guy.txt`** (level 5): `[parts]` five parts, `w h sprite path anim` (parts 1-4: w and h are the offset from
  the body), then `[paths]` and `[anims]` in the path and animation tokens. **`fat-guy-path.txt`**: the path he
  walks while alive.

## Leftovers kept as bytes in the source

Bytes no code reads stay in `src/levels/levelN/*.asm` as named `b` / `s` entries, not resources: level 1 six `$01`
at `$EA66`, level 3 eight `$01` at `$EB0D`, level 4 16 map-like bytes at `$EABD` and a `$01` at `$EAE8`, level 5 317
bytes of older data at `$E88D-$E9C9` and `$E9ED-$ECEC` (byte for byte level 4's block there: level 5 was laid over a
level 4 image), the scripts no record points to (level 2 `$F561`, `$F759`; level 4 `$F31E`, `$F3C0`, `$F53A`,
`$F5A7`, `$F7B3`, `$F846`; level 5 `$F26A`, `$F304`: they are in kinds.txt, labelled by address with no record
naming them), and the zeros after the data.
