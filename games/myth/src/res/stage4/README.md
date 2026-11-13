# Stage 4's resources

The editable data of stage 4's block (`$6C3F`-`$F03E`), one file a data entry of `src/stage4/stage4.ann` (`@res`).
`tools/res_formats.py` turns each into its bytes with the formats of `tools/res_stage.py` (the room data with
`tools/res_stage4.py`); `tools/build.sh` assembles them with INCBIN and checks the tape against the original.
`python3 tools/res_formats.py check` proves every file comes back unchanged through its bytes. The formats are
stage 1's (`src/res/stage1/README.md`), except the room data:

- `rooms-split.txt`: stage 4 keeps its nine grid records together, then all their room tables, then all the placement
  lists (stage 1 keeps each record next to its table). The file has a `layout split` line, the table base, each
  `grid` line with its `rooms` lines, then the placement lists in the records' order (`tools/res_stage4.py`).

| File | Address | Bytes | What | Read by |
|------|---------|-------|------|---------|
| `picture-hud-32x48.png` | `$7000`-`$76BF` | 1728 | the HUD as loaded: 48 lines x 32 bytes, then 6 rows of colours; in play the space holds the stage's records (`variables.asm`) | DissolveHud `$8FD6`, StageSetUp `$9715`; saved back by EndStage `$7898` |
| `table-pace-waits.csv` | `$7982` | 96 | the busy-wait rounds of each place, a word for GridNumber x 3 + RoomNumber (48 words) | PacePass `$7961` |
| `table-startitems.csv` | `$7F69` | 12 | the item kind of each of the 12 carried slots at the stage's start | InitStageState `$9F71` |
| `table-itemicons.csv` | `$7F75` | 20 | the icon of each item kind 0-9 (words; kind 4 is BlankIcon) | DrawItemIcon `$7E5A` |
| `rooms-split.txt` | `$9AE2`-`$9DAA` | 713 | 9 grid records (`$9AE2`-`$9B32`), their room tables (`$9B33`-`$9B4F`), 9 placement lists (`$9B50`-`$9DAA`) | RoomCells `$9898`, StartGrid `$A5CC`, LeaveRoomDown `$A06A`, LoadRoomActors |
| `table-kinds.csv` | `$9E1B` | 198 | the 22 placement kinds: Y offset, handler, record bytes +8..+`$0C`, +`$0F` | LoadRoomActors |
| `table-actor-templates.csv` | `$9EE1` | 144 | 8 whole actor records: hero, item, piece, fragment, column dust, bridge ledge, scorpion, mummy | SpawnActor `$A639` and its callers |
| `table-burst-steps.csv` | `$A525` | 40 | 20 (dx, dy) particle steps | UpdateBurst `$A41D` |
| `graphics.txt`, `tiles.png` | `$B77F`-`$C4A4` | 3366 | RLE-packed (escape `$C1`): 179 tiles, 108 blocks of 2 x 2 tiles, the map of the nine grids (5331 bytes unpacked) | Unrle from RoomChange `$97FB` |
| `rowpicture-boss.png` | `$C4A5` | 494 | the boss's face, 104 lines | DrawBossPicture `$8F2B` |
| `table-boss-colours.csv`, `table-boss-hit-colours.csv` | `$C693`, `$C6FB` | 104 + 104 | the face's 8 x 13 attributes, normal and while hit | DrawBossPicture `$8F2B` |
| `sprites-brazier.png` | `$C763` | 194 | a brazier's flame, 4 frames | Brazier `$8917` |
| `sprites-traps.png` | `$C825` | 904 | crumbling slab, spikes, falling column, dust: 27 frames | the trap handlers (kinds 5, 7, 8, 9) |
| `sprites-pendulum.png` | `$CBAD` | 892 | the pendulum, 15 frames | Pendulum `$888F` |
| `bitmaps-shot-small-2x5.png`, `bitmaps-shot-upright-1x15.png`, `bitmaps-shot-slanted-2x13.png` | `$CF29`-`$CF84` | 92 | the shots by direction | ShotFrames `$8098` (DrawShotRecord `$807C`) |
| `bitmaps-bolt-2x8.png` | `$CF85` | 48 | the hero's bolt, 3 frames | UpdateHeroBolt `$80F4` |
| `bitmaps-head-shots-2x8.png` | `$CFB5` | 80 | the boss's shots, 5 directions | HeadShotImages `$B604` |
| `bitmaps-water-4x2.png` | `$D005` | 24 | the water's surface, 3 frames | WaterRipple `$8629` |
| `bitmaps-game-over-8x8.png` | `$D01D` | 64 | GAME OVER | GameOverStep `$8414` |
| `sprites-barrier.png` | `$D05D` | 184 | the barrier's block and pillar, 5 frames | BarrierSet `$9711` |
| `sprites-mummy.png` | `$D115` | 828 | the mummy, 8 frames | MummyActor `$9351` |
| `sprites-scorpion.png` | `$D451` | 183 | the scorpion, 10 frames | ScorpionActor `$9319` |
| `sprites-boss-mouth.png` | `$D508` | 152 | the boss's mouth, 4 frames | BossMouth `$8AD4` |
| `sprites-ledge.png` | `$D5A0` | 207 | the crumbling and bridge ledges, 5 frames | CrumblingLedge `$89A8`, BridgeLedge `$8A59` |
| `bitmaps-disc-2x16.png` | `$D66F` | 32 | the altar's disc | AltarDisc `$8931` |
| `sprites-objects.png` | `$D68F` | 246 | urns, chests, the urn markers' cross: 9 frames | StrikeableActor `$A938`, UrnMarker `$8B1A` |
| `sprites-hero-strike.png` | `$D785` | 854 | the hero's strikes and throw, 16 frames | HeroStrikeLowSet `$AFB5` and the others |
| `bitmaps-energy-bar-6x1.png` | `$DADB` | 6 | the energy bar's pattern | DrawEnergyBar `$A54D` |
| `sprites-hero-jump.png` | `$DAE1` | 963 | the hero's jump, 19 frames | HeroJumpSet `$B25D` |
| `sprites-hero-walk.png` | `$DEA4` | 693 | the hero's walk and stand, 13 frames | HeroWalkSet `$B17E`, HeroStandSet `$AF11` |
| `bitmaps-unread-2x15.png` | `$E159` | 30 | a picture no code reads (kept editable as found) | none |
| `bitmaps-fragment-3x11.png` | `$E177` | 264 | an urn's fragment, shifted 0-7 pixels | MoveFragment `$AB35` |
| `sprites-piece.png` | `$E27F` | 292 | a piece of the artefact, 10 frames (the first two also the HUD's) | UpdatePieceActor `$8260` |
| `bitmaps-item-icons-2x16.png` | `$E3A3` | 288 | the 9 item icons | DrawItemIcon `$7E5A`, ItemIcons |
| `bitmaps-thrown-3x13.png`, `bitmaps-thrown-small-3x8.png` | `$E4C3`, `$E55F` | 156 + 120 | thrown items, 4 frames; 5 smaller frames no code reads | ImageDescriptors `$B62D` |
| `sprites-hero-leap.png` | `$E5D7` | 601 | the hero's leap, 14 frames | HeroLeapSet `$B29A` |
| `bitmaps-particles-1x8.png` | `$E83A` | 32 | the burst's 4 particle glyphs | UpdateBurst `$A41D` |
| `table-burst-glyphs.csv` | `$E85A` | 35 | the glyph of each burst step | UpdateBurst `$A41D` |
| `table-burst-directions.csv` | `$E87D` | 192 | 6 directions x 32 steps, indices into BurstSteps | UpdateBurst `$A41D` |
| `bitmaps-burst-boss-2x12.png` | `$E93D` | 24 | the shape the beaten boss bursts into | BossBeaten `$A24C` |
| `bitmaps-burst-shapes-2x12.png` | `$E95B` | 48 | two burst shapes (`$E95B`, `$E973`) | the ScoreBurst routines, the mummy |

**graphics.txt.** As stage 1's: a greedy packer (every run of 4 to 255 equal bytes becomes `ESC n v`, the escape
`$C1`) and one stretch the original left unpacked (`literal 285 9`); with it the block packs again bit for bit.

