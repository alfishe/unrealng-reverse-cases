# Stage 2's resources

The editable data of stage 2's block (TZX block 43, `$6C3F`-`$F03E`), one file a data entry of
`src/stage2/stage2.ann` (`@res`). `tools/res_formats.py` turns each into its bytes with the formats of
`tools/res_stage.py` (its docstring has the formats in full) and, for `map.txt`, `tools/res_stage2.py`;
`tools/build.sh` assembles them with INCBIN and checks the tape against the original. `python3 tools/res_formats.py
check` proves every file comes back unchanged through its bytes.

Formats in short:

- `sprites-NAME.png`: a sprite set: the frames in a row (0 paper, 1 ink, grey the boxes); the frame table (dx, dy,
  the bitmap's offset) in the PNG's text chunk `tx-frames`. Bytes no frame covers are kept there too.
- `bitmaps-NAME-WxH.png`: frames of W bytes x H lines one after another, no table; bytes past the last whole frame
  are kept in `tx-frames` (`rest`).
- `picture-NAME-WxH.png`: a linear picture (H lines of W bytes) and its attributes (W x H / 8), in colour.
- `rowpicture-NAME.png`: a row-packed picture (each line a byte LEN x 16 + SKIP, then LEN bytes); the lines' SKIP and
  LEN in `tx-rows`.
- `graphics.txt` + `tiles.png`: the RLE-packed tiles, blocks and map (see below).
- `map.txt`: the grid records, room tables and placement lists. Stage 2 stores them records first (three grid
  records, then the three room tables, then the placement lists), not interleaved as stage 1's `rooms.txt`; the
  format is `tools/res_stage2.py`'s: `base`, three `grid W H COLUMN ROW ROOMS MAP STEP` lines, a `rooms` line per
  grid row of rooms, then the `placements` sections (`KIND X Y`, `done` for bit 7, `end`).
- `table-NAME.csv`: rows of fixed columns (`res_stage.TABLES`).

| File | Address | Bytes | What | Read by |
|------|---------|-------|------|---------|
| `picture-hud-32x48.png` | `$7000`-`$76BF` | 1728 | the HUD as loaded (the same bytes as stage 1's): 48 lines x 32 bytes, then 6 rows of colours; in play the space holds the stage's records (`variables` module) | DissolveHud `$8AD6`, StageSetUp `$9177`; saved back by EndStage `$789D` |
| `table-startitems.csv` | `$7EF4` | 12 | the item kind of each of the 12 carried slots at the stage's start (item 3 at slot 6, item 1 at slot 7) | InitStageState `$9773` |
| `table-itemicons.csv` | `$7F00` | 16 | the icon of each item kind 0-7 (words; kind 4 the blank `$8BCA`) | DrawItemIcon `$7DEC` |
| `map.txt` | `$953E`-`$9606` | 201 | 3 grid records (Grid0 `$953E` 69 x 9, Grid1 `$9547` 47 x 15, Grid2 `$9550` 14 x 9), their room tables (`$9559`, `$955F`, `$9567`), 3 placement lists (`$9568` 18, `$95A1` 30, `$95FE` 2) | StageEntry, EnterGrid1 / 2, LeaveGrid1 / 2, RoomCells `$92F4`, StartGrid `$A35D`, LoadRoomActors `$A431` |
| `table-kinds.csv` | `$9607` | 189 | the 21 placement kinds: Y offset, handler, record bytes +8..+`$0C`, +`$0F` | LoadRoomActors `$A499` |
| `table-actor-templates.csv` | `$96C4` | 162 | 9 whole actor records: hero, spirit, harpy's wings, harpy, item, extra life, sparkle, piece, fragment | SpawnActor `$A416` and its callers |
| `table-burst-steps.csv` | `$9D9A` | 40 | 20 (dx, dy) particle steps | UpdateBurst `$9D06` |
| `graphics.txt`, `tiles.png` | `$B7D5`-`$C3D4` | 3072 | RLE-packed (escape `$C9`): 195 tiles (kinds, pixels, colours), 110 blocks of 2 x 2 tiles, the map of the three grids (1452 bytes) | Unrle `$A33D` from RoomChange `$9257` |
| `sprites-spirit.png` | `$C3D5` | 507 | the spirit, 8 frames | SpiritActor `$9028` (SpiritFrameSet `$9050`) |
| `bitmaps-shot-small-2x5.png`, `bitmaps-shot-upright-1x15.png`, `bitmaps-shot-slanted-2x13.png` | `$C5D0`-`$C62B` | 92 | the spirits' shots by direction (the upright pair never read in the recordings) | ShotFrames `$82CD` |
| `bitmaps-ripple-4x2.png` | `$C62C` | 24 | the pool's ripple, 3 frames | WaterActor `$8782` |
| `bitmaps-game-over-8x8.png` | `$C644` | 64 | GAME OVER | GameOverStep `$8585` |
| `bitmaps-hydra-neck-2x8.png` | `$C684` | 128 | a neck segment shifted 0-7 pixels | OrNeckSegment `$A066` (DrawNeckHighLoop `$9FEC`, DrawNeckLow `$A0DB`) |
| `sprites-strikeable.png` | `$C704` | 250 | the urns (kinds 16-19), 8 frames | StrikeableActor `$A9B8` (StrikeableSet `$A9F1`) |
| `sprites-hero-strike.png` | `$C7FE` | 767 | the hero's strikes, 11 frames | HeroStrikeLowSet `$AF82`, HeroStrikeMidSet `$AFC4`, HeroStrikeHighSet `$B000` |
| `bitmaps-energy-bar-6x1.png` | `$CAFD` | 6 | the energy bar's pattern | DrawEnergyBar `$9DC2` |
| `sprites-hero-jump.png` | `$CB03` | 1067 | the hero's jump, 19 frames | HeroJumpSet `$B1F3` |
| `sprites-hero-walk.png` | `$CF2E` | 792 | the hero's walk and stand, 13 frames | HeroWalkSet `$B0DE`, HeroStandSet `$AEDD` |
| `bitmaps-fragment-3x11.png` | `$D264` | 264 | a statue's fragment, shifted 0-7 pixels | MoveFragment `$ABA2` |
| `sprites-medusa.png` | `$D36C` | 401 | Medusa and her head, 7 frames | MedusaSetFrame `$81C8` (MedusaFrameSet `$81CB`) |
| `bitmaps-spin-shot-1x12.png` | `$D4FD` | 132 | a spinning shot, 11 frames (Medusa's head's shot and item 6's missile) | DrawFloorShot `$B5C6`, DrawHeroMissile `$B5E3` |
| `bitmaps-hydra-head-3x22.png` | `$D581` | 198 | a hydra head, 3 frames by pose | PlaceHydraHead `$8100` |
| `bitmaps-harpy-4x28.png` | `$D647` | 336 | the harpy's body, 3 frames | HarpyAttackFrames `$8EBF`, HarpyTemplate |
| `sprites-harpy-wings.png` | `$D797` | 464 | the harpy's wings, 5 frames | HarpyWingsActor `$8DD2` (HarpyWingsFrameSet `$8DE4`) |
| `rowpicture-hydra.png` | `$D967` | 986 | the hydra's body, 112 lines | DrawHydraBody `$9E21` with DrawRowPicture `$8B2A` |
| `sprites-piece.png` | `$DD41` | 292 | a piece of the artefact, 10 frames (the first two also the HUD's) | UpdatePieceActor `$842E` (PieceFrames `$846E`), ShowPieceTaken |
| `bitmaps-item-icons-2x16.png` | `$DE65` | 224 | 7 item icons (kinds 0, 1, 3, 6, 2, 5, 7 in memory order) | ItemIcons `$7F00`, SpawnItem callers |
| `sprites-statue.png` | `$DF45` | 375 | the statues, 4 frames | KneelingStatueActor `$A6EC`, WarriorStatueActor `$A718` (StatueSet `$A714`) |
| `sprites-harpy-rise.png` | `$E0BC` | 365 | the harpy rising, 4 frames | HarpyRiseActor `$A7F6` (HarpyRiseSet `$A879`) |
| `sprites-harpy-lamp.png` | `$E229` | 938 | the lamp, its flame and the extra life, 22 frames | HarpyLampActor `$A7E2`, HarpyFlameActor `$A760`, ExtraLifeActor `$9AFA` (HarpyLampSet `$A7F2`) |
| `sprites-sparkle.png` | `$E5D3` | 73 | the sparkle of a life taken, 6 frames | SparkleActor `$9B4F` (SparkleSet `$9B5D`) |
| `sprites-pool.png` | `$E61C` | 636 | the pool's surface, 18 frames | PoolActor `$ABF2` (PoolSet `$AC34`) |
| `bitmaps-drift-shots-3x13.png` | `$E898` | 156 | the drifting shots, 4 frames | ImageDescriptors `$B6DD` 0-3, UpdateDriftLeft `$B639` |
| `bitmaps-drift-fade-3x8.png` | `$E934` | 120 | a drifting shot fading, 5 frames | ImageDescriptors 4-8 |
| `sprites-hero-leap.png` | `$E9AC` | 826 | the hero's leaps, 14 frames | HeroLeapSet `$B230` |
| `sprites-drop.png` | `$ECE6` | 193 | the drop, 13 frames | DropActor `$A929` (DropSet `$A990`) |
| `bitmaps-particles-1x8.png` | `$EDA7` | 32 | the burst's 4 particle glyphs | UpdateBurst `$9C92` |
| `table-burst-glyphs.csv` | `$EDC7` | 35 | the glyph of each burst step | UpdateBurst |
| `table-burst-directions.csv` | `$EDEA` | 192 | 6 directions x 32 steps, indices into BurstSteps | UpdateBurst |
| `bitmaps-burst-shapes-2x12.png` | `$EEAA` | 104 | the burst shapes: StartBurst `$9BFA` reads 24 bytes from `$EEAA`, `$EEB8`, `$EECA`, `$EEE2`, `$EEEE` or `$EEFA` (overlapping); the PNG shows 4 frames of 24 bytes from `$EEAA` and keeps the last 8 bytes in `rest` | StartBurst's callers |

**graphics.txt.** The packer is greedy (every run of 4 to 255 equal bytes becomes `ESC n v`) and keeps one stretch
the original left unpacked (`literal 1397 8`, a blank tile's pixels); with it the block packs again bit for bit. A
changed map or tile set is packed the same way; the escape byte must not occur in the data. The grids' sizes for the
map section are `GRIDS['stage2']` in `tools/res_stage.py` (69 x 9, 47 x 15, 14 x 9), the same as the grid records in
`map.txt`.

**Not resources.** The bytes no code reads stay in the listing as data with a note: `$D246`-`$D263` (30 bytes after
the walk set, GraphicsLeftover), `$EF12`-`$F03E` (301 zeros, BlockEnd), `$77BA`-`$77FF` (70 zeros), and the work
space `$6C3F`-`$6FFF`, `$76C0`-`$77B9` (zeros as loaded). The small tables in the code (CarriedItems `$7EDC`,
CarriedCounts `$7EE8`, the frame-set words, ImageDescriptors `$B6DD`, DriftFallSteps `$B701`, DriftColours `$B4F0`)
are shaped data in the listing, not files.

The figures `docs/img/maps/stage2.png` (the three grids with every placement) and `docs/img/maps/stage2-rooms.png`
(each room) are drawn from these files by `python3 tools/fig_rooms.py stage2` (see `work/stage2/notes-stage2.md`
for how `map.txt` is fed to it).
