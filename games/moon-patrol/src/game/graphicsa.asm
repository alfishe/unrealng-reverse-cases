; --------------------------------------------------------------------------------------------------------------------
; graphicsa.asm: Graphics A: the title logo, the buggy's wreck, the explosions and bursts, one build-date string
;
; The sprites here and in graphics B are drawn by the sprite drawer $A826 through SpriteTable $B2D6 (sprite number ->
; drawer, graphics address). Every drawer XORs a pre-shifted image onto the screen: the graphics address plus a shift
; slot chosen by the low bits of x, then rows of W bytes, top row first, no mask. The drawers and their formats: $B1C8
; 5x23 bytes in 128-byte slots, 4 slots (x AND 6); $B184 4x16, 4 slots of 64; $B10D / $B115 3x16, 4 slots of 48 ($B115
; also colours 3x3 cells); $B0E2 3x12, 4 slots of 36; $B0BA 3x8, 8 slots of 24 (x AND 7); $B069 3x8, 4 slots of 24
; (also colours 3x2 cells); $B02A 2x9, 8 slots of 18; $B003 2x8, 4 slots of 16; $AFDD 2x4, 8 slots of 8. A frame is
; all its slots; a frame set is consecutive frames.
;
; The title logo is copied, not XORed: the copier $AFAB copies rows of BlitWidth bytes to the screen at BlitX (in
; bytes), lines BlitTop to BlitBottom-1.
; --------------------------------------------------------------------------------------------------------------------

; The title logo's "Moon": 10 bytes x 25 lines, copied to x 88, lines 24-48
;
; Copied by the copier $AFAB from the title $8004 ($8024: BlitTop 24,
; BlitBottom 49, BlitX $58 = byte 11, width 10) and at each life start from
; $9136 ($9163, the HUD header). Linear rows of 10 bytes, one bit a pixel, set
; = ink; no mask, no shifts. All 250 bytes are read in every build (game, a1
; twice, g1, t1, p2, h1 twice, i1, i2).
TitleMoon:
  INCBIN "res/graphics/TitleMoon.bin",$0000,250

; The title logo's "Patrol": 14 bytes x 25 lines, copied to x 72, lines 55-79
;
; Copied by the copier $AFAB from $8036 (BlitTop $37, BlitBottom $50, BlitX
; $48, width 14). Same format as TitleMoon $6132. The last 58 bytes,
; $6350-$6389, are also the first 3 1/4 shift slots of BuggyWreck1's frame:
; SpriteTable entry $3C points at $6350, so wreck piece 1 drawn at x AND 7 =
; 0-3 shows bytes of the logo (see BuggyWreck1 $638A).
TitlePatrol:
  INCBIN "res/graphics/TitlePatrol.bin",$0000,350

; Wreck piece 1 of the buggy (sprite $3C): the visible part of its 2x9 frame,
; slots 3 1/4 to 7
;
; Sprite $3C, drawer $B02A: 2 bytes x 9 lines, 8 shift slots of 18 bytes, one
; per pixel of x AND 7, from $6350. Its first 58 bytes, $6350-$6389, are the
; end of TitlePatrol $622C, so this entry starts where the piece's own bytes
; start: the middle of slot 3 (its line 2). Slots 4-7 ($6398-$63DF) hold a
; wheel with its hub on top, moving one pixel a slot.
;
; Drawn by the wreck routine $AB37 ($AB95) after a death: the three pieces
; $3C-$3E fly from the buggy along the path at $AC31. Read in game, a1, g1, p2,
; h1, h2 (deaths), never in the immune runs i1 / i2. A piece that leaves the
; top of the screen is drawn with a line number past 191, so the line table
; read runs past ScreenLineTable $FC00 into the print code at $FD80 (reads of
; $FDA6-$FDB7, game / g1 / p2 / h1 / h2) and the XOR lands on $6F75-$6F79,
; $77B5-$77B9, $7D15-$7D19 and $CB5B-$CB5F; every byte there is written an even
; number of times (draw and erase), so the image is restored.
BuggyWreck1:
  INCBIN "res/graphics/BuggyWreck1.bin",$0000,86

; Wreck piece 2 of the buggy (sprite $3D): 2x9, 8 shift slots of 18 bytes
;
; Drawn by the wreck routine $AB37 ($ABD0). A wheel with a stub; slots 0-2 move
; right, slot 3 restarts 5 pixels left (the image's origin moves with the
; slot). All 144 bytes read in game, a1, g1, p2, h1, h2.
BuggyWreck2:
  INCBIN "res/graphics/BuggyWreck2.bin",$0000,144

; Wreck piece 3 of the buggy (sprite $3E): 2x9, 8 shift slots of 18 bytes
;
; Drawn by the wreck routine $AB37 ($AC0B). A smaller wheel. Only the even
; slots were read (72 of 144 bytes): the piece's x stays even in the
; recordings.
BuggyWreck3:
  INCBIN "res/graphics/BuggyWreck3.bin",$0000,144

