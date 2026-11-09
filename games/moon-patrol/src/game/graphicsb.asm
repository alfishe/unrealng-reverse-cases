; --------------------------------------------------------------------------------------------------------------------
; graphicsb.asm: Graphics B: the enemies, the obstacles, the buggy and the three scenery strips
;
; Same formats as graphics A (the drawers are listed there). The Beginner enemies are read in game and the other
; plays; the Champion-only ones (plants, boulders, tanks, low flyers, their bursts) in i2, and in a1 / t1 where the
; score advance table draws them ($8141, sixteen sprites from $83D8).
; --------------------------------------------------------------------------------------------------------------------

; The small boulder's burst (sprites $80-$83): 4 frames of 2x8 bytes, 4 slots
; of 16
;
; Drawer $B003: 2 bytes x 8 lines, slot = x AND 6, 64 bytes a frame, frames at
; $C350, $C390, $C3D0, $C410. The boulder handler sets a small boulder's frame
; to $7F ($A1EA) and counts it to $83 ($A29C). Read only in i2, 96 of 256
; bytes.
BurstTiny:
  INCBIN "res/graphics/BurstTiny.bin",$0000,256

; The plant (sprites $64-$72): 8 frames of 4x16 bytes, 4 slots of 64; the
; sprites play them forward then back
;
; Drawer $B184: 4 bytes x 16 lines, slot = x AND 6, 256 bytes a frame, frames
; at $C450 + $100 n (n 0-7). Sprites $64-$6B are frames 1-8, $6C-$72 frames
; 7-1. The plant handler at $A2C6 draws sprite $63 + its step. Read in i2 66176
; times and in a1 1284 (the score table); 1024 of 2048 bytes.
PlantFrames:
  INCBIN "res/graphics/PlantFrames.bin",$0000,2048

; The plant's spray (sprites $74-$7A): 4 frames of 4x16, played forward then
; back
;
; Drawer $B184 as PlantFrames. Sprites $74-$77 are frames 1-4, $78-$7A frames
; 3-1; the plant handler uses step + $6F for steps 5-$0B ($A2E3). All 1024
; bytes read, in i2 only.
PlantSpray:
  INCBIN "res/graphics/PlantSpray.bin",$0000,1024

; The big boulder (sprites $4C-$57): 4 frames of 3x16, each used by three
; sprites
;
; Drawer $B10D: 3 bytes x 16 lines, slot = x AND 6, 192 bytes a frame, frames
; at $D050, $D110, $D1D0, $D290. The course command gives the kind's first
; sprite ($40 / $44 / $4C); the handler at $A196 steps the sprite number
; through the kind's range, and consecutive numbers share a frame (three here,
; two for the medium boulder), so the picture changes every third step. Read in
; i2 46080 times and in a1 / t1.
BoulderLarge:
  INCBIN "res/graphics/BoulderLarge.bin",$0000,768

; The medium boulder (sprites $44-$4B): 4 frames of 3x12, each used by two
; sprites
;
; Drawer $B0E2: 3 bytes x 12 lines, 4 slots of 36, 144 bytes a frame, frames at
; $D350, $D3E0, $D470, $D500. Read in i2, a1 and t1.
BoulderMedium:
  INCBIN "res/graphics/BoulderMedium.bin",$0000,576

; The small boulder (sprites $40-$43): 4 frames of 2x8, 4 slots of 16
;
; Drawer $B003: 64 bytes a frame, frames at $D590, $D5D0, $D610, $D650. 128 of
; 256 bytes read (i2, a1, t1).
BoulderSmall:
  INCBIN "res/graphics/BoulderSmall.bin",$0000,256

; The UFO bombs (sprites $1D, $1E): 2 frames of 2x4 bytes, 8 slots of 8
;
; Drawer $AFDD: 2 bytes x 4 lines, slot = x AND 7, 64 bytes a frame. $1D is the
; falling bomb ($9892 stores it in a new bomb), $1E the bomb landing ($9D61).
; Read in i1 and i2  and in a1 / t1.
UfoBomb:
  INCBIN "res/graphics/UfoBomb.bin",$0000,128

; The low flyer (sprite $14): 3x8 bytes, 8 shift slots of 24
;
; Drawer $B0BA: 3 bytes x 8 lines, slot = x AND 7, 192 bytes. Its handler is at
; $A03B (record $9903); the tank's record also holds sprite $14 ($98DA). Read
; in i2, a1 and t1.
LowFlyer:
  INCBIN "res/graphics/LowFlyer.bin",$0000,192

