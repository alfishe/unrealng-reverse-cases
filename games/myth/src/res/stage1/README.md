# Stage 1's resources

The editable data of stage 1's block (TZX block 40, `$6C3F`-`$F03E`), one file a data entry of
`src/stage1/stage1.ann` (`@res`). `tools/res_formats.py` turns each into its bytes with the formats of
`tools/res_stage.py` (its docstring has the formats in full); `tools/build.sh` assembles them with INCBIN and checks
the tape against the original. `python3 tools/res_formats.py check` proves every file comes back unchanged through
its bytes. The other stages use the same formats in their own folders.

Formats in short:

- `sprites-NAME.png`: a sprite set: the frames in a row (0 paper, 1 ink, grey the boxes); the frame table (dx, dy,
  the bitmap's offset) in the PNG's text chunk `tx-frames`. Bytes no frame covers are kept there too.
- `bitmaps-NAME-WxH.png`: frames of W bytes x H lines one after another, no table.
- `picture-NAME-WxH.png`: a linear picture (H lines of W bytes) and its attributes (W x H / 8), in colour.
- `rowpicture-NAME.png`: a row-packed picture (each line a byte LEN x 16 + SKIP, then LEN bytes); grey where a line
  has no bytes; the lines' SKIP and LEN in `tx-rows`.
- `graphics.txt` + `tiles.png`: the RLE-packed tiles, blocks and map (see below).
- `rooms.txt`: the grid records, room tables and placement lists.
- `table-NAME.csv`: rows of fixed columns (`res_stage.TABLES`).

| File | Address | Bytes | What | Read by |
|------|---------|-------|------|---------|
| `picture-hud-32x48.png` | `$7000`-`$76BF` | 1728 | the HUD as loaded: 48 lines x 32 bytes, then 6 rows of colours; in play the space holds the stage's records (`variables.asm`) | DissolveHud `$8AB1`, StageSetUp `$97AC`; saved back by EndStage `$789E` |
| `table-startitems.csv` | `$7F2F` | 12 | the item kind of each of the 12 carried slots at the stage's start | InitStageState `$9DA1` |
| `table-itemicons.csv` | `$7F3B` | 18 | the icon of each item kind 0-8 (words) | DrawItemIcon `$7E19`, SpawnItem `$A098` |
| `rooms.txt` | `$9B6F`-`$9C89` | 283 | 3 grid records (Grid0 `$9B6F`, Grid1 `$9B8A`, Grid2 `$9B96`) with their room tables; 3 placement lists (`$9BA0`, `$9C69`, `$9C78`) | RoomCells `$9928`, StartGrid `$A444`, CheckRoomExits `$AADA`, CheckGridPassages `$AB1C`, LoadRoomActors `$A4CC` |
| `table-kinds.csv` | `$9C8A` | 153 | the 17 placement kinds: Y offset, handler, record bytes +8..+`$0C`, +`$0F` | LoadRoomActors `$A4CC` |
| `table-actor-templates.csv` | `$9D23` | 126 | 7 whole actor records: bridge slab, hero, item, piece, fragment, warrior, warrior's head | SpawnActor `$A4B1` and its callers |
| `table-burst-steps.csv` | `$A39D` | 40 | 20 (dx, dy) particle steps | UpdateBurst |
| `graphics.txt`, `tiles.png` | `$B4B2`-`$C2B0` | 3583 | RLE-packed: 196 tiles (kinds, pixels, colours), 114 blocks of 2 x 2 tiles, the map of the three grids | Unrle `$A424` from RoomChange `$988B` |
| `bitmaps-bridge-slab-4x8.png` | `$C2B1` | 32 | the bridge slab | BridgeSlabActor `$90A3` (template) |
| `sprites-fire-pit.png` | `$C2D1` | 192 | fire pit flames, 6 frames | FirePitActor `$8D6D` |
| `sprites-flame-jet.png` | `$C391` | 418 | flame jet, 13 frames | FlameJetActor `$8DCC` |
| `bitmaps-hanging-2x37.png` | `$C533` | 592 | hanging body, 8 frames | HangingActor `$9186` |
| `bitmaps-shot-small-2x5.png`, `bitmaps-shot-upright-1x15.png`, `bitmaps-shot-slanted-2x13.png` | `$C783`-`$C7DE` | 92 | the shots by direction | ShotFrames `$813D` (missiles) |
| `sprites-warrior.png` | `$C7DF` | 1715 | the skeleton warrior, 21 frames | WarriorSetFrame `$9766` |
| `bitmaps-game-over-8x8.png` | `$CE92` | 64 | GAME OVER | GameOverStep `$836D` |
| `sprites-arena-head.png` | `$CED2` | 518 | the dragon's head, 2 frames | ArenaHeadActor `$90E7` |
| `rowpicture-arena.png` | `$D0D8` | 1078 | the dragon's body, 92 lines | DrawArenaPicture `$89BB` |
| `table-arena-attributes.csv` | `$D515` | 192 | the dragon's colours, 12 x 16 | DrawArenaPicture `$89BB` |
| `rowpicture-room.png` | `$D5D5` | 843 | the demon's face over room 12, 53 lines | DrawRoomPicture `$8930` |
| `bitmaps-thrown-2x6.png` | `$D926` | 96 | a thrown skull, 8 frames | the arc missiles (ArcFrame `$8090`) |
| `bitmaps-flat-shot-2x8.png` | `$D986` | 16 | a flat shot | FlatShotFrame `$85C4` |
| `bitmaps-bounce-2x13.png` | `$D996` | 52 | the bouncing shot, 2 frames | BounceFrames `$863D` |
| `sprites-gate.png` | `$D9CA` | 54 | the gate | GateActor `$9065` |
| `sprites-statue.png` | `$DA00` | 300 | the statue head, 3 frames | StatueActor `$912B` |
| `sprites-warrior-collapse.png` | `$DB2C` | 701 | the warrior falling apart, 14 frames | WarriorCollapse `$9705` |
| `bitmaps-boss-wing-3x33.png` | `$DDE9` | 99 | the winged demon's wing | BossWingLeft `$8E60`, BossWingRight `$8E6A` |
| `bitmaps-boss-body-6x32.png` | `$DE4C` | 384 | its body, 2 frames | BossBodySprite `$8FF3` |
| `bitmaps-boss-head-2x20.png` | `$DFCC` | 160 | its head, 4 frames | BossHeadFrames `$8F6D` |
| `sprites-piece.png` | `$E06C` | 292 | a piece of the artefact, 10 frames (the first two also the HUD's) | UpdatePieceActor `$8233`, ShowPieceTaken |
| `sprites-strikeable.png` | `$E190` | 250 | urns and chests (kinds 3-6), 8 frames | StrikeableActor `$A7C4` |
| `sprites-hero-strike.png` | `$E28A` | 435 | the hero's strikes, 9 frames | HeroStrikeLowSet `$AE82` and the others |
| `bitmaps-energy-bar-6x1.png` | `$E43D` | 6 | the energy bar's pattern | DrawEnergyBar `$A3C5` |
| `sprites-hero-jump.png` | `$E443` | 799 | the hero's jump, 19 frames | HeroJumpSet `$B0AF` |
| `sprites-hero-walk.png` | `$E762` | 642 | the hero's walk and stand, 13 frames | HeroWalkSet `$AFD7` |
| `bitmaps-fragment-3x11.png` | `$E9E4` | 264 | an urn's fragment, shifted 0-7 pixels | FragmentActor `$A891` |
| `bitmaps-item-icons-2x16.png` | `$EAEC` | 256 | the 8 item icons | DrawItemIcon `$7E19`, ItemIcons |
| `bitmaps-drift-shots-3x13.png` | `$EBEC` | 156 | the drifting shots, 4 frames | DrawDriftShot `$83D4` |
| `sprites-hero-leap.png` | `$EC88` | 478 | the hero's leaps, 14 frames | HeroLeapSet `$B0EC` |
| `bitmaps-particles-1x8.png` | `$EE66` | 32 | the burst's 4 particle glyphs | UpdateBurst |
| `table-burst-glyphs.csv` | `$EE86` | 35 | the glyph of each burst step | UpdateBurst |
| `table-burst-directions.csv` | `$EEA9` | 192 | 6 directions x 32 steps, indices into BurstSteps | UpdateBurst |
| `bitmaps-burst-shapes-2x12.png` | `$EF69` | 120 | the 5 shapes a burst breaks up (read 24 bytes from `$EF69`, `$EF85`, `$EF99`, `$EFB1`, `$EFC9`) | StartBurst `$A1F3` |

**graphics.txt.** The packer is greedy (every run of 4 to 255 equal bytes becomes `ESC n v`) and keeps one stretch
the original left unpacked (`literal 1366 8`, a blank tile's pixels); with it the block packs again bit for bit. A
changed map or tile set is packed the same way; the escape byte must not occur in the data.

**Not resources.** The bytes no code reads stay in the listing as data with a note: `$D50E` (7 bytes after the dragon's picture), `$D920` (6 bytes after the demon's face), `$EFE1`-`$F03E` (94
zeros), `$779C`-`$77FF` (100 zeros), and the work space `$6C3F`-`$6FFF`, `$76C0`-`$779B` (zeros as loaded).

The figures `docs/img/maps/stage1.png` (the three grids with every placement) and `docs/img/maps/stage1-rooms.png`
(each of the 22 rooms) are drawn from these files by `python3 tools/fig_rooms.py stage1`.
