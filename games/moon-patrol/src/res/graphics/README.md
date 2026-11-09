# Graphics

The pictures of graphics A (`$6132-$7EFF`) and graphics B (`$C350-$EFFF`) as indexed PNG sheets: palette 0 paper (black),
1 ink (white), 2 grid (grey, also the unused end of a 128-byte slot's last line). `tools/res_formats.py` turns each
back into its bytes (the layout is in the PNG's text chunk `mp-sheet` and in `SHEETS`).

- The sprites are drawn with XOR by DrawSprite `$A826`: the sprite table `$B2D6` gives each sprite number its drawer
  and graphics address, the drawer picks the pre-shifted slot for the sprite's x (4 or 8 slots, see each drawer in sprites.asm). A frame of
  the sheet is one slot: rows top first, bit 7 leftmost.
- The title logo is copied, not XORed, by BlitRows `$AFAB`.
- The scenery strips are stored column by column (34 columns of 8 pixels, 32 lines each, top first); ScenerySetup `$9541` draws
  them, the band scrollers (ScrollMountains `$A846`, ScrollHills `$A89A`) take new columns from them.
- Bytes inside these ranges that no recording read are kept in the sheets as they are.

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `TitleMoon.png` | `$6132-$622B` | 250 | 10 bytes across, 250-byte frames | TitlePage, BlitRows `$AFAB` | The title logo's "Moon": 10 bytes x 25 lines, copied to x 88, lines 24-48 |
| `TitlePatrol.png` | `$622C-$6389` | 350 | 14 bytes across, 350-byte frames | TitlePage, BlitRows `$AFAB`; its last 58 bytes also by DrawSprite16x9 (sprite `$3C`, from `$6350`) | The title logo's "Patrol": 14 bytes x 25 lines, copied to x 72, lines 55-79 |
| `BuggyWreck1.png` | `$638A-$63DF` | 86 | 2 bytes across, 86-byte frames | DrawSprite16x9 (sprite `$3C`, from `$6350`) | Wreck piece 1 of the buggy (sprite `$3C`): the visible part of its 2x9 frame, slots 3 1/4 to 7 |
| `BuggyWreck2.png` | `$63E0-$646F` | 144 | 2 bytes across, 18-byte frames | DrawSprite16x9 (sprites `$3D`) | Wreck piece 2 of the buggy (sprite `$3D`): 2x9, 8 shift slots of 18 bytes |
| `BuggyWreck3.png` | `$6470-$64FF` | 144 | 2 bytes across, 18-byte frames | DrawSprite16x9 (sprites `$3E`) | Wreck piece 3 of the buggy (sprite `$3E`): 2x9, 8 shift slots of 18 bytes |
| `BuggyExplosion.png` | `$6500-$74FF` | 4096 | 5 bytes across, 128-byte frames | DrawSprite40x23 (sprites `$1F`, `$20`, `$21`, `$22`, `$23`, `$24`, `$25`, `$26`, `$33`, `$34`, `$35`, `$36`) | The buggy's explosion (sprites `$1F`-`$26`): 8 frames of 5x23 bytes, 4 shift slots of 128 bytes each |
| `PlantScore.png` | `$7500-$75FF` | 256 | 4 bytes across, 64-byte frames | DrawSprite32x16 (sprites `$73`) | The "500" sign shown where a green plant was shot (sprite `$73`): 4x16 bytes, 4 shift slots of 64 |
| `BurstLarge.png` | `$7600-$78FF` | 768 | 3 bytes across, 48-byte frames | DrawSprite24x16Attr (sprites `$2F`, `$30`, `$31`, `$32`); DrawSprite24x16 (sprites `$60`, `$61`, `$62`, `$63`) | Large burst, 4 frames of 3x16 bytes (sprites `$2F`-`$32` with colour, `$60`-`$63` without) |
| `Debris.png` | `$7900-$7B3F` | 576 | 3 bytes across, 36-byte frames | DrawSprite24x12 (sprites `$2B`, `$2C`, `$2D`, `$2E`, `$5C`, `$5D`, `$5E`, `$5F`, `$7B`, `$7C`, `$7D`, `$7E`) | Debris, 4 frames of 3x12 bytes (sprites `$2B`-`$2E`, `$5C`-`$5F` and `$7B`-`$7E`) |
| `BurstMedium.png` | `$7B40-$7D7F` | 576 | 3 bytes across, 36-byte frames | DrawSprite24x12 (sprites `$58`, `$59`, `$5A`, `$5B`) | Medium burst, 4 frames of 3x12 bytes (sprites `$58`-`$5B`) |
| `BurstSmall.png` | `$7D80-$7EFF` | 384 | 3 bytes across, 24-byte frames | DrawSprite24x8Attr (sprites `$27`, `$28`, `$29`, `$2A`, `$37`, `$38`, `$39`, `$3A`) | Small burst, 4 frames of 3x8 bytes with colour (sprites `$27`-`$2A` and `$37`-`$3A`) |
| `BurstTiny.png` | `$C350-$C44F` | 256 | 2 bytes across, 16-byte frames | DrawSprite16x8 (sprites `$80`, `$81`, `$82`, `$83`) | The small boulder's burst (sprites `$80`-`$83`): 4 frames of 2x8 bytes, 4 slots of 16 |
| `PlantFrames.png` | `$C450-$CC4F` | 2048 | 4 bytes across, 64-byte frames | DrawSprite32x16 (sprites `$64`, `$65`, `$66`, `$67`, `$68`, `$69`, `$6A`, `$6B`, `$6C`, `$6D`, `$6E`, `$6F`, `$70`, `$71`, `$72`) | The plant (sprites `$64`-`$72`): 8 frames of 4x16 bytes, 4 slots of 64; the sprites play them forward then back |
| `PlantSpray.png` | `$CC50-$D04F` | 1024 | 4 bytes across, 64-byte frames | DrawSprite32x16 (sprites `$74`, `$75`, `$76`, `$77`, `$78`, `$79`, `$7A`) | The plant's spray (sprites `$74`-`$7A`): 4 frames of 4x16, played forward then back |
| `BoulderLarge.png` | `$D050-$D34F` | 768 | 3 bytes across, 48-byte frames | DrawSprite24x16 (sprites `$4C`, `$4D`, `$4E`, `$4F`, `$50`, `$51`, `$52`, `$53`, `$54`, `$55`, `$56`, `$57`) | The big boulder (sprites `$4C`-`$57`): 4 frames of 3x16, each used by three sprites |
| `BoulderMedium.png` | `$D350-$D58F` | 576 | 3 bytes across, 36-byte frames | DrawSprite24x12 (sprites `$44`, `$45`, `$46`, `$47`, `$48`, `$49`, `$4A`, `$4B`) | The medium boulder (sprites `$44`-`$4B`): 4 frames of 3x12, each used by two sprites |
| `BoulderSmall.png` | `$D590-$D68F` | 256 | 2 bytes across, 16-byte frames | DrawSprite16x8 (sprites `$40`, `$41`, `$42`, `$43`) | The small boulder (sprites `$40`-`$43`): 4 frames of 2x8, 4 slots of 16 |
| `UfoBomb.png` | `$D690-$D70F` | 128 | 2 bytes across, 8-byte frames | DrawSprite16x4 (sprites `$1D`, `$1E`) | The UFO bombs (sprites `$1D`, `$1E`): 2 frames of 2x4 bytes, 8 slots of 8 |
| `LowFlyer.png` | `$D710-$D7CF` | 192 | 3 bytes across, 24-byte frames | DrawSprite24x8 (sprites `$14`) | The low flyer (sprite `$14`): 3x8 bytes, 8 shift slots of 24 |
| `Tank.png` | `$D7D0-$D9CF` | 512 | 5 bytes across, 128-byte frames | DrawSprite40x23 (sprites `$13`) | The tank (sprite `$13`): 5x23 bytes, 4 shift slots of 128 |
| `Mine.png` | `$D9D0-$DA4F` | 128 | 2 bytes across, 8-byte frames | DrawSprite16x4 (sprites `$11`, `$12`) | The mine (sprites `$11`, `$12`): 2 blink frames of 2x4 bytes, 8 slots of 8 |
| `BombCrater.png` | `$DA50-$DB0F` | 192 | 3 bytes across, 48-byte frames | DrawSprite24x16 (sprites `$10`) | The crater a UFO bomb leaves (sprite `$10`): 3x16, 4 slots of 48 |
| `Rock.png` | `$DB10-$DB9F` | 144 | 3 bytes across, 36-byte frames | DrawSprite24x12 (sprites `$0F`) | The rock (sprite `$0F`): 3x12, 4 slots of 36 |
| `Spinner.png` | `$DBA0-$DE9F` | 768 | 3 bytes across, 48-byte frames | DrawSprite24x16Attr (sprites `$0B`, `$0C`, `$0D`, `$0E`) | The spinner, the third UFO kind (sprites `$0B`-`$0E`): 4 frames of 3x16 with colour, 4 slots of 48 |
| `UfoB.png` | `$DEA0-$E01F` | 384 | 3 bytes across, 24-byte frames | ScoreAdvancePage; DrawSprite24x8Attr (sprites `$05`, `$06`, `$07`, `$08`, `$09`, `$0A`) | The second UFO kind (sprites `$05`-`$0A`): 4 frames of 3x8 with colour, played 1 2 3 4 3 2 |
| `UfoA.png` | `$E020-$E13F` | 288 | 3 bytes across, 24-byte frames | DrawSprite24x8Attr (sprites `$01`, `$02`, `$03`, `$04`) | The first UFO kind (sprites `$01`-`$04`): 3 frames of 3x8 with colour, played 1 2 3 2 |
| `Buggy.png` | `$E140-$E33F` | 512 | 5 bytes across, 128-byte frames | DrawSprite40x23 (sprites `$00`) | The moon buggy (sprite `$00`): 5x23 bytes, 4 shift slots of 128 |
| `MountainsStrip.png` | `$E340-$E77F` | 1088 | 34 bytes across, 1088-byte frames, column by column | ScenerySetup | The mountains, the middle scenery layer (lines 96-127) when the scenery byte is 0: 34 columns of 8 pixels x 32 lines |
| `MoonBaseStrip.png` | `$E780-$EBBF` | 1088 | 34 bytes across, 1088-byte frames, column by column | ScenerySetup | The moon base city, the middle layer when the scenery byte is `$FF`: 34 columns x 32 lines |
| `HillsStrip.png` | `$EBC0-$EFFF` | 1088 | 34 bytes across, 1088-byte frames, column by column | ScenerySetup, ScrollMountains `$A846` (the column pointer wraps at `HillsStrip+$0440`, `$A858`) | The craggy hills, the back layer (lines 64-95), always: 34 columns x 32 lines |
