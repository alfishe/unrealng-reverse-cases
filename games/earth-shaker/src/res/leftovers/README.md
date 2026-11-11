# Leftovers

Bytes the code never reads as data (or reads only as padding), kept as their bytes and listed here, never dropped.

| File | Address | Bytes | What |
| --- | --- | ---: | --- |
| `win-pad.bin` | `$72FE-$72FF` | 2 | two `$FF` after WinTune (the page up to TeleportFrames `$7300`) |
| `names-pad.bin` | `$99C0-$99FF` | 64 | zeros after CaveNames; FindPassword `$8E91` compares 50 records of 20 bytes from `$9700` (`CP $32`), so `$9980-$9AE7` (code, these zeros, the map glyphs and tables) are records 33-50: a typed name never matches them |
| `map-patch.bin` | `$9A90-$9AA4` | 21 | code no path reaches: `CALL $8059`, `CALL $81CC`, `RET`, then `LD HL,$9A90`, `LD DE,$8D78`, `LD BC,7`, `LDIR`, `JP $8B20` (an installer of the map patch) |
| `names-pad2.bin` | `$9ACC-$9AE7` | 28 | zeros, the end of FindPassword's record 50 |
| `earth-anim-pad.bin` | `$9E1A-$9E1F` | 6 | `$C9 $1F $0F $F8 $E0 $03` after EarthAnim |
| `life-pad.bin` | `$ACFD-$ACFF` | 3 | three `$FF` after LifeTune |
| `title-pad.bin` | `$B26A-$B26B` | 2 | two zeros after TitleTune |
| `map-attr-old.bin` | `$E9B4-$E9BF` | 12 | MapCellAttrOld: the 1988 map attribute write (`CP $90`, `RET NC`, `CALL $81B9`, `LD A,(DE)`, `LD (HL),A`, `RET`), replaced by the 1990 patch |
| `choose-pad.bin` | `$ED0C-$ED27` | 28 | `$FE $FE $FC $FC` / `$AA $AA $00 $00` pixel rows: a fragment of a graphic |
| `tune-pad.bin` | `$EE49-$EEFF` | 183 | zeros |
| `graphic-pad.bin` | `$EF24-$F0FF` | 476 | zeros, then from `$F024` pixel bytes of unused graphics (a round object, wall rows) |
| `tunes-pad.bin` | `$F49E-$FADF` | 1602 | memory left in the image: 1288 bytes with no structure, then from `$F9A6` one whole cave record of 314 bytes no table points at: a test cave whose top row holds one of each object (`D.ZZAASS++TTOOFF+...`), 30 gems of 12 points, the start at cell 91, GfxEarth and GfxWall1, colours `$05 $06 $03 $01` |
