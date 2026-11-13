# Stage 3's resources

The editable data of stage 3's block (TZX block 46, "Scandinavia 500 AD", `$6C3F`-`$F03E`), one file a data entry of
`src/stage3/stage3.ann` (`@res`). `tools/res_formats.py` turns each into its bytes with the formats of
`tools/res_stage.py` (its docstring has the formats in full); `tools/build.sh` assembles them with INCBIN and checks
the tape against the original. `python3 tools/res_formats.py check` proves every file comes back unchanged through
its bytes. The formats are stage 1's (`src/res/stage1/README.md`):

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
| `picture-hud-32x48.png` | `$7000`-`$76BF` | 1728 | the HUD as loaded: 48 lines x 32 bytes, then 6 rows of colours; in play the space holds the stage's records (`variables.asm`) | DissolveHud `$8952`, StageSetUp `$970D`; saved back by EndStage `$78B6` |
| `table-startitems.csv` | `$7F1E` | 17 | the item kind of each of the 17 carried slots at the stage's start (slots 0-3 kind 4, the blank; slot 6 kind 3) | InitStageState `$9D00` |
| `table-itemicons.csv` | `$7F2F` | 20 | the icon of each item kind 0-9 (words; kind 4 BlankIcon `$8A44`) | DrawItemIcon `$7E07` |
| `rooms.txt` | `$9B37`-`$9BFA` | 196 | 3 grid records (Grid0 `$9B37` 47 x 9 blocks, Grid1 `$9B44` 124 x 9, Grid2 `$9B58` 14 x 9) with their room tables; 3 placement lists (`$9B62`: 14, `$9B8F`: 34, `$9BF8`: none) | RoomCells `$98F0`, StartGrid `$A639`, CheckRoomExits `$ACE2`, CheckGridPassages `$AD24`, LoadRoomActors `$A6CA` |
| `table-kinds.csv` | `$9BFB` | 117 | the 13 placement kinds: Y offset, handler, record bytes +8..+`$0C`, +`$0F` | LoadRoomActors `$A6CA` |
| `table-actor-templates.csv` | `$9C70` | 144 | 8 whole actor records: hero, item, piece, fragment, bog man (right, left), troll's legs, troll's body | SpawnActor `$A6AF` and its callers |
| `table-burst-steps.csv` | `$A313` | 40 | 20 (dx, dy) particle steps | UpdateBurst `$A201` |
| `graphics.txt`, `tiles.png` | `$B556`-`$C1F4` | 3231 | RLE-packed (escape `$F9`, 4437 bytes unpacked): 229 tiles (kinds, pixels, colours), 118 blocks of 2 x 2 tiles, the map of the three grids | Unrle `$A39A` from RoomChange `$9853` |
| `bitmaps-lightning-1-2x24.png` .. `bitmaps-lightning-4-3x104.png` | `$C1F5`-`$C44C` | 600 | the four lightning bolts over the longship (2 x 24, 2 x 48, 2 x 72, 3 x 104) | LightningActor `$94AC` through LightningFrames `$9500` |
| `rowpicture-throne.png` | `$C44D` | 335 | the giant on the throne (grid 2), 79 lines | ThroneBossStep `$9514` (DrawRowPicture) |
| `table-throne-attributes.csv` | `$C59E` | 50 | the giant's colours, 10 rows x 5 (`$FF`: leave the cell) | ThroneBossStep `$9514` |
| `sprites-drawbridge.png` | `$C5D0` | 388 | the castle's drawbridge, 4 frames from raised to lowered | DrawbridgeActor `$9369` |
| `sprites-pyre-flame.png` | `$C754` | 192 | the funeral pyre's flames, 6 frames | PyreFlameActor `$93C8` |
| `sprites-bier.png` | `$C814` | 269 | the pyre's bier (frame 0) and the body on it (frames 1-3) | PyreBierActor `$9420`, PyreBodyActor `$945E` |
| `rowpicture-dragon.png` | `$C921` | 408 | the dragon (grid 1 room 8), 69 lines | DrawDragon `$887A` |
| `table-dragon-attributes.csv` | `$CABF` | 81 | the dragon's colours, 9 x 9 (`$FF`: leave the cell) | DrawDragon `$887A` |
| `bitmaps-dragon-head-4x27.png` | `$CB10` | 432 | the dragon's head, 4 frames (jaws shut to open) | DragonHeadActor `$92BF` |
| `table-dragon-head-frames.csv` | `$CCC1` | 24 | the head's 4 frame records (dx, dy, width, height, offset) | SetActorFrame `$AC0A` from DragonHeadActor |
| `sprites-breath.png` | `$CCD9` | 989 | the dragon's breath, 7 frames from a puff to the full cloud | DragonFlameActor `$9329` |
| `sprites-troll.png` | `$D0B6` | 430 | the troll: legs walking (4 frames), body with the club (3) | TrollFrame `$90AF` (TrollLegsActor, TrollBodyActor) |
| `bitmaps-fireball-2x8.png` | `$D264` | 64 | the giant's fireball, 4 frames | UpdateThroneShot `$80F0` (ThroneShotFrames `$8170`) |
| `bitmaps-shot-small-2x5.png`, `bitmaps-shot-upright-1x15.png`, `bitmaps-shot-slanted-2x13.png` | `$D2A4`-`$D2FF` | 92 | the shots by direction (only the first is read in stage 3) | ShotFrames `$80A4` |
| `bitmaps-thrown-ammo-1x4.png` | `$D300` | 16 | the thrown object, 4 frames shrinking | UpdateThrownAmmo `$7FF5` (ThrownAmmoFrames `$805E`) |
| `bitmaps-water-4x4.png` | `$D310` | 16 | the water's surface, 3 overlapping 4 x 2 frames | WaterRippleActor `$928E` |
| `bitmaps-game-over-8x8.png` | `$D328` | 64 | GAME OVER | GameOverStep `$83F2` |
| `sprites-viking.png` | `$D368` | 1273 | the Viking warrior, 18 frames | VikingFrame `$8E9A` |
| `sprites-bog-man.png` | `$D861` | 1642 | the bog man, 20 frames (rising, wading, sinking) | BogManFrame `$9203` |
| `sprites-piece.png` | `$DECB` | 292 | a piece of the artefact, 10 frames (the first two also the HUD's) | UpdatePieceActor `$82B9`, ShowPieceTaken `$837F` |
| `sprites-strikeable.png` | `$DFEF` | 250 | urns and chests (kinds 0-3), 8 frames | StrikeableActor `$A9C2` |
| `sprites-hero-strike.png` | `$E0E9` | 309 | the hero's hammer strikes, 4 frames | HeroStrikeSet `$AF99` |
| `bitmaps-energy-bar-6x1.png` | `$E21E` | 6 | the energy bar's pattern | DrawEnergyBar `$A33B` |
| `sprites-hero-jump.png` | `$E224` | 1020 | the hero's jump, 19 frames | HeroJumpSet `$B143` |
| `sprites-hero-walk.png` | `$E620` | 728 | the hero's walk and stand, 13 frames | HeroWalkSet `$B06B`, HeroStandSet `$AF1F` |
| `bitmaps-fragment-3x11.png` | `$E8F8` | 264 | an urn's fragment, shifted 0-7 pixels | FragmentActor `$AA94` |
| `bitmaps-item-icons-2x16.png` | `$EA00` | 288 | the 9 item icons | DrawItemIcon `$7E07` through ItemIcons, SpawnItem `$A081` |
| `bitmaps-drift-shots-3x13.png` | `$EB20` | 156 | the drifting shots, 4 frames | UpdatePathFlyer `$842E` through ImageDescriptors `$B4B9` |
| `sprites-hero-leap.png` | `$EBBC` | 765 | the hero's leaps, 14 frames | HeroLeapSet `$B180` |
| `bitmaps-particles-1x8.png` | `$EEB9` | 32 | the burst's 4 particle glyphs | UpdateBurst `$A201` |
| `table-burst-glyphs.csv` | `$EED9` | 35 | the glyph of each burst step | UpdateBurst `$A201` |
| `table-burst-directions.csv` | `$EEFC` | 192 | 6 directions x 32 steps, indices into BurstSteps | UpdateBurst `$A201` |
| `bitmaps-burst-shapes-2x31.png` | `$EFBC` | 62 | the shapes a burst breaks up (24 bytes read from `$EFBC`, `$EFCA` or `$EFE2`, the bosses') | StartBurst `$A169` |

**graphics.txt.** The packer is stage 1's (greedy: every run of 4 to 255 equal bytes becomes `ESC n v`, here with
the escape `$F9`) and keeps one stretch the original left unpacked (`literal 1663 8`); with it the block packs again
bit for bit. A changed map or tile set is packed the same way; the escape byte must not occur in the data.

**Not resources.** The bytes no code reads stay in the listing as data with a note: `$C59C` (2 bytes after the
giant's picture), `$CAB9` (6 bytes after the dragon's picture), `$CCC0` (1 byte between the dragon head's frames and
their table), `$D320` (8 bytes after the water's frames), `$EFFA`-`$F03E` (69 zeros), and the work space
`$6C3F`-`$6FFF`, `$76C0`-`$76DF` (32 bytes, `Unused76C0`) and the span table's tail (zeros as loaded). Some code-area
bytes no code reads: ShotFramesUnused `$80A8`, SwampSpawnRoomsUnread `$8F8E`, RoomEventsLeftover `$9F7E`,
BurstLeftover `$A308`, RedCycleColours `$B452`, RedCycle4 `$B498`.

The figures `docs/img/maps/stage3.png` (the three grids with every placement) and `docs/img/maps/stage3-rooms.png`
(each of the 16 rooms) are drawn from these files by `python3 tools/fig_rooms.py stage3`.
