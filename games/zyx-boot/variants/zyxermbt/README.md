# Variant zyxermbt

From `work/candidates/owner-boots_zyx/zyxermbt.scl`, file `boot` (B, start 307, length 307, 51 sectors). Built by `tools/build.sh --variant zyxermbt`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 2 sectors of BASIC, then: `$7530` x 3, `$61A8` x 15, `$A600` x 8, `$C000` x 22.
- The music piece at `$C000`, 22 sectors; play `?`.
- Code of its own, described in `parts/intro.ann` (built by kit/mkgame.py from `parts/intro.json`, placed at `$7530`).
- Residue (bytes the saved file kept from a run, put back after the build):
  - `ClearPhaseIndex+2`: `05` (self-modified operand: the last phase offset index BuildRombPhases wrote)
  - `MarkPhaseWrite+2`: `1C` (self-modified operand: the last phase index marked)
  - `ScaleTestBit+3`: `5E` (self-modified opcode: the last BIT n,(IX) the phase builder used)
  - `ScaleWriteBit+3`: `8E` (self-modified opcode: the last RES/SET n,(IY) the phase builder used)
  - `SampleStarBit+1`: `76` (self-modified opcode: the last BIT n,(HL) SampleStars used)
  - `ChannelA`: `04082D01` (the player's channel record as the tune left it)
  - `ChannelA+7`: `0C0F010102C5B7D0BAD0000031D533D533D5` (the player's channel record as the tune left it)
  - `ChannelB+9`: `060106C5` (the player's channel record as the tune left it)
  - `ChannelC+9`: `06010AC5` (the player's channel record as the tune left it)
  - `AYRegisters`: `1C01` (the AY register image as the tune left it)
  - `AYMixer`: `080C` (the AY register image as the tune left it)
  - `AYEnvelopeShape`: `FF0206` (the AY image, CurrentChannel and DelayCounter as the tune left them)
  - `NextPosition+1`: `80C41101` (self-modified operand: the position the player starts next)
  - `PositionCountOp+1`: `16` (self-modified operand: the module's number of positions (InitPlayer))
  - `PatternTableOp+1`: `96C4` (self-modified operand: the pattern table (InitPlayer))
  - `SampleTableOp+1`: `74D0` (self-modified operand: the sample table (InitPlayer))
  - `CommandOrnament+1`: `EFD4` (self-modified operand: the ornament table (InitPlayer))
- `files/tail.bin`: the file's sectors after the last piece, kept as its bytes.
- Files that differ from the original: `basic.txt`, `files/tail.bin`, `graphics/intro-picture.png`, `tables/stars.txt`, `texts/menu-help.txt`.
- The tune: the original's ("Disco music" by Ant P, ASC Sound Master); its player state is residue: the file was saved after the tune had played.
- Its first piece (`$7530` x 3, `parts/intro.ann`) is a position-independent LZ depacker that puts a loading picture on the screen before the menu.