**The grids.** The records are named by the GridNumber (`$FE47`) the game sets when it enters a grid; the figures
number them in the records' order:

| Figure | Record | Grid | Size (blocks) | What |
|--------|--------|------|---------------|------|
| 0 | `$9AE2` | Grid0 | 25 x 9 | the beach and the barrier |
| 1 | `$9AEB` | Grid9 | 14 x 9 | the hall beyond the boss; the exit item |
| 2 | `$9AF4` | Grid2 | 47 x 9 | the tomb behind the hub's first door |
| 3 | `$9AFD` | Grid1 | 14 x 15 | the hub, the four doors at columns 8, `$0A`, `$0C`, `$0E` |
| 4 | `$9B06` | Grid3 | 47 x 9 | the second door's tomb |
| 5 | `$9B0F` | Grid4 | 58 x 9 | the third door's tomb |
| 6 | `$9B18` | Grid5 | 58 x 9 | the fourth door's tomb |
| 7 | `$9B21` | Grid8 | 36 x 9 | the boss's hall |
| 8 | `$9B2A` | Grid10 | 36 x 9 | the mummy's corridor (an empty placement list) |

The 62 placements of kind 4 at X 250 are fillers: they keep each trap's placement index even
(TrapSlotAddress `$8786`).

**Not resources.** The bytes no code reads stay in the listing as data with a note: `$E830` (10 bytes), `$E955`
(6 bytes after the boss's burst shape), `$E98B`-`$F03E` (1716 zeros), `$779C`-`$77FF` (100 zeros), and the work
space `$6C3F`-`$6FFF`, `$76C0`-`$779B`, TrapSlots `$9DAB` (zeros as loaded).

The figures `docs/img/maps/stage4.png` (the nine grids with every placement) and `docs/img/maps/stage4-rooms.png`
(each of the 29 rooms) are drawn from these files by `python3 tools/fig_rooms.py stage4` (until fig_rooms reads
`rooms-split.txt`, from a copy of it named `rooms.txt` given with `--res`).