; The buggy's explosion (sprites $1F-$26): 8 frames of 5x23 bytes, 4 shift
; slots of 128 bytes each
;
; Drawer $B1C8: 5 bytes x 23 lines = 115 bytes at the start of each 128-byte
; slot (13 bytes of padding), slot = x AND 6 (2-pixel steps), 4 slots = 512
; bytes a frame, frames at $6500, $6700, ..., $7300. Drawn by the buggy routine
; $AA0F ($AABC): sprite $1E + DeathStep $B216 (1-8) at the buggy's place, one
; frame a pass; the main loop $96CC erases frame $26 when DeathStep reaches 8.
; The tank's explosion, sprites $33-$36, reuses the first four frames
; (SpriteTable $B3A2).
;
; Slot 0 of frame 1 ($6500-$6572) is not an explosion: lines 0-11 and 20-22
; hold other bytes (rows of 2-pixel stripes), lines 12-19 are blank. It is read
; in game, a1, g1, p2, h1, h2, so a buggy dying at an x with x AND 6 = 0 shows
; those stripes for one frame; how it looks is for a run to confirm. 3685 of
; the 4096 bytes are read.
BuggyExplosion:
  INCBIN "res/graphics/BuggyExplosion.bin",$0000,4096

; The "500" sign shown where a green plant was shot (sprite $73): 4x16 bytes, 4
; shift slots of 64
;
; Drawer $B184: 4 bytes x 16 lines, slot = x AND 6, 256 bytes. Drawn by the
; plant routine at $A415 (LD A,$73) after the plant is shot. Read only in i2
; (Champion), slots 0 and 2 (128 of 256 bytes).
PlantScore:
  INCBIN "res/graphics/PlantScore.bin",$0000,256

; Large burst, 4 frames of 3x16 bytes (sprites $2F-$32 with colour, $60-$63
; without)
;
; Drawers $B115 (sprites $2F-$32, also colours 3x3 cells) and $B10D ($60-$63):
; 3 bytes x 16 lines, 4 slots of 48 bytes (x AND 6), 192 bytes a frame, frames
; at $7600, $76C0, $7780, $7840. $60-$63 are the large boulder's break-up: the
; boulder handler sets its frame to $5F ($A1FC) and $A29C counts it up until
; (frame - $5C) AND $D7 is 0, at $64. $2F-$32 are a shot UFO's burst: the UFO
; handler counts its frame up and ends at $33 ($9CCA-$9CD4). Read in i1 1920
; and i2 8064 times, a few reads in the other builds.
BurstLarge:
  INCBIN "res/graphics/BurstLarge.bin",$0000,768

; Debris, 4 frames of 3x12 bytes (sprites $2B-$2E, $5C-$5F and $7B-$7E)
;
; Drawer $B0E2: 3 bytes x 12 lines, 4 slots of 36 bytes (x AND 6), 144 bytes a
; frame, frames at $7900, $7990, $7A20, $7AB0. Sprites $2B-$2E are a shot
; rock's pieces (the rock handler counts its frame up to $2E, $9A79 CP $2F);
; $7B-$7E a shot plant's ($A439 CP $7F). $5C-$5F point here too, but the medium
; boulder's count stops at $5B: no user of $5C-$5F was found. Read in every
; build except t1.
Debris:
  INCBIN "res/graphics/Debris.bin",$0000,576

; Medium burst, 4 frames of 3x12 bytes (sprites $58-$5B)
;
; Drawer $B0E2 (as Debris $7900), frames at $7B40, $7BD0, $7C60, $7CF0. The
; medium boulder's break-up: the boulder handler sets its frame to $57 ($A1F3)
; and $A29C counts $58-$5B. Read in i2 2880 times; the few reads in game, a1,
; g1, p2, h1, h2 ($7D15-$7D19) are the wreck pieces' stray XOR (BuggyWreck1
; $638A).
BurstMedium:
  INCBIN "res/graphics/BurstMedium.bin",$0000,576

; Small burst, 4 frames of 3x8 bytes with colour (sprites $27-$2A and $37-$3A)
;
; Drawer $B069: 3 bytes x 8 lines, 4 slots of 24 bytes (x AND 6), 96 bytes a
; frame, frames at $7D80, $7DE0, $7E40, $7EA0; the drawer also colours 3x2
; cells with the colour in E'. $37-$3A are the low flyer's explosion (its
; handler counts to $3A, $A160 CP $3B); $27-$2A a UFO's smaller burst, ended at
; $2B by the same count ($9CCD). Read only in i1 (6144) and i2 (4416).
BurstSmall:
  INCBIN "res/graphics/BurstSmall.bin",$0000,384

; A print string with the build date 03:35 30/10/84, printed at each life
; start; its first byte $1F ends it at once
;
; The life start $90D3 prints it ($911A LD HL,$7F00; CALL $FFD0) and PrintText
; $FFD0 stops at the first byte, $1F: nothing is printed. Read once per life
; start (game 20, a1 4, g1 4, p2 8, h1 4, i1 6, i2 6); $7F01-$7F13 are never
; read. The rest reads as a whole print string: x 0, line $19, FONT 2, "03:35
; 30/10/84", end ($1F). With $16 (AT) instead of the first $1F it would print
; the date at x 0, line 25. The three other dates are disabled the same way:
; $90B8 (line $21), $A182 (line $29) and BuildDate0245 $B2C2 (line $31),
; printed one after the other by $90D3.
BuildDate0335:
  INCBIN "res/text/BuildDate0335.bin",$0000,20