; The tank (sprite $13): 5x23 bytes, 4 shift slots of 128
;
; Drawer $B1C8 (as the buggy): 115 bytes of each 128-byte slot used, slot = x
; AND 6. The handler at $9EBD; its explosion is sprites $33-$36
; (BuggyExplosion's first frames). 460 of 512 bytes read: the padding never is.
; Read in i1, i2, a1, t1.
Tank:
  INCBIN "res/graphics/Tank.bin",$0000,512

; The mine (sprites $11, $12): 2 blink frames of 2x4 bytes, 8 slots of 8
;
; Drawer $AFDD. The mine handler at $9AEB draws sprite $11 + bit 2 of PassCount
; $B23B ($9B42), so the mine blinks every 4 passes. Only 40 of 128 bytes are
; read (i1, i2, a1, t1).
Mine:
  INCBIN "res/graphics/Mine.bin",$0000,128

; The crater a UFO bomb leaves (sprite $10): 3x16, 4 slots of 48
;
; Drawer $B10D, 192 bytes; drawn by the crater handler at $9A92. All read (i1,
; i2, a1, t1).
BombCrater:
  INCBIN "res/graphics/BombCrater.bin",$0000,192

; The rock (sprite $0F): 3x12, 4 slots of 36
;
; Drawer $B0E2, 144 bytes; the rock handler at $99C3. Read in every build (game
; 37188 times).
Rock:
  INCBIN "res/graphics/Rock.bin",$0000,144

; The spinner, the third UFO kind (sprites $0B-$0E): 4 frames of 3x16 with
; colour, 4 slots of 48
;
; Drawer $B115: 3 bytes x 16 lines and the colour of 3x3 cells, 192 bytes a
; frame, frames at $DBA0, $DC60, $DD20, $DDE0. The UFO handler at $9B6B
; animates it ($9C93 LD A,$0B is its base). Read in i1, i2, a1, t1.
Spinner:
  INCBIN "res/graphics/Spinner.bin",$0000,768

; The second UFO kind (sprites $05-$0A): 4 frames of 3x8 with colour, played 1
; 2 3 4 3 2
;
; Drawer $B069: 3 bytes x 8 lines, 4 slots of 24, 96 bytes a frame, frames at
; $DEA0, $DF00, $DF60, $DFC0. Base sprite $05 ($9C97). Read in i1, i2, a1, t1.
UfoB:
  INCBIN "res/graphics/UfoB.bin",$0000,384

; The first UFO kind (sprites $01-$04): 3 frames of 3x8 with colour, played 1 2
; 3 2
;
; Drawer $B069, frames at $E020, $E080, $E0E0. Base sprite $01 ($9C9B). Read in
; i1, i2, a1, t1.
UfoA:
  INCBIN "res/graphics/UfoA.bin",$0000,288

; The moon buggy (sprite $00): 5x23 bytes, 4 shift slots of 128
;
; Drawer $B1C8: 115 bytes of each 128-byte slot, slot = x AND 6. Drawn every
; pass by the buggy routine at $AA0F ($AABC with A = 0 while DeathStep is $FF).
; 460 of 512 bytes read, in every build.
Buggy:
  INCBIN "res/graphics/Buggy.bin",$0000,512

; The mountains, the middle scenery layer (lines 96-127) when the scenery byte
; is 0: 34 columns of 8 pixels x 32 lines
;
; Column-major: each 32 bytes are one 8-pixel column, top line first; 34
; columns = 272 pixels. Drawn whole by $9590 at the life start, then fed in a
; column at a time by the middle scroller at $A89A (2 pixels every 4 passes)
; between MiddleStart and MiddleEnd. All 1088 bytes read in game and the other
; mountain plays.
MountainsStrip:
  INCBIN "res/graphics/MountainsStrip.bin",$0000,1088

; The moon base city, the middle layer when the scenery byte is $FF: 34 columns
; x 32 lines
;
; Same format and scroller as MountainsStrip. Chosen by $9541 from
; PlayerScenery; read in a1, t1, i1, i2 (the city sectors).
MoonBaseStrip:
  INCBIN "res/graphics/MoonBaseStrip.bin",$0000,1088

; The craggy hills, the back layer (lines 64-95), always: 34 columns x 32 lines
;
; Same format; drawn at the life start by $9590 and scrolled by the hills
; scroller at $A846, 1 pixel every 8 passes, the column pointer HillsColumn
; wrapping at $F000 back to $EBC0 ($A858, $A862). Read in every build.
HillsStrip:
  INCBIN "res/graphics/HillsStrip.bin",$0000,1088
